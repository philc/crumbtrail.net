class CreateWaitlistUsers < ActiveRecord::Migration
  def self.up
    create_table :waitlist_users do |t|
      t.column :email, :string, :null=>false
      t.column :hearabout, :string
      t.column :created_on, :datetime, :null=>false
    end
  end

  def self.down
    drop_table :waitlist_users
  end
end
