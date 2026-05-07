module CaptureCompletionFallback
  @pending = []
  @processing = false
  DELAY_FRAMES = 6

  module_function

  def log(message)
    MultiplayerDebug.info("CATCH-RECOVER", message) if defined?(MultiplayerDebug)
  rescue
  end

  def same_capture?(a, b)
    return false if !a || !b
    return true if a.equal?(b)
    a_pid = (a.personalID rescue nil)
    b_pid = (b.personalID rescue nil)
    return false if a_pid.nil? || b_pid.nil?
    a_pid == b_pid && (a.species rescue nil) == (b.species rescue nil)
  rescue
    false
  end

  def track(pokemon)
    return if !pokemon
    @pending ||= []
    @pending << pokemon if !@pending.any? { |entry| same_capture?(entry, pokemon) }
    pokemon.instance_variable_set(:@kif_capture_pending, true)
    pokemon.instance_variable_set(:@kif_capture_finalized, false)
    tracked_at = (Graphics.frame_count rescue 0)
    pokemon.instance_variable_set(:@kif_capture_tracked_at, tracked_at)
    log("tracked #{pokemon.name} pid=#{pokemon.personalID rescue 'n/a'}")
  rescue
  end

  def remove(pokemon)
    return if !@pending
    @pending.reject! { |entry| same_capture?(entry, pokemon) }
  rescue
  end

  def mark_finalized(pokemon)
    return if !pokemon
    pokemon.instance_variable_set(:@kif_capture_pending, false)
    pokemon.instance_variable_set(:@kif_capture_finalized, true)
    remove(pokemon)
    log("finalized #{pokemon.name} pid=#{pokemon.personalID rescue 'n/a'}")
  rescue
  end

  def pending?
    @pending && !@pending.empty?
  end

  def pending_recent_for_battle_end(max_age_frames = nil)
    return [] if !pending?
    now = Graphics.frame_count rescue 0
    max_age_frames ||= ((Graphics.frame_rate rescue 40) * 5)
    @pending.select do |pokemon|
      next false if !pokemon
      next false if pokemon.instance_variable_get(:@kif_capture_finalized)
      tracked_at = (pokemon.instance_variable_get(:@kif_capture_tracked_at) rescue now).to_i
      now - tracked_at <= max_age_frames
    end
  rescue
    []
  end

  def ready_to_flush?
    return false if !pending? || @processing
    return false if !$scene.is_a?(Scene_Map)
    return false if !$game_temp || $game_temp.in_battle || $game_temp.in_menu
    return false if $game_temp.message_window_showing
    return false if $game_temp.player_transferring || $game_temp.transition_processing
    return false if $game_system && $game_system.map_interpreter &&
                    $game_system.map_interpreter.running?
    true
  end

  def already_in_party?(pokemon)
    pid = (pokemon.personalID rescue nil)
    return false if pid.nil?
    $Trainer.party.any? { |party_pkmn| party_pkmn && (party_pkmn.personalID rescue nil) == pid }
  rescue
    false
  end

  def recover_scene
    begin
      EBDXOverlayCleanup.cleanup if defined?(EBDXOverlayCleanup)
    rescue
    end
    begin
      EBDXOverlayCleanup.cleanup_strays(true) if defined?(EBDXOverlayCleanup)
    rescue
    end
    begin
      if $scene.is_a?(Scene_Map)
        if $scene.respond_to?(:disposeSpritesets) && $scene.respond_to?(:createSpritesets)
          $scene.disposeSpritesets
          $scene.createSpritesets
        elsif $scene.respond_to?(:updateSpritesets)
          $scene.updateSpritesets(true)
        end
      end
    rescue
    end
    begin
      $scene.updateSpritesets(true) if $scene.is_a?(Scene_Map) && $scene.respond_to?(:updateSpritesets)
    rescue
    end
    begin
      Graphics.frame_reset
    rescue
    end
  end

  def finalize_on_map(pokemon)
    return mark_finalized(pokemon) if already_in_party?(pokemon)
    log("recovering #{pokemon.name} pid=#{pokemon.personalID rescue 'n/a'} on map")
    show_pokedex = false
    begin
      show_pokedex = !$Trainer.owned?(pokemon.species)
      $Trainer.pokedex.register(pokemon)
      if show_pokedex
        $Trainer.pokedex.set_owned(pokemon.species)
        $Trainer.pokedex.register_last_seen(pokemon) if $Trainer.has_pokedex
      end
      $Trainer.pokedex.set_shadow_pokemon_owned(pokemon.species) if pokemon.shadowPokemon?
      pokemon.record_first_moves
    rescue
    end
    storage_info = pbStorePokemonSilentlyGlobal(pokemon)
    begin
      skip_nickname = defined?($PokemonSystem) && $PokemonSystem &&
                      $PokemonSystem.respond_to?(:skipcaughtnickname) &&
                      $PokemonSystem.skipcaughtnickname == 1
      if defined?(DeferredCaughtPokemonProcessing)
        DeferredCaughtPokemonProcessing.enqueue(
          pokemon:      pokemon,
          show_pokedex: show_pokedex,
          storage_info: storage_info,
          ask_nickname: !pokemon.shadowPokemon? && !skip_nickname,
          autosave:     true
        )
      end
    rescue
    end
    begin
      MultiplayerCatchReports.announce_catches([pokemon]) if defined?(MultiplayerCatchReports)
    rescue
    end
    mark_finalized(pokemon)
  rescue => e
    log("recovery failed #{e.class}: #{e.message}")
  end

  def flush(force = false)
    return false if !force && !ready_to_flush?
    @processing = true
    now = Graphics.frame_count rescue 0
    to_finalize = @pending.dup.select do |pokemon|
      next false if !pokemon
      next false if pokemon.instance_variable_get(:@kif_capture_finalized)
      if force
        true
      else
        tracked_at = (pokemon.instance_variable_get(:@kif_capture_tracked_at) rescue now).to_i
        now - tracked_at >= DELAY_FRAMES
      end
    end
    if !to_finalize.empty?
      log("scene recovery for #{to_finalize.length} pending capture(s)")
      recover_scene
    end
    to_finalize.each do |pokemon|
      next if !pokemon
      finalize_on_map(pokemon)
    end
    @processing = false
    !to_finalize.empty?
  rescue => e
    @processing = false
    log("flush error #{e.class}: #{e.message}")
    false
  end
end

module DeferredCaughtPokemonProcessing
  @pending = []
  @processing = false
  @needs_scene_recovery = false

  module_function

  def log(message)
    MultiplayerDebug.info("CATCH-DEFER", message) if defined?(MultiplayerDebug)
  rescue
  end

  def enqueue(pokemon_or_entry, show_pokedex = nil)
    @pending ||= []
    entry = if pokemon_or_entry.is_a?(Hash)
      pokemon_or_entry.dup
    else
      { pokemon: pokemon_or_entry, show_pokedex: show_pokedex }
    end
    @pending << entry
    pokemon = entry[:pokemon] rescue nil
    log("queued #{pokemon.name} pid=#{pokemon.personalID rescue 'n/a'}") if pokemon
    @needs_scene_recovery = true
    EBDXOverlayCleanup.request_stray_cleanup if defined?(EBDXOverlayCleanup)
  end

  def pending?
    @pending && !@pending.empty?
  end

  def ready_to_flush?
    return false if !pending? || @processing
    return false if !$scene.is_a?(Scene_Map)
    return false if !$game_temp || $game_temp.in_battle || $game_temp.in_menu
    return false if $game_temp.message_window_showing
    return false if $game_temp.player_transferring || $game_temp.transition_processing
    return false if $game_system && $game_system.map_interpreter &&
                    $game_system.map_interpreter.running?
    return true
  end

  def flush(force = false)
    return false if !force && !ready_to_flush?
    return false if !pending?
    @processing = true
    log("flushing #{@pending.length} queued catch follow-up(s)#{" (forced)" if force}")
    recover_scene_if_needed
    while pending?
      entry = @pending.shift
      process_entry(entry)
    end
    @processing = false
    return true
  rescue => e
    @processing = false
    log("flush error #{e.class}: #{e.message}")
    raise
  end

  def recover_scene_if_needed
    return if !@needs_scene_recovery
    begin
      Graphics.transition(0)
    rescue
    end
    begin
      Graphics.frame_reset
    rescue
    end
    begin
      EBDXOverlayCleanup.cleanup if defined?(EBDXOverlayCleanup)
    rescue
    end
    begin
      EBDXOverlayCleanup.cleanup_strays(true) if defined?(EBDXOverlayCleanup)
    rescue
    end
    @needs_scene_recovery = false
  end

  def process_entry(entry_or_pokemon, show_pokedex = nil)
    entry = entry_or_pokemon.is_a?(Hash) ? entry_or_pokemon : {
      pokemon:      entry_or_pokemon,
      show_pokedex: show_pokedex
    }
    pokemon      = entry[:pokemon]
    show_pokedex = entry[:show_pokedex]
    storage_info = entry[:storage_info]
    ask_nickname = !!entry[:ask_nickname]
    autosave     = entry.key?(:autosave) ? !!entry[:autosave] : true
    if show_pokedex && $Trainer.has_pokedex
      pbMessage(_INTL("{1}'s data was added to the Pokedex.", pokemon.name))
      $Trainer.pokedex.register_last_seen(pokemon)
      pbShowPokedex(pokemon.species)
    end
    pbNickname(pokemon) if ask_nickname
    if storage_info
      pbShowDeferredCaughtPokemonStorageMessage(pokemon, storage_info)
    else
      gave_away_pokemon = promptGiveToPartner(pokemon) if isPartneredWithAnyTrainer()
      pbPromptCaughtPokemonActionAfterBattle(pokemon) if !gave_away_pokemon
    end
    Kernel.tryAutosave if autosave && $game_switches[AUTOSAVE_CATCH_SWITCH]
  end
end

def pbShowDeferredCaughtPokemonStorageMessage(pokemon, storage_info)
  return if !pokemon || !storage_info
  stored_box = storage_info[:stored_box]
  if stored_box.nil? || stored_box < 0
    pbMessage(_INTL("{1} has been added to your party.", pokemon.name))
    return
  end
  creator          = storage_info[:creator]
  current_box_name = storage_info[:current_box_name].to_s
  stored_box_name  = storage_info[:stored_box_name].to_s
  if stored_box != storage_info[:current_box]
    if creator
      pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.", current_box_name, creator))
    else
      pbMessage(_INTL("Box \"{1}\" on someone's PC was full.", current_box_name))
    end
    pbMessage(_INTL("{1} was transferred to box \"{2}\".", pokemon.name, stored_box_name))
  else
    if creator
      pbMessage(_INTL("{1} was transferred to {2}'s PC.", pokemon.name, creator))
    else
      pbMessage(_INTL("{1} was transferred to someone's PC.", pokemon.name))
    end
    pbMessage(_INTL("It was stored in box \"{1}\".", stored_box_name))
  end
end

def pbStorePokemonSilentlyGlobal(pokemon)
  storage_info = {
    stored_box:       -1,
    current_box:      $PokemonStorage.currentBox,
    creator:          ($Trainer.seen_storage_creator ? pbGetStorageCreator : nil),
    current_box_name: "",
    stored_box_name:  ""
  }
  if !$Trainer.party_full?
    $Trainer.party[$Trainer.party.length] = pokemon
    return storage_info
  end
  begin
    pokemon.heal
  rescue
  end
  storage_info[:current_box_name] = $PokemonStorage[storage_info[:current_box]].name rescue ""
  stored_box = $PokemonStorage.pbStoreCaught(pokemon)
  storage_info[:stored_box] = stored_box
  storage_info[:stored_box_name] = $PokemonStorage[stored_box].name rescue ""
  storage_info
end

def pbDeferredStoreCaughtPokemon(pokemon)
  skip_nickname = defined?($PokemonSystem) && $PokemonSystem &&
                  $PokemonSystem.respond_to?(:skipcaughtnickname) &&
                  $PokemonSystem.skipcaughtnickname == 1
  pbNickname(pokemon) if !pokemon.shadowPokemon? && !skip_nickname
  pbStorePokemon(pokemon)
end

def pbDeferredSwapCaughtPokemon(caughtPokemon)
  pbChoosePokemon(1, 2,
                  proc { |poke|
                    !poke.egg? &&
                      !(poke.isShadow? rescue false)
                  })
  index = pbGet(1)
  return false if index == -1
  if $PokemonGlobal.pokemonSelectionOriginalParty != nil
    $PokemonStorage.pbStoreCaught($PokemonGlobal.pokemonSelectionOriginalParty[index])
  else
    $PokemonStorage.pbStoreCaught($Trainer.party[index])
  end
  pbRemovePokemonAt(index)
  pbDeferredStoreCaughtPokemon(caughtPokemon)
  tmp = $Trainer.party[index]
  $Trainer.party[index] = $Trainer.party[-1]
  $Trainer.party[-1] = tmp
  return true
end

def pbPromptCaughtPokemonActionAfterBattle(pokemon)
  pickedOption = false
  if $PokemonGlobal.pokemonSelectionOriginalParty != nil
    return pbDeferredStoreCaughtPokemon(pokemon) if !($PokemonGlobal.pokemonSelectionOriginalParty.length >= Settings::MAX_PARTY_SIZE)
  else
    return pbDeferredStoreCaughtPokemon(pokemon) if !$Trainer.party_full?
  end

  if $PokemonSystem.skipcaughtprompt == 1
    return pbDeferredStoreCaughtPokemon(pokemon)
  end

  return promptKeepOrRelease(pokemon) if isOnPinkanIsland() && !$game_switches[SWITCH_PINKAN_FINISHED]
  while !pickedOption
    command = pbMessage(_INTL("\\ts[]Your team is full!"),
                        [_INTL("Add to your party"), _INTL("Store to PC"),], 2)
    echoln("command " + command.to_s)
    case command
    when 0
      pickedOption = pbDeferredSwapCaughtPokemon(pokemon)
    else
      pbDeferredStoreCaughtPokemon(pokemon)
      pickedOption = true
    end
  end
end

class Scene_Map
  unless method_defined?(:capture_completion_recovery_original_update)
    alias capture_completion_recovery_original_update update
  end

  def update
    capture_completion_recovery_original_update
    CaptureCompletionFallback.flush if defined?(CaptureCompletionFallback)
  end
end

module PokeBattle_BattleCommon
  #=============================================================================
  # Store caught Pokémon
  #=============================================================================
  def pbStorePokemon(pkmn)
    skip_nickname = defined?($PokemonSystem) && $PokemonSystem &&
                    $PokemonSystem.respond_to?(:skipcaughtnickname) &&
                    $PokemonSystem.skipcaughtnickname == 1
    currentBox = @peer.pbCurrentBox
    storedBox = @peer.pbStorePokemon(pbPlayer, pkmn)
    CaptureCompletionFallback.mark_finalized(pkmn) if defined?(CaptureCompletionFallback)
    # Nickname the Pokémon (unless it's a Shadow Pokémon)
    if !pkmn.shadowPokemon? && !skip_nickname
      if pbDisplayConfirm(_INTL("Would you like to give a nickname to {1}?", pkmn.name))
        nickname = @scene.pbNameEntry(_INTL("{1}'s nickname?", pkmn.speciesName), pkmn)
        pkmn.name = nickname
      end
    end
    # Store the Pokémon
    currentBox = currentBox
    storedBox = storedBox
    if storedBox < 0
      pbDisplayPaused(_INTL("{1} has been added to your party.", pkmn.name))
      @initialItems[0][pbPlayer.party.length - 1] = pkmn.item_id if @initialItems
      return
    end
    # Messages saying the Pokémon was stored in a PC box
    creator = @peer.pbGetStorageCreatorName
    curBoxName = @peer.pbBoxName(currentBox)
    boxName = @peer.pbBoxName(storedBox)
    if storedBox != currentBox
      if creator
        pbDisplayPaused(_INTL("Box \"{1}\" on {2}'s PC was full.", curBoxName, creator))
      else
        pbDisplayPaused(_INTL("Box \"{1}\" on someone's PC was full.", curBoxName))
      end
      pbDisplayPaused(_INTL("{1} was transferred to box \"{2}\".", pkmn.name, boxName))
    else
      if creator
        pbDisplayPaused(_INTL("{1} was transferred to {2}'s PC.", pkmn.name, creator))
      else
        pbDisplayPaused(_INTL("{1} was transferred to someone's PC.", pkmn.name))
      end
      pbDisplayPaused(_INTL("It was stored in box \"{1}\".", boxName))
    end
  end

  def pbSwapCaughtPokemonIntoParty(caughtPokemon)
    pbChoosePokemon(1, 2,
                    proc { |poke|
                      !poke.egg? &&
                        !(poke.isShadow? rescue false)
                    })
    index = pbGet(1)
    return false if index == -1
    if $PokemonGlobal.pokemonSelectionOriginalParty != nil
      $PokemonStorage.pbStoreCaught($PokemonGlobal.pokemonSelectionOriginalParty[index])
    else
      $PokemonStorage.pbStoreCaught($Trainer.party[index])
    end
    pbRemovePokemonAt(index)
    pbStorePokemon(caughtPokemon)
    if index < $Trainer.party.length - 1
      tmp = $Trainer.party[index]
      $Trainer.party[index] = $Trainer.party[-1]
      $Trainer.party[-1] = tmp
    end
    return true
  end

  def pbHandleCaughtPokemonStorage(caughtPokemon)
    if $PokemonGlobal.pokemonSelectionOriginalParty != nil
      return pbStorePokemon(caughtPokemon) if !($PokemonGlobal.pokemonSelectionOriginalParty.length >= Settings::MAX_PARTY_SIZE)
    else
      return pbStorePokemon(caughtPokemon) if !$Trainer.party_full?
    end

    # EBDX battle teardown is not reliably handling the party-full catch prompt.
    # Prefer guaranteed PC storage over leaving the catch pending until a later battle.
    if defined?(PokeBattle_SceneEBDX) && @scene.is_a?(PokeBattle_SceneEBDX)
      CaptureCompletionFallback.log("party full under EBDX; auto-storing #{caughtPokemon.name}") if defined?(CaptureCompletionFallback)
      return pbStorePokemon(caughtPokemon)
    end

    if defined?($PokemonSystem) && $PokemonSystem &&
       $PokemonSystem.respond_to?(:skipcaughtprompt) &&
       $PokemonSystem.skipcaughtprompt == 1
      return pbStorePokemon(caughtPokemon)
    end

    return promptKeepOrRelease(caughtPokemon) if isOnPinkanIsland() && !$game_switches[SWITCH_PINKAN_FINISHED]

    loop do
      command = pbMessage(_INTL("\\ts[]Your team is full!"),
                          [_INTL("Add to your party"), _INTL("Store to PC")], 2)
      case command
      when 0
        return true if pbSwapCaughtPokemonIntoParty(caughtPokemon)
      else
        pbStorePokemon(caughtPokemon)
        return true
      end
    end
  end

  def pbStorePokemonSilently(pkmn)
    storage_info = {
      stored_box:       -1,
      current_box:      @peer.pbCurrentBox,
      creator:          @peer.pbGetStorageCreatorName,
      current_box_name: "",
      stored_box_name:  ""
    }
    if !pbPlayer.party_full?
      pbPlayer.party[pbPlayer.party.length] = pkmn
      @initialItems[0][pbPlayer.party.length - 1] = pkmn.item_id if @initialItems
    else
      pkmn.heal
      storage_info[:current_box_name] = @peer.pbBoxName(storage_info[:current_box])
      stored_box = $PokemonStorage.pbStoreCaught(pkmn)
      storage_info[:stored_box] = stored_box
      storage_info[:stored_box_name] = @peer.pbBoxName(stored_box)
    end
    CaptureCompletionFallback.mark_finalized(pkmn) if defined?(CaptureCompletionFallback)
    storage_info
  end

  def pbUseDeferredCaughtPokemonFlow?
    return false if !defined?(EBDXToggle) || !EBDXToggle.enabled?
    return true if defined?(PokeBattle_SceneEBDX) && @scene.is_a?(PokeBattle_SceneEBDX)
    return true if @scene && @scene.class.name.to_s.include?("EBDX")
    return true if @scene && @scene.respond_to?(:vector) && @scene.respond_to?(:pbThrowSuccess)
    false
  rescue
    false
  end

  #def pbChoosePokemon(variableNumber, nameVarNumber, ableProc = nil, allowIneligible = false)
  # def swapCaughtPokemon(caughtPokemon)
  #   pbChoosePokemon(1,2,
  #                   proc {|poke|
  #                     !poke.egg? &&
  #                       !(poke.isShadow? rescue false)
  #                   })
  #   index = pbGet(1)
  #   return false if index == -1
  #   $PokemonStorage.pbStoreCaught($Trainer.party[index])
  #   pbRemovePokemonAt(index)
  #   pbStorePokemon(caughtPokemon)
  #   return true
  # end

  # Register all caught Pokémon in the Pokédex, and store them.
  def pbRecordAndStoreCaughtPokemon
    @caughtPokemon.each do |pkmn|
      pbPlayer.pokedex.register(pkmn) # In case the form changed upon leaving battle
      # Record the Pokémon's species as owned in the Pokédex
      if !pbPlayer.owned?(pkmn.species)
        pbPlayer.pokedex.set_owned(pkmn.species)
        if $Trainer.has_pokedex
          pbDisplayPaused(_INTL("{1}'s data was added to the Pokédex.", pkmn.name))
          pbPlayer.pokedex.register_last_seen(pkmn)
          @scene.pbShowPokedex(pkmn.species)
        end
      end
      # Record a Shadow Pokémon's species as having been caught
      pbPlayer.pokedex.set_shadow_pokemon_owned(pkmn.species) if pkmn.shadowPokemon?
      # Store caught Pokémon

      gave_away_pokemon = promptGiveToPartner(pkmn) if isPartneredWithAnyTrainer()

      pbHandleCaughtPokemonStorage(pkmn) if !gave_away_pokemon
      if $game_switches[AUTOSAVE_CATCH_SWITCH]
        Kernel.tryAutosave()
      end

    end
    @caughtPokemon.clear
  end

  # def promptCaughtPokemonAction(pokemon)
  #   pickedOption = false
  #   return pbStorePokemon(pokemon) if !$Trainer.party_full?
  #
  #   while !pickedOption
  #     command = pbMessage("\\ts[]Your team is full!"),
  #                         ["Add to your party", "Store to PC",], 2)
  #     echoln ("command " + command.to_s)
  #     case command
  #     when 0 #SWAP
  #       if swapCaughtPokemon(pokemon)
  #         echoln pickedOption
  #         pickedOption = true
  #       end
  #     else
  #       #STORE
  #       pbStorePokemon(pokemon)
  #       echoln pickedOption
  #       pickedOption = true
  #     end
  #   end
  #
  # end

  #=============================================================================
  # Throw a Poké Ball
  #=============================================================================
  def pbTrainerBallCaptureAllowed?(ball, battler)
    return false unless trainerBattle?
    return true if GameData::Item.get(ball).is_snag_ball? && battler.shadowPokemon?
    return false unless $PokemonSystem && $PokemonSystem.respond_to?(:rocketballsteal)
    ball_data = GameData::Item.get(ball)
    case $PokemonSystem.rocketballsteal
    when 1
      return ball_data.id == :ROCKETBALL
    when 2
      return ball_data.is_poke_ball?
    end
    return false
  end

  def pbThrowPokeBall(idxBattler, ball, catch_rate = nil, showPlayer = false)
    # Determine which Pokémon you're throwing the Poké Ball at
    battler = nil
    if opposes?(idxBattler)
      battler = @battlers[idxBattler]
    else
      battler = @battlers[idxBattler].pbDirectOpposing(true)
    end
    if battler.fainted?
      battler.eachAlly do |b|
        battler = b
        break
      end
    end
    # Messages
    itemName = GameData::Item.get(ball).name
    if battler.fainted?
      if itemName.starts_with_vowel?
        pbDisplay(_INTL("{1} threw an {2}!", pbPlayer.name, itemName))
      else
        pbDisplay(_INTL("{1} threw a {2}!", pbPlayer.name, itemName))
      end
      pbDisplay(_INTL("But there was no target..."))
      return
    end
    if itemName.starts_with_vowel?
      pbDisplayBrief(_INTL("{1} threw an {2}!", pbPlayer.name, itemName))
    else
      pbDisplayBrief(_INTL("{1} threw a {2}!", pbPlayer.name, itemName))
    end
    # Animation of opposing trainer blocking Poké Balls (unless it's a Snag Ball
    # at a Shadow Pokémon)
    if trainerBattle? && !pbTrainerBallCaptureAllowed?(ball, battler)
      @scene.pbThrowAndDeflect(ball, 1)
      pbDisplay(_INTL("The Trainer blocked your Poké Ball! Don't be a thief!"))
      return
    elsif $game_switches[SWITCH_CANNOT_CATCH_POKEMON]
      @scene.pbThrowAndDeflect(ball, 1)
      pbDisplay(_INTL("The Pokémon is impossible to catch!"))
      return
    end
    # Calculate the number of shakes (4=capture)
    pkmn = battler.pokemon
    @criticalCapture = false
    numShakes = pbCaptureCalc(pkmn, battler, catch_rate, ball)
    PBDebug.log("[Threw Poké Ball] #{itemName}, #{numShakes} shakes (4=capture)")
    # Animation of Ball throw, absorb, shake and capture/burst out
    @scene.pbThrow(ball, numShakes, @criticalCapture, battler.index, showPlayer)
    # Outcome message
    case numShakes
    when 0
      pbDisplay(_INTL("Oh no! The Pokémon broke free!"))
      BallHandlers.onFailCatch(ball, self, battler)
    when 1
      pbDisplay(_INTL("Aww! It appeared to be caught!"))
      BallHandlers.onFailCatch(ball, self, battler)
    when 2
      pbDisplay(_INTL("Aargh! Almost had it!"))
      BallHandlers.onFailCatch(ball, self, battler)
    when 3
      pbDisplay(_INTL("Gah! It was so close, too!"))
      BallHandlers.onFailCatch(ball, self, battler)
    when 4
      if $game_switches[SWITCH_SILVERBOSS_BATTLE]
        pkmn.species = :PALDIATINA
        pkmn.name = "Paldiatina"
      end
      pbDisplayBrief(_INTL("Gotcha! {1} was caught!", pkmn.name))
      @scene.pbThrowSuccess # Play capture success jingle
      pbRemoveFromParty(battler.index, battler.pokemonIndex)
      # Gain Exp
      if Settings::GAIN_EXP_FOR_CAPTURE
        battler.captured = true
        pbGainExp
        battler.captured = false
      end
      battler.pbReset
      if pbAllFainted?(battler.index)
        @decision = (trainerBattle?) ? 1 : 4 # Battle ended by win/capture
      end
      # Modify the Pokémon's properties because of the capture
      if pbTrainerBallCaptureAllowed?(ball, battler)
        pkmn.owner = Pokemon::Owner.new_from_trainer(pbPlayer)
      end
      BallHandlers.onCatch(ball, self, pkmn)
      pkmn.poke_ball = ball
      pkmn.makeUnmega if pkmn.mega?
      pkmn.makeUnprimal
      pkmn.update_shadow_moves if pkmn.shadowPokemon?
      pkmn.record_first_moves
      # Reset form
      pkmn.forced_form = nil if MultipleForms.hasFunction?(pkmn.species, "getForm")
      @peer.pbOnLeavingBattle(self, pkmn, true, true)
      # Make the Poké Ball and data box disappear
      @scene.pbHideCaptureBall(idxBattler)
      # Save the Pokémon for storage at the end of battle
      @caughtPokemon.push(pkmn)
      CaptureCompletionFallback.track(pkmn) if defined?(CaptureCompletionFallback)
    end
  end

  #=============================================================================
  # Calculate how many shakes a thrown Poké Ball will make (4 = capture)
  #=============================================================================
  def pbCaptureCalc(pkmn, battler, catch_rate, ball)
    return 4 if $DEBUG && Input.press?(Input::CTRL)
    # Get a catch rate if one wasn't provided
    catch_rate = pkmn.species_data.catch_rate if !catch_rate
    # Modify catch_rate depending on the Poké Ball's effect
    ultraBeast = [:NIHILEGO, :BUZZWOLE, :PHEROMOSA, :XURKITREE, :CELESTEELA,
                  :KARTANA, :GUZZLORD, :POIPOLE, :NAGANADEL, :STAKATAKA,
                  :BLACEPHALON].include?(pkmn.species)
    if !ultraBeast || ball == :BEASTBALL
      catch_rate = BallHandlers.modifyCatchRate(ball, catch_rate, self, battler, ultraBeast)
    else
      catch_rate /= 10
    end



    # First half of the shakes calculation
    a = battler.totalhp
    b = battler.hp
    x = ((3 * a - 2 * b) * catch_rate.to_f) / (3 * a)
    # Calculation modifiers
    if battler.status == :SLEEP || battler.status == :FROZEN
      x *= 2.5
    elsif battler.status != :NONE
      x *= 1.5
    end
    x = x.floor
    x = 1 if x < 1
    # Definite capture, no need to perform randomness checks
    return 4 if x >= 255 || BallHandlers.isUnconditional?(ball, self, battler)
    # Second half of the shakes calculation
    y = (65536 / ((255.0 / x) ** 0.1875)).floor

    #Increased chances of catching if is on last ball
    isOnLastBall = !$PokemonBag.pbHasItem?(ball)
    echoln isOnLastBall
    # Critical capture check
    if isOnLastBall
      c = x * 6 / 12
      if c > 0 && pbRandom(256) < c
        @criticalCapture = true
        return 4
      end
    end
    # Calculate the number of shakes
    numShakes = 0
    for i in 0...4
      break if numShakes < i
      numShakes += 1 if pbRandom(65536) < y
    end
    return numShakes
  end
end

module PokeBattle_BattleCommon
  def pbRecordAndStoreCaughtPokemon
    CaptureCompletionFallback.log("pbRecordAndStoreCaughtPokemon start count=#{@caughtPokemon.length}") if defined?(CaptureCompletionFallback)
    if pbUseDeferredCaughtPokemonFlow?
      @caughtPokemon.each do |pkmn|
        show_pokedex = !pbPlayer.owned?(pkmn.species)
        pbPlayer.pokedex.register(pkmn) # In case the form changed upon leaving battle
        if show_pokedex
          pbPlayer.pokedex.set_owned(pkmn.species)
          pbPlayer.pokedex.register_last_seen(pkmn) if $Trainer.has_pokedex
        end
        pbPlayer.pokedex.set_shadow_pokemon_owned(pkmn.species) if pkmn.shadowPokemon?
        storage_info = pbStorePokemonSilently(pkmn)
        skip_nickname = defined?($PokemonSystem) && $PokemonSystem &&
                        $PokemonSystem.respond_to?(:skipcaughtnickname) &&
                        $PokemonSystem.skipcaughtnickname == 1
        DeferredCaughtPokemonProcessing.enqueue(
          pokemon:      pkmn,
          show_pokedex: show_pokedex,
          storage_info: storage_info,
          ask_nickname: !pkmn.shadowPokemon? && !skip_nickname,
          autosave:     true
        )
        CaptureCompletionFallback.log("deferred follow-up queued for #{pkmn.name} pid=#{pkmn.personalID rescue 'n/a'}") if defined?(CaptureCompletionFallback)
      end
      @caughtPokemon.clear
      return
    end
    @caughtPokemon.each do |pkmn|
      pbPlayer.pokedex.register(pkmn) # In case the form changed upon leaving battle
      if !pbPlayer.owned?(pkmn.species)
        pbPlayer.pokedex.set_owned(pkmn.species)
        if $Trainer.has_pokedex
          pbDisplayPaused(_INTL("{1}'s data was added to the Pokédex.", pkmn.name))
          pbPlayer.pokedex.register_last_seen(pkmn)
          @scene.pbShowPokedex(pkmn.species)
        end
      end
      pbPlayer.pokedex.set_shadow_pokemon_owned(pkmn.species) if pkmn.shadowPokemon?
      gave_away_pokemon = promptGiveToPartner(pkmn) if isPartneredWithAnyTrainer()
      pbHandleCaughtPokemonStorage(pkmn) if !gave_away_pokemon
      Kernel.tryAutosave if $game_switches[AUTOSAVE_CATCH_SWITCH]
      CaptureCompletionFallback.mark_finalized(pkmn) if defined?(CaptureCompletionFallback)
    end
    @caughtPokemon.clear
  end
end
