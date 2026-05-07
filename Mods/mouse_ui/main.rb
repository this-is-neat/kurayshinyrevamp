module MouseUI
  module_function

  @queued_buttons = {}
  @mouse_reactivate_origin = nil

  def pointer_position
    return nil unless Input.respond_to?(:mouse_in_window)
    return nil unless Input.mouse_in_window
    return [Input.mouse_x, Input.mouse_y]
  rescue
    return nil
  end

  def queue_button(button)
    return if button.nil?
    @queued_buttons[button] = current_frame
  end

  def consume_button(button)
    return false if button.nil?
    frame = @queued_buttons[button]
    return false if !frame
    return frame == current_frame
  end

  def current_frame
    return Graphics.frame_count if defined?(Graphics) && Graphics.respond_to?(:frame_count)
    return 0
  rescue
    return 0
  end

  def clear_old_buttons
    now = current_frame
    @queued_buttons.delete_if { |_button, frame| frame != now }
  end

  def require_mouse_reactivation
    pos = pointer_position
    @mouse_reactivate_origin = pos ? [pos[0], pos[1]] : :unknown
  rescue
    @mouse_reactivate_origin = :unknown
  end

  def mouse_hover_active?
    return true if @mouse_reactivate_origin.nil?
    pos = pointer_position
    return false if !pos
    if @mouse_reactivate_origin == :unknown
      @mouse_reactivate_origin = nil
      return true
    end
    moved = (pos[0] != @mouse_reactivate_origin[0] || pos[1] != @mouse_reactivate_origin[1])
    @mouse_reactivate_origin = nil if moved
    return moved
  rescue
    return false
  end

  def queue_confirm
    queue_button(Input::USE) if defined?(Input::USE)
    queue_button(Input::C) if defined?(Input::C)
  end

  def queue_cancel
    queue_button(Input::BACK) if defined?(Input::BACK)
    queue_button(Input::B) if defined?(Input::B)
  end

  def queue_action
    queue_button(Input::ACTION) if defined?(Input::ACTION)
    queue_button(Input::A) if defined?(Input::A)
  end

  def queue_special
    queue_button(Input::SPECIAL) if defined?(Input::SPECIAL)
    queue_button(Input::Z) if defined?(Input::Z)
  end

  def option_name(option)
    return nil if !option
    return option.name if option.respond_to?(:name)
    return nil
  rescue
    return nil
  end

  def insert_root_option!(options, option)
    return options if !options || !option

    label = option_name(option)
    if label
      exists = options.any? { |existing| option_name(existing) == label }
      return options if exists
    end

    diagonal_index = options.rindex { |existing| option_name(existing) == _INTL("Diagonal Movement") }
    if diagonal_index
      options.insert(diagonal_index + 1, option)
      return options
    end

    kif_index = options.index { |existing| option_name(existing) == _INTL("KIF Settings") }
    if kif_index
      options.insert(kif_index, option)
      return options
    end

    options << option
    return options
  rescue
    options << option if options
    return options
  end

  def wheel_direction
    wheel = (Input.mouse_wheel rescue 0).to_i
    return -1 if wheel > 0
    return 1 if wheel < 0
    return 0
  rescue
    return 0
  end

  def sprite_hit?(sprite, mx, my)
    return false if !sprite || sprite.disposed?
    return false if !sprite.visible
    width = (sprite.src_rect && sprite.src_rect.width > 0) ? sprite.src_rect.width : (sprite.bitmap ? sprite.bitmap.width : 0)
    height = (sprite.src_rect && sprite.src_rect.height > 0) ? sprite.src_rect.height : (sprite.bitmap ? sprite.bitmap.height : 0)
    return false if width <= 0 || height <= 0
    zoom_x = (sprite.respond_to?(:zoom_x) && sprite.zoom_x && sprite.zoom_x != 0) ? sprite.zoom_x : 1.0
    zoom_y = (sprite.respond_to?(:zoom_y) && sprite.zoom_y && sprite.zoom_y != 0) ? sprite.zoom_y : 1.0

    sx = sprite.x - ((sprite.respond_to?(:ox) ? sprite.ox : 0) * zoom_x)
    sy = sprite.y - ((sprite.respond_to?(:oy) ? sprite.oy : 0) * zoom_y)

    if sprite.respond_to?(:viewport) && sprite.viewport
      vp = sprite.viewport
      sx += vp.rect.x if vp.respond_to?(:rect) && vp.rect
      sy += vp.rect.y if vp.respond_to?(:rect) && vp.rect
      sx -= vp.ox if vp.respond_to?(:ox)
      sy -= vp.oy if vp.respond_to?(:oy)
    end

    width *= zoom_x
    height *= zoom_y
    return mx >= sx && mx < sx + width && my >= sy && my < sy + height
  rescue
    return false
  end

  def battle_hovered_index(menu, mx, my)
    buttons = menu.instance_variable_get(:@buttons)
    return nil if !buttons || buttons.empty?
    visibility = menu.instance_variable_get(:@visibility)
    buttons.each_with_index do |button, i|
      next if !button || button.disposed?
      if visibility.is_a?(Hash)
        key = "button_#{i}"
        next if visibility.key?(key) && !visibility[key]
      end
      return i if sprite_hit?(button, mx, my)
    end
    return nil
  end

  def battle_sprite_hit?(menu, key, mx, my)
    sprites = menu.instance_variable_get(:@sprites)
    return false if !sprites || !sprites.is_a?(Hash)
    sprite = sprites[key]
    return false if !sprite
    visibility = menu.instance_variable_get(:@visibility)
    return false if visibility.is_a?(Hash) && visibility.key?(key) && !visibility[key]
    return sprite_hit?(sprite, mx, my)
  end

  def multiplayer_overlay_mouse_passthrough_blocked?
    if defined?(MultiplayerUI)
      if MultiplayerUI.respond_to?(:hud_visible_on_current_scene?) && !MultiplayerUI.hud_visible_on_current_scene?
        return false
      end
      return true if MultiplayerUI.respond_to?(:mouse_ui_click_consumed?) && MultiplayerUI.mouse_ui_click_consumed?
      return true if MultiplayerUI.respond_to?(:mouse_modal_overlay_open?) && MultiplayerUI.mouse_modal_overlay_open?
    end

    chat = ($chat_window rescue nil)
    return false if !chat || !defined?(ChatWindow)

    pos = pointer_position
    return false if !pos
    mx = pos[0]
    my = pos[1]

    if chat.respond_to?(:handle_x) && chat.respond_to?(:handle_y)
      hx = chat.handle_x
      hy = chat.handle_y
      if mx >= hx && mx < hx + ChatWindow::HANDLE_W &&
         my >= hy && my < hy + ChatWindow::HANDLE_H
        return true
      end
    end

    deploy_progress = (defined?(ChatState) ? (ChatState.deploy_progress rescue nil) : nil)
    panel_visible = !deploy_progress.nil? ? deploy_progress > 0.0 : (defined?(ChatState) && (ChatState.deployed rescue false))
    if panel_visible && chat.respond_to?(:panel_x) && chat.respond_to?(:panel_y)
      px = chat.panel_x
      py = chat.panel_y
      if mx >= px && mx < px + ChatWindow::PANEL_W &&
         my >= py && my < py + ChatWindow::PANEL_H
        return true
      end
    end
    return false
  rescue
    return false
  end
end

module Input
  class << self
    alias mouse_ui_original_update update unless method_defined?(:mouse_ui_original_update)
    alias mouse_ui_original_trigger_qmark trigger? unless method_defined?(:mouse_ui_original_trigger_qmark)
    alias mouse_ui_original_repeat_qmark repeat? unless method_defined?(:mouse_ui_original_repeat_qmark)
    alias mouse_ui_original_press_qmark press? unless method_defined?(:mouse_ui_original_press_qmark)
    alias mouse_ui_original_dir4 dir4 unless method_defined?(:mouse_ui_original_dir4)
    alias mouse_ui_original_dir8 dir8 unless method_defined?(:mouse_ui_original_dir8)
  end

  MOUSE_EDGE_WALK_PX = 96
  MOUSE_EDGE_RUN_PX  = 42
  MOUSE_CENTER_WALK_RADIUS_PX = 68
  MOUSE_CENTER_RUN_RADIUS_PX  = 50
  MOUSE_CENTER_DEADZONE_PX    = 12
  MOUSE_CENTER_RUN_EXPAND_PX  = 28

  def self.mouse_ui_center_move_mode?
    return false if !$PokemonSystem
    return false unless $PokemonSystem.respond_to?(:mouse_ui_map_control_mode)
    return ($PokemonSystem.mouse_ui_map_control_mode || 0).to_i == 2
  rescue
    return false
  end

  def self.mouse_ui_edge_move_mode?
    return false if !$PokemonSystem
    return false unless $PokemonSystem.respond_to?(:mouse_ui_map_control_mode)
    return ($PokemonSystem.mouse_ui_map_control_mode || 0).to_i == 1
  rescue
    return false
  end

  def self.mouse_ui_center_walk_radius_px
    value = MOUSE_CENTER_WALK_RADIUS_PX
    if $PokemonSystem && $PokemonSystem.respond_to?(:mouse_ui_center_walk_radius_px)
      value = ($PokemonSystem.mouse_ui_center_walk_radius_px || value).to_i
    end
    value = 0 if value < 0
    return value
  rescue
    return MOUSE_CENTER_WALK_RADIUS_PX
  end

  def self.mouse_ui_center_run_radius_px
    value = MOUSE_CENTER_RUN_RADIUS_PX
    if $PokemonSystem && $PokemonSystem.respond_to?(:mouse_ui_center_run_radius_px)
      value = ($PokemonSystem.mouse_ui_center_run_radius_px || value).to_i
    end
    walk = mouse_ui_center_walk_radius_px
    value = 0 if value < 0
    value = walk if value > walk
    return value
  rescue
    return MOUSE_CENTER_RUN_RADIUS_PX
  end

  def self.mouse_ui_center_deadzone_px
    value = MOUSE_CENTER_DEADZONE_PX
    if $PokemonSystem && $PokemonSystem.respond_to?(:mouse_ui_center_deadzone_px)
      value = ($PokemonSystem.mouse_ui_center_deadzone_px || value).to_i
    end
    walk = mouse_ui_center_walk_radius_px
    value = 0 if value < 0
    value = walk if value > walk
    return value
  rescue
    return MOUSE_CENTER_DEADZONE_PX
  end

  def self.mouse_ui_center_run_expand_px
    value = MOUSE_CENTER_RUN_EXPAND_PX
    if $PokemonSystem && $PokemonSystem.respond_to?(:mouse_ui_center_run_expand_px)
      value = ($PokemonSystem.mouse_ui_center_run_expand_px || value).to_i
    end
    value = 0 if value < 0
    return value
  rescue
    return MOUSE_CENTER_RUN_EXPAND_PX
  end

  def self.mouse_ui_map_input_allowed?
    return false if !$scene || !defined?(Scene_Map)
    return false if $scene.class != Scene_Map
    return false if !$game_temp
    return false if $game_temp.in_menu || $game_temp.in_battle || $game_temp.message_window_showing
    return false if $PokemonTemp && $PokemonTemp.miniupdate
    return false if !$game_player || $game_player.moving?
    return false if $game_player.respond_to?(:pbMapInterpreterRunning?) && $game_player.pbMapInterpreterRunning?
    return false unless Input.respond_to?(:mouse_in_window) && Input.mouse_in_window
    return true
  rescue
    return false
  end

  def self.mouse_ui_click_priority_frame?
    return false unless defined?(Input::MOUSELEFT) || defined?(Input::MOUSERIGHT)
    left_click = defined?(Input::MOUSELEFT) && mouse_ui_original_trigger_qmark(Input::MOUSELEFT)
    right_click = defined?(Input::MOUSERIGHT) && mouse_ui_original_trigger_qmark(Input::MOUSERIGHT)
    return (left_click || right_click)
  rescue
    return false
  end

  def self.mouse_ui_pending_map_menu?
    return !!@mouse_ui_pending_map_menu
  rescue
    return false
  end

  def self.mouse_ui_edge_vector
    return [0, 0] unless mouse_ui_map_input_allowed?
    # Click actions (use/cancel/menu) should always take priority over mouse-driven walking.
    return [0, 0] if mouse_ui_click_priority_frame?
    # If a right-click pause was requested while moving, stop feeding movement
    # until the pause trigger is replayed on a non-moving frame.
    return [0, 0] if mouse_ui_pending_map_menu?
    mx = Input.mouse_x
    my = Input.mouse_y
    gx = Graphics.width
    gy = Graphics.height

    dx = 0
    dy = 0
    if mouse_ui_center_move_mode?
      cx = gx / 2.0
      cy = gy / 2.0
      off_x = mx - cx
      off_y = my - cy
      abs_x = off_x.abs
      abs_y = off_y.abs
      walk_radius = mouse_ui_center_walk_radius_px
      active_radius = walk_radius + mouse_ui_center_run_expand_px
      deadzone = mouse_ui_center_deadzone_px

      # In center mode, ignore mouse positions outside the center movement zone.
      return [0, 0] if abs_x > active_radius || abs_y > active_radius

      if abs_x <= active_radius && abs_x >= deadzone
        dx = (off_x < 0) ? -1 : 1
      end
      if abs_y <= active_radius && abs_y >= deadzone
        dy = (off_y < 0) ? -1 : 1
      end
    elsif mouse_ui_edge_move_mode?
      dx = -1 if mx <= MOUSE_EDGE_WALK_PX
      dx = 1 if mx >= gx - MOUSE_EDGE_WALK_PX
      dy = -1 if my <= MOUSE_EDGE_WALK_PX
      dy = 1 if my >= gy - MOUSE_EDGE_WALK_PX
    else
      return [0, 0]
    end
    return [dx, dy]
  rescue
    return [0, 0]
  end

  def self.mouse_ui_edge_dir8
    dx, dy = mouse_ui_edge_vector
    return 0 if dx == 0 && dy == 0
    return 7 if dx < 0 && dy < 0
    return 9 if dx > 0 && dy < 0
    return 1 if dx < 0 && dy > 0
    return 3 if dx > 0 && dy > 0
    return 4 if dx < 0
    return 6 if dx > 0
    return 8 if dy < 0
    return 2
  end

  def self.mouse_ui_edge_dir4
    dx, dy = mouse_ui_edge_vector
    return 0 if dx == 0 && dy == 0
    if dx != 0 && dy != 0
      if mouse_ui_center_move_mode?
        cx = Graphics.width / 2.0
        cy = Graphics.height / 2.0
        off_x = (Input.mouse_x - cx).abs
        off_y = (Input.mouse_y - cy).abs
        return (off_x >= off_y) ? (dx < 0 ? 4 : 6) : (dy < 0 ? 8 : 2)
      end
      # Prefer the axis closer to the edge.
      left_dist = Input.mouse_x
      right_dist = Graphics.width - Input.mouse_x
      top_dist = Input.mouse_y
      bottom_dist = Graphics.height - Input.mouse_y
      hdist = dx < 0 ? left_dist : right_dist
      vdist = dy < 0 ? top_dist : bottom_dist
      return (hdist <= vdist) ? (dx < 0 ? 4 : 6) : (dy < 0 ? 8 : 2)
    end
    return 4 if dx < 0
    return 6 if dx > 0
    return 8 if dy < 0
    return 2
  end

  def self.mouse_ui_edge_running?
    return false unless mouse_ui_map_input_allowed?
    dir = mouse_ui_edge_dir4
    return false if dir == 0
    mx = Input.mouse_x
    my = Input.mouse_y
    if mouse_ui_center_move_mode?
      cx = Graphics.width / 2.0
      cy = Graphics.height / 2.0
      abs_x = (mx - cx).abs
      abs_y = (my - cy).abs
      walk_radius = mouse_ui_center_walk_radius_px
      active_radius = walk_radius + mouse_ui_center_run_expand_px
      run_radius = mouse_ui_center_run_radius_px
      return true if abs_x >= run_radius && abs_x <= active_radius
      return true if abs_y >= run_radius && abs_y <= active_radius
      return false
    end
    return true if mx <= MOUSE_EDGE_RUN_PX || mx >= Graphics.width - MOUSE_EDGE_RUN_PX
    return true if my <= MOUSE_EDGE_RUN_PX || my >= Graphics.height - MOUSE_EDGE_RUN_PX
    return false
  rescue
    return false
  end

  def self.update
    mouse_ui_original_update
    if !($scene && defined?(Scene_Map) && $scene.is_a?(Scene_Map))
      @mouse_ui_pending_map_menu = false
    end
    MouseUI.clear_old_buttons
  end

  def self.trigger?(button)
    if (button == Input::USE || button == Input::C) && defined?(Input::MOUSELEFT)
      if mouse_ui_original_trigger_qmark(Input::MOUSELEFT)
        return false if MouseUI.multiplayer_overlay_mouse_passthrough_blocked?
        # Left click should always act as USE, including while mouse movement is active.
        if $scene && defined?(Scene_Map) && $scene.is_a?(Scene_Map)
          return true if ($game_temp && $game_temp.message_window_showing)
          return true
        else
          return true
        end
      end
    end
    if (button == Input::BACK || button == Input::B) && defined?(Input::MOUSERIGHT)
      if mouse_ui_original_trigger_qmark(Input::MOUSERIGHT)
        return false if MouseUI.multiplayer_overlay_mouse_passthrough_blocked?
        if $scene && defined?(Scene_Map) && $scene.is_a?(Scene_Map) &&
           $game_player && $game_player.moving?
          @mouse_ui_pending_map_menu = true
        end
        return true
      end
      if mouse_ui_pending_map_menu? && $scene && defined?(Scene_Map) && $scene.is_a?(Scene_Map) &&
         $game_player && !$game_player.moving?
        @mouse_ui_pending_map_menu = false
        return true
      end
    end
    return true if MouseUI.consume_button(button)
    ret = mouse_ui_original_trigger_qmark(button)
    MouseUI.require_mouse_reactivation if ret && mouse_ui_keyboard_hover_lock_button?(button)
    return ret
  end

  def self.repeat?(button)
    ret = mouse_ui_original_repeat_qmark(button)
    MouseUI.require_mouse_reactivation if ret && mouse_ui_keyboard_hover_lock_button?(button)
    return ret
  end

  def self.mouse_ui_keyboard_hover_lock_button?(button)
    return false if defined?(Input::MOUSELEFT) && button == Input::MOUSELEFT
    return false if defined?(Input::MOUSERIGHT) && button == Input::MOUSERIGHT
    return true
  end

  def self.press?(button)
    if (button == Input::ACTION || (defined?(Input::A) && button == Input::A)) && mouse_ui_edge_running?
      return true
    end
    mouse_ui_original_press_qmark(button)
  end

  def self.dir4
    mouse_dir = mouse_ui_edge_dir4
    return mouse_dir if mouse_dir > 0
    mouse_ui_original_dir4
  end

  def self.dir8
    mouse_dir = mouse_ui_edge_dir8
    return mouse_dir if mouse_dir > 0
    mouse_ui_original_dir8
  end
end

class PokemonSystem
  attr_accessor :mouse_ui_map_control_mode
  attr_accessor :mouse_ui_center_walk_radius_px
  attr_accessor :mouse_ui_center_run_radius_px
  attr_accessor :mouse_ui_center_deadzone_px
  attr_accessor :mouse_ui_center_run_expand_px
  attr_accessor :mouse_ui_hover_throttle_level
  attr_accessor :mouse_ui_load_scroll_cooldown

  alias mouse_ui_map_control_original_initialize initialize unless method_defined?(:mouse_ui_map_control_original_initialize)
  def initialize
    mouse_ui_map_control_original_initialize
    @mouse_ui_map_control_mode = 0 if @mouse_ui_map_control_mode.nil?
    @mouse_ui_center_walk_radius_px = 68 if @mouse_ui_center_walk_radius_px.nil?
    @mouse_ui_center_run_radius_px = 50 if @mouse_ui_center_run_radius_px.nil?
    @mouse_ui_center_deadzone_px = 12 if @mouse_ui_center_deadzone_px.nil?
    @mouse_ui_center_run_expand_px = 28 if @mouse_ui_center_run_expand_px.nil?
    @mouse_ui_hover_throttle_level = 2 if @mouse_ui_hover_throttle_level.nil?
    @mouse_ui_load_scroll_cooldown = 4 if @mouse_ui_load_scroll_cooldown.nil?
  end
end

if defined?(PokemonOption_Scene)
  class PokemonOption_Scene
    alias mouse_ui_original_root_pbGetOptions pbGetOptions unless method_defined?(:mouse_ui_original_root_pbGetOptions)

    def pbGetOptions(inloadscreen = false)
      options = mouse_ui_original_root_pbGetOptions(inloadscreen)
      mouse_option = ButtonOption.new(_INTL("Mouse Options"),
        proc { openMouseUIOptionsMenu },
        "Tune mouse movement, hover scrolling, and click navigation"
      )

      MouseUI.insert_root_option!(options, mouse_option)
      return options
    end

    def openMouseUIOptionsMenu
      pbFadeOutIn {
        scene = MouseUIOptionsScene.new
        screen = PokemonOptionScreen.new(scene)
        screen.pbStartScreen
      }
    end
  end

  class MouseUIOptionsScene < PokemonOption_Scene
    def initialize
      @changedColor = false
    end

    def pbStartScene(inloadscreen = false)
      super
      @sprites["option"].nameBaseColor = Color.new(130, 130, 130)
      @sprites["option"].nameShadowColor = Color.new(75, 75, 75)
      @changedColor = true
      for i in 0...@PokemonOptions.length
        @sprites["option"][i] = (@PokemonOptions[i].get || 0)
      end
      @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
        _INTL("Mouse Options"), 0, 0, Graphics.width, 64, @viewport)
      @sprites["textbox"].text = _INTL("Tune mouse movement, hover scrolling, and click behavior")
      pbFadeInAndShow(@sprites) { pbUpdate }
    end

    def pbFadeInAndShow(sprites, visiblesprites = nil)
      return if !@changedColor
      super
    end

    def pbGetOptions(inloadscreen = false)
      options = []
      options << EnumOption.new(_INTL("Move Zone"), [_INTL("Off"), _INTL("Edges"), _INTL("Center")],
        proc { ($PokemonSystem.mouse_ui_map_control_mode || 0) },
        proc { |value| $PokemonSystem.mouse_ui_map_control_mode = value },
        ["Disable mouse-driven overworld movement (menus and clicks still work).",
         "Move with the mouse near screen edges. Runs at the very edge.",
         "Move only near screen center. Walk near center, run farther out."]
      )
      options << SliderOption.new(_INTL("Center Walk Radius"), 0, 240, 2,
        proc { ($PokemonSystem.mouse_ui_center_walk_radius_px || 68) },
        proc { |value|
          $PokemonSystem.mouse_ui_center_walk_radius_px = value
          active = value + ($PokemonSystem.mouse_ui_center_run_expand_px || 28)
          if ($PokemonSystem.mouse_ui_center_run_radius_px || 0) > active
            $PokemonSystem.mouse_ui_center_run_radius_px = active
          end
          if ($PokemonSystem.mouse_ui_center_deadzone_px || 0) > value
            $PokemonSystem.mouse_ui_center_deadzone_px = value
          end
        },
        "Center mode movement zone size in pixels"
      )
      options << SliderOption.new(_INTL("Center Run Radius"), 0, 240, 2,
        proc { ($PokemonSystem.mouse_ui_center_run_radius_px || 50) },
        proc { |value|
          active = ($PokemonSystem.mouse_ui_center_walk_radius_px || 68) + ($PokemonSystem.mouse_ui_center_run_expand_px || 28)
          $PokemonSystem.mouse_ui_center_run_radius_px = (value > active) ? active : value
        },
        "In center mode, start running when farther than this radius"
      )
      options << SliderOption.new(_INTL("Run Expand Radius"), 0, 200, 2,
        proc { ($PokemonSystem.mouse_ui_center_run_expand_px || 28) },
        proc { |value|
          $PokemonSystem.mouse_ui_center_run_expand_px = value
          active = ($PokemonSystem.mouse_ui_center_walk_radius_px || 68) + value
          if ($PokemonSystem.mouse_ui_center_run_radius_px || 0) > active
            $PokemonSystem.mouse_ui_center_run_radius_px = active
          end
        },
        "Extra outer radius where center-mode movement continues as run"
      )
      options << SliderOption.new(_INTL("Center Deadzone"), 0, 120, 1,
        proc { ($PokemonSystem.mouse_ui_center_deadzone_px || 12) },
        proc { |value|
          walk = ($PokemonSystem.mouse_ui_center_walk_radius_px || 68)
          $PokemonSystem.mouse_ui_center_deadzone_px = (value > walk) ? walk : value
        },
        "In center mode, no movement inside this radius"
      )
      options << EnumOption.new(_INTL("List Scroll Throttle"), [_INTL("VFast"), _INTL("Fast"), _INTL("Norm"), _INTL("Slow"), _INTL("VSlow")],
        proc { ($PokemonSystem.mouse_ui_hover_throttle_level || 2) },
        proc { |value| $PokemonSystem.mouse_ui_hover_throttle_level = value },
        ["Fastest stepped hover scrolling for long lists",
         "Faster stepped hover scrolling for long lists",
         "Balanced stepped hover scrolling for long lists",
         "Slower stepped hover scrolling speed",
         "Slowest stepped hover scrolling speed"]
      )
      options << NumberOption.new(_INTL("Load Edge Scroll Delay"), 0, 15,
        proc { ($PokemonSystem.mouse_ui_load_scroll_cooldown || 4) },
        proc { |value| $PokemonSystem.mouse_ui_load_scroll_cooldown = value },
        "Frames to wait before edge-hover scrolling advances the load list again"
      )
      return options
    end
  end
end

if defined?(MultiplayerUI) && defined?(MultiplayerUI::HotkeyHUD)
  class MultiplayerUI::HotkeyHUD
    def mouse_ui_visible_buttons
      in_squad = !!(defined?(MultiplayerClient) && MultiplayerClient.respond_to?(:in_squad?) && MultiplayerClient.in_squad? rescue false)
      self.class::BUTTONS.reject { |b| b[:key] == :squad && !in_squad }
    rescue
      []
    end

    def mouse_ui_button_key_at(mx, my)
      return nil if !@spr || @spr.disposed? || !@spr.visible
      rel_x = mx - @spr.x
      rel_y = my - @spr.y
      return nil if rel_x < 0 || rel_y < 0
      return nil if rel_x >= self.class::BTN_W

      buttons = mouse_ui_visible_buttons
      buttons.each_with_index do |btn, i|
        top = i * (self.class::BTN_H + self.class::BTN_GAP)
        bottom = top + self.class::BTN_H
        return btn[:key] if rel_y >= top && rel_y < bottom
      end
      nil
    rescue
      nil
    end

    def mouse_ui_activate_button(button_key)
      return if button_key.nil?
      case button_key
      when :chat
        if defined?(ChatState)
          chat_visible = !!(ChatState.visible rescue false)
          can_type = ($scene && $scene.is_a?(Scene_Map) && !$game_temp.in_menu && !$game_temp.in_battle && !$game_player.move_route_forcing rescue false)
          if chat_visible && can_type && defined?(ChatInput) && ChatInput.respond_to?(:open_chat_input)
            ChatInput.open_chat_input
          elsif ChatState.respond_to?(:toggle_visibility)
            ChatState.toggle_visibility
          end
        end
      when :gts
        GTSUI.open if defined?(GTSUI) && GTSUI.respond_to?(:open)
      when :players
        if defined?(MultiplayerUI)
          if MultiplayerUI.instance_variable_get(:@playerlist_open)
            MultiplayerUI.instance_variable_set(:@playerlist_close_requested, true)
          elsif MultiplayerUI.respond_to?(:openPlayerList)
            MultiplayerUI.openPlayerList
          end
        end
      when :squad
        if defined?(MultiplayerUI)
          if MultiplayerUI.instance_variable_get(:@squadwindow_open)
            MultiplayerUI.instance_variable_set(:@squadwindow_close_requested, true)
          elsif MultiplayerUI.respond_to?(:openSquadWindow)
            MultiplayerUI.openSquadWindow
          end
        end
      when :cases
        if defined?(KIFCases)
          if KIFCases.respond_to?(:screen_open?) && KIFCases.screen_open?
            KIFCases.request_close if KIFCases.respond_to?(:request_close)
          elsif defined?(KIFCases::CaseSelectScreen) && KIFCases::CaseSelectScreen.respond_to?(:open)
            KIFCases::CaseSelectScreen.open
          end
        end
      when :profile
        if defined?(MultiplayerUI::ProfilePanel)
          if MultiplayerUI::ProfilePanel.respond_to?(:open?) && MultiplayerUI::ProfilePanel.open?
            MultiplayerUI::ProfilePanel.close if MultiplayerUI::ProfilePanel.respond_to?(:close)
          elsif MultiplayerUI::ProfilePanel.respond_to?(:open)
            MultiplayerUI::ProfilePanel.open(uuid: "self")
          end
        end
      end
    rescue
    end

    alias mouse_ui_original_hotkeyhud_update update
    def update
      mouse_ui_original_hotkeyhud_update

      return if !$scene || !defined?(Scene_Map) || !$scene.is_a?(Scene_Map)
      return if !defined?(MultiplayerClient)
      return if !MultiplayerClient.instance_variable_get(:@connected)
      return if ($game_temp && ($game_temp.in_menu || $game_temp.in_battle))

      left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      return if !left_click
      pos = MouseUI.pointer_position
      return if !pos
      key = mouse_ui_button_key_at(pos[0], pos[1])
      mouse_ui_activate_button(key)
    rescue
    end
  end
end

class PokemonBag_Scene
  def pbMouseUIBagPocketAvailable?(pocket)
    return false if pocket <= 0 || pocket > PokemonBag.numPockets
    return true if !@choosing
    if @filterlist
      return @filterlist[pocket] && @filterlist[pocket].length > 0
    end
    return @bag.pockets[pocket] && @bag.pockets[pocket].length > 0
  rescue
    return false
  end

  def pbMouseUIBagStepPocket(current, direction)
    newpocket = current
    loop do
      newpocket = (direction < 0) ? ((newpocket == 1) ? PokemonBag.numPockets : newpocket - 1) : ((newpocket == PokemonBag.numPockets) ? 1 : newpocket + 1)
      break if !@choosing || newpocket == current
      break if pbMouseUIBagPocketAvailable?(newpocket)
    end
    return newpocket
  rescue
    return current
  end

  def pbMouseUIBagPocketFromRow(mx, my)
    row = @sprites["pocketicon"]
    return nil if !row || row.disposed?
    return nil if !row.visible
    rel_x = mx - row.x
    rel_y = my - row.y
    return nil if rel_y < 0 || rel_y >= 32
    return nil if rel_x < 0 || rel_x >= 186
    pocket = ((rel_x - 2) / 22).floor + 1
    return nil if pocket <= 0 || pocket > PokemonBag.numPockets
    return pocket
  rescue
    return nil
  end

  def pbMouseUIBagApplyPocket(newpocket)
    itemwindow = @sprites["itemlist"]
    return if !itemwindow || itemwindow.disposed?
    return if newpocket <= 0 || newpocket > PokemonBag.numPockets
    return if !pbMouseUIBagPocketAvailable?(newpocket)
    return if itemwindow.pocket == newpocket
    itemwindow.pocket = newpocket
    @bag.lastpocket = newpocket
    pbPlayCursorSE
    pbRefresh
  rescue
  end

  alias mouse_ui_original_bag_pbUpdate pbUpdate
  def pbUpdate
    mouse_ui_original_bag_pbUpdate
    return if !@sprites || !@sprites["itemlist"]
    itemwindow = @sprites["itemlist"]
    return if !itemwindow.active

    pos = MouseUI.pointer_position
    return if !pos
    mx = pos[0]
    my = pos[1]

    left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
    if left_click
      clicked_pocket = pbMouseUIBagPocketFromRow(mx, my)
      if clicked_pocket && pbMouseUIBagPocketAvailable?(clicked_pocket)
        @mouse_ui_bag_target_pocket = clicked_pocket
      elsif @sprites["leftarrow"] && MouseUI.sprite_hit?(@sprites["leftarrow"], mx, my)
        @mouse_ui_bag_target_pocket = pbMouseUIBagStepPocket(itemwindow.pocket, -1)
      elsif @sprites["rightarrow"] && MouseUI.sprite_hit?(@sprites["rightarrow"], mx, my)
        @mouse_ui_bag_target_pocket = pbMouseUIBagStepPocket(itemwindow.pocket, 1)
      end
    end

    if @mouse_ui_bag_target_pocket
      if @mouse_ui_bag_target_pocket == itemwindow.pocket
        @mouse_ui_bag_target_pocket = nil
      else
        left_next = pbMouseUIBagStepPocket(itemwindow.pocket, -1)
        right_next = pbMouseUIBagStepPocket(itemwindow.pocket, 1)
        target = @mouse_ui_bag_target_pocket
        # Drive existing keyboard logic one step at a time to keep all internal
        # item window references in sync with the base scene code.
        if left_next == target
          MouseUI.queue_button(Input::LEFT)
        elsif right_next == target
          MouseUI.queue_button(Input::RIGHT)
        else
          left_dist = 0
          cur = itemwindow.pocket
          loop do
            cur = pbMouseUIBagStepPocket(cur, -1)
            left_dist += 1
            break if cur == target || cur == itemwindow.pocket || left_dist > PokemonBag.numPockets
          end
          right_dist = 0
          cur = itemwindow.pocket
          loop do
            cur = pbMouseUIBagStepPocket(cur, 1)
            right_dist += 1
            break if cur == target || cur == itemwindow.pocket || right_dist > PokemonBag.numPockets
          end
          MouseUI.queue_button((left_dist <= right_dist) ? Input::LEFT : Input::RIGHT)
        end
      end
    end
  end
end

class PokemonParty_Scene
  def pbMouseUIPartySpriteHit?(sprite, mx, my)
    return false if !sprite || sprite.disposed?
    return true if MouseUI.sprite_hit?(sprite, mx, my)
    panel = sprite.instance_variable_get(:@panelbgsprite) rescue nil
    return true if panel && MouseUI.sprite_hit?(panel, mx, my)
    bg = sprite.instance_variable_get(:@bgsprite) rescue nil
    return true if bg && MouseUI.sprite_hit?(bg, mx, my)
    return false
  rescue
    return false
  end

  def pbMouseUIPartyHoverIndex
    return nil unless MouseUI.mouse_hover_active?
    pos = MouseUI.pointer_position
    return nil if !pos
    mx = pos[0]
    my = pos[1]
    numsprites = Settings::MAX_PARTY_SIZE + ((@multiselect) ? 2 : 1)
    0.upto(numsprites - 1) do |i|
      sprite = @sprites["pokemon#{i}"]
      next if !sprite
      return i if pbMouseUIPartySpriteHit?(sprite, mx, my)
    end
    return nil
  end

  alias mouse_ui_original_party_choose pbChoosePokemon
  def pbChoosePokemon(switching = false, initialsel = -1, canswitch = 0)
    for i in 0...Settings::MAX_PARTY_SIZE
      @sprites["pokemon#{i}"].preselected = (switching && i == @activecmd)
      @sprites["pokemon#{i}"].switching = switching
    end
    @activecmd = initialsel if initialsel >= 0
    pbRefresh
    loop do
      Graphics.update
      Input.update
      self.update

      oldsel = @activecmd
      if MouseUI.mouse_hover_active?
        hover_idx = pbMouseUIPartyHoverIndex
        if !hover_idx.nil? && hover_idx != @activecmd
          @activecmd = hover_idx
        end
      end

      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        @activecmd = pbChangeSelection(key, @activecmd)
      end

      if @activecmd != oldsel
        pbPlayCursorSE
        numsprites = Settings::MAX_PARTY_SIZE + ((@multiselect) ? 2 : 1)
        for i in 0...numsprites
          @sprites["pokemon#{i}"].selected = (i == @activecmd)
        end
      end

      cancelsprite = Settings::MAX_PARTY_SIZE + ((@multiselect) ? 1 : 0)
      left_click = (defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT))
      right_click = (defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT))

      if Input.trigger?(Input::ACTION) && canswitch == 1 && @activecmd != cancelsprite
        pbPlayDecisionSE
        return [1, @activecmd]
      elsif Input.trigger?(Input::ACTION) && canswitch == 2
        return -1
      elsif right_click || Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE if !switching
        return -1
      elsif left_click || Input.trigger?(Input::USE)
        if @activecmd == cancelsprite
          (switching) ? pbPlayDecisionSE : pbPlayCloseMenuSE
          return -1
        else
          pbPlayDecisionSE
          return @activecmd
        end
      end
    end
  end
end

class PokeBattle_Scene
  def pbMouseUITargetHoverIndex(window, texts, mx, my)
    buttons = window.instance_variable_get(:@buttons)
    return nil if !buttons

    if buttons.is_a?(Array)
      buttons.each_with_index do |button, i|
        next if !button
        next if texts && texts[i].nil?
        return i if MouseUI.sprite_hit?(button, mx, my)
      end
    elsif buttons.is_a?(Hash)
      keys = buttons.keys.sort_by { |k| k.to_i }
      keys.each do |key|
        button = buttons[key]
        next if !button
        idx = key.to_i
        next if texts && texts[idx].nil?
        return idx if MouseUI.sprite_hit?(button, mx, my)
      end
    end
    return nil
  rescue
    return nil
  end

  alias mouse_ui_original_pbCommandMenuEx pbCommandMenuEx
  def pbCommandMenuEx(idxBattler, texts, mode = 0)
    pbShowWindow(COMMAND_BOX)
    cw = @sprites["commandWindow"]
    cw.setTexts(texts)
    cw.setIndexAndMode(@lastCmd[idxBattler], mode)
    pbSelectBattler(idxBattler)
    ret = -1
    loop do
      oldIndex = cw.index
      pbUpdate(cw)

      mouse_blocked = MouseUI.multiplayer_overlay_mouse_passthrough_blocked?
      mouse_pos = mouse_blocked ? nil : MouseUI.pointer_position
      mouse_hover = nil
      if mouse_pos && MouseUI.mouse_hover_active?
        mouse_hover = MouseUI.battle_hovered_index(cw, mouse_pos[0], mouse_pos[1])
        if !mouse_hover.nil? && mouse_hover != cw.index
          cw.index = mouse_hover
          pbPlayCursorSE
        end
      end

      key_navigation = false
      if Input.trigger?(Input::LEFT)
        key_navigation = true
        cw.index -= 1 if (cw.index & 1) == 1
      elsif Input.trigger?(Input::RIGHT)
        key_navigation = true
        cw.index += 1 if (cw.index & 1) == 0
      elsif Input.trigger?(Input::UP)
        key_navigation = true
        cw.index -= 2 if (cw.index & 2) == 2
      elsif Input.trigger?(Input::DOWN)
        key_navigation = true
        cw.index += 2 if (cw.index & 2) == 0
      end
      pbPlayCursorSE if cw.index != oldIndex
      MouseUI.require_mouse_reactivation if key_navigation

      left_click = !mouse_blocked && defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      right_click = !mouse_blocked && defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      if left_click && !mouse_hover.nil?
        pbPlayDecisionSE
        ret = cw.index
        @lastCmd[idxBattler] = ret
        break
      elsif right_click && mode == 1
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = cw.index
        @lastCmd[idxBattler] = ret
        break
      elsif Input.trigger?(Input::BACK) && mode == 1
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::F9) && $DEBUG
        pbPlayDecisionSE
        ret = -2
        break
      end
    end
    return ret
  end

  alias mouse_ui_original_pbFightMenu pbFightMenu
  def pbFightMenu(idxBattler, megaEvoPossible = false)
    battler = @battle.battlers[idxBattler]
    cw = @sprites["fightWindow"]
    cw.battler = battler
    moveIndex = 0
    if battler.moves[@lastMove[idxBattler]] && battler.moves[@lastMove[idxBattler]].id
      moveIndex = @lastMove[idxBattler]
    end
    cw.shiftMode = (@battle.pbCanShift?(idxBattler)) ? 1 : 0
    cw.setIndexAndMode(moveIndex, (megaEvoPossible) ? 1 : 0)
    needFullRefresh = true
    needRefresh = false
    loop do
      if needFullRefresh
        pbShowWindow(FIGHT_BOX)
        pbSelectBattler(idxBattler)
        needFullRefresh = false
      end
      if needRefresh
        if megaEvoPossible
          newMode = (@battle.pbRegisteredMegaEvolution?(idxBattler)) ? 2 : 1
          cw.mode = newMode if newMode != cw.mode
        end
        needRefresh = false
      end

      oldIndex = cw.index
      pbUpdate(cw)

      mouse_blocked = MouseUI.multiplayer_overlay_mouse_passthrough_blocked?
      mouse_pos = mouse_blocked ? nil : MouseUI.pointer_position
      mouse_hover = nil
      if mouse_pos && MouseUI.mouse_hover_active?
        mouse_hover = MouseUI.battle_hovered_index(cw, mouse_pos[0], mouse_pos[1])
        if !mouse_hover.nil? && mouse_hover != cw.index
          cw.index = mouse_hover
          pbPlayCursorSE
        end
      end

      key_navigation = false
      if Input.trigger?(Input::LEFT)
        key_navigation = true
        cw.index -= 1 if (cw.index & 1) == 1
      elsif Input.trigger?(Input::RIGHT)
        key_navigation = true
        if battler.moves[cw.index + 1] && battler.moves[cw.index + 1].id
          cw.index += 1 if (cw.index & 1) == 0
        end
      elsif Input.trigger?(Input::UP)
        key_navigation = true
        cw.index -= 2 if (cw.index & 2) == 2
      elsif Input.trigger?(Input::DOWN)
        key_navigation = true
        if battler.moves[cw.index + 2] && battler.moves[cw.index + 2].id
          cw.index += 2 if (cw.index & 2) == 0
        end
      end
      pbPlayCursorSE if cw.index != oldIndex
      MouseUI.require_mouse_reactivation if key_navigation

      left_click = !mouse_blocked && defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      right_click = !mouse_blocked && defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      if left_click
        if !mouse_hover.nil?
          pbPlayDecisionSE
          break if yield cw.index
          needFullRefresh = true
          needRefresh = true
          next
        elsif mouse_pos && MouseUI.battle_sprite_hit?(cw, "megaButton", mouse_pos[0], mouse_pos[1]) && megaEvoPossible
          pbPlayDecisionSE
          break if yield -2
          needRefresh = true
          next
        elsif mouse_pos && MouseUI.battle_sprite_hit?(cw, "shiftButton", mouse_pos[0], mouse_pos[1]) && cw.shiftMode > 0
          pbPlayDecisionSE
          break if yield -3
          needRefresh = true
          next
        end
      end

      if right_click || Input.trigger?(Input::BACK) || Input.trigger?(Input::ACTION)
        pbPlayCancelSE
        break if yield -1
        needRefresh = true
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break if yield cw.index
        needFullRefresh = true
        needRefresh = true
      elsif Input.trigger?(Input::ACTION)
        if megaEvoPossible
          pbPlayDecisionSE
          break if yield -2
          needRefresh = true
        end
      elsif Input.trigger?(Input::SPECIAL)
        if cw.shiftMode > 0
          pbPlayDecisionSE
          break if yield -3
          needRefresh = true
        end
      end
    end
    @lastMove[idxBattler] = cw.index
  end

  alias mouse_ui_original_pbChooseTarget pbChooseTarget
  def pbChooseTarget(idxBattler, target_data, visibleSprites = nil)
    pbShowWindow(TARGET_BOX)
    cw = @sprites["targetWindow"]
    texts = pbCreateTargetTexts(idxBattler, target_data)
    mode = (target_data.num_targets == 1) ? 0 : 1
    cw.setDetails(texts, mode)
    cw.index = pbFirstTarget(idxBattler, target_data)
    pbSelectBattler((mode == 0) ? cw.index : texts, 2)
    pbFadeInAndShow(@sprites, visibleSprites) if visibleSprites
    ret = -1
    loop do
      oldIndex = cw.index
      pbUpdate(cw)

      mouse_blocked = MouseUI.multiplayer_overlay_mouse_passthrough_blocked?
      mouse_pos = mouse_blocked ? nil : MouseUI.pointer_position
      mouse_hover = nil
      if mode == 0 && mouse_pos && MouseUI.mouse_hover_active?
        mouse_hover = pbMouseUITargetHoverIndex(cw, texts, mouse_pos[0], mouse_pos[1])
        if !mouse_hover.nil? && mouse_hover != cw.index
          cw.index = mouse_hover
          pbPlayCursorSE
          pbSelectBattler(cw.index, 2)
        end
      end

      if mode == 0
        key_navigation = false
        if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
          key_navigation = true
          inc = ((cw.index % 2) == 0) ? -2 : 2
          inc *= -1 if Input.trigger?(Input::RIGHT)
          indexLength = @battle.sideSizes[cw.index % 2] * 2
          newIndex = cw.index
          loop do
            newIndex += inc
            break if newIndex < 0 || newIndex >= indexLength
            next if texts[newIndex].nil?
            cw.index = newIndex
            break
          end
        elsif (Input.trigger?(Input::UP) && (cw.index % 2) == 0) ||
              (Input.trigger?(Input::DOWN) && (cw.index % 2) == 1)
          key_navigation = true
          tryIndex = @battle.pbGetOpposingIndicesInOrder(cw.index)
          tryIndex.each do |idxBattlerTry|
            next if texts[idxBattlerTry].nil?
            cw.index = idxBattlerTry
            break
          end
        end
        if cw.index != oldIndex
          pbPlayCursorSE
          pbSelectBattler(cw.index, 2)
        end
        MouseUI.require_mouse_reactivation if key_navigation
      end

      left_click = !mouse_blocked && defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      right_click = !mouse_blocked && defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      if left_click
        if mode == 0 && !mouse_hover.nil?
          cw.index = mouse_hover
          ret = cw.index
          pbPlayDecisionSE
          break
        end
      end

      if Input.trigger?(Input::USE)
        ret = cw.index
        pbPlayDecisionSE
        break
      elsif right_click || Input.trigger?(Input::BACK)
        ret = -1
        pbPlayCancelSE
        break
      end
    end
    pbSelectBattler(-1)
    return ret
  end
end

class PokeBattle_SceneEBDX
  def pbMouseUIEBDXCommandHoverIndex(window, mx, my)
    indexes = window.indexes rescue []
    sprites = window.instance_variable_get(:@sprites)
    return nil if !sprites || indexes.nil?
    indexes.length.times do |i|
      sprite = sprites["b#{i}"]
      next if !sprite
      return i if MouseUI.sprite_hit?(sprite, mx, my)
    end
    return nil
  rescue
    return nil
  end

  def pbMouseUIEBDXFightHoverIndex(window, mx, my)
    nummoves = window.nummoves rescue 0
    return nil if nummoves <= 0
    return 0 if nummoves == 1

    xs = window.instance_variable_get(:@x)
    ys = window.instance_variable_get(:@y)
    if xs && ys && xs.length >= nummoves && ys.length >= nummoves
      xvals = xs[0, nummoves].compact
      yvals = ys[0, nummoves].compact
      if !xvals.empty? && !yvals.empty?
        xsplit = (xvals.min + xvals.max) / 2.0
        row_vals = yvals.uniq.sort
        col = (mx >= xsplit) ? 1 : 0
        if nummoves <= 2 || row_vals.length <= 1
          idx = col
          idx = nummoves - 1 if idx >= nummoves
          return idx
        end
        ysplit = (row_vals[0] + row_vals[-1]) / 2.0
        row = (my >= ysplit) ? 1 : 0
        idx = row * 2 + col
        if idx >= nummoves
          idx = row * 2
          idx = nummoves - 1 if idx >= nummoves
        end
        return idx
      end
    end

    btn_hash = window.instance_variable_get(:@button)
    return nil if !btn_hash
    nummoves.times do |i|
      sprite = btn_hash["#{i}"]
      next if !sprite
      return i if MouseUI.sprite_hit?(sprite, mx, my)
    end
    return nil
  rescue
    return nil
  end

  def pbMouseUIEBDXTargetHoverIndex(window, texts, mx, my)
    buttons = window.instance_variable_get(:@buttons)
    return nil if !buttons

    if buttons.is_a?(Hash)
      buttons.each do |key, sprite|
        next if !sprite
        idx = key.to_i
        next if texts && texts[idx].nil?
        return idx if MouseUI.sprite_hit?(sprite, mx, my)
      end
    elsif buttons.is_a?(Array)
      buttons.each_with_index do |sprite, i|
        next if !sprite
        next if texts && texts[i].nil?
        return i if MouseUI.sprite_hit?(sprite, mx, my)
      end
    end
    return nil
  rescue
    return nil
  end

  alias mouse_ui_original_pbCommandMenuEBDX pbCommandMenuEBDX
  def pbCommandMenuEBDX(idxBattler, firstAction)
    @commandWindow.refreshCommands(idxBattler) if @commandWindow.respond_to?(:refreshCommands)
    @commandWindow.showPlay if @commandWindow.respond_to?(:showPlay)
    numCommands = @commandWindow.indexes.length rescue 4
    if @commandWindow.respond_to?(:index=)
      remembered_index = (@lastCmd && @lastCmd[idxBattler]) || 0
      remembered_index = [[remembered_index, 0].max, numCommands - 1].min
      @commandWindow.index = remembered_index
    end
    ret = -1
    loop do
      pbUpdate(@commandWindow)

      mouse_blocked = MouseUI.multiplayer_overlay_mouse_passthrough_blocked?
      mouse_pos = mouse_blocked ? nil : MouseUI.pointer_position
      mouse_hover = nil
      if mouse_pos && MouseUI.mouse_hover_active?
        mouse_hover = pbMouseUIEBDXCommandHoverIndex(@commandWindow, mouse_pos[0], mouse_pos[1])
        if !mouse_hover.nil? && @commandWindow.respond_to?(:index) && @commandWindow.respond_to?(:index=) && mouse_hover != @commandWindow.index
          @commandWindow.index = mouse_hover
          pbPlayCursorSE
        end
      end

      key_navigation = false
      if Input.trigger?(Input::LEFT)
        key_navigation = true
        @commandWindow.index = (@commandWindow.index - 1) % numCommands if @commandWindow.respond_to?(:index=)
        pbPlayCursorSE
      elsif Input.trigger?(Input::RIGHT)
        key_navigation = true
        @commandWindow.index = (@commandWindow.index + 1) % numCommands if @commandWindow.respond_to?(:index=)
        pbPlayCursorSE
      elsif Input.trigger?(Input::UP)
        key_navigation = true
        @commandWindow.index = (@commandWindow.index - 1) % numCommands if @commandWindow.respond_to?(:index=)
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        key_navigation = true
        @commandWindow.index = (@commandWindow.index + 1) % numCommands if @commandWindow.respond_to?(:index=)
        pbPlayCursorSE
      elsif !mouse_blocked && defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT) && !mouse_hover.nil?
        ret = @commandWindow.indexes[@commandWindow.index] rescue @commandWindow.index
        @lastCmd[idxBattler] = ret if @lastCmd && ret >= 0
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::USE)
        ret = @commandWindow.indexes[@commandWindow.index] rescue @commandWindow.index
        @lastCmd[idxBattler] = ret if @lastCmd && ret >= 0
        pbPlayDecisionSE
        break
      elsif (!mouse_blocked && defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)) || Input.trigger?(Input::BACK)
        if firstAction
          pbPlayBuzzerSE
        else
          ret = -1
          pbPlayCancelSE
          break
        end
      end
      MouseUI.require_mouse_reactivation if key_navigation
    end
    @commandWindow.hidePlay if @commandWindow.respond_to?(:hidePlay)
    return ret
  end

  alias mouse_ui_original_pbFightMenu_EBDX pbFightMenu
  def pbFightMenu(idxBattler, megaEvoPossible = false)
    clearMessageWindow(true) if respond_to?(:clearMessageWindow)
    battler = @battle.battlers[idxBattler]
    cw = @fightWindow || @sprites["fightWindow"]
    if @fightWindow && @fightWindow.is_a?(FightWindowEBDX)
      @fightWindow.battler = battler if @fightWindow.respond_to?(:battler=)
      @fightWindow.generateButtons if @fightWindow.respond_to?(:generateButtons)
      @fightWindow.megaButton if megaEvoPossible && @fightWindow.respond_to?(:megaButton)
    end
    moveIndex = 0
    if battler.moves[@lastMove[idxBattler]] && battler.moves[@lastMove[idxBattler]].id
      moveIndex = @lastMove[idxBattler]
    end
    cw.shiftMode = (@battle.pbCanShift?(idxBattler)) ? 1 : 0 if cw.respond_to?(:shiftMode=)
    if cw.respond_to?(:setIndexAndMode)
      cw.setIndexAndMode(moveIndex, (megaEvoPossible) ? 1 : 0)
    else
      cw.index = moveIndex if cw.respond_to?(:index=)
    end

    needFullRefresh = true
    needRefresh = false
    loop do
      if needFullRefresh
        if @fightWindow && @fightWindow.is_a?(FightWindowEBDX)
          @fightWindow.showPlay if @fightWindow.respond_to?(:showPlay)
        else
          pbShowWindow(FIGHT_BOX)
        end
        pbSelectBattler(idxBattler)
        needFullRefresh = false
      end
      if needRefresh
        if megaEvoPossible && cw.respond_to?(:mode=)
          newMode = (@battle.pbRegisteredMegaEvolution?(idxBattler)) ? 2 : 1
          cw.mode = newMode if newMode != cw.mode
        end
        needRefresh = false
      end

      oldIndex = cw.index rescue 0
      pbUpdate(cw)

      mouse_blocked = MouseUI.multiplayer_overlay_mouse_passthrough_blocked?
      mouse_pos = mouse_blocked ? nil : MouseUI.pointer_position
      mouse_hover = nil
      if mouse_pos && MouseUI.mouse_hover_active?
        mouse_hover = pbMouseUIEBDXFightHoverIndex(cw, mouse_pos[0], mouse_pos[1])
        if !mouse_hover.nil? && cw.respond_to?(:index) && cw.respond_to?(:index=) && mouse_hover != cw.index
          cw.index = mouse_hover
          pbSEPlay("EBDX/SE_Select1", 80)
        end
      end

      key_navigation = false
      if Input.trigger?(Input::LEFT)
        key_navigation = true
        cw.index -= 1 if cw.respond_to?(:index=) && (cw.index & 1) == 1
        pbSEPlay("EBDX/SE_Select1", 80) if cw.index != oldIndex
      elsif Input.trigger?(Input::RIGHT)
        key_navigation = true
        if battler.moves[cw.index + 1] && battler.moves[cw.index + 1].id
          cw.index += 1 if cw.respond_to?(:index=) && (cw.index & 1) == 0
        end
        pbSEPlay("EBDX/SE_Select1", 80) if cw.index != oldIndex
      elsif Input.trigger?(Input::UP)
        key_navigation = true
        cw.index -= 2 if cw.respond_to?(:index=) && (cw.index & 2) == 2
        pbSEPlay("EBDX/SE_Select1", 80) if cw.index != oldIndex
      elsif Input.trigger?(Input::DOWN)
        key_navigation = true
        if battler.moves[cw.index + 2] && battler.moves[cw.index + 2].id
          cw.index += 2 if cw.respond_to?(:index=) && (cw.index & 2) == 0
        end
        pbSEPlay("EBDX/SE_Select1", 80) if cw.index != oldIndex
      elsif !mouse_blocked && defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT) && !mouse_hover.nil?
        pbSEPlay("EBDX/SE_Select2", 80)
        ret = cw.index rescue 0
        if yield ret
          @lastMove[idxBattler] = ret
          @fightWindow.hidePlay if @fightWindow && @fightWindow.respond_to?(:hidePlay)
          return
        end
        needFullRefresh = true
        needRefresh = true
      elsif Input.trigger?(Input::USE)
        pbSEPlay("EBDX/SE_Select2", 80)
        ret = cw.index rescue 0
        if yield ret
          @lastMove[idxBattler] = ret
          @fightWindow.hidePlay if @fightWindow && @fightWindow.respond_to?(:hidePlay)
          return
        end
        needFullRefresh = true
        needRefresh = true
      elsif (!mouse_blocked && defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)) || Input.trigger?(Input::BACK)
        pbSEPlay("EBDX/SE_Select3", 80)
        if yield -1
          @fightWindow.hidePlay if @fightWindow && @fightWindow.respond_to?(:hidePlay)
          return
        end
        needRefresh = true
      elsif Input.trigger?(Input::ACTION)
        if megaEvoPossible
          pbPlayDecisionSE
          if @fightWindow && @fightWindow.respond_to?(:megaButtonTrigger)
            @fightWindow.megaButtonTrigger
          end
          if yield -2
            @fightWindow.hidePlay if @fightWindow && @fightWindow.respond_to?(:hidePlay)
            return
          end
          needRefresh = true
        end
      elsif Input.trigger?(Input::SPECIAL)
        shiftMode = cw.respond_to?(:shiftMode) ? cw.shiftMode : 0
        if shiftMode > 0
          pbPlayDecisionSE
          if yield -3
            @fightWindow.hidePlay if @fightWindow && @fightWindow.respond_to?(:hidePlay)
            return
          end
          needRefresh = true
        end
      end
      MouseUI.require_mouse_reactivation if key_navigation
    end
  end

  alias mouse_ui_original_pbChooseTarget_EBDX pbChooseTarget
  def pbChooseTarget(idxBattler, target_data, visibleSprites = nil)
    texts = pbCreateTargetTexts(idxBattler, target_data)
    mode = (target_data.num_targets == 1) ? 0 : 1

    if @fightWindow && @fightWindow.respond_to?(:hidePlay)
      @fightWindow.hidePlay
    elsif @sprites["fightWindow"]
      @sprites["fightWindow"].visible = false
    end

    if @targetWindow && @targetWindow.is_a?(TargetWindowEBDX)
      @targetWindow.refresh(texts) if @targetWindow.respond_to?(:refresh)
      @targetWindow.index = pbFirstTarget(idxBattler, target_data)
      @targetWindow.showPlay if @targetWindow.respond_to?(:showPlay)
      cw = @targetWindow
    else
      pbShowWindow(TARGET_BOX)
      cw = @sprites["targetWindow"]
      cw.setDetails(texts, mode) if cw.respond_to?(:setDetails)
      cw.index = pbFirstTarget(idxBattler, target_data)
    end

    pbSelectBattler((mode == 0) ? cw.index : texts, 2)
    pbFadeInAndShow(@sprites, visibleSprites) if visibleSprites
    ret = -1

    loop do
      oldIndex = cw.index
      pbUpdate(cw)

      mouse_blocked = MouseUI.multiplayer_overlay_mouse_passthrough_blocked?
      mouse_pos = mouse_blocked ? nil : MouseUI.pointer_position
      mouse_hover = nil
      if mode == 0 && mouse_pos && MouseUI.mouse_hover_active?
        mouse_hover = pbMouseUIEBDXTargetHoverIndex(cw, texts, mouse_pos[0], mouse_pos[1])
        if !mouse_hover.nil? && mouse_hover != cw.index
          cw.index = mouse_hover
          pbPlayCursorSE
          pbSelectBattler(cw.index, 2)
        end
      end

      if mode == 0
        key_navigation = false
        if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
          key_navigation = true
          inc = ((cw.index % 2) == 0) ? -2 : 2
          inc *= -1 if Input.trigger?(Input::RIGHT)
          indexLength = @battle.sideSizes[cw.index % 2] * 2
          newIndex = cw.index
          loop do
            newIndex += inc
            break if newIndex < 0 || newIndex >= indexLength
            next if texts[newIndex].nil?
            cw.index = newIndex
            break
          end
        elsif (Input.trigger?(Input::UP) && (cw.index % 2) == 0) ||
              (Input.trigger?(Input::DOWN) && (cw.index % 2) == 1)
          key_navigation = true
          tryIndex = @battle.pbGetOpposingIndicesInOrder(cw.index)
          tryIndex.each do |idxBattlerTry|
            next if texts[idxBattlerTry].nil?
            cw.index = idxBattlerTry
            break
          end
        end
        if cw.index != oldIndex
          pbPlayCursorSE
          pbSelectBattler(cw.index, 2)
        end
        MouseUI.require_mouse_reactivation if key_navigation
      end

      left_click = !mouse_blocked && defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      right_click = !mouse_blocked && defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      if left_click
        if mode == 0 && !mouse_hover.nil?
          cw.index = mouse_hover
          ret = cw.index
          pbPlayDecisionSE
          break
        end
      end

      if Input.trigger?(Input::USE)
        ret = cw.index
        pbPlayDecisionSE
        break
      elsif right_click || Input.trigger?(Input::BACK)
        ret = -1
        pbPlayCancelSE
        break
      end
    end
    pbSelectBattler(-1)
    @targetWindow.hidePlay if @targetWindow && @targetWindow.respond_to?(:hidePlay)
    return ret
  end
end

class PokemonLoad_Scene
  MOUSE_LOAD_SCROLL_EDGE_PX   = 56
  MOUSE_LOAD_SCROLL_COOLDOWN  = 7

  def pbMouseUILoadScrollCooldown
    value = MOUSE_LOAD_SCROLL_COOLDOWN
    if $PokemonSystem && $PokemonSystem.respond_to?(:mouse_ui_load_scroll_cooldown)
      value = ($PokemonSystem.mouse_ui_load_scroll_cooldown || value).to_i
    end
    value = 0 if value < 0
    return value
  rescue
    return MOUSE_LOAD_SCROLL_COOLDOWN
  end

  def pbMouseUILoadHoverIndex
    return nil unless MouseUI.mouse_hover_active?
    pos = MouseUI.pointer_position
    return nil if !pos
    mx = pos[0]
    my = pos[1]
    return nil if !@sprites || !@sprites["cmdwindow"]
    list = @sprites["cmdwindow"].commands
    return nil if !list || list.length == 0

    panels = []
    0.upto(list.length - 1) do |i|
      panel = @sprites["panel#{i}"]
      next if !panel || panel.disposed? || !panel.visible
      panels << [i, panel]
    end
    return nil if panels.empty?

    # Prefer the actual visible panel hitboxes so the full Continue panel
    # remains clickable/selectable even when it spans several smaller rows.
    panels.reverse_each do |entry|
      return entry[0] if MouseUI.sprite_hit?(entry[1], mx, my)
    end

    return nil
  rescue
    nil
  end

  def pbMouseUILoadSetIndex(new_index)
    return if !@sprites || !@sprites["cmdwindow"]
    list = @sprites["cmdwindow"].commands
    return if !list || list.length == 0
    new_index = [[new_index, 0].max, list.length - 1].min
    old_index = @sprites["cmdwindow"].index
    return if old_index == new_index
    @sprites["cmdwindow"].index = new_index
    if @sprites["panel#{old_index}"]
      @sprites["panel#{old_index}"].selected = false
      @sprites["panel#{old_index}"].pbRefresh
    end
    if @sprites["panel#{new_index}"]
      @sprites["panel#{new_index}"].selected = true
      @sprites["panel#{new_index}"].pbRefresh
    end
    while @sprites["panel#{new_index}"] && @sprites["panel#{new_index}"].y > Graphics.height - 40 * 2
      for i in 0...list.length
        @sprites["panel#{i}"].y -= 24 * 2 if @sprites["panel#{i}"]
      end
      for i in 0...6
        break if !@sprites["party#{i}"]
        @sprites["party#{i}"].y -= 24 * 2
      end
      @sprites["player"].y -= 24 * 2 if @sprites["player"]
    end
    while @sprites["panel#{new_index}"] && @sprites["panel#{new_index}"].y < 16 * 2
      for i in 0...list.length
        @sprites["panel#{i}"].y += 24 * 2 if @sprites["panel#{i}"]
      end
      for i in 0...6
        break if !@sprites["party#{i}"]
        @sprites["party#{i}"].y += 24 * 2
      end
      @sprites["player"].y += 24 * 2 if @sprites["player"]
    end
  rescue
  end

  def pbMouseUILoadArrowClicked?(sprite_key)
    return false unless defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
    return false unless @sprites
    pos = MouseUI.pointer_position
    return false unless pos
    sprite = @sprites[sprite_key]
    return false if !sprite || sprite.disposed? || !sprite.visible
    return MouseUI.sprite_hit?(sprite, pos[0], pos[1]) if MouseUI.respond_to?(:sprite_hit?)
    width = sprite.framewidth rescue sprite.width
    height = sprite.frameheight rescue sprite.height
    return pos[0] >= sprite.x && pos[0] < sprite.x + width &&
           pos[1] >= sprite.y && pos[1] < sprite.y + height
  rescue
    false
  end

  def pbMouseUILoadSwitchSlotCommand(continue_idx)
    return nil if continue_idx.nil? || @sprites["cmdwindow"].index != continue_idx
    return -3 if pbMouseUILoadArrowClicked?("leftarrow") || Input.repeat?(Input::LEFT)
    return -2 if pbMouseUILoadArrowClicked?("rightarrow") || Input.repeat?(Input::RIGHT)
    return nil
  end

  alias mouse_ui_original_load_choose pbChoose
  def pbChoose(commands, continue_idx = nil)
    @sprites["cmdwindow"].commands = commands
    @mouse_ui_load_scroll_cooldown = 0
    if !continue_idx.nil?
      pbMouseUILoadSetIndex(continue_idx)
    end
    loop do
      Graphics.update
      Input.update
      wheel_direction = MouseUI.wheel_direction
      if wheel_direction != 0
        pos = MouseUI.pointer_position
        if pos
          pbMouseUILoadSetIndex(@sprites["cmdwindow"].index + wheel_direction)
          @mouse_ui_load_scroll_cooldown = pbMouseUILoadScrollCooldown
        end
      end
      hover_idx = pbMouseUILoadHoverIndex
      if !hover_idx.nil?
        pbMouseUILoadSetIndex(hover_idx)
        @mouse_ui_load_scroll_cooldown = 0
      else
        pos = MouseUI.pointer_position
        if pos && MouseUI.mouse_hover_active?
          my = pos[1]
          if @mouse_ui_load_scroll_cooldown > 0
            @mouse_ui_load_scroll_cooldown -= 1
          elsif my <= MOUSE_LOAD_SCROLL_EDGE_PX
            pbMouseUILoadSetIndex(@sprites["cmdwindow"].index - 1)
            @mouse_ui_load_scroll_cooldown = pbMouseUILoadScrollCooldown
          elsif my >= Graphics.height - MOUSE_LOAD_SCROLL_EDGE_PX
            pbMouseUILoadSetIndex(@sprites["cmdwindow"].index + 1)
            @mouse_ui_load_scroll_cooldown = pbMouseUILoadScrollCooldown
          end
        end
      end
      pbUpdate
      switch_slot_command = pbMouseUILoadSwitchSlotCommand(continue_idx)
      return switch_slot_command if !switch_slot_command.nil?
      left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      return @sprites["cmdwindow"].index if left_click || Input.trigger?(Input::USE)
    end
  end
end

class Window_PokemonOption
  def pbMouseUIOptionLocalXY(mx, my)
    sx, sy = pbMouseUIScreenPosition
    zoom_x = (self.zoom_x && self.zoom_x != 0) ? self.zoom_x : 1.0
    zoom_y = (self.zoom_y && self.zoom_y != 0) ? self.zoom_y : 1.0
    lx = ((mx - sx) / zoom_x).to_i - self.startX
    ly = ((my - sy) / zoom_y).to_i - self.startY
    return [lx, ly]
  end

  def pbMouseUISliderValueFor(index, lx)
    return nil if index < 0 || index >= @options.length
    return nil if !@options[index].is_a?(SliderOption)
    rect = itemRect(index)
    optionwidth = rect.width * 9 / 20
    max_text = sprintf(" %d", @options[index].optend)
    sliderlength = optionwidth - self.contents.text_size(max_text).width
    xpos = optionwidth + rect.x
    min_x = xpos
    max_x = xpos + [sliderlength - 8, 1].max
    clamped = [[lx, min_x].max, max_x].min
    ratio = (clamped - min_x).to_f / [max_x - min_x, 1].max
    min_val = @options[index].optstart
    max_val = @options[index].optend
    absolute = (min_val + (max_val - min_val) * ratio).round
    absolute = min_val if absolute < min_val
    absolute = max_val if absolute > max_val
    return absolute - min_val
  end

  def pbMouseUIEnumWordAt(index, lx, ly)
    return nil if index < 0 || index >= @options.length
    option = @options[index]
    return nil if !(option.is_a?(EnumOption) || option.is_a?(ButtonsOption))
    return nil if !option.respond_to?(:values) || !option.values || option.values.length <= 0
    rect = itemRect(index)
    return nil if !rect
    return nil if ly < rect.y || ly >= rect.y + rect.height

    optionwidth = rect.width * 9 / 20
    values = option.values
    return 0 if values.length == 1

    totalwidth = 0
    values.each { |value| totalwidth += self.contents.text_size(value).width }
    spacing = (optionwidth - totalwidth) / (values.length - 1)
    spacing = 0 if spacing < 0
    xpos = optionwidth + rect.x
    values.each_with_index do |value, i|
      text_w = self.contents.text_size(value).width
      return i if lx >= xpos && lx < xpos + text_w
      xpos += text_w + spacing
    end
    nil
  rescue
    nil
  end

  alias mouse_ui_original_option_update update
  def update
    mouse_ui_original_option_update
    return if !self.active || !self.visible
    pos = MouseUI.pointer_position
    return if !pos
    mx = pos[0]
    my = pos[1]

    if MouseUI.mouse_hover_active?
      hover = pbMouseUIIndexAtMouse(mx, my)
      self.index = hover if !hover.nil? && hover != self.index
    end

    lx, ly = pbMouseUIOptionLocalXY(mx, my)
    wheel_direction = MouseUI.wheel_direction
    if wheel_direction != 0
      idx = pbMouseUIIndexAtMouse(mx, my)
      idx = self.index if idx.nil?
      if idx >= 0 && idx < @options.length
        option = @options[idx]
        if option.is_a?(EnumOption) || option.is_a?(SliderOption) || option.is_a?(NumberOption)
          old_index = self.index
          old_value = self[idx]
          self.index = idx if idx != self.index
          new_value = (wheel_direction < 0) ? option.prev(self[idx]) : option.next(self[idx])
          if new_value != old_value || self.index != old_index
            self[idx] = new_value if new_value != old_value
            @selected_position = self[idx]
            @mustUpdateOptions = true
            @mustUpdateDescription = true
            pbPlayCursorSE
            MouseUI.require_mouse_reactivation
            return
          end
        end
      end
    end

    if defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      idx = self.index
      if idx >= 0 && idx < @options.length
        option = @options[idx]
        enum_choice = pbMouseUIEnumWordAt(idx, lx, ly)
        if !enum_choice.nil?
          if self[idx] != enum_choice
            self[idx] = enum_choice
            @selected_position = self[idx]
            @mustUpdateOptions = true
            @mustUpdateDescription = true
          end
          if option.is_a?(ButtonsOption)
            option.activate(enum_choice)
            @mustUpdateOptions = true
            @mustUpdateDescription = true
          end
          return
        end
      end
    end

    if defined?(Input::MOUSELEFT) && Input.press?(Input::MOUSELEFT)
      idx = self.index
      if idx >= 0 && idx < @options.length && @options[idx].is_a?(SliderOption)
        rect = itemRect(idx)
        optionwidth = rect.width * 9 / 20
        max_text = sprintf(" %d", @options[idx].optend)
        sliderlength = optionwidth - self.contents.text_size(max_text).width
        xpos = optionwidth + rect.x
        if lx >= xpos && lx <= xpos + sliderlength && ly >= rect.y - 10 && ly <= rect.y + rect.height + 10
          new_value = pbMouseUISliderValueFor(idx, lx)
          if !new_value.nil? && self[idx] != new_value
            self[idx] = new_value
            @selected_position = self[idx]
            @mustUpdateOptions = true
            @mustUpdateDescription = true
          end
        end
      end
    end
  end
end

class BagWindowEBDX
  def pbMouseUIHoverMainIndex
    return nil unless MouseUI.mouse_hover_active?
    pos = MouseUI.pointer_position
    return nil if !pos
    mx = pos[0]
    my = pos[1]
    0.upto(5) do |i|
      sprite = @sprites["pocket#{i}"]
      next if !sprite
      return i if MouseUI.sprite_hit?(sprite, mx, my)
    end
    nil
  rescue
    nil
  end

  def pbMouseUIHoverPocketTarget
    return nil unless MouseUI.mouse_hover_active?
    pos = MouseUI.pointer_position
    return nil if !pos
    mx = pos[0]
    my = pos[1]
    if MouseUI.sprite_hit?(@sprites["pocket5"], mx, my)
      return [:back, nil]
    end
    return nil if !@pocket
    @pocket.length.times do |i|
      spr = @items["#{i}"]
      next if !spr
      return [:item, i] if MouseUI.sprite_hit?(spr, mx, my)
    end
    nil
  rescue
    nil
  end

  alias mouse_ui_original_updateMain updateMain
  def updateMain
    hover_idx = pbMouseUIHoverMainIndex
    if !hover_idx.nil? && hover_idx != @index
      @index = hover_idx
    end
    mouse_left = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
    mouse_right = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
    if mouse_left && @index < 5
      self.confirm
      return
    elsif mouse_left && @index == 5
      self.finish
      return
    elsif mouse_right
      self.finish
      return
    end
    mouse_ui_original_updateMain
  end

  alias mouse_ui_original_updatePocket updatePocket
  def updatePocket
    hover = pbMouseUIHoverPocketTarget
    if hover
      if hover[0] == :back
        @back = true
      else
        @back = false
        @item = hover[1]
      end
    end
    mouse_left = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
    mouse_right = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
    if mouse_left
      if @back
        pbSEPlay("EBDX/SE_Select3")
        @selPocket = 0
        @page = -1
        @oldindex = -1
        @back = false
        @doubleback = true
        return
      else
        self.intoPocket
        return
      end
    elsif mouse_right
      pbSEPlay("EBDX/SE_Select3")
      @selPocket = 0
      @page = -1
      @oldindex = -1
      @back = false
      @doubleback = true
      return
    end
    mouse_ui_original_updatePocket
  end

  alias mouse_ui_original_useItem_qmark useItem?
  def useItem?
    Input.update
    item_data = (@ret) ? GameData::Item.try_get(@ret) : nil
    if !item_data
      @ret = nil
      self.refresh if respond_to?(:refresh)
      return false
    end
    bitmap = @sprites["confirm"].bitmap
    bitmap.clear
    bmp = pbBitmap(@path + @confirmImg)
    bitmap.blt(0, 0, bmp, bmp.rect)
    icon = pbBitmap(GameData::Item.icon_filename(item_data.id))
    bitmap.blt(20, 30, icon, icon.rect)
    drawTextEx(bitmap, 80, 12, 364, 3, item_data.description, @baseColor, Color.new(0, 0, 0, 32))
    @sprites["sel"].target(@sprites["confirm"])
    8.times do
      @sprites["confirm"].x += @viewport.width / 8
      @sprites["cancel"].x += @viewport.width / 8
      if @pocket
        for i in 0...@pocket.length
          @items["#{i}"].opacity -= 32
        end
      end
      for i in 0...4
        @sprites["pocket#{i}"].opacity -= 64 if @sprites["pocket#{i}"].opacity > 0
      end
      @sprites["pocket4"].y += 10 if @sprites["pocket4"].y < @sprites["pocket4"].ey + 80
      @sprites["pocket5"].y += 10 if @sprites["pocket5"].y < @sprites["pocket5"].ey + 80
      @sprites["name"].x -= @sprites["name"].width / 8
      @sprites["sel"].update
      @scene.animateScene
      @scene.pbGraphicsUpdate
    end
    @sprites["name"].x = -@sprites["name"].width
    index = 0
    oldindex = 0
    choice = (index == 0) ? "confirm" : "cancel"
    loop do
      @sprites[choice].src_rect.y += 1 if @sprites[choice].src_rect.y < 0

      pos = MouseUI.pointer_position
      if pos && MouseUI.mouse_hover_active?
        hover_choice = nil
        hover_choice = "confirm" if MouseUI.sprite_hit?(@sprites["confirm"], pos[0], pos[1])
        hover_choice = "cancel" if hover_choice.nil? && MouseUI.sprite_hit?(@sprites["cancel"], pos[0], pos[1])
        if hover_choice
          index = (hover_choice == "confirm") ? 0 : 1
          choice = hover_choice
        end
      end

      if Input.trigger?(Input::UP)
        index -= 1
        index = 1 if index < 0
        choice = (index == 0) ? "confirm" : "cancel"
      elsif Input.trigger?(Input::DOWN)
        index += 1
        index = 0 if index > 1
        choice = (index == 0) ? "confirm" : "cancel"
      end

      if index != oldindex
        oldindex = index
        pbSEPlay("EBDX/SE_Select1")
        @sprites[choice].src_rect.y -= 6
        @sprites["sel"].target(@sprites[choice])
      end

      left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      right_click = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      if left_click || Input.trigger?(Input::C)
        pbSEPlay("EBDX/SE_Select2")
        break
      elsif right_click || Input.trigger?(Input::B)
        @scene.pbPlayCancelSE()
        index = 1
        break
      end

      Input.update
      @sprites["sel"].update
      @scene.animateScene
      @scene.pbGraphicsUpdate
    end

    8.times do
      @sprites["confirm"].x -= @viewport.width / 8
      @sprites["cancel"].x -= @viewport.width / 8
      @sprites["pocket5"].y -= 10 if index > 0
      @sprites["sel"].update
      @scene.animateScene
      @scene.pbGraphicsUpdate
    end
    self.refresh
    if index > 0
      @ret = nil
      false
    else
      @index = 0 if @index == 4 && (@lastUsed == 0 || GameData::Item.get(@lastUsed).id_number == 0)
      true
    end
  end
end

class SpriteWindow_Selectable
  MOUSE_UI_HOVER_MIN_DELAY = 1
  MOUSE_UI_HOVER_MAX_DELAY = 12

  alias mouse_ui_original_update update

  def update
    mouse_ui_original_update
    pbMouseUIProcess
  end

  def pbMouseUIProcess
    return unless self.active
    return unless self.visible
    return if @ignore_input
    return if @item_max.nil? || @item_max <= 0

    pos = MouseUI.pointer_position
    return if !pos
    mx = pos[0]
    my = pos[1]

    wheel_direction = MouseUI.wheel_direction
    if wheel_direction != 0 && pbMouseUIPointInsideWindow?(mx, my)
      pbMouseUIApplyWheelScroll(wheel_direction)
      return
    end

    hover_active = MouseUI.mouse_hover_active?
    if !hover_active
      @mouse_ui_hover_target = nil
      @mouse_ui_hover_wait = 0
    end

    hovered_index = nil
    if hover_active
      hovered_index = pbMouseUIIndexAtMouse(mx, my)
      if !hovered_index.nil?
        if pbMouseUIUseSteppedHover?
          pbMouseUIApplySteppedHover(hovered_index)
        else
          old_index = self.index
          self.index = hovered_index
          pbPlayCursorSE() if old_index != self.index
        end
      else
        @mouse_ui_hover_target = nil
        @mouse_ui_hover_wait = 0
      end
    end

    if defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      clicked_index = pbMouseUIIndexAtMouse(mx, my)
      return if clicked_index.nil?
      old_index = self.index
      self.index = clicked_index
      pbPlayCursorSE() if old_index != self.index
      MouseUI.queue_confirm
    elsif defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      return unless pbMouseUIPointInsideWindow?(mx, my)
      MouseUI.queue_cancel
    end
  end

  def pbMouseUIApplyWheelScroll(direction)
    return if direction == 0

    old_index = self.index || 0
    old_index = 0 if old_index < 0
    step = pbMouseUIWheelStep
    new_index = old_index + (direction * step)
    new_index = 0 if new_index < 0
    new_index = @item_max - 1 if new_index >= @item_max
    return if new_index == old_index

    self.index = new_index
    @mouse_ui_hover_target = nil
    @mouse_ui_hover_wait = 0
    MouseUI.require_mouse_reactivation
    pbPlayCursorSE()
  rescue
    @mouse_ui_hover_target = nil
    @mouse_ui_hover_wait = 0
  end

  def pbMouseUIWheelStep
    cols = 1
    cols = self.columns if self.respond_to?(:columns)
    cols = cols.to_i
    cols = 1 if cols <= 0
    return cols
  rescue
    return 1
  end

  def pbMouseUIUseSteppedHover?
    return false if defined?(PokemonPauseMenu_Scene) && $scene && $scene.is_a?(PokemonPauseMenu_Scene)
    return false if !self.respond_to?(:page_item_max)
    return false if self.page_item_max.nil?
    return false if self.page_item_max <= 0
    return (@item_max > self.page_item_max)
  rescue
    return false
  end

  def pbMouseUIApplySteppedHover(target_index)
    return if target_index == self.index
    if @mouse_ui_hover_target != target_index
      @mouse_ui_hover_target = target_index
      @mouse_ui_hover_wait = 0
    end
    @mouse_ui_hover_wait ||= 0
    @mouse_ui_hover_wait += 1
    required_delay = pbMouseUIHoverStepDelay(target_index)
    return if @mouse_ui_hover_wait < required_delay

    old_index = self.index
    step = (target_index > self.index) ? 1 : -1
    self.index = self.index + step
    pbPlayCursorSE() if old_index != self.index
    @mouse_ui_hover_wait = 0
  rescue
    @mouse_ui_hover_target = nil
    @mouse_ui_hover_wait = 0
  end

  def pbMouseUIHoverStepDelay(target_index)
    distance = (target_index - self.index).abs
    base = if distance <= 1
      MOUSE_UI_HOVER_MAX_DELAY
    elsif distance == 2
      6
    elsif distance == 3
      3
    elsif distance == 4
      2
    else
      MOUSE_UI_HOVER_MIN_DELAY
    end
    throttle_offsets = [-2, -1, 0, 2, 4]
    level = 2
    if $PokemonSystem && $PokemonSystem.respond_to?(:mouse_ui_hover_throttle_level)
      level = ($PokemonSystem.mouse_ui_hover_throttle_level || level).to_i
    end
    level = [[level, 0].max, throttle_offsets.length - 1].min
    adjusted = base + throttle_offsets[level]
    adjusted = 0 if adjusted < 0
    return adjusted
  rescue
    return 4
  end

  def pbMouseUIIndexAtMouse(mx, my)
    return nil unless pbMouseUIPointInsideWindow?(mx, my)

    sx, sy = pbMouseUIScreenPosition
    zoom_x = (self.zoom_x && self.zoom_x != 0) ? self.zoom_x : 1.0
    zoom_y = (self.zoom_y && self.zoom_y != 0) ? self.zoom_y : 1.0

    local_x = ((mx - sx) / zoom_x).to_i - self.startX
    local_y = ((my - sy) / zoom_y).to_i - self.startY
    return nil if local_x < 0 || local_y < 0

    visible_first = [self.top_item, 0].max
    visible_last = [visible_first + self.page_item_max - 1, @item_max - 1].min
    return nil if visible_last < visible_first

    i = visible_first
    while i <= visible_last
      rect = itemRect(i)
      if rect && rect.width > 0 && rect.height > 0
        if local_x >= rect.x && local_x < rect.x + rect.width &&
           local_y >= rect.y && local_y < rect.y + rect.height
          return i
        end
      end
      i += 1
    end
    return nil
  end

  def pbMouseUIPointInsideWindow?(mx, my)
    sx, sy = pbMouseUIScreenPosition
    width = self.width
    height = self.height
    return false if !width || !height || width <= 0 || height <= 0
    return (mx >= sx && mx < sx + width && my >= sy && my < sy + height)
  end

  def pbMouseUIScreenPosition
    sx = self.x
    sy = self.y
    if self.viewport
      sx += self.viewport.rect.x if self.viewport.respond_to?(:rect) && self.viewport.rect
      sy += self.viewport.rect.y if self.viewport.respond_to?(:rect) && self.viewport.rect
      sx -= self.viewport.ox if self.viewport.respond_to?(:ox)
      sy -= self.viewport.oy if self.viewport.respond_to?(:oy)
    end
    return [sx, sy]
  rescue
    return [self.x, self.y]
  end
end

class BattleMenuBase
  alias mouse_ui_original_update update

  def update
    mouse_ui_original_update
    pbMouseUIBattleMenuProcess
  end

  def pbMouseUIBattleMenuProcess
    return unless @visible
    return if MouseUI.multiplayer_overlay_mouse_passthrough_blocked?
    pos = MouseUI.pointer_position
    return if !pos
    mx = pos[0]
    my = pos[1]

    hovered_index = nil
    hovered_index = pbMouseUIBattleHoveredButton(mx, my) if MouseUI.mouse_hover_active?
    self.index = hovered_index if !hovered_index.nil? && hovered_index != self.index

    if defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      if !hovered_index.nil?
        self.index = hovered_index
        MouseUI.queue_confirm
      elsif pbMouseUIBattleSpriteVisibleHit?("megaButton", mx, my)
        MouseUI.queue_action
      elsif pbMouseUIBattleSpriteVisibleHit?("shiftButton", mx, my)
        MouseUI.queue_special
      end
    elsif defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      if !hovered_index.nil? || pbMouseUIBattleSpriteVisibleHit?("megaButton", mx, my) || pbMouseUIBattleSpriteVisibleHit?("shiftButton", mx, my)
        MouseUI.queue_cancel
      end
    end
  end

  def pbMouseUIBattleHoveredButton(mx, my)
    return nil if !defined?(@buttons) || !@buttons || @buttons.empty?
    @buttons.each_with_index do |button, i|
      next if !button || button.disposed?
      next if !pbMouseUIBattleButtonVisible?(i, button)
      return i if pbMouseUIBattleSpriteHit?(button, mx, my)
    end
    return nil
  end

  def pbMouseUIBattleButtonVisible?(index, button)
    return false if !button.visible
    return true if !defined?(@visibility) || !@visibility
    return true if !@visibility.is_a?(Hash)
    key = "button_#{index}"
    return !!@visibility[key] if @visibility.key?(key)
    return true
  end

  def pbMouseUIBattleSpriteVisibleHit?(key, mx, my)
    return false if !defined?(@sprites) || !@sprites
    sprite = @sprites[key]
    return false if !sprite || sprite.disposed?
    return false if defined?(@visibility) && @visibility.is_a?(Hash) && @visibility.key?(key) && !@visibility[key]
    return pbMouseUIBattleSpriteHit?(sprite, mx, my)
  end

  def pbMouseUIBattleSpriteHit?(sprite, mx, my)
    return false if !sprite || sprite.disposed?
    return false if !sprite.visible
    width = (sprite.src_rect && sprite.src_rect.width > 0) ? sprite.src_rect.width : (sprite.bitmap ? sprite.bitmap.width : 0)
    height = (sprite.src_rect && sprite.src_rect.height > 0) ? sprite.src_rect.height : (sprite.bitmap ? sprite.bitmap.height : 0)
    return false if width <= 0 || height <= 0
    return mx >= sprite.x && mx < sprite.x + width && my >= sprite.y && my < sprite.y + height
  rescue
    return false
  end
end

class PokemonStorageScene
  def pbMouseUIStorageBoxArrowClick(mx, my)
    box = @sprites["box"] rescue nil
    return nil if !box || box.disposed? || !box.visible
    bw = (box.bitmap && !box.bitmap.disposed?) ? box.bitmap.width : 0
    return nil if bw <= 0
    bx = box.x
    by = box.y
    top = by
    bottom = by + 48
    return nil if my < top || my >= bottom
    return -4 if mx >= bx && mx < bx + 44
    return -5 if mx >= bx + bw - 44 && mx < bx + bw
    return nil
  rescue
    return nil
  end

  def pbMouseUIStorageSelectionAnchor(selection)
    marker = Struct.new(:x, :y, :angle, :mirror, :ox, :oy).new(0, 0, 0, false, 0, 0)
    pbSetArrow(marker, selection)
    if selection >= 0
      return [marker.x + 24, marker.y + 24]
    elsif selection == -2 || selection == -3
      return [marker.x + 40, marker.y + 24]
    end
    return [marker.x + 20, marker.y + 12]
  rescue
    return nil
  end

  def pbMouseUIStoragePartyAnchor(selection)
    marker = Struct.new(:x, :y, :angle, :mirror, :ox, :oy).new(0, 0, 0, false, 0, 0)
    pbPartySetArrow(marker, selection)
    if selection >= 0 && selection < Settings::MAX_PARTY_SIZE
      return [marker.x + 36, marker.y + 32]
    end
    return [marker.x + 28, marker.y + 20]
  rescue
    return nil
  end

  def pbMouseUIStorageSelectFromMouse(mx, my, include_party: true, include_box_arrows: false)
    if include_box_arrows
      arrow_click = pbMouseUIStorageBoxArrowClick(mx, my)
      return arrow_click if !arrow_click.nil?
    end

    best_selection = nil
    best_distance = nil

    candidates = []
    0.upto(PokemonBox::BOX_SIZE - 1) { |i| candidates << i }
    candidates << -1
    candidates << -2 if include_party
    candidates << -3
    candidates << -4
    candidates << -5

    candidates.each do |sel|
      pt = pbMouseUIStorageSelectionAnchor(sel)
      next if !pt
      dx = mx - pt[0]
      dy = my - pt[1]
      distance = (dx * dx) + (dy * dy)
      next if distance > (34 * 34)
      if best_distance.nil? || distance < best_distance
        best_distance = distance
        best_selection = sel
      end
    end

    return best_selection
  end

  def pbMouseUIStoragePartySelectFromMouse(mx, my, depositing)
    max_index = @screen.multiSelectRange ? Settings::MAX_PARTY_SIZE - 1 : Settings::MAX_PARTY_SIZE
    best_selection = nil
    best_distance = nil
    0.upto(max_index) do |sel|
      pt = pbMouseUIStoragePartyAnchor(sel)
      next if !pt
      dx = mx - pt[0]
      dy = my - pt[1]
      distance = (dx * dx) + (dy * dy)
      next if distance > (38 * 38)
      if best_distance.nil? || distance < best_distance
        best_distance = distance
        best_selection = sel
      end
    end
    return -1 if !depositing && best_selection == Settings::MAX_PARTY_SIZE
    return best_selection
  end

  alias mouse_ui_original_pbSelectBoxInternal pbSelectBoxInternal
  def pbSelectBoxInternal(_party)
    selection = @selection
    pbSetArrow(@sprites["arrow"], selection)
    pbUpdateOverlay(selection)
    pbSetMosaic(selection)
    loop do
      Graphics.update
      Input.update

      mouse_pos = MouseUI.pointer_position
      if mouse_pos && MouseUI.mouse_hover_active?
        mx = mouse_pos[0]
        my = mouse_pos[1]
        hovered = pbMouseUIStorageSelectFromMouse(mx, my, include_party: true, include_box_arrows: false)
        if !hovered.nil? && hovered != selection
          pbPlayCursorSE
          selection = hovered
          pbSetArrow(@sprites["arrow"], selection)
          pbUpdateOverlay(selection)
          pbSetMosaic(selection)
          pbUpdateSelectionRect(@storage.currentBox, selection) if @screen.multiSelectRange
        end
      end

      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        pbPlayCursorSE
        selection = pbChangeSelection(key, selection)
        pbSetArrow(@sprites["arrow"], selection)
        if selection == -4
          nextbox = (@storage.currentBox + @storage.maxBoxes - 1) % @storage.maxBoxes
          pbSwitchBoxToLeft(nextbox)
          @storage.currentBox = nextbox
        elsif selection == -5
          nextbox = (@storage.currentBox + 1) % @storage.maxBoxes
          pbSwitchBoxToRight(nextbox)
          @storage.currentBox = nextbox
        end
        selection = -1 if selection == -4 || selection == -5
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
        if @screen.multiSelectRange
          pbUpdateSelectionRect(@storage.currentBox, selection)
        end
      end
      self.update

      if defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT) && mouse_pos
        click_sel = pbMouseUIStorageSelectFromMouse(mouse_pos[0], mouse_pos[1], include_party: true, include_box_arrows: true)
        if !click_sel.nil?
          selection = click_sel
          pbSetArrow(@sprites["arrow"], selection)
          pbUpdateOverlay(selection)
          pbSetMosaic(selection)
          if selection == -4
            nextbox = (@storage.currentBox + @storage.maxBoxes - 1) % @storage.maxBoxes
            pbSwitchBoxToLeft(nextbox)
            @storage.currentBox = nextbox
            selection = -1
            pbUpdateOverlay(selection)
            pbSetMosaic(selection)
          elsif selection == -5
            nextbox = (@storage.currentBox + 1) % @storage.maxBoxes
            pbSwitchBoxToRight(nextbox)
            @storage.currentBox = nextbox
            selection = -1
            pbUpdateOverlay(selection)
            pbSetMosaic(selection)
          else
            @selection = selection
            if selection >= 0
              return [@storage.currentBox, selection]
            elsif selection == -1
              return [-4, -1]
            elsif selection == -2
              return [-2, -1]
            elsif selection == -3
              return [-3, -1]
            end
          end
        end
      end

      if defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
        @selection = selection
        return nil
      elsif Input.trigger?(Input::JUMPUP)
        pbPlayCursorSE
        nextbox = (@storage.currentBox + @storage.maxBoxes - 1) % @storage.maxBoxes
        pbSwitchBoxToLeft(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Input.trigger?(Input::JUMPDOWN)
        pbPlayCursorSE
        nextbox = (@storage.currentBox + 1) % @storage.maxBoxes
        pbSwitchBoxToRight(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Input.trigger?(Input::SPECIAL)
        if selection != -1
          pbPlayCursorSE
          selection = -1
          pbSetArrow(@sprites["arrow"], selection)
          pbUpdateOverlay(selection)
          pbSetMosaic(selection)
        end
      elsif Input.trigger?(Input::ACTION) && @command == 0
        pbPlayDecisionSE
        pbNextCursorMode
      elsif Input.trigger?(Input::BACK)
        @selection = selection
        return nil
      elsif Input.trigger?(Input::USE)
        @selection = selection
        if selection >= 0
          return [@storage.currentBox, selection]
        elsif selection == -1
          return [-4, -1]
        elsif selection == -2
          return [-2, -1]
        elsif selection == -3
          return [-3, -1]
        end
      end
    end
  end

  alias mouse_ui_original_pbSelectPartyInternal pbSelectPartyInternal
  def pbSelectPartyInternal(party, depositing)
    selection = @selection
    pbPartySetArrow(@sprites["arrow"], selection)
    pbUpdateOverlay(selection, party)
    pbSetMosaic(selection)
    lastsel = 1
    loop do
      Graphics.update
      Input.update

      mouse_pos = MouseUI.pointer_position
      if mouse_pos && MouseUI.mouse_hover_active?
        hovered = pbMouseUIStoragePartySelectFromMouse(mouse_pos[0], mouse_pos[1], depositing)
        if !hovered.nil? && hovered != selection
          pbPlayCursorSE
          selection = hovered
          pbPartySetArrow(@sprites["arrow"], selection)
          lastsel = selection if selection > 0
          pbUpdateOverlay(selection, party)
          pbSetMosaic(selection)
          pbUpdateSelectionRect(-1, selection) if @screen.multiSelectRange
        end
      end

      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        pbPlayCursorSE
        newselection = pbPartyChangeSelection(key, selection)
        if newselection == -1
          return -1 if !depositing
        elsif newselection == -2
          selection = lastsel
        else
          selection = newselection
        end
        pbPartySetArrow(@sprites["arrow"], selection)
        lastsel = selection if selection > 0
        pbUpdateOverlay(selection, party)
        pbSetMosaic(selection)
        if @screen.multiSelectRange
          pbUpdateSelectionRect(-1, selection)
        end
      end
      self.update

      if defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT) && mouse_pos
        click_sel = pbMouseUIStoragePartySelectFromMouse(mouse_pos[0], mouse_pos[1], depositing)
        if !click_sel.nil?
          selection = click_sel
          if selection >= 0 && selection < Settings::MAX_PARTY_SIZE
            @selection = selection
            return selection
          elsif selection == Settings::MAX_PARTY_SIZE
            @selection = selection
            return (depositing) ? -3 : -1
          end
        end
      end

      if defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
        @selection = selection
        return -1
      elsif Input.trigger?(Input::ACTION) && @command == 0
        pbPlayDecisionSE
        pbNextCursorMode
      elsif Input.trigger?(Input::BACK)
        @selection = selection
        return -1
      elsif Input.trigger?(Input::USE)
        if selection >= 0 && selection < Settings::MAX_PARTY_SIZE
          @selection = selection
          return selection
        elsif selection == Settings::MAX_PARTY_SIZE
          @selection = selection
          return (depositing) ? -3 : -1
        end
      end
    end
  end
end

class DoublePreviewScreen
  def pbMouseUIPreviewSelectionAt(mx, my)
    return 0 if pbMouseUIPreviewWindowHit?(@picture1, mx, my)
    return 1 if pbMouseUIPreviewWindowHit?(@picture2, mx, my)
    return -1 if @sprites && @sprites["cancel"] && MouseUI.sprite_hit?(@sprites["cancel"], mx, my)
    return nil
  end

  def pbMouseUIPreviewWindowHit?(window, mx, my)
    return false if !window || window.disposed?
    return false if window.respond_to?(:visible) && !window.visible
    sx, sy = MouseUI.window_screen_position(window)
    return mx >= sx && mx < sx + window.width && my >= sy && my < sy + window.height
  rescue
    return false
  end

  def startSelection
    loop do
      Graphics.update
      Input.update

      pos = MouseUI.pointer_position
      if pos && MouseUI.mouse_hover_active?
        hover_selection = pbMouseUIPreviewSelectionAt(pos[0], pos[1])
        if !hover_selection.nil? && hover_selection != @selected
          @selected = hover_selection
          updateSelectionGraphics
          pbPlayCursorSE
        end
      end

      left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      right_click = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      if left_click
        if pos
          click_selection = pbMouseUIPreviewSelectionAt(pos[0], pos[1])
          if !click_selection.nil?
            @selected = click_selection
            updateSelectionGraphics
            pbPlayDecisionSE
            return @selected
          end
        end
      elsif right_click || Input.trigger?(Input::BACK)
        pbPlayCancelSE
        return -1
      else
        updateSelection
        if Input.trigger?(Input::USE)
          pbPlayDecisionSE
          return @selected
        end
      end
    end
  end
end

if defined?(GenOneStyle)
  class GenOneStyle
    alias mouse_ui_original_genone_update_selector_position update_selector_position unless method_defined?(:mouse_ui_original_genone_update_selector_position)
    alias mouse_ui_original_genone_getFusedIdIntro getFusedIdIntro unless method_defined?(:mouse_ui_original_genone_getFusedIdIntro)

    def update_selector_position
      pos = MouseUI.pointer_position
      mouse_over = false
      if pos && @sprites
        mx = pos[0]
        my = pos[1]
        if @sprites["poke"] && MouseUI.sprite_hit?(@sprites["poke"], mx, my)
          @selector_pos = 0
          @mouse_ui_intro_choice = :right
          @sprites["selector"].opacity = 100 if @sprites["selector"]
          mouse_over = true
        elsif @sprites["2poke"] && MouseUI.sprite_hit?(@sprites["2poke"], mx, my)
          @selector_pos = 1
          @mouse_ui_intro_choice = :left
          @sprites["selector"].opacity = 100 if @sprites["selector"]
          mouse_over = true
        end
      end

      mouse_ui_original_genone_update_selector_position
      if mouse_over
        @sprites["selector"].opacity = 100 if @sprites && @sprites["selector"]
      end
    rescue
      mouse_ui_original_genone_update_selector_position
    end

    def getFusedIdIntro(randpoke1, randpoke2)
      if @mouse_ui_intro_choice
        return (@mouse_ui_intro_choice == :right) ? getSpeciesIdForFusion(randpoke2, randpoke1) : getSpeciesIdForFusion(randpoke1, randpoke2)
      end
      mouse_ui_original_genone_getFusedIdIntro(randpoke1, randpoke2)
    end
  end
end

module MouseUI
  module_function

  def window_screen_position(window)
    sx = window.x
    sy = window.y
    if window.respond_to?(:viewport) && window.viewport
      vp = window.viewport
      sx += vp.rect.x if vp.respond_to?(:rect) && vp.rect
      sy += vp.rect.y if vp.respond_to?(:rect) && vp.rect
      sx -= vp.ox if vp.respond_to?(:ox)
      sy -= vp.oy if vp.respond_to?(:oy)
    end
    [sx, sy]
  rescue
    [window.x, window.y]
  end

  def window_hover_index(window, mx, my)
    return nil unless mouse_hover_active?
    return nil if !window || (window.respond_to?(:disposed?) && window.disposed?)
    return nil if window.respond_to?(:visible) && !window.visible
    sx, sy = window_screen_position(window)
    return nil if mx < sx || my < sy || mx >= sx + window.width || my >= sy + window.height

    count = nil
    count = window.itemCount if count.nil? && window.respond_to?(:itemCount)
    count = window.item_max if count.nil? && window.respond_to?(:item_max)
    count = window.commands.length if count.nil? && window.respond_to?(:commands) && window.commands
    count = window.instance_variable_get(:@item_max) if count.nil?
    return nil if !count || count <= 0

    rel_x = mx - sx
    rel_y = my - sy
    0.upto(count - 1) do |i|
      next if !window.respond_to?(:itemRect)
      rect = window.itemRect(i)
      next if !rect
      next if rect.width <= 0 || rect.height <= 0
      return i if rel_x >= rect.x && rel_x < rect.x + rect.width && rel_y >= rect.y && rel_y < rect.y + rect.height
    end
    nil
  rescue
    nil
  end

  def window_point_inside?(window, mx, my)
    return false if !window || (window.respond_to?(:disposed?) && window.disposed?)
    return false if window.respond_to?(:visible) && !window.visible
    sx, sy = window_screen_position(window)
    return mx >= sx && mx < sx + window.width && my >= sy && my < sy + window.height
  rescue
    false
  end
end

module UIHelper
  class << self
    alias mouse_ui_original_uihelper_choose_number pbChooseNumber unless method_defined?(:mouse_ui_original_uihelper_choose_number)
  end

  def self.pbChooseNumber(helpwindow, helptext, maximum, initnum = 1)
    oldvisible = helpwindow.visible
    helpwindow.visible = true
    helpwindow.text = helptext
    helpwindow.letterbyletter = false
    curnumber = initnum
    ret = 0
    numwindow = Window_UnformattedTextPokemon.new("x000")
    numwindow.viewport = helpwindow.viewport
    numwindow.letterbyletter = false
    numwindow.text = _ISPRINTF("x{1:03d}", curnumber)
    numwindow.resizeToFit(numwindow.text, Graphics.width)
    pbBottomRight(numwindow)
    helpwindow.resizeHeightToFit(helpwindow.text, Graphics.width - numwindow.width)
    pbBottomLeft(helpwindow)
    loop do
      Graphics.update
      Input.update
      numwindow.update
      helpwindow.update

      left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      right_click = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      if left_click || right_click
        pos = MouseUI.pointer_position
        if pos && MouseUI.window_point_inside?(numwindow, pos[0], pos[1])
          sx, sy = MouseUI.window_screen_position(numwindow)
          lx = pos[0] - sx
          step = (lx < (numwindow.width * 2) / 3) ? 1 : 10
          if left_click
            curnumber += step
          else
            curnumber -= step
          end
          curnumber = 1 if curnumber < 1
          curnumber = maximum if curnumber > maximum
          numwindow.text = _ISPRINTF("x{1:03d}", curnumber)
          pbPlayCursorSE
          next
        end
        # Outside the number box, fall through to normal confirm/cancel behavior.
      end

      wheel_direction = MouseUI.wheel_direction
      if wheel_direction != 0
        pos = MouseUI.pointer_position
        if pos && MouseUI.window_point_inside?(numwindow, pos[0], pos[1])
          sx, sy = MouseUI.window_screen_position(numwindow)
          lx = pos[0] - sx
          step = (lx < (numwindow.width * 2) / 3) ? 1 : 10
          curnumber -= step * wheel_direction
          curnumber = 1 if curnumber < 1
          curnumber = maximum if curnumber > maximum
          numwindow.text = _ISPRINTF("x{1:03d}", curnumber)
          pbPlayCursorSE
          next
        end
      end

      if Input.trigger?(Input::BACK)
        ret = 0
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::USE)
        ret = curnumber
        pbPlayDecisionSE
        break
      elsif Input.repeat?(Input::UP)
        curnumber += 1
        curnumber = 1 if curnumber > maximum
        numwindow.text = _ISPRINTF("x{1:03d}", curnumber)
        pbPlayCursorSE
      elsif Input.repeat?(Input::DOWN)
        curnumber -= 1
        curnumber = maximum if curnumber < 1
        numwindow.text = _ISPRINTF("x{1:03d}", curnumber)
        pbPlayCursorSE
      elsif Input.repeat?(Input::LEFT)
        curnumber -= 10
        curnumber = 1 if curnumber < 1
        numwindow.text = _ISPRINTF("x{1:03d}", curnumber)
        pbPlayCursorSE
      elsif Input.repeat?(Input::RIGHT)
        curnumber += 10
        curnumber = maximum if curnumber > maximum
        numwindow.text = _ISPRINTF("x{1:03d}", curnumber)
        pbPlayCursorSE
      end
    end
    numwindow.dispose
    helpwindow.visible = oldvisible
    return ret
  end
end

class MoveRelearner_Scene
  alias mouse_ui_original_move_relearner_choose pbChooseMove unless method_defined?(:mouse_ui_original_move_relearner_choose)

  def pbChooseMove
    oldcmd = -1
    pbActivateWindow(@sprites, "commands") {
      loop do
        oldcmd = @sprites["commands"].index
        Graphics.update
        Input.update
        pbUpdate

        pos = MouseUI.pointer_position
        if pos
          hover_idx = MouseUI.window_hover_index(@sprites["commands"], pos[0], pos[1])
          if !hover_idx.nil? && hover_idx != @sprites["commands"].index
            @sprites["commands"].index = hover_idx
          end
        end

        if @sprites["commands"].index != oldcmd
          @sprites["background"].x = 0
          @sprites["background"].y = 78 + (@sprites["commands"].index - @sprites["commands"].top_item) * 64
          pbDrawMoveList
        end

        left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
        right_click = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
        if left_click
          if pos
            click_idx = MouseUI.window_hover_index(@sprites["commands"], pos[0], pos[1])
            if !click_idx.nil? && @pokemon
              @sprites["commands"].index = click_idx
              return @moves[@sprites["commands"].index]
            else
              next
            end
          else
            next
          end
        end

        if right_click || Input.trigger?(Input::BACK)
          return nil
        elsif Input.trigger?(Input::USE) && @pokemon
          return @moves[@sprites["commands"].index]
        end
      end
    }
  end
end

class PokemonSummary_Scene
  def pbMouseUISummaryTabAt(mx, my)
    return nil if @pokemon && @pokemon.egg?
    base_x = 242
    base_y = 2
    tab_w = 52
    tab_h = 44
    gap = 8
    0.upto(NB_PAGES - 1) do |i|
      x = base_x + i * (tab_w + gap)
      next if mx < x || mx >= x + tab_w || my < base_y || my >= base_y + tab_h
      page = i + 1
      next if page == 5 && (!$Trainer || !$Trainer.has_pokedex)
      return page
    end
    nil
  rescue
    nil
  end

  def pbMouseUIForgetMoveIndexAt(mx, my, maxmove, has_new_move)
    return nil if mx < 240 || mx >= Graphics.width
    0.upto(maxmove) do |i|
      row_y = 92 + (i * 64)
      row_y -= 76 if has_new_move
      row_y += 20 if has_new_move && i == Pokemon::MAX_MOVES
      return i if my >= row_y && my < row_y + 64
    end
    nil
  rescue
    nil
  end

  alias mouse_ui_original_summary_choose_forget pbChooseMoveToForget unless method_defined?(:mouse_ui_original_summary_choose_forget)
  def pbChooseMoveToForget(move_to_learn)
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    selmove = 0
    maxmove = (new_move) ? Pokemon::MAX_MOVES : Pokemon::MAX_MOVES - 1
    loop do
      Graphics.update
      Input.update
      pbUpdate

      pos = MouseUI.pointer_position
      if pos && MouseUI.mouse_hover_active?
        hover_idx = pbMouseUIForgetMoveIndexAt(pos[0], pos[1], maxmove, !new_move.nil?)
        if !hover_idx.nil? && hover_idx != selmove
          selmove = hover_idx
          @sprites["movesel"].index = selmove
          selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
          drawSelectedMove(new_move, selected_move)
        end
      end

      left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
      right_click = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
      if right_click || Input.trigger?(Input::BACK)
        selmove = Pokemon::MAX_MOVES
        pbPlayCloseMenuSE if new_move
        break
      elsif left_click
        if pos
          click_idx = pbMouseUIForgetMoveIndexAt(pos[0], pos[1], maxmove, !new_move.nil?)
          if !click_idx.nil?
            selmove = click_idx
            @sprites["movesel"].index = selmove
            selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
            drawSelectedMove(new_move, selected_move)
            pbPlayDecisionSE
            break
          end
        end
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove < 0
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = @pokemon.numMoves - 1
        end
        @sprites["movesel"].index = selmove
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove > maxmove
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = (new_move) ? maxmove : 0
        end
        @sprites["movesel"].index = selmove
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      end
    end
    return (selmove == Pokemon::MAX_MOVES) ? -1 : selmove
  end

  alias mouse_ui_original_summary_scene pbScene unless method_defined?(:mouse_ui_original_summary_scene)
  def pbScene
    @pokemon.play_cry
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false

      pos = MouseUI.pointer_position
      if pos && MouseUI.mouse_hover_active?
        hovered_page = pbMouseUISummaryTabAt(pos[0], pos[1])
        if !hovered_page.nil? && hovered_page != @page
          @page = hovered_page
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      end

      if Input.trigger?(Input::ACTION)
        pbSEStop
        @pokemon.play_cry
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        if @page == 4
          pbPlayDecisionSE
          pbMoveSelection
          dorefresh = true
        elsif @page == 5
          @page -= 1
          pbPlayDecisionSE
        elsif !@inbattle
          pbPlayDecisionSE
          dorefresh = pbOptions
        end
      elsif Input.trigger?(Input::UP) && @partyindex > 0
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN) && @partyindex < @party.length - 1
        oldindex = @partyindex
        pbGoToNext
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
        oldpage = @page
        @page -= 1
        @page = 1 if @page < 1
        @page = 5 if @page > 5
        if @page != oldpage
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
        if @page == 4 && !$Trainer.has_pokedex
          pbSEPlay("GUI sel buzzer")
        else
          oldpage = @page
          @page += 1
          @page = 1 if @page < 1
          @page = 5 if @page > 5
          if @page != oldpage
            pbSEPlay("GUI summary change page")
            @ribbonOffset = 0
            dorefresh = true
          end
        end
      end

      drawPage(@page) if dorefresh
    end
    return @partyindex
  end
end

if defined?(PokemonTutorNet_Scene)
  class PokemonTutorNet_Scene
    def pbMouseUITutorHoverIndex
      return nil unless MouseUI.mouse_hover_active?
      pos = MouseUI.pointer_position
      return nil if !pos
      mx = pos[0]
      my = pos[1]
      best = nil
      best_dist = nil
      0.upto(Settings::MAX_PARTY_SIZE - 1) do |i|
        next if !@party || !@party[i]
        x = (i % 2 == 0) ? 440 : 500
        y = 130 + (i / 2) * 88
        dx = mx - x
        dy = my - y
        dist = dx * dx + dy * dy
        next if dist > (44 * 44)
        if best_dist.nil? || dist < best_dist
          best_dist = dist
          best = i
        end
      end
      return best
    rescue
      return nil
    end

    alias mouse_ui_original_tutornet_choose_pokemon pbChoosePokemon unless method_defined?(:mouse_ui_original_tutornet_choose_pokemon)
    def pbChoosePokemon
      @sprites["commands"].ignore_input = true
      @activecmd = @last_mon_index
      0.upto(Settings::MAX_PARTY_SIZE - 1) do |i|
        @sprites["pokemon#{i}"].selected = (i == @activecmd)
      end
      loop do
        Graphics.update
        Input.update
        pbUpdate
        oldsel = @activecmd

        if MouseUI.mouse_hover_active?
          hover_idx = pbMouseUITutorHoverIndex
          @activecmd = hover_idx if !hover_idx.nil?
        end

        key = -1
        key = Input::DOWN if Input.repeat?(Input::DOWN) && @party.length > 2
        key = Input::RIGHT if Input.repeat?(Input::RIGHT)
        key = Input::LEFT if Input.repeat?(Input::LEFT)
        key = Input::UP if Input.repeat?(Input::UP) && @party.length > 2
        if key >= 0 && @party.length > 1
          @activecmd = pbChangeSelection(key, @activecmd)
        end

        numsprites = Settings::MAX_PARTY_SIZE
        if @activecmd != oldsel
          pbPlayCursorSE
          0.upto(numsprites - 1) do |i|
            @sprites["pokemon#{i}"].selected = (i == @activecmd)
          end
        end

        left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
        right_click = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
        if left_click
          hover_idx = pbMouseUITutorHoverIndex
          if !hover_idx.nil?
            @activecmd = hover_idx
            @sprites["commands"].ignore_input = false
            return @activecmd
          end
        end

        if Input.trigger?(Input::C)
          @sprites["commands"].ignore_input = false
          return @activecmd
        elsif right_click || Input.trigger?(Input::B)
          @sprites["commands"].ignore_input = false
          0.upto(numsprites - 1) do |i|
            @sprites["pokemon#{i}"].selected = false
          end
          pbPlayCancelSE
          return -1
        end
      end
      @sprites["commands"].ignore_input = false
    end
  end
end

class PokemonMart_Scene
  alias mouse_ui_original_mart_choose_number pbChooseNumber unless method_defined?(:mouse_ui_original_mart_choose_number)
  alias mouse_ui_original_mart_choose_buy_item pbChooseBuyItem unless method_defined?(:mouse_ui_original_mart_choose_buy_item)

  def pbChooseNumber(helptext, item, maximum)
    curnumber = 1
    ret = 0
    helpwindow = @sprites["helpwindow"]
    itemprice = @adapter.getPrice(item, !@buying)
    itemprice /= 2 if !@buying
    pbDisplay(helptext, true)
    using(numwindow = Window_AdvancedTextPokemon.new("")) {
      qty = @adapter.getQuantity(item)
      using(inbagwindow = Window_AdvancedTextPokemon.new("")) {
        pbPrepareWindow(numwindow)
        pbPrepareWindow(inbagwindow)
        numwindow.viewport = @viewport
        numwindow.width = 224
        numwindow.height = 64
        numwindow.baseColor = Color.new(88, 88, 80)
        numwindow.shadowColor = Color.new(168, 184, 184)
        inbagwindow.visible = @buying
        inbagwindow.viewport = @viewport
        inbagwindow.width = 190
        inbagwindow.height = 64
        inbagwindow.baseColor = Color.new(88, 88, 80)
        inbagwindow.shadowColor = Color.new(168, 184, 184)
        inbagwindow.text = _INTL("In Bag:<r>{1}  ", qty)
        numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
        pbBottomRight(numwindow)
        numwindow.y -= helpwindow.height
        pbBottomLeft(inbagwindow)
        inbagwindow.y -= helpwindow.height
        loop do
          Graphics.update
          Input.update
          numwindow.update
          inbagwindow.update
          self.update

          left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
          right_click = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
          if left_click || right_click
            pos = MouseUI.pointer_position
            if pos && MouseUI.window_point_inside?(numwindow, pos[0], pos[1])
              sx, sy = MouseUI.window_screen_position(numwindow)
              lx = pos[0] - sx
              step = (lx < (numwindow.width * 2) / 3) ? 1 : 10
              if left_click
                curnumber += step
              else
                curnumber -= step
              end
              curnumber = 1 if curnumber < 1
              curnumber = maximum if curnumber > maximum
              numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
              pbPlayCursorSE
              next
            end
            # Outside the number box, fall through to normal confirm/cancel behavior.
          end

          wheel_direction = MouseUI.wheel_direction
          if wheel_direction != 0
            pos = MouseUI.pointer_position
            if pos && MouseUI.window_point_inside?(numwindow, pos[0], pos[1])
              sx, sy = MouseUI.window_screen_position(numwindow)
              lx = pos[0] - sx
              step = (lx < (numwindow.width * 2) / 3) ? 1 : 10
              curnumber -= step * wheel_direction
              curnumber = 1 if curnumber < 1
              curnumber = maximum if curnumber > maximum
              numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
              pbPlayCursorSE
              next
            end
          end

          if Input.trigger?(Input::BACK)
            pbPlayCancelSE
            ret = 0
            break
          elsif Input.trigger?(Input::USE)
            pbPlayDecisionSE
            ret = curnumber
            break
          elsif Input.repeat?(Input::LEFT)
            pbPlayCursorSE
            curnumber -= 10
            curnumber = 1 if curnumber < 1
            numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
          elsif Input.repeat?(Input::RIGHT)
            pbPlayCursorSE
            curnumber += 10
            curnumber = maximum if curnumber > maximum
            numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
          elsif Input.repeat?(Input::UP)
            pbPlayCursorSE
            curnumber += 1
            curnumber = 1 if curnumber > maximum
            numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
          elsif Input.repeat?(Input::DOWN)
            pbPlayCursorSE
            curnumber -= 1
            curnumber = maximum if curnumber < 1
            numwindow.text = _INTL("x{1}<r>$ {2}", curnumber, (curnumber * itemprice).to_s_formatted)
          end
        end
      }
    }
    helpwindow.visible = false
    return ret
  end

  def pbChooseBuyItem
    itemwindow = @sprites["itemwindow"]
    @sprites["helpwindow"].visible = false
    pbActivateWindow(@sprites, "itemwindow") {
      pbRefresh
      loop do
        Graphics.update
        Input.update
        olditem = itemwindow.item
        self.update

        pos = MouseUI.pointer_position
        if pos
          hover_idx = MouseUI.window_hover_index(itemwindow, pos[0], pos[1])
          if !hover_idx.nil? && hover_idx != itemwindow.index
            itemwindow.index = hover_idx
          end
        end

        if itemwindow.item != olditem
          @sprites["icon"].item = itemwindow.item
          @sprites["itemtextwindow"].text = (itemwindow.item) ? @adapter.getDescription(itemwindow.item) : _INTL("Quit shopping.")
        end

        left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
        right_click = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
        if left_click
          if pos
            click_idx = MouseUI.window_hover_index(itemwindow, pos[0], pos[1])
            if !click_idx.nil?
              itemwindow.index = click_idx
              if itemwindow.index < @stock.length
                pbRefresh
                return @stock[itemwindow.index]
              else
                return nil
              end
            else
              next
            end
          else
            next
          end
        end

        if right_click || Input.trigger?(Input::BACK)
          pbPlayCloseMenuSE
          return nil
        elsif Input.trigger?(Input::USE)
          if itemwindow.index < @stock.length
            pbRefresh
            return @stock[itemwindow.index]
          else
            return nil
          end
        end
      end
    }
  end
end

class ItemStorage_Scene
  alias mouse_ui_original_itemstorage_choose_item pbChooseItem unless method_defined?(:mouse_ui_original_itemstorage_choose_item)

  def pbChooseItem
    pbRefresh
    @sprites["helpwindow"].visible = false
    itemwindow = @sprites["itemwindow"]
    itemwindow.refresh
    pbActivateWindow(@sprites, "itemwindow") {
      loop do
        Graphics.update
        Input.update
        olditem = itemwindow.item
        self.update

        pos = MouseUI.pointer_position
        if pos
          hover_idx = MouseUI.window_hover_index(itemwindow, pos[0], pos[1])
          if !hover_idx.nil? && hover_idx != itemwindow.index
            itemwindow.index = hover_idx
          end
        end

        pbRefresh if itemwindow.item != olditem

        left_click = defined?(Input::MOUSELEFT) && Input.trigger?(Input::MOUSELEFT)
        right_click = defined?(Input::MOUSERIGHT) && Input.trigger?(Input::MOUSERIGHT)
        if left_click
          if pos
            click_idx = MouseUI.window_hover_index(itemwindow, pos[0], pos[1])
            if !click_idx.nil?
              itemwindow.index = click_idx
              if itemwindow.index < @bag.length
                pbRefresh
                return @bag[itemwindow.index][0]
              else
                return nil
              end
            else
              next
            end
          else
            next
          end
        end

        if right_click || Input.trigger?(Input::BACK)
          return nil
        elsif Input.trigger?(Input::USE)
          if itemwindow.index < @bag.length
            pbRefresh
            return @bag[itemwindow.index][0]
          else
            return nil
          end
        end
      end
    }
  end
end
