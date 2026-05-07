begin
  require "zlib"
rescue LoadError
end

module TravelExpansionFramework
  SCRIPT_INGEST_DIRNAME = "ScriptIngest" if !const_defined?(:SCRIPT_INGEST_DIRNAME)
  EXTRACTED_ARCHIVES_DIRNAME = "ExtractedArchives" if !const_defined?(:EXTRACTED_ARCHIVES_DIRNAME)
  ARCHIVE_EXTRACTOR_DIRNAME = "Tools/RPGMakerDecrypter" if !const_defined?(:ARCHIVE_EXTRACTOR_DIRNAME)

  module_function

  def script_ingest_dir
    path = File.join(library_dir, SCRIPT_INGEST_DIRNAME)
    ensure_dir(path)
    return path
  end

  def extracted_archives_dir
    path = File.join(library_dir, EXTRACTED_ARCHIVES_DIRNAME)
    ensure_dir(path)
    return path
  end

  def archive_extractor_dir
    path = File.join(library_dir, ARCHIVE_EXTRACTOR_DIRNAME)
    ensure_dir(path)
    return path
  end

  def archive_extractor_path
    candidates = [
      File.join(archive_extractor_dir, "RPGMakerDecrypter-cli.exe"),
      File.join(archive_extractor_dir, "RPGMakerDecrypter-cli")
    ]
    return candidates.find { |path| File.file?(path) }
  end

  def archive_extractor_available?
    return !archive_extractor_path.nil?
  end

  def external_archive_extract_root(project_id)
    path = File.join(extracted_archives_dir, slugify(project_id))
    ensure_dir(path)
    return path
  end

  def script_ingest_project_root(project_id)
    path = File.join(script_ingest_dir, slugify(project_id))
    ensure_dir(path)
    return path
  end

  def external_script_workspace_manifest_path(project_info)
    return nil if !project_info.is_a?(Hash)
    return File.join(script_ingest_project_root(project_info[:id]), "manifest.json")
  end

  def external_script_workspace_ready?(project_info)
    path = external_script_workspace_manifest_path(project_info)
    return !path.nil? && File.file?(path)
  end

  def can_prepare_external_script_workspace?(project_info)
    return false if !project_info.is_a?(Hash)
    script_sources = project_info[:script_sources].is_a?(Hash) ? project_info[:script_sources] : {}
    return true if !script_sources[:script_directory].to_s.empty? && File.directory?(script_sources[:script_directory].to_s)
    return true if Array(script_sources[:script_archives]).length > 0
    return true if Array(script_sources[:plugin_script_archives]).length > 0
    return true if Array(script_sources[:plugin_directories]).length > 0
    return false
  end

  def can_extract_external_archive?(project_info)
    return false if !project_info.is_a?(Hash)
    return false if project_info[:archive_path].to_s.empty?
    return false if !archive_extractor_available?
    return true
  end

  def normalized_script_filename(index, name)
    base = name.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    base = File.basename(base.gsub("\\", "/"))
    base = base.gsub(/\.[^.]+\z/, "")
    base = "script" if base.strip.empty?
    base.gsub!(/[\\\/:\*\?\"<>\|]/, "_")
    base.gsub!(/\s+/, "_")
    base.gsub!(/[^\w\-\.\(\)\[\]]+/, "_")
    base.gsub!(/_+/, "_")
    base.gsub!(/\A_+|_+\z/, "")
    base = "script" if base.empty?
    base = base[0, 80]
    return format("%03d_%s.rb", integer(index, 0), base)
  end

  def normalize_script_text(text)
    normalized = text.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    normalized.gsub!(/\r\n?/, "\n")
    return normalized
  end

  def write_script_text(path, text)
    ensure_dir(File.dirname(path))
    File.open(path, "wb") { |file| file.write(normalize_script_text(text).gsub("\n", "\r\n")) }
    return true
  rescue => e
    log("Script write failed for #{path}: #{e.message}")
    return false
  end

  def decode_rgss_script_archive(archive_path)
    return [] if archive_path.to_s.empty?
    payload = load_marshaled_runtime(archive_path)
    return [] if !payload.is_a?(Array)
    decoded = []
    payload.each_with_index do |entry, index|
      next if !entry.is_a?(Array)
      script_name = normalize_string(entry[1], "script_#{index}")
      body = entry[2]
      text = ""
      if body.is_a?(String)
        begin
          text = defined?(Zlib) ? Zlib::Inflate.inflate(body) : body
        rescue
          text = body
        end
      else
        text = body.to_s
      end
      decoded << {
        "index"    => index,
        "name"     => script_name,
        "filename" => normalized_script_filename(index, script_name),
        "bytes"    => text.to_s.bytesize,
        "text"     => normalize_script_text(text)
      }
    end
    return decoded
  rescue => e
    log("RGSS script archive decode failed for #{archive_path}: #{e.message}")
    return []
  end

  def copy_script_tree_to_workspace(source_root, destination_root)
    copied_files = []
    return copied_files if source_root.to_s.empty? || !File.directory?(source_root)
    Dir[File.join(source_root, "**", "*")].sort.each do |path|
      next if File.directory?(path)
      relative = relative_path_from(path, source_root)
      destination = File.join(destination_root, relative)
      copied_files << relative if copy_runtime_file(path, destination)
    end
    return copied_files
  end

  def build_script_workspace_manifest(project_info, report)
    return {
      "generated_at"         => timestamp_string,
      "project_id"           => project_info[:id],
      "display_name"         => project_info[:display_name],
      "root"                 => project_info[:root],
      "script_workspace"     => report["workspace_root"],
      "source_tree"          => report["source_tree"],
      "decoded_archives"     => report["decoded_archives"],
      "copied_plugin_dirs"   => report["copied_plugin_dirs"],
      "total_written_files"  => integer(report["total_written_files"], 0),
      "warnings"             => Array(report["warnings"])
    }
  end

  def prepare_external_script_workspace(project_reference)
    project_info = project_reference.is_a?(Hash) ? project_reference : external_projects[project_reference.to_s]
    return { "success" => false, "error" => "Project was not found." } if !project_info.is_a?(Hash)
    return { "success" => false, "error" => "No readable script sources were detected for this project." } if !can_prepare_external_script_workspace?(project_info)

    workspace_root = script_ingest_project_root(project_info[:id])
    source_tree_root = File.join(workspace_root, "source_tree")
    decoded_archives_root = File.join(workspace_root, "decoded_archives")
    plugins_root = File.join(workspace_root, "plugins")
    ensure_dir(source_tree_root)
    ensure_dir(decoded_archives_root)
    ensure_dir(plugins_root)

    script_sources = project_info[:script_sources].is_a?(Hash) ? project_info[:script_sources] : {}
    written_count = 0
    warnings = []
    copied_plugin_dirs = []
    decoded_archives = []
    source_tree_report = {
      "path"          => nil,
      "written_files" => 0,
      "sample_files"  => []
    }

    script_directory = script_sources[:script_directory].to_s
    if !script_directory.empty? && File.directory?(script_directory)
      copied = copy_script_tree_to_workspace(script_directory, source_tree_root)
      written_count += copied.length
      source_tree_report["path"] = script_directory
      source_tree_report["written_files"] = copied.length
      source_tree_report["sample_files"] = copied[0, SCRIPT_SAMPLE_LIMIT]
    end

    [[:script_archives, "scripts_archive"], [:plugin_script_archives, "plugin_archive"]].each do |key, kind|
      Array(script_sources[key]).each do |entry|
        archive_path = (entry[:path] || entry["path"]).to_s
        next if archive_path.empty?
        archive_name = File.basename(archive_path).gsub(/\.[^.]+\z/, "")
        archive_root = File.join(decoded_archives_root, archive_name)
        ensure_dir(archive_root)
        decoded = decode_rgss_script_archive(archive_path)
        warnings << "Archive #{archive_path} did not decode into readable script entries." if decoded.empty?
        decoded.each do |script_entry|
          destination = File.join(archive_root, script_entry["filename"])
          written_count += 1 if write_script_text(destination, script_entry["text"])
        end
        decoded_archives << {
          "kind"          => kind,
          "path"          => archive_path,
          "output_root"   => archive_root,
          "script_count"  => decoded.length,
          "sample_files"  => decoded.map { |item| item["filename"] }[0, SCRIPT_SAMPLE_LIMIT]
        }
      end
    end

    Array(script_sources[:plugin_directories]).each do |plugin_dir|
      plugin_path = plugin_dir.is_a?(Hash) ? (plugin_dir[:path] || plugin_dir["path"]).to_s : plugin_dir.to_s
      next if plugin_path.empty? || !File.directory?(plugin_path)
      destination = File.join(plugins_root, File.basename(plugin_path))
      copied = copy_script_tree_to_workspace(plugin_path, destination)
      meta_files = Dir[File.join(plugin_path, "**", "meta.txt")].sort
      meta_files.each do |meta_path|
        relative = relative_path_from(meta_path, plugin_path)
        target = File.join(destination, relative)
        written_count += 1 if copy_runtime_file(meta_path, target)
      end
      written_count += copied.length
      copied_plugin_dirs << {
        "path"          => plugin_path,
        "output_root"   => destination,
        "written_files" => copied.length + meta_files.length
      }
    end

    report = {
      "success"             => true,
      "project_id"          => project_info[:id],
      "display_name"        => project_info[:display_name],
      "workspace_root"      => workspace_root,
      "source_tree"         => source_tree_report,
      "decoded_archives"    => decoded_archives,
      "copied_plugin_dirs"  => copied_plugin_dirs,
      "total_written_files" => written_count,
      "warnings"            => warnings,
      "generated_at"        => timestamp_string
    }
    manifest_path = external_script_workspace_manifest_path(project_info)
    File.open(manifest_path, "wb") { |file| file.write(safe_json_dump(build_script_workspace_manifest(project_info, report))) }
    write_json_report("script_workspace_#{slugify(project_info[:id])}.json", report)
    return report
  rescue => e
    log("Script workspace preparation failed for #{project_reference}: #{e.message}")
    return {
      "success"      => false,
      "display_name" => (project_info[:display_name] rescue project_reference.to_s),
      "error"        => e.message
    }
  end

  def extract_external_archive(project_reference)
    project_info = project_reference.is_a?(Hash) ? project_reference : external_projects[project_reference.to_s]
    return { "success" => false, "error" => "Project was not found." } if !project_info.is_a?(Hash)
    return { "success" => false, "error" => "This project does not expose an archive path." } if project_info[:archive_path].to_s.empty?
    extractor = archive_extractor_path
    return { "success" => false, "error" => "No RGSS archive extractor is installed." } if extractor.nil?

    output_root = external_archive_extract_root(project_info[:id])
    ensure_dir(output_root)
    archive_path = project_info[:archive_path].to_s
    command = "\"#{extractor}\" \"#{archive_path}\" -o \"#{output_root}\" -p -w"
    success = system(command)
    prepared_data = File.join(output_root, "Data")
    return { "success" => false, "display_name" => project_info[:display_name], "error" => "Archive extractor reported failure." } if !success
    return { "success" => false, "display_name" => project_info[:display_name], "error" => "Extraction completed but no Data folder was produced." } if !File.directory?(prepared_data)

    link_path = File.join(links_dir, "#{project_info[:id]}.json")
    ensure_dir(File.dirname(link_path))
    File.open(link_path, "wb") { |file| file.write(safe_json_dump(build_prepared_link_hash(project_info, prepared_data))) }

    result = {
      "success"             => true,
      "project_id"          => project_info[:id],
      "display_name"        => project_info[:display_name],
      "archive_path"        => archive_path,
      "extractor_path"      => extractor,
      "output_root"         => output_root,
      "prepared_data_root"  => prepared_data,
      "link_path"           => link_path,
      "restart_required"    => true,
      "generated_at"        => timestamp_string
    }
    write_json_report("archive_extract_#{slugify(project_info[:id])}.json", result)
    return result
  rescue => e
    log("Archive extraction failed for #{project_reference}: #{e.message}")
    return {
      "success"      => false,
      "display_name" => (project_info[:display_name] rescue project_reference.to_s),
      "error"        => e.message
    }
  end
end

module TravelExpansionFramework
  module_function

  PB_SPECIES_FALLBACKS = {
    :ORCHYNX   => :CSF_URANIUM_ORCHYNX,
    :RAPTORCH  => :CSF_URANIUM_RAPTORCH,
    :ELETUX    => :CSF_URANIUM_ELETUX,
    :SHYLEON   => :CSF_XENOVERSE_SHYLEON,
    :TRISHOUT  => :CSF_XENOVERSE_TRISHOUT,
    :SHULONG   => :CSF_XENOVERSE_SHULONG,
    :SHYLEONP  => :CSF_XENOVERSE_SHYLEONP,
    :TRISHOUTP => :CSF_XENOVERSE_TRISHOUTP,
    :SHULONGP  => :CSF_XENOVERSE_SHULONGP
  } if !const_defined?(:PB_SPECIES_FALLBACKS)

  def resolve_pb_species_constant_name(name)
    raw = name.to_s.strip
    return nil if raw.empty?
    candidates = []
    candidates << raw
    candidates << raw.upcase if raw != raw.upcase
    candidates << raw.downcase if raw != raw.downcase
    candidates.uniq.each do |candidate|
      symbol = candidate.to_sym
      if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:compatibility_alias_target)
        canonical_species = CustomSpeciesFramework.compatibility_alias_target(symbol) rescue nil
        if canonical_species
          canonical_data = GameData::Species.try_get(canonical_species) rescue nil
          return canonical_data.id if canonical_data
        end
      end
      species_data = GameData::Species.try_get(symbol) rescue nil
      return species_data.id if species_data
      fallback_species = PB_SPECIES_FALLBACKS[symbol]
      if fallback_species
        fallback_data = GameData::Species.try_get(fallback_species) rescue nil
        return fallback_data.id if fallback_data
      end
    end
    return nil
  rescue => e
    log("PBSpecies resolution failed for #{name}: #{e.class}: #{e.message}")
    return nil
  end

  def resolve_expansion_species(expansion_id, species_ref)
    return nil if species_ref.nil?
    if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:compatibility_alias_target)
      begin
        canonical = CustomSpeciesFramework.compatibility_alias_target(species_ref, expansion_id)
        return canonical if canonical
      rescue ArgumentError
        canonical = CustomSpeciesFramework.compatibility_alias_target(species_ref) rescue nil
        return canonical if canonical
      end
    end
    if species_ref.is_a?(Integer) &&
       defined?(CustomSpeciesFramework) &&
       CustomSpeciesFramework.respond_to?(:compatibility_number_alias_target)
      begin
        canonical = CustomSpeciesFramework.compatibility_number_alias_target(species_ref, expansion_id)
        return canonical if canonical
      rescue ArgumentError
        canonical = CustomSpeciesFramework.compatibility_number_alias_target(species_ref) rescue nil
        return canonical if canonical
      end
    end
    data = GameData::Species.try_get(species_ref) rescue nil
    return data.species if data && data.respond_to?(:species)
    fallback = PB_SPECIES_FALLBACKS[species_ref.to_sym] if species_ref.respond_to?(:to_sym)
    return fallback if fallback
    return species_ref
  rescue => e
    log("Expansion species resolution failed for #{expansion_id}/#{species_ref.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return species_ref
  end
end

if defined?(PBSpecies)
  class << PBSpecies
    if !method_defined?(:tef_original_const_missing)
      alias tef_original_const_missing const_missing if method_defined?(:const_missing)
    end

    def const_missing(name)
      species = TravelExpansionFramework.resolve_pb_species_constant_name(name)
      return const_set(name, species) if species
      if defined?(tef_original_const_missing)
        return tef_original_const_missing(name)
      end
      raise NameError, "uninitialized constant PBSpecies::#{name}"
    end
  end
end
