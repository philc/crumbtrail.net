class ProjectController < ApplicationController
   @@project_id=1050
   
  def index
    @project_id=@@project_id
    p = Project.find(@project_id)    
    
    # Select top 10 referers
#     @referers_total=TotalReferral.find(:all, 
#     :conditions=>["project_id = ?",@project_id],:order=>"count DESC")
    @referers_total = p.top_referers(20)
    @referers_total=format_referers_with_count(@referers_total)
#     @referers_total=[]
    
    
    
    @referers_unique= format_referers_date(p.recent_unique_referers(10))

    @referers_recent=format_referers_recent(p.recent_referers())
  
    # for hits today, I need to know what timezone they're in    
    @hits_day=p.hits(:day).flatten.join(",")    
    
    @hits_week=p.hits(:week).join(",")
    
    @hits_month=p.hits(:month).join(",")
    
    @preferences = ViewPreference.find_by_project_id(@project_id)
    
    
    # drop entries that are 0
    @browser_labels=[]
    @browser_data=[]
    @browsers = p.get_details(:browser).select{|k,v| v>0}
    # Data is now [ [browser,5], ... ]    
    @browsers.each do |pair|    
      @browser_labels<<"\"#{pair[0]}\""
      @browser_data<<pair[1]
    end
    
    @browser_labels=@browser_labels.join(',')
    @browser_data=@browser_data.join(',')
    
    
    
    # drop entries that are 0
    @os_labels=[]
    @os_data=[]
    @os= p.get_details(:os).select{|k,v| v>0}
    @os.each do |pair|    
      @os_labels<<"\"#{pair[0]}\""
      @os_data<<pair[1]
    end
    
    @os_labels=@os_labels.join(',')
    @os_data=@os_data.join(',')
    
    puts @os_labels
    puts @os_data
    
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
     rs.map{|r| "\"#{r.referer.url}\", \"#{r.landing_url.url}\",#{r.count}" }.flatten.join(",\n")
  end
  def format_referers_recent(rs)
    #rs.map{|r| "\"#{r.referer.url}\",#{to_js_date(r.visit_time)}" }.flatten.join(",\n")
    rs.map{|r| "\"#{r.referer.url}\", \"#{r.landing_url.url}\", #{to_js_date(r.visit_time)}" }.flatten.join(",\n")
  end
  def format_referers_date(rs)
     rs.map{|r| "\"#{r.referer.url}\", \"#{r.landing_url.url}\", #{to_js_date(r.first_visit)}" }.flatten.join(",\n")
  end
  def to_js_date(d)
    return "new Date(#{d.to_i*1000})"
  end
end
