class LandingTotal < ActiveRecord::Base
  belongs_to :project
  belongs_to :referer
  belongs_to :page

  def self.increment(request)
    project = request.project
    row = find_by_project_id_and_page_id(project.id, request.page)

    if row.nil?
      row = new(:project => project,
                :page => request.page,
                :referer => request.referer)
    else
      row.referer = request.referer
    end

    row.count += 1
    row.save
  end

  def self.get_most_popular(project, limit)
    return find(:all,
                :conditions => {:project_id=>project.id},
                :limit => limit,
                :order => "count DESC")
  end
  

end
