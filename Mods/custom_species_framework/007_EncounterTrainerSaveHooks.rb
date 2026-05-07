class PokemonEncounters
  alias csf_original_choose_wild_pokemon choose_wild_pokemon unless method_defined?(:csf_original_choose_wild_pokemon)

  def choose_wild_pokemon(enc_type, chance_rolls = 1)
    injected = CustomSpeciesFramework.roll_custom_encounter($game_map.map_id, enc_type) if defined?(CustomSpeciesFramework) && $game_map
    return injected if injected
    return csf_original_choose_wild_pokemon(enc_type, chance_rolls)
  end
end

if defined?(Pokemon)
  class Pokemon
    attr_accessor :csf_dormant_species_reference
    attr_accessor :csf_dormant_item_reference
  end
end

module CustomSpeciesFramework
  def self.roll_custom_encounter(map_id, enc_type)
    return nil if !active?
    enabled_hooks = @encounter_hooks.find_all { |hook|
      hook[:enabled] &&
      hook[:map_id] == map_id &&
      hook[:encounter_type] == enc_type &&
      species_reference_valid?(hook[:species])
    }
    return nil if enabled_hooks.empty?
    total_weight = enabled_hooks.inject(0) { |sum, hook| sum + hook[:weight] }
    roll = rand(total_weight)
    enabled_hooks.each do |hook|
      roll -= hook[:weight]
      next if roll >= 0
      minimum_level = [hook[:min_level], 1].max
      maximum_level = [hook[:max_level], minimum_level].max
      return [hook[:species], rand(minimum_level..maximum_level)]
    end
    return nil
  end

  def self.apply_trainer_hooks!(trainer)
    return if !active?
    matching_hooks = @trainer_hooks.find_all { |hook|
      hook[:enabled] &&
      hook[:trainer_type] == trainer.trainer_type &&
      hook[:trainer_name].to_s == trainer.name.to_s &&
      hook[:slot] >= 0 &&
      hook[:slot] < trainer.party.length
    }
    matching_hooks.each do |hook|
      existing_pokemon = trainer.party[hook[:slot]]
      trainer.party[hook[:slot]] = build_hooked_trainer_pokemon(trainer, existing_pokemon, hook)
    end
  end

  def self.build_hooked_trainer_pokemon(trainer, existing_pokemon, hook)
    level = hook[:level].is_a?(Integer) ? hook[:level] : existing_pokemon.level
    pokemon = Pokemon.new(hook[:species], level, trainer, false)
    pokemon.item = hook[:item] if hook[:item]
    pokemon.gender = hook[:gender] if !hook[:gender].nil?
    pokemon.nature = hook[:nature] if hook[:nature]
    pokemon.name = hook[:nickname] if !blank?(hook[:nickname])
    pokemon.shiny = true if hook[:shiny]
    if hook[:ability]
      pokemon.ability = hook[:ability]
    end
    if hook[:moves] && !hook[:moves].empty?
      pokemon.moves.clear
      hook[:moves].each { |move| pokemon.learn_move(move) }
    end
    pokemon.calc_stats
    return pokemon
  end

  def self.ensure_global_metadata!
    return if !$PokemonGlobal
    $PokemonGlobal.csf_framework_signature = framework_signature
    selected_id = nil
    selected_id = $PokemonGlobal.csf_selected_starter_set.to_s if $PokemonGlobal.respond_to?(:csf_selected_starter_set)
    starter_set_id = if blank?(selected_id) || selected_id == ORIGINAL_INFINITE_STARTER_SET_ID
                       nil
                     else
                       current_starter_set_id
                     end
    $PokemonGlobal.csf_active_starter_set = starter_set_id ? starter_set_id.to_s : nil
  end

  def self.migrate_legacy_species_variables!
    return if !$game_variables
    variable_ids = []
    variable_ids << VAR_PLAYER_STARTER_CHOICE if defined?(VAR_PLAYER_STARTER_CHOICE)
    variable_ids << VAR_RIVAL_STARTER_HEAD_CHOICE if defined?(VAR_RIVAL_STARTER_HEAD_CHOICE)
    variable_ids << VAR_RIVAL_STARTER_BODY_CHOICE if defined?(VAR_RIVAL_STARTER_BODY_CHOICE)
    variable_ids << VAR_RIVAL_STARTER if defined?(VAR_RIVAL_STARTER)
    variable_ids.compact.uniq.each do |variable_id|
      current_value = pbGet(variable_id) rescue nil
      translated_value = translate_legacy_species_number(current_value)
      next if translated_value.nil? || translated_value == current_value
      pbSet(variable_id, translated_value)
      log("Migrated legacy custom species variable #{variable_id} from #{current_value} to #{translated_value}.") if debug?
    end
  end

  def self.dormant_reference_value(value)
    return nil if value.nil?
    return value.id.to_s if value.respond_to?(:id)
    return value.to_s
  rescue
    return value.inspect
  end

  def self.reference_from_dormant_value(value)
    return nil if value.nil?
    return value if value.is_a?(Symbol) || value.is_a?(Integer)
    text = value.to_s
    return nil if text.empty?
    return text.to_i if text =~ /\A\d+\z/
    return text.to_sym
  rescue
    return nil
  end

  def self.item_reference_valid?(item)
    return false if item.nil?
    return false if !defined?(GameData::Item)
    return !GameData::Item.try_get(item).nil?
  rescue
    return false
  end

  def self.saved_pokemon_snapshot(pokemon, location)
    moves = []
    if pokemon.respond_to?(:moves)
      moves = Array(pokemon.moves).map { |move| dormant_reference_value(move.respond_to?(:id) ? move.id : move) }
    end
    {
      "location"      => location.to_s,
      "species"       => dormant_reference_value(pokemon.respond_to?(:species) ? pokemon.species : nil),
      "form"          => pokemon.respond_to?(:form) ? pokemon.form : nil,
      "forced_form"   => pokemon.respond_to?(:forced_form) ? pokemon.forced_form : nil,
      "level"         => pokemon.respond_to?(:level) ? pokemon.level : nil,
      "item"          => pokemon.respond_to?(:item_id) ? dormant_reference_value(pokemon.item_id) : nil,
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

  def self.record_dormant_save_reference(reference)
    if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:record_dormant_reference)
      reference["timestamp"] ||= TravelExpansionFramework.timestamp_string if TravelExpansionFramework.respond_to?(:timestamp_string)
      TravelExpansionFramework.record_dormant_reference(reference)
      TravelExpansionFramework.log("[save] dormant #{reference['type']} recorded at #{reference['location']}") if TravelExpansionFramework.respond_to?(:log)
    end
  rescue
  end

  def self.restore_dormant_species_reference!(pokemon, location)
    return false if pokemon.nil? || !pokemon.respond_to?(:csf_dormant_species_reference)
    reference = pokemon.csf_dormant_species_reference
    return false if !reference.is_a?(Hash)
    if (reference["repair_reason"] || reference[:repair_reason]).to_s == "context_alias_mismatch"
      pokemon.csf_dormant_species_reference = nil
      return false
    end
    species = reference_from_dormant_value(reference["species"] || reference[:species])
    return false if species.nil? || species == MISSING_SPECIES_ID
    return false if !species_reference_valid?(species, true)
    pokemon.species = species
    restored_form = reference["forced_form"] || reference[:forced_form] || reference["form"] || reference[:form]
    pokemon.forced_form = restored_form if pokemon.respond_to?(:forced_form=) && !restored_form.nil?
    pokemon.calc_stats rescue nil
    pokemon.csf_dormant_species_reference = nil
    record_dormant_save_reference({
      "type"     => "pokemon_species_restored",
      "location" => location.to_s,
      "species"  => dormant_reference_value(species)
    })
    return true
  rescue => e
    log("Dormant species restore failed at #{location}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def self.preserve_missing_species_reference!(pokemon, location)
    return false if pokemon.nil?
    original_species = pokemon.respond_to?(:species) ? pokemon.species : nil
    return false if original_species.nil? || original_species == MISSING_SPECIES_ID
    snapshot = saved_pokemon_snapshot(pokemon, location)
    pokemon.csf_dormant_species_reference = snapshot if pokemon.respond_to?(:csf_dormant_species_reference=)
    record_dormant_save_reference({
      "type"     => "pokemon_species",
      "location" => location.to_s,
      "species"  => dormant_reference_value(original_species),
      "snapshot" => snapshot
    })
    pokemon.species = MISSING_SPECIES_ID if pokemon.respond_to?(:species=)
    pokemon.calc_stats rescue nil
    return true
  rescue => e
    log("Missing species repair failed at #{location}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def self.restore_dormant_held_item_reference!(pokemon, location)
    return false if pokemon.nil? || !pokemon.respond_to?(:csf_dormant_item_reference)
    reference = pokemon.csf_dormant_item_reference
    return false if !reference.is_a?(Hash)
    item = reference_from_dormant_value(reference["item"] || reference[:item])
    return false if !item_reference_valid?(item)
    pokemon.item = item if pokemon.respond_to?(:item=)
    pokemon.csf_dormant_item_reference = nil
    record_dormant_save_reference({
      "type"     => "held_item_restored",
      "location" => location.to_s,
      "item"     => dormant_reference_value(item)
    })
    return true
  rescue => e
    log("Dormant held item restore failed at #{location}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def self.repair_missing_held_item_reference!(pokemon, location)
    return false if pokemon.nil? || !pokemon.respond_to?(:item_id)
    restore_dormant_held_item_reference!(pokemon, location)
    item = pokemon.item_id
    return false if item.nil? || item_reference_valid?(item)
    snapshot = saved_pokemon_snapshot(pokemon, location)
    item_reference = {
      "type"     => "held_item",
      "location" => location.to_s,
      "item"     => dormant_reference_value(item),
      "snapshot" => snapshot
    }
    pokemon.csf_dormant_item_reference = item_reference if pokemon.respond_to?(:csf_dormant_item_reference=)
    record_dormant_save_reference(item_reference)
    pokemon.instance_variable_set(:@item, nil)
    pokemon.mail = nil if pokemon.respond_to?(:mail=)
    return true
  rescue => e
    log("Missing held item repair failed at #{location}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def self.host_species_alias_for_metadata(metadata)
    return nil if !metadata.is_a?(Hash)
    Array(metadata[:compatibility_aliases]).each do |alias_id|
      next if alias_id.nil?
      symbol = alias_id.to_sym rescue nil
      next if symbol.nil?
      return symbol if host_species_symbol?(symbol)
    end
    return nil
  rescue
    return nil
  end

  def self.pokemon_obtain_expansion_id(pokemon)
    return nil if pokemon.nil? || !pokemon.respond_to?(:obtain_map)
    map_id = pokemon.obtain_map.to_i
    return nil if map_id <= 0
    return nil if !defined?(TravelExpansionFramework) || !TravelExpansionFramework.respond_to?(:current_map_expansion_id)
    expansion = TravelExpansionFramework.current_map_expansion_id(map_id)
    return nil if expansion.nil? || expansion.to_s.empty?
    return expansion.to_s
  rescue
    return nil
  end

  def self.metadata_matches_expansion_context?(metadata, expansion_id)
    return false if !metadata.is_a?(Hash) || expansion_id.nil? || expansion_id.to_s.empty?
    entry = {
      :source_pack    => metadata[:source_pack],
      :source_section => metadata[:source_section],
      :canonical_id   => metadata[:framework_species_key] || metadata[:source_pack]
    }
    return number_alias_entry_matches_context?(entry, expansion_id.to_s.downcase)
  rescue
    return false
  end

  def self.repair_context_mismatched_species_alias!(pokemon, location)
    return false if pokemon.nil? || !pokemon.respond_to?(:species)
    species = pokemon.species
    return false if species.nil? || species == MISSING_SPECIES_ID
    metadata = metadata_for(species)
    return false if metadata.nil?
    host_alias = host_species_alias_for_metadata(metadata)
    return false if host_alias.nil?
    obtain_expansion = pokemon_obtain_expansion_id(pokemon)
    return false if obtain_expansion.nil?
    return false if metadata_matches_expansion_context?(metadata, obtain_expansion)

    snapshot = saved_pokemon_snapshot(pokemon, location)
    snapshot["repair_reason"] = "context_alias_mismatch"
    snapshot["repaired_from"] = dormant_reference_value(species)
    snapshot["repaired_to"] = dormant_reference_value(host_alias)
    pokemon.species = host_alias
    pokemon.calc_stats rescue nil
    record_dormant_save_reference({
      "type"             => "pokemon_context_alias_repaired",
      "location"         => location.to_s,
      "obtain_expansion" => obtain_expansion,
      "species"          => dormant_reference_value(species),
      "replacement"      => dormant_reference_value(host_alias),
      "snapshot"         => snapshot
    })
    log("Repaired #{location} from #{species} to #{host_alias} because obtain expansion was #{obtain_expansion}.") if debug?
    return true
  rescue => e
    log("Context alias species repair failed at #{location}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def self.repair_missing_custom_species!
    each_saved_pokemon do |pokemon, location|
      next if pokemon.nil?
      restore_dormant_species_reference!(pokemon, location)
      repair_missing_held_item_reference!(pokemon, location)
      repair_context_mismatched_species_alias!(pokemon, location)
      species = pokemon.respond_to?(:species) ? pokemon.species : nil
      next if species.nil? || species == MISSING_SPECIES_ID
      next if species_reference_valid?(species, true)
      preserve_missing_species_reference!(pokemon, location)
    end
  end

  def self.each_saved_pokemon
    return if !$Trainer
    $Trainer.party.each_with_index { |pokemon, index| yield pokemon, "party:#{index}" if block_given? }
    return if !$PokemonStorage
    for box_index in 0...$PokemonStorage.maxBoxes
      for slot_index in 0...PokemonBox::BOX_SIZE
        pokemon = $PokemonStorage[box_index, slot_index]
        yield pokemon, "box:#{box_index}:#{slot_index}" if pokemon && block_given?
      end
    end
  end

  def self.repair_pokedex_from_saved_pokemon!
    return 0 if !$Trainer || !$Trainer.respond_to?(:pokedex) || !$Trainer.pokedex
    dex = $Trainer.pokedex
    repaired = 0
    each_saved_pokemon do |pokemon, location|
      next if pokemon.nil?
      next if pokemon.respond_to?(:egg?) && pokemon.egg?
      species = pokemon.respond_to?(:species) ? pokemon.species : nil
      next if species.nil? || species == MISSING_SPECIES_ID
      valid_species = species_reference_valid?(species, true)
      if !valid_species && defined?(GameData::Species) && GameData::Species.respond_to?(:try_get)
        valid_species = !GameData::Species.try_get(species).nil? rescue false
      end
      next if !valid_species
      begin
        seen_before = dex.respond_to?(:seen?) ? (dex.seen?(species) rescue false) : false
        owned_before = dex.respond_to?(:owned?) ? (dex.owned?(species) rescue false) : false
        dex.set_seen(species, false) if dex.respond_to?(:set_seen)
        dex.set_owned(species, false) if dex.respond_to?(:set_owned)
        if dex.respond_to?(:set_last_form_seen)
          gender = pokemon.respond_to?(:gender) ? pokemon.gender : 0
          form = pokemon.respond_to?(:form) ? pokemon.form : 0
          dex.set_last_form_seen(species, gender || 0, form || 0) rescue nil
        end
        if dex.respond_to?(:register_unfused_pkmn)
          dex.register_unfused_pkmn(pokemon) rescue nil
        end
        repaired += 1 if !seen_before || !owned_before
      rescue => e
        log("Skipped Pokedex repair for #{location}: #{e.class}: #{e.message}") if debug?
      end
    end
    dex.csf_pokedex_cache_changed! if dex.respond_to?(:csf_pokedex_cache_changed!)
    dex.refresh_accessible_dexes if dex.respond_to?(:refresh_accessible_dexes)
    log("Repaired Pokedex ownership from #{repaired} stored Pokemon.") if repaired > 0
    return repaired
  rescue => e
    log("Pokedex storage repair failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return 0
  end

  def self.pokedex_repair_species_valid?(species)
    return false if species.nil? || species == MISSING_SPECIES_ID
    return true if species_reference_valid?(species, true)
    if defined?(GameData::Species) && GameData::Species.respond_to?(:try_get)
      return true if GameData::Species.try_get(species)
    end
    return false
  rescue
    return false
  end

  def self.repair_pokedex_from_travel_progress!
    return 0 if !$Trainer || !$Trainer.respond_to?(:pokedex) || !$Trainer.pokedex
    return 0 if !defined?(TravelExpansionFramework)
    return 0 if !TravelExpansionFramework.respond_to?(:active_expansion_ids)
    return 0 if !TravelExpansionFramework.respond_to?(:dex_state_for)
    dex = $Trainer.pokedex
    repaired = 0
    TravelExpansionFramework.active_expansion_ids.each do |expansion_id|
      dex_state = TravelExpansionFramework.dex_state_for(expansion_id) rescue nil
      next if !dex_state.is_a?(Hash)
      [["seen", false], ["owned", true]].each do |bucket, owned|
        entries = dex_state[bucket]
        next if !entries.is_a?(Hash)
        entries.each_key do |species_ref|
          ref = species_ref.to_s =~ /\A\d+\z/ ? species_ref.to_i : species_ref
          species = canonical_species_id(ref) || ref
          next if !pokedex_repair_species_valid?(species)
          begin
            seen_before = dex.respond_to?(:seen?) ? (dex.seen?(species) rescue false) : false
            owned_before = dex.respond_to?(:owned?) ? (dex.owned?(species) rescue false) : false
            dex.set_seen(species, false) if dex.respond_to?(:set_seen)
            dex.set_owned(species, false) if owned && dex.respond_to?(:set_owned)
            repaired += 1 if !seen_before || (owned && !owned_before)
          rescue => e
            log("Skipped travel Pokedex repair for #{expansion_id}/#{species_ref}: #{e.class}: #{e.message}") if debug?
          end
        end
      end
    end
    dex.csf_pokedex_cache_changed! if repaired > 0 && dex.respond_to?(:csf_pokedex_cache_changed!)
    dex.refresh_accessible_dexes if repaired > 0 && dex.respond_to?(:refresh_accessible_dexes)
    log("Repaired Pokedex from #{repaired} travel progress entries.") if repaired > 0
    return repaired
  rescue => e
    log("Travel Pokedex progress repair failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return 0
  end

  def self.on_save_loaded!(save_kind)
    return if !active?
    install_home_pc_menu_patch! if respond_to?(:install_home_pc_menu_patch!)
    patch_starter_selection_common_event!
    if save_kind == :existing &&
       $PokemonGlobal &&
       $PokemonGlobal.respond_to?(:csf_selected_starter_set) &&
       blank?($PokemonGlobal.csf_selected_starter_set) &&
       $PokemonGlobal.respond_to?(:csf_active_starter_set) &&
       !blank?($PokemonGlobal.csf_active_starter_set) &&
       $PokemonGlobal.csf_active_starter_set.to_s != "framework_default" &&
        @starter_sets[$PokemonGlobal.csf_active_starter_set.to_s]
      $PokemonGlobal.csf_selected_starter_set = $PokemonGlobal.csf_active_starter_set.to_s
    end
    migrate_legacy_species_variables!
    repair_missing_custom_species!
    repair_pokedex_from_saved_pokemon!
    repair_pokedex_from_travel_progress!
    ensure_global_metadata!
    log("Save compatibility pass completed for #{save_kind} save.") if debug?
  end
end

Events.onTrainerPartyLoad += proc { |_sender, trainer|
  CustomSpeciesFramework.apply_trainer_hooks!(trainer)
}

class PokemonGlobalMetadata
  attr_accessor :csf_framework_signature
  attr_accessor :csf_active_starter_set
  attr_accessor :csf_selected_starter_set
end

alias csf_original_onLoadExistingGame onLoadExistingGame unless defined?(csf_original_onLoadExistingGame)
def onLoadExistingGame
  csf_original_onLoadExistingGame
  CustomSpeciesFramework.on_save_loaded!(:existing) if defined?(CustomSpeciesFramework)
end

alias csf_original_onStartingNewGame onStartingNewGame unless defined?(csf_original_onStartingNewGame)
def onStartingNewGame
  csf_original_onStartingNewGame
  CustomSpeciesFramework.on_save_loaded!(:new) if defined?(CustomSpeciesFramework)
end
