module TravelExpansionFramework
  module_function

  TOWN_MAP_DATA_FILENAMES = [
    "town_map.dat",
    "townmap.dat",
    "TownMap.rxdata",
    "town_map.txt",
    "townmap.txt"
  ].freeze unless const_defined?(:TOWN_MAP_DATA_FILENAMES)

  TOWN_MAP_IMAGE_EXTENSIONS = [
    "",
    ".png",
    ".gif",
    ".jpg",
    ".jpeg",
    ".bmp"
  ].freeze unless const_defined?(:TOWN_MAP_IMAGE_EXTENSIONS)

  def with_host_town_map
    previous = @force_host_town_map
    @force_host_town_map = true
    return yield
  ensure
    @force_host_town_map = previous
  end

  def force_host_town_map?
    return @force_host_town_map == true
  end

  def with_town_map_context(expansion_id)
    expansion = expansion_id.to_s
    return yield if expansion.empty?
    result = nil
    with_runtime_context(expansion, { :source => :town_map_item }) do
      with_rendering_expansion(expansion) do
        result = yield
      end
    end
    return result
  end

  def town_map_path_cache
    @town_map_path_cache ||= {}
    return @town_map_path_cache
  end

  def town_map_data_cache
    @town_map_data_cache ||= {}
    return @town_map_data_cache
  end

  def town_map_data_request?(file_path)
    normalized = file_path.to_s.gsub("\\", "/")
    return normalized =~ %r{(?:\A|/)Data/(?:town_?map\.dat|TownMap\.rxdata)\z}i
  rescue
    return false
  end

  def expansion_town_map_candidate_paths(expansion_id)
    expansion = expansion_id.to_s
    return [] if expansion.empty?
    roots = []
    data_root = expansion_data_root(expansion) if respond_to?(:expansion_data_root)
    roots << data_root
    if respond_to?(:runtime_asset_roots_for_expansion)
      runtime_asset_roots_for_expansion(expansion).each do |root|
        next if root.to_s.empty?
        roots << root
        roots << runtime_path_join(root, "Data")
      end
    end
    roots << runtime_path_join(runtime_path_join(library_dir, "ExtractedArchives"), runtime_path_join(slugify(expansion), "Data")) if respond_to?(:library_dir)
    roots << runtime_path_join(runtime_path_join(linked_projects_dir, slugify(expansion)), "Data") if respond_to?(:linked_projects_dir)
    roots << runtime_path_join(runtime_path_join(library_dir, "ExtractedArchives"), runtime_path_join(slugify(expansion), "PBS")) if respond_to?(:library_dir)
    roots << runtime_path_join(runtime_path_join(linked_projects_dir, slugify(expansion)), "PBS") if respond_to?(:linked_projects_dir)
    expanded_roots = []
    roots.compact.each do |root|
      text = root.to_s
      next if text.empty?
      expanded_roots << text
      expanded_roots << runtime_path_join(text, "Data") if File.basename(text).downcase != "data"
      expanded_roots << runtime_path_join(text, "PBS") if File.basename(text).downcase != "pbs"
      if File.basename(text).downcase == "data"
        expanded_roots << runtime_path_join(File.dirname(text), "PBS")
      elsif File.basename(text).downcase == "pbs"
        expanded_roots << runtime_path_join(File.dirname(text), "Data")
      end
    end
    paths = []
    expanded_roots.map { |root| root.to_s }.reject { |root| root.empty? }.uniq.each do |root|
      TOWN_MAP_DATA_FILENAMES.each do |filename|
        paths << runtime_path_join(root, filename)
      end
    end
    return paths.uniq
  rescue
    return []
  end

  def expansion_town_map_path(expansion_id)
    expansion = expansion_id.to_s
    return nil if expansion.empty?
    cached = town_map_path_cache[expansion]
    return cached if cached && runtime_file_exists?(cached)
    town_map_path_cache.delete(expansion)
    expansion_town_map_candidate_paths(expansion).each do |candidate|
      next if candidate.to_s.empty?
      next if !runtime_file_exists?(candidate)
      resolved = runtime_existing_path(candidate) || candidate
      town_map_path_cache[expansion] = resolved
      return resolved
    end
    return nil
  rescue => e
    log("[town_map] path lookup failed for #{expansion}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def deep_copy_town_map_value(value)
    case value
    when Array
      return value.map { |entry| deep_copy_town_map_value(entry) }
    when Hash
      copy = {}
      value.each_pair { |key, entry| copy[deep_copy_town_map_value(key)] = deep_copy_town_map_value(entry) }
      return copy
    else
      return value
    end
  end

  def deep_copy_town_map_data(data)
    Marshal.load(Marshal.dump(data))
  rescue
    return deep_copy_town_map_value(data)
  end

  def with_town_map_marshal_stubs
    created = []
    if !Object.const_defined?(:GameData)
      Object.const_set(:GameData, Module.new)
      created << [Object, :GameData]
    end
    if defined?(GameData) && !GameData.const_defined?(:TownMap)
      GameData.const_set(:TownMap, Class.new)
      created << [GameData, :TownMap]
    end
    if !Object.const_defined?(:TownMapData)
      Object.const_set(:TownMapData, Class.new)
      created << [Object, :TownMapData]
    end
    return yield
  ensure
    created.reverse_each do |parent, name|
      parent.send(:remove_const, name) rescue nil
    end
  end

  def load_town_map_marshaled_runtime(path)
    return load_marshaled_runtime(path)
  rescue ArgumentError => e
    raise e if e.message.to_s !~ /undefined class\/module/i
    return with_town_map_marshal_stubs { load_marshaled_runtime(path) }
  end

  def town_map_pbs_source?(path)
    return path.to_s =~ /(?:\A|\/|\\)town_?map\.txt\z/i
  rescue
    return false
  end

  def parse_town_map_csv(value)
    text = value.to_s
    values = []
    current = ""
    quoted = false
    index = 0
    while index < text.length
      char = text[index, 1]
      if quoted
        if char == "\""
          if text[index + 1, 1] == "\""
            current << "\""
            index += 1
          else
            quoted = false
          end
        else
          current << char.to_s
        end
      elsif char == "\""
        quoted = true
      elsif char == ","
        values << current.strip
        current = ""
      else
        current << char.to_s
      end
      index += 1
    end
    values << current.strip
    return values
  rescue
    return value.to_s.split(",").map { |entry| entry.to_s.strip }
  end

  def parse_town_map_point(value)
    fields = parse_town_map_csv(value)
    point = [
      integer(fields[0], 0),
      integer(fields[1], 0),
      fields[2].to_s,
      fields[3].to_s
    ]
    (4..7).each do |index|
      raw = fields[index]
      number = integer(raw, 0)
      point << (raw.nil? || raw.to_s.strip.empty? || number <= 0 ? nil : number)
    end
    return point
  rescue
    return nil
  end

  def load_town_map_pbs_runtime(path)
    data = []
    current = nil
    File.foreach(path) do |line|
      text = line.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") rescue line.to_s
      stripped = text.sub(/\A\xEF\xBB\xBF/, "").strip
      next if stripped.empty? || stripped.start_with?("#")
      if stripped =~ /\A\[(\d+)\]\z/
        current = ["", "", []]
        data[integer($1, 0)] = current
        next
      end
      next if !current || stripped !~ /\A([^=]+?)\s*=\s*(.*)\z/
      key = $1.to_s.strip.downcase
      value = $2.to_s.strip
      case key
      when "name"
        current[0] = value
      when "filename"
        current[1] = value
      when "point"
        point = parse_town_map_point(value)
        current[2] << point if point
      end
    end
    return data.any? { |region| region.is_a?(Array) } ? data : nil
  rescue => e
    log("[town_map] PBS town map parse failed for #{path}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def load_town_map_runtime(path)
    return load_town_map_pbs_runtime(path) if town_map_pbs_source?(path)
    return load_town_map_marshaled_runtime(path)
  end

  def town_map_object_value(object, *keys)
    return nil if object.nil?
    keys.each do |key|
      if object.is_a?(Hash)
        return object[key] if object.has_key?(key)
        return object[key.to_s] if object.has_key?(key.to_s)
      end
      ivar = "@#{key}"
      return object.instance_variable_get(ivar) if object.instance_variable_defined?(ivar)
      return object.send(key) if object.respond_to?(key)
    end
    return nil
  rescue
    return nil
  end

  def town_map_region_entry?(entry)
    return false if entry.nil?
    return true if town_map_object_value(entry, :filename)
    return true if town_map_object_value(entry, :point).is_a?(Array)
    return false
  end

  def coerce_hash_town_map_data(data)
    return nil if !data.is_a?(Hash)
    region_keys = data.keys.find_all do |key|
      integer(key, -1) >= 0 && town_map_region_entry?(data[key])
    end
    return nil if region_keys.empty?
    converted = []
    region_keys.sort_by { |key| integer(key, 0) }.each do |key|
      region_index = integer(key, 0)
      region_entry = data[key]
      name = town_map_object_value(region_entry, :real_name, :name)
      filename = town_map_object_value(region_entry, :filename)
      points = town_map_object_value(region_entry, :point)
      points = nil if !points.is_a?(Array)
      if !points
        points = []
        data.each_pair do |point_key, point_entry|
          next if point_key.is_a?(Integer)
          point_region = integer(town_map_object_value(point_entry, :region), -1)
          next if point_region != region_index
          pos = town_map_object_value(point_entry, :pos)
          pos = point_key if !pos && point_key.is_a?(Array)
          next if !pos.is_a?(Array)
          fly_data = town_map_object_value(point_entry, :flyData)
          fly_data = [] if !fly_data.is_a?(Array)
          points << [
            integer(pos[0], 0),
            integer(pos[1], 0),
            town_map_object_value(point_entry, :name).to_s,
            town_map_object_value(point_entry, :poi).to_s,
            integer(fly_data[0], 0) > 0 ? integer(fly_data[0], 0) : nil,
            integer(fly_data[1], 0) > 0 ? integer(fly_data[1], 0) : nil,
            integer(fly_data[2], 0) > 0 ? integer(fly_data[2], 0) : nil,
            nil
          ]
        end
      end
      converted[region_index] = [name, filename, points]
    end
    return converted
  rescue => e
    log("[town_map] hash town map conversion failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def coerce_expansion_town_map_data(data)
    return data if data.is_a?(Array)
    converted = coerce_hash_town_map_data(data) if data.is_a?(Hash)
    return converted if converted
    return nil
  end

  def normalize_expansion_town_map_data(expansion_id, data)
    data = coerce_expansion_town_map_data(data)
    return nil if !data.is_a?(Array)
    expansion = expansion_id.to_s
    normalized = deep_copy_town_map_data(data)
    normalized.each do |region|
      next if !region.is_a?(Array) || !region[2].is_a?(Array)
      region[2].each do |location|
        next if !location.is_a?(Array)
        local_map_id = integer(location[4], 0)
        next if local_map_id <= 0
        virtual_map_id = translate_expansion_map_id(expansion, local_map_id) if respond_to?(:translate_expansion_map_id)
        location[4] = virtual_map_id if integer(virtual_map_id, 0) > 0
      end
    end
    return normalized
  rescue => e
    log("[town_map] normalization failed for #{expansion}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def expansion_town_map_data(expansion_id)
    expansion = expansion_id.to_s
    return nil if expansion.empty?
    return nil if respond_to?(:expansion_active?) && !expansion_active?(expansion)
    path = expansion_town_map_path(expansion)
    return nil if path.to_s.empty?
    mtime = File.mtime(path).to_i rescue 0
    key = [path.to_s, mtime]
    cached = town_map_data_cache[expansion]
    return cached[:data] if cached.is_a?(Hash) && cached[:key] == key
    raw = load_town_map_runtime(path)
    data = normalize_expansion_town_map_data(expansion, raw)
    if data
      town_map_data_cache[expansion] = { :key => key, :data => data }
      log("[town_map] loaded #{expansion} town map from #{path}") if respond_to?(:log)
    else
      log("[town_map] unsupported town map data for #{expansion} at #{path}: #{raw.class}") if respond_to?(:log)
    end
    return data
  rescue => e
    log("[town_map] data load failed for #{expansion}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def current_town_map_expansion_id
    return nil if force_host_town_map?
    candidates = []
    map_id = nil
    if $game_map && $game_map.respond_to?(:map_id)
      map_id = $game_map.map_id
      candidates << current_map_expansion_id(map_id) if respond_to?(:current_map_expansion_id)
      candidates << visual_expansion_id_for_map($game_map) if respond_to?(:visual_expansion_id_for_map)
    end
    candidates << current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    candidates << current_expansion_marker if respond_to?(:current_expansion_marker)
    if map_id && respond_to?(:active_expansion_ids) && respond_to?(:manifest_for)
      target = integer(map_id, 0)
      active_expansion_ids.each do |expansion_id|
        manifest = manifest_for(expansion_id)
        next if !manifest.is_a?(Hash)
        map_block = manifest[:map_block] || manifest["map_block"]
        next if !map_block.is_a?(Hash)
        start_id = integer(map_block[:start] || map_block["start"], 0)
        size = integer(map_block[:size] || map_block["size"], RESERVED_MAP_BLOCK_SIZE)
        next if start_id <= 0 || size <= 0
        candidates << expansion_id if target >= start_id && target < start_id + size
      end
    end
    candidates.compact.map { |candidate| candidate.to_s }.reject { |candidate| candidate.empty? }.uniq.each do |candidate|
      next if candidate == HOST_EXPANSION_ID
      next if respond_to?(:expansion_active?) && !expansion_active?(candidate)
      if expansion_town_map_path(candidate)
        log("[town_map] using #{candidate} town map for map #{map_id || "none"}") if respond_to?(:log)
        return candidate
      end
    end
    return nil
  rescue => e
    log("[town_map] current expansion lookup failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def town_map_region_index(mapdata, requested_region = -1, player_position = nil)
    requested = integer(requested_region, -1)
    return requested if requested >= 0 && mapdata[requested]
    player_region = player_position.is_a?(Array) ? integer(player_position[0], -1) : -1
    return player_region if player_region >= 0 && mapdata[player_region]
    mapdata.each_with_index do |region, index|
      return index if region
    end
    return 0
  rescue
    return 0
  end

  def town_map_location_visible?(expansion_id, location, wallmap = false)
    return false if !location.is_a?(Array)
    switch_id = integer(location[7], 0)
    return true if switch_id <= 0
    return false if wallmap
    if !expansion_id.to_s.empty? && respond_to?(:expansion_switch_active?)
      return expansion_switch_active?(expansion_id, switch_id)
    end
    return $game_switches[switch_id] == true if defined?($game_switches) && $game_switches
    return false
  rescue
    return false
  end

  def town_map_location_name(value)
    return value.to_s.strip.downcase
  rescue
    return ""
  end

  def town_map_display_text(expansion_id, text, map_id = nil)
    value = text.to_s
    return value if value.empty?
    if respond_to?(:anil_expansion_id?) && anil_expansion_id?(expansion_id)
      value = anil_translate_text(value, map_id) if respond_to?(:anil_translate_text)
      value = anil_manual_text_fixups(value) if respond_to?(:anil_manual_text_fixups)
    end
    return value
  rescue
    return text.to_s
  end

  def consume_town_map_close_input!
    2.times do
      Graphics.update if defined?(Graphics)
      Input.update if defined?(Input)
    end
    return true
  rescue
    Input.update if defined?(Input)
    return true
  end

  def town_map_player_position(expansion_id, map_id, mapdata)
    target = integer(map_id, 0)
    return nil if target <= 0 || !mapdata.is_a?(Array)
    map_name = nil
    map_name = expansion_map_display_name(target) if respond_to?(:expansion_map_display_name)
    map_name = $game_map.name if map_name.to_s.empty? && $game_map && $game_map.respond_to?(:name) && integer($game_map.map_id, 0) == target
    normalized_names = [
      town_map_location_name(map_name),
      town_map_location_name(town_map_display_text(expansion_id, map_name, target))
    ].reject { |name| name.to_s.empty? }.uniq
    mapdata.each_with_index do |region, region_index|
      next if !region.is_a?(Array) || !region[2].is_a?(Array)
      region[2].each do |location|
        next if !location.is_a?(Array)
        return [region_index, integer(location[0], 0), integer(location[1], 0)] if integer(location[4], 0) == target
      end
    end
    if !normalized_names.empty?
      mapdata.each_with_index do |region, region_index|
        next if !region.is_a?(Array) || !region[2].is_a?(Array)
        region[2].each do |location|
          next if !location.is_a?(Array)
          location_names = [
            town_map_location_name(location[2]),
            town_map_location_name(town_map_display_text(expansion_id, location[2], target))
          ].reject { |name| name.to_s.empty? }.uniq
          return [region_index, integer(location[0], 0), integer(location[1], 0)] if (location_names & normalized_names).length > 0
        end
      end
    end
    metadata = GameData::MapMetadata.try_get(target) if defined?(GameData::MapMetadata)
    position = metadata.town_map_position if metadata && metadata.respond_to?(:town_map_position)
    return position if position.is_a?(Array)
    return nil
  rescue
    return nil
  end

  def town_map_region_name(expansion_id, region_index, region_data)
    name = region_data[0].to_s if region_data.is_a?(Array)
    name = town_map_display_text(expansion_id, name)
    return name if !name.to_s.empty?
    manifest = manifest_for(expansion_id) if respond_to?(:manifest_for)
    name = manifest[:name].to_s if manifest.is_a?(Hash)
    return name if !name.to_s.empty?
    return "Town Map"
  rescue
    return "Town Map"
  end

  def town_map_bitmap_path(expansion_id, region_data)
    filename = region_data[1].to_s if region_data.is_a?(Array)
    return nil if filename.to_s.empty?
    logical = filename.gsub("\\", "/")
    logical = "Graphics/Pictures/#{logical}" if logical !~ %r{\AGraphics/}i
    resolved = resolve_runtime_path_for_expansion(expansion_id, logical, TOWN_MAP_IMAGE_EXTENSIONS) if respond_to?(:resolve_runtime_path_for_expansion)
    return resolved if resolved
    return logical
  rescue
    return nil
  end
end

alias tef_town_map_original_load_data load_data
def load_data(file_path)
  if file_path.is_a?(String) &&
     TravelExpansionFramework.town_map_data_request?(file_path) &&
     !TravelExpansionFramework.force_host_town_map?
    expansion = TravelExpansionFramework.current_town_map_expansion_id
    data = TravelExpansionFramework.expansion_town_map_data(expansion) if expansion
    return data if data
  end
  return tef_town_map_original_load_data(file_path)
end

alias tef_town_map_original_pbLoadTownMapData pbLoadTownMapData
def pbLoadTownMapData
  if !TravelExpansionFramework.force_host_town_map?
    expansion = TravelExpansionFramework.current_town_map_expansion_id
    data = TravelExpansionFramework.expansion_town_map_data(expansion) if expansion
    return data if data
  end
  return TravelExpansionFramework.with_host_town_map { tef_town_map_original_pbLoadTownMapData }
end

if defined?(BetterRegionMap)
  module TravelExpansionFramework
    class ExpansionBetterRegionMap < BetterRegionMap
      def initialize(region = -1, show_player = true, can_fly = false, wallmap = false, species = nil, fly_anywhere = false)
        @tef_expansion_id = TravelExpansionFramework.current_town_map_expansion_id
        @tef_expansion_id = TravelExpansionFramework.current_runtime_expansion_id if @tef_expansion_id.to_s.empty? &&
                                                                                     TravelExpansionFramework.respond_to?(:current_runtime_expansion_id)
        @wallmap = wallmap
        @mapdata = TravelExpansionFramework.expansion_town_map_data(@tef_expansion_id)
        raise "No expansion town map data for #{@tef_expansion_id}" if !@mapdata
        map_id = $game_map && $game_map.respond_to?(:map_id) ? $game_map.map_id : 0
        player = TravelExpansionFramework.town_map_player_position(@tef_expansion_id, map_id, @mapdata)
        @region = TravelExpansionFramework.town_map_region_index(@mapdata, region, player)
        @data = @mapdata[@region]
        raise "No town map region #{@region} for #{@tef_expansion_id}" if !@data
        player = nil if player && player[0].to_i != @region.to_i
        @fly_anywhere = fly_anywhere
        @species = species
        @show_player = show_player && !player.nil?
        @can_fly = can_fly
        showBlk
        create_viewports
        create_sprites(player)
        hideBlk { update(false) }
        main
      rescue => e
        safe_dispose_partial
        raise e
      end

      def create_viewports
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99999
        @mapvp = Viewport.new(16, 32, 480, 320)
        @mapvp.z = 100000
        @mapoverlayvp = Viewport.new(16, 32, 480, 320)
        @mapoverlayvp.z = 100001
        @viewport2 = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport2.z = 100001
        @sprites = SpriteHash.new
        @window = SpriteHash.new
      end

      def create_sprites(player)
        @sprites["bg"] = Sprite.new(@viewport)
        @sprites["bg"].bmp("Graphics/Pictures/mapbg")
        @window["map"] = Sprite.new(@mapvp)
        map_bitmap = TravelExpansionFramework.town_map_bitmap_path(@tef_expansion_id, @data)
        raise "No town map bitmap for #{@tef_expansion_id} region #{@region}" if map_bitmap.to_s.empty?
        @window["map"].bmp(map_bitmap)
        @window["player"] = Sprite.new(@mapoverlayvp)
        if @show_player && player
          @window["player"].bmp("Graphics/Pictures/map/location_icon")
          @window["player"].x = TileWidth * player[1] + (TileWidth / 2.0)
          @window["player"].y = TileHeight * player[2] + (TileHeight / 2.0)
          @window["player"].center_origins
        end
        @window["areahighlight"] = BitmapSprite.new(@window["map"].bitmap.width, @window["map"].bitmap.height, @mapoverlayvp)
        @window["areahighlight"].y = -8
        @sprites["cursor"] = Sprite.new(@viewport2)
        @sprites["cursor"].bmp("Graphics/Pictures/mapCursor")
        @sprites["cursor"].src_rect.width = @sprites["cursor"].bmp.height
        @sprites["cursor"].ox = (@sprites["cursor"].bmp.height - TileWidth) / 2.0
        @sprites["cursor"].oy = @sprites["cursor"].ox
        @sprites["txt"] = TextSprite.new(@viewport)
        create_arrows
        $PokemonGlobal.regionMapSel = [0, 0] if !$PokemonGlobal.regionMapSel
        initial_position = calculate_initial_position(player)
        init_cursor_position(initial_position[0], initial_position[1])
        center_window
        create_fly_points if @can_fly
        update_text
        @dirs = []
        @mdirs = []
        @i = 0
      end

      def create_arrows
        @sprites["arrowLeft"] = Sprite.new(@viewport2)
        @sprites["arrowLeft"].bmp("Graphics/Pictures/mapArrowRight")
        @sprites["arrowLeft"].mirror = true
        @sprites["arrowLeft"].center_origins
        @sprites["arrowLeft"].xyz = 12, Graphics.height / 2
        @sprites["arrowRight"] = Sprite.new(@viewport2)
        @sprites["arrowRight"].bmp("Graphics/Pictures/mapArrowRight")
        @sprites["arrowRight"].center_origins
        @sprites["arrowRight"].xyz = Graphics.width - 12, Graphics.height / 2
        @sprites["arrowUp"] = Sprite.new(@viewport2)
        @sprites["arrowUp"].bmp("Graphics/Pictures/mapArrowDown")
        @sprites["arrowUp"].angle = 180
        @sprites["arrowUp"].center_origins
        @sprites["arrowUp"].xyz = Graphics.width / 2, 24
        @sprites["arrowDown"] = Sprite.new(@viewport2)
        @sprites["arrowDown"].bmp("Graphics/Pictures/mapArrowDown")
        @sprites["arrowDown"].center_origins
        @sprites["arrowDown"].xyz = Graphics.width / 2, Graphics.height - 24
      end

      def create_fly_points
        @spots = {}
        n = 0
        map_width = (@window["map"].bmp.width / TileWidth).to_i
        map_height = (@window["map"].bmp.height / TileHeight).to_i
        for x in 0...map_width
          for y in 0...map_height
            healspot = pbGetHealingSpot(x, y)
            next if !can_fly_to_location(healspot)
            @window["point#{n}"] = Sprite.new(@mapvp)
            fly_bitmap = TravelExpansionFramework.resolve_runtime_path_for_expansion(@tef_expansion_id, "Graphics/Pictures/mapFly", TravelExpansionFramework::TOWN_MAP_IMAGE_EXTENSIONS)
            @window["point#{n}"].bmp(fly_bitmap || "Graphics/Pictures/map/mapFly")
            @window["point#{n}"].src_rect.width = @window["point#{n}"].bmp.height
            @window["point#{n}"].x = TileWidth * x + (TileWidth / 2)
            @window["point#{n}"].y = TileHeight * y + (TileHeight / 2)
            @window["point#{n}"].oy = @window["point#{n}"].bmp.height / 2.0
            @window["point#{n}"].ox = @window["point#{n}"].oy
            @spots[[x, y]] = healspot
            n += 1
          end
        end
      end

      def safe_dispose_partial
        @sprites.dispose if @sprites && @sprites.respond_to?(:dispose)
        @window.dispose if @window && @window.respond_to?(:dispose)
        @viewport.dispose if @viewport && @viewport.respond_to?(:dispose)
        @viewport2.dispose if @viewport2 && @viewport2.respond_to?(:dispose)
        @mapvp.dispose if @mapvp && @mapvp.respond_to?(:dispose)
        @mapoverlayvp.dispose if @mapoverlayvp && @mapoverlayvp.respond_to?(:dispose)
        hideBlk rescue nil
      rescue
      end

      def been_to_johto
        return true
      end

      def been_to_sevii
        return true
      end

      def adjust_window_if_not_visited_regions
      end

      def calculate_initial_position(player)
        return [player[1], player[2]] if player && player[1] && player[2]
        if @data && @data[2].is_a?(Array)
          first_location = @data[2].find { |location| TravelExpansionFramework.town_map_location_visible?(@tef_expansion_id, location, @wallmap) }
          return [first_location[0], first_location[1]] if first_location
        end
        return [0, 0]
      end

      def pbGetHealingSpot(x, y)
        return nil if !@data || !@data[2]
        for loc in @data[2]
          next if !TravelExpansionFramework.town_map_location_visible?(@tef_expansion_id, loc, @wallmap)
          next if loc[0] != x || loc[1] != y
          return nil if !loc[4] || !loc[5] || !loc[6]
          return [loc[4], loc[5], loc[6]]
        end
        return nil
      end

      def close_requested?
        return true if Input.trigger?(Input::B)
        return true if defined?(Input::BACK) && Input.trigger?(Input::BACK)
        return false
      rescue
        return false
      end

      def main
        loop do
          update
          if Input.press?(Input::RIGHT) && ![4, 6].any? { |e| @dirs.include?(e) || @mdirs.include?(e) }
            if @sprites["cursor"].x < 480
              $PokemonGlobal.regionMapSel[0] += 1
              @sx = @sprites["cursor"].x
              @dirs << DIRECTION_RIGHT
            elsif @window.x > -1 * (@window["map"].bmp.width - 480)
              $PokemonGlobal.regionMapSel[0] += 1
              @mx = @window.x
              @mdirs << DIRECTION_RIGHT
            end
          end
          if Input.press?(Input::LEFT) && ![4, 6].any? { |e| @dirs.include?(e) || @mdirs.include?(e) }
            if @sprites["cursor"].x > 16
              $PokemonGlobal.regionMapSel[0] -= 1
              @sx = @sprites["cursor"].x
              @dirs << DIRECTION_LEFT
            elsif @window.x < 0 && been_to_johto
              $PokemonGlobal.regionMapSel[0] -= 1
              @mx = @window.x
              @mdirs << DIRECTION_LEFT
            end
          end
          if Input.press?(Input::DOWN) && ![DIRECTION_DOWN, DIRECTION_UP].any? { |e| @dirs.include?(e) || @mdirs.include?(e) }
            if @sprites["cursor"].y <= 320
              $PokemonGlobal.regionMapSel[1] += 1
              @sy = @sprites["cursor"].y
              @dirs << DIRECTION_DOWN
            elsif @window.y > -1 * (@window["map"].bmp.height - 320) && been_to_sevii
              $PokemonGlobal.regionMapSel[1] += 1
              @my = @window.y
              @mdirs << DIRECTION_DOWN
            end
          end
          if Input.press?(Input::UP) && ![2, 8].any? { |e| @dirs.include?(e) || @mdirs.include?(e) }
            if @sprites["cursor"].y > 32
              $PokemonGlobal.regionMapSel[1] -= 1
              @sy = @sprites["cursor"].y
              @dirs << DIRECTION_UP
            elsif @window.y < 0
              $PokemonGlobal.regionMapSel[1] -= 1
              @my = @window.y
              @mdirs << DIRECTION_UP
            end
          end
          print_current_position if Input.trigger?(Input::AUX1)
          if Input.trigger?(Input::C) && @dirs.empty?
            x, y = $PokemonGlobal.regionMapSel
            if @spots && @spots[[x, y]]
              @flydata = @spots[[x, y]]
              break
            else
              stick_to_positions = findNearbyHealingSpot(x, y)
              if stick_to_positions
                @sy = @sprites["cursor"].y
                @sx = @sprites["cursor"].x
                @my = @window.y
                @mx = @window.x
                move_cursor_to(stick_to_positions[0], stick_to_positions[1])
                update_text
              end
            end
          end
          break if close_requested?
        end
        dispose
      end

      def dispose
        return if @tef_disposed
        @tef_disposed = true
        showBlk { update(false) } rescue nil
        @sprites.dispose if @sprites && @sprites.respond_to?(:dispose)
        @window.dispose if @window && @window.respond_to?(:dispose)
        @viewport.dispose if @viewport && @viewport.respond_to?(:dispose)
        @viewport2.dispose if @viewport2 && @viewport2.respond_to?(:dispose)
        @mapvp.dispose if @mapvp && @mapvp.respond_to?(:dispose)
        @mapoverlayvp.dispose if @mapoverlayvp && @mapoverlayvp.respond_to?(:dispose)
        hideBlk rescue nil
        TravelExpansionFramework.consume_town_map_close_input! if TravelExpansionFramework.respond_to?(:consume_town_map_close_input!)
      end

      def update_text
        location = @data[2].find do |entry|
          entry[0] == $PokemonGlobal.regionMapSel[0] &&
            entry[1] == $PokemonGlobal.regionMapSel[1] &&
            TravelExpansionFramework.town_map_location_visible?(@tef_expansion_id, entry, @wallmap)
        end
        text = location ? TravelExpansionFramework.town_map_display_text(@tef_expansion_id, location[2]) : ""
        poi = (location && location[3]) ? TravelExpansionFramework.town_map_display_text(@tef_expansion_id, location[3]) : ""
        region_name = TravelExpansionFramework.town_map_region_name(@tef_expansion_id, @region, @data)
        @sprites["txt"].draw([
          [region_name, 16, 0, 0, Color.new(255, 255, 255), Color.new(0, 0, 0)],
          [text, 16, 354, 0, Color.new(255, 255, 255), Color.new(0, 0, 0)],
          [poi, 496, 354, 1, Color.new(255, 255, 255), Color.new(0, 0, 0)]
        ], true)
      end
    end
  end

  class BetterRegionMap
    alias tef_town_map_original_initialize initialize unless method_defined?(:tef_town_map_original_initialize)

    def initialize(region = -1, show_player = true, can_fly = false, wallmap = false, species = nil, fly_anywhere = false)
      if defined?(TravelExpansionFramework::ExpansionBetterRegionMap) &&
         !is_a?(TravelExpansionFramework::ExpansionBetterRegionMap)
        expansion = TravelExpansionFramework.current_town_map_expansion_id
        if expansion && TravelExpansionFramework.expansion_town_map_data(expansion)
          replacement = TravelExpansionFramework.with_town_map_context(expansion) do
            TravelExpansionFramework::ExpansionBetterRegionMap.new(region, show_player, can_fly, wallmap, species, fly_anywhere)
          end
          replacement.instance_variables.each do |ivar|
            instance_variable_set(ivar, replacement.instance_variable_get(ivar))
          end
          return
        end
      end
      tef_town_map_original_initialize(region, show_player, can_fly, wallmap, species, fly_anywhere)
    rescue => e
      TravelExpansionFramework.log("[town_map] BetterRegionMap redirect failed: #{e.class}: #{e.message}") rescue nil
      tef_town_map_original_initialize(region, show_player, can_fly, wallmap, species, fly_anywhere)
    end
  end

  alias tef_town_map_original_pbBetterRegionMap pbBetterRegionMap
  def pbBetterRegionMap(region = -1, show_player = true, can_fly = false, wallmap = false, species = nil, fly_anywhere = false)
    expansion = TravelExpansionFramework.current_town_map_expansion_id
    if expansion && TravelExpansionFramework.expansion_town_map_data(expansion)
      return TravelExpansionFramework.with_town_map_context(expansion) do
        TravelExpansionFramework::ExpansionBetterRegionMap.new(region, show_player, can_fly, wallmap, species, fly_anywhere).flydata
      end
    end
    return TravelExpansionFramework.with_host_town_map do
      tef_town_map_original_pbBetterRegionMap(region, show_player, can_fly, wallmap, species, fly_anywhere)
    end
  rescue => e
    TravelExpansionFramework.log("[town_map] expansion map failed for #{expansion}: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}") rescue nil
    if expansion && TravelExpansionFramework.expansion_town_map_path(expansion)
      pbMessage(_INTL("The Town Map for this world could not be opened.")) if defined?(pbMessage)
      return nil
    end
    return TravelExpansionFramework.with_host_town_map do
      tef_town_map_original_pbBetterRegionMap(region, show_player, can_fly, wallmap, species, fly_anywhere)
    end
  end
end

module TravelExpansionFramework
  module_function

  def call_town_map_global_method(method_name, *args)
    name = method_name.to_sym
    return nil if !Object.private_method_defined?(name) && !Object.method_defined?(name)
    return Object.new.send(name, *args)
  rescue => e
    log("[town_map] global #{method_name} call failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def town_map_item_reference?(item_identifier)
    canonical = canonical_imported_item_reference(item_identifier) if respond_to?(:canonical_imported_item_reference)
    return true if canonical && canonical[1].to_s.upcase == "TOWNMAP"
    text = item_identifier.to_s.strip.gsub(/\A:/, "").upcase
    return text == "TOWNMAP" || text.end_with?("_TOWNMAP")
  rescue
    return false
  end

  def town_map_item_handler_registry
    @town_map_item_handler_registry ||= {}
    return @town_map_item_handler_registry
  end

  def town_map_runtime_item_symbols
    symbols = [:TOWNMAP]
    if respond_to?(:imported_runtime_items)
      imported_runtime_items.each_value do |metadata|
        next if !metadata.is_a?(Hash)
        runtime_symbol = metadata[:runtime_symbol] || metadata["runtime_symbol"]
        raw_name = metadata[:raw_name] || metadata["raw_name"] || metadata[:source_id] || metadata["source_id"]
        symbols << runtime_symbol if runtime_symbol && town_map_item_reference?(raw_name || runtime_symbol)
      end
    end
    expansion_ids = []
    expansion_ids.concat(active_expansion_ids) if respond_to?(:active_expansion_ids)
    expansion_ids.concat(external_projects.keys) if respond_to?(:external_projects) && external_projects
    expansion_ids.each do |expansion_id|
      next if expansion_id.to_s.empty?
      runtime_symbol = imported_item_runtime_symbol(expansion_id, "TOWNMAP") if respond_to?(:imported_item_runtime_symbol)
      symbols << runtime_symbol if runtime_symbol
    end
    return symbols.compact.map { |symbol| symbol.is_a?(Symbol) ? symbol : symbol.to_s.to_sym }.uniq
  rescue
    return [:TOWNMAP]
  end

  def register_world_town_map_item_symbol!(symbol)
    return false if symbol.nil? || !defined?(ItemHandlers)
    item_symbol = symbol.is_a?(Symbol) ? symbol : symbol.to_s.to_sym
    return false if town_map_item_handler_registry[item_symbol]
    ItemHandlers::UseInField.add(item_symbol, proc { |_item|
      TravelExpansionFramework.open_current_world_town_map(-1, true, false, false)
      next 1
    })
    ItemHandlers::UseFromBag.add(item_symbol, proc { |_item|
      TravelExpansionFramework.open_current_world_town_map(-1, true, false, false)
      next 2
    })
    town_map_item_handler_registry[item_symbol] = true
    return true
  rescue => e
    log("[town_map] item handler registration failed for #{symbol}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def open_current_world_town_map(region = -1, show_player = true, can_fly = false, wallmap = false, species = nil, fly_anywhere = false)
    expansion = current_town_map_expansion_id
    if expansion && expansion_town_map_data(expansion)
      return with_town_map_context(expansion) do
        if defined?(TravelExpansionFramework::ExpansionBetterRegionMap)
          TravelExpansionFramework::ExpansionBetterRegionMap.new(region, show_player, can_fly, wallmap, species, fly_anywhere).flydata
        elsif Object.private_method_defined?(:tef_town_map_original_pbBetterRegionMap) || Object.method_defined?(:tef_town_map_original_pbBetterRegionMap)
          call_town_map_global_method(:tef_town_map_original_pbBetterRegionMap, region, show_player, can_fly, wallmap, species, fly_anywhere)
        else
          call_town_map_global_method(:pbShowMap, region, wallmap)
        end
      end
    end
    if Object.private_method_defined?(:tef_town_map_original_pbBetterRegionMap) || Object.method_defined?(:tef_town_map_original_pbBetterRegionMap)
      return with_host_town_map do
        call_town_map_global_method(:tef_town_map_original_pbBetterRegionMap, region, show_player, can_fly, wallmap, species, fly_anywhere)
      end
    end
    return with_host_town_map { call_town_map_global_method(:pbShowMap, region, wallmap) }
  rescue => e
    log("[town_map] item open failed for #{expansion}: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}") if respond_to?(:log)
    if expansion && expansion_town_map_path(expansion)
      pbMessage(_INTL("The Town Map for this world could not be opened.")) if defined?(pbMessage)
      return nil
    end
    if Object.private_method_defined?(:tef_town_map_original_pbBetterRegionMap) || Object.method_defined?(:tef_town_map_original_pbBetterRegionMap)
      return with_host_town_map do
        call_town_map_global_method(:tef_town_map_original_pbBetterRegionMap, region, show_player, can_fly, wallmap, species, fly_anywhere)
      end
    end
    return nil
  end

  def register_world_town_map_item_handlers!
    return false if !defined?(ItemHandlers)
    registered = false
    town_map_runtime_item_symbols.each do |symbol|
      registered = register_world_town_map_item_symbol!(symbol) || registered
    end
    log("[town_map] registered world-aware Town Map item handlers #{town_map_item_handler_registry.keys.inspect}") if registered && respond_to?(:log)
    return registered
  rescue => e
    log("[town_map] item handler registration failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end
end

if TravelExpansionFramework.respond_to?(:ensure_external_item_registered)
  class << TravelExpansionFramework
    alias tef_town_map_original_ensure_external_item_registered ensure_external_item_registered unless method_defined?(:tef_town_map_original_ensure_external_item_registered)

    def ensure_external_item_registered(expansion_id, item_identifier)
      result = tef_town_map_original_ensure_external_item_registered(expansion_id, item_identifier)
      if result && town_map_item_reference?(item_identifier)
        register_world_town_map_item_handlers!
      end
      return result
    end
  end
end

TravelExpansionFramework.register_world_town_map_item_handlers!

alias tef_town_map_original_pbShowMap pbShowMap
def pbShowMap(region = -1, wallmap = true)
  expansion = TravelExpansionFramework.current_town_map_expansion_id
  if expansion && TravelExpansionFramework.expansion_town_map_data(expansion)
    return pbBetterRegionMap(region, true, false, wallmap)
  end
  return TravelExpansionFramework.with_host_town_map { tef_town_map_original_pbShowMap(region, wallmap) }
end
