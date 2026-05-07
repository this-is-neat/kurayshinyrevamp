module TravelExpansionFramework
  module_function

  def deserted_expansion_ids
    ids = []
    ids << (defined?(DESERTED_EXPANSION_ID) ? DESERTED_EXPANSION_ID : "deserted")
    ids.concat(defined?(DESERTED_LEGACY_EXPANSION_IDS) ? DESERTED_LEGACY_EXPANSION_IDS : ["pokemon_deserted"])
    return ids
  end

  def deserted_active_now?(map_id = nil)
    return !active_project_expansion_id(deserted_expansion_ids, map_id).nil? if respond_to?(:active_project_expansion_id)
    expansion = current_runtime_expansion_id if respond_to?(:current_runtime_expansion_id)
    expansion = current_expansion_marker if (expansion.nil? || expansion.to_s.empty?) && respond_to?(:current_expansion_marker)
    return deserted_expansion_ids.map(&:to_s).include?(expansion.to_s)
  rescue
    return false
  end

  def deserted_boxes_full?
    return pbBoxesFull? if defined?(pbBoxesFull?)
    party_full = $Trainer && $Trainer.respond_to?(:party_full?) && $Trainer.party_full?
    storage_full = defined?($PokemonStorage) && $PokemonStorage && $PokemonStorage.respond_to?(:full?) && $PokemonStorage.full?
    return party_full && storage_full
  rescue
    return false
  end

  def deserted_last_gift_pokemon
    return @deserted_last_gift_pokemon
  end

  def deserted_add_pokemon_safely(pkmn, level = 1, see_form = true)
    return nil if !$Trainer
    pokemon = pkmn
    pokemon = Pokemon.new(pkmn, integer(level, 1)) if defined?(Pokemon) && !pokemon.is_a?(Pokemon)
    return nil if !pokemon
    @deserted_last_gift_pokemon = pokemon
    if deserted_boxes_full?
      pbMessage(_INTL("There's no more room for Pokemon!")) if defined?(pbMessage)
      return pokemon
    end
    pokemon.record_first_moves if pokemon.respond_to?(:record_first_moves)
    if $Trainer.respond_to?(:pokedex) && $Trainer.pokedex
      $Trainer.pokedex.register(pokemon) if see_form && $Trainer.pokedex.respond_to?(:register)
      $Trainer.pokedex.set_owned(pokemon.species) if $Trainer.pokedex.respond_to?(:set_owned) && pokemon.respond_to?(:species)
    end
    if $Trainer.respond_to?(:party_full?) && $Trainer.party_full?
      if defined?($PokemonStorage) && $PokemonStorage && $PokemonStorage.respond_to?(:pbStoreCaught)
        $PokemonStorage.pbStoreCaught(pokemon)
      elsif defined?(pbStorePokemon)
        pbStorePokemon(pokemon)
      end
    else
      $Trainer.party[$Trainer.party.length] = pokemon
    end
    return pokemon
  rescue => e
    log("Deserted safe Pokemon gift failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def deserted_sanitize_script(script, map_id = nil)
    text = script.to_s
    return script if text.empty?
    return script if !deserted_active_now?(map_id)
    return script if text !~ /pbAddPokemonSilent\s*\(/ || text !~ /\$Trainer\.party\s*\[\s*0\s*\]/
    sanitized = text.gsub(/(^|\n)([ \t]*)pbAddPokemonSilent\s*\(([^)\n]*)\)[ \t]*/) do
      "#{$1}#{$2}pkmn = TravelExpansionFramework.deserted_add_pokemon_safely(#{$3})"
    end
    sanitized.gsub!(/(^|\n)([ \t]*)pkmn\s*=\s*\$Trainer\.party\s*\[\s*0\s*\][ \t]*/, "\\1\\2pkmn ||= TravelExpansionFramework.deserted_last_gift_pokemon")
    log("[deserted] rewrote empty-party Pokemon gift script for map #{map_id}") if respond_to?(:log)
    return sanitized
  rescue => e
    log("Deserted script sanitize failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return script
  end

  def deserted_resolve_item(item)
    return nil if item.nil?
    item_data = GameData::Item.try_get(item) if defined?(GameData::Item)
    return item_data.id if item_data
    if respond_to?(:ensure_external_item_registered)
      resolved = ensure_external_item_registered("deserted", item)
      item_data = GameData::Item.try_get(resolved) if resolved && defined?(GameData::Item)
      return item_data.id if item_data
      return resolved if resolved
    end
    return nil
  rescue => e
    log("Deserted item resolve failed for #{item.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def deserted_item_name(item)
    item_data = GameData::Item.try_get(item) if item && defined?(GameData::Item)
    return item_data.name if item_data && item_data.respond_to?(:name)
    return humanize_external_item_name(item) if respond_to?(:humanize_external_item_name)
    return item.to_s.gsub(/\A:/, "").split("_").map { |part| part[0] ? part[0].upcase + part[1..-1].to_s.downcase : part }.join(" ")
  rescue
    return item.to_s
  end

  def deserted_normalize_recipe(recipe)
    raw_output = (recipe[0] rescue nil)
    output = deserted_resolve_item(raw_output)
    ingredients = []
    raw_ingredients = Array(recipe[1])
    index = 0
    while index < raw_ingredients.length
      ingredient = deserted_resolve_item(raw_ingredients[index])
      quantity = integer(raw_ingredients[index + 1], 0)
      ingredients << [ingredient, quantity] if ingredient && quantity > 0
      index += 2
    end
    return nil if !output || ingredients.empty?
    return {
      :output      => output,
      :ingredients => ingredients,
      :label       => deserted_item_name(output)
    }
  rescue
    return nil
  end

  def deserted_recipe_missing_ingredients(recipe)
    return [] if !$PokemonBag || !recipe.is_a?(Hash)
    recipe[:ingredients].find_all do |ingredient, quantity|
      have = $PokemonBag.pbQuantity(ingredient) rescue 0
      have < quantity
    end
  rescue
    return recipe[:ingredients] || []
  end

  def deserted_recipe_summary(recipe)
    return "" if !recipe.is_a?(Hash)
    recipe[:ingredients].map { |ingredient, quantity| "#{quantity}x #{deserted_item_name(ingredient)}" }.join(", ")
  rescue
    return ""
  end

  def deserted_craft_recipe(recipe)
    return false if !$PokemonBag || !recipe.is_a?(Hash)
    missing = deserted_recipe_missing_ingredients(recipe)
    if !missing.empty?
      pbMessage(_INTL("You need {1}.", missing.map { |item, qty| "#{qty}x #{deserted_item_name(item)}" }.join(", "))) if defined?(pbMessage)
      return false
    end
    if $PokemonBag.respond_to?(:pbCanStore?) && !$PokemonBag.pbCanStore?(recipe[:output], 1)
      pbMessage(_INTL("The Bag is full.")) if defined?(pbMessage)
      return false
    end
    recipe[:ingredients].each { |ingredient, quantity| $PokemonBag.pbDeleteItem(ingredient, quantity) if $PokemonBag.respond_to?(:pbDeleteItem) }
    stored = $PokemonBag.pbStoreItem(recipe[:output], 1)
    if stored
      pbMessage(_INTL("You crafted {1}.", deserted_item_name(recipe[:output]))) if defined?(pbMessage)
    else
      pbMessage(_INTL("The item could not be stored.")) if defined?(pbMessage)
    end
    return stored
  rescue => e
    log("Deserted craft recipe failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def deserted_item_crafter(stock, speech1 = nil, speech2 = nil)
    recipes = Array(stock).map { |recipe| deserted_normalize_recipe(recipe) }.compact
    if recipes.empty?
      pbMessage(_INTL("There aren't any compatible recipes here yet.")) if defined?(pbMessage)
      return false
    end
    return false if defined?(pbConfirmMessage) && !pbConfirmMessage(_INTL("Would you like to craft something?"))
    pbMessage(speech1 || _INTL("Let's get started!")) if defined?(pbMessage)
    loop do
      commands = recipes.map { |recipe| recipe[:label] }
      helps = recipes.map { |recipe| _INTL("Needs: {1}", deserted_recipe_summary(recipe)) }
      commands << _INTL("Cancel")
      helps << _INTL("Stop crafting.")
      choice = pbShowCommandsWithHelp(nil, commands, helps, -1, 0) rescue pbShowCommands(nil, commands, -1)
      break if choice.nil? || choice < 0 || choice >= recipes.length
      deserted_craft_recipe(recipes[choice])
    end
    pbMessage(speech2 || _INTL("Come back soon!")) if defined?(pbMessage)
    return true
  end
end

class Interpreter
  alias tef_deserted_original_execute_script execute_script unless method_defined?(:tef_deserted_original_execute_script)
  alias tef_deserted_original_pbItemCrafter pbItemCrafter if method_defined?(:pbItemCrafter) && !method_defined?(:tef_deserted_original_pbItemCrafter)

  def execute_script(script)
    map_id = @map_id rescue ($game_map.map_id rescue nil)
    script = TravelExpansionFramework.deserted_sanitize_script(script, map_id)
    return tef_deserted_original_execute_script(script)
  end

  def pbItemCrafter(stock, speech1 = nil, speech2 = nil)
    map_id = @map_id rescue ($game_map.map_id rescue nil)
    if TravelExpansionFramework.deserted_active_now?(map_id)
      return TravelExpansionFramework.deserted_item_crafter(stock, speech1, speech2)
    end
    return tef_deserted_original_pbItemCrafter(stock, speech1, speech2) if respond_to?(:tef_deserted_original_pbItemCrafter, true)
    return TravelExpansionFramework.deserted_item_crafter(stock, speech1, speech2)
  end
end

module Kernel
  alias tef_deserted_original_kernel_pbItemCrafter pbItemCrafter if method_defined?(:pbItemCrafter) && !method_defined?(:tef_deserted_original_kernel_pbItemCrafter)

  def pbItemCrafter(stock, speech1 = nil, speech2 = nil)
    if TravelExpansionFramework.deserted_active_now?
      return TravelExpansionFramework.deserted_item_crafter(stock, speech1, speech2)
    end
    return tef_deserted_original_kernel_pbItemCrafter(stock, speech1, speech2) if respond_to?(:tef_deserted_original_kernel_pbItemCrafter, true)
    return TravelExpansionFramework.deserted_item_crafter(stock, speech1, speech2)
  end
end
