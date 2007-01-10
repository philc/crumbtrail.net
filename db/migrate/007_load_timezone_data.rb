class LoadTimezoneData < ActiveRecord::Migration
  def self.up
    
    MainHelper::SUPPORTED_TIMEZONES.each do |t|
      Zone.create(:identifier=>t,
                 :offset=>TZInfo::Timezone.get(t).current_period.utc_offset/60.0/60)  
    end
  end

  def self.down
    Zone.delete_all
  end
end
