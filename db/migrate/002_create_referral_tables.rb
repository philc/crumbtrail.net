class CreateReferralTables < ActiveRecord::Migration
  def self.up
    # Create Referer Table
    create_table :referers do |t|
      t.column :url_hash, :integer, :null => false
      t.column :url, :string, :null => false
    end

    add_index :referers, :url_hash

    # Create Pages Table
    create_table :pages do |t|
      t.column :url_hash, :integer, :null => false
      t.column :url, :string, :null => false
    end

    add_index :pages, :url_hash

    # Create Recent Referral Table
    create_table :referral_recents do |t|
      t.column :project_id, :integer, :null => false
      t.column :referer_id, :integer, :null => false
      t.column :page_id, :integer, :null => false 
      t.column :visit_time, :datetime, :null => false
      t.column :row, :integer, :null => false
    end

    add_index :referral_recents, :project_id

    # Create Total Table
    create_table :referral_totals do |t|
      t.column :project_id, :integer, :null => false
      t.column :referer_id, :integer, :null => false
      t.column :page_id, :integer, :null => false
      t.column :first_visit, :datetime, :null => false
      t.column :count, :integer, :default => 0
    end

    add_index :referral_totals, :project_id
# 
#     # Create Search Referer Table
#     create_table :search_referrals do |t|
#       t.column :project_id, :integer, :null => false
#       t.column :search_url, :string, :null => false
#       t.column :search_url_hash, :integer, :null => false
#       t.column :search_words, :string, :null => false
#       t.column :count, :integer, :default => 0
#       t.column :landing_url_id, :integer
#       t.column :first_visit, :datetime, :null => false
#       t.column :recent_visit, :datetime, :null => false
#     end
# 
#     add_index :search_referrals, :project_id
#     add_index :search_referrals, :search_url_hash
  end

  def self.down
    drop_table :referers
    drop_table :pages
#     drop_table :landing_urls
    drop_table :referral_recents
    drop_table :referral_totals
#     drop_table :search_referers
  end
end
