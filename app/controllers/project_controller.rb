class ProjectController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_filter :authorize, :except=>[:index,:pagedata,:admin]

  # These are the default view strings, in case they don't have a cookie
  # expressing what section they should be viewing
  @@default_view={
    :section=>:glance,
    :pageviews=>:today,
    :referers=>:recent,
    :pages=>:recent,
    :searches=>:recent,
  }
  @@valid_sections=[:glance,:pageviews,:referers,:pages,:searches,:details,:rankings]
  
  # Show all the projects the user has.  Also update the user's
  # settings if the user hit the submitted the update settings form.
  def all
    @title="Projects for #{@account.username} - Breadcrumbs"

    @projects=@account.projects
    @email=@account.username
    
    @style="display:none"
    
    if (request.post?)
        update_user_settings()
    end
  end
  
  # Number of entries to show in each table
  @@size=10
  def new
    @title="Create a new project - Breadcrumbs"
    if (request.post?)
      @site_name=params[:site_name]
      @site_url=params[:site_url]

      validate_project_properties()

      if (@url_error.nil? && @name_error.nil?)
        # create the project, attach it to the current user
        
        project=Project.new(:account => @account,
                            :title   => @site_name,
                            :url     => @site_url,
                            :zone_id => @account.zone_id)
        project.save!
        
        # set this project as their recently viewed one
        @account.recent_project=project
        @account.save!
        redirect_to :controller=>"project",:action=>"code", :id=>project.id
      end
    end
  end
  
  # Will fill @url_error or @name_error with error messages
  # if they are empty
  def validate_project_properties
    if (@site_name.nil? || @site_name.empty?)
      @name_error="Please fill in the name of your website"
    end
    if (@site_url.nil? || @site_url.empty?)
      @url_error="Please fill in the URL of your website"
    end
  end
  
  def recent
    p=@account.recent_project
    if (p.nil?)
      redirect_to "/project/all"
    else
      redirect_to "/project/" + p.id.to_s
    end    
  end
  
  # This is part of the signup process which shows them the code they need
  def code    
    @project=Project.find_by_id(params[:id])
    @title="Code for project #{@project.title} - Breadcrumbs"
    # @project=nil
  end

  # Allows the user to change the project name and website URL for their
  # project.
  def setup
    @project=Project.find_by_id(params[:id])
    @title="#{@project.title} setup - Breadcrumbs"

    if (!request.post?)
      # First time, fill out the form from the project
      @site_name=@project.title
      @site_url=@project.url
    else
      # Post back. process the form.
      @site_name=params[:site_name]
      @site_url=params[:site_url]
      
      validate_project_properties()
      
      if (@url_error.nil? && @name_error.nil?)
        # create the project, attach it to the current user
        @project.title=@site_name
        @project.url=@site_url
        @project.save!
        
        flash[:notice]="Project options saved. <a href='/project/#{@project.id}'>Return to your stats.</a>"
        # I need a redirect here, otherwise the flash:notice will persist across two pages.
        redirect_to "/project/setup/" + @project.id.to_s
      end
    end
  end
  
  #
  # Fetches the user's project data and fills javascript variables with them.
  # Javascript does the actual table and graph drawing
  #
  def index
    # TODO: show them that they need to log in if they're not logged in.
    # Applies to demo account
    @id = params[:id]    
    
    @project = nil
    
    # Ensure that they are logged in, unless we're viewing a demo
    if @id != "livedemo"
      authorize()
      return if @account.demo?
    end
      
    if (@id == "recent")
      @project = @account.recent_project
    elsif (@id == "livedemo")
      puts "demo account"
      @account = Account.demo_account
      @project = Project.demo_project
    else
      @project = Project.find_by_id(@id)      
    end
    
    
    # If they don't have any projects, or we can't find the one they asked for,
    # send them to where they can create a new one.
    if (@project.nil?)
      redirect_to "/project/all" 
      return
    end

    if @project!=@account.recent_project
      @account.recent_project=@project
      @account.save!
    end
    
    # get the view options from their cookie
    @view_options=view_options_from_cookie(cookies[:breadcrumbs])   

    #@all_projects=@account.projects.reject{|p| p!=@project}
    
    @title="Stats for " + @project.title.to_s + " - Breadcrumbs"
    
    # use the date in the view that we have on record for them.    
    @date = JSDate.new(@project.time).to_json;
    
    build_glance_and_hits()
    @glance_today=@glance_today.map{ |e| number_with_delimiter(e) }
    @glance_yesterday=@glance_yesterday.map{ |e| number_with_delimiter(e) }
      
    build_referers() 
    
    build_pages()
    
    build_searches()
    
    # Details; browser and OS
    build_details()
  end

  #
  # fetches data used for pagination
  #
  def pagedata
    id=params[:project]
    project = Project.find_by_id(id)

    if (project.nil?)
      render :nothing=>true
      return
    end

    # TODO: check for wrong account. Display a message with the option of logging out.
    # if project.account!=@account       

    page=params[:p].to_i
    page=0 if (page<-1)


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

    # Find out which page we're showing; the view won't know which page
    # it's asking for in the case of when it requests the "last page"
    @page=page    

    @data=@data.map{|r| 
      [r.url,r.target.url,r.count]}.flatten.to_json
    render :layout=>false
  end


  # Saves referer options
  def save_options    
    result = process_options()

    if (result.nil?)
      flash[:notice]="Updated referer options."
    else
      flash[:notice]=result
    end
    
    redirect_to "/project/" + params[:pageid]
  end
  
  # Admin page
  def admin
    @title="Admin - Breadcrumbs"
        
    if (!@account || @account.role!="a")
      redirect_to "/signin/?r=" + request.request_uri
      return
    end


    @accounts=Account.find(:all)

    # Record total number of pageviews today
    @pageviews={:today=>0,:yesterday=>0}
    @uniques={:today=>0,:yesterday=>0}


    @accounts.each do |a|
      a.projects.each do |p|
        h=p.hits(:week)
        @pageviews[:today]+=h[0][0]
        @pageviews[:yesterday]+=h[1][0]
        @uniques[:today]+=h[0][1]
        @uniques[:yesterday]+=h[1][1]
      end
    end

    @waitlist=WaitlistUser.find(:all)
  end

  private  

  # Accept "digg.com/" and "digg.com", but not "digg.com/user1"
  @@domain_regex=/^[\w]+[\.][\w\.]+[\w]+\/?$/
  
  # Attempt to update the user's password and/or e-mail address.  Verify
  #  1) The username isn't already taken
  #  2) The user entered a valid password
  #  3) The user entered matching passwords.
  #
  #  If these three things check out, update their account in our database
  def update_user_settings
    email = params[:email]

    @errors={}
    # If they entered a new email address, make sure its valid
    if (email != @email)
      @email = email
      @errors["email"]=MainHelper::validate_email(email)

      if (!@errors["email"])
        a=Account.find_by_username(email)
        @errors["email"]= "An account with that e-mail address already exists" if !a.nil?
      end
    end

    pw1=params[:password]
    pw2=params[:password_confirm]
    @errors["password"]=MainHelper::validate_password(pw1)

    if (!@errors["password"] && pw1!=pw2)
        @errors["password"]="Your passwords don't match"
    end

    # If we found no errors, go ahead and try to save their account
    @style="visible"
    unless (@errors["password"] || @errors["email"])
      @style = "display:none"

      @account.username = email
      @account.password = pw1

      if @account.save
        @success_message = "Your account settings were successfully updated."
      else
        @success_message = "Sorry, there was a problem saving your settings.  Please try again later."
      end
    end
  end

  # Process a request to save the referer options. Involves collapsing referers
  def process_options
    project = Project.find_by_id(params[:pid])
    return "" if project.nil?
    # make sure they own this project
    return "" if @account.nil? || project.account!=@account

    # Loop through each domain that we're currently collapsing; if the user set it to "off" in the UI,
    # delete it.
    project.collapsing_refs.keys.each do |key|
      project.collapsing_refs.delete(key) if (params[key]=="off")              
    end    
    project.save

    # Process the new domain they want to collapse, if they provided one
    domain=params[:domain]
    domain.strip! unless domain.nil?
    # return "That is not a valid domain." if (domain.nil? || domain.empty?)
    return nil if (domain.nil? || domain.empty?)
    # make sure it's a valid domain
    #return "That is not a valid domain." if @@domain_regex.match(domain).nil?
    return nil if (@@domain_regex.match(domain).nil?)
         
    #puts "collapsing"
    #puts "domain",domain
    result = project.collapse_referer(domain)   

    return "You don't have any referers matching the domain \"#{domain}\"" if result.nil?
  end
  
  # Build view options from the incoming cookie
  def view_options_from_cookie(cookie)
    # the cookie string looks like 
    # hits=today,referers=total,pages=recent,searches=recent,section=glance
    options=@@default_view.clone()
    return options if cookie.nil?
    pairs=cookie.split(",")    
    pairs.each do |pair|
      part=pair.split("=")
      # Ensure that "section" is a valid section in case we ever rename section names, like hits->pageviews
      if (part[0]=="section")
        puts "section", @@default_view.values
        puts "looking for",part[1].to_sym
        puts  @@default_view.values.index(part[1].to_sym)
        options[part[0].to_sym]=part[1].to_sym unless @@valid_sections.index(part[1].to_sym).nil?
      elsif (part[1]!="undefined")
        # If javascript sends us "undefined", then use the default
        options[part[0].to_sym]=part[1].to_sym
      end
    end
    return options
  end
  def build_searches()
    @searches_total=@project.top_searches(@@size).map{|s|
      [s.search_words,s.url,s.page.url,s.count]
    }.flatten.to_json
    @searches_recent=@project.recent_searches().map{|s|
      [s.search.search_words,s.search.url,s.page_url,JSDate.new(s.visit_time)]
      }.flatten.to_json
  end
  def build_pages()
      @popular_pages=@project.top_landings(@@size).map{|p|
        [p.url,p.count]
      }.flatten.to_json
      @recent_pages=@project.recent_landings().map{|p|
        [p.first_url,(p.second_url.nil? ? nil : p.second_url),JSDate.new(p.visit_time)]
      }.flatten.to_json
  end  
  
  def build_glance_and_hits()
    week_data=@project.hits(:week)
    
    @glance_today=week_data[0]    
    @glance_yesterday=week_data[1]
    
    @glance=@project.at_a_glance()
    @glance_referers_today=@glance[:today].map{|r|
      [r.url,r.target.url,r.today_count]
    }.flatten.to_json
    @glance_referers_week=@glance[:week].map{|r|
      [r.url,r.page.url,r.seven_days_count]
    }.flatten.to_json
    
    @glance_sources=@project.hit_types_percents(:today).to_json()
  
    @hits_day=@project.hits(:day).join(",")
    @hits_week=@project.hits(:week).join(",")  
    @hits_month=@project.hits(:month).join(",")
    @hits_year=@project.hits(:year).join(",")
  end
  
  def build_referers()
    @referers_total = @project.top_referers(@@size+1)
    @referers_more = @referers_total.length>@@size
    @referers_total = @referers_total[0..-2] if @referers_more    
    
    @referers_total=@referers_total.map{|r|
      [r.url,r.page.url,r.count]}.flatten.to_json
    
    @referers_recent = @project.recent_referers().map{|r|
      [r.first_url,r.second_url,JSDate.new(r.visit_time)]
    }.flatten.to_json

    @referers_unique = @project.recent_unique_referers(@@size).map {|r|
      [r.url,r.page.url,JSDate.new(r.first_visit)]
    }.flatten.to_json
  end
    
  def build_details()
    # drop entries that are 0
    @browser_labels=[]
    @browser_data=[]
    browsers = @project.get_details(:browser)
    i=0
    HitDetail.browser_display.each do |key|
      v=browsers[key]
      next if v <=0
      @browser_labels << "\"#{key}\""
      @browser_data << [i,v]
      i += 1
    end
    
    @browser_labels=@browser_labels.join(',')
    @browser_data=@browser_data.to_json
    
    # drop entries that are 0
    @os_labels=[]
    @os_data=[]
    os = @project.get_details(:os)
    i=0
    HitDetail.os_display.each do |key|
      v=os[key]
      next if v <= 0
      @os_labels << "\"#{key}\""
      @os_data << [i,v]
      i += 1
    end    
    
    @os_labels=@os_labels.join(',')
    @os_data=@os_data.to_json
  end

end

# Utility class for stripping UTC from a date string and building a javascript date from it
class JSDate
  # You want the date, to be parsable by both IE and mozilla, to be a string that looks like this:
  # new Date("Sun Feb 25 5:38:14 2007 -0500")
  # The browsers will parse that date and then show it specific to the user's locale. So
  # new Date("Sun Feb 25 5:38:14 2007 -0300") will show up as 3:38:14 2007 for people using EST
  def initialize(d)
    @date = d.to_s.sub("UTC","")
    #@date=d.strftime("%a %b %d %H:%M:%S %Y %Z")
  end
  def to_json
    #return "new Date(\"#{@date}\")"
    return "dh.jsDate(\"#{@date}\")"
  end
end
