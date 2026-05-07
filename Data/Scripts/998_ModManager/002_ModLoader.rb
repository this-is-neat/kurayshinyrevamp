#==============================================================================
# Mod Manager — Loader
#
# The existing 999_Main.rb loads all .rb files in Mods/ root via:
#   Dir["./Mods/*.rb"].each {|file| load File.expand_path(file) }
#
# We do NOT touch that file. Instead, a bootstrap script
# (Mods/000_mod_manager_loader.rb) is picked up by that glob and calls
# ModManager.load_all_mods to handle subfolder-based mods.
#
# The bootstrap also sets a flag so legacy .rb files that load after it
# don't conflict (they load normally — no change needed).
#==============================================================================

# Global settings hash that mods can read at runtime:
#   $mod_manager_settings["my_mod"]["feature_x"]
$mod_manager_settings = {}

module ModManager
  #============================================================================
  # Main entry point — called from Mods/000_mod_manager_loader.rb
  #============================================================================
  def self.load_all_mods
    init unless initialized?

    loaded = 0
    errors = 0

    # Load managed mods (subfolders with mod.json) in topological order
    @@load_order.each do |mod_id|
      info = @@registry[mod_id]
      next unless info

      # Populate global settings for this mod
      $mod_manager_settings[mod_id] = load_mod_settings(mod_id)

      # Collect scripts: use mod.json "scripts" list if provided,
      # otherwise auto-detect all .rb files (including subfolders)
      if info.scripts && info.scripts.length > 0
        script_files = info.scripts.map { |s| File.join(info.folder_path, s) }
      else
        script_files = Dir[File.join(info.folder_path, "**", "*.rb")].sort
      end

      script_files.each do |script_path|
        next unless File.exist?(script_path)
        rel_name = script_path.sub(info.folder_path + "/", "")

        begin
          load File.expand_path(script_path)
        rescue => e
          echoln("[ModManager] Error in #{info.name}/#{rel_name}: #{e.message}")
          echoln("  #{e.backtrace[0..2].join("\n  ")}") if e.backtrace
          errors += 1
        end
      end

      # Install asset files (Graphics/, Audio/, etc.) if not already done
      manifest = File.join(info.folder_path, ".installed_assets")
      unless File.exist?(manifest)
        has_assets = ModManager::ASSET_DIRS.any? { |d| File.directory?(File.join(info.folder_path, d)) }
        ModManager.install_assets(mod_id) if has_assets
      end

      loaded += 1
    end

    summary = "[ModManager] Loaded #{loaded} mod(s)"
    summary += ", #{errors} error(s)" if errors > 0
    echoln(summary)
  end
end
