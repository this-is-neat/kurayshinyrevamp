#===============================================================================
# NPT Boss Loot Hook
# File: 990_NPT/013_BossLootHook.rb
#
# Hooks into the Multiplayer Boss loot system (if present) to:
#   - Add NPT TMs to the Rare loot pool
#   - Mega stones are already included via epic_pool (IDs 9300-9439)
#===============================================================================

if defined?(BossConfig)

  module BossConfig
    # ── NPT TM pool (built lazily from registered TM items) ─────────────
    def self.npt_tm_pool
      @npt_tm_pool ||= begin
        tms = []
        if defined?(GameData::Item)
          GameData::Item.each do |item|
            # NPT TM items have id_numbers 9500+
            next unless item.id_number.between?(9500, 9699)
            # Skip signature move TMs (description ends with "(Signature move)")
            desc = item.description rescue ""
            next if desc.include?("(Signature move)")
            tms << item.id
          end
        end
        tms
      end
    end

    def self.reset_npt_tm_pool; @npt_tm_pool = nil; end

    # ── Inject NPT TMs into the Rare loot pool ─────────────────────────
    # Override weighted_loot_pick to include NPT TMs in rare rolls
    class << self
      alias _npt_original_weighted_loot_pick weighted_loot_pick unless method_defined?(:_npt_original_weighted_loot_pick)

      def weighted_loot_pick
        result = _npt_original_weighted_loot_pick

        # If we rolled rare AND NPT TMs exist, 50% chance to swap for an NPT TM
        if result[:rarity] == :rare && !npt_tm_pool.empty? && rand(2) == 0
          result[:item] = npt_tm_pool.sample
        end

        result
      end
    end
  end

end
