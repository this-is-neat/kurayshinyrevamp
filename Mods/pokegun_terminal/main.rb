POKEGUN_TRANQ_GUN_ID    = 1061
POKEGUN_BEAN_BAG_GUN_ID = 1062
POKEGUN_AMMO_ID         = 1063
POKEGUN_ACTUAL_GUN_ID   = 1064
POKEGUN_ACTUAL_AMMO_ID  = 1065

module PokegunTerminal
  GUN_PRICE  = 1000
  AMMO_PRICE = 50
  AMMO_ITEM  = :TRANQNBEANS
  ACTUAL_GUN_PRICE  = 3000
  ACTUAL_AMMO_PRICE = 600
  ACTUAL_AMMO_ITEM  = :ACTUALAMMO

  ITEM_DATA = {
    :TRANQGUN => {
      :id_number   => POKEGUN_TRANQ_GUN_ID,
      :name        => "Pokegun Tranq Gun",
      :name_plural => "Tranq Guns",
      :description => "A Pokegun tool that tranquilizes a wild Pokemon and puts it to sleep.",
      :icon        => "Graphics/Items/DEVOLUTIONSPRAY"
    },
    :BEANBAGGUN => {
      :id_number   => POKEGUN_BEAN_BAG_GUN_ID,
      :name        => "Pokegun Bean Bag Gun",
      :name_plural => "Bean Bag Guns",
      :description => "A Pokegun tool that leaves a wild Pokemon clinging to 1 HP.",
      :icon        => "Graphics/Items/DEVOLUTIONSPRAY"
    },
    :TRANQNBEANS => {
      :id_number   => POKEGUN_AMMO_ID,
      :name        => "Pokegun Tranq N Beans",
      :name_plural => "Tranq N Beans",
      :description => "Shared ammo for the Pokegun Tranq Gun and Pokegun Bean Bag Gun.",
      :icon        => "Graphics/Items/CHARCOAL"
    },
    :ACTUALGUN => {
      :id_number   => POKEGUN_ACTUAL_GUN_ID,
      :name        => "Pokegun Actual Gun",
      :name_plural => "Actual Guns",
      :description => "A brutally direct battle tool that instantly knocks out a wild Pokemon.",
      :icon        => "Graphics/Items/DEVOLUTIONSPRAY"
    },
    :ACTUALAMMO => {
      :id_number   => POKEGUN_ACTUAL_AMMO_ID,
      :name        => "Pokegun Actual Ammo",
      :name_plural => "Actual Ammo",
      :description => "Live ammo for the Pokegun Actual Gun.",
      :icon        => "Graphics/Items/IRONBALL"
    }
  }.freeze

  module_function

  def register_items
    ITEM_DATA.each do |item_id, data|
      is_gun = [:TRANQGUN, :BEANBAGGUN, :ACTUALGUN].include?(item_id)
      GameData::Item.register({
        :id          => item_id,
        :id_number   => data[:id_number],
        :name        => data[:name],
        :name_plural => data[:name_plural],
        :pocket      => (is_gun) ? 8 : 1,
        :price       => 0,
        :description => data[:description],
        :field_use   => 0,
        :battle_use  => (is_gun) ? 9 : 0,
        :type        => (is_gun) ? 6 : 0,
        :move        => nil
      })

      MessageTypes.set(MessageTypes::Items, data[:id_number], data[:name])
      MessageTypes.set(MessageTypes::ItemPlurals, data[:id_number], data[:name_plural])
      MessageTypes.set(MessageTypes::ItemDescriptions, data[:id_number], data[:description])
    end
  end

  def wild_target_only?(item, battler, battle, scene, show_messages)
    if !battle.wildBattle?
      scene.pbDisplay(_INTL("It won't have any effect.")) if show_messages
      return false
    end
    if !battler || battler.fainted?
      scene.pbDisplay(_INTL("But there was no target...")) if show_messages
      return false
    end
    true
  end

  def can_use_tranq_gun?(item, battler, battle, scene, show_messages)
    return false if !wild_target_only?(item, battler, battle, scene, show_messages)
    if ammo_count <= 0
      scene.pbDisplay(_INTL("You're out of Tranq N Beans!")) if show_messages
      return false
    end
    battler.pbCanSleep?(nil, show_messages)
  end

  def can_use_bean_bag_gun?(item, battler, battle, scene, show_messages)
    return false if !wild_target_only?(item, battler, battle, scene, show_messages)
    if ammo_count <= 0
      scene.pbDisplay(_INTL("You're out of Tranq N Beans!")) if show_messages
      return false
    end
    if battler.hp <= 1
      scene.pbDisplay(_INTL("It won't have any effect.")) if show_messages
      return false
    end
    true
  end

  def can_use_actual_gun?(item, battler, battle, scene, show_messages)
    return false if !wild_target_only?(item, battler, battle, scene, show_messages)
    if actual_ammo_count <= 0
      scene.pbDisplay(_INTL("You're out of Actual Ammo!")) if show_messages
      return false
    end
    true
  end

  def use_tranq_gun(battler, battle)
    battler.pbSleep
  end

  def use_bean_bag_gun(battler, battle)
    damage = battler.hp - 1
    battler.pbReduceHP(damage)
    battle.pbDisplay(_INTL("{1} was left hanging on by a thread!", battler.pbThis))
  end

  def use_actual_gun(battler, battle)
    damage = battler.hp
    battler.pbReduceHP(damage)
    battle.pbDisplay(_INTL("{1} was knocked out instantly!", battler.pbThis))
  end

  def global_tools
    $PokemonGlobal ||= PokemonGlobalMetadata.new if defined?(PokemonGlobalMetadata) && !$PokemonGlobal
    if !$PokemonGlobal.instance_variable_defined?(:@pokegun_tools)
      $PokemonGlobal.instance_variable_set(:@pokegun_tools, {})
    end
    $PokemonGlobal.instance_variable_get(:@pokegun_tools)
  end

  def tool_unlocked?(item)
    return true if $PokemonBag && $PokemonBag.pbHasItem?(item)
    return false if !$PokemonGlobal
    !!global_tools[item]
  end

  def unlock_tool(item)
    global_tools[item] = true
  end

  def ammo_count
    return 0 if !$PokemonBag
    $PokemonBag.pbQuantity(AMMO_ITEM)
  end

  def consume_ammo
    return false if !$PokemonBag
    $PokemonBag.pbDeleteItem(AMMO_ITEM)
  end

  def actual_ammo_count
    return 0 if !$PokemonBag
    $PokemonBag.pbQuantity(ACTUAL_AMMO_ITEM)
  end

  def consume_actual_ammo
    return false if !$PokemonBag
    $PokemonBag.pbDeleteItem(ACTUAL_AMMO_ITEM)
  end

  def ensure_tool_in_bag(item)
    return false if !$PokemonBag
    return true if $PokemonBag.pbHasItem?(item)
    $PokemonBag.pbStoreItem(item)
  end

  def ensure_unlocked_tools_in_bag
    unlocked_tools.each { |item| ensure_tool_in_bag(item) }
  end

  def any_tool_unlocked?
    tool_unlocked?(:TRANQGUN) || tool_unlocked?(:BEANBAGGUN) || tool_unlocked?(:ACTUALGUN)
  end

  def unlocked_tools
    tools = []
    tools << :TRANQGUN if tool_unlocked?(:TRANQGUN)
    tools << :BEANBAGGUN if tool_unlocked?(:BEANBAGGUN)
    tools << :ACTUALGUN if tool_unlocked?(:ACTUALGUN)
    tools
  end

  def unlock_tool_via_terminal(item)
    if tool_unlocked?(item)
      ensure_tool_in_bag(item)
      pbMessage(_INTL("You already own the {1}.", GameData::Item.get(item).name))
      return false
    end
    price = (item == :ACTUALGUN) ? ACTUAL_GUN_PRICE : GUN_PRICE
    if !$Trainer || $Trainer.money < price
      pbMessage(_INTL("That costs ${1}, but you don't have enough money.", price.to_s_formatted))
      return false
    end
    return false if !pbConfirmMessage(_INTL("Buy the {1} for ${2}?",
      GameData::Item.get(item).name, price.to_s_formatted))
    $Trainer.money -= price
    unlock_tool(item)
    pbReceiveItem(item)
    true
  end

  def buy_ammo
    if !$Trainer || $Trainer.money < AMMO_PRICE
      pbMessage(_INTL("That costs ${1}, but you don't have enough money.", AMMO_PRICE.to_s_formatted))
      return false
    end
    maxafford = $Trainer.money / AMMO_PRICE
    maxafford = Settings::BAG_MAX_PER_SLOT if maxafford > Settings::BAG_MAX_PER_SLOT
    current_qty = ammo_count
    max_by_bag = Settings::BAG_MAX_PER_SLOT - current_qty
    maxafford = max_by_bag if maxafford > max_by_bag
    if maxafford <= 0 || !$PokemonBag.pbCanStore?(AMMO_ITEM, 1)
      pbMessage(_INTL("You have no more room in the Bag."))
      return false
    end

    quantity = 0
    msgwindow = pbCreateMessageWindow
    begin
      pbMessageDisplay(msgwindow,
        _INTL("{1}? Certainly. How many would you like?", GameData::Item.get(AMMO_ITEM).name),
        false)
      params = ChooseNumberParams.new
      params.setRange(1, maxafford)
      params.setInitialValue(1)
      params.setCancelValue(0)
      quantity = pbChooseNumber(msgwindow, params)
    ensure
      pbDisposeMessageWindow(msgwindow)
    end
    return false if quantity <= 0

    total_price = AMMO_PRICE * quantity
    return false if !pbConfirmMessage(_INTL("{1}, and you want {2}. That will be ${3}. OK?",
      GameData::Item.get(AMMO_ITEM).name, quantity, total_price.to_s_formatted))
    if !$Trainer || $Trainer.money < total_price
      pbMessage(_INTL("You don't have enough money."))
      return false
    end
    if !$PokemonBag.pbCanStore?(AMMO_ITEM, quantity)
      pbMessage(_INTL("You have no more room in the Bag."))
      return false
    end

    $Trainer.money -= total_price
    pbReceiveItem(AMMO_ITEM, quantity)
    true
  end

  def buy_actual_ammo
    if !$Trainer || $Trainer.money < ACTUAL_AMMO_PRICE
      pbMessage(_INTL("That costs ${1}, but you don't have enough money.", ACTUAL_AMMO_PRICE.to_s_formatted))
      return false
    end
    maxafford = $Trainer.money / ACTUAL_AMMO_PRICE
    maxafford = Settings::BAG_MAX_PER_SLOT if maxafford > Settings::BAG_MAX_PER_SLOT
    current_qty = actual_ammo_count
    max_by_bag = Settings::BAG_MAX_PER_SLOT - current_qty
    maxafford = max_by_bag if maxafford > max_by_bag
    if maxafford <= 0 || !$PokemonBag.pbCanStore?(ACTUAL_AMMO_ITEM, 1)
      pbMessage(_INTL("You have no more room in the Bag."))
      return false
    end

    quantity = 0
    msgwindow = pbCreateMessageWindow
    begin
      pbMessageDisplay(msgwindow,
        _INTL("{1}? Certainly. How many would you like?", GameData::Item.get(ACTUAL_AMMO_ITEM).name),
        false)
      params = ChooseNumberParams.new
      params.setRange(1, maxafford)
      params.setInitialValue(1)
      params.setCancelValue(0)
      quantity = pbChooseNumber(msgwindow, params)
    ensure
      pbDisposeMessageWindow(msgwindow)
    end
    return false if quantity <= 0

    total_price = ACTUAL_AMMO_PRICE * quantity
    return false if !pbConfirmMessage(_INTL("{1}, and you want {2}. That will be ${3}. OK?",
      GameData::Item.get(ACTUAL_AMMO_ITEM).name, quantity, total_price.to_s_formatted))
    if !$Trainer || $Trainer.money < total_price
      pbMessage(_INTL("You don't have enough money."))
      return false
    end
    if !$PokemonBag.pbCanStore?(ACTUAL_AMMO_ITEM, quantity)
      pbMessage(_INTL("You have no more room in the Bag."))
      return false
    end

    $Trainer.money -= total_price
    pbReceiveItem(ACTUAL_AMMO_ITEM, quantity)
    true
  end

  def show_pokegun_info
    pbMessage(_INTL("Pokegun Tranq Gun: Puts the targeted wild Pokemon to sleep."))
    pbMessage(_INTL("Pokegun Bean Bag Gun: Drops the targeted wild Pokemon to 1 HP without knocking it out."))
    pbMessage(_INTL("Pokegun Tranq N Beans are shared ammo for both guns, and 1 round is spent each time a shot lands."))
    pbMessage(_INTL("Pokegun Actual Gun: Instantly knocks out the targeted wild Pokemon and uses Pokegun Actual Ammo."))
  end
end

module GameData
  class << self
    unless method_defined?(:pokegun_terminal_original_load_all)
      alias pokegun_terminal_original_load_all load_all
      def load_all
        pokegun_terminal_original_load_all
        PokegunTerminal.register_items
      end
    end
  end

end

module PokegunTerminalItemClassPatch
  def icon_filename(item)
    item_id = GameData::Item.try_get(item)&.id
    data = PokegunTerminal::ITEM_DATA[item_id]
    return data[:icon] if data
    super
  end

  def held_icon_filename(item)
    item_id = GameData::Item.try_get(item)&.id
    data = PokegunTerminal::ITEM_DATA[item_id]
    return data[:icon] if data
    super
  end
end

GameData::Item.singleton_class.prepend(PokegunTerminalItemClassPatch) unless GameData::Item.singleton_class.ancestors.include?(PokegunTerminalItemClassPatch)

PokegunTerminal.register_items

module PBItems
  TRANQGUN    = POKEGUN_TRANQ_GUN_ID unless const_defined?(:TRANQGUN)
  BEANBAGGUN  = POKEGUN_BEAN_BAG_GUN_ID unless const_defined?(:BEANBAGGUN)
  TRANQNBEANS = POKEGUN_AMMO_ID unless const_defined?(:TRANQNBEANS)
  ACTUALGUN   = POKEGUN_ACTUAL_GUN_ID unless const_defined?(:ACTUALGUN)
  ACTUALAMMO  = POKEGUN_ACTUAL_AMMO_ID unless const_defined?(:ACTUALAMMO)
end

ItemHandlers::CanUseInBattle.add(:TRANQGUN, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  next PokegunTerminal.can_use_tranq_gun?(item, battler, battle, scene, showMessages)
})

ItemHandlers::CanUseInBattle.add(:BEANBAGGUN, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  next PokegunTerminal.can_use_bean_bag_gun?(item, battler, battle, scene, showMessages)
})

ItemHandlers::CanUseInBattle.add(:ACTUALGUN, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  next PokegunTerminal.can_use_actual_gun?(item, battler, battle, scene, showMessages)
})

ItemHandlers::UseInBattle.add(:TRANQGUN, proc { |item, battler, battle|
  PokegunTerminal.use_tranq_gun(battler, battle)
})

ItemHandlers::UseInBattle.add(:BEANBAGGUN, proc { |item, battler, battle|
  PokegunTerminal.use_bean_bag_gun(battler, battle)
})

ItemHandlers::UseInBattle.add(:ACTUALGUN, proc { |item, battler, battle|
  PokegunTerminal.use_actual_gun(battler, battle)
})

module PokegunTerminalBattlePatch
  def pbUsePokeBallInBattle(item, idxBattler, userBattler)
    if [:TRANQGUN, :BEANBAGGUN, :ACTUALGUN].include?(item)
      trainerName = pbGetOwnerName(userBattler.index)
      pbUseItemMessage(item, trainerName)
      battler = (idxBattler < 0) ? userBattler.pbDirectOpposing(true) : @battlers[idxBattler]
      pkmn = battler&.pokemon
      ch = @choices[userBattler.index]
      if battler && pkmn &&
         ItemHandlers.triggerCanUseInBattle(item, pkmn, battler, ch[3], true, self, @scene, false)
        ItemHandlers.triggerUseInBattle(item, battler, self)
        if item == :ACTUALGUN
          PokegunTerminal.consume_actual_ammo
        else
          PokegunTerminal.consume_ammo
        end
        ch[1] = nil
        return
      end
      pbDisplay(_INTL("But it had no effect!"))
      pbReturnUnusedItemToBag(item, userBattler.index)
      return
    end
    super
  end
end

PokeBattle_Battle.prepend(PokegunTerminalBattlePatch) unless PokeBattle_Battle.ancestors.include?(PokegunTerminalBattlePatch)

class PokegunTerminalPC
  def shouldShow?
    true
  end

  def name
    _INTL("Pokegun Terminal")
  end

  def access
    PokegunTerminal.ensure_unlocked_tools_in_bag
    pbMessage(_INTL("\\se[PC access]Accessed the Pokegun Terminal."))
    pbPokegunTerminalMenu
  end
end

def pbPokegunTerminalMenu
  loop do
    commands = [
      _INTL("Buy Pokegun Tranq Gun (${1})", PokegunTerminal::GUN_PRICE.to_s_formatted),
      _INTL("Buy Pokegun Bean Bag Gun (${1})", PokegunTerminal::GUN_PRICE.to_s_formatted),
      _INTL("Buy Pokegun Actual Gun (${1})", PokegunTerminal::ACTUAL_GUN_PRICE.to_s_formatted),
      _INTL("Buy Pokegun Tranq N Beans (${1})", PokegunTerminal::AMMO_PRICE.to_s_formatted),
      _INTL("Buy Pokegun Actual Ammo (${1})", PokegunTerminal::ACTUAL_AMMO_PRICE.to_s_formatted),
      _INTL("How They Work"),
      _INTL("Quit")
    ]
    cmd = pbMessage(_INTL("What Pokegun gear would you like to purchase?"), commands, commands.length)

    case cmd
    when 0
      PokegunTerminal.unlock_tool_via_terminal(:TRANQGUN)
    when 1
      PokegunTerminal.unlock_tool_via_terminal(:BEANBAGGUN)
    when 2
      PokegunTerminal.unlock_tool_via_terminal(:ACTUALGUN)
    when 3
      PokegunTerminal.buy_ammo
    when 4
      PokegunTerminal.buy_actual_ammo
    when 5
      PokegunTerminal.show_pokegun_info
    else
      break
    end
  end
end

PokemonPCList.registerPC(PokegunTerminalPC.new)
