module TravelExpansionFramework
  module_function

  def unbreakable_ties_expansion_ids
    ids = []
    ids << (defined?(UNBREAKABLE_TIES_EXPANSION_ID) ? UNBREAKABLE_TIES_EXPANSION_ID : "unbreakable_ties")
    ids.concat(defined?(UNBREAKABLE_TIES_LEGACY_EXPANSION_IDS) ? UNBREAKABLE_TIES_LEGACY_EXPANSION_IDS : ["unbreakableties"])
    return ids.compact.map(&:to_s).uniq
  rescue
    return ["unbreakable_ties", "unbreakableties"]
  end

  def unbreakable_ties_active_now?(map_id = nil)
    if respond_to?(:active_project_expansion_id)
      return !active_project_expansion_id(unbreakable_ties_expansion_ids, map_id).nil?
    end
    marker = current_expansion_marker.to_s if respond_to?(:current_expansion_marker)
    return unbreakable_ties_expansion_ids.include?(marker.to_s)
  rescue
    return false
  end

  def unbreakable_ties_switch_on?(switch_id)
    return false if !defined?($game_switches) || !$game_switches
    return $game_switches[switch_id.to_i] == true
  rescue
    return false
  end

  def unbreakable_ties_point_multiplier
    multiplier = 1.0
    multiplier *= 1.5 if unbreakable_ties_switch_on?(2092) # Nuzlocke
    multiplier *= 1.1 if unbreakable_ties_switch_on?(2097) # Lucariolocke
    if unbreakable_ties_switch_on?(2096)                  # Radical
      multiplier *= 1.75
    elsif unbreakable_ties_switch_on?(2095)               # Hard
      multiplier *= 1.25
    elsif unbreakable_ties_switch_on?(2094)               # Normal
      multiplier *= 1.0
    elsif unbreakable_ties_switch_on?(2093)               # Easy
      multiplier *= 0.75
    end
    $game_variables[995] = multiplier if defined?($game_variables) && $game_variables
    return multiplier
  rescue => e
    log("Unbreakable Ties point multiplier failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return 1.0
  end

  def unbreakable_ties_apply_speed!(speed_id = 0)
    imported_index = integer(speed_id, 0) if respond_to?(:integer)
    imported_index = speed_id.to_i if imported_index.nil?
    imported_index = 0 if imported_index < 0
    host_speed = [[imported_index + 1, 1].max, 10].min
    $GameSpeed = host_speed
    $frame = 0
    if defined?($PokemonSystem) && $PokemonSystem
      $PokemonSystem.speedvaluedef = host_speed - 1 if $PokemonSystem.respond_to?(:speedvaluedef=)
      $PokemonSystem.speedvalue = host_speed - 1 if $PokemonSystem.respond_to?(:speedvalue=) && host_speed > 1
    end
    if defined?($game_switches) && $game_switches && $game_switches[996]
      $CanToggle = false
      $isSpeedDesactivated = true
      $GameSpeed = 1
    else
      $CanToggle = true
      $isSpeedDesactivated = false
    end
    updateTitle if defined?(updateTitle)
    log("[unbreakable_ties] applied imported ChangeSpeed #{speed_id.inspect} as x#{$GameSpeed}") if respond_to?(:log)
    return true
  rescue => e
    $GameSpeed = 1
    $frame = 0
    log("[unbreakable_ties] ChangeSpeed fallback after #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end
end

class ChangeSpeed
  def pbChangeSpeed(speed_id = 0, *_args)
    return TravelExpansionFramework.unbreakable_ties_apply_speed!(speed_id) if defined?(TravelExpansionFramework) &&
                                                                               TravelExpansionFramework.respond_to?(:unbreakable_ties_apply_speed!)
    $GameSpeed = [speed_id.to_i + 1, 1].max
    $frame = 0
    return true
  rescue
    return false
  end
end unless defined?(ChangeSpeed)

class Interpreter
  const_set(:ChangeSpeed, ::ChangeSpeed) if defined?(::ChangeSpeed) && !const_defined?(:ChangeSpeed, false)

  def getPointMultiplier
    return TravelExpansionFramework.unbreakable_ties_point_multiplier
  end if !method_defined?(:getPointMultiplier)
end

module Kernel
  def getPointMultiplier
    return TravelExpansionFramework.unbreakable_ties_point_multiplier
  end if !method_defined?(:getPointMultiplier)
end
