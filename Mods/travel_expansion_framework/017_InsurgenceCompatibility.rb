module TravelExpansionFramework
  module_function

  INSURGENCE_EXPANSION_ID = "insurgence"
  INSURGENCE_EXISTING_SAVE_SWITCH_ID = 696
  INSURGENCE_CHALLENGE_SWITCHES = {
    :nuzlocke   => 71,
    :randomizer => 321,
    :pp_lock    => 345,
    :solo       => 346,
    :mystery    => 354,
    :nontech    => 355,
    :egglocke   => 356,
    :bravery    => 357,
    :wonder     => 583,
    :ironman    => 584
  }.freeze
  INSURGENCE_BLOCKED_RESUME_LOCAL_MAPS = [
    55,  # DeepSeaBase/test room variant
    57,  # DeepSeaBase/test room variant
    79,  # intro choice scene; rewrites identity/challenge state
    779  # DeepSeaBase tournament/debug display room
  ].freeze
  INSURGENCE_FORCE_SOLID_AFTER_TRANSFER_LOCAL_MAPS = [
    3, 42, 69, 70, 71, 383, 515
  ].freeze
  INSURGENCE_SCRIPTED_INTRO_TRANSFER_LOCAL_MAPS = [
    3, 42, 69, 70, 71, 383
  ].freeze

  class InsurgenceNullDependentEvent
    attr_accessor :blend_type
    attr_accessor :character_hue
    attr_accessor :character_name
    attr_accessor :direction
    attr_accessor :move_frequency
    attr_accessor :move_speed
    attr_accessor :opacity
    attr_accessor :pattern
    attr_accessor :step_anime
    attr_accessor :through
    attr_accessor :tile_id
    attr_accessor :transparent
    attr_accessor :walk_anime
    attr_accessor :x
    attr_accessor :y

  def initialize
      @blend_type = 0
      @character_hue = 0
      @character_name = ""
      @direction = 2
      @move_frequency = 3
      @move_speed = 4
      @opacity = 255
      @pattern = 0
      @step_anime = false
      @through = true
      @tile_id = 0
      @transparent = false
      @walk_anime = true
      @x = ($game_player.x rescue 0)
      @y = ($game_player.y rescue 0)
    end

    def map
      return $game_map
    end

    def moveto(x, y)
      @x = x
      @y = y
    end

    def jump(_x_plus, _y_plus)
    end

    def move_down
      @y += 1
    end

    def move_left
      @x -= 1
    end

    def move_right
      @x += 1
    end

    def move_up
      @y -= 1
    end

    def straighten
    end

    def erase
    end

    def screen_x
      return 0
    end

    def screen_y
      return 0
    end
  end

  def insurgence_expansion_id?(expansion_id = nil)
    expansion = expansion_id
    expansion = current_runtime_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_runtime_expansion_id)
    expansion = current_map_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_map_expansion_id)
    expansion = current_expansion_id if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_expansion_id)
    return expansion.to_s == INSURGENCE_EXPANSION_ID
  end

  def primary_dependent_event(dependent_events)
    return nil if dependent_events.nil?
    if dependent_events.respond_to?(:realEvents)
      events = dependent_events.realEvents
      return events[0] if events.is_a?(Array) && events[0]
    end
    if dependent_events.instance_variable_defined?(:@realEvents)
      events = dependent_events.instance_variable_get(:@realEvents)
      return events[0] if events.is_a?(Array) && events[0]
    end
    if defined?(Kernel.pbGetDependency)
      event = Kernel.pbGetDependency("Dependent") rescue nil
      return event if event
    end
    return nil
  rescue => e
    log("[insurgence] dependent event lookup failed: #{e.class}: #{e.message}")
    return nil
  end

  def insurgence_real_dependency(event_name = nil)
    return nil if !$PokemonTemp || !$PokemonTemp.respond_to?(:dependentEvents)
    dependent_events = $PokemonTemp.dependentEvents
    if !event_name.nil? && !event_name.to_s.empty?
      named_event = dependent_events.getEventByName(event_name.to_s) rescue nil
      return named_event if named_event
    end
    return primary_dependent_event(dependent_events)
  rescue => e
    log("[insurgence] real dependency lookup failed: #{e.class}: #{e.message}")
    return nil
  end

  def insurgence_dependency_candidate_event
    return nil if !$game_map || !$game_map.respond_to?(:events)
    events = $game_map.events.values.compact rescue []
    named = events.find { |event| event.name.to_s.strip.downcase == "mew" }
    return named if named
    by_charset = events.find { |event| (event.character_name rescue "").to_s == "151" }
    return by_charset if by_charset
    return $game_map.events[10] if ($game_map.events[10] rescue nil)
    return nil
  rescue => e
    log("[insurgence] dependency candidate lookup failed: #{e.class}: #{e.message}")
    return nil
  end

  def insurgence_recover_dependency(event_name = "Dependent")
    return nil if !insurgence_expansion_id?
    existing = insurgence_real_dependency(event_name)
    if existing
      insurgence_prepare_follower_event!(existing, true, event_name)
      return existing
    end
    candidate = insurgence_dependency_candidate_event
    return nil if !candidate
    if $PokemonTemp && $PokemonTemp.respond_to?(:dependentEvents)
      $PokemonTemp.dependentEvents.addEvent(candidate, event_name.to_s, nil)
      $PokemonTemp.dependentEvents.follows_player = true if $PokemonTemp.dependentEvents.respond_to?(:follows_player=)
    end
    recovered = insurgence_real_dependency(event_name)
    insurgence_prepare_follower_event!(recovered, true, event_name) if recovered
    log("[insurgence] recovered dependent event=#{candidate.id} name=#{event_name}") if recovered
    return recovered
  rescue => e
    log("[insurgence] dependency recovery failed: #{e.class}: #{e.message}")
    return nil
  end

  def insurgence_prepare_follower_event!(event, follows = true, event_name = "Dependent")
    return false if !event
    dependent_events = ($PokemonTemp.dependentEvents rescue nil)
    dependent_events.follows_player = follows if dependent_events && dependent_events.respond_to?(:follows_player=)
    event.transparent = false if event.respond_to?(:transparent=)
    event.opacity = 255 if event.respond_to?(:opacity=)
    event.instance_variable_set(:@opacity, 255) if event.instance_variable_defined?(:@opacity)
    event.through = true if event.respond_to?(:through=)
    event.walk_anime = true if event.respond_to?(:walk_anime=)
    event.step_anime = false if event.respond_to?(:step_anime=)
    if event_name.to_s.downcase == "mew" || (event.character_name rescue "").to_s.empty?
      event.character_name = "151" if event.respond_to?(:character_name=) && pbResolveBitmap("Graphics/Characters/151")
    end
    dependent_events.refresh_sprite if follows && dependent_events && dependent_events.respond_to?(:refresh_sprite)
    return true
  rescue => e
    log("[insurgence] follower event prep failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def fallback_dependent_event(key = nil)
    @insurgence_null_dependent_events ||= {}
    cache_key = key.to_s.empty? ? "__default__" : key.to_s
    return @insurgence_null_dependent_events[cache_key] ||= InsurgenceNullDependentEvent.new
  end

  def insurgence_virtual_map_id(local_map_id)
    manifest = manifest_for(INSURGENCE_EXPANSION_ID)
    return nil if !manifest || !manifest[:map_block].is_a?(Hash)
    start_id = integer(manifest[:map_block][:start], 0)
    local_id = integer(local_map_id, 0)
    return nil if start_id <= 0 || local_id <= 0
    return start_id + local_id
  rescue
    return nil
  end

  def insurgence_intro_completed?
    return false if !$game_self_switches
    map_id = insurgence_virtual_map_id(2)
    return false if !map_id
    return $game_self_switches[[map_id, 17, "B"]] == true
  rescue
    return false
  end

  def insurgence_resume_blocked?(expansion_id = nil)
    return false if !insurgence_expansion_id?(expansion_id)
    return !insurgence_intro_completed?
  end

  def insurgence_anchor_capture_blocked?(anchor = nil)
    normalized = sanitize_anchor(anchor)
    return false if !normalized
    local_id = local_map_id_for(INSURGENCE_EXPANSION_ID, normalized[:map_id]) if respond_to?(:local_map_id_for)
    local_id = integer(local_id, 0)
    return INSURGENCE_BLOCKED_RESUME_LOCAL_MAPS.include?(local_id)
  rescue => e
    log("[insurgence] anchor capture check failed: #{e.class}: #{e.message}")
    return false
  end

  def insurgence_map_interpreter_running?
    return true if pbMapInterpreterRunning? rescue false
    interpreter = $game_system.map_interpreter if $game_system && $game_system.respond_to?(:map_interpreter)
    return interpreter && interpreter.respond_to?(:running?) && interpreter.running?
  rescue
    return false
  end

  def insurgence_scripted_intro_transfer_active?(previous_map_id = nil, current_local_id = nil)
    current_local = integer(current_local_id, 0)
    current_local = insurgence_local_map_id if current_local <= 0
    previous_local = local_map_id_for(INSURGENCE_EXPANSION_ID, previous_map_id) if previous_map_id && respond_to?(:local_map_id_for)
    previous_local = integer(previous_local, 0)
    return false if !INSURGENCE_SCRIPTED_INTRO_TRANSFER_LOCAL_MAPS.include?(current_local)
    return false if previous_local > 0 && !INSURGENCE_SCRIPTED_INTRO_TRANSFER_LOCAL_MAPS.include?(previous_local)
    # Scene_Map#transfer_player runs before the foreign event interpreter is
    # always visible to pbMapInterpreterRunning?. If both sides are intro maps,
    # treat the transfer as scripted and let Insurgence's post-transfer route
    # finish before forcing collision back on.
    return true if previous_local > 0
    return insurgence_map_interpreter_running?
  rescue
    return false
  end

  def insurgence_frame_count
    return Graphics.frame_count if defined?(Graphics) && Graphics.respond_to?(:frame_count)
    return 0
  rescue
    return 0
  end

  def insurgence_cancel_intro_transfer_move_routes!
    characters = [$game_player]
    dependent_events = ($PokemonTemp.dependentEvents rescue nil)
    if dependent_events
      characters.concat(Array(dependent_events.realEvents)) if dependent_events.respond_to?(:realEvents)
      characters.concat(Array(dependent_events.instance_variable_get(:@realEvents))) if dependent_events.instance_variable_defined?(:@realEvents)
      ["Dependent", "Mew"].each do |event_name|
        candidate = dependent_events.getEventByName(event_name) rescue nil
        characters << candidate if candidate
      end
    end
    characters.compact.uniq.each do |character|
      character.cancelMoveRoute if character.respond_to?(:cancelMoveRoute)
      character.unlock if character.respond_to?(:unlock)
      character.through = false if character.respond_to?(:through=)
    end
    interpreter = pbMapInterpreter rescue nil
    interpreter.instance_variable_set(:@move_route_waiting, false) if interpreter
    return true
  rescue => e
    log("[insurgence] intro move-route recovery failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def insurgence_force_player_solid_after_transfer!(previous_map_id = nil)
    return false if !insurgence_expansion_id?
    return false if !$game_map || !$game_player
    local_id = local_map_id_for(INSURGENCE_EXPANSION_ID, $game_map.map_id) if respond_to?(:local_map_id_for)
    local_id = integer(local_id, 0)
    return false if !INSURGENCE_FORCE_SOLID_AFTER_TRANSFER_LOCAL_MAPS.include?(local_id)
    if insurgence_scripted_intro_transfer_active?(previous_map_id, local_id)
      @insurgence_pending_intro_transfer_solid_release = true
      @insurgence_pending_intro_transfer_solid_frame = insurgence_frame_count
      @insurgence_pending_intro_transfer_solid_map = $game_map.map_id rescue nil
      log("[insurgence] deferred player solid reset during scripted intro transfer local=#{local_id}") if $game_player.respond_to?(:through) && $game_player.through
      return true
    end
    @insurgence_pending_intro_transfer_solid_release = false
    changed = false
    if $game_player.respond_to?(:through=)
      changed = true if $game_player.respond_to?(:through) && $game_player.through
      $game_player.through = false
    end
    $game_player.always_on_top = false if $game_player.respond_to?(:always_on_top=)
    $game_player.unlock if $game_player.respond_to?(:unlock)
    if $game_player.respond_to?(:cancelMoveRoute) &&
       (!$game_player.respond_to?(:moving?) || !$game_player.moving?) &&
       (!$game_system || !$game_system.respond_to?(:map_interpreter) ||
        !$game_system.map_interpreter || !$game_system.map_interpreter.running?)
      $game_player.cancelMoveRoute
    end
    log("[insurgence] forced player solid after transfer local=#{local_id}") if changed
    return true
  rescue => e
    log("[insurgence] force solid after transfer failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def insurgence_maybe_release_intro_transfer_through!
    return false if !@insurgence_pending_intro_transfer_solid_release
    return false if !insurgence_expansion_id?
    return false if !$game_player
    frame_count = insurgence_frame_count
    started_frame = integer(@insurgence_pending_intro_transfer_solid_frame, frame_count)
    timed_out = frame_count > 0 && started_frame > 0 && frame_count - started_frame > 180
    if insurgence_map_interpreter_running?
      return false if !timed_out || ($game_temp && ($game_temp.message_window_showing rescue false))
      insurgence_cancel_intro_transfer_move_routes!
      log("[insurgence] recovered stuck intro transfer route local=#{insurgence_local_map_id}")
    end
    return false if !timed_out && $game_player.respond_to?(:moving?) && $game_player.moving?
    changed = false
    if $game_player.respond_to?(:through=)
      changed = true if $game_player.respond_to?(:through) && $game_player.through
      $game_player.through = false
    end
    $game_player.always_on_top = false if $game_player.respond_to?(:always_on_top=)
    $game_player.unlock if $game_player.respond_to?(:unlock)
    @insurgence_pending_intro_transfer_solid_release = false
    log("[insurgence] released deferred intro transfer solid state local=#{insurgence_local_map_id}") if changed
    return true
  rescue => e
    log("[insurgence] deferred solid release failed: #{e.class}: #{e.message}") if respond_to?(:log)
    @insurgence_pending_intro_transfer_solid_release = false
    return false
  end

  def insurgence_maybe_recover_intro_dna_lock!
    return false if !insurgence_expansion_id?
    return false if !insurgence_intro_transform_map?
    return false if insurgence_darkrai_cultist_transformed?
    return false if !insurgence_darkrai_cultist_dna_available?
    return false if $game_temp && ($game_temp.message_window_showing rescue false)
    running = insurgence_map_interpreter_running? ||
              ($game_player && $game_player.respond_to?(:move_route_forcing) && $game_player.move_route_forcing)
    if running
      key = [
        ($game_map.map_id rescue 0),
        ($game_player.x rescue 0),
        ($game_player.y rescue 0)
      ]
      if @insurgence_intro_dna_lock_key != key
        @insurgence_intro_dna_lock_key = key
        @insurgence_intro_dna_lock_frame = insurgence_frame_count
        return false
      end
      return false if insurgence_frame_count - integer(@insurgence_intro_dna_lock_frame, 0) <= 180
      insurgence_cancel_intro_transfer_move_routes!
      log("[insurgence] recovered DNA transform lock local=#{insurgence_local_map_id}")
    else
      @insurgence_intro_dna_lock_key = nil
      @insurgence_intro_dna_lock_frame = nil
      return false
    end
    return insurgence_apply_darkrai_cultist_transform!
  rescue => e
    log("[insurgence] DNA lock recovery failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def insurgence_player_female?
    return false if !$Trainer
    return $Trainer.female? if $Trainer.respond_to?(:female?)
    return $Trainer.isFemale? if $Trainer.respond_to?(:isFemale?)
    return false
  rescue
    return false
  end

  def insurgence_player_branch_female?
    return true if insurgence_player_female?
    current_id = integer($Trainer.character_ID, -1) rescue -1
    return [1, 3, 5, 7].include?(current_id)
  rescue
    return false
  end

  def insurgence_host_player_id
    current_id = integer($Trainer.character_ID, -1) rescue -1
    if current_id >= 0 && current_id < 8
      meta = GameData::Metadata.get_player(current_id) rescue nil
      return current_id if meta
    end
    return insurgence_player_branch_female? ? 1 : 0
  rescue
    return 0
  end

  def insurgence_preferred_player_id(requested_id = 0)
    requested = integer(requested_id, 0)
    return requested if requested < 0
    return insurgence_host_player_id
  rescue
    return insurgence_host_player_id
  end

  def insurgence_skin_choice_index
    skin_tone = integer($Trainer.skin_tone, 0) rescue 0
    return 1 if skin_tone <= 0
    return 0 if skin_tone <= 2
    return 1 if skin_tone <= 4
    return 2
  rescue
    return 1
  end

  def insurgence_intro_event_context?(map_id = nil, event_id = nil)
    return false if !insurgence_expansion_id?
    current_map_id = integer(map_id || ($game_map.map_id rescue 0), 0)
    current_event_id = integer(event_id, 0)
    intro_map_id = insurgence_virtual_map_id(79)
    return false if current_map_id <= 0 || intro_map_id.nil?
    return false if current_map_id != intro_map_id
    return true if current_event_id <= 0
    return current_event_id == 15
  rescue
    return 0
  end

  def insurgence_normalize_message_text(message)
    text = message.to_s.dup
    text.gsub!(/\\[A-Za-z](\[[^\]]*\])?/, "")
    text.gsub!(/\s+/, " ")
    return text.strip
  rescue
    return message.to_s
  end

  def insurgence_auto_choice_index(message, commands, map_id = nil, event_id = nil)
    return nil if !insurgence_intro_event_context?(map_id, event_id)
    command_list = Array(commands).map { |entry| entry.to_s.strip }
    normalized_message = insurgence_normalize_message_text(message).downcase
    case command_list
    when ["Boy", "Girl"]
      return insurgence_player_branch_female? ? 1 : 0
    when ["Left", "Middle", "Right"]
      return insurgence_skin_choice_index
    when ["Yes", "No"]
      return 0 if normalized_message.include?("are you sure")
    end
    return nil
  rescue => e
    log("[insurgence] intro auto-choice failed: #{e.class}: #{e.message}")
    return nil
  end

  def insurgence_apply_host_player_visuals!
    return false if !$Trainer
    host_id = insurgence_host_player_id
    meta = GameData::Metadata.get_player(host_id) rescue nil
    return false if !meta
    $Trainer.character_ID = host_id if $Trainer.respond_to?(:character_ID=)
    $Trainer.trainer_type = meta[0] if $Trainer.respond_to?(:trainer_type=) && meta[0]
    if $game_player
      $game_player.removeGraphicsOverride if $game_player.respond_to?(:removeGraphicsOverride)
      $game_player.remove_instance_variable(:@tef_insurgence_character_override) if $game_player.instance_variable_defined?(:@tef_insurgence_character_override)
      $game_player.instance_variable_set(:@defaultCharacterName, "") if $game_player.instance_variable_defined?(:@defaultCharacterName)
      $game_player.character_name = meta[1] if $game_player.respond_to?(:character_name=) && meta[1]
      $game_player.instance_variable_set(:@character_name, meta[1]) if meta[1]
      $game_player.through = false if $game_player.respond_to?(:through=)
      $game_player.transparent = false if $game_player.respond_to?(:transparent=)
      $game_player.refresh if $game_player.respond_to?(:refresh)
    end
    $game_map.need_refresh = true if $game_map
    $scene.reset_player_sprite if $scene && $scene.respond_to?(:reset_player_sprite)
    return true
  rescue => e
    log("[insurgence] host visual apply failed: #{e.class}: #{e.message}")
    return false
  end

  def insurgence_sanitize_intro_script(script)
    source = script.to_s
    return source if source.empty?
    changed = false
    filtered_lines = source.each_line.reject do |line|
      stripped = line.to_s.strip
      remove_line = stripped.start_with?("$Trainer.clothes[") ||
                    stripped == "Kernel.pbSetRandomMart" ||
                    stripped == "pbSetRandomMart"
      changed ||= remove_line
      remove_line
    end
    return source if !changed
    sanitized = filtered_lines.join
    log("[insurgence] sanitized legacy appearance script block")
    return sanitized
  rescue => e
    log("[insurgence] script sanitize failed: #{e.class}: #{e.message}")
    return script.to_s
  end

  def insurgence_follow_event(event_id, event_name = "Dependent", follows = true)
    return false if !insurgence_expansion_id?
    numeric_event_id = integer(event_id, 0)
    return false if numeric_event_id <= 0 || !$game_map
    existing = insurgence_real_dependency(event_name)
    if existing
      insurgence_prepare_follower_event!(existing, follows, event_name)
      return existing
    end
    source_event = $game_map.events[numeric_event_id] rescue nil
    return false if !source_event
    if $PokemonTemp && $PokemonTemp.respond_to?(:dependentEvents)
      $PokemonTemp.dependentEvents.addEvent(source_event, event_name.to_s, nil)
      $PokemonTemp.dependentEvents.follows_player = follows if $PokemonTemp.dependentEvents.respond_to?(:follows_player=)
      dependent = insurgence_real_dependency(event_name)
      insurgence_prepare_follower_event!(dependent, follows, event_name) if dependent
      log("[insurgence] follower bridged event=#{numeric_event_id} name=#{event_name}")
      return dependent || true
    end
    return false
  rescue => e
    log("[insurgence] follower bridge failed: #{e.class}: #{e.message}")
    return false
  end

  def insurgence_local_map_id(map_id = nil)
    source_map_id = integer(map_id || ($game_map.map_id rescue 0), 0)
    return integer(local_map_id_for(INSURGENCE_EXPANSION_ID, source_map_id), source_map_id) if respond_to?(:local_map_id_for)
    return source_map_id
  rescue
    return integer(map_id || 0, 0)
  end

  def insurgence_dna_flags
    return nil if !$game_variables
    $game_variables[42] = [] if !$game_variables[42].is_a?(Array)
    return $game_variables[42]
  rescue
    return nil
  end

  def insurgence_darkrai_cultist_dna_available?
    flags = insurgence_dna_flags
    return true if flags && flags[1] == true
    return true if $game_switches && $game_switches[42] && insurgence_intro_transform_map?
    return false
  rescue
    return false
  end

  def insurgence_darkrai_cultist_transformed?
    return integer($game_variables[41], 0) == 1
  rescue
    return false
  end

  def insurgence_intro_transform_map?
    return [42, 69, 70, 71].include?(insurgence_local_map_id)
  rescue
    return false
  end

  def insurgence_prompt_ready_for_messages?
    return false if !$game_player || !$game_temp
    return false if $game_temp.in_menu rescue false
    return false if $game_temp.in_battle rescue false
    return false if $game_temp.message_window_showing rescue false
    return false if pbMapInterpreterRunning? rescue false
    return true
  rescue
    return false
  end

  def insurgence_event_facing_player?(event)
    return false if !event || !$game_player
    return true if event.respond_to?(:at_coordinate?) && event.at_coordinate?($game_player.x, $game_player.y)
    facing_tile = $MapFactory.getFacingTile if defined?($MapFactory) && $MapFactory.respond_to?(:getFacingTile)
    return false if !facing_tile
    event_map_id = (event.map.map_id rescue $game_map.map_id)
    return integer(facing_tile[0], 0) == integer(event_map_id, 0) &&
           event.respond_to?(:at_coordinate?) &&
           event.at_coordinate?(integer(facing_tile[1], 0), integer(facing_tile[2], 0))
  rescue
    return false
  end

  def insurgence_apply_darkrai_cultist_transform!
    return false if !insurgence_intro_transform_map?
    $game_variables[41] = 1 if $game_variables
    $game_variables[112] = ($Trainer.character_ID rescue 0) if $game_variables && $game_variables[112].nil?
    pbPlayCry(151) rescue nil
    if $scene && $scene.respond_to?(:spriteset) && $scene.spriteset && $scene.spriteset.respond_to?(:addUserAnimation)
      $scene.spriteset.addUserAnimation(Animation_Come_Out, $game_player.x, $game_player.y) rescue nil
    end
    if $game_player
      $game_player.transparent = false if $game_player.respond_to?(:transparent=)
      $game_player.through = false if $game_player.respond_to?(:through=)
      cultist_graphic_available = begin
        pbResolveBitmap("Graphics/Characters/trchar163")
      rescue
        false
      end
      if cultist_graphic_available
        if $game_player.respond_to?(:setPlayerGraphicsOverride)
          $game_player.setPlayerGraphicsOverride("trchar163")
        end
        $game_player.character_name = "trchar163" if $game_player.respond_to?(:character_name=)
        $game_player.instance_variable_set(:@character_name, "trchar163")
        $game_player.instance_variable_set(:@tef_insurgence_character_override, "trchar163")
      end
      $game_player.refresh if $game_player.respond_to?(:refresh)
    end
    $game_map.need_refresh = true if $game_map
    @insurgence_dna_prompt_seen = true
    log("[insurgence] applied Darkrai Cultist transform bridge local=#{insurgence_local_map_id}")
    return true
  rescue => e
    log("[insurgence] Darkrai Cultist transform failed: #{e.class}: #{e.message}")
    return false
  end

  def insurgence_mew_transform_interaction!(auto_prompt = false)
    return false if !insurgence_expansion_id?
    return false if !insurgence_darkrai_cultist_dna_available?
    return false if !insurgence_prompt_ready_for_messages?
    if !insurgence_intro_transform_map?
      Kernel.pbMessage("Mew looks ready to help, but there is no reason to use that disguise here.") rescue nil
      return true
    end
    if auto_prompt
      confirmed = if Kernel.respond_to?(:pbConfirmMessage)
                    Kernel.pbConfirmMessage("Mew reacts to the DNA. Let it transform you into a Darkrai Cultist?")
                  else
                    Kernel.pbMessage("Mew reacts to the DNA. Transform into a Darkrai Cultist?", ["Yes", "No"]) == 0
                  end
      @insurgence_dna_prompt_seen = true
      return true if !confirmed
      return insurgence_apply_darkrai_cultist_transform!
    end
    interaction = Kernel.pbMessage("Choose an interaction.", ["Talk", "Transform"]) rescue 1
    if integer(interaction, 1) == 0
      Kernel.pbMessage("Mew watches you carefully, ready to use Transform with the DNA you found.") rescue nil
      return true
    end
    disguise = Kernel.pbMessage("Choose a disguise.", ["Darkrai Cultist", "Cancel"]) rescue 0
    return true if integer(disguise, 0) != 0
    return insurgence_apply_darkrai_cultist_transform!
  rescue => e
    log("[insurgence] Mew transform interaction failed: #{e.class}: #{e.message}")
    return false
  end

  def insurgence_try_mew_talk_interaction!
    return false if !insurgence_expansion_id?
    return false if !Input.trigger?(Input::USE) rescue false
    return false if !insurgence_darkrai_cultist_dna_available?
    return false if !insurgence_prompt_ready_for_messages?
    mew = insurgence_real_dependency("Dependent") || insurgence_real_dependency("Mew") || insurgence_recover_dependency("Dependent")
    return false if !insurgence_event_facing_player?(mew)
    return insurgence_mew_transform_interaction!(false)
  rescue => e
    log("[insurgence] Mew talk interaction failed: #{e.class}: #{e.message}")
    return false
  end

  def insurgence_maybe_prompt_mew_transform!
    return false if !insurgence_expansion_id?
    if insurgence_darkrai_cultist_transformed?
      @insurgence_dna_prompt_seen = true
      return false
    end
    return false if !insurgence_darkrai_cultist_dna_available?
    return false if !insurgence_intro_transform_map?
    return false if !insurgence_prompt_ready_for_messages?
    @insurgence_dna_prompt_seen = true
    Kernel.pbMessage("Mew reacts to the DNA and transforms you into a Darkrai Cultist disguise.") rescue nil
    return insurgence_apply_darkrai_cultist_transform!
  rescue => e
    log("[insurgence] Mew auto prompt failed: #{e.class}: #{e.message}")
    return false
  end

  def insurgence_has_resume_progress?
    state = state_for(INSURGENCE_EXPANSION_ID)
    return false if !state
    return true if insurgence_intro_completed?
    anchor = sanitize_anchor(state.last_anchor) if respond_to?(:sanitize_anchor)
    return true if integer(state.travel_count, 0) > 1 &&
                   anchor.is_a?(Hash) &&
                   integer(anchor[:map_id], 0) > 0
    return false
  rescue => e
    log("[insurgence] progress check failed: #{e.class}: #{e.message}")
    return false
  end

  def insurgence_apply_existing_save_flag!
    exists = insurgence_has_resume_progress?
    $game_switches[INSURGENCE_EXISTING_SAVE_SWITCH_ID] = exists if $game_switches
    return exists
  rescue => e
    log("[insurgence] existing save flag failed: #{e.class}: #{e.message}")
    return false
  end

  def insurgence_clear_challenge_switches!
    return if !$game_switches
    INSURGENCE_CHALLENGE_SWITCHES.each_value do |switch_id|
      $game_switches[switch_id] = false
    end
  rescue => e
    log("[insurgence] challenge switch clear failed: #{e.class}: #{e.message}")
  end

  def insurgence_record_challenge_profile!(profile_id, active_flags)
    state = state_for(INSURGENCE_EXPANSION_ID)
    return if !state || !state.respond_to?(:metadata)
    state.metadata ||= {}
    state.metadata["insurgence_challenge_profile"] = profile_id.to_s
    state.metadata["insurgence_challenge_flags"] = Array(active_flags).map { |flag| flag.to_s }
  rescue => e
    log("[insurgence] challenge profile record failed: #{e.class}: #{e.message}")
  end

  def insurgence_apply_challenge_profile!(profile_id)
    insurgence_clear_challenge_switches!
    active_flags = case profile_id.to_sym
                   when :nuzlocke
                     [:nuzlocke]
                   when :randomizer
                     [:randomizer]
                   when :randomlocke
                     [:nuzlocke, :randomizer]
                   else
                     []
                   end
    if $game_switches
      active_flags.each do |flag|
        switch_id = INSURGENCE_CHALLENGE_SWITCHES[flag]
        $game_switches[switch_id] = true if switch_id
      end
    end
    if defined?($PokemonGlobal) && $PokemonGlobal
      $PokemonGlobal.nuzlocke = active_flags.include?(:nuzlocke) if $PokemonGlobal.respond_to?(:nuzlocke=)
      $PokemonGlobal.randomizer = active_flags.include?(:randomizer) if $PokemonGlobal.respond_to?(:randomizer=)
    end
    insurgence_record_challenge_profile!(profile_id, active_flags)
    log("[insurgence] challenge profile applied #{profile_id} flags=#{active_flags.join(',')}")
    return active_flags
  rescue => e
    log("[insurgence] challenge profile apply failed: #{e.class}: #{e.message}")
    return []
  end
end

module Kernel
  def self.pbCheckSaves
    return false if !TravelExpansionFramework.insurgence_expansion_id?
    exists = TravelExpansionFramework.insurgence_apply_existing_save_flag!
    TravelExpansionFramework.log("[insurgence] pbCheckSaves => #{exists}")
    return exists
  rescue => e
    TravelExpansionFramework.log("[insurgence] pbCheckSaves failed: #{e.class}: #{e.message}")
    return false
  end

  def self.pbNuzlockeMenu
    return false if !TravelExpansionFramework.insurgence_expansion_id?
    TravelExpansionFramework.insurgence_clear_challenge_switches!
    choices = [
      "Classic Nuzlocke",
      "Randomizer",
      "Randomlocke",
      "Play Normally"
    ]
    message = "Select an Insurgence challenge profile for this run."
    selection = if Kernel.respond_to?(:pbMessage)
                  Kernel.pbMessage(message, choices, 0)
                else
                  0
                end
    selection = TravelExpansionFramework.integer(selection, 0)
    profile = case selection
              when 1 then :randomizer
              when 2 then :randomlocke
              when 3 then :normal
              else :nuzlocke
              end
    TravelExpansionFramework.insurgence_apply_challenge_profile!(profile)
    if profile == :normal
      Kernel.pbMessage("Challenge modifiers disabled. The intro will continue normally.") if Kernel.respond_to?(:pbMessage)
    elsif profile == :randomizer
      Kernel.pbMessage("Randomizer selected. Core intro flow will continue, but expansion-specific randomizer parity may still be partial.") if Kernel.respond_to?(:pbMessage)
    elsif profile == :randomlocke
      Kernel.pbMessage("Randomlocke selected. Core intro flow will continue, but some Insurgence-specific challenge edge cases may still differ from standalone Insurgence.") if Kernel.respond_to?(:pbMessage)
    end
    return profile != :normal
  rescue => e
    TravelExpansionFramework.log("[insurgence] pbNuzlockeMenu failed: #{e.class}: #{e.message}")
    TravelExpansionFramework.insurgence_apply_challenge_profile!(:nuzlocke)
    return true
  end

  def self.pbSetRandomMart
    return false if !TravelExpansionFramework.insurgence_expansion_id?
    TravelExpansionFramework.insurgence_apply_host_player_visuals!
    TravelExpansionFramework.log("[insurgence] skipped standalone wardrobe randomizer")
    return true
  rescue => e
    TravelExpansionFramework.log("[insurgence] pbSetRandomMart failed: #{e.class}: #{e.message}")
    return false
  end

  def self.pbChangeBackToNormal
    return false if !TravelExpansionFramework.insurgence_expansion_id?
    TravelExpansionFramework.insurgence_apply_host_player_visuals!
    $game_map.need_refresh = true if $game_map
    $game_player.refresh if $game_player && $game_player.respond_to?(:refresh)
    TravelExpansionFramework.log("[insurgence] restored host player visuals")
    return true
  rescue => e
    TravelExpansionFramework.log("[insurgence] pbChangeBackToNormal failed: #{e.class}: #{e.message}")
    return false
  end
end

class PokemonSystem
  def purism
    return TravelExpansionFramework.integer(@tef_insurgence_purism, 0)
  rescue
    return 0
  end

  def purism=(value)
    @tef_insurgence_purism = TravelExpansionFramework.integer(value, 0)
  rescue
    @tef_insurgence_purism = 0
  end
end

if defined?(DependentEvents)
  class DependentEvents
    if !method_defined?(:getMew)
      def getMew
        return nil if !TravelExpansionFramework.insurgence_expansion_id?
        event = TravelExpansionFramework.primary_dependent_event(self)
        event ||= TravelExpansionFramework.insurgence_recover_dependency("Dependent")
        return event if event
        return TravelExpansionFramework.fallback_dependent_event("Mew")
      end
    end

    alias tef_insurgence_original_updateDependentEvents updateDependentEvents unless method_defined?(:tef_insurgence_original_updateDependentEvents)

    def updateDependentEvents
      return if TravelExpansionFramework.insurgence_try_mew_talk_interaction!
      return tef_insurgence_original_updateDependentEvents
    end
  end
end

module Kernel
  def self.tef_insurgence_legend_species(legend)
    name = legend.to_s.strip
    normalized = name.gsub(/[^A-Za-z0-9]/, "").upcase
    normalized = "HOOH" if normalized == "HOOH" || normalized == "HOH"
    normalized = "KYUREM" if normalized == "ORIGINAL"
    if defined?(PBSpecies) && PBSpecies.const_defined?(normalized)
      return PBSpecies.const_get(normalized)
    end
    if defined?(GameData) && GameData.const_defined?(:Species)
      species = GameData::Species.try_get(normalized.to_sym) rescue nil
      species ||= GameData::Species.try_get(name.to_sym) rescue nil
      return species.species if species && species.respond_to?(:species)
    end
    return name
  rescue
    return legend
  end unless singleton_class.method_defined?(:tef_insurgence_legend_species)

  def self.doLegendEntrance(legend)
    species = tef_insurgence_legend_species(legend)
    bg_path = pbResolveBitmap("Graphics/Pictures/AlchemicalBG_#{legend}") if defined?(pbResolveBitmap)
    sigil_path = pbResolveBitmap("Graphics/Pictures/Alchemical_#{legend}") if defined?(pbResolveBitmap)
    if defined?(pbResolveBitmap) &&
       defined?(Sprite) &&
       defined?(Viewport) &&
       defined?(Graphics) &&
       bg_path &&
       sigil_path
      viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      viewport.z = 99_999
      bg = Sprite.new(viewport)
      sigil = Sprite.new(viewport)
      bg.bitmap = Bitmap.new(bg_path)
      sigil.bitmap = Bitmap.new(sigil_path)
      bg.opacity = 0
      sigil.opacity = 0
      16.times do
        bg.opacity += 16
        Graphics.update
      end
      pbPlayCry(species) if defined?(pbPlayCry)
      16.times do
        sigil.opacity += 16
        Graphics.update
      end
      12.times { Graphics.update }
      16.times do
        bg.opacity -= 16
        sigil.opacity -= 16
        Graphics.update
      end
      bg.dispose if bg && !bg.disposed?
      sigil.dispose if sigil && !sigil.disposed?
      viewport.dispose if viewport && !viewport.disposed?
    else
      pbPlayCry(species) if defined?(pbPlayCry)
      pbWait(12) if defined?(pbWait)
    end
    TravelExpansionFramework.log("[insurgence] played safe legendary entrance for #{legend}") if defined?(TravelExpansionFramework) &&
                                                                                                  TravelExpansionFramework.respond_to?(:log)
    return true
  rescue => e
    TravelExpansionFramework.log("[insurgence] legendary entrance skipped safely for #{legend}: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                                              TravelExpansionFramework.respond_to?(:log)
    return true
  end unless singleton_class.method_defined?(:doLegendEntrance)
end

def doLegendEntrance(legend)
  return Kernel.doLegendEntrance(legend)
end unless defined?(doLegendEntrance)

if defined?(Sprite_Player)
  class Sprite_Player
    alias tef_insurgence_original_updateCharacterBitmap updateCharacterBitmap unless method_defined?(:tef_insurgence_original_updateCharacterBitmap)

    def updateCharacterBitmap
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.insurgence_expansion_id? &&
         $game_player &&
         $game_player.instance_variable_defined?(:@tef_insurgence_character_override)
        override = $game_player.instance_variable_get(:@tef_insurgence_character_override).to_s
        resolved = pbResolveBitmap("Graphics/Characters/#{override}") if !override.empty?
        return AnimatedBitmap.new(resolved, @character_hue) if resolved
      end
      return tef_insurgence_original_updateCharacterBitmap
    rescue => e
      TravelExpansionFramework.log("[insurgence] player override bitmap fallback: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                                TravelExpansionFramework.respond_to?(:log)
      return tef_insurgence_original_updateCharacterBitmap
    end
  end
end

if defined?(Scene_Map)
  class Scene_Map
    alias tef_insurgence_original_update update unless method_defined?(:tef_insurgence_original_update)

    def update
      result = tef_insurgence_original_update
      TravelExpansionFramework.insurgence_maybe_release_intro_transfer_through!
      TravelExpansionFramework.insurgence_maybe_recover_intro_dna_lock!
      TravelExpansionFramework.insurgence_maybe_prompt_mew_transform!
      return result
    end
  end
end

if defined?(pbGetDependency) && !defined?(tef_insurgence_original_pbGetDependency)
  alias tef_insurgence_original_pbGetDependency pbGetDependency

  def pbGetDependency(eventName)
    event = tef_insurgence_original_pbGetDependency(eventName)
    return event if event || !TravelExpansionFramework.insurgence_expansion_id?
    if ["Dependent", "Mew"].include?(eventName.to_s)
      recovered = TravelExpansionFramework.insurgence_recover_dependency(eventName)
      return recovered if recovered
      return TravelExpansionFramework.fallback_dependent_event(eventName)
    end
    return TravelExpansionFramework.fallback_dependent_event(eventName)
  end
end

if defined?(pbChangePlayer) && !defined?(tef_insurgence_original_pbChangePlayer)
  alias tef_insurgence_original_pbChangePlayer pbChangePlayer
end

def pbChangePlayer(id, *args)
  if !TravelExpansionFramework.insurgence_expansion_id?
    return send(:tef_insurgence_original_pbChangePlayer, id, *args) if respond_to?(:tef_insurgence_original_pbChangePlayer, true)
    return false
  end
  requested_id = TravelExpansionFramework.integer(id, 0)
  resolved_id = TravelExpansionFramework.insurgence_preferred_player_id(requested_id)
  result = if respond_to?(:tef_insurgence_original_pbChangePlayer, true)
             send(:tef_insurgence_original_pbChangePlayer, resolved_id, *args)
           else
             false
           end
  TravelExpansionFramework.log("[insurgence] pbChangePlayer requested=#{requested_id} resolved=#{resolved_id}")
  return result
end

if defined?(pbTrainerName) && !defined?(tef_insurgence_original_pbTrainerName)
  alias tef_insurgence_original_pbTrainerName pbTrainerName
end

def pbTrainerName(name = nil, outfit = 0)
  if !TravelExpansionFramework.insurgence_expansion_id?
    return send(:tef_insurgence_original_pbTrainerName, name, outfit) if respond_to?(:tef_insurgence_original_pbTrainerName, true)
    return name.to_s
  end
  current_id = ($Trainer.character_ID rescue -1)
  pbChangePlayer(TravelExpansionFramework.insurgence_preferred_player_id(0)) if current_id.nil? || current_id < 0
  chosen_name = name.to_s.strip
  chosen_name = $Trainer.name.to_s.strip if chosen_name.empty? && $Trainer
  if chosen_name.empty?
    gender = TravelExpansionFramework.insurgence_player_female? ? GENDER_FEMALE : GENDER_MALE rescue nil
    chosen_name = getPlayerDefaultName(gender) rescue ""
  end
  chosen_name = "Player" if chosen_name.to_s.strip.empty?
  if $Trainer
    $Trainer.name = chosen_name
    $Trainer.outfit = outfit if $Trainer.respond_to?(:outfit=)
  end
  $game_variables[5] = chosen_name if $game_variables && $game_variables[5].nil?
  $PokemonTemp.begunNewGame = true if $PokemonTemp && $PokemonTemp.respond_to?(:begunNewGame=)
  TravelExpansionFramework.log("[insurgence] pbTrainerName => #{chosen_name.inspect}")
  return chosen_name
end

def pbPokemonFollow(event_id, event_name = "Dependent")
  return false if !TravelExpansionFramework.insurgence_expansion_id?
  return TravelExpansionFramework.insurgence_follow_event(event_id, event_name, true)
end

if defined?(pbFancyMoveTo) && !defined?(tef_insurgence_original_pbFancyMoveTo)
  alias tef_insurgence_original_pbFancyMoveTo pbFancyMoveTo
end

def pbFancyMoveTo(follower, newX, newY, leader = :__tef_missing__)
  if leader == :__tef_missing__
    if TravelExpansionFramework.insurgence_expansion_id?
      leader = ($game_player rescue nil) || follower
      TravelExpansionFramework.log("[insurgence] bridged 3-arg pbFancyMoveTo to host follower helper")
    else
      raise ArgumentError, "wrong number of arguments (given 3, expected 4)"
    end
  end
  return tef_insurgence_original_pbFancyMoveTo(follower, newX, newY, leader)
end

class Interpreter
  alias tef_insurgence_original_command_102 command_102 unless method_defined?(:tef_insurgence_original_command_102)
  alias tef_insurgence_original_execute_script execute_script unless method_defined?(:tef_insurgence_original_execute_script)

  def command_102
    if TravelExpansionFramework.insurgence_expansion_id?
      commands = @list[@index].parameters[0] rescue nil
      previous_message = (@list[@index - 1].parameters[0] rescue nil)
      auto_choice = TravelExpansionFramework.insurgence_auto_choice_index(
        previous_message,
        commands,
        ($game_map.map_id rescue nil),
        (@event_id rescue nil)
      )
      if !auto_choice.nil?
        @message_waiting = false
        @branch[@list[@index].indent] = auto_choice
        Input.update
        TravelExpansionFramework.log("[insurgence] auto-selected intro choice #{auto_choice} for #{Array(commands).inspect}")
        return true
      end
    end
    return tef_insurgence_original_command_102
  end

  def execute_script(script)
    if TravelExpansionFramework.insurgence_expansion_id?
      sanitized = TravelExpansionFramework.insurgence_sanitize_intro_script(script)
      if sanitized != script.to_s
        TravelExpansionFramework.insurgence_apply_host_player_visuals!
        return true if sanitized.strip.empty?
        return tef_insurgence_original_execute_script(sanitized)
      end
    end
    return tef_insurgence_original_execute_script(script)
  end
end

class Player
  alias tef_insurgence_original_party_setter party= unless method_defined?(:tef_insurgence_original_party_setter)

  def party=(value)
    if TravelExpansionFramework.insurgence_expansion_id? &&
       value.is_a?(Array) &&
       value.empty? &&
       instance_variable_defined?(:@party) &&
       @party.is_a?(Array) &&
       @party.length > 0
      TravelExpansionFramework.log("[insurgence] blocked intro party wipe")
      return @party
    end
    return tef_insurgence_original_party_setter(value)
  end
end
