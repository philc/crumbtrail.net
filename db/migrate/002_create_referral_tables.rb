class CreateReferralTables < ActiveRecord::Migration
  def self.up

    create_table (:pages, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :url_hash, :integer, :null => false
      t.column :url, :string, :null => false
      t.column :source_id, :integer, :default => 0
      t.column :source_type, :string, :limit => 1, :default => "d"
      t.column :count, :integer, :default => 0
    end

    add_index :pages, [:project_id, :url_hash]

    create_table (:referers, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :url_hash, :integer, :null => false
      t.column :url, :string, :null => false
      t.column :page_id, :integer, :null => false
      t.column :first_visit, :timestamp
      t.column :recent_visit, :date
      t.column :count, :integer, :default => 0
      t.column :daily_hit_counts, :text
      t.column :seven_days_count, :integer, :default => 0
      t.column :today_count, :integer, :default => 0
    end

    add_index :referers, [:project_id, :url_hash]
    add_index :referers, [:project_id, :recent_visit]
    add_index :referers, [:project_id, :count]

    create_table (:searches, :options => 'ENGINE=MyISAM') do |t|
      t.column :project_id, :integer, :null => false
      t.column :search_words_hash, :integer, :null => false
      t.column :search_words, :string, :null => false
      t.column :url_hash, :integer, :null => false
      t.column :url, :string, :null => false
      t.column :page_id, :integer
      t.column :count, :integer, :default => 0
    end

    add_index :searches, [:project_id, :search_words_hash]
    add_index :searches, [:project_id, :count]

  end

  def self.down
    drop_table :pages
    drop_table :referers
    drop_table :searches
  end
end
