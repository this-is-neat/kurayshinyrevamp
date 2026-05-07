module CustomSpeciesFramework
  def self.registered_species_matches_definition?(existing_species, internal_id, id_number)
    return false if existing_species.nil?
    existing_id = if existing_species.respond_to?(:id)
      existing_species.id
    elsif existing_species.respond_to?(:species)
      existing_species.species
    end
    existing_number = existing_species.id_number if existing_species.respond_to?(:id_number)
    existing_id == internal_id && existing_number.to_i == id_number.to_i
  rescue
    false
  end

  def self.validate_runtime_data!
    validate_species_ids!
    validate_starter_sets!
    validate_species_records!
    validate_encounter_hooks!
    validate_trainer_hooks!
    report_validation_results
  end

  def self.validate_species_ids!
    seen_ids = {}
    seen_numbers = {}
    @species_definitions.each do |definition|
      game_data = definition[:game_data]
      internal_id = game_data[:id]
      id_number = game_data[:id_number]

      if blank?(internal_id)
        @errors << "A custom species is missing an internal ID."
        next
      end
      if !internal_id.to_s.start_with?(INTERNAL_PREFIX)
        @errors << "#{internal_id} must use the #{INTERNAL_PREFIX} internal prefix."
      end
      if id_number < FRAMEWORK_FIRST_ID || id_number > MISSING_SPECIES_NUM
        @errors << "#{internal_id} uses ID #{id_number}, but framework species must stay within #{FRAMEWORK_FIRST_ID}..#{MISSING_SPECIES_NUM - 1}."
      elsif id_number == MISSING_SPECIES_NUM
        @errors << "#{internal_id} is trying to use the reserved placeholder species ID #{MISSING_SPECIES_NUM}."
      end
      if seen_ids[internal_id]
        @errors << "Duplicate internal ID detected: #{internal_id}."
      end
      if seen_numbers[id_number]
        @errors << "Duplicate numeric species ID detected: #{id_number}."
      end
      if defined?(GameData::Species::DATA) && GameData::Species::DATA.has_key?(internal_id)
        existing_species = GameData::Species::DATA[internal_id]
        if !registered_species_matches_definition?(existing_species, internal_id, id_number)
          @errors << "Internal ID #{internal_id} already exists in GameData::Species."
        end
      end
      if defined?(GameData::Species::DATA) && GameData::Species::DATA.has_key?(id_number)
        existing_species = GameData::Species::DATA[id_number]
        if !registered_species_matches_definition?(existing_species, internal_id, id_number)
          @errors << "Numeric species ID #{id_number} already exists in GameData::Species."
        end
      end
      seen_ids[internal_id] = true
      seen_numbers[id_number] = true
    end
  end

  def self.validate_starter_sets!
    if @starter_sets.empty?
      @errors << "No starter sets were loaded."
      return
    end
    if blank?(@config["active_starter_set"]) || !@starter_sets[@config["active_starter_set"].to_s]
      @errors << "Active starter set #{@config['active_starter_set'].inspect} was not found."
    end

    @starter_sets.each_value do |starter_set|
      if starter_set[:species].length != 3
        @errors << "Starter set #{starter_set[:id]} must contain exactly 3 species."
        next
      end
      starter_set[:species].each do |species|
        next if species_reference_valid?(species)
        @errors << "Starter set #{starter_set[:id]} references missing species #{species}."
      end
      starter_set[:rival_counterpick].each_pair do |player_species, rival_species|
        @errors << "Starter set #{starter_set[:id]} has an invalid rival mapping for #{player_species}." if !species_reference_valid?(rival_species)
      end
      startup_mode = starter_set[:startup_mode].to_s
      valid_modes = %w[species_override kanto_map johto_map hoenn_map sinnoh_map kalos_map custom_map]
      if !valid_modes.include?(startup_mode)
        @errors << "Starter set #{starter_set[:id]} uses unsupported startup mode #{startup_mode.inspect}."
      end
    end
  end

  def self.validate_species_records!
    @species_definitions.each do |definition|
      game_data = definition[:game_data]
      metadata  = definition[:metadata]
      internal_id = game_data[:id]

      @errors << "#{internal_id} is missing a display name." if blank?(game_data[:name])
      @errors << "#{internal_id} is missing a category." if blank?(game_data[:category])
      @errors << "#{internal_id} is missing a Pokedex entry." if blank?(game_data[:pokedex_entry])
      @errors << "#{internal_id} has no abilities." if game_data[:abilities].empty?
      @errors << "#{internal_id} has no level-up learnset." if game_data[:moves].empty?
      @errors << "#{internal_id} must define valid starter moves at level 5 or below." if metadata[:starter_eligible] && game_data[:moves].none? { |move_entry| move_entry[0] <= 5 }

      validate_enum_reference!(internal_id, "type", game_data[:type1], GameData::Type)
      validate_enum_reference!(internal_id, "type", game_data[:type2], GameData::Type)
      validate_enum_reference!(internal_id, "growth rate", game_data[:growth_rate], GameData::GrowthRate)
      validate_enum_reference!(internal_id, "gender ratio", game_data[:gender_ratio], GameData::GenderRatio)
      validate_enum_reference!(internal_id, "color", game_data[:color], GameData::BodyColor)
      validate_enum_reference!(internal_id, "shape", game_data[:shape], GameData::BodyShape)
      validate_enum_reference!(internal_id, "habitat", game_data[:habitat], GameData::Habitat)

      game_data[:abilities].each { |ability| validate_enum_reference!(internal_id, "ability", ability, GameData::Ability) }
      game_data[:hidden_abilities].each { |ability| validate_enum_reference!(internal_id, "hidden ability", ability, GameData::Ability) }
      game_data[:moves].each { |level, move| validate_enum_reference!(internal_id, "move at level #{level}", move, GameData::Move) }
      game_data[:egg_groups].each { |egg_group| validate_enum_reference!(internal_id, "egg group", egg_group, GameData::EggGroup) }
      game_data[:evolutions].each do |evolution|
        evolved_species, method_symbol, _parameter = evolution
        @errors << "#{internal_id} evolves into missing species #{evolved_species}." if !species_reference_valid?(evolved_species)
        validate_enum_reference!(internal_id, "evolution method", method_symbol, GameData::Evolution)
      end

      game_data[:base_stats].each_pair do |stat_symbol, stat_value|
        if stat_value <= 0
          @errors << "#{internal_id} has an invalid #{stat_symbol} stat value of #{stat_value}."
        end
      end

      if metadata[:kind] == :regional_variant
        @errors << "#{internal_id} is a regional variant but has no base species." if metadata[:base_species].nil?
        if metadata[:base_species] && !species_reference_valid?(metadata[:base_species], true)
          @errors << "#{internal_id} references missing base species #{metadata[:base_species]}."
        end
        if metadata[:fallback_species] && !species_reference_valid?(metadata[:fallback_species], true)
          @errors << "#{internal_id} references missing fallback species #{metadata[:fallback_species]}."
        end
      end

      if metadata[:starter_eligible] && metadata[:fusion_rule] != :blocked
        @errors << "#{internal_id} is starter-eligible but not marked as non-fusible."
      end

      validate_asset_requirements!(definition)
    end
  end

  def self.validate_asset_requirements!(definition)
    game_data = definition[:game_data]
    metadata  = definition[:metadata]
    internal_id = game_data[:id]
    required_assets = []
    if metadata[:kind] == :fakemon || metadata[:starter_eligible]
      required_assets = [:front, :back, :icon]
    end

    missing_required_assets = {}
    required_assets.each do |asset_kind|
      path = metadata[:assets][asset_kind]
      if blank?(path) || !asset_available?(path)
        missing_required_assets[asset_kind] = true
        message = "#{internal_id} is missing its required #{asset_kind} asset."
        if strict_asset_requirements?(metadata)
          @errors << message
        else
          @warnings << message
        end
      end
    end

    metadata[:assets].each_pair do |asset_kind, asset_path|
      next if missing_required_assets[asset_kind]
      next if asset_available?(asset_path)
      @warnings << "#{internal_id} references missing optional #{asset_kind} asset #{asset_path}."
    end
  end

  def self.strict_asset_requirements?(metadata)
    return true if !metadata.is_a?(Hash)
    return false if !blank?(metadata[:source_pack])
    return false if !blank?(metadata[:source_url])
    return false if !blank?(metadata[:import_insert_status])
    return false if !blank?(metadata[:framework_species_key])
    true
  end

  def self.validate_encounter_hooks!
    @encounter_hooks.each do |hook|
      next if !hook[:enabled]
      @errors << "Encounter hook for map #{hook[:map_id]} is missing a valid encounter type." if hook[:encounter_type].nil?
      @errors << "Encounter hook for map #{hook[:map_id]} references missing species #{hook[:species]}." if !species_reference_valid?(hook[:species])
    end
  end

  def self.validate_trainer_hooks!
    @trainer_hooks.each do |hook|
      next if !hook[:enabled]
      @errors << "Trainer hook #{hook.inspect} is missing a trainer type." if hook[:trainer_type].nil?
      @errors << "Trainer hook for #{hook[:trainer_type]} references missing species #{hook[:species]}." if !species_reference_valid?(hook[:species])
      hook[:moves].each { |move| validate_enum_reference!("trainer hook #{hook[:trainer_type]}", "move", move, GameData::Move) }
      validate_enum_reference!("trainer hook #{hook[:trainer_type]}", "item", hook[:item], GameData::Item) if hook[:item]
      validate_enum_reference!("trainer hook #{hook[:trainer_type]}", "ability", hook[:ability], GameData::Ability) if hook[:ability]
      validate_enum_reference!("trainer hook #{hook[:trainer_type]}", "nature", hook[:nature], GameData::Nature) if hook[:nature]
    end
  end

  def self.validate_enum_reference!(owner, label, value, game_data_class)
    return if value.nil?
    return if game_data_class.exists?(value)
    @errors << "#{owner} references missing #{label} #{value}."
  rescue
    @errors << "#{owner} references missing #{label} #{value}."
  end

  def self.fusion_species_reference_components(species)
    species_symbol = species.is_a?(String) ? species.to_sym : species
    return nil if !species_symbol.is_a?(Symbol)
    match = species_symbol.to_s.match(/\AB(\d+)H(\d+)\z/)
    return nil if match.nil?
    return [match[1].to_i, match[2].to_i]
  end

  def self.fusion_species_reference_valid?(species)
    components = fusion_species_reference_components(species)
    return false if components.nil?
    return false if !defined?(GameData::Species::DATA)

    body_id, head_id = components
    return false if body_id <= 0 || head_id <= 0
    return false if !GameData::Species::DATA.has_key?(body_id)
    return false if !GameData::Species::DATA.has_key?(head_id)
    return true
  end

  def self.species_reference_valid?(species, allow_fusion_symbol = false)
    return false if species.nil?
    species = species.to_sym if species.is_a?(String)
    return true if @species_definitions.any? { |definition| definition[:game_data][:id] == species }
    return true if allow_fusion_symbol && fusion_species_reference_valid?(species)
    if defined?(GameData::Species::DATA)
      return true if GameData::Species::DATA.has_key?(species)
      return true if species.is_a?(Integer) && GameData::Species::DATA.has_key?(species)
    end
    return false
  end

  def self.report_validation_results
    @warnings.each { |warning| log("Warning: #{warning}") } if debug?
    if !@errors.empty?
      log("Critical validation failed.")
      @errors.each { |error_message| log("Error: #{error_message}") }
    else
      log("Framework standard species range: #{FRAMEWORK_FIRST_ID}..#{MISSING_SPECIES_NUM - 1} (placeholder #{MISSING_SPECIES_NUM}, NB_POKEMON=#{Settings::NB_POKEMON}, triple threshold=#{Settings::ZAPMOLCUNO_NB}).") if debug?
      log("Validated #{@species_definitions.length} species definitions, #{@starter_sets.length} starter set(s), #{@encounter_hooks.length} encounter hook(s), and #{@trainer_hooks.length} trainer hook(s).") if debug?
    end
  end

  def self.species_definition_pack_key(definition)
    metadata = definition[:metadata] if definition.is_a?(Hash)
    key = metadata[:source_pack] if metadata.is_a?(Hash)
    key = metadata[:export_pack_name] if (key.nil? || key.to_s.empty?) && metadata.is_a?(Hash)
    key = metadata[:framework_species_key] if (key.nil? || key.to_s.empty?) && metadata.is_a?(Hash)
    key = "core"
    return key.to_s.empty? ? "core" : key.to_s
  rescue
    return "core"
  end

  def self.species_validation_errors_for(definitions)
    previous_definitions = @species_definitions
    previous_errors = @errors
    previous_warnings = @warnings
    @species_definitions = definitions
    @errors = []
    @warnings = []
    validate_species_ids!
    validate_species_records!
    return @errors.dup
  ensure
    @species_definitions = previous_definitions
    @errors = previous_errors
    @warnings = previous_warnings
  end

  def self.record_disabled_species_pack!(pack_key, errors)
    @disabled_species_packs ||= {}
    @disabled_species_packs[pack_key.to_s] = Array(errors).map(&:to_s)
    @warnings << "Disabled custom species pack #{pack_key}: #{Array(errors).first}"
    if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:record_dormant_reference)
      TravelExpansionFramework.record_dormant_reference({
        "type"      => "disabled_species_pack",
        "pack"      => pack_key.to_s,
        "errors"    => Array(errors).map(&:to_s)[0, 8],
        "timestamp" => TravelExpansionFramework.timestamp_string
      })
    end
  rescue
  end

  def self.isolate_invalid_species_packs!
    return if @species_definitions.empty?
    grouped = {}
    @species_definitions.each do |definition|
      grouped[species_definition_pack_key(definition)] ||= []
      grouped[species_definition_pack_key(definition)] << definition
    end
    accepted = grouped.delete("core") || []
    grouped.keys.sort.each do |pack_key|
      candidate = accepted + grouped[pack_key]
      errors = species_validation_errors_for(candidate)
      if errors.empty?
        accepted.concat(grouped[pack_key])
      else
        record_disabled_species_pack!(pack_key, errors)
      end
    end
    @species_definitions = accepted
  rescue => e
    @warnings << "Pack isolation failed: #{e.class}: #{e.message}"
  end

  def self.ensure_directory!(absolute_path)
    return if blank?(absolute_path)
    return if Dir.exist?(absolute_path)
    parent = File.dirname(absolute_path)
    ensure_directory!(parent) if parent && parent != absolute_path && !Dir.exist?(parent)
    Dir.mkdir(absolute_path) if !Dir.exist?(absolute_path)
  rescue
  end

  def self.copy_asset_if_needed(source_path, destination_path)
    return false if blank?(source_path) || blank?(destination_path)
    return false if !File.exist?(source_path)
    ensure_directory!(File.dirname(destination_path))

    if File.exist?(destination_path)
      begin
        return false if File.size(source_path) == File.size(destination_path) &&
                        File.binread(source_path) == File.binread(destination_path)
      rescue
      end
    end

    File.open(source_path, "rb") do |input|
      File.open(destination_path, "wb") do |output|
        IO.copy_stream(input, output)
      end
    end
    return true
  rescue => e
    @warnings << "Failed to install asset #{destination_path}: #{e.message}"
    return false
  end

  def self.standard_icon_sheet_dimensions?(animated_bitmap)
    return false if animated_bitmap.nil?
    return animated_bitmap.width == 128 && animated_bitmap.height == 64
  end

  def self.blit_standard_icon_frame(destination_bitmap, source_bitmap, source_rect, frame_index, y_offset = 0)
    return if destination_bitmap.nil? || source_bitmap.nil? || source_rect.nil?

    max_width = 40.0
    max_height = 40.0
    scale = [max_width / source_rect.width.to_f, max_height / source_rect.height.to_f, 1.0].min
    scale = 1.0 if scale <= 0
    dest_width = [(source_rect.width * scale).round, 1].max
    dest_height = [(source_rect.height * scale).round, 1].max

    frame_origin_x = frame_index * 64
    dest_x = frame_origin_x + ((64 - dest_width) / 2)
    dest_y = 10 + y_offset + ((40 - dest_height) / 2)
    destination_bitmap.stretch_blt(Rect.new(dest_x, dest_y, dest_width, dest_height), source_bitmap, source_rect)
  end

  def self.build_standard_icon_bitmap(source_path)
    return nil if blank?(source_path) || !File.exist?(source_path)

    source_bitmap = nil
    source_bitmap = AnimatedBitmap.new(source_path).recognizeDims rescue AnimatedBitmap.new(source_path)
    return source_bitmap if standard_icon_sheet_dimensions?(source_bitmap)

    source_frame_size = if source_bitmap.width >= source_bitmap.height * 2 && source_bitmap.height > 0
                          source_bitmap.height
                        else
                          [source_bitmap.width, source_bitmap.height].min
                        end
    source_rect = Rect.new(0, 0, source_frame_size, source_frame_size)

    standardized_bitmap = Bitmap.new(128, 64)
    blit_standard_icon_frame(standardized_bitmap, source_bitmap.bitmap, source_rect, 0, 0)
    blit_standard_icon_frame(standardized_bitmap, source_bitmap.bitmap, source_rect, 1, 2)
    source_bitmap.dispose
    return AnimatedBitmap.from_bitmap(standardized_bitmap)
  rescue => e
    @warnings << "Failed to format custom icon #{source_path}: #{e.message}"
    source_bitmap.dispose if source_bitmap && !source_bitmap.disposed?
    return nil
  end

  def self.front_strip_bitmap?(animated_bitmap)
    return false if animated_bitmap.nil?
    width = animated_bitmap.width
    height = animated_bitmap.height
    return false if width.nil? || height.nil? || width <= 0 || height <= 0
    return false if width < height * 4
    return false if (width % height) != 0
    return true
  rescue
    return false
  end

  def self.build_standard_front_battler_bitmap(source_path)
    return nil if blank?(source_path) || !File.exist?(source_path)

    source_bitmap = nil
    source_bitmap = AnimatedBitmap.new(source_path).recognizeDims rescue AnimatedBitmap.new(source_path)
    return nil if !front_strip_bitmap?(source_bitmap)

    frame_size = source_bitmap.height
    scale = frame_size <= 96 ? 2 : 1
    destination_size = [frame_size * scale, frame_size].max
    source_rect = Rect.new(0, 0, frame_size, frame_size)

    standardized_bitmap = Bitmap.new(destination_size, destination_size)
    standardized_bitmap.stretch_blt(Rect.new(0, 0, destination_size, destination_size), source_bitmap.bitmap, source_rect)
    source_bitmap.dispose
    return AnimatedBitmap.from_bitmap(standardized_bitmap)
  rescue => e
    @warnings << "Failed to format custom front battler #{source_path}: #{e.message}"
    source_bitmap.dispose if source_bitmap && !source_bitmap.disposed?
    return nil
  end

  def self.write_bitmap_png_if_needed(animated_bitmap, destination_path)
    return false if animated_bitmap.nil? || blank?(destination_path)
    ensure_directory!(File.dirname(destination_path))
    temporary_path = nil
    temporary_path = destination_path + ".csf_tmp"
    animated_bitmap.bitmap_to_png(temporary_path)

    if File.exist?(destination_path)
      begin
        if File.size(temporary_path) == File.size(destination_path) &&
           File.binread(temporary_path) == File.binread(destination_path)
          File.delete(temporary_path) rescue nil
          return false
        end
      rescue
      end
      File.delete(destination_path) rescue nil
    end

    File.rename(temporary_path, destination_path)
    return true
  rescue => e
    @warnings << "Failed to install asset #{destination_path}: #{e.message}"
    return false
  ensure
    File.delete(temporary_path) if temporary_path && File.exist?(temporary_path)
  end

  def self.install_icon_asset_if_needed(source_path, destination_path)
    icon_bitmap = nil
    icon_bitmap = build_standard_icon_bitmap(source_path)
    return false if icon_bitmap.nil?
    return write_bitmap_png_if_needed(icon_bitmap, destination_path)
  ensure
    icon_bitmap.dispose if icon_bitmap && !icon_bitmap.disposed?
  end

  def self.install_front_battler_asset_if_needed(source_path, destination_path)
    front_bitmap = nil
    front_bitmap = build_standard_front_battler_bitmap(source_path)
    return copy_asset_if_needed(source_path, destination_path) if front_bitmap.nil?
    return write_bitmap_png_if_needed(front_bitmap, destination_path)
  ensure
    front_bitmap.dispose if front_bitmap && !front_bitmap.disposed?
  end

  def self.append_png_extension(path)
    return nil if blank?(path)
    return path if File.extname(path.to_s).downcase == ".png"
    return path.to_s + ".png"
  end

  def self.root_graphic_path(relative_path)
    return nil if blank?(relative_path)
    normalized = relative_path.to_s.tr("/", File::SEPARATOR)
    normalized = append_png_extension(normalized)
    return File.expand_path(normalized, GAME_ROOT)
  end

  def self.runtime_art_source(definition, kind)
    metadata = definition[:metadata]
    assets = metadata[:assets] || {}
    source = asset_path(kind, definition[:game_data][:id])
    return source if source && File.exist?(source)

    fallback_species = metadata[:fallback_species]
    return nil if fallback_species.nil?

    fallback_path = case kind
                    when :front
                      GameData::Species.front_sprite_filename(fallback_species) rescue nil
                    when :back
                      GameData::Species.back_sprite_filename(fallback_species) rescue nil
                    when :icon
                      GameData::Species.icon_filename(fallback_species) rescue nil
                    else
                      nil
                    end
    return pbResolveBitmap(fallback_path) if fallback_path && pbResolveBitmap(fallback_path)

    direct_path = assets[kind]
    return mod_asset_source_path(direct_path) if direct_path
    return nil
  end

  def self.runtime_art_targets(definition, kind)
    game_data = definition[:game_data]
    metadata = definition[:metadata]
    species_id = game_data[:id]
    dex_number = game_data[:id_number]
    targets = []

    case kind
    when :front
      direct_path = metadata[:assets][:front]
      targets << root_graphic_path(direct_path) if direct_path
      targets << root_graphic_path("Graphics/Pokemon/Front/#{species_id}")
      targets << root_graphic_path("Graphics/Battlers/#{dex_number}/#{dex_number}")
      targets << root_graphic_path("Graphics/CustomBattlers/indexed/#{dex_number}/#{dex_number}")
      targets << root_graphic_path("Graphics/EBDX/Battlers/Front/#{dex_number}")
    when :back
      direct_path = metadata[:assets][:back]
      targets << root_graphic_path(direct_path) if direct_path
      targets << root_graphic_path("Graphics/Pokemon/Back/#{species_id}")
      targets << root_graphic_path("Graphics/EBDX/Battlers/Back/#{dex_number}")
    when :icon
      direct_path = metadata[:assets][:icon]
      targets << root_graphic_path(direct_path) if direct_path
      targets << root_graphic_path("Graphics/Pokemon/Icons/#{species_id}")
      targets << root_graphic_path("Graphics/Icons/icon#{dex_number}")
      targets << root_graphic_path("Graphics/Battlers/#{dex_number}/#{dex_number}_i")
      targets << root_graphic_path("Graphics/CustomBattlers/indexed/#{dex_number}/#{dex_number}_i")
    end

    return targets.compact.uniq
  end

  def self.install_runtime_assets!
    installed_count = 0
    @species_definitions.each do |definition|
      [:front, :back, :icon].each do |kind|
        source_path = runtime_art_source(definition, kind)
        next if blank?(source_path)
        runtime_art_targets(definition, kind).each do |destination_path|
          installed = case kind
                      when :icon
                        install_icon_asset_if_needed(source_path, destination_path)
                      when :front
                        install_front_battler_asset_if_needed(source_path, destination_path)
                      else
                        copy_asset_if_needed(source_path, destination_path)
                      end
          installed_count += 1 if installed
        end
      end
    end
    log("Installed or refreshed #{installed_count} runtime sprite asset file(s).") if debug?
  end

  def self.bootstrap!
    @boot_completed = false
    load_runtime_data!
    isolate_invalid_species_packs!
    validate_runtime_data!
    if @errors.empty?
      register_framework_species!
      install_runtime_assets!
      log("Registered #{@species_definitions.length} framework species.") if debug?
    else
      log("Framework boot aborted. The base game will continue without custom species support.")
    end
    @boot_completed = true
  rescue => e
    @errors << e.message
    log("Unhandled bootstrap exception: #{e.message}")
    log(e.backtrace[0, 5].join(" | ")) if e.backtrace && debug?
    @boot_completed = true
  end
end

module GameData
  class Species
    class << self
      alias csf_original_species_load_for_framework load unless method_defined?(:csf_original_species_load_for_framework)

      def load
        csf_original_species_load_for_framework
        if defined?(CustomSpeciesFramework)
          CustomSpeciesFramework.bootstrap!
          CustomSpeciesFramework.patch_starter_selection_common_event! if CustomSpeciesFramework.active?
          if CustomSpeciesFramework.respond_to?(:export_creator_catalog!) &&
             CustomSpeciesFramework.respond_to?(:export_creator_catalog_on_boot?) &&
             CustomSpeciesFramework.export_creator_catalog_on_boot?
            begin
              CustomSpeciesFramework.export_creator_catalog!
            rescue Exception => e
              if CustomSpeciesFramework.respond_to?(:log)
                CustomSpeciesFramework.log("Creator catalog export was skipped during boot: #{e.class}: #{e.message}")
              end
            end
          end
        end
      end
    end
  end
end
