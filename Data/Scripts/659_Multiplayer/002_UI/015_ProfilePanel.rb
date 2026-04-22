# ===========================================
# File: 015_ProfilePanel.rb
# Purpose: Floating centered profile overlay panel.
#          Shows stats, title, and sprite for any player (own or others).
#          Toggled with F8; also opened from the Player List.
#          Non-blocking overlay — drawn every frame via Scene_Map hook.
# ===========================================

if defined?(Scene_Map)

  module MultiplayerUI
    module ProfilePanel

      # ── Panel dimensions ─────────────────────────────────────────
      PANEL_W   = 330
      PANEL_H   = 260
      SPRITE_W  = 32
      SPRITE_H  = 48

      # ── State ────────────────────────────────────────────────────
      @open          = false
      @loading       = false
      @target_uuid   = nil   # UUID of the profile being shown
      @data          = nil   # Last received PROFILE_DATA hash
      @request_time  = nil   # Time.now when request was sent
      @fetch_time    = nil   # Time when PROFILE_DATA was received
      REQUEST_TIMEOUT = 4.0  # seconds before showing "No response"
      PALLET_TOWN_FALLBACK_HEALSPOT = [42, 12, 10]

      # Sprite resources (created on first open, disposed on panel close)
      @viewport      = nil
      @panel_spr     = nil
      @sprite_bmp    = nil   # trainer sprite bitmap (static frame)
      # Title animation (gradient phase)
      @title_phase   = 0.0

      # Mouse hover state for action buttons
      @btn_hovered   = false
      @return_btn_hovered = false
      @convert_btn_hovered = false

      # Cache: keyed by UUID, stores { data:, sprite_bmp:, fetch_time: }
      @cache         = {}

      # ── Public API ───────────────────────────────────────────────

      def self.open?; @open; end

      # Open the panel targeting a specific UUID ("self" or a platinum_uuid).
      def self.open(uuid: "self")
        return unless defined?(MultiplayerClient) && MultiplayerClient.session_id
        return if ($game_temp&.in_menu   rescue false)
        if defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:overlay_scene_type)
          return if MultiplayerUI.overlay_scene_type.nil?
        end

        uuid = MultiplayerClient.platinum_uuid || "self" if uuid == "self" || uuid.to_s.empty?

        @target_uuid  = uuid.to_s
        @open         = true
        @title_phase  = 0.0
        @request_time = Time.now

        # Use cached data if available — show immediately, refresh in background
        cached = @cache[@target_uuid]
        if cached
          @data       = cached[:data]
          @fetch_time = cached[:fetch_time]
          @loading    = true  # still fetch fresh data in background
          _dispose_sprite_bmp
          @sprite_bmp = cached[:sprite_bmp]  # reuse cached sprite bitmap
        else
          @data       = nil
          @fetch_time = nil
          @loading    = true
          _dispose_sprite_bmp
        end

        MultiplayerClient.request_profile(@target_uuid)
        _ensure_viewport
        _redraw
      end

      def self.close
        # Cache current data for instant re-open
        if @target_uuid && @data
          @cache[@target_uuid] = {
            data: @data,
            sprite_bmp: @sprite_bmp,
            fetch_time: @fetch_time
          }
          @sprite_bmp = nil  # prevent _dispose_panel from disposing cached bitmap
        end
        @open    = false
        @loading = false
        @data    = nil
        @btn_hovered = false
        @return_btn_hovered = false
        @convert_btn_hovered = false
        _dispose_panel
      end

      def self.toggle(uuid: "self")
        if @open && @target_uuid == (uuid == "self" ? (MultiplayerClient.platinum_uuid || "self") : uuid)
          close
        else
          close  # close any existing panel first
          open(uuid: uuid)
        end
      end

      # Called every frame from Scene_Map.update hook.
      def self.tick
        return unless @open

        # Right-click anywhere to close
        if (Input.trigger?(Input::MOUSERIGHT) rescue false)
          close
          return
        end

        # Poll for PROFILE_DATA response
        if @loading
          pd = MultiplayerClient.pop_profile_data rescue nil
          if pd.is_a?(Hash)
            @data       = pd
            @loading    = false
            @fetch_time = Time.now
            _dispose_sprite_bmp
            _build_sprite_bmp(_resolve_sprite_data(@data))
            # Update cache with fresh data
            @cache[@target_uuid] = {
              data: @data,
              sprite_bmp: @sprite_bmp,
              fetch_time: @fetch_time
            }
            _redraw
          elsif @request_time && (Time.now - @request_time) > REQUEST_TIMEOUT
            @loading = false  # Show timeout state
            _redraw
          end
        end

        # Advance gradient animation (gradient/tricolor need full redraw)
        td = @data && @data["active_title"]
        if td.is_a?(Hash)
          if td["effect"] == "gradient" || td["effect"] == "tricolor"
            speed = (td["speed"] || 0.3).to_f
            @title_phase += speed / 60.0
            _redraw
          elsif td["gilded"]
            _redraw
          end
        end

        # Change Title button — Z/C key or mouse click, only on own profile
        if !@loading && @data
          my_uuid = (MultiplayerClient.platinum_uuid rescue nil)
          mouse_clicked = (Input.trigger?(Input::MOUSELEFT) rescue false)
          if my_uuid && @target_uuid == my_uuid
            # Mouse hover + click
            _handle_btn_mouse(my_uuid)
            # Keyboard
            if !mouse_clicked && Input.trigger?(Input::C)
              _handle_change_title
            end
          else
            if @btn_hovered
              @btn_hovered = false
              _redraw
            end
          end
        end

        # Guard: close if we go into battle or menu
        scene_ok = if defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:overlay_scene_active?)
                     MultiplayerUI.overlay_scene_active? ||
                       (MultiplayerUI.respond_to?(:ui_show_on_all_screens?) && MultiplayerUI.ui_show_on_all_screens?)
                   else
                     !($game_temp&.in_menu rescue false)
                   end
        close unless scene_ok
      end

      # ── Private ──────────────────────────────────────────────────

      def self._ensure_viewport
        return if @viewport && !@viewport.disposed?
        @viewport   = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_400
      end

      def self._dispose_panel
        begin
          if @panel_spr && !@panel_spr.disposed?
            @panel_spr.bitmap.dispose rescue nil
            @panel_spr.dispose
          end
        rescue; end
        begin
          @viewport.dispose if @viewport && !@viewport.disposed?
        rescue; end
        @panel_spr = nil
        @viewport  = nil
        _dispose_sprite_bmp
      end


      def self._dispose_sprite_bmp
        begin
          @sprite_bmp.dispose if @sprite_bmp && !@sprite_bmp.disposed?
        rescue; end
        @sprite_bmp = nil
      end

      def self._resolve_sprite_data(pd)
        return nil unless pd.is_a?(Hash)
        if defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:profile_sprite_data)
          return MultiplayerUI.profile_sprite_data(@target_uuid, pd)
        end
        sd = pd["sprite_data"]
        sd.is_a?(Hash) ? sd : nil
      rescue
        nil
      end

      def self._presence_lines
        state = nil
        if defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:runtime_player_state_for_uuid)
          state = MultiplayerUI.runtime_player_state_for_uuid(@target_uuid)
        end
        return ["Live status", "Unavailable", nil] unless state

        line1 = state[:busy] ? "Online • Busy" : "Online"
        line2 = if state[:same_map]
          dist = state[:distance]
          (dist && dist > 0) ? "#{dist} tiles away" : "Same map"
        elsif state[:map].to_i > 0
          "Map #{state[:map].to_i}"
        else
          "Live status"
        end

        extras = []
        extras << "#{state[:ping]}ms" if state[:ping]
        [line1, line2, extras.empty? ? nil : extras.join(" • ")]
      rescue
        ["Live status", "Unavailable", nil]
      end

      # Try to build a trainer sprite bitmap from sprite_data hash.
      def self._build_sprite_bmp(sd)
        if defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:normalize_trainer_appearance)
          sd = MultiplayerUI.normalize_trainer_appearance(sd)
        end
        return unless sd.is_a?(Hash) && defined?(generateClothedBitmapStatic) && defined?(RemoteTrainer)
        remote_trainer = RemoteTrainer.new(
          (sd[:clothes] || sd["clothes"] || "001").to_s,
          (sd[:hat] || sd["hat"] || "000").to_s,
          (sd[:hat2] || sd["hat2"] || "000").to_s,
          (sd[:hair] || sd["hair"] || "000").to_s,
          (sd[:skin_tone] || sd["skin_tone"]).to_i,
          (sd[:hair_color] || sd["hair_color"]).to_i,
          (sd[:hat_color] || sd["hat_color"]).to_i,
          (sd[:hat2_color] || sd["hat2_color"]).to_i,
          (sd[:clothes_color] || sd["clothes_color"]).to_i
        )
        @sprite_bmp = generateClothedBitmapStatic(remote_trainer, "walk")
      rescue => e
        ##MultiplayerDebug.warn("PROFILE-PANEL", "Sprite build failed: #{e.message}")
        @sprite_bmp = nil
      end

      # Draw (or redraw) the full panel bitmap.
      def self._redraw
        return unless @viewport && !@viewport.disposed?

        sw = Graphics.width
        sh = Graphics.height
        px = (sw - PANEL_W) / 2
        py = (sh - PANEL_H) / 2

        if @panel_spr.nil? || @panel_spr.disposed?
          @panel_spr   = Sprite.new(@viewport)
          @panel_spr.x = px
          @panel_spr.y = py
          @panel_spr.z = 100
        end

        if @panel_spr.bitmap.nil? || @panel_spr.bitmap.disposed? ||
           @panel_spr.bitmap.width != PANEL_W || @panel_spr.bitmap.height != PANEL_H
          @panel_spr.bitmap.dispose rescue nil
          @panel_spr.bitmap = Bitmap.new(PANEL_W, PANEL_H)
        else
          @panel_spr.bitmap.clear
        end

        bmp = @panel_spr.bitmap

        # ── Background ───────────────────────────────────────────
        bg_color  = Color.new(15, 10, 25, 255)    # dark purple-black (fully opaque)
        brd_color = Color.new(130, 70, 200, 255)   # violet border (fully opaque)
        bmp.fill_rect(0, 0, PANEL_W, PANEL_H, brd_color)
        bmp.fill_rect(2, 2, PANEL_W - 4, PANEL_H - 4, bg_color)

        # ── Header bar ───────────────────────────────────────────
        hdr_color = Color.new(80, 35, 140, 230)
        bmp.fill_rect(2, 2, PANEL_W - 4, 20, hdr_color)
        bmp.font.size  = 13
        bmp.font.bold  = true
        bmp.font.color = Color.new(200, 160, 255)
        bmp.draw_text(5, 3, PANEL_W - 30, 16, "PROFILE", 0)
        # Close hint
        bmp.font.size  = 10
        bmp.font.bold  = false
        bmp.font.color = Color.new(140, 110, 180)
        bmp.draw_text(5, 3, PANEL_W - 8, 16, "[F8 / Esc]", 2)

        if @loading && (@request_time.nil? || (Time.now - @request_time) <= REQUEST_TIMEOUT)
          # ── Loading state ──────────────────────────────────────
          bmp.font.size  = 13
          bmp.font.bold  = false
          bmp.font.color = Color.new(180, 160, 220)
          dots = "." * ((Time.now.to_i % 3) + 1)
          bmp.draw_text(0, PANEL_H / 2 - 8, PANEL_W, 20, "Loading#{dots}", 1)
        elsif @data.nil?
          # ── Timeout / no data ─────────────────────────────────
          bmp.font.size  = 12
          bmp.font.color = Color.new(180, 100, 100)
          bmp.draw_text(0, PANEL_H / 2 - 8, PANEL_W, 20, "No response from server.", 1)
        else
          _draw_profile(bmp)
        end
      rescue => e
        ##MultiplayerDebug.error("PROFILE-PANEL", "Redraw error: #{e.message}")
      end

      # Draw the actual profile content once @data is available.
      def self._draw_profile(bmp)
        d = @data

        # ── Layout ───────────────────────────────────────────────
        # Three columns in the top band (all share y=26, height=SPRITE_H):
        #   Left  (x=8,  w=80):  Name + Title stacked
        #   Mid   (x=92, w=32):  Trainer sprite
        #   Right (x=130,w=134): Change Title button
        # Thick divider below the band, then stats.
        row_y     = 26
        top_h     = SPRITE_H          # 48
        left_x    = 8
        left_w    = 80
        sprite_x  = left_x + left_w + 4 - 25  # 67 — eats 25px into left transparent padding
        sprite_y  = row_y - 5                  # 21 — eats 5px into top transparent padding
        btn_x     = sprite_x + SPRITE_W + 6 + 30  # 135 — shrunk 30px from left
        btn_w     = PANEL_W - btn_x - 6           # 129
        btn_h     = top_h + 30                    # 78 — expanded 30px downward
        div_y     = row_y + top_h + 8 + 30    # 112 — lowered 30px for breathing room
        my_uuid   = (MultiplayerClient.platinum_uuid rescue nil)
        is_own    = _own_profile_target?

        # ── Name (left, top of band) ──────────────────────────────
        name_str = (d["name"] || "Unknown").to_s
        bmp.font.size  = 14
        bmp.font.bold  = true
        bmp.font.color = Color.new(0, 0, 0, 130)
        bmp.draw_text(left_x + 1, row_y + 1, left_w, 20, name_str, 0)
        bmp.font.color = Color.new(255, 255, 255)
        bmp.draw_text(left_x,     row_y,     left_w, 20, name_str, 0)

        # ── Title (left, below name) ──────────────────────────────
        title_y = row_y + 22
        td = d["active_title"]
        if td.is_a?(Hash) && !td["name"].to_s.empty?
          title_str   = td["name"].to_s
          bmp.font.size  = 10
          bmp.font.bold  = false
          if td["gilded"]
            tw = (bmp.text_size(title_str).width rescue title_str.length * 7)
            _draw_gilded_plate(bmp, left_x - 2, title_y, tw + 4, 14, Time.now.to_f)
            bmp.font.color = Color.new(15, 10, 0, 255)
            bmp.draw_text(left_x, title_y, left_w, 14, title_str, 0)
          else
            title_color = _panel_title_color(td)
            bmp.font.color = Color.new(0, 0, 0, 110)
            bmp.draw_text(left_x + 1, title_y + 1, left_w, 14, title_str, 0)
            bmp.font.color = title_color
            bmp.draw_text(left_x,     title_y,     left_w, 14, title_str, 0)
          end
        else
          bmp.font.size  = 10
          bmp.font.bold  = false
          bmp.font.color = Color.new(90, 75, 120)
          bmp.draw_text(left_x, title_y, left_w, 14, "No title", 0)
        end

        # ── Trainer sprite (middle column) ────────────────────────
        if @sprite_bmp && !@sprite_bmp.disposed?
          frame_w = (@sprite_bmp.width  / 4 rescue SPRITE_W)
          frame_h = (@sprite_bmp.height / 4 rescue SPRITE_H)
          bmp.blt(sprite_x, sprite_y, @sprite_bmp, Rect.new(frame_w, 0, frame_w, frame_h))
        else
          ph = Color.new(100, 80, 140, 180)
          bmp.fill_rect(sprite_x + 8,  sprite_y,      16,  2, ph)
          bmp.fill_rect(sprite_x + 6,  sprite_y +  2, 20, 12, ph)
          bmp.fill_rect(sprite_x + 8,  sprite_y + 14, 16,  2, ph)
          bmp.fill_rect(sprite_x + 6,  sprite_y + 17, 20, 18, ph)
          bmp.fill_rect(sprite_x + 6,  sprite_y + 35,  8, 12, ph)
          bmp.fill_rect(sprite_x + 18, sprite_y + 35,  8, 12, ph)
        end

        # ── Change Title button (right column) ────────────────────
        can_teleport = !is_own &&
                       defined?(MultiplayerUI) &&
                       MultiplayerUI.respond_to?(:can_silent_warp_to_sid?) &&
                       MultiplayerUI.can_silent_warp_to_sid?(_remote_target_sid)
        if !is_own && can_teleport && @btn_hovered
          btn_bg  = Color.new(55, 32, 92, 235)
          btn_brd = Color.new(150, 95, 220, 255)
        elsif !is_own && can_teleport
          btn_bg  = Color.new(42, 24, 72, 230)
          btn_brd = Color.new(95, 68, 145, 230)
        elsif is_own
          btn_bg  = Color.new(55, 25,  90, 210)
          btn_brd = Color.new(130, 65, 190, 220)
        else
          btn_bg  = Color.new(35, 25, 55, 230)
          btn_brd = Color.new(70, 55, 90, 220)
        end
        bmp.fill_rect(btn_x,     row_y,     btn_w,     btn_h,     btn_brd)
        bmp.fill_rect(btn_x + 2, row_y + 2, btn_w - 4, btn_h - 4, btn_bg)

        if is_own
          title_x = btn_x + 5
          title_y = row_y + 4
          title_w = btn_w - 10
          title_h = 30
          lower_y = title_y + title_h + 6
          lower_gap = 4
          lower_w = (title_w - lower_gap) / 2
          return_x = title_x
          return_y = lower_y
          return_w = lower_w
          return_h = 24
          convert_x = return_x + return_w + lower_gap
          convert_y = lower_y
          convert_w = title_w - return_w - lower_gap
          convert_h = return_h
          convert_ready = defined?(MultiplayerPlatinum) &&
                          defined?($Trainer) &&
                          $Trainer &&
                          MultiplayerPlatinum.connected?

          title_brd = @btn_hovered ? Color.new(180, 100, 255, 255) : Color.new(130, 65, 190, 220)
          title_bg  = @btn_hovered ? Color.new(80, 40, 130, 230) : Color.new(55, 25, 90, 210)
          bmp.fill_rect(title_x, title_y, title_w, title_h, title_brd)
          bmp.fill_rect(title_x + 2, title_y + 2, title_w - 4, title_h - 4, title_bg)

          return_brd = @return_btn_hovered ? Color.new(155, 110, 225, 245) : Color.new(105, 74, 155, 220)
          return_bg  = @return_btn_hovered ? Color.new(68, 46, 110, 235) : Color.new(45, 30, 75, 215)
          bmp.fill_rect(return_x, return_y, return_w, return_h, return_brd)
          bmp.fill_rect(return_x + 2, return_y + 2, return_w - 4, return_h - 4, return_bg)

          if convert_ready && @convert_btn_hovered
            convert_brd = Color.new(190, 145, 95, 255)
            convert_bg  = Color.new(120, 84, 38, 235)
          elsif convert_ready
            convert_brd = Color.new(148, 108, 64, 235)
            convert_bg  = Color.new(96, 66, 28, 225)
          else
            convert_brd = Color.new(88, 72, 52, 220)
            convert_bg  = Color.new(52, 40, 26, 210)
          end
          bmp.fill_rect(convert_x, convert_y, convert_w, convert_h, convert_brd)
          bmp.fill_rect(convert_x + 2, convert_y + 2, convert_w - 4, convert_h - 4, convert_bg)

          bmp.font.bold  = true
          bmp.font.size  = 11
          bmp.font.color = @btn_hovered ? Color.new(240, 200, 255) : Color.new(200, 160, 255)
          bmp.draw_text(title_x, title_y + 2, title_w, 14, "Change Title", 1)
          bmp.font.bold  = false
          bmp.font.size  = 8
          bmp.font.color = @btn_hovered ? Color.new(180, 140, 220) : Color.new(130, 100, 170)
          bmp.draw_text(title_x, title_y + 15, title_w, 10, @btn_hovered ? "Click to change" : "[Z / Enter]", 1)

          bmp.font.bold  = true
          bmp.font.size  = 10
          bmp.font.color = @return_btn_hovered ? Color.new(228, 208, 255) : Color.new(190, 170, 232)
          bmp.draw_text(return_x, return_y + 1, return_w, 12, "Return Home", 1)
          bmp.font.bold  = false
          bmp.font.size  = 8
          bmp.font.color = @return_btn_hovered ? Color.new(176, 156, 214) : Color.new(132, 116, 170)
          bmp.draw_text(return_x, return_y + 12, return_w, 10, @return_btn_hovered ? "Pallet Town" : "Home warp", 1)

          bmp.font.bold  = true
          bmp.font.size  = 9
          bmp.font.color = if convert_ready
                             @convert_btn_hovered ? Color.new(255, 228, 180) : Color.new(242, 210, 154)
                           else
                             Color.new(160, 138, 112)
                           end
          bmp.draw_text(convert_x, convert_y + 2, convert_w, 11, "Cash Out", 1)
          bmp.font.bold  = false
          bmp.font.size  = 8
          bmp.font.color = if convert_ready
                             @convert_btn_hovered ? Color.new(225, 194, 150) : Color.new(192, 164, 122)
                           else
                             Color.new(132, 112, 92)
                           end
          convert_hint = if convert_ready
                           @convert_btn_hovered ? "Choose amount" : '1 Pt = $10'
                         else
                           "Offline"
                         end
          bmp.draw_text(convert_x, convert_y + 12, convert_w, 10, convert_hint, 1)
        else
          lines = _presence_lines
          bmp.font.bold  = true
          bmp.font.size  = 12
          bmp.font.color = can_teleport ? Color.new(220, 185, 255) : Color.new(150, 125, 190)
          bmp.draw_text(btn_x, row_y + 8, btn_w, 18, "Teleport", 1)
          bmp.font.bold  = false
          bmp.font.size  = 10
          bmp.font.color = Color.new(190, 175, 225)
          bmp.draw_text(btn_x, row_y + 30, btn_w, 14, lines[1].to_s, 1)
          detail = lines[2]
          detail = lines[0] if detail.to_s.empty?
          bmp.font.size  = 9
          bmp.font.color = Color.new(130, 110, 165)
          bmp.draw_text(btn_x, row_y + 46, btn_w, 12, detail.to_s, 1)
          bmp.font.color = can_teleport ? Color.new(165, 135, 205) : Color.new(115, 100, 145)
          hint = can_teleport ? (@btn_hovered ? "Click to warp" : "[Z / Enter]") : "Location unavailable"
          bmp.draw_text(btn_x, row_y + 60, btn_w, 12, hint, 1)
        end

        # ── Thick divider ─────────────────────────────────────────
        bmp.fill_rect(6,     div_y,     PANEL_W - 12, 3, Color.new(80, 40, 130, 200))
        bmp.fill_rect(6 + 1, div_y + 1, PANEL_W - 14, 1, Color.new(160, 100, 220, 120))

        # ── Stats (2-column grid below divider) ───────────────────
        stats = d["stats"] || {}
        # Left column: battle/capture progress
        left_rows = [
          ["NPC Battles:",    stats["trainer_battles"].to_i],
          ["Wild Captured:",  stats["wild_captured"].to_i],
          ["Wild Fainted:",   stats["wild_fainted"].to_i],
          ["Eggs Hatched:",   stats["eggs_hatched"].to_i],
          ["Badges:",         stats["badges"].to_i],
          ["Dex Caught:",     stats["pokemon_caught"].to_i],
        ]
        # Right column: economy / social / titles
        right_rows = [
          ["Steps Taken:",    stats["steps"].to_i],
          ["Chat Sent:",      stats["chat_messages"].to_i],
          ["$ Won:",          stats["platinum_won"].to_i],
          ["$ Spent:",        stats["platinum_spent"].to_i],
          ["Titles:",         stats["titles_collected"].to_i],
          ["Bosses:",         stats["bosses_fainted"].to_i],
        ]
        label_color = Color.new(160, 130, 210)
        value_color = Color.new(230, 230, 255)
        col_w       = (PANEL_W - 24) / 2   # 153
        col1_x      = 12
        col2_x      = col1_x + col_w + 0
        label_w     = 78
        value_w     = col_w - label_w - 4
        base_y      = div_y + 10
        row_h       = 17
        bmp.font.bold = false
        bmp.font.size = 12

        draw_row = lambda do |x, y, label, value|
          bmp.font.color = label_color
          bmp.draw_text(x, y, label_w, 16, label, 0)
          bmp.font.color = value_color
          bmp.draw_text(x + label_w, y, value_w, 16, _fmt_num(value), 0)
        end

        left_rows.each_with_index  { |(l, v), i| draw_row.call(col1_x, base_y + i * row_h, l, v) }
        right_rows.each_with_index { |(l, v), i| draw_row.call(col2_x, base_y + i * row_h, l, v) }

        # ── Timestamp (bottom) ────────────────────────────────────
        bmp.font.size  = 9
        bmp.font.color = Color.new(90, 75, 120)
        bmp.draw_text(8, PANEL_H - 16, PANEL_W - 16, 14,
                      "Last fetched: #{_ago_str(@fetch_time)}", 0)
      end

      def self._action_box_layout
        row_y    = 26
        top_h    = SPRITE_H
        left_x   = 8
        left_w   = 80
        sprite_x = left_x + left_w + 4 - 25
        btn_x    = sprite_x + SPRITE_W + 6 + 30
        btn_w    = PANEL_W - btn_x - 6
        btn_h    = top_h + 30
        {
          x: btn_x,
          y: row_y,
          w: btn_w,
          h: btn_h,
          title_h: 30,
          return_h: 24,
          gap: 6,
          split_gap: 4
        }
      end

      # Mouse hover + click detection for the action box.
      def self._handle_btn_mouse(my_uuid)
        mx = (Input.mouse_x rescue nil)
        my = (Input.mouse_y rescue nil)
        return unless mx && my

        sw = Graphics.width
        sh = Graphics.height
        px = (sw - PANEL_W) / 2
        py = (sh - PANEL_H) / 2
        layout = _action_box_layout

        abs_btn_x = px + layout[:x]
        abs_btn_y = py + layout[:y]

        if _own_profile_target?
          title_x = abs_btn_x + 5
          title_y = abs_btn_y + 4
          title_w = layout[:w] - 10
          title_h = layout[:title_h]
          lower_w = (title_w - layout[:split_gap]) / 2
          return_x = title_x
          return_y = title_y + title_h + layout[:gap]
          return_w = lower_w
          return_h = layout[:return_h]
          convert_x = return_x + return_w + layout[:split_gap]
          convert_y = return_y
          convert_w = title_w - return_w - layout[:split_gap]
          convert_h = return_h

          over_title = mx >= title_x && mx < title_x + title_w &&
                       my >= title_y && my < title_y + title_h
          over_return = mx >= return_x && mx < return_x + return_w &&
                        my >= return_y && my < return_y + return_h
          over_convert = mx >= convert_x && mx < convert_x + convert_w &&
                         my >= convert_y && my < convert_y + convert_h

          if over_title != @btn_hovered || over_return != @return_btn_hovered || over_convert != @convert_btn_hovered
            @btn_hovered = over_title
            @return_btn_hovered = over_return
            @convert_btn_hovered = over_convert
            _redraw
          end

          if (Input.trigger?(Input::MOUSELEFT) rescue false)
            _handle_change_title if over_title
            _handle_return_to_pallet if over_return
            _handle_convert_platinum_to_money if over_convert
          end
        else
          over = mx >= abs_btn_x && mx < abs_btn_x + layout[:w] &&
                 my >= abs_btn_y && my < abs_btn_y + layout[:h]

          if over != @btn_hovered || @return_btn_hovered || @convert_btn_hovered
            @btn_hovered = over
            @return_btn_hovered = false
            @convert_btn_hovered = false
            _redraw
          end

          _handle_remote_teleport if over && (Input.trigger?(Input::MOUSELEFT) rescue false)
        end
      end

      def self._pallet_town_healspot
        data = pbLoadTownMapData rescue nil
        if data.is_a?(Array)
          data.each do |region|
            next unless region.is_a?(Array) && region[2].is_a?(Array)
            region[2].each do |loc|
              next unless loc.is_a?(Array)
              next unless loc[2].to_s.strip.casecmp("Pallet Town").zero?
              map_id = loc[4].to_i
              x = loc[5]
              y = loc[6]
              return [map_id, x.to_i, y.to_i] if map_id > 0 && !x.nil? && !y.nil?
            end
          end
        end
        PALLET_TOWN_FALLBACK_HEALSPOT
      rescue
        PALLET_TOWN_FALLBACK_HEALSPOT
      end

      def self._handle_return_to_pallet
        healspot = _pallet_town_healspot
        return pbMessage(_INTL("Pallet Town return point unavailable.")) unless healspot

        map_id, x, y = healspot
        return pbMessage(_INTL("Return unavailable right now.")) unless defined?($game_temp) && $game_temp

        local = (defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:local_runtime_position)) ? MultiplayerUI.local_runtime_position : nil
        if local && local[:map].to_i == map_id.to_i && local[:x].to_i == x.to_i && local[:y].to_i == y.to_i
          close
          return
        end

        $game_temp.player_transferring  = true
        $game_temp.player_new_map_id    = map_id.to_i
        $game_temp.player_new_x         = x.to_i
        $game_temp.player_new_y         = y.to_i
        $game_temp.player_new_direction = ($game_player.direction rescue 2)
        close
      rescue
        pbMessage(_INTL("Return failed."))
      end

      def self._handle_convert_platinum_to_money
        max_amount = MultiplayerPlatinum.cashout_max_amount(refresh: true)
        if max_amount <= 0
          pbMessage(_INTL("You don't have any Platinum to cash out."))
          return
        end

        amount = MultiplayerPlatinum.prompt_cashout_amount(max_amount, 1)
        return if amount.nil?

        money_amount = MultiplayerPlatinum.cashout_value(amount)
        choice = pbMessage(
          _INTL("Convert {1} Platinum into ${2}?", amount, money_amount.to_s_formatted),
          [_INTL("Yes"), _INTL("No")], 1
        )
        return unless choice == 0

        ok, result = MultiplayerPlatinum.convert_to_money(amount, money_amount, "profile_money_convert")
        unless ok
          pbMessage(_INTL(result.to_s))
          return
        end

        if @data.is_a?(Hash)
          stats = @data["stats"]
          stats["platinum_spent"] = stats["platinum_spent"].to_i + amount if stats.is_a?(Hash)
        end
        @fetch_time = Time.now if @fetch_time.nil?

        if defined?(MultiplayerClient) && @target_uuid
          @loading = true
          @request_time = Time.now
          MultiplayerClient.request_profile(@target_uuid) rescue nil
        end

        _redraw
        pbMessage(_INTL("Converted {1} Platinum into ${2}.", amount, money_amount.to_s_formatted))
      rescue
        pbMessage(_INTL("Platinum conversion failed."))
      end

      # Handle the Change Title menu (blocking, called from tick).
      def self._handle_change_title
        titles = (MultiplayerClient.own_titles rescue [])
        if titles.nil? || titles.empty?
          pbMessage(_INTL("You don't own any titles yet."))
          return
        end
        active_id = @data && @data["active_title"] && @data["active_title"]["id"]
        options = titles.map do |t|
          name = t.is_a?(Hash) ? t["name"].to_s : t.to_s
          t.is_a?(Hash) && t["id"] == active_id ? "#{name} (active)" : name
        end
        options << _INTL("[ Remove Title ]") if active_id
        options << _INTL("Cancel")
        choice = pbMessage(_INTL("Choose a title to equip:"), options, options.length - 1)
        return if choice < 0 || choice >= options.length - 1
        # "Remove Title" slot
        if active_id && choice == options.length - 2
          MultiplayerClient.equip_title("") rescue nil
          pbMessage(_INTL("Title removed."))
        else
          td = titles[choice]
          title_id = td.is_a?(Hash) ? td["id"].to_s : nil
          return if title_id.nil? || title_id.empty?
          if title_id == active_id
            MultiplayerClient.equip_title("") rescue nil
            pbMessage(_INTL("Title unequipped."))
          else
            MultiplayerClient.equip_title(title_id) rescue nil
            pbMessage(_INTL("Title equipped!"))
          end
        end
        # Refresh own profile to reflect change
        close
        MultiplayerUI::ProfilePanel.open(uuid: "self")
      rescue => e
        # Silently recover
      end

      # Compute title color for the panel (gradient uses @title_phase).
      def self._panel_title_color(td, alpha = 255)
        return Color.new(255, 255, 255, alpha) unless td.is_a?(Hash)
        c1 = td["color1"] || [255, 255, 255]
        c2 = td["color2"] || c1
        case td["effect"].to_s
        when "solid", "outline"
          Color.new(c1[0].to_i, c1[1].to_i, c1[2].to_i, alpha)
        when "gradient"
          t = (Math.sin(@title_phase * Math::PI * 2) + 1.0) / 2.0
          r = (c1[0].to_i + (c2[0].to_i - c1[0].to_i) * t).to_i.clamp(0, 255)
          g = (c1[1].to_i + (c2[1].to_i - c1[1].to_i) * t).to_i.clamp(0, 255)
          b = (c1[2].to_i + (c2[2].to_i - c1[2].to_i) * t).to_i.clamp(0, 255)
          Color.new(r, g, b, alpha)
        when "tricolor"
          c3 = td["color3"] || c2
          phase = (@title_phase * 3.0) % 3.0
          if phase < 1.0
            ca, cb = c1, c2; t = phase
          elsif phase < 2.0
            ca, cb = c2, c3; t = phase - 1.0
          else
            ca, cb = c3, c1; t = phase - 2.0
          end
          t = (1.0 - Math.cos(t * Math::PI)) / 2.0
          r = (ca[0].to_i + (cb[0].to_i - ca[0].to_i) * t).to_i.clamp(0, 255)
          g = (ca[1].to_i + (cb[1].to_i - ca[1].to_i) * t).to_i.clamp(0, 255)
          b = (ca[2].to_i + (cb[2].to_i - ca[2].to_i) * t).to_i.clamp(0, 255)
          Color.new(r, g, b, alpha)
        else
          Color.new(255, 255, 255, alpha)
        end
      rescue
        Color.new(255, 255, 255, alpha)
      end

      # Format a large integer with thousand separators (e.g. 1,234,567).
      def self._fmt_num(n)
        n.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      rescue
        n.to_s
      end

      # Gilded gold bar with pulsing glow. All opaque.
      # phase: Time.now.to_f — drives the glow pulse.
      def self._draw_gilded_plate(bmp, x, y, w, h, phase)
        # Two layered waves — use modulo to keep phase in sane range
        ph = phase % 100.0
        p1 = (Math.sin(ph * 2.5) + 1.0) / 2.0
        p2 = (Math.sin(ph * 1.1 + 1.2) + 1.0) / 2.0
        glow = p1 * 0.6 + p2 * 0.4  # 0..1
        # Base — wide swing: dark brown-gold ↔ warm gold
        br = (30 + glow * 45).to_i; bg = (22 + glow * 38).to_i
        bmp.fill_rect(x, y, w, h, Color.new(br, bg, 5))
        # Top bevel — muted ↔ bright
        tr = (160 + glow * 95).to_i; tg = (130 + glow * 80).to_i; tb = (25 + glow * 45).to_i
        bmp.fill_rect(x + 1, y, w - 2, 1, Color.new(tr, tg, tb))
        bmp.fill_rect(x + 1, y + 1, w - 2, 1, Color.new(tr - 50, tg - 40, [tb - 10, 0].max))
        # Bottom bevel
        bmp.fill_rect(x + 1, y + h - 2, w - 2, 1, Color.new((65 + glow * 30).to_i, (50 + glow * 22).to_i, 12))
        bmp.fill_rect(x + 1, y + h - 1, w - 2, 1, Color.new(35, 25, 8))
        # Side bevels
        bmp.fill_rect(x, y + 1, 1, h - 2, Color.new((140 + glow * 60).to_i, (115 + glow * 50).to_i, (20 + glow * 25).to_i))
        bmp.fill_rect(x + w - 1, y + 1, 1, h - 2, Color.new((85 + glow * 35).to_i, (60 + glow * 28).to_i, 15))
        # Inner gold body — bands breathe with glow
        inner_x = x + 2; inner_w = w - 4; mid_y = y + h / 2
        (2...h - 2).each do |dy|
          py = y + dy
          dist = (py - mid_y).abs.to_f / (h / 2.0)
          bright = (1.0 - dist) * (0.5 + glow * 0.5)
          r = (100 + bright * 130).to_i.clamp(0, 240)
          g = (75  + bright * 105).to_i.clamp(0, 190)
          b = (10  + bright * 25).to_i.clamp(0, 40)
          bmp.fill_rect(inner_x, py, inner_w, 1, Color.new(r, g, b))
        end
        # Corner rivets
        cr = (200 + glow * 55).to_i; cg = (170 + glow * 50).to_i
        bmp.fill_rect(x + 1, y + 1, 2, 2, Color.new(cr, cg, 45))
        bmp.fill_rect(x + w - 3, y + 1, 2, 2, Color.new(cr, cg, 45))
        bmp.fill_rect(x + 1, y + h - 3, 2, 2, Color.new((160 + glow * 40).to_i, (130 + glow * 35).to_i, 30))
        bmp.fill_rect(x + w - 3, y + h - 3, 2, 2, Color.new((160 + glow * 40).to_i, (130 + glow * 35).to_i, 30))
      end

      # Human-readable "X ago" string for a Time object.
      def self._ago_str(t)
        return "never" unless t
        secs = (Time.now - t).to_i
        return "just now"      if secs < 5
        return "#{secs}s ago"  if secs < 60
        return "#{secs/60}m ago" if secs < 3600
        "#{secs/3600}h ago"
      end

    end
  end

  # ── Hook into Scene_Map ──────────────────────────────────────────
  module MultiplayerUI
    module ProfilePanel
      def self._presence_lines
        state = nil
        if defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:runtime_player_state_for_uuid)
          state = MultiplayerUI.runtime_player_state_for_uuid(@target_uuid)
        end
        return ["Live status", "Unavailable", nil] unless state

        line1 = state[:busy] ? "Online | Busy" : "Online"
        line2 = if state[:same_map]
          dist = state[:distance]
          (dist && dist > 0) ? "#{dist} tiles away" : "Same map"
        elsif state[:map].to_i > 0
          "Map #{state[:map].to_i}"
        else
          "Live status"
        end

        extras = []
        extras << "#{state[:ping]}ms" if state[:ping]
        [line1, line2, extras.empty? ? nil : extras.join(" | ")]
      rescue
        ["Live status", "Unavailable", nil]
      end
    end
  end

  module MultiplayerUI
    module ProfilePanel
      def self.open(uuid: "self")
        return unless defined?(MultiplayerClient) && MultiplayerClient.session_id
        return if ($game_temp&.in_battle rescue false)
        return if ($game_temp&.in_menu   rescue false)

        uuid = MultiplayerClient.platinum_uuid || "self" if uuid == "self" || uuid.to_s.empty?

        @target_uuid  = uuid.to_s
        @open         = true
        @title_phase  = 0.0
        @request_time = Time.now
        @btn_hovered = false
        @return_btn_hovered = false

        cached = @cache[@target_uuid]
        cached_data = cached.is_a?(Hash) ? cached[:data] : nil

        @data       = cached_data
        @fetch_time = cached.is_a?(Hash) ? cached[:fetch_time] : nil
        @loading    = true
        _dispose_sprite_bmp

        if _own_profile_target?
          @data = _local_profile_data(cached_data)
          @fetch_time ||= Time.now
        end

        if @data
          _build_sprite_bmp(_resolve_sprite_data(@data))
        end
        if (!@sprite_bmp || @sprite_bmp.disposed?) && cached.is_a?(Hash)
          cached_bmp = cached[:sprite_bmp]
          @sprite_bmp = cached_bmp if cached_bmp && !cached_bmp.disposed?
        end

        MultiplayerClient.request_profile(@target_uuid)
        _ensure_viewport
        _redraw
      end

      def self.tick
        return unless @open

        if (Input.trigger?(Input::MOUSERIGHT) rescue false)
          close
          return
        end

        if @loading
          pd = MultiplayerClient.pop_profile_data rescue nil
          if pd.is_a?(Hash)
            pd = _local_profile_data(pd) if _own_profile_target?
            @data       = pd
            @loading    = false
            @fetch_time = Time.now
            _dispose_sprite_bmp
            _build_sprite_bmp(_resolve_sprite_data(@data))
            @cache[@target_uuid] = {
              data: @data,
              sprite_bmp: @sprite_bmp,
              fetch_time: @fetch_time
            }
            _redraw
          elsif @request_time && (Time.now - @request_time) > REQUEST_TIMEOUT
            @loading = false
            _redraw
          end
        end

        td = @data && @data["active_title"]
        if td.is_a?(Hash)
          if td["effect"] == "gradient" || td["effect"] == "tricolor"
            speed = (td["speed"] || 0.3).to_f
            @title_phase += speed / 60.0
            _redraw
          elsif td["gilded"]
            _redraw
          end
        end

        if !@loading && @data
          my_uuid = (MultiplayerClient.platinum_uuid rescue nil)
          mouse_clicked = (Input.trigger?(Input::MOUSELEFT) rescue false)
          if _own_profile_target?
            _handle_btn_mouse(my_uuid)
            if !mouse_clicked && Input.trigger?(Input::C)
              _handle_change_title
            end
          else
            _handle_btn_mouse(my_uuid)
            if !mouse_clicked && Input.trigger?(Input::C)
              _handle_remote_teleport
            end
          end
        elsif @btn_hovered || @return_btn_hovered || @convert_btn_hovered
          @btn_hovered = false
          @return_btn_hovered = false
          @convert_btn_hovered = false
          _redraw
        end

        if ($game_temp&.in_battle rescue false) || ($game_temp&.in_menu rescue false)
          close
        end
      end

      def self._own_profile_target?
        my_uuid = (MultiplayerClient.platinum_uuid rescue nil).to_s.strip
        target = @target_uuid.to_s.strip
        return true if target == "self"
        !my_uuid.empty? && target == my_uuid
      rescue
        false
      end

      def self._local_profile_data(base = nil)
        base = {} unless base.is_a?(Hash)
        stats = base["stats"].is_a?(Hash) ? base["stats"].dup : {}
        stats["badges"] = ($Trainer.badge_count rescue stats["badges"].to_i)
        stats["pokemon_caught"] = ($Trainer.pokedex.owned_count rescue stats["pokemon_caught"].to_i)
        stats["steps"] = ($PokemonGlobal.stepcount rescue stats["steps"].to_i)
        own_titles = (MultiplayerClient.own_titles rescue [])
        title_count = own_titles.is_a?(Array) ? own_titles.length : 0
        stats["titles_collected"] = [stats["titles_collected"].to_i, title_count].max

        name = ($Trainer.name rescue nil).to_s
        name = base["name"].to_s if name.empty?
        name = "Player" if name.empty?

        active_title = base["active_title"]
        sid = (MultiplayerClient.session_id rescue nil)
        live_title = sid ? (MultiplayerClient.title_for(sid) rescue nil) : nil
        active_title = live_title if live_title.is_a?(Hash)

        {
          "name"         => name,
          "active_title" => active_title,
          "stats"        => stats,
          "sprite_data"  => (MultiplayerUI.local_trainer_appearance rescue nil)
        }
      rescue
        base.is_a?(Hash) ? base : nil
      end

      def self._remote_target_sid
        return nil if _own_profile_target?
        return nil unless defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:sid_for_uuid)
        sid = MultiplayerUI.sid_for_uuid(@target_uuid).to_s.strip
        sid.empty? ? nil : sid
      rescue
        nil
      end

      def self._handle_remote_teleport
        sid = _remote_target_sid
        unless sid && defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:silent_warp_to_sid)
          pbMessage(_INTL("Player location unavailable."))
          return
        end

        ok, reason = MultiplayerUI.silent_warp_to_sid(sid)
        unless ok
          pbMessage(_INTL(reason || "Teleport unavailable."))
          return
        end

        close
      rescue
        pbMessage(_INTL("Teleport failed."))
      end

      def self._build_sprite_bmp(sd)
        if _own_profile_target? && defined?(generateClothedBitmapStatic) && defined?($Trainer) && $Trainer
          @sprite_bmp = generateClothedBitmapStatic($Trainer, "walk")
          return
        end

        if defined?(MultiplayerUI) && MultiplayerUI.respond_to?(:normalize_trainer_appearance)
          sd = MultiplayerUI.normalize_trainer_appearance(sd)
        end
        return unless sd.is_a?(Hash) && defined?(generateClothedBitmapStatic) && defined?(RemoteTrainer)

        remote_trainer = RemoteTrainer.new(
          (sd[:clothes] || sd["clothes"] || "001").to_s,
          (sd[:hat] || sd["hat"] || "000").to_s,
          (sd[:hat2] || sd["hat2"] || "000").to_s,
          (sd[:hair] || sd["hair"] || "000").to_s,
          (sd[:skin_tone] || sd["skin_tone"]).to_i,
          (sd[:hair_color] || sd["hair_color"]).to_i,
          (sd[:hat_color] || sd["hat_color"]).to_i,
          (sd[:hat2_color] || sd["hat2_color"]).to_i,
          (sd[:clothes_color] || sd["clothes_color"]).to_i
        )
        @sprite_bmp = generateClothedBitmapStatic(remote_trainer, "walk")
      rescue => e
        ##MultiplayerDebug.warn("PROFILE-PANEL", "Sprite build failed: #{e.message}")
        @sprite_bmp = nil
      end

      def self._redraw
        return unless @viewport && !@viewport.disposed?

        sw = Graphics.width
        sh = Graphics.height
        px = (sw - PANEL_W) / 2
        py = (sh - PANEL_H) / 2

        if @panel_spr.nil? || @panel_spr.disposed?
          @panel_spr   = Sprite.new(@viewport)
          @panel_spr.x = px
          @panel_spr.y = py
          @panel_spr.z = 100
        end

        if @panel_spr.bitmap.nil? || @panel_spr.bitmap.disposed? ||
           @panel_spr.bitmap.width != PANEL_W || @panel_spr.bitmap.height != PANEL_H
          @panel_spr.bitmap.dispose rescue nil
          @panel_spr.bitmap = Bitmap.new(PANEL_W, PANEL_H)
        else
          @panel_spr.bitmap.clear
        end

        bmp = @panel_spr.bitmap

        bg_color  = Color.new(15, 10, 25, 255)
        brd_color = Color.new(130, 70, 200, 255)
        bmp.fill_rect(0, 0, PANEL_W, PANEL_H, brd_color)
        bmp.fill_rect(2, 2, PANEL_W - 4, PANEL_H - 4, bg_color)

        hdr_color = Color.new(80, 35, 140, 230)
        bmp.fill_rect(2, 2, PANEL_W - 4, 20, hdr_color)
        bmp.font.size  = 13
        bmp.font.bold  = true
        bmp.font.color = Color.new(200, 160, 255)
        bmp.draw_text(5, 3, PANEL_W - 30, 16, "PROFILE", 0)
        bmp.font.size  = 10
        bmp.font.bold  = false
        bmp.font.color = Color.new(140, 110, 180)
        bmp.draw_text(5, 3, PANEL_W - 8, 16, "[F8 / Esc]", 2)

        if @data.nil? && @loading && (@request_time.nil? || (Time.now - @request_time) <= REQUEST_TIMEOUT)
          bmp.font.size  = 13
          bmp.font.bold  = false
          bmp.font.color = Color.new(180, 160, 220)
          dots = "." * ((Time.now.to_i % 3) + 1)
          bmp.draw_text(0, PANEL_H / 2 - 8, PANEL_W, 20, "Loading#{dots}", 1)
        elsif @data.nil?
          bmp.font.size  = 12
          bmp.font.color = Color.new(180, 100, 100)
          bmp.draw_text(0, PANEL_H / 2 - 8, PANEL_W, 20, "No response from server.", 1)
        else
          _draw_profile(bmp)
        end
      rescue => e
        ##MultiplayerDebug.error("PROFILE-PANEL", "Redraw error: #{e.message}")
      end
    end
  end

  class ::Scene_Map
    alias kif_profile_panel_update update unless method_defined?(:kif_profile_panel_update)

    def update
      kif_profile_panel_update
      MultiplayerUI::ProfilePanel.tick rescue nil
    end
  end

  if defined?(PokeBattle_Scene)
    class ::PokeBattle_Scene
      alias kif_profile_panel_pbUpdate pbUpdate unless method_defined?(:kif_profile_panel_pbUpdate)

      def pbUpdate(cw = nil)
        kif_profile_panel_pbUpdate(cw)
        MultiplayerUI::ProfilePanel.tick rescue nil
      end
    end
  end

end
