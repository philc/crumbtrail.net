#!/usr/bin/env ruby
require "rubygems"
require "active_record"
require "app/models/project.rb"

@filename = "searchparser/searchterms"

def establish_connection()
  f=YAML::load(File.open('config/database.yml'))
  args={}
  env=ENV['RAILS_ENV'] || 'development'
  f[env].map{ |k,v| args[k.intern]=v}

  ActiveRecord::Base.establish_connection(args)
end

def save_terms(file)
  terms = {}
  projects = Project.find_by_sql("select id,url,search_terms from projects")

  projects.each do |p|
    if (p.search_terms)
      terms[p.id] = { :domain => p.url, :queries => p.search_terms }
    end
  end

  file.puts(terms.to_yaml)
end

establish_connection()
@filename = ARGV[0] if ARGV[0]
file = File.new(@filename, "w")
save_terms(file)
file.close


