#===============================================================================
# NPT Move TMs — Auto-register TM items for all NPT moves
# File: 990_NPT/010_MoveTMs.rb
#
# Runs after 004_Moves.rb has loaded all NPT moves.
# Creates a TM item for each NPT move (id_number 6001-6187).
# TM items get id_number 9500+ and use the engine's machine_{TYPE}.png sprites.
# Pocket 4 = "TMs & HMs", field_use 3 = is_TM? true.
# TMs are numbered starting at TM200.
# Signature moves (<=4 species learners) are excluded.
#
# TYPE-BASED COMPATIBILITY
# ────────────────────────
# Any Pokémon whose type matches an NPT move's type can learn it via TM.
# Signature moves remain exclusive — only species that already have them
# in tutor_moves/moves/egg_moves can learn them (normal compatibility check).
# Normal-type NPT TMs can be learned by any Pokémon (matches vanilla TM
# behaviour where Normal TMs are broadly available).
#===============================================================================

if defined?(GameData) && defined?(GameData::Item) && defined?(GameData::Move)
  class GameData::Item
    class << self
      alias npt_move_tms_original_load load unless method_defined?(:npt_move_tms_original_load)
      def load
        npt_move_tms_original_load

        # Signature moves — exclusive to 1 family, no TM needed
        # (<=4 total occurrences across registration + learnsets)
        signature_moves = %i[
          BEHEMOTHBASH BEHEMOTHBLADE BLAZINGTORQUE COMBATTORQUE
          LIGHTTHATBURNSTHESKY MAGICALTORQUE NOXIOUSTORQUE PIKAPAPOW
          VEEVEEVOLLEY WICKEDTORQUE
          APPLEACID AQUASTEP ARMORCANNON ASTRALBARRAGE BADDYBAD
          BITTERBLADE BLOODMOON BOUNCYBUBBLE BUZZYBUZZ CEASELESSEDGE
          CHLOROBLAST CLANGOROUSSOUL COURTCHANGE DECORATE DIRECLAW
          DOODLE DOUBLESHOCK DRAGONDARTS DRAGONENERGY DRUMBEATING
          EERIESPELL ELECTROSHOT ESPERWING ETERNABEAM FICKLEBEAM
          FIERYWRATH FILLETAWAY FLOATYFALL FLOWERTRICK FREEZINGGLARE
          FREEZYFROST GIGATONHAMMER GLACIALLANCE GLITZYGLOW GRAVAPPLE
          INFERNALPARADE KOWTOWCLEAVE LUMINACRASH LUNARBLESSING
          MAGICPOWDER MAKEITRAIN MALIGNANTCHAIN MATCHAGOTCHA
          METEORASSAULT MOUNTAINGALE OBSTRUCT OCTOLOCK ORDERUP
          PYROBALL SAPPYSEED SHELLSIDEARM SILKTRAP SIZZLYSLIDE
          SNAPTRAP SNIPESHOT SPARKLYSWIRL SPLISHYSPLASH STONEAXE
          STRANGESTEAM SURGINGSTRIKES TARSHOT TEATIME THUNDERCAGE
          THUNDEROUSKICK TORCHSONG TRIPLEARROWS TRIPLEDIVE VICTORYDANCE
          ZIPPYZAP
          AURAWHEEL BITTERMALICE BOLTBEAK BURNINGBULWARK CHILLYRECEPTION
          FALSESURRENDER FISHIOUSREND GLAIVERUSH HYDROSTEAM
          JUNGLEHEALING MIGHTYCLEAVE MORTALSPIN NORETREAT OVERDRIVE
          POWERSHIFT PSYBLADE PSYSHIELDBASH RAGEFIST REVIVALBLESSING
          SALTCURE SPICYEXTRACT SPINOUT SYRUPBOMB TACHYONCUTTER
          TAKEHEART THUNDERCLAP
          BLEAKWINDSTORM DYNAMAXCANNON JETPUNCH MYSTICALPOWER
          POPULATIONBOMB SANDSEARSTORM SHEDTAIL SHELTER SPIRITBREAK
          SPRINGTIDESTORM TWINBEAM WICKEDBLOW WILDBOLTSTORM
          BARBBARRAGE HYPERDRILL LASTRESPECTS RAGINGBULL STUFFCHEEKS
        ]

        registered = 0
        tm_number = 200  # Start numbering at TM200
        GameData::Move.each do |move|
          next unless move.id_number.between?(6001, 6999)
          tm_sym       = "TM_#{move.id}".to_sym
          tm_id_number = 9500 + (move.id_number - 6001)
          next if self::DATA.has_key?(tm_sym)

          is_sig = signature_moves.include?(move.id)

          # Signature moves still get registered (so old saves don't crash)
          # but they get a generic name and won't appear in loot pools
          if is_sig
            register({
              id:          tm_sym,
              id_number:   tm_id_number,
              name:        "TM #{move.name}",
              name_plural: "TM #{move.name}",
              pocket:      4,
              price:       0,
              field_use:   3,
              battle_use:  0,
              type:        0,
              move:        move.id,
              description: "Teaches #{move.name} to a compatible Pokémon. (Signature move)",
            })
          else
            register({
              id:          tm_sym,
              id_number:   tm_id_number,
              name:        "TM#{tm_number} #{move.name}",
              name_plural: "TM#{tm_number} #{move.name}",
              pocket:      4,
              price:       0,
              field_use:   3,
              battle_use:  0,
              type:        0,
              move:        move.id,
              description: "Teaches #{move.name} to a compatible Pokémon.",
            })
            tm_number += 1
          end
          registered += 1
        end
      end
    end
  end
end

#===============================================================================
# Type-based TM compatibility for NPT moves
#
# Hooks compatible_with_move? so any Pokémon whose type matches an NPT move's
# type can learn it. Signature moves are excluded — they keep the default
# tutor_moves/moves/egg_moves check only.
#===============================================================================
module NPT
  # Centralised signature move set — frozen for fast lookup
  SIGNATURE_MOVES = %i[
    BEHEMOTHBASH BEHEMOTHBLADE BLAZINGTORQUE COMBATTORQUE
    LIGHTTHATBURNSTHESKY MAGICALTORQUE NOXIOUSTORQUE PIKAPAPOW
    VEEVEEVOLLEY WICKEDTORQUE
    APPLEACID AQUASTEP ARMORCANNON ASTRALBARRAGE BADDYBAD
    BITTERBLADE BLOODMOON BOUNCYBUBBLE BUZZYBUZZ CEASELESSEDGE
    CHLOROBLAST CLANGOROUSSOUL COURTCHANGE DECORATE DIRECLAW
    DOODLE DOUBLESHOCK DRAGONDARTS DRAGONENERGY DRUMBEATING
    EERIESPELL ELECTROSHOT ESPERWING ETERNABEAM FICKLEBEAM
    FIERYWRATH FILLETAWAY FLOATYFALL FLOWERTRICK FREEZINGGLARE
    FREEZYFROST GIGATONHAMMER GLACIALLANCE GLITZYGLOW GRAVAPPLE
    INFERNALPARADE KOWTOWCLEAVE LUMINACRASH LUNARBLESSING
    MAGICPOWDER MAKEITRAIN MALIGNANTCHAIN MATCHAGOTCHA
    METEORASSAULT MOUNTAINGALE OBSTRUCT OCTOLOCK ORDERUP
    PYROBALL SAPPYSEED SHELLSIDEARM SILKTRAP SIZZLYSLIDE
    SNAPTRAP SNIPESHOT SPARKLYSWIRL SPLISHYSPLASH STONEAXE
    STRANGESTEAM SURGINGSTRIKES TARSHOT TEATIME THUNDERCAGE
    THUNDEROUSKICK TORCHSONG TRIPLEARROWS TRIPLEDIVE VICTORYDANCE
    ZIPPYZAP
    AURAWHEEL BITTERMALICE BOLTBEAK BURNINGBULWARK CHILLYRECEPTION
    FALSESURRENDER FISHIOUSREND GLAIVERUSH HYDROSTEAM
    JUNGLEHEALING MIGHTYCLEAVE MORTALSPIN NORETREAT OVERDRIVE
    POWERSHIFT PSYBLADE PSYSHIELDBASH RAGEFIST REVIVALBLESSING
    SALTCURE SPICYEXTRACT SPINOUT SYRUPBOMB TACHYONCUTTER
    TAKEHEART THUNDERCLAP
    BLEAKWINDSTORM DYNAMAXCANNON JETPUNCH MYSTICALPOWER
    POPULATIONBOMB SANDSEARSTORM SHEDTAIL SHELTER SPIRITBREAK
    SPRINGTIDESTORM TWINBEAM WICKEDBLOW WILDBOLTSTORM
    BARBBARRAGE HYPERDRILL LASTRESPECTS RAGINGBULL STUFFCHEEKS
  ].to_h { |s| [s, true] }.freeze

  def self.npt_move?(move_data)
    move_data && move_data.id_number.between?(6001, 6999)
  end

  def self.signature_move?(move_id)
    SIGNATURE_MOVES.key?(move_id)
  end
end

class Pokemon
  alias _npt_tm_orig_compatible_with_move? compatible_with_move? unless method_defined?(:_npt_tm_orig_compatible_with_move?)

  def compatible_with_move?(move_id)
    move_data = GameData::Move.try_get(move_id)
    # For non-NPT moves or signature moves, use the original check
    if !NPT.npt_move?(move_data) || NPT.signature_move?(move_data.id)
      return _npt_tm_orig_compatible_with_move?(move_id)
    end
    # NPT move + not signature → type match grants compatibility
    # Normal-type NPT moves are learnable by any Pokémon
    move_type = move_data.type
    return true if move_type == :NORMAL
    return true if self.hasType?(move_type)
    # Still allow if the species already has it in its regular learnset
    _npt_tm_orig_compatible_with_move?(move_id)
  end
end
