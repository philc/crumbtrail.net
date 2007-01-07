#!/usr/bin/env ruby

# usage is 
# fetch_log nameOfLog [lines]

# nameOfLog - filename to save the log file as. Goes into ./script/log
# lines - last n lines of the log file. Omit to get the whole log.

# This script will connect to the remote server, zip up the log file,
# and download it


require "yaml"

host="crumbtrail.net"
log_path = "/var/log/apache2/crumbtrail/access.log"

name = ARGV[0]
if (name.nil?)
  puts "Usage: fetch_log nameOfLog [lines]"
  exit
end

lines = ARGV[1]

# Decide whether to cat the file, or to use tail
cat_command = (lines.nil?) ? "cat" : "tail -n #{lines}"

dump="mkdir logdump 2> /dev/null; " +
  "#{cat_command} #{log_path} | gzip -cf > logdump/#{name}.log.gz"

puts "compressing log on server"

# execute the command remotely
puts `ssh #{host} "#{dump}"`

puts "downloading log from server"

`mkdir ./script/log 2> /dev/null`
puts `scp #{host}:~/logdump/#{name}.log.gz ./script/log/`
`gunzip ./script/log/#{name}.log.gz`