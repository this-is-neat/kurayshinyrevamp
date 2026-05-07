module TravelExpansionFramework
  SCRIPT_SOURCE_REPORT_SCHEMA_VERSION = 1 if !const_defined?(:SCRIPT_SOURCE_REPORT_SCHEMA_VERSION)
  SCRIPT_SAMPLE_LIMIT = 20 if !const_defined?(:SCRIPT_SAMPLE_LIMIT)

  module_function

  def build_external_script_source_catalog
    projects = {}
    external_projects.keys.sort.each do |project_id|
      info = external_projects[project_id]
      next if !info.is_a?(Hash)
      projects[project_id.to_s] = build_project_script_source_entry(project_id, info)
    end
    return {
      "generated_at"         => timestamp_string,
      "schema_version"       => SCRIPT_SOURCE_REPORT_SCHEMA_VERSION,
      "search_roots"         => Array(source_config["search_roots"]).map { |entry| normalize_path(entry, current_game_root) }.compact.uniq,
      "project_count"        => projects.length,
      "projects"             => projects,
      "totals"               => build_script_source_totals(projects)
    }
  end

  def build_external_script_source_summary(catalog = nil)
    catalog ||= build_external_script_source_catalog
    projects = {}
    (catalog["projects"] || {}).keys.sort.each do |project_id|
      entry = catalog["projects"][project_id]
      projects[project_id] = {
        "display_name"              => entry["display_name"],
        "root"                      => entry["root"],
        "recommended_ingest_kinds"  => Array(entry["recommended_ingest_order"]).map { |source| source["kind"] },
        "has_extracted_scripts"     => !!entry["extracted_scripts_tree"]["exists"],
        "script_archive_count"      => Array(entry["script_archives"]).length,
        "plugin_archive_count"      => Array(entry["plugin_archives"]).length,
        "plugin_folder_count"       => integer(entry["plugins_folder"]["plugin_count"], 0),
        "nonstandard_candidate_count" => Array(entry["nonstandard_script_candidates"]).length,
        "warnings"                  => Array(entry["detection_notes"])
      }
    end
    return {
      "generated_at"   => catalog["generated_at"],
      "schema_version" => catalog["schema_version"],
      "project_count"  => projects.length,
      "projects"       => projects,
      "totals"         => catalog["totals"] || {}
    }
  end

  def write_external_script_source_reports
    catalog = build_external_script_source_catalog
    write_json_report("external_script_source_catalog.json", catalog)
    write_json_report("external_script_source_summary.json", build_external_script_source_summary(catalog))
    return catalog
  rescue => e
    log("Script source report generation failed: #{e.message}")
    return nil
  end

  def build_project_script_source_entry(project_id, info)
    root_path = normalize_path(info[:root], current_game_root)
    runtime_sources = info[:script_sources].is_a?(Hash) ? info[:script_sources] : {}
    if !root_path || root_path.to_s.empty?
      return {
        "display_name"                  => info[:display_name],
        "root"                          => nil,
        "linked"                        => info[:should_mount] == true,
        "compatibility"                 => info[:compatibility],
        "direct_mountable"              => info[:direct_mountable] == true,
        "encrypted"                     => info[:encrypted] == true,
        "game_ini"                      => { "path" => nil, "exists" => false },
        "mkxp_hints"                    => { "path" => nil, "exists" => false },
        "extracted_scripts_tree"        => { "path" => nil, "exists" => false, "script_file_count" => 0, "directory_count" => 0, "sample_files" => [], "top_level_entries" => [] },
        "script_archives"               => [],
        "plugin_archives"               => [],
        "plugins_folder"                => { "path" => nil, "exists" => false, "plugin_count" => 0, "plugins" => [] },
        "nonstandard_script_candidates" => [],
        "recommended_ingest_order"      => [],
        "detection_notes"               => ["No readable project root was available for script-source detection."]
      }
    end
    game_ini = read_project_game_ini(root_path)
    mkxp = read_mkxp_loader_hints(root_path)
    scripts_tree = detect_extracted_scripts_tree(root_path)
    if !scripts_tree["exists"] && runtime_sources[:script_directory]
      scripts_tree = {
        "path"              => runtime_sources[:script_directory],
        "exists"            => runtime_directory_exists?(runtime_sources[:script_directory]),
        "script_file_count" => integer(runtime_sources[:script_directory_count], 0),
        "directory_count"   => 0,
        "sample_files"      => [],
        "top_level_entries" => []
      }
    end
    script_archives = detect_script_archives(root_path, game_ini)
    if script_archives.empty? && runtime_sources[:script_archives].is_a?(Array)
      script_archives = runtime_sources[:script_archives].map do |entry|
        build_script_archive_entry(entry[:path] || entry["path"], game_ini["scripts_path_hint"], "scripts_archive")
      end
    end
    plugin_archives = detect_plugin_archives(root_path)
    if plugin_archives.empty? && runtime_sources[:plugin_script_archives].is_a?(Array)
      plugin_archives = runtime_sources[:plugin_script_archives].map do |entry|
        build_script_archive_entry(entry[:path] || entry["path"], nil, "plugin_archive")
      end
    end
    plugins_folder = detect_plugins_folder(root_path)
    if !plugins_folder["exists"] && runtime_sources[:plugin_directories].is_a?(Array) && runtime_sources[:plugin_directories].length > 0
      plugins_folder = {
        "path"         => (runtime_sources[:plugin_directories][0][:path] rescue runtime_sources[:plugin_directories][0]) || runtime_sources[:plugin_directories][0],
        "exists"       => true,
        "plugin_count" => integer(runtime_sources[:plugin_meta_count], 0),
        "plugins"      => []
      }
    end
    nonstandard_candidates = detect_nonstandard_script_candidates(root_path)
    notes = []
    if scripts_tree["exists"] && !script_archives.any? { |entry| entry["configured_in_game_ini"] }
      notes << "A readable Data/Scripts tree is present without a matching Game.ini Scripts target."
    end
    if !scripts_tree["exists"] && script_archives.empty?
      notes << "No extracted script tree or RGSS script archive was found under Data."
    end
    if plugins_folder["exists"] && plugin_archives.empty?
      notes << "A Plugins folder exists without a compiled PluginScripts archive."
    end
    if !plugins_folder["exists"] && !plugin_archives.empty?
      notes << "A PluginScripts archive exists without a readable Plugins folder."
    end
    if info[:encrypted] && script_archives.empty? && plugin_archives.empty?
      notes << "The install also advertises encrypted content; this detector could not identify readable script sources inside the packaged RGSS archives."
    end
    return {
      "display_name"               => info[:display_name],
      "root"                       => root_path,
      "linked"                     => info[:should_mount] == true,
      "compatibility"              => info[:compatibility],
      "direct_mountable"           => info[:direct_mountable] == true,
      "encrypted"                  => info[:encrypted] == true,
      "game_ini"                   => game_ini,
      "mkxp_hints"                 => mkxp,
      "extracted_scripts_tree"     => scripts_tree,
      "script_archives"            => script_archives,
      "plugin_archives"            => plugin_archives,
      "plugins_folder"             => plugins_folder,
      "nonstandard_script_candidates" => nonstandard_candidates,
      "recommended_ingest_order"   => recommend_ingest_order(scripts_tree, script_archives, plugin_archives, plugins_folder),
      "detection_notes"            => notes
    }
  end

  def build_script_source_totals(projects)
    totals = {
      "projects_with_extracted_scripts" => 0,
      "projects_with_script_archives"   => 0,
      "projects_with_plugin_archives"   => 0,
      "projects_with_plugins_folders"   => 0,
      "projects_with_nonstandard_candidates" => 0
    }
    projects.each_value do |entry|
      totals["projects_with_extracted_scripts"] += 1 if entry["extracted_scripts_tree"]["exists"]
      totals["projects_with_script_archives"] += 1 if Array(entry["script_archives"]).length > 0
      totals["projects_with_plugin_archives"] += 1 if Array(entry["plugin_archives"]).length > 0
      totals["projects_with_plugins_folders"] += 1 if entry["plugins_folder"]["exists"]
      totals["projects_with_nonstandard_candidates"] += 1 if Array(entry["nonstandard_script_candidates"]).length > 0
    end
    return totals
  end

  def read_project_game_ini(root_path)
    return {
      "path"              => nil,
      "exists"            => false,
      "title"             => nil,
      "scripts_entry"     => nil,
      "scripts_path_hint" => nil
    } if !root_path || root_path.to_s.empty?
    ini_path = File.join(root_path, "Game.ini")
    ini_path = Dir[File.join(root_path, "*.ini")].sort.first if !File.file?(ini_path)
    result = {
      "path"              => ini_path,
      "exists"            => !!ini_path && File.file?(ini_path),
      "title"             => nil,
      "scripts_entry"     => nil,
      "scripts_path_hint" => nil
    }
    return result if !result["exists"]
    read_text_lines_binary_safe(ini_path).each do |line|
      next if line !~ /\A([^=]+?)\s*=\s*(.*)\z/
      key = $1.to_s.strip.downcase
      value = $2.to_s.strip
      case key
      when "title"
        result["title"] = value
      when "scripts"
        result["scripts_entry"] = value
        normalized = value.gsub("\\", "/").sub(%r{\A\./}, "")
        result["scripts_path_hint"] = File.expand_path(File.join(root_path, normalized))
      end
    end
    return result
  rescue => e
    log("Game.ini scan failed for #{root_path}: #{e.message}")
    result["error"] = e.message
    return result
  end

  def read_mkxp_loader_hints(root_path)
    return {
      "path"                    => nil,
      "exists"                  => false,
      "preload_script_declared" => false,
      "custom_script_declared"  => false,
      "patches_declared"        => false
    } if !root_path || root_path.to_s.empty?
    path = File.join(root_path, "mkxp.json")
    return {
      "path"                    => path,
      "exists"                  => false,
      "preload_script_declared" => false,
      "custom_script_declared"  => false,
      "patches_declared"        => false
    } if !File.file?(path)
    raw = read_text_binary_safe(path)
    return {
      "path"                    => path,
      "exists"                  => true,
      "preload_script_declared" => raw.include?("\"preloadScript\""),
      "custom_script_declared"  => raw.include?("\"customScript\""),
      "patches_declared"        => raw.include?("\"patches\"")
    }
  rescue => e
    log("mkxp.json scan failed for #{root_path}: #{e.message}")
    return {
      "path"   => path,
      "exists" => true,
      "error"  => e.message
    }
  end

  def detect_extracted_scripts_tree(root_path)
    path = File.join(root_path, "Data", "Scripts")
    result = {
      "path"                => path,
      "exists"              => File.directory?(path),
      "script_file_count"   => 0,
      "directory_count"     => 0,
      "sample_files"        => [],
      "top_level_entries"   => []
    }
    return result if !result["exists"]
    script_files = Dir[File.join(path, "**", "*.rb")].sort
    directories = Dir[File.join(path, "**", "*")].find_all { |entry| File.directory?(entry) }.sort
    result["script_file_count"] = script_files.length
    result["directory_count"] = directories.length
    result["sample_files"] = relative_paths(script_files, path)
    result["top_level_entries"] = Dir[File.join(path, "*")].sort.map { |entry| File.basename(entry) }[0, SCRIPT_SAMPLE_LIMIT]
    return result
  rescue => e
    log("Extracted script tree scan failed for #{root_path}: #{e.message}")
    result["error"] = e.message
    return result
  end

  def detect_script_archives(root_path, game_ini)
    data_dir = File.join(root_path, "Data")
    expected_path = game_ini["scripts_path_hint"]
    archives = []
    archives.concat(Dir[File.join(data_dir, "Scripts*.rxdata")].sort)
    archives.concat(Dir[File.join(data_dir, "Scripts*.rvdata2")].sort)
    archives.concat(Dir[File.join(data_dir, "Scripts*.rvdata")].sort)
    archives.uniq!
    return archives.map { |path| build_script_archive_entry(path, expected_path, "scripts_archive") }
  end

  def detect_plugin_archives(root_path)
    data_dir = File.join(root_path, "Data")
    archives = []
    archives.concat(Dir[File.join(data_dir, "PluginScripts*.rxdata")].sort)
    archives.concat(Dir[File.join(data_dir, "PluginScripts*.rvdata2")].sort)
    archives.concat(Dir[File.join(data_dir, "PluginScripts*.rvdata")].sort)
    archives.uniq!
    return archives.map { |path| build_script_archive_entry(path, nil, "plugin_archive") }
  end

  def detect_nonstandard_script_candidates(root_path)
    data_dir = File.join(root_path, "Data")
    return [] if !File.directory?(data_dir)
    candidates = Dir[File.join(data_dir, "Scripts*")].sort
    candidates.concat(Dir[File.join(data_dir, "PluginScripts*")].sort)
    candidates.uniq!
    results = []
    candidates.each do |path|
      next if File.directory?(path)
      downcase = path.downcase
      next if downcase.end_with?(".rxdata") || downcase.end_with?(".rvdata2")
      results << build_basic_file_entry(path, data_dir).merge({
        "kind"  => "nonstandard_script_candidate",
        "label" => File.basename(path)
      })
    end
    return results
  end

  def build_script_archive_entry(path, expected_path, kind)
    entry = build_basic_file_entry(path, File.dirname(path))
    entry["kind"] = kind
    entry["configured_in_game_ini"] = expected_path ? File.expand_path(path) == File.expand_path(expected_path) : false
    entry["exact_primary_name"] = ["Scripts.rxdata", "Scripts.rvdata2", "PluginScripts.rxdata", "PluginScripts.rvdata2"].include?(File.basename(path))
    entry["archive_family"] = File.extname(path).downcase == ".rvdata2" ? "rgss3" : "rgss1_or_2"
    return entry
  end

  def detect_plugins_folder(root_path)
    candidates = [File.join(root_path, "Plugins"), File.join(root_path, "Plugin")]
    path = candidates.find { |candidate| File.directory?(candidate) } || candidates[0]
    result = {
      "path"         => path,
      "exists"       => File.directory?(path),
      "plugin_count" => 0,
      "plugins"      => []
    }
    return result if !result["exists"]
    plugin_dirs = Dir[File.join(path, "*")].find_all { |entry| File.directory?(entry) }.sort
    result["plugin_count"] = plugin_dirs.length
    result["plugins"] = plugin_dirs.map { |dir| detect_plugin_dir(dir) }
    return result
  rescue => e
    log("Plugins folder scan failed for #{root_path}: #{e.message}")
    result["error"] = e.message
    return result
  end

  def detect_plugin_dir(path)
    meta_path = File.join(path, "meta.txt")
    script_files = Dir[File.join(path, "**", "*.rb")].sort
    return {
      "folder"                 => File.basename(path),
      "path"                   => path,
      "has_meta"               => File.file?(meta_path),
      "meta_path"              => File.file?(meta_path) ? meta_path : nil,
      "meta"                   => File.file?(meta_path) ? parse_plugin_meta(meta_path) : {},
      "script_file_count"      => script_files.length,
      "sample_script_files"    => relative_paths(script_files, path)
    }
  end

  def parse_plugin_meta(path)
    meta = {}
    read_text_lines_binary_safe(path).each do |line|
      stripped = line.to_s.strip
      next if stripped.empty? || stripped.start_with?("#", ";")
      next if stripped !~ /\A(\w+)\s*=\s*(.*)\z/
      property = $1.to_s.upcase
      values = $2.to_s.split(",").map { |value| value.to_s.strip }
      case property
      when "REQUIRES", "EXACT", "OPTIONAL"
        meta["dependencies"] ||= []
        meta["dependencies"] << {
          "type"   => property.downcase,
          "values" => values
        }
      when "CONFLICTS"
        meta["conflicts"] = values
      when "SCRIPTS"
        meta["declared_scripts"] = values
      when "CREDITS"
        meta["credits"] = values
      when "LINK", "WEBSITE"
        meta["link"] = values[0]
      else
        meta[property.downcase] = values.length <= 1 ? values[0] : values
      end
    end
    return meta
  rescue => e
    return { "parse_error" => e.message }
  end

  def recommend_ingest_order(scripts_tree, script_archives, plugin_archives, plugins_folder)
    sources = []
    if plugins_folder["exists"] && integer(plugins_folder["plugin_count"], 0) > 0
      sources << {
        "kind"   => "plugins_folder",
        "path"   => plugins_folder["path"],
        "reason" => "Readable plugin folders and meta.txt files are the safest source of plugin-side intent."
      }
    end
    if scripts_tree["exists"] && integer(scripts_tree["script_file_count"], 0) > 0
      sources << {
        "kind"   => "extracted_scripts_tree",
        "path"   => scripts_tree["path"],
        "reason" => "Plain-text Data/Scripts files can be cataloged without archive decoding."
      }
    end
    configured_archive = script_archives.find { |entry| entry["configured_in_game_ini"] }
    if configured_archive
      sources << {
        "kind"   => configured_archive["kind"],
        "path"   => configured_archive["path"],
        "reason" => "Game.ini points at this archive as the main RGSS script container."
      }
    end
    script_archives.each do |entry|
      next if configured_archive && entry["path"] == configured_archive["path"]
      sources << {
        "kind"   => entry["kind"],
        "path"   => entry["path"],
        "reason" => "Alternate RGSS archive candidate found under Data."
      }
    end
    plugin_archives.each do |entry|
      sources << {
        "kind"   => entry["kind"],
        "path"   => entry["path"],
        "reason" => "Compiled plugin archive is present, but should be treated as opaque input."
      }
    end
    return sources
  end

  def read_text_binary_safe(path)
    raw = File.open(path, "rb") { |file| file.read }
    text = raw.to_s
    text.force_encoding("UTF-8") if text.respond_to?(:force_encoding)
    return text.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "")
  rescue
    return ""
  end

  def read_text_lines_binary_safe(path)
    text = read_text_binary_safe(path)
    return [] if text.empty?
    return text.split(/\r?\n/)
  rescue
    return []
  end

  def build_basic_file_entry(path, relative_base = nil)
    absolute = absolute_path?(path)
    return {
      "path"          => path,
      "relative_path" => relative_base ? relative_path_from(path, relative_base) : File.basename(path),
      "filename"      => File.basename(path),
      "size_bytes"    => absolute && File.file?(path) ? File.size(path) : 0,
      "modified_at"   => absolute && File.exist?(path) ? File.mtime(path).strftime("%Y-%m-%d %H:%M:%S") : nil
    }
  end

  def relative_paths(paths, base_path)
    paths[0, SCRIPT_SAMPLE_LIMIT].map { |path| relative_path_from(path, base_path) }
  end

  def relative_path_from(path, base_path)
    expanded_path = File.expand_path(path).gsub("\\", "/")
    expanded_base = File.expand_path(base_path).gsub("\\", "/")
    if expanded_path.start_with?(expanded_base + "/")
      return expanded_path[(expanded_base.length + 1)..-1]
    end
    return File.basename(path)
  end
end

TravelExpansionFramework.write_external_script_source_reports
