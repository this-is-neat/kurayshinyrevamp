#==============================================================================
# Mod Manager — Universal Linux Patch                        [008_LinuxInputs.rb]
#
# Fixes:
# 1. Keyboard Input (typing & triggers) on Linux/Wine.
# 2. Mod Publisher/Deleter execution on Linux/Wine via Host Redirection.
#
# APPROACH:
#   - For Linux users running under Wine/Proton, launching internal scripts
#     is unreliable. This patch intercepts the launch and provides a
#     one-click command to copy into your native host terminal.
#==============================================================================

module ModManager
  #----------------------------------------------------------------------------
  # Keyboard Input Patch
  #----------------------------------------------------------------------------
  module LinuxInputPatch
    def _window_active?
      return true
    end

    def _init_gas
      @_gas ||= begin
        Win32API.new('user32', 'GetAsyncKeyState', ['i'], 'i')
      rescue
        nil
      end
    end

    def _key_trigger?(vk_code)
      @_linux_last_states ||= {}
      _init_gas
      return false unless @_gas
      current_state = (@_gas.call(vk_code) & 0x8000) != 0
      triggered = current_state && !@_linux_last_states[vk_code]
      @_linux_last_states[vk_code] = current_state
      return triggered
    end
  end

  #----------------------------------------------------------------------------
  # Mod Publisher / Console Patch
  #----------------------------------------------------------------------------
  module LinuxPublisherPatch
    def _is_linux_host?
      File.exist?("Z:/etc") || File.exist?("Z:/proc") || File.exist?("Z:/tmp")
    end

    def _to_host_path(wine_path)
      abs = File.expand_path(wine_path)
      abs.sub(/^[A-Za-z]:/, "").gsub("\\", "/")
    end

    def _copy_to_clipboard(text)
      open_cb  = Win32API.new('user32', 'OpenClipboard', ['l'], 'i')
      close_cb = Win32API.new('user32', 'CloseClipboard', [], 'i')
      empty_cb = Win32API.new('user32', 'EmptyClipboard', [], 'i')
      set_cb   = Win32API.new('user32', 'SetClipboardData', ['i', 'l'], 'l')
      g_alloc  = Win32API.new('kernel32', 'GlobalAlloc', ['i', 'i'], 'l')
      g_lock   = Win32API.new('kernel32', 'GlobalLock', ['l'], 'l')
      g_unlock = Win32API.new('kernel32', 'GlobalUnlock', ['l'], 'i')
      memcpy   = Win32API.new('kernel32', 'RtlMoveMemory', ['l', 'p', 'i'], 'v')

      cf_text = 1
      gmem_moveable = 0x0002

      return false unless open_cb.call(0) != 0
      empty_cb.call
      buf = text + "\0"
      hmem = g_alloc.call(gmem_moveable, buf.length)
      if hmem != 0
        ptr = g_lock.call(hmem)
        if ptr != 0
          memcpy.call(ptr, buf, buf.length)
          g_unlock.call(hmem)
          set_cb.call(cf_text, hmem)
        end
      end
      close_cb.call
      true
    rescue
      false
    end

    def _write_host_launcher(sh_path)
      host_sh  = _to_host_path(sh_path)
      host_cwd = _to_host_path(Dir.pwd)
      launcher = "Z:/tmp/kif_mod_launcher.sh"
      # This script runs on the host (Linux) to bridge the environment
      content = "#!/bin/bash\ncd '#{host_cwd}'\nbash '#{host_sh}'\necho ''\nread -p 'Press Enter to close...'\n"
      File.open(launcher, "wb") { |f| f.write(content) }
      File.chmod(0755, launcher) rescue nil
      return "/tmp/kif_mod_launcher.sh"
    rescue
      nil
    end

    def _ask_and_launch(sh_path, bat_path)
      unless _is_linux_host?
        # Non-Linux host (likely standard Windows)
        if File.exist?(bat_path)
          system("start \"\" \"#{bat_path.gsub('/', '\\\\')}\"")
        else
          ui_message("#{File.basename(bat_path)} not found.")
        end
        return
      end

      # Linux/Wine detected
      msg = "Linux/Wine detected.\n\nRunning external tools inside Wine is unreliable.\nCopying command for your NATIVE Linux terminal..."
      return unless ui_message(msg, ["Copy Command", "Cancel"]) == 0

      host_launcher = _write_host_launcher(sh_path)
      if host_launcher
        cmd = "bash #{host_launcher}"
        if _copy_to_clipboard(cmd)
          ui_message("Command copied to clipboard!\n\nPaste it into your Linux terminal (Konsole/distro-terminal)\nto complete the process with your native Git.")
        else
          ui_message("Clipboard failure.\nManually run: bash #{host_launcher}")
        end
      end
    end

    def upload_mod; _ask_and_launch(File.join(ModManager::MODDEV_DIR,"publish_mod.sh"), File.join(ModManager::MODDEV_DIR,"publish_mod.bat")); end
    def delete_from_repo; _ask_and_launch(File.join(ModManager::MODDEV_DIR,"delete_mod.sh"), File.join(ModManager::MODDEV_DIR,"delete_mod.bat")); end
    def upload_modpack; _ask_and_launch(File.join(ModManager::MODDEV_DIR,"publish_modpack.sh"), File.join(ModManager::MODDEV_DIR,"publish_modpack.bat")); end
    def delete_modpack_from_repo; _ask_and_launch(File.join(ModManager::MODDEV_DIR,"delete_modpack.sh"), File.join(ModManager::MODDEV_DIR,"delete_modpack.bat")); end
  end
end

if defined?(ModManager)
  input_scenes = ["Scene_Installed", "Scene_Browser", "Scene_ModderTools"]
  input_scenes.each { |s| ModManager.const_get(s).send(:prepend, ModManager::LinuxInputPatch) if ModManager.const_defined?(s) }
  ModManager::Scene_ModderTools.send(:prepend, ModManager::LinuxPublisherPatch) if ModManager.const_defined?("Scene_ModderTools")
end
