class CreateAccountTables < ActiveRecord::Migration
  def self.up
    # Create Account Table
    create_table :accounts do |t|
      t.column :username, :string, :null => false
      t.column :password, :string, :null => false
      t.column :firstname, :string, :null => false
      t.column :lastname, :string, :null => false
      t.column :country_id, :integer, :null => false
      t.column :zone_id, :integer, :limit => 45, :null => false
    end

    add_index :accounts, :username, :unique => true
    
    create_table :sessions do |t|
      t.column :token, :string, :null=>false
      t.column :account_id, :integer, :null=>false
      t.column :expires, :date, :null=>false
    end
    
    add_index :sessions, :token

    # Create Project Table
    create_table :projects do |t|
      t.column :account_id, :integer, :null => false
      t.column :title, :string, :null => false
      t.column :url, :string, :null => false
      t.column :zone_id, :integer, :null => false
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
    end

    # Create Row Tracker Table
    create_table :row_trackers do |t|
      t.column :project_id, :integer, :null => false
      t.column :referrals_row, :integer, :default => 0
      t.column :hits_row, :integer, :default => 0
      t.column :landings_row, :integer, :default => 0
      t.column :searches_row, :integer, :default => 0
    end

    add_index :row_trackers, :project_id
  end

  def self.down
    drop_table :accounts
    drop_table :sessions
    drop_table :projects
    drop_table :countries
    drop_table :zones
    drop_table :row_trackers
  end
end