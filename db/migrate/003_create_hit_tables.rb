class CreateHitTables < ActiveRecord::Migration
  def self.up
    create_table :recent_hits do |t|
      t.column :project_id, :integer, :null => false
      t.column :referer_id, :integer, :null => false
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :recent_hits, :project_id

    create_table :hit_row_trackers do |t|
      t.column :project_id, :integer, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :hit_row_trackers, :project_id

    create_table :daily_hits do |t|
      t.column :project_id, :integer, :null => false
      t.column :date, :date
      t.column :count, :integer, :null => false, :default => 0
    end

    add_index :daily_hits, :project_id

    create_table :total_hits do |t|
      t.column :project_id, :integer, :null => false
      t.column :count, :integer, :null => false, :default => 0
    end

    add_index :total_hits, :project_id
  end

  def self.down
    drop_table :recent_hits
    drop_table :hit_row_trackers
    drop_table :daily_hits
    drop_table :total_hits
  end
end
