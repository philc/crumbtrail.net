class TZInfo::Timezone

  #MES- Here's a Test::Unit::TestCase that does a little testing for this functionality:
  #def test_timezone_mapping
  #  #MES- Test our additions to the TZInfo::Timezone class
  #  assert_equal 'America/Panama', TZInfo::Timezone.find_timezone_name_for_offset(-18000, -18000)
  #  
  #  assert_equal 'Asia/Yekaterinburg', TZInfo::Timezone.find_timezone_name_for_offset(21600, 18000)
  #  
  #  assert_equal 'America/Los_Angeles', TZInfo::Timezone.find_timezone_name_for_offset(-1, 1)
  #  assert_equal 'America/Los_Angeles', TZInfo::Timezone.find_timezone_name_for_offset(999999, 999999)
  #end


  #We want to automatically detect what timezone a user is in.  In a web application,
  # the timezone of the user is not easily available.  However, we do have a clue.
  # The JavaScript function Date.getTimezoneOffset() returns the offset from UTC for 
  # a given date (in minutes.)  If we ask for the offset for a number of different
  # times, we can guess the timezone that the user is in.  This method is not perfect
  # but should result in a timezone that is a pretty good guess.
  # For our "probe" times, we get the offset for June 30, 2005 and for December 30, 2005.
  # June 30 is likely to be affected by Daylight Savings Time for a user that is in a zone
  # that has a DST offset, and December 30 is unlikely to be affected by DST (or the opposite
  # in the southern hemisphere.)  Probing both of these times gives us a good guess as to 
  # what the "normal" offset and DST offsets are for the timezone.
  # Choosing recent dates (at the time of this writing) assures that we are up-to-date with
  # regard to political decisions regarding the definitions of timezones (though this 
  # information may well be out of date in the future.
  #
  # To convert the offsets to a timezone, we need a list of "standard" timezones.
  # It'd be nice to run through a canonical list of timezones (such as
  # TZInfo::Timezones.all_country_zones), and probe each for the offset for the above stated
  # dates.  This has a couple of problems.  First, it could be quite slow, since calculating the
  # offset for a timezone for a date can take some time.  Second, there will be repeat entries
  # (i.e. multiple timezones that have the same offset for the two dates), and we want 
  # a semi-intelligent way to differentiate between them.
  #
  # We deal with these problems by developing a separate canonical list, represented in 
  # TIMEZONES_FOR_LOOKUP below.  It simply maps two numbers to a timezone name (well, it's
  # actually an array of objects, each of which contains the offsets and the name.)
  #
  # The TIMEZONES_FOR_LOOKUP list was created via these steps:
  # 1. Translate all items in TZInfo::Timezone.all into TZOffsetInfo objects (i.e. extract
  #   the name, summer offset, and winter offset for the days mentioned above)
  # 2. Order the items by offset (summer offset, then winter offset)
  # 3. Calculate the "popularity" of each timezone.  When multiple timezones match
  #   a given pair of offsets, we want to return the most likely match for the
  #   user, which is assumed to be the most popular (i.e. widely used) timezone
  #   that matches.  To assess popularity, a Google search is conducted for the
  #   name of each timezone (or, more precisely, for the text 'zone "[timezone name]"').
  #   The number of Google hits is assumed to roughly correlate to the popularity of
  #   the timezone.
  # 4. Among all timezones for an offset pair, choose the most popular timezone- this
  #   will be the match for that offset pair.
  #
  # Note that the number of Google matches as of now (Nov. 1, 2005) is included in 
  # TIMEZONES_FOR_LOOKUP as a trailing comment
  #
  # Finally, the find_timezone_name_for_offset function will return a timezone name
  # given a summer and winter offset by searching TIMEZONES_FOR_LOOKUP.
  #
  # For posterity, the code used to come up with the list looks like this:
  #    summer = Time.utc(2005, 6, 30, 0, 0, 0)
  #    winter = Time.utc(2005, 12, 30, 0, 0, 0)
  #    test = []
  #    TZInfo::Timezone.all.each do | zone |
  #      tzt = TZOffsetInfo.new(zone.name, zone.period_for_utc(summer).utc_total_offset, zone.period_for_utc(winter).utc_total_offset)
  #      test << tzt
  #    end
  #    
  #    test = test.sort
  #    prev_summer = nil
  #    prev_winter = nil
  #    uniques = 0
  #    test.each do | tzt |
  #      if prev_summer == tzt.summer_offset && prev_winter == tzt.winter_offset
  #        p "\#REPEAT:      TZOffsetInfo.new('#{tzt.name}', #{tzt.summer_offset}, #{tzt.winter_offset})  \#"
  #      else
  #        p "      TZOffsetInfo.new('#{tzt.name}', #{tzt.summer_offset}, #{tzt.winter_offset})  \#"
  #        prev_summer = tzt.summer_offset
  #        prev_winter = tzt.winter_offset
  #        uniques += 1
  #      end
  #    end
  #    
  #    p "#{uniques} unique zones"
  
  
  def self.find_timezone_name_for_offset(summer_offset_secs, winter_offset_secs)
    summer_offset_secs = summer_offset_secs.to_i
    winter_offset_secs = winter_offset_secs.to_i
    
    #MES- Look for a matching item in TIMEZONES_FOR_LOOKUP, or default
    def_tz = lambda {DEFAULT_TIMEZONE_INFO}
    return TIMEZONES_FOR_LOOKUP.find(def_tz) do | tz | 
      summer_offset_secs == tz.summer_offset && winter_offset_secs == tz.winter_offset
    end.name
  end
  
  #MES- A little helper class to wrap up timezone offset info
  class TZOffsetInfo
    attr_accessor :summer_offset
    attr_accessor :winter_offset
    attr_accessor :name
    
    def initialize(name, summer_offset, winter_offset)
      @name = name
      @summer_offset = summer_offset
      @winter_offset = winter_offset
    end
  end
  
  DEFAULT_TIMEZONE_INFO = TZOffsetInfo.new('America/Los_Angeles', -25200, -28800)  # 27500

  TIMEZONES_FOR_LOOKUP = [
    TZOffsetInfo.new('Pacific/Midway', -39600, -39600),  # 20600
    #REPEAT:    TZOffsetInfo.new('Pacific/Apia', -39600, -39600),  # 19600
    #REPEAT:    TZOffsetInfo.new('Pacific/Niue', -39600, -39600),  # 19500
    #REPEAT:    TZOffsetInfo.new('Pacific/Pago_Pago', -39600, -39600),  # 17100
    TZOffsetInfo.new('Pacific/Tahiti', -36000, -36000),  # 31300
    #REPEAT:    TZOffsetInfo.new('Pacific/Fakaofo', -36000, -36000),  # 19000
    #REPEAT:    TZOffsetInfo.new('Pacific/Honolulu', -36000, -36000),  # 24700
    #REPEAT:    TZOffsetInfo.new('Pacific/Johnston', -36000, -36000),  # 15400
    #REPEAT:    TZOffsetInfo.new('Pacific/Rarotonga', -36000, -36000),  # 19300
    TZOffsetInfo.new('Pacific/Marquesas', -34200, -34200),  # 20000
    TZOffsetInfo.new('America/Adak', -32400, -36000),  # 19500
    TZOffsetInfo.new('Pacific/Gambier', -32400, -32400),  # 19600
    TZOffsetInfo.new('America/Anchorage', -28800, -32400),  # 24300
    #REPEAT:    TZOffsetInfo.new('America/Juneau', -28800, -32400),  # 16200
    #REPEAT:    TZOffsetInfo.new('America/Nome', -28800, -32400),  # 16100
    #REPEAT:    TZOffsetInfo.new('America/Yakutat', -28800, -32400),  # 15900
    TZOffsetInfo.new('Pacific/Pitcairn', -28800, -28800),  # 19500
    TZOffsetInfo.new('America/Los_Angeles', -25200, -28800),  # 27500
    #REPEAT:    TZOffsetInfo.new('America/Dawson', -25200, -28800),  # 17800
    #REPEAT:    TZOffsetInfo.new('America/Tijuana', -25200, -28800),  # 21300
    #REPEAT:    TZOffsetInfo.new('America/Vancouver', -25200, -28800),  # 23700
    #REPEAT:    TZOffsetInfo.new('America/Whitehorse', -25200, -28800),  # 18800
    TZOffsetInfo.new('America/Phoenix', -25200, -25200),  # 25100
    #REPEAT:    TZOffsetInfo.new('America/Dawson_Creek', -25200, -25200),  # 15300
    #REPEAT:    TZOffsetInfo.new('America/Hermosillo', -25200, -25200),  # 15600
    TZOffsetInfo.new('America/Denver', -21600, -25200),  # 27900
    #REPEAT:    TZOffsetInfo.new('America/Boise', -21600, -25200),  # 17300
    #REPEAT:    TZOffsetInfo.new('America/Cambridge_Bay', -21600, -25200),  # 14600
    #REPEAT:    TZOffsetInfo.new('America/Chihuahua', -21600, -25200),  # 16100
    #REPEAT:    TZOffsetInfo.new('America/Edmonton', -21600, -25200),  # 21900
    #REPEAT:    TZOffsetInfo.new('America/Inuvik', -21600, -25200),  # 15900
    #REPEAT:    TZOffsetInfo.new('America/Mazatlan', -21600, -25200),  # 20800
    #REPEAT:    TZOffsetInfo.new('America/Shiprock', -21600, -25200),  # 18200
    #REPEAT:    TZOffsetInfo.new('America/Yellowknife', -21600, -25200),  # 15800
    TZOffsetInfo.new('America/Guatemala', -21600, -21600),  # 35400
    #REPEAT:    TZOffsetInfo.new('America/Belize', -21600, -21600),  # 28700
    #REPEAT:    TZOffsetInfo.new('America/Costa_Rica', -21600, -21600),  # 18300
    #REPEAT:    TZOffsetInfo.new('America/El_Salvador', -21600, -21600),  # 18000
    #REPEAT:    TZOffsetInfo.new('America/Regina', -21600, -21600),  # 20700
    #REPEAT:    TZOffsetInfo.new('America/Swift_Current', -21600, -21600),  # 14500
    #REPEAT:    TZOffsetInfo.new('America/Tegucigalpa', -21600, -21600),  # 20100
    #REPEAT:    TZOffsetInfo.new('Pacific/Galapagos', -21600, -21600),  # 20200
    TZOffsetInfo.new('Pacific/Easter', -21600, -18000),  # 20600
    TZOffsetInfo.new('America/Chicago', -18000, -21600),  # 40500
    #REPEAT:    TZOffsetInfo.new('America/Cancun', -18000, -21600),  # 24000
    #REPEAT:    TZOffsetInfo.new('America/Managua', -18000, -21600),  # 20500
    #REPEAT:    TZOffsetInfo.new('America/Menominee', -18000, -21600),  # 16100
    #REPEAT:    TZOffsetInfo.new('America/Merida', -18000, -21600),  # 14800
    #REPEAT:    TZOffsetInfo.new('America/Mexico_City', -18000, -21600),  # 19600
    #REPEAT:    TZOffsetInfo.new('America/Monterrey', -18000, -21600),  # 14800
    #REPEAT:    TZOffsetInfo.new('America/North_Dakota/Center', -18000, -21600),  # 12700
    #REPEAT:    TZOffsetInfo.new('America/Rainy_River', -18000, -21600),  # 14600
    #REPEAT:    TZOffsetInfo.new('America/Rankin_Inlet', -18000, -21600),  # 14700
    #REPEAT:    TZOffsetInfo.new('America/Winnipeg', -18000, -21600),  # 21700
    TZOffsetInfo.new('America/Panama', -18000, -18000),  # 31600
    #REPEAT:    TZOffsetInfo.new('America/Bogota', -18000, -18000),  # 22300
    #REPEAT:    TZOffsetInfo.new('America/Cayman', -18000, -18000),  # 20700
    #REPEAT:    TZOffsetInfo.new('America/Coral_Harbour', -18000, -18000),  # 581
    #REPEAT:    TZOffsetInfo.new('America/Eirunepe', -18000, -18000),  # 15500
    #REPEAT:    TZOffsetInfo.new('America/Guayaquil', -18000, -18000),  # 27200
    #REPEAT:    TZOffsetInfo.new('America/Indiana/Indianapolis', -18000, -18000),  # 14900
    #REPEAT:    TZOffsetInfo.new('America/Indiana/Knox', -18000, -18000),  # 16300
    #REPEAT:    TZOffsetInfo.new('America/Indiana/Marengo', -18000, -18000),  # 15900
    #REPEAT:    TZOffsetInfo.new('America/Indiana/Vevay', -18000, -18000),  # 15900
    #REPEAT:    TZOffsetInfo.new('America/Jamaica', -18000, -18000),  # 21600
    #REPEAT:    TZOffsetInfo.new('America/Lima', -18000, -18000),  # 21000
    #REPEAT:    TZOffsetInfo.new('America/Rio_Branco', -18000, -18000),  # 13800
    TZOffsetInfo.new('America/New_York', -14400, -18000),  # 39300
    #REPEAT:    TZOffsetInfo.new('America/Detroit', -14400, -18000),  # 23200
    #REPEAT:    TZOffsetInfo.new('America/Grand_Turk', -14400, -18000),  # 18100
    #REPEAT:    TZOffsetInfo.new('America/Havana', -14400, -18000),  # 21200
    #REPEAT:    TZOffsetInfo.new('America/Iqaluit', -14400, -18000),  # 16200
    #REPEAT:    TZOffsetInfo.new('America/Kentucky/Louisville', -14400, -18000),  # 13700
    #REPEAT:    TZOffsetInfo.new('America/Kentucky/Monticello', -14400, -18000),  # 14500
    #REPEAT:    TZOffsetInfo.new('America/Montreal', -14400, -18000),  # 24100
    #REPEAT:    TZOffsetInfo.new('America/Nassau', -14400, -18000),  # 20800
    #REPEAT:    TZOffsetInfo.new('America/Nipigon', -14400, -18000),  # 15900
    #REPEAT:    TZOffsetInfo.new('America/Pangnirtung', -14400, -18000),  # 15900
    #REPEAT:    TZOffsetInfo.new('America/Port-au-Prince', -14400, -18000),  # 19900
    #REPEAT:    TZOffsetInfo.new('America/Thunder_Bay', -14400, -18000),  # 14600
    #REPEAT:    TZOffsetInfo.new('America/Toronto', -14400, -18000),  # 13900
    TZOffsetInfo.new('America/Guyana', -14400, -14400),  # 22300
    #REPEAT:    TZOffsetInfo.new('America/Anguilla', -14400, -14400),  # 20900
    #REPEAT:    TZOffsetInfo.new('America/Antigua', -14400, -14400),  # 21300
    #REPEAT:    TZOffsetInfo.new('America/Aruba', -14400, -14400),  # 21100
    #REPEAT:    TZOffsetInfo.new('America/Barbados', -14400, -14400),  # 21200
    #REPEAT:    TZOffsetInfo.new('America/Boa_Vista', -14400, -14400),  # 14800
    #REPEAT:    TZOffsetInfo.new('America/Caracas', -14400, -14400),  # 21900
    #REPEAT:    TZOffsetInfo.new('America/Curacao', -14400, -14400),  # 20600
    #REPEAT:    TZOffsetInfo.new('America/Dominica', -14400, -14400),  # 20500
    #REPEAT:    TZOffsetInfo.new('America/Grenada', -14400, -14400),  # 20800
    #REPEAT:    TZOffsetInfo.new('America/Guadeloupe', -14400, -14400),  # 20500
    #REPEAT:    TZOffsetInfo.new('America/La_Paz', -14400, -14400),  # 17800
    #REPEAT:    TZOffsetInfo.new('America/Manaus', -14400, -14400),  # 22300
    #REPEAT:    TZOffsetInfo.new('America/Martinique', -14400, -14400),  # 20400
    #REPEAT:    TZOffsetInfo.new('America/Montserrat', -14400, -14400),  # 20200
    #REPEAT:    TZOffsetInfo.new('America/Port_of_Spain', -14400, -14400),  # 17700
    #REPEAT:    TZOffsetInfo.new('America/Porto_Velho', -14400, -14400),  # 14500
    #REPEAT:    TZOffsetInfo.new('America/Puerto_Rico', -14400, -14400),  # 18000
    #REPEAT:    TZOffsetInfo.new('America/Santo_Domingo', -14400, -14400),  # 17700
    #REPEAT:    TZOffsetInfo.new('America/St_Kitts', -14400, -14400),  # 17500
    #REPEAT:    TZOffsetInfo.new('America/St_Lucia', -14400, -14400),  # 17600
    #REPEAT:    TZOffsetInfo.new('America/St_Thomas', -14400, -14400),  # 17700
    #REPEAT:    TZOffsetInfo.new('America/St_Vincent', -14400, -14400),  # 17600
    #REPEAT:    TZOffsetInfo.new('America/Tortola', -14400, -14400),  # 19800
    TZOffsetInfo.new('America/Santiago', -14400, -10800),  # 30000
    #REPEAT:    TZOffsetInfo.new('America/Asuncion', -14400, -10800),  # 20600
    #REPEAT:    TZOffsetInfo.new('America/Campo_Grande', -14400, -10800),  # 10500
    #REPEAT:    TZOffsetInfo.new('America/Cuiaba', -14400, -10800),  # 18100
    #REPEAT:    TZOffsetInfo.new('Antarctica/Palmer', -14400, -10800),  # 17600
    #REPEAT:    TZOffsetInfo.new('Atlantic/Stanley', -14400, -10800),  # 19600
    TZOffsetInfo.new('America/Halifax', -10800, -14400),  # 22900
    #REPEAT:    TZOffsetInfo.new('America/Glace_Bay', -10800, -14400),  # 14800
    #REPEAT:    TZOffsetInfo.new('America/Goose_Bay', -10800, -14400),  # 14900
    #REPEAT:    TZOffsetInfo.new('America/Thule', -10800, -14400),  # 20900
    #REPEAT:    TZOffsetInfo.new('Atlantic/Bermuda', -10800, -14400),  # 20500
    TZOffsetInfo.new('America/Montevideo', -10800, -10800),  # 20800
    #REPEAT:    TZOffsetInfo.new('America/Araguaina', -10800, -10800),  # 16300
    #REPEAT:    TZOffsetInfo.new('America/Argentina/Buenos_Aires', -10800, -10800),  # 808
    #REPEAT:    TZOffsetInfo.new('America/Argentina/Catamarca', -10800, -10800),  # 810
    #REPEAT:    TZOffsetInfo.new('America/Argentina/Cordoba', -10800, -10800),  # 806
    #REPEAT:    TZOffsetInfo.new('America/Argentina/Jujuy', -10800, -10800),  # 809
    #REPEAT:    TZOffsetInfo.new('America/Argentina/La_Rioja', -10800, -10800),  # 815
    #REPEAT:    TZOffsetInfo.new('America/Argentina/Mendoza', -10800, -10800),  # 824
    #REPEAT:    TZOffsetInfo.new('America/Argentina/Rio_Gallegos', -10800, -10800),  # 876
    #REPEAT:    TZOffsetInfo.new('America/Argentina/San_Juan', -10800, -10800),  # 819
    #REPEAT:    TZOffsetInfo.new('America/Argentina/Tucuman', -10800, -10800),  # 818
    #REPEAT:    TZOffsetInfo.new('America/Argentina/Ushuaia', -10800, -10800),  # 817
    #REPEAT:    TZOffsetInfo.new('America/Bahia', -10800, -10800),  # 10800
    #REPEAT:    TZOffsetInfo.new('America/Belem', -10800, -10800),  # 16500
    #REPEAT:    TZOffsetInfo.new('America/Cayenne', -10800, -10800),  # 20500
    #REPEAT:    TZOffsetInfo.new('America/Fortaleza', -10800, -10800),  # 17900
    #REPEAT:    TZOffsetInfo.new('America/Maceio', -10800, -10800),  # 16400
    #REPEAT:    TZOffsetInfo.new('America/Paramaribo', -10800, -10800),  # 20100
    #REPEAT:    TZOffsetInfo.new('America/Recife', -10800, -10800),  # 14900
    #REPEAT:    TZOffsetInfo.new('Antarctica/Rothera', -10800, -10800),  # 12300
    TZOffsetInfo.new('America/Sao_Paulo', -10800, -7200),  # 20600
    TZOffsetInfo.new('America/St_Johns', -9000, -12600),  # 19400
    TZOffsetInfo.new('America/Godthab', -7200, -10800),  # 27200
    #REPEAT:    TZOffsetInfo.new('America/Miquelon', -7200, -10800),  # 20100
    TZOffsetInfo.new('America/Noronha', -7200, -7200),  # 21800
    #REPEAT:    TZOffsetInfo.new('Atlantic/South_Georgia', -7200, -7200),  # 17200
    TZOffsetInfo.new('Atlantic/Cape_Verde', -3600, -3600),  # 17500
    TZOffsetInfo.new('Atlantic/Azores', 0, -3600),  # 24100
    #REPEAT:    TZOffsetInfo.new('America/Scoresbysund', 0, -3600),  # 20300
    TZOffsetInfo.new('Africa/Bamako', 0, 0),  # 26700
    #REPEAT:    TZOffsetInfo.new('Africa/Abidjan', 0, 0),  # 23400
    #REPEAT:    TZOffsetInfo.new('Africa/Accra', 0, 0),  # 22800
    #REPEAT:    TZOffsetInfo.new('Africa/Banjul', 0, 0),  # 21200
    #REPEAT:    TZOffsetInfo.new('Africa/Bissau', 0, 0),  # 20800
    #REPEAT:    TZOffsetInfo.new('Africa/Casablanca', 0, 0),  # 22100
    #REPEAT:    TZOffsetInfo.new('Africa/Conakry', 0, 0),  # 20800
    #REPEAT:    TZOffsetInfo.new('Africa/Dakar', 0, 0),  # 23100
    #REPEAT:    TZOffsetInfo.new('Africa/El_Aaiun', 0, 0),  # 14900
    #REPEAT:    TZOffsetInfo.new('Africa/Freetown', 0, 0),  # 20800
    #REPEAT:    TZOffsetInfo.new('Africa/Lome', 0, 0),  # 21100
    #REPEAT:    TZOffsetInfo.new('Africa/Monrovia', 0, 0),  # 20800
    #REPEAT:    TZOffsetInfo.new('Africa/Nouakchott', 0, 0),  # 20600
    #REPEAT:    TZOffsetInfo.new('Africa/Ouagadougou', 0, 0),  # 21200
    #REPEAT:    TZOffsetInfo.new('Africa/Sao_Tome', 0, 0),  # 18100
    #REPEAT:    TZOffsetInfo.new('America/Danmarkshavn', 0, 0),  # 14200
    #REPEAT:    TZOffsetInfo.new('Atlantic/Reykjavik', 0, 0),  # 20100
    #REPEAT:    TZOffsetInfo.new('Atlantic/St_Helena', 0, 0),  # 17100
    TZOffsetInfo.new('Europe/London', 3600, 0),  # 76800
    #REPEAT:    TZOffsetInfo.new('Atlantic/Canary', 3600, 0),  # 20900
    #REPEAT:    TZOffsetInfo.new('Atlantic/Faeroe', 3600, 0),  # 19600
    #REPEAT:    TZOffsetInfo.new('Atlantic/Madeira', 3600, 0),  # 18900
    #REPEAT:    TZOffsetInfo.new('Europe/Dublin', 3600, 0),  # 21700
    #REPEAT:    TZOffsetInfo.new('Europe/Lisbon', 3600, 0),  # 29400
    TZOffsetInfo.new('Africa/Algiers', 3600, 3600),  # 22100
    #REPEAT:    TZOffsetInfo.new('Africa/Bangui', 3600, 3600),  # 21000
    #REPEAT:    TZOffsetInfo.new('Africa/Brazzaville', 3600, 3600),  # 20800
    #REPEAT:    TZOffsetInfo.new('Africa/Douala', 3600, 3600),  # 20700
    #REPEAT:    TZOffsetInfo.new('Africa/Kinshasa', 3600, 3600),  # 21700
    #REPEAT:    TZOffsetInfo.new('Africa/Lagos', 3600, 3600),  # 21400
    #REPEAT:    TZOffsetInfo.new('Africa/Libreville', 3600, 3600),  # 20800
    #REPEAT:    TZOffsetInfo.new('Africa/Luanda', 3600, 3600),  # 20800
    #REPEAT:    TZOffsetInfo.new('Africa/Malabo', 3600, 3600),  # 20600
    #REPEAT:    TZOffsetInfo.new('Africa/Ndjamena', 3600, 3600),  # 20500
    #REPEAT:    TZOffsetInfo.new('Africa/Niamey', 3600, 3600),  # 20600
    #REPEAT:    TZOffsetInfo.new('Africa/Porto-Novo', 3600, 3600),  # 20000
    TZOffsetInfo.new('Africa/Windhoek', 3600, 7200),  # 21400
    TZOffsetInfo.new('Europe/Amsterdam', 7200, 3600),  # 32800
    #REPEAT:    TZOffsetInfo.new('Africa/Ceuta', 7200, 3600),  # 17400
    #REPEAT:    TZOffsetInfo.new('Africa/Tunis', 7200, 3600),  # 21500
    #REPEAT:    TZOffsetInfo.new('Arctic/Longyearbyen', 7200, 3600),  # 16000
    #REPEAT:    TZOffsetInfo.new('Atlantic/Jan_Mayen', 7200, 3600),  # 17300
    #REPEAT:    TZOffsetInfo.new('Europe/Andorra', 7200, 3600),  # 22000
    #REPEAT:    TZOffsetInfo.new('Europe/Belgrade', 7200, 3600),  # 20200
    #REPEAT:    TZOffsetInfo.new('Europe/Berlin', 7200, 3600),  # 30500
    #REPEAT:    TZOffsetInfo.new('Europe/Bratislava', 7200, 3600),  # 18800
    #REPEAT:    TZOffsetInfo.new('Europe/Brussels', 7200, 3600),  # 28900
    #REPEAT:    TZOffsetInfo.new('Europe/Budapest', 7200, 3600),  # 23500
    #REPEAT:    TZOffsetInfo.new('Europe/Copenhagen', 7200, 3600),  # 26000
    #REPEAT:    TZOffsetInfo.new('Europe/Gibraltar', 7200, 3600),  # 22000
    #REPEAT:    TZOffsetInfo.new('Europe/Ljubljana', 7200, 3600),  # 18200
    #REPEAT:    TZOffsetInfo.new('Europe/Luxembourg', 7200, 3600),  # 24900
    #REPEAT:    TZOffsetInfo.new('Europe/Madrid', 7200, 3600),  # 30700
    #REPEAT:    TZOffsetInfo.new('Europe/Malta', 7200, 3600),  # 21800
    #REPEAT:    TZOffsetInfo.new('Europe/Monaco', 7200, 3600),  # 21500
    #REPEAT:    TZOffsetInfo.new('Europe/Oslo', 7200, 3600),  # 21000
    #REPEAT:    TZOffsetInfo.new('Europe/Paris', 7200, 3600),  # 47900
    #REPEAT:    TZOffsetInfo.new('Europe/Prague', 7200, 3600),  # 24000
    #REPEAT:    TZOffsetInfo.new('Europe/Rome', 7200, 3600),  # 25900
    #REPEAT:    TZOffsetInfo.new('Europe/San_Marino', 7200, 3600),  # 16000
    #REPEAT:    TZOffsetInfo.new('Europe/Sarajevo', 7200, 3600),  # 17900
    #REPEAT:    TZOffsetInfo.new('Europe/Skopje', 7200, 3600),  # 17600
    #REPEAT:    TZOffsetInfo.new('Europe/Stockholm', 7200, 3600),  # 21900
    #REPEAT:    TZOffsetInfo.new('Europe/Tirane', 7200, 3600),  # 19400
    #REPEAT:    TZOffsetInfo.new('Europe/Vaduz', 7200, 3600),  # 19200
    #REPEAT:    TZOffsetInfo.new('Europe/Vatican', 7200, 3600),  # 17700
    #REPEAT:    TZOffsetInfo.new('Europe/Vienna', 7200, 3600),  # 24600
    #REPEAT:    TZOffsetInfo.new('Europe/Warsaw', 7200, 3600),  # 23200
    #REPEAT:    TZOffsetInfo.new('Europe/Zagreb', 7200, 3600),  # 17900
    #REPEAT:    TZOffsetInfo.new('Europe/Zurich', 7200, 3600),  # 22000
    TZOffsetInfo.new('Africa/Johannesburg', 7200, 7200),  # 64300
    #REPEAT:    TZOffsetInfo.new('Africa/Blantyre', 7200, 7200),  # 20900
    #REPEAT:    TZOffsetInfo.new('Africa/Bujumbura', 7200, 7200),  # 20900
    #REPEAT:    TZOffsetInfo.new('Africa/Gaborone', 7200, 7200),  # 21100
    #REPEAT:    TZOffsetInfo.new('Africa/Harare', 7200, 7200),  # 24600
    #REPEAT:    TZOffsetInfo.new('Africa/Kigali', 7200, 7200),  # 20600
    #REPEAT:    TZOffsetInfo.new('Africa/Lubumbashi', 7200, 7200),  # 18000
    #REPEAT:    TZOffsetInfo.new('Africa/Lusaka', 7200, 7200),  # 21100
    #REPEAT:    TZOffsetInfo.new('Africa/Maputo', 7200, 7200),  # 20900
    #REPEAT:    TZOffsetInfo.new('Africa/Maseru', 7200, 7200),  # 20800
    #REPEAT:    TZOffsetInfo.new('Africa/Mbabane', 7200, 7200),  # 20600
    #REPEAT:    TZOffsetInfo.new('Africa/Tripoli', 7200, 7200),  # 21200
    TZOffsetInfo.new('Asia/Beirut', 10800, 7200),  # 37200
    #REPEAT:    TZOffsetInfo.new('Africa/Cairo', 10800, 7200),  # 23300
    #REPEAT:    TZOffsetInfo.new('Asia/Amman', 10800, 7200),  # 20300
    #REPEAT:    TZOffsetInfo.new('Asia/Damascus', 10800, 7200),  # 19900
    #REPEAT:    TZOffsetInfo.new('Asia/Gaza', 10800, 7200),  # 18300
    #REPEAT:    TZOffsetInfo.new('Asia/Jerusalem', 10800, 7200),  # 19400
    #REPEAT:    TZOffsetInfo.new('Asia/Nicosia', 10800, 7200),  # 20100
    #REPEAT:    TZOffsetInfo.new('Europe/Athens', 10800, 7200),  # 24100
    #REPEAT:    TZOffsetInfo.new('Europe/Bucharest', 10800, 7200),  # 22100
    #REPEAT:    TZOffsetInfo.new('Europe/Chisinau', 10800, 7200),  # 19500
    #REPEAT:    TZOffsetInfo.new('Europe/Helsinki', 10800, 7200),  # 22500
    #REPEAT:    TZOffsetInfo.new('Europe/Istanbul', 10800, 7200),  # 21800
    #REPEAT:    TZOffsetInfo.new('Europe/Kaliningrad', 10800, 7200),  # 17600
    #REPEAT:    TZOffsetInfo.new('Europe/Kiev', 10800, 7200),  # 20700
    #REPEAT:    TZOffsetInfo.new('Europe/Mariehamn', 10800, 7200),  # 758
    #REPEAT:    TZOffsetInfo.new('Europe/Minsk', 10800, 7200),  # 20300
    #REPEAT:    TZOffsetInfo.new('Europe/Riga', 10800, 7200),  # 20100
    #REPEAT:    TZOffsetInfo.new('Europe/Simferopol', 10800, 7200),  # 19700
    #REPEAT:    TZOffsetInfo.new('Europe/Sofia', 10800, 7200),  # 20400
    #REPEAT:    TZOffsetInfo.new('Europe/Tallinn', 10800, 7200),  # 19900
    #REPEAT:    TZOffsetInfo.new('Europe/Uzhgorod', 10800, 7200),  # 15000
    #REPEAT:    TZOffsetInfo.new('Europe/Vilnius', 10800, 7200),  # 19900
    #REPEAT:    TZOffsetInfo.new('Europe/Zaporozhye', 10800, 7200),  # 15000
    TZOffsetInfo.new('Africa/Nairobi', 10800, 10800),  # 27100
    #REPEAT:    TZOffsetInfo.new('Africa/Addis_Ababa', 10800, 10800),  # 18900
    #REPEAT:    TZOffsetInfo.new('Africa/Asmera', 10800, 10800),  # 21000
    #REPEAT:    TZOffsetInfo.new('Africa/Dar_es_Salaam', 10800, 10800),  # 18300
    #REPEAT:    TZOffsetInfo.new('Africa/Djibouti', 10800, 10800),  # 24100
    #REPEAT:    TZOffsetInfo.new('Africa/Kampala', 10800, 10800),  # 22000
    #REPEAT:    TZOffsetInfo.new('Africa/Khartoum', 10800, 10800),  # 21300
    #REPEAT:    TZOffsetInfo.new('Africa/Mogadishu', 10800, 10800),  # 20800
    #REPEAT:    TZOffsetInfo.new('Antarctica/Syowa', 10800, 10800),  # 15700
    #REPEAT:    TZOffsetInfo.new('Asia/Aden', 10800, 10800),  # 20800
    #REPEAT:    TZOffsetInfo.new('Asia/Bahrain', 10800, 10800),  # 21200
    #REPEAT:    TZOffsetInfo.new('Asia/Kuwait', 10800, 10800),  # 20500
    #REPEAT:    TZOffsetInfo.new('Asia/Qatar', 10800, 10800),  # 20300
    #REPEAT:    TZOffsetInfo.new('Asia/Riyadh', 10800, 10800),  # 20400
    #REPEAT:    TZOffsetInfo.new('Indian/Antananarivo', 10800, 10800),  # 19800
    #REPEAT:    TZOffsetInfo.new('Indian/Comoro', 10800, 10800),  # 19100
    #REPEAT:    TZOffsetInfo.new('Indian/Mayotte', 10800, 10800),  # 19200
    TZOffsetInfo.new('Europe/Moscow', 14400, 10800),  # 26400
    #REPEAT:    TZOffsetInfo.new('Asia/Baghdad', 14400, 10800),  # 20500
    #REPEAT:    TZOffsetInfo.new('Asia/Tbilisi', 14400, 10800),  # 19900
    TZOffsetInfo.new('Asia/Dubai', 14400, 14400),  # 22400
    #REPEAT:    TZOffsetInfo.new('Asia/Muscat', 14400, 14400),  # 20000
    #REPEAT:    TZOffsetInfo.new('Indian/Mahe', 14400, 14400),  # 19100
    #REPEAT:    TZOffsetInfo.new('Indian/Mauritius', 14400, 14400),  # 19200
    #REPEAT:    TZOffsetInfo.new('Indian/Reunion', 14400, 14400),  # 19300
    TZOffsetInfo.new('Asia/Tehran', 16200, 12600),  # 20800
    TZOffsetInfo.new('Asia/Kabul', 16200, 16200),  # 16100
    TZOffsetInfo.new('Asia/Yerevan', 18000, 14400),  # 25100
    #REPEAT:    TZOffsetInfo.new('Asia/Baku', 18000, 14400),  # 17000
    #REPEAT:    TZOffsetInfo.new('Europe/Samara', 18000, 14400),  # 19700
    TZOffsetInfo.new('Asia/Tashkent', 18000, 18000),  # 45100
    #REPEAT:    TZOffsetInfo.new('Asia/Aqtau', 18000, 18000),  # 23500
    #REPEAT:    TZOffsetInfo.new('Asia/Aqtobe', 18000, 18000),  # 18000
    #REPEAT:    TZOffsetInfo.new('Asia/Ashgabat', 18000, 18000),  # 18300
    #REPEAT:    TZOffsetInfo.new('Asia/Dushanbe', 18000, 18000),  # 19700
    #REPEAT:    TZOffsetInfo.new('Asia/Karachi', 18000, 18000),  # 21800
    #REPEAT:    TZOffsetInfo.new('Asia/Oral', 18000, 18000),  # 15700
    #REPEAT:    TZOffsetInfo.new('Asia/Samarkand', 18000, 18000),  # 15600
    #REPEAT:    TZOffsetInfo.new('Indian/Kerguelen', 18000, 18000),  # 21600
    #REPEAT:    TZOffsetInfo.new('Indian/Maldives', 18000, 18000),  # 19200
    TZOffsetInfo.new('Asia/Calcutta', 19800, 19800),  # 22000
    TZOffsetInfo.new('Asia/Katmandu', 20700, 20700),  # 20000
    TZOffsetInfo.new('Asia/Yekaterinburg', 21600, 18000),  # 22900
    #REPEAT:    TZOffsetInfo.new('Asia/Bishkek', 21600, 18000),  # 20100
    TZOffsetInfo.new('Asia/Colombo', 21600, 21600),  # 20600
    #REPEAT:    TZOffsetInfo.new('Antarctica/Mawson', 21600, 21600),  # 19000
    #REPEAT:    TZOffsetInfo.new('Antarctica/Vostok', 21600, 21600),  # 14600
    #REPEAT:    TZOffsetInfo.new('Asia/Almaty', 21600, 21600),  # 19100
    #REPEAT:    TZOffsetInfo.new('Asia/Dhaka', 21600, 21600),  # 16900
    #REPEAT:    TZOffsetInfo.new('Asia/Qyzylorda', 21600, 21600),  # 13300
    #REPEAT:    TZOffsetInfo.new('Asia/Thimphu', 21600, 21600),  # 15400
    #REPEAT:    TZOffsetInfo.new('Indian/Chagos', 21600, 21600),  # 19700
    TZOffsetInfo.new('Asia/Rangoon', 23400, 23400),  # 20200
    #REPEAT:    TZOffsetInfo.new('Indian/Cocos', 23400, 23400),  # 19200
    TZOffsetInfo.new('Asia/Novosibirsk', 25200, 21600),  # 20800
    #REPEAT:    TZOffsetInfo.new('Asia/Omsk', 25200, 21600),  # 18400
    TZOffsetInfo.new('Asia/Bangkok', 25200, 25200),  # 38500
    #REPEAT:    TZOffsetInfo.new('Antarctica/Davis', 25200, 25200),  # 16000
    #REPEAT:    TZOffsetInfo.new('Asia/Jakarta', 25200, 25200),  # 24900
    #REPEAT:    TZOffsetInfo.new('Asia/Phnom_Penh', 25200, 25200),  # 17200
    #REPEAT:    TZOffsetInfo.new('Asia/Pontianak', 25200, 25200),  # 14000
    #REPEAT:    TZOffsetInfo.new('Asia/Saigon', 25200, 25200),  # 20100
    #REPEAT:    TZOffsetInfo.new('Asia/Vientiane', 25200, 25200),  # 19600
    #REPEAT:    TZOffsetInfo.new('Indian/Christmas', 25200, 25200),  # 19500
    TZOffsetInfo.new('Asia/Krasnoyarsk', 28800, 25200),  # 18100
    #REPEAT:    TZOffsetInfo.new('Asia/Hovd', 28800, 25200),  # 15500
    TZOffsetInfo.new('Australia/Perth', 28800, 28800),  # 81400
    #REPEAT:    TZOffsetInfo.new('Antarctica/Casey', 28800, 28800),  # 28500
    #REPEAT:    TZOffsetInfo.new('Asia/Brunei', 28800, 28800),  # 23300
    #REPEAT:    TZOffsetInfo.new('Asia/Chongqing', 28800, 28800),  # 13500
    #REPEAT:    TZOffsetInfo.new('Asia/Harbin', 28800, 28800),  # 15700
    #REPEAT:    TZOffsetInfo.new('Asia/Hong_Kong', 28800, 28800),  # 19200
    #REPEAT:    TZOffsetInfo.new('Asia/Kashgar', 28800, 28800),  # 16200
    #REPEAT:    TZOffsetInfo.new('Asia/Kuala_Lumpur', 28800, 28800),  # 25300
    #REPEAT:    TZOffsetInfo.new('Asia/Kuching', 28800, 28800),  # 15500
    #REPEAT:    TZOffsetInfo.new('Asia/Macau', 28800, 28800),  # 13200
    #REPEAT:    TZOffsetInfo.new('Asia/Makassar', 28800, 28800),  # 13000
    #REPEAT:    TZOffsetInfo.new('Asia/Manila', 28800, 28800),  # 22400
    #REPEAT:    TZOffsetInfo.new('Asia/Shanghai', 28800, 28800),  # 31300
    #REPEAT:    TZOffsetInfo.new('Asia/Singapore', 28800, 28800),  # 45300
    #REPEAT:    TZOffsetInfo.new('Asia/Taipei', 28800, 28800),  # 23900
    #REPEAT:    TZOffsetInfo.new('Asia/Urumqi', 28800, 28800),  # 15600
    TZOffsetInfo.new('Asia/Irkutsk', 32400, 28800),  # 21000
    #REPEAT:    TZOffsetInfo.new('Asia/Ulaanbaatar', 32400, 28800),  # 17200
    TZOffsetInfo.new('Asia/Tokyo', 32400, 32400),  # 29100
    #REPEAT:    TZOffsetInfo.new('Asia/Dili', 32400, 32400),  # 14800
    #REPEAT:    TZOffsetInfo.new('Asia/Jayapura', 32400, 32400),  # 20500
    #REPEAT:    TZOffsetInfo.new('Asia/Pyongyang', 32400, 32400),  # 19800
    #REPEAT:    TZOffsetInfo.new('Asia/Seoul', 32400, 32400),  # 22900
    #REPEAT:    TZOffsetInfo.new('Pacific/Palau', 32400, 32400),  # 19600
    TZOffsetInfo.new('Australia/Darwin', 34200, 34200),  # 25600
    TZOffsetInfo.new('Australia/Adelaide', 34200, 37800),  # 71200
    #REPEAT:    TZOffsetInfo.new('Australia/Broken_Hill', 34200, 37800),  # 18000
    TZOffsetInfo.new('Asia/Yakutsk', 36000, 32400),  # 21000
    #REPEAT:    TZOffsetInfo.new('Asia/Choibalsan', 36000, 32400),  # 14000
    TZOffsetInfo.new('Australia/Brisbane', 36000, 36000),  # 51300
    #REPEAT:    TZOffsetInfo.new('Antarctica/DumontDUrville', 36000, 36000),  # 17800
    #REPEAT:    TZOffsetInfo.new('Australia/Lindeman', 36000, 36000),  # 15600
    #REPEAT:    TZOffsetInfo.new('Pacific/Guam', 36000, 36000),  # 21700
    #REPEAT:    TZOffsetInfo.new('Pacific/Port_Moresby', 36000, 36000),  # 16700
    #REPEAT:    TZOffsetInfo.new('Pacific/Saipan', 36000, 36000),  # 19100
    #REPEAT:    TZOffsetInfo.new('Pacific/Truk', 36000, 36000),  # 19500
    TZOffsetInfo.new('Australia/Sydney', 36000, 39600),  # 81600
    #REPEAT:    TZOffsetInfo.new('Australia/Currie', 36000, 39600),  # 599
    #REPEAT:    TZOffsetInfo.new('Australia/Hobart', 36000, 39600),  # 24300
    #REPEAT:    TZOffsetInfo.new('Australia/Melbourne', 36000, 39600),  # 59100
    TZOffsetInfo.new('Australia/Lord_Howe', 37800, 39600),  # 17900
    TZOffsetInfo.new('Asia/Vladivostok', 39600, 36000),  # 20800
    #REPEAT:    TZOffsetInfo.new('Asia/Sakhalin', 39600, 36000),  # 13900
    TZOffsetInfo.new('Pacific/Guadalcanal', 39600, 39600),  # 20200
    #REPEAT:    TZOffsetInfo.new('Pacific/Efate', 39600, 39600),  # 19100
    #REPEAT:    TZOffsetInfo.new('Pacific/Kosrae', 39600, 39600),  # 19300
    #REPEAT:    TZOffsetInfo.new('Pacific/Noumea', 39600, 39600),  # 19600
    #REPEAT:    TZOffsetInfo.new('Pacific/Ponape', 39600, 39600),  # 19500
    TZOffsetInfo.new('Pacific/Norfolk', 41400, 41400),  # 19500
    TZOffsetInfo.new('Asia/Magadan', 43200, 39600),  # 20600
    TZOffsetInfo.new('Pacific/Fiji', 43200, 43200),  # 25800
    #REPEAT:    TZOffsetInfo.new('Pacific/Funafuti', 43200, 43200),  # 19100
    #REPEAT:    TZOffsetInfo.new('Pacific/Kwajalein', 43200, 43200),  # 18800
    #REPEAT:    TZOffsetInfo.new('Pacific/Majuro', 43200, 43200),  # 19300
    #REPEAT:    TZOffsetInfo.new('Pacific/Nauru', 43200, 43200),  # 19300
    #REPEAT:    TZOffsetInfo.new('Pacific/Tarawa', 43200, 43200),  # 21000
    #REPEAT:    TZOffsetInfo.new('Pacific/Wake', 43200, 43200),  # 19600
    #REPEAT:    TZOffsetInfo.new('Pacific/Wallis', 43200, 43200),  # 19300
    TZOffsetInfo.new('Pacific/Auckland', 43200, 46800),  # 30600
    #REPEAT:    TZOffsetInfo.new('Antarctica/McMurdo', 43200, 46800),  # 19300
    #REPEAT:    TZOffsetInfo.new('Antarctica/South_Pole', 43200, 46800),  # 15400
    TZOffsetInfo.new('Pacific/Chatham', 45900, 49500),  # 20300
    TZOffsetInfo.new('Asia/Kamchatka', 46800, 43200),  # 20800
    #REPEAT:    TZOffsetInfo.new('Asia/Anadyr', 46800, 43200),  # 20300
    TZOffsetInfo.new('Pacific/Enderbury', 46800, 46800),  # 19800
    #REPEAT:    TZOffsetInfo.new('Pacific/Tongatapu', 46800, 46800),  # 19300
    TZOffsetInfo.new('Pacific/Kiritimati', 50400, 50400)  # 19400
  ]
  
end







