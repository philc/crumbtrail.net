class ViewPreference < ActiveRecord::Base

    # details and glance don't have a model element in the db because they have no navlinks.
    # Any operations on it are basically a no-op.
    attr_accessor :details  
    @@sections={"glance"=>"","hits"=>"","referers"=>"","pages"=>"","searches"=>"","details"=>""}
    
    # add "valid values" for each section..
    #     @@valid_hits={:today=>"",:week=>"",:month=>"",:year=>""}

    def defaults()
      self.hits="today"
      self.referers="total"
      self.pages="today"
      self.searches="today"
      self.panel="referers"
    end
    def visible(section,id)
      return if  @@sections[section].nil?
      puts self.send(section)
      return (self.send(section)==id)
    end
    
    # this should be panel=, but I'm not sure how to do that with active record though.
    def set_section(v)
      self.panel=v unless (@@sections[v].nil?)
    end
    def set_panel(panel,value)
      puts "settign panel" + panel;
      return if  @@sections[panel].nil?
      puts "settign panel" + panel;
      self.send(panel+"=",value)
    end
    
#     def panel=(v)
#       panel=v unless (@@valid_panels[value].nil?)
#     end

#     def hits=(v)
#       hits=v
#     end
#     def referers(v)
#       referers=v
#     end
#     def pages(v)
#       pages=v
#     end
#     def searches
#       searches=v
#     end
    
end
