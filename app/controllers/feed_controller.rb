class FeedController < ApplicationController
  def referers
#    @kind=params[:kind]
   @project = Project.find_by_id(params[:id])
   @refs = @project.recent_unique_referers(10)
   headers["Content-Type"] = "application/rss+xml"    
   render :layout=>false
  end
end
