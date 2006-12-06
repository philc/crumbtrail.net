class LandingUrl < ActiveRecord::Base
  has_many :recent_referrals
  has_many :total_referrals
end
