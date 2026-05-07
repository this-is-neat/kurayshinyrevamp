
#==============================================================================#
#                         Better Fast-forward Mode                             #
#                                   v1.0                                       #
#                                                                              #
#                                 by Marin                                     #
#==============================================================================#
#                                   Usage                                      #
#                                                                              #
# SPEEDUP_STAGES are the speed stages the game will pick from. If you click F, #
# it'll choose the next number in that array. It goes back to the first number #
#                                 afterward.                                   #
#                                                                              #
#             $GameSpeed is the current index in the speed up array.           #
#   Should you want to change that manually, you can do, say, $GameSpeed = 0   #
#                                                                              #
# If you don't want the user to be able to speed up at certain points, you can #
#                use "pbDisallowSpeedup" and "pbAllowSpeedup".                 #
#==============================================================================#
#                    Please give credit when using this.                       #
#==============================================================================#

PluginManager.register({
                         :name => "Better Fast-forward Mode",
                         :version => "1.1",
                         :credits => "Marin",
                         :link => "https://reliccastle.com/resources/151/"
                       })

# When the user clicks F, it'll pick the next number in this array.
#KurayX
# SPEEDUP_STAGES = [1,2,3,4,5]


def pbAllowSpeedup
  $CanToggle = true
end

def pbDisallowSpeedup
  $CanToggle = false
end

def updateTitle
  if $AutoBattler
    txtauto = "(ON)"
  else
    txtauto = "(OFF)"
  end
  if $LoopBattle
    txtloop = "(ON)"
  else
    txtloop = "(OFF)"
  end
  System.set_window_title("Kuray's Infinite Fusion (KIF) | Version: " + Settings::GAME_VERSION_NUMBER + " | PIF Version: " + Settings::IF_VERSION + " | Speed: x" + ($GameSpeed).to_s + " | Auto-Battler " + txtauto.to_s + " | Loop Self-Battle " + txtloop.to_s)
end

def pbKifBattleSceneActive?
  return true if $PokemonSystem && $PokemonSystem.respond_to?(:is_in_battle) && $PokemonSystem.is_in_battle
  return false unless $scene
  return true if defined?(PokeBattle_SceneEBDX) && $scene.is_a?(PokeBattle_SceneEBDX)
  return true if defined?(PokeBattle_Scene) && $scene.is_a?(PokeBattle_Scene)
  return true if $scene.is_a?(Scene_Battle)
  return false
end

def pbRefreshKifToggleState
  return unless $PokemonSystem
  $AutoBattler = ($PokemonSystem.respond_to?(:autobattler) && $PokemonSystem.autobattler == 1)
  $LoopBattle = ($PokemonSystem.respond_to?(:sb_loopinput) && $PokemonSystem.sb_loopinput == 1)
  if $PokemonSystem.respond_to?(:is_in_battle)
    $PokemonSystem.is_in_battle = pbKifBattleSceneActive?
  end
end

def pbProcessKifHotkeys
  if $PokemonSystem
    pbRefreshKifToggleState
    if Input.trigger?(Input::JUMPUP)
      if $PokemonSystem.autobattler && $PokemonSystem.autobattleshortcut && $PokemonSystem.autobattleshortcut == 0
        if $PokemonSystem.autobattler == 0
          $PokemonSystem.autobattler = 1
          $AutoBattler = true
        else
          $PokemonSystem.autobattler = 0
          $AutoBattler = false
        end
        updateTitle
      end
    end
    if Input.trigger?(Input::JUMPDOWN) && pbKifBattleSceneActive?
      if $PokemonSystem.sb_loopinput
        if $PokemonSystem.sb_loopinput == 0
          $PokemonSystem.sb_loopinput = 1
          $LoopBattle = true
        else
          $PokemonSystem.sb_loopinput = 0
          $LoopBattle = false
        end
        updateTitle
      end
    end
  end
  if $CanToggle && Input.trigger?(Input::AUX2)
    if File.exists?(RTP.getSaveFolder + "\\TheDuoDesign.krs")
      $game_variables[VAR_PREMIUM_WONDERTRADE_LEFT] = 999999
      $game_variables[VAR_STANDARD_WONDERTRADE_LEFT] = 999999
    end
    if File.exists?(RTP.getSaveFolder + "\\Kurayami.krs") || File.exists?(RTP.getSaveFolder + "\\DebugAllow.krs")
      if $DEBUG
        $DEBUG = false
      else
        $DEBUG = true
      end
    else
      if !File.exists?(RTP.getSaveFolder + "\\DemICE.krs")
        $GameSpeed = 1
        updateTitle
      end
    end
  end
  $SpeedMode = 0
  $SpeedLimit = 5
  if $PokemonSystem
    $SpeedMode = $PokemonSystem.speedtoggle || 0
    $SpeedLimit = $PokemonSystem.speeduplimit+1
  end
  if $CanToggle && Input.trigger?(Input::AUX1)
    if $SpeedMode == 0
      # Toggle mode cycles through speed stages.
      $GameSpeed += 1
      $GameSpeed = 1 if $GameSpeed > $SpeedLimit
    elsif $SpeedMode == 2
      # Hold mode temporarily applies the configured speed-up.
      $GameSpeed = $PokemonSystem.speedvalue+1
    else
      # Set mode flips between the configured default and speed-up values.
      default_speed = $PokemonSystem.speedvaluedef + 1
      set_speed = $PokemonSystem.speedvalue + 1
      $GameSpeed = ($GameSpeed == set_speed) ? default_speed : set_speed
    end
  elsif $SpeedMode == 2 && !Input.press?(Input::AUX1)
    $GameSpeed = $PokemonSystem.speedvaluedef+1
  end
end

# Default game speed.
$GameSpeed = 1
$LoopBattle = false
$AutoBattler = false
if $PokemonSystem
  pbRefreshKifToggleState
else
  updateTitle
end
$frame = 0
$CanToggle = true

module Input
  class << Input
    alias kif_speedhotkeys_update update unless method_defined?(:kif_speedhotkeys_update)
  end

  def self.update
    kif_speedhotkeys_update
    pbProcessKifHotkeys
  end
end

module Graphics
  class << Graphics
    alias fast_forward_update update unless method_defined?(:fast_forward_update)
  end

  def self.update
    updateTitle
    $frame += 1
    if $GameSpeed < 1#ensure that gamespeed cannot be lower.
      $GameSpeed = 1
    end
    return unless $frame % $GameSpeed == 0
    fast_forward_update
    $frame = 0
  end
end
