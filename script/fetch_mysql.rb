#!/usr/bin/env ruby

# usage is 
# fetch_mysql [environment]

# This script will connect to the remote server, dump its database, zip it, 
# and copy it locally into ./script/db/
# This allows you to quickly get a similar db to that of the server

require "yaml"


host="crumbtrail.net"

# If no env provided, assume production since we're copying from the server

env = ARGV[0]
env = "production" if env.nil?

puts "using environment '#{env}'"

# Parse credentials from env file
f=YAML::load(File.open('config/database.yml'))

v=f[env]

db = v["database"]
user = v["username"]
pass = v["password"]

# build a string that tells mysql to compres a table
compress="mkdir dbdump 2> /dev/null; " +
  "mysqldump -u#{user} -p#{pass} #{db} | gzip -cf > dbdump/#{db}.gz"


puts "compressing database file on server"
# execute the command remotely
puts `ssh #{user}@#{host} "#{compress}"`

puts "downloading db file from server"
`mkdir ./script/db 2> /dev/null`
puts `scp #{user}@#{host}:~/dbdump/#{db}.gz ./script/db/`