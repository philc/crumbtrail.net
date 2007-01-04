#!/usr/bin/env ruby
require "vendor/rails/activerecord/lib/active_record.rb"
require "app/models/account.rb"
require "app/models/project.rb"
require "app/models/zone.rb"
require "app/models/server.rb"

def establish_connection()
  f=YAML::load(File.open('config/database.yml'))
  args={}
  env="development"
  f[env].map{ |k,v| args[k.intern]=v}

  ActiveRecord::Base.establish_connection(args)
end

def add
  puts "Creating accounts and projects..."
  mikequinn = Account.create(:username   => "mikequinn",
                             :password   => "pass1",
                             :firstname  => "Michael",
                             :lastname   => "Quinn",
                             :country_id => 1,
                             :zone_id   => 1) 
                             
  test  = Account.create(:username => "a@b.c", 
    :password => "password",
    :firstname => "",  
    :lastname=>"",
    :country_id=>1,
    :zone_id=>1
  )
                            
  demo = Account.create(:username   => "demo",
                         :password   => "pass1",
                         :firstname  => "Demo",
                         :lastname   => "Account",
                         :country_id => 1,
                         :zone_id   => 1,
                         :role=>"d")
                         
                         
  proj = Project.new(:account => demo,
                     :title => "Ninja Words",
                     :url => "ninjawords.com/",
                     :zone_id => demo.zone_id)
  proj.id = 1050
  proj.save
  
  puts "Creating Time zone info..."
  
  est = Zone.new(:identifier => 'US/Eastern')
  est.id = 1
  est.save
  
  pac = Zone.new(:identifier => 'US/Pacific')
  pac.id = 2
  pac.save
  
  server = Server.new(:zone_id => 1)
  server.id = 1
  server.save
  
  puts "done"
end
  
def drop
  puts "Deleting text accounts and projects..."
  Account.delete_all "username = 'mikequinn'"
  Account.delete_all "username = 'philc'"
  Project.delete(1050)
  puts "done"
end

establish_connection()
if ARGV.size == 1
  drop
else
  add
end
