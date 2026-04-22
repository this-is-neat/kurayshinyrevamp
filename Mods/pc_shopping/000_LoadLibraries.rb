# Add the Libs folder to Ruby's load path
game_path = File.expand_path(File.join(File.expand_path(__FILE__), '..'))
libs_path = File.join(game_path, 'Libs')
$:.unshift(libs_path)

# Load required libraries
begin
  require 'json' # For parsing and transferring data
rescue LoadError
  # Keep game booting even if JSON isn't available in this runtime.
  echoln "[PCShopping] JSON library not available. JSON-backed shop lists will be disabled." if defined?(echoln)
end