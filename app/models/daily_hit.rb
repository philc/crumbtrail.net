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

  include TimeHelpers

  def self.increment_hit(request)
    project = request.project

    daily_hit = find_by_project_id_and_date(project.id, request.time)
    daily_hit = new(:project => project, :date => request.time) if daily_hit.nil?

    daily_hit.count += 1
    daily_hit.save
  end

  # Returns the number of hits a project has received in the last day, week
  # or month.  If passed :week, it will return an array of hits counts for every day the
  # last week.  If passed :month, it will return an array of hit counts for every
  # week of the last month
  def self.get_hits(project, period)
    # Get the current date in the client's time zone
    c_time = TimeHelpers::convert_to_client_time(project, Time.now)
    c_date = Date.parse(c_time.to_s)

    if period == :week
      # Return an array of 7 integers representing each day's hit count
      return build_hit_array(project, c_date-6, c_date), c_time

    elsif period == :month
      hit_array = []
      hit_array << (build_hit_array(project, c_date-27, c_date-21).sum)
      hit_array << (build_hit_array(project, c_date-20, c_date-14).sum)
      hit_array << (build_hit_array(project, c_date-13, c_date-7).sum)
      hit_array << (build_hit_array(project, c_date-6, c_date).sum)
      return hit_array, c_time
    end
  end

  private

  def self.build_hit_array(project, first, last)
    hits = find(:all, :conditions => ['project_id = ? AND date >= ? AND date <= ?', 
                                      project.id, first, last], :order => "date ASC")
    curr = first
    hit_array = []
    i = 0
    while curr <= last
      if !hits[i].nil? && hits[i].date == curr
        hit_array << hits[i].count
        i += 1
      else
        hit_array << 0
      end

        curr += 1
    end

    return hit_array
  end
end
