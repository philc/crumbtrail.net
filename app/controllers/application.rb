# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # Don't filter anything to the production logs that matches "password"
  filter_parameter_logging "password"
  before_filter :signed_in?
 
  
  @@login_cookie=:login_token
  
  protected
  
  def login(username,password)
    result=Account.authenticate(username,password)
    
    if (result.class==Account)
      # Create a new session & cookie for this client
      cookies[@@login_cookie] = 
        {:value=>Session.create_for(result).token, :expires=>Session.expiration_time}
    
      redirect_to :controller=>"project"
    else
      # It's an error message
      return result
    end
  end
  
  def signed_in?

    # TESTING - just log in with a test user
#     @account=Account.authenticate("demo","pass1")
#     return
    token = cookies[@@login_cookie]    
    # TODO - re-enable this
    return nil if token.nil?
    
    # See if this token matches one of our accounts
    @account = Account.from_token(token)
    
    
    
    # Update their cookie
    if (@account)
      cookies[@@login_cookie] = { :value => token, :expires => Session.expiration_time}
    else #erase this state cookie
      cookies[@@login_cookie] = { :value=>"", :expires=>5.days.ago}
    end
    #return account    
  end
  
  def logout()    
    cookies[@@login_cookie] = { :value=>"", :expires=>5.days.ago}
  end
end