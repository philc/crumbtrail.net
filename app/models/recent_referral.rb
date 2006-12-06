class RecentReferral < ActiveRecord::Base
  belongs_to :project
  belongs_to :landing_url
  belongs_to :referer

  @@max_rows = 10

  def self.add_new_referer(request)
    project = request.project

    row_track = project.row_tracker
    row_track = RowTracker.new(:project_id => project.id) if row_track.nil?

    # Update the proper row for the project, or create a new row
    row = find_by_project_id_and_row(project.id, row_track.referrals_row)
    if !row.nil?
      row.referer = request.referer
      row.visit_time = request.time
      row.landing_url = request.landing_url
    else
      row = new(:project => project,
                :referer => request.referer,
                :visit_time => request.time,
                :row => row_track.referrals_row,
                :landing_url => request.landing_url)
    end
    row.save

    # Increment row.
    # Set row back to 0 if we have gone over 10 rows.  Could move
    # this into a user preference.
    row_track.referrals_row += 1
    row_track.referrals_row = 0 if row_track.referrals_row == @@max_rows
    row_track.save

  end

  def self.get_recent_referers(project)
    return find(:all, :conditions => ["project_id = ?", project.id], :order => "visit_time DESC")
  end
end
