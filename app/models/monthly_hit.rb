class MonthlyHit < ActiveRecord::Base
  belongs_to :project

  def self.increment_hit(request)
    proj = request.project
    time = request.time

    row = find_by_project_id_and_month(proj.id, time.month)
    row = new(:project_id => proj.id, :month => time.month, :last_update => time) if row.nil?

    row_t = row.last_update
    if row_t.year != time.year
      row.count = 0
    end

    row.count += 1
    row.last_update = time
    row.save
  end

  # Returns an array of hit counts for each hour in the past 24 hours,
  # starting with the most recent hour
  def self.get_hits(project)
    now = Date.parse(project.time.to_s)
    last_year = Date.civil(now.year-1, now.month, 1)

    rows = find(:all, 
                :conditions => ['project_id = ? AND last_update >= ?', project.id, last_year])

    hits = Array.new(12, 0)
    for h in rows
        hits[h.month-1] = h.count
    end

    return hits[now.month, hits.length].concat(hits[0, now.month]).reverse
  end
end

