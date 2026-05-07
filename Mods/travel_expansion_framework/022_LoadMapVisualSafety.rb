module TravelExpansionFramework
  module_function

  def saved_map_factory_map_id
    if defined?($MapFactory) && $MapFactory
      begin
        map = $MapFactory.map if $MapFactory.respond_to?(:map)
        return integer(map.map_id, 0) if map && map.respond_to?(:map_id)
      rescue
      end
      begin
        maps = $MapFactory.maps if $MapFactory.respond_to?(:maps)
        first = maps.find { |entry| entry && entry.respond_to?(:map_id) } if maps.respond_to?(:find)
        return integer(first.map_id, 0) if first
      rescue
      end
    end
    return integer($game_map.map_id, 0) if defined?($game_map) && $game_map && $game_map.respond_to?(:map_id)
    return integer($game_player.map_id, 0) if defined?($game_player) && $game_player && $game_player.respond_to?(:map_id)
    return 0
  rescue
    return 0
  end

  def saved_map_factory_map_object
    if defined?($MapFactory) && $MapFactory
      begin
        map = $MapFactory.map if $MapFactory.respond_to?(:map)
        return map if map && map.respond_to?(:map_id)
      rescue
      end
      begin
        maps = $MapFactory.maps if $MapFactory.respond_to?(:maps)
        first = maps.find { |entry| entry && entry.respond_to?(:map_id) } if maps.respond_to?(:find)
        return first if first
      rescue
      end
    end
    return $game_map if defined?($game_map) && $game_map && $game_map.respond_to?(:map_id)
    return nil
  rescue
    return nil
  end

  def clear_expansion_tile_cache_for_load!
    RPG::Cache.clear if defined?(RPG::Cache) && RPG::Cache.respond_to?(:clear)
    if defined?(MapFactoryHelper)
      MapFactoryHelper.class_variable_set(:@@MapDims, []) if MapFactoryHelper.class_variable_defined?(:@@MapDims)
    end
  rescue => e
    log("[load] cache clear before expansion map restore failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def direction_turn_proc(direction)
    case integer(direction, 2)
    when 4 then :turn_left
    when 6 then :turn_right
    when 8 then :turn_up
    else :turn_down
    end
  end

  def restore_player_anchor_after_map_rebuild(anchor)
    return if !anchor || !$game_player
    $game_player.moveto(anchor[:x], anchor[:y]) if $game_player.respond_to?(:moveto)
    turn_method = direction_turn_proc(anchor[:direction])
    $game_player.send(turn_method) if $game_player.respond_to?(turn_method)
    # During early save load, encounters may not exist yet; centering can run
    # engine update hooks that assume they do.
    if defined?($PokemonEncounters) && $PokemonEncounters && $game_player.respond_to?(:center)
      $game_player.center($game_player.x, $game_player.y)
    end
    $game_player.straighten if $game_player.respond_to?(:straighten)
  rescue => e
    log("[load] player anchor restore failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def load_safety_map_name(map_id)
    target = integer(map_id, 0)
    return "" if target <= 0
    info = nil
    info = $map_infos[target] if defined?($map_infos) && $map_infos.respond_to?(:[])
    info = $data_mapinfos[target] if info.nil? && defined?($data_mapinfos) && $data_mapinfos.respond_to?(:[])
    if info.nil? && defined?(load_data)
      infos = load_data("Data/MapInfos.rxdata") rescue nil
      info = infos[target] if infos.respond_to?(:[])
    end
    return info.name.to_s if info && info.respond_to?(:name)
    return ""
  rescue
    return ""
  end

  def suspicious_host_load_map?(map_id)
    target = integer(map_id, 0)
    return false if target <= 0 || target >= RESERVED_MAP_BLOCK_START
    known_internal = [203, 355, 374, 731, 732, 734, 735, 736, 737, 787, 789]
    return true if known_internal.include?(target)
    name = load_safety_map_name(target)
    normalized = name.downcase
    return true if ["test", "testing room", "tests"].include?(normalized)
    # These battle-facility maps contain legacy challenge/Pika Cup scripts and
    # are common stale-save landing pads after an expansion scene aborts.
    challenge_names = [
      "battle tower",
      "battle tower arena",
      "battle factory",
      "battle factory arena",
      "triple battle lounge"
    ]
    return challenge_names.include?(normalized)
  rescue
    return false
  end

  def rebuild_expansion_anchor_for_load!(expansion_id, anchor, reason = "saved expansion anchor")
    return false if !defined?(PokemonMapFactory)
    expansion = expansion_id.to_s
    normalized = sanitize_anchor(anchor)
    return false if expansion.empty? || !normalized
    return false if current_map_expansion_id(normalized[:map_id]).to_s != expansion
    return false if !expansion_active?(expansion)
    set_current_expansion(expansion) if respond_to?(:set_current_expansion)
    clear_expansion_tile_cache_for_load!
    with_rendering_expansion(expansion) do
      $MapFactory = PokemonMapFactory.new(normalized[:map_id])
    end
    $game_map = $MapFactory.map if $MapFactory && $MapFactory.respond_to?(:map)
    restore_player_anchor_after_map_rebuild(normalized)
    clear_stale_expansion_interpreters!("expansion load rebuild") if respond_to?(:clear_stale_expansion_interpreters!)
    reconcile_new_project_party_session_for_current_map!("expansion load rebuild") if respond_to?(:reconcile_new_project_party_session_for_current_map!)
    prepare_expansion_scene_visual_state! if respond_to?(:prepare_expansion_scene_visual_state!)
    remember_expansion_anchor(expansion, normalized) if respond_to?(:remember_expansion_anchor)
    remember_last_good_anchor("expansion", expansion, normalized) if respond_to?(:remember_last_good_anchor)
    store_canonical_location("expansion", expansion, normalized, "load_restore") if respond_to?(:store_canonical_location)
    log("[load] rebuilt #{reason} #{normalized[:map_id]} for #{expansion} before scene start") if respond_to?(:log)
    return true
  rescue => e
    log("[load] expansion anchor rebuild failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def rebuild_host_anchor_for_load!(anchor, reason = "host canonical save location")
    return false if !defined?(PokemonMapFactory)
    normalized = sanitize_anchor(anchor)
    normalized ||= sanitize_anchor(default_host_anchor) if respond_to?(:default_host_anchor)
    return false if !normalized
    return false if current_map_expansion_id(normalized[:map_id])
    return false if !valid_map_id?(normalized[:map_id])
    clear_current_expansion if respond_to?(:clear_current_expansion)
    clear_expansion_tile_cache_for_load!
    $MapFactory = PokemonMapFactory.new(normalized[:map_id])
    $game_map = $MapFactory.map if $MapFactory && $MapFactory.respond_to?(:map)
    restore_player_anchor_after_map_rebuild(normalized)
    clear_stale_expansion_interpreters!("host load rebuild") if respond_to?(:clear_stale_expansion_interpreters!)
    reconcile_new_project_party_session_for_current_map!("host load rebuild") if respond_to?(:reconcile_new_project_party_session_for_current_map!)
    remember_last_good_anchor("host", nil, normalized) if respond_to?(:remember_last_good_anchor)
    store_canonical_location("host", nil, normalized, "load_restore") if respond_to?(:store_canonical_location)
    log("[load] rebuilt #{reason} #{normalized[:map_id]} for host before scene start") if respond_to?(:log)
    return true
  rescue => e
    log("[load] host anchor rebuild failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def canonical_expansion_anchor_for_load(expansion_id, anchor)
    expansion = expansion_id.to_s
    normalized = sanitize_anchor(anchor)
    return nil if expansion.empty? || !normalized
    return nil if expansion_anchor_capture_blocked?(expansion, normalized)
    return normalized if current_map_expansion_id(normalized[:map_id]).to_s == expansion &&
                         expansion_map_active?(normalized[:map_id])
    target_id = remap_legacy_reserved_map_id_for_marker(normalized[:map_id], expansion) if respond_to?(:remap_legacy_reserved_map_id_for_marker)
    if target_id
      remapped = normalized.dup
      remapped[:map_id] = target_id
      return nil if expansion_anchor_capture_blocked?(expansion, remapped)
      return remapped if current_map_expansion_id(remapped[:map_id]).to_s == expansion &&
                          expansion_map_active?(remapped[:map_id])
    end
    return nil
  rescue
    return nil
  end

  def relocate_authoritative_expansion_load_to_host!(location, reason)
    anchor = default_host_anchor if respond_to?(:default_host_anchor)
    anchor = sanitize_anchor(anchor)
    return false if !anchor
    expansion = location.is_a?(Hash) ? location["expansion_id"].to_s : ""
    source_anchor = location.is_a?(Hash) ? normalize_anchor(location["anchor"]) : nil
    record_dormant_reference({
      "type"         => "player_map",
      "expansion_id" => expansion,
      "map_id"       => source_anchor ? source_anchor[:map_id] : nil,
      "reason"       => reason.to_s,
      "timestamp"    => timestamp_string
    }) if respond_to?(:record_dormant_reference)
    ensure_save_root.player_relocation_log << {
      "from"      => source_anchor ? source_anchor[:map_id] : nil,
      "to"        => anchor[:map_id],
      "reason"    => reason.to_s,
      "timestamp" => timestamp_string
    } if respond_to?(:ensure_save_root)
    return rebuild_host_anchor_for_load!(anchor, "safe host fallback after #{reason}")
  rescue => e
    log("[load] safe host relocation failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def restore_authoritative_location_for_load!
    return false if !defined?(PokemonMapFactory)
    location = canonical_location if respond_to?(:canonical_location)
    return false if !location.is_a?(Hash)
    kind = location["kind"].to_s
    anchor = normalize_anchor(location["anchor"])
    return false if !anchor
    if kind == "expansion"
      expansion = location["expansion_id"].to_s
      return relocate_authoritative_expansion_load_to_host!(location, "missing expansion #{expansion}") if expansion.empty? ||
                                                                                                            !expansion_active?(expansion)
      target_anchor = canonical_expansion_anchor_for_load(expansion, anchor)
      return relocate_authoritative_expansion_load_to_host!(location, "invalid expansion map #{anchor[:map_id]}") if !target_anchor
      set_current_expansion(expansion) if respond_to?(:set_current_expansion)
      return rebuild_expansion_anchor_for_load!(expansion, target_anchor, "host authoritative expansion save location")
    end
    host_anchor = sanitize_anchor(anchor)
    host_anchor = nil if host_anchor && current_map_expansion_id(host_anchor[:map_id])
    host_anchor ||= sanitize_anchor(default_host_anchor) if respond_to?(:default_host_anchor)
    return false if !host_anchor
    return rebuild_host_anchor_for_load!(host_anchor, "host authoritative save location")
  rescue => e
    log("[load] authoritative location restore failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def recover_stale_expansion_load_destination!
    map_id = saved_map_factory_map_id
    return false if map_id <= 0 || map_id >= RESERVED_MAP_BLOCK_START
    marker = current_expansion_marker.to_s if respond_to?(:current_expansion_marker)
    return false if marker.to_s.empty? || !expansion_active?(marker)
    return false if !suspicious_host_load_map?(map_id)
    anchor = last_expansion_anchor(marker) if respond_to?(:last_expansion_anchor)
    return false if !anchor
    name = load_safety_map_name(map_id)
    log("[load] suspicious host map #{map_id} #{name.inspect} with active marker #{marker}; restoring last expansion anchor") if respond_to?(:log)
    return rebuild_expansion_anchor_for_load!(marker, anchor, "last expansion anchor from stale host map #{map_id}")
  rescue => e
    log("[load] stale expansion load recovery failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def expansion_load_anchor_for_saved_map(expansion_id, saved_anchor)
    expansion = expansion_id.to_s
    saved = sanitize_anchor(saved_anchor)
    return saved if expansion.empty?
    remembered = last_expansion_anchor(expansion) if respond_to?(:last_expansion_anchor)
    remembered = sanitize_anchor(remembered)
    if !remembered
      log("[load] no remembered #{expansion} anchor; using saved MapFactory map #{saved ? saved[:map_id] : nil}") if respond_to?(:log)
      return saved
    end
    return remembered if !saved
    if integer(remembered[:map_id], 0) != integer(saved[:map_id], 0)
      log("[load] using remembered #{expansion} anchor #{remembered[:map_id]} instead of saved MapFactory map #{saved[:map_id]}") if respond_to?(:log)
      return remembered
    end
    log("[load] remembered #{expansion} anchor matches saved map #{saved[:map_id]}; using saved player position") if respond_to?(:log)
    return saved
  rescue => e
    log("[load] expansion load anchor selection failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return saved_anchor
  end

  def remapped_legacy_saved_map_anchor(saved_map, saved_anchor)
    return nil if !saved_map
    saved = sanitize_anchor(saved_anchor)
    return nil if !saved
    map_id = integer(saved[:map_id], 0)
    return nil if map_id < RESERVED_MAP_BLOCK_START
    direct_expansion = current_map_expansion_id(map_id)
    best = best_visual_expansion_for_map(saved_map, direct_expansion) if respond_to?(:best_visual_expansion_for_map)
    return nil if !best.is_a?(Hash)
    owner = best[:expansion_id].to_s
    return nil if owner.empty? || owner == direct_expansion.to_s
    owner_score = integer(best[:score], 0)
    direct_score = map_visual_asset_score_for_expansion(direct_expansion, saved_map) if respond_to?(:map_visual_asset_score_for_expansion)
    direct_score = integer(direct_score, 0)
    return nil if owner_score <= 0 || owner_score <= direct_score
    target_id = remap_legacy_reserved_map_id_for_marker(map_id, owner) if respond_to?(:remap_legacy_reserved_map_id_for_marker)
    return nil if !target_id
    remapped = saved.dup
    remapped[:map_id] = target_id
    log("[load] remapping saved legacy map #{map_id} -> #{target_id} for #{owner} before rebuild (visual=#{owner_score}, direct=#{direct_score})") if respond_to?(:log)
    return {
      :expansion_id => owner,
      :anchor       => remapped
    }
  rescue => e
    log("[load] saved legacy map remap check failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def raw_saved_expansion_anchor(expansion_id)
    root = ensure_save_root if respond_to?(:ensure_save_root)
    states = root.expansions if root && root.respond_to?(:expansions)
    state = states[expansion_id.to_s] if states.respond_to?(:[])
    return nil if !state || !state.respond_to?(:last_anchor)
    return normalize_anchor(state.last_anchor)
  rescue
    return nil
  end

  def saved_map_direct_owner_valid_for_load?(saved_map, direct_expansion)
    owner = direct_expansion.to_s
    return false if owner.empty? || !saved_map
    direct_score = map_visual_asset_score_for_expansion(owner, saved_map) if respond_to?(:map_visual_asset_score_for_expansion)
    direct_score = integer(direct_score, 0)
    return false if direct_score <= 0
    best = best_visual_expansion_for_map(saved_map, owner) if respond_to?(:best_visual_expansion_for_map)
    return false if !best.is_a?(Hash)
    return best[:expansion_id].to_s == owner
  rescue
    return false
  end

  def legacy_expansion_anchor_for_saved_map(saved_anchor, saved_map = nil)
    saved = sanitize_anchor(saved_anchor)
    return nil if !saved
    map_id = integer(saved[:map_id], 0)
    return nil if map_id < RESERVED_MAP_BLOCK_START
    direct_expansion = current_map_expansion_id(map_id)
    marker = current_expansion_marker.to_s if respond_to?(:current_expansion_marker)
    marker = "" if marker.nil?
    if saved_map_direct_owner_valid_for_load?(saved_map, direct_expansion) &&
       (marker.empty? || marker == direct_expansion.to_s)
      log("[load] saved map #{map_id} visually matches #{direct_expansion}; skipping raw legacy anchor remap") if respond_to?(:log)
      return nil
    end
    visual_owner = ""
    if saved_map && respond_to?(:best_visual_expansion_for_map)
      best = best_visual_expansion_for_map(saved_map, direct_expansion)
      visual_owner = best[:expansion_id].to_s if best.is_a?(Hash) && integer(best[:score], 0) > 0
    end
    Array(active_expansion_ids).each do |expansion_id|
      expansion = expansion_id.to_s
      next if expansion.empty? || !expansion_active?(expansion)
      if !visual_owner.empty? && visual_owner != expansion
        next unless !marker.empty? && marker == expansion && marker != direct_expansion.to_s
      end
      next if visual_owner.empty? && !marker.empty? && marker != expansion
      next if visual_owner.empty? && marker.empty? && !direct_expansion.to_s.empty?
      raw_anchor = raw_saved_expansion_anchor(expansion)
      next if !raw_anchor || integer(raw_anchor[:map_id], 0) != map_id
      target_id = remap_legacy_reserved_map_id_for_marker(map_id, expansion) if respond_to?(:remap_legacy_reserved_map_id_for_marker)
      next if !target_id
      remapped = raw_anchor.dup
      remapped[:map_id] = target_id
      log("[load] remapping raw saved #{expansion} anchor #{map_id} -> #{target_id}") if respond_to?(:log)
      return {
        :expansion_id => expansion,
        :anchor       => remapped
      }
    end
    return nil
  rescue => e
    log("[load] raw legacy anchor scan failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def rebuild_saved_expansion_map_for_load!
    return false if !defined?(PokemonMapFactory)
    map_id = saved_map_factory_map_id
    return false if map_id <= 0
    anchor = {
      :map_id    => map_id,
      :x         => ($game_player ? integer($game_player.x, 0) : 0),
      :y         => ($game_player ? integer($game_player.y, 0) : 0),
      :direction => ($game_player ? integer($game_player.direction, 2) : 2)
    }
    saved_map = saved_map_factory_map_object
    remap = remapped_legacy_saved_map_anchor(saved_map, anchor)
    remap ||= legacy_expansion_anchor_for_saved_map(anchor, saved_map)
    if remap
      expansion_id = remap[:expansion_id]
      anchor = remap[:anchor]
    else
      expansion_id = current_map_expansion_id(map_id)
    end
    return false if expansion_id.to_s.empty?
    return false if !expansion_active?(expansion_id)
    anchor = expansion_load_anchor_for_saved_map(expansion_id, anchor)
    if expansion_anchor_capture_blocked?(expansion_id, anchor)
      log("[load] blocked unsafe #{expansion_id} saved resume map #{anchor ? anchor[:map_id] : nil}; relocating to host") if respond_to?(:log)
      location = {
        "kind"         => "expansion",
        "expansion_id" => expansion_id.to_s,
        "anchor"       => anchor
      }
      return relocate_authoritative_expansion_load_to_host!(location, "unsafe #{expansion_id} resume map")
    end
    return rebuild_expansion_anchor_for_load!(expansion_id, anchor, "saved expansion map")
  rescue => e
    log("[load] saved expansion map rebuild failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def finalize_loaded_expansion_map_visuals!
    return false if !$game_map
    map_id = integer($game_map.map_id, 0)
    expansion_id = current_map_expansion_id(map_id)
    return false if expansion_id.to_s.empty?
    return false if !expansion_active?(expansion_id)
    set_current_expansion(expansion_id) if respond_to?(:set_current_expansion)
    with_rendering_expansion(expansion_id) do
      maps = []
      maps.concat($MapFactory.maps) if defined?($MapFactory) && $MapFactory && $MapFactory.respond_to?(:maps)
      maps << $game_map
      maps.compact.uniq.each do |map|
        next if !map
        map.updateTileset if map.respond_to?(:updateTileset)
        map.need_refresh = true if map.respond_to?(:need_refresh=)
        map.refresh if map.respond_to?(:refresh)
      end
    end
    if defined?($PokemonEncounters) && $PokemonEncounters && $PokemonEncounters.respond_to?(:setup)
      $PokemonEncounters.setup(map_id)
    end
    remember_expansion_anchor(expansion_id, current_anchor) if respond_to?(:remember_expansion_anchor) &&
                                                               respond_to?(:current_anchor) &&
                                                               current_anchor
    remember_last_good_anchor("expansion", expansion_id, current_anchor) if respond_to?(:remember_last_good_anchor) &&
                                                                            respond_to?(:current_anchor) &&
                                                                            current_anchor
    store_canonical_location("expansion", expansion_id, current_anchor, "load_finalize") if respond_to?(:store_canonical_location) &&
                                                                                          respond_to?(:current_anchor) &&
                                                                                          current_anchor
    pbUpdateVehicle if defined?(pbUpdateVehicle)
    $game_map.update if $game_map.respond_to?(:update)
    return true
  rescue => e
    log("[load] expansion map visual finalize failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def refresh_scene_expansion_tiles!(scene)
    return false if !scene || !$game_map
    expansion_id = current_map_expansion_id($game_map.map_id)
    return false if expansion_id.to_s.empty?
    return false if !expansion_active?(expansion_id)
    set_current_expansion(expansion_id) if respond_to?(:set_current_expansion)
    prepare_expansion_scene_visual_state! if respond_to?(:prepare_expansion_scene_visual_state!)
    after_expansion_scene_visual_refresh(scene) if respond_to?(:after_expansion_scene_visual_refresh)
    return true
  rescue => e
    log("[load] scene expansion tile refresh failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end
end

module Game
  class << self
    alias tef_load_visual_safety_original_load_map load_map unless method_defined?(:tef_load_visual_safety_original_load_map)

    def load_map
      if defined?(TravelExpansionFramework)
        rebuilt = false
        TravelExpansionFramework.prepare_after_load! if TravelExpansionFramework.respond_to?(:prepare_after_load!)
        rebuilt = TravelExpansionFramework.restore_authoritative_location_for_load! if TravelExpansionFramework.respond_to?(:restore_authoritative_location_for_load!)
        rebuilt = TravelExpansionFramework.recover_stale_expansion_load_destination! if !rebuilt &&
                                                                                       TravelExpansionFramework.respond_to?(:recover_stale_expansion_load_destination!)
        TravelExpansionFramework.rebuild_saved_expansion_map_for_load! if !rebuilt &&
                                                                          TravelExpansionFramework.respond_to?(:rebuild_saved_expansion_map_for_load!)
      end
      result = tef_load_visual_safety_original_load_map
      TravelExpansionFramework.clear_stale_expansion_interpreters!("load_map finalize") if defined?(TravelExpansionFramework) &&
                                                                                          TravelExpansionFramework.respond_to?(:clear_stale_expansion_interpreters!)
      TravelExpansionFramework.reconcile_new_project_party_session_for_current_map!("load_map finalize") if defined?(TravelExpansionFramework) &&
                                                                                                            TravelExpansionFramework.respond_to?(:reconcile_new_project_party_session_for_current_map!)
      TravelExpansionFramework.finalize_loaded_expansion_map_visuals! if defined?(TravelExpansionFramework) &&
                                                                        TravelExpansionFramework.respond_to?(:finalize_loaded_expansion_map_visuals!)
      TravelExpansionFramework.clear_stuck_screen_effects!("load_map") if defined?(TravelExpansionFramework) &&
                                                                          TravelExpansionFramework.respond_to?(:clear_stuck_screen_effects!)
      return result
    end
  end
end

class Scene_Map
  alias tef_load_visual_safety_original_createSpritesets createSpritesets unless method_defined?(:tef_load_visual_safety_original_createSpritesets)

  def createSpritesets
    TravelExpansionFramework.refresh_scene_expansion_tiles!(self) if defined?(TravelExpansionFramework) &&
                                                                     TravelExpansionFramework.respond_to?(:refresh_scene_expansion_tiles!)
    result = tef_load_visual_safety_original_createSpritesets
    TravelExpansionFramework.after_expansion_scene_visual_refresh(self) if defined?(TravelExpansionFramework) &&
                                                                          TravelExpansionFramework.respond_to?(:after_expansion_scene_visual_refresh)
    TravelExpansionFramework.clear_stuck_screen_effects!("createSpritesets") if defined?(TravelExpansionFramework) &&
                                                                                TravelExpansionFramework.respond_to?(:clear_stuck_screen_effects!)
    return result
  end
end

TravelExpansionFramework.log("022_LoadMapVisualSafety loaded from #{__FILE__}") if defined?(TravelExpansionFramework) &&
                                                                                   TravelExpansionFramework.respond_to?(:log)
