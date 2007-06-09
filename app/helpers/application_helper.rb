# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def show_form_error(message)
    return nil if (message.nil?)
    return '<div class="form_error">'+message+'</div>'
  end
  
  #
  # generates our custom form HTML for each field;
  # also shows validation if necessary
  #
  def field(type,*args)
    opts=args[0]
    
    att=[]
    # att<<"name='#{opts['name']}'" if opts[:name]
    # att<<"value='#{opts['value']}'"
    
    # if they provided an ID for the field, but not a name, then
    # make the name the same as the ID
    if (opts[:id] && !opts[:name])
      opts[:name] = opts[:id] 
    end
    
    att=[]
    # [:id,:name,:value].each do |a|  # uncomment to used to turn off js validation for debugging
    [:id,:name,:value,:validate, :required, :message].each do |a|
      att<< "#{a}=\"#{opts[a]}\"" if opts[a]
    end
    
    input_type=""
    tag=""
    if (type=="textarea")
      tag="textarea"
    else
      tag="input"
      input_type="type='#{type}'"
    end

    # see if we have a validation error message attached to this form
    error = @errors[opts[:show_error_for].to_s] || @errors[opts[:name].to_s]
    error = nil if opts[:show_error]==false
            
    tag = (type == "textarea") ? "textarea" : "input"
    input = %Q{<#{tag} class="field #{'form-error' if error}" #{input_type} #{att.join(' ')}></#{tag}>}    
    
    if error
      input += "<div class='form-error-message'>#{error}</div>"
    end
    
    return "<div class='field-wrap left'>#{input}</div>"      
      
  end
end
