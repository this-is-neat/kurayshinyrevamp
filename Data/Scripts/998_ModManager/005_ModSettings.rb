#==============================================================================
# Mod Manager — Per-Mod Settings Screen
#
# Extends PokemonOption_Scene to show settings defined in a mod's mod.json.
# Settings are persisted to <mod_folder>/settings.json.
#==============================================================================

module ModManager
  class Scene_ModSettings < PokemonOption_Scene
    def initialize(mod_info)
      super()
      @mod_info = mod_info
      @current_settings = ModManager.load_mod_settings(mod_info.id)
    end

    def initUIElements
      @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
        _INTL("#{@mod_info.name} Settings"), 0, 0, Graphics.width, 64, @viewport)
      @sprites["textbox"] = pbCreateMessageWindow
      @sprites["textbox"].text = _INTL("Configure settings for this mod.")
      @sprites["textbox"].letterbyletter = false
      pbSetSystemFont(@sprites["textbox"].contents)
    end

    def getDefaultDescription
      return _INTL("Configure settings for {1}.", @mod_info.name)
    end

    def pbGetOptions(inloadscreen = false)
      options = []
      return options unless @mod_info && @mod_info.settings_defs

      @mod_info.settings_defs.each do |sd|
        next unless sd.is_a?(Hash) && sd["key"]

        key = sd["key"]
        label = sd["label"] || key
        desc = sd["description"] || label
        type = sd["type"] || "toggle"

        case type
        when "toggle"
          get_proc = proc { @current_settings[key] == true ? 1 : 0 }
          set_proc = proc { |val| @current_settings[key] = (val == 1) }
          options << EnumOption.new(_INTL(label), [_INTL("Off"), _INTL("On")],
                                   get_proc, set_proc, desc)

        when "enum"
          vals = sd["options"]
          next unless vals.is_a?(Array) && vals.length > 0
          get_proc = proc {
            cur = @current_settings[key]
            idx = vals.index(cur)
            idx || 0
          }
          set_proc = proc { |val| @current_settings[key] = vals[val] }
          display = vals.map { |v| _INTL(v.to_s) }
          options << EnumOption.new(_INTL(label), display, get_proc, set_proc, desc)

        when "slider"
          opt_min = sd["min"] || 0
          opt_max = sd["max"] || 100
          step = sd["step"] || 1
          get_proc = proc {
            cur = @current_settings[key] || opt_min
            cur.to_i - opt_min
          }
          set_proc = proc { |val| @current_settings[key] = val + opt_min }
          options << SliderOption.new(_INTL(label), opt_min, opt_max, step,
                                     get_proc, set_proc, desc)

        when "number"
          opt_min = sd["min"] || 0
          opt_max = sd["max"] || 99
          get_proc = proc {
            cur = @current_settings[key] || opt_min
            cur.to_i - opt_min
          }
          set_proc = proc { |val| @current_settings[key] = val + opt_min }
          options << NumberOption.new(_INTL(label), opt_min, opt_max,
                                     get_proc, set_proc)
        end
      end

      options
    end

    def pbEndScene
      # Save settings before closing
      ModManager.save_mod_settings(@mod_info.id, @current_settings)
      super
    end

    # Entry point
    def main
      pbFadeOutIn {
        screen = PokemonOptionScreen.new(self)
        screen.pbStartScreen
      }
    end
  end
end
