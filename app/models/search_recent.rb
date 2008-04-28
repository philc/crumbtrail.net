class SearchRecent < ActiveRecord::Base
  belongs_to :project
  belongs_to :search

  @@max_rows = 10

  def self.add_new_search( project, search, page, time )
    # Update the proper row for the project, or create a new row
    row = find(:first, :conditions => ['project_id = ? AND row = ?', project.id, project.searches_row])

    if !row.nil?
      row.search     = search
      row.page_url   = page.url
      row.visit_time = time
    else
      row = new(:project    => project,
                :search     => search,
                :page_url   => page.url,
                :visit_time => time,
                :row        => project.searches_row)
    end

    row.save

    # Increment row.
    # Set row back to 0 if we have gone over 10 rows.  Could move
    # this into a user preference.
    project.searches_row = project.searches_row + 1
    project.searches_row = 0 if project.searches_row == @@max_rows
  end

  def self.get_recent_searches(project)
    return find(:all, :conditions => ['project_id = ?', project.id], :order => "visit_time DESC")
  end

end
