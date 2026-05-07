begin
  require "fileutils"
rescue LoadError
end

if !defined?($travel_expansion_framework_loaded)
  $travel_expansion_framework_loaded = true

  module TravelExpansionFramework
    VERSION                  = "0.2.0-rc.1"
    FRAMEWORK_MOD_ID         = "travel_expansion_framework"
    HOST_EXPANSION_ID        = "host"
    SAVE_SCHEMA_VERSION      = 2
    RESERVED_MAP_BLOCK_START = 20_000
    RESERVED_MAP_BLOCK_SIZE  = 1_000
    FIXED_EXTERNAL_MAP_BLOCK_STARTS = {
      "insurgence"      => 24_000,
      "pokemon_uranium" => 25_000,
      "reborn"          => 26_000,
      "xenoverse"       => 27_000,
      "opalo"           => 28_000,
      "empyrean"        => 29_000,
      "realidea"        => 30_000,
      "soulstones"      => 31_000,
      "soulstones2"     => 32_000,
      "anil"            => 33_000,
      "bushido"         => 34_000,
      "darkhorizon"     => 35_000,
      "infinity"        => 36_000,
      "solar_eclipse"   => 37_000,
      "vanguard"        => 38_000,
      "pokemon_z"       => 39_000,
      "chaos_in_vesita" => 40_000,
      "deserted"        => 41_000,
      "gadir_deluxe"    => 42_000,
      "hollow_woods"    => 43_000,
      "keishou"         => 44_000,
      "unbreakable_ties" => 45_000
    }.freeze
    MANIFEST_FILENAME        = "expansion_manifest.json"
    SOURCE_CONFIG_FILENAME   = "travel_expansion_sources.json"
    LINK_FILENAME            = "travel_expansion_link.json"
    LINKS_DIR                = File.expand_path("./ExpansionLinks")
    LIBRARY_DIR              = File.expand_path("./ExpansionLibrary")
    LINKED_PROJECTS_DIR      = File.expand_path("./ExpansionLibrary/LinkedProjects")
    VIRTUAL_MOUNT_ROOT       = "__travel_expansions__"
    REPORT_DIR               = File.expand_path("./Logs/travel_expansion_framework")
    LOG_FILE                 = File.join(REPORT_DIR, "framework.log")
    LOG_MAX_BYTES            = 1_500_000
    LOG_ROTATION_COUNT       = 3

    class SaveRoot
      attr_accessor :schema_version
      attr_accessor :framework_version
      attr_accessor :enabled_signature
      attr_accessor :expansions
      attr_accessor :missing_expansions
      attr_accessor :dormant_references
      attr_accessor :player_relocation_log
      attr_accessor :migration_history
      attr_accessor :last_host_anchor
      attr_accessor :canonical_location
      attr_accessor :last_good_host_anchor
      attr_accessor :last_good_expansion_anchors
      attr_accessor :last_completed_transition
      attr_accessor :failed_transition_log
      attr_accessor :release_manifest_version
      attr_accessor :release_last_safe_load_at
      attr_accessor :release_shim_hits
      attr_accessor :host_dex_shadow

      def initialize
        @schema_version       = TravelExpansionFramework::SAVE_SCHEMA_VERSION
        @framework_version    = TravelExpansionFramework::VERSION
        @enabled_signature    = []
        @expansions           = {}
        @missing_expansions   = []
        @dormant_references   = []
        @player_relocation_log = []
        @migration_history    = []
        @last_host_anchor     = nil
        @canonical_location   = nil
        @last_good_host_anchor = nil
        @last_good_expansion_anchors = {}
        @last_completed_transition = nil
        @failed_transition_log = []
        @release_manifest_version = nil
        @release_last_safe_load_at = nil
        @release_shim_hits = {}
        @host_dex_shadow = { "seen" => {}, "owned" => {} }
      end
    end

    class ExpansionState
      attr_accessor :id
      attr_accessor :version
      attr_accessor :enabled
      attr_accessor :installed
      attr_accessor :last_mode
      attr_accessor :shared_world
      attr_accessor :isolated_mode
      attr_accessor :badges
      attr_accessor :quests
      attr_accessor :regional_dex
      attr_accessor :fly_destinations
      attr_accessor :dormant_references
      attr_accessor :travel_count
      attr_accessor :last_entry_at
      attr_accessor :last_anchor
      attr_accessor :last_good_anchor
      attr_accessor :metadata

      def initialize(id = nil)
        @id                = id.to_s
        @version           = nil
        @enabled           = true
        @installed         = true
        @last_mode         = "shared"
        @shared_world      = true
        @isolated_mode     = false
        @badges            = {}
        @quests            = {}
        @regional_dex      = { "seen" => {}, "owned" => {} }
        @fly_destinations  = {}
        @dormant_references = []
        @travel_count      = 0
        @last_entry_at     = nil
        @last_anchor       = nil
        @last_good_anchor  = nil
        @metadata          = {}
      end
    end

    @save_root   = nil
    @registries  = {
      :expansions        => {},
      :maps              => {},
      :badges            => {},
      :quests            => {},
      :dex_data          => {},
      :variants          => {},
      :travel_nodes      => {},
      :assets            => {},
      :migrations        => {},
      :script_catalogs   => {},
      :external_projects => {},
      :release_compatibility => {},
      :release_shims     => {}
    }
    @runtime_bootstrapped = false
    @map_block_cursor     = RESERVED_MAP_BLOCK_START
    @mounted_sources      = {}

    module_function

    def registries
      @registries ||= {}
      return @registries
    end

    def registry(key)
      registries[key] ||= {}
      return registries[key]
    end

    def reset_registries!
      @registries = {
        :expansions        => {},
        :maps              => {},
        :badges            => {},
        :quests            => {},
        :dex_data          => {},
        :variants          => {},
        :travel_nodes      => {},
        :assets            => {},
        :migrations        => {},
        :script_catalogs   => {},
        :external_projects => {},
        :release_compatibility => {},
        :release_shims     => {}
      }
      @map_block_cursor = RESERVED_MAP_BLOCK_START
      @mounted_sources = {}
    end

    def runtime_bootstrapped?
      return @runtime_bootstrapped == true
    end

    def mark_bootstrapped!
      @runtime_bootstrapped = true
    end

    def report_dir
      return REPORT_DIR
    end

    def mounted_sources
      @mounted_sources ||= {}
      return @mounted_sources
    end

    def current_game_root
      return File.expand_path(".")
    end

    def framework_root
      return File.expand_path("./Mods/#{FRAMEWORK_MOD_ID}")
    end

    def links_dir
      return LINKS_DIR
    end

    def library_dir
      return LIBRARY_DIR
    end

    def linked_projects_dir
      return LINKED_PROJECTS_DIR
    end

    def linked_project_bridge_root(project_id)
      path = linked_project_bridge_path(project_id)
      return nil if path.nil? || !File.directory?(path)
      return File.expand_path(path)
    end

    def linked_project_bridge_path(project_id)
      return nil if project_id.nil? || project_id.to_s.empty?
      return File.expand_path(File.join(linked_projects_dir, slugify(project_id)))
    end

    def ensure_linked_project_bridge!(project_id, target_root)
      bridge_path = linked_project_bridge_path(project_id)
      return nil if bridge_path.nil?
      return bridge_path if File.directory?(bridge_path)
      target_path = normalize_path(target_root)
      return nil if target_path.nil? || !File.directory?(target_path)
      ensure_dir(linked_projects_dir)
      created = false
      if RUBY_PLATFORM.to_s.match?(/mswin|mingw|cygwin/i)
        bridge_cmd = bridge_path.gsub("/", "\\")
        target_cmd = target_path.gsub("/", "\\")
        created = system(%(cmd /c mklink /J "#{bridge_cmd}" "#{target_cmd}" >NUL))
      else
        File.symlink(target_path, bridge_path)
        created = true
      end
      if created && File.directory?(bridge_path)
        log("Created linked project bridge #{bridge_path} -> #{target_path}")
        return bridge_path
      end
      return linked_project_bridge_root(project_id)
    rescue => e
      log("Failed to create linked project bridge for #{project_id}: #{e.class}: #{e.message}")
      return linked_project_bridge_root(project_id)
    end

    def source_config_path
      return File.join(framework_root, SOURCE_CONFIG_FILENAME)
    end

    def ensure_report_dir
      return if File.directory?(report_dir)
      ensure_dir(report_dir)
    end

    def ensure_dir(path)
      return if !path || path.to_s.empty? || File.directory?(path)
      normalized = File.expand_path(path)
      current = normalized.gsub("\\", "/")
      parts = current.split("/")
      base = ""
      if current =~ /\A[A-Za-z]:\//
        base = parts.shift + "/"
      elsif current.start_with?("/")
        base = "/"
        parts.shift if parts.first == ""
      end
      parts.each do |part|
        next if part.nil? || part.empty?
        base = base.empty? ? part : File.join(base, part)
        Dir.mkdir(base) if !File.directory?(base)
      end
    rescue
      Dir.mkdir(path) rescue nil
    end

    def ensure_framework_dirs
      ensure_dir(report_dir)
      ensure_dir(links_dir)
      ensure_dir(library_dir)
      ensure_dir(linked_projects_dir)
    end

    def timestamp_string
      return Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end

    def rotate_framework_log_if_needed
      return if !File.file?(LOG_FILE)
      max_bytes = integer(LOG_MAX_BYTES, 1_500_000)
      return if max_bytes <= 0 || File.size(LOG_FILE) < max_bytes
      LOG_ROTATION_COUNT.downto(1) do |index|
        source = index == 1 ? LOG_FILE : "#{LOG_FILE}.#{index - 1}"
        target = "#{LOG_FILE}.#{index}"
        next if !File.file?(source)
        File.delete(target) if File.file?(target)
        File.rename(source, target)
      end
    rescue
    end

    def log(message)
      ensure_framework_dirs
      rotate_framework_log_if_needed
      File.open(LOG_FILE, "ab") { |file| file.write("[#{timestamp_string}] #{message}\r\n") }
    rescue
      echoln("[TravelExpansionFramework] #{message}") if defined?(echoln)
    end

    def safe_json_parse(path)
      return nil if !File.file?(path)
      raw = File.read(path)
      return ModManager::JSON.parse(raw) if defined?(ModManager::JSON)
      return nil
    rescue => e
      log("JSON parse failed for #{path}: #{e.message}")
      return nil
    end

    def safe_json_dump(data)
      return ModManager::JSON.dump(data) if defined?(ModManager::JSON)
      return data.inspect
    end

    def normalize_string(value, fallback = "")
      text = value.to_s.strip
      text = fallback.to_s if text.empty?
      return text
    end

    def slugify(value)
      slug = normalize_string(value, "expansion").downcase
      slug.gsub!(/[^\w]+/, "_")
      slug.gsub!(/\A_+|_+\z/, "")
      slug = "expansion" if slug.empty?
      return slug
    end

    def integer(value, fallback = 0)
      return value if value.is_a?(Integer)
      return fallback if value.nil?
      return Integer(value)
    rescue
      return fallback
    end

    def item_lookup_guard_depth
      @item_lookup_guard_depth ||= 0
      return @item_lookup_guard_depth
    end

    def item_lookup_guard_active?
      return item_lookup_guard_depth > 0
    end

    def with_item_lookup_guard
      @item_lookup_guard_depth = item_lookup_guard_depth + 1
      return yield
    ensure
      @item_lookup_guard_depth = [item_lookup_guard_depth - 1, 0].max
    end

    def boolean(value, fallback = false)
      return value if value == true || value == false
      return fallback if value.nil?
      return value.to_s.downcase == "true"
    end

    def normalize_anchor(anchor)
      if anchor.is_a?(Array)
        return {
          :map_id    => integer(anchor[0], 0),
          :x         => integer(anchor[1], 0),
          :y         => integer(anchor[2], 0),
          :direction => integer(anchor[3], 2)
        }
      end
      if anchor.is_a?(Hash)
        return {
          :map_id    => integer(anchor["map_id"] || anchor[:map_id], 0),
          :x         => integer(anchor["x"] || anchor[:x], 0),
          :y         => integer(anchor["y"] || anchor[:y], 0),
          :direction => integer(anchor["direction"] || anchor[:direction], 2)
        }
      end
      return nil
    end

    def normalize_path(path, base = nil)
      return nil if path.nil?
      text = path.to_s.strip
      return nil if text.empty?
      return File.expand_path(text) if text[/\A[A-Za-z]\:[\/\\]/]
      base_path = base || current_game_root
      return File.expand_path(File.join(base_path, text))
    end

    def absolute_path?(path)
      return false if path.nil?
      text = path.to_s
      return true if text[/\A[A-Za-z]\:[\/\\]/]
      return true if text.start_with?("/")
      return false
    end

    def game_relative_path(path)
      return nil if path.nil? || path.to_s.empty?
      absolute = File.expand_path(path.to_s).gsub("\\", "/")
      game_root = current_game_root.gsub("\\", "/")
      prefix = game_root.end_with?("/") ? game_root : "#{game_root}/"
      return nil if !absolute.downcase.start_with?(prefix.downcase)
      return absolute[prefix.length..-1]
    end

    def prefer_game_relative_path(path)
      return nil if path.nil? || path.to_s.empty?
      normalized = path.to_s.gsub("\\", "/")
      return normalized if !absolute_path?(normalized)
      relative = game_relative_path(normalized)
      return relative if relative && runtime_plain_file_exists?(relative)
      return File.expand_path(normalized)
    end

    def runtime_asset_roots_for_expansion(expansion_id)
      expansion = expansion_id.to_s
      return [] if expansion.empty?
      roots = []
      info = external_projects[expansion] if respond_to?(:external_projects)
      if info.is_a?(Hash)
        roots << info[:prepared_project_root]
        roots << info[:filesystem_bridge_root]
        roots << info[:source_mount_root]
        roots << info[:archive_mount_root]
      end
      roots.concat(Array(registry(:assets)[expansion])) if respond_to?(:registry)
      manifest = manifest_for(expansion) if respond_to?(:manifest_for)
      roots.concat(Array(manifest[:asset_roots])) if manifest.is_a?(Hash)
      roots << info[:root] if info.is_a?(Hash)
      return roots.compact.map { |root| root.to_s }.reject { |root| root.empty? }.uniq
    rescue
      return []
    end

    def resolve_runtime_path_for_expansion(expansion_id, logical_path, extensions = [])
      return nil if logical_path.nil?
      raw_path = logical_path.to_s
      return nil if raw_path.empty?
      normalized = raw_path.gsub("\\", "/").sub(/\A\.\//, "")
      return nil if normalized.empty?
      exts = extensions.is_a?(Array) ? extensions : [extensions]
      exts = [""] if exts.empty?
      if absolute_path?(normalized)
        existing = runtime_existing_path(normalized)
        return existing if existing
      elsif normalized !~ %r{\A(?:Graphics|Audio|Data)/}i
        existing = runtime_existing_path(normalized)
        return existing if existing
      end
      normalized.sub!(%r{\A/}, "")
      return nil if normalized.empty? || normalized.end_with?("/")
      basename = File.basename(normalized)
      return nil if basename.nil? || basename.empty? || basename == "." || basename == ".."
      runtime_asset_roots_for_expansion(expansion_id).each do |root|
        next if root.nil? || root.to_s.empty?
        candidate = runtime_path_join(root, normalized)
        existing = runtime_existing_path(candidate)
        return existing if existing
        exts.each do |ext|
          next if ext.to_s.empty?
          with_extension = candidate
          with_extension += ext.to_s if !candidate.downcase.end_with?(ext.to_s.downcase)
          existing = runtime_existing_path(with_extension)
          return existing if existing
        end
      end
      return nil
    rescue
      return nil
    end

    def runtime_path_join(root, child = nil)
      left = root.to_s.gsub("\\", "/")
      right = child.to_s.gsub("\\", "/")
      return left if right.empty?
      return right if left.empty?
      if absolute_path?(left)
        return File.expand_path(File.join(left, right))
      end
      left.sub!(%r{/+\z}, "")
      right.sub!(%r{\A/+}, "")
      return "#{left}/#{right}"
    end

    def runtime_plain_file_exists?(path)
      return false if path.nil? || path.to_s.empty?
      candidate = path.to_s.gsub("\\", "/")
      if absolute_path?(candidate)
        return File.file?(File.expand_path(candidate))
      end
      return safeExists?(candidate) if defined?(safeExists?)
      begin
        File.open(candidate, "rb") { return true }
      rescue
        return false
      end
    end

    def runtime_exact_file_path(path)
      return nil if path.nil? || path.to_s.empty?
      candidate = path.to_s.gsub("\\", "/")
      absolute = if absolute_path?(candidate)
        File.expand_path(candidate)
      else
        File.expand_path(candidate, current_game_root)
      end
      directory = File.dirname(absolute)
      basename = File.basename(absolute)
      return absolute if basename.nil? || basename.empty?
      if File.directory?(directory)
        entry = Dir.entries(directory).find { |name| name.to_s.downcase == basename.downcase }
        if entry && !entry.empty?
          matched = File.join(directory, entry)
          return matched if File.file?(matched)
        end
      end
      return absolute if File.file?(absolute)
      return nil
    rescue
      return nil
    end

    def runtime_existing_path(path)
      matched = runtime_exact_file_path(path)
      return nil if matched.nil?
      return prefer_game_relative_path(matched)
    end

    def runtime_file_exists?(path)
      return !runtime_exact_file_path(path).nil?
    end

    def runtime_directory_exists?(path)
      return false if path.nil? || path.to_s.empty?
      candidate = path.to_s
      return File.directory?(File.expand_path(candidate)) if absolute_path?(candidate)
      return safeIsDirectory?(candidate) if defined?(safeIsDirectory?)
      begin
        Dir.chdir(candidate) { return true }
      rescue
        return false
      end
    end

    def load_marshaled_runtime(path)
      candidate = path.to_s
      raise Errno::ENOENT if candidate.empty?
      if absolute_path?(candidate)
        normalized = File.expand_path(candidate)
        raise Errno::ENOENT if !File.file?(normalized)
        File.open(normalized, "rb") { |file| return Marshal.load(file) }
      end
      if candidate !~ /\AData\//i && runtime_file_exists?(candidate)
        begin
          File.open(candidate, "rb") { |file| return Marshal.load(file) }
        rescue
        end
      end
      return load_data(candidate)
    end

    def supports_virtual_mounts?
      return defined?(System) && System.respond_to?(:mount)
    end

    def system_reload_cache!
      return if !defined?(System) || !System.respond_to?(:reload_cache)
      System.reload_cache
    rescue => e
      log("System.reload_cache failed: #{e.message}")
    end

    def mount_source!(source_path, mount_point, reload = true)
      return false if !supports_virtual_mounts?
      source = File.expand_path(source_path.to_s)
      return false if source.empty? || !File.exist?(source)
      mount = mount_point.to_s.gsub("\\", "/")
      existing = mounted_sources[source]
      return true if existing == mount
      System.mount(source, mount, reload)
      mounted_sources[source] = mount
      return true
    rescue => e
      log("Failed to mount #{source_path} at #{mount_point}: #{e.message}")
      return false
    ensure
      system_reload_cache! if reload
    end

    def unmount_source!(source_path, reload = true)
      return false if !defined?(System) || !System.respond_to?(:unmount)
      source = File.expand_path(source_path.to_s)
      return false if source.empty?
      System.unmount(source, reload)
      mounted_sources.delete(source)
      return true
    rescue => e
      log("Failed to unmount #{source_path}: #{e.message}")
      return false
    ensure
      system_reload_cache! if reload
    end

    def virtual_mount_point(identifier, suffix = "root")
      return runtime_path_join(runtime_path_join(VIRTUAL_MOUNT_ROOT, slugify(identifier)), suffix)
    end

    def mod_enabled?(mod_id)
      return true if mod_id.nil? || mod_id.to_s.empty?
      return true if !defined?(ModManager) || !ModManager.respond_to?(:enabled?)
      return ModManager.enabled?(mod_id)
    rescue
      return true
    end

    def enabled_mod_ids
      return [] if !defined?(ModManager) || !ModManager.respond_to?(:enabled_mods)
      return ModManager.enabled_mods
    rescue
      return []
    end

    def expansion_ids
      return registry(:expansions).keys
    end

    def external_projects
      return registry(:external_projects)
    end

    def manifest_for(expansion_id)
      return registry(:expansions)[expansion_id.to_s]
    end

    def manifest_for_map_id(map_id)
      target = integer(map_id, 0)
      return nil if target <= 0
      registry(:expansions).each_value do |manifest|
        block = manifest[:map_block]
        next if !block.is_a?(Hash)
        start_id = integer(block[:start] || block["start"], 0)
        size = integer(block[:size] || block["size"], 0)
        next if start_id <= 0 || size <= 0
        next if target < start_id || target >= start_id + size
        return manifest
      end
      return nil
    end

    def expansion_active?(expansion_id)
      manifest = manifest_for(expansion_id)
      return false if !manifest
      return manifest[:enabled] == true
    end

    def map_visual_asset_score_for_expansion(expansion_id, map_object = nil)
      expansion = expansion_id.to_s
      return 0 if expansion.empty? || !expansion_active?(expansion)
      map = map_object || $game_map
      return 0 if !map
      extensions = [".png", ".gif", ".jpg", ".jpeg", ".bmp"]
      score = 0
      tileset_name = map.tileset_name.to_s if map.respond_to?(:tileset_name)
      if tileset_name && !tileset_name.empty?
        score += 8 if resolve_runtime_path_for_expansion(expansion, "Graphics/Tilesets/#{tileset_name}", extensions)
      end
      autotiles = map.respond_to?(:autotile_names) ? Array(map.autotile_names) : []
      autotiles.each do |name|
        next if name.to_s.empty?
        score += 1 if resolve_runtime_path_for_expansion(expansion, "Graphics/Autotiles/#{name}", extensions)
      end
      return score
    rescue
      return 0
    end

    def log_map_marker_override_once(map_id, direct_expansion, marker, marker_score, direct_score)
      @map_marker_override_log_cache ||= {}
      key = [integer(map_id, 0), direct_expansion.to_s, marker.to_s].join("|")
      return if @map_marker_override_log_cache[key]
      @map_marker_override_log_cache[key] = true
      log("[map] using saved expansion marker #{marker} for map #{map_id} instead of #{direct_expansion.inspect} (asset scores marker=#{marker_score}, direct=#{direct_score})")
    rescue
    end

    def log_visual_owner_override_once(map_id, direct_expansion, visual_expansion, visual_score, direct_score)
      @map_visual_owner_log_cache ||= {}
      key = [integer(map_id, 0), direct_expansion.to_s, visual_expansion.to_s].join("|")
      return if @map_visual_owner_log_cache[key]
      @map_visual_owner_log_cache[key] = true
      log("[map] visual owner #{visual_expansion} detected for map #{map_id} instead of #{direct_expansion.inspect} (asset scores visual=#{visual_score}, direct=#{direct_score})")
    rescue
    end

    def map_visual_cache_key(map_object)
      map = map_object || $game_map
      return nil if !map
      map_id = map.respond_to?(:map_id) ? integer(map.map_id, 0) : 0
      tileset_name = map.respond_to?(:tileset_name) ? map.tileset_name.to_s : ""
      autotiles = map.respond_to?(:autotile_names) ? Array(map.autotile_names).map { |entry| entry.to_s }.join("\0") : ""
      signature = active_expansion_ids.sort.join(",")
      marker = current_expansion_marker.to_s
      return [map_id, tileset_name, autotiles, signature, marker].join("|")
    rescue
      return nil
    end

    def visual_expansion_scores_for_map(map_object = nil)
      map = map_object || $game_map
      return [] if !map
      @map_visual_score_cache ||= {}
      cache_key = map_visual_cache_key(map)
      cached = cache_key ? @map_visual_score_cache[cache_key] : nil
      return cached if cached
      map_id = map.respond_to?(:map_id) ? map.map_id : nil
      candidates = []
      candidates << current_expansion_marker.to_s
      candidates << direct_map_expansion_id(map_id).to_s if map_id && respond_to?(:direct_map_expansion_id)
      candidates.concat(active_expansion_ids)
      scores = []
      candidates.compact.map { |entry| entry.to_s }.reject { |entry| entry.empty? }.uniq.each do |expansion_id|
        score = map_visual_asset_score_for_expansion(expansion_id, map)
        scores << [expansion_id, score] if score > 0
      end
      scores = scores.sort { |a, b| (b[1] == a[1]) ? (a[0] <=> b[0]) : (b[1] <=> a[1]) }
      @map_visual_score_cache[cache_key] = scores if cache_key
      return scores
    rescue
      return []
    end

    def best_visual_expansion_for_map(map_object = nil, direct_expansion = nil)
      map = map_object || $game_map
      return nil if !map
      direct = direct_expansion.to_s
      marker = current_expansion_marker.to_s
      scores = visual_expansion_scores_for_map(map)
      return nil if scores.empty?
      best_score = scores[0][1].to_i
      tied = scores.find_all { |entry| entry[1].to_i == best_score }.map { |entry| entry[0].to_s }
      best_id = tied[0]
      # Prefer the direct owner on ties so a common autotile name doesn't
      # accidentally move a valid current map into an unrelated expansion.
      best_id = direct if !direct.empty? && tied.include?(direct)
      best_id = marker if !marker.empty? && tied.include?(marker) && (direct.empty? || !tied.include?(direct))
      return {
        :expansion_id => best_id,
        :score        => best_score,
        :scores       => scores
      }
    rescue
      return nil
    end

    def visual_expansion_id_for_map(map_object = nil)
      map = map_object || $game_map
      return nil if !map
      @map_visual_owner_cache ||= {}
      cache_key = map_visual_cache_key(map)
      if cache_key && @map_visual_owner_cache.key?(cache_key)
        cached = @map_visual_owner_cache[cache_key]
        return cached == false ? nil : cached
      end
      map_id = map.respond_to?(:map_id) ? map.map_id : nil
      direct = direct_map_expansion_id(map_id) if map_id && respond_to?(:direct_map_expansion_id)
      result = nil
      if !direct.to_s.empty?
        # A registered map block is authoritative. Cross-expansion visual
        # scoring is useful for repairs, but it is too expensive and too
        # error-prone for normal rendering/menu updates.
        result = direct
      else
        target = integer(map_id, 0)
        reserved_start = defined?(RESERVED_MAP_BLOCK_START) ? RESERVED_MAP_BLOCK_START : 20_000
        if target >= reserved_start
          best = best_visual_expansion_for_map(map, direct)
          result = best[:expansion_id] if best
        end
      end
      @map_visual_owner_cache[cache_key] = (result.nil? || result.to_s.empty?) ? false : result if cache_key
      return result
    rescue
      return nil
    end

    def current_map_marker_override_id(map_id, direct_expansion = nil)
      return nil if !$game_map
      target = integer(map_id, 0)
      return nil if target <= 0 || target != integer($game_map.map_id, 0)
      marker = current_expansion_marker.to_s
      return nil if marker.empty? || marker == direct_expansion.to_s
      return nil if !expansion_active?(marker)
      return nil if target < RESERVED_MAP_BLOCK_START
      marker_score = map_visual_asset_score_for_expansion(marker, $game_map)
      direct_score = map_visual_asset_score_for_expansion(direct_expansion, $game_map)
      direct_known = !direct_expansion.to_s.empty?
      if marker_score > 0 && (!direct_known || marker_score > direct_score)
        log_map_marker_override_once(target, direct_expansion, marker, marker_score, direct_score)
        return marker
      end
      return nil
    rescue
      return nil
    end

    def active_expansion_ids
      return expansion_ids.find_all { |expansion_id| expansion_active?(expansion_id) }
    end

    def current_enabled_signature
      return active_expansion_ids.sort
    end

    def save_root
      return ensure_save_root
    end

    def ensure_save_root
      @save_root ||= SaveRoot.new
      normalize_save_root!
      return @save_root
    end

    def load_save_root(value)
      @save_root = value.is_a?(SaveRoot) ? value : SaveRoot.new
      @after_load_prepared = false
      normalize_save_root!
      return @save_root
    end

    def normalize_save_root!
      @save_root ||= SaveRoot.new
      @save_root.schema_version        = SAVE_SCHEMA_VERSION if @save_root.schema_version.nil?
      @save_root.framework_version     = VERSION if @save_root.framework_version.nil?
      @save_root.enabled_signature     ||= []
      @save_root.expansions            ||= {}
      @save_root.missing_expansions    ||= []
      @save_root.dormant_references    ||= []
      @save_root.player_relocation_log ||= []
      @save_root.migration_history     ||= []
      @save_root.last_good_expansion_anchors ||= {}
      @save_root.failed_transition_log ||= []
      @save_root.release_shim_hits ||= {} if @save_root.respond_to?(:release_shim_hits)
      @save_root.host_dex_shadow ||= { "seen" => {}, "owned" => {} } if @save_root.respond_to?(:host_dex_shadow)
      if @save_root.respond_to?(:host_dex_shadow) && @save_root.host_dex_shadow.is_a?(Hash)
        @save_root.host_dex_shadow["seen"] ||= {}
        @save_root.host_dex_shadow["owned"] ||= {}
      end
      @save_root.canonical_location = normalize_canonical_location(@save_root.canonical_location) if @save_root.respond_to?(:canonical_location)
      @save_root.last_good_host_anchor = normalize_anchor(@save_root.last_good_host_anchor) if @save_root.respond_to?(:last_good_host_anchor) &&
                                                                                                 @save_root.last_good_host_anchor
      normalized_states = {}
      @save_root.expansions.each do |expansion_id, state|
        normalized_states[expansion_id.to_s] = normalize_expansion_state(state, expansion_id)
      end
      @save_root.expansions = normalized_states
      @save_root.last_host_anchor = normalize_anchor(@save_root.last_host_anchor) if @save_root.last_host_anchor
      normalized_good_anchors = {}
      @save_root.last_good_expansion_anchors.each do |expansion_id, anchor|
        normalized = normalize_anchor(anchor)
        normalized_good_anchors[expansion_id.to_s] = normalized if normalized
      end
      @save_root.last_good_expansion_anchors = normalized_good_anchors
      @save_root.last_completed_transition = normalize_transition_record(@save_root.last_completed_transition) if @save_root.respond_to?(:last_completed_transition)
    end

    def normalize_expansion_state(state, expansion_id)
      normalized = state.is_a?(ExpansionState) ? state : ExpansionState.new(expansion_id)
      normalized.id                 = expansion_id.to_s
      normalized.badges            ||= {}
      normalized.quests            ||= {}
      normalized.regional_dex      ||= { "seen" => {}, "owned" => {} }
      normalized.regional_dex["seen"]  ||= {}
      normalized.regional_dex["owned"] ||= {}
      normalized.fly_destinations  ||= {}
      normalized.dormant_references ||= []
      normalized.last_anchor = normalize_anchor(normalized.last_anchor) if normalized.last_anchor
      normalized.last_good_anchor = normalize_anchor(normalized.last_good_anchor) if normalized.respond_to?(:last_good_anchor) &&
                                                                                     normalized.last_good_anchor
      normalized.metadata          ||= {}
      normalized.last_mode         = "shared"
      normalized.isolated_mode     = false
      normalized.travel_count      ||= 0
      return normalized
    end

    def normalize_canonical_location(record)
      return nil if !record.is_a?(Hash)
      raw_anchor = record["anchor"] || record[:anchor] || record
      anchor = normalize_anchor(raw_anchor)
      return nil if !anchor || integer(anchor[:map_id], 0) <= 0
      expansion_id = normalize_string(record["expansion_id"] || record[:expansion_id], "")
      kind = normalize_string(record["kind"] || record[:kind], "")
      kind = "expansion" if kind.empty? && !expansion_id.empty?
      kind = "host" if kind.empty? || expansion_id.empty? || expansion_id == HOST_EXPANSION_ID
      expansion_id = "" if kind == "host"
      return {
        "kind"         => kind,
        "expansion_id" => expansion_id,
        "anchor"       => anchor,
        "updated_at"   => normalize_string(record["updated_at"] || record[:updated_at], ""),
        "reason"       => normalize_string(record["reason"] || record[:reason], "")
      }
    rescue
      return nil
    end

    def normalize_transition_record(record)
      return nil if !record.is_a?(Hash)
      source_anchor = normalize_anchor(record["from"] || record[:from])
      target_anchor = normalize_anchor(record["to"] || record[:to])
      return nil if !target_anchor
      return {
        "source"       => normalize_string(record["source"] || record[:source], "unknown"),
        "expansion_id" => normalize_string(record["expansion_id"] || record[:expansion_id], ""),
        "from"         => source_anchor,
        "to"           => target_anchor,
        "ok"           => boolean(record["ok"] || record[:ok], false),
        "error"        => normalize_string(record["error"] || record[:error], ""),
        "timestamp"    => normalize_string(record["timestamp"] || record[:timestamp], "")
      }
    rescue
      return nil
    end

    def state_for(expansion_id)
      expansion_id = expansion_id.to_s
      ensure_save_root
      current = @save_root.expansions[expansion_id]
      current = normalize_expansion_state(current, expansion_id)
      @save_root.expansions[expansion_id] = current
      return current
    end

    def host_badges(player = $Trainer)
      return [] if !player
      badges = player.badges || []
      target_size = $game_switches && $game_switches[SWITCH_BEAT_THE_LEAGUE] ? 16 : 8
      target_size = [target_size, badges.length].max
      normalized = Array.new(target_size, false)
      badges.each_with_index { |value, index| normalized[index] = value ? true : false }
      return normalized
    rescue
      return player && player.badges ? player.badges : []
    end

    def badge_slot_count(expansion_id = nil, page_id = nil)
      return host_badges.length if expansion_id.nil? || expansion_id.to_s.empty? || expansion_id.to_s == HOST_EXPANSION_ID
      manifest = manifest_for(expansion_id)
      return 8 if !manifest
      page = manifest[:badge_pages].find { |entry| entry[:id] == page_id.to_s } if page_id
      page ||= manifest[:badge_pages].first
      return page ? integer(page[:slot_count], 8) : 8
    end

    def badge_array_for(expansion_id, page_id = nil, player = $Trainer)
      return host_badges(player) if expansion_id.nil? || expansion_id.to_s.empty? || expansion_id.to_s == HOST_EXPANSION_ID
      manifest = manifest_for(expansion_id)
      return [] if !manifest
      page = manifest[:badge_pages].find { |entry| entry[:id] == page_id.to_s } if page_id
      page ||= manifest[:badge_pages].first
      return [] if !page
      slots = integer(page[:slot_count], 8)
      state = state_for(expansion_id)
      state.badges[page[:id].to_s] ||= Array.new(slots, false)
      badges = Array.new(slots, false)
      state.badges[page[:id].to_s].each_with_index { |value, index| badges[index] = value ? true : false if index < slots }
      return badges
    end

    def expansion_badge_count(expansion_id)
      manifest = manifest_for(expansion_id)
      return 0 if !manifest
      total = 0
      manifest[:badge_pages].each do |page|
        total += badge_array_for(expansion_id, page[:id]).count(true)
      end
      return total
    end

    def global_badge_count(player = $Trainer)
      total = host_badges(player).count(true)
      active_expansion_ids.each { |expansion_id| total += expansion_badge_count(expansion_id) }
      return total
    end

    def dex_state_for(expansion_id)
      return nil if expansion_id.nil? || expansion_id.to_s.empty? || expansion_id.to_s == HOST_EXPANSION_ID
      state = state_for(expansion_id)
      state.regional_dex["seen"]  ||= {}
      state.regional_dex["owned"] ||= {}
      return state.regional_dex
    end

    def dex_seen_count(expansion_id)
      dex_state = dex_state_for(expansion_id)
      return 0 if !dex_state
      return dex_state["seen"].length
    end

    def dex_owned_count(expansion_id)
      dex_state = dex_state_for(expansion_id)
      return 0 if !dex_state
      return dex_state["owned"].length
    end

    def global_dex_totals(player = $Trainer)
      return [0, 0] if !player || !player.respond_to?(:pokedex) || !player.pokedex
      return [player.pokedex.owned_count, player.pokedex.seen_count]
    rescue
      return [0, 0]
    end

    def host_dex_shadow
      root = ensure_save_root
      root.host_dex_shadow = { "seen" => {}, "owned" => {} } if !root.respond_to?(:host_dex_shadow) || !root.host_dex_shadow.is_a?(Hash)
      root.host_dex_shadow["seen"] ||= {}
      root.host_dex_shadow["owned"] ||= {}
      return root.host_dex_shadow
    rescue
      return { "seen" => {}, "owned" => {} }
    end

    def dex_species_key(species)
      if defined?(GameData::Species) && GameData::Species.respond_to?(:try_get)
        data = GameData::Species.try_get(species) rescue nil
        return data.id.to_s if data && data.respond_to?(:id)
      end
      return species.to_s
    rescue
      return species.to_s
    end

    def record_host_dex_progress(species, owned = false)
      key = dex_species_key(species)
      return false if key.empty?
      shadow = host_dex_shadow
      shadow["seen"][key] = true
      shadow["owned"][key] = true if owned
      return true
    rescue => e
      log("[release] host dex shadow update failed: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def rebuild_host_dex_shadow_from_storage!
      return false if !defined?($Trainer) || !$Trainer
      if $Trainer.respond_to?(:party)
        Array($Trainer.party).each { |pokemon| record_host_dex_progress(pokemon.species, true) if pokemon && pokemon.respond_to?(:species) }
      end
      if defined?($PokemonStorage) && $PokemonStorage
        storage = $PokemonStorage
        box_count = storage.maxBoxes if storage.respond_to?(:maxBoxes)
        box_count ||= storage.max_boxes if storage.respond_to?(:max_boxes)
        box_count = integer(box_count, 0)
        (0...box_count).each do |box|
          limit = storage.maxPokemon(box) rescue 30
          (0...integer(limit, 30)).each do |slot|
            pokemon = storage[box, slot] rescue nil
            record_host_dex_progress(pokemon.species, true) if pokemon && pokemon.respond_to?(:species)
          end
        end
      end
      return true
    rescue => e
      log("[release] host dex shadow rebuild failed: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def restore_host_dex_shadow_to_player!
      return false if !defined?($Trainer) || !$Trainer || !$Trainer.respond_to?(:pokedex) || !$Trainer.pokedex
      dex = $Trainer.pokedex
      shadow = host_dex_shadow
      shadow["seen"].each_key do |species|
        next if species.to_s.empty?
        if dex.respond_to?(:set_seen)
          dex.set_seen(species.to_sym) rescue dex.set_seen(species)
        elsif dex.respond_to?(:register)
          data = GameData::Species.try_get(species.to_sym) rescue nil
          dex.register(data.id) if data && data.respond_to?(:id)
        end
      end
      shadow["owned"].each_key do |species|
        next if species.to_s.empty?
        if dex.respond_to?(:set_owned)
          dex.set_owned(species.to_sym) rescue dex.set_owned(species)
        elsif dex.respond_to?(:register)
          data = GameData::Species.try_get(species.to_sym) rescue nil
          dex.register(data.id) if data && data.respond_to?(:id)
        end
      end
      return true
    rescue => e
      log("[release] host dex shadow restore failed: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def current_map_expansion_id(map_id = nil)
      map_id ||= ($game_map ? $game_map.map_id : nil)
      return nil if !map_id
      entry = direct_map_expansion_entry(map_id)
      return nil if !entry
      direct_expansion = entry[:expansion_id].to_s
      if $game_map && map_id == $game_map.map_id
        marker = current_expansion_marker
        return marker if !marker.to_s.empty? && marker.to_s == direct_expansion
      end
      return direct_expansion
    end

    def remap_legacy_reserved_map_id_for_marker(map_id, expansion_id)
      expansion = expansion_id.to_s
      return nil if expansion.empty?
      manifest = manifest_for(expansion)
      return nil if !manifest || !manifest[:map_block].is_a?(Hash)
      current_id = integer(map_id, 0)
      return nil if current_id < RESERVED_MAP_BLOCK_START
      local_id = current_id % RESERVED_MAP_BLOCK_SIZE
      return nil if local_id <= 0
      start_id = integer(manifest[:map_block][:start] || manifest[:map_block]["start"], 0)
      return nil if start_id <= 0
      target_id = start_id + local_id
      return nil if target_id == current_id
      return nil if !expansion_map_active?(target_id)
      return target_id
    rescue
      return nil
    end

    def repair_legacy_current_expansion_map_id!
      return false if !$game_map || !$game_player
      current_id = integer($game_map.map_id, 0)
      return false if current_id < RESERVED_MAP_BLOCK_START
      direct_entry = direct_map_expansion_entry(current_id)
      direct_expansion = direct_entry ? direct_entry[:expansion_id].to_s : nil
      best = best_visual_expansion_for_map($game_map, direct_expansion)
      owner = best ? best[:expansion_id].to_s : ""
      marker = current_expansion_marker.to_s
      owner = marker if owner.empty? && !marker.empty? && expansion_active?(marker)
      return false if owner.empty? || !expansion_active?(owner)
      if direct_entry
        return false if direct_expansion == owner
        # Only override a valid direct map block when the save marker agrees.
        # Visual asset guesses alone can mistake host-style mod maps for another expansion.
        return false if marker.empty? || marker != owner
        owner_score = map_visual_asset_score_for_expansion(owner, $game_map)
        direct_score = map_visual_asset_score_for_expansion(direct_expansion, $game_map)
        return false if owner_score <= 0 || owner_score <= direct_score
      end
      target_id = remap_legacy_reserved_map_id_for_marker(current_id, owner)
      return false if !target_id
      x = $game_player.x
      y = $game_player.y
      direction = $game_player.direction
      log("[map] remapping legacy saved expansion map #{current_id} -> #{target_id} for #{owner}")
      if defined?(PokemonMapFactory)
        $MapFactory = PokemonMapFactory.new(target_id)
      elsif defined?($MapFactory) && $MapFactory && $MapFactory.respond_to?(:setup)
        $MapFactory.setup(target_id)
      else
        $game_map.setup(target_id) if $game_map.respond_to?(:setup)
      end
      $game_player.moveto(x, y)
      case direction
      when 4 then $game_player.turn_left if $game_player.respond_to?(:turn_left)
      when 6 then $game_player.turn_right if $game_player.respond_to?(:turn_right)
      when 8 then $game_player.turn_up if $game_player.respond_to?(:turn_up)
      else $game_player.turn_down if $game_player.respond_to?(:turn_down)
      end
      $game_player.center($game_player.x, $game_player.y) if $game_player.respond_to?(:center)
      $game_player.straighten if $game_player.respond_to?(:straighten)
      set_current_expansion(owner) if respond_to?(:set_current_expansion)
      return true
    rescue => e
      log("[map] legacy saved map remap failed: #{e.class}: #{e.message}")
      return false
    end

    def direct_map_expansion_entry(map_id)
      target = integer(map_id, 0)
      return nil if target <= 0
      entry = registry(:maps)[target]
      entry ||= dynamic_map_entry(manifest_for_map_id(target), target)
      return entry
    rescue
      return nil
    end

    def direct_map_expansion_id(map_id)
      entry = direct_map_expansion_entry(map_id)
      return nil if !entry
      expansion_id = entry[:expansion_id].to_s
      return nil if expansion_id.empty?
      return expansion_id
    end

    def manifest_map_source_path(manifest, local_id)
      return nil if !manifest || !manifest[:map_source].is_a?(Hash)
      template = manifest[:map_source][:path_template].to_s
      return nil if template.empty?
      begin
        return sprintf(template, local_id)
      rescue
        formatted = template.gsub("%03d", format("%03d", local_id))
        formatted.gsub!("%d", local_id.to_s)
        return formatted
      end
    end

    def dynamic_map_entry(manifest, map_id)
      return nil if !manifest || !manifest[:map_source].is_a?(Hash)
      start_id = integer(manifest[:map_block][:start], 0)
      size = integer(manifest[:map_block][:size], 0)
      target = integer(map_id, 0)
      return nil if start_id <= 0 || size <= 0 || target <= 0
      return nil if target < start_id || target >= start_id + size
      local_id = target - start_id
      return nil if local_id <= 0
      path = manifest_map_source_path(manifest, local_id)
      return nil if path.nil? || path.empty?
      return {
        :id           => "#{manifest[:id]}:map_#{local_id}",
        :expansion_id => manifest[:id],
        :local_id     => local_id,
        :virtual_id   => target,
        :path         => path,
        :name         => "#{manifest[:name]} Map #{local_id}",
        :mod_id       => manifest[:mod_id],
        :loader       => normalize_string(manifest[:map_source][:loader], "marshal_file")
      }
    end

    def expansion_map_entry(map_id)
      return registry(:maps)[map_id] || dynamic_map_entry(manifest_for_map_id(map_id), map_id)
    end

    def expansion_map?(map_id)
      return !expansion_map_entry(map_id).nil?
    end

    def expansion_map_active?(map_id)
      entry = expansion_map_entry(map_id)
      return false if !entry
      return false if !expansion_active?(entry[:expansion_id])
      return runtime_file_exists?(entry[:path])
    end

    def valid_map_id?(map_id)
      return false if integer(map_id, 0) <= 0
      if expansion_map?(map_id)
        return expansion_map_active?(map_id)
      end
      return pbRgssExists?(sprintf("Data/Map%03d.rxdata", map_id)) if defined?(pbRgssExists?)
      return File.file?(sprintf("Data/Map%03d.rxdata", map_id))
    rescue
      return false
    end

    def current_anchor
      return nil if !$game_map || !$game_player
      return {
        :map_id    => $game_map.map_id,
        :x         => $game_player.x,
        :y         => $game_player.y,
        :direction => $game_player.direction
      }
    end

    def unsafe_to_capture_anchor?
      return true if $game_temp && $game_temp.respond_to?(:message_window_showing) && $game_temp.message_window_showing
      interpreter = nil
      interpreter = pbMapInterpreter if defined?(pbMapInterpreter) && pbMapInterpreter
      interpreter ||= ($game_system ? $game_system.map_interpreter : nil)
      return false if !interpreter
      running = interpreter.respond_to?(:running?) ? interpreter.running? : nil
      running = !interpreter.instance_variable_get(:@list).nil? if running.nil?
      return true if running
      return integer(interpreter.instance_variable_get(:@event_id), 0) > 0
    rescue
      return false
    end

    def remember_host_anchor(anchor)
      normalized = normalize_anchor(anchor)
      return if !normalized
      return if current_map_expansion_id(normalized[:map_id])
      ensure_save_root.last_host_anchor = normalized
      if $PokemonGlobal
        $PokemonGlobal.tef_last_host_anchor = normalized
      end
    end

    def store_canonical_location(kind, expansion_id, anchor, reason = "runtime")
      normalized = sanitize_anchor(anchor) || normalize_anchor(anchor)
      return nil if !normalized || integer(normalized[:map_id], 0) <= 0
      save_kind = kind.to_s == "expansion" ? "expansion" : "host"
      expansion = save_kind == "expansion" ? expansion_id.to_s : ""
      if save_kind == "expansion" && expansion_anchor_capture_blocked?(expansion, normalized)
        log("[save] ignored unsafe #{expansion} canonical location #{normalized[:map_id]} for #{reason}") if respond_to?(:log)
        return ensure_save_root.canonical_location
      end
      location = {
        "kind"         => save_kind,
        "expansion_id" => expansion,
        "anchor"       => normalized,
        "updated_at"   => timestamp_string,
        "reason"       => reason.to_s
      }
      ensure_save_root.canonical_location = location
      ensure_save_root.enabled_signature = current_enabled_signature if runtime_bootstrapped?
      return location
    rescue => e
      log("[save] canonical location store failed: #{e.class}: #{e.message}") if respond_to?(:log)
      return nil
    end

    def canonical_location
      return normalize_canonical_location(ensure_save_root.canonical_location)
    rescue
      return nil
    end

    def capture_canonical_location_for_save!(reason = "save")
      root = ensure_save_root
      anchor = current_anchor
      return root if !anchor
      map_id = integer(anchor[:map_id], 0)
      expansion = current_map_expansion_id(map_id)
      if !expansion.to_s.empty? && expansion_active?(expansion)
        save_new_project_party_session!(expansion, reason) if respond_to?(:save_new_project_party_session!)
        set_current_expansion(expansion)
        remember_expansion_anchor(expansion, anchor)
        store_canonical_location("expansion", expansion, anchor, reason)
      else
        restore_all_new_project_host_parties!(reason) if respond_to?(:restore_all_new_project_host_parties!)
        if map_id >= RESERVED_MAP_BLOCK_START
          record_dormant_reference({
            "type"      => "unsafe_player_map_on_save",
            "map_id"    => map_id,
            "marker"    => current_expansion_marker.to_s,
            "timestamp" => timestamp_string
          })
          anchor = default_host_anchor
        end
        clear_current_expansion
        remember_host_anchor(anchor)
        store_canonical_location("host", nil, anchor, reason)
      end
      return root
    rescue => e
      log("[save] canonical location capture failed: #{e.class}: #{e.message}") if respond_to?(:log)
      return ensure_save_root
    end

    def remember_host_anchor_from_current_location
      return if unsafe_to_capture_anchor?
      anchor = current_anchor
      return if !anchor
      remember_host_anchor(anchor)
    end

    def remember_expansion_anchor(expansion_id, anchor)
      expansion = expansion_id.to_s
      return if expansion.empty? || expansion == HOST_EXPANSION_ID
      normalized = sanitize_anchor(anchor)
      return if !normalized
      map_expansion = current_map_expansion_id(normalized[:map_id])
      return if map_expansion.to_s != expansion
      return if expansion_anchor_capture_blocked?(expansion, normalized)
      state_for(expansion).last_anchor = normalized
    end

    def expansion_anchor_capture_blocked?(expansion_id, anchor)
      expansion = expansion_id.to_s
      normalized = sanitize_anchor(anchor)
      return false if expansion.empty? || !normalized
      if expansion == "insurgence" && respond_to?(:insurgence_anchor_capture_blocked?)
        return true if insurgence_anchor_capture_blocked?(normalized)
      end
      if expansion == "reborn" && respond_to?(:reborn_anchor_capture_blocked?)
        return true if reborn_anchor_capture_blocked?(normalized)
      end
      return false
    rescue => e
      log("[save] expansion anchor capture check failed for #{expansion_id}: #{e.class}: #{e.message}") if respond_to?(:log)
      return false
    end

    def remember_expansion_anchor_from_current_location(expansion_id = nil)
      return if unsafe_to_capture_anchor?
      anchor = current_anchor
      return if !anchor
      expansion = expansion_id || current_map_expansion_id(anchor[:map_id])
      return if expansion.nil? || expansion.to_s.empty?
      remember_expansion_anchor(expansion, anchor)
    end

    def last_expansion_anchor(expansion_id)
      expansion = expansion_id.to_s
      return nil if expansion.empty? || expansion == HOST_EXPANSION_ID
      location = canonical_location
      anchor = nil
      anchor = location["anchor"] if location &&
                                     location["kind"].to_s == "expansion" &&
                                     location["expansion_id"].to_s == expansion
      anchor ||= state_for(expansion).last_anchor
      return nil if !anchor
      normalized = sanitize_anchor(anchor)
      return nil if !normalized
      map_expansion = current_map_expansion_id(normalized[:map_id])
      return nil if map_expansion.to_s != expansion
      return nil if expansion_anchor_capture_blocked?(expansion, normalized)
      return normalized
    end

    def default_host_anchor
      candidate = nil
      candidate = normalize_anchor(ensure_save_root.last_good_host_anchor) if ensure_save_root.respond_to?(:last_good_host_anchor)
      candidate ||= normalize_anchor($PokemonGlobal.tef_last_host_anchor) if $PokemonGlobal && $PokemonGlobal.respond_to?(:tef_last_host_anchor)
      candidate ||= normalize_anchor(ensure_save_root.last_host_anchor)
      if candidate && valid_map_id?(candidate[:map_id])
        return sanitize_anchor(candidate)
      end
      if $PokemonGlobal && $PokemonGlobal.respond_to?(:pokecenterMapId) && valid_map_id?($PokemonGlobal.pokecenterMapId)
        return sanitize_anchor({
          :map_id    => $PokemonGlobal.pokecenterMapId,
          :x         => $PokemonGlobal.pokecenterX,
          :y         => $PokemonGlobal.pokecenterY,
          :direction => $PokemonGlobal.pokecenterDirection
        })
      end
      if defined?($data_system) && $data_system
        return sanitize_anchor({
          :map_id    => $data_system.start_map_id,
          :x         => $data_system.start_x,
          :y         => $data_system.start_y,
          :direction => 2
        })
      end
      return { :map_id => 1, :x => 0, :y => 0, :direction => 2 }
    end

    def sanitize_anchor(anchor)
      normalized = normalize_anchor(anchor)
      return nil if !normalized
      dims = MapFactoryHelper.getMapDims(normalized[:map_id]) rescue [0, 0]
      if dims && dims[0].to_i > 0 && dims[1].to_i > 0
        normalized[:x] = [[normalized[:x], 0].max, dims[0] - 1].min
        normalized[:y] = [[normalized[:y], 0].max, dims[1] - 1].min
      end
      normalized[:direction] = 2 if ![2, 4, 6, 8].include?(normalized[:direction])
      return normalized
    end

    def record_dormant_reference(reference)
      return if !reference.is_a?(Hash)
      root = ensure_save_root
      root.dormant_references ||= []
      comparable = reference.reject { |key, _value| key.to_s == "timestamp" || key.to_s == "updated_at" }
      duplicate = root.dormant_references.any? do |entry|
        next false if !entry.is_a?(Hash)
        entry.reject { |key, _value| key.to_s == "timestamp" || key.to_s == "updated_at" } == comparable
      end
      return if duplicate
      root.dormant_references << reference
      root.dormant_references.shift while root.dormant_references.length > 500
    end

    def remember_last_good_anchor(kind, expansion_id, anchor)
      normalized = sanitize_anchor(anchor) || normalize_anchor(anchor)
      return nil if !normalized || integer(normalized[:map_id], 0) <= 0
      root = ensure_save_root
      if kind.to_s == "expansion"
        expansion = expansion_id.to_s
        return nil if expansion.empty?
        state_for(expansion).last_good_anchor = normalized if state_for(expansion).respond_to?(:last_good_anchor=)
        root.last_good_expansion_anchors ||= {}
        root.last_good_expansion_anchors[expansion] = normalized
      else
        root.last_good_host_anchor = normalized if root.respond_to?(:last_good_host_anchor=)
        root.last_host_anchor = normalized
      end
      return normalized
    rescue => e
      log("[travel] failed to remember last good anchor: #{e.class}: #{e.message}") if respond_to?(:log)
      return nil
    end

    def transition_record(source, expansion_id, from_anchor, to_anchor, ok, error = nil)
      {
        "source"       => source.to_s,
        "expansion_id" => expansion_id.to_s,
        "from"         => normalize_anchor(from_anchor),
        "to"           => normalize_anchor(to_anchor),
        "ok"           => ok ? true : false,
        "error"        => error.to_s,
        "timestamp"    => timestamp_string
      }
    rescue
      {
        "source"    => source.to_s,
        "ok"        => ok ? true : false,
        "error"     => error.to_s,
        "timestamp" => timestamp_string
      }
    end

    def record_completed_transition(source, expansion_id, from_anchor, to_anchor)
      record = transition_record(source, expansion_id, from_anchor, to_anchor, true)
      root = ensure_save_root
      root.last_completed_transition = record if root.respond_to?(:last_completed_transition=)
      target_expansion = expansion_id.to_s
      target_anchor = normalize_anchor(record["to"])
      if target_anchor.nil? || target_expansion.empty? || target_expansion == HOST_EXPANSION_ID || !current_map_expansion_id(target_anchor[:map_id])
        remember_last_good_anchor("host", nil, target_anchor) if target_anchor
      else
        remember_last_good_anchor("expansion", target_expansion, target_anchor)
      end
      return record
    rescue => e
      log("[travel] failed to record completed transition: #{e.class}: #{e.message}") if respond_to?(:log)
      return nil
    end

    def record_failed_transition(source, expansion_id, from_anchor, to_anchor, error)
      record = transition_record(source, expansion_id, from_anchor, to_anchor, false, error)
      root = ensure_save_root
      root.failed_transition_log ||= []
      root.failed_transition_log << record
      root.failed_transition_log.shift while root.failed_transition_log.length > 100
      record_dormant_reference({
        "type"         => "failed_transition",
        "source"       => source.to_s,
        "expansion_id" => expansion_id.to_s,
        "from"         => normalize_anchor(from_anchor),
        "to"           => normalize_anchor(to_anchor),
        "error"        => error.to_s,
        "timestamp"    => timestamp_string
      })
      log("[travel] failed #{source} transfer to #{to_anchor.inspect}: #{error}") if respond_to?(:log)
      return record
    rescue => e
      log("[travel] failed to record transition failure: #{e.class}: #{e.message}") if respond_to?(:log)
      return nil
    end

    def current_expansion_marker
      if $PokemonGlobal && $PokemonGlobal.respond_to?(:tef_current_expansion_id) && !$PokemonGlobal.tef_current_expansion_id.to_s.empty?
        return $PokemonGlobal.tef_current_expansion_id.to_s
      end
      return nil
    end

    def current_expansion_id
      marker = current_expansion_marker
      return marker if !marker.to_s.empty?
      return current_map_expansion_id
    end

    def set_current_expansion(expansion_id)
      return if !$PokemonGlobal
      $PokemonGlobal.tef_current_expansion_id = expansion_id ? expansion_id.to_s : nil
    end

    def clear_current_expansion
      return if !$PokemonGlobal
      $PokemonGlobal.tef_current_expansion_id = nil
    end

    def update_current_expansion_from_map
      expansion_id = current_map_expansion_id
      if expansion_id
        set_current_expansion(expansion_id)
        remember_expansion_anchor_from_current_location(expansion_id)
        store_canonical_location("expansion", expansion_id, current_anchor, "map_change") if current_anchor && !unsafe_to_capture_anchor?
      else
        clear_current_expansion
        remember_host_anchor_from_current_location
        store_canonical_location("host", nil, current_anchor, "map_change") if current_anchor && !unsafe_to_capture_anchor?
      end
    end

    def record_dex_progress(species, owned = false, expansion_id = nil)
      record_host_dex_progress(species, owned)
      expansion_id ||= current_expansion_id
      return if expansion_id.nil? || expansion_id.to_s.empty? || expansion_id.to_s == HOST_EXPANSION_ID
      dex_state = dex_state_for(expansion_id)
      return if !dex_state
      species_id = dex_species_key(species)
      return if species_id.to_s.empty?
      dex_state["seen"][species_id] = true
      dex_state["owned"][species_id] = true if owned
    rescue => e
      log("Dex progress update failed for #{expansion_id}: #{e.message}")
    end

    def next_map_block_start(requested_size = RESERVED_MAP_BLOCK_SIZE)
      size = [integer(requested_size, RESERVED_MAP_BLOCK_SIZE), RESERVED_MAP_BLOCK_SIZE].max
      start = @map_block_cursor
      loop do
        conflict = fixed_external_map_block_ranges.find do |range|
          map_block_ranges_overlap?(start, size, range[:start], range[:size])
        end
        break if !conflict
        start = conflict[:end]
      end
      @map_block_cursor = start + size
      return start
    end

    def reserve_map_block!(start_id, size)
      start_value = integer(start_id, RESERVED_MAP_BLOCK_START)
      size_value = [integer(size, RESERVED_MAP_BLOCK_SIZE), 1].max
      end_value = start_value + size_value
      aligned_end = ((end_value + RESERVED_MAP_BLOCK_SIZE - 1) / RESERVED_MAP_BLOCK_SIZE) * RESERVED_MAP_BLOCK_SIZE
      @map_block_cursor = [@map_block_cursor, aligned_end].max
    end

    def fixed_external_map_block_start(expansion_id)
      fixed = FIXED_EXTERNAL_MAP_BLOCK_STARTS[expansion_id.to_s]
      return integer(fixed, 0)
    rescue
      return 0
    end

    def fixed_external_map_block_ranges
      FIXED_EXTERNAL_MAP_BLOCK_STARTS.map do |_expansion_id, start_id|
        start_value = integer(start_id, 0)
        size_value = RESERVED_MAP_BLOCK_SIZE
        {
          :start => start_value,
          :size  => size_value,
          :end   => start_value + size_value
        }
      end
    rescue
      return []
    end

    def map_block_ranges_overlap?(left_start, left_size, right_start, right_size)
      left_start = integer(left_start, 0)
      left_size = integer(left_size, 0)
      right_start = integer(right_start, 0)
      right_size = integer(right_size, 0)
      return false if left_size <= 0 || right_size <= 0
      left_end = left_start + left_size
      right_end = right_start + right_size
      return left_start < right_end && left_end > right_start
    rescue
      return false
    end
  end

  class PokemonGlobalMetadata
    attr_accessor :tef_current_expansion_id
    attr_accessor :tef_last_host_anchor
    attr_accessor :tef_missing_expansion_warnings
  end

  Events.onMapChange += proc { |_sender, *_args|
    TravelExpansionFramework.update_current_expansion_from_map if defined?(TravelExpansionFramework)
  }

  SaveData.register(:travel_expansion_root) do
    optional
    save_value { TravelExpansionFramework.capture_canonical_location_for_save!("save") }
    load_value { |value| TravelExpansionFramework.load_save_root(value) }
    new_game_value { TravelExpansionFramework::SaveRoot.new }
  end
end
