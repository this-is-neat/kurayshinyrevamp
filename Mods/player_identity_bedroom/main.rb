if defined?($player_identity_bedroom_mod_loaded) && $player_identity_bedroom_mod_loaded
  puts "[PlayerIdentityBedroom] Duplicate load skipped."
else
  $player_identity_bedroom_mod_loaded = true

  GENDER_NONBINARY = 2 unless defined?(GENDER_NONBINARY)

  module PlayerIdentityBedroomAddon
    MODULE_LABEL = "[PlayerIdentityBedroom]"
    DEFAULT_PRESENTATION_GENDER = GENDER_MALE
    INTRO_MIN_AGE = 10
    INTRO_MAX_AGE = 99
    FALLBACK_BEDROOM_MAP_ID = 73

    # The addon reuses the existing bedroom maps rather than creating a new asset pipeline.
    BEDROOM_STYLES = [
      # Labels are approximate palette names based on the existing room tiles.
      { :map_id => 68, :label => "Pink" },
      { :map_id => 48, :label => "Salmon" },
      { :map_id => 70, :label => "Purple" },
      { :map_id => 69, :label => "Mint" },
      { :map_id => 67, :label => "Sky" },
      { :map_id => 71, :label => "Gray" }
    ].freeze

    PRONOUN_SETS = {
      GENDER_FEMALE    => {
        :subject               => "she",
        :object                => "her",
        :possessive_adjective  => "her",
        :possessive            => "hers",
        :reflexive             => "herself",
        :be                    => "is",
        :have                  => "has",
        :do                    => "does"
      },
      GENDER_MALE      => {
        :subject               => "he",
        :object                => "him",
        :possessive_adjective  => "his",
        :possessive            => "his",
        :reflexive             => "himself",
        :be                    => "is",
        :have                  => "has",
        :do                    => "does"
      },
      GENDER_NONBINARY => {
        :subject               => "they",
        :object                => "them",
        :possessive_adjective  => "their",
        :possessive            => "theirs",
        :reflexive             => "themself",
        :be                    => "are",
        :have                  => "have",
        :do                    => "do"
      }
    }.freeze

    PRONOUN_TOKEN_KEYS = {
      "subject"      => :subject,
      "subj"         => :subject,
      "they"         => :subject,
      "object"       => :object,
      "obj"          => :object,
      "them"         => :object,
      "possessive"   => :possessive,
      "theirs"       => :possessive,
      "poss_adj"     => :possessive_adjective,
      "adj"          => :possessive_adjective,
      "their"        => :possessive_adjective,
      "possessive_adjective" => :possessive_adjective,
      "reflexive"    => :reflexive,
      "themself"     => :reflexive,
      "be"           => :be,
      "have"         => :have,
      "do"           => :do
    }.freeze

    # These neutralizations only cover common player-facing tags and can be extended later.
    NEUTRAL_PAIR_MAP = {
      ["he", "she"]                => "they",
      ["him", "her"]               => "them",
      ["his", "her"]               => "their",
      ["his", "hers"]              => "theirs",
      ["himself", "herself"]       => "themself",
      ["boy", "girl"]              => "kid",
      ["bro", "sis"]               => "friend",
      ["man", "woman"]             => "person",
      ["son", "daughter"]          => "child",
      ["brother", "sister"]        => "sibling",
      ["grandson", "granddaughter"] => "grandchild",
      ["husband", "wife"]          => "spouse",
      ["boyfriend", "girlfriend"]  => "partner",
      ["mr.", "ms."]               => "Mx.",
      ["mr", "ms"]                 => "Mx."
    }.freeze

    NEUTRAL_SINGLE_MAP = {
      "he"         => "they",
      "she"        => "they",
      "him"        => "them",
      "her"        => "their",
      "his"        => "their",
      "hers"       => "theirs",
      "himself"    => "themself",
      "herself"    => "themself",
      "boy"        => "kid",
      "girl"       => "kid",
      "bro"        => "friend",
      "sis"        => "friend",
      "man"        => "person",
      "woman"      => "person",
      "son"        => "child",
      "daughter"   => "child",
      "brother"    => "sibling",
      "sister"     => "sibling",
      "husband"    => "spouse",
      "wife"       => "spouse"
    }.freeze

    module_function

    def raw_framework_gender
      return GENDER_MALE if !defined?(pbGet)
      return pbGet(VAR_TRAINER_GENDER)
    rescue
      return nil
    end

    def normalize_binary_gender(value, fallback = DEFAULT_PRESENTATION_GENDER)
      return GENDER_FEMALE if value == GENDER_FEMALE
      return GENDER_MALE if value == GENDER_MALE
      return GENDER_FEMALE if value.to_i == GENDER_FEMALE && value.to_s =~ /\A\d+\z/
      return GENDER_MALE if value.to_i == GENDER_MALE && value.to_s =~ /\A\d+\z/
      return fallback
    end

    def safe_framework_gender
      return normalize_binary_gender(raw_framework_gender, DEFAULT_PRESENTATION_GENDER)
    end

    # Retained as a compatibility helper for earlier addon revisions.
    def safe_variable_gender
      return safe_framework_gender
    end

    def safe_player_age
      return nil if !defined?(pbGet)
      return pbGet(VAR_TRAINER_AGE)
    rescue
      return nil
    end

    def normalize_intro_age(age)
      value = age.to_i
      value = INTRO_MIN_AGE if value < INTRO_MIN_AGE
      value = INTRO_MAX_AGE if value > INTRO_MAX_AGE
      return value
    end

    def normalize_identity_gender(value)
      return GENDER_FEMALE if value == GENDER_FEMALE
      return GENDER_MALE if value == GENDER_MALE
      return GENDER_NONBINARY if value == GENDER_NONBINARY
      return GENDER_FEMALE if value.to_i == GENDER_FEMALE && value.to_s =~ /\A\d+\z/
      return GENDER_MALE if value.to_i == GENDER_MALE && value.to_s =~ /\A\d+\z/
      return GENDER_NONBINARY if value.to_i == GENDER_NONBINARY && value.to_s =~ /\A\d+\z/
      return GENDER_MALE
    end

    def normalize_presentation_gender(value, identity_gender = nil)
      fallback = normalize_binary_gender(identity_gender, DEFAULT_PRESENTATION_GENDER)
      return normalize_binary_gender(value, fallback)
    end

    def live_player_context?(player = $Trainer)
      return false if !player
      return defined?($Trainer) && $Trainer && player.equal?($Trainer)
    end

    def player_trainer_type_gender(player)
      return nil if !player
      trainer_type = nil
      trainer_type = player.trainer_type if player.respond_to?(:trainer_type)
      return nil if !trainer_type
      return normalize_binary_gender(GameData::TrainerType.get(trainer_type).gender, nil)
    rescue
      return nil
    end

    def resolved_identity_gender(player = $Trainer)
      return safe_framework_gender if !player
      explicit_identity = player.player_identity_gender if player.respond_to?(:player_identity_gender)
      return normalize_identity_gender(explicit_identity) if !explicit_identity.nil?

      if live_player_context?(player)
        framework_gender = normalize_identity_gender(raw_framework_gender)
        return framework_gender if framework_gender == GENDER_NONBINARY
      end

      presentation_hint = player.player_presentation_gender if player.respond_to?(:player_presentation_gender)
      presentation_hint = normalize_binary_gender(presentation_hint, nil) if !presentation_hint.nil?
      return presentation_hint if !presentation_hint.nil?

      trainer_type_gender = player_trainer_type_gender(player)
      return trainer_type_gender if !trainer_type_gender.nil?

      framework_binary_gender = live_player_context?(player) ? normalize_binary_gender(raw_framework_gender, nil) : nil
      return framework_binary_gender if !framework_binary_gender.nil?
      return DEFAULT_PRESENTATION_GENDER
    end

    def resolved_presentation_gender(player = $Trainer, identity_gender = nil)
      fallback = normalize_binary_gender(identity_gender.nil? ? resolved_identity_gender(player) : identity_gender, DEFAULT_PRESENTATION_GENDER)
      return fallback if !player

      explicit_presentation = player.player_presentation_gender if player.respond_to?(:player_presentation_gender)
      explicit_presentation = normalize_binary_gender(explicit_presentation, nil) if !explicit_presentation.nil?
      return explicit_presentation if !explicit_presentation.nil?

      trainer_type_gender = player_trainer_type_gender(player)
      return trainer_type_gender if !trainer_type_gender.nil?

      framework_binary_gender = live_player_context?(player) ? normalize_binary_gender(raw_framework_gender, nil) : nil
      return framework_binary_gender if !framework_binary_gender.nil?
      return fallback
    end

    # Older addon builds stored the nonbinary value directly in VAR_TRAINER_GENDER,
    # but RPG Maker page conditions treat variable checks as ">=", which makes 2
    # fall into male-only pages. Keep the framework variable binary and store the
    # player's actual identity separately on the live Player object instead.
    def migrate_legacy_gender_storage(player = $Trainer)
      return player if !live_player_context?(player)
      stored_identity = resolved_identity_gender(player)
      presentation_gender = resolved_presentation_gender(player, stored_identity)
      player.player_identity_gender = stored_identity
      player.player_presentation_gender = presentation_gender

      current_framework_gender = normalize_binary_gender(raw_framework_gender, nil)
      if defined?(pbSet) && current_framework_gender != presentation_gender
        pbSet(VAR_TRAINER_GENDER, presentation_gender)
      end
      return player
    end

    def normalize_bedroom_map_id(map_id)
      return nil if map_id.nil?
      value = map_id.to_i
      return value if BEDROOM_STYLES.any? { |style| style[:map_id] == value }
      return nil
    end

    def ensure_player_state(player = $Trainer)
      return nil if !player
      if live_player_context?(player)
        migrate_legacy_gender_storage(player)
        player.player_bedroom_map_id = normalize_bedroom_map_id(player.player_bedroom_map_id)
        player.player_intro_hair_dye_prompted = !!player.player_intro_hair_dye_prompted
      end
      return player
    end

    def player_identity_gender(player = $Trainer)
      return safe_framework_gender if !player
      player = ensure_player_state(player) if live_player_context?(player)
      return normalize_identity_gender(player.player_identity_gender) if player.respond_to?(:player_identity_gender) && !player.player_identity_gender.nil?
      return resolved_identity_gender(player)
    end

    def player_presentation_gender(player = $Trainer)
      return DEFAULT_PRESENTATION_GENDER if !player
      player = ensure_player_state(player) if live_player_context?(player)
      if player.respond_to?(:player_presentation_gender) && !player.player_presentation_gender.nil?
        return normalize_presentation_gender(player.player_presentation_gender, player_identity_gender(player))
      end
      return resolved_presentation_gender(player, player_identity_gender(player))
    end

    def identity_male?(player = $Trainer)
      return player_identity_gender(player) == GENDER_MALE
    end

    def identity_female?(player = $Trainer)
      return player_identity_gender(player) == GENDER_FEMALE
    end

    def nonbinary?(player = $Trainer)
      return player_identity_gender(player) == GENDER_NONBINARY
    end

    def presentation_male?(player = $Trainer)
      return player_presentation_gender(player) == GENDER_MALE
    end

    def presentation_female?(player = $Trainer)
      return player_presentation_gender(player) == GENDER_FEMALE
    end

    def apply_identity_selection(identity_gender, presentation_gender = nil, player = $Trainer)
      return if !player
      normalized_identity = normalize_identity_gender(identity_gender)
      normalized_presentation = if normalized_identity == GENDER_NONBINARY
        normalize_presentation_gender(presentation_gender, normalized_identity)
      else
        normalized_identity
      end
      player.player_identity_gender = normalized_identity
      player.player_presentation_gender = normalized_presentation
      pbSet(VAR_TRAINER_GENDER, normalized_presentation) if defined?(pbSet)
      ensure_player_state(player)
    end

    def gender_label(identity_gender)
      case normalize_identity_gender(identity_gender)
      when GENDER_FEMALE then return "Female"
      when GENDER_MALE then return "Male"
      else return "Nonbinary"
      end
    end

    def resolve_menu_presentation(identity_gender, current_presentation)
      normalized_identity = normalize_identity_gender(identity_gender)
      return normalized_identity if normalized_identity == GENDER_FEMALE || normalized_identity == GENDER_MALE
      return normalize_presentation_gender(current_presentation, normalized_identity)
    end

    def pronoun_set(player = $Trainer)
      return PRONOUN_SETS[player_identity_gender(player)] || PRONOUN_SETS[GENDER_NONBINARY]
    end

    def pronoun_key(key)
      normalized = key.to_s.strip.downcase
      return PRONOUN_TOKEN_KEYS[normalized] || normalized.to_sym
    end

    def capitalize_word(value)
      text = value.to_s
      return text if text.empty?
      return text[0].upcase + text[1..-1].to_s
    end

    def player_pronoun(key, capitalize = false, player = $Trainer)
      value = pronoun_set(player)[pronoun_key(key)] || ""
      return capitalize ? capitalize_word(value) : value
    end

    def preserve_case(source, replacement)
      return replacement.to_s if source.to_s.empty? || replacement.to_s.empty?
      return replacement.to_s.upcase if source == source.upcase
      return capitalize_word(replacement) if source[0, 1] == source[0, 1].upcase
      return replacement.to_s
    end

    def neutralize_pair(male_text, female_text)
      neutral = NEUTRAL_PAIR_MAP[[male_text.to_s.downcase, female_text.to_s.downcase]]
      neutral ||= NEUTRAL_SINGLE_MAP[male_text.to_s.downcase]
      neutral ||= NEUTRAL_SINGLE_MAP[female_text.to_s.downcase]
      return preserve_case(male_text, neutral.to_s)
    end

    def neutralize_single(text)
      neutral = NEUTRAL_SINGLE_MAP[text.to_s.downcase]
      return preserve_case(text, neutral.to_s)
    end

    def preprocess_message_text(message)
      return message if message.nil?
      text = message.to_s.dup
      text.gsub!(/\\pp\[([^\]]+)\]/i) { player_pronoun_token($1) }
      return text if !nonbinary?
      text.gsub!(/\\mu\[([^\]]*)\]\\fu\[([^\]]*)\]/i) { neutralize_pair($1, $2) }
      text.gsub!(/\\fu\[([^\]]*)\]\\mu\[([^\]]*)\]/i) { neutralize_pair($2, $1) }
      text.gsub!(/\\mu\[([^\]]*)\]/i) { neutralize_single($1) }
      text.gsub!(/\\fu\[([^\]]*)\]/i) { neutralize_single($1) }
      text.gsub!(/\\pg/i, "")
      text.gsub!(/\\pog/i, "")
      return text
    end

    def player_pronoun_token(token)
      token = token.to_s
      capitalize = token.match?(/\Acap_/i)
      token = token.sub(/\Acap_/i, "")
      return player_pronoun(token, capitalize)
    end

    def style_index_for_map_id(map_id)
      return BEDROOM_STYLES.index { |style| style[:map_id] == map_id }
    end

    def bedroom_style_label(map_id)
      style = BEDROOM_STYLES.find { |entry| entry[:map_id] == map_id.to_i }
      return style ? style[:label] : "Wood"
    end

    def bedroom_map?(map_id)
      return false if map_id.nil?
      return bedroom_transfer_target_map_ids.include?(map_id.to_i)
    end

    def choose_bedroom_style(default_map_id = nil, prompt_message = nil, allow_cancel = false)
      default_index = style_index_for_map_id(default_map_id) || style_index_for_map_id(bedroom_map_id) || 0
      pbMessage(prompt_message) if prompt_message
      commands = BEDROOM_STYLES.map { |style| _INTL(style[:label]) }
      if allow_cancel
        cancel_index = commands.length
        commands << _INTL("Cancel")
        choice = optionsMenu(commands, cancel_index, default_index)
        return nil if choice.nil? || choice < 0 || choice == cancel_index
      else
        choice = optionsMenu(commands, default_index, default_index)
        choice = default_index if choice.nil? || choice < 0 || choice >= BEDROOM_STYLES.length
      end
      return BEDROOM_STYLES[choice][:map_id]
    end

    def legacy_bedroom_map_id(age = nil, player = $Trainer)
      age = (age || safe_player_age).to_i
      return FALLBACK_BEDROOM_MAP_ID if age < INTRO_MIN_AGE
      if age <= 12
        return presentation_female?(player) ? 68 : 69
      elsif age <= 15
        return presentation_female?(player) ? 48 : 67
      else
        return presentation_female?(player) ? 70 : 71
      end
    end

    def bedroom_map_id(player = $Trainer, age = nil)
      player = ensure_player_state(player)
      return legacy_bedroom_map_id(age, player) if !player
      return player.player_bedroom_map_id if player.player_bedroom_map_id
      return legacy_bedroom_map_id(age, player)
    end

    def set_bedroom_map(map_id, player = $Trainer)
      player = ensure_player_state(player)
      return if !player
      normalized = normalize_bedroom_map_id(map_id)
      return if normalized.nil?
      player.player_bedroom_map_id = normalized
    end

    def intro_setup_context?(player = $Trainer)
      return false if !player || !$game_map || $game_map.map_id != 295
      return true if defined?($PokemonTemp) && $PokemonTemp && $PokemonTemp.begunNewGame
      return false if player.last_time_saved
      return false if player.respond_to?(:save_slot) && player.save_slot
      return true
    end

    def prompt_for_bedroom_style_if_needed
      return if !intro_setup_context?($Trainer)
      ensure_player_state($Trainer)
      return if $Trainer.player_bedroom_map_id
      selected_map_id = choose_bedroom_style(
        legacy_bedroom_map_id,
        _INTL("Choose a bedroom style.\nAll current room layouts are available regardless of identity."),
        false
      )
      set_bedroom_map(selected_map_id) if selected_map_id
    end

    def change_bedroom_style_from_pc
      return false if !$Trainer || !$game_map || !$game_player
      return false if !bedroom_map?($game_map.map_id)
      ensure_player_state($Trainer)
      selected_map_id = choose_bedroom_style(
        $game_map.map_id,
        _INTL("Choose a bedroom color.\nYou can update this again from your bedroom PC anytime."),
        true
      )
      return false if selected_map_id.nil?
      selected_label = bedroom_style_label(selected_map_id)
      previous_selection = bedroom_map_id
      set_bedroom_map(selected_map_id)
      if previous_selection == selected_map_id && $game_map.map_id == selected_map_id
        pbMessage(_INTL("Your bedroom is already set to the {1} style.", selected_label))
        return false
      end
      pbMessage(_INTL("Your bedroom was updated to the {1} style.", selected_label))
      return false if $game_map.map_id == selected_map_id
      queue_player_transfer(selected_map_id, $game_player.x, $game_player.y, $game_player.direction, 1)
      return true
    end

    def prompt_for_intro_hair_dye_if_needed
      return if !intro_setup_context?($Trainer)
      return if $Trainer.player_intro_hair_dye_prompted
      $Trainer.player_intro_hair_dye_prompted = true
      return if !defined?(selectHairColor)
      pbMessage(_INTL("You can customize your hair dye now.\nThis first intro dye session is free."))
      return if !pbConfirmMessage(_INTL("Would you like to adjust your hair dye now?"))
      selectHairColor
    end

    # Mirrors event command 201 closely, but can also execute immediately when
    # called from a common event child interpreter. That avoids stair returns
    # getting stuck with a queued transfer that never fires reliably.
    def queue_player_transfer(map_id, x, y, direction = 0, fade = 0, cancel_vehicles = true)
      return if !$game_temp
      return if $game_temp.player_transferring || $game_temp.message_window_showing || $game_temp.transition_processing
      $game_temp.player_transferring = true
      $game_temp.player_new_map_id = map_id
      $game_temp.player_new_x = x
      $game_temp.player_new_y = y
      $game_temp.player_new_direction = direction
      if fade == 0
        Graphics.freeze
        $game_temp.transition_processing = true
        $game_temp.transition_name = ""
      end
      if $scene.is_a?(Scene_Map) && $scene.respond_to?(:transfer_player)
        $scene.transfer_player(cancel_vehicles)
      end
    end

    def queue_player_bedroom_transfer(x, y, direction = 0, fade = 0)
      queue_player_transfer(bedroom_map_id, x, y, direction, fade)
    end

    def bedroom_transfer_target_map_ids
      return BEDROOM_STYLES.map { |style| style[:map_id] } + [FALLBACK_BEDROOM_MAP_ID]
    end

    def build_room_transfer_commands(template, x, y, direction, fade)
      commands = []
      bedroom_transfer_target_map_ids.each do |map_id|
        commands << clone_command(template, 111, 0, [12, "PlayerIdentityBedroomAddon.bedroom_map_id == #{map_id}"])
        commands << clone_command(template, 201, 1, [0, map_id, x, y, direction, fade])
        commands << clone_command(template, 412, 0, [])
      end
      return commands
    end

    def command_code(command)
      return command.code if command.respond_to?(:code)
      return command.instance_variable_get(:@code)
    end

    def set_command_code(command, value)
      if command.respond_to?(:code=)
        command.code = value
      else
        command.instance_variable_set(:@code, value)
      end
    end

    def command_indent(command)
      return command.indent if command.respond_to?(:indent)
      return command.instance_variable_get(:@indent)
    end

    def set_command_indent(command, value)
      if command.respond_to?(:indent=)
        command.indent = value
      else
        command.instance_variable_set(:@indent, value)
      end
    end

    def command_parameters(command)
      return command.parameters if command.respond_to?(:parameters)
      return command.instance_variable_get(:@parameters)
    end

    def set_command_parameters(command, value)
      if command.respond_to?(:parameters=)
        command.parameters = value
      else
        command.instance_variable_set(:@parameters, value)
      end
    end

    def command_script_text(command)
      code = command_code(command)
      params = command_parameters(command) || []
      return params[1].to_s if code == 111 && params[0] == 12
      return params[0].to_s if [355, 655, 101, 401].include?(code)
      return ""
    end

    def clone_command(source, code, indent, parameters)
      command = Marshal.load(Marshal.dump(source))
      set_command_code(command, code)
      set_command_indent(command, indent)
      set_command_parameters(command, parameters)
      return command
    end

    def event_list(container)
      return container.list if container.respond_to?(:list)
      return container.instance_variable_get(:@list)
    end

    def set_event_list(container, new_list)
      if container.respond_to?(:list=)
        container.list = new_list
      else
        container.instance_variable_set(:@list, new_list)
      end
    end

    def map_events(map)
      return map.events if map.respond_to?(:events)
      return map.instance_variable_get(:@events)
    end

    def event_pages(event)
      return event.pages if event.respond_to?(:pages)
      return event.instance_variable_get(:@pages)
    end

    def page_for(map, event_id, page_index = 0)
      events = map_events(map)
      return nil if !events || !events[event_id]
      pages = event_pages(events[event_id])
      return nil if !pages
      return pages[page_index]
    end

    # Preserve the engine's real Transfer Player commands so the room map fully
    # reloads when walking back upstairs instead of relying on a script redirect.
    def patch_room_transfer_container!(container, x, y, direction, fade, trailing_count)
      return false if !container
      list = event_list(container)
      return false if !list || list.empty?
      return false if list.any? { |command| command_script_text(command).include?("PlayerIdentityBedroomAddon.bedroom_map_id ==") }
      start_index = list.find_index do |command|
        text = command_script_text(command)
        (command_code(command) == 111 && text.include?("pbGet(99)<10")) ||
          text.include?("queue_player_bedroom_transfer")
      end
      return false if start_index.nil?
      start_command_text = command_script_text(list[start_index])
      end_index = if start_command_text.include?("queue_player_bedroom_transfer")
        start_index
      else
        last_search_index = list.length - trailing_count - 1
        last_search_index = list.length - 1 if last_search_index < start_index
        found_index = nil
        last_search_index.downto(start_index) do |index|
          if command_code(list[index]) == 412 && command_indent(list[index]) == 0
            found_index = index
            break
          end
        end
        found_index
      end
      return false if end_index.nil?
      replacement = build_room_transfer_commands(list[start_index], x, y, direction, fade)
      trailing = list[(end_index + 1)..-1].to_a.map { |command| Marshal.load(Marshal.dump(command)) }
      new_list = list[0...start_index] + replacement + trailing
      set_event_list(container, new_list)
      return true
    end

    def replace_condition_block!(container, condition_script, replacement_commands)
      list = event_list(container)
      return false if !list || list.empty?
      start_index = list.find_index do |command|
        command_code(command) == 111 && command_script_text(command) == condition_script
      end
      return false if start_index.nil?
      end_index = nil
      ((start_index + 1)...list.length).each do |index|
        if command_code(list[index]) == 412 && command_indent(list[index]) == 0
          end_index = index
          break
        end
      end
      return false if end_index.nil?
      template = list[start_index]
      built_commands = replacement_commands.map do |command_def|
        clone_command(
          template,
          command_def[:code],
          command_def[:indent] || 0,
          command_def[:parameters]
        )
      end
      new_list = list[0...start_index] + built_commands + list[(end_index + 1)..-1]
      set_event_list(container, new_list)
      return true
    end

    def replace_message_texts!(container, replacements)
      list = event_list(container)
      return false if !list || list.empty?
      changed = false
      list.each do |command|
        next if ![101, 401].include?(command_code(command))
        parameters = command_parameters(command)
        next if !parameters || parameters.empty?
        original_text = parameters[0].to_s
        next if !replacements.key?(original_text)
        updated_parameters = parameters.dup
        updated_parameters[0] = replacements[original_text]
        set_command_parameters(command, updated_parameters)
        changed = true
      end
      return changed
    end

    def patch_route34_pronoun_script!(container)
      list = event_list(container)
      return false if !list || list.empty?
      start_index = list.find_index do |command|
        command_code(command) == 355 &&
          command_script_text(command).include?('p = pbGet(52) == 1 ? "He" : "She"')
      end
      return false if start_index.nil?
      delete_count = (start_index + 1 < list.length && command_code(list[start_index + 1]) == 655) ? 2 : 1
      new_command = clone_command(
        list[start_index],
        355,
        0,
        ['pbSet(1, PlayerIdentityBedroomAddon.player_pronoun(:subject, true))']
      )
      new_list = list.dup
      new_list[start_index, delete_count] = [new_command]
      set_event_list(container, new_list)
      return true
    end

    def patch_common_events!(common_events)
      return false if !common_events
      changed = false
      changed = patch_room_transfer_container!(common_events[19], 8, 9, 8, 0, 0) || changed if common_events[19]
      changed = patch_room_transfer_container!(common_events[99], 11, 5, 0, 1, 0) || changed if common_events[99]
      changed = patch_room_transfer_container!(common_events[101], 11, 5, 0, 1, 1) || changed if common_events[101]
      return changed
    end

    def patch_map!(map_id, map)
      return false if !map
      changed = false
      case map_id
      when 3
        changed = patch_room_transfer_container!(page_for(map, 2, 0), 11, 5, 0, 1, 1) || changed
      when 29
        changed = replace_condition_block!(page_for(map, 12, 0), "isPlayerMale()", [
          { :code => 355, :parameters => ['pbCallBub(2,@event_id) #waiter'] },
          { :code => 101, :parameters => ["You, mon ami!"] }
        ]) || changed
        changed = replace_condition_block!(page_for(map, 12, 1), "isPlayerMale()", [
          { :code => 355, :parameters => ['pbCallBub(2,@event_id) #waiter'] },
          { :code => 101, :parameters => ["Mon ami, will you take ze orders for me? Ze chef will be "] },
          { :code => 401, :parameters => ["eternally grateful!"] }
        ]) || changed
      when 43
        sibling_dialogue_replacements = {
          "...It's awesome that you're finally becoming a trainer, sis!" => "...It's awesome that you're finally becoming a trainer!",
          "...It's awesome that you're finally becoming a trainer, bro!" => "...It's awesome that you're finally becoming a trainer!",
          "Sis, you're really going out adventuring in these clothes?" => "You're really going out adventuring in these clothes?",
          "Bro, you're really going out adventuring in these clothes?" => "You're really going out adventuring in these clothes?",
          "Sis, you've really been out adventuring in these clothes " => "You've really been out adventuring in these clothes ",
          "Bro, you've really been out adventuring in these clothes " => "You've really been out adventuring in these clothes ",
          "You should wear these instead, you'll look a lot tougher!" => "You should wear these instead, they should suit you better!",
          "You should wear these instead, you'll look a lot cuter!" => "You should wear these instead, they should suit you better!"
        }
        6.times do |page_index|
          changed = replace_message_texts!(page_for(map, 4, page_index), sibling_dialogue_replacements) || changed
        end
      when 45
        changed = replace_condition_block!(page_for(map, 16, 0), "isPlayerMale()", [
          { :code => 355, :parameters => ['pbCallBubDown(2,15) #grunt'] },
          { :code => 101, :parameters => ["They almost got pinched! This was much too risky of a "] },
          { :code => 401, :parameters => ["mission!"] }
        ]) || changed
      when 186
        changed = patch_room_transfer_container!(page_for(map, 8, 0), 8, 9, 8, 0, 0) || changed
      when 265
        changed = patch_route34_pronoun_script!(page_for(map, 10, 4)) || changed
      when 599
        changed = replace_message_texts!(page_for(map, 4, 0), {
          "This is the boy I told you about!" => "This is the trainer I told you about!",
          "This is the girl I told you about!" => "This is the trainer I told you about!"
        }) || changed
      end
      return changed
    end

    def in_memory_patchable_map_id?(map_id)
      return [3, 29, 43, 45, 186, 265, 599].include?(map_id)
    end

    def apply_in_memory_patches
      patch_common_events!($data_common_events) if defined?($data_common_events) && $data_common_events
      ensure_player_state($Trainer) if defined?($Trainer) && $Trainer
    end
  end

  class Player
    attr_accessor :player_identity_gender
    attr_accessor :player_presentation_gender
    attr_accessor :player_bedroom_map_id
    attr_accessor :player_intro_hair_dye_prompted

    alias __player_identity_bedroom_initialize initialize unless method_defined?(:__player_identity_bedroom_initialize)
    def initialize(*args)
      __player_identity_bedroom_initialize(*args)
      @player_identity_gender = nil
      @player_presentation_gender = nil
      @player_bedroom_map_id = nil
      @player_intro_hair_dye_prompted = false
    end

    def gender
      return PlayerIdentityBedroomAddon.player_identity_gender(self)
    end

    def male?
      return PlayerIdentityBedroomAddon.identity_male?(self)
    end

    def female?
      return PlayerIdentityBedroomAddon.identity_female?(self)
    end

    def nonbinary?
      return PlayerIdentityBedroomAddon.nonbinary?(self)
    end

    def presentation_gender
      return PlayerIdentityBedroomAddon.player_presentation_gender(self)
    end

    def pronouns
      return PlayerIdentityBedroomAddon.pronoun_set(self)
    end

    def last_worn_outfit
      @last_worn_outfit = getDefaultClothes(PlayerIdentityBedroomAddon.player_presentation_gender(self)) if !@last_worn_outfit
      return @last_worn_outfit
    end
  end

  class CharacterSelectMenuPresenter
    GENDER_TEXT_ID = "gender" unless const_defined?(:GENDER_TEXT_ID)

    alias __player_identity_bedroom_initialize initialize unless method_defined?(:__player_identity_bedroom_initialize)
    def initialize(view)
      __player_identity_bedroom_initialize(view)
      PlayerIdentityBedroomAddon.ensure_player_state($Trainer)
      @gender = PlayerIdentityBedroomAddon.player_identity_gender($Trainer)
      @presentation_gender = PlayerIdentityBedroomAddon.player_presentation_gender($Trainer)
      @age = PlayerIdentityBedroomAddon.normalize_intro_age(@age)
    end

    def setAge(y_index, incr)
      @age = PlayerIdentityBedroomAddon.normalize_intro_age(@age + incr)
      @view.displayAge(@age, y_index)
    end

    def setGender(current_index, incr)
      choices = [GENDER_FEMALE, GENDER_MALE, GENDER_NONBINARY]
      current_choice_index = choices.index(PlayerIdentityBedroomAddon.normalize_identity_gender(@gender)) || 1
      current_choice_index += incr
      current_choice_index = 0 if current_choice_index >= choices.length
      current_choice_index = choices.length - 1 if current_choice_index < 0
      @gender = choices[current_choice_index]
      @presentation_gender = PlayerIdentityBedroomAddon.resolve_menu_presentation(@gender, @presentation_gender)
      applyGender(@gender)
      @view.displayText(GENDER_TEXT_ID, PlayerIdentityBedroomAddon.gender_label(@gender), current_index)
    end

    def applyGender(gender_index)
      @presentation_gender = PlayerIdentityBedroomAddon.resolve_menu_presentation(gender_index, @presentation_gender)
      PlayerIdentityBedroomAddon.apply_identity_selection(gender_index, @presentation_gender)
      outfit_id = getDefaultClothes(@presentation_gender)
      hat_id = getDefaultHat(@presentation_gender)
      @hairstyle = getDefaultHair(@presentation_gender)
      applyHair
      $Trainer.clothes = outfit_id
      $Trainer.hat = hat_id
    end
  end

  class Object
    alias __player_identity_bedroom_pbMessageDisplay pbMessageDisplay unless method_defined?(:__player_identity_bedroom_pbMessageDisplay)
    def pbMessageDisplay(msgwindow, message, letterbyletter = true, commandProc = nil, withSound = true)
      prepared_message = PlayerIdentityBedroomAddon.preprocess_message_text(message)
      __player_identity_bedroom_pbMessageDisplay(msgwindow, prepared_message, letterbyletter, commandProc, withSound)
    end
  end

  alias __player_identity_bedroom_getPlayerDefaultName getPlayerDefaultName unless defined?(__player_identity_bedroom_getPlayerDefaultName)
  def getPlayerDefaultName(gender = nil)
    gender = PlayerIdentityBedroomAddon.normalize_identity_gender(gender.nil? ? PlayerIdentityBedroomAddon.player_identity_gender($Trainer) : gender)
    return "Green" if gender == GENDER_FEMALE
    return "Red" if gender == GENDER_MALE
    suggested_name = pbSuggestTrainerName(gender)
    return suggested_name if suggested_name && !suggested_name.empty?
    return "Player"
  end

  alias __player_identity_bedroom_getDefaultClothes getDefaultClothes unless defined?(__player_identity_bedroom_getDefaultClothes)
  def getDefaultClothes(gender = nil)
    resolved_gender = PlayerIdentityBedroomAddon.normalize_presentation_gender(gender, PlayerIdentityBedroomAddon.player_identity_gender($Trainer))
    return __player_identity_bedroom_getDefaultClothes(resolved_gender)
  end

  alias __player_identity_bedroom_getDefaultHat getDefaultHat unless defined?(__player_identity_bedroom_getDefaultHat)
  def getDefaultHat(gender = nil)
    resolved_gender = PlayerIdentityBedroomAddon.normalize_presentation_gender(gender, PlayerIdentityBedroomAddon.player_identity_gender($Trainer))
    return __player_identity_bedroom_getDefaultHat(resolved_gender)
  end

  alias __player_identity_bedroom_getDefaultHair getDefaultHair unless defined?(__player_identity_bedroom_getDefaultHair)
  def getDefaultHair(gender = nil)
    resolved_gender = PlayerIdentityBedroomAddon.normalize_presentation_gender(gender, PlayerIdentityBedroomAddon.player_identity_gender($Trainer))
    return __player_identity_bedroom_getDefaultHair(resolved_gender)
  end

  alias __player_identity_bedroom_setupStartingOutfit setupStartingOutfit unless defined?(__player_identity_bedroom_setupStartingOutfit)
  def setupStartingOutfit()
    PlayerIdentityBedroomAddon.prompt_for_bedroom_style_if_needed
    PlayerIdentityBedroomAddon.ensure_player_state($Trainer)
    original_identity = PlayerIdentityBedroomAddon.player_identity_gender($Trainer)
    presentation_gender = PlayerIdentityBedroomAddon.player_presentation_gender($Trainer)
    temporary_gender = PlayerIdentityBedroomAddon.nonbinary?($Trainer) ? presentation_gender : original_identity
    pbSet(VAR_TRAINER_GENDER, temporary_gender)
    __player_identity_bedroom_setupStartingOutfit()
    PlayerIdentityBedroomAddon.apply_identity_selection(original_identity, presentation_gender)
    if PlayerIdentityBedroomAddon.nonbinary?($Trainer)
      # Unlock both default silhouettes so the addon doesn't force a binary wardrobe follow-up later.
      $Trainer.unlock_clothes(DEFAULT_OUTFIT_MALE, true)
      $Trainer.unlock_clothes(DEFAULT_OUTFIT_FEMALE, true)
      $Trainer.unlock_hat(DEFAULT_OUTFIT_MALE, true)
      $Trainer.unlock_hat(DEFAULT_OUTFIT_FEMALE, true)
      $Trainer.unlock_hair(DEFAULT_OUTFIT_MALE, true)
      $Trainer.unlock_hair(DEFAULT_OUTFIT_FEMALE, true)
    end
    PlayerIdentityBedroomAddon.prompt_for_intro_hair_dye_if_needed
  end

  def isPlayerMale()
    return PlayerIdentityBedroomAddon.identity_male?($Trainer)
  end

  def isPlayerFemale()
    return PlayerIdentityBedroomAddon.identity_female?($Trainer)
  end

  def isPlayerNonbinary()
    return PlayerIdentityBedroomAddon.nonbinary?($Trainer)
  end

  def isPlayerPresentationMale()
    return PlayerIdentityBedroomAddon.presentation_male?($Trainer)
  end

  def isPlayerPresentationFemale()
    return PlayerIdentityBedroomAddon.presentation_female?($Trainer)
  end

  alias __player_identity_bedroom_pbTrainerPCMenu pbTrainerPCMenu unless defined?(__player_identity_bedroom_pbTrainerPCMenu)
  def pbTrainerPCMenu
    if !$game_map || !PlayerIdentityBedroomAddon.bedroom_map?($game_map.map_id)
      return __player_identity_bedroom_pbTrainerPCMenu()
    end
    command = 0
    loop do
      command = pbMessage(_INTL("What do you want to do?"), [
         _INTL("Item Storage"),
         _INTL("Mailbox"),
         _INTL("Change Bedroom Color"),
         _INTL("Turn Off")
         ], -1, nil, command)
      case command
      when 0 then pbPCItemStorage
      when 1 then pbPCMailbox
      when 2
        room_changed = PlayerIdentityBedroomAddon.change_bedroom_style_from_pc
        break if room_changed
      else
        break
      end
    end
  end

  if defined?(EventHandlers)
    EventHandlers.add(:on_load_save_file, :player_identity_bedroom_ensure_state) do |_save_data|
      PlayerIdentityBedroomAddon.ensure_player_state($Trainer)
    end
  end

  if defined?(obtainRocketOutfit)
    alias __player_identity_bedroom_obtainRocketOutfit obtainRocketOutfit unless defined?(__player_identity_bedroom_obtainRocketOutfit)
    def obtainRocketOutfit()
      PlayerIdentityBedroomAddon.ensure_player_state($Trainer)
      original_identity = PlayerIdentityBedroomAddon.player_identity_gender($Trainer)
      temporary_gender = PlayerIdentityBedroomAddon.player_presentation_gender($Trainer)
      pbSet(VAR_TRAINER_GENDER, temporary_gender)
      __player_identity_bedroom_obtainRocketOutfit()
      PlayerIdentityBedroomAddon.apply_identity_selection(original_identity, temporary_gender)
    end
  end

  if defined?(HOENN_RIVAL_EVENT_NAME)
    class Player
      def init_rival_appearance
        if PlayerIdentityBedroomAddon.presentation_male?(self)
          @rival_appearance = TrainerAppearance.new(
            5,
            HAT_MAY,
            CLOTHES_MAY,
            getFullHairId(HAIR_MAY, 3),
            0, 0, 0
          )
        else
          @rival_appearance = TrainerAppearance.new(
            5,
            HAT_BRENDAN,
            CLOTHES_BRENDAN,
            getFullHairId(HAIR_BRENDAN, 3),
            0, 0, 0
          )
        end
      end
    end

    def init_rival_name
      rival_name = PlayerIdentityBedroomAddon.presentation_female? ? "Brendan" : "May"
      pbSet(VAR_RIVAL_NAME, rival_name)
    end

    class Sprite_Character
      alias __player_identity_bedroom_checkModifySpriteGraphics checkModifySpriteGraphics unless method_defined?(:__player_identity_bedroom_checkModifySpriteGraphics)
      def checkModifySpriteGraphics(character)
        __player_identity_bedroom_checkModifySpriteGraphics(character)
        return if character == $game_player
        return if !$Trainer || !character.name.start_with?(HOENN_RIVAL_EVENT_NAME)
        return if character.character_name != TEMPLATE_CHARACTER_FILE
        return if !PlayerIdentityBedroomAddon.nonbinary?($Trainer)
        setSpriteToAppearance($Trainer.rival_appearance)
      end
    end

    def updateRivalTeamForSecondBattle()
      rival_trainer = $PokemonGlobal.battledTrainers[BATTLED_TRAINER_RIVAL_KEY]
      rival_starter = rival_trainer.currentTeam[0]
      rival_starter_species = rival_starter.species

      player_chosen_starter_index = pbGet(VAR_HOENN_CHOSEN_STARTER_INDEX)
      case player_chosen_starter_index
      when 0
        pokemon_species = if PlayerIdentityBedroomAddon.presentation_female?
          getFusionSpeciesSymbol(:LOTAD, rival_starter_species)
        else
          getFusionSpeciesSymbol(rival_starter_species, :SHROOMISH)
        end
      when 1
        pokemon_species = if PlayerIdentityBedroomAddon.presentation_female?
          getFusionSpeciesSymbol(:SLUGMA, rival_starter_species)
        else
          getFusionSpeciesSymbol(rival_starter_species, :NUMEL)
        end
      when 2
        pokemon_species = if PlayerIdentityBedroomAddon.presentation_female?
          getFusionSpeciesSymbol(rival_starter_species, :WINGULL)
        else
          getFusionSpeciesSymbol(:WAILMER, rival_starter_species)
        end
      end

      team = []
      team << Pokemon.new(pokemon_species, 15)

      rival_trainer.currentTeam = team
      $PokemonGlobal.battledTrainers[BATTLED_TRAINER_RIVAL_KEY] = rival_trainer
    end

    def updateRivalTeamForThirdBattle()
      rival_trainer = $PokemonGlobal.battledTrainers[BATTLED_TRAINER_RIVAL_KEY]
      rival_starter = rival_trainer.currentTeam[0]
      starter_species = rival_starter.species

      rival_starter.level = 20
      team = []
      team << rival_starter
      rival_trainer.currentTeam = team
      $PokemonGlobal.battledTrainers[BATTLED_TRAINER_RIVAL_KEY] = rival_trainer
      evolveRivalTeam

      evolution_species = rival_starter.check_evolution_on_level_up(false)
      starter_species = evolution_species if evolution_species

      player_chosen_starter_index = pbGet(VAR_HOENN_CHOSEN_STARTER_INDEX)
      case player_chosen_starter_index
      when 0
        if PlayerIdentityBedroomAddon.presentation_female?
          fire_grass_pokemon = starter_species
          water_fire_pokemon = getFusionSpeciesSymbol(:NUMEL, :WINGULL)
          water_grass_pokemon = getFusionSpeciesSymbol(:WAILMER, :SHROOMISH)
        else
          fire_grass_pokemon = starter_species
          water_fire_pokemon = getFusionSpeciesSymbol(:LOMBRE, :WINGULL)
          water_grass_pokemon = getFusionSpeciesSymbol(:SLUGMA, :WAILMER)
        end
        contains_starter = [fire_grass_pokemon]
        other_pokemon = [water_fire_pokemon, water_grass_pokemon]
      when 1
        if PlayerIdentityBedroomAddon.presentation_female?
          fire_grass_pokemon = getFusionSpeciesSymbol(:SHROOMISH, :NUMEL)
          water_fire_pokemon = getFusionSpeciesSymbol(:LOMBRE, :WAILMER)
          water_grass_pokemon = starter_species
        else
          fire_grass_pokemon = getFusionSpeciesSymbol(:LOMBRE, :SLUGMA)
          water_fire_pokemon = getFusionSpeciesSymbol(:SHROOMISH, :WINGULL)
          water_grass_pokemon = starter_species
        end
        contains_starter = [water_grass_pokemon]
        other_pokemon = [water_fire_pokemon, fire_grass_pokemon]
      when 2
        if PlayerIdentityBedroomAddon.presentation_female?
          fire_grass_pokemon = getFusionSpeciesSymbol(:SLUGMA, :SHROOMISH)
          water_fire_pokemon = starter_species
          water_grass_pokemon = getFusionSpeciesSymbol(:WAILMER, :NUMEL)
        else
          fire_grass_pokemon = getFusionSpeciesSymbol(:LOMBRE, :NUMEL)
          water_fire_pokemon = starter_species
          water_grass_pokemon = getFusionSpeciesSymbol(:SLUGMA, :WINGULL)
        end
        contains_starter = [water_fire_pokemon]
        other_pokemon = [water_grass_pokemon, fire_grass_pokemon]
      end

      team = []
      team << Pokemon.new(other_pokemon[0], 18)
      team << Pokemon.new(other_pokemon[1], 18)
      team << Pokemon.new(contains_starter[0], 20)

      rival_trainer.currentTeam = team
      $PokemonGlobal.battledTrainers[BATTLED_TRAINER_RIVAL_KEY] = rival_trainer
    end

    def initializeRivalBattledTrainer
      trainer_type = :RIVAL1
      trainer_name = PlayerIdentityBedroomAddon.presentation_male? ? "May" : "Brendan"
      trainer_appearance = $Trainer.rival_appearance
      rival_battled_trainer = BattledTrainer.new(trainer_type, trainer_name, 0, BATTLED_TRAINER_RIVAL_KEY)
      rival_battled_trainer.set_custom_appearance(trainer_appearance)
      team = []
      team << Pokemon.new(get_hoenn_rival_starter, 5)
      rival_battled_trainer.currentTeam = team
      return rival_battled_trainer
    end
  end

  class PokemonBag_Scene
    alias __player_identity_bedroom_pbRefresh pbRefresh unless method_defined?(:__player_identity_bedroom_pbRefresh)
    def pbRefresh
      __player_identity_bedroom_pbRefresh
      return if !$Trainer || !PlayerIdentityBedroomAddon.nonbinary?($Trainer)
      return if !@bag || !@sprites || !@sprites["bagsprite"]
      female_bitmap = sprintf("Graphics/Pictures/Bag/bag_#{@bag.lastpocket}_f")
      default_bitmap = sprintf("Graphics/Pictures/Bag/bag_#{@bag.lastpocket}")
      if PlayerIdentityBedroomAddon.presentation_female?($Trainer) && pbResolveBitmap(female_bitmap)
        @sprites["bagsprite"].setBitmap(female_bitmap)
      else
        @sprites["bagsprite"].setBitmap(default_bitmap)
      end
    end
  end

  class PokegearButton
    alias __player_identity_bedroom_initialize initialize unless method_defined?(:__player_identity_bedroom_initialize)
    def initialize(command, x, y, viewport = nil)
      __player_identity_bedroom_initialize(command, x, y, viewport)
      return if !$Trainer || !PlayerIdentityBedroomAddon.nonbinary?($Trainer)
      return if !PlayerIdentityBedroomAddon.presentation_female?($Trainer)
      female_button = "Graphics/Pictures/Pokegear/icon_button_f"
      return if !pbResolveBitmap(female_button)
      @button.dispose if @button && !@button.disposed?
      @button = AnimatedBitmap.new(female_button)
      refresh
    end
  end

  class PokemonPokegear_Scene
    alias __player_identity_bedroom_pbStartScene pbStartScene unless method_defined?(:__player_identity_bedroom_pbStartScene)
    def pbStartScene(commands)
      __player_identity_bedroom_pbStartScene(commands)
      return if !$Trainer || !PlayerIdentityBedroomAddon.nonbinary?($Trainer)
      return if !PlayerIdentityBedroomAddon.presentation_female?($Trainer)
      female_background = "Graphics/Pictures/Pokegear/bg_f"
      return if !pbResolveBitmap(female_background)
      @sprites["background"].setBitmap(female_background) if @sprites && @sprites["background"]
    end
  end

  alias __player_identity_bedroom_load_data load_data unless defined?(__player_identity_bedroom_load_data)
  def load_data(file_path)
    data = __player_identity_bedroom_load_data(file_path)
    normalized_path = file_path.to_s.tr("\\", "/")

    if normalized_path.end_with?("Data/CommonEvents.rxdata")
      cloned_data = Marshal.load(Marshal.dump(data))
      PlayerIdentityBedroomAddon.patch_common_events!(cloned_data)
      return cloned_data
    end

    match = normalized_path.match(/Data\/Map(\d{3})\.rxdata\z/i)
    return data if !match

    map_id = match[1].to_i
    return data if !PlayerIdentityBedroomAddon.in_memory_patchable_map_id?(map_id)

    cloned_data = Marshal.load(Marshal.dump(data))
    PlayerIdentityBedroomAddon.patch_map!(map_id, cloned_data)
    return cloned_data
  end

  PlayerIdentityBedroomAddon.apply_in_memory_patches
  puts "[PlayerIdentityBedroom] Loaded."
end
