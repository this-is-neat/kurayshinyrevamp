begin
  require 'json'
rescue LoadError
  # JSON is optional at boot; this mod now uses the game's outfit globals.
end

PC_HAIR_DYE_PRICE = 1000

# Alias the original methods
alias original_genericOutfitsShopMenu genericOutfitsShopMenu
alias original_getPresenter getPresenter
alias original_getAdapter getAdapter
alias original_list_all_possible_outfits list_all_possible_outfits
alias original_clothesShop clothesShop
alias original_hatShop hatShop
alias original_hairShop hairShop

# Custom generic shop menu
def custom_genericOutfitsShopMenu(stock = [], itemType = nil, versions = false, isShop = true, message = nil)
  if stock.nil? || stock.empty?
    pbMessage(_INTL("There is nothing available right now."))
    return false
  end

  message ||= _INTL("Welcome to Infinitely Instant Delivery! How may I serve you?")
  commands = [_INTL("Buy"), _INTL("Quit")]
  cmd = pbMessage(message, commands, commands.length)

  loop do
    if cmd == 0 # Buy
      adapter = getAdapter(itemType, stock, isShop)
      view = ClothesShopView.new
      presenter = getPresenter(itemType, view, stock, adapter, versions)
      presenter.pbBuyScreen
      return true
    else
      pbMessage(_INTL("Please use again!"))
      return false
    end
  end
end

# Custom presenter and adapter methods
def custom_getPresenter(itemType, view, stock, adapter, versions)
  case itemType
  when :HAIR then HairShopPresenter.new(view, stock, adapter, versions)
  else ClothesShopPresenter.new(view, stock, adapter, versions)
  end
end

def custom_getAdapter(itemType, stock, isShop)
  case itemType
  when :CLOTHES then ClothesMartAdapter.new(stock, isShop)
  when :HAT then HatsMartAdapter.new(stock, isShop)
  when :HAIR then HairMartAdapter.new(stock, isShop)
  end
end

def custom_outfit_collection_for_type(itemType)
  begin
    update_global_outfit_lists if respond_to?(:update_global_outfit_lists)
  rescue => error
    echoln "[PCShopping] Could not refresh outfit lists: #{error.class} - #{error.message}" if defined?(echoln)
  end

  return {} if !$PokemonGlobal

  case itemType
  when :CLOTHES then ($PokemonGlobal.clothes_data || {})
  when :HAT then ($PokemonGlobal.hats_data || {})
  when :HAIR then ($PokemonGlobal.hairstyles_data || {})
  else {}
  end
end

def custom_list_ids_for_type(itemType, only_affordable = false)
  items = custom_outfit_collection_for_type(itemType)
  return [] if items.empty?

  money = $Trainer && $Trainer.money ? $Trainer.money : 0
  ids = []

  items.each_value do |entry|
    next if !entry || !entry.respond_to?(:id)
    if only_affordable
      price = entry.respond_to?(:price) ? entry.price.to_i : 0
      next if price > money
    end
    ids << entry.id
  end

  ids.compact.uniq
end

def custom_shop_label(itemType)
  case itemType
  when :CLOTHES then _INTL("clothes")
  when :HAT then _INTL("hats")
  when :HAIR then _INTL("wigs")
  else _INTL("items")
  end
end

def custom_open_shop_for(itemType, ids)
  case itemType
  when :CLOTHES
    custom_clothesShop(ids)
  when :HAT
    custom_hatShop(ids)
  when :HAIR
    custom_hairShop(ids)
  else
    false
  end
end

def custom_browse_category_menu(itemType)
  loop do
    label = custom_shop_label(itemType)
    commands = [
      _INTL("Browse everything"),
      _INTL("Only affordable"),
      _INTL("Back")
    ]
    cmd = pbMessage(_INTL("How would you like to browse {1}?", label), commands, commands.length)
    break if cmd == 2 || cmd < 0

    ids = []
    case cmd
    when 0
      ids = custom_list_ids_for_type(itemType)
    when 1
      ids = custom_list_ids_for_type(itemType, true)
    end

    if ids.empty?
      pbMessage(_INTL("No matching {1} were found.", label))
      next
    end
    custom_open_shop_for(itemType, ids)
  end
end

# List all possible outfits
def custom_list_all_possible_outfits
  (custom_list_ids_for_type(:CLOTHES) +
   custom_list_ids_for_type(:HAT) +
   custom_list_ids_for_type(:HAIR)).uniq
end

# Shop methods
def custom_clothesShop(outfits_list = [], free = false, customMessage = nil)
  stock = outfits_list.compact.map { |id| get_clothes_by_id(id) }.compact
  if stock.empty?
    pbMessage(_INTL("No clothes are available for this selection."))
    return false
  end
  custom_genericOutfitsShopMenu(stock, :CLOTHES, false, !free, customMessage)
end

def custom_hatShop(outfits_list = [], free = false, customMessage = nil)
  stock = outfits_list.compact.map { |id| get_hat_by_id(id) }.compact
  if stock.empty?
    pbMessage(_INTL("No hats are available for this selection."))
    return false
  end
  custom_genericOutfitsShopMenu(stock, :HAT, false, !free, customMessage)
end

def custom_hairShop(outfits_list = [], free = false, customMessage = nil)
  currentHair = nil
  begin
    currentHair = getSimplifiedHairIdFromFullID($Trainer.hair) if $Trainer.hair
  rescue
    currentHair = nil
  end

  stock = [:SWAP_COLOR]
  stock << get_hair_by_id(currentHair) if $Trainer.hair
  stock += outfits_list.reject { |id| id == currentHair }.map { |id| get_hair_by_id(id) }.compact
  if stock.length <= 1
    pbMessage(_INTL("No wigs are available for this selection."))
    return false
  end
  custom_genericOutfitsShopMenu(stock, :HAIR, true, !free, customMessage)
end

def custom_buyHairDye
  if $Trainer.money < PC_HAIR_DYE_PRICE
    pbMessage(_INTL("Oh, I'm sorry but you don't have enough money."))
    return false
  end

  begin
    changed = selectHairColor
    if changed
      $Trainer.money -= PC_HAIR_DYE_PRICE
      pbMessage(_INTL("That will be ${1}. Thank you!", PC_HAIR_DYE_PRICE.to_s_formatted))
      return true
    end
    return false
  rescue NameError
    pbMessage(_INTL("Hair dye is not available right now."))
    return false
  end
end

# Infinitely Instant Delivery registration
class InfinitelyInstantDelivery
  def shouldShow?
    true
  end

  def name
    _INTL("Infinitely Instant Delivery")
  end

  def access
    pbMessage(_INTL("\\se[PC access]Accessed Infinitely Instant Delivery."))
    pbInfinitelyInstantDeliveryMenu
  end
end

def pbInfinitelyInstantDeliveryMenu
  loop do
    commands = [
      _INTL("Order Clothes"),
      _INTL("Order Hats"),
      _INTL("Order Wigs"),
      _INTL("Buy Hair Dye"),
      _INTL("Quit")
    ]
    cmd = pbMessage(_INTL("What would you like to order?"), commands, commands.length)

    case cmd
    when 0 then custom_browse_category_menu(:CLOTHES)
    when 1 then custom_browse_category_menu(:HAT)
    when 2 then custom_browse_category_menu(:HAIR)
    when 3 then custom_buyHairDye
    else break
    end
  end
end

PokemonPCList.registerPC(InfinitelyInstantDelivery.new)