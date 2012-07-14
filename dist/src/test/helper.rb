# you can define some helper methods

def fixture_path(f)
  File.expand_path(f, File.join(File.dirname(__FILE__), "fixtures"))
end
