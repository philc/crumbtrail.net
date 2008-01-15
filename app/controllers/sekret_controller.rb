class SekretController < ApplicationController
  skip_before_filter :stealth_mode?
  before_filter :bypass_stealth
  
  def bypass_stealth
    cookies[:sekret] = "SuperSekretCode"
    redirect_to "/"
  end
  
  def index
  end
end
