# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # Don't filter anything to the production logs that matches "password"
  filter_parameter_logging "password"
  
  
  
  protected
  
  def login(username,password)
    result=Account.authenticate(username,password)
    if (result.class==Account)
      # redirect to projects
      redirect_to :controller=>"project"
    else
      # It's an error message
      return result
    end
  end
  
  def self.login_token(username)
    
  end
end