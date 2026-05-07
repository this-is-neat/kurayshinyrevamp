module PCBattleBetting
  BET_AMOUNTS = [500, 1000, 2500, 5000].freeze
  MIN_LEVEL = 35
  MAX_LEVEL = 65
  THEMED_MIN_LEVEL = 78
  THEMED_MAX_LEVEL = 90
  FORMAT_PAYOUT_MULTIPLIERS = {
    :single => 2,
    :triple => 3,
    :themed_duel => 4
  }.freeze
  BATTLE_FORMATS = {
    :single => 1,
    :triple => 3,
    :themed_duel => 6
  }.freeze
  THEME_TYPES = [
    :FIRE, :WATER, :GRASS, :ELECTRIC, :ICE, :FIGHTING,
    :POISON, :GROUND, :FLYING, :PSYCHIC, :BUG, :ROCK,
    :GHOST, :DRAGON, :DARK, :STEEL, :FAIRY
  ].freeze
  TRAINER_STYLE_WORDS = [
    _INTL("Ace"), _INTL("Veteran"), _INTL("Tactician"), _INTL("Prodigy"),
    _INTL("Captain"), _INTL("Master"), _INTL("Champion")
  ].freeze
  TRAINER_NAME_PARTS = [
    _INTL("Nova"), _INTL("Rook"), _INTL("Skye"), _INTL("Vex"), _INTL("Blair"),
    _INTL("Onyx"), _INTL("Sage"), _INTL("Rune"), _INTL("Kai"), _INTL("Mira")
  ].freeze
  ELITE_INTRO_PHRASES = [
    _INTL("I climbed every final bracket in this region. I do not miss in endgame fights."),
    _INTL("This is champion-level pressure. If your side blinks, the match is over."),
    _INTL("You are watching perfected battle craft. Count the turns before checkmate."),
    _INTL("I forged this roster in the postgame gauntlet. We only play to close.")
  ].freeze
  THEME_INTRO_PHRASES = {
    :FIRE => [
      _INTL("Heat rises, pressure spikes, and my Fire core burns through final-round defenses."),
      _INTL("I trained in the endgame furnaces. One opening and this arena becomes ash.")
    ],
    :WATER => [
      _INTL("Water adapts to everything. In long sets, my flow always drowns the opposition."),
      _INTL("Champions break when momentum turns. My tide never stops once it starts.")
    ],
    :GRASS => [
      _INTL("My Grass rotation roots the field, then blooms into a clean endgame sweep."),
      _INTL("I win the long game. Every turn feeds the forest until your options disappear.")
    ],
    :ELECTRIC => [
      _INTL("Voltage, tempo, execution. My Electric squad ends battles before fear can set in."),
      _INTL("I strike first and keep initiative. Blink once and the board is gone.")
    ],
    :ICE => [
      _INTL("I freeze aggressive lines and shatter overextensions. Cold discipline wins titles."),
      _INTL("This is high-tier Ice control. Your momentum ends the moment winter lands.")
    ],
    :FIGHTING => [
      _INTL("No gimmicks. Pure Fighting fundamentals, hardened in elite postgame circuits."),
      _INTL("I break teams with pressure and reads. One wrong pivot and it is finished.")
    ],
    :POISON => [
      _INTL("I control pace with Poison precision. Every turn taxes your win condition."),
      _INTL("This is attrition at champion speed. You will lose options before you lose HP.")
    ],
    :GROUND => [
      _INTL("My Ground core anchors the field and buries reckless lines on contact."),
      _INTL("I dictate terrain, tempo, and trades. Endgame runs on my terms.")
    ],
    :FLYING => [
      _INTL("I own spacing and angles. My Flying unit punishes every grounded mistake."),
      _INTL("Altitude is advantage. We strike from above and never surrender initiative.")
    ],
    :PSYCHIC => [
      _INTL("I read two turns ahead. Psychic discipline turns prediction into certainty."),
      _INTL("This is refined mindgame pressure. By the reveal, the route is already solved.")
    ],
    :BUG => [
      _INTL("Swarm strategy scales with every turn. My Bug lineup overwhelms elite defenses."),
      _INTL("I open with pressure and close with numbers. You cannot cover every angle.")
    ],
    :ROCK => [
      _INTL("Rock structure wins championships. I trade once and your map collapses."),
      _INTL("I built this squad to outlast and out-hit every so-called meta answer.")
    ],
    :GHOST => [
      _INTL("My Ghost line slips past checks and punishes fear. Endgame is our hunting ground."),
      _INTL("I weaponize uncertainty. By the time you read the pattern, the match is gone.")
    ],
    :DRAGON => [
      _INTL("This Dragon core is tuned for peak play. Once it sets up, no wall survives."),
      _INTL("I trained for title brackets only. Dragons close sets with ruthless precision.")
    ],
    :DARK => [
      _INTL("I pressure mistakes and punish habits. My Dark unit thrives in high-stakes chaos."),
      _INTL("No safe lines, no free turns. Dark tempo ends even champion gameplans.")
    ],
    :STEEL => [
      _INTL("Steel discipline, zero panic. My structure absorbs pressure and crushes back."),
      _INTL("I forged this lineup for finals. It does not bend, and it does not break.")
    ],
    :FAIRY => [
      _INTL("Do not underestimate precision. My Fairy core turns elegant lines into hard checkmate."),
      _INTL("This is endgame-caliber control with Fairy tech. One misread and it is over.")
    ]
  }.freeze
  GENERAL_BATTLE_TRAINER_TYPES = [
    :ACE_TRAINER_M, :ACE_TRAINER_F, :VETERAN_M, :VETERAN_F,
    :COOLTRAINER_M, :COOLTRAINER_F, :GENTLEMAN, :LADY
  ].freeze
  THEME_TRAINER_TYPE_CANDIDATES = {
    :FIRE => [:FIREBREATHER, :BLACKBELT, :VETERAN_M],
    :WATER => [:SWIMMER_M, :SWIMMER_F, :SAILOR],
    :GRASS => [:AROMALADY, :BEAUTY, :LASS],
    :ELECTRIC => [:GUITARIST, :ENGINEER, :POKEMANIAC],
    :ICE => [:SKIER, :BOARDER, :VETERAN_F],
    :FIGHTING => [:BLACKBELT, :KARATEFAMILY, :CRUSHGIRL],
    :POISON => [:JUGGLER, :POKEMANIAC, :SCIENTIST],
    :GROUND => [:HIKER, :RUINMANIAC, :BACKPACKER],
    :FLYING => [:BIRDKEEPER, :PILOT, :RANGER_M],
    :PSYCHIC => [:PSYCHIC_M, :PSYCHIC_F, :MEDIUM],
    :BUG => [:BUGCATCHER, :RANGER_F, :PARASOLLADY],
    :ROCK => [:HIKER, :RUINMANIAC, :WORKER],
    :GHOST => [:HEXMANIAC, :MEDIUM, :CHANNELER],
    :DRAGON => [:DRAGONTAMER, :VETERAN_M, :VETERAN_F],
    :DARK => [:GRUNTM, :GRUNTF, :POKEMANIAC],
    :STEEL => [:ENGINEER, :SCIENTIST, :WORKER],
    :FAIRY => [:LASS, :PARASOLLADY, :BEAUTY]
  }.freeze

  module_function

  def available_species
    @available_species ||= begin
      species = []
      GameData::Species.each do |entry|
        next if entry.form != 0
        next if entry.id == :NONE
        next if entry.respond_to?(:is_fusion) && entry.is_fusion
        species << entry.id
      end
      species.uniq
    end
  end

  def build_contender(level)
    pool = available_species
    raise _INTL("No eligible species were found for betting battles.") if pool.empty?

    species = pool.sample
    data = GameData::Species.get(species)
    {
      :species => species,
      :name => data.name,
      :level => level
    }
  end

  def build_team(level, count)
    team = []
    used_species = {}
    pool = available_species
    raise _INTL("No eligible species were found for betting battles.") if pool.empty?

    count.times do
      species = nil
      tries = 0
      while tries < 30
        candidate = pool.sample
        if !used_species[candidate]
          species = candidate
          break
        end
        tries += 1
      end
      species ||= pool.sample
      used_species[species] = true
      data = GameData::Species.get(species)
      team << {
        :species => species,
        :name => data.name,
        :level => level
      }
    end
    team
  end

  def build_type_team(level, count, theme_type)
    pool = available_species.select do |species|
      data = GameData::Species.get(species)
      data.type1 == theme_type || data.type2 == theme_type
    end
    raise _INTL("Not enough Pokémon are available for the {1} theme.",
      GameData::Type.get(theme_type).name) if pool.empty?

    team = []
    used_species = {}
    count.times do
      species = nil
      tries = 0
      while tries < 40
        candidate = pool.sample
        if !used_species[candidate]
          species = candidate
          break
        end
        tries += 1
      end
      species ||= pool.sample
      used_species[species] = true
      data = GameData::Species.get(species)
      team << {
        :species => species,
        :name => data.name,
        :level => level
      }
    end
    team
  end

  def random_existing_trainer_type(candidates, fallback = nil)
    valid = []
    candidates.each do |tr_type|
      next if !GameData::TrainerType.exists?(tr_type)
      sprite = GameData::TrainerType.front_sprite_filename(tr_type)
      next if !sprite
      valid << tr_type
    end
    return valid.sample if valid.length > 0
    return fallback if fallback && GameData::TrainerType.exists?(fallback)
    trainer_type_for_sim
  end

  def build_themed_trainer(side_label, theme_type)
    type_name = GameData::Type.get(theme_type).name
    trainer_type = random_existing_trainer_type(THEME_TRAINER_TYPE_CANDIDATES[theme_type] || [], nil)
    style_word = begin
      GameData::TrainerType.get(trainer_type).name
    rescue
      TRAINER_STYLE_WORDS.sample
    end
    name_word = TRAINER_NAME_PARTS.sample
    {
      :name => _INTL("{1} {2} {3}", type_name, style_word, name_word),
      :theme_type => theme_type,
      :side_label => side_label,
      :trainer_type => trainer_type
    }
  end

  def build_standard_trainer(side_label)
    trainer_type = random_existing_trainer_type(GENERAL_BATTLE_TRAINER_TYPES, trainer_type_for_sim)
    style_word = begin
      GameData::TrainerType.get(trainer_type).name
    rescue
      TRAINER_STYLE_WORDS.sample
    end
    name_word = TRAINER_NAME_PARTS.sample
    {
      :name => _INTL("{1} {2}", style_word, name_word),
      :side_label => side_label,
      :trainer_type => trainer_type
    }
  end

  def trainer_intro_phrase(trainer_info)
    theme_type = trainer_info ? trainer_info[:theme_type] : nil
    if theme_type && THEME_INTRO_PHRASES[theme_type] && THEME_INTRO_PHRASES[theme_type].length > 0
      return THEME_INTRO_PHRASES[theme_type].sample
    end
    ELITE_INTRO_PHRASES.sample
  end

  def show_trainer_intro(trainer_info, corner_label)
    return if !trainer_info
    pbMessage(_INTL("{1} Corner - {2}: \"{3}\"",
      corner_label,
      trainer_info[:name],
      trainer_intro_phrase(trainer_info)))
  end

  def generate_match(team_size)
    level = rand(MIN_LEVEL..MAX_LEVEL)
    red = build_team(level, team_size)
    blue = build_team(level, team_size)

    {
      :red => red,
      :blue => blue,
      :team_size => team_size,
      :red_trainer => build_standard_trainer(_INTL("Red")),
      :blue_trainer => build_standard_trainer(_INTL("Blue"))
    }
  end

  def generate_themed_duel
    level = rand(THEMED_MIN_LEVEL..THEMED_MAX_LEVEL)
    red_type = THEME_TYPES.sample
    blue_type = THEME_TYPES.sample
    blue_type = (THEME_TYPES - [red_type]).sample if blue_type == red_type

    red_trainer = build_themed_trainer(_INTL("Red"), red_type)
    blue_trainer = build_themed_trainer(_INTL("Blue"), blue_type)

    {
      :red => build_type_team(level, BATTLE_FORMATS[:themed_duel], red_type),
      :blue => build_type_team(level, BATTLE_FORMATS[:themed_duel], blue_type),
      :team_size => BATTLE_FORMATS[:themed_duel],
      :format => :themed_duel,
      :red_trainer => red_trainer,
      :blue_trainer => blue_trainer
    }
  end

  def choose_battle_format
    commands = [
      _INTL("1v1"),
      _INTL("3v3"),
      _INTL("1v1 Themed Trainer Duel (6 Pokémon each)"),
      _INTL("Cancel")
    ]
    cmd = pbMessage(_INTL("Choose battle format."), commands, commands.length)
    return :single if cmd == 0
    return :triple if cmd == 1
    return :themed_duel if cmd == 2
    nil
  end

  def affordable_bets
    return [] if !$Trainer || !$Trainer.money
    BET_AMOUNTS.select { |amount| amount <= $Trainer.money }
  end

  def choose_side(match_data)
    red_label = team_label(match_data[:red])
    blue_label = team_label(match_data[:blue])
    commands = [
      _INTL("Red Corner ({1})", red_label),
      _INTL("Blue Corner ({1})", blue_label),
      _INTL("Cancel")
    ]
    cmd = pbMessage(_INTL("Who are you betting on?"), commands, commands.length)
    return :red if cmd == 0
    return :blue if cmd == 1
    return nil
  end

  def team_label(team)
    names = team.map { |c| c[:name] }
    return _INTL("{1} Lv.{2}", names[0], team[0][:level]) if team.length == 1
    _INTL("Lv.{1}: {2}", team[0][:level], names.join(", "))
  end

  def choose_bet_amount
    bets = affordable_bets
    bets = [0] + bets

    commands = bets.map do |amount|
      if amount == 0
        _INTL("$0 (Spectate)")
      else
        _INTL("${1}", amount.to_s_formatted)
      end
    end
    commands << _INTL("Cancel")
    cmd = pbMessage(_INTL("How much do you want to wager?"), commands, commands.length)
    return nil if cmd < 0 || cmd >= bets.length
    bets[cmd]
  end

  def trainer_type_for_sim
    type = nil
    if $Trainer && $Trainer.respond_to?(:trainer_type)
      type = $Trainer.trainer_type
    end
    return type if type && GameData::TrainerType.exists?(type)

    fallback = nil
    GameData::TrainerType.each do |entry|
      fallback = entry.id
      break
    end
    fallback
  end

  def run_betting_battle(match_data)
    red_trainer_name = match_data[:red_trainer] ? match_data[:red_trainer][:name] : _INTL("Red Corner")
    blue_trainer_name = match_data[:blue_trainer] ? match_data[:blue_trainer][:name] : _INTL("Blue Corner")
    red_trainer_type = match_data[:red_trainer] ? match_data[:red_trainer][:trainer_type] : nil
    blue_trainer_type = match_data[:blue_trainer] ? match_data[:blue_trainer][:trainer_type] : nil
    red_trainer_type ||= trainer_type_for_sim
    blue_trainer_type ||= trainer_type_for_sim
    raise _INTL("No trainer type could be found for the betting simulation.") if !red_trainer_type || !blue_trainer_type

    red_trainer = NPCTrainer.new(red_trainer_name, red_trainer_type)
    blue_trainer = NPCTrainer.new(blue_trainer_name, blue_trainer_type)

    red_trainer.party = match_data[:red].map { |c| Pokemon.new(c[:species], c[:level], red_trainer) }
    blue_trainer.party = match_data[:blue].map { |c| Pokemon.new(c[:species], c[:level], blue_trainer) }

    scene = pbNewBattleScene
    battle = PokeBattle_Battle.new(scene, red_trainer.party, blue_trainer.party, red_trainer, blue_trainer)
    battle.internalBattle = false
    battle.controlPlayer = true
    battle.expGain = false
    battle.moneyGain = false
    battle.canRun = false
    battle.setBattleMode("single") if match_data[:format] == :themed_duel
    battle.setBattleMode("triple") if match_data[:team_size] == 3

    pbPrepareBattle(battle)

    decision = 0
    pbBattleAnimation(pbGetTrainerBattleBGM(blue_trainer)) do
      pbSceneStandby do
        decision = battle.pbStartBattle
      end
    end
    Input.update

    return :red if decision == 1
    return :blue if decision == 2
    return :draw if decision == 5
    :draw
  end

  def payout_for(win, bet, format)
    return bet if win == :draw
    return 0 if bet <= 0
    multiplier = FORMAT_PAYOUT_MULTIPLIERS[format] || FORMAT_PAYOUT_MULTIPLIERS[:single]
    bet * multiplier
  end

  def place_bet
    if affordable_bets.empty?
      pbMessage(_INTL("You do not have enough money to place a bet."))
      pbMessage(_INTL("You can still spectate by choosing the $0 option."))
    end

    format = choose_battle_format
    return if !format

    match_data = if format == :themed_duel
      generate_themed_duel
    else
      team_size = BATTLE_FORMATS[format]
      data = generate_match(team_size)
      data[:format] = format
      data
    end

    format_label = case format
    when :single then _INTL("1v1")
    when :triple then _INTL("3v3")
    else _INTL("1v1 Themed Trainer Duel")
    end

    pbMessage(_INTL("Today's matchup is {1}: Red Corner versus Blue Corner!", format_label))
    if match_data[:red_trainer] && match_data[:blue_trainer]
      pbMessage(_INTL("Red Trainer: {1} ({2}-type style)",
        match_data[:red_trainer][:name],
        match_data[:red_trainer][:theme_type] ? GameData::Type.get(match_data[:red_trainer][:theme_type]).name : _INTL("mixed")))
      pbMessage(_INTL("Blue Trainer: {1} ({2}-type style)",
        match_data[:blue_trainer][:name],
        match_data[:blue_trainer][:theme_type] ? GameData::Type.get(match_data[:blue_trainer][:theme_type]).name : _INTL("mixed")))
    end
    pbMessage(_INTL("Red Corner: {1}", team_label(match_data[:red])))
    pbMessage(_INTL("Blue Corner: {1}", team_label(match_data[:blue])))
    show_trainer_intro(match_data[:red_trainer], _INTL("Red"))
    show_trainer_intro(match_data[:blue_trainer], _INTL("Blue"))

    bet_amount = choose_bet_amount
    return if !bet_amount

    selected_side = nil
    if bet_amount > 0
      selected_side = choose_side(match_data)
      return if !selected_side
    end

    if bet_amount <= 0
      pbMessage(_INTL("Spectate mode selected. No wager and no payout."))
    end

    if bet_amount > 0
      if !pbConfirmMessage(_INTL("Wager ${1} on the {2} Corner?", bet_amount.to_s_formatted,
        selected_side == :red ? _INTL("Red") : _INTL("Blue")))
        return
      end
    elsif !pbConfirmMessage(_INTL("Start spectating this match?"))
      return
    end

    if bet_amount > 0 && (!$Trainer || $Trainer.money < bet_amount)
      pbMessage(_INTL("You do not have enough money to place that bet."))
      return
    end

    if bet_amount > 0
      $Trainer.money -= bet_amount
      pbMessage(_INTL("Bet accepted. Starting the match!"))
    else
      pbMessage(_INTL("Starting spectate match!"))
    end

    winning_side = run_betting_battle(match_data)
    winning_team = (winning_side == :red) ? match_data[:red] : match_data[:blue]

    if winning_side == :draw
      if bet_amount > 0
        $Trainer.money += bet_amount
        pbMessage(_INTL("It was a draw! Your bet has been refunded."))
      else
        pbMessage(_INTL("It was a draw!"))
      end
      return
    end

    pbMessage(_INTL("Winner: {1} from the {2} Corner!", team_label(winning_team),
      winning_side == :red ? _INTL("Red") : _INTL("Blue")))

    if bet_amount > 0 && winning_side == selected_side
      payout = payout_for(winning_side, bet_amount, format)
      $Trainer.money += payout
      multiplier = FORMAT_PAYOUT_MULTIPLIERS[format] || FORMAT_PAYOUT_MULTIPLIERS[:single]
      pbMessage(_INTL("You won ${1} ({2}x)!", payout.to_s_formatted, multiplier))
    elsif bet_amount <= 0
      pbMessage(_INTL("Spectate complete. No payout was applied."))
    else
      pbMessage(_INTL("You lost the bet. Better luck on the next match."))
    end
  rescue => e
    echoln "[PCBattleBetting] #{e.class}: #{e.message}"
    pbMessage(_INTL("The betting service is temporarily unavailable."))
  end

  def show_battle_betting_info
    pbMessage(_INTL("Welcome to Battle Betting."))
    pbMessage(_INTL("Pick 1v1, 3v3, or Themed Trainer Duel (1v1 with full 6-Pokémon teams)."))
    pbMessage(_INTL("You can choose a $0 spectate wager to watch with no risk and no payout."))
    pbMessage(_INTL("Payouts: 1v1 = 2x, 3v3 = 3x, Themed Duel = 4x. Draws refund your wager."))
  end
end

class BattleBettingPC
  def shouldShow?
    true
  end

  def name
    _INTL("Battle Betting Terminal")
  end

  def access
    pbMessage(_INTL("\\se[PC access]Accessed the Battle Betting Terminal."))
    pbBattleBettingMenu
  end
end

def pbBattleBettingMenu
  loop do
    commands = [
      _INTL("Place Bet"),
      _INTL("How It Works"),
      _INTL("Quit")
    ]
    cmd = pbMessage(_INTL("What would you like to do?"), commands, commands.length)

    case cmd
    when 0
      PCBattleBetting.place_bet
    when 1
      PCBattleBetting.show_battle_betting_info
    else
      break
    end
  end
end

PokemonPCList.registerPC(BattleBettingPC.new)
