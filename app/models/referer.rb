class Referer < ActiveRecord::Base
  has_many :hourly_referrals
  has_many :daily_referrals
  has_many :total_referrals
  has_many :recent_hits
end
