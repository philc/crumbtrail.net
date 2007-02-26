class CreateLandingTables < ActiveRecord::Migration
  def self.up
     # Create Recent Referral Table
    create_table (:referral_recents, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :referer_id, :integer, :null => false
      t.column :page_id, :integer, :null => false 
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :referral_recents, :project_id

    # Create Search Recent Table
    create_table (:search_recents, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :search_id, :integer, :null => false
      t.column :page_id, :integer, :null => false
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :search_recents, :project_id

    # Create Landing Recents Table
    create_table (:landing_recents, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :page_id, :integer, :null => false 
      t.column :source_id, :integer
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :landing_recents, :project_id
  end

  def self.down
    drop_table :referral_recents
    drop_table :search_recents
    drop_table :landing_recents
  end
end
