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
  
  def initialize(project, ip, time, url, referer_url, browser, os)
    @project = project
    @ip = ip
    @time = time
    @url = url
    @referer_url = referer_url
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

    @landing_url = LandingUrl.find_by_url(@url)
    @landing_url = LandingUrl.create(:url => @url) if @landing_url.nil?

    @project.increment_referer(self)
    @project.increment_hit_count(self)
  end
end

class ApacheLogReader
  
  @@regex = Regexp.new('(.*)\s+\[(.*)\]\s+(.*)\s+(.*)\s+"(.*)"\s+"(.*)"')
  @@browser_replacements = { "Windows NT 6.0" => "Vista",
                             "Windows NT 5.2" => "Win 2003",
                             "Windows NT 5.1" => "XP",
                             "Windows NT 5.0" => "Win 2000" }
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

      id = parse_project_id($3).to_i
      project = Project.find(id)

      if !project.nil?
        ip          = $1
        time        = parse_time($2, project)
        referer     = parse_referer($3)
        landing_url = $4
        browser     = parse_browser($5)
        os          = parse_os($5)

        request = ApacheRequest.new(project, ip, time, landing_url, referer, browser, os)
        request.save
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

      return TimeHelpers::convert_to_client_time(project, time)
    end
  end

#------------------------------------------------------------------------------

  def self.parse_os(user_agent)
    user_agent.match(/(Windows NT 5.0|Windows NT 5.1|Windows NT 5.2|Windows NT 6.0|Windows 98|Windows 95|Linux|Mac OS X)/);
    browser = $1 || "Other"
    browser = @@browser_replacements[browser] if browser.match(/Windows NT/)
    return browser
  end

#------------------------------------------------------------------------------

  def self.parse_browser(user_agent)
    user_agent.match(/.*(Firefox\/1.5|Firefox\/2\.0|MSIE 6.0|MSIE 5.5|MSIE 7.0|Safari).*/)
    return $1 || "Other"
  end

#------------------------------------------------------------------------------
  
  def self.parse_referer(query)
    query.match(/r=([A-Za-z0-9\/:%\.]+)/)
    return $1 || "none"
  end

#------------------------------------------------------------------------------

  def self.parse_project_id(query)
    query.match(/p=([0-9]+)/)
    return $1 || "none"
  end
end

# ApacheLogReader::establish_connection()
ApacheLogReader::tail_log("script/test.log")
