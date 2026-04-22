#==============================================================================
# 990_NPT — Toggle UI
#
# Press Ctrl+N in the overworld to open a centered confirmation dialog asking the
# player whether they want to turn new Pokémon on/off. Uses pbMessage so
# the dialog is consistent with the rest of the game's UI and avoids having
# to build a custom sprite overlay.
#
# Scene_Map#update is aliased to check for the Ctrl+N key press on every frame
# while the player is walking around. Gated so it never fires during menus,
# battles, messages, or cutscenes.
#==============================================================================

module NPT
  module Toggle
    # Input::N isn't a constant in this engine; use the raw VK code for 'N'.
    TOGGLE_KEY_VK = 0x4E

    @toggle_key_down = false

    def self.show_toggle_dialog
      return unless $PokemonGlobal
      currently_on = new_pokemon_disabled?
      current_label = currently_on ? "OFF" : "ON"
      prompt = _INTL(
        "New Pokémon are currently {1}.\nTurn them {2}?",
        current_label,
        currently_on ? "ON" : "OFF"
      )
      if pbConfirmMessage(prompt)
        set_new_pokemon_disabled(!currently_on)
        # Encounter tables are built once at map load by PokemonEncounters#setup,
        # so we have to re-run setup for the current map or the toggle won't
        # take effect until the player leaves and comes back.
        if defined?($PokemonEncounters) && $PokemonEncounters && $game_map
          $PokemonEncounters.setup($game_map.map_id) rescue nil
        end
        if new_pokemon_disabled?
          pbMessage(_INTL("New Pokémon are now OFF.\nThey won't appear in wild battles, trainers,\nor the randomizer."))
        else
          pbMessage(_INTL("New Pokémon are now ON."))
        end
      end
    end

    def self.can_open_toggle?
      return false unless $scene.is_a?(Scene_Map)
      return false unless $game_map
      return false if $game_temp.nil?
      return false if $game_temp.message_window_showing
      return false if $game_temp.in_menu
      return false if $game_temp.in_battle
      return false if $game_player && $game_player.move_route_forcing
      return false if pbMapInterpreterRunning?
      # Don't fire while typing in chat — N would also be added to the message
      return false if defined?($chat_window) && $chat_window && $chat_window.input_mode
      true
    end

    def self.sync_input_state(get_async_key_state)
      @toggle_key_down = get_async_key_state && (get_async_key_state.call(TOGGLE_KEY_VK) & 0x8000) != 0
    rescue
      @toggle_key_down = false
    end

    def self.ctrl_n_trigger?(get_async_key_state)
      return false unless get_async_key_state
      n_down = (get_async_key_state.call(TOGGLE_KEY_VK) & 0x8000) != 0
      ctrl_down = Input.press?(Input::CTRL)
      triggered = ctrl_down && n_down && !@toggle_key_down
      @toggle_key_down = n_down
      triggered
    rescue
      @toggle_key_down = false
      false
    end
  end
end

class Scene_Map
  alias _npt_toggle_orig_update update

  def update
    _npt_toggle_orig_update
    _npt_toggle_check_input
  end

  def _npt_toggle_check_input
    @_npt_gas_n ||= Win32API.new('user32', 'GetAsyncKeyState', ['i'], 'i') rescue nil
    unless NPT::Toggle.can_open_toggle?
      NPT::Toggle.sync_input_state(@_npt_gas_n)
      return
    end
    return unless NPT::Toggle.ctrl_n_trigger?(@_npt_gas_n)
    NPT::Toggle.show_toggle_dialog
  rescue
  end
end
