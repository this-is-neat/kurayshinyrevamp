module TravelExpansionFramework
  module_function

  def bootstrap!
    reset_registries!
    scan_installed_expansions!
    refresh_runtime_flags!
    refresh_release_compatibility! if respond_to?(:refresh_release_compatibility!)
    normalize_save_root!
    run_pending_migrations!
    mark_bootstrapped!
    return true
  end

  def scan_installed_expansions!
    scan_local_mod_expansions!
    scan_external_projects!
  end

  def scan_local_mod_expansions!
    mods = []
    if defined?(ModManager) && ModManager.respond_to?(:registry)
      mods = ModManager.registry.values
    end
    mods.sort_by { |info| info.id.to_s }.each do |mod_info|
      manifest_path = File.join(mod_info.folder_path, MANIFEST_FILENAME)
      next if !File.file?(manifest_path)
      raw_manifest = safe_json_parse(manifest_path)
      next if !raw_manifest.is_a?(Hash)
      manifest = normalize_manifest(raw_manifest, mod_info)
      register_manifest(manifest) if manifest
    end
  end

  def default_source_config_hash
    return {
      "search_roots"                    => ["../PokemonMultiverse", "../", "./ExpansionLibrary"],
      "ignore_directories"              => [File.basename(current_game_root), "ExpansionLibrary", "ExpansionLinks"],
      "auto_link_readable_projects"     => true,
      "allow_direct_mount_without_link_file" => true,
      "projects"                        => {}
    }
  end

  def source_config
    config = default_source_config_hash
    raw = safe_json_parse(source_config_path)
    if raw.is_a?(Hash)
      config["search_roots"] = raw["search_roots"] if raw["search_roots"].is_a?(Array)
      config["ignore_directories"] = raw["ignore_directories"] if raw["ignore_directories"].is_a?(Array)
      config["auto_link_readable_projects"] = raw["auto_link_readable_projects"] if raw.has_key?("auto_link_readable_projects")
      config["allow_direct_mount_without_link_file"] = raw["allow_direct_mount_without_link_file"] if raw.has_key?("allow_direct_mount_without_link_file")
      if raw["projects"].is_a?(Hash)
        config["projects"] = config["projects"].merge(raw["projects"])
      end
    end
    return config
  end

  def source_link_overrides
    overrides = {}
    return overrides if !File.directory?(links_dir)
    Dir[File.join(links_dir, "*.json")].sort.each do |path|
      next if File.basename(path) == "external_project_link.template.json"
      raw = safe_json_parse(path)
      next if !raw.is_a?(Hash)
      roots = [raw["root"]]
      roots.concat(Array(raw["root_aliases"]))
      roots.concat(Array(raw["alternate_roots"]))
      roots.map { |entry| normalize_path(entry, current_game_root) }.compact.uniq.each do |root|
        normalized = raw.dup
        normalized["root"] = root
        overrides[root] = normalized
      end
    end
    return overrides
  end

  def project_title_from_ini(root_path)
    ini_path = File.join(root_path, "Game.ini")
    ini_path = Dir[File.join(root_path, "*.ini")].sort.first if !File.file?(ini_path)
    return nil if !ini_path || !File.file?(ini_path)
    File.open(ini_path, "rb") do |file|
      file.each_line do |line|
        line = line.to_s.encode("UTF-8", "binary", :invalid => :replace, :undef => :replace, :replace => "")
        line.gsub!(/\r?\n\z/, "")
        next if line !~ /\ATitle\s*=\s*(.+)\z/i
        return normalize_string($1, File.basename(root_path))
      end
    end
    return nil
  rescue
    return nil
  end

  def project_override_roots(override)
    return [] if !override.is_a?(Hash)
    raw_roots = []
    raw_roots << override["root"]
    raw_roots.concat(Array(override["root_aliases"]))
    raw_roots.concat(Array(override["alternate_roots"]))
    return raw_roots.map { |entry| normalize_path(entry, current_game_root) }.compact.uniq
  rescue
    return []
  end

  def external_project_dirs_from_roots
    config = source_config
    roots = Array(config["search_roots"]).map { |entry| normalize_path(entry, current_game_root) }.compact.uniq
    project_overrides = config["projects"].is_a?(Hash) ? config["projects"] : {}
    project_overrides.each_value do |override|
      project_override_roots(override).each do |root|
        roots << root if root && File.directory?(root)
      end
    end
    link_overrides = source_link_overrides
    roots.concat(link_overrides.keys.map { |root| File.directory?(root) ? root : File.dirname(root) }.compact)
    roots.uniq!
    ignore_names = Array(config["ignore_directories"]).map { |name| name.to_s.downcase }
    candidates = {}
    roots.each do |root|
      next if !root || !File.directory?(root)
      if File.file?(File.join(root, "Game.exe")) || File.file?(File.join(root, "Game.ini")) || File.directory?(File.join(root, "Data"))
        folder_name = File.basename(root).downcase
        next if ignore_names.include?(folder_name)
        candidates[root] = true
      end
      Dir[File.join(root, "*")].sort.each do |child|
        next if !File.directory?(child)
        folder_name = File.basename(child).downcase
        next if ignore_names.include?(folder_name)
        next if File.expand_path(child) == current_game_root
        has_install_markers = File.file?(File.join(child, "Game.exe")) ||
                              File.file?(File.join(child, "Game.ini")) ||
                              File.file?(File.join(child, "Uranium.exe")) ||
                              File.directory?(File.join(child, "Data")) ||
                              Dir[File.join(child, "*.rgssad")].length > 0
        candidates[child] = true if has_install_markers
      end
    end
    return candidates.keys.sort
  end

  def project_override_for_root(root_path)
    config = source_config
    overrides = config["projects"].is_a?(Hash) ? config["projects"] : {}
    normalized_root = File.expand_path(root_path)
    overrides.each_pair do |project_key, override|
      next if !override.is_a?(Hash)
      if project_override_roots(override).any? { |override_root| File.expand_path(override_root) == normalized_root }
        return override.merge("id" => normalize_string(override["id"], project_key))
      end
    end
    return nil
  end

  def project_link_override_for_root(root_path)
    return source_link_overrides[File.expand_path(root_path)]
  end

  def external_archive_candidates(root_path)
    patterns = ["*.rgssad", "*.rgss2a", "*.rgss3a"]
    candidates = []
    patterns.each { |pattern| candidates.concat(Dir[File.join(root_path, pattern)].sort) }
    priorities = [
      File.join(root_path, "Game.rgssad"),
      File.join(root_path, "Game.rgss2a"),
      File.join(root_path, "Game.rgss3a"),
      File.join(root_path, "#{File.basename(root_path)}.rgssad"),
      File.join(root_path, "#{File.basename(root_path)}.rgss2a"),
      File.join(root_path, "#{File.basename(root_path)}.rgss3a")
    ]
    ordered = priorities.find_all { |path| File.file?(path) }
    candidates.each { |path| ordered << path if !ordered.include?(path) }
    return ordered
  end

  def project_archive_mount_root(project_id)
    return virtual_mount_point(project_id, "archive")
  end

  def project_source_mount_root(project_id)
    return virtual_mount_point(project_id, "project")
  end

  def mounted_data_root_for_project(project_id, archive_path)
    mount_root = project_archive_mount_root(project_id)
    return nil if !mount_source!(archive_path, mount_root)
    return runtime_path_join(mount_root, "Data")
  end

  def mounted_project_root_for_project(project_id, root_path)
    mount_root = project_source_mount_root(project_id)
    return nil if !mount_source!(root_path, mount_root)
    return mount_root
  end

  def detect_map_ids_from_data_root(data_root)
    map_ids = []
    map_infos_path = runtime_path_join(data_root, "MapInfos.rxdata")
    if runtime_file_exists?(map_infos_path)
      begin
        map_infos = load_marshaled_runtime(map_infos_path)
        if map_infos.respond_to?(:keys)
          map_ids = map_infos.keys.map { |id| integer(id, 0) }.find_all { |id| id > 0 }.sort
        end
      rescue => e
        log("Unable to read map infos from #{data_root}: #{e.message}")
      end
    end
    if map_ids.empty?
      if absolute_path?(data_root)
        map_files = Dir[File.join(data_root, "Map*.rxdata")].sort
        map_ids = map_files.map { |path| integer(File.basename(path)[/\d+/], 0) }.find_all { |id| id > 0 }.sort
      else
        1.upto(999) do |id|
          path = runtime_path_join(data_root, format("Map%03d.rxdata", id))
          map_ids << id if runtime_file_exists?(path)
        end
      end
    end
    return map_ids.uniq.sort
  end

  def detect_script_sources(root_path, data_root)
    catalog = {
      :data_root                => data_root,
      :script_archives          => [],
      :plugin_script_archives   => [],
      :script_directory         => nil,
      :script_directory_count   => 0,
      :plugin_directories       => [],
      :plugin_meta_count        => 0
    }
    ["Scripts.rxdata", "Scripts.rvdata2", "Scripts.rvdata", "EditorScripts.rxdata", "PositionerScripts.rxdata"].each do |filename|
      path = runtime_path_join(data_root, filename)
      next if !runtime_file_exists?(path)
      catalog[:script_archives] << {
        :name => filename,
        :path => path
      }
    end
    ["PluginScripts.rxdata"].each do |filename|
      path = runtime_path_join(data_root, filename)
      next if !runtime_file_exists?(path)
      catalog[:plugin_script_archives] << {
        :name => filename,
        :path => path
      }
    end
    script_dir = File.join(root_path, "Data", "Scripts")
    if File.directory?(script_dir)
      catalog[:script_directory] = script_dir
      catalog[:script_directory_count] = Dir[File.join(script_dir, "**", "*.rb")].length
    end
    ["Plugins", "Plugin"].each do |folder_name|
      folder = File.join(root_path, folder_name)
      next if !File.directory?(folder)
      catalog[:plugin_directories] << folder
      catalog[:plugin_meta_count] += Dir[File.join(folder, "**", "meta.txt")].length
    end
    return catalog
  end

  ENTRY_NAME_REJECT_PATTERN = /\b(intro|title|credits|credit|debug|test|menu|bootstrap|splash)\b/i
  ENTRY_SETTLEMENT_PATTERN = /\b(ward|city|town|ranch|village|street|alley|road|path|square|plaza|harbor|harbour|dock|shore|beach|campus)\b/i
  ENTRY_WILDS_PATTERN = /\b(route|forest|woods|cave|desert|mount|mountain|island|outskirts|park|field|plains)\b/i
  ENTRY_INTERIOR_PATTERN = /\b(room|stanza|house|home|apartment|center|mart|gym|school|academy|lab|laboratory|office|museum|ship|boat|train|floor|basement|hall|interior|void|vuoto)\b/i
  SCRIPT_TRANSFER_PATTERNS = [
    /pbTeleport\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*(\d+))?/i,
    /pbMapWarp\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*(\d+))?/i,
    /pbDungeonWarp\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*(\d+))?/i
  ].freeze

  def external_map_info_name(map_infos, map_id)
    return "" if !map_infos.respond_to?(:[])
    info = map_infos[integer(map_id, 0)]
    return "" if !info
    return info.name.to_s if info.respond_to?(:name)
    return info[:name].to_s if info.is_a?(Hash) && info[:name]
    return info["name"].to_s if info.is_a?(Hash) && info["name"]
    return ""
  rescue
    return ""
  end

  def intro_like_external_map?(map_infos, map_id)
    name = external_map_info_name(map_infos, map_id)
    return false if name.empty?
    return name.match?(ENTRY_NAME_REJECT_PATTERN)
  end

  def external_entry_anchor_score(map_infos, anchor, depth = 0, reference_name = nil)
    return -9_999 if !anchor || integer(anchor[:map_id], 0) <= 0
    target_name = external_map_info_name(map_infos, anchor[:map_id])
    score = 100 - (depth * 10)
    score += 220 if target_name.match?(ENTRY_SETTLEMENT_PATTERN)
    score += 40 if target_name.match?(ENTRY_WILDS_PATTERN)
    score -= 180 if target_name.match?(ENTRY_INTERIOR_PATTERN)
    normalized_reference = reference_name.to_s.strip.downcase
    normalized_target = target_name.to_s.strip.downcase
    if !normalized_reference.empty? && !normalized_target.empty?
      score += 120 if normalized_reference == normalized_target
      score += 40 if normalized_target.include?(normalized_reference) || normalized_reference.include?(normalized_target)
    end
    return score
  rescue
    return -9_999
  end

  def external_system_anchor(data_root, map_ids)
    system_path = runtime_path_join(data_root, "System.rxdata")
    return nil if !runtime_file_exists?(system_path)
    system_data = load_marshaled_runtime(system_path)
    return nil if !system_data || !system_data.respond_to?(:start_map_id)
    return {
      :map_id    => integer(system_data.start_map_id, map_ids.min || 1),
      :x         => integer(system_data.start_x, 0),
      :y         => integer(system_data.start_y, 0),
      :direction => 2
    }
  rescue => e
    log("Unable to read external system data from #{data_root}: #{e.message}")
    return nil
  end

  def parse_script_transfer_anchor(script_text)
    text = script_text.to_s
    return nil if text.empty?
    SCRIPT_TRANSFER_PATTERNS.each do |pattern|
      match = text.match(pattern)
      next if !match
      return {
        :map_id    => integer(match[1], 0),
        :x         => integer(match[2], 0),
        :y         => integer(match[3], 0),
        :direction => integer(match[4], 2)
      }
    end
    map_id = text[/player_new_map_id\s*=\s*(\d+)/i, 1]
    x = text[/player_new_x\s*=\s*(\d+)/i, 1]
    y = text[/player_new_y\s*=\s*(\d+)/i, 1]
    return nil if map_id.nil? || x.nil? || y.nil?
    direction = text[/player_new_direction\s*=\s*(\d+)/i, 1]
    return {
      :map_id    => integer(map_id, 0),
      :x         => integer(x, 0),
      :y         => integer(y, 0),
      :direction => integer(direction, 2)
    }
  end

  def extract_external_script_block(command_list, start_index)
    return "" if !command_list.is_a?(Array)
    index = integer(start_index, 0)
    lines = []
    while index < command_list.length
      command = command_list[index]
      break if !command || ![355, 655].include?(command.code)
      lines << command.parameters[0].to_s
      index += 1
    end
    return lines.join("\n")
  rescue
    return ""
  end

  def direct_transfer_anchor_from_event_command(command)
    return nil if !command || command.code != 201
    params = command.parameters
    return nil if !params.is_a?(Array) || params.length < 5
    return nil if integer(params[0], 0) != 0
    return {
      :map_id    => integer(params[1], 0),
      :x         => integer(params[2], 0),
      :y         => integer(params[3], 0),
      :direction => integer(params[4], 2)
    }
  rescue
    return nil
  end

  def extract_intro_transfer_anchor(data_root, start_anchor, map_infos)
    return nil if !start_anchor || integer(start_anchor[:map_id], 0) <= 0
    visited = {}
    candidates = []
    queue = [[integer(start_anchor[:map_id], 0), 0]]
    reference_name = external_map_info_name(map_infos, start_anchor[:map_id])
    while queue.length > 0
      map_id, depth = queue.shift
      next if visited[map_id] || depth > 4
      visited[map_id] = true
      map_path = runtime_path_join(data_root, format("Map%03d.rxdata", map_id))
      next if !runtime_file_exists?(map_path)
      map_data = load_marshaled_runtime(map_path)
      next if !map_data || !map_data.respond_to?(:events)
      map_data.events.each_value do |event|
        next if !event || !event.respond_to?(:pages)
        event.pages.each do |page|
          next if !page || !page.respond_to?(:list)
          list = page.list
          next if !list.is_a?(Array)
          list.each_with_index do |command, index|
            anchors = []
            direct_anchor = direct_transfer_anchor_from_event_command(command)
            anchors << direct_anchor if direct_anchor
            if command && command.code == 355
              script_anchor = parse_script_transfer_anchor(extract_external_script_block(list, index))
              anchors << script_anchor if script_anchor
            end
            anchors.each do |anchor|
              next if !anchor || integer(anchor[:map_id], 0) <= 0
              queue << [integer(anchor[:map_id], 0), depth + 1] if depth < 4
              if intro_like_external_map?(map_infos, anchor[:map_id])
                next
              end
              score = external_entry_anchor_score(map_infos, anchor, depth, reference_name)
              candidates << [score, anchor]
            end
          end
        end
      end
    end
    candidates.sort_by! { |score, anchor| [-score, integer(anchor[:map_id], 0)] }
    return candidates.first[1] if candidates.length > 0
    return nil
  rescue => e
    log("Unable to analyze intro transfer map #{start_anchor[:map_id]} under #{data_root}: #{e.message}")
    return nil
  end

  def anchors_match?(left, right)
    normalized_left = normalize_anchor(left)
    normalized_right = normalize_anchor(right)
    return false if normalized_left.nil? || normalized_right.nil?
    return normalized_left[:map_id] == normalized_right[:map_id] &&
           normalized_left[:x] == normalized_right[:x] &&
           normalized_left[:y] == normalized_right[:y] &&
           normalized_left[:direction] == normalized_right[:direction]
  rescue
    return false
  end

  def external_anchor_profile(root_path, data_root, override, map_ids)
    profile = {
      :entry_anchor       => nil,
      :story_anchor       => nil,
      :exploration_anchor => nil,
      :system_anchor      => nil
    }
    explicit_story_anchor = normalize_anchor((override || {})["story_anchor"])
    explicit_exploration_anchor = normalize_anchor((override || {})["exploration_anchor"])
    anchor = normalize_anchor(override["entry_anchor"]) if override.is_a?(Hash)
    if explicit_story_anchor || explicit_exploration_anchor || anchor
      profile[:story_anchor] = explicit_story_anchor if explicit_story_anchor
      profile[:entry_anchor] = anchor || explicit_story_anchor || explicit_exploration_anchor
      profile[:exploration_anchor] = explicit_exploration_anchor || profile[:entry_anchor]
      profile[:system_anchor] = explicit_story_anchor || profile[:entry_anchor]
      return profile if profile[:entry_anchor]
    end
    if anchor && anchor[:map_id] > 0
      profile[:entry_anchor] = anchor
      profile[:exploration_anchor] = anchor
      return profile
    end
    explicit_map_id = integer((override || {})["entry_map_id"], 0)
    if explicit_map_id > 0
      explicit_anchor = {
        :map_id    => explicit_map_id,
        :x         => integer((override || {})["entry_x"], 0),
        :y         => integer((override || {})["entry_y"], 0),
        :direction => integer((override || {})["direction"], 2)
      }
      profile[:entry_anchor] = explicit_anchor
      profile[:exploration_anchor] = explicit_anchor
      return profile
    end
    map_infos = nil
    map_infos_path = runtime_path_join(data_root, "MapInfos.rxdata")
    if runtime_file_exists?(map_infos_path)
      begin
        map_infos = load_marshaled_runtime(map_infos_path)
      rescue => e
        log("Unable to read external map infos from #{data_root}: #{e.message}")
      end
    end
    system_anchor = external_system_anchor(data_root, map_ids)
    profile[:system_anchor] = system_anchor
    if system_anchor
      transfer_anchor = extract_intro_transfer_anchor(data_root, system_anchor, map_infos)
      exploration_anchor = system_anchor
      if transfer_anchor && integer(transfer_anchor[:map_id], 0) > 0
        system_score = external_entry_anchor_score(map_infos, system_anchor, 0)
        transfer_score = external_entry_anchor_score(
          map_infos,
          transfer_anchor,
          1,
          external_map_info_name(map_infos, system_anchor[:map_id])
        )
        if intro_like_external_map?(map_infos, system_anchor[:map_id]) || transfer_score > system_score
          exploration_anchor = {
            :map_id    => integer(transfer_anchor[:map_id], system_anchor[:map_id]),
            :x         => integer(transfer_anchor[:x], system_anchor[:x]),
            :y         => integer(transfer_anchor[:y], system_anchor[:y]),
            :direction => integer(transfer_anchor[:direction], system_anchor[:direction])
          }
        end
      end
      profile[:exploration_anchor] = exploration_anchor
      if intro_like_external_map?(map_infos, system_anchor[:map_id]) && !anchors_match?(system_anchor, exploration_anchor)
        profile[:story_anchor] = system_anchor
        profile[:entry_anchor] = system_anchor
      else
        profile[:entry_anchor] = exploration_anchor
      end
      return profile
    end
    fallback_anchor = {
      :map_id    => map_ids.min || 1,
      :x         => 0,
      :y         => 0,
      :direction => 2
    }
    profile[:entry_anchor] = fallback_anchor
    profile[:exploration_anchor] = fallback_anchor
    return profile
  end

  def probe_external_project(root_path)
    root_path = File.expand_path(root_path)
    override = project_override_for_root(root_path)
    link_override = project_link_override_for_root(root_path)
    merged_override = {}
    merged_override.merge!(override) if override.is_a?(Hash)
    merged_override.merge!(link_override) if link_override.is_a?(Hash)
    folder_name = File.basename(root_path)
    project_id = slugify(merged_override["id"] || folder_name)
    filesystem_bridge_root = ensure_linked_project_bridge!(project_id, root_path) || linked_project_bridge_root(project_id)
    title = normalize_string(merged_override["display_name"], project_title_from_ini(root_path) || folder_name)
    data_dir = File.join(root_path, "Data")
    graphics_dir = File.join(root_path, "Graphics")
    audio_dir = File.join(root_path, "Audio")
    prepared_data_root = normalize_path(merged_override["prepared_data_root"], current_game_root)
    prepared_data_root = nil if prepared_data_root && !File.directory?(prepared_data_root)
    prepared_project_root = nil
    prepared_project_root = File.expand_path(File.dirname(prepared_data_root)) if prepared_data_root
    archive_candidates = external_archive_candidates(root_path)
    archive_path = archive_candidates.first
    mounted_data_root = nil
    archive_mount_root = nil
    source_mount_root = nil
    source_data_root = nil
    candidate_data_roots = []
    candidate_data_roots << prepared_data_root if prepared_data_root
    if File.directory?(root_path) && supports_virtual_mounts?
      source_mount_root = mounted_project_root_for_project(project_id, root_path)
      candidate_data_roots << runtime_path_join(source_mount_root, "Data") if source_mount_root
    end
    candidate_data_roots << data_dir if File.directory?(data_dir) && File.file?(File.join(data_dir, "System.rxdata"))
    if archive_path && supports_virtual_mounts?
      mounted_data_root = mounted_data_root_for_project(project_id, archive_path)
      archive_mount_root = project_archive_mount_root(project_id) if mounted_data_root
      candidate_data_roots << mounted_data_root if mounted_data_root
    end
    candidate_data_roots << data_dir if File.directory?(data_dir)
    map_ids = []
    candidate_data_roots.each do |candidate_root|
      next if candidate_root.to_s.empty?
      detected_map_ids = detect_map_ids_from_data_root(candidate_root)
      next if detected_map_ids.empty? && !runtime_file_exists?(runtime_path_join(candidate_root, "System.rxdata"))
      source_data_root = candidate_root
      map_ids = detected_map_ids
      break
    end
    encrypted = !archive_path.nil?
    asset_roots = [root_path, filesystem_bridge_root, source_mount_root, archive_mount_root, prepared_project_root].compact
    graphics_available = asset_roots.any? { |root| File.directory?(File.join(root.to_s, "Graphics")) }
    direct_mountable = !source_data_root.nil? && !map_ids.empty? && graphics_available
    script_sources = source_data_root ? detect_script_sources(root_path, source_data_root) : detect_script_sources(root_path, data_dir)
    config = source_config
    allow_direct_mount = boolean(config["allow_direct_mount_without_link_file"], true)
    auto_link = boolean(config["auto_link_readable_projects"], true)
    explicit_direct_mount = merged_override.has_key?("direct_mount") ? boolean(merged_override["direct_mount"], false) : nil
    enabled_flag = !merged_override.has_key?("enabled") || boolean(merged_override["enabled"], true)
    should_mount = enabled_flag && direct_mountable && (
      explicit_direct_mount == true ||
      (explicit_direct_mount.nil? && auto_link && allow_direct_mount)
    )
    compatibility = if direct_mountable
                      if archive_mount_root
                        should_mount ? "archive_mountable" : "archive_mount_disabled"
                      else
                        should_mount ? "direct_mountable" : "direct_mount_disabled"
                      end
                    elsif encrypted
                      "packaged_install_detected"
                    else
                      "detection_only"
                    end
    status_reason = if direct_mountable
                      if should_mount
                        if prepared_data_root
                          "Prepared extracted data and live assets were found. This install can be linked through the prepared snapshot."
                        else
                          archive_mount_root ? "Archive-backed project data can be mounted through mkxp-z and linked as a read-only exploratory expansion." : "Readable map and graphics data found. This install can be linked as a read-only exploratory expansion."
                        end
                      elsif !enabled_flag
                        "Readable project detected, but this link is disabled in the source config or link override."
                      else
                        if prepared_data_root
                          "Prepared data is available for this install, but direct linking is disabled."
                        else
                          archive_mount_root ? "Archive-backed project detected, but archive mounting is turned off for this install." : "Readable project detected, but direct mounting is turned off for this install."
                        end
                      end
                    elsif encrypted
                      supports_virtual_mounts? ? "A packaged RGSS archive was detected, but the framework could not expose its data through the current runtime mount path." : "A packaged RGSS archive was detected, but this runtime does not expose virtual mounting support."
                    else
                      "Required map or graphics data is missing for direct linking."
                    end
    script_archive_detected = Array(script_sources[:script_archives]).length > 0
    plugin_sources_detected = Array(script_sources[:plugin_directories]).length > 0 || Array(script_sources[:plugin_script_archives]).length > 0
    source_tree_detected = !script_sources[:script_directory].to_s.empty?
    extracted_install_detected = !source_data_root.to_s.empty? && absolute_path?(source_data_root)
    return {
      :id               => project_id,
      :root             => root_path,
      :filesystem_bridge_root => filesystem_bridge_root,
      :source_mount_root => source_mount_root,
      :display_name     => title,
      :author           => normalize_string(merged_override["author"], ""),
      :version          => normalize_string(merged_override["version"], "linked-install"),
      :has_data         => File.directory?(data_dir),
      :has_graphics     => graphics_available,
      :has_audio        => File.directory?(audio_dir),
      :encrypted        => encrypted,
      :archive_path     => archive_path,
      :archive_mount_root => archive_mount_root,
      :prepared_data_root => prepared_data_root,
      :prepared_project_root => prepared_project_root,
      :data_root        => source_data_root,
      :map_count        => map_ids.length,
      :readable_map_count => map_ids.length,
      :map_ids          => map_ids,
      :map_files        => map_ids.map { |id| runtime_path_join(source_data_root, format("Map%03d.rxdata", id)) },
      :anchor_profile   => external_anchor_profile(root_path, source_data_root || data_dir, merged_override, map_ids),
      :direct_mountable => direct_mountable,
      :archive_mountable => !archive_mount_root.nil? && direct_mountable,
      :source_tree_mountable => archive_mount_root.nil? && direct_mountable,
      :prepared_snapshot_available => !prepared_data_root.to_s.empty?,
      :archive_detected => encrypted,
      :script_archive_detected => script_archive_detected,
      :plugin_sources_detected => plugin_sources_detected,
      :source_tree_detected => source_tree_detected,
      :extracted_install_detected => extracted_install_detected,
      :should_mount     => should_mount,
      :compatibility    => compatibility,
      :install_layout   => prepared_data_root ? "prepared_snapshot" : (archive_mount_root ? "archive_mount" : (source_mount_root ? "mounted_filesystem" : (extracted_install_detected ? "filesystem" : "detection_only"))),
      :status_reason    => normalize_string(merged_override["status_reason"], status_reason),
      :position_mode    => normalize_string(merged_override["position_mode"], "fixed"),
      :mode_options     => (merged_override["mode_options"].is_a?(Array) ? merged_override["mode_options"] : ["shared"]).map { |mode| normalize_string(mode, "shared") }.uniq,
      :script_sources   => script_sources,
      :override         => merged_override
    }
  end

  def build_external_manifest(project_info)
    # Fixed external blocks are aligned on 1,000-map boundaries. A +buffer here
    # makes high local IDs such as Map999 spill into the next project's block.
    block_size = [project_info[:map_ids].max.to_i + 1, RESERVED_MAP_BLOCK_SIZE].max
    requested_start = integer(project_info[:override]["map_block_start"], 0)
    fixed_start = fixed_external_map_block_start(project_info[:id]) if respond_to?(:fixed_external_map_block_start)
    fixed_start = integer(fixed_start, 0)
    block_start = if requested_start > 0
                    requested_start
                  elsif fixed_start > 0
                    fixed_start
                  else
                    next_map_block_start(block_size)
                  end
    manifest = {
      :id               => project_info[:id],
      :namespace        => slugify(project_info[:display_name]),
      :mod_id           => nil,
      :name             => project_info[:display_name],
      :author           => project_info[:author],
      :version          => project_info[:version],
      :description      => ["Linked external gameworld for #{project_info[:display_name]}."],
      :permissions      => { "source_type" => "linked_external_install", "root" => project_info[:root] },
      :manifest_enabled => project_info[:should_mount],
      :enabled          => false,
      :map_block        => {
        :start => block_start,
        :size  => block_size
      },
      :map_source       => {
        :loader        => (project_info[:archive_mount_root] || project_info[:source_mount_root]) ? "runtime_load_data" : "marshal_file",
        :path_template => runtime_path_join(project_info[:data_root], "Map%03d.rxdata")
      },
      :map_files        => [],
      :travel_nodes     => [],
      :badge_pages      => [
        {
          :id         => "#{project_info[:id]}_badges",
          :name       => "#{project_info[:display_name]} Badges",
          :slot_count => 8
        }
      ],
      :dex_pages        => [
        {
          :id      => "#{project_info[:id]}_dex",
          :name    => "#{project_info[:display_name]} Dex",
          :species => []
        }
      ],
      :quest_defs       => [],
      :variant_rules    => [],
      :transfer_rules   => [],
      :asset_roots      => [project_info[:root], project_info[:prepared_project_root], project_info[:source_mount_root], project_info[:archive_mount_root], project_info[:filesystem_bridge_root]].compact,
      :migrations       => [],
      :source_type      => "external_project",
      :source_root      => project_info[:root],
      :script_catalog   => project_info[:script_sources]
    }
    anchor_profile = project_info[:anchor_profile].is_a?(Hash) ? project_info[:anchor_profile] : {}
    entry_anchor = normalize_anchor(anchor_profile[:entry_anchor]) || normalize_anchor(anchor_profile["entry_anchor"])
    entry_anchor ||= {
      :map_id    => 1,
      :x         => 0,
      :y         => 0,
      :direction => 2
    }
    exploration_anchor = normalize_anchor(anchor_profile[:exploration_anchor]) || normalize_anchor(anchor_profile["exploration_anchor"])
    resume_anchor = nil
    if exploration_anchor && !anchors_match?(exploration_anchor, entry_anchor)
      resume_anchor = {
        :map_id    => block_start + integer(exploration_anchor[:map_id], 1),
        :x         => integer(exploration_anchor[:x], 0),
        :y         => integer(exploration_anchor[:y], 0),
        :direction => integer(exploration_anchor[:direction], 2)
      }
    end
    entry_virtual_id = block_start + integer(entry_anchor[:map_id], 1)
    manifest[:travel_nodes] << {
      :id              => "#{manifest[:id]}:entry",
      :expansion_id    => manifest[:id],
      :name            => project_info[:display_name],
      :description     => (anchor_profile[:story_anchor] ? "Start the normal opening flow for #{project_info[:display_name]}." : "Travel to #{project_info[:display_name]}."),
      :entry_map_id    => entry_virtual_id,
      :x               => integer(entry_anchor[:x], 0),
      :y               => integer(entry_anchor[:y], 0),
      :direction       => integer(entry_anchor[:direction], 2),
      :position_mode   => "last_expansion_anchor",
      :mode_options    => project_info[:mode_options],
      :bedroom_pc_only => true,
      :sort_order      => 1000 + external_projects.length,
      :return_anchor   => resume_anchor
    }
    show_exploration_node = boolean((project_info[:override] || {})["show_exploration_node"], false)
    if show_exploration_node && exploration_anchor && !anchors_match?(exploration_anchor, entry_anchor)
      manifest[:travel_nodes] << {
        :id              => "#{manifest[:id]}:exploration",
        :expansion_id    => manifest[:id],
        :name            => "#{project_info[:display_name]} (Exploration)",
        :description     => "Enter a safer exploration point in #{project_info[:display_name]}.",
        :entry_map_id    => block_start + integer(exploration_anchor[:map_id], 1),
        :x               => integer(exploration_anchor[:x], 0),
        :y               => integer(exploration_anchor[:y], 0),
        :direction       => integer(exploration_anchor[:direction], 2),
        :position_mode   => project_info[:position_mode],
        :mode_options    => project_info[:mode_options],
        :bedroom_pc_only => true,
        :sort_order      => 1001 + external_projects.length,
        :return_anchor   => nil
      }
    end
    return manifest
  end

  def scan_external_projects!
    external_project_dirs_from_roots.each do |root_path|
      next if root_path == current_game_root
      info = probe_external_project(root_path)
      next if !info
      external_projects[info[:id]] = info
      next if !info[:should_mount]
      register_manifest(build_external_manifest(info))
    end
  end

  def normalize_manifest(raw_manifest, mod_info)
    expansion_id = normalize_string(raw_manifest["id"], mod_info.id)
    namespace    = normalize_string(raw_manifest["namespace"], expansion_id)
    manifest_enabled = raw_manifest["enabled"] != false
    requested_block = raw_manifest["map_block"].is_a?(Hash) ? raw_manifest["map_block"] : {}
    block_size  = integer(requested_block["size"], RESERVED_MAP_BLOCK_SIZE)
    block_start = integer(requested_block["start"], 0)
    block_start = next_map_block_start(block_size) if block_start <= 0
    manifest = {
      :id             => expansion_id,
      :namespace      => namespace,
      :mod_id         => mod_info.id,
      :name           => normalize_string(raw_manifest["name"], expansion_id.split("_").map(&:capitalize).join(" ")),
      :author         => normalize_string(raw_manifest["author"], mod_info.author),
      :version        => normalize_string(raw_manifest["version"], mod_info.version),
      :description    => raw_manifest["description"],
      :permissions    => raw_manifest["permissions"],
      :manifest_enabled => manifest_enabled,
      :enabled        => false,
      :map_block      => {
        :start => block_start,
        :size  => block_size
      },
      :map_files      => [],
      :travel_nodes   => [],
      :badge_pages    => [],
      :dex_pages      => [],
      :quest_defs     => [],
      :variant_rules  => [],
      :transfer_rules => [],
      :asset_roots    => [],
      :map_source     => nil,
      :migrations     => []
    }
    normalize_asset_roots!(manifest, raw_manifest, mod_info)
    normalize_map_files!(manifest, raw_manifest, mod_info)
    normalize_travel_nodes!(manifest, raw_manifest)
    normalize_badges!(manifest, raw_manifest)
    normalize_dex_pages!(manifest, raw_manifest)
    normalize_quests!(manifest, raw_manifest)
    normalize_variants!(manifest, raw_manifest)
    normalize_migrations!(manifest, raw_manifest)
    return manifest
  rescue => e
    log("Failed to normalize manifest for #{mod_info.id}: #{e.message}")
    return nil
  end

  def normalize_asset_roots!(manifest, raw_manifest, mod_info)
    roots = []
    roots.concat(raw_manifest["asset_roots"]) if raw_manifest["asset_roots"].is_a?(Array)
    if raw_manifest["assets"].is_a?(Hash) && raw_manifest["assets"]["roots"].is_a?(Array)
      roots.concat(raw_manifest["assets"]["roots"])
    end
    manifest[:asset_roots] = roots.map { |root| File.expand_path(File.join(mod_info.folder_path, root.to_s)) }
    manifest[:asset_roots].uniq!
  end

  def normalize_map_files!(manifest, raw_manifest, mod_info)
    raw_maps = raw_manifest["maps"].is_a?(Hash) ? raw_manifest["maps"] : {}
    files = raw_maps["files"].is_a?(Array) ? raw_maps["files"] : []
    files.each_with_index do |raw_entry, index|
      next if !raw_entry.is_a?(Hash)
      local_id = integer(raw_entry["local_id"], index + 1)
      virtual_id = integer(raw_entry["virtual_id"], manifest[:map_block][:start] + local_id)
      path = File.expand_path(File.join(mod_info.folder_path, raw_entry["path"].to_s))
      manifest[:map_files] << {
        :id           => normalize_string(raw_entry["id"], "map_#{local_id}"),
        :expansion_id => manifest[:id],
        :local_id     => local_id,
        :virtual_id   => virtual_id,
        :path         => path,
        :name         => normalize_string(raw_entry["name"], "#{manifest[:name]} Map #{local_id}"),
        :mod_id       => mod_info.id,
        :loader       => "marshal_file"
      }
    end
  end

  def normalize_travel_nodes!(manifest, raw_manifest)
    nodes = []
    if raw_manifest["travel_nodes"].is_a?(Array)
      nodes = raw_manifest["travel_nodes"]
    elsif raw_manifest["travel"].is_a?(Hash) && raw_manifest["travel"]["nodes"].is_a?(Array)
      nodes = raw_manifest["travel"]["nodes"]
    end
    nodes.each_with_index do |raw_node, index|
      next if !raw_node.is_a?(Hash)
      node_map_id = resolve_manifest_map_id(manifest, raw_node["map_id"], raw_node["local_map_id"])
      next if node_map_id <= 0
      mode_options = raw_node["mode_options"].is_a?(Array) ? raw_node["mode_options"] : ["shared"]
      manifest[:travel_nodes] << {
        :id             => "#{manifest[:id]}:#{normalize_string(raw_node["id"], "entry_#{index + 1}")}",
        :expansion_id   => manifest[:id],
        :name           => normalize_string(raw_node["name"], manifest[:name]),
        :description    => normalize_string(raw_node["description"], "Travel to #{manifest[:name]}."),
        :entry_map_id   => node_map_id,
        :x              => integer(raw_node["x"], 0),
        :y              => integer(raw_node["y"], 0),
        :direction      => integer(raw_node["direction"], 2),
        :position_mode  => normalize_string(raw_node["position_mode"], "fixed"),
        :mode_options   => mode_options.map { |mode| normalize_string(mode, "shared") }.uniq,
        :bedroom_pc_only => raw_node["bedroom_pc_only"] != false,
        :sort_order     => integer(raw_node["sort_order"], index),
        :return_anchor  => normalize_anchor(raw_node["return_anchor"])
      }
    end
  end

  def normalize_badges!(manifest, raw_manifest)
    badge_root = raw_manifest["badges"].is_a?(Hash) ? raw_manifest["badges"] : {}
    badge_pages = badge_root["pages"].is_a?(Array) ? badge_root["pages"] : []
    badge_pages = [{ "id" => "#{manifest[:id]}_badges", "name" => "#{manifest[:name]} Badges", "slot_count" => 8 }] if badge_pages.empty?
    badge_pages.each_with_index do |raw_page, index|
      next if !raw_page.is_a?(Hash)
      manifest[:badge_pages] << {
        :id         => normalize_string(raw_page["id"], "#{manifest[:id]}_badges_#{index + 1}"),
        :name       => normalize_string(raw_page["name"], "#{manifest[:name]} Badges"),
        :slot_count => integer(raw_page["slot_count"] || raw_page["count"], 8)
      }
    end
  end

  def normalize_dex_pages!(manifest, raw_manifest)
    dex_root = raw_manifest["dex"].is_a?(Hash) ? raw_manifest["dex"] : {}
    dex_pages = dex_root["pages"].is_a?(Array) ? dex_root["pages"] : []
    dex_pages.each_with_index do |raw_page, index|
      next if !raw_page.is_a?(Hash)
      manifest[:dex_pages] << {
        :id      => normalize_string(raw_page["id"], "#{manifest[:id]}_dex_#{index + 1}"),
        :name    => normalize_string(raw_page["name"], "#{manifest[:name]} Dex"),
        :species => raw_page["species"].is_a?(Array) ? raw_page["species"].map { |species| species.to_s } : []
      }
    end
  end

  def normalize_quests!(manifest, raw_manifest)
    quest_root = raw_manifest["quests"].is_a?(Hash) ? raw_manifest["quests"] : {}
    defs = quest_root["definitions"].is_a?(Array) ? quest_root["definitions"] : []
    defs.each do |raw_quest|
      next if !raw_quest.is_a?(Hash)
      manifest[:quest_defs] << {
        :id           => "#{manifest[:namespace]}:#{normalize_string(raw_quest["id"], "quest")}",
        :expansion_id => manifest[:id],
        :name         => normalize_string(raw_quest["name"], "Quest"),
        :description  => normalize_string(raw_quest["description"], "")
      }
    end
  end

  def normalize_variants!(manifest, raw_manifest)
    variant_root = raw_manifest["variants"].is_a?(Hash) ? raw_manifest["variants"] : {}
    aliases = variant_root["aliases"].is_a?(Array) ? variant_root["aliases"] : []
    aliases.each do |raw_alias|
      next if !raw_alias.is_a?(Hash)
      manifest[:variant_rules] << {
        :id             => "#{manifest[:namespace]}:#{normalize_string(raw_alias["id"], "variant")}",
        :expansion_id   => manifest[:id],
        :host_species   => normalize_string(raw_alias["host_species"], ""),
        :expansion_form => normalize_string(raw_alias["expansion_form"], ""),
        :mapped_species => normalize_string(raw_alias["mapped_species"], "")
      }
    end
    transfer_rules = variant_root["transfer_rules"].is_a?(Array) ? variant_root["transfer_rules"] : []
    transfer_rules.each do |raw_rule|
      next if !raw_rule.is_a?(Hash)
      manifest[:transfer_rules] << raw_rule
    end
  end

  def normalize_migrations!(manifest, raw_manifest)
    raw_migrations = raw_manifest["migrations"].is_a?(Array) ? raw_manifest["migrations"] : []
    raw_migrations.each do |raw_migration|
      next if !raw_migration.is_a?(Hash)
      manifest[:migrations] << {
        :expansion_id => manifest[:id],
        :from         => normalize_string(raw_migration["from"], ""),
        :to           => normalize_string(raw_migration["to"], manifest[:version]),
        :note         => normalize_string(raw_migration["note"], "")
      }
    end
  end

  def resolve_manifest_map_id(manifest, raw_map_id, raw_local_id)
    map_id = integer(raw_map_id, 0)
    return map_id if map_id > 0
    local_id = integer(raw_local_id, 0)
    return 0 if local_id <= 0
    return manifest[:map_block][:start] + local_id
  end

  def register_manifest(manifest)
    expansion_id = manifest[:id]
    reserve_map_block!(manifest[:map_block][:start], manifest[:map_block][:size])
    registry(:expansions)[expansion_id] = manifest
    manifest[:map_files].each do |map_entry|
      registry(:maps)[map_entry[:virtual_id]] = map_entry
    end
    registry(:badges)[expansion_id] = manifest[:badge_pages]
    registry(:dex_data)[expansion_id] = manifest[:dex_pages]
    registry(:quests)[expansion_id] = manifest[:quest_defs]
    registry(:variants)[expansion_id] = {
      :aliases        => manifest[:variant_rules],
      :transfer_rules => manifest[:transfer_rules]
    }
    registry(:travel_nodes)[expansion_id] = manifest[:travel_nodes]
    registry(:assets)[expansion_id] = manifest[:asset_roots]
    registry(:migrations)[expansion_id] = manifest[:migrations]
    registry(:script_catalogs)[expansion_id] = manifest[:script_catalog] if manifest[:script_catalog]
  end

  def refresh_runtime_flags!
    registry(:expansions).each_value do |manifest|
      manifest[:enabled] = (manifest[:manifest_enabled] == true && mod_enabled?(manifest[:mod_id]))
      state = state_for(manifest[:id])
      state.enabled   = manifest[:enabled]
      state.installed = true
      state.version ||= manifest[:version]
      state.shared_world = true if state.shared_world.nil?
      state.isolated_mode = false if state.isolated_mode.nil?
      manifest[:badge_pages].each do |page|
        state.badges[page[:id]] ||= Array.new(integer(page[:slot_count], 8), false)
      end
    end
    ensure_save_root.enabled_signature ||= current_enabled_signature
  end

  def run_pending_migrations!
    active_expansion_ids.each do |expansion_id|
      manifest = manifest_for(expansion_id)
      next if !manifest
      state = state_for(expansion_id)
      next if state.version.to_s == manifest[:version].to_s
      record = {
        "expansion_id" => expansion_id,
        "from"         => state.version.to_s,
        "to"           => manifest[:version].to_s,
        "note"         => manifest[:migrations].map { |migration| migration[:note] }.reject(&:empty?).join("; "),
        "timestamp"    => timestamp_string
      }
      ensure_save_root.migration_history << record
      log("Migration recorded for #{expansion_id}: #{state.version} -> #{manifest[:version]}")
      state.version = manifest[:version]
    end
  end
end
