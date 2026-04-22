#===============================================================================
# NPT Mega Accessories — Untossable + Auto-Grant
# File: 990_NPT/014_MegaAccessories.rb
#
# 1. Makes Mega Ring/Bracelet/Cuff/Charm untossable (is_important? = true)
# 2. On bag open, checks if the player owns any mega accessory.
#    If not, grants one at random. This is retrocompatible — existing
#    players who already have one are unaffected.
#===============================================================================

if defined?(GameData) && defined?(GameData::Item)

  # ── Make mega accessories untossable ──────────────────────────────────
  MEGA_ACCESSORY_IDS = %i[MEGARING MEGABRACELET MEGACUFF MEGACHARM]

  class GameData::Item
    alias _npt_original_is_important? is_important? unless method_defined?(:_npt_original_is_important?)

    def is_important?
      return true if MEGA_ACCESSORY_IDS.include?(@id)
      _npt_original_is_important?
    end
  end

  # ── Auto-grant one mega accessory if player has none ──────────────────
  module MegaAccessoryGrant
    @granted_this_session = false

    def self.check_and_grant
      return if @granted_this_session
      return unless defined?($PokemonBag) && $PokemonBag

      # Check if player already has any mega accessory
      has_any = MEGA_ACCESSORY_IDS.any? { |id|
        $PokemonBag.pbQuantity(id) > 0 rescue false
      }
      return if has_any

      # Grant one at random
      chosen = MEGA_ACCESSORY_IDS.sample
      $PokemonBag.pbStoreItem(chosen, 1)
      @granted_this_session = true

      item_name = GameData::Item.get(chosen).name rescue chosen.to_s
      pbMessage(_INTL("You received a {1}!\nThis allows your Pokémon to Mega Evolve in battle.", item_name))
    end
  end

  # ── Hook into bag open ────────────────────────────────────────────────
  if defined?(PokemonBag_Scene)
    class PokemonBag_Scene
      alias _npt_mega_acc_pbStartScene pbStartScene unless method_defined?(:_npt_mega_acc_pbStartScene)

      def pbStartScene(*args)
        MegaAccessoryGrant.check_and_grant
        _npt_mega_acc_pbStartScene(*args)
      end
    end
  end

end
