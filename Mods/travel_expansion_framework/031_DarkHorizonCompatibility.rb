if defined?(TravelExpansionFramework)
  module TravelExpansionFramework
    DARKHORIZON_START_LOCAL_MAP_ID = 127 unless const_defined?(:DARKHORIZON_START_LOCAL_MAP_ID)
    DARKHORIZON_START_ANCHOR = {
      :map_id    => DARKHORIZON_START_LOCAL_MAP_ID,
      :x         => 9,
      :y         => 9,
      :direction => 6
    }.freeze unless const_defined?(:DARKHORIZON_START_ANCHOR)

    module_function

    def darkhorizon_expansion_ids
      return [DARKHORIZON_EXPANSION_ID] + DARKHORIZON_LEGACY_EXPANSION_IDS if const_defined?(:DARKHORIZON_EXPANSION_ID)
      return ["darkhorizon", "dark_horizon", "pokemon_darkhorizon", "pokemon_dark_horizon"]
    rescue
      return ["darkhorizon"]
    end

    def darkhorizon_active_now?(map_id = nil)
      return !active_project_expansion_id(darkhorizon_expansion_ids, map_id).nil? if respond_to?(:active_project_expansion_id)
      target_map_id = integer(map_id || ($game_map.map_id rescue 0), 0)
      fixed_start = fixed_external_map_block_start("darkhorizon") if respond_to?(:fixed_external_map_block_start)
      fixed_start = integer(fixed_start, 35_000)
      return target_map_id >= fixed_start && target_map_id < fixed_start + RESERVED_MAP_BLOCK_SIZE
    rescue
      return false
    end

    def current_darkhorizon_expansion_id(map_id = nil)
      expansion = active_project_expansion_id(darkhorizon_expansion_ids, map_id) if respond_to?(:active_project_expansion_id)
      return expansion if !expansion.to_s.empty?
      return DARKHORIZON_EXPANSION_ID if const_defined?(:DARKHORIZON_EXPANSION_ID)
      return "darkhorizon"
    rescue
      return "darkhorizon"
    end

    def darkhorizon_map_block_start
      expansion = current_darkhorizon_expansion_id
      manifest = manifest_for(expansion) if respond_to?(:manifest_for)
      block = manifest[:map_block] if manifest
      start = integer(block[:start] || block["start"], 0) if block.is_a?(Hash)
      return start if start.to_i > 0
      fixed = fixed_external_map_block_start("darkhorizon") if respond_to?(:fixed_external_map_block_start)
      return integer(fixed, 35_000)
    rescue
      return 35_000
    end

    def darkhorizon_virtual_map_id(local_map_id)
      local = integer(local_map_id, 0)
      return local if local >= RESERVED_MAP_BLOCK_START
      return darkhorizon_map_block_start + local
    rescue
      return 35_000 + local_map_id.to_i
    end

    def darkhorizon_anchor(local_anchor = nil)
      raw = local_anchor.is_a?(Hash) ? local_anchor : DARKHORIZON_START_ANCHOR
      anchor = {
        :map_id    => darkhorizon_virtual_map_id(raw[:map_id] || raw["map_id"]),
        :x         => integer(raw[:x] || raw["x"], 0),
        :y         => integer(raw[:y] || raw["y"], 0),
        :direction => integer(raw[:direction] || raw["direction"], 2)
      }
      return sanitize_anchor(anchor) || anchor
    rescue
      return {
        :map_id    => 35_127,
        :x         => 9,
        :y         => 9,
        :direction => 6
      }
    end

    def darkhorizon_species_id(species)
      raw = species
      raw = raw.species if raw.respond_to?(:species)
      raw = raw.id if raw.respond_to?(:id)
      data = GameData::Species.try_get(raw) if defined?(GameData::Species) && GameData::Species.respond_to?(:try_get)
      data = GameData::Species.get(raw) if !data && defined?(GameData::Species) && GameData::Species.respond_to?(:get)
      return data.species if data && data.respond_to?(:species)
      return data.id if data && data.respond_to?(:id)
      return raw.to_sym if raw.is_a?(String) && !raw.empty?
      return raw
    rescue
      return species
    end

    def darkhorizon_item_id(item)
      raw = item
      raw = raw.id if raw.respond_to?(:id)
      data = GameData::Item.try_get(raw) if defined?(GameData::Item) && GameData::Item.respond_to?(:try_get)
      data = GameData::Item.get(raw) if !data && defined?(GameData::Item) && GameData::Item.respond_to?(:get)
      return data.id if data && data.respond_to?(:id)
      return raw.to_sym if raw.is_a?(String) && !raw.empty?
      return raw
    rescue
      return item
    end

    def darkhorizon_initialize_species!
      return false if !defined?(EliteBattle)
      species = [:NONE]
      if defined?(GameData::Species) && GameData::Species.respond_to?(:each_species)
        GameData::Species.each_species { |entry| species << darkhorizon_species_id(entry) }
      elsif defined?(GameData::Species) && GameData::Species.respond_to?(:each)
        GameData::Species.each { |entry| species << darkhorizon_species_id(entry) }
      elsif EliteBattle.respond_to?(:all_species)
        species.concat(Array(EliteBattle.all_species))
      end
      species = species.compact.uniq
      species = [:NONE] if species.empty?
      EliteBattle.instance_variable_set(:@full_species, species)
      return true
    rescue => e
      log("[darkhorizon] InitializeSpecies shim failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      EliteBattle.instance_variable_set(:@full_species, [:NONE]) if defined?(EliteBattle)
      return false
    end

    def darkhorizon_initialize_items!
      return false if !defined?(EliteBattle)
      items = [:NONE]
      if defined?(GameData::Item) && GameData::Item.respond_to?(:each)
        GameData::Item.each { |entry| items << darkhorizon_item_id(entry) }
      elsif defined?(GameData::Item) && GameData::Item.respond_to?(:values)
        GameData::Item.values.each { |entry| items << darkhorizon_item_id(entry) }
      end
      items = items.compact.uniq
      items = [:NONE] if items.empty?
      EliteBattle.instance_variable_set(:@full_items, items)
      return true
    rescue => e
      log("[darkhorizon] InitializeItems shim failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      EliteBattle.instance_variable_set(:@full_items, [:NONE]) if defined?(EliteBattle)
      return false
    end

    def darkhorizon_species_index(species)
      darkhorizon_initialize_species! if !defined?(EliteBattle) || !EliteBattle.instance_variable_get(:@full_species).is_a?(Array)
      list = EliteBattle.instance_variable_get(:@full_species) || [:NONE]
      resolved = darkhorizon_species_id(species)
      index = list.index(resolved)
      if index.nil? && resolved
        list << resolved
        EliteBattle.instance_variable_set(:@full_species, list)
        index = list.length - 1
      end
      return index || 0
    rescue
      return 0
    end

    def darkhorizon_item_index(item)
      darkhorizon_initialize_items! if !defined?(EliteBattle) || !EliteBattle.instance_variable_get(:@full_items).is_a?(Array)
      list = EliteBattle.instance_variable_get(:@full_items) || [:NONE]
      resolved = darkhorizon_item_id(item)
      index = list.index(resolved)
      if index.nil? && resolved
        list << resolved
        EliteBattle.instance_variable_set(:@full_items, list)
        index = list.length - 1
      end
      return index || 0
    rescue
      return 0
    end

    def darkhorizon_item_available?(item)
      return false if item.nil?
      resolved = darkhorizon_item_id(item)
      darkhorizon_initialize_items! if defined?(EliteBattle) && !EliteBattle.instance_variable_get(:@full_items).is_a?(Array)
      list = defined?(EliteBattle) ? EliteBattle.instance_variable_get(:@full_items) : nil
      return true if list.is_a?(Array) && list.include?(resolved)
      return !(GameData::Item.try_get(resolved).nil?) if defined?(GameData::Item) && GameData::Item.respond_to?(:try_get)
      return true
    rescue
      return false
    end

    def darkhorizon_add_item(item, quantity = 1)
      return false if !$bag
      resolved = darkhorizon_item_id(item)
      return false if resolved.nil?
      return false if defined?(GameData::Item) && GameData::Item.respond_to?(:try_get) && GameData::Item.try_get(resolved).nil?
      $bag.add(resolved, [integer(quantity, 1), 1].max)
      return true
    rescue => e
      log("[darkhorizon] skipped starter item #{item.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def darkhorizon_set_default_mode!
      if defined?($game_switches) && $game_switches && defined?(Settings) && Settings.const_defined?(:SWITCH_HARDMODE)
        $game_switches[Settings::SWITCH_HARDMODE] = false
      end
      EliteBattle.set(:randomizer, false) if defined?(EliteBattle) && EliteBattle.respond_to?(:set)
      EliteBattle.set(:nuzlocke, false) if defined?(EliteBattle) && EliteBattle.respond_to?(:set)
      return true
    rescue
      return true
    end

    def darkhorizon_starting_items!
      darkhorizon_add_item(:ANTIDOTE, 1)
      darkhorizon_add_item(:BURNHEAL, 1)
      darkhorizon_add_item(:PARALYZEHEAL, 1)
      darkhorizon_add_item(:ICEHEAL, 1)
      darkhorizon_add_item(:POTION, 1)
      return true
    rescue
      return true
    end

    def darkhorizon_starting_settings!
      player = (defined?($player) && $player) ? $player : (defined?($Trainer) ? $Trainer : nil)
      player.has_running_shoes = true if player && player.respond_to?(:has_running_shoes=)
      $game_variables[80] = 1 if defined?($game_variables) && $game_variables
      player.initialize_instant_messages if player && player.respond_to?(:initialize_instant_messages)
      return true
    rescue => e
      log("[darkhorizon] starting settings shim failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return true
    end

    def darkhorizon_healing_machine!
      trainer = (defined?($Trainer) && $Trainer) ? $Trainer : nil
      trainer ||= $player if defined?($player) && $player
      return false if !trainer
      party = trainer.party if trainer.respond_to?(:party)
      healed = 0
      Array(party).each do |pkmn|
        next if !pkmn
        next if pkmn.respond_to?(:permaFaint) && pkmn.permaFaint
        next if !pkmn.respond_to?(:heal)
        pkmn.heal
        healed += 1
      end
      trainer.heal_party if healed == 0 && trainer.respond_to?(:heal_party)
      pbSEPlay("Recovery") if defined?(pbSEPlay)
      log("[darkhorizon] healing machine restored party") if respond_to?(:log)
      return true
    rescue => e
      log("[darkhorizon] healing machine shim failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      begin
        $Trainer.heal_party if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:heal_party)
      rescue
      end
      return true
    end

    def darkhorizon_transfer_to_start!
      anchor = darkhorizon_anchor
      context = {
        :source            => :story_transfer,
        :expansion_id      => current_darkhorizon_expansion_id(anchor[:map_id]),
        :allow_story_state => true,
        :immediate         => true,
        :auto_rescue       => true
      }
      if respond_to?(:safe_transfer_to_anchor)
        return true if safe_transfer_to_anchor(anchor, context)
      end
      if $game_temp && $scene && $scene.respond_to?(:transfer_player)
        $game_temp.player_transferring = true if $game_temp.respond_to?(:player_transferring=)
        $game_temp.player_new_map_id = anchor[:map_id]
        $game_temp.player_new_x = anchor[:x]
        $game_temp.player_new_y = anchor[:y]
        $game_temp.player_new_direction = anchor[:direction]
        $scene.transfer_player(false)
        $game_map.autoplay if $game_map && $game_map.respond_to?(:autoplay)
        $game_map.refresh if $game_map && $game_map.respond_to?(:refresh)
        return true
      end
      return false
    rescue => e
      log("[darkhorizon] start transfer failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def darkhorizon_start_new_game!
      darkhorizon_initialize_species!
      darkhorizon_initialize_items!
      darkhorizon_set_default_mode!
      darkhorizon_starting_items!
      darkhorizon_starting_settings!
      $PokemonTemp.begunNewGame = true if defined?($PokemonTemp) && $PokemonTemp && $PokemonTemp.respond_to?(:begunNewGame=)
      result = darkhorizon_transfer_to_start!
      clear_stuck_screen_effects!("darkhorizon intro", true) if respond_to?(:clear_stuck_screen_effects!)
      log("[darkhorizon] safely skipped unsupported standalone intro UI and transferred to story start") if respond_to?(:log)
      return result
    rescue => e
      log("[darkhorizon] pbStartNewGame shim failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      clear_stuck_screen_effects!("darkhorizon intro failure", true) if respond_to?(:clear_stuck_screen_effects!)
      return true
    end
  end
end

if defined?(Settings)
  module Settings
    SWITCH_HARDMODE       = 64 unless const_defined?(:SWITCH_HARDMODE)
    SWITCH_BATTLE_RUNNING = 237 unless const_defined?(:SWITCH_BATTLE_RUNNING)
    SWITCH_STORYPOINT_1   = 218 unless const_defined?(:SWITCH_STORYPOINT_1)
    SWITCH_STORYPOINT_2   = 219 unless const_defined?(:SWITCH_STORYPOINT_2)
    SWITCH_STORYPOINT_3   = 220 unless const_defined?(:SWITCH_STORYPOINT_3)
    SWITCH_STORYPOINT_4   = 221 unless const_defined?(:SWITCH_STORYPOINT_4)
    SWITCH_STORYPOINT_5   = 222 unless const_defined?(:SWITCH_STORYPOINT_5)
    SWITCH_STORYPOINT_6   = 223 unless const_defined?(:SWITCH_STORYPOINT_6)
    SWITCH_STORYPOINT_7   = 224 unless const_defined?(:SWITCH_STORYPOINT_7)
    SWITCH_STORYPOINT_8   = 225 unless const_defined?(:SWITCH_STORYPOINT_8)
    SWITCH_STORYPOINT_9   = 234 unless const_defined?(:SWITCH_STORYPOINT_9)
    SWITCH_STORYPOINT_Wes = 216 unless const_defined?(:SWITCH_STORYPOINT_Wes)
    SWITCH_STORYPOINT_Nik = 217 unless const_defined?(:SWITCH_STORYPOINT_Nik)
    VARIABLE_AUTOSAVE     = 91 unless const_defined?(:VARIABLE_AUTOSAVE)
  end
end

if defined?(PokemonGlobalMetadata)
  class PokemonGlobalMetadata
    attr_accessor :isRandomizer unless method_defined?(:isRandomizer)
    attr_accessor :randomizedData unless method_defined?(:randomizedData)
    attr_accessor :randomizerRules unless method_defined?(:randomizerRules)
    attr_accessor :isNuzlocke unless method_defined?(:isNuzlocke)
    attr_accessor :qNuzlocke unless method_defined?(:qNuzlocke)
    attr_accessor :nuzlockeData unless method_defined?(:nuzlockeData)
    attr_accessor :nuzlockeRules unless method_defined?(:nuzlockeRules)
  end
end

if defined?(PokemonSystem)
  class PokemonSystem
    def levelcap
      @levelcap = 0 if @levelcap.nil?
      return @levelcap
    end unless method_defined?(:levelcap)

    def levelcap=(value)
      @levelcap = value.to_i
    end unless method_defined?(:levelcap=)

    def battle_speed
      @battle_speed = 0 if @battle_speed.nil?
      return @battle_speed
    end unless method_defined?(:battle_speed)

    def battle_speed=(value)
      @battle_speed = value.to_i
    end unless method_defined?(:battle_speed=)

    def only_speedup_battles
      @only_speedup_battles = 0 if @only_speedup_battles.nil?
      return @only_speedup_battles
    end unless method_defined?(:only_speedup_battles)

    def only_speedup_battles=(value)
      @only_speedup_battles = value.to_i
    end unless method_defined?(:only_speedup_battles=)

    def sendtoboxes
      @sendtoboxes = 0 if @sendtoboxes.nil?
      return @sendtoboxes
    end unless method_defined?(:sendtoboxes)

    def sendtoboxes=(value)
      @sendtoboxes = value.to_i
    end unless method_defined?(:sendtoboxes=)

    def givenicknames
      @givenicknames = 0 if @givenicknames.nil?
      return @givenicknames
    end unless method_defined?(:givenicknames)

    def givenicknames=(value)
      @givenicknames = value.to_i
    end unless method_defined?(:givenicknames=)

    def Autosave
      @Autosave = 0 if @Autosave.nil?
      return @Autosave
    end unless method_defined?(:Autosave)

    def Autosave=(value)
      @Autosave = value.to_i
    end unless method_defined?(:Autosave=)

    def from_current_menu_theme(data, default = nil)
      default = data if default.nil?
      if data.is_a?(String)
        menu_path = defined?(MENU_FILE_PATH) ? MENU_FILE_PATH : "Graphics/Pictures/VPM/"
        file = "Theme #{current_menu_theme.to_i + 1}/#{default}"
        return file if defined?(pbResolveBitmap) && pbResolveBitmap(menu_path + file)
        return default
      elsif data.is_a?(Array)
        return data[current_menu_theme.to_i] || default
      end
      return default
    rescue
      return default
    end unless method_defined?(:from_current_menu_theme)
  end
end

if defined?(Player)
  class Player
    def initialize_instant_messages
      @instant_messages = [] if !instance_variable_defined?(:@instant_messages) || @instant_messages.nil?
      return @instant_messages
    end if !method_defined?(:initialize_instant_messages)

    def instant_messages
      @instant_messages = [] if !instance_variable_defined?(:@instant_messages) || @instant_messages.nil?
      return @instant_messages
    end if !method_defined?(:instant_messages)

    def im_passive
      return []
    end if !method_defined?(:im_passive)
  end
end

if defined?(Pokemon)
  class Pokemon
    attr_accessor :permaFaint unless method_defined?(:permaFaint)
  end
end

if defined?(EliteBattle)
  module EliteBattle
    class << self
      def InitializeSpecies
        return TravelExpansionFramework.darkhorizon_initialize_species! if defined?(TravelExpansionFramework)
        return true
      end unless method_defined?(:InitializeSpecies)

      def InitializeItems
        return TravelExpansionFramework.darkhorizon_initialize_items! if defined?(TravelExpansionFramework)
        return true
      end unless method_defined?(:InitializeItems)

      def CanGetItemData?(item)
        return TravelExpansionFramework.darkhorizon_item_available?(item) if defined?(TravelExpansionFramework)
        return true
      end unless method_defined?(:CanGetItemData?)

      def GetSpeciesIndex(species)
        return TravelExpansionFramework.darkhorizon_species_index(species) if defined?(TravelExpansionFramework)
        return 0
      end unless method_defined?(:GetSpeciesIndex)

      def GetSpeciesID(species)
        return TravelExpansionFramework.darkhorizon_species_id(species) if defined?(TravelExpansionFramework)
        return species
      end unless method_defined?(:GetSpeciesID)

      def GetItemID(item)
        return TravelExpansionFramework.darkhorizon_item_index(item) if defined?(TravelExpansionFramework)
        return 0
      end unless method_defined?(:GetItemID)

      def randomizer?
        return !!$PokemonGlobal.isRandomizer if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:isRandomizer)
        return !!instance_variable_get(:@tef_darkhorizon_randomizer)
      rescue
        return false
      end unless method_defined?(:randomizer?)

      def randomizerOn?
        return randomizer? && !!get(:randomizer) if respond_to?(:get)
        return randomizer?
      rescue
        return false
      end unless method_defined?(:randomizerOn?)

      def startRandomizer(skip = false)
        instance_variable_set(:@tef_darkhorizon_randomizer, true)
        set(:randomizer, true) if respond_to?(:set)
        if defined?($PokemonGlobal) && $PokemonGlobal
          $PokemonGlobal.isRandomizer = true if $PokemonGlobal.respond_to?(:isRandomizer=)
          $PokemonGlobal.randomizerRules = [] if $PokemonGlobal.respond_to?(:randomizerRules=) && $PokemonGlobal.randomizerRules.nil?
          $PokemonGlobal.randomizedData = {} if $PokemonGlobal.respond_to?(:randomizedData=) && $PokemonGlobal.randomizedData.nil?
        end
        return true
      rescue
        return true
      end unless method_defined?(:startRandomizer)

      def resetRandomizer
        instance_variable_set(:@tef_darkhorizon_randomizer, false)
        set(:randomizer, false) if respond_to?(:set)
        if defined?($PokemonGlobal) && $PokemonGlobal
          $PokemonGlobal.isRandomizer = false if $PokemonGlobal.respond_to?(:isRandomizer=)
          $PokemonGlobal.randomizerRules = nil if $PokemonGlobal.respond_to?(:randomizerRules=)
          $PokemonGlobal.randomizedData = nil if $PokemonGlobal.respond_to?(:randomizedData=)
        end
        return true
      rescue
        return true
      end unless method_defined?(:resetRandomizer)

      def nuzlocke?
        return !!$PokemonGlobal.isNuzlocke if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:isNuzlocke)
        return !!instance_variable_get(:@tef_darkhorizon_nuzlocke)
      rescue
        return false
      end unless method_defined?(:nuzlocke?)

      def nuzlockeOn?
        return nuzlocke? && !!get(:nuzlocke) if respond_to?(:get)
        return nuzlocke?
      rescue
        return false
      end unless method_defined?(:nuzlockeOn?)

      def startNuzlocke(skip = false)
        instance_variable_set(:@tef_darkhorizon_nuzlocke, true)
        set(:nuzlocke, true) if respond_to?(:set)
        if defined?($PokemonGlobal) && $PokemonGlobal
          $PokemonGlobal.isNuzlocke = true if $PokemonGlobal.respond_to?(:isNuzlocke=)
          $PokemonGlobal.qNuzlocke = true if $PokemonGlobal.respond_to?(:qNuzlocke=)
          $PokemonGlobal.nuzlockeRules = [] if $PokemonGlobal.respond_to?(:nuzlockeRules=) && $PokemonGlobal.nuzlockeRules.nil?
          $PokemonGlobal.nuzlockeData = {} if $PokemonGlobal.respond_to?(:nuzlockeData=) && $PokemonGlobal.nuzlockeData.nil?
        end
        return true
      rescue
        return true
      end unless method_defined?(:startNuzlocke)

      def resetNuzlocke
        instance_variable_set(:@tef_darkhorizon_nuzlocke, false)
        set(:nuzlocke, false) if respond_to?(:set)
        if defined?($PokemonGlobal) && $PokemonGlobal
          $PokemonGlobal.isNuzlocke = false if $PokemonGlobal.respond_to?(:isNuzlocke=)
          $PokemonGlobal.qNuzlocke = false if $PokemonGlobal.respond_to?(:qNuzlocke=)
          $PokemonGlobal.nuzlockeRules = nil if $PokemonGlobal.respond_to?(:nuzlockeRules=)
          $PokemonGlobal.nuzlockeData = nil if $PokemonGlobal.respond_to?(:nuzlockeData=)
        end
        return true
      rescue
        return true
      end unless method_defined?(:resetNuzlocke)
    end
  end
end

class TrainerBattle
  class << self
    unless method_defined?(:start)
      def start(*args)
        if defined?(TravelExpansionFramework) && TravelExpansionFramework.darkhorizon_active_now?
          local_skip = TravelExpansionFramework.darkhorizon_virtual_map_id(144) rescue 35_144
          setBattleRule("2v2") if defined?(setBattleRule) &&
                                  (!defined?($game_map) || !$game_map || $game_map.map_id.to_i != local_skip.to_i)
        end
        return false if args.empty?
        if args[0].is_a?(Array)
          first = args[0]
          return pbTrainerBattle(first[0], first[1], first[3], false, first[2].to_i, false, 1) if defined?(pbTrainerBattle)
        end
        trainer_type = args[0]
        trainer_name = args[1]
        version = 0
        end_speech = nil
        can_lose = false
        outcome_var = 1
        args[2..-1].to_a.each do |arg|
          if arg.is_a?(Integer)
            version = arg if version.to_i == 0
          elsif arg.is_a?(String)
            end_speech = arg if end_speech.nil?
          elsif arg == true || arg == false
            can_lose = arg
          elsif arg.is_a?(Hash)
            version = arg[:version].to_i if arg.has_key?(:version)
            end_speech = arg[:end_speech] || arg["end_speech"] || end_speech
            can_lose = !!(arg[:can_lose] || arg["can_lose"]) if arg.has_key?(:can_lose) || arg.has_key?("can_lose")
            outcome_var = arg[:outcome_var].to_i if arg.has_key?(:outcome_var)
            outcome_var = arg["outcome_var"].to_i if arg.has_key?("outcome_var")
          end
        end
        return pbTrainerBattle(trainer_type, trainer_name, end_speech, false, version, can_lose, outcome_var) if defined?(pbTrainerBattle)
        return false
      rescue => e
        TravelExpansionFramework.log("[darkhorizon] TrainerBattle.start bridge failed safely: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                                            TravelExpansionFramework.respond_to?(:log)
        return false
      end
    end
  end
end

if defined?(Interpreter) && defined?(::TrainerBattle)
  class Interpreter
    TrainerBattle = ::TrainerBattle unless const_defined?(:TrainerBattle, false)
  end
end

if defined?(pbStartNewGame) && !defined?(tef_darkhorizon_original_pbStartNewGame)
  alias tef_darkhorizon_original_pbStartNewGame pbStartNewGame
end

def pbStartNewGame(*args)
  if defined?(TravelExpansionFramework) && TravelExpansionFramework.darkhorizon_active_now?
    return TravelExpansionFramework.darkhorizon_start_new_game!
  end
  return send(:tef_darkhorizon_original_pbStartNewGame, *args) if respond_to?(:tef_darkhorizon_original_pbStartNewGame, true)
  return true
end

def pbEasyHardMode_Selection(*_args)
  return TravelExpansionFramework.darkhorizon_set_default_mode! if defined?(TravelExpansionFramework)
  return true
end unless defined?(pbEasyHardMode_Selection)

def pbRandomizer_Selection(*_args)
  return true
end unless defined?(pbRandomizer_Selection)

def pbNuzlocke_Selection(*_args)
  return true
end unless defined?(pbNuzlocke_Selection)

def pbGameIntroduction(*_args)
  return true
end unless defined?(pbGameIntroduction)

def pbSetPlayerStarting(*_args)
  pbsetPlayerStartingItems if respond_to?(:pbsetPlayerStartingItems, true)
  pbsetPlayerStartingSettings if respond_to?(:pbsetPlayerStartingSettings, true)
  return pbSetPlayerStartingPosition if respond_to?(:pbSetPlayerStartingPosition, true)
  return true
end unless defined?(pbSetPlayerStarting)

def pbSetPlayerStartingPosition(*_args)
  return TravelExpansionFramework.darkhorizon_transfer_to_start! if defined?(TravelExpansionFramework)
  return true
end unless defined?(pbSetPlayerStartingPosition)

def pbsetPlayerStartingSettings(*_args)
  return TravelExpansionFramework.darkhorizon_starting_settings! if defined?(TravelExpansionFramework)
  return true
end unless defined?(pbsetPlayerStartingSettings)

def pbsetPlayerStartingItems(*_args)
  return TravelExpansionFramework.darkhorizon_starting_items! if defined?(TravelExpansionFramework)
  return true
end unless defined?(pbsetPlayerStartingItems)

def pbHealingMachine(*_args)
  return TravelExpansionFramework.darkhorizon_healing_machine! if defined?(TravelExpansionFramework) &&
                                                                  TravelExpansionFramework.respond_to?(:darkhorizon_healing_machine!)
  $Trainer.heal_party if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:heal_party)
  return true
end unless defined?(pbHealingMachine)

module TravelExpansionFramework
  module_function

  def darkhorizon_xd_pc!
    if defined?(pbPokeCenterPC)
      pbPokeCenterPC
      return true
    end
    if defined?(PokemonStorageScene) && defined?(PokemonStorageScreen) && defined?($PokemonStorage) && $PokemonStorage
      pbFadeOutIn {
        scene = PokemonStorageScene.new
        screen = PokemonStorageScreen.new(scene, $PokemonStorage)
        screen.pbStartScreen(0)
      }
      return true
    end
    log("[darkhorizon] pbXDPC skipped because host PC UI is unavailable") if respond_to?(:log)
    return true
  rescue => e
    log("[darkhorizon] pbXDPC failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end
end

def pbXDPC(*_args)
  return TravelExpansionFramework.darkhorizon_xd_pc! if defined?(TravelExpansionFramework) &&
                                                        TravelExpansionFramework.respond_to?(:darkhorizon_xd_pc!)
  return pbPokeCenterPC if defined?(pbPokeCenterPC)
  return true
end unless defined?(pbXDPC)

if defined?(Interpreter)
  class Interpreter
    def pbStartNewGame(*args)
      return TravelExpansionFramework.darkhorizon_start_new_game! if defined?(TravelExpansionFramework) &&
                                                                    TravelExpansionFramework.darkhorizon_active_now?
      return true
    end unless method_defined?(:pbStartNewGame)

    def pbEasyHardMode_Selection(*_args)
      return TravelExpansionFramework.darkhorizon_set_default_mode! if defined?(TravelExpansionFramework)
      return true
    end unless method_defined?(:pbEasyHardMode_Selection)

    def pbRandomizer_Selection(*_args)
      return true
    end unless method_defined?(:pbRandomizer_Selection)

    def pbNuzlocke_Selection(*_args)
      return true
    end unless method_defined?(:pbNuzlocke_Selection)

    def pbGameIntroduction(*_args)
      return true
    end unless method_defined?(:pbGameIntroduction)

    def pbSetPlayerStarting(*_args)
      pbsetPlayerStartingItems if respond_to?(:pbsetPlayerStartingItems, true)
      pbsetPlayerStartingSettings if respond_to?(:pbsetPlayerStartingSettings, true)
      return pbSetPlayerStartingPosition if respond_to?(:pbSetPlayerStartingPosition, true)
      return true
    end unless method_defined?(:pbSetPlayerStarting)

    def pbSetPlayerStartingPosition(*_args)
      return TravelExpansionFramework.darkhorizon_transfer_to_start! if defined?(TravelExpansionFramework)
      return true
    end unless method_defined?(:pbSetPlayerStartingPosition)

    def pbsetPlayerStartingSettings(*_args)
      return TravelExpansionFramework.darkhorizon_starting_settings! if defined?(TravelExpansionFramework)
      return true
    end unless method_defined?(:pbsetPlayerStartingSettings)

    def pbsetPlayerStartingItems(*_args)
      return TravelExpansionFramework.darkhorizon_starting_items! if defined?(TravelExpansionFramework)
      return true
    end unless method_defined?(:pbsetPlayerStartingItems)

    def pbHealingMachine(*_args)
      return TravelExpansionFramework.darkhorizon_healing_machine! if defined?(TravelExpansionFramework) &&
                                                                      TravelExpansionFramework.respond_to?(:darkhorizon_healing_machine!)
      $Trainer.heal_party if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:heal_party)
      return true
    end unless method_defined?(:pbHealingMachine)

    def pbXDPC(*_args)
      return TravelExpansionFramework.darkhorizon_xd_pc! if defined?(TravelExpansionFramework) &&
                                                            TravelExpansionFramework.respond_to?(:darkhorizon_xd_pc!)
      return pbPokeCenterPC if defined?(pbPokeCenterPC)
      return true
    end unless method_defined?(:pbXDPC)
  end
end

TravelExpansionFramework.log("[darkhorizon] compatibility shims loaded") if defined?(TravelExpansionFramework) &&
                                                                            TravelExpansionFramework.respond_to?(:log)
