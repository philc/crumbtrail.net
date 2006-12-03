class CreateViewPreferences < ActiveRecord::Migration
  attr_accessor:hits,:referers, :pages, :searches
  def self.up
    create_table :view_preferences do |t|
      t.column :id, :int, :null=>false
      t.column :project_id, :int, :null=>false
      t.column :hits, :string , :limit=>15, :null => false
      t.column :referers, :string , :limit=>15, :null => false
      t.column :pages, :string , :limit=>15, :null => false
      t.column :searches, :string , :limit=>15, :null => false
      t.column :panel, :string , :limit=>15, :null => false
      
    end
    
    add_index :view_preferences, :project_id
    
    # default testing data. remove.
    v=ViewPreference.new
    v.defaults()
    v.project_id=1050
    v.save!
    
  end

  def self.down
    drop_table :view_preferences
  end
end
