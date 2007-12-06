#!/usr/bin/env ruby
#
# rankengine daemon
#
# Usage: daemon start|stop|restart
#

require 'rubygems'
require 'daemons' 

@startrankengine = File.dirname(__FILE__)+"/startrankengine.rb"

@options = {
  :app_name   => "rankengine",
  :multiple   => false,
  :backtrace  => true,
  :monitor    => false,
  :log_output => true
}

Daemons.run(@startrankengine, @options)