#==============================================================================
# 990_NPT — Trainer party filter
#
# When NPT::Toggle.new_pokemon_disabled? is true, any NPT-registered species
# that appears in a loaded trainer's party is swapped for a vanilla fallback.
# NPT doesn't inject into trainer PBS directly, but the randomizer + fusion
# logic can still land an NPT species inside a trainer's roster; this hook
# catches it at the point trainers are materialized for battle.
#
# Fallback selection is deterministic (based on the NPT id_number) so the
# same trainer always gets the same substitution within a session.
#==============================================================================

module NPT
  module Toggle
    VANILLA_ID_CEILING = 501  # NB_POKEMON before NPT raised it

    def self.vanilla_fallback_for(sp)
      data = GameData::Species.try_get(sp) rescue nil
      return sp unless data
      base = data.id_number
      # Deterministic 1..VANILLA_ID_CEILING pick
      fallback_id = ((base * 2654435761) % VANILLA_ID_CEILING) + 1
      fallback = GameData::Species.try_get(fallback_id) rescue nil
      return fallback.id if fallback
      :PIKACHU
    end

    def self.sanitize_trainer_party!(trainer)
      return unless trainer && trainer.respond_to?(:party)
      return unless new_pokemon_disabled?
      trainer.party.each do |pkmn|
        next unless pkmn
        next unless npt_species?(pkmn.species)
        new_sp = vanilla_fallback_for(pkmn.species)
        begin
          pkmn.species = new_sp
          pkmn.form_simple = 0 if pkmn.respond_to?(:form_simple=)
          pkmn.calc_stats if pkmn.respond_to?(:calc_stats)
        rescue
        end
      end
    end
  end
end

alias _npt_orig_pbLoadTrainer pbLoadTrainer

def pbLoadTrainer(tr_type, tr_name, tr_version = 0)
  trainer = _npt_orig_pbLoadTrainer(tr_type, tr_name, tr_version)
  NPT::Toggle.sanitize_trainer_party!(trainer)
  trainer
end
