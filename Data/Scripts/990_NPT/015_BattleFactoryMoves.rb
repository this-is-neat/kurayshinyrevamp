#===============================================================================
# NPT Hook: Battle Factory — STAB NPT moves + priority selection
#===============================================================================
# 1. pbGetLegalMoves2 override:
#    - Includes ALL tutor moves (not just TM-teachable)
#    - Injects STAB-matching NPT moves (id 6001+) into the legal pool
#      even if the species doesn't naturally learn them
#    - NPT STAB moves get high weight (+4) so they're picked often
#
# 2. pbRandomPokemonFromRule override:
#    - Prioritizes picking NPT moves first (1-2 slots)
#    - Fills remaining slots from the normal pool
#
# 3. True Randomness mode (BattleFactoryData#pbPrepareRentals hook):
#    - Player is prompted ON/OFF before rentals are generated
#    - When ON: every Pokemon (rentals + opponent) gets a random species from
#      ALL of GameData::Species (including NPT-registered ones, form 0 only)
#      and 4 fully random moves drawn from the entire move pool
#===============================================================================

#-------------------------------------------------------------------------------
# True Randomness — global flag, reset each factory challenge entry
#-------------------------------------------------------------------------------
$NPT_FACTORY_TRUE_RANDOM = false

# Flat pool of all usable move IDs, built once per session
$nptAllMovePool = nil
# Flat pool of all base-form species IDs (symbols), built once per session
$nptAllSpeciesPool = nil

# All species with fusion sprites: base KIF (1-501) + NPT (502-1198)
NPT_BASE_KIF_COUNT = 1198

def npt_build_all_species_pool
  return if $nptAllSpeciesPool
  $nptAllSpeciesPool = []
  GameData::Species.each do |sp|
    next if sp.form != 0
    next if sp.id_number < 1 || sp.id_number > 1197
    $nptAllSpeciesPool << sp.id
  end
end

# Returns a random species: 50% chance of a dual fusion (head+body each from
# base KIF 1-501), 50% chance of a base/NPT species from the static pool.
def npt_random_factory_species
  head = rand(NPT_BASE_KIF_COUNT) + 1
  body = rand(NPT_BASE_KIF_COUNT) + 1
  return getFusedPokemonIdFromDexNum(body, head)
end

def npt_build_all_move_pool
  return if $nptAllMovePool
  $nptAllMovePool = []
  GameData::Move.each do |m|
    next if [:STRUGGLE, :SKETCH].include?(m.id)
    next if m.base_damage == 0 && m.accuracy == 0 && m.function_code == "000"
    $nptAllMovePool << m.id
  end
end

# Assign 4 random moves from the full pool to a Pokemon
def npt_randomize_moves(pkmn)
  npt_build_all_move_pool
  pool = $nptAllMovePool.dup
  chosen = []
  while chosen.length < Pokemon::MAX_MOVES && !pool.empty?
    idx = rand(pool.length)
    chosen << pool[idx]
    pool.delete_at(idx)
  end
  Pokemon::MAX_MOVES.times do |i|
    pkmn.moves[i] = chosen[i] ? Pokemon::Move.new(chosen[i]) : nil
  end
end

#-------------------------------------------------------------------------------
# Hook BattleFactoryData#pbPrepareRentals — prompt once per challenge entry
#-------------------------------------------------------------------------------
class BattleFactoryData
  alias _npt_original_pbPrepareRentals pbPrepareRentals

  def pbPrepareRentals
    $NPT_FACTORY_TRUE_RANDOM = false
    pbMessage("\\se[]Battle Factory Mode")
    if pbConfirmMessage("Enable TRUE RANDOMNESS?\nAll Pokémon will have completely random moves!")
      $NPT_FACTORY_TRUE_RANDOM = true
      pbMessage("TRUE RANDOMNESS is ON!\nEvery moveset will be pure chaos!")
    else
      pbMessage("Standard mode. Good luck!")
    end
    _npt_original_pbPrepareRentals
  end
end

#-------------------------------------------------------------------------------
# Hook pbBattleFactoryPokemon — randomize species + moves when flag is ON
#-------------------------------------------------------------------------------
alias _npt_original_pbBattleFactoryPokemon pbBattleFactoryPokemon

def pbBattleFactoryPokemon(rules, win_count, swap_count, rentals)
  party = _npt_original_pbBattleFactoryPokemon(rules, win_count, swap_count, rentals)
  if $NPT_FACTORY_TRUE_RANDOM
    npt_build_all_species_pool
    level = rules.ruleset.suggestedLevel
    party.map! do |pkmn|
      species = npt_random_factory_species
      new_pkmn = Pokemon.new(species, level, nil)
      new_pkmn.personalID = rand(2**16) | rand(2**16) << 16
      # Preserve the IV value from the original Pokemon
      GameData::Stat.each_main { |s| new_pkmn.iv[s.id] = pkmn.iv[s.id] }
      new_pkmn.calc_stats
      npt_randomize_moves(new_pkmn)
      new_pkmn
    end
  end
  return party
end

# NPT move ID range
NPT_MOVE_ID_MIN = 6001
NPT_MOVE_ID_MAX = 6999

# Cache of NPT moves grouped by type, built lazily
$nptMovesByType = nil

def npt_build_move_type_cache
  return if $nptMovesByType
  $nptMovesByType = {}
  GameData::Move.each do |m|
    next if !m.id_number || m.id_number < NPT_MOVE_ID_MIN || m.id_number > NPT_MOVE_ID_MAX
    next if m.base_damage == 0  # skip status moves — STAB only matters for damage
    type = m.type
    $nptMovesByType[type] ||= []
    $nptMovesByType[type].push(m.id) if !$nptMovesByType[type].include?(m.id)
  end
end

# Check if a move ID is an NPT move
def isNPTMove?(move_id)
  md = GameData::Move.try_get(move_id)
  return false if !md
  return md.id_number >= NPT_MOVE_ID_MIN && md.id_number <= NPT_MOVE_ID_MAX
end

#===============================================================================
# Override pbGetLegalMoves2 — add STAB NPT moves to the legal pool
#===============================================================================
if defined?(:pbGetLegalMoves2)
  alias _npt_original_pbGetLegalMoves2 pbGetLegalMoves2
end

def pbGetLegalMoves2(species, maxlevel)
  # In true randomness mode, moves are assigned randomly after — skip learnset computation
  return [] if $NPT_FACTORY_TRUE_RANDOM

  species_data = GameData::Species.try_get(species)
  moves = []
  return moves if !species_data

  # Level-up moves up to maxlevel
  species_data.moves.each { |m| addMove(moves, m[1], 2) if m[0] <= maxlevel }

  # Build TM move list (cached)
  if !$tmMoves
    $tmMoves = []
    GameData::Item.each { |i| $tmMoves.push(i.move) if i.is_machine? }
  end

  # ALL tutor moves — not just TM-teachable ones
  species_data.tutor_moves.each { |m| addMove(moves, m, 0) }

  # Egg moves from baby species (guard against fused/invalid species)
  begin
    babyspecies = babySpecies(species)
    baby_data = GameData::Species.try_get(babyspecies)
    baby_data.egg_moves.each { |m| addMove(moves, m, 2) } if baby_data
  rescue; end

  #---------------------------------------------------------------------------
  # NPT STAB injection: add NPT damaging moves that match this species' types
  #---------------------------------------------------------------------------
  npt_build_move_type_cache
  type1 = species_data.type1
  type2 = species_data.type2 || type1
  stab_types = [type1, type2].uniq

  stab_types.each do |t|
    npt_moves = $nptMovesByType[t]
    next if !npt_moves
    npt_moves.each do |mid|
      # High weight (base 4) so NPT moves appear frequently in the pool
      addMove(moves, mid, 4)
    end
  end

  #---------------------------------------------------------------------------
  # Filter out weaker/redundant moves (same logic as original)
  #---------------------------------------------------------------------------
  movedatas = []
  for move in moves
    md = GameData::Move.try_get(move)
    movedatas.push([move, md]) if md
  end
  moves.select! { |m| GameData::Move.try_get(m) }

  deleteAll = proc { |a, item|
    while a.include?(item)
      a.delete(item)
    end
  }

  for move in moves
    md = GameData::Move.try_get(move)
    next if !md
    for move2 in movedatas
      if md.function_code == "0A5" && move2[1].function_code == "000" &&
         md.type == move2[1].type && md.base_damage >= move2[1].base_damage
        deleteAll.call(moves, move2[0])
      elsif md.function_code == move2[1].function_code && md.base_damage == 0 &&
         move2[1].base_damage == 0 && md.accuracy > move2[1].accuracy
        deleteAll.call(moves, move2[0])
      elsif md.function_code == "006" && move2[1].function_code == "005"
        deleteAll.call(moves, move2[0])
      elsif md.function_code == move2[1].function_code && md.base_damage != 0 &&
         md.type == move2[1].type &&
         (md.total_pp == 15 || md.total_pp == 10 || md.total_pp == move2[1].total_pp) &&
         (md.base_damage > move2[1].base_damage ||
         (md.base_damage == move2[1].base_damage && md.accuracy > move2[1].accuracy))
        deleteAll.call(moves, move2[0])
      end
    end
  end

  return moves
end

#===============================================================================
# Override pbRandomPokemonFromRule — prioritize NPT moves in selection
#===============================================================================
alias _npt_original_pbRandomPokemonFromRule pbRandomPokemonFromRule

def pbRandomPokemonFromRule(rules, trainer)
  # Let the original generate the Pokemon (which calls our patched pbGetLegalMoves2)
  pkmn = _npt_original_pbRandomPokemonFromRule(rules, trainer)
  return pkmn if !pkmn

  # Now try to swap in NPT STAB moves where possible
  species = pkmn.species
  species_data = GameData::Species.try_get(species)
  return pkmn if !species_data

  type1 = species_data.type1
  type2 = species_data.type2 || type1
  stab_types = [type1, type2].uniq

  # Get the legal move pool for this species
  level = pkmn.level
  $legalMoves = {} if level != $legalMovesLevel
  $legalMovesLevel = level
  $legalMoves[species] = pbGetLegalMoves2(species, level) if !$legalMoves[species]
  pool = $legalMoves[species]
  return pkmn if !pool || pool.empty?

  # Find NPT STAB moves in the pool (deduplicated)
  npt_stab = (pool | []).select { |mid| isNPTMove?(mid) && stab_types.include?(GameData::Move.get(mid).type) }
  return pkmn if npt_stab.empty?

  current_moves = []
  Pokemon::MAX_MOVES.times do |i|
    m = pkmn.moves[i]
    current_moves.push(m ? m.id : nil)
  end

  # Determine preferred category from base stats: Attack vs SpAtk
  # base_stats: [HP, ATK, DEF, SPATK, SPDEF, SPD]
  bs = species_data.base_stats
  atk  = bs[1] || 0
  spatk = bs[3] || 0
  # 0 = physical, 1 = special, nil = mixed (equal stats)
  preferred_cat = atk > spatk ? 0 : (spatk > atk ? 1 : nil)

  # Score every (npt_move, slot) pair, then pick randomly weighted by score
  slots_replaced = 0
  max_npt_slots = [2, npt_stab.length].min

  max_npt_slots.times do
    # Build candidates: [npt_move, slot_index, score]
    candidates = []

    npt_stab.each do |npt_move|
      next if current_moves.include?(npt_move)
      npt_data = GameData::Move.try_get(npt_move)
      next if !npt_data

      current_moves.each_with_index do |cm, i|
        next if !cm
        cmd = GameData::Move.try_get(cm)
        next if !cmd
        next if isNPTMove?(cm)
        next if cmd.base_damage == 0

        score = 0
        # Same-type and NPT is stronger
        if cmd.type == npt_data.type && npt_data.base_damage > cmd.base_damage
          score = npt_data.base_damage - cmd.base_damage + 200
        # Weak Normal filler (< 80 BP)
        elsif cmd.type == :NORMAL && cmd.base_damage < 80
          score = 100 + (80 - cmd.base_damage)
        # Off-type coverage weaker than NPT STAB
        elsif !stab_types.include?(cmd.type) && npt_data.base_damage >= cmd.base_damage
          score = npt_data.base_damage - cmd.base_damage + 1
        end

        next if score <= 0

        # Category match bonus: NPT move matches the slot's category
        score += 300 if npt_data.category == cmd.category
        # Stat lean bonus: NPT move matches the Pokemon's best offensive stat
        score += 100 if preferred_cat && npt_data.category == preferred_cat

        candidates.push([npt_move, i, score])
      end
    end

    break if candidates.empty?

    # Weighted random selection — higher score = more likely, but not guaranteed
    total_weight = candidates.sum { |c| c[2] }
    roll = rand(total_weight)
    picked = nil
    cumulative = 0
    candidates.each do |c|
      cumulative += c[2]
      if roll < cumulative
        picked = c
        break
      end
    end
    picked = candidates.last if !picked

    npt_move, slot_idx, _score = picked
    pkmn.moves[slot_idx] = Pokemon::Move.new(npt_move)
    current_moves[slot_idx] = npt_move
    slots_replaced += 1
  end

  return pkmn
end
