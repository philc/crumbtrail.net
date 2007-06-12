#
# Taken from the css_dryer readme
#
class StylesheetsController < ApplicationController
  before_filter :set_headers
  # we handle generating the css files in production mode ourselves;
  # this controller won't get hit in production mode. 
  # after_filter  { |c| c.cache_page }
  
  session :off
  layout nil

  def index
    # change filename from css to ncss
    template = File.basename(params[:cssfile].to_s,"css").to_s + "ncss"
    render :file=>"app/views/stylesheets/"+template.to_s
  end
  private
  def set_headers
    ::ActionController::Base.page_cache_extension = '.css'
    headers['Content-Type'] = 'text/css; charset=utf-8'
  end
  


end