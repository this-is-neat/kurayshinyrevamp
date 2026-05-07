module TravelExpansionFramework
  module_function

  REBORN_EXPANSION_ID = "reborn" if !const_defined?(:REBORN_EXPANSION_ID)
  REBORN_POST_TRAIN_SAFE_LOCAL_MAPS = [37].freeze if !const_defined?(:REBORN_POST_TRAIN_SAFE_LOCAL_MAPS)
  REBORN_TRAIN_SOURCE_LOCAL_MAPS = [667, 689].freeze if !const_defined?(:REBORN_TRAIN_SOURCE_LOCAL_MAPS)
  REBORN_BLOCKED_RESUME_LOCAL_MAPS = [51, 667, 689].freeze if !const_defined?(:REBORN_BLOCKED_RESUME_LOCAL_MAPS)
  REBORN_GOT_POKEMON_SWITCH = 2 if !const_defined?(:REBORN_GOT_POKEMON_SWITCH)
  REBORN_POST_TRAIN_COMPLETE_SWITCH = 30 if !const_defined?(:REBORN_POST_TRAIN_COMPLETE_SWITCH)
  REBORN_POST_TRAIN_GREETING_EVENT = 1 if !const_defined?(:REBORN_POST_TRAIN_GREETING_EVENT)
  REBORN_POST_TRAIN_SPAWN_X = 23 if !const_defined?(:REBORN_POST_TRAIN_SPAWN_X)
  REBORN_POST_TRAIN_SPAWN_Y = 68 if !const_defined?(:REBORN_POST_TRAIN_SPAWN_Y)

  def reborn_expansion_id?(expansion_id = nil)
    expansion = expansion_id
    expansion = current_runtime_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_runtime_expansion_id)
    expansion = current_map_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_map_expansion_id)
    expansion = current_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_expansion_id)
    return expansion.to_s == REBORN_EXPANSION_ID
  end

  def reborn_current_map_id
    return integer($game_map.map_id, 0) if defined?($game_map) && $game_map && $game_map.respond_to?(:map_id)
    return 0
  rescue
    return 0
  end

  def reborn_local_map_id(map_id = nil)
    map_id = reborn_current_map_id if map_id.nil? || integer(map_id, 0) <= 0
    map_id = integer(map_id, 0)
    return 0 if map_id <= 0
    local_id = local_map_id_for(REBORN_EXPANSION_ID, map_id) if respond_to?(:local_map_id_for)
    local_id = integer(local_id, 0)
    return local_id if local_id > 0
    return map_id % 1000 if map_id >= 20_000
    return map_id
  rescue
    return 0
  end

  def reborn_anchor_capture_blocked?(anchor = nil)
    normalized = sanitize_anchor(anchor)
    return false if !normalized
    local_id = local_map_id_for(REBORN_EXPANSION_ID, normalized[:map_id]) if respond_to?(:local_map_id_for)
    local_id = integer(local_id, 0)
    local_id = integer(normalized[:map_id], 0) % 1000 if local_id <= 0 && integer(normalized[:map_id], 0) >= 20_000
    return true if local_id == 37 && !reborn_post_train_story_complete?
    return REBORN_BLOCKED_RESUME_LOCAL_MAPS.include?(local_id)
  rescue => e
    log("[reborn] anchor capture check failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_map_interpreter
    interpreter = pbMapInterpreter if defined?(pbMapInterpreter) && pbMapInterpreter
    interpreter ||= $game_system.map_interpreter if $game_system && $game_system.respond_to?(:map_interpreter)
    return interpreter
  rescue
    return nil
  end

  def reborn_map_interpreter_running?
    return true if $game_temp && $game_temp.respond_to?(:message_window_showing) && $game_temp.message_window_showing
    interpreter = reborn_map_interpreter
    return false if !interpreter
    running = interpreter.running? if interpreter.respond_to?(:running?)
    return running ? true : false if !running.nil?
    return !interpreter.instance_variable_get(:@list).nil?
  rescue
    return false
  end

  def reborn_metadata
    return nil if !respond_to?(:state_for)
    state = state_for(REBORN_EXPANSION_ID)
    return nil if !state || !state.respond_to?(:metadata)
    state.metadata = {} if state.respond_to?(:metadata=) && !state.metadata.is_a?(Hash)
    return state.metadata if state.metadata.is_a?(Hash)
    return nil
  rescue
    return nil
  end

  def reborn_post_train_arrival_pending?
    metadata = reborn_metadata
    return false if !metadata
    return metadata["post_train_arrival_pending"] == true
  rescue
    return false
  end

  def reborn_post_train_greeting_recorded?
    metadata = reborn_metadata
    return false if !metadata
    return metadata["post_train_greeting_complete"] == true
  rescue
    return false
  end

  def reborn_mark_post_train_arrival_pending!(reason = nil)
    metadata = reborn_metadata
    return false if !metadata
    already_pending = metadata["post_train_arrival_pending"] == true
    metadata["post_train_arrival_pending"] = true
    metadata["post_train_greeting_complete"] = false
    metadata["post_train_arrival_pending_at"] = timestamp_string if respond_to?(:timestamp_string)
    metadata["post_train_arrival_reason"] = reason.to_s if reason
    log("[reborn] marked post-train greeting pending via #{reason}") if !already_pending && respond_to?(:log)
    return true
  rescue => e
    log("[reborn] failed to mark post-train arrival pending: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_record_post_train_greeting_complete!(reason = nil)
    metadata = reborn_metadata
    return false if !metadata
    already_complete = metadata["post_train_greeting_complete"] == true
    metadata["post_train_greeting_complete"] = true
    metadata.delete("post_train_arrival_pending")
    metadata["post_train_greeting_completed_at"] = timestamp_string if respond_to?(:timestamp_string)
    metadata["post_train_greeting_completed_by"] = reason.to_s if reason
    log("[reborn] recorded post-train greeting completion via #{reason}") if !already_complete && respond_to?(:log)
    return true
  rescue => e
    log("[reborn] failed to record post-train greeting completion: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_post_train_switch_enabled?
    return expansion_switch_value(REBORN_EXPANSION_ID, REBORN_POST_TRAIN_COMPLETE_SWITCH) if respond_to?(:expansion_switch_value)
    return false if !$game_switches
    return $game_switches[REBORN_POST_TRAIN_COMPLETE_SWITCH] ? true : false
  rescue
    return false
  end

  def reborn_set_post_train_switch!(value, reason = nil)
    changed = false
    if respond_to?(:set_expansion_switch_value)
      changed = set_expansion_switch_value(REBORN_EXPANSION_ID, REBORN_POST_TRAIN_COMPLETE_SWITCH, value)
    elsif $game_switches
      $game_switches[REBORN_POST_TRAIN_COMPLETE_SWITCH] = value ? true : false
      changed = true
    end
    $game_map.need_refresh = true if changed && $game_map && $game_map.respond_to?(:need_refresh=)
    log("[reborn] set post-train switch #{REBORN_POST_TRAIN_COMPLETE_SWITCH}=#{value ? true : false} #{reason}") if changed && respond_to?(:log)
    return changed
  rescue => e
    log("[reborn] failed to set post-train switch: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_clear_intro_got_pokemon_switch!(reason = nil)
    return false if !respond_to?(:expansion_switch_value) || !respond_to?(:set_expansion_switch_value)
    return false if !expansion_switch_value(REBORN_EXPANSION_ID, REBORN_GOT_POKEMON_SWITCH)
    changed = set_expansion_switch_value(REBORN_EXPANSION_ID, REBORN_GOT_POKEMON_SWITCH, false)
    $game_map.need_refresh = true if changed && $game_map && $game_map.respond_to?(:need_refresh=)
    log("[reborn] cleared leaked Got Pokemon switch before post-train greeting #{reason}") if changed && respond_to?(:log)
    return changed
  rescue => e
    log("[reborn] failed to clear intro Got Pokemon switch: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_post_train_completion_context?
    return false if !reborn_expansion_id?
    context = current_runtime_context if respond_to?(:current_runtime_context)
    context = nil if !context.is_a?(Hash)
    map_id = context ? integer(context[:map_id], 0) : 0
    map_id = reborn_current_map_id if map_id <= 0
    return false if reborn_local_map_id(map_id) != 37
    event_id = context ? integer(context[:event_id], 0) : 0
    if event_id <= 0
      interpreter = reborn_map_interpreter
      event_id = integer(interpreter.instance_variable_get(:@event_id), 0) if interpreter
    end
    return event_id == REBORN_POST_TRAIN_GREETING_EVENT
  rescue
    return false
  end

  def reborn_post_train_completion_switch?(switch_id)
    return integer(switch_id, 0) == REBORN_POST_TRAIN_COMPLETE_SWITCH
  rescue
    return false
  end

  def reborn_player_near_post_train_spawn?
    return false if !$game_player
    x = integer($game_player.x, 0)
    y = integer($game_player.y, 0)
    return (x - REBORN_POST_TRAIN_SPAWN_X).abs <= 4 &&
           (y - REBORN_POST_TRAIN_SPAWN_Y).abs <= 4
  rescue
    return false
  end

  def reborn_repair_post_train_intro_switch!(previous_local_id = nil)
    return false if !$game_map || reborn_local_map_id($game_map.map_id) != 37
    previous = integer(previous_local_id, 0)
    train_transition = REBORN_TRAIN_SOURCE_LOCAL_MAPS.include?(previous)
    load_recovery = previous <= 0 &&
                    !reborn_post_train_greeting_recorded? &&
                    reborn_player_near_post_train_spawn?
    return false if !train_transition && !load_recovery
    reborn_mark_post_train_arrival_pending!(train_transition ? "train_transfer" : "load_recovery")
    reborn_clear_intro_got_pokemon_switch!(train_transition ? "train_transfer" : "load_recovery")
    if reborn_post_train_switch_enabled?
      reborn_set_post_train_switch!(false, train_transition ? "before map 37 autorun" : "load recovery before map 37 autorun")
      log("[reborn] repaired leaked post-train completion switch before greeting previous=#{previous}") if respond_to?(:log)
      return true
    end
    return false
  rescue => e
    log("[reborn] post-train switch repair failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_clear_stale_train_interpreter_after_transfer!(previous_map_id = nil)
    return false if !$game_map
    local_id = reborn_local_map_id($game_map.map_id)
    return false if !REBORN_POST_TRAIN_SAFE_LOCAL_MAPS.include?(local_id)
    previous_local_id = reborn_local_map_id(previous_map_id)
    return false if !REBORN_TRAIN_SOURCE_LOCAL_MAPS.include?(previous_local_id)
    interpreter = reborn_map_interpreter
    return false if !interpreter
    interpreter_map_id = integer(interpreter.instance_variable_get(:@map_id), 0) rescue 0
    interpreter_local_id = reborn_local_map_id(interpreter_map_id)
    return false if !REBORN_TRAIN_SOURCE_LOCAL_MAPS.include?(interpreter_local_id)
    interpreter.clear if interpreter.respond_to?(:clear)
    interpreter.instance_variable_set(:@list, nil)
    interpreter.instance_variable_set(:@index, 0)
    interpreter.instance_variable_set(:@branch, {})
    interpreter.instance_variable_set(:@child_interpreter, nil)
    if $game_temp
      $game_temp.message_window_showing = false if $game_temp.respond_to?(:message_window_showing=)
      $game_temp.player_transferring = false if $game_temp.respond_to?(:player_transferring=)
      $game_temp.transition_processing = false if $game_temp.respond_to?(:transition_processing=)
    end
    $game_map.need_refresh = true if $game_map.respond_to?(:need_refresh=)
    log("[reborn] cleared stale train interpreter after transfer previous=#{previous_local_id} interpreter=#{interpreter_local_id}")
    return true
  rescue => e
    log("[reborn] stale train interpreter clear failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_post_train_story_complete?
    return false if reborn_post_train_arrival_pending?
    return reborn_post_train_switch_enabled? ? true : false
  rescue
    return false
  end

  def reborn_entry_resume_blocked?(expansion_id = nil, node = nil)
    return false if expansion_id.to_s != REBORN_EXPANSION_ID
    node_id = node.is_a?(Hash) ? node[:id].to_s : ""
    return false if !node_id.empty? && !node_id.end_with?(":entry")
    return !reborn_post_train_story_complete?
  rescue => e
    log("[reborn] entry resume gate failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_release_player_control!(reason = "post-train")
    return false if !$game_player
    changed = false
    if $game_player.respond_to?(:through=)
      changed = true if $game_player.respond_to?(:through) && $game_player.through
      $game_player.through = false
    end
    if $game_player.respond_to?(:transparent=)
      changed = true if $game_player.respond_to?(:transparent) && $game_player.transparent
      $game_player.transparent = false
    end
    $game_player.always_on_top = false if $game_player.respond_to?(:always_on_top=)
    $game_player.unlock if $game_player.respond_to?(:unlock)
    if $game_player.respond_to?(:cancelMoveRoute) &&
       (!$game_player.respond_to?(:moving?) || !$game_player.moving?)
      $game_player.cancelMoveRoute
    end
    $game_player.refresh if $game_player.respond_to?(:refresh)
    if changed
      log("[reborn] released player control #{reason} local=#{reborn_local_map_id}") if respond_to?(:log)
    end
    return true
  rescue => e
    log("[reborn] player control release failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_maybe_release_post_train_control!
    return false if !reborn_expansion_id?
    return false if !$game_map || reborn_local_map_id($game_map.map_id) != 37
    if !reborn_post_train_story_complete?
      @reborn_post_train_control_released = false
      return false
    end
    return false if @reborn_post_train_control_released
    return false if reborn_map_interpreter_running?
    return false if $game_player && $game_player.respond_to?(:moving?) && $game_player.moving?
    reborn_release_player_control!("after story completion")
    @reborn_post_train_control_released = true
    return true
  rescue => e
    log("[reborn] post-train deferred release failed: #{e.class}: #{e.message}") if respond_to?(:log)
    @reborn_post_train_control_released = true
    return false
  end

  def reborn_force_player_safe_after_transfer!(previous_map_id = nil)
    return false if !reborn_expansion_id?
    return false if !$game_map || !$game_player
    local_id = reborn_local_map_id($game_map.map_id)
    return false if !REBORN_POST_TRAIN_SAFE_LOCAL_MAPS.include?(local_id)
    raw_previous_map_id = integer(previous_map_id, 0)
    previous_local_id = raw_previous_map_id > 0 ? reborn_local_map_id(previous_map_id) : 0
    from_train_intro = REBORN_TRAIN_SOURCE_LOCAL_MAPS.include?(previous_local_id) || previous_local_id <= 0
    reborn_repair_post_train_intro_switch!(previous_local_id) if from_train_intro

    if from_train_intro && !reborn_post_train_story_complete?
      $game_player.refresh if $game_player.respond_to?(:refresh)
      $game_map.need_refresh = true if $game_map.respond_to?(:need_refresh=)
      log("[reborn] preserving post-train autorun before safe-state release local=#{local_id} previous=#{previous_local_id}") if respond_to?(:log)
      return false
    end

    reborn_release_player_control!("after transfer")
    if from_train_intro && $game_player.respond_to?(:cancelMoveRoute) &&
       (!$game_player.respond_to?(:moving?) || !$game_player.moving?) &&
       (!$game_system || !$game_system.respond_to?(:map_interpreter) ||
        !$game_system.map_interpreter || !$game_system.map_interpreter.running?)
      $game_player.cancelMoveRoute
    end
    Kernel.pbTicketClear(true) if from_train_intro && Kernel.respond_to?(:pbTicketClear)
    reborn_clear_stale_train_interpreter_after_transfer!(previous_map_id) if from_train_intro
    $game_player.refresh if $game_player.respond_to?(:refresh)
    $game_map.need_refresh = true if $game_map.respond_to?(:need_refresh=)
    remember_expansion_anchor(REBORN_EXPANSION_ID, current_anchor) if respond_to?(:remember_expansion_anchor) &&
                                                                     respond_to?(:current_anchor) &&
                                                                     current_anchor
    store_canonical_location("expansion", REBORN_EXPANSION_ID, current_anchor, "reborn_post_train_transfer") if respond_to?(:store_canonical_location) &&
                                                                                                               respond_to?(:current_anchor) &&
                                                                                                               current_anchor
    log("[reborn] forced post-train player safe state local=#{local_id} previous=#{previous_local_id}") if from_train_intro
    return true
  rescue => e
    log("[reborn] post-train safety failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_intro_staging_map?(map_id = nil)
    map_id = reborn_current_map_id if map_id.nil? || integer(map_id, 0) <= 0
    map_id = integer(map_id, 0)
    return false if map_id <= 0
    expansion = current_map_expansion_id(map_id) if respond_to?(:current_map_expansion_id)
    expansion = current_expansion_id if expansion.to_s.empty? && respond_to?(:current_expansion_id)
    return false if expansion.to_s != REBORN_EXPANSION_ID
    return (map_id % 1000) == 51
  rescue
    return false
  end

  def reborn_suppress_static_intro_track_bg?(parameters, map_id = nil)
    return false if !reborn_intro_staging_map?(map_id)
    params = Array(parameters)
    return false if integer(params[0], -1) != 0
    return params[1].to_s.downcase == "introtrackbg"
  rescue
    return false
  end

  def reborn_constants_path
    info = external_projects[REBORN_EXPANSION_ID]
    root = info[:root].to_s if info.is_a?(Hash)
    root = File.join("C:/Games", "Reborn") if root.to_s.empty?
    return nil if root.to_s.empty?
    path = File.join(root, "Scripts", "Reborn", "SystemConstants.rb")
    return path if File.file?(path)
    return nil
  rescue
    return nil
  end

  def reborn_scripts_path
    info = external_projects[REBORN_EXPANSION_ID]
    root = info[:root].to_s if info.is_a?(Hash)
    root = File.join("C:/Games", "Reborn") if root.to_s.empty?
    return nil if root.to_s.empty?
    path = File.join(root, "Scripts", "Reborn", "RebornScripts.rb")
    return path if File.file?(path)
    return nil
  rescue
    return nil
  end

  def reborn_constants_catalog
    @reborn_constants_catalog ||= begin
      path = reborn_constants_path
      catalog = {
        :switches  => {},
        :variables => {},
        :known_trainers => {}
      }
      return catalog if path.nil? || !File.file?(path)
      current_section = nil
      File.readlines(path).each do |line|
        text = line.to_s
        case text
        when /^\s*Switches\s*=\s*\{/
          current_section = :switches
          next
        when /^\s*Variables\s*=\s*\{/
          current_section = :variables
          next
        when /^\s*KNOWN_TRAINERS\s*=\s*\{/
          current_section = :known_trainers
          next
        end
        if current_section && text =~ /^\s*\}/
          current_section = nil
          next
        end
        next if current_section.nil?
        if current_section == :known_trainers
          next if text !~ /^\s*"(.+?)"\s*=>\s*(-?\d+)/
          key = $1.to_s
          value = integer($2, 0)
          next if key.empty? || value <= 0
          catalog[current_section][key] = value
          catalog[current_section][key.to_sym] = value
          next
        end
        next if text !~ /^\s*([A-Za-z0-9_]+)\s*:\s*(-?\d+)/
        key = $1.to_s
        value = integer($2, 0)
        next if key.empty? || value <= 0
        catalog[current_section][key] = value
        catalog[current_section][key.to_sym] = value
      end
      catalog
    end
    return @reborn_constants_catalog
  rescue => e
    log("[reborn] constants catalog load failed: #{e.class}: #{e.message}")
    @reborn_constants_catalog = {
      :switches  => {},
      :variables => {},
      :known_trainers => {}
    }
    return @reborn_constants_catalog
  end

  def reborn_switch_id(identifier)
    value = integer(identifier, 0)
    return value if value > 0
    key = identifier.to_s.sub(/\A:/, "")
    return nil if key.empty?
    return reborn_constants_catalog[:switches][key] || reborn_constants_catalog[:switches][key.to_sym]
  rescue
    return nil
  end

  def reborn_variable_id(identifier)
    value = integer(identifier, 0)
    return value if value > 0
    key = identifier.to_s.sub(/\A:/, "")
    return nil if key.empty?
    return reborn_constants_catalog[:variables][key] || reborn_constants_catalog[:variables][key.to_sym]
  rescue
    return nil
  end

  def reborn_known_trainer_id(identifier)
    value = integer(identifier, 0)
    return value if value > 0
    key = normalize_string(identifier, "")
    return nil if key.empty?
    known = reborn_constants_catalog[:known_trainers]
    return nil if !known.is_a?(Hash)
    return known[key] || known[key.to_sym]
  rescue
    return nil
  end

  def reborn_extract_hash_block(text, constant_name)
    marker = "#{constant_name} = {"
    start_index = text.index(marker)
    return "" if start_index.nil?
    brace_index = text.index("{", start_index)
    return "" if brace_index.nil?
    depth = 0
    index = brace_index
    while index < text.length
      char = text[index]
      depth += 1 if char == "{"
      depth -= 1 if char == "}"
      return text[(brace_index + 1)...index].to_s if depth <= 0
      index += 1
    end
    return ""
  rescue
    return ""
  end

  def reborn_password_catalog
    @reborn_password_catalog ||= begin
      path = reborn_scripts_path
      catalog = {
        :passwords => {},
        :bulk      => {}
      }
      return catalog if path.nil? || !File.file?(path)
      text = File.read(path)
      hash_block = reborn_extract_hash_block(text, "PASSWORD_HASH")
      hash_block.scan(/"([^"]+)"\s*=>\s*(?::([A-Za-z0-9_]+)|(-?\d+))/).each do |key, symbol_name, numeric_id|
        catalog[:passwords][key.to_s.downcase] = symbol_name ? symbol_name.to_sym : integer(numeric_id, 0)
      end
      bulk_block = reborn_extract_hash_block(text, "BULK_PASSWORDS")
      bulk_block.scan(/"([^"]+)"\s*=>\s*\[(.*?)\]/m).each do |key, body|
        catalog[:bulk][key.to_s.downcase] = body.scan(/"([^"]+)"/).flatten.map { |entry| entry.to_s.downcase }
      end
      catalog
    end
    return @reborn_password_catalog
  rescue => e
    log("[reborn] password catalog load failed: #{e.class}: #{e.message}")
    @reborn_password_catalog = {
      :passwords => {},
      :bulk      => {}
    }
    return @reborn_password_catalog
  end

  def reborn_password_switch_id(password)
    entry = password.to_s.downcase.strip
    return nil if entry.empty?
    id = reborn_password_catalog[:passwords][entry]
    return nil if id.nil?
    resolved = reborn_switch_id(id)
    return resolved || id
  rescue
    return nil
  end

  def reborn_set_password_switch(password, value = true)
    switch_id = reborn_password_switch_id(password)
    return false if switch_id.nil? || !$game_switches
    $game_switches[switch_id] = value ? true : false
    return true
  rescue => e
    log("[reborn] password switch set failed for #{password.inspect}: #{e.class}: #{e.message}")
    return false
  end

  def reborn_password_active?(password)
    switch_id = reborn_password_switch_id(password)
    return false if switch_id.nil? || !$game_switches
    return $game_switches[switch_id] ? true : false
  rescue
    return false
  end

  def reborn_add_password(entrytext)
    entry = entrytext.to_s.downcase.strip
    state = state_for(REBORN_EXPANSION_ID) if respond_to?(:state_for)
    if state && state.respond_to?(:metadata) && state.metadata.is_a?(Hash)
      state.metadata["reborn_password_entries"] ||= []
      state.metadata["reborn_password_entries"] << entry if !entry.empty?
      state.metadata["reborn_password_entries"].uniq!
    end
    return false if entry.empty?
    catalog = reborn_password_catalog
    applied = false
    if catalog[:passwords][entry]
      switch_id = reborn_password_switch_id(entry)
      if switch_id && $game_switches
        $game_switches[switch_id] = !$game_switches[switch_id]
        applied = true
      end
    end
    bulk = catalog[:bulk][entry]
    if bulk && !bulk.empty?
      bulk.each { |password| applied = reborn_set_password_switch(password, true) || applied }
    end
    if ["leveloffset", "setlevel", "flatlevel"].include?(entry) && $game_variables
      $game_variables[47] = 1
    elsif ["percentlevel", "levelpercent"].include?(entry) && $game_variables
      $game_variables[47] = 2
    elsif ["exppercent", "expercent"].include?(entry) && $game_variables
      $game_variables[47] = 3
    end
    if reborn_password_active?("fieldapp") && $game_switches
      (599..636).each { |switch_id| $game_switches[switch_id] = true }
    end
    if !applied && $game_switches
      invalid_switch = reborn_switch_id(2037) || 2037
      $game_switches[invalid_switch] = true
    end
    log("[reborn] password #{entry.inspect} #{applied ? "applied" : "ignored/invalid"}")
    return applied
  rescue => e
    log("[reborn] addPassword bridge failed for #{entrytext.inspect}: #{e.class}: #{e.message}")
    return false
  end

  def reborn_legacy_owner(owner)
    return owner if owner.nil?
    return owner if defined?(Pokemon::Owner) && owner.is_a?(Pokemon::Owner)
    return owner if defined?(Player) && owner.is_a?(Player)
    return owner if defined?(NPCTrainer) && owner.is_a?(NPCTrainer)
    if defined?(PokeBattle_Trainer) && owner.is_a?(PokeBattle_Trainer)
      gender = 2
      gender = integer(owner.gender, 2) if owner.respond_to?(:gender)
      language = owner.respond_to?(:language) ? integer(owner.language, 2) : 2
      return Pokemon::Owner.new(integer(owner.id, 0), owner.name.to_s, gender, language)
    end
    if owner.respond_to?(:id) && owner.respond_to?(:name)
      gender = owner.respond_to?(:gender) ? integer(owner.gender, 2) : 2
      language = owner.respond_to?(:language) ? integer(owner.language, 2) : 2
      return Pokemon::Owner.new(integer(owner.id, 0), owner.name.to_s, gender, language)
    end
    return owner
  rescue => e
    log("[reborn] legacy owner conversion failed for #{owner.inspect}: #{e.class}: #{e.message}")
    return owner
  end

  def reborn_build_legacy_pokemon(species, level, owner = $Trainer, with_moves = true, form = nil, recheck_form = true, *_rest)
    effective_owner = reborn_legacy_owner(owner)
    effective_owner = $Trainer if effective_owner.nil?
    pokemon = Pokemon.new(species, integer(level, 1), effective_owner, with_moves != false, recheck_form != false)
    if !form.nil? && form != false
      form_value = integer(form, 0)
      pokemon.forced_form = form_value if pokemon.respond_to?(:forced_form=)
      pokemon.form = form_value if pokemon.respond_to?(:form=)
    end
    return pokemon
  rescue => e
    log("[reborn] legacy pokemon build failed for #{species.inspect}/#{level.inspect}: #{e.class}: #{e.message}")
    raise
  end

  def reborn_default_mart_stock
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
            when 10..12
              [:POKEBALL, :GREATBALL, :ULTRABALL, :SUPERREPEL, :MAXREPEL, :ESCAPEROPE, :FULLHEAL, :HYPERPOTION]
            when 13..16
              [:POKEBALL, :GREATBALL, :ULTRABALL, :SUPERREPEL, :MAXREPEL, :ESCAPEROPE, :FULLHEAL, :ULTRAPOTION]
            when 17
              [:POKEBALL, :GREATBALL, :ULTRABALL, :SUPERREPEL, :MAXREPEL, :ESCAPEROPE, :FULLHEAL, :ULTRAPOTION,
               :MAXPOTION]
            when 18
              [:POKEBALL, :GREATBALL, :ULTRABALL, :SUPERREPEL, :MAXREPEL, :ESCAPEROPE, :FULLHEAL, :HYPERPOTION,
               :ULTRAPOTION, :MAXPOTION, :FULLRESTORE, :REVIVE]
            else
              [:POTION, :ANTIDOTE, :POKEBALL]
            end
    filtered = []
    stock.each do |item|
      next if !GameData::Item.exists?(item)
      next if pbIsImportantItem?(item) && $PokemonBag && $PokemonBag.pbQuantity(item) > 0
      filtered << item
    end
    return filtered
  rescue => e
    log("[reborn] default mart stock build failed: #{e.class}: #{e.message}")
    return [:POTION, :ANTIDOTE, :POKEBALL].find_all { |item| GameData::Item.exists?(item) }
  end

  def reborn_trainer_type_data(identifier)
    symbol_id = external_identifier(identifier)
    return nil if symbol_id.nil?
    return nil if !respond_to?(:external_trainer_catalog)
    catalog = external_trainer_catalog(REBORN_EXPANSION_ID)
    return nil if !catalog.is_a?(Hash)
    types = catalog[:types]
    return nil if !types.is_a?(Hash)
    return types[symbol_id] || types[symbol_id.to_sym] || types[symbol_id.to_s]
  rescue => e
    log("[reborn] trainer type lookup failed for #{identifier.inspect}: #{e.class}: #{e.message}")
    return nil
  end

  def reborn_known_trainer_record(name, preferred_version = 0)
    trainer_name = normalize_string(name, "")
    return nil if trainer_name.empty?
    catalog = external_trainer_catalog(REBORN_EXPANSION_ID)
    return nil if !catalog.is_a?(Hash)
    team_map = catalog[:teams]
    return nil if !team_map.is_a?(Hash)
    version = integer(preferred_version, 0)
    exact = team_map.values.find_all { |entry| entry.is_a?(Hash) && entry[:name] == trainer_name && integer(entry[:version], 0) == version }
    return exact.first if exact.length == 1
    matches = team_map.values.find_all { |entry| entry.is_a?(Hash) && entry[:name] == trainer_name }
    return nil if matches.empty?
    matches.sort_by! { |entry| integer(entry[:version], 0) }
    exact = matches.find { |entry| integer(entry[:version], 0) == version }
    return exact if exact
    return matches.first
  rescue => e
    log("[reborn] knownTrainer record lookup failed for #{name.inspect}/#{preferred_version}: #{e.class}: #{e.message}")
    return nil
  end

  def reborn_known_trainer(name, preferred_version = 0)
    trainer_name = normalize_string(name, "")
    return nil if trainer_name.empty?
    known_id = reborn_known_trainer_id(trainer_name)
    if known_id && defined?(NPCTrainer)
      placeholder_type = TRAINER_HOST_PLACEHOLDER_TYPE
      placeholder_type = :YOUNGSTER if placeholder_type.nil?
      trainer = NPCTrainer.new(trainer_name, placeholder_type)
      trainer.id = known_id if trainer.respond_to?(:id=)
      trainer.party.clear if trainer.respond_to?(:party) && trainer.party.respond_to?(:clear)
      return trainer
    end
    record = reborn_known_trainer_record(trainer_name, preferred_version)
    return nil if !record.is_a?(Hash)
    return load_external_trainer(REBORN_EXPANSION_ID, record[:trainer_type], record[:name], record[:version])
  rescue => e
    log("[reborn] knownTrainer load failed for #{name.inspect}/#{preferred_version}: #{e.class}: #{e.message}")
    return nil
  end

  def play_reborn_trainer_intro_me(identifier)
    data = reborn_trainer_type_data(identifier)
    return false if !data.is_a?(Hash)
    name = data[:intro_ME] || data["intro_ME"] || data[:intro_BGM] || data["intro_BGM"]
    name = normalize_string_or_nil(name) if respond_to?(:normalize_string_or_nil)
    return false if name.to_s.empty?
    bgm = pbStringToAudioFile(name)
    pbMEPlay(bgm) if bgm
    return true
  rescue => e
    log("[reborn] trainer intro ME failed for #{identifier.inspect}: #{e.class}: #{e.message}")
    return false
  end

  def reborn_host_player_name
    name = ""
    name = $Trainer.name.to_s.strip if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:name)
    return name if !name.empty?
    return "Player"
  rescue
    return "Player"
  end

  def reborn_player_gender_label
    if $Trainer
      return _INTL("Non-Binary") if $Trainer.respond_to?(:nonbinary?) && $Trainer.nonbinary?
      return _INTL("Female") if $Trainer.respond_to?(:female?) && $Trainer.female?
      return _INTL("Male") if $Trainer.respond_to?(:male?) && $Trainer.male?
      gender = $Trainer.gender if $Trainer.respond_to?(:gender)
      return _INTL("Non-Binary") if defined?(GENDER_NONBINARY) && gender == GENDER_NONBINARY
      return _INTL("Female") if defined?(GENDER_FEMALE) && gender == GENDER_FEMALE
      return _INTL("Male") if defined?(GENDER_MALE) && gender == GENDER_MALE
    end
    gender_variable = nil
    gender_variable = $game_variables[:Player_Gender] if $game_variables
    return _INTL("Non-Binary") if defined?(GENDER_NONBINARY) && gender_variable == GENDER_NONBINARY
    return _INTL("Female") if defined?(GENDER_FEMALE) && gender_variable == GENDER_FEMALE
    return _INTL("Male")
  rescue
    return "Male"
  end

  def reborn_player_gender_value
    if $Trainer
      return 2 if $Trainer.respond_to?(:nonbinary?) && $Trainer.nonbinary?
      return 1 if $Trainer.respond_to?(:female?) && $Trainer.female?
      return 0 if $Trainer.respond_to?(:male?) && $Trainer.male?
      gender = $Trainer.gender if $Trainer.respond_to?(:gender)
      return 2 if defined?(GENDER_NONBINARY) && gender == GENDER_NONBINARY
      return 1 if defined?(GENDER_FEMALE) && gender == GENDER_FEMALE
      return 0 if defined?(GENDER_MALE) && gender == GENDER_MALE
    end
    gender_variable = nil
    gender_variable = $game_variables[:Player_Gender] if $game_variables
    return 2 if defined?(GENDER_NONBINARY) && gender_variable == GENDER_NONBINARY
    return 1 if defined?(GENDER_FEMALE) && gender_variable == GENDER_FEMALE
    return integer(gender_variable, 0)
  rescue
    return 0
  end

  def reborn_preferred_character_index
    case reborn_player_gender_value
    when 1 then return 2 # Alice
    when 2 then return 6 # Decibel
    else return 1        # Vero
    end
  end

  def reborn_preferred_player_sprite
    case reborn_preferred_character_index
    when 2 then return 1 # Alice
    when 6 then return 9 # Decibel
    else return 0        # Vero
    end
  end

  def reborn_player_sprite_for_character_index(character_index = nil)
    index = integer(character_index, 0)
    index = integer($game_variables[358], reborn_preferred_character_index) if index <= 0 && $game_variables
    case index
    when 2 then return 1 # Alice
    when 3 then return 4 # Kuro
    when 4 then return 5 # Lucia
    when 5 then return 8 # Ari
    when 6 then return 9 # Decibel
    else return 0        # Vero
    end
  rescue
    return reborn_preferred_player_sprite
  end

  def reborn_character_index_for_player_sprite(sprite_id)
    case integer(sprite_id, -1)
    when 1 then return 2 # Alice
    when 4 then return 3 # Kuro
    when 5 then return 4 # Lucia
    when 8 then return 5 # Ari
    when 9 then return 6 # Decibel
    else return 1        # Vero
    end
  rescue
    return reborn_preferred_character_index
  end

  def reborn_remember_intro_character!(sprite_id)
    return false if !$game_variables
    character_index = reborn_character_index_for_player_sprite(sprite_id)
    character_index = reborn_preferred_character_index if character_index <= 0 || character_index > 6
    sprite_value = reborn_player_sprite_for_character_index(character_index)
    gender_value = reborn_gender_for_character_index(character_index)
    sprite_variable = reborn_variable_id(:Player_Sprite) || 176
    gender_variable = reborn_variable_id(:Player_Gender) || 151
    $game_variables[358] = character_index
    $game_variables[sprite_variable] = sprite_value
    $game_variables[gender_variable] = gender_value
    state = state_for(REBORN_EXPANSION_ID) if respond_to?(:state_for)
    if state && state.respond_to?(:metadata) && state.metadata.is_a?(Hash)
      state.metadata["reborn_intro_character_index"] = character_index
      state.metadata["reborn_intro_player_sprite"] = sprite_value
    end
    return true
  rescue => e
    log("[reborn] intro character remember failed for #{sprite_id.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def reborn_gender_for_character_index(character_index = nil)
    index = integer(character_index, 0)
    index = integer($game_variables[358], reborn_preferred_character_index) if index <= 0 && $game_variables
    case index
    when 2, 4 then return 1
    when 5, 6 then return 2
    else return 0
    end
  rescue
    return reborn_player_gender_value
  end

  def reborn_apply_player_id!(variable_id = nil)
    return reborn_preferred_player_sprite if !$game_variables
    reborn_sync_intro_identity!(false)
    character_index = integer($game_variables[358], reborn_preferred_character_index)
    if character_index <= 0 || character_index > 6
      character_index = reborn_preferred_character_index
      $game_variables[358] = character_index
    end
    sprite_id = reborn_player_sprite_for_character_index(character_index)
    gender_id = reborn_gender_for_character_index(character_index)
    target_variable = reborn_variable_id(variable_id)
    target_variable = reborn_variable_id(:Player_Sprite) || 176 if target_variable.nil? || target_variable <= 0
    gender_variable = reborn_variable_id(:Player_Gender) || 151
    $game_variables[target_variable] = sprite_id
    $game_variables[gender_variable] = gender_id
    return sprite_id
  rescue => e
    log("[reborn] pbGetPlayerID bridge failed for #{variable_id.inspect}: #{e.class}: #{e.message}")
    return reborn_preferred_player_sprite
  end

  def reborn_sync_intro_identity!(force = false)
    return false if !$game_variables
    if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:name=)
      host_name = reborn_host_player_name
      $Trainer.name = host_name if $Trainer.name.to_s.strip.empty?
    end
    character_variable = 358
    gender_variable = reborn_variable_id(:Player_Gender) || 151
    sprite_variable = reborn_variable_id(:Player_Sprite) || 176
    preferred_character = reborn_preferred_character_index
    preferred_gender = reborn_player_gender_value
    preferred_sprite = reborn_preferred_player_sprite
    current_character = integer($game_variables[character_variable], 0)
    if current_character <= 0 || current_character > 6
      $game_variables[character_variable] = preferred_character
      current_character = preferred_character
    end
    current_gender = integer($game_variables[gender_variable], -1)
    $game_variables[gender_variable] = preferred_gender if current_gender < 0 || current_gender > 2
    current_sprite = integer($game_variables[sprite_variable], -1)
    valid_sprites = [0, 1, 4, 5, 8, 9]
    $game_variables[sprite_variable] = preferred_sprite if !valid_sprites.include?(current_sprite)
    return true
  rescue => e
    log("[reborn] intro identity sync failed: #{e.class}: #{e.message}")
    return false
  end

  def reborn_game_data_name(data)
    return nil if data.nil?
    [:real_name, :name, :id].each do |method_name|
      next if !data.respond_to?(method_name)
      value = data.send(method_name) rescue nil
      text = value.to_s
      return text if !text.empty?
    end
    return nil
  rescue
    return nil
  end

  def reborn_game_data_description(data)
    return nil if data.nil?
    [:real_description, :description, :desc].each do |method_name|
      next if !data.respond_to?(method_name)
      value = data.send(method_name) rescue nil
      text = value.to_s
      return text if !text.empty?
    end
    return nil
  rescue
    return nil
  end

  def reborn_species_data_for(species, form = 0)
    return nil if !defined?(GameData::Species)
    if species.respond_to?(:species) && species.respond_to?(:species_data)
      data = species.species_data rescue nil
      return data if data
      species = species.species
    end
    resolved = resolve_expansion_species(REBORN_EXPANSION_ID, species) if respond_to?(:resolve_expansion_species)
    resolved = species if resolved.nil?
    form_id = integer(form, 0)
    if GameData::Species.respond_to?(:get_species_form)
      data = GameData::Species.get_species_form(resolved, form_id) rescue nil
      return data if data
    end
    data = GameData::Species.try_get(resolved) rescue nil
    return data if data
    data = GameData::Species.try_get(species) rescue nil
    return data if data
    return nil
  rescue => e
    log("[reborn] species data lookup failed for #{species.inspect}/#{form.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def reborn_legacy_species_name(species, form = 0)
    if species.respond_to?(:speciesName)
      name = species.speciesName rescue nil
      return name.to_s if !name.to_s.empty?
    end
    data = reborn_species_data_for(species, form)
    name = reborn_game_data_name(data)
    return name if name
    return species.to_s
  rescue => e
    log("[reborn] getMonName bridge failed for #{species.inspect}/#{form.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return species.to_s
  end

  def reborn_item_data_for(item)
    return nil if !defined?(GameData::Item)
    resolved = resolve_external_item(item, REBORN_EXPANSION_ID) if respond_to?(:resolve_external_item)
    resolved = item if resolved.nil?
    data = GameData::Item.try_get(resolved) rescue nil
    return data if data
    data = GameData::Item.try_get(item) rescue nil
    return data if data
    return nil
  rescue => e
    log("[reborn] item data lookup failed for #{item.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def reborn_legacy_item_name(item)
    data = reborn_item_data_for(item)
    name = reborn_game_data_name(data)
    return name if name
    return item.to_s
  rescue => e
    log("[reborn] getItemName bridge failed for #{item.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return item.to_s
  end

  def reborn_legacy_item_description(item)
    data = reborn_item_data_for(item)
    description = reborn_game_data_description(data)
    return description if description
    return ""
  rescue => e
    log("[reborn] getItemDescription bridge failed for #{item.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return ""
  end

  def reborn_move_data_for(move)
    return nil if !defined?(GameData::Move)
    resolved = resolve_external_move(move) if respond_to?(:resolve_external_move)
    resolved = move if resolved.nil?
    data = GameData::Move.try_get(resolved) rescue nil
    return data if data
    data = GameData::Move.try_get(move) rescue nil
    return data if data
    return nil
  rescue => e
    log("[reborn] move data lookup failed for #{move.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def reborn_legacy_move_name(move)
    data = reborn_move_data_for(move)
    name = reborn_game_data_name(data)
    return name if name
    return move.to_s
  rescue => e
    log("[reborn] getMoveName bridge failed for #{move.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return move.to_s
  end

  def reborn_ability_data_for(ability)
    return nil if !defined?(GameData::Ability)
    resolved = resolve_external_ability(ability) if respond_to?(:resolve_external_ability)
    resolved = ability if resolved.nil?
    data = GameData::Ability.try_get(resolved) rescue nil
    return data if data
    data = GameData::Ability.try_get(ability) rescue nil
    return data if data
    return nil
  rescue => e
    log("[reborn] ability data lookup failed for #{ability.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def reborn_legacy_ability_name(ability, _short = false)
    data = reborn_ability_data_for(ability)
    name = reborn_game_data_name(data)
    return name if name
    return ability.to_s
  rescue => e
    log("[reborn] getAbilityName bridge failed for #{ability.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return ability.to_s
  end

  def reborn_message_free_text(message, currenttext = "", passwordbox = false, maxlength = 12, width = 240, *_extra, &block)
    if Object.private_method_defined?(:pbMessageFreeText) || Object.method_defined?(:pbMessageFreeText)
      return Object.new.send(:pbMessageFreeText, message, currenttext, passwordbox, maxlength, width, &block)
    end
    if Object.private_method_defined?(:pbEnterText) || Object.method_defined?(:pbEnterText)
      return Object.new.send(:pbEnterText, message, 0, maxlength, currenttext)
    end
    return currenttext.to_s
  rescue => e
    log("[reborn] Kernel.pbMessageFreeText bridge failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return currenttext.to_s
  end

  def reborn_intro_continue_choice_index(commands)
    choices = Array(commands).map { |entry| entry.to_s.strip }
    return nil if choices.empty?
    normalized = choices.map { |entry| entry.downcase }
    return nil if !normalized.include?("keyboard controls")
    return nil if !normalized.include?("gamepad controls")
    continue_index = normalized.index("continue")
    return continue_index if continue_index
    return nil
  rescue
    return nil
  end
end

class Game_Switches
  alias tef_reborn_compat_original_get []
  alias tef_reborn_compat_original_set []=

  def [](switch_id)
    runtime_expansion = TravelExpansionFramework.current_runtime_expansion_id
    expansion_id = runtime_expansion
    expansion_id = TravelExpansionFramework.current_map_expansion_id if expansion_id.nil? || expansion_id.empty?
    if TravelExpansionFramework.reborn_expansion_id?(expansion_id)
      resolved = TravelExpansionFramework.reborn_switch_id(switch_id)
      switch_id = resolved if resolved
      if runtime_expansion.nil? || runtime_expansion.empty?
        return TravelExpansionFramework.with_runtime_context(expansion_id) { tef_reborn_compat_original_get(switch_id) }
      end
    end
    return tef_reborn_compat_original_get(switch_id)
  end

  def []=(switch_id, value)
    runtime_expansion = TravelExpansionFramework.current_runtime_expansion_id
    expansion_id = runtime_expansion
    expansion_id = TravelExpansionFramework.current_map_expansion_id if expansion_id.nil? || expansion_id.empty?
    reborn_context = TravelExpansionFramework.reborn_expansion_id?(expansion_id)
    if reborn_context
      resolved = TravelExpansionFramework.reborn_switch_id(switch_id)
      switch_id = resolved if resolved
    end
    result = if reborn_context && (runtime_expansion.nil? || runtime_expansion.empty?)
               TravelExpansionFramework.with_runtime_context(expansion_id) { tef_reborn_compat_original_set(switch_id, value) }
             else
               tef_reborn_compat_original_set(switch_id, value)
             end
    if value && reborn_context &&
       TravelExpansionFramework.reborn_post_train_completion_switch?(switch_id) &&
       TravelExpansionFramework.reborn_post_train_completion_context?
      TravelExpansionFramework.reborn_record_post_train_greeting_complete!("map37_event1_switch")
    end
    return result
  end
end

class Game_Variables
  alias tef_reborn_compat_original_get []
  alias tef_reborn_compat_original_set []=

  def [](variable_id)
    runtime_expansion = TravelExpansionFramework.current_runtime_expansion_id
    expansion_id = runtime_expansion
    expansion_id = TravelExpansionFramework.current_map_expansion_id if expansion_id.nil? || expansion_id.empty?
    if TravelExpansionFramework.reborn_expansion_id?(expansion_id)
      resolved = TravelExpansionFramework.reborn_variable_id(variable_id)
      variable_id = resolved if resolved
      if runtime_expansion.nil? || runtime_expansion.empty?
        return TravelExpansionFramework.with_runtime_context(expansion_id) { tef_reborn_compat_original_get(variable_id) }
      end
    end
    return tef_reborn_compat_original_get(variable_id)
  end

  def []=(variable_id, value)
    runtime_expansion = TravelExpansionFramework.current_runtime_expansion_id
    expansion_id = runtime_expansion
    expansion_id = TravelExpansionFramework.current_map_expansion_id if expansion_id.nil? || expansion_id.empty?
    if TravelExpansionFramework.reborn_expansion_id?(expansion_id)
      resolved = TravelExpansionFramework.reborn_variable_id(variable_id)
      variable_id = resolved if resolved
      if runtime_expansion.nil? || runtime_expansion.empty?
        return TravelExpansionFramework.with_runtime_context(expansion_id) { tef_reborn_compat_original_set(variable_id, value) }
      end
    end
    return tef_reborn_compat_original_set(variable_id, value)
  end
end

class Player::Pokedex
  def canViewDex
    if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:pokedex) && $Trainer.pokedex.equal?(self)
      return $Trainer.has_pokedex ? true : false
    end
    return @tef_reborn_can_view_dex ? true : false
  end

  def canViewDex=(value)
    @tef_reborn_can_view_dex = value ? true : false
    if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:pokedex) && $Trainer.pokedex.equal?(self) &&
       $Trainer.respond_to?(:has_pokedex=)
      $Trainer.has_pokedex = @tef_reborn_can_view_dex
    end
    return @tef_reborn_can_view_dex
  end
end

class Player
  def pokegear
    return self.has_pokegear ? true : false
  end

  def pokegear=(value)
    self.has_pokegear = value ? true : false
    return self.has_pokegear
  end

  # Reborn event scripts often call the older camelCase helper names directly
  # on the live Player object instead of only through Trainer.
  def pokemonParty
    return pokemon_party
  end

  def ablePokemonParty
    return able_party
  end

  def partyCount
    return party_count
  end

  def pokemonCount
    return pokemon_count
  end

  def ablePokemonCount
    return able_pokemon_count
  end

  def firstParty
    return first_party
  end

  def firstPokemon
    return first_pokemon
  end

  def firstAblePokemon
    return first_able_pokemon
  end

  def lastParty
    return last_party
  end

  def lastPokemon
    return last_pokemon
  end

  def lastAblePokemon
    return last_able_pokemon
  end
end

class Trainer
  # Reborn event scripts still call the old camelCase trainer party helpers.
  def pokemonParty
    return pokemon_party
  end

  def ablePokemonParty
    return able_party
  end

  def partyCount
    return party_count
  end

  def pokemonCount
    return pokemon_count
  end

  def ablePokemonCount
    return able_pokemon_count
  end

  def firstParty
    return first_party
  end

  def firstPokemon
    return first_pokemon
  end

  def firstAblePokemon
    return first_able_pokemon
  end

  def lastParty
    return last_party
  end

  def lastPokemon
    return last_pokemon
  end

  def lastAblePokemon
    return last_able_pokemon
  end
end

class PokemonStorage
  def upTotalBoxes(newtotal)
    target = TravelExpansionFramework.integer(newtotal, self.maxBoxes)
    return self.maxBoxes if target <= self.maxBoxes
    while @boxes.length < target
      boxnum = @boxes.length + 1
      @boxes[boxnum - 1] = PokemonBox.new(_INTL("Box {1}", boxnum), PokemonBox::BOX_SIZE)
      @boxes[boxnum - 1].background = (boxnum - 1) % BASICWALLPAPERQTY
    end
    return self.maxBoxes
  end
end

class RegionalStorage
  def upTotalBoxes(newtotal)
    return getCurrentStorage.upTotalBoxes(newtotal)
  end
end

def pbDefaultMart(speech = nil, cantsell = false)
  return nil if !TravelExpansionFramework.reborn_expansion_id?
  stock = TravelExpansionFramework.reborn_default_mart_stock
  return pbPokemonMart(stock, speech, cantsell)
end

def getMonName(species, form = 0)
  return TravelExpansionFramework.reborn_legacy_species_name(species, form)
end

def getItemName(item)
  return TravelExpansionFramework.reborn_legacy_item_name(item)
end

def getItemDescription(item)
  return TravelExpansionFramework.reborn_legacy_item_description(item)
end

def getMoveName(move)
  return TravelExpansionFramework.reborn_legacy_move_name(move)
end

def getMoveShortName(move)
  return TravelExpansionFramework.reborn_legacy_move_name(move)
end

def getAbilityName(ability, short = false)
  return TravelExpansionFramework.reborn_legacy_ability_name(ability, short)
end

module Kernel
  class << self
    alias tef_reborn_original_pbMessageFreeText pbMessageFreeText if method_defined?(:pbMessageFreeText) &&
                                                                     !method_defined?(:tef_reborn_original_pbMessageFreeText)

    def pbMessageFreeText(message, currenttext = "", passwordbox = false, maxlength = 12, width = 240, *extra, &block)
      if TravelExpansionFramework.reborn_expansion_id? || !respond_to?(:tef_reborn_original_pbMessageFreeText)
        return TravelExpansionFramework.reborn_message_free_text(message, currenttext, passwordbox, maxlength, width, *extra, &block)
      end
      return tef_reborn_original_pbMessageFreeText(message, currenttext, passwordbox, maxlength, width, *extra, &block)
    end

    def getMonName(species, form = 0)
      return TravelExpansionFramework.reborn_legacy_species_name(species, form)
    end

    def getItemName(item)
      return TravelExpansionFramework.reborn_legacy_item_name(item)
    end

    def getItemDescription(item)
      return TravelExpansionFramework.reborn_legacy_item_description(item)
    end

    def getMoveName(move)
      return TravelExpansionFramework.reborn_legacy_move_name(move)
    end

    def getMoveShortName(move)
      return TravelExpansionFramework.reborn_legacy_move_name(move)
    end

    def getAbilityName(ability, short = false)
      return TravelExpansionFramework.reborn_legacy_ability_name(ability, short)
    end
  end

  def self.tef_reborn_tts(text)
    message = text.to_s.strip
    TravelExpansionFramework.log("[reborn] TTS skipped: #{message}") if !message.empty?
    return true
  rescue
    return true
  end

  def self.tts(text)
    return tef_reborn_tts(text)
  end

  def self.rebornIntroTTS(start = false)
    TravelExpansionFramework.reborn_sync_intro_identity!(start == true)
    names = ["Vero", "Alice", "Kuro", "Lucia", "Ari", "Decibel"]
    index = 0
    index = TravelExpansionFramework.integer($game_variables[358], 1) - 1 if $game_variables
    index = 0 if index < 0
    index = names.length - 1 if index >= names.length
    tts("Select your player character:") if start
    tts(names[index])
    return true
  rescue => e
    TravelExpansionFramework.log("[reborn] rebornIntroTTS failed: #{e.class}: #{e.message}")
    return true
  end

  def self.pbGetPlayerID(variable_id = nil)
    return TravelExpansionFramework.reborn_apply_player_id!(variable_id)
  end

  def self.addPassword(entrytext)
    return TravelExpansionFramework.reborn_add_password(entrytext)
  end

  def self.pbBridgeOn
    return true
  end

  def self.pbBridgeOff
    return true
  end

  def self.pbTicketViewport
    TravelExpansionFramework.reborn_sync_intro_identity!(false)
    pbTicketClear(false)
    @tef_reborn_ticket_viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @tef_reborn_ticket_viewport.z = 99_999
    @tef_reborn_ticket_sprites = {}
    return @tef_reborn_ticket_viewport
  rescue => e
    TravelExpansionFramework.log("[reborn] pbTicketViewport failed: #{e.class}: #{e.message}")
    return nil
  end

  def self.pbTicketText(textno)
    return nil if !TravelExpansionFramework.reborn_expansion_id?
    TravelExpansionFramework.reborn_sync_intro_identity!(false)
    @tef_reborn_ticket_sprites ||= {}
    @tef_reborn_ticket_viewport ||= Viewport.new(0, 0, Graphics.width, Graphics.height)
    @tef_reborn_ticket_viewport.z = 99_999 if @tef_reborn_ticket_viewport.respond_to?(:z=)
    overlay_sprite = @tef_reborn_ticket_sprites["overlay"]
    if overlay_sprite.nil? || (overlay_sprite.respond_to?(:disposed?) && overlay_sprite.disposed?)
      overlay_sprite = BitmapSprite.new(Graphics.width, Graphics.height, @tef_reborn_ticket_viewport)
      @tef_reborn_ticket_sprites["overlay"] = overlay_sprite
    end
    overlay = overlay_sprite.bitmap
    return nil if overlay.nil?
    player_name = ($Trainer && $Trainer.respond_to?(:name)) ? $Trainer.name.to_s : "Player"
    player_gender = TravelExpansionFramework.reborn_player_gender_label
    base_color = Color.new(78, 66, 66)
    shadow_color = Color.new(159, 150, 144)
    text_positions = [
      [player_name, (Graphics.width / 2) - 143, 198, 0, base_color, shadow_color],
      [player_gender, (Graphics.width / 2) + 26, 198, 0, base_color, shadow_color],
      ["8R750", (Graphics.width / 2) - 83, 221, 0, base_color, shadow_color],
      ["5D", (Graphics.width / 2) + 98, 221, 0, base_color, shadow_color],
      ["Grandview Station", (Graphics.width / 2) - 73, 248, 0, base_color, shadow_color],
      ["ONE", (Graphics.width / 2) - 60, 273, 0, base_color, shadow_color],
      ["SGL", (Graphics.width / 2) + 98, 273, 0, base_color, shadow_color]
    ]
    index = TravelExpansionFramework.integer(textno, 0)
    entry = text_positions[index]
    return nil if entry.nil?
    overlay.font.name = "PokemonEmerald" if overlay.respond_to?(:font) && overlay.font
    overlay.font.size = 36 if overlay.respond_to?(:font) && overlay.font
    pbDrawTextPositions(overlay, [entry])
    return true
  rescue => e
    TravelExpansionFramework.log("[reborn] pbTicketText failed for #{textno.inspect}: #{e.class}: #{e.message}")
    return nil
  end

  def self.pbTicketClear(dispose_viewport = true)
    pbDisposeSpriteHash(@tef_reborn_ticket_sprites) if defined?(pbDisposeSpriteHash) && @tef_reborn_ticket_sprites
    @tef_reborn_ticket_sprites = {}
    if dispose_viewport && @tef_reborn_ticket_viewport
      @tef_reborn_ticket_viewport.dispose if @tef_reborn_ticket_viewport.respond_to?(:dispose) &&
                                             !(@tef_reborn_ticket_viewport.respond_to?(:disposed?) && @tef_reborn_ticket_viewport.disposed?)
      @tef_reborn_ticket_viewport = nil
    end
    return true
  rescue => e
    TravelExpansionFramework.log("[reborn] pbTicketClear failed: #{e.class}: #{e.message}")
    @tef_reborn_ticket_sprites = {}
    @tef_reborn_ticket_viewport = nil if dispose_viewport
    return false
  end
end

if !(Kernel.method_defined?(:tts) || Kernel.private_method_defined?(:tts))
  module Kernel
    def tts(text)
      return Kernel.tts(text)
    end
  end
end

if !(Kernel.method_defined?(:rebornIntroTTS) || Kernel.private_method_defined?(:rebornIntroTTS))
  module Kernel
    def rebornIntroTTS(start = false)
      return Kernel.rebornIntroTTS(start)
    end
  end
end

if !(Kernel.method_defined?(:pbGetPlayerID) || Kernel.private_method_defined?(:pbGetPlayerID))
  module Kernel
    def pbGetPlayerID(variable_id = nil)
      return Kernel.pbGetPlayerID(variable_id)
    end
  end
end

if !(Kernel.method_defined?(:addPassword) || Kernel.private_method_defined?(:addPassword))
  module Kernel
    def addPassword(entrytext)
      return Kernel.addPassword(entrytext)
    end
  end
end

if defined?(Scene_Map)
  class Scene_Map
    alias tef_reborn_original_update update unless method_defined?(:tef_reborn_original_update)

    def update
      result = tef_reborn_original_update
      TravelExpansionFramework.reborn_maybe_release_post_train_control!
      return result
    end
  end
end

if defined?(pbTrainerName) && !defined?(tef_reborn_original_pbTrainerName)
  alias tef_reborn_original_pbTrainerName pbTrainerName

  def pbTrainerName(name = nil, outfit = 0)
    if TravelExpansionFramework.reborn_expansion_id?
      chosen_name = TravelExpansionFramework.reborn_host_player_name
      chosen_name = name.to_s.strip if chosen_name.empty? && !name.nil?
      chosen_name = "Player" if chosen_name.empty?
      if defined?($Trainer) && $Trainer
        $Trainer.name = chosen_name if $Trainer.respond_to?(:name=)
        $Trainer.outfit = outfit if $Trainer.respond_to?(:outfit=)
      end
      $PokemonTemp.begunNewGame = true if defined?($PokemonTemp) && $PokemonTemp && $PokemonTemp.respond_to?(:begunNewGame=)
      TravelExpansionFramework.reborn_sync_intro_identity!(true)
      TravelExpansionFramework.log("[reborn] intro trainer name auto-filled as #{chosen_name.inspect}") if TravelExpansionFramework.respond_to?(:log)
      return true
    end
    return tef_reborn_original_pbTrainerName(name, outfit)
  end
end

if defined?(pbChangePlayer) && !defined?(tef_reborn_original_pbChangePlayer)
  alias tef_reborn_original_pbChangePlayer pbChangePlayer

  def pbChangePlayer(id, *args)
    if TravelExpansionFramework.reborn_expansion_id?
      TravelExpansionFramework.reborn_remember_intro_character!(id)
      if defined?($game_player) && $game_player
        $game_player.refresh if $game_player.respond_to?(:refresh)
      end
      TravelExpansionFramework.log("[reborn] accepted intro character #{id.inspect} without changing host overworld sprite") if TravelExpansionFramework.respond_to?(:log)
      return true
    end
    return tef_reborn_original_pbChangePlayer(id, *args)
  end
end

class DefaultKeyboardControlsScene
  def initialize(*_args); end

  def pbRender(*_args)
    TravelExpansionFramework.log("[reborn] skipped Reborn keyboard controls scene") if defined?(TravelExpansionFramework) &&
                                                                                       TravelExpansionFramework.respond_to?(:log)
    return true
  end
end if !defined?(DefaultKeyboardControlsScene)

class DefaultGamepadControlsScene
  def initialize(*_args); end

  def pbRender(*_args)
    TravelExpansionFramework.log("[reborn] skipped Reborn gamepad controls scene") if defined?(TravelExpansionFramework) &&
                                                                                     TravelExpansionFramework.respond_to?(:log)
    return true
  end
end if !defined?(DefaultGamepadControlsScene)

if defined?(Interpreter)
  class Interpreter
    DefaultKeyboardControlsScene = ::DefaultKeyboardControlsScene if !const_defined?(:DefaultKeyboardControlsScene) &&
                                                                     defined?(::DefaultKeyboardControlsScene)
    DefaultGamepadControlsScene = ::DefaultGamepadControlsScene if !const_defined?(:DefaultGamepadControlsScene) &&
                                                                   defined?(::DefaultGamepadControlsScene)

    alias tef_reborn_original_command_204 command_204 unless method_defined?(:tef_reborn_original_command_204)
    alias tef_reborn_original_command_102 command_102 unless method_defined?(:tef_reborn_original_command_102)

    def command_204
      parameters = @parameters
      parameters = @list[@index].parameters if (parameters.nil? || parameters.empty?) && @list && @list[@index]
      if TravelExpansionFramework.reborn_suppress_static_intro_track_bg?(parameters, @map_id)
        if defined?($game_map) && $game_map
          $game_map.panorama_name = "" if $game_map.respond_to?(:panorama_name=)
          $game_map.panorama_hue = 0 if $game_map.respond_to?(:panorama_hue=)
        end
        TravelExpansionFramework.log("[reborn] suppressed static introTrackBg panorama on boarding-pass staging map") if TravelExpansionFramework.respond_to?(:log)
        return true
      end
      return tef_reborn_original_command_204
    end

    def command_102
      if TravelExpansionFramework.reborn_expansion_id?
        commands = (@list[@index].parameters[0] rescue nil)
        auto_choice = TravelExpansionFramework.reborn_intro_continue_choice_index(commands)
        if !auto_choice.nil?
          tef_ensure_branch_state! if respond_to?(:tef_ensure_branch_state!)
          @message_waiting = false
          @branch ||= {}
          @branch[@list[@index].indent] = auto_choice
          Input.update
          TravelExpansionFramework.reborn_sync_intro_identity!(true)
          TravelExpansionFramework.log("[reborn] auto-selected Continue for controls menu #{Array(commands).inspect}") if TravelExpansionFramework.respond_to?(:log)
          return true
        end
      end
      return tef_reborn_original_command_102
    end

    def rebornIntroTTS(start = false)
      return Kernel.rebornIntroTTS(start)
    end

    def tts(text)
      return Kernel.tts(text)
    end

    def pbGetPlayerID(variable_id = nil)
      return Kernel.pbGetPlayerID(variable_id)
    end

    def addPassword(entrytext)
      return Kernel.addPassword(entrytext)
    end
  end
end

def pbBridgeOn
  return Kernel.pbBridgeOn
end

def pbBridgeOff
  return Kernel.pbBridgeOff
end

def pbTicketViewport
  return Kernel.pbTicketViewport
end

def pbTicketText(textno)
  return Kernel.pbTicketText(textno)
end

def pbTicketClear
  return Kernel.pbTicketClear
end

def pbGetPlayerID(variable_id = nil)
  return Kernel.pbGetPlayerID(variable_id)
end

def addPassword(entrytext)
  return Kernel.addPassword(entrytext)
end

def knownTrainer(name, version = 0)
  return nil if !TravelExpansionFramework.reborn_expansion_id?
  trainer = TravelExpansionFramework.reborn_known_trainer(name, version)
  return trainer if trainer
  raise _INTL("Reborn trainer {1} could not be resolved.", name.to_s)
end

if defined?(PokeBattle_Pokemon)
  class << PokeBattle_Pokemon
    def new(*args)
      if TravelExpansionFramework.reborn_expansion_id?
        return TravelExpansionFramework.reborn_build_legacy_pokemon(*args)
      end
      super(*args)
    end
  end
end

def belongsTo(pkmn, name)
  return false if !TravelExpansionFramework.reborn_expansion_id?
  return false if pkmn.nil? || !pkmn.respond_to?(:trainerID)
  known_id = TravelExpansionFramework.reborn_known_trainer_id(name)
  return false if known_id.nil?
  return pkmn.trainerID == known_id
end

alias tef_reborn_original_pbPlayTrainerIntroME pbPlayTrainerIntroME unless defined?(tef_reborn_original_pbPlayTrainerIntroME)
def pbPlayTrainerIntroME(trainer_type)
  if TravelExpansionFramework.reborn_expansion_id?
    normalized = TravelExpansionFramework.external_identifier(trainer_type) rescue trainer_type
    if normalized && !GameData::TrainerType.exists?(normalized)
      TravelExpansionFramework.play_reborn_trainer_intro_me(normalized)
      return
    end
  end
  return tef_reborn_original_pbPlayTrainerIntroME(trainer_type)
end

alias tef_reborn_original_pbGetTrainerBattleBGMFromType pbGetTrainerBattleBGMFromType unless defined?(tef_reborn_original_pbGetTrainerBattleBGMFromType)
def pbGetTrainerBattleBGMFromType(trainertype)
  if TravelExpansionFramework.reborn_expansion_id?
    data = TravelExpansionFramework.reborn_trainer_type_data(trainertype)
    if data.is_a?(Hash)
      music = TravelExpansionFramework.normalize_string_or_nil(data[:battle_BGM] || data["battle_BGM"])
      return pbStringToAudioFile(music) if music
    end
  end
  return tef_reborn_original_pbGetTrainerBattleBGMFromType(trainertype)
end

class Interpreter
  alias tef_reborn_original_pbTrainerIntro pbTrainerIntro unless method_defined?(:tef_reborn_original_pbTrainerIntro)

  def pbTrainerIntro(symbol)
    if TravelExpansionFramework.reborn_expansion_id?
      normalized = TravelExpansionFramework.external_identifier(symbol) rescue symbol
      if normalized && GameData::TrainerType.exists?(normalized)
        return tef_reborn_original_pbTrainerIntro(normalized)
      end
      pbGlobalLock
      TravelExpansionFramework.play_reborn_trainer_intro_me(normalized || symbol)
      return true
    end
    return tef_reborn_original_pbTrainerIntro(symbol)
  end
end

def pbMonoRandEvents
  return nil if !TravelExpansionFramework.reborn_expansion_id?
  eventarray = []
  mixpokemon = []
  mixegg = []
  mixonyx = []
  dollevent = []
  mixsnufful = []
  mixturtmor = []
  mixslums = []
  mixmalchous = []
  mixtrade = []
  actuallypanpour = []
  mixperidot = []
  mixtrain = []
  variablearray = [50, 228, 229, 231, 351, 352, 353, 354, 355, 803, 356, 357]
  if $game_switches[1193]
    mixegg.push(17)
    mixmalchous.push(1)
  end
  if $game_switches[1197]
    mixegg.push(4, 9)
    mixtrain.push(2)
  end
  if $game_switches[1196]
    mixegg.push(7, 11)
    mixturtmor.push(1)
  end
  if $game_switches[1186]
    mixpokemon.push(2)
    mixegg.push(14)
  end
  if $game_switches[1199]
    mixegg.push(0, 3, 8, 12)
    mixsnufful.push(0)
    mixtrade.push(1, 4)
  end
  if $game_switches[1183]
    mixegg.push(10, 13, 17)
    actuallypanpour.push(0)
  end
  if $game_switches[1188]
    mixegg.push(5)
    mixsnufful.push(1)
  end
  if $game_switches[1192]
    mixegg.push(3, 15)
    mixslums.push(1)
    mixmalchous.push(1)
  end
  if $game_switches[1195]
    mixegg.push(6, 10)
    mixonyx.push(6)
    dollevent.push(2)
    mixmalchous.push(1)
  end
  if $game_switches[1185]
    mixegg.push(5, 12)
    mixmalchous.push(2, 3)
  end
  if $game_switches[1189]
    mixperidot.push(3)
    mixegg.push(11)
    dollevent.push(0, 2)
  end
  if $game_switches[1187]
    mixperidot.push(3)
    mixegg.push(4, 8)
    mixonyx.push(2, 4)
    mixtrade.push(2)
    mixperidot.push(3)
  end
  if $game_switches[1182]
    mixpokemon.push(1)
    mixegg.push(15)
    mixsnufful.push(1)
    mixmalchous.push(2, 4)
    mixtrade.push(3)
    mixperidot.push(2)
  end
  if $game_switches[1190]
    mixegg.push(1, 6)
  end
  if $game_switches[1194]
    mixperidot.push(1)
    mixegg.push(2)
    mixslums.push(2, 3)
    dollevent.push(0)
    mixmalchous.push(4)
    mixtrade.push(1)
  end
  if $game_switches[1191]
    mixperidot.push(4)
    mixegg.push(16)
    mixtrade.push(4)
    mixperidot.push(4)
  end
  if $game_switches[1198]
    mixperidot.push(4)
    mixegg.push(9)
    mixslums.push(3)
  end
  if $game_switches[1184]
    mixegg.push(0, 1, 2)
    mixslums.push(1)
    actuallypanpour.push(1)
  end
  if $game_switches[:NB_Pokemon_Only]
    mixperidot.push(1)
    mixmalchous.push(1)
    dollevent.push(0, 2)
    mixslums.push(3)
    mixtrade.push(2, 4)
  end
  eventarray.push(mixpokemon, mixegg, mixonyx, dollevent, mixsnufful, mixturtmor, mixslums, mixmalchous, mixtrade, actuallypanpour, mixperidot, mixtrain)
  for i in 0...eventarray.length
    j = eventarray[i]
    var = variablearray[i]
    next if j.length == 0
    j.uniq!
    randevent = j.length > 1 ? rand(j.length) : 0
    if i == 9
      $game_switches[var] = (j[randevent] != 0)
    else
      $game_variables[var] = j[randevent]
    end
  end
  return true
end
