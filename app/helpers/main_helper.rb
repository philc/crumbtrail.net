module MainHelper
  

  
  @@email_error="This is not a valid email address"
  def self.validate_email(email)
    email=email.strip
    
    # inside of the email shouldn't contain whitespace
    if !email.scan(/\s/).empty?
      return @@email_error
    end
    
    # should contain one ampersand
    if email.scan(/@/).size != 1
#       return "This doesn't look like a valid email address"
      return @@email_error
    end
    
    # Make sure it's the correct form, e.g. at least satisfies a@b.c
    if email.match(/^.+@.+\..+$/).nil?
      return @@email_error
    end
    return nil
  end
  
  def self.validate_password(password)
    if !password.scan(/\s/).empty?
      return "Passwords can't contain spaces"
    end
    if password.length<5
      return "Passwords should be at least 5 characters long"
    end
  end
  require 'tzinfo'
  
  def self.tz_offset(off)
    # off=TZInfo::Timezone.get(zone).current_period.utc_offset/60.0/60
    time=off%1==0 ? ":00" : ":30"
    "(GMT" + (off<0 ? "-" : "+") +
    (off<10 && off >-10 ? "0" : "") + 
    off.abs.floor.to_s + time + ")"
  end
  
  SUPPORTED_TIMEZONES=
   [
     'Pacific/Midway',
     'Pacific/Tahiti',
     'America/Adak',
     'US/Alaska',
     'US/Pacific',
     'US/Arizona',
     'US/Mountain',
     'America/Guatemala',
     'US/Central',
     'America/Bogota',
     'US/Eastern',
     'America/Caracas',
     'America/Santiago',
     'Canada/Atlantic',
     'America/Montevideo',
     'America/Sao_Paulo',
     'America/St_Johns',
     'America/Godthab',
     'America/Noronha',
     'Atlantic/Cape_Verde',
     'Atlantic/Azores',
     'Africa/Casablanca',
     'Europe/London',
     'Africa/Algiers',
     'Europe/Amsterdam',
     'Africa/Harare',
     'Europe/Athens',
     'Africa/Nairobi',
     'Europe/Moscow',
     'Asia/Tehran',
     'Asia/Kabul',
     'Asia/Baku',
     'Asia/Karachi',
     'Asia/Calcutta',
     'Asia/Katmandu',
     'Asia/Yekaterinburg',
     'Asia/Colombo',
     'Asia/Rangoon',
     'Asia/Almaty',
     'Asia/Bangkok',
     'Asia/Krasnoyarsk',
     'Australia/Perth',
     'Asia/Irkutsk',
     'Asia/Tokyo',
     'Australia/Darwin',
     'Australia/Adelaide',
     'Asia/Yakutsk',
     'Australia/Brisbane',
     'Australia/Sydney',
     'Australia/Lord_Howe',
     'Asia/Vladivostok',
     'Asia/Magadan',
     'Pacific/Fiji',
     'Pacific/Auckland'
   ]
   
end
