#!/usr/bin/env ruby
#
# Usage:
#   startogreader.rb [nameOfLog] [-noresume] [-p=1050] [-notail]
#     
#     nameOfLog 
#       should reside in script/log/. 
#       Otherwise the default log gets used (/var/log/apache2/stats.crumbtrail/access.log)
#     -noresume 
#       forces the logreader to start at the beginning of the log
#     -p=projectID
#       only process log files that are from a certain project
#     -notail
#       Exit when the logreader hits the end of the file
#
ENV["RAILS_ENV"] ||= "development"

class Hash
  def with_symbols!
    self.keys.each{|key| self[key.to_s.to_sym] = self[key] }; self
  end
end

APP_PATH=File.dirname(__FILE__) + '/../'
require APP_PATH + "/config/environment"
require APP_PATH + "/logreader/logreader.rb"

@configfile=APP_PATH+"config/logreader.yml"
@defaultlog="/var/log/apache2/stats.crumbtrail/access.log"


def log_to_process()
  logfile = ARGV[0]
  script_dir=APP_PATH+"script/"

  # If a logfile wasn't specified on the command line, check the config file
  if (logfile.nil?)
    if @options[:logfile].nil?
      logfile = @defaultlog
    else
      if FileTest.exists?(@options[:logfile])
        return @options[:logfile]
      else
        raise "Log file #{@options[:logfile]} doesn't exist"
      end
    end
  end
  
  # First try the file outright, e.g. /var/log/apache2/access.log
  # Then try ./script/testlogs, which is where the main testing logs are
  # Then try ./script/log, which are where custom downloaded logs are

  return logfile if (FileTest.exists? logfile )
  return script_dir+"testlogs/#{logfile}" if (FileTest.exists?(script_dir+"testlogs/#{logfile}"))
  return script_dir+"log/#{logfile}" if (FileTest.exists?(script_dir+"log/#{logfile}"))
  raise "Log file #{logfile} doesn't exist" if !logfile.nil?
end

#
# Strips an option out of the command line args. So 
# strip_arg('-noresume') would return -noresume and remove it from ARGV.
# Passing in a regex will use that pattern to find the option and return
# the result of any grouping, e.g. strip_arg(/p=(\d+)/) would return the value of \d+
#
def strip_arg(pattern)
  if (pattern.class==Regexp)
    for a in ARGV
      m = a.match(pattern)
      return m[1] unless m.nil?
    end
    return nil
  else
    ARGV.delete(pattern)
  end
end

check_logger_setup()

@options = YAML.load( ERB.new( IO.read(@configfile) ).result ).with_symbols!

# Check if -resume option was supplied, and if so remove it from CLI
noresume   = strip_arg("-noresume")
notail     = strip_arg("-notail")
project_id = strip_arg(/-p=(\d+)/)
logfile    = log_to_process()

#ApacheLogReader::benchmark_log("script/testlogs/" + logfile)
ApacheLogReader::tail_log(logfile, noresume, project_id, notail)
