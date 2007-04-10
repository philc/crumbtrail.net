#!/usr/bin/env ruby

#
# Creates the databases in mysql, and grants access to the databases to the accounts listed in
# config/databases.yml
# 
# * requires sudo
#

require 'yaml'
APP_PATH=File.dirname(__FILE__) + '/../../'
  

def mysqlcreate(db)
  `sudo mysql -e "create database #{db};"`
end

def mysqlgrant (db,user,pass)
  cmd="GRANT ALL PRIVILEGES ON #{db}.* TO '#{user}'@'localhost' identified by '#{pass}' with grant option;";
  `sudo mysql -e "#{cmd}"`
end



c=YAML::load(File.open(APP_PATH+'config/database.yml'))

["development","test","production"].each do |env|
  mysqlcreate(c[env]["database"])
  mysqlgrant(c[env]["database"], c[env]["username"], c[env]["password"])
end