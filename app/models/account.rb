require 'digest/sha1'

class Account < ActiveRecord::Base
  has_many :projects  
  has_many :sessions
  belongs_to :country
  belongs_to :zone
 
  def before_create
    # secret value to append to the user's feeds, so the URLs are hidden
    self.access_key ||= Digest::SHA1.hexdigest(self.username + self.password + rand(500).to_s)
  end    
  
  def self.authenticate(username,password)
    account=self.find_by_username(username)
    return "No account registered with that e-mail" if account.nil?
    
    if account.password!=encrypt(password)
      return "Incorrect login"
    end
    
    account.last_access=Date.today
    account.save
    
    return account    
  end
  
  def recent_project
    rp=self.recent_project_id
    return nil if (rp.nil?)
    p=Project.find_by_id(rp)    
    
    # If this link is somehow bad, in the case of
    # the their deleting a project or something, 
    # then just use their first project
    p = self.projects[0] if (p.nil?)
      
    return p
  end
  
  def recent_project=(project)
    self.recent_project_id=project.id    
  end
  def self.from_token(token)
    return nil if token.nil?
    session=Session.from_token(token)
   
    
    return (session.nil?) ? nil : session.account
  end
  
  def password=(pass)
    write_attribute(:password,Account.encrypt(pass))
  end
  
  # Identity
  def self.demo_account()
    return find(:first, :conditions=>{:role =>"d"})
  end
  def demo?()
    return self.role=="d"
  end
  
  protected
  
  def self.encrypt(text)
    return Digest::SHA1.hexdigest(text)
  end
  
  
end
