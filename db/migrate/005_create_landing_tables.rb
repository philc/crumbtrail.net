class CreateLandingTables < ActiveRecord::Migration
  def self.up
    # Create Landing Totals Table
    create_table (:landing_totals, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :page_id, :integer, :default => 0
      t.column :referer_id, :integer, :default => 0
      t.column :count, :integer, :default => 0
    end

    add_index :landing_totals, :project_id

    # Create Landing Recents Table
    create_table (:landing_recents, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :page_id, :integer, :null => false 
      t.column :referer_id, :integer, :null => false
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :landing_recents, :project_id
  end

  def self.down
    drop_table :landing_totals
    drop_table :landing_recents
  end
end
