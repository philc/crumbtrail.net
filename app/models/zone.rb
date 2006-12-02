class Zone < ActiveRecord::Base
  has_many :servers
  has_many :projects
  has_many :accounts
end
