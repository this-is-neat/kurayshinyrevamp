module TravelExpansionFramework
  module_function

  DEFAULT_LEGACY_ENCOUNTER_TYPE_MAP = {
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
    12 => :BugContest,
    13 => :Land
  }.freeze if !const_defined?(:DEFAULT_LEGACY_ENCOUNTER_TYPE_MAP)

  REBORN_LEGACY_ENCOUNTER_TYPE_MAP = {
    0  => :Land,
    1  => :Cave,
    2  => :Water,
    3  => :RockSmash,
    4  => :OldRod,
    5  => :GoodRod,
    6  => :SuperRod,
    7  => :HeadbuttLow,
    8  => :LandMorning,
    9  => :LandDay,
    10 => :LandNight,
    11 => :BugContest
  }.freeze if !const_defined?(:REBORN_LEGACY_ENCOUNTER_TYPE_MAP)

  DEFAULT_LEGACY_ENCOUNTER_SLOT_CHANCES = {
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
    12 => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1],
    13 => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  }.freeze if !const_defined?(:DEFAULT_LEGACY_ENCOUNTER_SLOT_CHANCES)

  REBORN_LEGACY_ENCOUNTER_SLOT_CHANCES = {
    0  => [20, 15, 12, 10, 10, 10, 5, 5, 5, 4, 2, 2],
    1  => [20, 15, 12, 10, 10, 10, 5, 5, 5, 4, 2, 2],
    2  => [50, 25, 15, 7, 3],
    3  => [50, 25, 15, 7, 3],
    4  => [70, 30],
    5  => [60, 20, 20],
    6  => [40, 35, 15, 7, 3],
    7  => [30, 25, 20, 10, 5, 5, 4, 1],
    8  => [20, 15, 12, 10, 10, 10, 5, 5, 5, 4, 2, 2],
    9  => [20, 15, 12, 10, 10, 10, 5, 5, 5, 4, 2, 2],
    10 => [20, 15, 12, 10, 10, 10, 5, 5, 5, 4, 2, 2],
    11 => [20, 15, 12, 10, 10, 10, 5, 5, 5, 4, 2, 2]
  }.freeze if !const_defined?(:REBORN_LEGACY_ENCOUNTER_SLOT_CHANCES)

  EXPANSION_ENCOUNTER_GRASS_TAGS = [2, 10, 14, 24, 25, 26].freeze if !const_defined?(:EXPANSION_ENCOUNTER_GRASS_TAGS)
  EXPANSION_ENCOUNTER_GRASS_NAME_PATTERN = /(tall\s*grass|tallgrass|deadgrass|wild\s*grass|encounter\s*grass|grass\s*encounter|bush|flower|meadow|foliage|shrub|coppice)/i.freeze if !const_defined?(:EXPANSION_ENCOUNTER_GRASS_NAME_PATTERN)

  def expansion_encounter_profile(expansion_id)
    case expansion_id.to_s
    when "reborn"
      return {
        :type_map     => REBORN_LEGACY_ENCOUNTER_TYPE_MAP,
        :slot_chances => REBORN_LEGACY_ENCOUNTER_SLOT_CHANCES
      }
    else
      return {
        :type_map     => DEFAULT_LEGACY_ENCOUNTER_TYPE_MAP,
        :slot_chances => DEFAULT_LEGACY_ENCOUNTER_SLOT_CHANCES
      }
    end
  end

  def expansion_encounter_data_roots(expansion_id)
    manifest = manifest_for(expansion_id)
    project_info = external_projects[expansion_id.to_s] if respond_to?(:external_projects)
    roots = []
    if project_info.is_a?(Hash)
      roots << project_info[:data_root]
      roots << File.join(project_info[:root].to_s, "Data") if !project_info[:root].to_s.empty?
    end
    if manifest.is_a?(Hash)
      roots << manifest[:external_data_root]
      map_source = manifest[:map_source] || manifest["map_source"]
      if map_source.is_a?(Hash)
        template = map_source[:path_template] || map_source["path_template"]
        if template.to_s =~ /\A(.+?)(?:Map%03d\.rxdata|Map%03d|%03d\.rxdata|%03d)\z/i
          roots << $1
        end
      end
      source_root = manifest[:source_root] || manifest["source_root"]
      roots << File.join(source_root.to_s, "Data") if !source_root.to_s.empty?
    end
    return roots.compact.map { |root| root.to_s.gsub("\\", "/").sub(%r{/+\z}, "") }.reject { |root| root.empty? }.uniq
  rescue
    return []
  end

  def expansion_encounter_candidate_paths(expansion_id)
    paths = []
    expansion_encounter_data_roots(expansion_id).each do |root|
      paths << runtime_path_join(root, "encounters.dat")
      paths << runtime_path_join(root, "Encounters.rxdata")
      paths << runtime_path_join(root, "encounters.rxdata")
    end
    manifest = manifest_for(expansion_id)
    source_root = manifest[:source_root] || manifest["source_root"] if manifest.is_a?(Hash)
    if !source_root.to_s.empty?
      paths << File.join(source_root.to_s, "PBS", "encounters.txt")
      paths << File.join(source_root.to_s, "Backups", "encounters.txt")
    end
    return paths.compact.map { |path| path.to_s.gsub("\\", "/") }.reject { |path| path.empty? }.uniq
  rescue
    return []
  end

  def expansion_native_data_modules(expansion_id)
    expansion = expansion_id.to_s
    candidates = []
    camel = expansion.split(/[^A-Za-z0-9]+/).map { |part| part.capitalize }.join
    candidates << "#{camel}Data" if !camel.empty?
    candidates << camel if !camel.empty?
    candidates << "VaudelleRegionData" if expansion == "vaudelle_region"
    modules = []
    candidates.uniq.each do |name|
      begin
        modules << Object.const_get(name) if Object.const_defined?(name)
      rescue
      end
    end
    return modules
  rescue
    return []
  end

  def expansion_native_encounter_data(expansion_id)
    expansion_native_data_modules(expansion_id).each do |data_module|
      begin
        if data_module.respond_to?(:encounters)
          data = data_module.encounters
          return data if data && (!data.respond_to?(:empty?) || !data.empty?)
        end
        if data_module.const_defined?(:ENCOUNTERS)
          data = data_module.const_get(:ENCOUNTERS)
          return data if data && (!data.respond_to?(:empty?) || !data.empty?)
        end
      rescue
      end
    end
    return nil
  rescue
    return nil
  end

  def expansion_load_encounter_file(path)
    candidate = path.to_s
    return nil if candidate.empty?
    if candidate[/\.txt\z/i]
      return expansion_parse_encounters_txt(candidate)
    end
    if absolute_path?(candidate) && File.file?(candidate)
      File.open(candidate, "rb") { |file| return Marshal.load(file) }
    end
    return load_marshaled_runtime(candidate) if respond_to?(:load_marshaled_runtime)
    return nil
  rescue => e
    log("Expansion encounter load failed for #{candidate}: #{e.class}: #{e.message}")
    return nil
  end

  def expansion_parse_encounters_txt(path)
    return nil if !File.file?(path)
    data = {}
    current_map = nil
    current_type = nil
    type_name_to_index = {}
    DEFAULT_LEGACY_ENCOUNTER_TYPE_MAP.each_pair { |index, type| type_name_to_index[type.to_s.upcase] = index }
    REBORN_LEGACY_ENCOUNTER_TYPE_MAP.each_pair { |index, type| type_name_to_index[type.to_s.upcase] = index }
    File.foreach(path) do |line|
      text = line.to_s.strip
      next if text.empty? || text.start_with?("#")
      if text =~ /\A\[(\d+)\]\z/
        current_map = integer($1, 0)
        current_type = nil
        data[current_map] ||= [[0] * 14, []]
        next
      end
      next if current_map.nil?
      parts = text.split(",").map { |part| part.strip }
      type_index = type_name_to_index[parts[0].to_s.upcase]
      if type_index
        current_type = type_index
        density = integer(parts[1], 0)
        data[current_map][0][type_index] = density if density > 0
        data[current_map][1][type_index] ||= []
        next
      end
      next if current_type.nil? || parts.length < 3
      species = parts[0].to_s
      min_level = integer(parts[1], 1)
      max_level = integer(parts[2], min_level)
      data[current_map][1][current_type] ||= []
      data[current_map][1][current_type] << [species, min_level, max_level]
    end
    return data
  rescue => e
    log("Expansion encounters.txt parse failed for #{path}: #{e.class}: #{e.message}")
    return nil
  end

  def expansion_encounter_data(expansion_id)
    expansion = expansion_id.to_s
    @expansion_encounter_data ||= {}
    return @expansion_encounter_data[expansion] if @expansion_encounter_data.has_key?(expansion)
    native_data = expansion_native_encounter_data(expansion)
    if native_data && (!native_data.respond_to?(:empty?) || !native_data.empty?)
      @expansion_encounter_data[expansion] = native_data
      log("[#{expansion}] loaded native expansion encounter table")
      return native_data
    end
    expansion_encounter_candidate_paths(expansion).each do |path|
      data = expansion_load_encounter_file(path)
      next if data.nil?
      next if data.respond_to?(:empty?) && data.empty?
      @expansion_encounter_data[expansion] = data
      log("[#{expansion}] loaded expansion encounters from #{path}")
      return data
    end
    @expansion_encounter_data[expansion] = {}
    log_runtime_asset_once(expansion, :encounters_missing, "Data/encounters.dat", "No expansion encounter data found") if respond_to?(:log_runtime_asset_once)
    return @expansion_encounter_data[expansion]
  rescue => e
    log("[#{expansion}] expansion encounter data failed: #{e.class}: #{e.message}")
    @expansion_encounter_data[expansion] = {}
    return @expansion_encounter_data[expansion]
  end

  def expansion_raw_encounter_entry(expansion_id, map_id)
    data = expansion_encounter_data(expansion_id)
    return nil if data.nil? || (data.respond_to?(:empty?) && data.empty?)
    local_id = local_map_id_for(expansion_id, map_id)
    virtual_id = integer(map_id, 0)
    version = integer(($PokemonGlobal.encounter_version rescue 0), 0)
    if data.respond_to?(:get)
      entry = data.get(local_id, version) rescue nil
      entry ||= data.get(local_id, 0) rescue nil
      return entry if entry
    end
    if data.is_a?(Hash)
      keys = [
        local_id,
        local_id.to_s,
        "#{local_id}_#{version}".to_sym,
        "#{local_id}_0".to_sym,
        "#{local_id}_#{version}",
        "#{local_id}_0",
        virtual_id,
        virtual_id.to_s,
        "#{virtual_id}_#{version}".to_sym,
        "#{virtual_id}_0".to_sym,
        "#{virtual_id}_#{version}",
        "#{virtual_id}_0"
      ]
      keys.each { |key| return data[key] if data.has_key?(key) }
      data.each_value do |value|
        return value if value.respond_to?(:map) && integer(value.map, 0) == local_id
      end
    end
    return nil
  rescue
    return nil
  end

  def expansion_encounter_type_valid?(encounter_type)
    return false if encounter_type.nil?
    return true if defined?(GameData::EncounterType) && GameData::EncounterType.exists?(encounter_type)
    return false
  rescue
    return false
  end

  def expansion_encounter_type_family(encounter_type)
    data = GameData::EncounterType.try_get(encounter_type) rescue nil
    type = data.respond_to?(:type) ? data.type : nil
    return :land if type == :land || type == :contest
    return :cave if type == :cave
    return :water if type == :water
    return :fishing if type == :fishing
    return nil
  rescue
    return nil
  end

  def expansion_first_valid_encounter_type(*types)
    types.each { |type| return type if expansion_encounter_type_valid?(type) }
    return nil
  end

  def expansion_encounter_type_alias(encounter_type)
    key = encounter_type.to_s.downcase.gsub(/[^a-z0-9]+/, "")
    return nil if key.empty?
    return expansion_first_valid_encounter_type(:RockSmash) if key.include?("rocksmash")
    return expansion_first_valid_encounter_type(:HeadbuttHigh, :HeadbuttLow) if key.include?("headbutt")
    return expansion_first_valid_encounter_type(:SuperRod) if key.include?("superrod")
    return expansion_first_valid_encounter_type(:GoodRod) if key.include?("goodrod")
    return expansion_first_valid_encounter_type(:OldRod) if key.include?("oldrod")
    return expansion_first_valid_encounter_type(:Water) if key =~ /(water|surf|sea|ocean|pond|lake|river|stream)/
    return expansion_first_valid_encounter_type(:Cave) if key =~ /(cave|cavern|dungeon|mine|ruin|ruins|underground)/
    if key =~ /(land|grass|field|forest|woods|bush|flower|meadow|foliage|shrub|sand|desert|beach|shore|dune|snow|storm|fog|sun|sunny|rain|ash|marsh|swamp|wild)/
      return expansion_first_valid_encounter_type(:Land)
    end
    return nil
  rescue
    return nil
  end

  def expansion_compatible_encounter_types(encounter_type, present_families = {})
    targets = []
    valid_original = expansion_encounter_type_valid?(encounter_type)
    targets << encounter_type if valid_original
    alias_type = expansion_encounter_type_alias(encounter_type)
    if alias_type && alias_type != encounter_type
      alias_family = expansion_encounter_type_family(alias_type)
      targets << alias_type if !valid_original || !present_families[alias_family]
    end
    return targets.uniq
  rescue
    return []
  end

  def expansion_default_step_chance(encounter_type)
    data = GameData::EncounterType.try_get(encounter_type) rescue nil
    value = data.respond_to?(:trigger_chance) ? integer(data.trigger_chance, 0) : 0
    return value if value > 0
    case data && data.respond_to?(:type) ? data.type : nil
    when :land
      return 10
    when :cave
      return 5
    when :water
      return 2
    end
    return 0
  rescue
    return 0
  end

  def expansion_raw_step_chance(raw_steps, encounter_type)
    return 0 if !raw_steps
    candidates = [encounter_type, encounter_type.to_s]
    candidates << encounter_type.to_sym if encounter_type.respond_to?(:to_sym)
    candidates.compact.uniq.each do |key|
      value = raw_steps[key] rescue nil
      chance = integer(value, 0)
      return chance if chance > 0
    end
    if raw_steps.respond_to?(:each_pair)
      raw_steps.each_pair do |key, value|
        next if key.to_s != encounter_type.to_s
        chance = integer(value, 0)
        return chance if chance > 0
      end
    end
    return 0
  rescue
    return 0
  end

  def expansion_density_for_legacy_type(densities, old_type, encounter_type)
    density = integer(densities[old_type], 0)
    return density if density > 0
    type_data = GameData::EncounterType.try_get(encounter_type) rescue nil
    case type_data && type_data.respond_to?(:type) ? type_data.type : nil
    when :land, :contest
      density = integer(densities[0], 0)
    when :cave
      density = integer(densities[1], 0)
    when :water
      density = integer(densities[2], 0)
    end
    density = expansion_default_step_chance(encounter_type) if density <= 0
    return density
  rescue
    return 0
  end

  def resolve_expansion_encounter_species(expansion_id, species)
    if expansion_id.to_s == "pokemon_uranium" && respond_to?(:uranium_resolve_species)
      resolved = uranium_resolve_species(species)
      return resolved if resolved && (GameData::Species.try_get(resolved) rescue nil)
    end
    if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:compatibility_alias_target)
      aliased = CustomSpeciesFramework.compatibility_alias_target(species) rescue nil
      if aliased
        data = GameData::Species.try_get(aliased) rescue nil
        return data.species if data
      end
    end
    if species.is_a?(String) || species.is_a?(Symbol)
      resolved = resolve_pb_species_constant_name(species) if respond_to?(:resolve_pb_species_constant_name)
      data = GameData::Species.try_get(resolved) rescue nil
      return data.species if data
      data = GameData::Species.try_get(species.to_sym) rescue nil
      return data.species if data
    else
      data = GameData::Species.try_get(species) rescue nil
      return data.species if data
    end
    return nil
  rescue
    return nil
  end

  def expansion_convert_legacy_encounter_table(expansion_id, raw_entry)
    return nil if !raw_entry.is_a?(Array) || raw_entry.length < 2
    densities = raw_entry[0].is_a?(Array) ? raw_entry[0] : []
    tables = raw_entry[1].is_a?(Array) ? raw_entry[1] : []
    profile = expansion_encounter_profile(expansion_id)
    type_map = profile[:type_map]
    slot_chances = profile[:slot_chances]
    step_chances = {}
    encounter_tables = {}
    local_map_id = local_map_id_for(expansion_id, ($game_map.map_id rescue 0))
    tables.each_with_index do |entries, old_type|
      next if !entries.is_a?(Array) || entries.empty?
      encounter_type = type_map[old_type]
      next if !expansion_encounter_type_valid?(encounter_type)
      converted = []
      chances = slot_chances[old_type] || DEFAULT_LEGACY_ENCOUNTER_SLOT_CHANCES[old_type] || []
      entries.each_with_index do |entry, index|
        next if !entry.is_a?(Array) || entry.length < 3
        species = resolve_expansion_encounter_species(expansion_id, entry[0])
        if species.nil?
          log("[#{expansion_id}] skipped unresolved encounter species #{entry[0].inspect} on local map #{local_map_id} type #{encounter_type}")
          next
        end
        min_level = [integer(entry[1], 1), 1].max
        max_level = [integer(entry[2], min_level), min_level].max
        weight = [integer(chances[index], 1), 1].max
        converted << [weight, species, min_level, max_level]
      end
      next if converted.empty?
      density = expansion_density_for_legacy_type(densities, old_type, encounter_type)
      step_chances[encounter_type] = density if density > 0
      encounter_tables[encounter_type] = converted
    end
    return nil if encounter_tables.empty?
    return {
      :step_chances     => step_chances,
      :encounter_tables => encounter_tables
    }
  end

  def expansion_convert_modern_encounter_table(expansion_id, raw_entry)
    step_chances = {}
    encounter_tables = {}
    raw_steps = raw_entry.respond_to?(:step_chances) ? raw_entry.step_chances : nil
    raw_types = raw_entry.respond_to?(:types) ? raw_entry.types : nil
    return nil if !raw_types.respond_to?(:each)
    present_families = {}
    raw_type_pairs = []
    if raw_types.respond_to?(:each_pair)
      raw_types.each_pair { |encounter_type, entries| raw_type_pairs << [encounter_type, entries] }
    else
      raw_types.each { |pair| raw_type_pairs << [pair[0], pair[1]] if pair.respond_to?(:[]) }
    end
    raw_type_pairs.each do |encounter_type, _entries|
      family = expansion_encounter_type_family(encounter_type)
      present_families[family] = true if family
    end
    raw_type_pairs.each do |encounter_type, entries|
      compatible_types = expansion_compatible_encounter_types(encounter_type, present_families)
      next if compatible_types.empty?
      next if !entries.is_a?(Array) || entries.empty?
      converted = []
      entries.each do |entry|
        next if !entry.is_a?(Array) || entry.length < 4
        species = resolve_expansion_encounter_species(expansion_id, entry[1])
        next if species.nil?
        weight = [integer(entry[0], 1), 1].max
        min_level = [integer(entry[2], 1), 1].max
        max_level = [integer(entry[3], min_level), min_level].max
        converted << [weight, species, min_level, max_level]
      end
      next if converted.empty?
      compatible_types.each do |compatible_type|
        source_step = expansion_raw_step_chance(raw_steps, encounter_type)
        source_step = expansion_default_step_chance(compatible_type) if source_step <= 0
        step_chances[compatible_type] = [integer(step_chances[compatible_type], 0), source_step].max if source_step > 0
        encounter_tables[compatible_type] ||= []
        encounter_tables[compatible_type].concat(converted)
      end
    end
    return nil if encounter_tables.empty?
    return {
      :step_chances     => step_chances,
      :encounter_tables => encounter_tables
    }
  end

  def expansion_build_encounter_table(map_id)
    expansion_id = current_map_expansion_id(map_id)
    return nil if expansion_id.to_s.empty?
    raw_entry = expansion_raw_encounter_entry(expansion_id, map_id)
    if raw_entry.nil?
      local_id = local_map_id_for(expansion_id, map_id)
      log_runtime_asset_once(expansion_id, :encounter_map_missing, "map #{local_id}", "No encounter entry for this expansion map") if respond_to?(:log_runtime_asset_once)
    end
    return nil if raw_entry.nil?
    converted = expansion_convert_modern_encounter_table(expansion_id, raw_entry)
    converted ||= expansion_convert_legacy_encounter_table(expansion_id, raw_entry)
    return converted
  rescue => e
    log("[#{expansion_id}] expansion encounter conversion failed for map #{map_id}: #{e.class}: #{e.message}")
    return nil
  end

  def apply_expansion_encounter_table!(pokemon_encounters, map_id)
    expansion_id = current_map_expansion_id(map_id)
    return false if expansion_id.to_s.empty?
    converted = expansion_build_encounter_table(map_id)
    if !converted
      clear_expansion_encounter_table!(pokemon_encounters, map_id)
      return false
    end
    pokemon_encounters.instance_variable_set(:@step_count, 0) if !pokemon_encounters.instance_variable_defined?(:@step_count)
    pokemon_encounters.instance_variable_set(:@chance_accumulator, 0) if !pokemon_encounters.instance_variable_defined?(:@chance_accumulator)
    step_chances = pokemon_encounters.instance_variable_get(:@step_chances)
    encounter_tables = pokemon_encounters.instance_variable_get(:@encounter_tables)
    step_chances = {} if !step_chances.is_a?(Hash)
    encounter_tables = {} if !encounter_tables.is_a?(Hash)
    converted[:step_chances].each_pair { |type, value| step_chances[type] = value }
    converted[:encounter_tables].each_pair { |type, entries| encounter_tables[type] = entries }
    pokemon_encounters.instance_variable_set(:@step_chances, step_chances)
    pokemon_encounters.instance_variable_set(:@encounter_tables, encounter_tables)
    local_id = local_map_id_for(expansion_id, map_id)
    log("[#{expansion_id}] loaded encounter bridge for local map #{local_id} (#{converted[:encounter_tables].keys.join(', ')})")
    return true
  rescue => e
    log("[#{expansion_id}] encounter bridge failed for map #{map_id}: #{e.class}: #{e.message}")
    return false
  end

  def clear_expansion_encounter_table!(pokemon_encounters, map_id = nil)
    return false if !pokemon_encounters
    pokemon_encounters.instance_variable_set(:@step_count, 0)
    pokemon_encounters.instance_variable_set(:@chance_accumulator, 0)
    pokemon_encounters.instance_variable_set(:@step_chances, {})
    pokemon_encounters.instance_variable_set(:@encounter_tables, {})
    pokemon_encounters.instance_variable_set(:@tef_expansion_encounter_map_id, map_id) if map_id
    return true
  rescue => e
    expansion_id = current_map_expansion_id(map_id)
    log("[#{expansion_id}] encounter clear failed for map #{map_id}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def expansion_autotile_name_for_tile(game_map, tile_id)
    id = integer(tile_id, 0)
    return nil if id < 48 || id >= 384
    names = game_map.autotile_names rescue nil
    return nil if !names.respond_to?(:[])
    index = (id / 48) - 1
    return nil if index < 0
    name = names[index] rescue nil
    return name.to_s
  rescue
    return nil
  end

  def expansion_tile_has_bush_flag?(game_map, tile_id)
    passages = game_map.instance_variable_get(:@passages) rescue nil
    return false if !passages.respond_to?(:[])
    return (integer(passages[tile_id], 0) & 0x40) == 0x40
  rescue
    return false
  end

  def expansion_tile_name_suggests_land_encounter?(game_map, tile_id)
    name = expansion_autotile_name_for_tile(game_map, tile_id)
    return false if name.nil? || name.empty?
    return name =~ EXPANSION_ENCOUNTER_GRASS_NAME_PATTERN
  rescue
    return false
  end

  def expansion_land_encounter_tile?(game_map, x, y, terrain_tag = nil)
    return true if terrain_tag && terrain_tag.respond_to?(:land_wild_encounters) && terrain_tag.land_wild_encounters
    return false if !game_map || !game_map.respond_to?(:data)
    terrain_tags = game_map.instance_variable_get(:@terrain_tags) rescue nil
    data = game_map.data
    return false if !terrain_tags.respond_to?(:[])
    3.times do |layer|
      tile_id = data[x, y, layer] rescue nil
      next if tile_id.nil?
      raw_tag = integer(terrain_tags[tile_id], 0) rescue 0
      return true if EXPANSION_ENCOUNTER_GRASS_TAGS.include?(raw_tag)
      return true if expansion_tile_has_bush_flag?(game_map, tile_id)
      return true if expansion_tile_name_suggests_land_encounter?(game_map, tile_id)
    end
    return false
  rescue
    return false
  end
end

class PokemonEncounters
  alias tef_expansion_original_setup setup unless method_defined?(:tef_expansion_original_setup)
  alias tef_expansion_original_map_has_encounter_type? map_has_encounter_type? unless method_defined?(:tef_expansion_original_map_has_encounter_type?)
  alias tef_expansion_original_encounter_possible_here? encounter_possible_here? unless method_defined?(:tef_expansion_original_encounter_possible_here?)
  alias tef_expansion_original_encounter_type encounter_type unless method_defined?(:tef_expansion_original_encounter_type)

  def setup(map_ID)
    tef_expansion_original_setup(map_ID)
    @tef_expansion_encounter_map_id = nil
    if TravelExpansionFramework.current_map_expansion_id(map_ID)
      TravelExpansionFramework.apply_expansion_encounter_table!(self, map_ID)
      @tef_expansion_encounter_map_id = map_ID
    end
  end

  def tef_expansion_ensure_current_map_table!
    return if !$game_map
    map_id = $game_map.map_id
    return if @tef_expansion_encounter_map_id == map_id
    @tef_expansion_encounter_map_id = map_id
    return if !TravelExpansionFramework.current_map_expansion_id(map_id)
    TravelExpansionFramework.apply_expansion_encounter_table!(self, map_id)
  rescue
  end

  def map_has_encounter_type?(map_ID, enc_type)
    expansion_id = TravelExpansionFramework.current_map_expansion_id(map_ID)
    converted = TravelExpansionFramework.expansion_build_encounter_table(map_ID) if expansion_id
    if converted && converted[:encounter_tables].is_a?(Hash)
      entries = converted[:encounter_tables][enc_type]
      return entries.is_a?(Array) && !entries.empty?
    end
    return false if expansion_id
    return tef_expansion_original_map_has_encounter_type?(map_ID, enc_type)
  end

  def encounter_possible_here?
    tef_expansion_ensure_current_map_table!
    return true if tef_expansion_original_encounter_possible_here?
    return false if !TravelExpansionFramework.current_map_expansion_id
    return false if !$game_map || !$game_player
    terrain_tag = $game_map.terrain_tag($game_player.x, $game_player.y) rescue nil
    return false if terrain_tag && terrain_tag.respond_to?(:ice) && terrain_tag.ice
    return true if $PokemonGlobal && $PokemonGlobal.surfing && has_water_encounters?
    return true if has_cave_encounters?
    return true if has_land_encounters? && TravelExpansionFramework.expansion_land_encounter_tile?($game_map, $game_player.x, $game_player.y, terrain_tag)
    return false
  end

  def encounter_type
    tef_expansion_ensure_current_map_table!
    ret = tef_expansion_original_encounter_type
    return ret if ret
    return nil if !TravelExpansionFramework.current_map_expansion_id
    return nil if !$game_map || !$game_player
    time = pbGetTimeNow
    terrain_tag = $game_map.terrain_tag($game_player.x, $game_player.y) rescue nil
    if $PokemonGlobal && $PokemonGlobal.surfing
      return find_valid_encounter_type_for_time(:Water, time)
    end
    if has_land_encounters? && TravelExpansionFramework.expansion_land_encounter_tile?($game_map, $game_player.x, $game_player.y, terrain_tag)
      return :BugContest if pbInBugContest? && has_encounter_type?(:BugContest)
      return find_valid_encounter_type_for_time(:Land, time)
    end
    return find_valid_encounter_type_for_time(:Cave, time) if has_cave_encounters?
    return nil
  end
end
