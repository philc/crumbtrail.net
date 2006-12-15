# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def show_form_error(message)
    return nil if (message.nil?)
    return '<div class="form_error">'+message+'</div>'
  end
  

end
