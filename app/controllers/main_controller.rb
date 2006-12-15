class MainController < ApplicationController
  helper MainHelper
  def index
#     puts params
#     puts cookies
    if (request.post?)
      @email=params[:email]
      
      @login_error=login(@email,params[:password])
    end
  end
  def signup
  
    if request.post?
      email=params[:email]
      @email_error=MainHelper::validate_email(email)
      pw1=params[:password]
      pw2=params[:password_confirm]
      
      @password_error=MainHelper::validate_password(pw1)
      
      # No need to show that they made a typo in their
      # password if we're already showing an email or pw error
      if (pw1!=pw2 && @email_error.nil? && @password_error.nil?)
          @password_error="Your passwords don't match"
      end
      redirect_to :controller=>"project", :action=>"first"
    end
    
    
    
  end
  
end
