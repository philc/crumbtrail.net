class SearchRecent < ActiveRecord::Base
  belongs_to :project
  belongs_to :search
  belongs_to :page
  belongs_to :primary,
             :class_name  => "Search",
             :foreign_key  => "search_id"
  belongs_to :secondary,
             :class_name  => "Page",
             :foreign_key  => "page_id"

  require File.dirname(__FILE__)+'/../../lib/rollable_recent_table.rb'

  def self.add_new_search(request)
    RollableRecentTable::add_new(SearchRecent, 
                                 :searches_row, 
                                 request.project, 
                                 request.source, 
                                 request.target,
                                 request.time)
  end

  def self.get_recent_searches(project)
    RollableRecentTable::get_recent(SearchRecent, project)
  end
end
