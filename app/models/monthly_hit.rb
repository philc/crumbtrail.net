class MonthlyHit < ActiveRecord::Base
  belongs_to :project

  def self.increment_hit(request)
    proj = request.project
    time = request.time

    row = find_by_project_id_and_month(proj.id, time.month)
    row = new(:project_id => proj.id, :month => time.month, :last_update => time) if row.nil?

    row_t = row.last_update
    if row_t.year != time.year
      row.total = 0
      row.unique = 0
    end

    row.total += 1
    row.unique += 1 if request.unique
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
    uniques = Array.new(12, 0)
    for h in rows
        hits[h.month-1] = h.total
        uniques[h.month-1] = h.unique
    end
    hits = hits.zip(uniques)
    
    return hits[now.month, hits.length].concat(hits[0, now.month]).reverse
  end
end

