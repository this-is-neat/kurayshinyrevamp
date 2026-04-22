#==============================================================================
# Mod Manager Bootstrap
#
# This file is picked up by the existing Dir["./Mods/*.rb"] glob in
# 999_Main.rb. The "000_" prefix ensures it runs before any other
# legacy .rb mods in this folder.
#
# It calls ModManager.load_all_mods which loads subfolder-based mods
# (Mods/<mod_name>/mod.json + scripts) in dependency order.
#
# Legacy .rb files in Mods/ root still load normally after this via
# the same glob — no changes to core files needed.
#==============================================================================

if defined?(ModManager) && ModManager.respond_to?(:load_all_mods)
  ModManager.load_all_mods
end