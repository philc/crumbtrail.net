class MainController < ApplicationController
  helper MainHelper

  def index
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
    
    if @account
      redirect_to "/project/recent" 
      return
    end    
    
    # If they didn't come from the beta url, send them to the waitlist
    unless (request.request_uri =~ /privatesignup/)
      redirect_to :action=>"waitlist"
      return
    end
    
    @zones = Zone.all
    @errors={}
    if (! params[:type].nil?)    

      if request.post?
        email=params[:email]
        @errors["email"]=MainHelper::validate_email(email)
      
        # See if we've already got an email registered with that name
        if (!@email_error)
          a=Account.find_by_username(email)        
          unless a.nil?
            @errors["email"]="We already have an account using that email"
          end          
          # once we support resetting your password, enable this message, with the correct link
          # We already have an account using that email. Forgotten your password?<br/>
          # <a href="mailto:mikejquinn@gmail.com?subject=[reset password for <%= params[:email] %>]">
          #   We can reset it and can email it to you</a>.
        end
            
        pw1=params[:password]
        pw2=params[:password_confirm]
      
        @errors["password"]=MainHelper::validate_password(pw1)
        # No need to show that they made a typo in their
        # password if we're already showing an email or pw error
        if (!@errors["password"] && pw1!=pw2)
          @errors["password"]="Your passwords don't match"
        end

        timezone=Zone.find_by_identifier(params[:timezone])
        return if timezone.nil?
      
        had_error = !@errors.values.reject(&:nil?).empty?
        puts "had_error:",had_error
        unless (had_error)
          # TODO: for now we're just ignoring what type of account
          # they've chosen, and every account is made to be free.
          puts "creating account"
          create_account(email,pw1,timezone)
          redirect_to :controller=>"project", :action=>"new"
          return
        end
      end     
      render :action=>"login_info"
    end 
  end

  def signin
    @title = "Sign in - Breadcrumbs"
    # If they get to this page and are already logged in (like in another frame),
    # continue their redirect. If there's none, send them to their project page
    redirect = params[:r]
    if (redirect.nil? || redirect.empty? || redirect =~ /signin/i)
      redirect="/project/recent"
    end
    
    unless (@account.demo?)
      redirect_to redirect
      return
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
  
  def about
    @title = "About - Breadcrumbs"
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
     a.last_access=Date.today
     a.save!
    # a=Account.setup(username,password,timezone)
    # a.country_id=1
    # a.save!
     cookies[@@login_cookie] = 
          {:value=>Session.create_for(a).token, :expires=>Session.expiration_time}
  end
end
