#==============================================================================
# Mod Manager — Data Layer
#
# ModInfo class, registry, state management, dependency resolution,
# version comparison, settings I/O.
#==============================================================================


module ModManager
  # Lightweight JSON parser/serializer (isolated from other mods)
  module JSON
    module_function

    def dump(obj, indent = 0)
      case obj
      when Hash
        return "{}" if obj.empty?
        parts = []
        space = "  " * (indent + 1)
        obj.each_pair do |k, v|
          parts << "\n" + space + '"' + esc(k.to_s) + '": ' + dump(v, indent + 1)
        end
        '{' + parts.join(',') + "\n" + ("  " * indent) + '}'
      when Array
        return "[]" if obj.empty?
        if obj.all? { |v| v.is_a?(String) || v.is_a?(Numeric) } && obj.length < 5
          '[' + obj.map { |v| dump(v, indent + 1) }.join(', ') + ']'
        else
          space = "  " * (indent + 1)
          parts = obj.map { |v| "\n" + space + dump(v, indent + 1) }
          '[' + parts.join(',') + "\n" + ("  " * indent) + ']'
        end
      when String
        '"' + esc(obj) + '"'
      when Integer, Float
        obj.to_s
      when TrueClass
        'true'
      when FalseClass
        'false'
      when NilClass
        'null'
      else
        '"' + esc(obj.to_s) + '"'
      end
    end

    def parse(str)
      @s = str.to_s
      @i = 0
      val = read_value
      skip_ws
      val
    end

    def esc(s)
      s.to_s.gsub(/["\\\b\f\r\t\n]/) do |m|
        case m
        when '"' then "\\\""
        when "\\" then "\\\\"
        when "\b" then "\\b"
        when "\f" then "\\f"
        when "\r" then "\\r"
        when "\t" then "\\t"
        when "\n" then "\\n"
        else m
        end
      end
    end

    def skip_ws
      @i += 1 while @i < @s.length && @s[@i] =~ /\s/
    end

    def read_value
      skip_ws
      return nil if @i >= @s.length
      ch = @s[@i,1]
      case ch
      when '{' then read_object
      when '[' then read_array
      when '"' then read_string
      when 't' then read_true
      when 'f' then read_false
      when 'n' then read_null
      else          read_number
      end
    end

    def read_object
      obj = {}
      @i += 1
      skip_ws
      return obj if @s[@i,1] == '}' && (@i += 1)
      loop do
        key = read_string
        skip_ws
        @i += 1 if @s[@i,1] == ':'
        val = read_value
        obj[key] = val
        skip_ws
        if @s[@i,1] == '}'
          @i += 1
          break
        end
        @i += 1 if @s[@i,1] == ','
        skip_ws
      end
      obj
    end

    def read_array
      arr = []
      @i += 1
      skip_ws
      return arr if @s[@i,1] == ']' && (@i += 1)
      loop do
        arr << read_value
        skip_ws
        if @s[@i,1] == ']'
          @i += 1
          break
        end
        @i += 1 if @s[@i,1] == ','
        skip_ws
      end
      arr
    end

    def read_string
      out = ''
      @i += 1
      while @i < @s.length
        ch = @s[@i,1]
        @i += 1
        if ch == '"'
          break
        elsif ch == '\\'
          esc = @s[@i,1]; @i += 1
          case esc
          when '"';  out << '"'
          when '\\'; out << '\\'
          when '/';  out << '/'
          when 'b';  out << "\b"
          when 'f';  out << "\f"
          when 'n';  out << "\n"
          when 'r';  out << "\r"
          when 't';  out << "\t"
          when 'u'
            hex = @s[@i, 4].to_s; @i += 4
            begin; out << [hex.to_i(16)].pack('U'); rescue; out << 'u' << hex; end
          else        out << esc.to_s
          end
        else
          out << ch
        end
      end
      out
    end

    def read_true;  @i += 4; true;  end
    def read_false; @i += 5; false; end
    def read_null;  @i += 4; nil;   end

    def read_number
      start_pos = @i
      @i += 1 while @i < @s.length && @s[@i,1] =~ /[-+0-9.eE]/
      num = @s[start_pos...@i]
      if num.include?('.') || num.include?('e') || num.include?('E')
        num.to_f
      else
        begin; Integer(num); rescue; 0; end
      end
    end
  end
  MOD_DIR    = File.expand_path("./Mods")
  MODDEV_DIR = File.expand_path("./ModDev")
  STATE_FILE = File.expand_path("./Mods/mod_manager_state.json")

  VALID_TAGS = [
    "Gameplay", "Visual", "Audio", "QoL", "Balance", "Difficulty",
    "Fusion", "Multiplayer", "UI", "Cosmetic", "Bug Fix", "Content"
  ]

  # Internal state
  @@registry   = {}   # mod_id => ModInfo
  @@state      = {}   # mod_id => { "enabled" => bool }
  @@load_order = []   # sorted mod_id array
  @@moddev_override = false
  @@initialized = false

  #============================================================================
  # ModInfo — parsed representation of a mod.json
  #============================================================================
  class ModInfo
    attr_accessor :id, :name, :version, :author, :description,
                  :tags, :dependencies, :incompatible, :settings_defs,
                  :scripts, :icon_path, :folder_path

    def initialize
      @id            = ""
      @name          = "Unknown"
      @version       = "1.0.0"
      @author        = "Unknown"
      @description   = ""
      @tags          = []
      @dependencies  = []   # [{id:, min_version:}]
      @incompatible  = []   # [mod_id, ...]
      @settings_defs = []   # [{key:, type:, label:, ...}]
      @scripts       = []   # ["main.rb", ...]
      @icon_path     = nil
      @folder_path   = ""
    end

    def is_dev?
      @folder_path && @folder_path.include?("/ModDev/")
    end

    def self.from_hash(hash, folder_path)
      info = ModInfo.new
      info.folder_path = folder_path
      info.id          = hash["id"].to_s
      info.name        = hash["name"].to_s
      info.version     = hash["version"].to_s
      info.author      = hash["author"].to_s
      
      desc = hash["description"]
      if desc.is_a?(Array)
        info.description = desc.join("\n")
      else
        info.description = desc.to_s
      end

      # Tags
      if hash["tags"].is_a?(Array)
        info.tags = hash["tags"].map { |t| t.to_s }
      end

      # Dependencies
      if hash["dependencies"].is_a?(Array)
        info.dependencies = hash["dependencies"].map do |dep|
          if dep.is_a?(Hash)
            { "id" => dep["id"].to_s, "min_version" => (dep["min_version"] || "0").to_s }
          else
            { "id" => dep.to_s, "min_version" => "0" }
          end
        end
      end

      # Incompatibilities
      if hash["incompatible"].is_a?(Array)
        info.incompatible = hash["incompatible"].map { |i| i.to_s }
      end

      # Settings definitions
      if hash["settings"].is_a?(Array)
        info.settings_defs = hash["settings"].select { |s| s.is_a?(Hash) }
      end

      # Scripts
      if hash["scripts"].is_a?(Array)
        info.scripts = hash["scripts"].map { |s| s.to_s }
      else
        # Default: load all .rb files in folder sorted alphabetically
        info.scripts = Dir["#{folder_path}/*.rb"].map { |f| File.basename(f) }.sort
      end

      # Icon
      icon_file = hash["icon"].to_s
      icon_file = "icon.png" if icon_file.empty?
      full_icon = File.join(folder_path, icon_file)
      info.icon_path = full_icon if File.exist?(full_icon)

      info
    end

    def has_icon?
      @icon_path && File.exist?(@icon_path)
    end

    def incompatible_with?(other_id)
      @incompatible.include?(other_id)
    end

    def settings_file
      File.join(@folder_path, "settings.json")
    end
  end

  #============================================================================
  # Registry scanning
  #============================================================================
  def self.scan_mods
    @@registry.clear
    return unless File.directory?(MOD_DIR)

    # 1. Identify folder names in ModDev/ for override
    dev_folders = []
    if moddev_override? && File.directory?(MODDEV_DIR)
      dev_folders = Dir.entries(MODDEV_DIR).select do |f|
        File.directory?(File.join(MODDEV_DIR, f)) && !['.', '..'].include?(f)
      end
    end

    # 2. Scan regular Mods/ folder (skipping those overridden by folder name)
    Dir["#{MOD_DIR}/*/mod.json"].each do |json_path|
      folder_path = File.dirname(json_path)
      folder_name = File.basename(folder_path)
      next if dev_folders.include?(folder_name)

      begin
        raw = File.read(json_path)
        hash = ModManager::JSON.parse(raw)
        next unless hash.is_a?(Hash) && hash["id"]
        info = ModInfo.from_hash(hash, folder_path)
        next if info.id.empty?
        @@registry[info.id] = info
      rescue => e
        echoln("[ModManager] Error loading #{json_path}: #{e.message}")
      end
    end

    # 3. Scan ModDev/ folder
    if moddev_override? && File.directory?(MODDEV_DIR)
      _scan_directory(MODDEV_DIR)
    end

    @@initialized = true
  end

  def self._scan_directory(dir)
    Dir["#{dir}/*/mod.json"].each do |json_path|
      begin
        folder = File.dirname(json_path)
        raw = File.read(json_path)
        hash = ModManager::JSON.parse(raw)
        next unless hash.is_a?(Hash) && hash["id"]

        info = ModInfo.from_hash(hash, folder)
        next if info.id.empty?

        # This will overwrite if the same ID was already found (e.g. from Mods/)
        @@registry[info.id] = info
      rescue => e
        echoln("[ModManager] Error loading #{json_path}: #{e.message}")
      end
    end
  end

  #============================================================================
  # State persistence (enabled/disabled)
  #============================================================================
  def self.load_state
    if File.exist?(STATE_FILE)
      begin
        raw = File.read(STATE_FILE)
        parsed = ModManager::JSON.parse(raw)
        if parsed.is_a?(Hash)
          @@state = parsed["mods"] if parsed["mods"].is_a?(Hash)
          @@moddev_override = !!parsed["moddev_override"]
        end
      rescue => e
        echoln("[ModManager] Error loading state: #{e.message}")
        @@state = {}
      end
    end
    # Ensure every registered mod has a state entry (default: enabled)
    @@registry.each_key do |mod_id|
      unless @@state[mod_id].is_a?(Hash)
        @@state[mod_id] = { "enabled" => true }
      end
    end
  end

  def self.save_state
    begin
      data = {
        "mods" => @@state,
        "moddev_override" => @@moddev_override
      }
      File.open(STATE_FILE, "w") { |f| f.write(ModManager::JSON.dump(data)) }
    rescue => e
      echoln("[ModManager] Error saving state: #{e.message}")
    end
  end

  #============================================================================
  # Accessors
  #============================================================================
  def self.registry
    @@registry
  end

  def self.state
    @@state
  end

  def self.load_order
    @@load_order
  end

  def self.initialized?
    @@initialized
  end

  def self.moddev_override?
    @@moddev_override
  end

  def self.toggle_moddev_override
    @@moddev_override = !@@moddev_override
    save_state
    refresh
  end

  def self.enabled?(mod_id)
    return true unless @@state[mod_id].is_a?(Hash)
    @@state[mod_id]["enabled"] != false
  end

  def self.toggle(mod_id)
    @@state[mod_id] ||= {}
    @@state[mod_id]["enabled"] = !enabled?(mod_id)
    save_state
  end

  def self.get_mod(mod_id)
    @@registry[mod_id]
  end

  def self.mod_count
    @@registry.length
  end

  def self.enabled_mods
    @@registry.keys.select { |id| enabled?(id) }
  end

  def self.loose_count
    loose_mods.length
  end

  def self.loose_mods
    return [] unless File.directory?(MOD_DIR)
    Dir["#{MOD_DIR}/*.rb"].map { |f| File.basename(f) }.select do |fn|
      !fn.start_with?("000_") && fn != "compat.rb"
    end.sort
  end

  #============================================================================
  # Asset installation — copies Graphics/, Audio/, etc. to game root
  #============================================================================
  ASSET_DIRS = ["Graphics", "Audio", "Data", "Fonts"]

  # Copy asset folders from a mod into the game root and save a manifest
  def self.install_assets(mod_id)
    info = @@registry[mod_id]
    mod_folder = info ? info.folder_path : File.join(MOD_DIR, mod_id)
    return unless File.directory?(mod_folder)

    game_root = File.expand_path(".")
    manifest = []

    ASSET_DIRS.each do |asset_dir|
      src = File.join(mod_folder, asset_dir)
      next unless File.directory?(src)

      # Recursively copy all files
      _collect_files(src).each do |src_file|
        rel = src_file.sub(mod_folder + "/", "").sub(mod_folder + "\\", "")
        dest = File.join(game_root, rel)
        dest_dir = File.dirname(dest)

        # Create destination directories
        _ensure_dir(dest_dir)

        # Copy file
        begin
          File.open(dest, "wb") { |f| f.write(File.binread(src_file)) }
          manifest << rel
        rescue => e
          echoln("[ModManager] Failed to copy #{rel}: #{e.message}")
        end
      end
    end

    # Save manifest so we know what to clean up on uninstall
    if manifest.length > 0
      manifest_path = File.join(mod_folder, ".installed_assets")
      File.open(manifest_path, "w") { |f| f.puts manifest.join("\n") }
      echoln("[ModManager] Installed #{manifest.length} asset file(s) for #{mod_id}")
    end
  end

  # Remove previously installed asset files using the manifest
  def self.uninstall_assets(mod_id)
    info = @@registry[mod_id]
    mod_folder = info ? info.folder_path : File.join(MOD_DIR, mod_id)
    manifest_path = File.join(mod_folder, ".installed_assets")
    return unless File.exist?(manifest_path)

    game_root = File.expand_path(".")
    lines = File.read(manifest_path).split("\n").map(&:strip).reject(&:empty?)

    lines.each do |rel|
      dest = File.join(game_root, rel)
      File.delete(dest) rescue nil
    end

    # Clean up empty directories left behind
    lines.map { |rel| File.dirname(File.join(game_root, rel)) }
         .uniq.sort.reverse.each do |dir|
      Dir.rmdir(dir) rescue nil if File.directory?(dir) && (Dir.entries(dir) - [".", ".."]).empty?
    end

    echoln("[ModManager] Removed #{lines.length} asset file(s) for #{mod_id}")
  end

  def self._collect_files(dir)
    files = []
    Dir["#{dir}/**/*"].each do |entry|
      files << entry unless File.directory?(entry)
    end
    files
  end

  def self._ensure_dir(path)
    parts = []
    current = path
    while !File.directory?(current)
      parts.unshift(current)
      current = File.dirname(current)
    end
    parts.each { |p| Dir.mkdir(p) rescue nil }
  end

  #============================================================================
  # Uninstall
  #============================================================================
  def self.uninstall(mod_id)
    info = @@registry[mod_id]
    return false unless info

    # Remove copied asset files first
    uninstall_assets(mod_id)

    # Delete mod folder
    folder = info.folder_path
    if File.directory?(folder)
      begin
        _delete_folder(folder)
      rescue => e
        echoln("[ModManager] Error deleting #{folder}: #{e.message}")
        return false
      end
    end

    @@registry.delete(mod_id)
    @@state.delete(mod_id)
    save_state
    true
  end

  def self._delete_folder(path)
    Dir["#{path}/**/*"].sort.reverse.each do |entry|
      if File.directory?(entry)
        Dir.rmdir(entry) rescue nil
      else
        File.delete(entry) rescue nil
      end
    end
    Dir.rmdir(path) rescue nil
  end

  #============================================================================
  # Dependency checking
  #============================================================================
  def self.check_dependencies(mod_id)
    info = @@registry[mod_id]
    return [] unless info

    results = []
    info.dependencies.each do |dep|
      dep_id = dep["id"]
      dep_ver = dep["min_version"] || "0"
      dep_mod = @@registry[dep_id]

      if dep_mod.nil?
        results << { "id" => dep_id, "required" => dep_ver, "status" => "missing" }
      elsif compare_versions(dep_mod.version, dep_ver) < 0
        results << { "id" => dep_id, "required" => dep_ver, "installed" => dep_mod.version, "status" => "version_mismatch" }
      else
        results << { "id" => dep_id, "required" => dep_ver, "installed" => dep_mod.version, "status" => "ok" }
      end
    end
    results
  end

  def self.check_incompatibilities(mod_id)
    info = @@registry[mod_id]
    return [] unless info

    conflicts = []
    # Check this mod's declared incompatibilities
    info.incompatible.each do |other_id|
      conflicts << other_id if @@registry[other_id] && enabled?(other_id)
    end
    # Check if other mods declare incompatibility with this one
    @@registry.each do |other_id, other_info|
      next if other_id == mod_id
      if other_info.incompatible_with?(mod_id) && enabled?(other_id)
        conflicts << other_id unless conflicts.include?(other_id)
      end
    end
    conflicts
  end

  #============================================================================
  # Version comparison (delegates to PluginManager)
  #============================================================================
  def self.compare_versions(v1, v2)
    if defined?(PluginManager) && PluginManager.respond_to?(:compare_versions)
      PluginManager.compare_versions(v1, v2)
    else
      # Fallback: simple numeric comparison
      a = v1.to_s.split(".").map(&:to_i)
      b = v2.to_s.split(".").map(&:to_i)
      max = [a.length, b.length].max
      max.times do |i|
        c = (a[i] || 0) <=> (b[i] || 0)
        return c if c != 0
      end
      0
    end
  end

  #============================================================================
  # Topological sort (Kahn's algorithm)
  #============================================================================
  def self.compute_load_order
    enabled = enabled_mods
    return [] if enabled.empty?

    # Build adjacency: if mod A depends on mod B, edge B -> A (B loads before A)
    in_degree = {}
    adj = {}
    enabled.each do |id|
      in_degree[id] = 0
      adj[id] = []
    end

    enabled.each do |id|
      info = @@registry[id]
      next unless info
      info.dependencies.each do |dep|
        dep_id = dep["id"]
        next unless enabled.include?(dep_id) # skip deps not in enabled set
        adj[dep_id] << id
        in_degree[id] += 1
      end
    end

    # Kahn's BFS
    queue = enabled.select { |id| in_degree[id] == 0 }
    result = []

    until queue.empty?
      # Sort by folder name (basename) to respect alphabetical loading for independent mods
      queue.sort_by! { |id| File.basename(@@registry[id].folder_path).downcase }
      node = queue.shift
      result << node
      
      adj[node].each do |neighbor|
        in_degree[neighbor] -= 1
        queue << neighbor if in_degree[neighbor] == 0
      end
    end

    if result.length < enabled.length
      missing = enabled - result
      echoln("[ModManager] WARNING: Circular dependency detected! Mods not loaded: #{missing.join(', ')}")
      # Append them anyway so they at least attempt to load (sorted by folder name)
      result.concat(missing.sort_by { |id| File.basename(@@registry[id].folder_path).downcase })
    end

    @@load_order = result
  end

  #============================================================================
  # Per-mod settings
  #============================================================================
  def self.load_mod_settings(mod_id)
    info = @@registry[mod_id]
    return {} unless info

    settings = {}
    # Start with defaults from settings_defs
    info.settings_defs.each do |sd|
      settings[sd["key"]] = sd["default"] if sd["key"]
    end

    # Override with saved values
    sf = info.settings_file
    if File.exist?(sf)
      begin
        raw = File.read(sf)
        saved = ModManager::JSON.parse(raw)
        if saved.is_a?(Hash)
          saved.each { |k, v| settings[k] = v }
        end
      rescue => e
        echoln("[ModManager] Error loading settings for #{mod_id}: #{e.message}")
      end
    end

    settings
  end

  def self.save_mod_settings(mod_id, settings_hash)
    info = @@registry[mod_id]
    return unless info
    begin
      File.open(info.settings_file, "w") { |f| f.write(ModManager::JSON.dump(settings_hash)) }
    rescue => e
      echoln("[ModManager] Error saving settings for #{mod_id}: #{e.message}")
    end
  end

  #============================================================================
  # Initialization
  #============================================================================
  def self.init
    return if @@initialized
    load_state        # 1. Load toggle state first
    scan_mods         # 2. Scan (now respects the toggle)
    compute_load_order # 3. Finalize load order
    @@initialized = true
  end

  # Force re-scan (after install/uninstall)
  def self.refresh
    @@initialized = false
    init
  end

  #============================================================================
  # ModpackInfo — parsed representation of a modpack.json
  #============================================================================
  class ModpackInfo
    attr_accessor :id, :name, :version, :author, :description,
                  :tags, :mods, :icon_path, :folder_path

    def initialize
      @id          = ""
      @name        = "Unknown"
      @version     = "1.0.0"
      @author      = "Unknown"
      @description = ""
      @tags        = []
      @mods        = []   # [{ "id" => "mod_a", "version" => "1.0.0" }, ...]
      @icon_path   = nil
      @folder_path = ""
    end

    def self.from_hash(hash, folder_path = "")
      info = ModpackInfo.new
      info.folder_path = folder_path
      info.id          = hash["id"].to_s
      info.name        = hash["name"].to_s
      info.version     = hash["version"].to_s
      info.author      = hash["author"].to_s
      info.description = hash["description"].to_s

      if hash["tags"].is_a?(Array)
        info.tags = hash["tags"].map { |t| t.to_s }
      end

      if hash["mods"].is_a?(Array)
        info.mods = hash["mods"].map do |m|
          if m.is_a?(Hash)
            { "id" => m["id"].to_s, "version" => (m["version"] || "").to_s }
          else
            { "id" => m.to_s, "version" => "" }
          end
        end
      end

      # Icon
      if folder_path && !folder_path.empty?
        icon_file = hash["icon"].to_s
        icon_file = "icon.png" if icon_file.empty?
        full_icon = File.join(folder_path, icon_file)
        info.icon_path = full_icon if File.exist?(full_icon)
      end

      info
    end

    def has_icon?
      @icon_path && File.exist?(@icon_path)
    end

    def mod_count
      @mods.length
    end
  end

  #============================================================================
  # Share Code — encode/decode mod lists as compact strings
  #
  # Format: KIF-<base62(zlib(payload))>
  # Payload: "mod_id@version,mod_id@version,..." (sorted alphabetically)
  # Fallback (no Zlib): KIFr-<base62(raw_payload_bytes)>
  #============================================================================
  BASE62_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

  def self.base62_encode(bytes)
    return "" if bytes.nil? || bytes.empty?
    # Convert byte array to a big integer
    num = 0
    bytes.each { |b| num = num * 256 + (b & 0xFF) }
    return BASE62_CHARS[0, 1] if num == 0
    result = ""
    while num > 0
      result = BASE62_CHARS[num % 62, 1] + result
      num /= 62
    end
    # Preserve leading zero bytes
    leading_zeros = 0
    bytes.each { |b| break if b != 0; leading_zeros += 1 }
    (BASE62_CHARS[0, 1] * leading_zeros) + result
  end

  def self.base62_decode(str)
    return [] if str.nil? || str.empty?
    # Count leading '0' chars (represent leading zero bytes)
    leading_zeros = 0
    str.each_char { |c| break if c != BASE62_CHARS[0, 1]; leading_zeros += 1 }
    # Convert base62 string to big integer
    num = 0
    str.each_char do |c|
      idx = BASE62_CHARS.index(c)
      return nil unless idx  # invalid character
      num = num * 62 + idx
    end
    # Convert big integer to byte array
    bytes = []
    while num > 0
      bytes.unshift(num & 0xFF)
      num >>= 8
    end
    ([0] * leading_zeros) + bytes
  end

  # Encode a list of mods into a share code string
  # mod_entries: [{ "id" => "mod_a", "version" => "1.0.0" }, ...]
  def self.encode_share_code(mod_entries)
    return nil if mod_entries.nil? || mod_entries.empty?
    payload = mod_entries
      .sort_by { |e| e["id"].to_s }
      .map { |e| "#{e["id"]}@#{e["version"]}" }
      .join(",")
    begin
      compressed = Zlib::Deflate.deflate(payload, 9)
      "KIF-" + base62_encode(compressed.bytes.to_a)
    rescue
      # Zlib unavailable — raw encoding (longer codes)
      "KIFr-" + base62_encode(payload.bytes.to_a)
    end
  end

  # Decode a share code string back into a mod list
  # Returns: [{ "id" => "mod_a", "version" => "1.0.0" }, ...] or nil on failure
  def self.decode_share_code(code)
    return nil unless code.is_a?(String)
    code = code.strip
    if code.start_with?("KIF-")
      encoded = code[4..-1]
      bytes = base62_decode(encoded)
      return nil unless bytes
      begin
        raw = Zlib::Inflate.inflate(bytes.pack("C*"))
      rescue
        return nil
      end
    elsif code.start_with?("KIFr-")
      encoded = code[5..-1]
      bytes = base62_decode(encoded)
      return nil unless bytes
      raw = bytes.pack("C*")
    else
      return nil
    end
    # Parse "mod_id@version,mod_id@version,..."
    entries = []
    raw.split(",").each do |part|
      parts = part.split("@", 2)
      next if parts[0].nil? || parts[0].empty?
      entries << { "id" => parts[0], "version" => (parts[1] || "") }
    end
    entries.empty? ? nil : entries
  end

  #============================================================================
  # Dependency auto-resolution — recursively find all deps to install
  #============================================================================
  # Returns { "to_install" => [mod_ids], "missing" => [dep_ids_not_found] }
  def self.resolve_all_dependencies(mod_id, visited = {})
    return { "to_install" => [], "missing" => [] } if visited[mod_id]
    visited[mod_id] = true

    to_install = []
    missing = []

    # Get dependency list from local registry or remote
    info = get_mod(mod_id)
    deps = info ? info.dependencies : []

    # If not installed locally, try remote
    if deps.empty? && !info
      begin
        remote_json = GitHub.fetch_mod_json(mod_id)
        if remote_json && remote_json["dependencies"].is_a?(Array)
          deps = remote_json["dependencies"].map do |d|
            if d.is_a?(Hash)
              { "id" => d["id"].to_s, "min_version" => (d["min_version"] || "0").to_s }
            else
              { "id" => d.to_s, "min_version" => "0" }
            end
          end
        end
      rescue
        # Can't fetch remote deps — skip
      end
    end

    deps.each do |dep|
      dep_id = dep["id"]
      dep_ver = dep["min_version"] || "0"
      dep_mod = get_mod(dep_id)

      if dep_mod
        # Installed — check if version is sufficient
        if compare_versions(dep_mod.version, dep_ver) < 0
          to_install << dep_id  # needs update
        end
      else
        # Not installed — check if available in repo
        begin
          remote_json = GitHub.fetch_mod_json(dep_id)
          if remote_json
            to_install << dep_id
          else
            missing << dep_id
          end
        rescue
          missing << dep_id
        end
      end

      # Recurse into this dependency's deps
      sub = resolve_all_dependencies(dep_id, visited)
      to_install.concat(sub["to_install"])
      missing.concat(sub["missing"])
    end

    { "to_install" => to_install.uniq, "missing" => missing.uniq }
  end

  #============================================================================
  # Clipboard helpers (uses MKXP-Z Input.clipboard)
  #============================================================================
  def self.clipboard_write(text)
    Input.clipboard = text
    true
  rescue
    false
  end

  def self.clipboard_read
    Input.clipboard
  rescue
    nil
  end
end
