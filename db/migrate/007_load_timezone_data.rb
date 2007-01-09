class LoadTimezoneData < ActiveRecord::Migration
  def self.up
    MainHelper::SUPPORTED_TIMEZONES.each do |t|
      Zone.create(:identifier=>t,
                 :offset=>TZInfo::Timezone.get(t).current_period.utc_offset/60.0/60)  
    end
  end
  # def self.tz_offset(zone)
  #   off=TZInfo::Timezone.get(zone).current_period.utc_offset/60.0/60
  #   time=off%1==0 ? ":00" : ":30"
  #   "(GMT" + (off<0 ? "-" : "+") +
  #   (off<10 && off >-10 ? "0" : "") + 
  #   off.abs.floor.to_s + time + ")"
  # end
  def self.down
    Zone.delete_all
  end
end
