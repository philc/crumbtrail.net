class Referer < ActiveRecord::Base
  belongs_to :project
  belongs_to :page
  has_one    :search
  serialize  :daily_hit_counts, Hash

  def self.find_by_url(project, url)
    referers = find_all_by_project_id_and_url_hash(project.id, url.hash)
    for id in referers
      return id if id.url = url
    end

    return nil
  end

  def self.get_referer(project, url, first_visit = nil)
    referer = find_by_url(project, url)
    referer = create(:project => project, :url_hash => url.hash, :url => url, :first_visit => first_visit, :daily_hit_counts => Hash.new(0)) if referer.nil?
    return referer
  end

  def increment(page, visit_time)
    self.page = page
    self.count += 1

    update_hit_counts(visit_time)

    self.save
  end

  def self.get_recent_unique(project, limit)
    return find(:all,
                :conditions => ['project_id = ? AND first_visit is not NULL', project.id],
                :order      => "first_visit DESC",
                :limit      => limit)
  end

  def self.get_top_referers(project, limit, offset=0)
    return find(:all,
                :conditions => ['project_id = ? AND first_visit is not NULL', project.id],
                :order      => "count DESC",
                :offset     => offset,
                :limit      => limit)
  end

  def self.count_top_referers(project)
    return count(:conditions => ['project_id = ? AND first_visit is not NULL', project.id])
  end

  def self.at_a_glance(project, limit)
    today = Date.parse(project.time.to_s)
    referers = {}

    referers[:today] = find(:all,
                            :conditions => ['project_id = ? AND first_visit is not NULL AND recent_visit = ?', project.id, today],
                            :order      => "today_count DESC",
                            :limit      => limit)

    last_week = today - 7
    referers[:week] = find(:all,
                           :conditions => ['project_id = ? AND first_visit is not NULL AND recent_visit > ?', project.id, last_week],
                           :order      => "seven_days_count DESC",
                           :limit      => limit)

    return referers
  end

  private

  def update_hit_counts(time)
    today = Date.parse(time.to_s)
    last_week = today - 7

    self.daily_hit_counts[today.to_s] = 0 if self.daily_hit_counts[today.to_s].nil?
    self.daily_hit_counts[today.to_s] += 1
    self.today_count = self.daily_hit_counts[today.to_s]

    self.seven_days_count = 0
    self.daily_hit_counts.keys.each do |date|
      if Date.parse(date) <= last_week
        self.daily_hit_counts.delete(date)
      else
        self.seven_days_count += self.daily_hit_counts[date]
      end
    end

    self.recent_visit = today
  end

end
