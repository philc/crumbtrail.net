module ProjectHelper
  def panel_style(panel)
    @view_options[:section] == panel ? nil : "style='display:none'"
  end
  def menu_selected(id)
    #puts id,@preferences.panel
    #@preferences.panel == id ? "class='active'" : nil
    @view_options[:section] == id ? "class='active'" : nil
  end
  def visible(n,v)
    return @view_options[n]==v
  end
  # Creates a link, which will be disabled if the account is a demo account
  def demo_link(href,title,onclick="")
    return (@account.demo?) ? title : "<a href=\"#{href}\" onclick=\"#{onclick}\">#{title}</a>"
    
  end
end
