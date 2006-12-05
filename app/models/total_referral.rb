class TotalReferral < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :internal_url

  def self.increment_referer(request)
    project = request.project
    referer = request.referer

    total_referral = find_by_project_id_and_referer_id(project.id, referer.id)
    
    if total_referral.nil?
      total_referral = new(:project_id => project.id,
                           :referer_id => referer.id,
                           :count => 0,
                           :first_visit => request.time,
                           :recent_visit => request.time,
                           :internal_url => request.internal_url)
    else
      total_referral.recent_visit = request.time
      total_referral.internal_url = request.internal_url
    end

    total_referral.count += 1
    total_referral.save
  end
  
  def self.get_recent_unique(project)
    return find(:all,
                :conditions => ["project_id = ?", project.id],
                :order      => "first_visit DESC",
                :limit      => 10)
  end
end
