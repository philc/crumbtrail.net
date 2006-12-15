require 'digest/sha1'

# This is a user's logged in session. Basically keeping track of a 
# login token that they have stored in a cookie
class Session < ActiveRecord::Base
  belongs_to :account
  
  def self.from_token(token)
    s=Session.find_by_token(token)
    
    # If somehow they've come back with a really old token, and it's expired,
    # delete it and make them log in again
    if (s.expires < DateTIme.now)
      s.destroy!
      return nil
    end
    return s
  end
  
  def self.create_for(account)
    # generate some random text, digest it
    text = DateTime.now.to_s+rand(500000).to_s
    s=Session.new
    s.token = Digest::SHA1.hexdigest(text)
    s.account=account
    s.expires = DateTime.now
    s.save!
    return s
  end
end
