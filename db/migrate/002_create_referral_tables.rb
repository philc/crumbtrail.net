class CreateReferralTables < ActiveRecord::Migration
  def self.up
    # Create Sources Table
    create_table (:sources, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :url_hash, :integer, :null => false
      t.column :url, :string, :null => false
      t.column :path_id, :integer
      t.column :count, :integer, :default => 0
      t.column :type, :string
 
      # Referer columns
      t.column :first_visit, :timestamp
      t.column :recent_visit, :date
      t.column :daily_hit_counts, :text
      t.column :seven_days_count, :integer, :default => 0
      t.column :today_count, :integer, :default => 0
    
      # Search columns
      t.column :search_words, :string
      t.column :search_words_hash, :integer
    end

    add_index :sources, [:project_id, :type, :url_hash]
    add_index :sources, [:project_id, :type, :search_words_hash]

  end

  def self.down
    drop_table :sources
  end
end
