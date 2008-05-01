
class Referer < ActiveRecord::Base
  belongs_to :project
  belongs_to :page
  serialize  :daily_hit_counts, Hash
  
  def after_initialize
    self.daily_hit_counts = Hash.new(0) if self.daily_hit_counts.nil?
  end

  def self.find_by_url(project, url)
    referers = find(:all,
                    :conditions => ['project_id = ? AND url_hash = ?', project.id, url.hash])
    for id in referers
      return id if id.url = url
    end

    return nil
  end

  def self.get_referer_by_id(id, project, page, time = nil)
    referer = Referer.find(id)

    unless referer.nil?
      update_hit_counts(referer, time)

      referer.increment(page)
      referer.save
    end

    return referer
  end

  def self.get_or_create_referer(project, url, page, time = nil)
    return nil if is_internal_referer(project, url)

    referer = find_by_url(project, url)
    referer = create_referer(project, url, page, time) if referer.nil?

    update_hit_counts(referer, time)
    
    referer.increment(page)
    referer.save

    return referer
  end

  def self.create_referer(project, url, page, time = nil)
    referer = new(:project          => project, 
                  :url_hash         => url.hash, 
                  :url              => url, 
                  :first_visit      => time) if referer.nil?

    update_hit_counts(referer, time)
    
    referer.increment(page)
    referer.save

    return referer
  end

  def self.get_recent_unique(project, limit)
    return find(:all,
                :conditions => ['project_id = ?', project.id],
                :order      => "first_visit DESC",
                :limit      => limit)
  end

  def self.get_top_referers(project, limit, offset=0)
    return find(:all,
                :conditions => ['project_id = ?', project.id],
                :order      => "count DESC",
                :offset     => offset,
                :limit      => limit)
  end

  def self.count_top_referers(project)
    return count(:conditions => ['project_id = ?', project.id])
  end

  def self.at_a_glance(project, limit)
    today = Date.parse(project.time.to_s)
    referers = {}

    referers[:today] = find(:all,
                            :conditions => ['project_id = ? AND recent_visit = ?', project.id, today],
                            :order      => "today_count DESC",
                            :limit      => limit)
    
    last_week = today - 7
    referers[:week] = find(:all,
                           :conditions => ['project_id = ? AND recent_visit > ?', project.id, last_week],
                           :order      => "seven_days_count DESC",
                           :limit      => limit)

    return referers
  end  
  
  #
  # Finds referers that have a url containg the given word. Useful for looking at things like
  # non-search referers containg the word "google" (to see if our search parsing is missing anything)
  #
  def self.urls_containing(word)
    Referer.find(:all, :conditions=>["url like ?", "%#{word}%"]).map{|s|CGI.unescape(s.url)}
  end

  def increment(page)
    self.page = page
    self.count += 1
  end

  private

  def self.update_hit_counts(ref, time)
    date = Date.parse(time.to_s)
    week_prev = date - 7

    ref.daily_hit_counts[date.to_s] = 0 if ref.daily_hit_counts[date.to_s].nil?
    ref.daily_hit_counts[date.to_s] += 1
    ref.today_count = ref.daily_hit_counts[date.to_s]

    ref.seven_days_count = 0
    ref.daily_hit_counts.keys.each do |day|
      if Date.parse(day) <= week_prev
        ref.daily_hit_counts.delete(day)
      else
        ref.seven_days_count += ref.daily_hit_counts[day]
      end
    end

    ref.recent_visit = date
  end

  def self.is_internal_referer(project, ref)
    url = project.url
    url = url.first(url.length-1) if url.ends_with?("/")
    
    return ref.starts_with?(url)
  end

end
