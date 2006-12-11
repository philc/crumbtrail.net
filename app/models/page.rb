class Page < ActiveRecord::Base
  has_many :total_referrals

  def self.find_by_url(url)
    pages = find(:all, :conditions => ['url_hash = ?', url.hash])
    for id in pages
      return id if id.url = url
    end

    return nil
  end

  def self.get_page(url)
    page = find_by_url(url)
    page = create(:url_hash => url.hash, :url => url) if page.nil?
    return page
  end
end
