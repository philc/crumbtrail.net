#!/usr/bin/ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'cgi'

@@url = "ninjawords.com"

class Parser

  @@num = 100 
  @@google = "http://www.google.com/search?q=%s&num=%n"
  @@yahoo = "http://search.yahoo.com/search?p=%s&n=%n"
  @@msn = "http://search.msn.com/results.aspx?q=%s"
  @@providers = {}

  def initialize(url)
    @url = url
    @@providers = { :google => method(:parse_google),
                    :yahoo => method(:parse_yahoo),
                    :msn => method(:parse_msn) }
  end

  def parse_google(words)
    querystr = @@google.gsub("%s", words).gsub("%n", @@num.to_s)
    doc = Hpricot(open(querystr))
    anchors = (doc/"a.l")

    links = []
    anchors.each do |anchor|
      links << anchor.attributes['href']
    end

    return links
  end

  def parse_yahoo(words)
    querystr = @@yahoo.gsub("%s", words).gsub("%n", @@num.to_s)
    doc = Hpricot(open(querystr))
    searchdiv = (doc/"div#yschweb")
    ems = (searchdiv/"em.yschurl")
    
    links = []
    ems.each do |em|
      links << "http://#{em.inner_text}"
    end

    return links
  end

  def parse_msn(words)
    @msncookie = "SRCHHPGUSR=NEWWND=0&ADLT=DEMOTE&NRSLT=#{@@num.to_s}&NRSPH=2&LOC=LAT%3d0.00|LON%3d0.00|DISP%3d&SRCHLANG="
    querystr = @@msn.gsub("%s", words)
    doc = Hpricot(open(querystr, "Cookie" => @msncookie))
    anchors = (doc/"div#results>ul>li>h3>a")

    links = []
    anchors.each do |anchor|
      links << anchor.attributes['href']
    end

    return links
  end

  def parse(queries)
    @results = {}
    queries.each do |query|
      query = CGI.escape(query)
      threads = []
      for provider in @@providers.keys
        threads << Thread.new(provider, query) do |p, q|
          Thread.current["provider"] = p
          Thread.current["results"] = @@providers[p].call(q)
        end
      end

      result = {}
      threads.each do |thr|
        thr.join
        puts thr["provider"]
        puts thr["results"]
        result[thr["provider"]] = thr["results"]
      end

      @results[query] = result
    end

    return @results
  end

  def positions
    unless (@results.nil?)
      positions = {}
      @results.each_key do |search|
        position = {}
        @results[search].each_pair do |provider, results| 
          
          results.each_index do |i|
            url = results[i]
            if url.match("^http://(www.)?#{@@url}")
              position[provider] = i+1
              break
            end
          end

        end
        positions[search] = position
      end

      return positions
    end
  end
end
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
