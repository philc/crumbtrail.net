#!/usr/bin/env ruby

#You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"
require File.dirname(__FILE__) + "/../../logreader/logreader.rb"

@configfile = File.dirname(__FILE__) + "/../../config/logreader.yml"

$running = true;
Signal.trap("TERM") do 
  $running = false
end

while($running) do

  cfgfile = File.open(@configfile, 'r');
  config = YAML::load(cfgfile)
  
  logfile = config[:logfile]
  resume  = true
  
  ApacheLogReader::tail_log(logfile, true)
  
  sleep 10
end