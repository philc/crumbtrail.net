module ProjectHelper
  def panel_style(panel)
    @preferences.panel == panel ? nil : "style='display:none'"
  end
  def menu_selected(id)
    puts id,@preferences.panel
    @preferences.panel == id ? "class='active'" : nil
  end
end
