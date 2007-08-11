#
# Supports calling css_dryer from outside of a controller.
# Really should be in CSS_Dryer..

require File.dirname(__FILE__)+"/../../css_dryer/lib/css_dryer"

# require "css_dryer"

# -philc
# Add offline rendering
# -philc
class CssDryerRenderer
  include CssDryer
  include ERB::Util
  def render(css_text)
    env = Object.new
    bind = env.send :binding      

    env.extend(StylesheetsHelper)

    # strip out all comments, because ncss has trouble
    # with multi-line comments. Remove when they fix the bugs
    # that I posted on the blog
    css_text.gsub!(/\/\*(.|[\n])*?\*\//,"")

    # Evaluate with ERB
    dry_css = ERB.new(css_text).result(bind)

    # Flatten
    process(dry_css)
  end
end