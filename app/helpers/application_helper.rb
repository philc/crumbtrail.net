# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def show_form_error(message)
    return nil if (message.nil?)
    return '<div class="form-error-message">'+message+'</div>'
  end


  #
  # Generates our custom form HTML for each field;
  # also shows validation if necessary
  #
  def field(type,*args)
    opts=args[0]

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

    errors = (defined? @errors) ? @errors : {}
    puts "errors in helper:",errors
    # see if we have a validation error message attached to this field.

    error = errors[opts[:show_error_for].to_s] || errors[opts[:name].to_s]
    error = nil if opts[:show_error]==false

    if (type=="textarea")
      type_string = ""
      tag="textarea"
    else
      tag="input"
      type_string = "type='#{type}'"
    end

    # tag = (type == "textarea") ? "textarea" : "input"

    error_class=""
    error_class="form-error" unless error.nil? || error.empty?

    input = %Q{<#{tag} #{type_string} class="field #{error_class}" #{att.join(' ')}></#{tag}>}    

    if error
      input += "<div class='form-error-message'>#{error}</div>"
    end

    return "<div class='field-wrap left'>#{input}</div>"      

  end
end
