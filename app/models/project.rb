class Project < ActiveRecord::Base
   belongs_to :account
   belongs_to :zone
   has_one  :row_tracker
#   has_many :recent_referrals
#   has_many :total_referrals
#   has_many :hourly_hits
#   has_many :daily_hits
#   has_one  :total_hit
#   has_one  :hit_detail
#   has_many :landing_urls
#   has_many :search_referers

  def process_request(request)
    increment_referer(request) if request.referer.url != '/'
    increment_hit_count(request)
    increment_page_landing(request) if request.page.url != '-'
    record_details(request)
  end

  # Returns an array of RecentReferrals (Length hardcoded at 10)
  def recent_referers()
     return ReferralRecent.get_recent_referers(self)
  end

  # Returns an array of TotalReferrals
  #  limit - the number of referers you want returned
  def recent_unique_referers(limit)
    return ReferralTotal.get_recent_unique(self, limit)
  end

  # Returns an array of TotalReferrals
  #  limit - the number of referers you want returned
  def top_referers(limit)
    return ReferralTotal.get_top_referers(self, limit)
  end

  # Get the hit count for a specified period.
  # Period can be :day, :week, or :month
  #
  # Returns an array containing hit counts for time devisions of the specified
  # period, most recent first
  def hits(period)
    if period == :day
      return HitHourly.get_hits(self)
    elsif period == :week
      return HitDaily.get_past_week_hits(self)
    elsif period == :month
      return HitDaily.get_past_month_hits(self)
    elsif period == :year
      return HitMonthly.get_hits(self)
    end
  end

  def top_landings(limit)
    return LandingTotal.get_most_popular(self, limit)
  end
  
  def recent_landings()
    return LandingRecent.get_recent_landings(self)
  end
  
  def get_details(type)
    return HitDetail.get_details(self, type)
  end

  def time(*t)
    t[0] = Time.now if t.empty?
    TimeHelpers.convert_to_client_time(self, t[0])
  end

  private

  def increment_referer(request)
    ReferralTotal.increment(request)
    ReferralRecent.add_new_referer(request)
  end

  def increment_hit_count(request)
    HitHourly.increment_hit(request)
    HitDaily.increment_hit(request)
    HitMonthly.increment_hit(request)
    HitTotal::increment_hit(request)
  end

  def increment_page_landing(request)
    LandingTotal.increment(request)
    LandingRecent.add_new_landing(request)
  end

  def record_details(request)
    HitDetail.record_details(request)
  end
end
