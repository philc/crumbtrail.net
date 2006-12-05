class CreateReferralTables < ActiveRecord::Migration
  def self.up
    # Create Hourly Table
    create_table :hourly_referrals do |t|
      t.column :project_id, :integer, :null => false
      t.column :referer_id, :integer, :null => false
      t.column :hour, :integer, :null => false
      t.column :count, :integer, :null => false
      t.column :last_update, :datetime
    end

    add_index :hourly_referrals, :project_id
    add_index :hourly_referrals, :referer_id

    # Create Daily Table
    create_table :daily_referrals do |t|
      t.column :project_id, :integer, :null => false
      t.column :referer_id, :integer, :null => false
      t.column :day, :integer, :null => false
      t.column :count, :integer, :null => false
      t.column :last_update, :datetime
    end

    add_index :daily_referrals, :project_id

    # Create Total Table
    create_table :total_referrals do |t|
      t.column :project_id, :integer, :null => false
      t.column :referer_id, :integer, :null => false
      t.column :count, :integer, :default => 0
      t.column :first_visit, :datetime
      t.column :recent_visit, :datetime
      t.column :internal_url_id, :integer
    end

    add_index :total_referrals, :project_id

    # Create Referer Table
    create_table :referers do |t|
      t.column :url, :string, :null => false
    end

    add_index :referers, :url

    # Create Internal Url Table
    create_table :internal_urls do |t|
      t.column :url, :string, :null => false
    end

    add_index :internal_urls, :url
  end

  def self.down
    drop_table :hourly_referrals
    drop_table :daily_referrals
    drop_table :total_referrals
    drop_table :referers
    drop_table :internal_urls
  end
end
