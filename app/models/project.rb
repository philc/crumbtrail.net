class Project < ActiveRecord::Base
  belongs_to :account
  belongs_to :zone
  has_many   :referers
  has_many   :referral_totals
  has_one    :row_tracker
  has_one    :recent_project, :class_name => "Project"
  serialize  :collapsing_refs

  def process_request(request)
    lock

    referer = request.referer
    page = request.page

    if referer.url != '-' && referer.url != '/' && page.url != '-'
      search_terms = SearchTotal.analyze_search_url(request.referer.url)
      if !search_terms.nil?
        SearchTotal.increment_search_string(request, search_terms)
        SearchRecent.add_new_search(request, search_terms)
      else
        increment_referer(request)
      end

      increment_page_landing(request)
      record_details(request)
    end

    increment_hit_count(request)
    save

    unlock
  end

  @@domain_regex = '^([A-Za-z0-9\.]+)'

  def get_referer(url)
    url.match(@@domain_regex)
    domain = $1

    return nil if domain.nil?

    self.collapsing_refs = [] if self.collapsing_refs.nil?

    referer = self.collapsing_refs.find { |ref| ref[0] == domain }
    if !referer.nil?
      return Referer.find_by_id(referer[1].to_i)
    else
      return Referer.get_referer(self, url)
    end

  end

  def collapse_referer(url)
    url.match(@@domain_regex)
    domain = $1

    # Return if the domain is already collapsed
    self.collapsing_refs = [] if self.collapsing_refs.nil?
    return nil if domain.nil? || self.collapsing_refs.find { |ref| ref[0] == domain }

    #todo - make sure its not a search domain

    lock

    # Find all the referers from the collapsing domain (including subdomains of the domain)
    collapsables = Referer.find(:all, :conditions => ['project_id = ? AND url REGEXP ?', id, "[A-Za-z0-9\.]*#{domain}/"])

    return nil if collapsables.length == 0

    # Create the record for the collapsed domain
    domain_row = Referer.create(:project_id => id, :url_hash => domain.hash, :url => domain+'/')

    # Update the project to collapse this domain in the future
    self.collapsing_refs << [domain, domain_row.id]
    self.save

    # Collapse ReferralTotal
    count = 0
    first_visit = self.time
    page_id = nil
    collapsing_ref_totals = find_collapsable_records(collapsables, referral_totals)

    return nil if collapsing_ref_totals.length == 0 # shouldn't happen, but just in case

    collapsing_ref_totals.each do |ref|
      count += ref.count
      first_visit = ref.first_visit if ref.first_visit < first_visit
      page_id = ref.page_id
      ref.destroy
    end
    ReferralTotal.create(:project_id => id,
                         :referer_id => domain_row.id,
                         :page_id => page_id,
                         :first_visit => first_visit,
                         :count => count)

    # Redirect referer ID in remaining tables
    change_tables = [LandingTotal, LandingRecent, ReferralRecent]
    change_tables.each do |table|
      table.find_all_by_project_id(id).each do |record|
        if is_collapsable_record(collapsables, record)
          record.referer_id = domain_row.id
          record.save
        end
      end
    end

    # Destroy the referer records
    collapsables.each { |ref| ref.destroy }

    unlock

    return domain_row.id
  end

# =Referers
#------------------------------------------------------------------------------

  # Returns an array of RecentReferrals (Length hardcoded at 10)
  def recent_referers()
     return ReferralRecent.get_recent_referers(self)
  end

  # Returns an array of TotalReferrals
  #  limit - the number of referers you want returned
  def recent_unique_referers(limit)
    return ReferralTotal.get_recent_unique(self, limit)
  end

  # Returns an array of TotalReferrals
  #  limit - the number of referers you want returned
  def top_referers(limit, offset=0)
    return ReferralTotal.get_top_referers(self, limit, offset)
  end

  def count_top_referers()
    return ReferralTotal.count_top_referers(self)
  end

# =Searches
#------------------------------------------------------------------------------

  def top_searches(limit, offset=0)
    return SearchTotal.get_top_searches(self, limit, offset)
  end

  def count_top_searches()
    return SearchTotal.count_top_searches(self)
  end

  def recent_searches()
    return SearchRecent.get_recent_searches(self)
  end

# =Hits
#------------------------------------------------------------------------------

  # Get the hit count for a specified period.
  # Period can be :day, :week, or :month
  #
  # Returns an array containing hit counts for time devisions of the specified
  # period, most recent first
  def hits(period)
    if period == :today
      return HitDaily.get_hits_today(self)
    elsif period == :day
      return HitHourly.get_hits(self)
    elsif period == :week
      return HitDaily.get_past_week_hits(self)
    elsif period == :month
      return HitDaily.get_past_month_hits(self)
    elsif period == :year
      return HitMonthly.get_hits(self)
    end
  end

# =Landings
#------------------------------------------------------------------------------

  def top_landings(limit)
    return LandingTotal.get_most_popular(self, limit)
  end

  def recent_landings()
    return LandingRecent.get_recent_landings(self)
  end

# =Details
#------------------------------------------------------------------------------

  def get_details(type)
    return HitDetail.get_details(self, type)
  end

# =Time
#------------------------------------------------------------------------------

  def time(*t)
    t[0] = Time.now if t.empty?
    TimeHelpers.convert_to_client_time(self, t[0])
  end

private

  def increment_referer(request)
    ReferralTotal.increment(request)
    ReferralRecent.add_new_referer(request)
  end

  def increment_hit_count(request)
    HitHourly.increment_hit(request)
    HitDaily.increment_hit(request)
    HitMonthly.increment_hit(request)
    self.first_hit = request.time if self.first_hit.nil?
    self.total_hits += 1
    self.unique_hits += 1 if request.unique
  end

  def increment_page_landing(request)
    LandingTotal.increment(request)
    LandingRecent.add_new_landing(request)
  end

  def record_details(request)
    HitDetail.record_details(request)
  end

# =Collapsing
#------------------------------------------------------------------------------

  def find_collapsable_records(collapsed_referers, rows)
    return rows.select { |row| is_collapsable_record(collapsed_referers, row) }
  end

  def is_collapsable_record(collapsed_referers, row)
    #todo - make a faster search
    bool = collapsed_referers.find { |x| x.id == row.referer_id }
    bool = bool ? true : false
    return bool
  end

# =Locking
#------------------------------------------------------------------------------

  @@tables = %w{ search_totals search_recents
                 landing_totals landing_recents 
                 referral_totals referral_recents 
                 hit_hourlies hit_dailies hit_monthlies 
                 referers }
  @@sql_lock = nil

  def lock()
    build_lock_string if @@sql_lock.nil?
    connection.execute @@sql_lock
  end

  def unlock()
    connection.execute "UNLOCK TABLES;"
  end

  def build_lock_string
    @@sql_lock = "LOCK TABLES #{@@tables[0]} WRITE"
    for table in @@tables[1..@@tables.length]
      @@sql_lock += ", #{table} WRITE"
    end
  end

end
