# 009_NPTAnimations.rb
# EBDX animation aliases for all NPT moves registered in 004_Moves.rb.
#
# Uses EliteBattle.copyMoveAnimation(:SOURCE, :TARGET, ...) which stores a
# symbol redirect — no sprite or Proc code needed.  Loads after 660_EBDX so
# all source keys are already registered.
#
# If a source key has no EBDX animation the call is silently ignored and the
# game falls back to the vanilla RPGMaker Animations database.  Safe to add or
# remove lines freely.

if defined?(EliteBattle)

# ── Dark ──────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:NIGHTSLASH,
  :CEASELESSEDGE, :KOWTOWCLEAVE, :BITTERBLADE, :WICKEDBLOW, :WICKEDTORQUE,
  :MIGHTYCLEAVE)
EliteBattle.copyMoveAnimation(:FEINTATTACK, :FALSESURRENDER, :LASHOUT)
EliteBattle.copyMoveAnimation(:SHADOWBALL,
  :LASTRESPECTS, :ASTRALBARRAGE, :BITTERMALICE, :EERIESPELL, :POLTERGEIST)
EliteBattle.copyMoveAnimation(:SHADOWCLAW,  :DIRECLAW)
EliteBattle.copyMoveAnimation(:SHADOWPUNCH, :RAGEFIST)
EliteBattle.copyMoveAnimation(:DARKPULSE,   :FIERYWRATH, :BADDYBAD, :INFERNALPARADE)
EliteBattle.copyMoveAnimation(:CRUNCH,      :FISHIOUSREND, :JAWLOCK)
EliteBattle.copyMoveAnimation(:NATURESMADNESS, :RUINATION)

# ── Fighting ──────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:CLOSECOMBAT,  :COLLISIONCOURSE)
EliteBattle.copyMoveAnimation(:MACHPUNCH,    :COMBATTORQUE, :JETPUNCH)
EliteBattle.copyMoveAnimation(:HIGHJUMPKICK, :AXEKICK, :THUNDEROUSKICK)
EliteBattle.copyMoveAnimation(:HEADSMASH,    :HEADLONGRUSH, :METEORASSAULT)
EliteBattle.copyMoveAnimation(:BULLETPUNCH,  :UPPERHAND)
EliteBattle.copyMoveAnimation(:COUNTER,      :COMEUPPANCE)

# ── Electric ──────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:THUNDERBOLT,
  :ELECTRODRIFT, :THUNDERCLAP, :DOUBLESHOCK, :BOLTBEAK, :BUZZYBUZZ,
  :ZIPPYZAP, :OVERDRIVE, :PIKAPAPOW, :RISINGVOLTAGE, :SUPERCELLSLAM,
  :WILDBOLTSTORM, :THUNDERCAGE)
EliteBattle.copyMoveAnimation(:DISCHARGE, :ELECTROSHOT)

# ── Dragon ────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:DRAGONPULSE, :FICKLEBEAM, :DRAGONENERGY, :DYNAMAXCANNON)
EliteBattle.copyMoveAnimation(:OUTRAGE,     :GLAIVERUSH, :RAGINGFURY)
EliteBattle.copyMoveAnimation(:DRAGONCLAW,  :BREAKINGSWIPE, :DRAGONDARTS, :ORDERUP, :SCALESHOT)
EliteBattle.copyMoveAnimation(:DRACOMETEOR, :ETERNABEAM, :METEORBEAM)
EliteBattle.copyMoveAnimation(:DRAGONDANCE, :CLANGOROUSSOUL, :DRAGONCHEER)

# ── Psychic ───────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:PSYCHOCUT,   :PSYBLADE)
EliteBattle.copyMoveAnimation(:PSYBEAM,     :PSYCHICNOISE, :TWINBEAM)
EliteBattle.copyMoveAnimation(:PSYCHIC,     :EXPANDINGFORCE, :MYSTICALPOWER)
EliteBattle.copyMoveAnimation(:AIRSLASH,    :ESPERWING)
EliteBattle.copyMoveAnimation(:PSYSTRIKE,   :PSYSHIELDBASH)
EliteBattle.copyMoveAnimation(:CALMMIND,    :TAKEHEART)
EliteBattle.copyMoveAnimation(:LIGHTSCREEN, :GLITZYGLOW)

# ── Fairy ─────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:DISARMINGVOICE, :ALLURINGVOICE)
EliteBattle.copyMoveAnimation(:MOONBLAST,
  :MAGICALTORQUE, :MISTYEXPLOSION, :VEEVEEVOLLEY, :SPARKLYSWIRL,
  :LUMINACRASH, :BLOODMOON, :SPIRITBREAK)
EliteBattle.copyMoveAnimation(:MYSTICALFIRE, :STRANGESTEAM)

# ── Fire ──────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:FLAMETHROWER,
  :ARMORCANNON, :BURNINGJEALOUSY, :SPICYEXTRACT, :TEMPERFLARE, :TORCHSONG)
EliteBattle.copyMoveAnimation(:FIREBLAST,  :PYROBALL)
EliteBattle.copyMoveAnimation(:FIRESPIN,   :BLAZINGTORQUE)
EliteBattle.copyMoveAnimation(:FLAREBLITZ, :SIZZLYSLIDE)

# ── Water ─────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:HYDROPUMP,  :HYDROSTEAM)
EliteBattle.copyMoveAnimation(:AQUAJET,    :AQUASTEP, :FLIPTURN)
EliteBattle.copyMoveAnimation(:RAZORSHELL, :AQUACUTTER)
EliteBattle.copyMoveAnimation(:ABSORB,     :MATCHAGOTCHA, :BOUNCYBUBBLE)
EliteBattle.copyMoveAnimation(:SCALD,      :SPLISHYSPLASH, :SHELLSIDEARM)
EliteBattle.copyMoveAnimation(:WATERGUN,   :CHILLINGWATER)
EliteBattle.copyMoveAnimation(:AQUATAIL,   :WAVECRASH, :SURGINGSTRIKES)
EliteBattle.copyMoveAnimation(:CLAMP,      :SNAPTRAP)
EliteBattle.copyMoveAnimation(:DIVE,       :TRIPLEDIVE)
EliteBattle.copyMoveAnimation(:AURASPHERE, :SNIPESHOT, :AURAWHEEL)

# ── Ice ───────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:ICEBEAM,     :FREEZINGGLARE, :FREEZYFROST, :CHILLYRECEPTION)
EliteBattle.copyMoveAnimation(:ICICLECRASH, :GLACIALLANCE, :MOUNTAINGALE, :TRIPLEAXEL)
EliteBattle.copyMoveAnimation(:ICEPUNCH,    :ICESPINNER)
EliteBattle.copyMoveAnimation(:HAIL,        :SNOWSCAPE)

# ── Grass ─────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:VINEWHIP,      :GRASSYGLIDE, :BRANCHPOKE, :TRAILBLAZE)
EliteBattle.copyMoveAnimation(:WOODHAMMER,    :IVYCUDGEL)
EliteBattle.copyMoveAnimation(:PETALBLIZZARD, :FLOWERTRICK)
EliteBattle.copyMoveAnimation(:SEEDBOMB,      :GRAVAPPLE)
EliteBattle.copyMoveAnimation(:LEECHSEED,     :SYRUPBOMB, :SAPPYSEED)
EliteBattle.copyMoveAnimation(:ENERGYBALL,    :CHLOROBLAST, :TERRAINPULSE)

# ── Steel ─────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:IRONHEAD,
  :HARDPRESS, :BEHEMOTHBASH, :BEHEMOTHBLADE, :STEELROLLER)
EliteBattle.copyMoveAnimation(:HAMMERARM,   :GIGATONHAMMER)
EliteBattle.copyMoveAnimation(:SMARTSTRIKE, :STONEAXE)
EliteBattle.copyMoveAnimation(:FLASHCANNON, :STEELBEAM, :TACHYONCUTTER)
EliteBattle.copyMoveAnimation(:GYROBALL,    :SPINOUT)
EliteBattle.copyMoveAnimation(:DRILLRUN,    :HYPERDRILL)

# ── Rock ──────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:ROCKSLIDE, :SALTCURE)

# ── Poison ────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:POISONJAB, :BARBBARRAGE, :MALIGNANTCHAIN, :NOXIOUSTORQUE)
EliteBattle.copyMoveAnimation(:ACIDSPRAY, :CORROSIVEGAS, :TARSHOT)
EliteBattle.copyMoveAnimation(:ACID,      :APPLEACID)
EliteBattle.copyMoveAnimation(:RAPIDSPIN, :MORTALSPIN, :TIDYUP)

# ── Bug ───────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:LUNGE,     :POUNCE)
EliteBattle.copyMoveAnimation(:BUGBITE,   :SKITTERSMACK)
EliteBattle.copyMoveAnimation(:STICKYWEB, :SILKTRAP)
EliteBattle.copyMoveAnimation(:PINMISSILE, :TRIPLEARROWS)

# ── Ground ────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:EARTHQUAKE, :DRUMBEATING)
EliteBattle.copyMoveAnimation(:MUDSHOT,    :SCORCHINGSANDS)

# ── Flying ────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:HURRICANE,
  :BLEAKWINDSTORM, :SPRINGTIDESTORM, :SANDSEARSTORM)
EliteBattle.copyMoveAnimation(:WINGATTACK, :DUALWINGBEAT)
EliteBattle.copyMoveAnimation(:BRAVEBIRD,  :FLOATYFALL)

# ── Ghost ─────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:WRAP, :OCTOLOCK)

# ── Normal ────────────────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:SWIFT,    :TERABLAST, :TERASTARSTORM)
EliteBattle.copyMoveAnimation(:TAILSLAP, :POPULATIONBOMB)
EliteBattle.copyMoveAnimation(:BODYSLAM, :RAGINGBULL, :BODYPRESS)
EliteBattle.copyMoveAnimation(:BATONPASS, :COURTCHANGE, :SHEDTAIL)
EliteBattle.copyMoveAnimation(:PAYDAY,   :MAKEITRAIN)
EliteBattle.copyMoveAnimation(:HYPERBEAM, :LIGHTTHATBURNSTHESKY)

# ── Status / support ──────────────────────────────────────────────────────────
EliteBattle.copyMoveAnimation(:AROMATHERAPY, :JUNGLEHEALING, :LUNARBLESSING)
EliteBattle.copyMoveAnimation(:PROTECT,   :OBSTRUCT, :BURNINGBULWARK)
EliteBattle.copyMoveAnimation(:IRONDEFENSE, :SHELTER)
EliteBattle.copyMoveAnimation(:POWDER,    :MAGICPOWDER)
EliteBattle.copyMoveAnimation(:SWORDSDANCE,
  :FILLETAWAY, :DECORATE, :NORETREAT, :VICTORYDANCE, :STUFFCHEEKS)
EliteBattle.copyMoveAnimation(:HELPINGHAND, :COACHING)
EliteBattle.copyMoveAnimation(:SKILLSWAP,  :DOODLE)
EliteBattle.copyMoveAnimation(:HEALINGWISH, :REVIVALBLESSING)
EliteBattle.copyMoveAnimation(:HEALPULSE,  :LIFEDEW)
EliteBattle.copyMoveAnimation(:GUARDSWAP,  :POWERSHIFT)
EliteBattle.copyMoveAnimation(:REST,       :TEATIME)

end # defined?(EliteBattle)
