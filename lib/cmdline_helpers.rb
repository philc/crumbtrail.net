#
# Strips an option out of the command line args. So 
# strip_arg('-resume') would return -resume and remove it from ARGV.
# Passing in a regex will use that pattern to find the option and return
# the result of any grouping, e.g. strip_arg(/p=(\d+)/) would return the value of \d+
#
def strip_arg(pattern)
  if (pattern.class==Regexp)
    for a in ARGV
      m = a.match(pattern)
      return m[1] unless m.nil?
    end
    return nil
  else
    ARGV.delete(pattern)
  end
end

