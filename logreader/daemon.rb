#!/usr/bin/env ruby
#
# logreader daemon
#
# Usage: daemon start|stop|restart [logFile]
#   logfile defaults to /var/log/apache2/stats.crumbtrail/access.log
#

#You might want to change this

@APP_PATH=File.dirname(__FILE__)+"/.."

require 'rubygems'
require 'daemons' 
require 'yaml'
require 'erb'
require @APP_PATH+"/logreader/logreader.rb"

@startlogfile = @APP_PATH+"/logreader/startlogreader.rb"
@defaultlog   = '/var/log/apache2/stats.crumbtrail/access.log'

@options = {
  :app_name   => "logreader",
  :multiple   => false,
  :backtrace  => true,
  :monitor    => false,
  :log_output => true
}

Daemons.run(@startlogfile, @options)