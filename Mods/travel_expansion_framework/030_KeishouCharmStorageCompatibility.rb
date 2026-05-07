if defined?(TravelExpansionFramework)
  module TravelExpansionFramework
    KEISHOU_NORMAL_CHARM_IDS = [
      :APRICORNCHARM, :BALANCECHARM, :BERRYCHARM, :CATCHINGCHARM, :CLOVERCHARM,
      :COINCHARM, :COLORCHARM, :CONTESTCHARM, :CORRUPTCHARM, :CRAFTINGCHARM,
      :DISABLECHARM, :EASYCHARM, :EFFORTCHARM, :EXPALLCHARM, :EXPCHARM,
      :FRUGALCHARM, :GENECHARM, :GOLDCHARM, :HARDCHARM, :HEALINGCHARM,
      :HEARTCHARM, :HUNTERSCHARM, :IVCHARM, :KEYCHARM, :LINKCHARM,
      :LURECHARM, :MERCYCHARM, :MININGCHARM, :NATURECHARM, :OVALCHARM,
      :POINTSCHARM, :PROMOCHARM, :PURIFYCHARM, :RESISTORCHARM, :ROAMINGCHARM,
      :SAFARICHARM, :SHINYCHARM, :SLOTSCHARM, :SMARTCHARM, :SPIRITCHARM,
      :STABCHARM, :STEPCHARM, :TRADINGCHARM, :TRIPTRIADCHARM, :TWINCHARM,
      :VIRALCHARM, :WISHINGCHARM, :ELEMENTCHARM
    ].freeze unless const_defined?(:KEISHOU_NORMAL_CHARM_IDS)

    KEISHOU_ELEMENT_CHARM_IDS = [
      :BUGCHARM, :DARKCHARM, :DRAGONCHARM, :ELECTRICCHARM, :FAIRYCHARM,
      :FIGHTINGCHARM, :FIRECHARM, :FLYINGCHARM, :GHOSTCHARM, :GRASSCHARM,
      :GROUNDCHARM, :ICECHARM, :NORMALCHARM, :PSYCHICCHARM, :POISONCHARM,
      :ROCKCHARM, :STEELCHARM, :WATERCHARM
    ].freeze unless const_defined?(:KEISHOU_ELEMENT_CHARM_IDS)

    KEISHOU_CHARM_IDS = (
      KEISHOU_NORMAL_CHARM_IDS + KEISHOU_ELEMENT_CHARM_IDS
    ).uniq.freeze unless const_defined?(:KEISHOU_CHARM_IDS)

    KEISHOU_EXCLUSIVE_CHARM_GROUPS = [
      [:EASYCHARM, :HARDCHARM],
      [:HEARTCHARM, :MERCYCHARM],
      [:PURIFYCHARM, :CORRUPTCHARM],
      [:BALANCECHARM, :LINKCHARM]
    ].freeze unless const_defined?(:KEISHOU_EXCLUSIVE_CHARM_GROUPS)

    KEISHOU_POKEBOWL_RECIPE_FLAG = "Pokeball" unless const_defined?(:KEISHOU_POKEBOWL_RECIPE_FLAG)
    KEISHOU_CRAFTING_ITEM_FLAGS = {
      :POKEBOWL               => "Pokeball",
      :ITEMCRAFTINGBAG        => "Item",
      :BATTLECRAFTINGBAG      => "BattleItem",
      :TERACRAFTINGBAG        => "TeraItem",
      :MEGACRAFTINGBAG        => "Megastone",
      :TMCRAFTINGLENSCOPPER   => "TMBronze",
      :TMCRAFTINGLENSSILVER   => "TMSilver",
      :TMCRAFTINGLENSGOLD     => "TMGold",
      :TMCRAFTINGLENSPLATINUM => "TMPlatinum"
    }.freeze unless const_defined?(:KEISHOU_CRAFTING_ITEM_FLAGS)

    KEISHOU_ROCK_SMASH_ITEM_PROBABILITY = 50 unless const_defined?(:KEISHOU_ROCK_SMASH_ITEM_PROBABILITY)
    KEISHOU_ROCK_SMASH_ITEMS = [
      [:FIREGEM, 35, 1],
      [:WATERGEM, 35, 1],
      [:ELECTRICGEM, 35, 1],
      [:GRASSGEM, 35, 1],
      [:ICEGEM, 35, 1],
      [:FIGHTINGGEM, 35, 1],
      [:POISONGEM, 35, 1],
      [:GROUNDGEM, 35, 1],
      [:FLYINGGEM, 35, 1],
      [:PSYCHICGEM, 35, 1],
      [:BUGGEM, 35, 1],
      [:ROCKGEM, 35, 1],
      [:GHOSTGEM, 35, 1],
      [:DRAGONGEM, 35, 1],
      [:DARKGEM, 35, 1],
      [:STEELGEM, 35, 1],
      [:NORMALGEM, 35, 1],
      [:FAIRYGEM, 35, 1],
      [:STARDUST, 12, 1],
      [:RELICCOPPER, 12, 1],
      [:MEGASHARD, 50, 6],
      [:MEGASHARD, 50, 8],
      [:MEGASHARD, 50, 12]
    ].freeze unless const_defined?(:KEISHOU_ROCK_SMASH_ITEMS)

    KEISHOU_PORTABLE_ITEM_IDS = (
      [:STORAGEDEVICE, :CHARMCASE, :NOTEBOOK] +
      KEISHOU_CRAFTING_ITEM_FLAGS.keys +
      KEISHOU_CHARM_IDS
    ).uniq.freeze unless const_defined?(:KEISHOU_PORTABLE_ITEM_IDS)

    KEISHOU_ELEMENT_CHARM_TYPES = {
      :BUGCHARM      => :BUG,
      :DARKCHARM     => :DARK,
      :DRAGONCHARM   => :DRAGON,
      :ELECTRICCHARM => :ELECTRIC,
      :FAIRYCHARM    => :FAIRY,
      :FIGHTINGCHARM => :FIGHTING,
      :FIRECHARM     => :FIRE,
      :FLYINGCHARM   => :FLYING,
      :GHOSTCHARM    => :GHOST,
      :GRASSCHARM    => :GRASS,
      :GROUNDCHARM   => :GROUND,
      :ICECHARM      => :ICE,
      :NORMALCHARM   => :NORMAL,
      :PSYCHICCHARM  => :PSYCHIC,
      :POISONCHARM   => :POISON,
      :ROCKCHARM     => :ROCK,
      :STEELCHARM    => :STEEL,
      :WATERCHARM    => :WATER
    }.freeze unless const_defined?(:KEISHOU_ELEMENT_CHARM_TYPES)

    module_function

    def keishou_expansion_ids
      ids = [KEISHOU_EXPANSION_ID]
      ids.concat(KEISHOU_LEGACY_EXPANSION_IDS) if const_defined?(:KEISHOU_LEGACY_EXPANSION_IDS)
      return ids.compact.map(&:to_s).reject { |entry| entry.empty? }.uniq
    rescue
      return ["keishou"]
    end

    def keishou_player
      return $player if defined?($player) && $player
      return $Trainer if defined?($Trainer) && $Trainer
      return nil
    rescue
      return nil
    end

    def keishou_raw_item_symbol(item_identifier)
      raw = item_identifier
      raw = raw.id if raw.respond_to?(:id)
      if respond_to?(:canonical_imported_item_reference)
        canonical = canonical_imported_item_reference(raw) rescue nil
        raw = canonical[1] if canonical && keishou_expansion_ids.include?(canonical[0].to_s)
      end
      if respond_to?(:imported_item_raw_name)
        keishou_expansion_ids.each do |expansion_id|
          raw = imported_item_raw_name(expansion_id, raw)
        end
      end
      text = raw.to_s.strip.gsub(/\A:/, "")
      keishou_expansion_ids.each do |expansion_id|
        prefix = "TEF_#{slugify(expansion_id).upcase}_"
        text = text[prefix.length..-1].to_s if text.upcase.start_with?(prefix)
      end
      text = text.upcase.gsub(/[^\w]+/, "_").gsub(/\A_+|_+\z/, "")
      return nil if text.empty?
      return text.to_sym
    rescue
      text = item_identifier.to_s.strip.gsub(/\A:/, "").upcase
      return nil if text.empty?
      return text.to_sym
    end

    def keishou_charm_symbol(charm)
      raw = keishou_raw_item_symbol(charm)
      return nil if raw.nil?
      return raw
    end

    def keishou_charm_id?(charm)
      raw = keishou_charm_symbol(charm)
      return false if raw.nil?
      return KEISHOU_CHARM_IDS.include?(raw)
    end

    def keishou_element_charm_id?(charm)
      raw = keishou_charm_symbol(charm)
      return false if raw.nil?
      return KEISHOU_ELEMENT_CHARM_IDS.include?(raw)
    end

    def keishou_item_data(symbol)
      return nil if symbol.nil?
      data = base_item_try_get(symbol) if respond_to?(:base_item_try_get)
      data ||= GameData::Item.try_get(symbol) if defined?(GameData::Item)
      return data
    rescue
      return nil
    end

    def keishou_runtime_item_symbol(raw)
      symbols = keishou_runtime_item_symbols(raw)
      return symbols.first
    rescue
      return nil
    end

    def keishou_runtime_item_symbols(raw)
      raw_symbol = keishou_raw_item_symbol(raw)
      return [] if raw_symbol.nil?
      symbols = []
      if respond_to?(:ensure_external_item_registered)
        keishou_expansion_ids.each do |expansion_id|
          runtime = ensure_external_item_registered(expansion_id, raw_symbol)
          symbols << runtime if runtime
        end
      end
      symbols << raw_symbol if keishou_item_data(raw_symbol)
      return symbols.compact.uniq
    rescue
      return []
    end

    def keishou_item_catalog
      return generic_pbs_item_catalog(KEISHOU_EXPANSION_ID) if respond_to?(:generic_pbs_item_catalog)
      return {}
    rescue
      return {}
    end

    def keishou_item_catalog_entry(raw)
      raw_symbol = keishou_raw_item_symbol(raw)
      return nil if raw_symbol.nil?
      normalized = normalized_imported_item_name(raw_symbol) if respond_to?(:normalized_imported_item_name)
      normalized ||= raw_symbol.to_s.upcase.gsub(/[^\w]+/, "")
      entry = keishou_item_catalog[normalized]
      return entry.is_a?(Hash) ? entry : nil
    rescue
      return nil
    end

    def keishou_item_catalog_paths
      roots = []
      if respond_to?(:external_projects)
        keishou_expansion_ids.each do |expansion_id|
          info = external_projects[expansion_id]
          next if !info.is_a?(Hash)
          roots << (info[:root] || info["root"])
          roots << (info[:filesystem_bridge_root] || info["filesystem_bridge_root"])
          roots << (info[:source_mount_root] || info["source_mount_root"])
          roots << (info[:archive_mount_root] || info["archive_mount_root"])
        end
      end
      if respond_to?(:linked_project_bridge_root)
        keishou_expansion_ids.each do |expansion_id|
          roots << linked_project_bridge_root(expansion_id)
        end
      end
      roots << File.expand_path("C:/Games/PIF/ExpansionLibrary/LinkedProjects/keishou")
      paths = []
      roots.compact.map(&:to_s).reject { |root| root.empty? }.uniq.each do |root|
        Dir[File.join(root, "PBS", "items*.txt")].sort.each do |candidate|
          exact = runtime_exact_file_path(candidate) if respond_to?(:runtime_exact_file_path)
          exact ||= candidate
          paths << exact if exact && File.file?(exact)
        end
      end
      return paths.uniq
    rescue
      return []
    end

    def keishou_full_item_catalog
      @keishou_full_item_catalog ||= begin
        catalog = {}
        keishou_item_catalog_paths.each do |path|
          parsed = parse_generic_pbs_item_catalog(path) if respond_to?(:parse_generic_pbs_item_catalog)
          catalog.merge!(parsed) if parsed.is_a?(Hash)
        end
        catalog.merge!(keishou_item_catalog) if keishou_item_catalog.is_a?(Hash)
        catalog
      end
    rescue => e
      log("[keishou] full item catalog parse failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return keishou_item_catalog
    end

    def keishou_item_definition_from_catalog(raw)
      raw_symbol = keishou_raw_item_symbol(raw)
      return nil if raw_symbol.nil?
      normalized = normalized_imported_item_name(raw_symbol) if respond_to?(:normalized_imported_item_name)
      normalized ||= raw_symbol.to_s.upcase.gsub(/[^\w]+/, "")
      entry = keishou_full_item_catalog[normalized]
      entry = keishou_item_catalog_entry(raw_symbol) if !entry.is_a?(Hash)
      return nil if !entry.is_a?(Hash)
      display_name = normalize_imported_item_text(entry[:name] || raw_symbol.to_s) if respond_to?(:normalize_imported_item_text)
      display_name ||= entry[:name].to_s
      display_name = raw_symbol.to_s if display_name.empty?
      display_plural = normalize_imported_item_text(entry[:nameplural] || entry[:name_plural] || "#{display_name}s") if respond_to?(:normalize_imported_item_text)
      display_plural ||= entry[:nameplural].to_s
      display_plural = "#{display_name}s" if display_plural.empty?
      description = normalize_imported_item_text(entry[:description]) if respond_to?(:normalize_imported_item_text)
      description ||= entry[:description].to_s
      return nil if description.empty?
      flags = generic_pbs_item_flags(entry).map { |flag| flag.to_s.downcase } if respond_to?(:generic_pbs_item_flags)
      flags ||= entry[:flags].to_s.split(",").map { |flag| flag.strip.downcase }
      pocket = integer(entry[:pocket], 1)
      field_use = generic_pbs_item_field_use(entry[:fielduse] || entry[:field_use]) if respond_to?(:generic_pbs_item_field_use)
      field_use = integer(entry[:fielduse] || entry[:field_use], 0) if field_use.nil?
      battle_use = generic_pbs_item_battle_use(entry[:battleuse] || entry[:battle_use]) if respond_to?(:generic_pbs_item_battle_use)
      battle_use = integer(entry[:battleuse] || entry[:battle_use], 0) if battle_use.nil?
      type = 0
      if flags.include?("keyitem") || flags.include?("key_item") || pocket == 8
        pocket = 8
        type = 6
      elsif flags.include?("mail")
        pocket = 6
        type = flags.include?("iconmail") || flags.include?("icon_mail") ? 2 : 1
      elsif flags.include?("pokeball") || normalized.end_with?("BALL")
        pocket = 3
        type = 3
      elsif flags.include?("berry") || normalized.end_with?("BERRY")
        pocket = 5
        type = 5
      elsif flags.include?("megastone") || flags.include?("mega_stone")
        type = 12
      elsif flags.include?("fossil")
        type = 8
      end
      return {
        :name        => display_name,
        :name_plural => display_plural,
        :description => description,
        :price       => integer(entry[:price], 0),
        :pocket      => pocket,
        :type        => type,
        :field_use   => field_use,
        :battle_use  => battle_use,
        :raw_name    => raw_symbol,
        :icon_logical_path => "Graphics/Items/#{raw_symbol}"
      }
    rescue => e
      log("[keishou] item definition lookup failed for #{raw.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
      return nil
    end

    def keishou_item_metadata_definition(raw)
      definition = keishou_item_definition_from_catalog(raw)
      return definition if definition.is_a?(Hash)
      if respond_to?(:generic_pbs_item_definition)
        definition = generic_pbs_item_definition(KEISHOU_EXPANSION_ID, raw)
        return definition if definition.is_a?(Hash)
      end
      entry = keishou_item_catalog_entry(raw)
      return nil if !entry.is_a?(Hash)
      name = entry[:name] || raw
      plural = entry[:nameplural] || entry[:name_plural] || "#{name}s"
      description = entry[:description]
      return nil if description.to_s.empty?
      {
        :name        => name,
        :name_plural => plural,
        :description => description,
        :price       => entry[:price] || 0,
        :pocket      => entry[:pocket] || 1,
        :type        => 0,
        :field_use   => 0,
        :battle_use  => 0
      }
    rescue
      return nil
    end

    def keishou_apply_item_metadata!(raw)
      raw_symbol = keishou_raw_item_symbol(raw)
      return false if raw_symbol.nil?
      item_data_list = (keishou_runtime_item_symbols(raw_symbol) + [raw_symbol]).map { |candidate| keishou_item_data(candidate) }.compact.uniq
      return false if item_data_list.empty?
      definition = keishou_item_metadata_definition(raw_symbol)
      return false if !definition.is_a?(Hash)
      display_name = definition[:name].to_s
      display_name = humanize_external_item_name(raw_symbol.to_s) if display_name.empty? && respond_to?(:humanize_external_item_name)
      display_name = raw_symbol.to_s if display_name.empty?
      display_plural = definition[:name_plural].to_s
      display_plural = "#{display_name}s" if display_plural.empty?
      description = definition[:description].to_s
      return false if description.empty?
      item_data_list.each do |item_data|
        id_number = item_data.id_number if item_data.respond_to?(:id_number)
        item_data.instance_variable_set(:@real_name, display_name)
        item_data.instance_variable_set(:@real_name_plural, display_plural)
        item_data.instance_variable_set(:@real_description, description)
        item_data.instance_variable_set(:@pocket, integer(definition[:pocket], item_data.pocket)) if respond_to?(:integer) && item_data.respond_to?(:pocket)
        item_data.instance_variable_set(:@price, integer(definition[:price], item_data.price)) if respond_to?(:integer) && item_data.respond_to?(:price)
        item_data.instance_variable_set(:@field_use, integer(definition[:field_use], item_data.field_use)) if respond_to?(:integer) && item_data.respond_to?(:field_use)
        item_data.instance_variable_set(:@battle_use, integer(definition[:battle_use], item_data.battle_use)) if respond_to?(:integer) && item_data.respond_to?(:battle_use)
        item_data.instance_variable_set(:@type, integer(definition[:type], item_data.type)) if respond_to?(:integer) && item_data.respond_to?(:type)
        if defined?(MessageTypes) && id_number && id_number.to_i >= 0
          MessageTypes.set(MessageTypes::Items, id_number, display_name)
          MessageTypes.set(MessageTypes::ItemPlurals, id_number, display_plural)
          MessageTypes.set(MessageTypes::ItemDescriptions, id_number, description)
        end
        if respond_to?(:imported_runtime_items)
          metadata_expansion = KEISHOU_EXPANSION_ID
          canonical = canonical_imported_item_reference(item_data.id) if respond_to?(:canonical_imported_item_reference)
          metadata_expansion = canonical[0].to_s if canonical && keishou_expansion_ids.include?(canonical[0].to_s)
          metadata = imported_runtime_items[item_data.id] || {}
          metadata = metadata.merge(definition).merge({
            :runtime_symbol => item_data.id,
            :raw_name       => raw_symbol,
            :expansion_id   => metadata_expansion,
            :id_number      => id_number
          })
          imported_runtime_items[item_data.id] = metadata
          imported_runtime_item_lookup[item_data.id] = metadata if respond_to?(:imported_runtime_item_lookup)
          imported_runtime_item_lookup[item_data.id.to_s] = metadata if respond_to?(:imported_runtime_item_lookup)
          imported_runtime_item_lookup[id_number] = metadata if respond_to?(:imported_runtime_item_lookup) && id_number
          imported_runtime_item_lookup[id_number.to_s] = metadata if respond_to?(:imported_runtime_item_lookup) && id_number
          attach_imported_item_metadata(item_data, metadata) if respond_to?(:attach_imported_item_metadata)
          remember_imported_item_origin(metadata) if respond_to?(:remember_imported_item_origin)
        end
      end
      return true
    rescue => e
      log("[keishou] item metadata refresh failed for #{raw.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_item_display_definition_for_item(item)
      return nil if item.nil?
      metadata = item.instance_variable_get(:@travel_expansion_item_metadata) rescue nil
      raw = nil
      if metadata.is_a?(Hash) && respond_to?(:imported_item_metadata_value) &&
         keishou_expansion_ids.include?(imported_item_metadata_value(metadata, :expansion_id).to_s)
        raw = imported_item_metadata_value(metadata, :raw_name)
      end
      raw ||= item.id if item.respond_to?(:id)
      raw = keishou_raw_item_symbol(raw)
      return nil if raw.nil?
      definition = keishou_item_metadata_definition(raw)
      return definition if definition.is_a?(Hash)
      return nil
    rescue
      return nil
    end

    def keishou_item_display_value(item, key)
      definition = keishou_item_display_definition_for_item(item)
      return nil if !definition.is_a?(Hash)
      value = definition[key]
      value = definition[key.to_s] if value.nil?
      return nil if value.nil? || value.to_s.empty?
      return value.to_s
    rescue
      return nil
    end

    def keishou_native_item_icon_filename(item_data)
      return nil if item_data.nil? || !item_data.respond_to?(:id)
      raw = keishou_raw_item_symbol(item_data.id)
      return nil if raw.nil?
      normalized = normalized_imported_item_name(raw) if respond_to?(:normalized_imported_item_name)
      normalized ||= raw.to_s.upcase.gsub(/[^\w]+/, "")
      has_keishou_icon_context = keishou_active_now? ||
                                 raw == :WAILMERPAIL ||
                                 (respond_to?(:known_imported_item_origin_id) &&
                                  keishou_expansion_ids.include?(known_imported_item_origin_id(raw).to_s))
      return nil if !has_keishou_icon_context
      return nil if !keishou_full_item_catalog.has_key?(normalized) && !KEISHOU_PORTABLE_ITEM_IDS.include?(raw)
      logical = "Graphics/Items/#{raw}"
      extensions = const_defined?(:REBORN_ITEM_ICON_EXTENSIONS) ? REBORN_ITEM_ICON_EXTENSIONS : [".png", ".gif", ".bmp"]
      keishou_expansion_ids.each do |expansion_id|
        resolved = resolve_runtime_path_for_expansion(expansion_id, logical, extensions) if respond_to?(:resolve_runtime_path_for_expansion)
        if resolved && !resolved.to_s.empty?
          return resolved.to_s.sub(/\.(png|gif|bmp)\z/i, "")
        end
      end
      direct = File.expand_path("C:/Games/PIF/ExpansionLibrary/LinkedProjects/keishou/#{logical}.png")
      return direct.sub(/\.(png|gif|bmp)\z/i, "") if File.file?(direct)
      return nil
    rescue => e
      log("[keishou] native item icon lookup failed for #{item_data.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
      return nil
    end

    def keishou_refresh_item_metadata!
      refreshed = 0
      KEISHOU_PORTABLE_ITEM_IDS.each do |raw|
        refreshed += 1 if keishou_apply_item_metadata!(raw)
      end
      clear_item_icon_filename_cache! if refreshed > 0 && respond_to?(:clear_item_icon_filename_cache!)
      log("[keishou] refreshed #{refreshed} item names/descriptions from PBS") if refreshed > 0 && respond_to?(:log)
      return refreshed
    rescue => e
      log("[keishou] item metadata refresh pass failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return 0
    end

    def keishou_item_name(raw, fallback = nil)
      raw_symbol = keishou_raw_item_symbol(raw)
      candidates = []
      runtime = keishou_runtime_item_symbol(raw_symbol)
      candidates << runtime if runtime
      candidates << raw_symbol if raw_symbol
      candidates.compact.uniq.each do |candidate|
        item_data = keishou_item_data(candidate)
        return item_data.name.to_s if item_data && item_data.respond_to?(:name) && !item_data.name.to_s.empty?
      end
      text = fallback || raw_symbol || raw
      return humanize_external_item_name(text.to_s) if respond_to?(:humanize_external_item_name)
      return text.to_s.gsub("_", " ").split(/\s+/).map { |part| part[0] ? part[0].upcase + part[1..-1].downcase : part }.join(" ")
    rescue
      return fallback.to_s if fallback && !fallback.to_s.empty?
      return raw.to_s
    end

    def keishou_bag
      return $PokemonBag if defined?($PokemonBag) && $PokemonBag
      return $bag if defined?($bag) && $bag
      return nil
    rescue
      return nil
    end

    def sync_keishou_bag_alias!
      $bag = $PokemonBag if defined?($PokemonBag) && $PokemonBag
      return $bag if defined?($bag) && $bag
      return nil
    rescue
      return nil
    end

    def keishou_active_now?(map_id = nil)
      ids = [KEISHOU_EXPANSION_ID]
      ids.concat(KEISHOU_LEGACY_EXPANSION_IDS) if const_defined?(:KEISHOU_LEGACY_EXPANSION_IDS)
      candidates = []
      candidates << current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
      candidates << current_expansion_marker if respond_to?(:current_expansion_marker)
      candidates << current_map_expansion_id(map_id) if respond_to?(:current_map_expansion_id)
      return candidates.compact.any? { |entry| ids.include?(entry.to_s) }
    rescue
      return false
    end

    def keishou_catalog_item?(item)
      return false if item.nil?
      normalized = normalized_imported_item_name(item) if respond_to?(:normalized_imported_item_name)
      return false if normalized.to_s.empty?
      catalog = keishou_full_item_catalog
      return catalog.is_a?(Hash) && catalog.has_key?(normalized)
    rescue
      return false
    end

    def keishou_should_resolve_external_item?(item)
      return false if item.nil?
      canonical = canonical_imported_item_reference(item) if respond_to?(:canonical_imported_item_reference)
      return canonical && keishou_expansion_ids.include?(canonical[0].to_s) if canonical
      return true if keishou_active_now?
      origin = known_imported_item_origin_id(item) if respond_to?(:known_imported_item_origin_id)
      return true if keishou_expansion_ids.include?(origin.to_s)
      return keishou_catalog_item?(item)
    rescue
      return false
    end

    def keishou_resolve_bag_item(item)
      return nil if item.nil?
      raw = item.respond_to?(:id) ? item.id : item
      data = base_item_try_get(raw) if respond_to?(:base_item_try_get)
      return data.id if data && data.respond_to?(:id)
      runtimes = []
      if raw.is_a?(Symbol) || raw.is_a?(String)
        runtimes = keishou_runtime_item_symbols(raw) if keishou_should_resolve_external_item?(raw)
      end
      runtimes.each do |runtime|
        data = keishou_item_data(runtime)
        return data.id if data && data.respond_to?(:id)
      end
      data = GameData::Item.try_get(raw) if defined?(GameData::Item)
      return data.id if data && data.respond_to?(:id)
      return runtimes.first if !runtimes.empty?
      return raw
    rescue
      return item.respond_to?(:id) ? item.id : item
    end

    def keishou_bag_item_candidates(item)
      candidates = []
      raw = item.respond_to?(:id) ? item.id : item
      candidates << raw
      raw_symbol = keishou_raw_item_symbol(raw)
      candidates << raw_symbol if raw_symbol
      runtimes = []
      runtimes = keishou_runtime_item_symbols(raw_symbol || raw) if (raw_symbol || raw) &&
                                                                    keishou_should_resolve_external_item?(raw_symbol || raw)
      candidates.concat(runtimes)
      data = nil
      runtimes.each do |runtime|
        data = keishou_item_data(runtime)
        break if data
      end
      data ||= keishou_item_data(raw_symbol) if raw_symbol
      data ||= keishou_item_data(raw)
      if data
        candidates << data.id if data.respond_to?(:id)
        candidates << data.id_number if data.respond_to?(:id_number)
      end
      return candidates.compact.uniq
    rescue
      return [item].compact
    end

    def keishou_bag_slot_quantity(bag, item)
      candidates = keishou_bag_item_candidates(item)
      return 0 if bag.nil? || candidates.empty?
      normalized = candidates.map { |entry| entry.is_a?(String) ? entry.to_sym : entry }.compact
      normalized.concat(candidates.map(&:to_s))
      total = 0
      pockets = bag.instance_variable_get(:@pockets) if bag.respond_to?(:instance_variable_get)
      Array(pockets).each do |pocket|
        Array(pocket).each do |slot|
          next if !slot || !slot[0]
          key = slot[0]
          total += slot[1].to_i if normalized.include?(key) || normalized.include?(key.to_s)
        end
      end
      return total
    rescue
      return 0
    end

    def keishou_bag_quantity(item)
      bag = sync_keishou_bag_alias! || keishou_bag
      return 0 if bag.nil? || item.nil?
      resolved = keishou_resolve_bag_item(item)
      manual = keishou_bag_slot_quantity(bag, item)
      native = 0
      native = bag.pbQuantity(resolved) if resolved && bag.respond_to?(:pbQuantity)
      return [manual, native.to_i].max
    rescue
      return 0
    end

    def keishou_bag_has_item?(item, qty = 1)
      bag = keishou_bag
      return false if bag.nil? || item.nil?
      return keishou_bag_quantity(item) >= [qty.to_i, 1].max
    rescue
      return false
    end

    def keishou_bag_can_store_item?(item, qty = 1)
      bag = sync_keishou_bag_alias! || keishou_bag
      resolved = keishou_resolve_bag_item(item)
      return false if bag.nil? || resolved.nil?
      return bag.pbCanStore?(resolved, qty.to_i) if bag.respond_to?(:pbCanStore?)
      return true
    rescue
      return false
    end

    def keishou_store_bag_item(item, qty = 1)
      bag = sync_keishou_bag_alias! || keishou_bag
      resolved = keishou_resolve_bag_item(item)
      return false if bag.nil? || resolved.nil?
      return bag.pbStoreItem(resolved, qty.to_i) if bag.respond_to?(:pbStoreItem)
      return bag.add(resolved, qty.to_i) if bag.respond_to?(:add)
      return false
    rescue => e
      log("[keishou] failed storing bag item #{item.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_delete_bag_item(item, qty = 1)
      bag = sync_keishou_bag_alias! || keishou_bag
      resolved = keishou_resolve_bag_item(item)
      return false if bag.nil? || resolved.nil?
      return true if qty.to_i <= 0
      return true if bag.respond_to?(:pbDeleteItem) && (bag.pbDeleteItem(resolved, qty.to_i) rescue false)
      keishou_bag_item_candidates(item).each do |candidate|
        next if candidate.nil? || candidate == resolved
        return true if bag.respond_to?(:pbDeleteItem) && (bag.pbDeleteItem(candidate, qty.to_i) rescue false)
      end
      return bag.remove(resolved, qty.to_i) if bag.respond_to?(:remove)
      return false
    rescue => e
      log("[keishou] failed deleting bag item #{item.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_receive_item(item)
      resolved = keishou_resolve_bag_item(item)
      return true if keishou_bag_has_item?(resolved)
      if defined?(pbReceiveItem)
        received = pbReceiveItem(resolved) rescue false
        return true if received
      end
      return keishou_store_bag_item(resolved)
    rescue => e
      log("[keishou] failed to receive #{item.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def ensure_keishou_charm_case!(show_intro = true)
      raw = :CHARMCASE
      runtime = keishou_runtime_item_symbol(raw)
      candidates = [runtime, raw].compact.uniq
      return true if candidates.any? { |candidate| keishou_bag_has_item?(candidate) }
      pbMessage(_INTL("It looks like you haven't received a Charm Case yet!")) if show_intro && defined?(pbMessage)
      item = candidates.find { |candidate| keishou_item_data(candidate) } || runtime
      return true if item.nil?
      result = keishou_receive_item(item)
      log("[keishou] granted Charm Case via compatibility handler item=#{item.inspect} result=#{result}") if respond_to?(:log)
      return true
    rescue => e
      log("[keishou] Charm Case grant failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return true
    end

    def keishou_player_value(player, ivar_name, fallback)
      value = player.instance_variable_get(ivar_name) if player
      return fallback if value.nil?
      return value
    rescue
      return fallback
    end

    def keishou_set_player_value(player, ivar_name, value)
      player.instance_variable_set(ivar_name, value) if player
      return value
    rescue
      return value
    end

    def keishou_symbol_list(value)
      Array(value).compact.map { |entry| keishou_raw_item_symbol(entry) }.compact.uniq
    rescue
      return []
    end

    def keishou_initialize_charms!(player = nil)
      player ||= keishou_player
      return false if player.nil?
      charmlist = keishou_symbol_list(keishou_player_value(player, :@charmlist, []))
      element_list = keishou_symbol_list(keishou_player_value(player, :@elementCharmlist, []))
      active = keishou_player_value(player, :@charmsActive, {})
      active = {} if !active.is_a?(Hash)
      normalized_active = {}
      active.each_pair do |key, value|
        raw = keishou_raw_item_symbol(key)
        normalized_active[raw] = value ? true : false if raw
      end
      KEISHOU_CHARM_IDS.each { |raw| normalized_active[raw] = false if !normalized_active.has_key?(raw) }
      keishou_set_player_value(player, :@charmlist, charmlist)
      keishou_set_player_value(player, :@elementCharmlist, element_list)
      keishou_set_player_value(player, :@charmsActive, normalized_active)
      keishou_set_player_value(player, :@eleCharmsActive, {}) if keishou_player_value(player, :@eleCharmsActive, nil).nil?
      keishou_set_player_value(player, :@last_wish_time, 0) if keishou_player_value(player, :@last_wish_time, nil).nil?
      keishou_set_player_value(player, :@link_charm_data, [0, 0, [], nil]) if keishou_player_value(player, :@link_charm_data, nil).nil?
      keishou_set_player_value(player, :@ball_for_apricorn, 0) if keishou_player_value(player, :@ball_for_apricorn, nil).nil?
      keishou_set_player_value(player, :@next_run, 0) if keishou_player_value(player, :@next_run, nil).nil?
      keishou_set_player_value(player, :@activeNature, []) if keishou_player_value(player, :@activeNature, nil).nil?
      keishou_set_player_value(player, :@natureList, []) if keishou_player_value(player, :@natureList, nil).nil?
      keishou_set_player_value(player, :@maxCharms, 3) if keishou_player_value(player, :@maxCharms, nil).nil?
      keishou_count_active_charms(player)
      return true
    rescue => e
      log("[keishou] initialize charms failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_active_charm?(charm, player = nil)
      player ||= keishou_player
      return false if player.nil?
      raw = keishou_charm_symbol(charm)
      return false if raw.nil?
      keishou_initialize_charms!(player)
      active = keishou_player_value(player, :@charmsActive, {})
      return active[raw] == true
    rescue
      return false
    end

    def keishou_count_active_charms(player = nil)
      player ||= keishou_player
      return 0 if player.nil?
      active = keishou_player_value(player, :@charmsActive, {})
      count = 0
      KEISHOU_NORMAL_CHARM_IDS.each do |raw|
        next if raw == :ELEMENTCHARM
        count += 1 if active[raw] == true
      end
      count += 1 if KEISHOU_ELEMENT_CHARM_IDS.any? { |raw| active[raw] == true }
      keishou_set_player_value(player, :@active_count, count)
      return count
    rescue
      return 0
    end

    def keishou_max_active_charms(player = nil)
      player ||= keishou_player
      keishou_initialize_charms!(player) if player
      max_charms = keishou_player_value(player, :@maxCharms, 3)
      return [max_charms.to_i, 0].max
    rescue
      return 3
    end

    def keishou_charm_limit_exempt?(charm)
      raw = keishou_charm_symbol(charm)
      return true if raw.nil?
      return true if [:WISHINGCHARM, :NATURECHARM, :ELEMENTCHARM].include?(raw)
      return false
    rescue
      return false
    end

    def keishou_set_charm_active!(charm, value, player = nil)
      player ||= keishou_player
      return false if player.nil?
      raw = keishou_charm_symbol(charm)
      return false if raw.nil?
      keishou_initialize_charms!(player)
      active = keishou_player_value(player, :@charmsActive, {})
      if value && keishou_element_charm_id?(raw)
        if active[raw] != true && active[:ELEMENTCHARM] != true && !keishou_charm_limit_exempt?(raw) &&
           keishou_count_active_charms(player) >= keishou_max_active_charms(player)
          return false
        end
        KEISHOU_ELEMENT_CHARM_IDS.each { |element| active[element] = false }
        active[:ELEMENTCHARM] = true
      elsif !value && keishou_element_charm_id?(raw)
        active[:ELEMENTCHARM] = KEISHOU_ELEMENT_CHARM_IDS.any? { |element| element != raw && active[element] == true }
      elsif value
        KEISHOU_EXCLUSIVE_CHARM_GROUPS.each do |group|
          next if !group.include?(raw)
          group.each { |other| active[other] = false if other != raw }
        end
        if active[raw] != true && !keishou_charm_limit_exempt?(raw) &&
           keishou_count_active_charms(player) >= keishou_max_active_charms(player)
          return false
        end
      end
      active[raw] = value ? true : false
      active[:ELEMENTCHARM] = false if !KEISHOU_ELEMENT_CHARM_IDS.any? { |element| active[element] == true }
      keishou_set_player_value(player, :@charmsActive, active)
      keishou_count_active_charms(player)
      return active[raw] == true
    rescue => e
      log("[keishou] set charm #{charm.inspect} failed: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_toggle_charm(charm, display_message = true, player = nil)
      player ||= keishou_player
      return false if player.nil?
      raw = keishou_charm_symbol(charm)
      return false if raw.nil?
      next_state = !keishou_active_charm?(raw, player)
      changed = keishou_set_charm_active!(raw, next_state, player)
      if next_state && !changed
        pbMessage(_INTL("You can only have {1} charms active at once.", keishou_max_active_charms(player))) if display_message && defined?(pbMessage)
        return false
      end
      if display_message && defined?(pbMessage)
        state_text = next_state ? "enabled" : "disabled"
        pbMessage(_INTL("The {1} was {2}.", keishou_item_name(raw), state_text))
      end
      return next_state
    end

    def keishou_gain_charm(charm, silent = false, element = false)
      player = keishou_player
      return false if player.nil?
      raw = keishou_charm_symbol(charm)
      if raw.nil?
        pbMessage(_INTL("That charm is not available.")) if !silent && defined?(pbMessage)
        return false
      end
      element = true if keishou_element_charm_id?(raw)
      ensure_keishou_charm_case!(!silent)
      keishou_initialize_charms!(player)
      list_name = element ? :@elementCharmlist : :@charmlist
      list = keishou_symbol_list(keishou_player_value(player, list_name, []))
      if !list.include?(raw)
        list << raw
        keishou_set_player_value(player, list_name, list)
        keishou_set_charm_active!(raw, true, player)
        pbMessage(_INTL("{1} is now available in the Charm Case!", keishou_item_name(raw))) if !silent && defined?(pbMessage)
        log("[keishou] gained charm #{raw}") if respond_to?(:log)
        return true
      end
      pbMessage(_INTL("{1} is already in the Charm Case.", keishou_item_name(raw))) if !silent && defined?(pbMessage)
      return true
    rescue => e
      log("[keishou] gain charm #{charm.inspect} failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      pbMessage(_INTL("That charm could not be added safely.")) if !silent && defined?(pbMessage)
      return false
    end

    def keishou_remove_charm(charm, silent = false)
      player = keishou_player
      return false if player.nil?
      raw = keishou_charm_symbol(charm)
      return false if raw.nil?
      keishou_initialize_charms!(player)
      [:@charmlist, :@elementCharmlist].each do |list_name|
        list = keishou_symbol_list(keishou_player_value(player, list_name, []))
        list.delete(raw)
        keishou_set_player_value(player, list_name, list)
      end
      keishou_set_charm_active!(raw, false, player)
      pbMessage(_INTL("{1} was removed from the Charm Case.", keishou_item_name(raw))) if !silent && defined?(pbMessage)
      log("[keishou] removed charm #{raw}") if respond_to?(:log)
      return true
    rescue => e
      log("[keishou] remove charm #{charm.inspect} failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_deactivate_all_charms
      player = keishou_player
      return false if player.nil?
      keishou_initialize_charms!(player)
      active = keishou_player_value(player, :@charmsActive, {})
      active.keys.each { |key| active[key] = false }
      keishou_set_player_value(player, :@charmsActive, active)
      keishou_count_active_charms(player)
      return true
    rescue
      return false
    end

    def keishou_give_all_charms(element = false)
      ids = element ? KEISHOU_ELEMENT_CHARM_IDS : (KEISHOU_NORMAL_CHARM_IDS - [:ELEMENTCHARM])
      ids.each { |raw| keishou_gain_charm(raw, true, element) }
      return true
    rescue => e
      log("[keishou] give all charms failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_open_charm_case
      player = keishou_player
      return false if player.nil?
      keishou_initialize_charms!(player)
      entries = keishou_symbol_list(keishou_player_value(player, :@charmlist, [])) +
                keishou_symbol_list(keishou_player_value(player, :@elementCharmlist, []))
      entries = entries.uniq.select { |raw| keishou_charm_id?(raw) }
      if entries.empty?
        pbMessage(_INTL("There are no charms in the Charm Case.")) if defined?(pbMessage)
        return true
      end
      command = 0
      loop do
        commands = entries.map do |raw|
          state = keishou_active_charm?(raw, player) ? "On" : "Off"
          _INTL("{1}: {2}", keishou_item_name(raw), state)
        end
        commands << _INTL("Close")
        command = pbMessage(_INTL("Choose a charm."), commands, commands.length - 1, nil, command)
        break if command.nil? || command < 0 || command >= entries.length
        keishou_toggle_charm(entries[command], true, player)
      end
      return true
    rescue => e
      log("[keishou] Charm Case UI fallback failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      pbMessage(_INTL("The Charm Case cannot be opened right now.")) if defined?(pbMessage)
      return false
    end

    def keishou_open_storage_device
      command = 0
      loop do
        commands = [_INTL("Pokemon Storage"), _INTL("Item Storage"), _INTL("Cancel")]
        command = pbMessage(_INTL("Access which storage?"), commands, commands.length - 1, nil, command)
        case command
        when 0
          if defined?(StorageSystemPC) && StorageSystemPC.respond_to?(:access)
            StorageSystemPC.access
          elsif defined?(PokemonStorageScene) && defined?(PokemonStorageScreen) && defined?($PokemonStorage)
            pbFadeOutIn {
              scene = PokemonStorageScene.new
              screen = PokemonStorageScreen.new(scene, $PokemonStorage)
              screen.pbStartScreen(0)
            }
          else
            pbMessage(_INTL("Pokemon Storage is not available right now."))
          end
        when 1
          if defined?(pbPCItemStorage)
            pbPCItemStorage
          else
            pbMessage(_INTL("Item Storage is not available right now."))
          end
        else
          break
        end
      end
      pbSEPlay("PC close") if defined?(pbSEPlay)
      log("[keishou] Storage Device opened") if respond_to?(:log)
      return true
    rescue => e
      log("[keishou] Storage Device failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      pbMessage(_INTL("The Storage Device cannot be used right now.")) if defined?(pbMessage)
      return false
    end

    def keishou_recipe_source_path
      @keishou_recipe_source_path ||= begin
        roots = []
        if respond_to?(:external_projects)
          keishou_expansion_ids.each do |expansion_id|
            info = external_projects[expansion_id]
            next if !info.is_a?(Hash)
            roots << (info[:root] || info["root"])
            roots << (info[:filesystem_bridge_root] || info["filesystem_bridge_root"])
            roots << (info[:source_mount_root] || info["source_mount_root"])
            roots << (info[:archive_mount_root] || info["archive_mount_root"])
            roots << (info[:prepared_project_root] || info["prepared_project_root"])
          end
        end
        if respond_to?(:linked_project_bridge_root)
          keishou_expansion_ids.each do |expansion_id|
            roots << linked_project_bridge_root(expansion_id)
          end
        end
        keishou_expansion_ids.each do |expansion_id|
          roots << File.expand_path("../../ExpansionLibrary/LinkedProjects/#{expansion_id}", __dir__)
          roots << File.expand_path("../../ExpansionLibrary/ExtractedArchives/#{expansion_id}", __dir__)
        end
        roots << File.expand_path("C:/Games/PIF/ExpansionLibrary/LinkedProjects/keishou")
        roots.compact.map(&:to_s).reject { |root| root.empty? }.uniq.each do |root|
          candidate = File.join(root, "PBS", "recipes.txt")
          exact = runtime_exact_file_path(candidate) if respond_to?(:runtime_exact_file_path)
          exact ||= candidate
          return exact if exact && File.file?(exact)
        end
        nil
      end
    rescue
      return nil
    end

    def keishou_recipe_item_token(token)
      raw = token.to_s.strip
      return nil if raw.empty?
      normalized = raw.upcase.gsub(/[^\w]+/, "_").gsub(/\A_+|_+\z/, "")
      return raw if normalized.empty?
      symbol = normalized.to_sym
      data = base_item_try_get(symbol) if respond_to?(:base_item_try_get)
      return data.id if data && data.respond_to?(:id)
      if keishou_catalog_item?(symbol)
        runtime = keishou_runtime_item_symbol(symbol)
        return runtime if runtime
      end
      return symbol if defined?(GameData::Item) && (GameData::Item.exists?(symbol) rescue false)
      return raw
    rescue
      return token
    end

    def keishou_parse_recipe_ingredients(raw)
      parts = raw.to_s.split(",").map { |part| part.strip }.reject { |part| part.empty? }
      ingredients = []
      index = 0
      while index < parts.length
        token = parts[index]
        quantity = parts[index + 1].to_i
        quantity = 1 if quantity <= 0
        ingredient = keishou_recipe_item_token(token)
        ingredients << [ingredient, quantity] if ingredient
        index += 2
      end
      return ingredients
    rescue
      return []
    end

    def keishou_recipe_records
      return @keishou_recipe_records if @keishou_recipe_records
      records = {}
      source = keishou_recipe_source_path
      return @keishou_recipe_records = records if source.nil? || !File.file?(source)
      current_id = nil
      current_data = {}
      flush = proc do
        next if current_id.to_s.empty? || current_data[:item].to_s.empty?
        recipe_id = current_id.to_sym
        output = keishou_recipe_item_token(current_data[:item])
        ingredients = keishou_parse_recipe_ingredients(current_data[:ingredients])
        next if output.nil? || ingredients.empty?
        yield_count = current_data[:yield].to_i
        yield_count = 1 if yield_count <= 0
        flags = current_data[:flags].to_s.split(",").map { |flag| flag.strip }.reject { |flag| flag.empty? }
        records[recipe_id] = {
          :id          => recipe_id,
          :item        => output,
          :yield       => yield_count,
          :ingredients => ingredients,
          :flags       => flags
        }
      end
      File.foreach(source) do |line|
        stripped = line.to_s.strip
        next if stripped.empty? || stripped.start_with?("#")
        if stripped =~ /\A\[(.+?)\]\z/
          flush.call
          current_id = Regexp.last_match(1).to_s.strip
          current_data = {}
          next
        end
        next if current_id.nil?
        next if stripped !~ /\A([^=]+?)\s*=\s*(.*)\z/
        key = Regexp.last_match(1).to_s.strip.downcase.to_sym
        current_data[key] = Regexp.last_match(2).to_s.strip
      end
      flush.call
      @keishou_recipe_records = records
      return records
    rescue => e
      log("[keishou] recipe parse failed: #{e.class}: #{e.message}") if respond_to?(:log)
      @keishou_recipe_records = {}
      return @keishou_recipe_records
    end

    def keishou_recipe_record_for(recipe_id)
      records = keishou_recipe_records
      return nil if records.empty? || recipe_id.nil?
      direct = records[recipe_id.to_sym] rescue nil
      return direct if direct
      needle = recipe_id.to_s.downcase
      pair = records.find { |id, _record| id.to_s.downcase == needle }
      return pair ? pair[1] : nil
    rescue
      return nil
    end

    def keishou_register_recipe(record)
      return nil if record.nil? || !defined?(GameData::Recipe)
      recipe_id = record[:id]
      return recipe_id if GameData::Recipe.respond_to?(:exists?) && (GameData::Recipe.exists?(recipe_id) rescue false)
      if GameData::Recipe.respond_to?(:register)
        GameData::Recipe.register(record)
      elsif defined?(GameData::Recipe::DATA)
        GameData::Recipe::DATA[recipe_id] = GameData::Recipe.new(record)
      end
      return recipe_id
    rescue => e
      log("[keishou] recipe registration failed for #{record.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
      return record[:id] rescue nil
    end

    def keishou_pokebowl_recipe_ids
      ids = []
      keishou_recipe_records.each_value do |record|
        flags = Array(record[:flags]).map { |flag| flag.to_s.downcase }
        next if !flags.include?(KEISHOU_POKEBOWL_RECIPE_FLAG.downcase)
        ids << (keishou_register_recipe(record) || record[:id])
      end
      return ids.compact.uniq
    rescue => e
      log("[keishou] Pokebowl recipe lookup failed: #{e.class}: #{e.message}") if respond_to?(:log)
      return []
    end

    def keishou_global_recipes
      return [] if !defined?($PokemonGlobal) || !$PokemonGlobal
      if $PokemonGlobal.respond_to?(:recipes)
        list = $PokemonGlobal.recipes
      else
        list = $PokemonGlobal.instance_variable_get(:@recipes)
        if list.nil?
          list = []
          $PokemonGlobal.instance_variable_set(:@recipes, list)
        end
      end
      return list
    rescue
      return []
    end

    def keishou_unlock_recipe(recipe_id)
      registered = recipe_id.to_sym rescue recipe_id
      list = keishou_global_recipes
      list << registered if !list.include?(registered)
      list.uniq!
      return true
    rescue => e
      log("[keishou] unlock recipe #{recipe_id.inspect} failed: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_lock_recipe(recipe_id)
      list = keishou_global_recipes
      candidates = [recipe_id]
      record = keishou_recipe_record_for(recipe_id)
      candidates << record[:id] if record
      candidates.compact.each { |candidate| list.delete(candidate) }
      return true
    rescue
      return false
    end

    def keishou_recipe_ids_for_flag(flag = nil)
      requested = flag.to_s
      unlocked = keishou_global_recipes.compact
      if unlocked.empty? && requested.downcase == KEISHOU_POKEBOWL_RECIPE_FLAG.downcase
        return keishou_pokebowl_recipe_ids
      end
      ids = []
      unlocked.each do |recipe_id|
        record = keishou_recipe_record_for(recipe_id)
        next if !record
        if !requested.empty?
          flags = Array(record[:flags]).map { |entry| entry.to_s.downcase.strip }
          next if !flags.include?(requested.downcase)
        end
        ids << (keishou_register_recipe(record) || recipe_id)
      end
      return ids
    rescue => e
      log("[keishou] recipe flag lookup failed: #{e.class}: #{e.message}") if respond_to?(:log)
      return []
    end

    def keishou_recipe_output_quantity(recipe)
      value = recipe.send(:yield) if recipe && recipe.respond_to?(:yield)
      value = recipe.instance_variable_get(:@yield) if value.nil? && recipe.respond_to?(:instance_variable_get)
      value = 1 if value.to_i <= 0
      return value.to_i
    rescue
      return 1
    end

    def keishou_recipe_ingredients(recipe)
      ingredients = recipe.ingredients if recipe && recipe.respond_to?(:ingredients)
      return Array(ingredients)
    rescue
      return []
    end

    def keishou_recipe_output_item(recipe)
      item = recipe.item if recipe && recipe.respond_to?(:item)
      return keishou_resolve_bag_item(item)
    rescue
      return nil
    end

    def keishou_recipe_item_name(item)
      data = GameData::Item.get(item) if defined?(GameData::Item)
      return data.name.to_s if data && data.respond_to?(:name)
      return keishou_item_name(item)
    rescue
      return keishou_item_name(item)
    end

    def keishou_recipe_ingredient_candidates(ingredient)
      if ingredient.is_a?(Symbol)
        return [keishou_resolve_bag_item(ingredient)].compact
      end
      if ingredient.is_a?(String) && defined?(GameData::Item) && GameData::Item.respond_to?(:each)
        candidates = []
        GameData::Item.each do |item_data|
          next if !item_data.respond_to?(:has_flag?) || !(item_data.has_flag?(ingredient) rescue false)
          candidates << item_data.id if item_data.respond_to?(:id)
        end
        return candidates.compact
      end
      return [keishou_resolve_bag_item(ingredient)].compact
    rescue
      return []
    end

    def keishou_recipe_ingredient_quantity(ingredient)
      return keishou_recipe_ingredient_candidates(ingredient).inject(0) do |sum, candidate|
        sum + keishou_bag_quantity(candidate)
      end
    rescue
      return 0
    end

    def keishou_effective_recipe_ingredient_quantity(quantity)
      required = [quantity.to_i, 1].max
      required = [required - 1, 1].max if keishou_active_charm?(:CRAFTINGCHARM)
      return required
    rescue
      return [quantity.to_i, 1].max
    end

    def keishou_effective_recipe_output_quantity(recipe)
      amount = keishou_recipe_output_quantity(recipe)
      amount += 1 if keishou_active_charm?(:CRAFTINGCHARM)
      return [amount.to_i, 1].max
    rescue
      return 1
    end

    def keishou_max_craft_count(recipe)
      max_count = nil
      keishou_recipe_ingredients(recipe).each do |ingredient, quantity|
        quantity = keishou_effective_recipe_ingredient_quantity(quantity)
        have = keishou_recipe_ingredient_quantity(ingredient)
        count = have / quantity
        max_count = max_count.nil? ? count : [max_count, count].min
      end
      return [max_count || 0, 99].min
    rescue
      return 0
    end

    def keishou_delete_recipe_ingredient(ingredient, quantity)
      remaining = quantity.to_i
      keishou_recipe_ingredient_candidates(ingredient).each do |candidate|
        break if remaining <= 0
        have = keishou_bag_quantity(candidate)
        next if have <= 0
        take = [have, remaining].min
        remaining -= take if keishou_delete_bag_item(candidate, take)
      end
      return remaining <= 0
    rescue
      return false
    end

    def keishou_missing_recipe_text(recipe, volume)
      missing = []
      keishou_recipe_ingredients(recipe).each do |ingredient, quantity|
        need = keishou_effective_recipe_ingredient_quantity(quantity) * volume.to_i
        have = keishou_recipe_ingredient_quantity(ingredient)
        next if have >= need
        name = ingredient.is_a?(String) ? ingredient : keishou_recipe_item_name(keishou_resolve_bag_item(ingredient))
        missing << "#{name} #{have}/#{need}"
      end
      return missing.join(", ")
    rescue
      return ""
    end

    def keishou_craft_recipe_interactive(recipe)
      output = keishou_recipe_output_item(recipe)
      return false if output.nil?
      max_count = keishou_max_craft_count(recipe)
      if max_count <= 0
        details = keishou_missing_recipe_text(recipe, 1)
        message = details.empty? ? "You lack the necessary ingredients." : "You lack the necessary ingredients: #{details}."
        pbMessage(_INTL(message)) if defined?(pbMessage)
        return false
      end
      volume = 1
      if max_count > 1 && defined?(ChooseNumberParams) && defined?(pbMessageChooseNumber)
        params = ChooseNumberParams.new
        params.setRange(1, max_count)
        params.setDefaultValue(1)
        volume = pbMessageChooseNumber(_INTL("Craft how many?"), params)
        return false if volume.to_i <= 0
      end
      produced_each = keishou_effective_recipe_output_quantity(recipe)
      total = produced_each * volume.to_i
      item_name = keishou_recipe_item_name(output)
      if !keishou_bag_can_store_item?(output, total)
        pbMessage(_INTL("Too bad... The Bag is full.")) if defined?(pbMessage)
        return false
      end
      return false if defined?(pbConfirmMessage) &&
                      !pbConfirmMessage(_INTL("Would you like to craft {1} {2}?", total, item_name))
      keishou_recipe_ingredients(recipe).each do |ingredient, quantity|
        return false if !keishou_delete_recipe_ingredient(ingredient, keishou_effective_recipe_ingredient_quantity(quantity) * volume.to_i)
      end
      if keishou_store_bag_item(output, total)
        pbSEPlay("Pkmn move learnt") if defined?(pbSEPlay)
        pbMessage(_INTL("You crafted {1} {2}.", total, item_name)) if defined?(pbMessage)
        return true
      end
      pbMessage(_INTL("Too bad... The Bag is full.")) if defined?(pbMessage)
      return false
    rescue => e
      log("[keishou] recipe craft failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      pbMessage(_INTL("The Poke Bowl cannot craft that right now.")) if defined?(pbMessage)
      return false
    end

    def keishou_craft_from_recipe_list(stock, speech1 = nil, speech2 = nil)
      sync_keishou_bag_alias!
      recipes = Array(stock).compact.map do |recipe_id|
        record = keishou_recipe_record_for(recipe_id)
        registered = keishou_register_recipe(record) || recipe_id
        GameData::Recipe.get(registered) rescue nil
      end.compact
      if recipes.empty?
        pbMessage(_INTL("You don't have any recipes to use here.")) if defined?(pbMessage)
        return false
      end
      pbMessage(speech1) if speech1 && defined?(pbMessage)
      command = 0
      loop do
        commands = recipes.map do |recipe|
          output = keishou_recipe_output_item(recipe)
          _INTL("{1} x{2}", keishou_recipe_item_name(output), keishou_effective_recipe_output_quantity(recipe))
        end
        commands << _INTL("Cancel")
        command = pbMessage(_INTL("Choose a recipe."), commands, commands.length - 1, nil, command)
        break if command.nil? || command < 0 || command >= recipes.length
        keishou_craft_recipe_interactive(recipes[command])
      end
      pbMessage(speech2) if speech2 && defined?(pbMessage)
      return true
    rescue => e
      log("[keishou] fallback crafting UI failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      pbMessage(_INTL("The Poke Bowl cannot be used right now.")) if defined?(pbMessage)
      return false
    end

    def keishou_open_pokebowl
      sync_keishou_bag_alias!
      stock = defined?(pbGetRecipes) ? pbGetRecipes(KEISHOU_POKEBOWL_RECIPE_FLAG) : []
      stock = keishou_pokebowl_recipe_ids if stock.nil? || stock.empty?
      if stock.empty?
        pbMessage(_INTL("You don't have any Pokeball recipes to use here.")) if defined?(pbMessage)
        return false
      end
      if defined?(pbItemCrafter)
        pbItemCrafter(stock)
      else
        keishou_craft_from_recipe_list(stock)
      end
      return true
    rescue => e
      log("[keishou] Poke Bowl failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      pbMessage(_INTL("The Poke Bowl cannot be used right now.")) if defined?(pbMessage)
      return false
    end

    def keishou_crafting_flag_for_item(raw)
      raw_symbol = keishou_raw_item_symbol(raw)
      return nil if raw_symbol.nil?
      return KEISHOU_CRAFTING_ITEM_FLAGS[raw_symbol]
    rescue
      return nil
    end

    def keishou_open_crafting_item(raw)
      flag = keishou_crafting_flag_for_item(raw)
      return keishou_open_pokebowl if flag.to_s.downcase == KEISHOU_POKEBOWL_RECIPE_FLAG.downcase
      if flag.to_s.empty?
        pbMessage(_INTL("This crafting tool cannot be used right now.")) if defined?(pbMessage)
        return false
      end
      stock = defined?(pbGetRecipes) ? pbGetRecipes(flag) : keishou_recipe_ids_for_flag(flag)
      if stock.nil? || stock.empty?
        pbMessage(_INTL("You don't have any recipes to use here.")) if defined?(pbMessage)
        return true
      end
      if defined?(pbItemCrafter)
        pbItemCrafter(stock)
      else
        keishou_craft_from_recipe_list(stock)
      end
      return true
    rescue => e
      log("[keishou] crafting item #{raw.inspect} failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      pbMessage(_INTL("This crafting tool cannot be used right now.")) if defined?(pbMessage)
      return false
    end

    def keishou_global_notebook
      return [] if !defined?($PokemonGlobal) || !$PokemonGlobal
      if $PokemonGlobal.respond_to?(:notebook)
        return $PokemonGlobal.notebook
      end
      notes = $PokemonGlobal.instance_variable_get(:@notebook)
      notes = [] if !notes.is_a?(Array)
      $PokemonGlobal.instance_variable_set(:@notebook, notes)
      return notes
    rescue
      return []
    end

    def keishou_note_storage_limit
      base = defined?(NoteConfig) && NoteConfig.const_defined?(:NUM_NOTE_STORAGE) ? NoteConfig::NUM_NOTE_STORAGE : 100
      variable_id = defined?(NoteConfig) && NoteConfig.const_defined?(:NOTE_STORAGE_VARIABLE) ? NoteConfig::NOTE_STORAGE_VARIABLE : 0
      extra = (defined?($game_variables) && variable_id.to_i > 0) ? $game_variables[variable_id.to_i].to_i : 0
      return [base.to_i + extra, 1].max
    rescue
      return 100
    end

    def keishou_note_title(note)
      return note.matter.to_s if note.respond_to?(:matter)
      return note[:matter].to_s if note.is_a?(Hash) && note.has_key?(:matter)
      return note["matter"].to_s if note.is_a?(Hash) && note.has_key?("matter")
      return note[:title].to_s if note.is_a?(Hash) && note.has_key?(:title)
      return note["title"].to_s if note.is_a?(Hash) && note.has_key?("title")
      return _INTL("Untitled")
    rescue
      return "Untitled"
    end

    def keishou_note_message(note)
      return note.message.to_s if note.respond_to?(:message)
      return note[:message].to_s if note.is_a?(Hash) && note.has_key?(:message)
      return note["message"].to_s if note.is_a?(Hash) && note.has_key?("message")
      return note[:text].to_s if note.is_a?(Hash) && note.has_key?(:text)
      return note["text"].to_s if note.is_a?(Hash) && note.has_key?("text")
      return ""
    rescue
      return ""
    end

    def keishou_make_note(title, message)
      if defined?(Mail) && defined?(GameData::Item)
        mail_item = [:BRIDGETMAIL, :GREETMAIL, :THANKSMAIL, :REPLYMAIL].find { |item| GameData::Item.try_get(item) rescue false }
        return Mail.new(mail_item, title, message, "") if mail_item
      end
      return {
        :matter  => title.to_s,
        :message => message.to_s,
        :sender  => "",
        :created => Time.now.to_i
      }
    rescue
      return { :matter => title.to_s, :message => message.to_s, :sender => "" }
    end

    def keishou_write_note
      notes = keishou_global_notebook
      limit = keishou_note_storage_limit
      if notes.length >= limit
        pbMessage(_INTL("There's no space for the note. Please, increase the notebook capacity.")) if defined?(pbMessage)
        return false
      end
      title = defined?(pbEnterText) ? pbEnterText(_INTL("Title for the note?"), 0, 25, "") : ""
      return false if title.nil? || title.to_s.empty?
      message = if defined?(pbMessageFreeText)
                  pbMessageFreeText(_INTL("Enter a text"), "", false, 250)
                elsif defined?(pbEnterText)
                  pbEnterText(_INTL("Enter a text"), 0, 250, "")
                else
                  ""
                end
      return false if message.nil? || message.to_s.empty?
      notes << keishou_make_note(title, message)
      pbMessage(_INTL("The note was written.")) if defined?(pbMessage)
      return true
    rescue => e
      log("[keishou] write note failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      pbMessage(_INTL("The note couldn't be written right now.")) if defined?(pbMessage)
      return false
    end

    def keishou_read_note(note)
      title = keishou_note_title(note)
      message = keishou_note_message(note)
      if defined?(pbDisplayMail) && note.respond_to?(:item)
        pbFadeOutIn { pbDisplayMail(note) }
      else
        pbMessage(_INTL("{1}\\n{2}", title, message)) if defined?(pbMessage)
      end
      return true
    rescue => e
      log("[keishou] read note failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_open_notebook_list
      notes = keishou_global_notebook
      if notes.empty?
        pbMessage(_INTL("There's no notes here.")) if defined?(pbMessage)
        return true
      end
      command = 0
      loop do
        commands = notes.map { |note| keishou_note_title(note) }
        commands << _INTL("Cancel")
        command = if defined?(pbShowCommands)
                    pbShowCommands(nil, commands, -1, command)
                  else
                    pbMessage(_INTL("Choose a note."), commands, commands.length - 1, nil, command)
                  end
        break if command.nil? || command < 0 || command >= notes.length
        action = pbMessage(_INTL("What do you want to do with note {1}?", keishou_note_title(notes[command])),
                           [_INTL("Read"), _INTL("Delete"), _INTL("Cancel")], -1)
        if action == 0
          keishou_read_note(notes[command])
        elsif action == 1 && (!defined?(pbConfirmMessage) || pbConfirmMessage(_INTL("The note will be lost. Is that OK?")))
          notes.delete_at(command)
          pbMessage(_INTL("The note was deleted.")) if defined?(pbMessage)
        end
      end
      return true
    rescue => e
      log("[keishou] notebook list failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_open_notebook
      notes = keishou_global_notebook
      command = 0
      loop do
        commands = [_INTL("Write a note"), _INTL("Open the notebook"), _INTL("Check amount of notes"), _INTL("Cancel")]
        command = pbMessage(_INTL("What do you want to do?"), commands, commands.length - 1, nil, command)
        break if command.nil? || command < 0 || command >= commands.length - 1
        case command
        when 0 then keishou_write_note
        when 1 then keishou_open_notebook_list
        when 2 then pbMessage(_INTL("Notes stored: {1}/{2}", notes.length, keishou_note_storage_limit))
        end
      end
      return true
    rescue => e
      log("[keishou] Notebook failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      pbMessage(_INTL("The Notebook cannot be opened right now.")) if defined?(pbMessage)
      return false
    end

    def keishou_register_item_handler(raw, from_bag_result)
      return if !defined?(ItemHandlers)
      symbols = [raw]
      symbols.concat(keishou_runtime_item_symbols(raw))
      symbols = symbols.compact.uniq
      symbols.each do |symbol|
        next if symbol.nil?
        if raw == :STORAGEDEVICE
          ItemHandlers::UseFromBag.add(symbol, proc { |_item|
            TravelExpansionFramework.keishou_open_storage_device
            next from_bag_result
          })
          ItemHandlers::UseInField.add(symbol, proc { |_item|
            TravelExpansionFramework.keishou_open_storage_device
            next 1
          })
        elsif raw == :CHARMCASE
          ItemHandlers::UseFromBag.add(symbol, proc { |_item|
            if defined?(CharmCase_Scene) && defined?(CharmCaseScreen)
              player = TravelExpansionFramework.keishou_player
              TravelExpansionFramework.keishou_initialize_charms!(player)
              pbFadeOutIn {
                scene = CharmCase_Scene.new
                screen = CharmCaseScreen.new(scene, player ? player.charmlist : [])
                screen.pbBuyScreen
              }
            else
              TravelExpansionFramework.keishou_open_charm_case
            end
            next from_bag_result
          })
          ItemHandlers::UseInField.add(symbol, proc { |_item|
            if defined?(CharmCase_Scene) && defined?(CharmCaseScreen)
              player = TravelExpansionFramework.keishou_player
              TravelExpansionFramework.keishou_initialize_charms!(player)
              pbFadeOutIn {
                scene = CharmCase_Scene.new
                screen = CharmCaseScreen.new(scene, player ? player.charmlist : [])
                screen.pbBuyScreen
              }
            else
              TravelExpansionFramework.keishou_open_charm_case
            end
            next 1
          })
        elsif raw == :POKEBOWL
          ItemHandlers::UseFromBag.add(symbol, proc { |_item|
            TravelExpansionFramework.keishou_open_pokebowl
            next from_bag_result
          })
          ItemHandlers::UseInField.add(symbol, proc { |_item|
            TravelExpansionFramework.keishou_open_pokebowl
            next 1
          })
        elsif KEISHOU_CRAFTING_ITEM_FLAGS.has_key?(raw)
          ItemHandlers::UseFromBag.add(symbol, proc { |_item|
            TravelExpansionFramework.keishou_open_crafting_item(raw)
            next from_bag_result
          })
          ItemHandlers::UseInField.add(symbol, proc { |_item|
            TravelExpansionFramework.keishou_open_crafting_item(raw)
            next 1
          })
        elsif raw == :NOTEBOOK
          ItemHandlers::UseFromBag.add(symbol, proc { |_item|
            TravelExpansionFramework.keishou_open_notebook
            next from_bag_result
          })
          ItemHandlers::UseInField.add(symbol, proc { |_item|
            TravelExpansionFramework.keishou_open_notebook
            next 1
          })
        end
      end
      return true
    rescue => e
      log("[keishou] failed registering item handler for #{raw.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_first_party_pokemon
      player = keishou_player
      return player.first_pokemon if player && player.respond_to?(:first_pokemon)
      party = player.party if player && player.respond_to?(:party)
      return Array(party).find { |pkmn| pkmn && (!pkmn.respond_to?(:egg?) || !pkmn.egg?) }
    rescue
      return nil
    end

    def keishou_random_personal_id
      return rand(2**16) | (rand(2**16) << 16)
    end

    def keishou_reroll_shiny!(pokemon, retries)
      return pokemon if pokemon.nil? || retries.to_i <= 0 || !pokemon.respond_to?(:shiny?)
      retries.to_i.times do
        break if pokemon.shiny?
        pokemon.shiny = nil if pokemon.respond_to?(:shiny=)
        pokemon.personalID = keishou_random_personal_id if pokemon.respond_to?(:personalID=)
      end
      return pokemon
    rescue => e
      log("[keishou] shiny charm retry failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return pokemon
    end

    def keishou_apply_clover_charm!(pokemon)
      return pokemon if pokemon.nil? || !keishou_active_charm?(:CLOVERCHARM)
      return pokemon if pokemon.respond_to?(:item) && pokemon.item
      items = Array(pokemon.wildHoldItems) if pokemon.respond_to?(:wildHoldItems)
      return pokemon if items.nil? || items.empty?
      items = [items[0], items[1], items[2]]
      first = keishou_first_party_pokemon
      chances = [60, 20, 5]
      if first && first.respond_to?(:hasAbility?) && (first.hasAbility?(:COMPOUNDEYES) || first.hasAbility?(:SUPERLUCK))
        chances = [100, 35, 15]
      end
      roll = rand(100)
      item = nil
      if items[0] && ((items[0] == items[1] && items[1] == items[2]) || roll < chances[0])
        item = items[0]
      elsif items[1] && roll < chances[0] + chances[1]
        item = items[1]
      elsif items[2] && roll < chances[0] + chances[1] + chances[2]
        item = items[2]
      end
      pokemon.item = item if item && pokemon.respond_to?(:item=)
      return pokemon
    rescue => e
      log("[keishou] Clover Charm effect failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return pokemon
    end

    def keishou_learn_random_special_move!(pokemon)
      return pokemon if pokemon.nil? || !keishou_active_charm?(:SMARTCHARM) || rand(100) >= 30
      species_data = pokemon.species_data if pokemon.respond_to?(:species_data)
      moves = Array(species_data.tutor_moves) if species_data && species_data.respond_to?(:tutor_moves)
      moves ||= []
      moves.concat(Array(species_data.get_egg_moves)) if species_data && species_data.respond_to?(:get_egg_moves)
      moves = moves.compact.uniq.select do |move|
        (!defined?(GameData::Move) || GameData::Move.exists?(move)) &&
          (!pokemon.respond_to?(:hasMove?) || !pokemon.hasMove?(move))
      end
      pokemon.learn_move(moves.sample) if !moves.empty? && pokemon.respond_to?(:learn_move)
      return pokemon
    rescue => e
      log("[keishou] Smart Charm effect failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return pokemon
    end

    def keishou_apply_hidden_ability_charm!(pokemon)
      return pokemon if pokemon.nil? || !keishou_active_charm?(:KEYCHARM) || rand(100) >= 30
      abilities = pokemon.getAbilityList if pokemon.respond_to?(:getAbilityList)
      hidden_indexes = Array(abilities).select { |entry| entry[1].to_i >= 2 }.map { |entry| entry[1].to_i }
      pokemon.ability_index = hidden_indexes.sample if !hidden_indexes.empty? && pokemon.respond_to?(:ability_index=)
      return pokemon
    rescue => e
      log("[keishou] Key Charm effect failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return pokemon
    end

    def keishou_apply_iv_charms!(pokemon)
      return pokemon if pokemon.nil? || !pokemon.respond_to?(:iv) || !defined?(GameData::Stat)
      limit = defined?(Pokemon::IV_STAT_LIMIT) ? Pokemon::IV_STAT_LIMIT : 31
      GameData::Stat.each_main do |stat|
        current = pokemon.iv[stat.id].to_i
        pokemon.iv[stat.id] = [current + 5, limit].min if keishou_active_charm?(:IVCHARM)
      end
      if keishou_active_charm?(:GENECHARM) && rand(100) < 40
        stats = []
        GameData::Stat.each_main { |stat| stats << stat.id }
        stat = stats.sample
        pokemon.iv[stat] = limit if stat
      end
      pokemon.calc_stats if pokemon.respond_to?(:calc_stats)
      return pokemon
    rescue => e
      log("[keishou] IV charm effects failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return pokemon
    end

    def keishou_apply_wild_charm_effects!(pokemon, is_roamer = false)
      return pokemon if pokemon.nil?
      shiny_retries = 0
      shiny_retries += 2 if keishou_active_charm?(:SHINYCHARM)
      fishing = defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:fishing) && $PokemonGlobal.fishing
      shiny_retries += 2 if fishing && keishou_active_charm?(:LURECHARM)
      keishou_reroll_shiny!(pokemon, shiny_retries)
      keishou_apply_clover_charm!(pokemon)
      keishou_learn_random_special_move!(pokemon)
      pokemon.givePokerus if pokemon.respond_to?(:givePokerus) && keishou_active_charm?(:VIRALCHARM) && rand(100) < 10
      first = keishou_first_party_pokemon
      if first && !is_roamer && first.respond_to?(:nature) && pokemon.respond_to?(:nature=) &&
         keishou_active_charm?(:SPIRITCHARM) && rand(100) < 50
        pokemon.nature = first.nature
      end
      keishou_apply_hidden_ability_charm!(pokemon)
      keishou_apply_iv_charms!(pokemon)
      return pokemon
    rescue => e
      log("[keishou] wild charm effects failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return pokemon
    end

    def keishou_active_element_charm_type(player = nil)
      player ||= keishou_player
      keishou_initialize_charms!(player) if player
      active = keishou_player_value(player, :@charmsActive, {})
      KEISHOU_ELEMENT_CHARM_TYPES.each_pair do |charm, type|
        return type if active[charm] == true
      end
      return nil
    rescue
      return nil
    end

    def keishou_pokemon_has_type?(pokemon, type)
      return false if pokemon.nil? || type.nil?
      return pokemon.hasType?(type) if pokemon.respond_to?(:hasType?)
      return Array(pokemon.types).include?(type) if pokemon.respond_to?(:types)
      return false
    rescue
      return false
    end

    def keishou_adjust_catch_rate_for_charms(pokemon, catch_rate)
      return catch_rate if pokemon.nil?
      base = catch_rate || (pokemon.species_data.catch_rate if pokemon.respond_to?(:species_data))
      return catch_rate if base.nil?
      adjusted = base.to_f
      adjusted *= 1.2 if keishou_active_charm?(:CATCHINGCHARM)
      element_type = keishou_active_element_charm_type
      adjusted *= 2.5 if element_type && keishou_pokemon_has_type?(pokemon, element_type)
      return [[adjusted.round, 1].max, 255].min
    rescue => e
      log("[keishou] catch charm adjustment failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return catch_rate
    end

    def keishou_apply_gold_charm_bonus!(battle, old_money)
      return if battle.nil? || old_money.nil? || !keishou_active_charm?(:GOLDCHARM)
      return if battle.instance_variable_get(:@tef_keishou_gold_charm_paid)
      return if !battle.respond_to?(:trainerBattle?) || !battle.trainerBattle?
      battle.instance_variable_set(:@tef_keishou_gold_charm_paid, true)
      current = battle.pbPlayer.money if battle.respond_to?(:pbPlayer) && battle.pbPlayer
      return if current.nil?
      gained = [current.to_i - old_money.to_i, 0].max
      bonus = gained + 500
      return if bonus <= 0
      battle.pbPlayer.money += bonus
      $stats.battle_money_gained += bonus if defined?($stats) && $stats && $stats.respond_to?(:battle_money_gained=)
      text = bonus.respond_to?(:to_s_formatted) ? bonus.to_s_formatted : bonus.to_s
      battle.pbDisplayPaused(_INTL("You picked up ${1} from the Gold Charm!", text)) if battle.respond_to?(:pbDisplayPaused)
    rescue => e
      log("[keishou] Gold Charm bonus failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    end

    def keishou_healing_charm_restore_amount(restore_hp)
      amount = restore_hp.to_i
      amount *= 2 if amount > 0 && keishou_active_charm?(:HEALINGCHARM)
      return amount
    rescue
      return restore_hp
    end

    def keishou_step_healing_tick!
      return if !keishou_active_charm?(:HEALINGCHARM)
      @keishou_healing_charm_steps = @keishou_healing_charm_steps.to_i + 1
      return if @keishou_healing_charm_steps % 35 != 0
      player = keishou_player
      Array(player.party).each do |pkmn|
        next if pkmn.nil? || !pkmn.respond_to?(:able?) || !pkmn.able?
        next if !pkmn.respond_to?(:hp) || !pkmn.respond_to?(:totalhp) || pkmn.hp >= pkmn.totalhp
        pkmn.hp = [pkmn.hp + 1, pkmn.totalhp].min if pkmn.respond_to?(:hp=)
      end
    rescue => e
      log("[keishou] Healing Charm step tick failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    end

    def keishou_random_rock_smash_item!
      return false if respond_to?(:keishou_active_now?) && !keishou_active_now?
      table = KEISHOU_ROCK_SMASH_ITEMS
      return false if !table.is_a?(Array) || table.empty?
      entry = table[rand(table.length)]
      item = entry[0]
      threshold = entry[1].to_i
      quantity = [entry[2].to_i, 1].max
      roll = rand([KEISHOU_ROCK_SMASH_ITEM_PROBABILITY.to_i, 1].max)
      return false if roll > threshold
      resolved = keishou_resolve_bag_item(item)
      resolved = item if resolved.nil?
      pbMessage(_INTL("There's an item hidden inside the rock.")) if defined?(pbMessage)
      if defined?(pbItemBall)
        return pbItemBall(resolved, quantity)
      end
      return keishou_store_bag_item(resolved, quantity)
    rescue => e
      log("[keishou] Rock Smash random item failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_rock_smash_random_encounter!
      return false if respond_to?(:keishou_active_now?) && !keishou_active_now?
      if defined?($PokemonEncounters) && $PokemonEncounters &&
         $PokemonEncounters.respond_to?(:encounter_triggered?) &&
         ($PokemonEncounters.encounter_triggered?(:RockSmash, false, false) rescue false)
        $stats.rock_smash_battles += 1 if defined?($stats) && $stats && $stats.respond_to?(:rock_smash_battles) &&
                                          $stats.respond_to?(:rock_smash_battles=)
        return pbEncounter(:RockSmash) if defined?(pbEncounter)
      end
      return keishou_random_rock_smash_item!
    rescue => e
      log("[keishou] Rock Smash encounter helper failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def keishou_adjust_item_ball_quantity(item, quantity)
      return quantity if !keishou_active_charm?(:TWINCHARM)
      item_data = GameData::Item.try_get(item) if defined?(GameData::Item)
      return quantity if item_data && item_data.respond_to?(:is_important?) && item_data.is_important?
      return [quantity.to_i * 2, 1].max
    rescue
      return quantity
    end

    def install_keishou_charm_storage_compatibility!
      sync_keishou_bag_alias!
      keishou_refresh_item_metadata!
      [:STORAGEDEVICE, :CHARMCASE, :NOTEBOOK].each { |raw| keishou_register_item_handler(raw, 1) }
      KEISHOU_CRAFTING_ITEM_FLAGS.keys.each { |raw| keishou_register_item_handler(raw, 1) }
      log("[keishou] Charm Case, Storage Device, crafting, and Notebook compatibility loaded") if respond_to?(:log)
      return true
    rescue => e
      log("[keishou] compatibility install failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end
  end

  TravelExpansionFramework.install_keishou_charm_storage_compatibility!
end

if defined?(GameData) && !defined?(GameData::Recipe)
  module GameData
    class Recipe
      DATA = {} unless const_defined?(:DATA)

      attr_reader :id
      attr_reader :item
      attr_reader :ingredients
      attr_reader :flags

      def initialize(hash)
        @id = hash[:id]
        @item = hash[:item]
        @yield = hash[:yield] || 1
        @ingredients = hash[:ingredients] || []
        @flags = hash[:flags] || []
      end

      def yield
        return @yield
      end

      def has_flag?(flag)
        needle = flag.to_s.downcase
        return @flags.any? { |entry| entry.to_s.downcase == needle }
      end

      class << self
        def register(hash)
          recipe = new(hash)
          DATA[recipe.id] = recipe
          return recipe
        end

        def try_get(id)
          return id if id.is_a?(GameData::Recipe)
          key = id.to_sym rescue id
          return DATA[key]
        end

        def get(id)
          recipe = try_get(id)
          raise "Unknown recipe #{id.inspect}" if recipe.nil?
          return recipe
        end

        def exists?(id)
          return !try_get(id).nil?
        end

        def each
          DATA.each_value { |recipe| yield recipe } if block_given?
        end

        def load; end

        def save; end
      end
    end
  end
end

if defined?(PokemonGlobalMetadata)
  class PokemonGlobalMetadata
    def recipes
      @recipes = [] if !@recipes.is_a?(Array)
      return @recipes
    end unless method_defined?(:recipes)

    def notebook
      @notebook = [] if !@notebook.is_a?(Array)
      return @notebook
    end unless method_defined?(:notebook)

    def notebook=(value)
      @notebook = value.is_a?(Array) ? value : []
    end unless method_defined?(:notebook=)

    attr_accessor :choice unless method_defined?(:choice)
    attr_accessor :icon1 unless method_defined?(:icon1)
    attr_accessor :icon2 unless method_defined?(:icon2)
    attr_accessor :icon3 unless method_defined?(:icon3)
  end
end

if defined?(PokemonBag)
  class PokemonBag
    def quantity(item)
      return TravelExpansionFramework.keishou_bag_quantity(item)
    end unless method_defined?(:quantity)

    def has?(item, qty = 1)
      return TravelExpansionFramework.keishou_bag_has_item?(item, qty)
    end unless method_defined?(:has?)

    def include?(item)
      return has?(item)
    end unless method_defined?(:include?)

    def add(item, qty = 1)
      return TravelExpansionFramework.keishou_store_bag_item(item, qty)
    end unless method_defined?(:add)

    def remove(item, qty = 1)
      return TravelExpansionFramework.keishou_delete_bag_item(item, qty)
    end unless method_defined?(:remove)

    def delete(item, qty = 1)
      return TravelExpansionFramework.keishou_delete_bag_item(item, qty)
    end unless method_defined?(:delete)

    def can_add?(item, qty = 1)
      return TravelExpansionFramework.keishou_bag_can_store_item?(item, qty)
    end unless method_defined?(:can_add?)

    def can_store?(item, qty = 1)
      return TravelExpansionFramework.keishou_bag_can_store_item?(item, qty)
    end unless method_defined?(:can_store?)
  end
end

if defined?(Interpreter) && Interpreter.method_defined?(:execute_script)
  class Interpreter
    alias tef_keishou_bag_original_execute_script execute_script unless method_defined?(:tef_keishou_bag_original_execute_script)

    def execute_script(script)
      TravelExpansionFramework.sync_keishou_bag_alias! if defined?(TravelExpansionFramework) &&
                                                          TravelExpansionFramework.respond_to?(:sync_keishou_bag_alias!)
      return tef_keishou_bag_original_execute_script(script)
    end
  end
end

if defined?(Interpreter)
  class Interpreter
    def pbUnlockRecipe(recipe_id)
      return TravelExpansionFramework.keishou_unlock_recipe(recipe_id)
    end unless method_defined?(:pbUnlockRecipe)

    def pbLockRecipe(recipe_id)
      return TravelExpansionFramework.keishou_lock_recipe(recipe_id)
    end unless method_defined?(:pbLockRecipe)

    def pbGetRecipes(flag = nil)
      return TravelExpansionFramework.keishou_recipe_ids_for_flag(flag)
    end unless method_defined?(:pbGetRecipes)

    def pbItemCrafter(stock, speech1 = nil, speech2 = nil)
      return TravelExpansionFramework.keishou_craft_from_recipe_list(stock, speech1, speech2)
    end unless method_defined?(:pbItemCrafter)

    def pbRandomItem
      return TravelExpansionFramework.keishou_random_rock_smash_item!
    end unless method_defined?(:pbRandomItem)

    alias tef_keishou_original_pbRockSmashRandomEncounter pbRockSmashRandomEncounter if method_defined?(:pbRockSmashRandomEncounter) &&
                                                                                         !method_defined?(:tef_keishou_original_pbRockSmashRandomEncounter)

    def pbRockSmashRandomEncounter(*args)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:keishou_active_now?) &&
         TravelExpansionFramework.keishou_active_now?
        return TravelExpansionFramework.keishou_rock_smash_random_encounter!
      end
      return tef_keishou_original_pbRockSmashRandomEncounter(*args) if respond_to?(:tef_keishou_original_pbRockSmashRandomEncounter, true)
      return false
    end

    def pbToggleCharm(charm, display_message = true)
      return TravelExpansionFramework.keishou_toggle_charm(charm, display_message)
    end unless method_defined?(:pbToggleCharm)

    def pbGainCharm(charm)
      return TravelExpansionFramework.keishou_gain_charm(charm, false, false)
    end unless method_defined?(:pbGainCharm)

    def pbSilentGainCharm(charm)
      return TravelExpansionFramework.keishou_gain_charm(charm, true, false)
    end unless method_defined?(:pbSilentGainCharm)

    def pbGainElementCharm(charm)
      return TravelExpansionFramework.keishou_gain_charm(charm, false, true)
    end unless method_defined?(:pbGainElementCharm)

    def pbRemoveCharm(charm)
      return TravelExpansionFramework.keishou_remove_charm(charm, false)
    end unless method_defined?(:pbRemoveCharm)

    def pbSilentRemoveCharm(charm)
      return TravelExpansionFramework.keishou_remove_charm(charm, true)
    end unless method_defined?(:pbSilentRemoveCharm)

    def pbDeactivateAll
      return TravelExpansionFramework.keishou_deactivate_all_charms
    end unless method_defined?(:pbDeactivateAll)

    def pbGiveAllCharms
      return TravelExpansionFramework.keishou_give_all_charms(false)
    end unless method_defined?(:pbGiveAllCharms)

    def pbGiveAllECharms
      return TravelExpansionFramework.keishou_give_all_charms(true)
    end unless method_defined?(:pbGiveAllECharms)

    def countActiveCharms
      return TravelExpansionFramework.keishou_count_active_charms
    end unless method_defined?(:countActiveCharms)

    def activeCharm?(charm)
      return TravelExpansionFramework.keishou_active_charm?(charm)
    end unless method_defined?(:activeCharm?)

    def pbGC(charm)
      return pbGainCharm(charm)
    end unless method_defined?(:pbGC)

    def pbGEC(charm)
      return pbGainElementCharm(charm)
    end unless method_defined?(:pbGEC)

    def pbDAC
      return pbDeactivateAll
    end unless method_defined?(:pbDAC)

    def pbGAC
      return pbGiveAllCharms
    end unless method_defined?(:pbGAC)

    def pbGAEC
      return pbGiveAllECharms
    end unless method_defined?(:pbGAEC)

    def pbRC(charm)
      return pbRemoveCharm(charm)
    end unless method_defined?(:pbRC)

    def pbSGC(charm)
      return pbSilentGainCharm(charm)
    end unless method_defined?(:pbSGC)

    def pbSRC(charm)
      return pbSilentRemoveCharm(charm)
    end unless method_defined?(:pbSRC)

    def pbIncMaxCharms(inc = 1)
      player = TravelExpansionFramework.keishou_player
      TravelExpansionFramework.keishou_initialize_charms!(player)
      player.maxCharms = [player.maxCharms.to_i + inc.to_i, 0].max if player && player.respond_to?(:maxCharms=)
      return player ? player.maxCharms : 0
    end unless method_defined?(:pbIncMaxCharms)

    def pbDecMaxCharms(dec = 1)
      player = TravelExpansionFramework.keishou_player
      TravelExpansionFramework.keishou_initialize_charms!(player)
      player.maxCharms = [player.maxCharms.to_i - dec.to_i, 0].max if player && player.respond_to?(:maxCharms=)
      return player ? player.maxCharms : 0
    end unless method_defined?(:pbDecMaxCharms)
  end
end

if defined?(pbUseItem) && !Object.private_method_defined?(:tef_keishou_bag_original_pbUseItem)
  alias tef_keishou_bag_original_pbUseItem pbUseItem

  def pbUseItem(bag, item, bagscene = nil)
    TravelExpansionFramework.sync_keishou_bag_alias! if defined?(TravelExpansionFramework) &&
                                                        TravelExpansionFramework.respond_to?(:sync_keishou_bag_alias!)
    return tef_keishou_bag_original_pbUseItem(bag, item, bagscene)
  end
end

def pbUnlockRecipe(recipe_id)
  return TravelExpansionFramework.keishou_unlock_recipe(recipe_id)
end unless defined?(pbUnlockRecipe)

def pbLockRecipe(recipe_id)
  return TravelExpansionFramework.keishou_lock_recipe(recipe_id)
end unless defined?(pbLockRecipe)

def pbGetRecipes(flag = nil)
  return TravelExpansionFramework.keishou_recipe_ids_for_flag(flag)
end unless defined?(pbGetRecipes)

def pbItemCrafter(stock, speech1 = nil, speech2 = nil)
  return TravelExpansionFramework.keishou_craft_from_recipe_list(stock, speech1, speech2)
end unless defined?(pbItemCrafter)

def pbRandomItem
  return TravelExpansionFramework.keishou_random_rock_smash_item!
end unless defined?(pbRandomItem)

def pbRockSmashRandomEncounter
  return TravelExpansionFramework.keishou_rock_smash_random_encounter!
end unless defined?(pbRockSmashRandomEncounter)

if defined?(Kernel)
  module Kernel
    def pbRandomItem
      return TravelExpansionFramework.keishou_random_rock_smash_item! if defined?(TravelExpansionFramework) &&
                                                                         TravelExpansionFramework.respond_to?(:keishou_random_rock_smash_item!)
      return false
    end unless method_defined?(:pbRandomItem)
    module_function :pbRandomItem if method_defined?(:pbRandomItem) && !respond_to?(:pbRandomItem)

    def pbRockSmashRandomEncounter
      return TravelExpansionFramework.keishou_rock_smash_random_encounter! if defined?(TravelExpansionFramework) &&
                                                                              TravelExpansionFramework.respond_to?(:keishou_rock_smash_random_encounter!)
      return false
    end unless method_defined?(:pbRockSmashRandomEncounter)
    module_function :pbRockSmashRandomEncounter if method_defined?(:pbRockSmashRandomEncounter) &&
                                                   !respond_to?(:pbRockSmashRandomEncounter)
  end
end

if !defined?(NoteConfig)
  module NoteConfig
    NUM_NOTE_STORAGE = 100 unless const_defined?(:NUM_NOTE_STORAGE)
    NOTE_STORAGE_VARIABLE = 0 unless const_defined?(:NOTE_STORAGE_VARIABLE)
    POKEMON = :BULBASAUR unless const_defined?(:POKEMON)
    FULL_MESSAGE = "There's no space for the note. Please, increase the notebook capacity." unless const_defined?(:FULL_MESSAGE)
    NEW_SCENE = false unless const_defined?(:NEW_SCENE)
    NOTES_BACKGROUND = [:BRIDGETMAIL, :GREETMAIL, :THANKSMAIL, :REPLYMAIL].freeze unless const_defined?(:NOTES_BACKGROUND)
    ICON_NOTE = [].freeze unless const_defined?(:ICON_NOTE)
  end
end

def writeNote
  return TravelExpansionFramework.keishou_write_note
end unless defined?(writeNote)

def pbMoveToNotebook(pokemon)
  return false if !defined?(TravelExpansionFramework)
  notes = TravelExpansionFramework.keishou_global_notebook
  return false if notes.length >= TravelExpansionFramework.keishou_note_storage_limit
  mail = pokemon.mail if pokemon && pokemon.respond_to?(:mail)
  return false if mail.nil?
  notes << mail
  pokemon.mail = nil if pokemon.respond_to?(:mail=)
  return true
rescue
  return false
end unless defined?(pbMoveToNotebook)

def pbPCNotebook
  return TravelExpansionFramework.keishou_open_notebook_list
end unless defined?(pbPCNotebook)

def pbNewNotebookScreen
  return TravelExpansionFramework.keishou_open_notebook_list
end unless defined?(pbNewNotebookScreen)

if defined?(Player)
  class Player
    attr_accessor :charmsActive
    attr_accessor :eleCharmsActive
    attr_accessor :charmlist
    attr_accessor :elementCharmlist
    attr_accessor :last_wish_time
    attr_accessor :link_charm_data
    attr_accessor :ball_for_apricorn
    attr_accessor :next_run
    attr_accessor :activeNature
    attr_accessor :natureList
    attr_accessor :maxCharms
    attr_accessor :active_count
    attr_accessor :tera_charged

    def initializeCharms
      return TravelExpansionFramework.keishou_initialize_charms!(self)
    end unless method_defined?(:initializeCharms)

    def activeCharm?(charm)
      return TravelExpansionFramework.keishou_active_charm?(charm, self)
    end unless method_defined?(:activeCharm?)

    def tera_charged?
      return true if @tera_charged.nil?
      return @tera_charged ? true : false
    end unless method_defined?(:tera_charged?)

    def has_pokemon_tera_type?(_type = nil)
      return false
    end unless method_defined?(:has_pokemon_tera_type?)
  end
end

if defined?(Trainer)
  class Trainer
    attr_accessor :charmsActive
    attr_accessor :eleCharmsActive
    attr_accessor :charmlist
    attr_accessor :elementCharmlist
    attr_accessor :last_wish_time
    attr_accessor :link_charm_data
    attr_accessor :ball_for_apricorn
    attr_accessor :next_run
    attr_accessor :activeNature
    attr_accessor :natureList
    attr_accessor :maxCharms
    attr_accessor :active_count
    attr_accessor :tera_charged

    def initializeCharms
      return TravelExpansionFramework.keishou_initialize_charms!(self)
    end unless method_defined?(:initializeCharms)

    def activeCharm?(charm)
      return TravelExpansionFramework.keishou_active_charm?(charm, self)
    end unless method_defined?(:activeCharm?)

    def tera_charged?
      return true if @tera_charged.nil?
      return @tera_charged ? true : false
    end unless method_defined?(:tera_charged?)

    def has_pokemon_tera_type?(_type = nil)
      return false
    end unless method_defined?(:has_pokemon_tera_type?)
  end
end

if defined?(GameData::Item)
  module GameData
    class Item
      alias tef_keishou_original_name name unless method_defined?(:tef_keishou_original_name)
      alias tef_keishou_original_name_plural name_plural unless method_defined?(:tef_keishou_original_name_plural)
      alias tef_keishou_original_description description unless method_defined?(:tef_keishou_original_description)

      def name
        value = TravelExpansionFramework.keishou_item_display_value(self, :name) if defined?(TravelExpansionFramework) &&
                                                                                    TravelExpansionFramework.respond_to?(:keishou_item_display_value)
        return value if value && !value.empty?
        return tef_keishou_original_name
      end

      def name_plural
        value = TravelExpansionFramework.keishou_item_display_value(self, :name_plural) if defined?(TravelExpansionFramework) &&
                                                                                          TravelExpansionFramework.respond_to?(:keishou_item_display_value)
        return value if value && !value.empty?
        return tef_keishou_original_name_plural
      end

      def description
        value = TravelExpansionFramework.keishou_item_display_value(self, :description) if defined?(TravelExpansionFramework) &&
                                                                                          TravelExpansionFramework.respond_to?(:keishou_item_display_value)
        return value if value && !value.empty?
        return tef_keishou_original_description
      end

      def is_charm?
        return defined?(TravelExpansionFramework) &&
               TravelExpansionFramework.keishou_charm_id?(self.id) &&
               !TravelExpansionFramework.keishou_element_charm_id?(self.id)
      end unless method_defined?(:is_charm?)

      def is_echarm?
        return defined?(TravelExpansionFramework) &&
               TravelExpansionFramework.keishou_element_charm_id?(self.id)
      end unless method_defined?(:is_echarm?)
    end
  end
end

def pbToggleCharm(charm, display_message = true)
  return TravelExpansionFramework.keishou_toggle_charm(charm, display_message)
end unless defined?(pbToggleCharm)

def pbGainCharm(charm)
  return TravelExpansionFramework.keishou_gain_charm(charm, false, false)
end unless defined?(pbGainCharm)

def pbSilentGainCharm(charm)
  return TravelExpansionFramework.keishou_gain_charm(charm, true, false)
end unless defined?(pbSilentGainCharm)

def pbGainElementCharm(charm)
  return TravelExpansionFramework.keishou_gain_charm(charm, false, true)
end unless defined?(pbGainElementCharm)

def pbRemoveCharm(charm)
  return TravelExpansionFramework.keishou_remove_charm(charm, false)
end unless defined?(pbRemoveCharm)

def pbSilentRemoveCharm(charm)
  return TravelExpansionFramework.keishou_remove_charm(charm, true)
end unless defined?(pbSilentRemoveCharm)

def pbDeactivateAll
  return TravelExpansionFramework.keishou_deactivate_all_charms
end unless defined?(pbDeactivateAll)

def pbGiveAllCharms
  return TravelExpansionFramework.keishou_give_all_charms(false)
end unless defined?(pbGiveAllCharms)

def pbGiveAllECharms
  return TravelExpansionFramework.keishou_give_all_charms(true)
end unless defined?(pbGiveAllECharms)

def countActiveCharms
  return TravelExpansionFramework.keishou_count_active_charms
end unless defined?(countActiveCharms)

def activeCharm?(charm)
  return TravelExpansionFramework.keishou_active_charm?(charm)
end unless defined?(activeCharm?)

def pbGC(charm)
  return pbGainCharm(charm)
end unless defined?(pbGC)

def pbGEC(charm)
  return pbGainElementCharm(charm)
end unless defined?(pbGEC)

def pbDAC
  return pbDeactivateAll
end unless defined?(pbDAC)

def pbGAC
  return pbGiveAllCharms
end unless defined?(pbGAC)

def pbGAEC
  return pbGiveAllECharms
end unless defined?(pbGAEC)

def pbRC(charm)
  return pbRemoveCharm(charm)
end unless defined?(pbRC)

def pbSGC(charm)
  return pbSilentGainCharm(charm)
end unless defined?(pbSGC)

def pbSRC(charm)
  return pbSilentRemoveCharm(charm)
end unless defined?(pbSRC)

def pbIncMaxCharms(inc = 1)
  player = TravelExpansionFramework.keishou_player
  TravelExpansionFramework.keishou_initialize_charms!(player)
  player.maxCharms = [player.maxCharms.to_i + inc.to_i, 0].max if player && player.respond_to?(:maxCharms=)
  return player ? player.maxCharms : 0
end unless defined?(pbIncMaxCharms)

def pbDecMaxCharms(dec = 1)
  player = TravelExpansionFramework.keishou_player
  TravelExpansionFramework.keishou_initialize_charms!(player)
  player.maxCharms = [player.maxCharms.to_i - dec.to_i, 0].max if player && player.respond_to?(:maxCharms=)
  return player ? player.maxCharms : 0
end unless defined?(pbDecMaxCharms)

if defined?(Interpreter) && Interpreter.method_defined?(:command_314)
  class Interpreter
    alias tef_keishou_tera_original_command_314 command_314 unless method_defined?(:tef_keishou_tera_original_command_314)

    def command_314
      $player.tera_charged = true if defined?($player) && $player && $player.respond_to?(:tera_charged=)
      return tef_keishou_tera_original_command_314
    end
  end
end

if defined?(pbGenerateWildPokemon) && !Object.private_method_defined?(:tef_keishou_original_pbGenerateWildPokemon)
  alias tef_keishou_original_pbGenerateWildPokemon pbGenerateWildPokemon

  def pbGenerateWildPokemon(species, level, isRoamer = false)
    pokemon = tef_keishou_original_pbGenerateWildPokemon(species, level, isRoamer)
    TravelExpansionFramework.keishou_apply_wild_charm_effects!(pokemon, isRoamer) if defined?(TravelExpansionFramework) &&
                                                                                     TravelExpansionFramework.respond_to?(:keishou_apply_wild_charm_effects!)
    return pokemon
  end
end

if defined?(PokeBattle_BattleCommon) && PokeBattle_BattleCommon.method_defined?(:pbCaptureCalc)
  module PokeBattle_BattleCommon
    alias tef_keishou_original_pbCaptureCalc pbCaptureCalc unless method_defined?(:tef_keishou_original_pbCaptureCalc)

    def pbCaptureCalc(pkmn, battler, catch_rate, ball)
      adjusted_rate = catch_rate
      adjusted_rate = TravelExpansionFramework.keishou_adjust_catch_rate_for_charms(pkmn, catch_rate) if defined?(TravelExpansionFramework) &&
                                                                                                          TravelExpansionFramework.respond_to?(:keishou_adjust_catch_rate_for_charms)
      return tef_keishou_original_pbCaptureCalc(pkmn, battler, adjusted_rate, ball)
    end
  end
end

if defined?(PokeBattle_Battle) && PokeBattle_Battle.method_defined?(:pbGainMoney)
  class PokeBattle_Battle
    alias tef_keishou_original_pbGainMoney pbGainMoney unless method_defined?(:tef_keishou_original_pbGainMoney)

    def pbGainMoney
      old_money = pbPlayer.money if respond_to?(:pbPlayer) && pbPlayer
      result = tef_keishou_original_pbGainMoney
      TravelExpansionFramework.keishou_apply_gold_charm_bonus!(self, old_money) if defined?(TravelExpansionFramework) &&
                                                                                   TravelExpansionFramework.respond_to?(:keishou_apply_gold_charm_bonus!)
      return result
    end
  end
end

if defined?(pbItemRestoreHP) && !Object.private_method_defined?(:tef_keishou_original_pbItemRestoreHP)
  alias tef_keishou_original_pbItemRestoreHP pbItemRestoreHP

  def pbItemRestoreHP(pkmn, restoreHP)
    amount = restoreHP
    amount = TravelExpansionFramework.keishou_healing_charm_restore_amount(restoreHP) if defined?(TravelExpansionFramework) &&
                                                                                        TravelExpansionFramework.respond_to?(:keishou_healing_charm_restore_amount)
    return tef_keishou_original_pbItemRestoreHP(pkmn, amount)
  end
end

if defined?(pbItemBall) && !Object.private_method_defined?(:tef_keishou_original_pbItemBall)
  alias tef_keishou_original_pbItemBall pbItemBall

  def pbItemBall(item, quantity = 1, item_name = "", canRandom = true)
    adjusted_quantity = quantity
    hidden_item_event = false
    event_id = @event_id if instance_variable_defined?(:@event_id)
    if defined?($game_map) && $game_map && event_id && $game_map.respond_to?(:events)
      event = $game_map.events[event_id] rescue nil
      hidden_item_event = event && event.respond_to?(:name) && event.name.to_s[/hiddenitem/i]
    end
    adjusted_quantity = TravelExpansionFramework.keishou_adjust_item_ball_quantity(item, quantity) if hidden_item_event &&
                                                                                                      defined?(TravelExpansionFramework) &&
                                                                                                      TravelExpansionFramework.respond_to?(:keishou_adjust_item_ball_quantity)
    return tef_keishou_original_pbItemBall(item, adjusted_quantity, item_name, canRandom)
  end
end

if defined?(EventHandlers) && EventHandlers.respond_to?(:add)
  EventHandlers.add(:on_player_step_taken, :tef_keishou_healing_charm_tick,
                    proc {
                      TravelExpansionFramework.keishou_step_healing_tick! if defined?(TravelExpansionFramework) &&
                                                                             TravelExpansionFramework.respond_to?(:keishou_step_healing_tick!)
                    })
end
