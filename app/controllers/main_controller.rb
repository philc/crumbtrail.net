class MainController < ApplicationController
  helper MainHelper
  def index
    #@account=signed_in?
    @title="Breadcrumbs - Follow the trail"
    if (request.post?)
      @email=params[:email]
      
      @login_error=login(@email,params[:password])
    end
  end
  
  def signup
    @title="Sign up - Breadcrumbs"
    
    # You shouldn't be able to get to this page if you're logged in. If they
    # navigate here manually, forward them back to their projects
    
    
    redirect_to "/project/recent" if @account
    
    @title="Sign up"
    @zones = Zone.all
    
    if request.post?
      email=params[:email]
      @email_error=MainHelper::validate_email(email)
      
      # Check for duplicates
      if (!@email_error)
        a=Account.find_by_username(email)        
        @duplicate_error= !a.nil?
      end
            
      pw1=params[:password]
      pw2=params[:password_confirm]
      
      @password_error=MainHelper::validate_password(pw1)
      
      # No need to show that they made a typo in their
      # password if we're already showing an email or pw error
      if (pw1!=pw2 && @email_error.nil? && @password_error.nil?)
          @password_error="Your passwords don't match"
      end
      
      timezone=Zone.find_by_identifier(params[:timezone])
      return if timezone.nil?
      
      unless (@password_error || @email_error || @duplicate_error)      
        create_account(email,pw1,timezone)
        redirect_to :controller=>"project", :action=>"new"
      end
    end       
  end

  def signin
    @title="Sign in - Breadcrumbs"
    # If they get to this page and are already logged in (like in another frame),
    # continue their redirect. If there's none, send them to their project page
    redirect = params[:r]
    if (redirect.nil? || redirect.empty? || redirect =~ /signin/i)
      redirect="/project/recent"
    end
    if (@account)
      redirect_to redirect
    end

    if (request.post?)
      @email=params[:email]
      @login_error=login(@email,params[:password], redirect)
    end
  end

  def signout
    logout()
    redirect_to "/"
  end
  
  private
  
  def create_account(username, password, timezone)
     a=Account.new
     a.username=username
     a.password=password
     # a.access_key=MD5.hexdigest(username + password + rand(500).to_s)
     # TODO make this based on the client
     a.country_id=1
     a.zone=timezone
     a.save!
    # a=Account.setup(username,password,timezone)
    # a.country_id=1
    # a.save!
     cookies[@@login_cookie] = 
          {:value=>Session.create_for(a).token, :expires=>Session.expiration_time}
  end
end
