# MoveInCircles main.rb
# F5 toggles a compact auto-walk loop tuned for encounters and egg steps.

MOVE_IN_CIRCLES = 1669

module MoveInCircles
  DIRECTIONS = [6, 2, 4, 8].freeze
  ENCOUNTER_STEP_DELAY = 0.10
  NORMAL_STEP_DELAY = 0.14
  BLOCKED_STEP_DELAY = 0.12

  module_function

  def enabled?
    return false if !$game_switches
    return $game_switches[MOVE_IN_CIRCLES]
  end

  def clock_now
    return System.uptime if defined?(System) && System.respond_to?(:uptime)
    return Graphics.frame_count.to_f / Graphics.frame_rate
  end

  def chat_typing?
    return defined?($chat_window) && $chat_window && $chat_window.input_mode
  end

  def mini_update_active?
    return true if defined?($PokemonTemp) && $PokemonTemp && $PokemonTemp.respond_to?(:miniupdate) && $PokemonTemp.miniupdate
    return true if $game_temp && $game_temp.respond_to?(:in_mini_update) && $game_temp.in_mini_update
    return false
  end

  def can_autowalk?(player)
    return false if !enabled?
    return false if !player
    return false if player.move_route_forcing
    return false if player.moving? || player.jumping?
    return false if pbMapInterpreterRunning?
    return false if $game_temp.message_window_showing || $game_temp.in_menu
    return false if mini_update_active? || chat_typing?
    return false if defined?($PokemonTemp) && $PokemonTemp && $PokemonTemp.encounterTriggered
    next_move_at = player.instance_variable_get(:@circle_move_ready_at) || 0.0
    return clock_now >= next_move_at
  end

  def reset!(player)
    return if !player
    player.instance_variable_set(:@circle_move_ready_at, 0.0)
    player.instance_variable_set(:@circle_step, 0)
  end

  def schedule_next_move(player, delay)
    player.instance_variable_set(:@circle_move_ready_at, clock_now + delay)
  end

  def advance_circle!(player, chosen_direction = nil)
    current_index = player.instance_variable_get(:@circle_step) || 0
    direction_index = chosen_direction ? DIRECTIONS.index(chosen_direction) : current_index
    next_index = ((direction_index || current_index) + 1) % DIRECTIONS.length
    player.instance_variable_set(:@circle_step, next_index)
  end

  def offset_for(direction)
    case direction
    when 4 then [-1, 0]
    when 6 then [1, 0]
    when 8 then [0, -1]
    when 2 then [0, 1]
    else        [0, 0]
    end
  end

  def step_encounters_possible_at?(x, y)
    return false if !$PokemonEncounters || !$game_map || !$game_map.valid?(x, y)
    return true if $PokemonGlobal.surfing
    terrain_tag = $game_map.terrain_tag(x, y)
    return false if terrain_tag.ice
    return true if $PokemonEncounters.has_cave_encounters?
    return true if $PokemonEncounters.has_land_encounters? && terrain_tag.land_wild_encounters
    return false
  rescue StandardError
    return false
  end

  def encounter_delay(player)
    return ENCOUNTER_STEP_DELAY if step_encounters_possible_at?(player.x, player.y)
    return NORMAL_STEP_DELAY
  end

  def preferred_direction(player)
    current_index = player.instance_variable_get(:@circle_step) || 0
    primary_direction = DIRECTIONS[current_index % DIRECTIONS.length]
    return primary_direction if !step_encounters_possible_at?(player.x, player.y)

    rotated_directions = DIRECTIONS.rotate(current_index % DIRECTIONS.length)
    rotated_directions.each do |direction|
      next if !player.can_move_in_direction?(direction)
      dx, dy = offset_for(direction)
      next if !step_encounters_possible_at?(player.x + dx, player.y + dy)
      return direction
    end
    return primary_direction
  end

  def walk_step(player)
    direction = preferred_direction(player)
    old_x = player.x
    old_y = player.y
    case direction
    when 4 then player.move_left
    when 6 then player.move_right
    when 8 then player.move_up
    when 2 then player.move_down
    end
    moved = player.moving? || player.x != old_x || player.y != old_y
    advance_circle!(player, direction)
    schedule_next_move(player, moved ? encounter_delay(player) : BLOCKED_STEP_DELAY)
  end
end

# --- F5 shortcut to toggle Move In Circles ---
module MoveInCirclesHotkey
  module_function

  def update
    return if !Input.trigger?(Input::F5)
    $game_switches[MOVE_IN_CIRCLES] = !$game_switches[MOVE_IN_CIRCLES]
    msg = $game_switches[MOVE_IN_CIRCLES] ? "Move In Circles: ON" : "Move In Circles: OFF"
    pbMessage(msg) if defined?(pbMessage)
    MoveInCircles.reset!($game_player)
  end
end

class Scene_Map
  alias moveincircles_update update unless method_defined?(:moveincircles_update)

  def update(*args)
    MoveInCirclesHotkey.update if defined?(MoveInCirclesHotkey)
    moveincircles_update(*args)
  end
end

class Game_Player < Game_Character
  alias moveincircles_update_command_new update_command_new unless method_defined?(:moveincircles_update_command_new)

  def update_command_new
    if MoveInCircles.can_autowalk?(self)
      MoveInCircles.walk_step(self)
      @lastdir = 0
      return
    end

    MoveInCircles.reset!(self) if !MoveInCircles.enabled?
    moveincircles_update_command_new
  end
end
