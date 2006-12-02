class TotalHit < ActiveRecord::Base
  belongs_to :project

  def self.increment_hit(project)
    total_hit = find_by_project_id(project.id)
    total_hit = new(:project => project) if total_hit.nil?

    total_hit.count += 1
    total_hit.save
  end
end
