module TravelExpansionFramework
  TRAINER_HOST_PLACEHOLDER_TYPE = :YOUNGSTER
  TRAINER_ASSET_EXTENSIONS      = [".png", ".gif", ".jpg", ".jpeg", ".bmp"].freeze
  IMPORTED_TRAINER_NATIVE_BATTLE_SPRITES = false

  module ImportedTrainerTypeGameDataBehavior
    def name
      return @real_name if !@real_name.to_s.empty?
      return super
    rescue
      return "Trainer"
    end

    def travel_expansion_imported_trainer_type_data
      return @travel_expansion_imported_trainer_type_data || {}
    end
  end

  module ImportedTrainerBehavior
    def travel_expansion_external_trainer?
      return true
    end

    def travel_expansion_external_trainer_type
      return @travel_expansion_external_trainer_type
    end

    def travel_expansion_external_trainer_type_data
      return @travel_expansion_external_trainer_type_data || {}
    end

    def travel_expansion_expansion_id
      return @travel_expansion_expansion_id.to_s
    rescue
      return nil
    end

    def trainer_type_name
      data = travel_expansion_external_trainer_type_data
      title = data[:title].to_s
      return title if !title.empty?
      return super
    rescue
      return "Trainer"
    end

    def base_money
      data = travel_expansion_external_trainer_type_data
      value = TravelExpansionFramework.integer(data[:base_money], -1)
      return value if value >= 0
      return super
    rescue
      return 30
    end

    def skill_level
      data = travel_expansion_external_trainer_type_data
      value = TravelExpansionFramework.integer(data[:skill_level], -1)
      return value if value >= 0
      return super
    rescue
      return 30
    end

    def skill_code
      data = travel_expansion_external_trainer_type_data
      code = data[:skill_code]
      return code if !code.nil?
      return super
    rescue
      return nil
    end

    def gender
      data = travel_expansion_external_trainer_type_data
      value = TravelExpansionFramework.integer(data[:gender], 2)
      return value if [0, 1, 2].include?(value)
      return super
    rescue
      return 2
    end

    def male?
      return gender == 0
    end

    def female?
      return gender == 1
    end
  end

  class ImportedTrainerDataProxy
    def initialize(expansion_id, trainer_type, trainer_name, trainer_version)
      @expansion_id    = expansion_id.to_s
      @trainer_type    = trainer_type
      @trainer_name    = trainer_name.to_s
      @trainer_version = TravelExpansionFramework.integer(trainer_version, 0)
    end

    def trainer_type
      return @trainer_type
    end

    def real_name
      return @trainer_name
    end

    def name
      return @trainer_name
    end

    def version
      return @trainer_version
    end

    def id
      return [@trainer_type, @trainer_name, @trainer_version]
    end

    def id_number
      type_data = type_data_hash
      return TravelExpansionFramework.integer(type_data[:id_number], 0)
    end

    def items
      record = record_hash
      return [] if !record.is_a?(Hash)
      return Array(record[:items]).clone
    end

    def pokemon
      record = record_hash
      return [] if !record.is_a?(Hash)
      return Array(record[:pokemon]).clone
    end

    def lose_text
      record = record_hash
      return "..." if !record.is_a?(Hash)
      text = record[:lose_text].to_s
      text = TravelExpansionFramework.localized_external_trainer_text(@expansion_id, text) if !text.empty?
      return text.empty? ? "..." : text
    end

    def to_trainer
      return TravelExpansionFramework.load_external_trainer(@expansion_id, @trainer_type, @trainer_name, @trainer_version)
    end

    private

    def record_hash
      catalog = TravelExpansionFramework.external_trainer_catalog(@expansion_id)
      return nil if !catalog.is_a?(Hash)
      return TravelExpansionFramework.find_external_trainer_record(catalog, @trainer_type, @trainer_name, @trainer_version)
    rescue
      return nil
    end

    def type_data_hash
      record = record_hash
      return {} if !record.is_a?(Hash)
      catalog = TravelExpansionFramework.external_trainer_catalog(@expansion_id)
      return {} if !catalog.is_a?(Hash) || !catalog[:types].is_a?(Hash)
      return catalog[:types][record[:trainer_type]] || {}
    rescue
      return {}
    end
  end

  module_function

  def imported_trainer_native_battle_sprites_enabled?
    return IMPORTED_TRAINER_NATIVE_BATTLE_SPRITES == true
  end

  def imported_trainer_type_runtime_index
    @imported_trainer_type_runtime_index ||= {}
    return @imported_trainer_type_runtime_index
  end

  def imported_trainer_type_store(expansion_id)
    expansion = expansion_id.to_s
    return {} if expansion.empty?
    cache = runtime_data_cache[expansion] ||= {}
    cache[:imported_trainer_types] ||= {}
    return cache[:imported_trainer_types]
  end

  def imported_trainer_runtime_id(expansion_id, type_id)
    expansion = expansion_id.to_s.upcase.gsub(/[^A-Z0-9]+/, "_")
    expansion = "GENERIC" if expansion.empty?
    identifier = external_identifier(type_id)
    name = identifier.nil? ? "TRAINER" : identifier.to_s
    name = name.upcase.gsub(/[^A-Z0-9]+/, "_")
    name = "TRAINER" if name.empty?
    return "TEF_#{expansion}_#{name}".to_sym
  rescue
    return :TEF_GENERIC_TRAINER
  end

  def build_imported_trainer_game_data(data)
    return nil if !data.is_a?(Hash)
    game_data = GameData::TrainerType.new(
      :id          => data[:runtime_id],
      :id_number   => integer(data[:id_number], 0),
      :name        => normalize_string_or_nil(data[:title]) || data[:id].to_s,
      :base_money  => integer(data[:base_money], 30),
      :battle_BGM  => normalize_string_or_nil(data[:battle_BGM]),
      :victory_ME  => normalize_string_or_nil(data[:victory_ME]),
      :intro_ME    => normalize_string_or_nil(data[:intro_BGM] || data[:intro_ME]),
      :gender      => integer(data[:gender], 2),
      :skill_level => integer(data[:skill_level], 30),
      :skill_code  => data[:skill_code]
    )
    game_data.instance_variable_set(:@travel_expansion_imported_trainer_type_data, data)
    game_data.extend(ImportedTrainerTypeGameDataBehavior)
    return game_data
  rescue => e
    log("Failed to build imported trainer runtime type #{data[:runtime_id]}: #{e.class}: #{e.message}")
    return nil
  end

  def register_imported_trainer_type(expansion_id, data)
    return data if !data.is_a?(Hash)
    normalized = data.dup
    normalized[:expansion_id] = expansion_id.to_s
    normalized[:runtime_id] = imported_trainer_runtime_id(expansion_id, normalized[:id]) if normalized[:runtime_id].nil?
    normalized[:game_data] = build_imported_trainer_game_data(normalized) if !normalized[:game_data].is_a?(GameData::TrainerType)
    store = imported_trainer_type_store(expansion_id)
    store[normalized[:id]] = normalized if !normalized[:id].nil?
    store[normalized[:runtime_id]] = normalized if !normalized[:runtime_id].nil?
    store[normalized[:id_number]] = normalized if integer(normalized[:id_number], 0) > 0
    imported_trainer_type_runtime_index[normalized[:id]] = normalized if !normalized[:id].nil?
    imported_trainer_type_runtime_index[normalized[:runtime_id]] = normalized if !normalized[:runtime_id].nil?
    imported_trainer_type_runtime_index[normalized[:id_number]] = normalized if integer(normalized[:id_number], 0) > 0
    return normalized
  end

  def imported_trainer_runtime_identifier?(other)
    identifier = other
    identifier = other.id if defined?(GameData::TrainerType) && other.is_a?(GameData::TrainerType)
    text = identifier.to_s.strip.upcase
    return text.start_with?("TEF_")
  rescue
    return false
  end

  def imported_trainer_type_data(other, preferred_expansion_id = nil)
    if defined?(GameData::TrainerType) && other.is_a?(GameData::TrainerType)
      data = other.instance_variable_get(:@travel_expansion_imported_trainer_type_data) rescue nil
      return data if data.is_a?(Hash)
    end
    identifier = external_identifier(other)
    return nil if identifier.nil?
    active_ids = active_trainer_lookup_expansion_ids(preferred_expansion_id)
    active_ids.each do |expansion_id|
      external_trainer_catalog(expansion_id)
      store = imported_trainer_type_store(expansion_id)
      data = store[identifier] if store.is_a?(Hash)
      return data if data
    end
    if imported_trainer_runtime_identifier?(identifier)
      data = imported_trainer_type_runtime_index[identifier]
      return data if data
    end
    return nil
  rescue
    return nil
  end

  def imported_trainer_type_known?(other, preferred_expansion_id = nil)
    return !imported_trainer_type_data(other, preferred_expansion_id).nil?
  rescue
    return false
  end

  def imported_trainer_game_data(other, preferred_expansion_id = nil)
    data = imported_trainer_type_data(other, preferred_expansion_id)
    return nil if !data.is_a?(Hash)
    return data[:game_data] if data[:game_data].is_a?(GameData::TrainerType)
    registered = register_imported_trainer_type(data[:expansion_id], data)
    return registered[:game_data]
  rescue
    return nil
  end

  def external_trainer_catalog(expansion_id)
    expansion = expansion_id.to_s
    return nil if expansion.empty?
    cache = runtime_data_cache[expansion] ||= {}
    return cache[:trainer_catalog] if cache.has_key?(:trainer_catalog)
    cache[:trainer_catalog] = load_external_trainer_catalog(expansion)
    return cache[:trainer_catalog]
  end

  def clear_external_trainer_catalog!(expansion_id = nil)
    if expansion_id
      cache = runtime_data_cache[expansion_id.to_s]
      if cache.is_a?(Hash) && cache[:imported_trainer_types].is_a?(Hash)
        cache[:imported_trainer_types].each_value do |data|
          next if !data.is_a?(Hash)
          imported_trainer_type_runtime_index.delete(data[:id]) if data[:id]
          imported_trainer_type_runtime_index.delete(data[:runtime_id]) if data[:runtime_id]
          imported_trainer_type_runtime_index.delete(integer(data[:id_number], 0)) if integer(data[:id_number], 0) > 0
        end
      end
      cache.delete(:trainer_catalog) if cache.is_a?(Hash)
      cache.delete(:imported_trainer_types) if cache.is_a?(Hash)
      return
    end
    runtime_data_cache.each_value do |entry|
      next if !entry.is_a?(Hash)
      entry.delete(:trainer_catalog)
      entry.delete(:imported_trainer_types)
    end
    imported_trainer_type_runtime_index.clear
  end

  def active_trainer_lookup_expansion_id
    expansion = nil
    context = current_runtime_context if respond_to?(:current_runtime_context)
    if context.is_a?(Hash)
      context_expansion = context[:expansion_id].to_s
      context_map_id = integer(context[:map_id], 0)
      if !context_expansion.empty?
        if context_map_id > 0
          map_expansion = current_map_expansion_id(context_map_id) if respond_to?(:current_map_expansion_id)
          expansion = context_expansion if map_expansion.to_s == context_expansion
        elsif defined?($game_map) && $game_map && $game_map.respond_to?(:map_id)
          map_expansion = current_map_expansion_id($game_map.map_id) if respond_to?(:current_map_expansion_id)
          expansion = context_expansion if map_expansion.to_s == context_expansion
        end
      end
    end
    expansion = current_map_expansion_id if expansion.to_s.empty? && respond_to?(:current_map_expansion_id)
    expansion = expansion.to_s
    return nil if expansion.empty?
    return expansion
  end

  def active_trainer_lookup_expansion_ids(preferred_expansion_id = nil)
    ids = []
    direct_candidates = []
    direct_candidates << preferred_expansion_id
    direct_candidates << active_trainer_lookup_expansion_id
    if defined?($game_map) && $game_map && $game_map.respond_to?(:map_id) && respond_to?(:current_map_expansion_id)
      direct_candidates << current_map_expansion_id($game_map.map_id)
    end
    direct_candidates.each do |candidate|
      expansion = candidate.to_s
      next if expansion.empty? || ids.include?(expansion)
      ids << expansion
    end
    return ids
  rescue
    fallback = preferred_expansion_id.to_s
    return fallback.empty? ? [] : [fallback]
  end

  def localized_external_trainer_text(expansion_id, text, map_id = nil)
    return nil if text.nil?
    value = text.to_s
    return value if value.empty?
    if respond_to?(:anil_expansion_id?) && anil_expansion_id?(expansion_id) && respond_to?(:anil_translate_text)
      return anil_translate_text(value, map_id || ($game_map.map_id rescue nil))
    end
    if expansion_id.to_s == "xenoverse" && respond_to?(:xenoverse_battle_display_text)
      return xenoverse_battle_display_text(value, map_id || ($game_map.map_id rescue nil))
    end
    return value
  rescue => e
    log("Imported trainer text localization failed for #{expansion_id}: #{e.class}: #{e.message}") if respond_to?(:log)
    return text.to_s
  end

  def external_trainer_expansion_id(trainer)
    return nil if trainer.nil?
    if trainer.respond_to?(:travel_expansion_expansion_id)
      expansion = trainer.travel_expansion_expansion_id
      return expansion.to_s if !expansion.to_s.empty?
    end
    expansion = trainer.instance_variable_get(:@travel_expansion_expansion_id) if trainer.instance_variable_defined?(:@travel_expansion_expansion_id)
    return expansion.to_s if !expansion.to_s.empty?
    return nil
  rescue
    return nil
  end

  def external_trainer_record_proxy_for_expansion(expansion_id, tr_type, tr_name, tr_version = 0)
    catalog = external_trainer_catalog(expansion_id)
    return nil if !catalog.is_a?(Hash)
    record = find_external_trainer_record(catalog, tr_type, tr_name, tr_version)
    return nil if !record
    return ImportedTrainerDataProxy.new(expansion_id, tr_type, tr_name, tr_version)
  rescue => e
    log("Trainer compatibility record proxy failed for #{expansion_id}/#{tr_type}/#{tr_name}/#{tr_version}: #{e.class}: #{e.message}")
    return nil
  end

  def external_trainer_record_proxy(tr_type, tr_name, tr_version = 0, preferred_expansion_id = nil)
    active_trainer_lookup_expansion_ids(preferred_expansion_id).each do |expansion_id|
      proxy = external_trainer_record_proxy_for_expansion(expansion_id, tr_type, tr_name, tr_version)
      return proxy if proxy
    end
    return nil
  end

  def load_external_trainer(expansion_id, tr_type, tr_name, tr_version = 0)
    catalog = external_trainer_catalog(expansion_id)
    return nil if !catalog.is_a?(Hash)
    record = find_external_trainer_record(catalog, tr_type, tr_name, tr_version)
    return nil if !record
    trainer = build_external_trainer(expansion_id, catalog, record)
    return nil if !trainer
    begin
      NPT::Toggle.sanitize_trainer_party!(trainer) if defined?(NPT::Toggle) && NPT::Toggle.respond_to?(:sanitize_trainer_party!)
    rescue => e
      log("Trainer compatibility NPT sanitize failed for #{expansion_id}/#{tr_type}/#{tr_name}/#{tr_version}: #{e.message}")
    end
    return trainer
  rescue => e
    log("Trainer compatibility load failed for #{expansion_id}/#{tr_type}/#{tr_name}/#{tr_version}: #{e.class}: #{e.message}")
    return nil
  end

  def external_project_root(expansion_id)
    info = external_projects[expansion_id.to_s]
    return File.expand_path(info[:root]) if info.is_a?(Hash) && !info[:root].to_s.empty?
    manifest = manifest_for(expansion_id)
    return File.expand_path(manifest[:source_root]) if manifest.is_a?(Hash) && !manifest[:source_root].to_s.empty?
    return nil
  rescue
    return nil
  end

  def load_external_trainer_catalog(expansion_id)
    root = external_project_root(expansion_id)
    return nil if root.nil? || !File.directory?(root)
    if expansion_id.to_s == "xenoverse"
      xenoverse_paths = xenoverse_pbs_trainer_paths(root)
      return load_xenoverse_pbs_trainer_catalog(expansion_id, root, xenoverse_paths) if xenoverse_paths
    end
    if expansion_id.to_s == "pokemon_uranium"
      uranium_paths = uranium_dat_trainer_paths(expansion_id, root)
      return load_uranium_dat_trainer_catalog(expansion_id, root, uranium_paths) if uranium_paths
    end
    reborn_paths = reborn_text_export_paths(root)
    return load_reborn_text_export_catalog(expansion_id, root, reborn_paths) if reborn_paths
    dat_paths = generic_dat_trainer_paths(expansion_id, root)
    return load_generic_dat_trainer_catalog(expansion_id, root, dat_paths) if dat_paths
    generic_paths = generic_pbs_trainer_paths(root)
    return load_generic_pbs_trainer_catalog(expansion_id, root, generic_paths) if generic_paths
    return nil
  end

  def generic_dat_trainer_paths(expansion_id, root)
    data_root = external_project_data_root(expansion_id)
    data_root = File.join(root.to_s, "Data") if data_root.to_s.empty?
    return nil if data_root.to_s.empty? || !File.directory?(data_root)
    type_candidates = [
      File.join(data_root, "trainer_types.dat"),
      File.join(data_root, "trainertypes.dat")
    ]
    team_candidates = [
      File.join(data_root, "trainers.dat")
    ]
    type_path = type_candidates.find { |path| File.file?(path) }
    team_path = team_candidates.find { |path| File.file?(path) }
    return nil if !type_path || !team_path
    return {
      :data_root => data_root,
      :type_path => type_path,
      :team_path => team_path
    }
  rescue
    return nil
  end

  def load_generic_dat_trainer_data(path)
    return nil if path.to_s.empty? || !File.file?(path)
    return Marshal.load(File.binread(path))
  rescue => e
    log("Failed to load generic trainer data #{path}: #{e.class}: #{e.message}")
    return nil
  end

  def load_generic_dat_trainer_catalog(expansion_id, root, paths)
    raw_types = load_generic_dat_trainer_data(paths[:type_path])
    raw_teams = load_generic_dat_trainer_data(paths[:team_path])
    return nil if raw_types.nil? || raw_teams.nil?

    type_entries = raw_types.is_a?(Hash) ? raw_types.values : Array(raw_types)
    team_entries = raw_teams.is_a?(Hash) ? raw_teams.values : Array(raw_teams)
    type_map = {}
    id_map = {}
    type_entries.each do |entry|
      normalized = if entry.is_a?(Array)
                     normalize_uranium_trainer_type(expansion_id, root, entry)
                   else
                     normalize_generic_dat_trainer_type(expansion_id, root, entry)
                   end
      next if !normalized
      normalized = register_imported_trainer_type(expansion_id, normalized)
      type_map[normalized[:id]] = normalized
      id_map[normalized[:id_number]] = normalized[:id] if integer(normalized[:id_number], 0) > 0
    end

    team_map = {}
    team_entries.each do |entry|
      normalized = if entry.is_a?(Array)
                     normalize_uranium_trainer_record(entry, id_map)
                   else
                     normalize_generic_dat_trainer_record(entry)
                   end
      next if !normalized
      key = [normalized[:trainer_type], normalized[:name], normalized[:version]]
      team_map[key] = normalized
    end

    log("Loaded generic compiled trainer catalog for #{expansion_id} from #{paths[:data_root]} (#{type_map.length} trainer types, #{team_map.length} teams)")
    return {
      :adapter => :generic_dat,
      :root    => root,
      :types   => type_map,
      :id_map  => id_map,
      :teams   => team_map
    }
  rescue => e
    log("Failed to load generic compiled trainer catalog for #{expansion_id} from #{paths[:data_root]}: #{e.class}: #{e.message}")
    return nil
  end

  def generic_dat_ivar(object, *names)
    return nil if object.nil?
    names.each do |name|
      ivar = name.to_s.start_with?("@") ? name.to_s : "@#{name}"
      return object.instance_variable_get(ivar) if object.instance_variable_defined?(ivar)
    end
    return nil
  rescue
    return nil
  end

  def normalize_generic_dat_trainer_type(expansion_id, root, entry)
    return nil if !entry
    symbol_id = external_identifier(generic_dat_ivar(entry, :id, :trainer_type))
    return nil if symbol_id.nil?
    title = normalize_string_or_nil(generic_dat_ivar(entry, :real_name, :name)) || symbol_id.to_s
    pbs_suffix = normalize_string_or_nil(generic_dat_ivar(entry, :pbs_file_suffix))
    sprite_keys = [symbol_id, pbs_suffix, title].compact
    return {
      :id             => symbol_id,
      :runtime_id     => imported_trainer_runtime_id(expansion_id, symbol_id),
      :id_number      => integer(generic_dat_ivar(entry, :id_number), 0),
      :title          => title,
      :skill_level    => integer(generic_dat_ivar(entry, :skill_level), 30),
      :base_money     => integer(generic_dat_ivar(entry, :base_money), 30),
      :battle_BGM     => normalize_string_or_nil(generic_dat_ivar(entry, :battle_BGM, :battle_bgm)),
      :victory_ME     => normalize_string_or_nil(generic_dat_ivar(entry, :victory_ME, :victory_BGM, :victory_bgm)),
      :intro_BGM      => normalize_string_or_nil(generic_dat_ivar(entry, :intro_BGM, :intro_bgm)),
      :sprite         => pbs_suffix || symbol_id.to_s,
      :front_sprite   => first_existing_logical_asset(root, sprite_keys.flat_map { |key|
        [
          asset_basename_path("Graphics/Trainers", key),
          asset_basename_path("Graphics/Trainers", key.to_s.upcase),
          asset_basename_path("Graphics/Characters", key),
          asset_basename_path("Graphics/Characters", key.to_s.upcase)
        ]
      }),
      :back_sprite    => first_existing_logical_asset(root, sprite_keys.flat_map { |key|
        [
          asset_basename_path("Graphics/Trainers", "#{key}_back"),
          asset_basename_path("Graphics/Characters", "#{key}_back")
        ]
      }),
      :overworld_sprite => first_existing_logical_asset(root, sprite_keys.flat_map { |key|
        [
          asset_basename_path("Graphics/Characters", key),
          asset_basename_path("Graphics/Characters", key.to_s.upcase)
        ]
      }),
      :gender         => integer(generic_dat_ivar(entry, :gender), 2)
    }
  rescue => e
    log("Generic compiled trainer type normalize failed: #{e.class}: #{e.message}")
    return nil
  end

  def normalize_generic_dat_trainer_record(entry)
    return nil if !entry
    trainer_type = external_identifier(generic_dat_ivar(entry, :trainer_type, :type))
    return nil if trainer_type.nil?
    pokemon = Array(generic_dat_ivar(entry, :pokemon, :party)).map { |pkmn| normalize_generic_dat_trainer_pokemon(pkmn) }.compact
    return {
      :trainer_type => trainer_type,
      :name         => normalize_string(generic_dat_ivar(entry, :real_name, :name), ""),
      :version      => integer(generic_dat_ivar(entry, :version), 0),
      :lose_text    => normalize_string_or_nil(generic_dat_ivar(entry, :real_lose_text, :lose_text)),
      :items        => Array(generic_dat_ivar(entry, :items)).map { |item| external_identifier(item) }.compact,
      :pokemon      => pokemon
    }
  rescue => e
    log("Generic compiled trainer record normalize failed: #{e.class}: #{e.message}")
    return nil
  end

  def generic_dat_hash_value(entry, *keys)
    return nil if !entry.is_a?(Hash)
    keys.each do |key|
      return entry[key] if entry.has_key?(key)
      key_string = key.to_s
      return entry[key_string] if entry.has_key?(key_string)
      found = entry.keys.find { |candidate| candidate.to_s.downcase == key_string.downcase }
      return entry[found] if found
    end
    return nil
  rescue
    return nil
  end

  def normalize_generic_dat_trainer_pokemon(entry)
    return nil if !entry
    if entry.is_a?(Hash)
      species = generic_dat_hash_value(entry, :species)
      species_id = external_identifier(species) || species
      return nil if species_id.nil?
      level = integer(generic_dat_hash_value(entry, :level), 1)
      return nil if level <= 0
      moves = Array(generic_dat_hash_value(entry, :moves)).map { |move| external_identifier(move) }.compact
      return {
        :species         => species_id,
        :level           => level,
        :item            => external_identifier(generic_dat_hash_value(entry, :item)),
        :moves           => moves,
        :ability         => external_identifier(generic_dat_hash_value(entry, :ability)),
        :ability_index   => generic_dat_hash_value(entry, :ability_index),
        :gender          => generic_dat_hash_value(entry, :gender),
        :form            => generic_dat_hash_value(entry, :form),
        :shininess       => generic_dat_hash_value(entry, :shiny, :shininess),
        :nature          => external_identifier(generic_dat_hash_value(entry, :nature)),
        :iv              => generic_dat_hash_value(entry, :iv, :ivs),
        :ev              => generic_dat_hash_value(entry, :ev, :evs),
        :happiness       => generic_dat_hash_value(entry, :happiness),
        :name            => normalize_string_or_nil(generic_dat_hash_value(entry, :name, :nickname)),
        :shadowness      => generic_dat_hash_value(entry, :shadow, :shadowness),
        :poke_ball       => external_identifier(generic_dat_hash_value(entry, :ball, :poke_ball))
      }
    end
    return nil
  rescue => e
    log("Generic compiled trainer Pokemon normalize failed: #{e.class}: #{e.message}")
    return nil
  end

  def generic_pbs_trainer_paths(root)
    pbs_root = File.join(root.to_s, "PBS")
    return nil if !File.directory?(pbs_root)
    type_candidates = [
      File.join(pbs_root, "trainer_types.txt"),
      File.join(pbs_root, "trainertypes.txt")
    ]
    team_candidates = [
      File.join(pbs_root, "trainers.txt"),
      File.join(pbs_root, "trainer_teams.txt")
    ]
    type_path = type_candidates.find { |path| File.file?(path) }
    team_path = team_candidates.find { |path| File.file?(path) }
    return nil if !type_path || !team_path
    return {
      :pbs_root  => pbs_root,
      :type_path => type_path,
      :team_path => team_path
    }
  rescue
    return nil
  end

  def parse_generic_pbs_sections(path)
    sections = []
    current = nil
    File.foreach(path) do |line|
      raw = line.to_s.gsub(/\r?\n\z/, "")
      text = raw.strip
      next if text.empty? || text.start_with?("#")
      if text =~ /\A\[(.+)\]\z/
        current = {
          :section => $1.to_s.strip,
          :values  => {},
          :rows    => []
        }
        sections << current
        next
      end
      next if !current
      current[:rows] << raw
      if text =~ /\A([^=]+?)\s*=\s*(.*)\z/
        current[:values][$1.to_s.strip] = $2.to_s.strip
      end
    end
    return sections
  rescue => e
    log("Generic PBS section parse failed for #{path}: #{e.class}: #{e.message}")
    return []
  end

  def split_generic_pbs_csv(value)
    return value.to_s.split(",").map { |entry| entry.to_s.strip }.find_all { |entry| !entry.empty? }
  rescue
    return []
  end

  def generic_pbs_value(section, *keys)
    return nil if !section.is_a?(Hash)
    values = section[:values]
    return nil if !values.is_a?(Hash)
    keys.each do |key|
      return values[key.to_s] if values.has_key?(key.to_s)
      found = values.keys.find { |entry| entry.to_s.downcase == key.to_s.downcase }
      return values[found] if found
    end
    return nil
  rescue
    return nil
  end

  def generic_pbs_gender_value(value)
    text = value.to_s.strip.downcase
    return 0 if ["male", "m", "boy", "hombre"].include?(text)
    return 1 if ["female", "f", "girl", "mujer"].include?(text)
    return 2
  rescue
    return 2
  end

  def generic_pbs_trainer_type_id_number(expansion_id, index)
    hash = 0
    expansion_id.to_s.each_byte { |byte| hash = ((hash * 33) + byte) % 500 }
    return 80_000 + (hash * 1_000) + integer(index, 0) + 1
  rescue
    return 80_000 + integer(index, 0) + 1
  end

  def load_generic_pbs_trainer_catalog(expansion_id, root, paths)
    type_sections = parse_generic_pbs_sections(paths[:type_path])
    team_sections = parse_generic_pbs_trainer_blocks(paths[:team_path])
    return nil if type_sections.empty? || team_sections.empty?

    type_map = {}
    id_map = {}
    type_sections.each_with_index do |section, index|
      normalized = normalize_generic_pbs_trainer_type(expansion_id, root, section, index)
      next if !normalized
      normalized = register_imported_trainer_type(expansion_id, normalized)
      type_map[normalized[:id]] = normalized
      id_map[normalized[:id_number]] = normalized[:id] if integer(normalized[:id_number], 0) > 0
    end

    team_map = {}
    team_sections.each do |section|
      normalized = normalize_generic_pbs_trainer_record(section)
      next if !normalized
      key = [normalized[:trainer_type], normalized[:name], normalized[:version]]
      team_map[key] = normalized
    end

    log("Loaded generic PBS trainer catalog for #{expansion_id} from #{paths[:pbs_root]} (#{type_map.length} trainer types, #{team_map.length} teams)")
    return {
      :adapter => :generic_pbs,
      :root    => root,
      :types   => type_map,
      :id_map  => id_map,
      :teams   => team_map
    }
  rescue => e
    log("Failed to load generic PBS trainer catalog for #{expansion_id}: #{e.class}: #{e.message}")
    return nil
  end

  def normalize_generic_pbs_trainer_type(expansion_id, root, section, index = 0)
    symbol_id = external_identifier(section[:section])
    return nil if symbol_id.nil?
    title = normalize_string_or_nil(generic_pbs_value(section, "Name", "Title")) || symbol_id.to_s
    id_number = integer(generic_pbs_value(section, "ID", "Id", "TrainerID", "TrainerId"), 0)
    id_number = generic_pbs_trainer_type_id_number(expansion_id, index) if id_number <= 0
    front_sprite_name = generic_pbs_value(section, "FrontSprite", "Sprite", "Front")
    back_sprite_name = generic_pbs_value(section, "BackSprite", "Back")
    overworld_sprite_name = generic_pbs_value(section, "OverworldSprite", "Character", "Charset")
    symbol_text = symbol_id.to_s
    return {
      :id               => symbol_id,
      :runtime_id       => imported_trainer_runtime_id(expansion_id, symbol_id),
      :id_number        => id_number,
      :title            => title,
      :skill_level      => integer(generic_pbs_value(section, "SkillLevel", "Skill"), integer(generic_pbs_value(section, "BaseMoney"), 30)),
      :base_money       => integer(generic_pbs_value(section, "BaseMoney", "Money"), 30),
      :battle_BGM       => normalize_string_or_nil(generic_pbs_value(section, "BattleBGM", "BattleMusic")),
      :victory_ME       => normalize_string_or_nil(generic_pbs_value(section, "VictoryME", "VictoryMusic")),
      :intro_BGM        => normalize_string_or_nil(generic_pbs_value(section, "IntroME", "IntroBGM", "IntroMusic")),
      :front_sprite     => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Trainers", front_sprite_name),
        "Graphics/Trainers/#{symbol_text}",
        "Graphics/Trainers/#{symbol_text.upcase}",
        asset_basename_path("Graphics/Trainers", title)
      ]),
      :back_sprite      => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Trainers", back_sprite_name),
        "Graphics/Trainers/#{symbol_text}_back",
        "Graphics/Trainers/#{symbol_text.upcase}_back"
      ]),
      :overworld_sprite => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Characters", overworld_sprite_name),
        "Graphics/Characters/#{symbol_text}",
        "Graphics/Characters/#{symbol_text.upcase}"
      ]),
      :gender           => generic_pbs_gender_value(generic_pbs_value(section, "Gender"))
    }
  rescue => e
    log("Generic PBS trainer type parse failed for #{section[:section]}: #{e.class}: #{e.message}")
    return nil
  end

  def parse_generic_pbs_trainer_blocks(path)
    blocks = []
    current = nil
    current_pokemon = nil
    File.foreach(path) do |line|
      raw = line.to_s.gsub(/\r?\n\z/, "")
      text = raw.strip
      next if text.empty? || text.start_with?("#")
      if text =~ /\A\[(.+)\]\z/
        current = {
          :section => $1.to_s.strip,
          :values  => {},
          :items   => [],
          :pokemon => []
        }
        blocks << current
        current_pokemon = nil
        next
      end
      next if !current || text !~ /\A([^=]+?)\s*=\s*(.*)\z/
      key = $1.to_s.strip
      value = $2.to_s.strip
      if key.casecmp("Pokemon").zero?
        parts = split_generic_pbs_csv(value)
        current_pokemon = { :species => parts[0], :level => parts[1] }
        current[:pokemon] << current_pokemon
        next
      end
      if current_pokemon && raw =~ /\A\s+/ && generic_pbs_pokemon_property?(key)
        generic_pbs_assign_pokemon_property!(current_pokemon, key, value)
        next
      end
      current[:values][key] = value
      current[:items] = split_generic_pbs_csv(value) if key.casecmp("Items").zero?
      current_pokemon = nil if raw !~ /\A\s+/
    end
    return blocks
  rescue => e
    log("Generic PBS trainer team parse failed for #{path}: #{e.class}: #{e.message}")
    return []
  end

  def generic_pbs_pokemon_property?(key)
    return %w[Name Moves Ability AbilityIndex Gender Form Nature IV EV Happiness Shiny Shadow Ball Item].include?(key.to_s)
  rescue
    return false
  end

  def generic_pbs_truthy?(value)
    return false if value.nil?
    return value if value == true || value == false
    text = value.to_s.strip.downcase
    return false if text.empty? || ["false", "0", "no", "off", "nil"].include?(text)
    return true
  rescue
    return false
  end

  def generic_pbs_assign_pokemon_property!(pokemon, key, value)
    return if !pokemon.is_a?(Hash)
    case key.to_s.downcase
    when "name"
      pokemon[:name] = value
    when "moves"
      pokemon[:moves] = split_generic_pbs_csv(value)
    when "ability"
      pokemon[:ability] = value
    when "abilityindex"
      pokemon[:ability_index] = value
    when "gender"
      pokemon[:gender] = value
    when "form"
      pokemon[:form] = value
    when "nature"
      pokemon[:nature] = value
    when "iv"
      pokemon[:iv] = value
    when "ev"
      pokemon[:ev] = value
    when "happiness"
      pokemon[:happiness] = value
    when "shiny"
      pokemon[:shiny] = value
    when "shadow"
      pokemon[:shadow] = value
    when "ball"
      pokemon[:ball] = value
    when "item"
      pokemon[:item] = value
    end
  rescue
  end

  def normalize_generic_pbs_trainer_record(section)
    header = section[:section].to_s
    parts = split_generic_pbs_csv(header)
    return nil if parts.length < 2
    pokemon = Array(section[:pokemon]).map { |pkmn| normalize_generic_pbs_trainer_pokemon(pkmn) }.compact
    return {
      :trainer_type => external_identifier(parts[0]),
      :name         => normalize_string(parts[1], ""),
      :version      => integer(parts[2], 0),
      :lose_text    => generic_pbs_value(section, "LoseText", "Lose", "EndSpeech"),
      :items        => Array(section[:items]).map { |item| external_identifier(item) }.compact,
      :pokemon      => pokemon
    }
  rescue => e
    log("Generic PBS trainer record parse failed for #{section[:section]}: #{e.class}: #{e.message}")
    return nil
  end

  def normalize_generic_pbs_trainer_pokemon(entry)
    return nil if !entry.is_a?(Hash)
    species = external_identifier(entry[:species])
    return nil if species.nil?
    return {
      :species       => species,
      :level         => integer(entry[:level], 1),
      :item          => external_identifier(entry[:item]),
      :moves         => split_generic_pbs_csv(entry[:moves].is_a?(Array) ? entry[:moves].join(",") : entry[:moves]).map { |move| external_identifier(move) },
      :ability       => external_identifier(entry[:ability]),
      :ability_index => entry[:ability_index],
      :gender        => normalize_string_or_nil(entry[:gender]),
      :form          => entry[:form],
      :nature        => external_identifier(entry[:nature]),
      :iv            => entry[:iv],
      :ev            => entry[:ev],
      :happiness     => entry[:happiness],
      :name          => normalize_string_or_nil(entry[:name]),
      :shininess     => generic_pbs_truthy?(entry[:shiny]) || boolean(entry[:shiny], false),
      :shadowness    => generic_pbs_truthy?(entry[:shadow]) || boolean(entry[:shadow], false),
      :poke_ball     => external_identifier(entry[:ball])
    }
  rescue => e
    log("Generic PBS trainer Pokemon parse failed: #{e.class}: #{e.message}")
    return nil
  end

  def external_project_data_root(expansion_id)
    if respond_to?(:expansion_data_root)
      data_root = expansion_data_root(expansion_id)
      return data_root if !data_root.to_s.empty?
    end
    info = external_projects[expansion_id.to_s] if respond_to?(:external_projects)
    return info[:data_root].to_s if info.is_a?(Hash) && !info[:data_root].to_s.empty?
    root = external_project_root(expansion_id)
    return nil if root.nil? || root.empty?
    candidate = File.join(root, "Data")
    return candidate if File.directory?(candidate)
    return nil
  rescue
    return nil
  end

  def uranium_dat_trainer_paths(expansion_id, root)
    data_root = external_project_data_root(expansion_id)
    return nil if data_root.to_s.empty?
    type_path = File.join(data_root, "trainertypes.dat")
    team_path = File.join(data_root, "trainers.dat")
    return nil if !File.file?(type_path) || !File.file?(team_path)
    return {
      :data_root => data_root,
      :type_path => type_path,
      :team_path => team_path
    }
  end

  def load_uranium_marshaled_data(path)
    return nil if path.to_s.empty? || !File.file?(path)
    return Marshal.load(File.binread(path))
  rescue => e
    log("Failed to load Uranium trainer data #{path}: #{e.class}: #{e.message}")
    return nil
  end

  def load_uranium_dat_trainer_catalog(expansion_id, root, paths)
    raw_types = load_uranium_marshaled_data(paths[:type_path])
    raw_teams = load_uranium_marshaled_data(paths[:team_path])
    return nil if !raw_types.is_a?(Array) || !raw_teams.is_a?(Array)

    type_map = {}
    id_map = {}
    raw_types.each do |entry|
      normalized = normalize_uranium_trainer_type(expansion_id, root, entry)
      next if !normalized
      normalized = register_imported_trainer_type(expansion_id, normalized)
      type_map[normalized[:id]] = normalized
      id_map[normalized[:id_number]] = normalized[:id] if normalized[:id_number] > 0
    end

    team_map = {}
    raw_teams.each do |entry|
      normalized = normalize_uranium_trainer_record(entry, id_map)
      next if !normalized
      key = [normalized[:trainer_type], normalized[:name], normalized[:version]]
      team_map[key] = normalized
    end

    log("Loaded external trainer catalog for #{expansion_id} from #{paths[:data_root]} (#{type_map.length} trainer types, #{team_map.length} teams)")
    return {
      :adapter => :uranium_dat,
      :root    => root,
      :types   => type_map,
      :id_map  => id_map,
      :teams   => team_map
    }
  rescue => e
    log("Failed to load Uranium trainer catalog for #{expansion_id} from #{paths[:data_root]}: #{e.class}: #{e.message}")
    return nil
  end

  def normalize_uranium_trainer_type(expansion_id, root, entry)
    return nil if !entry.is_a?(Array) || entry.length < 3
    id_number = integer(entry[0], 0)
    symbol_id = external_identifier(entry[1])
    return nil if id_number <= 0 || symbol_id.nil?
    title = normalize_string_or_nil(entry[2]) || symbol_id.to_s
    return {
      :id             => symbol_id,
      :runtime_id     => imported_trainer_runtime_id(expansion_id, symbol_id),
      :id_number      => id_number,
      :title          => title,
      :skill_level    => integer(entry[8], integer(entry[3], 30)),
      :base_money     => integer(entry[3], 30),
      :battle_BGM     => normalize_string_or_nil(entry[4]),
      :victory_ME     => normalize_string_or_nil(entry[5]),
      :intro_BGM      => normalize_string_or_nil(entry[6]),
      :sprite         => sprintf("trainer%03d", id_number),
      :front_sprite   => first_existing_logical_asset(root, [
        sprintf("Graphics/Characters/trainer%03d", id_number),
        sprintf("Graphics/Characters/HGSS_%03d", id_number),
        asset_basename_path("Graphics/Characters", entry[1]),
        asset_basename_path("Graphics/Characters", entry[2])
      ]),
      :back_sprite    => first_existing_logical_asset(root, [
        sprintf("Graphics/Characters/trback%03d", id_number),
        asset_basename_path("Graphics/Characters", "#{entry[1]}_back")
      ]),
      :overworld_sprite => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Characters", entry[1]),
        asset_basename_path("Graphics/Characters", entry[2])
      ]),
      :gender         => integer(entry[7], 2)
    }
  end

  def normalize_uranium_trainer_record(entry, id_map = nil)
    return nil if !entry.is_a?(Array) || entry.length < 4
    raw_type = integer(entry[0], 0)
    trainer_type = id_map.is_a?(Hash) ? id_map[raw_type] : nil
    trainer_type ||= external_identifier(raw_type)
    return nil if trainer_type.nil?
    pokemon = Array(entry[3]).map { |pkmn| normalize_uranium_trainer_pokemon(pkmn) }.compact
    return {
      :trainer_type => trainer_type,
      :name         => normalize_string(entry[1], ""),
      :version      => integer(entry[4], 0),
      :lose_text    => nil,
      :items        => Array(entry[2]).map { |item| integer(item, 0) }.find_all { |item| item > 0 },
      :pokemon      => pokemon
    }
  end

  def normalize_uranium_trainer_pokemon(entry)
    return nil if !entry.is_a?(Array) || entry.length < 2
    species = integer(entry[0], 0)
    level = integer(entry[1], 1)
    return nil if species <= 0 || level <= 0
    moves = Array(entry[3, 4]).map { |move| integer(move, 0) }.find_all { |move| move > 0 }
    item = integer(entry[2], 0)
    ability_index = integer(entry[7], -1)
    ability_index = nil if ability_index < 0
    gender = entry[8]
    gender = nil if gender.nil?
    form = integer(entry[9], 0)
    form = nil if form <= 0
    shiny = (entry[10] == true)
    nature = integer(entry[11], -1)
    nature = nil if nature < 0
    iv = integer(entry[12], -1)
    iv = nil if iv < 0
    happiness = integer(entry[13], -1)
    happiness = nil if happiness < 0
    nickname = normalize_string_or_nil(entry[14])
    shadow = (entry[15] == true)
    ball = integer(entry[16], 0)
    ball = nil if ball <= 0
    return {
      :species         => species,
      :level           => level,
      :item            => (item > 0 ? item : nil),
      :moves           => moves,
      :ability_index   => ability_index,
      :gender          => gender,
      :form            => form,
      :shininess       => shiny,
      :nature          => nature,
      :iv              => iv,
      :happiness       => happiness,
      :name            => nickname,
      :shadowness      => shadow,
      :poke_ball       => ball
    }
  end

  def xenoverse_pbs_trainer_paths(root)
    pbs_root = File.join(root, "PBS")
    type_candidates = [
      File.join(pbs_root, "trainertypes.txt"),
      File.join(pbs_root, "trainer_types.txt")
    ]
    team_candidates = [
      File.join(pbs_root, "trainers.txt")
    ]
    type_path = type_candidates.find { |path| File.file?(path) }
    team_path = team_candidates.find { |path| File.file?(path) }
    return nil if type_path.nil? || team_path.nil?
    return {
      :type_paths => type_candidates.find_all { |path| File.file?(path) },
      :team_paths => team_candidates.find_all { |path| File.file?(path) }
    }
  end

  def load_xenoverse_pbs_trainer_catalog(expansion_id, root, paths)
    type_rows = []
    Array(paths[:type_paths]).each { |path| type_rows.concat(parse_xenoverse_trainer_type_rows(path)) }
    team_blocks = []
    Array(paths[:team_paths]).each { |path| team_blocks.concat(parse_xenoverse_trainer_blocks(path)) }
    return nil if type_rows.empty? || team_blocks.empty?

    type_map = {}
    id_map = {}
    type_rows.each_with_index do |row, index|
      normalized = normalize_xenoverse_csv_trainer_type(expansion_id, root, row, index)
      next if !normalized
      normalized = register_imported_trainer_type(expansion_id, normalized)
      type_map[normalized[:id]] = normalized
      id_map[normalized[:id_number]] = normalized[:id] if normalized[:id_number] > 0
    end

    team_map = {}
    team_blocks.each do |block|
      normalized = normalize_xenoverse_flat_trainer_record(block)
      next if !normalized
      if team_map.has_key?([normalized[:trainer_type], normalized[:name], normalized[:version]])
        version = integer(normalized[:version], 0)
        version += 1 while team_map.has_key?([normalized[:trainer_type], normalized[:name], version])
        normalized = normalized.dup
        normalized[:version] = version
      end
      key = [normalized[:trainer_type], normalized[:name], normalized[:version]]
      team_map[key] = normalized
    end

    log("Loaded external trainer catalog for #{expansion_id} from #{root} (#{type_map.length} trainer types, #{team_map.length} teams)")
    return {
      :adapter => :xenoverse_pbs,
      :root    => root,
      :types   => type_map,
      :id_map  => id_map,
      :teams   => team_map
    }
  rescue => e
    log("Failed to load Xenoverse trainer catalog for #{expansion_id} from #{root}: #{e.class}: #{e.message}")
    return nil
  end

  def parse_xenoverse_trainer_type_rows(path)
    rows = []
    File.foreach(path) do |line|
      text = line.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "").strip
      next if text.empty? || text.start_with?("#", ";")
      rows << text.split(",", -1).map { |entry| entry.to_s.strip }
    end
    return rows
  rescue => e
    log("Xenoverse trainer type parse failed for #{path}: #{e.class}: #{e.message}")
    return []
  end

  def parse_xenoverse_trainer_blocks(path)
    blocks = []
    current = []
    File.foreach(path) do |line|
      text = line.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "").strip
      if text.start_with?("#")
        blocks << current if !current.empty?
        current = []
        next
      end
      next if text.empty?
      current << text
    end
    blocks << current if !current.empty?
    return blocks
  rescue => e
    log("Xenoverse trainer team parse failed for #{path}: #{e.class}: #{e.message}")
    return []
  end

  def normalize_xenoverse_csv_trainer_type(expansion_id, root, row, index = 0)
    return nil if !row.is_a?(Array) || row.length < 2
    id_number = integer(row[0], 0)
    symbol_id = external_identifier(row[1])
    return nil if symbol_id.nil?
    title = normalize_string_or_nil(row[2]) || symbol_id.to_s
    base_money = integer(row[3], 30)
    battle_bgm = normalize_string_or_nil(row[4])
    victory_me = normalize_string_or_nil(row[5])
    gender = parse_external_gender(row[7])
    skill_level = integer(row[8], 30)
    sprite_name = symbol_id.to_s
    numeric_sprite_name = id_number > 0 ? "trainer#{id_number}" : nil
    padded_sprite_name = id_number > 0 ? sprintf("trainer%03d", id_number) : nil
    return {
      :id             => symbol_id,
      :runtime_id     => imported_trainer_runtime_id(expansion_id, symbol_id),
      :id_number      => id_number,
      :title          => title,
      :skill_level    => skill_level,
      :base_money     => base_money,
      :battle_BGM     => battle_bgm,
      :intro_BGM      => normalize_string_or_nil(row[6]),
      :victory_ME     => victory_me,
      :sprite         => sprite_name,
      :front_sprite   => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Characters", numeric_sprite_name),
        asset_basename_path("Graphics/Characters", padded_sprite_name),
        asset_basename_path("Graphics/Characters", "trainer#{sprite_name}"),
        asset_basename_path("Graphics/Trainers", sprite_name),
        asset_basename_path("Graphics/Characters", sprite_name),
        "Graphics/Trainers/#{symbol_id}"
      ]),
      :back_sprite    => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Trainers", "#{sprite_name}_back"),
        "Graphics/Trainers/#{symbol_id}_back"
      ]),
      :overworld_sprite => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Characters", sprite_name),
        "Graphics/Characters/#{symbol_id}"
      ]),
      :gender         => gender,
      :flags          => [],
      :source_index   => index
    }
  end

  def normalize_xenoverse_flat_trainer_record(block)
    lines = Array(block).map { |entry| entry.to_s.strip }.find_all { |entry| !entry.empty? }
    return nil if lines.length < 3
    trainer_type = external_identifier(lines[0])
    return nil if trainer_type.nil?
    name = normalize_string(lines[1], "")
    header = lines[2].split(",", -1).map { |entry| normalize_string_or_nil(entry) }
    declared_count = integer(header[0], -1)
    version = 0
    items = Array(header[1..-1]).compact.map { |item| external_identifier(item) }.compact
    pokemon_lines = Array(lines[3..-1])
    pokemon_lines = pokemon_lines.first(declared_count) if declared_count >= 0
    pokemon = pokemon_lines.map { |line| normalize_xenoverse_flat_trainer_pokemon(line) }.compact
    return {
      :trainer_type => trainer_type,
      :name         => name,
      :version      => version,
      :lose_text    => nil,
      :items        => items,
      :pokemon      => pokemon
    }
  end

  def normalize_xenoverse_flat_trainer_pokemon(line)
    parts = line.to_s.split(",", -1).map { |entry| entry.to_s.strip }
    return nil if parts.empty?
    species = external_identifier(parts[0])
    return nil if species.nil?
    moves = parts[3, 4].to_a.map { |move| external_identifier(move) }.compact
    item = external_identifier(parts[2])
    ability_index = integer(parts[7], -1)
    ability_index = nil if ability_index < 0
    gender = normalize_string_or_nil(parts[8])
    nature = normalize_string_or_nil(parts[11])
    iv = integer(parts[12], -1)
    iv = nil if iv < 0
    happiness = integer(parts[13], -1)
    happiness = nil if happiness < 0
    form = nil
    trailing_numeric = parts.reverse.find { |entry| entry.to_s.match?(/\A\d+\z/) }
    if trailing_numeric
      candidate = integer(trailing_numeric, 0)
      form = candidate if candidate > 0
    end
    return {
      :species         => species,
      :level           => integer(parts[1], 1),
      :item            => item,
      :moves           => moves,
      :ability_index   => ability_index,
      :gender          => gender,
      :form            => form,
      :nature          => nature,
      :iv              => iv,
      :happiness       => happiness,
      :name            => nil,
      :shininess       => false,
      :super_shininess => false,
      :shadowness      => false,
      :poke_ball       => nil
    }
  end

  def parse_external_trainer_sections(path)
    sections = []
    current = nil
    File.foreach(path) do |line|
      text = line.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      stripped = text.strip
      next if stripped.empty? || stripped.start_with?("#", ";")
      if stripped =~ /\A\[(.+)\]\z/
        current = {
          :section => $1.to_s.strip,
          :entries => []
        }
        sections << current
        next
      end
      next if current.nil?
      next if stripped !~ /\A([^=]+?)\s*=\s*(.*)\z/
      current[:entries] << [$1.to_s.strip, $2.to_s.strip]
    end
    return sections
  rescue => e
    log("Xenoverse trainer PBS parse failed for #{path}: #{e.class}: #{e.message}")
    return []
  end

  def trainer_section_value(section, *names)
    Array(section[:entries]).reverse_each do |entry|
      key = entry[0].to_s
      return entry[1] if names.any? { |name| key.casecmp(name.to_s).zero? }
    end
    return nil
  end

  def trainer_section_values(section, *names)
    values = []
    Array(section[:entries]).each do |entry|
      key = entry[0].to_s
      values << entry[1] if names.any? { |name| key.casecmp(name.to_s).zero? }
    end
    return values
  end

  def split_external_csv(value)
    return [] if value.nil?
    return value.to_s.split(",").map { |entry| normalize_string_or_nil(entry) }.compact
  end

  def parse_external_gender(value)
    text = value.to_s.strip.downcase
    return 0 if ["m", "male", "0"].include?(text)
    return 1 if ["f", "female", "1"].include?(text)
    return 2 if ["u", "unknown", "2", "genderless", "none"].include?(text)
    return 2
  end

  def parse_external_boolean(value, fallback = false)
    return fallback if value.nil?
    return value if value == true || value == false
    text = value.to_s.strip.downcase
    return true if ["1", "true", "yes", "y", "on"].include?(text)
    return false if ["0", "false", "no", "n", "off"].include?(text)
    return fallback
  end

  def parse_external_stat_list(value)
    return nil if value.nil?
    values = split_external_csv(value).map { |entry| integer(entry, 0) }
    return values.empty? ? nil : values
  end

  def normalize_xenoverse_trainer_type(expansion_id, root, section, index = 0)
    return nil if !section.is_a?(Hash)
    symbol_id = external_identifier(section[:section])
    return nil if symbol_id.nil?
    title = normalize_string_or_nil(trainer_section_value(section, "Name", "Title")) || symbol_id.to_s
    base_money = integer(trainer_section_value(section, "BaseMoney", "Money"), 30)
    skill_level = integer(trainer_section_value(section, "SkillLevel", "Skill"), base_money)
    sprite_name = trainer_section_value(section, "Sprite", "FrontSprite", "BattleSprite", "TrainerSprite")
    back_sprite_name = trainer_section_value(section, "BackSprite")
    battle_bgm = normalize_string_or_nil(trainer_section_value(section, "BattleBGM", "Battle_BGM", "BGM"))
    intro_bgm = normalize_string_or_nil(trainer_section_value(section, "IntroBGM", "Intro_BGM"))
    victory_me = normalize_string_or_nil(trainer_section_value(section, "VictoryBGM", "VictoryME", "Victory_ME", "WinBGM"))
    flags = split_external_csv(trainer_section_value(section, "Flags"))
    return {
      :id             => symbol_id,
      :runtime_id     => imported_trainer_runtime_id(expansion_id, symbol_id),
      :id_number      => integer(trainer_section_value(section, "ID", "Id", "TrainerID", "TrainerId"), 0),
      :title          => title,
      :skill_level    => skill_level,
      :base_money     => base_money,
      :battle_BGM     => battle_bgm,
      :intro_BGM      => intro_bgm,
      :victory_ME     => victory_me,
      :sprite         => normalize_string_or_nil(sprite_name) || symbol_id.to_s,
      :front_sprite   => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Trainers", sprite_name),
        asset_basename_path("Graphics/Trainers", symbol_id),
        asset_basename_path("Graphics/Trainers", symbol_id.to_s.upcase),
        "Graphics/Trainers/#{symbol_id}"
      ]),
      :back_sprite    => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Trainers", back_sprite_name),
        asset_basename_path("Graphics/Trainers", "#{symbol_id}_back"),
        asset_basename_path("Graphics/Trainers", "#{symbol_id.to_s.upcase}_back"),
        "Graphics/Trainers/#{symbol_id}_back"
      ]),
      :overworld_sprite => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Characters", trainer_section_value(section, "OverworldSprite", "Overworld", "CharacterSprite"))
      ]),
      :gender         => parse_external_gender(trainer_section_value(section, "Gender")),
      :flags          => flags,
      :source_index   => index
    }
  end

  def normalize_xenoverse_trainer_record(section)
    return nil if !section.is_a?(Hash)
    header = section[:section].to_s
    parts = header.split(",").map { |entry| normalize_string_or_nil(entry) }.compact
    return nil if parts.empty?
    trainer_type = external_identifier(parts[0])
    return nil if trainer_type.nil?
    name = normalize_string_or_nil(parts[1]) || ""
    version = integer(parts[2], 0)
    pokemon = []
    current_pokemon = nil

    Array(section[:entries]).each do |entry|
      key = entry[0].to_s
      value = entry[1].to_s
      if key.casecmp("Pokemon").zero?
        current_pokemon = normalize_xenoverse_trainer_pokemon(value)
        pokemon << current_pokemon if current_pokemon
        next
      end
      if current_pokemon
        normalize_xenoverse_trainer_pokemon_property!(current_pokemon, key, value)
        next
      end
    end

    return {
      :trainer_type => trainer_type,
      :name         => name,
      :version      => version,
      :lose_text    => normalize_string_or_nil(trainer_section_value(section, "LoseText", "DefeatText")),
      :items        => split_external_csv(trainer_section_value(section, "Items", "Item")).map { |item| external_identifier(item) }.compact,
      :pokemon      => pokemon.compact
    }
  end

  def normalize_xenoverse_trainer_pokemon(value)
    parts = value.to_s.split(",").map { |entry| normalize_string_or_nil(entry) }.compact
    return nil if parts.length < 1
    species = external_identifier(parts[0])
    return nil if species.nil?
    pokemon = {
      :species       => species,
      :level         => integer(parts[1], 1),
      :item          => nil,
      :moves         => [],
      :ability       => nil,
      :ability_index => nil,
      :gender        => nil,
      :form          => nil,
      :nature        => nil,
      :iv            => nil,
      :ev            => nil,
      :happiness     => nil,
      :name          => nil,
      :shininess     => false,
      :super_shininess => false,
      :shadowness    => false,
      :poke_ball     => nil
    }
    return pokemon
  end

  def normalize_xenoverse_trainer_pokemon_property!(pokemon, key, value)
    case key.to_s.downcase
    when "name"
      pokemon[:name] = normalize_string_or_nil(value)
    when "form"
      pokemon[:form] = integer(value, 0)
    when "gender"
      pokemon[:gender] = normalize_string_or_nil(value)
    when "shiny"
      pokemon[:shininess] = parse_external_boolean(value, false)
    when "supershiny", "super_shiny"
      pokemon[:super_shininess] = parse_external_boolean(value, false)
      pokemon[:shininess] = true if pokemon[:super_shininess]
    when "shadow"
      pokemon[:shadowness] = parse_external_boolean(value, false)
    when "moves"
      pokemon[:moves] = split_external_csv(value).map { |move| external_identifier(move) }.compact
    when "ability"
      pokemon[:ability] = external_identifier(value)
    when "abilityindex", "ability_index"
      pokemon[:ability_index] = integer(value, 0)
    when "item"
      pokemon[:item] = external_identifier(value)
    when "nature"
      pokemon[:nature] = external_identifier(value)
    when "iv"
      pokemon[:iv] = parse_external_stat_list(value)
    when "ev"
      pokemon[:ev] = parse_external_stat_list(value)
    when "happiness"
      pokemon[:happiness] = integer(value, 70)
    when "ball", "pokeball", "poke_ball"
      pokemon[:poke_ball] = external_identifier(value)
    end
  end

  def reborn_text_export_paths(root)
    type_path = File.join(root, "Scripts", "Reborn", "ttypetext.rb")
    team_path = File.join(root, "Scripts", "Reborn", "trainertext.rb")
    return nil if !File.file?(type_path) || !File.file?(team_path)
    return {
      :type_path => type_path,
      :team_path => team_path
    }
  end

  def load_reborn_text_export_catalog(expansion_id, root, paths)
    sandbox = Module.new
    sandbox.module_eval(File.read(paths[:type_path]), paths[:type_path], 1)
    sandbox.module_eval(File.read(paths[:team_path]), paths[:team_path], 1)
    raw_types = sandbox.const_defined?(:TTYPEHASH) ? sandbox.const_get(:TTYPEHASH) : nil
    raw_teams = sandbox.const_defined?(:TEAMARRAY) ? sandbox.const_get(:TEAMARRAY) : nil
    return nil if !raw_types.is_a?(Hash) || !raw_teams.is_a?(Array)
    type_map = {}
    id_map = {}
    raw_types.each_pair do |type_id, data|
      normalized = normalize_reborn_trainer_type(expansion_id, root, type_id, data)
      next if !normalized
      normalized = register_imported_trainer_type(expansion_id, normalized)
      type_map[normalized[:id]] = normalized
      id_map[normalized[:id_number]] = normalized[:id] if normalized[:id_number] > 0
    end
    team_map = {}
    raw_teams.each do |entry|
      normalized = normalize_reborn_trainer_record(entry)
      next if !normalized
      key = [normalized[:trainer_type], normalized[:name], normalized[:version]]
      team_map[key] = normalized
    end
    log("Loaded external trainer catalog for #{expansion_id} from #{root} (#{type_map.length} trainer types, #{team_map.length} teams)")
    return {
      :adapter => :reborn_text_exports,
      :root    => root,
      :types   => type_map,
      :id_map  => id_map,
      :teams   => team_map
    }
  rescue => e
    log("Failed to load external trainer catalog for #{expansion_id} from #{root}: #{e.class}: #{e.message}")
    return nil
  end

  def normalize_reborn_trainer_type(expansion_id, root, type_id, data)
    return nil if type_id.nil? || !data.is_a?(Hash)
    symbol_id = external_identifier(type_id)
    return nil if symbol_id.nil?
    id_number = integer(data[:ID] || data["ID"], 0)
    return {
      :id          => symbol_id,
      :runtime_id  => imported_trainer_runtime_id(expansion_id, symbol_id),
      :id_number   => id_number,
      :title       => normalize_string_or_nil(data[:title] || data["title"]) || symbol_id.to_s,
      :skill_level => integer(data[:skill] || data["skill"], 0),
      :base_money  => integer(data[:moneymult] || data["moneymult"], 30),
      :battle_BGM  => normalize_string_or_nil(data[:battleBGM] || data["battleBGM"]),
      :victory_ME  => normalize_string_or_nil(data[:winBGM] || data["winBGM"]),
      :sprite      => normalize_string_or_nil(data[:sprite] || data["sprite"]),
      :front_sprite => first_existing_logical_asset(root, [
        sprintf("Graphics/Characters/trainer%03d", id_number),
        "Graphics/Characters/trainer#{id_number}"
      ]),
      :back_sprite => first_existing_logical_asset(root, [
        sprintf("Graphics/Characters/trback%03d", id_number),
        "Graphics/Characters/trback#{id_number}"
      ]),
      :overworld_sprite => first_existing_logical_asset(root, [
        asset_basename_path("Graphics/Characters", data[:sprite] || data["sprite"])
      ]),
      :gender      => integer(data[:gender] || data["gender"], 2)
    }
  end

  def normalize_reborn_trainer_record(entry)
    return nil if !entry.is_a?(Hash)
    team_id = entry[:teamid] || entry["teamid"]
    return nil if !team_id.is_a?(Array) || team_id.length < 3
    trainer_type = external_identifier(team_id[1])
    return nil if trainer_type.nil?
    pokemon = Array(entry[:mons] || entry["mons"]).map { |pkmn| normalize_reborn_trainer_pokemon(pkmn) }.compact
    return {
      :trainer_type => trainer_type,
      :name         => normalize_string(team_id[0], ""),
      :version      => integer(team_id[2], 0),
      :lose_text    => normalize_string_or_nil(entry[:defeat] || entry["defeat"]),
      :items        => Array(entry[:items] || entry["items"]).map { |item| external_identifier(item) }.compact,
      :pokemon      => pokemon
    }
  end

  def normalize_reborn_trainer_pokemon(entry)
    return nil if !entry.is_a?(Hash)
    species = external_identifier(entry[:species] || entry["species"])
    return nil if species.nil?
    return {
      :species       => species,
      :level         => integer(entry[:level] || entry["level"], 1),
      :item          => external_identifier(entry[:item] || entry["item"]),
      :moves         => Array(entry[:moves] || entry["moves"]).map { |move| external_identifier(move) },
      :ability       => external_identifier(entry[:ability] || entry["ability"]),
      :ability_index => entry[:ability_index] || entry["ability_index"],
      :gender        => normalize_string_or_nil(entry[:gender] || entry["gender"]),
      :form          => entry[:form] || entry["form"],
      :nature        => external_identifier(entry[:nature] || entry["nature"]),
      :iv            => entry[:iv] || entry["iv"],
      :ev            => entry[:ev] || entry["ev"],
      :happiness     => entry[:happiness] || entry["happiness"],
      :name          => normalize_string_or_nil(entry[:name] || entry["name"]),
      :shininess     => boolean(entry[:shiny] || entry["shiny"], false),
      :shadowness    => boolean(entry[:shadow] || entry["shadow"], false),
      :poke_ball     => external_identifier(entry[:ball] || entry["ball"])
    }
  end

  def find_external_trainer_record(catalog, tr_type, tr_name, tr_version = 0)
    team_map = catalog[:teams]
    return nil if !team_map.is_a?(Hash)
    version = integer(tr_version, 0)
    type_candidates = external_trainer_type_candidates(catalog, tr_type)
    name_candidates = [normalize_string(tr_name, ""), tr_name.to_s].find_all { |value| !value.empty? }.uniq
    type_candidates.each do |type_id|
      name_candidates.each do |name|
        key = [type_id, name, version]
        return team_map[key] if team_map.has_key?(key)
      end
    end
    name_candidates.each do |name|
      matches = team_map.values.find_all { |entry| entry[:name] == name && entry[:version] == version }
      return matches.first if matches.length == 1
    end
    return nil
  end

  def external_trainer_type_candidates(catalog, tr_type)
    candidates = []
    identifier = external_identifier(tr_type)
    candidates << identifier if identifier
    if tr_type.is_a?(Integer)
      mapped = catalog[:id_map].is_a?(Hash) ? catalog[:id_map][tr_type] : nil
      candidates << mapped if mapped
    else
      number = integer(tr_type, -1)
      if number >= 0
        mapped = catalog[:id_map].is_a?(Hash) ? catalog[:id_map][number] : nil
        candidates << mapped if mapped
      end
    end
    return candidates.compact.uniq
  end

  def build_external_trainer(expansion_id, catalog, record)
    type_data = catalog[:types].is_a?(Hash) ? catalog[:types][record[:trainer_type]] : nil
    placeholder_data = nil
    begin
      placeholder_data = GameData::TrainerType.try_get(TRAINER_HOST_PLACEHOLDER_TYPE)
    rescue
      placeholder_data = nil
    end
    placeholder = placeholder_data ? placeholder_data.id : GameData::TrainerType.keys.find { |key| !key.is_a?(Integer) }
    return nil if placeholder.nil?
    trainer = NPCTrainer.new(record[:name], placeholder)
    if imported_trainer_native_battle_sprites_enabled? && type_data.is_a?(Hash) && type_data[:runtime_id]
      trainer.instance_variable_set(:@travel_expansion_runtime_trainer_type, type_data[:runtime_id])
      if trainer.respond_to?(:trainer_type=)
        begin
          trainer.trainer_type = type_data[:runtime_id]
        rescue => e
          log("Imported trainer runtime type assignment failed for #{expansion_id}/#{record[:trainer_type]}/#{record[:name]}: #{e.class}: #{e.message}")
        end
      end
    end
    trainer.id = $Trainer.make_foreign_ID if $Trainer && $Trainer.respond_to?(:make_foreign_ID)
    trainer.items = Array(record[:items]).map { |item| resolve_external_item(item, expansion_id) }.compact
    lose_text = localized_external_trainer_text(expansion_id, record[:lose_text])
    trainer.lose_text = lose_text if !lose_text.to_s.empty?
    if type_data.is_a?(Hash) && trainer.respond_to?(:sprite_override=)
      trainer.sprite_override = resolved_external_trainer_asset(expansion_id, type_data, :front_sprite)
    elsif trainer.respond_to?(:sprite_override=)
      trainer.sprite_override = nil
    end
    trainer.instance_variable_set(:@travel_expansion_external_trainer_type, record[:trainer_type])
    trainer.instance_variable_set(:@travel_expansion_external_trainer_type_data, type_data || {})
    trainer.instance_variable_set(:@travel_expansion_expansion_id, expansion_id.to_s)
    trainer.extend(ImportedTrainerBehavior)
    if imported_trainer_native_battle_sprites_enabled? && type_data.is_a?(Hash) && trainer.respond_to?(:trainer_type)
      log("Assigned imported trainer runtime type #{trainer.trainer_type} for #{expansion_id}/#{record[:trainer_type]}/#{record[:name]} using #{type_data[:front_sprite]}")
    end
    Array(record[:pokemon]).each do |pkmn_data|
      pokemon = build_external_trainer_pokemon(trainer, pkmn_data, expansion_id)
      trainer.party << pokemon if pokemon
    end
    return trainer
  rescue => e
    log("Failed to build external trainer #{record[:trainer_type]}/#{record[:name]}/#{record[:version]}: #{e.class}: #{e.message}")
    return nil
  end

  def build_external_trainer_pokemon(trainer, pkmn_data, expansion_id = nil)
    return nil if !pkmn_data.is_a?(Hash)
    species = resolve_external_species(pkmn_data[:species], expansion_id)
    return nil if species.nil?
    level = integer(pkmn_data[:level], 1)
    pkmn = Pokemon.new(species, level, trainer, false)
    if pkmn_data[:form]
      pkmn.forced_form = pkmn_data[:form] if pkmn.respond_to?(:forced_form=) && MultipleForms.hasFunction?(species, "getForm")
      pkmn.form_simple = pkmn_data[:form] if pkmn.respond_to?(:form_simple=)
    end
    item = resolve_external_item(pkmn_data[:item], expansion_id)
    pkmn.item = item if item && pkmn.respond_to?(:item=)
    moves = Array(pkmn_data[:moves]).map { |move| resolve_external_move(move) }.compact
    if moves.empty?
      pkmn.reset_moves if pkmn.respond_to?(:reset_moves)
    else
      moves.each { |move| pkmn.learn_move(move) if pkmn.respond_to?(:learn_move) }
    end
    pkmn.ability_index = integer(pkmn_data[:ability_index], 0) if !pkmn_data[:ability_index].nil? && pkmn.respond_to?(:ability_index=)
    ability = resolve_external_ability(pkmn_data[:ability])
    pkmn.ability = ability if ability && pkmn.respond_to?(:ability=)
    gender = normalized_external_gender(pkmn_data[:gender])
    pkmn.gender = gender if !gender.nil? && pkmn.respond_to?(:gender=)
    pkmn.shiny = true if pkmn_data[:shininess] && pkmn.respond_to?(:shiny=)
    pkmn.super_shiny = true if pkmn_data[:super_shininess] && pkmn.respond_to?(:super_shiny=)
    nature = resolve_external_nature(pkmn_data[:nature])
    pkmn.nature = nature if nature && pkmn.respond_to?(:nature=)
    apply_external_ivs!(pkmn, pkmn_data[:iv], level)
    apply_external_evs!(pkmn, pkmn_data[:ev], level)
    pkmn.happiness = integer(pkmn_data[:happiness], pkmn.happiness) if !pkmn_data[:happiness].nil? && pkmn.respond_to?(:happiness=)
    pkmn.name = pkmn_data[:name] if !pkmn_data[:name].to_s.empty? && pkmn.respond_to?(:name=)
    if pkmn_data[:shadowness]
      begin
        pkmn.makeShadow if pkmn.respond_to?(:makeShadow)
        pkmn.update_shadow_moves(true) if pkmn.respond_to?(:update_shadow_moves)
        pkmn.shiny = false if pkmn.respond_to?(:shiny=)
      rescue => e
        log("Shadow trainer Pokemon setup failed for #{pkmn.name}: #{e.message}")
      end
    end
    ball = resolve_external_item(pkmn_data[:poke_ball], expansion_id)
    pkmn.poke_ball = ball if ball && pkmn.respond_to?(:poke_ball=)
    pkmn.calc_stats if pkmn.respond_to?(:calc_stats)
    return pkmn
  rescue => e
    log("Failed to build external trainer Pokemon #{pkmn_data[:species]}: #{e.class}: #{e.message}")
    return nil
  end

  def resolve_external_species(value, expansion_id = nil)
    identifier = external_identifier(value)
    return nil if identifier.nil?
    expansion = expansion_id.to_s
    if expansion == "pokemon_uranium" && respond_to?(:uranium_resolve_species)
      resolved = uranium_resolve_species(value) rescue nil
      data = GameData::Species.try_get(resolved) rescue nil
      return data.id if data
    elsif expansion == "xenoverse" && respond_to?(:xenoverse_resolve_species_reference)
      resolved = xenoverse_resolve_species_reference(value) rescue nil
      data = GameData::Species.try_get(resolved) rescue nil
      return data.id if data
    end
    if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:compatibility_alias_target)
      canonical = CustomSpeciesFramework.compatibility_alias_target(identifier) rescue nil
      if canonical
        data = GameData::Species.try_get(canonical) rescue nil
        return data.id if data
      end
    end
    data = GameData::Species.try_get(identifier) rescue nil
    return data.id if data
    return nil
  end

  def resolve_external_move(value)
    identifier = external_identifier(value)
    return nil if identifier.nil?
    data = GameData::Move.try_get(identifier) rescue nil
    return data.id if data
    return nil
  end

  def resolve_external_ability(value)
    identifier = external_identifier(value)
    return nil if identifier.nil?
    data = GameData::Ability.try_get(identifier) rescue nil
    return data.id if data
    return nil
  end

  def resolve_external_item(value, expansion_id = nil)
    identifier = external_identifier(value)
    return nil if identifier.nil?
    data = GameData::Item.try_get(identifier) rescue nil
    return data.id if data
    if !expansion_id.to_s.empty? && respond_to?(:ensure_external_item_registered)
      registered = ensure_external_item_registered(expansion_id, identifier) rescue nil
      data = GameData::Item.try_get(registered) rescue nil
      return data.id if data
      return registered if registered
    end
    return nil
  end

  def resolve_external_nature(value)
    identifier = external_identifier(value)
    return nil if identifier.nil?
    data = GameData::Nature.try_get(identifier) rescue nil
    return data.id if data
    return nil
  end

  def external_main_stat_ids
    stats = []
    if defined?(GameData::Stat) && GameData::Stat.respond_to?(:each_main)
      GameData::Stat.each_main do |stat|
        next if stat.nil?
        stats << (stat.respond_to?(:id) ? stat.id : stat)
      end
    end
    stats = [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED] if stats.empty?
    return stats
  rescue
    return [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED]
  end

  def external_iv_limit
    return Pokemon::IV_STAT_LIMIT if defined?(Pokemon::IV_STAT_LIMIT)
    return 31
  end

  def external_ev_limit
    return Pokemon::EV_LIMIT if defined?(Pokemon::EV_LIMIT)
    return 510
  end

  def clamp_external_stat_value(value, minimum, maximum)
    numeric = integer(value, minimum)
    numeric = minimum if numeric < minimum
    numeric = maximum if numeric > maximum
    return numeric
  end

  def apply_external_ivs!(pkmn, raw_ivs, level)
    limit = external_iv_limit
    fallback = [integer(level, 1) / 2, limit].min
    external_main_stat_ids.each_with_index do |stat_id, index|
      value = extract_external_stat_value(raw_ivs, stat_id, index, fallback)
      pkmn.iv[stat_id] = clamp_external_stat_value(value, 0, limit)
    end
  rescue => e
    log("Failed to apply trainer IVs for #{pkmn.species}: #{e.message}")
  end

  def apply_external_evs!(pkmn, raw_evs, level)
    per_stat_limit = external_ev_limit / 6
    fallback = [integer(level, 1) * 3 / 2, per_stat_limit].min
    external_main_stat_ids.each_with_index do |stat_id, index|
      value = extract_external_stat_value(raw_evs, stat_id, index, fallback)
      pkmn.ev[stat_id] = clamp_external_stat_value(value, 0, per_stat_limit)
    end
  rescue => e
    log("Failed to apply trainer EVs for #{pkmn.species}: #{e.message}")
  end

  def extract_external_stat_value(value, stat_id, index, fallback)
    return fallback if value.nil?
    if value.is_a?(Hash)
      return integer(value[stat_id] || value[stat_id.to_s] || value[index] || value[index.to_s], fallback)
    end
    if value.is_a?(Array)
      return integer(value[index], fallback)
    end
    return integer(value, fallback)
  end

  def normalized_external_gender(value)
    case value.to_s.strip.upcase
    when "M", "MALE", "0"
      return 0
    when "F", "FEMALE", "1"
      return 1
    when "N", "NONE", "2"
      return 2
    end
    return nil
  end

  def external_identifier(value)
    return value if value.is_a?(Symbol)
    return value if value.is_a?(Integer)
    if defined?(GameData::TrainerType) && value.is_a?(GameData::TrainerType)
      return value.id
    end
    if defined?(GameData::Trainer) && value.is_a?(GameData::Trainer)
      return value.id
    end
    text = value.to_s.strip
    return nil if text.empty?
    return text.to_sym
  rescue
    return nil
  end

  def resolve_pb_trainers_constant_value(name)
    raw = name.to_s.strip
    return nil if raw.empty?
    return nil if active_trainer_lookup_expansion_ids.empty?
    candidates = []
    candidates << raw
    candidates << raw.upcase if raw != raw.upcase
    candidates << raw.downcase if raw != raw.downcase
    candidates.uniq.each do |candidate|
      data = imported_trainer_type_data(candidate.to_sym)
      data ||= imported_trainer_type_data(candidate)
      next if !data.is_a?(Hash)
      id_number = integer(data[:id_number], 0)
      log("Resolved PBTrainers::#{name} -> #{id_number} (#{data[:id]})") if id_number > 0
      return id_number if id_number > 0
      return data[:id] if data[:id]
    end
    return nil
  rescue => e
    log("PBTrainers resolution failed for #{name}: #{e.class}: #{e.message}")
    return nil
  end

  def normalize_string_or_nil(value)
    text = value.to_s.strip
    return nil if text.empty?
    return text
  end

  def resolved_external_trainer_asset(expansion_id, type_data, key)
    return nil if !type_data.is_a?(Hash)
    logical = normalize_string_or_nil(type_data[key])
    return nil if logical.nil?
    if respond_to?(:resolve_runtime_path_for_expansion)
      resolved = resolve_runtime_path_for_expansion(expansion_id, logical, TRAINER_ASSET_EXTENSIONS)
      return resolved if resolved
    end
    return logical
  end

  def asset_basename_path(folder, filename)
    return nil if filename.nil? || filename.to_s.empty?
    base = File.basename(filename.to_s, File.extname(filename.to_s))
    return nil if base.empty?
    return "#{folder}/#{base}"
  end

  def first_existing_logical_asset(root, candidates)
    Array(candidates).each do |logical|
      next if logical.nil? || logical.to_s.empty?
      candidate = logical.to_s.gsub("\\", "/")
      ext = File.extname(candidate)
      if !ext.empty?
        absolute = File.join(root, candidate.gsub("/", File::SEPARATOR))
        return candidate if File.file?(absolute)
        next
      end
      TRAINER_ASSET_EXTENSIONS.each do |suffix|
        absolute = File.join(root, "#{candidate}#{suffix}".gsub("/", File::SEPARATOR))
        return candidate if File.file?(absolute)
      end
    end
    return nil
  end

  def imported_trainer_audio_name(trainer, key)
    trainer_array = trainer.is_a?(Array) ? trainer : [trainer]
    trainer_array.each do |entry|
      next if !entry || !entry.respond_to?(:travel_expansion_external_trainer_type_data)
      data = entry.travel_expansion_external_trainer_type_data
      next if !data.is_a?(Hash)
      name = normalize_string_or_nil(data[key])
      return name if name
    end
    return nil
  end
end

module GameData
  class TrainerType
    class << self
      alias_method :tef_imported_trainer_original_exists, :exists? if method_defined?(:exists?) && !method_defined?(:tef_imported_trainer_original_exists)
      alias_method :tef_imported_trainer_original_try_get, :try_get if method_defined?(:try_get) && !method_defined?(:tef_imported_trainer_original_try_get)
      alias_method :tef_imported_trainer_original_get, :get if method_defined?(:get) && !method_defined?(:tef_imported_trainer_original_get)
      alias_method :tef_imported_trainer_original_front_sprite_filename, :front_sprite_filename if method_defined?(:front_sprite_filename) && !method_defined?(:tef_imported_trainer_original_front_sprite_filename)
      alias_method :tef_imported_trainer_original_back_sprite_filename, :back_sprite_filename if method_defined?(:back_sprite_filename) && !method_defined?(:tef_imported_trainer_original_back_sprite_filename)
      alias_method :tef_imported_trainer_original_charset_filename, :charset_filename if method_defined?(:charset_filename) && !method_defined?(:tef_imported_trainer_original_charset_filename)

      def exists?(other)
        native = tef_imported_trainer_original_exists(other) if defined?(tef_imported_trainer_original_exists)
        return native if native && !TravelExpansionFramework.imported_trainer_runtime_identifier?(other) &&
                         TravelExpansionFramework.active_trainer_lookup_expansion_ids.empty?
        return true if TravelExpansionFramework.imported_trainer_type_known?(other)
        return native if !native.nil?
        return tef_imported_trainer_original_exists(other) if defined?(tef_imported_trainer_original_exists)
        return false
      end

      def try_get(other)
        if !TravelExpansionFramework.imported_trainer_runtime_identifier?(other) &&
           TravelExpansionFramework.active_trainer_lookup_expansion_ids.empty?
          return tef_imported_trainer_original_try_get(other) if defined?(tef_imported_trainer_original_try_get)
        end
        imported = TravelExpansionFramework.imported_trainer_game_data(other)
        return imported if imported
        return tef_imported_trainer_original_try_get(other) if defined?(tef_imported_trainer_original_try_get)
        return nil
      end

      def get(other)
        if !TravelExpansionFramework.imported_trainer_runtime_identifier?(other) &&
           TravelExpansionFramework.active_trainer_lookup_expansion_ids.empty?
          native = tef_imported_trainer_original_try_get(other) if defined?(tef_imported_trainer_original_try_get)
          return native if native
        end
        imported = TravelExpansionFramework.imported_trainer_game_data(other)
        return imported if imported
        if defined?(tef_imported_trainer_original_try_get)
          native = tef_imported_trainer_original_try_get(other)
          return native if native
        elsif defined?(tef_imported_trainer_original_get)
          native = tef_imported_trainer_original_get(other)
          return native if native
        end
        raise ArgumentError, "Unknown trainer type #{other.inspect}"
      end

      def front_sprite_filename(tr_type)
        data = TravelExpansionFramework.imported_trainer_type_data(tr_type)
        if data.is_a?(Hash)
          logical = TravelExpansionFramework.normalize_string_or_nil(data[:front_sprite])
          resolved = TravelExpansionFramework.resolve_runtime_path_for_expansion(data[:expansion_id], logical, TravelExpansionFramework::TRAINER_ASSET_EXTENSIONS) if logical
          return resolved if resolved
          return logical if logical && pbResolveBitmap(logical)
          logical = TravelExpansionFramework.normalize_string_or_nil(data[:overworld_sprite])
          resolved = TravelExpansionFramework.resolve_runtime_path_for_expansion(data[:expansion_id], logical, TravelExpansionFramework::TRAINER_ASSET_EXTENSIONS) if logical
          return resolved if resolved
          return logical if logical && pbResolveBitmap(logical)
        end
        return tef_imported_trainer_original_front_sprite_filename(tr_type) if defined?(tef_imported_trainer_original_front_sprite_filename)
        return nil
      end

      def back_sprite_filename(tr_type)
        data = TravelExpansionFramework.imported_trainer_type_data(tr_type)
        if data.is_a?(Hash)
          logical = TravelExpansionFramework.normalize_string_or_nil(data[:back_sprite])
          resolved = TravelExpansionFramework.resolve_runtime_path_for_expansion(data[:expansion_id], logical, TravelExpansionFramework::TRAINER_ASSET_EXTENSIONS) if logical
          return resolved if resolved
          return logical if logical && pbResolveBitmap(logical)
        end
        return tef_imported_trainer_original_back_sprite_filename(tr_type) if defined?(tef_imported_trainer_original_back_sprite_filename)
        return nil
      end

      def charset_filename(tr_type)
        data = TravelExpansionFramework.imported_trainer_type_data(tr_type)
        if data.is_a?(Hash)
          logical = TravelExpansionFramework.normalize_string_or_nil(data[:overworld_sprite])
          resolved = TravelExpansionFramework.resolve_runtime_path_for_expansion(data[:expansion_id], logical, TravelExpansionFramework::TRAINER_ASSET_EXTENSIONS) if logical
          return resolved if resolved
          return logical if logical && pbResolveBitmap(logical)
        end
        return tef_imported_trainer_original_charset_filename(tr_type) if defined?(tef_imported_trainer_original_charset_filename)
        return nil
      end
    end
  end
end

module TravelExpansionFramework
  module_function

  def forced_external_trainer_stack
    @forced_external_trainer_stack ||= []
    return @forced_external_trainer_stack
  end

  def external_trainer_lookup_keys(tr_type, tr_name, tr_version = 0)
    keys = []
    versions = [integer(tr_version, 0)]
    types = [tr_type]
    identifier = external_identifier(tr_type)
    types << identifier if !identifier.nil?
    names = [tr_name.to_s]
    normalized_name = normalize_string_or_nil(tr_name)
    names << normalized_name if normalized_name
    types.each do |type|
      names.each do |name|
        next if name.to_s.empty?
        versions.each do |version|
          key = [type, name, version]
          keys << key if !keys.include?(key)
        end
      end
    end
    return keys
  rescue
    return [[tr_type, tr_name.to_s, integer(tr_version, 0)]]
  end

  def with_forced_external_trainers(entries)
    mapping = {}
    Array(entries).each do |entry|
      next if !entry.is_a?(Hash)
      trainer = entry[:trainer]
      next if trainer.nil?
      external_trainer_lookup_keys(entry[:tr_type], entry[:tr_name], entry[:tr_version]).each do |key|
        mapping[key] = trainer
      end
    end
    return yield if mapping.empty?
    forced_external_trainer_stack << mapping
    return yield
  ensure
    forced_external_trainer_stack.pop if !mapping.nil? && !mapping.empty? && forced_external_trainer_stack.length > 0
  end

  def forced_external_trainer(tr_type, tr_name, tr_version = 0)
    keys = external_trainer_lookup_keys(tr_type, tr_name, tr_version)
    forced_external_trainer_stack.reverse_each do |mapping|
      keys.each do |key|
        trainer = mapping[key]
        return trainer if trainer
      end
    end
    return nil
  rescue
    return nil
  end

  def load_external_trainer_from_candidates(tr_type, tr_name, tr_version = 0, preferred_expansion_id = nil)
    active_trainer_lookup_expansion_ids(preferred_expansion_id).each do |expansion_id|
      imported = load_external_trainer(expansion_id, tr_type, tr_name, tr_version)
      return imported if imported
    end
    return nil
  end

  def run_imported_trainer_battle(imported, end_speech = nil,
                                  double_battle = false, can_lose = false, outcome_var = 1,
                                  name_override = nil, trainer_type_override = nil)
    return false if imported.nil?
    trainer = imported
    trainer.trainer_type = trainer_type_override if !trainer_type_override.nil? && trainer.respond_to?(:trainer_type=)
    trainer.name = name_override if !name_override.nil? && trainer.respond_to?(:name=)
    if end_speech && !end_speech.empty? && trainer.respond_to?(:lose_text=)
      expansion_id = external_trainer_expansion_id(trainer)
      trainer.lose_text = localized_external_trainer_text(expansion_id, end_speech)
    end

    if !$PokemonTemp.waitingTrainer && pbMapInterpreterRunning? &&
       ($Trainer.able_pokemon_count > 1 ||
       ($Trainer.able_pokemon_count > 0 && $PokemonGlobal.partner))
      this_event = pbMapInterpreter.get_character(0)
      triggered_events = $game_player.pbTriggeredTrainerEvents([2], false)
      other_event = []
      for event in triggered_events
        next if event.id == this_event.id
        next if $game_self_switches[[$game_map.map_id, event.id, "A"]]
        other_event.push(event)
      end
      Events.onTrainerPartyLoad.trigger(nil, trainer)
      if other_event.length == 1 && trainer.party.length <= Settings::MAX_PARTY_SIZE
        $PokemonTemp.waitingTrainer = [trainer, this_event.id]
        return false
      end
    end

    setBattleRule("outcomeVar", outcome_var) if outcome_var != 1
    setBattleRule("canLose") if can_lose
    setBattleRule("double") if double_battle || $PokemonTemp.waitingTrainer

    if $PokemonTemp.waitingTrainer
      decision = pbTrainerBattleCore($PokemonTemp.waitingTrainer[0], trainer)
    else
      Events.onTrainerPartyLoad.trigger(nil, trainer)
      decision = pbTrainerBattleCore(trainer)
    end

    if decision == 1 && $PokemonTemp.waitingTrainer
      pbMapInterpreter.pbSetSelfSwitch($PokemonTemp.waitingTrainer[1], "A", true)
    end
    $PokemonTemp.waitingTrainer = nil
    return (decision == 1)
  end

  def run_imported_double_trainer_battle(args)
    return false if !args.is_a?(Array) || args.length < 2
    setBattleRule("outcomeVar", args[2]) if args[2] != 1
    setBattleRule("canLose") if args[3]
    setBattleRule("double")
    trainers = [
      resolve_trainer_argument_for_battle(args[0]),
      resolve_trainer_argument_for_battle(args[1])
    ]
    if trainers.any? { |trainer| trainer.nil? }
      log("Imported double trainer battle could not resolve one or more trainers: #{args[0].inspect}, #{args[1].inspect}")
      return false
    end
    decision = pbTrainerBattleCore(trainers[0], trainers[1])
    return (decision == 1)
  end

  def run_imported_triple_trainer_battle(args)
    return false if !args.is_a?(Array) || args.length < 3
    setBattleRule("outcomeVar", args[3]) if args[3] != 1
    setBattleRule("canLose") if args[4]
    setBattleRule("triple")
    trainers = [
      resolve_trainer_argument_for_battle(args[0]),
      resolve_trainer_argument_for_battle(args[1]),
      resolve_trainer_argument_for_battle(args[2])
    ]
    if trainers.any? { |trainer| trainer.nil? }
      log("Imported triple trainer battle could not resolve one or more trainers: #{args[0].inspect}, #{args[1].inspect}, #{args[2].inspect}")
      return false
    end
    decision = pbTrainerBattleCore(trainers[0], trainers[1], trainers[2])
    return (decision == 1)
  end

  def resolve_trainer_argument_for_battle(arg)
    return arg if !arg.is_a?(Array) || arg.length < 3
    resolved = resolve_external_trainer_argument(arg)
    return resolved if !resolved.is_a?(Array)
    trainer = nil
    begin
      trainer = tef_original_pbLoadTrainer(arg[0], arg[1], arg[2]) if defined?(tef_original_pbLoadTrainer)
    rescue RuntimeError => e
      log("Host trainer fallback failed for mixed imported battle #{arg[0]}/#{arg[1]}/#{arg[2]}: #{e.message}")
    end
    if trainer && arg.length > 3 && !arg[3].to_s.empty? && trainer.respond_to?(:lose_text=)
      trainer.lose_text = arg[3]
    end
    return trainer
  rescue => e
    log("Trainer battle argument resolution failed for #{arg.inspect}: #{e.class}: #{e.message}")
    return nil
  end

  def resolve_external_trainer_argument(arg)
    return arg if !arg.is_a?(Array) || arg.length < 3
    forced = forced_external_trainer(arg[0], arg[1], arg[2])
    return forced if forced
    imported = load_external_trainer_from_candidates(arg[0], arg[1], arg[2])
    if imported && arg.length > 3 && !arg[3].to_s.empty? && imported.respond_to?(:lose_text=)
      expansion_id = external_trainer_expansion_id(imported)
      imported.lose_text = localized_external_trainer_text(expansion_id, arg[3])
    end
    log("Resolved imported trainer directly in pbTrainerBattleCore for #{arg[0]}/#{arg[1]}/#{arg[2]}") if imported
    return imported if imported
    return arg
  rescue
    return arg
  end

  def patch_imported_trainer_data_lookup!(trainer_class)
    singleton = class << trainer_class; self; end
    return if singleton.method_defined?(:tef_imported_trainer_data_original_try_get)
    singleton.class_eval do
      alias_method :tef_imported_trainer_data_original_exists, :exists?
      alias_method :tef_imported_trainer_data_original_try_get, :try_get
      alias_method :tef_imported_trainer_data_original_get, :get

      define_method(:exists?) do |tr_type, tr_name, tr_version = 0|
        proxy = TravelExpansionFramework.external_trainer_record_proxy(tr_type, tr_name, tr_version)
        return true if proxy
        return tef_imported_trainer_data_original_exists(tr_type, tr_name, tr_version)
      end

      define_method(:try_get) do |tr_type, tr_name, tr_version = 0|
        proxy = TravelExpansionFramework.external_trainer_record_proxy(tr_type, tr_name, tr_version)
        return proxy if proxy
        return tef_imported_trainer_data_original_try_get(tr_type, tr_name, tr_version)
      end

      define_method(:get) do |tr_type, tr_name, tr_version = 0|
        proxy = TravelExpansionFramework.external_trainer_record_proxy(tr_type, tr_name, tr_version)
        return proxy if proxy
        return tef_imported_trainer_data_original_get(tr_type, tr_name, tr_version)
      end
    end
  rescue => e
    TravelExpansionFramework.log("Failed to patch imported trainer lookup for #{trainer_class}: #{e.class}: #{e.message}")
  end
end

if defined?(TravelExpansionFramework)
  TravelExpansionFramework.log("012_TrainerCompatibility begin load from #{__FILE__}")
  TravelExpansionFramework.log(
    "012_TrainerCompatibility availability pbLoadTrainer=#{defined?(pbLoadTrainer).inspect} " \
    "pbTrainerBattleCore=#{defined?(pbTrainerBattleCore).inspect} " \
    "pbTrainerBattle=#{defined?(pbTrainerBattle).inspect} " \
    "pbDoubleTrainerBattle=#{defined?(pbDoubleTrainerBattle).inspect} " \
    "pbTripleTrainerBattle=#{defined?(pbTripleTrainerBattle).inspect} " \
    "pbMissingTrainer=#{defined?(pbMissingTrainer).inspect}"
  )
end

TravelExpansionFramework.patch_imported_trainer_data_lookup!(GameData::Trainer) if defined?(GameData::Trainer)
TravelExpansionFramework.patch_imported_trainer_data_lookup!(GameData::TrainerModern) if defined?(GameData::TrainerModern)
TravelExpansionFramework.patch_imported_trainer_data_lookup!(GameData::TrainerExpert) if defined?(GameData::TrainerExpert)

alias tef_original_pbLoadTrainer pbLoadTrainer if defined?(pbLoadTrainer) && !defined?(tef_original_pbLoadTrainer)
def pbLoadTrainer(tr_type, tr_name, tr_version = 0)
  begin
    active_ids = TravelExpansionFramework.active_trainer_lookup_expansion_ids
    map_expansion = TravelExpansionFramework.current_map_expansion_id if TravelExpansionFramework.respond_to?(:current_map_expansion_id)
    if !active_ids.empty? || !map_expansion.to_s.empty?
      TravelExpansionFramework.log("pbLoadTrainer start #{tr_type}/#{tr_name}/#{tr_version} map_expansion=#{map_expansion.inspect} candidates=#{active_ids.inspect}")
    end
  rescue
  end
  forced = TravelExpansionFramework.forced_external_trainer(tr_type, tr_name, tr_version)
  if forced
    TravelExpansionFramework.log("pbLoadTrainer satisfied by forced trainer #{tr_type}/#{tr_name}/#{tr_version}")
    return forced
  end
  imported = TravelExpansionFramework.load_external_trainer_from_candidates(tr_type, tr_name, tr_version)
  if imported
    TravelExpansionFramework.log("pbLoadTrainer satisfied by imported trainer #{tr_type}/#{tr_name}/#{tr_version}")
    return imported
  end
  trainer = nil
  original_error = nil
  begin
    trainer = tef_original_pbLoadTrainer(tr_type, tr_name, tr_version) if defined?(tef_original_pbLoadTrainer)
  rescue RuntimeError => e
    original_error = e
  end
  return trainer if trainer
  TravelExpansionFramework.active_trainer_lookup_expansion_ids.each do |expansion_id|
    imported = TravelExpansionFramework.load_external_trainer(expansion_id, tr_type, tr_name, tr_version)
    if imported
      TravelExpansionFramework.log("Loaded imported trainer #{tr_type}/#{tr_name}/#{tr_version} for #{expansion_id}")
      return imported
    end
  end
  TravelExpansionFramework.log("pbLoadTrainer no imported match for #{tr_type}/#{tr_name}/#{tr_version}")
  raise original_error if original_error
  return trainer
end

alias tef_original_pbTrainerBattleCore pbTrainerBattleCore if defined?(pbTrainerBattleCore) && !defined?(tef_original_pbTrainerBattleCore)
def pbTrainerBattleCore(*args)
  return nil if !defined?(tef_original_pbTrainerBattleCore)
  resolved_args = args.map { |arg| TravelExpansionFramework.resolve_external_trainer_argument(arg) }
  return tef_original_pbTrainerBattleCore(*resolved_args)
end

alias tef_original_pbTrainerBattle pbTrainerBattle if defined?(pbTrainerBattle) && !defined?(tef_original_pbTrainerBattle)
def pbTrainerBattle(trainerID, trainerName, endSpeech=nil,
                    doubleBattle=false, trainerPartyID=0, canLose=false, outcomeVar=1,
                    name_override=nil, trainer_type_overide=nil)
  return false if !defined?(tef_original_pbTrainerBattle)
  imported = TravelExpansionFramework.load_external_trainer_from_candidates(trainerID, trainerName, trainerPartyID)
  return tef_original_pbTrainerBattle(trainerID, trainerName, endSpeech,
                                      doubleBattle, trainerPartyID, canLose, outcomeVar,
                                      name_override, trainer_type_overide) if !imported
  TravelExpansionFramework.log("Running imported trainer battle directly for #{trainerID}/#{trainerName}/#{trainerPartyID}")
  return TravelExpansionFramework.run_imported_trainer_battle(
    imported, endSpeech, doubleBattle, canLose, outcomeVar, name_override, trainer_type_overide
  )
end

alias tef_original_pbDoubleTrainerBattle pbDoubleTrainerBattle if defined?(pbDoubleTrainerBattle) && !defined?(tef_original_pbDoubleTrainerBattle)
def pbDoubleTrainerBattle(trainerID1, trainerName1, trainerPartyID1, endSpeech1,
                          trainerID2, trainerName2, trainerPartyID2=0, endSpeech2=nil,
                          canLose=false, outcomeVar=1)
  return false if !defined?(tef_original_pbDoubleTrainerBattle)
  imported1 = TravelExpansionFramework.load_external_trainer_from_candidates(trainerID1, trainerName1, trainerPartyID1)
  imported2 = TravelExpansionFramework.load_external_trainer_from_candidates(trainerID2, trainerName2, trainerPartyID2)
  return tef_original_pbDoubleTrainerBattle(trainerID1, trainerName1, trainerPartyID1, endSpeech1,
                                            trainerID2, trainerName2, trainerPartyID2, endSpeech2,
                                            canLose, outcomeVar) if imported1.nil? && imported2.nil?
  TravelExpansionFramework.log("Running imported double trainer battle directly for #{trainerID1}/#{trainerName1}/#{trainerPartyID1} and #{trainerID2}/#{trainerName2}/#{trainerPartyID2}")
  arg1 = imported1 || [trainerID1, trainerName1, trainerPartyID1, endSpeech1]
  arg2 = imported2 || [trainerID2, trainerName2, trainerPartyID2, endSpeech2]
  return TravelExpansionFramework.run_imported_double_trainer_battle([arg1, arg2, outcomeVar, canLose])
end

alias tef_original_pbTripleTrainerBattle pbTripleTrainerBattle if defined?(pbTripleTrainerBattle) && !defined?(tef_original_pbTripleTrainerBattle)
def pbTripleTrainerBattle(trainerID1, trainerName1, trainerPartyID1, endSpeech1,
                          trainerID2, trainerName2, trainerPartyID2, endSpeech2,
                          trainerID3, trainerName3, trainerPartyID3=0, endSpeech3=nil,
                          canLose=false, outcomeVar=1)
  return false if !defined?(tef_original_pbTripleTrainerBattle)
  imported1 = TravelExpansionFramework.load_external_trainer_from_candidates(trainerID1, trainerName1, trainerPartyID1)
  imported2 = TravelExpansionFramework.load_external_trainer_from_candidates(trainerID2, trainerName2, trainerPartyID2)
  imported3 = TravelExpansionFramework.load_external_trainer_from_candidates(trainerID3, trainerName3, trainerPartyID3)
  if imported1.nil? && imported2.nil? && imported3.nil?
    return tef_original_pbTripleTrainerBattle(trainerID1, trainerName1, trainerPartyID1, endSpeech1,
                                              trainerID2, trainerName2, trainerPartyID2, endSpeech2,
                                              trainerID3, trainerName3, trainerPartyID3, endSpeech3,
                                              canLose, outcomeVar)
  end
  TravelExpansionFramework.log("Running imported triple trainer battle directly for #{trainerID1}/#{trainerName1}/#{trainerPartyID1}, #{trainerID2}/#{trainerName2}/#{trainerPartyID2}, #{trainerID3}/#{trainerName3}/#{trainerPartyID3}")
  arg1 = imported1 || [trainerID1, trainerName1, trainerPartyID1, endSpeech1]
  arg2 = imported2 || [trainerID2, trainerName2, trainerPartyID2, endSpeech2]
  arg3 = imported3 || [trainerID3, trainerName3, trainerPartyID3, endSpeech3]
  return TravelExpansionFramework.run_imported_triple_trainer_battle([arg1, arg2, arg3, outcomeVar, canLose])
end

alias tef_original_pbGetTrainerBattleBGM pbGetTrainerBattleBGM if defined?(pbGetTrainerBattleBGM) && !defined?(tef_original_pbGetTrainerBattleBGM)
def pbGetTrainerBattleBGM(trainer)
  imported = TravelExpansionFramework.imported_trainer_audio_name(trainer, :battle_BGM)
  return pbStringToAudioFile(imported) if imported
  return nil if !defined?(tef_original_pbGetTrainerBattleBGM)
  return tef_original_pbGetTrainerBattleBGM(trainer)
end

alias tef_original_pbMissingTrainer pbMissingTrainer if defined?(pbMissingTrainer) && !defined?(tef_original_pbMissingTrainer)
def pbMissingTrainer(tr_type, tr_name, tr_version)
  expansion = nil
  candidates = []
  probe = nil
  begin
    map_id = ($game_map && $game_map.respond_to?(:map_id)) ? $game_map.map_id : nil
    expansion = TravelExpansionFramework.current_map_expansion_id(map_id) if TravelExpansionFramework.respond_to?(:current_map_expansion_id)
    candidates = TravelExpansionFramework.active_trainer_lookup_expansion_ids
    probe = TravelExpansionFramework.load_external_trainer_from_candidates(tr_type, tr_name, tr_version)
    TravelExpansionFramework.log("pbMissingTrainer #{tr_type}/#{tr_name}/#{tr_version} map_id=#{map_id.inspect} expansion=#{expansion.inspect} candidates=#{candidates.inspect} imported_probe=#{!probe.nil?}")
  rescue => e
    TravelExpansionFramework.log("pbMissingTrainer logging failed for #{tr_type}/#{tr_name}/#{tr_version}: #{e.class}: #{e.message}")
  end
  if !expansion.to_s.empty? || !Array(candidates).empty? || probe
    TravelExpansionFramework.log("Suppressed host missing trainer dialog for expansion trainer #{tr_type}/#{tr_name}/#{tr_version}") if TravelExpansionFramework.respond_to?(:log)
    return 1
  end
  return 1 if !defined?(tef_original_pbMissingTrainer)
  return tef_original_pbMissingTrainer(tr_type, tr_name, tr_version)
end

if defined?(OverworldBattleAliases)
  class << OverworldBattleAliases
    if method_defined?(:coop_trainer_original_pbTrainerBattle) &&
       !method_defined?(:tef_imported_coop_trainer_original_pbTrainerBattle)
      alias tef_imported_coop_trainer_original_pbTrainerBattle coop_trainer_original_pbTrainerBattle

      def coop_trainer_original_pbTrainerBattle(trainerID, trainerName, endSpeech=nil,
                                               doubleBattle=false, trainerPartyID=0, canLose=false, outcomeVar=1,
                                               name_override=nil, trainer_type_override=nil)
        imported = TravelExpansionFramework.load_external_trainer_from_candidates(trainerID, trainerName, trainerPartyID)
        if imported
          TravelExpansionFramework.log("Multiplayer fallback path resolved imported trainer #{trainerID}/#{trainerName}/#{trainerPartyID}")
          return TravelExpansionFramework.run_imported_trainer_battle(
            imported, endSpeech, doubleBattle, canLose, outcomeVar, name_override, trainer_type_override
          )
        end
        return tef_imported_coop_trainer_original_pbTrainerBattle(
          trainerID, trainerName, endSpeech, doubleBattle, trainerPartyID, canLose, outcomeVar,
          name_override, trainer_type_override
        )
      end
    end
  end
end

if defined?(PBTrainers)
  class << PBTrainers
    if !method_defined?(:tef_original_const_missing)
      alias tef_original_const_missing const_missing if method_defined?(:const_missing)
    end

    def const_missing(name)
      resolved = TravelExpansionFramework.resolve_pb_trainers_constant_value(name)
      return resolved if !resolved.nil?
      return tef_original_const_missing(name) if defined?(tef_original_const_missing)
      raise NameError, "uninitialized constant PBTrainers::#{name}"
    end
  end
end

TravelExpansionFramework.log("012_TrainerCompatibility loaded from #{__FILE__}")
