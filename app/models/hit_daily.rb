require 'lib/time_helpers'

# Represents the number of hits for a project for any given day
class HitDaily < ActiveRecord::Base
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
      row = create(:project => project, :date => request.time, :total => 1, :row => row_track.hits_row)
      row.unique = 1 if request.unique
    elsif row.date == date
      row.total += 1
      row.unique += 1 if request.unique
      row.save
    elsif row.date < past
      row.total = 1
      if request.unique
        row.unique = 1
      else
        row.unique = 0
      end 
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
    c_date = Date.parse(project.time.to_s)

    hits = build_hit_array(project, c_date-6, c_date)
    return hits[0].zip(hits[1])
  end

  def self.get_past_month_hits(project)
    c_date = Date.parse(project.time.to_s)

    hit_array = []

    hits = build_hit_array(project, c_date-6, c_date)
    hit_array << [hits[0].sum, hits[1].sum]

    hits = build_hit_array(project, c_date-13, c_date-7)
    hit_array << [hits[0].sum, hits[1].sum]

    hits = build_hit_array(project, c_date-20, c_date-14)
    hit_array << [hits[0].sum, hits[1].sum]

    hits = build_hit_array(project, c_date-27, c_date-21)
    hit_array << [hits[0].sum, hits[1].sum]

    return hit_array
  end

  private

  def self.build_hit_array(project, first, last)
    rows = find(:all, 
                :conditions => ['project_id = ? AND date >= ? AND date <= ?', project.id, first, last],
                :order => 'date ASC')

    hits = Array.new((last - first).to_i + 1, 0)
    uniques = Array.new((last - first).to_i + 1, 0)
    for r in rows
      hits[(r.date - first).to_i] = r.total
      uniques[(r.date - first).to_i] = r.unique
    end

    return hits.reverse, uniques.reverse
  end

end
