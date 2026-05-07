module CustomSpeciesFramework
  ENUM_SYMBOL_ALIASES = {
    :growth_rate => {
      :MediumFast          => :Medium,
      :Medium_Slow         => :Parabolic,
      :MediumSlow          => :Parabolic,
      :SlowThenVeryFast    => :Fluctuating,
      :FastThenVerySlow    => :Erratic
    },
    :gender_ratio => {
      :Female12Point5Percent => :FemaleOneEighth,
      :Female87Point5Percent => :FemaleSevenEighths,
      :Male12Point5Percent   => :FemaleSevenEighths,
      :Male87Point5Percent   => :FemaleOneEighth,
      :FemaleOneEighths      => :FemaleOneEighth,
      :FemaleSevenEighth     => :FemaleSevenEighths
    },
    :body_shape => {
      :Blob        => :HeadBase,
      :Slime       => :HeadBase,
      :Amorphous   => :HeadBase,
      :Wings       => :Winged,
      :Wing        => :Winged,
      :BugWings    => :Insectoid,
      :BugWing     => :Insectoid,
      :Bug         => :Insectoid
    }
  } unless const_defined?(:ENUM_SYMBOL_ALIASES)

  def self.reset_runtime_state!
    @config                = DEFAULT_CONFIG.dup
    @species_definitions   = []
    @metadata_by_symbol    = {}
    @metadata_by_id_number = {}
    @compatibility_alias_map = {}
    @compatibility_alias_context_map = {}
    @compatibility_number_alias_map = {}
    @compatibility_number_alias_context_map = {}
    @starter_sets          = {}
    @encounter_hooks       = []
    @trainer_hooks         = []
    @warnings              = []
    @errors                = []
  end

  def self.load_json(relative_path, fallback)
    absolute_path = File.join(DATA_DIR, relative_path)
    return load_json_file(absolute_path, fallback, relative_path)
  end

  def self.load_json_file(absolute_path, fallback, source_label = nil)
    return fallback if absolute_path.nil? || !File.exist?(absolute_path)
    raw = File.read(absolute_path)
    raw = raw.sub(/\A\xEF\xBB\xBF/, "")
    parsed = ModManager::JSON.parse(raw)
    return parsed.nil? ? fallback : parsed
  rescue => e
    label = source_label || absolute_path.to_s
    @errors << "Failed to read #{label}: #{e.message}"
    return fallback
  end

  def self.extract_payload_array(payload, key)
    return payload if payload.is_a?(Array)
    return [] if !payload.is_a?(Hash)
    value = payload[key]
    value = payload[key.to_sym] if value.nil?
    return value.is_a?(Array) ? value : []
  end

  def self.load_runtime_data!
    reset_runtime_state!
    loaded_config = load_json("framework_config.json", {})
    @config.merge!(loaded_config) if loaded_config.is_a?(Hash)

    starter_payload = load_json("starter_sets.json", {})
    normalize_starter_sets!(extract_payload_array(starter_payload, "starter_sets"))
    creator_starter_payload = load_json("creator_starter_sets.json", {})
    normalize_starter_sets!(extract_payload_array(creator_starter_payload, "starter_sets"))

    load_all_species_files!

    @encounter_hooks = normalize_encounter_hooks(extract_payload_array(load_json("encounters.json", {}), "encounters"))
    @trainer_hooks   = normalize_trainer_hooks(extract_payload_array(load_json("trainer_hooks.json", {}), "trainer_hooks"))
  end

  def self.load_all_species_files!
    discovered_species_json_paths.each do |absolute_path|
      source_label = if path_within_root?(DATA_DIR, absolute_path)
        absolute_path.sub(DATA_DIR + File::SEPARATOR, "")
      elsif path_within_root?(GAME_ROOT, absolute_path)
        absolute_path.sub(GAME_ROOT + File::SEPARATOR, "")
      else
        absolute_path
      end
      payload = load_json_file(absolute_path, {}, source_label)
      species_array = extract_payload_array(payload, "species")
      if !payload.is_a?(Hash) && !payload.is_a?(Array)
        @warnings << "Skipped #{source_label}: expected a JSON object or array, got #{payload.class}."
        next
      end
      normalize_species_payload!(species_array)
    end
  end

  def self.normalize_starter_sets!(starter_sets)
    starter_sets.each do |raw_set|
      next if !raw_set.is_a?(Hash)
      set_id = raw_set["id"].to_s
      next if blank?(set_id)
      species = []
      (raw_set["species"] || []).each do |entry|
        species << symbolize(entry)
      end
      rival_counterpick = {}
      (raw_set["rival_counterpick"] || {}).each_pair do |player_species, rival_species|
        rival_counterpick[symbolize(player_species)] = symbolize(rival_species)
      end
      @starter_sets[set_id] = {
        :id                       => set_id,
        :label                    => blank?(raw_set["label"]) ? set_id : raw_set["label"].to_s,
        :replace_default_starters => boolean_value(raw_set["replace_default_starters"], set_id == "framework_default"),
        :intro_selectable         => boolean_value(raw_set["intro_selectable"], true),
        :intro_default            => boolean_value(raw_set["intro_default"], false),
        :intro_order              => raw_set["intro_order"].to_i,
        :startup_mode             => blank?(raw_set["startup_mode"]) ? "species_override" : raw_set["startup_mode"].to_s,
        :species                  => species,
        :rival_counterpick        => rival_counterpick
      }
    end
  end

  def self.normalize_species_payload!(species_array)
    species_array.each do |raw_species|
      next if !raw_species.is_a?(Hash)
      definition = normalize_species_definition(raw_species)
      next if definition.nil?
      @species_definitions << definition
    end
  end

  def self.normalize_species_definition(raw_species)
    internal_id = symbolize(raw_species["id"])
    return nil if internal_id.nil?
    resolved_slot = resolve_definition_slot(raw_species)
    if resolved_slot.nil?
      @errors << "#{internal_id} must define a positive framework slot or a legacy framework id_number."
      return nil
    end
    if resolved_slot > FRAMEWORK_CONTENT_SLOTS
      @errors << "#{internal_id} requested framework slot #{resolved_slot}, but only 1..#{FRAMEWORK_CONTENT_SLOTS} were reserved at startup."
      return nil
    end

    game_data = {
      :id                => internal_id,
      :id_number         => framework_id_from_slot(resolved_slot),
      :name              => raw_species["name"].to_s,
      :category          => raw_species["category"].to_s,
      :pokedex_entry     => raw_species["pokedex_entry"].to_s,
      :type1             => symbolize(raw_species["type1"]) || :NORMAL,
      :type2             => symbolize(raw_species["type2"]),
      :base_stats        => normalize_stat_hash(raw_species["base_stats"], 1),
      :evs               => normalize_stat_hash(raw_species["evs"], 0),
      :base_exp          => raw_species["base_exp"].to_i,
      :growth_rate       => normalize_enum_symbol(raw_species["growth_rate"], :growth_rate) || :Medium,
      :gender_ratio      => normalize_enum_symbol(raw_species["gender_ratio"], :gender_ratio) || :Female50Percent,
      :catch_rate        => raw_species["catch_rate"].to_i,
      :happiness         => raw_species["happiness"].to_i,
      :moves             => normalize_level_up_moves(raw_species["moves"]),
      :tutor_moves       => normalize_symbol_list(raw_species["tutor_moves"]),
      :egg_moves         => normalize_symbol_list(raw_species["egg_moves"]),
      :abilities         => normalize_symbol_list(raw_species["abilities"]),
      :hidden_abilities  => normalize_symbol_list(raw_species["hidden_abilities"]),
      :egg_groups        => normalize_symbol_list(raw_species["egg_groups"]),
      :hatch_steps       => raw_species["hatch_steps"].to_i,
      :evolutions        => normalize_evolutions(raw_species["evolutions"]),
      :height            => raw_species["height"].to_i,
      :weight            => raw_species["weight"].to_i,
      :color             => normalize_enum_symbol(raw_species["color"], :body_color) || :Red,
      :shape             => normalize_enum_symbol(raw_species["shape"], :body_shape) || :Head,
      :habitat           => normalize_enum_symbol(raw_species["habitat"], :habitat) || :None,
      :generation        => raw_species["generation"].to_i
    }
    game_data[:type2] = game_data[:type1] if game_data[:type2].nil?
    world_data = raw_species["world_data"].is_a?(Hash) ? raw_species["world_data"] : {}
    fusion_meta = raw_species["fusion_meta"].is_a?(Hash) ? raw_species["fusion_meta"] : {}
    export_meta = raw_species["export_meta"].is_a?(Hash) ? raw_species["export_meta"] : {}
    integration = raw_species["integration"].is_a?(Hash) ? raw_species["integration"] : {}

    metadata = {
      :kind                      => symbolize(raw_species["kind"]) || :fakemon,
      :framework_slot            => resolved_slot,
      :base_species              => symbolize(raw_species["base_species"]),
      :variant_scope             => raw_species["variant_scope"].to_s,
      :variant_family            => raw_species["variant_family"],
      :starter_eligible          => boolean_value(raw_species["starter_eligible"], false),
      :encounter_eligible        => boolean_value(raw_species["encounter_eligible"], false),
      :trainer_eligible          => boolean_value(raw_species["trainer_eligible"], false),
      :dex_visible               => raw_species.has_key?("dex_visible") ? boolean_value(raw_species["dex_visible"], false) : nil,
      :fusion_rule               => normalize_fusion_rule(raw_species["fusion_rule"]),
      :standard_fusion_compatible => boolean_value(raw_species["standard_fusion_compatible"], false),
      :fallback_species          => symbolize(raw_species["fallback_species"]),
      :assets                    => normalize_assets(raw_species["assets"]),
      :tm_moves                  => normalize_symbol_list(raw_species["tm_moves"]),
      :encounter_rarity          => (world_data["encounter_rarity"] || raw_species["encounter_rarity"]).to_s,
      :encounter_zones           => normalize_string_list(world_data["encounter_zones"] || raw_species["encounter_zones"]),
      :trainer_roles             => normalize_string_list(world_data["trainer_roles"] || raw_species["trainer_roles"]),
      :trainer_notes             => (world_data["trainer_notes"] || raw_species["trainer_notes"]).to_s,
      :encounter_level_min       => (world_data["encounter_level_min"] || raw_species["encounter_level_min"]).to_i,
      :encounter_level_max       => (world_data["encounter_level_max"] || raw_species["encounter_level_max"]).to_i,
      :head_offset_x             => (fusion_meta["head_offset_x"] || raw_species["head_offset_x"]).to_i,
      :head_offset_y             => (fusion_meta["head_offset_y"] || raw_species["head_offset_y"]).to_i,
      :body_offset_x             => (fusion_meta["body_offset_x"] || raw_species["body_offset_x"]).to_i,
      :body_offset_y             => (fusion_meta["body_offset_y"] || raw_species["body_offset_y"]).to_i,
      :fusion_naming_notes       => (fusion_meta["naming_notes"] || raw_species["fusion_naming_notes"]).to_s,
      :fusion_sprite_hints       => (fusion_meta["sprite_hints"] || raw_species["fusion_sprite_hints"]).to_s,
      :export_author             => (export_meta["author"] || raw_species["export_author"]).to_s,
      :export_version            => (export_meta["version"] || raw_species["export_version"]).to_s,
      :export_pack_name          => (export_meta["pack_name"] || raw_species["export_pack_name"]).to_s,
      :export_tags               => normalize_string_list(export_meta["tags"] || raw_species["export_tags"]),
      :source_pack               => raw_species["source_pack"].to_s,
      :source_url                => raw_species["source_url"].to_s,
      :creator                   => raw_species["creator"].to_s,
      :credit_text               => raw_species["credit_text"].to_s,
      :usage_permission          => raw_species["usage_permission"].to_s,
      :auto_import_allowed       => boolean_value(raw_species["auto_import_allowed"], false),
      :manual_review_required    => boolean_value(raw_species["manual_review_required"], false),
      :framework_species_key     => integration["framework_species_key"].to_s,
      :import_insert_status      => integration["insert_status"].to_s,
      :import_insert_errors      => normalize_string_list(integration["insert_errors"]),
      :compatibility_aliases     => normalize_symbol_list(integration["compatibility_aliases"] || raw_species["compatibility_aliases"]),
      :legacy_foreign_numbers    => normalize_integer_list(integration["legacy_foreign_numbers"] || raw_species["legacy_foreign_numbers"]),
      :source_section            => integration["source_section"].to_s,
      :form_names                => normalize_string_list(integration["form_names"] || raw_species["form_names"]),
      :regional_numbers          => normalize_integer_list(integration["regional_numbers"] || raw_species["regional_numbers"]),
      :import_notes              => raw_species["notes"].to_s,
      :design_notes              => raw_species["design_notes"].to_s,
      :template_source_label     => raw_species["template_source_label"].to_s
    }
    if metadata[:fallback_species].nil? && metadata[:kind] == :regional_variant
      metadata[:fallback_species] = metadata[:base_species]
    end

    return {
      :game_data => game_data,
      :metadata  => metadata
    }
  end

  def self.resolve_definition_slot(raw_species)
    return nil if !raw_species.is_a?(Hash)
    raw_slot = raw_species["slot"]
    slot_number = raw_slot.to_i
    return slot_number if slot_number > 0

    raw_id_number = raw_species["id_number"]
    return nil if raw_id_number.nil?
    return framework_slot_from_configured_id_number(raw_id_number)
  end

  def self.normalize_enum_symbol(value, enum_key = nil)
    symbol = symbolize(value)
    return nil if symbol.nil?
    alias_map = ENUM_SYMBOL_ALIASES[enum_key] || {}
    return alias_map[symbol] if alias_map[symbol]

    normalized = symbol.to_s.gsub(/[^A-Za-z0-9]/, "").downcase
    alias_map.each_pair do |alias_id, target_id|
      next if alias_id.nil?
      alias_normalized = alias_id.to_s.gsub(/[^A-Za-z0-9]/, "").downcase
      return target_id if alias_normalized == normalized
    end
    return symbol
  end

  def self.normalize_symbol_list(values)
    ret = []
    iterable_values = if values.is_a?(Array)
      values
    elsif values.nil?
      []
    else
      [values]
    end
    iterable_values.each do |entry|
      symbol = symbolize(entry)
      ret << symbol if symbol
    end
    return ret
  end

  def self.normalize_string_list(values)
    ret = []
    if values.is_a?(Array)
      values.each do |entry|
        next if blank?(entry)
        ret << entry.to_s
      end
      return ret
    end
    return ret if blank?(values)
    values.to_s.split(/[\r\n,;]+/).each do |entry|
      next if blank?(entry)
      ret << entry.to_s.strip
    end
    return ret
  end

  def self.normalize_integer_list(values)
    ret = []
    iterable_values = if values.is_a?(Array)
      values
    elsif values.nil?
      []
    else
      [values]
    end
    iterable_values.each do |entry|
      next if blank?(entry)
      value = entry.to_i
      ret << value if value > 0
    end
    return ret.uniq
  end

  def self.normalize_stat_hash(raw_stats, fallback_value)
    ret = {}
    STAT_KEY_MAP.each_pair do |_raw_key, stat_symbol|
      ret[stat_symbol] = fallback_value
    end
    return ret if !raw_stats.is_a?(Hash)
    raw_stats.each_pair do |raw_key, value|
      stat_symbol = STAT_KEY_MAP[raw_key.to_s.upcase]
      next if stat_symbol.nil?
      ret[stat_symbol] = value.to_i
    end
    return ret
  end

  def self.normalize_level_up_moves(raw_moves)
    ret = []
    iterable_moves = raw_moves.is_a?(Array) ? raw_moves : []
    iterable_moves.each do |entry|
      next if !entry.is_a?(Hash)
      move_symbol = symbolize(entry["move"])
      next if move_symbol.nil?
      ret << [entry["level"].to_i, move_symbol]
    end
    ret.sort_by! { |level_entry| [level_entry[0], level_entry[1].to_s] }
    return ret
  end

  def self.normalize_evolutions(raw_evolutions)
    ret = []
    iterable_evolutions = raw_evolutions.is_a?(Array) ? raw_evolutions : []
    iterable_evolutions.each do |entry|
      next if !entry.is_a?(Hash)
      evolved_species = symbolize(entry["species"])
      method_symbol   = symbolize(entry["method"])
      parameter       = normalize_evolution_parameter(entry["parameter"])
      next if evolved_species.nil? || method_symbol.nil?
      ret << [evolved_species, method_symbol, parameter]
    end
    return ret
  end

  def self.normalize_evolution_parameter(value)
    return nil if value.nil?
    return value if value.is_a?(Numeric) || value == true || value == false
    if value.is_a?(String)
      stripped = value.strip
      return nil if stripped.empty?
      return stripped.to_i if stripped.match?(/\A-?\d+\z/)
      return symbolize(stripped) if stripped.match?(/\A[A-Za-z0-9_]+\z/)
      return stripped
    end
    return value
  end

  def self.normalize_assets(raw_assets)
    ret = {}
    return ret if !raw_assets.is_a?(Hash)
    %w[front back icon cry overworld shiny_front shiny_back shiny_icon].each do |asset_key|
      next if blank?(raw_assets[asset_key])
      ret[asset_key.to_sym] = raw_assets[asset_key].to_s
    end
    return ret
  end

  def self.normalize_fusion_rule(raw_value)
    case raw_value.to_s.strip.downcase
    when "standard", "fusible"
      return :standard
    when "restricted"
      return :restricted
    else
      return :blocked
    end
  end

  def self.normalize_encounter_hooks(raw_hooks)
    ret = []
    (raw_hooks || []).each do |entry|
      next if !entry.is_a?(Hash)
      ret << {
        :enabled        => boolean_value(entry["enabled"], false),
        :map_id         => entry["map_id"].to_i,
        :encounter_type => symbolize(entry["encounter_type"]),
        :species        => symbolize(entry["species"]),
        :weight         => [entry["weight"].to_i, 1].max,
        :min_level      => [entry["min_level"].to_i, 1].max,
        :max_level      => [entry["max_level"].to_i, 1].max
      }
    end
    return ret
  end

  def self.normalize_trainer_hooks(raw_hooks)
    ret = []
    (raw_hooks || []).each do |entry|
      next if !entry.is_a?(Hash)
      ret << {
        :enabled      => boolean_value(entry["enabled"], false),
        :trainer_type => symbolize(entry["trainer_type"]),
        :trainer_name => entry["trainer_name"].to_s,
        :slot         => entry["slot"].to_i,
        :species      => symbolize(entry["species"]),
        :level        => entry["level"],
        :moves        => normalize_symbol_list(entry["moves"]),
        :item         => symbolize(entry["item"]),
        :ability      => symbolize(entry["ability"]),
        :gender       => entry["gender"],
        :nature       => symbolize(entry["nature"]),
        :shiny        => boolean_value(entry["shiny"], false),
        :nickname     => entry["nickname"].to_s
      }
    end
    return ret
  end

  def self.placeholder_species_definition
    return {
      :game_data => {
        :id               => MISSING_SPECIES_ID,
        :id_number        => MISSING_SPECIES_NUM,
        :name             => "Unresolved Species",
        :category         => "Framework Fallback",
        :pokedex_entry    => "This placeholder appears when a save still references custom species data that is no longer installed.",
        :type1            => :NORMAL,
        :type2            => :NORMAL,
        :base_stats       => {
          :HP              => 50,
          :ATTACK          => 50,
          :DEFENSE         => 50,
          :SPECIAL_ATTACK  => 50,
          :SPECIAL_DEFENSE => 50,
          :SPEED           => 50
        },
        :evs              => {
          :HP              => 0,
          :ATTACK          => 0,
          :DEFENSE         => 0,
          :SPECIAL_ATTACK  => 0,
          :SPECIAL_DEFENSE => 0,
          :SPEED           => 0
        },
        :base_exp         => 60,
        :growth_rate      => :Medium,
        :gender_ratio     => :Genderless,
        :catch_rate       => 3,
        :happiness        => 70,
        :moves            => [[1, :TACKLE]],
        :abilities        => [:PRESSURE],
        :hidden_abilities => [],
        :egg_groups       => [:Undiscovered],
        :hatch_steps      => 1,
        :evolutions       => [],
        :height           => 10,
        :weight           => 10,
        :color            => :Gray,
        :shape            => :Head,
        :habitat          => :None,
        :generation       => 0
      },
      :metadata => {
        :kind                       => :framework_placeholder,
        :starter_eligible           => false,
        :encounter_eligible         => false,
        :trainer_eligible           => false,
        :fusion_rule                => :blocked,
        :standard_fusion_compatible => false,
        :fallback_species           => :PIKACHU,
        :assets                     => {}
      }
    }
  end

  def self.register_framework_species!
    placeholder = placeholder_species_definition
    register_definition!(placeholder) if !GameData::Species::DATA.has_key?(MISSING_SPECIES_ID)

    ordered_definitions = @species_definitions.sort_by { |definition| definition[:game_data][:id_number] }
    ordered_definitions.each do |definition|
      register_definition!(definition)
    end
  end

  def self.register_definition!(definition)
    game_data = definition[:game_data]
    metadata  = definition[:metadata]
    GameData::Species.register(game_data)
    @metadata_by_symbol[game_data[:id]] = metadata
    @metadata_by_id_number[game_data[:id_number]] = metadata
    register_pb_species_constant(game_data[:id])
    register_species_aliases!(game_data[:id], metadata)
    clear_species_data_lookup_cache! if respond_to?(:clear_species_data_lookup_cache!)
  end

  def self.register_species_aliases!(canonical_id, metadata)
    return if canonical_id.nil? || !metadata.is_a?(Hash)
    Array(metadata[:compatibility_aliases]).each do |alias_id|
      next if alias_id.nil? || alias_id == canonical_id
      compatibility_alias_map[alias_id] = canonical_id
      compatibility_alias_context_map[alias_id] ||= []
      compatibility_alias_context_map[alias_id] << {
        :canonical_id    => canonical_id,
        :source_pack     => metadata[:source_pack],
        :source_section  => metadata[:source_section],
        :framework_slot  => metadata[:framework_slot]
      }
      register_pb_species_constant(alias_id, canonical_id)
    end
    Array(metadata[:legacy_foreign_numbers]).each do |foreign_number|
      next if foreign_number.nil?
      value = foreign_number.to_i
      next if value <= 0
      compatibility_number_alias_map[value] ||= canonical_id
      compatibility_number_alias_context_map[value] ||= []
      compatibility_number_alias_context_map[value] << {
        :canonical_id    => canonical_id,
        :source_pack     => metadata[:source_pack],
        :source_section  => metadata[:source_section],
        :framework_slot  => metadata[:framework_slot]
      }
    end
  end

  def self.register_pb_species_constant(internal_id, target_id = nil)
    return if !defined?(PBSpecies)
    return if PBSpecies.const_defined?(internal_id, false)
    PBSpecies.const_set(internal_id, target_id || internal_id)
  rescue
  end
end
