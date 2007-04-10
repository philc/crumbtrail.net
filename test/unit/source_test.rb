require File.dirname(__FILE__) + '/../test_helper'

require_dependency 'source'

class SourceTest < Test::Unit::TestCase
  #fixtures :countries



  # Search URLS to parse
  @@yahoo=[
    "http://search.yahoo.com/search?p=lackluster definition&rs=0&fr2=rs-top&toggle=1&cop=mss&ei=UTF-8&fr=yfp-t-501",
    "http://yq.search.yahoo.com/search?p=gregarious synonyms&ei=UTF-8&fr=yq-tb&yq=1&x=wrt&p=1050&u=1&c=7718"
  ]
  @@google=[
    "http://www.google.com/search?hl=en&safe=off&q=predictable definition&p=1050&u=1&c=6671"
  ]
  @@msn=[
    "http://search.msn.com.tr/results.aspx?q=ninjawords&FORM=MSNH&p=1050&u=1&c=168"
  ]
  
  def test_search_analyze_url
    (@@yahoo+@@google+@@msn).each do |q|
      assert_not_nil(Search.analyze_url(q), q)
    end

  end
end
