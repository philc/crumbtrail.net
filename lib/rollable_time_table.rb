module RollableTimeTable
  def self.increment_referer(request, time_column, time_method, c)
    project = request.project
    referer = request.referer
    time = request.time

    referral = c.find(:first, :conditions => ["project_id = ? AND referer_id = ? AND #{time_column.to_s} = ?", project.id, referer.id, time.send(time_method)])

    if (!referral.nil? && 
       ((referral.last_update.day != time.day) || 
        (referral.last_update.month != time.month) || 
        (referral.last_update.year != time.year)))
      referral.count = 0
    end

    if referral.nil?
      referral = c.new(:project_id => project.id,
                       :referer_id => referer.id,
                       time_column => time.send(time_method),
                       :count => 0)
    end

    referral.count += 1
    referral.last_update = time
    referral.save

  end
end