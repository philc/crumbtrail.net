#!/usr/bin/env ruby
#
# logreader daemon
#
# Usage: daemon start|stop|restart [logFile]
#   logfile defaults ot /var/log/apache2/stats.crumbtrail/access.log
#

LOGREADER_PATH=File.dirname(__FILE__) + '/'

module LogReader
  class Daemon
    def self.start
      log = ARGV[1] || "/var/log/apache2/stats.crumbtrail/access.log"
      pids = pid_of_reader()
      if (pids.length>0)
        puts "LogReader is already running as process #{pids.flatten}"
        return
      end
      # don't wait for this to finish; run it in its own subprocess
      exec("nohup ./logreader.rb #{log}  -resume > /tmp/nohup &") if fork.nil?
      
      # Show the initial output from the logreader
      puts `cat /tmp/nohup`
      
      puts "started"      
    end
    
    def self.stop
      pids = pid_of_reader()
      if pids.length<=0
        puts "LogReader doesn't appear to be running"
        return true
      end

      if pids.length>1
        puts "There are #{pids.length} logReader processes running. Killing them all"
      end

      for pid in pids do
        `kill #{pid}`
      end
      puts "stopped"
      
      # If we failed to stop something, return an error condition
      pids = pid_of_reader()
      if pids.length>0
        puts "failed to kill #{pids.length} processes" 
        return false
      end
      
      return true            
    end
    
    def self.restart
      # If we fail to stop something, don't start another process
      if (!stop())
        puts "failed to stop the process; not starting another one"
        return
      end
      start()
    end
    
    
    def self.pid_of_reader
      pidof('ruby ./logreader')
    end
    
    #
    # a version of pidof that matches against the full process name, not just the program.
    # e.g. it can differentiate between "ruby" and  "ruby ./logreader"
    def self.pidof(proc)
      # each match is on its own line. The first col is the proc number.

      # reject out any procs that contain grep in them, because that's probably the process
      # we're using to grep for our target proc anyway
      `ps ax | grep "#{proc}"`.reject{|line|line.index("grep")}.map{|line| line.split(' ')[0]}
    end
  end
end