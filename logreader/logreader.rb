require File.dirname(__FILE__) + "/../lib/time_helpers.rb"

class ApacheRequest
  attr_reader   :time
  attr_reader   :page_url
  attr_reader   :source_url
  attr_reader   :unique
  attr_reader   :browser
  attr_reader   :os

  def initialize(ip, time, page_url, source_url, unique, browser, os)
    @ip = ip
    @time = time
    @page_url = page_url
    @source_url = source_url
    @unique = unique
    @browser = browser
    @os = os
  end

#------------------------------------------------------------------------------

  def print
    puts "Client IP: #{@ip}"
    puts "Time: #{@time.to_s}"
    puts "Source: #{@source_url}"
    puts "Project Id: #{@project_id}"
    puts "Monitored Page: #{@landing_url}"
    puts "Browser: #{@browser}"
    puts "OS: #{@os}"
    puts "\n"
  end

#------------------------------------------------------------------------------

  def save( project )
    project.process_request( self ) unless project.nil?
  end

end

class ApacheLogReader

  @@log_line_regex = Regexp.compile('(.+)\s+\[(.+)\]\s+(.+)\s+(.+)\s+"(.+)"')
  
  @@log_dir="/var/log/breadcrumbs/"
  def self.log_dir; @@log_dir end
 
  @@progress_file = @@log_dir+"/progress.txt"
  @@error_file = @@log_dir + "/errors.txt"
 
  # How often to record (in lines) how far we are into the log file
  @@progress_frequency=5
  
#------------------------------------------------------------------------------

  def self.process_line(line,project_id=nil)
    t = Time.now
    if @@log_line_regex.match(line)
      id = parse_project_id($3).to_i
      #project_id=nil
      # Only process stats from a single account if that option is in effect
      unless project_id.nil?
        return if id!=project_id
      end
      
      begin        
        project = Project.find(id)
        if !project.nil?
          ip          = $1
          time        = parse_time($2, project)
          referer_url = parse_referer($3)
          unique      = parse_unique($3)
          landing_url = $4
          browser     = parse_browser($5)
          os          = parse_os($5)

          strip_protocol(referer_url)
          strip_protocol(landing_url)
          request = ApacheRequest.new(ip, time, landing_url, referer_url, unique, browser, os)
          
          request.save( project )
        end

      rescue ActiveRecord::RecordNotFound
        #puts "Couldn't find project #{id} from: " + line

      rescue Exception => e
        puts "Unhandled exception for line: " + line
        puts e.message
        puts e.backtrace.inspect
      end
    end
  end

#------------------------------------------------------------------------------


  def self.tail_log(logfile, noresume=true, project_id=nil, notail=nil)
    puts "Parsing log file:  #{logfile.to_s}\n  Logging to #{ENV['RAILS_ENV'] || 'development'} database."
    file = File.new(logfile, "r")

    # Allow our thread to exit under normal TERM and INT signals
    exited=false    
    Signal.trap("TERM") do
      exited=true
    end
    Signal.trap("INT") do
      exited=true
    end
    
    
    #
    # Try and resume into the log file if we need to
    #    
    count=1
    if (noresume)
      puts "Starting at the beginning of the log file"
      # Back up the old progress file in case we wanted to run
      # with 'resume' enabled but forgot to.
      `cp #{@@progress_file} #{@@progress_file}.bak 2> /dev/null`
    else
      count=load_progress
      puts "Resuming #{count} lines into the log file"
      $stdout.flush
      skip_ahead(file,count)
      puts "Done seeking ahead into the log file. Starting to read."
    end

    $stdout.flush

    while (!exited)
      begin
        line = file.gets
        if !line.nil?
          process_line(line,project_id)
          
          count+=1
          record_progress(count) if (count % @@progress_frequency==0)
        elsif notail != nil
          break
        else
          sleep 1
        end
      rescue Exception=>e
        # Let exceptions from TERM and INT signals go through, like (ctrl+C)
        raise e if (e.class==Interrupt || e.class==SystemExit)
        
        # otherwise, log the error for later analysis
        f=File.new @@error_file, 'a'
        err="#{count} : #{e}\n for this line: #{line}"
        err += "\nBacktrace\n#{e.backtrace}"
        f.puts err
        puts err
        f.close()
      end
    end
    
  ensure
    file.close() unless file.nil?
  end
  
  #------------------------------------------------------------------------------
  
  # Load how far we've read into the log file, so we can start from there
  def self.load_progress
    count=0
    if (FileTest.exists? @@progress_file)
      f=File.open @@progress_file, "r"
      count=f.read.strip.to_i
      f.close()      
    end
    return count
  end
  
  # Record how are we are into the log file
  def self.record_progress(count)
    f=File.new @@log_dir + "/progress.txt", "w"
    f.write count
    f.close()
  end
  
  # Skip n lines into the log file
  def self.skip_ahead(file,n)    
    (n-1).times do
      file.gets
    end
  end
  
  #------------------------------------------------------------------------------
  
  def self.benchmark_log(logfile)
    puts "Parsing log file: " + logfile
    log_lines=0
    #Benchmark.bmbm("processing the whole log") do |x|
    times=Benchmark.bm do |x|
      x.report do
        log_lines=0
        file = File.new(logfile, "r")
        line=""
        while (!line.nil?)
          line = file.gets
          next if line.nil?
          #Benchmark.benchmark("process line") do |x|
            #x.report { process_line(line) }
            process_line(line)
          #end
          log_lines+=1
        end
        file.close
        file=nil
      end

    end
    #reqs=(log_lines/times[0].real).floor
    #puts "processed #{log_lines} lines, at #{reqs} req/s"
  end
#------------------------------------------------------------------------------
  include TimeHelpers
  def self.parse_time(time_string, project)
    @@time_regex = Regexp.compile('^(\d{4}) (\d\d) (\d\d) (\d\d) (\d\d) (\d\d)$')
    if @@time_regex.match(time_string)
      time = Time.local($1, $2, $3, $4, $5, $6)

      return project.time(time)
    end
  end

#------------------------------------------------------------------------------
  @@os_hash = {
    'Windows NT 5.0' => 'os_nt',
    'Windows NT 5.1' => 'os_nt',
    'Windows NT 5.2' => 'os_nt',
    'Windows NT 6.0' => 'os_vista',
    'Windows 98' => 'os_9x',
    'Windows 95' => 'os_9x',
    'Linux' => 'os_linux',
    'Mac OS X' => 'os_macosx',
    'Other' => 'os_other'
  }

  def self.parse_os(user_agent)
    user_agent.match(/(Windows NT 5.0|Windows NT 5.1|Windows NT 5.2|Windows NT 6.0|Windows 98|Windows 95|Linux|Mac OS X)/);
    os = $1 || "Other"
    return @@os_hash[os]
  end

#------------------------------------------------------------------------------

  @@browser_hash = {
    'Firefox/1.5' => 'b_firefox',
    'Firefox/2.0' => 'b_firefox',
    'MSIE 5' => 'b_ie5_6',
    'MSIE 6.0' => 'b_ie5_6',
    'MSIE 7.0' => 'b_ie7',
    'Safari' => 'b_safari',
    'Other' => 'b_other'
  }
  
  
  @@browser = Regexp.compile('.*(Firefox\/1.5|Firefox\/2\.0|MSIE 6.0|MSIE 5|MSIE 7.0|Safari).*')
  def self.parse_browser(user_agent)
    @@browser.match(user_agent)
    browser = $1 || "Other"
    return @@browser_hash[browser]
  end

#------------------------------------------------------------------------------
  
  @@referer = Regexp.compile('[&\?]r=([A-Za-z0-9\/:+%\.\-_]+)')
  def self.parse_referer(query)
    #puts "----Before: #{query}"
    @@referer.match(query)
    #puts "----After: #{$1}"
    return $1
  end

#------------------------------------------------------------------------------
  
  @@unique = Regexp.compile('[&\?]u=([0-9])')
  def self.parse_unique(query)
    @@unique.match(query)
    if !$1.nil?
      return $1.to_i == 1
    else
      return false
    end
  end

#------------------------------------------------------------------------------

  @@project = Regexp.compile('[&\?]p=([0-9]+)')
  def self.parse_project_id(query)
    @@project.match(query)
    return $1 || "none"
  end

#------------------------------------------------------------------------------

  def self.strip_protocol(url)
    if !url.nil?
      if url =~ /^http:\/\//
        url.slice!(0..6)
      elsif url =~ /http%3A\/\//
        url.slice!(0..8)
      end

      if url =~ /^www\./
        url.slice!(0..3)
      end

      if url =~ /^[A-Za-z0-9\.\-]+$/
        url << '/'
      end
    end
    return nil
  end

  def self.strip_server_url(project, url)
    if !url.nil?
      if url =~ /^#{project.url}/
        url.slice!(0..project.url.length-2)
      end
    end
    return nil
  end
end

#
# Ensures that the log directory where we store our progress (usually /var/log/breadcrumbs)
# exists and we can write to it
# 
def check_logger_setup()
  log_dir=ApacheLogReader::log_dir
  # Make sure we can record our progress
  if (! FileTest.exists? log_dir)
    `mkdir #{log_dir}`
  end
  if (! FileTest.exists? log_dir)
    puts "Trying to create #{log_dir} with sudo:"
    
    user = `whoami`.strip
    puts "chown -R #{user}:#{user} #{log_dir}"
    `sudo mkdir #{log_dir}`
    # Make sure the current user can write to it
    `sudo chown -R #{user}:#{user} #{log_dir}`
  end
  if (! FileTest.exists? log_dir)
    puts "Couldn not create util folder for logreader. Exiting."
    exit      
  end
    
end
