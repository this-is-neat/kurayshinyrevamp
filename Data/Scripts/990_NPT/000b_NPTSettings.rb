#==============================================================================
# 990_NPT — Runtime settings (persistent across save/load)
#
# Exposes NPT::Toggle with two queryable states used by the encounter /
# randomizer / trainer / UI hooks:
#
#   NPT::Toggle.new_pokemon_disabled?
#     True when the player has asked to hide all NPT-registered species.
#     Persisted via an attribute added to PokemonGlobalMetadata so it
#     survives save/load.
#
#   NPT::Toggle.badge_gate_active?
#     True when UBs/Paradox (GLOBAL_TABLE) should be blocked because the
#     player hasn't earned 5 gym badges yet. Independent of the toggle.
#==============================================================================

class PokemonGlobalMetadata
  attr_writer :npt_new_pokemon_disabled

  def npt_new_pokemon_disabled
    @npt_new_pokemon_disabled = false if @npt_new_pokemon_disabled.nil?
    @npt_new_pokemon_disabled
  end
end

module NPT
  module Toggle
    MIN_BADGES_FOR_GLOBAL = 5

    def self.new_pokemon_disabled?
      return false unless $PokemonGlobal
      $PokemonGlobal.npt_new_pokemon_disabled == true
    end

    def self.set_new_pokemon_disabled(value)
      return unless $PokemonGlobal
      $PokemonGlobal.npt_new_pokemon_disabled = (value == true)
    end

    def self.badge_gate_active?
      return true unless $Trainer
      count = ($Trainer.respond_to?(:badge_count) ? $Trainer.badge_count : 0).to_i
      count < MIN_BADGES_FOR_GLOBAL
    end

    # True if the given species ID (Symbol or Integer) is an NPT-registered
    # species (id_number >= NPT::FIRST_ID). Used by randomizer/trainer hooks
    # to substitute NPT picks with vanilla fallbacks.
    def self.npt_species?(sp)
      return false unless sp
      data = GameData::Species.try_get(sp) rescue nil
      return false unless data
      data.id_number >= NPT::FIRST_ID
    end
  end
end
