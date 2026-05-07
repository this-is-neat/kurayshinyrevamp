module TravelExpansionFramework
  module_function

  def runtime_context_stack
    @runtime_context_stack ||= []
    return @runtime_context_stack
  end

  def runtime_data_cache
    @runtime_data_cache ||= {}
    return @runtime_data_cache
  end

  def current_runtime_context
    return runtime_context_stack.last
  end

  def current_runtime_expansion_id
    context = current_runtime_context
    return nil if !context.is_a?(Hash)
    expansion_id = context[:expansion_id].to_s
    return nil if expansion_id.empty?
    return expansion_id
  end

  def with_runtime_context(expansion_id, extra = nil)
    expansion = expansion_id.to_s
    return yield if expansion.empty?
    context = {}
    parent = current_runtime_context
    if parent.is_a?(Hash)
      parent.each_pair { |key, value| context[key] = value }
    end
    context[:expansion_id] = expansion
    if extra.is_a?(Hash)
      extra.each_pair { |key, value| context[key.to_sym] = value }
    end
    runtime_context_stack << context
    result = yield
    return result
  ensure
    runtime_context_stack.pop if runtime_context_stack.length > 0
  end

  def expansion_runtime_store(expansion_id, key)
    state = state_for(expansion_id)
    state.metadata ||= {}
    state.metadata["runtime_state"] ||= {}
    state.metadata["runtime_state"][key.to_s] ||= {}
    return state.metadata["runtime_state"][key.to_s]
  end

  def expansion_switch_value(expansion_id, switch_id)
    identifier = integer(switch_id, 0)
    return false if identifier <= 0
    store = expansion_runtime_store(expansion_id, :switches)
    return store[identifier] == true
  end

  def set_expansion_switch_value(expansion_id, switch_id, value)
    identifier = integer(switch_id, 0)
    return false if identifier <= 0
    store = expansion_runtime_store(expansion_id, :switches)
    new_value = value ? true : false
    changed = (store[identifier] != new_value)
    store[identifier] = new_value
    return changed
  end

  def expansion_variable_value(expansion_id, variable_id)
    identifier = integer(variable_id, 0)
    return 0 if identifier <= 0
    store = expansion_runtime_store(expansion_id, :variables)
    return store[identifier] if store.has_key?(identifier)
    return 0
  end

  def set_expansion_variable_value(expansion_id, variable_id, value)
    identifier = integer(variable_id, 0)
    return false if identifier <= 0
    store = expansion_runtime_store(expansion_id, :variables)
    changed = (!store.has_key?(identifier) || store[identifier] != value)
    store[identifier] = value
    return changed
  end

  def expansion_data_root(expansion_id)
    info = external_projects[expansion_id.to_s]
    data_root = info[:data_root].to_s if info.is_a?(Hash)
    return data_root if !data_root.to_s.empty?
    manifest = manifest_for(expansion_id)
    return nil if !manifest
    sample_path = manifest_map_source_path(manifest, 1)
    if !sample_path.to_s.empty?
      return File.dirname(sample_path)
    end
    first_map = manifest[:map_files].is_a?(Array) ? manifest[:map_files].first : nil
    return File.dirname(first_map[:path]) if first_map && first_map[:path]
    return nil
  end

  def expansion_data_path(expansion_id, filename)
    root = expansion_data_root(expansion_id)
    return nil if root.to_s.empty?
    return runtime_path_join(root, filename)
  end

  def load_expansion_data_file(expansion_id, cache_key, filename)
    expansion = expansion_id.to_s
    return nil if expansion.empty?
    cache = runtime_data_cache[expansion] ||= {}
    return cache[cache_key] if cache.has_key?(cache_key)
    path = expansion_data_path(expansion, filename)
    if path.to_s.empty? || !runtime_file_exists?(path)
      cache[cache_key] = nil
      return nil
    end
    cache[cache_key] = load_marshaled_runtime(path)
    return cache[cache_key]
  rescue => e
    log("Compatibility data load failed for #{expansion} #{filename}: #{e.message}")
    cache[cache_key] = nil if cache
    return nil
  end

  def expansion_system_data(expansion_id)
    return load_expansion_data_file(expansion_id, :system, "System.rxdata")
  end

  def expansion_common_events(expansion_id)
    return load_expansion_data_file(expansion_id, :common_events, "CommonEvents.rxdata")
  end

  def expansion_tilesets(expansion_id)
    return load_expansion_data_file(expansion_id, :tilesets, "Tilesets.rxdata")
  end

  def expansion_map_infos(expansion_id)
    return load_expansion_data_file(expansion_id, :map_infos, "MapInfos.rxdata")
  end

  def expansion_tileset_for_map(map_id, map_data = nil)
    expansion_id = current_map_expansion_id(map_id)
    return nil if expansion_id.nil? || expansion_id.empty?
    map = map_data || load_map_data(map_id)
    return nil if !map || !map.respond_to?(:tileset_id)
    tilesets = expansion_tilesets(expansion_id)
    return nil if !tilesets.respond_to?(:[])
    return tilesets[integer(map.tileset_id, 0)]
  rescue => e
    log("External tileset resolution failed for map #{map_id}: #{e.message}")
    return nil
  end

  def expansion_map_display_name(map_id)
    expansion_id = current_map_expansion_id(map_id)
    return nil if expansion_id.nil? || expansion_id.empty?
    map_infos = expansion_map_infos(expansion_id)
    return nil if !map_infos.respond_to?(:[])
    local_id = local_map_id_for(expansion_id, map_id)
    return nil if local_id <= 0
    map_info = map_infos[local_id]
    return nil if !map_info
    return map_info.name if map_info.respond_to?(:name)
    return map_info[:name] if map_info.is_a?(Hash)
    return nil
  rescue => e
    log("External map name resolution failed for map #{map_id}: #{e.message}")
    return nil
  end

  def switch_name_for(expansion_id, switch_id)
    expansion = expansion_id.to_s
    identifier = integer(switch_id, 0)
    if !expansion.empty? && identifier > 0
      system_data = expansion_system_data(expansion)
      if system_data && system_data.respond_to?(:switches)
        begin
          name = system_data.switches[identifier]
          return name if !name.nil?
        rescue
        end
      end
    end
    return $data_system.switches[identifier] if defined?($data_system) && $data_system && $data_system.respond_to?(:switches)
    return nil
  rescue
    return nil
  end

  def expansion_switch_active?(expansion_id, switch_id)
    result = with_runtime_context(expansion_id) { expansion_switch_value(expansion_id, switch_id) }
    return result ? true : false
  end

  def expansion_virtual_map_id(expansion_id, local_map_id)
    manifest = manifest_for(expansion_id)
    return nil if !manifest
    local_id = integer(local_map_id, 0)
    return nil if local_id <= 0
    virtual_id = integer(manifest[:map_block][:start], 0) + local_id
    return virtual_id if current_map_expansion_id(virtual_id).to_s == expansion_id.to_s
    return virtual_id if !expansion_map_entry(virtual_id).nil?
    return nil
  end

  def local_map_id_for(expansion_id, map_id)
    manifest = manifest_for(expansion_id)
    return integer(map_id, 0) if !manifest
    target = integer(map_id, 0)
    start_id = integer(manifest[:map_block][:start], 0)
    size = integer(manifest[:map_block][:size], 0)
    return target if target <= 0 || start_id <= 0 || size <= 0
    return target if target < start_id || target >= start_id + size
    return target - start_id
  end

  def translate_expansion_map_id(expansion_id, map_id)
    expansion = expansion_id.to_s
    return integer(map_id, 0) if expansion.empty?
    target = integer(map_id, 0)
    return target if target <= 0
    return target if current_map_expansion_id(target).to_s == expansion
    translated = expansion_virtual_map_id(expansion, target)
    return translated || target
  end

  def find_expansion_common_event(expansion_id, common_event_id)
    common_events = expansion_common_events(expansion_id)
    return nil if common_events.nil?
    identifier = integer(common_event_id, 0)
    return nil if identifier <= 0
    return common_events[identifier] if common_events.respond_to?(:[])
    return nil
  rescue
    return nil
  end

  def install_external_common_events_for(game_map)
    return if !game_map
    expansion_id = current_map_expansion_id(game_map.map_id)
    return if expansion_id.nil? || expansion_id.to_s.empty?
    common_events = expansion_common_events(expansion_id)
    return if !common_events.respond_to?(:each_with_index)
    current = game_map.instance_variable_get(:@common_events)
    current = {} if !current.is_a?(Hash)
    common_events.each_with_index do |common_event, index|
      next if index <= 0 || !common_event
      key = "tef:#{expansion_id}:#{index}"
      current[key] = ExternalCommonEventRunner.new(expansion_id, index)
    end
    game_map.instance_variable_set(:@common_events, current)
  end

  class ExternalCommonEventRunner
    def initialize(expansion_id, common_event_id)
      @expansion_id = expansion_id.to_s
      @common_event_id = common_event_id
      @interpreter = nil
      refresh
    end

    def common_event
      return TravelExpansionFramework.find_expansion_common_event(@expansion_id, @common_event_id)
    end

    def name
      event = common_event
      return event.name if event && event.respond_to?(:name)
      return "Common Event #{@common_event_id}"
    end

    def trigger
      event = common_event
      return event.trigger if event && event.respond_to?(:trigger)
      return 0
    end

    def switch_id
      event = common_event
      return event.switch_id if event && event.respond_to?(:switch_id)
      return 0
    end

    def list
      event = common_event
      return event.list if event && event.respond_to?(:list)
      return nil
    end

    def switchIsOn?(id)
      switch_name = TravelExpansionFramework.switch_name_for(@expansion_id, id)
      return false if !switch_name
      if switch_name[/^s\:/]
        return eval($~.post_match)
      end
      result = TravelExpansionFramework.with_runtime_context(@expansion_id) { $game_switches[id] }
      return result ? true : false
    end

    def refresh
      if self.trigger == 2 && switchIsOn?(self.switch_id)
        @interpreter ||= Interpreter.new
      else
        @interpreter = nil
      end
    end

    def update
      return if @interpreter.nil?
      if !@interpreter.running?
        event_list = self.list
        return if !event_list
        TravelExpansionFramework.with_runtime_context(@expansion_id, {
          :map_id          => ($game_map ? $game_map.map_id : 0),
          :common_event_id => @common_event_id
        }) do
          @interpreter.setup(event_list, 0, ($game_map ? $game_map.map_id : nil))
        end
      end
      TravelExpansionFramework.with_runtime_context(@expansion_id, {
        :map_id          => ($game_map ? $game_map.map_id : 0),
        :common_event_id => @common_event_id
      }) do
        @interpreter.update
      end
    end
  end
end

class Game_Switches
  alias tef_compat_original_get []
  alias tef_compat_original_set []=

  def [](switch_id)
    expansion_id = TravelExpansionFramework.current_runtime_expansion_id
    expansion_id = TravelExpansionFramework.current_map_expansion_id if expansion_id.nil? || expansion_id.empty?
    return tef_compat_original_get(switch_id) if expansion_id.nil? || expansion_id.empty?
    return TravelExpansionFramework.expansion_switch_value(expansion_id, switch_id)
  end

  def []=(switch_id, value)
    expansion_id = TravelExpansionFramework.current_runtime_expansion_id
    expansion_id = TravelExpansionFramework.current_map_expansion_id if expansion_id.nil? || expansion_id.empty?
    return tef_compat_original_set(switch_id, value) if expansion_id.nil? || expansion_id.empty?
    changed = TravelExpansionFramework.set_expansion_switch_value(expansion_id, switch_id, value)
    $game_map.need_refresh = true if changed && $game_map
    return value
  end
end

class Game_Variables
  alias tef_compat_original_get []
  alias tef_compat_original_set []=

  def [](variable_id)
    expansion_id = TravelExpansionFramework.current_runtime_expansion_id
    expansion_id = TravelExpansionFramework.current_map_expansion_id if expansion_id.nil? || expansion_id.empty?
    return tef_compat_original_get(variable_id) if expansion_id.nil? || expansion_id.empty?
    return TravelExpansionFramework.expansion_variable_value(expansion_id, variable_id)
  end

  def []=(variable_id, value)
    expansion_id = TravelExpansionFramework.current_runtime_expansion_id
    expansion_id = TravelExpansionFramework.current_map_expansion_id if expansion_id.nil? || expansion_id.empty?
    return tef_compat_original_set(variable_id, value) if expansion_id.nil? || expansion_id.empty?
    changed = TravelExpansionFramework.set_expansion_variable_value(expansion_id, variable_id, value)
    $game_map.need_refresh = true if changed && $game_map
    return value
  end
end

class Game_Event
  alias tef_compat_original_refresh refresh
  alias tef_compat_original_switchIsOn? switchIsOn?

  def switchIsOn?(id)
    expansion_id = TravelExpansionFramework.current_runtime_expansion_id || TravelExpansionFramework.current_map_expansion_id(@map_id)
    return tef_compat_original_switchIsOn?(id) if expansion_id.nil? || expansion_id.empty?
    switch_name = TravelExpansionFramework.switch_name_for(expansion_id, id)
    return tef_compat_original_switchIsOn?(id) if switch_name.nil?
    if switch_name[/^s\:/]
      return eval($~.post_match)
    end
    return $game_switches[id]
  end

  def refresh
    expansion_id = TravelExpansionFramework.current_map_expansion_id(@map_id)
    return tef_compat_original_refresh if expansion_id.nil? || expansion_id.empty?
    TravelExpansionFramework.with_runtime_context(expansion_id, {
      :map_id   => @map_id,
      :event_id => @id,
      :event    => self
    }) do
      tef_compat_original_refresh
    end
  end
end

class Game_Map
  alias tef_compat_original_setup setup

  def setup(map_id)
    tef_compat_original_setup(map_id)
    TravelExpansionFramework.install_external_common_events_for(self)
  end
end

class Interpreter
  attr_reader :tef_expansion_id

  alias tef_compat_original_setup setup
  alias tef_compat_original_update update
  alias tef_compat_original_setup_starting_event setup_starting_event
  alias tef_compat_original_pbCommonEvent pbCommonEvent
  alias tef_compat_original_command_if command_if
  alias tef_compat_original_command_111 command_111
  alias tef_compat_original_command_411 command_411
  alias tef_compat_original_command_117 command_117
  alias tef_compat_original_command_122 command_122
  alias tef_compat_original_command_201 command_201 unless method_defined?(:tef_compat_original_command_201)

  def tef_ensure_branch_state!
    return if @branch.is_a?(Hash)
    @branch = {}
    if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:log)
      TravelExpansionFramework.log("[interpreter] repaired missing branch state for map #{@map_id}, event #{@event_id}")
    end
  rescue
    @branch = {}
  end

  def setup(list, event_id, map_id = nil)
    tef_compat_original_setup(list, event_id, map_id)
    tef_ensure_branch_state!
    forced_expansion = TravelExpansionFramework.current_runtime_expansion_id
    @tef_expansion_id = if integer(event_id, 0) > 0
                           TravelExpansionFramework.current_map_expansion_id(@map_id)
                        elsif !forced_expansion.nil? && !forced_expansion.empty?
                          forced_expansion
                        else
                          nil
                        end
  end

  def update
    tef_ensure_branch_state!
    if TravelExpansionFramework.respond_to?(:interpreter_stale_for_current_map?) &&
       TravelExpansionFramework.interpreter_stale_for_current_map?(self)
      TravelExpansionFramework.clear_interpreter_state!(self, "stale interpreter update") if TravelExpansionFramework.respond_to?(:clear_interpreter_state!)
      return false
    end
    expansion_id = @tef_expansion_id
    expansion_id = TravelExpansionFramework.current_map_expansion_id if (expansion_id.nil? || expansion_id.empty?) && @main
    return tef_compat_original_update if expansion_id.nil? || expansion_id.empty?
    TravelExpansionFramework.with_runtime_context(expansion_id, {
      :map_id      => @map_id,
      :event_id    => @event_id,
      :interpreter => self
    }) do
      tef_compat_original_update
    end
  end

  def setup_starting_event
    $game_map.refresh if $game_map && $game_map.need_refresh
    if $game_temp.common_event_id > 0
      setup($data_common_events[$game_temp.common_event_id].list, 0)
      $game_temp.common_event_id = 0
      return
    end
    if $game_map
      for event in $game_map.events.values
        next if !event.starting
        if event.trigger < 3
          event.lock
          event.clear_starting
        end
        setup(event.list, event.id, event.map.map_id)
        return
      end
    end
    expansion_id = TravelExpansionFramework.current_map_expansion_id
    if !expansion_id.nil? && !expansion_id.empty?
      common_events = TravelExpansionFramework.expansion_common_events(expansion_id)
      if common_events.respond_to?(:each_with_index)
        common_events.each_with_index do |common_event, index|
          next if index <= 0 || !common_event || common_event.trigger != 1
          next if !TravelExpansionFramework.expansion_switch_active?(expansion_id, common_event.switch_id)
          TravelExpansionFramework.with_runtime_context(expansion_id, {
            :map_id          => ($game_map ? $game_map.map_id : 0),
            :common_event_id => index
          }) do
            setup(common_event.list, 0, ($game_map ? $game_map.map_id : nil))
          end
          return
        end
      end
    end
    tef_compat_original_setup_starting_event
  end

  def pbCommonEvent(id)
    expansion_id = @tef_expansion_id || TravelExpansionFramework.current_runtime_expansion_id
    common_event = TravelExpansionFramework.find_expansion_common_event(expansion_id, id)
    if common_event.nil?
      if !expansion_id.nil? && !expansion_id.empty?
        TravelExpansionFramework.log("Missing expansion common event #{id} for #{expansion_id}; host fallback was blocked.")
        return
      end
      return tef_compat_original_pbCommonEvent(id)
    end
    if $game_temp.in_battle
      TravelExpansionFramework.with_runtime_context(expansion_id, {
        :map_id          => @map_id,
        :event_id        => @event_id,
        :common_event_id => id
      }) do
        $game_system.battle_interpreter.setup(common_event.list, 0, @map_id)
      end
      return
    end
    interp = Interpreter.new
    TravelExpansionFramework.with_runtime_context(expansion_id, {
      :map_id          => @map_id,
      :event_id        => @event_id,
      :common_event_id => id
    }) do
      interp.setup(common_event.list, 0, @map_id)
      loop do
        Graphics.update
        Input.update
        interp.update
        pbUpdateSceneMap
        break if !interp.running?
      end
    end
  end

  def command_if(value)
    tef_ensure_branch_state!
    return tef_compat_original_command_if(value)
  end

  def command_111
    tef_ensure_branch_state!
    if (@tef_expansion_id.nil? || @tef_expansion_id.empty?) || @parameters[0] != 0
      return tef_compat_original_command_111
    end
    switch_name = TravelExpansionFramework.switch_name_for(@tef_expansion_id, @parameters[1])
    result = false
    if switch_name && switch_name[/^s\:/]
      result = (eval($~.post_match) == (@parameters[2] == 0))
    else
      result = ($game_switches[@parameters[1]] == (@parameters[2] == 0))
    end
    @branch[@list[@index].indent] = result
    if @branch[@list[@index].indent]
      @branch.delete(@list[@index].indent)
      return true
    end
    return command_skip
  end

  def command_411
    tef_ensure_branch_state!
    return tef_compat_original_command_411
  end

  def command_117
    common_event = TravelExpansionFramework.find_expansion_common_event(@tef_expansion_id, @parameters[0])
    if common_event.nil?
      if !@tef_expansion_id.nil? && !@tef_expansion_id.empty?
        TravelExpansionFramework.log("Missing expansion common event #{@parameters[0]} for #{@tef_expansion_id}; host fallback was blocked.")
        return true
      end
      return tef_compat_original_command_117
    end
    @child_interpreter = Interpreter.new(@depth + 1)
    TravelExpansionFramework.with_runtime_context(@tef_expansion_id, {
      :map_id          => @map_id,
      :event_id        => @event_id,
      :common_event_id => @parameters[0]
    }) do
      @child_interpreter.setup(common_event.list, @event_id, @map_id)
    end
    return true
  end

  def command_122
    if (@tef_expansion_id.nil? || @tef_expansion_id.empty?) || !(@parameters[3] == 7 && @parameters[4] == 0)
      return tef_compat_original_command_122
    end
    value = TravelExpansionFramework.local_map_id_for(@tef_expansion_id, $game_map.map_id)
    for i in @parameters[0]..@parameters[1]
      case @parameters[2]
      when 0
        next if $game_variables[i] == value
        $game_variables[i] = value
      when 1
        next if $game_variables[i] >= 99_999_999
        $game_variables[i] += value
      when 2
        next if $game_variables[i] <= -99_999_999
        $game_variables[i] -= value
      when 3
        next if value == 1
        $game_variables[i] *= value
      when 4
        next if value == 1 || value == 0
        $game_variables[i] /= value
      when 5
        next if value == 1 || value == 0
        $game_variables[i] %= value
      end
      $game_variables[i] = 99_999_999 if $game_variables[i] > 99_999_999
      $game_variables[i] = -99_999_999 if $game_variables[i] < -99_999_999
      $game_map.need_refresh = true if $game_map
    end
    return true
  end

  def command_201
    if defined?(tef_compat_original_command_201)
      raw_target_map_id = if @parameters[0] == 0
        integer(@parameters[1], 0)
      else
        integer($game_variables[@parameters[1]], 0)
      end
      source_map_id = integer(@map_id, ($game_map ? $game_map.map_id : 0))
      source_expansion = @tef_expansion_id.to_s
      source_expansion = TravelExpansionFramework.current_runtime_expansion_id.to_s if source_expansion.empty?
      source_expansion = TravelExpansionFramework.current_map_expansion_id(source_map_id).to_s if source_expansion.empty? && source_map_id > 0
      target_expansion = TravelExpansionFramework.current_map_expansion_id(raw_target_map_id).to_s
      return tef_compat_original_command_201 if source_expansion.empty? && target_expansion.empty?
    end
    return true if $game_temp.in_battle
    return false if $game_temp.player_transferring ||
                    $game_temp.message_window_showing ||
                    $game_temp.transition_processing
    if @parameters[0] == 0
      target_map_id = @parameters[1]
      target_x = @parameters[2]
      target_y = @parameters[3]
      target_direction = @parameters[4]
    else
      target_map_id = $game_variables[@parameters[1]]
      target_x = $game_variables[@parameters[2]]
      target_y = $game_variables[@parameters[3]]
      target_direction = @parameters[4]
    end
    transfer_expansion = @tef_expansion_id.to_s
    transfer_expansion = source_expansion if transfer_expansion.empty? && defined?(source_expansion)
    target_map_id = TravelExpansionFramework.translate_expansion_map_id(transfer_expansion, target_map_id)
    queued = TravelExpansionFramework.safe_transfer_to_anchor({
      :map_id    => target_map_id,
      :x         => target_x,
      :y         => target_y,
      :direction => target_direction
    }, {
      :source            => :story_transfer,
      :expansion_id      => transfer_expansion,
      :allow_story_state => true,
      :immediate         => false,
      :auto_rescue       => false
    })
    if !queued
      $game_temp.player_transferring = false if $game_temp.respond_to?(:player_transferring=)
      return false
    end
    @index += 1
    if @parameters[5] == 0
      Graphics.freeze
      $game_temp.transition_processing = true
      $game_temp.transition_name = ""
    end
    return false
  end

  private

  def integer(value, fallback = 0)
    return TravelExpansionFramework.integer(value, fallback)
  end
end
