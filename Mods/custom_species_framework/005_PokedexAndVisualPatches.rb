class Player < Trainer
  class Pokedex
    alias csf_original_clear clear unless method_defined?(:csf_original_clear)

    def clear
      preserve_snapshot = csf_preserve_pokedex_clear? ? csf_pokedex_snapshot : nil
      csf_original_clear
      @seen_custom = {}
      @owned_custom = {}
      if preserve_snapshot
        csf_merge_pokedex_snapshot!(preserve_snapshot)
        if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
          CustomSpeciesFramework.log("Preserved Pokedex progress across expansion clear.")
        end
      else
        csf_pokedex_cache_changed!
      end
    end

    def csf_pokedex_cache_changed!
      @csf_pokedex_cache_version = (@csf_pokedex_cache_version || 0) + 1
      @csf_pokedex_runtime_cache = {}
      @csf_pokedex_count_cache = {}
      CustomSpeciesFramework.clear_pokedex_scene_cache! if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:clear_pokedex_scene_cache!)
    end

    def csf_pokedex_cache_version
      @csf_pokedex_cache_version ||= 0
    end

    def csf_pokedex_count_cache
      @csf_pokedex_count_cache ||= {}
    end

    def csf_preserve_pokedex_clear?
      return true if defined?(CustomSpeciesFramework) &&
                     CustomSpeciesFramework.respond_to?(:preserve_pokedex_clear?) &&
                     CustomSpeciesFramework.preserve_pokedex_clear?
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:current_expansion_id)
        expansion_id = TravelExpansionFramework.current_expansion_id rescue nil
        host_id = TravelExpansionFramework.const_defined?(:HOST_EXPANSION_ID) ? TravelExpansionFramework::HOST_EXPANSION_ID : "host"
        return true if !expansion_id.to_s.empty? && expansion_id.to_s != host_id.to_s
      end
      return false
    rescue
      return false
    end

    def csf_clone_pokedex_value(value)
      if value.is_a?(Hash)
        cloned = {}
        value.each { |key, entry| cloned[key] = csf_clone_pokedex_value(entry) }
        return cloned
      elsif value.is_a?(Array)
        return value.map { |entry| csf_clone_pokedex_value(entry) }
      end
      return value
    end

    def csf_pokedex_snapshot
      resyncPokedexIfNumberOfPokemonChanged rescue nil
      csf_ensure_custom_hashes! if respond_to?(:csf_ensure_custom_hashes!)
      return {
        :seen_standard  => csf_clone_pokedex_value(@seen_standard),
        :owned_standard => csf_clone_pokedex_value(@owned_standard),
        :seen_fusion    => csf_sparse_fusion_storage_from(@seen_fusion),
        :owned_fusion   => csf_sparse_fusion_storage_from(@owned_fusion),
        :seen_triple    => csf_clone_pokedex_value(@seen_triple),
        :owned_triple   => csf_clone_pokedex_value(@owned_triple),
        :seen_custom    => csf_clone_pokedex_value(@seen_custom),
        :owned_custom   => csf_clone_pokedex_value(@owned_custom),
        :seen_forms     => csf_clone_pokedex_value(@seen_forms),
        :last_seen_forms => csf_clone_pokedex_value(@last_seen_forms),
        :owned_shadow   => csf_clone_pokedex_value(@owned_shadow),
        :unlocked_dexes => csf_clone_pokedex_value(@unlocked_dexes)
      }
    rescue => e
      CustomSpeciesFramework.log("Pokedex snapshot failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      return nil
    end

    def csf_merge_standard_storage!(storage_name, snapshot_storage)
      return false if snapshot_storage.nil?
      storage = instance_variable_get(storage_name)
      storage = initStandardDexArray if !storage.respond_to?(:[]=)
      changed = false
      if snapshot_storage.is_a?(Hash)
        snapshot_storage.each do |species_id, value|
          next if value != true
          index = species_id.to_i
          next if index <= 0
          if storage[index] != true
            storage[index] = true
            changed = true
          end
        end
      elsif snapshot_storage.respond_to?(:each_with_index)
        snapshot_storage.each_with_index do |value, index|
          next if value != true || index <= 0
          if storage[index] != true
            storage[index] = true
            changed = true
          end
        end
      end
      instance_variable_set(storage_name, storage)
      return changed
    end

    def csf_merge_fusion_storage!(storage_name, snapshot_storage)
      sparse = csf_sparse_fusion_storage_from(snapshot_storage)
      return false if sparse.empty?
      storage = csf_sparse_fusion_storage!(storage_name)
      changed = false
      sparse.each do |head_id, row|
        next if row.nil?
        storage[head_id.to_i] ||= {}
        row.each do |body_id, value|
          next if value != true
          if storage[head_id.to_i][body_id.to_i] != true
            storage[head_id.to_i][body_id.to_i] = true
            changed = true
          end
        end
      end
      return changed
    end

    def csf_merge_flag_hash!(storage_name, snapshot_storage)
      return false if !snapshot_storage.is_a?(Hash)
      storage = instance_variable_get(storage_name)
      storage = {} if !storage.is_a?(Hash)
      changed = false
      snapshot_storage.each do |key, value|
        next if value != true
        if storage[key] != true
          storage[key] = true
          changed = true
        end
      end
      instance_variable_set(storage_name, storage)
      return changed
    end

    def csf_merge_plain_hash!(storage_name, snapshot_storage)
      return false if !snapshot_storage.is_a?(Hash)
      storage = instance_variable_get(storage_name)
      storage = {} if !storage.is_a?(Hash)
      changed = false
      snapshot_storage.each do |key, value|
        next if storage.has_key?(key)
        storage[key] = csf_clone_pokedex_value(value)
        changed = true
      end
      instance_variable_set(storage_name, storage)
      return changed
    end

    def csf_merge_unlocked_dexes!(snapshot_storage)
      return false if !snapshot_storage.respond_to?(:each_with_index)
      @unlocked_dexes ||= []
      changed = false
      snapshot_storage.each_with_index do |value, index|
        next if value != true
        if @unlocked_dexes[index] != true
          @unlocked_dexes[index] = true
          changed = true
        end
      end
      return changed
    end

    def csf_merge_pokedex_snapshot!(snapshot)
      return false if !snapshot.is_a?(Hash)
      changed = false
      changed = csf_merge_standard_storage!(:@seen_standard, snapshot[:seen_standard]) || changed
      changed = csf_merge_standard_storage!(:@owned_standard, snapshot[:owned_standard]) || changed
      changed = csf_merge_fusion_storage!(:@seen_fusion, snapshot[:seen_fusion]) || changed
      changed = csf_merge_fusion_storage!(:@owned_fusion, snapshot[:owned_fusion]) || changed
      changed = csf_merge_flag_hash!(:@seen_triple, snapshot[:seen_triple]) || changed
      changed = csf_merge_flag_hash!(:@owned_triple, snapshot[:owned_triple]) || changed
      changed = csf_merge_flag_hash!(:@seen_custom, snapshot[:seen_custom]) || changed
      changed = csf_merge_flag_hash!(:@owned_custom, snapshot[:owned_custom]) || changed
      changed = csf_merge_plain_hash!(:@seen_forms, snapshot[:seen_forms]) || changed
      changed = csf_merge_plain_hash!(:@last_seen_forms, snapshot[:last_seen_forms]) || changed
      changed = csf_merge_flag_hash!(:@owned_shadow, snapshot[:owned_shadow]) || changed
      changed = csf_merge_unlocked_dexes!(snapshot[:unlocked_dexes]) || changed
      csf_pokedex_cache_changed!
      refresh_accessible_dexes rescue nil
      return changed
    rescue => e
      CustomSpeciesFramework.log("Pokedex snapshot merge failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      return false
    end

    def csf_base_species_limit
      return CustomSpeciesFramework::FRAMEWORK_BASE_NB_POKEMON if defined?(CustomSpeciesFramework::FRAMEWORK_BASE_NB_POKEMON)
      return 501
    end

    alias csf_original_initFusionDexArray initFusionDexArray unless method_defined?(:csf_original_initFusionDexArray)
    def initFusionDexArray
      return {}
    end

    alias csf_original_resyncPokedexIfNumberOfPokemonChanged resyncPokedexIfNumberOfPokemonChanged unless method_defined?(:csf_original_resyncPokedexIfNumberOfPokemonChanged)
    def resyncPokedexIfNumberOfPokemonChanged
      @seen_standard ||= initStandardDexArray
      @owned_standard ||= initStandardDexArray
      @seen_fusion ||= initFusionDexArray
      @owned_fusion ||= initFusionDexArray
      @seen_triple ||= {}
      @owned_triple ||= {}
    end

    alias csf_original_try_resync_pokedex try_resync_pokedex unless method_defined?(:csf_original_try_resync_pokedex)
    def try_resync_pokedex
      resyncPokedexIfNumberOfPokemonChanged
    end

    alias csf_original_resync_fused_pokedex_array resync_fused_pokedex_array unless method_defined?(:csf_original_resync_fused_pokedex_array)
    def resync_fused_pokedex_array(original_dex_array)
      return csf_sparse_fusion_storage_from(original_dex_array)
    end

    alias csf_original_verify_dex_is_correct_length verify_dex_is_correct_length unless method_defined?(:csf_original_verify_dex_is_correct_length)
    def verify_dex_is_correct_length(current_dex)
      return true if current_dex.is_a?(Hash)
      return current_dex.respond_to?(:length) && current_dex.length > 1
    end

    alias csf_original_dex_sync_needed dex_sync_needed? unless method_defined?(:csf_original_dex_sync_needed)
    def dex_sync_needed?
      return @owned_standard.nil? || @owned_fusion.nil? || @owned_triple.nil? ||
             @seen_standard.nil? || @seen_fusion.nil? || @seen_triple.nil?
    end

    def csf_ensure_custom_hashes!
      @seen_custom ||= {}
      @owned_custom ||= {}
    end

    def csf_valid_fusion_component?(value)
      return false if value.nil?
      numeric_value = value.to_i
      return false if numeric_value <= 0
      return false if numeric_value >= Settings::ZAPMOLCUNO_NB
      return numeric_value <= Settings::NB_POKEMON
    end

    def csf_ensure_fusion_dex_storage!
      @seen_fusion ||= initFusionDexArray
      @owned_fusion ||= initFusionDexArray
    end

    def csf_ensure_fusion_row!(storage_name, head_id)
      return nil if !csf_valid_fusion_component?(head_id)
      csf_ensure_fusion_dex_storage!
      storage = instance_variable_get(storage_name)
      return nil if storage.nil?
      if storage.is_a?(Hash)
        storage[head_id] ||= {}
        return storage[head_id]
      end
      storage[head_id] ||= []
      return storage[head_id]
    end

    def csf_sparse_fusion_storage_from(storage)
      sparse = {}
      if storage.is_a?(Hash)
        storage.each do |head_id, row|
          next if !csf_valid_fusion_component?(head_id)
          if row.is_a?(Hash)
            row.each do |body_id, value|
              next if value != true || !csf_valid_fusion_component?(body_id)
              sparse[head_id.to_i] ||= {}
              sparse[head_id.to_i][body_id.to_i] = true
            end
          elsif row.respond_to?(:each_with_index)
            next if row.respond_to?(:include?) && !row.include?(true)
            row.each_with_index do |value, body_id|
              next if value != true || !csf_valid_fusion_component?(body_id)
              sparse[head_id.to_i] ||= {}
              sparse[head_id.to_i][body_id.to_i] = true
            end
          end
        end
      elsif storage.respond_to?(:each_with_index)
        storage.each_with_index do |row, head_id|
          next if row.nil? || !csf_valid_fusion_component?(head_id)
          if row.is_a?(Hash)
            row.each do |body_id, value|
              next if value != true || !csf_valid_fusion_component?(body_id)
              sparse[head_id] ||= {}
              sparse[head_id][body_id.to_i] = true
            end
          elsif row.respond_to?(:each_with_index)
            next if row.respond_to?(:include?) && !row.include?(true)
            row.each_with_index do |value, body_id|
              next if value != true || !csf_valid_fusion_component?(body_id)
              sparse[head_id] ||= {}
              sparse[head_id][body_id] = true
            end
          end
        end
      end
      return sparse
    rescue => e
      CustomSpeciesFramework.log("Pokedex fusion storage compaction failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      return {}
    end

    def csf_sparse_fusion_storage!(storage_name)
      storage = instance_variable_get(storage_name)
      if storage.is_a?(Hash)
        return storage
      end
      sparse = csf_sparse_fusion_storage_from(storage)
      instance_variable_set(storage_name, sparse)
      csf_pokedex_cache_changed!
      return sparse
    end

    def csf_fusion_components_for(species)
      dex_num = getDexNumberForSpecies(species) rescue nil
      dex_num = species.to_i if dex_num.nil? && species.is_a?(Integer)
      return nil if dex_num.nil?
      dex_num = dex_num.to_i
      return nil if dex_num <= Settings::NB_POKEMON
      return nil if dex_num >= Settings::ZAPMOLCUNO_NB
      divisors = [Settings::NB_POKEMON]
      divisors << csf_base_species_limit if csf_base_species_limit != Settings::NB_POKEMON
      divisors.compact.uniq.each do |divisor|
        next if divisor.to_i <= 0 || dex_num <= divisor.to_i
        body_id = getBodyID(dex_num, divisor.to_i) rescue nil
        head_id = getHeadID(dex_num, body_id, divisor.to_i) rescue nil
        next if !csf_valid_fusion_component?(head_id) || !csf_valid_fusion_component?(body_id)
        expected = body_id.to_i * divisor.to_i + head_id.to_i
        next if expected != dex_num
        return [body_id.to_i, head_id.to_i, divisor.to_i]
      end
      return nil
    rescue
      return nil
    end

    def csf_fusion_id_for_components(body_id, head_id)
      return body_id.to_i * Settings::NB_POKEMON + head_id.to_i
    end

    def csf_get_fusion_flag(storage_name, head_id, body_id)
      storage = instance_variable_get(storage_name)
      return false if storage.nil?
      row = storage[head_id] rescue nil
      return false if row.nil?
      return row[body_id] == true
    rescue
      return false
    end

    def csf_set_fusion_flag(storage_name, head_id, body_id)
      row = csf_ensure_fusion_row!(storage_name, head_id)
      return false if row.nil?
      return false if row[body_id] == true
      row[body_id] = true
      csf_pokedex_cache_changed!
      return true
    end

    def seen_fusion?(species)
      components = csf_fusion_components_for(species)
      return false if components.nil?
      body_id, head_id = components[0], components[1]
      return csf_get_fusion_flag(:@seen_fusion, head_id, body_id)
    end

    def set_seen_fusion(species)
      components = csf_fusion_components_for(species)
      return false if components.nil?
      body_id, head_id = components[0], components[1]
      return csf_set_fusion_flag(:@seen_fusion, head_id, body_id)
    end

    def owned_fusion?(species)
      components = csf_fusion_components_for(species)
      return false if components.nil?
      body_id, head_id = components[0], components[1]
      return csf_get_fusion_flag(:@owned_fusion, head_id, body_id)
    end

    def set_owned_fusion(species)
      components = csf_fusion_components_for(species)
      return false if components.nil?
      body_id, head_id = components[0], components[1]
      return csf_set_fusion_flag(:@owned_fusion, head_id, body_id)
    end

    def csf_count_standard_storage(storage_name)
      storage = instance_variable_get(storage_name)
      return 0 if storage.nil?
      if storage.is_a?(Hash)
        return storage.count { |species_id, value| species_id.to_i > 0 && value == true }
      end
      count = 0
      storage.each_with_index { |value, species_id| count += 1 if species_id > 0 && value == true } if storage.respond_to?(:each_with_index)
      return count
    end

    def csf_standard_ids(storage_name)
      storage = instance_variable_get(storage_name)
      ret = []
      return ret if storage.nil?
      if storage.is_a?(Hash)
        storage.each { |species_id, value| ret << species_id.to_i if species_id.to_i > 0 && value == true }
      elsif storage.respond_to?(:each_with_index)
        storage.each_with_index { |value, species_id| ret << species_id if species_id > 0 && value == true }
      end
      return ret
    end

    def csf_count_fusion_storage(storage_name)
      storage = csf_sparse_fusion_storage!(storage_name)
      count = 0
      storage.each_value { |row| count += row.count { |_body_id, value| value == true } if row }
      return count
    end

    def csf_fusion_ids(storage_name)
      storage = csf_sparse_fusion_storage!(storage_name)
      ret = []
      storage.each do |head_id, row|
        next if row.nil?
        row.each do |body_id, value|
          next if value != true
          ret << csf_fusion_id_for_components(body_id, head_id)
        end
      end
      return ret
    end

    def csf_triple_ids(storage_name)
      storage = instance_variable_get(storage_name)
      return [] if !storage.is_a?(Hash)
      ret = []
      storage.each do |species_ref, value|
        next if value != true
        id_number = CustomSpeciesFramework.resolve_id_number(species_ref) rescue nil
        ret << (id_number || species_ref)
      end
      return ret
    end

    def csf_custom_species_refs(storage_name)
      csf_ensure_custom_hashes!
      storage = instance_variable_get(storage_name)
      return [] if !storage.is_a?(Hash)
      return storage.keys.select { |species_id| storage[species_id] == true && CustomSpeciesFramework.custom_species_dex_visible?(species_id) }
    end

    def csf_pokedex_species_refs(filter_owned = false)
      if filter_owned
        return csf_standard_ids(:@owned_standard) +
               csf_fusion_ids(:@owned_fusion) +
               csf_triple_ids(:@owned_triple) +
               csf_custom_species_refs(:@owned_custom)
      end
      return csf_standard_ids(:@seen_standard) +
             csf_fusion_ids(:@seen_fusion) +
             csf_triple_ids(:@seen_triple) +
             csf_custom_species_refs(:@seen_custom)
    end

    def csf_visible_pokedex_entries(filter_owned = false)
      @csf_pokedex_runtime_cache ||= {}
      cache_key = [filter_owned == true, csf_pokedex_cache_version, Settings::NB_POKEMON]
      cached = @csf_pokedex_runtime_cache[cache_key]
      return cached.map(&:dup) if cached
      entries = CustomSpeciesFramework.pokedex_entries_from_refs(csf_pokedex_species_refs(filter_owned), filter_owned)
      cache_key = [filter_owned == true, csf_pokedex_cache_version, Settings::NB_POKEMON]
      @csf_pokedex_runtime_cache[cache_key] = entries.map(&:dup)
      return entries
    end

    alias csf_original_set_seen set_seen unless method_defined?(:csf_original_set_seen)
    def set_seen(species, should_refresh_dexes = true)
      resyncPokedexIfNumberOfPokemonChanged
      changed = false
      if CustomSpeciesFramework.custom_species?(species) && !CustomSpeciesFramework.actual_fusion_number?(species)
        csf_ensure_custom_hashes!
        species_id = CustomSpeciesFramework.canonical_species_id(species)
        if species_id && CustomSpeciesFramework.custom_species_dex_visible?(species_id)
          already_seen = @seen_custom[species_id] == true
          @seen_custom[species_id] = true
          if !already_seen
            csf_pokedex_cache_changed!
            changed = true
          end
          self.refresh_accessible_dexes if should_refresh_dexes && changed
        end
        return
      end
      components = csf_fusion_components_for(species)
      if components
        changed = set_seen_fusion(species)
      else
        dex_num = getDexNumberForSpecies(species) rescue nil
        if dex_num && dex_num.to_i >= Settings::ZAPMOLCUNO_NB
          @seen_triple ||= {}
          species_id = GameData::Species.try_get(species)&.species rescue species
          already_seen = @seen_triple[species_id] == true
          @seen_triple[species_id] = true
          if !already_seen
            csf_pokedex_cache_changed!
            changed = true
          end
        elsif dex_num && dex_num.to_i > 0 && dex_num.to_i <= Settings::NB_POKEMON
          @seen_standard ||= initStandardDexArray
          already_seen = @seen_standard[dex_num.to_i] == true
          @seen_standard[dex_num.to_i] = true
          if !already_seen
            csf_pokedex_cache_changed!
            changed = true
          end
        end
      end
      self.refresh_accessible_dexes if should_refresh_dexes && changed
    end

    alias csf_original_seen_query seen? unless method_defined?(:csf_original_seen_query)
    def seen?(species)
      return false if species.nil?
      if CustomSpeciesFramework.custom_species?(species) && !CustomSpeciesFramework.actual_fusion_number?(species)
        csf_ensure_custom_hashes!
        species_id = CustomSpeciesFramework.canonical_species_id(species)
        return @seen_custom[species_id] == true
      end
      return seen_fusion?(species) if csf_fusion_components_for(species)
      dex_num = getDexNumberForSpecies(species) rescue nil
      return false if dex_num.nil?
      dex_num = dex_num.to_i
      if dex_num >= Settings::ZAPMOLCUNO_NB
        @seen_triple ||= {}
        species_id = GameData::Species.try_get(species)&.species rescue species
        return @seen_triple[species_id] == true
      end
      @seen_standard ||= initStandardDexArray
      return false if dex_num > Settings::NB_POKEMON
      return @seen_standard[dex_num] == true
    end

    alias csf_original_set_owned set_owned unless method_defined?(:csf_original_set_owned)
    def set_owned(species, should_refresh_dexes = true)
      resyncPokedexIfNumberOfPokemonChanged
      changed = false
      if CustomSpeciesFramework.custom_species?(species) && !CustomSpeciesFramework.actual_fusion_number?(species)
        csf_ensure_custom_hashes!
        species_id = CustomSpeciesFramework.canonical_species_id(species)
        if species_id && CustomSpeciesFramework.custom_species_dex_visible?(species_id)
          already_owned = @owned_custom[species_id] == true
          @owned_custom[species_id] = true
          if !already_owned
            csf_pokedex_cache_changed!
            changed = true
          end
          self.refresh_accessible_dexes if should_refresh_dexes && changed
        end
        return
      end
      components = csf_fusion_components_for(species)
      if components
        changed = set_owned_fusion(species)
      else
        dex_num = getDexNumberForSpecies(species) rescue nil
        if dex_num && dex_num.to_i >= Settings::ZAPMOLCUNO_NB
          @owned_triple ||= {}
          species_id = GameData::Species.try_get(species)&.species rescue species
          already_owned = @owned_triple[species_id] == true
          @owned_triple[species_id] = true
          if !already_owned
            csf_pokedex_cache_changed!
            changed = true
          end
        elsif dex_num && dex_num.to_i > 0 && dex_num.to_i <= Settings::NB_POKEMON
          @owned_standard ||= initStandardDexArray
          already_owned = @owned_standard[dex_num.to_i] == true
          @owned_standard[dex_num.to_i] = true
          if !already_owned
            csf_pokedex_cache_changed!
            changed = true
          end
        end
      end
      self.refresh_accessible_dexes if should_refresh_dexes && changed
    end

    alias csf_original_owned_query owned? unless method_defined?(:csf_original_owned_query)
    def owned?(species)
      return false if species.nil?
      if CustomSpeciesFramework.custom_species?(species) && !CustomSpeciesFramework.actual_fusion_number?(species)
        csf_ensure_custom_hashes!
        species_id = CustomSpeciesFramework.canonical_species_id(species)
        return @owned_custom[species_id] == true
      end
      return owned_fusion?(species) if csf_fusion_components_for(species)
      dex_num = getDexNumberForSpecies(species) rescue nil
      return false if dex_num.nil?
      dex_num = dex_num.to_i
      if dex_num >= Settings::ZAPMOLCUNO_NB
        @owned_triple ||= {}
        species_id = GameData::Species.try_get(species)&.species rescue species
        return @owned_triple[species_id] == true
      end
      @owned_standard ||= initStandardDexArray
      return false if dex_num > Settings::NB_POKEMON
      return @owned_standard[dex_num] == true
    end

    alias csf_original_seen_count seen_count unless method_defined?(:csf_original_seen_count)
    def seen_count(dex = -1)
      csf_ensure_custom_hashes!
      csf_sparse_fusion_storage!(:@seen_fusion)
      cache_key = [:seen, dex, csf_pokedex_cache_version, Settings::NB_POKEMON]
      cached = csf_pokedex_count_cache[cache_key]
      return cached if !cached.nil?
      start_time = Time.now
      custom_count = @seen_custom.keys.count { |species_id| CustomSpeciesFramework.custom_species_dex_visible?(species_id) }
      count = csf_count_standard_storage(:@seen_standard) +
              csf_count_fusion_storage(:@seen_fusion) +
              csf_triple_ids(:@seen_triple).length +
              custom_count
      csf_pokedex_count_cache[cache_key] = count
      elapsed = Time.now - start_time
      CustomSpeciesFramework.log("Pokedex seen count took #{format('%.3f', elapsed)}s.") if elapsed > 0.75 && defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      return count
    end

    alias csf_original_owned_count owned_count unless method_defined?(:csf_original_owned_count)
    def owned_count(dex = -1)
      csf_ensure_custom_hashes!
      csf_sparse_fusion_storage!(:@owned_fusion)
      cache_key = [:owned, dex, csf_pokedex_cache_version, Settings::NB_POKEMON]
      cached = csf_pokedex_count_cache[cache_key]
      return cached if !cached.nil?
      start_time = Time.now
      custom_count = @owned_custom.keys.count { |species_id| CustomSpeciesFramework.custom_species_dex_visible?(species_id) }
      count = csf_count_standard_storage(:@owned_standard) +
              csf_count_fusion_storage(:@owned_fusion) +
              csf_triple_ids(:@owned_triple).length +
              custom_count
      csf_pokedex_count_cache[cache_key] = count
      elapsed = Time.now - start_time
      CustomSpeciesFramework.log("Pokedex owned count took #{format('%.3f', elapsed)}s.") if elapsed > 0.75 && defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      return count
    end

    def isFusion(num)
      return !csf_fusion_components_for(num).nil?
    end
  end
end

module CustomSpeciesFramework
  def self.pokedex_clear_preservation_depth
    @pokedex_clear_preservation_depth ||= 0
  end

  def self.preserve_pokedex_clear?
    return pokedex_clear_preservation_depth > 0
  end

  def self.with_pokedex_clear_preservation
    @pokedex_clear_preservation_depth = pokedex_clear_preservation_depth + 1
    return yield if block_given?
  ensure
    @pokedex_clear_preservation_depth = [pokedex_clear_preservation_depth - 1, 0].max
  end

  def self.each_runtime_pokedex_species
    return enum_for(:each_runtime_pokedex_species) if !block_given?
    yielded = {}
    if defined?(GameData::Species) && GameData::Species.respond_to?(:each)
      GameData::Species.each do |species_data|
        yield_pokedex_species_once(species_data, yielded) { |entry| yield entry }
      end
    elsif defined?(GameData::Species::DATA)
      GameData::Species::DATA.each_value do |species_data|
        yield_pokedex_species_once(species_data, yielded) { |entry| yield entry }
      end
    end
    pokedex_species_ids.each do |species|
      species_data = GameData::Species.try_get(species) rescue nil
      species_data ||= GameData::Species.get(species) rescue nil
      yield_pokedex_species_once(species_data, yielded) { |entry| yield entry }
    end
  end

  def self.yield_pokedex_species_once(species_data, yielded)
    return if species_data.nil? || !species_data.respond_to?(:id_number)
    id_number = species_data.id_number.to_i
    return if id_number <= 0
    return if yielded[id_number]
    yielded[id_number] = true
    yield species_data
  rescue
  end

  def self.pokedex_seen?(species_key, id_number)
    return false if !$Trainer
    return true if ($Trainer.seen?(species_key) rescue false)
    return true if ($Trainer.seen?(id_number) rescue false)
    return false
  end

  def self.pokedex_owned?(species_key, id_number)
    return false if !$Trainer
    return true if ($Trainer.owned?(species_key) rescue false)
    return true if ($Trainer.owned?(id_number) rescue false)
    return false
  end

  def self.pokedex_duplicate_key(species_data)
    metadata = metadata_for(species_data.species) rescue nil
    return [:id, species_data.id_number.to_i] if metadata.nil?
    aliases = Array(metadata[:compatibility_aliases]).map { |entry| entry.to_s.downcase }.sort
    source_pack = metadata[:source_pack].to_s.downcase
    kind = metadata[:kind].to_s.downcase
    name = (species_data.real_name rescue species_data.name rescue species_data.species.to_s).to_s.downcase
    if !aliases.empty?
      return [:alias, source_pack, kind, aliases.join("|")]
    end
    return [:source_name, source_pack, kind, name] if !source_pack.empty?
    return [:id, species_data.id_number.to_i]
  rescue
    return [:id, species_data.id_number.to_i]
  end

  def self.pokedex_species_entry_allowed?(species_data, allow_fusion = false)
    return false if species_data.nil?
    id_number = species_data.id_number.to_i rescue 0
    return false if id_number <= 0
    if defined?(LEGACY_RESERVED_ID_MIN) && id_number >= LEGACY_RESERVED_ID_MIN
      return false unless allow_fusion &&
                          ((actual_fusion_number?(id_number) rescue false) ||
                           (actual_triple_fusion_number?(id_number) rescue false))
    end
    return false if species_data.respond_to?(:form) && species_data.form.to_i != 0
    species_key = species_data.respond_to?(:species) ? species_data.species : species_data.id
    return false if species_key == MISSING_SPECIES_ID
    return false if !allow_fusion && (actual_fusion_number?(id_number) rescue false)
    return false if !allow_fusion && (actual_triple_fusion_number?(id_number) rescue false)
    metadata = metadata_for(species_key) rescue nil
    return true if metadata.nil?
    return false if metadata[:kind] == :framework_placeholder
    return custom_species_dex_visible?(species_key)
  rescue
    return false
  end

  def self.pokedex_list_entry_from_species_data(species_data, allow_fusion = false)
    return nil if !pokedex_species_entry_allowed?(species_data, allow_fusion)
    id_number = species_data.id_number.to_i
    species_key = species_data.respond_to?(:species) ? species_data.species : species_data.id
    name = species_data.real_name rescue species_data.name rescue species_key.to_s
    height = species_data.height rescue 0
    weight = species_data.weight rescue 0
    type1 = species_data.type1 rescue nil
    type2 = species_data.type2 rescue nil
    color = species_data.color rescue nil
    shape = species_data.shape rescue nil
    return [id_number, name, height, weight, id_number, 0, type1, type2, color, shape]
  rescue => e
    log("Pokedex entry build skipped: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def self.fusion_components_from_id_number(id_number)
    number = id_number.to_i
    return nil if number <= Settings::NB_POKEMON.to_i
    return nil if number >= Settings::ZAPMOLCUNO_NB.to_i
    divisor = Settings::NB_POKEMON.to_i
    return nil if divisor <= 0
    body_id = getBodyID(number, divisor) rescue nil
    head_id = getHeadID(number, body_id, divisor) rescue nil
    return nil if body_id.nil? || head_id.nil?
    body_id = body_id.to_i
    head_id = head_id.to_i
    return nil if body_id <= 0 || head_id <= 0
    return nil if body_id > Settings::NB_POKEMON.to_i || head_id > Settings::NB_POKEMON.to_i
    return nil if body_id * divisor + head_id != number
    return [body_id, head_id]
  rescue
    return nil
  end

  def self.species_data_for_dex_component(dex_number)
    number = dex_number.to_i
    return nil if number <= 0
    if defined?(GameData::Species::DATA)
      direct = GameData::Species::DATA[number] rescue nil
      return direct if direct && direct.respond_to?(:id_number)
    end
    return GameData::Species.get(number) rescue nil
  end

  def self.lightweight_fusion_name(body_data, head_data)
    body_number = body_data.id_number.to_i
    head_number = head_data.id_number.to_i
    body_nat = (defined?(GameData::NAT_DEX_MAPPING) && GameData::NAT_DEX_MAPPING[body_number]) ? GameData::NAT_DEX_MAPPING[body_number] : body_number
    head_nat = (defined?(GameData::NAT_DEX_MAPPING) && GameData::NAT_DEX_MAPPING[head_number]) ? GameData::NAT_DEX_MAPPING[head_number] : head_number
    if defined?(GameData::SPLIT_NAMES) && GameData::SPLIT_NAMES[head_nat] && GameData::SPLIT_NAMES[body_nat]
      prefix = GameData::SPLIT_NAMES[head_nat][0].to_s
      suffix = GameData::SPLIT_NAMES[body_nat][1].to_s
      prefix = prefix[0..-2] if !prefix.empty? && !suffix.empty? && prefix[-1] == suffix[0]
      combined = prefix + suffix
      return combined if !combined.empty?
    end
    head_name = head_data.real_name rescue head_data.name rescue head_data.species.to_s
    body_name = body_data.real_name rescue body_data.name rescue body_data.species.to_s
    return "#{head_name}/#{body_name}"
  rescue
    return "Fusion"
  end

  def self.lightweight_fusion_entry(id_number)
    components = fusion_components_from_id_number(id_number)
    return nil if components.nil?
    body_id, head_id = components
    body_data = species_data_for_dex_component(body_id)
    head_data = species_data_for_dex_component(head_id)
    return nil if body_data.nil? || head_data.nil?
    type1 = head_data.type1 rescue nil
    head_type2 = head_data.type2 rescue nil
    type1 = head_type2 if type1 == :NORMAL && head_type2 == :FLYING
    body_type1 = body_data.type1 rescue nil
    body_type2 = body_data.type2 rescue nil
    type2 = (body_type2 == type1 || body_type2.nil?) ? body_type1 : body_type2
    type2 = type1 if type2.nil?
    height = (((head_data.height rescue 0).to_i + (body_data.height rescue 0).to_i) / 2).floor
    weight = (((head_data.weight rescue 0).to_i + (body_data.weight rescue 0).to_i) / 2).floor
    color = head_data.color rescue nil
    shape = body_data.shape rescue nil
    return [id_number.to_i, lightweight_fusion_name(body_data, head_data), height, weight, id_number.to_i, 0, type1, type2, color, shape]
  rescue => e
    log("Lightweight fusion Pokedex entry skipped for #{id_number.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def self.pokedex_entries_from_refs(species_refs, filter_owned = false)
    ret = []
    seen_display_numbers = {}
    seen_duplicate_keys = {}
    Array(species_refs).each do |species_ref|
      if species_ref.is_a?(Integer) && (actual_fusion_number?(species_ref) rescue false)
        entry = lightweight_fusion_entry(species_ref)
        next if entry.nil?
        duplicate_key = [:fusion, entry[0]]
        next if seen_duplicate_keys[duplicate_key] || seen_display_numbers[entry[4]]
        ret << entry
        seen_duplicate_keys[duplicate_key] = true
        seen_display_numbers[entry[4]] = true
        next
      end
      species_data = nil
      species_data = species_data_for_id_number(species_ref) if species_ref.is_a?(Integer)
      species_data ||= GameData::Species.try_get(species_ref) rescue nil
      species_data ||= GameData::Species.get(species_ref) rescue nil
      next if species_data.nil?
      id_number = species_data.id_number.to_i rescue 0
      next if id_number <= 0
      fusion_entry = actual_fusion_number?(id_number) rescue false
      triple_entry = actual_triple_fusion_number?(id_number) rescue false
      duplicate_key = if fusion_entry
                        [:fusion, id_number]
                      elsif triple_entry
                        [:triple, id_number]
                      else
                        pokedex_duplicate_key(species_data)
                      end
      next if seen_duplicate_keys[duplicate_key]
      display_number = id_number
      next if seen_display_numbers[display_number]
      entry = pokedex_list_entry_from_species_data(species_data, true)
      next if entry.nil?
      ret << entry
      seen_duplicate_keys[duplicate_key] = true
      seen_display_numbers[display_number] = true
    end
    ret.sort_by! { |entry| entry[4] || entry[0] }
    return ret
  rescue => e
    log("Pokedex sparse list failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return []
  end

  def self.safe_pokedex_list(filter_owned = false)
    if $Trainer && $Trainer.respond_to?(:pokedex) && $Trainer.pokedex.respond_to?(:csf_visible_pokedex_entries)
      return $Trainer.pokedex.csf_visible_pokedex_entries(filter_owned)
    end
    ret = []
    seen_display_numbers = {}
    seen_duplicate_keys = {}
    return ret if !$Trainer
    each_runtime_pokedex_species do |species_data|
      next if !pokedex_species_entry_allowed?(species_data)
      id_number = species_data.id_number.to_i
      species_key = species_data.respond_to?(:species) ? species_data.species : species_data.id
      next if !pokedex_seen?(species_key, id_number)
      next if filter_owned && !pokedex_owned?(species_key, id_number)
      duplicate_key = pokedex_duplicate_key(species_data)
      next if seen_duplicate_keys[duplicate_key]
      display_number = id_number
      next if seen_display_numbers[display_number]
      entry = pokedex_list_entry_from_species_data(species_data, false)
      next if entry.nil?
      entry[4] = display_number
      ret << entry
      seen_duplicate_keys[duplicate_key] = true
      seen_display_numbers[display_number] = true
    end
    ret.sort_by! { |entry| entry[4] || entry[0] }
    return ret
  rescue => e
    log("Safe Pokedex list failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return []
  end
end

alias csf_original_pbGetDexList pbGetDexList unless defined?(csf_original_pbGetDexList)
def pbGetDexList(filter_owned = false)
  return CustomSpeciesFramework.safe_pokedex_list(filter_owned)
end

module CustomSpeciesFramework
  def self.full_pokedex_length
    base_count = Settings::NB_POKEMON.to_i
    base_count -= 1 if const_defined?(:MISSING_SPECIES_NUM) && MISSING_SPECIES_NUM.to_i > 0 && MISSING_SPECIES_NUM.to_i <= Settings::NB_POKEMON.to_i
    base_count = 0 if base_count < 0
    fusion_count = Settings::NB_POKEMON.to_i * Settings::NB_POKEMON.to_i
    return base_count + fusion_count
  rescue
    return 0
  end
end

alias csf_original_pbGetRegionalDexLength pbGetRegionalDexLength unless defined?(csf_original_pbGetRegionalDexLength)
def pbGetRegionalDexLength(region_dex)
  return CustomSpeciesFramework.full_pokedex_length if region_dex.to_i < 0
  return csf_original_pbGetRegionalDexLength(region_dex)
end

module CustomSpeciesFramework
  def self.pokedex_sprite_hash?(sprites)
    return false if !sprites.is_a?(Hash)
    return sprites.has_key?("pokedex") && sprites.has_key?("overlay") && sprites.has_key?("background")
  rescue
    return false
  end

  def self.fast_pokedex_fade_frames
    frames = ((Graphics.frame_rate rescue 40).to_i * (Settings::FADEOUT_SPEED rescue 0.2).to_f).floor
    frames = 1 if frames < 1
    return [frames, 8].min
  rescue
    return 6
  end

  def self.fast_pokedex_fade_out_and_hide(sprites, &block)
    visible_sprites = {}
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 999999
    color = Color.new(0, 0, 0, 0)
    frames = fast_pokedex_fade_frames
    start_time = Time.now
    pbDeactivateWindows(sprites) do
      0.upto(frames) do |frame|
        color.set(0, 0, 0, (255 * frame / frames.to_f).round)
        viewport.color = color
        block.call if block
        Graphics.update
        Input.update
      end
    end
    sprites.each do |key, sprite|
      next if !sprite || pbDisposed?(sprite)
      visible_sprites[key] = true if sprite.visible
      sprite.visible = false
    end
    elapsed = Time.now - start_time
    log("Fast Pokedex fade out took #{format('%.3f', elapsed)}s") if elapsed > 0.75 && respond_to?(:log)
    return visible_sprites
  rescue => e
    log("Fast Pokedex fade out failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return {}
  ensure
    viewport.dispose if viewport && !viewport.disposed? rescue nil
  end

  def self.fast_pokedex_fade_in_and_show(sprites, visible_sprites = nil, &block)
    if visible_sprites
      visible_sprites.each do |key, visible|
        next if !visible || !sprites[key] || pbDisposed?(sprites[key])
        sprites[key].visible = true
      end
    end
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 999999
    color = Color.new(0, 0, 0, 255)
    viewport.color = color
    frames = fast_pokedex_fade_frames
    start_time = Time.now
    pbDeactivateWindows(sprites) do
      0.upto(frames) do |frame|
        color.set(0, 0, 0, (255 * (frames - frame) / frames.to_f).round)
        viewport.color = color
        block.call if block
        Graphics.update
        Input.update
      end
    end
    elapsed = Time.now - start_time
    log("Fast Pokedex fade in took #{format('%.3f', elapsed)}s") if elapsed > 0.75 && respond_to?(:log)
  rescue => e
    log("Fast Pokedex fade in failed: #{e.class}: #{e.message}") if respond_to?(:log)
  ensure
    viewport.dispose if viewport && !viewport.disposed? rescue nil
  end
end

alias csf_original_pbFadeOutAndHide_for_pokedex pbFadeOutAndHide unless defined?(csf_original_pbFadeOutAndHide_for_pokedex)
def pbFadeOutAndHide(sprites, &block)
  if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.pokedex_sprite_hash?(sprites)
    return CustomSpeciesFramework.fast_pokedex_fade_out_and_hide(sprites, &block)
  end
  return csf_original_pbFadeOutAndHide_for_pokedex(sprites, &block)
end

alias csf_original_pbFadeInAndShow_for_pokedex pbFadeInAndShow unless defined?(csf_original_pbFadeInAndShow_for_pokedex)
def pbFadeInAndShow(sprites, visible_sprites = nil, &block)
  if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.pokedex_sprite_hash?(sprites)
    return CustomSpeciesFramework.fast_pokedex_fade_in_and_show(sprites, visible_sprites, &block)
  end
  return csf_original_pbFadeInAndShow_for_pokedex(sprites, visible_sprites, &block)
end

module GameData
  class Species
    class << self
      alias csf_original_front_sprite_filename front_sprite_filename unless method_defined?(:csf_original_front_sprite_filename)
      alias csf_original_back_sprite_filename back_sprite_filename unless method_defined?(:csf_original_back_sprite_filename)
      alias csf_original_icon_filename icon_filename unless method_defined?(:csf_original_icon_filename)
      alias csf_original_icon_filename_from_pokemon icon_filename_from_pokemon unless method_defined?(:csf_original_icon_filename_from_pokemon)
      alias csf_original_check_cry_file check_cry_file unless method_defined?(:csf_original_check_cry_file)

      def front_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
        resolved = CustomSpeciesFramework.resolve_graphic(:front, species)
        return resolved if resolved.is_a?(String)
        species = resolved if resolved.is_a?(Symbol)
        path = csf_original_front_sprite_filename(species, form, gender, shiny, shadow)
        return path if path
        return get_unfused_sprite_path(getDexNumberForSpecies(species), form)
      end

      def back_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
        resolved = CustomSpeciesFramework.resolve_graphic(:back, species)
        return resolved if resolved.is_a?(String)
        species = resolved if resolved.is_a?(Symbol)
        path = csf_original_back_sprite_filename(species, form, gender, shiny, shadow)
        return path if path
        return get_unfused_sprite_path(getDexNumberForSpecies(species), form)
      end

      def icon_filename(species, spriteform = nil, gender = nil, shiny = false, shadow = false, egg = false)
        return csf_original_icon_filename(species, spriteform, gender, shiny, shadow, egg) if egg
        resolved = CustomSpeciesFramework.preferred_icon_path(species)
        resolved ||= CustomSpeciesFramework.resolve_graphic(:icon, species)
        return resolved if resolved.is_a?(String)
        species = resolved if resolved.is_a?(Symbol)
        return csf_original_icon_filename(species, spriteform, gender, shiny, shadow, egg)
      end

      def icon_filename_from_pokemon(pkmn)
        return csf_original_icon_filename_from_pokemon(pkmn) if pkmn.nil?
        return pbResolveBitmap(sprintf("Graphics/Icons/iconEgg")) if pkmn.egg?
        resolved = CustomSpeciesFramework.preferred_icon_path(pkmn.species)
        resolved ||= CustomSpeciesFramework.resolve_graphic(:icon, pkmn.species)
        return resolved if resolved.is_a?(String)
        return csf_original_icon_filename_from_pokemon(pkmn)
      end

      def check_cry_file(species, form)
        metadata = CustomSpeciesFramework.metadata_for(species)
        if metadata
          cry_asset = CustomSpeciesFramework.asset_path(:cry, species)
          return cry_asset if cry_asset
          fallback_species = metadata[:fallback_species]
          return csf_original_check_cry_file(fallback_species, form) if fallback_species
          return nil
        end
        return csf_original_check_cry_file(species, form)
      end

      def play_cry_from_species(species, form = 0, volume = 90, pitch = 100)
        dex_num = getDexNumberForSpecies(species)
        return if !dex_num
        return play_triple_fusion_cry(species, volume, pitch) if CustomSpeciesFramework.actual_triple_fusion_number?(dex_num)
        if CustomSpeciesFramework.actual_fusion_number?(dex_num)
          body_number = getBodyID(dex_num)
          head_number = getHeadID(dex_num, body_number)
          return play_fusion_cry(GameData::Species.get(head_number).species, GameData::Species.get(body_number).species, volume, pitch)
        end
        filename = self.cry_filename(species, form)
        return if !filename
        pbSEPlay(RPG::AudioFile.new(filename, volume, pitch)) rescue nil
      end

      def play_cry_from_pokemon(pkmn, volume = 90, pitch = nil)
        return if !pkmn || pkmn.egg?
        species_data = pkmn.species_data
        return play_triple_fusion_cry(pkmn.species, volume, pitch) if species_data.is_triple_fusion
        if pkmn.isFusion?
          return play_fusion_cry(species_data.get_head_species, species_data.get_body_species, volume, pitch)
        end
        filename = self.cry_filename_from_pokemon(pkmn)
        return if !filename
        pitch ||= 75 + (pkmn.hp * 25 / pkmn.totalhp)
        pbSEPlay(RPG::AudioFile.new(filename, volume, pitch)) rescue nil
      end
    end
  end
end

module CustomSpeciesFramework
  def self.clear_pokedex_scene_cache!
    @scene_pokedex_list_cache = {}
  end

  def self.normalize_pokedex_list_entry(entry)
    return nil if entry.nil?
    normalized_entry = entry.dup

    species_number = normalized_entry[0]
    display_number = normalized_entry[4]

    translated_species_number = translate_legacy_species_number(species_number) if species_number.is_a?(Integer)
    translated_display_number = translate_legacy_species_number(display_number) if display_number.is_a?(Integer)

    resolved_number = translated_species_number || translated_display_number
    resolved_number ||= species_number if species_number.is_a?(Integer) && framework_absolute_id_number?(species_number)
    resolved_number ||= display_number if display_number.is_a?(Integer) && framework_absolute_id_number?(display_number)
    if resolved_number
      species_data = species_data_for_id_number(resolved_number)
      if species_data
        if CustomSpeciesFramework.custom_species?(species_data.species)
          return nil if species_data.species == CustomSpeciesFramework::MISSING_SPECIES_ID
          return nil if !CustomSpeciesFramework.custom_species_dex_visible?(species_data.species)
        end
        normalized_entry[0] = species_data.id_number
        normalized_entry[1] = species_data.real_name
        normalized_entry[2] = species_data.height
        normalized_entry[3] = species_data.weight
        normalized_entry[4] = species_data.id_number
      end
    end

    return normalized_entry
  end

  def self.scene_safe_pokedex_list(filter_owned = false)
    if $Trainer && $Trainer.respond_to?(:pokedex) && $Trainer.pokedex.respond_to?(:csf_pokedex_cache_version)
      @scene_pokedex_list_cache ||= {}
      pokedex = $Trainer.pokedex
      cache_key = [pokedex.object_id, filter_owned == true, pokedex.csf_pokedex_cache_version, Settings::NB_POKEMON]
      cached = @scene_pokedex_list_cache[cache_key]
      return cached.map(&:dup) if cached
    end
    normalized = []
    list = safe_pokedex_list(filter_owned)
    list = [] if !list.is_a?(Array)
    list.each do |entry|
      safe_entry = entry.is_a?(Array) ? entry.dup : (normalize_pokedex_list_entry(entry) rescue entry)
      next if safe_entry.nil? || safe_entry[0].nil?
      safe_entry[1] = safe_entry[1].to_s
      safe_entry[2] = safe_entry[2].to_i
      safe_entry[3] = safe_entry[3].to_i
      safe_entry[4] = safe_entry[4].to_i
      safe_entry[5] = 0 if safe_entry[5].nil?
      normalized << safe_entry
    end
    @scene_pokedex_list_cache[cache_key] = normalized.map(&:dup) if defined?(cache_key) && @scene_pokedex_list_cache
    return normalized
  rescue => e
    log("Pokedex scene list failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return []
  end
end

class Window_Pokedex
  alias csf_original_pokedex_commands_set commands= unless method_defined?(:csf_original_pokedex_commands_set)
  def commands=(value)
    @commands = value || []
    @item_max = @commands.length
  end

  alias csf_original_pokedex_species species unless method_defined?(:csf_original_pokedex_species)
  def species
    commands = @commands || []
    return nil if commands.empty?
    current_index = self.index rescue 0
    current_index = 0 if current_index.nil?
    if current_index < 0 || current_index >= commands.length
      current_index = [[current_index, 0].max, commands.length - 1].min
      self.index = current_index
    end
    current_entry = commands[current_index]
    return nil if current_entry.nil?
    return current_entry[0]
  rescue
    return nil
  end

  alias csf_original_pokedex_drawItem drawItem unless method_defined?(:csf_original_pokedex_drawItem)
  def drawItem(index, count, rect)
    return if @commands.nil? || index < 0 || index >= @commands.length || @commands[index].nil?
    csf_original_pokedex_drawItem(index, count, rect)
  rescue => e
    CustomSpeciesFramework.log("Pokedex row draw skipped: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
  end

  alias csf_original_pokedex_refresh refresh unless method_defined?(:csf_original_pokedex_refresh)
  def refresh
    @commands ||= []
    @item_max = itemCount
    dwidth  = self.width - self.borderX
    dheight = self.height - self.borderY
    self.contents = pbDoEnsureBitmap(self.contents, dwidth, dheight)
    self.contents.clear
    if @commands.empty?
      @item_max = 0
      return
    end
    first = self.top_item rescue 0
    page_count = self.page_item_max rescue 0
    last = [first + page_count, @item_max - 1].min
    first.upto(last) do |i|
      drawItem(i, @item_max, itemRect(i))
    end
    drawCursor(self.index, itemRect(self.index)) if self.index && self.index >= 0 && self.index < @item_max
  end
end

class PokemonPokedex_Scene
  alias csf_original_scene_pbStartScene pbStartScene unless method_defined?(:csf_original_scene_pbStartScene)
  def pbStartScene(filter_owned = false)
    start_time = Time.now
    result = csf_original_scene_pbStartScene(filter_owned)
    elapsed = Time.now - start_time
    if elapsed > 0.75 && defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      CustomSpeciesFramework.log("Pokedex start scene took #{format('%.3f', elapsed)}s.")
    end
    return result
  rescue => e
    CustomSpeciesFramework.log("Pokedex start scene failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
    raise
  end

  alias csf_original_scene_pbEndScene pbEndScene unless method_defined?(:csf_original_scene_pbEndScene)
  def pbEndScene
    start_time = Time.now
    result = csf_original_scene_pbEndScene
    elapsed = Time.now - start_time
    if elapsed > 0.75 && defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      CustomSpeciesFramework.log("Pokedex end scene took #{format('%.3f', elapsed)}s.")
    end
    return result
  rescue => e
    CustomSpeciesFramework.log("Pokedex end scene failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
    raise
  end

  alias csf_original_scene_pbGetDexList pbGetDexList unless method_defined?(:csf_original_scene_pbGetDexList)
  def pbGetDexList(filter_owned = false)
    return CustomSpeciesFramework.scene_safe_pokedex_list(filter_owned)
  rescue => e
    CustomSpeciesFramework.log("Pokedex scene pbGetDexList failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
    return []
  end

  alias csf_original_scene_pbRefreshDexList pbRefreshDexList unless method_defined?(:csf_original_scene_pbRefreshDexList)
  def pbRefreshDexList(index = 0)
    start_time = Time.now
    index = 0 if index.nil?
    dexlist = pbGetDexList(@filter_owned)
    dexlist = [] if !dexlist.is_a?(Array)
    dexlist.compact!
    case $PokemonGlobal.pokedexMode
    when MODENUMERICAL
      dexlist[0] = nil if dexlist[0] && dexlist[0][5] && !$Trainer.seen?(dexlist[0][0])
      i = dexlist.length - 1
      loop do
        break unless i >= 0
        break if !dexlist[i] || ($Trainer.seen?(dexlist[i][0]) rescue false)
        dexlist[i] = nil
        i -= 1
      end
      dexlist.compact!
      dexlist.sort! { |a, b| (a[4].to_i == b[4].to_i) ? a[0].to_i <=> b[0].to_i : a[4].to_i <=> b[4].to_i }
    when MODEATOZ
      dexlist.sort! { |a, b| (a[1].to_s == b[1].to_s) ? a[4].to_i <=> b[4].to_i : a[1].to_s <=> b[1].to_s }
    when MODEHEAVIEST
      dexlist.sort! { |a, b| (a[3].to_i == b[3].to_i) ? a[4].to_i <=> b[4].to_i : b[3].to_i <=> a[3].to_i }
    when MODELIGHTEST
      dexlist.sort! { |a, b| (a[3].to_i == b[3].to_i) ? a[4].to_i <=> b[4].to_i : a[3].to_i <=> b[3].to_i }
    when MODETALLEST
      dexlist.sort! { |a, b| (a[2].to_i == b[2].to_i) ? a[4].to_i <=> b[4].to_i : b[2].to_i <=> a[2].to_i }
    when MODESMALLEST
      dexlist.sort! { |a, b| (a[2].to_i == b[2].to_i) ? a[4].to_i <=> b[4].to_i : a[2].to_i <=> b[2].to_i }
    end
    @dexlist = dexlist
    if @sprites && @sprites["pokedex"]
      @sprites["pokedex"].commands = @dexlist
      if @dexlist.empty?
        @sprites["pokedex"].index = 0
      else
        @sprites["pokedex"].index = [[index.to_i, 0].max, @dexlist.length - 1].min
      end
      @sprites["pokedex"].refresh
    end
    if @sprites && @sprites["background"]
      if @searchResults
        @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_listsearch")
      else
        @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_list")
      end
    end
    pbRefresh
    elapsed = Time.now - start_time
    if elapsed > 0.75 && defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      CustomSpeciesFramework.log("Pokedex refresh list took #{format('%.3f', elapsed)}s for #{@dexlist ? @dexlist.length : 0} entries.")
    end
  rescue => e
    CustomSpeciesFramework.log("Pokedex refresh list failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
    @dexlist ||= []
    csf_refresh_empty_pokedex(_INTL("Pokedex data could not be shown safely.")) if respond_to?(:csf_refresh_empty_pokedex)
  end

  alias csf_original_scene_pbRefresh pbRefresh unless method_defined?(:csf_original_scene_pbRefresh)
  def pbRefresh
    if @dexlist.nil? || @dexlist.empty?
      csf_refresh_empty_pokedex(_INTL("No Pokedex data is available."))
      return
    end
    @sprites["icon"].visible = true if @sprites && @sprites["icon"]
    csf_original_scene_pbRefresh
  rescue => e
    CustomSpeciesFramework.log("Pokedex refresh failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
    csf_refresh_empty_pokedex(_INTL("Pokedex data could not be shown safely."))
  end

  alias csf_original_scene_setIconBitmap setIconBitmap unless method_defined?(:csf_original_scene_setIconBitmap)
  def setIconBitmap(species)
    if species.nil? || (species.is_a?(Integer) && species <= 0)
      @sprites["icon"].visible = false if @sprites && @sprites["icon"]
      return
    end
    @sprites["icon"].visible = true if @sprites && @sprites["icon"]
    csf_original_scene_setIconBitmap(species)
  rescue => e
    CustomSpeciesFramework.log("Pokedex icon skipped for #{species.inspect}: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
    @sprites["icon"].visible = false if @sprites && @sprites["icon"]
  end

  def csf_refresh_empty_pokedex(message)
    return if !@sprites || !@sprites["overlay"]
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(88, 88, 80)
    shadow = Color.new(168, 184, 184)
    dexname = _INTL("Pokedex")
    if $Trainer && $Trainer.pokedex.dexes_count > 1
      thisdex = Settings.pokedex_names[pbGetSavePositionIndex] rescue nil
      dexname = thisdex.is_a?(Array) ? thisdex[0] : thisdex if thisdex
    end
    textpos = [
      [dexname, Graphics.width / 2, -2, 2, Color.new(248, 248, 248), Color.new(0, 0, 0)],
      [message, Graphics.width / 2, 176, 2, base, shadow]
    ]
    pbDrawTextPositions(overlay, textpos)
    @sprites["icon"].visible = false if @sprites["icon"]
  rescue => e
    CustomSpeciesFramework.log("Pokedex empty refresh failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
  end
end

class PokemonPokedexScreen
  alias csf_original_pokedex_screen_pbStartScreen pbStartScreen unless method_defined?(:csf_original_pokedex_screen_pbStartScreen)
  def pbStartScreen(filter_owned = false)
    begin
      @scene.pbStartScene(filter_owned)
      @scene.pbPokedex
    rescue => e
      CustomSpeciesFramework.log("Pokedex screen aborted safely: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      pbMessage(_INTL("The Pokedex data could not be displayed safely.")) rescue nil
    ensure
      @scene.pbEndScene rescue nil
    end
  end
end

class PokemonPokedexMenuScreen
  alias csf_original_pokedex_menu_screen_pbStartScreen pbStartScreen unless method_defined?(:csf_original_pokedex_menu_screen_pbStartScreen)
  def pbStartScreen
    commands  = []
    commands2 = []
    dexnames = Settings.pokedex_names
    accessible_dexes = $Trainer.pokedex.accessible_dexes
    accessible_dexes.each do |dex|
      if dexnames[dex].nil?
        commands.push(_INTL("Full Pokedex"))
      elsif dexnames[dex].is_a?(Array)
        commands.push(dexnames[dex][0])
      else
        commands.push(dexnames[dex])
      end
      commands2.push([$Trainer.pokedex.seen_count(dex),
                      $Trainer.pokedex.owned_count(dex),
                      pbGetRegionalDexLength(dex)])
    end
    commands.push(_INTL("Owned Pokemon"))
    commands.push(_INTL("Exit"))

    @scene.pbStartScene(commands, commands2)
    loop do
      cmd = @scene.pbScene
      break if cmd < 0 || cmd > 1
      $PokemonGlobal.pokedexDex = accessible_dexes[0] || -1
      only_owned = cmd == 1
      scene = PokemonPokedex_Scene.new
      screen = PokemonPokedexScreen.new(scene)
      screen.pbStartScreen(only_owned)
    end
  rescue => e
    CustomSpeciesFramework.log("Pokedex menu screen aborted safely: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
    pbMessage(_INTL("The Pokedex data could not be displayed safely.")) rescue nil
  ensure
    @scene.pbEndScene rescue nil
  end
end

alias csf_original_get_unfused_sprite_path get_unfused_sprite_path unless defined?(csf_original_get_unfused_sprite_path)
def get_unfused_sprite_path(dex_number_id, spriteform = nil)
  custom_path = CustomSpeciesFramework.asset_path(:front, dex_number_id)
  return custom_path if custom_path
  fallback_species = CustomSpeciesFramework.fallback_species_for(dex_number_id)
  return csf_original_get_unfused_sprite_path(getDexNumberForSpecies(fallback_species), spriteform) if fallback_species
  return csf_original_get_unfused_sprite_path(dex_number_id, spriteform)
end

module CustomSpeciesFramework
  def self.battler_asset_path(species, back = false)
    runtime_path = runtime_battler_path(species, back)
    return runtime_path if runtime_path
    asset_kind = back ? :back : :front
    direct_path = asset_path(asset_kind, species)
    return direct_path if direct_path
    return asset_path(:front, species) if back

    fallback_species = fallback_species_for(species)
    return nil if fallback_species.nil?
    return battler_asset_path(fallback_species, back)
  end

  def self.load_custom_battler_bitmap(species, back = false, shiny = false, body_shiny = false, head_shiny = false, shiny_value = 0, shiny_r = 0, shiny_g = 1, shiny_b = 2, shiny_krs = nil, shiny_omega = nil)
    battler_path = battler_asset_path(species, back)
    return nil if battler_path.nil?

    sprite = AnimatedBitmap.new(battler_path).recognizeDims rescue AnimatedBitmap.new(battler_path)
    return sprite if !shiny || sprite.nil?

    begin
      if access_deprecated_kurayshiny() == 1 && sprite.respond_to?(:shiftColors)
        dex_number = getDexNumberForSpecies(species)
        hue_offset = GameData::Species.calculateShinyHueOffset(dex_number, body_shiny, head_shiny)
        sprite.shiftColors(hue_offset)
      elsif sprite.respond_to?(:pbGiveFinaleColor)
        sprite.pbGiveFinaleColor(shiny_r, shiny_g, shiny_b, shiny_value, shiny_krs || [0, 0, 0, 0, 0, 0, 0, 0, 0], shiny_omega || {})
      end
    rescue
    end
    return sprite
  end

  def self.load_custom_battler_bitmap_for_ebdx(species, back = false, scale = nil, speed = 2)
    battler_path = battler_asset_path(species, back)
    return nil if battler_path.nil?
    return nil if !defined?(BitmapEBDX)

    default_scale = if defined?(EliteBattle)
                      back ? EliteBattle::BACK_SPRITE_SCALE : EliteBattle::FRONT_SPRITE_SCALE
                    else
                      back ? Settings::BACKRPSPRITE_SCALE : Settings::FRONTSPRITE_SCALE
                    end
    return BitmapEBDX.new(battler_path, scale || default_scale, speed)
  rescue
    return nil
  end

  def self.ebdx_bitmap_request?
    caller_locations(2, 12).any? { |location| location.path.to_s.include?("660_EBDX") }
  rescue
    return false
  end
end

module GameData
  class Species
    class << self
      alias csf_original_front_sprite_bitmap front_sprite_bitmap unless method_defined?(:csf_original_front_sprite_bitmap)
      alias csf_original_back_sprite_bitmap back_sprite_bitmap unless method_defined?(:csf_original_back_sprite_bitmap)

      def front_sprite_bitmap(dex_number, *args)
        custom_bitmap = CustomSpeciesFramework.load_custom_battler_bitmap(
          dex_number,
          false,
          args[2] || false,
          args[3] || false,
          args[4] || false,
          args[5] || 0,
          args[6] || 0,
          args[7] || 1,
          args[8] || 2,
          args[9],
          args[10]
        )
        return custom_bitmap if custom_bitmap
        return csf_original_front_sprite_bitmap(dex_number, *args)
      end

      def back_sprite_bitmap(dex_number, *args)
        custom_bitmap = CustomSpeciesFramework.load_custom_battler_bitmap(
          dex_number,
          true,
          args[2] || false,
          args[3] || false,
          args[4] || false,
          args[5] || 0,
          args[6] || 0,
          args[7] || 1,
          args[8] || 2,
          args[9],
          args[10]
        )
        return custom_bitmap if custom_bitmap
        return csf_original_back_sprite_bitmap(dex_number, *args)
      end
    end
  end
end

alias csf_original_pbLoadPokemonBitmapSpecies pbLoadPokemonBitmapSpecies unless defined?(csf_original_pbLoadPokemonBitmapSpecies)
def pbLoadPokemonBitmapSpecies(pokemon, species, back = false, scale = nil, speed = 2)
  if CustomSpeciesFramework.custom_species?(species)
    if CustomSpeciesFramework.ebdx_bitmap_request?
      custom_bitmap = CustomSpeciesFramework.load_custom_battler_bitmap_for_ebdx(species, back, scale, speed)
      return custom_bitmap if custom_bitmap
    end

    shiny = pokemon.respond_to?(:shiny?) ? pokemon.shiny? : false
    body_shiny = pokemon.respond_to?(:bodyShiny?) ? pokemon.bodyShiny? : false
    head_shiny = pokemon.respond_to?(:headShiny?) ? pokemon.headShiny? : false
    shiny_value = pokemon.respond_to?(:shinyValue?) ? pokemon.shinyValue? : 0
    shiny_r = pokemon.respond_to?(:shinyR?) ? pokemon.shinyR? : 0
    shiny_g = pokemon.respond_to?(:shinyG?) ? pokemon.shinyG? : 1
    shiny_b = pokemon.respond_to?(:shinyB?) ? pokemon.shinyB? : 2
    shiny_krs = pokemon.respond_to?(:shinyKRS?) ? pokemon.shinyKRS? : nil
    shiny_omega = pokemon.respond_to?(:shinyOmega?) ? pokemon.shinyOmega? : nil

    custom_bitmap = CustomSpeciesFramework.load_custom_battler_bitmap(
      species,
      back,
      shiny,
      body_shiny,
      head_shiny,
      shiny_value,
      shiny_r,
      shiny_g,
      shiny_b,
      shiny_krs,
      shiny_omega
    )
    return custom_bitmap if custom_bitmap
  end
  return csf_original_pbLoadPokemonBitmapSpecies(pokemon, species, back, scale, speed)
end

alias csf_original_pbLoadSpeciesBitmap pbLoadSpeciesBitmap unless defined?(csf_original_pbLoadSpeciesBitmap)
def pbLoadSpeciesBitmap(species, female = false, form = 0, shiny = false, shadow = false, back = false, egg = false, scale = nil)
  if !egg && CustomSpeciesFramework.custom_species?(species)
    custom_bitmap = if CustomSpeciesFramework.ebdx_bitmap_request?
                      CustomSpeciesFramework.load_custom_battler_bitmap_for_ebdx(species, back, scale)
                    else
                      CustomSpeciesFramework.load_custom_battler_bitmap(species, back, shiny)
                    end
    return custom_bitmap if custom_bitmap
  end
  return csf_original_pbLoadSpeciesBitmap(species, female, form, shiny, shadow, back, egg, scale)
end

alias csf_original_pbPokemonBitmapFile pbPokemonBitmapFile unless defined?(csf_original_pbPokemonBitmapFile)
def pbPokemonBitmapFile(species, *args)
  back = args.length >= 2 ? args[1] : false
  custom_path = CustomSpeciesFramework.battler_asset_path(species, back)
  return custom_path if custom_path
  return csf_original_pbPokemonBitmapFile(species, *args)
end

alias csf_original_pbCheckPokemonIconFiles pbCheckPokemonIconFiles unless defined?(csf_original_pbCheckPokemonIconFiles)
def pbCheckPokemonIconFiles(speciesID, egg = false, dna = false)
  return csf_original_pbCheckPokemonIconFiles(speciesID, egg, dna) if egg || dna
  custom_path = CustomSpeciesFramework.preferred_icon_path(speciesID)
  custom_path ||= CustomSpeciesFramework.resolve_graphic(:icon, speciesID)
  return custom_path if custom_path.is_a?(String)
  return csf_original_pbCheckPokemonIconFiles(speciesID, egg, dna)
end

alias csf_original_GetSpritePath GetSpritePath unless defined?(csf_original_GetSpritePath)
def GetSpritePath(poke1, poke2, isFused)
  if !isFused
    custom_path = CustomSpeciesFramework.battler_asset_path(poke2, false)
    return custom_path if custom_path
  end
  return csf_original_GetSpritePath(poke1, poke2, isFused)
end

class PokemonIconSprite < SpriteWrapper
  alias csf_original_useRegularIcon useRegularIcon unless method_defined?(:csf_original_useRegularIcon)

  def useRegularIcon(species)
    return true if !CustomSpeciesFramework.actual_fusion_number?(species)
    return csf_original_useRegularIcon(species)
  end
end

class PokemonBoxIcon < IconSprite
  alias csf_original_useRegularIcon useRegularIcon unless method_defined?(:csf_original_useRegularIcon)

  def useRegularIcon(species)
    return true if !CustomSpeciesFramework.actual_fusion_number?(species)
    return csf_original_useRegularIcon(species)
  end
end

class PokemonPokedexInfo_Scene
  alias csf_original_info_pbUpdateDummyPokemon pbUpdateDummyPokemon unless method_defined?(:csf_original_info_pbUpdateDummyPokemon)
  def pbUpdateDummyPokemon
    @dexlist = [] if !@dexlist.is_a?(Array)
    raise "No Pokedex entries available" if @dexlist.empty?
    @index = [[@index.to_i, 0].max, @dexlist.length - 1].min
    entry = @dexlist[@index]
    normalized_entry = CustomSpeciesFramework.normalize_pokedex_list_entry(entry) rescue entry
    raise "Invalid Pokedex entry" if normalized_entry.nil? || normalized_entry[0].nil?
    @dexlist[@index] = normalized_entry
    csf_original_info_pbUpdateDummyPokemon
  rescue => e
    CustomSpeciesFramework.log("Pokedex entry setup failed: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
    raise e
  end

  def list_pokemon_forms
    species_symbol = GameData::Species.get(@species).species
    body_id = if CustomSpeciesFramework.actual_fusion_number?(species_symbol)
                getBodyID(species_symbol)
              else
                species_data = GameData::Species.get(species_symbol)
                species_data.id_number
              end
    forms_list = []
    found_last_form = false
    form_index = 0
    while !found_last_form
      form_index += 1
      form_path = Settings::BATTLERS_FOLDER + body_id.to_s + "_" + form_index.to_s
      if File.directory?(form_path)
        forms_list << form_index
      else
        found_last_form = true
      end
    end
    return forms_list
  end
end

class PokemonPokedexInfoScreen
  alias csf_original_info_screen_pbStartScreen pbStartScreen unless method_defined?(:csf_original_info_screen_pbStartScreen)
  def pbStartScreen(dexlist, index, region)
    ret = index
    begin
      safe_dexlist = []
      Array(dexlist).each do |entry|
        normalized_entry = CustomSpeciesFramework.normalize_pokedex_list_entry(entry) rescue entry
        safe_dexlist << normalized_entry if normalized_entry && normalized_entry[0]
      end
      return ret if safe_dexlist.empty?
      safe_index = [[index.to_i, 0].max, safe_dexlist.length - 1].min
      @scene.pbStartScene(safe_dexlist, safe_index, region)
      ret = @scene.pbScene
    rescue => e
      CustomSpeciesFramework.log("Pokedex entry screen aborted safely: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      pbMessage(_INTL("That Pokedex entry could not be displayed safely.")) rescue nil
    ensure
      @scene.pbEndScene rescue nil
    end
    return ret
  end

  alias csf_original_info_screen_pbStartSceneSingle pbStartSceneSingle unless method_defined?(:csf_original_info_screen_pbStartSceneSingle)
  def pbStartSceneSingle(species)
    completed = false
    begin
      resolved_species = CustomSpeciesFramework.resolve_id_number(species) rescue species
      resolved_species = species if resolved_species.nil?
      csf_original_info_screen_pbStartSceneSingle(resolved_species)
      completed = true
    rescue => e
      CustomSpeciesFramework.log("Single Pokedex entry aborted safely: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      pbMessage(_INTL("That Pokedex entry could not be displayed safely.")) rescue nil
    ensure
      @scene.pbEndScene rescue nil if !completed
    end
  end

  alias csf_original_info_screen_pbDexEntry pbDexEntry unless method_defined?(:csf_original_info_screen_pbDexEntry)
  def pbDexEntry(species)
    completed = false
    begin
      resolved_species = CustomSpeciesFramework.resolve_id_number(species) rescue species
      resolved_species = species if resolved_species.nil?
      csf_original_info_screen_pbDexEntry(resolved_species)
      completed = true
    rescue => e
      CustomSpeciesFramework.log("Caught Pokedex entry aborted safely: #{e.class}: #{e.message}") if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:log)
      pbMessage(_INTL("That Pokedex entry could not be displayed safely.")) rescue nil
    ensure
      @scene.pbEndScene rescue nil if !completed
    end
  end
end

class PokedexUtils
  class << self
    alias csf_original_pbGetAvailableAlts pbGetAvailableAlts unless method_defined?(:csf_original_pbGetAvailableAlts)

    def pbGetAvailableAlts(species, form_index = 0)
      if CustomSpeciesFramework.custom_species?(species) && !CustomSpeciesFramework.actual_fusion_number?(species)
        ret = []
        front_path = CustomSpeciesFramework.asset_path(:front, species)
        ret << front_path if front_path
        fallback_species = CustomSpeciesFramework.fallback_species_for(species)
        if ret.empty? && fallback_species
          return csf_original_pbGetAvailableAlts(fallback_species, form_index)
        end
        return ret
      end
      return csf_original_pbGetAvailableAlts(species, form_index)
    end
  end
end

module CustomSpeciesFramework
  POKEDEX_SPRITE_PAGE_CANVAS_SIZE = 288 unless const_defined?(:POKEDEX_SPRITE_PAGE_CANVAS_SIZE)
  POKEDEX_SPRITE_PAGE_MAX_VISIBLE_SIZE = 198 unless const_defined?(:POKEDEX_SPRITE_PAGE_MAX_VISIBLE_SIZE)
  STORAGE_BOX_ICON_CANVAS_SIZE = 52 unless const_defined?(:STORAGE_BOX_ICON_CANVAS_SIZE)
  STORAGE_BOX_ICON_MAX_VISIBLE_SIZE = 48 unless const_defined?(:STORAGE_BOX_ICON_MAX_VISIBLE_SIZE)
  STORAGE_BOX_ICON_MIN_SHORT_EDGE = 36 unless const_defined?(:STORAGE_BOX_ICON_MIN_SHORT_EDGE)
  STORAGE_BOX_ICON_MAX_WIDE_VISIBLE_SIZE = 50 unless const_defined?(:STORAGE_BOX_ICON_MAX_WIDE_VISIBLE_SIZE)
  STORAGE_BOX_ICON_MAX_UPSCALE = 2.0 unless const_defined?(:STORAGE_BOX_ICON_MAX_UPSCALE)

  def self.pokedex_sprite_page_source_rect(animated_bitmap)
    width = animated_bitmap.width
    height = animated_bitmap.height
    return Rect.new(0, 0, 1, 1) if width.to_i <= 0 || height.to_i <= 0
    if width == 96 && height == 96
      return Rect.new(0, 0, 96, 96)
    elsif width == 288 && height == 288
      return Rect.new(0, 0, 288, 288)
    elsif height > 0 && width >= height * 4 && (width % height) == 0
      # EBDX-style animated strips are stored as square frames in one row.
      return Rect.new(0, 0, height, height)
    elsif width > height && height > 0 && (width.to_f / height.to_f) >= 1.5
      side = [width, height].min
      return Rect.new(0, 0, side, side)
    end
    return Rect.new(0, 0, width, height)
  rescue
    return Rect.new(0, 0, 1, 1)
  end

  def self.bitmap_alpha_bounds(bitmap, source_rect)
    min_x = source_rect.x + source_rect.width
    min_y = source_rect.y + source_rect.height
    max_x = source_rect.x - 1
    max_y = source_rect.y - 1
    y_end = source_rect.y + source_rect.height
    x_end = source_rect.x + source_rect.width
    y = source_rect.y
    while y < y_end
      x = source_rect.x
      while x < x_end
        color = bitmap.get_pixel(x, y) rescue nil
        alpha = color.respond_to?(:alpha) ? color.alpha.to_i : 255
        if alpha > 0
          min_x = x if x < min_x
          min_y = y if y < min_y
          max_x = x if x > max_x
          max_y = y if y > max_y
        end
        x += 1
      end
      y += 1
    end
    return source_rect if max_x < min_x || max_y < min_y
    return Rect.new(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
  rescue
    return source_rect
  end

  def self.pokedex_sprite_page_base_scale(source_rect)
    return 3.0 if source_rect.width <= 96 && source_rect.height <= 96
    return 2.0 if source_rect.width <= 144 && source_rect.height <= 144
    return 1.0
  rescue
    return 1.0
  end

  def self.pokedex_sprite_page_gallery_source(path)
    return nil if blank?(path)
    normalized = path.to_s.tr("\\", "/")
    return path if normalized.include?("/Graphics/BaseSprites/")
    return path if normalized.start_with?("Graphics/BaseSprites/")
    filename = File.basename(normalized, ".*")
    return path if filename !~ /\A\d+(?:_\d+)?[a-z]*\z/i
    wants_gallery_source =
      normalized.include?("/Graphics/EBDX/Battlers/Front/") ||
      normalized.start_with?("Graphics/EBDX/Battlers/Front/") ||
      normalized.include?("/Graphics/Pokemon/Front/") ||
      normalized.start_with?("Graphics/Pokemon/Front/") ||
      normalized.include?("/Graphics/Battlers/") ||
      normalized.start_with?("Graphics/Battlers/")
    return path if !wants_gallery_source

    relative_candidate = "Graphics/BaseSprites/#{filename}.png"
    resolved = pbResolveBitmap(relative_candidate) rescue nil
    return resolved if resolved
    if const_defined?(:GAME_ROOT)
      absolute_candidate = File.join(GAME_ROOT, "Graphics", "BaseSprites", "#{filename}.png")
      return absolute_candidate if File.exist?(absolute_candidate)
    end
    return path
  rescue
    return path
  end

  def self.pokedex_sprite_page_bitmap(path)
    return nil if blank?(path)
    source = nil
    display_path = pokedex_sprite_page_gallery_source(path) || path
    source = AnimatedBitmap.new(display_path)
    source_rect = pokedex_sprite_page_source_rect(source)
    bounds = bitmap_alpha_bounds(source.bitmap, source_rect)
    max_visible = POKEDEX_SPRITE_PAGE_MAX_VISIBLE_SIZE.to_f
    base_scale = pokedex_sprite_page_base_scale(source_rect)
    scale = [
      base_scale,
      max_visible / [bounds.width.to_f, 1.0].max,
      max_visible / [bounds.height.to_f, 1.0].max
    ].min
    scale = 1.0 if scale <= 0

    dest_width = [(bounds.width * scale).round, 1].max
    dest_height = [(bounds.height * scale).round, 1].max
    canvas_size = POKEDEX_SPRITE_PAGE_CANVAS_SIZE
    dest_x = ((canvas_size - dest_width) / 2.0).round
    dest_y = ((canvas_size - dest_height) / 2.0).round

    normalized = Bitmap.new(canvas_size, canvas_size)
    normalized.clear if normalized.respond_to?(:clear)
    normalized.stretch_blt(Rect.new(dest_x, dest_y, dest_width, dest_height), source.bitmap, bounds)
    return AnimatedBitmap.from_bitmap(normalized)
  rescue => e
    log("Pokedex sprite display normalization failed for #{path.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  ensure
    source.dispose if source && source.respond_to?(:dispose) && !source.disposed?
  end

  def self.storage_box_icon_bitmap_from_source(source)
    source_bitmap = source.respond_to?(:bitmap) ? source.bitmap : source
    return nil if source_bitmap.nil?
    return nil if source_bitmap.respond_to?(:disposed?) && source_bitmap.disposed?
    source_rect = if source.respond_to?(:width) && source.respond_to?(:height)
                    pokedex_sprite_page_source_rect(source)
                  else
                    Rect.new(0, 0, source_bitmap.width, source_bitmap.height)
                  end
    bounds = bitmap_alpha_bounds(source_bitmap, source_rect)
    max_visible = STORAGE_BOX_ICON_MAX_VISIBLE_SIZE.to_f
    longest_edge = [bounds.width.to_f, bounds.height.to_f, 1.0].max
    shortest_edge = [[bounds.width.to_f, bounds.height.to_f].min, 1.0].max
    scale = max_visible / longest_edge
    if longest_edge / shortest_edge >= 1.25
      min_short_scale = STORAGE_BOX_ICON_MIN_SHORT_EDGE.to_f / shortest_edge
      wide_cap_scale = STORAGE_BOX_ICON_MAX_WIDE_VISIBLE_SIZE.to_f / longest_edge
      scale = [scale, min_short_scale].max
      scale = [scale, wide_cap_scale].min
    end
    scale = STORAGE_BOX_ICON_MAX_UPSCALE if scale > STORAGE_BOX_ICON_MAX_UPSCALE
    scale = 1.0 if scale <= 0

    dest_width = [(bounds.width * scale).round, 1].max
    dest_height = [(bounds.height * scale).round, 1].max
    canvas_size = STORAGE_BOX_ICON_CANVAS_SIZE
    dest_x = ((canvas_size - dest_width) / 2.0).round
    dest_y = ((canvas_size - dest_height) / 2.0).round

    normalized = Bitmap.new(canvas_size, canvas_size)
    normalized.clear if normalized.respond_to?(:clear)
    normalized.stretch_blt(Rect.new(dest_x, dest_y, dest_width, dest_height), source_bitmap, bounds)
    return AnimatedBitmap.from_bitmap(normalized)
  rescue => e
    log("Storage box icon normalization failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def self.normalize_storage_box_icon_sprite!(sprite)
    return if sprite.nil? || sprite.disposed?
    animated_bitmap = sprite.respond_to?(:getBitmap) ? sprite.getBitmap : nil
    source = animated_bitmap || sprite.bitmap
    normalized = storage_box_icon_bitmap_from_source(source)
    return if normalized.nil?
    sprite.instance_variable_set(:@icon_offset_x, 0) if sprite.instance_variable_defined?(:@icon_offset_x)
    sprite.instance_variable_set(:@icon_offset_y, 0) if sprite.instance_variable_defined?(:@icon_offset_y)
    logical_x = sprite.instance_variable_defined?(:@logical_x) ? sprite.instance_variable_get(:@logical_x) : sprite.x
    logical_y = sprite.instance_variable_defined?(:@logical_y) ? sprite.instance_variable_get(:@logical_y) : sprite.y
    sprite.setBitmapDirectly(normalized)
    sprite.src_rect = Rect.new(0, 0, STORAGE_BOX_ICON_CANVAS_SIZE, STORAGE_BOX_ICON_CANVAS_SIZE) if sprite.bitmap
    sprite.zoom_x = 1.0 if sprite.respond_to?(:zoom_x=)
    sprite.zoom_y = 1.0 if sprite.respond_to?(:zoom_y=)
    sprite.ox = 0 if sprite.respond_to?(:ox=)
    sprite.oy = 0 if sprite.respond_to?(:oy=)
    sprite.x = logical_x if !logical_x.nil?
    sprite.y = logical_y if !logical_y.nil?
  rescue => e
    log("Storage box icon sprite normalization failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end
end

if defined?(PokemonPokedexInfo_Scene)
  class PokemonPokedexInfo_Scene
    def setAvailableBitmaps(available_alts)
      available_alts = [] if !available_alts.is_a?(Array)
      available_alts = available_alts.compact
      if @available_bitmaps
        @available_bitmaps.each do |bmp|
          next if !bmp
          begin
            bmp.dispose if bmp.respond_to?(:dispose) && !bmp.disposed?
          rescue
          end
        end
      end
      @available_bitmap_paths = available_alts.dup
      @available_bitmaps = available_alts.map do |path|
        begin
          normalized = CustomSpeciesFramework.pokedex_sprite_page_bitmap(path)
          normalized || AnimatedBitmap.new(path).recognizeDims()
        rescue
          echoln("Failed to load normalized pokedex sprite bitmap: #{path}")
          nil
        end
      end
    end
  end
end

if defined?(PokemonBoxIcon)
  class PokemonBoxIcon < IconSprite
    alias csf_original_storage_box_icon_refresh refresh unless method_defined?(:csf_original_storage_box_icon_refresh)

    def refresh(fusion_enabled = true)
      result = csf_original_storage_box_icon_refresh(fusion_enabled)
      CustomSpeciesFramework.normalize_storage_box_icon_sprite!(self) if @pokemon
      return result
    end
  end
end

if defined?(PokemonBoxPartySprite)
  class PokemonBoxPartySprite < SpriteWrapper
    alias csf_original_storage_box_party_refresh refresh unless method_defined?(:csf_original_storage_box_party_refresh)

    def refresh
      result = csf_original_storage_box_party_refresh
      if @pokemonsprites.is_a?(Array)
        @pokemonsprites.each do |sprite|
          next if sprite.nil? || sprite.disposed?
          next if !sprite.respond_to?(:pokemon) || !sprite.pokemon
          CustomSpeciesFramework.normalize_storage_box_icon_sprite!(sprite)
        end
      end
      return result
    end
  end
end
