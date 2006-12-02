class Account < ActiveRecord::Base
  has_many :projects
  belongs_to :country
  belongs_to :zone
end
