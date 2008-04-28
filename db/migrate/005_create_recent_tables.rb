class CreateRecentTables < ActiveRecord::Migration
  def self.up
     # Create Recent Referral Table
    create_table (:referral_recents, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :first_url, :string, :null => false
      t.column :second_url, :string, :null => false 
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :referral_recents, [:project_id, :row]

    # Create Search Recent Table
    create_table (:search_recents, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :search_id, :integer, :null => false
      t.column :page_url, :string, :null => false
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :search_recents, [:project_id, :row]

    # Create Pagehit Recents Table
    create_table (:pagehit_recents, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :first_url, :string, :null => false 
      t.column :second_url, :string, :null => false
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :pagehit_recents, [:project_id, :row]
  end

  def self.down
    drop_table :referral_recents
    drop_table :search_recents
    drop_table :pagehit_recents
  end
end
