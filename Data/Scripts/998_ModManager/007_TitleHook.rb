#==============================================================================
# Mod Manager — Title Screen Hook
#
# Adds "Mod Manager" button to the title/load screen.
# Overrides the TitleMultiplayer version of pbStartLoadScreen (659).
# Since 998 loads after 659, this alias chain works correctly.
#
# DEPENDENCY: 659_Multiplayer/002_UI/015_TitleMultiplayer.rb
# If that file changes its command structure, this file must be updated.
#==============================================================================

#==============================================================================
# Patch MultiSaves scene to accept an optional continue_index (6th arg)
# so we can place "Mod Manager" before "Continue" without breaking the
# save-info panel. TitleMultiplayer already adds this; this patch only
# applies when TitleMultiplayer is NOT present.
#==============================================================================
unless defined?(TitleMultiplayer)
  # Find the actual scene class (name varies across client versions)
  _mm_scene_class = defined?(PokemonLoad_Scene) ? PokemonLoad_Scene :
                    (defined?(PokemonLoadScene) ? PokemonLoadScene : nil)

  if _mm_scene_class
    _mm_scene_class.class_eval do
      alias _mod_mgr_orig_pbStartScene pbStartScene unless method_defined?(:_mod_mgr_orig_pbStartScene)

      def pbStartScene(commands, show_continue, trainer, frame_count, map_id, continue_index = 0)
        @continue_index = continue_index
        # Call original with commands reordered so continue is at index 0,
        # then fix panel order afterwards.
        if show_continue && continue_index > 0
          reordered = commands.dup
          cont_cmd = reordered.delete_at(continue_index)
          reordered.unshift(cont_cmd)
          _mod_mgr_orig_pbStartScene(reordered, show_continue, trainer, frame_count, map_id)
          # Dispose panels built with wrong order, rebuild correctly
          commands.length.times do |i|
            p = @sprites["panel#{i}"]
            next unless p
            p.bitmap.dispose if p.bitmap && !p.bitmap.disposed?
            p.dispose
          end
          y = 16 * 2
          for i in 0...commands.length
            is_continue = (show_continue && i == continue_index)
            @sprites["panel#{i}"] = PokemonLoadPanel.new(i, commands[i],
                                                         is_continue, trainer, frame_count, map_id, @viewport)
            @sprites["panel#{i}"].x = 24 * 2
            @sprites["panel#{i}"].y = y
            @sprites["panel#{i}"].pbRefresh
            y += is_continue ? 112 * 2 : 24 * 2
          end
        else
          _mod_mgr_orig_pbStartScene(commands, show_continue, trainer, frame_count, map_id)
        end
      end

      alias _mod_mgr_orig_pbSetParty pbSetParty unless method_defined?(:_mod_mgr_orig_pbSetParty)

      def pbSetParty(trainer)
        _mod_mgr_orig_pbSetParty(trainer)
        # pbSetParty uses hardcoded screen positions assuming continue is at
        # index 0. Offset player + party sprites when continue is lower.
        return unless @continue_index && @continue_index > 0
        offset_y = @continue_index * 24 * 2  # each small panel = 24*2 px
        if @sprites["player"]
          @sprites["player"].y += offset_y
        end
        6.times do |i|
          break unless @sprites["party#{i}"]
          @sprites["party#{i}"].y += offset_y
        end
      end
    end
  end
end

class PokemonLoadScreen
  alias _mod_mgr_title_pbStartLoadScreen pbStartLoadScreen unless method_defined?(:_mod_mgr_title_pbStartLoadScreen)

  def pbStartLoadScreen
    # ── Pre-init from MultiSaves ──────────────────────────────────────────
    updateHttpSettingsFile rescue nil
    updateCreditsFile rescue nil
    updateCustomDexFile rescue nil
    updateOnlineCustomSpritesFile rescue nil

    newer_version = find_newer_available_version rescue nil
    if newer_version
      if File.file?('.\INSTALL_OR_UPDATE.bat')
        update_answer = pbMessage(_INTL("Version {1} is now available! Update now?", newer_version), ["Yes","No"], 1)
        if update_answer == 0
          Process.spawn('.\INSTALL_OR_UPDATE.bat', "auto")
          exit
        end
      else
        pbMessage(_INTL("Version {1} is now available! Please check the game's official page to download the newest version.", newer_version))
      end
    end

    if $PokemonSystem && $PokemonSystem.shiny_cache == 1
      checkDirectory("Cache") rescue nil
      checkDirectory("Cache/Shiny") rescue nil
      Dir.glob("Cache/Shiny/*").each do |file|
        File.delete(file) if File.file?(file)
      end
    end

    has_unimported = (($game_temp.unimportedSprites && $game_temp.unimportedSprites.size > 0) rescue false)
    if has_unimported
      handleReplaceExistingSprites() rescue nil
    end
    has_imported = (($game_temp.nb_imported_sprites && $game_temp.nb_imported_sprites > 0) rescue false)
    if has_imported
      pbMessage(_INTL("{1} new custom sprites were imported into the game", $game_temp.nb_imported_sprites.to_s))
    end
    checkEnableSpritesDownload rescue nil
    $game_temp.nb_imported_sprites = nil rescue nil

    copyKeybindings()
    $KURAY_OPTIONSNAME_LOADED = false
    begin; kurayeggs_main() if $KURAYEGGS_WRITEDATA; rescue; end

    save_file_list = SaveData.display_slots
    first_time = true

    loop do
      # ── Outer loop: save slot switching ─────────────────────────────────
      save_file_list = SaveData.display_slots
      if @selected_file
        @save_data = load_save_file(SaveData.get_full_path(@selected_file), true)
      else
        @save_data = {}
      end
      @save_data ||= {}

      commands = []
      cmd_multiplayer   = -1
      cmd_mod_manager   = -1
      cmd_continue      = -1
      cmd_new_game      = -1
      cmd_new_game_plus = -1
      cmd_options       = -1
      cmd_language      = -1
      cmd_mystery_gift  = -1
      cmd_debug         = -1
      cmd_quit          = -1
      cmd_doc           = -1
      cmd_discord       = -1
      cmd_pifdiscord    = -1
      cmd_wiki          = -1

      show_continue = !@save_data.empty?
      new_game_plus = show_continue && ((@save_data[:player].new_game_plus_unlocked rescue false) || $DEBUG)

      # ── Build commands ────────────────────────────────────────────────
      if defined?(TitleMultiplayer)
        commands[cmd_multiplayer = commands.length] = _INTL('Multiplayer')
      end
      commands[cmd_mod_manager = commands.length] = _INTL('Mod Manager')

      if show_continue
        commands[cmd_continue = commands.length] = "#{@selected_file}"
        commands[cmd_mystery_gift = commands.length] = _INTL('Mystery Gift')
      end
      commands[cmd_new_game = commands.length] = _INTL('New Game')
      if new_game_plus
        commands[cmd_new_game_plus = commands.length] = _INTL('New Game +')
      end
      commands[cmd_options = commands.length]    = _INTL('Options')
      commands[cmd_discord = commands.length]    = _INTL('KIF Discord')
      commands[cmd_doc = commands.length]        = _INTL('KIF Documentation (Obsolete)')
      commands[cmd_pifdiscord = commands.length] = _INTL('PIF Discord')
      commands[cmd_wiki = commands.length]       = _INTL('Wiki')
      commands[cmd_language = commands.length]   = _INTL('Language') if Settings::LANGUAGES.length >= 2
      commands[cmd_debug = commands.length]      = _INTL('Debug') if $DEBUG
      commands[cmd_quit = commands.length]       = _INTL('Quit Game')
      cmd_left = -3
      cmd_right = -2

      map_id = show_continue ? (@save_data[:map_factory].map.map_id rescue 0) : 0
      # Both TitleMultiplayer and our patched MultiSaves accept 6 args
      @scene.pbStartScene(commands, show_continue, @save_data[:player],
                          @save_data[:frame_count] || 0, map_id, cmd_continue)
      @scene.pbSetParty(@save_data[:player]) if show_continue
      if first_time
        @scene.pbStartScene2
        first_time = false
      else
        @scene.pbUpdate
      end

      # Default selection: Continue if save exists, else New Game
      default_idx = show_continue ? cmd_continue : cmd_new_game
      sprites = @scene.instance_variable_get(:@sprites)
      if sprites && sprites["cmdwindow"]
        sprites["cmdwindow"].commands = commands
        sprites["cmdwindow"].index = default_idx
        commands.length.times do |i|
          panel = sprites["panel#{i}"]
          next unless panel
          panel.selected = (i == default_idx)
          panel.pbRefresh
        end
      end

      loop do
        # ── Inner loop: command selection ──────────────────────────────────
        command = @scene.pbChoose(commands, cmd_continue)
        pbPlayDecisionSE if command != cmd_quit

        case command
        when cmd_mod_manager
          scene = ModManager::Scene_Installed.new
          scene.main

        when cmd_multiplayer
          result = TitleMultiplayer.open_menu
          if TitleMultiplayer.pending_ip
            if show_continue
              next unless confirm_selected_save_load
              @save_data = load_selected_save_data
              next if @save_data.empty?
              @scene.pbEndScene
              Game.load(@save_data)
              $game_switches[SWITCH_V5_1] = true rescue nil
              ensureCorrectDifficulty() rescue nil
              setGameMode() rescue nil
              $PokemonGlobal.alt_sprite_substitutions = {} if !$PokemonGlobal.alt_sprite_substitutions rescue nil
              $PokemonGlobal.autogen_sprites_cache = {} rescue nil
              return
            else
              @scene.pbEndScene
              Game.start_new
              $PokemonGlobal.alt_sprite_substitutions = {} if !$PokemonGlobal.alt_sprite_substitutions rescue nil
              return
            end
          end

        when cmd_continue
          next unless confirm_selected_save_load
          @save_data = load_selected_save_data
          next if @save_data.empty?
          @scene.pbEndScene
          Game.load(@save_data)
          $game_switches[SWITCH_V5_1] = true rescue nil
          ensureCorrectDifficulty() rescue nil
          setGameMode() rescue nil
          $PokemonGlobal.alt_sprite_substitutions = {} if !$PokemonGlobal.alt_sprite_substitutions rescue nil
          $PokemonGlobal.autogen_sprites_cache = {} rescue nil
          return

        when cmd_new_game
          @scene.pbEndScene
          Game.start_new
          $PokemonGlobal.alt_sprite_substitutions = {} if !$PokemonGlobal.alt_sprite_substitutions rescue nil
          return

        when cmd_new_game_plus
          @scene.pbEndScene
          Game.start_new(@save_data[:bag], @save_data[:storage_system], @save_data[:player])
          @save_data[:player].new_game_plus_unlocked = true
          return

        when cmd_pifdiscord
          openUrlInBrowser(Settings::PIF_DISCORD_URL) rescue nil

        when cmd_wiki
          openUrlInBrowser(Settings::WIKI_URL) rescue nil

        when cmd_doc
          openUrlInBrowser("https://docs.google.com/document/d/1O6pKKL62dbLcapO0c2zDG2UI-eN6uatYlt_0GSk1dbE") rescue nil
          return

        when cmd_discord
          openUrlInBrowser(Settings::DISCORD_URL) rescue nil
          return

        when cmd_mystery_gift
          pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }

        when cmd_options
          pbFadeOutIn do
            scene = PokemonOption_Scene.new
            screen = PokemonOptionScreen.new(scene)
            screen.pbStartScreen(true)
          end

        when cmd_language
          @scene.pbEndScene
          $PokemonSystem.language = pbChooseLanguage
          pbLoadMessages('Data/' + Settings::LANGUAGES[$PokemonSystem.language][1])
          if show_continue
            @save_data[:pokemon_system] = $PokemonSystem
            File.open(SaveData.get_full_path(@selected_file), 'wb') { |file| Marshal.dump(@save_data, file) }
          end
          $scene = pbCallTitle
          return

        when cmd_debug
          pbFadeOutIn { pbDebugMenu(false) }

        when cmd_quit
          pbPlayCloseMenuSE
          @scene.pbEndScene
          $scene = nil
          return

        when cmd_left
          @scene.pbCloseScene
          @selected_file = SaveData.get_prev_slot(save_file_list, @selected_file)
          break # to outer loop

        when cmd_right
          @scene.pbCloseScene
          @selected_file = SaveData.get_next_slot(save_file_list, @selected_file)
          break # to outer loop

        else
          pbPlayBuzzerSE
        end
      end
    end
  end
end
