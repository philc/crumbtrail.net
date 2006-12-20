module RollableRecentTable

  @@max_rows = 10

  def self.add_new(table_class, row_col_name, request, *extras)
    project = request.project
    row_equals = (row_col_name.to_s + '=').to_sym

    # Update the proper row for the project, or create a new row
    row = table_class.find_by_project_id_and_row(project.id, project.send(row_col_name))
    if !row.nil?
      row.referer = request.referer
      row.page = request.page
      row.visit_time = request.time
      add_extras_to_row(row, extras)
    else
      row = table_class.new(:project => project,
                            :referer => request.referer,
                            :page => request.page,
                            :visit_time => request.time,
                            :row => project.send(row_col_name))
      add_extras_to_row(row, extras)
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

  def self.add_extras_to_row(row, extras)
    if extras.length == 1
      extras[0].keys.each do |key|
        equal_key = (key.to_s + '=').to_sym
        row.send(equal_key, extras[0][key])
      end
    end
  end

end
