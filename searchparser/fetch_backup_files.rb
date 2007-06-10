#!/usr/bin/env ruby
require 'yaml'
require 'searchparser/fetcher.rb'

@infile = "searchparser/searchterms"

def save_backups(infile)
  projects = YAML::load(infile)
  projects.each_pair do |pid, data|
    fetcher = Fetcher.new(pid)
    fetcher.save_test_files(data[:queries])
  end
end

@infile = ARGV[0] if ARGV[0]
file = File.open(@infile, "r")
save_backups(file)
file.close
