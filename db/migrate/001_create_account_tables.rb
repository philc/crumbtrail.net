class CreateAccountTables < ActiveRecord::Migration
  def self.up
    # Create Account Table
    create_table :accounts do |t|
      t.column :username, :string, :null => false
      t.column :password, :string, :null => false
      t.column :firstname, :string, :null => false
      t.column :lastname, :string, :null => false
      t.column :country_id, :integer, :null => false
      t.column :access_key, :string
      t.column :zone_id, :integer, :limit => 45, :null => false
      t.column :last_access, :date, :null => false
      # account type:
        # d=demo
        # p1=paid level 1, p2 etc.
        # f=free        
      t.column :role, :string, :limit=>2, :default=>"f", :null=>false
      # recently viewed project
      t.column :recent_project_id, :int
    end

    add_index :accounts, :username, :unique => true

    create_table :sessions do |t|
      t.column :token, :string, :null=>false
      t.column :account_id, :integer, :null=>false
      t.column :expires, :timestamp, :null=>false
    end

    add_index :sessions, :token

    # Create Project Table
    create_table (:projects, :options => 'ENGINE=MyISAM') do |t|
      t.column :account_id, :integer, :null => false
      t.column :title, :string, :null => false
      t.column :url, :string, :null => false
      t.column :zone_id, :integer, :null => false
      t.column :referrals_row, :integer, :default => 0
      t.column :hits_row, :integer, :default => 0
      t.column :landings_row, :integer, :default => 0
      t.column :searches_row, :integer, :default => 0
      t.column :total_hits, :integer, :default => 0
      t.column :unique_hits, :integer, :default => 0
      t.column :direct_hits, :integer, :default => 0
      t.column :search_hits, :integer, :default => 0
      t.column :referer_hits, :integer, :default => 0
      t.column :first_hit, :date
      t.column :collapsing_refs, :text
    end

    add_index :projects, :account_id

    # Create Country Table
    # todo: load in country info
    create_table :countries do |t|
      t.column :name, :string, :null => false
    end

    # Create Timezone Table
    # todo: load in timezone identifiers
    create_table :zones do |t|
      t.column :identifier, :string, :null => false
      t.column :offset, :float, :null=>false
    end
    add_index :zones, :identifier
    
  end

  def self.down
    drop_table :accounts
    drop_table :sessions
    drop_table :projects
    drop_table :countries
    drop_table :zones
  end
end