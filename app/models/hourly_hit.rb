require 'lib/time_helpers.rb'

class HourlyHit < ActiveRecord::Base
  belongs_to :project

  def self.increment_hit(request)
    proj = request.project
    time = request.time

    h = find_by_project_id_and_hour(proj.id, time.hour)
    h = new(:project_id => proj.id, :hour => time.hour, :last_update => time) if h.nil?

    h_t = h.last_update
    if h_t.day != time.day || h_t.month != time.month || h_t.year != time.year
      h.count = 0
    end

    h.count += 1
    h.save
  end

  # Returns an array of two elements:
  #     - hit counts for each hour in the last 24 hours, starting with the most recent hour
  #     - the current time in the time zone of the project
  def self.get_hits(project)
    hourly_hits = find(:all, :conditions => ['project_id = ?', project.id], :order => 'last_update DESC')
    c_time = TimeHelpers::convert_to_client_time(project, Time.now)
    c_yesterday = c_time - (60 * 60 * 24)

    hits = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    for h in hourly_hits
      if h.last_update >= c_yesterday
        hits[h.hour] = h.count
      end
    end

    return hits[c_time.hour+1, hits.length].concat(hits[0, c_time.hour+1]).reverse, c_time
  end
end
