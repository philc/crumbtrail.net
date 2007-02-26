module RollableRecentTable

  @@max_rows = 10

  def self.add_new(table_class, row_col_name, project, primary, secondary, time)
    row_equals = (row_col_name.to_s + '=').to_sym

    # Update the proper row for the project, or create a new row
    row = table_class.find_by_project_id_and_row(project.id, project.send(row_col_name))
    if !row.nil?
      row.primary    = primary
      row.secondary  = secondary
      row.visit_time = time
    else
      row = table_class.new(:project    => project,
                            :primary    => primary,
                            :secondary  => secondary,
                            :visit_time => time,
                            :row        => project.send(row_col_name))
    end
    row.save

    # Increment row.
    # Set row back to 0 if we have gone over 10 rows.  Could move
    # this into a user preference.
    project.send(row_equals, (project.send(row_col_name) + 1))
    project.send(row_equals, 0) if project.send(row_col_name) == @@max_rows
  end

  def self.get_recent(table_class, project)
    return table_class.find(:all, :conditions => ["project_id = ?", project.id], :order => "visit_time DESC")
  end

end
