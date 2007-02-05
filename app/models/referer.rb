class Referer < ActiveRecord::Base
  belongs_to :project
  belongs_to :page
  has_one    :search
  
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
  
  def increment(page, visit_time = nil)
    self.page = page
    self.first_visit = visit_time if self.first_visit.nil?
    self.count += 1
    self.save
  end
  
#   def self.increment(request)
#     project = request.project
#     row = find_by_project_id_and_referer_id(project.id, request.referer.id)
# 
#     if row.nil?
#       row = new(:project => project,
#                 :referer => request.referer,
#                 :page => request.page,
#                 :first_visit => request.time)
#     else
#       row.page = request.page
#     end
# 
#     row.count += 1
#     row.save
#   end
  
  def self.get_recent_unique(project, limit)
    return find(:all,
                :conditions => ['project_id = ? AND first_visit is not NULL', project.id],
                :order      => "first_visit DESC",
                :limit      => limit)
  end

  def self.get_top_referers(project, limit, offset=0)
    return find(:all,
                :conditions => ['project_id = ? AND first_visit is not NULL', project.id],
                :order      => "count DESC",
                :offset     => offset,
                :limit      => limit)
  end

  def self.count_top_referers(project)
    return count(:conditions => ['project_id = ? AND first_visit is not NULL', project.id])
  end
end
