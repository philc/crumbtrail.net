require 'lib/time_helpers'

# Is there a better place to put this?
class Array
  def sum
    
    inject( 0 ) { |sum,x| sum+x }
  end
end

# Represents the number of hits for a project for any given day
class DailyHit < ActiveRecord::Base
  belongs_to :project

  @@max_rows = 35
  include TimeHelpers

  def self.increment_hit(request)
    project = request.project
    date = Date.parse(request.time.to_s)
    past = date - (@@max_rows - 1)

    row_track = project.row_tracker
    row_track = RowTracker.new(:project => project) if row_track.nil?

    row = find_by_project_id_and_row(project.id, row_track.hits_row)
    if row.nil?
      row = DailyHit.create(:project => project, :date => request.time, :count => 1, :row => row_track.hits_row)
    elsif row.date == date
      row.count += 1
      row.save
    elsif row.date < past
      row.count = 1
      row.date = date
      row.save
    else
      row_track.hits_row += 1
      row_track.hits_row = 0 if row_track == @@max_rows
      row_track.save
      increment_hit(request)
    end
  end

  def self.get_past_week_hits(project)
    c_time = TimeHelpers.convert_to_client_time(project, Time.now)
    c_date = Date.parse(c_time.to_s)

    return build_hit_array(project, c_date-6, c_date)
  end

  def self.get_past_month_hits(project)
    c_time = TimeHelpers.convert_to_client_time(project, Time.now)
    c_date = Date.parse(c_time.to_s)

    hit_array = []
    hit_array << (build_hit_array(project, c_date-6, c_date).sum)
    hit_array << (build_hit_array(project, c_date-13, c_date-7).sum)
    hit_array << (build_hit_array(project, c_date-20, c_date-14).sum)
    hit_array << (build_hit_array(project, c_date-27, c_date-21).sum)
    return hit_array
  end

  private

  def self.build_hit_array(project, first, last)
    rows = find(:all, 
                :conditions => ['project_id = ? AND date >= ? AND date <= ?', project.id, first, last], 
                :order => 'date ASC')

    days = Array.new((last - first).to_i + 1, 0)
    for r in rows
      days[(r.date - first).to_i] = r.count
    end

    return days.reverse
  end

end
