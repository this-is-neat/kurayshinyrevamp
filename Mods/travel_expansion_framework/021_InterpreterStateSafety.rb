class Interpreter
  alias tef_interpreter_state_safety_execute_command execute_command unless method_defined?(:tef_interpreter_state_safety_execute_command)
  alias tef_interpreter_state_safety_command_111 command_111 unless method_defined?(:tef_interpreter_state_safety_command_111)
  alias tef_interpreter_state_safety_command_411 command_411 unless method_defined?(:tef_interpreter_state_safety_command_411)
  alias tef_interpreter_state_safety_command_if command_if unless method_defined?(:tef_interpreter_state_safety_command_if)

  def tef_interpreter_state_safety_repair_branch!
    return if @branch.is_a?(Hash)
    previous = @branch.class.to_s rescue "unknown"
    @branch = {}
    if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:log)
      TravelExpansionFramework.log("[interpreter] repaired missing branch state before command on map #{@map_id}, event #{@event_id}, index #{@index} (was #{previous})")
    end
  rescue
    @branch = {}
  end

  def tef_interpreter_state_safety_log(message)
    if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:log)
      TravelExpansionFramework.log(message)
    end
  rescue
  end

  def tef_interpreter_state_safety_current_command
    return nil if !@list.respond_to?(:[])
    return nil if @index.nil?
    return @list[@index]
  rescue
    return nil
  end

  def tef_interpreter_state_safety_current_indent
    command = tef_interpreter_state_safety_current_command
    return 0 if command.nil? || !command.respond_to?(:indent)
    return command.indent
  rescue
    return 0
  end

  def tef_interpreter_state_safety_still_on_command?(indent, expected_list = nil, expected_index = nil, expected_command = nil)
    return false if !expected_list.nil? && @list != expected_list
    return false if !expected_index.nil? && @index != expected_index
    command = tef_interpreter_state_safety_current_command
    return false if command.nil?
    return false if !expected_command.nil? && command != expected_command
    return command.respond_to?(:indent) && command.indent == indent
  rescue
    return false
  end

  def execute_command
    tef_interpreter_state_safety_repair_branch!
    return false if !@list.respond_to?(:size) || @index.nil?
    return tef_interpreter_state_safety_execute_command
  rescue NoMethodError
    bt = $!.backtrace.join("\n") rescue ""
    if bt[/004_Interpreter_Commands\.rb:(355|366)/]
      tef_interpreter_state_safety_log("[interpreter] stopped command after nil branch/list state on map #{@map_id}, event #{@event_id}, index #{@index}")
      return false
    end
    raise
  end

  def command_111
    tef_interpreter_state_safety_repair_branch!
    indent = tef_interpreter_state_safety_current_indent
    starting_list = @list
    starting_index = @index
    params = @parameters
    current_command = tef_interpreter_state_safety_current_command
    params = current_command.parameters if (params.nil? || !params.respond_to?(:[])) &&
                                           current_command &&
                                           current_command.respond_to?(:parameters)
    return false if params.nil? || !params.respond_to?(:[])

    result = false
    case params[0]
    when 0   # switch
      switch_name = nil
      if defined?(TravelExpansionFramework)
        expansion_id = @tef_expansion_id
        expansion_id = TravelExpansionFramework.current_runtime_expansion_id if (expansion_id.nil? || expansion_id.empty?) &&
                                                                                TravelExpansionFramework.respond_to?(:current_runtime_expansion_id)
        if !expansion_id.nil? && !expansion_id.empty? && TravelExpansionFramework.respond_to?(:switch_name_for)
          switch_name = TravelExpansionFramework.switch_name_for(expansion_id, params[1])
        end
      end
      switch_name = $data_system.switches[params[1]] if switch_name.nil? &&
                                                        defined?($data_system) &&
                                                        $data_system &&
                                                        $data_system.respond_to?(:switches) &&
                                                        $data_system.switches
      if switch_name && switch_name[/^s\:/]
        result = (eval($~.post_match) == (params[2] == 0))
      else
        result = ($game_switches[params[1]] == (params[2] == 0))
      end
    when 1   # variable
      value1 = $game_variables[params[1]]
      value2 = (params[2] == 0) ? params[3] : $game_variables[params[3]]
      case params[4]
      when 0 then result = (value1 == value2)
      when 1 then result = (value1 >= value2)
      when 2 then result = (value1 <= value2)
      when 3 then result = (value1 > value2)
      when 4 then result = (value1 < value2)
      when 5 then result = (value1 != value2)
      end
    when 2   # self switch
      if @event_id && @event_id > 0
        key = [$game_map.map_id, @event_id, params[1]]
        result = ($game_self_switches[key] == (params[2] == 0))
      end
    when 3   # timer
      if $game_system.timer_working
        sec = $game_system.timer / Graphics.frame_rate
        result = (params[2] == 0) ? (sec >= params[1]) : (sec <= params[1])
      end
    when 6   # character
      character = get_character(params[1])
      result = (character.direction == params[2]) if character
    when 7   # gold
      gold = $Trainer.money
      result = (params[2] == 0) ? (gold >= params[1]) : (gold <= params[1])
    when 11   # button
      result = Input.press?(params[1])
    when 12   # script
      result = execute_script(params[1])
    end

    if !tef_interpreter_state_safety_still_on_command?(indent, starting_list, starting_index, current_command)
      tef_interpreter_state_safety_log("[interpreter] conditional branch command list changed during evaluation on map #{@map_id}, event #{@event_id}, index #{@index}; stopping safely")
      return false
    end

    @branch[indent] = result
    if @branch[indent]
      @branch.delete(indent)
      return true
    end
    return command_skip
  end

  def command_411
    tef_interpreter_state_safety_repair_branch!
    indent = tef_interpreter_state_safety_current_indent
    return false if !tef_interpreter_state_safety_still_on_command?(indent)
    if @branch[indent] == false
      @branch.delete(indent)
      return true
    end
    return command_skip
  end

  def command_if(value)
    tef_interpreter_state_safety_repair_branch!
    indent = tef_interpreter_state_safety_current_indent
    return false if !tef_interpreter_state_safety_still_on_command?(indent)
    if @branch[indent] == value
      @branch.delete(indent)
      return true
    end
    return command_skip
  end
end

TravelExpansionFramework.log("021_InterpreterStateSafety loaded from #{__FILE__}") if defined?(TravelExpansionFramework) &&
                                                                                       TravelExpansionFramework.respond_to?(:log)
