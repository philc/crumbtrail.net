class CreateServers < ActiveRecord::Migration
  def self.up
    create_table :servers do |t|
      t.column :zone_id, :integer, :null => false
    end

  end

  def self.down
    drop_table :servers
  end
end
