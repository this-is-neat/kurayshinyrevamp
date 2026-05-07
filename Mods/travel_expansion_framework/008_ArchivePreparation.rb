module TravelExpansionFramework
  PREPARED_SNAPSHOT_DIRNAME = "PreparedSnapshots" if !const_defined?(:PREPARED_SNAPSHOT_DIRNAME)

  module_function

  def prepared_snapshots_dir
    return File.join(library_dir, PREPARED_SNAPSHOT_DIRNAME)
  end

  def prepared_project_root(project_id)
    return File.join(prepared_snapshots_dir, slugify(project_id))
  end

  def prepared_data_root(project_id)
    return File.join(prepared_project_root(project_id), "Data")
  end

  def external_project_preparable?(project_info)
    return false if !project_info.is_a?(Hash)
    return true if !project_info[:archive_path].to_s.empty? && (!project_info[:data_root].to_s.empty? || supports_virtual_mounts?)
    return false
  end

  def copy_runtime_file(source_path, destination_path)
    return false if source_path.to_s.empty? || destination_path.to_s.empty?
    return false if !runtime_file_exists?(source_path)
    ensure_dir(File.dirname(destination_path))
    File.open(source_path, "rb") do |input|
      File.open(destination_path, "wb") do |output|
        loop do
          chunk = input.read(32_768)
          break if !chunk || chunk.empty?
          output.write(chunk)
        end
      end
    end
    return true
  rescue => e
    log("Snapshot copy failed from #{source_path} to #{destination_path}: #{e.message}")
    return false
  end

  def build_prepared_link_hash(project_info, data_root)
    project_root = File.expand_path(File.dirname(data_root.to_s)) if !data_root.to_s.empty?
    return {
      "id"                => project_info[:id],
      "root"              => project_info[:root],
      "display_name"      => project_info[:display_name],
      "enabled"           => true,
      "direct_mount"      => true,
      "prepared_data_root" => data_root,
      "prepared_project_root" => project_root,
      "position_mode"     => normalize_string(project_info[:position_mode], "fixed"),
      "mode_options"      => Array(project_info[:mode_options]).map { |mode| normalize_string(mode, "shared") }.uniq,
      "status_reason"     => "Prepared snapshot staged at #{data_root}. Restart the game to relink this install through the extracted data snapshot."
    }
  end

  def prepare_external_project(project_reference)
    project_info = project_reference.is_a?(Hash) ? project_reference : external_projects[project_reference.to_s]
    return { "success" => false, "error" => "Project was not found." } if !project_info.is_a?(Hash)
    project_id = project_info[:id].to_s
    return { "success" => false, "error" => "Project identifier is missing." } if project_id.empty?
    source_data_root = project_info[:data_root].to_s
    if source_data_root.empty? && !project_info[:archive_path].to_s.empty? && supports_virtual_mounts?
      mounted_root = mounted_data_root_for_project(project_id, project_info[:archive_path])
      source_data_root = mounted_root.to_s
    end
    return { "success" => false, "error" => "No readable data source was available for this project." } if source_data_root.empty?

    target_root = prepared_project_root(project_id)
    target_data_root = prepared_data_root(project_id)
    ensure_dir(target_data_root)

    fixed_filenames = [
      "System.rxdata",
      "MapInfos.rxdata",
      "CommonEvents.rxdata",
      "Scripts.rxdata",
      "Scripts.rvdata",
      "Scripts.rvdata2",
      "PluginScripts.rxdata",
      "PluginScripts.rvdata",
      "PluginScripts.rvdata2",
      "Animations.rxdata",
      "Areas.rxdata",
      "Classes.rxdata",
      "Enemies.rxdata",
      "Items.rxdata",
      "MapConnections.rxdata",
      "Metadata.rxdata",
      "PokemonForms.rxdata",
      "Skills.rxdata",
      "States.rxdata",
      "Tilesets.rxdata",
      "TownMap.rxdata",
      "Troops.rxdata"
    ]

    map_ids = Array(project_info[:map_ids])
    map_ids = detect_map_ids_from_data_root(source_data_root) if map_ids.empty?
    map_ids.each do |map_id|
      fixed_filenames << format("Map%03d.rxdata", integer(map_id, 0))
    end

    script_sources = project_info[:script_sources].is_a?(Hash) ? project_info[:script_sources] : {}
    Array(script_sources[:script_archives]).each do |entry|
      filename = File.basename((entry[:path] || entry["path"]).to_s)
      fixed_filenames << filename if !filename.empty?
    end
    Array(script_sources[:plugin_script_archives]).each do |entry|
      filename = File.basename((entry[:path] || entry["path"]).to_s)
      fixed_filenames << filename if !filename.empty?
    end

    copied_files = []
    missing_files = []
    fixed_filenames.uniq.each do |filename|
      next if filename.to_s.empty?
      source_path = runtime_path_join(source_data_root, filename)
      if !runtime_file_exists?(source_path)
        missing_files << filename
        next
      end
      destination_path = File.join(target_data_root, filename)
      copied_files << filename if copy_runtime_file(source_path, destination_path)
    end

    link_path = File.join(links_dir, "#{project_id}.json")
    ensure_dir(File.dirname(link_path))
    File.open(link_path, "wb") { |file| file.write(safe_json_dump(build_prepared_link_hash(project_info, target_data_root))) }

    result = {
      "success"             => true,
      "project_id"          => project_id,
      "display_name"        => project_info[:display_name],
      "source_data_root"    => source_data_root,
      "prepared_root"       => target_root,
      "prepared_data_root"  => target_data_root,
      "link_path"           => link_path,
      "copied_file_count"   => copied_files.length,
      "copied_files"        => copied_files,
      "missing_files"       => missing_files,
      "map_count"           => map_ids.length,
      "generated_at"        => timestamp_string,
      "restart_required"    => true
    }
    write_json_report("prepared_snapshot_#{project_id}.json", result)
    return result
  rescue => e
    log("Prepared snapshot failed for #{project_reference}: #{e.message}")
    return {
      "success"      => false,
      "project_id"   => project_id,
      "display_name" => (project_info[:display_name] rescue project_reference.to_s),
      "error"        => e.message
    }
  end
end
