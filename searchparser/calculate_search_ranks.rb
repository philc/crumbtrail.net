#!/usr/bin/env ruby
require 'yaml'
require 'script/parser.rb'

@infile = "searchterms"
@outfile = "searchresults"

Url = 0
Terms = 1

def save_rankings(infile, outfile)
  output = {}
  projects = YAML::load(infile)
  projects.each_pair do |id, p|
    parser = Parser.new(p[Url])
    parser.parse(p[Terms])
    results = parser.positions
    output[id] = results
  end

  outfile.puts(output.to_yaml)
end


@filename = ARGV[0] if ARGV[0]
infile = File.open(@infile, "r")
outfile = File.open(@outfile, "w")
save_rankings(infile,outfile)
infile.close
outfile.close

