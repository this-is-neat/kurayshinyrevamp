module TravelExpansionFramework
  module_function

  HOST_UTILITY_CHARACTER_BITMAPS = %w[shadow base_surf base_dive surf_offset].freeze
  HOST_UI_BITMAPS = %w[
    graphics/pictures/types
    graphics/pictures/types2
    graphics/pictures/types_display
    graphics/pictures/battle/ability_bar
    graphics/pictures/battle/cursor_command
    graphics/pictures/battle/cursor_command_darkmode
    graphics/pictures/battle/cursor_command_m2
    graphics/pictures/battle/cursor_fight
    graphics/pictures/battle/cursor_mega
    graphics/pictures/battle/cursor_shift
    graphics/pictures/battle/cursor_target
    graphics/pictures/battle/databox_normal
    graphics/pictures/battle/databox_normal_foe
    graphics/pictures/battle/databox_safari
    graphics/pictures/battle/databox_thin
    graphics/pictures/battle/databox_thin_foe
    graphics/pictures/battle/icon_ball
    graphics/pictures/battle/icon_ball_empty
    graphics/pictures/battle/icon_ball_faint
    graphics/pictures/battle/icon_ball_status
    graphics/pictures/battle/icon_mega
    graphics/pictures/battle/icon_numbers
    graphics/pictures/battle/icon_own
    graphics/pictures/battle/icon_primal_groudon
    graphics/pictures/battle/icon_primal_kyogre
    graphics/pictures/battle/icon_statuses
    graphics/pictures/battle/overlay_command
    graphics/pictures/battle/overlay_command_darkmode
    graphics/pictures/battle/overlay_command_m2
    graphics/pictures/battle/overlay_exp
    graphics/pictures/battle/overlay_fight
    graphics/pictures/battle/overlay_hp
    graphics/pictures/battle/overlay_lineup
    graphics/pictures/battle/overlay_lv
    graphics/pictures/battle/overlay_message
    graphics/pictures/battle/overlay_message_darkmode
    graphics/pictures/battle/overlay_message_m2
    graphics/pictures/battle/typessmall
    graphics/ebdx/pictures/ui/abilitymessage
    graphics/ebdx/pictures/ui/barcolors
    graphics/ebdx/pictures/ui/battleboxowned
    graphics/ebdx/pictures/ui/btncmd
    graphics/ebdx/pictures/ui/btnempty
    graphics/ebdx/pictures/ui/category
    graphics/ebdx/pictures/ui/cmdsel
    graphics/ebdx/pictures/ui/cmdsel2
    graphics/ebdx/pictures/ui/containers
    graphics/ebdx/pictures/ui/containersboss
    graphics/ebdx/pictures/ui/databox
    graphics/ebdx/pictures/ui/databoxboss
    graphics/ebdx/pictures/ui/databoxlight
    graphics/ebdx/pictures/ui/lightbar
    graphics/ebdx/pictures/ui/megabutton
    graphics/ebdx/pictures/ui/moveselbuttons
    graphics/ebdx/pictures/ui/partyballs
    graphics/ebdx/pictures/ui/partybar
    graphics/ebdx/pictures/ui/pause
    graphics/ebdx/pictures/ui/safaribar
    graphics/ebdx/pictures/ui/skin1
    graphics/ebdx/pictures/ui/skin2
    graphics/ebdx/pictures/ui/status
    graphics/ebdx/pictures/ui/symmega
    graphics/ebdx/pictures/ui/types
    graphics/ebdx/pictures/ui/types2
  ].freeze unless const_defined?(:HOST_UI_BITMAPS)
  AUDIO_EXTENSIONS = ["", ".ogg", ".mp3", ".wav", ".mid", ".midi", ".wma"].freeze if !const_defined?(:AUDIO_EXTENSIONS)

  def current_asset_expansion_id
    expansion = @rendering_expansion_id
    expansion = current_runtime_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_runtime_expansion_id)
    if (expansion.nil? || expansion.to_s.empty?) && $game_map
      map_id = $game_map.respond_to?(:map_id) ? $game_map.map_id : nil
      direct_expansion = direct_map_expansion_id(map_id) if respond_to?(:direct_map_expansion_id)
      expansion = direct_expansion if (expansion.nil? || expansion.to_s.empty?) && !direct_expansion.to_s.empty?
      if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:visual_expansion_id_for_map)
        # Host maps can share common tileset/autotile names with imported games.
        # Only use visual guessing for reserved expansion maps that lack a direct owner.
        reserved_start = defined?(RESERVED_MAP_BLOCK_START) ? RESERVED_MAP_BLOCK_START : 20_000
        expansion = visual_expansion_id_for_map($game_map) if map_id.to_i >= reserved_start
      end
    end
    expansion = current_map_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_map_expansion_id)
    expansion = current_expansion_id if (expansion.nil? || expansion.to_s.empty?) && !$game_map && respond_to?(:current_expansion_id)
    expansion = expansion.to_s
    return nil if expansion.empty?
    return expansion
  end

  def runtime_asset_log_cache
    @runtime_asset_log_cache ||= {}
    return @runtime_asset_log_cache
  end

  def log_runtime_asset_once(expansion_id, kind, name, detail)
    expansion = expansion_id.to_s
    return if expansion.empty?
    key = [expansion, kind.to_s, name.to_s, detail.to_s].join("|")
    return if runtime_asset_log_cache[key]
    runtime_asset_log_cache[key] = true
    log("[#{expansion}] #{kind}: #{name} => #{detail}")
  end

  def asset_roots
    current_expansion = current_asset_expansion_id
    return [] if current_expansion.nil? || current_expansion.to_s.empty?
    return Array(registry(:assets)[current_expansion]).uniq
  end

  def host_ui_bitmap_path(logical_path, extensions = [])
    return nil if current_asset_expansion_id.to_s.empty?
    normalized = logical_path.to_s.gsub("\\", "/").sub(/\A\.\//, "").sub(%r{\A/+}, "")
    return nil if normalized.empty? || absolute_path?(normalized)
    extname = File.extname(normalized)
    base = normalized
    base = base[0...-extname.length] if !extname.empty?
    return nil if !HOST_UI_BITMAPS.include?(base.downcase)
    candidates = []
    candidates << normalized if !extname.empty?
    exts = extensions.is_a?(Array) ? extensions : [extensions]
    exts = [".png", ".gif", ".jpg", ".jpeg", ".bmp"] if exts.empty? || exts.all? { |ext| ext.to_s.empty? }
    exts.each do |ext|
      ext = ext.to_s
      next if ext.empty?
      candidates << "#{base}#{ext}"
    end
    candidates.uniq.each do |candidate|
      existing = runtime_existing_path(candidate)
      return existing if existing
    end
    return nil
  rescue
    return nil
  end

  def with_rendering_expansion(expansion_id)
    previous = @rendering_expansion_id
    @rendering_expansion_id = expansion_id.to_s
    return yield
  ensure
    @rendering_expansion_id = previous
  end

  def unlock_active_event_context
    return if !$game_system || !$game_system.respond_to?(:map_interpreter)
    interpreter = $game_system.map_interpreter
    return if !interpreter
    event_id = interpreter.instance_variable_get(:@event_id) rescue 0
    return if integer(event_id, 0) <= 0
    return if !$game_map || !$game_map.respond_to?(:events)
    event = $game_map.events[event_id]
    return if !event || !event.respond_to?(:unlock)
    event.unlock
  rescue
  end

  def interpreter_context_map_id(interpreter)
    return 0 if !interpreter
    map_id = interpreter.instance_variable_get(:@map_id) rescue 0
    return integer(map_id, 0)
  rescue
    return 0
  end

  def interpreter_context_event_id(interpreter)
    return 0 if !interpreter
    event_id = interpreter.instance_variable_get(:@event_id) rescue 0
    return integer(event_id, 0)
  rescue
    return 0
  end

  def interpreter_context_expansion_id(interpreter)
    return nil if !interpreter
    expansion_id = nil
    expansion_id = interpreter.tef_expansion_id if interpreter.respond_to?(:tef_expansion_id)
    expansion_id = interpreter.instance_variable_get(:@tef_expansion_id) if expansion_id.to_s.empty?
    map_id = interpreter_context_map_id(interpreter)
    expansion_id = current_map_expansion_id(map_id) if expansion_id.to_s.empty? && map_id > 0
    return nil if expansion_id.to_s.empty?
    return expansion_id.to_s
  rescue
    return nil
  end

  def expansion_context_ids_match?(left, right)
    left_id = left.to_s
    right_id = right.to_s
    return false if left_id.empty? || right_id.empty?
    return true if left_id == right_id
    if respond_to?(:canonical_new_project_id)
      return canonical_new_project_id(left_id).to_s == canonical_new_project_id(right_id).to_s
    end
    return false
  rescue
    return left.to_s == right.to_s
  end

  def current_loaded_map_id_for_interpreter_guard
    map_id = 0
    map_id = integer($game_map.map_id, 0) if defined?($game_map) && $game_map && $game_map.respond_to?(:map_id)
    if map_id <= 0 && defined?($game_player) && $game_player && $game_player.respond_to?(:map_id)
      map_id = integer($game_player.map_id, 0)
    end
    return map_id
  rescue
    return 0
  end

  def interpreter_stale_for_current_map?(interpreter, current_map_id = nil)
    return false if !interpreter
    expansion_id = interpreter_context_expansion_id(interpreter)
    return false if expansion_id.to_s.empty?
    map_id = integer(current_map_id, 0)
    map_id = current_loaded_map_id_for_interpreter_guard if map_id <= 0
    return false if map_id <= 0
    current_expansion = current_map_expansion_id(map_id)
    return true if current_expansion.to_s.empty?
    return true if !expansion_context_ids_match?(current_expansion, expansion_id)
    interpreter_map_id = interpreter_context_map_id(interpreter)
    interpreter_map_expansion = current_map_expansion_id(interpreter_map_id) if interpreter_map_id > 0
    return true if !interpreter_map_expansion.to_s.empty? &&
                   !expansion_context_ids_match?(interpreter_map_expansion, current_expansion)
    return false
  rescue => e
    log("[interpreter] stale guard failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def clear_interpreter_state!(interpreter, reason = "stale expansion interpreter")
    return false if !interpreter
    expansion_id = interpreter_context_expansion_id(interpreter)
    map_id = interpreter_context_map_id(interpreter)
    event_id = interpreter_context_event_id(interpreter)
    index = interpreter.instance_variable_get(:@index) rescue nil
    reason_text = reason.to_s
    should_record_reference = !expansion_id.to_s.empty? && !(reason_text =~ /\Aexpansion boundary /)
    record_dormant_reference({
      "type"         => "stale_interpreter",
      "expansion_id" => expansion_id.to_s,
      "map_id"       => map_id,
      "event_id"     => event_id,
      "index"        => index,
      "reason"       => reason_text,
      "timestamp"    => timestamp_string
    }) if should_record_reference && respond_to?(:record_dormant_reference)
    log("[interpreter] cleared #{reason_text} (expansion=#{expansion_id.inspect}, map=#{map_id}, event=#{event_id}, index=#{index.inspect})") if respond_to?(:log)
    interpreter.clear if interpreter.respond_to?(:clear)
    interpreter.instance_variable_set(:@list, nil)
    interpreter.instance_variable_set(:@index, 0)
    interpreter.instance_variable_set(:@child_interpreter, nil)
    interpreter.instance_variable_set(:@message_waiting, false)
    interpreter.instance_variable_set(:@move_route_waiting, false)
    interpreter.instance_variable_set(:@wait_count, 0)
    interpreter.instance_variable_set(:@branch, {})
    interpreter.instance_variable_set(:@tef_expansion_id, nil)
    if $game_temp
      $game_temp.message_window_showing = false if $game_temp.respond_to?(:message_window_showing=)
      $game_temp.menu_calling = false if $game_temp.respond_to?(:menu_calling=)
      $game_temp.in_menu = false if $game_temp.respond_to?(:in_menu=)
      $game_temp.player_transferring = false if $game_temp.respond_to?(:player_transferring=)
      $game_temp.transition_processing = false if $game_temp.respond_to?(:transition_processing=)
      if $game_temp.respond_to?(:common_event_id=)
        $game_temp.common_event_id = 0
      end
    end
    $game_system.menu_disabled = false if defined?($game_system) && $game_system && $game_system.respond_to?(:menu_disabled=)
    if current_map_expansion_id(current_loaded_map_id_for_interpreter_guard).to_s.empty?
      clear_current_expansion if respond_to?(:clear_current_expansion)
    end
    if $game_player
      $game_player.unlock if $game_player.respond_to?(:unlock)
      $game_player.cancelMoveRoute if $game_player.respond_to?(:cancelMoveRoute)
      $game_player.straighten if $game_player.respond_to?(:straighten)
    end
    return true
  rescue => e
    log("[interpreter] failed to clear interpreter state: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def clear_stale_expansion_interpreters!(reason = "stale expansion interpreter")
    interpreters = []
    begin
      interpreters << pbMapInterpreter if defined?(pbMapInterpreter) && pbMapInterpreter
    rescue
    end
    begin
      interpreters << $game_system.map_interpreter if $game_system && $game_system.respond_to?(:map_interpreter)
    rescue
    end
    cleared = false
    seen = {}
    current_map_id = current_loaded_map_id_for_interpreter_guard
    interpreters.compact.each do |interpreter|
      object_key = interpreter.object_id
      next if seen[object_key]
      seen[object_key] = true
      next if !interpreter_stale_for_current_map?(interpreter, current_map_id)
      cleared = clear_interpreter_state!(interpreter, reason) || cleared
    end
    return cleared
  rescue => e
    log("[interpreter] stale interpreter sweep failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def release_player_movement_lock(previous_map_id = nil)
    if defined?(SWITCH_LOCK_PLAYER_MOVEMENT) && $game_switches
      $game_switches[SWITCH_LOCK_PLAYER_MOVEMENT] = false
    end
    $game_system.menu_disabled = false if defined?($game_system) && $game_system && $game_system.respond_to?(:menu_disabled=)
    if $game_temp
      $game_temp.message_window_showing = false if $game_temp.respond_to?(:message_window_showing=)
      $game_temp.menu_calling = false if $game_temp.respond_to?(:menu_calling=)
      $game_temp.in_menu = false if $game_temp.respond_to?(:in_menu=)
      $game_temp.player_transferring = false if $game_temp.respond_to?(:player_transferring=)
      $game_temp.transition_processing = false if $game_temp.respond_to?(:transition_processing=)
    end
    if defined?($PokemonTemp) && $PokemonTemp
      $PokemonTemp.miniupdate = false if $PokemonTemp.respond_to?(:miniupdate=)
      $PokemonTemp.hiddenMoveEventCalling = false if $PokemonTemp.respond_to?(:hiddenMoveEventCalling=)
    end
    interpreter = nil
    interpreter = pbMapInterpreter if defined?(pbMapInterpreter) && pbMapInterpreter
    interpreter ||= $game_system.map_interpreter if $game_system && $game_system.map_interpreter
    if interpreter && interpreter.respond_to?(:clear)
      interpreter_map_id = interpreter.instance_variable_get(:@map_id) rescue nil
      current_map_id = ($game_map ? $game_map.map_id : nil)
      should_clear_interpreter = true
      if previous_map_id && current_map_id && integer(previous_map_id, 0) != integer(current_map_id, 0)
        should_clear_interpreter = (integer(interpreter_map_id, 0) == integer(previous_map_id, 0))
      end
      if should_clear_interpreter
        clear_interpreter_state!(interpreter, "expansion boundary #{previous_map_id} -> #{current_map_id}")
      end
    end
    unlock_active_event_context
    if $game_player
      $game_player.unlock if $game_player.respond_to?(:unlock)
      $game_player.cancelMoveRoute if $game_player.respond_to?(:cancelMoveRoute)
      $game_player.straighten if $game_player.respond_to?(:straighten)
    end
    if defined?($PokemonTemp) && $PokemonTemp && $PokemonTemp.respond_to?(:dependentEvents)
      dependent_events = $PokemonTemp.dependentEvents
      dependent_events.pbMapChangeMoveDependentEvents if dependent_events && dependent_events.respond_to?(:pbMapChangeMoveDependentEvents)
    end
  end

  def after_expansion_transfer(previous_map_id = nil)
    update_current_expansion_from_map if respond_to?(:update_current_expansion_from_map)
    current_expansion = current_map_expansion_id
    previous_expansion = current_map_expansion_id(previous_map_id) if previous_map_id
    crossed_expansion_boundary = previous_expansion.to_s != current_expansion.to_s
    release_player_movement_lock(previous_map_id) if crossed_expansion_boundary
    xenoverse_handle_boundary(previous_expansion, current_expansion) if respond_to?(:xenoverse_handle_boundary)
    new_project_handle_boundary_party_session!(previous_expansion, current_expansion) if respond_to?(:new_project_handle_boundary_party_session!)
    insurgence_force_player_solid_after_transfer!(previous_map_id) if respond_to?(:insurgence_force_player_solid_after_transfer!)
    reborn_force_player_safe_after_transfer!(previous_map_id) if respond_to?(:reborn_force_player_safe_after_transfer!)
    touched_expansion = !previous_expansion.to_s.empty? || !current_expansion.to_s.empty?
    prepare_expansion_scene_visual_state! if touched_expansion
    remember_expansion_anchor_from_current_location(current_expansion) if current_expansion && respond_to?(:remember_expansion_anchor_from_current_location)
    return if !$scene || !$scene.is_a?(Scene_Map)
    renderer = $scene.map_renderer if $scene.respond_to?(:map_renderer)
    return if !renderer
    if touched_expansion && renderer.respond_to?(:refresh)
      renderer.refresh
    end
    after_expansion_scene_visual_refresh($scene) if touched_expansion
    clear_stuck_screen_effects!("expansion transfer #{previous_map_id} -> #{($game_map ? $game_map.map_id : nil)}") if respond_to?(:clear_stuck_screen_effects!)
  end

  def neutral_screen_tone
    return Tone.new(0, 0, 0, 0)
  rescue
    return nil
  end

  def transparent_screen_color
    return Color.new(0, 0, 0, 0)
  rescue
    return nil
  end

  def visual_number(value, fallback = 0)
    return fallback if value.nil?
    return value.to_f
  rescue
    return fallback
  end

  def dark_screen_tone?(tone)
    return false if !tone
    red = visual_number(tone.red, 0) if tone.respond_to?(:red)
    green = visual_number(tone.green, 0) if tone.respond_to?(:green)
    blue = visual_number(tone.blue, 0) if tone.respond_to?(:blue)
    return false if red.nil? || green.nil? || blue.nil?
    return red <= -200 && green <= -200 && blue <= -200
  rescue
    return false
  end

  def opaque_black_color?(color)
    return false if !color
    alpha = visual_number(color.alpha, 0) if color.respond_to?(:alpha)
    red = visual_number(color.red, 0) if color.respond_to?(:red)
    green = visual_number(color.green, 0) if color.respond_to?(:green)
    blue = visual_number(color.blue, 0) if color.respond_to?(:blue)
    return false if alpha.nil? || red.nil? || green.nil? || blue.nil?
    return alpha >= 200 && red <= 20 && green <= 20 && blue <= 20
  rescue
    return false
  end

  def screen_visuals_stuck_dark?(screen = nil)
    screen ||= (defined?($game_screen) ? $game_screen : nil)
    return false if !screen
    brightness = if screen.respond_to?(:brightness)
      visual_number(screen.brightness, 255)
    else
      visual_number(screen.instance_variable_get(:@brightness), 255)
    end
    return true if brightness <= 5
    tone = screen.respond_to?(:tone) ? screen.tone : screen.instance_variable_get(:@tone)
    return true if dark_screen_tone?(tone)
    flash = screen.respond_to?(:flash_color) ? screen.flash_color : screen.instance_variable_get(:@flash_color)
    return true if opaque_black_color?(flash)
    return false
  rescue
    return false
  end

  def clear_stuck_screen_effects!(reason = "runtime", force = false)
    screen = defined?($game_screen) ? $game_screen : nil
    neutral_tone = neutral_screen_tone
    transparent_color = transparent_screen_color
    should_clear_screen = force || screen_visuals_stuck_dark?(screen)
    changed = false
    if screen && should_clear_screen
      if neutral_tone && screen.respond_to?(:start_tone_change)
        screen.start_tone_change(neutral_tone, 0)
      elsif neutral_tone
        screen.instance_variable_set(:@tone, neutral_tone.clone)
        screen.instance_variable_set(:@tone_target, neutral_tone.clone)
        screen.instance_variable_set(:@tone_duration, 0)
      end
      if transparent_color && screen.respond_to?(:start_flash)
        screen.start_flash(transparent_color, 0)
      elsif transparent_color
        screen.instance_variable_set(:@flash_color, transparent_color.clone)
        screen.instance_variable_set(:@flash_duration, 0)
      end
      screen.instance_variable_set(:@brightness, 255) if screen.instance_variable_defined?(:@brightness)
      screen.instance_variable_set(:@fadeout_duration, 0) if screen.instance_variable_defined?(:@fadeout_duration)
      screen.instance_variable_set(:@fadein_duration, 0) if screen.instance_variable_defined?(:@fadein_duration)
      changed = true
    end
    if defined?(Graphics) && Graphics.respond_to?(:brightness)
      graphics_brightness = visual_number(Graphics.brightness, 255)
      if force || graphics_brightness <= 5
        Graphics.brightness = 255 rescue nil
        changed = true
      end
    end
    if defined?($game_temp) && $game_temp && (force || should_clear_screen)
      if $game_temp.respond_to?(:transition_processing=)
        $game_temp.transition_processing = false
        changed = true
      end
      $game_temp.transition_name = "" if $game_temp.respond_to?(:transition_name=)
    end
    scene = defined?($scene) ? $scene : nil
    renderer = scene && scene.respond_to?(:map_renderer) ? scene.map_renderer : nil
    if renderer
      renderer_tone = renderer.respond_to?(:tone) ? renderer.tone : nil
      renderer_color = renderer.respond_to?(:color) ? renderer.color : nil
      if force || dark_screen_tone?(renderer_tone) || opaque_black_color?(renderer_color)
        renderer.tone = neutral_tone if neutral_tone && renderer.respond_to?(:tone=)
        renderer.color = transparent_color if transparent_color && renderer.respond_to?(:color=)
        renderer.refresh if renderer.respond_to?(:refresh)
        changed = true
      end
    end
    if changed
      Graphics.transition(0) if defined?(Graphics) && Graphics.respond_to?(:transition)
      log("[visual] cleared stuck screen effects after #{reason} on map #{($game_map ? $game_map.map_id : nil)}") if respond_to?(:log)
    end
    return changed
  rescue => e
    log("[visual] stuck screen cleanup failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def prepare_expansion_scene_visual_state!
    return false if !$game_map
    expansion_id = visual_expansion_id_for_map($game_map) if respond_to?(:visual_expansion_id_for_map)
    expansion_id = current_map_expansion_id($game_map.map_id) if expansion_id.to_s.empty?
    return false if expansion_id.to_s.empty?
    set_current_expansion(expansion_id) if respond_to?(:set_current_expansion)
    maps = []
    maps.concat($MapFactory.maps) if defined?($MapFactory) && $MapFactory && $MapFactory.respond_to?(:maps)
    maps << $game_map
    maps.compact.uniq.each do |map|
      map_expansion = visual_expansion_id_for_map(map) if respond_to?(:visual_expansion_id_for_map)
      map_expansion = current_map_expansion_id(map.map_id) if map_expansion.to_s.empty?
      next if map_expansion.to_s.empty?
      with_rendering_expansion(map_expansion) do
        map.updateTileset if map.respond_to?(:updateTileset)
      end
      map.need_refresh = true if map.respond_to?(:need_refresh=)
      map.refresh if map.respond_to?(:refresh)
    end
    if $game_player && $game_player.respond_to?(:center)
      $game_player.center($game_player.x, $game_player.y)
      $game_player.straighten if $game_player.respond_to?(:straighten)
    end
    return true
  rescue => e
    log("[map] expansion scene visual prepare failed: #{e.class}: #{e.message}")
    return false
  end

  def after_expansion_scene_visual_refresh(scene)
    return false if !scene || !$game_map
    expansion_id = visual_expansion_id_for_map($game_map) if respond_to?(:visual_expansion_id_for_map)
    expansion_id = current_map_expansion_id($game_map.map_id) if expansion_id.to_s.empty?
    return false if expansion_id.to_s.empty?
    renderer = scene.map_renderer if scene.respond_to?(:map_renderer)
    if renderer
      renderer.tone = Tone.new(0, 0, 0, 0) if renderer.respond_to?(:tone=)
      renderer.color = Color.new(0, 0, 0, 0) if renderer.respond_to?(:color=)
      renderer.refresh if renderer.respond_to?(:refresh)
      renderer.update if renderer.respond_to?(:update)
    end
    $game_map.autoplay if $game_map.respond_to?(:autoplay)
    return true
  rescue => e
    log("[map] expansion scene visual refresh failed: #{e.class}: #{e.message}")
    return false
  end

  def resolved_tileset_path(name)
    return nil if name.nil? || name.to_s.empty?
    return resolve_runtime_path("Graphics/Tilesets/#{name}", [".png", ".gif", ".jpg", ".jpeg", ".bmp"])
  end

  def resolved_autotile_path(name)
    return nil if name.nil? || name.to_s.empty?
    return resolve_runtime_path("Graphics/Autotiles/#{name}", [".png", ".gif", ".jpg", ".jpeg", ".bmp"])
  end

  def current_audio_expansion_id
    candidates = []
    if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:player_new_map_id)
      target_map_id = integer($game_temp.player_new_map_id, 0)
      candidates << current_map_expansion_id(target_map_id) if target_map_id > 0 && respond_to?(:current_map_expansion_id)
    end
    candidates << current_asset_expansion_id
    if defined?($game_map) && $game_map && $game_map.respond_to?(:map_id) && respond_to?(:current_map_expansion_id)
      candidates << current_map_expansion_id($game_map.map_id)
    end
    candidates << current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    candidates.each do |candidate|
      expansion = candidate.to_s
      return expansion if !expansion.empty?
    end
    return nil
  rescue
    return nil
  end

  def normalized_audio_logical_path(name, folder = nil)
    raw = name.to_s.gsub("\\", "/").sub(/\A\.\//, "")
    return nil if raw.empty?
    return raw if raw =~ %r{\AAudio/(?:BGM|BGS|ME|SE)/}i
    audio_folder = folder.to_s.strip
    audio_folder = "BGM" if audio_folder.empty?
    return "Audio/#{audio_folder}/#{raw}"
  rescue
    return nil
  end

  def resolve_expansion_audio_path(name, folder = nil, preferred_expansion_id = nil)
    logical = normalized_audio_logical_path(name, folder)
    return nil if logical.nil? || logical.empty?
    expansion_id = preferred_expansion_id.to_s
    expansion_id = current_audio_expansion_id if expansion_id.empty?
    if !expansion_id.to_s.empty? && respond_to?(:resolve_runtime_path_for_expansion)
      resolved = resolve_runtime_path_for_expansion(expansion_id, logical, AUDIO_EXTENSIONS)
      if resolved
        log_runtime_asset_once(expansion_id, :audio, logical, resolved) if respond_to?(:log_runtime_asset_once)
        return resolved
      end
    end
    resolved = resolve_runtime_path(logical, AUDIO_EXTENSIONS) if respond_to?(:resolve_runtime_path)
    return resolved if resolved
    return nil
  rescue => e
    log("[audio] resolve failed for #{name}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def suspicious_expansion_bitmap?(bitmap)
    return true if bitmap.nil?
    return false if !bitmap.respond_to?(:width) || !bitmap.respond_to?(:height)
    return bitmap.width.to_i <= 32 && bitmap.height.to_i <= 32
  rescue
    return true
  end

  def host_utility_character_bitmap?(path)
    normalized = path.to_s.gsub("\\", "/")
    return false if normalized !~ %r{\AGraphics/Characters/([^/]+)\z}i
    return HOST_UTILITY_CHARACTER_BITMAPS.include?($1.to_s.downcase)
  end

  def resolve_runtime_path(logical_path, extensions = [])
    return nil if logical_path.nil?
    raw_path = logical_path.to_s
    return nil if raw_path.empty?
    normalized = raw_path.gsub("\\", "/").sub(/\A\.\//, "")
    return nil if normalized.empty?
    exts = extensions.is_a?(Array) ? extensions : [extensions]
    exts = [""] if exts.empty?
    host_ui_path = host_ui_bitmap_path(normalized, exts)
    if host_ui_path
      log_runtime_asset_once(current_asset_expansion_id, :host_ui_bitmap, normalized, host_ui_path)
      return host_ui_path
    end
    if absolute_path?(normalized)
      absolute = File.expand_path(normalized)
      existing = runtime_existing_path(absolute)
      return existing if existing
      exts.each do |ext|
        next if ext.to_s.empty?
        with_extension = absolute
        with_extension += ext.to_s if !absolute.downcase.end_with?(ext.to_s.downcase)
        existing = runtime_existing_path(with_extension)
        return existing if existing
      end
      return nil
    end
    normalized.sub!(%r{\A/}, "")
    return nil if normalized.empty? || normalized.end_with?("/")
    basename = File.basename(normalized)
    return nil if basename.nil? || basename.empty? || basename == "." || basename == ".."
    asset_roots.reverse_each do |root|
      next if !root || root.to_s.empty?
      candidate = runtime_path_join(root, normalized)
      existing = runtime_existing_path(candidate)
      return existing if existing
      exts.each do |ext|
        next if ext.to_s.empty? && candidate == logical_path
        with_extension = candidate
        with_extension += ext.to_s if !ext.to_s.empty? && !candidate.downcase.end_with?(ext.to_s.downcase)
        existing = runtime_existing_path(with_extension)
        return existing if existing
      end
    end
    return nil
  end

  def load_map_data(map_id)
    entry = expansion_map_entry(map_id)
    if entry
      raise Errno::ENOENT if !expansion_map_active?(map_id)
      return load_marshaled_runtime(entry[:path])
    end
    return load_data(sprintf("Data/Map%03d.rxdata", map_id))
  end

  def map_display_name(map_id)
    resolved_name = expansion_map_display_name(map_id) if respond_to?(:expansion_map_display_name)
    return resolved_name if !resolved_name.to_s.empty?
    entry = expansion_map_entry(map_id)
    return nil if !entry
    return entry[:name]
  end

  class RuntimeMapInfoProxy
    attr_accessor :name

    def initialize(name)
      @name = name.to_s
    end
  end

  def runtime_map_info_proxy(name)
    key = name.to_s
    return nil if key.empty?
    @runtime_map_info_proxies ||= {}
    @runtime_map_info_proxies[key] ||= RuntimeMapInfoProxy.new(key)
    return @runtime_map_info_proxies[key]
  end

  def attach_runtime_map_info!(mapinfos, map_id)
    return mapinfos if !mapinfos || !mapinfos.respond_to?(:[]=)
    identifier = integer(map_id, 0)
    return mapinfos if identifier <= 0
    existing = mapinfos[identifier] rescue nil
    return mapinfos if existing && (!existing.respond_to?(:name) || !existing.name.to_s.empty?)
    name = map_display_name(identifier)
    return mapinfos if name.to_s.empty?
    proxy = runtime_map_info_proxy(name)
    return mapinfos if !proxy
    mapinfos[identifier] = proxy
    return mapinfos
  rescue
    return mapinfos
  end

  def prime_runtime_mapinfos!(mapinfos)
    tracked_map_ids = []
    tracked_map_ids.concat(Array($PokemonGlobal.mapTrail)) if $PokemonGlobal && $PokemonGlobal.respond_to?(:mapTrail)
    tracked_map_ids << $game_map.map_id if $game_map
    tracked_map_ids.compact.each do |map_id|
      attach_runtime_map_info!(mapinfos, map_id)
    end
    return mapinfos
  rescue
    return mapinfos
  end

  def expansion_map_block_start(expansion_id)
    manifest = manifest_for(expansion_id) if respond_to?(:manifest_for)
    block = manifest[:map_block] if manifest.is_a?(Hash)
    return integer(block[:start] || block["start"], 0) if block.is_a?(Hash)
    return 0
  rescue
    return 0
  end

  def expansion_virtual_map_id(expansion_id, local_map_id)
    start_id = expansion_map_block_start(expansion_id)
    local_id = integer(local_map_id, 0)
    return 0 if start_id <= 0 || local_id <= 0
    return start_id + local_id
  rescue
    return 0
  end

  def normalize_map_connection_edge(edge)
    case edge.to_s.strip.downcase
    when "n", "north" then "N"
    when "s", "south" then "S"
    when "e", "east" then "E"
    when "w", "west" then "W"
    else edge.to_s.strip
    end
  rescue
    return edge
  end

  def expansion_map_connection_candidate_paths(expansion_id)
    expansion = expansion_id.to_s
    return [] if expansion.empty?
    paths = []
    manifest = manifest_for(expansion) if respond_to?(:manifest_for)
    if manifest.is_a?(Hash) && manifest[:map_source].is_a?(Hash)
      template = manifest[:map_source][:path_template].to_s
      if !template.empty?
        data_root = File.dirname(template)
        paths << runtime_path_join(data_root, "map_connections.dat")
        paths << runtime_path_join(data_root, "connections.dat")
        paths << runtime_path_join(data_root, "MapConnections.rxdata")
        paths << runtime_path_join(data_root, "Connections.rxdata")
        paths << runtime_path_join(File.dirname(data_root), "PBS/map_connections.txt")
      end
      source_root = manifest[:source_root].to_s
      paths << runtime_path_join(source_root, "PBS/map_connections.txt") if !source_root.empty?
    end
    roots = []
    roots.concat(runtime_asset_roots_for_expansion(expansion)) if respond_to?(:runtime_asset_roots_for_expansion)
    roots << runtime_path_join(linked_projects_dir, slugify(expansion)) if respond_to?(:linked_projects_dir)
    roots << runtime_path_join(runtime_path_join(library_dir, "ExtractedArchives"), slugify(expansion)) if respond_to?(:library_dir)
    roots.compact.map { |root| root.to_s }.reject { |root| root.empty? }.uniq.each do |root|
      paths << runtime_path_join(root, "Data/map_connections.dat")
      paths << runtime_path_join(root, "Data/connections.dat")
      paths << runtime_path_join(root, "Data/MapConnections.rxdata")
      paths << runtime_path_join(root, "Data/Connections.rxdata")
      paths << runtime_path_join(root, "PBS/map_connections.txt")
    end
    return paths.compact.map { |path| path.to_s }.reject { |path| path.empty? }.uniq
  rescue
    return []
  end

  def parse_pbs_map_connections(path)
    return [] if !runtime_file_exists?(path)
    connections = []
    File.readlines(path).each do |line|
      text = line.to_s.sub(/#.*/, "").strip
      next if text.empty?
      parts = text.split(",").map { |part| part.strip }
      next if parts.length < 6
      connections << [
        integer(parts[0], 0),
        normalize_map_connection_edge(parts[1]),
        integer(parts[2], 0),
        integer(parts[3], 0),
        normalize_map_connection_edge(parts[4]),
        integer(parts[5], 0)
      ]
    end
    return connections
  rescue => e
    log("[map] failed to parse map connections #{path}: #{e.class}: #{e.message}") if respond_to?(:log)
    return []
  end

  def load_expansion_map_connections_from_path(path)
    return [] if path.to_s.empty? || !runtime_file_exists?(path)
    ext = File.extname(path.to_s).downcase
    if ext == ".txt"
      return parse_pbs_map_connections(path)
    end
    raw = load_marshaled_runtime(path)
    return [] if !raw.respond_to?(:map)
    raw.map do |entry|
      next nil if !entry.respond_to?(:[])
      [
        integer(entry[0], 0),
        normalize_map_connection_edge(entry[1]),
        integer(entry[2], 0),
        integer(entry[3], 0),
        normalize_map_connection_edge(entry[4]),
        integer(entry[5], 0)
      ]
    end.compact
  rescue => e
    log("[map] failed to load map connections #{path}: #{e.class}: #{e.message}") if respond_to?(:log)
    return []
  end

  def raw_expansion_map_connections(expansion_id)
    expansion = expansion_id.to_s
    return [] if expansion.empty?
    @raw_expansion_map_connections_cache ||= {}
    paths = expansion_map_connection_candidate_paths(expansion).select { |path| runtime_file_exists?(path) }
    signature = paths.map do |path|
      mtime = File.mtime(path).to_i rescue 0
      "#{path}|#{mtime}"
    end.join(";")
    cached = @raw_expansion_map_connections_cache[expansion]
    return cached[:connections] if cached && cached[:signature] == signature
    connections = []
    paths.each do |path|
      loaded = load_expansion_map_connections_from_path(path)
      next if loaded.empty?
      connections.concat(loaded)
      break if File.extname(path.to_s).downcase != ".txt"
    end
    @raw_expansion_map_connections_cache[expansion] = {
      :signature   => signature,
      :connections => connections
    }
    return connections
  rescue
    return []
  end

  def normalized_expansion_map_connection(expansion_id, raw_connection)
    return nil if !raw_connection.respond_to?(:[])
    first_map = expansion_virtual_map_id(expansion_id, raw_connection[0])
    second_map = expansion_virtual_map_id(expansion_id, raw_connection[3])
    return nil if first_map <= 0 || second_map <= 0
    return nil if !expansion_map_active?(first_map) || !expansion_map_active?(second_map)
    conn = [
      first_map,
      normalize_map_connection_edge(raw_connection[1]),
      integer(raw_connection[2], 0),
      second_map,
      normalize_map_connection_edge(raw_connection[4]),
      integer(raw_connection[5], 0)
    ]
    dimensions = MapFactoryHelper.getMapDims(conn[0])
    return nil if dimensions[0].to_i == 0 || dimensions[1].to_i == 0
    dimensions = MapFactoryHelper.getMapDims(conn[3])
    return nil if dimensions[0].to_i == 0 || dimensions[1].to_i == 0
    edge = MapFactoryHelper.getMapEdge(conn[0], conn[1])
    case conn[1]
    when "N", "S"
      conn[1] = conn[2]
      conn[2] = edge
    when "E", "W"
      conn[1] = edge
    end
    edge = MapFactoryHelper.getMapEdge(conn[3], conn[4])
    case conn[4]
    when "N", "S"
      conn[4] = conn[5]
      conn[5] = edge
    when "E", "W"
      conn[4] = edge
    end
    return conn
  rescue => e
    log("[map] failed to normalize #{expansion_id} map connection #{raw_connection.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def map_connection_signature(conn)
    return nil if !conn.respond_to?(:[])
    return [conn[0], conn[1], conn[2], conn[3], conn[4], conn[5]].join("|")
  rescue
    return nil
  end

  def augment_map_connections!(connections)
    return connections if !connections.respond_to?(:[])
    object_id = connections.object_id
    signature = current_enabled_signature.join("|") if respond_to?(:current_enabled_signature)
    signature ||= active_expansion_ids.join("|") if respond_to?(:active_expansion_ids)
    signature = signature.to_s
    return connections if @expansion_map_connections_augmented_object_id == object_id &&
                          @expansion_map_connections_augmented_signature == signature
    existing = {}
    connections.each do |entry_list|
      next if !entry_list.respond_to?(:each)
      entry_list.each do |conn|
        key = map_connection_signature(conn)
        existing[key] = true if key
      end
    end
    added_by_expansion = Hash.new(0)
    active_expansion_ids.each do |expansion|
      raw_expansion_map_connections(expansion).each do |raw_connection|
        conn = normalized_expansion_map_connection(expansion, raw_connection)
        next if !conn
        key = map_connection_signature(conn)
        next if key && existing[key]
        connections[conn[0]] ||= []
        connections[conn[0]].push(conn)
        connections[conn[3]] ||= []
        connections[conn[3]].push(conn)
        existing[key] = true if key
        added_by_expansion[expansion] += 1
      end
    end
    added_by_expansion.each do |expansion, count|
      next if count <= 0
      @expansion_map_connections_log ||= {}
      log_key = "#{expansion}|#{count}|#{signature}"
      next if @expansion_map_connections_log[log_key]
      @expansion_map_connections_log[log_key] = true
      log("[map] added #{count} map connections for #{expansion}") if respond_to?(:log)
    end
    @expansion_map_connections_augmented_object_id = object_id
    @expansion_map_connections_augmented_signature = signature
    return connections
  rescue => e
    log("[map] expansion map connection augmentation failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return connections
  end
end

alias tef_original_load_data load_data
def load_data(file_path)
  if file_path.is_a?(String)
    normalized = file_path.gsub("\\", "/")
    if normalized =~ /(?:^|\/)Data\/Map(\d+)\.rxdata$/i
      map_id = $1.to_i
      if TravelExpansionFramework.expansion_map_active?(map_id)
        return TravelExpansionFramework.load_map_data(map_id)
      end
    end
  end
  return tef_original_load_data(file_path)
end

alias tef_original_pbLoadMapInfos pbLoadMapInfos
def pbLoadMapInfos
  mapinfos = tef_original_pbLoadMapInfos
  TravelExpansionFramework.prime_runtime_mapinfos!(mapinfos) if defined?(TravelExpansionFramework)
  return mapinfos
end

alias tef_original_pbResolveBitmap pbResolveBitmap
def pbResolveBitmap(x)
  return nil if x.nil? || x.to_s.empty?
  if TravelExpansionFramework.current_asset_expansion_id
    resolved = TravelExpansionFramework.resolve_runtime_path(x, [".png", ".gif", ".jpg", ".jpeg", ".bmp"])
    return resolved if resolved
  end
  resolved = tef_original_pbResolveBitmap(x)
  return resolved if resolved
  return TravelExpansionFramework.resolve_runtime_path(x, [".png", ".gif", ".jpg", ".jpeg", ".bmp"])
end

alias tef_original_pbGetTileset pbGetTileset
def pbGetTileset(name, hue = 0)
  resolved = TravelExpansionFramework.resolved_tileset_path(name)
  if resolved
    begin
      bitmap = AnimatedBitmap.new(resolved, hue).deanimate
      if TravelExpansionFramework.suspicious_expansion_bitmap?(bitmap)
        TravelExpansionFramework.log_runtime_asset_once(TravelExpansionFramework.current_asset_expansion_id, :tileset_placeholder, name, resolved)
      else
        TravelExpansionFramework.log_runtime_asset_once(TravelExpansionFramework.current_asset_expansion_id, :tileset, name, resolved)
        return bitmap
      end
    rescue => e
      TravelExpansionFramework.log_runtime_asset_once(TravelExpansionFramework.current_asset_expansion_id, :tileset_load_failed, name, "#{resolved} (#{e.class}: #{e.message})")
    end
  end
  TravelExpansionFramework.log_runtime_asset_once(TravelExpansionFramework.current_asset_expansion_id, :tileset_missing, name, "fallback_to_host")
  return tef_original_pbGetTileset(name, hue)
end

alias tef_original_pbGetAutotile pbGetAutotile
def pbGetAutotile(name, hue = 0)
  resolved = TravelExpansionFramework.resolved_autotile_path(name)
  if resolved
    begin
      bitmap = AnimatedBitmap.new(resolved, hue).deanimate
      if TravelExpansionFramework.suspicious_expansion_bitmap?(bitmap)
        TravelExpansionFramework.log_runtime_asset_once(TravelExpansionFramework.current_asset_expansion_id, :autotile_placeholder, name, resolved)
      else
        TravelExpansionFramework.log_runtime_asset_once(TravelExpansionFramework.current_asset_expansion_id, :autotile, name, resolved)
        return bitmap
      end
    rescue => e
      TravelExpansionFramework.log_runtime_asset_once(TravelExpansionFramework.current_asset_expansion_id, :autotile_load_failed, name, "#{resolved} (#{e.class}: #{e.message})")
    end
  end
  TravelExpansionFramework.log_runtime_asset_once(TravelExpansionFramework.current_asset_expansion_id, :autotile_missing, name, "fallback_to_host")
  return tef_original_pbGetAutotile(name, hue)
end

alias tef_original_pbResolveAudioSE pbResolveAudioSE
def pbResolveAudioSE(file)
  return nil if file.nil? || file.to_s.empty?
  if TravelExpansionFramework.current_asset_expansion_id
    resolved = TravelExpansionFramework.resolve_runtime_path("Audio/SE/#{file}", ["", ".wav", ".mp3", ".ogg"])
    return resolved if resolved
  end
  resolved = tef_original_pbResolveAudioSE(file)
  return resolved if resolved
  return TravelExpansionFramework.resolve_runtime_path("Audio/SE/#{file}", ["", ".wav", ".mp3", ".ogg"])
end

module FileTest
  class << self
    alias tef_original_audio_exist? audio_exist? if method_defined?(:audio_exist?) && !method_defined?(:tef_original_audio_exist?)

    def audio_exist?(filename)
      resolved = TravelExpansionFramework.resolve_expansion_audio_path(filename)
      return true if resolved
      return tef_original_audio_exist?(filename) if defined?(tef_original_audio_exist?)
      return false
    end
  end
end

class Game_System
  alias tef_original_bgm_play_internal2 bgm_play_internal2 unless method_defined?(:tef_original_bgm_play_internal2)

  def bgm_play_internal2(name, volume, pitch, position)
    resolved = TravelExpansionFramework.resolve_expansion_audio_path(name, "BGM")
    return tef_original_bgm_play_internal2(resolved || name, volume, pitch, position)
  end
end

if defined?(Audio)
  class << Audio
    alias tef_original_bgm_play bgm_play if method_defined?(:bgm_play) && !method_defined?(:tef_original_bgm_play)
    alias tef_original_bgs_play bgs_play if method_defined?(:bgs_play) && !method_defined?(:tef_original_bgs_play)
    alias tef_original_me_play me_play if method_defined?(:me_play) && !method_defined?(:tef_original_me_play)
    alias tef_original_se_play se_play if method_defined?(:se_play) && !method_defined?(:tef_original_se_play)

    def bgm_play(name, *args)
      resolved = TravelExpansionFramework.resolve_expansion_audio_path(name, "BGM")
      return tef_original_bgm_play(resolved || name, *args)
    end

    def bgs_play(name, *args)
      resolved = TravelExpansionFramework.resolve_expansion_audio_path(name, "BGS")
      return tef_original_bgs_play(resolved || name, *args)
    end

    def me_play(name, *args)
      resolved = TravelExpansionFramework.resolve_expansion_audio_path(name, "ME")
      return tef_original_me_play(resolved || name, *args)
    end

    def se_play(name, *args)
      resolved = TravelExpansionFramework.resolve_expansion_audio_path(name, "SE")
      return tef_original_se_play(resolved || name, *args)
    end
  end
end

module RTP
  class << self
    alias tef_original_getPath getPath

    def getPath(filename, extensions = [])
      return tef_original_getPath(filename, extensions) if filename.nil? || filename.to_s.empty?
      if TravelExpansionFramework.current_asset_expansion_id
        resolved = TravelExpansionFramework.resolve_runtime_path(filename, extensions)
        return resolved if resolved
      end
      result = tef_original_getPath(filename, extensions)
      return result if result && result != filename
      resolved = TravelExpansionFramework.resolve_runtime_path(filename, extensions)
      return resolved if resolved
      return result
    end
  end
end

module RPG
  module Cache
    class << self
      alias tef_original_load_bitmap load_bitmap

      def load_bitmap(folder_name, filename, hue = 0, rcode = 0, gcode = 1, bcode = 2, pifshiny = 0, kifshiny = 0)
        path = folder_name + filename.to_s
        host_utility_bitmap = TravelExpansionFramework.current_asset_expansion_id &&
                              TravelExpansionFramework.host_utility_character_bitmap?(path)
        if host_utility_bitmap
          return tef_original_load_bitmap(folder_name, filename, hue, rcode, gcode, bcode, pifshiny, kifshiny)
        end
        resolved = TravelExpansionFramework.resolve_runtime_path(path, [".png", ".gif", ".jpg", ".jpeg", ".bmp"])
        if resolved && TravelExpansionFramework.runtime_file_exists?(resolved)
          begin
            exact_resolved = TravelExpansionFramework.runtime_existing_path(resolved) || resolved
            return load_bitmap_path(exact_resolved, hue, rcode, gcode, bcode, pifshiny, kifshiny)
          rescue => e
            TravelExpansionFramework.log_runtime_asset_once(
              TravelExpansionFramework.current_asset_expansion_id,
              :bitmap_load_failed,
              path,
              "#{resolved} (#{e.class}: #{e.message})"
            )
          end
        end
        begin
          return tef_original_load_bitmap(folder_name, filename, hue, rcode, gcode, bcode, pifshiny, kifshiny)
        rescue => e
          if TravelExpansionFramework.host_utility_character_bitmap?(path)
            TravelExpansionFramework.log_runtime_asset_once(
              TravelExpansionFramework.current_asset_expansion_id,
              :bitmap_host_utility_blank_fallback,
              path,
              e.message
            )
            return BitmapWrapper.new(32, 32)
          end
          raise e
        end
      end
    end
  end
end

class Game_Map
  alias tef_original_setup setup
  alias tef_original_name name
  alias tef_original_updateTileset updateTileset
  alias tef_scroll_safety_original_start_scroll start_scroll unless method_defined?(:tef_scroll_safety_original_start_scroll)
  alias tef_scroll_safety_original_scrolling? scrolling? unless method_defined?(:tef_scroll_safety_original_scrolling?)
  alias tef_scroll_safety_original_update update unless method_defined?(:tef_scroll_safety_original_update)

  def tef_ensure_scroll_state!
    @scroll_direction = 2 if !@scroll_direction.is_a?(Numeric)
    @scroll_rest = 0 if !@scroll_rest.is_a?(Numeric)
    @scroll_speed = 4 if !@scroll_speed.is_a?(Numeric)
  rescue
    @scroll_direction = 2
    @scroll_rest = 0
    @scroll_speed = 4
  end

  def start_scroll(direction, distance, speed)
    tef_ensure_scroll_state!
    direction = TravelExpansionFramework.integer(direction, @scroll_direction)
    distance = TravelExpansionFramework.integer(distance, 0)
    speed = TravelExpansionFramework.integer(speed, @scroll_speed)
    tef_scroll_safety_original_start_scroll(direction, distance, speed)
  end

  def scrolling?
    tef_ensure_scroll_state!
    return tef_scroll_safety_original_scrolling?
  end

  def update
    tef_ensure_scroll_state!
    return tef_scroll_safety_original_update
  end

  def tef_apply_external_tileset(tileset)
    return false if !tileset
    expansion_id = TravelExpansionFramework.current_map_expansion_id(@map_id)
    @tileset_name = tileset.respond_to?(:tileset_name) ? tileset.tileset_name.to_s : ""
    @autotile_names = if tileset.respond_to?(:autotile_names)
      Array(tileset.autotile_names).map { |entry| entry.to_s }
    else
      []
    end
    @panorama_name = tileset.respond_to?(:panorama_name) ? tileset.panorama_name.to_s : ""
    @panorama_hue = tileset.respond_to?(:panorama_hue) ? tileset.panorama_hue : 0
    @fog_name = tileset.respond_to?(:fog_name) ? tileset.fog_name.to_s : ""
    @fog_hue = tileset.respond_to?(:fog_hue) ? tileset.fog_hue : 0
    @fog_opacity = tileset.respond_to?(:fog_opacity) ? tileset.fog_opacity : 0
    @fog_blend_type = tileset.respond_to?(:fog_blend_type) ? tileset.fog_blend_type : 0
    @fog_zoom = tileset.respond_to?(:fog_zoom) ? tileset.fog_zoom : 100
    @fog_sx = tileset.respond_to?(:fog_sx) ? tileset.fog_sx : 0
    @fog_sy = tileset.respond_to?(:fog_sy) ? tileset.fog_sy : 0
    @battleback_name = tileset.respond_to?(:battleback_name) ? tileset.battleback_name.to_s : ""
    @passages = tileset.respond_to?(:passages) ? tileset.passages : nil
    @priorities = tileset.respond_to?(:priorities) ? tileset.priorities : nil
    raw_terrain_tags = tileset.respond_to?(:terrain_tags) ? tileset.terrain_tags : nil
    @terrain_tags = raw_terrain_tags
    @terrain_tags = TravelExpansionFramework.uranium_wrap_terrain_tags(expansion_id, @terrain_tags) if TravelExpansionFramework.respond_to?(:uranium_wrap_terrain_tags)
    @terrain_tags = TravelExpansionFramework.empyrean_wrap_terrain_tags(expansion_id, @terrain_tags) if TravelExpansionFramework.respond_to?(:empyrean_wrap_terrain_tags)
    @terrain_tags = TravelExpansionFramework.solar_eclipse_wrap_terrain_tags(expansion_id, @terrain_tags) if TravelExpansionFramework.respond_to?(:solar_eclipse_wrap_terrain_tags)
    return true
  end

  def updateTileset
    if TravelExpansionFramework.expansion_map_active?(@map_id)
      tileset = TravelExpansionFramework.expansion_tileset_for_map(@map_id, @map)
      return if tef_apply_external_tileset(tileset)
    end
    tef_original_updateTileset
  end

  def setup(map_id)
    if TravelExpansionFramework.expansion_map_active?(map_id)
      @map_id = map_id
      @map = TravelExpansionFramework.load_map_data(map_id)
      tileset = TravelExpansionFramework.expansion_tileset_for_map(map_id, @map) || $data_tilesets[@map.tileset_id]
      expansion_id = TravelExpansionFramework.direct_map_expansion_id(map_id)
      TravelExpansionFramework.set_current_expansion(expansion_id) if expansion_id && TravelExpansionFramework.respond_to?(:set_current_expansion)
      TravelExpansionFramework.with_rendering_expansion(expansion_id) do
        updateTileset
      end
      @fog_ox = 0
      @fog_oy = 0
      @fog2_ox = 0
      @fog2_oy = 0
      @fog2_sx = 0
      @fog2_sy = 0
      @fog2_opacity = 0
      @fog_tone = Tone.new(0, 0, 0, 0)
      @fog_tone_target = Tone.new(0, 0, 0, 0)
      @fog_tone_duration = 0
      @fog_opacity_duration = 0
      @fog_opacity_target = 0
      self.display_x = 0
      self.display_y = 0
      @need_refresh = false
      Events.onMapCreate.trigger(self, map_id, @map, tileset)
      @events = {}
      @map.events.keys.each do |event_id|
        @events[event_id] = Game_Event.new(@map_id, @map.events[event_id], self)
      end
      @common_events = {}
      for i in 1...$data_common_events.size
        @common_events[i] = Game_CommonEvent.new(i)
      end
      @scroll_direction = 2
      @scroll_rest = 0
      @scroll_speed = 4
      expansion_id ||= TravelExpansionFramework.current_map_expansion_id(map_id)
      TravelExpansionFramework.log("[#{expansion_id}] setup map=#{map_id} tileset=#{@tileset_name.inspect} autotiles=#{Array(@autotile_names).length} size=#{@map.width}x#{@map.height}") if expansion_id
      return
    end
    result = tef_original_setup(map_id)
    tef_ensure_scroll_state!
    return result
  end

  def name
    override = TravelExpansionFramework.map_display_name(@map_id)
    return override if override
    return tef_original_name
  end
end

module MapFactoryHelper
  class << self
    alias tef_original_getMapDims getMapDims
    alias tef_original_getMapConnections getMapConnections

    def getMapDims(id)
      if TravelExpansionFramework.expansion_map?(id)
        @@MapDims = [] if !@@MapDims
        if !@@MapDims[id]
          begin
            if TravelExpansionFramework.expansion_map_active?(id)
              map = TravelExpansionFramework.load_map_data(id)
              @@MapDims[id] = [map.width, map.height]
            else
              @@MapDims[id] = [0, 0]
            end
          rescue
            @@MapDims[id] = [0, 0]
          end
        end
        return @@MapDims[id]
      end
      return tef_original_getMapDims(id)
    end

    def getMapConnections
      connections = tef_original_getMapConnections
      TravelExpansionFramework.augment_map_connections!(connections) if defined?(TravelExpansionFramework) &&
                                                                        TravelExpansionFramework.respond_to?(:augment_map_connections!)
      return connections
    end
  end
end

class Scene_Map
  alias tef_original_createSpritesets createSpritesets unless method_defined?(:tef_original_createSpritesets)
  alias tef_original_autofade autofade
  alias tef_original_transfer_player transfer_player

  def createSpritesets
    TravelExpansionFramework.repair_legacy_current_expansion_map_id! if defined?(TravelExpansionFramework) &&
                                                                        TravelExpansionFramework.respond_to?(:repair_legacy_current_expansion_map_id!)
    expansion_id = nil
    if defined?(TravelExpansionFramework)
      expansion_id = TravelExpansionFramework.visual_expansion_id_for_map($game_map) if TravelExpansionFramework.respond_to?(:visual_expansion_id_for_map)
      expansion_id = TravelExpansionFramework.current_map_expansion_id if expansion_id.to_s.empty?
    end
    if expansion_id && !expansion_id.to_s.empty?
      TravelExpansionFramework.set_current_expansion(expansion_id) if TravelExpansionFramework.respond_to?(:set_current_expansion)
      result = nil
      TravelExpansionFramework.with_rendering_expansion(expansion_id) do
        result = tef_original_createSpritesets
      end
      return result
    end
    return tef_original_createSpritesets
  end

  def autofade(mapid)
    if TravelExpansionFramework.expansion_map?(mapid)
      playingBGM = $game_system.playing_bgm
      playingBGS = $game_system.playing_bgs
      return if !playingBGM && !playingBGS
      begin
        map = TravelExpansionFramework.load_map_data(mapid)
      rescue
        return
      end
      if playingBGM && map.autoplay_bgm
        if (PBDayNight.isNight? rescue false)
          pbBGMFade(0.8) if playingBGM.name != map.bgm.name && playingBGM.name != map.bgm.name + "_n"
        else
          pbBGMFade(0.8) if playingBGM.name != map.bgm.name
        end
      end
      if playingBGS && map.autoplay_bgs
        pbBGMFade(0.8) if playingBGS.name != map.bgs.name
      end
      Graphics.frame_reset
      return
    end
    tef_original_autofade(mapid)
  end

  def transfer_player(*args)
    previous_map_id = ($game_map ? $game_map.map_id : nil)
    target_map_id = ($game_temp ? $game_temp.player_new_map_id : nil)
    pending_transfer = TravelExpansionFramework.pending_safe_transfer if TravelExpansionFramework.respond_to?(:pending_safe_transfer)
    if !pending_transfer && $game_temp && $game_temp.respond_to?(:player_transferring) && $game_temp.player_transferring &&
       TravelExpansionFramework.respond_to?(:mark_pending_safe_transfer)
      target_anchor = TravelExpansionFramework.sanitize_anchor({
        :map_id    => target_map_id,
        :x         => $game_temp.player_new_x,
        :y         => $game_temp.player_new_y,
        :direction => $game_temp.player_new_direction
      })
      context = TravelExpansionFramework.normalize_transfer_context({
        :source      => :scene_transfer,
        :immediate   => true,
        :auto_rescue => true
      }, target_anchor)
      error = TravelExpansionFramework.transfer_preflight_error(target_anchor, context)
      if error
        TravelExpansionFramework.record_failed_transition(context[:source], context[:expansion_id], TravelExpansionFramework.current_anchor, target_anchor, error) if TravelExpansionFramework.respond_to?(:record_failed_transition)
        TravelExpansionFramework.rollback_failed_transfer!(TravelExpansionFramework.current_anchor, target_anchor, context, error) if TravelExpansionFramework.respond_to?(:rollback_failed_transfer!)
        return false
      end
      TravelExpansionFramework.mark_pending_safe_transfer(context, TravelExpansionFramework.current_anchor, target_anchor)
      pending_transfer = TravelExpansionFramework.pending_safe_transfer if TravelExpansionFramework.respond_to?(:pending_safe_transfer)
    end
    result = tef_original_transfer_player(*args)
    if TravelExpansionFramework.current_map_expansion_id(previous_map_id) || TravelExpansionFramework.current_map_expansion_id(target_map_id)
      TravelExpansionFramework.after_expansion_transfer(previous_map_id)
    end
    if pending_transfer && TravelExpansionFramework.respond_to?(:complete_pending_safe_transfer!)
      TravelExpansionFramework.complete_pending_safe_transfer!(TravelExpansionFramework.current_anchor)
    end
    TravelExpansionFramework.start_home_pc_reentry_guard(45) if result != false &&
                                                               TravelExpansionFramework.respond_to?(:start_home_pc_reentry_guard)
    TravelExpansionFramework.clear_stuck_screen_effects!("map transfer #{previous_map_id} -> #{($game_map ? $game_map.map_id : target_map_id)}") if TravelExpansionFramework.respond_to?(:clear_stuck_screen_effects!)
    return result
  rescue => e
    if TravelExpansionFramework.respond_to?(:pending_safe_transfer)
      pending = TravelExpansionFramework.pending_safe_transfer
      if pending && TravelExpansionFramework.respond_to?(:rollback_failed_transfer!)
        context = pending[:context] || {}
        TravelExpansionFramework.rollback_failed_transfer!(pending[:from], pending[:to], TravelExpansionFramework.normalize_transfer_context(context, pending[:to]), "#{e.class}: #{e.message}")
        TravelExpansionFramework.clear_stuck_screen_effects!("failed map transfer #{previous_map_id} -> #{target_map_id}", true) if TravelExpansionFramework.respond_to?(:clear_stuck_screen_effects!)
        return false
      end
    end
    raise
  end
end

if defined?(Sprite_Player)
  class Sprite_Player
    alias tef_expansion_bush_original_update update unless method_defined?(:tef_expansion_bush_original_update)
    alias tef_expansion_bush_original_dispose dispose unless method_defined?(:tef_expansion_bush_original_dispose)

    def update
      tef_expansion_bush_original_update
      tef_apply_expansion_clothed_bush_bitmap
    end

    def dispose
      tef_dispose_expansion_bush_bitmap
      tef_expansion_bush_original_dispose
    end

    private

    def tef_dispose_expansion_bush_bitmap
      if @tef_expansion_bushbitmap
        @tef_expansion_bushbitmap.dispose if @tef_expansion_bushbitmap.respond_to?(:dispose)
        @tef_expansion_bushbitmap = nil
      end
      @tef_expansion_bushdepth = nil
      @tef_expansion_bushbitmap_source_id = nil
    rescue
    end

    def tef_apply_expansion_clothed_bush_bitmap
      active = TravelExpansionFramework.current_map_expansion_id
      bushdepth = (@character && @character.respond_to?(:bush_depth)) ? @character.bush_depth.to_i : 0
      if active.to_s.empty? || bushdepth <= 0 || @character != $game_player
        tef_dispose_expansion_bush_bitmap
        return
      end
      source_bitmap = getClothedPlayerSprite()
      return if source_bitmap.nil?
      source_id = source_bitmap.object_id
      if @tef_expansion_bushbitmap.nil? ||
         @tef_expansion_bushdepth != bushdepth ||
         @tef_expansion_bushbitmap_source_id != source_id
        @tef_expansion_bushbitmap.dispose if @tef_expansion_bushbitmap && @tef_expansion_bushbitmap.respond_to?(:dispose)
        @tef_expansion_bushbitmap = BushBitmap.new(source_bitmap, false, bushdepth)
        @tef_expansion_bushdepth = bushdepth
        @tef_expansion_bushbitmap_source_id = source_id
      end
      return if !@tef_expansion_bushbitmap || !@tef_expansion_bushbitmap.respond_to?(:bitmap)
      self.bitmap = @tef_expansion_bushbitmap.bitmap
      if @tile_id == 0 && @character
        @cw = [self.bitmap.width / 4, 1].max if self.bitmap && self.bitmap.respond_to?(:width)
        @ch = [self.bitmap.height / 4, 1].max if self.bitmap && self.bitmap.respond_to?(:height)
        sx = @character.pattern.to_i * @cw
        sy = ((@character.direction.to_i - 2) / 2) * @ch
        self.src_rect.set(sx, sy, @cw, @ch)
        self.ox = @cw / 2 if respond_to?(:ox=)
        self.oy = @ch if respond_to?(:oy=)
      end
    rescue => e
      TravelExpansionFramework.log("[sprite] expansion bush override failed: #{e.class}: #{e.message}") if TravelExpansionFramework.respond_to?(:log)
    end
  end
end

class TilemapRenderer
  alias tef_original_check_if_screen_moved check_if_screen_moved

  def check_if_screen_moved
    previous_expansion = TravelExpansionFramework.current_map_expansion_id(@current_map_id)
    current_expansion = TravelExpansionFramework.current_map_expansion_id
    if previous_expansion || current_expansion
      @pixel_offset_x = 0
      @pixel_offset_y = 0
    end
    return tef_original_check_if_screen_moved
  end

  alias tef_original_refresh_tile_bitmap refresh_tile_bitmap

  def tef_visual_expansion_for_render_map(map)
    return nil if !map
    map_id = map.respond_to?(:map_id) ? map.map_id : nil
    tileset_name = map.respond_to?(:tileset_name) ? map.tileset_name.to_s : ""
    autotiles_id = map.respond_to?(:autotile_names) ? map.autotile_names.object_id : 0
    marker = TravelExpansionFramework.current_expansion_marker.to_s if TravelExpansionFramework.respond_to?(:current_expansion_marker)
    if @tef_visual_render_map_object_id == map.object_id &&
       @tef_visual_render_map_id == map_id &&
       @tef_visual_render_map_tileset == tileset_name &&
       @tef_visual_render_map_autotiles_id == autotiles_id &&
       @tef_visual_render_map_marker == marker.to_s
      return @tef_visual_render_map_cache_value == false ? nil : @tef_visual_render_map_cache_value
    end
    expansion_id = nil
    expansion_id = TravelExpansionFramework.visual_expansion_id_for_map(map) if TravelExpansionFramework.respond_to?(:visual_expansion_id_for_map)
    expansion_id = TravelExpansionFramework.current_map_expansion_id(map_id) if expansion_id.to_s.empty?
    @tef_visual_render_map_object_id = map.object_id
    @tef_visual_render_map_id = map_id
    @tef_visual_render_map_tileset = tileset_name
    @tef_visual_render_map_autotiles_id = autotiles_id
    @tef_visual_render_map_marker = marker.to_s
    @tef_visual_render_map_cache_value = expansion_id.to_s.empty? ? false : expansion_id
    return expansion_id
  rescue
    return nil
  end

  def refresh_tile_bitmap(tile, map, tile_id)
    expansion_id = tef_visual_expansion_for_render_map(map)
    return tef_original_refresh_tile_bitmap(tile, map, tile_id) if expansion_id.nil? || expansion_id.to_s.empty?
    TravelExpansionFramework.with_rendering_expansion(expansion_id) do
      tef_original_refresh_tile_bitmap(tile, map, tile_id)
    end
  end

  alias tef_original_get_autotile_overrides get_autotile_overrides
  alias tef_original_add_extra_autotiles add_extra_autotiles
  alias tef_original_remove_extra_autotiles remove_extra_autotiles

  def get_autotile_overrides(tileset_id, map_id)
    return {} if TravelExpansionFramework.current_map_expansion_id(map_id)
    return tef_original_get_autotile_overrides(tileset_id, map_id)
  end

  def add_extra_autotiles(tileset_id, map_id)
    return if TravelExpansionFramework.current_map_expansion_id(map_id)
    tef_original_add_extra_autotiles(tileset_id, map_id)
  end

  def remove_extra_autotiles(tileset_id)
    return if TravelExpansionFramework.current_asset_expansion_id
    tef_original_remove_extra_autotiles(tileset_id)
  end

  class AutotileBitmaps
    alias tef_original_add add

    def add(filename)
      expansion_id = TravelExpansionFramework.current_asset_expansion_id
      return tef_original_add(filename) if expansion_id.nil? || expansion_id.to_s.empty?
      return if nil_or_empty?(filename)
      if @bitmaps[filename]
        @load_counts[filename] += 1
        return
      end
      orig_bitmap = pbGetAutotile(filename)
      @bitmap_wraps[filename] = false
      duration = AUTOTILE_FRAME_DURATION
      duration = $~[1].to_i if filename[/\[\s*(\d+?)\s*\]\s*$/]
      @frame_durations[filename] = duration.to_f / 20
      bitmap = AutotileExpander.expand(orig_bitmap)
      orig_bitmap.dispose if orig_bitmap != bitmap
      self[filename] = bitmap
      @load_counts[filename] = 1
    end
  end
end
