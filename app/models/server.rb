class Server < ActiveRecord::Base
  belongs_to :zone

  def self.get_server()
    return find(1)
  end
end
