#!/usr/bin/env ruby

# Use this script to reset all hit data for all projects.

APP_PATH=File.dirname(__FILE__) + '/../'
require APP_PATH + "/config/environment"


def reset_project( p )
  p.referrals_row = 0
  p.hits_row = 0
  p.landings_row = 0
  p.searches_row = 0
  p.total_hits = 0
  p.unique_hits = 0
  p.direct_hits = 0
  p.search_hits = 0
  p.referer_hits = 0
  p.first_hit = nil

  p.save!
end

projects = Project.find(:all)

projects.each do |p|
  reset_project(p)
end
