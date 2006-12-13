class ProjectController < ApplicationController
  @@project_id=1050
  
  # These are the default view strings
  @@default_view={
    :section=>:glance,
    :hits=>:today,
    :referers=>:recent,
    :pages=>:recent,
    :searches=>:recent
  }

  def index
    # get the view options from their cookie
    @view_options=view_options_from_cookie(cookies[:breadcrumbs])
    
    size=10
    
    p = Project.find(@@project_id)    
    @project=p   
    
    
    @referers_total = p.top_referers(size+1)
    @referers_more = @referers_total.length>size
    @referers_total = @referers_total[0..-2] if @referers_more
    
    
    #@referers_total=format_referers_with_count(@referers_total)
    @referers_total=@referers_total.map{|r| 
      [r.referer.url,r.page.url,r.count]}.flatten.to_json

    
    # use the date in the view that we have on record for them.    
    @date = to_js_date(p.time);
    
    
    @referers_unique= format_referers_date(p.recent_unique_referers(10)[0..size-1])

    @referers_recent=format_referers_recent(p.recent_referers()[0..size-1])
  
    @hits_day=p.hits(:day).join(",")    
    
    weekData=p.hits(:week)
    @hits_week=weekData.join(",")  
    
    @hits_year=p.hits(:year).join(",")
    
    @glance_today=weekData[0]    
    @glance_yesterday=weekData[1]
    
    @hits_month=p.hits(:month).join(",")
    
    @preferences = ViewPreference.find_by_project_id(@@project_id)
    
    # Pages
    @popular_pages=format_total_pages(p.top_landings(10))
    @recent_pages=format_recent_pages(p.recent_landings)

    # Details; browser and OS
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
 
  
  def format_total_pages(pages)
    pages.map{|p| "\"#{p.page.url}\", #{p.count}"}.flatten.join(",\n")
  end
  def format_recent_pages(pages)
    pages.map{|p| "\"#{p.page.url}\", \"#{p.referer.url}\", #{to_js_date(p.visit_time)}"}.flatten.join(",\n")
  end
  
  def format_referers_with_count(rs)
     rs.map{|r| "\"#{r.referer.url}\", \"#{r.page.url}\",#{r.count}" }.flatten.join(",\n")
  end
  def format_referers_recent(rs)
    #rs.map{|r| "\"#{r.referer.url}\",#{to_js_date(r.visit_time)}" }.flatten.join(",\n")
    rs.map{|r| "\"#{r.referer.url}\", \"#{r.page.url}\", #{to_js_date(r.visit_time)}" }.flatten.join(",\n")
  end
  def format_referers_date(rs)
     rs.map{|r| "\"#{r.referer.url}\", \"#{r.page.url}\", #{to_js_date(r.first_visit)}" }.flatten.join(",\n")
  end
  def to_js_date(d)
    return "new Date(\"#{d.to_s.sub("UTC","")}\")"
  end
  def data
    size=10
    project = Project.find(@@project_id)    
    
       
    page=params[:p].to_i
    page=0 if (page<-1)
    
    puts "page we got:",page
    
    # a parameter of -1 means find the last page
    if (page==-1)
      rowCount = project.count_top_referers()
      page = (rowCount/size).floor()
    end
    
    # request one more than we need; if we get it, then there is more
    # referers to show, and the "next" link should be enabled.
    # if we don't get it, then there are no more items to show
    @data=project.top_referers(size+1,page*size)
    @more = @data.length>size
    @data=@data[0..-2] if @more
    
    # Find out which page we're showing; the review won't know which page
    # it's asking for in the case of when it requests the "last page"
    @page=page    
    
    @data=@data.map{|r| 
      [r.referer.url,r.page.url,r.count]}.flatten.to_json
    render :layout=>false
  end
  private
  # Build view options from the incoming cookie
  def view_options_from_cookie(cookie)
    # the cookie string looks like 
    # hits=today,referers=total,pages=recent,searches=recent,section=glance
    options=@@default_view.clone()
    return options if cookie.nil?
    pairs=cookie.split(",")    
    pairs.each do |pair|
      part=pair.split("=")
      options[part[0].to_sym]=part[1].to_sym
    end
    return options
  end
end
