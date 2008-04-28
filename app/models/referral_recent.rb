class ReferralRecent < ActiveRecord::Base
  belongs_to :project

  require File.dirname(__FILE__)+'/../../lib/rollable_recent_table.rb'

  def self.add_new_referer( project, source, page, time )
    RollableRecentTable::add_new(ReferralRecent,
                                 :referrals_row,
                                 project,
                                 source,
                                 page,
                                 time)
  end

  def self.get_recent_referers(project)
    RollableRecentTable::get_recent(ReferralRecent, project)
  end
end
