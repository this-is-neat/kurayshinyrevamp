module TravelExpansionFramework
  module_function

  XENOVERSE_EXPANSION_ID = "xenoverse"
  XENOVERSE_AUTOTILE_FRAME_INTERVAL = 15
  XENOVERSE_SPECIES_ALIASES = {
    1021 => :CSF_XENOVERSE_SHYLEON,
    1022 => :CSF_XENOVERSE_TRISHOUT,
    1023 => :CSF_XENOVERSE_SHULONG,
    2009 => :CSF_XENOVERSE_SHYLEONP,
    2010 => :CSF_XENOVERSE_TRISHOUTP,
    2011 => :CSF_XENOVERSE_SHULONGP,
    :SHYLEON   => :CSF_XENOVERSE_SHYLEON,
    :TRISHOUT  => :CSF_XENOVERSE_TRISHOUT,
    :SHULONG   => :CSF_XENOVERSE_SHULONG,
    :SHYLEONP  => :CSF_XENOVERSE_SHYLEONP,
    :TRISHOUTP => :CSF_XENOVERSE_TRISHOUTP,
    :SHULONGP  => :CSF_XENOVERSE_SHULONGP
  } unless const_defined?(:XENOVERSE_SPECIES_ALIASES)

  def xenoverse_use_software_renderer?
    return false
  end

  def xenoverse_expansion_id?(expansion_id = nil)
    return expansion_id.to_s == XENOVERSE_EXPANSION_ID if !expansion_id.nil? && !expansion_id.to_s.empty?
    context_expansion = current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    return true if context_expansion.to_s == XENOVERSE_EXPANSION_ID
    map_id = integer(($game_map.map_id rescue 0), 0)
    if map_id > 0 && respond_to?(:current_map_expansion_id)
      map_expansion = current_map_expansion_id(map_id)
      if map_expansion.to_s.empty?
        clear_current_expansion if respond_to?(:clear_current_expansion)
        return false
      end
      return map_expansion.to_s == XENOVERSE_EXPANSION_ID
    end
    marker = current_expansion_marker if respond_to?(:current_expansion_marker)
    return marker.to_s == XENOVERSE_EXPANSION_ID
  rescue
    return false
  end

  def xenoverse_prefer_english?
    return true
  end

  def xenoverse_root_path
    info = external_projects[XENOVERSE_EXPANSION_ID]
    root = info[:root].to_s if info.is_a?(Hash)
    root = File.join("C:/Games", "Xenoverse") if root.to_s.empty?
    return nil if root.to_s.empty?
    return root
  rescue
    return nil
  end

  def xenoverse_species_alias_for(value)
    return nil if value.nil?
    return nil if defined?(Pokemon) && value.is_a?(Pokemon)
    return XENOVERSE_SPECIES_ALIASES[value] if XENOVERSE_SPECIES_ALIASES.has_key?(value)
    if value.is_a?(String)
      raw = value.strip
      return nil if raw.empty?
      numeric = Integer(raw) rescue nil
      return XENOVERSE_SPECIES_ALIASES[numeric] if numeric && XENOVERSE_SPECIES_ALIASES.has_key?(numeric)
      symbol = raw.upcase.gsub(/[^A-Z0-9_]+/, "_").to_sym
      return XENOVERSE_SPECIES_ALIASES[symbol]
    end
    if value.is_a?(Symbol)
      symbol = value.to_s.upcase.gsub(/[^A-Z0-9_]+/, "_").to_sym
      return XENOVERSE_SPECIES_ALIASES[symbol]
    end
    return nil
  rescue
    return nil
  end

  def xenoverse_resolve_species_reference(value)
    return value if value.nil?
    return value if defined?(Pokemon) && value.is_a?(Pokemon)
    canonical = nil
    if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:compatibility_alias_target)
      canonical = CustomSpeciesFramework.compatibility_alias_target(value) rescue nil
    end
    canonical ||= xenoverse_species_alias_for(value)
    return value if canonical.nil?
    data = GameData::Species.try_get(canonical) rescue nil
    return data.id if data
    return value
  rescue => e
    log("[xenoverse] species reference #{value.inspect} could not be resolved: #{e.class}: #{e.message}")
    return value
  end

  def xenoverse_translation_path
    root = xenoverse_root_path
    return nil if root.to_s.empty?
    path = File.join(root, "Data", "english.txt")
    return path if File.file?(path)
    return nil
  rescue
    return nil
  end

  def xenoverse_translation_data_path
    root = xenoverse_root_path
    return nil if root.to_s.empty?
    path = File.join(root, "Data", "english.dat")
    return path if File.file?(path)
    return nil
  rescue
    return nil
  end

  def xenoverse_translation_key(text)
    normalized = xenoverse_repair_text(text)
    normalized.gsub!("\r", "")
    normalized.gsub!("<<[>>", "[")
    normalized.gsub!("<<]>>", "]")
    normalized.gsub!(/\\n/, " ")
    normalized.gsub!(/<<[nN]>>/, " ")
    normalized.gsub!(/<<n>>/i, " ")
    normalized.gsub!("\n", " ")
    normalized.gsub!(/[ \t]+/, " ")
    normalized.gsub!("’", "'")
    normalized.gsub!("‘", "'")
    normalized.gsub!("“", "\"")
    normalized.gsub!("”", "\"")
    normalized.gsub!("’", "'")
    normalized.gsub!("â€™", "'")
    normalized.strip!
    return normalized
  end

  def xenoverse_repair_text(text)
    normalized = text.to_s.dup
    replacements = {
      "PokÃ©mon" => "Pokémon",
      "Ã¨" => "è",
      "Ã©" => "é",
      "Ã¬" => "ì",
      "Ã²" => "ò",
      "Ã¹" => "ù",
      "Ã€" => "À",
      "Ãˆ" => "È",
      "Ã‰" => "É",
      "ÃŒ" => "Ì",
      "Ã’" => "Ò",
      "Ã™" => "Ù",
      "â€™" => "'",
      "â€˜" => "'",
      "â€œ" => "\"",
      "â€" => "\"",
      "â€¦" => "...",
      "Ã—" => "x"
    }
    {
      "PokÃ©mon" => "Pokémon",
      "Ã¨" => "è",
      "Ã©" => "é",
      "Ã¬" => "ì",
      "Ã²" => "ò",
      "Ã¹" => "ù",
      "Ã€" => "À",
      "Ãˆ" => "È",
      "Ã‰" => "É",
      "ÃŒ" => "Ì",
      "Ã’" => "Ò",
      "Ã™" => "Ù",
      "Ã‡" => "Ç"
    }.each { |from, to| normalized.gsub!(from, to) }
    replacements.each { |from, to| normalized.gsub!(from, to) }
    return normalized
  rescue
    return text.to_s
  end

  def xenoverse_translation_key_variants(text)
    base = xenoverse_translation_key(text)
    return [] if base.to_s.empty?
    variants = [base]
    stripped_old = base.sub(/\A\[old\]/i, "")
    variants << stripped_old if !stripped_old.empty?
    variants << "[old]#{base}" if base !~ /\A\[old\]/i
    variants << "[old]#{stripped_old}" if !stripped_old.empty? && stripped_old !~ /\A\[old\]/i
    compacted = stripped_old.to_s.gsub(/\s+/, " ").strip
    variants << compacted if !compacted.empty?
    return variants.compact.map { |entry| entry.to_s.strip }.reject { |entry| entry.empty? }.uniq
  rescue
    value = xenoverse_translation_key(text).to_s
    return value.empty? ? [] : [value]
  end

  def xenoverse_safe_marshal_load(path)
    return nil if path.nil? || !File.file?(path)
    File.open(path, "rb") { |file| Marshal.load(file) }
  rescue => e
    log("[xenoverse] marshal load failed for #{path}: #{e.class}: #{e.message}")
    return nil
  end

  def xenoverse_collect_translation_pair_lists!(target, source_entries, translated_entries, scope = nil)
    return if !source_entries.respond_to?(:each_with_index) || !translated_entries.respond_to?(:[])
    source_entries.each_with_index do |source, index|
      translated = translated_entries[index]
      next if source.nil? || translated.nil?
      xenoverse_collect_translation_entries!(target, { source => translated }, scope)
    end
  rescue => e
    label = scope ? "map #{scope}" : "script"
    log("[xenoverse] translation pair import failed for #{label}: #{e.class}: #{e.message}")
  end

  def xenoverse_collect_translation_entries!(target, entries, scope = nil)
    if entries.is_a?(Array) &&
       entries.length >= 2 &&
       entries[0].respond_to?(:each_with_index) &&
       entries[1].respond_to?(:[])
      return xenoverse_collect_translation_pair_lists!(target, entries[0], entries[1], scope)
    end
    return if !entries.respond_to?(:each)
    scope_key = scope.to_i
    entries.each do |source, translated|
      source_keys = xenoverse_translation_key_variants(source)
      next if source_keys.empty?
      translated_text = xenoverse_decode_translation_markup(xenoverse_repair_text(translated))
      next if translated_text.to_s.empty?
      source_keys.each do |source_key|
        if scope
          target[:maps][scope_key] ||= {}
          target[:maps][scope_key][source_key] = translated_text
        else
          target[:script][source_key] = translated_text
        end
        target[:all][source_key] = translated_text if !target[:all].has_key?(source_key)
      end
    end
  rescue => e
    label = scope ? "map #{scope}" : "script"
    log("[xenoverse] translation import failed for #{label}: #{e.class}: #{e.message}")
  end

  def xenoverse_active_now?(map_id = nil)
    return true if xenoverse_expansion_id?
    target_map_id = integer(map_id, 0)
    if target_map_id <= 0 && defined?($game_map) && $game_map
      target_map_id = integer($game_map.map_id, 0)
    end
    if target_map_id > 0
      expansion = nil
      expansion = current_map_expansion_id(target_map_id) if respond_to?(:current_map_expansion_id)
      return true if expansion.to_s == XENOVERSE_EXPANSION_ID
      manifest = manifest_for_map_id(target_map_id) if respond_to?(:manifest_for_map_id)
      return true if manifest.is_a?(Hash) && manifest[:id].to_s == XENOVERSE_EXPANSION_ID
    end
    state = state_for(XENOVERSE_EXPANSION_ID)
    return true if state && state.respond_to?(:active) && state.active
    return false
  rescue
    return false
  end

  def xenoverse_battle_animation_active?
    map_id = integer(($game_map.map_id rescue 0), 0)
    map_expansion = current_map_expansion_id(map_id) if map_id > 0 && respond_to?(:current_map_expansion_id)
    if map_id > 0 && map_expansion.to_s.empty?
      clear_current_expansion if respond_to?(:clear_current_expansion)
      xenoverse_sync_runtime_language!(false) if respond_to?(:xenoverse_sync_runtime_language!)
      return false
    end
    return true if map_expansion.to_s == XENOVERSE_EXPANSION_ID
    context = current_runtime_context if respond_to?(:current_runtime_context)
    return true if context.is_a?(Hash) && context[:expansion_id].to_s == XENOVERSE_EXPANSION_ID
    return false
  rescue
    return false
  end

  def recover_disposed_battle_viewport!(label)
    log("[#{label}] battle animation recovered after disposed viewport") if respond_to?(:log)
    if $game_temp
      $game_temp.in_battle = false if $game_temp.respond_to?(:in_battle=)
      $game_temp.transition_processing = false if $game_temp.respond_to?(:transition_processing=)
    end
    if $scene.is_a?(Scene_Map)
      begin
        $scene.createSpritesets if $scene.respond_to?(:createSpritesets)
      rescue => restore_error
        log("[#{label}] spriteset restore after battle failed: #{restore_error.class}: #{restore_error.message}") if respond_to?(:log)
      end
    end
    if $game_map
      $game_map.autoplay rescue nil
      $game_map.refresh rescue nil
    end
    Input.update rescue nil
    Graphics.update rescue nil
    return nil
  end

  def xenoverse_translation_catalog
    @xenoverse_translation_catalog ||= begin
      catalog = {
        :loaded => true,
        :maps   => {},
        :all    => {},
        :script => {}
      }
      data_path = xenoverse_translation_data_path
      if data_path && File.file?(data_path)
        data = xenoverse_safe_marshal_load(data_path)
        if data.is_a?(Array)
          raw_maps = data[0]
          if raw_maps.respond_to?(:each_with_index)
            raw_maps.each_with_index do |entries, local_map_id|
              xenoverse_collect_translation_entries!(catalog, entries, local_map_id)
            end
          end
          xenoverse_collect_translation_entries!(catalog, data[22], nil)
        end
      end
      path = xenoverse_translation_path
      if path && File.file?(path)
        current_scope = nil
        pending = nil
        File.readlines(path).each do |line|
          text = line.to_s
          text.gsub!(/\r?\n\z/, "")
          if text[/\A\[Map(\d+)\]\z/i]
            current_scope = [:map, integer($1, 0)]
            pending = nil
            next
          elsif text[/\A\[(\d+)\]\z/i]
            current_scope = [:script, integer($1, 0)]
            pending = nil
            next
          end
          next if text.start_with?("#")
          if pending.nil?
            pending = text
            next
          end
          original = xenoverse_translation_key(pending)
          translated = xenoverse_decode_translation_markup(xenoverse_repair_text(text))
          if !original.empty? && !translated.to_s.empty?
            if current_scope && current_scope[0] == :map
              catalog[:maps][current_scope[1]] ||= {}
              catalog[:maps][current_scope[1]][original] = translated
            else
              catalog[:script][original] = translated if !catalog[:script].has_key?(original)
            end
            catalog[:all][original] = translated if !catalog[:all].has_key?(original)
          end
          pending = nil
        end
      end
      catalog
    end
    return @xenoverse_translation_catalog
  rescue => e
    log("[xenoverse] translation catalog load failed: #{e.class}: #{e.message}")
    @xenoverse_translation_catalog = {
      :loaded => true,
      :maps   => {},
      :all    => {}
    }
    return @xenoverse_translation_catalog
  end

  def xenoverse_current_local_map_id(map_id = nil)
    current_map_id = map_id
    current_map_id = $game_map.map_id if current_map_id.nil? && $game_map
    current_map_id = integer(current_map_id, 0)
    return 0 if current_map_id <= 0
    return local_map_id_for(XENOVERSE_EXPANSION_ID, current_map_id) if respond_to?(:local_map_id_for)
    return current_map_id
  rescue
    return 0
  end

  def xenoverse_decode_translation_markup(text)
    decoded = xenoverse_repair_text(text)
    decoded.gsub!("<<[>>", "[")
    decoded.gsub!("<<]>>", "]")
    decoded.gsub!("<<n>>", "\n")
    decoded.gsub!("<<N>>", "\n")
    decoded
  end

  def xenoverse_translate_text(text, map_id = nil)
    source = xenoverse_repair_text(text)
    return source if source.empty? || !xenoverse_prefer_english?
    keys = xenoverse_translation_key_variants(source)
    return source if keys.empty?
    catalog = xenoverse_translation_catalog
    local_map_id = xenoverse_current_local_map_id(map_id)
    translated = nil
    if catalog[:maps].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:maps][local_map_id][key] if translated.nil? && catalog[:maps][local_map_id].is_a?(Hash)
        translated = catalog[:maps][0][key] if translated.nil? && catalog[:maps][0].is_a?(Hash)
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
    return source if translated.nil? || translated.to_s.empty?
    return xenoverse_decode_translation_markup(xenoverse_repair_text(translated))
  rescue => e
    log("[xenoverse] translation lookup failed: #{e.class}: #{e.message}")
    return source
  end

  def xenoverse_translate_script_text(text, map_id = nil)
    source = xenoverse_repair_text(text)
    return source if source.empty? || !xenoverse_prefer_english?
    keys = xenoverse_translation_key_variants(source)
    return source if keys.empty?
    catalog = xenoverse_translation_catalog
    if catalog[:script].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:script][key]
        break if translated
      end
    end
    translated = xenoverse_translate_text(source, map_id) if translated.nil? || translated.to_s.empty?
    return source if translated.nil? || translated.to_s.empty?
    return xenoverse_decode_translation_markup(xenoverse_repair_text(translated))
  rescue => e
    log("[xenoverse] script translation lookup failed: #{e.class}: #{e.message}")
    return source
  end

  def xenoverse_format_text(template, values)
    result = template.to_s.dup
    Array(values).each_with_index do |value, index|
      result.gsub!(/\{#{index + 1}\}/, value.to_s)
    end
    return result
  rescue
    return template.to_s
  end

  def xenoverse_deep_clone(value)
    return nil if value.nil?
    return Marshal.load(Marshal.dump(value))
  rescue
    if value.is_a?(Array)
      return value.map { |entry| xenoverse_deep_clone(entry) }
    end
    if value.is_a?(Hash)
      cloned = {}
      value.each { |key, entry| cloned[xenoverse_deep_clone(key)] = xenoverse_deep_clone(entry) }
      return cloned
    end
    begin
      return value.clone
    rescue
      return value
    end
  end

  def xenoverse_session_metadata
    state = state_for(XENOVERSE_EXPANSION_ID)
    return {} if !state || !state.respond_to?(:metadata)
    state.metadata ||= {}
    state.metadata["xenoverse_session"] ||= {}
    return state.metadata["xenoverse_session"]
  end

  class XenoverseAchievementShim
    attr_accessor :name
    attr_accessor :title
    attr_accessor :description
    attr_accessor :image
    attr_accessor :amount
    attr_reader   :progress
    attr_accessor :hidden
    attr_accessor :locked
    attr_accessor :callback
    attr_accessor :disabled

    def initialize(name, data = nil)
      @name        = name.to_s
      @title       = @name
      @description = ""
      @image       = "Graphics/Achievements/default.png"
      @amount      = 1
      @progress    = 0
      @hidden      = true
      @locked      = false
      @callback    = nil
      @disabled    = false
      assign_export(data) if data.is_a?(Hash)
    end

    def each
      yield "name", @name
      yield "title", @title
      yield "description", @description
      yield "image", @image
      yield "amount", @amount
      yield "progress", @progress
      yield "hidden", @hidden
      yield "locked", @locked
      yield "callback", @callback
      yield "disabled", @disabled
    end

    def silentProgress(value, _mute = false)
      @progress = [TravelExpansionFramework.integer(value, 0), 0].max
      @hidden = false if @progress > 0
      TravelExpansionFramework.xenoverse_sync_achievement_record!(self)
      return @progress
    end

    def progress=(value)
      delta = TravelExpansionFramework.integer(value, 0)
      if delta < 0
        @progress = 0
      else
        @progress += delta
      end
      @hidden = false if @progress > 0
      TravelExpansionFramework.xenoverse_sync_achievement_record!(self)
      return @progress
    end

    def completed
      return @progress >= TravelExpansionFramework.integer(@amount, 1)
    end

    def completed?
      return completed
    end

    def assign(key, value)
      case key.to_s
      when "title"
        @title = value.to_s
      when "description"
        @description = value.to_s
      when "image"
        image_name = value.to_s
        @image = image_name[/\AGraphics\//i] ? image_name : "Graphics/Achievements/#{image_name}.png"
      when "amount"
        @amount = [TravelExpansionFramework.integer(value, 1), 1].max
      when "progress"
        @progress = [TravelExpansionFramework.integer(value, 0), 0].max
      when "hidden"
        @hidden = tef_truthy?(value, true)
      when "locked"
        @locked = tef_truthy?(value, false)
      when "disabled"
        @disabled = tef_truthy?(value, false)
      when "callback"
        @callback = nil
      end
      TravelExpansionFramework.xenoverse_sync_achievement_record!(self)
      return value
    end

    def [](key)
      case key.to_s
      when "name"        then return @name
      when "title"       then return @title
      when "description" then return @description
      when "image"       then return @image
      when "amount"      then return @amount
      when "progress"    then return @progress
      when "hidden"      then return @hidden
      when "locked"      then return @locked
      when "callback"    then return @callback
      when "disabled"    then return @disabled
      end
      return nil
    end

    def []=(key, value)
      return assign(key, value)
    end

    def export
      return {
        "title"       => @title,
        "description" => @description,
        "image"       => @image,
        "amount"      => @amount,
        "progress"    => @progress,
        "hidden"      => @hidden,
        "locked"      => @locked,
        "disabled"    => @disabled
      }
    end

    def assign_export(data)
      data.each { |key, value| assign(key, value) }
    end

    private

    def tef_truthy?(value, default = false)
      return value if value == true || value == false
      text = value.to_s.strip.downcase
      return true if ["1", "true", "yes", "on"].include?(text)
      return false if ["0", "false", "no", "off"].include?(text)
      return default
    end
  end

  class XenoverseAchievementsHash < Hash
    def [](key)
      normalized = key.to_s
      self[normalized] = TravelExpansionFramework.xenoverse_build_achievement_record(normalized) if !has_key?(normalized)
      return super(normalized)
    end

    def []=(key, value)
      normalized = key.to_s
      record = value
      if value.is_a?(Hash)
        record = TravelExpansionFramework.xenoverse_build_achievement_record(normalized, value)
      elsif !value.respond_to?(:progress) || !value.respond_to?(:name)
        record = TravelExpansionFramework.xenoverse_build_achievement_record(normalized)
      end
      TravelExpansionFramework.xenoverse_sync_achievement_record!(record)
      return super(normalized, record)
    end
  end

  def xenoverse_achievement_store
    state = state_for(XENOVERSE_EXPANSION_ID)
    if state && state.respond_to?(:metadata)
      state.metadata = {} if !state.metadata.is_a?(Hash) && state.respond_to?(:metadata=)
      if state.metadata.is_a?(Hash)
        state.metadata["xenoverse_achievements"] ||= {}
        return state.metadata["xenoverse_achievements"]
      end
    end
    @xenoverse_in_memory_achievement_store ||= {}
    return @xenoverse_in_memory_achievement_store
  rescue
    @xenoverse_in_memory_achievement_store ||= {}
    return @xenoverse_in_memory_achievement_store
  end

  def xenoverse_build_achievement_record(name, data = nil)
    key = name.to_s
    payload = data
    payload = xenoverse_achievement_store[key] if payload.nil?
    record = XenoverseAchievementShim.new(key, payload.is_a?(Hash) ? payload : nil)
    return record
  end

  def xenoverse_sync_achievement_record!(record)
    return nil if record.nil?
    key = record.respond_to?(:name) ? record.name.to_s : ""
    return nil if key.empty?
    payload = if record.respond_to?(:export)
                record.export
              else
                {
                  "progress" => (record.progress rescue 0),
                  "hidden"   => (record.hidden rescue true),
                  "locked"   => (record.locked rescue false)
                }
              end
    xenoverse_achievement_store[key] = payload
    return payload
  rescue => e
    log("[xenoverse] achievement sync failed: #{e.class}: #{e.message}")
    return nil
  end

  def xenoverse_flush_achievements!
    return false if !$achievements || !$achievements.respond_to?(:each)
    $achievements.each { |_key, record| xenoverse_sync_achievement_record!(record) }
    return true
  rescue => e
    log("[xenoverse] achievement flush failed: #{e.class}: #{e.message}")
    return false
  end

  def xenoverse_ensure_achievements!
    store = xenoverse_achievement_store
    if !$achievements.is_a?(XenoverseAchievementsHash)
      @xenoverse_host_achievements = $achievements if !@xenoverse_achievements_active
      bridge = XenoverseAchievementsHash.new
      if $achievements.respond_to?(:each)
        $achievements.each { |key, value| bridge[key] = value }
      end
      store.each { |key, data| bridge[key] = data if !bridge.has_key?(key.to_s) }
      $achievements = bridge
      log("[xenoverse] achievement bridge initialized records=#{$achievements.length}")
    else
      store.each { |key, data| $achievements[key] = data if !$achievements.has_key?(key.to_s) }
    end
    $orderedAchievements = $achievements.keys.sort if !defined?($orderedAchievements) || $orderedAchievements.nil?
    @xenoverse_achievements_active = true
    return $achievements
  rescue => e
    log("[xenoverse] achievement bridge failed: #{e.class}: #{e.message}")
    $achievements = XenoverseAchievementsHash.new if !$achievements.respond_to?(:[])
    return $achievements
  end

  def xenoverse_restore_achievements!
    xenoverse_flush_achievements!
    return false if !@xenoverse_achievements_active
    $achievements = @xenoverse_host_achievements
    @xenoverse_host_achievements = nil
    @xenoverse_achievements_active = false
    return true
  rescue => e
    log("[xenoverse] achievement restore failed: #{e.class}: #{e.message}")
    return false
  end

  def xenoverse_sync_runtime_language!(active = xenoverse_active_now?)
    return nil if !$PokemonSystem || !$PokemonSystem.respond_to?(:language)
    session = xenoverse_session_metadata
    if active
      session["host_language"] = integer($PokemonSystem.language, 0) if !session.has_key?("host_language")
      $PokemonSystem.language = 1 if integer($PokemonSystem.language, 0) != 1
    elsif session.has_key?("host_language")
      $PokemonSystem.language = integer(session["host_language"], 0)
      session.delete("host_language")
    end
    return $PokemonSystem.language
  rescue => e
    log("[xenoverse] language sync failed: #{e.class}: #{e.message}")
    return nil
  end

  def xenoverse_prepare_session_for_entry!(mode = "shared")
    return false if !$Trainer
    session = xenoverse_session_metadata
    if $Trainer.respond_to?(:npcPartner)
      session["host_npc_partner"] = xenoverse_deep_clone($Trainer.npcPartner) if !session["active"]
    end
    if $PokemonGlobal && $PokemonGlobal.respond_to?(:partner)
      session["host_global_partner"] = xenoverse_deep_clone($PokemonGlobal.partner) if !session["active"]
    end
    session["mode"] = mode.to_s
    session["active"] = true
    $Trainer.npcPartner = nil if $Trainer.respond_to?(:npcPartner=)
    $PokemonGlobal.partner = nil if $PokemonGlobal && $PokemonGlobal.respond_to?(:partner=)
    xenoverse_sync_runtime_language!(true)
    xenoverse_apply_host_player_visuals!
    xenoverse_ensure_achievements!
    log("[xenoverse] session prepared mode=#{session["mode"]} host_party_preserved=#{Array($Trainer.party).length}")
    return true
  rescue => e
    log("[xenoverse] session prepare failed: #{e.class}: #{e.message}")
    return false
  end

  def xenoverse_commit_current_session_party!
    return xenoverse_deep_clone($Trainer.party) if $Trainer
    return nil
  rescue
    return nil
  end

  def xenoverse_restore_host_session!
    return false if !$Trainer
    session = xenoverse_session_metadata
    return false if !session["active"]
    if $Trainer.respond_to?(:npcPartner=)
      $Trainer.npcPartner = xenoverse_deep_clone(session["host_npc_partner"])
    end
    if $PokemonGlobal && $PokemonGlobal.respond_to?(:partner=)
      $PokemonGlobal.partner = xenoverse_deep_clone(session["host_global_partner"])
    end
    session.delete("host_npc_partner")
    session.delete("host_global_partner")
    session["active"] = false
    xenoverse_sync_runtime_language!(false)
    xenoverse_apply_host_player_visuals!
    xenoverse_restore_achievements!
    log("[xenoverse] session restored host_party_preserved=#{Array($Trainer.party).length}")
    return true
  rescue => e
    log("[xenoverse] session restore failed: #{e.class}: #{e.message}")
    return false
  end

  def xenoverse_handle_boundary(previous_expansion, current_expansion)
    previous_id = previous_expansion.to_s
    current_id = current_expansion.to_s
    if current_id == XENOVERSE_EXPANSION_ID
      xenoverse_sync_runtime_language!(true)
      xenoverse_apply_host_player_visuals!
      xenoverse_ensure_achievements!
    elsif previous_id == XENOVERSE_EXPANSION_ID && current_id != XENOVERSE_EXPANSION_ID
      xenoverse_restore_host_session!
    else
      xenoverse_sync_runtime_language!(false)
    end
  rescue => e
    log("[xenoverse] boundary handling failed: #{e.class}: #{e.message}")
  end

  def xenoverse_imported_trainer_type_data(symbol_or_id)
    data = imported_trainer_type_data(symbol_or_id) if respond_to?(:imported_trainer_type_data)
    return data if data.is_a?(Hash)
    resolved = resolve_pb_trainers_constant_value(symbol_or_id) if respond_to?(:resolve_pb_trainers_constant_value)
    if !resolved.nil? && resolved != symbol_or_id
      data = imported_trainer_type_data(resolved) if respond_to?(:imported_trainer_type_data)
      return data if data.is_a?(Hash)
    end
    return nil
  rescue => e
    log("[xenoverse] trainer type lookup failed for #{symbol_or_id.inspect}: #{e.class}: #{e.message}")
    return nil
  end

  def xenoverse_play_trainer_intro(symbol_or_id)
    data = xenoverse_imported_trainer_type_data(symbol_or_id)
    if data.is_a?(Hash)
      audio_name = normalize_string_or_nil(data[:intro_BGM] || data[:intro_ME] || data[:battle_BGM])
      if audio_name
        pbMEPlay(pbStringToAudioFile(audio_name))
        return true
      end
    end
    resolved = resolve_pb_trainers_constant_value(symbol_or_id) if respond_to?(:resolve_pb_trainers_constant_value)
    if !resolved.nil?
      trainer_type_data = GameData::TrainerType.try_get(resolved) if defined?(GameData::TrainerType)
      if trainer_type_data && !nil_or_empty?(trainer_type_data.intro_ME)
        pbMEPlay(pbStringToAudioFile(trainer_type_data.intro_ME))
        return true
      end
    end
    return false
  rescue => e
    log("[xenoverse] trainer intro ME failed for #{symbol_or_id.inspect}: #{e.class}: #{e.message}")
    return false
  end

  def xenoverse_trainer_battle_bgm_from_type(symbol_or_id)
    data = xenoverse_imported_trainer_type_data(symbol_or_id)
    return nil if !data.is_a?(Hash)
    audio_name = normalize_string_or_nil(data[:battle_BGM])
    return nil if audio_name.nil?
    return pbStringToAudioFile(audio_name)
  rescue => e
    log("[xenoverse] trainer battle BGM lookup failed for #{symbol_or_id.inspect}: #{e.class}: #{e.message}")
    return nil
  end

  def xenoverse_fullbox_state
    @xenoverse_fullbox_state ||= {
      :positions              => {},
      :active_position        => nil,
      :dispose_after_message  => false
    }
    return @xenoverse_fullbox_state
  end

  def reset_xenoverse_fullbox_state
    state = xenoverse_fullbox_state
    state[:positions] = {}
    state[:active_position] = nil
    state[:dispose_after_message] = false
  end

  def xenoverse_truthy?(value)
    return value if value == true || value == false
    normalized = value.to_s.strip.downcase
    return ["1", "true", "yes", "on"].include?(normalized)
  end

  def xenoverse_player_female?
    return false if !$Trainer
    return $Trainer.female? if $Trainer.respond_to?(:female?)
    return $Trainer.isFemale? if $Trainer.respond_to?(:isFemale?)
    return false
  rescue
    return false
  end

  def xenoverse_primary_dependent_event(dependent_events = nil)
    dependent_events ||= ($PokemonTemp.dependentEvents rescue nil)
    return nil if dependent_events.nil?
    if dependent_events.respond_to?(:getEventByName)
      event = dependent_events.getEventByName("Dependent") rescue nil
      return event if event
    end
    if dependent_events.respond_to?(:eachEvent)
      dependent_events.eachEvent do |event, data|
        next if event.nil? || !data.is_a?(Array)
        return event if data[8].to_s == "Dependent"
      end
    end
    if dependent_events.respond_to?(:realEvents)
      events = dependent_events.realEvents
      return events[0] if events.is_a?(Array) && events[0]
    end
    return nil
  rescue => e
    log("[xenoverse] dependent event lookup failed: #{e.class}: #{e.message}")
    return nil
  end

  def xenoverse_apply_host_player_visuals!
    return false if !$game_player
    $game_player.removeGraphicsOverride if $game_player.respond_to?(:removeGraphicsOverride)
    $game_player.instance_variable_set(:@defaultCharacterName, "")
    $game_player.instance_variable_set(:@character_name, nil)
    $game_player.charsetData = nil if $game_player.respond_to?(:charsetData=)
    if defined?(GameData::Metadata) && $Trainer
      meta = GameData::Metadata.get_player($Trainer.character_ID) rescue nil
      host_char_name = pbGetPlayerCharset(meta, 1, $Trainer, true) if meta && defined?(pbGetPlayerCharset)
      if host_char_name && !host_char_name.to_s.empty?
        $game_player.character_name = host_char_name if $game_player.respond_to?(:character_name=)
        $game_player.instance_variable_set(:@character_name, host_char_name)
      end
    end
    pbUpdateVehicle if defined?(pbUpdateVehicle)
    $game_player.calculate_bush_depth if $game_player.respond_to?(:calculate_bush_depth)
    $game_player.refresh if $game_player.respond_to?(:refresh)
    $game_player.straighten if $game_player.respond_to?(:straighten)
    return true
  rescue => e
    log("[xenoverse] player visual reset failed: #{e.class}: #{e.message}")
    return false
  end

  def xenoverse_normalize_position(value)
    normalized = value.to_s.strip.downcase
    normalized = "centre" if normalized == "center"
    return normalized.to_sym if %w[left right centre out_left out_right].include?(normalized)
    return :left
  end

  def xenoverse_position_state(position)
    normalized = xenoverse_normalize_position(position)
    state = xenoverse_fullbox_state
    state[:positions][normalized] ||= {}
    return state[:positions][normalized]
  end

  def xenoverse_set_speaker(position, name = nil, asset = nil, pose = nil, active = nil)
    slot = xenoverse_position_state(position)
    slot[:name] = name.to_s if !name.nil? && !name.to_s.empty?
    slot[:asset] = asset.to_s if !asset.nil? && !asset.to_s.empty?
    slot[:pose] = pose.to_s if !pose.nil? && !pose.to_s.empty?
    normalized_position = xenoverse_normalize_position(position)
    if active.nil?
      state = xenoverse_fullbox_state
      state[:active_position] = normalized_position if state[:active_position].nil?
    elsif xenoverse_truthy?(active)
      xenoverse_fullbox_state[:active_position] = normalized_position
    end
  end

  def xenoverse_delete_speaker(position = nil)
    if position.nil?
      reset_xenoverse_fullbox_state
      return
    end
    normalized_position = xenoverse_normalize_position(position)
    state = xenoverse_fullbox_state
    state[:positions].delete(normalized_position)
    state[:active_position] = nil if state[:active_position] == normalized_position
  end

  def xenoverse_active_speaker_name
    state = xenoverse_fullbox_state
    if state[:active_position]
      entry = state[:positions][state[:active_position]]
      return entry[:name].to_s if entry && !entry[:name].to_s.empty?
    end
    state[:positions].each_value do |entry|
      next if !entry || entry[:name].to_s.empty?
      return entry[:name].to_s
    end
    return ""
  end

  def xenoverse_variable_value(token)
    key = token.to_s.strip
    return "" if key.empty?
    case key.downcase
    when "pl"
      return $Trainer ? $Trainer.name.to_s : ""
    when "pm"
      return ($Trainer && $Trainer.respond_to?(:money)) ? _INTL("${1}", $Trainer.money.to_s_formatted) : ""
    end
    return $game_variables[key.to_i].to_s if key[/\A\d+\z/]
    return ""
  rescue
    return ""
  end

  def xenoverse_replace_variables(text)
    result = text.to_s.gsub(/@([A-Za-z0-9_]+)\|?/) do
      replacement = xenoverse_variable_value($1)
      replacement = "@#{$1}" if replacement.to_s.empty?
      replacement
    end
    return result
  end

  def xenoverse_apply_gender_markup(text)
    source = text.to_s
    female = xenoverse_player_female?
    buffer = +""
    index = 0
    while index < source.length
      char = source[index, 1]
      if char == "|"
        count = 1
        while source[index + count, 1] == "|"
          count += 1
        end
        replacement = source[(index + count), count].to_s
        if female && buffer.length >= count && replacement.length == count
          buffer = buffer[0, buffer.length - count] + replacement
        end
        index += count * 2
        next
      end
      buffer << char
      index += 1
    end
    return buffer
  end

  def xenoverse_handle_inline_command(command_text, map_id = nil)
    parts = command_text.to_s.split(",").map { |entry| entry.to_s.strip }
    return "" if parts.empty?
    command = parts.shift.to_s.downcase
    state = xenoverse_fullbox_state
    case command
    when "new"
      translated_name = xenoverse_translate_text(parts[0].to_s, map_id)
      xenoverse_set_speaker(parts[3], translated_name, parts[1], parts[2], parts[4])
    when "mug"
      xenoverse_set_speaker(parts[0], nil, parts[1], parts[2], nil)
    when "act", "speak"
      state[:active_position] = xenoverse_normalize_position(parts[0])
    when "actall"
      if state[:active_position].nil?
        first_position = state[:positions].keys.first
        state[:active_position] = first_position if first_position
      end
    when "del"
      xenoverse_delete_speaker(parts[0])
    when "enable"
      state[:active_position] ||= xenoverse_normalize_position(parts[1] || :left) if xenoverse_truthy?(parts[0])
    when "dispose"
      state[:dispose_after_message] = true
    end
    return ""
  rescue
    return ""
  end

  def xenoverse_rewrite_inline_commands(text, map_id = nil, handle_commands = true)
    source = text.to_s
    buffer = +""
    index = 0
    while index < source.length
      char = source[index, 1]
      if char == "["
        closing_index = source.index("]", index + 1)
        if closing_index && !source[0, index].to_s.match?(/\\[A-Za-z]+\z/)
          command_text = source[(index + 1)...closing_index].to_s
          buffer << (handle_commands ? xenoverse_handle_inline_command(command_text, map_id).to_s : "")
          index = closing_index + 1
          next
        end
      end
      buffer << char
      index += 1
    end
    return buffer
  rescue
    return text.to_s
  end

  def xenoverse_choice_text(message, map_id = nil)
    text = xenoverse_translate_text(message.to_s, map_id)
    text = xenoverse_decode_translation_markup(text)
    text = xenoverse_replace_variables(text)
    text = xenoverse_apply_gender_markup(text)
    text = xenoverse_rewrite_inline_commands(text, map_id, false)
    text.gsub!(/<[^>]+>/, "")
    text.gsub!(/[ \t]+\n/, "\n")
    text.gsub!(/\n[ \t]+/, "\n")
    text.gsub!(/[ \t]{2,}/, " ")
    text.strip!
    return text
  rescue
    return message.to_s
  end

  def xenoverse_plain_text(message, map_id = nil)
    state = xenoverse_fullbox_state
    state[:dispose_after_message] = false
    text = message.to_s.dup
    text.gsub!(/\r/, "")
    text.sub!(/\A\[old\]/i, "")
    text = xenoverse_translate_text(text, map_id)
    text = xenoverse_decode_translation_markup(text)
    text = xenoverse_rewrite_inline_commands(text, map_id, true)
    text = xenoverse_replace_variables(text)
    text = xenoverse_apply_gender_markup(text)
    text.sub!(/\A\[old\]/i, "")
    text.gsub!(/<[^>]+>/, "")
    text.gsub!(/[ \t]+\n/, "\n")
    text.gsub!(/\n[ \t]+/, "\n")
    text.gsub!(/[ \t]{2,}/, " ")
    text.strip!
    speaker = xenoverse_active_speaker_name
    if !speaker.empty? && !text.empty? && text !~ /\A#{Regexp.escape(speaker)}\s*:/
      text = "#{speaker}: #{text}"
    end
    reset_xenoverse_fullbox_state if state[:dispose_after_message]
    return text
  rescue => e
    log("[xenoverse] dialogue parse failed: #{e.class}: #{e.message}")
    return message.to_s
  end

  def xenoverse_battle_display_text(message, map_id = nil)
    return message if message.nil?
    return xenoverse_plain_text(message.to_s, map_id)
  rescue => e
    log("[xenoverse] battle text translation failed: #{e.class}: #{e.message}")
    return message.to_s
  end

  module XenoverseRenderer
    class Adapter
      attr_accessor :tone
      attr_accessor :color
      attr_accessor :ox
      attr_accessor :oy
      attr_accessor :visible
      attr_reader :viewport

      def initialize(viewport)
        @viewport = viewport
        @base_sprite = Sprite.new(@viewport)
        @base_sprite.visible = true
        @base_sprite.z = 0
        @base_sprite.bitmap = Bitmap.new(Graphics.width + tile_width, Graphics.height + tile_height)
        @priority_sprites = []
        @priority_cache = {}
        @helper = nil
        @tileset_bitmap = nil
        @autotile_bitmaps = []
        @current_map_id = nil
        @last_origin = nil
        @last_anim_bucket = nil
        @tone = Tone.new(0, 0, 0, 0)
        @color = Color.new(0, 0, 0, 0)
        @ox = 0
        @oy = 0
        @visible = true
        @disposed = false
        @needs_refresh = true
      end

      def disposed?
        return @disposed
      end

      def dispose
        return if disposed?
        @priority_cache.each_value { |bitmap| bitmap.dispose if bitmap && !bitmap.disposed? }
        @priority_cache.clear
        @priority_sprites.each { |sprite| sprite.dispose if sprite && !sprite.disposed? }
        @priority_sprites.clear
        @helper.dispose if @helper && @helper.respond_to?(:dispose)
        @helper = nil
        @base_sprite.bitmap.dispose if @base_sprite && @base_sprite.bitmap && !@base_sprite.bitmap.disposed?
        @base_sprite.dispose if @base_sprite && !@base_sprite.disposed?
        @base_sprite = nil
        @tileset_bitmap = nil
        @autotile_bitmaps.clear
        @disposed = true
      end

      def add_tileset(_filename)
        @needs_refresh = true
      end

      def remove_tileset(_filename)
        @needs_refresh = true
      end

      def add_autotile(_filename)
        @needs_refresh = true
      end

      def remove_autotile(_filename)
        @needs_refresh = true
      end

      def add_extra_autotiles(_tileset_id, _map_id)
        @needs_refresh = true
      end

      def remove_extra_autotiles(_tileset_id)
        @needs_refresh = true
      end

      def refresh
        @needs_refresh = true
      end

      def update
        return if disposed?
        map = $game_map
        if !map || !TravelExpansionFramework.xenoverse_expansion_id?(TravelExpansionFramework.current_map_expansion_id(map.map_id))
          @base_sprite.visible = false if @base_sprite
          @priority_sprites.each { |sprite| sprite.visible = false if sprite && !sprite.disposed? }
          return
        end
        rebuild_for_map(map) if @current_map_id != map.map_id || @helper.nil?
        origin = [pixel_origin_x(map), pixel_origin_y(map)]
        anim_bucket = Graphics.frame_count / TravelExpansionFramework::XENOVERSE_AUTOTILE_FRAME_INTERVAL
        if @needs_refresh || @last_origin != origin || @last_anim_bucket != anim_bucket
          redraw_current_map(map)
          @last_origin = origin
          @last_anim_bucket = anim_bucket
          @needs_refresh = false
        end
        apply_visual_state
      end

      private

      def tile_width
        return (TilemapRenderer::DISPLAY_TILE_WIDTH rescue 32)
      end

      def tile_height
        return (TilemapRenderer::DISPLAY_TILE_HEIGHT rescue 32)
      end

      def pixel_origin_x(map)
        divisor = (Game_Map::X_SUBPIXELS rescue 4)
        return (map.display_x.to_f / divisor).round
      end

      def pixel_origin_y(map)
        divisor = (Game_Map::Y_SUBPIXELS rescue 4)
        return (map.display_y.to_f / divisor).round
      end

      def rebuild_for_map(map)
        @helper.dispose if @helper && @helper.respond_to?(:dispose)
        @helper = nil
        @priority_cache.each_value { |bitmap| bitmap.dispose if bitmap && !bitmap.disposed? }
        @priority_cache.clear
        expansion_id = TravelExpansionFramework.current_map_expansion_id(map.map_id)
        TravelExpansionFramework.with_rendering_expansion(expansion_id) do
          @tileset_bitmap = pbGetTileset(map.tileset_name)
          @autotile_bitmaps = []
          7.times do |index|
            @autotile_bitmaps[index] = pbGetAutotile(map.autotile_names[index])
          end
        end
        @helper = TileDrawingHelper.new(@tileset_bitmap, @autotile_bitmaps)
        @current_map_id = map.map_id
        @last_origin = nil
        @last_anim_bucket = nil
        @needs_refresh = true
        TravelExpansionFramework.log("[xenoverse] software renderer active for map #{@current_map_id} (#{map.tileset_name})")
      end

      def apply_visual_state
        return if !@base_sprite || @base_sprite.disposed?
        @base_sprite.visible = @visible
        @base_sprite.tone = @tone
        @base_sprite.color = @color
        @priority_sprites.each do |sprite|
          next if !sprite || sprite.disposed?
          sprite.visible = @visible && !!sprite.instance_variable_get(:@tef_active)
          sprite.tone = @tone
          sprite.color = @color
        end
      end

      def ensure_priority_sprite(index)
        @priority_sprites[index] ||= Sprite.new(@viewport)
        return @priority_sprites[index]
      end

      def priority_tile_bitmap(tile_id, frame)
        cache_key = [tile_id, frame]
        return @priority_cache[cache_key] if @priority_cache[cache_key]
        bitmap = Bitmap.new(tile_width, tile_height)
        @helper.bltSmallTile(bitmap, 0, 0, tile_width, tile_height, tile_id, frame)
        @priority_cache[cache_key] = bitmap
        return bitmap
      end

      def autotile_frame(tile_id)
        return 0 if tile_id <= 0 || tile_id >= 384
        autotile = @autotile_bitmaps[(tile_id / 48) - 1]
        return 0 if !autotile || autotile.disposed?
        frames = if autotile.height == 32
                   [autotile.width / 32, 1].max
                 else
                   [autotile.width / 96, 1].max
                 end
        return 0 if frames <= 1
        return (Graphics.frame_count / TravelExpansionFramework::XENOVERSE_AUTOTILE_FRAME_INTERVAL) % frames
      end

      def redraw_current_map(map)
        bitmap = @base_sprite.bitmap
        return if !bitmap || bitmap.disposed? || !@helper
        bitmap.clear
        origin_x = pixel_origin_x(map)
        origin_y = pixel_origin_y(map)
        start_x = origin_x / tile_width
        start_y = origin_y / tile_height
        offset_x = origin_x % tile_width
        offset_y = origin_y % tile_height
        visible_width = (Graphics.width / tile_width) + 2
        visible_height = (Graphics.height / tile_height) + 2
        priority_count = 0
        visible_height.times do |vy|
          map_y = start_y + vy
          next if map_y < 0 || map_y >= map.height
          screen_y = (vy * tile_height) - offset_y
          visible_width.times do |vx|
            map_x = start_x + vx
            next if map_x < 0 || map_x >= map.width
            screen_x = (vx * tile_width) - offset_x
            3.times do |layer|
              tile_id = map.data[map_x, map_y, layer]
              next if !tile_id || tile_id.to_i <= 0
              tile_id = tile_id.to_i
              priority = map.priorities[tile_id] || 0
              frame = autotile_frame(tile_id)
              if priority.to_i <= 0
                @helper.bltSmallTile(bitmap, screen_x, screen_y, tile_width, tile_height, tile_id, frame)
                next
              end
              sprite = ensure_priority_sprite(priority_count)
              sprite.bitmap = priority_tile_bitmap(tile_id, frame)
              sprite.x = screen_x
              sprite.y = screen_y
              sprite.z = screen_y + (priority.to_i * 32) + 32
              sprite.instance_variable_set(:@tef_active, true)
              sprite.visible = true
              priority_count += 1
            end
          end
        end
        while priority_count < @priority_sprites.length
          sprite = @priority_sprites[priority_count]
          if sprite && !sprite.disposed?
            sprite.instance_variable_set(:@tef_active, false)
            sprite.visible = false
          end
          priority_count += 1
        end
      end
    end
  end
end

unless defined?(::Achievement)
  class ::Achievement < TravelExpansionFramework::XenoverseAchievementShim
    class << self
      def load(_new_game = false)
        return TravelExpansionFramework.xenoverse_ensure_achievements!
      end

      def save
        return TravelExpansionFramework.xenoverse_flush_achievements!
      end

      def importAchievements
        return TravelExpansionFramework.xenoverse_ensure_achievements!
      end

      def createObjects(pbs = nil, _load = nil)
        TravelExpansionFramework.xenoverse_ensure_achievements!
        if pbs.respond_to?(:each)
          pbs.each do |key, values|
            record = $achievements[key]
            values.each { |entry_key, entry_value| record.assign(entry_key, entry_value) } if values.respond_to?(:each)
          end
        end
        return $achievements
      end
    end
  end
end

unless defined?(::Achievement_UI)
  class ::Achievement_UI
    class << self
      def onChangeProgress(_achievement)
        return nil
      end
    end
  end
end

unless defined?(pbCheckPlatinumAchi)
  def pbCheckPlatinumAchi
    return false
  end
end

class Interpreter
  alias tef_xenoverse_original_execute_script execute_script unless method_defined?(:tef_xenoverse_original_execute_script)

  def execute_script(script)
    TravelExpansionFramework.xenoverse_ensure_achievements! if TravelExpansionFramework.xenoverse_active_now?
    return tef_xenoverse_original_execute_script(script)
  end
end

def fbInitialize(_fast = false)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
  TravelExpansionFramework.reset_xenoverse_fullbox_state
end

def fbEnable(_enable, _show_old = false)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
end

def fbNewMugshot(name, type, pose, position, active = true, _fade_in = 0, _fast = false)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
  translated_name = TravelExpansionFramework.xenoverse_translate_text(name.to_s)
  TravelExpansionFramework.xenoverse_set_speaker(position, translated_name, type, pose, active)
end

def fbPosition(arr, position, _frame = 0)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
  return if arr.nil?
  if arr.is_a?(Symbol)
    normalized_from = TravelExpansionFramework.xenoverse_normalize_position(arr)
    normalized_to = TravelExpansionFramework.xenoverse_normalize_position(position)
    entry = TravelExpansionFramework.xenoverse_fullbox_state[:positions][normalized_from]
    return if !entry
    TravelExpansionFramework.xenoverse_delete_speaker(normalized_from) if normalized_from != normalized_to
    TravelExpansionFramework.xenoverse_set_speaker(normalized_to, entry[:name], entry[:asset], entry[:pose], nil)
  end
end

def fbMove(arr, position, frame = 10)
  fbPosition(arr, position, frame)
end

def fbOpacity(_arr, _active, _frame = 0)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
end

def fbFade(arr, active, frame = 10)
  fbOpacity(arr, active, frame)
end

def fbFadeMove(arr, active, position, frame = 10)
  fbFade(arr, active, frame)
  fbPosition(arr, position, frame)
end

def fbAnimate(_condition = nil)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
end

def fbMakeMove
  return if !TravelExpansionFramework.xenoverse_expansion_id?
end

def fbMugshot(mug, type, pose)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
  TravelExpansionFramework.xenoverse_set_speaker(mug, nil, type, pose, nil)
end

def fbUpdate(_graphics_update = true)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
end

def fbDeleteMugshot(arr = nil)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
  return TravelExpansionFramework.reset_xenoverse_fullbox_state if arr.nil?
  TravelExpansionFramework.xenoverse_delete_speaker(arr)
end

def fbActive(arr = nil)
  return if !TravelExpansionFramework.xenoverse_expansion_id?
  state = TravelExpansionFramework.xenoverse_fullbox_state
  if arr.nil?
    state[:active_position] = nil
  elsif arr.is_a?(Symbol)
    state[:active_position] = TravelExpansionFramework.xenoverse_normalize_position(arr)
  end
end

def fbActiveAll
  return if !TravelExpansionFramework.xenoverse_expansion_id?
  state = TravelExpansionFramework.xenoverse_fullbox_state
  state[:active_position] = state[:positions].keys.first
end

def fbSpeaking(arr)
  fbActive(arr)
end

def fbDispose
  return if !TravelExpansionFramework.xenoverse_expansion_id?
  TravelExpansionFramework.reset_xenoverse_fullbox_state
end

class Trainer
  def storedStarter
    return @tef_xenoverse_stored_starter if instance_variable_defined?(:@tef_xenoverse_stored_starter)
    state = TravelExpansionFramework.state_for(TravelExpansionFramework::XENOVERSE_EXPANSION_ID)
    metadata = state && state.respond_to?(:metadata) ? state.metadata : nil
    return metadata["xenoverse_stored_starter"] if metadata.is_a?(Hash)
    return nil
  rescue
    return nil
  end

  def setStored(value)
    @tef_xenoverse_stored_starter = value
    state = TravelExpansionFramework.state_for(TravelExpansionFramework::XENOVERSE_EXPANSION_ID)
    metadata = state && state.respond_to?(:metadata) ? state.metadata : nil
    metadata["xenoverse_stored_starter"] = value if metadata.is_a?(Hash)
    return value
  rescue
    return value
  end
end

class Player
  def npcPartner
    return @npcPartner if instance_variable_defined?(:@npcPartner)
    return nil
  end

  def npcPartner=(value)
    @npcPartner = value
  end
end

class Game_Player
  alias tef_xenoverse_original_setPlayerGraphicsOverride setPlayerGraphicsOverride unless method_defined?(:tef_xenoverse_original_setPlayerGraphicsOverride)
  alias tef_xenoverse_original_hasGraphicsOverride? hasGraphicsOverride? unless method_defined?(:tef_xenoverse_original_hasGraphicsOverride?)
  alias tef_xenoverse_original_character_name character_name unless method_defined?(:tef_xenoverse_original_character_name)

  def setPlayerGraphicsOverride(path)
    if TravelExpansionFramework.xenoverse_active_now?
      @defaultCharacterName = ""
      @character_name = nil
      return ""
    end
    return tef_xenoverse_original_setPlayerGraphicsOverride(path)
  end

  def hasGraphicsOverride?
    return false if TravelExpansionFramework.xenoverse_active_now?
    return tef_xenoverse_original_hasGraphicsOverride?
  end

  def character_name
    if TravelExpansionFramework.xenoverse_active_now?
      removeGraphicsOverride if respond_to?(:removeGraphicsOverride)
      @defaultCharacterName = ""
      self.charsetData = nil if respond_to?(:charsetData=)
    end
    return tef_xenoverse_original_character_name
  end
end

class Sprite_Player
  alias tef_xenoverse_original_update update unless method_defined?(:tef_xenoverse_original_update)
  alias tef_xenoverse_original_dispose dispose unless method_defined?(:tef_xenoverse_original_dispose)

  def update
    tef_xenoverse_original_update
    tef_xenoverse_apply_clothed_bush_bitmap
  end

  def dispose
    if @tef_xenoverse_bushbitmap
      @tef_xenoverse_bushbitmap.dispose if @tef_xenoverse_bushbitmap.respond_to?(:dispose)
      @tef_xenoverse_bushbitmap = nil
    end
    tef_xenoverse_original_dispose
  end

  private

  def tef_xenoverse_apply_clothed_bush_bitmap
    active = TravelExpansionFramework.xenoverse_active_now?
    bushdepth = (@character && @character.respond_to?(:bush_depth)) ? @character.bush_depth.to_i : 0
    if !active || bushdepth <= 0 || @character != $game_player
      if @tef_xenoverse_bushbitmap
        @tef_xenoverse_bushbitmap.dispose if @tef_xenoverse_bushbitmap.respond_to?(:dispose)
        @tef_xenoverse_bushbitmap = nil
        @tef_xenoverse_bushdepth = nil
        @tef_xenoverse_bushbitmap_source_id = nil
      end
      return
    end
    source_bitmap = getClothedPlayerSprite()
    return if source_bitmap.nil?
    source_id = source_bitmap.object_id
    if @tef_xenoverse_bushbitmap.nil? ||
       @tef_xenoverse_bushdepth != bushdepth ||
       @tef_xenoverse_bushbitmap_source_id != source_id
      @tef_xenoverse_bushbitmap.dispose if @tef_xenoverse_bushbitmap && @tef_xenoverse_bushbitmap.respond_to?(:dispose)
      @tef_xenoverse_bushbitmap = BushBitmap.new(source_bitmap, false, bushdepth)
      @tef_xenoverse_bushdepth = bushdepth
      @tef_xenoverse_bushbitmap_source_id = source_id
    end
    if @tef_xenoverse_bushbitmap && @tef_xenoverse_bushbitmap.respond_to?(:bitmap)
      self.bitmap = @tef_xenoverse_bushbitmap.bitmap
      if @tile_id == 0 && @character
        @cw = [self.bitmap.width / 4, 1].max if self.bitmap && self.bitmap.respond_to?(:width)
        @ch = [self.bitmap.height / 4, 1].max if self.bitmap && self.bitmap.respond_to?(:height)
        sx = @character.pattern.to_i * @cw
        sy = ((@character.direction.to_i - 2) / 2) * @ch
        self.src_rect.set(sx, sy, @cw, @ch)
        self.ox = @cw / 2
        self.oy = (@spriteoffset rescue false) ? @ch - 16 : @ch
        self.oy -= @character.bob_height if @character.respond_to?(:bob_height)
      end
    end
  rescue => e
    TravelExpansionFramework.log("[xenoverse] bush sprite override failed: #{e.class}: #{e.message}")
  end
end

if defined?(isPartneredWithAnyTrainer) && !defined?(tef_xenoverse_original_isPartneredWithAnyTrainer)
  alias tef_xenoverse_original_isPartneredWithAnyTrainer isPartneredWithAnyTrainer
end

def isPartneredWithAnyTrainer()
  return false if TravelExpansionFramework.xenoverse_active_now?
  return false if !$Trainer || !$Trainer.respond_to?(:npcPartner)
  return $Trainer.npcPartner != nil
end

if defined?(isPartneredWithTrainer) && !defined?(tef_xenoverse_original_isPartneredWithTrainer)
  alias tef_xenoverse_original_isPartneredWithTrainer isPartneredWithTrainer
end

def isPartneredWithTrainer(trainer)
  return false if TravelExpansionFramework.xenoverse_active_now?
  return false if !$Trainer || !$Trainer.respond_to?(:npcPartner)
  return $Trainer.npcPartner == trainer.trainerKey
end

if defined?(promptGiveToPartner) && !defined?(tef_xenoverse_original_promptGiveToPartner)
  alias tef_xenoverse_original_promptGiveToPartner promptGiveToPartner
end

def promptGiveToPartner(caughtPokemon)
  return false if TravelExpansionFramework.xenoverse_active_now?
  return tef_xenoverse_original_promptGiveToPartner(caughtPokemon) if respond_to?(:tef_xenoverse_original_promptGiveToPartner, true)
  return false
end

if defined?(DependentEvents)
  class DependentEvents
    if !method_defined?(:SetMoveRoute)
      def SetMoveRoute(commands, waitComplete = false)
        return nil if !TravelExpansionFramework.xenoverse_active_now?
        route_commands = Array(commands).compact
        return nil if route_commands.empty?
        event = TravelExpansionFramework.xenoverse_primary_dependent_event(self)
        return nil if event.nil?
        route = pbMoveRoute(event, route_commands, waitComplete)
        refresh_sprite(false) if respond_to?(:refresh_sprite)
        return route
      rescue => e
        TravelExpansionFramework.log("[xenoverse] SetMoveRoute failed: #{e.class}: #{e.message}")
        return nil
      end
    end
  end
end

if defined?(FollowingMoveRoute) && !defined?(tef_xenoverse_original_FollowingMoveRoute)
  alias tef_xenoverse_original_FollowingMoveRoute FollowingMoveRoute
end

def FollowingMoveRoute(commands, waitComplete = false)
  if !TravelExpansionFramework.xenoverse_active_now?
    return send(:tef_xenoverse_original_FollowingMoveRoute, commands, waitComplete) if respond_to?(:tef_xenoverse_original_FollowingMoveRoute, true)
    return nil
  end
  dependent_events = ($PokemonTemp.dependentEvents rescue nil)
  return nil if dependent_events.nil?
  route = nil
  if dependent_events.respond_to?(:SetMoveRoute)
    route = dependent_events.SetMoveRoute(commands, waitComplete)
  else
    event = TravelExpansionFramework.xenoverse_primary_dependent_event(dependent_events)
    route = pbMoveRoute(event, Array(commands).compact, waitComplete) if event
  end
  @move_route_waiting = true if waitComplete && instance_variable_defined?(:@move_route_waiting)
  return route
end

def pbPokeStep
  return nil if !TravelExpansionFramework.xenoverse_active_now?
  return nil if !$game_map || !$game_map.respond_to?(:events) || !$game_map.events
  $game_map.events.each_value do |event|
    next if event.nil? || event.name.to_s != "Poke"
    pbMoveRoute(event, [PBMoveRoute::StepAnimeOn])
  end
  return nil
end

def pbReceiveItemPop(item, quantity = 1)
  quantity = TravelExpansionFramework.integer(quantity, 1)
  quantity = 1 if quantity <= 0
  return pbReceiveItem(item, quantity)
end

if defined?(pbAddPokemon) && !defined?(tef_xenoverse_original_pbAddPokemon)
  alias tef_xenoverse_original_pbAddPokemon pbAddPokemon
end

def pbAddPokemon(pkmn, level = 1, see_form = true, dontRandomize = false, variableToSave = nil)
  if TravelExpansionFramework.xenoverse_active_now?
    pkmn = TravelExpansionFramework.xenoverse_resolve_species_reference(pkmn)
  end
  return tef_xenoverse_original_pbAddPokemon(pkmn, level, see_form, dontRandomize, variableToSave)
end

if defined?(pbAddPokemonSilent) && !defined?(tef_xenoverse_original_pbAddPokemonSilent)
  alias tef_xenoverse_original_pbAddPokemonSilent pbAddPokemonSilent
end

def pbAddPokemonSilent(pkmn, level = 1, see_form = true)
  if TravelExpansionFramework.xenoverse_active_now?
    pkmn = TravelExpansionFramework.xenoverse_resolve_species_reference(pkmn)
  end
  return tef_xenoverse_original_pbAddPokemonSilent(pkmn, level, see_form)
end

if defined?(pbAddToParty) && !defined?(tef_xenoverse_original_pbAddToParty)
  alias tef_xenoverse_original_pbAddToParty pbAddToParty
end

def pbAddToParty(pkmn, level = 1, see_form = true, dontRandomize = false)
  if TravelExpansionFramework.xenoverse_active_now?
    pkmn = TravelExpansionFramework.xenoverse_resolve_species_reference(pkmn)
  end
  return tef_xenoverse_original_pbAddToParty(pkmn, level, see_form, dontRandomize)
end

if defined?(pbAddToPartySilent) && !defined?(tef_xenoverse_original_pbAddToPartySilent)
  alias tef_xenoverse_original_pbAddToPartySilent pbAddToPartySilent
end

def pbAddToPartySilent(pkmn, level = nil, see_form = true)
  if TravelExpansionFramework.xenoverse_active_now?
    pkmn = TravelExpansionFramework.xenoverse_resolve_species_reference(pkmn)
  end
  return tef_xenoverse_original_pbAddToPartySilent(pkmn, level, see_form)
end

if defined?(pbAddForeignPokemon) && !defined?(tef_xenoverse_original_pbAddForeignPokemon)
  alias tef_xenoverse_original_pbAddForeignPokemon pbAddForeignPokemon
end

def pbAddForeignPokemon(pkmn, level = 1, owner_name = nil, nickname = nil, owner_gender = 0, see_form = true)
  if TravelExpansionFramework.xenoverse_active_now?
    pkmn = TravelExpansionFramework.xenoverse_resolve_species_reference(pkmn)
  end
  return tef_xenoverse_original_pbAddForeignPokemon(pkmn, level, owner_name, nickname, owner_gender, see_form)
end

if defined?(pbGenerateEgg) && !defined?(tef_xenoverse_original_pbGenerateEgg)
  alias tef_xenoverse_original_pbGenerateEgg pbGenerateEgg
end

def pbGenerateEgg(pkmn, text = "")
  if TravelExpansionFramework.xenoverse_active_now?
    pkmn = TravelExpansionFramework.xenoverse_resolve_species_reference(pkmn)
  end
  return tef_xenoverse_original_pbGenerateEgg(pkmn, text)
end

if defined?(pbAddPokemonID) && !defined?(tef_xenoverse_original_pbAddPokemonID)
  alias tef_xenoverse_original_pbAddPokemonID pbAddPokemonID
end

def pbAddPokemonID(pokemon_id, level = 1, see_form = true, skip_randomize = false)
  if TravelExpansionFramework.xenoverse_active_now?
    resolved_id = TravelExpansionFramework.xenoverse_resolve_species_reference(pokemon_id)
    if resolved_id != pokemon_id && !resolved_id.is_a?(Integer)
      return pbAddPokemon(resolved_id, level, see_form, skip_randomize)
    end
    pokemon_id = resolved_id
  end
  return tef_xenoverse_original_pbAddPokemonID(pokemon_id, level, see_form, skip_randomize)
end

if defined?(getID) && !defined?(tef_xenoverse_original_getID)
  alias tef_xenoverse_original_getID getID
end

def getID(pbspecies_unused, species)
  if TravelExpansionFramework.xenoverse_active_now?
    resolved = TravelExpansionFramework.xenoverse_resolve_species_reference(species)
    if resolved != species
      data = GameData::Species.try_get(resolved) rescue nil
      return data.id_number if data
    end
  end
  return tef_xenoverse_original_getID(pbspecies_unused, species)
end

if defined?(pbBattleAnimation) && !defined?(tef_xenoverse_original_pbBattleAnimation)
  alias tef_xenoverse_original_pbBattleAnimation pbBattleAnimation
end

def pbBattleAnimation(bgm = nil, battletype = 0, foe = nil, &block)
  active = TravelExpansionFramework.xenoverse_battle_animation_active?
  label = active ? TravelExpansionFramework::XENOVERSE_EXPANSION_ID : "host"
  begin
    return tef_xenoverse_original_pbBattleAnimation(bgm, battletype, foe, &block)
  rescue RGSSError => e
    raise e if e.message.to_s !~ /disposed viewport/i
    return TravelExpansionFramework.recover_disposed_battle_viewport!(label)
  end
end

if defined?(pbChangePlayer) && !defined?(tef_xenoverse_original_pbChangePlayer)
  alias tef_xenoverse_original_pbChangePlayer pbChangePlayer
end

def pbChangePlayer(id, *args)
  if !TravelExpansionFramework.xenoverse_active_now?
    return send(:tef_xenoverse_original_pbChangePlayer, id, *args) if respond_to?(:tef_xenoverse_original_pbChangePlayer, true)
    return TravelExpansionFramework.integer(id, 0)
  end
  TravelExpansionFramework.xenoverse_sync_runtime_language!(true)
  state = TravelExpansionFramework.state_for(TravelExpansionFramework::XENOVERSE_EXPANSION_ID)
  state.metadata["xenoverse_avatar_id"] = TravelExpansionFramework.integer(id, 0) if state && state.respond_to?(:metadata) && state.metadata.is_a?(Hash)
  TravelExpansionFramework.xenoverse_apply_host_player_visuals!
  return TravelExpansionFramework.integer(id, 0)
end

if defined?(pbTrainerName) && !defined?(tef_xenoverse_original_pbTrainerName)
  alias tef_xenoverse_original_pbTrainerName pbTrainerName
end

def pbTrainerName(name = nil, outfit = 0)
  if !TravelExpansionFramework.xenoverse_active_now?
    return send(:tef_xenoverse_original_pbTrainerName, name, outfit) if respond_to?(:tef_xenoverse_original_pbTrainerName, true)
    return $Trainer.name.to_s if $Trainer
    return name.to_s
  end
  TravelExpansionFramework.xenoverse_sync_runtime_language!(true)
  return $Trainer.name.to_s if $Trainer
  return name.to_s
end

if defined?(pbCallGenderSelect) && !defined?(tef_xenoverse_original_pbCallGenderSelect)
  alias tef_xenoverse_original_pbCallGenderSelect pbCallGenderSelect
end

def pbCallGenderSelect(*args)
  if !TravelExpansionFramework.xenoverse_active_now?
    return send(:tef_xenoverse_original_pbCallGenderSelect, *args) if respond_to?(:tef_xenoverse_original_pbCallGenderSelect, true)
    return 0
  end
  TravelExpansionFramework.xenoverse_sync_runtime_language!(true)
  female = TravelExpansionFramework.xenoverse_player_female?
  TravelExpansionFramework.with_runtime_context(TravelExpansionFramework::XENOVERSE_EXPANSION_ID, {
    :map_id   => ($game_map.map_id rescue nil),
    :event_id => 0,
    :source   => :xenoverse_gender_bootstrap
  }) do
    $game_switches[37] = !female if $game_switches
    $game_switches[38] = female if $game_switches
    $game_variables[51] = (female ? 1 : 0) if $game_variables
  end
  state = TravelExpansionFramework.state_for(TravelExpansionFramework::XENOVERSE_EXPANSION_ID)
  if state && state.respond_to?(:metadata) && state.metadata.is_a?(Hash)
    state.metadata["xenoverse_gender_bootstrapped"] = true
    state.metadata["xenoverse_gender_value"] = female ? "female" : "male"
  end
  return female ? 1 : 0
end

class Interpreter
  alias tef_xenoverse_original_pbTrainerIntro pbTrainerIntro unless method_defined?(:tef_xenoverse_original_pbTrainerIntro)

  def pbTrainerIntro(symbol)
    if !TravelExpansionFramework.xenoverse_active_now?
      return tef_xenoverse_original_pbTrainerIntro(symbol)
    end
    TravelExpansionFramework.xenoverse_sync_runtime_language!(true)
    pbGlobalLock
    TravelExpansionFramework.xenoverse_play_trainer_intro(symbol)
    return true
  rescue => e
    TravelExpansionFramework.log("[xenoverse] pbTrainerIntro failed for #{symbol.inspect}: #{e.class}: #{e.message}")
    return tef_xenoverse_original_pbTrainerIntro(symbol)
  end
end

if defined?(pbPlayTrainerIntroME) && !defined?(tef_xenoverse_original_pbPlayTrainerIntroME)
  alias tef_xenoverse_original_pbPlayTrainerIntroME pbPlayTrainerIntroME
end

def pbPlayTrainerIntroME(trainer_type)
  if TravelExpansionFramework.xenoverse_active_now?
    played = TravelExpansionFramework.xenoverse_play_trainer_intro(trainer_type)
    return if played
  end
  return tef_xenoverse_original_pbPlayTrainerIntroME(trainer_type) if defined?(tef_xenoverse_original_pbPlayTrainerIntroME)
end

if defined?(pbGetTrainerBattleBGMFromType) && !defined?(tef_xenoverse_original_pbGetTrainerBattleBGMFromType)
  alias tef_xenoverse_original_pbGetTrainerBattleBGMFromType pbGetTrainerBattleBGMFromType
end

def pbGetTrainerBattleBGMFromType(trainertype)
  if TravelExpansionFramework.xenoverse_active_now?
    ret = TravelExpansionFramework.xenoverse_trainer_battle_bgm_from_type(trainertype)
    return ret if ret
  end
  return tef_xenoverse_original_pbGetTrainerBattleBGMFromType(trainertype) if defined?(tef_xenoverse_original_pbGetTrainerBattleBGMFromType)
  return nil
end

if defined?(PokeBattle_Battle)
  class PokeBattle_Battle
    alias tef_xenoverse_original_pbDisplay pbDisplay unless method_defined?(:tef_xenoverse_original_pbDisplay)
    alias tef_xenoverse_original_pbDisplayBrief pbDisplayBrief unless method_defined?(:tef_xenoverse_original_pbDisplayBrief)
    alias tef_xenoverse_original_pbDisplayPaused pbDisplayPaused unless method_defined?(:tef_xenoverse_original_pbDisplayPaused)
    alias tef_xenoverse_original_pbDisplayConfirm pbDisplayConfirm unless method_defined?(:tef_xenoverse_original_pbDisplayConfirm)

    def pbDisplay(msg, &block)
      if TravelExpansionFramework.xenoverse_active_now?
        msg = TravelExpansionFramework.xenoverse_battle_display_text(msg, ($game_map.map_id rescue nil))
      end
      return tef_xenoverse_original_pbDisplay(msg, &block)
    end

    def pbDisplayBrief(msg)
      if TravelExpansionFramework.xenoverse_active_now?
        msg = TravelExpansionFramework.xenoverse_battle_display_text(msg, ($game_map.map_id rescue nil))
      end
      return tef_xenoverse_original_pbDisplayBrief(msg)
    end

    def pbDisplayPaused(msg, &block)
      if TravelExpansionFramework.xenoverse_active_now?
        msg = TravelExpansionFramework.xenoverse_battle_display_text(msg, ($game_map.map_id rescue nil))
      end
      return tef_xenoverse_original_pbDisplayPaused(msg, &block)
    end

    def pbDisplayConfirm(msg)
      if TravelExpansionFramework.xenoverse_active_now?
        msg = TravelExpansionFramework.xenoverse_battle_display_text(msg, ($game_map.map_id rescue nil))
      end
      return tef_xenoverse_original_pbDisplayConfirm(msg)
    end
  end
end

if defined?(_INTL) && !defined?(tef_xenoverse_original__INTL)
  alias tef_xenoverse_original__INTL _INTL
end

def _INTL(*arg)
  if !TravelExpansionFramework.xenoverse_active_now?
    return tef_xenoverse_original__INTL(*arg)
  end
  TravelExpansionFramework.xenoverse_sync_runtime_language!(true)
  template = TravelExpansionFramework.xenoverse_translate_script_text(arg[0].to_s, ($game_map.map_id rescue nil))
  return TravelExpansionFramework.xenoverse_format_text(template, arg[1..-1])
rescue
  return tef_xenoverse_original__INTL(*arg)
end

if defined?(pbMessage) && !defined?(tef_xenoverse_original_pbMessage)
  alias tef_xenoverse_original_pbMessage pbMessage
end

def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
  return tef_xenoverse_original_pbMessage(message, commands, cmdIfCancel, skin, defaultCmd, &block) if !TravelExpansionFramework.xenoverse_active_now?
  TravelExpansionFramework.xenoverse_sync_runtime_language!(true)
  map_id = ($game_map.map_id rescue nil)
  text = TravelExpansionFramework.xenoverse_plain_text(message.to_s, map_id)
  translated_commands = commands
  if commands
    translated_commands = Array(commands).map { |entry| TravelExpansionFramework.xenoverse_choice_text(entry, map_id) }
  end
  return tef_xenoverse_original_pbMessage(text, translated_commands, cmdIfCancel, skin, defaultCmd, &block)
end

def fbText(message, commands = nil, cmdIfCancel = 0, defaultCmd = 0, &block)
  return nil if !TravelExpansionFramework.xenoverse_active_now?
  TravelExpansionFramework.xenoverse_sync_runtime_language!(true)
  text = TravelExpansionFramework.xenoverse_plain_text(message)
  return nil if text.to_s.empty? && !commands
  if commands
    translated_commands = Array(commands).map { |entry| TravelExpansionFramework.xenoverse_choice_text(entry) }
    return pbMessage(text, translated_commands, cmdIfCancel, nil, defaultCmd, &block)
  end
  pbMessage(text, &block)
  return nil
end

class SceltaStarter
  STARTER_SWITCH_MAP = {
    1021 => 51,
    1022 => 52,
    1023 => 53
  }
  STARTER_NAME_MAP = {
    1021 => "Shyleon",
    1022 => "Trishout",
    1023 => "Shulong"
  }
  STARTER_SPECIES_MAP = {
    1021 => :SHYLEON,
    1022 => :TRISHOUT,
    1023 => :SHULONG
  }

  def initialize(*starter_ids)
    ids = Array(starter_ids).flatten.map { |value| TravelExpansionFramework.integer(value, 0) }.find_all { |value| value > 0 }
    ids = STARTER_NAME_MAP.keys if ids.empty?
    choice = choose_starter_id(ids)
    apply_starter_choice(choice)
  end

  private

  def choose_starter_id(ids)
    return ids.first if !TravelExpansionFramework.xenoverse_active_now?
    TravelExpansionFramework.xenoverse_sync_runtime_language!(true)
    commands = ids.map { |value| STARTER_NAME_MAP[value] || "Starter #{value}" }
    message = TravelExpansionFramework.xenoverse_translate_script_text("Choose the Pokémon you like best!")
    selection = 0
    begin
      selection = pbMessage(message, commands, -1)
    rescue
      selection = 0
    end
    selection = 0 if selection.nil? || selection < 0
    return ids[selection] || ids.first
  end

  def apply_starter_choice(starter_id)
    switch_id = STARTER_SWITCH_MAP[starter_id]
    switch_id = STARTER_SWITCH_MAP.values.first if switch_id.nil?
    TravelExpansionFramework.with_runtime_context(TravelExpansionFramework::XENOVERSE_EXPANSION_ID, {
      :map_id   => ($game_map.map_id rescue nil),
      :event_id => 0,
      :source   => :xenoverse_starter_selection
    }) do
      $game_switches[7] = true if $game_switches
      [51, 52, 53].each { |id| $game_switches[id] = false if $game_switches }
      $game_switches[switch_id] = true if $game_switches
      $game_switches[70] = true if $game_switches
      $game_switches[71] = false if $game_switches
      $game_map.need_refresh = true if $game_map
    end
    state = TravelExpansionFramework.state_for(TravelExpansionFramework::XENOVERSE_EXPANSION_ID)
    if state && state.respond_to?(:metadata) && state.metadata.is_a?(Hash)
      state.metadata["xenoverse_starter_id"] = starter_id
      state.metadata["xenoverse_starter_name"] = STARTER_NAME_MAP[starter_id]
      state.metadata["xenoverse_starter_species"] = STARTER_SPECIES_MAP[starter_id].to_s
      state.metadata["xenoverse_starter_switch"] = switch_id
    end
    $Trainer.setStored(starter_id) if $Trainer && $Trainer.respond_to?(:setStored)
    TravelExpansionFramework.log("[xenoverse] starter choice => #{STARTER_NAME_MAP[starter_id]} (#{starter_id}) switch=#{switch_id}")
  end
end

class Scene_Map
  alias tef_xenoverse_original_createSpritesets createSpritesets

  def createSpritesets
    if TravelExpansionFramework.xenoverse_use_software_renderer? &&
       TravelExpansionFramework.xenoverse_expansion_id?(TravelExpansionFramework.current_map_expansion_id)
      if @map_renderer && !@map_renderer.is_a?(TravelExpansionFramework::XenoverseRenderer::Adapter)
        @map_renderer.dispose if @map_renderer.respond_to?(:dispose) && !@map_renderer.disposed?
        @map_renderer = nil
      end
      @map_renderer = TravelExpansionFramework::XenoverseRenderer::Adapter.new(Spriteset_Map.viewport) if !@map_renderer || @map_renderer.disposed?
      @spritesetGlobal = Spriteset_Global.new if !@spritesetGlobal
      @spritesets = {}
      for map in $MapFactory.maps
        @spritesets[map.map_id] = Spriteset_Map.new(map)
      end
      $MapFactory.setSceneStarted(self)
      updateSpritesets(true)
      return
    end
    if @map_renderer && @map_renderer.is_a?(TravelExpansionFramework::XenoverseRenderer::Adapter)
      @map_renderer.dispose if !@map_renderer.disposed?
      @map_renderer = nil
    end
    tef_xenoverse_original_createSpritesets
  end
end

class Interpreter
  alias tef_xenoverse_original_command_101 command_101

  def command_101
    expansion_id = if respond_to?(:tef_expansion_id)
                     @tef_expansion_id
                   else
                     TravelExpansionFramework.current_runtime_expansion_id
                   end
    return tef_xenoverse_original_command_101 if !TravelExpansionFramework.xenoverse_expansion_id?(expansion_id)
    TravelExpansionFramework.xenoverse_sync_runtime_language!(true)
    return false if $game_temp.message_window_showing
    message = @list[@index].parameters[0].to_s
    message_end = ""
    commands = nil
    number_input_variable = nil
    number_input_max_digits = nil
    loop do
      next_index = pbNextIndex(@index)
      case @list[next_index].code
      when 401
        text = @list[next_index].parameters[0].to_s
        message += "\n" if !message.empty?
        message += text
        @index = next_index
        next
      when 101
        message_end = "\1"
      when 102
        commands = @list[next_index].parameters
        @index = next_index
      when 103
        number_input_variable = @list[next_index].parameters[0]
        number_input_max_digits = @list[next_index].parameters[1]
        @index = next_index
      end
      break
    end
    message = TravelExpansionFramework.xenoverse_plain_text(message, $game_map.map_id)
    @message_waiting = true
    if commands
      cmd_texts = []
      for cmd in commands[0]
        localized = TravelExpansionFramework.xenoverse_choice_text(cmd, $game_map.map_id)
        cmd_texts.push(localized)
      end
      command = pbMessage(message + message_end, cmd_texts, commands[1])
      @branch[@list[@index].indent] = command
    elsif number_input_variable
      params = ChooseNumberParams.new
      params.setMaxDigits(number_input_max_digits)
      params.setDefaultValue($game_variables[number_input_variable])
      $game_variables[number_input_variable] = pbMessageChooseNumber(message + message_end, params)
      $game_map.need_refresh = true if $game_map
    elsif !message.to_s.empty?
      pbMessage(message + message_end)
    end
    @message_waiting = false
    return true
  end
end
