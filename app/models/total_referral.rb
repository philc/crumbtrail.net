class TotalReferral < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer

  def self.increment_referer(project_id, time, referer)
    total_referral = find_by_project_id_and_referer_id(project_id, referer.id)

    if total_referral.nil?
      total_referral = new(:project_id => project_id,
                           :referer_id => referer.id,
                           :count => 0,
                           :first_visit => time,
                           :recent_visit => time)
    else
      total_referral.recent_visit = time
    end

    total_referral.count += 1
    total_referral.save
  end
  
  def self.get_recent_unique(project_id)
    return find(:all,
                :conditions => ["project_id = ?", project_id],
                :order      => "first_visit DESC",
                :limit      => 10)
  end
end
