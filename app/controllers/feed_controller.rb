class FeedController < ApplicationController

  def referers

    @project = verify_project
    if (@project)
      @kind=params[:kind]
      @refs = params[:option]=="unique" ? @project.recent_unique_referers(10) : @project.recent_referers()
    end
    puts "bad key" if @project.nil?
    headers["Content-Type"] = "application/rss+xml"    
    render :layout=>false
  end

  def hits

    #    @project= Project.find_by_id(params[:id])

    @project=verify_project()
    if (@project)
      @hits = @project.hits(:day)
    end
    headers["Content-Type"] = "application/rss+xml"    
    render :layout=>false    

  end

  def verify_project
    p =  Project.find_by_id(params[:id])
    key = params[:k]
    puts key
    puts p.account.access_key
    return nil if p.nil? || key.nil?    
    # Let the RSS feed show without a key if it's the demo project
    return nil if (p.id != Project.demo_project_id && p.account.access_key!=key)

    return p
  end
end
