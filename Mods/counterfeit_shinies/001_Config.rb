module CounterfeitShinies
  VERSION = "1.1.0"
  DATA_VERSION = 1

  module Config
    FACTION_NAME = "Team Infinite Cannon"
    SUMMARY_TAG = "COUNTERFEIT"
    WORKSHOP_TITLE = "Counterfeit Workshop"
    LAUNDER_TITLE = "Clean-Slate Terminal"
    PICKER_TITLE = "Choose a Pokemon"
    DEFAULT_SOURCE = :workshop
    DEFAULT_SHINY_STYLE = 2
    SHINY_STYLE_NAMES = ["Vanilla", "Forced Shiny", "PIF Style", "Hybrid Shiny"]
    DEFAULT_CHANNELS = [0, 1, 2]
    DEFAULT_KRS = [0, 0, 0, 0, 0, 0, 0, 0, 0]
    PALETTE_FAVORITE_SLOTS = 6
    ALLOW_INDOOR_ENFORCERS = false
    ALLOW_DAYCARE_STORAGE = true
    STRIP_IF_LAST_OWNED = true
    STRIP_IMPORTED_TRADE_COUNTERFEITS = true
    LAUNDER_REWARD_NAME = "Clean-Slate Seal"
    LEVEL_CAP_REWARD_TOKENS = 1

    PC_MENU_PROMPT = "What do you want to do?"
    PC_MENU_ITEM_STORAGE = "Item Storage"
    PC_MENU_MAILBOX = "Mailbox"
    PC_MENU_WORKSHOP = "Counterfeit Workshop"
    PC_MENU_LAUNDER = "Scrub Counterfeit Tag"
    PC_MENU_BEDROOM_COLOR = "Change Bedroom Color"
    PC_MENU_TURN_OFF = "Turn Off"
    WORLD_OFFER_PROMPT = "Quietly offer a counterfeit finish?"
    WORLD_OFFER_IMMEDIATE_CALL_THRESHOLD = 5
    WORLD_OFFER_ANGER_THRESHOLD = 20
    WORLD_OFFER_DECLINE_THRESHOLD = 50
    WORLD_OFFER_HEAT_GAIN = 20
    WORLD_OFFER_STEP_GAIN = 52
    WORLD_OFFER_IMMEDIATE_HEAT_GAIN = 36
    WORLD_OFFER_IMMEDIATE_STEP_GAIN = 96
    WORLD_OFFER_EVENT_COOLDOWN_SECONDS = 4
    WORLD_OFFER_REPEAT_STREAK_REQUIRED = 3
    WORLD_OFFER_MULTI_BUY_CHANCE = 45
    WORLD_OFFER_MAX_MULTI_BUY = 3
    WORLD_OFFER_REPEATABLE_SCRIPT_PATTERNS = [
      /pbPhoneRegisterBattle\s*\(/i,
      /pbPhoneBattleCount\s*\(/i,
      /pbPhoneReadyToBattle\?\s*\(/i,
      /pbPhoneIncrement\s*\(/i,
      /\brematch\b/i
    ]
    WORLD_OFFER_DIALOGUE_LABELS = [
      "someone quiet",
      "someone lingering",
      "someone half-hidden",
      "someone with cold eyes"
    ]
    PREFERENCE_SPECIES_BONUS = 18
    PREFERENCE_FAMILY_BONUS = 10
    PREFERENCE_TYPE_BONUS = 5
    PREFERENCE_DIRECT_MENTION_BONUS = 22
    PREFERENCE_FUSION_THEME_BONUS = 6
    PREFERENCE_DOUBLE_COMPONENT_BONUS = 14
    PREFERENCE_DOUBLE_SPECIES_BONUS = 18
    PREFERENCE_MAX_SCORE = 90
    PREFERENCE_MULTI_BUY_SCORE_STEP = 3
    PREFERENCE_OFFER_MIN_BASE = 5
    PREFERENCE_OFFER_MIN_SCORE_STEP = 2
    PREFERENCE_OFFER_MIN_CAP = 72
    PREFERENCE_OFFER_MAX_BASE = 55
    PREFERENCE_OFFER_MAX_SCORE_STEP = 1
    PREFERENCE_OFFER_MAX_CAP = 100
    PREFERENCE_ARCHETYPES = {
      :medical => {
        :trainer_keywords  => [/nurse/i, /doctor/i, /medic/i, /healer/i, /care/i, /joy/i],
        :dialogue_keywords => [/heal/i, /recovery/i, /patient/i, /clinic/i, /center/i, /medicine/i, /healthy/i, /rest/i],
        :map_keywords      => [/center/i, /clinic/i, /hospital/i, /ward/i],
        :types             => [:NORMAL, :FAIRY, :PSYCHIC],
        :species           => [:HAPPINY, :CHANSEY, :BLISSEY, :AUDINO, :CLEFAIRY, :CLEFABLE, :TOGEPI, :TOGETIC, :TOGEKISS, :MUNNA, :MUSHARNA]
      },
      :shoreline => {
        :trainer_keywords  => [/swimmer/i, /sailor/i, /tuber/i, /diver/i, /surfer/i, /mariner/i],
        :dialogue_keywords => [/sea/i, /ocean/i, /wave/i, /tide/i, /harbor/i, /beach/i, /boat/i, /island/i],
        :map_keywords      => [/beach/i, /harbor/i, /port/i, /sea/i, /ocean/i, /cape/i, /island/i],
        :types             => [:WATER, :FLYING, :ICE],
        :species           => [:SHELLDER, :CLOYSTER, :TENTACOOL, :TENTACRUEL, :HORSEA, :SEADRA, :KINGDRA, :STARYU, :STARMIE, :KRABBY, :KINGLER, :LAPRAS, :SEEL, :DEWGONG, :SQUIRTLE, :WARTORTLE, :BLASTOISE]
      },
      :angler => {
        :trainer_keywords  => [/fisher/i, /angler/i],
        :dialogue_keywords => [/fish/i, /rod/i, /catch/i, /bite/i, /school of fish/i, /river/i, /lake/i],
        :map_keywords      => [/lake/i, /river/i, /pier/i, /dock/i, /pond/i],
        :types             => [:WATER, :DRAGON, :ELECTRIC],
        :species           => [:MAGIKARP, :GYARADOS, :POLIWAG, :POLIWHIRL, :POLIWRATH, :GOLDEEN, :SEAKING, :REMORAID, :OCTILLERY, :CHINCHOU, :LANTURN, :QWILFISH, :WHISCASH, :FEEBAS, :MILOTIC]
      },
      :woods_bug => {
        :trainer_keywords  => [/bug/i, /camper/i, /picnicker/i, /scout/i, /ranger/i],
        :dialogue_keywords => [/forest/i, /woods/i, /tree/i, /moss/i, /cocoon/i, /web/i, /bug/i, /leaf/i],
        :map_keywords      => [/forest/i, /woods/i, /park/i, /grove/i, /safari/i],
        :types             => [:BUG, :GRASS, :POISON],
        :species           => [:CATERPIE, :METAPOD, :BUTTERFREE, :WEEDLE, :KAKUNA, :BEEDRILL, :PARAS, :PARASECT, :VENONAT, :VENOMOTH, :SCYTHER, :PINSIR, :LEDYBA, :LEDIAN, :SPINARAK, :ARIADOS, :YANMA, :HERACROSS]
      },
      :bird_sky => {
        :trainer_keywords  => [/bird/i, /pilot/i, /flier/i, /traveler/i, /messenger/i],
        :dialogue_keywords => [/sky/i, /wind/i, /wing/i, /feather/i, /flight/i, /bird/i, /cloud/i],
        :map_keywords      => [/gate/i, /airport/i, /peak/i, /tower/i, /bridge/i],
        :types             => [:FLYING, :NORMAL, :DRAGON],
        :species           => [:PIDGEY, :PIDGEOTTO, :PIDGEOT, :SPEAROW, :FEAROW, :DODUO, :DODRIO, :FARFETCHD, :HOOTHOOT, :NOCTOWL, :NATU, :XATU, :MURKROW, :HONCHKROW, :SKARMORY, :ZUBAT, :GOLBAT, :CROBAT]
      },
      :stone_climber => {
        :trainer_keywords  => [/hiker/i, /miner/i, /ruin/i, /mountain/i],
        :dialogue_keywords => [/rock/i, /stone/i, /cave/i, /mountain/i, /mine/i, /tunnel/i, /boulder/i, /fossil/i],
        :map_keywords      => [/cave/i, /mt\.?/i, /mount/i, /tunnel/i, /mine/i, /rock/i],
        :types             => [:ROCK, :GROUND, :STEEL],
        :species           => [:GEODUDE, :GRAVELER, :GOLEM, :ONIX, :STEELIX, :RHYHORN, :RHYDON, :RYPERIOR, :OMANYTE, :OMASTAR, :KABUTO, :KABUTOPS, :AERODACTYL, :SANDSHREW, :SANDSLASH, :NOSEPASS, :PROBOPASS]
      },
      :desert_nomad => {
        :trainer_keywords  => [/wanderer/i, /nomad/i, /ruin maniac/i, /archaeologist/i],
        :dialogue_keywords => [/sand/i, /dune/i, /desert/i, /sun/i, /ruin/i, /bone/i],
        :map_keywords      => [/desert/i, /ruin/i, /badlands/i, /canyon/i],
        :types             => [:GROUND, :FIRE, :DRAGON],
        :species           => [:CUBONE, :MAROWAK, :TRAPINCH, :VIBRAVA, :FLYGON, :CACNEA, :CACTURNE, :SANDILE, :KROKOROK, :KROOKODILE, :NUMEL, :CAMERUPT, :PHANPY, :DONPHAN]
      },
      :electric_tech => {
        :trainer_keywords  => [/scientist/i, /engineer/i, /guitarist/i, /gamer/i, /hacker/i, /technician/i],
        :dialogue_keywords => [/machine/i, /engine/i, /gear/i, /wire/i, /circuit/i, /power/i, /magnet/i, /battery/i, /lab/i, /data/i],
        :map_keywords      => [/power plant/i, /plant/i, /lab/i, /silph/i, /generator/i, /tower/i],
        :types             => [:ELECTRIC, :STEEL, :PSYCHIC],
        :species           => [:PIKACHU, :RAICHU, :MAGNEMITE, :MAGNETON, :MAGNEZONE, :VOLTORB, :ELECTRODE, :PORYGON, :PORYGON2, :PORYGONZ, :ROTOM, :ELEKID, :ELECTABUZZ, :ELECTIVIRE, :MAREEP, :FLAAFFY, :AMPHAROS]
      },
      :mind_mystic => {
        :trainer_keywords  => [/psychic/i, /seer/i, /sage/i, /mystic/i],
        :dialogue_keywords => [/mind/i, /future/i, /vision/i, /dream/i, /telepathy/i, /fortune/i, /thought/i],
        :map_keywords      => [/tower/i, /shrine/i, /dojo/i, /temple/i],
        :types             => [:PSYCHIC, :FAIRY, :GHOST],
        :species           => [:ABRA, :KADABRA, :ALAKAZAM, :DROWZEE, :HYPNO, :SLOWPOKE, :SLOWBRO, :ESPEON, :RALTS, :KIRLIA, :GARDEVOIR, :MUNNA, :MUSHARNA, :NATU, :XATU]
      },
      :ghost_night => {
        :trainer_keywords  => [/medium/i, /channeler/i, /hex/i, /grave/i],
        :dialogue_keywords => [/ghost/i, /grave/i, /haunted/i, /curse/i, /spirit/i, /shadow/i, /night/i, /moon/i],
        :map_keywords      => [/tower/i, /grave/i, /cemetery/i, /haunt/i, /lavender/i, /manor/i],
        :types             => [:GHOST, :DARK, :POISON],
        :species           => [:GASTLY, :HAUNTER, :GENGAR, :MISDREAVUS, :MISMAGIUS, :SHUPPET, :BANETTE, :DUSKULL, :DUSCLOPS, :DUSKNOIR, :MURKROW, :HONCHKROW, :ABSOL, :ZORUA, :ZOROARK]
      },
      :fighter => {
        :trainer_keywords  => [/blackbelt/i, /karate/i, /fighter/i, /martial/i, /athlete/i, /champ/i],
        :dialogue_keywords => [/train/i, /muscle/i, /fist/i, /kick/i, /strength/i, /discipline/i, /dojo/i],
        :map_keywords      => [/dojo/i, /gym/i, /arena/i],
        :types             => [:FIGHTING, :STEEL, :ROCK],
        :species           => [:MANKEY, :PRIMEAPE, :MACHOP, :MACHOKE, :MACHAMP, :HITMONLEE, :HITMONCHAN, :HITMONTOP, :RIOLU, :LUCARIO, :MEDITITE, :MEDICHAM, :HERACROSS, :TYROGUE]
      },
      :poison_chem => {
        :trainer_keywords  => [/scientist/i, /burglar/i, /biker/i, /punk/i, /chemist/i],
        :dialogue_keywords => [/toxic/i, /poison/i, /acid/i, /sludge/i, /gas/i, /smog/i, /chemical/i, /sewer/i],
        :map_keywords      => [/sewer/i, /plant/i, /lab/i, /factory/i],
        :types             => [:POISON, :DARK, :STEEL],
        :species           => [:EKANS, :ARBOK, :NIDORANmA, :NIDORINO, :NIDOKING, :NIDORANfE, :NIDORINA, :NIDOQUEEN, :GRIMER, :MUK, :KOFFING, :WEEZING, :CROAGUNK, :TOXICROAK, :SKORUPI, :DRAPION, :STUNKY, :SKUNTANK]
      },
      :beauty_grace => {
        :trainer_keywords  => [/beauty/i, /lady/i, /idol/i, /model/i, /socialite/i],
        :dialogue_keywords => [/pretty/i, /beautiful/i, /lovely/i, /elegant/i, /fashion/i, /style/i, /perfume/i, /grace/i],
        :map_keywords      => [/salon/i, /boutique/i, /garden/i, /resort/i],
        :types             => [:FAIRY, :PSYCHIC, :FIRE, :GRASS],
        :species           => [:VULPIX, :NINETALES, :EEVEE, :ESPEON, :GLAMEOW, :PURUGLY, :ROSELIA, :ROSERADE, :RALTS, :KIRLIA, :GARDEVOIR, :FEEBAS, :MILOTIC, :CLEFAIRY, :CLEFABLE]
      },
      :performer => {
        :trainer_keywords  => [/dancer/i, /musician/i, /performer/i, /idol/i, /artist/i],
        :dialogue_keywords => [/song/i, /sing/i, /dance/i, /rhythm/i, /stage/i, /show/i, /melody/i, /beat/i],
        :map_keywords      => [/theater/i, /hall/i, /stage/i, /studio/i],
        :types             => [:NORMAL, :FAIRY, :FLYING, :PSYCHIC],
        :species           => [:JIGGLYPUFF, :WIGGLYTUFF, :CHATOT, :KRICKETOT, :KRICKETUNE, :MELOETTA_A, :MELOETTA_P, :MIMEJR, :MRMIME, :TOGEPI, :TOGETIC, :TOGEKISS]
      },
      :home_cute => {
        :trainer_keywords  => [/lass/i, /youngster/i, /school/i, /breeder/i, /family/i, /child/i],
        :dialogue_keywords => [/cute/i, /sweet/i, /home/i, /cozy/i, /friend/i, /pet/i, /soft/i],
        :map_keywords      => [/house/i, /town/i, /village/i, /farm/i, /ranch/i],
        :types             => [:NORMAL, :FAIRY, :GRASS],
        :species           => [:EEVEE, :SNORLAX, :MILTANK, :SENTRET, :FURRET, :BUNEARY, :LOPUNNY, :MARILL, :AZUMARILL, :CLEFAIRY, :TOGEPI, :ODDISH, :BELLOSSOM]
      },
      :fire_blood => {
        :trainer_keywords  => [/firebreather/i, /chef/i, /cook/i, /roughneck/i, /ace/i],
        :dialogue_keywords => [/hot/i, /heat/i, /flame/i, /burn/i, /forge/i, /stove/i, /spice/i, /smoke/i],
        :map_keywords      => [/volcano/i, /mansion/i, /forge/i, /cinnabar/i, /boiler/i],
        :types             => [:FIRE, :DARK, :FIGHTING],
        :species           => [:CHARMANDER, :CHARMELEON, :CHARIZARD, :VULPIX, :NINETALES, :GROWLITHE, :ARCANINE, :PONYTA, :RAPIDASH, :MAGBY, :MAGMAR, :MAGMORTAR, :HOUNDOUR, :HOUNDOOM, :SLUGMA, :MAGCARGO]
      },
      :ice_trail => {
        :trainer_keywords  => [/skier/i, /boarder/i, /snow/i, /winter/i],
        :dialogue_keywords => [/ice/i, /snow/i, /cold/i, /freeze/i, /winter/i, /frost/i, /blizzard/i],
        :map_keywords      => [/ice/i, /snow/i, /glacier/i, /frost/i, /seafoam/i],
        :types             => [:ICE, :WATER, :FLYING],
        :species           => [:SNEASEL, :WEAVILE, :DELIBIRD, :SWINUB, :PILOSWINE, :MAMOSWINE, :SNORUNT, :GLALIE, :SPHEAL, :SEALEO, :WALREIN, :LAPRAS, :ARTICUNO, :JYNX]
      },
      :dragon_rare => {
        :trainer_keywords  => [/dragon/i, /collector/i, /veteran/i, /ace/i, /cooltrainer/i, /gentleman/i],
        :dialogue_keywords => [/rare/i, /legend/i, /perfect/i, /prized/i, /collection/i, /draconic/i, /ancient/i],
        :map_keywords      => [/cave/i, /den/i, /tower/i, /league/i, /manor/i],
        :types             => [:DRAGON, :STEEL, :ICE, :FAIRY],
        :species           => [:DRATINI, :DRAGONAIR, :DRAGONITE, :HORSEA, :SEADRA, :KINGDRA, :BAGON, :SHELGON, :SALAMENCE, :GIBLE, :GABITE, :GARCHOMP, :AXEW, :FRAXURE, :HAXORUS, :LARVITAR, :PUPITAR, :TYRANITAR]
      },
      :coin_dark => {
        :trainer_keywords  => [/burglar/i, /gambler/i, /gentleman/i, /lady/i, /thief/i, /biker/i, /cueball/i],
        :dialogue_keywords => [/money/i, /coin/i, /rare/i, /profit/i, /debt/i, /pay/i, /price/i, /deal/i, /lucky/i],
        :map_keywords      => [/corner/i, /casino/i, /market/i, /alley/i, /warehouse/i],
        :types             => [:DARK, :NORMAL, :STEEL],
        :species           => [:MEOWTH, :PERSIAN, :MURKROW, :HONCHKROW, :SNEASEL, :WEAVILE, :ABSOL, :ZORUA, :ZOROARK, :PAWNIARD, :BISHARP, :RATTATA, :RATICATE]
      },
      :garden => {
        :trainer_keywords  => [/gardener/i, /florist/i, /breeder/i, /picnicker/i],
        :dialogue_keywords => [/flower/i, /garden/i, /petal/i, /seed/i, /herb/i, /bloom/i, /fragrance/i, /vine/i],
        :map_keywords      => [/garden/i, /park/i, /greenhouse/i, /route/i],
        :types             => [:GRASS, :FAIRY, :POISON],
        :species           => [:BULBASAUR, :IVYSAUR, :VENUSAUR, :ODDISH, :GLOOM, :VILEPLUME, :BELLOSSOM, :BELLSPROUT, :WEEPINBELL, :VICTREEBEL, :ROSELIA, :ROSERADE, :TANGELA, :TANGROWTH, :HOPPIP, :SKIPLOOM, :JUMPLUFF]
      }
    }

    HEAT_PER_STEP = 2
    HEAT_PER_EXTRA_COUNTERFEIT = 1
    HEAT_DECAY_WHEN_CLEAN = 3
    WIN_HEAT_REDUCTION = 16
    LOSS_HEAT_RESET = 0
    HEAT_CAP = 120
    BASE_STEP_THRESHOLD = 120
    BADGE_STEP_REDUCTION = 5
    EXTRA_COUNTERFEIT_STEP_REDUCTION = 18
    VALUE_STEP_REDUCTION_DIVISOR = 2500
    MIN_STEP_THRESHOLD = 32
    BASE_ENCOUNTER_CHANCE = 20
    HEAT_ENCOUNTER_CHANCE_STEP = 4
    BADGE_ENCOUNTER_CHANCE_STEP = 1
    VALUE_ENCOUNTER_CHANCE_DIVISOR = 5000
    MAX_ENCOUNTER_CHANCE = 78

    PRESTIGE_WINS_GAIN = 1
    BATTLE_USE_GAIN = 1
    NOTORIETY_GAIN_WIN = 9
    NOTORIETY_GAIN_USE = 2
    SALE_BONUS_PER_WIN = 250
    FUSION_MERGE_BONUS = 350

    VALUE_BASE = 1400
    VALUE_RARITY_MULT = 14
    VALUE_APPEAL_MULT = 24
    VALUE_AGE_MULT = 10
    VALUE_BATTLE_USE_MULT = 100
    VALUE_ENFORCER_WIN_MULT = 500
    VALUE_NOTORIETY_MULT = 45
    VALUE_ACTIVE_BONUS = 250
    VALUE_FUSION_BONUS = 1600
    VALUE_STYLE_BONUS = 80
    AGE_STEP_DIVISOR = 240
    MAX_AGE_SCORE = 70
    MIN_MARKET_VALUE = 600

    ENFORCER_START_LEVEL = 12
    ENFORCER_LEVEL_STEP = 4
    ENFORCER_TEAM_SIZE_STAGE_STEP = 4
    ENFORCER_MAX_TEAM_SIZE = 4
    ENFORCER_CHASE_ENABLED = true
    ENFORCER_CHASE_DURATION_SECONDS = 30
    ENFORCER_CHASE_MIN_DISTANCE = 5
    ENFORCER_CHASE_MAX_DISTANCE = 8
    ENFORCER_CHASE_SPEED = 3.8
    ENFORCER_CHASE_CLOSE_DISTANCE = 3
    ENFORCER_CHASE_DUST_INTERVAL = 12
    ENFORCER_CHASE_ALERT_INTERVAL = 90
    ENFORCER_CHASE_CHARSETS = ["BWWorker"]

    CHANNEL_MIN = 0
    CHANNEL_SOFT_CAP = 11
    CHANNEL_HARD_CAP = 25
    HUE_MIN = -180
    HUE_MAX = 180
    BOOST_MIN = -200
    BOOST_MAX = 200

    ENFORCER_TRAINER_TYPES = [
      :SCIENTIST, :BURGLAR, :BLACKBELT, :ENGINEER, :GENTLEMAN,
      :POKEMANIAC, :JUGGLER, :ACE_TRAINER_M, :ACE_TRAINER_F, :REPORTER,
      :COOLTRAINER_M, :COOLTRAINER_F, :CUEBALL, :BEAUTY
    ]

    ENFORCER_NAMES = [
      "Nix", "Rook", "Mara", "Slate", "Cinder", "Vale",
      "Kite", "Sable", "Wren", "Iris", "Crow", "Dahl"
    ]

    ENFORCER_ROLES = [
      "shine inspector",
      "collection broker",
      "counterfeit hunter",
      "Infinite Cannon scout",
      "black-market auditor"
    ]

    MAJOR_TRAINER_TEXT_PATTERNS = [
      /leader/i,
      /gym/i,
      /elite/i,
      /champ/i,
      /rival/i,
      /prof/i,
      /rocket/i,
      /admin/i,
      /executive/i,
      /boss/i,
      /commander/i,
      /captain/i,
      /warden/i,
      /sage/i,
      /elder/i,
      /scientist.*silph/i,
      /officer/i,
      /police/i
    ]

    ENFORCER_POOL = [
      :EKANS, :ARBOK, :MEOWTH, :PERSIAN, :RATTATA, :RATICATE, :KOFFING,
      :WEEZING, :MURKROW, :HONCHKROW, :HOUNDOUR, :HOUNDOOM, :MAGNEMITE,
      :MAGNETON, :MAGNEZONE, :SNEASEL, :WEAVILE, :STUNKY, :SKUNTANK,
      :ZORUA, :ZOROARK, :TRUBBISH, :GARBODOR, :PAWNIARD, :BISHARP,
      :CROAGUNK, :TOXICROAK, :SANDILE, :KROKOROK, :KROOKODILE, :SCRAGGY,
      :SCRAFTY, :ABSOL, :BANETTE, :ROTOM, :WATCHOG, :GOLBAT, :CROBAT,
      :PORYGON, :PORYGON2, :PORYGONZ
    ]

    NOTORIETY_TIERS = [
      { :name => "Quiet",     :minimum => 0,  :bonus => 0 },
      { :name => "Noticed",   :minimum => 8,  :bonus => 300 },
      { :name => "Wanted",    :minimum => 18, :bonus => 850 },
      { :name => "Notorious", :minimum => 32, :bonus => 1700 }
    ]

    BUYER_PROFILES = {
      :street_fence => {
        :title            => "Street Fence",
        :name             => "street fence",
        :multiplier       => 0.95,
        :minimum_value    => 0,
        :minimum_appeal   => 0,
        :session_bonus    => 0.00,
        :welcome          => "Keep it low. Keep it quick. I move forged shine before breakfast.",
        :empty_text       => "No forged stock, no deal. Come back with a counterfeit finish.",
        :reject_text      => "This one is too sloppy even for me.",
        :confirm_template => "The street fence offers ${1} for {2}. Sell it?"
      },
      :volume_runner => {
        :title            => "Volume Runner",
        :name             => "volume runner",
        :multiplier       => 0.88,
        :minimum_value    => 0,
        :minimum_appeal   => 0,
        :session_bonus    => 0.04,
        :welcome          => "I buy in piles, not in poetry. Keep feeding me stock and the rate climbs.",
        :empty_text       => "You do not have any counterfeit stock ready to move.",
        :reject_text      => "If it glows, I buy it. Bring me something forged.",
        :confirm_template => "The volume runner stacks ${1} on the table for {2}. Move it?"
      },
      :prestige_collector => {
        :title            => "Prestige Collector",
        :name             => "prestige collector",
        :multiplier       => 1.20,
        :minimum_value    => 4500,
        :minimum_appeal   => 35,
        :session_bonus    => 0.02,
        :welcome          => "If the underworld is already whispering about a finish, I pay for the story too.",
        :empty_text       => "Nothing in your stock is refined enough for a prestige sale yet.",
        :reject_text      => "I collect legends, not rushed palettes.",
        :confirm_template => "The prestige collector offers ${1} for {2}. Accept the private sale?"
      }
    }

    module_function

    def channel_cap
      return CHANNEL_HARD_CAP if !$PokemonSystem || !$PokemonSystem.respond_to?(:shinyadvanced)
      return ($PokemonSystem.shinyadvanced == 2) ? CHANNEL_HARD_CAP : CHANNEL_SOFT_CAP
    end

    def buyer_profile(profile_id)
      return BUYER_PROFILES[profile_id] || BUYER_PROFILES[:street_fence]
    end
  end
end
