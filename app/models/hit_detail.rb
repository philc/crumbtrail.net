# Access hit details through project.hit_details(:browser|:os)
# What time period are these hit details for?
class HitDetail < ActiveRecord::Base
  belongs_to :project

  @@os={
   "os_nt"=>"Windows XP/2000/2003",
   "os_9x"=>"Windows 95/98", 
   "os_vista"=>"Windows Vista",
   "os_linux"=>"Linux",
   "os_macosx"=>"Mac OSX",
   "os_other" => "Other"}

  # order to display
  @@os_display=[ @@os["vista"],@@os["os_nt"],@@os["os_9x"],@@os["os_linux"],@@os["os_macosx"],@@os["os_other"]]
  def self.os_display
    return @@os_display
  end

  @@browser = {
    "b_firefox"=>"Firefox",
    "b_ie5_6"=>"Internet Explorer 5/6",
    "b_ie7"=>"Internet Explorer 7",
    "b_safari"=>"Safari",
    "b_other"=>"Other"}

  @@browser_display= [@@browser["b_firefox"],@@browser["b_ie5_6"],@@browser["b_ie7"],
      @@browser["b_safari"],@@browser["b_other"]]
  def self.browser_display
    return @@browser_display
  end

  def self.record_details( project, browser, os, time )
    date = Date.parse(project.time(time).to_s)

    row = find_by_project_id_and_day(project.id, date.wday)
    row = new(:project => project, :day => date.wday, :last_update => date) if row.nil?

    if row.last_update != date
      for key in @@os.keys
        row.send((key+"=").to_sym, 0)
      end

      for key in @@browser.keys
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
    
    # TODO: which is it?
    rows = find(:all,
                :conditions => ['project_id = ? AND last_update >= ?', project.id, last_week])
    rows = find(:all, :conditions=>['project_id = ?',project.id])
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
    @@browser.each do |key,display_key| 
      results[display_key]=send(key.to_sym)
    end
    return results
  end

  def os_stats()
    results = Hash.new(0)
    @@os.each do |key,display_key| 
      results[display_key]=send(key.to_sym)
    end
    return results
  end

end
