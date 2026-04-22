# 006_Items.rb
# Registers Gen 8-9 evolution items that are not in the base game.
# These items are required so NPT evolution chains do not crash on load.
# IDs 8001-8007 are reserved for NPT evolution items.
#
# Items already in game (no registration needed):
#   Stones: THUNDERSTONE FIRESTONE WATERSTONE LEAFSTONE MOONSTONE SUNSTONE SHINYSTONE ICESTONE
#   Other:  DEEPSEATOOTH DEEPSEASCALE RAZORCLAW SACHET

# Full set of valid evolution items (for generator reference):
module NPT
  VALID_EVOLUTION_ITEMS = %i[
    THUNDERSTONE  FIRESTONE  WATERSTONE  LEAFSTONE  MOONSTONE  SUNSTONE  SHINYSTONE  ICESTONE  DEEPSEATOOTH  DEEPSEASCALE  RAZORCLAW  SACHET  SWEETAPPLE  TARTAPPLE  CRACKEDPOT  PEATBLOCK  BLACKAUGURITE  MALICIOUSARMOR  AUSPICIOUSARMOR
  ].freeze
end

if defined?(GameData) && defined?(GameData::Item)
  class GameData::Item
    class << self
      alias npt_items_original_load load
      def load
        npt_items_original_load

        # ──────────────────────────────────────────────────────────
        # Sweet Apple (#8001)
        # ──────────────────────────────────────────────────────────
        unless GameData::Item.exists?(:SWEETAPPLE)
          register({
            :id          => :SWEETAPPLE,
            :id_number   => 8001,
            :name        => "Sweet Apple",
            :name_plural => "Sweet Apples",
            :pocket      => 1,
            :price       => 0,
            :description => "A sweet apple that makes Applin evolve into Appletun.",
            :field_use   => 2,
            :battle_use  => 0,
            :type        => 0,
            :move        => nil
          })
          MessageTypes.set(MessageTypes::Items,            8001, "Sweet Apple")
          MessageTypes.set(MessageTypes::ItemPlurals,      8001, "Sweet Apples")
          MessageTypes.set(MessageTypes::ItemDescriptions, 8001, "A sweet apple that makes Applin evolve into Appletun.")
        end

        # ──────────────────────────────────────────────────────────
        # Tart Apple (#8002)
        # ──────────────────────────────────────────────────────────
        unless GameData::Item.exists?(:TARTAPPLE)
          register({
            :id          => :TARTAPPLE,
            :id_number   => 8002,
            :name        => "Tart Apple",
            :name_plural => "Tart Apples",
            :pocket      => 1,
            :price       => 0,
            :description => "A tart apple that makes Applin evolve into Flapple.",
            :field_use   => 2,
            :battle_use  => 0,
            :type        => 0,
            :move        => nil
          })
          MessageTypes.set(MessageTypes::Items,            8002, "Tart Apple")
          MessageTypes.set(MessageTypes::ItemPlurals,      8002, "Tart Apples")
          MessageTypes.set(MessageTypes::ItemDescriptions, 8002, "A tart apple that makes Applin evolve into Flapple.")
        end

        # ──────────────────────────────────────────────────────────
        # Cracked Pot (#8003)
        # ──────────────────────────────────────────────────────────
        unless GameData::Item.exists?(:CRACKEDPOT)
          register({
            :id          => :CRACKEDPOT,
            :id_number   => 8003,
            :name        => "Cracked Pot",
            :name_plural => "Cracked Pots",
            :pocket      => 1,
            :price       => 0,
            :description => "A cracked teapot that makes Sinistea evolve into Polteageist.",
            :field_use   => 2,
            :battle_use  => 0,
            :type        => 0,
            :move        => nil
          })
          MessageTypes.set(MessageTypes::Items,            8003, "Cracked Pot")
          MessageTypes.set(MessageTypes::ItemPlurals,      8003, "Cracked Pots")
          MessageTypes.set(MessageTypes::ItemDescriptions, 8003, "A cracked teapot that makes Sinistea evolve into Polteageist.")
        end

        # ──────────────────────────────────────────────────────────
        # Peat Block (#8004)
        # ──────────────────────────────────────────────────────────
        unless GameData::Item.exists?(:PEATBLOCK)
          register({
            :id          => :PEATBLOCK,
            :id_number   => 8004,
            :name        => "Peat Block",
            :name_plural => "Peat Blocks",
            :pocket      => 1,
            :price       => 0,
            :description => "A block of peat that makes Ursaring evolve into Ursaluna.",
            :field_use   => 2,
            :battle_use  => 0,
            :type        => 0,
            :move        => nil
          })
          MessageTypes.set(MessageTypes::Items,            8004, "Peat Block")
          MessageTypes.set(MessageTypes::ItemPlurals,      8004, "Peat Blocks")
          MessageTypes.set(MessageTypes::ItemDescriptions, 8004, "A block of peat that makes Ursaring evolve into Ursaluna.")
        end

        # ──────────────────────────────────────────────────────────
        # Black Augurite (#8005)
        # ──────────────────────────────────────────────────────────
        unless GameData::Item.exists?(:BLACKAUGURITE)
          register({
            :id          => :BLACKAUGURITE,
            :id_number   => 8005,
            :name        => "Black Augurite",
            :name_plural => "Black Augurites",
            :pocket      => 1,
            :price       => 0,
            :description => "A jet-black stone that makes Scyther evolve into Kleavor.",
            :field_use   => 2,
            :battle_use  => 0,
            :type        => 0,
            :move        => nil
          })
          MessageTypes.set(MessageTypes::Items,            8005, "Black Augurite")
          MessageTypes.set(MessageTypes::ItemPlurals,      8005, "Black Augurites")
          MessageTypes.set(MessageTypes::ItemDescriptions, 8005, "A jet-black stone that makes Scyther evolve into Kleavor.")
        end

        # ──────────────────────────────────────────────────────────
        # Auspicious Armor (#8006)
        # ──────────────────────────────────────────────────────────
        unless GameData::Item.exists?(:AUSPICIOUSARMOR)
          register({
            :id          => :AUSPICIOUSARMOR,
            :id_number   => 8006,
            :name        => "Auspicious Armor",
            :name_plural => "Auspicious Armors",
            :pocket      => 1,
            :price       => 0,
            :description => "A suit of armor imbued with good fortune. Makes Charcadet evolve into Armarouge.",
            :field_use   => 2,
            :battle_use  => 0,
            :type        => 0,
            :move        => nil
          })
          MessageTypes.set(MessageTypes::Items,            8006, "Auspicious Armor")
          MessageTypes.set(MessageTypes::ItemPlurals,      8006, "Auspicious Armors")
          MessageTypes.set(MessageTypes::ItemDescriptions, 8006, "A suit of armor imbued with good fortune. Makes Charcadet evolve into Armarouge.")
        end

        # ──────────────────────────────────────────────────────────
        # Malicious Armor (#8007)
        # ──────────────────────────────────────────────────────────
        unless GameData::Item.exists?(:MALICIOUSARMOR)
          register({
            :id          => :MALICIOUSARMOR,
            :id_number   => 8007,
            :name        => "Malicious Armor",
            :name_plural => "Malicious Armors",
            :pocket      => 1,
            :price       => 0,
            :description => "A suit of armor imbued with spite. Makes Charcadet evolve into Ceruledge.",
            :field_use   => 2,
            :battle_use  => 0,
            :type        => 0,
            :move        => nil
          })
          MessageTypes.set(MessageTypes::Items,            8007, "Malicious Armor")
          MessageTypes.set(MessageTypes::ItemPlurals,      8007, "Malicious Armors")
          MessageTypes.set(MessageTypes::ItemDescriptions, 8007, "A suit of armor imbued with spite. Makes Charcadet evolve into Ceruledge.")
        end

      end  # load
    end  # class << self
  end  # GameData::Item
end
