class PagehitRecent < ActiveRecord::Base
  belongs_to :project

  require File.dirname(__FILE__)+'/../../lib/rollable_recent_table.rb'

  def self.add_new_hit( project, page, source, time )
    RollableRecentTable::add_new(PagehitRecent, 
                                 :landings_row, 
                                 project, 
                                 page, 
                                 source, 
                                 time)
  end

  def self.get_recent_hits(project)
    RollableRecentTable::get_recent(PagehitRecent, project)
  end
end
