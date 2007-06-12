#!/usr/bin/env ruby
require 'rubygems'
require 'active_record'
require 'yaml'
require 'date'
require 'app/models/ranking.rb'

@filename = "searchparser/searchresults"

def establish_connection()
  f=YAML::load(File.open('config/database.yml'))
  args={}
  env=ENV['RAILS_ENV'] || 'development'
  f[env].map{ |k,v| args[k.intern]=v}

  ActiveRecord::Base.establish_connection(args)
end

def save_query_ranks(pid, query, rankhash)
  rankhash.each_pair do |engine, rank|
    enginechr = engine.to_s[0].chr
    ranking = Ranking.find(
      :first,
      :conditions => ['project_id = ? and engine = ? and query = ?',
                      pid, enginechr, query],
      :order      => "search_date DESC")

    if ranking.nil? || ranking.rank != rank
      newrank = Ranking.new(:project_id  => pid,
                            :query       => query,
                            :engine      => enginechr,
                            :rank        => rank,
                            :search_date => Date.today)
      newrank.save!
    end
  end
end

def save_rankings(file)
  results = YAML::load(file)
  results.each_pair do |pid, rankings_hash|
    rankings_hash.each_pair do |query, rank_hash|
      save_query_ranks(pid, query, rank_hash)
    end
  end
end

establish_connection()
@filename = ARGV[0] if ARGV[0]
file = File.open(@filename, "r")
save_rankings(file)
file.close
