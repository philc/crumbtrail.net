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
        output[pid][r.query] = {} if output[pid][r.query].nil?
        output[pid][r.query][r.engine] = r.get_rank(data[:domain])
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

