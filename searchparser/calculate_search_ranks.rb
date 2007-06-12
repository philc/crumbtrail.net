#!/usr/bin/env ruby
require 'yaml'
require 'lib/cmdline_helpers.rb'
require 'searchparser/fetcher.rb'

@infile = "searchparser/searchterms"
@outfile = "searchparser/searchresults"

def save_rankings(infile, outfile, fromfile)
  output = {}
  projects = YAML::load(infile)
  projects.each_pair do |pid, data|
    fetcher = Fetcher.new(pid)
    results = fetcher.fetch_results(data[:queries], fromfile)

    output[pid] = {}
    results.each do |result|
      result.each do |r|
        rank = r.get_rank(data[:domain])
        
        output[pid][r.query] = {} if output[pid][r.query].nil? && !rank.nil?
        output[pid][r.query][r.engine] = rank unless rank.nil?
      end
    end
  end

  outfile.puts(output.to_yaml)
end

fromfiles = strip_arg('-fromfiles')
infile = File.open(@infile, "r")
outfile = File.open(@outfile, "w")
save_rankings(infile, outfile, !fromfiles.nil?)
infile.close
outfile.close

