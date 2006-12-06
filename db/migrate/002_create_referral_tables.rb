class CreateReferralTables < ActiveRecord::Migration
  def self.up
    # Create Referer Table
    create_table :referers do |t|
      t.column :url, :string, :null => false
    end

    add_index :referers, :url

    # Create Internal Url Table
    create_table :landing_urls do |t|
      t.column :url, :string, :null => false
    end

    add_index :landing_urls, :url

    # Create Recent Referral Table
    create_table :recent_referrals do |t|
      t.column :project_id, :integer, :null => false
      t.column :referer_id, :integer, :null => false
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
      t.column :landing_url_id, :integer, :null => false
    end

    add_index :recent_referrals, :project_id

    # Create Total Table
    create_table :total_referrals do |t|
      t.column :project_id, :integer, :null => false
      t.column :referer_id, :integer, :null => false
      t.column :first_visit, :datetime
      t.column :count, :integer, :default => 0
      t.column :landing_url_id, :integer
    end

    add_index :total_referrals, :project_id

  end

  def self.down
    drop_table :referers
    drop_table :landing_urls
    drop_table :recent_referrals
    drop_table :total_referrals
  end
end
