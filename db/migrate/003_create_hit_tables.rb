class CreateHitTables < ActiveRecord::Migration
  def self.up
    create_table :hourly_hits do |t|
      t.column :project_id, :integer, :null => false
      t.column :hour, :integer, :null => false
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :last_update, :datetime, :null => false
    end

    add_index :hourly_hits, :project_id

    create_table :daily_hits do |t|
      t.column :project_id, :integer, :null => false
      t.column :date, :date
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :row, :integer, :default => 0
    end

    add_index :daily_hits, :project_id

    create_table :monthly_hits do |t|
      t.column :project_id, :integer, :null => false
      t.column :month, :integer, :null => false
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :last_update, :date, :null => false
    end

    add_index :monthly_hits, :project_id

    create_table :total_hits do |t|
      t.column :project_id, :integer, :null => false
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :first_hit, :date, :null => false
    end

    add_index :total_hits, :project_id
  end

  def self.down
    drop_table :hourly_hits
    drop_table :daily_hits
    drop_table :monthly_hits
    drop_table :total_hits
  end
end
