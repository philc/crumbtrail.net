class DailyReferral < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer

  include RollableTimeTable

  def self.increment_referer(request)
    RollableTimeTable::increment_referer(request, :day, :wday, self)
  end
end
