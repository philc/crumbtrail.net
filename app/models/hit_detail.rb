class HitDetail < ActiveRecord::Base
  belongs_to :project

  @@os_keys = %w[os_w2k os_xp os_w2k3 os_vista os_w98 os_w95 os_linux os_macosx]
  @@browser_keys = %w[b_firefox15 b_firefox20 b_ie5 b_ie6 b_ie7 b_safari b_other]

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

    stats = Hash.new(0)
    hash_call = (type.to_s + "_stats").to_sym
    for r in rows
      r_hash = r.send(hash_call) 
      r_hash.each_key {|key| stats[key] += r_hash[key]}
    end

    return stats
  end

  def browser_stats()
    hash = Hash.new(0)
    for key in @@browser_keys
      hash[key[2, key.length].to_sym] = send(key.to_sym)
    end

    return hash;
  end

  def os_stats()
    hash = Hash.new(0)
    for key in @@os_keys
      hash[key[3, key.length].to_sym] = send(key.to_sym)
    end

    return hash;
  end

end
