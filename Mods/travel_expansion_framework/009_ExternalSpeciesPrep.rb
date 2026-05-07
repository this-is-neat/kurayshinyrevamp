module TravelExpansionFramework
  module_function

  SPECIES_SOURCE_CANDIDATES = [
    ["PBS", "pokemon.txt"],
    ["Backups", "pokemon.txt"],
    ["pokemon.txt"]
  ] if !const_defined?(:SPECIES_SOURCE_CANDIDATES)

  PBS_STAT_ORDER = [
    :HP,
    :ATTACK,
    :DEFENSE,
    :SPEED,
    :SPECIAL_ATTACK,
    :SPECIAL_DEFENSE
  ] if !const_defined?(:PBS_STAT_ORDER)

  EXTERNAL_SPECIES_ASSET_EXTENSIONS = [".png", ".gif", ".jpg", ".jpeg", ".bmp"].freeze if !const_defined?(:EXTERNAL_SPECIES_ASSET_EXTENSIONS)

  def custom_species_framework_root
    path = File.expand_path("./Mods/custom_species_framework", current_game_root)
    return File.directory?(path) ? path : nil
  end

  def custom_species_framework_species_dir
    root = custom_species_framework_root
    return nil if root.nil?
    path = File.join(root, "data", "species")
    ensure_dir(path)
    return path
  end

  def custom_species_framework_present?
    return !custom_species_framework_root.nil?
  end

  def external_species_source_candidates(project_info)
    return [] if !project_info.is_a?(Hash)
    root = normalize_path(project_info[:root], current_game_root)
    return [] if root.nil? || root.empty?
    candidates = []
    SPECIES_SOURCE_CANDIDATES.each do |parts|
      path = File.join(root, *parts)
      candidates << path if File.file?(path)
    end
    return candidates.uniq
  end

  def external_species_source_path(project_info)
    return external_species_source_candidates(project_info).first
  end

  def external_species_pack_path(project_info)
    species_dir = custom_species_framework_species_dir
    return nil if species_dir.nil? || !project_info.is_a?(Hash)
    project_id = project_info[:id].to_s
    return nil if project_id.empty?
    return File.join(species_dir, "travel_expansion_#{slugify(project_id)}.json")
  end

  def external_species_pack_ready?(project_info)
    path = external_species_pack_path(project_info)
    return !path.nil? && File.file?(path)
  end

  def external_species_project_prefix(project_info)
    values = []
    values << project_info[:namespace] if project_info.is_a?(Hash)
    values << project_info[:id] if project_info.is_a?(Hash)
    values << project_info[:display_name] if project_info.is_a?(Hash)
    values.each do |value|
      normalized = normalize_species_symbol_name(value)
      return normalized if normalized
    end
    return "EXPANSION"
  end

  def external_species_canonical_id(project_info, internal_name)
    normalized_name = normalize_species_symbol_name(internal_name)
    return nil if normalized_name.nil?
    return "CSF_#{external_species_project_prefix(project_info)}_#{normalized_name}"
  end

  def external_species_foreign_number(record)
    return 0 if !record.is_a?(Hash)
    value = integer(record["section"], 0)
    value = integer(record["Number"], 0) if value <= 0
    return value
  end

  def custom_species_framework_graphics_root
    root = custom_species_framework_root
    return nil if root.nil?
    return File.join(root, "Graphics", "Pokemon")
  end

  def custom_species_framework_asset_logical_path(folder_name, asset_name)
    return "Graphics/Pokemon/#{folder_name}/#{asset_name}"
  end

  def custom_species_framework_asset_destination(folder_name, asset_name)
    root = custom_species_framework_graphics_root
    return nil if root.nil?
    destination = File.join(root, folder_name, "#{asset_name}.png")
    ensure_dir(File.dirname(destination))
    return destination
  end

  def external_species_existing_asset(root, relative_bases)
    return nil if root.nil? || root.empty?
    Array(relative_bases).each do |relative_base|
      next if relative_base.to_s.empty?
      EXTERNAL_SPECIES_ASSET_EXTENSIONS.each do |extension|
        candidate = File.join(root, "#{relative_base}#{extension}")
        matched = runtime_exact_file_path(candidate)
        return matched if matched
      end
    end
    return nil
  end

  def external_species_asset_bases(foreign_number, internal_name, asset_kind)
    number_token = foreign_number > 0 ? foreign_number.to_s : nil
    internal_token = normalize_species_symbol_name(internal_name)
    bases = []
    case asset_kind
    when :front
      bases << "Graphics/Battlers/Front/#{number_token}" if number_token
      bases << "Graphics/Battlers/#{number_token}" if number_token
      bases << "Graphics/Battlers/Front/#{internal_token}" if internal_token
      bases << "Graphics/Battlers/#{internal_token}" if internal_token
    when :back
      bases << "Graphics/Battlers/Back/#{number_token}" if number_token
      bases << "Graphics/Battlers/#{number_token}b" if number_token
      bases << "Graphics/Battlers/Back/#{internal_token}" if internal_token
      bases << "Graphics/Battlers/#{internal_token}b" if internal_token
    when :icon
      bases << "Graphics/Icons/icon#{number_token}" if number_token
      bases << "Graphics/Icons/#{number_token}" if number_token
      bases << "Graphics/Pictures/DexNew/Icon/#{number_token}" if number_token
      bases << "Graphics/Pictures/Dex/Icon/#{number_token}" if number_token
      bases << "Graphics/Icons/icon#{internal_token}" if internal_token
      bases << "Graphics/Icons/#{internal_token}" if internal_token
    when :shiny_front
      bases << "Graphics/Battlers/FrontShiny/#{number_token}" if number_token
      bases << "Graphics/Battlers/Front/#{number_token}s" if number_token
      bases << "Graphics/Battlers/FrontShiny/#{internal_token}" if internal_token
      bases << "Graphics/Battlers/Front/#{internal_token}s" if internal_token
    when :shiny_back
      bases << "Graphics/Battlers/BackShiny/#{number_token}" if number_token
      bases << "Graphics/Battlers/Back/#{number_token}s" if number_token
      bases << "Graphics/Battlers/BackShiny/#{internal_token}" if internal_token
      bases << "Graphics/Battlers/Back/#{internal_token}s" if internal_token
    when :shiny_icon
      bases << "Graphics/Icons/icon#{number_token}s" if number_token
      bases << "Graphics/Pictures/DexNew/Icon/#{number_token}s" if number_token
      bases << "Graphics/Pictures/Dex/Icon/#{number_token}s" if number_token
      bases << "Graphics/Icons/icon#{internal_token}s" if internal_token
    end
    return bases.compact.uniq
  end

  def stage_external_species_assets(project_info, record, canonical_id)
    root = normalize_path(project_info[:root], current_game_root)
    return {} if root.nil? || canonical_id.to_s.empty?
    foreign_number = external_species_foreign_number(record)
    internal_name = record["InternalName"]
    staged = {}
    {
      :front       => ["Front", canonical_id],
      :back        => ["Back", canonical_id],
      :icon        => ["Icons", canonical_id],
      :shiny_front => ["Front", "#{canonical_id}_shiny_front"],
      :shiny_back  => ["Back", "#{canonical_id}_shiny_back"],
      :shiny_icon  => ["Icons", "#{canonical_id}_shiny_icon"]
    }.each_pair do |asset_kind, folder_name|
      folder_name, asset_name = folder_name
      source_path = external_species_existing_asset(root, external_species_asset_bases(foreign_number, internal_name, asset_kind))
      next if source_path.nil?
      destination_path = custom_species_framework_asset_destination(folder_name, asset_name)
      next if destination_path.nil?
      copied = copy_runtime_file(source_path, destination_path)
      next if !copied
      staged[asset_kind.to_s] = custom_species_framework_asset_logical_path(folder_name, asset_name)
    end
    return staged
  end

  def next_custom_species_slot
    species_dir = custom_species_framework_species_dir
    return 1 if species_dir.nil?
    max_slot = 0
    Dir[File.join(species_dir, "*.json")].sort.each do |path|
      begin
        raw = File.read(path)
        raw.scan(/"slot"\s*:\s*(\d+)/i) do |match|
          max_slot = [max_slot, match[0].to_i].max
        end
      rescue
      end
    end
    return max_slot + 1
  end

  def parse_pbs_sections(path)
    sections = []
    current = nil
    File.foreach(path) do |line|
      raw_line = line.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      stripped = raw_line.strip
      next if stripped.empty? || stripped.start_with?("#")
      if stripped =~ /\A\[(.+)\]\z/
        current = {
          "section" => $1.to_s.strip
        }
        sections << current
        next
      end
      next if current.nil?
      next if stripped !~ /\A([^=]+?)\s*=\s*(.*)\z/
      current[$1.to_s.strip] = $2.to_s.strip
    end
    return sections
  rescue => e
    log("PBS species parse failed for #{path}: #{e.message}")
    return []
  end

  def parse_pbs_csv(value)
    return [] if value.nil?
    return value.to_s.split(",").map { |entry| entry.to_s.strip }.reject { |entry| entry.empty? }
  end

  def parse_pbs_stat_hash(value)
    values = parse_pbs_csv(value).map { |entry| integer(entry, 0) }
    ret = {}
    PBS_STAT_ORDER.each_with_index do |stat_key, index|
      ret[stat_key.to_s] = values[index] || 1
    end
    return ret
  end

  def parse_pbs_moves(value)
    values = parse_pbs_csv(value)
    ret = []
    index = 0
    while index + 1 < values.length
      level = integer(values[index], 1)
      move = values[index + 1].to_s
      ret << { "level" => level, "move" => move }
      index += 2
    end
    return ret
  end

  def parse_pbs_evolutions(value)
    values = parse_pbs_csv(value)
    ret = []
    index = 0
    while index + 1 < values.length
      species = values[index].to_s
      method = values[index + 1].to_s
      parameter = values[index + 2]
      ret << {
        "species"   => species,
        "method"    => method,
        "parameter" => parameter
      }
      index += 3
    end
    return ret
  end

  def normalize_species_symbol_name(value)
    text = value.to_s.strip.upcase
    text.gsub!(/[^A-Z0-9_]/, "")
    return nil if text.empty?
    return text
  end

  def normalize_external_species_enum_value(raw_value, enum_kind, fallback)
    normalized = normalize_species_symbol_name(raw_value)
    return fallback if normalized.nil?
    case enum_kind
    when :gender_ratio
      return "FemaleOneEighth"   if normalized == "FEMALE12POINT5PERCENT"
      return "FemaleSevenEighths" if normalized == "FEMALE87POINT5PERCENT"
      return "FemaleSevenEighths" if normalized == "MALE12POINT5PERCENT"
      return "FemaleOneEighth"    if normalized == "MALE87POINT5PERCENT"
    when :growth_rate
      return "Medium"      if normalized == "MEDIUMFAST"
      return "Parabolic"   if normalized == "MEDIUMSLOW" || normalized == "MEDIUM_SLOW"
      return "Fluctuating" if normalized == "SLOWTHENVERYFAST"
      return "Erratic"     if normalized == "FASTTHENVERYSLOW"
    end
    return normalized
  end

  def host_species_known_by_name?(internal_name)
    symbol_name = normalize_species_symbol_name(internal_name)
    return false if symbol_name.nil?
    return !GameData::Species.try_get(symbol_name.to_sym).nil?
  rescue
    return false
  end

  def build_custom_species_definition_from_pbs(record, slot, project_info)
    internal_name = normalize_species_symbol_name(record["InternalName"])
    return nil if internal_name.nil?
    canonical_id = external_species_canonical_id(project_info, internal_name)
    return nil if canonical_id.nil?
    foreign_number = external_species_foreign_number(record)
    name = normalize_string(record["Name"], internal_name.capitalize)
    category = normalize_string(record["Kind"], "Foreign Species")
    type_values = parse_pbs_csv(record["Type1"])
    type_values << record["Type2"].to_s if !record["Type2"].to_s.strip.empty?
    base_stats = parse_pbs_stat_hash(record["BaseStats"])
    moves = parse_pbs_moves(record["Moves"])
    abilities = parse_pbs_csv(record["Abilities"])
    hidden_abilities = parse_pbs_csv(record["HiddenAbility"])
    egg_groups = parse_pbs_csv(record["Compatibility"])
    growth_rate = normalize_external_species_enum_value(record["GrowthRate"], :growth_rate, "Medium")
    gender_ratio = normalize_external_species_enum_value(record["GenderRate"], :gender_ratio, "Female50Percent")
    color = normalize_species_symbol_name(record["Color"]) || "Red"
    habitat = normalize_species_symbol_name(record["Habitat"]) || "None"
    regional_numbers = parse_pbs_csv(record["RegionalNumbers"]).map { |entry| integer(entry, 0) }.find_all { |value| value > 0 }
    staged_assets = stage_external_species_assets(project_info, record, canonical_id)

    return {
      "slot"                     => integer(slot, 0),
      "id"                       => canonical_id,
      "name"                     => name,
      "category"                 => category,
      "pokedex_entry"            => record["Pokedex"].to_s,
      "type1"                    => (type_values[0] || "NORMAL"),
      "type2"                    => (type_values[1] || type_values[0] || "NORMAL"),
      "base_stats"               => base_stats,
      "base_exp"                 => integer(record["BaseEXP"], 1),
      "growth_rate"              => growth_rate,
      "gender_ratio"             => gender_ratio,
      "catch_rate"               => integer(record["Rareness"], 45),
      "happiness"                => integer(record["Happiness"], 70),
      "moves"                    => moves,
      "abilities"                => abilities,
      "hidden_abilities"         => hidden_abilities,
      "egg_groups"               => egg_groups,
      "hatch_steps"              => integer(record["StepsToHatch"], 0),
      "height"                   => integer(record["Height"].to_f * 10, 1),
      "weight"                   => integer(record["Weight"].to_f * 10, 1),
      "color"                    => color,
      "habitat"                  => habitat,
      "evolutions"               => parse_pbs_evolutions(record["Evolutions"]),
      "kind"                     => "fakemon",
      "starter_eligible"         => false,
      "encounter_eligible"       => false,
      "trainer_eligible"         => false,
      "source_pack"              => project_info[:display_name].to_s,
      "creator"                  => project_info[:display_name].to_s,
      "manual_review_required"   => true,
      "auto_import_allowed"      => false,
      "usage_permission"         => "Linked local install only; generated for private compatibility testing.",
      "notes"                    => "Generated by Travel Expansion Framework from #{File.basename(external_species_source_path(project_info).to_s)}.",
      "assets"                   => staged_assets,
      "integration"              => {
        "framework_species_key"   => canonical_id,
        "compatibility_aliases"   => [internal_name],
        "legacy_foreign_numbers"  => (foreign_number > 0 ? [foreign_number] : []),
        "source_section"          => record["section"].to_s,
        "form_names"              => parse_pbs_csv(record["FormNames"]),
        "regional_numbers"        => regional_numbers
      }
    }
  end

  def prepare_external_species_pack(project_reference)
    project_info = project_reference.is_a?(Hash) ? project_reference : external_projects[project_reference.to_s]
    return { "success" => false, "error" => "Project was not found." } if !project_info.is_a?(Hash)
    return { "success" => false, "error" => "Custom Species Framework is not installed." } if !custom_species_framework_present?
    source_path = external_species_source_path(project_info)
    return { "success" => false, "error" => "No readable species source file was found for this project." } if source_path.nil?

    records = parse_pbs_sections(source_path)
    candidates = []
    records.each do |record|
      next if !record.is_a?(Hash)
      internal_name = record["InternalName"].to_s
      next if internal_name.empty?
      next if host_species_known_by_name?(internal_name)
      candidates << record
    end
    return {
      "success"      => false,
      "display_name" => project_info[:display_name],
      "error"        => "No new custom species were found to append."
    } if candidates.empty?

    slot = next_custom_species_slot
    payload = { "species" => [] }
    candidates.each do |record|
      entry = build_custom_species_definition_from_pbs(record, slot, project_info)
      next if entry.nil?
      payload["species"] << entry
      slot += 1
    end
    return {
      "success"      => false,
      "display_name" => project_info[:display_name],
      "error"        => "Species parsing produced no usable entries."
    } if payload["species"].empty?

    output_path = external_species_pack_path(project_info)
    ensure_dir(File.dirname(output_path))
    File.open(output_path, "wb") { |file| file.write(safe_json_dump(payload)) }
    result = {
      "success"             => true,
      "display_name"        => project_info[:display_name],
      "project_id"          => project_info[:id],
      "species_source_path" => source_path,
      "output_path"         => output_path,
      "species_count"       => payload["species"].length,
      "first_slot"          => payload["species"].first["slot"],
      "last_slot"           => payload["species"].last["slot"],
      "restart_required"    => true,
      "generated_at"        => timestamp_string
    }
    write_json_report("external_species_pack_#{slugify(project_info[:id])}.json", result)
    return result
  rescue => e
    log("Species pack preparation failed for #{project_reference}: #{e.message}")
    return {
      "success"      => false,
      "display_name" => (project_info[:display_name] rescue project_reference.to_s),
      "error"        => e.message
    }
  end
end
