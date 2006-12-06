require 'lib/time_helpers.rb'

class HourlyHit < ActiveRecord::Base
  belongs_to :project

  def self.increment_hit(request)
    proj = request.project
    time = request.time

    row = find_by_project_id_and_hour(proj.id, time.hour)
    row = new(:project_id => proj.id, :hour => time.hour, :last_update => time) if row.nil?

    row_t = row.last_update
    if row_t.day != time.day || row_t.month != time.month || row_t.year != time.year
      row.count = 0
    end

    row.count += 1
    row.last_update = time
    row.save
  end

  # Returns an array of hit counts for each hour in the past 24 hours,
  # starting with the most recent hour
  def self.get_hits(project)
    c_time = project.time
    c_yesterday = c_time - (60 * 60 * 24)

    rows = find(:all, 
                :conditions => ['project_id = ? AND last_update >= ?', project.id, c_yesterday], 
                :order => 'last_update DESC')

    hits = Array.new(24, 0)
    for r in rows
        hits[r.hour] = r.count
    end

    return hits[c_time.hour+1, hits.length].concat(hits[0, c_time.hour+1]).reverse
  end
end
