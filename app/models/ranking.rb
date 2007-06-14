class Ranking < ActiveRecord::Base
  def self.get_rank_details(project)
    rankings = {}
    [:google, :yahoo, :msn].each do |engine|
      rankings[engine] = get_ranks_for_engine(project, engine)
    end
    return rankings
  end

  private

  def self.get_ranks_for_engine(project, engine)
    rankings = []
    project.queries.each do |query|
      rank = get_engine_query_rank(project, engine, query)
      if rank.nil?
        rankings << query
      else
        rankings << rank
      end
    end
    return rankings
  end

  def self.get_engine_query_rank(project, engine, query)
    enginechr = engine.to_s[0].chr
    ranking = Ranking.find(
      :first,
      :conditions => ['project_id = ? and engine = ? and query = ?',
                      project.id, enginechr, query],
      :order      => "search_date DESC")
    return ranking
  end
end
