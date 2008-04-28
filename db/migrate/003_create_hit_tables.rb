class CreateHitTables < ActiveRecord::Migration
  def self.up
    create_table (:hit_hourlies, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :hour, :integer, :null => false
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :search, :integer, :default => 0
      t.column :direct, :integer, :default => 0
      t.column :referer, :integer, :default => 0
      t.column :last_update, :timestamp, :null => false
    end

    add_index :hit_hourlies, :project_id

    create_table (:hit_dailies, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :date, :date
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :row, :integer, :default => 0
    end

    add_index :hit_dailies, :project_id

    create_table (:hit_monthlies, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :month, :integer, :null => false
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :last_update, :date, :null => false
    end

    add_index :hit_monthlies, :project_id

  end

  def self.down
    drop_table :hit_hourlies
    drop_table :hit_dailies
    drop_table :hit_monthlies
  end
end
