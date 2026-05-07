if defined?($freedom_of_exploration_loaded) && $freedom_of_exploration_loaded
  puts "[Freedom Exploration] Duplicate load skipped."
  return
end
$freedom_of_exploration_loaded = true

module FreedomExploration
  ROUTE_1_MAP_ID = 78
  SECRET_GARDEN_MAP_ID = 185
  SECRET_GARDEN_ROUTE_EVENT_ID = 5
  SECRET_GARDEN_STORY_SWITCH = 60
  SECRET_GARDEN_DISCOVERY_VARIABLE = 193
  SECRET_GARDEN_ENTRY_X = 36
  SECRET_GARDEN_ENTRY_Y = 9
  SECRET_GARDEN_DESTINATION = [SECRET_GARDEN_MAP_ID, 13, 9, 2]

  SHOP_STOCK = [
    [:ESCAPEROPE, 700],
    [:LANTERN, 1000],
    [:MACHETE, 1500],
    [:PICKAXE, 1500],
    [:LEVER, 2000],
    [:SURFBOARD, 5000],
    [:TELEPORTER, 6000],
    [:SCUBAGEAR, 8000],
    [:BICYCLE, 10000],
    [:CLIMBINGGEAR, 12000]
  ]

  def self.open_pc_menu
    command = 0
    loop do
      command = pbShowCommandsWithHelp(
        nil,
        [
          _INTL("Buy Exploration Gear"),
          _INTL("Review Safety Rules"),
          _INTL("Log Off")
        ],
        [
          _INTL("Buy the traversal items that normally arrive much later in the story."),
          _INTL("Review the travel protections this mod enables before you route-break."),
          _INTL("Return to the previous menu.")
        ],
        -1,
        command
      )
      case command
      when 0 then open_shop
      when 1 then show_safety_rules
      else        break
      end
    end
  end

  def self.open_shop
    old_prices = ($game_temp && $game_temp.mart_prices) ? $game_temp.mart_prices.clone : {}
    $game_temp.mart_prices = old_prices.clone
    SHOP_STOCK.each do |item, price|
      item_id = GameData::Item.get(item).id
      $game_temp.mart_prices[item_id] = [price, 0]
    end
    pbPokemonMart(
      SHOP_STOCK.map { |item, _price| item },
      _INTL("Freedom of exploration inventory online. What do you need?"),
      true
    )
  ensure
    $game_temp.mart_prices = old_prices || {}
  end

  def self.show_safety_rules
    pbMessage(_INTL("This mod keeps Route 1's Secret Garden entrance active even before its story flag turns on."))
    pbMessage(_INTL("If you travel with a follower, the follower is dismissed before Surf, Dive, Fly, Teleporter, Dig, or Escape Rope travel so you don't get stranded."))
    pbMessage(_INTL("If Dig or Escape Rope doesn't have a cave escape point, it falls back to your last healing spot instead."))
  end

  def self.has_companions?
    return false if !$game_player || !$PokemonGlobal
    return $game_player.pbHasDependentEvents?
  end

  def self.dismiss_companions_for_travel(show_message = true)
    return false if !has_companions?
    pbMessage(_INTL("Your companion heads back so you can travel safely.")) if show_message
    pbRemoveDependencies if defined?(pbRemoveDependencies)
    return true
  end

  def self.escape_destination
    escape = ($PokemonGlobal.escapePoint rescue nil)
    return escape if escape && !escape.empty?
    map_id = ($PokemonGlobal.pokecenterMapId rescue nil)
    x = ($PokemonGlobal.pokecenterX rescue nil)
    y = ($PokemonGlobal.pokecenterY rescue nil)
    direction = ($PokemonGlobal.pokecenterDirection rescue 2)
    return nil if !map_id || !x || !y
    return [map_id, x, y, direction]
  end

  def self.escape_destination_name(destination)
    return _INTL("your last safe place") if !destination || destination.empty?
    return pbGetMapNameFromId(destination[0])
  end

  def self.use_escape_destination(destination)
    return false if !destination || destination.empty?
    pbFadeOutIn {
      pbCancelVehicles
      $game_temp.player_new_map_id = destination[0]
      $game_temp.player_new_x = destination[1]
      $game_temp.player_new_y = destination[2]
      $game_temp.player_new_direction = destination[3]
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
    }
    pbEraseEscapePoint
    return true
  end

  def self.secret_garden_touch?
    return false if !$game_map || !$game_player
    return false if $game_map.map_id != ROUTE_1_MAP_ID
    return false if $game_player.x != SECRET_GARDEN_ENTRY_X || $game_player.y != SECRET_GARDEN_ENTRY_Y
    return false if !secret_garden_access_available?
    return true
  end

  def self.secret_garden_access_available?
    return true if secret_garden_discovered?
    return true if $game_switches && $game_switches[SECRET_GARDEN_STORY_SWITCH]
    return true if $Trainer && $Trainer.badge_count >= 1
    return true
  end

  def self.secret_garden_front_touch?(player, dir)
    return false if !player || !$game_map
    return false if $game_map.map_id != ROUTE_1_MAP_ID
    return false if !secret_garden_access_available?
    x_offset = (dir == 4) ? -1 : (dir == 6) ? 1 : 0
    y_offset = (dir == 8) ? -1 : (dir == 2) ? 1 : 0
    return player.x + x_offset == SECRET_GARDEN_ENTRY_X &&
           player.y + y_offset == SECRET_GARDEN_ENTRY_Y
  end

  def self.secret_garden_discovered?
    return false if !$game_self_switches
    return $game_self_switches[[ROUTE_1_MAP_ID, SECRET_GARDEN_ROUTE_EVENT_ID, "A"]] ? true : false
  end

  def self.mark_secret_garden_discovered
    return if secret_garden_discovered?
    pbSet(SECRET_GARDEN_DISCOVERY_VARIABLE, pbGet(SECRET_GARDEN_DISCOVERY_VARIABLE) + 1)
    old_value = $game_self_switches[[ROUTE_1_MAP_ID, SECRET_GARDEN_ROUTE_EVENT_ID, "A"]]
    $game_self_switches[[ROUTE_1_MAP_ID, SECRET_GARDEN_ROUTE_EVENT_ID, "A"]] = true
    if old_value != true && $MapFactory && $MapFactory.hasMap?(ROUTE_1_MAP_ID)
      $MapFactory.getMap(ROUTE_1_MAP_ID, false).need_refresh = true
    elsif $game_map && $game_map.map_id == ROUTE_1_MAP_ID
      $game_map.need_refresh = true
    end
  end

  def self.enter_secret_garden
    return if @secret_garden_transfer_in_progress
    @secret_garden_transfer_in_progress = true
    mark_secret_garden_discovered
    pbFadeOutIn {
      pbCancelVehicles
      $game_temp.player_new_map_id = SECRET_GARDEN_DESTINATION[0]
      $game_temp.player_new_x = SECRET_GARDEN_DESTINATION[1]
      $game_temp.player_new_y = SECRET_GARDEN_DESTINATION[2]
      $game_temp.player_new_direction = SECRET_GARDEN_DESTINATION[3]
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
    }
  ensure
    @secret_garden_transfer_in_progress = false
  end
end

class FreedomExplorationPC
  def shouldShow?
    return true
  end

  def name
    return _INTL("Freedom Travel")
  end

  def access
    pbMessage(_INTL("\\se[PC access]Connected to the Freedom Travel network."))
    FreedomExploration.open_pc_menu
  end
end

if defined?(PokemonPCList) && (!$freedom_exploration_pc_registered rescue true)
  PokemonPCList.registerPC(FreedomExplorationPC.new)
  $freedom_exploration_pc_registered = true
end

if !$freedom_exploration_secret_garden_hook_registered
  Events.onStepTaken += proc {
    next unless FreedomExploration.secret_garden_touch?
    FreedomExploration.enter_secret_garden
  }
  $freedom_exploration_secret_garden_hook_registered = true
end

class Game_Player
  alias freedom_exploration_original_check_event_trigger_touch check_event_trigger_touch unless method_defined?(:freedom_exploration_original_check_event_trigger_touch)

  def check_event_trigger_touch(dir)
    if FreedomExploration.secret_garden_front_touch?(self, dir)
      FreedomExploration.enter_secret_garden
      return true
    end
    freedom_exploration_original_check_event_trigger_touch(dir)
  end
end

HiddenMoveHandlers::CanUseMove.add(:DIG, proc { |_move, _pkmn, showmsg|
  destination = FreedomExploration.escape_destination
  if !destination || destination.empty?
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::ConfirmUseMove.add(:DIG, proc { |_move, _pkmn|
  destination = FreedomExploration.escape_destination
  next false if !destination || destination.empty?
  mapname = FreedomExploration.escape_destination_name(destination)
  next pbConfirmMessage(_INTL("Want to escape from here and return to {1}?", mapname))
})

HiddenMoveHandlers::UseMove.add(:DIG, proc { |move, pokemon|
  destination = FreedomExploration.escape_destination
  next false if !destination || destination.empty?
  FreedomExploration.dismiss_companions_for_travel
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  next FreedomExploration.use_escape_destination(destination)
})

ItemHandlers::UseFromBag.add(:ESCAPEROPE, proc { |_item|
  destination = FreedomExploration.escape_destination
  if destination && !destination.empty?
    next 4
  end
  pbMessage(_INTL("Can't use that here."))
  next 0
})

ItemHandlers::ConfirmUseInField.add(:ESCAPEROPE, proc { |_item|
  destination = FreedomExploration.escape_destination
  if !destination || destination.empty?
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  mapname = FreedomExploration.escape_destination_name(destination)
  next pbConfirmMessage(_INTL("Want to escape from here and return to {1}?", mapname))
})

ItemHandlers::UseInField.add(:ESCAPEROPE, proc { |item|
  destination = FreedomExploration.escape_destination
  if !destination || destination.empty?
    pbMessage(_INTL("Can't use that here."))
    next 0
  end
  FreedomExploration.dismiss_companions_for_travel
  pbUseItemMessage(item)
  FreedomExploration.use_escape_destination(destination)
  next 3
})

alias freedom_exploration_original_pbCanUseFly pbCanUseFly unless defined?(freedom_exploration_original_pbCanUseFly)
def pbCanUseFly(showmsg)
  return false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_TELEPORT, showmsg)
  if !GameData::MapMetadata.exists?($game_map.map_id) ||
     !GameData::MapMetadata.get($game_map.map_id).outdoor_map
    pbMessage(_INTL("Can't use that here.")) if showmsg
    return false
  end
  return true
end

alias freedom_exploration_original_pbFly pbFly unless defined?(freedom_exploration_original_pbFly)
def pbFly(move, pokemon)
  return false if !$PokemonTemp.flydata
  FreedomExploration.dismiss_companions_for_travel if FreedomExploration.has_companions?
  return freedom_exploration_original_pbFly(move, pokemon)
end

HiddenMoveHandlers::CanUseMove.add(:SURF, proc { |_move, _pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_SURF, showmsg)
  if $PokemonGlobal.surfing
    pbMessage(_INTL("You're already surfing.")) if showmsg
    next false
  end
  if GameData::MapMetadata.exists?($game_map.map_id) &&
     GameData::MapMetadata.get($game_map.map_id).always_bicycle
    pbMessage(_INTL("Let's enjoy cycling!")) if showmsg
    next false
  end
  if !$game_player.pbFacingTerrainTag.can_surf_freely ||
     !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
    pbMessage(_INTL("No surfing here!")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:SURF, proc { |move, pokemon|
  $game_temp.in_menu = false
  pbCancelVehicles
  FreedomExploration.dismiss_companions_for_travel(false) if FreedomExploration.has_companions?
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  surfbgm = GameData::Metadata.get.surf_BGM
  pbCueBGM(surfbgm, 0.5) if surfbgm
  surfing_poke = pokemon if pokemon
  pbStartSurfing(surfing_poke)
  next true
})

alias freedom_exploration_original_pbSurf pbSurf unless defined?(freedom_exploration_original_pbSurf)
def pbSurf
  return false if $game_player.pbFacingEvent
  return false if $PokemonGlobal.diving || $PokemonGlobal.surfing
  move = :SURF
  movefinder = $Trainer.get_pokemon_with_move(move)
  if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_SURF, false) || (!$DEBUG && !movefinder)
    return false if $PokemonBag.pbQuantity(:SURFBOARD) <= 0
  end
  FreedomExploration.dismiss_companions_for_travel(false) if FreedomExploration.has_companions?
  if $PokemonSystem.quicksurf == 1
    surfbgm = GameData::Metadata.get.surf_BGM
    pbCueBGM(surfbgm, 0.5) if surfbgm
    surfing_poke = movefinder.species if movefinder
    pbStartSurfing(surfing_poke)
    return true
  end
  if pbConfirmMessage(_INTL("The water is a deep blue...\nWould you like to surf on it?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbCancelVehicles
    pbHiddenMoveAnimation(movefinder)
    surfbgm = GameData::Metadata.get.surf_BGM
    pbCueBGM(surfbgm, 0.5) if surfbgm && !Settings::MAPS_WITHOUT_SURF_MUSIC.include?($game_map.map_id)
    surfing_poke = movefinder.species if movefinder
    pbStartSurfing(surfing_poke)
    return true
  end
  return false
end

alias freedom_exploration_original_pbDive pbDive unless defined?(freedom_exploration_original_pbDive)
def pbDive
  FreedomExploration.dismiss_companions_for_travel(false) if FreedomExploration.has_companions?
  return freedom_exploration_original_pbDive
end

alias freedom_exploration_original_pbSurfacing pbSurfacing unless defined?(freedom_exploration_original_pbSurfacing)
def pbSurfacing
  FreedomExploration.dismiss_companions_for_travel(false) if FreedomExploration.has_companions?
  return freedom_exploration_original_pbSurfacing
end

puts "[Freedom Exploration] Loaded."