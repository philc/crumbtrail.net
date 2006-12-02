module ProjectHelper
  def panel_style(panel)
    @preferences.panel == panel ? nil : "style='display:none'"
  end
  def menu_selected(id)
    @preferences.panel == id ? "class='active'" : nil
  end
end
