class MainController < ApplicationController
  helper MainHelper
  def index
#     puts params
#     puts cookies
    @account=signed_in?
    if (request.post?)
      @email=params[:email]
      
      @login_error=login(@email,params[:password])
    end
  end
  
  # TODO disallow duplicate emails
  
  def signup  
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
      
      unless (@password_error || @email_error || @duplicate_error)      
        create_account(email,pw1)
        redirect_to :controller=>"project", :action=>"first"
      end
    end       
  end
  
  def signout
    logout()
    redirect_to "/"
  end
  
  private
  
  def create_account(username, password)
     a=Account.new
     a.username=username
     a.password=password
     # TODO make this based on the client
     a.country_id=1
     a.zone_id=1
     a.save!
     s=Session.create_for(a)
     t=Session.expiration_time
     cookies[@@login_cookie] = 
          {:value=>Session.create_for(a).token, :expires=>Session.expiration_time}
#      cookies[@@login_cookie] = 
#           {:value=>Session.create_for(a), :expires=>Session.expiration_time}
  end
end
