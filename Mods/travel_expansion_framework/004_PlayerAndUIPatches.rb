class Quest
  attr_accessor :expansion_id
end

class Pokemon
  attr_accessor :tef_origin_expansion_id
  attr_accessor :tef_origin_variant_id
end

class Player
  def badges_for(expansion_id = nil, page_id = nil)
    return TravelExpansionFramework.host_badges(self) if expansion_id.nil? || expansion_id.to_s.empty? || expansion_id.to_s == TravelExpansionFramework::HOST_EXPANSION_ID
    return TravelExpansionFramework.badge_array_for(expansion_id, page_id, self)
  end

  def badge_pages
    return TravelExpansionFramework.trainer_card_pages(self)
  end

  def global_badge_count
    return TravelExpansionFramework.global_badge_count(self)
  end
end

class Player::Pokedex
  alias tef_original_set_seen set_seen
  alias tef_original_set_owned set_owned

  def set_seen(species, should_refresh_dexes = true)
    tef_original_set_seen(species, should_refresh_dexes)
    TravelExpansionFramework.record_dex_progress(species, false)
  end

  def set_owned(species, should_refresh_dexes = true)
    tef_original_set_owned(species, should_refresh_dexes)
    TravelExpansionFramework.record_dex_progress(species, true)
  end
end

module TravelExpansionFramework
  module_function

  def current_frame_count
    return Graphics.frame_count if defined?(Graphics) && Graphics.respond_to?(:frame_count)
    return 0
  end

  def home_pc_interaction_input_pressed?
    return false if !defined?(Input)
    input_constants = []
    input_constants << Input::USE if Input.const_defined?(:USE)
    input_constants << Input::ACTION if Input.const_defined?(:ACTION)
    input_constants << Input::BACK if Input.const_defined?(:BACK)
    input_constants.each do |constant|
      begin
        return true if Input.press?(constant)
      rescue
      end
    end
    return false
  end

  def start_home_pc_reentry_guard(frames = 60)
    @home_pc_reentry_guard_until = current_frame_count + integer(frames, 60)
    @home_pc_reentry_requires_release = true
  end

  def home_pc_reentry_blocked?
    now = current_frame_count
    if now >= @home_pc_reentry_guard_until.to_i
      @home_pc_reentry_requires_release = false
      @home_pc_reentry_guard_until = 0
      return false
    end
    if @home_pc_reentry_requires_release
      if home_pc_interaction_input_pressed?
        @home_pc_reentry_guard_until = [@home_pc_reentry_guard_until.to_i, now + 2].max
        return true
      end
      @home_pc_reentry_requires_release = false
    end
    return now < @home_pc_reentry_guard_until.to_i
  rescue
    return false
  end

  def finish_home_pc_session
    start_home_pc_reentry_guard(90)
    release_player_movement_lock if respond_to?(:release_player_movement_lock)
    Input.update if defined?(Input) && Input.respond_to?(:update)
    return true
  rescue
    return false
  end

  def trainer_card_pages(player = $Trainer)
    pages = []
    global_owned, global_seen = global_dex_totals(player)
    pages << {
      :id             => HOST_EXPANSION_ID,
      :expansion_id   => HOST_EXPANSION_ID,
      :label          => "Host World",
      :badge_values   => host_badges(player),
      :badge_obtained => host_badges(player).count(true),
      :badge_total    => host_badges(player).length,
      :owned_count    => player && player.pokedex ? player.pokedex.owned_count : 0,
      :seen_count     => player && player.pokedex ? player.pokedex.seen_count : 0,
      :global_owned   => global_owned,
      :global_seen    => global_seen
    }
    active_expansion_ids.each do |expansion_id|
      manifest = manifest_for(expansion_id)
      next if !manifest
      manifest[:badge_pages].each do |page|
        badges = badge_array_for(expansion_id, page[:id], player)
        pages << {
          :id             => page[:id],
          :expansion_id   => expansion_id,
          :label          => page[:name],
          :badge_values   => badges,
          :badge_obtained => badges.count(true),
          :badge_total    => badges.length,
          :owned_count    => dex_owned_count(expansion_id),
          :seen_count     => dex_seen_count(expansion_id),
          :global_owned   => global_owned,
          :global_seen    => global_seen
        }
      end
    end
    return pages
  end

  def travelable_nodes
    nodes = []
    active_expansion_ids.each do |expansion_id|
      nodes.concat(Array(registry(:travel_nodes)[expansion_id]))
    end
    nodes = nodes.reject do |node|
      id = node[:id].to_s.downcase
      name = node[:name].to_s.downcase
      id.end_with?(":exploration") || id.end_with?("_exploration") || name.include?("(exploration)")
    end
    nodes.each { |node| node[:mode_options] = ["shared"] }
    nodes.sort_by { |node| [integer(node[:sort_order], 0), node[:name].to_s] }
  end

  def travel_terminal_enabled?
    return true if current_expansion_id
    return true if travelable_nodes.length > 0
    return false
  end

  def external_project_info_lookup(project_info, *keys)
    return [false, nil] if !project_info.is_a?(Hash)
    keys.each do |key|
      return [true, project_info[key]] if project_info.has_key?(key)
      string_key = key.to_s
      return [true, project_info[string_key]] if project_info.has_key?(string_key)
    end
    return [false, nil]
  end

  def external_project_info_value(project_info, *keys)
    found, value = external_project_info_lookup(project_info, *keys)
    return value if found
    return nil
  end

  def external_project_info_flag(project_info, *keys)
    found, value = external_project_info_lookup(project_info, *keys)
    return nil if !found
    return boolean(value, false)
  end

  def external_project_humanize_code(value)
    text = value.to_s.strip
    return "" if text.empty?
    text = text.tr("-", "_")
    words = text.split("_").find_all { |word| !word.nil? && !word.empty? }
    return text if words.empty?
    return words.map { |word| word[0, 1].upcase + word[1..-1].to_s.downcase }.join(" ")
  end

  def external_project_compatibility_code(project_info)
    compatibility = external_project_info_value(project_info, :compatibility, :compatibility_code, :install_compatibility)
    return compatibility.to_s if !compatibility.nil? && !compatibility.to_s.empty?
    return "packaged_install_detected" if external_project_info_flag(project_info, :archive_detected, :encrypted) == true
    return "direct_mountable" if external_project_info_flag(project_info, :direct_mountable) == true
    return "plugin_sources_detected" if external_project_info_flag(project_info, :plugin_sources_detected, :has_plugin_sources) == true
    return "detection_only"
  end

  def external_project_mount_mode_codes(project_info)
    codes = []
    {
      "prepared_snapshot" => [:prepared_snapshot_available],
      "archive_mountable" => [:archive_mountable, :mountable_archive, :archive_backed_mountable],
      "extracted_mountable" => [:extracted_mountable, :extracted_copy_mountable, :extracted_install_mountable],
      "source_tree_mountable" => [:source_tree_mountable, :mountable_source_tree, :plugin_source_mountable]
    }.each_pair do |code, keys|
      codes << code if external_project_info_flag(project_info, *keys) == true
    end
    codes << "prepared_snapshot" if !external_project_info_value(project_info, :prepared_data_root).to_s.empty?
    compatibility = external_project_compatibility_code(project_info)
    case compatibility
    when "archive_mountable", "extracted_mountable", "extracted_copy_mountable", "extracted_install_mountable", "source_tree_mountable"
      codes << compatibility
    when "direct_mountable", "direct_mount_disabled"
      codes << "direct_mountable" if codes.empty? && external_project_info_flag(project_info, :direct_mountable) != false
    end
    codes << "direct_mountable" if codes.empty? && external_project_info_flag(project_info, :direct_mountable) == true
    return codes.uniq
  end

  def external_project_mount_mode_labels(project_info)
    labels = external_project_mount_mode_codes(project_info).map do |code|
      case code
      when "prepared_snapshot" then "Prepared Snapshot"
      when "archive_mountable" then "Archive"
      when "extracted_mountable", "extracted_copy_mountable", "extracted_install_mountable" then "Extracted"
      when "source_tree_mountable" then "Source Tree"
      when "direct_mountable" then "Readable Project"
      else
        external_project_humanize_code(code)
      end
    end
    return labels.find_all { |label| !label.to_s.empty? }.uniq
  end

  def external_project_detected_feature_codes(project_info)
    features = []
    features << "prepared_snapshot_detected" if !external_project_info_value(project_info, :prepared_data_root).to_s.empty?
    features << "species_source_detected" if external_species_source_candidates(project_info).length > 0
    features << "species_pack_ready" if external_species_pack_ready?(project_info)
    script_archive_flag = external_project_info_flag(project_info, :script_archive_detected, :has_script_archive, :script_archive_present)
    encrypted_flag = external_project_info_flag(project_info, :encrypted)
    features << "script_archive_detected" if script_archive_flag == true || (script_archive_flag.nil? && encrypted_flag == true)
    features << "plugin_sources_detected" if external_project_info_flag(project_info, :plugin_sources_detected, :has_plugin_sources, :plugin_source_tree_detected) == true
    features << "archive_detected" if external_project_info_flag(project_info, :archive_detected) == true
    features << "source_tree_detected" if external_project_info_flag(project_info, :source_tree_detected, :has_source_tree) == true
    features << "extracted_install_detected" if external_project_info_flag(project_info, :extracted_install_detected, :extracted_copy_detected, :has_extracted_data) == true
    script_sources = external_project_info_value(project_info, :script_sources)
    if script_sources.is_a?(Hash)
      features << "script_archive_detected" if Array(script_sources[:script_archives] || script_sources["script_archives"]).length > 0
      plugin_archives = Array(script_sources[:plugin_script_archives] || script_sources["plugin_script_archives"])
      plugin_dirs = Array(script_sources[:plugin_directories] || script_sources["plugin_directories"])
      features << "plugin_sources_detected" if plugin_archives.length > 0 || plugin_dirs.length > 0
      features << "source_tree_detected" if !(script_sources[:script_directory] || script_sources["script_directory"]).to_s.empty?
    end
    features << "archive_detected" if !external_project_info_value(project_info, :archive_path).to_s.empty?
    features << "extracted_install_detected" if !external_project_info_value(project_info, :data_root).to_s.empty? && external_project_info_value(project_info, :archive_mount_root).to_s.empty?
    return features.uniq
  end

  def external_project_detected_feature_labels(project_info)
    labels = external_project_detected_feature_codes(project_info).map do |code|
      case code
      when "prepared_snapshot_detected" then "Prepared snapshot detected"
      when "species_source_detected" then "Species source detected"
      when "species_pack_ready" then "Species pack prepared"
      when "script_archive_detected" then "Script archive detected"
      when "plugin_sources_detected" then "Plugin sources detected"
      when "archive_detected" then "Archive install detected"
      when "source_tree_detected" then "Source tree detected"
      when "extracted_install_detected" then "Extracted install detected"
      else
        external_project_humanize_code(code)
      end
    end
    return labels.find_all { |label| !label.to_s.empty? }.uniq
  end

  def external_project_compatibility_label(project_info)
    code = external_project_compatibility_code(project_info)
    case code
    when "archive_mountable"
      return "Archive-backed install can be mounted directly"
    when "extracted_mountable", "extracted_copy_mountable", "extracted_install_mountable"
      return "Extracted install can be mounted directly"
    when "source_tree_mountable"
      return "Source tree can be mounted directly"
    when "direct_mountable"
      return "Readable install can be mounted directly"
    when "direct_mount_disabled"
      return "Readable install detected, but direct linking is disabled"
    when "packaged_install_detected"
      return "Packaged archive detected and needs an extracted or source-tree copy"
    when "plugin_sources_detected"
      return "Plugin sources detected"
    when "detection_only"
      return "Install markers were detected, but not enough readable content is available yet"
    else
      return external_project_humanize_code(code)
    end
  end

  def external_project_status_help_text(project_info)
    status_reason = normalize_string(external_project_info_value(project_info, :status_reason), "")
    compatibility_label = external_project_compatibility_label(project_info)
    return status_reason if compatibility_label.empty? || status_reason.empty?
    return "#{compatibility_label}. #{status_reason}"
  end

  def external_project_detail_lines(project_info)
    detail_lines = []
    detail_lines << _INTL("Status: {1}", external_project_status_label(project_info))
    compatibility_label = external_project_compatibility_label(project_info)
    detail_lines << _INTL("Compatibility: {1}", compatibility_label) if !compatibility_label.empty?
    detail_lines << _INTL("Root: {1}", external_project_info_value(project_info, :root).to_s)
    prepared_root = external_project_info_value(project_info, :prepared_data_root)
    detail_lines << _INTL("Prepared data: {1}", prepared_root.to_s) if !prepared_root.to_s.empty?
    prepared_project_root = external_project_info_value(project_info, :prepared_project_root)
    detail_lines << _INTL("Prepared project: {1}", prepared_project_root.to_s) if !prepared_project_root.to_s.empty?
    species_source = external_species_source_path(project_info)
    detail_lines << _INTL("Species source: {1}", species_source.to_s) if !species_source.to_s.empty?
    species_pack = external_species_pack_path(project_info)
    detail_lines << _INTL("Species pack: {1}", species_pack.to_s) if !species_pack.to_s.empty? && File.file?(species_pack)
    readable_maps = external_project_info_value(project_info, :readable_map_count, :map_count)
    detail_lines << _INTL("Readable maps: {1}", integer(readable_maps, 0)) if !readable_maps.nil?
    mount_modes = external_project_mount_mode_labels(project_info)
    detail_lines << _INTL("Mount paths: {1}", mount_modes.join(", ")) if !mount_modes.empty?
    detected_features = external_project_detected_feature_labels(project_info)
    detail_lines << _INTL("Detected features: {1}", detected_features.join(", ")) if !detected_features.empty?
    status_reason = normalize_string(external_project_info_value(project_info, :status_reason), "")
    detail_lines << status_reason if !status_reason.empty?
    return detail_lines
  end

  def external_project_report_entry(project_info)
    entry = {
      "display_name"           => external_project_info_value(project_info, :display_name).to_s,
      "root"                   => external_project_info_value(project_info, :root).to_s,
      "map_count"              => integer(external_project_info_value(project_info, :readable_map_count, :map_count), 0),
      "direct_mountable"       => boolean(external_project_info_value(project_info, :direct_mountable), false),
      "linked"                 => boolean(external_project_info_value(project_info, :should_mount), false),
      "encrypted"              => boolean(external_project_info_value(project_info, :encrypted), false),
      "compatibility"          => external_project_compatibility_code(project_info),
      "compatibility_label"    => external_project_compatibility_label(project_info),
      "status_label"           => external_project_status_label(project_info),
      "status_reason"          => normalize_string(external_project_info_value(project_info, :status_reason), ""),
      "mount_modes"            => external_project_mount_mode_codes(project_info),
      "mount_mode_labels"      => external_project_mount_mode_labels(project_info),
      "detected_features"      => external_project_detected_feature_codes(project_info),
      "detected_feature_labels" => external_project_detected_feature_labels(project_info)
    }
    {
      "archive_mountable"       => [:archive_mountable, :mountable_archive, :archive_backed_mountable],
      "extracted_mountable"     => [:extracted_mountable, :extracted_copy_mountable, :extracted_install_mountable],
      "source_tree_mountable"   => [:source_tree_mountable, :mountable_source_tree, :plugin_source_mountable],
      "prepared_snapshot_available" => [:prepared_snapshot_available],
      "script_archive_detected" => [:script_archive_detected, :has_script_archive, :script_archive_present],
      "plugin_sources_detected" => [:plugin_sources_detected, :has_plugin_sources, :plugin_source_tree_detected]
    }.each_pair do |output_key, keys|
      value = external_project_info_flag(project_info, *keys)
      entry[output_key] = value if !value.nil?
    end
    {
      "source_type"          => [:source_type, :install_type],
      "install_layout"       => [:install_layout, :layout],
      "archive_path"         => [:archive_path],
      "archive_mount_root"   => [:archive_mount_root],
      "prepared_data_root"   => [:prepared_data_root],
      "prepared_project_root" => [:prepared_project_root],
      "data_root"            => [:data_root],
      "script_archive_path"  => [:script_archive_path],
      "script_sources"       => [:script_sources],
      "plugin_source_paths"  => [:plugin_source_paths],
      "compatibility_notes"  => [:compatibility_notes, :compatibility_details]
    }.each_pair do |output_key, keys|
      value = external_project_info_value(project_info, *keys)
      entry[output_key] = value if !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
    end
    species_source = external_species_source_path(project_info)
    entry["species_source_path"] = species_source if !species_source.to_s.empty?
    species_pack = external_species_pack_path(project_info)
    entry["species_pack_path"] = species_pack if !species_pack.to_s.empty? && File.file?(species_pack)
    return entry
  end

  def external_project_status_label(project_info)
    mount_modes = external_project_mount_mode_labels(project_info)
    return mount_modes.empty? ? "Linked" : "Linked (#{mount_modes[0]})" if external_project_info_flag(project_info, :should_mount) == true
    return "Needs Extracted Copy" if external_project_compatibility_code(project_info) == "packaged_install_detected"
    return mount_modes.empty? ? "Detected" : "Detected (#{mount_modes[0]})" if external_project_info_flag(project_info, :direct_mountable) == true || !mount_modes.empty?
    return "Detected (Plugin Sources)" if external_project_info_flag(project_info, :plugin_sources_detected, :has_plugin_sources, :plugin_source_tree_detected) == true
    return "Needs Extracted Copy" if external_project_info_flag(project_info, :encrypted, :script_archive_detected, :has_script_archive, :script_archive_present) == true
    return "Unsupported"
  end

  def can_prepare_external_project?(project_info)
    return false if !external_project_preparable?(project_info)
    return external_project_info_value(project_info, :prepared_data_root).to_s.empty?
  end

  def can_prepare_external_species_pack?(project_info)
    return false if !custom_species_framework_present?
    return false if external_species_pack_ready?(project_info)
    return external_species_source_candidates(project_info).length > 0
  end

  def show_external_project_actions(project_info)
    loop do
      commands = [_INTL("View Details")]
      helps = [_INTL("See detected paths, mount mode, and compatibility notes for this install.")]
      if can_prepare_external_project?(project_info)
        commands << _INTL("Prepare Extracted Snapshot")
        helps << _INTL("Copy readable Data files from the mounted archive into a prepared snapshot for future relinking.")
      end
      if can_extract_external_archive?(project_info) && external_project_info_value(project_info, :prepared_data_root).to_s.empty?
        commands << _INTL("Extract Archive Snapshot")
        helps << _INTL("Unpack the local RGSS archive into ExpansionLibrary/ExtractedArchives, then relink this game through the extracted snapshot after restart.")
      end
      if can_prepare_external_species_pack?(project_info)
        commands << _INTL("Prepare Dex Species Pack")
        helps << _INTL("Generate a Custom Species Framework pack so foreign custom species can append to the end of the host dex after restart.")
      end
      commands << _INTL("Back")
      helps << _INTL("Return to the install list.")
      choice = pbShowCommandsWithHelp(nil, commands, helps, -1, 0)
      break if choice < 0 || choice >= commands.length - 1
      case commands[choice]
      when _INTL("View Details")
        pbMessage(external_project_detail_lines(project_info).join("\n"))
      when _INTL("Prepare Extracted Snapshot")
        result = prepare_external_project(project_info)
        if result["success"]
          project_info[:prepared_data_root] = result["prepared_data_root"]
          project_info[:prepared_project_root] = result["prepared_root"]
          project_info[:prepared_snapshot_available] = true
          project_info[:status_reason] = "Prepared snapshot staged at #{result["prepared_data_root"]}. Restart the game to relink this install through the extracted data snapshot."
          pbMessage(_INTL("Prepared {1} files for {2}.\nSnapshot: {3}\nRestart the game to relink it through the prepared data snapshot.", result["copied_file_count"], result["display_name"], result["prepared_data_root"]))
        else
          pbMessage(_INTL("Snapshot preparation failed.\n{1}", result["error"].to_s))
        end
      when _INTL("Extract Archive Snapshot")
        result = extract_external_archive(project_info)
        if result["success"]
          project_info[:prepared_data_root] = result["prepared_data_root"]
          project_info[:prepared_project_root] = result["output_root"]
          project_info[:prepared_snapshot_available] = true
          project_info[:status_reason] = "Extracted archive staged at #{result["prepared_data_root"]}. Restart the game to relink this install through the extracted data snapshot."
          pbMessage(_INTL("Extracted {1}.\nSnapshot: {2}\nRestart the game to link maps and assets from the extracted snapshot.", result["display_name"], result["prepared_data_root"]))
        else
          pbMessage(_INTL("Archive extraction failed.\n{1}", result["error"].to_s))
        end
      when _INTL("Prepare Dex Species Pack")
        result = prepare_external_species_pack(project_info)
        if result["success"]
          pbMessage(_INTL("Prepared {1} custom species entries for {2}.\nPack: {3}\nRestart the game so they append onto the end of the host dex.", result["species_count"], result["display_name"], result["output_path"]))
        else
          pbMessage(_INTL("Species pack preparation failed.\n{1}", result["error"].to_s))
        end
      end
    end
    return true
  end

  def show_external_project_status
    entries = external_projects.values.sort_by { |info| [info[:should_mount] ? 0 : 1, info[:display_name].to_s.downcase] }
    if entries.empty?
      pbMessage(_INTL("No external installs were detected in the configured scan roots."))
      return false
    end
    loop do
      commands = []
      helps = []
      entries.each do |info|
        commands << _INTL("{1} [{2}]", info[:display_name], external_project_status_label(info))
        helps << external_project_status_help_text(info)
      end
      commands << _INTL("Close")
      helps << _INTL("Return to the travel terminal.")
      choice = pbShowCommandsWithHelp(nil, commands, helps, -1, 0)
      break if choice < 0 || choice >= entries.length
      info = entries[choice]
      show_external_project_actions(info)
    end
    return true
  end

  def expansion_label(expansion_id)
    return "Host World" if expansion_id.nil? || expansion_id.to_s.empty? || expansion_id.to_s == HOST_EXPANSION_ID
    manifest = manifest_for(expansion_id)
    return manifest ? manifest[:name] : expansion_id.to_s
  end

  def prompt_travel_mode(_node)
    return "shared"
  end

  def resolve_node_destination(node)
    anchor = {
      :map_id    => node[:entry_map_id],
      :x         => integer(node[:x], 0),
      :y         => integer(node[:y], 0),
      :direction => integer(node[:direction], 2)
    }
    position_mode = node[:position_mode].to_s
    if position_mode == "last_expansion_anchor"
      expansion_id = node[:expansion_id].to_s
      if !expansion_id.empty?
        state = state_for(expansion_id)
        entry_anchor = sanitize_anchor(anchor)
        remembered = last_expansion_anchor(expansion_id)
        if remembered &&
           expansion_anchor_capture_blocked?(expansion_id, remembered)
          log("[travel] ignored unsafe #{expansion_id} resume anchor #{remembered[:map_id]}") if respond_to?(:log)
          remembered = nil
        end
        if respond_to?(:insurgence_resume_blocked?) &&
           insurgence_resume_blocked?(expansion_id) &&
           node[:id].to_s.end_with?(":entry") &&
           !remembered &&
           entry_anchor
          return entry_anchor
        end
        if respond_to?(:reborn_entry_resume_blocked?) &&
           reborn_entry_resume_blocked?(expansion_id, node) &&
           node[:id].to_s.end_with?(":entry") &&
           entry_anchor
          log("[travel] forcing #{expansion_id} story entry until Reborn post-train sequence completes") if respond_to?(:log)
          return entry_anchor
        end
        if remembered
          if integer(state.travel_count, 0) > 1 && entry_anchor && anchors_match?(remembered, entry_anchor)
            resume_anchor = sanitize_anchor(node[:return_anchor])
            return resume_anchor if resume_anchor
          end
          return remembered
        end
        if integer(state.travel_count, 0) > 1
          resume_anchor = sanitize_anchor(node[:return_anchor])
          return resume_anchor if resume_anchor
        end
      end
    end
    case position_mode
    when "mirror_current"
      if $game_player
        anchor[:x] = $game_player.x
        anchor[:y] = $game_player.y
        anchor[:direction] = $game_player.direction
      end
    when "last_host_anchor"
      host_anchor = default_host_anchor
      anchor[:x] = host_anchor[:x]
      anchor[:y] = host_anchor[:y]
      anchor[:direction] = host_anchor[:direction]
    end
    return sanitize_anchor(anchor)
  end

  def apply_player_direction(direction)
    return if !$game_player
    case direction
    when 2 then $game_player.turn_down
    when 4 then $game_player.turn_left
    when 6 then $game_player.turn_right
    when 8 then $game_player.turn_up
    end
  end

  PLAYER_HOME_FALLBACK_ANCHOR = {
    :map_id    => 42,
    :x         => 12,
    :y         => 10,
    :direction => 2
  }.freeze unless const_defined?(:PLAYER_HOME_FALLBACK_ANCHOR)

  def player_home_anchor
    data = if respond_to?(:with_host_town_map)
      with_host_town_map { pbLoadTownMapData }
    else
      pbLoadTownMapData
    end rescue nil
    if data.is_a?(Array)
      data.each do |region|
        next unless region.is_a?(Array) && region[2].is_a?(Array)
        region[2].each do |location|
          next unless location.is_a?(Array)
          next unless location[2].to_s.strip.casecmp("Pallet Town").zero?
          candidate = sanitize_anchor({
            :map_id    => integer(location[4], 0),
            :x         => integer(location[5], 0),
            :y         => integer(location[6], 0),
            :direction => 2
          })
          return candidate if candidate
        end
      end
    end
    fallback = sanitize_anchor(PLAYER_HOME_FALLBACK_ANCHOR)
    return fallback if fallback
    return sanitize_anchor(default_host_anchor)
  rescue
    fallback = sanitize_anchor(PLAYER_HOME_FALLBACK_ANCHOR)
    return fallback if fallback
    return sanitize_anchor(default_host_anchor)
  end

  def player_at_anchor?(anchor)
    target = sanitize_anchor(anchor)
    return false if !target || !$game_map || !$game_player
    return false if $game_map.map_id.to_i != target[:map_id].to_i
    return false if $game_player.x.to_i != target[:x].to_i
    return false if $game_player.y.to_i != target[:y].to_i
    return true
  rescue
    return false
  end

  def queue_anchor_transfer(anchor)
    target = sanitize_anchor(anchor)
    return false if !target || !$game_temp
    $game_temp.player_transferring = true
    $game_temp.player_new_map_id = target[:map_id]
    $game_temp.player_new_x = target[:x]
    $game_temp.player_new_y = target[:y]
    $game_temp.player_new_direction = target[:direction]
    return true
  end

  def normalize_transfer_context(context, target = nil)
    raw = context.is_a?(Hash) ? context : {}
    expansion_id = raw[:expansion_id] || raw["expansion_id"]
    expansion_id = current_map_expansion_id(target[:map_id]) if (expansion_id.nil? || expansion_id.to_s.empty?) &&
                                                               target &&
                                                               respond_to?(:current_map_expansion_id)
    {
      :source            => (raw[:source] || raw["source"] || :unknown).to_s,
      :expansion_id      => expansion_id.to_s,
      :allow_story_state => boolean(raw[:allow_story_state] || raw["allow_story_state"], false),
      :immediate         => raw.has_key?(:immediate) ? boolean(raw[:immediate], true) : boolean(raw["immediate"], true),
      :auto_rescue       => raw.has_key?(:auto_rescue) ? boolean(raw[:auto_rescue], true) : boolean(raw["auto_rescue"], true)
    }
  rescue
    { :source => "unknown", :expansion_id => "", :allow_story_state => false, :immediate => true, :auto_rescue => true }
  end

  def transfer_preflight_error(target, context)
    return "missing destination" if !target
    map_id = integer(target[:map_id], 0)
    return "invalid map id #{map_id}" if map_id <= 0
    return "map #{map_id} is unavailable" if !valid_map_id?(map_id)
    expansion_id = context[:expansion_id].to_s
    map_expansion = current_map_expansion_id(map_id)
    if !map_expansion.to_s.empty?
      return "expansion #{map_expansion} is disabled" if !expansion_active?(map_expansion)
      return "destination expansion mismatch #{expansion_id} -> #{map_expansion}" if !expansion_id.empty? &&
                                                                                     expansion_id != map_expansion.to_s
    end
    if map_expansion.to_s.empty? && map_id >= RESERVED_MAP_BLOCK_START
      return "reserved map #{map_id} has no active expansion"
    end
    return nil
  rescue => e
    return "preflight failed: #{e.class}: #{e.message}"
  end

  def mark_pending_safe_transfer(context, from_anchor, target_anchor)
    return if !$game_temp
    payload = {
      :context => context,
      :from    => normalize_anchor(from_anchor),
      :to      => normalize_anchor(target_anchor)
    }
    $game_temp.instance_variable_set(:@tef_pending_safe_transfer, payload)
  rescue
  end

  def pending_safe_transfer
    return nil if !$game_temp
    value = $game_temp.instance_variable_get(:@tef_pending_safe_transfer) rescue nil
    return value.is_a?(Hash) ? value : nil
  rescue
    return nil
  end

  def clear_pending_safe_transfer
    $game_temp.instance_variable_set(:@tef_pending_safe_transfer, nil) if $game_temp
  rescue
  end

  def complete_pending_safe_transfer!(actual_anchor = nil)
    pending = pending_safe_transfer
    return false if !pending
    context = normalize_transfer_context(pending[:context], pending[:to])
    target = sanitize_anchor(actual_anchor || current_anchor || pending[:to])
    if target
      record_completed_transition(context[:source], context[:expansion_id], pending[:from], target) if respond_to?(:record_completed_transition)
      store_canonical_location(context[:expansion_id].to_s.empty? ? "host" : "expansion", context[:expansion_id], target, context[:source]) if respond_to?(:store_canonical_location)
    end
    clear_pending_safe_transfer
    return true
  rescue => e
    log("[travel] pending transfer finalize failed: #{e.class}: #{e.message}") if respond_to?(:log)
    clear_pending_safe_transfer
    return false
  end

  def rollback_failed_transfer!(from_anchor, target_anchor, context, error)
    record_failed_transition(context[:source], context[:expansion_id], from_anchor, target_anchor, error) if respond_to?(:record_failed_transition)
    release_player_movement_lock if respond_to?(:release_player_movement_lock)
    clear_pending_safe_transfer
    return false if !context[:auto_rescue]
    return false if context[:source].to_s == "trainer_card_return"
    rescue_anchor = player_home_anchor if respond_to?(:player_home_anchor)
    rescue_anchor = sanitize_anchor(rescue_anchor)
    return false if !rescue_anchor || player_at_anchor?(rescue_anchor)
    log("[travel] auto-rescuing player to host after failed #{context[:source]} transfer") if respond_to?(:log)
    safe_transfer_to_anchor(rescue_anchor, {
      :source      => :auto_rescue,
      :immediate   => true,
      :auto_rescue => false
    })
  rescue => e
    log("[travel] transfer rollback failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def safe_transfer_to_anchor(anchor, context = {})
    return false if @safe_transfer_depth.to_i > 3
    target = sanitize_anchor(anchor)
    normalized_context = normalize_transfer_context(context, target)
    from_anchor = current_anchor
    rebuild_host_dex_shadow_from_storage! if respond_to?(:rebuild_host_dex_shadow_from_storage!)
    error = transfer_preflight_error(target, normalized_context)
    if error
      return rollback_failed_transfer!(from_anchor, target, normalized_context, error)
    end

    target_expansion = current_map_expansion_id(target[:map_id])
    previous_expansion = current_expansion_id
    if previous_expansion.to_s.empty? && !target_expansion.to_s.empty?
      remember_host_anchor_from_current_location
    elsif !previous_expansion.to_s.empty? && previous_expansion != target_expansion.to_s
      remember_expansion_anchor_from_current_location(previous_expansion)
    end
    if target_expansion.to_s.empty?
      clear_current_expansion
    else
      set_current_expansion(target_expansion)
      normalized_context[:expansion_id] = target_expansion.to_s
    end

    mark_pending_safe_transfer(normalized_context, from_anchor, target)
    if !normalized_context[:immediate] || !$scene || !$scene.respond_to?(:transfer_player)
      queued = queue_anchor_transfer(target)
      return queued if queued
      return rollback_failed_transfer!(from_anchor, target, normalized_context, "failed to queue transfer")
    end

    @safe_transfer_depth = @safe_transfer_depth.to_i + 1
    transfer_result = nil
    pbFadeOutIn {
      if queue_anchor_transfer(target)
        transfer_result = $scene.transfer_player(false)
        if transfer_result != false
          $game_map.autoplay if $game_map && $game_map.respond_to?(:autoplay)
          $game_map.refresh if $game_map && $game_map.respond_to?(:refresh)
        end
      else
        transfer_result = false
      end
    }
    return rollback_failed_transfer!(from_anchor, target, normalized_context, "failed to complete transfer") if transfer_result == false && pending_safe_transfer
    return false if transfer_result == false
    complete_pending_safe_transfer!(current_anchor)
    restore_host_dex_shadow_to_player! if respond_to?(:restore_host_dex_shadow_to_player!)
    start_home_pc_reentry_guard(90)
    return true
  rescue => e
    safe_context = normalized_context || normalize_transfer_context(context, target)
    return rollback_failed_transfer!(from_anchor, target, safe_context, "#{e.class}: #{e.message}")
  ensure
    @safe_transfer_depth = [@safe_transfer_depth.to_i - 1, 0].max
  end

  def purge_expansion_map_trail!
    return if !$PokemonGlobal || !$PokemonGlobal.respond_to?(:mapTrail=)
    trail = Array($PokemonGlobal.mapTrail)
    if trail.empty?
      $PokemonGlobal.mapTrail = []
      return
    end
    filtered = trail.find_all do |map_id|
      expansion_id = current_map_expansion_id(map_id)
      expansion_id.nil? || expansion_id.to_s.empty?
    end
    $PokemonGlobal.mapTrail = filtered
  rescue
    $PokemonGlobal.mapTrail = [] if $PokemonGlobal && $PokemonGlobal.respond_to?(:mapTrail=)
  end

  def prepare_host_return(anchor)
    target = sanitize_anchor(anchor)
    return nil if !target
    previous_expansion = current_expansion_id
    remember_expansion_anchor_from_current_location(previous_expansion) if !previous_expansion.to_s.empty?
    clear_current_expansion
    purge_expansion_map_trail!
    release_player_movement_lock if respond_to?(:release_player_movement_lock)
    return target
  end

  def run_anchor_transfer(anchor, immediate: true, source: :manual_transfer, expansion_id: nil, allow_story_state: false)
    target = sanitize_anchor(anchor)
    return false if !target
    return safe_transfer_to_anchor(target, {
      :source            => source,
      :expansion_id      => expansion_id,
      :allow_story_state => allow_story_state,
      :immediate         => immediate
    })
  end

  def transfer_to_anchor(anchor, context = {})
    anchor = sanitize_anchor(anchor)
    return false if !anchor
    context = context.is_a?(Hash) ? context : {}
    context[:source] ||= :manual_transfer
    context[:immediate] = true if !context.has_key?(:immediate)
    return safe_transfer_to_anchor(anchor, context)
  end

  def travel_to_node(node)
    return false if !node
    mode = prompt_travel_mode(node)
    return false if mode.nil?
    expansion_id = node[:expansion_id].to_s
    previous_expansion = current_expansion_id
    destination = resolve_node_destination(node)
    if !destination || !valid_map_id?(destination[:map_id])
      log("[travel] blocked invalid destination for #{expansion_id}: #{destination.inspect}") if respond_to?(:log)
      return false
    end
    if previous_expansion.to_s.empty?
      remember_host_anchor_from_current_location
    elsif previous_expansion != expansion_id
      remember_expansion_anchor_from_current_location(previous_expansion)
    end
    state = state_for(expansion_id)
    state.last_mode = "shared"
    state.isolated_mode = false
    state.last_entry_at = Time.now.to_i
    state.travel_count += 1
    if expansion_id == XENOVERSE_EXPANSION_ID && respond_to?(:xenoverse_prepare_session_for_entry!)
      xenoverse_prepare_session_for_entry!(mode)
    end
    set_current_expansion(expansion_id)
    success = safe_transfer_to_anchor(destination, {
      :source            => :travel_terminal,
      :expansion_id      => expansion_id,
      :allow_story_state => false,
      :immediate         => true
    })
    if !success && expansion_id == XENOVERSE_EXPANSION_ID && respond_to?(:xenoverse_restore_host_session!)
      xenoverse_restore_host_session!
    end
    if !success
      if previous_expansion.to_s.empty?
        clear_current_expansion
      else
        set_current_expansion(previous_expansion)
      end
      log("[travel] transfer to #{expansion_id} failed; restored previous expansion marker #{previous_expansion.inspect}") if respond_to?(:log)
    end
    return success
  end

  def return_home(immediate: true)
    return safe_return_home!(source: :return_home, immediate: immediate)
  end

  def return_to_host_world(immediate: true)
    target = prepare_host_return(default_host_anchor)
    return false if !target
    return true if player_at_anchor?(target) && current_map_expansion_id.nil?
    return run_anchor_transfer(target, immediate: immediate, source: :return_to_host_world)
  end

  def safe_return_home_blocked?
    return true if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:in_battle) && $game_temp.in_battle
    return true if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:player_transferring) && $game_temp.player_transferring
    return true if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:message_window_showing) && $game_temp.message_window_showing
    return true if defined?($game_temp) && $game_temp && $game_temp.respond_to?(:transition_processing) && $game_temp.transition_processing
    return false
  rescue
    return true
  end

  def safe_return_home!(source: :trainer_card_return, immediate: true)
    return false if safe_return_home_blocked?
    anchor = player_home_anchor
    return false if !anchor
    return true if player_at_anchor?(anchor) && current_map_expansion_id.nil?
    target = prepare_host_return(anchor)
    return false if !target
    return safe_transfer_to_anchor(target, {
      :source      => source,
      :immediate   => immediate,
      :auto_rescue => false
    })
  end

  def home_pc_custom_species_label
    return nil if !defined?(CustomSpeciesFramework)
    return nil if !CustomSpeciesFramework.respond_to?(:home_pc_command_label)
    return nil if !CustomSpeciesFramework.respond_to?(:open_home_pc_delivery_menu)
    label = CustomSpeciesFramework.home_pc_command_label.to_s
    return nil if label.empty?
    return label
  rescue
    return nil
  end

  def open_home_pc_custom_species
    return false if !defined?(CustomSpeciesFramework)
    return false if !CustomSpeciesFramework.respond_to?(:open_home_pc_delivery_menu)
    CustomSpeciesFramework.open_home_pc_delivery_menu
    return true
  rescue
    return false
  end

  def can_change_bedroom_style_from_pc?
    return false if !defined?(PlayerIdentityBedroomAddon)
    return false if !PlayerIdentityBedroomAddon.respond_to?(:change_bedroom_style_from_pc)
    if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:player_home_pc_context?)
      return CustomSpeciesFramework.player_home_pc_context?
    end
    return true
  rescue
    return false
  end

  def change_bedroom_style_from_pc
    return false if !can_change_bedroom_style_from_pc?
    return !!PlayerIdentityBedroomAddon.change_bedroom_style_from_pc
  rescue
    return false
  end

  def open_travel_terminal
    commands = []
    helps = []
    actions = []
    if current_expansion_id
      commands << _INTL("Return to Host World")
      helps << _INTL("Leave {1} and go back to the last safe host location.", expansion_label(current_expansion_id))
      actions << [:return, nil]
    end
    travelable_nodes.each do |node|
      commands << node[:name]
      helps << node[:description]
      actions << [:travel, node]
    end
    commands << _INTL("Cancel")
    helps << _INTL("Return to the previous menu.")
    choice = pbShowCommandsWithHelp(nil, commands, helps, -1, 0)
    return :cancelled if choice < 0 || choice >= actions.length
    action, payload = actions[choice]
    case action
    when :return
      return return_to_host_world ? :transferred : :cancelled
    when :travel
      return travel_to_node(payload) ? :transferred : :cancelled
    end
    return :cancelled
  end

  def pbBedroomPCMenu
    command = 0
    loop do
      commands = []
      helps = []
      cmd_item_storage = commands.length
      commands << _INTL("Item Storage")
      helps << _INTL("Take out items from the PC or store items for later.")
      cmd_mailbox = commands.length
      commands << _INTL("Mailbox")
      helps << _INTL("Read and manage the Mail stored on this PC.")
      cmd_custom_species = -1
      custom_species_label = home_pc_custom_species_label
      if custom_species_label
        cmd_custom_species = commands.length
        commands << custom_species_label
        helps << _INTL("Review or claim pending custom species deliveries.")
      end
      cmd_bedroom_color = -1
      if can_change_bedroom_style_from_pc?
        cmd_bedroom_color = commands.length
        commands << _INTL("Change Bedroom Color")
        helps << _INTL("Swap to a different bedroom style from the PC.")
      end
      cmd_travel = -1
      if travel_terminal_enabled?
        cmd_travel = commands.length
        commands << _INTL("Travel to Other Lands")
        helps << _INTL("Enter installed expansion packs or return from an active expansion.")
      end
      commands << _INTL("Turn Off")
      helps << _INTL("Return to the game.")
      command = pbShowCommandsWithHelp(nil, commands, helps, -1, command)
      case command
      when cmd_item_storage then pbPCItemStorage
      when cmd_mailbox then pbPCMailbox
      when cmd_custom_species then open_home_pc_custom_species
      when cmd_bedroom_color
        break if change_bedroom_style_from_pc
      when cmd_travel
        result = open_travel_terminal
        break if result == :transferred
      else
        break
      end
    end
  end

  def open_counterfeit_bedroom_pc_menu
    return pbBedroomPCMenu if !defined?(CounterfeitShinies)
    command = 0
    loop do
      commands = []
      cmd_item_storage = commands.length
      commands << _INTL(CounterfeitShinies::Config::PC_MENU_ITEM_STORAGE)
      cmd_mailbox = commands.length
      commands << _INTL(CounterfeitShinies::Config::PC_MENU_MAILBOX)
      cmd_custom_species = -1
      custom_species_label = home_pc_custom_species_label
      if custom_species_label
        cmd_custom_species = commands.length
        commands << custom_species_label
      end
      cmd_workshop = commands.length
      commands << _INTL(CounterfeitShinies::Config::PC_MENU_WORKSHOP)
      cmd_launder = commands.length
      commands << CounterfeitShinies.bedroom_pc_launder_label
      cmd_bedroom_color = -1
      if can_change_bedroom_style_from_pc?
        cmd_bedroom_color = commands.length
        commands << _INTL(CounterfeitShinies::Config::PC_MENU_BEDROOM_COLOR)
      end
      cmd_travel = -1
      if travel_terminal_enabled?
        cmd_travel = commands.length
        commands << _INTL("Travel to Other Lands")
      end
      cmd_turn_off = commands.length
      commands << _INTL(CounterfeitShinies::Config::PC_MENU_TURN_OFF)
      command = pbMessage(_INTL(CounterfeitShinies::Config::PC_MENU_PROMPT), commands, -1, nil, command)
      case command
      when cmd_item_storage then pbPCItemStorage
      when cmd_mailbox then pbPCMailbox
      when cmd_custom_species then open_home_pc_custom_species
      when cmd_workshop then CounterfeitShinies.open_workshop
      when cmd_launder then CounterfeitShinies.open_laundry
      when cmd_bedroom_color
        break if change_bedroom_style_from_pc
      when cmd_travel
        result = open_travel_terminal
        break if result == :transferred
      when cmd_turn_off, -1
        break
      end
    end
    return true
  end
end

def pbTrainerPCMenu
  return TravelExpansionFramework.pbBedroomPCMenu
end

alias tef_original_pbTrainerPC pbTrainerPC unless defined?(tef_original_pbTrainerPC)
def pbTrainerPC
  if TravelExpansionFramework.home_pc_reentry_blocked?
    Input.update if defined?(Input) && Input.respond_to?(:update)
    return
  end
  return if $game_temp && $game_temp.respond_to?(:player_transferring) && $game_temp.player_transferring
  begin
    return tef_original_pbTrainerPC
  ensure
    TravelExpansionFramework.finish_home_pc_session
  end
end

if defined?(CounterfeitShinies)
  singleton = class << CounterfeitShinies; self; end
  singleton.send(:define_method, :open_bedroom_pc_menu) do
    return TravelExpansionFramework.open_counterfeit_bedroom_pc_menu
  end
end

if defined?(MultiplayerUI) && defined?(MultiplayerUI::ProfilePanel)
  profile_panel_singleton = class << MultiplayerUI::ProfilePanel; self; end
  profile_panel_singleton.send(:define_method, :_handle_return_to_pallet) do
    anchor = TravelExpansionFramework.player_home_anchor
    if TravelExpansionFramework.player_at_anchor?(anchor) && TravelExpansionFramework.current_map_expansion_id.nil?
      close
      return
    end
    if TravelExpansionFramework.safe_return_home!(source: :trainer_card_return, immediate: true)
      close
      return
    end
    pbMessage(_INTL("Return unavailable right now."))
  rescue
    pbMessage(_INTL("Return failed."))
  end
end

class PokemonTrainerCard_Scene
  alias tef_original_pbStartScene pbStartScene

  def pbStartScene
    @tef_page_index = 0
    @tef_pages = TravelExpansionFramework.trainer_card_pages
    @tef_close_after_home_return = false
    tef_original_pbStartScene
  end

  def trainerCardActions
    cmd_swapBackground = _INTL("Swap background")
    cmd_copyTrainerID = _INTL("Copy Trainer ID")
    cmd_returnHome = _INTL("Return Home")
    cmd_cashOutPlatinum = _INTL("Cash out Platinum")
    cmd_cancel = _INTL("Cancel")
    commands = [cmd_swapBackground, cmd_copyTrainerID, cmd_returnHome]
    commands << cmd_cashOutPlatinum if defined?(MultiplayerPlatinum)
    commands << cmd_cancel
    choice = optionsMenu(commands)
    return if choice.nil? || choice < 0
    case commands[choice]
    when cmd_swapBackground
      promptSwapBackground
    when cmd_copyTrainerID
      Input.clipboard = $Trainer.id.to_s
      pbMessage(_INTL("Your Trainer ID was copied to the clipboard!"))
    when cmd_returnHome
      anchor = TravelExpansionFramework.player_home_anchor
      if TravelExpansionFramework.player_at_anchor?(anchor) && TravelExpansionFramework.current_map_expansion_id.nil?
        pbMessage(_INTL("You're already home."))
      elsif TravelExpansionFramework.safe_return_home!(source: :trainer_card_return, immediate: false)
        @tef_close_after_home_return = true
      else
        pbMessage(_INTL("Return home unavailable right now."))
      end
    when cmd_cashOutPlatinum
      max_amount = MultiplayerPlatinum.cashout_max_amount(refresh: true)
      if max_amount <= 0
        pbMessage(_INTL("You don't have any Platinum to cash out."))
        return
      end

      amount = MultiplayerPlatinum.prompt_cashout_amount(max_amount, 1) { pbUpdate }
      return if amount.nil?

      money_amount = MultiplayerPlatinum.cashout_value(amount)
      return unless pbConfirmMessage(_INTL("Convert {1} Platinum into ${2}?", amount, money_amount.to_s_formatted))

      ok, result = MultiplayerPlatinum.convert_to_money(amount, money_amount, "trainer_card_menu_convert")
      if ok
        request_platinum_balance_from_server(force: true) if respond_to?(:request_platinum_balance_from_server)
        pbDrawTrainerCardFront
        pbMessage(_INTL("Converted {1} Platinum into ${2}.", amount, money_amount.to_s_formatted))
        pbDrawTrainerCardFront
      else
        pbMessage(_INTL(result.to_s))
      end
    end
  end

  def tef_current_card_page
    @tef_pages ||= TravelExpansionFramework.trainer_card_pages
    return @tef_pages[@tef_page_index] || @tef_pages.first
  end

  def pbDrawTrainerCardFront
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    baseColor = Color.new(72, 72, 72)
    shadowColor = Color.new(160, 160, 160)
    $PokemonGlobal.startTime = pbGetTimeNow if !$PokemonGlobal.startTime
    starttime = "#{pbGetAbbrevMonthName($PokemonGlobal.startTime.mon)} #{$PokemonGlobal.startTime.day}, #{$PokemonGlobal.startTime.year}"
    page = tef_current_card_page
    global_badges = $Trainer.respond_to?(:global_badge_count) ? $Trainer.global_badge_count : ($Trainer.badges || []).count(true)
    textPositions = [
      [_INTL("Campaign"), 34, 58, 0, baseColor, shadowColor],
      [page[:label].to_s, 302, 58, 1, baseColor, shadowColor],
      [_INTL("Name"), 34, 106, 0, baseColor, shadowColor],
      [$Trainer.name, 302, 106, 1, baseColor, shadowColor],
      [_INTL("Money"), 34, 154, 0, baseColor, shadowColor],
      [_INTL("${1}", $Trainer.money.to_s_formatted), 302, 154, 1, baseColor, shadowColor],
      [_INTL("Pokedex"), 34, 202, 0, baseColor, shadowColor],
      [sprintf("%d/%d", page[:owned_count], page[:seen_count]), 302, 202, 1, baseColor, shadowColor],
      [_INTL("Global"), 34, 250, 0, baseColor, shadowColor],
      [_INTL("Badges {1}  Dex {2}/{3}", global_badges, page[:global_owned], page[:global_seen]), 302, 250, 1, baseColor, shadowColor],
      [_INTL("Started"), 34, 298, 0, baseColor, shadowColor],
      [starttime, 302, 298, 1, baseColor, shadowColor],
      [_INTL("Page {1}/{2}", @tef_page_index + 1, @tef_pages.length), 462, 28, 1, baseColor, shadowColor],
      [_INTL("Trainer ID"), 352, 58, 0, baseColor, shadowColor],
      [sprintf("%05d", $Trainer.id), 462, 88, 1, baseColor, shadowColor],
      [_INTL("Badges"), 352, 122, 0, baseColor, shadowColor],
      [_INTL("{1}/{2}", page[:badge_obtained], page[:badge_total]), 462, 152, 1, baseColor, shadowColor]
    ]
    pbDrawTextPositions(overlay, textPositions)
    imagePositions = []
    x = 72
    page[:badge_values].each_with_index do |owned, index|
      next if !owned
      row = index < 8 ? 0 : 1
      badge_graphic_x = row == 0 ? index * 32 : (index - 8) * 32
      badge_graphic_y = row * 32
      draw_y = row == 0 ? 346 : 380
      imagePositions << ["Graphics/Pictures/Trainer Card/icon_badges", x, draw_y, badge_graphic_x, badge_graphic_y, 32, 32]
      x += 48
      x = 72 if index == 7
    end
    pbDrawImagePositions(overlay, imagePositions)
  end

  def pbTrainerCard
    pbSEPlay("GUI trainer card open")
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @tef_pages.length > 1 && Input.trigger?(Input::LEFT)
        @tef_page_index = (@tef_page_index - 1) % @tef_pages.length
        pbPlayCursorSE
        pbDrawTrainerCardFront
      elsif @tef_pages.length > 1 && Input.trigger?(Input::RIGHT)
        @tef_page_index = (@tef_page_index + 1) % @tef_pages.length
        pbPlayCursorSE
        pbDrawTrainerCardFront
      elsif Input.trigger?(Input::USE)
        trainerCardActions
        if @tef_close_after_home_return
          pbPlayCloseMenuSE
          break
        end
        pbDrawTrainerCardFront
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      end
    end
  end
end

class PokemonPauseMenu_Scene
  alias tef_original_pbShowCommands pbShowCommands unless defined?(tef_original_pbShowCommands)

  def pbShowCommands(commands)
    return -1 if $game_temp && $game_temp.player_transferring
    return tef_original_pbShowCommands(commands)
  end
end
