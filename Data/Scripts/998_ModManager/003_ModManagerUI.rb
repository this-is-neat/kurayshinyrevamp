#==============================================================================
# Mod Manager — Installed Mods UI
#
# Two-panel scene: left = scrollable mod list, right = selected mod details.
# Bottom bar: [Mod Browser] [Modder Tools] [Back]
#==============================================================================

module ModManager
  class Scene_Installed
    # Colors
    BG_COLOR       = Color.new(20, 18, 30, 240)
    PANEL_BG       = Color.new(35, 32, 50)
    PANEL_BORDER   = Color.new(80, 70, 110)
    ROW_NORMAL     = Color.new(255, 255, 255, 8)
    ROW_SELECTED   = Color.new(255, 255, 255, 30)
    ROW_DISABLED   = Color.new(255, 255, 255, 4)
    WHITE          = Color.new(255, 255, 255)
    GRAY           = Color.new(180, 180, 180)
    DIM            = Color.new(120, 120, 140)
    SHADOW         = Color.new(40, 35, 55)
    GREEN          = Color.new(100, 220, 120)
    RED            = Color.new(220, 80, 80)
    YELLOW         = Color.new(240, 220, 80)
    ORANGE         = Color.new(240, 160, 60)
    TAG_BG         = Color.new(60, 55, 80)
    FOOTER_BG      = Color.new(28, 25, 42)
    FOOTER_SEL     = Color.new(100, 80, 160)
    SEARCH_BG      = Color.new(50, 45, 70)
    WARN_BORDER    = Color.new(200, 60, 60)

    # Layout
    SCREEN_W     = 512
    SCREEN_H     = 384
    TITLE_H      = 28
    FOOTER_H     = 28
    LEFT_W       = 186
    RIGHT_W      = SCREEN_W - LEFT_W - 16  # 310
    SEARCH_H     = 22
    ROW_H        = 20
    CONTENT_Y    = TITLE_H + 4
    CONTENT_H    = SCREEN_H - TITLE_H - FOOTER_H - 8
    LIST_Y       = SEARCH_H + 4
    LIST_H       = CONTENT_H - SEARCH_H - 4

    def initialize
      @vp = nil
      @bg = nil
      @title_spr = nil
      @left_spr = nil
      @right_spr = nil
      @footer_spr = nil
      @running = false
      @all_mods = []
      @filtered_mods = []
      @sel_index = 0
      @scroll = 0
      @search_text = ""
      @search_active = false
      @cursor_frame = 0
      @active_filter = nil
      @footer_index = 0  # 0=Browser, 1=Modder Tools, 2=Back
      @focus = :list     # :list or :footer
    end

    def main
      Graphics.freeze
      setup
      Graphics.transition(8)
      loop do
        Graphics.update
        Input.update
        break unless @running
        # Blink cursor when search is active
        if @search_active
          @cursor_frame += 1
          draw_left if @cursor_frame % 20 == 0  # redraw every 20 frames for blink
        end
        _poll_mm_update_check
        handle_input
      end
      Graphics.freeze
      teardown
      Graphics.transition(8)
    end

    #==========================================================================
    # Setup / Teardown
    #==========================================================================
    def setup
      @running = true
      ModManager.refresh

      @vp = Viewport.new(0, 0, SCREEN_W, SCREEN_H)
      @vp.z = 100_000

      # Background (fully opaque so it covers the title screen)
      @bg = Sprite.new(@vp)
      @bg.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      @bg.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H, Color.new(20, 18, 30, 255))

      # Title bar
      @title_spr = Sprite.new(@vp)
      @title_spr.bitmap = Bitmap.new(SCREEN_W, TITLE_H)
      @title_spr.z = 10

      # Left panel (mod list)
      @left_spr = Sprite.new(@vp)
      @left_spr.bitmap = Bitmap.new(LEFT_W, CONTENT_H)
      @left_spr.x = 4
      @left_spr.y = CONTENT_Y
      @left_spr.z = 10

      # Right panel (details)
      @right_spr = Sprite.new(@vp)
      @right_spr.bitmap = Bitmap.new(RIGHT_W, CONTENT_H)
      @right_spr.x = LEFT_W + 12
      @right_spr.y = CONTENT_Y
      @right_spr.z = 10

      # Footer
      @footer_spr = Sprite.new(@vp)
      @footer_spr.bitmap = Bitmap.new(SCREEN_W, FOOTER_H)
      @footer_spr.y = SCREEN_H - FOOTER_H
      @footer_spr.z = 10

      @mm_update_available = false
      @mm_remote_version = nil
      @mm_check_thread = nil
      @mm_check_done = false
      @mm_check_prompted = false

      refresh_data
      draw_title
      draw_left
      draw_right
      draw_footer

      # Kick off background version check. HTTPLite has no timeout, so a
      # synchronous call in setup() would freeze the game on bad networks.
      # Run it in a thread; the main loop polls _poll_mm_update_check.
      _kick_mm_update_check
    end

    def _kick_mm_update_check
      return unless defined?(ModManager::GitHub)
      return if @mm_check_thread
      ModManager::GitHub.reset_mm_check
      @mm_check_thread = Thread.new do
        begin
          ModManager::GitHub.fetch_mm_remote_version
        rescue
        end
      end
    end

    def _poll_mm_update_check
      return if @mm_check_done
      return unless @mm_check_thread
      return if @mm_check_thread.alive?
      @mm_check_done = true
      @mm_check_thread = nil

      begin
        if ModManager::GitHub.mm_update_available?
          @mm_update_available = true
          @mm_remote_version = ModManager::GitHub.fetch_mm_remote_version
          draw_title
        end
      rescue
      end

      return unless @mm_update_available && @mm_remote_version
      return if @mm_check_prompted
      @mm_check_prompted = true

      local_v = ModManager::GitHub.mm_local_version || "?"
      result = show_message(
        "A new version of the Mod Manager is available!\n\n" \
        "v#{local_v} -> v#{@mm_remote_version}\n\n" \
        "Download now? The game will restart\nafter the update.",
        ["Update", "Later"]
      )
      do_mm_update(skip_confirm: true) if result == 0
    end

    def teardown
      [@footer_spr, @right_spr, @left_spr, @title_spr, @bg].compact.each do |s|
        begin
          s.bitmap.dispose if s.bitmap && !s.bitmap.disposed?
          s.dispose
        rescue; end
      end
      @vp.dispose if @vp
      @vp = nil
    end

    #==========================================================================
    # Data
    #==========================================================================
    def refresh_data
      @all_mods = ModManager.registry.values.sort_by { |m| m.name.downcase }
      # Inject special pinned entries if installed
      if _npt_installed?
        npt = _build_npt_info
        @all_mods.unshift(npt) if npt
      end
      if _mp_installed?
        mp = _build_mp_info
        @all_mods.unshift(mp) if mp
      end
      if ModManager.loose_count > 0
        @all_mods << _build_loose_summary
      end
      apply_filter
    end

    def _mp_installed?
      (defined?(ModManager::GitHub) && ModManager::GitHub.mp_installed?) ||
        File.directory?("Data/Scripts/659_Multiplayer")
    end

    def _npt_installed?
      (defined?(ModManager::GitHub) && ModManager::GitHub.npt_installed?) ||
        File.directory?("Data/Scripts/990_NPT")
    end

    def _build_mp_info
      info = ModManager::ModInfo.new
      info.id          = "_kif_multiplayer"
      info.name        = "KIF Multiplayer"
      info.author      = "sKarreku"
      info.description = "The official KIF Multiplayer mod. Adds online multiplayer, " \
                         "EBDX battle system, boss battles, and more. This is a large " \
                         "download (~100 MB) that installs scripts, graphics, audio, and fonts."
      info.tags        = ["Multiplayer", "Content", "Visual", "Audio"]
      info.folder_path = "Data/Scripts/659_Multiplayer"
      if defined?(MultiplayerVersion::CURRENT_VERSION)
        info.version = MultiplayerVersion::CURRENT_VERSION
      else
        info.version = "?"
      end
      info
    end

    def _build_npt_info
      info = ModManager::ModInfo.new
      info.id          = "_aleks_npt"
      info.name        = "Aleks Full Implementation"
      info.author      = "sKarreku"
      info.description = "A massive content pack that adds custom mega forms, sprites, " \
                         "audio, and graphics. This is a very large download (~5 GB) that " \
                         "installs into Data, Audio, and Graphics folders."
      info.tags        = ["Content", "Visual", "Audio", "Fusion"]
      info.folder_path = "Data/Scripts/990_NPT"
      if defined?(NPTVersion::CURRENT_VERSION)
        info.version = NPTVersion::CURRENT_VERSION
      else
        info.version = "?"
      end
      info
    end

    def _is_mp_entry?(mod_info)
      mod_info.id == "_kif_multiplayer"
    end

    def _is_special_entry?(mod_info)
      mod_info.id == "_kif_multiplayer" || mod_info.id == "_aleks_npt" || mod_info.id == "_loose_mods_summary"
    end

    def _build_loose_summary
      info = ModManager::ModInfo.new
      info.id          = "_loose_mods_summary"
      cnt = ModManager.loose_count
      info.name        = "... #{cnt} Loose mod#{cnt == 1 ? '' : 's'} also loaded"
      info.description = ModManager.loose_mods.join("\n")
      info.author      = "N/A"
      info
    end

    def apply_filter
      list = @all_mods
      # Search filter
      unless @search_text.empty?
        q = @search_text.downcase
        list = list.select do |m|
          m.name.downcase.include?(q) ||
          m.author.downcase.include?(q) ||
          m.description.downcase.include?(q) ||
          m.tags.any? { |t| t.downcase.include?(q) }
        end
      end
      # Tag filter
      if @active_filter
        list = list.select { |m| m.tags.include?(@active_filter) }
      end
      @filtered_mods = list
      @sel_index = @sel_index.clamp(0, [(@filtered_mods.length - 1), 0].max)
      ensure_visible
    end

    def rows_per_page
      (LIST_H / ROW_H).floor
    end

    def ensure_visible
      rpp = rows_per_page
      return if @filtered_mods.empty?
      @scroll = @sel_index if @sel_index < @scroll
      @scroll = @sel_index - rpp + 1 if @sel_index >= @scroll + rpp
      max_scroll = [@filtered_mods.length - rpp, 0].max
      @scroll = @scroll.clamp(0, max_scroll)
    end

    def selected_mod
      return nil if @filtered_mods.empty?
      @filtered_mods[@sel_index]
    end

    #==========================================================================
    # Drawing
    #==========================================================================
    def draw_title
      b = @title_spr.bitmap
      b.clear
      b.fill_rect(0, 0, SCREEN_W, TITLE_H, FOOTER_BG)
      pbSetSystemFont(b)
      b.font.size = 20
      pbDrawShadowText(b, 8, 0, -1, TITLE_H, "Mod Manager", WHITE, SHADOW)

      # Local MM version, drawn right after the title in smaller dim font
      title_w = b.text_size("Mod Manager").width
      local_v_str = (ModManager::GitHub.mm_local_version rescue nil)
      if local_v_str
        b.font.size = 14
        pbDrawShadowText(b, 8 + title_w + 6, 4, -1, TITLE_H - 4,
                         "v#{local_v_str}", DIM, SHADOW)
      end

      b.font.size = 16
      if @mm_update_available && @mm_remote_version
        local_v = ModManager::GitHub.mm_local_version || "?"
        pbDrawShadowText(b, SCREEN_W - 8, 0, -1, TITLE_H,
                         "Update: v#{local_v} -> v#{@mm_remote_version} [U]", YELLOW, SHADOW, 1)
      else
        count_text = "#{@filtered_mods.length} mod(s)"
        count_text += " (filter: #{@active_filter})" if @active_filter
        pbDrawShadowText(b, SCREEN_W - 8, 0, -1, TITLE_H, count_text, DIM, SHADOW, 1)
      end
    end

    def draw_left
      b = @left_spr.bitmap
      b.clear

      # Panel background
      draw_rounded_rect(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BG)
      draw_border(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BORDER)

      # Search bar
      search_bg = @search_active ? Color.new(70, 60, 100) : SEARCH_BG
      search_border = @search_active ? Color.new(140, 120, 200) : PANEL_BORDER
      draw_rounded_rect(b, 4, 4, LEFT_W - 8, SEARCH_H, search_bg)
      if @search_active
        draw_border(b, 4, 4, LEFT_W - 8, SEARCH_H, search_border)
      end
      pbSetSmallFont(b)
      if @search_active
        cursor = (@cursor_frame / 20) % 2 == 0 ? "|" : ""
        search_display = @search_text + cursor
        search_color = WHITE
      elsif @search_text.empty?
        search_display = "Click or S to search..."
        search_color = DIM
      else
        search_display = @search_text
        search_color = WHITE
      end
      pbDrawShadowText(b, 10, 2, LEFT_W - 20, SEARCH_H, search_display, search_color, SHADOW)

      # Mod list
      rpp = rows_per_page
      visible = @filtered_mods[@scroll, rpp] || []

      pbSetSmallFont(b)
      visible.each_with_index do |mod_info, i|
        real_index = @scroll + i
        y = LIST_Y + i * ROW_H
        selected = (real_index == @sel_index && @focus == :list)
        
        is_mp = _is_special_entry?(mod_info)
        is_loose = (mod_info.id == "_loose_mods_summary")
        
        enabled = is_mp ? true : ModManager.enabled?(mod_info.id)
        conflicts = is_mp ? [] : ModManager.check_incompatibilities(mod_info.id)

        # Row background
        if selected
          b.fill_rect(4, y, LEFT_W - 8, ROW_H - 2, ROW_SELECTED)
        elsif !enabled
          b.fill_rect(4, y, LEFT_W - 8, ROW_H - 2, ROW_DISABLED)
        else
          b.fill_rect(4, y, LEFT_W - 8, ROW_H - 2, ROW_NORMAL)
        end

        # Incompatibility warning
        if conflicts.length > 0 && enabled
          b.fill_rect(4, y, 3, ROW_H - 2, WARN_BORDER)
          pbDrawShadowText(b, LEFT_W - 22, y - 2, 14, ROW_H, "!", RED, SHADOW, 2)
        end

        # Status dot
        unless is_loose
          if is_mp
            dot_color = YELLOW
          else
            needs_restart = (ModManager::GitHub.just_installed[mod_info.id] rescue false)
            dot_color = needs_restart ? YELLOW : (enabled ? GREEN : RED)
          end
          dot_y = y + (ROW_H - 2) / 2 - 3
          b.fill_rect(10, dot_y, 6, 6, dot_color)
        end

        # Mod name
        name = mod_info.name
        name_color = is_loose ? DIM : (is_mp ? YELLOW : (enabled ? WHITE : DIM))
        
        # [MD] tag
        is_dev = mod_info.is_dev?
        tag_w = 0
        if is_dev
          tag = "[MD] "
          tag_w = b.text_size(tag).width
          pbDrawShadowText(b, 20, y - 2, tag_w, ROW_H, tag, RED, SHADOW)
        end
        
        max_w = LEFT_W - 30 - tag_w
        if b.text_size(name).width > max_w
          while b.text_size(name + "..").width > max_w && name.length > 0
            name = name[0...-1]
          end
          name += ".."
        end
        pbDrawShadowText(b, 20 + tag_w, y - 2, max_w, ROW_H, name, name_color, SHADOW)
      end

      # Scroll indicators
      if @scroll > 0
        pbDrawShadowText(b, LEFT_W / 2, LIST_Y - 12, -1, 12, "^", GRAY, SHADOW, 2)
      end
      if @scroll + rpp < @filtered_mods.length
        pbDrawShadowText(b, LEFT_W / 2, LIST_Y + rpp * ROW_H - 2, -1, 12, "v", GRAY, SHADOW, 2)
      end
    end

    def draw_right
      b = @right_spr.bitmap
      b.clear

      draw_rounded_rect(b, 0, 0, RIGHT_W, CONTENT_H, PANEL_BG)
      draw_border(b, 0, 0, RIGHT_W, CONTENT_H, PANEL_BORDER)

      mod = selected_mod
      unless mod
        pbSetSystemFont(b)
        b.font.size = 18
        pbDrawShadowText(b, 0, CONTENT_H / 2 - 12, RIGHT_W, 24,
                         "No mods installed", DIM, SHADOW, 2)
        return
      end

      x = 12
      y = 8
      is_mp = _is_special_entry?(mod)
      enabled = is_mp ? true : ModManager.enabled?(mod.id)
      conflicts = is_mp ? [] : ModManager.check_incompatibilities(mod.id)

      # Mod name (large)
      pbSetSystemFont(b)
      b.font.size = 20
      name_color = is_mp ? YELLOW : WHITE
      pbDrawShadowText(b, x, y, RIGHT_W - 24, 24, mod.name, name_color, SHADOW)
      y += 24

      # Version + Author
      pbSetSmallFont(b)
      pbDrawShadowText(b, x, y, -1, 16, "v#{mod.version}", GRAY, SHADOW)
      pbDrawShadowText(b, x + 60, y, -1, 16, "by #{mod.author}", GRAY, SHADOW)
      y += 18

      # Status
      if is_mp
        status_text = "Always Active"
        status_color = YELLOW
      else
        needs_restart = (ModManager::GitHub.just_installed[mod.id] rescue false)
        if needs_restart
          status_text = "Restart required"
          status_color = YELLOW
        elsif enabled
          status_text = "Enabled"
          status_color = GREEN
        else
          status_text = "Disabled"
          status_color = RED
        end
      end
      pbDrawShadowText(b, x, y, -1, 16, status_text, status_color, SHADOW)
      y += 24

      # Tags
      if mod.tags.length > 0
        tag_x = x
        tag_h = 18
        mod.tags.each do |tag|
          tw = b.text_size(tag).width + 10
          if tag_x + tw > RIGHT_W - 12
            tag_x = x
            y += tag_h + 2
          end
          draw_rounded_rect(b, tag_x, y, tw, tag_h, TAG_BG)
          pbDrawShadowText(b, tag_x + 5, y - 4, tw, tag_h, tag, GRAY, SHADOW)
          tag_x += tw + 4
        end
        y += tag_h + 4
      end

      # Separator
      b.fill_rect(x, y, RIGHT_W - 24, 1, PANEL_BORDER)
      y += 6

      # Description — scrollable
      hint_y = CONTENT_H - 22
      pbSetSmallFont(b)
      desc = mod.description
      if desc && !desc.empty?
        max_desc_y = hint_y - 4
        start_y = y
        # Split by explicit newlines first
        raw_lines = desc.split("\n")
        display_lines = []
        raw_lines.each do |raw_line|
          words = raw_line.split(" ")
          if words.empty?
            display_lines << ""
            next
          end
          current = ""
          words.each do |word|
            test = current.empty? ? word : "#{current} #{word}"
            if b.text_size(test).width > RIGHT_W - 28
              display_lines << current
              current = word
            else
              current = test
            end
          end
          display_lines << current unless current.empty?
        end

        display_lines.each_with_index do |line, i|
          next if i < (@desc_scroll || 0)
          break if y + 15 > max_desc_y
          pbDrawShadowText(b, x, y, RIGHT_W - 28, 16, line, GRAY, SHADOW)
          y += 16
        end

        # Scrollbar
        max_visible = (max_desc_y - start_y) / 16
        if display_lines.length > max_visible
          sb_x = RIGHT_W - 14
          sb_y = start_y
          sb_h = max_desc_y - sb_y
          b.fill_rect(sb_x, sb_y, 10, sb_h, Color.new(0, 0, 0, 60))
          
          handle_h = [ (sb_h.to_f * max_visible / display_lines.length).to_i, 16].max
          max_scroll = display_lines.length - max_visible
          @desc_scroll = (@desc_scroll || 0).clamp(0, max_scroll)
          
          if @dragging_desc
            my = (Input.mouse_y rescue -1) - @right_spr.y
            ratio = (my - sb_y).to_f / sb_h
            @desc_scroll = (display_lines.length * ratio - max_visible / 2).to_i.clamp(0, max_scroll)
          end

          handle_y = sb_y + (sb_h - handle_h) * @desc_scroll.to_f / max_scroll
          b.fill_rect(sb_x + 1, handle_y, 8, handle_h, GRAY)
          @desc_scrollbar_rect = Rect.new(sb_x, sb_y, 10, sb_h)
        else
          @desc_scrollbar_rect = nil
          @desc_scroll = 0
        end
      end
      y += 6

      # Dependencies
      if mod.dependencies.length > 0 && y + 16 < hint_y
        pbDrawShadowText(b, x, y, -1, 14, "Dependencies:", WHITE, SHADOW)
        y += 14
        dep_results = ModManager.check_dependencies(mod.id)
        dep_results.each do |dep|
          break if y + 14 > hint_y
          status = dep["status"]
          dep_name = dep["id"]
          dep_mod = ModManager.get_mod(dep["id"])
          dep_name = dep_mod.name if dep_mod
          case status
          when "ok"
            pbDrawShadowText(b, x + 8, y, -1, 14, "#{dep_name} v#{dep["required"]}+", GREEN, SHADOW)
          when "missing"
            pbDrawShadowText(b, x + 8, y, -1, 14, "#{dep_name} (missing!)", RED, SHADOW)
          when "version_mismatch"
            pbDrawShadowText(b, x + 8, y, -1, 14,
              "#{dep_name} needs v#{dep["required"]}+ (have v#{dep["installed"]})", ORANGE, SHADOW)
          end
          y += 14
        end
        y += 4
      end

      # Incompatibilities
      if conflicts.length > 0 && y + 16 < hint_y
        pbDrawShadowText(b, x, y, -1, 14, "Conflicts:", RED, SHADOW)
        y += 14
        conflicts.each do |cid|
          break if y + 14 > hint_y
          cmod = ModManager.get_mod(cid)
          cname = cmod ? cmod.name : cid
          pbDrawShadowText(b, x + 8, y, -1, 14, cname, RED, SHADOW)
          y += 14
        end
        y += 4
      end

      # Controls hint at bottom
      pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14,
                       "Z: Actions  |  F: Filter  |  S: Search", DIM, SHADOW, 2)
    end

    FOOTER_BUTTONS = ["Mod Browser", "Share Code", "Modder Tools", "Back"]

    def draw_footer
      b = @footer_spr.bitmap
      b.clear
      b.fill_rect(0, 0, SCREEN_W, FOOTER_H, FOOTER_BG)

      buttons = FOOTER_BUTTONS
      btn_w = SCREEN_W / buttons.length

      pbSetSmallFont(b)
      buttons.each_with_index do |label, i|
        bx = i * btn_w
        if @focus == :footer && @footer_index == i
          draw_rounded_rect(b, bx + 4, 4, btn_w - 8, FOOTER_H - 8, FOOTER_SEL)
          pbDrawShadowText(b, bx, 0, btn_w, FOOTER_H, label, WHITE, SHADOW, 2)
        else
          pbDrawShadowText(b, bx, 0, btn_w, FOOTER_H, label, GRAY, SHADOW, 2)
        end
      end
    end

    #==========================================================================
    # Input
    #==========================================================================
    def handle_input
      # Mouse handling (every frame)
      handle_mouse

      # When search bar is active, capture keyboard input
      if @search_active
        handle_search_input
        return
      end

      # Back / Right-click
      if Input.trigger?(Input::B) || Input.trigger?(Input::MOUSERIGHT)
        if @focus == :footer
          @focus = :list
          draw_left
          draw_footer
        else
          @running = false
        end
        return
      end

      # Activate search (S key)
      if _key_trigger?(0x53)  # S
        activate_search
        return
      end

      # MM update (U key)
      if _key_trigger?(0x55) && @mm_update_available  # U
        do_mm_update
        return
      end

      # Filter (F key)
      if _key_trigger?(0x46)  # F
        tags = ModManager::VALID_TAGS + ["Clear Filter"]
        choice = show_message("Filter by tag:", tags)
        if choice >= 0 && choice < ModManager::VALID_TAGS.length
          @active_filter = ModManager::VALID_TAGS[choice]
        else
          @active_filter = nil
        end
        @sel_index = 0
        @scroll = 0
        apply_filter
        draw_title
        draw_left
        draw_right
        return
      end

      if @focus == :list
        handle_list_input
      else
        handle_footer_input
      end
    end

    #==========================================================================
    # Live Search
    #==========================================================================
    def activate_search
      @search_active = true
      @cursor_frame = 0
      @focus = :list
      draw_left
    end

    def deactivate_search
      @search_active = false
      @search_text = ""
      @sel_index = 0
      @scroll = 0
      apply_filter
      draw_title
      draw_left
      draw_right
    end

    def handle_search_input
      # ESC / Enter / Right-click — close search
      if Input.trigger?(Input::B) || _key_trigger?(0x0D) || Input.trigger?(Input::MOUSERIGHT)
        deactivate_search
        return
      end

      old_text = @search_text

      # Backspace
      if _key_repeat?(0x08)  # VK_BACK
        @search_text = @search_text[0...-1] unless @search_text.empty?
      end

      # Delete all (Ctrl+Backspace or Delete)
      if _key_trigger?(0x2E)  # VK_DELETE
        @search_text = ""
      end

      # Type characters: A-Z
      (0x41..0x5A).each do |vk|
        if _key_trigger?(vk)
          shift = _key_pressed?(0x10)  # VK_SHIFT
          ch = (vk - 0x41 + 97).chr  # lowercase
          ch = ch.upcase if shift
          @search_text += ch if @search_text.length < 30
        end
      end

      # 0-9
      (0x30..0x39).each do |vk|
        if _key_trigger?(vk)
          @search_text += (vk - 0x30).to_s if @search_text.length < 30
        end
      end

      # Space
      if _key_trigger?(0x20)  # VK_SPACE
        @search_text += " " if @search_text.length < 30
      end

      # Minus / underscore
      if _key_trigger?(0xBD)  # VK_OEM_MINUS
        shift = _key_pressed?(0x10)
        @search_text += (shift ? "_" : "-") if @search_text.length < 30
      end

      # If text changed, re-filter
      if @search_text != old_text
        @sel_index = 0
        @scroll = 0
        apply_filter
        draw_title
        draw_left
        draw_right
      end
    end

    #==========================================================================
    # Mouse
    #==========================================================================
    def handle_mouse
      mx = Input.mouse_x rescue nil
      my = Input.mouse_y rescue nil
      return unless mx && my

      clicked = Input.trigger?(Input::MOUSELEFT) rescue false
      old_sel = @sel_index
      old_focus = @focus
      old_footer = @footer_index

      # Left panel hit test (mod list)
      lx = @left_spr.x
      ly = @left_spr.y
      if mx >= lx && mx < lx + LEFT_W && my >= ly + LIST_Y && my < ly + LIST_Y + LIST_H
        row = ((my - ly - LIST_Y) / ROW_H).floor
        real_index = @scroll + row
        if real_index >= 0 && real_index < @filtered_mods.length
          @focus = :list
          @sel_index = real_index
          if clicked
            open_action_menu(selected_mod) if selected_mod
            return
          end
        end
      end

      # Search bar hit test
      if clicked && mx >= lx && mx < lx + LEFT_W && my >= ly && my < ly + SEARCH_H
        activate_search unless @search_active
        return
      end

      # Click outside search bar deactivates search
      if clicked && @search_active
        deactivate_search
      end

      # Footer hit test
      fy = @footer_spr.y
      if my >= fy && my < fy + FOOTER_H
        btn_count = FOOTER_BUTTONS.length
        btn_w = SCREEN_W / btn_count
        btn_idx = (mx / btn_w).floor.clamp(0, btn_count - 1)
        @focus = :footer
        @footer_index = btn_idx
        if clicked
          case @footer_index
          when 0 then open_browser
          when 1 then do_share_code
          when 2 then open_modder_tools
          when 3 then @running = false
          end
          return
        end
      end

      # Description scrolling
      mx ||= -1; my ||= -1
      rx = @right_spr.x; ry = @right_spr.y
      if mx >= rx && mx < rx + RIGHT_W && my >= ry && my < ry + CONTENT_H
        mw = (_mouse_scroll rescue 0)
        if mw != 0
          old_scroll = @desc_scroll || 0
          @desc_scroll = [old_scroll - mw, 0].max
          # clamping is done in draw_right
          draw_right
        end
        
        # Scrollbar dragging
        if @desc_scrollbar_rect && clicked && mx >= rx + @desc_scrollbar_rect.x && mx < rx + @desc_scrollbar_rect.x + @desc_scrollbar_rect.width &&
           my >= ry + @desc_scrollbar_rect.y && my < ry + @desc_scrollbar_rect.y + @desc_scrollbar_rect.height
          @dragging_desc = true
        end
      end

      if @dragging_desc
        if !Input.press?(Input::MOUSELEFT)
          @dragging_desc = false
        else
          # Calculate scroll based on mouse Y
          # This is simplified; we'll refine it in draw_right if needed
          # For now, just trigger redraw
          draw_right
        end
      end

      # Redraw if selection or focus changed
      if @sel_index != old_sel || @focus != old_focus || @footer_index != old_footer || @dragging_desc
        draw_left if @sel_index != old_sel || @focus != old_focus
        draw_right if @sel_index != old_sel || @dragging_desc
        draw_footer if @focus != old_focus || @footer_index != old_footer
      end
    end

    def handle_list_input
      changed = false

      # Navigate up/down
      if Input.repeat?(Input::UP) && @filtered_mods.length > 0
        @sel_index = (@sel_index - 1) % @filtered_mods.length
        ensure_visible
        changed = true
      elsif Input.repeat?(Input::DOWN) && @filtered_mods.length > 0
        @sel_index = (@sel_index + 1) % @filtered_mods.length
        ensure_visible
        changed = true
      end

      # Switch to footer
      if Input.trigger?(Input::DOWN) && @filtered_mods.length == 0
        @focus = :footer
        changed = true
      end

      # Tab to footer
      if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
        @focus = :footer
        draw_left
        draw_footer
        return
      end

      # Action on selected mod
      if Input.trigger?(Input::C) && selected_mod
        open_action_menu(selected_mod)
        return
      end

      if changed
        draw_left
        draw_right
      end
    end

    def handle_footer_input
      btn_count = FOOTER_BUTTONS.length
      if Input.trigger?(Input::LEFT)
        @footer_index = (@footer_index - 1) % btn_count
        draw_footer
      elsif Input.trigger?(Input::RIGHT)
        @footer_index = (@footer_index + 1) % btn_count
        draw_footer
      elsif Input.trigger?(Input::UP)
        @focus = :list
        draw_left
        draw_footer
      elsif Input.trigger?(Input::C)
        case @footer_index
        when 0 then open_browser        # Mod Browser
        when 1 then do_share_code       # Share Code
        when 2 then open_modder_tools   # Modder Tools
        when 3 then @running = false    # Back
        end
      end
    end

    #==========================================================================
    # Actions
    #==========================================================================
    def open_action_menu(mod_info)
      # Special entries
      if _is_mp_entry?(mod_info)
        _open_mp_action_menu(mod_info)
        return
      end
      if mod_info.id == "_aleks_npt"
        _open_npt_action_menu(mod_info)
        return
      end

      enabled = ModManager.enabled?(mod_info.id)
      toggle_label = enabled ? "Disable" : "Enable"
      has_settings = mod_info.settings_defs.length > 0

      cmds = [toggle_label]
      cmds << "Settings" if has_settings
      cmds << "Uninstall"
      cmds << "Cancel"

      choice = show_message(mod_info.name, cmds)
      return if choice < 0 || cmds[choice] == "Cancel"

      case cmds[choice]
      when toggle_label
        if !enabled
          # Auto-enable dependencies
          deps = ModManager.check_dependencies(mod_info.id)
          disabled_deps = deps.select { |d| d["status"] == "ok" && !ModManager.enabled?(d["id"]) }
          missing_deps = deps.select { |d| d["status"] == "missing" }

          if disabled_deps.length > 0
            dep_names = disabled_deps.map { |d|
              dm = ModManager.get_mod(d["id"])
              dm ? dm.name : d["id"]
            }.join(", ")
            if show_message("Enable required dependencies?\n#{dep_names}", ["Yes", "No"]) == 0
              disabled_deps.each do |d|
                ModManager.state[d["id"]] ||= {}
                ModManager.state[d["id"]]["enabled"] = true
              end
              ModManager.save_state
            end
          end

          if missing_deps.length > 0
            missing_names = missing_deps.map { |d| d["id"] }.join(", ")
            show_message("Warning: Missing dependencies:\n#{missing_names}\n\nInstall from Mod Browser.")
          end

          # Check incompatibilities before enabling
          conflicts = ModManager.check_incompatibilities(mod_info.id)
          if conflicts.length > 0
            conflict_names = conflicts.map { |cid|
              cm = ModManager.get_mod(cid)
              cm ? cm.name : cid
            }.join(", ")
            show_message("Warning: This mod conflicts with:\n#{conflict_names}")
          end
        end
        ModManager.toggle(mod_info.id)
        refresh_data
        draw_left
        draw_right

      when "Settings"
        if defined?(ModManager::Scene_ModSettings)
          # Settings scene uses PokemonOption — must lower z for it
          @vp.z = 1 if @vp
          scene = ModManager::Scene_ModSettings.new(mod_info)
          scene.main
          @vp.z = 100_000 if @vp
          draw_left
          draw_right
        end

      when "Uninstall"
        if show_message("Uninstall #{mod_info.name}?\nThis cannot be undone.", ["Yes", "No"]) == 0
          ModManager.uninstall(mod_info.id)
          refresh_data
          draw_title
          draw_left
          draw_right
        end
      end
    end

    def _open_mp_action_menu(mod_info)
      cmds = ["Uninstall", "Cancel"]
      choice = show_message("KIF Multiplayer v#{mod_info.version}", cmds)
      return if choice < 0 || cmds[choice] == "Cancel"

      if cmds[choice] == "Uninstall"
        confirm = show_message(
          "This will delete KIF Multiplayer and\nrestart the game. Continue?",
          ["Yes", "No"]
        )
        return unless confirm == 0

        # Delete the 659_Multiplayer folder
        mp_path = "Data/Scripts/659_Multiplayer"
        if File.directory?(mp_path)
          _delete_recursive(mp_path)
        end

        # Force restart
        show_message("KIF Multiplayer has been removed.\nThe game will now restart.")
        if File.file?("Game.exe")
          Process.spawn("Game.exe")
        end
        exit
      end
    end

    def _open_npt_action_menu(mod_info)
      show_message(
        "Aleks Full Implementation v#{mod_info.version}\n" \
        "by #{mod_info.author}\n\n" \
        "#{mod_info.description}\n\n" \
        "This mod cannot be uninstalled from\nthe Mod Manager."
      )
    end

    def _delete_recursive(path)
      return unless File.directory?(path)
      Dir.foreach(path) do |entry|
        next if entry == "." || entry == ".."
        full = File.join(path, entry)
        if File.directory?(full)
          _delete_recursive(full)
        else
          File.delete(full) rescue nil
        end
      end
      Dir.rmdir(path) rescue nil
    end

    def do_share_code
      enabled = ModManager.enabled_mods
      installed = enabled.map { |id| ModManager.get_mod(id) }.compact
      # Remove special entries
      installed = installed.reject { |m| _is_special_entry?(m) }

      if installed.empty?
        show_message("No enabled mods to export.")
        return
      end

      entries = installed.map { |info| { "id" => info.id, "version" => info.version } }
      code = ModManager.encode_share_code(entries)
      if code
        if ModManager.clipboard_write(code)
          show_message("Share code copied to clipboard!\n\n#{code}")
        else
          show_message("Share code generated:\n\n#{code}\n\n(Could not copy to clipboard)")
        end
      else
        show_message("Failed to generate share code.")
      end
    end

    def do_mm_update(skip_confirm: false)
      return unless @mm_update_available && @mm_remote_version
      local_v = ModManager::GitHub.mm_local_version || "?"

      unless skip_confirm
        result = show_message(
          "Update Mod Manager?\n#{local_v} -> #{@mm_remote_version}\n\nThe game will close after updating.",
          ["Update", "Cancel"]
        )
        return if result != 0
      end

      game_root = File.expand_path(".")
      sevenz    = File.join(game_root, "REQUIRED_BY_INSTALLER_UPDATER", "7z.exe")
      temp_rar  = File.join(game_root, "_mm_update.7z")

      show_status("Downloading Mod Manager v#{@mm_remote_version}...")
      begin
        pbDownloadToFile(ModManager::GitHub::MM_ARCHIVE_URL, temp_rar)

        unless File.exist?(temp_rar) && File.size(temp_rar) > 1024
          hide_status
          show_message("Download failed — archive missing or too small.\nThe Mod Manager was not modified.")
          File.delete(temp_rar) rescue nil
          return
        end

        unless File.exist?(sevenz)
          hide_status
          show_message("7z.exe not found at:\n#{sevenz}\n\nThe Mod Manager was not modified.")
          File.delete(temp_rar) rescue nil
          return
        end

        show_status("Extracting Mod Manager...")
        # -y = auto-yes to overwrites, -o = output dir
        cmd = "\"#{sevenz}\" x -y -o\"#{game_root}\" \"#{temp_rar}\""
        ok = system(cmd)
        File.delete(temp_rar) rescue nil

        hide_status
        unless ok
          show_message("Extraction failed.\nThe Mod Manager may be partially updated.\nPlease re-run the installer.")
          return
        end

        show_message("Mod Manager updated to v#{@mm_remote_version}!\n\nThe game will now close.\nPlease relaunch to apply changes.")
        Kernel.exit
      rescue => e
        hide_status
        File.delete(temp_rar) rescue nil
        show_message("Update failed: #{e.message}\n\nThe Mod Manager was not modified.")
      end
    end

    def show_status(text)
      hide_status
      @status_dim = Sprite.new(@vp)
      @status_dim.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      @status_dim.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H, Color.new(0, 0, 0, 120))
      @status_dim.z = 900

      box_w = 280
      box_h = 48
      @status_box = Sprite.new(@vp)
      @status_box.bitmap = Bitmap.new(box_w, box_h)
      @status_box.x = (SCREEN_W - box_w) / 2
      @status_box.y = (SCREEN_H - box_h) / 2
      @status_box.z = 901
      draw_rounded_rect(@status_box.bitmap, 0, 0, box_w, box_h, Color.new(40, 35, 60))
      draw_border(@status_box.bitmap, 0, 0, box_w, box_h, Color.new(120, 100, 180))
      pbSetSmallFont(@status_box.bitmap)
      pbDrawShadowText(@status_box.bitmap, 0, 14, box_w, 20, text, WHITE, SHADOW, 2)
      Graphics.update
    end

    def hide_status
      if @status_box
        @status_box.bitmap.dispose rescue nil
        @status_box.dispose rescue nil
        @status_box = nil
      end
      if @status_dim
        @status_dim.bitmap.dispose rescue nil
        @status_dim.dispose rescue nil
        @status_dim = nil
      end
    end

    def open_browser
      # Check marker file BEFORE creating the browser scene.
      # HTTPLite has no timeout — calling it against a non-existent host
      # will freeze the entire game and potentially the computer.
      marker = File.join(ModManager::MOD_DIR, ".mod_browser_enabled")
      unless File.exist?(marker)
        show_message(
          "Mod Browser is not yet configured.\n\n" \
          "The GitHub repository (KIF-Mods/mods) needs to\n" \
          "be created first. Once ready, place a file called\n" \
          ".mod_browser_enabled inside your Mods/ folder."
        )
        return
      end

      if defined?(ModManager::Scene_Browser)
        scene = ModManager::Scene_Browser.new
        scene.main
        # Refresh after returning (mods may have been installed)
        refresh_data
        draw_title
        draw_left
        draw_right
      else
        show_message("Mod Browser not available yet.")
      end
    end

    def open_modder_tools
      if defined?(ModManager::Scene_ModderTools)
        # Modder Tools has its own viewport at z=200,000
        # so it renders on top of everything including our overlay
        scene = ModManager::Scene_ModderTools.new
        scene.main
      else
        show_message("Modder Tools not available yet.")
      end
    end

    #==========================================================================
    # Helpers
    #==========================================================================
    def _init_gas
      @_gas ||= begin
        Win32API.new('user32', 'GetAsyncKeyState', ['i'], 'i')
      rescue
        nil
      end
    end

    def _window_active?
      @_gfw ||= Win32API.new('user32', 'GetForegroundWindow', [], 'l') rescue nil
      @_gwtpi ||= Win32API.new('user32', 'GetWindowThreadProcessId', ['l', 'p'], 'l') rescue nil
      return true unless @_gfw && @_gwtpi
      hwnd = @_gfw.call
      pid_buf = "\0" * 4
      @_gwtpi.call(hwnd, pid_buf)
      fg_pid = pid_buf.unpack('L')[0]
      fg_pid == Process.pid
    rescue
      true
    end

    # Returns true on the frame a key is first pressed (low bit)
    def _key_trigger?(vk_code)
      _init_gas
      return false unless @_gas && _window_active?
      (@_gas.call(vk_code) & 0x01) != 0
    rescue
      false
    end

    # Returns true if a key is currently held down (high bit)
    def _key_pressed?(vk_code)
      _init_gas
      return false unless @_gas && _window_active?
      (@_gas.call(vk_code) & 0x8000) != 0
    rescue
      false
    end

    # Simple key repeat: trigger + debounce via frame counting
    def _key_repeat?(vk_code)
      @_repeat_timers ||= {}
      if _key_pressed?(vk_code)
        @_repeat_timers[vk_code] ||= 0
        @_repeat_timers[vk_code] += 1
        # Fire on first frame, then every 4 frames after 12 frame delay
        t = @_repeat_timers[vk_code]
        return t == 1 || (t > 12 && t % 4 == 0)
      else
        @_repeat_timers[vk_code] = 0
        return false
      end
    end

    def _mouse_scroll
      0
    end

    # Show a message box inside our viewport (so overlay stays visible).
    # Waits for Z/Enter/click to dismiss. Returns chosen index for choices.
    def show_message(text, choices = nil)
      # Consume lingering key states so they don't bleed from previous action
      _init_gas
      if @_gas
        [0x0D, 0x5A, 0x20].each { |vk| @_gas.call(vk) }  # Enter, Z, Space
      end
      Graphics.update
      Input.update

      # Darken overlay
      dim = Sprite.new(@vp)
      dim.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      dim.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H, Color.new(0, 0, 0, 120))
      dim.z = 900

      # Message box
      box_w = 320
      lines = text.split("\n")
      choice_count = choices ? choices.length : 0
      line_h = 18
      padding = 16
      box_h = padding * 2 + lines.length * line_h + (choice_count > 0 ? choice_count * line_h + 8 : line_h)
      box_x = (SCREEN_W - box_w) / 2
      box_y = (SCREEN_H - box_h) / 2

      box = Sprite.new(@vp)
      box.bitmap = Bitmap.new(box_w, box_h)
      box.x = box_x
      box.y = box_y
      box.z = 901

      b = box.bitmap
      draw_rounded_rect(b, 0, 0, box_w, box_h, Color.new(40, 35, 60))
      draw_border(b, 0, 0, box_w, box_h, Color.new(120, 100, 180))

      pbSetSmallFont(b)
      ty = padding
      lines.each do |line|
        pbDrawShadowText(b, padding, ty, box_w - padding * 2, line_h, line, WHITE, SHADOW)
        ty += line_h
      end

      selected = 0
      if choices
        ty += 4
        _draw_choices(b, choices, selected, padding, ty, box_w, line_h)
      else
        # "OK" prompt
        ty += 4
        pbDrawShadowText(b, 0, ty, box_w, line_h, "[OK]", GRAY, SHADOW, 2)
      end

      # Input loop
      loop do
        Graphics.update
        Input.update

        if choices
          old_sel = selected
          if Input.trigger?(Input::UP)
            selected = (selected - 1) % choices.length
          elsif Input.trigger?(Input::DOWN)
            selected = (selected + 1) % choices.length
          end

          # Mouse hover on choices
          mx = Input.mouse_x rescue nil
          my = Input.mouse_y rescue nil
          if mx && my
            choice_base_y = box_y + padding + lines.length * line_h + 4
            if mx >= box_x + padding && mx < box_x + box_w - padding
              choices.each_with_index do |_, ci|
                cy = choice_base_y + ci * line_h
                if my >= cy && my < cy + line_h
                  selected = ci
                  break
                end
              end
            end
          end

          if selected != old_sel
            _draw_choices(b, choices, selected, padding,
                          padding + lines.length * line_h + 4, box_w, line_h)
          end

          if Input.trigger?(Input::C) || (Input.trigger?(Input::MOUSELEFT) rescue false)
            break
          end
        else
          if Input.trigger?(Input::C) || Input.trigger?(Input::B) ||
             (Input.trigger?(Input::MOUSELEFT) rescue false)
            break
          end
        end

        # B / right-click cancels (returns last choice or -1)
        if choices && (Input.trigger?(Input::B) || (Input.trigger?(Input::MOUSERIGHT) rescue false))
          selected = choices.length - 1
          break
        end
      end

      # Cleanup
      box.bitmap.dispose
      box.dispose
      dim.bitmap.dispose
      dim.dispose

      selected
    end

    def _draw_choices(bmp, choices, selected, px, ty, box_w, line_h)
      # Clear the choices area
      bmp.fill_rect(px, ty - 2, box_w - px * 2, choices.length * line_h + 4, Color.new(40, 35, 60))
      choices.each_with_index do |label, i|
        if i == selected
          bmp.fill_rect(px, ty + i * line_h, box_w - px * 2, line_h, Color.new(80, 60, 130))
          pbDrawShadowText(bmp, px + 8, ty + i * line_h, box_w - px * 2, line_h, "> #{label}", WHITE, SHADOW)
        else
          pbDrawShadowText(bmp, px + 8, ty + i * line_h, box_w - px * 2, line_h, label, GRAY, SHADOW)
        end
      end
    end

    def draw_rounded_rect(bmp, x, y, w, h, color)
      bmp.fill_rect(x + 2, y, w - 4, h, color)
      bmp.fill_rect(x, y + 2, w, h - 4, color)
      bmp.fill_rect(x + 1, y + 1, w - 2, h - 2, color)
    end

    def draw_border(bmp, x, y, w, h, color)
      bmp.fill_rect(x + 2, y, w - 4, 1, color)
      bmp.fill_rect(x + 2, y + h - 1, w - 4, 1, color)
      bmp.fill_rect(x, y + 2, 1, h - 4, color)
      bmp.fill_rect(x + w - 1, y + 2, 1, h - 4, color)
    end
  end
end
