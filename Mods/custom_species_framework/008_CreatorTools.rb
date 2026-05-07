module CustomSpeciesFramework
  def self.catalog_guard(label, fallback = nil)
    return yield
  rescue SystemStackError => e
    log("Creator catalog #{label} stack overflow: #{e.message}")
    return fallback
  rescue StandardError => e
    log("Creator catalog #{label} failed: #{e.class}: #{e.message}")
    return fallback
  end

  def self.unique_game_data_entries(data_hash)
    unique = {}
    (data_hash || {}).each_value do |entry|
      next if entry.nil?
      key = entry.respond_to?(:id) ? entry.id : entry.object_id
      unique[key] ||= entry
    end
    return unique.values
  end

  def self.catalog_enum_entries(data_hash, sort_by_name = true)
    entries = unique_game_data_entries(data_hash).map do |entry|
      {
        "id" => entry.id.to_s,
        "name" => (entry.respond_to?(:name) ? entry.name.to_s : entry.id.to_s)
      }
    end
    if sort_by_name
      entries.sort_by! { |entry| [entry["name"].to_s.downcase, entry["id"].to_s] }
    else
      entries.sort_by! { |entry| entry["id"].to_s }
    end
    return entries
  end

  def self.catalog_move_category_name(category)
    return "Physical" if category.to_i == 0
    return "Special" if category.to_i == 1
    return "Status"
  end

  def self.catalog_move_entries
    moves = unique_game_data_entries(GameData::Move::DATA).map do |move|
      {
        "id" => move.id.to_s,
        "name" => move.name.to_s,
        "type" => move.type.to_s,
        "category" => move.category,
        "category_name" => catalog_move_category_name(move.category),
        "power" => move.base_damage,
        "accuracy" => move.accuracy,
        "pp" => move.total_pp,
        "priority" => move.priority,
        "description" => move.description.to_s
      }
    end
    moves.sort_by! { |move| [move["name"].downcase, move["id"]] }
    return moves
  end

  def self.catalog_ability_entries
    abilities = unique_game_data_entries(GameData::Ability::DATA).map do |ability|
      {
        "id" => ability.id.to_s,
        "name" => ability.name.to_s,
        "description" => ability.description.to_s
      }
    end
    abilities.sort_by! { |ability| [ability["name"].downcase, ability["id"]] }
    return abilities
  end

  def self.catalog_item_entries
    items = unique_game_data_entries(GameData::Item::DATA).find_all do |item|
      next false if item.nil?
      next false if item.id.nil?
      next false if item.id_number.to_i <= 0
      true
    end
    entries = items.map do |item|
      {
        "id" => item.id.to_s,
        "name" => item.name.to_s,
        "id_number" => item.id_number,
        "pocket" => item.pocket,
        "description" => item.description.to_s
      }
    end
    entries.sort_by! { |item| [item["name"].downcase, item["id_number"].to_i] }
    return entries
  end

  def self.evolution_parameter_kind(evolution)
    parameter = evolution.parameter
    return nil if parameter.nil?
    return parameter.name if parameter.is_a?(Class)
    return parameter.to_s if parameter.is_a?(Symbol)
    return parameter.class.name
  end

  def self.catalog_evolution_entries
    evolutions = unique_game_data_entries(GameData::Evolution::DATA).map do |evolution|
      {
        "id" => evolution.id.to_s,
        "name" => evolution.real_name.to_s,
        "parameter_kind" => evolution_parameter_kind(evolution),
        "minimum_level" => evolution.minimum_level
      }
    end
    evolutions.sort_by! { |entry| [entry["name"].downcase, entry["id"]] }
    return evolutions
  end

  def self.catalog_stat_entries
    stats = unique_game_data_entries(GameData::Stat::DATA).find_all do |stat|
      stat.respond_to?(:main?) ? stat.main? : true
    end
    entries = stats.map do |stat|
      {
        "id" => stat.id.to_s,
        "name" => (stat.respond_to?(:name) ? stat.name.to_s : stat.id.to_s)
      }
    end
    entries.sort_by! { |entry| entry["id"] }
    return entries
  end

  def self.catalog_species_entries
    species = unique_game_data_entries(GameData::Species::DATA).find_all do |entry|
      next false if entry.nil?
      next false if entry.id == MISSING_SPECIES_ID
      next false if entry.form.to_i != 0
      next false if actual_fusion_number?(entry.id_number)
      next false if actual_triple_fusion_number?(entry.id_number)
      true
    end
    entries = []
    species.each do |entry|
      begin
        payload = catalog_species_payload(entry)
        entries << payload if payload
      rescue SystemStackError => e
        log("Creator catalog skipped species #{entry.id}: #{e.class}: #{e.message}")
      rescue StandardError => e
        log("Creator catalog skipped species #{entry.id}: #{e.class}: #{e.message}")
      end
    end
    entries.sort_by! { |entry| [entry["name"].downcase, entry["id_number"].to_i] }
    return entries
  end

  def self.catalog_species_payload(entry)
    metadata = metadata_for(entry.id) || {}
    kind = metadata[:kind] || (metadata.empty? ? :base_game : :fakemon)
    previous_species = catalog_guard("previous species for #{entry.id}", nil) do
      prev = entry.get_previous_species
      prev if prev && prev != entry.species
    end
    {
      "id" => entry.id.to_s,
      "species" => entry.species.to_s,
      "name" => entry.name.to_s,
      "id_number" => entry.id_number,
      "category" => entry.category.to_s,
      "pokedex_entry" => entry.pokedex_entry.to_s,
      "design_notes" => metadata[:design_notes].to_s,
      "template_source_label" => metadata[:template_source_label].to_s,
      "types" => entry.types.map { |type| type.to_s },
      "base_stats" => catalog_stat_hash(entry.base_stats),
      "bst" => entry.base_stats.values.compact.map { |value| value.to_i }.inject(0, :+),
      "base_exp" => entry.base_exp,
      "growth_rate" => catalog_named_entry(entry.growth_rate, GameData::GrowthRate),
      "gender_ratio" => catalog_named_entry(entry.gender_ratio, GameData::GenderRatio),
      "catch_rate" => entry.catch_rate,
      "happiness" => entry.happiness,
      "abilities" => catalog_named_list(entry.abilities, GameData::Ability),
      "hidden_abilities" => catalog_named_list(entry.hidden_abilities, GameData::Ability),
      "moves" => catalog_guard("moves for #{entry.id}", []) { catalog_species_level_moves(entry.moves) },
      "tutor_moves" => catalog_guard("tutor moves for #{entry.id}", []) { catalog_species_named_moves(entry.tutor_moves) },
      "egg_moves" => catalog_guard("egg moves for #{entry.id}", []) { catalog_species_named_moves(entry.egg_moves) },
      "tm_moves" => catalog_species_named_moves(metadata[:tm_moves]),
      "egg_groups" => catalog_named_list(entry.egg_groups, GameData::EggGroup),
      "hatch_steps" => entry.hatch_steps,
      "evolutions" => catalog_guard("evolutions for #{entry.id}", []) { catalog_species_evolutions(entry) },
      "previous_species" => catalog_species_reference(previous_species),
      "family_species" => catalog_guard("family for #{entry.id}", [catalog_species_reference(entry.id)].compact) { catalog_species_family(entry) },
      "height" => entry.height,
      "weight" => entry.weight,
      "color" => catalog_named_entry(entry.color, GameData::BodyColor),
      "shape" => catalog_named_entry(entry.shape, GameData::BodyShape),
      "habitat" => catalog_named_entry(entry.habitat, GameData::Habitat),
      "generation" => entry.generation,
      "kind" => kind.to_s,
      "source" => metadata.empty? ? "base_game" : "framework",
      "fusion_rule" => fusion_rule(entry.id).to_s,
      "fusion_compatible" => standard_fusion_compatible?(entry.id),
      "starter_eligible" => metadata[:starter_eligible] ? true : false,
      "encounter_eligible" => metadata[:encounter_eligible] ? true : false,
      "trainer_eligible" => metadata[:trainer_eligible] ? true : false,
      "source_pack" => metadata[:source_pack].to_s,
      "source_url" => metadata[:source_url].to_s,
      "creator" => metadata[:creator].to_s,
      "credit_text" => metadata[:credit_text].to_s,
      "usage_permission" => metadata[:usage_permission].to_s,
      "auto_import_allowed" => metadata[:auto_import_allowed] ? true : false,
      "manual_review_required" => metadata[:manual_review_required] ? true : false,
      "import_notes" => metadata[:import_notes].to_s,
      "regional_variant" => kind.to_s == "regional_variant",
      "variant_scope" => metadata[:variant_scope].to_s,
      "variant_family" => metadata[:variant_family].to_s,
      "base_species" => catalog_species_reference(metadata[:base_species]),
      "fallback_species" => catalog_species_reference(metadata[:fallback_species]),
      "visuals" => catalog_guard("visuals for #{entry.id}", {}) { catalog_species_visuals(entry) },
      "world_data" => catalog_species_world_data(metadata),
      "fusion_meta" => catalog_species_fusion_meta(entry, metadata),
      "export_meta" => catalog_species_export_meta(entry)
    }
  end

  def self.catalog_stat_hash(base_stats)
    stats = {}
    GameData::Stat.each_main do |stat|
      stats[stat.id.to_s] = base_stats[stat.id].to_i
    end
    return stats
  end

  def self.catalog_named_entry(id, klass)
    return nil if id.nil?
    entry = klass.get(id) rescue nil
    return nil if entry.nil?
    return {
      "id" => entry.id.to_s,
      "name" => (entry.respond_to?(:name) ? entry.name.to_s : entry.id.to_s)
    }
  end

  def self.catalog_named_list(ids, klass)
    return [] if ids.nil?
    ids.map { |id| catalog_named_entry(id, klass) }.compact
  end

  def self.catalog_move_reference(move_id)
    move = GameData::Move.get(move_id) rescue nil
    return nil if move.nil?
    return {
      "id" => move.id.to_s,
      "name" => move.name.to_s,
      "type" => move.type.to_s,
      "category" => move.category,
      "category_name" => catalog_move_category_name(move.category),
      "power" => move.base_damage,
      "accuracy" => move.accuracy,
      "pp" => move.total_pp
    }
  end

  def self.catalog_species_level_moves(moves)
    return [] if moves.nil?
    moves.map do |level, move_id|
      move_data = catalog_move_reference(move_id)
      next if move_data.nil?
      move_data["level"] = level.to_i
      move_data
    end.compact.sort_by { |move| [move["level"].to_i, move["name"].to_s] }
  end

  def self.catalog_species_named_moves(move_ids)
    return [] if move_ids.nil?
    move_ids.map { |move_id| catalog_move_reference(move_id) }.compact
  end

  def self.catalog_species_reference(species_id)
    return nil if species_id.nil?
    species = GameData::Species.get(species_id) rescue nil
    return nil if species.nil?
    return {
      "id" => species.id.to_s,
      "name" => species.name.to_s,
      "id_number" => species.id_number
    }
  end

  def self.catalog_species_evolutions(entry)
    evos = entry.get_evolutions(false) rescue []
    evos.map do |species_id, method_id, parameter|
      method = GameData::Evolution.get(method_id) rescue nil
      {
        "species" => catalog_species_reference(species_id),
        "method" => {
          "id" => method_id.to_s,
          "name" => (method ? method.real_name.to_s : method_id.to_s),
          "parameter_kind" => evolution_parameter_kind(method),
          "minimum_level" => (method ? method.minimum_level : nil)
        },
        "parameter" => catalog_evolution_parameter(parameter)
      }
    end
  end

  def self.catalog_evolution_parameter(parameter)
    return nil if parameter.nil?
    if parameter.is_a?(Symbol)
      move = catalog_move_reference(parameter)
      return move if move
      item = catalog_named_entry(parameter, GameData::Item)
      return item if item
      species = catalog_species_reference(parameter)
      return species if species
      type = catalog_named_entry(parameter, GameData::Type)
      return type if type
    end
    return parameter
  end

  def self.catalog_species_family(entry)
    family = entry.get_related_species rescue [entry.id]
    family.map { |species_id| catalog_species_reference(species_id) }.compact
  end

  def self.absolute_path_string?(path)
    return false if path.nil?
    text = path.to_s
    return true if text.start_with?(File::SEPARATOR)
    return true if text =~ /\A[A-Za-z]:[\\\/]/
    return false
  end

  def self.resolve_existing_file_path(path)
    return nil if path.nil?
    text = path.to_s
    return nil if text.empty?
    candidates = []
    if absolute_path_string?(text)
      candidates << text
      candidates << "#{text}.png"
    else
      normalized = text.tr("/", File::SEPARATOR)
      candidates << File.join(ROOT, normalized)
      candidates << File.join(ROOT, normalized + ".png")
      candidates << File.join(GAME_ROOT, normalized)
      candidates << File.join(GAME_ROOT, normalized + ".png")
    end
    candidates.each do |candidate|
      return File.expand_path(candidate) if File.exist?(candidate)
    end
    return nil
  end

  def self.web_asset_url_for_file(path)
    absolute = resolve_existing_file_path(path)
    return nil if absolute.nil?
    mod_root = File.expand_path(ROOT)
    game_root = File.expand_path(GAME_ROOT)
    if absolute.start_with?(mod_root + File::SEPARATOR)
      relative = absolute[(mod_root.length + 1)..-1].tr(File::SEPARATOR, "/")
      return "/mod/#{relative}"
    end
    if absolute.start_with?(game_root + File::SEPARATOR)
      relative = absolute[(game_root.length + 1)..-1].tr(File::SEPARATOR, "/")
      return "/game/#{relative}"
    end
    return nil
  end

  def self.catalog_first_existing_path(*paths)
    paths.compact.each do |path|
      return path if resolve_existing_file_path(path)
    end
    return nil
  end

  def self.catalog_default_front_sprite_path(entry)
    dex_number = entry.id_number.to_i
    return nil if dex_number <= 0
    return catalog_first_existing_path(
      "Graphics/BaseSprites/#{dex_number}",
      "Graphics/Battlers/#{dex_number}/#{dex_number}",
      "Graphics/Pokemon/Front/#{entry.id}"
    )
  end

  def self.catalog_front_sprite_path(entry)
    default_path = catalog_default_front_sprite_path(entry)
    return default_path if default_path

    explicit_path = GameData::Species.front_sprite_filename(entry.id) rescue nil
    return explicit_path if resolve_existing_file_path(explicit_path)

    dex_number = entry.id_number.to_i
    return nil if dex_number <= 0

    if defined?(get_unfused_sprite_path)
      begin
        unfused_path = get_unfused_sprite_path(dex_number, nil)
        return unfused_path if resolve_existing_file_path(unfused_path)
      rescue
      end
    end

    return nil
  end

  def self.catalog_back_sprite_path(entry, front_path = nil)
    default_path = catalog_first_existing_path("Graphics/Pokemon/Back/#{entry.id}")
    return default_path if default_path

    explicit_path = GameData::Species.back_sprite_filename(entry.id) rescue nil
    return explicit_path if resolve_existing_file_path(explicit_path)
    return front_path
  end

  def self.catalog_icon_sprite_path(entry)
    dex_number = entry.id_number.to_i
    default_path = catalog_first_existing_path(
      "Graphics/Pokemon/Icons/#{entry.id}",
      (dex_number > 0 ? "Graphics/Icons/icon#{dex_number}" : nil)
    )
    return default_path if default_path

    explicit_path = GameData::Species.icon_filename(entry.id) rescue nil
    return explicit_path if resolve_existing_file_path(explicit_path)
    return nil
  end

  def self.catalog_species_visuals(entry)
    front_path = nil
    back_path = nil
    icon_path = nil
    shiny_front_path = nil
    shiny_back_path = nil
    overworld_path = nil
    if custom_species?(entry.id)
      front_path = asset_path(:front, entry.id)
      back_path = asset_path(:back, entry.id)
      icon_path = preferred_icon_path(entry.id)
      shiny_front_path = asset_path(:shiny_front, entry.id)
      shiny_back_path = asset_path(:shiny_back, entry.id)
      overworld_path = asset_path(:overworld, entry.id)
    end
    front_path ||= catalog_front_sprite_path(entry)
    back_path ||= catalog_back_sprite_path(entry, front_path)
    icon_path ||= catalog_icon_sprite_path(entry)
    {
      "front" => web_asset_url_for_file(front_path),
      "back" => web_asset_url_for_file(back_path),
      "icon" => web_asset_url_for_file(icon_path),
      "shiny_front" => web_asset_url_for_file(shiny_front_path),
      "shiny_back" => web_asset_url_for_file(shiny_back_path),
      "overworld" => web_asset_url_for_file(overworld_path),
      "shiny_strategy" => "hue_shift"
    }
  end

  def self.catalog_species_world_data(metadata)
    return {
      "encounter_eligible" => metadata[:encounter_eligible] ? true : false,
      "trainer_eligible" => metadata[:trainer_eligible] ? true : false,
      "encounter_rarity" => metadata[:encounter_rarity].to_s,
      "encounter_zones" => metadata[:encounter_zones] || [],
      "trainer_roles" => metadata[:trainer_roles] || [],
      "trainer_notes" => metadata[:trainer_notes].to_s,
      "encounter_level_min" => metadata[:encounter_level_min].to_i,
      "encounter_level_max" => metadata[:encounter_level_max].to_i
    }
  end

  def self.catalog_species_fusion_meta(entry, metadata)
    return {
      "rule" => fusion_rule(entry.id).to_s,
      "compatible" => standard_fusion_compatible?(entry.id),
      "head_offset_x" => metadata[:head_offset_x].to_i,
      "head_offset_y" => metadata[:head_offset_y].to_i,
      "body_offset_x" => metadata[:body_offset_x].to_i,
      "body_offset_y" => metadata[:body_offset_y].to_i,
      "naming_notes" => metadata[:fusion_naming_notes].to_s,
      "sprite_hints" => metadata[:fusion_sprite_hints].to_s
    }
  end

  def self.catalog_species_export_meta(entry)
    metadata = metadata_for(entry.id) || {}
    return {
      "framework_managed" => !metadata.empty?,
      "slot" => metadata[:framework_slot],
      "json_filename" => "#{entry.id.to_s.downcase}.json",
      "recommended_internal_id" => entry.id.to_s,
      "author" => metadata[:export_author].to_s,
      "version" => metadata[:export_version].to_s,
      "pack_name" => metadata[:export_pack_name].to_s,
      "tags" => metadata[:export_tags] || [],
      "source_pack" => metadata[:source_pack].to_s,
      "source_url" => metadata[:source_url].to_s,
      "creator" => metadata[:creator].to_s,
      "credit_text" => metadata[:credit_text].to_s,
      "usage_permission" => metadata[:usage_permission].to_s,
      "auto_import_allowed" => metadata[:auto_import_allowed] ? true : false,
      "manual_review_required" => metadata[:manual_review_required] ? true : false,
      "framework_species_key" => metadata[:framework_species_key].to_s,
      "insert_status" => metadata[:import_insert_status].to_s,
      "insert_errors" => metadata[:import_insert_errors] || []
    }
  end

  def self.creator_catalog_payload
    return {
      "generated_at" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
      "framework" => {
        "version" => @config["version"].to_s,
        "active_starter_set" => current_starter_set_id.to_s,
        "standard_species_min" => FRAMEWORK_FIRST_ID,
        "standard_species_max" => MISSING_SPECIES_NUM - 1
      },
      "types" => catalog_guard("types", []) { catalog_enum_entries(GameData::Type::DATA) },
      "abilities" => catalog_guard("abilities", []) { catalog_ability_entries },
      "moves" => catalog_guard("moves", []) { catalog_move_entries },
      "items" => catalog_guard("items", []) { catalog_item_entries },
      "growth_rates" => catalog_guard("growth rates", []) { catalog_enum_entries(GameData::GrowthRate::DATA, false) },
      "gender_ratios" => catalog_guard("gender ratios", []) { catalog_enum_entries(GameData::GenderRatio::DATA, false) },
      "egg_groups" => catalog_guard("egg groups", []) { catalog_enum_entries(GameData::EggGroup::DATA, false) },
      "body_colors" => catalog_guard("body colors", []) { catalog_enum_entries(GameData::BodyColor::DATA, false) },
      "body_shapes" => catalog_guard("body shapes", []) { catalog_enum_entries(GameData::BodyShape::DATA, false) },
      "habitats" => catalog_guard("habitats", []) { catalog_enum_entries(GameData::Habitat::DATA, false) },
      "evolution_methods" => catalog_guard("evolution methods", []) { catalog_evolution_entries },
      "stats" => catalog_guard("stats", []) { catalog_stat_entries },
      "species" => catalog_guard("species", []) { catalog_species_entries },
      "starter_sets" => (@starter_sets || {}).values.sort_by { |starter_set| [starter_set[:intro_order].to_i, starter_set[:label].to_s] }.map do |starter_set|
        {
          "id" => starter_set[:id].to_s,
          "label" => starter_set[:label].to_s,
          "species" => (starter_set[:species] || []).map { |species| species.to_s }
        }
      end
    }
  end

  def self.export_creator_catalog!
    ensure_directory!(CREATOR_DIR)
    ensure_directory!(CREATOR_DATA_DIR)
    payload = creator_catalog_payload
    temp_file = CREATOR_CATALOG_FILE + ".tmp"
    File.open(temp_file, "wb") do |file|
      file.write(ModManager::JSON.dump(payload))
    end
    File.delete(CREATOR_CATALOG_FILE) if File.exist?(CREATOR_CATALOG_FILE)
    File.rename(temp_file, CREATOR_CATALOG_FILE)
    log("Exported creator catalog to #{CREATOR_CATALOG_FILE}.") if debug?
  rescue SystemStackError => e
    begin
      temp_file = CREATOR_CATALOG_FILE + ".tmp"
      File.delete(temp_file) if File.exist?(temp_file)
    rescue
    end
    log("Creator catalog export stack overflow: #{e.message}")
  rescue => e
    begin
      temp_file = CREATOR_CATALOG_FILE + ".tmp"
      File.delete(temp_file) if File.exist?(temp_file)
    rescue
    end
    log("Creator catalog export failed: #{e.class}: #{e.message}")
  end
end
