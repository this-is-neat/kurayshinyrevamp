if defined?(Pokemon)
  class Pokemon
    attr_accessor :tef_dormant_species_reference
    attr_accessor :tef_dormant_item_reference
  end
end

module TravelExpansionFramework
  module_function

  def write_json_report(filename, data)
    ensure_report_dir
    path = File.join(report_dir, filename)
    File.open(path, "wb") { |file| file.write(safe_json_dump(data)) }
    return path
  rescue => e
    log("Report write failed for #{filename}: #{e.message}")
    return nil
  end

  def manifest_template_hash
    return {
      "schema_version" => 1,
      "id"             => "your_expansion_id",
      "name"           => "Your Expansion Name",
      "namespace"      => "your_expansion_namespace",
      "version"        => "0.1.0",
      "author"         => "Author Name",
      "asset_roots"    => ["assets"],
      "map_block"      => {
        "start" => 21000,
        "size"  => 1000
      },
      "maps" => {
        "files" => [
          {
            "id"       => "entry_map",
            "local_id" => 1,
            "path"     => "maps/Map001.rxdata",
            "name"     => "Entry Map"
          }
        ]
      },
      "travel_nodes" => [
        {
          "id"            => "entry",
          "name"          => "Entry Point",
          "description"   => "Travel into the expansion pack.",
          "local_map_id"  => 1,
          "position_mode" => "fixed",
          "x"             => 0,
          "y"             => 0,
          "direction"     => 2,
          "mode_options"  => ["shared"]
        }
      ],
      "badges" => {
        "pages" => [
          {
            "id"         => "region_badges",
            "name"       => "Region Badges",
            "slot_count" => 8
          }
        ]
      },
      "dex" => {
        "pages" => [
          {
            "id"      => "region_dex",
            "name"    => "Region Dex",
            "species" => []
          }
        ]
      },
      "quests" => {
        "definitions" => []
      },
      "variants" => {
        "aliases"        => [],
        "transfer_rules" => []
      },
      "migrations" => []
    }
  end

  def build_conflict_report
    block_ranges = []
    duplicate_maps = {}
    registry(:maps).each do |virtual_id, entry|
      duplicate_maps[virtual_id] ||= []
      duplicate_maps[virtual_id] << entry[:expansion_id]
    end
    registry(:expansions).each_value do |manifest|
      start_id = manifest[:map_block][:start]
      end_id = start_id + manifest[:map_block][:size] - 1
      block_ranges << {
        "expansion_id" => manifest[:id],
        "start"        => start_id,
        "end"          => end_id
      }
    end
    overlaps = []
    block_ranges.combination(2) do |left, right|
      next if left["end"] < right["start"] || right["end"] < left["start"]
      overlaps << {
        "left"  => left,
        "right" => right
      }
    end
    return {
      "generated_at"           => timestamp_string,
      "active_expansions"      => active_expansion_ids,
      "installed_expansions"   => expansion_ids,
      "map_block_overlaps"     => overlaps,
      "duplicate_virtual_maps" => duplicate_maps.find_all { |_virtual_id, entries| entries.length > 1 }.to_h,
      "disabled_expansions"    => expansion_ids - active_expansion_ids
    }
  end

  def build_external_project_report
    config = source_config
    projects = external_projects.transform_values { |info| external_project_report_entry(info) }
    return {
      "generated_at"  => timestamp_string,
      "search_roots"  => Array(config["search_roots"]).map { |entry| normalize_path(entry, current_game_root) }.compact.uniq,
      "projects"      => projects
    }
  end

  def simulate_uninstall(expansion_id)
    expansion_id = expansion_id.to_s
    manifest = manifest_for(expansion_id)
    state = state_for(expansion_id)
    current_map_reference = current_map_expansion_id == expansion_id
    result = {
      "generated_at"      => timestamp_string,
      "expansion_id"      => expansion_id,
      "installed"         => !manifest.nil?,
      "active"            => expansion_active?(expansion_id),
      "current_map_owned" => current_map_reference,
      "player_relocation" => current_map_reference ? default_host_anchor : nil,
      "badge_pages"       => manifest ? manifest[:badge_pages].length : 0,
      "badge_progress"    => expansion_badge_count(expansion_id),
      "dex_seen"          => dex_seen_count(expansion_id),
      "dex_owned"         => dex_owned_count(expansion_id),
      "dormant_refs"      => Array(state.dormant_references).length
    }
    write_json_report("uninstall_simulation_#{expansion_id}.json", result)
    return result
  end

  def run_smoke_tests
    tests = []
    tests << {
      "name"   => "framework_bootstrapped",
      "passed" => runtime_bootstrapped?,
      "detail" => "Framework bootstrap completed."
    }
    tests << {
      "name"   => "save_root_ready",
      "passed" => ensure_save_root.is_a?(SaveRoot),
      "detail" => "Expansion save root is registered and available."
    }
    tests << {
      "name"   => "manifest_template_available",
      "passed" => File.file?(File.expand_path("./Mods/travel_expansion_framework/templates/expansion_manifest.template.json")),
      "detail" => "Manifest template exists for pack authors."
    }
    tests << {
      "name"   => "source_config_available",
      "passed" => File.file?(source_config_path),
      "detail" => "External install scan roots are configurable through the source config file."
    }
    tests << {
      "name"   => "sample_pack_registered",
      "passed" => !manifest_for("sample_annex").nil?,
      "detail" => "Sample expansion manifest was discovered."
    }
    tests << {
      "name"   => "sample_pack_travel_node",
      "passed" => travelable_nodes.any? { |node| node[:expansion_id] == "sample_annex" },
      "detail" => "At least one bedroom-PC travel node is available."
    }
    tests << {
      "name"   => "player_progress_helpers",
      "passed" => !defined?($Trainer) || ($Trainer.respond_to?(:badge_pages) && $Trainer.respond_to?(:global_badge_count)),
      "detail" => "Player exposes expansion-aware trainer-card helpers."
    }
    tests << {
      "name"   => "external_project_registry_ready",
      "passed" => external_projects.is_a?(Hash),
      "detail" => "Detected external installs are tracked in a dedicated registry."
    }
    write_json_report("smoke_test_report.json", {
      "generated_at" => timestamp_string,
      "tests"        => tests
    })
    return tests
  end

  def write_registry_snapshot
    snapshot = {
      "generated_at"  => timestamp_string,
      "expansions"    => registry(:expansions).transform_values { |manifest|
        {
          "name"         => manifest[:name],
          "version"      => manifest[:version],
          "enabled"      => manifest[:enabled],
          "source_type"  => manifest[:source_type] || "managed_mod",
          "map_block"    => manifest[:map_block],
          "maps"         => manifest[:map_files].map { |entry| { "virtual_id" => entry[:virtual_id], "path" => entry[:path], "name" => entry[:name] } },
          "travel_nodes" => manifest[:travel_nodes].map { |node| { "id" => node[:id], "entry_map_id" => node[:entry_map_id], "position_mode" => node[:position_mode] } }
        }
      },
      "external_projects" => external_projects.transform_values { |info|
        external_project_report_entry(info)
      }
    }
    write_json_report("registry_snapshot.json", snapshot)
  end

  def prepare_after_load!
    return if @after_load_prepared
    bootstrap! if !runtime_bootstrapped?
    previous_signature = Array(ensure_save_root.enabled_signature).map { |id| id.to_s }
    current_signature = current_enabled_signature
    ensure_save_root.missing_expansions = previous_signature - current_signature
    repair_current_map_reference!
    clear_stale_expansion_interpreters!("after_load") if respond_to?(:clear_stale_expansion_interpreters!)
    scan_disabled_content_references!(ensure_save_root.missing_expansions)
    repair_missing_pokemon_references!
    restore_dormant_item_references!
    repair_missing_item_references!
    rebuild_host_dex_shadow_from_storage! if respond_to?(:rebuild_host_dex_shadow_from_storage!)
    restore_host_dex_shadow_to_player! if respond_to?(:restore_host_dex_shadow_to_player!)
    ensure_save_root.release_last_safe_load_at = timestamp_string if ensure_save_root.respond_to?(:release_last_safe_load_at=)
    write_release_index_report! if respond_to?(:write_release_index_report!)
    ensure_save_root.enabled_signature = current_signature
    @after_load_prepared = true
  end

  def repair_current_map_reference!
    map_id = nil
    map_id = $game_player.map_id if !map_id && $game_player && $game_player.respond_to?(:map_id)
    map_id = $game_map.map_id if !map_id && $game_map
    expansion_id = current_map_expansion_id(map_id)
    return if !expansion_id
    return if expansion_active?(expansion_id)
    anchor = default_host_anchor
    record_dormant_reference({
      "type"         => "player_map",
      "expansion_id" => expansion_id,
      "map_id"       => map_id,
      "timestamp"    => timestamp_string
    })
    ensure_save_root.player_relocation_log << {
      "from"      => map_id,
      "to"        => anchor[:map_id],
      "timestamp" => timestamp_string
    }
    if $PokemonGlobal
      $PokemonGlobal.tef_missing_expansion_warnings ||= []
      $PokemonGlobal.tef_missing_expansion_warnings << expansion_id unless $PokemonGlobal.tef_missing_expansion_warnings.include?(expansion_id)
      $PokemonGlobal.tef_current_expansion_id = nil
    end
    return rebuild_host_anchor_for_load!(anchor, "missing expansion #{expansion_id}") if respond_to?(:rebuild_host_anchor_for_load!)
    $MapFactory = PokemonMapFactory.new(anchor[:map_id])
    if $game_player
      $game_player.moveto(anchor[:x], anchor[:y])
    end
  end

  def each_saved_pokemon
    if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:party)
      $Trainer.party.each_with_index do |pokemon, index|
        yield(pokemon, "party:#{index}") if block_given?
      end
    end
    if defined?($PokemonStorage) && $PokemonStorage
      for box_index in 0...$PokemonStorage.maxBoxes
        for slot_index in 0...PokemonBox::BOX_SIZE
          pokemon = $PokemonStorage[box_index, slot_index]
          yield(pokemon, "box:#{box_index}:#{slot_index}") if pokemon && block_given?
        end
      end
    end
  rescue => e
    log("Pokemon reference scan failed: #{e.message}")
  end

  def pokemon_reference_value(value)
    return nil if value.nil?
    return value.id.to_s if value.respond_to?(:id)
    return value.to_s
  rescue
    return value.inspect
  end

  def value_from_pokemon_reference(value)
    return nil if value.nil?
    return value if value.is_a?(Symbol) || value.is_a?(Integer)
    text = value.to_s
    return nil if text.empty?
    return text.to_i if text =~ /\A\d+\z/
    return text.to_sym
  rescue
    return nil
  end

  def save_species_available?(species)
    return false if species.nil?
    if defined?(CustomSpeciesFramework) &&
       CustomSpeciesFramework.respond_to?(:active?) &&
       CustomSpeciesFramework.active? &&
       CustomSpeciesFramework.respond_to?(:species_reference_valid?)
      return true if CustomSpeciesFramework.species_reference_valid?(species, true)
    end
    return false if !defined?(GameData::Species::DATA) || !GameData::Species::DATA.is_a?(Hash)
    query = species.is_a?(String) ? species.to_sym : species
    return true if GameData::Species::DATA.has_key?(query)
    return true if species.is_a?(Integer) && GameData::Species::DATA.has_key?(species)
    return false
  rescue
    return false
  end

  def safe_missing_species_id
    if defined?(CustomSpeciesFramework) && defined?(CustomSpeciesFramework::MISSING_SPECIES_ID)
      fallback = CustomSpeciesFramework::MISSING_SPECIES_ID
      return fallback if save_species_available?(fallback)
    end
    return :PIKACHU if save_species_available?(:PIKACHU)
    if defined?(GameData::Species::DATA) && GameData::Species::DATA.is_a?(Hash)
      entry = GameData::Species::DATA.values.find { |value| value.respond_to?(:id) || value.respond_to?(:species) }
      return entry.id if entry.respond_to?(:id)
      return entry.species if entry.respond_to?(:species)
    end
    return nil
  rescue
    return nil
  end

  def pokemon_save_snapshot(pokemon, location)
    moves = []
    if pokemon.respond_to?(:moves)
      moves = Array(pokemon.moves).map { |move| pokemon_reference_value(move.respond_to?(:id) ? move.id : move) }
    end
    {
      "location"      => location.to_s,
      "species"       => pokemon_reference_value(pokemon.respond_to?(:species) ? pokemon.species : nil),
      "form"          => pokemon.respond_to?(:form) ? pokemon.form : nil,
      "forced_form"   => pokemon.respond_to?(:forced_form) ? pokemon.forced_form : nil,
      "level"         => pokemon.respond_to?(:level) ? pokemon.level : nil,
      "item"          => pokemon.respond_to?(:item_id) ? pokemon_reference_value(pokemon.item_id) : nil,
      "name"          => pokemon.respond_to?(:name) ? pokemon.name.to_s : nil,
      "moves"         => moves,
      "obtain_method" => pokemon.respond_to?(:obtain_method) ? pokemon.obtain_method : nil,
      "obtain_map"    => pokemon.respond_to?(:obtain_map) ? pokemon.obtain_map : nil,
      "obtain_level"  => pokemon.respond_to?(:obtain_level) ? pokemon.obtain_level : nil,
      "obtain_text"   => pokemon.respond_to?(:obtain_text) ? pokemon.obtain_text.to_s : nil
    }
  rescue
    { "location" => location.to_s }
  end

  def pokemon_dormant_reference(pokemon, attr_name, ivar_name)
    return nil if !pokemon
    return pokemon.send(attr_name) if pokemon.respond_to?(attr_name)
    return pokemon.instance_variable_get(ivar_name) if pokemon.instance_variable_defined?(ivar_name)
    return nil
  rescue
    return nil
  end

  def clear_pokemon_dormant_reference!(pokemon, writer_name, ivar_name)
    if pokemon.respond_to?(writer_name)
      pokemon.send(writer_name, nil)
    elsif pokemon.instance_variable_defined?(ivar_name)
      pokemon.instance_variable_set(ivar_name, nil)
    end
  rescue
  end

  def restore_dormant_pokemon_species!(pokemon, location)
    reference = pokemon_dormant_reference(pokemon, :tef_dormant_species_reference, :@tef_dormant_species_reference)
    reference ||= pokemon_dormant_reference(pokemon, :csf_dormant_species_reference, :@csf_dormant_species_reference)
    return false if !reference.is_a?(Hash)
    species = value_from_pokemon_reference(reference["species"] || reference[:species])
    return false if species.nil? || !save_species_available?(species)
    pokemon.species = species if pokemon.respond_to?(:species=)
    restored_form = reference["forced_form"] || reference[:forced_form] || reference["form"] || reference[:form]
    pokemon.forced_form = restored_form if pokemon.respond_to?(:forced_form=) && !restored_form.nil?
    pokemon.calc_stats rescue nil
    clear_pokemon_dormant_reference!(pokemon, :tef_dormant_species_reference=, :@tef_dormant_species_reference)
    clear_pokemon_dormant_reference!(pokemon, :csf_dormant_species_reference=, :@csf_dormant_species_reference)
    record_dormant_reference({
      "type"      => "pokemon_species_restored",
      "location"  => location.to_s,
      "species"   => pokemon_reference_value(species),
      "timestamp" => timestamp_string
    })
    return true
  rescue => e
    log("[save] dormant pokemon species restore failed at #{location}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def preserve_missing_pokemon_species!(pokemon, location)
    fallback = safe_missing_species_id
    return false if pokemon.nil? || fallback.nil?
    original_species = pokemon.respond_to?(:species) ? pokemon.species : nil
    return false if original_species.nil? || original_species == fallback
    snapshot = pokemon_save_snapshot(pokemon, location)
    pokemon.tef_dormant_species_reference = snapshot if pokemon.respond_to?(:tef_dormant_species_reference=)
    record_dormant_reference({
      "type"      => "pokemon_species",
      "location"  => location.to_s,
      "species"   => pokemon_reference_value(original_species),
      "snapshot"  => snapshot,
      "timestamp" => timestamp_string
    })
    pokemon.species = fallback if pokemon.respond_to?(:species=)
    pokemon.calc_stats rescue nil
    log("[save] replaced missing pokemon species #{original_species.inspect} at #{location} with #{fallback.inspect}") if respond_to?(:log)
    return true
  rescue => e
    log("[save] missing pokemon species repair failed at #{location}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def restore_dormant_pokemon_item!(pokemon, location)
    reference = pokemon_dormant_reference(pokemon, :tef_dormant_item_reference, :@tef_dormant_item_reference)
    reference ||= pokemon_dormant_reference(pokemon, :csf_dormant_item_reference, :@csf_dormant_item_reference)
    return false if !reference.is_a?(Hash)
    item = item_from_dormant_value(reference["item"] || reference[:item])
    return false if !save_item_available?(item)
    pokemon.item = item if pokemon.respond_to?(:item=)
    clear_pokemon_dormant_reference!(pokemon, :tef_dormant_item_reference=, :@tef_dormant_item_reference)
    clear_pokemon_dormant_reference!(pokemon, :csf_dormant_item_reference=, :@csf_dormant_item_reference)
    record_dormant_reference({
      "type"      => "held_item_restored",
      "location"  => location.to_s,
      "item"      => dormant_item_value(item),
      "timestamp" => timestamp_string
    })
    return true
  rescue => e
    log("[save] dormant held item restore failed at #{location}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def repair_missing_pokemon_item!(pokemon, location)
    return false if pokemon.nil? || !pokemon.respond_to?(:item_id)
    restore_dormant_pokemon_item!(pokemon, location)
    item = pokemon.item_id
    return false if item.nil? || save_item_available?(item)
    snapshot = pokemon_save_snapshot(pokemon, location)
    reference = {
      "type"      => "held_item",
      "location"  => location.to_s,
      "item"      => dormant_item_value(item),
      "snapshot"  => snapshot,
      "timestamp" => timestamp_string
    }
    pokemon.tef_dormant_item_reference = reference if pokemon.respond_to?(:tef_dormant_item_reference=)
    record_dormant_reference(reference)
    pokemon.instance_variable_set(:@item, nil)
    pokemon.mail = nil if pokemon.respond_to?(:mail=)
    log("[save] removed missing held item #{item.inspect} at #{location}") if respond_to?(:log)
    return true
  rescue => e
    log("[save] missing held item repair failed at #{location}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def repair_missing_pokemon_references!
    each_saved_pokemon do |pokemon, location|
      next if !pokemon
      restore_dormant_pokemon_species!(pokemon, location)
      repair_missing_pokemon_item!(pokemon, location)
      species = pokemon.respond_to?(:species) ? pokemon.species : nil
      next if species.nil? || save_species_available?(species)
      preserve_missing_pokemon_species!(pokemon, location)
    end
  rescue => e
    log("[save] pokemon reference repair failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def scan_disabled_content_references!(disabled_ids)
    disabled = Array(disabled_ids).map { |id| id.to_s }
    return if disabled.empty?
    each_saved_pokemon do |pokemon, location|
      next if !pokemon
      next if !pokemon.respond_to?(:tef_origin_expansion_id)
      expansion_id = pokemon.tef_origin_expansion_id.to_s
      next if expansion_id.empty? || !disabled.include?(expansion_id)
      record_dormant_reference({
        "type"         => "pokemon",
        "expansion_id" => expansion_id,
        "location"     => location,
        "species"      => pokemon.species.to_s,
        "timestamp"    => timestamp_string
      })
    end
  end

  def dormant_item_value(value)
    return nil if value.nil?
    return value.id.to_s if value.respond_to?(:id)
    return value.to_s
  rescue
    return value.inspect
  end

  def item_from_dormant_value(value)
    return nil if value.nil?
    return value if value.is_a?(Symbol) || value.is_a?(Integer)
    text = value.to_s
    return nil if text.empty?
    return text.to_i if text =~ /\A\d+\z/
    return text.to_sym
  rescue
    return nil
  end

  def save_item_available?(item)
    return false if item.nil? || !defined?(GameData::Item)
    return !GameData::Item.try_get(item).nil?
  rescue
    return false
  end

  def record_missing_item_reference!(type, location, item, quantity = 1, extra = {})
    reference = {
      "type"      => type.to_s,
      "location"  => location.to_s,
      "item"      => dormant_item_value(item),
      "quantity"  => [integer(quantity, 1), 1].max,
      "timestamp" => timestamp_string
    }
    extra.each_pair { |key, value| reference[key.to_s] = value } if extra.is_a?(Hash)
    record_dormant_reference(reference)
    log("[save] removed missing #{type} #{reference['item']} x#{reference['quantity']} from #{location}") if respond_to?(:log)
    return reference
  rescue => e
    log("[save] failed to record missing item #{item.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def each_raw_bag_item_slot
    return if !defined?($PokemonBag) || !$PokemonBag
    pockets = $PokemonBag.instance_variable_get(:@pockets) rescue nil
    pockets ||= $PokemonBag.pockets rescue nil
    return if !pockets.respond_to?(:each_with_index)
    pockets.each_with_index do |pocket, pocket_index|
      next if !pocket.respond_to?(:each_with_index)
      pocket.each_with_index do |slot, slot_index|
        next if !slot || !slot.respond_to?(:[])
        yield(pocket, pocket_index, slot_index, slot) if block_given?
      end
    end
  rescue => e
    log("[save] bag item scan failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def each_pc_item_slot
    return if !$PokemonGlobal || !$PokemonGlobal.respond_to?(:pcItemStorage)
    storage = $PokemonGlobal.pcItemStorage
    return if !storage || !storage.respond_to?(:items)
    storage.items.each_with_index do |slot, slot_index|
      next if !slot || !slot.respond_to?(:[])
      yield(storage.items, slot_index, slot) if block_given?
    end
  rescue => e
    log("[save] PC item scan failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def restore_dormant_item_references!
    root = ensure_save_root
    Array(root.dormant_references).each do |entry|
      next if !entry.is_a?(Hash)
      next if entry["restored_at"] || entry[:restored_at]
      type = (entry["type"] || entry[:type]).to_s
      next if type != "bag_item" && type != "pc_item"
      item = item_from_dormant_value(entry["item"] || entry[:item])
      quantity = [integer(entry["quantity"] || entry[:quantity], 1), 1].max
      next if !save_item_available?(item)
      restored = false
      if type == "bag_item" && defined?($PokemonBag) && $PokemonBag
        restored = $PokemonBag.pbCanStore?(item, quantity) && $PokemonBag.pbStoreItem(item, quantity)
      elsif type == "pc_item" && $PokemonGlobal && $PokemonGlobal.respond_to?(:pcItemStorage)
        $PokemonGlobal.pcItemStorage ||= PCItemStorage.new if defined?(PCItemStorage)
        storage = $PokemonGlobal.pcItemStorage
        restored = storage && storage.pbCanStore?(item, quantity) && storage.pbStoreItem(item, quantity)
      end
      if restored
        entry["restored_at"] = timestamp_string
        log("[save] restored dormant #{type} #{entry['item']} x#{quantity}") if respond_to?(:log)
      end
    end
  rescue => e
    log("[save] dormant item restore failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def repair_missing_bag_items!
    changed = false
    each_raw_bag_item_slot do |pocket, pocket_index, slot_index, slot|
      item = slot[0]
      quantity = slot[1]
      next if item.nil? || save_item_available?(item)
      record_missing_item_reference!("bag_item", "bag:#{pocket_index}:#{slot_index}", item, quantity)
      pocket[slot_index] = nil
      changed = true
    end
    if defined?($PokemonBag) && $PokemonBag
      pockets = $PokemonBag.instance_variable_get(:@pockets) rescue nil
      Array(pockets).each { |pocket| pocket.compact! if pocket.respond_to?(:compact!) } if changed
      registered = $PokemonBag.instance_variable_get(:@registeredItems) rescue nil
      if registered.respond_to?(:each_with_index)
        registered.each_with_index do |item, index|
          next if item.nil? || save_item_available?(item)
          record_missing_item_reference!("registered_item", "registered:#{index}", item, 1)
          registered[index] = nil
        end
        registered.compact!
      end
    end
  rescue => e
    log("[save] missing bag item repair failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def repair_missing_pc_items!
    changed = false
    each_pc_item_slot do |items, slot_index, slot|
      item = slot[0]
      quantity = slot[1]
      next if item.nil? || save_item_available?(item)
      record_missing_item_reference!("pc_item", "pc_items:#{slot_index}", item, quantity)
      items[slot_index] = nil
      changed = true
    end
    if changed && $PokemonGlobal && $PokemonGlobal.respond_to?(:pcItemStorage) && $PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage.items.compact!
    end
  rescue => e
    log("[save] missing PC item repair failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def repair_missing_item_references!
    repair_missing_bag_items!
    repair_missing_pc_items!
  rescue => e
    log("[save] missing item repair failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end
end

module Game
  class << self
    alias tef_original_load_map load_map

    def load_map
      TravelExpansionFramework.prepare_after_load! if defined?(TravelExpansionFramework)
      tef_original_load_map
    end
  end
end

TravelExpansionFramework.bootstrap!
TravelExpansionFramework.write_registry_snapshot
TravelExpansionFramework.write_json_report("conflict_report.json", TravelExpansionFramework.build_conflict_report)
TravelExpansionFramework.write_json_report("external_project_scan.json", TravelExpansionFramework.build_external_project_report)
TravelExpansionFramework.run_smoke_tests
