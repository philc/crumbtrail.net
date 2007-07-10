require 'date'

class Ranking < ActiveRecord::Base
  belongs_to :project

  def self.get_plot_data_for_engine(project, engine)
    cutoff = Date.today - 90
    enginechr = engine.to_s[0].chr

    rankings = {}
    project.queries.each do |query|
      #puts "Checking #{query}"
      rankings[query] = Ranking.find(
        :all,
        :conditions => ['project_id = ? and engine = ? and query = ? and search_date >= ?',
                        project.id, enginechr, query, cutoff],
        :order      => "search_date")
      #puts "#{query} returned nil" if rankings[query].nil?
      #puts "Found #{rankings[query].size.to_s} for #{query}"
    end

    rankings.each_pair {|e, r| puts "#{e} => #{r.size.to_s}"}

    oldest_date   = get_oldest_date(rankings)

    plot_hash = {}
    rankings.each_pair do |engine, rankings|
      plot_hash[engine] = []
      current_rank = nil
      current_date = oldest_date
      i = 0
      rankings.each do |ranking|
        while (current_date != ranking.search_date && current_date <= Date.today)
          #puts "#{current_rank.to_s} for #{current_date.to_s} ranking date #{ranking.search_date.to_s}"
          plot_hash[engine] << [i, current_rank] unless current_rank.nil?
          i += 1
          current_date += 1
        end
        current_rank = ranking.rank
      end

      while (current_date <= Date.today)
        plot_hash[engine] << [i, current_rank] unless current_rank.nil?
        i += 1
        current_date += 1
      end
    end

    time_labels = []
    current_date = oldest_date
    i = 0
    while (current_date <= Date.today)
      if (time_labels.last.nil? || time_labels.last[1] != Date::MONTHNAMES[current_date.month])
        time_labels << [i, Date::MONTHNAMES[current_date.month]]
      end
      i += 1
      current_date += 1
    end

    return [plot_hash, time_labels]
  end

  def self.get_oldest_date(rank_hash)
    date = Date.today
    rank_hash.each_pair do |key, rankings|
      rankings.each do |ranking|
        date = ranking.search_date if ranking.search_date < date
      end
    end

    return date
  end

  # Returns a big hash with each engine as the key.  Contains all results for
  # each query for each engine
  def self.get_rankings_by_engine(project)
    rankings = {}
    [:google, :yahoo, :msn].each do |engine|
      rankings[engine] = get_ranks_for_engine(project, engine)
    end
    return rankings
  end

  # Returns a big hash with each query as the key.  Contains all results for
  # each engine for each query
  def self.get_rankings_by_query(project)
    rankings = {}
    project.queries = [] if project.queries.nil?
    project.queries.each do |query|
      rankings[query] = get_ranks_for_query(project, query)
    end
    return rankings
  end

  private

  # Returns a hash of results from each engine for a specified query:
  # [ :google => [rank, delta], :yahoo => [rank, delta], :msn => [rank, delta] ]
  def self.get_ranks_for_query(project, query)
    results = {}
    [:google, :yahoo, :msn].each do |engine|
      results[engine] = get_engine_ranking_for_query(project, engine, query)
    end
    return results
  end

  # Returns an array with the results for every query on the specified
  # engine.
  #
  # One element for each query.  Returns just the query string if no
  # results were found:
  # [Ranking, "my query with no results", Ranking]
  def self.get_ranks_for_engine(project, engine)
    results = {}
    project.queries.each do |query|
      results[query] = get_engine_ranking_for_query(project, engine, query)
    end
    return results 
  end
   
  # Returns the actual Ranking object for the row in the database
  # for the given engine and query
  def self.get_engine_ranking_for_query(project, engine, query)
    enginechr = engine.to_s[0].chr
    ranking = Ranking.find(
      :first,
      :conditions => ['project_id = ? and engine = ? and query = ?',
                      project.id, enginechr, query],
      :order      => "search_date DESC")
    return ranking
  end

  # Returns a two element array for a given query and engine
  # [rank, delta]
  def self.get_engine_data_for_query(project, query, engine)
    rank = []
    ranking = get_engine_ranking_for_query(project, engine, query)
    if (ranking.nil?)
      rank << nil << nil
    else
      rank << ranking.rank << ranking.delta
    end
    return rank
  end

end
