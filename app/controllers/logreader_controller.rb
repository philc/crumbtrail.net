require 'script/logreader.rb'

class LogreaderController < ApplicationController
  def index
    ApacheLogReader::tail_log("script/test.log")
  end
end
