#!/usr/bin/env ruby

#You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../config/environment"
require File.dirname(__FILE__) + "/ranklib.rb"

@rankdir = File.dirname(__FILE__) + "/../tmp/rankengine/"
@termsfilename = @rankdir + "querylist"
@resultsfilename = @rankdir + "resultslist"

while(true) do
  
  ActiveRecord::Base.logger << "#{Time.now}: Calculating search ranks\n"
  
  if(! FileTest.exists? @rankdir)
    FileUtils.mkdir(@rankdir, :mode => 0755)
  end
  
  termsFileName = "#{@termsfilename}.#{Date.today.to_s}"
  resultsFileName = "#{@resultsfilename}.#{Date.today.to_s}"
  
  # Read the list of queryies we need to make from
  # our database, and store them in a file
  file = File.open(termsFileName, 'w')
  write_terms_file(file)
  file.close()

  # Now, read that file and perform the queries.
  # Store the results in another file.
  termsfile = File.open(termsFileName, 'r')
  resultsfile = File.open(resultsFileName, 'w')
  get_rankings(termsfile, resultsfile, false)
  termsfile.close()
  resultsfile.close()

  # Read the result file and store the ranks back in
  # our database.
  resultsfile = File.open(resultsFileName, 'r')
  store_rank_results(resultsfile)
  resultsfile.close()
  
  # Sleep in one hour increments until we hit the next day
  date = Date.today
  while( date == Date.today && $running )
    sleep( 3600 )
    ActiveRecord::Base.logger << "#{Time.now}: Rank engine waking up to see if a day has passed"
  end  
  
end