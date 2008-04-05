#!/usr/bin/env ruby
require "vendor/rails/activerecord/lib/active_record.rb"
require "app/models/account.rb"
require "app/models/project.rb"
require "app/models/zone.rb"
require "app/models/server.rb"
require "app/models/ranking.rb"

def establish_connection()
  f=YAML::load(File.open('config/database.yml'))
  args={}
  env=ENV['RAILS_ENV'] || 'development'
  f[env].map{ |k,v| args[k.intern]=v}

  ActiveRecord::Base.establish_connection(args)
end

def add
  puts "Creating accounts and projects..."
  
  z=Zone.find_by_identifier('US/Eastern')
  
  mikeq = Account.new(:username    => "mikeq",
                      :password    => "pass1",
                      :firstname   => "Michael",
                      :lastname    => "Quinn",
                      :last_access => Date.today,
                      :country_id => 1,
                      :zone => z,
                      :role => "a") 
  
  proj = Project.new(:account => mikeq,
                     :title => "Personal Site",
                     :url => "mikequinn.org/",
                     :zone => mikeq.zone)
  proj.id = 1051
  proj.save

  test  = Account.create(:username => "a@b.c", 
                         :password => "password",
                         :firstname => "",  
                         :lastname => "",
                         :last_access => Date.today,
                         :country_id => 1,
                         :zone => z)

  # This is the "real owner" of the ninjawords account                            
  philc = Account.create(:username   => "philc",
                         :password   => "pass1",
                         :firstname  => "Phil",
                         :lastname   => "Crosby",
                         :last_access => Date.today,
                         :country_id => 1,
                         :zone_id   => z.id,
                         :role => "a")
                         
                         
  proj = Project.new(:account => philc,
                     :title => "Ninja Words",
                     :url => "ninjawords.com/",
                     :zone => philc.zone)
  proj.id = 1050
  proj.save

  demo = Account.create(:username=>"demo",
                    :password => "pass1",
                    :firstname => "Demo",
                    :lastname => "Account",
                    :last_access => (Date.today - 3),
                    :country_id => 1,
                    :zone_id => z.id,
                    :role => "d"
                    )
  
  # puts "Creating Time zone info..."
  # 
  # est = Zone.new(:identifier => 'US/Eastern')
  # est.id = 1
  # est.save
  # 
  # pac = Zone.new(:identifier => 'US/Pacific')
  # pac.id = 2
  # pac.save
  

  
  puts "done"
end
  
def drop
  puts "Deleting text accounts and projects..."
  Account.delete_all "username = 'mikequinn'"
  Account.delete_all "username = 'a@b.c'"
  Account.delete_all "username = 'philc'"
  Account.delete_all "username = 'demo'"
  Project.delete(1050)
  puts "done"
end

establish_connection()
if ARGV.size == 1
  drop
else
  add
end
