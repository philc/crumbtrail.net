class ProjectController < ApplicationController
  @@project_id=1050
  
  # These are the default view strings, in case they don't have a cookie
  # expressing what section they should be viewing
  @@default_view={
    :section=>:glance,
    :hits=>:today,
    :referers=>:recent,
    :pages=>:recent,
    :searches=>:recent
  }
  
  # Number of entries to show in each table
  @@size=10
  
  #
  # Fetches the user's project data and fills javascript variables with them.
  # Javascript does the actual table and graph drawing
  #
  def index
    # get the view options from their cookie
    @view_options=view_options_from_cookie(cookies[:breadcrumbs])   
    
    p = Project.find(@@project_id)    
    @project=p   
    
    # use the date in the view that we have on record for them.    
    @date = JSDate.new(p.time).to_json;
    
    build_glance_and_hits()
    
    build_referers(p) 
    
    build_pages()
    
    build_searches()
    
    # Details; browser and OS
    build_details(p)       
  end
 
  #
  # fetches data used for pagination
  #
  def data
    project = Project.find(@@project_id)    
    
       
    page=params[:p].to_i
    page=0 if (page<-1)
    
    puts "page we got:",page
    
    # a parameter of -1 means find the last page
    if (page==-1)
      rowCount = project.count_top_referers()
      page = (rowCount/@@size).floor()
    end
    
    # request one more than we need; if we get it, then there is more
    # referers to show, and the "next" link should be enabled.
    # if we don't get it, then there are no more items to show
    @data=project.top_referers(@@size+1,page*@@size)
    @more = @data.length>@@size
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
  def build_searches()
    @searches_recent=@project.recent_searches().map{|s|
      [s.search_words,s.referer.url,JSDate.new(s.visit_time)]
      }.flatten.to_json
    @searches_total=@project.top_searches(@@size).map{|s|
      [s.search_words,s.referer.url,s.count]
    }.flatten.to_json
  end
  def build_pages()
      @popular_pages=@project.top_landings(@@size).map{|p|
        [p.page.url,p.count]
      }.flatten.to_json
      @recent_pages=@project.recent_landings().map{|p|
        [p.page.url,p.referer.url,JSDate.new(p.visit_time)]
      }.flatten.to_json
  end
  
  def build_glance_and_hits()
    week_data=@project.hits(:week)
    
    @glance_today=week_data[0]    
    @glance_yesterday=week_data[1]
    
    @hits_day=@project.hits(:day).join(",")
    @hits_week=@project.hits(:week).join(",")  
    @hits_month=@project.hits(:month).join(",")
    @hits_year=@project.hits(:year).join(",")
  end
  
  def build_referers(p)
    @referers_total = p.top_referers(@@size+1)
    @referers_more = @referers_total.length>@@size
    @referers_total = @referers_total[0..-2] if @referers_more    
    
    @referers_total=@referers_total.map{|r|
      [r.referer.url,r.page.url,r.count]}.flatten.to_json
    
    @referers_unique = p.recent_unique_referers(@@size).map {|r|
      [r.referer.url,r.page.url,JSDate.new(r.first_visit)]
    }.flatten.to_json

    @referers_recent = p.recent_referers().map{|r|
      [r.referer.url,r.page.url,JSDate.new(r.visit_time)]
    }.flatten.to_json
  end
  
  def build_details(p)
    # drop entries that are 0
    @browser_labels=[]
    @browser_data=[]
    browsers = p.get_details(:browser)
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
end

# Utility class for stripping UTC from a date string and building a javascript date from it
class JSDate
  def initialize(d)
    @date=d.to_s.sub("UTC","")
  end
  def to_json
    return "new Date(\"#{@date}\")"
  end
end
