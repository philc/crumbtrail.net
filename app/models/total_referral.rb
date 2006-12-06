class TotalReferral < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :landing_url

  def self.increment_referer(request)
    project = request.project

    row = find_by_project_id_and_referer_id(project.id, request.referer.id)
    
    if row.nil?
      row = new(:project_id => project.id,
                :referer_id => request.referer.id,
                :first_visit => request.time,
                :count => 0,
                :landing_url => request.landing_url)
    else
      row.landing_url = request.landing_url
    end

    row.count += 1
    row.save
  end
  
  def self.get_recent_unique(project, limit)
    return find(:all,
                :conditions => ["project_id = ?", project.id],
                :order      => "first_visit DESC",
                :limit      => limit)
  end

  def self.get_top_referers(project, limit)
    return find(:all,
                :conditions => ["project_id = ?", project.id],
                :order      => "count DESC",
                :limit      => limit)
  end
end
