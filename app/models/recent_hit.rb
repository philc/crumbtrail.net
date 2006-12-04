require "app/models/hit_row_tracker.rb"

class RecentHit < ActiveRecord::Base
  belongs_to :referer
  belongs_to :project

  @@max_rows = 10

  def self.add_new_hit(request)
    project = request.project
    referer = request.referer

    row_tracker = HitRowTracker.find_by_project_id(project.id)
    if row_tracker.nil?
      row_tracker = HitRowTracker.new(:project_id => project.id, :row => 0)
    else
      row_tracker.row += 1
    end

    # Set row back to 0 if we have gone over 10 rows.  Could move
    # this into a user preference.
    row_tracker.row = 0 if row_tracker.row == @@max_rows
    row_tracker.save

    # Update the proper row for the project, or create a new row
    recent_hit = find_by_project_id_and_row(project.id, row_tracker.row)
    if !recent_hit.nil?
      recent_hit.referer = referer
      recent_hit.visit_time = request.time
    else
      recent_hit = new(:project_id => project.id, 
                       :referer => referer,
                       :visit_time => request.time,
                       :row => row_tracker.row)
    end
    recent_hit.save
  end

  def self.get_recent_hits(project)
    return find(:all, :conditions => ["project_id = ?", project.id], :order => "visit_time DESC")
  end
end
