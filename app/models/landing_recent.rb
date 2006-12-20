class LandingRecent < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :page

  require './lib/rollable_recent_table.rb'

  def self.add_new_landing(request)
    RollableRecentTable::add_new(LandingRecent, :landings_row, request)
  end

  def self.get_recent_landings(project)
    RollableRecentTable::get_recent(LandingRecent, project)
  end
end
