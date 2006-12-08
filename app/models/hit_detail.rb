# Access hit details through project.hit_details(:browser|:os)
# What time period are these hit details for?
class HitDetail < ActiveRecord::Base
  belongs_to :project
  # Do we need to keep track of so many windows versions? Can we intelligently group some of these windows
  # together? I don't think many people with server 2003, a $900 OS, browse the net with it such
  # that it will be an important statistic. Can we have a "windows-based" other or something?
  
  #@@os_keys = %w[os_w2k os_xp os_w2k3 os_vista os_w98 os_w95 os_linux os_macosx]
  #@@browser_keys = %w[b_firefox15 b_firefox20 b_ie5 b_ie6 b_ie7 b_safari b_other]
  
  @@os_display={
   "os_nt"=>"Windows XP/2000/2003",
   "os_9x"=>"Windows 95/98", 
   "os_vista"=>"Windows Vista",
   "os_linux"=>"Linux",
   "os_macosx"=>"Mac OSX",
   "os_other" => "Other"}

  @@os_keys=@@os_display.keys

  @@browser_display = {
    "b_firefox"=>"Firefox 1.5/2.0",
    "b_ie5_6"=>"Internet Explorer 5/6",
    "b_ie7"=>"Internet Explorer 7",
    "b_safari"=>"Safari",
    "b_other"=>"Other"}
    
  @@browser_keys=@@browser_display.keys
  
  def self.increment_browser(request)
    project = request.project
    browser = request.browser
    os      = request.os
    date = Date.parse(project.time(request.time).to_s)

    row = find_by_project_id_and_day(project.id, date.wday)
    row = new(:project => project, :day => date.wday, :last_update => date) if row.nil?

    if row.last_update != date
      for key in @@os_keys
        row.send((key+"=").to_sym, 0)
      end

      for key in @@browser_keys
        row.send((key+"=").to_sym, 0)
      end
    end

    row.send((os+"=").to_sym, row.send(os)+1) 
    row.send((browser+"=").to_sym, row.send(browser)+1)
    row.last_update = date
    row.save
  end

  def self.get_details(project, type)
    date = Date.parse(project.time.to_s)
    last_week = date - 6

    rows = find(:all,
                :conditions => ['project_id = ? AND last_update >= ?', project.id, last_week])

    hash_call = (type.to_s + "_stats").to_sym
    
    stats = Hash.new(0)
    
    for r in rows
      r_hash = r.send(hash_call)
      r_hash.each {|k,v| stats[k]+=v}
    end

    return stats    
  end

  def browser_stats()
    results = Hash.new(0)
    @@browser_display.each do |key,display_key| 
      results[display_key]=send(key.to_sym)
    end
    return results
  end

  def os_stats()
    results = Hash.new(0)
    @@os_display.each do |key,display_key| 
      results[display_key]=send(key.to_sym)
    end
    return results
  end

end
