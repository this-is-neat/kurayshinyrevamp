module TravelExpansionFramework
  RELEASE_COMPATIBILITY_VERSION = "2026.05-rc1" unless const_defined?(:RELEASE_COMPATIBILITY_VERSION)
  RELEASE_COMPATIBILITY_FILENAME = "release_compatibility_manifest.json" unless const_defined?(:RELEASE_COMPATIBILITY_FILENAME)
  RELEASE_SHIM_CATALOG_FILENAME = "release_shim_catalog.json" unless const_defined?(:RELEASE_SHIM_CATALOG_FILENAME)

  RELEASE_COMPATIBILITY_CATEGORIES = [
    "startup",
    "story_transfer",
    "trainer_battle",
    "item_handlers",
    "town_map",
    "follower_system",
    "bridge_passability",
    "encounters",
    "dex",
    "menu_settings",
    "save_load_recovery"
  ].freeze unless const_defined?(:RELEASE_COMPATIBILITY_CATEGORIES)

  RELEASE_WORLD_DISPLAY_NAMES = {
    "reborn"             => "Pokemon Reborn",
    "xenoverse"         => "Pokemon Xenoverse",
    "insurgence"        => "Pokemon Insurgence",
    "pokemon_uranium"   => "Pokemon Uranium",
    "opalo"             => "Pokemon Opalo",
    "empyrean"          => "Pokemon Empyrean",
    "realidea"          => "Pokemon Realidea",
    "soulstones"        => "Pokemon Soulstones",
    "soulstones2"       => "Pokemon Soulstones 2",
    "anil"              => "Pokemon Anil / Indigo",
    "bushido"           => "Pokemon Bushido",
    "darkhorizon"       => "Pokemon Dark Horizon",
    "infinity"          => "Pokemon Infinity",
    "solar_eclipse"     => "Pokemon Solar Eclipse",
    "vanguard"          => "Pokemon Vanguard",
    "pokemon_z"         => "Pokemon Z",
    "chaos_in_vesita"   => "Pokemon Chaos in Vesita",
    "deserted"          => "Pokemon Deserted",
    "gadir_deluxe"      => "Pokemon Gadir Deluxe",
    "hollow_woods"      => "Pokemon Hollow Woods",
    "keishou"           => "Pokemon Keishou",
    "unbreakable_ties"  => "Pokemon Unbreakable Ties"
  }.freeze unless const_defined?(:RELEASE_WORLD_DISPLAY_NAMES)

  RELEASE_REQUIRED_SHIMS = {
    "reborn"            => ["startup", "story_transfer", "trainer_battle", "town_map", "menu_settings", "save_load_recovery"],
    "xenoverse"         => ["startup", "story_transfer", "trainer_battle", "item_handlers", "save_load_recovery"],
    "insurgence"        => ["startup", "story_transfer", "trainer_battle", "follower_system", "menu_settings", "save_load_recovery"],
    "pokemon_uranium"   => ["startup", "story_transfer", "trainer_battle", "encounters", "save_load_recovery"],
    "opalo"             => ["startup", "story_transfer", "trainer_battle", "encounters", "save_load_recovery"],
    "empyrean"          => ["startup", "story_transfer", "trainer_battle", "bridge_passability", "encounters", "save_load_recovery"],
    "realidea"          => ["startup", "story_transfer", "trainer_battle", "menu_settings", "save_load_recovery"],
    "soulstones"        => ["startup", "story_transfer", "trainer_battle", "item_handlers", "encounters", "save_load_recovery"],
    "soulstones2"       => ["startup", "story_transfer", "trainer_battle", "item_handlers", "encounters", "save_load_recovery"],
    "anil"              => ["startup", "story_transfer", "trainer_battle", "item_handlers", "town_map", "follower_system", "dex", "menu_settings", "save_load_recovery"],
    "bushido"           => ["startup", "story_transfer", "trainer_battle", "menu_settings", "save_load_recovery"],
    "darkhorizon"       => ["startup", "story_transfer", "trainer_battle", "item_handlers", "menu_settings", "save_load_recovery"],
    "infinity"          => ["startup", "story_transfer", "trainer_battle", "follower_system", "menu_settings", "save_load_recovery"],
    "solar_eclipse"     => ["startup", "story_transfer", "trainer_battle", "follower_system", "menu_settings", "save_load_recovery"],
    "vanguard"          => ["startup", "story_transfer", "trainer_battle", "save_load_recovery"],
    "pokemon_z"         => ["startup", "story_transfer", "trainer_battle", "menu_settings", "save_load_recovery"],
    "chaos_in_vesita"   => ["startup", "story_transfer", "trainer_battle", "save_load_recovery"],
    "deserted"          => ["startup", "story_transfer", "trainer_battle", "save_load_recovery"],
    "gadir_deluxe"      => ["startup", "story_transfer", "trainer_battle", "menu_settings", "save_load_recovery"],
    "hollow_woods"      => ["startup", "story_transfer", "trainer_battle", "item_handlers", "menu_settings", "save_load_recovery"],
    "keishou"           => ["startup", "story_transfer", "trainer_battle", "item_handlers", "town_map", "bridge_passability", "encounters", "menu_settings", "save_load_recovery"],
    "unbreakable_ties"  => ["startup", "story_transfer", "trainer_battle", "menu_settings", "save_load_recovery"]
  }.freeze unless const_defined?(:RELEASE_REQUIRED_SHIMS)

  RELEASE_KNOWN_RISKS = {
    "reborn"            => ["story flags after scripted crashes", "map transfer interpreter staleness"],
    "empyrean"          => ["bridge passability and over/under bridge state"],
    "soulstones"        => ["helper methods and edge map connections"],
    "soulstones2"       => ["helper methods and starter setup"],
    "anil"              => ["native menus, town map language, follower/photo helpers, and transfer release"],
    "bushido"           => ["battle scripting setup and party ownership reset"],
    "darkhorizon"       => ["EliteBattle setup and trainer wrappers"],
    "infinity"          => ["day-night helper methods and roaming checks"],
    "solar_eclipse"     => ["intro setting menus and trainer-card setup"],
    "hollow_woods"      => ["game-mode screens, starter selection, and quest helpers"],
    "keishou"           => ["native item handlers, charm/crafting/storage, town map routing, bridge and encounter tags"]
  }.freeze unless const_defined?(:RELEASE_KNOWN_RISKS)

  RELEASE_SMOKE_ROUTE = [
    "enter from PC or travel terminal",
    "complete first required dialogue",
    "trigger one map transfer",
    "open menu and town map",
    "run one wild battle and one trainer battle",
    "save, quit, reload, and return home"
  ].freeze unless const_defined?(:RELEASE_SMOKE_ROUTE)

  RELEASE_GENERIC_SHIM_CATALOG = {
    "pbZoomIn"                  => { "category" => "map_visual",       "default" => "true",  "note" => "Visual zoom request is ignored safely." },
    "pbZoomOut"                 => { "category" => "map_visual",       "default" => "true",  "note" => "Visual zoom request is ignored safely." },
    "pbWatchTV"                 => { "category" => "item_handlers",    "default" => "true",  "note" => "TV flavor event is acknowledged." },
    "pbCheckRoaming"            => { "category" => "encounters",       "default" => "false", "note" => "Unsupported roaming check fails closed." },
    "pbHasStarters?"            => { "category" => "startup",          "default" => "party_present", "note" => "Starter ownership is inferred from host party." },
    "prerandomizeMiningStones"  => { "category" => "startup",          "default" => "true",  "note" => "Mining pre-randomization is skipped safely." },
    "useAirDragonite"           => { "category" => "story_transfer",   "default" => "false", "note" => "Unsupported ride shortcut fails closed." },
    "pbHealingMachine"          => { "category" => "item_handlers",    "default" => "heal_party", "note" => "Host party heal fallback." },
    "pbXDPC"                    => { "category" => "item_handlers",    "default" => "host_pc", "note" => "External PC terminal opens the host PC UI." },
    "pbPokeMartWorker"          => { "category" => "item_handlers",    "default" => "host_mart", "note" => "External mart worker opens a safe host mart inventory." },
    "characterPopup"            => { "category" => "story_transfer",   "default" => "true",  "note" => "Popup marker is skipped safely." },
    "getCompletedQuests"        => { "category" => "menu_settings",    "default" => "array", "note" => "Quest list is host-local until native quest bridge is certified." },
    "getActiveQuests"           => { "category" => "menu_settings",    "default" => "array", "note" => "Quest list is host-local until native quest bridge is certified." },
    "pbRandomItem"              => { "category" => "item_handlers",    "default" => "nil",   "note" => "Unsupported random pickup gives no item." },
    "TrainerBattle.start"       => { "category" => "trainer_battle",   "default" => "true",  "note" => "Last-resort trainer wrapper prevents crashes." },
    "LevelCapsEX.enabled?"      => { "category" => "menu_settings",    "default" => "false", "note" => "Unsupported level-cap plugin is treated as disabled." },
    "FollowingPkmn.active?"     => { "category" => "follower_system",  "default" => "false", "note" => "Follower system reports inactive unless a world bridge owns it." },
    "NilClass#quantity"         => { "category" => "item_handlers",    "default" => "zero",  "note" => "Missing item storage queries fail closed." }
  }.freeze unless const_defined?(:RELEASE_GENERIC_SHIM_CATALOG)

  module_function

  def release_compatibility_manifest_path
    return File.join(framework_root, RELEASE_COMPATIBILITY_FILENAME)
  end

  def release_shim_catalog_path
    return File.join(framework_root, RELEASE_SHIM_CATALOG_FILENAME)
  end

  def release_world_ids
    ids = RELEASE_WORLD_DISPLAY_NAMES.keys
    ids = ids + registry(:expansions).keys.map { |id| id.to_s } if respond_to?(:registry)
    return ids.uniq.sort
  rescue
    return RELEASE_WORLD_DISPLAY_NAMES.keys.sort
  end

  def release_world_display_name(expansion_id)
    id = expansion_id.to_s
    manifest = manifest_for(id) rescue nil
    return manifest[:name].to_s if manifest && manifest[:name] && !manifest[:name].to_s.empty?
    return RELEASE_WORLD_DISPLAY_NAMES[id] || id.split("_").map { |part| part.capitalize }.join(" ")
  end

  def release_default_world_profile(expansion_id)
    id = expansion_id.to_s
    manifest = manifest_for(id) rescue nil
    source = external_projects[id] rescue nil
    installed = !manifest.nil? || !source.nil?
    active = expansion_active?(id) rescue false
    required = Array(RELEASE_REQUIRED_SHIMS[id])
    required = RELEASE_COMPATIBILITY_CATEGORIES if required.empty?
    return {
      "id"                    => id,
      "display_name"          => release_world_display_name(id),
      "status"                => "release_candidate",
      "installed"             => installed,
      "active"                => active,
      "required_categories"   => required,
      "known_risks"           => Array(RELEASE_KNOWN_RISKS[id]),
      "last_verified_smoke_route" => RELEASE_SMOKE_ROUTE,
      "host_first"            => true,
      "host_battle_ui_locked" => true,
      "fail_closed"           => true
    }
  rescue => e
    log("[release] default profile failed for #{expansion_id}: #{e.class}: #{e.message}") if respond_to?(:log)
    return {
      "id"                    => id,
      "display_name"          => id,
      "status"                => "release_candidate",
      "installed"             => false,
      "active"                => false,
      "required_categories"   => RELEASE_COMPATIBILITY_CATEGORIES,
      "known_risks"           => [],
      "last_verified_smoke_route" => RELEASE_SMOKE_ROUTE,
      "host_first"            => true,
      "host_battle_ui_locked" => true,
      "fail_closed"           => true
    }
  end

  def release_default_compatibility_manifest
    worlds = {}
    release_world_ids.each { |id| worlds[id] = release_default_world_profile(id) }
    return {
      "schema_version" => 1,
      "version"       => RELEASE_COMPATIBILITY_VERSION,
      "generated_by"  => FRAMEWORK_MOD_ID,
      "worlds"        => worlds,
      "safety_rules"  => [
        "host save data stays authoritative",
        "canonical location updates only after a valid loaded map and released player state",
        "missing worlds and missing assets rescue to host home and keep dormant metadata",
        "host dex shadow is merged from party and PC instead of reset by imported setup",
        "host battle UI remains locked unless a world UI is certified"
      ]
    }
  end

  def release_hash_get(hash, key)
    return nil if !hash.is_a?(Hash)
    return hash[key] if hash.has_key?(key)
    symbol = key.to_s.to_sym
    return hash[symbol] if hash.has_key?(symbol)
    return nil
  end

  def normalize_release_world_profile(expansion_id, raw_profile)
    profile = release_default_world_profile(expansion_id)
    return profile if !raw_profile.is_a?(Hash)
    raw_profile.each_pair do |key, value|
      text_key = key.to_s
      next if text_key.empty?
      profile[text_key] = value
    end
    profile["id"] = expansion_id.to_s
    profile["display_name"] = normalize_string(profile["display_name"], release_world_display_name(expansion_id))
    profile["status"] = normalize_string(profile["status"], "release_candidate")
    profile["required_categories"] = Array(profile["required_categories"]).map { |category| category.to_s }.uniq
    profile["required_categories"] = RELEASE_COMPATIBILITY_CATEGORIES if profile["required_categories"].empty?
    profile["known_risks"] = Array(profile["known_risks"]).map { |risk| risk.to_s }.reject { |risk| risk.empty? }
    profile["last_verified_smoke_route"] = Array(profile["last_verified_smoke_route"]).map { |step| step.to_s }.reject { |step| step.empty? }
    profile["last_verified_smoke_route"] = RELEASE_SMOKE_ROUTE if profile["last_verified_smoke_route"].empty?
    profile["installed"] = !manifest_for(expansion_id).nil? rescue profile["installed"] == true
    profile["active"] = expansion_active?(expansion_id) rescue profile["active"] == true
    profile["host_first"] = profile["host_first"] != false
    profile["host_battle_ui_locked"] = profile["host_battle_ui_locked"] != false
    profile["fail_closed"] = profile["fail_closed"] != false
    return profile
  end

  def normalize_release_compatibility_manifest(raw)
    manifest = release_default_compatibility_manifest
    return manifest if !raw.is_a?(Hash)
    version = release_hash_get(raw, "version")
    manifest["version"] = normalize_string(version, RELEASE_COMPATIBILITY_VERSION)
    raw_worlds = release_hash_get(raw, "worlds")
    if raw_worlds.is_a?(Array)
      raw_worlds.each do |entry|
        next if !entry.is_a?(Hash)
        id = normalize_string(release_hash_get(entry, "id"), "")
        next if id.empty?
        manifest["worlds"][id] = normalize_release_world_profile(id, entry)
      end
    elsif raw_worlds.is_a?(Hash)
      raw_worlds.each_pair do |id, entry|
        manifest["worlds"][id.to_s] = normalize_release_world_profile(id.to_s, entry)
      end
    end
    release_world_ids.each do |id|
      manifest["worlds"][id] = normalize_release_world_profile(id, manifest["worlds"][id])
    end
    return manifest
  end

  def release_compatibility_manifest
    raw = safe_json_parse(release_compatibility_manifest_path)
    return normalize_release_compatibility_manifest(raw)
  rescue => e
    log("[release] compatibility manifest read failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return release_default_compatibility_manifest
  end

  def refresh_release_compatibility!
    manifest = release_compatibility_manifest
    table = registry(:release_compatibility)
    table.clear
    manifest["worlds"].each_pair { |id, profile| table[id.to_s] = profile }
    root = ensure_save_root rescue nil
    if root && root.respond_to?(:release_manifest_version=)
      root.release_manifest_version = manifest["version"]
    end
    return table
  rescue => e
    log("[release] refresh failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return {}
  end

  def release_world_profile(expansion_id)
    id = expansion_id.to_s
    refresh_release_compatibility! if registry(:release_compatibility).empty?
    return registry(:release_compatibility)[id] || release_default_world_profile(id)
  rescue
    return release_default_world_profile(expansion_id)
  end

  def release_world_status(expansion_id)
    return release_world_profile(expansion_id)["status"].to_s
  rescue
    return "release_candidate"
  end

  def release_world_release_candidate?(expansion_id)
    status = release_world_status(expansion_id)
    return status == "release_candidate" || status == "verified"
  end

  def release_required_shims(expansion_id)
    return Array(release_world_profile(expansion_id)["required_categories"])
  rescue
    return []
  end

  def release_known_risks(expansion_id)
    return Array(release_world_profile(expansion_id)["known_risks"])
  rescue
    return []
  end

  def release_smoke_route(expansion_id)
    return Array(release_world_profile(expansion_id)["last_verified_smoke_route"])
  rescue
    return RELEASE_SMOKE_ROUTE
  end

  def release_default_shim_catalog
    return {
      "schema_version" => 1,
      "version"       => RELEASE_COMPATIBILITY_VERSION,
      "shims"         => RELEASE_GENERIC_SHIM_CATALOG
    }
  end

  def normalize_release_shim_catalog(raw)
    catalog = release_default_shim_catalog
    return catalog if !raw.is_a?(Hash)
    version = release_hash_get(raw, "version")
    catalog["version"] = normalize_string(version, RELEASE_COMPATIBILITY_VERSION)
    raw_shims = release_hash_get(raw, "shims")
    if raw_shims.is_a?(Hash)
      raw_shims.each_pair do |name, entry|
        next if !entry.is_a?(Hash)
        normalized = {}
        entry.each_pair { |key, value| normalized[key.to_s] = value }
        normalized["category"] = normalize_string(normalized["category"], "missing_api")
        normalized["default"] = normalize_string(normalized["default"], "true")
        catalog["shims"][name.to_s] = normalized
      end
    end
    return catalog
  end

  def release_shim_catalog
    table = registry(:release_shims)
    return table if !table.empty?
    raw = safe_json_parse(release_shim_catalog_path)
    catalog = normalize_release_shim_catalog(raw)
    table.clear
    catalog["shims"].each_pair { |name, entry| table[name.to_s] = entry }
    return table
  rescue => e
    log("[release] shim catalog read failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return RELEASE_GENERIC_SHIM_CATALOG
  end

  def release_shim_entry(name)
    return release_shim_catalog[name.to_s] || RELEASE_GENERIC_SHIM_CATALOG[name.to_s]
  rescue
    return nil
  end

  def release_current_context_expansion_id
    id = current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    id = current_expansion_id if (id.nil? || id.to_s.empty?) && respond_to?(:current_expansion_id)
    id = current_map_expansion_id if (id.nil? || id.to_s.empty?) && respond_to?(:current_map_expansion_id)
    id = HOST_EXPANSION_ID if id.nil? || id.to_s.empty?
    return id.to_s
  rescue
    return HOST_EXPANSION_ID
  end

  def release_shim_hit_store
    @release_shim_hit_counts ||= {}
    return @release_shim_hit_counts
  end

  def record_release_shim_hit(name, category = nil, disposition = nil, expansion_id = nil)
    entry = release_shim_entry(name) || {}
    category ||= entry["category"] || "missing_api"
    disposition ||= entry["default"] || "true"
    expansion_id ||= release_current_context_expansion_id
    key = [expansion_id.to_s, category.to_s, name.to_s, disposition.to_s].join("|")
    store = release_shim_hit_store
    store[key] = integer(store[key], 0) + 1
    root = ensure_save_root rescue nil
    if root && root.respond_to?(:release_shim_hits)
      root.release_shim_hits ||= {}
      root.release_shim_hits[expansion_id.to_s] ||= {}
      root.release_shim_hits[expansion_id.to_s][name.to_s] = store[key]
    end
    if store[key] == 1 || (store[key] % 25) == 0
      log("[release] shim #{name} used in #{expansion_id} category=#{category} disposition=#{disposition} count=#{store[key]}") if respond_to?(:log)
    end
    return store[key]
  rescue => e
    log("[release] shim hit record failed for #{name}: #{e.class}: #{e.message}") if respond_to?(:log)
    return 0
  end

  def release_default_value(default_name, args = [])
    case default_name.to_s
    when "true"
      return true
    when "false"
      return false
    when "nil"
      return nil
    when "zero"
      return 0
    when "array"
      return []
    when "hash"
      return {}
    when "party_present"
      party = ($Trainer.party rescue [])
      return Array(party).compact.length > 0
    when "heal_party"
      release_heal_party!
      return true
    when "host_pc"
      release_open_host_pc!
      return true
    when "host_mart"
      release_open_host_mart!
      return true
    else
      return true
    end
  rescue
    return true
  end

  def release_safe_stub(name, default_name = nil, category = nil, *args)
    entry = release_shim_entry(name) || {}
    default_name ||= entry["default"] || "true"
    category ||= entry["category"] || "missing_api"
    record_release_shim_hit(name, category, default_name)
    return release_default_value(default_name, args)
  end

  def release_heal_party!
    if defined?(pbHealAll)
      pbHealAll
      return true
    end
    party = ($Trainer.party rescue [])
    Array(party).compact.each do |pokemon|
      if pokemon.respond_to?(:heal)
        pokemon.heal
        next
      end
      if pokemon.respond_to?(:totalhp) && pokemon.respond_to?(:hp=)
        pokemon.hp = pokemon.totalhp rescue nil
      end
      pokemon.status = nil if pokemon.respond_to?(:status=)
      pokemon.statusCount = 0 if pokemon.respond_to?(:statusCount=)
    end
    return true
  rescue => e
    log("[release] heal party fallback failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def release_open_host_pc!
    if defined?(pbPokeCenterPC)
      pbPokeCenterPC
      return true
    end
    if defined?(PokemonStorageScene) && defined?(PokemonStorageScreen) && defined?($PokemonStorage) && $PokemonStorage
      pbFadeOutIn {
        scene = PokemonStorageScene.new
        screen = PokemonStorageScreen.new(scene, $PokemonStorage)
        screen.pbStartScreen(0)
      }
      return true
    end
    return true
  rescue => e
    log("[release] host PC fallback failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def release_item_exists?(item)
    return GameData::Item.exists?(item) if defined?(GameData::Item) && GameData::Item.respond_to?(:exists?)
    return !GameData::Item.get(item).nil? if defined?(GameData::Item) && GameData::Item.respond_to?(:get)
    return true
  rescue
    return false
  end

  def release_default_mart_stock
    badges = 0
    if defined?($Trainer) && $Trainer
      badges = integer($Trainer.badge_count, 0) if $Trainer.respond_to?(:badge_count)
      badges = integer($Trainer.numbadges, badges) if badges <= 0 && $Trainer.respond_to?(:numbadges)
    end
    stock = case badges
            when 0
              [:POTION, :ANTIDOTE, :POKEBALL]
            when 1
              [:POTION, :ANTIDOTE, :PARLYZHEAL, :BURNHEAL, :ESCAPEROPE, :REPEL, :POKEBALL]
            when 2..5
              [:SUPERPOTION, :ANTIDOTE, :PARLYZHEAL, :BURNHEAL, :ESCAPEROPE, :SUPERREPEL, :POKEBALL]
            when 6..9
              [:SUPERPOTION, :ANTIDOTE, :PARLYZHEAL, :BURNHEAL, :ESCAPEROPE, :SUPERREPEL, :POKEBALL, :GREATBALL]
            else
              [:POKEBALL, :GREATBALL, :ULTRABALL, :SUPERREPEL, :MAXREPEL, :ESCAPEROPE, :FULLHEAL, :HYPERPOTION]
            end
    stock.find_all { |item| release_item_exists?(item) }
  rescue => e
    log("[release] default mart stock build failed: #{e.class}: #{e.message}") if respond_to?(:log)
    [:POTION, :ANTIDOTE, :POKEBALL].find_all { |item| release_item_exists?(item) }
  end

  def release_open_host_mart!(stock = nil, speech = nil, cantsell = false)
    stock = release_default_mart_stock if !stock.is_a?(Array) || stock.empty?
    stock = stock.find_all { |item| release_item_exists?(item) }
    stock = [:POTION, :POKEBALL].find_all { |item| release_item_exists?(item) } if stock.empty?
    if Kernel.respond_to?(:pbPokemonMart)
      Kernel.pbPokemonMart(stock, speech, cantsell)
      return true
    end
    if Object.private_method_defined?(:pbPokemonMart) || Object.method_defined?(:pbPokemonMart)
      Object.new.send(:pbPokemonMart, stock, speech, cantsell)
      return true
    end
    if defined?(pbPokemonMart)
      pbPokemonMart(stock, speech, cantsell)
      return true
    end
    if Kernel.respond_to?(:pbMessage)
      Kernel.pbMessage("The Poke Mart service is not available right now.")
    elsif defined?(pbMessage)
      pbMessage("The Poke Mart service is not available right now.")
    end
    return true
  rescue => e
    log("[release] host mart fallback failed safely: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def release_quest_store(key)
    return [] if !defined?($PokemonGlobal) || !$PokemonGlobal
    ivar = key == :completed ? :@tef_completed_quests : :@tef_active_quests
    $PokemonGlobal.instance_variable_set(ivar, []) if !$PokemonGlobal.instance_variable_defined?(ivar)
    value = $PokemonGlobal.instance_variable_get(ivar)
    value = [] if !value.is_a?(Array)
    $PokemonGlobal.instance_variable_set(ivar, value)
    return value
  rescue
    return []
  end

  def release_constant_fallback(name)
    text = name.to_s
    record_release_shim_hit("constant #{text}", "missing_constant", "fallback")
    return ::TrainerBattle if text == "TrainerBattle" && defined?(::TrainerBattle)
    return ::BattleScripting if text == "BattleScripting" && defined?(::BattleScripting)
    return ::PartyPicture if text == "PartyPicture" && defined?(::PartyPicture)
    return ::ChangeSpeed if text == "ChangeSpeed" && defined?(::ChangeSpeed)
    return ::GenderPickSelection if text == "GenderPickSelection" && defined?(::GenderPickSelection)
    return ::GameMode_Scene if text == "GameMode_Scene" && defined?(::GameMode_Scene)
    return ::GameModeScreen if text == "GameModeScreen" && defined?(::GameModeScreen)
    return ::DiegoWTsStarterSelection if text == "DiegoWTsStarterSelection" && defined?(::DiegoWTsStarterSelection)
    return ::LevelCapsEX if text == "LevelCapsEX" && defined?(::LevelCapsEX)
    return :DrewQuest if text == "DrewQuest"
    return nil
  rescue
    return nil
  end

  def write_release_index_report!
    refresh_release_compatibility! if registry(:release_compatibility).empty?
    report = {
      "generated_at"       => timestamp_string,
      "framework_version"  => VERSION,
      "manifest_version"   => RELEASE_COMPATIBILITY_VERSION,
      "host_first"         => true,
      "host_battle_ui_locked" => true,
      "worlds"             => registry(:release_compatibility),
      "shim_hits"          => release_shim_hit_store
    }
    return write_json_report("release_compatibility_index.json", report) if respond_to?(:write_json_report)
    return nil
  rescue => e
    log("[release] index report failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end
end

def pbZoomIn(*args)
  return TravelExpansionFramework.release_safe_stub("pbZoomIn", "true", "map_visual", *args)
end unless defined?(pbZoomIn)

def pbZoomOut(*args)
  return TravelExpansionFramework.release_safe_stub("pbZoomOut", "true", "map_visual", *args)
end unless defined?(pbZoomOut)

def pbWatchTV(*args)
  return TravelExpansionFramework.release_safe_stub("pbWatchTV", "true", "item_handlers", *args)
end unless defined?(pbWatchTV)

def pbCheckRoaming(*args)
  return TravelExpansionFramework.release_safe_stub("pbCheckRoaming", "false", "encounters", *args)
end unless defined?(pbCheckRoaming)

def pbHasStarters?
  return TravelExpansionFramework.release_safe_stub("pbHasStarters?", "party_present", "startup")
end unless defined?(pbHasStarters?)

def prerandomizeMiningStones(*args)
  return TravelExpansionFramework.release_safe_stub("prerandomizeMiningStones", "true", "startup", *args)
end unless defined?(prerandomizeMiningStones)

def useAirDragonite(*args)
  return TravelExpansionFramework.release_safe_stub("useAirDragonite", "false", "story_transfer", *args)
end unless defined?(useAirDragonite)

def pbHealingMachine(*args)
  return TravelExpansionFramework.release_safe_stub("pbHealingMachine", "heal_party", "item_handlers", *args)
end unless defined?(pbHealingMachine)

def pbXDPC(*args)
  return TravelExpansionFramework.release_safe_stub("pbXDPC", "host_pc", "item_handlers", *args)
end unless defined?(pbXDPC)

def pbPokeMartWorker(*args)
  return TravelExpansionFramework.release_safe_stub("pbPokeMartWorker", "host_mart", "item_handlers", *args)
end unless defined?(pbPokeMartWorker)

def characterPopup(label, event_ref = nil, *args)
  return TravelExpansionFramework.release_safe_stub("characterPopup", "true", "story_transfer", label, event_ref, *args)
end unless defined?(characterPopup)

def getCompletedQuests
  TravelExpansionFramework.record_release_shim_hit("getCompletedQuests", "menu_settings", "array") if defined?(TravelExpansionFramework)
  return TravelExpansionFramework.release_quest_store(:completed)
end unless defined?(getCompletedQuests)

def getActiveQuests
  TravelExpansionFramework.record_release_shim_hit("getActiveQuests", "menu_settings", "array") if defined?(TravelExpansionFramework)
  return TravelExpansionFramework.release_quest_store(:active)
end unless defined?(getActiveQuests)

def completeQuest(quest)
  completed = TravelExpansionFramework.release_quest_store(:completed)
  completed << quest if !completed.include?(quest)
  return true
end unless defined?(completeQuest)

def activateQuest(quest)
  active = TravelExpansionFramework.release_quest_store(:active)
  active << quest if !active.include?(quest)
  return true
end unless defined?(activateQuest)

def pbRandomItem(*args)
  return TravelExpansionFramework.release_safe_stub("pbRandomItem", "nil", "item_handlers", *args)
end unless defined?(pbRandomItem)

DrewQuest = :DrewQuest unless defined?(DrewQuest)

module Settings
end unless defined?(Settings)

if defined?(Settings) && Settings.respond_to?(:const_defined?)
  {
    :MONEY_MODIFIER        => 5501,
    :EXP_MODIFIER          => 5502,
    :CATCH_MODIFIER        => 5503,
    :PLAYER_IVS           => 5504,
    :OPPONENT_IVS         => 5505,
    :TRAINER_AI           => 5506,
    :PLAYER_DAMAGE_OUTPUT => 5507,
    :ENEMY_DAMAGE_OUTPUT  => 5508,
    :OPPONENT_LEVEL_MOD   => 5509,
    :OPPONENT_EVS         => 5510
  }.each_pair do |name, value|
    Settings.const_set(name, value) if !Settings.const_defined?(name)
  end
  Settings.const_set(:CUSTOMSETTINGS, []) if !Settings.const_defined?(:CUSTOMSETTINGS)
end

if defined?(PokemonSystem)
  class PokemonSystem
    def current_menu_theme
      @current_menu_theme ||= 0
      return @current_menu_theme
    end unless method_defined?(:current_menu_theme)

    def current_menu_theme=(value)
      @current_menu_theme = value
    end unless method_defined?(:current_menu_theme=)

    def difficulty
      @difficulty ||= 0
      return @difficulty
    end unless method_defined?(:difficulty)

    def difficulty=(value)
      @difficulty = value
    end unless method_defined?(:difficulty=)

    def daytone
      @daytone ||= 0
      return @daytone
    end unless method_defined?(:daytone)

    def daytone=(value)
      @daytone = value
    end unless method_defined?(:daytone=)

    def mystery_gift_unlocked
      @mystery_gift_unlocked ||= false
      return @mystery_gift_unlocked
    end unless method_defined?(:mystery_gift_unlocked)

    def mystery_gift_unlocked=(value)
      @mystery_gift_unlocked = value == true
    end unless method_defined?(:mystery_gift_unlocked=)

    if method_defined?(:pokedex=) && !method_defined?(:tef_release_original_pokedex_writer)
      alias tef_release_original_pokedex_writer pokedex=

      def pokedex=(value)
        TravelExpansionFramework.rebuild_host_dex_shadow_from_storage! if defined?(TravelExpansionFramework) &&
                                                                          TravelExpansionFramework.respond_to?(:rebuild_host_dex_shadow_from_storage!)
        tef_release_original_pokedex_writer(value)
        TravelExpansionFramework.restore_host_dex_shadow_to_player! if defined?(TravelExpansionFramework) &&
                                                                       TravelExpansionFramework.respond_to?(:restore_host_dex_shadow_to_player!)
        return value
      end
    end
  end
end

if defined?(Player)
  class Player
    def tef_release_list_attr(name)
      ivar = "@#{name}"
      instance_variable_set(ivar, []) if !instance_variable_defined?(ivar) || !instance_variable_get(ivar).is_a?(Array)
      return instance_variable_get(ivar)
    end unless method_defined?(:tef_release_list_attr)

    def owned
      return tef_release_list_attr(:owned)
    end unless method_defined?(:owned)

    def owned=(value)
      @owned = value.is_a?(Array) ? value : Array(value)
    end unless method_defined?(:owned=)

    def battlebelt
      return tef_release_list_attr(:battlebelt)
    end unless method_defined?(:battlebelt)

    def battlebelt=(value)
      @battlebelt = value.is_a?(Array) ? value : Array(value)
    end unless method_defined?(:battlebelt=)

    def difficulty
      @difficulty ||= 0
      return @difficulty
    end unless method_defined?(:difficulty)

    def difficulty=(value)
      @difficulty = value
    end unless method_defined?(:difficulty=)

    def wallpaper
      @wallpaper ||= 0
      return @wallpaper
    end unless method_defined?(:wallpaper)

    def wallpaper=(value)
      @wallpaper = value
    end unless method_defined?(:wallpaper=)

    def tera_charged
      @tera_charged ||= false
      return @tera_charged
    end unless method_defined?(:tera_charged)

    def tera_charged=(value)
      @tera_charged = value == true
    end unless method_defined?(:tera_charged=)

    def mystery_gift_unlocked
      @mystery_gift_unlocked ||= false
      return @mystery_gift_unlocked
    end unless method_defined?(:mystery_gift_unlocked)

    def mystery_gift_unlocked=(value)
      @mystery_gift_unlocked = value == true
    end unless method_defined?(:mystery_gift_unlocked=)
  end
end

module LevelCapsEX
end unless defined?(LevelCapsEX)

class << LevelCapsEX
  def enabled?
    TravelExpansionFramework.record_release_shim_hit("LevelCapsEX.enabled?", "menu_settings", "false") if defined?(TravelExpansionFramework)
    return false
  end unless method_defined?(:enabled?)

  def toggle
    TravelExpansionFramework.record_release_shim_hit("LevelCapsEX.toggle", "menu_settings", "false") if defined?(TravelExpansionFramework)
    return false
  end unless method_defined?(:toggle)
end

module FollowingPkmn
end unless defined?(FollowingPkmn)

module FollowingPkmn
  def self.active?
    TravelExpansionFramework.record_release_shim_hit("FollowingPkmn.active?", "follower_system", "false") if defined?(TravelExpansionFramework)
    return false
  end unless respond_to?(:active?)

  def self.toggle_off(*_args)
    return true
  end unless respond_to?(:toggle_off)
end

class TrainerBattle
  def self.start(*args)
    return pbTrainerBattle(args[0], args[1]) if defined?(pbTrainerBattle) && args.length >= 2
    return TravelExpansionFramework.release_safe_stub("TrainerBattle.start", "true", "trainer_battle", *args)
  rescue => e
    TravelExpansionFramework.log("[release] TrainerBattle.start fallback failed safely: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                                    TravelExpansionFramework.respond_to?(:log)
    return true
  end
end unless defined?(TrainerBattle)

module BattleScripting
end unless defined?(BattleScripting)

class << BattleScripting
  def tef_release_scripts
    @tef_release_scripts ||= {}
    return @tef_release_scripts
  end unless method_defined?(:tef_release_scripts)

  def setInScript(key, value)
    tef_release_scripts[key.to_s] = value
    TravelExpansionFramework.record_release_shim_hit("BattleScripting.setInScript", "trainer_battle", "true") if defined?(TravelExpansionFramework)
    return true
  end unless method_defined?(:setInScript)

  def getInScript(key)
    return tef_release_scripts[key.to_s]
  end unless method_defined?(:getInScript)
end

class ChangeSpeed
  def initialize(*_args)
  end

  def pbChangeSpeed(value = 0)
    TravelExpansionFramework.record_release_shim_hit("ChangeSpeed.pbChangeSpeed", "menu_settings", value.to_s) if defined?(TravelExpansionFramework)
    return true
  end
end unless defined?(ChangeSpeed)

class PartyPicture
  def initialize(*args)
    TravelExpansionFramework.record_release_shim_hit("PartyPicture.new", "follower_system", "true") if defined?(TravelExpansionFramework)
    @args = args
  end

  def dispose
    return true
  end
end unless defined?(PartyPicture)

class GenderPickSelection
  def self.show(*args)
    TravelExpansionFramework.record_release_shim_hit("GenderPickSelection.show", "menu_settings", "true") if defined?(TravelExpansionFramework)
    return true
  end
end unless defined?(GenderPickSelection)

class GameMode_Scene
  def initialize(*_args)
  end
end unless defined?(GameMode_Scene)

class GameModeScreen
  def initialize(scene = nil)
    @scene = scene
  end

  def pbStartScreen(*_args)
    TravelExpansionFramework.record_release_shim_hit("GameModeScreen.pbStartScreen", "menu_settings", "true") if defined?(TravelExpansionFramework)
    return true
  end
end unless defined?(GameModeScreen)

class DiegoWTsStarterSelection
  def initialize(*starters)
    @starters = starters
  end

  def pbStartScreen(*_args)
    TravelExpansionFramework.record_release_shim_hit("DiegoWTsStarterSelection.pbStartScreen", "startup", "true") if defined?(TravelExpansionFramework)
    return true
  end
end unless defined?(DiegoWTsStarterSelection)

module EliteBattle
end unless defined?(EliteBattle)

class << EliteBattle
  def InitializeSpecies(*args)
    TravelExpansionFramework.record_release_shim_hit("EliteBattle.InitializeSpecies", "startup", "true") if defined?(TravelExpansionFramework)
    return true
  end unless method_defined?(:InitializeSpecies)
end

module Kernel
  def doLegendEntrance(*args)
    TravelExpansionFramework.record_release_shim_hit("Kernel.doLegendEntrance", "story_transfer", "true") if defined?(TravelExpansionFramework)
    return true
  end unless method_defined?(:doLegendEntrance)

  def self.pbPokeMartWorker(*args)
    return TravelExpansionFramework.release_safe_stub("pbPokeMartWorker", "host_mart", "item_handlers", *args)
  end unless respond_to?(:pbPokeMartWorker)
end

class NilClass
  def quantity(*_args)
    TravelExpansionFramework.record_release_shim_hit("NilClass#quantity", "item_handlers", "zero") if defined?(TravelExpansionFramework)
    return 0
  end unless method_defined?(:quantity)

  def mystery_gift_unlocked
    TravelExpansionFramework.record_release_shim_hit("NilClass#mystery_gift_unlocked", "menu_settings", "false") if defined?(TravelExpansionFramework)
    return false
  end unless method_defined?(:mystery_gift_unlocked)
end

if defined?(Interpreter)
  class Interpreter
    TrainerBattle = ::TrainerBattle if defined?(::TrainerBattle) && !const_defined?(:TrainerBattle, false)
    BattleScripting = ::BattleScripting if defined?(::BattleScripting) && !const_defined?(:BattleScripting, false)
    PartyPicture = ::PartyPicture if defined?(::PartyPicture) && !const_defined?(:PartyPicture, false)
    ChangeSpeed = ::ChangeSpeed if defined?(::ChangeSpeed) && !const_defined?(:ChangeSpeed, false)
    GenderPickSelection = ::GenderPickSelection if defined?(::GenderPickSelection) && !const_defined?(:GenderPickSelection, false)
    GameMode_Scene = ::GameMode_Scene if defined?(::GameMode_Scene) && !const_defined?(:GameMode_Scene, false)
    GameModeScreen = ::GameModeScreen if defined?(::GameModeScreen) && !const_defined?(:GameModeScreen, false)
    DiegoWTsStarterSelection = ::DiegoWTsStarterSelection if defined?(::DiegoWTsStarterSelection) && !const_defined?(:DiegoWTsStarterSelection, false)
    LevelCapsEX = ::LevelCapsEX if defined?(::LevelCapsEX) && !const_defined?(:LevelCapsEX, false)
    DrewQuest = ::DrewQuest if defined?(::DrewQuest) && !const_defined?(:DrewQuest, false)
  end

  class << Interpreter
    alias tef_release_original_const_missing const_missing unless method_defined?(:tef_release_original_const_missing)

    def const_missing(name)
      fallback = TravelExpansionFramework.release_constant_fallback(name) if defined?(TravelExpansionFramework) &&
                                                                            TravelExpansionFramework.respond_to?(:release_constant_fallback)
      return const_set(name, fallback) if fallback
      return tef_release_original_const_missing(name) if respond_to?(:tef_release_original_const_missing, true)
      raise NameError, "uninitialized constant Interpreter::#{name}"
    end
  end
end

class << Object
  alias tef_release_original_const_missing const_missing unless method_defined?(:tef_release_original_const_missing)

  def const_missing(name)
    fallback = TravelExpansionFramework.release_constant_fallback(name) if defined?(TravelExpansionFramework) &&
                                                                          TravelExpansionFramework.respond_to?(:release_constant_fallback)
    return const_set(name, fallback) if fallback
    return tef_release_original_const_missing(name) if respond_to?(:tef_release_original_const_missing, true)
    raise NameError, "uninitialized constant Object::#{name}"
  end
end

TravelExpansionFramework.refresh_release_compatibility! if defined?(TravelExpansionFramework) &&
                                                          TravelExpansionFramework.respond_to?(:refresh_release_compatibility!)
TravelExpansionFramework.write_release_index_report! if defined?(TravelExpansionFramework) &&
                                                       TravelExpansionFramework.respond_to?(:write_release_index_report!)
