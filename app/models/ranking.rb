class Ranking < ActiveRecord::Base
  belongs_to :project

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
