require 'cgi'
class Source < ActiveRecord::Base
  belongs_to :project
  
  def increment(target)
    self.target = target
    self.count += 1
  end
  
  def self.is_internal_referer(project, ref)
    url = project.url
    url = url.first(url.length-1) if url.ends_with?("/")
    
    return ref.starts_with?(url)
  end
end

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

class Referer < Source
  belongs_to :target,
             :class_name  => "Page",
             :foreign_key => "path_id"
  
  serialize  :daily_hit_counts, Hash

  def self.find_by_url(project, url)
    referers = find_all_by_project_id_and_url_hash(project.id, url.hash)
    for id in referers
      return id if id.url = url
    end

    return nil
  end

  def self.get_or_create_referer(project, url, page, time = nil)
    return nil if is_internal_referer(project, url)

    referer = find_by_url(project, url)
    referer = new(:project          => project, 
                  :url_hash         => url.hash, 
                  :url              => url, 
                  :first_visit      => time, 
                  :daily_hit_counts => Hash.new(0)) if referer.nil?

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

end

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

class Search < Source
  belongs_to :target,
             :class_name  => "Page",
             :foreign_key => "path_id"

  def self.find_by_search_words(project, words)
    searches = find_all_by_project_id_and_search_words_hash(project.id, words.hash)
    for id in searches
      return id if id.search_words = words
    end

    return nil
  end
  
  def self.get_or_create_search(project, url, page)
    words = analyze_url(url)
    return nil if words.nil?
  
    search  = find_by_search_words(project, words)
    search  = new(:project           => project,
                  :url_hash          => url.hash,
                  :url               => url,
                  :search_words      => words,
                  :search_words_hash => words.hash) if search.nil?
    
    search.increment(page)
    search.save

    return search
  end

  def self.get_top_searches(project, limit, offset=0)
    return find(:all,
                :conditions => ["project_id = ?", project.id],
                :order      => "count DESC",
                :offset     => offset,
                :limit      => limit)
  end

  def self.count_top_searches(project)
    return count(:conditions => ["project_id",project.id])
  end

  #private 
  
  @@search_term = '([A-Za-z0-9\+\-_\. %]+)'
  @@google = Regexp.compile("google\..*\/(?:blog)?search.*[&\?]q=#{@@search_term}&?")
  @@msn    = Regexp.compile("search\.msn\..*/results\.aspx.*[&\?]q=#{@@search_term}&?")
  @@live   = Regexp.compile("search\.live\..*\/results\.aspx.*[&\?]q=#{@@search_term}&?")
  @@yahoo  = Regexp.compile("search\.yahoo\..*/search.*[&\?]p=#{@@search_term}&?")
  def self.analyze_url(url)
    unesc_url = CGI.unescape(url)
    if !@@google.match(unesc_url).nil? ||
       !@@msn.match(unesc_url).nil? ||
       !@@live.match(unesc_url).nil? ||
       !@@yahoo.match(unesc_url).nil?
      words = CGI.unescape($1)
      return words.downcase
    else
      return nil
    end
  end

end

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

class Page < Source
  belongs_to :origin,
             :class_name  => "Source",
             :foreign_key => "path_id"

  def self.find_by_url(project, url)
    pages = find_all_by_project_id_and_url_hash(project.id, url.hash)
    for id in pages
      return id if id.url = url
    end

    return nil
  end

  def self.get_or_new_page(project, url)
    return nil if !is_internal_referer(project, url)

    page = find_by_url(project, url)
    page = new(:project => project, :url_hash => url.hash, :url => url) if page.nil?
    
    page.count += 1
    
    return page
  end

  def self.get_or_create_page(project, url)
    page = get_or_new_page(project, url)
    page.save

    return page
  end
  
  def self.get_most_popular(project, limit)
    return find(:all,
                :conditions => {:project_id=>project.id},
                :limit => limit,
                :order => "count DESC")
  end

end