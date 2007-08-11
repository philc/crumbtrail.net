require "find"

namespace :js do
  desc "Minify javascript src for production environment"
  task :min => :environment do
    jsdir='public/javascripts/'
    jslib="vendor/plugins/javascripts/lib"
    # These are files that must be included first, or in a specific order.
    # The rest of the .js files in the javascript directory will be
    # included automatically, after these files.
    libs = [
      'public/javascripts/mootools.js', 
      "#{jslib}/util.mootools.js",
      "#{jslib}/util.js",
      "#{jslib}/forms.js",
      "#{jslib}/util.dom.js",
      "#{jslib}/util.dombuilder.js",
      'public/javascripts/ui.js'
    ]

    files = find_js_files(jsdir)

    # Remove duplicates
    files.reject!{|e| libs.include?(e) }

    # sort by file length, so rte.js comes before rte.links.js
    files=files.sort_by{|e| e.length}

    libs.concat(files)
    # paths to jsmin script and final minified file
    jsmin = 'script/javascript/jsmin.rb'
    final = 'public/javascripts/all_min.js'
    # create single tmp js file
    tmp = Tempfile.open('all')
    libs.each {|lib| open(lib) {|f| tmp.write(f.read) } }
    tmp.rewind

    # minify file
    %x[ruby #{jsmin} < #{tmp.path} > #{final}]
    puts "\n#{final}"
  end

  # Finds all .js files in the given directory.
  # Excludes the file all_min.js
  def find_js_files(directory)

    files=[]
    Find.find(directory) do |f|
      if f.ends_with?('~') || (FileTest.directory?(f) && f!=directory)
        Find.prune 
      end 
      files.push(f) if f!=directory and f.ends_with?(".js") and !f.ends_with?("all_min.js")
    end
    return files
  end
end


