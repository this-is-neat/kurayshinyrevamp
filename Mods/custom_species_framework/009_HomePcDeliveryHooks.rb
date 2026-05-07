module CustomSpeciesFramework
  DELIVERY_QUEUE_VERSION = "1.0.0" unless const_defined?(:DELIVERY_QUEUE_VERSION)
  DELIVERY_HISTORY_LIMIT = 36 unless const_defined?(:DELIVERY_HISTORY_LIMIT)

  def self.read_delivery_queue_payload
    payload = {
      "version"    => DELIVERY_QUEUE_VERSION,
      "updated_at" => nil,
      "deliveries" => [],
      "history"    => []
    }
    return payload if !File.exist?(CREATOR_DELIVERY_FILE)
    raw = File.read(CREATOR_DELIVERY_FILE)
    raw = raw.sub(/\A\xEF\xBB\xBF/, "")
    parsed = ModManager::JSON.parse(raw)
    return payload if !parsed.is_a?(Hash)
    payload["version"] = parsed["version"].to_s if parsed["version"]
    payload["updated_at"] = parsed["updated_at"].to_s if parsed["updated_at"]
    payload["deliveries"] = parsed["deliveries"].is_a?(Array) ? parsed["deliveries"] : []
    payload["history"] = parsed["history"].is_a?(Array) ? parsed["history"] : []
    return payload
  rescue => e
    log("Failed to read creator delivery queue: #{e.message}")
    return payload
  end

  def self.write_delivery_queue_payload(payload)
    safe_payload = {
      "version"    => DELIVERY_QUEUE_VERSION,
      "updated_at" => delivery_timestamp,
      "deliveries" => payload["deliveries"].is_a?(Array) ? payload["deliveries"] : [],
      "history"    => payload["history"].is_a?(Array) ? payload["history"] : []
    }
    json = nil
    if defined?(ModManager::JSON) && ModManager::JSON.respond_to?(:generate)
      json = ModManager::JSON.generate(safe_payload)
    elsif defined?(JSON) && JSON.respond_to?(:generate)
      json = JSON.generate(safe_payload)
    end
    return false if blank?(json)
    File.open(CREATOR_DELIVERY_FILE, "wb") { |file| file.write(json) }
    return true
  rescue => e
    log("Failed to write creator delivery queue: #{e.message}")
    return false
  end

  def self.delivery_timestamp
    return Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end

  def self.pending_delivery_entries
    payload = read_delivery_queue_payload
    deliveries = payload["deliveries"].find_all { |entry|
      entry.is_a?(Hash) && entry["status"].to_s != "claimed" && entry["status"].to_s != "canceled"
    }
    return deliveries
  end

  def self.home_pc_delivery_count
    return pending_delivery_entries.length
  end

  def self.home_pc_command_label
    count = home_pc_delivery_count
    return _INTL("{1} ({2})", HOME_PC_MENU_LABEL, count) if count > 0
    return _INTL(HOME_PC_MENU_LABEL)
  end

  def self.player_home_pc_context?
    return false if !$game_map
    if defined?(PlayerIdentityBedroomAddon) &&
       PlayerIdentityBedroomAddon.respond_to?(:bedroom_map?)
      return PlayerIdentityBedroomAddon.bedroom_map?($game_map.map_id)
    end
    return true
  rescue
    return true
  end

  def self.install_home_pc_menu_patch!
    install_trainer_pc_menu_patch!
    install_counterfeit_pc_menu_patch! if defined?(CounterfeitShinies)
  end

  def self.install_trainer_pc_menu_patch!
    return if @trainer_pc_menu_patched
    Object.send(:define_method, :pbTrainerPCMenu) do
      return CustomSpeciesFramework.open_augmented_trainer_pc_menu
    end
    Object.send(:private, :pbTrainerPCMenu) rescue nil
    @trainer_pc_menu_patched = true
  rescue => e
    log("Failed to install trainer PC menu patch: #{e.message}")
  end

  def self.install_counterfeit_pc_menu_patch!
    return if @counterfeit_pc_menu_patched
    singleton = class << CounterfeitShinies; self; end
    singleton.send(:define_method, :open_bedroom_pc_menu) do
      command = 0
      loop do
        commands = []
        cmd_item_storage = commands.length
        commands << _INTL(CounterfeitShinies::Config::PC_MENU_ITEM_STORAGE)
        cmd_mailbox = commands.length
        commands << _INTL(CounterfeitShinies::Config::PC_MENU_MAILBOX)
        cmd_custom_species = commands.length
        commands << CustomSpeciesFramework.home_pc_command_label
        cmd_workshop = commands.length
        commands << _INTL(CounterfeitShinies::Config::PC_MENU_WORKSHOP)
        cmd_launder = commands.length
        commands << CounterfeitShinies.bedroom_pc_launder_label
        cmd_bedroom_color = -1
        if defined?(PlayerIdentityBedroomAddon) &&
           PlayerIdentityBedroomAddon.respond_to?(:change_bedroom_style_from_pc)
          cmd_bedroom_color = commands.length
          commands << _INTL(CounterfeitShinies::Config::PC_MENU_BEDROOM_COLOR)
        end
        cmd_turn_off = commands.length
        commands << _INTL(CounterfeitShinies::Config::PC_MENU_TURN_OFF)
        command = pbMessage(_INTL(CounterfeitShinies::Config::PC_MENU_PROMPT), commands, -1, nil, command)
        case command
        when cmd_item_storage
          pbPCItemStorage
        when cmd_mailbox
          pbPCMailbox
        when cmd_custom_species
          CustomSpeciesFramework.open_home_pc_delivery_menu
        when cmd_workshop
          CounterfeitShinies.open_workshop
        when cmd_launder
          CounterfeitShinies.open_laundry
        when cmd_bedroom_color
          room_changed = PlayerIdentityBedroomAddon.change_bedroom_style_from_pc
          break if room_changed
        when cmd_turn_off, -1
          break
        end
      end
    end
    @counterfeit_pc_menu_patched = true
  rescue => e
    log("Failed to install counterfeit PC menu patch: #{e.message}")
  end

  def self.open_augmented_trainer_pc_menu
    command = 0
    loop do
      commands = []
      cmd_item_storage = commands.length
      commands << _INTL("Item Storage")
      cmd_mailbox = commands.length
      commands << _INTL("Mailbox")
      cmd_custom_species = commands.length
      commands << home_pc_command_label
      cmd_bedroom_color = -1
      if player_home_pc_context? &&
         defined?(PlayerIdentityBedroomAddon) &&
         PlayerIdentityBedroomAddon.respond_to?(:change_bedroom_style_from_pc)
        cmd_bedroom_color = commands.length
        commands << _INTL("Change Bedroom Color")
      end
      cmd_turn_off = commands.length
      commands << _INTL("Turn Off")
      command = pbMessage(_INTL("What do you want to do?"), commands, -1, nil, command)
      case command
      when cmd_item_storage
        pbPCItemStorage
      when cmd_mailbox
        pbPCMailbox
      when cmd_custom_species
        open_home_pc_delivery_menu
      when cmd_bedroom_color
        room_changed = PlayerIdentityBedroomAddon.change_bedroom_style_from_pc
        break if room_changed
      else
        break
      end
    end
  end

  def self.open_home_pc_delivery_menu
    deliveries = pending_delivery_entries
    if deliveries.empty?
      pbMessage(_INTL("There are no custom species deliveries waiting right now."))
      return
    end

    command = 0
    loop do
      deliveries = pending_delivery_entries
      break if deliveries.empty?

      commands = deliveries.map { |delivery| delivery_menu_title(delivery) }
      cmd_claim_all = commands.length
      commands << _INTL("Claim All To Boxes")
      cmd_cancel = commands.length
      commands << _INTL("Cancel")

      command = pbMessage(_INTL("Which delivery would you like to review?"), commands, -1, nil, command)
      if command >= 0 && command < deliveries.length
        open_single_delivery_entry(deliveries[command])
      elsif command == cmd_claim_all
        claim_all_deliveries_to_boxes!
      else
        break
      end
    end
  end

  def self.delivery_menu_title(delivery)
    species_name = delivery["species_name"].to_s
    level = delivery_level(delivery)
    quantity = delivery_quantity(delivery)
    return _INTL("{1} Lv. {2} x{3}", species_name, level, quantity)
  end

  def self.open_single_delivery_entry(delivery)
    return if !delivery.is_a?(Hash)
    command = 0
    loop do
      pbMessage(delivery_summary_text(delivery))
      commands = []
      cmd_party = commands.length
      commands << _INTL("Claim To Party")
      cmd_box = commands.length
      commands << _INTL("Send To Box")
      cmd_cancel_delivery = commands.length
      commands << _INTL("Cancel Delivery")
      cmd_back = commands.length
      commands << _INTL("Back")
      command = pbShowCommands(nil, commands, -1, command)
      case command
      when cmd_party
        handled, message = claim_pending_delivery!(delivery["delivery_id"], :party)
        pbMessage(message) if !blank?(message)
        break if handled
      when cmd_box
        handled, message = claim_pending_delivery!(delivery["delivery_id"], :box)
        pbMessage(message) if !blank?(message)
        break if handled
      when cmd_cancel_delivery
        if pbConfirmMessage(_INTL("Cancel this queued delivery?"))
          handled, message = cancel_pending_delivery!(delivery["delivery_id"])
          pbMessage(message) if !blank?(message)
          break if handled
        end
      else
        break
      end
    end
  end

  def self.claim_all_deliveries_to_boxes!
    deliveries = pending_delivery_entries
    return if deliveries.empty?
    needed_slots = deliveries.inject(0) { |sum, delivery| sum + delivery_quantity(delivery) }
    if storage_free_slots < needed_slots
      pbMessage(_INTL("The Pokemon Boxes do not have enough open space for every pending delivery."))
      return
    end

    claimed = 0
    deliveries.each do |delivery|
      handled, _message = claim_pending_delivery!(delivery["delivery_id"], :box)
      claimed += 1 if handled
    end
    if claimed > 0
      pbMessage(_INTL("Sent {1} queued custom deliveries to your Pokemon Boxes.", claimed))
    else
      pbMessage(_INTL("No deliveries could be claimed right now."))
    end
  end

  def self.delivery_level(delivery)
    pokemon_payload = delivery["pokemon"].is_a?(Hash) ? delivery["pokemon"] : {}
    level = pokemon_payload["level"].to_i
    return [[level, 1].max, 100].min
  end

  def self.delivery_quantity(delivery)
    quantity = delivery["quantity"].to_i
    quantity = 1 if quantity <= 0
    return quantity
  end

  def self.delivery_summary_text(delivery)
    notes = []
    notes << _INTL("Delivery: {1}", delivery["delivery_label"].to_s) if !blank?(delivery["delivery_label"])
    notes << _INTL("Species: {1}", delivery["species_name"].to_s)
    notes << _INTL("Level: {1}", delivery_level(delivery))
    notes << _INTL("Quantity: {1}", delivery_quantity(delivery))
    pokemon_payload = delivery["pokemon"].is_a?(Hash) ? delivery["pokemon"] : {}
    notes << _INTL("Nickname: {1}", pokemon_payload["nickname"].to_s) if !blank?(pokemon_payload["nickname"])
    notes << _INTL("Held Item: {1}", pokemon_payload["held_item"].to_s) if !blank?(pokemon_payload["held_item"])
    notes << _INTL("Special Finish: Shiny") if boolean_value(pokemon_payload["shiny"], false)
    notes << delivery["message"].to_s if !blank?(delivery["message"])
    return notes.join("\n")
  end

  def self.claim_pending_delivery!(delivery_id, destination)
    return [false, _INTL("No active trainer save is loaded.")] if !$Trainer
    payload = read_delivery_queue_payload
    delivery = nil
    payload["deliveries"].each do |entry|
      next if !entry.is_a?(Hash)
      next if entry["delivery_id"].to_s != delivery_id.to_s
      delivery = entry
      break
    end
    return [false, _INTL("That delivery is no longer queued.")] if delivery.nil?

    quantity = delivery_quantity(delivery)
    if destination == :party && ($Trainer.party.length + quantity) > 6
      return [false, _INTL("Your party does not have enough room for this delivery.")]
    end
    if destination == :box && storage_free_slots < quantity
      return [false, _INTL("The Pokemon Boxes are full.")]
    end

    claimed_box_names = []
    quantity.times do
      pokemon = build_delivery_pokemon(delivery)
      return [false, _INTL("The queued species data is missing or invalid.")] if pokemon.nil?
      if destination == :party
        $Trainer.party[$Trainer.party.length] = pokemon
      else
        box_index = $PokemonStorage.pbStoreCaught(pokemon)
        return [false, _INTL("The Pokemon Boxes are full.")] if box_index.nil? || box_index < 0
        box = $PokemonStorage[box_index] rescue nil
        claimed_box_names << (box && box.respond_to?(:name) ? box.name : _INTL("Box {1}", box_index + 1))
      end
    end

    archive_delivery_entry!(payload, delivery, destination, claimed_box_names)
    write_delivery_queue_payload(payload)

    if destination == :party
      return [true, _INTL("{1} was delivered to your party.", delivery["species_name"].to_s)]
    end
    target_box = claimed_box_names.empty? ? _INTL("your Pokemon Boxes") : claimed_box_names.uniq.join(", ")
    return [true, _INTL("{1} was sent to {2}.", delivery["species_name"].to_s, target_box)]
  end

  def self.cancel_pending_delivery!(delivery_id)
    payload = read_delivery_queue_payload
    delivery = nil
    payload["deliveries"].each do |entry|
      next if !entry.is_a?(Hash)
      next if entry["delivery_id"].to_s != delivery_id.to_s
      delivery = entry
      break
    end
    return [false, _INTL("That delivery is no longer queued.")] if delivery.nil?
    archive_delivery_entry!(payload, delivery, :canceled, [])
    write_delivery_queue_payload(payload)
    return [true, _INTL("Canceled the queued delivery for {1}.", delivery["species_name"].to_s)]
  end

  def self.archive_delivery_entry!(payload, delivery, destination, claimed_box_names)
    payload["deliveries"] = payload["deliveries"].find_all { |entry|
      !entry.is_a?(Hash) || entry["delivery_id"].to_s != delivery["delivery_id"].to_s
    }
    history_entry = delivery.clone
    history_entry["status"] = (destination == :canceled) ? "canceled" : "claimed"
    history_entry["claimed_at"] = delivery_timestamp
    history_entry["claim_destination"] = destination.to_s
    history_entry["claim_boxes"] = claimed_box_names if !claimed_box_names.empty?
    payload["history"] = [] if !payload["history"].is_a?(Array)
    payload["history"].unshift(history_entry)
    payload["history"] = payload["history"][0, DELIVERY_HISTORY_LIMIT]
  end

  def self.build_delivery_pokemon(delivery)
    species = symbolize(delivery["species_id"])
    return nil if !species_reference_valid?(species)
    level = delivery_level(delivery)
    pokemon = Pokemon.new(species, level)
    pokemon_payload = delivery["pokemon"].is_a?(Hash) ? delivery["pokemon"] : {}
    nickname = pokemon_payload["nickname"].to_s
    pokemon.name = nickname if !blank?(nickname)
    held_item = symbolize(pokemon_payload["held_item"])
    begin
      pokemon.item = held_item if held_item && GameData::Item.exists?(held_item)
    rescue
    end
    pokemon.shiny = true if boolean_value(pokemon_payload["shiny"], false)
    begin
      $Trainer.pokedex.register(pokemon)
      $Trainer.pokedex.set_owned(pokemon.species)
    rescue
    end
    pokemon.record_first_moves rescue nil
    pokemon.calc_stats rescue nil
    return pokemon
  rescue => e
    log("Failed to build queued delivery Pokemon #{delivery.inspect}: #{e.message}")
    return nil
  end

  def self.storage_free_slots
    return 0 if !$PokemonStorage
    free_slots = 0
    for box_index in 0...$PokemonStorage.maxBoxes
      for slot_index in 0...PokemonBox::BOX_SIZE
        free_slots += 1 if $PokemonStorage[box_index, slot_index].nil?
      end
    end
    return free_slots
  rescue
    return 0
  end
end
