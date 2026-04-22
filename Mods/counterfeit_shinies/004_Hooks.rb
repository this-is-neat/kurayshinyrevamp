def pbCounterfeitShinyWorkshop
  return CounterfeitShinies.open_workshop
end

def pbCounterfeitBuyer(profile_id = :street_fence)
  return CounterfeitShinies.open_buyer(profile_id)
end

def pbCounterfeitStatus
  pbMessage(_INTL(CounterfeitShinies.player_status_text))
end

def pbCounterfeitLaundry
  return CounterfeitShinies.open_laundry
end

alias counterfeit_shinies_pbTrainerPC pbTrainerPC
def pbTrainerPC
  if CounterfeitShinies.bedroom_pc_menu?
    pbMessage(_INTL("\\se[PC open]{1} booted up the PC.", $Trainer.name))
    CounterfeitShinies.open_bedroom_pc_menu
    pbSEPlay("PC close")
    return
  end
  counterfeit_shinies_pbTrainerPC
end

class Game_Event
  alias counterfeit_shinies_start start
  def start
    if !$game_system.map_interpreter.running? && CounterfeitShinies.try_world_offer(self)
      return
    end
    counterfeit_shinies_start
  end
end

class Interpreter
  alias counterfeit_shinies_command_101 command_101
  def command_101
    if @event_id.to_i > 0
      text = CounterfeitShinies.interpreter_message_preview(self)
      CounterfeitShinies.capture_dialogue_message(@map_id, @event_id, text)
    end
    counterfeit_shinies_command_101
  end

  alias counterfeit_shinies_command_end command_end
  def command_end
    map_id = @map_id
    event_id = @event_id
    main = @main
    CounterfeitShinies.finalize_dialogue_interaction(map_id, event_id) if main && event_id.to_i > 0
    counterfeit_shinies_command_end
    return if !main || event_id.to_i <= 0
    return if !$game_map || $game_map.map_id != map_id
    $game_map.refresh if $game_map.need_refresh
    event = $game_map.events[event_id] rescue nil
    event.refresh if event && event.respond_to?(:refresh)
    CounterfeitShinies.try_post_event_world_offer(event)
  end
end

class Game_Character
  alias counterfeit_shinies_passable passable?
  def passable?(x, y, d, strict = false)
    ret = counterfeit_shinies_passable(x, y, d, strict)
    return ret if !ret
    return ret if self != $game_player
    new_x = x + ((d == 6) ? 1 : (d == 4) ? -1 : 0)
    new_y = y + ((d == 2) ? 1 : (d == 8) ? -1 : 0)
    return false if defined?(CounterfeitShinies) && CounterfeitShinies.enforcer_chaser_blocks_tile?(new_x, new_y)
    return ret
  end
end

Events.onStepTaken += proc { |_sender, _e|
  begin
    CounterfeitShinies.cool_heat_if_clean
  rescue
  end
}

Events.onMapUpdate += proc { |_sender, _e|
  begin
    CounterfeitShinies.update_enforcer_chase
  rescue
  end
}

Events.onStepTakenTransferPossible += proc { |_sender, e|
  begin
    handled = e[0]
    next if handled[0]
    if CounterfeitShinies.trigger_enforcer_encounter
      handled[0] = true
    end
  rescue
  end
}

Events.onMapChanging += proc { |_sender, _e|
  begin
    CounterfeitShinies.clear_dialogue_buffers!
    CounterfeitShinies.clear_enforcer_chase!(:map_transfer)
  rescue
  end
}

Events.onStartBattle += proc { |_sender, _e|
  begin
    if CounterfeitShinies.enforcer_chase_active?
      CounterfeitShinies.clear_enforcer_chase!(:other_battle)
    end
  rescue
  end
}

Events.onEndBattle += proc { |_sender, e|
  begin
    decision = e[0]
    CounterfeitShinies.handle_enforcer_battle_end(decision)
  rescue
    $PokemonTemp.counterfeit_shiny_context = nil if $PokemonTemp
  end
}

class CounterfeitEnforcerProjectedSprite < RPG::Sprite
  def initialize(viewport, character)
    super(viewport)
    @viewport = viewport
    @character = character
    @charset_name = nil
    @charset_hue = nil
    @charbitmap = nil
    @cw = 0
    @ch = 0
    @spriteoffset = false
    @shadow = nil
    self.visible = false
    create_shadow
    refresh_bitmap
  end

  def dispose
    dispose_shadow
    dispose_bitmap
    super
  end

  def refresh_bitmap
    dispose_bitmap
    return if !@character
    @charset_name = @character.character_name.to_s
    @charset_hue = @character.character_hue
    return if @charset_name.empty?
    path = "Graphics/Characters/#{@charset_name}"
    return if !pbResolveBitmap(path)
    @charbitmap = AnimatedBitmap.new(path, @charset_hue)
    update_bitmap_frame(true)
  rescue
    dispose_bitmap
  end

  def update
    super
    return hide_sprite if !@character
    if @charset_name != @character.character_name.to_s || @charset_hue != @character.character_hue
      refresh_bitmap
    else
      update_bitmap_frame
    end
    return hide_sprite if !self.bitmap || self.bitmap.disposed?
    self.visible = !@character.transparent
    frame = @character.pattern.to_i
    frame = 0 if frame < 0
    frame = 3 if frame > 3
    row = case @character.direction
          when 2 then 0
          when 4 then 1
          when 6 then 2
          when 8 then 3
          else 0
          end
    self.src_rect.set(frame * @cw, row * @ch, @cw, @ch)
    self.ox = @cw / 2
    self.oy = @spriteoffset ? @ch - 16 : @ch
    self.x = projected_screen_x
    self.y = projected_screen_y
    self.z = projected_screen_z
    self.opacity = @character.opacity
    self.blend_type = @character.blend_type
    pbDayNightTint(self) if defined?(pbDayNightTint) && self.visible
    update_shadow
  rescue
    hide_sprite
  end

  private

  def projected_screen_x
    map = $game_map
    return 0 if !map
    return ((@character.real_x.to_f - map.display_x) / Game_Map::X_SUBPIXELS).round +
           (@character.width * Game_Map::TILE_WIDTH / 2)
  rescue
    return 0
  end

  def projected_screen_y_ground
    map = $game_map
    return 0 if !map
    return ((@character.real_y.to_f - map.display_y) / Game_Map::Y_SUBPIXELS).round +
           Game_Map::TILE_HEIGHT
  rescue
    return 0
  end

  def projected_screen_y
    return projected_screen_y_ground
  end

  def projected_screen_z
    ground_y = projected_screen_y_ground
    z = ground_y
    z += Game_Map::TILE_HEIGHT - 1 if @ch > Game_Map::TILE_HEIGHT
    return z
  rescue
    return 0
  end

  def update_bitmap_frame(force = false)
    return if !@charbitmap
    @charbitmap.update if @charbitmap.respond_to?(:update)
    current = @charbitmap.bitmap
    return if !current || current.disposed?
    self.bitmap = current if force || self.bitmap != current
    @cw = [current.width / 4, 1].max if force || @cw <= 0
    @ch = [current.height / 4, 1].max if force || @ch <= 0
    @spriteoffset = !!(@charset_name[/fish/i] || @charset_name[/dive/i] || @charset_name[/surf/i])
  end

  def create_shadow
    shadow_path = defined?(SHADOW_IMG_FOLDER) ? SHADOW_IMG_FOLDER : "Graphics/Characters/"
    shadow_name = defined?(SHADOW_IMG_NAME) ? SHADOW_IMG_NAME : "shadow"
    return if !pbResolveBitmap("#{shadow_path}#{shadow_name}")
    @shadow = Sprite.new(@viewport)
    @shadow.bitmap = RPG::Cache.load_bitmap(shadow_path, shadow_name)
    @shadow.ox = @shadow.bitmap.width / 2
    @shadow.oy = @shadow.bitmap.height / 2
    @shadow.visible = false
  rescue
    dispose_shadow
  end

  def update_shadow
    return if !@shadow
    @shadow.visible = self.visible
    return if !self.visible
    @shadow.x = self.x
    @shadow.y = self.y - 6
    @shadow.z = [self.z - 1, 0].max
    @shadow.opacity = self.opacity
    pbDayNightTint(@shadow) if defined?(pbDayNightTint)
  end

  def hide_sprite
    self.visible = false
    @shadow.visible = false if @shadow
  end

  def dispose_bitmap
    if @charbitmap && @charbitmap.respond_to?(:dispose)
      @charbitmap.dispose
    end
    @charbitmap = nil
    self.bitmap = nil rescue nil
  end

  def dispose_shadow
    return if !@shadow
    @shadow.dispose if !@shadow.disposed?
    @shadow = nil
  end
end

class CounterfeitEnforcerChaseVisual
  def initialize(viewport, map)
    @viewport = viewport
    @map = map
    @sprite = nil
    @character = nil
    @disposed = false
  end

  def disposed?
    return @disposed
  end

  def dispose
    @sprite.dispose if @sprite && !@sprite.disposed?
    @sprite = nil
    @character = nil
    @disposed = true
  end

  def update
    return if @disposed
    refresh_character
    state = CounterfeitShinies.enforcer_chase_state
    if state && state[:map_id] == @map.map_id &&
       !$game_temp.in_menu && !$game_temp.in_battle &&
       !$game_temp.message_window_showing && !pbMapInterpreterRunning?
      CounterfeitShinies.update_enforcer_chase_character(state)
    end
    @sprite.update if @sprite && !@sprite.disposed?
    update_effects
  end

  def refresh_character
    current = CounterfeitShinies.current_chase_character_for_map(@map.map_id)
    return if current.equal?(@character)
    @sprite.dispose if @sprite && !@sprite.disposed?
    @sprite = nil
    @character = current
    if @character
      @sprite = CounterfeitEnforcerProjectedSprite.new(@viewport, @character)
    end
  end

  def update_effects
    state = CounterfeitShinies.enforcer_chase_state
    return if !state || state[:map_id] != @map.map_id
    return if !@character || !@sprite || @sprite.disposed?
    if @character.moving? && Graphics.frame_count - state[:last_dust_frame].to_i >= CounterfeitShinies::Config::ENFORCER_CHASE_DUST_INTERVAL
      if $scene && $scene.respond_to?(:spriteset) && $scene.spriteset
        $scene.spriteset.addUserAnimation(Settings::DUST_ANIMATION_ID, @character.x, @character.y, true, 1)
      end
      state[:last_dust_frame] = Graphics.frame_count
    end
    if CounterfeitShinies.enforcer_chase_close?(state) &&
       Graphics.frame_count - state[:last_alert_frame].to_i >= CounterfeitShinies::Config::ENFORCER_CHASE_ALERT_INTERVAL
      if $scene && $scene.respond_to?(:spriteset) && $scene.spriteset
        $scene.spriteset.addUserAnimation(Settings::EXCLAMATION_ANIMATION_ID, @character.x, @character.y, true, 2)
      end
      state[:last_alert_frame] = Graphics.frame_count
    end
  end
end

class CounterfeitEnforcerChaseHUD
  def initialize
    @window = Window_AdvancedTextPokemon.newWithSize("", Graphics.width - 176, 0, 176, 64)
    @window.z = 99999
    @window.visible = false
    @last_text = nil
  end

  def disposed?
    return @window.disposed?
  end

  def dispose
    @window.dispose
  end

  def update
    state = CounterfeitShinies.enforcer_chase_state
    if !state || !$game_map || state[:map_id] != $game_map.map_id
      @window.visible = false
      @last_text = nil
      return
    end
    seconds = CounterfeitShinies.enforcer_chase_seconds_left(state)
    gap = CounterfeitShinies.enforcer_chase_gap_label(state)
    text = _INTL("Enforcer Tail\n{1}s / {2}", seconds, gap)
    if text != @last_text
      @window.text = text
      @last_text = text
    end
    @window.visible = true
  end
end

Events.onSpritesetCreate += proc { |_sender, e|
  begin
    spriteset = e[0]
    viewport = e[1]
    spriteset.addUserSprite(CounterfeitEnforcerChaseVisual.new(viewport, spriteset.map))
    spriteset.addUserSprite(CounterfeitEnforcerChaseHUD.new) if spriteset.map == $game_map
  rescue
  end
}

module GameData
  class Species
    class << self
      alias counterfeit_shinies_sprite_bitmap_from_pokemon sprite_bitmap_from_pokemon
      def sprite_bitmap_from_pokemon(pkmn, back = false, species = nil, makeShiny = true)
        bitmap = counterfeit_shinies_sprite_bitmap_from_pokemon(pkmn, back, species, makeShiny)
        return bitmap if !defined?(CounterfeitShinies)
        return CounterfeitShinies.apply_fake_shiny_render!(bitmap, pkmn, makeShiny)
      end
    end
  end
end

class PokeBattle_Battle
  alias counterfeit_shinies_pbSendOut pbSendOut
  def pbSendOut(sendOuts, startBattle = false)
    ret = counterfeit_shinies_pbSendOut(sendOuts, startBattle)
    if $PokemonTemp && $PokemonTemp.counterfeit_shiny_context
      sendOuts.each do |entry|
        idxBattler = entry[0]
        pokemon = entry[1]
        next if (idxBattler & 1) != 0
        CounterfeitShinies.record_battle_use(pokemon)
      end
    end
    return ret
  end
end

alias counterfeit_shinies_pbStartTrade pbStartTrade
def pbStartTrade(pokemonIndex, newpoke, nickname, trainerName, trainerGender = 0, savegame = false)
  ret = counterfeit_shinies_pbStartTrade(
    pokemonIndex, newpoke, nickname, trainerName, trainerGender, savegame
  )
  CounterfeitShinies.strip_trade_counterfeit!(ret)
  return ret
end

alias counterfeit_shinies_pbFuse pbFuse
def pbFuse(pokemon, poke2, splicer_item)
  primary_snapshot = CounterfeitShinies.counterfeit_snapshot(pokemon)
  secondary_snapshot = CounterfeitShinies.counterfeit_snapshot(poke2)
  mixed_real_shine = (
    (pokemon.shiny? && !CounterfeitShinies.counterfeit?(pokemon)) ||
    (poke2.shiny? && !CounterfeitShinies.counterfeit?(poke2)) ||
    CounterfeitShinies.external_fake_shiny?(pokemon) ||
    CounterfeitShinies.external_fake_shiny?(poke2)
  )
  ret = counterfeit_shinies_pbFuse(pokemon, poke2, splicer_item)
  if ret
    if mixed_real_shine
      CounterfeitShinies.clear_counterfeit!(pokemon)
    else
      merged = CounterfeitShinies.merge_snapshots(primary_snapshot, secondary_snapshot)
      CounterfeitShinies.apply_snapshot!(pokemon, merged, :fusion) if merged
    end
  end
  return ret
end

alias counterfeit_shinies_pbUnfuse pbUnfuse
def pbUnfuse(pokemon, scene, supersplicers, pcPosition = nil)
  snapshot = CounterfeitShinies.counterfeit_snapshot(pokemon)
  before_ids = []
  CounterfeitShinies.each_owned_reference(true, true) do |ref|
    before_ids << ref[:pokemon].object_id
  end
  ret = counterfeit_shinies_pbUnfuse(pokemon, scene, supersplicers, pcPosition)
  if ret && snapshot
    CounterfeitShinies.apply_snapshot!(pokemon, snapshot, :unfusion)
    new_head = nil
    CounterfeitShinies.each_owned_reference(true, true) do |ref|
      next if before_ids.include?(ref[:pokemon].object_id)
      next if ref[:pokemon].equal?(pokemon)
      new_head = ref[:pokemon]
      break
    end
    if new_head
      new_head.counterfeit_shiny_data = nil if new_head.respond_to?(:counterfeit_shiny_data=)
      new_head.fakeshiny = false if new_head.respond_to?(:fakeshiny=)
    end
  end
  return ret
end

class PokemonPartyPanel
  alias counterfeit_shinies_refresh refresh
  def refresh
    counterfeit_shinies_refresh
    return if !@pokemon || @pokemon.egg?
    return if !CounterfeitShinies.render_fake_shiny?(@pokemon)
    return if @pokemon.shiny?
    return if !@overlaysprite || @overlaysprite.disposed?
    return if !@overlaysprite.bitmap || @overlaysprite.bitmap.disposed?
    @overlaysprite.bitmap.fill_rect(56, 32, 40, 40, Color.new(0, 0, 0, 0))
    image_pos = []
    addShinyStarsToGraphicsArray(
      image_pos,
      80,
      48,
      @pokemon.bodyShiny?,
      @pokemon.headShiny?,
      @pokemon.debugShiny?,
      0,
      0,
      16,
      16,
      false,
      false,
      true,
      CounterfeitShinies.shiny_star_payload(@pokemon)
    )
    pbDrawImagePositions(@overlaysprite.bitmap, image_pos)
  end
end

class PokemonSummary_Scene
  alias counterfeit_shinies_drawPage drawPage
  def drawPage(page)
    counterfeit_shinies_drawPage(page)
    return if !@sprites || !@sprites["overlay"] || !@sprites["overlay"].bitmap
    if CounterfeitShinies.render_fake_shiny?(@pokemon) && !@pokemon.shiny?
      image_pos = []
      addShinyStarsToGraphicsArray(
        image_pos,
        2,
        134,
        @pokemon.bodyShiny?,
        @pokemon.headShiny?,
        @pokemon.debugShiny?,
        nil,
        nil,
        nil,
        nil,
        true,
        false,
        true,
        CounterfeitShinies.shiny_star_payload(@pokemon)
      )
      pbDrawImagePositions(@sprites["overlay"].bitmap, image_pos)
    end
    return if !CounterfeitShinies.counterfeit?(@pokemon)
    overlay = @sprites["overlay"].bitmap
    base = Color.new(240, 104, 96)
    shadow = Color.new(88, 40, 40)
    value_text = CounterfeitShinies.format_money(CounterfeitShinies.market_value(@pokemon))
    pbDrawShadowText(
      overlay, 214, 54, 160, 24,
      CounterfeitShinies::Config::SUMMARY_TAG, base, shadow
    )
    pbDrawShadowText(
      overlay, 214, 74, 160, 24,
      value_text, Color.new(232, 232, 232), Color.new(72, 72, 72)
    )
  end
end
