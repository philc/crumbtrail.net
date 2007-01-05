require 'digest/sha1'


# This is a user's logged in session. Basically keeping track of a 
# login token that they have stored in a cookie
class Session < ActiveRecord::Base
  belongs_to :account
  
  def self.expiration_time
    return 30.days.from_now
  end
  
  def self.from_token(token)
    return nil if token.nil?
    s=Session.find_by_token(token)
    puts "found session token" if s
    return nil if s.nil?
    
    # If somehow they've come back with a really old token, and it's expired,
    # delete it and make them log in again
    if (s.expires < Time.now)
      s.destroy
      return nil
    elsif s.expires< (self.expiration_time-1.day)         
    # If the last time we've accessed this thing is 24 hours ago,
    # then update its time stamp. Saves us a few writes to the db    
      s.expires=self.expiration_time
      s.save!
    end
    return s
  end
  
  def self.create_for(account)
    # generate some random text, digest it
    text = Time.now.to_s+rand(500000).to_s
    s=Session.new
    s.token = Digest::SHA1.hexdigest(text)
    s.account=account
    s.expires = expiration_time
    s.save!
    return s
  end
  
end
