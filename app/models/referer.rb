class Referer < ActiveRecord::Base
  belongs_to :project

  def self.find_by_url(project, url)
    referers = find_all_by_project_id_and_url_hash(project.id, url.hash)
    for id in referers
      return id if id.url = url
    end

    return nil
  end

  def self.get_referer(project, url)
    referer = find_by_url(project, url)
    referer = create(:project => project, :url_hash => url.hash, :url => url) if referer.nil?
    return referer
  end
end
