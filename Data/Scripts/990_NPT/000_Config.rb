#==============================================================================
# 990_NPT — New Pokémon Tool
# File: 000_Config.rb
# Purpose: Override NB_POKEMON to make room for custom species registered in
#          this folder, without touching any core game file.
#
# HOW IT WORKS
# ────────────
# NB_POKEMON = 501 is set in 001_Settings.rb and also aliased at the top level
# by 052_AddOns/Gen 2.rb.  Scripts are loaded in alphanumeric order, so by the
# time this file executes both those constants already exist.  We replace them
# here via remove_const so no "already initialized constant" warning fires and
# all downstream code that reads NB_POKEMON gets the new value.
#
# POKÉDEX SAFETY
# ──────────────
# The Pokédex stores fusion data in a 2-D array indexed by [head_id][body_id].
# On every access it calls resyncPokedexIfNumberOfPokemonChanged(), which
# detects that the stored arrays are too small and silently expands them while
# preserving all existing seen/owned flags.  No manual migration is required.
#
# SAVE DATA SAFETY
# ────────────────
# Pokémon stored in party and boxes use Symbol species identifiers (:PIKACHU,
# :B25H1, etc.), never raw integers.  Changing NB_POKEMON does not affect them.
#
# ADDING MORE POKÉMON
# ───────────────────
# 1. Increase NPT_EXTRA_POKEMON below (or add another block in this file).
# 2. Register the species in 001_Registration.rb.
# 3. Add split-name syllables in 002_SplitNames.rb.
# 4. Add a PBSpecies alias in 003_PBSpeciesCompat.rb.
# 5. Drop sprites into Graphics/Battlers/<id>/ and Graphics/Pokemon/Icons/.
#==============================================================================

module NPT
  # ── Configuration ─────────────────────────────────────────────────────────

  # First ID available for custom Pokémon (must be > original NB_POKEMON = 501)
  FIRST_ID = 502

  # How many custom slots to reserve.  Increase this as you add more species.
  # The new NB_POKEMON will be FIRST_ID + RESERVED_SLOTS - 1.
  RESERVED_SLOTS = 700  # gives IDs 502..1201, NB_POKEMON becomes 1201

  # ── Derived ───────────────────────────────────────────────────────────────
  NEW_NB_POKEMON = FIRST_ID + RESERVED_SLOTS - 1  # 1201

  # Split-name index base: entries for custom Pokémon are appended to
  # GameData::SPLIT_NAMES starting at this offset (safely beyond existing 907).
  SPLIT_NAMES_BASE_INDEX = 950

  # Captured before we override Settings::ZAPMOLCUNO_NB below.
  # Used by rebase_triple_fusions to locate the species that need rebasing.
  OLD_ZAPMOLCUNO_NB = Settings::ZAPMOLCUNO_NB   # 999999
end

# ── Override Settings::NB_POKEMON ─────────────────────────────────────────────
module Settings
  remove_const :NB_POKEMON
  NB_POKEMON = NPT::NEW_NB_POKEMON
end

# ── Override the top-level NB_POKEMON alias (set by 052_AddOns/Gen 2.rb) ──────
Object.send(:remove_const, :NB_POKEMON) if Object.const_defined?(:NB_POKEMON)
NB_POKEMON = Settings::NB_POKEMON

echoln "[990_NPT] NB_POKEMON overridden to #{NB_POKEMON} (custom species IDs: #{NPT::FIRST_ID}..#{NPT::NEW_NB_POKEMON})"

# ── Override Settings::ZAPMOLCUNO_NB ─────────────────────────────────────────
# ZAPMOLCUNO_NB marks the lower boundary of triple-fusion ID space.
# For NB_POKEMON = N, the maximum valid dual-fusion ID is N*N + N.
# The original value (999,999) was sized for NB_POKEMON = 501.
# With NB_POKEMON = 1201, max dual-fusion = 1201*1201+1201 = 1,443,602,
# which exceeds 999,999 — causing getBasePokemonID to treat high-ID fusions
# (e.g. Terapagos × Pecharunt, ID ~1,239,295) as triple fusions and return nil.
# We recompute the boundary so it sits just above the true dual-fusion ceiling.
module Settings
  remove_const :ZAPMOLCUNO_NB
  n = NPT::NEW_NB_POKEMON
  ZAPMOLCUNO_NB = n * n + n + 1   # first ID that cannot be a valid dual fusion
end
echoln "[990_NPT] ZAPMOLCUNO_NB overridden to #{Settings::ZAPMOLCUNO_NB} (max dual-fusion ID: #{NPT::NEW_NB_POKEMON ** 2 + NPT::NEW_NB_POKEMON})"

# ── Rebase triple-fusion species from old ZAPMOLCUNO_NB to new one ────────────
# Triple fusions (:ZAPMOLTICUNO, :BIRDBOSS, etc.) are registered in species.dat
# AND by GameData.kuray_rewritetriples() with hardcoded id_numbers starting at
# OLD_ZAPMOLCUNO_NB (999999).  Now that Settings::ZAPMOLCUNO_NB has been raised
# to 1,443,603, those species fall below the threshold and are wrongly classified
# as dual fusions — corrupted sprites result.
#
# This method re-registers each vanilla triple-fusion species (id in range
# [OLD_ZAPMOLCUNO_NB, KURAY_NEW_TRIPLES)) at the new offset.  Modded triples
# (id >= KURAY_NEW_TRIPLES = 9,999,999) are already above the new threshold
# and must NOT be touched — they use their own KURAY_NEW_TRIPLES base constant.
module NPT
  def self.rebase_triple_fusions
    old_base = NPT::OLD_ZAPMOLCUNO_NB     # 999999
    new_base = Settings::ZAPMOLCUNO_NB    # 1,443,603
    mod_base = Settings::KURAY_NEW_TRIPLES rescue 9_999_999   # 9,999,999
    return if old_base == new_base

    # Only rebase vanilla triples (old_base..mod_base-1).
    # Modded triples (id >= mod_base) are already above ZAPMOLCUNO_NB and safe.
    # DATA stores entries under both symbol and integer keys; uniq deduplicates.
    to_patch = GameData::Species::DATA.values.select { |sp|
      sp.is_a?(GameData::Species) &&
      sp.id_number >= old_base &&
      sp.id_number < new_base &&   # already-rebased species (>= new_base) are excluded
      sp.id_number < mod_base
    }.uniq
    return if to_patch.empty?

    to_patch.each do |sp|
      old_id = sp.id_number
      new_id  = new_base + (old_id - old_base)

      GameData::Species.register({
        id:                    sp.id,
        id_number:             new_id,
        species:               sp.species,
        form:                  sp.form,
        name:                  sp.real_name,
        form_name:             sp.real_form_name,
        category:              sp.real_category,
        pokedex_entry:         sp.real_pokedex_entry,
        pokedex_form:          sp.pokedex_form,
        type1:                 sp.type1,
        type2:                 sp.type2,
        base_stats:            sp.base_stats,
        evs:                   sp.evs,
        base_exp:              sp.base_exp,
        growth_rate:           sp.growth_rate,
        gender_ratio:          sp.gender_ratio,
        catch_rate:            sp.catch_rate,
        happiness:             sp.happiness,
        moves:                 sp.moves,
        tutor_moves:           sp.tutor_moves,
        egg_moves:             sp.egg_moves,
        abilities:             sp.abilities,
        hidden_abilities:      sp.hidden_abilities,
        wild_item_common:      sp.wild_item_common,
        wild_item_uncommon:    sp.wild_item_uncommon,
        wild_item_rare:        sp.wild_item_rare,
        egg_groups:            sp.egg_groups,
        hatch_steps:           sp.hatch_steps,
        incense:               sp.incense,
        evolutions:            sp.evolutions,
        height:                sp.height,
        weight:                sp.weight,
        color:                 sp.color,
        shape:                 sp.shape,
        habitat:               sp.habitat,
        generation:            sp.generation,
        mega_stone:            sp.mega_stone,
        mega_move:             sp.mega_move,
        unmega_form:           sp.unmega_form,
        mega_message:          sp.mega_message,
        back_sprite_x:         sp.back_sprite_x,
        back_sprite_y:         sp.back_sprite_y,
        front_sprite_x:        sp.front_sprite_x,
        front_sprite_y:        sp.front_sprite_y,
        front_sprite_altitude: sp.front_sprite_altitude,
        shadow_x:              sp.shadow_x,
        shadow_size:           sp.shadow_size,
      })

      # Remove the stale integer-keyed entry so nothing accidentally looks it up
      # by the old id_number.  Symbol lookups (:ZAPMOLTICUNO etc.) now return the
      # freshly registered object whose id_number is new_id.
      GameData::Species::DATA.delete(old_id)
    end

    echoln "[990_NPT] Rebased #{to_patch.length} triple-fusion species: #{old_base}+N => #{new_base}+N"
  end
end

# ── Hook GameData::Species.load to re-inject custom species after every load ──
# GameData::Species.load calls const_set(:DATA, load_data("species.dat")), which
# replaces the entire DATA hash and wipes anything registered at script-load time.
# By aliasing load here, our species are re-registered every time the .dat loads.
module GameData
  class Species
    class << self
      alias _npt_original_species_load load
      def load
        _npt_original_species_load
        NPT.register_all_species if NPT.respond_to?(:register_all_species)
        # Register vanilla triple fusions even outside challenge mode.
        # kuray_rewritetriples adds them at old id_numbers; our hook on it then
        # calls rebase_triple_fusions to correct those IDs immediately.
        GameData.kuray_rewritetriples if GameData.respond_to?(:kuray_rewritetriples)
        # Belt-and-suspenders: rebase again in case the hook isn't in place yet.
        NPT.rebase_triple_fusions if NPT.respond_to?(:rebase_triple_fusions)
        echoln "[990_NPT] Custom species injected after Species.load"
      end
    end
  end
end

# ── Hook GameData.kuray_rewritetriples to rebase after every call ─────────────
# kuray_rewritetriples() re-registers vanilla triple fusions with hardcoded
# OLD id_numbers (999999, 1000000, …) every time it is called from ChallengeMode.
# This hook runs rebase_triple_fusions immediately after, so the id_numbers are
# always corrected regardless of call order.
module GameData
  class << self
    alias _npt_original_kuray_rewritetriples kuray_rewritetriples
    def kuray_rewritetriples
      _npt_original_kuray_rewritetriples
      NPT.rebase_triple_fusions if NPT.respond_to?(:rebase_triple_fusions)
    end
  end
end

# ── Redirect triple-fusion sprite path to correct folder ─────────────────────
# kuray_global_triples() returns paths under "Graphics/Battlers/special/" but
# the actual files live in "Graphics/Other/Triples/".
# kuray_global_triples is a top-level (Object-private) method, so we alias it
# via Object.class_eval and replace the base path in the returned string.
Object.class_eval do
  alias _npt_original_kuray_global_triples kuray_global_triples
  def kuray_global_triples(dexNum)
    result = _npt_original_kuray_global_triples(dexNum)
    # "invisible" lives in Graphics/Battlers/special/ — do not redirect it to Triples/
    return result if result&.end_with?("invisible")
    result&.gsub("Graphics/Battlers/special/", "Graphics/Other/Triples/")
  end
end
