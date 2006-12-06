class ProjectController < ApplicationController
   @@project_id=1050
   
  def index
    @project_id=@@project_id
    
    # Select top 10 referers
    @referers_total=TotalReferral.find(:all, 
    :conditions=>["project_id = ?",@project_id],:order=>"count DESC")
    
    @referers_total=format_referers_with_count(@referers_total)
#     @referers_total=[]
    
    p = Project.find(@project_id)    
    
    @referers_unique= format_referers_date(p.recent_unique())

    @referers_recent=format_referers_recent(p.recent_hits())
  
    
    # for hits today, I need to know what timezone they're in    
    @hits_week=p.hits(:week)[0].join(",")
    
    @hits_month=p.hits(:month).join(",")
    
    @preferences = ViewPreference.find_by_project_id(@project_id)
    
  end
  def lag()
    sleep 3
  end
  def setpref()
    # TODO : check here to ensure that the logged in user
    # owns this project. ACtually, change this so that view prefs are per user, not per project.
    puts "seting preference"
    render :nothing => true
    pref=params[:p]
    value=params[:v]
    puts pref,value
    puts value.class
    return if pref.nil? || value.nil?
    
    p = ViewPreference.find_by_project_id(@@project_id)
    
    puts pref,value
    
    if (pref=="section")
      p.set_section(value)
    else
      p.set_panel(pref,value)
    end
    p.save!
  end
  def format_referers_with_count(rs)
     rs.map{|r| "\"#{r.referer.url}\",#{r.count}" }.flatten.join(",\n")
  end
  def format_referers_recent(rs)
    #rs.map{|r| "\"#{r.referer.url}\",#{to_js_date(r.visit_time)}" }.flatten.join(",\n")
    rs.map{|r| "\"#{r.referer.url}\",#{to_js_date(r.visit_time)}" }.flatten.join(",\n")
  end
  def format_referers_date(rs)
     rs.map{|r| "\"#{r.referer.url}\", \"#{r.internal_url.url}\", #{to_js_date(r.first_visit)}" }.flatten.join(",\n")
  end
  def to_js_date(d)
    return "new Date(#{d.to_i*1000})"
  end
end
