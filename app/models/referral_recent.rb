class ReferralRecent < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :page

  @@max_rows = 10

  def self.add_new_referer(request)
    project = request.project

    # Update the proper row for the project, or create a new row
    row = find_by_project_id_and_row(project.id, project.referrals_row)
    if !row.nil?
      row.referer = request.referer
      row.visit_time = request.time
      row.page = request.page
    else
      row = new(:project => project,
                :referer => request.referer,
                :page => request.page,
                :visit_time => request.time,
                :row => project.referrals_row)
    end
    row.save

    # Increment row.
    # Set row back to 0 if we have gone over 10 rows.  Could move
    # this into a user preference.
    project.referrals_row += 1
    project.referrals_row = 0 if project.referrals_row == @@max_rows
  end

  def self.get_recent_referers(project)
    return find(:all, :conditions => ["project_id = ?", project.id], :order => "visit_time DESC")
  end
end
