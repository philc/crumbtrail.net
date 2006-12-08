class LandingUrl < ActiveRecord::Base
  has_many   :recent_referrals
  has_many   :total_referrals
  belongs_to :referers
  belongs_to :recent_referrals

  def self.get_most_popular(project, limit)
    return find(:all, 
                :conditions => ['project_id = ?', project.id],
                :limit => limit,
                :order => "count DESC")
  end

  def self.get_most_recent(project, limit)
    return find(:all,
                :conditions => ['project_id = ?', project.id],
                :limit => limit,
                :order => "last_visit DESC")
  end
end
