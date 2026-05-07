module TravelExpansionFramework
  module_function

  GENERIC_ENGLISH_TRANSLATION_SKIP_IDS = %w[
    anil pokemon_anil pokemon_indigo indigo
    opalo pokemon_opalo
    realidea
  ].freeze unless const_defined?(:GENERIC_ENGLISH_TRANSLATION_SKIP_IDS)

  def generic_english_translation_cache
    @generic_english_translation_cache ||= {}
  end

  def generic_english_translation_path_cache
    @generic_english_translation_path_cache ||= {}
  end

  def generic_english_translation_path(expansion_id)
    expansion = canonical_new_project_id(expansion_id)
    return nil if expansion.to_s.empty?
    info = external_projects[expansion] rescue nil
    cache_key_parts = [expansion]
    if info.is_a?(Hash)
      cache_key_parts << info[:root].to_s
      cache_key_parts << info[:prepared_project_root].to_s
      cache_key_parts << info[:prepared_data_root].to_s
    end
    cache_key = cache_key_parts.join("|")
    cache = generic_english_translation_path_cache
    return (cache[cache_key] == false ? nil : cache[cache_key]) if cache.has_key?(cache_key)
    project_roots = []
    data_roots = []
    if info.is_a?(Hash)
      project_roots << info[:prepared_project_root]
      project_roots << info[:filesystem_bridge_root]
      project_roots << info[:source_mount_root]
      project_roots << info[:archive_mount_root]
      project_roots << info[:root]
      data_roots << info[:prepared_data_root]
    end
    root = project_root_path(expansion, expansion) if respond_to?(:project_root_path)
    project_roots << root
    project_roots.concat(runtime_asset_roots_for_expansion(expansion)) if respond_to?(:runtime_asset_roots_for_expansion)
    root_list = project_roots.compact.map(&:to_s).reject(&:empty?).uniq
    data_root_list = data_roots.compact.map(&:to_s).reject(&:empty?).uniq
    project_relatives = [
      File.join("Data", "messages_english_game.dat"),
      File.join("Data", "messages_english.dat"),
      File.join("Data", "lang_english.dat"),
      File.join("Data", "English.dat"),
      File.join("Data", "english.dat"),
      File.join("Data", "messages_en.dat"),
      File.join("Data", "en.dat")
    ]
    data_relatives = [
      "messages_english_game.dat",
      "messages_english.dat",
      "lang_english.dat",
      "English.dat",
      "english.dat",
      "messages_en.dat",
      "en.dat"
    ]
    root_list.each do |candidate_root|
      [
        project_relatives,
        candidate_root.to_s.end_with?("/Data", "\\Data") ? data_relatives : []
      ].flatten.each do |relative|
        path = File.join(candidate_root, relative)
        exact = runtime_exact_file_path(path) if respond_to?(:runtime_exact_file_path)
        if exact && File.file?(exact)
          cache[cache_key] = exact
          return exact
        end
        if File.file?(path)
          cache[cache_key] = path
          return path
        end
      end
    end
    data_root_list.each do |candidate_root|
      data_relatives.each do |relative|
        path = File.join(candidate_root, relative)
        exact = runtime_exact_file_path(path) if respond_to?(:runtime_exact_file_path)
        if exact && File.file?(exact)
          cache[cache_key] = exact
          return exact
        end
        if File.file?(path)
          cache[cache_key] = path
          return path
        end
      end
    end
    cache[cache_key] = false
    return nil
  rescue
    return nil
  end

  def generic_english_translation_active_expansion_id(map_id = nil)
    expansion = active_project_expansion_id(new_project_expansion_ids, map_id) if respond_to?(:active_project_expansion_id)
    expansion = canonical_new_project_id(expansion)
    return nil if expansion.to_s.empty?
    return nil if GENERIC_ENGLISH_TRANSLATION_SKIP_IDS.include?(expansion)
    return nil if generic_english_translation_path(expansion).nil?
    return expansion
  rescue
    return nil
  end

  def generic_english_decode_translation_text(text)
    decoded = opalo_decode_translation_markup(text) if respond_to?(:opalo_decode_translation_markup)
    decoded ||= text.to_s.dup
    decoded.gsub!("&quot;", "\"")
    return decoded
  rescue
    return text.to_s
  end

  def generic_english_translation_key_variants(text)
    variants = []
    variants.concat(opalo_translation_key_variants(text)) if respond_to?(:opalo_translation_key_variants)
    source = text.to_s.dup
    source.gsub!("\r", "")
    source.gsub!(/\\n/i, " ")
    source.gsub!("\n", " ")
    source.gsub!("\001", "")
    source.gsub!(/\\(?:tg|xn)\[([^\]]+)\]/i, " \\1 ")
    source.gsub!(/\\[A-Za-z]+\[[^\]]*\]/, " ")
    source.gsub!(/<\/?[^>]+>/, " ")
    source.gsub!(/[ \t]+/, " ")
    source.strip!
    variants << source if !source.empty?
    return variants.compact.reject { |entry| entry.to_s.empty? }.uniq
  rescue
    return []
  end

  def generic_english_collect_translation_entry!(catalog, source, translated, scope = nil)
    return if source.nil? || translated.nil?
    source_text = source.to_s
    translated_text = generic_english_decode_translation_text(translated)
    return if source_text.empty? || translated_text.empty?
    keys = generic_english_translation_key_variants(source_text)
    return if keys.empty?
    keys.each do |key|
      if !scope.nil?
        catalog[:maps][scope] ||= {}
        catalog[:maps][scope][key] = translated_text
      else
        catalog[:script][key] = translated_text
      end
      catalog[:all][key] = translated_text if !catalog[:all].has_key?(key)
    end
    fuzzy_key = realidea_fuzzy_translation_key(source_text) if respond_to?(:realidea_fuzzy_translation_key)
    return if fuzzy_key.to_s.empty?
    if !scope.nil?
      catalog[:map_entries][scope] ||= []
      catalog[:map_entries][scope] << [fuzzy_key, translated_text]
    else
      catalog[:script_entries] << [fuzzy_key, translated_text]
    end
    catalog[:all_entries] << [fuzzy_key, translated_text]
  rescue => e
    log("[generic-english] translation entry failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def generic_english_collect_translation_container!(catalog, container, scope = nil)
    case container
    when Hash
      container.each do |source, translated|
        if source.is_a?(String) && translated.is_a?(String)
          generic_english_collect_translation_entry!(catalog, source, translated, scope)
        else
          generic_english_collect_translation_container!(catalog, translated, scope)
        end
      end
    when Array
      if container.length == 2 && container[0].is_a?(String) && container[1].is_a?(String)
        generic_english_collect_translation_entry!(catalog, container[0], container[1], scope)
      else
        container.each { |entry| generic_english_collect_translation_container!(catalog, entry, scope) }
      end
    end
  rescue => e
    log("[generic-english] translation section failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def generic_english_translation_catalog(expansion_id)
    expansion = canonical_new_project_id(expansion_id)
    return { :loaded => true, :maps => {}, :script => {}, :all => {}, :map_entries => {}, :script_entries => [], :all_entries => [] } if expansion.empty?
    cache = generic_english_translation_cache
    return cache[expansion] if cache.has_key?(expansion)
    catalog = {
      :loaded         => true,
      :maps           => {},
      :script         => {},
      :all            => {},
      :map_entries    => {},
      :script_entries => [],
      :all_entries    => []
    }
    path = generic_english_translation_path(expansion)
    if path && File.file?(path)
      data = File.open(path, "rb") { |file| Marshal.load(file) }
      if data.is_a?(Array)
        map_messages = data[0]
        if map_messages.is_a?(Array)
          map_messages.each_with_index do |entries, map_index|
            generic_english_collect_translation_container!(catalog, entries, map_index)
          end
        elsif map_messages.is_a?(Hash)
          map_messages.each do |map_index, entries|
            generic_english_collect_translation_container!(catalog, entries, integer(map_index, 0))
          end
        end
        data.each_with_index do |section, section_index|
          next if section_index == 0
          generic_english_collect_translation_container!(catalog, section, nil)
        end
      else
        generic_english_collect_translation_container!(catalog, data, nil)
      end
      log("[generic-english] loaded #{expansion} translations from #{path}") if respond_to?(:log)
    end
    cache[expansion] = catalog
    return catalog
  rescue => e
    log("[generic-english] catalog load failed for #{expansion_id}: #{e.class}: #{e.message}") if respond_to?(:log)
    cache[expansion] = { :loaded => true, :maps => {}, :script => {}, :all => {}, :map_entries => {}, :script_entries => [], :all_entries => [] } if defined?(cache) && expansion
    return cache[expansion] if defined?(cache) && expansion && cache[expansion]
    return { :loaded => true, :maps => {}, :script => {}, :all => {}, :map_entries => {}, :script_entries => [], :all_entries => [] }
  end

  def generic_english_current_local_map_id(expansion_id, map_id = nil)
    current_map_id = integer(map_id || ($game_map.map_id rescue 0), 0)
    return 0 if current_map_id <= 0
    return local_map_id_for(expansion_id, current_map_id) if respond_to?(:local_map_id_for)
    return current_map_id
  rescue
    return 0
  end

  def generic_english_fuzzy_translation(catalog, source, local_map_id)
    return nil if !respond_to?(:realidea_fuzzy_translation_key) || !respond_to?(:realidea_common_prefix_length)
    source_key = realidea_fuzzy_translation_key(source)
    return nil if source_key.length < 36
    candidates = []
    candidates.concat(catalog[:map_entries][local_map_id] || []) if catalog[:map_entries].is_a?(Hash)
    candidates.concat(catalog[:map_entries][0] || []) if catalog[:map_entries].is_a?(Hash) && local_map_id != 0
    candidates.concat(catalog[:script_entries] || [])
    candidates.concat(catalog[:all_entries] || [])
    best_text = nil
    best_score = 0
    candidates.each do |entry|
      next if !entry || entry.length < 2
      candidate_key = entry[0].to_s
      next if candidate_key.empty?
      score = realidea_common_prefix_length(source_key, candidate_key)
      next if score < 48 || score <= best_score
      best_score = score
      best_text = entry[1]
    end
    return best_text
  rescue
    return nil
  end

  def generic_english_translate_text(expansion_id, text, map_id = nil)
    source = text.to_s
    return source if source.empty?
    trailer = source[/\001+\z/].to_s
    lookup_source = trailer.empty? ? source : source[0, source.length - trailer.length]
    prefix = lookup_source[/\A(?:\\w\[[^\]]+\]\s*)+/i].to_s
    keys = generic_english_translation_key_variants(lookup_source)
    return source if keys.empty?
    catalog = generic_english_translation_catalog(expansion_id)
    local_map_id = generic_english_current_local_map_id(expansion_id, map_id)
    translated = nil
    if catalog[:maps].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:maps][local_map_id][key] if translated.nil? && catalog[:maps][local_map_id].is_a?(Hash)
        translated = catalog[:maps][0][key] if translated.nil? && catalog[:maps][0].is_a?(Hash)
        break if translated
      end
    end
    if translated.nil? && catalog[:script].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:script][key]
        break if translated
      end
    end
    if translated.nil? && catalog[:all].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:all][key]
        break if translated
      end
    end
    translated = generic_english_fuzzy_translation(catalog, lookup_source, local_map_id) if translated.nil?
    return source if translated.nil? || translated.to_s.empty?
    result = generic_english_decode_translation_text(translated)
    result = "#{prefix}#{result}" if !prefix.empty? && result !~ /\A#{Regexp.escape(prefix)}/
    return "#{result}#{trailer}"
  rescue => e
    log("[generic-english] lookup failed for #{expansion_id}: #{e.class}: #{e.message}") if respond_to?(:log)
    return text.to_s
  end
end

class PokemonGlobalMetadata
  attr_accessor :quests unless method_defined?(:quests)
end if defined?(PokemonGlobalMetadata)

class Quest
  attr_accessor :id unless method_defined?(:id)
  attr_accessor :name unless method_defined?(:name)
  attr_accessor :desc unless method_defined?(:desc)
  attr_accessor :npc unless method_defined?(:npc)
  attr_accessor :sprite unless method_defined?(:sprite)
  attr_accessor :location unless method_defined?(:location)
  attr_accessor :color unless method_defined?(:color)
  attr_accessor :time unless method_defined?(:time)
  attr_accessor :completed unless method_defined?(:completed)

  alias tef_batch_original_initialize initialize if !method_defined?(:tef_batch_original_initialize)

  def initialize(*args)
    if args.length >= 6
      return tef_batch_original_initialize(*args)
    end
    @id = args[0]
    @name = args[1].to_s
    @desc = args[1].to_s
    @npc = ""
    @sprite = ""
    @location = ""
    begin
      @color = pbColor(args[2] || :WHITE)
    rescue
      @color = args[2] || :WHITE
    end
    @time = Time.now rescue nil
    @completed = false
  end
end if defined?(Quest)

module TravelExpansionFramework
  class BatchQuestCollection
    attr_accessor :active_quests
    attr_accessor :completed_quests
    attr_accessor :failed_quests

    def initialize
      @active_quests = []
      @completed_quests = []
      @failed_quests = []
    end
  end unless const_defined?(:BatchQuestCollection)

  class << self
    alias tef_batch_original_prepare_new_project_text prepare_new_project_text if method_defined?(:prepare_new_project_text) &&
                                                                                  !method_defined?(:tef_batch_original_prepare_new_project_text)
    alias tef_batch_original_localized_external_trainer_text localized_external_trainer_text if method_defined?(:localized_external_trainer_text) &&
                                                                                                !method_defined?(:tef_batch_original_localized_external_trainer_text)
  end

  def self.prepare_new_project_text(text, map_id = nil)
    if respond_to?(:xenoverse_active_now?) && xenoverse_active_now?(map_id) && respond_to?(:xenoverse_translate_script_text)
      result = xenoverse_translate_script_text(text.to_s, map_id)
      result = cleanup_imported_message_text(result, map_id) if respond_to?(:cleanup_imported_message_text)
      return result
    end
    expansion = generic_english_translation_active_expansion_id(map_id)
    if expansion
      result = generic_english_translate_text(expansion, text, map_id)
      result = cleanup_imported_message_text(result, map_id) if respond_to?(:cleanup_imported_message_text)
      return result
    end
    return tef_batch_original_prepare_new_project_text(text, map_id) if respond_to?(:tef_batch_original_prepare_new_project_text)
    return text.to_s
  rescue
    return text.to_s
  end

  def self.localized_external_trainer_text(expansion_id, text, map_id = nil)
    expansion = canonical_new_project_id(expansion_id)
    if !GENERIC_ENGLISH_TRANSLATION_SKIP_IDS.include?(expansion) && generic_english_translation_path(expansion)
      return generic_english_translate_text(expansion, text, map_id || ($game_map.map_id rescue nil))
    end
    return tef_batch_original_localized_external_trainer_text(expansion_id, text, map_id) if respond_to?(:tef_batch_original_localized_external_trainer_text)
    return text.to_s
  rescue
    return text.to_s
  end
end

class Interpreter
  alias tef_batch_original_pbTrainerIntro pbTrainerIntro if method_defined?(:pbTrainerIntro) &&
                                                            !method_defined?(:tef_batch_original_pbTrainerIntro)

  def tef_batch_active_expansion_id
    map_id = @map_id if instance_variable_defined?(:@map_id)
    map_id = ($game_map.map_id rescue nil) if map_id.nil?
    return TravelExpansionFramework.current_new_project_expansion_id(map_id) if TravelExpansionFramework.respond_to?(:current_new_project_expansion_id)
    return nil
  rescue
    return nil
  end

  def tef_batch_metadata
    expansion = tef_batch_active_expansion_id
    return nil if expansion.to_s.empty?
    return TravelExpansionFramework.new_project_metadata(expansion) if TravelExpansionFramework.respond_to?(:new_project_metadata)
    return nil
  rescue
    return nil
  end

  def tef_batch_translate_map_id(map_id)
    expansion = tef_batch_active_expansion_id
    return map_id if expansion.to_s.empty?
    return TravelExpansionFramework.translate_expansion_map_id(expansion, map_id) if TravelExpansionFramework.respond_to?(:translate_expansion_map_id)
    return map_id
  rescue
    return map_id
  end

  def pbTrainerIntro(symbol)
    expansion = tef_batch_active_expansion_id
    if !expansion.to_s.empty? && TravelExpansionFramework.respond_to?(:external_trainer_catalog)
      TravelExpansionFramework.external_trainer_catalog(expansion)
      data = TravelExpansionFramework.imported_trainer_type_data(symbol) if TravelExpansionFramework.respond_to?(:imported_trainer_type_data)
      runtime = data[:runtime_id] if data.is_a?(Hash)
      if runtime && respond_to?(:tef_batch_original_pbTrainerIntro, true)
        return tef_batch_original_pbTrainerIntro(runtime) rescue true
      end
      pbGlobalLock if respond_to?(:pbGlobalLock)
      return true if !respond_to?(:tef_batch_original_pbTrainerIntro, true)
    end
    return tef_batch_original_pbTrainerIntro(symbol) if respond_to?(:tef_batch_original_pbTrainerIntro, true)
    return true
  rescue
    return true
  end

  def pbGet(variable_id)
    return $game_variables[variable_id.to_i] if defined?($game_variables) && $game_variables
    return nil
  rescue
    return nil
  end if !method_defined?(:pbGet)

  def pbSet(variable_id, value)
    $game_variables[variable_id.to_i] = value if defined?($game_variables) && $game_variables
    return value
  rescue
    return value
  end if !method_defined?(:pbSet)

  def pbGetPokemon(variable_id)
    return pbGet(variable_id)
  rescue
    return nil
  end if !method_defined?(:pbGetPokemon)

  def pbItemChest(item, quantity = 1, *args)
    return pbItemBall(item, quantity, *args) if respond_to?(:pbItemBall, true)
    return pbReceiveItem(item, quantity) if respond_to?(:pbReceiveItem, true)
    return false
  rescue
    return false
  end if !method_defined?(:pbItemChest)

  def pbGetKeyItem(item, quantity = 1, *args)
    return pbReceiveItem(item, quantity, *args) if respond_to?(:pbReceiveItem, true)
    return false
  rescue
    return false
  end if !method_defined?(:pbGetKeyItem)

  def pbReceiveIM(key = nil, *args)
    meta = tef_batch_metadata
    if meta
      meta["instant_messages"] ||= []
      meta["instant_messages"] << key.to_s
      meta["instant_messages"].shift while meta["instant_messages"].length > 100
    end
    return true
  rescue
    return true
  end if !method_defined?(:pbReceiveIM)

  def pbSetSelfSwitchArray(first_event_id, last_event_id, switch_name = "A", value = true, map_id = nil)
    map_id = tef_batch_translate_map_id(map_id) if map_id
    first_event_id.to_i.upto(last_event_id.to_i) do |event_id|
      pbSetSelfSwitch(event_id, switch_name, value, map_id) if respond_to?(:pbSetSelfSwitch, true)
    end
    return true
  rescue
    return false
  end if !method_defined?(:pbSetSelfSwitchArray)

  def pbSetSelfSwitch2(map_id, event_id, switch_name = "A", value = true)
    map_id = tef_batch_translate_map_id(map_id)
    return pbSetSelfSwitch(event_id, switch_name, value, map_id) if respond_to?(:pbSetSelfSwitch, true)
    return false
  rescue
    return false
  end if !method_defined?(:pbSetSelfSwitch2)

  def colorQuest(color = "white")
    return color.to_s
  rescue
    return "white"
  end if !method_defined?(:colorQuest)

  def tef_batch_quest_store
    meta = tef_batch_metadata
    meta["quest_state"] ||= {} if meta
    return meta ? meta["quest_state"] : {}
  rescue
    return {}
  end

  def tef_batch_quest_key(quest_id)
    text = quest_id.respond_to?(:id) ? quest_id.id.to_s : quest_id.to_s
    text = text[1, text.length - 1] if text[0, 1] == ":"
    return text
  rescue
    return quest_id.to_s
  end

  def tef_batch_quest_symbol(quest_id)
    return tef_batch_quest_key(quest_id).to_sym
  rescue
    return quest_id
  end

  def tef_batch_quest_entry(store, quest_id)
    key = tef_batch_quest_key(quest_id)
    old_key = quest_id.to_s
    store[key] ||= store[old_key] || {}
    store.delete(old_key) if old_key != key && store.has_key?(old_key)
    return store[key]
  rescue
    return {}
  end

  def tef_batch_global_quest_collection
    return nil if !defined?($PokemonGlobal) || !$PokemonGlobal
    quests = $PokemonGlobal.quests if $PokemonGlobal.respond_to?(:quests)
    if !quests
      quests = TravelExpansionFramework::BatchQuestCollection.new
      $PokemonGlobal.quests = quests if $PokemonGlobal.respond_to?(:quests=)
    end
    if quests
      quests.active_quests = [] if quests.respond_to?(:active_quests=) && !quests.active_quests
      quests.completed_quests = [] if quests.respond_to?(:completed_quests=) && !quests.completed_quests
      quests.failed_quests = [] if quests.respond_to?(:failed_quests=) && !quests.failed_quests
    end
    return quests
  rescue
    return nil
  end

  def tef_batch_quest_id_list(list)
    ids = []
    return ids if !list
    list.each do |quest|
      ids << tef_batch_quest_symbol(quest)
    end
    return ids
  rescue
    return []
  end

  def tef_batch_quest_present?(list, quest_id)
    key = tef_batch_quest_key(quest_id)
    return false if !list
    list.any? { |quest| tef_batch_quest_key(quest) == key }
  rescue
    return false
  end

  def tef_batch_make_quest(quest_id, completed = false)
    quest = nil
    if defined?(Quest)
      begin
        quest = Quest.new(tef_batch_quest_symbol(quest_id), "", :WHITE)
      rescue
        begin
          quest = Quest.allocate
        rescue
          quest = nil
        end
      end
    end
    return tef_batch_quest_symbol(quest_id) if !quest
    quest.id = tef_batch_quest_symbol(quest_id) if quest.respond_to?(:id=)
    quest.name = tef_batch_quest_key(quest_id) if quest.respond_to?(:name=)
    quest.desc = "" if quest.respond_to?(:desc=)
    quest.npc = "" if quest.respond_to?(:npc=)
    quest.sprite = "" if quest.respond_to?(:sprite=)
    quest.location = "" if quest.respond_to?(:location=)
    begin
      quest.color = pbColor(:WHITE) if quest.respond_to?(:color=)
    rescue
      quest.color = :WHITE if quest.respond_to?(:color=)
    end
    quest.time = Time.now if quest.respond_to?(:time=)
    quest.completed = completed if quest.respond_to?(:completed=)
    return quest
  rescue
    return tef_batch_quest_symbol(quest_id)
  end

  def tef_batch_add_global_quest(quest_id, completed = false)
    quests = tef_batch_global_quest_collection
    return if !quests
    active = quests.active_quests if quests.respond_to?(:active_quests)
    complete = quests.completed_quests if quests.respond_to?(:completed_quests)
    key = tef_batch_quest_key(quest_id)
    active.delete_if { |quest| tef_batch_quest_key(quest) == key } if active
    complete.delete_if { |quest| tef_batch_quest_key(quest) == key } if complete
    target = completed ? complete : active
    target << tef_batch_make_quest(quest_id, completed) if target
  rescue
  end

  def activateQuest(quest_id, color = nil, silent = false, *_args)
    store = tef_batch_quest_store
    entry = tef_batch_quest_entry(store, quest_id)
    entry["active"] = true
    entry["complete"] = false
    entry["color"] = color.to_s if color
    tef_batch_add_global_quest(quest_id, false)
    return true
  rescue
    return true
  end if !method_defined?(:activateQuest)

  def completeQuest(quest_id, *_args)
    store = tef_batch_quest_store
    entry = tef_batch_quest_entry(store, quest_id)
    entry["active"] = false
    entry["complete"] = true
    tef_batch_add_global_quest(quest_id, true)
    return true
  rescue
    return true
  end if !method_defined?(:completeQuest)

  def advanceQuestToStage(quest_id, stage = 1, *_args)
    store = tef_batch_quest_store
    entry = tef_batch_quest_entry(store, quest_id)
    entry["active"] = true
    entry["complete"] = false
    entry["stage"] = stage.to_i
    tef_batch_add_global_quest(quest_id, false)
    return true
  rescue
    return true
  end if !method_defined?(:advanceQuestToStage)

  def getCurrentStage(quest_id)
    store = tef_batch_quest_store
    return (tef_batch_quest_entry(store, quest_id) || {})["stage"].to_i
  rescue
    return 0
  end if !method_defined?(:getCurrentStage)

  def getActiveQuests
    store = tef_batch_quest_store
    completed = {}
    active = []
    store.each do |quest_id, state|
      next if !state.is_a?(Hash)
      key = tef_batch_quest_key(quest_id)
      completed[key] = true if state["complete"]
      active << tef_batch_quest_symbol(quest_id) if state["active"] && !state["complete"]
    end
    quests = tef_batch_global_quest_collection
    active.concat(tef_batch_quest_id_list(quests.active_quests)) if quests && quests.respond_to?(:active_quests)
    if quests && quests.respond_to?(:completed_quests)
      tef_batch_quest_id_list(quests.completed_quests).each { |quest_id| completed[tef_batch_quest_key(quest_id)] = true }
    end
    return active.reject { |quest_id| completed[tef_batch_quest_key(quest_id)] }.uniq
  rescue
    return []
  end if !method_defined?(:getActiveQuests)

  def getCompletedQuests
    store = tef_batch_quest_store
    completed = []
    store.each do |quest_id, state|
      completed << tef_batch_quest_symbol(quest_id) if state.is_a?(Hash) && state["complete"]
    end
    quests = tef_batch_global_quest_collection
    completed.concat(tef_batch_quest_id_list(quests.completed_quests)) if quests && quests.respond_to?(:completed_quests)
    return completed.uniq
  rescue
    return []
  end if !method_defined?(:getCompletedQuests)

  def getFailedQuests
    quests = tef_batch_global_quest_collection
    return tef_batch_quest_id_list(quests.failed_quests).uniq if quests && quests.respond_to?(:failed_quests)
    return []
  rescue
    return []
  end if !method_defined?(:getFailedQuests)

  def completeTask(task_id, *_args)
    meta = tef_batch_metadata
    if meta
      meta["completed_tasks"] ||= {}
      meta["completed_tasks"][task_id.to_s] = true
    end
    return true
  rescue
    return true
  end if !method_defined?(:completeTask)

  def setLogro(category, value = true, *_args)
    meta = tef_batch_metadata
    if meta
      meta["achievements"] ||= {}
      meta["achievements"][category.to_s] = value
    end
    return value
  rescue
    return value
  end if !method_defined?(:setLogro)

  def getLogro(category)
    meta = tef_batch_metadata
    return 0 if !meta || !meta["achievements"].is_a?(Hash)
    return meta["achievements"][category.to_s] || 0
  rescue
    return 0
  end if !method_defined?(:getLogro)

  def passCheck(*_args)
    return false
  end if !method_defined?(:passCheck)

  def setVariable(value, variable_id = nil)
    pbSet(variable_id, value) if variable_id && respond_to?(:pbSet, true)
    return value
  rescue
    return value
  end if !method_defined?(:setVariable)

  def pbUnlockDiploma(*_args)
    return true
  end if !method_defined?(:pbUnlockDiploma)

  def pbUnlockShadowPokemonSeenList(*_args)
    return true
  end if !method_defined?(:pbUnlockShadowPokemonSeenList)

  def pbShowTipCardsGrouped(*_args)
    return true
  end if !method_defined?(:pbShowTipCardsGrouped)

  def pbTVScene(*_args)
    return true
  end if !method_defined?(:pbTVScene)

  def pbPokemonSpot(*_args)
    return true
  end if !method_defined?(:pbPokemonSpot)

  def pbCipherPeonNoticePlayer(event = nil, *args)
    return pbNoticePlayer(event, *args) if respond_to?(:pbNoticePlayer, true)
    return true
  rescue
    return true
  end if !method_defined?(:pbCipherPeonNoticePlayer)

  def pbStepOnSpot(*_args)
    return true
  end if !method_defined?(:pbStepOnSpot)

  def pbUpdateZoom(*_args)
    return true
  end if !method_defined?(:pbUpdateZoom)

  def move_to_location(map_id, x = 0, y = 0, fade = true, direction = 2)
    map_id = tef_batch_translate_map_id(map_id)
    return transfer_player(map_id, x, y, direction, fade) if respond_to?(:transfer_player, true)
    return pbTransferPlayer(map_id, x, y, direction) if respond_to?(:pbTransferPlayer, true)
    return false
  rescue
    return false
  end if !method_defined?(:move_to_location)

  def look_at_event(subject, target = nil)
    subject.turn_toward_character(target) if subject && target && subject.respond_to?(:turn_toward_character)
    return true
  rescue
    return true
  end if !method_defined?(:look_at_event)

  def hide_choice(*_args)
    return false
  end if !method_defined?(:hide_choice)

  def rename_choice(index, text = nil)
    return text || index
  end if !method_defined?(:rename_choice)

  def clUnlockCharacter(*_args)
    return true
  end if !method_defined?(:clUnlockCharacter)

  def pbAddDependency2(event_id, event_name = "Dependent", common_event = nil, *args)
    return pbAddDependency(event_id, event_name, common_event, *args) if respond_to?(:pbAddDependency, true)
    return true
  rescue
    return true
  end if !method_defined?(:pbAddDependency2)

  def pbRemoveDependency2(*_args)
    return true
  end if !method_defined?(:pbRemoveDependency2)

  def pbCameraShake(*_args)
    return true
  end if !method_defined?(:pbCameraShake)

  def pbCameraScrollTo(*_args)
    return true
  end if !method_defined?(:pbCameraScrollTo)

  def pbSwitchCharacter(event_id, character_name = nil, pattern = 0, *_args)
    event = get_character(event_id) if respond_to?(:get_character, true)
    if event && event.respond_to?(:character_name=) && character_name
      event.character_name = character_name.to_s
      event.pattern = pattern.to_i if event.respond_to?(:pattern=)
    end
    return true
  rescue
    return true
  end if !method_defined?(:pbSwitchCharacter)

  def pbPokemonMart2(stock, *args)
    return pbPokemonMart(stock, *args) if respond_to?(:pbPokemonMart, true)
    return true
  rescue
    return true
  end if !method_defined?(:pbPokemonMart2)

  def pbPokemonMart3(stock, *args)
    return pbPokemonMart(stock, *args) if respond_to?(:pbPokemonMart, true)
    return true
  rescue
    return true
  end if !method_defined?(:pbPokemonMart3)

  def setPrice(*_args)
    return true
  end if !method_defined?(:setPrice)

  def pbGainSocialLinkBond(*_args)
    return true
  end if !method_defined?(:pbGainSocialLinkBond)

  def pbAddSocialLink(*_args)
    return true
  end if !method_defined?(:pbAddSocialLink)

  def pbGetSocialLinkBond(*_args)
    return 0
  end if !method_defined?(:pbGetSocialLinkBond)

  def jess_fogs(*_args)
    return true
  end if !method_defined?(:jess_fogs)

  def lightsToggle(*_args)
    return true
  end if !method_defined?(:lightsToggle)

  def pbWheel(*_args)
    return 0
  end if !method_defined?(:pbWheel)

  def pbItemCrafter(*_args)
    return true
  end if !method_defined?(:pbItemCrafter)

  def createPokemon(species, level = 1, *_args)
    return Pokemon.new(species, level.to_i) if defined?(Pokemon)
    return nil
  rescue
    return nil
  end if !method_defined?(:createPokemon)

  def createTrainer(*_args)
    return nil
  end if !method_defined?(:createTrainer)

  def customTrainerBattle(*_args)
    return false
  end if !method_defined?(:customTrainerBattle)

  def pbBossFight(species, level = 1, form = 0, *_args)
    return pbWildBattle(species, level.to_i) if respond_to?(:pbWildBattle, true)
    return false
  rescue
    return false
  end if !method_defined?(:pbBossFight)

  def pbFollowingAnimation(*_args)
    return true
  end if !method_defined?(:pbFollowingAnimation)

  def pbRegisterPartner(*_args)
    return true
  end if !method_defined?(:pbRegisterPartner)
end
