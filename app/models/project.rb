class Project < ActiveRecord::Base
  belongs_to :account
  belongs_to :zone
  has_many :hourly_referrals
  has_many :daily_referrals
  has_many :total_referrals
  has_many :hit_row_trackers
  has_many :recent_hits
  has_many :daily_hits
  has_many :total_hits

  def increment_referer(request)
    TotalReferral::increment_referer(request)
    HourlyReferral::increment_referer(request)
    DailyReferral::increment_referer(request)
  end

  def increment_hit_count(request)
    RecentHit::add_new_hit(request)
    DailyHit::increment_hit(request)
    TotalHit::increment_hit(self)
  end
  
  # Returns the hit count for a specified period
  # Period can be :day, :week, or :month
  def hits(period)
    return DailyHit.get_hits(self, period)
  end
  
  # Returns the total hits for the project
  def total_hits()
    total = TotalHit.find_by_project_id(self.id)
    return total.count
  end
  
  # Returns an array of RecentHits
  def recent_hits()
    return RecentHit.get_recent_hits(self)
  end
  
  # Returns and array of TotalReferrals, with the most recent
  # unique hit first.
  def recent_unique()
    return TotalReferral.get_recent_unique(self)
  end
  
  private

end
