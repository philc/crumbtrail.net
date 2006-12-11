class ProjectController < ApplicationController
   @@project_id=1050
   
  def index
    @project_id=@@project_id
    p = Project.find(@project_id)    
    @project=p
    # only take the first 10 referers. Change this to a better way when we do pagination
    limit=9
    @referers_total = p.top_referers(10)
    @referers_total=format_referers_with_count(@referers_total)
    
    # use the date in the view that we have on record for them.    
    @date = to_js_date(p.time);
    
    
    @referers_unique= format_referers_date(p.recent_unique_referers(10)[0..limit])

    @referers_recent=format_referers_recent(p.recent_referers()[0..limit])
  
    @hits_day=p.hits(:day).join(",")    
    
    weekData=p.hits(:week)
    @hits_week=weekData.join(",")  
    
    
    @glance_today=weekData[0]    
    @glance_yesterday=weekData[1]
    
    @hits_month=p.hits(:month).join(",")
    
    @preferences = ViewPreference.find_by_project_id(@project_id)
    
    # Pages
    @popular_pages=format_pages(p.most_popular_pages(10))
    @recent_pages=format_pages(p.most_recent_pages(10))
    
    build_details(p)

   
  end
  def build_details(p)
    # drop entries that are 0
    @browser_labels=[]
    @browser_data=[]
    #@browsers = p.get_details(:browser).select{|k,v| v>0}
    browsers = p.get_details(:browser)
    # Data is now [ [browser,5], ... ]    
    HitDetail.browser_display.each do |key|
      v=browsers[key]
      next if v <=0
      @browser_labels << "\"#{key}\""
      @browser_data<<v
    end
    
    @browser_labels=@browser_labels.join(',')
    @browser_data=@browser_data.join(',')   
    
    # drop entries that are 0
    @os_labels=[]
    @os_data=[]
    os = p.get_details(:os)
    HitDetail.os_display.each do |key|
      v=os[key]
      next if v <=0
      @os_labels << "\"#{key}\""
      @os_data<<v
    end    
    
    @os_labels=@os_labels.join(',')
    @os_data=@os_data.join(',')
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
  
  def format_pages(pages)
    pages.map{|p| "\"#{p.url}\", #{p.count}"}.flatten.join(",\n")
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
    return "new Date(\"#{d.to_s.sub("UTC","")}\")"
  end
end
