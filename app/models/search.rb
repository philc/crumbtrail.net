class Search < ActiveRecord::Base
  belongs_to :project
  belongs_to :page

  def self.find_by_search_words(project, words)
    searches = find(:all,
                    :conditions => ['project_id = ? AND search_words_hash = ?', project.id, words.hash])

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

  def increment(page)
    self.page = page
    self.count += 1
  end
  
  def self.is_internal_referer(project, ref)
    url = project.url
    url = url.first(url.length-1) if url.ends_with?("/")
    
    return ref.starts_with?(url)
  end

  #private 
  
  @@search_term = '([A-Za-z0-9+\-_.: %]+)'

  # Do we want to special case each google service like this?
  @@google = Regexp.compile("google\..*\/(?:search|images|ie|custom|blogsearch).*[&\?]q=#{@@search_term}&?")
  @@msn    = Regexp.compile("search\.msn\..*/results\.aspx.*[&\?]q=#{@@search_term}&?")
  @@live   = Regexp.compile("search\.live\..*\/results\.aspx.*[&\?]q=#{@@search_term}&?")
  #  @@yahoo  = Regexp.compile("search\.yahoo\..*/search.*[&\?]p=#{@@search_term}&?")
  @@yahoo  = Regexp.compile("yahoo\..*/search.*[&\?]p=#{@@search_term}&?")
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
