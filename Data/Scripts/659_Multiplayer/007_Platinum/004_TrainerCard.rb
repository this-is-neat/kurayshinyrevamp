#===============================================================================
# Platinum Currency - Trainer Card UI Display
# Shows platinum balance and a trainer-card cash-out action.
#===============================================================================

class PokemonTrainerCard_Scene
  PLATINUM_BOX_W      = 140
  PLATINUM_BOX_H      = 28
  PLATINUM_BUTTON_H   = 24
  PLATINUM_BUTTON_GAP = 4
  PLATINUM_CENTER_X   = 400
  PLATINUM_DISPLAY_Y  = 265

  alias platinum_startScene pbStartScene
  def pbStartScene
    @platinum_button_hover = false
    @platinum_box_rect = nil
    @platinum_button_rect = nil
    @last_platinum_balance_request_at = nil
    @platinum_icon_name = nil
    platinum_startScene
  end

  alias platinum_pbUpdate pbUpdate
  def pbUpdate
    platinum_pbUpdate
    update_platinum_button_mouse
  end

  alias platinum_drawTrainerCardFront pbDrawTrainerCardFront
  def pbDrawTrainerCardFront
    platinum_drawTrainerCardFront
    request_platinum_balance_from_server
    draw_platinum_display
  end

  def request_platinum_balance_from_server(force: false)
    return unless defined?(MultiplayerPlatinum) && MultiplayerPlatinum.connected?
    now = Time.now.to_f
    return if !force && @last_platinum_balance_request_at && (now - @last_platinum_balance_request_at) < 0.75
    return unless MultiplayerPlatinum.request_balance_update
    @last_platinum_balance_request_at = now
  rescue => e
    ##MultiplayerDebug.warn("PLATINUM-UI", "Failed to request balance: #{e.message}")
  end

  def platinum_display_layout
    box_x = PLATINUM_CENTER_X - PLATINUM_BOX_W / 2
    box_y = PLATINUM_DISPLAY_Y - 2
    {
      box_x: box_x,
      box_y: box_y,
      box_w: PLATINUM_BOX_W,
      box_h: PLATINUM_BOX_H,
      button_x: box_x,
      button_y: box_y - PLATINUM_BUTTON_H - PLATINUM_BUTTON_GAP,
      button_w: PLATINUM_BOX_W,
      button_h: PLATINUM_BUTTON_H
    }
  end

  def platinum_button_enabled?
    defined?(MultiplayerPlatinum) && MultiplayerPlatinum.connected?
  rescue
    false
  end

  def draw_platinum_panel_box(overlay, x, y, width, height, outer_color, inner_color)
    overlay.fill_rect(x + 2, y, width - 4, height, outer_color)
    overlay.fill_rect(x + 1, y + 1, width - 2, height - 2, outer_color)
    overlay.fill_rect(x, y + 2, width, height - 4, outer_color)
    overlay.fill_rect(x + 1, y, width - 2, 1, Color.new(180, 180, 180))
    overlay.fill_rect(x + 1, y + height - 1, width - 2, 1, Color.new(180, 180, 180))
    overlay.fill_rect(x, y + 1, 1, height - 2, Color.new(180, 180, 180))
    overlay.fill_rect(x + width - 1, y + 1, 1, height - 2, Color.new(180, 180, 180))
    overlay.set_pixel(x + 1, y + 1, Color.new(180, 180, 180))
    overlay.set_pixel(x + width - 2, y + 1, Color.new(180, 180, 180))
    overlay.set_pixel(x + 1, y + height - 2, Color.new(180, 180, 180))
    overlay.set_pixel(x + width - 2, y + height - 2, Color.new(180, 180, 180))

    inset_x = x + 3
    inset_y = y + 3
    inset_w = width - 6
    inset_h = height - 6
    overlay.fill_rect(inset_x, inset_y, inset_w, inset_h, inner_color)
    shadow_color = Color.new(30, 30, 30)
    overlay.fill_rect(inset_x + 1, inset_y + 1, inset_w - 2, 1, shadow_color)
    overlay.fill_rect(inset_x + 1, inset_y + 1, 1, inset_h - 2, shadow_color)
  end

  def draw_platinum_display
    return unless @sprites && @sprites["overlay"]
    overlay = @sprites["overlay"].bitmap
    layout = platinum_display_layout
    balance = defined?(MultiplayerPlatinum) ? MultiplayerPlatinum.cached_balance.to_i : 0
    connected = platinum_button_enabled?

    @platinum_box_rect = Rect.new(layout[:box_x], layout[:box_y], layout[:box_w], layout[:box_h])
    @platinum_button_rect = Rect.new(layout[:button_x], layout[:button_y], layout[:button_w], layout[:button_h])

    old_font_size = overlay.font.size
    old_font_bold = overlay.font.bold

    button_outer = if connected && @platinum_button_hover
      Color.new(190, 145, 95)
    elsif connected
      Color.new(148, 108, 64)
    else
      Color.new(88, 72, 52)
    end
    button_inner = if connected && @platinum_button_hover
      Color.new(120, 84, 38)
    elsif connected
      Color.new(96, 66, 28)
    else
      Color.new(52, 40, 26)
    end
    draw_platinum_panel_box(overlay, layout[:button_x], layout[:button_y], layout[:button_w], layout[:button_h],
                            button_outer, button_inner)

    overlay.font.bold = true
    overlay.font.size = 10
    overlay.font.color = connected ? Color.new(242, 210, 154) : Color.new(160, 138, 112)
    overlay.draw_text(layout[:button_x], layout[:button_y] + 1, layout[:button_w], 11, "Cash Out", 1)
    overlay.font.bold = false
    overlay.font.size = 8
    overlay.font.color = connected ? Color.new(192, 164, 122) : Color.new(132, 112, 92)
    button_hint = if connected
      @platinum_button_hover ? "Choose amount" : "1 Pt = $10"
    else
      "Offline"
    end
    overlay.draw_text(layout[:button_x], layout[:button_y] + 12, layout[:button_w], 10, button_hint, 1)

    draw_platinum_panel_box(overlay, layout[:box_x], layout[:box_y], layout[:box_w], layout[:box_h],
                            Color.new(45, 45, 45), Color.new(60, 60, 60))

    inset_x = layout[:box_x] + 3
    inset_y = layout[:box_y] + 3
    inset_w = layout[:box_w] - 6
    inset_h = layout[:box_h] - 6
    icon_width = 16
    icon_x = inset_x + 4
    icon_y = inset_y + (inset_h - icon_width) / 2
    icon_loaded = false
    text_color = Color.new(220, 220, 220)
    text_shadow = Color.new(100, 100, 100)

    begin
      @@platinum_icon_cycle ||= 1
      @platinum_icon_name ||= begin
        selected = "platinum_icon#{@@platinum_icon_cycle == 1 ? '' : @@platinum_icon_cycle}"
        @@platinum_icon_cycle = (@@platinum_icon_cycle % 3) + 1
        selected
      end
      icon_name = @platinum_icon_name

      if pbResolveBitmap("Graphics/Pictures/Trainer Card/#{icon_name}")
        icon_bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/Trainer Card/", icon_name)
        overlay.stretch_blt(Rect.new(icon_x, icon_y, icon_width, icon_width),
                            icon_bitmap, Rect.new(0, 0, icon_bitmap.width, icon_bitmap.height))
        icon_loaded = true
      elsif pbResolveBitmap("Graphics/Pictures/#{icon_name}")
        icon_bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/", icon_name)
        overlay.stretch_blt(Rect.new(icon_x, icon_y, icon_width, icon_width),
                            icon_bitmap, Rect.new(0, 0, icon_bitmap.width, icon_bitmap.height))
        icon_loaded = true
      end
    rescue => e
      ##MultiplayerDebug.warn("PLATINUM-UI", "Failed to load icon: #{e.message}")
    end

    unless icon_loaded
      overlay.font.size = 14
      overlay.font.bold = true
      pbDrawTextPositions(overlay, [[_INTL("Pt"), icon_x, icon_y - 2, 0, text_color, text_shadow]])
      icon_width = 20
    end

    balance_text = balance.to_s_formatted
    text_area_start = icon_x + icon_width + 4
    text_area_width = (inset_x + inset_w) - text_area_start

    overlay.font.bold = false
    overlay.font.size = old_font_size
    text_size = overlay.text_size(balance_text)
    text_width = text_size.width
    max_text_width = text_area_width - 4
    if text_width > max_text_width
      scale_factor = max_text_width.to_f / text_width
      overlay.font.size = [(old_font_size * scale_factor).to_i, 10].max
      text_size = overlay.text_size(balance_text)
      text_width = text_size.width
    end

    value_x = text_area_start + (text_area_width - text_width) / 2
    value_y = inset_y + (inset_h - text_size.height) / 2

    overlay.font.color = text_shadow
    overlay.draw_text(value_x + 1, value_y + 1, text_width + 20, text_size.height + 4, balance_text)
    overlay.font.color = text_color
    overlay.draw_text(value_x, value_y, text_width + 20, text_size.height + 4, balance_text)

    overlay.font.size = old_font_size
    overlay.font.bold = old_font_bold
  end

  def update_platinum_button_mouse
    return unless @platinum_button_rect && @sprites && @sprites["overlay"]
    mx = (Input.mouse_x rescue nil)
    my = (Input.mouse_y rescue nil)
    hovered = false
    if mx && my && platinum_button_enabled?
      hovered = mx >= @platinum_button_rect.x && mx < (@platinum_button_rect.x + @platinum_button_rect.width) &&
                my >= @platinum_button_rect.y && my < (@platinum_button_rect.y + @platinum_button_rect.height)
    end

    if hovered != @platinum_button_hover
      @platinum_button_hover = hovered
      pbDrawTrainerCardFront
    end

    return unless hovered
    return unless (Input.trigger?(Input::MOUSELEFT) rescue false)
    handle_platinum_cashout
  end

  def handle_platinum_cashout
    return unless defined?(MultiplayerPlatinum)
    max_amount = MultiplayerPlatinum.cashout_max_amount(refresh: true)
    if max_amount <= 0
      pbMessage(_INTL("You don't have any Platinum to cash out."))
      return
    end

    amount = MultiplayerPlatinum.prompt_cashout_amount(max_amount, 1) { pbUpdate }
    return if amount.nil?

    money_amount = MultiplayerPlatinum.cashout_value(amount)
    choice = pbMessage(
      _INTL("Convert {1} Platinum into ${2}?", amount, money_amount.to_s_formatted),
      [_INTL("Yes"), _INTL("No")], 1
    )
    return unless choice == 0

    ok, result = MultiplayerPlatinum.convert_to_money(amount, money_amount, "trainer_card_convert")
    if ok
      request_platinum_balance_from_server(force: true)
      pbMessage(_INTL("Converted {1} Platinum into ${2}.", amount, money_amount.to_s_formatted))
    else
      pbMessage(_INTL(result.to_s))
    end
    pbDrawTrainerCardFront
  end
end
