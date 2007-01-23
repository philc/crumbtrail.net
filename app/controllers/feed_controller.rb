class FeedController < ApplicationController

  def referers
#    @kind=params[:kind]
   @project = Project.find_by_id(params[:id])
   @refs = params[:option]=="unique" ? @project.recent_unique_referers(10) : @project.recent_referers()
   headers["Content-Type"] = "application/rss+xml"    
   render :layout=>false
  end
end
