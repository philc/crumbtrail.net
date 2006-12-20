class ReferralRecent < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :page

  require './lib/rollable_recent_table.rb'

  def self.add_new_referer(request)
    RollableRecentTable::add_new(ReferralRecent, :referrals_row, request)
  end

  def self.get_recent_referers(project)
    RollableRecentTable::get_recent(ReferralRecent, project)
  end
end
