class Project < ActiveRecord::Base
  belongs_to :account
  belongs_to :zone
  has_one  :row_tracker
  has_many :recent_referrals
  has_many :total_referrals
  has_many :hourly_hits
  has_many :daily_hits
  has_one  :total_hit
  has_one  :hit_detail
  has_many :landing_urls

  def increment_referer(request)
    TotalReferral.increment_referer(request)
    RecentReferral.add_new_referer(request)
  end

  def increment_hit_count(request)
    HourlyHit.increment_hit(request)
    DailyHit.increment_hit(request)
    MonthlyHit.increment_hit(request)
    TotalHit::increment_hit(request)
  end

  def increment_details(request)
    HitDetail.increment_browser(request)
  end
  
  # Returns an array of RecentReferrals (Length hardcoded at 10)
  def recent_referers()
    return RecentReferral.get_recent_referers(self)
  end

  # Returns an array of TotalReferrals
  #  limit - the number of referers you want returned
  def recent_unique_referers(limit)
    return TotalReferral.get_recent_unique(self, limit)
  end

  # Returns an array of TotalReferrals
  #  limit - the number of referers you want returned
  def top_referers(limit)
    return TotalReferral.get_top_referers(self, limit)
  end

  # Get the hit count for a specified period.
  # Period can be :day, :week, or :month
  #
  # Returns an array containing hit counts for time devisions of the specified
  # period, most recent first
  def hits(period)
    if period == :day
      return HourlyHit.get_hits(self)
    elsif period == :week
      return DailyHit.get_past_week_hits(self)
    elsif period == :month
      return DailyHit.get_past_month_hits(self)
    elsif period == :year
      return MonthlyHit.get_hits(self)
    end
  end

  def most_popular_pages(limit)
    return LandingUrl.get_most_popular(self, limit)
  end
  
  def most_recent_pages(limit)
    return LandingUrl.get_most_recent(self, limit)
  end
  
  def get_details(type)
    return HitDetail.get_details(self, type)
  end

  def time(*t)
    t[0] = Time.now if t.empty?
    TimeHelpers.convert_to_client_time(self, t[0])
  end

end
