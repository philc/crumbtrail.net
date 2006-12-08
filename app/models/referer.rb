class Referer < ActiveRecord::Base
  has_many :recent_referrals
  has_many :total_referrals
  has_many :landing_urls
end
