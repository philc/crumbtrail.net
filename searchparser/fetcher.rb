#!/usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'cgi'
require 'fileutils'
require 'active_record'
require File.dirname(__FILE__) + "/../app/models/project.rb"
require File.dirname(__FILE__) + "/../app/models/ranking.rb"

Num = 100

class RankFinder
  attr_reader :results
  attr_reader :query
  attr_reader :engine

  def initialize(engine, query)
    @results = []
    @engine = engine
    @query = query
  end

  def <<(result)
    @results << result
  end

  def get_rank(url)
    format_url(url)

    i = 1
    @results.each do |result|
      return i if result.match("^http://(www.)?#{url}")
      i += 1
    end

    return nil
  end

  private

  def format_url(url)
    url.chop! while url[url.length-1].chr == '/'
  end
end

#------------------------------------------------------------------------------

class Engine
  @fromfile = false

  def initialize(enginename, id, fromfile)
    @enginename = enginename
    @id = id
    @fromfile = fromfile
  end

  protected

  def get_source(querystr, query, cookie)
    if @fromfile
      return get_test_file(query, :read)
    else
      if (cookie)
        return open(querystr, "Cookie" => cookie)
      else
        return open(querystr)
      end
    end
  end

  def get_test_file(query, mode)
    dirname = "searchparser/results/#{@id.to_s}/#{query}"
    filename = "#{dirname}/#{@enginename}"
    FileUtils.mkpath(dirname) unless File.exists?(dirname)

    case mode
      when :read
        return File.open(filename, "r")
      when :write
        return File.new(filename, "w")
    end
  end

  def save_test_file(querystr, query, cookie)
    file = get_test_file(query, :write)
    if (cookie)
      uri = open(querystr, "Cookie" => cookie)
    else
      uri = open(querystr)
    end
    uri.each_line { |x| file.puts x }
    file.close
  end

end

#------------------------------------------------------------------------------

class Google < Engine 
  @@url = "http://www.google.com/search?q=%s&num=%n"
  
  def initialize(id, fromfile)
    super(self.class.name, id, fromfile)
  end

  def fetch(query)
    begin
      doc = Hpricot(get_source(build_query_str(query), query, nil))
      anchors = (doc/"a.l")

      rankFinder = RankFinder.new(:google, query)
      anchors.each do |anchor|
        rankFinder << anchor.attributes['href']
      end
    rescue OpenURI::HTTPError
      puts "Error querying google."
    end

    return rankFinder
  end

  def save_test_file(query)
    super(build_query_str(query), query, nil)
  end

  protected

  def build_query_str(query)
    return @@url.gsub("%s", query).gsub("%n", Num.to_s)
  end
end

#------------------------------------------------------------------------------

class Yahoo < Engine 
  @@url = "http://search.yahoo.com/search?p=%s&n=%n"
  
  def initialize(id, fromfile)
    super(self.class.name, id, fromfile)
  end

  def fetch(query)
    begin
      doc = Hpricot(get_source(build_query_str(query), query, nil))
      searchdiv = (doc/"div#yschweb")
      ems = (searchdiv/"em.yschurl")

      rankFinder = RankFinder.new(:yahoo, query)
      ems.each do |em|
        rankFinder << "http://#{em.inner_text}"
      end
    rescue OpenURI::HTTPError
      puts "Error querying yahoo."
    end

    return rankFinder
  end
  
  def save_test_file(query)
    super(build_query_str(query), query, nil)
  end

  protected

  def build_query_str(query)
    return @@url.gsub("%s", query).gsub("%n", Num.to_s)
  end

end

#------------------------------------------------------------------------------

class Msn < Engine
  @@url    = "http://search.msn.com/results.aspx?q=%s"
  @@cookie = "SRCHHPGUSR=NEWWND=0&ADLT=DEMOTE&NRSLT=#{Num.to_s}&NRSPH=2&LOC=LAT%3d0.00|LON%3d0.00|DISP%3d&SRCHLANG="

  def initialize(id, fromfile)
    super(self.class.name, id, fromfile)
  end

  def fetch(query)
    begin
      doc = Hpricot(get_source(build_query_str(query), query, @@cookie))
      anchors = (doc/"div#results>ul>li>h3>a")

      rankFinder = RankFinder.new(:msn, query)
      anchors.each do |anchor|
        rankFinder << anchor.attributes['href']
      end
    rescue OpenURI::HTTPError
      puts "Error querying msn."
    end

    return rankFinder
  end

  def save_test_file(query)
    super(build_query_str(query), query, @@cookie)
  end

  protected

  def build_query_str(query)
    return @@url.gsub("%s", query)
  end
end

#------------------------------------------------------------------------------

class Fetcher

  def initialize(uid)
    @uid = uid
  end

  def fetch_results(queries, fromfile)
    allresults = []
    queries.each do |query|
      query = CGI.escape(query)
      allresults << threaded_search(query, fromfile)
    end

    return allresults
  end

  def save_test_files(queries)
    queries.each do |query|
      query = CGI.escape(query)
      [Google, Yahoo, Msn].each do |engine|
        e = engine.new(@uid, false)
        e.save_test_file(query)
      end
    end
  end

  def self.one_shot_search(pid, query)
    #establish_connection() 
    p = Project.find(pid)
    
    unless p.nil?
      results = Fetcher.new(1051).fetch_results([query],false)

      # threaded_search returns an array of Ranking objects.
      # Save the results.
      results[0].each do |result|
        enginechr = result.engine.to_s[0].chr
        rank = result.get_rank(p.url)
        unless rank.nil?
          ranking = Ranking.find(
            :first,
            :conditions => ['project_id = ? and engine = ? and query = ?',
                            p.id, enginechr, query],
            :order      => "search_date DESC")

          if ranking.nil? || ranking.rank != rank
            newrank = Ranking.new(
              :project     => p,
              :query       => CGI.unescape(query),
              :engine      => enginechr,
              :rank        => rank,
              :search_date => Date.today)
              newrank.delta = ranking.rank - rank unless ranking.nil?
              newrank.save!
          end
        end
      end
    end
  end

  private

  def threaded_search(query, fromfile)
    threads = []
    threads << create_query_thread(Google, query, fromfile)
    threads << create_query_thread(Yahoo, query, fromfile)
    threads << create_query_thread(Msn, query, fromfile)

    results = []
    threads.each do |thr|
      thr.join
      results << thr["results"] if thr["results"]
    end

    return results
  end

  def create_query_thread(engine, query, fromfile)
    thread = Thread.new(engine, query) do |e, q|
      provider = e.new(@uid, fromfile)
      Thread.current["engine"] = e.name
      Thread.current["results"] = provider.fetch(q)
      #puts Thread.current["results"]
    end

    return thread
  end

end

#------------------------------------------------------------------------------

=begin
  def save_backups(userid, query)
    uri = open(@@google.gsub("%s", query).gsub("%n", @@num.to_s))
    save_results(userid, "google", uri)

    uri = open(@@yahoo.gsub("%s", query).gsub("%n", @@num.to_s))
    save_results(userid, "yahoo", uri)

    uri = open(@@msn.gsub("%s", query), "Cookie" => @@msncookie)
    save_results(userid, "msn", uri)
  end

  
  private

 end
=end

=begin
parser = Parser.new(@@url)
results = parser.parse(ARGV[0])
placement = parser.position()

#puts "Yahoo results:"
#i = 1
#results[:google].each do |x|
#  puts i.to_s + ": " + x
#  i += 1
#end

puts "results: "
results.each_key { |x| puts x }
puts "placement: "
placement.each_key { |x| puts x }

puts "Search placement:"
placement.each_pair do |key, value|
  puts "#{key.to_s} => #{value.to_s}"
end
=end
