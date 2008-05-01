#require File.dirname(__FILE__)+"/source.rb"

class Project < ActiveRecord::Base
  belongs_to :account
  belongs_to :zone
  has_one    :recent_project, :class_name => "Project"

  # An array of collapsed referers. Contains entries of ["referer string", "row_id"]
  serialize  :collapsing_refs
  
  def after_initialize
    self.collapsing_refs = {} if self.collapsing_refs.nil?
  end

  def self.demo_project()
    # Show the ninjawords account. Can change this to another project at any time.
    return Project.find(demo_project_id)
  end
  def self.demo_project_id()
    return 1050
  end

  @@domain_regex = '^([A-Za-z0-9\.]+)'

  def process_request(request)
    locked do

      page = Page.get_or_new_page(self, request.page_url)

      unless page.nil?

        if( request.source_url != nil &&
            request.source_url != "/" &&
            request.source_url != "-" )

          source = Search.get_or_create_search( self, request.source_url, page )

          # If the source is not a search page, maybe its an external site
          if source.nil?
            collapse_id = self.get_collapsible_referer_id( request.source_url )

            if( collapse_id.nil? )
              source = Referer.get_or_create_referer( self, request.source_url, page, request.time )

            elsif collapse_id.is_a?(Fixnum)
              source = Referer.get_referer_by_id( collapse_id, self, page, request.time )

            elsif collapse_id.is_a?(Symbol)
              request.source_url.match(@@domain_regex)
              domain = $1
              source = Referer.create_referer( self, domain, page, request.time )
              self.collapsing_refs[domain] = source.id

            end
          end
        end

        # Save the source ID on the target record
        unless source.nil?
          if source.class == Referer
            page.source_id   = source.id
            page.source_type = "r"
            ReferralRecent.add_new_referer( self, source.url, page.url, request.time )
          elsif source.class == Search
            page.source_id   = source.id
            page.source_type = "s"
            SearchRecent.add_new_search( self, source, page, request.time )
          end

          PagehitRecent.add_new_hit( self, page.url, source.url, request.time )
        end

        increment_hit_count(request, source)
        HitDetail.record_details( self, request.browser, request.os, request.time )

        page.save

      end

      self.save
    end
  end

  def get_collapsible_referer_id(url)
    url.match(@@domain_regex)
    domain = $1

    return nil if domain.nil?

    return self.collapsing_refs[domain]
  end
  
  def collapse_referer(url)
    url.match(@@domain_regex)
    domain = $1

    locked do

      # Return if the domain is already collapsed
      refid = get_collapsible_referer_id(domain)
      return nil if refid.is_a?(Fixnum)

      # Find all the referers from the collapsing domain (including subdomains of the domain)
      collapsables = Referer.find(:all, :conditions => ['project_id = ? AND url REGEXP ?', id, "[A-Za-z0-9\.]*#{domain}/"])

      # If there is nothing to be collapsed yet, return early
      if collapsables.length == 0
        self.collapsing_refs[domain] = :no_id
        self.save
        return nil
      end

      # Create the record for the collapsed domain
      d = Referer.new(:project_id => id, :url_hash => domain.hash, :url => domain+'/', :first_visit => Time.at(0))

      # Add up the total of hits coming from this domain
      ids = {}
      collapsables.each do |ref|
        ids[ref.id] = 1
        d.count += ref.count
        if d.first_visit < ref.first_visit
          d.page = ref.page
          d.first_visit = ref.first_visit
        end
      end

      # Delete all referers that have been collapsed
      Referer.delete(collapsables)

      d.save

      # I'm not sure we even use this data anywhere, but update
      # all pages to say their hit came from the collapsed url 
      Page.find_all_by_project_id(id).each do |page|
        if page.source_type == 'r' && defined?(ids[page.source_id])
           page.source_id = d.id
           page.save
        end
      end

      # Update the project to collapse this domain in the future
      self.collapsing_refs[domain] = d.id
      self.save

    end
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
    return Referer.get_recent_unique(self, limit)
  end

  # Returns an array of TotalReferrals
  #  limit - the number of referers you want returned
  def top_referers(limit, offset=0)
    return Referer.get_top_referers(self, limit, offset)
  end

  def count_top_referers()
    return Referer.count_top_referers(self)
  end

  def at_a_glance(limit = 3)
    return Referer.at_a_glance(self, limit)
  end

  # =Searches
  #------------------------------------------------------------------------------

  def top_searches(limit, offset=0)
    return Search.get_top_searches(self, limit, offset)
  end

  def count_top_searches()
    return Search.count_top_searches(self)
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
  
  #
  # The source of your traffic - whether direct, from referers, or from search
  #
  def hit_types(period)
    hits = nil
    if period == :today
      hits = HitHourly.get_hit_sources(self)
    elsif period == :total
      hits = {}
      hits[:referer] = self.referer_hits
      hits[:search] = self.search_hits
      hits[:direct] = self.direct_hits
    end
    return hits
  end

  def hit_types_percents(period)
    hits = self.hit_types(period)
    total = hits.values.sum()
    return hits if total==0
    
    hits.each_key{|k| hits[k]=hits[k]*100.0/total }
    return hits
  end

  # =Landings
  #------------------------------------------------------------------------------

  def top_landings(limit)
    return Page.get_most_popular(self, limit)
  end

  def recent_landings()
    return PagehitRecent.get_recent_hits(self)
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

  def increment_hit_count(request, source)

    type = :direct
    if source.class == Referer
      type = :referer
    elsif source.class == Search
      type = :search
    end

    HitHourly.increment_hit( self, request.time, request.unique, type )
    HitDaily.increment_hit( self, request.time, request.unique )
    HitMonthly.increment_hit( self, request.time, request.unique )

    self.first_hit = request.time if self.first_hit.nil?
    self.total_hits += 1
    self.unique_hits += 1 if request.unique

    type_count = self.send((type.to_s + '_hits').to_sym)
    self.send((type.to_s + '_hits=').to_sym, type_count + 1)
  end

  # =Locking
  #------------------------------------------------------------------------------

  @@tables = %w{ 
    searches pages referers
    pagehit_recents referral_recents search_recents
    hit_hourlies hit_dailies hit_monthlies hit_details }
  @@sql_lock = nil

  def locked()
    lock()
    yield
  ensure
    unlock()
  end
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
