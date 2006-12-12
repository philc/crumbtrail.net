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
end
