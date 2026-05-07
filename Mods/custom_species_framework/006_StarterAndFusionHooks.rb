alias csf_original_obtainStarter obtainStarter unless defined?(csf_original_obtainStarter)
def obtainStarter(starterIndex = 0)
  if defined?(CustomSpeciesFramework) &&
     CustomSpeciesFramework.override_default_starters? &&
     !($game_switches && $game_switches[SWITCH_RANDOM_STARTERS])
    custom_starter = CustomSpeciesFramework.starter_for_index(starterIndex)
    return GameData::Species.get(custom_starter) if custom_starter
  end
  return csf_original_obtainStarter(starterIndex)
end

alias csf_original_setRivalStarter setRivalStarter unless defined?(csf_original_setRivalStarter)
def setRivalStarter(starterIndex1, starterIndex2)
  if defined?(CustomSpeciesFramework) &&
     CustomSpeciesFramework.override_default_starters? &&
     !($game_switches && $game_switches[SWITCH_RANDOM_STARTERS])
    player_index = CustomSpeciesFramework.player_starter_index_from_remaining(starterIndex1, starterIndex2)
    rival_species = CustomSpeciesFramework.rival_counterpick_for_player_index(player_index)
    if rival_species
      rival_species_data = GameData::Species.get(rival_species)
      pbSet(VAR_RIVAL_STARTER, rival_species_data.id_number)
      $game_switches[SWITCH_DEFINED_RIVAL_STARTER] = true
      return rival_species_data.id_number
    end
  end
  return csf_original_setRivalStarter(starterIndex1, starterIndex2)
end

alias csf_original_setStarterEasterEgg setStarterEasterEgg unless defined?(csf_original_setStarterEasterEgg)
def setStarterEasterEgg
  csf_original_setStarterEasterEgg
  if defined?(CustomSpeciesFramework) &&
     !CustomSpeciesFramework.starter_selection_common_event_patched?
    CustomSpeciesFramework.prompt_startup_starter_set!
  end
end

def pbDNASplicing(pokemon, scene, item = :DNASPLICERS)
  is_supersplicer = isSuperSplicersMechanics(item)
  playingBGM = $game_system.getPlayingBGM

  if pokemon.isFusion?
    return true if pbUnfuse(pokemon, scene, is_supersplicer)
    return false
  end

  if pokemon.fused != nil
    if $Trainer.party.length >= 6
      scene.pbDisplay(_INTL("Your party is full! You can't unfuse {1}.", pokemon.name))
      return false
    end
    $Trainer.party[$Trainer.party.length] = pokemon.fused
    pokemon.fused = nil
    pokemon.form = 0
    scene.pbHardRefresh
    scene.pbDisplay(_INTL("{1} changed Forme!", pokemon.name))
    return true
  end

  blocking_message = CustomSpeciesFramework.fusion_block_message_for(pokemon)
  if blocking_message
    scene.pbDisplay(blocking_message)
    return false
  end

  chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pok\u00e9mon?"))
  return false if chosen < 0
  poke2 = $Trainer.party[chosen]

  if pokemon == poke2
    scene.pbDisplay(_INTL("{1} can't be fused with itself!", pokemon.name))
    return false
  end

  if !CustomSpeciesFramework.can_fuse_pair?(pokemon, poke2)
    scene.pbDisplay(CustomSpeciesFramework.fusion_pair_message(pokemon, poke2))
    return false
  end

  selectedHead = selectFusion(pokemon, poke2, is_supersplicer)
  if selectedHead == -1
    return false
  end
  if selectedHead.nil?
    scene.pbDisplay(_INTL("It won't have any effect."))
    return false
  end

  selectedBase = selectedHead == pokemon ? poke2 : pokemon
  firstOptionSelected = selectedHead == pokemon
  if !firstOptionSelected
    chosen = getPokemonPositionInParty(pokemon)
    if chosen == -1
      scene.pbDisplay(_INTL("There was an error..."))
      return false
    end
  end

  if Kernel.pbConfirmMessage(_INTL("Fuse {1} and {2}?", selectedHead.name, selectedBase.name))
    return false if !pbFuse(selectedHead, selectedBase, item)
    pbRemovePokemonAt(chosen)
    scene.pbHardRefresh
    pbBGMPlay(playingBGM)
    return true
  end
  return false
end

alias csf_original_selectFusion selectFusion unless defined?(csf_original_selectFusion)
def selectFusion(pokemon, poke2, supersplicers = false)
  return nil if !CustomSpeciesFramework.can_fuse_pair?(pokemon, poke2)
  return csf_original_selectFusion(pokemon, poke2, supersplicers)
end

alias csf_original_pbFuse pbFuse unless defined?(csf_original_pbFuse)
def pbFuse(pokemon, poke2, splicer_item)
  return false if !CustomSpeciesFramework.can_fuse_pair?(pokemon, poke2)
  return csf_original_pbFuse(pokemon, poke2, splicer_item)
end

class PokemonStorageScreen
  def organizeActions(selected, pokemon, heldpoke, isTransferBox)
    commands = []
    cmdMove = -1
    cmdSummary = -1
    cmdWithdraw = -1
    cmdItem = -1
    cmdFuse = -1
    cmdUnfuse = -1
    cmdReverse = -1
    cmdRelease = -1
    cmdDebug = -1
    cmdCancel = -1
    cmdNickname = -1

    if heldpoke
      helptext = _INTL("{1} is selected.", heldpoke.name)
      commands[cmdMove = commands.length] = (pokemon) ? _INTL("Shift") : _INTL("Place")
    elsif pokemon
      helptext = _INTL("{1} is selected.", pokemon.name)
      commands[cmdMove = commands.length] = _INTL("Move")
    end
    commands[cmdSummary = commands.length] = _INTL("Summary")
    if pokemon != nil && !isTransferBox
      if pokemon.isFusion?
        commands[cmdUnfuse = commands.length] = _INTL("Unfuse")
        commands[cmdReverse = commands.length] = _INTL("Reverse") if $PokemonBag.pbQuantity(:DNAREVERSER) > 0 || $PokemonBag.pbQuantity(:INFINITEREVERSERS) > 0
      elsif CustomSpeciesFramework.can_show_fuse_command?(pokemon) && !@heldpkmn
        commands[cmdFuse = commands.length] = _INTL("Fuse")
      end
    end
    commands[cmdNickname = commands.length] = _INTL("Nickname") if !@heldpkmn && !isTransferBox
    commands[cmdWithdraw = commands.length] = (selected[0] == -1) ? _INTL("Store") : _INTL("Withdraw")
    commands[cmdItem = commands.length] = _INTL("Item") if !isTransferBox
    commands[cmdRelease = commands.length] = _INTL("Release") if !isTransferBox
    commands[cmdDebug = commands.length] = _INTL("Debug") if $DEBUG
    commands[cmdCancel = commands.length] = _INTL("Cancel")

    command = pbShowCommands(helptext, commands)
    if cmdMove >= 0 && command == cmdMove
      if @heldpkmn
        (pokemon) ? pbSwap(selected) : pbPlace(selected)
      else
        if @scene.cursormode == "multiselect"
          pbHoldMulti(selected[0], selected[1])
        else
          pbHold(selected)
        end
      end
    elsif cmdSummary >= 0 && command == cmdSummary
      pbSummary(selected, @heldpkmn)
    elsif cmdNickname >= 0 && command == cmdNickname
      renamePokemon(selected)
    elsif cmdWithdraw >= 0 && command == cmdWithdraw
      (selected[0] == -1) ? pbStore(selected, @heldpkmn) : pbWithdraw(selected, @heldpkmn)
    elsif cmdItem >= 0 && command == cmdItem
      pbItem(selected, @heldpkmn)
    elsif cmdFuse >= 0 && command == cmdFuse
      pbFuseFromPC(selected, @heldpkmn)
    elsif cmdUnfuse >= 0 && command == cmdUnfuse
      pbUnfuseFromPC(selected)
    elsif cmdReverse >= 0 && command == cmdReverse
      reverseFromPC(selected)
    elsif cmdRelease >= 0 && command == cmdRelease
      pbRelease(selected, @heldpkmn)
    elsif cmdDebug >= 0 && command == cmdDebug
      pbPokemonDebug((@heldpkmn) ? @heldpkmn : pokemon, selected, heldpoke)
    end
  end

  def pbFuseFromPC(selected, heldpoke)
    @scene.pbSetCursorMode("default")
    box = selected[0]
    index = selected[1]
    poke_body = @storage[box, index]
    if heldpoke
      if heldpoke.isFusion?
        pbDisplay(_INTL("{1} is already fused!", heldpoke.name))
        return
      end
      blocking_message = CustomSpeciesFramework.fusion_block_message_for(heldpoke)
      if blocking_message
        pbDisplay(blocking_message)
        return
      end
      if heldpoke.egg?
        pbDisplay(_INTL("It's impossible to fuse an egg!"))
        return
      end
    end

    splicerItem = selectSplicer()
    if splicerItem.nil?
      cancelFusion()
      return
    end

    if !heldpoke
      @fusionMode = true
      @fusionItem = splicerItem
      @scene.setFusing(true, @fusionItem)
      pbHold(selected)
      pbDisplay(_INTL("Select a Pok\u00e9mon to fuse it with"))
      @scene.sprites["box"].disableFusions()
      return
    end

    if !poke_body
      pbDisplay(_INTL("Select a Pok\u00e9mon to fuse it with"))
      @fusionMode = true
      @fusionItem = splicerItem
      @scene.setFusing(true, @fusionItem)
      return
    end
  end

  def pbFusionCommands(selected)
    heldpoke = pbHeldPokemon
    pokemon = @storage[selected[0], selected[1]]

    if !pokemon
      command = pbShowCommands(_INTL("Select an action"), [_INTL("Continue fusing"), _INTL("Stop fusing")])
      cancelFusion if command == 1
      return
    end

    commands = [
      _INTL("Fuse"),
      _INTL("Swap"),
      _INTL("Stop fusing"),
      _INTL("Cancel")
    ]

    if !heldpoke
      pbPlace(selected)
      @fusionMode = false
      @scene.setFusing(false)
      return
    end

    command = pbShowCommands(_INTL("Select an action"), commands)
    case command
    when 0
      if pokemon.isFusion?
        pbDisplay(_INTL("This Pok\u00e9mon is already fused!"))
        return
      end
      if !CustomSpeciesFramework.can_fuse_pair?(pokemon, heldpoke)
        pbDisplay(CustomSpeciesFramework.fusion_pair_message(pokemon, heldpoke))
        return false
      end
      isSuperSplicer = isSuperSplicer?(@fusionItem)
      selectedHead = selectFusion(pokemon, heldpoke, isSuperSplicer)
      if selectedHead.nil?
        pbDisplay(_INTL("It won't have any effect."))
        return false
      end
      return false if selectedHead == -1

      selectedBase = selectedHead == pokemon ? heldpoke : pokemon
      firstOptionSelected = selectedBase == pokemon

      if Kernel.pbConfirmMessage(_INTL("Fuse the two Pok\u00e9mon?"))
        playingBGM = $game_system.getPlayingBGM
        return false if !pbFuse(selectedHead, selectedBase, @fusionItem)
        $PokemonBag.pbDeleteItem(@fusionItem) if canDeleteItem(@fusionItem)
        if firstOptionSelected
          deleteSelectedPokemon(heldpoke, selected)
        else
          deleteHeldPokemon(heldpoke, selected)
        end
        @scene.setFusing(false)
        @fusionMode = false
        @scene.sprites["box"].enableFusions()
        pbBGMPlay(playingBGM)
        return
      end
    when 1
      pbSwap(selected) if pokemon && !pokemon.isFusion?
    when 2
      cancelFusion
      return
    end
  end
end
