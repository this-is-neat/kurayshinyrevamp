#===============================================================================
#
#===============================================================================
class PokemonPauseMenu_Scene
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].visible = false
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["infowindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
    @sprites["helpwindow"].visible = false
    @infostate = false
    @helpstate = false
    pbSEPlay("GUI menu open")
  end

  def pbShowInfo(text)
    @sprites["infowindow"].resizeToFit(text, Graphics.height)
    @sprites["infowindow"].text = text
    @sprites["infowindow"].visible = true
    @infostate = true
  end

  def pbShowHelp(text)
    @sprites["helpwindow"].resizeToFit(text, Graphics.height)
    @sprites["helpwindow"].text = text
    @sprites["helpwindow"].visible = true
    pbBottomLeft(@sprites["helpwindow"])
    @helpstate = true
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible = true
    @sprites["infowindow"].visible = @infostate
    @sprites["helpwindow"].visible = @helpstate
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible = false
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"].visible = false
  end

  def pbShowCommands(commands)
    ret = -1
    cmdwindow = @sprites["cmdwindow"]
    cmdwindow.commands = commands
    cmdwindow.index = [($PokemonTemp.menuLastChoice || 0), commands.length - 1].min
    cmdwindow.resizeToFit(commands)
    cmdwindow.x = Graphics.width - cmdwindow.width
    cmdwindow.y = 0
    cmdwindow.visible = true
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      pbUpdateSceneMap
      if Input.trigger?(Input::BACK)
        ret = -1
        break
      elsif Input.trigger?(Input::USE)
        ret = cmdwindow.index
        $PokemonTemp.menuLastChoice = ret
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbRefresh; end
end

#===============================================================================
#
#===============================================================================
class PokemonPauseMenu
  LEGACY_QOL_BLOCKED_MAPS = [315, 316, 317, 318, 328, 343,
                             776, 777, 778, 779, 780, 781, 782, 783, 784,
                             722, 723, 724, 720,
                             304, 306, 307]
  LEGACY_KURAY_SHOP_BLOCKED_MAPS = [315, 316, 317, 318, 328, 341]

  def initialize(scene)
    @scene = scene
  end

  def with_menu_scene_restore(reapply: true)
    if defined?(OverworldZoom)
      OverworldZoom.with_temporary_restore(reapply: reapply) { yield }
    else
      yield
    end
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def legacy_qol_locked?
    LEGACY_QOL_BLOCKED_MAPS.include?($game_map.map_id) && !File.exist?("DemICE.krs")
  end

  def legacy_kuray_shop_locked?
    LEGACY_KURAY_SHOP_BLOCKED_MAPS.include?($game_map.map_id) && !File.exist?("DemICE.krs")
  end

  def open_legacy_pc
    if legacy_qol_locked?
      @scene.pbHideMenu
      pbMessage(_INTL("Can't use that here."))
      return
    end
    pbPlayDecisionSE
    $game_temp.fromkurayshop = 1
    with_menu_scene_restore do
      pbFadeOutIn {
        scene = PokemonStorageScene.new
        screen = PokemonStorageScreen.new(scene, $PokemonStorage)
        screen.pbStartScreen(0)
        $once = 0
      }
    end
    $game_temp.fromkurayshop = nil
    @scene.pbRefresh
  end

  def heal_legacy_party
    if legacy_qol_locked?
      @scene.pbHideMenu
      pbMessage(_INTL("Can't use that here."))
      return
    end
    $Trainer.heal_party
    pbMessage(_INTL("Pokemons healed!"))
    @scene.pbRefresh
  end

  def open_kuray_shop
    if legacy_kuray_shop_locked?
      @scene.pbHideMenu
      pbMessage(_INTL("Can't use that here."))
      return
    end
    pbPlayDecisionSE
    oldmart = $game_temp.mart_prices.clone
    $game_temp.fromkurayshop = 1
    begin
      $game_temp.mart_prices[303] = [10000, 5000]
      $game_temp.mart_prices[314] = [10000, 5000]
      $game_temp.mart_prices[329] = [10000, 5000]
      $game_temp.mart_prices[335] = [10000, 5000]
      $game_temp.mart_prices[343] = [10000, 5000]
      $game_temp.mart_prices[345] = [10000, 5000]
      $game_temp.mart_prices[346] = [10000, 5000]
      $game_temp.mart_prices[356] = [10000, 5000]
      $game_temp.mart_prices[358] = [10000, 5000]
      $game_temp.mart_prices[367] = [10000, 5000]
      $game_temp.mart_prices[618] = [30000, 15000]
      $game_temp.mart_prices[619] = [30000, 15000]
      $game_temp.mart_prices[646] = [30000, 15000]
      $game_temp.mart_prices[647] = [30000, 15000]
      $game_temp.mart_prices[648] = [30000, 15000]
      $game_temp.mart_prices[649] = [30000, 15000]
      $game_temp.mart_prices[650] = [30000, 15000]
      $game_temp.mart_prices[651] = [30000, 15000]
      $game_temp.mart_prices[652] = [30000, 15000]
      $game_temp.mart_prices[653] = [30000, 15000]
      $game_temp.mart_prices[654] = [30000, 15000]
      $game_temp.mart_prices[655] = [30000, 15000]
      $game_temp.mart_prices[656] = [30000, 15000]
      $game_temp.mart_prices[657] = [30000, 15000]
      $game_temp.mart_prices[570] = ($PokemonSystem.kuraystreamerdream != 0) ? [-1, 0] : [6900, 3450]
      if $PokemonSystem.kuraystreamerdream == 0
        $game_temp.mart_prices[568] = $game_switches[SWITCH_GOT_BADGE_8] ? [42000, 24000] : [999999, 24000]
        $game_temp.mart_prices[569] = [8200, 4100]
      else
        $game_temp.mart_prices[568] = [-1, 0]
        $game_temp.mart_prices[569] = [-1, 0]
      end
      $game_temp.mart_prices[245] = [1200, 600]
      $game_temp.mart_prices[247] = [4000, 2000]
      $game_temp.mart_prices[249] = [9100, 4550]
      $game_temp.mart_prices[246] = [3600, 1800]
      $game_temp.mart_prices[248] = [12000, 6000]
      $game_temp.mart_prices[250] = [29120, 14560]
      $game_temp.mart_prices[121] = [3000, 1500]
      $game_temp.mart_prices[122] = [3000, 1500]
      $game_temp.mart_prices[123] = [3000, 1500]
      $game_temp.mart_prices[124] = [3000, 1500]
      $game_temp.mart_prices[125] = [3000, 1500]
      $game_temp.mart_prices[126] = [3000, 1500]
      $game_temp.mart_prices[114] = [6000, 3000]
      $game_temp.mart_prices[115] = [6000, 3000]
      $game_temp.mart_prices[116] = [6000, 3000]
      $game_temp.mart_prices[100] = [6000, 3000]
      $game_temp.mart_prices[194] = [10000, 1000]
      if $PokemonSystem.kuraystreamerdream == 0
        $game_temp.mart_prices[235] = [10000, 0]
        $game_temp.mart_prices[263] = [10000, 0]
        $game_temp.mart_prices[264] = [960000, 0]
        $game_temp.mart_prices[3]   = [700, 350]
      else
        $game_temp.mart_prices[235] = [-1, 0]
        $game_temp.mart_prices[263] = [-1, 0]
        $game_temp.mart_prices[264] = [-1, 0]
        $game_temp.mart_prices[3]   = [-1, 0]
      end
      $game_temp.mart_prices[68] = [4000, 2000]
      $game_temp.mart_prices[623] = [1000, 500]

      for i in 2000..2032
        if $PokemonSystem.kuraystreamerdream == 0
          tmp_sellprice = ($KURAYEGGS_BASEPRICE[i - 2000] / 2.0).round
          $game_temp.mart_prices[i] = [$KURAYEGGS_BASEPRICE[i - 2000], tmp_sellprice]
        else
          $game_temp.mart_prices[i] = [-1, 0]
        end
      end

      allitems = [570, 569, 568, 245, 247, 249, 246, 248, 250,
                  121, 122, 123, 124, 125, 126,
                  303, 314, 329, 335, 343, 345, 346, 356, 358, 367,
                  618, 619, 646, 647, 648, 649, 650, 651, 652, 653, 654, 655, 656,
                  657, 659,
                  114, 115, 116, 100,
                  194,
                  235, 263, 264, 3,
                  68]
      allitems.push(623) if $PokemonSystem.rocketballsteal && $PokemonSystem.rocketballsteal > 0
      newitems = [2000, 2001, 2032, 2021, 2020,
                  2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010,
                  2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019,
                  2022]
      allitems.concat(newitems)
      allitems.push(2023) if $game_switches[SWITCH_GOT_BADGE_1]
      allitems.push(2024) if $game_switches[SWITCH_GOT_BADGE_2]
      allitems.push(2025) if $game_switches[SWITCH_GOT_BADGE_3]
      allitems.push(2026) if $game_switches[SWITCH_GOT_BADGE_4]
      allitems.push(2027) if $game_switches[SWITCH_GOT_BADGE_5]
      allitems.push(2028) if $game_switches[SWITCH_GOT_BADGE_6]
      allitems.push(2029) if $game_switches[SWITCH_GOT_BADGE_7]
      allitems.push(2030) if $game_switches[SWITCH_GOT_BADGE_8]
      allitems.push(2031) if $game_variables[VAR_STAT_NB_ELITE_FOUR] >= 1
      with_menu_scene_restore do
        pbFadeOutIn {
          scene = PokemonMart_Scene.new
          screen = PokemonMartScreen.new(scene, allitems)
          screen.pbBuyScreen
        }
      end
    ensure
      $game_temp.mart_prices = oldmart.clone
      $game_temp.fromkurayshop = nil
    end
    @scene.pbRefresh
  end

  def open_tutornet
    if LEGACY_KURAY_SHOP_BLOCKED_MAPS.include?($game_map.map_id)
      @scene.pbHideMenu
      pbMessage(_INTL("Can't use that here."))
      return
    end
    pbPlayDecisionSE
    with_menu_scene_restore do
      pbFadeOutIn {
        tmtutor_convert if defined?(tmtutor_convert)
        scene = PokemonTutorNet_Scene.new
        screen = PokemonTutorNetScreen.new(scene)
        screen.pbStartScreen
        @scene.pbRefresh
      }
    end
  end

  def open_multiplayer_menu
    pbPlayDecisionSE
    @scene.pbHideMenu
    with_menu_scene_restore { MultiplayerUI.openMultiplayerMenu }
    pbUpdateSceneMap
    @scene.pbRefresh
  end

  def open_mod_manager
    pbPlayDecisionSE
    @scene.pbHideMenu
    with_menu_scene_restore do
      scene = ModManager::Scene_Installed.new
      scene.main
    end
    pbUpdateSceneMap
    @scene.pbRefresh
  end

  def pbStartPokemonMenu
    if !$Trainer
      if $DEBUG
        pbMessage(_INTL("The player trainer was not defined, so the pause menu can't be displayed."))
        pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
      end
      return
    end
    @scene.pbStartScene
    endscene = true
    commands = []
    cmdPokedex = -1
    cmdPokemon = -1
    cmdBag = -1
    cmdPC = -1
    cmdKurayHeal = -1
    cmdKurayShop = -1
    cmdTutorNet = -1
    cmdTrainer = -1
    cmdOutfit = -1
    cmdSave = -1
    cmdPokegear = -1
    cmdOption = -1
    cmdMultiplayer = -1
    cmdModManager = -1
    cmdDebug = -1
    cmdQuit = -1
    cmdEndGame = -1
    if $Trainer.has_pokedex && $Trainer.pokedex.accessible_dexes.length > 0
      commands[cmdPokedex = commands.length] = _INTL("Pokédex")
    end
    commands[cmdPokemon = commands.length] = _INTL("Pokémon") if $Trainer.party_count > 0
    commands[cmdBag = commands.length] = _INTL("Bag") if !pbInBugContest?
    if $PokemonSystem.respond_to?(:kurayqol) && $PokemonSystem.kurayqol == 1
      commands[cmdPC = commands.length] = _INTL("PC")
      commands[cmdKurayHeal = commands.length] = _INTL("Heal Pokémon")
      commands[cmdKurayShop = commands.length] = _INTL("Kuray Shop") if !pbInBugContest?
    end
    if !pbInBugContest? && $PokemonSystem.respond_to?(:tutornet) && $PokemonSystem.tutornet == 1 &&
       defined?(PokemonTutorNet_Scene) && defined?(PokemonTutorNetScreen)
      commands[cmdTutorNet = commands.length] = _INTL("Tutor.net")
    end
    commands[cmdPokegear = commands.length] = _INTL("Pokégear") if $Trainer.has_pokegear
    commands[cmdTrainer = commands.length] = $Trainer.name
    commands[cmdOutfit = commands.length] = _INTL("Outfit") if $Trainer.can_change_outfit
    if pbInSafari?
      if Settings::SAFARI_STEPS <= 0
        @scene.pbShowInfo(_INTL("Balls: {1}", pbSafariState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Steps: {1}/{2}\nBalls: {3}",
                                pbSafariState.steps, Settings::SAFARI_STEPS, pbSafariState.ballcount))
      end
      commands[cmdQuit = commands.length] = _INTL("Quit")
    elsif pbInBugContest?
      if pbBugContestState.lastPokemon
        @scene.pbShowInfo(_INTL("Caught: {1}\nLevel: {2}\nBalls: {3}",
                                pbBugContestState.lastPokemon.speciesName,
                                pbBugContestState.lastPokemon.level,
                                pbBugContestState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Caught: None\nBalls: {1}", pbBugContestState.ballcount))
      end
      commands[cmdQuit = commands.length] = _INTL("Quit Contest")
    else
      commands[cmdSave = commands.length] = _INTL("Save") if $game_system && !$game_system.save_disabled
    end
    commands[cmdMultiplayer = commands.length] = _INTL("Multiplayer") if defined?(MultiplayerUI)
    commands[cmdOption = commands.length] = _INTL("Options")
    commands[cmdModManager = commands.length] = _INTL("Mod Manager") if defined?(ModManager::Scene_Installed)
    commands[cmdDebug = commands.length] = _INTL("Debug") if $DEBUG
    commands[cmdEndGame = commands.length] = _INTL("Title screen")
    loop do
      command = @scene.pbShowCommands(commands)
      if cmdPokedex >= 0 && command == cmdPokedex
        pbPlayDecisionSE
        if Settings::USE_CURRENT_REGION_DEX
          with_menu_scene_restore do
            pbFadeOutIn {
              scene = PokemonPokedex_Scene.new
              screen = PokemonPokedexScreen.new(scene)
              screen.pbStartScreen
              @scene.pbRefresh
            }
          end
        else
          $PokemonGlobal.pokedexDex = $Trainer.pokedex.accessible_dexes[0]
          with_menu_scene_restore do
            pbFadeOutIn {
              scene = PokemonPokedexMenu_Scene.new
              screen = PokemonPokedexMenuScreen.new(scene)
              screen.pbStartScreen
              @scene.pbRefresh
            }
          end
        end
      elsif cmdPokemon >= 0 && command == cmdPokemon
        pbPlayDecisionSE
        hiddenmove = nil
        with_menu_scene_restore do
          pbFadeOutIn {
            sscene = PokemonParty_Scene.new
            sscreen = PokemonPartyScreen.new(sscene, $Trainer.party)
            hiddenmove = sscreen.pbPokemonScreen
            (hiddenmove) ? @scene.pbEndScene : @scene.pbRefresh
          }
        end
        if hiddenmove
          $game_temp.in_menu = false
          pbUseHiddenMove(hiddenmove[0], hiddenmove[1])
          return
        end
      elsif cmdBag >= 0 && command == cmdBag
        pbPlayDecisionSE
        item = nil
        with_menu_scene_restore do
          pbFadeOutIn {
            scene = PokemonBag_Scene.new
            screen = PokemonBagScreen.new(scene, $PokemonBag)
            item = screen.pbStartScreen
            (item) ? @scene.pbEndScene : @scene.pbRefresh
          }
        end
        if item
          $game_temp.in_menu = false
          pbUseKeyItemInField(item)
          return
        end
      elsif cmdPC >= 0 && command == cmdPC
        open_legacy_pc
      elsif cmdKurayHeal >= 0 && command == cmdKurayHeal
        heal_legacy_party
      elsif cmdKurayShop >= 0 && command == cmdKurayShop
        open_kuray_shop
      elsif cmdTutorNet >= 0 && command == cmdTutorNet
        open_tutornet
      elsif cmdPokegear >= 0 && command == cmdPokegear
        pbPlayDecisionSE
        with_menu_scene_restore do
          pbFadeOutIn {
            scene = PokemonPokegear_Scene.new
            screen = PokemonPokegearScreen.new(scene)
            screen.pbStartScreen
            @scene.pbRefresh
          }
        end
      elsif cmdTrainer >= 0 && command == cmdTrainer
        pbPlayDecisionSE
        with_menu_scene_restore do
          pbFadeOutIn {
            scene = PokemonTrainerCard_Scene.new
            screen = PokemonTrainerCardScreen.new(scene)
            screen.pbStartScreen
            @scene.pbRefresh
          }
        end
      elsif cmdOutfit >= 0 && command == cmdOutfit
        @scene.pbHideMenu
        pbCommonEvent(COMMON_EVENT_OUTFIT)
      elsif cmdQuit >= 0 && command == cmdQuit
        @scene.pbHideMenu
        if pbInSafari?
          if pbConfirmMessage(_INTL("Would you like to leave the Safari Game right now?"))
            @scene.pbEndScene
            pbSafariState.decision = 1
            pbSafariState.pbGoToStart
            return
          else
            pbShowMenu
          end
        else
          if pbConfirmMessage(_INTL("Would you like to end the Contest now?"))
            @scene.pbEndScene
            pbBugContestState.pbStartJudging
            return
          else
            pbShowMenu
          end
        end
      elsif cmdSave >= 0 && command == cmdSave
        @scene.pbHideMenu
        saved = false
        with_menu_scene_restore do
          scene = PokemonSave_Scene.new
          screen = PokemonSaveScreen.new(scene)
          saved = screen.pbSaveScreen
        end
        if saved
          @scene.pbEndScene
          endscene = false
          break
        else
          pbShowMenu
        end
      elsif cmdMultiplayer >= 0 && command == cmdMultiplayer
        open_multiplayer_menu
      elsif cmdOption >= 0 && command == cmdOption
        pbPlayDecisionSE
        with_menu_scene_restore do
          pbFadeOutIn {
            scene = PokemonOption_Scene.new
            screen = PokemonOptionScreen.new(scene)
            screen.pbStartScreen
            pbUpdateSceneMap
            @scene.pbRefresh
          }
        end
      elsif cmdModManager >= 0 && command == cmdModManager
        open_mod_manager
      elsif cmdDebug >= 0 && command == cmdDebug
        pbPlayDecisionSE
        with_menu_scene_restore do
          pbFadeOutIn {
            pbDebugMenu
            @scene.pbRefresh
          }
        end
      elsif cmdEndGame >= 0 && command == cmdEndGame
        @scene.pbHideMenu
        if pbConfirmMessage(_INTL("Are you sure you want to quit the game and return to the main menu?"))
          with_menu_scene_restore(reapply: false) do
            scene = PokemonSave_Scene.new
            screen = PokemonSaveScreen.new(scene)
            screen.pbSaveScreen
          end
          $game_temp.to_title = true
          return
        else
          pbShowMenu
        end
      else
        pbPlayCloseMenuSE
        break
      end
    end
    @scene.pbEndScene if endscene
  end
end
