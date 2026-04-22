# 009_MoveLearnsets.rb
# Auto-generated — adds NPT moves to base game Pokémon tutor_moves.
# Source: PokéAPI learned_by_pokemon data.
# Only patches species already in GameData::Species::DATA (skips unknown).
#
# 647 species patched across 172 moves.
# Generated on: 2026-03-14 15:36:43

module NPT
  def self.patch_base_move_learnsets
    patched = 0
    skipped = 0

    # AEGISLASH
    if GameData::Species::DATA[:AEGISLASH]
      sp = GameData::Species::DATA[:AEGISLASH]
      [:STEELBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AEGISLASH_BLADE
    if GameData::Species::DATA[:AEGISLASH_BLADE]
      sp = GameData::Species::DATA[:AEGISLASH_BLADE]
      [:STEELBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AERODACTYL
    if GameData::Species::DATA[:AERODACTYL]
      sp = GameData::Species::DATA[:AERODACTYL]
      [:DUALWINGBEAT, :METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AGGRON
    if GameData::Species::DATA[:AGGRON]
      sp = GameData::Species::DATA[:AGGRON]
      [:BODYPRESS, :METEORBEAM, :STEELBEAM, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AIPOM
    if GameData::Species::DATA[:AIPOM]
      sp = GameData::Species::DATA[:AIPOM]
      [:CHILLINGWATER, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ALAKAZAM
    if GameData::Species::DATA[:ALAKAZAM]
      sp = GameData::Species::DATA[:ALAKAZAM]
      [:EXPANDINGFORCE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ALTARIA
    if GameData::Species::DATA[:ALTARIA]
      sp = GameData::Species::DATA[:ALTARIA]
      [:ALLURINGVOICE, :BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AMAURA
    if GameData::Species::DATA[:AMAURA]
      sp = GameData::Species::DATA[:AMAURA]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AMBIPOM
    if GameData::Species::DATA[:AMBIPOM]
      sp = GameData::Species::DATA[:AMBIPOM]
      [:CHILLINGWATER, :TERABLAST, :TRAILBLAZE, :TRIPLEAXEL, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AMPHAROS
    if GameData::Species::DATA[:AMPHAROS]
      sp = GameData::Species::DATA[:AMPHAROS]
      [:BREAKINGSWIPE, :DRAGONCHEER, :METEORBEAM, :SUPERCELLSLAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ANORITH
    if GameData::Species::DATA[:ANORITH]
      sp = GameData::Species::DATA[:ANORITH]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ARBOK
    if GameData::Species::DATA[:ARBOK]
      sp = GameData::Species::DATA[:ARBOK]
      [:BREAKINGSWIPE, :LASHOUT, :SCALESHOT, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ARCANINE
    if GameData::Species::DATA[:ARCANINE]
      sp = GameData::Species::DATA[:ARCANINE]
      [:SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ARCANINE_HISUI
    if GameData::Species::DATA[:ARCANINE_HISUI]
      sp = GameData::Species::DATA[:ARCANINE_HISUI]
      [:RAGINGFURY, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ARCEUS
    if GameData::Species::DATA[:ARCEUS]
      sp = GameData::Species::DATA[:ARCEUS]
      [:BODYPRESS, :CHILLINGWATER, :METEORBEAM, :SCORCHINGSANDS, :STEELBEAM, :SUPERCELLSLAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ARIADOS
    if GameData::Species::DATA[:ARIADOS]
      sp = GameData::Species::DATA[:ARIADOS]
      [:POUNCE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ARMALDO
    if GameData::Species::DATA[:ARMALDO]
      sp = GameData::Species::DATA[:ARMALDO]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ARON
    if GameData::Species::DATA[:ARON]
      sp = GameData::Species::DATA[:ARON]
      [:BODYPRESS, :STEELBEAM, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ARTICUNO
    if GameData::Species::DATA[:ARTICUNO]
      sp = GameData::Species::DATA[:ARTICUNO]
      [:DUALWINGBEAT, :ICESPINNER, :SNOWSCAPE, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ARTICUNO_GALAR
    if GameData::Species::DATA[:ARTICUNO_GALAR]
      sp = GameData::Species::DATA[:ARTICUNO_GALAR]
      [:DUALWINGBEAT, :EXPANDINGFORCE, :FREEZINGGLARE, :PSYCHICNOISE, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AURORUS
    if GameData::Species::DATA[:AURORUS]
      sp = GameData::Species::DATA[:AURORUS]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AVALUGG_HISUI
    if GameData::Species::DATA[:AVALUGG_HISUI]
      sp = GameData::Species::DATA[:AVALUGG_HISUI]
      [:BODYPRESS, :CHILLINGWATER, :HARDPRESS, :ICESPINNER, :METEORBEAM, :MOUNTAINGALE, :POWERSHIFT, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AXEW
    if GameData::Species::DATA[:AXEW]
      sp = GameData::Species::DATA[:AXEW]
      [:BREAKINGSWIPE, :DRAGONCHEER, :SCALESHOT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AZUMARILL
    if GameData::Species::DATA[:AZUMARILL]
      sp = GameData::Species::DATA[:AZUMARILL]
      [:ALLURINGVOICE, :CHILLINGWATER, :ICESPINNER, :MISTYEXPLOSION, :SNOWSCAPE, :STEELROLLER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # AZURILL
    if GameData::Species::DATA[:AZURILL]
      sp = GameData::Species::DATA[:AZURILL]
      [:ALLURINGVOICE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BAGON
    if GameData::Species::DATA[:BAGON]
      sp = GameData::Species::DATA[:BAGON]
      [:DRAGONCHEER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BANETTE
    if GameData::Species::DATA[:BANETTE]
      sp = GameData::Species::DATA[:BANETTE]
      [:BURNINGJEALOUSY, :LASHOUT, :POLTERGEIST, :POUNCE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BASCULEGION_FEMALE
    if GameData::Species::DATA[:BASCULEGION_FEMALE]
      sp = GameData::Species::DATA[:BASCULEGION_FEMALE]
      [:CHILLINGWATER, :FLIPTURN, :LASTRESPECTS, :SCALESHOT, :SNOWSCAPE, :TERABLAST, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BASCULIN_BLUE_STRIPED
    if GameData::Species::DATA[:BASCULIN_BLUE_STRIPED]
      sp = GameData::Species::DATA[:BASCULIN_BLUE_STRIPED]
      [:CHILLINGWATER, :FLIPTURN, :SCALESHOT, :SNOWSCAPE, :TERABLAST, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BASCULIN_WHITE_STRIPED
    if GameData::Species::DATA[:BASCULIN_WHITE_STRIPED]
      sp = GameData::Species::DATA[:BASCULIN_WHITE_STRIPED]
      [:CHILLINGWATER, :FLIPTURN, :LASTRESPECTS, :SCALESHOT, :SNOWSCAPE, :TERABLAST, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BASTIODON
    if GameData::Species::DATA[:BASTIODON]
      sp = GameData::Species::DATA[:BASTIODON]
      [:BODYPRESS, :HARDPRESS, :METEORBEAM, :SCORCHINGSANDS, :STEELBEAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BAYLEEF
    if GameData::Species::DATA[:BAYLEEF]
      sp = GameData::Species::DATA[:BAYLEEF]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BELDUM
    if GameData::Species::DATA[:BELDUM]
      sp = GameData::Species::DATA[:BELDUM]
      [:STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BELLOSSOM
    if GameData::Species::DATA[:BELLOSSOM]
      sp = GameData::Species::DATA[:BELLOSSOM]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BELLSPROUT
    if GameData::Species::DATA[:BELLSPROUT]
      sp = GameData::Species::DATA[:BELLSPROUT]
      [:GRASSYGLIDE, :POUNCE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BEWEAR
    if GameData::Species::DATA[:BEWEAR]
      sp = GameData::Species::DATA[:BEWEAR]
      [:BODYPRESS, :COACHING].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BISHARP
    if GameData::Species::DATA[:BISHARP]
      sp = GameData::Species::DATA[:BISHARP]
      [:LASHOUT, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BLASTOISE
    if GameData::Species::DATA[:BLASTOISE]
      sp = GameData::Species::DATA[:BLASTOISE]
      [:BODYPRESS, :CHILLINGWATER, :FLIPTURN, :ICESPINNER, :LIFEDEW, :TERABLAST, :TERRAINPULSE, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BLAZIKEN
    if GameData::Species::DATA[:BLAZIKEN]
      sp = GameData::Species::DATA[:BLAZIKEN]
      [:COACHING, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BLISSEY
    if GameData::Species::DATA[:BLISSEY]
      sp = GameData::Species::DATA[:BLISSEY]
      [:ALLURINGVOICE, :CHILLINGWATER, :LIFEDEW, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BONSLY
    if GameData::Species::DATA[:BONSLY]
      sp = GameData::Species::DATA[:BONSLY]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BRAIXEN
    if GameData::Species::DATA[:BRAIXEN]
      sp = GameData::Species::DATA[:BRAIXEN]
      [:BURNINGJEALOUSY, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BRAVIARY_HISUI
    if GameData::Species::DATA[:BRAVIARY_HISUI]
      sp = GameData::Species::DATA[:BRAVIARY_HISUI]
      [:DUALWINGBEAT, :ESPERWING, :EXPANDINGFORCE, :POWERSHIFT, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BRELOOM
    if GameData::Species::DATA[:BRELOOM]
      sp = GameData::Species::DATA[:BRELOOM]
      [:POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BRUTE_BONNET
    if GameData::Species::DATA[:BRUTE_BONNET]
      sp = GameData::Species::DATA[:BRUTE_BONNET]
      [:BODYPRESS, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BRUXISH
    if GameData::Species::DATA[:BRUXISH]
      sp = GameData::Species::DATA[:BRUXISH]
      [:CHILLINGWATER, :EXPANDINGFORCE, :FLIPTURN, :PSYCHICNOISE, :TERABLAST, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BUDEW
    if GameData::Species::DATA[:BUDEW]
      sp = GameData::Species::DATA[:BUDEW]
      [:GRASSYGLIDE, :LIFEDEW].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BULBASAUR
    if GameData::Species::DATA[:BULBASAUR]
      sp = GameData::Species::DATA[:BULBASAUR]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BUNEARY
    if GameData::Species::DATA[:BUNEARY]
      sp = GameData::Species::DATA[:BUNEARY]
      [:TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # BUTTERFREE
    if GameData::Species::DATA[:BUTTERFREE]
      sp = GameData::Species::DATA[:BUTTERFREE]
      [:DUALWINGBEAT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CACNEA
    if GameData::Species::DATA[:CACNEA]
      sp = GameData::Species::DATA[:CACNEA]
      [:GRASSYGLIDE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CACTURNE
    if GameData::Species::DATA[:CACTURNE]
      sp = GameData::Species::DATA[:CACTURNE]
      [:GRASSYGLIDE, :LASHOUT, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CALYREX_ICE
    if GameData::Species::DATA[:CALYREX_ICE]
      sp = GameData::Species::DATA[:CALYREX_ICE]
      [:BODYPRESS, :EXPANDINGFORCE, :GLACIALLANCE, :LASHOUT, :LIFEDEW, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CALYREX_SHADOW
    if GameData::Species::DATA[:CALYREX_SHADOW]
      sp = GameData::Species::DATA[:CALYREX_SHADOW]
      [:ASTRALBARRAGE, :EXPANDINGFORCE, :LASHOUT, :LIFEDEW, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CARBINK
    if GameData::Species::DATA[:CARBINK]
      sp = GameData::Species::DATA[:CARBINK]
      [:BODYPRESS, :METEORBEAM, :MISTYEXPLOSION, :TERABLAST, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CARVANHA
    if GameData::Species::DATA[:CARVANHA]
      sp = GameData::Species::DATA[:CARVANHA]
      [:FLIPTURN, :SCALESHOT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CELEBI
    if GameData::Species::DATA[:CELEBI]
      sp = GameData::Species::DATA[:CELEBI]
      [:DUALWINGBEAT, :EXPANDINGFORCE, :GRASSYGLIDE, :LIFEDEW].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHANDELURE
    if GameData::Species::DATA[:CHANDELURE]
      sp = GameData::Species::DATA[:CHANDELURE]
      [:BURNINGJEALOUSY, :LASHOUT, :POLTERGEIST, :SKITTERSMACK, :TEMPERFLARE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHANSEY
    if GameData::Species::DATA[:CHANSEY]
      sp = GameData::Species::DATA[:CHANSEY]
      [:CHILLINGWATER, :LIFEDEW, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHARIZARD
    if GameData::Species::DATA[:CHARIZARD]
      sp = GameData::Species::DATA[:CHARIZARD]
      [:BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :SCALESHOT, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHARMANDER
    if GameData::Species::DATA[:CHARMANDER]
      sp = GameData::Species::DATA[:CHARMANDER]
      [:BREAKINGSWIPE, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHARMELEON
    if GameData::Species::DATA[:CHARMELEON]
      sp = GameData::Species::DATA[:CHARMELEON]
      [:BREAKINGSWIPE, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHESNAUGHT
    if GameData::Species::DATA[:CHESNAUGHT]
      sp = GameData::Species::DATA[:CHESNAUGHT]
      [:BODYPRESS, :COACHING, :GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHESPIN
    if GameData::Species::DATA[:CHESPIN]
      sp = GameData::Species::DATA[:CHESPIN]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHIEN_PAO
    if GameData::Species::DATA[:CHIEN_PAO]
      sp = GameData::Species::DATA[:CHIEN_PAO]
      [:ICESPINNER, :LASHOUT, :RUINATION, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHIKORITA
    if GameData::Species::DATA[:CHIKORITA]
      sp = GameData::Species::DATA[:CHIKORITA]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHIMCHAR
    if GameData::Species::DATA[:CHIMCHAR]
      sp = GameData::Species::DATA[:CHIMCHAR]
      [:BURNINGJEALOUSY, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHINCHOU
    if GameData::Species::DATA[:CHINCHOU]
      sp = GameData::Species::DATA[:CHINCHOU]
      [:CHILLINGWATER, :FLIPTURN, :RISINGVOLTAGE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CHI_YU
    if GameData::Species::DATA[:CHI_YU]
      sp = GameData::Species::DATA[:CHI_YU]
      [:BURNINGJEALOUSY, :LASHOUT, :RUINATION, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CLEFABLE
    if GameData::Species::DATA[:CLEFABLE]
      sp = GameData::Species::DATA[:CLEFABLE]
      [:ALLURINGVOICE, :CHILLINGWATER, :DUALWINGBEAT, :LIFEDEW, :METEORBEAM, :MISTYEXPLOSION, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CLEFAIRY
    if GameData::Species::DATA[:CLEFAIRY]
      sp = GameData::Species::DATA[:CLEFAIRY]
      [:ALLURINGVOICE, :CHILLINGWATER, :DUALWINGBEAT, :LIFEDEW, :METEORBEAM, :MISTYEXPLOSION, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CLEFFA
    if GameData::Species::DATA[:CLEFFA]
      sp = GameData::Species::DATA[:CLEFFA]
      [:ALLURINGVOICE, :CHILLINGWATER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CLOYSTER
    if GameData::Species::DATA[:CLOYSTER]
      sp = GameData::Species::DATA[:CLOYSTER]
      [:CHILLINGWATER, :ICESPINNER, :SNOWSCAPE, :STEELROLLER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # COFAGRIGUS
    if GameData::Species::DATA[:COFAGRIGUS]
      sp = GameData::Species::DATA[:COFAGRIGUS]
      [:BODYPRESS, :POLTERGEIST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # COMBUSKEN
    if GameData::Species::DATA[:COMBUSKEN]
      sp = GameData::Species::DATA[:COMBUSKEN]
      [:COACHING, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CORSOLA
    if GameData::Species::DATA[:CORSOLA]
      sp = GameData::Species::DATA[:CORSOLA]
      [:LIFEDEW, :METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CORSOLA_GALAR
    if GameData::Species::DATA[:CORSOLA_GALAR]
      sp = GameData::Species::DATA[:CORSOLA_GALAR]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # COTTONEE
    if GameData::Species::DATA[:COTTONEE]
      sp = GameData::Species::DATA[:COTTONEE]
      [:GRASSYGLIDE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CRADILY
    if GameData::Species::DATA[:CRADILY]
      sp = GameData::Species::DATA[:CRADILY]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CRAMORANT_GORGING
    if GameData::Species::DATA[:CRAMORANT_GORGING]
      sp = GameData::Species::DATA[:CRAMORANT_GORGING]
      [:DUALWINGBEAT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CRAMORANT_GULPING
    if GameData::Species::DATA[:CRAMORANT_GULPING]
      sp = GameData::Species::DATA[:CRAMORANT_GULPING]
      [:DUALWINGBEAT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CRANIDOS
    if GameData::Species::DATA[:CRANIDOS]
      sp = GameData::Species::DATA[:CRANIDOS]
      [:DRAGONCHEER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CRESSELIA
    if GameData::Species::DATA[:CRESSELIA]
      sp = GameData::Species::DATA[:CRESSELIA]
      [:EXPANDINGFORCE, :LUNARBLESSING, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CROBAT
    if GameData::Species::DATA[:CROBAT]
      sp = GameData::Species::DATA[:CROBAT]
      [:DUALWINGBEAT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CROCONAW
    if GameData::Species::DATA[:CROCONAW]
      sp = GameData::Species::DATA[:CROCONAW]
      [:BREAKINGSWIPE, :CHILLINGWATER, :FLIPTURN, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CUBONE
    if GameData::Species::DATA[:CUBONE]
      sp = GameData::Species::DATA[:CUBONE]
      [:SCORCHINGSANDS].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # CYNDAQUIL
    if GameData::Species::DATA[:CYNDAQUIL]
      sp = GameData::Species::DATA[:CYNDAQUIL]
      [:BURNINGJEALOUSY, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DARKRAI
    if GameData::Species::DATA[:DARKRAI]
      sp = GameData::Species::DATA[:DARKRAI]
      [:LASHOUT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DARMANITAN_GALAR_STANDARD
    if GameData::Species::DATA[:DARMANITAN_GALAR_STANDARD]
      sp = GameData::Species::DATA[:DARMANITAN_GALAR_STANDARD]
      [:BODYPRESS, :BURNINGJEALOUSY, :LASHOUT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DARMANITAN_GALAR_ZEN
    if GameData::Species::DATA[:DARMANITAN_GALAR_ZEN]
      sp = GameData::Species::DATA[:DARMANITAN_GALAR_ZEN]
      [:BODYPRESS, :BURNINGJEALOUSY, :LASHOUT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DARMANITAN_ZEN
    if GameData::Species::DATA[:DARMANITAN_ZEN]
      sp = GameData::Species::DATA[:DARMANITAN_ZEN]
      [:BODYPRESS, :BURNINGJEALOUSY, :EXPANDINGFORCE, :LASHOUT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DECIDUEYE_HISUI
    if GameData::Species::DATA[:DECIDUEYE_HISUI]
      sp = GameData::Species::DATA[:DECIDUEYE_HISUI]
      [:COACHING, :DUALWINGBEAT, :GRASSYGLIDE, :TERABLAST, :TRAILBLAZE, :TRIPLEARROWS, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DEINO
    if GameData::Species::DATA[:DEINO]
      sp = GameData::Species::DATA[:DEINO]
      [:DRAGONCHEER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DELIBIRD
    if GameData::Species::DATA[:DELIBIRD]
      sp = GameData::Species::DATA[:DELIBIRD]
      [:CHILLINGWATER, :DUALWINGBEAT, :ICESPINNER, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DELPHOX
    if GameData::Species::DATA[:DELPHOX]
      sp = GameData::Species::DATA[:DELPHOX]
      [:BURNINGJEALOUSY, :EXPANDINGFORCE, :PSYCHICNOISE, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DEOXYS
    if GameData::Species::DATA[:DEOXYS]
      sp = GameData::Species::DATA[:DEOXYS]
      [:EXPANDINGFORCE, :METEORBEAM, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DEOXYS_ATTACK
    if GameData::Species::DATA[:DEOXYS_ATTACK]
      sp = GameData::Species::DATA[:DEOXYS_ATTACK]
      [:EXPANDINGFORCE, :METEORBEAM, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DEOXYS_DEFENSE
    if GameData::Species::DATA[:DEOXYS_DEFENSE]
      sp = GameData::Species::DATA[:DEOXYS_DEFENSE]
      [:EXPANDINGFORCE, :METEORBEAM, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DEOXYS_SPEED
    if GameData::Species::DATA[:DEOXYS_SPEED]
      sp = GameData::Species::DATA[:DEOXYS_SPEED]
      [:EXPANDINGFORCE, :METEORBEAM, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DEWGONG
    if GameData::Species::DATA[:DEWGONG]
      sp = GameData::Species::DATA[:DEWGONG]
      [:ALLURINGVOICE, :CHILLINGWATER, :FLIPTURN, :ICESPINNER, :SNOWSCAPE, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DHELMISE
    if GameData::Species::DATA[:DHELMISE]
      sp = GameData::Species::DATA[:DHELMISE]
      [:BODYPRESS, :GRASSYGLIDE, :POLTERGEIST, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DIALGA
    if GameData::Species::DATA[:DIALGA]
      sp = GameData::Species::DATA[:DIALGA]
      [:BODYPRESS, :BREAKINGSWIPE, :SCALESHOT, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DIALGA_ORIGIN
    if GameData::Species::DATA[:DIALGA_ORIGIN]
      sp = GameData::Species::DATA[:DIALGA_ORIGIN]
      [:BODYPRESS, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DIANCIE
    if GameData::Species::DATA[:DIANCIE]
      sp = GameData::Species::DATA[:DIANCIE]
      [:BODYPRESS, :METEORBEAM, :MISTYEXPLOSION, :SCORCHINGSANDS, :SNOWSCAPE, :TERABLAST, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DIGLETT
    if GameData::Species::DATA[:DIGLETT]
      sp = GameData::Species::DATA[:DIGLETT]
      [:SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DIGLETT_ALOLA
    if GameData::Species::DATA[:DIGLETT_ALOLA]
      sp = GameData::Species::DATA[:DIGLETT_ALOLA]
      [:SCORCHINGSANDS, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DODRIO
    if GameData::Species::DATA[:DODRIO]
      sp = GameData::Species::DATA[:DODRIO]
      [:POUNCE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DODUO
    if GameData::Species::DATA[:DODUO]
      sp = GameData::Species::DATA[:DODUO]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DONPHAN
    if GameData::Species::DATA[:DONPHAN]
      sp = GameData::Species::DATA[:DONPHAN]
      [:BODYPRESS, :ICESPINNER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DOUBLADE
    if GameData::Species::DATA[:DOUBLADE]
      sp = GameData::Species::DATA[:DOUBLADE]
      [:STEELBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DRAGONAIR
    if GameData::Species::DATA[:DRAGONAIR]
      sp = GameData::Species::DATA[:DRAGONAIR]
      [:BREAKINGSWIPE, :CHILLINGWATER, :DRAGONCHEER, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DRAGONITE
    if GameData::Species::DATA[:DRAGONITE]
      sp = GameData::Species::DATA[:DRAGONITE]
      [:BODYPRESS, :BREAKINGSWIPE, :CHILLINGWATER, :DRAGONCHEER, :DUALWINGBEAT, :ICESPINNER, :SCALESHOT, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DRATINI
    if GameData::Species::DATA[:DRATINI]
      sp = GameData::Species::DATA[:DRATINI]
      [:BREAKINGSWIPE, :CHILLINGWATER, :DRAGONCHEER, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DRIFBLIM
    if GameData::Species::DATA[:DRIFBLIM]
      sp = GameData::Species::DATA[:DRIFBLIM]
      [:TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DRIFLOON
    if GameData::Species::DATA[:DRIFLOON]
      sp = GameData::Species::DATA[:DRIFLOON]
      [:TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DROWZEE
    if GameData::Species::DATA[:DROWZEE]
      sp = GameData::Species::DATA[:DROWZEE]
      [:EXPANDINGFORCE, :PSYCHICNOISE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DUDUNSPARCE_THREE_SEGMENT
    if GameData::Species::DATA[:DUDUNSPARCE_THREE_SEGMENT]
      sp = GameData::Species::DATA[:DUDUNSPARCE_THREE_SEGMENT]
      [:BODYPRESS, :BREAKINGSWIPE, :CHILLINGWATER, :DUALWINGBEAT, :HYPERDRILL, :ICESPINNER, :POUNCE, :SCALESHOT, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DUGTRIO
    if GameData::Species::DATA[:DUGTRIO]
      sp = GameData::Species::DATA[:DUGTRIO]
      [:SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DUGTRIO_ALOLA
    if GameData::Species::DATA[:DUGTRIO_ALOLA]
      sp = GameData::Species::DATA[:DUGTRIO_ALOLA]
      [:SCORCHINGSANDS, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DUNSPARCE
    if GameData::Species::DATA[:DUNSPARCE]
      sp = GameData::Species::DATA[:DUNSPARCE]
      [:BREAKINGSWIPE, :CHILLINGWATER, :DUALWINGBEAT, :HYPERDRILL, :ICESPINNER, :POUNCE, :SCALESHOT, :SKITTERSMACK, :TERABLAST, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DUOSION
    if GameData::Species::DATA[:DUOSION]
      sp = GameData::Species::DATA[:DUOSION]
      [:EXPANDINGFORCE, :STEELROLLER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DUSCLOPS
    if GameData::Species::DATA[:DUSCLOPS]
      sp = GameData::Species::DATA[:DUSCLOPS]
      [:POLTERGEIST, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DUSKNOIR
    if GameData::Species::DATA[:DUSKNOIR]
      sp = GameData::Species::DATA[:DUSKNOIR]
      [:HARDPRESS, :POLTERGEIST, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # DUSKULL
    if GameData::Species::DATA[:DUSKULL]
      sp = GameData::Species::DATA[:DUSKULL]
      [:POLTERGEIST, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # EEVEE
    if GameData::Species::DATA[:EEVEE]
      sp = GameData::Species::DATA[:EEVEE]
      [:ALLURINGVOICE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # EEVEE_STARTER
    if GameData::Species::DATA[:EEVEE_STARTER]
      sp = GameData::Species::DATA[:EEVEE_STARTER]
      [:BADDYBAD, :BOUNCYBUBBLE, :BUZZYBUZZ, :FREEZYFROST, :GLITZYGLOW, :SAPPYSEED, :SIZZLYSLIDE, :SPARKLYSWIRL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # EISCUE_NOICE
    if GameData::Species::DATA[:EISCUE_NOICE]
      sp = GameData::Species::DATA[:EISCUE_NOICE]
      [:CHILLINGWATER, :FLIPTURN, :ICESPINNER, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # EKANS
    if GameData::Species::DATA[:EKANS]
      sp = GameData::Species::DATA[:EKANS]
      [:LASHOUT, :SCALESHOT, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ELECTABUZZ
    if GameData::Species::DATA[:ELECTABUZZ]
      sp = GameData::Species::DATA[:ELECTABUZZ]
      [:RISINGVOLTAGE, :SUPERCELLSLAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ELECTIVIRE
    if GameData::Species::DATA[:ELECTIVIRE]
      sp = GameData::Species::DATA[:ELECTIVIRE]
      [:RISINGVOLTAGE, :SUPERCELLSLAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ELECTRODE
    if GameData::Species::DATA[:ELECTRODE]
      sp = GameData::Species::DATA[:ELECTRODE]
      [:SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ELECTRODE_HISUI
    if GameData::Species::DATA[:ELECTRODE_HISUI]
      sp = GameData::Species::DATA[:ELECTRODE_HISUI]
      [:CHLOROBLAST, :GRASSYGLIDE, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ELEKID
    if GameData::Species::DATA[:ELEKID]
      sp = GameData::Species::DATA[:ELEKID]
      [:SUPERCELLSLAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # EMPOLEON
    if GameData::Species::DATA[:EMPOLEON]
      sp = GameData::Species::DATA[:EMPOLEON]
      [:CHILLINGWATER, :DUALWINGBEAT, :FLIPTURN, :ICESPINNER, :LASHOUT, :SNOWSCAPE, :STEELBEAM, :TERABLAST, :TRIPLEAXEL, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ENAMORUS_THERIAN
    if GameData::Species::DATA[:ENAMORUS_THERIAN]
      sp = GameData::Species::DATA[:ENAMORUS_THERIAN]
      [:ALLURINGVOICE, :MISTYEXPLOSION, :SPRINGTIDESTORM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ENTEI
    if GameData::Species::DATA[:ENTEI]
      sp = GameData::Species::DATA[:ENTEI]
      [:SCORCHINGSANDS, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ESPEON
    if GameData::Species::DATA[:ESPEON]
      sp = GameData::Species::DATA[:ESPEON]
      [:ALLURINGVOICE, :EXPANDINGFORCE, :PSYCHICNOISE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ETERNATUS_ETERNAMAX
    if GameData::Species::DATA[:ETERNATUS_ETERNAMAX]
      sp = GameData::Species::DATA[:ETERNATUS_ETERNAMAX]
      [:DYNAMAXCANNON, :ETERNABEAM, :METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # EXEGGCUTE
    if GameData::Species::DATA[:EXEGGCUTE]
      sp = GameData::Species::DATA[:EXEGGCUTE]
      [:GRASSYGLIDE, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # EXEGGUTOR
    if GameData::Species::DATA[:EXEGGUTOR]
      sp = GameData::Species::DATA[:EXEGGUTOR]
      [:EXPANDINGFORCE, :GRASSYGLIDE, :PSYCHICNOISE, :TERABLAST, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # EXEGGUTOR_ALOLA
    if GameData::Species::DATA[:EXEGGUTOR_ALOLA]
      sp = GameData::Species::DATA[:EXEGGUTOR_ALOLA]
      [:BREAKINGSWIPE, :DRAGONCHEER, :GRASSYGLIDE, :PSYCHICNOISE, :TERABLAST, :TERRAINPULSE, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FARFETCHD
    if GameData::Species::DATA[:FARFETCHD]
      sp = GameData::Species::DATA[:FARFETCHD]
      [:DUALWINGBEAT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FARFETCHD_GALAR
    if GameData::Species::DATA[:FARFETCHD_GALAR]
      sp = GameData::Species::DATA[:FARFETCHD_GALAR]
      [:DUALWINGBEAT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FEEBAS
    if GameData::Species::DATA[:FEEBAS]
      sp = GameData::Species::DATA[:FEEBAS]
      [:CHILLINGWATER, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FENNEKIN
    if GameData::Species::DATA[:FENNEKIN]
      sp = GameData::Species::DATA[:FENNEKIN]
      [:BURNINGJEALOUSY, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FERALIGATR
    if GameData::Species::DATA[:FERALIGATR]
      sp = GameData::Species::DATA[:FERALIGATR]
      [:BREAKINGSWIPE, :CHILLINGWATER, :FLIPTURN, :LASHOUT, :SCALESHOT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FERROSEED
    if GameData::Species::DATA[:FERROSEED]
      sp = GameData::Species::DATA[:FERROSEED]
      [:STEELBEAM, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FERROTHORN
    if GameData::Species::DATA[:FERROTHORN]
      sp = GameData::Species::DATA[:FERROTHORN]
      [:BODYPRESS, :STEELBEAM, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FLAAFFY
    if GameData::Species::DATA[:FLAAFFY]
      sp = GameData::Species::DATA[:FLAAFFY]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FLAREON
    if GameData::Species::DATA[:FLAREON]
      sp = GameData::Species::DATA[:FLAREON]
      [:ALLURINGVOICE, :BURNINGJEALOUSY, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FLETCHINDER
    if GameData::Species::DATA[:FLETCHINDER]
      sp = GameData::Species::DATA[:FLETCHINDER]
      [:DUALWINGBEAT, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FLETCHLING
    if GameData::Species::DATA[:FLETCHLING]
      sp = GameData::Species::DATA[:FLETCHLING]
      [:DUALWINGBEAT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FLUTTER_MANE
    if GameData::Species::DATA[:FLUTTER_MANE]
      sp = GameData::Species::DATA[:FLUTTER_MANE]
      [:POLTERGEIST, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FLYGON
    if GameData::Species::DATA[:FLYGON]
      sp = GameData::Species::DATA[:FLYGON]
      [:ALLURINGVOICE, :BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :PSYCHICNOISE, :SCALESHOT, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FOMANTIS
    if GameData::Species::DATA[:FOMANTIS]
      sp = GameData::Species::DATA[:FOMANTIS]
      [:GRASSYGLIDE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FORRETRESS
    if GameData::Species::DATA[:FORRETRESS]
      sp = GameData::Species::DATA[:FORRETRESS]
      [:BODYPRESS, :HARDPRESS, :ICESPINNER, :POUNCE, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FRAXURE
    if GameData::Species::DATA[:FRAXURE]
      sp = GameData::Species::DATA[:FRAXURE]
      [:BREAKINGSWIPE, :DRAGONCHEER, :SCALESHOT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FRILLISH_MALE
    if GameData::Species::DATA[:FRILLISH_MALE]
      sp = GameData::Species::DATA[:FRILLISH_MALE]
      [:POLTERGEIST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FROAKIE
    if GameData::Species::DATA[:FROAKIE]
      sp = GameData::Species::DATA[:FROAKIE]
      [:CHILLINGWATER, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FROGADIER
    if GameData::Species::DATA[:FROGADIER]
      sp = GameData::Species::DATA[:FROGADIER]
      [:CHILLINGWATER, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FROSLASS
    if GameData::Species::DATA[:FROSLASS]
      sp = GameData::Species::DATA[:FROSLASS]
      [:CHILLINGWATER, :ICESPINNER, :POLTERGEIST, :SNOWSCAPE, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # FURRET
    if GameData::Species::DATA[:FURRET]
      sp = GameData::Species::DATA[:FURRET]
      [:CHILLINGWATER, :TERABLAST, :TIDYUP, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GABITE
    if GameData::Species::DATA[:GABITE]
      sp = GameData::Species::DATA[:GABITE]
      [:BREAKINGSWIPE, :DRAGONCHEER, :SCALESHOT, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GALLADE
    if GameData::Species::DATA[:GALLADE]
      sp = GameData::Species::DATA[:GALLADE]
      [:ALLURINGVOICE, :AQUACUTTER, :COACHING, :EXPANDINGFORCE, :LIFEDEW, :TERABLAST, :TRIPLEAXEL, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GALVANTULA
    if GameData::Species::DATA[:GALVANTULA]
      sp = GameData::Species::DATA[:GALVANTULA]
      [:POUNCE, :RISINGVOLTAGE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GARBODOR
    if GameData::Species::DATA[:GARBODOR]
      sp = GameData::Species::DATA[:GARBODOR]
      [:BODYPRESS, :CORROSIVEGAS].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GARCHOMP
    if GameData::Species::DATA[:GARCHOMP]
      sp = GameData::Species::DATA[:GARCHOMP]
      [:BREAKINGSWIPE, :DRAGONCHEER, :SCALESHOT, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GARDEVOIR
    if GameData::Species::DATA[:GARDEVOIR]
      sp = GameData::Species::DATA[:GARDEVOIR]
      [:ALLURINGVOICE, :EXPANDINGFORCE, :LIFEDEW, :MISTYEXPLOSION, :PSYCHICNOISE, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GASTLY
    if GameData::Species::DATA[:GASTLY]
      sp = GameData::Species::DATA[:GASTLY]
      [:CORROSIVEGAS, :POLTERGEIST, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GENESECT
    if GameData::Species::DATA[:GENESECT]
      sp = GameData::Species::DATA[:GENESECT]
      [:STEELBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GENGAR
    if GameData::Species::DATA[:GENGAR]
      sp = GameData::Species::DATA[:GENGAR]
      [:CORROSIVEGAS, :POLTERGEIST, :PSYCHICNOISE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GEODUDE
    if GameData::Species::DATA[:GEODUDE]
      sp = GameData::Species::DATA[:GEODUDE]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GEODUDE_ALOLA
    if GameData::Species::DATA[:GEODUDE_ALOLA]
      sp = GameData::Species::DATA[:GEODUDE_ALOLA]
      [:SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GIBLE
    if GameData::Species::DATA[:GIBLE]
      sp = GameData::Species::DATA[:GIBLE]
      [:DRAGONCHEER, :SCALESHOT, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GIMMIGHOUL_ROAMING
    if GameData::Species::DATA[:GIMMIGHOUL_ROAMING]
      sp = GameData::Species::DATA[:GIMMIGHOUL_ROAMING]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GIRAFARIG
    if GameData::Species::DATA[:GIRAFARIG]
      sp = GameData::Species::DATA[:GIRAFARIG]
      [:EXPANDINGFORCE, :PSYCHICNOISE, :TERABLAST, :TRAILBLAZE, :TWINBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GIRATINA
    if GameData::Species::DATA[:GIRATINA]
      sp = GameData::Species::DATA[:GIRATINA]
      [:BREAKINGSWIPE, :DUALWINGBEAT, :POLTERGEIST, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GIRATINA_ORIGIN
    if GameData::Species::DATA[:GIRATINA_ORIGIN]
      sp = GameData::Species::DATA[:GIRATINA_ORIGIN]
      [:BREAKINGSWIPE, :DUALWINGBEAT, :POLTERGEIST, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GLACEON
    if GameData::Species::DATA[:GLACEON]
      sp = GameData::Species::DATA[:GLACEON]
      [:ALLURINGVOICE, :CHILLINGWATER, :SNOWSCAPE, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GLALIE
    if GameData::Species::DATA[:GLALIE]
      sp = GameData::Species::DATA[:GLALIE]
      [:CHILLINGWATER, :ICESPINNER, :SNOWSCAPE, :STEELROLLER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GLIGAR
    if GameData::Species::DATA[:GLIGAR]
      sp = GameData::Species::DATA[:GLIGAR]
      [:BREAKINGSWIPE, :DUALWINGBEAT, :SCALESHOT, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GLISCOR
    if GameData::Species::DATA[:GLISCOR]
      sp = GameData::Species::DATA[:GLISCOR]
      [:BREAKINGSWIPE, :DUALWINGBEAT, :SCALESHOT, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GLOOM
    if GameData::Species::DATA[:GLOOM]
      sp = GameData::Species::DATA[:GLOOM]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOLBAT
    if GameData::Species::DATA[:GOLBAT]
      sp = GameData::Species::DATA[:GOLBAT]
      [:DUALWINGBEAT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOLDEEN
    if GameData::Species::DATA[:GOLDEEN]
      sp = GameData::Species::DATA[:GOLDEEN]
      [:FLIPTURN, :SCALESHOT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOLDUCK
    if GameData::Species::DATA[:GOLDUCK]
      sp = GameData::Species::DATA[:GOLDUCK]
      [:CHILLINGWATER, :FLIPTURN, :PSYCHICNOISE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOLEM
    if GameData::Species::DATA[:GOLEM]
      sp = GameData::Species::DATA[:GOLEM]
      [:BODYPRESS, :HARDPRESS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOLEM_ALOLA
    if GameData::Species::DATA[:GOLEM_ALOLA]
      sp = GameData::Species::DATA[:GOLEM_ALOLA]
      [:BODYPRESS, :HARDPRESS, :METEORBEAM, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOLETT
    if GameData::Species::DATA[:GOLETT]
      sp = GameData::Species::DATA[:GOLETT]
      [:POLTERGEIST, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOLISOPOD
    if GameData::Species::DATA[:GOLISOPOD]
      sp = GameData::Species::DATA[:GOLISOPOD]
      [:SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOLURK
    if GameData::Species::DATA[:GOLURK]
      sp = GameData::Species::DATA[:GOLURK]
      [:BODYPRESS, :HARDPRESS, :POLTERGEIST, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOODRA
    if GameData::Species::DATA[:GOODRA]
      sp = GameData::Species::DATA[:GOODRA]
      [:BODYPRESS, :BREAKINGSWIPE, :CHILLINGWATER, :DRAGONCHEER, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOODRA_HISUI
    if GameData::Species::DATA[:GOODRA_HISUI]
      sp = GameData::Species::DATA[:GOODRA_HISUI]
      [:BODYPRESS, :BREAKINGSWIPE, :CHILLINGWATER, :DRAGONCHEER, :ICESPINNER, :LASHOUT, :SHELTER, :SKITTERSMACK, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOOMY
    if GameData::Species::DATA[:GOOMY]
      sp = GameData::Species::DATA[:GOOMY]
      [:CHILLINGWATER, :LIFEDEW, :SHELTER, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOUGING_FIRE
    if GameData::Species::DATA[:GOUGING_FIRE]
      sp = GameData::Species::DATA[:GOUGING_FIRE]
      [:BREAKINGSWIPE, :BURNINGBULWARK, :DRAGONCHEER, :RAGINGFURY, :SCALESHOT, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOURGEIST
    if GameData::Species::DATA[:GOURGEIST]
      sp = GameData::Species::DATA[:GOURGEIST]
      [:GRASSYGLIDE, :POLTERGEIST, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOURGEIST_LARGE
    if GameData::Species::DATA[:GOURGEIST_LARGE]
      sp = GameData::Species::DATA[:GOURGEIST_LARGE]
      [:GRASSYGLIDE, :POLTERGEIST, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOURGEIST_SMALL
    if GameData::Species::DATA[:GOURGEIST_SMALL]
      sp = GameData::Species::DATA[:GOURGEIST_SMALL]
      [:GRASSYGLIDE, :POLTERGEIST, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GOURGEIST_SUPER
    if GameData::Species::DATA[:GOURGEIST_SUPER]
      sp = GameData::Species::DATA[:GOURGEIST_SUPER]
      [:GRASSYGLIDE, :POLTERGEIST, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GRANBULL
    if GameData::Species::DATA[:GRANBULL]
      sp = GameData::Species::DATA[:GRANBULL]
      [:LASHOUT, :TEMPERFLARE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GRAVELER
    if GameData::Species::DATA[:GRAVELER]
      sp = GameData::Species::DATA[:GRAVELER]
      [:BODYPRESS, :HARDPRESS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GRAVELER_ALOLA
    if GameData::Species::DATA[:GRAVELER_ALOLA]
      sp = GameData::Species::DATA[:GRAVELER_ALOLA]
      [:HARDPRESS, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GREAT_TUSK
    if GameData::Species::DATA[:GREAT_TUSK]
      sp = GameData::Species::DATA[:GREAT_TUSK]
      [:BODYPRESS, :HEADLONGRUSH, :ICESPINNER, :SUPERCELLSLAM, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GRENINJA
    if GameData::Species::DATA[:GRENINJA]
      sp = GameData::Species::DATA[:GRENINJA]
      [:CHILLINGWATER, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GRENINJA_ASH
    if GameData::Species::DATA[:GRENINJA_ASH]
      sp = GameData::Species::DATA[:GRENINJA_ASH]
      [:CHILLINGWATER, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GRIMER
    if GameData::Species::DATA[:GRIMER]
      sp = GameData::Species::DATA[:GRIMER]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GRIMER_ALOLA
    if GameData::Species::DATA[:GRIMER_ALOLA]
      sp = GameData::Species::DATA[:GRIMER_ALOLA]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GROTLE
    if GameData::Species::DATA[:GROTLE]
      sp = GameData::Species::DATA[:GROTLE]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GROUDON
    if GameData::Species::DATA[:GROUDON]
      sp = GameData::Species::DATA[:GROUDON]
      [:BODYPRESS, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GROVYLE
    if GameData::Species::DATA[:GROVYLE]
      sp = GameData::Species::DATA[:GROVYLE]
      [:BREAKINGSWIPE, :GRASSYGLIDE, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GROWLITHE
    if GameData::Species::DATA[:GROWLITHE]
      sp = GameData::Species::DATA[:GROWLITHE]
      [:RAGINGFURY, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GROWLITHE_HISUI
    if GameData::Species::DATA[:GROWLITHE_HISUI]
      sp = GameData::Species::DATA[:GROWLITHE_HISUI]
      [:SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # GYARADOS
    if GameData::Species::DATA[:GYARADOS]
      sp = GameData::Species::DATA[:GYARADOS]
      [:CHILLINGWATER, :DRAGONCHEER, :LASHOUT, :SCALESHOT, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HAKAMO_O
    if GameData::Species::DATA[:HAKAMO_O]
      sp = GameData::Species::DATA[:HAKAMO_O]
      [:BREAKINGSWIPE, :COACHING, :DRAGONCHEER, :SCALESHOT, :TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HAPPINY
    if GameData::Species::DATA[:HAPPINY]
      sp = GameData::Species::DATA[:HAPPINY]
      [:SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HAUNTER
    if GameData::Species::DATA[:HAUNTER]
      sp = GameData::Species::DATA[:HAUNTER]
      [:CORROSIVEGAS, :POLTERGEIST, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HAWLUCHA
    if GameData::Species::DATA[:HAWLUCHA]
      sp = GameData::Species::DATA[:HAWLUCHA]
      [:BODYPRESS, :COACHING, :DUALWINGBEAT, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HAXORUS
    if GameData::Species::DATA[:HAXORUS]
      sp = GameData::Species::DATA[:HAXORUS]
      [:BREAKINGSWIPE, :DRAGONCHEER, :SCALESHOT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HERACROSS
    if GameData::Species::DATA[:HERACROSS]
      sp = GameData::Species::DATA[:HERACROSS]
      [:COACHING, :POUNCE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HITMONCHAN
    if GameData::Species::DATA[:HITMONCHAN]
      sp = GameData::Species::DATA[:HITMONCHAN]
      [:COACHING, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HITMONLEE
    if GameData::Species::DATA[:HITMONLEE]
      sp = GameData::Species::DATA[:HITMONLEE]
      [:AXEKICK, :COACHING, :TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HITMONTOP
    if GameData::Species::DATA[:HITMONTOP]
      sp = GameData::Species::DATA[:HITMONTOP]
      [:COACHING, :ICESPINNER, :TERABLAST, :TRIPLEAXEL, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HONCHKROW
    if GameData::Species::DATA[:HONCHKROW]
      sp = GameData::Species::DATA[:HONCHKROW]
      [:CHILLINGWATER, :COMEUPPANCE, :DUALWINGBEAT, :LASHOUT, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HONEDGE
    if GameData::Species::DATA[:HONEDGE]
      sp = GameData::Species::DATA[:HONEDGE]
      [:STEELBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HOOPA_UNBOUND
    if GameData::Species::DATA[:HOOPA_UNBOUND]
      sp = GameData::Species::DATA[:HOOPA_UNBOUND]
      [:EXPANDINGFORCE, :LASHOUT, :PSYCHICNOISE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HOOTHOOT
    if GameData::Species::DATA[:HOOTHOOT]
      sp = GameData::Species::DATA[:HOOTHOOT]
      [:DUALWINGBEAT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HOPPIP
    if GameData::Species::DATA[:HOPPIP]
      sp = GameData::Species::DATA[:HOPPIP]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HORSEA
    if GameData::Species::DATA[:HORSEA]
      sp = GameData::Species::DATA[:HORSEA]
      [:CHILLINGWATER, :FLIPTURN, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HOUNDOOM
    if GameData::Species::DATA[:HOUNDOOM]
      sp = GameData::Species::DATA[:HOUNDOOM]
      [:BURNINGJEALOUSY, :COMEUPPANCE, :LASHOUT, :TEMPERFLARE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HOUNDOUR
    if GameData::Species::DATA[:HOUNDOUR]
      sp = GameData::Species::DATA[:HOUNDOUR]
      [:BURNINGJEALOUSY, :COMEUPPANCE, :LASHOUT, :TEMPERFLARE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HO_OH
    if GameData::Species::DATA[:HO_OH]
      sp = GameData::Species::DATA[:HO_OH]
      [:DUALWINGBEAT, :LIFEDEW, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HYDREIGON
    if GameData::Species::DATA[:HYDREIGON]
      sp = GameData::Species::DATA[:HYDREIGON]
      [:BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :LASHOUT, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # HYPNO
    if GameData::Species::DATA[:HYPNO]
      sp = GameData::Species::DATA[:HYPNO]
      [:BODYPRESS, :EXPANDINGFORCE, :PSYCHICNOISE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IGGLYBUFF
    if GameData::Species::DATA[:IGGLYBUFF]
      sp = GameData::Species::DATA[:IGGLYBUFF]
      [:ALLURINGVOICE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # INDEEDEE_FEMALE
    if GameData::Species::DATA[:INDEEDEE_FEMALE]
      sp = GameData::Species::DATA[:INDEEDEE_FEMALE]
      [:EXPANDINGFORCE, :PSYCHICNOISE, :TERABLAST, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # INFERNAPE
    if GameData::Species::DATA[:INFERNAPE]
      sp = GameData::Species::DATA[:INFERNAPE]
      [:BURNINGJEALOUSY, :COACHING, :LASHOUT, :RAGINGFURY, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_BOULDER
    if GameData::Species::DATA[:IRON_BOULDER]
      sp = GameData::Species::DATA[:IRON_BOULDER]
      [:METEORBEAM, :MIGHTYCLEAVE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_BUNDLE
    if GameData::Species::DATA[:IRON_BUNDLE]
      sp = GameData::Species::DATA[:IRON_BUNDLE]
      [:CHILLINGWATER, :FLIPTURN, :ICESPINNER, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_CROWN
    if GameData::Species::DATA[:IRON_CROWN]
      sp = GameData::Species::DATA[:IRON_CROWN]
      [:EXPANDINGFORCE, :PSYCHICNOISE, :STEELBEAM, :SUPERCELLSLAM, :TACHYONCUTTER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_HANDS
    if GameData::Species::DATA[:IRON_HANDS]
      sp = GameData::Species::DATA[:IRON_HANDS]
      [:BODYPRESS, :HARDPRESS, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_JUGULIS
    if GameData::Species::DATA[:IRON_JUGULIS]
      sp = GameData::Species::DATA[:IRON_JUGULIS]
      [:DRAGONCHEER, :DUALWINGBEAT, :LASHOUT, :METEORBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_LEAVES
    if GameData::Species::DATA[:IRON_LEAVES]
      sp = GameData::Species::DATA[:IRON_LEAVES]
      [:COACHING, :PSYBLADE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_MOTH
    if GameData::Species::DATA[:IRON_MOTH]
      sp = GameData::Species::DATA[:IRON_MOTH]
      [:METEORBEAM, :POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_THORNS
    if GameData::Species::DATA[:IRON_THORNS]
      sp = GameData::Species::DATA[:IRON_THORNS]
      [:BODYPRESS, :BREAKINGSWIPE, :METEORBEAM, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_TREADS
    if GameData::Species::DATA[:IRON_TREADS]
      sp = GameData::Species::DATA[:IRON_TREADS]
      [:BODYPRESS, :HARDPRESS, :ICESPINNER, :STEELBEAM, :STEELROLLER, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IRON_VALIANT
    if GameData::Species::DATA[:IRON_VALIANT]
      sp = GameData::Species::DATA[:IRON_VALIANT]
      [:COACHING, :EXPANDINGFORCE, :SPIRITBREAK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # IVYSAUR
    if GameData::Species::DATA[:IVYSAUR]
      sp = GameData::Species::DATA[:IVYSAUR]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # JANGMO_O
    if GameData::Species::DATA[:JANGMO_O]
      sp = GameData::Species::DATA[:JANGMO_O]
      [:BREAKINGSWIPE, :DRAGONCHEER, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # JELLICENT_MALE
    if GameData::Species::DATA[:JELLICENT_MALE]
      sp = GameData::Species::DATA[:JELLICENT_MALE]
      [:POLTERGEIST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # JIGGLYPUFF
    if GameData::Species::DATA[:JIGGLYPUFF]
      sp = GameData::Species::DATA[:JIGGLYPUFF]
      [:ALLURINGVOICE, :BODYPRESS, :CHILLINGWATER, :ICESPINNER, :MISTYEXPLOSION, :PSYCHICNOISE, :STEELROLLER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # JIRACHI
    if GameData::Species::DATA[:JIRACHI]
      sp = GameData::Species::DATA[:JIRACHI]
      [:EXPANDINGFORCE, :LIFEDEW, :METEORBEAM, :PSYCHICNOISE, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # JOLTEON
    if GameData::Species::DATA[:JOLTEON]
      sp = GameData::Species::DATA[:JOLTEON]
      [:ALLURINGVOICE, :RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # JOLTIK
    if GameData::Species::DATA[:JOLTIK]
      sp = GameData::Species::DATA[:JOLTIK]
      [:POUNCE, :RISINGVOLTAGE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # JUMPLUFF
    if GameData::Species::DATA[:JUMPLUFF]
      sp = GameData::Species::DATA[:JUMPLUFF]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # JYNX
    if GameData::Species::DATA[:JYNX]
      sp = GameData::Species::DATA[:JYNX]
      [:EXPANDINGFORCE, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KABUTO
    if GameData::Species::DATA[:KABUTO]
      sp = GameData::Species::DATA[:KABUTO]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KABUTOPS
    if GameData::Species::DATA[:KABUTOPS]
      sp = GameData::Species::DATA[:KABUTOPS]
      [:FLIPTURN, :METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KADABRA
    if GameData::Species::DATA[:KADABRA]
      sp = GameData::Species::DATA[:KADABRA]
      [:EXPANDINGFORCE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KANGASKHAN
    if GameData::Species::DATA[:KANGASKHAN]
      sp = GameData::Species::DATA[:KANGASKHAN]
      [:TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KELDEO_RESOLUTE
    if GameData::Species::DATA[:KELDEO_RESOLUTE]
      sp = GameData::Species::DATA[:KELDEO_RESOLUTE]
      [:CHILLINGWATER, :COACHING, :FLIPTURN, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KINGDRA
    if GameData::Species::DATA[:KINGDRA]
      sp = GameData::Species::DATA[:KINGDRA]
      [:BREAKINGSWIPE, :CHILLINGWATER, :FLIPTURN, :SCALESHOT, :SNOWSCAPE, :TERABLAST, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KIRLIA
    if GameData::Species::DATA[:KIRLIA]
      sp = GameData::Species::DATA[:KIRLIA]
      [:ALLURINGVOICE, :EXPANDINGFORCE, :LIFEDEW, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KLANG
    if GameData::Species::DATA[:KLANG]
      sp = GameData::Species::DATA[:KLANG]
      [:RISINGVOLTAGE, :STEELBEAM, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KLEFKI
    if GameData::Species::DATA[:KLEFKI]
      sp = GameData::Species::DATA[:KLEFKI]
      [:SKITTERSMACK, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KLINK
    if GameData::Species::DATA[:KLINK]
      sp = GameData::Species::DATA[:KLINK]
      [:RISINGVOLTAGE, :STEELBEAM, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KLINKLANG
    if GameData::Species::DATA[:KLINKLANG]
      sp = GameData::Species::DATA[:KLINKLANG]
      [:RISINGVOLTAGE, :STEELBEAM, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KOFFING
    if GameData::Species::DATA[:KOFFING]
      sp = GameData::Species::DATA[:KOFFING]
      [:CORROSIVEGAS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KOMMO_O
    if GameData::Species::DATA[:KOMMO_O]
      sp = GameData::Species::DATA[:KOMMO_O]
      [:BODYPRESS, :BREAKINGSWIPE, :CLANGOROUSSOUL, :COACHING, :DRAGONCHEER, :SCALESHOT, :TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KORAIDON_GLIDING_BUILD
    if GameData::Species::DATA[:KORAIDON_GLIDING_BUILD]
      sp = GameData::Species::DATA[:KORAIDON_GLIDING_BUILD]
      [:BODYPRESS, :BREAKINGSWIPE, :COLLISIONCOURSE, :DUALWINGBEAT, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KORAIDON_LIMITED_BUILD
    if GameData::Species::DATA[:KORAIDON_LIMITED_BUILD]
      sp = GameData::Species::DATA[:KORAIDON_LIMITED_BUILD]
      [:BODYPRESS, :BREAKINGSWIPE, :COLLISIONCOURSE, :DUALWINGBEAT, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KORAIDON_SPRINTING_BUILD
    if GameData::Species::DATA[:KORAIDON_SPRINTING_BUILD]
      sp = GameData::Species::DATA[:KORAIDON_SPRINTING_BUILD]
      [:BODYPRESS, :BREAKINGSWIPE, :COLLISIONCOURSE, :DUALWINGBEAT, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KORAIDON_SWIMMING_BUILD
    if GameData::Species::DATA[:KORAIDON_SWIMMING_BUILD]
      sp = GameData::Species::DATA[:KORAIDON_SWIMMING_BUILD]
      [:BODYPRESS, :BREAKINGSWIPE, :COLLISIONCOURSE, :DUALWINGBEAT, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KROKOROK
    if GameData::Species::DATA[:KROKOROK]
      sp = GameData::Species::DATA[:KROKOROK]
      [:BREAKINGSWIPE, :LASHOUT, :SCALESHOT, :SCORCHINGSANDS, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KROOKODILE
    if GameData::Species::DATA[:KROOKODILE]
      sp = GameData::Species::DATA[:KROOKODILE]
      [:BREAKINGSWIPE, :LASHOUT, :SCALESHOT, :SCORCHINGSANDS, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KYOGRE
    if GameData::Species::DATA[:KYOGRE]
      sp = GameData::Species::DATA[:KYOGRE]
      [:CHILLINGWATER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KYUREM
    if GameData::Species::DATA[:KYUREM]
      sp = GameData::Species::DATA[:KYUREM]
      [:BODYPRESS, :BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :SCALESHOT, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KYUREM_BLACK
    if GameData::Species::DATA[:KYUREM_BLACK]
      sp = GameData::Species::DATA[:KYUREM_BLACK]
      [:BODYPRESS, :BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :SCALESHOT, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # KYUREM_WHITE
    if GameData::Species::DATA[:KYUREM_WHITE]
      sp = GameData::Species::DATA[:KYUREM_WHITE]
      [:BODYPRESS, :BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :SCALESHOT, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LAIRON
    if GameData::Species::DATA[:LAIRON]
      sp = GameData::Species::DATA[:LAIRON]
      [:BODYPRESS, :STEELBEAM, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LAMPENT
    if GameData::Species::DATA[:LAMPENT]
      sp = GameData::Species::DATA[:LAMPENT]
      [:BURNINGJEALOUSY, :LASHOUT, :POLTERGEIST, :SKITTERSMACK, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LANDORUS_THERIAN
    if GameData::Species::DATA[:LANDORUS_THERIAN]
      sp = GameData::Species::DATA[:LANDORUS_THERIAN]
      [:SANDSEARSTORM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LANTURN
    if GameData::Species::DATA[:LANTURN]
      sp = GameData::Species::DATA[:LANTURN]
      [:CHILLINGWATER, :FLIPTURN, :RISINGVOLTAGE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LAPRAS
    if GameData::Species::DATA[:LAPRAS]
      sp = GameData::Species::DATA[:LAPRAS]
      [:ALLURINGVOICE, :BODYPRESS, :CHILLINGWATER, :DRAGONCHEER, :LIFEDEW, :PSYCHICNOISE, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LARVESTA
    if GameData::Species::DATA[:LARVESTA]
      sp = GameData::Species::DATA[:LARVESTA]
      [:POUNCE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LARVITAR
    if GameData::Species::DATA[:LARVITAR]
      sp = GameData::Species::DATA[:LARVITAR]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LATIAS
    if GameData::Species::DATA[:LATIAS]
      sp = GameData::Species::DATA[:LATIAS]
      [:ALLURINGVOICE, :BREAKINGSWIPE, :CHILLINGWATER, :DRAGONCHEER, :DUALWINGBEAT, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LATIOS
    if GameData::Species::DATA[:LATIOS]
      sp = GameData::Species::DATA[:LATIOS]
      [:BREAKINGSWIPE, :CHILLINGWATER, :DRAGONCHEER, :DUALWINGBEAT, :FLIPTURN, :PSYCHICNOISE, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LEAFEON
    if GameData::Species::DATA[:LEAFEON]
      sp = GameData::Species::DATA[:LEAFEON]
      [:ALLURINGVOICE, :GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LICKILICKY
    if GameData::Species::DATA[:LICKILICKY]
      sp = GameData::Species::DATA[:LICKILICKY]
      [:BODYPRESS, :STEELROLLER, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LICKITUNG
    if GameData::Species::DATA[:LICKITUNG]
      sp = GameData::Species::DATA[:LICKITUNG]
      [:BODYPRESS, :STEELROLLER, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LILEEP
    if GameData::Species::DATA[:LILEEP]
      sp = GameData::Species::DATA[:LILEEP]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LILLIGANT_HISUI
    if GameData::Species::DATA[:LILLIGANT_HISUI]
      sp = GameData::Species::DATA[:LILLIGANT_HISUI]
      [:AXEKICK, :COACHING, :GRASSYGLIDE, :ICESPINNER, :TERABLAST, :TRAILBLAZE, :TRIPLEAXEL, :UPPERHAND, :VICTORYDANCE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LINOONE_GALAR
    if GameData::Species::DATA[:LINOONE_GALAR]
      sp = GameData::Species::DATA[:LINOONE_GALAR]
      [:BODYPRESS, :LASHOUT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LITWICK
    if GameData::Species::DATA[:LITWICK]
      sp = GameData::Species::DATA[:LITWICK]
      [:BURNINGJEALOUSY, :POLTERGEIST, :SKITTERSMACK, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LOMBRE
    if GameData::Species::DATA[:LOMBRE]
      sp = GameData::Species::DATA[:LOMBRE]
      [:CHILLINGWATER, :GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LOPUNNY
    if GameData::Species::DATA[:LOPUNNY]
      sp = GameData::Species::DATA[:LOPUNNY]
      [:TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LOTAD
    if GameData::Species::DATA[:LOTAD]
      sp = GameData::Species::DATA[:LOTAD]
      [:CHILLINGWATER, :GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LUCARIO
    if GameData::Species::DATA[:LUCARIO]
      sp = GameData::Species::DATA[:LUCARIO]
      [:COACHING, :LIFEDEW, :STEELBEAM, :TERABLAST, :TERRAINPULSE, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LUDICOLO
    if GameData::Species::DATA[:LUDICOLO]
      sp = GameData::Species::DATA[:LUDICOLO]
      [:CHILLINGWATER, :GRASSYGLIDE, :ICESPINNER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LUGIA
    if GameData::Species::DATA[:LUGIA]
      sp = GameData::Species::DATA[:LUGIA]
      [:CHILLINGWATER, :DUALWINGBEAT, :PSYCHICNOISE, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LURANTIS
    if GameData::Species::DATA[:LURANTIS]
      sp = GameData::Species::DATA[:LURANTIS]
      [:GRASSYGLIDE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LUVDISC
    if GameData::Species::DATA[:LUVDISC]
      sp = GameData::Species::DATA[:LUVDISC]
      [:FLIPTURN, :SCALESHOT, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LUXIO
    if GameData::Species::DATA[:LUXIO]
      sp = GameData::Species::DATA[:LUXIO]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LUXRAY
    if GameData::Species::DATA[:LUXRAY]
      sp = GameData::Species::DATA[:LUXRAY]
      [:RISINGVOLTAGE, :SUPERCELLSLAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LYCANROC
    if GameData::Species::DATA[:LYCANROC]
      sp = GameData::Species::DATA[:LYCANROC]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LYCANROC_DUSK
    if GameData::Species::DATA[:LYCANROC_DUSK]
      sp = GameData::Species::DATA[:LYCANROC_DUSK]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # LYCANROC_MIDNIGHT
    if GameData::Species::DATA[:LYCANROC_MIDNIGHT]
      sp = GameData::Species::DATA[:LYCANROC_MIDNIGHT]
      [:LASHOUT, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MACHAMP
    if GameData::Species::DATA[:MACHAMP]
      sp = GameData::Species::DATA[:MACHAMP]
      [:COACHING].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MACHOKE
    if GameData::Species::DATA[:MACHOKE]
      sp = GameData::Species::DATA[:MACHOKE]
      [:COACHING].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MACHOP
    if GameData::Species::DATA[:MACHOP]
      sp = GameData::Species::DATA[:MACHOP]
      [:COACHING].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAGBY
    if GameData::Species::DATA[:MAGBY]
      sp = GameData::Species::DATA[:MAGBY]
      [:BURNINGJEALOUSY, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAGCARGO
    if GameData::Species::DATA[:MAGCARGO]
      sp = GameData::Species::DATA[:MAGCARGO]
      [:BURNINGJEALOUSY, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAGEARNA_ORIGINAL
    if GameData::Species::DATA[:MAGEARNA_ORIGINAL]
      sp = GameData::Species::DATA[:MAGEARNA_ORIGINAL]
      [:ICESPINNER, :MISTYEXPLOSION, :SNOWSCAPE, :STEELBEAM, :STEELROLLER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAGMAR
    if GameData::Species::DATA[:MAGMAR]
      sp = GameData::Species::DATA[:MAGMAR]
      [:BURNINGJEALOUSY, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAGMORTAR
    if GameData::Species::DATA[:MAGMORTAR]
      sp = GameData::Species::DATA[:MAGMORTAR]
      [:BURNINGJEALOUSY, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAGNEMITE
    if GameData::Species::DATA[:MAGNEMITE]
      sp = GameData::Species::DATA[:MAGNEMITE]
      [:RISINGVOLTAGE, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAGNETON
    if GameData::Species::DATA[:MAGNETON]
      sp = GameData::Species::DATA[:MAGNETON]
      [:RISINGVOLTAGE, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAGNEZONE
    if GameData::Species::DATA[:MAGNEZONE]
      sp = GameData::Species::DATA[:MAGNEZONE]
      [:BODYPRESS, :HARDPRESS, :RISINGVOLTAGE, :STEELBEAM, :STEELROLLER, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAMOSWINE
    if GameData::Species::DATA[:MAMOSWINE]
      sp = GameData::Species::DATA[:MAMOSWINE]
      [:BODYPRESS, :HARDPRESS, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MANKEY
    if GameData::Species::DATA[:MANKEY]
      sp = GameData::Species::DATA[:MANKEY]
      [:LASHOUT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MANTINE
    if GameData::Species::DATA[:MANTINE]
      sp = GameData::Species::DATA[:MANTINE]
      [:BODYPRESS, :DUALWINGBEAT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAREANIE
    if GameData::Species::DATA[:MAREANIE]
      sp = GameData::Species::DATA[:MAREANIE]
      [:CHILLINGWATER, :ICESPINNER, :POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAREEP
    if GameData::Species::DATA[:MAREEP]
      sp = GameData::Species::DATA[:MAREEP]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MARILL
    if GameData::Species::DATA[:MARILL]
      sp = GameData::Species::DATA[:MARILL]
      [:ALLURINGVOICE, :CHILLINGWATER, :ICESPINNER, :MISTYEXPLOSION, :SNOWSCAPE, :STEELROLLER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAROWAK
    if GameData::Species::DATA[:MAROWAK]
      sp = GameData::Species::DATA[:MAROWAK]
      [:SCORCHINGSANDS].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAROWAK_ALOLA
    if GameData::Species::DATA[:MAROWAK_ALOLA]
      sp = GameData::Species::DATA[:MAROWAK_ALOLA]
      [:BURNINGJEALOUSY, :POLTERGEIST, :SCORCHINGSANDS].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MARSHTOMP
    if GameData::Species::DATA[:MARSHTOMP]
      sp = GameData::Species::DATA[:MARSHTOMP]
      [:CHILLINGWATER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAUSHOLD_FAMILY_OF_THREE
    if GameData::Species::DATA[:MAUSHOLD_FAMILY_OF_THREE]
      sp = GameData::Species::DATA[:MAUSHOLD_FAMILY_OF_THREE]
      [:CHILLINGWATER, :POPULATIONBOMB, :TERABLAST, :TIDYUP, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MAWILE
    if GameData::Species::DATA[:MAWILE]
      sp = GameData::Species::DATA[:MAWILE]
      [:STEELBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MEGANIUM
    if GameData::Species::DATA[:MEGANIUM]
      sp = GameData::Species::DATA[:MEGANIUM]
      [:BODYPRESS, :GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MELOETTA
    if GameData::Species::DATA[:MELOETTA]
      sp = GameData::Species::DATA[:MELOETTA]
      [:ALLURINGVOICE, :COACHING, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MELOETTA_PIROUETTE
    if GameData::Species::DATA[:MELOETTA_PIROUETTE]
      sp = GameData::Species::DATA[:MELOETTA_PIROUETTE]
      [:ALLURINGVOICE, :COACHING, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MEOWSTIC_FEMALE
    if GameData::Species::DATA[:MEOWSTIC_FEMALE]
      sp = GameData::Species::DATA[:MEOWSTIC_FEMALE]
      [:ALLURINGVOICE, :EXPANDINGFORCE, :PSYCHICNOISE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MEOWTH
    if GameData::Species::DATA[:MEOWTH]
      sp = GameData::Species::DATA[:MEOWTH]
      [:CHILLINGWATER, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MEOWTH_ALOLA
    if GameData::Species::DATA[:MEOWTH_ALOLA]
      sp = GameData::Species::DATA[:MEOWTH_ALOLA]
      [:CHILLINGWATER, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MEOWTH_GALAR
    if GameData::Species::DATA[:MEOWTH_GALAR]
      sp = GameData::Species::DATA[:MEOWTH_GALAR]
      [:LASHOUT, :STEELBEAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # METAGROSS
    if GameData::Species::DATA[:METAGROSS]
      sp = GameData::Species::DATA[:METAGROSS]
      [:BODYPRESS, :EXPANDINGFORCE, :HARDPRESS, :METEORBEAM, :PSYCHICNOISE, :STEELBEAM, :STEELROLLER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # METANG
    if GameData::Species::DATA[:METANG]
      sp = GameData::Species::DATA[:METANG]
      [:EXPANDINGFORCE, :HARDPRESS, :METEORBEAM, :PSYCHICNOISE, :STEELBEAM, :STEELROLLER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MEW
    if GameData::Species::DATA[:MEW]
      sp = GameData::Species::DATA[:MEW]
      [:ALLURINGVOICE, :BODYPRESS, :BREAKINGSWIPE, :BURNINGJEALOUSY, :CHILLINGWATER, :COACHING, :CORROSIVEGAS, :DRAGONCHEER, :DUALWINGBEAT, :EXPANDINGFORCE, :FLIPTURN, :GRASSYGLIDE, :HARDPRESS, :ICESPINNER, :LASHOUT, :LIFEDEW, :METEORBEAM, :MISTYEXPLOSION, :POLTERGEIST, :POUNCE, :PSYCHICNOISE, :RISINGVOLTAGE, :SCALESHOT, :SCORCHINGSANDS, :SKITTERSMACK, :SNOWSCAPE, :STEELBEAM, :STEELROLLER, :SUPERCELLSLAM, :TEMPERFLARE, :TERABLAST, :TERRAINPULSE, :TRAILBLAZE, :TRIPLEAXEL, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MEWTWO
    if GameData::Species::DATA[:MEWTWO]
      sp = GameData::Species::DATA[:MEWTWO]
      [:CHILLINGWATER, :EXPANDINGFORCE, :LASHOUT, :LIFEDEW, :PSYCHICNOISE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MILOTIC
    if GameData::Species::DATA[:MILOTIC]
      sp = GameData::Species::DATA[:MILOTIC]
      [:ALLURINGVOICE, :BREAKINGSWIPE, :CHILLINGWATER, :DRAGONCHEER, :FLIPTURN, :LIFEDEW, :SCALESHOT, :SKITTERSMACK, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MILTANK
    if GameData::Species::DATA[:MILTANK]
      sp = GameData::Species::DATA[:MILTANK]
      [:BODYPRESS, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MIMIKYU
    if GameData::Species::DATA[:MIMIKYU]
      sp = GameData::Species::DATA[:MIMIKYU]
      [:BURNINGJEALOUSY, :POUNCE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MIMIKYU_BUSTED
    if GameData::Species::DATA[:MIMIKYU_BUSTED]
      sp = GameData::Species::DATA[:MIMIKYU_BUSTED]
      [:BURNINGJEALOUSY, :POUNCE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR
    if GameData::Species::DATA[:MINIOR]
      sp = GameData::Species::DATA[:MINIOR]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_BLUE
    if GameData::Species::DATA[:MINIOR_BLUE]
      sp = GameData::Species::DATA[:MINIOR_BLUE]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_BLUE_METEOR
    if GameData::Species::DATA[:MINIOR_BLUE_METEOR]
      sp = GameData::Species::DATA[:MINIOR_BLUE_METEOR]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_GREEN
    if GameData::Species::DATA[:MINIOR_GREEN]
      sp = GameData::Species::DATA[:MINIOR_GREEN]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_GREEN_METEOR
    if GameData::Species::DATA[:MINIOR_GREEN_METEOR]
      sp = GameData::Species::DATA[:MINIOR_GREEN_METEOR]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_INDIGO
    if GameData::Species::DATA[:MINIOR_INDIGO]
      sp = GameData::Species::DATA[:MINIOR_INDIGO]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_INDIGO_METEOR
    if GameData::Species::DATA[:MINIOR_INDIGO_METEOR]
      sp = GameData::Species::DATA[:MINIOR_INDIGO_METEOR]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_ORANGE
    if GameData::Species::DATA[:MINIOR_ORANGE]
      sp = GameData::Species::DATA[:MINIOR_ORANGE]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_ORANGE_METEOR
    if GameData::Species::DATA[:MINIOR_ORANGE_METEOR]
      sp = GameData::Species::DATA[:MINIOR_ORANGE_METEOR]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_RED
    if GameData::Species::DATA[:MINIOR_RED]
      sp = GameData::Species::DATA[:MINIOR_RED]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_VIOLET
    if GameData::Species::DATA[:MINIOR_VIOLET]
      sp = GameData::Species::DATA[:MINIOR_VIOLET]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_VIOLET_METEOR
    if GameData::Species::DATA[:MINIOR_VIOLET_METEOR]
      sp = GameData::Species::DATA[:MINIOR_VIOLET_METEOR]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_YELLOW
    if GameData::Species::DATA[:MINIOR_YELLOW]
      sp = GameData::Species::DATA[:MINIOR_YELLOW]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MINIOR_YELLOW_METEOR
    if GameData::Species::DATA[:MINIOR_YELLOW_METEOR]
      sp = GameData::Species::DATA[:MINIOR_YELLOW_METEOR]
      [:METEORBEAM, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MIRAIDON_AQUATIC_MODE
    if GameData::Species::DATA[:MIRAIDON_AQUATIC_MODE]
      sp = GameData::Species::DATA[:MIRAIDON_AQUATIC_MODE]
      [:ELECTRODRIFT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MIRAIDON_DRIVE_MODE
    if GameData::Species::DATA[:MIRAIDON_DRIVE_MODE]
      sp = GameData::Species::DATA[:MIRAIDON_DRIVE_MODE]
      [:ELECTRODRIFT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MIRAIDON_GLIDE_MODE
    if GameData::Species::DATA[:MIRAIDON_GLIDE_MODE]
      sp = GameData::Species::DATA[:MIRAIDON_GLIDE_MODE]
      [:ELECTRODRIFT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MIRAIDON_LOW_POWER_MODE
    if GameData::Species::DATA[:MIRAIDON_LOW_POWER_MODE]
      sp = GameData::Species::DATA[:MIRAIDON_LOW_POWER_MODE]
      [:ELECTRODRIFT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MISDREAVUS
    if GameData::Species::DATA[:MISDREAVUS]
      sp = GameData::Species::DATA[:MISDREAVUS]
      [:BURNINGJEALOUSY, :POLTERGEIST, :PSYCHICNOISE, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MISMAGIUS
    if GameData::Species::DATA[:MISMAGIUS]
      sp = GameData::Species::DATA[:MISMAGIUS]
      [:BURNINGJEALOUSY, :LASHOUT, :POLTERGEIST, :PSYCHICNOISE, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MOLTRES
    if GameData::Species::DATA[:MOLTRES]
      sp = GameData::Species::DATA[:MOLTRES]
      [:BURNINGJEALOUSY, :DUALWINGBEAT, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MOLTRES_GALAR
    if GameData::Species::DATA[:MOLTRES_GALAR]
      sp = GameData::Species::DATA[:MOLTRES_GALAR]
      [:DUALWINGBEAT, :FIERYWRATH, :LASHOUT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MONFERNO
    if GameData::Species::DATA[:MONFERNO]
      sp = GameData::Species::DATA[:MONFERNO]
      [:BURNINGJEALOUSY, :LASHOUT, :TEMPERFLARE, :TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MORPEKO_HANGRY
    if GameData::Species::DATA[:MORPEKO_HANGRY]
      sp = GameData::Species::DATA[:MORPEKO_HANGRY]
      [:AURAWHEEL, :LASHOUT, :RISINGVOLTAGE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MR_MIME
    if GameData::Species::DATA[:MR_MIME]
      sp = GameData::Species::DATA[:MR_MIME]
      [:EXPANDINGFORCE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MR_MIME_GALAR
    if GameData::Species::DATA[:MR_MIME_GALAR]
      sp = GameData::Species::DATA[:MR_MIME_GALAR]
      [:EXPANDINGFORCE, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MR_RIME
    if GameData::Species::DATA[:MR_RIME]
      sp = GameData::Species::DATA[:MR_RIME]
      [:EXPANDINGFORCE, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MUDKIP
    if GameData::Species::DATA[:MUDKIP]
      sp = GameData::Species::DATA[:MUDKIP]
      [:CHILLINGWATER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MUK
    if GameData::Species::DATA[:MUK]
      sp = GameData::Species::DATA[:MUK]
      [:LASHOUT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MUK_ALOLA
    if GameData::Species::DATA[:MUK_ALOLA]
      sp = GameData::Species::DATA[:MUK_ALOLA]
      [:LASHOUT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MUNCHLAX
    if GameData::Species::DATA[:MUNCHLAX]
      sp = GameData::Species::DATA[:MUNCHLAX]
      [:CHILLINGWATER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # MURKROW
    if GameData::Species::DATA[:MURKROW]
      sp = GameData::Species::DATA[:MURKROW]
      [:DUALWINGBEAT, :LASHOUT, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NATU
    if GameData::Species::DATA[:NATU]
      sp = GameData::Species::DATA[:NATU]
      [:DUALWINGBEAT, :EXPANDINGFORCE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NECROZMA
    if GameData::Species::DATA[:NECROZMA]
      sp = GameData::Species::DATA[:NECROZMA]
      [:BREAKINGSWIPE, :EXPANDINGFORCE, :METEORBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NECROZMA_DAWN
    if GameData::Species::DATA[:NECROZMA_DAWN]
      sp = GameData::Species::DATA[:NECROZMA_DAWN]
      [:BREAKINGSWIPE, :EXPANDINGFORCE, :METEORBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NECROZMA_DUSK
    if GameData::Species::DATA[:NECROZMA_DUSK]
      sp = GameData::Species::DATA[:NECROZMA_DUSK]
      [:BREAKINGSWIPE, :EXPANDINGFORCE, :METEORBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NIDOKING
    if GameData::Species::DATA[:NIDOKING]
      sp = GameData::Species::DATA[:NIDOKING]
      [:BODYPRESS, :SCORCHINGSANDS].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NIDOQUEEN
    if GameData::Species::DATA[:NIDOQUEEN]
      sp = GameData::Species::DATA[:NIDOQUEEN]
      [:BODYPRESS, :SCORCHINGSANDS].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NINCADA
    if GameData::Species::DATA[:NINCADA]
      sp = GameData::Species::DATA[:NINCADA]
      [:SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NINETALES
    if GameData::Species::DATA[:NINETALES]
      sp = GameData::Species::DATA[:NINETALES]
      [:BURNINGJEALOUSY, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NINETALES_ALOLA
    if GameData::Species::DATA[:NINETALES_ALOLA]
      sp = GameData::Species::DATA[:NINETALES_ALOLA]
      [:CHILLINGWATER, :SNOWSCAPE, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NINJASK
    if GameData::Species::DATA[:NINJASK]
      sp = GameData::Species::DATA[:NINJASK]
      [:DUALWINGBEAT, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NOCTOWL
    if GameData::Species::DATA[:NOCTOWL]
      sp = GameData::Species::DATA[:NOCTOWL]
      [:DUALWINGBEAT, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NOIBAT
    if GameData::Species::DATA[:NOIBAT]
      sp = GameData::Species::DATA[:NOIBAT]
      [:DUALWINGBEAT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NOIVERN
    if GameData::Species::DATA[:NOIVERN]
      sp = GameData::Species::DATA[:NOIVERN]
      [:BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # NOSEPASS
    if GameData::Species::DATA[:NOSEPASS]
      sp = GameData::Species::DATA[:NOSEPASS]
      [:BODYPRESS, :METEORBEAM, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # OCTILLERY
    if GameData::Species::DATA[:OCTILLERY]
      sp = GameData::Species::DATA[:OCTILLERY]
      [:SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ODDISH
    if GameData::Species::DATA[:ODDISH]
      sp = GameData::Species::DATA[:ODDISH]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # OGERPON_CORNERSTONE_MASK
    if GameData::Species::DATA[:OGERPON_CORNERSTONE_MASK]
      sp = GameData::Species::DATA[:OGERPON_CORNERSTONE_MASK]
      [:GRASSYGLIDE, :IVYCUDGEL, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # OGERPON_HEARTHFLAME_MASK
    if GameData::Species::DATA[:OGERPON_HEARTHFLAME_MASK]
      sp = GameData::Species::DATA[:OGERPON_HEARTHFLAME_MASK]
      [:GRASSYGLIDE, :IVYCUDGEL, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # OGERPON_WELLSPRING_MASK
    if GameData::Species::DATA[:OGERPON_WELLSPRING_MASK]
      sp = GameData::Species::DATA[:OGERPON_WELLSPRING_MASK]
      [:GRASSYGLIDE, :IVYCUDGEL, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # OINKOLOGNE_FEMALE
    if GameData::Species::DATA[:OINKOLOGNE_FEMALE]
      sp = GameData::Species::DATA[:OINKOLOGNE_FEMALE]
      [:BODYPRESS, :CHILLINGWATER, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # OMANYTE
    if GameData::Species::DATA[:OMANYTE]
      sp = GameData::Species::DATA[:OMANYTE]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # OMASTAR
    if GameData::Species::DATA[:OMASTAR]
      sp = GameData::Species::DATA[:OMASTAR]
      [:METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ONIX
    if GameData::Species::DATA[:ONIX]
      sp = GameData::Species::DATA[:ONIX]
      [:BODYPRESS, :BREAKINGSWIPE, :METEORBEAM, :SCORCHINGSANDS].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ORICORIO
    if GameData::Species::DATA[:ORICORIO]
      sp = GameData::Species::DATA[:ORICORIO]
      [:ALLURINGVOICE, :DUALWINGBEAT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ORICORIO_PAU
    if GameData::Species::DATA[:ORICORIO_PAU]
      sp = GameData::Species::DATA[:ORICORIO_PAU]
      [:ALLURINGVOICE, :DUALWINGBEAT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ORICORIO_POM_POM
    if GameData::Species::DATA[:ORICORIO_POM_POM]
      sp = GameData::Species::DATA[:ORICORIO_POM_POM]
      [:ALLURINGVOICE, :DUALWINGBEAT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ORICORIO_SENSU
    if GameData::Species::DATA[:ORICORIO_SENSU]
      sp = GameData::Species::DATA[:ORICORIO_SENSU]
      [:ALLURINGVOICE, :DUALWINGBEAT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PALAFIN_HERO
    if GameData::Species::DATA[:PALAFIN_HERO]
      sp = GameData::Species::DATA[:PALAFIN_HERO]
      [:CHILLINGWATER, :FLIPTURN, :HARDPRESS, :JETPUNCH, :TERABLAST, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PALKIA
    if GameData::Species::DATA[:PALKIA]
      sp = GameData::Species::DATA[:PALKIA]
      [:BODYPRESS, :BREAKINGSWIPE, :CHILLINGWATER, :DUALWINGBEAT, :SCALESHOT, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PALKIA_ORIGIN
    if GameData::Species::DATA[:PALKIA_ORIGIN]
      sp = GameData::Species::DATA[:PALKIA_ORIGIN]
      [:BODYPRESS, :CHILLINGWATER, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PALOSSAND
    if GameData::Species::DATA[:PALOSSAND]
      sp = GameData::Species::DATA[:PALOSSAND]
      [:CHILLINGWATER, :POLTERGEIST, :SCORCHINGSANDS, :TERABLAST, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PAWNIARD
    if GameData::Species::DATA[:PAWNIARD]
      sp = GameData::Species::DATA[:PAWNIARD]
      [:LASHOUT, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PERSIAN
    if GameData::Species::DATA[:PERSIAN]
      sp = GameData::Species::DATA[:PERSIAN]
      [:CHILLINGWATER, :LASHOUT, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PERSIAN_ALOLA
    if GameData::Species::DATA[:PERSIAN_ALOLA]
      sp = GameData::Species::DATA[:PERSIAN_ALOLA]
      [:BURNINGJEALOUSY, :CHILLINGWATER, :LASHOUT, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PHANPY
    if GameData::Species::DATA[:PHANPY]
      sp = GameData::Species::DATA[:PHANPY]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PHANTUMP
    if GameData::Species::DATA[:PHANTUMP]
      sp = GameData::Species::DATA[:PHANTUMP]
      [:BRANCHPOKE, :GRASSYGLIDE, :LASHOUT, :POLTERGEIST, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PICHU
    if GameData::Species::DATA[:PICHU]
      sp = GameData::Species::DATA[:PICHU]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU
    if GameData::Species::DATA[:PIKACHU]
      sp = GameData::Species::DATA[:PIKACHU]
      [:ALLURINGVOICE, :RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU_ALOLA_CAP
    if GameData::Species::DATA[:PIKACHU_ALOLA_CAP]
      sp = GameData::Species::DATA[:PIKACHU_ALOLA_CAP]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU_HOENN_CAP
    if GameData::Species::DATA[:PIKACHU_HOENN_CAP]
      sp = GameData::Species::DATA[:PIKACHU_HOENN_CAP]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU_KALOS_CAP
    if GameData::Species::DATA[:PIKACHU_KALOS_CAP]
      sp = GameData::Species::DATA[:PIKACHU_KALOS_CAP]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU_ORIGINAL_CAP
    if GameData::Species::DATA[:PIKACHU_ORIGINAL_CAP]
      sp = GameData::Species::DATA[:PIKACHU_ORIGINAL_CAP]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU_PARTNER_CAP
    if GameData::Species::DATA[:PIKACHU_PARTNER_CAP]
      sp = GameData::Species::DATA[:PIKACHU_PARTNER_CAP]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU_SINNOH_CAP
    if GameData::Species::DATA[:PIKACHU_SINNOH_CAP]
      sp = GameData::Species::DATA[:PIKACHU_SINNOH_CAP]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU_STARTER
    if GameData::Species::DATA[:PIKACHU_STARTER]
      sp = GameData::Species::DATA[:PIKACHU_STARTER]
      [:FLOATYFALL, :SPLISHYSPLASH, :ZIPPYZAP].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU_UNOVA_CAP
    if GameData::Species::DATA[:PIKACHU_UNOVA_CAP]
      sp = GameData::Species::DATA[:PIKACHU_UNOVA_CAP]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIKACHU_WORLD_CAP
    if GameData::Species::DATA[:PIKACHU_WORLD_CAP]
      sp = GameData::Species::DATA[:PIKACHU_WORLD_CAP]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PILOSWINE
    if GameData::Species::DATA[:PILOSWINE]
      sp = GameData::Species::DATA[:PILOSWINE]
      [:SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PINECO
    if GameData::Species::DATA[:PINECO]
      sp = GameData::Species::DATA[:PINECO]
      [:ICESPINNER, :POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PIPLUP
    if GameData::Species::DATA[:PIPLUP]
      sp = GameData::Species::DATA[:PIPLUP]
      [:CHILLINGWATER, :FLIPTURN, :ICESPINNER, :SNOWSCAPE, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # POLITOED
    if GameData::Species::DATA[:POLITOED]
      sp = GameData::Species::DATA[:POLITOED]
      [:CHILLINGWATER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # POLIWAG
    if GameData::Species::DATA[:POLIWAG]
      sp = GameData::Species::DATA[:POLIWAG]
      [:CHILLINGWATER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # POLIWHIRL
    if GameData::Species::DATA[:POLIWHIRL]
      sp = GameData::Species::DATA[:POLIWHIRL]
      [:CHILLINGWATER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # POLIWRATH
    if GameData::Species::DATA[:POLIWRATH]
      sp = GameData::Species::DATA[:POLIWRATH]
      [:CHILLINGWATER, :COACHING, :TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PONYTA_GALAR
    if GameData::Species::DATA[:PONYTA_GALAR]
      sp = GameData::Species::DATA[:PONYTA_GALAR]
      [:EXPANDINGFORCE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PORYGON
    if GameData::Species::DATA[:PORYGON]
      sp = GameData::Species::DATA[:PORYGON]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PORYGON2
    if GameData::Species::DATA[:PORYGON2]
      sp = GameData::Species::DATA[:PORYGON2]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PORYGONZ
    if GameData::Species::DATA[:PORYGONZ]
      sp = GameData::Species::DATA[:PORYGONZ]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PRIMEAPE
    if GameData::Species::DATA[:PRIMEAPE]
      sp = GameData::Species::DATA[:PRIMEAPE]
      [:LASHOUT, :RAGEFIST, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PRINPLUP
    if GameData::Species::DATA[:PRINPLUP]
      sp = GameData::Species::DATA[:PRINPLUP]
      [:CHILLINGWATER, :FLIPTURN, :ICESPINNER, :SNOWSCAPE, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PROBOPASS
    if GameData::Species::DATA[:PROBOPASS]
      sp = GameData::Species::DATA[:PROBOPASS]
      [:BODYPRESS, :HARDPRESS, :METEORBEAM, :STEELBEAM, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PSYDUCK
    if GameData::Species::DATA[:PSYDUCK]
      sp = GameData::Species::DATA[:PSYDUCK]
      [:CHILLINGWATER, :FLIPTURN, :PSYCHICNOISE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PUMPKABOO
    if GameData::Species::DATA[:PUMPKABOO]
      sp = GameData::Species::DATA[:PUMPKABOO]
      [:GRASSYGLIDE, :POLTERGEIST, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PUMPKABOO_LARGE
    if GameData::Species::DATA[:PUMPKABOO_LARGE]
      sp = GameData::Species::DATA[:PUMPKABOO_LARGE]
      [:GRASSYGLIDE, :POLTERGEIST, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PUMPKABOO_SMALL
    if GameData::Species::DATA[:PUMPKABOO_SMALL]
      sp = GameData::Species::DATA[:PUMPKABOO_SMALL]
      [:GRASSYGLIDE, :POLTERGEIST, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PUMPKABOO_SUPER
    if GameData::Species::DATA[:PUMPKABOO_SUPER]
      sp = GameData::Species::DATA[:PUMPKABOO_SUPER]
      [:GRASSYGLIDE, :POLTERGEIST, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PUPITAR
    if GameData::Species::DATA[:PUPITAR]
      sp = GameData::Species::DATA[:PUPITAR]
      [:LASHOUT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # PYROAR_MALE
    if GameData::Species::DATA[:PYROAR_MALE]
      sp = GameData::Species::DATA[:PYROAR_MALE]
      [:BURNINGJEALOUSY, :TEMPERFLARE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # QUAGSIRE
    if GameData::Species::DATA[:QUAGSIRE]
      sp = GameData::Species::DATA[:QUAGSIRE]
      [:BODYPRESS, :CHILLINGWATER, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # QUILAVA
    if GameData::Species::DATA[:QUILAVA]
      sp = GameData::Species::DATA[:QUILAVA]
      [:BURNINGJEALOUSY, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # QUILLADIN
    if GameData::Species::DATA[:QUILLADIN]
      sp = GameData::Species::DATA[:QUILLADIN]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # QWILFISH
    if GameData::Species::DATA[:QWILFISH]
      sp = GameData::Species::DATA[:QWILFISH]
      [:BARBBARRAGE, :CHILLINGWATER, :FLIPTURN, :SCALESHOT, :STEELROLLER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # QWILFISH_HISUI
    if GameData::Species::DATA[:QWILFISH_HISUI]
      sp = GameData::Species::DATA[:QWILFISH_HISUI]
      [:BARBBARRAGE, :CHILLINGWATER, :LASHOUT, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RAGING_BOLT
    if GameData::Species::DATA[:RAGING_BOLT]
      sp = GameData::Species::DATA[:RAGING_BOLT]
      [:BODYPRESS, :BREAKINGSWIPE, :DRAGONCHEER, :RISINGVOLTAGE, :SUPERCELLSLAM, :TERABLAST, :THUNDERCLAP].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RAICHU
    if GameData::Species::DATA[:RAICHU]
      sp = GameData::Species::DATA[:RAICHU]
      [:ALLURINGVOICE, :RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RAICHU_ALOLA
    if GameData::Species::DATA[:RAICHU_ALOLA]
      sp = GameData::Species::DATA[:RAICHU_ALOLA]
      [:ALLURINGVOICE, :EXPANDINGFORCE, :PSYCHICNOISE, :RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RAIKOU
    if GameData::Species::DATA[:RAIKOU]
      sp = GameData::Species::DATA[:RAIKOU]
      [:RISINGVOLTAGE, :SUPERCELLSLAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RALTS
    if GameData::Species::DATA[:RALTS]
      sp = GameData::Species::DATA[:RALTS]
      [:ALLURINGVOICE, :EXPANDINGFORCE, :LIFEDEW, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RAMPARDOS
    if GameData::Species::DATA[:RAMPARDOS]
      sp = GameData::Species::DATA[:RAMPARDOS]
      [:BODYPRESS, :BREAKINGSWIPE, :DRAGONCHEER, :SUPERCELLSLAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RAPIDASH
    if GameData::Species::DATA[:RAPIDASH]
      sp = GameData::Species::DATA[:RAPIDASH]
      [:SCORCHINGSANDS].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RAPIDASH_GALAR
    if GameData::Species::DATA[:RAPIDASH_GALAR]
      sp = GameData::Species::DATA[:RAPIDASH_GALAR]
      [:EXPANDINGFORCE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RAYQUAZA
    if GameData::Species::DATA[:RAYQUAZA]
      sp = GameData::Species::DATA[:RAYQUAZA]
      [:BREAKINGSWIPE, :DRAGONCHEER, :METEORBEAM, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # REGICE
    if GameData::Species::DATA[:REGICE]
      sp = GameData::Species::DATA[:REGICE]
      [:BODYPRESS, :ICESPINNER, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # REGIGIGAS
    if GameData::Species::DATA[:REGIGIGAS]
      sp = GameData::Species::DATA[:REGIGIGAS]
      [:BODYPRESS, :HARDPRESS, :TERABLAST, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # REGIROCK
    if GameData::Species::DATA[:REGIROCK]
      sp = GameData::Species::DATA[:REGIROCK]
      [:BODYPRESS, :HARDPRESS, :METEORBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # REGISTEEL
    if GameData::Species::DATA[:REGISTEEL]
      sp = GameData::Species::DATA[:REGISTEEL]
      [:BODYPRESS, :HARDPRESS, :ICESPINNER, :METEORBEAM, :STEELBEAM, :STEELROLLER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RESHIRAM
    if GameData::Species::DATA[:RESHIRAM]
      sp = GameData::Species::DATA[:RESHIRAM]
      [:BODYPRESS, :BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :SCALESHOT, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # REUNICLUS
    if GameData::Species::DATA[:REUNICLUS]
      sp = GameData::Species::DATA[:REUNICLUS]
      [:EXPANDINGFORCE, :PSYCHICNOISE, :STEELROLLER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RHYDON
    if GameData::Species::DATA[:RHYDON]
      sp = GameData::Species::DATA[:RHYDON]
      [:BODYPRESS, :BREAKINGSWIPE, :METEORBEAM, :SCORCHINGSANDS, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RHYHORN
    if GameData::Species::DATA[:RHYHORN]
      sp = GameData::Species::DATA[:RHYHORN]
      [:BODYPRESS, :SCORCHINGSANDS, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RHYPERIOR
    if GameData::Species::DATA[:RHYPERIOR]
      sp = GameData::Species::DATA[:RHYPERIOR]
      [:BODYPRESS, :BREAKINGSWIPE, :METEORBEAM, :SCORCHINGSANDS, :SUPERCELLSLAM, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # RIOLU
    if GameData::Species::DATA[:RIOLU]
      sp = GameData::Species::DATA[:RIOLU]
      [:COACHING, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROARING_MOON
    if GameData::Species::DATA[:ROARING_MOON]
      sp = GameData::Species::DATA[:ROARING_MOON]
      [:BODYPRESS, :BREAKINGSWIPE, :DRAGONCHEER, :JAWLOCK, :LASHOUT, :SCALESHOT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROCKRUFF
    if GameData::Species::DATA[:ROCKRUFF]
      sp = GameData::Species::DATA[:ROCKRUFF]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROCKRUFF_OWN_TEMPO
    if GameData::Species::DATA[:ROCKRUFF_OWN_TEMPO]
      sp = GameData::Species::DATA[:ROCKRUFF_OWN_TEMPO]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROSELIA
    if GameData::Species::DATA[:ROSELIA]
      sp = GameData::Species::DATA[:ROSELIA]
      [:GRASSYGLIDE, :LIFEDEW].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROSERADE
    if GameData::Species::DATA[:ROSERADE]
      sp = GameData::Species::DATA[:ROSERADE]
      [:GRASSYGLIDE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROTOM
    if GameData::Species::DATA[:ROTOM]
      sp = GameData::Species::DATA[:ROTOM]
      [:POLTERGEIST, :RISINGVOLTAGE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROTOM_FAN
    if GameData::Species::DATA[:ROTOM_FAN]
      sp = GameData::Species::DATA[:ROTOM_FAN]
      [:POLTERGEIST, :RISINGVOLTAGE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROTOM_FROST
    if GameData::Species::DATA[:ROTOM_FROST]
      sp = GameData::Species::DATA[:ROTOM_FROST]
      [:POLTERGEIST, :RISINGVOLTAGE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROTOM_HEAT
    if GameData::Species::DATA[:ROTOM_HEAT]
      sp = GameData::Species::DATA[:ROTOM_HEAT]
      [:POLTERGEIST, :RISINGVOLTAGE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROTOM_MOW
    if GameData::Species::DATA[:ROTOM_MOW]
      sp = GameData::Species::DATA[:ROTOM_MOW]
      [:POLTERGEIST, :RISINGVOLTAGE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ROTOM_WASH
    if GameData::Species::DATA[:ROTOM_WASH]
      sp = GameData::Species::DATA[:ROTOM_WASH]
      [:POLTERGEIST, :RISINGVOLTAGE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SABLEYE
    if GameData::Species::DATA[:SABLEYE]
      sp = GameData::Species::DATA[:SABLEYE]
      [:LASHOUT, :POLTERGEIST, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SALAMENCE
    if GameData::Species::DATA[:SALAMENCE]
      sp = GameData::Species::DATA[:SALAMENCE]
      [:BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SAMUROTT_HISUI
    if GameData::Species::DATA[:SAMUROTT_HISUI]
      sp = GameData::Species::DATA[:SAMUROTT_HISUI]
      [:CEASELESSEDGE, :CHILLINGWATER, :FLIPTURN, :LASHOUT, :SNOWSCAPE, :TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SANDILE
    if GameData::Species::DATA[:SANDILE]
      sp = GameData::Species::DATA[:SANDILE]
      [:LASHOUT, :SCORCHINGSANDS, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SANDSHREW
    if GameData::Species::DATA[:SANDSHREW]
      sp = GameData::Species::DATA[:SANDSHREW]
      [:SCORCHINGSANDS, :STEELROLLER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SANDSHREW_ALOLA
    if GameData::Species::DATA[:SANDSHREW_ALOLA]
      sp = GameData::Species::DATA[:SANDSHREW_ALOLA]
      [:ICESPINNER, :SNOWSCAPE, :STEELBEAM, :STEELROLLER, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SANDSLASH
    if GameData::Species::DATA[:SANDSLASH]
      sp = GameData::Species::DATA[:SANDSLASH]
      [:SCORCHINGSANDS, :STEELROLLER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SANDSLASH_ALOLA
    if GameData::Species::DATA[:SANDSLASH_ALOLA]
      sp = GameData::Species::DATA[:SANDSLASH_ALOLA]
      [:ICESPINNER, :SNOWSCAPE, :STEELBEAM, :STEELROLLER, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SANDYGAST
    if GameData::Species::DATA[:SANDYGAST]
      sp = GameData::Species::DATA[:SANDYGAST]
      [:CHILLINGWATER, :POLTERGEIST, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SANDY_SHOCKS
    if GameData::Species::DATA[:SANDY_SHOCKS]
      sp = GameData::Species::DATA[:SANDY_SHOCKS]
      [:BODYPRESS, :SCORCHINGSANDS, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SCEPTILE
    if GameData::Species::DATA[:SCEPTILE]
      sp = GameData::Species::DATA[:SCEPTILE]
      [:BREAKINGSWIPE, :DRAGONCHEER, :GRASSYGLIDE, :SCALESHOT, :SHEDTAIL, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SCIZOR
    if GameData::Species::DATA[:SCIZOR]
      sp = GameData::Species::DATA[:SCIZOR]
      [:DUALWINGBEAT, :HARDPRESS, :POUNCE, :SKITTERSMACK, :STEELBEAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SCOLIPEDE
    if GameData::Species::DATA[:SCOLIPEDE]
      sp = GameData::Species::DATA[:SCOLIPEDE]
      [:SKITTERSMACK, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SCRAFTY
    if GameData::Species::DATA[:SCRAFTY]
      sp = GameData::Species::DATA[:SCRAFTY]
      [:COACHING, :LASHOUT, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SCRAGGY
    if GameData::Species::DATA[:SCRAGGY]
      sp = GameData::Species::DATA[:SCRAGGY]
      [:COACHING, :LASHOUT, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SCREAM_TAIL
    if GameData::Species::DATA[:SCREAM_TAIL]
      sp = GameData::Species::DATA[:SCREAM_TAIL]
      [:EXPANDINGFORCE, :MISTYEXPLOSION, :PSYCHICNOISE, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SCYTHER
    if GameData::Species::DATA[:SCYTHER]
      sp = GameData::Species::DATA[:SCYTHER]
      [:DUALWINGBEAT, :POUNCE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SEADRA
    if GameData::Species::DATA[:SEADRA]
      sp = GameData::Species::DATA[:SEADRA]
      [:CHILLINGWATER, :FLIPTURN, :SCALESHOT, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SEAKING
    if GameData::Species::DATA[:SEAKING]
      sp = GameData::Species::DATA[:SEAKING]
      [:FLIPTURN, :SCALESHOT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SEEL
    if GameData::Species::DATA[:SEEL]
      sp = GameData::Species::DATA[:SEEL]
      [:CHILLINGWATER, :FLIPTURN, :ICESPINNER, :SNOWSCAPE, :TERABLAST, :TRIPLEAXEL].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SENTRET
    if GameData::Species::DATA[:SENTRET]
      sp = GameData::Species::DATA[:SENTRET]
      [:CHILLINGWATER, :TERABLAST, :TIDYUP, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHARPEDO
    if GameData::Species::DATA[:SHARPEDO]
      sp = GameData::Species::DATA[:SHARPEDO]
      [:FLIPTURN, :SCALESHOT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHAYMIN_SKY
    if GameData::Species::DATA[:SHAYMIN_SKY]
      sp = GameData::Species::DATA[:SHAYMIN_SKY]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHEDINJA
    if GameData::Species::DATA[:SHEDINJA]
      sp = GameData::Species::DATA[:SHEDINJA]
      [:POLTERGEIST, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHELGON
    if GameData::Species::DATA[:SHELGON]
      sp = GameData::Species::DATA[:SHELGON]
      [:DRAGONCHEER, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHELLDER
    if GameData::Species::DATA[:SHELLDER]
      sp = GameData::Species::DATA[:SHELLDER]
      [:CHILLINGWATER, :ICESPINNER, :LIFEDEW, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHIELDON
    if GameData::Species::DATA[:SHIELDON]
      sp = GameData::Species::DATA[:SHIELDON]
      [:HARDPRESS, :SCORCHINGSANDS, :STEELBEAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHINX
    if GameData::Species::DATA[:SHINX]
      sp = GameData::Species::DATA[:SHINX]
      [:RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHROOMISH
    if GameData::Species::DATA[:SHROOMISH]
      sp = GameData::Species::DATA[:SHROOMISH]
      [:POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHUCKLE
    if GameData::Species::DATA[:SHUCKLE]
      sp = GameData::Species::DATA[:SHUCKLE]
      [:METEORBEAM, :SKITTERSMACK, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SHUPPET
    if GameData::Species::DATA[:SHUPPET]
      sp = GameData::Species::DATA[:SHUPPET]
      [:LASHOUT, :POLTERGEIST, :POUNCE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SKARMORY
    if GameData::Species::DATA[:SKARMORY]
      sp = GameData::Species::DATA[:SKARMORY]
      [:BODYPRESS, :DUALWINGBEAT, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SKIPLOOM
    if GameData::Species::DATA[:SKIPLOOM]
      sp = GameData::Species::DATA[:SKIPLOOM]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLAKING
    if GameData::Species::DATA[:SLAKING]
      sp = GameData::Species::DATA[:SLAKING]
      [:BODYPRESS, :CHILLINGWATER, :HARDPRESS, :LASHOUT, :POUNCE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLAKOTH
    if GameData::Species::DATA[:SLAKOTH]
      sp = GameData::Species::DATA[:SLAKOTH]
      [:CHILLINGWATER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLIGGOO
    if GameData::Species::DATA[:SLIGGOO]
      sp = GameData::Species::DATA[:SLIGGOO]
      [:CHILLINGWATER, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLIGGOO_HISUI
    if GameData::Species::DATA[:SLIGGOO_HISUI]
      sp = GameData::Species::DATA[:SLIGGOO_HISUI]
      [:CHILLINGWATER, :ICESPINNER, :SHELTER, :SKITTERSMACK, :STEELBEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLITHER_WING
    if GameData::Species::DATA[:SLITHER_WING]
      sp = GameData::Species::DATA[:SLITHER_WING]
      [:BODYPRESS, :DUALWINGBEAT, :SKITTERSMACK, :TEMPERFLARE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLOWBRO
    if GameData::Species::DATA[:SLOWBRO]
      sp = GameData::Species::DATA[:SLOWBRO]
      [:BODYPRESS, :CHILLINGWATER, :EXPANDINGFORCE, :PSYCHICNOISE, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLOWBRO_GALAR
    if GameData::Species::DATA[:SLOWBRO_GALAR]
      sp = GameData::Species::DATA[:SLOWBRO_GALAR]
      [:BODYPRESS, :CHILLINGWATER, :EXPANDINGFORCE, :SHELLSIDEARM, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLOWKING
    if GameData::Species::DATA[:SLOWKING]
      sp = GameData::Species::DATA[:SLOWKING]
      [:CHILLINGWATER, :CHILLYRECEPTION, :EXPANDINGFORCE, :PSYCHICNOISE, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLOWKING_GALAR
    if GameData::Species::DATA[:SLOWKING_GALAR]
      sp = GameData::Species::DATA[:SLOWKING_GALAR]
      [:CHILLINGWATER, :CHILLYRECEPTION, :EERIESPELL, :EXPANDINGFORCE, :PSYCHICNOISE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLOWPOKE
    if GameData::Species::DATA[:SLOWPOKE]
      sp = GameData::Species::DATA[:SLOWPOKE]
      [:CHILLINGWATER, :EXPANDINGFORCE, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLOWPOKE_GALAR
    if GameData::Species::DATA[:SLOWPOKE_GALAR]
      sp = GameData::Species::DATA[:SLOWPOKE_GALAR]
      [:CHILLINGWATER, :EXPANDINGFORCE, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLUGMA
    if GameData::Species::DATA[:SLUGMA]
      sp = GameData::Species::DATA[:SLUGMA]
      [:TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SLURPUFF
    if GameData::Species::DATA[:SLURPUFF]
      sp = GameData::Species::DATA[:SLURPUFF]
      [:MISTYEXPLOSION].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SNEASEL
    if GameData::Species::DATA[:SNEASEL]
      sp = GameData::Species::DATA[:SNEASEL]
      [:LASHOUT, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE, :TRIPLEAXEL, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SNEASEL_HISUI
    if GameData::Species::DATA[:SNEASEL_HISUI]
      sp = GameData::Species::DATA[:SNEASEL_HISUI]
      [:COACHING, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SNORLAX
    if GameData::Species::DATA[:SNORLAX]
      sp = GameData::Species::DATA[:SNORLAX]
      [:BODYPRESS, :CHILLINGWATER, :HARDPRESS, :STEELROLLER, :SUPERCELLSLAM, :TERABLAST, :TERRAINPULSE, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SNORUNT
    if GameData::Species::DATA[:SNORUNT]
      sp = GameData::Species::DATA[:SNORUNT]
      [:CHILLINGWATER, :ICESPINNER, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SNUBBULL
    if GameData::Species::DATA[:SNUBBULL]
      sp = GameData::Species::DATA[:SNUBBULL]
      [:LASHOUT, :TEMPERFLARE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SOLOSIS
    if GameData::Species::DATA[:SOLOSIS]
      sp = GameData::Species::DATA[:SOLOSIS]
      [:EXPANDINGFORCE, :STEELROLLER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SPINARAK
    if GameData::Species::DATA[:SPINARAK]
      sp = GameData::Species::DATA[:SPINARAK]
      [:POUNCE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SPIRITOMB
    if GameData::Species::DATA[:SPIRITOMB]
      sp = GameData::Species::DATA[:SPIRITOMB]
      [:BURNINGJEALOUSY, :LASHOUT, :POLTERGEIST, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SQUAWKABILLY_BLUE_PLUMAGE
    if GameData::Species::DATA[:SQUAWKABILLY_BLUE_PLUMAGE]
      sp = GameData::Species::DATA[:SQUAWKABILLY_BLUE_PLUMAGE]
      [:DUALWINGBEAT, :LASHOUT, :POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SQUAWKABILLY_WHITE_PLUMAGE
    if GameData::Species::DATA[:SQUAWKABILLY_WHITE_PLUMAGE]
      sp = GameData::Species::DATA[:SQUAWKABILLY_WHITE_PLUMAGE]
      [:DUALWINGBEAT, :LASHOUT, :POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SQUAWKABILLY_YELLOW_PLUMAGE
    if GameData::Species::DATA[:SQUAWKABILLY_YELLOW_PLUMAGE]
      sp = GameData::Species::DATA[:SQUAWKABILLY_YELLOW_PLUMAGE]
      [:DUALWINGBEAT, :LASHOUT, :POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SQUIRTLE
    if GameData::Species::DATA[:SQUIRTLE]
      sp = GameData::Species::DATA[:SQUIRTLE]
      [:CHILLINGWATER, :FLIPTURN, :ICESPINNER, :LIFEDEW, :TERABLAST, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # STANTLER
    if GameData::Species::DATA[:STANTLER]
      sp = GameData::Species::DATA[:STANTLER]
      [:PSYSHIELDBASH, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # STARMIE
    if GameData::Species::DATA[:STARMIE]
      sp = GameData::Species::DATA[:STARMIE]
      [:EXPANDINGFORCE, :FLIPTURN, :METEORBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # STARYU
    if GameData::Species::DATA[:STARYU]
      sp = GameData::Species::DATA[:STARYU]
      [:FLIPTURN].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # STEELIX
    if GameData::Species::DATA[:STEELIX]
      sp = GameData::Species::DATA[:STEELIX]
      [:BODYPRESS, :BREAKINGSWIPE, :METEORBEAM, :SCORCHINGSANDS, :STEELBEAM, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # STUFFUL
    if GameData::Species::DATA[:STUFFUL]
      sp = GameData::Species::DATA[:STUFFUL]
      [:COACHING].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # STUNFISK
    if GameData::Species::DATA[:STUNFISK]
      sp = GameData::Species::DATA[:STUNFISK]
      [:LASHOUT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # STUNFISK_GALAR
    if GameData::Species::DATA[:STUNFISK_GALAR]
      sp = GameData::Species::DATA[:STUNFISK_GALAR]
      [:LASHOUT, :SNAPTRAP, :STEELBEAM, :TERRAINPULSE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SUDOWOODO
    if GameData::Species::DATA[:SUDOWOODO]
      sp = GameData::Species::DATA[:SUDOWOODO]
      [:BODYPRESS, :METEORBEAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SUICUNE
    if GameData::Species::DATA[:SUICUNE]
      sp = GameData::Species::DATA[:SUICUNE]
      [:CHILLINGWATER, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SUNFLORA
    if GameData::Species::DATA[:SUNFLORA]
      sp = GameData::Species::DATA[:SUNFLORA]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SUNKERN
    if GameData::Species::DATA[:SUNKERN]
      sp = GameData::Species::DATA[:SUNKERN]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SWABLU
    if GameData::Species::DATA[:SWABLU]
      sp = GameData::Species::DATA[:SWABLU]
      [:DRAGONCHEER, :DUALWINGBEAT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SWAMPERT
    if GameData::Species::DATA[:SWAMPERT]
      sp = GameData::Species::DATA[:SWAMPERT]
      [:BODYPRESS, :CHILLINGWATER, :FLIPTURN, :HARDPRESS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SWINUB
    if GameData::Species::DATA[:SWINUB]
      sp = GameData::Species::DATA[:SWINUB]
      [:SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SWIRLIX
    if GameData::Species::DATA[:SWIRLIX]
      sp = GameData::Species::DATA[:SWIRLIX]
      [:MISTYEXPLOSION].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # SYLVEON
    if GameData::Species::DATA[:SYLVEON]
      sp = GameData::Species::DATA[:SYLVEON]
      [:ALLURINGVOICE, :MISTYEXPLOSION, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TALONFLAME
    if GameData::Species::DATA[:TALONFLAME]
      sp = GameData::Species::DATA[:TALONFLAME]
      [:DUALWINGBEAT, :TEMPERFLARE, :TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TANGELA
    if GameData::Species::DATA[:TANGELA]
      sp = GameData::Species::DATA[:TANGELA]
      [:GRASSYGLIDE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TANGROWTH
    if GameData::Species::DATA[:TANGROWTH]
      sp = GameData::Species::DATA[:TANGROWTH]
      [:GRASSYGLIDE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TATSUGIRI_DROOPY
    if GameData::Species::DATA[:TATSUGIRI_DROOPY]
      sp = GameData::Species::DATA[:TATSUGIRI_DROOPY]
      [:CHILLINGWATER, :DRAGONCHEER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TATSUGIRI_STRETCHY
    if GameData::Species::DATA[:TATSUGIRI_STRETCHY]
      sp = GameData::Species::DATA[:TATSUGIRI_STRETCHY]
      [:CHILLINGWATER, :DRAGONCHEER, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TAUROS
    if GameData::Species::DATA[:TAUROS]
      sp = GameData::Species::DATA[:TAUROS]
      [:LASHOUT, :RAGINGBULL, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TAUROS_PALDEA_AQUA_BREED
    if GameData::Species::DATA[:TAUROS_PALDEA_AQUA_BREED]
      sp = GameData::Species::DATA[:TAUROS_PALDEA_AQUA_BREED]
      [:BODYPRESS, :CHILLINGWATER, :LASHOUT, :RAGINGBULL, :TERABLAST, :TRAILBLAZE, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TAUROS_PALDEA_BLAZE_BREED
    if GameData::Species::DATA[:TAUROS_PALDEA_BLAZE_BREED]
      sp = GameData::Species::DATA[:TAUROS_PALDEA_BLAZE_BREED]
      [:BODYPRESS, :LASHOUT, :RAGINGBULL, :TEMPERFLARE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TAUROS_PALDEA_COMBAT_BREED
    if GameData::Species::DATA[:TAUROS_PALDEA_COMBAT_BREED]
      sp = GameData::Species::DATA[:TAUROS_PALDEA_COMBAT_BREED]
      [:BODYPRESS, :LASHOUT, :RAGINGBULL, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TEDDIURSA
    if GameData::Species::DATA[:TEDDIURSA]
      sp = GameData::Species::DATA[:TEDDIURSA]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TENTACOOL
    if GameData::Species::DATA[:TENTACOOL]
      sp = GameData::Species::DATA[:TENTACOOL]
      [:CHILLINGWATER, :FLIPTURN, :POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TENTACRUEL
    if GameData::Species::DATA[:TENTACRUEL]
      sp = GameData::Species::DATA[:TENTACRUEL]
      [:CHILLINGWATER, :CORROSIVEGAS, :FLIPTURN, :POUNCE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TERAPAGOS_STELLAR
    if GameData::Species::DATA[:TERAPAGOS_STELLAR]
      sp = GameData::Species::DATA[:TERAPAGOS_STELLAR]
      [:BODYPRESS, :ICESPINNER, :METEORBEAM, :SCORCHINGSANDS, :SUPERCELLSLAM, :TERASTARSTORM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TERAPAGOS_TERASTAL
    if GameData::Species::DATA[:TERAPAGOS_TERASTAL]
      sp = GameData::Species::DATA[:TERAPAGOS_TERASTAL]
      [:BODYPRESS, :ICESPINNER, :METEORBEAM, :SCORCHINGSANDS, :SUPERCELLSLAM, :TERASTARSTORM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # THUNDURUS_THERIAN
    if GameData::Species::DATA[:THUNDURUS_THERIAN]
      sp = GameData::Species::DATA[:THUNDURUS_THERIAN]
      [:LASHOUT, :RISINGVOLTAGE, :SUPERCELLSLAM, :TERABLAST, :WILDBOLTSTORM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TING_LU
    if GameData::Species::DATA[:TING_LU]
      sp = GameData::Species::DATA[:TING_LU]
      [:BODYPRESS, :LASHOUT, :RUINATION, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TOGEKISS
    if GameData::Species::DATA[:TOGEKISS]
      sp = GameData::Species::DATA[:TOGEKISS]
      [:DUALWINGBEAT, :LIFEDEW].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TOGEPI
    if GameData::Species::DATA[:TOGEPI]
      sp = GameData::Species::DATA[:TOGEPI]
      [:LIFEDEW].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TOGETIC
    if GameData::Species::DATA[:TOGETIC]
      sp = GameData::Species::DATA[:TOGETIC]
      [:DUALWINGBEAT, :LIFEDEW].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TORCHIC
    if GameData::Species::DATA[:TORCHIC]
      sp = GameData::Species::DATA[:TORCHIC]
      [:TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TORKOAL
    if GameData::Species::DATA[:TORKOAL]
      sp = GameData::Species::DATA[:TORKOAL]
      [:BODYPRESS, :BURNINGJEALOUSY, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TORNADUS_THERIAN
    if GameData::Species::DATA[:TORNADUS_THERIAN]
      sp = GameData::Species::DATA[:TORNADUS_THERIAN]
      [:BLEAKWINDSTORM, :CHILLINGWATER, :LASHOUT, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TORTERRA
    if GameData::Species::DATA[:TORTERRA]
      sp = GameData::Species::DATA[:TORTERRA]
      [:BODYPRESS, :GRASSYGLIDE, :HARDPRESS, :HEADLONGRUSH, :SCORCHINGSANDS, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TOTODILE
    if GameData::Species::DATA[:TOTODILE]
      sp = GameData::Species::DATA[:TOTODILE]
      [:BREAKINGSWIPE, :CHILLINGWATER, :FLIPTURN, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TOXAPEX
    if GameData::Species::DATA[:TOXAPEX]
      sp = GameData::Species::DATA[:TOXAPEX]
      [:CHILLINGWATER, :ICESPINNER, :POUNCE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TOXTRICITY_LOW_KEY
    if GameData::Species::DATA[:TOXTRICITY_LOW_KEY]
      sp = GameData::Species::DATA[:TOXTRICITY_LOW_KEY]
      [:OVERDRIVE, :PSYCHICNOISE, :RISINGVOLTAGE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TRAPINCH
    if GameData::Species::DATA[:TRAPINCH]
      sp = GameData::Species::DATA[:TRAPINCH]
      [:SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TREECKO
    if GameData::Species::DATA[:TREECKO]
      sp = GameData::Species::DATA[:TREECKO]
      [:BREAKINGSWIPE, :GRASSYGLIDE, :TERABLAST, :TRAILBLAZE, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TREVENANT
    if GameData::Species::DATA[:TREVENANT]
      sp = GameData::Species::DATA[:TREVENANT]
      [:BRANCHPOKE, :BURNINGJEALOUSY, :GRASSYGLIDE, :LASHOUT, :POLTERGEIST, :PSYCHICNOISE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TRUBBISH
    if GameData::Species::DATA[:TRUBBISH]
      sp = GameData::Species::DATA[:TRUBBISH]
      [:CORROSIVEGAS].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TURTWIG
    if GameData::Species::DATA[:TURTWIG]
      sp = GameData::Species::DATA[:TURTWIG]
      [:GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TYPHLOSION
    if GameData::Species::DATA[:TYPHLOSION]
      sp = GameData::Species::DATA[:TYPHLOSION]
      [:BURNINGJEALOUSY, :POLTERGEIST, :SCORCHINGSANDS, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TYPHLOSION_HISUI
    if GameData::Species::DATA[:TYPHLOSION_HISUI]
      sp = GameData::Species::DATA[:TYPHLOSION_HISUI]
      [:BURNINGJEALOUSY, :INFERNALPARADE, :POLTERGEIST, :TEMPERFLARE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TYRANITAR
    if GameData::Species::DATA[:TYRANITAR]
      sp = GameData::Species::DATA[:TYRANITAR]
      [:BODYPRESS, :BREAKINGSWIPE, :HARDPRESS, :LASHOUT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TYRANTRUM
    if GameData::Species::DATA[:TYRANTRUM]
      sp = GameData::Species::DATA[:TYRANTRUM]
      [:BREAKINGSWIPE, :LASHOUT, :METEORBEAM, :SCALESHOT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TYROGUE
    if GameData::Species::DATA[:TYROGUE]
      sp = GameData::Species::DATA[:TYROGUE]
      [:TERABLAST, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # TYRUNT
    if GameData::Species::DATA[:TYRUNT]
      sp = GameData::Species::DATA[:TYRUNT]
      [:LASHOUT, :METEORBEAM, :SCALESHOT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # UMBREON
    if GameData::Species::DATA[:UMBREON]
      sp = GameData::Species::DATA[:UMBREON]
      [:ALLURINGVOICE, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # URSALUNA_BLOODMOON
    if GameData::Species::DATA[:URSALUNA_BLOODMOON]
      sp = GameData::Species::DATA[:URSALUNA_BLOODMOON]
      [:BLOODMOON, :BODYPRESS, :HARDPRESS, :HEADLONGRUSH, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # URSARING
    if GameData::Species::DATA[:URSARING]
      sp = GameData::Species::DATA[:URSARING]
      [:TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # URSHIFU_RAPID_STRIKE
    if GameData::Species::DATA[:URSHIFU_RAPID_STRIKE]
      sp = GameData::Species::DATA[:URSHIFU_RAPID_STRIKE]
      [:BODYPRESS, :CHILLINGWATER, :COACHING, :ICESPINNER, :SURGINGSTRIKES, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VAPOREON
    if GameData::Species::DATA[:VAPOREON]
      sp = GameData::Species::DATA[:VAPOREON]
      [:ALLURINGVOICE, :CHILLINGWATER, :FLIPTURN, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VENIPEDE
    if GameData::Species::DATA[:VENIPEDE]
      sp = GameData::Species::DATA[:VENIPEDE]
      [:SKITTERSMACK, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VENOMOTH
    if GameData::Species::DATA[:VENOMOTH]
      sp = GameData::Species::DATA[:VENOMOTH]
      [:POUNCE, :PSYCHICNOISE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VENONAT
    if GameData::Species::DATA[:VENONAT]
      sp = GameData::Species::DATA[:VENONAT]
      [:POUNCE, :PSYCHICNOISE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VENUSAUR
    if GameData::Species::DATA[:VENUSAUR]
      sp = GameData::Species::DATA[:VENUSAUR]
      [:GRASSYGLIDE, :TERABLAST, :TERRAINPULSE, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VIBRAVA
    if GameData::Species::DATA[:VIBRAVA]
      sp = GameData::Species::DATA[:VIBRAVA]
      [:DUALWINGBEAT, :SCORCHINGSANDS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VICTREEBEL
    if GameData::Species::DATA[:VICTREEBEL]
      sp = GameData::Species::DATA[:VICTREEBEL]
      [:GRASSYGLIDE, :POUNCE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VIGOROTH
    if GameData::Species::DATA[:VIGOROTH]
      sp = GameData::Species::DATA[:VIGOROTH]
      [:CHILLINGWATER, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VILEPLUME
    if GameData::Species::DATA[:VILEPLUME]
      sp = GameData::Species::DATA[:VILEPLUME]
      [:CORROSIVEGAS, :GRASSYGLIDE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VOLCARONA
    if GameData::Species::DATA[:VOLCARONA]
      sp = GameData::Species::DATA[:VOLCARONA]
      [:DUALWINGBEAT, :POUNCE, :SKITTERSMACK, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VOLTORB
    if GameData::Species::DATA[:VOLTORB]
      sp = GameData::Species::DATA[:VOLTORB]
      [:TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VOLTORB_HISUI
    if GameData::Species::DATA[:VOLTORB_HISUI]
      sp = GameData::Species::DATA[:VOLTORB_HISUI]
      [:GRASSYGLIDE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VULPIX
    if GameData::Species::DATA[:VULPIX]
      sp = GameData::Species::DATA[:VULPIX]
      [:BURNINGJEALOUSY, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # VULPIX_ALOLA
    if GameData::Species::DATA[:VULPIX_ALOLA]
      sp = GameData::Species::DATA[:VULPIX_ALOLA]
      [:CHILLINGWATER, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WAILMER
    if GameData::Species::DATA[:WAILMER]
      sp = GameData::Species::DATA[:WAILMER]
      [:BODYPRESS, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WAILORD
    if GameData::Species::DATA[:WAILORD]
      sp = GameData::Species::DATA[:WAILORD]
      [:BODYPRESS, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WALKING_WAKE
    if GameData::Species::DATA[:WALKING_WAKE]
      sp = GameData::Species::DATA[:WALKING_WAKE]
      [:BREAKINGSWIPE, :CHILLINGWATER, :DRAGONCHEER, :FLIPTURN, :HYDROSTEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WARTORTLE
    if GameData::Species::DATA[:WARTORTLE]
      sp = GameData::Species::DATA[:WARTORTLE]
      [:CHILLINGWATER, :FLIPTURN, :ICESPINNER, :LIFEDEW, :TERABLAST, :WAVECRASH].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WEAVILE
    if GameData::Species::DATA[:WEAVILE]
      sp = GameData::Species::DATA[:WEAVILE]
      [:CHILLINGWATER, :ICESPINNER, :LASHOUT, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE, :TRIPLEAXEL, :UPPERHAND].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WEEPINBELL
    if GameData::Species::DATA[:WEEPINBELL]
      sp = GameData::Species::DATA[:WEEPINBELL]
      [:GRASSYGLIDE, :POUNCE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WEEZING
    if GameData::Species::DATA[:WEEZING]
      sp = GameData::Species::DATA[:WEEZING]
      [:CORROSIVEGAS, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WEEZING_GALAR
    if GameData::Species::DATA[:WEEZING_GALAR]
      sp = GameData::Species::DATA[:WEEZING_GALAR]
      [:CORROSIVEGAS, :MISTYEXPLOSION, :STRANGESTEAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WHIMSICOTT
    if GameData::Species::DATA[:WHIMSICOTT]
      sp = GameData::Species::DATA[:WHIMSICOTT]
      [:GRASSYGLIDE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WHIRLIPEDE
    if GameData::Species::DATA[:WHIRLIPEDE]
      sp = GameData::Species::DATA[:WHIRLIPEDE]
      [:SKITTERSMACK, :STEELROLLER].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WIGGLYTUFF
    if GameData::Species::DATA[:WIGGLYTUFF]
      sp = GameData::Species::DATA[:WIGGLYTUFF]
      [:ALLURINGVOICE, :BODYPRESS, :CHILLINGWATER, :EXPANDINGFORCE, :ICESPINNER, :MISTYEXPLOSION, :PSYCHICNOISE, :STEELROLLER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WIMPOD
    if GameData::Species::DATA[:WIMPOD]
      sp = GameData::Species::DATA[:WIMPOD]
      [:SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WISHIWASHI_SCHOOL
    if GameData::Species::DATA[:WISHIWASHI_SCHOOL]
      sp = GameData::Species::DATA[:WISHIWASHI_SCHOOL]
      [:FLIPTURN, :SCALESHOT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WOOPER
    if GameData::Species::DATA[:WOOPER]
      sp = GameData::Species::DATA[:WOOPER]
      [:CHILLINGWATER, :SNOWSCAPE, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WOOPER_PALDEA
    if GameData::Species::DATA[:WOOPER_PALDEA]
      sp = GameData::Species::DATA[:WOOPER_PALDEA]
      [:BODYPRESS, :CHILLINGWATER, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WORMADAM_TRASH
    if GameData::Species::DATA[:WORMADAM_TRASH]
      sp = GameData::Species::DATA[:WORMADAM_TRASH]
      [:STEELBEAM].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # WO_CHIEN
    if GameData::Species::DATA[:WO_CHIEN]
      sp = GameData::Species::DATA[:WO_CHIEN]
      [:BODYPRESS, :LASHOUT, :RUINATION, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # XATU
    if GameData::Species::DATA[:XATU]
      sp = GameData::Species::DATA[:XATU]
      [:DUALWINGBEAT, :EXPANDINGFORCE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # YAMASK
    if GameData::Species::DATA[:YAMASK]
      sp = GameData::Species::DATA[:YAMASK]
      [:POLTERGEIST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # YAMASK_GALAR
    if GameData::Species::DATA[:YAMASK_GALAR]
      sp = GameData::Species::DATA[:YAMASK_GALAR]
      [:POLTERGEIST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # YANMA
    if GameData::Species::DATA[:YANMA]
      sp = GameData::Species::DATA[:YANMA]
      [:POUNCE, :PSYCHICNOISE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # YANMEGA
    if GameData::Species::DATA[:YANMEGA]
      sp = GameData::Species::DATA[:YANMEGA]
      [:DUALWINGBEAT, :POUNCE, :PSYCHICNOISE, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZACIAN_CROWNED
    if GameData::Species::DATA[:ZACIAN_CROWNED]
      sp = GameData::Species::DATA[:ZACIAN_CROWNED]
      [:STEELBEAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZAMAZENTA_CROWNED
    if GameData::Species::DATA[:ZAMAZENTA_CROWNED]
      sp = GameData::Species::DATA[:ZAMAZENTA_CROWNED]
      [:BODYPRESS, :COACHING, :STEELBEAM, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZAPDOS
    if GameData::Species::DATA[:ZAPDOS]
      sp = GameData::Species::DATA[:ZAPDOS]
      [:DUALWINGBEAT, :RISINGVOLTAGE, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZAPDOS_GALAR
    if GameData::Species::DATA[:ZAPDOS_GALAR]
      sp = GameData::Species::DATA[:ZAPDOS_GALAR]
      [:COACHING, :DUALWINGBEAT, :TERABLAST, :THUNDEROUSKICK, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZARUDE_DADA
    if GameData::Species::DATA[:ZARUDE_DADA]
      sp = GameData::Species::DATA[:ZARUDE_DADA]
      [:GRASSYGLIDE, :JUNGLEHEALING, :LASHOUT, :TERABLAST, :TRAILBLAZE].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZEKROM
    if GameData::Species::DATA[:ZEKROM]
      sp = GameData::Species::DATA[:ZEKROM]
      [:BODYPRESS, :BREAKINGSWIPE, :DRAGONCHEER, :DUALWINGBEAT, :RISINGVOLTAGE, :SCALESHOT, :SUPERCELLSLAM, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZIGZAGOON_GALAR
    if GameData::Species::DATA[:ZIGZAGOON_GALAR]
      sp = GameData::Species::DATA[:ZIGZAGOON_GALAR]
      [:LASHOUT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZOROARK
    if GameData::Species::DATA[:ZOROARK]
      sp = GameData::Species::DATA[:ZOROARK]
      [:BURNINGJEALOUSY, :LASHOUT, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZOROARK_HISUI
    if GameData::Species::DATA[:ZOROARK_HISUI]
      sp = GameData::Species::DATA[:ZOROARK_HISUI]
      [:BITTERMALICE, :BURNINGJEALOUSY, :LASHOUT, :POLTERGEIST, :SKITTERSMACK, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZORUA
    if GameData::Species::DATA[:ZORUA]
      sp = GameData::Species::DATA[:ZORUA]
      [:BURNINGJEALOUSY, :LASHOUT, :SKITTERSMACK, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZORUA_HISUI
    if GameData::Species::DATA[:ZORUA_HISUI]
      sp = GameData::Species::DATA[:ZORUA_HISUI]
      [:BITTERMALICE, :BURNINGJEALOUSY, :COMEUPPANCE, :LASHOUT, :SKITTERSMACK, :SNOWSCAPE, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZUBAT
    if GameData::Species::DATA[:ZUBAT]
      sp = GameData::Species::DATA[:ZUBAT]
      [:DUALWINGBEAT].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZWEILOUS
    if GameData::Species::DATA[:ZWEILOUS]
      sp = GameData::Species::DATA[:ZWEILOUS]
      [:DRAGONCHEER, :LASHOUT, :TERABLAST].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZYGARDE_10
    if GameData::Species::DATA[:ZYGARDE_10]
      sp = GameData::Species::DATA[:ZYGARDE_10]
      [:BREAKINGSWIPE, :SCALESHOT, :SCORCHINGSANDS, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZYGARDE_10_POWER_CONSTRUCT
    if GameData::Species::DATA[:ZYGARDE_10_POWER_CONSTRUCT]
      sp = GameData::Species::DATA[:ZYGARDE_10_POWER_CONSTRUCT]
      [:BREAKINGSWIPE, :SCALESHOT, :SCORCHINGSANDS, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZYGARDE_50_POWER_CONSTRUCT
    if GameData::Species::DATA[:ZYGARDE_50_POWER_CONSTRUCT]
      sp = GameData::Species::DATA[:ZYGARDE_50_POWER_CONSTRUCT]
      [:BREAKINGSWIPE, :SCALESHOT, :SCORCHINGSANDS, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    # ZYGARDE_COMPLETE
    if GameData::Species::DATA[:ZYGARDE_COMPLETE]
      sp = GameData::Species::DATA[:ZYGARDE_COMPLETE]
      [:BREAKINGSWIPE, :SCALESHOT, :SCORCHINGSANDS, :SKITTERSMACK].each do |m|
        unless sp.tutor_moves.include?(m)
          sp.tutor_moves << m
          patched += 1
        end
      end
    else
      skipped += 1
    end

    echoln "[NPT] Patched #{patched} tutor move entries across base species (#{skipped} species not found)"
  end
end

# Run the patch after species data is loaded
NPT.patch_base_move_learnsets
