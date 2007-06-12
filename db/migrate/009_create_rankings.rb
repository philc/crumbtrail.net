class CreateRankings < ActiveRecord::Migration
  def self.up
    create_table :rankings do |t|
      t.column :project_id, :integer, :null => false
      t.column :query, :string, :null => false
      t.column :engine, :string, :limit => 1, :null => false
      t.column :rank, :integer, :null => false
      t.column :search_date, :date, :null => false
    end

    add_index :rankings, [:project_id, :query, :engine]

    add_column :projects, :queries, :string
  end

  def self.down
    drop_table :rankings
    remove_column :projects, :queries
  end
end
