module TravelExpansionFramework
  module_function

  OPALO_EXPANSION_ID = "opalo" unless const_defined?(:OPALO_EXPANSION_ID)
  OPALO_LEGACY_EXPANSION_IDS = ["pokemon_opalo"].freeze unless const_defined?(:OPALO_LEGACY_EXPANSION_IDS)
  OPALO_COMPAT_PICTURE_OVERRIDES = %w[
    MenuNuzNormalClaro
    MenuNuzNormalOsc
    MenuNuzNuzClaro
    MenuNuzNuzOsc
    MenuNuzNormalDif1
    MenuNuzNormalDif1Claro
    MenuNuzNormalDif2
    MenuNuzNormalDif2Claro
    MenuNuzNormalDif3
    MenuNuzNormalDif3Claro
  ].freeze unless const_defined?(:OPALO_COMPAT_PICTURE_OVERRIDES)
  OPALO_LENS_OF_TRUTH_DURATION_SECONDS = 14 unless const_defined?(:OPALO_LENS_OF_TRUTH_DURATION_SECONDS)
  OPALO_LENS_OF_TRUTH_RANGE = 3 unless const_defined?(:OPALO_LENS_OF_TRUTH_RANGE)
  OPALO_STARTER_ROOM_LOCAL_MAP_ID = 5 unless const_defined?(:OPALO_STARTER_ROOM_LOCAL_MAP_ID)
  OPALO_STARTER_TOWN_LOCAL_MAP_ID = 2 unless const_defined?(:OPALO_STARTER_TOWN_LOCAL_MAP_ID)
  OPALO_STARTER_ROUTE_LOCAL_MAP_ID = 6 unless const_defined?(:OPALO_STARTER_ROUTE_LOCAL_MAP_ID)
  OPALO_STARTER_SELECTED_SWITCH = 62 unless const_defined?(:OPALO_STARTER_SELECTED_SWITCH)
  OPALO_STARTER_FLED_SWITCH = 63 unless const_defined?(:OPALO_STARTER_FLED_SWITCH)
  OPALO_STARTER_HIDDEN_SWITCH = 64 unless const_defined?(:OPALO_STARTER_HIDDEN_SWITCH)
  OPALO_STARTER_CHASE_SWITCH = 65 unless const_defined?(:OPALO_STARTER_CHASE_SWITCH)
  OPALO_STARTER_POOCHYENA_SWITCH = 66 unless const_defined?(:OPALO_STARTER_POOCHYENA_SWITCH)
  OPALO_STARTER_BATTLE_DONE_SWITCH = 67 unless const_defined?(:OPALO_STARTER_BATTLE_DONE_SWITCH)
  OPALO_STARTER_PROFESSOR_SWITCH = 68 unless const_defined?(:OPALO_STARTER_PROFESSOR_SWITCH)
  OPALO_STARTER_CHOICE_VARIABLE = 54 unless const_defined?(:OPALO_STARTER_CHOICE_VARIABLE)
  EMPYREAN_EXPANSION_ID = "empyrean" unless const_defined?(:EMPYREAN_EXPANSION_ID)
  EMPYREAN_LEGACY_EXPANSION_IDS = ["pokemonempyrean", "pokemon_empyrean"].freeze unless const_defined?(:EMPYREAN_LEGACY_EXPANSION_IDS)
  REALIDEA_EXPANSION_ID = "realidea" unless const_defined?(:REALIDEA_EXPANSION_ID)
  SOULSTONES_EXPANSION_ID = "soulstones" unless const_defined?(:SOULSTONES_EXPANSION_ID)
  SOULSTONES2_EXPANSION_ID = "soulstones2" unless const_defined?(:SOULSTONES2_EXPANSION_ID)
  ANIL_EXPANSION_ID = "anil" unless const_defined?(:ANIL_EXPANSION_ID)
  ANIL_LEGACY_EXPANSION_IDS = ["pokemon_anil", "pokemon_indigo", "indigo"].freeze unless const_defined?(:ANIL_LEGACY_EXPANSION_IDS)
  BUSHIDO_EXPANSION_ID = "bushido" unless const_defined?(:BUSHIDO_EXPANSION_ID)
  BUSHIDO_LEGACY_EXPANSION_IDS = ["pokemon_bushido"].freeze unless const_defined?(:BUSHIDO_LEGACY_EXPANSION_IDS)
  DARKHORIZON_EXPANSION_ID = "darkhorizon" unless const_defined?(:DARKHORIZON_EXPANSION_ID)
  DARKHORIZON_LEGACY_EXPANSION_IDS = ["dark_horizon", "pokemon_darkhorizon", "pokemon_dark_horizon"].freeze unless const_defined?(:DARKHORIZON_LEGACY_EXPANSION_IDS)
  INFINITY_EXPANSION_ID = "infinity" unless const_defined?(:INFINITY_EXPANSION_ID)
  INFINITY_LEGACY_EXPANSION_IDS = ["pokemon_infinity"].freeze unless const_defined?(:INFINITY_LEGACY_EXPANSION_IDS)
  SOLAR_ECLIPSE_EXPANSION_ID = "solar_eclipse" unless const_defined?(:SOLAR_ECLIPSE_EXPANSION_ID)
  SOLAR_ECLIPSE_LEGACY_EXPANSION_IDS = ["solareclipse", "pokemon_solar_eclipse", "pokemon_solareclipse", "solar_light_lunar_dark", "solar_light_and_lunar_dark", "pokemon_solar_light_lunar_dark"].freeze unless const_defined?(:SOLAR_ECLIPSE_LEGACY_EXPANSION_IDS)
  VANGUARD_EXPANSION_ID = "vanguard" unless const_defined?(:VANGUARD_EXPANSION_ID)
  VANGUARD_LEGACY_EXPANSION_IDS = ["pokemon_vanguard"].freeze unless const_defined?(:VANGUARD_LEGACY_EXPANSION_IDS)
  POKEMON_Z_EXPANSION_ID = "pokemon_z" unless const_defined?(:POKEMON_Z_EXPANSION_ID)
  POKEMON_Z_LEGACY_EXPANSION_IDS = ["z", "pokemonz"].freeze unless const_defined?(:POKEMON_Z_LEGACY_EXPANSION_IDS)
  CHAOS_IN_VESITA_EXPANSION_ID = "chaos_in_vesita" unless const_defined?(:CHAOS_IN_VESITA_EXPANSION_ID)
  CHAOS_IN_VESITA_LEGACY_EXPANSION_IDS = ["chaosinvesita", "pokemon_chaos_in_vesita", "chaos_vesita"].freeze unless const_defined?(:CHAOS_IN_VESITA_LEGACY_EXPANSION_IDS)
  DESERTED_EXPANSION_ID = "deserted" unless const_defined?(:DESERTED_EXPANSION_ID)
  DESERTED_LEGACY_EXPANSION_IDS = ["pokemon_deserted"].freeze unless const_defined?(:DESERTED_LEGACY_EXPANSION_IDS)
  GADIR_DELUXE_EXPANSION_ID = "gadir_deluxe" unless const_defined?(:GADIR_DELUXE_EXPANSION_ID)
  GADIR_DELUXE_LEGACY_EXPANSION_IDS = ["gadirdeluxe", "gadirdelux", "pokemon_gadir_deluxe", "pokemon_gadir_delux"].freeze unless const_defined?(:GADIR_DELUXE_LEGACY_EXPANSION_IDS)
  GADIR_DELUXE_INTRO_LOCAL_MAP_ID = 1 unless const_defined?(:GADIR_DELUXE_INTRO_LOCAL_MAP_ID)
  GADIR_DELUXE_HOME_LOCAL_MAP_ID = 78 unless const_defined?(:GADIR_DELUXE_HOME_LOCAL_MAP_ID)
  GADIR_DELUXE_SWITCH_CHAPI_INTRO = 62 unless const_defined?(:GADIR_DELUXE_SWITCH_CHAPI_INTRO)
  GADIR_DELUXE_SWITCH_FININTRO = 63 unless const_defined?(:GADIR_DELUXE_SWITCH_FININTRO)
  GADIR_DELUXE_SWITCH_ENCIENDE = 596 unless const_defined?(:GADIR_DELUXE_SWITCH_ENCIENDE)
  GADIR_DELUXE_SWITCH_ULTIMO_PARCHE = 702 unless const_defined?(:GADIR_DELUXE_SWITCH_ULTIMO_PARCHE)
  GADIR_DELUXE_INTRO_IDLE_RECOVERY_FRAMES = 150 unless const_defined?(:GADIR_DELUXE_INTRO_IDLE_RECOVERY_FRAMES)
  HOLLOW_WOODS_EXPANSION_ID = "hollow_woods" unless const_defined?(:HOLLOW_WOODS_EXPANSION_ID)
  HOLLOW_WOODS_LEGACY_EXPANSION_IDS = ["hollowwoods", "pokemon_hollow_woods", "pokemon_hollowwoods"].freeze unless const_defined?(:HOLLOW_WOODS_LEGACY_EXPANSION_IDS)
  KEISHOU_EXPANSION_ID = "keishou" unless const_defined?(:KEISHOU_EXPANSION_ID)
  KEISHOU_LEGACY_EXPANSION_IDS = ["pokemon_keishou"].freeze unless const_defined?(:KEISHOU_LEGACY_EXPANSION_IDS)
  UNBREAKABLE_TIES_EXPANSION_ID = "unbreakable_ties" unless const_defined?(:UNBREAKABLE_TIES_EXPANSION_ID)
  UNBREAKABLE_TIES_LEGACY_EXPANSION_IDS = ["unbreakableties", "pokemon_unbreakable_ties", "pokemon_unbreakableties"].freeze unless const_defined?(:UNBREAKABLE_TIES_LEGACY_EXPANSION_IDS)
  NEW_PROJECT_PARTY_ISOLATION_IDS = [KEISHOU_EXPANSION_ID].freeze unless const_defined?(:NEW_PROJECT_PARTY_ISOLATION_IDS)
  NEW_PROJECT_BANKED_GIFT_IDS = [KEISHOU_EXPANSION_ID, OPALO_EXPANSION_ID].freeze unless const_defined?(:NEW_PROJECT_BANKED_GIFT_IDS)
  EMPYREAN_TERRAIN_TAG_TRANSLATIONS = {
    4  => 15, # Essentials Rock -> Infinite Fusion Rock
    6  => 7,  # Essentials StillWater -> Infinite Fusion surfable water
    15 => 4   # Essentials Bridge -> Infinite Fusion Bridge
  }.freeze unless const_defined?(:EMPYREAN_TERRAIN_TAG_TRANSLATIONS)
  EMPYREAN_BRIDGE_SCAN_RADIUS = 3 unless const_defined?(:EMPYREAN_BRIDGE_SCAN_RADIUS)

  class EmpyreanTerrainTagProxy
    def initialize(source)
      @source = source
    end

    def [](index)
      if TravelExpansionFramework.respond_to?(:empyrean_bridge_tile_id?) &&
         TravelExpansionFramework.empyrean_bridge_tile_id?(index)
        return 4
      end
      return TravelExpansionFramework.empyrean_translate_terrain_tag(@source[index])
    rescue
      return TravelExpansionFramework.empyrean_translate_terrain_tag(nil)
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

  class HollowWoodsGameMode
    DEFAULTS = {
      "levelcap"   => 0,
      "randomizer" => 0,
      "nuzlocke"   => 0,
      "autoheal"   => 0
    }.freeze unless const_defined?(:DEFAULTS)

    def initialize
      DEFAULTS.each { |key, value| instance_variable_set("@#{key}", value) }
    end

    def metadata
      return nil if !defined?(TravelExpansionFramework) ||
                    !TravelExpansionFramework.respond_to?(:new_project_metadata)
      expansion = nil
      expansion = TravelExpansionFramework.current_new_project_expansion_id if TravelExpansionFramework.respond_to?(:current_new_project_expansion_id)
      expansion = TravelExpansionFramework::HOLLOW_WOODS_EXPANSION_ID if expansion.to_s.empty? &&
                                                                        TravelExpansionFramework.const_defined?(:HOLLOW_WOODS_EXPANSION_ID)
      return TravelExpansionFramework.new_project_metadata(expansion)
    rescue
      return nil
    end

    def settings_store
      meta = metadata
      return nil if !meta
      meta["hollow_woods_game_mode"] = {} if !meta["hollow_woods_game_mode"].is_a?(Hash)
      return meta["hollow_woods_game_mode"]
    rescue
      return nil
    end

    def normalize_key(name)
      key = name.to_s
      key = key[0, key.length - 1] if key[-1, 1] == "="
      return key.downcase
    rescue
      return name.to_s.downcase
    end

    def integer(value, fallback = 0)
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:integer)
        return TravelExpansionFramework.integer(value, fallback)
      end
      return fallback if value.nil?
      return value ? 1 : 0 if value == true || value == false
      return value.to_i
    rescue
      return fallback
    end

    def [](name)
      key = normalize_key(name)
      store = settings_store
      return integer(store[key], DEFAULTS[key] || 0) if store && store.has_key?(key)
      ivar = "@#{key}"
      return integer(instance_variable_get(ivar), DEFAULTS[key] || 0) if instance_variable_defined?(ivar)
      return DEFAULTS[key] || 0
    end

    def []=(name, value)
      key = normalize_key(name)
      normalized = integer(value, DEFAULTS[key] || 0)
      instance_variable_set("@#{key}", normalized)
      store = settings_store
      store[key] = normalized if store
      return normalized
    end

    DEFAULTS.keys.each do |key|
      define_method(key) { self[key] }
      define_method("#{key}=") { |value| self[key] = value }
    end

    def method_missing(name, *args, &block)
      method_name = name.to_s
      if method_name[-1, 1] == "="
        return self[method_name] = args.first
      end
      return self[method_name] if args.empty?
      super
    end

    def respond_to_missing?(_name, _include_private = false)
      return true
    end
  end

  NEW_PROJECT_COMPATIBILITY_PROFILES = {
    "opalo"           => { :aliases => ["pokemon_opalo"], :language => :opalo_translation },
    "pokemon_opalo"   => { :canonical => "opalo" },
    "empyrean"        => { :aliases => ["pokemonempyrean", "pokemon_empyrean"], :identity => :host },
    "pokemonempyrean" => { :canonical => "empyrean" },
    "pokemon_empyrean" => { :canonical => "empyrean" },
    "realidea"        => { :aliases => [], :identity => :host, :language => :realidea_translation },
    "soulstones"      => { :aliases => [], :identity => :host },
    "soulstones2"     => { :aliases => [], :identity => :host },
    "anil"            => { :aliases => ["pokemon_anil", "pokemon_indigo", "indigo"], :identity => :host },
    "pokemon_anil"    => { :canonical => "anil" },
    "pokemon_indigo"  => { :canonical => "anil" },
    "indigo"          => { :canonical => "anil" },
    "bushido"         => { :aliases => ["pokemon_bushido"], :identity => :host },
    "pokemon_bushido" => { :canonical => "bushido" },
    "darkhorizon"     => { :aliases => ["dark_horizon", "pokemon_darkhorizon", "pokemon_dark_horizon"], :identity => :host },
    "dark_horizon"    => { :canonical => "darkhorizon" },
    "pokemon_darkhorizon" => { :canonical => "darkhorizon" },
    "pokemon_dark_horizon" => { :canonical => "darkhorizon" },
    "infinity"        => { :aliases => ["pokemon_infinity"], :identity => :host },
    "pokemon_infinity" => { :canonical => "infinity" },
    "solar_eclipse"   => { :aliases => ["solareclipse", "pokemon_solar_eclipse", "pokemon_solareclipse", "solar_light_lunar_dark", "solar_light_and_lunar_dark", "pokemon_solar_light_lunar_dark"], :identity => :host },
    "solareclipse"    => { :canonical => "solar_eclipse" },
    "pokemon_solar_eclipse" => { :canonical => "solar_eclipse" },
    "pokemon_solareclipse" => { :canonical => "solar_eclipse" },
    "solar_light_lunar_dark" => { :canonical => "solar_eclipse" },
    "solar_light_and_lunar_dark" => { :canonical => "solar_eclipse" },
    "pokemon_solar_light_lunar_dark" => { :canonical => "solar_eclipse" },
    "vanguard"        => { :aliases => ["pokemon_vanguard"], :identity => :host },
    "pokemon_vanguard" => { :canonical => "vanguard" },
    "pokemon_z"       => { :aliases => ["z", "pokemonz"], :identity => :host },
    "z"               => { :canonical => "pokemon_z" },
    "pokemonz"        => { :canonical => "pokemon_z" },
    "chaos_in_vesita" => { :aliases => ["chaosinvesita", "pokemon_chaos_in_vesita", "chaos_vesita"], :identity => :host },
    "chaosinvesita"   => { :canonical => "chaos_in_vesita" },
    "pokemon_chaos_in_vesita" => { :canonical => "chaos_in_vesita" },
    "chaos_vesita"    => { :canonical => "chaos_in_vesita" },
    "deserted"        => { :aliases => ["pokemon_deserted"], :identity => :host },
    "pokemon_deserted" => { :canonical => "deserted" },
    "gadir_deluxe"    => { :aliases => ["gadirdeluxe", "gadirdelux", "pokemon_gadir_deluxe", "pokemon_gadir_delux"], :identity => :host },
    "gadirdeluxe"     => { :canonical => "gadir_deluxe" },
    "gadirdelux"      => { :canonical => "gadir_deluxe" },
    "pokemon_gadir_deluxe" => { :canonical => "gadir_deluxe" },
    "pokemon_gadir_delux" => { :canonical => "gadir_deluxe" },
    "hollow_woods"    => { :aliases => ["hollowwoods", "pokemon_hollow_woods", "pokemon_hollowwoods"], :identity => :host },
    "hollowwoods"     => { :canonical => "hollow_woods" },
    "pokemon_hollow_woods" => { :canonical => "hollow_woods" },
    "pokemon_hollowwoods" => { :canonical => "hollow_woods" },
    "keishou"         => { :aliases => ["pokemon_keishou"], :identity => :host },
    "pokemon_keishou" => { :canonical => "keishou" },
    "unbreakable_ties" => { :aliases => ["unbreakableties", "pokemon_unbreakable_ties", "pokemon_unbreakableties"], :identity => :host },
    "unbreakableties" => { :canonical => "unbreakable_ties" },
    "pokemon_unbreakable_ties" => { :canonical => "unbreakable_ties" },
    "pokemon_unbreakableties" => { :canonical => "unbreakable_ties" }
  }.freeze unless const_defined?(:NEW_PROJECT_COMPATIBILITY_PROFILES)

  if !defined?(::OrderedHash)
    class ::OrderedHash < Hash
      def initialize
        @keys = []
        super
      end

      def keys
        return @keys ? @keys.clone : super
      end

      def []=(key, value)
        @keys ||= []
        @keys << key if !has_key?(key)
        return super(key, value)
      end

      def self._load(string)
        result = self.new
        keysvalues = Marshal.load(string) rescue [[], []]
        keys = keysvalues[0] || []
        values = keysvalues[1] || []
        for i in 0...keys.length
          result[keys[i]] = values[i]
        end
        return result
      end
    end
  end

  if defined?(::OrderedHash) && !::OrderedHash.respond_to?(:_load)
    class ::OrderedHash
      def self._load(string)
        result = self.new
        keysvalues = Marshal.load(string) rescue [[], []]
        keys = keysvalues[0] || []
        values = keysvalues[1] || []
        for i in 0...keys.length
          result[keys[i]] = values[i] if result.respond_to?(:[]=)
        end
        return result
      end
    end
  end

  def canonical_new_project_id(expansion_id)
    id = expansion_id.to_s
    profile = NEW_PROJECT_COMPATIBILITY_PROFILES[id] rescue nil
    return profile[:canonical].to_s if profile.is_a?(Hash) && profile[:canonical]
    return id
  rescue
    return expansion_id.to_s
  end

  def expansion_id_in_list?(expansion_id, ids)
    target = canonical_new_project_id(expansion_id)
    return ids.map { |id| canonical_new_project_id(id) }.include?(target)
  rescue
    return false
  end

  def active_project_expansion_id(ids, map_id = nil)
    @new_project_active_cache ||= {}
    runtime_id = current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    return canonical_new_project_id(runtime_id) if expansion_id_in_list?(runtime_id, ids)
    target_map_id = integer(map_id || ($game_map.map_id rescue 0), 0)
    marker = current_expansion_marker if respond_to?(:current_expansion_marker)
    frame = (Graphics.frame_count rescue 0)
    if @new_project_active_cache_frame != frame
      @new_project_active_cache = {}
      @new_project_active_cache_frame = frame
    end
    cache_key = [ids.map(&:to_s).sort.join("|"), target_map_id, marker.to_s, frame]
    return @new_project_active_cache[cache_key] if @new_project_active_cache.has_key?(cache_key)
    if target_map_id > 0 && respond_to?(:current_map_expansion_id)
      map_expansion = current_map_expansion_id(target_map_id)
      if expansion_id_in_list?(map_expansion, ids)
        result = canonical_new_project_id(map_expansion)
        @new_project_active_cache[cache_key] = result
        return result
      end
    end
    if target_map_id <= 0 && expansion_id_in_list?(marker, ids)
      result = canonical_new_project_id(marker)
      @new_project_active_cache[cache_key] = result
      return result
    end
    @new_project_active_cache[cache_key] = nil
    return nil
  rescue
    return nil
  end

  def opalo_expansion_ids
    return [OPALO_EXPANSION_ID] + OPALO_LEGACY_EXPANSION_IDS
  end

  def empyrean_expansion_ids
    return [EMPYREAN_EXPANSION_ID] + EMPYREAN_LEGACY_EXPANSION_IDS
  end

  def anil_expansion_ids
    return [ANIL_EXPANSION_ID] + ANIL_LEGACY_EXPANSION_IDS
  end

  def gadir_deluxe_expansion_ids
    return [GADIR_DELUXE_EXPANSION_ID] + GADIR_DELUXE_LEGACY_EXPANSION_IDS
  end

  def hollow_woods_expansion_ids
    return [HOLLOW_WOODS_EXPANSION_ID] + HOLLOW_WOODS_LEGACY_EXPANSION_IDS
  end

  def infinity_expansion_ids
    return [INFINITY_EXPANSION_ID] + INFINITY_LEGACY_EXPANSION_IDS
  end

  def newly_registered_project_expansion_ids
    return [BUSHIDO_EXPANSION_ID] + BUSHIDO_LEGACY_EXPANSION_IDS +
           [DARKHORIZON_EXPANSION_ID] + DARKHORIZON_LEGACY_EXPANSION_IDS +
           [INFINITY_EXPANSION_ID] + INFINITY_LEGACY_EXPANSION_IDS +
           [SOLAR_ECLIPSE_EXPANSION_ID] + SOLAR_ECLIPSE_LEGACY_EXPANSION_IDS +
           [VANGUARD_EXPANSION_ID] + VANGUARD_LEGACY_EXPANSION_IDS +
           [POKEMON_Z_EXPANSION_ID] + POKEMON_Z_LEGACY_EXPANSION_IDS +
           [CHAOS_IN_VESITA_EXPANSION_ID] + CHAOS_IN_VESITA_LEGACY_EXPANSION_IDS +
           [DESERTED_EXPANSION_ID] + DESERTED_LEGACY_EXPANSION_IDS +
           [GADIR_DELUXE_EXPANSION_ID] + GADIR_DELUXE_LEGACY_EXPANSION_IDS +
           [HOLLOW_WOODS_EXPANSION_ID] + HOLLOW_WOODS_LEGACY_EXPANSION_IDS +
           [KEISHOU_EXPANSION_ID] + KEISHOU_LEGACY_EXPANSION_IDS +
           [UNBREAKABLE_TIES_EXPANSION_ID] + UNBREAKABLE_TIES_LEGACY_EXPANSION_IDS
  end

  def new_project_expansion_ids
    return opalo_expansion_ids + empyrean_expansion_ids + [
      REALIDEA_EXPANSION_ID,
      SOULSTONES_EXPANSION_ID,
      SOULSTONES2_EXPANSION_ID
    ] + anil_expansion_ids + newly_registered_project_expansion_ids
  end

  def anil_expansion_id?(expansion_id = nil)
    return expansion_id_in_list?(expansion_id, anil_expansion_ids) if !expansion_id.nil? && !expansion_id.to_s.empty?
    return !active_project_expansion_id(anil_expansion_ids).nil?
  end

  def anil_active_now?(map_id = nil)
    return !active_project_expansion_id(anil_expansion_ids, map_id).nil?
  end

  def current_anil_expansion_id(map_id = nil)
    return active_project_expansion_id(anil_expansion_ids, map_id)
  end

  def anil_root_path
    return project_root_path(ANIL_EXPANSION_ID, "Anil", ["Pokemon Anil", "Pokemon Indigo"])
  end

  def anil_metadata
    expansion = active_project_expansion_id(anil_expansion_ids) || ANIL_EXPANSION_ID
    state = state_for(expansion) rescue nil
    return nil if !state || !state.respond_to?(:metadata)
    state.metadata = {} if state.metadata.nil? && state.respond_to?(:metadata=)
    return state.metadata if state.metadata.is_a?(Hash)
    return nil
  rescue
    return nil
  end

  def anil_remember_value(key, value)
    meta = anil_metadata
    meta[key.to_s] = value if meta
    return value
  rescue
    return value
  end

  def anil_value(key, fallback = nil)
    meta = anil_metadata
    return fallback if !meta || !meta.has_key?(key.to_s)
    return meta[key.to_s]
  rescue
    return fallback
  end

  def anil_truthy?(value)
    return false if value.nil?
    return value if value == true || value == false
    text = value.to_s.strip.downcase
    return false if text.empty? || ["false", "0", "no", "off", "nil"].include?(text)
    return true
  rescue
    return false
  end

  def anil_temp_switch_key(map_id, event_id, switch_name = "A")
    map = integer(map_id || ($game_map.map_id rescue 0), 0)
    event = integer(event_id, 0)
    switch = switch_name.to_s
    switch = "A" if switch.empty?
    return [map, event, switch]
  end

  def anil_temp_switch_value(map_id, event_id, switch_name = "A")
    key = anil_temp_switch_key(map_id, event_id, switch_name)
    return false if !defined?($game_self_switches) || !$game_self_switches
    return $game_self_switches[key] ? true : false
  rescue
    return false
  end

  def anil_set_temp_switch(map_id, event_id, switch_name = "A", value = true)
    return false if !defined?($game_self_switches) || !$game_self_switches
    key = anil_temp_switch_key(map_id, event_id, switch_name)
    $game_self_switches[key] = value ? true : false
    $game_map.need_refresh = true if defined?($game_map) && $game_map && $game_map.respond_to?(:need_refresh=)
    return true
  rescue
    return false
  end

  def anil_default_starter_regions
    return [
      ["Kanto",  [:BULBASAUR, :CHARMANDER, :SQUIRTLE]],
      ["Johto",  [:CHIKORITA, :CYNDAQUIL, :TOTODILE]],
      ["Hoenn",  [:TREECKO, :TORCHIC, :MUDKIP]],
      ["Sinnoh", [:TURTWIG, :CHIMCHAR, :PIPLUP]],
      ["Unova",  [:SNIVY, :TEPIG, :OSHAWOTT]],
      ["Kalos",  [:CHESPIN, :FENNEKIN, :FROAKIE]],
      ["Alola",  [:ROWLET, :LITTEN, :POPPLIO]],
      ["Galar",  [:GROOKEY, :SCORBUNNY, :SOBBLE]],
      ["Paldea", [:SPRIGATITO, :FUECOCO, :QUAXLY]]
    ]
  end

  def new_project_identity_expansion_ids
    return new_project_expansion_ids
  end

  def opalo_expansion_id?(expansion_id = nil)
    return expansion_id_in_list?(expansion_id, opalo_expansion_ids) if !expansion_id.nil? && !expansion_id.to_s.empty?
    return !active_project_expansion_id(opalo_expansion_ids).nil?
  end

  def opalo_active_now?(map_id = nil)
    return !active_project_expansion_id(opalo_expansion_ids, map_id).nil?
  end

  def empyrean_expansion_id?(expansion_id = nil)
    return expansion_id_in_list?(expansion_id, empyrean_expansion_ids) if !expansion_id.nil? && !expansion_id.to_s.empty?
    return !active_project_expansion_id(empyrean_expansion_ids).nil?
  end

  def empyrean_active_now?(map_id = nil)
    return !active_project_expansion_id(empyrean_expansion_ids, map_id).nil?
  end

  def empyrean_translate_terrain_tag(tag)
    value = integer(tag, 0) if respond_to?(:integer)
    value = tag.to_i if value.nil?
    return 0 if value <= 0
    return EMPYREAN_TERRAIN_TAG_TRANSLATIONS[value] || value
  rescue
    return 0
  end

  def empyrean_wrap_terrain_tags(expansion_id, terrain_tags)
    return terrain_tags if terrain_tags.nil?
    return terrain_tags if !empyrean_expansion_ids.include?(expansion_id.to_s)
    return terrain_tags if terrain_tags.is_a?(EmpyreanTerrainTagProxy)
    return EmpyreanTerrainTagProxy.new(terrain_tags)
  rescue
    return terrain_tags
  end

  def empyrean_map?(map_id = nil)
    current_map_id = map_id
    current_map_id = $game_map.map_id if current_map_id.nil? && defined?($game_map) && $game_map && $game_map.respond_to?(:map_id)
    return empyrean_expansion_ids.include?(current_map_expansion_id(current_map_id).to_s) if respond_to?(:current_map_expansion_id)
    return empyrean_active_now?(current_map_id)
  rescue
    return false
  end

  def empyrean_bridge_command_list?(list)
    Array(list).any? do |command|
      code = command.respond_to?(:code) ? command.code : command.instance_variable_get(:@code)
      next false if code.to_i != 355 && code.to_i != 655
      params = command.respond_to?(:parameters) ? command.parameters : command.instance_variable_get(:@parameters)
      Array(params).join("\n")[/pbBridge(On|Off)/i]
    end
  rescue
    return false
  end

  def empyrean_bridge_events(game_map)
    return [] if !game_map || !game_map.respond_to?(:events)
    game_map.events.values.select do |event|
      next false if !event
      list = event.respond_to?(:list) ? event.list : event.instance_variable_get(:@list)
      empyrean_bridge_command_list?(list)
    end
  rescue
    return []
  end

  def empyrean_bridge_on_event_at?(game_map, x, y)
    return false if !game_map || !game_map.respond_to?(:events)
    game_map.events.values.any? do |event|
      next false if !event
      ex = event.respond_to?(:x) ? event.x : event.instance_variable_get(:@x)
      ey = event.respond_to?(:y) ? event.y : event.instance_variable_get(:@y)
      next false if ex.to_i != x.to_i || ey.to_i != y.to_i
      list = event.respond_to?(:list) ? event.list : event.instance_variable_get(:@list)
      Array(list).any? do |command|
        code = command.respond_to?(:code) ? command.code : command.instance_variable_get(:@code)
        next false if code.to_i != 355 && code.to_i != 655
        params = command.respond_to?(:parameters) ? command.parameters : command.instance_variable_get(:@parameters)
        Array(params).join("\n")[/pbBridgeOn/i]
      end
    end
  rescue
    return false
  end

  def empyrean_bridge_surface_tile_ids_at(game_map, x, y)
    return [] if !game_map || !game_map.respond_to?(:valid?) || !game_map.valid?(x, y)
    data = game_map.respond_to?(:data) ? game_map.data : game_map.instance_variable_get(:@map).data
    passages = game_map.respond_to?(:passages) ? game_map.passages : game_map.instance_variable_get(:@passages)
    priorities = game_map.respond_to?(:priorities) ? game_map.priorities : game_map.instance_variable_get(:@priorities)
    terrain_tags = game_map.respond_to?(:terrain_tags) ? game_map.terrain_tags : game_map.instance_variable_get(:@terrain_tags)
    return [] if !data || !passages || !priorities || !terrain_tags
    ids = []
    [2, 1, 0].each do |layer|
      tile_id = data[x, y, layer] rescue nil
      next if tile_id.nil? || tile_id.to_i <= 0
      tag_value = terrain_tags[tile_id] rescue 0
      translated = empyrean_translate_terrain_tag(tag_value)
      terrain = GameData::TerrainTag.try_get(translated) if defined?(GameData) && defined?(GameData::TerrainTag)
      if terrain && terrain.respond_to?(:bridge) && terrain.bridge
        ids << tile_id.to_i
        next
      end
      next if terrain && terrain.respond_to?(:ignore_passability) && terrain.ignore_passability
      next if terrain && terrain.respond_to?(:id) && terrain.id != :None && translated.to_i != 0
      passage = passages[tile_id] rescue nil
      priority = priorities[tile_id] rescue 0
      next if passage.nil?
      ids << tile_id.to_i if priority.to_i > 0 && (passage.to_i & 0x0f) == 0
    end
    return ids.uniq
  rescue
    return []
  end

  def empyrean_prepare_bridge_cache!(game_map)
    return false if !game_map || !empyrean_map?(game_map.map_id)
    map_id = game_map.map_id
    @empyrean_bridge_tile_ids_by_map_id ||= {}
    @empyrean_bridge_coords_by_map_id ||= {}
    return true if @empyrean_bridge_tile_ids_by_map_id[map_id] &&
                   @empyrean_bridge_coords_by_map_id[map_id]
    tile_ids = {}
    coords = {}
    queue = []
    radius = EMPYREAN_BRIDGE_SCAN_RADIUS
    empyrean_bridge_events(game_map).each do |event|
      ex = event.respond_to?(:x) ? event.x : event.instance_variable_get(:@x)
      ey = event.respond_to?(:y) ? event.y : event.instance_variable_get(:@y)
      (-radius..radius).each do |dx|
        (-radius..radius).each do |dy|
          x = ex.to_i + dx
          y = ey.to_i + dy
          ids = empyrean_bridge_surface_tile_ids_at(game_map, x, y)
          next if ids.empty?
          key = "#{x},#{y}"
          next if coords[key]
          coords[key] = true
          ids.each { |tile_id| tile_ids[tile_id] = true }
          queue << [x, y]
        end
      end
    end
    checked = 0
    until queue.empty? || checked > 1200
      checked += 1
      x, y = queue.shift
      [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
        nx = x + dx
        ny = y + dy
        key = "#{nx},#{ny}"
        next if coords[key]
        ids = empyrean_bridge_surface_tile_ids_at(game_map, nx, ny)
        next if ids.empty?
        coords[key] = true
        ids.each { |tile_id| tile_ids[tile_id] = true }
        queue << [nx, ny]
      end
    end
    @empyrean_bridge_tile_ids_by_map_id[map_id] = tile_ids
    @empyrean_bridge_coords_by_map_id[map_id] = coords
    game_map.instance_variable_set(:@tef_empyrean_bridge_tile_ids, tile_ids)
    game_map.instance_variable_set(:@tef_empyrean_bridge_coords, coords)
    log("[empyrean] bridge cache map=#{map_id} tiles=#{tile_ids.length} coords=#{coords.length}") if respond_to?(:log) && !tile_ids.empty?
    return true
  rescue => e
    log("[empyrean] bridge cache failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def empyrean_bridge_tile_id?(tile_id, map_id = nil)
    return false if tile_id.nil?
    current_map_id = map_id
    current_map_id = $game_map.map_id if current_map_id.nil? && defined?($game_map) && $game_map && $game_map.respond_to?(:map_id)
    return false if !current_map_id || !empyrean_map?(current_map_id)
    @empyrean_bridge_tile_ids_by_map_id ||= {}
    empyrean_prepare_bridge_cache!($game_map) if defined?($game_map) && $game_map &&
                                                 $game_map.respond_to?(:map_id) &&
                                                 $game_map.map_id == current_map_id &&
                                                 !@empyrean_bridge_tile_ids_by_map_id[current_map_id]
    cache = @empyrean_bridge_tile_ids_by_map_id[current_map_id]
    return cache && cache[tile_id.to_i] ? true : false
  rescue
    return false
  end

  def empyrean_bridge_surface_coord?(game_map, x, y)
    return false if !game_map || !game_map.respond_to?(:valid?) || !game_map.valid?(x, y)
    empyrean_prepare_bridge_cache!(game_map)
    coords = game_map.instance_variable_get(:@tef_empyrean_bridge_coords)
    return true if coords && coords["#{x},#{y}"]
    return !empyrean_bridge_surface_tile_ids_at(game_map, x, y).empty?
  rescue
    return false
  end

  def empyrean_set_bridge_height!(height = 2)
    return true if !defined?($PokemonGlobal) || !$PokemonGlobal
    value = integer(height, 2) if respond_to?(:integer)
    value = height.to_i if value.nil?
    value = 2 if value <= 0
    $PokemonGlobal.bridge = value if $PokemonGlobal.respond_to?(:bridge=)
    return true
  rescue
    return true
  end

  def empyrean_clear_bridge_height!
    $PokemonGlobal.bridge = 0 if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:bridge=)
    return true
  rescue
    return true
  end

  def empyrean_prepare_bridge_for_step!(game_map, x, y, d)
    return false if !empyrean_map?(game_map.map_id)
    return false if ![2, 4, 6, 8].include?(d.to_i)
    new_x = x + (d.to_i == 6 ? 1 : d.to_i == 4 ? -1 : 0)
    new_y = y + (d.to_i == 2 ? 1 : d.to_i == 8 ? -1 : 0)
    if empyrean_bridge_on_event_at?(game_map, x, y) ||
       empyrean_bridge_on_event_at?(game_map, new_x, new_y) ||
       empyrean_bridge_surface_coord?(game_map, x, y) ||
       empyrean_bridge_surface_coord?(game_map, new_x, new_y)
      return empyrean_set_bridge_height!(2)
    end
    return false
  rescue
    return false
  end

  def empyrean_bridge_step_passable?(game_map, x, y, d)
    return false if !empyrean_map?(game_map.map_id)
    return false if !defined?($PokemonGlobal) || !$PokemonGlobal || !$PokemonGlobal.respond_to?(:bridge) || $PokemonGlobal.bridge.to_i <= 0
    return false if ![2, 4, 6, 8].include?(d.to_i)
    new_x = x + (d.to_i == 6 ? 1 : d.to_i == 4 ? -1 : 0)
    new_y = y + (d.to_i == 2 ? 1 : d.to_i == 8 ? -1 : 0)
    return empyrean_bridge_surface_coord?(game_map, x, y) ||
           empyrean_bridge_surface_coord?(game_map, new_x, new_y)
  rescue
    return false
  end

  def gadir_deluxe_active_now?(map_id = nil)
    return !active_project_expansion_id(gadir_deluxe_expansion_ids, map_id).nil?
  end

  def hollow_woods_active_now?(map_id = nil)
    return !active_project_expansion_id(hollow_woods_expansion_ids, map_id).nil?
  end

  def infinity_active_now?(map_id = nil)
    return !active_project_expansion_id(infinity_expansion_ids, map_id).nil?
  end

  def hollow_woods_game_mode
    @hollow_woods_game_mode = HollowWoodsGameMode.new if !@hollow_woods_game_mode.is_a?(HollowWoodsGameMode)
    return @hollow_woods_game_mode
  rescue
    return HollowWoodsGameMode.new
  end

  def hollow_woods_apply_game_mode_defaults!(source = nil)
    mode = hollow_woods_game_mode
    mode.levelcap = 0
    mode.randomizer = 0
    mode.nuzlocke = 0
    mode.autoheal = 0
    if defined?($GameMode)
      $GameMode = mode if $GameMode.nil? || !$GameMode.respond_to?(:randomizer)
    else
      $GameMode = mode
    end
    meta = new_project_metadata(HOLLOW_WOODS_EXPANSION_ID) || new_project_metadata
    if meta
      meta["hollow_woods_game_mode_source"] = source.to_s if source
      meta["hollow_woods_game_mode_ready"] = true
    end
    log("[hollow_woods] applied host-safe game mode defaults#{source ? " from #{source}" : ""}") if respond_to?(:log)
    return mode
  rescue => e
    log("[hollow_woods] game mode default setup failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def hollow_woods_watch_tv!(*_args)
    hollow_woods_apply_game_mode_defaults!(:watch_tv) if respond_to?(:hollow_woods_apply_game_mode_defaults!)
    pbMessage(_INTL("The TV is showing a quiet local broadcast.")) if defined?(pbMessage)
    return true
  rescue => e
    log("[hollow_woods] TV event skipped safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def hollow_woods_starter_species(species_ref)
    raw = species_ref.to_s.upcase.gsub(/[^A-Z0-9_]/, "")
    raw = "REMORAID" if ["REMOIRAID", "REMOIRAD"].include?(raw)
    raw = "VULPIX" if raw.empty?
    resolved = resolve_expansion_species(HOLLOW_WOODS_EXPANSION_ID, raw.to_sym) if respond_to?(:resolve_expansion_species)
    resolved ||= raw.to_sym
    data = GameData::Species.try_get(resolved) rescue nil
    data ||= GameData::Species.try_get(raw.to_sym) rescue nil
    return data.species if data && data.respond_to?(:species)
    return data.id if data && data.respond_to?(:id)
    fallback = GameData::Species.try_get(:VULPIX) rescue nil
    return fallback.species if fallback && fallback.respond_to?(:species)
    return :VULPIX
  rescue
    return :VULPIX
  end

  def hollow_woods_species_name(species)
    data = GameData::Species.try_get(species) rescue nil
    return data.name if data && data.respond_to?(:name)
    return species.to_s.split("_").map { |part| part.capitalize }.join(" ")
  rescue
    return species.to_s
  end

  def hollow_woods_choose_starter!(*species_refs)
    hollow_woods_apply_game_mode_defaults!(:starter_selection) if respond_to?(:hollow_woods_apply_game_mode_defaults!)
    species = Array(species_refs).flatten.map { |entry| hollow_woods_starter_species(entry) }.compact
    species = [:VULPIX, :REMORAID, :COTTONEE] if species.empty?
    species.uniq!
    names = species.map { |entry| hollow_woods_species_name(entry) }
    cancel_index = names.length
    choice = 0
    if defined?(pbMessage)
      choice = pbMessage(_INTL("Which Pokemon will travel with you?"), names + [_INTL("Cancel")], cancel_index, nil, 0)
    end
    return nil if choice.nil? || choice.to_i < 0 || choice.to_i >= species.length
    selected = species[choice.to_i]
    result = false
    if defined?(pbAddPokemon)
      result = pbAddPokemon(selected, 5)
    elsif defined?(pbAddPokemonSilent)
      result = pbAddPokemonSilent(selected, 5)
    end
    meta = new_project_metadata(HOLLOW_WOODS_EXPANSION_ID) || new_project_metadata
    if meta
      meta["hollow_woods_starter_species"] = selected.to_s
      meta["hollow_woods_starter_received"] = result ? true : false
    end
    log("[hollow_woods] starter selection #{selected} result=#{result}") if respond_to?(:log)
    return selected
  rescue => e
    log("[hollow_woods] starter selection skipped safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def infinity_check_roaming!(event_id = nil, *_args)
    map_id = integer(($game_map.map_id rescue 0), 0) if respond_to?(:integer)
    map_id = ($game_map.map_id rescue 0).to_i if map_id.nil?
    return false if !infinity_active_now?(map_id)
    if defined?($PokemonGlobal) && $PokemonGlobal
      $PokemonGlobal.roamPosition = {} if $PokemonGlobal.respond_to?(:roamPosition=) &&
                                          !$PokemonGlobal.roamPosition.is_a?(Hash)
      $PokemonGlobal.roamPokemon = [] if $PokemonGlobal.respond_to?(:roamPokemon=) &&
                                        !$PokemonGlobal.roamPokemon.is_a?(Array)
      $PokemonGlobal.roamedAlready = false if $PokemonGlobal.respond_to?(:roamedAlready=) &&
                                             $PokemonGlobal.roamedAlready.nil?
    end
    @infinity_roaming_skip_logged ||= {}
    key = [map_id, event_id || :global]
    if !@infinity_roaming_skip_logged[key]
      @infinity_roaming_skip_logged[key] = true
      suffix = event_id ? " event #{event_id}" : ""
      log("[infinity] optional pbCheckRoaming skipped safely on map #{map_id}#{suffix}") if respond_to?(:log)
    end
    return false
  rescue => e
    log("[infinity] roaming check skipped safely after error: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def gadir_deluxe_switch_active?(expansion_id, switch_id)
    expansion = canonical_new_project_id(expansion_id)
    begin
      return true if expansion_switch_value(expansion, switch_id)
    rescue
    end
    if defined?($game_switches) && $game_switches &&
       $game_switches.respond_to?(:tef_compat_original_get)
      return $game_switches.tef_compat_original_get(integer(switch_id, 0)) == true
    end
    return false
  rescue
    return false
  end

  def gadir_deluxe_set_switch!(expansion_id, switch_id, value = true)
    expansion = canonical_new_project_id(expansion_id)
    set_expansion_switch_value(expansion, switch_id, value)
    $game_map.need_refresh = true if defined?($game_map) && $game_map && $game_map.respond_to?(:need_refresh=)
    return value
  rescue
    return value
  end

  def new_project_map_interpreter_running?
    interpreter = nil
    interpreter = $game_system.map_interpreter if defined?($game_system) &&
                                                 $game_system &&
                                                 $game_system.respond_to?(:map_interpreter)
    return false if !interpreter
    return interpreter.running? if interpreter.respond_to?(:running?)
    return false
  rescue
    return false
  end

  def new_project_message_or_transfer_busy?
    return false if !defined?($game_temp) || !$game_temp
    return true if $game_temp.respond_to?(:message_window_showing) && $game_temp.message_window_showing
    return true if $game_temp.respond_to?(:player_transferring) && $game_temp.player_transferring
    return true if $game_temp.respond_to?(:transition_processing) && $game_temp.transition_processing
    return false
  rescue
    return false
  end

  def reset_gadir_deluxe_intro_recovery_counter!(metadata = nil)
    metadata["gadir_intro_idle_frames"] = 0 if metadata
    @gadir_deluxe_intro_idle_frames = 0
    return true
  rescue
    @gadir_deluxe_intro_idle_frames = 0
    return true
  end

  def gadir_deluxe_complete_intro_recovery!(expansion_id)
    expansion = canonical_new_project_id(expansion_id)
    return false if expansion.to_s.empty?
    [
      GADIR_DELUXE_SWITCH_CHAPI_INTRO,
      GADIR_DELUXE_SWITCH_FININTRO,
      GADIR_DELUXE_SWITCH_ENCIENDE,
      GADIR_DELUXE_SWITCH_ULTIMO_PARCHE
    ].each { |switch_id| gadir_deluxe_set_switch!(expansion, switch_id, true) }
    with_runtime_context(expansion) do
      if defined?($PokemonBag) && $PokemonBag && $PokemonBag.respond_to?(:pbStoreItem)
        $PokemonBag.pbStoreItem(:MISIONARIO) rescue nil
      end
    end
    $game_temp.player_transferring = false if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:player_transferring=)
    $game_temp.transition_processing = false if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:transition_processing=)
    $game_temp.transition_name = "" if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:transition_name=)
    clear_stuck_screen_effects!("gadir_deluxe intro recovery", true) if respond_to?(:clear_stuck_screen_effects!)
    apply_host_player_visuals!(expansion) if respond_to?(:apply_host_player_visuals!)
    target_map = translate_expansion_map_id(expansion, GADIR_DELUXE_HOME_LOCAL_MAP_ID)
    log("[gadir_deluxe] recovered stalled character intro; transferring to bedroom start") if respond_to?(:log)
    safe_transfer_to_anchor({
      :map_id    => target_map,
      :x         => 9,
      :y         => 8,
      :direction => 6
    }, {
      :source            => :story_transfer,
      :expansion_id      => expansion,
      :allow_story_state => false,
      :immediate         => true,
      :auto_rescue       => false
    })
  rescue => e
    log("[gadir_deluxe] intro recovery failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def gadir_deluxe_intro_recovery_update!
    return false if !defined?($game_map) || !$game_map
    map_id = integer($game_map.map_id, 0)
    expansion = active_project_expansion_id(gadir_deluxe_expansion_ids, map_id)
    return false if expansion.to_s.empty?
    local_map = local_map_id_for(expansion, map_id) rescue map_id
    metadata = new_project_metadata(expansion)
    if integer(local_map, 0) != GADIR_DELUXE_INTRO_LOCAL_MAP_ID
      reset_gadir_deluxe_intro_recovery_counter!(metadata)
      return false
    end
    started = gadir_deluxe_switch_active?(expansion, GADIR_DELUXE_SWITCH_CHAPI_INTRO)
    finished = begin
      expansion_switch_value(expansion, GADIR_DELUXE_SWITCH_FININTRO)
    rescue
      false
    end
    if !started || finished
      reset_gadir_deluxe_intro_recovery_counter!(metadata)
      return false
    end
    if new_project_map_interpreter_running? || new_project_message_or_transfer_busy?
      reset_gadir_deluxe_intro_recovery_counter!(metadata)
      return false
    end
    frames = metadata ? integer(metadata["gadir_intro_idle_frames"], 0) : integer(@gadir_deluxe_intro_idle_frames, 0)
    frames += 1
    metadata["gadir_intro_idle_frames"] = frames if metadata
    @gadir_deluxe_intro_idle_frames = frames
    return false if frames < GADIR_DELUXE_INTRO_IDLE_RECOVERY_FRAMES
    reset_gadir_deluxe_intro_recovery_counter!(metadata)
    return gadir_deluxe_complete_intro_recovery!(expansion)
  rescue => e
    log("[gadir_deluxe] intro recovery update failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def new_project_identity_active_now?(map_id = nil)
    return new_project_active_now?(map_id)
  end

  def new_project_active_now?(map_id = nil)
    return !active_project_expansion_id(new_project_expansion_ids, map_id).nil?
  end

  def current_new_project_expansion_id(map_id = nil)
    return active_project_expansion_id(new_project_expansion_ids, map_id)
  end

  def bare_species_constant_resolution_active?
    expansion = active_project_expansion_id(new_project_expansion_ids)
    expansion ||= current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    return false if expansion.to_s.empty?
    return false if defined?(HOST_EXPANSION_ID) && expansion.to_s == HOST_EXPANSION_ID.to_s
    return true
  rescue
    return false
  end

  def project_root_path(project_id, fallback_folder, aliases = [])
    info = external_projects[project_id] rescue nil
    root = info[:root].to_s if info.is_a?(Hash)
    return root if !root.to_s.empty? && File.directory?(root)
    ([fallback_folder] + Array(aliases)).each do |folder|
      path = File.join("C:/Games", folder.to_s)
      return path if File.directory?(path)
    end
    return root if !root.to_s.empty?
    return nil
  rescue
    return nil
  end

  def opalo_root_path
    return project_root_path(OPALO_EXPANSION_ID, "Opalo", ["Pokemon Opalo"])
  end

  def opalo_translation_path
    root = opalo_root_path
    return nil if root.to_s.empty?
    ["intl.txt", File.join("Data", "english.txt"), File.join("Data", "intl.txt")].each do |relative|
      path = File.join(root, relative)
      return path if File.file?(path)
    end
    return nil
  rescue
    return nil
  end

  def opalo_compat_asset_root
    return File.join(framework_root, "compat_assets", OPALO_EXPANSION_ID)
  rescue
    return File.expand_path("./Mods/#{FRAMEWORK_MOD_ID}/compat_assets/#{OPALO_EXPANSION_ID}")
  end

  def opalo_asset_context_active?
    expansion = current_asset_expansion_id if respond_to?(:current_asset_expansion_id)
    expansion = current_runtime_expansion_id if expansion.to_s.empty? && respond_to?(:current_runtime_expansion_id)
    expansion = current_map_expansion_id if expansion.to_s.empty? && respond_to?(:current_map_expansion_id)
    return opalo_expansion_id?(expansion) if !expansion.to_s.empty?
    return opalo_active_now?
  rescue
    return false
  end

  def opalo_picture_override_path(logical_path, extensions = [])
    return nil if !opalo_asset_context_active?
    normalized = logical_path.to_s.gsub("\\", "/").sub(/\A\.\//, "").sub(%r{\A/+}, "")
    return nil if normalized.empty? || normalized.end_with?("/")
    extname = File.extname(normalized)
    without_ext = extname.empty? ? normalized : normalized[0...-extname.length]
    return nil if without_ext !~ %r{\AGraphics/Pictures/([^/]+)\z}i
    picture_name = $1.to_s
    return nil if !OPALO_COMPAT_PICTURE_OVERRIDES.include?(picture_name)
    exts = extensions.is_a?(Array) ? extensions : [extensions]
    exts = [".png"] if exts.empty? || exts.all? { |ext| ext.to_s.empty? }
    candidates = []
    candidates << normalized if !extname.empty?
    exts.each do |ext|
      ext = ext.to_s
      next if ext.empty?
      candidates << "#{without_ext}#{ext}"
    end
    candidates.uniq.each do |candidate|
      path = File.join(opalo_compat_asset_root, *candidate.split("/"))
      return path if File.file?(path)
    end
    return nil
  rescue => e
    log("[opalo] picture override failed for #{logical_path}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def opalo_lens_event?(event)
    return false if !event
    map_id = event.instance_variable_get(:@map_id) rescue nil
    return false if !opalo_active_now?(map_id)
    name = event.respond_to?(:name) ? event.name.to_s : ""
    return name.include?("#EOT")
  rescue
    return false
  end

  def opalo_lens_show_event?(event)
    name = event.respond_to?(:name) ? event.name.to_s : ""
    return name[/SHOW/i] != nil
  rescue
    return false
  end

  def opalo_lens_hide_event?(event)
    name = event.respond_to?(:name) ? event.name.to_s : ""
    return name[/HIDE/i] != nil
  rescue
    return false
  end

  def opalo_lens_event_limit_opacity(event, fallback)
    name = event.respond_to?(:name) ? event.name.to_s : ""
    value = name[/(\d+)/, 1]
    return integer(value, fallback) if value
    return fallback
  rescue
    return fallback
  end

  def opalo_lens_active?
    return false if !defined?($scene) || !$scene || !$scene.respond_to?(:eye_of_truth_time)
    return integer($scene.eye_of_truth_time, 0) > 0
  rescue
    return false
  end

  def opalo_lens_event_in_range?(event)
    return false if !opalo_lens_active?
    return false if !defined?($game_player) || !$game_player
    distance_x = integer(event.x, 0) - integer($game_player.x, 0)
    distance_y = integer(event.y, 0) - integer($game_player.y, 0)
    return Math.sqrt((distance_x * distance_x) + (distance_y * distance_y)) <= OPALO_LENS_OF_TRUTH_RANGE
  rescue
    return false
  end

  def opalo_event_under_player?(event)
    return false if !defined?($game_player) || !$game_player
    return event.respond_to?(:at_coordinate?) && event.at_coordinate?($game_player.x, $game_player.y)
  rescue
    return false
  end

  def apply_opalo_lens_event_state!(event, immediate = false)
    return false if !opalo_lens_event?(event)
    in_range = opalo_lens_event_in_range?(event)
    current = integer(event.opacity, 255)
    target = current
    if opalo_lens_show_event?(event)
      target = in_range ? opalo_lens_event_limit_opacity(event, 255) : 0
      event.through = !in_range || opalo_event_under_player?(event) if event.respond_to?(:through=)
    elsif opalo_lens_hide_event?(event)
      target = in_range ? opalo_lens_event_limit_opacity(event, 0) : 255
      event.through = in_range || opalo_event_under_player?(event) if event.respond_to?(:through=)
    else
      return false
    end
    if immediate
      event.opacity = target if event.respond_to?(:opacity=)
    elsif event.respond_to?(:opacity=)
      step = 26
      event.opacity = [[current + step, target].min, 255].min if current < target
      event.opacity = [[current - step, target].max, 0].max if current > target
    end
    return true
  rescue => e
    log("[opalo] Lens of Truth event shim failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def activate_opalo_lens_of_truth!
    return false if !opalo_active_now?
    return false if !defined?($scene) || !$scene
    return false if !$scene.respond_to?(:eye_of_truth_time=)
    frames = (Graphics.frame_rate rescue 40).to_i
    frames = 40 if frames <= 0
    $scene.eye_of_truth_time = OPALO_LENS_OF_TRUTH_DURATION_SECONDS * frames
    return true
  rescue
    return false
  end

  def realidea_root_path
    return project_root_path(REALIDEA_EXPANSION_ID, "Realidea", ["Pokemon Realidea", "Pokemon Realidea System"])
  end

  def realidea_translation_path
    root = realidea_root_path
    return nil if root.to_s.empty?
    [File.join("Data", "English.dat"), File.join("Data", "english.dat")].each do |relative|
      path = File.join(root, relative)
      return path if File.file?(path)
    end
    return nil
  rescue
    return nil
  end

  def read_utf8_lines(path)
    return [] if path.to_s.empty? || !File.file?(path)
    lines = []
    File.open(path, "rb") do |file|
      file.each_line do |line|
        text = line.to_s.dup
        text.force_encoding("UTF-8") if text.respond_to?(:force_encoding)
        text = text.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "")
        text.gsub!(/\r?\n\z/, "")
        lines << text
      end
    end
    return lines
  rescue => e
    log("[translation] failed to read #{path}: #{e.class}: #{e.message}") if respond_to?(:log)
    return []
  end

  def opalo_translation_key(text)
    normalized = text.to_s.dup
    normalized.gsub!("\r", "")
    normalized.gsub!(/\\n/i, " ")
    normalized.gsub!("\n", " ")
    normalized.gsub!("\001", "")
    normalized.gsub!(/[ \t]+/, " ")
    normalized.strip!
    return normalized.to_s
  rescue
    return text.to_s
  end

  def opalo_translation_key_variants(text)
    base = opalo_translation_key(text)
    return [] if base.empty?
    variants = [base]
    stripped_window = base.gsub(/\A(?:\\w\[[^\]]+\]\s*)+/i, "").strip
    variants << stripped_window if !stripped_window.empty?
    stripped_controls = stripped_window.gsub(/\\[A-Za-z]+\[[^\]]*\]/, "").strip
    variants << stripped_controls if !stripped_controls.empty?
    compacted = stripped_window.gsub(/\s+/, " ").strip
    variants << compacted if !compacted.empty?
    return variants.compact.reject { |entry| entry.to_s.empty? }.uniq
  rescue
    value = opalo_translation_key(text)
    return value.empty? ? [] : [value]
  end

  def opalo_decode_translation_markup(text)
    decoded = text.to_s.dup
    decoded.gsub!("<<n>>", "\n")
    decoded.gsub!("<<N>>", "\n")
    decoded.gsub!(/\\n/i, "\n")
    return decoded
  rescue
    return text.to_s
  end

  def opalo_collect_translation_entry!(catalog, source, translated, scope = nil)
    keys = opalo_translation_key_variants(source)
    return if keys.empty?
    text = opalo_decode_translation_markup(translated)
    return if text.to_s.empty?
    keys.each do |key|
      if scope
        catalog[:maps][scope] ||= {}
        catalog[:maps][scope][key] = text
      else
        catalog[:script][key] = text
      end
      catalog[:all][key] = text if !catalog[:all].has_key?(key)
    end
  rescue => e
    log("[opalo] translation entry failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def opalo_translation_catalog
    @opalo_translation_catalog ||= begin
      catalog = { :loaded => true, :maps => {}, :script => {}, :all => {} }
      path = opalo_translation_path
      pending = nil
      current_scope = nil
      read_utf8_lines(path).each do |line|
        next if line.start_with?("#")
        if line[/\A\[Map(\d+)\]\z/i]
          current_scope = integer($1, 0)
          pending = nil
          next
        elsif line[/\A\[(\d+)\]\z/i]
          current_scope = nil
          pending = nil
          next
        end
        next if line.empty? && pending.nil?
        if pending.nil?
          pending = line
          next
        end
        opalo_collect_translation_entry!(catalog, pending, line, current_scope)
        pending = nil
      end
      catalog
    end
    return @opalo_translation_catalog
  rescue => e
    log("[opalo] translation catalog load failed: #{e.class}: #{e.message}") if respond_to?(:log)
    @opalo_translation_catalog = { :loaded => true, :maps => {}, :script => {}, :all => {} }
    return @opalo_translation_catalog
  end

  def opalo_current_local_map_id(map_id = nil)
    current_map_id = integer(map_id || ($game_map.map_id rescue 0), 0)
    return 0 if current_map_id <= 0
    expansion = active_project_expansion_id(opalo_expansion_ids, current_map_id) || OPALO_EXPANSION_ID
    return local_map_id_for(expansion, current_map_id) if respond_to?(:local_map_id_for)
    return current_map_id
  rescue
    return 0
  end

  def opalo_metadata(expansion_id = nil)
    expansion = expansion_id.to_s
    expansion = active_project_expansion_id(opalo_expansion_ids) if expansion.empty?
    expansion = OPALO_EXPANSION_ID if expansion.to_s.empty?
    return new_project_metadata(expansion) if respond_to?(:new_project_metadata)
    state = state_for(expansion) rescue nil
    return nil if !state || !state.respond_to?(:metadata)
    state.metadata = {} if state.metadata.nil? && state.respond_to?(:metadata=)
    return state.metadata if state.metadata.is_a?(Hash)
    return nil
  rescue
    return nil
  end

  def opalo_valid_starter_choice?(choice)
    return [1, 2, 3].include?(integer(choice, 0))
  rescue
    return false
  end

  def remember_opalo_starter_choice!(choice, expansion_id = nil)
    selected = integer(choice, 0)
    return nil if !opalo_valid_starter_choice?(selected)
    meta = opalo_metadata(expansion_id)
    meta["opalo_starter_choice"] = selected if meta
    return selected
  rescue
    return nil
  end

  def remembered_opalo_starter_choice(expansion_id = nil)
    meta = opalo_metadata(expansion_id)
    choice = integer(meta && meta["opalo_starter_choice"], 0)
    return choice if opalo_valid_starter_choice?(choice)
    return 0
  rescue
    return 0
  end

  def opalo_repair_starter_room_state!(map_id = nil, reason = "runtime")
    current_map_id = integer(map_id || ($game_map.map_id rescue 0), 0)
    return false if current_map_id <= 0 || !opalo_active_now?(current_map_id)
    local_map = opalo_current_local_map_id(current_map_id)
    starter_maps = [
      OPALO_STARTER_TOWN_LOCAL_MAP_ID,
      OPALO_STARTER_ROOM_LOCAL_MAP_ID,
      OPALO_STARTER_ROUTE_LOCAL_MAP_ID
    ]
    return false if !starter_maps.include?(local_map)
    return false if !defined?($game_switches) || !$game_switches || !defined?($game_variables) || !$game_variables

    expansion = active_project_expansion_id(opalo_expansion_ids, current_map_id) || OPALO_EXPANSION_ID
    changed = false
    choice = integer($game_variables[OPALO_STARTER_CHOICE_VARIABLE], 0)
    remember_opalo_starter_choice!(choice, expansion) if opalo_valid_starter_choice?(choice)

    fled = $game_switches[OPALO_STARTER_FLED_SWITCH] == true
    hidden = $game_switches[OPALO_STARTER_HIDDEN_SWITCH] == true
    chasing = $game_switches[OPALO_STARTER_CHASE_SWITCH] == true
    poochyena_seen = $game_switches[OPALO_STARTER_POOCHYENA_SWITCH] == true
    battle_done = $game_switches[OPALO_STARTER_BATTLE_DONE_SWITCH] == true
    professor_seen = $game_switches[OPALO_STARTER_PROFESSOR_SWITCH] == true
    starter_story_started = fled || hidden || chasing || poochyena_seen || battle_done || professor_seen
    if starter_story_started && $game_switches[OPALO_STARTER_SELECTED_SWITCH] != true
      $game_switches[OPALO_STARTER_SELECTED_SWITCH] = true
      changed = true
    end

    if starter_story_started && !opalo_valid_starter_choice?(choice)
      remembered = remembered_opalo_starter_choice(expansion)
      remembered = 1 if !opalo_valid_starter_choice?(remembered)
      $game_variables[OPALO_STARTER_CHOICE_VARIABLE] = remembered
      remember_opalo_starter_choice!(remembered, expansion)
      changed = true
    end

    if changed
      meta = opalo_metadata(expansion)
      if meta
        meta["opalo_starter_state_repaired"] = {
          "map_id"     => current_map_id,
          "local_map"  => local_map,
          "reason"     => reason.to_s,
          "choice"     => integer($game_variables[OPALO_STARTER_CHOICE_VARIABLE], 0),
          "updated_at" => (timestamp_string if respond_to?(:timestamp_string))
        }
      end
      $game_map.need_refresh = true if defined?($game_map) && $game_map && $game_map.respond_to?(:need_refresh=)
      log("[opalo] repaired starter room state on map #{current_map_id} (local #{local_map}) via #{reason}; choice=#{$game_variables[OPALO_STARTER_CHOICE_VARIABLE]}") if respond_to?(:log)
    end
    return changed
  rescue => e
    log("[opalo] starter room repair failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def opalo_translate_text(text, map_id = nil)
    source = text.to_s
    return source if source.empty?
    trailer = source[/\001+\z/].to_s
    lookup_source = trailer.empty? ? source : source[0, source.length - trailer.length]
    prefix = lookup_source[/\A(?:\\w\[[^\]]+\]\s*)+/i].to_s
    keys = opalo_translation_key_variants(lookup_source)
    return source if keys.empty?
    catalog = opalo_translation_catalog
    local_map_id = opalo_current_local_map_id(map_id)
    translated = nil
    if catalog[:maps].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:maps][local_map_id][key] if translated.nil? && catalog[:maps][local_map_id].is_a?(Hash)
        translated = catalog[:maps][0][key] if translated.nil? && catalog[:maps][0].is_a?(Hash)
      end
    end
    if translated.nil? && catalog[:script].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:script][key]
        break if translated
      end
    end
    if translated.nil? && catalog[:all].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:all][key]
        break if translated
      end
    end
    return source if translated.nil? || translated.to_s.empty?
    result = opalo_decode_translation_markup(translated)
    result = "#{prefix}#{result}" if !prefix.empty? && result !~ /\A#{Regexp.escape(prefix)}/
    return "#{result}#{trailer}"
  rescue => e
    log("[opalo] translation lookup failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return text.to_s
  end

  def format_translation_text(template, values)
    result = template.to_s.dup
    Array(values).each_with_index do |value, index|
      result.gsub!(/\{#{index + 1}\}/, value.to_s)
    end
    return result
  rescue
    return template.to_s
  end

  def translate_opalo_commands(commands, map_id = nil)
    return commands if !commands
    return Array(commands).map { |entry| opalo_translate_text(entry, map_id) }
  rescue
    return commands
  end

  def realidea_current_local_map_id(map_id = nil)
    current_map_id = integer(map_id || ($game_map.map_id rescue 0), 0)
    return 0 if current_map_id <= 0
    return local_map_id_for(REALIDEA_EXPANSION_ID, current_map_id) if respond_to?(:local_map_id_for)
    return current_map_id
  rescue
    return 0
  end

  def realidea_fuzzy_translation_key(text)
    normalized = text.to_s.dup
    normalized.force_encoding("UTF-8") if normalized.respond_to?(:force_encoding)
    normalized = normalized.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "") if normalized.respond_to?(:encode)
    normalized.gsub!(/&quot;/i, "\"")
    normalized.gsub!(/\r/, " ")
    normalized.gsub!(/\\[Nn]/, " ")
    normalized.gsub!(/\n/, " ")
    normalized.gsub!(/\001/, " ")
    normalized.gsub!(/\\(?:tg|xn)\[([^\]]+)\]/i, " \\1 ")
    normalized.gsub!(/\\[A-Za-z]+\[[^\]]*\]/, " ")
    normalized.gsub!(/<\/?[^>]+>/, " ")
    normalized.gsub!(/[\"'\.,;:!\?\(\)\[\]\{\}]+/, " ")
    normalized.gsub!(/\s+/, " ")
    normalized.strip!
    normalized.downcase!
    return normalized.to_s
  rescue
    return text.to_s
  end

  def realidea_common_prefix_length(left, right)
    left = left.to_s
    right = right.to_s
    limit = [left.length, right.length].min
    index = 0
    index += 1 while index < limit && left[index, 1] == right[index, 1]
    return index
  rescue
    return 0
  end

  def realidea_collect_translation_entry!(catalog, source, translated, scope = nil)
    text = opalo_decode_translation_markup(translated)
    return if text.to_s.empty?
    keys = opalo_translation_key_variants(source)
    return if keys.empty?
    keys.each do |key|
      if scope
        catalog[:maps][scope] ||= {}
        catalog[:maps][scope][key] = text
      else
        catalog[:script][key] = text
      end
      catalog[:all][key] = text if !catalog[:all].has_key?(key)
    end
    fuzzy_key = realidea_fuzzy_translation_key(source)
    return if fuzzy_key.empty?
    if scope
      catalog[:map_entries][scope] ||= []
      catalog[:map_entries][scope] << [fuzzy_key, text]
    else
      catalog[:script_entries] << [fuzzy_key, text]
    end
    catalog[:all_entries] << [fuzzy_key, text]
  rescue => e
    log("[realidea] translation entry failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def realidea_collect_translation_entries!(catalog, entries, scope = nil)
    return if !entries || !entries.respond_to?(:each)
    entries.each do |source, translated|
      realidea_collect_translation_entry!(catalog, source, translated, scope)
    end
  rescue => e
    log("[realidea] translation section failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def realidea_translation_catalog
    @realidea_translation_catalog ||= begin
      catalog = {
        :loaded => true,
        :maps => {},
        :script => {},
        :all => {},
        :map_entries => {},
        :script_entries => [],
        :all_entries => []
      }
      path = realidea_translation_path
      if path && File.file?(path)
        data = File.open(path, "rb") { |file| Marshal.load(file) }
        if data.is_a?(Array)
          maps = data[0]
          if maps.is_a?(Array)
            maps.each_with_index do |entries, map_index|
              realidea_collect_translation_entries!(catalog, entries, map_index)
            end
          elsif maps.is_a?(Hash)
            maps.each do |map_index, entries|
              realidea_collect_translation_entries!(catalog, entries, integer(map_index, 0))
            end
          end
          realidea_collect_translation_entries!(catalog, data[23], nil) if data.length > 23
        elsif data.is_a?(Hash)
          data.each do |source, translated|
            realidea_collect_translation_entry!(catalog, source, translated, nil)
          end
        end
      end
      catalog
    end
    return @realidea_translation_catalog
  rescue => e
    log("[realidea] translation catalog load failed: #{e.class}: #{e.message}") if respond_to?(:log)
    @realidea_translation_catalog = {
      :loaded => true,
      :maps => {},
      :script => {},
      :all => {},
      :map_entries => {},
      :script_entries => [],
      :all_entries => []
    }
    return @realidea_translation_catalog
  end

  def realidea_fuzzy_translation(catalog, source, local_map_id)
    source_key = realidea_fuzzy_translation_key(source)
    return nil if source_key.length < 36
    candidates = []
    candidates.concat(catalog[:map_entries][local_map_id] || []) if catalog[:map_entries].is_a?(Hash)
    candidates.concat(catalog[:map_entries][0] || []) if catalog[:map_entries].is_a?(Hash) && local_map_id != 0
    candidates.concat(catalog[:script_entries] || [])
    candidates.concat(catalog[:all_entries] || [])
    best_text = nil
    best_score = 0
    candidates.each do |entry|
      next if !entry || entry.length < 2
      candidate_key = entry[0].to_s
      next if candidate_key.empty?
      score = realidea_common_prefix_length(source_key, candidate_key)
      next if score < 48
      if score > best_score
        best_score = score
        best_text = entry[1]
      end
    end
    return best_text
  rescue
    return nil
  end

  def realidea_translate_text(text, map_id = nil)
    source = text.to_s
    return source if source.empty?
    trailer = source[/\001+\z/].to_s
    lookup_source = trailer.empty? ? source : source[0, source.length - trailer.length]
    keys = opalo_translation_key_variants(lookup_source)
    return source if keys.empty?
    catalog = realidea_translation_catalog
    local_map_id = realidea_current_local_map_id(map_id)
    translated = nil
    if catalog[:maps].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:maps][local_map_id][key] if translated.nil? && catalog[:maps][local_map_id].is_a?(Hash)
        translated = catalog[:maps][0][key] if translated.nil? && catalog[:maps][0].is_a?(Hash)
      end
    end
    if translated.nil? && catalog[:script].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:script][key]
        break if translated
      end
    end
    if translated.nil? && catalog[:all].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:all][key]
        break if translated
      end
    end
    translated = realidea_fuzzy_translation(catalog, lookup_source, local_map_id) if translated.nil?
    return source if translated.nil? || translated.to_s.empty?
    result = opalo_decode_translation_markup(translated)
    return "#{result}#{trailer}"
  rescue => e
    log("[realidea] translation lookup failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return text.to_s
  end

  def cleanup_imported_message_text(text, map_id = nil)
    source = text.to_s
    return source if source.empty?
    trailer = source[/\001+\z/].to_s
    body = trailer.empty? ? source.dup : source[0, source.length - trailer.length]
    body.gsub!(/&quot;/i, "\"")
    body.gsub!(/<br\s*\/?>/i, "\n")
    body.gsub!(/\\(?:tg|xn|dxn|dxor)\[\\[Vv]\[(\d+)\]\]\s*/i) do
      speaker = ($game_variables[$1.to_i] rescue nil).to_s
      speaker = "Someone" if speaker.empty?
      "#{speaker}: "
    end
    body.gsub!(/\\(?:tg|xn|dxn|dxor)\[([^\]]+)\]\s*/i) { "#{$1}: " }
    body.gsub!(/\\(?:pg|pog|sh)/i, "")
    body.gsub!(/\\(?:wtnp|wt|w|l|c|ts|se|me|ch)\[[^\]]*\]/i, "")
    body.gsub!(/\\(?:\.\.\.|\.\.|\.|\||\^)/, "")
    body.gsub!(/<\/?(?:fs|c2|c3|ac|al|ar|b|i|u)[^>]*>/i, "")
    body.gsub!(/<icon=[^>]+>/i, "")
    body.gsub!(/<[^>]+>/, "")
    body.gsub!(/\\[Nn]/, "\n")
    body.gsub!(/[ \t]+\n/, "\n")
    body.gsub!(/\n[ \t]+/, "\n")
    body.gsub!(/[ \t]{2,}/, " ")
    body.strip!
    return "#{body}#{trailer}"
  rescue
    return text.to_s
  end

  def prepare_new_project_text(text, map_id = nil)
    result = text.to_s
    if respond_to?(:anil_active_now?) && anil_active_now?(map_id) && respond_to?(:anil_translate_text)
      result = anil_translate_text(result, map_id)
    elsif realidea_active_now?(map_id)
      result = realidea_translate_text(result, map_id)
    elsif opalo_active_now?(map_id)
      result = opalo_translate_text(result, map_id)
    end
    result = cleanup_imported_message_text(result, map_id) if new_project_active_now?(map_id)
    return result
  rescue
    return text.to_s
  end

  def prepare_new_project_commands(commands, map_id = nil)
    return commands if !commands
    return Array(commands).map { |entry| prepare_new_project_text(entry, map_id) }
  rescue
    return commands
  end

  def host_player_name_for_expansion
    name = ($Trainer.name rescue nil).to_s.strip
    return name if !name.empty?
    return "Player"
  rescue
    return "Player"
  end

  def empyrean_metadata
    expansion = active_project_expansion_id(empyrean_expansion_ids) || EMPYREAN_EXPANSION_ID
    state = state_for(expansion) rescue nil
    return nil if !state || !state.respond_to?(:metadata)
    state.metadata = {} if state.metadata.nil? && state.respond_to?(:metadata=)
    return state.metadata if state.metadata.is_a?(Hash)
    return nil
  rescue
    return nil
  end

  def new_project_metadata(expansion_id = nil)
    expansion = expansion_id.to_s
    expansion = current_new_project_expansion_id if expansion.empty?
    return nil if expansion.to_s.empty?
    state = state_for(expansion) rescue nil
    return nil if !state || !state.respond_to?(:metadata)
    state.metadata = {} if state.metadata.nil? && state.respond_to?(:metadata=)
    return state.metadata if state.metadata.is_a?(Hash)
    return nil
  rescue
    return nil
  end

  def new_project_deep_clone(value)
    return nil if value.nil?
    return Marshal.load(Marshal.dump(value))
  rescue
    if value.is_a?(Array)
      return value.map { |entry| new_project_deep_clone(entry) }
    end
    if value.is_a?(Hash)
      cloned = {}
      value.each { |key, entry| cloned[new_project_deep_clone(key)] = new_project_deep_clone(entry) }
      return cloned
    end
    begin
      return value.clone
    rescue
      return value
    end
  end

  def new_project_party_isolation_expansion_id(expansion_id = nil)
    expansion = expansion_id.to_s
    expansion = current_new_project_expansion_id if expansion.empty?
    expansion = canonical_new_project_id(expansion)
    return nil if expansion.to_s.empty?
    return expansion if NEW_PROJECT_PARTY_ISOLATION_IDS.map { |id| canonical_new_project_id(id) }.include?(expansion)
    return nil
  rescue
    return nil
  end

  def new_project_party_session(expansion_id = nil)
    expansion = new_project_party_isolation_expansion_id(expansion_id)
    return nil if expansion.to_s.empty?
    meta = new_project_metadata(expansion)
    return nil if !meta
    meta["party_session"] = {} if !meta["party_session"].is_a?(Hash)
    return meta["party_session"]
  rescue
    return nil
  end

  def new_project_party_session_active?(expansion_id = nil)
    session = new_project_party_session(expansion_id)
    return !!(session && session["active"])
  rescue
    return false
  end

  def activate_new_project_party_session!(expansion_id = nil, reason = "entry")
    expansion = new_project_party_isolation_expansion_id(expansion_id)
    return false if expansion.to_s.empty?
    return false if !defined?($Trainer) || !$Trainer || !$Trainer.respond_to?(:party)
    session = new_project_party_session(expansion)
    return false if !session
    if session["active"]
      session["expansion_party_snapshot"] = new_project_deep_clone($Trainer.party)
      return true
    end
    session["host_party_snapshot"] ||= new_project_deep_clone($Trainer.party)
    expansion_party = session["expansion_party_snapshot"]
    expansion_party = [] if !expansion_party.is_a?(Array)
    $Trainer.party = new_project_deep_clone(expansion_party)
    $player = $Trainer if defined?($player)
    session["active"] = true
    session["last_reason"] = reason.to_s
    session["updated_at"] = timestamp_string if respond_to?(:timestamp_string)
    log("[#{expansion}] activated isolated party session for #{reason}; host_party_preserved=#{Array(session["host_party_snapshot"]).length}, expansion_party=#{Array($Trainer.party).length}") if respond_to?(:log)
    return true
  rescue => e
    log("[new_project] party session activation failed for #{expansion_id}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def save_new_project_party_session!(expansion_id = nil, reason = "runtime")
    expansion = new_project_party_isolation_expansion_id(expansion_id)
    return false if expansion.to_s.empty?
    return false if !defined?($Trainer) || !$Trainer || !$Trainer.respond_to?(:party)
    session = new_project_party_session(expansion)
    return false if !session || !session["active"]
    session["expansion_party_snapshot"] = new_project_deep_clone($Trainer.party)
    session["last_reason"] = reason.to_s
    session["updated_at"] = timestamp_string if respond_to?(:timestamp_string)
    return true
  rescue => e
    log("[new_project] party session save failed for #{expansion_id}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def restore_new_project_host_party!(expansion_id = nil, reason = "return")
    expansion = new_project_party_isolation_expansion_id(expansion_id)
    return false if expansion.to_s.empty?
    return false if !defined?($Trainer) || !$Trainer || !$Trainer.respond_to?(:party)
    session = new_project_party_session(expansion)
    return false if !session || !session["active"]
    session["expansion_party_snapshot"] = new_project_deep_clone($Trainer.party)
    host_party = session["host_party_snapshot"]
    if host_party.is_a?(Array)
      $Trainer.party = new_project_deep_clone(host_party)
      $player = $Trainer if defined?($player)
      session.delete("host_party_snapshot")
    end
    session["active"] = false
    session["last_reason"] = reason.to_s
    session["updated_at"] = timestamp_string if respond_to?(:timestamp_string)
    log("[#{expansion}] restored host party after #{reason}; host_party=#{Array($Trainer.party).length}, saved_expansion_party=#{Array(session["expansion_party_snapshot"]).length}") if respond_to?(:log)
    return true
  rescue => e
    log("[new_project] host party restore failed for #{expansion_id}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def restore_all_new_project_host_parties!(reason = "host context")
    restored = false
    NEW_PROJECT_PARTY_ISOLATION_IDS.each do |expansion_id|
      restored = restore_new_project_host_party!(expansion_id, reason) || restored
    end
    return restored
  rescue
    return false
  end

  def ensure_new_project_party_can_receive_gift!(reason = "gift")
    expansion = new_project_party_isolation_expansion_id
    return false if expansion.to_s.empty?
    return save_new_project_party_session!(expansion, reason) if new_project_party_session_active?(expansion)
    return false
  rescue => e
    log("[new_project] gift party guard failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def new_project_banked_gift_expansion_id(expansion_id = nil)
    expansion = expansion_id.to_s
    expansion = current_new_project_expansion_id if expansion.empty?
    expansion = canonical_new_project_id(expansion)
    return nil if expansion.to_s.empty?
    return expansion if NEW_PROJECT_BANKED_GIFT_IDS.map { |id| canonical_new_project_id(id) }.include?(expansion)
    return nil
  rescue
    return nil
  end

  def record_new_project_banked_gift!(expansion_id, pokemon, box, source)
    context = current_runtime_context if respond_to?(:current_runtime_context)
    context = {} if !context.is_a?(Hash)
    map_id = integer(context[:map_id], 0)
    map_id = integer($game_map.map_id, 0) if map_id <= 0 && defined?($game_map) && $game_map
    event_id = integer(context[:event_id], 0)
    @new_project_banked_gift = {
      :expansion_id => canonical_new_project_id(expansion_id),
      :pokemon      => pokemon,
      :box          => integer(box, -1),
      :map_id       => map_id,
      :event_id     => event_id,
      :source       => source.to_s
    }
    meta = new_project_metadata(expansion_id)
    if meta
      meta["last_banked_gift"] = {
        "species"    => (pokemon.species rescue nil).to_s,
        "name"       => (pokemon.name rescue nil).to_s,
        "box"        => integer(box, -1),
        "map_id"     => map_id,
        "event_id"   => event_id,
        "source"     => source.to_s,
        "updated_at" => (timestamp_string if respond_to?(:timestamp_string))
      }
    end
    return @new_project_banked_gift
  rescue => e
    log("[new_project] banked gift record failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def current_new_project_banked_gift_pokemon
    gift = @new_project_banked_gift
    return nil if !gift.is_a?(Hash) || !gift[:pokemon]
    expansion = new_project_banked_gift_expansion_id
    return nil if expansion.to_s.empty?
    return nil if canonical_new_project_id(gift[:expansion_id]).to_s != expansion.to_s
    context = current_runtime_context if respond_to?(:current_runtime_context)
    return nil if !context.is_a?(Hash)
    context_map_id = integer(context[:map_id], 0)
    context_event_id = integer(context[:event_id], 0)
    return nil if integer(gift[:map_id], 0) > 0 && context_map_id > 0 && integer(gift[:map_id], 0) != context_map_id
    return nil if integer(gift[:event_id], 0) > 0 && context_event_id > 0 && integer(gift[:event_id], 0) != context_event_id
    return gift[:pokemon]
  rescue
    return nil
  end

  def bank_new_project_gift_pokemon_if_needed!(pkmn, level = 1, see_form = true, dont_randomize = false, variable_to_save = nil, source = "gift")
    expansion = new_project_banked_gift_expansion_id
    return nil if expansion.to_s.empty?
    return nil if !defined?($Trainer) || !$Trainer || !$Trainer.respond_to?(:party_full?)
    return nil if !$Trainer.party_full?
    return nil if !defined?($PokemonStorage) || !$PokemonStorage || !$PokemonStorage.respond_to?(:pbStoreCaught)
    return nil if defined?(pbBoxesFull) && pbBoxesFull?
    pokemon = pkmn
    pokemon = Pokemon.new(pokemon, level) if defined?(Pokemon) && !pokemon.is_a?(Pokemon)
    return false if !pokemon
    tryRandomizeGiftPokemon(pokemon, dont_randomize) if defined?(tryRandomizeGiftPokemon)
    species_name = (pokemon.speciesName rescue nil) || (pokemon.name rescue nil) || pokemon.to_s
    silent_source = source.to_s[/Silent/]
    pbMessage(_INTL("{1} obtained {2}!\\me[Pkmn get]\\wtnp[20]\1", $Trainer.name, species_name)) if !silent_source &&
                                                                                                      defined?(pbMessage) &&
                                                                                                      defined?(_INTL)
    if $Trainer.respond_to?(:pokedex) && $Trainer.pokedex
      $Trainer.pokedex.register(pokemon) if see_form && $Trainer.pokedex.respond_to?(:register)
      $Trainer.pokedex.set_seen(pokemon.species) if $Trainer.pokedex.respond_to?(:set_seen) && pokemon.respond_to?(:species)
      $Trainer.pokedex.set_owned(pokemon.species) if $Trainer.pokedex.respond_to?(:set_owned) && pokemon.respond_to?(:species)
    end
    pokemon.record_first_moves if pokemon.respond_to?(:record_first_moves)
    box = $PokemonStorage.pbStoreCaught(pokemon)
    return false if integer(box, -1) < 0
    pbSet(variable_to_save, pokemon) if variable_to_save && defined?(pbSet)
    record_new_project_banked_gift!(expansion, pokemon, box, source)
    log("[#{expansion}] banked full-party gift #{species_name.inspect} in box #{box} via #{source}") if respond_to?(:log)
    return true
  rescue => e
    log("[new_project] banked gift handling failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def reconcile_new_project_party_session_for_current_map!(reason = "map context")
    map_expansion = current_map_expansion_id if respond_to?(:current_map_expansion_id)
    expansion = map_expansion.to_s.empty? ? nil : new_project_party_isolation_expansion_id(map_expansion)
    if expansion.to_s.empty?
      return restore_all_new_project_host_parties!(reason)
    end
    return save_new_project_party_session!(expansion, reason) if new_project_party_session_active?(expansion)
    return false
  rescue => e
    log("[new_project] party session reconcile failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def new_project_handle_boundary_party_session!(previous_expansion, current_expansion)
    previous_id = previous_expansion.to_s.empty? ? nil : new_project_party_isolation_expansion_id(previous_expansion)
    current_id = current_expansion.to_s.empty? ? nil : new_project_party_isolation_expansion_id(current_expansion)
    if !current_id.to_s.empty?
      return reconcile_new_project_party_session_for_current_map!("entry boundary")
    end
    return restore_new_project_host_party!(previous_id, "expansion boundary") if !previous_id.to_s.empty?
    return false
  rescue => e
    log("[new_project] party boundary handling failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def ensure_player_global!
    if defined?($Trainer) && $Trainer
      $player = $Trainer if !defined?($player) || $player.nil?
    end
    return $player if defined?($player)
    return nil
  rescue
    return nil
  end

  def empyrean_log_once(key, message)
    @empyrean_log_once ||= {}
    return if @empyrean_log_once[key]
    @empyrean_log_once[key] = true
    log(message) if respond_to?(:log)
  rescue
  end

  def empyrean_host_female?
    trainer = $Trainer rescue nil
    return false if !trainer
    return true if trainer.respond_to?(:female?) && trainer.female?
    return false if trainer.respond_to?(:male?) && trainer.male?
    gender = trainer.gender if trainer.respond_to?(:gender)
    return true if defined?(GENDER_FEMALE) && gender == GENDER_FEMALE
    return false
  rescue
    return false
  end

  def host_player_female?
    return host_player_gender_symbol == :female
  end

  def host_player_gender_symbol
    trainer = $Trainer rescue nil
    return :unknown if !trainer
    return :female if trainer.respond_to?(:female?) && trainer.female?
    return :male if trainer.respond_to?(:male?) && trainer.male?
    gender = trainer.gender if trainer.respond_to?(:gender)
    return :female if defined?(GENDER_FEMALE) && gender == GENDER_FEMALE
    return :male if defined?(GENDER_MALE) && gender == GENDER_MALE
    return :neutral
  rescue
    return :unknown
  end

  def host_player_male?
    return host_player_gender_symbol != :female
  rescue
    return true
  end

  def host_player_charset_name
    trainer = $Trainer rescue nil
    if defined?(GameData::Metadata) && trainer
      meta = GameData::Metadata.get_player(trainer.character_ID) rescue nil
      charset = 1
      charset_name = pbGetPlayerCharset(meta, charset, trainer, true) if meta && defined?(pbGetPlayerCharset)
      return charset_name.to_s if charset_name && !charset_name.to_s.empty?
      return meta[1].to_s if meta.respond_to?(:[]) && meta[1] && !meta[1].to_s.empty?
    end
    name = ($game_player.character_name rescue "").to_s
    return name if !name.empty?
    return nil
  rescue
    return nil
  end

  def apply_host_player_visuals!(label = "new_project")
    return false if !$game_player
    $game_player.removeGraphicsOverride if $game_player.respond_to?(:removeGraphicsOverride)
    $game_player.instance_variable_set(:@defaultCharacterName, "") if $game_player.instance_variable_defined?(:@defaultCharacterName)
    $game_player.charsetData = nil if $game_player.respond_to?(:charsetData=)
    charset_name = host_player_charset_name
    if charset_name && !charset_name.empty?
      $game_player.character_name = charset_name if $game_player.respond_to?(:character_name=)
      $game_player.instance_variable_set(:@character_name, charset_name)
    end
    $game_player.through = false if $game_player.respond_to?(:through=)
    $game_player.transparent = false if $game_player.respond_to?(:transparent=)
    $game_player.calculate_bush_depth if $game_player.respond_to?(:calculate_bush_depth)
    $game_player.refresh if $game_player.respond_to?(:refresh)
    $game_player.straighten if $game_player.respond_to?(:straighten)
    $game_map.need_refresh = true if defined?($game_map) && $game_map
    log("[#{label}] preserved host player visuals #{charset_name.inspect}") if respond_to?(:log) && charset_name
    return true
  rescue => e
    log("[#{label}] host player visual sync failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def host_gender_choice_index(commands)
    list = Array(commands).map { |entry| entry.to_s }
    return nil if list.empty?
    female = host_player_female?
    female_index = list.index { |entry| entry[/female|girl|woman|chica|mujer|right|derecha/i] }
    male_index = list.index { |entry| entry[/male|boy|man|chico|hombre|left|izquierda/i] }
    if female
      return female_index if !female_index.nil?
      return 1 if list.length == 2
    else
      return male_index if !male_index.nil?
      return 0
    end
    return 0
  rescue
    return nil
  end

  def plausible_rival_name?(name)
    text = name.to_s.strip
    return false if text.empty?
    normalized = text.downcase.gsub(/[^a-z0-9]+/, " ").strip
    return false if normalized.empty?
    generic_prompts = [
      "rival",
      "your rival",
      "the rival",
      "my rival",
      "rival name",
      "rival s name",
      "your rival name",
      "your rival s name",
      "rival nickname",
      "rival s nickname",
      "your rival nickname",
      "your rival s nickname",
      "name",
      "nickname",
      "trainer",
      "player"
    ]
    return false if generic_prompts.include?(normalized)
    return false if normalized =~ /\Arival\s*\d*\z/
    return false if normalized =~ /\A(?:your\s+|the\s+|my\s+)?rival(?:\s+s)?\s+(?:name|nickname)\z/
    return true
  rescue
    return false
  end

  def host_game_variable_value(variable_id)
    identifier = integer(variable_id, 0)
    return nil if identifier <= 0 || !defined?($game_variables) || !$game_variables
    if $game_variables.respond_to?(:tef_compat_original_get, true)
      return $game_variables.send(:tef_compat_original_get, identifier)
    end
    return $game_variables[identifier]
  rescue
    return nil
  end

  def name_from_trainer_like_object(object)
    return nil if object.nil?
    [:real_name, :name, :trainer_name, :full_name].each do |method_name|
      next if !object.respond_to?(method_name)
      value = object.send(method_name) rescue nil
      return value.to_s.strip if plausible_rival_name?(value)
    end
    [:@real_name, :@name, :@trainer_name].each do |ivar|
      next if !object.instance_variable_defined?(ivar)
      value = object.instance_variable_get(ivar) rescue nil
      return value.to_s.strip if plausible_rival_name?(value)
    end
    return nil
  rescue
    return nil
  end

  def host_rival_name_for_expansion
    candidates = []
    if defined?(VAR_RIVAL_NAME)
      rival_var = VAR_RIVAL_NAME rescue nil
      candidates << host_game_variable_value(rival_var) if rival_var
      candidates << (pbGet(rival_var) rescue nil) if rival_var && defined?(pbGet)
    end
    if defined?(Settings) && Settings.const_defined?(:RIVAL_NAMES)
      Array(Settings::RIVAL_NAMES).each do |entry|
        rival_var = entry.is_a?(Array) ? entry[1] : nil
        candidates << host_game_variable_value(rival_var) if rival_var
      end
    end

    trainer = ($Trainer rescue nil)
    candidates << name_from_trainer_like_object(trainer.rival) if trainer && trainer.respond_to?(:rival)
    candidates << name_from_trainer_like_object(trainer.rival_trainer) if trainer && trainer.respond_to?(:rival_trainer)
    [:@rival_name, :@rivalName].each do |ivar|
      candidates << trainer.instance_variable_get(ivar) if trainer && trainer.instance_variable_defined?(ivar)
    end

    global = ($PokemonGlobal rescue nil)
    [:@rival_name, :@rivalName].each do |ivar|
      candidates << global.instance_variable_get(ivar) if global && global.instance_variable_defined?(ivar)
    end
    battled = global.battledTrainers if global && global.respond_to?(:battledTrainers)
    if battled
      if defined?(BATTLED_TRAINER_RIVAL_KEY)
        rival_record = battled[BATTLED_TRAINER_RIVAL_KEY] rescue nil
        candidates << name_from_trainer_like_object(rival_record)
      end
      if battled.respond_to?(:each_value)
        battled.each_value do |entry|
          type_text = ""
          [:trainer_type, :type, :id].each do |method_name|
            type_text = entry.send(method_name).to_s if entry && entry.respond_to?(method_name)
            break if !type_text.empty?
          end
          candidates << name_from_trainer_like_object(entry) if type_text[/rival/i]
        end
      end
    end

    candidates.each do |candidate|
      text = candidate.to_s.strip
      return text if plausible_rival_name?(text)
    end
    return nil
  rescue => e
    log("[travel] host rival name lookup failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def expansion_rival_name(slot = nil)
    meta = new_project_metadata
    key = slot.nil? ? "rival_name" : "rival_name_#{slot}"
    stored = meta[key].to_s.strip if meta
    name = host_rival_name_for_expansion
    if slot.nil? && plausible_rival_name?(name)
      meta[key] = name if meta
      return name
    end
    return stored if plausible_rival_name?(stored)
    name = slot.nil? ? "Blue" : "Rival #{slot}" if !plausible_rival_name?(name)
    meta[key] = name if meta
    return name
  rescue
    return "Blue"
  end

  def normalize_choice_text(text)
    normalized = text.to_s.downcase
    normalized.gsub!(/\\[a-z]+\[[^\]]*\]/i, "")
    normalized.gsub!(/<[^>]+>/, "")
    normalized.gsub!(/[^\p{Alnum}\s]+/u, " ")
    normalized.gsub!(/\s+/, " ")
    normalized.strip!
    return normalized
  rescue
    return text.to_s.downcase
  end

  def choice_index_matching(commands, pattern)
    Array(commands).each_with_index do |entry, index|
      return index if entry.to_s[pattern]
    end
    return nil
  rescue
    return nil
  end

  def new_project_auto_choice_index(previous_message, commands, map_id = nil, _event_id = nil)
    return nil if !new_project_identity_active_now?(map_id)
    list = Array(commands)
    return nil if list.empty?
    text = normalize_choice_text(previous_message)
    joined = normalize_choice_text(list.join(" "))
    if hollow_woods_active_now?(map_id) &&
       text[/difficulty|game mode|settings/] &&
       joined[/\byes\b/] &&
       joined[/\bno\b/]
      hollow_woods_apply_game_mode_defaults!(:intro_prompt)
      return choice_index_matching(list, /\Ano\z/i) || 1
    end
    if text[/difficulty|dificultad/] || joined[/standard.*adept.*unfair|normal.*hard|easy.*normal/]
      return choice_index_matching(list, /standard|normal/i) || 0
    end
    if text[/randomizer|randomize|aleatori|inverse|special mode|nuzlocke|bosses.*canon|canon teams/] ||
       joined[/randomizer|randomize|inverse|canon/]
      return choice_index_matching(list, /\Ano\z/i) || choice_index_matching(list, /canon/i) || 0
    end
    expansion = nil
    if integer(map_id, 0) > 0 && respond_to?(:current_map_expansion_id)
      map_expansion = current_map_expansion_id(map_id)
      expansion = map_expansion.to_s if expansion_id_in_list?(map_expansion, new_project_expansion_ids)
    end
    expansion ||= active_project_expansion_id(new_project_expansion_ids, map_id)
    local_map = expansion ? (local_map_id_for(expansion, map_id) rescue integer(map_id, 0)) : integer(map_id, 0)
    intro_map = [1, 156].include?(integer(local_map, 0))
    if text[/boy|girl|gender|male|female|chico|chica|hombre|mujer/] ||
       joined[/male.*female/] ||
       (intro_map && joined[/left.*right|izquierda.*derecha/])
      return host_gender_choice_index(list)
    end
    if text[/appearance|look|aspecto/] && list.length > 0
      return host_gender_choice_index(list) || 0
    end
    if text[/are you sure|are you certain|is that correct|is that your name|so you re|ese es tu nombre|seguro|correcto|cierto/]
      return choice_index_matching(list, /^yes$/i) || choice_index_matching(list, /^s/i) || 0
    end
    if text[/do you need help|help choices|need help|info needed/]
      return choice_index_matching(list, /no info/i)
    end
    return nil
  rescue => e
    log("[travel] auto choice failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def empyrean_apply_gender_selection!
    selection = host_player_female? ? 1 : 0
    $game_variables[1] = selection if defined?($game_variables) && $game_variables
    $game_switches[63] = (selection == 0) if defined?($game_switches) && $game_switches
    meta = new_project_metadata || empyrean_metadata
    if meta
      meta["intro_gender_selection"] = selection
      meta["intro_gender"] = host_player_gender_symbol.to_s
      meta["intro_name"] = host_player_name_for_expansion
    end
    return selection
  rescue
    return 0
  end

  def realidea_apply_gender_selection!
    male_player = host_player_male?
    selection = male_player ? 0 : 1
    rival_name = male_player ? "Fatima" : "Dante"
    $game_switches[70] = male_player if defined?($game_switches) && $game_switches
    $game_variables[89] = rival_name if defined?($game_variables) && $game_variables
    meta = new_project_metadata(REALIDEA_EXPANSION_ID) || new_project_metadata
    if meta
      meta["intro_gender_selection"] = selection
      meta["intro_gender"] = host_player_gender_symbol.to_s
      meta["intro_name"] = host_player_name_for_expansion
      meta["realidea_player_male_switch_70"] = male_player
      meta["rival_name"] = rival_name
    end
    return selection
  rescue
    return host_player_female? ? 1 : 0
  end

  def apply_new_project_gender_selection!(map_id = nil)
    return realidea_apply_gender_selection! if realidea_active_now?(map_id)
    return empyrean_apply_gender_selection!
  rescue
    return host_player_female? ? 1 : 0
  end

  def empyrean_apply_skin_selection!(selection = 0)
    value = integer(selection, 0)
    value = 0 if value < 0
    $game_variables[1] = value if defined?($game_variables) && $game_variables
    meta = new_project_metadata || empyrean_metadata
    meta["intro_skin_selection"] = value if meta
    return value
  rescue
    return 0
  end

  def empyrean_intro_sprites_ready!
    empyrean_log_once(:intro_sprites, "[empyrean] calcIntroSprites shimmed; using host-safe intro selection sprites")
    return true
  rescue
    return true
  end

  def set_expansion_level_cap(level)
    value = integer(level, 0)
    meta = new_project_metadata || empyrean_metadata
    meta["level_cap"] = value if meta
    return value
  rescue
    return level
  end

  def realidea_active_now?(map_id = nil)
    return current_new_project_expansion_id(map_id).to_s == REALIDEA_EXPANSION_ID
  rescue
    return false
  end

  def realidea_picture_frame
    frame = integer(($game_variables[97] rescue 0), 0)
    frame = 0 if frame < 0
    return frame
  rescue
    return 0
  end

  def realidea_show_picture(number, path, opacity = 255, blend_type = 0, x = 0, y = 0)
    return true if !realidea_active_now?
    return false if !defined?($game_screen) || !$game_screen || !$game_screen.respond_to?(:pictures)
    picture_id = integer(number, 0)
    return false if picture_id <= 0
    picture = $game_screen.pictures[picture_id] rescue nil
    return false if !picture || !picture.respond_to?(:show)
    picture.show(path.to_s, 0, x, y, 100, 100, opacity, blend_type)
    return true
  rescue => e
    log("[realidea] picture helper failed for #{path}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def realidea_gif(number, folder, delay = "0.13s", opacity = 255, blend_type = 0, x = 0, y = 0)
    frame = realidea_picture_frame
    folder_name = folder.to_s.gsub("\\", "/").sub(/\A\/+/, "")
    return realidea_show_picture(number, "/#{folder_name}/frame_#{frame}_delay-#{delay}", opacity, blend_type, x, y)
  end

  def realidea_haya_picture(kind)
    frame = realidea_picture_frame
    name = kind.to_s == "parpadeando" ? "Haya Parpadeando" : "Haya Hablando"
    return realidea_show_picture(2, "/Hayaya/#{name}#{frame}", 255, 0)
  end

  def new_project_dependent_events
    return nil if !defined?($PokemonTemp) || !$PokemonTemp || !$PokemonTemp.respond_to?(:dependentEvents)
    return $PokemonTemp.dependentEvents
  rescue
    return nil
  end

  def new_project_primary_dependent_event(event_name = nil)
    dependent_events = new_project_dependent_events
    return nil if dependent_events.nil?
    if !event_name.nil? && !event_name.to_s.empty?
      named_event = dependent_events.getEventByName(event_name.to_s) rescue nil
      return named_event if named_event
    end
    if dependent_events.respond_to?(:realEvents)
      events = dependent_events.realEvents rescue nil
      return events[0] if events.is_a?(Array) && events[0]
    end
    if dependent_events.instance_variable_defined?(:@realEvents)
      events = dependent_events.instance_variable_get(:@realEvents)
      return events[0] if events.is_a?(Array) && events[0]
    end
    return nil
  rescue => e
    log("[travel] dependent lookup failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def new_project_source_event_for_dependency(event_id = nil, event_name = "Dependent")
    if event_id && integer(event_id, 0) > 0 && defined?($game_map) && $game_map && $game_map.respond_to?(:events)
      event = $game_map.events[integer(event_id, 0)] rescue nil
      return event if event
    end
    if !event_name.to_s.empty? && defined?($game_map) && $game_map && $game_map.respond_to?(:events)
      target_name = event_name.to_s.downcase
      event = ($game_map.events.values.compact.find { |candidate| candidate.name.to_s.downcase == target_name } rescue nil)
      return event if event
    end
    return nil
  rescue
    return nil
  end

  def new_project_follow_event(event_id, event_name = "Dependent", follows_player = true)
    return false if !new_project_active_now?
    dependent_events = new_project_dependent_events
    source_event = new_project_source_event_for_dependency(event_id, event_name)
    if dependent_events && source_event
      begin
        existing = new_project_primary_dependent_event(event_name)
        if existing.nil? && dependent_events.respond_to?(:addEvent)
          dependent_events.addEvent(source_event, event_name.to_s, nil)
          existing = new_project_primary_dependent_event(event_name)
        end
        existing ||= source_event
        existing.follows_player = follows_player if existing.respond_to?(:follows_player=)
        existing.through = false if existing.respond_to?(:through=)
        existing.transparent = false if existing.respond_to?(:transparent=)
        source_event.erase if source_event.respond_to?(:erase) && existing != source_event
        $game_map.need_refresh = true if defined?($game_map) && $game_map
        log("[travel] bridged follower #{event_name.inspect} from event #{event_id.inspect}") if respond_to?(:log)
        return true
      rescue => e
        log("[travel] follower bridge failed: #{e.class}: #{e.message}") if respond_to?(:log)
      end
    end
    return false
  end

  def new_project_following_move_route(commands, wait_complete = false)
    return nil if !new_project_active_now?
    dependent_events = new_project_dependent_events
    if dependent_events && dependent_events.respond_to?(:SetMoveRoute)
      return dependent_events.SetMoveRoute(commands, wait_complete) rescue nil
    end
    event = new_project_primary_dependent_event("Dependent") || new_project_primary_dependent_event
    return nil if !event
    route = pbMoveRoute(event, Array(commands).compact, wait_complete) if defined?(pbMoveRoute)
    return route
  rescue => e
    log("[travel] FollowingMoveRoute bridge failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  SOULSTONES_STARTER_SPECIES = [
    :BULBASAUR, :CHARMANDER, :SQUIRTLE,
    :CHIKORITA, :CYNDAQUIL, :TOTODILE,
    :TREECKO, :TORCHIC, :MUDKIP,
    :TURTWIG, :CHIMCHAR, :PIPLUP,
    :SNIVY, :TEPIG, :OSHAWOTT,
    :CHESPIN, :FENNEKIN, :FROAKIE,
    :ROWLET, :LITTEN, :POPPLIO,
    :GROOKEY, :SCORBUNNY, :SOBBLE,
    :SPRIGATITO, :FUECOCO, :QUAXLY
  ].freeze unless const_defined?(:SOULSTONES_STARTER_SPECIES)

  SOULSTONES2_MINING_TOTAL_WEIGHT = 1_000 unless const_defined?(:SOULSTONES2_MINING_TOTAL_WEIGHT)

  def soulstones_party
    trainer = $Trainer rescue nil
    return [] if !trainer
    return trainer.pokemonParty if trainer.respond_to?(:pokemonParty)
    return trainer.pokemon_party if trainer.respond_to?(:pokemon_party)
    return trainer.party if trainer.respond_to?(:party)
    return []
  rescue
    return []
  end

  def soulstones_species_symbol(species)
    return nil if species.nil?
    if defined?(GameData::Species) && GameData::Species.respond_to?(:try_get)
      data = GameData::Species.try_get(species) rescue nil
      return data.species if data && data.respond_to?(:species)
    end
    return species.to_sym if species.respond_to?(:to_sym)
    return species
  rescue
    return species
  end

  def soulstones_has_starter?
    starters = SOULSTONES_STARTER_SPECIES
    soulstones_party.each do |pokemon|
      next if !pokemon || (pokemon.respond_to?(:egg?) && pokemon.egg?)
      species = pokemon.respond_to?(:species) ? pokemon.species : pokemon
      return true if starters.include?(soulstones_species_symbol(species))
    end
    return false
  rescue => e
    log("[soulstones] starter check failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def soulstones2_ensure_mining_storage!
    return nil if !$Trainer
    if $Trainer.respond_to?(:miningRocks)
      rocks = $Trainer.miningRocks rescue nil
      $Trainer.miningRocks = [] if !rocks.is_a?(Array) && $Trainer.respond_to?(:miningRocks=)
      return $Trainer.miningRocks rescue nil
    end
    $Trainer.instance_variable_set(:@miningRocks, []) if $Trainer.respond_to?(:instance_variable_set)
    return $Trainer.instance_variable_get(:@miningRocks) if $Trainer.respond_to?(:instance_variable_get)
    return nil
  rescue
    return nil
  end

  def soulstones2_generate_mining_stone!
    rocks = soulstones2_ensure_mining_storage!
    return false if !rocks.is_a?(Array)
    numitems = 3 + rand(3)
    rolls = []
    numitems.times { rolls << rand(SOULSTONES2_MINING_TOTAL_WEIGHT) }
    rocks << [numitems, rolls]
    return true
  rescue => e
    log("[soulstones2] mining stone generation failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def soulstones2_prerandomize_mining_stones!(count = 50)
    rocks = soulstones2_ensure_mining_storage!
    return false if !rocks.is_a?(Array)
    rocks.clear
    [integer(count, 50), 1].max.times { soulstones2_generate_mining_stone! }
    return true
  rescue => e
    log("[soulstones2] mining prerandomizer failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end
end

if defined?(PokemonSystem)
  class PokemonSystem
    def current_menu_theme
      value = @tef_new_project_current_menu_theme
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:new_project_metadata) &&
         TravelExpansionFramework.respond_to?(:new_project_active_now?) &&
         TravelExpansionFramework.new_project_active_now?
        meta = TravelExpansionFramework.new_project_metadata
        value = meta["current_menu_theme"] if meta && meta.has_key?("current_menu_theme")
      end
      return TravelExpansionFramework.integer(value, 0) if defined?(TravelExpansionFramework) &&
                                                          TravelExpansionFramework.respond_to?(:integer)
      return value.to_i
    rescue
      return 0
    end unless method_defined?(:current_menu_theme)

    def current_menu_theme=(value)
      normalized = if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:integer)
                     TravelExpansionFramework.integer(value, 0)
                   else
                     value.to_i
                   end
      @tef_new_project_current_menu_theme = normalized
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:new_project_metadata) &&
         TravelExpansionFramework.respond_to?(:new_project_active_now?) &&
         TravelExpansionFramework.new_project_active_now?
        expansion = TravelExpansionFramework.current_new_project_expansion_id if TravelExpansionFramework.respond_to?(:current_new_project_expansion_id)
        meta = TravelExpansionFramework.new_project_metadata(expansion)
        meta["current_menu_theme"] = normalized if meta
        TravelExpansionFramework.log("[#{expansion || "new_project"}] stored imported menu theme #{normalized}") if TravelExpansionFramework.respond_to?(:log)
      end
      return normalized
    rescue
      @tef_new_project_current_menu_theme = 0
      return 0
    end unless method_defined?(:current_menu_theme=)

    def difficulty
      value = @tef_new_project_difficulty
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:new_project_metadata) &&
         TravelExpansionFramework.respond_to?(:new_project_active_now?) &&
         TravelExpansionFramework.new_project_active_now?
        meta = TravelExpansionFramework.new_project_metadata
        if meta
          value = meta["difficulty"] if meta.has_key?("difficulty")
          value = meta["difficulty_mode"] if value.nil? && meta.has_key?("difficulty_mode")
        end
      end
      return TravelExpansionFramework.integer(value, 0) if defined?(TravelExpansionFramework) &&
                                                          TravelExpansionFramework.respond_to?(:integer)
      return value.to_i
    rescue
      return 0
    end unless method_defined?(:difficulty)

    def difficulty=(value)
      normalized = if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:integer)
                     TravelExpansionFramework.integer(value, 0)
      else
        value.to_i
      end
      @tef_new_project_difficulty = normalized
      if defined?($game_variables) && $game_variables
        $game_variables[242] = normalized
        current_min = ($game_variables[243] rescue nil)
        $game_variables[243] = normalized if current_min.nil? || normalized < current_min.to_i
      end
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:new_project_metadata) &&
         TravelExpansionFramework.respond_to?(:new_project_active_now?) &&
         TravelExpansionFramework.new_project_active_now?
        expansion = TravelExpansionFramework.current_new_project_expansion_id if TravelExpansionFramework.respond_to?(:current_new_project_expansion_id)
        meta = TravelExpansionFramework.new_project_metadata(expansion)
        if meta
          meta["difficulty"] = normalized
          meta["difficulty_mode"] = normalized
        end
        if TravelExpansionFramework.respond_to?(:log)
          TravelExpansionFramework.log("[#{expansion || "new_project"}] stored imported difficulty #{normalized}")
        end
      end
      if defined?($Trainer) && $Trainer
        $Trainer.selected_difficulty = normalized if $Trainer.respond_to?(:selected_difficulty=)
        if $Trainer.respond_to?(:lowest_difficulty=)
          lowest = ($Trainer.lowest_difficulty rescue nil)
          $Trainer.lowest_difficulty = normalized if lowest.nil? || normalized < lowest.to_i
        end
        $Trainer.difficulty_mode = normalized if $Trainer.respond_to?(:difficulty_mode=)
      end
      return normalized
    rescue
      @tef_new_project_difficulty = 0
      return 0
    end unless method_defined?(:difficulty=)
  end
end

if TravelExpansionFramework.respond_to?(:resolve_runtime_path)
  class << TravelExpansionFramework
    alias tef_new_projects_original_resolve_runtime_path resolve_runtime_path unless method_defined?(:tef_new_projects_original_resolve_runtime_path)

    def resolve_runtime_path(logical_path, extensions = [])
      override = opalo_picture_override_path(logical_path, extensions) if respond_to?(:opalo_picture_override_path)
      if override
        log_runtime_asset_once(TravelExpansionFramework::OPALO_EXPANSION_ID, :compat_picture, logical_path, override) if respond_to?(:log_runtime_asset_once)
        return override
      end
      return tef_new_projects_original_resolve_runtime_path(logical_path, extensions)
    end
  end
end

if defined?(Scene_Map)
  class Scene_Map
    attr_accessor :eye_of_truth_time unless method_defined?(:eye_of_truth_time)
    alias tef_new_projects_original_update update unless method_defined?(:tef_new_projects_original_update)

    def update(*args)
      result = tef_new_projects_original_update(*args)
      TravelExpansionFramework.opalo_repair_starter_room_state!(($game_map.map_id rescue nil), "scene_update") if defined?(TravelExpansionFramework) &&
                                                                                                                   TravelExpansionFramework.respond_to?(:opalo_repair_starter_room_state!)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.opalo_active_now? &&
         respond_to?(:eye_of_truth_time) &&
         @eye_of_truth_time.to_i > 0
        @eye_of_truth_time = @eye_of_truth_time.to_i - 1
      end
      TravelExpansionFramework.gadir_deluxe_intro_recovery_update! if defined?(TravelExpansionFramework) &&
                                                                      TravelExpansionFramework.respond_to?(:gadir_deluxe_intro_recovery_update!)
      return result
    end
  end
end

if defined?(Game_Event)
  class Game_Event
    alias tef_new_projects_original_refresh refresh unless method_defined?(:tef_new_projects_original_refresh)
    alias tef_new_projects_original_update update unless method_defined?(:tef_new_projects_original_update)

    def refresh
      TravelExpansionFramework.opalo_repair_starter_room_state!(@map_id, "event_refresh") if defined?(TravelExpansionFramework) &&
                                                                                            TravelExpansionFramework.respond_to?(:opalo_repair_starter_room_state!)
      result = tef_new_projects_original_refresh
      TravelExpansionFramework.apply_opalo_lens_event_state!(self, true) if defined?(TravelExpansionFramework)
      return result
    end

    def update
      result = tef_new_projects_original_update
      TravelExpansionFramework.apply_opalo_lens_event_state!(self, false) if defined?(TravelExpansionFramework)
      return result
    end
  end
end

def pbLensOfTruth
  if defined?(TravelExpansionFramework) && TravelExpansionFramework.opalo_active_now?
    if defined?($scene) && $scene && $scene.respond_to?(:eye_of_truth_time) && $scene.eye_of_truth_time.to_i > 0
      pbMessage(_INTL("The Lens is already being used.")) if defined?(pbMessage)
      return false
    end
    TravelExpansionFramework.activate_opalo_lens_of_truth!
    return true
  end
  return true
end unless defined?(pbLensOfTruth)

GOLD_ID = 0 unless defined?(GOLD_ID)
DIFFICULTY_EASY = -1 unless defined?(DIFFICULTY_EASY)
DIFFICULTY_NORMAL = 0 unless defined?(DIFFICULTY_NORMAL)
DIFFICULTY_EXTREME = 1 unless defined?(DIFFICULTY_EXTREME)
AE_PLAYER_CHARACTER = "player_character" unless defined?(AE_PLAYER_CHARACTER)
AE_GYM = "gym" unless defined?(AE_GYM)
AE_KATA = "kata" unless defined?(AE_KATA)
AE_QUEST = "quest" unless defined?(AE_QUEST)
AE_STARTER = "starter" unless defined?(AE_STARTER)

def calcIntroSprites(*_args)
  return TravelExpansionFramework.empyrean_intro_sprites_ready! if TravelExpansionFramework.new_project_identity_active_now?
  return true
end unless defined?(calcIntroSprites)

def calcPlayerSprites(*_args)
  return true if TravelExpansionFramework.new_project_identity_active_now?
  return true
end unless defined?(calcPlayerSprites)

def giveDefaultClothing(*_args)
  return true if TravelExpansionFramework.new_project_identity_active_now?
  return true
end unless defined?(giveDefaultClothing)

def trackAnalyticsEvent(*_args)
  return nil
end unless defined?(trackAnalyticsEvent)

def setDifficultyVar(value)
  TravelExpansionFramework.ensure_player_global!
  $game_variables[242] = value if defined?($game_variables) && $game_variables
  meta = TravelExpansionFramework.new_project_metadata || (TravelExpansionFramework.empyrean_metadata if TravelExpansionFramework.empyrean_active_now?)
  meta["difficulty"] = value if meta
  return value
end unless defined?(setDifficultyVar)

def setDifficulty(value)
  mapped = case value
           when 0 then DIFFICULTY_EASY
           when 1 then DIFFICULTY_NORMAL
           when 2 then DIFFICULTY_EXTREME
           else value
           end
  return setDifficultyVar(mapped)
end unless defined?(setDifficulty)

def getDifficulty
  return $game_variables[242] if defined?($game_variables) && $game_variables
  return DIFFICULTY_NORMAL
end unless defined?(getDifficulty)

def getMinDifficulty
  return $game_variables[243] if defined?($game_variables) && $game_variables
  return DIFFICULTY_NORMAL
end unless defined?(getMinDifficulty)

def isDifficultyEasy?
  return getDifficulty == DIFFICULTY_EASY
end unless defined?(isDifficultyEasy?)

def isDifficultyNormal?
  return getDifficulty == DIFFICULTY_NORMAL
end unless defined?(isDifficultyNormal?)

def isDifficultyExtreme?
  return getDifficulty == DIFFICULTY_EXTREME
end unless defined?(isDifficultyExtreme?)

def setSkintone(value)
  return TravelExpansionFramework.empyrean_apply_skin_selection!(value) if TravelExpansionFramework.new_project_identity_active_now?
  return value
end unless defined?(setSkintone)

def skintone
  meta = TravelExpansionFramework.new_project_metadata
  return meta["intro_skin_selection"] if meta && meta.has_key?("intro_skin_selection")
  return 0
end unless defined?(skintone)

def isPlayerMale?
  return TravelExpansionFramework.host_player_male? if TravelExpansionFramework.new_project_identity_active_now?
  trainer = $Trainer rescue nil
  return true if !trainer
  return trainer.male? if trainer.respond_to?(:male?)
  return false if trainer.respond_to?(:female?) && trainer.female?
  return true
end unless defined?(isPlayerMale?)

def pbUpdateMax(level)
  return TravelExpansionFramework.set_expansion_level_cap(level)
end unless defined?(pbUpdateMax)

def gif(numero, carpeta)
  return TravelExpansionFramework.realidea_gif(numero, carpeta, "0.13s", 255, 0, 0, 0)
end unless defined?(gif)

def talismannormal(numero, carpeta)
  return TravelExpansionFramework.realidea_gif(numero, carpeta, "0.2s", 255, 0, -10, 0)
end unless defined?(talismannormal)

def talismanotro(numero, carpeta)
  return TravelExpansionFramework.realidea_gif(numero, carpeta, "0.08s", 255, 0, -10, 0)
end unless defined?(talismanotro)

def gifdisco(numero, carpeta)
  return TravelExpansionFramework.realidea_gif(numero, carpeta, "0.04s", 70, 1, 0, 0)
end unless defined?(gifdisco)

def gifhayahablando
  return TravelExpansionFramework.realidea_haya_picture("hablando")
end unless defined?(gifhayahablando)

def gifhayaparpadeando
  return TravelExpansionFramework.realidea_haya_picture("parpadeando")
end unless defined?(gifhayaparpadeando)

if defined?(Player)
  class Player
    def difficulty_mode
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.new_project_identity_active_now?
        meta = TravelExpansionFramework.new_project_metadata
        return meta["difficulty_mode"] if meta && meta.has_key?("difficulty_mode")
      end
      return @difficulty_mode if instance_variable_defined?(:@difficulty_mode)
      return selected_difficulty if respond_to?(:selected_difficulty) && !selected_difficulty.nil?
      return 0
    rescue
      return 0
    end unless method_defined?(:difficulty_mode)

    def difficulty_mode=(value)
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.new_project_identity_active_now?
        meta = TravelExpansionFramework.new_project_metadata
        meta["difficulty_mode"] = value if meta
      end
      @difficulty_mode = value
      self.selected_difficulty = value if respond_to?(:selected_difficulty=)
      return value
    rescue
      return value
    end unless method_defined?(:difficulty_mode=)

    def pokemon_count
      party_value = party if respond_to?(:party)
      return Array(party_value).length
    rescue
      return 0
    end unless method_defined?(:pokemon_count)
  end
end

module TravelExpansionFramework
  module_function

  def resolve_character_popup_event(event_ref = nil, fallback_event_id = nil)
    return $game_player if event_ref.to_s == "Player" && defined?($game_player)
    return nil if !defined?($game_map) || !$game_map || !$game_map.respond_to?(:events)
    ref = event_ref
    ref = fallback_event_id if ref.nil? || ref.to_s.empty?
    if ref.is_a?(Integer) || ref.to_s[/\AEV0*(\d+)\z/i]
      event_id = ref.is_a?(Integer) ? ref : $1.to_i
      event = $game_map.events[event_id] rescue nil
      return event if event
    end
    name = ref.to_s
    $game_map.events.values.each do |event|
      return event if event.respond_to?(:name) && event.name.to_s == name
    end
    return $game_player if defined?($game_player) && $game_player
    return nil
  rescue
    return nil
  end

  def show_character_popup(label, event_ref = nil, fallback_event_id = nil)
    event = resolve_character_popup_event(event_ref, fallback_event_id)
    return true if !event
    animation_id = if defined?(Settings) && Settings.const_defined?(:EXCLAMATION_ANIMATION_ID)
      Settings::EXCLAMATION_ANIMATION_ID
    else
      3
    end
    if defined?(pbExclaim) && [:P_EXCLAMATION, "P_EXCLAMATION"].include?(label)
      pbExclaim(event, animation_id) rescue nil
    elsif defined?($scene) && $scene && $scene.respond_to?(:spriteset) &&
          $scene.spriteset && $scene.spriteset.respond_to?(:addUserAnimation)
      x = event.respond_to?(:x) ? event.x : 0
      y = event.respond_to?(:y) ? event.y : 0
      $scene.spriteset.addUserAnimation(animation_id, x, y, true, 1)
    end
    return true
  rescue => e
    log("[empyrean] characterPopup #{label.inspect}/#{event_ref.inspect} skipped safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def play_expansion_cry(species_ref, volume = 50, pitch = 100)
    expansion = current_new_project_expansion_id if respond_to?(:current_new_project_expansion_id)
    expansion = current_runtime_expansion_id if expansion.to_s.empty? && respond_to?(:current_runtime_expansion_id)
    species = resolve_expansion_species(expansion, species_ref) if respond_to?(:resolve_expansion_species)
    species ||= species_ref
    if defined?(getID) && defined?(PBSpecies)
      species = getID(PBSpecies, species) rescue species
    elsif defined?(GameData) && GameData.const_defined?(:Species)
      data = GameData::Species.try_get(species) rescue nil
      species = data.species if data && data.respond_to?(:species)
    end
    return pbPlayCry(species, volume, pitch) if defined?(pbPlayCry)
    if defined?(pbCryFile) && defined?(pbSEPlay)
      cry = pbCryFile(species) rescue nil
      pbSEPlay(cry, volume, pitch) if cry
    end
    return true
  rescue => e
    log("[empyrean] playCry #{species_ref.inspect} skipped safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end
end

def activar(event, swtch = "A", value = true)
  map_id = @map_id if instance_variable_defined?(:@map_id)
  map_id = ($game_map.map_id rescue 0) if map_id.nil? || map_id.to_i <= 0
  switch_name = swtch.nil? ? "A" : swtch.to_s
  switch_name = "A" if switch_name.empty?
  $game_self_switches[[map_id, event, switch_name]] = value if defined?($game_self_switches) && $game_self_switches
  $game_map.need_refresh = true if defined?($game_map) && $game_map
  return true
end unless defined?(activar)

def skipToHour(hour)
  meta = TravelExpansionFramework.new_project_metadata
  meta["requested_skip_hour"] = hour if meta
  return true
end unless defined?(skipToHour)

def weather(type = :None, power = 0, duration = 0)
  $game_screen.weather(type, power, duration) if defined?($game_screen) && $game_screen && $game_screen.respond_to?(:weather)
  return true
rescue
  return true
end unless defined?(weather)

def pbPlayCrySpecies(pokemon, form = 0, volume = 90, pitch = nil)
  species = pokemon
  if defined?(GameData) && GameData.const_defined?(:Species)
    data = GameData::Species.try_get(species) rescue nil
    data ||= GameData::Species.try_get(species.to_s.upcase.to_sym) rescue nil
    species = data.species if data && data.respond_to?(:species)
    if GameData::Species.respond_to?(:play_cry_from_species)
      return GameData::Species.play_cry_from_species(species, form, volume, pitch) rescue nil
    end
  end
  return pbPlayCry(species, form, volume, pitch) if defined?(pbPlayCry)
  return playCry(species) if defined?(playCry)
  return nil
end unless defined?(pbPlayCrySpecies)

def playCry(species, volume = 50, pitch = 100)
  return TravelExpansionFramework.play_expansion_cry(species, volume, pitch) if defined?(TravelExpansionFramework) &&
                                                                               TravelExpansionFramework.respond_to?(:play_expansion_cry)
  return true
end unless defined?(playCry)

def characterPopup(label, event_ref = nil)
  return TravelExpansionFramework.show_character_popup(label, event_ref) if defined?(TravelExpansionFramework) &&
                                                                           TravelExpansionFramework.respond_to?(:show_character_popup)
  return true
end unless defined?(characterPopup)

def chrp(label, event_ref = nil)
  return characterPopup(label, event_ref)
end unless defined?(chrp)

def chrp1(event_ref = nil)
  return characterPopup(:P_EXCLAMATION, event_ref)
end unless defined?(chrp1)

def pbShuffleDex(*_args)
  return true
end unless defined?(pbShuffleDex)

def pbShuffleDexTrainers(*_args)
  return true
end unless defined?(pbShuffleDexTrainers)

def pbWatchTV(*args)
  return TravelExpansionFramework.hollow_woods_watch_tv!(*args) if defined?(TravelExpansionFramework) &&
                                                                   TravelExpansionFramework.respond_to?(:hollow_woods_watch_tv!)
  return true
end unless defined?(pbWatchTV)

def pbCheckRoaming(*args)
  return TravelExpansionFramework.infinity_check_roaming!(nil, *args) if defined?(TravelExpansionFramework) &&
                                                                         TravelExpansionFramework.respond_to?(:infinity_check_roaming!)
  return false
end unless defined?(pbCheckRoaming)

def pbHasStarters?
  return TravelExpansionFramework.soulstones_has_starter? if defined?(TravelExpansionFramework) &&
                                                             TravelExpansionFramework.respond_to?(:soulstones_has_starter?)
  return false
end unless defined?(pbHasStarters?)

def prerandomizeMiningStones
  return TravelExpansionFramework.soulstones2_prerandomize_mining_stones! if defined?(TravelExpansionFramework) &&
                                                                            TravelExpansionFramework.respond_to?(:soulstones2_prerandomize_mining_stones!)
  return false
end unless defined?(prerandomizeMiningStones)

def generateOneStone
  return TravelExpansionFramework.soulstones2_generate_mining_stone! if defined?(TravelExpansionFramework) &&
                                                                       TravelExpansionFramework.respond_to?(:soulstones2_generate_mining_stone!)
  return false
end unless defined?(generateOneStone)

def useAirDragonite
  if !defined?(PokemonRegionMap_Scene) || !defined?(PokemonRegionMapScreen)
    pbMessage(_INTL("Dragonite cannot find a safe route right now.")) if defined?(pbMessage)
    return false
  end
  scene = PokemonRegionMap_Scene.new(-1, false)
  screen = PokemonRegionMapScreen.new(scene)
  $PokemonTemp.flydata = screen.pbStartFlyScreen
  if !$PokemonTemp.flydata
    pbMessage(_INTL("No worries. Feel free to come back anytime.")) if defined?(pbMessage)
    return false
  end
  target = {
    :map_id    => $PokemonTemp.flydata[0],
    :x         => $PokemonTemp.flydata[1],
    :y         => $PokemonTemp.flydata[2],
    :direction => 2
  }
  map_name = TravelExpansionFramework.map_display_name(target[:map_id]) if defined?(TravelExpansionFramework) &&
                                                                           TravelExpansionFramework.respond_to?(:map_display_name)
  map_name ||= ($game_map.name rescue "your destination")
  if defined?(pbHiddenMoveAnimation) && !pbHiddenMoveAnimation(nil)
    pbMessage(_INTL("Alright, buckle up {1}! Dragonite and I are taking you to {2}.", $Trainer.name, map_name)) if defined?(pbMessage)
  end
  $PokemonTemp.flydata = nil
  if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:safe_transfer_to_anchor)
    return TravelExpansionFramework.safe_transfer_to_anchor(target, {
      :source    => :soulstones_air_dragonite,
      :immediate => true
    })
  end
  pbFadeOutIn {
    pbCancelVehicles if defined?(pbCancelVehicles)
    pbSEPlay("PRSFX- Gust") if defined?(pbSEPlay)
    $game_temp.player_new_map_id = target[:map_id]
    $game_temp.player_new_x = target[:x]
    $game_temp.player_new_y = target[:y]
    $game_temp.player_new_direction = 2
    $scene.transfer_player if $scene && $scene.respond_to?(:transfer_player)
    $game_map.autoplay if $game_map && $game_map.respond_to?(:autoplay)
    $game_map.refresh if $game_map && $game_map.respond_to?(:refresh)
  }
  pbEraseEscapePoint if defined?(pbEraseEscapePoint)
  return true
rescue => e
  TravelExpansionFramework.log("[soulstones] Air Dragonite failed safely: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                      TravelExpansionFramework.respond_to?(:log)
  pbMessage(_INTL("Dragonite cannot find a safe route right now.")) if defined?(pbMessage)
  return false
end unless defined?(useAirDragonite)

if defined?(Trainer)
  class Trainer
    def default_battlebelt
      return {
        :med1   => [:NONE, 0, "None"],
        :med2   => [:NONE, 0, "None"],
        :combat => [:NONE, 0, "None"]
      }
    end unless method_defined?(:default_battlebelt)

    def normalize_battlebelt!
      @battlebelt = default_battlebelt if !@battlebelt.is_a?(Hash)
      defaults = default_battlebelt
      defaults.each do |slot, value|
        @battlebelt[slot] = value if !@battlebelt[slot].is_a?(Array) || @battlebelt[slot].length < 3
      end
      @beltbag = PokemonBag.new if (!@beltbag || !@beltbag.is_a?(PokemonBag)) && defined?(PokemonBag)
      @bagup = nil if !instance_variable_defined?(:@bagup)
      return @battlebelt
    end unless method_defined?(:normalize_battlebelt!)

    def battlebelt
      normalize_battlebelt! if respond_to?(:normalize_battlebelt!)
      return @battlebelt
    end unless method_defined?(:battlebelt)

    def battlebelt=(value)
      @battlebelt = value.is_a?(Hash) ? value : default_battlebelt
      normalize_battlebelt! if respond_to?(:normalize_battlebelt!)
      return @battlebelt
    end unless method_defined?(:battlebelt=)

    def beltbag
      normalize_battlebelt! if respond_to?(:normalize_battlebelt!)
      return @beltbag
    end unless method_defined?(:beltbag)

    def beltbag=(value)
      @beltbag = value
      return @beltbag
    end unless method_defined?(:beltbag=)

    def bagup
      @bagup = nil if !instance_variable_defined?(:@bagup)
      return @bagup
    end unless method_defined?(:bagup)

    def bagup=(value)
      @bagup = value
      return @bagup
    end unless method_defined?(:bagup=)

    def reset_battlebelt
      @battlebelt = default_battlebelt
      @beltbag = PokemonBag.new if defined?(PokemonBag)
      @bagup = nil
      $usingbelt = false
      return @battlebelt
    end unless method_defined?(:reset_battlebelt)

    def miningRocks
      @miningRocks ||= []
      return @miningRocks
    end unless method_defined?(:miningRocks)

    def miningRocks=(value)
      @miningRocks = value.is_a?(Array) ? value : []
      return @miningRocks
    end unless method_defined?(:miningRocks=)
  end
end

unless defined?(::GameMode_Scene)
  class ::GameMode_Scene
    def pbStartScene(*_args)
      return true
    end

    def pbMain(*_args)
      return 0
    end

    def pbEndScene(*_args)
      return true
    end

    def pbUpdate(*_args)
      return true
    end

    def update(*args)
      return pbUpdate(*args)
    end
  end
end

unless defined?(::GameModeScreen)
  class ::GameModeScreen
    def initialize(scene = nil)
      @scene = scene
    end

    def pbStartScreen(*_args)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:hollow_woods_apply_game_mode_defaults!)
        TravelExpansionFramework.hollow_woods_apply_game_mode_defaults!(:game_mode_screen)
      end
      @scene.pbStartScene if @scene && @scene.respond_to?(:pbStartScene)
      @scene.pbEndScene if @scene && @scene.respond_to?(:pbEndScene)
      return 0
    rescue => e
      TravelExpansionFramework.log("[hollow_woods] game mode screen skipped safely: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                                  TravelExpansionFramework.respond_to?(:log)
      return 0
    end
  end
end

if defined?(TravelExpansionFramework) &&
   TravelExpansionFramework.respond_to?(:hollow_woods_apply_game_mode_defaults!)
  TravelExpansionFramework.hollow_woods_apply_game_mode_defaults!(:load)
end

def pbPCSettings(*args)
  if defined?(TravelExpansionFramework) &&
     TravelExpansionFramework.respond_to?(:hollow_woods_apply_game_mode_defaults!)
    TravelExpansionFramework.hollow_woods_apply_game_mode_defaults!(:pc_settings)
  end
  if defined?(pbFadeOutIn)
    pbFadeOutIn {
      scene = ::GameMode_Scene.new
      screen = ::GameModeScreen.new(scene)
      screen.pbStartScreen(*args)
      pbUpdateSceneMap if defined?(pbUpdateSceneMap)
    }
  else
    screen = ::GameModeScreen.new(::GameMode_Scene.new)
    screen.pbStartScreen(*args)
  end
  return true
end unless defined?(pbPCSettings)

module PBDayNight
  class << self
    def tef_infinity_shift_hour(time = nil)
      time = pbGetTimeNow if time.nil? && defined?(pbGetTimeNow)
      time = Time.now if time.nil?
      return time.hour if time.respond_to?(:hour)
      return time.to_i % 24
    rescue
      return 12
    end unless method_defined?(:tef_infinity_shift_hour)

    def isShift1?(time = nil)
      hour = tef_infinity_shift_hour(time)
      return hour >= 0 && hour < 4
    end unless method_defined?(:isShift1?)

    def isShift2?(time = nil)
      hour = tef_infinity_shift_hour(time)
      return hour >= 4 && hour < 8
    end unless method_defined?(:isShift2?)

    def isShift3?(time = nil)
      hour = tef_infinity_shift_hour(time)
      return hour >= 8 && hour < 12
    end unless method_defined?(:isShift3?)

    def isShift4?(time = nil)
      hour = tef_infinity_shift_hour(time)
      return hour >= 12 && hour < 16
    end unless method_defined?(:isShift4?)

    def isShift5?(time = nil)
      hour = tef_infinity_shift_hour(time)
      return hour >= 16 && hour < 20
    end unless method_defined?(:isShift5?)

    def isShift6?(time = nil)
      hour = tef_infinity_shift_hour(time)
      return hour >= 20 && hour < 24
    end unless method_defined?(:isShift6?)

    def reset
      @dayNightToneLastUpdate = nil
      @cachedTone = nil
      return true
    end unless method_defined?(:reset)
  end
end

class << Object
  alias tef_new_projects_original_const_missing const_missing unless method_defined?(:tef_new_projects_original_const_missing)

  def const_missing(name)
    if defined?(TravelExpansionFramework) &&
       TravelExpansionFramework.bare_species_constant_resolution_active? &&
       TravelExpansionFramework.respond_to?(:resolve_pb_species_constant_name)
      species = TravelExpansionFramework.resolve_pb_species_constant_name(name) rescue nil
      return const_set(name, species) if species
    end
    return tef_new_projects_original_const_missing(name) if respond_to?(:tef_new_projects_original_const_missing, true)
    raise NameError, "uninitialized constant Object::#{name}"
  end
end

if defined?(pbChangePlayer) && !defined?(tef_new_projects_original_pbChangePlayer)
  alias tef_new_projects_original_pbChangePlayer pbChangePlayer
end

def pbChangePlayer(id, *args)
  if TravelExpansionFramework.new_project_identity_active_now?
    TravelExpansionFramework.apply_new_project_gender_selection!
    TravelExpansionFramework.apply_host_player_visuals!(TravelExpansionFramework.current_new_project_expansion_id || "new_project")
    TravelExpansionFramework.empyrean_log_once(:change_player, "[travel] ignored expansion intro pbChangePlayer(#{id.inspect}) to preserve host player identity")
    return true
  end
  return send(:tef_new_projects_original_pbChangePlayer, id, *args) if respond_to?(:tef_new_projects_original_pbChangePlayer, true)
  return false
end

if defined?(pbTrainerName) && !defined?(tef_new_projects_original_pbTrainerName)
  alias tef_new_projects_original_pbTrainerName pbTrainerName
end

def pbTrainerName(name = nil, outfit = 0)
  if TravelExpansionFramework.new_project_identity_active_now?
    chosen_name = TravelExpansionFramework.host_player_name_for_expansion
    meta = TravelExpansionFramework.new_project_metadata || TravelExpansionFramework.empyrean_metadata
    meta["intro_requested_name"] = name.to_s if meta && !name.nil?
    meta["intro_name"] = chosen_name if meta
    $PokemonTemp.begunNewGame = true if defined?($PokemonTemp) && $PokemonTemp && $PokemonTemp.respond_to?(:begunNewGame=)
    TravelExpansionFramework.empyrean_log_once(:trainer_name, "[travel] expansion intro trainer name reused host name #{chosen_name.inspect}")
    return chosen_name
  end
  return send(:tef_new_projects_original_pbTrainerName, name, outfit) if respond_to?(:tef_new_projects_original_pbTrainerName, true)
  return name.to_s
end

if defined?(pbAddDependency) && !defined?(tef_new_projects_original_pbAddDependency)
  alias tef_new_projects_original_pbAddDependency pbAddDependency
end

def pbAddDependency(event_id, event_name = "Dependent", common_event = nil, *args)
  if TravelExpansionFramework.new_project_active_now?
    return true if TravelExpansionFramework.new_project_follow_event(event_id, event_name, false)
  end
  if respond_to?(:tef_new_projects_original_pbAddDependency, true)
    return send(:tef_new_projects_original_pbAddDependency, event_id, event_name, common_event, *args)
  end
  return false
end

if defined?(pbPokemonFollow) && !defined?(tef_new_projects_original_pbPokemonFollow)
  alias tef_new_projects_original_pbPokemonFollow pbPokemonFollow
end

def pbPokemonFollow(event_id, event_name = "Dependent")
  if TravelExpansionFramework.new_project_active_now?
    return true if TravelExpansionFramework.new_project_follow_event(event_id, event_name, true)
  end
  if respond_to?(:tef_new_projects_original_pbPokemonFollow, true)
    return send(:tef_new_projects_original_pbPokemonFollow, event_id, event_name)
  end
  return false
end

if defined?(pbFancyMoveTo) && !defined?(tef_new_projects_original_pbFancyMoveTo)
  alias tef_new_projects_original_pbFancyMoveTo pbFancyMoveTo
end

def pbFancyMoveTo(follower, newX, newY, leader = :__tef_missing__)
  if leader == :__tef_missing__ && TravelExpansionFramework.new_project_active_now?
    leader = ($game_player rescue nil) || follower
    TravelExpansionFramework.log("[travel] bridged 3-arg pbFancyMoveTo for #{TravelExpansionFramework.current_new_project_expansion_id}") if TravelExpansionFramework.respond_to?(:log)
  end
  if respond_to?(:tef_new_projects_original_pbFancyMoveTo, true)
    return send(:tef_new_projects_original_pbFancyMoveTo, follower, newX, newY, leader)
  end
  return false
end

if defined?(FollowingMoveRoute) && !defined?(tef_new_projects_original_FollowingMoveRoute)
  alias tef_new_projects_original_FollowingMoveRoute FollowingMoveRoute
end

def FollowingMoveRoute(commands, waitComplete = false)
  if TravelExpansionFramework.new_project_active_now?
    route = TravelExpansionFramework.new_project_following_move_route(commands, waitComplete)
    return route if route
  end
  if respond_to?(:tef_new_projects_original_FollowingMoveRoute, true)
    return send(:tef_new_projects_original_FollowingMoveRoute, commands, waitComplete)
  end
  return nil
end

if defined?(pbGetDependency) && !defined?(tef_new_projects_original_pbGetDependency)
  alias tef_new_projects_original_pbGetDependency pbGetDependency
end

def pbGetDependency(eventName)
  existing = nil
  existing = send(:tef_new_projects_original_pbGetDependency, eventName) if respond_to?(:tef_new_projects_original_pbGetDependency, true)
  return existing if existing
  if TravelExpansionFramework.new_project_active_now?
    event = TravelExpansionFramework.new_project_primary_dependent_event(eventName)
    event ||= TravelExpansionFramework.new_project_primary_dependent_event("Dependent")
    event ||= TravelExpansionFramework.new_project_primary_dependent_event
    return event if event
  end
  return existing
rescue
  return nil
end

if defined?(_INTL) && !defined?(tef_new_projects_original__INTL)
  alias tef_new_projects_original__INTL _INTL
end

if defined?(pbAddPokemon) && !defined?(tef_new_projects_original_pbAddPokemon)
  alias tef_new_projects_original_pbAddPokemon pbAddPokemon
end

def pbAddPokemon(pkmn, level = 1, see_form = true, dontRandomize = false, variableToSave = nil)
  if TravelExpansionFramework.respond_to?(:bank_new_project_gift_pokemon_if_needed!)
    handled = TravelExpansionFramework.bank_new_project_gift_pokemon_if_needed!(pkmn, level, see_form, dontRandomize, variableToSave, "pbAddPokemon")
    return handled if !handled.nil?
  end
  result = tef_new_projects_original_pbAddPokemon(pkmn, level, see_form, dontRandomize, variableToSave)
  TravelExpansionFramework.save_new_project_party_session!(nil, "pbAddPokemon") if TravelExpansionFramework.respond_to?(:save_new_project_party_session!)
  return result
end

if defined?(pbAddPokemonSilent) && !defined?(tef_new_projects_original_pbAddPokemonSilent)
  alias tef_new_projects_original_pbAddPokemonSilent pbAddPokemonSilent
end

def pbAddPokemonSilent(pkmn, level = 1, see_form = true)
  if TravelExpansionFramework.respond_to?(:bank_new_project_gift_pokemon_if_needed!)
    handled = TravelExpansionFramework.bank_new_project_gift_pokemon_if_needed!(pkmn, level, see_form, false, nil, "pbAddPokemonSilent")
    return handled if !handled.nil?
  end
  result = tef_new_projects_original_pbAddPokemonSilent(pkmn, level, see_form)
  TravelExpansionFramework.save_new_project_party_session!(nil, "pbAddPokemonSilent") if TravelExpansionFramework.respond_to?(:save_new_project_party_session!)
  return result
end

if defined?(pbAddToParty) && !defined?(tef_new_projects_original_pbAddToParty)
  alias tef_new_projects_original_pbAddToParty pbAddToParty
end

def pbAddToParty(pkmn, level = 1, see_form = true, dontRandomize = false)
  if TravelExpansionFramework.respond_to?(:bank_new_project_gift_pokemon_if_needed!)
    handled = TravelExpansionFramework.bank_new_project_gift_pokemon_if_needed!(pkmn, level, see_form, dontRandomize, nil, "pbAddToParty")
    return handled if !handled.nil?
  end
  result = tef_new_projects_original_pbAddToParty(pkmn, level, see_form, dontRandomize)
  TravelExpansionFramework.save_new_project_party_session!(nil, "pbAddToParty") if TravelExpansionFramework.respond_to?(:save_new_project_party_session!)
  return result
end

if defined?(pbAddToPartySilent) && !defined?(tef_new_projects_original_pbAddToPartySilent)
  alias tef_new_projects_original_pbAddToPartySilent pbAddToPartySilent
end

def pbAddToPartySilent(pkmn, level = nil, see_form = true)
  if TravelExpansionFramework.respond_to?(:bank_new_project_gift_pokemon_if_needed!)
    handled = TravelExpansionFramework.bank_new_project_gift_pokemon_if_needed!(pkmn, level || 1, see_form, false, nil, "pbAddToPartySilent")
    return handled if !handled.nil?
  end
  result = tef_new_projects_original_pbAddToPartySilent(pkmn, level, see_form)
  TravelExpansionFramework.save_new_project_party_session!(nil, "pbAddToPartySilent") if TravelExpansionFramework.respond_to?(:save_new_project_party_session!)
  return result
end

if defined?(Player)
  class Player
    alias tef_new_projects_original_last_party last_party unless method_defined?(:tef_new_projects_original_last_party)

    def last_party
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:current_new_project_banked_gift_pokemon)
        gift = TravelExpansionFramework.current_new_project_banked_gift_pokemon
        return gift if gift
      end
      return tef_new_projects_original_last_party
    end
  end
end

if defined?(Trainer)
  class Trainer
    alias tef_new_projects_original_last_party last_party unless method_defined?(:tef_new_projects_original_last_party)

    def last_party
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:current_new_project_banked_gift_pokemon)
        gift = TravelExpansionFramework.current_new_project_banked_gift_pokemon
        return gift if gift
      end
      return tef_new_projects_original_last_party
    end
  end
end

def _INTL(*arg)
  if TravelExpansionFramework.new_project_active_now?
    template = TravelExpansionFramework.prepare_new_project_text(arg[0].to_s, ($game_map.map_id rescue nil))
    return TravelExpansionFramework.format_translation_text(template, arg[1..-1])
  end
  return send(:tef_new_projects_original__INTL, *arg) if respond_to?(:tef_new_projects_original__INTL, true)
  return TravelExpansionFramework.format_translation_text(arg[0].to_s, arg[1..-1])
end

if defined?(pbMessage) && !defined?(tef_new_projects_original_pbMessage)
  alias tef_new_projects_original_pbMessage pbMessage
end

def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
  TravelExpansionFramework.ensure_player_global! if TravelExpansionFramework.new_project_identity_active_now?
  if TravelExpansionFramework.new_project_active_now?
    map_id = ($game_map.map_id rescue nil)
    message = TravelExpansionFramework.prepare_new_project_text(message, map_id)
    commands = TravelExpansionFramework.prepare_new_project_commands(commands, map_id) if commands
  end
  if commands && TravelExpansionFramework.new_project_identity_active_now?
    auto_choice = TravelExpansionFramework.new_project_auto_choice_index(message, commands, ($game_map.map_id rescue nil), nil)
    if !auto_choice.nil?
      TravelExpansionFramework.log("[travel] auto-selected intro choice #{auto_choice} for #{Array(commands).inspect}") if TravelExpansionFramework.respond_to?(:log)
      return auto_choice
    end
  end
  return tef_new_projects_original_pbMessage(message, commands, cmdIfCancel, skin, defaultCmd, &block)
end

if defined?(pbMessageDisplay) && !defined?(tef_new_projects_original_pbMessageDisplay)
  alias tef_new_projects_original_pbMessageDisplay pbMessageDisplay
end

def pbMessageDisplay(msgwindow, message, letterbyletter = true, commandProc = nil, withSound = true)
  message = TravelExpansionFramework.prepare_new_project_text(message, ($game_map.map_id rescue nil)) if TravelExpansionFramework.new_project_active_now?
  return tef_new_projects_original_pbMessageDisplay(msgwindow, message, letterbyletter, commandProc, withSound)
end

if defined?(pbMessageChooseNumber) && !defined?(tef_new_projects_original_pbMessageChooseNumber)
  alias tef_new_projects_original_pbMessageChooseNumber pbMessageChooseNumber
end

def pbMessageChooseNumber(message, params, &block)
  message = TravelExpansionFramework.prepare_new_project_text(message, ($game_map.map_id rescue nil)) if TravelExpansionFramework.new_project_active_now?
  return tef_new_projects_original_pbMessageChooseNumber(message, params, &block)
end

if defined?(pbMessageFreeText) && !defined?(tef_new_projects_original_pbMessageFreeText)
  alias tef_new_projects_original_pbMessageFreeText pbMessageFreeText
end

def pbMessageFreeText(message, currenttext, passwordbox, maxlength, width = 240, &block)
  if TravelExpansionFramework.new_project_identity_active_now?
    if message.to_s[/rival/i]
      return TravelExpansionFramework.expansion_rival_name
    end
    if message.to_s[/what do you wish to be called|tell me.*name|what is your name|call sign|nombre|llam/i]
      return TravelExpansionFramework.host_player_name_for_expansion
    end
  elsif TravelExpansionFramework.empyrean_active_now? && message.to_s[/what do you wish to be called/i]
    return TravelExpansionFramework.host_player_name_for_expansion
  end
  message = TravelExpansionFramework.prepare_new_project_text(message, ($game_map.map_id rescue nil)) if TravelExpansionFramework.new_project_active_now?
  return tef_new_projects_original_pbMessageFreeText(message, currenttext, passwordbox, maxlength, width, &block)
end

if defined?(pbShowCommands) && !defined?(tef_new_projects_original_pbShowCommands)
  alias tef_new_projects_original_pbShowCommands pbShowCommands
end

def pbShowCommands(msgwindow, commands = nil, cmdIfCancel = 0, defaultCmd = 0, x_offset = nil, y_offset = nil)
  commands = TravelExpansionFramework.prepare_new_project_commands(commands, ($game_map.map_id rescue nil)) if TravelExpansionFramework.new_project_active_now? && commands
  return tef_new_projects_original_pbShowCommands(msgwindow, commands, cmdIfCancel, defaultCmd, x_offset, y_offset)
end

if defined?(pbShowCommandsWithHelp) && !defined?(tef_new_projects_original_pbShowCommandsWithHelp)
  alias tef_new_projects_original_pbShowCommandsWithHelp pbShowCommandsWithHelp
end

def pbShowCommandsWithHelp(msgwindow, commands, help, cmdIfCancel = 0, defaultCmd = 0)
  if TravelExpansionFramework.new_project_active_now?
    map_id = ($game_map.map_id rescue nil)
    commands = TravelExpansionFramework.prepare_new_project_commands(commands, map_id)
    help = TravelExpansionFramework.prepare_new_project_commands(help, map_id)
  end
  return tef_new_projects_original_pbShowCommandsWithHelp(msgwindow, commands, help, cmdIfCancel, defaultCmd)
end

unless defined?(AnimatedText)
  class AnimatedText
    def initialize(text, *_args)
      @text = text.to_s
      @shown = false
    end

    def start
      return true if @shown
      @shown = true
      pbMessage(@text) if TravelExpansionFramework.new_project_identity_active_now? && !@text.empty?
      return true
    end

    def update
      return true
    end

    def dispose
      @shown = true
      return true
    end
  end
end

unless defined?(GenderSelection)
  class GenderSelection
    def initialize(_text = nil)
      TravelExpansionFramework.apply_new_project_gender_selection! if TravelExpansionFramework.new_project_identity_active_now?
      $genderSelection = self if defined?($genderSelection)
    end

    def restart
      TravelExpansionFramework.apply_new_project_gender_selection! if TravelExpansionFramework.new_project_identity_active_now?
      return true
    end

    def start
      return true
    end

    def end
      dispose
    end

    def dispose
      $genderSelection = nil if defined?($genderSelection)
      return true
    end
  end
end

unless defined?(PokemonGenderSelection)
  class PokemonGenderSelection
    attr_reader :selected_gender

    def initialize(*_args)
      @selected_gender = TravelExpansionFramework.apply_new_project_gender_selection!
      TravelExpansionFramework.apply_host_player_visuals!(TravelExpansionFramework.current_new_project_expansion_id || "new_project")
      @close = 1
    end

    def input
      return true
    end

    def main_method
      return true
    end

    def continue
      return true
    end

    def dispose
      return true
    end
  end
end

if defined?(Interpreter) && defined?(PokemonGenderSelection)
  class Interpreter
    PokemonGenderSelection = ::PokemonGenderSelection unless const_defined?(:PokemonGenderSelection)
  end
end

unless defined?(SkintoneSelection)
  class SkintoneSelection
    def initialize(_text = nil)
      TravelExpansionFramework.empyrean_apply_skin_selection!(0) if TravelExpansionFramework.new_project_identity_active_now?
      $skinSelection = self if defined?($skinSelection)
    end

    def restart
      TravelExpansionFramework.empyrean_apply_skin_selection!(0) if TravelExpansionFramework.new_project_identity_active_now?
      return true
    end

    def start
      return true
    end

    def end
      dispose
    end

    def dispose
      $skinSelection = nil if defined?($skinSelection)
      return true
    end
  end
end

unless defined?(DiegoWTsStarterSelection)
  class DiegoWTsStarterSelection
    attr_reader :selected_species

    def initialize(*species)
      @selected_species = TravelExpansionFramework.hollow_woods_choose_starter!(*species) if defined?(TravelExpansionFramework) &&
                                                                                             TravelExpansionFramework.respond_to?(:hollow_woods_choose_starter!)
    end
  end
end

if defined?(Interpreter) && defined?(DiegoWTsStarterSelection)
  class Interpreter
    DiegoWTsStarterSelection = ::DiegoWTsStarterSelection unless const_defined?(:DiegoWTsStarterSelection)
  end
end

class Interpreter
  GameMode_Scene = ::GameMode_Scene if defined?(::GameMode_Scene) && !const_defined?(:GameMode_Scene)
  GameModeScreen = ::GameModeScreen if defined?(::GameModeScreen) && !const_defined?(:GameModeScreen)

  alias tef_new_projects_original_command_102 command_102 unless method_defined?(:tef_new_projects_original_command_102)
  alias tef_new_projects_original_execute_script execute_script unless method_defined?(:tef_new_projects_original_execute_script)

  def tef_new_projects_previous_message
    index = @index.to_i - 1
    while index >= 0
      command = @list[index] rescue nil
      break if !command
      code = command.code rescue command.instance_variable_get(:@code)
      params = command.parameters rescue command.instance_variable_get(:@parameters)
      return Array(params)[0].to_s if [101, 401].include?(code)
      index -= 1
    end
    return nil
  rescue
    return nil
  end

  def command_102
    if TravelExpansionFramework.new_project_identity_active_now?((@map_id rescue nil))
      TravelExpansionFramework.ensure_player_global!
      commands = @list[@index].parameters[0] rescue nil
      auto_choice = TravelExpansionFramework.new_project_auto_choice_index(
        tef_new_projects_previous_message,
        commands,
        (@map_id rescue ($game_map.map_id rescue nil)),
        (@event_id rescue nil)
      )
      if !auto_choice.nil?
        @message_waiting = false
        @branch[@list[@index].indent] = auto_choice if @branch
        Input.update rescue nil
        TravelExpansionFramework.log("[travel] auto-selected command_102 choice #{auto_choice} for #{Array(commands).inspect}") if TravelExpansionFramework.respond_to?(:log)
        return true
      end
    end
    return tef_new_projects_original_command_102
  end

  def execute_script(script)
    TravelExpansionFramework.ensure_player_global! if TravelExpansionFramework.new_project_identity_active_now?((@map_id rescue nil))
    return tef_new_projects_original_execute_script(script)
  end

  def activar(event, swtch = "A", value = true)
    map_id = @map_id if instance_variable_defined?(:@map_id)
    map_id = ($game_map.map_id rescue 0) if map_id.nil? || map_id.to_i <= 0
    switch_name = swtch.nil? ? "A" : swtch.to_s
    switch_name = "A" if switch_name.empty?
    $game_self_switches[[map_id, event, switch_name]] = value if defined?($game_self_switches) && $game_self_switches
    $game_map.need_refresh = true if defined?($game_map) && $game_map
    return true
  end

  def Activar(event, swtch = "A", value = true)
    return activar(event, swtch, value)
  end

  def pbUpdateMax(level)
    return TravelExpansionFramework.set_expansion_level_cap(level)
  end

  def gif(numero, carpeta)
    return TravelExpansionFramework.realidea_gif(numero, carpeta, "0.13s", 255, 0, 0, 0)
  end

  def talismannormal(numero, carpeta)
    return TravelExpansionFramework.realidea_gif(numero, carpeta, "0.2s", 255, 0, -10, 0)
  end

  def talismanotro(numero, carpeta)
    return TravelExpansionFramework.realidea_gif(numero, carpeta, "0.08s", 255, 0, -10, 0)
  end

  def gifdisco(numero, carpeta)
    return TravelExpansionFramework.realidea_gif(numero, carpeta, "0.04s", 70, 1, 0, 0)
  end

  def gifhayahablando
    return TravelExpansionFramework.realidea_haya_picture("hablando")
  end

  def gifhayaparpadeando
    return TravelExpansionFramework.realidea_haya_picture("parpadeando")
  end

  def skipToHour(hour)
    meta = TravelExpansionFramework.new_project_metadata
    meta["requested_skip_hour"] = hour if meta
    return true
  end

  def weather(type = :None, power = 0, duration = 0)
    $game_screen.weather(type, power, duration) if defined?($game_screen) && $game_screen && $game_screen.respond_to?(:weather)
    return true
  rescue
    return true
  end

  def pbPCSettings(*args)
    if defined?(TravelExpansionFramework) &&
       TravelExpansionFramework.respond_to?(:hollow_woods_apply_game_mode_defaults!)
      TravelExpansionFramework.hollow_woods_apply_game_mode_defaults!(:interpreter_pc_settings)
    end
    scene = ::GameMode_Scene.new if defined?(::GameMode_Scene)
    screen = ::GameModeScreen.new(scene) if defined?(::GameModeScreen)
    screen.pbStartScreen(*args) if screen && screen.respond_to?(:pbStartScreen)
    pbUpdateSceneMap if respond_to?(:pbUpdateSceneMap)
    return true
  rescue => e
    TravelExpansionFramework.log("[hollow_woods] interpreter pc settings skipped safely: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                                       TravelExpansionFramework.respond_to?(:log)
    return true
  end

  def pbWatchTV(*args)
    return TravelExpansionFramework.hollow_woods_watch_tv!(*args) if defined?(TravelExpansionFramework) &&
                                                                     TravelExpansionFramework.respond_to?(:hollow_woods_watch_tv!)
    return true
  end

  def pbCheckRoaming(*args)
    return TravelExpansionFramework.infinity_check_roaming!(@event_id, *args) if defined?(TravelExpansionFramework) &&
                                                                                TravelExpansionFramework.respond_to?(:infinity_check_roaming!)
    return false
  end

  def isBridgeOn
    return false if !defined?($PokemonGlobal) || !$PokemonGlobal
    return $PokemonGlobal.respond_to?(:bridge) && $PokemonGlobal.bridge.to_i > 0
  rescue
    return false
  end

  def pbBridgeOn(height = 2, *_args)
    return TravelExpansionFramework.empyrean_set_bridge_height!(height) if defined?(TravelExpansionFramework) &&
                                                                           TravelExpansionFramework.respond_to?(:empyrean_set_bridge_height!)
    $PokemonGlobal.bridge = height if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:bridge=)
    return true
  rescue
    return true
  end

  def pbBridgeOff(*_args)
    return TravelExpansionFramework.empyrean_clear_bridge_height! if defined?(TravelExpansionFramework) &&
                                                                     TravelExpansionFramework.respond_to?(:empyrean_clear_bridge_height!)
    $PokemonGlobal.bridge = 0 if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:bridge=)
    return true
  rescue
    return true
  end

  def characterPopup(label, event_ref = nil, *_args)
    return TravelExpansionFramework.show_character_popup(label, event_ref, @event_id) if defined?(TravelExpansionFramework) &&
                                                                                         TravelExpansionFramework.respond_to?(:show_character_popup)
    return true
  end

  def chrp(label, event_ref = nil)
    return characterPopup(label, event_ref)
  end

  def chrp1(event_ref = nil)
    return characterPopup(:P_EXCLAMATION, event_ref)
  end

  def playCry(species, volume = 50, pitch = 100)
    return TravelExpansionFramework.play_expansion_cry(species, volume, pitch) if defined?(TravelExpansionFramework) &&
                                                                                 TravelExpansionFramework.respond_to?(:play_expansion_cry)
    return true
  end

  def pbPlayCrySpecies(pokemon, form = 0, volume = 90, pitch = nil)
    return ::Kernel.pbPlayCrySpecies(pokemon, form, volume, pitch) if ::Kernel.respond_to?(:pbPlayCrySpecies)
    return pbPlayCry(pokemon, form, volume, pitch) if respond_to?(:pbPlayCry)
    return nil
  rescue
    return nil
  end

  def pbShuffleDex(*_args)
    return true
  end

  def pbShuffleDexTrainers(*_args)
    return true
  end

  def pbPokemonFollow(_event_id, _event_name = "Dependent")
    if defined?(TravelExpansionFramework) &&
       TravelExpansionFramework.respond_to?(:insurgence_expansion_id?) &&
       TravelExpansionFramework.insurgence_expansion_id?
      return TravelExpansionFramework.insurgence_follow_event(_event_id, _event_name, true)
    end
    if TravelExpansionFramework.new_project_identity_active_now?((@map_id rescue nil))
      return TravelExpansionFramework.new_project_follow_event(_event_id, _event_name, true)
    end
    return false
  end

  def pbAddDependency(event_id, event_name = "Dependent", common_event = nil, *args)
    if defined?(TravelExpansionFramework) &&
       TravelExpansionFramework.respond_to?(:insurgence_expansion_id?) &&
       TravelExpansionFramework.insurgence_expansion_id?
      return true if TravelExpansionFramework.insurgence_follow_event(event_id, event_name, false)
    end
    if TravelExpansionFramework.new_project_identity_active_now?((@map_id rescue nil))
      return true if TravelExpansionFramework.new_project_follow_event(event_id, event_name, false)
    end
    return send(:tef_new_projects_original_pbAddDependency, event_id, event_name, common_event, *args) if respond_to?(:tef_new_projects_original_pbAddDependency, true)
    return false
  end

  def pbChangePlayer(id, *args)
    if TravelExpansionFramework.new_project_identity_active_now?((@map_id rescue nil))
      TravelExpansionFramework.apply_new_project_gender_selection!((@map_id rescue nil))
      TravelExpansionFramework.apply_host_player_visuals!(TravelExpansionFramework.current_new_project_expansion_id(@map_id) || "new_project")
      return true
    end
    return send(:tef_new_projects_original_pbChangePlayer, id, *args) if respond_to?(:tef_new_projects_original_pbChangePlayer, true)
    return false
  end

  def pbTrainerName(name = nil, outfit = 0)
    if TravelExpansionFramework.new_project_identity_active_now?((@map_id rescue nil))
      chosen_name = TravelExpansionFramework.host_player_name_for_expansion
      meta = TravelExpansionFramework.new_project_metadata
      meta["intro_requested_name"] = name.to_s if meta && !name.nil?
      meta["intro_name"] = chosen_name if meta
      $PokemonTemp.begunNewGame = true if defined?($PokemonTemp) && $PokemonTemp && $PokemonTemp.respond_to?(:begunNewGame=)
      return chosen_name
    end
    return send(:tef_new_projects_original_pbTrainerName, name, outfit) if respond_to?(:tef_new_projects_original_pbTrainerName, true)
    return name.to_s
  end

  def setSkintone(value)
    return TravelExpansionFramework.empyrean_apply_skin_selection!(value)
  end

  def skintone
    meta = TravelExpansionFramework.new_project_metadata
    return meta["intro_skin_selection"] if meta && meta.has_key?("intro_skin_selection")
    return 0
  rescue
    return 0
  end

  def isPlayerMale?
    return !TravelExpansionFramework.host_player_female?
  end

  def setDifficultyVar(value)
    TravelExpansionFramework.ensure_player_global!
    $game_variables[242] = value if defined?($game_variables) && $game_variables
    meta = TravelExpansionFramework.new_project_metadata
    meta["difficulty"] = value if meta
    return value
  end

  def trackAnalyticsEvent(*args)
    return nil
  end

  def giveDefaultClothing(*args)
    return true
  end

  def calcPlayerSprites(*args)
    return true
  end

  def calcIntroSprites(*args)
    return TravelExpansionFramework.empyrean_intro_sprites_ready! if TravelExpansionFramework.new_project_identity_active_now?
    return true
  end
end

if defined?(Game_Map)
  class Game_Map
    alias tef_empyrean_original_setup setup unless method_defined?(:tef_empyrean_original_setup)
    alias tef_empyrean_original_playerPassable? playerPassable? unless method_defined?(:tef_empyrean_original_playerPassable?)

    def setup(map_id)
      result = tef_empyrean_original_setup(map_id)
      TravelExpansionFramework.opalo_repair_starter_room_state!(map_id, "map_setup") if defined?(TravelExpansionFramework) &&
                                                                                       TravelExpansionFramework.respond_to?(:opalo_repair_starter_room_state!)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:empyrean_map?) &&
         TravelExpansionFramework.respond_to?(:empyrean_prepare_bridge_cache!) &&
         TravelExpansionFramework.empyrean_map?(map_id)
        TravelExpansionFramework.empyrean_prepare_bridge_cache!(self)
      end
      return result
    end

    def playerPassable?(x, y, d, self_event = nil)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:empyrean_map?) &&
         TravelExpansionFramework.respond_to?(:empyrean_prepare_bridge_for_step!) &&
         TravelExpansionFramework.empyrean_map?(@map_id)
        TravelExpansionFramework.empyrean_prepare_bridge_for_step!(self, x, y, d)
      end
      result = tef_empyrean_original_playerPassable?(x, y, d, self_event)
      return true if !result &&
                     defined?(TravelExpansionFramework) &&
                     TravelExpansionFramework.respond_to?(:empyrean_bridge_step_passable?) &&
                     TravelExpansionFramework.empyrean_bridge_step_passable?(self, x, y, d)
      return result
    end
  end
end
