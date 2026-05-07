module TravelExpansionFramework
  module_function

  def bushido_expansion_ids
    ids = []
    ids << BUSHIDO_EXPANSION_ID if const_defined?(:BUSHIDO_EXPANSION_ID)
    ids += BUSHIDO_LEGACY_EXPANSION_IDS if const_defined?(:BUSHIDO_LEGACY_EXPANSION_IDS)
    ids << "bushido"
    ids << "pokemon_bushido"
    return ids.uniq
  rescue
    return ["bushido", "pokemon_bushido"]
  end

  def bushido_active_now?(map_id = nil)
    return !active_project_expansion_id(bushido_expansion_ids, map_id).nil? if respond_to?(:active_project_expansion_id)
    marker = current_expansion_marker.to_s rescue ""
    return bushido_expansion_ids.include?(marker)
  rescue
    return false
  end

  def bushido_identifier(value)
    return value if value.is_a?(Symbol) || value.is_a?(Integer)
    text = value.to_s.strip.gsub(/\A:/, "")
    return nil if text.empty?
    return text.upcase.gsub(/[^A-Z0-9_]+/, "_").gsub(/\A_+|_+\z/, "").to_sym
  rescue
    return nil
  end

  def bushido_species(value)
    resolved = resolve_external_species(value, "bushido") if respond_to?(:resolve_external_species)
    return resolved if resolved
    identifier = bushido_identifier(value)
    data = GameData::Species.try_get(identifier) rescue nil
    return data.id if data && data.respond_to?(:id)
    return identifier
  rescue
    return bushido_identifier(value)
  end

  def bushido_item(value)
    identifier = bushido_identifier(value)
    resolved = ensure_external_item_registered("bushido", identifier) if identifier && respond_to?(:ensure_external_item_registered)
    return resolved if resolved
    data = GameData::Item.try_get(identifier) rescue nil
    return data.id if data && data.respond_to?(:id)
    return identifier
  rescue
    return bushido_identifier(value)
  end

  def bushido_safe_level(level)
    value = level.to_i
    value = 1 if value <= 0
    return value
  rescue
    return 1
  end

  def bushido_call_helper(method_name, *args)
    return Kernel.send(method_name, *args) if defined?(Kernel) && Kernel.respond_to?(method_name)
    return send(method_name, *args) if respond_to?(method_name, true)
    return nil
  rescue
    return nil
  end

  def bushido_root_path
    return project_root_path(BUSHIDO_EXPANSION_ID, "Bushido", ["Pokemon Bushido"]) if respond_to?(:project_root_path) &&
                                                                                       const_defined?(:BUSHIDO_EXPANSION_ID)
    ["C:/Games/Bushido", "C:/Games/Pokemon Bushido"].each { |path| return path if File.directory?(path) }
    return nil
  rescue
    return nil
  end

  def bushido_dialogue_data_path
    root = bushido_root_path
    return nil if root.to_s.empty?
    path = File.join(root, "Data", "Scripts", "023_PluginScripts", "007_BattleScript_Data.rb")
    return path if File.file?(path)
    return nil
  rescue
    return nil
  end

  def bushido_load_dialogue_data!
    return true if @bushido_dialogue_data_loaded
    path = bushido_dialogue_data_path
    return false if path.to_s.empty?
    load(path)
    @bushido_dialogue_data_loaded = true
    log("[bushido] loaded dialogue data constants from #{path}") if respond_to?(:log)
    return true
  rescue => e
    @bushido_dialogue_data_loaded = true
    log("[bushido] dialogue data load failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def bushido_legacy_dex_capacity
    max = 2048
    max = [max, PBSpecies.maxValue.to_i + 1].max if defined?(PBSpecies) && PBSpecies.respond_to?(:maxValue)
    return max
  rescue
    return 2048
  end

  class BushidoDexProxy
    include Enumerable

    def initialize(player, kind, values)
      @player = player
      @kind = kind
      @values = values.is_a?(Array) ? values : []
    end

    def [](index)
      species = species_index(index)
      if species && species >= 0 && species < @values.length
        cached = @values[species]
        return cached if cached
      end
      return pokedex_flag(species)
    rescue
      return false
    end

    def []=(index, value)
      species = species_index(index)
      if species && species >= 0
        @values[species] = value
        set_pokedex_flag(species) if value
      end
      return value
    rescue
      return value
    end

    def each
      limit = [@values.length, TravelExpansionFramework.bushido_legacy_dex_capacity].max
      i = 0
      while i < limit
        yield self[i]
        i += 1
      end
    end

    def length
      return [@values.length, TravelExpansionFramework.bushido_legacy_dex_capacity].max
    rescue
      return @values.length
    end
    alias size length

    def empty?
      return !any? { |value| value }
    rescue
      return true
    end

    def compact!
      @values.compact!
      return self
    rescue
      return self
    end

    def to_a
      array = []
      each_with_index { |value, index| array[index] = value }
      return array
    rescue
      return @values.clone
    end

    private

    def species_index(value)
      return value if value.is_a?(Integer)
      text = value.to_s
      return text.to_i if text[/\A\d+\z/]
      resolved = TravelExpansionFramework.bushido_species(value) if defined?(TravelExpansionFramework) &&
                                                                    TravelExpansionFramework.respond_to?(:bushido_species)
      return resolved if resolved.is_a?(Integer)
      return nil
    rescue
      return nil
    end

    def pokedex_flag(species)
      return false if !species || species <= 0 || !@player || !@player.respond_to?(:pokedex)
      dex = @player.pokedex
      return false if !dex
      method = (@kind == :owned) ? :owned? : :seen?
      return dex.send(method, species) if dex.respond_to?(method)
      return @player.send(method, species) if @player.respond_to?(method)
      return false
    rescue
      return false
    end

    def set_pokedex_flag(species)
      return false if !species || species <= 0 || !@player || !@player.respond_to?(:pokedex)
      dex = @player.pokedex
      return false if !dex
      method = (@kind == :owned) ? :set_owned : :set_seen
      if dex.respond_to?(method)
        begin
          dex.send(method, species, false)
        rescue ArgumentError
          dex.send(method, species)
        end
      end
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:record_dex_progress)
        TravelExpansionFramework.record_dex_progress(species, @kind == :owned, "bushido")
      end
      return true
    rescue
      return false
    end
  end
end

if defined?(PokemonTemp)
  class PokemonTemp
    def dialogueData
      @dialogueData = { :DIAL => false } if !@dialogueData.is_a?(Hash)
      return @dialogueData
    end

    def dialogueData=(value)
      @dialogueData = value.is_a?(Hash) ? value : { :DIAL => false }
      return @dialogueData
    end

    def dialogueDone
      @dialogueDone = {} if !@dialogueDone.is_a?(Hash)
      return @dialogueDone
    end

    def dialogueDone=(value)
      @dialogueDone = value.is_a?(Hash) ? value : {}
      return @dialogueDone
    end

    def dialogueInstances
      @dialogueInstances = {} if !@dialogueInstances.is_a?(Hash)
      return @dialogueInstances
    end

    def dialogueInstances=(value)
      @dialogueInstances = value.is_a?(Hash) ? value : {}
      return @dialogueInstances
    end

    def orderData
      @orderData = {} if !@orderData.is_a?(Hash)
      return @orderData
    end

    def orderData=(value)
      @orderData = value.is_a?(Hash) ? value : {}
      return @orderData
    end
  end
end

if defined?(Trainer)
  class Trainer
    def tef_bushido_legacy_dex_values(kind)
      ivar = (kind == :owned) ? :@tef_bushido_owned : :@tef_bushido_seen
      values = instance_variable_get(ivar)
      values = [] if !values.is_a?(Array)
      instance_variable_set(ivar, values)
      return values
    end

    def tef_bushido_legacy_default_value(value)
      return value.collect { |entry| entry.is_a?(Array) ? entry.clone : entry } if value.is_a?(Array)
      return value
    rescue
      return nil
    end

    def tef_bushido_legacy_array(ivar, default_value = nil)
      values = instance_variable_get(ivar)
      values = [] if !values.is_a?(Array)
      capacity = TravelExpansionFramework.bushido_legacy_dex_capacity if defined?(TravelExpansionFramework) &&
                                                                         TravelExpansionFramework.respond_to?(:bushido_legacy_dex_capacity)
      capacity ||= 2048
      while values.length <= capacity
        values << tef_bushido_legacy_default_value(default_value)
      end
      instance_variable_set(ivar, values)
      return values
    rescue
      values ||= []
      instance_variable_set(ivar, values)
      return values
    end

    def seen
      values = tef_bushido_legacy_dex_values(:seen)
      return TravelExpansionFramework::BushidoDexProxy.new(self, :seen, values) if defined?(TravelExpansionFramework::BushidoDexProxy)
      return values
    end

    def seen=(value)
      @tef_bushido_seen = value.is_a?(Array) ? value.clone : []
      return @tef_bushido_seen
    end

    def owned
      values = tef_bushido_legacy_dex_values(:owned)
      return TravelExpansionFramework::BushidoDexProxy.new(self, :owned, values) if defined?(TravelExpansionFramework::BushidoDexProxy)
      return values
    end

    def owned=(value)
      @tef_bushido_owned = value.is_a?(Array) ? value.clone : []
      return @tef_bushido_owned
    end

    def formseen
      values = tef_bushido_legacy_array(:@tef_bushido_formseen, [[], []])
      values.each_with_index { |value, index| values[index] = [[], []] if !value.is_a?(Array) }
      return values
    end

    def formseen=(value)
      @tef_bushido_formseen = value.is_a?(Array) ? value.clone : []
      return @tef_bushido_formseen
    end

    def formlastseen
      values = tef_bushido_legacy_array(:@tef_bushido_formlastseen, [])
      values.each_with_index { |value, index| values[index] = [] if !value.is_a?(Array) }
      return values
    end

    def formlastseen=(value)
      @tef_bushido_formlastseen = value.is_a?(Array) ? value.clone : []
      return @tef_bushido_formlastseen
    end

    def shadowcaught
      return tef_bushido_legacy_array(:@tef_bushido_shadowcaught, false)
    end

    def shadowcaught=(value)
      @tef_bushido_shadowcaught = value.is_a?(Array) ? value.clone : []
      return @tef_bushido_shadowcaught
    end
  end
end

module TrainerDialogue
  def self.ensure_storage!
    return false if !$PokemonTemp
    $PokemonTemp.dialogueData[:DIAL] = false if !$PokemonTemp.dialogueData.has_key?(:DIAL)
    return true
  rescue
    return false
  end

  def self.set(param, data)
    return false if !ensure_storage!
    key = param.to_s
    $PokemonTemp.dialogueData[:DIAL] = true
    $PokemonTemp.dialogueData[key] = data
    $PokemonTemp.dialogueDone[key] = 2
    base_key = key.split(",")[0].to_s
    $PokemonTemp.dialogueInstances[base_key] = 1 if !base_key.empty?
    return true
  rescue
    return false
  end

  def self.copy(param, to_copy)
    return false if !ensure_storage!
    return set(param, $PokemonTemp.dialogueData[to_copy.to_s])
  rescue
    return false
  end

  def self.resetAll
    return false if !$PokemonTemp
    $PokemonTemp.dialogueData = { :DIAL => false }
    $PokemonTemp.dialogueDone = {}
    $PokemonTemp.dialogueInstances = {}
    $PokemonTemp.orderData = {}
    return true
  rescue
    return false
  end

  def self.hasData?
    return false if !ensure_storage!
    return $PokemonTemp.dialogueData[:DIAL] ? true : false
  rescue
    return false
  end

  def self.get(param = nil)
    return false if !hasData?
    return $PokemonTemp.dialogueData[param.to_s] if param
    return $PokemonTemp.dialogueData
  rescue
    return false
  end

  def self.setDone(param)
    return false if !ensure_storage!
    key = param.to_s
    $PokemonTemp.dialogueDone[key] = 1 if !key.include?("rand")
    return true
  rescue
    return false
  end

  def self.setFinal
    return false if !ensure_storage!
    $PokemonTemp.dialogueDone.keys.each do |key|
      next if $PokemonTemp.dialogueDone[key] != 1
      $PokemonTemp.dialogueDone[key] = 0
      $PokemonTemp.dialogueData[key] = nil
    end
    return true
  rescue
    return false
  end

  def self.eval(parameter, _no_pri = false)
    return -1 if !hasData?
    key = parameter.to_s
    return -1 if !$PokemonTemp.dialogueDone[key]
    return -1 if [0, 1].include?($PokemonTemp.dialogueDone[key])
    data = $PokemonTemp.dialogueData[key]
    return 0 if data.is_a?(String)
    return 1 if data.is_a?(Hash)
    return 2 if data.is_a?(Proc)
    return 3 if data.is_a?(Array)
    return -1
  rescue
    return -1
  end

  def self.display(parameter, battle = nil, scene = nil, no_pri = false)
    key = parameter.to_s
    if $PokemonTemp && $PokemonTemp.dialogueInstances[key].is_a?(Numeric) && $PokemonTemp.dialogueInstances[key] > 1
      key = "#{key},#{$PokemonTemp.dialogueInstances[key]}"
    end
    data = get(key)
    return false if !data
    if data.is_a?(Proc) && battle
      data.call(battle)
    elsif data.is_a?(Array)
      data.each { |line| pbMessage(_INTL(line.to_s)) if defined?(pbMessage) }
    elsif data.is_a?(Hash) && data["text"]
      Array(data["text"]).each { |line| pbMessage(_INTL(line.to_s)) if defined?(pbMessage) }
    elsif data.is_a?(String)
      pbMessage(_INTL(data)) if defined?(pbMessage)
    end
    setDone(key)
    setInstance(parameter)
    return true
  rescue => e
    TravelExpansionFramework.log("[bushido] dialogue display skipped: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                   TravelExpansionFramework.respond_to?(:log)
    return false
  end

  def self.forceSet(parameter)
    return false if !ensure_storage!
    key = parameter.to_s
    $PokemonTemp.dialogueDone[key] = 1
    parts = key.split(",")
    $PokemonTemp.dialogueInstances[parts[0]] = parts[1].to_i + 1 if parts[0]
    return true
  rescue
    return false
  end

  def self.setInstance(parameter)
    return false if !$PokemonTemp
    key = parameter.to_s
    return true if key.include?("rand")
    no_increment = ["lowHP", "lowHPOpp", "halfHP", "halfHPOpp", "bigDamage", "bigDamageOpp",
                    "smlDamage", "smlDamageOpp", "attack", "attackOpp", "superEff", "superEffOpp",
                    "notEff", "notEffOpp"]
    $PokemonTemp.dialogueInstances[key] = 1 if !$PokemonTemp.dialogueInstances[key].is_a?(Numeric)
    $PokemonTemp.dialogueInstances[key] += 1 if !no_increment.include?(key)
    return true
  rescue
    return false
  end

  def self.changeTrainerSprite(_name, _scene, _delay = 2)
    return false
  end
end unless defined?(TrainerDialogue)

module BattleScripting
  def self.resolve_dialogue_constant(name)
    TravelExpansionFramework.bushido_load_dialogue_data! if defined?(TravelExpansionFramework) &&
                                                            TravelExpansionFramework.respond_to?(:bushido_load_dialogue_data!)
    return nil if !defined?(DialogueModule)
    key = name.is_a?(Symbol) ? name : name.to_s.gsub(/\A:/, "").to_sym
    return DialogueModule.const_get(key) if DialogueModule.const_defined?(key)
    return nil
  rescue => e
    TravelExpansionFramework.log("[bushido] dialogue constant #{name.inspect} unavailable: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                                       TravelExpansionFramework.respond_to?(:log)
    return nil
  end

  def self.set(param, data)
    return TrainerDialogue.set(param, data) if defined?(TrainerDialogue) && TrainerDialogue.respond_to?(:set)
    return false
  end

  def self.copy(param, data)
    return TrainerDialogue.copy(param, data) if defined?(TrainerDialogue) && TrainerDialogue.respond_to?(:copy)
    return false
  end

  def self.setInScript(param, name)
    value = resolve_dialogue_constant(name)
    return false if value.nil?
    return set(param, value)
  end

  def self.ensure_order_data!
    return {} if !$PokemonTemp
    $PokemonTemp.orderData ||= {}
    return $PokemonTemp.orderData
  rescue
    return {}
  end

  def self.hasOrderData?
    return ensure_order_data!["hasOrder"] ? true : false
  end

  def self.hasAceData?
    return ensure_order_data!["hasAce"] ? true : false
  end

  def self.getAceOf(id)
    value = ensure_order_data!["ace#{id}"]
    return value if value
    return -1
  end

  def self.getOrderOf(id)
    value = ensure_order_data!["order#{id}"]
    return value if value
    return []
  end

  def self.setTrainerOrder(*args)
    data = ensure_order_data!
    fail = false
    data["hasOrder"] = true
    args.each_with_index do |entry, index|
      if !entry.is_a?(Array) || entry.length != 6 || data["ace#{2 * index + 1}"]
        fail = true
        break
      end
      data["order#{2 * index + 1}"] = entry
    end
    data["hasOrder"] = false if fail
    return !fail
  rescue
    return false
  end

  def self.setTrainerAce(*args)
    data = ensure_order_data!
    fail = false
    data["hasAce"] = true
    args.each_with_index do |entry, index|
      if !entry.is_a?(Numeric) || data["order#{2 * index + 1}"]
        fail = true
        break
      end
      data["ace#{2 * index + 1}"] = [[entry.to_i, 0].max, 6].min
    end
    data["hasAce"] = false if fail
    return !fail
  rescue
    return false
  end
end unless defined?(BattleScripting)

if defined?(Interpreter) && !Interpreter.const_defined?(:BattleScripting)
  Interpreter.const_set(:BattleScripting, ::BattleScripting)
end

if defined?(Game_Interpreter) && !Game_Interpreter.const_defined?(:BattleScripting)
  Game_Interpreter.const_set(:BattleScripting, ::BattleScripting)
end

def vRI(item, quantity = 1)
  resolved = TravelExpansionFramework.bushido_item(item)
  return pbReceiveItem(resolved, quantity.to_i) if respond_to?(:pbReceiveItem, true)
  return Kernel.pbReceiveItem(resolved, quantity.to_i) if defined?(Kernel) && Kernel.respond_to?(:pbReceiveItem)
  return false
rescue
  return false
end

def vFI(item, quantity = 1)
  resolved = TravelExpansionFramework.bushido_item(item)
  return pbItemBall(resolved, quantity.to_i) if respond_to?(:pbItemBall, true)
  return Kernel.pbItemBall(resolved, quantity.to_i) if defined?(Kernel) && Kernel.respond_to?(:pbItemBall)
  return false
rescue
  return false
end

def vDI(item, quantity = 1)
  resolved = TravelExpansionFramework.bushido_item(item)
  return $PokemonBag.pbDeleteItem(resolved, quantity.to_i) if $PokemonBag && $PokemonBag.respond_to?(:pbDeleteItem)
  return false
rescue
  return false
end

def vAI(item, quantity = 1)
  resolved = TravelExpansionFramework.bushido_item(item)
  return $PokemonBag.pbStoreItem(resolved, quantity.to_i) if $PokemonBag && $PokemonBag.respond_to?(:pbStoreItem)
  return false
rescue
  return false
end

def vIQ(item)
  resolved = TravelExpansionFramework.bushido_item(item)
  return $PokemonBag.pbQuantity(resolved) if $PokemonBag && $PokemonBag.respond_to?(:pbQuantity)
  return 0
rescue
  return 0
end

def vHI(item)
  resolved = TravelExpansionFramework.bushido_item(item)
  return $PokemonBag.pbHasItem?(resolved) if $PokemonBag && $PokemonBag.respond_to?(:pbHasItem?)
  return false
rescue
  return false
end

def vGP(species, level)
  resolved = TravelExpansionFramework.bushido_species(species)
  level = TravelExpansionFramework.bushido_safe_level(level)
  return pbAddPokemon(resolved, level) if respond_to?(:pbAddPokemon, true)
  return false
rescue
  return false
end

def vAP(species, level)
  resolved = TravelExpansionFramework.bushido_species(species)
  level = TravelExpansionFramework.bushido_safe_level(level)
  return pbAddToParty(resolved, level) if respond_to?(:pbAddToParty, true)
  return pbAddPokemon(resolved, level) if respond_to?(:pbAddPokemon, true)
  return false
rescue
  return false
end

def vRP(species, level, from, nickname, gender = 0)
  resolved = TravelExpansionFramework.bushido_species(species)
  level = TravelExpansionFramework.bushido_safe_level(level)
  return pbAddForeignPokemon(resolved, level, from, nickname, gender) if respond_to?(:pbAddForeignPokemon, true)
  return pbAddPokemon(resolved, level) if respond_to?(:pbAddPokemon, true)
  return false
rescue
  return false
end

def vDP(index = 0)
  return pbRemovePokemonAt(index.to_i) if respond_to?(:pbRemovePokemonAt, true)
  return false
rescue
  return false
end

def vGPS(species, level)
  resolved = TravelExpansionFramework.bushido_species(species)
  level = TravelExpansionFramework.bushido_safe_level(level)
  return pbAddPokemonSilent(resolved, level) if respond_to?(:pbAddPokemonSilent, true)
  return pbAddPokemon(resolved, level) if respond_to?(:pbAddPokemon, true)
  return false
rescue
  return false
end

def vAPS(species, level)
  resolved = TravelExpansionFramework.bushido_species(species)
  level = TravelExpansionFramework.bushido_safe_level(level)
  return pbAddToPartySilent(resolved, level) if respond_to?(:pbAddToPartySilent, true)
  return pbAddToParty(resolved, level) if respond_to?(:pbAddToParty, true)
  return pbAddPokemonSilent(resolved, level) if respond_to?(:pbAddPokemonSilent, true)
  return false
rescue
  return false
end

def vHP(species)
  resolved = TravelExpansionFramework.bushido_species(species)
  return pbHasSpecies?(resolved) if respond_to?(:pbHasSpecies?, true)
  return $Trainer.has_species?(resolved) if $Trainer && $Trainer.respond_to?(:has_species?)
  return false
rescue
  return false
end

def vWB(species, level, result_variable = 0, can_escape = true, can_lose = false)
  resolved = TravelExpansionFramework.bushido_species(species)
  level = TravelExpansionFramework.bushido_safe_level(level)
  return pbWildBattle(resolved, level, result_variable.to_i, can_escape, can_lose) if respond_to?(:pbWildBattle, true)
  return Kernel.pbWildBattle(resolved, level) if defined?(Kernel) && Kernel.respond_to?(:pbWildBattle)
  return false
rescue
  return false
end

def vTB(trainer_type, trainer_name, end_speech = "...", double_battle = false, trainer_version = 0, can_lose = false, outcome_variable = 0)
  type = trainer_type.is_a?(Symbol) ? trainer_type : trainer_type.to_s.upcase.gsub(/[^A-Z0-9_]+/, "_").to_sym
  return pbTrainerBattle(type, trainer_name, end_speech, double_battle, trainer_version.to_i, can_lose, outcome_variable.to_i) if respond_to?(:pbTrainerBattle, true)
  return false
rescue
  return false
end

def vCry(species, volume = 80, pitch = 100)
  resolved = TravelExpansionFramework.bushido_species(species)
  return pbPlayCrySpecies(resolved, 0, volume, pitch) if respond_to?(:pbPlayCrySpecies, true)
  return pbSEPlay(pbCryFile(resolved), volume, pitch) if respond_to?(:pbCryFile, true) && respond_to?(:pbSEPlay, true)
  return true
rescue
  return true
end

def vSS(event_id, self_switch = "A")
  return pbSetSelfSwitch(event_id.to_i, self_switch.to_s, true) if respond_to?(:pbSetSelfSwitch, true)
  return false
rescue
  return false
end

def vSSF(event_id, self_switch = "A")
  return pbSetSelfSwitch(event_id.to_i, self_switch.to_s, false) if respond_to?(:pbSetSelfSwitch, true)
  return false
rescue
  return false
end

def vTSS(event_id = @event_id, self_switch = "A")
  key = [($game_map.map_id rescue 0), event_id.to_i, self_switch.to_s]
  $game_self_switches[key] = !$game_self_switches[key]
  $game_map.need_refresh = true if $game_map && $game_map.respond_to?(:need_refresh=)
  return true
rescue
  return false
end

def vTSSR(self_switch, min_event_id, max_event_id)
  min_event_id.to_i.upto(max_event_id.to_i) { |event_id| vTSS(event_id, self_switch) }
  return true
rescue
  return false
end

def vO(_outfit = 0)
  return true
end

def vG(_gender = 0)
  return true
end

def vTG
  return true
end

def vTRD(dex_index = 0)
  pbUnlockDex(dex_index.to_i) if respond_to?(:pbUnlockDex, true)
  return true
rescue
  return true
end

def vTPD
  $Trainer.pokedex = true if $Trainer && $Trainer.respond_to?(:pokedex=)
  return true
rescue
  return true
end

def vTRS
  $PokemonGlobal.runningShoes = true if $PokemonGlobal && $PokemonGlobal.respond_to?(:runningShoes=)
  return true
rescue
  return true
end

def vTPG
  $Trainer.pokegear = true if $Trainer && $Trainer.respond_to?(:pokegear=)
  return true
rescue
  return true
end

def vTGS(switch_id)
  id = switch_id.to_i
  return false if id <= 0 || !$game_switches
  $game_switches[id] = !$game_switches[id]
  $game_map.need_refresh = true if $game_map && $game_map.respond_to?(:need_refresh=)
  return true
rescue
  return false
end

[
  [:vReceiveItem, :vRI], [:vItemReceive, :vRI], [:vGI, :vRI], [:vGetItem, :vRI], [:vItemGet, :vRI],
  [:vFindItem, :vFI], [:vItemFind, :vFI], [:vItemBall, :vFI],
  [:vDeleteItem, :vDI], [:vItemDelete, :vDI], [:vRemoveItem, :vDI], [:vItemRemove, :vDI],
  [:vAddItem, :vAI], [:vAddItemSilent, :vAI], [:vItemAdd, :vAI], [:vItemSilent, :vAI],
  [:vItemQuantity, :vIQ], [:vQuantityItem, :vIQ], [:vHasItem, :vHI],
  [:vGivePokemon, :vGP], [:vAddPokemon, :vAP], [:vReceivePokemon, :vRP],
  [:vDeletePokemon, :vDP], [:vRemovePokemon, :vDP],
  [:vGivePokemonSilent, :vGPS], [:vAddPokemonSilent, :vAPS],
  [:vHasPokemon, :vHP], [:vHS, :vHP], [:vHasSpecies, :vHP],
  [:vWildBattle, :vWB], [:vTrainerBattle, :vTB],
  [:vPlayCry, :vCry], [:vPC, :vCry],
  [:vSST, :vSS], [:vSSt, :vSS], [:vSetSelfSwitch, :vSS], [:vSetSelfSwitchTrue, :vSS],
  [:vSSf, :vSSF], [:vSetSelfSwitchFalse, :vSSF],
  [:vtSS, :vTSS], [:vToggleSelfSwitch, :vTSS],
  [:vToggleSelfSwitchRange, :vTSSR], [:vRTSS, :vTSSR], [:vRangeToggleSelfSwitch, :vTSSR],
  [:vOutfit, :vO], [:vSO, :vO], [:vSetOutfit, :vO],
  [:vGender, :vG], [:vSG, :vG], [:vSetGender, :vG],
  [:vToggleGender, :vTG],
  [:vToggleRegionDex, :vTRD],
  [:vTogglePokedex, :vTPD], [:vTogglePokeDex, :vTPD],
  [:vToggleRunningShoes, :vTRS], [:vRS, :vTRS], [:vRunningShoes, :vTRS],
  [:vTogglePokegear, :vTPG], [:vTogglePokeGear, :vTPG],
  [:vtGS, :vTGS], [:vTS, :vTGS], [:vToggleGlobalSwitch, :vTGS], [:vToggleGameSwitch, :vTGS], [:vToggleSwitch, :vTGS]
].each do |alias_name, target_name|
  next if Object.private_method_defined?(alias_name) || Object.method_defined?(alias_name)
  Object.send(:define_method, alias_name) { |*args| send(target_name, *args) }
  Object.send(:private, alias_name)
end
