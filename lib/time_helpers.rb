module TimeHelpers
  require 'tzinfo'
  
  @@tz_server = nil
  
  def self.convert_to_client_time(project, time)
    init_server_time
    tz_client = TZInfo::Timezone.get(project.zone.identifier)
    newtime = tz_client.utc_to_local(@@tz_server.local_to_utc(time))
    return newtime
  end
  
  def self.init_server_time
    if @@tz_server.nil?
      server_zone = Server.get_server.zone.identifier
      @@tz_server = TZInfo::Timezone.get(server_zone)
    end
  end
end