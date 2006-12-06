class CreateDetails < ActiveRecord::Migration
  def self.up
    create_table :hit_details do |t|
      t.column :project_id, :integer, :null => false
      t.column :day, :integer, :null => false
      t.column :last_update, :date, :null => false

      t.column :b_firefox15, :integer, :default => 0
      t.column :b_firefox20, :integer, :default => 0
      t.column :b_ie5, :integer, :default => 0
      t.column :b_ie6, :integer, :default => 0
      t.column :b_ie7, :integer, :default => 0
      t.column :b_safari, :integer, :default => 0
      t.column :b_other, :integer, :default => 0

      t.column :os_vista, :integer, :default => 0
      t.column :os_w2k3, :integer, :default => 0
      t.column :os_xp, :integer, :default => 0
      t.column :os_w2k, :integer, :default => 0
      t.column :os_w98, :integer, :default => 0
      t.column :os_w95, :integer, :default => 0
      t.column :os_linux, :integer, :default => 0
      t.column :os_macosx, :integer, :default => 0
      t.column :os_other, :integer, :default => 0
    end

    add_index :hit_details, :project_id
  end

  def self.down
    drop_table :hit_details
  end
end
