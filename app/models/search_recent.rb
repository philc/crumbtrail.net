class SearchRecent < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :page

  require './lib/rollable_recent_table.rb'

  def self.add_new_search(request, words)
    RollableRecentTable::add_new(SearchRecent, :searches_row, request, {:search_words => words})
  end

  def self.get_recent_searches(project)
    RollableRecentTable::get_recent(SearchRecent, project)
  end
end
