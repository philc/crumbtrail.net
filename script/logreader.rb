# #!/usr/bin/env ruby
# require "vendor/rails/activerecord/lib/active_record.rb"
# require "app/models/referer.rb"
# require "app/models/project.rb"
# require "app/models/server.rb"
# require "app/models/total_referral.rb"
# require "app/models/hourly_referral.rb"
# require "app/models/daily_referral.rb"
# require "app/models/recent_hit.rb"
# require "lib/rollable_time_table.rb"
# require 'lib/time_helpers.rb'

class ApacheRequest
  attr_reader   :project
  attr_reader   :time
  attr_reader   :referer
  attr_reader   :landing_url
  attr_reader   :unique
  attr_reader   :browser
  attr_reader   :os
  
  def initialize(project, ip, time, url, referer_url, unique, browser, os)
    @project = project
    @ip = ip
    @time = time
    @url = url
    @referer_url = referer_url
    @unique = unique
    @browser = browser
    @os = os
  end

#------------------------------------------------------------------------------

  def print
    puts "Client IP: #{@ip}"
    puts "Time: #{@time.to_s}"
    puts "Referer: #{@referer_url}"
    puts "Project Id: #{@project_id}"
    puts "Monitored Page: #{@landing_url}"
    puts "Browser: #{@browser}"
    puts "OS: #{@os}"
    puts "\n"
  end

#------------------------------------------------------------------------------

  def save
    @referer = Referer.find_by_url(@referer_url)
    @referer = Referer.create(:url => @referer_url) if @referer.nil?

    @landing_url = LandingUrl.find(:first, :conditions => ['project_id = ? AND url = ?', @project.id, @url])
    @landing_url = LandingUrl.create(:project_id => @project.id, 
                                     :url => @url, 
                                     :count => 0,
                                     :referer_id => @referer.id,
                                     :last_visit => @project.time) if @landing_url.nil?
    @landing_url.count += 1
    @landing_url.referer_id = @referer.id
    @landing_url.last_visit = @project.time
    @landing_url.save

    @project.increment_referer(self) if @referer_url != '/'
    @project.increment_hit_count(self)
    @project.increment_details(self)
  end
end

class ApacheLogReader

  @@regex = Regexp.new('(.+)\s+\[(.+)\]\s+(.+)\s+(.+)\s+"(.+)"')

#------------------------------------------------------------------------------

  def self.establish_connection()
    f=YAML::load(File.open('config/database.yml'))
    args={}

    f["development"].map{ |k,v| args[k.intern]=v}

    ActiveRecord::Base.establish_connection(args)
  end

#------------------------------------------------------------------------------

  def self.process_line(line)
    if @@regex.match(line)

      begin
        id = parse_project_id($3).to_i
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
          if !referer_url.match("^#{project.url}").nil?
            referer_url = '/'
          end

          strip_protocol(landing_url)
          #strip_server_url(project, landing_url)

          request = ApacheRequest.new(project, ip, time, landing_url, referer_url, unique, browser, os)
          request.save
        end

      rescue ActiveRecord::RecordNotFound
        puts "Couldn't find project : " + line
      end
    end
  end

#------------------------------------------------------------------------------

  def self.tail_log(logfile)
    puts "Parsing log file: " + logfile
    file = File.new(logfile, "r")
    while (1)
      line = file.gets
      if !line.nil?
        process_line(line)
      else
        sleep 1
      end
    end
  end

#------------------------------------------------------------------------------
  include TimeHelpers
  def self.parse_time(time_string, project)
    if time_string.match(/^(\d{4}) (\d\d) (\d\d) (\d\d) (\d\d) (\d\d)$/)
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
  
  def self.parse_browser(user_agent)
    user_agent.match(/.*(Firefox\/1.5|Firefox\/2\.0|MSIE 6.0|MSIE 5|MSIE 7.0|Safari).*/)
    browser = $1 || "Other"
    return @@browser_hash[browser]
  end

#------------------------------------------------------------------------------
  
  def self.parse_referer(query)
    query.match(/[&\?]r=([A-Za-z0-9\/:%\.]+)/)
    return $1 || '/'
  end

#------------------------------------------------------------------------------
  def self.parse_unique(query)
    query.match(/[&\?]u=([0-9])/)
    if !$1.nil?
      return $1.to_i == 1
    else
      return false
    end
  end

#------------------------------------------------------------------------------

  def self.parse_project_id(query)
    query.match(/[&\?]p=([0-9]+)/)
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

      if url =~ /www\./
        url.slice!(0..3)
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

# ApacheLogReader::establish_connection()
#ApacheLogReader::tail_log("script/test.log")
#ApacheLogReader::tail_log("script/test-long.log")
ApacheLogReader::tail_log("/var/log/apache2/stats.crumbtrail/access.log")
