require File.dirname(__FILE__) + '/../test_helper'

require_dependency 'source'

class SourceTest < Test::Unit::TestCase
  #fixtures :countries



  # Search URLS to parse
  @@yahoo={
    "http://search.yahoo.com/search?p=lackluster definition&rs=0&fr2=rs-top&toggle=1&cop=mss&ei=UTF-8&fr=yfp-t-501" =>"lackluster definition",
    "http://yq.search.yahoo.com/search?p=gregarious synonyms&ei=UTF-8&fr=yq-tb&yq=1&x=wrt"=>"gregarious synonyms"
  }
  @@google={
    "http://www.google.com/search?hl=en&safe=off&q=predictable definition&p=1050&u=1&c=6671" =>"predictable definition",
    "http://google.com/search?q=definition:+vulpes&hl=en&start=10&sa=N" => "definition: vulpes",
    "images.google.com/images?svnum=10&um=1&hl=en&q=paprika&btnG=Search Images" => "paprika"
  }
  @@msn={
    "http://search.msn.com.tr/results.aspx?q=ninjawords&FORM=MSNH&p=1050&u=1&c=168" => "ninjawords"
  }

  def test_search_analyze_url
    combined=@@yahoo.merge(@@google).merge(@@msn)

    combined.each do |url,terms|
      assert_equal(terms,Search.analyze_url(url))
    end


  end
end
