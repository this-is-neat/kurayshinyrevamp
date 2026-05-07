module TravelExpansionFramework
  module_function

  SOLAR_ECLIPSE_TERRAIN_TAG_TRANSLATIONS = {
    15 => 4 # Essentials Bridge -> Infinite Fusion Bridge
  }.freeze unless const_defined?(:SOLAR_ECLIPSE_TERRAIN_TAG_TRANSLATIONS)

  class SolarEclipseTerrainTagProxy
    def initialize(source)
      @source = source
    end

    def [](index)
      return TravelExpansionFramework.solar_eclipse_translate_terrain_tag(@source[index])
    rescue
      return TravelExpansionFramework.solar_eclipse_translate_terrain_tag(nil)
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

  def solar_eclipse_expansion_ids
    ids = []
    ids << (defined?(SOLAR_ECLIPSE_EXPANSION_ID) ? SOLAR_ECLIPSE_EXPANSION_ID : "solar_eclipse")
    ids.concat(defined?(SOLAR_ECLIPSE_LEGACY_EXPANSION_IDS) ? SOLAR_ECLIPSE_LEGACY_EXPANSION_IDS : ["solareclipse"])
    return ids.compact.map(&:to_s).uniq
  rescue
    return ["solar_eclipse", "solareclipse"]
  end

  def solar_eclipse_active_now?(map_id = nil)
    runtime = current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    return true if solar_eclipse_expansion_ids.include?(runtime.to_s)
    if respond_to?(:active_project_expansion_id)
      return !active_project_expansion_id(solar_eclipse_expansion_ids, map_id).nil?
    end
    marker = current_expansion_marker.to_s if respond_to?(:current_expansion_marker)
    return solar_eclipse_expansion_ids.include?(marker.to_s)
  rescue
    return false
  end

  def solar_eclipse_translate_terrain_tag(tag)
    value = integer(tag, 0) if respond_to?(:integer)
    value = tag.to_i if value.nil?
    return 0 if value <= 0
    return SOLAR_ECLIPSE_TERRAIN_TAG_TRANSLATIONS[value] || value
  rescue
    return 0
  end

  def solar_eclipse_wrap_terrain_tags(expansion_id, terrain_tags)
    return terrain_tags if terrain_tags.nil?
    return terrain_tags if !solar_eclipse_expansion_ids.include?(expansion_id.to_s)
    return terrain_tags if terrain_tags.is_a?(SolarEclipseTerrainTagProxy)
    return SolarEclipseTerrainTagProxy.new(terrain_tags)
  rescue
    return terrain_tags
  end

  def set_bridge_height!(height = 2)
    return true if !defined?($PokemonGlobal) || !$PokemonGlobal
    value = integer(height, 2) if respond_to?(:integer)
    value = height.to_i if value.nil?
    value = 2 if value <= 0
    $PokemonGlobal.bridge = value if $PokemonGlobal.respond_to?(:bridge=)
    return true
  rescue => e
    log("[travel] bridge height fallback failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def clear_bridge_height!
    $PokemonGlobal.bridge = 0 if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:bridge=)
    return true
  rescue => e
    log("[travel] bridge clear fallback failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def solar_eclipse_map?(map_id = nil)
    current_map_id = map_id
    current_map_id = $game_map.map_id if current_map_id.nil? && defined?($game_map) && $game_map && $game_map.respond_to?(:map_id)
    return solar_eclipse_expansion_ids.include?(current_map_expansion_id(current_map_id).to_s) if respond_to?(:current_map_expansion_id)
    return solar_eclipse_active_now?(current_map_id)
  rescue
    return false
  end

  def solar_eclipse_bridge_tile?(map, x, y)
    return false if !map || !map.respond_to?(:valid?) || !map.valid?(x, y)
    data = map.respond_to?(:data) ? map.data : nil
    terrain_tags = map.respond_to?(:terrain_tags) ? map.terrain_tags : nil
    return false if !data || !terrain_tags
    [2, 1, 0].each do |layer|
      tile_id = data[x, y, layer] rescue nil
      next if tile_id.nil?
      tag_value = terrain_tags[tile_id] rescue nil
      tag_value = solar_eclipse_translate_terrain_tag(tag_value)
      terrain = GameData::TerrainTag.try_get(tag_value) if defined?(GameData) && defined?(GameData::TerrainTag)
      return true if terrain && terrain.respond_to?(:bridge) && terrain.bridge
    end
    return false
  rescue
    return false
  end

  def solar_eclipse_ensure_bridge_for_tile!(map, x, y)
    return false if !solar_eclipse_bridge_tile?(map, x, y)
    set_bridge_height!(2)
    return true
  rescue
    return false
  end

  SOLAR_ECLIPSE_FOLLOWER_EVENT_NAME = "FollowerPkmn" unless const_defined?(:SOLAR_ECLIPSE_FOLLOWER_EVENT_NAME)
  SOLAR_ECLIPSE_STORY_DEPENDENCY_NAMES = [
    "FollowerPkmn", "Giltbert", "Diana", "Lisbeth", "Abigail", "Aelia", "Lairus", "Sienna"
  ].freeze unless const_defined?(:SOLAR_ECLIPSE_STORY_DEPENDENCY_NAMES)

  def solar_eclipse_party_members
    trainer = ($Trainer rescue nil)
    trainer ||= ($player rescue nil)
    party = trainer.party if trainer && trainer.respond_to?(:party)
    return Array(party).compact
  rescue
    return []
  end

  def solar_eclipse_first_followable_pokemon
    party = solar_eclipse_party_members
    living = party.find do |pkmn|
      next false if pkmn.nil?
      next false if pkmn.respond_to?(:egg?) && pkmn.egg?
      hp = pkmn.hp if pkmn.respond_to?(:hp)
      hp.nil? || hp.to_i > 0
    end
    return living || party.find { |pkmn| pkmn && !(pkmn.respond_to?(:egg?) && pkmn.egg?) }
  rescue
    return nil
  end

  def solar_eclipse_character_bitmap_available?(logical_name)
    logical = logical_name.to_s.gsub("\\", "/").sub(/\A\/+/, "")
    return false if logical.empty?
    return true if defined?(pbResolveBitmap) && pbResolveBitmap("Graphics/Characters/#{logical}")
    return false
  rescue
    return false
  end

  def solar_eclipse_follower_charset_for_pokemon(pokemon)
    return anil_follower_charset_for_pokemon(pokemon) if respond_to?(:anil_follower_charset_for_pokemon)
    candidates = []
    if pokemon
      species = pokemon.species if pokemon.respond_to?(:species)
      form = pokemon.form if pokemon.respond_to?(:form)
      gender = pokemon.gender if pokemon.respond_to?(:gender)
      data = GameData::Species.get(species) rescue nil
      species_symbol = (data && data.respond_to?(:species)) ? data.species : species
      species_text = species_symbol.to_s
      id_number = (data && data.respond_to?(:id_number)) ? integer(data.id_number, 0) : 0
      form_value = integer(form, 0)
      gender_value = integer(gender, -1)
      candidates << "Followers/#{species_text}_#{form_value}_female" if form_value > 0 && gender_value == 1
      candidates << "Followers/#{species_text}_#{form_value}" if form_value > 0
      candidates << "Followers/#{species_text}_female" if gender_value == 1
      candidates << "Followers/#{species_text}"
      if id_number > 0
        id_text = format("%03d", id_number)
        candidates << "Followers/#{id_text}_#{form_value}" if form_value > 0
        candidates << "Followers/#{id_text}"
        candidates << "Overworld/#{id_text}_#{form_value}" if form_value > 0
        candidates << "Overworld/#{id_text}"
      end
    end
    candidates << "Followers/000"
    candidates << "000"
    chosen = candidates.compact.map(&:to_s).reject(&:empty?).uniq.find { |logical| solar_eclipse_character_bitmap_available?(logical) }
    return chosen || "Followers/000"
  rescue => e
    log("[solar_eclipse] follower charset resolution failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return "Followers/000"
  end

  def solar_eclipse_apply_event_charset!(event, logical_name, direction = 2, pattern = 0)
    return false if event.nil?
    logical = logical_name.to_s.gsub("\\", "/").sub(/\A\/+/, "")
    logical = "Followers/000" if logical.empty?
    event.character_name = logical if event.respond_to?(:character_name=)
    event.character_hue = 0 if event.respond_to?(:character_hue=)
    event.transparent = false if event.respond_to?(:transparent=)
    event.through = true if event.respond_to?(:through=)
    event.direction = integer(direction, 2) if event.respond_to?(:direction=)
    event.pattern = integer(pattern, 0) if event.respond_to?(:pattern=)
    event.walk_anime = true if event.respond_to?(:walk_anime=)
    event.set_opacity(255) if event.respond_to?(:set_opacity)
    event.instance_variable_set(:@opacity, 255) if event.instance_variable_defined?(:@opacity)
    event.instance_variable_set(:@tile_id, 0) if event.instance_variable_defined?(:@tile_id)
    event.instance_variable_set(:@tef_solar_eclipse_runtime_follower, true)
    event.calculate_bush_depth if event.respond_to?(:calculate_bush_depth)
    return true
  rescue => e
    log("[solar_eclipse] failed to apply follower charset #{logical_name.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def solar_eclipse_dependent_events
    return nil if !defined?($PokemonTemp) || !$PokemonTemp || !$PokemonTemp.respond_to?(:dependentEvents)
    return $PokemonTemp.dependentEvents
  rescue
    return nil
  end

  def solar_eclipse_following_get
    dependent = solar_eclipse_dependent_events
    return nil if dependent.nil?
    event = dependent.getEventByName(SOLAR_ECLIPSE_FOLLOWER_EVENT_NAME) rescue nil
    return event if event
    events = dependent.realEvents if dependent.respond_to?(:realEvents)
    return Array(events).compact.find { |candidate| candidate.instance_variable_defined?(:@tef_solar_eclipse_runtime_follower) }
  rescue
    return nil
  end

  def solar_eclipse_set_following_visible!(enabled)
    enabled = enabled ? true : false
    @solar_eclipse_following_enabled = enabled
    if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:follower_toggled=)
      $PokemonGlobal.follower_toggled = enabled
    end
    event = solar_eclipse_following_get
    if event
      event.transparent = !enabled if event.respond_to?(:transparent=)
      event.through = true if event.respond_to?(:through=)
      event.set_opacity(enabled ? 255 : 0) if event.respond_to?(:set_opacity)
      event.instance_variable_set(:@opacity, enabled ? 255 : 0) if event.instance_variable_defined?(:@opacity)
    end
    dependent = solar_eclipse_dependent_events
    if dependent && dependent.instance_variable_defined?(:@lastUpdate)
      current = dependent.instance_variable_get(:@lastUpdate)
      dependent.instance_variable_set(:@lastUpdate, current.to_i + 1)
    end
    return true
  rescue
    return true
  end

  def solar_eclipse_following_active?
    return false if !solar_eclipse_active_now?
    return false if solar_eclipse_following_get.nil?
    return false if solar_eclipse_first_followable_pokemon.nil?
    if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:follower_toggled)
      return $PokemonGlobal.follower_toggled ? true : false
    end
    return @solar_eclipse_following_enabled ? true : false
  rescue
    return false
  end

  def solar_eclipse_following_start!(event_id = nil, *_args)
    return true if !solar_eclipse_active_now?
    dependent = solar_eclipse_dependent_events
    source_event = nil
    numeric_event_id = integer(event_id, 0)
    if numeric_event_id > 0 && defined?($game_map) && $game_map && $game_map.respond_to?(:events)
      source_event = $game_map.events[numeric_event_id] rescue nil
    end
    pokemon = solar_eclipse_first_followable_pokemon
    return solar_eclipse_set_following_visible!(false) if pokemon.nil?
    charset = solar_eclipse_follower_charset_for_pokemon(pokemon)
    direction = ($game_player.direction rescue 2)
    if dependent && source_event
      begin
        dependent.removeEventByName(SOLAR_ECLIPSE_FOLLOWER_EVENT_NAME) if dependent.respond_to?(:removeEventByName)
      rescue
      end
      source_event.moveto($game_player.x, $game_player.y) if defined?($game_player) && $game_player && source_event.respond_to?(:moveto)
      solar_eclipse_apply_event_charset!(source_event, charset, direction, 0)
      if dependent.respond_to?(:addEvent)
        dependent.addEvent(source_event, SOLAR_ECLIPSE_FOLLOWER_EVENT_NAME, nil)
        follower = dependent.getEventByName(SOLAR_ECLIPSE_FOLLOWER_EVENT_NAME) rescue nil
        solar_eclipse_apply_event_charset!(follower, charset, direction, 0) if follower
      end
      @solar_eclipse_following_event_id = numeric_event_id
      solar_eclipse_set_following_visible!(true)
      log("[solar_eclipse] follower started from event #{numeric_event_id} using #{charset}") if respond_to?(:log)
      return true
    end
    follower = solar_eclipse_following_get
    solar_eclipse_apply_event_charset!(follower, charset, direction, 0) if follower
    solar_eclipse_set_following_visible!(!follower.nil?)
    return true
  rescue => e
    log("[solar_eclipse] follower start failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def solar_eclipse_following_stop!(*_args)
    dependent = solar_eclipse_dependent_events
    dependent.removeEventByName(SOLAR_ECLIPSE_FOLLOWER_EVENT_NAME) if dependent && dependent.respond_to?(:removeEventByName)
    solar_eclipse_set_following_visible!(false)
    return true
  rescue => e
    log("[solar_eclipse] follower stop failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def solar_eclipse_following_refresh!(*_args)
    return true if !solar_eclipse_active_now?
    follower = solar_eclipse_following_get
    return solar_eclipse_following_start!(@solar_eclipse_following_event_id || 0) if follower.nil?
    pokemon = solar_eclipse_first_followable_pokemon
    return solar_eclipse_set_following_visible!(false) if pokemon.nil?
    charset = solar_eclipse_follower_charset_for_pokemon(pokemon)
    solar_eclipse_apply_event_charset!(follower, charset, follower.direction, follower.pattern)
    desired = if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:follower_toggled)
                $PokemonGlobal.follower_toggled ? true : false
              else
                @solar_eclipse_following_enabled != false
              end
    solar_eclipse_set_following_visible!(desired)
    return true
  rescue => e
    log("[solar_eclipse] follower refresh failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def solar_eclipse_following_toggle!(forced = nil, *_args)
    return true if !solar_eclipse_active_now?
    if forced.nil?
      forced = !solar_eclipse_following_active?
    else
      forced = forced ? true : false
    end
    solar_eclipse_following_start!(@solar_eclipse_following_event_id || 0) if forced && solar_eclipse_following_get.nil?
    solar_eclipse_set_following_visible!(forced && !solar_eclipse_following_get.nil?)
    return true
  rescue => e
    log("[solar_eclipse] follower toggle failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def solar_eclipse_following_move_route!(commands = [], wait_complete = false, *_args)
    return true if !solar_eclipse_active_now?
    follower = solar_eclipse_following_get
    return true if follower.nil?
    route = pbMoveRoute(follower, Array(commands).compact, false) if defined?(pbMoveRoute)
    pbMapInterpreter.command_210 if wait_complete && defined?(pbMapInterpreter) && pbMapInterpreter && pbMapInterpreter.respond_to?(:command_210)
    return route || true
  rescue => e
    log("[solar_eclipse] follower move route failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def solar_eclipse_following_increase_time!
    return true if !defined?($PokemonGlobal) || !$PokemonGlobal
    if $PokemonGlobal.respond_to?(:time_taken)
      $PokemonGlobal.time_taken = $PokemonGlobal.time_taken.to_i + 1
    end
    return true
  rescue
    return true
  end

  def solar_eclipse_cleanup_foreign_dependencies!(map_id = nil)
    return true if solar_eclipse_map?(map_id)
    return true if !defined?($PokemonGlobal) || !$PokemonGlobal || !$PokemonGlobal.respond_to?(:dependentEvents)
    events = $PokemonGlobal.dependentEvents
    return true if !events.respond_to?(:length)
    dependent = solar_eclipse_dependent_events
    real_events = dependent.realEvents if dependent && dependent.respond_to?(:realEvents)
    removed = []
    (events.length - 1).downto(0) do |index|
      data = events[index]
      next if !data || !SOLAR_ECLIPSE_STORY_DEPENDENCY_NAMES.include?(data[8].to_s)
      events[index] = nil
      real_events[index] = nil if real_events.respond_to?(:[]=)
      removed << data[8].to_s
    end
    events.compact! if events.respond_to?(:compact!)
    real_events.compact! if real_events.respond_to?(:compact!)
    if dependent && dependent.instance_variable_defined?(:@lastUpdate) && !removed.empty?
      current = dependent.instance_variable_get(:@lastUpdate)
      dependent.instance_variable_set(:@lastUpdate, current.to_i + 1)
    end
    if !removed.empty? && respond_to?(:log)
      log("[solar_eclipse] cleared foreign dependent event(s) outside Solar: #{removed.uniq.join(', ')}")
    end
    return true
  rescue => e
    log("[solar_eclipse] foreign dependency cleanup failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def solar_eclipse_setting_id(name)
    return nil if !defined?(Settings) || !Settings.const_defined?(name)
    return Settings.const_get(name)
  rescue
    return nil
  end

  def solar_eclipse_variable_defaults
    return {
      :EXP_MODIFIER => 1.0,
      :MONEY_MODIFIER => 1.0,
      :CATCH_MODIFIER => 1.0,
      :PLAYER_IVS => -1,
      :OPPONENT_IVS => -1,
      :TRAINER_AI => -1,
      :PLAYER_DAMAGE_OUPUT => 0,
      :ENEMY_DAMAGE_OUPUT => 0,
      :OPPONENT_LEVEL_MOD => 0,
      :OPPONENT_EVS => 0,
      :FORCED_IVS => -1
    }
  end

  def solar_eclipse_source_variable_defaults
    return {
      62 => 1.0,   # EXP modifier
      46 => 1.0,   # Money modifier
      91 => 1.0,   # Catch modifier
      66 => -1,    # Player IVs
      205 => -1,   # Opponent IVs
      63 => -1,    # Trainer AI
      64 => 0,     # Player damage output
      65 => 0,     # Enemy damage output
      68 => 0,     # Opponent level modifier
      226 => 0     # Opponent EVs
    }
  end

  def solar_eclipse_switch_defaults
    return {
      :INVERSE_BATTLE => false,
      :KEEP_ITEMS => false,
      :LITTLE_CUP => false,
      :NO_EVS => false,
      :RISING_LEVEL => false,
      :AFFECTION_EFFECTS => false,
      :EXP_ALL => false,
      :FORCED_LEVELCAP => false,
      :HARDER_BOSSES => false,
      :BAN_RECOVERY => false,
      :BAN_REVIVAL => false,
      :BAN_XITEMS => false,
      :BOX_LINK => false,
      :FREE_DOCTORS => false,
      :DEX_ADVANCE => false,
      :PHONEAPP_EGG => false,
      :PHONEAPP_HABITAT => false,
      :PHONEAPP_NAV => false,
      :TRAINER_CARD => false,
      :DISABLE_SAVING => false
    }
  end

  def solar_eclipse_source_switch_defaults
    return {
      35 => false,  # Nuzlocke
      36 => false,  # Randomizer
      68 => false,  # Affection effects
      70 => false,  # Inverse battles
      86 => false,  # Recycle held items
      94 => false,  # Shared EXP
      101 => false, # Little Cup
      103 => false, # Level caps
      104 => false, # Boss effects
      105 => false, # Recovery item ban
      106 => false, # Revival item ban
      107 => false, # Battle item ban
      108 => false, # No EVs
      109 => false, # Box Link
      110 => false, # Passive doctors
      111 => false  # Rising level modifier
    }
  end

  def solar_eclipse_ensure_modifier_variables!
    return false if !defined?($game_variables) || !$game_variables || !defined?(Settings)
    solar_eclipse_variable_defaults.each do |name, default|
      variable_id = solar_eclipse_setting_id(name)
      next if !variable_id
      current = $game_variables[variable_id]
      if [:EXP_MODIFIER, :MONEY_MODIFIER, :CATCH_MODIFIER].include?(name)
        $game_variables[variable_id] = default if current.nil? || current.to_f <= 0
      else
        $game_variables[variable_id] = default if current.nil?
      end
    end
    custom_id = solar_eclipse_setting_id(:CUSTOMSETTINGS)
    if custom_id && !$game_variables[custom_id].is_a?(Hash)
      $game_variables[custom_id] = {}
    end
    solar_eclipse_source_variable_defaults.each do |variable_id, default|
      current = $game_variables[variable_id]
      if [62, 46, 91].include?(variable_id)
        $game_variables[variable_id] = default if current.nil? || current.to_f <= 0
      else
        $game_variables[variable_id] = default if current.nil?
      end
    end
    if defined?($game_switches) && $game_switches
      solar_eclipse_switch_defaults.each_key do |name|
        switch_id = solar_eclipse_setting_id(name)
        next if !switch_id
        $game_switches[switch_id] = false if $game_switches[switch_id].nil?
      end
      solar_eclipse_source_switch_defaults.each do |switch_id, default|
        $game_switches[switch_id] = default if $game_switches[switch_id].nil?
      end
    end
    return true
  rescue => e
    log("[solar_eclipse] modifier defaults failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def solar_eclipse_apply_safe_intro_settings!
    solar_eclipse_ensure_modifier_variables!
    if defined?($game_variables) && $game_variables && defined?(Settings)
      solar_eclipse_variable_defaults.each do |name, default|
        variable_id = solar_eclipse_setting_id(name)
        next if !variable_id
        $game_variables[variable_id] = default
      end
      solar_eclipse_source_variable_defaults.each do |variable_id, default|
        $game_variables[variable_id] = default
      end
      custom_id = solar_eclipse_setting_id(:CUSTOMSETTINGS)
      if custom_id
        $game_variables[custom_id] = {
          "source" => "travel_expansion_framework",
          "mode" => "host_defaults",
          "exp_modifier" => 1.0,
          "money_modifier" => 1.0,
          "catch_modifier" => 1.0,
          "player_ivs" => -1,
          "opponent_ivs" => -1,
          "trainer_ai" => -1,
          "player_damage_output" => 0,
          "enemy_damage_output" => 0,
          "opponent_level_mod" => 0,
          "opponent_evs" => 0
        }
      end
    end
    if defined?($game_switches) && $game_switches && defined?(Settings)
      solar_eclipse_switch_defaults.each do |name, default|
        switch_id = solar_eclipse_setting_id(name)
        next if !switch_id
        $game_switches[switch_id] = default
      end
      solar_eclipse_source_switch_defaults.each do |switch_id, default|
        $game_switches[switch_id] = default
      end
    end
    if defined?($PokemonGlobal) && $PokemonGlobal
      [:isNuzlocke, :qNuzlocke, :isRandomizer, :qRandomizer].each do |name|
        setter = "#{name}="
        $PokemonGlobal.send(setter, false) if $PokemonGlobal.respond_to?(setter)
      end
      [:nuzlockeData, :nuzlockeRules, :randomizerSettings].each do |name|
        setter = "#{name}="
        $PokemonGlobal.send(setter, nil) if $PokemonGlobal.respond_to?(setter)
      end
    end
    if defined?(EliteBattle) && EliteBattle.respond_to?(:set)
      begin
        EliteBattle.set(:nuzlocke, false)
      rescue
      end
      begin
        EliteBattle.set(:randomizer, false)
      rescue
      end
    end
    if defined?($Trainer) && $Trainer &&
       $Trainer.respond_to?(:difficulty) && $Trainer.respond_to?(:difficulty=)
      current = ($Trainer.difficulty rescue "")
      $Trainer.difficulty = "Standard" if current.nil? || current.to_s.strip.empty?
    end
    expansion = current_new_project_expansion_id if respond_to?(:current_new_project_expansion_id)
    expansion = SOLAR_ECLIPSE_EXPANSION_ID if expansion.to_s.empty? && defined?(SOLAR_ECLIPSE_EXPANSION_ID)
    expansion = "solar_eclipse" if expansion.to_s.empty?
    meta = new_project_metadata(expansion) if respond_to?(:new_project_metadata)
    if meta
      meta["solar_eclipse_intro_settings_normalized"] = true
      meta["solar_eclipse_intro_settings_mode"] = "host_defaults"
      meta["solar_eclipse_intro_settings_defaults"] = {
        "difficulty" => "Standard",
        "challenge_modes" => "off",
        "modifiers" => "standard"
      }
    end
    @solar_eclipse_log_once ||= {}
    if !@solar_eclipse_log_once[:safe_intro_settings]
      @solar_eclipse_log_once[:safe_intro_settings] = true
      log("[solar_eclipse] normalized intro settings to host-safe defaults") if respond_to?(:log)
    end
    return true
  rescue => e
    log("[solar_eclipse] intro settings normalization failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def solar_eclipse_current_outfit
    trainer = ($Trainer rescue nil)
    value = trainer.outfit if trainer && trainer.respond_to?(:outfit)
    value = 0 if value.nil?
    return integer(value, 0) if respond_to?(:integer)
    return value.to_i
  rescue
    return 0
  end

  def solar_eclipse_current_local_map_id(map_id = nil)
    current_map_id = map_id || ($game_map.map_id rescue nil)
    expansion = current_map_expansion_id(current_map_id) if respond_to?(:current_map_expansion_id)
    expansion ||= current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    expansion = "solar_eclipse" if expansion.to_s.empty?
    if respond_to?(:local_map_id_for)
      return local_map_id_for(expansion, current_map_id)
    end
    return integer(current_map_id, 0) if respond_to?(:integer)
    return current_map_id.to_i
  rescue
    return 0
  end

  def solar_eclipse_intro_trainer_card_review?
    return false if !solar_eclipse_active_now?
    local_map = solar_eclipse_current_local_map_id
    local_map = respond_to?(:integer) ? integer(local_map, 0) : local_map.to_i
    return false if local_map != 1
    return true
  rescue
    return false
  end

  def solar_eclipse_metadata
    expansion = current_new_project_expansion_id if respond_to?(:current_new_project_expansion_id)
    expansion = SOLAR_ECLIPSE_EXPANSION_ID if expansion.to_s.empty? && defined?(SOLAR_ECLIPSE_EXPANSION_ID)
    expansion = "solar_eclipse" if expansion.to_s.empty?
    return new_project_metadata(expansion) if respond_to?(:new_project_metadata)
    return nil
  rescue
    return nil
  end

  def solar_eclipse_intro_normalized?
    meta = solar_eclipse_metadata
    return true if meta && meta["solar_eclipse_intro_settings_normalized"]
    return true if meta && meta["solar_eclipse_intro_trainer_card_review_skipped"]
    return false
  rescue
    return false
  end

  def solar_eclipse_complete_intro!(map_id = nil)
    solar_eclipse_apply_safe_intro_settings!
    current_map_id = map_id || ($game_map.map_id rescue nil)
    current_map_id = respond_to?(:integer) ? integer(current_map_id, 0) : current_map_id.to_i
    if defined?($game_self_switches) && $game_self_switches && current_map_id > 0
      $game_self_switches[[current_map_id, 1, "A"]] = false
      $game_self_switches[[current_map_id, 1, "D"]] = true
      $game_self_switches[[current_map_id, 3, "A"]] = true
      $game_self_switches[[current_map_id, 5, "A"]] = true
    end
    if defined?($game_switches) && $game_switches
      $game_switches[198] = true
      $game_switches[50] = true
      $game_switches[223] = false
    end
    if defined?($game_map) && $game_map
      $game_map.need_refresh = true if $game_map.respond_to?(:need_refresh=)
    end
    if defined?($MapFactory) && $MapFactory.respond_to?(:hasMap?) && $MapFactory.hasMap?(current_map_id)
      $MapFactory.getMap(current_map_id, false).need_refresh = true rescue nil
    end
    meta = solar_eclipse_metadata
    if meta
      meta["solar_eclipse_intro_completed_by_framework"] = true
      meta["solar_eclipse_intro_completed_map_id"] = current_map_id
    end
    @solar_eclipse_log_once ||= {}
    if !@solar_eclipse_log_once[:intro_completed]
      @solar_eclipse_log_once[:intro_completed] = true
      log("[solar_eclipse] completed intro handoff and disabled looping autorun") if respond_to?(:log)
    end
    return true
  rescue => e
    log("[solar_eclipse] intro completion guard failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def solar_eclipse_intro_repeat_text?(message, event_id = nil, map_id = nil)
    return false if !solar_eclipse_active_now?(map_id)
    local_map = solar_eclipse_current_local_map_id(map_id)
    local_map = respond_to?(:integer) ? integer(local_map, 0) : local_map.to_i
    return false if local_map != 1
    return false if !event_id.nil? && event_id.to_i > 0 && event_id.to_i != 1
    text = message.to_s.downcase.gsub(/\s+/, " ")
    intro_review_seen = false
    current_map_id = map_id || ($game_map.map_id rescue nil)
    current_map_id = respond_to?(:integer) ? integer(current_map_id, 0) : current_map_id.to_i
    intro_review_seen = ($game_self_switches[[current_map_id, 1, "D"]] rescue false) if defined?($game_self_switches) && $game_self_switches
    normalized = solar_eclipse_intro_normalized? || intro_review_seen
    return true if text.include?("firstly, can you show me what picture") && normalized
    return true if text.include?("here is your trainer card") && normalized
    return true if text.include?("anything you'd like to review") && normalized
    return false
  rescue
    return false
  end

  def solar_eclipse_mark_trainer_card_review_skipped!
    solar_eclipse_apply_safe_intro_settings!
    expansion = current_new_project_expansion_id if respond_to?(:current_new_project_expansion_id)
    expansion = SOLAR_ECLIPSE_EXPANSION_ID if expansion.to_s.empty? && defined?(SOLAR_ECLIPSE_EXPANSION_ID)
    expansion = "solar_eclipse" if expansion.to_s.empty?
    meta = new_project_metadata(expansion) if respond_to?(:new_project_metadata)
    meta["solar_eclipse_intro_trainer_card_review_skipped"] = true if meta
    @solar_eclipse_log_once ||= {}
    if !@solar_eclipse_log_once[:trainer_card_review_skipped]
      @solar_eclipse_log_once[:trainer_card_review_skipped] = true
      log("[solar_eclipse] skipped imported intro Trainer Card review scene") if respond_to?(:log)
    end
    return true
  rescue => e
    log("[solar_eclipse] trainer card review skip failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def solar_eclipse_intro_trainer_card_script?(script)
    return false if !solar_eclipse_intro_trainer_card_review?
    text = script.to_s
    return true if text.include?("PokemonTrainerCardScreen.new")
    return true if text.include?("PokemonTrainerCard_Scene.new") && text.include?("pbStartScreen")
    return false
  rescue
    return false
  end

  def solar_eclipse_gender_pick_selection!(map_id = nil)
    solar_eclipse_ensure_modifier_variables!
    expansion = current_new_project_expansion_id(map_id) if respond_to?(:current_new_project_expansion_id)
    expansion = SOLAR_ECLIPSE_EXPANSION_ID if expansion.to_s.empty? && defined?(SOLAR_ECLIPSE_EXPANSION_ID)
    expansion = "solar_eclipse" if expansion.to_s.empty?
    outfit = solar_eclipse_current_outfit
    if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:outfit=) && ($Trainer.outfit rescue nil).nil?
      $Trainer.outfit = outfit
    end
    meta = new_project_metadata(expansion) if respond_to?(:new_project_metadata)
    if meta
      meta["intro_gender_pick_shown"] = true
      meta["intro_outfit"] = outfit
      meta["intro_selection_source"] = "host_player"
    end
    $PokemonTemp.begunNewGame = true if defined?($PokemonTemp) && $PokemonTemp && $PokemonTemp.respond_to?(:begunNewGame=)
    apply_new_project_gender_selection!(map_id) if respond_to?(:apply_new_project_gender_selection!)
    apply_host_player_visuals!(expansion) if respond_to?(:apply_host_player_visuals!)
    @solar_eclipse_log_once ||= {}
    if !@solar_eclipse_log_once[:gender_pick_selection]
      @solar_eclipse_log_once[:gender_pick_selection] = true
      log("[solar_eclipse] skipped imported GenderPickSelection UI; preserved host outfit #{outfit}") if respond_to?(:log)
    end
    return outfit
  rescue => e
    log("[solar_eclipse] GenderPickSelection fallback after #{e.class}: #{e.message}") if respond_to?(:log)
    return 0
  end

  def solar_eclipse_player_difficulty_value
    if respond_to?(:new_project_metadata)
      expansion = current_new_project_expansion_id if respond_to?(:current_new_project_expansion_id)
      expansion = SOLAR_ECLIPSE_EXPANSION_ID if expansion.to_s.empty? && defined?(SOLAR_ECLIPSE_EXPANSION_ID)
      expansion = "solar_eclipse" if expansion.to_s.empty?
      meta = new_project_metadata(expansion)
      return meta["solar_eclipse_difficulty"] if meta && meta.has_key?("solar_eclipse_difficulty")
    end
    return ""
  rescue
    return ""
  end

  def solar_eclipse_store_player_difficulty!(value)
    stored = value.nil? ? "" : value
    expansion = current_new_project_expansion_id if respond_to?(:current_new_project_expansion_id)
    expansion = SOLAR_ECLIPSE_EXPANSION_ID if expansion.to_s.empty? && defined?(SOLAR_ECLIPSE_EXPANSION_ID)
    expansion = "solar_eclipse" if expansion.to_s.empty?
    meta = new_project_metadata(expansion) if respond_to?(:new_project_metadata)
    if meta
      meta["solar_eclipse_difficulty"] = stored
      meta["difficulty_label"] = stored.to_s
    end
    log("[solar_eclipse] stored imported trainer difficulty #{stored.inspect}") if respond_to?(:log)
    return stored
  rescue => e
    log("[solar_eclipse] trainer difficulty fallback after #{e.class}: #{e.message}") if respond_to?(:log)
    return value.nil? ? "" : value
  end

  def solar_eclipse_player_wallpaper_value
    meta = solar_eclipse_metadata
    value = meta["solar_eclipse_wallpaper"] if meta
    return value.nil? ? 0 : value
  rescue
    return 0
  end

  def solar_eclipse_store_player_wallpaper!(value)
    stored = value.nil? ? 0 : value
    meta = solar_eclipse_metadata
    meta["solar_eclipse_wallpaper"] = stored if meta
    log("[solar_eclipse] stored imported trainer wallpaper #{stored.inspect}") if respond_to?(:log)
    return stored
  rescue => e
    log("[solar_eclipse] trainer wallpaper fallback after #{e.class}: #{e.message}") if respond_to?(:log)
    return value.nil? ? 0 : value
  end

  def solar_eclipse_replace_common_event_with_intro_defaults!(common_event)
    return false if !common_event || !common_event.respond_to?(:list)
    list = common_event.list
    return false if !list.respond_to?(:[]) || list.length < 2
    script_command = list[0]
    end_command = list[1]
    return false if !script_command.respond_to?(:code=) || !script_command.respond_to?(:parameters=)
    return false if !end_command.respond_to?(:code=) || !end_command.respond_to?(:parameters=)
    script_command.code = 355
    script_command.indent = 0 if script_command.respond_to?(:indent=)
    script_command.parameters = ["TravelExpansionFramework.solar_eclipse_apply_safe_intro_settings!"]
    end_command.code = 0
    end_command.indent = 0 if end_command.respond_to?(:indent=)
    end_command.parameters = []
    replacement = [script_command, end_command]
    if list.respond_to?(:replace)
      list.replace(replacement)
    elsif common_event.respond_to?(:list=)
      common_event.list = replacement
    else
      return false
    end
    return true
  end

  def solar_eclipse_patch_intro_difficulty_common_event!
    return false if @solar_eclipse_intro_difficulty_patched
    expansion = current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    expansion = SOLAR_ECLIPSE_EXPANSION_ID if expansion.to_s.empty? && defined?(SOLAR_ECLIPSE_EXPANSION_ID)
    expansion = "solar_eclipse" if expansion.to_s.empty?
    common_events = expansion_common_events(expansion) if respond_to?(:expansion_common_events)
    return false if !common_events.respond_to?(:[])
    patched = false
    [72, 74].each do |common_event_id|
      patched = solar_eclipse_replace_common_event_with_intro_defaults!(common_events[common_event_id]) || patched
    end
    solar_eclipse_apply_safe_intro_settings!
    @solar_eclipse_intro_difficulty_patched = true if patched
    log("[solar_eclipse] replaced intro difficulty/settings common events with host-safe defaults") if patched && respond_to?(:log)
    return patched
  rescue => e
    log("[solar_eclipse] IntroCustomDifficulty patch failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def solar_eclipse_choice_index(commands, pattern, fallback = nil)
    return fallback if !commands.respond_to?(:each_with_index)
    commands.each_with_index do |command, index|
      return index if command.to_s.downcase[pattern]
    end
    return fallback
  rescue
    return fallback
  end

  def solar_eclipse_command_text(commands)
    return "" if !commands.respond_to?(:map)
    return commands.map { |command| command.to_s.downcase }.join(" ")
  rescue
    return ""
  end

  def solar_eclipse_auto_intro_command_choice(commands)
    text = solar_eclipse_command_text(commands)
    return nil if text.empty?
    if text.include?("battle") && text.include?("parameters") &&
       text.include?("benefits") && text.include?("special") &&
       text.include?("ready")
      solar_eclipse_apply_safe_intro_settings!
      return solar_eclipse_choice_index(commands, /ready/, commands.length - 1)
    end
    if text.include?("appearance") && text.include?("difficulty") &&
       text.include?("additions") && text.include?("go")
      solar_eclipse_apply_safe_intro_settings!
      return solar_eclipse_choice_index(commands, /go/, commands.length - 1)
    end
    if text.include?("cancel") &&
       (text.include?("bag restrictions") ||
        text.include?("opponent skill") ||
        text.include?("damage modifiers") ||
        text.include?("opponent levels") ||
        text.include?("level caps") ||
        text.include?("forced iv") ||
        text.include?("opponent ev") ||
        text.include?("little cup") ||
        text.include?("exp modifiers") ||
        text.include?("money modifiers") ||
        text.include?("catch modifiers") ||
        text.include?("item benefits") ||
        text.include?("nuzlocke") ||
        text.include?("inverse battle") ||
        text.include?("randomizer") ||
        text.include?("starter"))
      solar_eclipse_apply_safe_intro_settings!
      return solar_eclipse_choice_index(commands, /cancel/, commands.length - 1)
    end
    return nil
  rescue => e
    log("[solar_eclipse] intro command auto-choice failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def solar_eclipse_auto_intro_message_choice(message, commands = nil)
    text = message.to_s.downcase.gsub(/\s+/, " ")
    command_choice = solar_eclipse_auto_intro_command_choice(commands)
    return command_choice if !command_choice.nil?
    return nil if commands.nil?
    if text.include?("would you like to look at more advanced settings")
      solar_eclipse_apply_safe_intro_settings!
      return solar_eclipse_choice_index(commands, /no/, 1)
    end
    if text.include?("is there anything you'd like to alter") && text.include?("ready")
      solar_eclipse_apply_safe_intro_settings!
      return 4
    end
    if text.include?("anything you'd like to review") && text.include?("go")
      solar_eclipse_apply_safe_intro_settings!
      return 4
    end
    if text.include?("what sort of battle rules") && text.include?("cancel")
      solar_eclipse_apply_safe_intro_settings!
      return 3
    end
    if text.include?("your current ranking would be") || text.include?("is everything in order")
      solar_eclipse_apply_safe_intro_settings!
      return solar_eclipse_choice_index(commands, /yes/, 0)
    end
    return nil
  rescue => e
    log("[solar_eclipse] intro message auto-choice failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def solar_eclipse_intro_message_choice_context(message)
    text = message.to_s.downcase.gsub(/\s+/, " ")
    return nil if text !~ /\\ch\[/
    return :advanced_settings_no if text.include?("would you like to look at more advanced settings")
    return :main_ready if text.include?("is there anything you'd like to alter") && text.include?("ready")
    return :review_go if text.include?("anything you'd like to review") && text.include?("go")
    return :battle_cancel if text.include?("what sort of battle rules") && text.include?("cancel")
    return :confirm_yes if text.include?("your current ranking would be") || text.include?("is everything in order")
    return nil
  rescue
    return nil
  end

  def solar_eclipse_prepare_intro_message_choice!(message)
    @solar_eclipse_pending_intro_choice = solar_eclipse_intro_message_choice_context(message)
    return @solar_eclipse_pending_intro_choice
  rescue
    @solar_eclipse_pending_intro_choice = nil
    return nil
  end

  def solar_eclipse_take_pending_intro_choice(commands)
    context = @solar_eclipse_pending_intro_choice
    @solar_eclipse_pending_intro_choice = nil
    return nil if !context
    solar_eclipse_apply_safe_intro_settings!
    case context
    when :advanced_settings_no
      return solar_eclipse_choice_index(commands, /no/, 1)
    when :main_ready
      return solar_eclipse_choice_index(commands, /ready/, commands.respond_to?(:length) ? commands.length - 1 : 4)
    when :review_go
      return solar_eclipse_choice_index(commands, /go/, commands.respond_to?(:length) ? commands.length - 1 : 4)
    when :battle_cancel
      return solar_eclipse_choice_index(commands, /cancel/, commands.respond_to?(:length) ? commands.length - 1 : 3)
    when :confirm_yes
      return solar_eclipse_choice_index(commands, /yes/, 0)
    end
    return nil
  rescue => e
    log("[solar_eclipse] pending intro choice failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def solar_eclipse_normalize_choice_cancel(commands, cmd_if_cancel, default_cmd)
    return [cmd_if_cancel, default_cmd] if !commands.respond_to?(:length)
    count = commands.length
    return [cmd_if_cancel, default_cmd] if count <= 0
    if cmd_if_cancel.is_a?(Integer) && cmd_if_cancel >= count
      cmd_if_cancel = count - 1
    end
    if default_cmd.is_a?(Integer) && default_cmd >= count
      default_cmd = count - 1
    end
    return [cmd_if_cancel, default_cmd]
  rescue
    return [cmd_if_cancel, default_cmd]
  end
end

if defined?(Settings)
  module Settings
    EXP_MODIFIER        = 62 unless const_defined?(:EXP_MODIFIER)
    MONEY_MODIFIER      = 46 unless const_defined?(:MONEY_MODIFIER)
    CATCH_MODIFIER      = 91 unless const_defined?(:CATCH_MODIFIER)
    PLAYER_IVS          = 66 unless const_defined?(:PLAYER_IVS)
    OPPONENT_IVS        = 205 unless const_defined?(:OPPONENT_IVS)
    TRAINER_AI          = 63 unless const_defined?(:TRAINER_AI)
    PLAYER_DAMAGE_OUPUT = 64 unless const_defined?(:PLAYER_DAMAGE_OUPUT)
    ENEMY_DAMAGE_OUPUT  = 65 unless const_defined?(:ENEMY_DAMAGE_OUPUT)
    OPPONENT_LEVEL_MOD  = 68 unless const_defined?(:OPPONENT_LEVEL_MOD)
    OPPONENT_EVS        = 226 unless const_defined?(:OPPONENT_EVS)
    CUSTOMSETTINGS      = 117 unless const_defined?(:CUSTOMSETTINGS)
    FORCED_IVS          = PLAYER_IVS unless const_defined?(:FORCED_IVS)

    INVERSE_BATTLE      = 70 unless const_defined?(:INVERSE_BATTLE)
    KEEP_ITEMS          = 86 unless const_defined?(:KEEP_ITEMS)
    LITTLE_CUP          = 101 unless const_defined?(:LITTLE_CUP)
    NO_EVS              = 108 unless const_defined?(:NO_EVS)
    RISING_LEVEL        = 111 unless const_defined?(:RISING_LEVEL)
    AFFECTION_EFFECTS   = 68 unless const_defined?(:AFFECTION_EFFECTS)
    EXP_ALL             = 94 unless const_defined?(:EXP_ALL)
    FORCED_LEVELCAP     = 103 unless const_defined?(:FORCED_LEVELCAP)
    HARDER_BOSSES       = 104 unless const_defined?(:HARDER_BOSSES)
    BAN_RECOVERY        = 105 unless const_defined?(:BAN_RECOVERY)
    BAN_REVIVAL         = 106 unless const_defined?(:BAN_REVIVAL)
    BAN_XITEMS          = 107 unless const_defined?(:BAN_XITEMS)
    BOX_LINK            = 109 unless const_defined?(:BOX_LINK)
    FREE_DOCTORS        = 110 unless const_defined?(:FREE_DOCTORS)
    DEX_ADVANCE         = 37_955 unless const_defined?(:DEX_ADVANCE)
    PHONEAPP_EGG        = 37_956 unless const_defined?(:PHONEAPP_EGG)
    PHONEAPP_HABITAT    = 37_957 unless const_defined?(:PHONEAPP_HABITAT)
    PHONEAPP_NAV        = 37_958 unless const_defined?(:PHONEAPP_NAV)
    TRAINER_CARD        = 50 unless const_defined?(:TRAINER_CARD)
    DISABLE_SAVING      = 37_960 unless const_defined?(:DISABLE_SAVING)

    USE_CURRENT_REGION_DEX = false unless const_defined?(:USE_CURRENT_REGION_DEX)
    DEXES_WITH_OFFSETS     = [] unless const_defined?(:DEXES_WITH_OFFSETS)
    DEX_SHOWS_ALL_FORMS    = false unless const_defined?(:DEX_SHOWS_ALL_FORMS)
    REGION_MAP_EXTRAS      = [] unless const_defined?(:REGION_MAP_EXTRAS)
    NEW_BERRY_PLANTS       = false unless const_defined?(:NEW_BERRY_PLANTS)
  end
end

if !defined?(Keys)
  module Keys
  end
end

if defined?(Keys)
  module Keys
    TEF_SOLAR_ECLIPSE_KEY_CODES = {
      "Backspace" => 0x08,
      "Tab" => 0x09,
      "Enter" => 0x0D,
      "Shift" => 0x10,
      "Ctrl" => 0x11,
      "Alt" => 0x12,
      "Esc" => 0x1B,
      "Space" => 0x20,
      "Page Up" => 0x21,
      "Page Down" => 0x22,
      "End" => 0x23,
      "Home" => 0x24,
      "Left" => 0x25,
      "Up" => 0x26,
      "Right" => 0x27,
      "Down" => 0x28,
      "A" => 0x41,
      "B" => 0x42,
      "C" => 0x43,
      "D" => 0x44,
      "I" => 0x49,
      "J" => 0x4A,
      "K" => 0x4B,
      "L" => 0x4C,
      "Q" => 0x51,
      "S" => 0x53,
      "X" => 0x58,
      "Z" => 0x5A
    } unless const_defined?(:TEF_SOLAR_ECLIPSE_KEY_CODES)

    def self.key_code(key_name)
      return key_name if key_name.is_a?(Integer)
      key = key_name.to_s
      return TEF_SOLAR_ECLIPSE_KEY_CODES[key] || TEF_SOLAR_ECLIPSE_KEY_CODES[key.upcase] || 0
    rescue
      return 0
    end unless respond_to?(:key_code)

    def self.key_name(key_code)
      code = key_code.to_i
      found = TEF_SOLAR_ECLIPSE_KEY_CODES.find { |_name, value| value == code }
      return found[0] if found
      return code.to_s
    rescue
      return ""
    end unless respond_to?(:key_name)
  end
end

if !defined?(ControlConfig) && defined?(Keys)
  class ControlConfig
    attr_reader :control_action
    attr_accessor :key_code

    def initialize(control_action, default_key)
      @control_action = control_action.to_s
      @key_code = Keys.respond_to?(:key_code) ? Keys.key_code(default_key) : default_key.to_i
    end

    def key_name
      return Keys.key_name(@key_code) if defined?(Keys) && Keys.respond_to?(:key_name)
      return @key_code.to_s
    rescue
      return ""
    end
  end
end

if defined?(PokemonSystem)
  class PokemonSystem
    TEF_SOLAR_ECLIPSE_SYSTEM_DEFAULTS = {
      :daytone => 0,
      :autoheal => 0,
      :autosave => 0,
      :measurements => 0
    } unless const_defined?(:TEF_SOLAR_ECLIPSE_SYSTEM_DEFAULTS)

    TEF_SOLAR_ECLIPSE_DEFAULT_CONTROL_CODES = {
      "Down" => [0x28, 0x4B],
      "Left" => [0x25, 0x4A],
      "Right" => [0x27, 0x4C],
      "Up" => [0x26, 0x49],
      "Action" => [0x43, 0x0D, 0x20],
      "Cancel" => [0x58, 0x1B],
      "Menu" => [0x5A, 0x10],
      "Scroll Up" => [0x41],
      "Scroll Down" => [0x53],
      "Ready Menu" => [0x44],
      "Quick Save" => [0x51],
      "Speed-Up" => [0x12]
    } unless const_defined?(:TEF_SOLAR_ECLIPSE_DEFAULT_CONTROL_CODES)

    def tef_solar_eclipse_system_options
      @tef_solar_eclipse_system_options = {} if !instance_variable_defined?(:@tef_solar_eclipse_system_options) ||
                                                !@tef_solar_eclipse_system_options.is_a?(Hash)
      return @tef_solar_eclipse_system_options
    rescue
      return {}
    end

    TEF_SOLAR_ECLIPSE_SYSTEM_DEFAULTS.each do |option_name, default_value|
      define_method(option_name) do
        begin
          options = tef_solar_eclipse_system_options
          value = options.has_key?(option_name) ? options[option_name] : default_value
          value.nil? ? default_value : value
        rescue
          default_value
        end
      end unless method_defined?(option_name)

      define_method("#{option_name}=") do |value|
        begin
          stored = value.nil? ? default_value : value
          tef_solar_eclipse_system_options[option_name] = stored
          stored
        rescue
          value.nil? ? default_value : value
        end
      end unless method_defined?("#{option_name}=")
    end

    def game_controls
      if instance_variable_defined?(:@game_controls) && @game_controls.respond_to?(:map)
        return @game_controls
      end
      if defined?(Keys) && Keys.respond_to?(:default_controls)
        @game_controls = Keys.default_controls
      elsif defined?(ControlConfig)
        @game_controls = []
        TEF_SOLAR_ECLIPSE_DEFAULT_CONTROL_CODES.each do |action, codes|
          Array(codes).each do |code|
            @game_controls << ControlConfig.new(action, code)
          end
        end
      else
        @game_controls = []
      end
      return @game_controls
    rescue
      return []
    end unless method_defined?(:game_controls)

    def game_controls=(value)
      if value.nil?
        remove_instance_variable(:@game_controls) if instance_variable_defined?(:@game_controls)
      else
        @game_controls = value
      end
      return game_controls
    rescue
      @game_controls = []
      return @game_controls
    end unless method_defined?(:game_controls=)

    def game_control_code(action)
      name = action.to_s
      controls = game_controls
      codes = []
      if controls.respond_to?(:each)
        controls.each do |control|
          control_name = if control.respond_to?(:control_action)
                           control.control_action
                         elsif control.respond_to?(:[])
                           control[:control_action] rescue nil
                         end
          next if control_name.to_s != name
          code = control.respond_to?(:key_code) ? control.key_code : nil
          code = control[:key_code] rescue code if code.nil? && control.respond_to?(:[])
          codes << code.to_i if !code.nil? && code.to_i > 0
        end
      end
      codes = TEF_SOLAR_ECLIPSE_DEFAULT_CONTROL_CODES[name] if codes.empty?
      return Array(codes).compact
    rescue
      return Array(TEF_SOLAR_ECLIPSE_DEFAULT_CONTROL_CODES[action.to_s]).compact
    end unless method_defined?(:game_control_code)
  end
end

module Kernel
  def self.pbBridgeOn(height = 2, *_args)
    return TravelExpansionFramework.set_bridge_height!(height) if defined?(TravelExpansionFramework) &&
                                                                  TravelExpansionFramework.respond_to?(:set_bridge_height!)
    $PokemonGlobal.bridge = height if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:bridge=)
    return true
  rescue
    return true
  end

  def self.pbBridgeOff(*_args)
    return TravelExpansionFramework.clear_bridge_height! if defined?(TravelExpansionFramework) &&
                                                            TravelExpansionFramework.respond_to?(:clear_bridge_height!)
    $PokemonGlobal.bridge = 0 if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:bridge=)
    return true
  rescue
    return true
  end
end

def pbBridgeOn(height = 2, *args)
  return Kernel.pbBridgeOn(height, *args) if defined?(Kernel) && Kernel.respond_to?(:pbBridgeOn)
  return TravelExpansionFramework.set_bridge_height!(height) if defined?(TravelExpansionFramework) &&
                                                                TravelExpansionFramework.respond_to?(:set_bridge_height!)
  return true
end

def pbBridgeOff(*args)
  return Kernel.pbBridgeOff(*args) if defined?(Kernel) && Kernel.respond_to?(:pbBridgeOff)
  return TravelExpansionFramework.clear_bridge_height! if defined?(TravelExpansionFramework) &&
                                                          TravelExpansionFramework.respond_to?(:clear_bridge_height!)
  return true
end

if !defined?(FollowingPkmn)
  module FollowingPkmn; end
end

module FollowingPkmn
  FOLLOWER_COMMON_EVENT = nil unless const_defined?(:FOLLOWER_COMMON_EVENT)
  ANIMATION_COME_OUT = 30 unless const_defined?(:ANIMATION_COME_OUT)
  ANIMATION_COME_IN = 29 unless const_defined?(:ANIMATION_COME_IN)
  ANIMATION_EMOTE_HEART = 9 unless const_defined?(:ANIMATION_EMOTE_HEART)
  ANIMATION_EMOTE_MUSIC = 12 unless const_defined?(:ANIMATION_EMOTE_MUSIC)
  ANIMATION_EMOTE_SMILE = 11 unless const_defined?(:ANIMATION_EMOTE_SMILE)
  ANIMATION_EMOTE_HAPPY = 10 unless const_defined?(:ANIMATION_EMOTE_HAPPY)
  ANIMATION_EMOTE_ELIPSES = 13 unless const_defined?(:ANIMATION_EMOTE_ELIPSES)
  ANIMATION_EMOTE_SAD = 14 unless const_defined?(:ANIMATION_EMOTE_SAD)
  ANIMATION_EMOTE_ANGRY = 15 unless const_defined?(:ANIMATION_EMOTE_ANGRY)
  ANIMATION_EMOTE_POISON = 17 unless const_defined?(:ANIMATION_EMOTE_POISON)
  ANIMATION_EMOTE_EXCLAIM = 3 unless const_defined?(:ANIMATION_EMOTE_EXCLAIM)
  FRIENDSHIP_TIME_TAKEN = 125 unless const_defined?(:FRIENDSHIP_TIME_TAKEN)
  ITEM_TIME_TAKEN = 375 unless const_defined?(:ITEM_TIME_TAKEN)
  ALWAYS_ANIMATE = true unless const_defined?(:ALWAYS_ANIMATE)
  ALWAYS_FACE_PLAYER = false unless const_defined?(:ALWAYS_FACE_PLAYER)
  IMPASSABLE_FOLLOWER = false unless const_defined?(:IMPASSABLE_FOLLOWER)
  SLIDE_INTO_BATTLE = false unless const_defined?(:SLIDE_INTO_BATTLE)
end

class << FollowingPkmn
  alias tef_solar_eclipse_original_active? active? if method_defined?(:active?) &&
                                                      !method_defined?(:tef_solar_eclipse_original_active?)
  alias tef_solar_eclipse_original_can_check? can_check? if method_defined?(:can_check?) &&
                                                            !method_defined?(:tef_solar_eclipse_original_can_check?)
  alias tef_solar_eclipse_original_get get if method_defined?(:get) &&
                                              !method_defined?(:tef_solar_eclipse_original_get)
  alias tef_solar_eclipse_original_refresh refresh if method_defined?(:refresh) &&
                                                      !method_defined?(:tef_solar_eclipse_original_refresh)
  alias tef_solar_eclipse_original_refresh_internal refresh_internal if method_defined?(:refresh_internal) &&
                                                                        !method_defined?(:tef_solar_eclipse_original_refresh_internal)
  alias tef_solar_eclipse_original_start_following start_following if method_defined?(:start_following) &&
                                                                      !method_defined?(:tef_solar_eclipse_original_start_following)
  alias tef_solar_eclipse_original_stop_following stop_following if method_defined?(:stop_following) &&
                                                                    !method_defined?(:tef_solar_eclipse_original_stop_following)
  alias tef_solar_eclipse_original_toggle toggle if method_defined?(:toggle) &&
                                                    !method_defined?(:tef_solar_eclipse_original_toggle)
  alias tef_solar_eclipse_original_toggle_on toggle_on if method_defined?(:toggle_on) &&
                                                          !method_defined?(:tef_solar_eclipse_original_toggle_on)
  alias tef_solar_eclipse_original_toggle_off toggle_off if method_defined?(:toggle_off) &&
                                                            !method_defined?(:tef_solar_eclipse_original_toggle_off)
  alias tef_solar_eclipse_original_move_route move_route if method_defined?(:move_route) &&
                                                            !method_defined?(:tef_solar_eclipse_original_move_route)
  alias tef_solar_eclipse_original_talk talk if method_defined?(:talk) &&
                                                !method_defined?(:tef_solar_eclipse_original_talk)
  alias tef_solar_eclipse_original_animation animation if method_defined?(:animation) &&
                                                          !method_defined?(:tef_solar_eclipse_original_animation)
  alias tef_solar_eclipse_original_item item if method_defined?(:item) &&
                                                !method_defined?(:tef_solar_eclipse_original_item)
  alias tef_solar_eclipse_original_increase_time increase_time if method_defined?(:increase_time) &&
                                                                  !method_defined?(:tef_solar_eclipse_original_increase_time)

  def tef_solar_eclipse_active_context?
    return defined?(TravelExpansionFramework) &&
           TravelExpansionFramework.respond_to?(:solar_eclipse_active_now?) &&
           TravelExpansionFramework.solar_eclipse_active_now?
  rescue
    return false
  end

  def active?
    return TravelExpansionFramework.solar_eclipse_following_active? if tef_solar_eclipse_active_context? &&
                                                                      TravelExpansionFramework.respond_to?(:solar_eclipse_following_active?)
    return tef_solar_eclipse_original_active? if respond_to?(:tef_solar_eclipse_original_active?, true)
    return false
  rescue
    return false
  end

  def can_check?
    return true if tef_solar_eclipse_active_context?
    return tef_solar_eclipse_original_can_check? if respond_to?(:tef_solar_eclipse_original_can_check?, true)
    return defined?($PokemonTemp) && $PokemonTemp && defined?($PokemonGlobal) && $PokemonGlobal
  rescue
    return false
  end

  def get
    return TravelExpansionFramework.solar_eclipse_following_get if tef_solar_eclipse_active_context? &&
                                                                  TravelExpansionFramework.respond_to?(:solar_eclipse_following_get)
    return tef_solar_eclipse_original_get if respond_to?(:tef_solar_eclipse_original_get, true)
    return nil
  rescue
    return nil
  end

  def refresh(*args)
    return TravelExpansionFramework.solar_eclipse_following_refresh!(*args) if tef_solar_eclipse_active_context? &&
                                                                              TravelExpansionFramework.respond_to?(:solar_eclipse_following_refresh!)
    return tef_solar_eclipse_original_refresh(*args) if respond_to?(:tef_solar_eclipse_original_refresh, true)
    return true
  rescue
    return true
  end

  def refresh_internal(*args)
    return TravelExpansionFramework.solar_eclipse_following_refresh!(*args) if tef_solar_eclipse_active_context? &&
                                                                              TravelExpansionFramework.respond_to?(:solar_eclipse_following_refresh!)
    return tef_solar_eclipse_original_refresh_internal(*args) if respond_to?(:tef_solar_eclipse_original_refresh_internal, true)
    return true
  rescue
    return true
  end

  def start_following(*args)
    return TravelExpansionFramework.solar_eclipse_following_start!(*args) if tef_solar_eclipse_active_context? &&
                                                                            TravelExpansionFramework.respond_to?(:solar_eclipse_following_start!)
    return tef_solar_eclipse_original_start_following(*args) if respond_to?(:tef_solar_eclipse_original_start_following, true)
    return true
  rescue
    return true
  end

  def stop_following(*args)
    return TravelExpansionFramework.solar_eclipse_following_stop!(*args) if tef_solar_eclipse_active_context? &&
                                                                           TravelExpansionFramework.respond_to?(:solar_eclipse_following_stop!)
    return tef_solar_eclipse_original_stop_following(*args) if respond_to?(:tef_solar_eclipse_original_stop_following, true)
    return true
  rescue
    return true
  end

  def toggle(*args)
    return TravelExpansionFramework.solar_eclipse_following_toggle!(*args) if tef_solar_eclipse_active_context? &&
                                                                             TravelExpansionFramework.respond_to?(:solar_eclipse_following_toggle!)
    return tef_solar_eclipse_original_toggle(*args) if respond_to?(:tef_solar_eclipse_original_toggle, true)
    return true
  rescue
    return true
  end

  def toggle_on(*args)
    return TravelExpansionFramework.solar_eclipse_following_toggle!(true, *args) if tef_solar_eclipse_active_context? &&
                                                                                   TravelExpansionFramework.respond_to?(:solar_eclipse_following_toggle!)
    return tef_solar_eclipse_original_toggle_on(*args) if respond_to?(:tef_solar_eclipse_original_toggle_on, true)
    return toggle(true, *args)
  rescue
    return true
  end

  def toggle_off(*args)
    return TravelExpansionFramework.solar_eclipse_following_toggle!(false, *args) if tef_solar_eclipse_active_context? &&
                                                                                    TravelExpansionFramework.respond_to?(:solar_eclipse_following_toggle!)
    return tef_solar_eclipse_original_toggle_off(*args) if respond_to?(:tef_solar_eclipse_original_toggle_off, true)
    return toggle(false, *args)
  rescue
    return true
  end

  def move_route(*args)
    return TravelExpansionFramework.solar_eclipse_following_move_route!(*args) if tef_solar_eclipse_active_context? &&
                                                                                 TravelExpansionFramework.respond_to?(:solar_eclipse_following_move_route!)
    return tef_solar_eclipse_original_move_route(*args) if respond_to?(:tef_solar_eclipse_original_move_route, true)
    return true
  rescue
    return true
  end

  def talk(*args)
    return false if tef_solar_eclipse_active_context? && !active?
    return tef_solar_eclipse_original_talk(*args) if respond_to?(:tef_solar_eclipse_original_talk, true)
    return false
  rescue
    return false
  end

  def animation(*args)
    return true if tef_solar_eclipse_active_context?
    return tef_solar_eclipse_original_animation(*args) if respond_to?(:tef_solar_eclipse_original_animation, true)
    return true
  rescue
    return true
  end

  def item(*args)
    return false if tef_solar_eclipse_active_context?
    return tef_solar_eclipse_original_item(*args) if respond_to?(:tef_solar_eclipse_original_item, true)
    return false
  rescue
    return false
  end

  def increase_time(*args)
    return TravelExpansionFramework.solar_eclipse_following_increase_time! if tef_solar_eclipse_active_context? &&
                                                                             TravelExpansionFramework.respond_to?(:solar_eclipse_following_increase_time!)
    return tef_solar_eclipse_original_increase_time(*args) if respond_to?(:tef_solar_eclipse_original_increase_time, true)
    return true
  rescue
    return true
  end
end

if defined?(PokemonGlobalMetadata)
  class PokemonGlobalMetadata
    attr_accessor :follower_toggled unless method_defined?(:follower_toggled)
    attr_accessor :follower_hold_item unless method_defined?(:follower_hold_item)
    attr_accessor :current_surfing unless method_defined?(:current_surfing)
    attr_accessor :current_diving unless method_defined?(:current_diving)

    def call_refresh
      @call_refresh = [false, false] if !instance_variable_defined?(:@call_refresh) || @call_refresh.nil?
      return @call_refresh
    rescue
      return [false, false]
    end unless method_defined?(:call_refresh)

    def call_refresh=(value)
      @call_refresh = value.is_a?(Array) ? value : [value, false]
      return @call_refresh
    rescue
      return [false, false]
    end unless method_defined?(:call_refresh=)

    def time_taken
      @time_taken = 0 if !instance_variable_defined?(:@time_taken) || @time_taken.nil?
      return @time_taken
    rescue
      return 0
    end unless method_defined?(:time_taken)

    def time_taken=(value)
      @time_taken = value.to_i
      return @time_taken
    rescue
      @time_taken = 0
      return @time_taken
    end unless method_defined?(:time_taken=)
  end
end

if defined?(DependentEvents)
  class DependentEvents
    alias tef_solar_eclipse_original_can_refresh? can_refresh? if method_defined?(:can_refresh?) &&
                                                                  !method_defined?(:tef_solar_eclipse_original_can_refresh?)

    def can_refresh?
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:solar_eclipse_active_now?) &&
         TravelExpansionFramework.solar_eclipse_active_now?
        return FollowingPkmn.active? if defined?(FollowingPkmn) && FollowingPkmn.respond_to?(:active?)
        return false
      end
      return tef_solar_eclipse_original_can_refresh? if respond_to?(:tef_solar_eclipse_original_can_refresh?, true)
      return true
    rescue
      return false
    end
  end
end

if defined?(Game_Map)
  class Game_Map
    alias tef_solar_eclipse_original_setup setup unless method_defined?(:tef_solar_eclipse_original_setup)
    alias tef_solar_eclipse_original_playerPassable? playerPassable? unless method_defined?(:tef_solar_eclipse_original_playerPassable?)

    def setup(map_id)
      result = tef_solar_eclipse_original_setup(map_id)
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:solar_eclipse_cleanup_foreign_dependencies!)
        TravelExpansionFramework.solar_eclipse_cleanup_foreign_dependencies!(map_id)
      end
      return result
    end

    def playerPassable?(x, y, d, self_event = nil)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:solar_eclipse_map?) &&
         TravelExpansionFramework.solar_eclipse_map?(@map_id)
        new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
        new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
        if TravelExpansionFramework.respond_to?(:solar_eclipse_ensure_bridge_for_tile!)
          TravelExpansionFramework.solar_eclipse_ensure_bridge_for_tile!(self, x, y)
          TravelExpansionFramework.solar_eclipse_ensure_bridge_for_tile!(self, new_x, new_y)
        end
      end
      return tef_solar_eclipse_original_playerPassable?(x, y, d, self_event)
    end
  end
end

def pbZoomIn
  begin
    if defined?($zoom) && $zoom && $zoom.respond_to?(:dispose) &&
       (!$zoom.respond_to?(:disposed?) || !$zoom.disposed?)
      $zoom.dispose
    end
  rescue
  end
  begin
    $zoom = nil
    if defined?($tef_solar_eclipse_zoom_viewport) && $tef_solar_eclipse_zoom_viewport &&
       $tef_solar_eclipse_zoom_viewport.respond_to?(:dispose) &&
       (!$tef_solar_eclipse_zoom_viewport.respond_to?(:disposed?) || !$tef_solar_eclipse_zoom_viewport.disposed?)
      $tef_solar_eclipse_zoom_viewport.dispose
    end
  rescue
  end
  return true if !defined?(Graphics) || !defined?(Viewport) || !defined?(Sprite)
  return true if !Graphics.respond_to?(:snap_to_bitmap)
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 1_000_000 if viewport.respond_to?(:z=)
  sprite = Sprite.new(viewport)
  sprite.bitmap = Graphics.snap_to_bitmap
  if sprite.bitmap
    center_x = sprite.bitmap.width / 2
    center_y = sprite.bitmap.height / 2
    sprite.x = center_x if sprite.respond_to?(:x=)
    sprite.y = center_y if sprite.respond_to?(:y=)
    sprite.ox = center_x if sprite.respond_to?(:ox=)
    sprite.oy = center_y if sprite.respond_to?(:oy=)
  end
  $zoom = sprite
  $tef_solar_eclipse_zoom_viewport = viewport
  return true
rescue => e
  TravelExpansionFramework.log("[solar_eclipse] door zoom-in skipped after #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                       TravelExpansionFramework.respond_to?(:log)
  $zoom = nil
  return false
end unless defined?(pbZoomIn)

def pbUpdateZoom(time = 0)
  frames = time.to_i rescue 0
  frames = 0 if frames < 0
  frames = 60 if frames > 60
  frames.times do
    Graphics.update if defined?(Graphics) && Graphics.respond_to?(:update)
    Input.update if defined?(Input) && Input.respond_to?(:update)
    next if !defined?($zoom) || !$zoom
    $zoom.zoom_x += 0.01 if $zoom.respond_to?(:zoom_x) && $zoom.respond_to?(:zoom_x=)
    $zoom.zoom_y += 0.01 if $zoom.respond_to?(:zoom_y) && $zoom.respond_to?(:zoom_y=)
  end
  return true
rescue => e
  TravelExpansionFramework.log("[solar_eclipse] door zoom update skipped after #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                          TravelExpansionFramework.respond_to?(:log)
  return false
end unless defined?(pbUpdateZoom)

def pbFadeOutZoom
  if defined?($zoom) && $zoom
    32.times do
      Graphics.update if defined?(Graphics) && Graphics.respond_to?(:update)
      Input.update if defined?(Input) && Input.respond_to?(:update)
      $zoom.zoom_x += 0.01 if $zoom.respond_to?(:zoom_x) && $zoom.respond_to?(:zoom_x=)
      $zoom.zoom_y += 0.01 if $zoom.respond_to?(:zoom_y) && $zoom.respond_to?(:zoom_y=)
      $zoom.opacity -= (255 / 32.0) if $zoom.respond_to?(:opacity) && $zoom.respond_to?(:opacity=)
    end
    $zoom.dispose if $zoom.respond_to?(:dispose) && (!$zoom.respond_to?(:disposed?) || !$zoom.disposed?)
  end
  if defined?($tef_solar_eclipse_zoom_viewport) && $tef_solar_eclipse_zoom_viewport &&
     $tef_solar_eclipse_zoom_viewport.respond_to?(:dispose) &&
     (!$tef_solar_eclipse_zoom_viewport.respond_to?(:disposed?) || !$tef_solar_eclipse_zoom_viewport.disposed?)
    $tef_solar_eclipse_zoom_viewport.dispose
  end
  $zoom = nil
  $tef_solar_eclipse_zoom_viewport = nil
  return true
rescue => e
  TravelExpansionFramework.log("[solar_eclipse] door zoom fade skipped after #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                        TravelExpansionFramework.respond_to?(:log)
  $zoom = nil
  $tef_solar_eclipse_zoom_viewport = nil
  return false
end unless defined?(pbFadeOutZoom)

if defined?(pbMessage) && !defined?(tef_solar_eclipse_original_pbMessage)
  alias tef_solar_eclipse_original_pbMessage pbMessage
end

def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
  if defined?(TravelExpansionFramework) &&
     TravelExpansionFramework.respond_to?(:solar_eclipse_active_now?) &&
     TravelExpansionFramework.solar_eclipse_active_now?
    if commands.nil? && TravelExpansionFramework.respond_to?(:solar_eclipse_prepare_intro_message_choice!)
      TravelExpansionFramework.solar_eclipse_prepare_intro_message_choice!(message)
    end
    if TravelExpansionFramework.respond_to?(:solar_eclipse_auto_intro_message_choice)
      auto_choice = TravelExpansionFramework.solar_eclipse_auto_intro_message_choice(message, commands)
      return auto_choice if !auto_choice.nil?
    end
    if TravelExpansionFramework.respond_to?(:solar_eclipse_normalize_choice_cancel)
      cmdIfCancel, defaultCmd = TravelExpansionFramework.solar_eclipse_normalize_choice_cancel(commands, cmdIfCancel, defaultCmd)
    end
  end
  return tef_solar_eclipse_original_pbMessage(message, commands, cmdIfCancel, skin, defaultCmd, &block)
end

if defined?(pbShowCommands) && !defined?(tef_solar_eclipse_original_pbShowCommands)
  alias tef_solar_eclipse_original_pbShowCommands pbShowCommands
end

def pbShowCommands(msgwindow, commands = nil, cmdIfCancel = 0, defaultCmd = 0, x_offset = nil, y_offset = nil)
  if defined?(TravelExpansionFramework) &&
     TravelExpansionFramework.respond_to?(:solar_eclipse_active_now?) &&
     TravelExpansionFramework.solar_eclipse_active_now?
    if TravelExpansionFramework.respond_to?(:solar_eclipse_take_pending_intro_choice)
      pending_choice = TravelExpansionFramework.solar_eclipse_take_pending_intro_choice(commands)
      return pending_choice if !pending_choice.nil?
    end
    if TravelExpansionFramework.respond_to?(:solar_eclipse_auto_intro_command_choice)
      auto_choice = TravelExpansionFramework.solar_eclipse_auto_intro_command_choice(commands)
      return auto_choice if !auto_choice.nil?
    end
    if TravelExpansionFramework.respond_to?(:solar_eclipse_normalize_choice_cancel)
      cmdIfCancel, defaultCmd = TravelExpansionFramework.solar_eclipse_normalize_choice_cancel(commands, cmdIfCancel, defaultCmd)
    end
  end
  return tef_solar_eclipse_original_pbShowCommands(msgwindow, commands, cmdIfCancel, defaultCmd, x_offset, y_offset)
end

if defined?(Player)
  class Player
    def difficulty
      return @tef_solar_eclipse_difficulty if instance_variable_defined?(:@tef_solar_eclipse_difficulty)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:solar_eclipse_player_difficulty_value)
        return TravelExpansionFramework.solar_eclipse_player_difficulty_value
      end
      return ""
    rescue
      return ""
    end unless method_defined?(:difficulty)

    def difficulty=(value)
      stored = value.nil? ? "" : value
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:solar_eclipse_store_player_difficulty!) &&
         (!TravelExpansionFramework.respond_to?(:new_project_active_now?) || TravelExpansionFramework.new_project_active_now?)
        stored = TravelExpansionFramework.solar_eclipse_store_player_difficulty!(stored)
      end
      @tef_solar_eclipse_difficulty = stored
      return stored
    rescue
      @tef_solar_eclipse_difficulty = value.nil? ? "" : value
      return @tef_solar_eclipse_difficulty
    end unless method_defined?(:difficulty=)

    def wallpaper
      return @tef_solar_eclipse_wallpaper if instance_variable_defined?(:@tef_solar_eclipse_wallpaper)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:solar_eclipse_player_wallpaper_value)
        return TravelExpansionFramework.solar_eclipse_player_wallpaper_value
      end
      return 0
    rescue
      return 0
    end unless method_defined?(:wallpaper)

    def wallpaper=(value)
      stored = value.nil? ? 0 : value
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:solar_eclipse_store_player_wallpaper!) &&
         (!TravelExpansionFramework.respond_to?(:new_project_active_now?) || TravelExpansionFramework.new_project_active_now?)
        stored = TravelExpansionFramework.solar_eclipse_store_player_wallpaper!(stored)
      end
      @tef_solar_eclipse_wallpaper = stored
      return stored
    rescue
      @tef_solar_eclipse_wallpaper = value.nil? ? 0 : value
      return @tef_solar_eclipse_wallpaper
    end unless method_defined?(:wallpaper=)
  end
end

if defined?(PokemonTrainerCardScreen)
  class PokemonTrainerCardScreen
    alias tef_solar_eclipse_original_pbStartScreen pbStartScreen if method_defined?(:pbStartScreen) &&
                                                                    !method_defined?(:tef_solar_eclipse_original_pbStartScreen)

    def pbStartScreen(*args)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:solar_eclipse_intro_trainer_card_review?) &&
         TravelExpansionFramework.solar_eclipse_intro_trainer_card_review?
        TravelExpansionFramework.solar_eclipse_mark_trainer_card_review_skipped! if TravelExpansionFramework.respond_to?(:solar_eclipse_mark_trainer_card_review_skipped!)
        return true
      end
      return tef_solar_eclipse_original_pbStartScreen(*args)
    end if method_defined?(:tef_solar_eclipse_original_pbStartScreen)
  end
end

if defined?(PokemonTrainerCard_Scene)
  class PokemonTrainerCard_Scene
    alias tef_solar_eclipse_original_scene_pbTrainerCard pbTrainerCard if method_defined?(:pbTrainerCard) &&
                                                                         !method_defined?(:tef_solar_eclipse_original_scene_pbTrainerCard)

    def pbTrainerCard(*args)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:solar_eclipse_intro_trainer_card_review?) &&
         TravelExpansionFramework.solar_eclipse_intro_trainer_card_review?
        TravelExpansionFramework.solar_eclipse_mark_trainer_card_review_skipped! if TravelExpansionFramework.respond_to?(:solar_eclipse_mark_trainer_card_review_skipped!)
        return true
      end
      return tef_solar_eclipse_original_scene_pbTrainerCard(*args)
    end if method_defined?(:tef_solar_eclipse_original_scene_pbTrainerCard)
  end
end

module GenderPickSelection
  def self.quant_registered_player
    if defined?(GameData) && GameData.const_defined?(:Metadata) && GameData::Metadata.respond_to?(:get_player)
      count = 0
      loop do
        break if !GameData::Metadata.get_player(count)
        count += 1
      end
      return [count, 1].max
    end
    return 1
  rescue
    return 1
  end

  def self.show(*_args)
    if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:solar_eclipse_gender_pick_selection!)
      map_id = ($game_map.map_id rescue nil)
      return TravelExpansionFramework.solar_eclipse_gender_pick_selection!(map_id)
    end
    return 0
  end

  class Show
    def show
      return GenderPickSelection.show
    end

    def endScene
      return true
    end

    def dispose(*_args)
      return true
    end
  end
end

class Interpreter
  alias tef_solar_eclipse_original_command_101 command_101 if method_defined?(:command_101) &&
                                                              !method_defined?(:tef_solar_eclipse_original_command_101)
  alias tef_solar_eclipse_original_command_117 command_117 if method_defined?(:command_117) &&
                                                              !method_defined?(:tef_solar_eclipse_original_command_117)
  alias tef_solar_eclipse_original_execute_script execute_script if method_defined?(:execute_script) &&
                                                                    !method_defined?(:tef_solar_eclipse_original_execute_script)

  def command_101
    message = (@list[@index].parameters[0] rescue "")
    if defined?(TravelExpansionFramework) &&
       TravelExpansionFramework.respond_to?(:solar_eclipse_intro_repeat_text?) &&
       TravelExpansionFramework.solar_eclipse_intro_repeat_text?(message, (@event_id rescue nil), (@map_id rescue nil))
      TravelExpansionFramework.solar_eclipse_complete_intro!((@map_id rescue nil)) if TravelExpansionFramework.respond_to?(:solar_eclipse_complete_intro!)
      command_end
      return false
    end
    return tef_solar_eclipse_original_command_101
  end if method_defined?(:tef_solar_eclipse_original_command_101)

  def command_117
    if defined?(TravelExpansionFramework) &&
       TravelExpansionFramework.respond_to?(:solar_eclipse_expansion_ids) &&
       @parameters &&
       [72, 74].include?(@parameters[0].to_i) &&
       (TravelExpansionFramework.solar_eclipse_expansion_ids.include?(@tef_expansion_id.to_s) ||
        (TravelExpansionFramework.respond_to?(:solar_eclipse_active_now?) &&
         TravelExpansionFramework.solar_eclipse_active_now?))
      TravelExpansionFramework.solar_eclipse_patch_intro_difficulty_common_event! if TravelExpansionFramework.respond_to?(:solar_eclipse_patch_intro_difficulty_common_event!)
    end
    return tef_solar_eclipse_original_command_117
  end if method_defined?(:tef_solar_eclipse_original_command_117)

  def execute_script(script)
    if defined?(TravelExpansionFramework) &&
       TravelExpansionFramework.respond_to?(:solar_eclipse_intro_trainer_card_script?) &&
       TravelExpansionFramework.solar_eclipse_intro_trainer_card_script?(script)
      TravelExpansionFramework.solar_eclipse_mark_trainer_card_review_skipped! if TravelExpansionFramework.respond_to?(:solar_eclipse_mark_trainer_card_review_skipped!)
      return true
    end
    return tef_solar_eclipse_original_execute_script(script)
  end if method_defined?(:tef_solar_eclipse_original_execute_script)

  const_set(:GenderPickSelection, ::GenderPickSelection) if defined?(::GenderPickSelection) &&
                                                            !const_defined?(:GenderPickSelection, false)
end
