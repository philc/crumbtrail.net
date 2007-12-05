#!/usr/bin/env ruby
#
# Usage:
#    ranktest.rb
# 
#   Running this file will:
#     1) get a list of queries to make from the database
#     2) perform the actual queries to MSN, Google, and Yahoo
#     3) save the results back to the database
#

ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../config/environment"
require 'ranklib.rb'

@termsfilename = File.dirname(__FILE__) + "/../tmp/termsfile"
@ranksfilename = File.dirname(__FILE__) + "/../tmp/ranksfile"

def save_backups(infile)
  projects = YAML::load(infile)
  projects.each_pair do |pid, data|
    fetcher = Fetcher.new(pid)
    fetcher.save_test_files(data[:queries])
  end
end

# Read the list of queryies we need to make from
# our database, and store them in a file
file = File.open(@termsfilename, 'w')
write_terms_file(file)
file.close()

# Now, read that file and perform the queries.
# Store the results in another file.
termsfile = File.open(@termsfilename, 'r')
ranksfile = File.open(@ranksfilename, 'w')
get_rankings(termsfile, ranksfile, false)
termsfile.close()
ranksfile.close()

# Read the result file and store the ranks back in
# our database.
ranksfile = File.open(@ranksfilename, 'r')
store_rank_results(ranksfile)
ranksfile.close()
