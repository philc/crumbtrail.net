class SearchRecent < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :page

  @@max_rows = 10

  def self.add_new_search(request, words)
    project = request.project

    row_track = project.row_tracker
    row_track = RowTracker.new(:project_id => project.id) if row_track.nil?

    # Update the proper row for the project, or create a new row
    row = find_by_project_id_and_row(project.id, row_track.searches_row)
    if !row.nil?
      row.referer = request.referer
      row.visit_time = request.time
      row.page = request.page
    else
      row = new(:project => project,
                :referer => request.referer,
                :page => request.page,
                :search_words => words,
                :visit_time => request.time,
                :row => row_track.searches_row)
    end
    row.save

    # Increment row.
    # Set row back to 0 if we have gone over 10 rows.  Could move
    # this into a user preference.
    row_track.searches_row += 1
    row_track.searches_row = 0 if row_track.searches_row == @@max_rows
    row_track.save

  end

  def self.get_recent_searches(project)
    return find(:all, :conditions => ["project_id = ?", project.id], :order => "visit_time DESC")
  end
end
