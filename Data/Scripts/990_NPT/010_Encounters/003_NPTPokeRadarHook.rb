#==============================================================================
# 003_NPTPokeRadarHook.rb
# Prevents ultra-low probability NPT slots (UBs / Paradox at 0.1 weight) from
# appearing in the Pokéradar banner as "unseen" Pokémon.
#
# Problem: GLOBAL_TABLE injects UBs & Paradox at 0.1% on every map.
# listPokemonInCurrentRoute reads the full encounter table, so all 31 species
# would show as "unseen" on every route — permanently blocking the
# canEncounterRarePokemon unlock (which requires unseenPokemon.length == 0).
#
# Fix: alias listPokemonInCurrentRoute to skip any slot whose probability
# weight is < 1 before building the seen/unseen lists.
#==============================================================================

module NPT
  # Threshold below which an encounter slot is considered "invisible" to the
  # Pokéradar UI.  Matches RARE_PROB = 0.1 in 001_NPTEncounterData.rb.
  RADAR_MIN_PROB = 1
end

# listPokemonInCurrentRoute is a top-level (Object-private) method defined in
# 013_Items/005_Item_PokeRadar.rb. Alias it via Object.class_eval so that the
# method lookup chain is preserved correctly.
Object.class_eval do
  alias _npt_orig_listPokemonInCurrentRoute listPokemonInCurrentRoute

  def listPokemonInCurrentRoute(encounterType, onlySeen = false, onlyUnseen = false)
    return [] if encounterType.nil?
    processed = []
    seen      = []
    unseen    = []

    for encounter in $PokemonEncounters.listPossibleEncounters(encounterType)
      # Skip sub-threshold slots (UBs / Paradox at 0.1 weight) — they must
      # not count as "unseen" in the radar banner.
      next if encounter[0] < NPT::RADAR_MIN_PROB

      species = $game_switches[SWITCH_RANDOM_WILD] && !$game_switches[SWITCH_RANDOM_WILD_AREA] \
                  ? getRandomizedTo(encounter[1]) : encounter[1]
      species = GameData::Species.get(species).id if species.is_a?(Integer)

      next if processed.include?(species)
      if $Trainer.seen?(species)
        seen      << species
      else
        unseen    << species
      end
      processed << species
    end

    return onlySeen ? seen : onlyUnseen ? unseen : processed
  end
end
