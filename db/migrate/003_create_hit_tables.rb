class CreateHitTables < ActiveRecord::Migration
  def self.up
    create_table :hit_hourlies do |t|
      t.column :project_id, :integer, :null => false
      t.column :hour, :integer, :null => false
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :last_update, :datetime, :null => false
    end

    add_index :hit_hourlies, :project_id

    create_table :hit_dailies do |t|
      t.column :project_id, :integer, :null => false
      t.column :date, :date
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :row, :integer, :default => 0
    end

    add_index :hit_dailies, :project_id

    create_table :hit_monthlies do |t|
      t.column :project_id, :integer, :null => false
      t.column :month, :integer, :null => false
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :last_update, :date, :null => false
    end

    add_index :hit_monthlies, :project_id

    create_table :hit_totals do |t|
      t.column :project_id, :integer, :null => false
      t.column :total, :integer, :default => 0
      t.column :unique, :integer, :default => 0
      t.column :first_hit, :date, :null => false
    end

    add_index :hit_totals, :project_id
  end

  def self.down
    drop_table :hit_hourlys
    drop_table :hit_dailys
    drop_table :hit_monthlys
    drop_table :hit_totals
  end
end
