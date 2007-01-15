class ReferralTotal < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :page

  def self.increment(request)
    project = request.project
    row = find_by_project_id_and_referer_id(project.id, request.referer.id)

    if row.nil?
      row = new(:project => project,
                :referer => request.referer,
                :page => request.page,
                :first_visit => request.time)
    else
      row.page = request.page
    end

    row.count += 1
    row.save
  end
  
  def self.get_recent_unique(project, limit)
    return find(:all,
                :conditions => {:project_id=> project.id},
                :order      => "first_visit DESC",
                :limit      => limit)
  end

  def self.get_top_referers(project, limit, offset=0)
    return find(:all,
                :conditions => {:project_id=> project.id},
                :order      => "count DESC",
                :offset     => offset,
                :limit      => limit)
  end

  def self.count_top_referers(project)
    return count(:conditions => {:project_id=> project.id})
  end
end
