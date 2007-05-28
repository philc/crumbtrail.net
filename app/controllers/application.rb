# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # Don't filter anything to the production logs that matches "password"
  filter_parameter_logging "password"
  before_filter :signed_in?
  session :off
  
    
  # Their login cookie contains both their account # and their session token, like this:
  #   login_cookie=account_id|session_token
  @@login_cookie=:login_token
  
  protected
  
  def login(username,password, redirect="/project/recent")
    
    result=Account.authenticate(username,password)
    
    if (result.class==Account)
      # Create a new session & cookie for this client
      @account=result
      cookies[@@login_cookie] = create_cookie(Session.create_for(result).token)    
      #redirect_to :controller=>"project"
      redirect_to redirect
    else
      # It's an error message
      return result
    end
  end
  
  def authorize()
    puts "in authorize, :",@account
    if @account.nil?
     redirect_to "/signin/?r=" + request.request_uri
      # redirect_to "/signin/"
    end
  end
  
  def create_cookie(token)
    # cookie is in format of account_id|token
    return {
      :value=>"#{@account.id}|#{token}",
      :expires => Session.expiration_time
    }
  end
  
  def signed_in?
    # TESTING - just log in with a test user
#     @account=Account.authenticate("demo","pass1")
#     return

    cookie = cookies[@@login_cookie]    
    # see top of file for the cookie format
    token = cookie.split('|')[1] unless cookie.nil?
    # TODO - re-enable this
    return nil if token.nil?
    
    puts "PROCESSING LOGIN"
    
    # See if this token matches one of our accounts
    @account = Account.from_token(token)

    
    # Update their cookie
    if (@account)
      puts "setting token to #{@account.id}|#{token}"
      cookies[@@login_cookie] = create_cookie(token)
    else #erase this state cookie
      cookies[@@login_cookie] = { :value=>"", :expires=>5.days.ago}
    end
  
  end
  
  def logout()    
    cookies[@@login_cookie] = { :value=>"", :expires=>5.days.ago}
  end
end