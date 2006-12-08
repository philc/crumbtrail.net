require 'script/logreader.rb'

class LogreaderController < ApplicationController
  def index
    ApacheLogReader::tail_log("/var/log/apache2/stats.crumbtrail/access.log")
  end
end
