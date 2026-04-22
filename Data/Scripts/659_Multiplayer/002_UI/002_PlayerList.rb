# ===========================================
# File: 004_UI_PlayerList.rb
# Purpose: Adds "Player List" option under Outfit in pause menu (scene hook)
# Works with KIF’s PokemonPauseMenu_Scene#pbShowCommands
# Fixed: no index shifting (doesn't mutate caller's array)
# Adds: "Request Trade" action per player
# ===========================================

##MultiplayerDebug.info("UI-PLAYER", "Player List hook (Scene level) loaded.")

module MultiplayerUI
  # ===========================================
  # === Parsing Helpers
  # ===========================================
  # Expected format from server: "SIDx - Name"
  # Returns [sid, name, uuid] from a server player-list entry.
  # Old format: "SIDx - Name"
  # New format: "SIDx - Name - uuid"
  def self.parse_player_entry(entry)
    return [nil, nil, nil] if entry.nil?
    s = entry.to_s
    parts = s.split(" - ", 3)
    if parts.length >= 2
      sid  = parts[0].strip
      name = parts[1].strip
      uuid = parts.length >= 3 ? parts[2].strip : nil
    else
      sub = s.split(" ", 2)
      sid  = sub[0].to_s.strip
      name = (sub[1] || "").strip
      uuid = nil
    end
    [sid, name, uuid]
  end

  # Normalize appearance payloads from mixed client/server versions.
  # Older versions may omit fields or send placeholder values like "default".
  def self.normalize_trainer_appearance(raw)
    raw = {} unless raw.is_a?(Hash)
    {
      clothes: _normalize_appearance_id(_appearance_value(raw, [:clothes, :outfit], "001"), "001"),
      hat: _normalize_appearance_id(_appearance_value(raw, :hat, "000"), "000"),
      hat2: _normalize_appearance_id(_appearance_value(raw, [:hat2, :secondary_hat], "000"), "000"),
      hair: _normalize_appearance_id(_appearance_value(raw, :hair, "000"), "000"),
      skin_tone: _appearance_int(raw, [:skin_tone, :skin_color, :skin], 0),
      hair_color: _appearance_int(raw, :hair_color, 0),
      hat_color: _appearance_int(raw, :hat_color, 0),
      hat2_color: _appearance_int(raw, [:hat2_color, :secondary_hat_color], 0),
      clothes_color: _appearance_int(raw, :clothes_color, 0)
    }
  end

  def self.local_trainer_appearance
    return nil unless defined?($Trainer) && $Trainer
    normalize_trainer_appearance(
      clothes: ($Trainer.respond_to?(:clothes) ? $Trainer.clothes : ($Trainer.respond_to?(:outfit) ? $Trainer.outfit : nil)),
      hat: ($Trainer.respond_to?(:hat) ? $Trainer.hat : nil),
      hat2: ($Trainer.respond_to?(:hat2) ? $Trainer.hat2 : nil),
      hair: ($Trainer.respond_to?(:hair) ? $Trainer.hair : nil),
      skin_tone: ($Trainer.respond_to?(:skin_tone) ? $Trainer.skin_tone : nil),
      hair_color: ($Trainer.respond_to?(:hair_color) ? $Trainer.hair_color : nil),
      hat_color: ($Trainer.respond_to?(:hat_color) ? $Trainer.hat_color : nil),
      hat2_color: ($Trainer.respond_to?(:hat2_color) ? $Trainer.hat2_color : nil),
      clothes_color: ($Trainer.respond_to?(:clothes_color) ? $Trainer.clothes_color : nil)
    )
  rescue
    nil
  end

  def self.sid_for_uuid(uuid)
    return nil if uuid.nil?
    uuid = uuid.to_s.strip
    return nil if uuid.empty?
    list = MultiplayerClient.instance_variable_get(:@player_list) rescue nil
    return nil unless list.is_a?(Array)
    list.each do |entry|
      sid, _name, entry_uuid = parse_player_entry(entry)
      next if entry_uuid.to_s.strip.empty?
      return sid if entry_uuid == uuid
    end
    nil
  rescue
    nil
  end

  def self.profile_sprite_data(uuid, payload = nil)
    payload_sprite = payload.is_a?(Hash) ? payload["sprite_data"] : nil

    my_uuid = MultiplayerClient.platinum_uuid rescue nil
    if uuid.to_s == "self" || (!my_uuid.to_s.empty? && uuid.to_s == my_uuid.to_s)
      local = local_trainer_appearance
      if local && payload_sprite.is_a?(Hash) && !payload_sprite.empty?
        return normalize_trainer_appearance(payload_sprite.merge(local))
      end
      return local if local
    end

    sid = sid_for_uuid(uuid)
    if sid && defined?(MultiplayerClient)
      remote = MultiplayerClient.players[sid] rescue nil
      if payload_sprite.is_a?(Hash) && !payload_sprite.empty? && remote.is_a?(Hash) && !remote.empty?
        return normalize_trainer_appearance(payload_sprite.merge(remote))
      end
      return normalize_trainer_appearance(remote) if remote.is_a?(Hash) && !remote.empty?
    end

    if payload_sprite.is_a?(Hash) && !payload_sprite.empty?
      return normalize_trainer_appearance(payload_sprite)
    end

    nil
  rescue
    nil
  end

  def self._appearance_value(raw, key, default)
    value = _appearance_lookup(raw, key)
    value = default if value.nil?
    value.to_s.strip
  rescue
    default
  end

  def self._appearance_int(raw, key, default)
    value = _appearance_lookup(raw, key)
    return default if value.nil? || value.to_s.strip.empty?
    value.to_i
  rescue
    default
  end

  def self._appearance_lookup(raw, key)
    keys = key.is_a?(Array) ? key : [key]
    keys.each do |entry|
      value = raw[entry]
      return value unless value.nil?
      value = raw[entry.to_s]
      return value unless value.nil?
    end
    nil
  rescue
    nil
  end

  def self._normalize_appearance_id(value, default)
    text = value.to_s.strip
    return default if text.empty?
    return default if text.downcase == "default"
    return default if text.downcase == "nil"
    text
  rescue
    default
  end

  def self.local_runtime_position
    return nil unless defined?($game_map) && $game_map
    return nil unless defined?($game_player) && $game_player
    {
      map: $game_map.map_id.to_i,
      x: $game_player.x.to_i,
      y: $game_player.y.to_i
    }
  rescue
    nil
  end

  def self.consume_mouse_ui_click!
    @mouse_ui_click_frame = Graphics.frame_count
    true
  rescue
    false
  end

  def self.mouse_ui_click_consumed?
    frame = @mouse_ui_click_frame
    !frame.nil? && frame == Graphics.frame_count
  rescue
    false
  end

  def self.mouse_modal_overlay_open?
    return true if (defined?(MultiplayerUI::ProfilePanel) && MultiplayerUI::ProfilePanel.open? rescue false)
    return true if (instance_variable_get(:@playerlist_open) rescue false)
    return true if (instance_variable_get(:@squadwindow_open) rescue false)
    return true if (defined?(KIFCases) && KIFCases.respond_to?(:screen_open?) && KIFCases.screen_open? rescue false)
    false
  rescue
    false
  end

  def self.block_overworld_mouse_input?
    mouse_modal_overlay_open? || mouse_ui_click_consumed?
  rescue
    false
  end

  def self.ping_value_for(sid)
    return nil unless defined?(PingTracker)
    ping = PingTracker.get_ping(sid) rescue nil
    ping = ping.to_i
    ping > 0 ? ping : nil
  rescue
    nil
  end

  def self.runtime_player_state_for_sid(sid)
    return nil if sid.to_s.strip.empty?
    players = MultiplayerClient.players rescue nil
    return nil unless players.is_a?(Hash)
    data = players[sid] || players[sid.to_s]
    return nil unless data.is_a?(Hash)

    map = data[:map].to_i
    x = data[:x]
    y = data[:y]
    local = local_runtime_position
    same_map = local && map > 0 && local[:map] == map
    distance = nil
    if same_map && !x.nil? && !y.nil?
      distance = (x.to_i - local[:x]).abs + (y.to_i - local[:y]).abs
    end

    {
      sid: sid.to_s,
      map: map,
      x: x.nil? ? nil : x.to_i,
      y: y.nil? ? nil : y.to_i,
      busy: data[:busy].to_i == 1,
      same_map: !!same_map,
      distance: distance,
      ping: ping_value_for(sid),
      last_sync_time: data[:last_sync_time]
    }
  rescue
    nil
  end

  def self.runtime_player_state_for_uuid(uuid)
    sid = sid_for_uuid(uuid)
    return nil if sid.nil? || sid.empty?
    runtime_player_state_for_sid(sid)
  rescue
    nil
  end

  def self.can_silent_warp_to_sid?(sid)
    state = runtime_player_state_for_sid(sid)
    return false unless state.is_a?(Hash)
    state[:map].to_i > 0 && !state[:x].nil? && !state[:y].nil?
  rescue
    false
  end

  def self.silent_warp_to_sid(sid)
    state = runtime_player_state_for_sid(sid)
    return [false, "Player location unavailable."] unless state.is_a?(Hash)

    map_id = state[:map].to_i
    x = state[:x]
    y = state[:y]
    return [false, "Player location unavailable."] if map_id <= 0 || x.nil? || y.nil?
    return [false, "Teleport unavailable right now."] unless defined?($game_temp) && $game_temp

    local = local_runtime_position
    if local && local[:map].to_i == map_id && local[:x].to_i == x.to_i && local[:y].to_i == y.to_i
      return [true, nil]
    end

    $game_temp.player_transferring  = true
    $game_temp.player_new_map_id    = map_id
    $game_temp.player_new_x         = x.to_i
    $game_temp.player_new_y         = y.to_i
    $game_temp.player_new_direction = ($game_player.direction rescue 2)
    [true, nil]
  rescue
    [false, "Teleport failed."]
  end

  def self.player_presence_text(state, include_ping: true, prefix_online: false)
    return nil unless state.is_a?(Hash)
    parts = []
    parts << "Online" if prefix_online

    location = if state[:same_map]
      dist = state[:distance]
      (dist && dist > 0) ? "#{dist} tiles away" : "Same map"
    elsif state[:map].to_i > 0
      "Map #{state[:map].to_i}"
    else
      "Live status"
    end
    parts << location unless location.empty?
    parts << "Busy" if state[:busy]
    parts << "#{state[:ping]}ms" if include_ping && state[:ping]
    parts.join(" • ")
  rescue
    nil
  end

  def self.map_name_for_id(map_id)
    map_id = map_id.to_i
    return nil if map_id <= 0
    name = defined?(pbGetMapNameFromId) ? pbGetMapNameFromId(map_id).to_s.strip : ""
    return name unless name.empty?
    "Map #{map_id}"
  rescue
    "Map #{map_id.to_i}"
  end

  def self.player_map_text(state, fallback_map_id = nil)
    map_id = if state.is_a?(Hash) && state[:map].to_i > 0
      state[:map].to_i
    else
      fallback_map_id.to_i
    end
    return "Location unavailable" if map_id <= 0
    map_name_for_id(map_id)
  rescue
    "Location unavailable"
  end

  def self.sort_player_entries(entries)
    entries.sort_by do |entry|
      state = runtime_player_state_for_sid(entry[:sid]) || {}
      same_map_rank = state[:same_map] ? 0 : 1
      distance_rank = state[:distance] || 999_999
      busy_rank = state[:busy] ? 1 : 0
      ping_rank = state[:ping] || 999_999
      [
        entry[:is_self] ? 0 : 1,
        same_map_rank,
        distance_rank,
        busy_rank,
        ping_rank,
        entry[:name].to_s.downcase,
        entry[:sid].to_s
      ]
    end
  rescue
    entries
  end

  # Build a display list without mutating the original commands.
  # Returns [display_commands, inserted_indices]
  def self.build_playerlist_display(orig_cmds)
    display = orig_cmds.dup
    inserted = []
    begin
      return [display, inserted] unless MultiplayerClient.instance_variable_get(:@connected)
      oi = display.index(_INTL("Outfit"))
      return [display, inserted] if oi.nil?
      return [display, inserted] if display.include?(_INTL("Player List"))
      insert_pos = oi + 1
      display = display.dup
      display.insert(insert_pos, _INTL("Player List"))
      inserted << insert_pos
      ##MultiplayerDebug.info("UI-PL-INJ", "Prepared Player List injection at #{insert_pos} (no mutation).")
    rescue => e
      ##MultiplayerDebug.error("UI-PL-INJ-ERR", "Injection prep failed: #{e.message}")
    end
    [display, inserted]
  end

  # ===========================================
  # === Hook: Scene Level (pbShowCommands)
  # ===========================================
  if defined?(PokemonPauseMenu_Scene)
    class ::PokemonPauseMenu_Scene
      alias kif_pl_pbShowCommands pbShowCommands unless method_defined?(:kif_pl_pbShowCommands)

      def pbShowCommands(commands)
        # Build a separate display list and keep original intact
        display, inserted = MultiplayerUI.build_playerlist_display(commands)
        ##MultiplayerDebug.info("UI-PL-HOOK", "pbShowCommands hooked; orig=#{commands.length}, disp=#{display.length}")

        # Call original with our display list
        ret_disp = kif_pl_pbShowCommands(display)

        # If canceled or invalid
        return ret_disp if ret_disp.nil? || ret_disp < 0

        # If user picked our injected command, handle and consume it
        if inserted.include?(ret_disp) && display[ret_disp] == _INTL("Player List")
          begin
            ##MultiplayerDebug.info("UI-PL-ACT", "Player List selected from menu.")
            MultiplayerUI.openPlayerList
          rescue => e
            ##MultiplayerDebug.error("UI-PL-SELERR", "Player List open failed: #{e.message}")
          end
          return -1  # consume; return to menu
        end

        # Map display index back to the original index by subtracting
        # how many injected items occurred before the selection.
        shift = inserted.count { |i| i < ret_disp }
        ret_orig = ret_disp - shift
        return ret_orig
      end
    end
    ##MultiplayerDebug.info("UI-PL-OK", "Hooked PokemonPauseMenu_Scene.pbShowCommands (Player List, no-shift).")
  else
    ##MultiplayerDebug.error("UI-PL-NOCLASS", "PokemonPauseMenu_Scene not found — Player List hook failed.")
  end

  # ===========================================
  # === Open Player List Scene (custom grid UI)
  # ===========================================
  def self.openPlayerList
    unless MultiplayerClient.instance_variable_get(:@connected)
      pbMessage(_INTL("You are not connected to any server."))
      return
    end

    MultiplayerUI.instance_variable_set(:@playerlist_open, true)
    MultiplayerUI.instance_variable_set(:@playerlist_close_requested, false)

    begin
      PlayerListGrid.new.run
    rescue Exception => e
      pbMessage(_INTL("Player List encountered an error and was closed."))
    ensure
      MultiplayerUI.instance_variable_set(:@playerlist_open, false)
    end
  end

  # =====================================================================
  # Shared blocking player context menu (reused by player list, chat, etc.)
  # Same visual as ChatWindow's context menu — dark popup with hover items.
  # Returns selected action index (0–6) or nil if cancelled.
  # =====================================================================
  CTX_ACTIONS = ["View Profile", "Send PM", "Invite to Squad",
                 "Battle Request", "Request Trade", "Inspect Party",
                 "Teleport to Player"]
  CTX_W       = 156
  CTX_ITEM_H  = 20
  CTX_PAD     = 4
  C_CTX_BG     = Color.new(35, 35, 42, 245)
  C_CTX_HOVER  = Color.new(60, 100, 180, 255)
  C_CTX_TEXT   = Color.new(210, 210, 220)
  C_CTX_BORDER = Color.new(80, 80, 95)
  C_CTX_HEADER = Color.new(70, 130, 200)

  # Show a blocking context menu at (screen_x, screen_y) for player `name`.
  # viewport: parent viewport (or nil to create a temporary one)
  # Returns action index 0..6 or nil.
  def self.player_context_menu(name, screen_x, screen_y, viewport = nil)
    items = CTX_ACTIONS
    ctx_h = CTX_PAD * 2 + 16 + items.length * CTX_ITEM_H
    sw = Graphics.width
    sh = Graphics.height

    own_vp = false
    unless viewport && !viewport.disposed?
      viewport = Viewport.new(0, 0, sw, sh)
      viewport.z = 100_000
      own_vp = true
    end

    menu_x = [[screen_x, 2].max, sw - CTX_W - 2].min
    menu_y = [[screen_y, 2].max, sh - ctx_h - 2].min

    ctx_spr = Sprite.new(viewport)
    ctx_spr.bitmap = Bitmap.new(CTX_W, ctx_h)
    ctx_spr.x = menu_x
    ctx_spr.y = menu_y
    ctx_spr.z = 200
    hover = nil

    _draw_ctx_menu(ctx_spr.bitmap, name, items, hover)

    result = nil
    loop do
      Graphics.update
      Input.update

      mx = (Input.mouse_x rescue nil)
      my = (Input.mouse_y rescue nil)

      old_hover = hover
      hover = nil
      if mx && my && mx >= menu_x && mx < menu_x + CTX_W
        items.each_with_index do |_label, i|
          iy = menu_y + CTX_PAD + 16 + i * CTX_ITEM_H
          if my >= iy && my < iy + CTX_ITEM_H
            hover = i
            break
          end
        end
      end
      _draw_ctx_menu(ctx_spr.bitmap, name, items, hover) if hover != old_hover

      if (Input.trigger?(Input::MOUSELEFT) rescue false)
        if hover
          result = hover
          pbSEPlay("GUI sel decision", 80) rescue nil
        end
        break
      end

      break if Input.trigger?(Input::BACK)
      break if (Input.trigger?(Input::MOUSERIGHT) rescue false)

      if Input.trigger?(Input::UP)
        hover = hover ? (hover - 1) % items.size : items.size - 1
        pbSEPlay("GUI sel cursor", 60) rescue nil
        _draw_ctx_menu(ctx_spr.bitmap, name, items, hover)
      elsif Input.trigger?(Input::DOWN)
        hover = hover ? (hover + 1) % items.size : 0
        pbSEPlay("GUI sel cursor", 60) rescue nil
        _draw_ctx_menu(ctx_spr.bitmap, name, items, hover)
      elsif Input.trigger?(Input::C) && hover
        result = hover
        pbSEPlay("GUI sel decision", 80) rescue nil
        break
      end
    end

    ctx_spr.bitmap.dispose rescue nil
    ctx_spr.dispose rescue nil
    viewport.dispose if own_vp rescue nil
    result
  end

  def self._draw_ctx_menu(bmp, name, items, hover)
    ctx_h = CTX_PAD * 2 + 16 + items.length * CTX_ITEM_H
    bmp.clear

    bmp.fill_rect(0, 0, CTX_W, ctx_h, C_CTX_BG)
    bmp.fill_rect(0, 0, CTX_W, 1, C_CTX_BORDER)
    bmp.fill_rect(0, ctx_h - 1, CTX_W, 1, C_CTX_BORDER)
    bmp.fill_rect(0, 0, 1, ctx_h, C_CTX_BORDER)
    bmp.fill_rect(CTX_W - 1, 0, 1, ctx_h, C_CTX_BORDER)

    pbSetSystemFont(bmp) if defined?(pbSetSystemFont)

    bmp.font.size  = 12
    bmp.font.bold  = true
    bmp.font.color = C_CTX_HEADER
    header = name.to_s
    header = header[0..14] + ".." if header.length > 16
    bmp.draw_text(CTX_PAD, CTX_PAD, CTX_W - CTX_PAD * 2, 14, header)
    bmp.fill_rect(CTX_PAD, CTX_PAD + 15, CTX_W - CTX_PAD * 2, 1, C_CTX_BORDER)

    bmp.font.bold = false
    bmp.font.size = 12
    items.each_with_index do |label, i|
      iy = CTX_PAD + 16 + i * CTX_ITEM_H
      if i == hover
        bmp.fill_rect(1, iy, CTX_W - 2, CTX_ITEM_H, C_CTX_HOVER)
        bmp.font.color = Color.new(255, 255, 255)
      else
        bmp.font.color = C_CTX_TEXT
      end
      bmp.draw_text(CTX_PAD + 2, iy + 2, CTX_W - CTX_PAD * 2 - 4, CTX_ITEM_H - 4, label)
    end
  end

  # =====================================================================
  # PlayerListGrid — 2×6 card grid with trainer sprites, GTS-style theme
  # =====================================================================
  class PlayerListGrid
    # ── Layout constants ──────────────────────────────────────────────
    GRID_COLS  = 2
    GRID_ROWS  = 6
    PER_PAGE   = GRID_COLS * GRID_ROWS  # 12
    CELL_W     = 220
    CELL_H     = 52
    CELL_PAD   = 4
    SPRITE_SZ  = 40   # scaled sprite inside cell

    # ── GTS color palette ─────────────────────────────────────────────
    BG_COLOR     = Color.new(20, 18, 30, 255)
    PANEL_BG     = Color.new(35, 32, 50)
    PANEL_BORDER = Color.new(80, 70, 110)
    CELL_BG      = Color.new(40, 36, 58)
    CELL_SEL     = Color.new(80, 65, 130)
    CELL_HOVER   = Color.new(60, 52, 90)
    CELL_SELF    = Color.new(50, 45, 70)
    WHITE        = Color.new(255, 255, 255)
    GRAY         = Color.new(180, 180, 180)
    DIM          = Color.new(120, 120, 140)
    TITLE_BAR_BG = Color.new(28, 25, 42)
    ACCENT       = Color.new(100, 80, 160)
    FOOTER_BG    = Color.new(28, 25, 42)
    FOOTER_SEL   = Color.new(100, 80, 160)
    PLAT_COLOR   = Color.new(220, 200, 255)

    TITLE_H    = 28
    FOOTER_H   = 44
    SCREEN_W   = Graphics.width
    SCREEN_H   = Graphics.height

    def initialize
      @viewport  = nil
      @sprites   = {}
      @cursor    = 0      # index within current page
      @page      = 0
      @entries   = []     # parsed: [{ sid:, name:, uuid:, sprite_data:, title_data: }, ...]
      @cell_bmps = []     # cached cell sprite bitmaps (disposed on page change)
      @hover_idx = -1     # mouse hover cell index
    end

    def run
      _setup_viewport
      _draw_bg
      _draw_header
      _draw_footer

      # Fetch player list
      players = _fetch_players
      unless players && !players.empty?
        _dispose_all
        pbMessage(_INTL("No player data received from server."))
        return
      end

      _build_entries(players)
      _draw_grid
      _draw_cursor

      closed_by_action = catch(:playerlist_closed) do
        loop do
          Graphics.update
          Input.update

          # F3 close
          if MultiplayerUI.instance_variable_get(:@playerlist_close_requested)
            MultiplayerUI.instance_variable_set(:@playerlist_close_requested, false)
            pbSEPlay("GUI menu close")
            break
          end

          break if Input.trigger?(Input::BACK)
          break if (Input.trigger?(Input::MOUSERIGHT) rescue false)

          _handle_keyboard
          _handle_mouse

          if Input.trigger?(Input::C) || _mouse_clicked_cell?
            _select_current
          end
        end
        false
      end

      # If closed via context action, the action handler already disposed sprites
      unless closed_by_action
        _dispose_all
        Graphics.update
      end
    end

    private

    # ── Fetch player list from server ─────────────────────────────────
    def _fetch_players
      MultiplayerClient.send_data("REQ_PLAYERS")
      start = Time.now
      players = nil
      while Time.now - start < 3.0
        Graphics.update
        Input.update
        players = MultiplayerClient.instance_variable_get(:@player_list)
        break if players && players.any?
      end
      players ||= MultiplayerClient.instance_variable_get(:@player_list)
      players
    end

    # ── Build structured entries ──────────────────────────────────────
    def _build_entries(raw_list)
      my_sid = (MultiplayerClient.session_id rescue nil)
      remote = MultiplayerClient.players rescue {}

      entries = raw_list.map do |raw|
        sid, name, uuid = MultiplayerUI.parse_player_entry(raw)
        next nil if sid.nil? || sid.empty?

        rd = remote[sid] || {}
        td = (MultiplayerClient.title_for(sid) rescue nil)
        appearance = MultiplayerUI.normalize_trainer_appearance(rd)

        {
          sid:         sid,
          name:        name || sid,
          uuid:        uuid,
          is_self:     (my_sid && sid == my_sid),
          clothes:     appearance[:clothes],
          hat:         appearance[:hat],
          hat2:        appearance[:hat2],
          hair:        appearance[:hair],
          skin_tone:   appearance[:skin_tone],
          hair_color:  appearance[:hair_color],
          hat_color:   appearance[:hat_color],
          hat2_color:  appearance[:hat2_color],
          clothes_color: appearance[:clothes_color],
          title_data:  td
        }
      end.compact
      @entries = MultiplayerUI.sort_player_entries(entries)
    end

    # ── Current page slice ────────────────────────────────────────────
    def _page_entries
      start = @page * PER_PAGE
      @entries[start, PER_PAGE] || []
    end

    def _total_pages
      [(@entries.size.to_f / PER_PAGE).ceil, 1].max
    end

    # ── Viewport ──────────────────────────────────────────────────────
    def _setup_viewport
      @viewport = Viewport.new(0, 0, SCREEN_W, SCREEN_H)
      @viewport.z = 99_999
    end

    # ── Background ────────────────────────────────────────────────────
    def _draw_bg
      bmp = Bitmap.new(SCREEN_W, SCREEN_H)
      bmp.fill_rect(0, 0, SCREEN_W, SCREEN_H, BG_COLOR)
      @sprites[:bg] = _spr(bmp, 0, 0)
    end

    # ── Header ────────────────────────────────────────────────────────
    def _draw_header
      bmp = Bitmap.new(SCREEN_W, TITLE_H)
      bmp.fill_rect(0, 0, SCREEN_W, TITLE_H, TITLE_BAR_BG)
      bmp.fill_rect(0, TITLE_H - 1, SCREEN_W, 1, ACCENT)
      pbSetSystemFont(bmp) if defined?(pbSetSystemFont)
      bmp.font.size  = 14
      bmp.font.bold  = true
      bmp.font.color = PLAT_COLOR
      bmp.draw_text(12, 4, 300, 20, "PLAYER LIST", 0)
      @sprites[:header] = _spr(bmp, 0, 0)
    end

    # ── Footer ────────────────────────────────────────────────────────
    def _draw_footer
      bmp = Bitmap.new(SCREEN_W, FOOTER_H)
      bmp.fill_rect(0, 0, SCREEN_W, FOOTER_H, FOOTER_BG)
      bmp.fill_rect(0, 0, SCREEN_W, 1, Color.new(80, 70, 110, 120))
      bmp.fill_rect(0, 21, SCREEN_W, 1, Color.new(80, 70, 110, 90))
      pbSetSystemFont(bmp) if defined?(pbSetSystemFont)
      bmp.font.size  = 11
      bmp.font.bold  = false
      bmp.font.color = DIM
      bmp.draw_text(12, 4, 340, 16, "[Z/Click] Select   [X/Right-Click] Close", 0)
      @sprites[:footer] = _spr(bmp, 0, SCREEN_H - FOOTER_H)
      _update_page_indicator
      _update_footer_detail
    end

    def _update_page_indicator
      spr = @sprites[:footer]
      return unless spr && spr.bitmap && !spr.bitmap.disposed?
      bmp = spr.bitmap
      # Clear right side only (page text area)
      bmp.fill_rect(SCREEN_W - 190, 0, 190, 21, FOOTER_BG)
      bmp.fill_rect(SCREEN_W - 190, 0, 190, 1, Color.new(80, 70, 110, 120))
      pbSetSystemFont(bmp) if defined?(pbSetSystemFont)
      bmp.font.size  = 11
      bmp.font.bold  = false
      if _total_pages > 1
        bmp.font.color = GRAY
        bmp.draw_text(0, 4, SCREEN_W - 12, 16, "Page #{@page + 1}/#{_total_pages}  [<//>] Navigate", 2)
      else
        bmp.font.color = DIM
        bmp.draw_text(0, 4, SCREEN_W - 12, 16, "#{@entries.size} player#{"s" if @entries.size != 1} online", 2)
      end
    end

    def _update_footer_detail
      spr = @sprites[:footer]
      return unless spr && spr.bitmap && !spr.bitmap.disposed?
      bmp = spr.bitmap
      bmp.fill_rect(0, 22, SCREEN_W, FOOTER_H - 22, FOOTER_BG)
      pbSetSystemFont(bmp) if defined?(pbSetSystemFont)
      bmp.font.size = 10
      bmp.font.bold = false

      entry = _page_entries[@cursor] rescue nil
      if entry
        presence = MultiplayerUI.player_presence_text(
          MultiplayerUI.runtime_player_state_for_sid(entry[:sid]),
          include_ping: true
        )
        detail = "Selected: #{entry[:name]}"
        detail += " • #{presence}" if presence && !presence.empty?
        bmp.font.color = GRAY
        bmp.draw_text(12, 24, SCREEN_W - 24, 14, detail, 0)
      else
        bmp.font.color = DIM
        bmp.draw_text(12, 24, SCREEN_W - 24, 14, "Fetching player data...", 0)
      end
    end

    # ── Grid ──────────────────────────────────────────────────────────
    GRID_PAD_X = 12   # left margin
    GRID_PAD_Y = 6    # top margin below header

    def _grid_origin
      gx = GRID_PAD_X
      gy = TITLE_H + GRID_PAD_Y
      [gx, gy]
    end

    def _draw_grid
      _clear_cells
      entries = _page_entries
      gx, gy = _grid_origin

      entries.each_with_index do |entry, i|
        col = i % GRID_COLS
        row = i / GRID_COLS
        cx = gx + col * (CELL_W + CELL_PAD)
        cy = gy + row * (CELL_H + CELL_PAD)

        selected = (i == @cursor)
        hovered  = (i == @hover_idx && !selected)
        cell_bmp = _render_cell(entry, selected, hovered)
        spr = _spr(cell_bmp, cx, cy)
        spr.z = 10
        @sprites["cell_#{i}".to_sym] = spr
        @cell_bmps << cell_bmp
      end

      # Draw empty cells for remaining slots
      (entries.size...PER_PAGE).each do |i|
        col = i % GRID_COLS
        row = i / GRID_COLS
        cx = gx + col * (CELL_W + CELL_PAD)
        cy = gy + row * (CELL_H + CELL_PAD)
        cell_bmp = _render_empty_cell
        spr = _spr(cell_bmp, cx, cy)
        spr.z = 10
        @sprites["cell_#{i}".to_sym] = spr
        @cell_bmps << cell_bmp
      end

      _draw_cursor
    end

    def _render_cell(entry, selected, hovered)
      bmp = Bitmap.new(CELL_W, CELL_H)

      # Background
      bg = if selected
             CELL_SEL
           elsif hovered
             CELL_HOVER
           elsif entry[:is_self]
             CELL_SELF
           else
             CELL_BG
           end
      border = selected ? ACCENT : PANEL_BORDER
      bmp.fill_rect(0, 0, CELL_W, CELL_H, border)
      bmp.fill_rect(1, 1, CELL_W - 2, CELL_H - 2, bg)

      # Left accent bar (purple for self, subtle for others)
      accent = entry[:is_self] ? Color.new(200, 180, 60, 200) : Color.new(80, 70, 140, 150)
      bmp.fill_rect(1, 1, 3, CELL_H - 2, accent)

      # Trainer sprite (front-facing, same as coop wait screen)
      full_bmp = _build_trainer_sprite(entry)
      drawn = _draw_sprite_into(bmp, full_bmp, 6, 2, SPRITE_SZ, CELL_H - 4)
      full_bmp.dispose if full_bmp && !full_bmp.disposed? rescue nil
      _draw_placeholder(bmp, 10, 6) unless drawn

      # Text area (right of sprite)
      text_x = 50
      text_w = CELL_W - text_x - 6
      state = MultiplayerUI.runtime_player_state_for_sid(entry[:sid])
      fallback_map_id = entry[:is_self] ? (MultiplayerUI.local_runtime_position[:map] rescue 0) : 0
      location_text = MultiplayerUI.player_map_text(state, fallback_map_id)
      pbSetSystemFont(bmp) if defined?(pbSetSystemFont)

      # Name
      bmp.font.size  = 14
      bmp.font.bold  = true
      bmp.font.color = WHITE
      name_str = entry[:name].to_s
      name_str += "  (You)" if entry[:is_self]
      bmp.draw_text(text_x, 2, text_w, 18, name_str, 0)

      # Title
      td = entry[:title_data]
      bmp.font.size  = 11
      bmp.font.bold  = false
      if td.is_a?(Hash) && !td["name"].to_s.empty?
        if td["gilded"]
          tw = (bmp.text_size(td["name"].to_s).width rescue td["name"].to_s.length * 7)
          gt = Time.now.to_f
          _draw_gilded_plate(bmp, text_x - 2, 18, tw + 4, 14, gt)
          bmp.font.color = Color.new(15, 10, 0, 255)
          bmp.draw_text(text_x, 18, text_w, 14, td["name"].to_s, 0)
        else
          bmp.font.color = _title_color(td)
          bmp.draw_text(text_x, 18, text_w, 14, td["name"].to_s, 0)
        end
      else
        bmp.font.color = DIM
        bmp.draw_text(text_x, 18, text_w, 14, "No title", 0)
      end

      # Map location
      bmp.font.size  = 10
      bmp.font.bold  = false
      bmp.font.color = if state && state[:same_map]
                         Color.new(180, 204, 230)
                       elsif location_text == "Location unavailable"
                         DIM
                       else
                         Color.new(150, 146, 180)
                       end
      bmp.draw_text(text_x, 32, text_w, 12, location_text, 0)

      # SID + ping indicator (right-aligned)
      ping_str = (MultiplayerUI.ping_text_for(entry[:sid]) rescue nil)
      sid_label = ping_str ? "#{entry[:sid]}  #{ping_str}" : entry[:sid]
      bmp.font.size  = 11
      bmp.font.bold  = false
      bmp.font.color = Color.new(110, 100, 145)
      bmp.draw_text(0, 4, CELL_W - 6, 16, sid_label, 2)

      bmp
    end

    def _render_empty_cell
      bmp = Bitmap.new(CELL_W, CELL_H)
      bmp.fill_rect(0, 0, CELL_W, CELL_H, Color.new(30, 27, 42, 150))
      bmp.fill_rect(1, 1, CELL_W - 2, CELL_H - 2, Color.new(25, 22, 36, 120))
      bmp
    end

    # ── Build trainer sprite bitmap (same approach as CoopTrainerWaitScreen) ──
    def _build_trainer_sprite(entry)
      return nil unless defined?(generateClothedBitmapStatic)

      full_bmp = if entry[:is_self]
        # Use local $Trainer directly (includes current outfit)
        generateClothedBitmapStatic($Trainer, "walk") rescue nil
      else
        return nil unless defined?(RemoteTrainer)
        rt = RemoteTrainer.new(
          entry[:clothes], entry[:hat], entry[:hat2], entry[:hair],
          entry[:skin_tone], entry[:hair_color],
          entry[:hat_color], entry[:hat2_color], entry[:clothes_color]
        )
        generateClothedBitmapStatic(rt, "walk") rescue nil
      end
      full_bmp
    rescue
      nil
    end

    # ── Draw trainer sprite into cell bitmap (front-facing, native size) ─
    def _draw_sprite_into(bmp, full_bmp, target_x, target_y, target_w, target_h)
      return false unless full_bmp && !full_bmp.disposed?

      # Extract front-facing frame (column 1, row 0) — same as overworld
      char_w = full_bmp.width  / 4
      char_h = full_bmp.height / 4
      src_rect = Rect.new(char_w, 0, char_w, char_h)

      # Draw at native size (1:1, same as overworld), centered in target area
      ox = target_x + (target_w - char_w) / 2
      oy = target_y + (target_h - char_h) / 2
      bmp.blt(ox, oy, full_bmp, src_rect)
      true
    rescue
      false
    end

    # ── Placeholder silhouette ────────────────────────────────────────
    def _draw_placeholder(bmp, x, y)
      c = Color.new(100, 85, 140, 160)
      # Head
      bmp.fill_rect(x + 8,  y,      16, 2,  c)
      bmp.fill_rect(x + 6,  y + 2,  20, 10, c)
      bmp.fill_rect(x + 8,  y + 12, 16, 2,  c)
      # Body
      bmp.fill_rect(x + 4,  y + 15, 24, 16, c)
      # Legs
      bmp.fill_rect(x + 6,  y + 31, 8,  5,  c)
      bmp.fill_rect(x + 18, y + 31, 8,  5,  c)
    end

    # ── Gilded gold bar with pulsing glow (opaque) ──────
    def _draw_gilded_plate(bmp, x, y, w, h, phase)
      ph = phase % 100.0
      p1 = (Math.sin(ph * 2.5) + 1.0) / 2.0
      p2 = (Math.sin(ph * 1.1 + 1.2) + 1.0) / 2.0
      glow = p1 * 0.6 + p2 * 0.4
      br = (30 + glow * 45).to_i; bg = (22 + glow * 38).to_i
      bmp.fill_rect(x, y, w, h, Color.new(br, bg, 5))
      tr = (160 + glow * 95).to_i; tg = (130 + glow * 80).to_i; tb = (25 + glow * 45).to_i
      bmp.fill_rect(x + 1, y, w - 2, 1, Color.new(tr, tg, tb))
      bmp.fill_rect(x + 1, y + 1, w - 2, 1, Color.new(tr - 50, tg - 40, [tb - 10, 0].max))
      bmp.fill_rect(x + 1, y + h - 2, w - 2, 1, Color.new((65 + glow * 30).to_i, (50 + glow * 22).to_i, 12))
      bmp.fill_rect(x + 1, y + h - 1, w - 2, 1, Color.new(35, 25, 8))
      bmp.fill_rect(x, y + 1, 1, h - 2, Color.new((140 + glow * 60).to_i, (115 + glow * 50).to_i, (20 + glow * 25).to_i))
      bmp.fill_rect(x + w - 1, y + 1, 1, h - 2, Color.new((85 + glow * 35).to_i, (60 + glow * 28).to_i, 15))
      inner_x = x + 2; inner_w = w - 4; mid_y = y + h / 2
      (2...h - 2).each do |dy|
        py = y + dy; dist = (py - mid_y).abs.to_f / (h / 2.0)
        bright = (1.0 - dist) * (0.5 + glow * 0.5)
        r = (100 + bright * 130).to_i.clamp(0, 240)
        g = (75 + bright * 105).to_i.clamp(0, 190)
        b = (10 + bright * 25).to_i.clamp(0, 40)
        bmp.fill_rect(inner_x, py, inner_w, 1, Color.new(r, g, b))
      end
      cr = (200 + glow * 55).to_i; cg = (170 + glow * 50).to_i
      bmp.fill_rect(x + 1, y + 1, 2, 2, Color.new(cr, cg, 45))
      bmp.fill_rect(x + w - 3, y + 1, 2, 2, Color.new(cr, cg, 45))
      bmp.fill_rect(x + 1, y + h - 3, 2, 2, Color.new((160 + glow * 40).to_i, (130 + glow * 35).to_i, 30))
      bmp.fill_rect(x + w - 3, y + h - 3, 2, 2, Color.new((160 + glow * 40).to_i, (130 + glow * 35).to_i, 30))
    end

    # ── Title color helper ────────────────────────────────────────────
    def _title_color(td)
      return GRAY unless td.is_a?(Hash)
      c1 = td["color1"] || [255, 255, 255]
      Color.new(c1[0].to_i, c1[1].to_i, c1[2].to_i)
    rescue
      GRAY
    end

    # ── Cursor ────────────────────────────────────────────────────────
    def _draw_cursor
      entries = _page_entries
      return if entries.empty?

      @cursor = @cursor.clamp(0, [entries.size - 1, 0].max)

      # Redraw all cells to reflect selection state
      gx, gy = _grid_origin
      entries.each_with_index do |entry, i|
        spr = @sprites["cell_#{i}".to_sym]
        next unless spr && !spr.disposed?
        selected = (i == @cursor)
        hovered  = (i == @hover_idx && !selected)
        old_bmp = spr.bitmap
        new_bmp = _render_cell(entry, selected, hovered)
        spr.bitmap = new_bmp
        old_bmp.dispose if old_bmp && !old_bmp.disposed?
      end
      _update_footer_detail
    end

    # ── Keyboard input ────────────────────────────────────────────────
    def _handle_keyboard
      entries = _page_entries
      return if entries.empty?
      old = @cursor

      if Input.trigger?(Input::RIGHT)
        if @cursor % GRID_COLS < GRID_COLS - 1 && @cursor + 1 < entries.size
          @cursor += 1
        end
      elsif Input.trigger?(Input::LEFT)
        @cursor -= 1 if @cursor % GRID_COLS > 0
      elsif Input.trigger?(Input::DOWN)
        new_c = @cursor + GRID_COLS
        if new_c < entries.size
          @cursor = new_c
        elsif _total_pages > 1
          # Next page
          _change_page(@page + 1)
          return
        end
      elsif Input.trigger?(Input::UP)
        new_c = @cursor - GRID_COLS
        if new_c >= 0
          @cursor = new_c
        elsif _total_pages > 1 && @page > 0
          # Previous page
          _change_page(@page - 1)
          return
        end
      end

      if @cursor != old
        pbSEPlay("GUI sel cursor", 60) rescue nil
        _draw_cursor
      end
    end

    # ── Mouse input ───────────────────────────────────────────────────
    def _handle_mouse
      mx = (Input.mouse_x rescue nil)
      my = (Input.mouse_y rescue nil)
      return unless mx && my

      entries = _page_entries
      gx, gy = _grid_origin
      old_hover = @hover_idx
      @hover_idx = -1

      entries.each_with_index do |_entry, i|
        col = i % GRID_COLS
        row = i / GRID_COLS
        cx = gx + col * (CELL_W + CELL_PAD)
        cy = gy + row * (CELL_H + CELL_PAD)

        if mx >= cx && mx < cx + CELL_W && my >= cy && my < cy + CELL_H
          @hover_idx = i
          # Move cursor to hovered cell
          if @cursor != i
            @cursor = i
            pbSEPlay("GUI sel cursor", 60) rescue nil
          end
          break
        end
      end

      _draw_cursor if @hover_idx != old_hover
    end

    @_mouse_clicked = false
    def _mouse_clicked_cell?
      return false unless (Input.trigger?(Input::MOUSELEFT) rescue false)
      @hover_idx >= 0 && @hover_idx == @cursor
    end

    # ── Page navigation ───────────────────────────────────────────────
    def _change_page(new_page)
      new_page = new_page % _total_pages
      @page = new_page
      @cursor = 0
      @hover_idx = -1
      _draw_grid
      _update_page_indicator
      pbSEPlay("GUI sel cursor", 60) rescue nil
    end

    # ── Select current player ──────────────────────────────────────
    # Delegates to the chat window's persistent context menu (same
    # code path as right-clicking a SID in chat), which is the only
    # flow that reliably runs in the normal game loop and lets modals
    # (PM, squad invite, battle, trade, inspect party) overlay correctly.
    def _select_current
      entries = _page_entries
      return if entries.empty? || @cursor < 0 || @cursor >= entries.size

      entry = entries[@cursor]
      return unless entry

      pbSEPlay("GUI sel decision", 80) rescue nil

      sid  = entry[:sid]
      name = entry[:name]
      uuid = entry[:uuid]

      # Position menu next to the selected cell (screen coords)
      gx, gy = _grid_origin
      col = @cursor % GRID_COLS
      row = @cursor / GRID_COLS
      scx = gx + col * (CELL_W + CELL_PAD) + CELL_W + 4
      scy = gy + row * (CELL_H + CELL_PAD)

      # Self: only "View Profile" is meaningful — open directly.
      if entry[:is_self]
        if defined?(MultiplayerUI::ProfilePanel)
          _dispose_all
          MultiplayerUI.instance_variable_set(:@playerlist_open, false)
          MultiplayerUI::ProfilePanel.open(uuid: "self") rescue nil
          throw(:playerlist_closed, true)
        end
        return
      end

      # Close the player list first so the chat's update loop resumes
      # and the chat context menu can render on top of the overworld.
      _dispose_all
      MultiplayerUI.instance_variable_set(:@playerlist_open, false)

      # Delegate to the chat's persistent, non-blocking context menu.
      # ChatInputHotkeys.handle_mouse (called every frame) will pick up
      # the click/hover and invoke _execute_ctx_action exactly as it
      # does when right-clicking a SID in chat.
      if $chat_window && $chat_window.respond_to?(:open_context_menu)
        $chat_window.open_context_menu(sid, name, scx, scy) rescue nil
      end

      throw(:playerlist_closed, true)
    end

    # ── Sprite helper ─────────────────────────────────────────────────
    def _spr(bmp, x, y)
      s = Sprite.new(@viewport)
      s.bitmap = bmp
      s.x = x; s.y = y
      s
    end

    # ── Cleanup ───────────────────────────────────────────────────────
    def _clear_cells
      PER_PAGE.times do |i|
        key = "cell_#{i}".to_sym
        spr = @sprites.delete(key)
        next unless spr
        spr.bitmap.dispose if spr.bitmap && !spr.bitmap.disposed?
        spr.dispose rescue nil
      end
      @cell_bmps.each { |b| b.dispose if b && !b.disposed? rescue nil }
      @cell_bmps.clear
    end

    def _dispose_all
      @sprites.each_value do |s|
        next unless s
        s.bitmap.dispose if s.bitmap && !s.bitmap.disposed? rescue nil
        s.dispose rescue nil
      end
      @sprites.clear
      @cell_bmps.each { |b| b.dispose if b && !b.disposed? rescue nil }
      @cell_bmps.clear
      @viewport.dispose if @viewport && !@viewport.disposed? rescue nil
    end
  end

  def self.player_presence_text(state, include_ping: true, prefix_online: false)
    return nil unless state.is_a?(Hash)
    parts = []
    parts << "Online" if prefix_online

    location = if state[:same_map]
      dist = state[:distance]
      (dist && dist > 0) ? "#{dist} tiles away" : "Same map"
    elsif state[:map].to_i > 0
      "Map #{state[:map].to_i}"
    else
      "Live status"
    end

    parts << location unless location.to_s.empty?
    parts << "Busy" if state[:busy]
    parts << "#{state[:ping]}ms" if include_ping && state[:ping]
    parts.join(" | ")
  rescue
    nil
  end

  class PlayerListGrid
    private

    def _update_footer_detail
      spr = @sprites[:footer]
      return unless spr && spr.bitmap && !spr.bitmap.disposed?
      bmp = spr.bitmap
      bmp.fill_rect(0, 22, SCREEN_W, FOOTER_H - 22, FOOTER_BG)
      pbSetSystemFont(bmp) if defined?(pbSetSystemFont)
      bmp.font.size = 10
      bmp.font.bold = false

      entry = _page_entries[@cursor] rescue nil
      if entry
        presence = MultiplayerUI.player_presence_text(
          MultiplayerUI.runtime_player_state_for_sid(entry[:sid]),
          include_ping: true
        )
        detail = "Selected: #{entry[:name]}"
        detail += " - #{presence}" if presence && !presence.empty?
        bmp.font.color = GRAY
        bmp.draw_text(12, 24, SCREEN_W - 24, 14, detail, 0)
      else
        bmp.font.color = DIM
        bmp.draw_text(12, 24, SCREEN_W - 24, 14, "Fetching player data...", 0)
      end
    end
  end
end
