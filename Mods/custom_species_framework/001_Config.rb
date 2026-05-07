module CustomSpeciesFramework
  ROOT                = File.expand_path(File.dirname(__FILE__)) unless const_defined?(:ROOT)
  GAME_ROOT           = File.expand_path(File.join(ROOT, "..", "..")) unless const_defined?(:GAME_ROOT)
  MODS_DIR            = File.join(GAME_ROOT, "Mods") unless const_defined?(:MODS_DIR)
  DATA_DIR            = File.join(ROOT, "data") unless const_defined?(:DATA_DIR)
  CREATOR_DIR         = File.join(ROOT, "creator") unless const_defined?(:CREATOR_DIR)
  CREATOR_WEB_DIR     = File.join(CREATOR_DIR, "web") unless const_defined?(:CREATOR_WEB_DIR)
  CREATOR_DATA_DIR    = File.join(CREATOR_DIR, "data") unless const_defined?(:CREATOR_DATA_DIR)
  CREATOR_SPECIES_FILE = File.join(DATA_DIR, "species", "user_created_species.json") unless const_defined?(:CREATOR_SPECIES_FILE)
  CREATOR_STARTER_SETS_FILE = File.join(DATA_DIR, "creator_starter_sets.json") unless const_defined?(:CREATOR_STARTER_SETS_FILE)
  CREATOR_DELIVERY_FILE = File.join(DATA_DIR, "creator_delivery_queue.json") unless const_defined?(:CREATOR_DELIVERY_FILE)
  CREATOR_CATALOG_FILE = File.join(CREATOR_DATA_DIR, "game_catalog.json") unless const_defined?(:CREATOR_CATALOG_FILE)
  EXTERNAL_SPECIES_RELATIVE_DIR = File.join("data", "custom_species_framework", "species") unless const_defined?(:EXTERNAL_SPECIES_RELATIVE_DIR)
  INTERNAL_PREFIX     = "CSF_" unless const_defined?(:INTERNAL_PREFIX)
  ORIGINAL_INFINITE_STARTER_SET_ID = "__original_infinite__" unless const_defined?(:ORIGINAL_INFINITE_STARTER_SET_ID)
  LEGACY_RESERVED_ID_MIN = 252000 unless const_defined?(:LEGACY_RESERVED_ID_MIN)
  FRAMEWORK_BASE_NB_POKEMON = Settings::NB_POKEMON unless const_defined?(:FRAMEWORK_BASE_NB_POKEMON)

  def self.path_within_root?(root_path, candidate_path)
    expanded_root = File.realpath(root_path.to_s) rescue File.expand_path(root_path.to_s)
    expanded_candidate = File.realpath(candidate_path.to_s) rescue File.expand_path(candidate_path.to_s)
    return true if expanded_candidate == expanded_root
    normalized_root = expanded_root.end_with?(File::SEPARATOR) ? expanded_root : expanded_root + File::SEPARATOR
    return expanded_candidate.start_with?(normalized_root)
  end

  def self.core_species_json_paths
    species_dir = File.join(DATA_DIR, "species")
    return [] if !Dir.exist?(species_dir)
    return Dir.glob(File.join(species_dir, "*.json")).sort.map { |path| File.expand_path(path) }
  end

  def self.external_species_json_paths
    return [] if !Dir.exist?(MODS_DIR)
    ret = []
    Dir.glob(File.join(MODS_DIR, "*")).sort.each do |mod_path|
      next if !File.directory?(mod_path)
      expanded_mod_path = File.expand_path(mod_path)
      next if expanded_mod_path == ROOT

      species_dir = File.join(expanded_mod_path, EXTERNAL_SPECIES_RELATIVE_DIR)
      next if !Dir.exist?(species_dir)

      Dir.glob(File.join(species_dir, "**", "*.json")).sort.each do |candidate_path|
        expanded_candidate = File.expand_path(candidate_path)
        next if !path_within_root?(expanded_mod_path, expanded_candidate)
        ret << expanded_candidate
      end
    end
    return ret
  end

  def self.discovered_species_json_paths
    ordered_paths = core_species_json_paths + external_species_json_paths
    seen = {}
    return ordered_paths.each_with_object([]) do |absolute_path, ret|
      normalized = File.expand_path(absolute_path)
      next if seen[normalized]
      seen[normalized] = true
      ret << normalized
    end
  end

  FRAMEWORK_DISCOVERED_MAX_SLOT = begin
    discovered_max_slot = 0
    discovered_species_json_paths.each do |absolute_path|
      begin
        raw = File.read(absolute_path)
        raw.scan(/"slot"\s*:\s*(\d+)/i) do |match|
          discovered_max_slot = [discovered_max_slot, match[0].to_i].max
        end
        raw.scan(/"id_number"\s*:\s*(\d+)/i) do |match|
          raw_id_number = match[0].to_i
          next if raw_id_number < LEGACY_RESERVED_ID_MIN
          discovered_max_slot = [discovered_max_slot, raw_id_number - LEGACY_RESERVED_ID_MIN].max
        end
      rescue
      end
    end
    discovered_max_slot
  end unless const_defined?(:FRAMEWORK_DISCOVERED_MAX_SLOT)
  FRAMEWORK_CONTENT_SLOTS = FRAMEWORK_DISCOVERED_MAX_SLOT unless const_defined?(:FRAMEWORK_CONTENT_SLOTS)
  FRAMEWORK_RESERVED_SLOTS = FRAMEWORK_CONTENT_SLOTS + 1 unless const_defined?(:FRAMEWORK_RESERVED_SLOTS)
  FRAMEWORK_FIRST_ID = FRAMEWORK_BASE_NB_POKEMON + 1 unless const_defined?(:FRAMEWORK_FIRST_ID)
  FRAMEWORK_LAST_ID  = FRAMEWORK_FIRST_ID + FRAMEWORK_RESERVED_SLOTS - 1 unless const_defined?(:FRAMEWORK_LAST_ID)
  MISSING_SPECIES_ID  = :CSF_MISSINGNO unless const_defined?(:MISSING_SPECIES_ID)
  MISSING_SPECIES_NUM = FRAMEWORK_LAST_ID unless const_defined?(:MISSING_SPECIES_NUM)
  LOG_PREFIX          = "[CustomSpeciesFramework]" unless const_defined?(:LOG_PREFIX)
  LOG_FILE            = File.join(ROOT, "framework_debug.log") unless const_defined?(:LOG_FILE)

  if Settings::NB_POKEMON != FRAMEWORK_LAST_ID
    module ::Settings
      remove_const :NB_POKEMON if const_defined?(:NB_POKEMON)
      NB_POKEMON = CustomSpeciesFramework::FRAMEWORK_LAST_ID
      remove_const :ZAPMOLCUNO_NB if const_defined?(:ZAPMOLCUNO_NB)
      ZAPMOLCUNO_NB = (NB_POKEMON * NB_POKEMON) + NB_POKEMON + 1
    end
    Object.send(:remove_const, :NB_POKEMON) if Object.const_defined?(:NB_POKEMON)
    Object.const_set(:NB_POKEMON, Settings::NB_POKEMON)
  end

  STAT_KEY_MAP = {
    "HP"              => :HP,
    "ATTACK"          => :ATTACK,
    "DEFENSE"         => :DEFENSE,
    "SPECIAL_ATTACK"  => :SPECIAL_ATTACK,
    "SPECIAL_DEFENSE" => :SPECIAL_DEFENSE,
    "SPEED"           => :SPEED
  } unless const_defined?(:STAT_KEY_MAP)

  DEFAULT_CONFIG = {
    "version"                  => "1.1.0",
    "enabled"                  => true,
    "replace_default_starters" => true,
    "active_starter_set"       => "framework_default",
    "deterministic_load"       => true,
    "diagnostics"              => true,
    "export_creator_catalog_on_boot" => false
  } unless const_defined?(:DEFAULT_CONFIG)
  STARTER_SELECTION_COMMON_EVENT_ID = 46 unless const_defined?(:STARTER_SELECTION_COMMON_EVENT_ID)
  MIXED_GENERATIONS_SWITCH_ID       = 889 unless const_defined?(:MIXED_GENERATIONS_SWITCH_ID)
  HOME_PC_MENU_LABEL                = "Custom Species Delivery" unless const_defined?(:HOME_PC_MENU_LABEL)
  HOME_PC_DELIVERY_SENDER           = "Pokedex Studio" unless const_defined?(:HOME_PC_DELIVERY_SENDER)

  class << self
    attr_reader :boot_completed
    attr_reader :config
    attr_reader :encounter_hooks
    attr_reader :errors
    attr_reader :metadata_by_id_number
    attr_reader :metadata_by_symbol
    attr_reader :species_definitions
    attr_reader :starter_sets
    attr_reader :trainer_hooks
    attr_reader :warnings
  end

  @boot_completed      = false
  @config              = DEFAULT_CONFIG.dup
  @species_definitions = []
  @metadata_by_symbol  = {}
  @metadata_by_id_number = {}
  @starter_sets        = {}
  @encounter_hooks     = []
  @trainer_hooks       = []
  @warnings            = []
  @errors              = []

  def self.log(message)
    formatted = "#{LOG_PREFIX} #{message}"
    echoln(formatted) rescue nil
    begin
      File.open(LOG_FILE, "a") { |file| file.puts("[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{formatted}") }
    rescue
    end
  end

  def self.debug?
    return false if !@config
    return boolean_value(@config["diagnostics"], true)
  end

  def self.export_creator_catalog_on_boot?
    return false if !@config
    return boolean_value(@config["export_creator_catalog_on_boot"], false)
  end

  def self.boolean_value(value, default = false)
    return default if value.nil?
    return value if value == true || value == false
    case value.to_s.strip.downcase
    when "1", "true", "yes", "on"  then return true
    when "0", "false", "no", "off" then return false
    end
    return default
  end

  def self.blank?(value)
    return true if value.nil?
    return value.empty? if value.respond_to?(:empty?)
    return value.to_s.strip.empty?
  end

  def self.symbolize(value)
    return nil if value.nil?
    return value if value.is_a?(Symbol)
    return value.to_sym if value.is_a?(String)
    return value
  end

  def self.framework_slot_from_legacy_id_number(id_number)
    return nil if id_number.nil?
    numeric_id = id_number.to_i
    return nil if numeric_id < LEGACY_RESERVED_ID_MIN
    slot = numeric_id - LEGACY_RESERVED_ID_MIN
    return nil if slot <= 0
    return slot
  end

  def self.framework_slot_from_absolute_id_number(id_number)
    return nil if id_number.nil?
    numeric_id = id_number.to_i
    return nil if numeric_id < FRAMEWORK_FIRST_ID
    return nil if numeric_id >= MISSING_SPECIES_NUM
    return (numeric_id - FRAMEWORK_FIRST_ID) + 1
  end

  def self.framework_slot_from_configured_id_number(id_number)
    slot = framework_slot_from_absolute_id_number(id_number)
    return slot if slot
    return framework_slot_from_legacy_id_number(id_number)
  end

  def self.framework_id_from_slot(slot)
    return nil if slot.nil?
    slot_number = slot.to_i
    return nil if slot_number <= 0
    return FRAMEWORK_FIRST_ID + slot_number - 1
  end

  def self.translate_legacy_species_number(id_number)
    slot = framework_slot_from_legacy_id_number(id_number)
    return nil if slot.nil?
    return nil if slot > FRAMEWORK_CONTENT_SLOTS
    translated_id = framework_id_from_slot(slot)
    return translated_id
  end

  def self.compatibility_alias_map
    @compatibility_alias_map ||= {}
  end

  def self.compatibility_alias_context_map
    @compatibility_alias_context_map ||= {}
  end

  def self.compatibility_number_alias_map
    @compatibility_number_alias_map ||= {}
  end

  def self.compatibility_number_alias_context_map
    @compatibility_number_alias_context_map ||= {}
  end

  def self.framework_absolute_id_number?(id_number)
    numeric_id = id_number.to_i
    return numeric_id >= FRAMEWORK_FIRST_ID && numeric_id <= FRAMEWORK_LAST_ID
  end

  def self.clear_species_data_lookup_cache!
    @species_data_by_id_number = nil
  end

  def self.species_data_by_id_number
    return @species_data_by_id_number if @species_data_by_id_number
    lookup = {}
    if defined?(GameData::Species::DATA)
      GameData::Species::DATA.each_value do |entry|
        next if !entry || !entry.respond_to?(:id_number)
        number = entry.id_number.to_i
        lookup[number] ||= entry if number > 0
      end
    end
    @species_data_by_id_number = lookup
    return lookup
  rescue
    @species_data_by_id_number = {}
    return @species_data_by_id_number
  end

  def self.species_data_for_id_number(id_number)
    return nil if id_number.nil?
    numeric_id = id_number.to_i
    return nil if numeric_id <= 0
    return nil if !defined?(GameData::Species::DATA)
    direct = GameData::Species::DATA[numeric_id] rescue nil
    return direct if direct && direct.respond_to?(:id_number)
    return species_data_by_id_number[numeric_id]
  rescue
    return nil
  end

  def self.current_number_alias_expansion_context(expansion_id = nil)
    context = expansion_id
    return nil if !defined?(TravelExpansionFramework) && (context.nil? || context.to_s.empty?)
    context = TravelExpansionFramework.current_runtime_expansion_id if (context.nil? || context.to_s.empty?) &&
                                                                       TravelExpansionFramework.respond_to?(:current_runtime_expansion_id)
    context = TravelExpansionFramework.current_expansion_id if (context.nil? || context.to_s.empty?) &&
                                                              TravelExpansionFramework.respond_to?(:current_expansion_id)
    context = TravelExpansionFramework.current_expansion_marker if (context.nil? || context.to_s.empty?) &&
                                                                  TravelExpansionFramework.respond_to?(:current_expansion_marker)
    return nil if context.nil? || context.to_s.empty?
    return context.to_s.downcase
  rescue
    return nil
  end

  def self.number_alias_entry_matches_context?(entry, context_key)
    return false if !entry.is_a?(Hash) || context_key.nil? || context_key.to_s.empty?
    source_text = [
      entry[:source_pack],
      entry[:source_section],
      entry[:canonical_id]
    ].compact.join(" ").downcase
    %w[
      uranium xenoverse reborn insurgence anil indigo opalo empyrean realidea soulstones
      bushido darkhorizon dark_horizon infinity solar_eclipse solareclipse vanguard pokemon_z pokemonz
      chaos_in_vesita chaosinvesita deserted gadir_deluxe gadirdeluxe gadirdelux
      hollow_woods hollowwoods keishou unbreakable_ties unbreakableties
    ].each do |token|
      return true if context_key.include?(token) && source_text.include?(token)
    end
    return false
  end

  def self.compatibility_number_alias_target(id_number, expansion_id = nil)
    numeric_id = id_number.to_i
    return nil if numeric_id <= 0
    entries = compatibility_number_alias_context_map[numeric_id]
    return nil if entries.nil? || entries.empty?
    context_key = current_number_alias_expansion_context(expansion_id)
    if context_key
      match = entries.find { |entry| number_alias_entry_matches_context?(entry, context_key) }
      return match[:canonical_id] if match
    end
    return nil if framework_absolute_id_number?(numeric_id)
    return nil
  end

  def self.compatibility_alias_target(species, expansion_id = nil)
    return nil if species.nil?
    if species.is_a?(String) || species.is_a?(Symbol)
      symbol = species.to_sym
      entries = compatibility_alias_context_map[symbol]
      context_key = current_number_alias_expansion_context(expansion_id)
      if entries && context_key
        match = entries.find { |entry| number_alias_entry_matches_context?(entry, context_key) }
        return match[:canonical_id] if match
      end
      return nil if entries && !entries.empty? && host_species_symbol?(symbol)
      return compatibility_alias_map[symbol]
    end
    if species.is_a?(Integer)
      translated_id = translate_legacy_species_number(species)
      return translated_id if translated_id
      return compatibility_number_alias_target(species, expansion_id)
    end
    return nil
  end

  def self.custom_internal_symbol?(species)
    symbol = canonical_species_id(species)
    return false if symbol.nil?
    return symbol.to_s.start_with?(INTERNAL_PREFIX)
  end

  def self.canonical_species_id(species)
    return nil if species.nil?
    if species.is_a?(Pokemon)
      return species.species
    elsif species.is_a?(GameData::Species)
      return species.species
    elsif species.is_a?(Integer)
      translated_id = translate_legacy_species_number(species)
      species = translated_id if translated_id
      if !framework_absolute_id_number?(species)
        aliased_species = compatibility_alias_target(species)
        return aliased_species if aliased_species.is_a?(Symbol)
      end
      species_data = nil
      species_data = GameData::Species::DATA[species] if defined?(GameData::Species::DATA)
      species_data ||= species_data_for_id_number(species)
      return species_data.species if species_data
      return nil
    elsif species.is_a?(String)
      aliased_species = compatibility_alias_target(species)
      return aliased_species if aliased_species.is_a?(Symbol)
      return species.to_sym
    elsif species.is_a?(Symbol)
      aliased_species = compatibility_alias_target(species)
      return aliased_species if aliased_species.is_a?(Symbol)
      return species
    end
    return nil
  end

  def self.resolve_id_number(species)
    return nil if species.nil?
    if species.is_a?(Integer)
      translated_id = translate_legacy_species_number(species)
      return translated_id if translated_id
      if !framework_absolute_id_number?(species)
        aliased_species = compatibility_alias_target(species)
        if aliased_species.is_a?(Symbol) && defined?(GameData::Species::DATA)
          species_data = GameData::Species::DATA[aliased_species]
          return species_data.id_number if species_data
        end
      end
      return species
    end
    canonical_species = canonical_species_id(species)
    species_data = nil
    species_data = GameData::Species::DATA[canonical_species] if canonical_species && defined?(GameData::Species::DATA)
    species_data ||= GameData::Species.try_get(canonical_species) rescue nil
    return species_data.id_number if species_data
    return nil
  end

  def self.metadata_for(species)
    symbol = canonical_species_id(species)
    return @metadata_by_symbol[symbol] if symbol && @metadata_by_symbol[symbol]
    id_number = resolve_id_number(species)
    return @metadata_by_id_number[id_number] if id_number && @metadata_by_id_number[id_number]
    return nil
  end

  def self.custom_species?(species)
    return !metadata_for(species).nil?
  end

  def self.host_species_symbol?(species)
    symbol = symbolize(species)
    return false if symbol.nil?
    return false if @metadata_by_symbol && @metadata_by_symbol[symbol]
    return false if !defined?(GameData::Species::DATA)
    data = GameData::Species::DATA[symbol] rescue nil
    return data && data.respond_to?(:species) && data.species == symbol
  rescue
    return false
  end

  def self.custom_species_dex_visible?(species)
    metadata = metadata_for(species)
    return false if metadata.nil?
    return metadata[:dex_visible] if metadata[:dex_visible] == true || metadata[:dex_visible] == false
    return false if metadata[:kind] == :framework_placeholder
    return true if metadata[:kind] == :fakemon
    return true if metadata[:kind] == :regional_variant
    if metadata[:kind] == :external_bridge
      aliases = Array(metadata[:compatibility_aliases])
      return true if aliases.empty?
      return aliases.any? { |alias_id| !host_species_symbol?(alias_id) }
    end
    return false
  end

  def self.actual_fusion_number?(species_or_number)
    id_number = resolve_id_number(species_or_number)
    return false if id_number.nil?
    return false if custom_species_id_number?(id_number)
    return false if id_number >= Settings::ZAPMOLCUNO_NB
    return id_number > Settings::NB_POKEMON
  end

  def self.actual_triple_fusion_number?(species_or_number)
    id_number = resolve_id_number(species_or_number)
    return false if id_number.nil?
    return id_number >= Settings::ZAPMOLCUNO_NB
  end

  def self.custom_species_id_number?(id_number)
    return false if id_number.nil?
    translated_id = translate_legacy_species_number(id_number)
    id_number = translated_id if translated_id
    return !@metadata_by_id_number[id_number].nil?
  end

  def self.fusion_safe_source?(metadata)
    return true if metadata.nil?
    source_text = [
      metadata[:source_pack],
      metadata[:source_section],
      metadata[:template_source_label],
      metadata[:framework_species_key],
      metadata[:export_pack_name]
    ].compact.join(" ").downcase
    return true if source_text.include?("infinite fusion")
    return true if source_text.include?("kuray")
    return true if source_text.match?(/\bkif\b/)
    return true if source_text.match?(/\bpif\b/)
    return true if source_text.include?("full implementation")
    return true if source_text.include?("full_implementation")
    return true if source_text.include?("full dex")
    return false
  rescue
    return false
  end

  def self.fusion_policy_allows_custom_species?(metadata)
    return true if metadata.nil?
    kind = metadata[:kind]
    return true if kind != :fakemon && kind != :regional_variant
    return fusion_safe_source?(metadata)
  end

  def self.standard_fusion_compatible?(species)
    metadata = metadata_for(species)
    return true if metadata.nil?
    return false if actual_fusion_number?(species) || actual_triple_fusion_number?(species)
    return false if !fusion_policy_allows_custom_species?(metadata)
    return metadata[:fusion_rule] == :standard && metadata[:standard_fusion_compatible]
  end

  def self.fusion_rule(species)
    metadata = metadata_for(species)
    return :standard if metadata.nil?
    return metadata[:fusion_rule] || :blocked
  end

  def self.display_name(species)
    return species.name if species.is_a?(Pokemon)
    species_data = GameData::Species.try_get(species) rescue nil
    return species_data.name if species_data
    return species.to_s
  end

  def self.fusion_block_message_for(species)
    return nil if standard_fusion_compatible?(species)
    name = display_name(species)
    case fusion_rule(species)
    when :blocked
      return _INTL("{1}'s DNA is too unstable to fuse.", name)
    when :restricted
      return _INTL("{1} doesn't have stock fusion output data enabled.", name)
    else
      return _INTL("{1} can't be fused right now.", name)
    end
  end

  def self.can_show_fuse_command?(pokemon)
    return false if pokemon.nil?
    return false if pokemon.egg?
    return false if pokemon.isFusion?
    return standard_fusion_compatible?(pokemon)
  end

  def self.can_fuse_pair?(pokemon_a, pokemon_b)
    return false if pokemon_a.nil? || pokemon_b.nil?
    return false if pokemon_a == pokemon_b
    return false if pokemon_a.egg? || pokemon_b.egg?
    return false if pokemon_a.hp == 0 || pokemon_b.hp == 0
    return false if pokemon_a.isFusion? || pokemon_b.isFusion?
    return standard_fusion_compatible?(pokemon_a) && standard_fusion_compatible?(pokemon_b)
  end

  def self.fusion_pair_message(pokemon_a, pokemon_b)
    message = fusion_block_message_for(pokemon_a)
    return message if message
    message = fusion_block_message_for(pokemon_b)
    return message if message
    return _INTL("{1} can't be fused with {2}.", display_name(pokemon_b), display_name(pokemon_a))
  end

  def self.fallback_species_for(species)
    metadata = metadata_for(species)
    return nil if metadata.nil?
    return metadata[:fallback_species]
  end

  def self.asset_path(kind, species)
    metadata = metadata_for(species)
    return nil if metadata.nil?
    assets = metadata[:assets] || {}
    path = assets[kind]
    return nil if blank?(path)
    resolved = pbResolveBitmap(path) rescue nil
    return resolved if resolved
    return mod_asset_source_path(path)
  end

  def self.mod_asset_source_path(path)
    return nil if blank?(path)
    normalized = path.to_s.tr("/", File::SEPARATOR)
    candidates = [
      File.join(ROOT, normalized),
      File.join(ROOT, normalized + ".png"),
      File.join(GAME_ROOT, normalized),
      File.join(GAME_ROOT, normalized + ".png")
    ]
    candidates.each do |candidate|
      return candidate if File.exist?(candidate)
    end
    return nil
  end

  def self.asset_available?(path)
    return false if blank?(path)
    resolved = pbResolveBitmap(path) rescue nil
    return true if resolved
    return true if mod_asset_source_path(path)
    return false
  end

  def self.runtime_icon_path(species)
    id_number = resolve_id_number(species)
    return nil if id_number.nil?
    runtime_path = pbResolveBitmap(sprintf("Graphics/Icons/icon%03d", id_number)) rescue nil
    return runtime_path if runtime_path
    runtime_path = pbResolveBitmap(sprintf("Graphics/Icons/icon%d", id_number)) rescue nil
    return runtime_path if runtime_path
    return nil
  end

  def self.preferred_icon_path(species)
    runtime_path = runtime_icon_path(species)
    return runtime_path if runtime_path
    return asset_path(:icon, species)
  end

  def self.runtime_battler_path(species, back = false)
    folder = back ? "Back" : "Front"
    canonical_species = canonical_species_id(species)
    if canonical_species
      runtime_path = pbResolveBitmap(sprintf("Graphics/Pokemon/%s/%s", folder, canonical_species)) rescue nil
      return runtime_path if runtime_path
    end
    id_number = resolve_id_number(species)
    if id_number && id_number > 0
      runtime_path = pbResolveBitmap(sprintf("Graphics/Pokemon/%s/%d", folder, id_number)) rescue nil
      return runtime_path if runtime_path
      runtime_path = pbResolveBitmap(sprintf("Graphics/EBDX/Battlers/%s/%d", folder, id_number)) rescue nil
      return runtime_path if runtime_path
    end
    return nil
  end

  def self.resolve_graphic(kind, species)
    if kind == :front || kind == :back
      runtime_path = runtime_battler_path(species, kind == :back)
      return runtime_path if runtime_path
    end
    direct_path = asset_path(kind, species)
    return direct_path if direct_path
    fallback_species = fallback_species_for(species)
    return nil if fallback_species.nil?
    return fallback_species
  end

  def self.active?
    return false if !@boot_completed
    return false if !boolean_value(@config["enabled"], true)
    return @errors.empty?
  end

  def self.override_default_starters?
    return false if !active?
    return false if current_starter_set.nil?
    return false if !$PokemonGlobal || !$PokemonGlobal.respond_to?(:csf_selected_starter_set)
    selected_id = $PokemonGlobal.csf_selected_starter_set.to_s
    return false if blank?(selected_id) || selected_id == ORIGINAL_INFINITE_STARTER_SET_ID
    return current_starter_set[:replace_default_starters]
  end

  def self.current_starter_set_id
    return nil if runtime_special_startup_mode
    if $PokemonGlobal
      if $PokemonGlobal.respond_to?(:csf_selected_starter_set)
        selected_id = $PokemonGlobal.csf_selected_starter_set
        return nil if selected_id.to_s == ORIGINAL_INFINITE_STARTER_SET_ID
        return selected_id.to_s if !blank?(selected_id) && @starter_sets[selected_id.to_s]
      end
      if $PokemonGlobal.respond_to?(:csf_active_starter_set)
        legacy_id = $PokemonGlobal.csf_active_starter_set
        return legacy_id.to_s if !blank?(legacy_id) && @starter_sets[legacy_id.to_s]
      end
    end
    runtime_id = starter_set_id_from_runtime_switches
    return runtime_id if runtime_id
    configured_id = @config["active_starter_set"].to_s
    return configured_id if @starter_sets[configured_id]
    return @starter_sets.keys.sort[0]
  end

  def self.current_starter_set
    return nil if @starter_sets.nil? || @starter_sets.empty?
    key = current_starter_set_id.to_s
    return @starter_sets[key]
  end

  def self.startup_starter_sets
    ret = @starter_sets.values.find_all { |starter_set| starter_set[:intro_selectable] }
    ret.sort_by { |starter_set| [starter_set[:intro_order], starter_set[:label].to_s] }
  end

  def self.default_startup_starter_set_id
    intro_default = startup_starter_sets.find { |starter_set| starter_set[:intro_default] }
    return intro_default[:id] if intro_default
    configured_id = @config["active_starter_set"].to_s
    return configured_id if @starter_sets[configured_id]
    first_set = startup_starter_sets[0]
    return first_set[:id] if first_set
    return current_starter_set_id
  end

  def self.startup_mode_for(starter_set_id = nil)
    starter_set = starter_set_id ? @starter_sets[starter_set_id.to_s] : current_starter_set
    return "species_override" if starter_set.nil?
    return starter_set[:startup_mode].to_s
  end

  def self.reset_startup_switches!
    return if !$game_switches
    all_startup_switches.each { |switch_id| $game_switches[switch_id] = false }
  end

  def self.apply_starter_set_selection!(starter_set_id)
    return select_original_infinite_startup_mode! if starter_set_id.to_s == ORIGINAL_INFINITE_STARTER_SET_ID
    starter_set = @starter_sets[starter_set_id.to_s]
    return nil if starter_set.nil?
    reset_startup_switches!
    if $PokemonGlobal && $PokemonGlobal.respond_to?(:csf_selected_starter_set=)
      $PokemonGlobal.csf_selected_starter_set = starter_set[:id]
    end

    switch_id = startup_mode_switches[startup_mode_for(starter_set[:id])]
    $game_switches[switch_id] = true if $game_switches && switch_id
    ensure_global_metadata! if $PokemonGlobal && respond_to?(:ensure_global_metadata!)
    return starter_set
  end

  def self.select_original_infinite_startup_mode!
    reset_startup_switches!
    if $PokemonGlobal && $PokemonGlobal.respond_to?(:csf_selected_starter_set=)
      $PokemonGlobal.csf_selected_starter_set = ORIGINAL_INFINITE_STARTER_SET_ID
    end
    ensure_global_metadata! if $PokemonGlobal && respond_to?(:ensure_global_metadata!)
    return ORIGINAL_INFINITE_STARTER_SET_ID
  end

  def self.select_special_startup_mode!(mode_key)
    switch_id = special_startup_mode_switches[mode_key.to_s]
    return nil if switch_id.nil?
    reset_startup_switches!
    if $PokemonGlobal && $PokemonGlobal.respond_to?(:csf_selected_starter_set=)
      $PokemonGlobal.csf_selected_starter_set = nil
    end
    $game_switches[switch_id] = true if $game_switches
    ensure_global_metadata! if $PokemonGlobal && respond_to?(:ensure_global_metadata!)
    return mode_key.to_s
  end

  def self.apply_intro_starter_option!(option_key)
    case option_key.to_s
    when "original_infinite", "original", "infinite", "kif", "vanilla", "default"
      return select_original_infinite_startup_mode!
    when "framework_default", "fakemon_trio"
      return apply_starter_set_selection!("framework_default")
    when "kanto_classic", "kanto"
      return apply_starter_set_selection!("kanto_classic")
    when "johto_classic", "johto"
      return apply_starter_set_selection!("johto_classic")
    when "hoenn_classic", "hoenn"
      return apply_starter_set_selection!("hoenn_classic")
    when "sinnoh_classic", "sinnoh"
      return apply_starter_set_selection!("sinnoh_classic")
    when "kalos_classic", "kalos"
      return apply_starter_set_selection!("kalos_classic")
    when "mixed_generations"
      return select_special_startup_mode!("mixed_generations")
    when "manual_custom", "custom"
      return select_special_startup_mode!("manual_custom")
    end
    return nil
  end

  def self.easter_egg_custom_starter_active?
    return false if !$game_switches || !$game_switches[SWITCH_CUSTOM_STARTERS]
    player_choice = pbGet(VAR_PLAYER_STARTER_CHOICE) rescue 0
    rival_head    = pbGet(VAR_RIVAL_STARTER_HEAD_CHOICE) rescue 0
    rival_body    = pbGet(VAR_RIVAL_STARTER_BODY_CHOICE) rescue 0
    return player_choice.to_i > 0 && rival_head.to_i > 0 && rival_body.to_i > 0
  end

  def self.prompt_startup_starter_set!
    return nil if !active?
    return nil if startup_starter_sets.empty?
    return nil if easter_egg_custom_starter_active?
    if $PokemonGlobal && $PokemonGlobal.respond_to?(:csf_selected_starter_set)
      selected_id = $PokemonGlobal.csf_selected_starter_set
      return nil if selected_id.to_s == ORIGINAL_INFINITE_STARTER_SET_ID
      return @starter_sets[selected_id.to_s] if !blank?(selected_id) && @starter_sets[selected_id.to_s]
    end

    default_id = default_startup_starter_set_id
    command_labels = startup_starter_sets.map { |starter_set| starter_set[:label] }
    default_index = startup_starter_sets.index { |starter_set| starter_set[:id] == default_id } || 0
    choice = pbMessage(
      _INTL("\\C[7]Choose this save file's starter set."),
      command_labels,
      default_index + 1,
      nil,
      default_index
    )
    selected_set = startup_starter_sets[choice] || startup_starter_sets[default_index]
    return apply_starter_set_selection!(selected_set[:id])
  end

  def self.prompt_legacy_startup_starter_set!
    return nil if !active?
    command_map = [
      [_INTL("Kanto"), "kanto_classic"],
      [_INTL("Johto"), "johto_classic"],
      [_INTL("Hoenn"), "hoenn_classic"],
      [_INTL("Sinnoh"), "sinnoh_classic"]
    ]
    command_map << [_INTL("Kalos"), "kalos_classic"] if @starter_sets["kalos_classic"]
    command_map << [_INTL("Fakemon Trio"), "framework_default"] if @starter_sets["framework_default"]
    return nil if command_map.empty?
    default_index = command_map.index { |_, starter_key| starter_key == default_startup_starter_set_id } || 0
    choice = pbMessage(_INTL("Use which set of starters?"), command_map.map { |entry| entry[0] }, default_index)
    selected = command_map[choice] || command_map[default_index]
    return apply_intro_starter_option!(selected[1])
  end

  def self.startup_mode_switches
    return {
      "kanto_map" => nil,
      "custom_map" => (defined?(SWITCH_CUSTOM_STARTERS) ? SWITCH_CUSTOM_STARTERS : nil),
      "johto_map"  => (defined?(SWITCH_JOHTO_STARTERS) ? SWITCH_JOHTO_STARTERS : nil),
      "hoenn_map"  => (defined?(SWITCH_HOENN_STARTERS) ? SWITCH_HOENN_STARTERS : nil),
      "sinnoh_map" => (defined?(SWITCH_SINNOH_STARTERS) ? SWITCH_SINNOH_STARTERS : nil),
      "kalos_map"  => (defined?(SWITCH_KALOS_STARTERS) ? SWITCH_KALOS_STARTERS : nil)
    }
  end

  def self.special_startup_mode_switches
    return {
      "mixed_generations" => MIXED_GENERATIONS_SWITCH_ID,
      "manual_custom"     => (defined?(SWITCH_CUSTOM_STARTERS) ? SWITCH_CUSTOM_STARTERS : nil)
    }
  end

  def self.all_startup_switches
    return (startup_mode_switches.values + special_startup_mode_switches.values).compact.uniq
  end

  def self.runtime_special_startup_mode
    return nil if !$game_switches
    special_startup_mode_switches.each_pair do |mode_key, switch_id|
      next if switch_id.nil?
      return mode_key if $game_switches[switch_id]
    end
    return nil
  end

  def self.starter_set_id_from_runtime_switches
    return nil if !$game_switches
    startup_starter_sets.each do |starter_set|
      switch_id = startup_mode_switches[starter_set[:startup_mode]]
      next if switch_id.nil?
      return starter_set[:id] if $game_switches[switch_id]
    end
    return nil
  end

  def self.starter_selection_common_event
    return nil if !$data_common_events
    event = $data_common_events[STARTER_SELECTION_COMMON_EVENT_ID]
    return nil if event.nil?
    return nil if !event.respond_to?(:list)
    return event
  end

  def self.starter_selection_common_event_patched?
    return !!@starter_selection_common_event_patched
  end

  def self.starter_selection_common_event_patchable?
    event = starter_selection_common_event
    return false if event.nil?
    list = event.list
    return false if event.name.to_s != "starter set selection"
    return false if list.nil? || list.length < 96
    return false if list[13].nil? || list[13].code != 101
    return false if list[14].nil? || list[14].code != 401
    return false if list[38].nil? || list[38].code != 111
    return true
  end

  def self.build_event_command(code, indent, parameters)
    return RPG::EventCommand.new(code, indent, parameters)
  end

  def self.build_script_command(indent, script)
    return build_event_command(355, indent, [script])
  end

  def self.patch_starter_selection_common_event!
    return true if starter_selection_common_event_patched?
    return false if !active?
    return false if !starter_selection_common_event_patchable?

    event = starter_selection_common_event
    list = event.list

    list[13].parameters = ["\\ch[1,0,Kanto,Johto,Hoenn,Sinnoh,Kalos,"]
    list[14].parameters = [" Mixed Generations, Fakemon Trio, Custom]"]

    list[16] = build_script_command(5, "CustomSpeciesFramework.apply_intro_starter_option!('kanto_classic')")
    list[19] = build_script_command(5, "CustomSpeciesFramework.apply_intro_starter_option!('johto_classic')")
    list[23] = build_script_command(5, "CustomSpeciesFramework.apply_intro_starter_option!('hoenn_classic')")
    list[27] = build_script_command(5, "CustomSpeciesFramework.apply_intro_starter_option!('sinnoh_classic')")
    list[31] = build_script_command(5, "CustomSpeciesFramework.apply_intro_starter_option!('kalos_classic')")
    list[35] = build_script_command(5, "CustomSpeciesFramework.apply_intro_starter_option!('mixed_generations')")
    list[38].parameters = [1, 1, 0, 7, 0]
    list[69] = build_script_command(7, "CustomSpeciesFramework.apply_intro_starter_option!('manual_custom')")

    fakemon_branch = [
      build_event_command(111, 4, [1, 1, 0, 6, 0]),
      build_script_command(5, "CustomSpeciesFramework.apply_intro_starter_option!('framework_default')"),
      build_event_command(0, 5, []),
      build_event_command(412, 4, [])
    ]
    list.insert(38, *fakemon_branch)

    fallback_commands = [
      build_script_command(4, "CustomSpeciesFramework.prompt_legacy_startup_starter_set!"),
      build_event_command(0, 4, [])
    ]
    list[85, 15] = fallback_commands

    @starter_selection_common_event_patched = true
    log("Patched Common Event #{STARTER_SELECTION_COMMON_EVENT_ID} starter menu with framework starter support.") if debug?
    return true
  rescue => e
    log("Starter menu patch failed: #{e.message}") if debug?
    return false
  end

  def self.starter_species
    starter_set = current_starter_set
    return [] if starter_set.nil?
    return starter_set[:species]
  end

  def self.starter_for_index(index)
    starters = starter_species
    return nil if starters.nil? || starters.empty?
    return starters[index]
  end

  def self.player_starter_index_from_remaining(remaining_a, remaining_b)
    indexes = [0, 1, 2]
    indexes.delete(remaining_a)
    indexes.delete(remaining_b)
    return indexes[0]
  end

  def self.rival_counterpick_for_player_index(index)
    starter_set = current_starter_set
    return nil if starter_set.nil?
    player_species = starter_set[:species][index]
    return nil if player_species.nil?
    return starter_set[:rival_counterpick][player_species]
  end

  def self.pokedex_species_ids
    ret = []
    @species_definitions.each do |definition|
      next if definition[:game_data][:id] == MISSING_SPECIES_ID
      next if !custom_species_dex_visible?(definition[:game_data][:id])
      ret << definition[:game_data][:id]
    end
    return ret
  end

  def self.framework_signature
    ordered = @species_definitions.sort_by { |definition| definition[:game_data][:id_number] }
    return ordered.map { |definition|
      "#{definition[:game_data][:id_number]}:#{definition[:game_data][:id]}"
    }.join("|")
  end
end
