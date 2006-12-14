require 'cgi'

class SearchTotal < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :page

  @@google = Regexp.compile('^google.*\/search.*[&\?]q=([A-Za-z0-9\+\. %]+)&?')
  def self.increment_search_string(request, words)
    project = request.project

    row = find_by_search_string(project, words)
    row = new(:project => project, :referer => request.referer, :page => request.page, :search_words => words, :search_words_hash => words.hash) if row.nil?

    row.count += 1
    row.save
  end

  def self.analyze_search_url(url)
    unesc_url = CGI.unescape(url)
    if !@@google.match(unesc_url).nil?
      words = CGI.unescape($1)
      return words.downcase
    else
      return nil
    end
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

  private
  
  def self.find_by_search_string(project, words)
    rows = find(:all, :conditions => ['project_id = ? AND search_words_hash = ?', project.id, words.hash])
    for r in rows
      if r.search_words == words
        return r
      end
    end
    return nil
  end
end
