module Settings
    ALLOW_DIAGONAL_MOVEMENT = true
    CHANGE_DIAGONAL_MOVEMENT_IN_OPTIONS = true
  end
  
  class Game_Player < Game_Character
    def allow_diagonal_movement
      diag_setting = $PokemonSystem.diagmovement
      return Settings::ALLOW_DIAGONAL_MOVEMENT && (diag_setting == 0 || diag_setting.nil?)
    end
  
    alias allow_diag_movement_update_com update_command_new
    def update_command_new
      return update_command_new_8_diag if allow_diagonal_movement
      allow_diag_movement_update_com
    end
  
    def update_command_new_8_diag
      dir = Input.dir8
      if $PokemonGlobal.forced_movement?
        move_forward
      elsif !pbMapInterpreterRunning? && !$game_temp.message_window_showing &&
            !$game_temp.in_mini_update && !$game_temp.in_menu
        if @moved_last_frame || (dir > 0 && dir == @lastdir && System.uptime - @lastdirframe >= 0.075)
          case dir
          when 1 then move_lower_left
          when 2 then move_down
          when 3 then move_lower_right
          when 4 then move_left
          when 6 then move_right
          when 7 then move_upper_left
          when 8 then move_up
          when 9 then move_upper_right
          end
        elsif dir != @lastdir
          case dir
          when 1 then move_lower_left
          when 2 then turn_down
          when 3 then move_lower_right
          when 4 then turn_left
          when 6 then turn_right
          when 7 then move_upper_left
          when 8 then turn_up
          when 9 then move_upper_right
          end
        end
        @lastdirframe = System.uptime if dir != @lastdir
        @lastdir = dir
      end
    end

    # Route diagonal movement through the same player-side encounter/dependent
    # event safeguards used by cardinal movement.
    def move_diagonal_guarded(method_name)
      return if $PokemonTemp.encounterTriggered
      old_x = @x
      old_y = @y
      send(method_name)
      if !($PokemonTemp.encounterTriggered) && (@x != old_x || @y != old_y)
        $PokemonTemp.dependentEvents.pbMoveDependentEvents
      end
      $PokemonTemp.encounterTriggered = false
    end

    alias mod_diag_move_lower_left move_lower_left
    def move_lower_left
      move_diagonal_guarded(:mod_diag_move_lower_left)
    end

    alias mod_diag_move_lower_right move_lower_right
    def move_lower_right
      move_diagonal_guarded(:mod_diag_move_lower_right)
    end

    alias mod_diag_move_upper_left move_upper_left
    def move_upper_left
      move_diagonal_guarded(:mod_diag_move_upper_left)
    end

    alias mod_diag_move_upper_right move_upper_right
    def move_upper_right
      move_diagonal_guarded(:mod_diag_move_upper_right)
    end
  end
  
  class PokemonGlobalMetadata
    def forced_movement?
      @forced_movement ||= false
    end
  
    def forced_movement=(value)
      @forced_movement = value
    end
  end
  
  class Game_Temp
    attr_accessor :in_mini_update, :common_event_id
  
    alias mod_initialize initialize
    def initialize
      mod_initialize
      @in_mini_update = false
      @common_event_id ||= 0
    end
  end
  
  class Interpreter
    alias mod_setup_starting_event setup_starting_event
    def setup_starting_event
      if $game_temp.common_event_id && $game_temp.common_event_id > 0
        setup($data_common_events[$game_temp.common_event_id].list, 0)
        $game_temp.common_event_id = 0
        return
      end
      mod_setup_starting_event
    end
  end
  
  class PokemonSystem
    attr_accessor :diagmovement unless method_defined?(:diagmovement)
  end
  
  $PokemonSystem ||= PokemonSystem.new
  $PokemonSystem.diagmovement = 0 if $PokemonSystem.diagmovement.nil?
  
  class PokemonOption_Scene
    alias diagmovement_original_pbGetOptions pbGetOptions
    def pbGetOptions(inloadscreen = false)
      options = diagmovement_original_pbGetOptions(inloadscreen)
      if Settings::CHANGE_DIAGONAL_MOVEMENT_IN_OPTIONS
        options << EnumOption.new(
          _INTL("Diagonal Movement"),
          [_INTL("On"), _INTL("Off")],
          proc { $PokemonSystem.diagmovement },
          proc { |value| $PokemonSystem.diagmovement = value },
          "Enable or disable diagonal movement."
        )
      end
      options
    end
  end