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

def generate_test_ranks(proj)
  proj.queries.each do |query|
    [:google, :yahoo, :msn].each do |engine|
      
      date = Date.today-14
      lastRank = nil
      rank = 1 + rand(20)
     
      while (date <= Date.today)
        delta = lastRank-rank unless lastRank.nil?

        # if there has been a change in rank, record it
        if delta != 0
          ranking = Ranking.new(:project     => proj,
                                :query       => query,
                                :engine      => engine.to_s[0].chr,
                                :rank        => rank,
                                :search_date => date);
          ranking.delta = delta unless delta.nil?
          ranking.save
        end
        
        # randomize the next rank
        lastRank = rank
        rank = rank + (-5 + rand(9))
        rank = 1 if rank < 1

        # randomize the next date a change is recorded
        date = date + 1 + rand(3)
      end
    end
  end
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
                      :zone=>z,
                      :role=>"a") 
  
  proj = Project.new(:account => mikeq,
                     :title => "Personal Site",
                     :url => "mikequinn.org/",
                     :zone => mikeq.zone)
  proj.add_query("mike quinn")
  proj.add_query("mike quinn blog")
  proj.add_query("michael quinn")
  proj.add_query("google interview")
  proj.id = 1051
  proj.save

  generate_test_ranks(proj)

  test  = Account.create(:username => "a@b.c", 
    :password => "password",
    :firstname => "",  
    :lastname=>"",
    :last_access=>Date.today,
    :country_id=>1,
    :zone=>z
  )

  # This is the "real owner" of the ninjawords account                            
  philc = Account.create(:username   => "philc",
                         :password   => "pass1",
                         :firstname  => "Phil",
                         :lastname   => "Crosby",
                         :last_access => Date.today,
                         :country_id => 1,
                         :zone_id   => z.id,
                         :role=>"a")
                         
                         
  proj = Project.new(:account => philc,
                     :title => "Ninja Words",
                     :url => "ninjawords.com/",
                     :zone => philc.zone)
  proj.add_query("ninja words")
  proj.add_query("fast dictionary")
  proj.add_query("incontravertible")
  proj.add_query("ninjawords.com")
  proj.id = 1050
  proj.save
  
  demo = Account.create(:username=>"demo",
                    :password => "pass1",
                    :firstname=>"Demo",
                    :lastname=>"Account",
                    :last_access => (Date.today-3),
                    :country_id=>1,
                    :zone_id=>z.id,
                    :role=>"d"
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
