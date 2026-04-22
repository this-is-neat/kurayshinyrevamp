class PokemonEncounters
  alias npt_encounters_orig_setup setup

  def setup(map_ID)
    npt_encounters_orig_setup(map_ID)
    return if @encounter_tables.nil? || @encounter_tables.empty?

    disabled   = NPT::Toggle.new_pokemon_disabled?
    badge_gate = NPT::Toggle.badge_gate_active?

    # Build combined injection list: global slots + map-specific slots
    injections = {}
    # GLOBAL_TABLE (UBs/Paradox) — skipped entirely when the player toggle
    # is on OR when they haven't earned 5 badges yet.
    unless disabled || badge_gate
      NPTEncounters::GLOBAL_TABLE.each do |enc_type, slots|
        (injections[enc_type] ||= []).concat(slots)
      end
    end
    # MAP_TABLE (per-route NPT species) — skipped when the toggle is on.
    unless disabled
      if NPTEncounters::MAP_TABLE.key?(map_ID)
        NPTEncounters::MAP_TABLE[map_ID].each do |enc_type, slots|
          (injections[enc_type] ||= []).concat(slots)
        end
      end
    end
    return if injections.empty?

    # Append validated slots into the live encounter table
    # choose_wild_pokemon expects: [probability, species_sym, min_lv, max_lv]
    injections.each do |enc_type, slots|
      next unless @encounter_tables.key?(enc_type)
      slots.each do |slot|
        next unless GameData::Species.exists?(slot[1])
        @encounter_tables[enc_type] << slot
      end
    end
  end
end

# ---------------------------------------------------------------------------
# Optional: EncounterModifier hook for global chance-based NPT injection.
# This fires on every encounter result from choose_wild_pokemon, regardless
# of map. Uncomment and customise as needed.
# ---------------------------------------------------------------------------
# EncounterModifier.register(proc { |encounter|
#   if encounter && rand(100) < 5
#     npt_species = :MIGHTYENA
#     if GameData::Species.exists?(npt_species)
#       encounter = [npt_species, rand(20..35)]
#     end
#   end
#   encounter
# })

# ---------------------------------------------------------------------------
# Fusion Guard — GLOBAL_TABLE species (Ultra Beasts & Paradox) must never
# appear as fusion components.  kurayEncounterInit is overridden here so
# that if either the base encounter OR the fusion partner comes from the
# GLOBAL_TABLE, the fusion step is skipped entirely and the UB/Paradox
# spawns as a standalone encounter instead.
# ---------------------------------------------------------------------------
NPT_GLOBAL_SPECIES = {}
NPTEncounters::GLOBAL_TABLE.values.each do |slots|
  slots.each { |slot| NPT_GLOBAL_SPECIES[slot[1]] = true }
end

# Handles both Symbol (:NIHILEGO) and Integer species IDs.
def npt_global_species?(sp_id)
  return false unless sp_id
  return NPT_GLOBAL_SPECIES.key?(sp_id) if sp_id.is_a?(Symbol)
  sym = GameData::Species.try_get(sp_id)&.id rescue nil
  sym ? NPT_GLOBAL_SPECIES.key?(sym) : false
end

alias npt_orig_kuray_encounter_init kurayEncounterInit

def kurayEncounterInit(encounter_type)
  encounter = getEncounter(encounter_type)
  disabled = NPT::Toggle.new_pokemon_disabled?

  # When the toggle is on, ANY NPT-registered species is a blocker (not just
  # GLOBAL_TABLE). Otherwise only UBs/Paradox are blocked.
  blocked = lambda do |sp|
    next true if npt_global_species?(sp)
    next true if disabled && NPT::Toggle.npt_species?(sp)
    false
  end

  if isFusedEncounter() && !blocked.call(encounter[0])
    encounter_fusedWith = getEncounter(encounter_type)
    if encounter[0] != encounter_fusedWith[0] && !blocked.call(encounter_fusedWith[0])
      encounter[0] = getFusionSpeciesSymbol(encounter[0], encounter_fusedWith[0])
    end
  end
  if encounter[0].is_a?(Integer)
    encounter[0] = getSpecies(encounter[0])
  end
  return encounter
end
