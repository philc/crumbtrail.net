class LandingRecent < ActiveRecord::Base
  belongs_to :project
  belongs_to :page
  belongs_to :source
  belongs_to :primary,
             :class_name  => "Source",
             :foreign_key  => "page_id"
  belongs_to :secondary,
             :class_name  => "Source",
             :foreign_key  => "source_id"           

  require File.dirname(__FILE__)+'/../../lib/rollable_recent_table.rb'

  def self.add_new_landing(request)
    RollableRecentTable::add_new(LandingRecent, 
                                 :landings_row, 
                                 request.project, 
                                 request.target, 
                                 request.source, 
                                 request.time)
  end

  def self.get_recent_landings(project)
    RollableRecentTable::get_recent(LandingRecent, project)
  end
end
