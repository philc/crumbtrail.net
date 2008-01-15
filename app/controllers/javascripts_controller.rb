class JavascriptsController < ApplicationController
  skip_before_filter :stealth_mode?
  before_filter :set_headers
  session :off
  layout nil

  def index
    render :file => "vendor/plugins/jsext/lib/" + params[:jsfile].to_s
  end

  private
  def set_headers
    headers['Content-Type'] = 'text/javascript; charset=utf-8'
  end
end
