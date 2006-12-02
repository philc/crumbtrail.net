class ProjectController < ApplicationController
   @@project_id=1050
   
  def index
    @project_id=@@project_id
    
    # Select top 10 referers
    @referers_total=TotalReferral.find(:all, 
    :conditions=>["project_id = ?",@project_id],:order=>"count DESC")
    #puts @referers_total
    @referers_total=format_referers_with_count(@referers_total)
    #@referers_unique=format_referers(TotalReferral.recent_unique(@project_id))
    #puts @referers_total
    
     #format_referers_date(TotalReferral.recent_unique(@project_id))
     p = Project.find(@project_id)
    @referers_unique= format_referers_date(p.recent_unique())

     #format_referers_date(Project(@project_id))
    
    #@referers_recent=format_referers_recent(RecentHit.get_recent_hits(@project_id))
    
    
    @preferences = p = ViewPreference.find_by_project_id(@project_id)
  end
  def lag()
    sleep 3
  end
  def setpref()
    # TODO : check here to ensure that the logged in user
    # owns this project.
    puts "seting preference"
    render :nothing => true
    pref=params[:p]
    value=params[:v]
    return if pref.nil? || value.nil?
    
    p = ViewPreference.find_by_project_id(@@project_id)
    
    if (pref=="panel")
      p.set_panel(value)
    else
      p.set_section(pref,value)
    end
    p.save!
  end
  def format_referers_with_count(rs)
     rs.map{|r| "\"#{r.referer.url}\",#{r.count}" }.flatten.join(",\n")
  end
  def format_referers_recent(rs)
     #rs.map{|r| "\"#{r.referer.url}\", #{to_js_date(r.first_visit)}" }.flatten.join(",\n")
     #rs.map{|r| "\"#{r.referer.url}\", #{to_js_date(r.recent_visit)}" }.flatten.join(",\n")
  end
  def format_referers_date(rs)
     #rs.map{|r| "\"#{r.referer.url}\", #{to_js_date(r.first_visit)}" }.flatten.join(",\n")
     rs.map{|r| "\"#{r.referer.url}\", #{to_js_date(r.first_visit)}" }.flatten.join(",\n")
  end
  def to_js_date(d)
    #return "new Date(#{d.year},#{d.month},#{d.day},#{d.hour},#{d.min},#{d.sec})"    
    return "new Date(#{d.to_i*1000})"
  end
end
