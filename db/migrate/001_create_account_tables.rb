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

  end

  def self.down
    drop_table :accounts
    drop_table :projects
    drop_table :countries
    drop_table :zones
  end
end