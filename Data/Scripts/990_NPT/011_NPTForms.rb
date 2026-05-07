#===============================================================================
# 011_NPTForms.rb
#
# - Form handlers for NPT species not covered by the base FormHandlers.rb
# - Base-species evolution patches (forward evolutions injected without
#   touching any core game file)
#===============================================================================

#===============================================================================
# NPT alternate-form sprite hook
#
# pkmn.species always returns the BASE species symbol (e.g. :WISHIWASHI) because
# Pokemon#species= bails early when the new species shares the same base symbol.
# So we cannot detect the active form from pkmn.species alone.
#
# pkmn.form in battle returns @form directly (Pokemon#form returns @form when
# $game_temp.in_battle, bypassing MultipleForms.call).  form_simple= writes
# @form directly without the NO-OP guard, so it is the correct setter.
#
# This alias checks pkmn.form > 0: if so, it builds the _N symbol
# (e.g. :WISHIWASHI_1) to look up the form-specific species id_number (1077)
# and calls get_unfused_sprite_path so Graphics/BaseSprites/1077.png is used
# instead of the fusion composite path (which triggers for any id > 501).
#===============================================================================
module GameData
  class Species
    class << self
      alias _npt_sbfp sprite_bitmap_from_pokemon
      def sprite_bitmap_from_pokemon(pkmn, back = false, species = nil, makeShiny = true)
        form_n = pkmn.form.to_i
        if form_n > 0
          base_sym = (species || pkmn.species).to_s
          form_sym = :"#{base_sym}_#{form_n}"
          sp_data  = GameData::Species.get(form_sym) rescue nil
          if sp_data
            id_num = sp_data.id_number
            path   = get_unfused_sprite_path(id_num, nil)
            if path && pbResolveBitmap(path)
              if defined?(MultiplayerDebug)
                MultiplayerDebug.info("NPT-FORM-SPRITE", "species=#{base_sym} form=#{form_n} id_num=#{id_num} path=#{path}")
              end
              bmp = AnimatedBitmap.new(path).recognizeDims()
              bmp.scale_bitmap(pkmn.sprite_scale)
              return bmp
            end
          end
        end
        _npt_sbfp(pkmn, back, species, makeShiny)
      end
    end
  end
end

#===============================================================================
# pbChangeForm sync hook
#
# The core pbChangeForm calls @pokemon.form = newForm which is a NO-OP in this
# engine (commented out).  That means pkmn.form stays 0 after any form change,
# so sprite_bitmap_from_pokemon never sees form > 0 and always loads the base
# sprite.  This alias calls form_simple= (which actually writes @form on the
# Pokemon object) after every pbChangeForm so that pkmn.form reflects reality.
# Wishiwashi/Schooling is handled separately above and skipped here.
#===============================================================================
class PokeBattle_Battler
  alias _npt_pbChangeForm pbChangeForm
  def pbChangeForm(newForm, msg)
    _npt_pbChangeForm(newForm, msg)
    # Sync Pokemon's @form so sprite_bitmap_from_pokemon reads the correct value.
    # Skip for Wishiwashi — its form is managed by the Schooling hook above.
    return if isSpecies?(:WISHIWASHI)
    @pokemon.form_simple = @form if @pokemon && @form != @pokemon.form_simple
  end
end

#===============================================================================
# Ogerpon — item-based form selection (Teal/Wellspring/Hearthflame/Cornerstone)
#===============================================================================
MultipleForms.register(:OGERPON, {
  "getForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:WELLSPRINGMASK)
    next 2 if pkmn.hasItem?(:HEARTHFLAMEMASK)
    next 3 if pkmn.hasItem?(:CORNERSTONEMASK)
    next 0
  }
})

#===============================================================================
# Base-species evolution patches
#
# NPT.register_all_species is aliased here so that every time the Species data
# is re-injected (GameData::Species.load hook in 000_Config.rb), the forward
# evolution entries for base-game Pokémon that evolve into NPT species are also
# applied — without modifying any core game file.
#===============================================================================
module NPT
  class << self
    alias _npt_register_all_pre_patch register_all_species

    def register_all_species
      _npt_register_all_pre_patch
      patch_base_species_evolutions
    end

    def patch_base_species_evolutions
      # Primeape (base-game #57) → Annihilape (NPT)
      # Evolves when levelling up while knowing Rage Fist.
      if GameData::Species.exists?(:PRIMEAPE)
        evos = GameData::Species.get(:PRIMEAPE).evolutions
        unless evos.any? { |e| e[0] == :ANNIHILAPE }
          evos << [:ANNIHILAPE, :HasMove, :RAGEFIST, false]
          echoln "[990_NPT] Patched PRIMEAPE → ANNIHILAPE evolution"
        end
      end

      # Bisharp (base-game #625) → Kingambit (NPT)
      # Simplified to Level 64 (originally: defeat 3 Leader's Crest Bisharp).
      if GameData::Species.exists?(:BISHARP)
        evos = GameData::Species.get(:BISHARP).evolutions
        unless evos.any? { |e| e[0] == :KINGAMBIT }
          evos << [:KINGAMBIT, :Level, 64, false]
          echoln "[990_NPT] Patched BISHARP → KINGAMBIT evolution"
        end
      end

      # Yamask (base-game #562) split evolutions by time of day:
      #   Day   → Cofagrigus (base game, patch Level → LevelDay)
      #   Night → Runerigus  (NPT)
      if GameData::Species.exists?(:YAMASK)
        evos = GameData::Species.get(:YAMASK).evolutions
        # Change existing Cofagrigus evo from plain Level to LevelDay
        cofagrigus_evo = evos.find { |e| e[0] == :COFAGRIGUS && e[1] == :Level }
        if cofagrigus_evo
          cofagrigus_evo[1] = :LevelDay
          echoln "[990_NPT] Patched YAMASK → COFAGRIGUS: Level 34 → LevelDay 34"
        end
        # Add night path to Runerigus
        unless evos.any? { |e| e[0] == :RUNERIGUS }
          evos << [:RUNERIGUS, :LevelNight, 34, false]
          echoln "[990_NPT] Patched YAMASK → RUNERIGUS: LevelNight 34"
        end
      end
    end
  end
end
