require File.dirname(__FILE__)+'/../../lib/time_helpers.rb'

class HitHourly < ActiveRecord::Base
  belongs_to :project

  def self.increment_hit( project, time, unique, type )
    row = find_by_project_id_and_hour(project.id, time.hour)
    row = new(:project => project, :hour => time.hour, :last_update => time) if row.nil?

    row_t = row.last_update
    if row_t.day != time.day || row_t.month != time.month || row_t.year != time.year
      row.total = 0
      row.search = 0
      row.referer = 0
      row.direct = 0
      row.unique = 0
    end

    row.total += 1
    row.unique += 1 if unique
    
    type_count = row.send( type )
    row.send((type.to_s + '=').to_sym, type_count + 1)
    
    row.last_update = time
    row.save
  end

  # Returns an array of hit counts for each hour in the past 24 hours,
  # starting with the most recent hour
  def self.get_hits(project)
    c_time = project.time
    rows = get_valid_rows(project)

    hits = Array.new(24, 0)
    uniques = Array.new(24,0)
    for r in rows
        hits[r.hour] = r.total
        uniques[r.hour] = r.unique
    end
    hits = hits.zip(uniques)

    return hits[c_time.hour+1, hits.length].concat(hits[0, c_time.hour+1]).reverse
  end
  
  def self.get_hit_sources(project)
    rows = get_valid_rows(project)
    hits = {:referer=>0, :search=>0, :direct=>0}
    
    hits.each_key do |key|
      rows.each do |row|
        hits[key] += row.send(key)
      end
    end
    
    return hits
  end
  
  def self.get_valid_rows(project)
    c_time = project.time
    c_yesterday = c_time - (60 * 60 * 23)

    return find(:all, 
                :conditions => ['project_id = ? AND last_update >= ?', project.id, c_yesterday], 
                :order => 'last_update DESC')  
  end
end
