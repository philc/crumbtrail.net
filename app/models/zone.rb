class Zone < ActiveRecord::Base
  has_many :servers
  has_many :projects
  has_many :accounts
  
  def self.all
    Zone.find(:all, :order=>"offset asc, identifier")
  end
  
end
