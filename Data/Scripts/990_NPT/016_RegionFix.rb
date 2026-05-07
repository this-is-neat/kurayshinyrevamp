#===============================================================================
# NPT Region Fix
#
# The vanilla region-check functions use hardcoded dex number ranges.
# NPT Pokemon have dex numbers 502+ and never match. They do have a correct
# `generation` field in their GameData::Species entry.
#
# This patches each region function to fall back to the `generation` field
# when a dex number is outside the vanilla range (> 501).
#===============================================================================

# Returns the generation number for an NPT dex number (502+), nil otherwise.
NPT_GEN_CACHE = {}
def npt_generation_for_dex(dex_num)
  return nil if dex_num.nil? || dex_num <= 0 || dex_num <= 501
  return NPT_GEN_CACHE[dex_num] if NPT_GEN_CACHE.key?(dex_num)
  gen = nil
  GameData::Species.each do |s|
    next unless s.id_number == dex_num && s.form == 0
    gen = s.generation.to_i
    break
  end
  NPT_GEN_CACHE[dex_num] = gen
  gen
rescue
  nil
end

# Returns all relevant dex numbers for a species symbol/integer.
# For fused species (B{n}H{n} symbols), also returns the component dex numbers.
def npt_dex_numbers_for(species)
  nums = []
  sym = species.is_a?(Symbol) ? species : nil

  # For fused species symbols like :B502H1, decompose to components
  if sym && sym.to_s.match?(/\AB\d+H\d+\z/)
    m = sym.to_s.match(/\AB(\d+)H(\d+)\z/)
    nums << m[1].to_i
    nums << m[2].to_i
  else
    dex = getDexNumberForSpecies(species) rescue nil
    nums << dex if dex
  end

  nums.compact
end

alias _npt_original_isInKantoGeneration isInKantoGeneration
def isInKantoGeneration(dexNumber)
  _npt_original_isInKantoGeneration(dexNumber) || npt_generation_for_dex(dexNumber) == 1
end

alias _npt_original_isInJohtoGeneration isInJohtoGeneration
def isInJohtoGeneration(dexNumber)
  _npt_original_isInJohtoGeneration(dexNumber) || npt_generation_for_dex(dexNumber) == 2
end

# isKantoPokemon and isJohtoPokemon call the above two, so they're covered.

alias _npt_original_isHoennPokemon isHoennPokemon
def isHoennPokemon(species)
  (begin; _npt_original_isHoennPokemon(species); rescue; false; end) ||
    npt_dex_numbers_for(species).any? { |d| npt_generation_for_dex(d) == 3 }
end

alias _npt_original_isSinnohPokemon isSinnohPokemon
def isSinnohPokemon(species)
  (begin; _npt_original_isSinnohPokemon(species); rescue; false; end) ||
    npt_dex_numbers_for(species).any? { |d| npt_generation_for_dex(d) == 4 }
end

alias _npt_original_isUnovaPokemon isUnovaPokemon
def isUnovaPokemon(species)
  (begin; _npt_original_isUnovaPokemon(species); rescue; false; end) ||
    npt_dex_numbers_for(species).any? { |d| npt_generation_for_dex(d) == 5 }
end

alias _npt_original_isKalosPokemon isKalosPokemon
def isKalosPokemon(species)
  (begin; _npt_original_isKalosPokemon(species); rescue; false; end) ||
    npt_dex_numbers_for(species).any? { |d| npt_generation_for_dex(d) == 6 }
end

alias _npt_original_isAlolaPokemon isAlolaPokemon
def isAlolaPokemon(species)
  (begin; _npt_original_isAlolaPokemon(species); rescue; false; end) ||
    npt_dex_numbers_for(species).any? { |d| npt_generation_for_dex(d) == 7 }
end
