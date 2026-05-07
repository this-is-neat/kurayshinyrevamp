module TravelExpansionFramework
  module_function

  URANIUM_EXPANSION_ID = "pokemon_uranium"
  URANIUM_STARTER_NAMES = ["Orchynx", "Raptorch", "Eletux"].freeze
  URANIUM_STARTER_SPECIES = [:CSF_URANIUM_ORCHYNX, :CSF_URANIUM_RAPTORCH, :CSF_URANIUM_ELETUX].freeze
  URANIUM_STARTER_SPECIES_ALIASES = {
    :ORCHYNX  => :CSF_URANIUM_ORCHYNX,
    :RAPTORCH => :CSF_URANIUM_RAPTORCH,
    :ELETUX   => :CSF_URANIUM_ELETUX
  }.freeze
  URANIUM_PLAYER_NAME_FALLBACKS = {
    0 => "Vitor",
    1 => "Natalie",
    2 => "Pluto"
  }.freeze
  URANIUM_ROCKSMASH_SOFTLOCK_MAPS = [32, 33, 35, 36, 37].freeze
  URANIUM_TERRAIN_TAG_TRANSLATIONS = {
    4  => 15,  # Uranium Rock -> IF Rock
    6  => 3,   # Uranium Beach -> treat as sand-like ground
    15 => 4,   # Uranium Bridge -> IF Bridge
    16 => 16,  # Uranium Snow -> safe non-sliding neutral ground
    17 => 27,  # Uranium StillWater -> IF StillWater
    18 => 15,  # Uranium Volcano -> safe rock-like ground
    19 => 15,  # Uranium Nuclear -> safe rock-like ground for now
    20 => 0    # Uranium Shadow -> no terrain effect
  }.freeze
  URANIUM_ENCOUNTER_TYPE_MAP = {
    0  => :Land,
    1  => :Cave,
    2  => :Water,
    3  => :RockSmash,
    4  => :OldRod,
    5  => :GoodRod,
    6  => :SuperRod,
    7  => :HeadbuttLow,
    8  => :HeadbuttHigh,
    9  => :LandMorning,
    10 => :LandDay,
    11 => :LandNight,
    12 => :BugContest
  }.freeze
  URANIUM_ENCOUNTER_SLOT_CHANCES = {
    0  => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1],
    1  => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1],
    2  => [60, 30, 5, 4, 1],
    3  => [60, 30, 5, 4, 1],
    4  => [70, 30],
    5  => [60, 20, 20],
    6  => [40, 40, 15, 4, 1],
    7  => [30, 25, 20, 10, 5, 5, 4, 1],
    8  => [30, 25, 20, 10, 5, 5, 4, 1],
    9  => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1],
    10 => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1],
    11 => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1],
    12 => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  }.freeze

  class UraniumTerrainTagProxy
    def initialize(source)
      @source = source
    end

    def [](index)
      return TravelExpansionFramework.uranium_translate_terrain_tag(@source[index])
    rescue
      return TravelExpansionFramework.uranium_translate_terrain_tag(nil)
    end

    def []=(index, value)
      return if !@source.respond_to?(:[]=)
      @source[index] = value
    end

    def method_missing(name, *args, &block)
      return @source.public_send(name, *args, &block) if @source.respond_to?(name)
      super
    end

    def respond_to_missing?(name, include_private = false)
      return true if @source.respond_to?(name, include_private)
      super
    end
  end

  def uranium_expansion_id?(expansion_id = nil)
    expansion = expansion_id
    expansion = current_runtime_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_runtime_expansion_id)
    expansion = current_map_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_map_expansion_id)
    expansion = current_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_expansion_id)
    return expansion.to_s == URANIUM_EXPANSION_ID
  end

  def uranium_local_map_id(map_id = nil)
    current_map_id = map_id
    current_map_id = $game_map.map_id if current_map_id.nil? && $game_map
    current_map_id = integer(current_map_id, 0)
    return 0 if current_map_id <= 0
    return local_map_id_for(URANIUM_EXPANSION_ID, current_map_id) if respond_to?(:local_map_id_for)
    return current_map_id
  rescue
    return 0
  end

  def uranium_quiz_map?(map_id = nil)
    return uranium_local_map_id(map_id) == 50
  rescue
    return false
  end

  def uranium_external_data_root
    manifest = manifest_for(URANIUM_EXPANSION_ID) if respond_to?(:manifest_for)
    data_root = manifest[:external_data_root] if manifest.is_a?(Hash)
    return nil if data_root.to_s.empty?
    return data_root
  rescue
    return nil
  end

  def uranium_encounter_data
    @uranium_encounter_data ||= begin
      root = uranium_external_data_root
      if root.to_s.empty?
        {}
      else
        path = File.join(root, "encounters.dat")
        if !File.exist?(path)
          {}
        else
          Marshal.load(File.binread(path))
        end
      end
    rescue => e
      log("[pokemon_uranium] failed to load encounters.dat: #{e.class}: #{e.message}")
      {}
    end
    return @uranium_encounter_data
  end

  def uranium_translate_terrain_tag(tag)
    value = integer(tag, 0)
    return 0 if value <= 0
    return URANIUM_TERRAIN_TAG_TRANSLATIONS[value] || value
  rescue
    return 0
  end

  def uranium_wrap_terrain_tags(expansion_id, terrain_tags)
    return terrain_tags if !uranium_expansion_id?(expansion_id)
    return terrain_tags if terrain_tags.nil? || terrain_tags.is_a?(UraniumTerrainTagProxy)
    return UraniumTerrainTagProxy.new(terrain_tags)
  rescue
    return terrain_tags
  end

  def uranium_map?(map_id = nil)
    return uranium_expansion_id?(current_map_expansion_id(map_id))
  rescue
    return false
  end

  def uranium_resolve_foreign_species_number(foreign_number)
    value = integer(foreign_number, 0)
    return nil if value <= 0
    if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:compatibility_alias_target)
      canonical = CustomSpeciesFramework.compatibility_alias_target(value) rescue nil
      if canonical
        data = GameData::Species.try_get(canonical) rescue nil
        return data.species if data
        return canonical
      end
    end
    return nil
  rescue
    return nil
  end

  def uranium_build_encounter_table(map_id)
    local_map_id = uranium_local_map_id(map_id)
    raw_entry = uranium_encounter_data[local_map_id]
    return nil if !raw_entry.is_a?(Array) || raw_entry.length < 2
    densities = raw_entry[0].is_a?(Array) ? raw_entry[0] : []
    tables = raw_entry[1].is_a?(Array) ? raw_entry[1] : []
    step_chances = {}
    encounter_tables = {}
    tables.each_with_index do |entries, old_type|
      next if !entries.is_a?(Array) || entries.empty?
      encounter_type = URANIUM_ENCOUNTER_TYPE_MAP[old_type]
      next if encounter_type.nil?
      density = integer(densities[old_type], 0)
      slot_chances = URANIUM_ENCOUNTER_SLOT_CHANCES[old_type] || []
      converted = []
      entries.each_with_index do |entry, index|
        next if !entry.is_a?(Array) || entry.length < 3
        species = uranium_resolve_species(entry[0])
        if species.nil?
          log("[pokemon_uranium] skipped unresolved encounter species #{entry[0].inspect} on map #{local_map_id} type #{encounter_type}")
          next
        end
        weight = integer(slot_chances[index], 1)
        min_level = [integer(entry[1], 1), 1].max
        max_level = [integer(entry[2], min_level), min_level].max
        converted << [weight, species, min_level, max_level]
      end
      next if converted.empty?
      step_chances[encounter_type] = density if density > 0
      encounter_tables[encounter_type] = converted
    end
    return nil if encounter_tables.empty?
    return {
      :step_chances     => step_chances,
      :encounter_tables => encounter_tables
    }
  rescue => e
    log("[pokemon_uranium] encounter conversion failed for map #{map_id}: #{e.class}: #{e.message}")
    return nil
  end

  def uranium_rock_smash_softlocked?
    return false if !$PokemonGlobal
    return false if !$PokemonGlobal.respond_to?(:nuzlocke) || !$PokemonGlobal.respond_to?(:randomizer)
    return false if !$PokemonGlobal.nuzlocke || !$PokemonGlobal.randomizer
    return false if !$PokemonBag || !$PokemonBag.respond_to?(:pbQuantity)
    hm_item = :HM06
    hm_item = GameData::Item.get(:HM06).id if defined?(GameData::Item) && GameData::Item.exists?(:HM06)
    return false if $PokemonBag.pbQuantity(hm_item) <= 0 rescue false
    has_required_badge = if defined?(HIDDENMOVESCOUNTBADGES) && HIDDENMOVESCOUNTBADGES
      $Trainer && $Trainer.respond_to?(:numbadges) && $Trainer.numbadges >= 1
    else
      $Trainer && $Trainer.respond_to?(:badges) && $Trainer.badges && $Trainer.badges[1]
    end
    return false if !has_required_badge
    return false if !$PokemonGlobal.respond_to?(:nuzlockeMapState)
    return false if URANIUM_ROCKSMASH_SOFTLOCK_MAPS.any? { |i| integer($PokemonGlobal.nuzlockeMapState(i), 0) == 0 }
    move = :ROCKSMASH
    if defined?(GameData::Move) && GameData::Move.exists?(:ROCKSMASH)
      move = GameData::Move.get(:ROCKSMASH).id
    end
    if $Trainer && $Trainer.respond_to?(:party)
      $Trainer.party.each do |pkmn|
        next if !pkmn
        return false if pkmn.respond_to?(:knowsMove?) && pkmn.knowsMove?(move)
        return false if defined?(pbSpeciesCompatible?) && pbSpeciesCompatible?(pkmn.species, move) rescue false
      end
    end
    if defined?($PokemonStorage) && $PokemonStorage && $PokemonStorage.respond_to?(:maxBoxes)
      0.upto($PokemonStorage.maxBoxes - 1) do |box|
        0.upto($PokemonStorage.maxPokemon(box) - 1) do |slot|
          pkmn = $PokemonStorage[box, slot] rescue nil
          next if !pkmn
          return false if pkmn.respond_to?(:knowsMove?) && pkmn.knowsMove?(move)
          return false if defined?(pbSpeciesCompatible?) && pbSpeciesCompatible?(pkmn.species, move) rescue false
        end
      end
    end
    return true
  rescue => e
    log("[pokemon_uranium] rock smash softlock check failed: #{e.class}: #{e.message}")
    return false
  end

  def uranium_plain_text(text)
    result = text.to_s.dup
    result.gsub!(/\r/, "")
    result.gsub!(/<c[^>]*>/i, "")
    result.gsub!(/<c[^,\]\r\n]*/i, "")
    result.gsub!(/(^|[\s,])(?:[0-9a-f]{6,8})>/i, "\\1")
    result.gsub!(/\\c\[\d+\]/i, "")
    result.gsub!(/\\C\[\d+\]/i, "")
    result.gsub!(/[ \t]+\n/, "\n")
    result.gsub!(/\n[ \t]+/, "\n")
    result.gsub!(/[ \t]{2,}/, " ")
    result.strip!
    return result
  rescue
    return text.to_s
  end

  def uranium_sanitize_message_markup(text)
    result = text.to_s.dup
    result.gsub!(/\r/, "")
    result.gsub!(/<c[^>]*>/i, "")
    result.gsub!(/<c[^,\]\r\n]*/i, "")
    result.gsub!(/(^|[\s,])(?:[0-9a-f]{6,8})>/i, "\\1")
    result.gsub!(/\\c\[[^\]]+\]/i, "")
    return result
  rescue
    return text.to_s
  end

  def uranium_sanitize_commands(commands)
    return commands if !commands.is_a?(Array)
    return commands.map { |entry| uranium_plain_text(entry) }
  end

  def uranium_adjust_choice_variable(value)
    return value if !uranium_expansion_id?
    return value if !uranium_quiz_map?
    return value if !value.is_a?(Numeric)
    score_data = expansion_variable_value(URANIUM_EXPANSION_ID, 151)
    return value if !score_data.is_a?(Array) || score_data.empty?
    raw_index = integer(value, -1)
    adjusted_index = raw_index
    if raw_index == score_data.length && raw_index > 0
      adjusted_index = raw_index - 1
    elsif raw_index > score_data.length
      adjusted_index = score_data.length - 1
    end
    if adjusted_index != raw_index
      log("[pokemon_uranium] normalized quiz choice index #{raw_index} -> #{adjusted_index}")
    end
    return adjusted_index
  rescue => e
    log("[pokemon_uranium] choice normalization failed: #{e.class}: #{e.message}")
    return value
  end

  def uranium_resolve_species(species)
    if species.is_a?(Integer)
      canonical = uranium_resolve_foreign_species_number(species)
      return canonical if canonical
      return nil if uranium_expansion_id?
    end
    if species.is_a?(Symbol)
      canonical = URANIUM_STARTER_SPECIES_ALIASES[species] || species
      if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:compatibility_alias_target)
        aliased = CustomSpeciesFramework.compatibility_alias_target(canonical) rescue nil
        canonical = aliased if aliased
      end
      data = GameData::Species.try_get(canonical) rescue nil
      return data.species if data
      return canonical
    end
    data = GameData::Species.try_get(species) rescue nil
    return data.species if data
    return species
  end

  def uranium_record_shown_species(species, x = nil, y = nil)
    resolved = uranium_resolve_species(species)
    begin
      $Trainer.pokedex.set_seen(resolved) if $Trainer && $Trainer.respond_to?(:pokedex) && $Trainer.pokedex
    rescue
    end
    state = state_for(URANIUM_EXPANSION_ID)
    if state && state.respond_to?(:metadata) && state.metadata.is_a?(Hash)
      state.metadata["uranium_last_shown_species"] = resolved.to_s
      state.metadata["uranium_last_show_x"] = integer(x, 0)
      state.metadata["uranium_last_show_y"] = integer(y, 0)
    end
    return resolved
  rescue
    return species
  end

  def uranium_starter_index(value)
    index = integer(value, 0)
    index = 0 if index < 0
    index = index % URANIUM_STARTER_NAMES.length if index >= URANIUM_STARTER_NAMES.length
    return index
  rescue
    return 0
  end

  def uranium_starter_name(value)
    return URANIUM_STARTER_NAMES[uranium_starter_index(value)]
  rescue
    return URANIUM_STARTER_NAMES[0]
  end

  def uranium_starter_species(value)
    species = URANIUM_STARTER_SPECIES[uranium_starter_index(value)] || URANIUM_STARTER_SPECIES[0]
    resolved = uranium_resolve_species(species)
    return resolved
  rescue
    return :ORCHYNX
  end

  def uranium_record_selected_starter(value, theo = false)
    index = uranium_starter_index(value)
    starter_name = uranium_starter_name(index)
    starter_species = uranium_starter_species(index)
    begin
      $Trainer.pokedex.set_seen(starter_species) if $Trainer && $Trainer.respond_to?(:pokedex) && $Trainer.pokedex
    rescue
    end
    state = state_for(URANIUM_EXPANSION_ID)
    if state && state.respond_to?(:metadata) && state.metadata.is_a?(Hash)
      state.metadata["uranium_last_starter_index"] = index
      state.metadata["uranium_last_starter_name"] = starter_name
      state.metadata["uranium_last_starter_species"] = starter_species.to_s
      state.metadata["uranium_last_starter_for_theo"] = !!theo
    end
    return index
  rescue
    return uranium_starter_index(value)
  end

  def uranium_player_choice
    trainer = $Trainer rescue nil
    return integer(trainer.character_ID, 0) if trainer && trainer.respond_to?(:character_ID) && integer(trainer.character_ID, -1) >= 0
    gender = pbGet(VAR_TRAINER_GENDER) rescue nil
    return 1 if defined?(GENDER_FEMALE) && gender == GENDER_FEMALE
    return 0
  rescue
    return 0
  end

  def uranium_player_name_for(choice)
    fallback = URANIUM_PLAYER_NAME_FALLBACKS[integer(choice, 0)] || "Player"
    trainer = $Trainer rescue nil
    current_name = trainer.name.to_s.strip if trainer && trainer.respond_to?(:name)
    return fallback if current_name.nil? || current_name.empty? || current_name == "Unnamed"
    return current_name
  rescue
    return "Player"
  end

  def uranium_apply_gender_selection(choice = nil)
    selected = integer(choice.nil? ? uranium_player_choice : choice, 0)
    selected = 0 if selected < 0 || selected > 2
    if selected == 2
      selected = 0 if !GameData::Metadata.get_player(2) rescue true
    end
    pbChangePlayer(selected) if defined?(pbChangePlayer)
    trainer = $Trainer rescue nil
    gender_value = if selected == 1 && defined?(GENDER_FEMALE)
      GENDER_FEMALE
    elsif defined?(GENDER_MALE)
      GENDER_MALE
    else
      selected == 1 ? 0 : 1
    end
    pbSet(VAR_TRAINER_GENDER, gender_value) if defined?(pbSet) && defined?(VAR_TRAINER_GENDER)
    if trainer
      trainer.name = uranium_player_name_for(selected) if trainer.respond_to?(:name=)
    end
    state = state_for(URANIUM_EXPANSION_ID)
    if state && state.respond_to?(:metadata) && state.metadata.is_a?(Hash)
      state.metadata["uranium_gender_choice"] = selected
      state.metadata["uranium_gender_selected"] = true
      state.metadata["uranium_player_name"] = trainer.name.to_s if trainer && trainer.respond_to?(:name)
    end
    return selected
  rescue => e
    log("[pokemon_uranium] gender selection bridge failed: #{e.class}: #{e.message}")
    return 0
  end

  def uranium_handle_gender_selector
    selected = uranium_apply_gender_selection
    trainer = $Trainer rescue nil
    name = trainer.name.to_s if trainer && trainer.respond_to?(:name)
    name = uranium_player_name_for(selected) if name.to_s.strip.empty?
    uranium_message("I'd like to know your name.\nPlease tell me.")
    uranium_message("#{name}, are you ready?")
    uranium_message("Your journey --- your story --- is about to unfold.")
    uranium_message("The future is a blank slate. You and your Pokemon are going to fill it.")
    uranium_message("Let's go!")
    return selected
  rescue => e
    log("[pokemon_uranium] gender selector bridge failed: #{e.class}: #{e.message}")
    return 0
  end

  def uranium_message(text)
    message = text.to_s
    return if message.empty?
    if defined?(Kernel.pbMessage)
      Kernel.pbMessage(message)
    elsif respond_to?(:pbMessage)
      pbMessage(message)
    end
  rescue => e
    log("[pokemon_uranium] message bridge failed: #{e.class}: #{e.message}")
  end

  def uranium_handle_starter_selector(starter, theo = false)
    index = uranium_record_selected_starter(starter, theo)
    starter_name = uranium_starter_name(index)
    role_text = case index
    when 0 then "a calm, defensive start"
    when 1 then "an aggressive, high-pressure start"
    else "a flexible, balanced start"
    end
    if theo
      uranium_message("#{starter_name} feels like the right fit for Theo.\\wtnp[80]")
    else
      uranium_message("For #{role_text}, #{starter_name} feels like the right partner.\\wtnp[80]")
      uranium_message("#{starter_name} is ready to join your story in Tandor.\\wtnp[80]")
    end
    begin
      pbMEPlay("PU-PokemonObtained") if defined?(pbMEPlay)
    rescue => e
      log("[pokemon_uranium] starter fanfare failed: #{e.class}: #{e.message}")
    end
    return index
  rescue => e
    log("[pokemon_uranium] starter selector bridge failed: #{e.class}: #{e.message}")
    return uranium_starter_index(starter)
  end

  def uranium_randomizer_enabled?
    global = $PokemonGlobal rescue nil
    return false if global.nil?
    return !!global.randomizer if global.respond_to?(:randomizer)
    return false
  rescue
    return false
  end

  def uranium_skip_control_binding!
    state = state_for(URANIUM_EXPANSION_ID)
    if state && state.respond_to?(:metadata) && state.metadata.is_a?(Hash)
      state.metadata["uranium_control_binding_skipped"] = true
    end
    log("[pokemon_uranium] skipped ControlBindingScreen and continued intro")
    return true
  rescue => e
    log("[pokemon_uranium] control binding skip failed: #{e.class}: #{e.message}")
    return true
  end
end

class PokemonGlobalMetadata
  def randomizer
    return !!@randomizer
  end if !method_defined?(:randomizer)

  def randomizer=(value)
    @randomizer = !!value
  end if !method_defined?(:randomizer=)

  def nuzlocke
    return !!@nuzlocke
  end if !method_defined?(:nuzlocke)

  def nuzlocke=(value)
    @nuzlocke = !!value
  end if !method_defined?(:nuzlocke=)
end

class Player
  def pokedex=(value)
    self.has_pokedex = !!value if respond_to?(:has_pokedex=)
  end if !method_defined?(:pokedex=)

  def pokegear=(value)
    self.has_pokegear = !!value if respond_to?(:has_pokegear=)
  end if !method_defined?(:pokegear=)
end

class Pokemon
  def nuzlocke_heal
    if defined?($PokemonGlobal) && $PokemonGlobal &&
       $PokemonGlobal.respond_to?(:nuzlocke) && $PokemonGlobal.nuzlocke &&
       respond_to?(:fainted?) && fainted?
      heal_status if respond_to?(:heal_status)
      heal_PP if respond_to?(:heal_PP)
      return self
    end
    heal if respond_to?(:heal)
    return self
  end if !method_defined?(:nuzlocke_heal)
end

class Object
  if private_method_defined?(:pbMessage) || method_defined?(:pbMessage)
    alias tef_uranium_object_pbMessage pbMessage

    def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
      if TravelExpansionFramework.uranium_expansion_id?
        message = TravelExpansionFramework.uranium_sanitize_message_markup(message)
        commands = TravelExpansionFramework.uranium_sanitize_commands(commands)
      end
      return tef_uranium_object_pbMessage(message, commands, cmdIfCancel, skin, defaultCmd, &block)
    end

    private :pbMessage
  end

  if private_method_defined?(:pbShowCommands) || method_defined?(:pbShowCommands)
    alias tef_uranium_object_pbShowCommands pbShowCommands

    def pbShowCommands(msgwindow, commands = nil, cmdIfCancel = 0, defaultCmd = 0, x_offset = nil, y_offset = nil)
      if TravelExpansionFramework.uranium_expansion_id?
        commands = TravelExpansionFramework.uranium_sanitize_commands(commands)
      end
      return tef_uranium_object_pbShowCommands(msgwindow, commands, cmdIfCancel, defaultCmd, x_offset, y_offset)
    end

    private :pbShowCommands
  end
end

class << Kernel
  if method_defined?(:pbMessage) || private_method_defined?(:pbMessage)
    alias tef_uranium_singleton_pbMessage pbMessage

    def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
      if TravelExpansionFramework.uranium_expansion_id?
        message = TravelExpansionFramework.uranium_sanitize_message_markup(message)
        commands = TravelExpansionFramework.uranium_sanitize_commands(commands)
      end
      return tef_uranium_singleton_pbMessage(message, commands, cmdIfCancel, skin, defaultCmd, &block)
    end
  end

  if method_defined?(:pbShowCommands) || private_method_defined?(:pbShowCommands)
    alias tef_uranium_singleton_pbShowCommands pbShowCommands

    def pbShowCommands(msgwindow, commands = nil, cmdIfCancel = 0, defaultCmd = 0, x_offset = nil, y_offset = nil)
      if TravelExpansionFramework.uranium_expansion_id?
        commands = TravelExpansionFramework.uranium_sanitize_commands(commands)
      end
      return tef_uranium_singleton_pbShowCommands(msgwindow, commands, cmdIfCancel, defaultCmd, x_offset, y_offset)
    end
  end
end

class Game_Variables
  alias tef_uranium_original_get []

  def [](variable_id)
    value = tef_uranium_original_get(variable_id)
    if TravelExpansionFramework.uranium_expansion_id? && TravelExpansionFramework.integer(variable_id, 0) == 2
      return TravelExpansionFramework.uranium_adjust_choice_variable(value)
    end
    return value
  end
end

if !defined?(tef_uranium_pbShowPokemon_bridge)
  tef_uranium_pbShowPokemon_bridge = true

  def pbShowPokemon(species, x = nil, y = nil, *_args)
    return nil if !TravelExpansionFramework.uranium_expansion_id?
    TravelExpansionFramework.uranium_record_shown_species(species, x, y)
    return true
  end

  def pbHidePokemon(*_args)
    return nil if !TravelExpansionFramework.uranium_expansion_id?
    return true
  end
end

if !defined?(tef_uranium_runtime_bridge)
  tef_uranium_runtime_bridge = true

  def pbGenderSelector(*_args)
    return nil if !TravelExpansionFramework.uranium_expansion_id?
    return TravelExpansionFramework.uranium_handle_gender_selector
  end

  def pbDisposePokemon(*_args)
    return nil if !TravelExpansionFramework.uranium_expansion_id?
    animation = ($pokeani rescue nil)
    return true if animation.nil?
    begin
      10.times do
        Graphics.update if defined?(Graphics)
        Input.update if defined?(Input)
        animation.update if animation.respond_to?(:update)
        if animation.respond_to?(:opacity) && animation.respond_to?(:opacity=)
          animation.opacity = animation.opacity.to_f - 25.5
        end
      end
      if animation.respond_to?(:dispose) && !(animation.respond_to?(:disposed?) && animation.disposed?)
        animation.dispose
      end
    rescue => e
      TravelExpansionFramework.log("[pokemon_uranium] dispose pokemon bridge failed: #{e.class}: #{e.message}")
    ensure
      $pokeani = nil if defined?($pokeani)
    end
    return true
  end

  def pbUpdatePokemonInMap(*_args)
    return nil if !TravelExpansionFramework.uranium_expansion_id?
    animation = ($pokeani rescue nil)
    return nil if animation.nil?
    return nil if animation.respond_to?(:disposed?) && animation.disposed?
    animation.update if animation.respond_to?(:update)
    return true
  rescue => e
    TravelExpansionFramework.log("[pokemon_uranium] update pokemon bridge failed: #{e.class}: #{e.message}")
    return nil
  end

  def pbStarterSelector(starter, theo = false, *_args)
    return nil if !TravelExpansionFramework.uranium_expansion_id?
    return TravelExpansionFramework.uranium_handle_starter_selector(starter, theo)
  end
end

if !defined?(ControlBindingScene)
  class ControlBindingScene
    def initialize(*_args)
    end
  end
end

if !defined?(ControlBindingScreen)
  class ControlBindingScreen
    def initialize(*_args)
    end

    def pbStartScreen(*_args)
      return nil if !TravelExpansionFramework.uranium_expansion_id?
      TravelExpansionFramework.uranium_skip_control_binding!
      return true
    end
  end
end

def isRockSmashSoftlocked?
  return false if !TravelExpansionFramework.uranium_expansion_id?
  return TravelExpansionFramework.uranium_rock_smash_softlocked?
end

class PokemonEncounters
  alias tef_uranium_original_setup setup unless method_defined?(:tef_uranium_original_setup)

  def setup(map_ID)
    tef_uranium_original_setup(map_ID)
    return if !TravelExpansionFramework.uranium_map?(map_ID)
    converted = TravelExpansionFramework.uranium_build_encounter_table(map_ID)
    return if !converted
    @step_count ||= 0
    @step_chances ||= {}
    @encounter_tables ||= {}
    converted[:step_chances].each_pair { |type, value| @step_chances[type] = value }
    converted[:encounter_tables].each_pair { |type, entries| @encounter_tables[type] = entries }
    TravelExpansionFramework.log("[pokemon_uranium] loaded encounter bridge for map #{TravelExpansionFramework.uranium_local_map_id(map_ID)} (#{@encounter_tables.keys.join(', ')})")
  rescue => e
    TravelExpansionFramework.log("[pokemon_uranium] encounter setup bridge failed for #{map_ID}: #{e.class}: #{e.message}")
  end
end

class Game_Map
  alias tef_uranium_original_playerPassable? playerPassable? unless method_defined?(:tef_uranium_original_playerPassable?)
  alias tef_uranium_original_terrain_tag terrain_tag unless method_defined?(:tef_uranium_original_terrain_tag)

  def playerPassable?(x, y, d, self_event = nil)
    return tef_uranium_original_playerPassable?(x, y, d, self_event) if !TravelExpansionFramework.uranium_map?(@map_id)
    bit = (1 << (d / 2 - 1)) & 0x0f
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
      passage = @passages[tile_id]
      if terrain
        return true if $PokemonGlobal.surfing && terrain.can_surf && !terrain.waterfall
        return false if $PokemonGlobal.bicycle && terrain.must_walk
      end
      if !terrain || !terrain.ignore_passability
        return false if passage & bit != 0 || passage & 0x0f == 0x0f
        return true if @priorities[tile_id] == 0
      end
    end
    return true
  end

  def terrain_tag(x, y, countBridge = false)
    return tef_uranium_original_terrain_tag(x, y, countBridge) if !TravelExpansionFramework.uranium_map?(@map_id)
    if valid?(x, y)
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
        next if terrain.id == :None || terrain.ignore_passability
        return terrain
      end
    end
    return GameData::TerrainTag.get(:None)
  end
end
