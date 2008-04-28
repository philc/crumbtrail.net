class Page < ActiveRecord::Base
  belongs_to :project

  def self.find_by_url(project, url)
    pages = find(:all,
                 :conditions => ['project_id = ? AND url_hash = ?', project.id, url.hash])

    for id in pages
      return id if (id.url == url)
    end

    return nil
  end

  def self.get_or_new_page(project, url)
    return nil if !is_internal_referer(project, url)

    page = find_by_url(project, url)
    page = new(:project => project, :url_hash => url.hash, :url => url) if page.nil?

    page.count += 1

    return page
  end

  def self.get_or_create_page(project, url)
    page = get_or_new_page(project, url)
    page.save

    return page
  end
  
  def self.get_most_popular(project, limit)
    return find(:all,
                :conditions => {:project_id=>project.id},
                :limit => limit,
                :order => "count DESC")
  end

  def self.is_internal_referer(project, ref)
    url = project.url
    url = url.first(url.length-1) if url.ends_with?("/")
    
    return ref.starts_with?(url)
  end

end
