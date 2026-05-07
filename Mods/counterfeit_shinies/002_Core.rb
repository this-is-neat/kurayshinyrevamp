class Pokemon
  attr_accessor :counterfeit_shiny_data

  alias counterfeit_shinies_existing_superHue superHue if method_defined?(:superHue)
  def superHue
    hue = nil
    hue = CounterfeitShinies.super_hue_for(self) if defined?(CounterfeitShinies)
    return hue if !hue.nil?
    return counterfeit_shinies_existing_superHue if defined?(counterfeit_shinies_existing_superHue)
    return nil
  end
end

class PokemonGlobalMetadata
  attr_accessor :counterfeit_shiny_state
end

class PokemonTemp
  attr_accessor :counterfeit_shiny_context
  attr_accessor :counterfeit_shiny_chase
  attr_accessor :counterfeit_shiny_offer_cooldowns
  attr_accessor :counterfeit_shiny_dialogue_buffers
  attr_accessor :counterfeit_shiny_dialogue_memory
end

class CounterfeitEnforcerChaser < Game_Character
  def initialize(map, x, y, character_name)
    super(map)
    @id = 0
    @original_x = x
    @original_y = y
    moveto(x, y)
    @character_name = character_name.to_s
    @character_hue = 0
    self.move_speed = CounterfeitShinies::Config::ENFORCER_CHASE_SPEED
    self.move_frequency = 6
    @move_type = 2
    @walk_anime = true
    @step_anime = false
    @through = false
    @transparent = false
  end

  def active?
    return true
  end

  def name
    return "counterfeit_enforcer"
  end

  def pbCheckEventTriggerAfterTurning
    # The chase sprite is a free-floating overworld pursuer, not a map event.
  end

  def check_event_trigger_touch(_dir)
    # Touch-trigger logic is handled by the chase controller, not the engine's event hooks.
  end

  def update
    super
    return if !$game_player
    return if moving? || jumping?
    return if @wait_count.to_i > 0
    move_toward_player
  end
end

module CounterfeitShinies
  module_function

  def default_palette_favorites
    return Array.new(Config::PALETTE_FAVORITE_SLOTS) { nil }
  end

  def default_global_state
    return {
      :next_id           => 1,
      :heat              => 0,
      :step_meter        => 0,
      :encounters        => 0,
      :enforcer_stage    => 0,
      :wins              => 0,
      :losses            => 0,
      :level_cap_wins    => 0,
      :laundered         => 0,
      :laundering_tokens => 0,
      :gross_profit      => 0,
      :lifetime_sales    => 0,
      :buyer_history     => {},
      :last_confiscated  => nil,
      :palette_favorites => default_palette_favorites
    }
  end

  def global_state
    return default_global_state if !$PokemonGlobal
    $PokemonGlobal.counterfeit_shiny_state = default_global_state if !$PokemonGlobal.counterfeit_shiny_state.is_a?(Hash)
    base = default_global_state
    base.each_pair do |key, value|
      next if $PokemonGlobal.counterfeit_shiny_state.key?(key)
      $PokemonGlobal.counterfeit_shiny_state[key] = deep_clone(value)
    end
    return $PokemonGlobal.counterfeit_shiny_state
  end

  def deep_clone(value)
    return Marshal.load(Marshal.dump(value))
  rescue
    case value
    when Hash
      ret = {}
      value.each_pair { |k, v| ret[k] = deep_clone(v) }
      return ret
    when Array
      return value.map { |v| deep_clone(v) }
    else
      return value
    end
  end

  def counterfeit_data_for(pokemon)
    return nil if !pokemon || !pokemon.respond_to?(:counterfeit_shiny_data)
    return nil if !pokemon.counterfeit_shiny_data.is_a?(Hash)
    data = pokemon.counterfeit_shiny_data
    data[:enabled] = true if data[:enabled].nil? && data[:counterfeit_shiny]
    return nil if !data[:enabled]
    ensure_data_defaults!(pokemon)
    return pokemon.counterfeit_shiny_data
  end

  def counterfeit?(pokemon)
    return !counterfeit_data_for(pokemon).nil?
  end

  def external_fake_shiny?(pokemon)
    return false if !pokemon
    return false if counterfeit?(pokemon)
    return pokemon.respond_to?(:fakeshiny?) && pokemon.fakeshiny?
  end

  def true_shiny?(pokemon)
    return false if !pokemon || !pokemon.respond_to?(:shiny?)
    return pokemon.shiny?
  end

  def render_fake_shiny?(pokemon)
    return false if !pokemon
    return pokemon.respond_to?(:fakeshiny?) && pokemon.fakeshiny?
  end

  def render_shiny_in_ui?(pokemon)
    return true_shiny?(pokemon) || render_fake_shiny?(pokemon)
  end

  def shiny_star_payload(pokemon)
    return [0, 0, 0, 0] if !pokemon
    return [pokemon.shinyR?, pokemon.shinyG?, pokemon.shinyB?, pokemon.shinyKRS?]
  end

  def laundering_token_count
    return global_state[:laundering_tokens].to_i
  end

  def grant_laundering_tokens(amount = Config::LEVEL_CAP_REWARD_TOKENS)
    amount = amount.to_i
    return 0 if amount <= 0
    global_state[:laundering_tokens] += amount
    return amount
  end

  def spend_laundering_token(amount = 1)
    amount = amount.to_i
    return false if amount <= 0
    return false if laundering_token_count < amount
    global_state[:laundering_tokens] -= amount
    global_state[:laundering_tokens] = 0 if global_state[:laundering_tokens] < 0
    return true
  end

  def owned_pokemon_count
    count = 0
    each_owned_reference(true, true) { |_ref| count += 1 }
    return count
  end

  def remaining_owned_pokemon_count(except_pokemon)
    count = 0
    each_owned_reference(true, true) do |ref|
      next if ref[:pokemon].equal?(except_pokemon)
      next if ref[:pokemon].respond_to?(:egg?) && ref[:pokemon].egg?
      count += 1
    end
    return count
  end

  def safe_to_remove_entire_pokemon?(pokemon)
    return remaining_owned_pokemon_count(pokemon) > 0
  end

  def ensure_data_defaults!(pokemon)
    return nil if !pokemon
    pokemon.counterfeit_shiny_data = {} if !pokemon.counterfeit_shiny_data.is_a?(Hash)
    data = pokemon.counterfeit_shiny_data
    data[:enabled] = true if data[:enabled].nil?
    data[:version] = DATA_VERSION if !data[:version]
    data[:id] = next_counterfeit_id if !data[:id]
    data[:created_frame] = Graphics.frame_count if !data[:created_frame]
    data[:created_step] = ($PokemonGlobal ? $PokemonGlobal.stepcount : 0) if !data[:created_step]
    data[:created_map] = ($game_map ? $game_map.map_id : 0) if !data[:created_map]
    data[:created_source] = Config::DEFAULT_SOURCE if !data[:created_source]
    data[:sale_bonus] = 0 if data[:sale_bonus].nil?
    data[:enforcer_wins] = 0 if data[:enforcer_wins].nil?
    data[:battle_uses] = 0 if data[:battle_uses].nil?
    data[:peak_heat] = 0 if data[:peak_heat].nil?
    data[:notoriety] = 0 if data[:notoriety].nil?
    data[:status] = :owned if !data[:status]
    data[:last_sale_value] = 0 if data[:last_sale_value].nil?
    ensure_palette_defaults!(pokemon)
    return data
  end

  def ensure_palette_defaults!(pokemon)
    return if !pokemon
    pokemon.fakeshiny = true
    pokemon.shinyValue = sanitize_hue(pokemon.shinyValue?)
    pokemon.shinyR = sanitize_channel(pokemon.shinyR?)
    pokemon.shinyG = sanitize_channel(pokemon.shinyG?)
    pokemon.shinyB = sanitize_channel(pokemon.shinyB?)
    pokemon.shinyKRS = sanitize_krs(pokemon.shinyKRS?)
    pokemon.shinyimprovpif = sanitize_style(pokemon.shinyimprovpif?)
  end

  def sanitize_hue(value)
    value = value.to_i
    value = Config::HUE_MIN if value < Config::HUE_MIN
    value = Config::HUE_MAX if value > Config::HUE_MAX
    return value
  end

  def sanitize_channel(value)
    value = value.to_i
    min = Config::CHANNEL_MIN
    max = Config.channel_cap
    value = min if value < min
    value = max if value > max
    return value
  end

  def sanitize_boost(value)
    value = value.to_i
    value = Config::BOOST_MIN if value < Config::BOOST_MIN
    value = Config::BOOST_MAX if value > Config::BOOST_MAX
    return value
  end

  def sanitize_style(value)
    value = value.to_i
    value = 0 if value < 0
    value = 3 if value > 3
    return value
  end

  def sanitize_krs(values)
    values = deep_clone(values || [])
    values = [] if !values.is_a?(Array)
    values += Config::DEFAULT_KRS if values.length < Config::DEFAULT_KRS.length
    ret = values[0, Config::DEFAULT_KRS.length]
    3.times { |i| ret[i] = sanitize_boost(ret[i]) }
    (3...6).each do |i|
      ret[i] = ret[i].to_i
      ret[i] = 0 if ret[i] < 0
      ret[i] = 4 if ret[i] > 4
    end
    (6...9).each do |i|
      ret[i] = ret[i].to_i
      ret[i] = 0 if ret[i] < 0
      ret[i] = 2 if ret[i] > 2
    end
    return ret
  end

  def next_counterfeit_id
    state = global_state
    next_id = state[:next_id].to_i
    next_id = 1 if next_id <= 0
    state[:next_id] = next_id + 1
    return next_id
  end

  def capture_visual_state(pokemon)
    return nil if !pokemon
    return {
      :shiny          => pokemon.shiny?,
      :debug_shiny    => pokemon.debug_shiny,
      :natural_shiny  => pokemon.natural_shiny,
      :fakeshiny      => pokemon.fakeshiny,
      :shinyValue     => pokemon.shinyValue?,
      :shinyR         => pokemon.shinyR?,
      :shinyG         => pokemon.shinyG?,
      :shinyB         => pokemon.shinyB?,
      :shinyKRS       => deep_clone(pokemon.shinyKRS?),
      :shinyimprovpif => pokemon.shinyimprovpif?
    }
  end

  def capture_palette_state(pokemon)
    return nil if !pokemon
    return normalize_palette({
      :shinyValue     => pokemon.shinyValue?,
      :shinyR         => pokemon.shinyR?,
      :shinyG         => pokemon.shinyG?,
      :shinyB         => pokemon.shinyB?,
      :shinyKRS       => pokemon.shinyKRS?,
      :shinyimprovpif => pokemon.shinyimprovpif?
    })
  end

  def apply_visual_state!(pokemon, snapshot)
    return if !pokemon || !snapshot
    pokemon.shiny = snapshot[:shiny]
    pokemon.debug_shiny = snapshot[:debug_shiny]
    pokemon.natural_shiny = snapshot[:natural_shiny]
    pokemon.fakeshiny = snapshot[:fakeshiny]
    pokemon.shinyValue = snapshot[:shinyValue]
    pokemon.shinyR = snapshot[:shinyR]
    pokemon.shinyG = snapshot[:shinyG]
    pokemon.shinyB = snapshot[:shinyB]
    pokemon.shinyKRS = deep_clone(snapshot[:shinyKRS])
    pokemon.shinyimprovpif = snapshot[:shinyimprovpif]
  end

  def restore_visual_state(pokemon, snapshot)
    apply_visual_state!(pokemon, snapshot)
  end

  def default_palette
    return normalize_palette({
      :shinyValue     => rand(Config::HUE_MIN..Config::HUE_MAX),
      :shinyR         => rand(Config::CHANNEL_MIN..Config.channel_cap),
      :shinyG         => rand(Config::CHANNEL_MIN..Config.channel_cap),
      :shinyB         => rand(Config::CHANNEL_MIN..Config.channel_cap),
      :shinyKRS       => [
        rand(Config::BOOST_MIN..Config::BOOST_MAX),
        rand(Config::BOOST_MIN..Config::BOOST_MAX),
        rand(Config::BOOST_MIN..Config::BOOST_MAX),
        0, 0, 0, 0, 0, 0
      ],
      :shinyimprovpif => Config::DEFAULT_SHINY_STYLE
    })
  end

  def normalize_palette(palette)
    return nil if !palette.is_a?(Hash)
    return {
      :shinyValue     => sanitize_hue(palette[:shinyValue]),
      :shinyR         => sanitize_channel(palette[:shinyR]),
      :shinyG         => sanitize_channel(palette[:shinyG]),
      :shinyB         => sanitize_channel(palette[:shinyB]),
      :shinyKRS       => sanitize_krs(palette[:shinyKRS]),
      :shinyimprovpif => sanitize_style(palette[:shinyimprovpif])
    }
  end

  def apply_palette!(pokemon, palette)
    return if !pokemon
    palette = normalize_palette(palette)
    palette = default_palette if !palette
    pokemon.fakeshiny = true
    pokemon.shinyValue = sanitize_hue(palette[:shinyValue])
    pokemon.shinyR = sanitize_channel(palette[:shinyR])
    pokemon.shinyG = sanitize_channel(palette[:shinyG])
    pokemon.shinyB = sanitize_channel(palette[:shinyB])
    pokemon.shinyKRS = sanitize_krs(palette[:shinyKRS])
    pokemon.shinyimprovpif = sanitize_style(palette[:shinyimprovpif])
  end

  def apply_counterfeit!(pokemon, palette = nil, source = Config::DEFAULT_SOURCE)
    return false if !pokemon
    ensure_data_defaults!(pokemon)
    apply_palette!(pokemon, palette || {
      :shinyValue     => pokemon.shinyValue?,
      :shinyR         => pokemon.shinyR?,
      :shinyG         => pokemon.shinyG?,
      :shinyB         => pokemon.shinyB?,
      :shinyKRS       => pokemon.shinyKRS?,
      :shinyimprovpif => pokemon.shinyimprovpif?
    })
    data = pokemon.counterfeit_shiny_data
    data[:enabled] = true
    data[:version] = DATA_VERSION
    data[:created_source] = source if data[:created_source].nil? || data[:status] != :owned
    data[:status] = :owned
    data[:created_step] = ($PokemonGlobal ? $PokemonGlobal.stepcount : 0) if !data[:created_step]
    data[:created_frame] = Graphics.frame_count if !data[:created_frame]
    data[:created_map] = ($game_map ? $game_map.map_id : 0) if !data[:created_map]
    return true
  end

  def palette_favorites
    favorites = global_state[:palette_favorites]
    favorites = default_palette_favorites if !favorites.is_a?(Array)
    favorites = favorites[0, Config::PALETTE_FAVORITE_SLOTS]
    while favorites.length < Config::PALETTE_FAVORITE_SLOTS
      favorites << nil
    end
    favorites.each_with_index do |entry, index|
      favorites[index] = normalize_palette_favorite(entry)
    end
    global_state[:palette_favorites] = favorites
    return favorites
  end

  def normalize_palette_favorite(entry)
    return nil if !entry
    raw_palette = nil
    label = ""
    if entry.is_a?(Hash) && entry[:palette].is_a?(Hash)
      raw_palette = entry[:palette]
      label = entry[:label].to_s
    elsif entry.is_a?(Hash) && entry.key?(:shinyValue)
      raw_palette = entry
    else
      return nil
    end
    palette = normalize_palette(raw_palette)
    return nil if !palette
    label = "Saved Finish" if label.strip.empty?
    return {
      :label   => label,
      :palette => palette
    }
  end

  def palette_favorite(slot)
    slot = slot.to_i
    return nil if slot < 0 || slot >= Config::PALETTE_FAVORITE_SLOTS
    return palette_favorites[slot]
  end

  def favorite_fill_count
    count = 0
    palette_favorites.each { |entry| count += 1 if entry }
    return count
  end

  def favorite_label_for(pokemon)
    return "Saved Finish" if !pokemon
    species = pokemon.speciesName.to_s.strip
    name = pokemon.name.to_s.strip
    return species if name.empty?
    return name if species.empty?
    return species if name.downcase == species.downcase
    return "#{name} (#{species})"
  end

  def save_palette_favorite(slot, pokemon)
    slot = slot.to_i
    return false if slot < 0 || slot >= Config::PALETTE_FAVORITE_SLOTS
    palette = capture_palette_state(pokemon)
    return false if !palette
    palette_favorites[slot] = {
      :label   => favorite_label_for(pokemon),
      :palette => palette
    }
    return true
  end

  def apply_palette_favorite!(pokemon, slot)
    entry = palette_favorite(slot)
    return false if !pokemon || !entry
    apply_palette!(pokemon, entry[:palette])
    return true
  end

  def palette_signature(palette)
    palette = normalize_palette(palette)
    return "No finish data" if !palette
    boosts = sanitize_krs(palette[:shinyKRS])
    style = Config::SHINY_STYLE_NAMES[sanitize_style(palette[:shinyimprovpif])]
    return _INTL(
      "Hue {1} / RGB {2}-{3}-{4} / Boost {5}-{6}-{7} / {8}",
      palette[:shinyValue], palette[:shinyR], palette[:shinyG], palette[:shinyB],
      boosts[0], boosts[1], boosts[2], style
    )
  end

  def palette_favorite_command_text(slot)
    entry = palette_favorite(slot)
    return _INTL("Slot {1}: Empty", slot + 1) if !entry
    return _INTL("Slot {1}: {2}", slot + 1, entry[:label])
  end

  def clear_counterfeit!(pokemon)
    return false if !pokemon
    return false if !counterfeit?(pokemon)
    pokemon.counterfeit_shiny_data = nil
    pokemon.fakeshiny = false if pokemon.respond_to?(:fakeshiny=)
    return true
  end

  def stripped_or_confiscated!(pokemon, reason)
    return if !pokemon
    data = counterfeit_data_for(pokemon)
    return if !data
    data[:status] = reason
  end

  def super_hue_for(pokemon)
    return nil if !counterfeit?(pokemon)
    return sanitize_hue(pokemon.shinyValue?)
  end

  def eligible_for_workshop?(pokemon)
    return false if !pokemon
    return true if counterfeit?(pokemon)
    return false if pokemon.egg?
    return false if pokemon.respond_to?(:shadowPokemon?) && pokemon.shadowPokemon?
    return false if true_shiny?(pokemon)
    return false if external_fake_shiny?(pokemon)
    return true
  end

  def eligible_for_sale?(pokemon)
    return false if !counterfeit?(pokemon)
    ref = find_owned_reference(pokemon, true, false)
    return false if !ref
    return false if ref[:location] == :daycare
    return true
  end

  def each_owned_reference(include_storage = true, include_daycare = true)
    return if !$Trainer
    $Trainer.party.each_with_index do |pokemon, index|
      next if !pokemon
      yield({ :pokemon => pokemon, :location => :party, :index => index, :box => -1, :slot => nil })
    end
    if include_storage && $PokemonStorage
      0.upto($PokemonStorage.maxBoxes - 1) do |box|
        0.upto($PokemonStorage.maxPokemon(box) - 1) do |index|
          pokemon = $PokemonStorage[box, index]
          next if !pokemon
          yield({
            :pokemon  => pokemon,
            :location => :pc,
            :index    => index,
            :box      => box,
            :slot     => nil
          })
        end
      end
    end
    if include_daycare && Config::ALLOW_DAYCARE_STORAGE && $PokemonGlobal && $PokemonGlobal.daycare
      $PokemonGlobal.daycare.each_with_index do |entry, slot|
        pokemon = entry[0]
        next if !pokemon
        yield({
          :pokemon  => pokemon,
          :location => :daycare,
          :index    => nil,
          :box      => nil,
          :slot     => slot
        })
      end
    end
  end

  def find_owned_reference(target_pokemon, include_storage = true, include_daycare = true)
    ret = nil
    each_owned_reference(include_storage, include_daycare) do |ref|
      if ref[:pokemon].equal?(target_pokemon)
        ret = ref
        break
      end
    end
    return ret
  end

  def workshop_candidates
    ret = []
    each_owned_reference(true, false) do |ref|
      ret << ref if eligible_for_workshop?(ref[:pokemon])
    end
    ret.sort_by! do |ref|
      [
        (ref[:location] == :party) ? 0 : 1,
        ref[:box] || 0,
        ref[:index] || 0,
        ref[:pokemon].level * -1
      ]
    end
    return ret
  end

  def sale_candidates
    ret = []
    each_owned_reference(true, false) do |ref|
      ret << ref if counterfeit?(ref[:pokemon])
    end
    ret.sort_by! do |ref|
      [
        -market_value(ref[:pokemon]),
        (ref[:location] == :party) ? 0 : 1,
        ref[:box] || 0,
        ref[:index] || 0
      ]
    end
    return ret
  end

  def laundering_candidates
    ret = []
    each_owned_reference(true, false) do |ref|
      ret << ref if counterfeit?(ref[:pokemon])
    end
    ret.sort_by! do |ref|
      [
        (ref[:location] == :party) ? 0 : 1,
        -market_value(ref[:pokemon]),
        ref[:box] || 0,
        ref[:index] || 0
      ]
    end
    return ret
  end

  def party_sale_candidates
    ret = []
    return ret if !$Trainer
    $Trainer.party.each_with_index do |pokemon, index|
      next if !counterfeit?(pokemon)
      ret << { :pokemon => pokemon, :index => index }
    end
    ret.sort_by! do |ref|
      [
        -market_value(ref[:pokemon]),
        counterfeit_data_for(ref[:pokemon])[:created_step].to_i,
        ref[:index].to_i
      ]
    end
    return ret
  end

  def party_counterfeits
    ret = []
    return ret if !$Trainer
    $Trainer.party.each_with_index do |pokemon, index|
      next if !counterfeit?(pokemon)
      ret << { :pokemon => pokemon, :index => index }
    end
    return ret
  end

  def spotlight_counterfeit
    ret = party_counterfeits
    return nil if ret.empty?
    ret.sort_by! do |ref|
      data = counterfeit_data_for(ref[:pokemon])
      [
        -market_value(ref[:pokemon]),
        data[:created_step].to_i,
        ref[:index].to_i
      ]
    end
    return ret.first[:pokemon]
  end

  def spotlight_counterfeit_id
    pokemon = spotlight_counterfeit
    return nil if !pokemon
    return counterfeit_data_for(pokemon)[:id]
  end

  def location_text(ref)
    return "Party ##{ref[:index] + 1}" if ref[:location] == :party
    return "Box #{ref[:box] + 1}, Slot #{ref[:index] + 1}" if ref[:location] == :pc
    return "Day Care #{ref[:slot] + 1}" if ref[:location] == :daycare
    return "Unknown"
  end

  def short_location_text(ref)
    return "Party" if ref[:location] == :party
    return "Box #{ref[:box] + 1}" if ref[:location] == :pc
    return "Day Care" if ref[:location] == :daycare
    return "Unknown"
  end

  def age_steps(pokemon)
    data = counterfeit_data_for(pokemon)
    return 0 if !data || !$PokemonGlobal
    return [$PokemonGlobal.stepcount - data[:created_step].to_i, 0].max
  end

  def species_data_for(pokemon)
    return pokemon.species_data if pokemon.respond_to?(:species_data)
    return GameData::Species.get(pokemon.species)
  end

  def fusion_species?(pokemon)
    return pokemon.isFusion? if pokemon.respond_to?(:isFusion?)
    species_data = species_data_for(pokemon)
    return species_data.respond_to?(:is_fusion) && species_data.is_fusion
  end

  def species_rarity_score(pokemon)
    species_data = species_data_for(pokemon)
    catch_rate = species_data.catch_rate.to_i
    bst = 0
    species_data.base_stats.each_value { |value| bst += value.to_i }
    rarity = (255 - catch_rate)
    rarity += (bst / 6)
    rarity += 60 if fusion_species?(pokemon)
    return [rarity, 20].max
  end

  def appeal_score(pokemon)
    ensure_palette_defaults!(pokemon)
    hue_score = (pokemon.shinyValue?.abs.to_f / Config::HUE_MAX * 40).round
    channel_values = [pokemon.shinyR?, pokemon.shinyG?, pokemon.shinyB?]
    spread_score = (channel_values.max - channel_values.min) * 2
    boost_values = sanitize_krs(pokemon.shinyKRS?)
    boost_score = ((boost_values[0].abs + boost_values[1].abs + boost_values[2].abs) / 30.0).round
    style_score = sanitize_style(pokemon.shinyimprovpif?) * Config::VALUE_STYLE_BONUS
    total = 10 + hue_score + spread_score + boost_score + (style_score / 20)
    total = 100 if total > 100
    return total
  end

  def age_score(pokemon)
    score = age_steps(pokemon) / Config::AGE_STEP_DIVISOR
    score = Config::MAX_AGE_SCORE if score > Config::MAX_AGE_SCORE
    return score
  end

  def notoriety_tier(pokemon)
    tier = Config::NOTORIETY_TIERS.first
    score = counterfeit_data_for(pokemon)[:notoriety].to_i
    Config::NOTORIETY_TIERS.each do |candidate|
      tier = candidate if score >= candidate[:minimum]
    end
    return tier
  end

  def market_value(pokemon)
    return 0 if !counterfeit?(pokemon)
    data = counterfeit_data_for(pokemon)
    value = Config::VALUE_BASE
    value += species_rarity_score(pokemon) * Config::VALUE_RARITY_MULT
    value += appeal_score(pokemon) * Config::VALUE_APPEAL_MULT
    value += age_score(pokemon) * Config::VALUE_AGE_MULT
    value += data[:battle_uses].to_i * Config::VALUE_BATTLE_USE_MULT
    value += data[:enforcer_wins].to_i * Config::VALUE_ENFORCER_WIN_MULT
    value += data[:notoriety].to_i * Config::VALUE_NOTORIETY_MULT
    value += data[:sale_bonus].to_i
    value += Config::VALUE_ACTIVE_BONUS if data[:battle_uses].to_i > 0
    value += Config::VALUE_FUSION_BONUS if fusion_species?(pokemon)
    value += notoriety_tier(pokemon)[:bonus].to_i
    value = Config::MIN_MARKET_VALUE if value < Config::MIN_MARKET_VALUE
    return value
  end

  def format_money(value)
    return "$#{value.to_i.to_s_formatted}"
  end

  def quote_for(profile_id, pokemon, session_sales = 0)
    profile = Config.buyer_profile(profile_id)
    return { :allowed => false, :offer => 0, :reason => profile[:empty_text] } if !counterfeit?(pokemon)
    if !safe_to_remove_entire_pokemon?(pokemon)
      return {
        :allowed => false,
        :offer   => 0,
        :reason  => "Selling this would leave you without any Pokemon."
      }
    end
    value = market_value(pokemon)
    if value < profile[:minimum_value].to_i
      return { :allowed => false, :offer => 0, :reason => profile[:reject_text] }
    end
    if appeal_score(pokemon) < profile[:minimum_appeal].to_i
      return { :allowed => false, :offer => 0, :reason => profile[:reject_text] }
    end
    multiplier = profile[:multiplier].to_f
    multiplier += session_sales.to_i * profile[:session_bonus].to_f if session_sales.to_i > 0
    offer = (value * multiplier).round
    offer = 1 if offer < 1
    return { :allowed => true, :offer => offer, :reason => nil }
  end

  def notoriety_label(pokemon)
    return notoriety_tier(pokemon)[:name]
  end

  def heat_label(heat = nil)
    heat = global_state[:heat].to_i if heat.nil?
    return "Cold" if heat <= 0
    return "Warm" if heat < 25
    return "Hot" if heat < 55
    return "Scalding"
  end

  def workshop_summary_text(pokemon, ref = nil)
    lines = []
    lines << "#{pokemon.name} Lv#{pokemon.level}"
    species = pokemon.speciesName.to_s
    lines << species if species != pokemon.name.to_s
    if ref
      location_line = case ref[:location]
                      when :party   then "Party ##{ref[:index] + 1}"
                      when :pc      then "Box #{ref[:box] + 1} Slot #{ref[:index] + 1}"
                      when :daycare then "Day Care #{ref[:slot] + 1}"
                      else               location_text(ref)
                      end
      lines << location_line
    end
    if counterfeit?(pokemon)
      lines << "Value #{format_money(market_value(pokemon))}"
      wins = counterfeit_data_for(pokemon)[:enforcer_wins].to_i
      lines << "Wins #{wins}" if wins > 0
    else
      lines << "Est. #{format_money(estimated_new_value(pokemon))}"
    end
    return lines.join("\n")
  end

  def buyer_summary_text(profile_id, pokemon, ref, session_sales)
    quote = quote_for(profile_id, pokemon, session_sales)
    lines = []
    lines << "#{pokemon.name} / Lv#{pokemon.level}"
    species = pokemon.speciesName.to_s
    identity = []
    identity << species if species != pokemon.name.to_s
    identity << location_text(ref)
    lines << identity.join(" / ")
    lines << "Market #{format_money(market_value(pokemon))} / #{notoriety_label(pokemon)}"
    if quote[:allowed]
      lines << "Offer #{format_money(quote[:offer])}"
    else
      lines << "Offer Refused"
      lines << quote[:reason].to_s
    end
    return lines.join("\n")
  end

  def launder_summary_text(pokemon, ref = nil)
    lines = []
    lines << "#{pokemon.name} / Lv#{pokemon.level}"
    species = pokemon.speciesName.to_s
    identity = []
    identity << species if species != pokemon.name.to_s
    identity << location_text(ref) if ref
    lines << identity.join(" / ") if !identity.empty?
    lines << "Forged #{notoriety_label(pokemon)} / #{format_money(market_value(pokemon))}"
    lines << "1 #{Config::LAUNDER_REWARD_NAME} / clears the tag"
    return lines.join("\n")
  end

  def event_script_text_from_list(list)
    return "" if !list
    lines = []
    list.each do |command|
      next if !command
      case command.code
      when 355, 655
        lines << command.parameters[0].to_s
      end
    end
    return lines.join("\n")
  end

  def normalized_offer_dialogue_text(text)
    cleaned = text.to_s.dup
    cleaned.gsub!(/\s+/, " ")
    cleaned.strip!
    return cleaned
  end

  def active_event_list(event)
    return nil if !event
    list = nil
    list = event.list if event.respond_to?(:list)
    if !list || list.empty?
      page = event.instance_variable_get(:@page) rescue nil
      list = page.list if page && page.respond_to?(:list)
    end
    return list
  end

  def world_offer_event_key(event)
    return nil if !event
    map_id = event.respond_to?(:map_id) ? event.map_id : $game_map.map_id
    event_id = event.respond_to?(:id) ? event.id : nil
    return nil if !event_id
    return [map_id, event_id]
  end

  def world_offer_cooldowns
    return {} if !$PokemonTemp
    $PokemonTemp.counterfeit_shiny_offer_cooldowns = {} if !$PokemonTemp.counterfeit_shiny_offer_cooldowns.is_a?(Hash)
    return $PokemonTemp.counterfeit_shiny_offer_cooldowns
  end

  def dialogue_buffers
    return {} if !$PokemonTemp
    $PokemonTemp.counterfeit_shiny_dialogue_buffers = {} if !$PokemonTemp.counterfeit_shiny_dialogue_buffers.is_a?(Hash)
    return $PokemonTemp.counterfeit_shiny_dialogue_buffers
  end

  def dialogue_memory
    return {} if !$PokemonTemp
    $PokemonTemp.counterfeit_shiny_dialogue_memory = {} if !$PokemonTemp.counterfeit_shiny_dialogue_memory.is_a?(Hash)
    return $PokemonTemp.counterfeit_shiny_dialogue_memory
  end

  def capture_dialogue_message(map_id, event_id, text)
    return if map_id.to_i <= 0 || event_id.to_i <= 0
    line = normalized_offer_dialogue_text(text)
    return if line.empty?
    key = [map_id.to_i, event_id.to_i]
    dialogue_buffers[key] = [] if !dialogue_buffers[key].is_a?(Array)
    dialogue_buffers[key] << line
  end

  def finalize_dialogue_interaction(map_id, event_id)
    return nil if map_id.to_i <= 0 || event_id.to_i <= 0
    key = [map_id.to_i, event_id.to_i]
    lines = dialogue_buffers.delete(key)
    return nil if !lines || lines.empty?
    signature = normalized_offer_dialogue_text(lines.join(" "))
    return nil if signature.empty?
    state = dialogue_memory[key]
    if !state.is_a?(Hash) || state[:signature].to_s != signature
      state = {
        :signature  => signature,
        :streak     => 1,
        :last_frame => Graphics.frame_count
      }
    else
      state[:streak] = state[:streak].to_i + 1
      state[:last_frame] = Graphics.frame_count
    end
    dialogue_memory[key] = state
    return state
  end

  def clear_dialogue_buffers!
    return if !$PokemonTemp
    $PokemonTemp.counterfeit_shiny_dialogue_buffers = {}
  end

  def dialogue_offer_ready_for_event?(event)
    key = world_offer_event_key(event)
    return false if !key
    state = dialogue_memory[key]
    return false if !state.is_a?(Hash)
    return false if state[:signature].to_s.empty?
    return state[:streak].to_i >= Config::WORLD_OFFER_REPEAT_STREAK_REQUIRED
  end

  def buyer_history
    state = global_state
    state[:buyer_history] = {} if !state[:buyer_history].is_a?(Hash)
    return state[:buyer_history]
  end

  def world_offer_buyer_key(event)
    key = world_offer_event_key(event)
    return nil if !key
    return "#{key[0]}:#{key[1]}"
  end

  def world_offer_buyer_entry(event)
    key = world_offer_buyer_key(event)
    return nil if !key
    entry = buyer_history[key]
    return entry if entry.is_a?(Hash)
    return nil
  end

  def world_offer_buyer_spent?(event)
    entry = world_offer_buyer_entry(event)
    return false if !entry
    return entry[:sold_count].to_i > 0
  end

  def record_world_offer_sale!(event, count)
    key = world_offer_buyer_key(event)
    return if !key
    buyer_history[key] = {
      :sold_count => count.to_i,
      :last_frame => Graphics.frame_count
    }
  end

  def normalized_preference_archetypes
    return @normalized_preference_archetypes if @normalized_preference_archetypes
    ret = {}
    Config::PREFERENCE_ARCHETYPES.each_pair do |tag, data|
      species = Array(data[:species]).map do |species_id|
        species_data = GameData::Species.try_get(species_id)
        species_data ? species_data.id : nil
      end.compact.uniq
      families = species.map do |species_id|
        species_data = GameData::Species.try_get(species_id)
        species_data ? species_data.get_baby_species : nil
      end.compact.uniq
      types = Array(data[:types]).map do |type_id|
        type_data = GameData::Type.try_get(type_id) rescue nil
        type_data ? type_data.id : nil
      end.compact.uniq
      ret[tag] = {
        :trainer_keywords  => Array(data[:trainer_keywords]),
        :dialogue_keywords => Array(data[:dialogue_keywords]),
        :map_keywords      => Array(data[:map_keywords]),
        :species           => species,
        :families          => families,
        :types             => types
      }
    end
    @normalized_preference_archetypes = ret
    return @normalized_preference_archetypes
  end

  def base_species_name_lookup
    return @base_species_name_lookup if @base_species_name_lookup
    seen = {}
    ret = []
    GameData::Species.each do |species|
      next if species.respond_to?(:is_fusion) && species.is_fusion
      next if seen[species.id]
      seen[species.id] = true
      name = normalized_offer_dialogue_text(species.real_name).downcase
      next if name.empty?
      ret << [name, species.id]
    end
    ret.sort_by! { |entry| -entry[0].length }
    @base_species_name_lookup = ret
    return @base_species_name_lookup
  end

  def offer_dialogue_signature_for_event(event)
    key = world_offer_event_key(event)
    return "" if !key
    state = dialogue_memory[key]
    return "" if !state.is_a?(Hash)
    return state[:signature].to_s
  end

  def world_offer_context_for_event(event, profile)
    trainer_bits = []
    trainer_bits << profile[:type_name].to_s
    trainer_bits << profile[:trainer_name].to_s
    trainer_bits << profile[:display_name].to_s
    trainer_bits << event.name.to_s if event.respond_to?(:name)
    trainer_bits << event.character_name.to_s if event.respond_to?(:character_name)
    trainer_text = trainer_bits.join(" ").downcase
    map_text = ""
    map_text = $game_map.name.to_s.downcase if $game_map && $game_map.respond_to?(:name)
    dialogue_text = offer_dialogue_signature_for_event(event).downcase
    return {
      :trainer_text  => trainer_text,
      :map_text      => map_text,
      :dialogue_text => dialogue_text
    }
  end

  def mention_species_from_text(text)
    ret = []
    haystack = text.to_s.downcase
    return ret if haystack.empty?
    base_species_name_lookup.each do |name, species_id|
      next if !haystack.include?(name)
      ret << species_id
    end
    return ret.uniq
  end

  def world_offer_matched_archetypes(context)
    ret = []
    normalized_preference_archetypes.each_pair do |tag, data|
      weight = 0
      weight += 2 if data[:trainer_keywords].any? { |pattern| context[:trainer_text].match?(pattern) }
      weight += 1 if data[:map_keywords].any? { |pattern| context[:map_text].match?(pattern) }
      dialogue_hits = 0
      data[:dialogue_keywords].each do |pattern|
        dialogue_hits += 1 if !context[:dialogue_text].empty? && context[:dialogue_text].match?(pattern)
      end
      weight += [dialogue_hits, 3].min
      ret << { :tag => tag, :weight => weight } if weight > 0
    end
    return ret
  end

  def world_offer_species_parts(pokemon)
    return [] if !pokemon
    if fusion_species?(pokemon)
      body_id = getBodyID(pokemon.species)
      head_id = getHeadID(pokemon.species, body_id)
      body_species = GameData::Species.try_get(body_id)
      head_species = GameData::Species.try_get(head_id)
      parts = []
      parts << body_species.id if body_species
      parts << head_species.id if head_species
      return parts
    end
    species_data = GameData::Species.try_get(pokemon.species)
    return species_data ? [species_data.id] : []
  end

  def world_offer_family_root(species_id)
    species_data = GameData::Species.try_get(species_id)
    return nil if !species_data
    return species_data.get_baby_species
  end

  def world_offer_component_types(species_id)
    species_data = GameData::Species.try_get(species_id)
    return [] if !species_data || !species_data.respond_to?(:types)
    return species_data.types
  end

  def world_offer_preference_for_pokemon(event, profile, pokemon)
    context = world_offer_context_for_event(event, profile)
    matched_tags = world_offer_matched_archetypes(context)
    parts = world_offer_species_parts(pokemon)
    families = parts.map { |species_id| world_offer_family_root(species_id) }
    part_types = parts.map { |species_id| world_offer_component_types(species_id) }
    mentioned_species = mention_species_from_text(context[:dialogue_text])
    mentioned_families = mentioned_species.map { |species_id| world_offer_family_root(species_id) }.compact.uniq
    score = 0
    matched_archetypes = []
    matched_components = 0
    matched_exact_components = 0
    matched_tags.each do |tag_info|
      data = normalized_preference_archetypes[tag_info[:tag]]
      next if !data
      tag_score = 0
      tag_component_matches = []
      tag_exact_matches = []
      parts.each_with_index do |species_id, index|
        exact_match = data[:species].include?(species_id)
        family_match = data[:families].include?(families[index])
        type_hits = (part_types[index] & data[:types]).length
        if exact_match
          tag_score += Config::PREFERENCE_SPECIES_BONUS
          tag_component_matches << index
          tag_exact_matches << index
        elsif family_match
          tag_score += Config::PREFERENCE_FAMILY_BONUS
          tag_component_matches << index
        end
        if type_hits > 0
          tag_score += [type_hits, 2].min * Config::PREFERENCE_TYPE_BONUS
          tag_component_matches << index
        end
      end
      if fusion_species?(pokemon) && !tag_component_matches.empty?
        tag_score += Config::PREFERENCE_FUSION_THEME_BONUS
      end
      if fusion_species?(pokemon) && tag_component_matches.uniq.length >= 2
        tag_score += Config::PREFERENCE_DOUBLE_COMPONENT_BONUS
      end
      if fusion_species?(pokemon) && tag_exact_matches.uniq.length >= 2
        tag_score += Config::PREFERENCE_DOUBLE_SPECIES_BONUS
      end
      if tag_score > 0
        intensity = [tag_info[:weight].to_i - 1, 3].min
        intensity = 0 if intensity < 0
        tag_score = (tag_score * (1.0 + intensity * 0.20)).round
        matched_components = [matched_components, tag_component_matches.uniq.length].max
        matched_exact_components = [matched_exact_components, tag_exact_matches.uniq.length].max
        matched_archetypes << tag_info[:tag]
        score += tag_score
      end
    end
    direct_species_hits = 0
    family_mention_hits = 0
    parts.each_with_index do |species_id, index|
      direct_species_hits += 1 if mentioned_species.include?(species_id)
      family_mention_hits += 1 if mentioned_families.include?(families[index])
    end
    score += direct_species_hits * Config::PREFERENCE_DIRECT_MENTION_BONUS
    score += family_mention_hits * (Config::PREFERENCE_DIRECT_MENTION_BONUS / 2)
    if fusion_species?(pokemon) && direct_species_hits >= 2
      score += Config::PREFERENCE_DOUBLE_SPECIES_BONUS
    end
    score = Config::PREFERENCE_MAX_SCORE if score > Config::PREFERENCE_MAX_SCORE
    return {
      :score                    => score,
      :tags                     => matched_archetypes.uniq,
      :direct_species_hits      => direct_species_hits,
      :family_mention_hits      => family_mention_hits,
      :matched_components       => matched_components,
      :matched_exact_components => matched_exact_components
    }
  end

  def world_offer_thresholds(preference)
    score = preference[:score].to_i
    immediate = [Config::WORLD_OFFER_IMMEDIATE_CALL_THRESHOLD - (score / 18), 0].max
    anger = [Config::WORLD_OFFER_ANGER_THRESHOLD - (score / 7), immediate + 3].max
    decline = [Config::WORLD_OFFER_DECLINE_THRESHOLD - (score / 3), anger + 8].max
    return {
      :immediate => immediate,
      :anger     => anger,
      :decline   => decline
    }
  end

  def world_offer_percent_range(preference)
    score = preference[:score].to_i
    min_percent = Config::PREFERENCE_OFFER_MIN_BASE + (score / Config::PREFERENCE_OFFER_MIN_SCORE_STEP)
    min_percent = Config::PREFERENCE_OFFER_MIN_CAP if min_percent > Config::PREFERENCE_OFFER_MIN_CAP
    max_percent = Config::PREFERENCE_OFFER_MAX_BASE + (score / Config::PREFERENCE_OFFER_MAX_SCORE_STEP)
    max_percent = Config::PREFERENCE_OFFER_MAX_CAP if max_percent > Config::PREFERENCE_OFFER_MAX_CAP
    max_percent = min_percent if max_percent < min_percent
    return [min_percent, max_percent]
  end

  def world_offer_interest_line(pokemon, preference)
    score = preference[:score].to_i
    return _INTL("Their attention settles on {1} immediately.", pokemon.name) if score >= 65
    return _INTL("They turn {1}'s ball over once, thinking.", pokemon.name) if score >= 30
    return _INTL("They weigh {1}'s ball in one hand.", pokemon.name)
  end

  def world_offer_event_cooldown_active?(event)
    key = world_offer_event_key(event)
    return false if !key
    expires = world_offer_cooldowns[key].to_i
    if expires <= Graphics.frame_count
      world_offer_cooldowns.delete(key)
      return false
    end
    return true
  end

  def snooze_world_offer_event!(event, seconds = Config::WORLD_OFFER_EVENT_COOLDOWN_SECONDS)
    key = world_offer_event_key(event)
    return if !key
    frame_window = (Graphics.frame_rate * seconds.to_f).to_i
    world_offer_cooldowns[key] = Graphics.frame_count + [frame_window, 1].max
  end

  def active_event_script_text(event)
    return "" if !event
    return event_script_text_from_list(active_event_list(event))
  end

  def interpreter_message_preview(interpreter)
    return "" if !interpreter
    list = interpreter.instance_variable_get(:@list) rescue nil
    index = interpreter.instance_variable_get(:@index).to_i rescue 0
    return "" if !list || !list[index]
    message = list[index].parameters[0].to_s
    loop do
      next_index = interpreter.pbNextIndex(index)
      break if next_index < 0 || next_index >= list.length
      command = list[next_index]
      break if !command || command.code != 401
      text = command.parameters[0].to_s
      message += " " if text != "" && message[message.length - 1, 1] != " "
      message += text
      index = next_index
    end
    map_id = interpreter.instance_variable_get(:@map_id).to_i rescue 0
    message = _MAPINTL(map_id, message) rescue message
    return normalized_offer_dialogue_text(message)
  end

  def all_event_script_text(event)
    return "" if !event
    rpg_event = event.instance_variable_get(:@event) rescue nil
    return active_event_script_text(event) if !rpg_event || !rpg_event.respond_to?(:pages)
    lines = []
    rpg_event.pages.each do |page|
      next if !page || !page.respond_to?(:list)
      text = event_script_text_from_list(page.list)
      lines << text if !text.empty?
    end
    return lines.join("\n")
  end

  def repeatable_trainer_script?(script_text)
    return false if script_text.to_s.empty?
    Config::WORLD_OFFER_REPEATABLE_SCRIPT_PATTERNS.each do |pattern|
      return true if script_text.match?(pattern)
    end
    if script_text[/pbTrainerCheck\(\s*:(\w+)\s*,\s*\"([^\"]+)\"\s*,\s*(\d+)/m]
      return true if $3.to_i > 1
    end
    return false
  end

  def trainer_metadata_from_script_text(script_text)
    return nil if script_text.to_s.empty?
    return nil if !script_text[/pbTrainer(?:Battle|Check)\(\s*:(\w+)\s*,\s*\"([^\"]+)\"/m]
    trainer_type = $1.to_sym
    trainer_name = $2.to_s
    type_data = GameData::TrainerType.try_get(trainer_type) rescue nil
    return nil if !type_data
    return {
      :trainer_type => type_data.id,
      :trainer_name => trainer_name,
      :type_name    => type_data.name.to_s,
      :display_name => "#{type_data.name} #{trainer_name}"
    }
  end

  def trainer_metadata_for_event(event)
    return nil if !event
    active_script = active_event_script_text(event)
    full_script = all_event_script_text(event)
    return nil if full_script.empty?
    return nil if repeatable_trainer_script?(full_script)
    active_metadata = trainer_metadata_from_script_text(active_script)
    metadata = active_metadata || trainer_metadata_from_script_text(full_script)
    return nil if !metadata
    metadata[:active_script_text] = active_script
    metadata[:script_text] = full_script
    metadata[:active_trainer_page] = !active_metadata.nil?
    metadata[:post_battle_page] = !metadata[:active_trainer_page]
    return metadata
  end

  def generic_dialogue_offer_metadata_for_event(event)
    return nil if !event
    return nil if !event.respond_to?(:character_name) || event.character_name.to_s.empty?
    key = world_offer_event_key(event)
    labels = Config::WORLD_OFFER_DIALOGUE_LABELS
    label = "someone quiet"
    if labels && !labels.empty? && key
      label = labels[key[1] % labels.length].to_s
    end
    return {
      :trainer_type       => nil,
      :trainer_name       => "",
      :type_name          => "",
      :display_name       => label,
      :script_text        => "",
      :active_script_text => "",
      :active_trainer_page => false,
      :post_battle_page   => true,
      :dialogue_npc       => true
    }
  end

  def eligible_world_offer_trainer_metadata?(metadata)
    return false if !metadata
    return false if metadata[:display_name].to_s.empty?
    return true
  end

  def world_offer_profile_for_event(event, after_event = false)
    return nil if !event
    return nil if world_offer_event_cooldown_active?(event)
    return nil if world_offer_buyer_spent?(event)
    return nil if !event.respond_to?(:character_name) || event.character_name.to_s.empty?
    return nil if ![0, 2].include?(event.trigger)
    metadata = trainer_metadata_for_event(event)
    metadata = generic_dialogue_offer_metadata_for_event(event) if !metadata && after_event
    return nil if !eligible_world_offer_trainer_metadata?(metadata)
    return nil if !after_event && !metadata[:active_trainer_page]
    return nil if after_event && !metadata[:post_battle_page]
    return nil if after_event && !dialogue_offer_ready_for_event?(event)
    return metadata
  end

  def world_offer_target
    return party_sale_candidates.first[:pokemon] if !party_sale_candidates.empty?
    return nil
  end

  def choose_world_offer_pokemon
    candidates = party_sale_candidates
    return nil if candidates.empty?
    return candidates.first[:pokemon] if candidates.length == 1
    commands = candidates.map do |ref|
      pokemon = ref[:pokemon]
      "#{pokemon.name} #{format_money(market_value(pokemon))}"
    end
    commands << _INTL("Back")
    choice = pbMessage(_INTL("Which one do you show?"), commands, commands.length - 1)
    return nil if choice < 0 || choice >= candidates.length
    return candidates[choice][:pokemon]
  end

  def world_offer_prompt_text(_profile = nil)
    return _INTL("They linger on your party a little too long. Make an offer?")
  end

  def complete_world_sale!(pokemon, offer)
    return false if !pokemon
    return false if !safe_to_remove_entire_pokemon?(pokemon)
    data = counterfeit_data_for(pokemon)
    return false if !remove_owned_pokemon(pokemon, :sold)
    if data
      data[:status] = :sold
      data[:last_sale_value] = offer
    end
    global_state[:gross_profit] += offer
    global_state[:lifetime_sales] += 1
    $Trainer.money += offer
    pbSEPlay("Mart buy item")
    pbMessage(_INTL("You hand over {1} and quietly pocket ${2}.", pokemon.name, offer.to_i.to_s_formatted))
    return true
  end

  def trigger_tipoff_enforcer!(profile)
    accelerate_enforcer_pressure!(Config::WORLD_OFFER_IMMEDIATE_HEAT_GAIN, Config::WORLD_OFFER_IMMEDIATE_STEP_GAIN)
    intro_lines = [
      "They recoil and palm a phone.",
      "\"I've got a counterfeit runner right here. Send somebody now.\""
    ]
    return trigger_enforcer_encounter(true, intro_lines, "tipoff enforcer")
  end

  def world_offer_purchase_capacity(preference)
    max_take = [party_sale_candidates.length, Config::WORLD_OFFER_MAX_MULTI_BUY].min
    return 0 if max_take <= 0
    capacity = 1
    chance = Config::WORLD_OFFER_MULTI_BUY_CHANCE + (preference[:score].to_i / Config::PREFERENCE_MULTI_BUY_SCORE_STEP)
    chance = 90 if chance > 90
    while capacity < max_take
      break if rand(100) >= chance
      capacity += 1
      chance -= 18
      chance = 15 if chance < 15
    end
    return capacity
  end

  def handle_world_offer(profile, event)
    return false if !profile || !event
    return false if party_sale_candidates.empty?
    first_pokemon = choose_world_offer_pokemon
    if !first_pokemon
      pbMessage(_INTL("You keep your stock out of sight."))
      return true
    end
    preference = world_offer_preference_for_pokemon(event, profile, first_pokemon)
    thresholds = world_offer_thresholds(preference)
    roll = rand(100)
    if roll < thresholds[:immediate]
      pbMessage(_INTL("Their expression hardens the second you test the waters."))
      trigger_tipoff_enforcer!(profile)
      return true
    end
    if roll < thresholds[:anger]
      pbMessage(_INTL("They take a step back. \"Not here. Not with that kind of heat on you.\""))
      accelerate_enforcer_pressure!(Config::WORLD_OFFER_HEAT_GAIN, Config::WORLD_OFFER_STEP_GAIN)
      return true
    end
    if roll < thresholds[:decline]
      pbMessage(_INTL("They glance over {1}, then let the moment die. \"No deal. Too hot tonight.\"", first_pokemon.name))
      return true
    end
    capacity = world_offer_purchase_capacity(preference)
    sold_count = 0
    if capacity > 1
      pbMessage(_INTL("They keep their voice low. \"If the stock is right, I can move more than one.\""))
    end
    current_pokemon = first_pokemon
    loop do
      pokemon = current_pokemon
      current_preference = world_offer_preference_for_pokemon(event, profile, pokemon)
      offer_range = world_offer_percent_range(current_preference)
      offer_percent = rand(offer_range[0]..offer_range[1])
      offer = (market_value(pokemon) * offer_percent / 100.0).floor
      pbMessage(world_offer_interest_line(pokemon, current_preference))
      pbMessage(_INTL("\"${1}. Quiet and final.\"", offer.to_i.to_s_formatted))
      if offer <= 0
        pbMessage(_INTL("The number is insulting. The deal dies there."))
        break
      end
      if !pbConfirmMessage(_INTL("Take ${1} for {2}?", offer.to_i.to_s_formatted, pokemon.name))
        pbMessage(_INTL("You pull the offer back and keep moving."))
        break
      end
      if !complete_world_sale!(pokemon, offer)
        pbMessage(_INTL("You cannot move that one right now."))
        break
      end
      sold_count += 1
      break if sold_count >= capacity
      break if party_sale_candidates.empty?
      break if !pbConfirmMessage(_INTL("Show them another?"))
      pbMessage(_INTL("They scan the street once, then hold out a hand again."))
      current_pokemon = choose_world_offer_pokemon
      if !current_pokemon
        pbMessage(_INTL("You let the rest stay hidden."))
        break
      end
    end
    record_world_offer_sale!(event, sold_count) if sold_count > 0
    return true
  end

  def try_world_offer(event)
    return false if enforcer_chase_active?
    return false if party_sale_candidates.empty?
    profile = world_offer_profile_for_event(event)
    return false if !profile
    return false if !pbConfirmMessage(world_offer_prompt_text(profile))
    handled = handle_world_offer(profile, event)
    snooze_world_offer_event!(event) if handled
    return handled
  end

  def try_post_event_world_offer(event)
    return false if enforcer_chase_active?
    return false if party_sale_candidates.empty?
    profile = world_offer_profile_for_event(event, true)
    return false if !profile
    return false if !pbConfirmMessage(world_offer_prompt_text(profile))
    handled = handle_world_offer(profile, event)
    snooze_world_offer_event!(event) if handled
    return handled
  end

  def estimated_new_value(pokemon)
    snapshot = deep_clone(pokemon.counterfeit_shiny_data)
    visual = capture_visual_state(pokemon)
    begin
      apply_counterfeit!(pokemon, default_palette, :estimate)
      return market_value(pokemon)
    ensure
      restore_visual_state(pokemon, visual)
      pokemon.counterfeit_shiny_data = snapshot
    end
  end

  def preview_bitmap(pokemon, back = false)
    return GameData::Species.sprite_bitmap_from_pokemon(pokemon, back)
  end

  def remove_owned_pokemon(pokemon, reason = :sold)
    ref = find_owned_reference(pokemon, true, true)
    return false if !ref
    if ref[:location] == :daycare
      stripped_or_confiscated!(pokemon, reason)
      $PokemonGlobal.daycare[ref[:slot]][0] = nil
      $PokemonGlobal.daycare[ref[:slot]][1] = 0
      return true
    end
    stripped_or_confiscated!(pokemon, reason)
    if ref[:location] == :party
      $Trainer.remove_pokemon_at_index(ref[:index])
    else
      $PokemonStorage.pbDelete(ref[:box], ref[:index])
    end
    return true
  end

  def strip_instead_of_confiscating!(pokemon)
    return false if !pokemon
    clear_counterfeit!(pokemon)
    return true
  end

  def remove_counterfeit_tag!(pokemon)
    return false if !counterfeit?(pokemon)
    data = counterfeit_data_for(pokemon)
    visual = capture_visual_state(pokemon)
    return false if !data || !visual
    pokemon.counterfeit_shiny_data = {
      :enabled         => false,
      :version         => DATA_VERSION,
      :status          => :laundered,
      :id              => data[:id],
      :created_source  => data[:created_source],
      :laundered_step  => ($PokemonGlobal ? $PokemonGlobal.stepcount : 0)
    }
    visual[:fakeshiny] = true
    apply_visual_state!(pokemon, visual)
    global_state[:laundered] += 1
    return true
  end

  def current_enforcer_base_level
    max_level = GameData::GrowthRate.max_level
    level = Config::ENFORCER_START_LEVEL + (global_state[:enforcer_stage].to_i * Config::ENFORCER_LEVEL_STEP)
    level = max_level if level > max_level
    return level
  end

  def advance_enforcer_stage!
    max_level = GameData::GrowthRate.max_level
    max_stage = [(max_level - Config::ENFORCER_START_LEVEL) / Config::ENFORCER_LEVEL_STEP, 0].max
    global_state[:enforcer_stage] += 1 if global_state[:enforcer_stage].to_i < max_stage
  end

  def reset_enforcer_stage!
    global_state[:enforcer_stage] = 0
  end

  def accelerate_enforcer_pressure!(heat_gain, step_gain)
    state = global_state
    state[:heat] += heat_gain.to_i
    state[:heat] = Config::HEAT_CAP if state[:heat] > Config::HEAT_CAP
    state[:step_meter] += step_gain.to_i
  end

  def enforcer_chase_state
    return nil if !$PokemonTemp
    state = $PokemonTemp.counterfeit_shiny_chase
    return nil if !state.is_a?(Hash)
    return state
  end

  def enforcer_chase_active?
    return !enforcer_chase_state.nil?
  end

  def current_chase_character_for_map(map_id = nil)
    state = enforcer_chase_state
    return nil if !state
    map_id = $game_map.map_id if map_id.nil? && $game_map
    return nil if map_id.nil? || state[:map_id] != map_id
    return state[:character]
  end

  def update_enforcer_chase_character(state = nil)
    state = enforcer_chase_state if state.nil?
    return nil if !state
    chaser = state[:character]
    return nil if !chaser
    frame = Graphics.frame_count
    return chaser if state[:last_character_update_frame].to_i == frame
    chaser.update
    state[:last_character_update_frame] = frame
    return chaser
  end

  def enforcer_chase_seconds_left(state = nil)
    state = enforcer_chase_state if state.nil?
    return 0 if !state
    remaining = state[:expires_frame].to_i - Graphics.frame_count
    remaining = 0 if remaining < 0
    return (remaining.to_f / Graphics.frame_rate).ceil
  end

  def enforcer_chase_distance(state = nil)
    state = enforcer_chase_state if state.nil?
    return nil if !state || !$game_player
    chaser = state[:character]
    return nil if !chaser
    dx = (chaser.x - $game_player.x).abs
    dy = (chaser.y - $game_player.y).abs
    return dx + dy
  end

  def enforcer_chase_gap_label(state = nil)
    distance = enforcer_chase_distance(state)
    return "Cold" if distance.nil?
    return "On You" if distance <= 1
    return "Tight" if distance <= Config::ENFORCER_CHASE_CLOSE_DISTANCE
    return "Close" if distance <= 6
    return "Wide"
  end

  def enforcer_chase_close?(state = nil)
    distance = enforcer_chase_distance(state)
    return false if distance.nil?
    return distance <= Config::ENFORCER_CHASE_CLOSE_DISTANCE
  end

  def clear_enforcer_chase!(reason = :cleared, show_message = false)
    state = enforcer_chase_state
    return false if !state
    if [:escaped, :map_transfer, :other_battle].include?(reason)
      global_state[:step_meter] = 0
    end
    if show_message
      case reason
      when :escaped
        pbMessage(_INTL("You shake the enforcer and the trail goes cold for now."))
      when :other_battle
        pbMessage(_INTL("The enforcer loses you in the confusion of another battle."))
      end
    end
    $PokemonTemp.counterfeit_shiny_chase = nil if $PokemonTemp
    return true
  end

  def available_enforcer_charsets
    ret = []
    Config::ENFORCER_CHASE_CHARSETS.each do |name|
      ret << name if pbResolveBitmap("Graphics/Characters/#{name}")
    end
    ret << "003" if ret.empty?
    return ret
  end

  def direction_toward_player_from(x, y)
    dx = $game_player.x - x
    dy = $game_player.y - y
    return 6 if dx > 0 && dx.abs >= dy.abs
    return 4 if dx < 0 && dx.abs >= dy.abs
    return 2 if dy > 0
    return 8
  end

  def occupied_overworld_tile?(map, x, y)
    return true if !map || !map.valid?(x, y)
    return true if $game_player && $game_player.at_coordinate?(x, y)
    map.events.each_value do |event|
      next if !event
      next if event.through
      return true if event.at_coordinate?(x, y)
    end
    state = enforcer_chase_state
    if state && state[:character] && state[:map_id] == map.map_id
      return true if state[:character].at_coordinate?(x, y)
    end
    return false
  end

  def build_enforcer_chaser
    return nil if !$game_map || !$game_player
    map = $game_map
    charsets = available_enforcer_charsets
    ordered_dirs = [$game_player.opposite_direction, 2, 4, 6, 8].uniq
    ordered_dirs = ordered_dirs.sort_by { rand }
    best_fallback = nil
    Config::ENFORCER_CHASE_MAX_DISTANCE.downto(Config::ENFORCER_CHASE_MIN_DISTANCE) do |distance|
      ordered_dirs.each do |dir|
        x = $game_player.x + ((dir == 6) ? distance : (dir == 4) ? -distance : 0)
        y = $game_player.y + ((dir == 2) ? distance : (dir == 8) ? -distance : 0)
        next if occupied_overworld_tile?(map, x, y)
        chaser = CounterfeitEnforcerChaser.new(map, x, y, charsets.sample)
        chaser.direction = direction_toward_player_from(x, y)
        passable_origin = [2, 4, 6, 8].any? { |d| chaser.can_move_in_direction?(d) }
        next if !passable_origin
        return chaser if pbEventCanReachPlayer?(chaser, $game_player, distance + 1)
        best_fallback ||= chaser
      end
    end
    return best_fallback
  end

  def build_enforcer_context(target, role = nil)
    return nil if !target
    trainer = build_enforcer_trainer
    level_cap = trainer.instance_variable_get(:@counterfeit_level_cap) == true
    return {
      :type      => :enforcer,
      :trainer   => trainer,
      :target_id => counterfeit_data_for(target)[:id],
      :role      => role || Config::ENFORCER_ROLES.sample,
      :used_ids  => [],
      :level_cap => level_cap
    }
  end

  def show_enforcer_intro(context, opening_lines = nil, battle_from_chase = false)
    if opening_lines.is_a?(Array) && !opening_lines.empty?
      opening_lines.each { |line| pbMessage(_INTL(line)) }
      return
    end
    if battle_from_chase
      pbMessage(_INTL("The {1} from {2} cuts you off.", context[:role], Config::FACTION_NAME))
    else
      pbMessage(_INTL("A {1} from {2} steps into your path.", context[:role], Config::FACTION_NAME))
    end
    if context[:level_cap]
      pbMessage(_INTL("\"Level {1}. Final seal. Beat me, and the clean-slate reward is yours.\"", GameData::GrowthRate.max_level))
    else
      pbMessage(_INTL("\"That finish is counterfeit. Hand it over, or prove it's worth the trouble.\""))
    end
  end

  def show_enforcer_chase_intro(context, opening_lines = nil)
    if opening_lines.is_a?(Array) && !opening_lines.empty?
      opening_lines.each { |line| pbMessage(_INTL(line)) }
    else
      pbMessage(_INTL("A {1} from {2} catches sight of your counterfeit stock.", context[:role], Config::FACTION_NAME))
    end
  end

  def engage_enforcer_battle(context, opening_lines = nil, battle_from_chase = false)
    return false if !context
    clear_enforcer_chase!(:engaged)
    $PokemonTemp.counterfeit_shiny_context = deep_clone(context)
    global_state[:encounters] += 1
    advance_enforcer_stage!
    show_enforcer_intro($PokemonTemp.counterfeit_shiny_context, opening_lines, battle_from_chase)
    setBattleRule("canLose")
    decision = pbTrainerBattleCore($PokemonTemp.counterfeit_shiny_context[:trainer])
    $PokemonTemp.counterfeit_shiny_context = nil if $PokemonTemp && decision.to_i == 0
    return decision == 1
  end

  def start_enforcer_chase(context, opening_lines = nil)
    return false if !context || !$PokemonTemp
    return engage_enforcer_battle(context, opening_lines) if !Config::ENFORCER_CHASE_ENABLED
    chaser = build_enforcer_chaser
    return engage_enforcer_battle(context, opening_lines) if !chaser
    clear_enforcer_chase!(:replaced)
    show_enforcer_chase_intro(context, opening_lines)
    $PokemonTemp.counterfeit_shiny_chase = deep_clone(context)
    $PokemonTemp.counterfeit_shiny_chase[:type] = :enforcer_chase
    $PokemonTemp.counterfeit_shiny_chase[:map_id] = $game_map.map_id
    $PokemonTemp.counterfeit_shiny_chase[:started_frame] = Graphics.frame_count
    $PokemonTemp.counterfeit_shiny_chase[:expires_frame] = Graphics.frame_count + (Graphics.frame_rate * Config::ENFORCER_CHASE_DURATION_SECONDS)
    $PokemonTemp.counterfeit_shiny_chase[:character] = chaser
    $PokemonTemp.counterfeit_shiny_chase[:last_dust_frame] = Graphics.frame_count - Config::ENFORCER_CHASE_DUST_INTERVAL
    $PokemonTemp.counterfeit_shiny_chase[:last_alert_frame] = Graphics.frame_count - Config::ENFORCER_CHASE_ALERT_INTERVAL
    $PokemonTemp.counterfeit_shiny_chase[:last_character_update_frame] = nil
    global_state[:step_meter] = 0
    pbExclaim(chaser) rescue nil
    pbMessage(_INTL("The enforcer gives chase. Get away by any means to lose them."))
    return true
  end

  def enforcer_chase_caught_player?(character)
    return false if !character || character.moving? || $game_player.moving?
    dx = (character.x - $game_player.x).abs
    dy = (character.y - $game_player.y).abs
    return (dx + dy) <= 1
  end

  def update_enforcer_chase
    state = enforcer_chase_state
    return if !state
    if !$game_map || state[:map_id] != $game_map.map_id
      clear_enforcer_chase!(:map_transfer)
      return
    end
    return if $game_temp.in_menu || $game_temp.in_battle
    return if $game_temp.message_window_showing || pbMapInterpreterRunning?
    if !find_counterfeit_by_id(state[:target_id]) || party_counterfeits.empty?
      clear_enforcer_chase!(:cleared)
      return
    end
    if Graphics.frame_count >= state[:expires_frame].to_i
      clear_enforcer_chase!(:escaped, true)
      return
    end
    chaser = state[:character]
    return clear_enforcer_chase!(:cleared) if !chaser
    chaser = update_enforcer_chase_character(state)
    return if !enforcer_chase_caught_player?(chaser)
    pbTurnTowardEvent(chaser, $game_player) rescue nil
    pbTurnTowardEvent($game_player, chaser) rescue nil
    engage_enforcer_battle(state, nil, true)
  end

  def enforcer_chaser_blocks_tile?(new_x, new_y)
    chaser = current_chase_character_for_map
    return false if !chaser || chaser.through
    return chaser.at_coordinate?(new_x, new_y)
  end

  def average_party_level
    return 1 if !$Trainer || !$Trainer.party
    total = 0
    count = 0
    $Trainer.party.each do |pokemon|
      next if !pokemon
      total += pokemon.level
      count += 1
    end
    return 1 if count <= 0
    return (total.to_f / count).round
  end

  def should_trigger_enforcer?
    return false if !$Trainer || !$PokemonGlobal || party_counterfeits.empty?
    return false if $Trainer.able_pokemon_count <= 0
    return false if !$game_map
    return false if enforcer_chase_active?
    if !Config::ALLOW_INDOOR_ENFORCERS
      return false if !GameData::MapMetadata.exists?($game_map.map_id)
      return false if !GameData::MapMetadata.get($game_map.map_id).outdoor_map
    end
    return false if defined?(pbInSafari?) && pbInSafari?
    return false if pbMapInterpreterRunning?
    return false if $PokemonTemp && $PokemonTemp.counterfeit_shiny_context
    state = global_state
    spotlight = spotlight_counterfeit
    heat_gain = Config::HEAT_PER_STEP + ([party_counterfeits.length - 1, 0].max * Config::HEAT_PER_EXTRA_COUNTERFEIT)
    state[:heat] += heat_gain
    state[:heat] = Config::HEAT_CAP if state[:heat] > Config::HEAT_CAP
    state[:step_meter] += 1
    data = counterfeit_data_for(spotlight)
    data[:peak_heat] = [data[:peak_heat].to_i, state[:heat].to_i].max if data
    threshold = Config::BASE_STEP_THRESHOLD
    threshold -= $Trainer.badge_count * Config::BADGE_STEP_REDUCTION
    threshold -= [party_counterfeits.length - 1, 0].max * Config::EXTRA_COUNTERFEIT_STEP_REDUCTION
    threshold -= market_value(spotlight) / Config::VALUE_STEP_REDUCTION_DIVISOR if spotlight
    threshold = Config::MIN_STEP_THRESHOLD if threshold < Config::MIN_STEP_THRESHOLD
    return false if state[:step_meter] < threshold
    state[:step_meter] = threshold / 2
    chance = Config::BASE_ENCOUNTER_CHANCE
    chance += state[:heat].to_i / 10 * Config::HEAT_ENCOUNTER_CHANCE_STEP
    chance += $Trainer.badge_count * Config::BADGE_ENCOUNTER_CHANCE_STEP
    chance += market_value(spotlight) / Config::VALUE_ENCOUNTER_CHANCE_DIVISOR if spotlight
    chance = Config::MAX_ENCOUNTER_CHANCE if chance > Config::MAX_ENCOUNTER_CHANCE
    return rand(100) < chance
  end

  def cool_heat_if_clean
    return if !$PokemonGlobal || party_counterfeits.length > 0
    state = global_state
    state[:heat] -= Config::HEAT_DECAY_WHEN_CLEAN
    state[:heat] = 0 if state[:heat] < 0
    state[:step_meter] = 0 if state[:heat] == 0
  end

  def build_enforcer_trainer
    trainer_type = nil
    Config::ENFORCER_TRAINER_TYPES.each do |candidate|
      next if !GameData::TrainerType.exists?(candidate)
      trainer_type = candidate
      break
    end
    if !trainer_type
      GameData::TrainerType::DATA.each_key do |key|
        next if !key.is_a?(Symbol)
        trainer_type = key
        break
      end
    end
    trainer_type = :SCIENTIST if !trainer_type
    trainer = NPCTrainer.new(Config::ENFORCER_NAMES.sample, trainer_type)
    trainer.id = rand(1_000_000)
    trainer.lose_text = "That forged finish just got more expensive..."
    trainer.items = []
    party, level_cap = build_enforcer_party(trainer)
    trainer.party = party
    trainer.instance_variable_set(:@counterfeit_level_cap, level_cap)
    return trainer
  end

  def build_enforcer_party(trainer)
    spotlight = spotlight_counterfeit
    level = current_enforcer_base_level
    max_level = GameData::GrowthRate.max_level
    team_size = 1 + (global_state[:enforcer_stage].to_i / Config::ENFORCER_TEAM_SIZE_STAGE_STEP)
    team_size += 1 if party_counterfeits.length >= 2
    team_size = Config::ENFORCER_MAX_TEAM_SIZE if team_size > Config::ENFORCER_MAX_TEAM_SIZE
    pool = Config::ENFORCER_POOL.find_all { |species| GameData::Species.exists?(species) }
    pool = Config::ENFORCER_POOL if pool.empty?
    party = []
    team_size.times do |i|
      species = pool.sample
      next if !species
      member_level = level + rand(0..3)
      member_level = max_level if member_level > max_level
      pokemon = Pokemon.new(species, member_level, trainer)
      party << pokemon
      break if party.length >= team_size
    end
    if party.empty?
      fallback = GameData::Species::DATA.keys.find { |key| key.is_a?(Symbol) }
      party << Pokemon.new(fallback, level, trainer) if fallback
    end
    level_cap = party.any? { |pkmn| pkmn.level >= max_level }
    return party, level_cap
  end

  def record_battle_use(pokemon)
    return if !pokemon || !counterfeit?(pokemon)
    return if !$PokemonTemp || !$PokemonTemp.counterfeit_shiny_context
    context = $PokemonTemp.counterfeit_shiny_context
    return if context[:type] != :enforcer
    context[:used_ids] ||= []
    data = counterfeit_data_for(pokemon)
    return if !data
    return if context[:used_ids].include?(data[:id])
    context[:used_ids] << data[:id]
  end

  def resolve_used_pokemon_ids
    context = ($PokemonTemp) ? $PokemonTemp.counterfeit_shiny_context : nil
    return [] if !context || !context[:used_ids].is_a?(Array)
    return context[:used_ids]
  end

  def find_counterfeit_by_id(counterfeit_id)
    return nil if counterfeit_id.nil?
    found = nil
    each_owned_reference(true, true) do |ref|
      data = counterfeit_data_for(ref[:pokemon])
      next if !data
      if data[:id] == counterfeit_id
        found = ref[:pokemon]
        break
      end
    end
    return found
  end

  def prestige_target_after_battle
    context = ($PokemonTemp) ? $PokemonTemp.counterfeit_shiny_context : nil
    return nil if !context
    used = resolve_used_pokemon_ids
    if used.include?(context[:target_id])
      return find_counterfeit_by_id(context[:target_id])
    end
    used.each do |counterfeit_id|
      pokemon = find_counterfeit_by_id(counterfeit_id)
      return pokemon if pokemon
    end
    return nil
  end

  def trigger_enforcer_encounter(forced = false, opening_lines = nil, forced_role = nil)
    return false if !forced && !should_trigger_enforcer?
    return false if !$Trainer || !$PokemonGlobal || party_counterfeits.empty?
    return false if $Trainer.able_pokemon_count <= 0
    return false if !$game_map
    return false if pbMapInterpreterRunning?
    return false if ($PokemonTemp && $PokemonTemp.counterfeit_shiny_context) || enforcer_chase_active?
    target = spotlight_counterfeit
    return false if !target
    context = build_enforcer_context(target, forced_role)
    return false if !context
    return start_enforcer_chase(context, opening_lines)
  end

  def handle_enforcer_battle_end(decision)
    return if !$PokemonTemp || !$PokemonTemp.counterfeit_shiny_context
    context = $PokemonTemp.counterfeit_shiny_context
    return if context[:type] != :enforcer
    state = global_state
    case decision
    when 1
      state[:wins] += 1
      state[:heat] -= Config::WIN_HEAT_REDUCTION
      state[:heat] = 0 if state[:heat] < 0
      recipient = prestige_target_after_battle
      if recipient
        data = counterfeit_data_for(recipient)
        data[:enforcer_wins] += Config::PRESTIGE_WINS_GAIN
        data[:battle_uses] += Config::BATTLE_USE_GAIN
        data[:notoriety] += Config::NOTORIETY_GAIN_WIN
        data[:sale_bonus] += Config::SALE_BONUS_PER_WIN
        pbMessage(_INTL("{1}'s forged finish earns new whispers on the black market.", recipient.name))
      end
      if context[:level_cap]
        grant_laundering_tokens
        state[:level_cap_wins] += 1
        pbMessage(_INTL("You seize a {1}. The bedroom PC can now scrub one counterfeit tag without stripping the forged shine.", Config::LAUNDER_REWARD_NAME))
      end
    when 2, 5
      state[:losses] += 1
      state[:heat] = Config::LOSS_HEAT_RESET
      reset_enforcer_stage!
      target = find_counterfeit_by_id(context[:target_id])
      if target
        if Config::STRIP_IF_LAST_OWNED && !safe_to_remove_entire_pokemon?(target)
          strip_instead_of_confiscating!(target)
          pbMessage(_INTL("The enforcer strips the counterfeit finish from {1} and lets the Pokemon go.", target.name))
        elsif remove_owned_pokemon(target, :confiscated)
          state[:last_confiscated] = target.species
          pbMessage(_INTL("The enforcer confiscates {1} as evidence and vanishes into the crowd.", target.name))
        end
      end
    end
  ensure
    $PokemonTemp.counterfeit_shiny_context = nil if $PokemonTemp
  end

  def player_status_text
    party = party_counterfeits.length
    stored = 0
    each_owned_reference(true, true) do |ref|
      next if !counterfeit?(ref[:pokemon])
      next if ref[:location] == :party
      stored += 1
    end
    spotlight = spotlight_counterfeit
    lines = []
    lines << "#{Config::FACTION_NAME} Heat: #{heat_label}"
    lines << "Party Stock: #{party}"
    lines << "Stored Stock: #{stored}"
    lines << "#{Config::LAUNDER_REWARD_NAME}s: #{laundering_token_count}"
    if spotlight
      lines << "Spotlight: #{spotlight.name} (#{format_money(market_value(spotlight))})"
    else
      lines << "Spotlight: None"
    end
    return lines.join("\n")
  end

  def apply_fake_shiny_render!(bitmap, pokemon, make_shiny = true)
    return bitmap if !bitmap || !pokemon
    return bitmap if !make_shiny
    return bitmap if true_shiny?(pokemon)
    return bitmap if !render_fake_shiny?(pokemon)
    if defined?(access_deprecated_kurayshiny) && access_deprecated_kurayshiny() == 1
      if bitmap.respond_to?(:shiftColors)
        bitmap.shiftColors(
          GameData::Species.calculateShinyHueOffset(
            pokemon.species,
            pokemon.bodyShiny?,
            pokemon.headShiny?
          )
        )
      end
    elsif bitmap.respond_to?(:pbGiveFinaleColor)
      shiny_omega = pokemon.respond_to?(:shinyOmega?) ? pokemon.shinyOmega? : {}
      bitmap.pbGiveFinaleColor(
        pokemon.shinyR?,
        pokemon.shinyG?,
        pokemon.shinyB?,
        pokemon.shinyValue?,
        pokemon.shinyKRS?,
        shiny_omega
      )
    end
    return bitmap
  end

  def strip_trade_counterfeit!(pokemon)
    return if !pokemon
    return if !Config::STRIP_IMPORTED_TRADE_COUNTERFEITS
    return if !counterfeit?(pokemon)
    clear_counterfeit!(pokemon)
  end

  def counterfeit_snapshot(pokemon)
    return nil if !counterfeit?(pokemon)
    return {
      :data   => deep_clone(counterfeit_data_for(pokemon)),
      :visual => capture_visual_state(pokemon)
    }
  end

  def apply_snapshot!(pokemon, snapshot, source = Config::DEFAULT_SOURCE)
    return false if !pokemon || !snapshot
    pokemon.counterfeit_shiny_data = deep_clone(snapshot[:data])
    ensure_data_defaults!(pokemon)
    pokemon.counterfeit_shiny_data[:created_source] = source if source
    restore_visual_state(pokemon, snapshot[:visual])
    pokemon.fakeshiny = true
    return true
  end

  def merge_snapshots(primary_snapshot, secondary_snapshot)
    return secondary_snapshot if !primary_snapshot
    return primary_snapshot if !secondary_snapshot
    base = (primary_snapshot[:data][:enforcer_wins].to_i >= secondary_snapshot[:data][:enforcer_wins].to_i) ? primary_snapshot : secondary_snapshot
    other = (base.equal?(primary_snapshot)) ? secondary_snapshot : primary_snapshot
    merged = deep_clone(base)
    merged[:data][:enforcer_wins] += other[:data][:enforcer_wins].to_i
    merged[:data][:battle_uses] += other[:data][:battle_uses].to_i
    merged[:data][:sale_bonus] += other[:data][:sale_bonus].to_i + Config::FUSION_MERGE_BONUS
    merged[:data][:notoriety] += (other[:data][:notoriety].to_i / 2)
    merged[:visual][:shinyValue] = ((base[:visual][:shinyValue].to_i + other[:visual][:shinyValue].to_i) / 2.0).round
    merged[:visual][:shinyKRS] = sanitize_krs([
      ((base[:visual][:shinyKRS][0].to_i + other[:visual][:shinyKRS][0].to_i) / 2.0).round,
      ((base[:visual][:shinyKRS][1].to_i + other[:visual][:shinyKRS][1].to_i) / 2.0).round,
      ((base[:visual][:shinyKRS][2].to_i + other[:visual][:shinyKRS][2].to_i) / 2.0).round,
      0, 0, 0, 0, 0, 0
    ])
    return merged
  end
end
