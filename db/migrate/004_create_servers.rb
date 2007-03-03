class CreateServers < ActiveRecord::Migration
  def self.up
    create_table :servers do |t|
      t.column :zone_id, :integer, :null => false
      t.column :last_log_time, :time
    end
    
    
    server = Server.new(:zone_id => 11)
    server.id = 1
    server.save

  end

  def self.down
    drop_table :servers    
  end
end
