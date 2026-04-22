#==============================================================================
# Mod Manager — Modder Tools
#
# In-game forms for creating and updating mods.
# Output goes to ModDev/ folder (separate from Mods/).
# All UI renders in its own viewport at z=200,000 so it appears
# on top of the Mod Manager overlay (z=100,000).
#==============================================================================

module ModManager
  class Scene_ModderTools
    # Colors
    BG_COLOR     = Color.new(0, 0, 0, 140)
    BOX_BG       = Color.new(40, 35, 60)
    BOX_BORDER   = Color.new(120, 100, 180)
    SEL_BG       = Color.new(80, 60, 130)
    WHITE        = Color.new(255, 255, 255)
    GRAY         = Color.new(180, 180, 180)
    DIM          = Color.new(120, 120, 140)
    SHADOW       = Color.new(20, 18, 30)
    GREEN        = Color.new(100, 220, 120)
    INPUT_BG     = Color.new(50, 45, 70)
    INPUT_BORDER = Color.new(140, 120, 200)
    SCREEN_W     = 512
    SCREEN_H     = 384

    def initialize
      @vp = nil
      @dim = nil
      @_gas = nil
    end

    def main
      @vp = Viewport.new(0, 0, SCREEN_W, SCREEN_H)
      @vp.z = 200_000

      @dim = Sprite.new(@vp)
      @dim.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      @dim.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H, BG_COLOR)
      @dim.z = 0

      loop do
        main_choice, sub_choice = ui_main_menu
        break if main_choice.nil?
        case main_choice
        when 0 # Create
          create_mod if sub_choice == 0
          create_modpack if sub_choice == 1
        when 1 # Update
          update_mod if sub_choice == 0
          update_modpack if sub_choice == 1
        when 2 # Upload
          upload_mod if sub_choice == 0
          upload_modpack if sub_choice == 1
        when 3 # Delete
          delete_mod if sub_choice == 0
          delete_modpack if sub_choice == 1
        when 4 # Delete from Repo
          delete_from_repo if sub_choice == 0
          delete_modpack_from_repo if sub_choice == 1
        end
      end

      @dim.bitmap.dispose if @dim && @dim.bitmap && !@dim.bitmap.disposed?
      @dim.dispose if @dim
      @vp.dispose if @vp
      @vp = nil
    end

    #==========================================================================
    # Main Menu with hover submenus
    # Returns [main_index, sub_index] or nil to exit
    #==========================================================================
    MENU_ITEMS = ["Create", "Update", "Upload", "Delete", "Delete from Repo", "Settings", "Back"]
    SUB_ITEMS  = ["Mod", "Modpack"]
    # Indices 0..4 have submenus, 5..6 do not
    SUBMENU_COUNT = 5

    def ui_main_menu
      _wait_key_release

      override = ModManager.moddev_override? ? "[ON]" : "[OFF]"
      dynamic_menu = MENU_ITEMS.dup
      dynamic_menu[5] = "ModDev: #{override}"

      line_h = 18
      pad = 16
      title = "Modder Tools"

      # Main menu box dimensions
      main_w = 200
      main_h = pad * 2 + line_h + MENU_ITEMS.length * line_h + 4
      main_x = (SCREEN_W - main_w) / 2 - 60
      main_y = (SCREEN_H - main_h) / 2

      # Submenu box dimensions (appears to the right)
      sub_w = 130
      sub_h = pad * 2 + SUB_ITEMS.length * line_h
      sub_x = main_x + main_w + 4
      sub_y = main_y  # will be adjusted per-item

      # Main menu sprite
      main_spr = Sprite.new(@vp)
      main_spr.bitmap = Bitmap.new(main_w, main_h)
      main_spr.x = main_x
      main_spr.y = main_y
      main_spr.z = 10

      # Submenu sprite
      sub_spr = Sprite.new(@vp)
      sub_spr.bitmap = Bitmap.new(sub_w, sub_h)
      sub_spr.x = sub_x
      sub_spr.y = sub_y
      sub_spr.z = 10
      sub_spr.visible = false

      selected = 0
      sub_selected = -1  # -1 = not in submenu
      in_submenu = false
      last_selected = -1
      last_sub_selected = -2
      last_in_submenu = nil

      result = nil

      loop do
        # Redraw main menu if selection changed
        if selected != last_selected || in_submenu != last_in_submenu
          b = main_spr.bitmap
          b.clear
          _draw_box_bg(b, main_w, main_h)
          pbSetSmallFont(b)

          # Title
          pbDrawShadowText(b, pad, pad, main_w - pad * 2, line_h, title, WHITE, SHADOW)
          ty = pad + line_h + 4

          MENU_ITEMS.each_with_index do |_, i|
            label = dynamic_menu[i]
            arrow = (i < SUBMENU_COUNT) ? "  >" : ""
            if i == selected
              b.fill_rect(pad, ty + i * line_h, main_w - pad * 2, line_h, SEL_BG)
              col = in_submenu ? GRAY : WHITE
              pbDrawShadowText(b, pad + 8, ty + i * line_h, main_w - pad * 2 - 16, line_h, "> #{label}#{arrow}", col, SHADOW)
            else
              pbDrawShadowText(b, pad + 8, ty + i * line_h, main_w - pad * 2 - 16, line_h, "#{label}#{arrow}", GRAY, SHADOW)
            end
          end
          last_selected = selected
          last_in_submenu = in_submenu
        end

        # Show/hide/redraw submenu
        if selected < SUBMENU_COUNT
          # Position submenu vertically aligned to the hovered main item
          item_screen_y = main_y + pad + line_h + 4 + selected * line_h
          new_sub_y = item_screen_y
          # Clamp to screen
          new_sub_y = SCREEN_H - sub_h if new_sub_y + sub_h > SCREEN_H
          new_sub_y = 0 if new_sub_y < 0
          sub_spr.y = new_sub_y

          if sub_selected != last_sub_selected || !sub_spr.visible
            sb = sub_spr.bitmap
            sb.clear
            _draw_box_bg(sb, sub_w, sub_h)
            pbSetSmallFont(sb)

            SUB_ITEMS.each_with_index do |label, i|
              sy = pad + i * line_h
              if in_submenu && i == sub_selected
                sb.fill_rect(pad, sy, sub_w - pad * 2, line_h, SEL_BG)
                pbDrawShadowText(sb, pad + 8, sy, sub_w - pad * 2, line_h, "> #{label}", WHITE, SHADOW)
              else
                pbDrawShadowText(sb, pad + 8, sy, sub_w - pad * 2, line_h, label, GRAY, SHADOW)
              end
            end
            last_sub_selected = sub_selected
          end
          sub_spr.visible = true
        else
          sub_spr.visible = false
          last_sub_selected = -2
        end

        Graphics.update
        Input.update

        # --- Mouse handling ---
        mx = Input.mouse_x rescue nil
        my = Input.mouse_y rescue nil
        if mx && my
          # Check if mouse is over submenu
          if sub_spr.visible &&
             mx >= sub_spr.x && mx < sub_spr.x + sub_w &&
             my >= sub_spr.y && my < sub_spr.y + sub_h
            hover_sub = (my - sub_spr.y - pad) / line_h
            if hover_sub >= 0 && hover_sub < SUB_ITEMS.length
              in_submenu = true
              sub_selected = hover_sub
            end
          # Check if mouse is over main menu
          elsif mx >= main_x && mx < main_x + main_w
            choice_base_y = main_y + pad + line_h + 4
            if my >= choice_base_y && my < choice_base_y + MENU_ITEMS.length * line_h
              hover_main = (my - choice_base_y) / line_h
              if hover_main >= 0 && hover_main < MENU_ITEMS.length
                selected = hover_main
                in_submenu = false
                sub_selected = 0
              end
            end
          end

          # Mouse click
          mouse_left = begin; Input.trigger?(Input::MOUSELEFT); rescue; false; end
          mouse_right = begin; Input.trigger?(Input::MOUSERIGHT); rescue; false; end

          if mouse_left
            if in_submenu && sub_spr.visible
              result = [selected, sub_selected]
              break
            elsif !in_submenu
              if selected == 5
                # Toggle ModDev override in-place
                _do_toggle_moddev(dynamic_menu)
                last_selected = -1 # trigger redraw
              elsif selected >= SUBMENU_COUNT
                # "Back"
                result = nil
                break
              else
                # Clicked on a main item with submenu — enter submenu
                in_submenu = true
                sub_selected = 0
              end
            end
          end

          if mouse_right
            if in_submenu
              in_submenu = false
              sub_selected = -1
            else
              result = nil
              break
            end
          end
        end

        # --- Keyboard handling ---
        if Input.trigger?(Input::UP)
          if in_submenu
            sub_selected = (sub_selected - 1) % SUB_ITEMS.length
          else
            selected = (selected - 1) % MENU_ITEMS.length
            sub_selected = 0
          end
        end

        if Input.trigger?(Input::DOWN)
          if in_submenu
            sub_selected = (sub_selected + 1) % SUB_ITEMS.length
          else
            selected = (selected + 1) % MENU_ITEMS.length
            sub_selected = 0
          end
        end

        if Input.trigger?(Input::RIGHT)
          if !in_submenu && selected < SUBMENU_COUNT
            in_submenu = true
            sub_selected = 0
          end
        end

        if Input.trigger?(Input::LEFT)
          if in_submenu
            in_submenu = false
            sub_selected = -1
          end
        end

        if Input.trigger?(Input::C)
          if in_submenu
            result = [selected, sub_selected]
            break
          elsif selected == 5
            # Toggle ModDev override in-place
            _do_toggle_moddev(dynamic_menu)
            last_selected = -1 # trigger redraw
          elsif selected >= SUBMENU_COUNT
            # "Back"
            result = nil
            break
          else
            # Enter submenu
            in_submenu = true
            sub_selected = 0
          end
        end

        if Input.trigger?(Input::B)
          if in_submenu
            in_submenu = false
            sub_selected = -1
          else
            result = nil
            break
          end
        end
      end

      main_spr.bitmap.dispose
      main_spr.dispose
      sub_spr.bitmap.dispose
      sub_spr.dispose
      result
    end

    def _do_toggle_moddev(dynamic_menu)
      msg = "ModDev Mode allows you to load mods from /ModDev/ instead of /Mods/ if a duplicate or unique folder name exists.\n\nUnique mods in /Mods/ will still load normally.\n\nToggle it now?"
      return if ui_message(msg, ["Yes", "Cancel"]) != 0
      
      ModManager.toggle_moddev_override
      override = ModManager.moddev_override? ? "[ON]" : "[OFF]"
      dynamic_menu[5] = "ModDev: #{override}"
      ui_message("ModDev is now #{override}.\n\nPlease restart the game for this\nto take effect.")
    end

    def ui_settings
      loop do
        override = ModManager.moddev_override? ? "[ON]" : "[OFF]"
        choices = [
          "ModDev Override: #{override}",
          "Back"
        ]
        choice = ui_message("Settings:", choices)
        case choice
        when 0
          ModManager.toggle_moddev_override
          ui_message("ModDev Override is now #{ModManager.moddev_override? ? 'ON' : 'OFF'}.\n\nMods will be re-scanned.")
        else
          break
        end
      end
    end

    #==========================================================================
    # Custom UI: Message box with choices (renders in our viewport)
    #==========================================================================
    def ui_message(text, commands = nil)
      _wait_key_release
      line_h = 18
      pad = 16
      box_w = 340
      
      # Dummy bitmap for text measurement
      temp_b = Bitmap.new(1, 1)
      pbSetSmallFont(temp_b)
      
      # Pre-calculate wrapped lines to determine box height
      wrapped_lines = []
      text.to_s.split("\n").each do |raw_line|
        words = raw_line.split(" ")
        if words.empty?
          wrapped_lines << ""
          next
        end
        current = ""
        words.each do |word|
          test = current.empty? ? word : "#{current} #{word}"
          if temp_b.text_size(test).width > box_w - pad * 2
            wrapped_lines << current
            current = word
          else
            current = test
          end
        end
        wrapped_lines << current unless current.empty?
      end
      temp_b.dispose

      choice_count = commands ? commands.length : 0
      box_h = pad * 2 + wrapped_lines.length * line_h + (choice_count > 0 ? choice_count * line_h + 8 : line_h + 4)
      box_x = (SCREEN_W - box_w) / 2
      box_y = (SCREEN_H - box_h) / 2

      spr = Sprite.new(@vp)
      spr.bitmap = Bitmap.new(box_w, box_h)
      spr.x = box_x
      spr.y = box_y
      spr.z = 10

      b = spr.bitmap
      _draw_box_bg(b, box_w, box_h)

      pbSetSmallFont(b)
      ty = pad
      wrapped_lines.each do |line|
        pbDrawShadowText(b, pad, ty, box_w - pad * 2, line_h, line, WHITE, SHADOW)
        ty += line_h
      end

      selected = 0
      if commands
        ty += 4
        _redraw_choices(b, commands, selected, pad, ty, box_w, line_h)
      else
        ty += 4
        pbDrawShadowText(b, 0, ty, box_w, line_h, "[OK]", GRAY, SHADOW, 2)
      end

      result = _run_choice_loop(spr, commands, selected, wrapped_lines, pad, box_x, box_y, box_w, line_h)

      spr.bitmap.dispose
      spr.dispose
      result
    end

    #==========================================================================
    # Custom UI: Text input (renders in our viewport)
    #==========================================================================
    def ui_text_input(prompt, max_len = 30, default = "")
      _wait_key_release
      line_h = 18
      pad = 16
      box_w = 360
      box_h = pad * 2 + line_h * 3 + 8
      box_x = (SCREEN_W - box_w) / 2
      box_y = (SCREEN_H - box_h) / 2

      spr = Sprite.new(@vp)
      spr.bitmap = Bitmap.new(box_w, box_h)
      spr.x = box_x
      spr.y = box_y
      spr.z = 10

      text = default.to_s.dup
      cursor_frame = 0

      loop do
        b = spr.bitmap
        b.clear
        _draw_box_bg(b, box_w, box_h)
        pbSetSmallFont(b)
        
        # Wrapped prompt
        py = pad
        prompt.split("\n").each do |p_line|
          words = p_line.split(" ")
          curr = ""
          words.each do |w|
            t = curr.empty? ? w : "#{curr} #{w}"
            if b.text_size(t).width > box_w - pad * 2
              pbDrawShadowText(b, pad, py, box_w - pad * 2, line_h, curr, WHITE, SHADOW)
              py += line_h
              curr = w
            else
              curr = t
            end
          end
          pbDrawShadowText(b, pad, py, box_w - pad * 2, line_h, curr, WHITE, SHADOW)
          py += line_h
        end

        iy = py + 4
        input_w = box_w - pad * 2
        b.fill_rect(pad, iy, input_w, line_h + 4, INPUT_BG)
        _draw_rect_border(b, pad, iy, input_w, line_h + 4, INPUT_BORDER)
        cursor = (cursor_frame / 20) % 2 == 0 ? "|" : ""
        pbDrawShadowText(b, pad + 4, iy + 1, input_w - 8, line_h, text + cursor, WHITE, SHADOW)
        hy = iy + line_h + 8
        pbDrawShadowText(b, 0, hy, box_w, line_h, "Enter: confirm  |  Esc: cancel", DIM, SHADOW, 2)
        Graphics.update
        Input.update
        cursor_frame += 1
        break if _key_trigger?(0x0D)
        if Input.trigger?(Input::B)
          text = nil
          break
        end
        text = text[0...-1] if _key_repeat?(0x08) && !text.empty?
        text = "" if _key_trigger?(0x2E)
        (0x41..0x5A).each do |vk|
          if _key_trigger?(vk)
            shift = _key_pressed?(0x10); ch = (vk - 0x41 + 97).chr
            ch = ch.upcase if shift; text += ch if text.length < max_len
          end
        end
        (0x30..0x39).each do |vk|
          if _key_trigger?(vk)
            shift = _key_pressed?(0x10)
            if shift
              specials = {0x30=>")", 0x31=>"!", 0x32=>"@", 0x33=>"#", 0x34=>"$", 0x35=>"%", 0x36=>"^", 0x37=>"&", 0x38=>"*", 0x39=>"("}
              text += specials[vk] if text.length < max_len
            else
              text += (vk - 0x30).to_s if text.length < max_len
            end
          end
        end
        [0x20, 0xBE, 0xBC, 0xBD, 0xBB, 0xBA, 0xBF, 0xDB, 0xDD, 0xDE].each do |vk|
          if _key_trigger?(vk)
            shift = _key_pressed?(0x10)
            ch = case vk
            when 0x20 then " "
            when 0xBE then shift ? ">" : "."
            when 0xBC then shift ? "<" : ","
            when 0xBD then shift ? "_" : "-"
            when 0xBB then shift ? "+" : "="
            when 0xBA then shift ? ":" : ";"
            when 0xBF then shift ? "?" : "/"
            when 0xDB then shift ? "{" : "["
            when 0xDD then shift ? "}" : "]"
            when 0xDE then shift ? "\"" : "'"
            end
            text += ch if ch && text.length < max_len
          end
        end
      end
      spr.bitmap.dispose
      spr.dispose
      text
    end

    def ui_multiline_input(prompt, max_lines = 10, max_len = 500, default = "")
      _wait_key_release
      line_h = 18
      pad = 16
      box_w = 400
      
      # Temporary bitmap to calculate dynamic box_h
      temp_b = Bitmap.new(box_w, 1000)
      pbSetSmallFont(temp_b)
      py = pad
      prompt.split("\n").each do |p_line|
        words = p_line.split(" ")
        curr = ""
        words.each do |w|
          t = curr.empty? ? w : "#{curr} #{w}"
          if temp_b.text_size(t).width > box_w - pad * 2
            py += line_h
            curr = w
          else
            curr = t
          end
        end
        py += line_h
      end
      input_h = line_h * max_lines + 8
      box_h = py + input_h + pad + 32 # extra space for labels
      temp_b.dispose

      box_x = (SCREEN_W - box_w) / 2
      box_y = (SCREEN_H - box_h) / 2

      spr = Sprite.new(@vp)
      spr.bitmap = Bitmap.new(box_w, box_h)
      spr.x = box_x
      spr.y = box_y
      spr.z = 10

      text = default.to_s.dup
      scroll = 0
      cursor_pos = text.length # Use index for cursor
      cursor_frame = 0
      dragging_scroll = false
      should_autoscroll = true

      loop do
        b = spr.bitmap
        b.clear
        _draw_box_bg(b, box_w, box_h)
        pbSetSmallFont(b)
        
        # Wrapped prompt
        py = pad
        prompt.split("\n").each do |p_line|
          words = p_line.split(" ")
          curr = ""
          words.each do |w|
            t = curr.empty? ? w : "#{curr} #{w}"
            if b.text_size(t).width > box_w - pad * 2
              pbDrawShadowText(b, pad, py, box_w - pad * 2, line_h, curr, WHITE, SHADOW)
              py += line_h
              curr = w
            else
              curr = t
            end
          end
          pbDrawShadowText(b, pad, py, box_w - pad * 2, line_h, curr, WHITE, SHADOW)
          py += line_h
        end

        iy = py + 4
        input_w = box_w - pad * 2
        input_h = line_h * max_lines + 8
        b.fill_rect(pad, iy, input_w, input_h, INPUT_BG)
        _draw_rect_border(b, pad, iy, input_w, input_h, INPUT_BORDER)

        # Better wrapping with coordinate mapping
        display_lines = [] # Array of {text: "", start: 0, end: 0}
        current_line = { text: "", start: 0 }
        
        i = 0
        text.each_char do |ch|
          if ch == "\n"
            current_line[:end] = i
            display_lines << current_line
            current_line = { text: "", start: i + 1 }
          else
            test = current_line[:text] + ch
            if b.text_size(test).width > input_w - 24 # leave space for scrollbar
              current_line[:end] = i
              display_lines << current_line
              current_line = { text: ch, start: i }
            else
              current_line[:text] = test
            end
          end
          i += 1
        end
        current_line[:end] = i
        display_lines << current_line

        # Auto-scroll if typing or moving cursor
        max_scroll = [display_lines.length - max_lines, 0].max
        cursor_line_idx = display_lines.find_index { |l| cursor_pos >= l[:start] && cursor_pos <= l[:end] } || 0
        if should_autoscroll && !dragging_scroll
          if cursor_line_idx < scroll
            scroll = cursor_line_idx
          elsif cursor_line_idx >= scroll + max_lines
            scroll = cursor_line_idx - max_lines + 1
          end
          should_autoscroll = false
        end
        scroll = scroll.clamp(0, max_scroll)

        # Drawing Text
        display_lines.each_with_index do |line, idx|
          next if idx < scroll
          break if idx >= scroll + max_lines
          ly = iy + 4 + (idx - scroll) * line_h
          pbDrawShadowText(b, pad + 6, ly, input_w - 24, line_h, line[:text], WHITE, SHADOW)
          
          # Draw Cursor
          if (cursor_frame / 20) % 2 == 0 && idx == cursor_line_idx
            # Relative pos in line
            rel_idx = cursor_pos - line[:start]
            cursor_x = pad + 6 + b.text_size(line[:text][0...rel_idx]).width
            b.fill_rect(cursor_x, ly + 2, 2, line_h - 4, WHITE)
          end
        end

        # Scrollbar
        if display_lines.length > max_lines
          sb_x = pad + input_w - 14
          sb_y = iy + 4
          sb_h = input_h - 8
          b.fill_rect(sb_x, sb_y, 10, sb_h, Color.new(0, 0, 0, 60))
          
          handle_h = [ (sb_h.to_f * max_lines / display_lines.length).to_i, 16].max
          handle_y = sb_y + (sb_h - handle_h) * scroll.to_f / max_scroll
          b.fill_rect(sb_x, handle_y, 10, handle_h, GRAY)
        end

        hy = iy + input_h + 8
        pbDrawShadowText(b, 0, hy, box_w, line_h, "Shift+Enter: newline  |  Enter: confirm", DIM, SHADOW, 2)

        Graphics.update
        Input.update
        cursor_frame += 1
        mx = (Input.mouse_x rescue -1) - box_x
        my = (Input.mouse_y rescue -1) - box_y
        clicked = (Input.trigger?(Input::MOUSELEFT) rescue false)
        pressing = (Input.press?(Input::MOUSELEFT) rescue false)

        # Scroll wheel
        mw = (Input.mouse_wheel rescue 0)
        if mw != 0
          scroll = [[scroll - (mw > 0 ? 1 : -1), 0].max, max_scroll].min
        end

        # Scrollbar dragging
        if display_lines.length > max_lines
          sb_x = pad + input_w - 14
          sb_y = iy + 4
          sb_rh = input_h - 8
          # Wider hit area for dragging
          if clicked && mx >= sb_x - 4 && mx < sb_x + 14 && my >= sb_y && my < sb_y + sb_rh
            dragging_scroll = true
          end
          if dragging_scroll
            if pressing
              ratio = (my - sb_y).to_f / sb_rh
              scroll = (display_lines.length * ratio - max_lines / 2).to_i
              scroll = scroll.clamp(0, max_scroll)
            else
              dragging_scroll = false
            end
          end
        end

        # Mouse click to move cursor
        if clicked && !dragging_scroll && mx >= pad && mx < pad + input_w - 15 && my >= iy && my < iy + input_h
          click_line_idx = scroll + (my - iy - 4) / line_h
          click_line_idx = click_line_idx.clamp(0, display_lines.length - 1)
          line = display_lines[click_line_idx]
          rel_x = mx - pad - 6
          
          # Find nearest character
          best_pos = line[:start]
          min_diff = (rel_x).abs
          (1..line[:text].length).each do |len|
            width = b.text_size(line[:text][0, len]).width
            diff = (rel_x - width).abs
            if diff < min_diff
              min_diff = diff
              best_pos = line[:start] + len
            end
          end
          cursor_pos = best_pos
          cursor_frame = 0
        end

        # Keyboard Navigation
        if _key_repeat?(0x25) # LEFT
          cursor_pos = [cursor_pos - 1, 0].max
          should_autoscroll = true
          cursor_frame = 0
        elsif _key_repeat?(0x27) # RIGHT
          cursor_pos = [cursor_pos + 1, text.length].min
          should_autoscroll = true
          cursor_frame = 0
        elsif _key_repeat?(0x26) # UP
          if cursor_line_idx > 0
            # rel_x of current cursor pos
            current_line = display_lines[cursor_line_idx]
            rel_idx = cursor_pos - current_line[:start]
            rel_x = b.text_size(current_line[:text][0...rel_idx]).width
            
            target_line = display_lines[cursor_line_idx - 1]
            # Find nearest pos in previous line
            best_pos = target_line[:start]
            min_diff = (rel_x).abs
            (1..target_line[:text].length).each do |len|
              width = b.text_size(target_line[:text][0, len]).width
              diff = (rel_x - width).abs
              if diff < min_diff
                min_diff = diff
                best_pos = target_line[:start] + len
              end
            end
            cursor_pos = best_pos
          else
            cursor_pos = 0
          end
          should_autoscroll = true
          cursor_frame = 0
        elsif _key_repeat?(0x28) # DOWN
          if cursor_line_idx < display_lines.length - 1
            current_line = display_lines[cursor_line_idx]
            rel_idx = cursor_pos - current_line[:start]
            rel_x = b.text_size(current_line[:text][0...rel_idx]).width
            
            target_line = display_lines[cursor_line_idx + 1]
            best_pos = target_line[:start]
            min_diff = (rel_x).abs
            (1..target_line[:text].length).each do |len|
              width = b.text_size(target_line[:text][0, len]).width
              diff = (rel_x - width).abs
              if diff < min_diff
                min_diff = diff
                best_pos = target_line[:start] + len
              end
            end
            cursor_pos = best_pos
          else
            cursor_pos = text.length
          end
          should_autoscroll = true
          cursor_frame = 0
        elsif _key_repeat?(0x24) # HOME
          cursor_pos = display_lines[cursor_line_idx][:start]
          should_autoscroll = true
          cursor_frame = 0
        elsif _key_trigger?(0x23) # END
          cursor_pos = display_lines[cursor_line_idx][:end]
          should_autoscroll = true
          cursor_frame = 0
        elsif _key_trigger?(0x21) # PAGE UP
          cursor_pos = display_lines[[cursor_line_idx - max_lines, 0].max][:start]
          should_autoscroll = true
          cursor_frame = 0
        elsif _key_trigger?(0x22) # PAGE DOWN
          cursor_pos = display_lines[[cursor_line_idx + max_lines, display_lines.length - 1].max][:end]
          should_autoscroll = true
          cursor_frame = 0
        end

        if _key_trigger?(0x0D)
          if _key_pressed?(0x10) # Shift
            if text.length < max_len
               text.insert(cursor_pos, "\n")
               cursor_pos += 1
               should_autoscroll = true
               cursor_frame = 0
            end
          else
            break
          end
        end

        if Input.trigger?(Input::B)
          text = nil
          break
        end

        if _key_repeat?(0x08) && cursor_pos > 0 # Backspace
          text.slice!(cursor_pos - 1)
          cursor_pos -= 1
          should_autoscroll = true
          cursor_frame = 0
        end

        if _key_trigger?(0x2E) && cursor_pos < text.length # Delete
          text.slice!(cursor_pos)
          should_autoscroll = true
          cursor_frame = 0
        end

        # Character input
        (0x41..0x5A).each do |vk|
          if _key_trigger?(vk)
            shift = _key_pressed?(0x10)
            ch = (vk - 0x41 + 97).chr
            ch = ch.upcase if shift
            if text.length < max_len
              text.insert(cursor_pos, ch)
              cursor_pos += 1
              should_autoscroll = true
          should_autoscroll = true
          cursor_frame = 0
            end
          end
        end
        (0x30..0x39).each do |vk|
          if _key_trigger?(vk)
            shift = _key_pressed?(0x10)
            if shift
              specials = {0x30=>")", 0x31=>"!", 0x32=>"@", 0x33=>"#", 0x34=>"$", 0x35=>"%", 0x36=>"^", 0x37=>"&", 0x38=>"*", 0x39=>"("}
              text.insert(cursor_pos, specials[vk]) if text.length < max_len
            else
              text.insert(cursor_pos, (vk - 0x30).to_s) if text.length < max_len
            end
            cursor_pos += 1
            should_autoscroll = true
          should_autoscroll = true
          cursor_frame = 0
          end
        end
        [0x20, 0xBE, 0xBC, 0xBD, 0xBB, 0xBA, 0xBF, 0xDB, 0xDD, 0xDE].each do |vk|
          if _key_trigger?(vk)
            shift = _key_pressed?(0x10)
            ch = case vk
            when 0x20 then " "
            when 0xBE then shift ? ">" : "."
            when 0xBC then shift ? "<" : ","
            when 0xBD then shift ? "_" : "-"
            when 0xBB then shift ? "+" : "="
            when 0xBA then shift ? ":" : ";"
            when 0xBF then shift ? "?" : "/"
            when 0xDB then shift ? "{" : "["
            when 0xDD then shift ? "}" : "]"
            when 0xDE then shift ? "\"" : "'"
            end
            if ch && text.length < max_len
              text.insert(cursor_pos, ch)
              cursor_pos += 1
              cursor_frame = 0
            end
          end
        end
      end
      spr.bitmap.dispose
      spr.dispose
      text
    end

    #==========================================================================
    # Create Mod
    #==========================================================================
    def create_mod
      # 1. Mod name
      name = ui_text_input("Mod Name:", 30)
      return if name.nil? || name.strip.empty?
      name = name.strip

      # 2. Auto-generate ID
      id = name.downcase.gsub(/[^a-z0-9]/, '_').gsub(/_+/, '_').gsub(/^_|_$/, '')
      if id.empty?
        ui_message("Could not generate a valid ID from that name.")
        return
      end

      # Check if ID already exists
      target = File.join(ModManager::MODDEV_DIR, id)
      if File.directory?(target)
        ui_message("A mod with ID '#{id}' already exists in ModDev/.")
        return
      end

      # 3. GitHub username
      author = ui_text_input("Author Name:", 30)
      return if author.nil? || author.strip.empty?
      author = author.strip

      # 4. Description
      description = ui_multiline_input("Mod Description:", 5, 500)
      description = "" if description.nil?

      # 5. Version
      version = ui_text_input("Version:", 15, "1.0.0")
      version = "1.0.0" if version.nil? || version.strip.empty?
      version = version.strip

      # 6. Tags (multi-select)
      tags = ui_select_tags

      # 7. Dependencies (pick from known mods)
      dependencies = []
      loop do
        break if ui_message("Add a dependency?", ["Yes", "No"]) != 0
        existing_ids = dependencies.map { |d| d["id"] }
        dep_id = _pick_mod("Select dependency:", id, existing_ids)
        break unless dep_id
        dep_ver = ui_text_input("Minimum version:", 15, "1.0.0")
        dep_ver = "1.0.0" if dep_ver.nil? || dep_ver.strip.empty?
        dependencies << { "id" => dep_id, "min_version" => dep_ver.strip }
      end

      # 8. Incompatibilities (pick from known mods)
      incompatible = []
      loop do
        break if ui_message("Add an incompatible mod?", ["Yes", "No"]) != 0
        inc_id = _pick_mod("Select incompatible mod:", id, incompatible)
        break unless inc_id
        incompatible << inc_id
      end

      # 9. Generate output
      begin
        Dir.mkdir(ModManager::MODDEV_DIR) unless File.directory?(ModManager::MODDEV_DIR)
        Dir.mkdir(target) unless File.directory?(target)

        mod_json = {
          "name" => name,
          "id" => id,
          "version" => version,
          "author" => author,
          "description" => description,
          "tags" => tags,
          "dependencies" => dependencies,
          "incompatible" => incompatible,
          "settings" => [],
          "scripts" => ["main.rb"],
          "icon" => "icon.png"
        }

        File.open(File.join(target, "mod.json"), "w") do |f|
          f.write(ModManager::JSON.dump(mod_json))
        end

        File.open(File.join(target, "main.rb"), "w") do |f|
          f.write(<<~RUBY)
            #==============================================================================
            # #{name}
            # by #{author} — v#{version}
            #
            # #{description}
            #==============================================================================

            # Your mod code here.
            # Access your mod's settings via:
            #   $mod_manager_settings["#{id}"]
            #
            # Example:
            #   if $mod_manager_settings["#{id}"]["my_setting"]
            #     # do something
            #   end
          RUBY
        end

        ui_message("Mod created!\n\nFolder: ModDev/#{id}/\n\nEdit main.rb, then upload the folder\nto GitHub (KIF-Mods/mods).")
      rescue => e
        ui_message("Error creating mod: #{e.message}")
      end
    end

    #==========================================================================
    # Update Mod
    #==========================================================================
    #==========================================================================
    # Delete Mod
    #==========================================================================
    def delete_mod
      unless File.directory?(ModManager::MODDEV_DIR)
        ui_message("No ModDev/ folder found.")
        return
      end

      mod_dirs = Dir["#{ModManager::MODDEV_DIR}/*/mod.json"]
      if mod_dirs.empty?
        ui_message("No mods found in ModDev/.")
        return
      end

      mods = []
      mod_dirs.each do |json_path|
        begin
          raw = File.read(json_path)
          parsed = ModManager::JSON.parse(raw)
          next unless parsed.is_a?(Hash) && parsed["id"]
          mods << { "path" => File.dirname(json_path), "json" => parsed }
        rescue
          next
        end
      end

      if mods.empty?
        ui_message("No valid mods found in ModDev/.")
        return
      end

      names = mods.map { |m| m["json"]["name"] || m["json"]["id"] }
      names << "Cancel"
      choice = ui_message("Select mod to delete:", names)
      return if choice < 0 || choice >= mods.length

      mod = mods[choice]
      mod_name = mod["json"]["name"] || mod["json"]["id"]
      mod_path = mod["path"]

      confirm = ui_message("Delete '#{mod_name}'?\nThis will remove the entire folder\nand cannot be undone.", ["Yes, delete it", "Cancel"])
      return if confirm != 0

      begin
        # Delete all files in the mod folder, then the folder itself
        Dir["#{mod_path}/*"].each do |file|
          File.delete(file) rescue nil
        end
        Dir.rmdir(mod_path) rescue nil

        ui_message("'#{mod_name}' has been deleted.")
      rescue => e
        ui_message("Error deleting mod: #{e.message}")
      end
    end

    #==========================================================================
    # Upload Mod (launches publish script)
    #==========================================================================
    def upload_mod
      # Detect OS and find the right script
      moddev = ModManager::MODDEV_DIR
      bat_path = File.join(moddev, "publish_mod.bat")
      sh_path = File.join(moddev, "publish_mod.sh")

      if RUBY_PLATFORM =~ /mswin|mingw|win/i || ENV['OS'] =~ /Windows/i
        # Windows
        if File.exist?(bat_path)
          ui_message("Opening the Mod Publisher...\n\nThe publisher will open in a new window.\nFollow the prompts there.")
          system("start \"\" \"#{bat_path.gsub('/', '\\\\')}\"")
        else
          ui_message("publish_mod.bat not found in ModDev/.\n\nPlease make sure the file exists.")
        end
      else
        # Mac / Linux
        if File.exist?(sh_path)
          ui_message("Opening the Mod Publisher...\n\nThe publisher will open in a new terminal.\nFollow the prompts there.")
          # Try common terminal emulators
          if system("which gnome-terminal > /dev/null 2>&1")
            system("gnome-terminal -- bash \"#{sh_path}\" &")
          elsif system("which xterm > /dev/null 2>&1")
            system("xterm -e bash \"#{sh_path}\" &")
          elsif RUBY_PLATFORM =~ /darwin/i
            system("open -a Terminal \"#{sh_path}\"")
          else
            system("bash \"#{sh_path}\" &")
          end
        else
          ui_message("publish_mod.sh not found in ModDev/.\n\nPlease make sure the file exists.")
        end
      end
    end

    #==========================================================================
    # Delete from Repo (launches delete script)
    #==========================================================================
    def delete_from_repo
      moddev = ModManager::MODDEV_DIR
      bat_path = File.join(moddev, "delete_mod.bat")
      sh_path = File.join(moddev, "delete_mod.sh")

      if RUBY_PLATFORM =~ /mswin|mingw|win/i || ENV['OS'] =~ /Windows/i
        if File.exist?(bat_path)
          ui_message("Opening the Mod Deleter...\n\nA terminal window will open.\nFollow the prompts there.")
          system("start \"\" \"#{bat_path.gsub('/', '\\\\')}\"")
        else
          ui_message("delete_mod.bat not found in ModDev/.\n\nPlease make sure the file exists.")
        end
      else
        if File.exist?(sh_path)
          ui_message("Opening the Mod Deleter...\n\nA terminal will open.\nFollow the prompts there.")
          if system("which gnome-terminal > /dev/null 2>&1")
            system("gnome-terminal -- bash \"#{sh_path}\" &")
          elsif system("which xterm > /dev/null 2>&1")
            system("xterm -e bash \"#{sh_path}\" &")
          elsif RUBY_PLATFORM =~ /darwin/i
            system("open -a Terminal \"#{sh_path}\"")
          else
            system("bash \"#{sh_path}\" &")
          end
        else
          ui_message("delete_mod.sh not found in ModDev/.\n\nPlease make sure the file exists.")
        end
      end
    end

    #==========================================================================
    # Upload Modpack (launches publish script — requires verified team access)
    #==========================================================================
    def upload_modpack
      moddev = ModManager::MODDEV_DIR

      # Check that there's at least one modpack to upload
      pack_files = Dir["#{moddev}/*/modpack.json"] rescue []
      if pack_files.empty?
        ui_message("No modpacks found in ModDev/.\n\nCreate one first with Create > Modpack.")
        return
      end

      ui_message("Uploading a modpack requires write access\nto the KIF-Mods GitHub repository.\n\nYou must be on the verified team\nwith write permissions.")

      bat_path = File.join(moddev, "publish_modpack.bat")
      sh_path = File.join(moddev, "publish_modpack.sh")

      if RUBY_PLATFORM =~ /mswin|mingw|win/i || ENV['OS'] =~ /Windows/i
        if File.exist?(bat_path)
          ui_message("Opening the Modpack Publisher...\n\nThe publisher will open in a new window.\nFollow the prompts there.")
          system("start \"\" \"#{bat_path.gsub('/', '\\\\')}\"")
        else
          ui_message("publish_modpack.bat not found in ModDev/.\n\nPlease make sure the file exists.")
        end
      else
        if File.exist?(sh_path)
          ui_message("Opening the Modpack Publisher...\n\nThe publisher will open in a new terminal.\nFollow the prompts there.")
          if system("which gnome-terminal > /dev/null 2>&1")
            system("gnome-terminal -- bash \"#{sh_path}\" &")
          elsif system("which xterm > /dev/null 2>&1")
            system("xterm -e bash \"#{sh_path}\" &")
          elsif RUBY_PLATFORM =~ /darwin/i
            system("open -a Terminal \"#{sh_path}\"")
          else
            system("bash \"#{sh_path}\" &")
          end
        else
          ui_message("publish_modpack.sh not found in ModDev/.\n\nPlease make sure the file exists.")
        end
      end
    end

    #==========================================================================
    # Delete Modpack (local — from ModDev/)
    #==========================================================================
    def delete_modpack
      unless File.directory?(ModManager::MODDEV_DIR)
        ui_message("No ModDev/ folder found.")
        return
      end

      pack_files = Dir["#{ModManager::MODDEV_DIR}/*/modpack.json"]
      if pack_files.empty?
        ui_message("No modpacks found in ModDev/.")
        return
      end

      packs = []
      pack_files.each do |json_path|
        begin
          raw = File.read(json_path)
          parsed = ModManager::JSON.parse(raw)
          next unless parsed.is_a?(Hash) && parsed["id"]
          packs << { "path" => File.dirname(json_path), "json" => parsed }
        rescue
          next
        end
      end

      if packs.empty?
        ui_message("No valid modpacks found in ModDev/.")
        return
      end

      names = packs.map { |p| p["json"]["name"] || p["json"]["id"] }
      names << "Cancel"
      choice = ui_message("Select modpack to delete:", names)
      return if choice < 0 || choice >= packs.length

      pack = packs[choice]
      pack_name = pack["json"]["name"] || pack["json"]["id"]
      pack_path = pack["path"]

      confirm = ui_message("Delete '#{pack_name}'?\nThis will remove the entire folder\nand cannot be undone.", ["Yes, delete it", "Cancel"])
      return if confirm != 0

      begin
        Dir["#{pack_path}/*"].each do |file|
          File.delete(file) rescue nil
        end
        Dir.rmdir(pack_path) rescue nil
        ui_message("'#{pack_name}' has been deleted.")
      rescue => e
        ui_message("Error deleting modpack: #{e.message}")
      end
    end

    #==========================================================================
    # Delete Modpack from Repo (launches delete script — requires team access)
    #==========================================================================
    def delete_modpack_from_repo
      ui_message("Deleting a modpack from the repo requires\nwrite access to the KIF-Mods GitHub\nrepository.\n\nYou must be on the verified team\nwith write permissions.")

      moddev = ModManager::MODDEV_DIR
      bat_path = File.join(moddev, "delete_modpack.bat")
      sh_path = File.join(moddev, "delete_modpack.sh")

      if RUBY_PLATFORM =~ /mswin|mingw|win/i || ENV['OS'] =~ /Windows/i
        if File.exist?(bat_path)
          ui_message("Opening the Modpack Deleter...\n\nA terminal window will open.\nFollow the prompts there.")
          system("start \"\" \"#{bat_path.gsub('/', '\\\\')}\"")
        else
          ui_message("delete_modpack.bat not found in ModDev/.\n\nPlease make sure the file exists.")
        end
      else
        if File.exist?(sh_path)
          ui_message("Opening the Modpack Deleter...\n\nA terminal will open.\nFollow the prompts there.")
          if system("which gnome-terminal > /dev/null 2>&1")
            system("gnome-terminal -- bash \"#{sh_path}\" &")
          elsif system("which xterm > /dev/null 2>&1")
            system("xterm -e bash \"#{sh_path}\" &")
          elsif RUBY_PLATFORM =~ /darwin/i
            system("open -a Terminal \"#{sh_path}\"")
          else
            system("bash \"#{sh_path}\" &")
          end
        else
          ui_message("delete_modpack.sh not found in ModDev/.\n\nPlease make sure the file exists.")
        end
      end
    end

    #==========================================================================
    # Update Mod
    #==========================================================================
    def update_mod
      unless File.directory?(ModManager::MODDEV_DIR)
        ui_message("No ModDev/ folder found.")
        return
      end

      mod_dirs = Dir["#{ModManager::MODDEV_DIR}/*/mod.json"]
      if mod_dirs.empty?
        ui_message("No mods found in ModDev/.")
        return
      end

      mods = []
      mod_dirs.each do |json_path|
        begin
          raw = File.read(json_path)
          parsed = ModManager::JSON.parse(raw)
          next unless parsed.is_a?(Hash) && parsed["id"]
          mods << { "path" => File.dirname(json_path), "json" => parsed }
        rescue
          next
        end
      end

      if mods.empty?
        ui_message("No valid mods found in ModDev/.")
        return
      end

      names = mods.map { |m| m["json"]["name"] || m["json"]["id"] }
      names << "Cancel"
      choice = ui_message("Select mod to update:", names)
      return if choice < 0 || choice >= mods.length

      mod = mods[choice]
      json = mod["json"]
      path = mod["path"]

      loop do
        cmds = [
          "Name: #{json["name"]}",
          "Description",
          "Version: #{json["version"]}",
          "Author: #{json["author"]}",
          "Tags: #{(json["tags"] || []).join(", ")}",
          "Dependencies (#{(json["dependencies"] || []).length})",
          "Incompatibilities (#{(json["incompatible"] || []).length})",
          "Save & Exit",
          "Cancel"
        ]
        choice = ui_message("Edit #{json["name"]}:", cmds)

        case choice
        when 0
          new_name = ui_text_input("Mod Name:", 30, json["name"].to_s)
          json["name"] = new_name.strip if new_name && !new_name.strip.empty?
        when 1
          desc = json["description"]
          desc = desc.join("\n") if desc.is_a?(Array)
          new_desc = ui_multiline_input("Description:", 5, 500, desc.to_s)
          if new_desc
            json["description"] = new_desc.include?("\n") ? new_desc.split("\n") : new_desc
          end
        when 2
          new_ver = ui_text_input("Version:", 15, json["version"].to_s)
          json["version"] = new_ver.strip if new_ver && !new_ver.strip.empty?
        when 3
          new_author = ui_text_input("Author Name:", 30, json["author"].to_s)
          json["author"] = new_author.strip if new_author && !new_author.strip.empty?
        when 4
          json["tags"] = ui_select_tags(json["tags"] || [])
        when 5
          ui_edit_dependencies(json)
        when 6
          ui_edit_incompatibilities(json)
        when 7
          begin
            File.open(File.join(path, "mod.json"), "w") { |f| f.write(ModManager::JSON.dump(json)) }
            ui_message("Mod updated!\nUpload the folder to GitHub to publish.")
          rescue => e
            ui_message("Error saving: #{e.message}")
          end
          break
        else
          break
        end
      end
    end

    #==========================================================================
    # Create Modpack
    #==========================================================================
    def create_modpack
      # 1. Modpack name
      name = ui_text_input("Modpack Name:", 30)
      return if name.nil? || name.strip.empty?
      name = name.strip

      # 2. Auto-generate ID
      id = name.downcase.gsub(/[^a-z0-9]/, '_').gsub(/_+/, '_').gsub(/^_|_$/, '')
      if id.empty?
        ui_message("Could not generate a valid ID from that name.")
        return
      end

      target = File.join(ModManager::MODDEV_DIR, id)
      if File.directory?(target)
        ui_message("A modpack with ID '#{id}' already exists in ModDev/.")
        return
      end

      # 3. Author
      author = ui_text_input("Author Name:", 30)
      return if author.nil? || author.strip.empty?
      author = author.strip

      # 4. Description
      description = ui_multiline_input("Modpack Description:", 5, 500)
      description = "" if description.nil?

      # 5. Version
      version = ui_text_input("Version:", 15, "1.0.0")
      version = "1.0.0" if version.nil? || version.strip.empty?
      version = version.strip

      # 6. Tags
      tags = ui_select_tags

      # 7. Select mods for the modpack
      mods = []
      loop do
        if mods.empty?
          break if ui_message("Add a mod to this modpack?", ["Yes", "Cancel"]) != 0
        else
          break if ui_message("#{mods.length} mod(s) added.\nAdd another?", ["Yes", "Done"]) != 0
        end
        existing_ids = mods.map { |m| m["id"] }
        mod_id = _pick_mod("Select mod for modpack:", nil, existing_ids)
        break unless mod_id
        # Optionally set minimum version
        set_ver = ui_message("Set minimum version for '#{mod_id}'?", ["Yes", "No"])
        mod_entry = { "id" => mod_id }
        if set_ver == 0
          min_ver = ui_text_input("Minimum version:", 15, "1.0.0")
          mod_entry["version"] = min_ver.strip if min_ver && !min_ver.strip.empty?
        end
        mods << mod_entry
      end

      if mods.empty?
        ui_message("No mods selected. Modpack not created.")
        return
      end

      # 8. Generate output
      begin
        Dir.mkdir(ModManager::MODDEV_DIR) unless File.directory?(ModManager::MODDEV_DIR)
        Dir.mkdir(target) unless File.directory?(target)

        modpack_json = {
          "name" => name,
          "id" => id,
          "version" => version,
          "author" => author,
          "description" => description,
          "tags" => tags,
          "mods" => mods
        }

        File.open(File.join(target, "modpack.json"), "w") do |f|
          f.write(ModManager::JSON.dump(modpack_json))
        end

        ui_message("Modpack created!\n\nFolder: ModDev/#{id}/\n\nUpload the folder to GitHub\n(KIF-Mods/mods/modpacks/#{id}/).")
      rescue => e
        ui_message("Error creating modpack: #{e.message}")
      end
    end

    #==========================================================================
    # Update Modpack
    #==========================================================================
    def update_modpack
      unless File.directory?(ModManager::MODDEV_DIR)
        ui_message("No ModDev/ folder found.")
        return
      end

      pack_files = Dir["#{ModManager::MODDEV_DIR}/*/modpack.json"]
      if pack_files.empty?
        ui_message("No modpacks found in ModDev/.\n\nCreate one first with 'Create Modpack'.")
        return
      end

      packs = []
      pack_files.each do |json_path|
        begin
          raw = File.read(json_path)
          parsed = ModManager::JSON.parse(raw)
          next unless parsed.is_a?(Hash) && parsed["id"]
          packs << { "path" => File.dirname(json_path), "json" => parsed }
        rescue
          next
        end
      end

      if packs.empty?
        ui_message("No valid modpacks found in ModDev/.")
        return
      end

      names = packs.map { |p| p["json"]["name"] || p["json"]["id"] }
      names << "Cancel"
      choice = ui_message("Select modpack to update:", names)
      return if choice < 0 || choice >= packs.length

      pack = packs[choice]
      json = pack["json"]
      path = pack["path"]

      loop do
        mod_count = (json["mods"] || []).length
        cmds = [
          "Name: #{json["name"]}",
          "Description",
          "Version: #{json["version"]}",
          "Author: #{json["author"]}",
          "Tags: #{(json["tags"] || []).join(", ")}",
          "Mods (#{mod_count})",
          "Save & Exit",
          "Cancel"
        ]
        choice = ui_message("Edit #{json["name"]}:", cmds)

        case choice
        when 0
          new_name = ui_text_input("Modpack Name:", 30, json["name"].to_s)
          json["name"] = new_name.strip if new_name && !new_name.strip.empty?
        when 1
          new_desc = ui_multiline_input("Description:", 5, 500, json["description"].to_s)
          if new_desc
            json["description"] = new_desc.include?("\n") ? new_desc.split("\n") : new_desc
          end
        when 2
          new_ver = ui_text_input("Version:", 15, json["version"].to_s)
          json["version"] = new_ver.strip if new_ver && !new_ver.strip.empty?
        when 3
          new_author = ui_text_input("Author Name:", 30, json["author"].to_s)
          json["author"] = new_author.strip if new_author && !new_author.strip.empty?
        when 4
          json["tags"] = ui_select_tags(json["tags"] || [])
        when 5
          ui_edit_modpack_mods(json)
        when 6
          begin
            File.open(File.join(path, "modpack.json"), "w") { |f| f.write(ModManager::JSON.dump(json)) }
            ui_message("Modpack updated!\nUpload the folder to GitHub to publish.")
          rescue => e
            ui_message("Error saving: #{e.message}")
          end
          break
        else
          break
        end
      end
    end

    #==========================================================================
    # Edit Modpack Mods List
    #==========================================================================
    def ui_edit_modpack_mods(json)
      json["mods"] ||= []
      loop do
        mods = json["mods"]
        display = mods.map do |m|
          ver_str = m["version"] ? " >= #{m["version"]}" : ""
          "#{m["id"]}#{ver_str}"
        end
        display << "Add mod"
        display << "Done"
        choice = ui_message("Modpack mods:", display)

        if choice >= 0 && choice < mods.length
          # Remove or edit existing mod entry
          mod_entry = mods[choice]
          action = ui_message("#{mod_entry["id"]}:", ["Remove", "Change version", "Cancel"])
          if action == 0
            mods.delete_at(choice)
          elsif action == 1
            new_ver = ui_text_input("Minimum version (blank for any):", 15, mod_entry["version"].to_s)
            if new_ver && !new_ver.strip.empty?
              mod_entry["version"] = new_ver.strip
            else
              mod_entry.delete("version")
            end
          end
        elsif choice == mods.length
          existing_ids = mods.map { |m| m["id"] }
          mod_id = _pick_mod("Select mod to add:", nil, existing_ids)
          if mod_id
            new_entry = { "id" => mod_id }
            set_ver = ui_message("Set minimum version for '#{mod_id}'?", ["Yes", "No"])
            if set_ver == 0
              min_ver = ui_text_input("Minimum version:", 15, "1.0.0")
              new_entry["version"] = min_ver.strip if min_ver && !min_ver.strip.empty?
            end
            mods << new_entry
          end
        else
          break
        end
      end
    end

    #==========================================================================
    # Tag Selection (custom multi-select in our viewport)
    #==========================================================================
    def ui_select_tags(existing = [])
      selected = existing.dup
      loop do
        display = ModManager::VALID_TAGS.map do |tag|
          selected.include?(tag) ? "[X] #{tag}" : "[ ] #{tag}"
        end
        display << "Done"
        choice = ui_message("Select tags (toggle on/off):", display)

        if choice >= 0 && choice < ModManager::VALID_TAGS.length
          tag = ModManager::VALID_TAGS[choice]
          if selected.include?(tag)
            selected.delete(tag)
          else
            selected << tag
          end
        else
          break
        end
      end
      selected
    end

    # Gather all known mods (installed + in-dev + remote from GitHub cache)
    # Returns array of { "id" => ..., "name" => ..., "source" => ... }
    def _all_known_mods(exclude_id = nil)
      known = {}  # id => { name:, source: }

      # 1. Installed mods (from Mods/)
      ModManager.registry.each do |id, info|
        next if id == exclude_id
        known[id] = { "name" => info.name, "source" => "installed" }
      end

      # 2. In-dev mods (from ModDev/)
      if File.directory?(ModManager::MODDEV_DIR)
        Dir["#{ModManager::MODDEV_DIR}/*/mod.json"].each do |path|
          begin
            raw = File.read(path)
            parsed = ModManager::JSON.parse(raw)
            next unless parsed.is_a?(Hash) && parsed["id"]
            mid = parsed["id"]
            next if mid == exclude_id
            known[mid] ||= { "name" => parsed["name"] || mid, "source" => "dev" }
          rescue
            next
          end
        end
      end

      # 3. Remote mods from GitHub cache (if browser was used this session)
      if defined?(ModManager::GitHub)
        remote_list = ModManager::GitHub.cached_mod_list rescue nil
        remote_json = ModManager::GitHub.cached_mod_json rescue {}
        if remote_list.is_a?(Array)
          remote_list.each do |folder|
            next if folder == exclude_id || known[folder]
            rj = remote_json[folder] if remote_json
            rname = rj && rj["name"] ? rj["name"] : folder
            known[folder] = { "name" => rname, "source" => "remote" }
          end
        end
      end

      known.map { |id, info| { "id" => id, "name" => info["name"], "source" => info["source"] } }
            .sort_by { |m| m["name"].downcase }
    end

    # Pick a mod from the known mods list. Returns mod ID or nil.
    def _pick_mod(prompt, exclude_id = nil, already_selected = [])
      # Try to fetch remote list if cache is empty and browser is enabled
      if defined?(ModManager::GitHub)
        cached = ModManager::GitHub.cached_mod_list rescue nil
        if cached.nil?
          marker = File.join(ModManager::MOD_DIR, ".mod_browser_enabled")
          if File.exist?(marker)
            ui_message("Fetching mod list from GitHub...")
            ModManager::GitHub.fetch_mod_list rescue nil
          end
        end
      end

      mods = _all_known_mods(exclude_id)
      # Filter out already selected ones
      mods = mods.reject { |m| already_selected.include?(m["id"]) }

      if mods.empty?
        ui_message("No other mods found.\n\nInstall mods or create them in ModDev/\nfor them to appear here.")
        return nil
      end

      # Show source tag next to each mod
      source_tag = { "installed" => "[local]", "dev" => "[dev]", "remote" => "[github]" }
      display = mods.map { |m| "#{m["name"]}  #{source_tag[m["source"]] || ""}" }
      display << "Type ID manually..."
      display << "Cancel"
      choice = ui_message(prompt, display)

      if choice >= 0 && choice < mods.length
        return mods[choice]["id"]
      elsif choice == mods.length
        # Manual input fallback
        typed = ui_text_input("Mod ID:", 30)
        return typed && !typed.strip.empty? ? typed.strip : nil
      end
      nil
    end

    def ui_edit_dependencies(json)
      json["dependencies"] ||= []
      loop do
        deps = json["dependencies"]
        display = deps.map { |d| "#{d["id"]} >= #{d["min_version"]}" }
        display << "Add"
        display << "Done"
        choice = ui_message("Dependencies:", display)

        if choice >= 0 && choice < deps.length
          if ui_message("Remove #{deps[choice]["id"]}?", ["Yes", "No"]) == 0
            deps.delete_at(choice)
          end
        elsif choice == deps.length
          existing_ids = deps.map { |d| d["id"] }
          dep_id = _pick_mod("Select dependency:", json["id"], existing_ids)
          if dep_id
            dep_ver = ui_text_input("Minimum version:", 15, "1.0.0")
            dep_ver = "1.0.0" if dep_ver.nil? || dep_ver.strip.empty?
            deps << { "id" => dep_id, "min_version" => dep_ver.strip }
          end
        else
          break
        end
      end
    end

    def ui_edit_incompatibilities(json)
      json["incompatible"] ||= []
      loop do
        incs = json["incompatible"]
        display = incs.dup
        display << "Add"
        display << "Done"
        choice = ui_message("Incompatible mods:", display)

        if choice >= 0 && choice < incs.length
          if ui_message("Remove #{incs[choice]}?", ["Yes", "No"]) == 0
            incs.delete_at(choice)
          end
        elsif choice == incs.length
          inc_id = _pick_mod("Select incompatible mod:", json["id"], incs)
          incs << inc_id if inc_id
        else
          break
        end
      end
    end

    #==========================================================================
    # Internal drawing helpers
    #==========================================================================
    def _draw_box_bg(b, w, h)
      # Rounded rect fill
      b.fill_rect(2, 0, w - 4, h, BOX_BG)
      b.fill_rect(0, 2, w, h - 4, BOX_BG)
      b.fill_rect(1, 1, w - 2, h - 2, BOX_BG)
      # Border
      _draw_rect_border(b, 0, 0, w, h, BOX_BORDER)
    end

    def _draw_rect_border(b, x, y, w, h, color)
      b.fill_rect(x + 2, y, w - 4, 1, color)
      b.fill_rect(x + 2, y + h - 1, w - 4, 1, color)
      b.fill_rect(x, y + 2, 1, h - 4, color)
      b.fill_rect(x + w - 1, y + 2, 1, h - 4, color)
    end

    def _redraw_choices(b, choices, selected, pad, ty, box_w, line_h)
      b.fill_rect(pad, ty - 2, box_w - pad * 2, choices.length * line_h + 4, BOX_BG)
      choices.each_with_index do |label, i|
        if i == selected
          b.fill_rect(pad, ty + i * line_h, box_w - pad * 2, line_h, SEL_BG)
          pbDrawShadowText(b, pad + 8, ty + i * line_h, box_w - pad * 2, line_h, "> #{label}", WHITE, SHADOW)
        else
          pbDrawShadowText(b, pad + 8, ty + i * line_h, box_w - pad * 2, line_h, label, GRAY, SHADOW)
        end
      end
    end

    def _run_choice_loop(spr, choices, selected, lines, pad, box_x, box_y, box_w, line_h)
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

          # Mouse hover
          mx = Input.mouse_x rescue nil
          my = Input.mouse_y rescue nil
          if mx && my
            choice_base_y = box_y + pad + lines.length * line_h + 4
            if mx >= box_x + pad && mx < box_x + box_w - pad
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
            _redraw_choices(spr.bitmap, choices, selected, pad,
                            pad + lines.length * line_h + 4, box_w, line_h)
          end

          if Input.trigger?(Input::C) || (Input.trigger?(Input::MOUSELEFT) rescue false)
            return selected
          end

          if Input.trigger?(Input::B) || (Input.trigger?(Input::MOUSERIGHT) rescue false)
            return choices.length - 1
          end
        else
          if Input.trigger?(Input::C) || Input.trigger?(Input::B) ||
             (Input.trigger?(Input::MOUSELEFT) rescue false)
            return 0
          end
        end
      end
    end

    #==========================================================================
    # Win32API key helpers
    #==========================================================================
    # Consume lingering key states so they don't bleed into the next input
    def _wait_key_release
      # Read GetAsyncKeyState for common confirm keys to clear the low bit
      _init_gas
      if @_gas
        [0x0D, 0x5A, 0x20].each { |vk| @_gas.call(vk) }  # Enter, Z, Space
      end
      # One frame to let Input.trigger? clear
      Graphics.update
      Input.update
    end

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

    def _key_trigger?(vk_code)
      _init_gas
      return false unless @_gas && _window_active?
      (@_gas.call(vk_code) & 0x01) != 0
    rescue
      false
    end

    def _key_pressed?(vk_code)
      _init_gas
      return false unless @_gas && _window_active?
      (@_gas.call(vk_code) & 0x8000) != 0
    rescue
      false
    end

    def _key_repeat?(vk_code)
      @_repeat_timers ||= {}
      if _key_pressed?(vk_code)
        @_repeat_timers[vk_code] ||= 0
        @_repeat_timers[vk_code] += 1
        t = @_repeat_timers[vk_code]
        return t == 1 || (t > 12 && t % 4 == 0)
      else
        @_repeat_timers[vk_code] = 0
        return false
      end
    end
  end
end
