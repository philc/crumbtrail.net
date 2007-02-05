class Page < ActiveRecord::Base
  belongs_to :project
  has_many   :referers

  def self.find_by_url(project, url)
    pages = find_all_by_project_id_and_url_hash(project.id, url.hash)
    for id in pages
      return id if id.url = url
    end

    return nil
  end

  def self.get_page(project, url)
    page = find_by_url(project, url)
    page = create(:project => project, :url_hash => url.hash, :url => url) if page.nil?
    return page
  end
end
