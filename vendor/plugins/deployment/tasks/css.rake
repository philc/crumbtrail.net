#require 'vendor/plugins/css_dryer/lib/css_dryer'
require File.dirname(__FILE__)+"/../lib/css_dryer_ext"
namespace :css do
  desc "Concatenates css files and strips comments and superfluous whitepsace. Pipes them through css_dryer"  
  task :min => :environment do

    dest = "public/stylesheets/all_min.css"
    
    # All of our CSS files come from the app/views/stylesheets views
    src = "app/views/stylesheets/"
    libs = [
      'jjot',
      'noteboard',
      'note',
      'account',
      'forms',
      'search',
      'debug',
      'controls.tabpanel',
      'copy',
      'meta'
    ]
    
    
    libs=libs.map{|f| src+f+".ncss" }

    final_css=""
    libs.each do |lib|
      open(lib) do |f|
        final_css+=f.read
      end
    end

    c = CssDryerRenderer.new

    final_css = c.render(final_css)

    final_css = collapse_whitespace(final_css)

    
    #write it to destination
    File.open(dest,"w") {|file| file.puts final_css}
      
  end
  
  # looks for /* .(non-greedy) */
  @@css_regexp=/\/\*(.|[\n])*?\*\//
  def strip_css_comments(text)
    text.gsub(@@css_regexp,"")
  end
  @@whitespace_regexp=/([\n]\s+|\s+\n)/
  def collapse_whitespace(text)
    text.gsub(@@whitespace_regexp,"\n")    
  end
end


