module MainHelper
  

  
  @@email_error="This is not a valid email address"
  def self.validate_email(email)
    email=email.strip
    
    # inside of the email shouldn't contain whitespace
    if !email.scan(/\s/).empty?
      return @@email_error
    end
    
    # should contain one ampersand
    if email.scan(/@/).size != 1
#       return "This doesn't look like a valid email address"
      return @@email_error+"adf"
    end
    
    # Make sure it's the correct form, e.g. at least satisfies a@b.c
    if email.match(/^.+@.+\..+$/).nil?
      return @@email_error
    end
    return nil
  end
  
  def self.validate_password(password)
    if !password.scan(/\s/).empty?
      return "Passwords can't have spaces."
    end
    if password.length<5
      return "Passwords should be at least 5 characters long"
    end
  end
  
end
