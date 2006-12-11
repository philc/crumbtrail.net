class Referer < ActiveRecord::Base
  has_many :recent_referrals
  has_many :total_referrals
  has_many :landing_urls

  def self.find_by_url(url)
    referers = find(:all, :conditions => ['url_hash = ?', url.hash])
    for id in referers
      return id if id.url = url
    end

    return nil
  end

  def self.get_referer(url)
    referer = find_by_url(url)
    referer = create(:url_hash => url.hash, :url => url) if referer.nil?
    return referer
  end
end
