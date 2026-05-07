class CounterfeitPokemonPickerWindow < Window_DrawableCommand
  attr_reader :entries

  def initialize(entries, x, y, width, height, viewport = nil)
    @entries = entries || []
    super(x, y, width, height)
    self.viewport = viewport if viewport
    self.active = true
    colors = getDefaultTextColors(self.windowskin)
    self.baseColor = colors[0]
    self.shadowColor = colors[1]
    refresh
  end

  def itemCount
    return @entries.length
  end

  def entries=(value)
    @entries = value || []
    @item_max = itemCount
    self.index = 0 if self.index >= @item_max
    refresh
  end

  def drawItem(index, _count, rect)
    return if !@entries[index]
    entry = @entries[index]
    rect = drawCursor(index, rect)
    pbSetSystemFont(self.contents)
    right_text = entry[:right_text].to_s
    if right_text.empty?
      left_width = rect.width - 8
    else
      left_width = rect.width - 104
    end
    pbDrawShadowText(
      self.contents, rect.x, rect.y, left_width, rect.height,
      entry[:left_text].to_s, self.baseColor, self.shadowColor
    )
    if !right_text.empty?
      right_color = entry[:right_color] || self.baseColor
      pbDrawShadowText(
        self.contents, rect.x + rect.width - 100, rect.y, 96, rect.height,
        right_text, right_color, self.shadowColor, 2
      )
    end
  end
end

class CounterfeitSliderWindow < Window_DrawableCommand
  attr_reader :items

  def initialize(items, x, y, width, height, viewport = nil)
    @items = items || []
    super(x, y, width, height)
    self.viewport = viewport if viewport
    self.active = true
    colors = getDefaultTextColors(self.windowskin)
    self.baseColor = colors[0]
    self.shadowColor = colors[1]
    refresh
  end

  def itemCount
    return @items.length
  end

  def items=(value)
    @items = value || []
    @item_max = itemCount
    self.index = 0 if self.index >= @item_max
    refresh
  end

  def drawItem(index, _count, rect)
    return if !@items[index]
    item = @items[index]
    rect = drawCursor(index, rect)
    pbSetSystemFont(self.contents)
    label_color = item[:label_color] || self.baseColor
    value_color = item[:value_color] || self.baseColor
    if item[:slider]
      drawSliderItem(rect, item, label_color, value_color)
    else
      value_width = [rect.width / 3, 96].max
      label_width = [rect.width - value_width - 12, 40].max
      pbDrawShadowText(
        self.contents, rect.x, rect.y, label_width, rect.height,
        item[:label].to_s, label_color, self.shadowColor
      )
      pbDrawShadowText(
        self.contents, rect.x + rect.width - value_width - 4, rect.y, value_width, rect.height,
        item[:value].to_s, value_color, self.shadowColor, 2
      )
    end
  end

  def drawSliderItem(rect, item, label_color, value_color)
    value_width = 52
    label_width = 72
    bar_gap = 8
    bar_width = [rect.width - label_width - value_width - (bar_gap * 2), 48].max
    bar_x = rect.x + label_width + bar_gap
    bar_y = rect.y + (rect.height / 2) - 4
    current = item[:current].to_i
    min = item[:min].to_i
    max = item[:max].to_i
    max = min + 1 if max <= min
    ratio = (current - min).to_f / (max - min).to_f
    ratio = 0.0 if ratio < 0.0
    ratio = 1.0 if ratio > 1.0
    fill_width = [(bar_width * ratio).round, 4].max
    self.contents.fill_rect(bar_x, bar_y, bar_width, 8, Color.new(52, 52, 52))
    self.contents.fill_rect(bar_x + 1, bar_y + 1, bar_width - 2, 6, Color.new(20, 20, 20))
    bar_color = item[:bar_color] || Color.new(88, 184, 120)
    self.contents.fill_rect(bar_x + 1, bar_y + 1, [fill_width - 2, 1].max, 6, bar_color)
    if min < 0 && max > 0
      center_ratio = (0 - min).to_f / (max - min).to_f
      center_x = bar_x + (bar_width * center_ratio).round
      self.contents.fill_rect(center_x, bar_y - 1, 1, 10, Color.new(220, 220, 220))
    end
    pbDrawShadowText(
      self.contents, rect.x, rect.y, label_width, rect.height,
      item[:label].to_s, label_color, self.shadowColor
    )
    pbDrawShadowText(
      self.contents, rect.x + rect.width - value_width - 4, rect.y, value_width, rect.height,
      item[:value].to_s, value_color, self.shadowColor, 2
    )
  end
end

module CounterfeitPreviewBitmapHelper
  module_function

  def trimmed_bitmap(bitmap)
    return nil if !bitmap || bitmap.disposed?
    min_x = nil
    min_y = nil
    max_x = nil
    max_y = nil
    for y in 0...bitmap.height
      for x in 0...bitmap.width
        next if bitmap.get_pixel(x, y).alpha <= 0
        min_x = x if min_x.nil? || x < min_x
        max_x = x if max_x.nil? || x > max_x
        min_y = y if min_y.nil? || y < min_y
        max_y = y if max_y.nil? || y > max_y
      end
    end
    return bitmap.clone if min_x.nil?
    padding = 6
    min_x = [min_x - padding, 0].max
    min_y = [min_y - padding, 0].max
    max_x = [max_x + padding, bitmap.width - 1].min
    max_y = [max_y + padding, bitmap.height - 1].min
    width = [max_x - min_x + 1, 1].max
    height = [max_y - min_y + 1, 1].max
    ret = Bitmap.new(width, height)
    ret.blt(0, 0, bitmap, Rect.new(min_x, min_y, width, height))
    return ret
  rescue
    return bitmap.clone
  end
end

class CounterfeitPokemonPickerScene
  MAX_PREVIEW_ZOOM = 4.0

  def initialize(title, refs, mode, profile_id = nil, session_sales = 0)
    @title = title
    @refs = refs
    @mode = mode
    @profile_id = profile_id
    @session_sales = session_sales
    @sprites = {}
    @preview_wrapper = nil
  end

  def pbStartScreen
    return nil if !@refs || @refs.empty?
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    skin = "Graphics/Windowskins/default_opaque"
    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
      @title, 0, 0, Graphics.width, 64, @viewport
    )
    @sprites["title"].windowskin = nil
    left_width = [[(Graphics.width * 0.28).to_i, 248].max, 272].min
    right_x = left_width + 20
    right_width = Graphics.width - right_x - 20
    detail_height = 156
    detail_y = Graphics.height - 64 - detail_height - 8
    body_height = Graphics.height - 64 - 64
    @sprites["list"] = CounterfeitPokemonPickerWindow.new(
      build_entries, 0, 48, left_width, body_height, @viewport
    )
    @sprites["list"].setSkin(skin)
    detail_width = right_width - 4
    detail_x = right_x + 2
    @sprites["detail"] = Window_AdvancedTextPokemon.newWithSize(
      "", detail_x, detail_y, detail_width, detail_height, @viewport
    )
    @sprites["detail"].setSkin(skin)
    @sprites["help"] = Window_UnformattedTextPokemon.newWithSize(
      default_help_text, 0, Graphics.height - 64, Graphics.width, 64, @viewport
    )
    @sprites["help"].setSkin(skin)
    @preview_area = {
      :x      => right_x + 12,
      :y      => 56,
      :width  => right_width - 24,
      :height => detail_y - 70
    }
    @sprites["preview"] = Sprite.new(@viewport)
    @sprites["preview"].x = right_x + (right_width / 2)
    @sprites["preview"].y = detail_y - 12
    @sprites["preview"].z = 1
    refresh_entry
    pbFadeInAndShow(@sprites)
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
      if @last_index != @sprites["list"].index
        refresh_entry
      end
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        return nil
      end
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        return current_ref
      end
    end
  ensure
    pbFadeOutAndHide(@sprites) rescue nil
    dispose_preview
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport && !@viewport.disposed?
  end

  def build_entries
    @refs.map do |ref|
      pokemon = ref[:pokemon]
      right_text = ""
      right_color = nil
      case @mode
      when :buyer
        quote = CounterfeitShinies.quote_for(@profile_id, pokemon, @session_sales)
        if quote[:allowed]
          right_text = CounterfeitShinies.format_money(quote[:offer])
        else
          right_text = "Refused"
          right_color = Color.new(208, 88, 88)
        end
      when :launder
        right_text = "Scrub"
        right_color = Color.new(80, 160, 80)
      else
        right_text = ""
      end
      {
        :left_text  => compact_entry_label(pokemon),
        :right_text => right_text,
        :right_color => right_color
      }
    end
  end

  def compact_entry_label(pokemon)
    name = pokemon.name.to_s
    max_name = 14
    name = "#{name[0, max_name - 3]}..." if name.length > max_name
    return "#{name} Lv#{pokemon.level}"
  end

  def current_ref
    return nil if !@refs || @refs.empty?
    return @refs[@sprites["list"].index]
  end

  def default_help_text
    case @mode
    when :buyer
      return "Choose counterfeit stock to sell."
    when :launder
      return "Choose counterfeit stock to scrub clean."
    else
      return "Choose a Pokemon to inspect."
    end
  end

  def refresh_entry
    @last_index = @sprites["list"].index
    ref = current_ref
    return if !ref
    pokemon = ref[:pokemon]
    text = case @mode
           when :buyer
             CounterfeitShinies.buyer_summary_text(@profile_id, pokemon, ref, @session_sales)
           when :launder
             CounterfeitShinies.launder_summary_text(pokemon, ref)
           else
             CounterfeitShinies.workshop_summary_text(pokemon, ref)
           end
    @sprites["detail"].text = text
    refresh_preview(pokemon)
  end

  def refresh_preview(pokemon)
    dispose_preview
    return if !pokemon
    bitmap = nil
    if CounterfeitShinies.render_fake_shiny?(pokemon)
      bitmap = CounterfeitShinies.preview_bitmap(pokemon)
    else
      bitmap = GameData::Species.sprite_bitmap_from_pokemon(pokemon)
    end
    return if !bitmap
    @preview_wrapper = bitmap if bitmap.respond_to?(:dispose)
    source = bitmap.respond_to?(:bitmap) ? bitmap.bitmap : bitmap
    @sprites["preview"].bitmap = CounterfeitPreviewBitmapHelper.trimmed_bitmap(source)
    bmp = @sprites["preview"].bitmap
    @sprites["preview"].ox = bmp.width / 2
    @sprites["preview"].oy = bmp.height
    area = @preview_area || { :x => 0, :y => 64, :width => Graphics.width, :height => Graphics.height - 128 }
    scale_x = area[:width].to_f / [bmp.width, 1].max
    scale_y = area[:height].to_f / [bmp.height, 1].max
    scale = [scale_x, scale_y, MAX_PREVIEW_ZOOM].min
    @sprites["preview"].zoom_x = scale
    @sprites["preview"].zoom_y = scale
    @sprites["preview"].x = area[:x] + (area[:width] / 2)
    @sprites["preview"].y = area[:y] + area[:height]
  end

  def dispose_preview
    if @sprites["preview"] && @sprites["preview"].bitmap && !@sprites["preview"].bitmap.disposed?
      @sprites["preview"].bitmap.dispose
    end
    if @sprites["preview"]
      @sprites["preview"].zoom_x = 1.0
      @sprites["preview"].zoom_y = 1.0
    end
    if @preview_wrapper && @preview_wrapper.respond_to?(:dispose)
      @preview_wrapper.dispose
    end
    @preview_wrapper = nil
  end
end

class CounterfeitShinyEditorScene
  STYLE_NAMES = CounterfeitShinies::Config::SHINY_STYLE_NAMES
  MAX_PREVIEW_ZOOM = 4.0

  def initialize(pokemon)
    @pokemon = pokemon
    @new_counterfeit = !CounterfeitShinies.counterfeit?(pokemon)
    @data_snapshot = CounterfeitShinies.deep_clone(pokemon.counterfeit_shiny_data)
    @visual_snapshot = CounterfeitShinies.capture_visual_state(pokemon)
    @last_favorite_slot = 0
    @preview_wrapper = nil
    @sprites = {}
  end

  def pbStartScreen
    prime_preview_state
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    skin = "Graphics/Windowskins/default_opaque"
    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
      CounterfeitShinies::Config::WORKSHOP_TITLE, 0, 0, Graphics.width, 64, @viewport
    )
    @sprites["title"].windowskin = nil
    left_width = [[(Graphics.width * 0.33).to_i, 300].max, 340].min
    right_x = left_width + 16
    right_width = Graphics.width - right_x - 16
    stats_height = 132
    preview_y = 58 + stats_height + 18
    preview_bottom = Graphics.height - 8
    @sprites["stats"] = Window_AdvancedTextPokemon.newWithSize(
      "", 16, 58, left_width, stats_height, @viewport
    )
    @sprites["stats"].setSkin(skin)
    @preview_area = {
      :x      => 16,
      :y      => preview_y,
      :width  => left_width,
      :height => [preview_bottom - preview_y, 200].max
    }
    @sprites["help"] = Window_UnformattedTextPokemon.newWithSize(
      "", 0, Graphics.height - 64, Graphics.width, 64, @viewport
    )
    @sprites["help"].setSkin(skin)
    @sprites["help"].visible = false
    @sprites["preview"] = Sprite.new(@viewport)
    @sprites["preview"].x = 16 + (left_width / 2)
    @sprites["preview"].y = @preview_area[:y] + @preview_area[:height]
    @sprites["preview"].z = 1
    @sprites["sliders"] = CounterfeitSliderWindow.new(
      slider_items, right_x, 58, right_width, Graphics.height - 66, @viewport
    )
    @sprites["sliders"].setSkin(skin)
    refresh_scene
    pbFadeInAndShow(@sprites)
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
      if handle_adjustment(-1) || handle_adjustment(1)
        refresh_scene
        next
      end
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        restore_original_state
        return nil
      end
      next if !Input.trigger?(Input::USE)
      pbPlayDecisionSE
      action = handle_action
      next if action == :continue
      return action
    end
  ensure
    pbFadeOutAndHide(@sprites) rescue nil
    dispose_preview
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport && !@viewport.disposed?
  end

  def prime_preview_state
    if @new_counterfeit
      CounterfeitShinies.apply_counterfeit!(@pokemon, CounterfeitShinies.default_palette, :workshop)
    else
      CounterfeitShinies.ensure_data_defaults!(@pokemon)
    end
  end

  def restore_original_state
    CounterfeitShinies.restore_visual_state(@pokemon, @visual_snapshot)
    @pokemon.counterfeit_shiny_data = @data_snapshot
  end

  def slider_items
    krs = CounterfeitShinies.sanitize_krs(@pokemon.shinyKRS?)
    shelf_text = "#{CounterfeitShinies.favorite_fill_count}/#{CounterfeitShinies::Config::PALETTE_FAVORITE_SLOTS}"
    return [
      slider_item("Hue",   @pokemon.shinyValue?, CounterfeitShinies::Config::HUE_MIN, CounterfeitShinies::Config::HUE_MAX, Color.new(212, 180, 92)),
      slider_item("Red",   @pokemon.shinyR?,     CounterfeitShinies::Config::CHANNEL_MIN,  CounterfeitShinies::Config::CHANNEL_HARD_CAP, Color.new(216, 96, 96)),
      slider_item("Green", @pokemon.shinyG?,     CounterfeitShinies::Config::CHANNEL_MIN,  CounterfeitShinies::Config::CHANNEL_HARD_CAP, Color.new(112, 208, 112)),
      slider_item("Blue",  @pokemon.shinyB?,     CounterfeitShinies::Config::CHANNEL_MIN,  CounterfeitShinies::Config::CHANNEL_HARD_CAP, Color.new(112, 144, 232)),
      slider_item("R Boost", krs[0], CounterfeitShinies::Config::BOOST_MIN, CounterfeitShinies::Config::BOOST_MAX, Color.new(216, 96, 96)),
      slider_item("G Boost", krs[1], CounterfeitShinies::Config::BOOST_MIN, CounterfeitShinies::Config::BOOST_MAX, Color.new(112, 208, 112)),
      slider_item("B Boost", krs[2], CounterfeitShinies::Config::BOOST_MIN, CounterfeitShinies::Config::BOOST_MAX, Color.new(112, 144, 232)),
      { :label => "Shuffle",      :value => "Roll",    :label_color => Color.new(80, 160, 80) },
      { :label => "Style",        :value => short_style_name },
      { :label => "Load Fav",     :value => shelf_text },
      { :label => "Save Fav",     :value => shelf_text },
      { :label => (@new_counterfeit ? "Forge" : "Save"), :value => "Commit", :label_color => Color.new(80, 160, 80) },
      { :label => "Cancel",       :value => "Back",     :label_color => Color.new(208, 88, 88) }
    ]
  end

  def help_text
    return ""
  end

  def refresh_scene
    @sprites["sliders"].items = slider_items
    @sprites["help"].text = help_text
    @sprites["stats"].text = stats_text
    refresh_preview
  end

  def stats_text
    lines = []
    lines << "#{@pokemon.name} / Lv#{@pokemon.level}"
    species = @pokemon.speciesName.to_s
    lines << species if species != @pokemon.name.to_s
    lines << "Value #{CounterfeitShinies.format_money(CounterfeitShinies.market_value(@pokemon))} / Appeal #{CounterfeitShinies.appeal_score(@pokemon)}"
    wins = CounterfeitShinies.counterfeit_data_for(@pokemon) ? CounterfeitShinies.counterfeit_data_for(@pokemon)[:enforcer_wins].to_i : 0
    lines << "Wins #{wins} / Heat #{CounterfeitShinies.heat_label}"
    lines << "Style #{short_style_name}"
    return lines.join("\n")
  end

  def refresh_preview
    dispose_preview
    bitmap = CounterfeitShinies.preview_bitmap(@pokemon)
    return if !bitmap
    @preview_wrapper = bitmap if bitmap.respond_to?(:dispose)
    source = bitmap.respond_to?(:bitmap) ? bitmap.bitmap : bitmap
    @sprites["preview"].bitmap = CounterfeitPreviewBitmapHelper.trimmed_bitmap(source)
    bmp = @sprites["preview"].bitmap
    @sprites["preview"].ox = bmp.width / 2
    @sprites["preview"].oy = bmp.height
    area = @preview_area || { :x => 16, :y => 264, :width => 220, :height => Graphics.height - 64 - 272 }
    scale_x = area[:width].to_f / [bmp.width, 1].max
    scale_y = area[:height].to_f / [bmp.height, 1].max
    scale = [scale_x, scale_y, MAX_PREVIEW_ZOOM].min
    @sprites["preview"].zoom_x = scale
    @sprites["preview"].zoom_y = scale
    @sprites["preview"].x = area[:x] + (area[:width] / 2)
    @sprites["preview"].y = area[:y] + area[:height]
  end

  def dispose_preview
    if @sprites["preview"] && @sprites["preview"].bitmap && !@sprites["preview"].bitmap.disposed?
      @sprites["preview"].bitmap.dispose
    end
    if @sprites["preview"]
      @sprites["preview"].zoom_x = 1.0
      @sprites["preview"].zoom_y = 1.0
    end
    if @preview_wrapper && @preview_wrapper.respond_to?(:dispose)
      @preview_wrapper.dispose
    end
    @preview_wrapper = nil
  end

  def handle_adjustment(direction)
    return false if direction == 0
    left = (direction < 0)
    right = (direction > 0)
    triggered = left ? Input.repeat?(Input::LEFT) : Input.repeat?(Input::RIGHT)
    return false if !triggered
    case @sprites["sliders"].index
    when 0
      @pokemon.shinyValue = CounterfeitShinies.sanitize_hue(@pokemon.shinyValue? + (direction * 6))
    when 1
      @pokemon.shinyR = CounterfeitShinies.sanitize_channel(@pokemon.shinyR? + direction)
    when 2
      @pokemon.shinyG = CounterfeitShinies.sanitize_channel(@pokemon.shinyG? + direction)
    when 3
      @pokemon.shinyB = CounterfeitShinies.sanitize_channel(@pokemon.shinyB? + direction)
    when 4, 5, 6
      krs = CounterfeitShinies.sanitize_krs(@pokemon.shinyKRS?)
      slot = @sprites["sliders"].index - 4
      krs[slot] = CounterfeitShinies.sanitize_boost(krs[slot].to_i + (direction * 8))
      @pokemon.shinyKRS = krs
    when 7
      @pokemon.shinyimprovpif = CounterfeitShinies.sanitize_style(@pokemon.shinyimprovpif? + direction)
    else
      return false
    end
    pbPlayCursorSE
    return true
  end

  def handle_action
    case @sprites["sliders"].index
    when 7
      CounterfeitShinies.apply_palette!(@pokemon, CounterfeitShinies.default_palette)
      refresh_scene
      return :continue
    when 8
      load_favorite_palette
      refresh_scene
      return :continue
    when 9
      save_favorite_palette
      refresh_scene
      return :continue
    when 10
      CounterfeitShinies.apply_counterfeit!(@pokemon, {
        :shinyValue     => @pokemon.shinyValue?,
        :shinyR         => @pokemon.shinyR?,
        :shinyG         => @pokemon.shinyG?,
        :shinyB         => @pokemon.shinyB?,
        :shinyKRS       => @pokemon.shinyKRS?,
        :shinyimprovpif => @pokemon.shinyimprovpif?
      }, :workshop)
      return @new_counterfeit ? :created : :updated
    when 11
      restore_original_state
      return nil
    else
      return :continue
    end
  end

  def load_favorite_palette
    slot = choose_favorite_slot(:load)
    return if slot.nil?
    if !CounterfeitShinies.apply_palette_favorite!(@pokemon, slot)
      pbMessage(_INTL("That favorite slot is empty."))
      return
    end
    pbMessage(_INTL("Loaded favorite slot {1} onto {2}.", slot + 1, @pokemon.name))
  end

  def save_favorite_palette
    slot = choose_favorite_slot(:save)
    return if slot.nil?
    existing = CounterfeitShinies.palette_favorite(slot)
    if existing
      return if !pbConfirmMessage(_INTL("Overwrite favorite slot {1}?", slot + 1))
    end
    return if !CounterfeitShinies.save_palette_favorite(slot, @pokemon)
    pbMessage(_INTL("Saved the current forged finish to favorite slot {1}.", slot + 1))
  end

  def choose_favorite_slot(mode)
    commands = []
    help = []
    0.upto(CounterfeitShinies::Config::PALETTE_FAVORITE_SLOTS - 1) do |slot|
      entry = CounterfeitShinies.palette_favorite(slot)
      commands << CounterfeitShinies.palette_favorite_command_text(slot)
      if entry
        action_text = (mode == :save) ? "Overwrite this slot with the current finish." : "Apply this saved finish to the current stock."
        help << _INTL("{1}. {2}", CounterfeitShinies.palette_signature(entry[:palette]), action_text)
      else
        action_text = (mode == :save) ? "Save the current finish into this empty slot." : "This slot is empty."
        help << action_text
      end
    end
    commands << "Cancel"
    help << "Leave the favorite shelf alone."
    choice = pbShowCommandsWithHelp(nil, commands, help, commands.length, @last_favorite_slot)
    return nil if choice < 0 || choice >= CounterfeitShinies::Config::PALETTE_FAVORITE_SLOTS
    @last_favorite_slot = choice
    return choice
  end

  def short_style_name
    case @pokemon.shinyimprovpif?
    when 1 then "Forced"
    when 2 then "PIF"
    when 3 then "Hybrid"
    else        "Vanilla"
    end
  end

  def slider_item(label, current, min, max, bar_color)
    return {
      :label     => label,
      :value     => current.to_i.to_s,
      :current   => current.to_i,
      :min       => min,
      :max       => max,
      :slider    => true,
      :bar_color => bar_color
    }
  end
end

module CounterfeitShinies
  module_function

  def open_workshop
    refs = workshop_candidates
    if refs.empty?
      pbMessage(_INTL("You do not have any eligible party or PC stock for a counterfeit finish."))
      return false
    end
    picker = CounterfeitPokemonPickerScene.new(Config::WORKSHOP_TITLE, refs, :workshop)
    chosen_ref = picker.pbStartScreen
    return false if !chosen_ref
    pokemon = chosen_ref[:pokemon]
    editor = CounterfeitShinyEditorScene.new(pokemon)
    result = editor.pbStartScreen
    case result
    when :created
      pbMessage(_INTL("{1} now carries a forged Team Infinite Cannon finish.", pokemon.name))
      return true
    when :updated
      pbMessage(_INTL("{1}'s counterfeit finish has been retouched.", pokemon.name))
      return true
    end
    return false
  end

  def open_laundry
    if laundering_token_count <= 0
      pbMessage(_INTL("You do not have a {1} yet. Beat a level {2} enforcer and bring the reward back here.", Config::LAUNDER_REWARD_NAME, GameData::GrowthRate.max_level))
      return false
    end
    refs = laundering_candidates
    if refs.empty?
      pbMessage(_INTL("You do not have any counterfeit stock ready to scrub clean."))
      return false
    end
    picker = CounterfeitPokemonPickerScene.new(Config::LAUNDER_TITLE, refs, :launder)
    chosen_ref = picker.pbStartScreen
    return false if !chosen_ref
    pokemon = chosen_ref[:pokemon]
    confirm_text = _INTL("Use a {1} on {2}? The forged shine will remain, but it will stop counting as counterfeit stock.", Config::LAUNDER_REWARD_NAME, pokemon.name)
    return false if !pbConfirmMessage(confirm_text)
    return false if !spend_laundering_token
    if !remove_counterfeit_tag!(pokemon)
      grant_laundering_tokens
      return false
    end
    pbMessage(_INTL("{1}'s counterfeit tag is scrubbed clean. The forged finish remains, but Team Infinite Cannon can no longer trace it to your stock.", pokemon.name))
    return true
  end

  def open_buyer(profile_id = :street_fence)
    profile = Config.buyer_profile(profile_id)
    session_sales = 0
    pbMessage(_INTL(profile[:welcome]))
    loop do
      refs = sale_candidates
      if refs.empty?
        pbMessage(_INTL(profile[:empty_text]))
        return session_sales > 0
      end
      picker = CounterfeitPokemonPickerScene.new(profile[:title], refs, :buyer, profile_id, session_sales)
      chosen_ref = picker.pbStartScreen
      return session_sales > 0 if !chosen_ref
      pokemon = chosen_ref[:pokemon]
      quote = quote_for(profile_id, pokemon, session_sales)
      if !quote[:allowed]
        pbMessage(_INTL(quote[:reason].to_s))
        next
      end
      confirm_text = _INTL(profile[:confirm_template], quote[:offer].to_s_formatted, pokemon.name)
      next if !pbConfirmMessage(confirm_text)
      next if !remove_owned_pokemon(pokemon, :sold)
      data = counterfeit_data_for(pokemon)
      if data
        data[:status] = :sold
        data[:last_sale_value] = quote[:offer]
      end
      global_state[:gross_profit] += quote[:offer]
      global_state[:lifetime_sales] += 1
      $Trainer.money += quote[:offer]
      session_sales += 1
      pbSEPlay("Mart buy item")
      pbMessage(_INTL("You hand over {1} and receive ${2}.", pokemon.name, quote[:offer].to_s_formatted))
      break if !pbConfirmMessage(_INTL("Offer another counterfeit?"))
    end
    return session_sales > 0
  end

  def bedroom_pc_menu?
    return false if !$game_map
    return false if !defined?(PlayerIdentityBedroomAddon)
    return false if !PlayerIdentityBedroomAddon.respond_to?(:bedroom_map?)
    return PlayerIdentityBedroomAddon.bedroom_map?($game_map.map_id)
  end

  def bedroom_pc_launder_label
    return _INTL("{1} ({2})", Config::PC_MENU_LAUNDER, laundering_token_count)
  end

  def open_bedroom_pc_menu
    command = 0
    loop do
      commands = []
      cmd_item_storage = commands.length
      commands << _INTL(Config::PC_MENU_ITEM_STORAGE)
      cmd_mailbox = commands.length
      commands << _INTL(Config::PC_MENU_MAILBOX)
      cmd_workshop = commands.length
      commands << _INTL(Config::PC_MENU_WORKSHOP)
      cmd_launder = commands.length
      commands << bedroom_pc_launder_label
      cmd_bedroom_color = -1
      if defined?(PlayerIdentityBedroomAddon) && PlayerIdentityBedroomAddon.respond_to?(:change_bedroom_style_from_pc)
        cmd_bedroom_color = commands.length
        commands << _INTL(Config::PC_MENU_BEDROOM_COLOR)
      end
      cmd_turn_off = commands.length
      commands << _INTL(Config::PC_MENU_TURN_OFF)
      command = pbMessage(_INTL(Config::PC_MENU_PROMPT), commands, -1, nil, command)
      case command
      when cmd_item_storage
        pbPCItemStorage
      when cmd_mailbox
        pbPCMailbox
      when cmd_workshop
        open_workshop
      when cmd_launder
        open_laundry
      when cmd_bedroom_color
        room_changed = PlayerIdentityBedroomAddon.change_bedroom_style_from_pc
        break if room_changed
      when cmd_turn_off, -1
        break
      end
    end
  end
end
