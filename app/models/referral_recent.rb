class ReferralRecent < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :page
  belongs_to :primary,
             :class_name  => "Referer",
             :foreign_key  => "referer_id"
  belongs_to :secondary,
             :class_name  => "Page",
             :foreign_key  => "page_id"      
  
  require './lib/rollable_recent_table.rb'

  def self.add_new_referer(request)
    RollableRecentTable::add_new(ReferralRecent, 
                                 :referrals_row, 
                                 request.project, 
                                 request.source, 
                                 request.target,
                                 request.time)
  end

  def self.get_recent_referers(project)
    RollableRecentTable::get_recent(ReferralRecent, project)
  end
end
