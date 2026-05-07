if defined?(TravelExpansionFramework) && !defined?(STARTER_REGIONS)
  STARTER_REGIONS = TravelExpansionFramework.anil_default_starter_regions
end

module TravelExpansionFramework
  module_function

  def anil_mode_states
    @anil_mode_states ||= {}
  end

  def anil_mode_key(key)
    return key.to_s.downcase.gsub(/[^a-z0-9]+/, "_").sub(/\A_+/, "").sub(/_+\z/, "").to_sym
  rescue
    return :unknown
  end

  def anil_mode_enabled?(key, default = false)
    mode_key = anil_mode_key(key)
    states = anil_mode_states
    return states[mode_key] if states.has_key?(mode_key)
    return default ? true : false
  rescue
    return default ? true : false
  end

  def anil_set_mode_enabled(key, value)
    anil_mode_states[anil_mode_key(key)] = value ? true : false
    return anil_mode_states[anil_mode_key(key)]
  rescue
    return value ? true : false
  end

  def anil_toggle_mode(key)
    return anil_set_mode_enabled(key, !anil_mode_enabled?(key))
  rescue
    return false
  end

  def anil_any_challenge_mode_enabled?
    anil_mode_states.any? { |key, value| value && key.to_s.start_with?("challenge_") }
  rescue
    return false
  end

  def anil_trainer_has_species?(trainer, species, form = -1, gender = -1, shiny = false)
    form_value = integer(form, -1)
    gender_value = integer(gender, -1)
    shiny_required = boolean(shiny, false)
    party = trainer.pokemon_party if trainer && trainer.respond_to?(:pokemon_party)
    party = trainer.party if (!party || party.empty?) && trainer && trainer.respond_to?(:party)
    Array(party).any? do |pokemon|
      next false if pokemon.nil?
      if pokemon.respond_to?(:isSpecies?)
        next false if !pokemon.isSpecies?(species)
      else
        next false if !pokemon.respond_to?(:species) || pokemon.species != species
      end
      next false if form_value >= 0 && (!pokemon.respond_to?(:form) || integer(pokemon.form, -99) != form_value)
      next false if gender_value >= 0 && (!pokemon.respond_to?(:gender) || integer(pokemon.gender, -99) != gender_value)
      next false if shiny_required && (!pokemon.respond_to?(:shiny?) || !pokemon.shiny?)
      true
    end
  rescue => e
    log("[anil] has_species? compatibility failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end
end if defined?(TravelExpansionFramework)

if !defined?(ButtonEventScene)
  class ButtonEventScene
    def pbStartScene(*_args)
      return 0
    end

    def pbEndScene(*_args)
      return true
    end
  end
end

if !defined?(RandomizedChallenge)
  module RandomizedChallenge
    RANDOMIZE_TM_MOVES = false if !const_defined?(:RANDOMIZE_TM_MOVES)
    def self.enabled?(*_args); return false; end
    def self.randomize_pokemon?; return false; end
    def self.moves_on?; return false; end
    def self.randomize_items?; return false; end
    def self.wild_paused?(*_args); return false; end
    def self.resume_random_species(*_args); return true; end
    def self.pause_random_species(*_args); return true; end
  end
else
  module RandomizedChallenge
    RANDOMIZE_TM_MOVES = false if !const_defined?(:RANDOMIZE_TM_MOVES)
    def self.enabled?(*_args); return false; end if !respond_to?(:enabled?)
    def self.randomize_pokemon?; return false; end if !respond_to?(:randomize_pokemon?)
    def self.moves_on?; return false; end if !respond_to?(:moves_on?)
    def self.randomize_items?; return false; end if !respond_to?(:randomize_items?)
    def self.wild_paused?(*_args); return false; end if !respond_to?(:wild_paused?)
    def self.resume_random_species(*_args); return true; end if !respond_to?(:resume_random_species)
    def self.pause_random_species(*_args); return true; end if !respond_to?(:pause_random_species)
  end
end

if !defined?(LevelCapsEX)
  module LevelCapsEX; end
end

class << LevelCapsEX
  def enabled?(*_args)
    return TravelExpansionFramework.anil_mode_enabled?(:level_caps_ex, false) if defined?(TravelExpansionFramework) &&
                                                                               TravelExpansionFramework.respond_to?(:anil_mode_enabled?)
    return false
  rescue
    return false
  end unless method_defined?(:enabled?)

  def enabled(*args); return enabled?(*args); end unless method_defined?(:enabled)
  def on?(*args); return enabled?(*args); end unless method_defined?(:on?)
  def off?(*args); return !enabled?(*args); end unless method_defined?(:off?)

  def enable(*_args)
    TravelExpansionFramework.anil_set_mode_enabled(:level_caps_ex, true) if defined?(TravelExpansionFramework) &&
                                                                            TravelExpansionFramework.respond_to?(:anil_set_mode_enabled)
    return true
  rescue
    return true
  end unless method_defined?(:enable)

  def disable(*_args)
    TravelExpansionFramework.anil_set_mode_enabled(:level_caps_ex, false) if defined?(TravelExpansionFramework) &&
                                                                             TravelExpansionFramework.respond_to?(:anil_set_mode_enabled)
    return true
  rescue
    return true
  end unless method_defined?(:disable)

  def toggle(*_args)
    return TravelExpansionFramework.anil_toggle_mode(:level_caps_ex) if defined?(TravelExpansionFramework) &&
                                                                       TravelExpansionFramework.respond_to?(:anil_toggle_mode)
    return true
  rescue
    return true
  end unless method_defined?(:toggle)
end if defined?(LevelCapsEX)

if !defined?(FollowingPkmn)
  module FollowingPkmn; end
end

class << FollowingPkmn
  def toggle_on(*args)
    return TravelExpansionFramework.anil_following_toggle!(true, *args) if defined?(TravelExpansionFramework) &&
                                                                          TravelExpansionFramework.respond_to?(:anil_following_toggle!)
    return true
  end unless method_defined?(:toggle_on)

  def toggle_off(*args)
    return TravelExpansionFramework.anil_following_toggle!(false, *args) if defined?(TravelExpansionFramework) &&
                                                                           TravelExpansionFramework.respond_to?(:anil_following_toggle!)
    return true
  end unless method_defined?(:toggle_off)

  def refresh(*args)
    return TravelExpansionFramework.anil_following_refresh!(*args) if defined?(TravelExpansionFramework) &&
                                                                      TravelExpansionFramework.respond_to?(:anil_following_refresh!)
    return true
  end unless method_defined?(:refresh)

  def start_following(*args)
    return TravelExpansionFramework.anil_following_start!(*args) if defined?(TravelExpansionFramework) &&
                                                                    TravelExpansionFramework.respond_to?(:anil_following_start!)
    return true
  end unless method_defined?(:start_following)

  def move_route(*args)
    return TravelExpansionFramework.anil_following_move_route!(*args) if defined?(TravelExpansionFramework) &&
                                                                        TravelExpansionFramework.respond_to?(:anil_following_move_route!)
    return true
  end unless method_defined?(:move_route)
end if defined?(FollowingPkmn)

if !defined?(PartyPicture)
  class PartyPicture
    def initialize(*event_ids)
      TravelExpansionFramework.anil_setup_party_picture_events(event_ids) if defined?(TravelExpansionFramework) &&
                                                                             TravelExpansionFramework.respond_to?(:anil_setup_party_picture_events)
    rescue => e
      TravelExpansionFramework.log("[anil] PartyPicture bridge failed: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                     TravelExpansionFramework.respond_to?(:log)
    end
  end
end

if !defined?(ChallengeModes)
  module ChallengeModes; end
end

class << ChallengeModes
  def on?(mode = nil, *_args)
    return TravelExpansionFramework.anil_any_challenge_mode_enabled? if mode.nil? &&
                                                                       defined?(TravelExpansionFramework) &&
                                                                       TravelExpansionFramework.respond_to?(:anil_any_challenge_mode_enabled?)
    return TravelExpansionFramework.anil_mode_enabled?("challenge_#{mode}", false) if defined?(TravelExpansionFramework) &&
                                                                                     TravelExpansionFramework.respond_to?(:anil_mode_enabled?)
    return false
  rescue
    return false
  end unless method_defined?(:on?)

  def enabled?(*args); return on?(*args); end unless method_defined?(:enabled?)

  def toggle(mode = nil, *_args)
    key = mode.nil? ? :challenge_modes : "challenge_#{mode}"
    return TravelExpansionFramework.anil_toggle_mode(key) if defined?(TravelExpansionFramework) &&
                                                            TravelExpansionFramework.respond_to?(:anil_toggle_mode)
    return true
  rescue
    return true
  end unless method_defined?(:toggle)

  def set_loss(*_args); return true; end unless method_defined?(:set_loss)
  def set_victory(*_args); return true; end unless method_defined?(:set_victory)
end if defined?(ChallengeModes)

if !defined?(RandomizerConfigurator)
  module RandomizerConfigurator; end
end

class << RandomizerConfigurator
  def toggle_randomize_pokemon(*_args); return true; end unless method_defined?(:toggle_randomize_pokemon)
end if defined?(RandomizerConfigurator)

class << RandomizedChallenge
  def tm_mart(*_args); return []; end unless method_defined?(:tm_mart)
end if defined?(RandomizedChallenge)

if defined?(PBMoveRoute)
  {
    :DOWN       => :Down,
    :LEFT       => :Left,
    :RIGHT      => :Right,
    :UP         => :Up,
    :TURN_RIGHT => :TurnRight
  }.each_pair do |compat_name, host_name|
    next if PBMoveRoute.const_defined?(compat_name, false)
    next if !PBMoveRoute.const_defined?(host_name, false)
    PBMoveRoute.const_set(compat_name, PBMoveRoute.const_get(host_name))
  end
end

if !defined?(PunchBag)
  module PunchBag; end
end

class << PunchBag
  def play_proportional_ev(*_args); return true; end unless method_defined?(:play_proportional_ev)
end if defined?(PunchBag)

if !defined?(DayCare)
  module DayCare; end
end

class << DayCare
  def get_details(*_args); return nil; end unless method_defined?(:get_details)
  def get_compatibility(*_args); return 0; end unless method_defined?(:get_compatibility)
  def choose(*_args); return nil; end unless method_defined?(:choose)
  def deposit(*_args); return true; end unless method_defined?(:deposit)
  def reset_egg_counters(*_args); return true; end unless method_defined?(:reset_egg_counters)
end if defined?(DayCare)

module Kernel
  def self.pbSetPokemonCenter(*args)
    if Object.private_method_defined?(:pbSetPokemonCenter) || Object.method_defined?(:pbSetPokemonCenter)
      return Object.new.send(:pbSetPokemonCenter, *args)
    end
    return true
  rescue
    return true
  end unless respond_to?(:pbSetPokemonCenter)
end

if !defined?(WildBattle)
  module WildBattle; end
end

class << WildBattle
  def start(species, level = 5, *_args)
    return Kernel.pbWildBattle(species, level) if defined?(Kernel) && Kernel.respond_to?(:pbWildBattle)
    return pbWildBattle(species, level) if defined?(pbWildBattle)
    return true
  rescue
    return true
  end unless method_defined?(:start)
end if defined?(WildBattle)

if defined?(Pokemon)
  class Pokemon
    class << self
      def play_cry(species, form = 0, volume = 90, pitch = nil)
        return pbPlayCrySpecies(species, form, volume, pitch) if defined?(pbPlayCrySpecies)
        return true
      rescue
        return true
      end unless method_defined?(:play_cry)
    end

    def make_shiny
      self.shiny = true if respond_to?(:shiny=)
      @shiny = true
      return true
    rescue
      return true
    end unless method_defined?(:make_shiny)

    def set_nature(nature)
      self.nature = nature if respond_to?(:nature=)
      return true
    rescue
      return true
    end unless method_defined?(:set_nature)

    def setForm(form = 0, *_args)
      self.form = form if respond_to?(:form=)
      calc_stats if respond_to?(:calc_stats)
      return true
    rescue
      return true
    end unless method_defined?(:setForm)

    def can_learn_egg_move?(*_args)
      return false
    end unless method_defined?(:can_learn_egg_move?)
  end
end

if defined?(PokemonGlobalMetadata)
  class PokemonGlobalMetadata
    attr_accessor :follower_toggled unless method_defined?(:follower_toggled)
    attr_accessor :nuzlocke unless method_defined?(:nuzlocke)
    attr_accessor :permalocke_loss unless method_defined?(:permalocke_loss)
  end
end

if defined?(DependentEvents)
  class DependentEvents
    def can_refresh?
      return true
    end unless method_defined?(:can_refresh?)

    def refresh_sprite(*_args)
      @lastUpdate = (@lastUpdate || 0) + 1 if instance_variable_defined?(:@lastUpdate)
      return true
    end unless method_defined?(:refresh_sprite)

    def remove_sprite(*_args)
      @lastUpdate = (@lastUpdate || 0) + 1 if instance_variable_defined?(:@lastUpdate)
      return true
    end unless method_defined?(:remove_sprite)
  end
end

if defined?(Trainer)
  class Trainer
    alias tef_anil_original_has_species? has_species? if method_defined?(:has_species?) &&
                                                         !method_defined?(:tef_anil_original_has_species?)

    def has_species?(species, form = -1, gender = -1, shiny = false, *_args)
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:anil_trainer_has_species?)
        return TravelExpansionFramework.anil_trainer_has_species?(self, species, form, gender, shiny)
      end
      return tef_anil_original_has_species?(species, form) if respond_to?(:tef_anil_original_has_species?, true)
      return Array(party).any? { |pkmn| pkmn && pkmn.respond_to?(:isSpecies?) && pkmn.isSpecies?(species) }
    rescue
      return false
    end
  end
end

if defined?(Player)
  class Player
    alias tef_anil_original_outfit_set outfit= if method_defined?(:outfit=) &&
                                                  !method_defined?(:tef_anil_original_outfit_set)
    alias tef_anil_original_has_species? has_species? if method_defined?(:has_species?) &&
                                                         !method_defined?(:tef_anil_original_has_species?)

    def outfit=(value)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:anil_suppress_player_outfit_assignment?) &&
         TravelExpansionFramework.anil_suppress_player_outfit_assignment?(value)
        TravelExpansionFramework.anil_note_suppressed_player_outfit!(value) if TravelExpansionFramework.respond_to?(:anil_note_suppressed_player_outfit!)
        return @outfit
      end
      return tef_anil_original_outfit_set(value) if respond_to?(:tef_anil_original_outfit_set, true)
      @outfit = value
      return value
    rescue
      @outfit = value
      return value
    end

    def has_species?(species, form = -1, gender = -1, shiny = false, *_args)
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:anil_trainer_has_species?)
        return TravelExpansionFramework.anil_trainer_has_species?(self, species, form, gender, shiny)
      end
      return tef_anil_original_has_species?(species, form) if respond_to?(:tef_anil_original_has_species?, true)
      return Array(party).any? { |pkmn| pkmn && pkmn.respond_to?(:isSpecies?) && pkmn.isSpecies?(species) }
    rescue
      return false
    end

    def connecting_online
      return @tef_anil_connecting_online ? true : false
    rescue
      return false
    end unless method_defined?(:connecting_online)

    def connecting_online=(value)
      @tef_anil_connecting_online = value ? true : false
    rescue
      @tef_anil_connecting_online = false
    end unless method_defined?(:connecting_online=)

    def connecting_online?
      return connecting_online
    rescue
      return false
    end unless method_defined?(:connecting_online?)

    def stars
      @tef_anil_stars = TravelExpansionFramework.integer(@tef_anil_stars, 0) if defined?(TravelExpansionFramework)
      return @tef_anil_stars || 0
    rescue
      return 0
    end unless method_defined?(:stars)

    def stars=(value)
      @tef_anil_stars = defined?(TravelExpansionFramework) ? TravelExpansionFramework.integer(value, 0) : value.to_i
    rescue
      @tef_anil_stars = 0
    end unless method_defined?(:stars=)

    def find_pokemon_of_species(species)
      target = species.to_s.upcase
      Array(party).find do |pkmn|
        next false if pkmn.nil?
        pkmn_species = pkmn.species if pkmn.respond_to?(:species)
        pkmn_species.to_s.upcase == target
      end
    rescue
      return nil
    end unless method_defined?(:find_pokemon_of_species)

    def give_status_party_pokemon(status, limit = nil, chance = 100, *_args)
      amount = TravelExpansionFramework.integer(limit, 0)
      amount = Array(party).length if amount <= 0
      applied = 0
      Array(party).each do |pkmn|
        next if pkmn.nil? || applied >= amount
        next if rand(100) >= TravelExpansionFramework.integer(chance, 100)
        if pkmn.respond_to?(:status=)
          pkmn.status = status
          applied += 1
        end
      end
      return applied
    rescue
      return 0
    end unless method_defined?(:give_status_party_pokemon)
  end
end

class NilClass
  def mystery_gift_unlocked; return false; end unless method_defined?(:mystery_gift_unlocked)
  def mystery_gift_unlocked=(_value); return false; end unless method_defined?(:mystery_gift_unlocked=)
  def new_game_plus_unlocked; return false; end unless method_defined?(:new_game_plus_unlocked)
  def new_game_plus_unlocked=(_value); return false; end unless method_defined?(:new_game_plus_unlocked=)
  def connecting_online; return false; end unless method_defined?(:connecting_online)
  def connecting_online=(_value); return false; end unless method_defined?(:connecting_online=)
  def connecting_online?; return false; end unless method_defined?(:connecting_online?)
  def stars; return 0; end unless method_defined?(:stars)
  def stars=(_value); return 0; end unless method_defined?(:stars=)
  def badge_count; return 0; end unless method_defined?(:badge_count)
  def lowest_difficulty; return 0; end unless method_defined?(:lowest_difficulty)
  def game_mode; return 0; end unless method_defined?(:game_mode)
  def male?; return false; end unless method_defined?(:male?)
  def female?; return false; end unless method_defined?(:female?)
  def name; return "Player"; end unless method_defined?(:name)
  def party; return []; end unless method_defined?(:party)
end

if defined?(Player::Pokedex)
  class Player::Pokedex
    def lock(*_args)
      @tef_anil_locked = true
      return true
    end unless method_defined?(:lock)

    def unlock(*_args)
      @tef_anil_locked = false
      return true
    end unless method_defined?(:unlock)
  end
end

module TravelExpansionFramework
  module_function

  def anil_starter_pool(region_index = 0)
    regions = defined?(STARTER_REGIONS) ? STARTER_REGIONS : anil_default_starter_regions
    region = Array(regions)[integer(region_index, 0)] || Array(regions).first
    starters = region.is_a?(Array) ? region[1] : nil
    starters = region if starters.nil?
    starters = Array(starters).map { |entry| entry.is_a?(Symbol) ? entry : entry.to_s.upcase.to_sym }
    starters = [:BULBASAUR, :CHARMANDER, :SQUIRTLE] if starters.empty?
    return starters
  rescue
    return [:BULBASAUR, :CHARMANDER, :SQUIRTLE]
  end

  def anil_valid_species(symbol)
    data = GameData::Species.try_get(symbol) rescue nil
    return data.id if data
    if defined?(CustomSpeciesFramework) && CustomSpeciesFramework.respond_to?(:compatibility_alias_target)
      alias_target = CustomSpeciesFramework.compatibility_alias_target(symbol) rescue nil
      data = GameData::Species.try_get(alias_target) rescue nil
      return data.id if data
    end
    return nil
  rescue
    return nil
  end

  def anil_choose_starter(region_index = 0, slot_index = nil)
    pool = anil_starter_pool(region_index)
    if slot_index.nil?
      slot = rand(pool.length)
    else
      slot = [[integer(slot_index, 0), 0].max, pool.length - 1].min
    end
    chosen = pool[slot]
    return anil_valid_species(chosen) || anil_valid_species(:BULBASAUR) || :BULBASAUR
  rescue
    return :BULBASAUR
  end

  ANIL_FOLLOWER_EVENT_NAME = "AnilFollower" if !const_defined?(:ANIL_FOLLOWER_EVENT_NAME, false)

  def anil_party_members
    trainer = ($Trainer rescue nil)
    trainer ||= ($player rescue nil)
    party = trainer.party if trainer && trainer.respond_to?(:party)
    return Array(party).compact
  rescue
    return []
  end

  def anil_first_followable_pokemon
    party = anil_party_members
    living = party.find do |pkmn|
      next false if pkmn.nil?
      next false if pkmn.respond_to?(:egg?) && pkmn.egg?
      hp = pkmn.hp if pkmn.respond_to?(:hp)
      hp.nil? || hp.to_i > 0
    end
    return living || party.find { |pkmn| pkmn && !(pkmn.respond_to?(:egg?) && pkmn.egg?) }
  rescue
    return nil
  end

  def anil_character_bitmap_available?(logical_name)
    logical = logical_name.to_s.gsub("\\", "/").sub(/\A\/+/, "")
    return false if logical.empty?
    return true if defined?(pbResolveBitmap) && pbResolveBitmap("Graphics/Characters/#{logical}")
    return false
  rescue
    return false
  end

  def anil_species_graphic_candidates(species, form = 0, gender = nil)
    data = GameData::Species.get(species) rescue nil
    species_symbol = (data && data.respond_to?(:species)) ? data.species : species
    species_text = species_symbol.to_s
    id_number = (data && data.respond_to?(:id_number)) ? integer(data.id_number, 0) : 0
    form_value = integer(form, 0)
    gender_value = integer(gender, -1)
    candidates = []
    forms = [form_value]
    forms << integer(data.form, 0) if data && data.respond_to?(:form)
    forms = forms.uniq.select { |value| value && value > 0 }
    forms.each do |value|
      candidates << "Followers/#{species_text}_#{value}_female" if gender_value == 1
      candidates << "Followers/#{species_text}_#{value}"
    end
    candidates << "Followers/#{species_text}_female" if gender_value == 1
    candidates << "Followers/#{species_text}"
    if id_number > 0
      id_text = format("%03d", id_number)
      forms.each do |value|
        candidates << "Overworld/#{id_text}_#{value}"
      end
      candidates << "Overworld/#{id_text}"
    end
    return candidates
  rescue
    return []
  end

  def anil_fusion_base_species_candidates(pokemon)
    return [] if pokemon.nil?
    data = pokemon.species_data if pokemon.respond_to?(:species_data)
    dex_num = data.id_number if data && data.respond_to?(:id_number)
    dex_num ||= getDexNumberForSpecies(pokemon.species) if defined?(getDexNumberForSpecies) && pokemon.respond_to?(:species)
    dex_num = integer(dex_num, 0)
    return [] if dex_num <= 0
    body_id = getBodyID(dex_num) if defined?(getBodyID)
    head_id = getHeadID(dex_num, body_id) if defined?(getHeadID)
    return [body_id, head_id].compact.map { |value| integer(value, 0) }.select { |value| value > 0 }.uniq
  rescue
    return []
  end

  def anil_follower_charset_for_pokemon(pokemon)
    candidates = []
    if pokemon
      species = pokemon.species if pokemon.respond_to?(:species)
      form = pokemon.form if pokemon.respond_to?(:form)
      gender = pokemon.gender if pokemon.respond_to?(:gender)
      candidates.concat(anil_species_graphic_candidates(species, form, gender)) if species
      fusion = pokemon.isFusion? if pokemon.respond_to?(:isFusion?)
      if fusion
        anil_fusion_base_species_candidates(pokemon).each do |base_id|
          candidates.concat(anil_species_graphic_candidates(base_id, 0, gender))
        end
      end
    end
    candidates << "Followers/000"
    candidates << "000"
    candidates = candidates.compact.map(&:to_s).reject(&:empty?).uniq
    chosen = candidates.find { |logical| anil_character_bitmap_available?(logical) }
    return chosen || "Followers/000"
  rescue => e
    log("[anil] follower charset resolution failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return "Followers/000"
  end

  def anil_apply_event_charset!(event, logical_name, direction = 2, pattern = 0)
    return false if event.nil?
    logical = logical_name.to_s.gsub("\\", "/").sub(/\A\/+/, "")
    logical = "Followers/000" if logical.empty?
    event.character_name = logical if event.respond_to?(:character_name=)
    event.character_hue = 0 if event.respond_to?(:character_hue=)
    event.transparent = false if event.respond_to?(:transparent=)
    event.through = true if event.respond_to?(:through=)
    event.direction = integer(direction, 2) if event.respond_to?(:direction=)
    event.pattern = integer(pattern, 0) if event.respond_to?(:pattern=)
    event.walk_anime = true if event.respond_to?(:walk_anime=)
    event.set_opacity(255) if event.respond_to?(:set_opacity)
    event.instance_variable_set(:@opacity, 255) if event.instance_variable_defined?(:@opacity)
    event.instance_variable_set(:@tile_id, 0) if event.instance_variable_defined?(:@tile_id)
    event.instance_variable_set(:@tef_anil_runtime_charset, logical)
    event.calculate_bush_depth if event.respond_to?(:calculate_bush_depth)
    return true
  rescue => e
    log("[anil] failed to apply event charset #{logical_name.inspect}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_hide_runtime_charset_event!(event)
    return false if event.nil?
    event.character_name = "" if event.respond_to?(:character_name=)
    event.transparent = true if event.respond_to?(:transparent=)
    event.through = true if event.respond_to?(:through=)
    event.set_opacity(0) if event.respond_to?(:set_opacity)
    event.instance_variable_set(:@opacity, 0) if event.instance_variable_defined?(:@opacity)
    event.instance_variable_set(:@tile_id, 0) if event.instance_variable_defined?(:@tile_id)
    event.remove_instance_variable(:@tef_anil_runtime_charset) if event.instance_variable_defined?(:@tef_anil_runtime_charset)
    event.calculate_bush_depth if event.respond_to?(:calculate_bush_depth)
    return true
  rescue
    return false
  end

  def anil_party_picture_event_usable?(event)
    return false if event.nil?
    return true if event.instance_variable_defined?(:@tef_anil_party_picture_event)
    name = event.name.to_s.downcase rescue ""
    return true if name.include?("poke foto") || name.include?("pokefoto") || name.include?("foto ")
    character_name = event.respond_to?(:character_name) ? event.character_name.to_s : ""
    return false if !character_name.empty?
    trigger = event.respond_to?(:trigger) ? event.trigger : nil
    list = event.respond_to?(:list) ? event.list : nil
    return false if trigger && trigger != 0
    return false if list && list.respond_to?(:length) && list.length > 1
    return true
  rescue
    return false
  end

  def anil_setup_party_picture_events(event_ids)
    return false if !anil_event_context_active?
    return false if !defined?($game_map) || !$game_map || !$game_map.respond_to?(:events)
    ids = Array(event_ids).flatten.map { |id| integer(id, 0) }.select { |id| id > 0 }.uniq
    return false if ids.empty?
    party = anil_party_members.reject { |pkmn| pkmn.respond_to?(:egg?) && pkmn.egg? }
    applied = []
    ids.each_with_index do |event_id, index|
      event = $game_map.events[event_id] rescue nil
      next if !anil_party_picture_event_usable?(event)
      pokemon = party[index]
      if pokemon
        charset = anil_follower_charset_for_pokemon(pokemon)
        next if !anil_apply_event_charset!(event, charset, 2, 0)
        event.instance_variable_set(:@tef_anil_party_picture_event, true)
        applied << event_id
      else
        anil_hide_runtime_charset_event!(event)
      end
    end
    @anil_party_picture_event_ids = applied
    log("[anil] PartyPicture displayed #{applied.length} party sprite(s) on map #{$game_map.map_id}") if respond_to?(:log) && !applied.empty?
    return true
  rescue => e
    log("[anil] PartyPicture setup failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_clear_party_picture_events(event_ids = nil)
    return false if !defined?($game_map) || !$game_map || !$game_map.respond_to?(:events)
    requested = Array(event_ids).flatten.map { |id| integer(id, 0) }.select { |id| id > 0 }
    applied = Array(@anil_party_picture_event_ids)
    ids = (requested.empty? ? applied : (requested & applied)).uniq
    ids.each do |event_id|
      event = $game_map.events[event_id] rescue nil
      next if !event || !event.instance_variable_defined?(:@tef_anil_party_picture_event)
      anil_hide_runtime_charset_event!(event)
      event.remove_instance_variable(:@tef_anil_party_picture_event) if event.instance_variable_defined?(:@tef_anil_party_picture_event)
    end
    @anil_party_picture_event_ids = applied - ids
    return true
  rescue => e
    log("[anil] PartyPicture cleanup failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_dependent_events
    return nil if !defined?($PokemonTemp) || !$PokemonTemp || !$PokemonTemp.respond_to?(:dependentEvents)
    return $PokemonTemp.dependentEvents
  rescue
    return nil
  end

  def anil_primary_follower_event
    dependent = anil_dependent_events
    return nil if dependent.nil?
    event = dependent.getEventByName(ANIL_FOLLOWER_EVENT_NAME) rescue nil
    event ||= dependent.getEventByName("Dependent") rescue nil
    return event if event
    events = dependent.realEvents if dependent.respond_to?(:realEvents)
    return Array(events).compact.first
  rescue
    return nil
  end

  def anil_set_follower_visible!(enabled)
    @anil_following_enabled = enabled ? true : false
    if defined?($PokemonGlobal) && $PokemonGlobal && $PokemonGlobal.respond_to?(:follower_toggled=)
      $PokemonGlobal.follower_toggled = @anil_following_enabled
    end
    event = anil_primary_follower_event
    if event
      event.transparent = !@anil_following_enabled if event.respond_to?(:transparent=)
      event.set_opacity(@anil_following_enabled ? 255 : 0) if event.respond_to?(:set_opacity)
      event.instance_variable_set(:@opacity, @anil_following_enabled ? 255 : 0) if event.instance_variable_defined?(:@opacity)
      event.through = true if event.respond_to?(:through=)
    end
    dependent = anil_dependent_events
    dependent.refresh_sprite if @anil_following_enabled && dependent && dependent.respond_to?(:refresh_sprite)
    dependent.remove_sprite(true) if !@anil_following_enabled && dependent && dependent.respond_to?(:remove_sprite)
    return true
  rescue
    return true
  end

  def anil_following_start!(event_id = nil, *_args)
    return true if !anil_event_context_active?
    dependent = anil_dependent_events
    source_event = nil
    numeric_event_id = integer(event_id, 0)
    if numeric_event_id > 0 && defined?($game_map) && $game_map && $game_map.respond_to?(:events)
      source_event = $game_map.events[numeric_event_id] rescue nil
    end
    pokemon = anil_first_followable_pokemon
    charset = anil_follower_charset_for_pokemon(pokemon)
    direction = ($game_player.direction rescue 2)
    if dependent && source_event
      begin
        dependent.removeEventByName(ANIL_FOLLOWER_EVENT_NAME) if dependent.respond_to?(:removeEventByName)
      rescue
      end
      source_event.moveto($game_player.x, $game_player.y) if defined?($game_player) && $game_player && source_event.respond_to?(:moveto)
      anil_apply_event_charset!(source_event, charset, direction, 0)
      if dependent.respond_to?(:addEvent)
        dependent.addEvent(source_event, ANIL_FOLLOWER_EVENT_NAME, nil)
        follower = dependent.getEventByName(ANIL_FOLLOWER_EVENT_NAME) rescue nil
        anil_apply_event_charset!(follower, charset, direction, 0) if follower
      end
      @anil_following_event_id = numeric_event_id
      anil_set_follower_visible!(true)
      log("[anil] follower started from event #{numeric_event_id} using #{charset}") if respond_to?(:log)
      return true
    end
    follower = anil_primary_follower_event
    anil_apply_event_charset!(follower, charset, direction, 0) if follower
    anil_set_follower_visible!(true)
    return true
  rescue => e
    log("[anil] follower start failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def anil_following_refresh!(*_args)
    return true if !anil_event_context_active?
    follower = anil_primary_follower_event
    return anil_following_start!(@anil_following_event_id || 0) if follower.nil?
    pokemon = anil_first_followable_pokemon
    charset = anil_follower_charset_for_pokemon(pokemon)
    anil_apply_event_charset!(follower, charset, follower.direction, follower.pattern)
    anil_set_follower_visible!(@anil_following_enabled != false)
    return true
  rescue => e
    log("[anil] follower refresh failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def anil_following_toggle!(enabled, *_args)
    return true if !anil_event_context_active?
    anil_following_refresh! if enabled && anil_primary_follower_event.nil?
    anil_set_follower_visible!(enabled)
    return true
  rescue
    return true
  end

  def anil_following_move_route!(commands = [], wait_complete = false, *_args)
    return true if !anil_event_context_active?
    follower = anil_primary_follower_event
    return true if follower.nil?
    route = pbMoveRoute(follower, Array(commands).compact, wait_complete) if defined?(pbMoveRoute)
    return route || true
  rescue => e
    log("[anil] follower move route failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end

  def anil_event_context_active?(map_id = nil)
    return anil_active_now?(map_id) if respond_to?(:anil_active_now?)
    return false
  rescue
    return false
  end

  def anil_player_visual_keys
    return ["character_ID", "trainer_type", "outfit", "clothes", "hat", "hat2", "hair",
            "skin_tone", "clothes_color", "hat_color", "hat2_color", "hair_color"]
  end

  def anil_capture_host_player_visual_state!(label = "entry")
    trainer = $Trainer rescue nil
    return false if !trainer
    state = {}
    anil_player_visual_keys.each do |key|
      method_name = key.to_s
      state[method_name] = trainer.send(method_name) if trainer.respond_to?(method_name)
    end
    state["character_name"] = ($game_player.character_name rescue nil) if defined?($game_player) && $game_player
    anil_remember_value("host_player_visual_state", state) if respond_to?(:anil_remember_value)
    log("[anil] captured host player visual state for #{label}") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] host player visual capture failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_host_player_visual_state
    return anil_value("host_player_visual_state", nil) if respond_to?(:anil_value)
    return nil
  rescue
    return nil
  end

  def anil_suppress_player_outfit_assignment?(_value = nil)
    return false if @anil_restoring_player_visuals
    return false if !anil_event_context_active?
    return true
  rescue
    return false
  end

  def anil_note_suppressed_player_outfit!(value)
    @anil_suppressed_player_outfit_values ||= {}
    key = value.inspect
    return if @anil_suppressed_player_outfit_values[key]
    @anil_suppressed_player_outfit_values[key] = true
    log("[anil] suppressed imported player outfit #{key} to preserve host player sprite") if respond_to?(:log)
  rescue
  end

  def anil_restore_trainer_visual_state!(trainer, state)
    return false if !trainer || !state.is_a?(Hash)
    anil_player_visual_keys.each do |key|
      next if !state.has_key?(key)
      trainer.instance_variable_set("@#{key}", state[key])
    end
    return true
  rescue => e
    log("[anil] trainer visual state restore failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_refresh_player_sprite!(scene = nil)
    target_scene = scene || (defined?($scene) ? $scene : nil)
    if target_scene && target_scene.respond_to?(:reset_player_sprite)
      target_scene.reset_player_sprite
    elsif target_scene && target_scene.respond_to?(:spritesetGlobal)
      spriteset = target_scene.spritesetGlobal
      if spriteset && spriteset.respond_to?(:playersprite) && spriteset.playersprite
        spriteset.playersprite.updateBitmap if spriteset.playersprite.respond_to?(:updateBitmap)
        spriteset.playersprite.refreshOutfit if spriteset.playersprite.respond_to?(:refreshOutfit)
      end
    end
    return true
  rescue => e
    log("[anil] player sprite refresh failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_player_visuals_need_restore?
    trainer = $Trainer rescue nil
    return false if !trainer
    return true if trainer.respond_to?(:outfit) && integer(trainer.outfit, 0) == 2
    state = anil_host_player_visual_state
    if state.is_a?(Hash)
      ["character_ID", "trainer_type", "clothes", "hat", "hat2", "hair", "skin_tone"].each do |key|
        next if !state.has_key?(key) || !trainer.respond_to?(key)
        return true if trainer.send(key) != state[key]
      end
    end
    return true if defined?($game_player) && $game_player && $game_player.respond_to?(:hasGraphicsOverride?) &&
                   $game_player.hasGraphicsOverride?
    return false
  rescue
    return false
  end

  def anil_restore_host_player_visuals!(reason = "anil", scene = nil)
    trainer = $Trainer rescue nil
    @anil_restoring_player_visuals = true
    state = anil_host_player_visual_state
    anil_restore_trainer_visual_state!(trainer, state)
    if trainer && trainer.respond_to?(:outfit) && integer(trainer.outfit, 0) == 2
      trainer.instance_variable_set(:@outfit, 0)
    end
    apply_host_player_visuals!("anil #{reason}") if respond_to?(:apply_host_player_visuals!)
    anil_refresh_player_sprite!(scene)
    log("[anil] restored host player visuals after #{reason}") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] host player visual restore failed after #{reason}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  ensure
    @anil_restoring_player_visuals = false
  end

  def anil_player_visual_watchdog_tick!(scene = nil)
    return false if !anil_event_context_active?
    @anil_player_visual_watchdog_frame = integer(@anil_player_visual_watchdog_frame, 0) + 1
    return false if (@anil_player_visual_watchdog_frame % 30) != 0
    return false if !anil_player_visuals_need_restore?
    return anil_restore_host_player_visuals!("visual watchdog", scene)
  rescue => e
    log("[anil] player visual watchdog failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_log_once(key, message)
    @anil_log_once ||= {}
    return if @anil_log_once[key]
    @anil_log_once[key] = true
    log(message) if respond_to?(:log)
  rescue
  end

  def anil_translation_path
    root = anil_root_path
    return nil if root.to_s.empty?
    [
      File.join("Data", "messages_english_game.dat"),
      File.join("Data", "messages_english.dat"),
      File.join("Data", "English.dat"),
      File.join("Data", "english.dat")
    ].each do |relative|
      path = runtime_exact_file_path(File.join(root, relative)) if respond_to?(:runtime_exact_file_path)
      return path if path && File.file?(path)
    end
    return nil
  rescue
    return nil
  end

  def anil_translation_key_variants(text)
    variants = []
    variants.concat(opalo_translation_key_variants(text)) if respond_to?(:opalo_translation_key_variants)
    base = text.to_s.dup
    base.gsub!("\r", "")
    base.gsub!(/\\n/i, " ")
    base.gsub!("\n", " ")
    base.gsub!("\001", "")
    base.gsub!(/<\/?[^>]+>/, "")
    base.gsub!(/[ \t]+/, " ")
    base.strip!
    variants << base if !base.empty?
    compact = base.gsub(/[¡!¿\?\.,"'“”‘’]/, " ").gsub(/\s+/, " ").strip
    variants << compact if !compact.empty?
    return variants.compact.reject { |entry| entry.to_s.empty? }.uniq
  rescue
    return []
  end

  def anil_decode_translation_text(text)
    decoded = opalo_decode_translation_markup(text) if respond_to?(:opalo_decode_translation_markup)
    decoded ||= text.to_s.dup
    decoded.gsub!("&quot;", "\"")
    decoded.gsub!("\\PN", ($Trainer.name rescue "Player").to_s) if defined?($Trainer) && $Trainer
    return decoded
  rescue
    return text.to_s
  end

  def anil_collect_translation_entry!(catalog, source, translated, scope = nil)
    return if source.nil? || translated.nil?
    source_text = source.to_s
    translated_text = anil_decode_translation_text(translated)
    return if source_text.empty? || translated_text.empty?
    keys = anil_translation_key_variants(source_text)
    return if keys.empty?
    keys.each do |key|
      if !scope.nil?
        catalog[:maps][scope] ||= {}
        catalog[:maps][scope][key] = translated_text
      else
        catalog[:script][key] = translated_text
      end
      catalog[:all][key] = translated_text if !catalog[:all].has_key?(key)
    end
  rescue => e
    log("[anil] translation entry failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def anil_collect_translation_container!(catalog, container, scope = nil)
    case container
    when Hash
      container.each do |source, translated|
        if source.is_a?(String) && translated.is_a?(String)
          anil_collect_translation_entry!(catalog, source, translated, scope)
        else
          anil_collect_translation_container!(catalog, translated, scope)
        end
      end
    when Array
      container.each { |entry| anil_collect_translation_container!(catalog, entry, scope) }
    end
  rescue => e
    log("[anil] translation section failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end

  def anil_translation_catalog
    @anil_translation_catalog ||= begin
      catalog = {
        :loaded => true,
        :maps   => {},
        :script => {},
        :all    => {}
      }
      path = anil_translation_path
      if path && File.file?(path)
        data = File.open(path, "rb") { |file| Marshal.load(file) }
        if data.is_a?(Array)
          map_messages = data[0]
          if map_messages.is_a?(Array)
            map_messages.each_with_index do |entries, map_index|
              anil_collect_translation_container!(catalog, entries, map_index)
            end
          elsif map_messages.is_a?(Hash)
            map_messages.each do |map_index, entries|
              anil_collect_translation_container!(catalog, entries, integer(map_index, 0))
            end
          end
          data.each_with_index do |section, section_index|
            next if section_index == 0
            anil_collect_translation_container!(catalog, section, nil)
          end
        else
          anil_collect_translation_container!(catalog, data, nil)
        end
      end
      catalog
    end
    return @anil_translation_catalog
  rescue => e
    log("[anil] translation catalog load failed: #{e.class}: #{e.message}") if respond_to?(:log)
    @anil_translation_catalog = { :loaded => true, :maps => {}, :script => {}, :all => {} }
    return @anil_translation_catalog
  end

  def anil_current_local_map_id(map_id = nil)
    current_map_id = integer(map_id || ($game_map.map_id rescue 0), 0)
    return 0 if current_map_id <= 0
    expansion = active_project_expansion_id(anil_expansion_ids, current_map_id) || ANIL_EXPANSION_ID
    return local_map_id_for(expansion, current_map_id) if respond_to?(:local_map_id_for)
    return current_map_id
  rescue
    return 0
  end

  def anil_translate_text(text, map_id = nil)
    source = text.to_s
    return source if source.empty?
    trailer = source[/\001+\z/].to_s
    lookup_source = trailer.empty? ? source : source[0, source.length - trailer.length]
    keys = anil_translation_key_variants(lookup_source)
    return anil_manual_text_fixups(source) if keys.empty?
    catalog = anil_translation_catalog
    local_map_id = anil_current_local_map_id(map_id)
    translated = nil
    if catalog[:maps].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:maps][local_map_id][key] if translated.nil? && catalog[:maps][local_map_id].is_a?(Hash)
        translated = catalog[:maps][0][key] if translated.nil? && catalog[:maps][0].is_a?(Hash)
        break if translated
      end
    end
    if translated.nil? && catalog[:script].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:script][key]
        break if translated
      end
    end
    if translated.nil? && catalog[:all].is_a?(Hash)
      keys.each do |key|
        translated = catalog[:all][key]
        break if translated
      end
    end
    return anil_manual_text_fixups(source) if translated.nil? || translated.to_s.empty?
    return "#{anil_manual_text_fixups(anil_decode_translation_text(translated))}#{trailer}"
  rescue => e
    log("[anil] translation lookup failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return text.to_s
  end

  def anil_manual_text_fixups(text)
    result = text.to_s.dup
    return result if result.empty?
    replacements = {
      "Rival Rojo"        => "Rival Red",
      "Entrenador Rojo"   => "Trainer Red",
      "Campeon Rojo"      => "Champion Red",
      "Rojo"              => "Red",
      "Azul"              => "Blue",
      "Verde"             => "Green",
      "Pueblo Paleta"     => "Pallet Town",
      "Ciudad Verde"      => "Viridian City",
      "Bosque Verde"      => "Viridian Forest",
      "Ciudad Plateada"   => "Pewter City",
      "Ciudad Celeste"    => "Cerulean City",
      "Pueblo Lavanda"    => "Lavender Town",
      "Ciudad Azulona"    => "Celadon City",
      "Ciudad Fucsia"     => "Fuchsia City",
      "Ciudad Azafran"    => "Saffron City",
      "Isla Canela"       => "Cinnabar Island",
      "Calle Victoria"    => "Victory Road",
      "Islas Espuma"      => "Seafoam Islands",
      "Cueva Diglett"     => "Diglett's Cave",
      "Central Energia"   => "Power Plant",
      "Monte Moon"        => "Mt. Moon"
    }
    replacements.each_pair do |from, to|
      result.gsub!(/\b#{Regexp.escape(from)}\b/i, to)
    end
    result.gsub!(/\bRuta\s+(\d+)\b/i, "Route \\1")
    result.gsub!(/\bLaboratorio Pok.{0,4}mon\b/i, "Pokemon Lab")
    result.gsub!(/\bMansi.{1,4}n Pok.{0,4}mon\b/i, "Pokemon Mansion")
    result.gsub!(/\bCiudad Carm.{1,4}n\b/i, "Vermilion City")
    result.gsub!(/\bT.{1,4}nel Roca\b/i, "Rock Tunnel")
    result.gsub!(/\bMeseta A.{1,4}il\b/i, "Indigo Plateau")
    result.gsub!(/\bCueva Celeste\b/i, "Cerulean Cave")
    return result
  rescue
    return text.to_s
  end

  def anil_showdown_move_name(move)
    move_id = move.id if move && move.respond_to?(:id)
    data = GameData::Move.get(move_id) if defined?(GameData::Move) && move_id
    return data.real_name if data && data.respond_to?(:real_name)
    return data.name if data && data.respond_to?(:name)
    return move.name if move && move.respond_to?(:name)
    return move_id.to_s if move_id
    return nil
  rescue
    return nil
  end

  def anil_showdown_stat_line(label, values)
    stats = [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED]
    names = {
      :HP => "HP",
      :ATTACK => "Atk",
      :DEFENSE => "Def",
      :SPECIAL_ATTACK => "SpA",
      :SPECIAL_DEFENSE => "SpD",
      :SPEED => "Spe"
    }
    parts = stats.map do |stat|
      value = values[stat] if values.respond_to?(:[])
      value = values[stat.to_s] if value.nil? && values.respond_to?(:[])
      value = integer(value, 0)
      "#{value} #{names[stat]}"
    end
    return "#{label}: #{parts.join(' / ')}"
  rescue
    return "#{label}: 0 HP / 0 Atk / 0 Def / 0 SpA / 0 SpD / 0 Spe"
  end

  def anil_showdown_species_name(pokemon)
    species_data = pokemon.species_data if pokemon && pokemon.respond_to?(:species_data)
    return species_data.real_name if species_data && species_data.respond_to?(:real_name)
    return species_data.name if species_data && species_data.respond_to?(:name)
    species = pokemon.species if pokemon && pokemon.respond_to?(:species)
    data = GameData::Species.try_get(species) if defined?(GameData::Species) && species
    return data.real_name if data && data.respond_to?(:real_name)
    return data.name if data && data.respond_to?(:name)
    return species.to_s
  rescue
    return "Pokemon"
  end

  def anil_showdown_item_name(pokemon)
    item = pokemon.item if pokemon && pokemon.respond_to?(:item)
    return nil if item.nil?
    return item.name if item.respond_to?(:name)
    data = GameData::Item.try_get(item) if defined?(GameData::Item)
    return data.name if data && data.respond_to?(:name)
    return item.to_s
  rescue
    return nil
  end

  def anil_showdown_ability_name(pokemon)
    ability = pokemon.ability if pokemon && pokemon.respond_to?(:ability)
    return ability.name if ability && ability.respond_to?(:name)
    return ability.to_s if ability
    return "Unknown"
  rescue
    return "Unknown"
  end

  def anil_showdown_pokemon_text(pokemon)
    nickname = pokemon.name if pokemon && pokemon.respond_to?(:name)
    species_name = anil_showdown_species_name(pokemon)
    item_name = anil_showdown_item_name(pokemon)
    name_line = nickname.to_s.empty? ? species_name.to_s : "#{nickname} (#{species_name})"
    name_line = "#{name_line} @ #{item_name}" if item_name && !item_name.to_s.empty?
    lines = [name_line]
    lines << "Ability: #{anil_showdown_ability_name(pokemon)}"
    lines << "Level: #{integer((pokemon.level if pokemon.respond_to?(:level)), 1)}"
    if pokemon.respond_to?(:ev)
      lines << anil_showdown_stat_line("EVs", pokemon.ev || {})
    end
    if pokemon.respond_to?(:iv)
      lines << anil_showdown_stat_line("IVs", pokemon.iv || {})
    end
    moves = pokemon.moves if pokemon && pokemon.respond_to?(:moves)
    Array(moves).compact.each do |move|
      move_name = anil_showdown_move_name(move)
      lines << "- #{move_name}" if move_name && !move_name.to_s.empty?
    end
    return lines.join("\n")
  rescue => e
    log("[anil] pokepaste pokemon export failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return "Pokemon"
  end

  def anil_party_showdown_text
    ensure_player_global! if respond_to?(:ensure_player_global!)
    trainer = (defined?($player) && $player) ? $player : (defined?($Trainer) ? $Trainer : nil)
    party = trainer.party if trainer && trainer.respond_to?(:party)
    entries = Array(party).compact.map { |pokemon| anil_showdown_pokemon_text(pokemon) }
    return entries.join("\n\n")
  rescue => e
    log("[anil] pokepaste party export failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return ""
  end

  def anil_export_pokepaste!
    text = anil_party_showdown_text
    if text.to_s.empty?
      log("[anil] pokepaste export skipped because the party was empty") if respond_to?(:log)
      return false
    end
    Input.clipboard = text if defined?(Input) && Input.respond_to?(:clipboard=)
    log("[anil] copied pokepaste export for #{text.scan(/\n\n/).length + 1} Pokemon") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] pokepaste export failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_intro_interpreter_leaked?(interpreter, current_map_id = nil)
    return false if !interpreter
    expansion_id = interpreter_context_expansion_id(interpreter) if respond_to?(:interpreter_context_expansion_id)
    return false if expansion_id.to_s.empty?
    return false if !respond_to?(:canonical_new_project_id) && expansion_id.to_s != ANIL_EXPANSION_ID.to_s
    canonical = canonical_new_project_id(expansion_id) if respond_to?(:canonical_new_project_id)
    return false if canonical && canonical.to_s != ANIL_EXPANSION_ID.to_s
    interpreter_map = interpreter_context_map_id(interpreter)
    event_id = interpreter_context_event_id(interpreter)
    return false if integer(event_id, 0) <= 0
    local_interpreter_map = local_map_id_for(expansion_id, interpreter_map) if respond_to?(:local_map_id_for)
    local_interpreter_map ||= interpreter_map
    return false if integer(local_interpreter_map, 0) != 1
    current_map = integer(current_map_id, 0)
    current_map = current_loaded_map_id_for_interpreter_guard if current_map <= 0 && respond_to?(:current_loaded_map_id_for_interpreter_guard)
    return false if current_map <= 0 || current_map == interpreter_map
    log("[anil] cleared leaked intro interpreter from map #{interpreter_map} while current map is #{current_map}") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] intro interpreter guard failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_canonical_expansion_id(expansion_id)
    value = expansion_id.to_s
    return canonical_new_project_id(value).to_s if respond_to?(:canonical_new_project_id)
    return value
  rescue
    return expansion_id.to_s
  end

  def anil_map_context?(map_id = nil)
    id = integer(map_id || ($game_map.map_id rescue 0), 0)
    return false if id <= 0
    expansion = current_map_expansion_id(id) if respond_to?(:current_map_expansion_id)
    return anil_canonical_expansion_id(expansion) == ANIL_EXPANSION_ID.to_s
  rescue
    return false
  end

  def anil_local_map_for_runtime(map_id = nil)
    runtime_map = integer(map_id || ($game_map.map_id rescue 0), 0)
    return 0 if runtime_map <= 0
    expansion = current_map_expansion_id(runtime_map) if respond_to?(:current_map_expansion_id)
    expansion = ANIL_EXPANSION_ID if expansion.to_s.empty?
    return local_map_id_for(expansion, runtime_map) if respond_to?(:local_map_id_for)
    return runtime_map
  rescue
    return integer(map_id || ($game_map.map_id rescue 0), 0)
  end

  def anil_mark_recent_transfer!(previous_map_id = nil, current_map_id = nil)
    current = integer(current_map_id || ($game_map.map_id rescue 0), 0)
    return false if current <= 0 || !anil_map_context?(current)
    @anil_recent_transfer = {
      :previous_map_id => integer(previous_map_id, 0),
      :current_map_id  => current,
      :local_map_id    => anil_local_map_for_runtime(current),
      :frames          => 0,
      :recovered       => false
    }
    return true
  rescue => e
    log("[anil] failed to mark recent transfer: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_transition_visuals_dark?(scene = nil)
    screen = defined?($game_screen) ? $game_screen : nil
    return true if respond_to?(:screen_visuals_stuck_dark?) && screen_visuals_stuck_dark?(screen)
    if defined?(Graphics) && Graphics.respond_to?(:brightness)
      return true if visual_number(Graphics.brightness, 255) <= 5
    end
    renderer = scene.map_renderer if scene && scene.respond_to?(:map_renderer)
    if renderer
      tone = renderer.respond_to?(:tone) ? renderer.tone : nil
      color = renderer.respond_to?(:color) ? renderer.color : nil
      return true if dark_screen_tone?(tone) || opaque_black_color?(color)
    end
    return false
  rescue
    return false
  end

  def anil_clear_post_transfer_runtime_flags!(clear_message = false)
    if defined?($game_temp) && $game_temp
      $game_temp.player_transferring = false if $game_temp.respond_to?(:player_transferring=)
      $game_temp.transition_processing = false if $game_temp.respond_to?(:transition_processing=)
      $game_temp.menu_calling = false if $game_temp.respond_to?(:menu_calling=)
      $game_temp.debug_calling = false if $game_temp.respond_to?(:debug_calling=)
      $game_temp.in_menu = false if $game_temp.respond_to?(:in_menu=)
      $game_temp.moving_furniture = nil if $game_temp.respond_to?(:moving_furniture=)
      $game_temp.moving_furniture_oldPlayerPosition = nil if $game_temp.respond_to?(:moving_furniture_oldPlayerPosition=)
      $game_temp.moving_furniture_oldItemPosition = nil if $game_temp.respond_to?(:moving_furniture_oldItemPosition=)
      $game_temp.message_window_showing = false if clear_message && $game_temp.respond_to?(:message_window_showing=)
    end
    if defined?($PokemonTemp) && $PokemonTemp
      $PokemonTemp.miniupdate = false if $PokemonTemp.respond_to?(:miniupdate=)
      $PokemonTemp.hiddenMoveEventCalling = false if $PokemonTemp.respond_to?(:hiddenMoveEventCalling=)
      $PokemonTemp.keyItemCalling = false if $PokemonTemp.respond_to?(:keyItemCalling=)
      $PokemonTemp.encounterTriggered = false if $PokemonTemp.respond_to?(:encounterTriggered=)
      $PokemonTemp.waitingTrainer = nil if $PokemonTemp.respond_to?(:waitingTrainer=)
    end
    if defined?($chat_window) && $chat_window && $chat_window.respond_to?(:input_mode=)
      $chat_window.input_mode = false
    end
    return true
  rescue
    return false
  end

  def anil_clear_pending_transfer_target!(reason = "transfer complete")
    return false if !defined?($game_temp) || !$game_temp
    $game_temp.player_new_map_id = 0 if $game_temp.respond_to?(:player_new_map_id=)
    $game_temp.player_new_x = 0 if $game_temp.respond_to?(:player_new_x=)
    $game_temp.player_new_y = 0 if $game_temp.respond_to?(:player_new_y=)
    $game_temp.player_new_direction = 0 if $game_temp.respond_to?(:player_new_direction=)
    log("[anil] cleared pending transfer target after #{reason}") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] pending transfer target clear failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_recover_transition_visuals!(scene = nil, reason = "transition watchdog", clear_interpreter = false)
    prepare_expansion_scene_visual_state! if respond_to?(:prepare_expansion_scene_visual_state!)
    after_expansion_scene_visual_refresh(scene) if scene && respond_to?(:after_expansion_scene_visual_refresh)
    clear_stuck_screen_effects!(reason, true) if respond_to?(:clear_stuck_screen_effects!)
    if clear_interpreter && respond_to?(:release_player_movement_lock)
      release_player_movement_lock
    else
      anil_clear_post_transfer_runtime_flags!(false)
    end
    $game_player.unlock if defined?($game_player) && $game_player && $game_player.respond_to?(:unlock)
    $game_player.straighten if defined?($game_player) && $game_player && $game_player.respond_to?(:straighten)
    anil_adjust_transition_gate_landing!(nil, ($game_map.map_id rescue nil)) if respond_to?(:anil_adjust_transition_gate_landing!)
    anil_restore_host_player_visuals!(reason, scene) if respond_to?(:anil_restore_host_player_visuals!)
    log("[anil] recovered black transition visuals after #{reason} on map #{($game_map.map_id rescue nil)}") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] transition visual recovery failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_transition_watchdog_tick!(scene = nil)
    info = @anil_recent_transfer
    current = integer($game_map.map_id, 0) if defined?($game_map) && $game_map
    return false if current.nil? || current <= 0
    pending_target = 0
    if defined?($game_temp) && $game_temp &&
       $game_temp.respond_to?(:player_transferring) && $game_temp.player_transferring
      pending_target = integer(($game_temp.player_new_map_id if $game_temp.respond_to?(:player_new_map_id)), 0)
    end
    watchdog_map = pending_target > 0 ? pending_target : current
    if !info.is_a?(Hash)
      local_watchdog = anil_local_map_for_runtime(watchdog_map)
      dark_now = anil_transition_visuals_dark?(scene)
      gate_boot_needed = integer(local_watchdog, 0) == 33 &&
                         @anil_transition_boot_recovered_map_id != watchdog_map
      if anil_map_context?(watchdog_map) &&
         (gate_boot_needed || pending_target > 0 || dark_now)
        @anil_recent_transfer = {
          :previous_map_id => current,
          :current_map_id  => current,
          :target_map_id   => watchdog_map,
          :local_map_id    => local_watchdog,
          :frames          => 0,
          :busy_frames     => 0,
          :recovered       => false
        }
        @anil_transition_boot_recovered_map_id = watchdog_map if gate_boot_needed
        info = @anil_recent_transfer
      else
        return false
      end
    end
    info_current = integer(info[:current_map_id], 0)
    info_target = integer(info[:target_map_id] || info[:current_map_id], 0)
    return @anil_recent_transfer = nil if current != info_current && current != info_target && pending_target != info_target
    info[:current_map_id] = current if current == info_target
    return @anil_recent_transfer = nil if !anil_map_context?(current) && !anil_map_context?(info_target)
    busy_flags = {}
    if defined?($game_temp) && $game_temp
      busy_flags[:in_battle] = $game_temp.in_battle if $game_temp.respond_to?(:in_battle)
      busy_flags[:player_transferring] = $game_temp.player_transferring if $game_temp.respond_to?(:player_transferring)
      busy_flags[:transition_processing] = $game_temp.transition_processing if $game_temp.respond_to?(:transition_processing)
      busy_flags[:message_window_showing] = $game_temp.message_window_showing if $game_temp.respond_to?(:message_window_showing)
    end
    info[:frames] = integer(info[:frames], 0) + 1
    blocking_transfer = busy_flags[:player_transferring] || busy_flags[:transition_processing]
    info[:busy_frames] = blocking_transfer ? integer(info[:busy_frames], 0) + 1 : 0
    return false if busy_flags[:in_battle] && info[:frames] < 180
    local_map = integer(info[:local_map_id], 0)
    dark = anil_transition_visuals_dark?(scene)
    should_force_gate = local_map == 33 && info[:frames] >= 45 &&
                        (!busy_flags[:message_window_showing] || dark || blocking_transfer)
    should_clear_dark = info[:frames] >= 60 && dark
    should_clear_busy = blocking_transfer && integer(info[:busy_frames], 0) >= 45
    if !info[:recovered] && (should_force_gate || should_clear_dark || should_clear_busy)
      info[:recovered] = true
      reason = "transfer #{info[:previous_map_id]} -> #{info[:target_map_id] || info[:current_map_id]}"
      reason = "#{reason} busy=#{busy_flags.select { |_key, value| value }.keys.join(',')}"
      return anil_recover_transition_visuals!(scene, reason, should_clear_busy)
    end
    @anil_recent_transfer = nil if info[:frames] > 240
    return false
  rescue => e
    log("[anil] transition watchdog failed: #{e.class}: #{e.message}") if respond_to?(:log)
    @anil_recent_transfer = nil
    return false
  end

  def anil_map_interpreter
    return pbMapInterpreter if defined?(pbMapInterpreter) && pbMapInterpreter
    return $game_system.map_interpreter if defined?($game_system) && $game_system && $game_system.respond_to?(:map_interpreter)
    return nil
  rescue
    return nil
  end

  def anil_transfer_tail_interpreter?(interpreter = nil, previous_map_id = nil, current_map_id = nil)
    interpreter ||= anil_map_interpreter
    return false if !interpreter || !anil_interpreter_running?(interpreter)
    current = integer(current_map_id || ($game_map.map_id rescue 0), 0)
    previous = integer(previous_map_id, 0)
    interpreter_map = interpreter_context_map_id(interpreter) if respond_to?(:interpreter_context_map_id)
    interpreter_map = integer(interpreter_map, 0)
    return false if current <= 0 || interpreter_map <= 0 || interpreter_map == current
    return false if previous > 0 && interpreter_map != previous
    current_local = anil_local_map_for_runtime(current)
    previous_local = anil_local_map_for_runtime(interpreter_map)
    return false if integer(current_local, 0) != 33 && integer(previous_local, 0) != 33
    list = interpreter.instance_variable_get(:@list) rescue nil
    index = integer((interpreter.instance_variable_get(:@index) rescue 0), 0)
    return false if !list.respond_to?(:[])
    transfer_seen = false
    0.upto([index, list.length - 1].min) do |i|
      command = list[i]
      next if !command
      code = command.respond_to?(:code) ? command.code : command.instance_variable_get(:@code)
      transfer_seen = true if integer(code, 0) == 201
    end
    return false if !transfer_seen
    remaining = []
    index.upto(list.length - 1) do |i|
      command = list[i]
      next if !command
      code = command.respond_to?(:code) ? command.code : command.instance_variable_get(:@code)
      remaining << integer(code, 0)
    end
    return remaining.all? { |code| [0, 106, 223, 250].include?(code) }
  rescue
    return false
  end

  def anil_finish_transfer_tail_interpreter!(previous_map_id = nil, current_map_id = nil, reason = "transfer tail")
    interpreter = anil_map_interpreter
    return false if !anil_transfer_tail_interpreter?(interpreter, previous_map_id, current_map_id)
    clear_interpreter_state!(interpreter, "anil #{reason} #{previous_map_id} -> #{current_map_id}") if respond_to?(:clear_interpreter_state!)
    if defined?(SWITCH_LOCK_PLAYER_MOVEMENT) && defined?($game_switches) && $game_switches
      $game_switches[SWITCH_LOCK_PLAYER_MOVEMENT] = false
    end
    $game_system.menu_disabled = false if defined?($game_system) && $game_system && $game_system.respond_to?(:menu_disabled=)
    anil_clear_post_transfer_runtime_flags!(true)
    if defined?($game_player) && $game_player
      $game_player.unlock if $game_player.respond_to?(:unlock)
      $game_player.cancelMoveRoute if $game_player.respond_to?(:cancelMoveRoute)
      $game_player.straighten if $game_player.respond_to?(:straighten)
    end
    log("[anil] finished transfer-tail interpreter after #{reason} #{previous_map_id} -> #{current_map_id}") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] transfer-tail interpreter finish failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_transition_gate_map?(map_id = nil)
    return integer(anil_local_map_for_runtime(map_id || ($game_map.map_id rescue 0)), 0) == 33
  rescue
    return false
  end

  def anil_transition_gate_event?(event = nil)
    return false if !event
    event_map_id = event.respond_to?(:map_id) ? event.map_id : (event.instance_variable_get(:@map_id) rescue nil)
    return false if !anil_transition_gate_map?(event_map_id)
    name = event.respond_to?(:name) ? event.name.to_s : (event.instance_variable_get(:@event).name.to_s rescue "")
    return name =~ /FlechaSalida/i
  rescue
    return false
  end

  def anil_transition_gate_top_event?(event = nil)
    return false if !anil_transition_gate_event?(event)
    y = integer((event.y if event.respond_to?(:y)), integer((event.instance_variable_get(:@y) rescue 0), 0))
    return y >= 3 && y <= 5
  rescue
    return false
  end

  def anil_transition_gate_event_under_player?(event = nil)
    return false if !event || !defined?($game_player) || !$game_player
    if event.respond_to?(:at_coordinate?)
      return event.at_coordinate?($game_player.x, $game_player.y)
    end
    x = integer((event.x if event.respond_to?(:x)), integer((event.instance_variable_get(:@x) rescue 0), 0))
    y = integer((event.y if event.respond_to?(:y)), integer((event.instance_variable_get(:@y) rescue 0), 0))
    return x == integer($game_player.x, 0) && y == integer($game_player.y, 0)
  rescue
    return false
  end

  def anil_apply_event_temp_switch!(event = nil, switch_name = "A", value = true, refresh_event = true)
    return false if !event
    map_id = event.respond_to?(:map_id) ? event.map_id : (event.instance_variable_get(:@map_id) rescue nil)
    event_id = event.respond_to?(:id) ? event.id : (event.instance_variable_get(:@id) rescue nil)
    temp = event.instance_variable_get(:@tempSwitches) rescue nil
    if temp.respond_to?(:[]=)
      temp[switch_name.to_s] = value ? true : false
    end
    anil_set_temp_switch(map_id, event_id, switch_name, value) if respond_to?(:anil_set_temp_switch)
    event.refresh if refresh_event && event.respond_to?(:refresh)
    return true
  rescue => e
    log("[anil] temp switch apply failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_transition_gate_off_player_autorun?(event = nil)
    return false if !anil_transition_gate_top_event?(event)
    return false if anil_transition_gate_event_under_player?(event)
    trigger = event.respond_to?(:trigger) ? event.trigger : (event.instance_variable_get(:@trigger) rescue nil)
    return integer(trigger, 0) == 3
  rescue
    return false
  end

  def anil_transition_gate_touch_exit?(event = nil)
    return false if !anil_transition_gate_event?(event)
    trigger = event.respond_to?(:trigger) ? event.trigger : (event.instance_variable_get(:@trigger) rescue nil)
    return false if ![1, 2].include?(integer(trigger, 0))
    character_name = event.respond_to?(:character_name) ? event.character_name.to_s : (event.instance_variable_get(:@character_name).to_s rescue "")
    return !character_name.empty?
  rescue
    return false
  end

  def anil_transition_gate_off_player_autorun_pending?
    return false if !anil_transition_gate_map?
    return false if !defined?($game_map) || !$game_map || !$game_map.respond_to?(:events)
    $game_map.events.values.any? do |event|
      starting = event.respond_to?(:starting) && event.starting
      starting && anil_transition_gate_off_player_autorun?(event)
    end
  rescue
    return false
  end

  def anil_clear_transition_gate_off_player_autoruns!(reason = "transition hall", refresh_map = true)
    return false if !anil_transition_gate_map?
    return false if !defined?($game_map) || !$game_map || !$game_map.respond_to?(:events)
    cleared_ids = []
    $game_map.events.values.each do |event|
      next if !anil_transition_gate_off_player_autorun?(event)
      cleared_ids << (event.id rescue nil)
      anil_apply_event_temp_switch!(event, "A", true, false)
      event.clear_starting if event.respond_to?(:clear_starting)
      event.cancelMoveRoute if event.respond_to?(:cancelMoveRoute)
    end
    cleared_ids.compact!
    return false if cleared_ids.empty?
    if refresh_map
      $game_map.need_refresh = true if $game_map.respond_to?(:need_refresh=)
      $game_map.refresh if $game_map.respond_to?(:refresh)
    end
    log("[anil] cleared off-player transition hall autoruns after #{reason}: #{cleared_ids.join(',')}") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] off-player transition hall autorun clear failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_adjust_transition_gate_landing!(previous_map_id = nil, current_map_id = nil)
    current = integer(current_map_id || ($game_map.map_id rescue 0), 0)
    return false if !anil_transition_gate_map?(current)
    return false if !defined?($game_player) || !$game_player
    x = integer($game_player.x, 0)
    y = integer($game_player.y, 0)
    destination = nil
    destination = [8, 14] if [7, 8, 9].include?(x) && y >= 15 && y <= 17
    destination = [31, 14] if [30, 31, 32].include?(x) && y >= 15 && y <= 17
    return false if !destination
    $game_player.moveto(destination[0], destination[1]) if $game_player.respond_to?(:moveto)
    $game_player.turn_down if $game_player.respond_to?(:turn_down)
    $game_player.unlock if $game_player.respond_to?(:unlock)
    $game_player.cancelMoveRoute if $game_player.respond_to?(:cancelMoveRoute)
    $game_player.instance_variable_set(:@starting, false) if $game_player.instance_variable_defined?(:@starting)
    $game_player.instance_variable_set(:@wait_count, 0) if $game_player.instance_variable_defined?(:@wait_count)
    $game_player.instance_variable_set(:@jump_count, 0) if $game_player.instance_variable_defined?(:@jump_count)
    $game_player.instance_variable_set(:@jump_distance_left, 0) if $game_player.instance_variable_defined?(:@jump_distance_left)
    $game_player.straighten if $game_player.respond_to?(:straighten)
    if defined?(SWITCH_LOCK_PLAYER_MOVEMENT) && defined?($game_switches) && $game_switches
      $game_switches[SWITCH_LOCK_PLAYER_MOVEMENT] = false
    end
    $game_system.menu_disabled = false if defined?($game_system) && $game_system && $game_system.respond_to?(:menu_disabled=)
    anil_clear_post_transfer_runtime_flags!(true)
    @anil_transition_gate_rescue_frames = 0
    log("[anil] adjusted transition gate landing #{x},#{y} -> #{destination[0]},#{destination[1]} after #{previous_map_id} -> #{current}") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] transition gate landing adjust failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_complete_transition_gate_arrival!(scene = nil, previous_map_id = nil, current_map_id = nil, reason = "transition gate", break_update_loop = false)
    current = integer(current_map_id || ($game_map.map_id rescue 0), 0)
    return false if !anil_transition_gate_map?(current)
    return false if !defined?($game_player) || !$game_player
    flags_before = anil_transition_gate_lock_flags if respond_to?(:anil_transition_gate_lock_flags)
    interpreter = anil_map_interpreter
    if interpreter && anil_interpreter_running?(interpreter)
      interpreter_map = interpreter_context_map_id(interpreter) if respond_to?(:interpreter_context_map_id)
      interpreter_event_id = interpreter_context_event_id(interpreter) if respond_to?(:interpreter_context_event_id)
      event = nil
      event = $game_map.events[integer(interpreter_event_id, 0)] if defined?($game_map) && $game_map &&
                                                                    $game_map.respond_to?(:events)
      should_clear = integer(interpreter_map, 0) != current ||
                     integer(interpreter_event_id, 0) <= 0 ||
                     anil_transition_gate_event?(event)
      if should_clear && respond_to?(:clear_interpreter_state!)
        clear_interpreter_state!(interpreter, "anil #{reason} gate arrival")
      end
    end
    if anil_transition_gate_arrival_zone? && respond_to?(:anil_clear_transition_gate_event_starts!)
      anil_clear_transition_gate_event_starts!(false)
    end
    anil_clear_transition_gate_off_player_autoruns!(reason, true) if respond_to?(:anil_clear_transition_gate_off_player_autoruns!)
    if defined?(SWITCH_LOCK_PLAYER_MOVEMENT) && defined?($game_switches) && $game_switches
      $game_switches[SWITCH_LOCK_PLAYER_MOVEMENT] = false
    end
    $game_system.menu_disabled = false if defined?($game_system) && $game_system && $game_system.respond_to?(:menu_disabled=)
    anil_clear_post_transfer_runtime_flags!(true)
    if defined?($PokemonTemp) && $PokemonTemp
      $PokemonTemp.encounterTriggered = false if $PokemonTemp.respond_to?(:encounterTriggered=)
      $PokemonTemp.waitingTrainer = nil if $PokemonTemp.respond_to?(:waitingTrainer=)
    end
    if defined?($game_player) && $game_player
      $game_player.unlock if $game_player.respond_to?(:unlock)
      $game_player.cancelMoveRoute if $game_player.respond_to?(:cancelMoveRoute)
      $game_player.transparent = false if $game_player.respond_to?(:transparent=)
      $game_player.through = false if $game_player.respond_to?(:through=)
      $game_player.instance_variable_set(:@starting, false) if $game_player.instance_variable_defined?(:@starting)
      $game_player.instance_variable_set(:@wait_count, 0) if $game_player.instance_variable_defined?(:@wait_count)
      $game_player.instance_variable_set(:@move_route_waiting, false) if $game_player.instance_variable_defined?(:@move_route_waiting)
      $game_player.instance_variable_set(:@jump_count, 0) if $game_player.instance_variable_defined?(:@jump_count)
      $game_player.instance_variable_set(:@jump_distance_left, 0) if $game_player.instance_variable_defined?(:@jump_distance_left)
      $game_player.instance_variable_set(:@moved_this_frame, false) if $game_player.instance_variable_defined?(:@moved_this_frame)
      $game_player.instance_variable_set(:@stopped_this_frame, true) if $game_player.instance_variable_defined?(:@stopped_this_frame)
      $game_player.straighten if $game_player.respond_to?(:straighten)
    end
    anil_adjust_transition_gate_landing!(previous_map_id, current)
    clear_stuck_screen_effects!(reason, true) if respond_to?(:clear_stuck_screen_effects!)
    anil_restore_host_player_visuals!(reason, scene) if respond_to?(:anil_restore_host_player_visuals!)
    if break_update_loop && defined?($game_temp) && $game_temp
      $game_temp.player_transferring = false if $game_temp.respond_to?(:player_transferring=)
      $game_temp.transition_processing = false if $game_temp.respond_to?(:transition_processing=)
      $game_temp.transition_name = "" if $game_temp.respond_to?(:transition_name=)
      anil_clear_pending_transfer_target!(reason) if respond_to?(:anil_clear_pending_transfer_target!)
    end
    @anil_recent_transfer = nil
    @anil_transition_gate_arrival_watch = {
      :map_id => current,
      :frames => 45,
      :x => $game_player.x,
      :y => $game_player.y
    }
    Graphics.frame_reset if defined?(Graphics) && Graphics.respond_to?(:frame_reset)
    Input.update rescue nil
    if respond_to?(:log)
      before_text = flags_before.is_a?(Hash) ? flags_before.select { |_key, value| value }.keys.join(",") : ""
      after_flags = anil_transition_gate_lock_flags if respond_to?(:anil_transition_gate_lock_flags)
      after_text = after_flags.is_a?(Hash) ? after_flags.select { |_key, value| value }.keys.join(",") : ""
      log("[anil] completed transition gate arrival after #{reason} on map #{current} pos=#{$game_player.x},#{$game_player.y} before=#{before_text} after=#{after_text} break_update=#{break_update_loop ? 1 : 0}")
    end
    return true
  rescue => e
    log("[anil] transition gate arrival completion failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_transition_gate_arrival_zone?
    current = integer(($game_map.map_id if defined?($game_map) && $game_map), 0)
    return false if !anil_transition_gate_map?(current)
    return false if !defined?($game_player) || !$game_player
    x = integer($game_player.x, 0)
    y = integer($game_player.y, 0)
    return true if [7, 8, 9].include?(x) && y >= 12 && y <= 16
    return true if [30, 31, 32].include?(x) && y >= 12 && y <= 16
    return false
  rescue
    return false
  end

  def anil_transition_gate_arrival_unlock_needed?
    return false if !anil_transition_gate_arrival_zone?
    return false if defined?($game_temp) && $game_temp &&
                    $game_temp.respond_to?(:in_battle) && $game_temp.in_battle
    interpreter = anil_map_interpreter
    return false if anil_transition_gate_touch_exit?(anil_transition_gate_event_for_interpreter(interpreter))
    flags = anil_transition_gate_lock_flags
    return true if flags[:player_transferring] || flags[:transition_processing]
    return true if flags[:message_window_showing] || flags[:in_menu]
    return true if flags[:moving_furniture] || flags[:miniupdate]
    return true if flags[:waiting_trainer] || flags[:chat_input]
    return true if flags[:movement_switch] || flags[:menu_disabled]
    return true if flags[:player_locked] || flags[:forced_route]
    return true if anil_transition_gate_arrival_watch_active? && flags[:interpreter_running]
    return true if anil_interpreter_stale_after_visible_transfer?(interpreter)
    if anil_interpreter_running?(interpreter)
      interpreter_map = interpreter_context_map_id(interpreter) if respond_to?(:interpreter_context_map_id)
      return true if integer(interpreter_map, 0) != integer(($game_map.map_id rescue 0), 0)
    end
    return false
  rescue
    return false
  end

  def anil_transition_gate_arrival_watch_active?
    watch = @anil_transition_gate_arrival_watch
    return false if !watch.is_a?(Hash)
    return false if integer(watch[:frames], 0) <= 0
    return false if !anil_transition_gate_arrival_zone?
    return integer(watch[:map_id], 0) == integer(($game_map.map_id rescue 0), 0)
  rescue
    return false
  end

  def anil_transition_gate_suppress_starting_events?
    return false if !anil_transition_gate_map?
    return false if defined?($game_temp) && $game_temp &&
                    $game_temp.respond_to?(:in_battle) && $game_temp.in_battle
    return true if anil_transition_gate_off_player_autorun_pending?
    return anil_transition_gate_arrival_watch_active? && anil_transition_gate_arrival_zone?
  rescue
    return false
  end

  def anil_transition_gate_idle_unlock!(scene = nil, reason = "transition gate idle unlock", clear_interpreter = false)
    return false if !anil_transition_gate_arrival_zone?
    return false if defined?($game_temp) && $game_temp &&
                    $game_temp.respond_to?(:in_battle) && $game_temp.in_battle
    current = integer(($game_map.map_id rescue 0), 0)
    return false if !anil_transition_gate_map?(current)
    flags_before = anil_transition_gate_lock_flags
    interpreter = anil_map_interpreter
    return false if anil_transition_gate_touch_exit?(anil_transition_gate_event_for_interpreter(interpreter))
    interpreter_running = anil_interpreter_running?(interpreter)
    blockers = anil_transition_gate_blocking_flags(flags_before, interpreter, true)
    return false if blockers.empty?
    cleared_interpreter = false
    if interpreter_running && clear_interpreter && anil_transition_gate_clearable_interpreter?(interpreter, true) &&
       respond_to?(:clear_interpreter_state!)
      clear_interpreter_state!(interpreter, "anil #{reason}")
      cleared_interpreter = true
    end
    cleared_events = anil_clear_transition_gate_event_starts!(false)
    if defined?(SWITCH_LOCK_PLAYER_MOVEMENT) && defined?($game_switches) && $game_switches
      $game_switches[SWITCH_LOCK_PLAYER_MOVEMENT] = false
    end
    $game_system.menu_disabled = false if defined?($game_system) && $game_system && $game_system.respond_to?(:menu_disabled=)
    anil_clear_post_transfer_runtime_flags!(true)
    if defined?($game_player) && $game_player
      $game_player.unlock if $game_player.respond_to?(:unlock)
      $game_player.cancelMoveRoute if flags_before[:forced_route] && $game_player.respond_to?(:cancelMoveRoute)
      if !$game_player.respond_to?(:moving?) || !$game_player.moving?
        $game_player.instance_variable_set(:@starting, false) if $game_player.instance_variable_defined?(:@starting)
        $game_player.instance_variable_set(:@wait_count, 0) if $game_player.instance_variable_defined?(:@wait_count)
        $game_player.instance_variable_set(:@move_route_waiting, false) if $game_player.instance_variable_defined?(:@move_route_waiting)
        $game_player.instance_variable_set(:@jump_count, 0) if $game_player.instance_variable_defined?(:@jump_count)
        $game_player.instance_variable_set(:@jump_distance_left, 0) if $game_player.instance_variable_defined?(:@jump_distance_left)
      end
      $game_player.transparent = false if $game_player.respond_to?(:transparent=)
      $game_player.through = false if $game_player.respond_to?(:through=)
      $game_player.straighten if $game_player.respond_to?(:straighten) &&
                                  (!$game_player.respond_to?(:moving?) || !$game_player.moving?)
    end
    changed_flags = blockers
    changed = cleared_interpreter || cleared_events || !changed_flags.empty?
    if changed && respond_to?(:log)
      @anil_transition_gate_idle_unlock_logs ||= {}
      event_id = interpreter_context_event_id(interpreter) if respond_to?(:interpreter_context_event_id)
      key = "#{current}:#{reason}:#{changed_flags.keys.join(',')}:#{event_id}"
      if !@anil_transition_gate_idle_unlock_logs[key]
        @anil_transition_gate_idle_unlock_logs[key] = true
        position = defined?($game_player) && $game_player ? "#{$game_player.x},#{$game_player.y}" : "nil"
        log("[anil] idle-unlocked transition gate after #{reason} on map #{current} pos=#{position} flags=#{changed_flags.keys.join(',')} interpreter=#{event_id || 'nil'} events=#{cleared_events ? 1 : 0}")
      end
    end
    return changed
  rescue => e
    log("[anil] transition gate idle unlock failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_transition_gate_pre_update_unlock!(scene = nil)
    watch = @anil_transition_gate_arrival_watch
    watched = watch.is_a?(Hash) &&
              integer(watch[:frames], 0) > 0 &&
              integer(watch[:map_id], 0) == integer(($game_map.map_id rescue 0), 0)
    @anil_transition_gate_arrival_watch = nil if watch.is_a?(Hash) && integer(watch[:frames], 0) <= 0
    if watch.is_a?(Hash)
      watch[:frames] = integer(watch[:frames], 0) - 1
      @anil_transition_gate_arrival_watch = watch
    end
    if watched && !anil_transition_gate_arrival_zone?
      @anil_transition_gate_arrival_watch = nil
      @anil_transition_gate_rescue_frames = 0
      return false
    end
    if watched
      anil_transition_gate_idle_unlock!(scene, "arrival watch", true)
      return true
    end
    return false if !anil_transition_gate_arrival_unlock_needed?
    anil_transition_gate_idle_unlock!(scene, "pre-update gate unlock", true)
    return true
  rescue => e
    log("[anil] transition gate pre-update unlock failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_transition_gate_player_zone?
    current = integer(($game_map.map_id if defined?($game_map) && $game_map), 0)
    return false if !anil_transition_gate_map?(current)
    return false if !defined?($game_player) || !$game_player
    x = integer($game_player.x, 0)
    y = integer($game_player.y, 0)
    return true if [7, 8, 9].include?(x) && y >= 12 && y <= 18
    return true if [30, 31, 32].include?(x) && y >= 12 && y <= 18
    return true if [7, 8, 9].include?(x) && y >= 3 && y <= 5
    return true if [30, 31, 32].include?(x) && y >= 3 && y <= 5
    return false
  rescue
    return false
  end

  def anil_transition_gate_lock_flags(interpreter = nil)
    flags = {}
    if defined?($game_temp) && $game_temp
      flags[:in_battle] = $game_temp.in_battle if $game_temp.respond_to?(:in_battle)
      flags[:player_transferring] = $game_temp.player_transferring if $game_temp.respond_to?(:player_transferring)
      flags[:transition_processing] = $game_temp.transition_processing if $game_temp.respond_to?(:transition_processing)
      flags[:message_window_showing] = $game_temp.message_window_showing if $game_temp.respond_to?(:message_window_showing)
      flags[:in_menu] = $game_temp.in_menu if $game_temp.respond_to?(:in_menu)
      flags[:moving_furniture] = $game_temp.moving_furniture if $game_temp.respond_to?(:moving_furniture)
    end
    flags[:movement_switch] = defined?(SWITCH_LOCK_PLAYER_MOVEMENT) &&
                              defined?($game_switches) && $game_switches &&
                              $game_switches[SWITCH_LOCK_PLAYER_MOVEMENT]
    flags[:menu_disabled] = defined?($game_system) && $game_system &&
                            $game_system.respond_to?(:menu_disabled) &&
                            $game_system.menu_disabled
    flags[:player_locked] = defined?($game_player) && $game_player &&
                            $game_player.respond_to?(:lock?) &&
                            $game_player.lock?
    flags[:forced_route] = defined?($game_player) && $game_player &&
                           $game_player.respond_to?(:move_route_forcing) &&
                           $game_player.move_route_forcing
    flags[:moving] = defined?($game_player) && $game_player &&
                     $game_player.respond_to?(:moving?) &&
                     $game_player.moving?
    flags[:jumping] = defined?($game_player) && $game_player &&
                      $game_player.respond_to?(:jumping?) &&
                      $game_player.jumping?
    flags[:miniupdate] = defined?($PokemonTemp) && $PokemonTemp &&
                         $PokemonTemp.respond_to?(:miniupdate) &&
                         $PokemonTemp.miniupdate
    flags[:waiting_trainer] = defined?($PokemonTemp) && $PokemonTemp &&
                              $PokemonTemp.respond_to?(:waitingTrainer) &&
                              $PokemonTemp.waitingTrainer
    flags[:chat_input] = defined?($chat_window) && $chat_window &&
                         $chat_window.respond_to?(:input_mode) &&
                         $chat_window.input_mode
    interpreter ||= anil_map_interpreter
    flags[:interpreter_running] = anil_interpreter_running?(interpreter)
    flags
  rescue
    {}
  end

  def anil_transition_gate_event_for_interpreter(interpreter = nil)
    interpreter ||= anil_map_interpreter
    return nil if !interpreter
    event_id = interpreter_context_event_id(interpreter) if respond_to?(:interpreter_context_event_id)
    event_id = integer(event_id, 0)
    return nil if event_id <= 0
    return nil if !defined?($game_map) || !$game_map || !$game_map.respond_to?(:events)
    return $game_map.events[event_id]
  rescue
    return nil
  end

  def anil_transition_gate_clearable_interpreter?(interpreter = nil, arrival_only = false)
    interpreter ||= anil_map_interpreter
    return false if !anil_interpreter_running?(interpreter)
    return true if anil_interpreter_stale_after_visible_transfer?(interpreter)
    return true if anil_interpreter_waiting_without_window?(interpreter)
    event = anil_transition_gate_event_for_interpreter(interpreter)
    return true if anil_transition_gate_event?(event) &&
                   !anil_transition_gate_touch_exit?(event)
    return true if arrival_only &&
                   anil_transition_gate_arrival_zone? &&
                   integer((interpreter_context_event_id(interpreter) if respond_to?(:interpreter_context_event_id)), 0) <= 0
    return false
  rescue
    return false
  end

  def anil_transition_gate_blocking_flags(flags = nil, interpreter = nil, arrival_only = false)
    flags ||= anil_transition_gate_lock_flags(interpreter)
    interpreter ||= anil_map_interpreter
    blockers = {}
    [
      :player_transferring,
      :transition_processing,
      :moving_furniture,
      :miniupdate,
      :waiting_trainer,
      :chat_input,
      :movement_switch,
      :menu_disabled,
      :player_locked,
      :forced_route
    ].each do |key|
      blockers[key] = true if flags[key]
    end
    if anil_transition_gate_clearable_interpreter?(interpreter, arrival_only)
      blockers[:interpreter_running] = true
    end
    return blockers
  rescue
    return {}
  end

  def anil_clear_transition_gate_event_starts!(all_events = false)
    return false if !anil_transition_gate_map?
    return false if !defined?($game_map) || !$game_map || !$game_map.respond_to?(:events)
    cleared = false
    $game_map.events.values.each do |event|
      next if !all_events && !anil_transition_gate_event?(event)
      was_starting = event.respond_to?(:starting) ? event.starting : false
      if event.respond_to?(:clear_starting)
        event.clear_starting
        cleared = true if was_starting || !event.respond_to?(:starting)
      end
      event.cancelMoveRoute if event.respond_to?(:cancelMoveRoute) &&
                                (was_starting || anil_transition_gate_event?(event))
    end
    return cleared
  rescue
    return false
  end

  def anil_interpreter_running?(interpreter = nil)
    interpreter ||= anil_map_interpreter
    return interpreter && interpreter.respond_to?(:running?) && interpreter.running?
  rescue
    return false
  end

  def anil_interpreter_waiting_without_window?(interpreter = nil)
    interpreter ||= anil_map_interpreter
    return false if !interpreter || !anil_interpreter_running?(interpreter)
    waiting = interpreter.instance_variable_get(:@message_waiting) rescue false
    return false if !waiting
    return false if defined?($game_temp) && $game_temp &&
                    $game_temp.respond_to?(:message_window_showing) &&
                    $game_temp.message_window_showing
    return true
  rescue
    return false
  end

  def anil_interpreter_stale_after_visible_transfer?(interpreter = nil)
    interpreter ||= anil_map_interpreter
    return false if !interpreter || !anil_interpreter_running?(interpreter)
    current = integer(($game_map.map_id if defined?($game_map) && $game_map), 0)
    return true if respond_to?(:interpreter_stale_for_current_map?) &&
                   interpreter_stale_for_current_map?(interpreter, current)
    interpreter_map = interpreter_context_map_id(interpreter) if respond_to?(:interpreter_context_map_id)
    interpreter_event = interpreter_context_event_id(interpreter) if respond_to?(:interpreter_context_event_id)
    return true if current > 0 &&
                   integer(interpreter_map, 0) > 0 &&
                   integer(interpreter_map, 0) != current &&
                   integer(interpreter_event, 0) <= 0 &&
                   !anil_interpreter_waiting_without_window?(interpreter)
    return anil_interpreter_waiting_without_window?(interpreter)
  rescue
    return false
  end

  def anil_post_transfer_locked_state?(interpreter = nil)
    return false if !anil_event_context_active?
    transition_gate_zone = anil_transition_gate_player_zone?
    if defined?($game_temp) && $game_temp
      return false if $game_temp.respond_to?(:in_battle) && $game_temp.in_battle
      return false if !transition_gate_zone &&
                      $game_temp.respond_to?(:player_transferring) &&
                      $game_temp.player_transferring
      return false if !transition_gate_zone &&
                      $game_temp.respond_to?(:transition_processing) &&
                      $game_temp.transition_processing
      if !transition_gate_zone
        return false if $game_temp.respond_to?(:message_window_showing) && $game_temp.message_window_showing
        return false if $game_temp.respond_to?(:in_menu) && $game_temp.in_menu
      end
    end
    interpreter ||= anil_map_interpreter
    gate_flags = anil_transition_gate_lock_flags(interpreter)
    interpreter_running = anil_interpreter_running?(interpreter)
    return false if anil_transition_gate_touch_exit?(anil_transition_gate_event_for_interpreter(interpreter))
    stale_interpreter = anil_interpreter_stale_after_visible_transfer?(interpreter)
    movement_switch = defined?(SWITCH_LOCK_PLAYER_MOVEMENT) &&
                      defined?($game_switches) && $game_switches &&
                      $game_switches[SWITCH_LOCK_PLAYER_MOVEMENT]
    menu_disabled = defined?($game_system) && $game_system &&
                    $game_system.respond_to?(:menu_disabled) &&
                    $game_system.menu_disabled
    player_locked = defined?($game_player) && $game_player &&
                    $game_player.respond_to?(:lock?) &&
                    $game_player.lock?
    forced_route = defined?($game_player) && $game_player &&
                   $game_player.respond_to?(:move_route_forcing) &&
                   $game_player.move_route_forcing
    return true if stale_interpreter
    recent = @anil_recent_transfer
    local_map = integer((recent[:local_map_id] if recent.is_a?(Hash)), 0)
    return true if interpreter_running && local_map == 33
    if transition_gate_zone
      return true if gate_flags[:player_transferring] || gate_flags[:transition_processing]
      return true if gate_flags[:moving_furniture] || gate_flags[:miniupdate]
      return true if gate_flags[:waiting_trainer] || gate_flags[:chat_input]
      return true if anil_transition_gate_clearable_interpreter?(interpreter, false)
    end
    return true if !interpreter_running && (movement_switch || menu_disabled || player_locked || forced_route)
    return false
  rescue
    return false
  end

  def anil_recover_post_transfer_lock!(scene = nil, reason = "post-transfer lock")
    interpreter = anil_map_interpreter
    if anil_interpreter_stale_after_visible_transfer?(interpreter)
      clear_interpreter_state!(interpreter, "anil #{reason}") if respond_to?(:clear_interpreter_state!)
    elsif anil_transition_gate_player_zone? && anil_transition_gate_clearable_interpreter?(interpreter, false)
      clear_interpreter_state!(interpreter, "anil #{reason} transition gate interpreter") if respond_to?(:clear_interpreter_state!)
    end
    if defined?(SWITCH_LOCK_PLAYER_MOVEMENT) && defined?($game_switches) && $game_switches
      $game_switches[SWITCH_LOCK_PLAYER_MOVEMENT] = false
    end
    $game_system.menu_disabled = false if defined?($game_system) && $game_system && $game_system.respond_to?(:menu_disabled=)
    flags_before = anil_transition_gate_lock_flags(interpreter) if respond_to?(:anil_transition_gate_lock_flags)
    anil_clear_post_transfer_runtime_flags!(true)
    if defined?($game_player) && $game_player
      $game_player.unlock if $game_player.respond_to?(:unlock)
      $game_player.cancelMoveRoute if $game_player.respond_to?(:cancelMoveRoute)
      $game_player.instance_variable_set(:@starting, false) if $game_player.instance_variable_defined?(:@starting)
      $game_player.instance_variable_set(:@wait_count, 0) if $game_player.instance_variable_defined?(:@wait_count)
      $game_player.instance_variable_set(:@jump_count, 0) if $game_player.instance_variable_defined?(:@jump_count)
      $game_player.instance_variable_set(:@jump_distance_left, 0) if $game_player.instance_variable_defined?(:@jump_distance_left)
      $game_player.moveto($game_player.x, $game_player.y) if $game_player.respond_to?(:moveto)
      $game_player.straighten if $game_player.respond_to?(:straighten)
    end
    anil_clear_transition_gate_event_starts!(false) if respond_to?(:anil_clear_transition_gate_event_starts!)
    anil_adjust_transition_gate_landing!(nil, ($game_map.map_id rescue nil)) if respond_to?(:anil_adjust_transition_gate_landing!)
    clear_stuck_screen_effects!(reason, true) if respond_to?(:clear_stuck_screen_effects!)
    anil_restore_host_player_visuals!(reason, scene) if respond_to?(:anil_restore_host_player_visuals!)
    if respond_to?(:log)
      flag_text = flags_before.is_a?(Hash) ? flags_before.select { |_key, value| value }.keys.join(",") : ""
      log("[anil] recovered visible post-transfer lock after #{reason} on map #{($game_map.map_id rescue nil)} flags=#{flag_text}")
    end
    return true
  rescue => e
    log("[anil] post-transfer lock recovery failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_post_transfer_lock_watchdog_tick!(scene = nil)
    if anil_post_transfer_locked_state?
      @anil_post_transfer_lock_frames = integer(@anil_post_transfer_lock_frames, 0) + 1
    else
      @anil_post_transfer_lock_frames = 0
      return false
    end
    threshold = anil_transition_gate_player_zone? ? 20 : 75
    return false if @anil_post_transfer_lock_frames < threshold
    @anil_post_transfer_lock_frames = 0
    return anil_recover_post_transfer_lock!(scene, "visible idle watchdog")
  rescue => e
    log("[anil] post-transfer lock watchdog failed: #{e.class}: #{e.message}") if respond_to?(:log)
    @anil_post_transfer_lock_frames = 0
    return false
  end

  def anil_transition_hall_pre_interpreter_rescue!(interpreter = nil, reason = "interpreter pre-update")
    current = integer(($game_map.map_id rescue 0), 0)
    return false if !anil_transition_gate_map?(current)
    return false if defined?($game_temp) && $game_temp &&
                    $game_temp.respond_to?(:in_battle) && $game_temp.in_battle
    changed = anil_clear_transition_gate_off_player_autoruns!(reason, true)
    interpreter ||= anil_map_interpreter
    if anil_interpreter_running?(interpreter)
      event = anil_transition_gate_event_for_interpreter(interpreter)
      if anil_transition_gate_off_player_autorun?(event)
        event_id = event.id rescue nil
        anil_apply_event_temp_switch!(event, "A", true, true)
        clear_interpreter_state!(interpreter, "anil #{reason} off-player transition hall autorun") if respond_to?(:clear_interpreter_state!)
        anil_clear_post_transfer_runtime_flags!(false)
        changed = true
        log("[anil] cleared running off-player transition hall autorun event=#{event_id} after #{reason}") if respond_to?(:log)
      end
    end
    if changed && defined?($game_player) && $game_player
      $game_player.unlock if $game_player.respond_to?(:unlock)
      $game_player.cancelMoveRoute if $game_player.respond_to?(:cancelMoveRoute)
      $game_player.straighten if $game_player.respond_to?(:straighten) &&
                                  (!$game_player.respond_to?(:moving?) || !$game_player.moving?)
    end
    return changed
  rescue => e
    log("[anil] transition hall pre-interpreter rescue failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_transition_hall_visible_lock_tick!(scene = nil)
    current = integer(($game_map.map_id rescue 0), 0)
    return false if !anil_transition_gate_map?(current)
    return false if defined?($game_temp) && $game_temp &&
                    $game_temp.respond_to?(:in_battle) && $game_temp.in_battle
    interpreter = anil_map_interpreter
    if anil_transition_gate_touch_exit?(anil_transition_gate_event_for_interpreter(interpreter))
      @anil_transition_hall_visible_lock = nil
      return false
    end
    flags = anil_transition_gate_lock_flags(interpreter)
    blockers = anil_transition_gate_blocking_flags(flags, interpreter, false)
    silent_interpreter = anil_interpreter_running?(interpreter) &&
                         !flags[:message_window_showing] &&
                         !flags[:in_menu] &&
                         !flags[:moving] &&
                         !flags[:jumping]
    stale_message = flags[:message_window_showing] &&
                    !anil_interpreter_running?(interpreter) &&
                    !flags[:moving] &&
                    !flags[:jumping]
    blocked = !blockers.empty? || silent_interpreter || stale_message
    if !blocked
      @anil_transition_hall_visible_lock = nil
      return false
    end
    event_id = integer((interpreter_context_event_id(interpreter) if respond_to?(:interpreter_context_event_id)), 0)
    index = integer((interpreter.instance_variable_get(:@index) if interpreter), 0)
    x = integer(($game_player.x rescue 0), 0)
    y = integer(($game_player.y rescue 0), 0)
    signature = [current, event_id, index, x, y, blockers.keys.sort, silent_interpreter, stale_message]
    state = @anil_transition_hall_visible_lock
    if !state.is_a?(Hash) || state[:signature] != signature
      state = { :signature => signature, :frames => 0, :logged => false }
    end
    state[:frames] = integer(state[:frames], 0) + 1
    @anil_transition_hall_visible_lock = state
    if state[:frames] == 45 && !state[:logged] && respond_to?(:log)
      state[:logged] = true
      flag_text = blockers.keys.join(",")
      flag_text = "silent_interpreter" if flag_text.empty? && silent_interpreter
      flag_text = "stale_message" if flag_text.empty? && stale_message
      log("[anil] transition hall idle state pos=#{x},#{y} event=#{event_id} index=#{index} flags=#{flag_text}")
    end
    threshold = anil_transition_gate_player_zone? ? 60 : 105
    return false if state[:frames] < threshold
    @anil_transition_hall_visible_lock = nil
    if (silent_interpreter || !blockers.empty?) && anil_transition_gate_clearable_interpreter?(interpreter, false) &&
       respond_to?(:clear_interpreter_state!)
      clear_interpreter_state!(interpreter, "anil transition hall visible idle")
    elsif silent_interpreter && event_id > 0 && !flags[:message_window_showing] && respond_to?(:clear_interpreter_state!)
      clear_interpreter_state!(interpreter, "anil transition hall silent interpreter")
    end
    if defined?(SWITCH_LOCK_PLAYER_MOVEMENT) && defined?($game_switches) && $game_switches
      $game_switches[SWITCH_LOCK_PLAYER_MOVEMENT] = false
    end
    $game_system.menu_disabled = false if defined?($game_system) && $game_system && $game_system.respond_to?(:menu_disabled=)
    anil_clear_post_transfer_runtime_flags!(stale_message)
    if defined?($game_player) && $game_player
      $game_player.unlock if $game_player.respond_to?(:unlock)
      $game_player.cancelMoveRoute if flags[:forced_route] && $game_player.respond_to?(:cancelMoveRoute)
      if !$game_player.respond_to?(:moving?) || !$game_player.moving?
        $game_player.instance_variable_set(:@starting, false) if $game_player.instance_variable_defined?(:@starting)
        $game_player.instance_variable_set(:@wait_count, 0) if $game_player.instance_variable_defined?(:@wait_count)
        $game_player.instance_variable_set(:@move_route_waiting, false) if $game_player.instance_variable_defined?(:@move_route_waiting)
      end
      $game_player.straighten if $game_player.respond_to?(:straighten) &&
                                  (!$game_player.respond_to?(:moving?) || !$game_player.moving?)
    end
    log("[anil] recovered transition hall visible idle lock on map #{current} pos=#{x},#{y} event=#{event_id} flags=#{blockers.keys.join(',')} silent=#{silent_interpreter ? 1 : 0} stale_message=#{stale_message ? 1 : 0}") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] transition hall visible lock watchdog failed: #{e.class}: #{e.message}") if respond_to?(:log)
    @anil_transition_hall_visible_lock = nil
    return false
  end

  def anil_transition_gate_hard_watchdog_tick!(scene = nil)
    return false if !anil_transition_gate_player_zone?
    interpreter = anil_map_interpreter
    return false if anil_transition_gate_touch_exit?(anil_transition_gate_event_for_interpreter(interpreter))
    flags = anil_transition_gate_lock_flags(interpreter)
    blockers = anil_transition_gate_blocking_flags(flags, interpreter, true)
    if blockers.empty? && !anil_transition_visuals_dark?(scene)
      @anil_transition_gate_rescue_frames = 0
      return false
    end
    @anil_transition_gate_rescue_frames = integer(@anil_transition_gate_rescue_frames, 0) + 1
    if @anil_transition_gate_rescue_frames == 12 && respond_to?(:log)
      flag_text = blockers.keys.join(",")
      flag_text = "dark" if flag_text.empty?
      position = defined?($game_player) && $game_player ? "#{$game_player.x},#{$game_player.y}" : "nil"
      pending = if defined?($game_temp) && $game_temp
                  "#{$game_temp.player_new_map_id rescue nil},#{$game_temp.player_new_x rescue nil},#{$game_temp.player_new_y rescue nil}"
                else
                  "nil"
                end
      log("[anil] transition gate state pos=#{position} pending=#{pending} flags=#{flag_text}")
    end
    return false if @anil_transition_gate_rescue_frames < 30
    @anil_transition_gate_rescue_frames = -9999
    anil_recover_post_transfer_lock!(scene, "transition gate hard watchdog") if respond_to?(:anil_recover_post_transfer_lock!)
    return true
  rescue => e
    log("[anil] transition gate hard watchdog failed: #{e.class}: #{e.message}") if respond_to?(:log)
    @anil_transition_gate_rescue_frames = -9999
    return false
  end
end

if defined?(TravelExpansionFramework) &&
   TravelExpansionFramework.respond_to?(:interpreter_stale_for_current_map?) &&
   !TravelExpansionFramework.singleton_class.method_defined?(:tef_anil_original_interpreter_stale_for_current_map?)
  class << TravelExpansionFramework
    alias tef_anil_original_interpreter_stale_for_current_map? interpreter_stale_for_current_map?

    def interpreter_stale_for_current_map?(interpreter, current_map_id = nil)
      return true if respond_to?(:anil_intro_interpreter_leaked?) &&
                     anil_intro_interpreter_leaked?(interpreter, current_map_id)
      return tef_anil_original_interpreter_stale_for_current_map?(interpreter, current_map_id)
    end
  end
end

if defined?(TravelExpansionFramework) &&
   TravelExpansionFramework.respond_to?(:after_expansion_transfer) &&
   !TravelExpansionFramework.singleton_class.method_defined?(:tef_anil_original_after_expansion_transfer)
  class << TravelExpansionFramework
    alias tef_anil_original_after_expansion_transfer after_expansion_transfer

    def after_expansion_transfer(previous_map_id = nil)
      result = tef_anil_original_after_expansion_transfer(previous_map_id)
      current_map_id = ($game_map.map_id rescue nil)
      previous_anil = anil_map_context?(previous_map_id) if respond_to?(:anil_map_context?)
      current_anil = anil_map_context?(current_map_id) if respond_to?(:anil_map_context?)
      anil_capture_host_player_visual_state!("entry transfer") if current_anil && !previous_anil &&
                                                                  respond_to?(:anil_capture_host_player_visual_state!)
      anil_restore_host_player_visuals!("transfer") if current_anil &&
                                                       respond_to?(:anil_player_visuals_need_restore?) &&
                                                       anil_player_visuals_need_restore? &&
                                                       respond_to?(:anil_restore_host_player_visuals!)
      anil_mark_recent_transfer!(previous_map_id, current_map_id) if respond_to?(:anil_mark_recent_transfer!)
      if current_anil && respond_to?(:anil_local_map_for_runtime) &&
         integer(anil_local_map_for_runtime(current_map_id), 0) == 33 &&
         respond_to?(:anil_recover_transition_visuals!)
        anil_recover_transition_visuals!((defined?($scene) ? $scene : nil), "forest transfer arrival", false)
      end
      return result
    end
  end
end

class PokemonSystem
  def guardar_al_curar?
    return @tef_anil_save_on_heal ? true : false
  rescue
    return false
  end unless method_defined?(:guardar_al_curar?)

  def guardar_al_curar=(value)
    @tef_anil_save_on_heal = value ? true : false
  rescue
    @tef_anil_save_on_heal = false
  end unless method_defined?(:guardar_al_curar=)

  def salvajes_visibles_en_ow
    value = @tef_anil_visible_wilds
    return 1 if value.nil?
    return 1 if value == true
    return 0 if value == false
    return TravelExpansionFramework.integer(value, 1)
  rescue
    return 1
  end

  def salvajes_visibles_en_ow=(value)
    @tef_anil_visible_wilds = value == true ? 1 : (value == false ? 0 : TravelExpansionFramework.integer(value, 0))
  rescue
    @tef_anil_visible_wilds = 0
  end

  def salvajes_visibles_en_ow?
    return salvajes_visibles_en_ow != 0
  rescue
    return true
  end
end

module TravelExpansionFramework
  module_function

  def anil_visible_wilds_enabled?
    return true if !anil_event_context_active?
    return true if !defined?($PokemonSystem) || !$PokemonSystem
    return $PokemonSystem.salvajes_visibles_en_ow? if $PokemonSystem.respond_to?(:salvajes_visibles_en_ow?)
    value = $PokemonSystem.salvajes_visibles_en_ow if $PokemonSystem.respond_to?(:salvajes_visibles_en_ow)
    return true if value.nil?
    return value != 0
  rescue => e
    log("[anil] visible wild option fallback enabled after #{e.class}: #{e.message}") if respond_to?(:log)
    return true
  end
end

if defined?(Scene_Map)
  class Scene_Map
    alias tef_anil_safe_transfer_player transfer_player unless method_defined?(:tef_anil_safe_transfer_player)
    alias tef_anil_transition_watchdog_update update unless method_defined?(:tef_anil_transition_watchdog_update)

    def transfer_player(*args)
      previous_map_id = ($game_map.map_id rescue nil)
      target_map_id = ($game_temp.player_new_map_id rescue nil)
      anil_involved = false
      anil_forest_target = false
      if defined?(TravelExpansionFramework)
        anil_involved = (TravelExpansionFramework.anil_map_context?(previous_map_id) rescue false) ||
                        (TravelExpansionFramework.anil_map_context?(target_map_id) rescue false)
        anil_forest_target = anil_involved &&
                             TravelExpansionFramework.respond_to?(:anil_local_map_for_runtime) &&
                             TravelExpansionFramework.integer(TravelExpansionFramework.anil_local_map_for_runtime(target_map_id), 0) == 33
      end
      if anil_involved
        TravelExpansionFramework.anil_mark_recent_transfer!(previous_map_id, target_map_id) if TravelExpansionFramework.respond_to?(:anil_mark_recent_transfer!)
        if defined?($game_temp) && $game_temp
          $game_temp.transition_processing = false if $game_temp.respond_to?(:transition_processing=)
          $game_temp.transition_name = "" if $game_temp.respond_to?(:transition_name=)
        end
        TravelExpansionFramework.clear_stuck_screen_effects!("anil pre-transfer #{previous_map_id} -> #{target_map_id}", true) if anil_forest_target &&
                                                                                                                              TravelExpansionFramework.respond_to?(:clear_stuck_screen_effects!)
      end
      result = tef_anil_safe_transfer_player(*args)
      if anil_involved && defined?(TravelExpansionFramework)
        dark = TravelExpansionFramework.anil_transition_visuals_dark?(self) if TravelExpansionFramework.respond_to?(:anil_transition_visuals_dark?)
        if result == false || anil_forest_target || dark
          TravelExpansionFramework.anil_recover_transition_visuals!(self, "transfer_player #{previous_map_id} -> #{target_map_id}", result == false) if TravelExpansionFramework.respond_to?(:anil_recover_transition_visuals!)
        elsif TravelExpansionFramework.respond_to?(:clear_stuck_screen_effects!)
          TravelExpansionFramework.clear_stuck_screen_effects!("anil transfer #{previous_map_id} -> #{target_map_id}")
        end
        if result != false && TravelExpansionFramework.respond_to?(:anil_finish_transfer_tail_interpreter!)
          TravelExpansionFramework.anil_finish_transfer_tail_interpreter!(previous_map_id, ($game_map.map_id rescue target_map_id), "transfer_player")
        end
        if result != false && TravelExpansionFramework.respond_to?(:anil_adjust_transition_gate_landing!)
          TravelExpansionFramework.anil_adjust_transition_gate_landing!(previous_map_id, ($game_map.map_id rescue target_map_id))
        end
        if result != false && anil_forest_target &&
           TravelExpansionFramework.respond_to?(:anil_complete_transition_gate_arrival!)
          TravelExpansionFramework.anil_complete_transition_gate_arrival!(self, previous_map_id, ($game_map.map_id rescue target_map_id), "transfer_player #{previous_map_id} -> #{target_map_id}", true)
          if TravelExpansionFramework.respond_to?(:log)
            TravelExpansionFramework.log("[anil] handing off scene update after transition gate transfer #{previous_map_id} -> #{target_map_id}")
          end
          update_depth = TravelExpansionFramework.integer((@tef_anil_update_guard_depth rescue 0), 0)
          throw(:tef_anil_transition_gate_handoff, result) if update_depth > 0
        end
      end
      return result
    rescue => e
      if anil_involved && defined?(TravelExpansionFramework)
        TravelExpansionFramework.log("[anil] transfer_player guarded #{previous_map_id} -> #{target_map_id} after #{e.class}: #{e.message}") if TravelExpansionFramework.respond_to?(:log)
        TravelExpansionFramework.anil_recover_transition_visuals!(self, "transfer exception #{previous_map_id} -> #{target_map_id}", true) if TravelExpansionFramework.respond_to?(:anil_recover_transition_visuals!)
        return false
      end
      raise
    ensure
      if anil_involved && defined?($game_temp) && $game_temp
        $game_temp.player_transferring = false if $game_temp.respond_to?(:player_transferring=) && result == false
        $game_temp.transition_processing = false if $game_temp.respond_to?(:transition_processing=) && result == false
      end
    end

    def update
      TravelExpansionFramework.anil_transition_gate_pre_update_unlock!(self) if defined?(TravelExpansionFramework) &&
                                                                                TravelExpansionFramework.respond_to?(:anil_transition_gate_pre_update_unlock!)
      sentinel = Object.new
      result = nil
      @tef_anil_update_guard_depth = TravelExpansionFramework.integer((@tef_anil_update_guard_depth rescue 0), 0) + 1 if defined?(TravelExpansionFramework)
      handoff = catch(:tef_anil_transition_gate_handoff) do
        result = tef_anil_transition_watchdog_update
        sentinel
      end
      if handoff != sentinel
        TravelExpansionFramework.anil_transition_gate_pre_update_unlock!(self) if defined?(TravelExpansionFramework) &&
                                                                                  TravelExpansionFramework.respond_to?(:anil_transition_gate_pre_update_unlock!)
        begin
          updateSpritesets(false) if respond_to?(:updateSpritesets)
        rescue => e
          TravelExpansionFramework.log("[anil] transition gate handoff sprite update failed: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                                           TravelExpansionFramework.respond_to?(:log)
        end
        TravelExpansionFramework.log("[anil] returned scene update after transition gate handoff on map #{($game_map.map_id rescue nil)}") if defined?(TravelExpansionFramework) &&
                                                                                                                                              TravelExpansionFramework.respond_to?(:log)
        return handoff
      end
      TravelExpansionFramework.anil_transition_watchdog_tick!(self) if defined?(TravelExpansionFramework) &&
                                                                       TravelExpansionFramework.respond_to?(:anil_transition_watchdog_tick!)
      TravelExpansionFramework.anil_post_transfer_lock_watchdog_tick!(self) if defined?(TravelExpansionFramework) &&
                                                                               TravelExpansionFramework.respond_to?(:anil_post_transfer_lock_watchdog_tick!)
      TravelExpansionFramework.anil_transition_hall_visible_lock_tick!(self) if defined?(TravelExpansionFramework) &&
                                                                                TravelExpansionFramework.respond_to?(:anil_transition_hall_visible_lock_tick!)
      TravelExpansionFramework.anil_transition_gate_hard_watchdog_tick!(self) if defined?(TravelExpansionFramework) &&
                                                                                 TravelExpansionFramework.respond_to?(:anil_transition_gate_hard_watchdog_tick!)
      TravelExpansionFramework.anil_player_visual_watchdog_tick!(self) if defined?(TravelExpansionFramework) &&
                                                                          TravelExpansionFramework.respond_to?(:anil_player_visual_watchdog_tick!)
      return result
    ensure
      @tef_anil_update_guard_depth = [TravelExpansionFramework.integer((@tef_anil_update_guard_depth rescue 1), 1) - 1, 0].max if defined?(TravelExpansionFramework) &&
                                                                                                                   @tef_anil_update_guard_depth
    end
  end
end

if defined?(Interpreter)
  class Interpreter
    alias tef_anil_transition_gate_setup_starting_event setup_starting_event unless method_defined?(:tef_anil_transition_gate_setup_starting_event)
    alias tef_anil_transition_gate_interpreter_update update unless method_defined?(:tef_anil_transition_gate_interpreter_update)

    def setup_starting_event(*args)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:anil_transition_gate_suppress_starting_events?) &&
         TravelExpansionFramework.anil_transition_gate_suppress_starting_events?
        $game_map.refresh if defined?($game_map) && $game_map && $game_map.respond_to?(:need_refresh) &&
                              $game_map.need_refresh && $game_map.respond_to?(:refresh)
        if TravelExpansionFramework.respond_to?(:anil_clear_transition_gate_off_player_autoruns!)
          TravelExpansionFramework.anil_clear_transition_gate_off_player_autoruns!("setup_starting_event", true)
        elsif TravelExpansionFramework.respond_to?(:anil_clear_transition_gate_event_starts!)
          TravelExpansionFramework.anil_clear_transition_gate_event_starts!(false)
        end
      end
      return tef_anil_transition_gate_setup_starting_event(*args)
    end

    def update(*args)
      TravelExpansionFramework.anil_transition_hall_pre_interpreter_rescue!(self, "interpreter pre-update") if defined?(TravelExpansionFramework) &&
                                                                                                               TravelExpansionFramework.respond_to?(:anil_transition_hall_pre_interpreter_rescue!)
      TravelExpansionFramework.anil_transition_gate_idle_unlock!($scene, "interpreter pre-update", true) if defined?(TravelExpansionFramework) &&
                                                                                                            TravelExpansionFramework.respond_to?(:anil_transition_gate_idle_unlock!)
      return tef_anil_transition_gate_interpreter_update(*args)
    end
  end
end

if defined?(Game_Player)
  class Game_Player
    alias tef_anil_transition_gate_player_update update unless method_defined?(:tef_anil_transition_gate_player_update)

    def update(*args)
      TravelExpansionFramework.anil_transition_gate_idle_unlock!($scene, "player pre-update", true) if defined?(TravelExpansionFramework) &&
                                                                                                      TravelExpansionFramework.respond_to?(:anil_transition_gate_idle_unlock!)
      result = tef_anil_transition_gate_player_update(*args)
      TravelExpansionFramework.anil_transition_gate_idle_unlock!($scene, "player post-update", false) if defined?(TravelExpansionFramework) &&
                                                                                                        TravelExpansionFramework.respond_to?(:anil_transition_gate_idle_unlock!)
      return result
    end
  end
end

if defined?(Game_Event)
  class Game_Event
    alias tef_anil_transition_gate_refresh refresh unless method_defined?(:tef_anil_transition_gate_refresh)
    alias tef_anil_original_tsOn? tsOn? unless method_defined?(:tef_anil_original_tsOn?) || !method_defined?(:tsOn?)
    alias tef_anil_original_tsOff? tsOff? unless method_defined?(:tef_anil_original_tsOff?) || !method_defined?(:tsOff?)
    alias tef_anil_original_setTempSwitchOn setTempSwitchOn unless method_defined?(:tef_anil_original_setTempSwitchOn) || !method_defined?(:setTempSwitchOn)
    alias tef_anil_original_setTempSwitchOff setTempSwitchOff unless method_defined?(:tef_anil_original_setTempSwitchOff) || !method_defined?(:setTempSwitchOff)

    def tef_anil_temp_switch_context?
      defined?(TravelExpansionFramework) &&
        TravelExpansionFramework.respond_to?(:anil_map_context?) &&
        TravelExpansionFramework.anil_map_context?(@map_id)
    rescue
      false
    end

    def tef_anil_temp_switch_value(switch_name = "A")
      temp = @tempSwitches if instance_variable_defined?(:@tempSwitches)
      if temp.respond_to?(:has_key?) && temp.has_key?(switch_name.to_s)
        return temp[switch_name.to_s] ? true : false
      end
      return false
    rescue
      return false
    end

    def tef_anil_set_temp_switch_value(switch_name = "A", value = true)
      @tempSwitches ||= {}
      @tempSwitches[switch_name.to_s] = value ? true : false
      if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:anil_set_temp_switch)
        TravelExpansionFramework.anil_set_temp_switch(@map_id, @id, switch_name, value)
      end
      refresh
      return true
    rescue
      return false
    end

    def tsOn?(switch_name)
      return tef_anil_temp_switch_value(switch_name) if tef_anil_temp_switch_context?
      return tef_anil_original_tsOn?(switch_name)
    end

    def tsOff?(switch_name)
      return !tef_anil_temp_switch_value(switch_name) if tef_anil_temp_switch_context?
      return tef_anil_original_tsOff?(switch_name)
    end

    def setTempSwitchOn(switch_name)
      return tef_anil_set_temp_switch_value(switch_name, true) if tef_anil_temp_switch_context?
      return tef_anil_original_setTempSwitchOn(switch_name)
    end

    def setTempSwitchOff(switch_name)
      return tef_anil_set_temp_switch_value(switch_name, false) if tef_anil_temp_switch_context?
      return tef_anil_original_setTempSwitchOff(switch_name)
    end

    def refresh(*args)
      result = tef_anil_transition_gate_refresh(*args)
      if defined?(TravelExpansionFramework) &&
         TravelExpansionFramework.respond_to?(:anil_transition_gate_event?) &&
         TravelExpansionFramework.anil_transition_gate_event?(self)
        if TravelExpansionFramework.respond_to?(:anil_transition_gate_touch_exit?) &&
           TravelExpansionFramework.anil_transition_gate_touch_exit?(self)
          @through = false
        elsif @trigger == 3
          @through = true
        end
      end
      return result
    end
  end
end

module TravelExpansionFramework
  module_function

  def anil_pause_menu_label(command)
    label = anil_manual_text_fixups(command.to_s)
    label.gsub!(/Pok.{0,4}dex/i, "Pokedex")
    label.gsub!(/Pok.{0,4}mon/i, "Pokemon")
    label.gsub!(/Pok.{0,4}gear/i, "Pokegear")
    label.sub!(/\A[^A-Za-z]+(?=Pokedex|Pokemon|Pokegear)/i, "")
    label.gsub!(/[ \t]{2,}/, " ")
    label.strip!
    return label.empty? ? command.to_s : label
  rescue
    return command.to_s
  end

  def anil_pause_menu_command_allowed?(label)
    text = label.to_s.downcase
    return false if text.strip.empty?
    return true
  rescue
    return true
  end
end

if defined?(TravelExpansionFramework) && TravelExpansionFramework.respond_to?(:format_translation_text)
  class << TravelExpansionFramework
    alias tef_anil_original_format_translation_text format_translation_text unless method_defined?(:tef_anil_original_format_translation_text)

    def format_translation_text(template, values)
      result = tef_anil_original_format_translation_text(template, values)
      if respond_to?(:anil_event_context_active?) &&
         anil_event_context_active? &&
         respond_to?(:anil_manual_text_fixups)
        result = anil_manual_text_fixups(result)
      end
      return result
    rescue
      return template.to_s
    end
  end
end

if defined?(PokemonPauseMenu_Scene)
  class PokemonPauseMenu_Scene
    alias tef_anil_original_pbShowCommands pbShowCommands unless method_defined?(:tef_anil_original_pbShowCommands)

    def pbShowCommands(commands)
      return -1 if defined?($game_temp) && $game_temp && $game_temp.player_transferring
      anil_menu = defined?(TravelExpansionFramework) &&
                  TravelExpansionFramework.respond_to?(:anil_event_context_active?) &&
                  TravelExpansionFramework.anil_event_context_active?
      return tef_anil_original_pbShowCommands(commands) if !anil_menu
      filtered = []
      Array(commands).each_with_index do |command, original_index|
        label = TravelExpansionFramework.anil_pause_menu_label(command)
        next if !TravelExpansionFramework.anil_pause_menu_command_allowed?(label)
        filtered << [label, original_index]
      end
      return -1 if filtered.empty?
      display_commands = filtered.map { |entry| entry[0] }
      ret = tef_anil_original_pbShowCommands(display_commands)
      return ret if ret.nil? || ret < 0
      mapped = filtered[ret] ? filtered[ret][1] : ret
      if defined?($PokemonTemp) && $PokemonTemp
        $PokemonTemp.menuLastChoice = mapped
      end
      return mapped
    rescue => e
      TravelExpansionFramework.log("[anil] pause menu filter failed: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                   TravelExpansionFramework.respond_to?(:log)
      return tef_anil_original_pbShowCommands(commands)
    end
  end
end

if defined?(pbStartOver) && !defined?(tef_anil_original_pbStartOver)
  alias tef_anil_original_pbStartOver pbStartOver

  def pbStartOver(gameover = false, *args)
    anil_context = defined?(TravelExpansionFramework) &&
                   TravelExpansionFramework.respond_to?(:anil_event_context_active?) &&
                   TravelExpansionFramework.anil_event_context_active?
    result = send(:tef_anil_original_pbStartOver, gameover, *args)
    if anil_context && defined?(TravelExpansionFramework) &&
       TravelExpansionFramework.respond_to?(:anil_restore_host_player_visuals!)
      TravelExpansionFramework.anil_restore_host_player_visuals!("start over")
    end
    return result
  end
end

if !Object.method_defined?(:pb_salvajes_visibles_en_ow?) && !Object.private_method_defined?(:pb_salvajes_visibles_en_ow?)
  def pb_salvajes_visibles_en_ow?
    return TravelExpansionFramework.anil_visible_wilds_enabled? if defined?(TravelExpansionFramework) &&
                                                                   TravelExpansionFramework.respond_to?(:anil_visible_wilds_enabled?)
    return true
  rescue
    return true
  end
end

module TravelExpansionFramework
  module_function

  ANIL_KEY_ITEM_ALIASES = {
    :POKERIDER     => :POKERIDER,
    :POKERIDE      => :POKERIDER,
    :POKE_RIDE     => :POKERIDER,
    :POKERADAR     => :POKERADAR,
    :POKE_RADAR    => :POKERADAR,
    :RADAR         => :RADAR,
    :ALBUMFOTOS    => :ALBUMFOTOS,
    :ALBUM_FOTOS   => :ALBUMFOTOS,
    :ALBUMDEFOTOS  => :ALBUMFOTOS,
    :PHOTOALBUM    => :ALBUMFOTOS,
    :PHOTO_ALBUM   => :ALBUMFOTOS
  }.freeze unless const_defined?(:ANIL_KEY_ITEM_ALIASES, false)

  def anil_key_item_handler_registry
    @anil_key_item_handler_registry ||= {}
  end

  def anil_key_item_raw_name(value)
    raw = value.to_s.strip.gsub(/\A:/, "")
    raw = imported_item_raw_name(ANIL_EXPANSION_ID, raw) if respond_to?(:imported_item_raw_name) &&
                                                           const_defined?(:ANIL_EXPANSION_ID)
    normalized = raw.upcase.gsub(/[^A-Z0-9]+/, "_").gsub(/\A_+|_+\z/, "").to_sym
    aliases = const_defined?(:ANIL_KEY_ITEM_ALIASES, false) ? ANIL_KEY_ITEM_ALIASES : {}
    return aliases[normalized] || normalized
  rescue
    return value.to_s.upcase.to_sym
  end

  def anil_key_item_reference?(value)
    aliases = const_defined?(:ANIL_KEY_ITEM_ALIASES, false) ? ANIL_KEY_ITEM_ALIASES : {}
    return aliases.values.include?(anil_key_item_raw_name(value))
  rescue
    return false
  end

  def anil_key_item_symbols(raw_name)
    raw = anil_key_item_raw_name(raw_name)
    expansion = const_defined?(:ANIL_EXPANSION_ID) ? ANIL_EXPANSION_ID : "anil"
    symbols = []
    direct = base_item_try_get(raw) if respond_to?(:base_item_try_get)
    symbols << (direct.id rescue raw) if direct
    runtime = imported_item_runtime_symbol(expansion, raw) if respond_to?(:imported_item_runtime_symbol)
    symbols << runtime if runtime
    imported = ensure_external_item_registered(expansion, raw) if respond_to?(:ensure_external_item_registered)
    symbols << imported if imported
    if respond_to?(:imported_runtime_items)
      imported_runtime_items.each_value do |metadata|
        next if !metadata.is_a?(Hash)
        metadata_expansion = metadata[:expansion_id] || metadata["expansion_id"]
        next if anil_canonical_expansion_id(metadata_expansion).to_s != expansion.to_s
        metadata_raw = metadata[:raw_name] || metadata["raw_name"] || metadata[:source_id] || metadata["source_id"]
        next if anil_key_item_raw_name(metadata_raw) != raw
        symbols << (metadata[:runtime_symbol] || metadata["runtime_symbol"])
      end
    end
    return symbols.compact.map { |symbol| symbol.is_a?(String) ? symbol.to_sym : symbol }.uniq
  rescue => e
    log("[anil] key item symbol lookup failed for #{raw_name}: #{e.class}: #{e.message}") if respond_to?(:log)
    return []
  end

  def anil_party_snapshot_names
    anil_party_members.map do |pkmn|
      next nil if pkmn.nil?
      name = pkmn.name if pkmn.respond_to?(:name)
      next name.to_s if name && !name.to_s.empty?
      species = pkmn.species if pkmn.respond_to?(:species)
      data = GameData::Species.try_get(species) rescue nil
      next data ? data.name.to_s : species.to_s
    end.compact.first(6)
  rescue
    return []
  end

  def anil_current_map_album_name
    name = $game_map.name if defined?($game_map) && $game_map && $game_map.respond_to?(:name)
    if (name.nil? || name.to_s.empty?) && defined?($mapinfos) && $mapinfos
      info = $mapinfos[$game_map.map_id] rescue nil
      name = info.name if info && info.respond_to?(:name)
    end
    local = anil_local_map_for_runtime($game_map.map_id) if defined?($game_map) && $game_map &&
                                                            respond_to?(:anil_local_map_for_runtime)
    fallback = local.to_i > 0 ? "Anil Map #{local}" : "Anil Map"
    return name.to_s.empty? ? fallback : anil_manual_text_fixups(name.to_s)
  rescue
    return "Anil Map"
  end

  def anil_photo_album_entries
    entries = anil_value("photo_album_entries", []) if respond_to?(:anil_value)
    entries = [] if !entries.is_a?(Array)
    return entries.find_all { |entry| entry.is_a?(Hash) }
  rescue
    return []
  end

  def anil_record_photo_album_entry!(event_ids = nil)
    return false if !anil_event_context_active?
    return false if !defined?($game_map) || !$game_map || !defined?($game_player) || !$game_player
    entry = {
      :runtime_map_id => $game_map.map_id,
      :local_map_id   => (anil_local_map_for_runtime($game_map.map_id) if respond_to?(:anil_local_map_for_runtime)),
      :map_name       => anil_current_map_album_name,
      :x              => $game_player.x,
      :y              => $game_player.y,
      :party          => anil_party_snapshot_names,
      :event_ids      => Array(event_ids).flatten.map { |id| integer(id, 0) }.select { |id| id > 0 }.uniq,
      :recorded_at    => Time.now.to_i
    }
    entries = anil_photo_album_entries
    last = entries.last
    if last && integer(last[:runtime_map_id] || last["runtime_map_id"], 0) == entry[:runtime_map_id] &&
       integer(last[:x] || last["x"], -1) == entry[:x] &&
       integer(last[:y] || last["y"], -1) == entry[:y] &&
       Array(last[:party] || last["party"]) == entry[:party]
      return false
    end
    entries << entry
    entries = entries.last(50)
    anil_remember_value("photo_album_entries", entries) if respond_to?(:anil_remember_value)
    log("[anil] recorded Photo Album entry at #{entry[:map_name]} (#{entry[:runtime_map_id]} #{entry[:x]},#{entry[:y]})") if respond_to?(:log)
    return true
  rescue => e
    log("[anil] Photo Album record failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_use_photo_album!
    entries = anil_photo_album_entries
    if entries.empty?
      pbMessage(_INTL("There aren't any photos in the album yet.")) if defined?(pbMessage)
      return true
    end
    pbMessage(_INTL("The Photo Album has {1} saved photo(s).", entries.length)) if defined?(pbMessage)
    entries.last(8).each_with_index do |entry, index|
      map_name = entry[:map_name] || entry["map_name"] || "Anil Map"
      party = Array(entry[:party] || entry["party"]).reject { |name| name.to_s.empty? }
      party_text = party.empty? ? "" : "\n#{party.join(", ")}"
      pbMessage("#{index + 1}. #{map_name}#{party_text}") if defined?(pbMessage)
    end
    return true
  rescue => e
    log("[anil] Photo Album open failed: #{e.class}: #{e.message}") if respond_to?(:log)
    pbMessage(_INTL("The Photo Album could not be opened.")) if defined?(pbMessage)
    return false
  end

  def anil_queue_poke_ride_transfer(flydata)
    return false if !flydata || flydata.length < 3
    anchor = sanitize_anchor({
      :map_id    => flydata[0],
      :x         => flydata[1],
      :y         => flydata[2],
      :direction => 2
    }) if respond_to?(:sanitize_anchor)
    return false if !anchor
    pbCancelVehicles if defined?(pbCancelVehicles)
    expansion = current_map_expansion_id(anchor[:map_id]) if respond_to?(:current_map_expansion_id)
    if respond_to?(:safe_transfer_to_anchor)
      return safe_transfer_to_anchor(anchor, {
        :source            => :anil_poke_ride,
        :expansion_id      => expansion,
        :allow_story_state => false,
        :immediate         => false
      })
    end
    return queue_anchor_transfer(anchor) if respond_to?(:queue_anchor_transfer)
    return false
  rescue => e
    log("[anil] Poke Ride transfer queue failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_use_poke_ride!
    if defined?($game_temp) && $game_temp && $game_temp.player_transferring
      pbMessage(_INTL("You can't use that right now.")) if defined?(pbMessage)
      return false
    end
    if !respond_to?(:open_current_world_town_map)
      pbMessage(_INTL("The Poke Ride map could not be opened.")) if defined?(pbMessage)
      return false
    end
    flydata = open_current_world_town_map(-1, true, true, false, nil, false)
    return true if flydata.nil?
    return anil_queue_poke_ride_transfer(flydata)
  rescue => e
    log("[anil] Poke Ride failed: #{e.class}: #{e.message}") if respond_to?(:log)
    pbMessage(_INTL("The Poke Ride map could not be opened.")) if defined?(pbMessage)
    return false
  end

  def anil_use_poke_radar!
    return false if !defined?(pbCanUsePokeRadar?) || !defined?(pbUsePokeRadar)
    return false if !pbCanUsePokeRadar?
    return pbUsePokeRadar ? true : false
  rescue => e
    log("[anil] Poke Radar failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_species_display_name(species)
    data = GameData::Species.try_get(species) rescue nil
    return data.name.to_s if data && data.respond_to?(:name)
    return species.to_s.split("_").map { |part| part.capitalize }.join(" ")
  rescue
    return species.to_s
  end

  def anil_use_wild_radar!
    encounters = defined?($PokemonEncounters) ? $PokemonEncounters : nil
    if !encounters || !encounters.respond_to?(:encounter_type) || !encounters.respond_to?(:listPossibleEncounters)
      pbMessage(_INTL("The radar isn't picking up any wild Pokemon here.")) if defined?(pbMessage)
      return true
    end
    encounter_type = encounters.encounter_type rescue nil
    if encounter_type.nil?
      pbMessage(_INTL("The radar isn't picking up any wild Pokemon here.")) if defined?(pbMessage)
      return true
    end
    table = encounters.listPossibleEncounters(encounter_type) rescue []
    ranges = {}
    Array(table).each do |entry|
      next if !entry.is_a?(Array) || entry.length < 4
      species = entry[1]
      min_level = integer(entry[2], 1)
      max_level = integer(entry[3], min_level)
      current = ranges[species] || [min_level, max_level]
      current[0] = [current[0], min_level].min
      current[1] = [current[1], max_level].max
      ranges[species] = current
    end
    if ranges.empty?
      pbMessage(_INTL("The radar isn't picking up any wild Pokemon here.")) if defined?(pbMessage)
      return true
    end
    type_data = GameData::EncounterType.try_get(encounter_type) rescue nil
    type_name = type_data && type_data.respond_to?(:real_name) ? type_data.real_name.to_s : encounter_type.to_s
    pbMessage(_INTL("The radar found {1} wild Pokemon signal(s) nearby.", ranges.length)) if defined?(pbMessage)
    lines = ranges.sort_by { |species, _range| anil_species_display_name(species) }.map do |species, range|
      level_text = range[0] == range[1] ? "Lv. #{range[0]}" : "Lv. #{range[0]}-#{range[1]}"
      "#{anil_species_display_name(species)} #{level_text}"
    end
    lines.first(12).each_slice(4) do |slice|
      pbMessage("#{type_name}: #{slice.join(", ")}") if defined?(pbMessage)
    end
    remaining = lines.length - 12
    pbMessage(_INTL("And {1} more signal(s).", remaining)) if remaining > 0 && defined?(pbMessage)
    return true
  rescue => e
    log("[anil] wild radar failed: #{e.class}: #{e.message}") if respond_to?(:log)
    pbMessage(_INTL("The radar couldn't read this area.")) if defined?(pbMessage)
    return false
  end

  def anil_register_key_item_symbol!(raw_name, item_symbol)
    return false if item_symbol.nil? || !defined?(ItemHandlers)
    raw = anil_key_item_raw_name(raw_name)
    symbol = item_symbol.is_a?(String) ? item_symbol.to_sym : item_symbol
    key = "#{raw}:#{symbol}"
    return false if anil_key_item_handler_registry[key]
    case raw
    when :POKERADAR
      if symbol == :POKERADAR && ItemHandlers::UseInField[symbol] && ItemHandlers::UseFromBag[symbol]
        anil_key_item_handler_registry[key] = true
        return false
      end
      ItemHandlers::UseInField.add(symbol, proc { |_item|
        next TravelExpansionFramework.anil_use_poke_radar! ? 1 : 0
      })
      ItemHandlers::UseFromBag.add(symbol, proc { |_item|
        next TravelExpansionFramework.anil_use_poke_radar! ? 2 : 0
      })
    when :RADAR
      ItemHandlers::UseInField.add(symbol, proc { |_item|
        next TravelExpansionFramework.anil_use_wild_radar! ? 1 : 0
      })
      ItemHandlers::UseFromBag.add(symbol, proc { |_item|
        next TravelExpansionFramework.anil_use_wild_radar! ? 1 : 0
      })
    when :POKERIDER
      ItemHandlers::UseInField.add(symbol, proc { |_item|
        next TravelExpansionFramework.anil_use_poke_ride! ? 1 : 0
      })
      ItemHandlers::UseFromBag.add(symbol, proc { |_item|
        next TravelExpansionFramework.anil_use_poke_ride! ? 2 : 0
      })
    when :ALBUMFOTOS
      ItemHandlers::UseInField.add(symbol, proc { |_item|
        next TravelExpansionFramework.anil_use_photo_album! ? 1 : 0
      })
      ItemHandlers::UseFromBag.add(symbol, proc { |_item|
        next TravelExpansionFramework.anil_use_photo_album! ? 1 : 0
      })
    else
      return false
    end
    anil_key_item_handler_registry[key] = true
    return true
  rescue => e
    log("[anil] key item handler failed for #{raw_name}/#{item_symbol}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end

  def anil_register_key_item_handlers!
    return false if !defined?(ItemHandlers)
    return false if @anil_key_item_registration_active
    @anil_key_item_registration_active = true
    registered = false
    [:POKERIDER, :POKERADAR, :RADAR, :ALBUMFOTOS].each do |raw|
      anil_key_item_symbols(raw).each do |symbol|
        registered = anil_register_key_item_symbol!(raw, symbol) || registered
      end
    end
    log("[anil] registered Anil key item handlers #{anil_key_item_handler_registry.keys.inspect}") if registered && respond_to?(:log)
    return registered
  rescue => e
    log("[anil] key item registration failed: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  ensure
    @anil_key_item_registration_active = false
  end
end

if defined?(TravelExpansionFramework) &&
   TravelExpansionFramework.respond_to?(:ensure_external_item_registered) &&
   !TravelExpansionFramework.singleton_class.method_defined?(:tef_anil_items_original_ensure_external_item_registered)
  class << TravelExpansionFramework
    alias tef_anil_items_original_ensure_external_item_registered ensure_external_item_registered

    def ensure_external_item_registered(expansion_id, item_identifier)
      result = tef_anil_items_original_ensure_external_item_registered(expansion_id, item_identifier)
      if result && respond_to?(:anil_canonical_expansion_id) &&
         anil_canonical_expansion_id(expansion_id).to_s == TravelExpansionFramework::ANIL_EXPANSION_ID.to_s &&
         !@anil_key_item_registration_active &&
         respond_to?(:anil_key_item_reference?) &&
         anil_key_item_reference?(item_identifier)
        anil_register_key_item_handlers! if respond_to?(:anil_register_key_item_handlers!)
      end
      return result
    end
  end
end

TravelExpansionFramework.anil_register_key_item_handlers! if defined?(TravelExpansionFramework) &&
                                                             TravelExpansionFramework.respond_to?(:anil_register_key_item_handlers!)

class Interpreter
  const_set(:LevelCapsEX, ::LevelCapsEX) if defined?(::LevelCapsEX) && !const_defined?(:LevelCapsEX, false)
  const_set(:ChallengeModes, ::ChallengeModes) if defined?(::ChallengeModes) && !const_defined?(:ChallengeModes, false)
  const_set(:RandomizedChallenge, ::RandomizedChallenge) if defined?(::RandomizedChallenge) && !const_defined?(:RandomizedChallenge, false)
  const_set(:RandomizerConfigurator, ::RandomizerConfigurator) if defined?(::RandomizerConfigurator) && !const_defined?(:RandomizerConfigurator, false)
  const_set(:FollowingPkmn, ::FollowingPkmn) if defined?(::FollowingPkmn) && !const_defined?(:FollowingPkmn, false)
  const_set(:PartyPicture, ::PartyPicture) if defined?(::PartyPicture) && !const_defined?(:PartyPicture, false)

  alias tef_anil_host_get_self get_self if method_defined?(:get_self) && !method_defined?(:tef_anil_host_get_self)
  alias tef_anil_host_setTempSwitchOn setTempSwitchOn if method_defined?(:setTempSwitchOn) && !method_defined?(:tef_anil_host_setTempSwitchOn)
  alias tef_anil_host_setTempSwitchOff setTempSwitchOff if method_defined?(:setTempSwitchOff) && !method_defined?(:tef_anil_host_setTempSwitchOff)
  alias tef_anil_host_isTempSwitchOff? isTempSwitchOff? if method_defined?(:isTempSwitchOff?) && !method_defined?(:tef_anil_host_isTempSwitchOff?)
  alias tef_anil_host_isTempSwitchOn? isTempSwitchOn? if method_defined?(:isTempSwitchOn?) && !method_defined?(:tef_anil_host_isTempSwitchOn?)
  alias tef_anil_host_pbSetSelfSwitch pbSetSelfSwitch if method_defined?(:pbSetSelfSwitch) && !method_defined?(:tef_anil_host_pbSetSelfSwitch)
  alias tef_anil_host_pbPokeCenterPC pbPokeCenterPC if (method_defined?(:pbPokeCenterPC) || private_method_defined?(:pbPokeCenterPC)) &&
                                                       !method_defined?(:tef_anil_host_pbPokeCenterPC) &&
                                                       !private_method_defined?(:tef_anil_host_pbPokeCenterPC)
  alias tef_anil_host_pbSetPokemonCenter pbSetPokemonCenter if (method_defined?(:pbSetPokemonCenter) || private_method_defined?(:pbSetPokemonCenter)) &&
                                                               !method_defined?(:tef_anil_host_pbSetPokemonCenter) &&
                                                               !private_method_defined?(:tef_anil_host_pbSetPokemonCenter)
  alias tef_anil_host_pbPokemonMart pbPokemonMart if (method_defined?(:pbPokemonMart) || private_method_defined?(:pbPokemonMart)) &&
                                                    !method_defined?(:tef_anil_host_pbPokemonMart) &&
                                                    !private_method_defined?(:tef_anil_host_pbPokemonMart)
  alias tef_anil_host_pbEnterNPCName pbEnterNPCName if (method_defined?(:pbEnterNPCName) || private_method_defined?(:pbEnterNPCName)) &&
                                                       !method_defined?(:tef_anil_host_pbEnterNPCName) &&
                                                       !private_method_defined?(:tef_anil_host_pbEnterNPCName)
  alias tef_anil_original_command_102 command_102 if method_defined?(:command_102) && !method_defined?(:tef_anil_original_command_102)
  alias tef_anil_original_execute_script execute_script if method_defined?(:execute_script) && !method_defined?(:tef_anil_original_execute_script)

  def tef_anil_active?
    map_id = @map_id if instance_variable_defined?(:@map_id)
    map_id = ($game_map.map_id rescue nil) if map_id.nil?
    return TravelExpansionFramework.anil_event_context_active?(map_id)
  rescue
    return false
  end

  def get_self
    return nil if !defined?($game_map) || !$game_map
    return $game_map.events[@event_id] if defined?(@event_id) && @event_id && $game_map.events
    return nil
  rescue
    return nil
  end if !method_defined?(:get_self)

  def setTempSwitchOn(switch_name = "A", event_id = nil)
    return tef_anil_host_setTempSwitchOn(switch_name) if !tef_anil_active? && respond_to?(:tef_anil_host_setTempSwitchOn)
    event_id ||= @event_id if instance_variable_defined?(:@event_id)
    map_id = @map_id if instance_variable_defined?(:@map_id)
    event = get_self rescue nil
    return event.setTempSwitchOn(switch_name) if event && event.respond_to?(:setTempSwitchOn)
    return TravelExpansionFramework.anil_set_temp_switch(map_id, event_id, switch_name, true)
  end

  def setTempSwitchOff(switch_name = "A", event_id = nil)
    return tef_anil_host_setTempSwitchOff(switch_name) if !tef_anil_active? && respond_to?(:tef_anil_host_setTempSwitchOff)
    event_id ||= @event_id if instance_variable_defined?(:@event_id)
    map_id = @map_id if instance_variable_defined?(:@map_id)
    event = get_self rescue nil
    return event.setTempSwitchOff(switch_name) if event && event.respond_to?(:setTempSwitchOff)
    return TravelExpansionFramework.anil_set_temp_switch(map_id, event_id, switch_name, false)
  end

  def isTempSwitchOff?(switch_name = "A", event_id = nil)
    return tef_anil_host_isTempSwitchOff?(switch_name) if !tef_anil_active? && respond_to?(:tef_anil_host_isTempSwitchOff?)
    event_id ||= @event_id if instance_variable_defined?(:@event_id)
    map_id = @map_id if instance_variable_defined?(:@map_id)
    event = get_self rescue nil
    return event.tsOff?(switch_name) if event && event.respond_to?(:tsOff?)
    return !TravelExpansionFramework.anil_temp_switch_value(map_id, event_id, switch_name)
  end

  def isTempSwitchOn?(switch_name = "A", event_id = nil)
    return tef_anil_host_isTempSwitchOn?(switch_name) if !tef_anil_active? && respond_to?(:tef_anil_host_isTempSwitchOn?)
    event_id ||= @event_id if instance_variable_defined?(:@event_id)
    map_id = @map_id if instance_variable_defined?(:@map_id)
    event = get_self rescue nil
    return event.tsOn?(switch_name) if event && event.respond_to?(:tsOn?)
    return TravelExpansionFramework.anil_temp_switch_value(map_id, event_id, switch_name)
  end

  def pbSetSelfSwitch(event_id = nil, switch_name = "A", value = true, map_id = nil)
    if !tef_anil_active? && respond_to?(:tef_anil_host_pbSetSelfSwitch, true)
      return tef_anil_host_pbSetSelfSwitch(event_id, switch_name, value, map_id.nil? ? -1 : map_id)
    end
    map_id = @map_id if map_id.nil? && instance_variable_defined?(:@map_id)
    if map_id && TravelExpansionFramework.respond_to?(:translate_expansion_map_id)
      expansion_id = TravelExpansionFramework.current_anil_expansion_id(map_id) rescue nil
      expansion_id ||= TravelExpansionFramework.current_anil_expansion_id rescue nil
      expansion_id ||= TravelExpansionFramework::ANIL_EXPANSION_ID if TravelExpansionFramework.const_defined?(:ANIL_EXPANSION_ID)
      map_id = TravelExpansionFramework.translate_expansion_map_id(expansion_id, map_id) if expansion_id
    end
    event_id ||= @event_id if instance_variable_defined?(:@event_id)
    return TravelExpansionFramework.anil_set_temp_switch(map_id, event_id, switch_name, value)
  end

  def pbEventScreen(scene_class = nil, *args)
    if scene_class.respond_to?(:new)
      scene = scene_class.new rescue nil
      return scene.pbStartScene(*args) if scene && scene.respond_to?(:pbStartScene)
    end
    return 0
  rescue
    return 0
  end

  def pbEnterNPCName(*args)
    if !tef_anil_active?
      return tef_anil_host_pbEnterNPCName(*args) if respond_to?(:tef_anil_host_pbEnterNPCName, true)
      return Object.instance_method(:pbEnterNPCName).bind(self).call(*args) if Object.method_defined?(:pbEnterNPCName) ||
                                                                              Object.private_method_defined?(:pbEnterNPCName)
    end
    fallback_candidates = [args[3], args[0]]
    fallback = fallback_candidates.map { |candidate| candidate.to_s.strip }.find do |candidate|
      TravelExpansionFramework.plausible_rival_name?(candidate)
    end
    name = TravelExpansionFramework.host_rival_name_for_expansion || fallback || "Blue"
    TravelExpansionFramework.anil_remember_value("rival_name", name)
    return name
  rescue
    return tef_anil_active? ? "Blue" : ""
  end

  def pbToneChangeAll(*_args)
    return true
  end

  def pbPanoramaMove(*_args)
    return true
  end

  def pbZoomMap(*_args)
    return true
  end

  def pbCameraToEvent(*_args)
    return true
  end

  def gif(*_args)
    return true
  end

  def terminarFoto(*args)
    TravelExpansionFramework.anil_record_photo_album_entry!(args) if defined?(TravelExpansionFramework) &&
                                                                     TravelExpansionFramework.respond_to?(:anil_record_photo_album_entry!)
    TravelExpansionFramework.anil_clear_party_picture_events(args) if defined?(TravelExpansionFramework) &&
                                                                     TravelExpansionFramework.respond_to?(:anil_clear_party_picture_events)
    return true
  end

  def renderBadgeAnimation(*_args)
    return true
  end

  def tradeExpert(*_args)
    return true
  end

  def delete_all_wild_pkmn_spawned(*_args)
    return true
  end

  def has_any_custom_modes?(*_args)
    return false
  end if !method_defined?(:has_any_custom_modes?)

  def check_has_living_pokemon?(*_args)
    trainer = $Trainer if defined?($Trainer)
    party = trainer.party if trainer && trainer.respond_to?(:party)
    return true if !party.respond_to?(:any?)
    return party.any? do |pkmn|
      next false if pkmn.nil?
      next false if pkmn.respond_to?(:egg?) && pkmn.egg?
      hp = pkmn.hp if pkmn.respond_to?(:hp)
      next hp.nil? ? true : hp.to_i > 0
    end
  rescue
    return true
  end if !method_defined?(:check_has_living_pokemon?)

  def setBattleRule(*args)
    return Kernel.setBattleRule(*args) if defined?(Kernel) && Kernel.respond_to?(:setBattleRule)
    return true
  rescue
    return true
  end if !method_defined?(:setBattleRule)

  def pbTrainerEnd(*_args)
    return true
  end if !method_defined?(:pbTrainerEnd)

  def pbNoticePlayer(event = nil, *_args)
    event.turn_toward_player if event && event.respond_to?(:turn_toward_player)
    return true
  rescue
    return true
  end if !method_defined?(:pbNoticePlayer)

  def pbNoticePlayer2(event = nil, *args)
    return pbNoticePlayer(event, *args)
  rescue
    return true
  end if !method_defined?(:pbNoticePlayer2)

  def pbCaveEntrance(*_args)
    return true
  end if !method_defined?(:pbCaveEntrance)

  def pbCaveExit(*_args)
    return true
  end if !method_defined?(:pbCaveExit)

  def todas_fotos_hechas?(*_args)
    return true
  end if !method_defined?(:todas_fotos_hechas?)

  def pbBridgeOn(*_args)
    return true
  end if !method_defined?(:pbBridgeOn)

  def pbBridgeOff(*_args)
    return true
  end if !method_defined?(:pbBridgeOff)

  def aumentar_entrenadores_importantes(*_args)
    return true
  end if !method_defined?(:aumentar_entrenadores_importantes)

  def add_new_vial_charge(*_args)
    return true
  end if !method_defined?(:add_new_vial_charge)

  def registrar_legendarios_para_reaparecer(*_args)
    return true
  end if !method_defined?(:registrar_legendarios_para_reaparecer)

  def pbCameraReset(*_args)
    return true
  end if !method_defined?(:pbCameraReset)

  def pbMostrarMenuCustomizacion(*_args)
    return true
  end if !method_defined?(:pbMostrarMenuCustomizacion)

  def casino_pokemon_exchange(*_args)
    return true
  end if !method_defined?(:casino_pokemon_exchange)

  def comprar_monedas_casino(*_args)
    return true
  end if !method_defined?(:comprar_monedas_casino)

  def battle_mewtwo_armadura(*_args)
    return true
  end if !method_defined?(:battle_mewtwo_armadura)

  def peluquero_furfrou(*_args)
    return true
  end if !method_defined?(:peluquero_furfrou)

  def resetear_entrenadores_torre(*_args)
    return true
  end if !method_defined?(:resetear_entrenadores_torre)

  def pbRockSmashRandomEncounter(*_args)
    return true
  end if !method_defined?(:pbRockSmashRandomEncounter)

  def pbMiningGame(*_args)
    return true
  end if !method_defined?(:pbMiningGame)

  def pbSlotMachine(*_args)
    return true
  end if !method_defined?(:pbSlotMachine)

  def pbVoltorbFlip(*_args)
    return true
  end if !method_defined?(:pbVoltorbFlip)

  def pbPokeCenterPC(*args)
    return tef_anil_host_pbPokeCenterPC(*args) if respond_to?(:tef_anil_host_pbPokeCenterPC, true)
    return Object.instance_method(:pbPokeCenterPC).bind(self).call(*args) if Object.method_defined?(:pbPokeCenterPC) ||
                                                                            Object.private_method_defined?(:pbPokeCenterPC)
    return true
  rescue
    return true
  end

  def pbSetPokemonCenter(*args)
    return tef_anil_host_pbSetPokemonCenter(*args) if respond_to?(:tef_anil_host_pbSetPokemonCenter, true)
    return Object.instance_method(:pbSetPokemonCenter).bind(self).call(*args) if Object.method_defined?(:pbSetPokemonCenter) ||
                                                                                Object.private_method_defined?(:pbSetPokemonCenter)
    return true
  rescue
    return true
  end

  def pbPokemonMart(*args)
    if !tef_anil_active?
      return tef_anil_host_pbPokemonMart(*args) if respond_to?(:tef_anil_host_pbPokemonMart, true)
      return Object.instance_method(:pbPokemonMart).bind(self).call(*args) if Object.method_defined?(:pbPokemonMart) ||
                                                                             Object.private_method_defined?(:pbPokemonMart)
    end
    return tef_anil_host_pbPokemonMart(*args) if respond_to?(:tef_anil_host_pbPokemonMart, true) && args[0].is_a?(Array)
    return true
  rescue
    return true
  end

  def tef_anil_choice_texts
    command = @list[@index] rescue nil
    params = command.parameters rescue command.instance_variable_get(:@parameters)
    return Array(params[0])
  rescue
    return []
  end

  def tef_anil_choice_indent
    command = @list[@index] rescue nil
    return command.indent if command && command.respond_to?(:indent)
    return command.instance_variable_get(:@indent) if command
    return 0
  rescue
    return 0
  end

  def tef_anil_normalized_choice_join
    normalizer = nil
    normalizer = proc { |text| TravelExpansionFramework.normalize_choice_text(text) } if defined?(TravelExpansionFramework) &&
                                                                                         TravelExpansionFramework.respond_to?(:normalize_choice_text)
    tef_anil_choice_texts.map do |entry|
      normalizer ? normalizer.call(entry) : entry.to_s.downcase
    end.join(" ")
  rescue
    return tef_anil_choice_texts.join(" ").downcase
  end

  def tef_anil_back_closes_choice?
    joined = tef_anil_normalized_choice_join
    return true if joined[/recordar movimiento.*olvidar movimiento.*niveles.*exportar pok.paste/]
    return true if joined[/relearn.*forget.*leader.*export/]
    return true if joined[/preguntas frecuentes.*nada/]
    return true if joined[/faq.*nothing|frequently asked.*nothing|questions.*nothing/]
    return true if joined[/acerca del juego.*acerca de algunos pok.mon.*modo random.*tengo un bug/]
    return true if joined[/about the game.*about certain pok.mon.*random mode.*bug/]
    return true if joined[/about the game/] && joined[/random mode/] && joined[/bug/]
    return true if joined[/acerca del juego/] && joined[/modo random/] && joined[/bug/]
    return true if joined[/sobre los shiny.*puntos de la partida.*mejor nada/]
    return false
  rescue
    return false
  end

  def tef_anil_close_choice_interpreter!(reason = "choice cancelled")
    TravelExpansionFramework.log("[anil] closed menu choice: #{reason}") if defined?(TravelExpansionFramework) &&
                                                                           TravelExpansionFramework.respond_to?(:log)
    @message_waiting = false
    @move_route_waiting = false
    @wait_count = 0
    @branch = {} if @branch
    @child_interpreter = nil
    command_end if respond_to?(:command_end)
    @list = nil
    TravelExpansionFramework.unlock_active_event_context if defined?(TravelExpansionFramework) &&
                                                           TravelExpansionFramework.respond_to?(:unlock_active_event_context)
    Input.update rescue nil
    return false
  rescue
    @list = nil
    return false
  end

  def command_102
    if tef_anil_active? && tef_anil_back_closes_choice?
      @message_waiting = true
      command = pbShowCommands(nil, tef_anil_choice_texts, -1)
      @message_waiting = false
      if command.nil? || command.to_i < 0
        return tef_anil_close_choice_interpreter!("back button")
      end
      @branch[tef_anil_choice_indent] = command if @branch
      Input.update rescue nil
      return true
    end
    return tef_anil_original_command_102 if respond_to?(:tef_anil_original_command_102, true)
    return true
  end if method_defined?(:tef_anil_original_command_102)

  def execute_script(script)
    TravelExpansionFramework.ensure_player_global! if defined?(TravelExpansionFramework) &&
                                                     TravelExpansionFramework.respond_to?(:ensure_player_global!)
    return tef_anil_original_execute_script(script) if respond_to?(:tef_anil_original_execute_script, true)
    return eval(script)
  rescue NoMethodError => e
    missing_name = e.name.to_s rescue ""
    if tef_anil_active? && ["mystery_gift_unlocked", "pbShowdown"].include?(missing_name)
      TravelExpansionFramework.log("[anil] recovered missing script method #{missing_name} in #{script.inspect}") if defined?(TravelExpansionFramework) &&
                                                                                                                     TravelExpansionFramework.respond_to?(:log)
      return false if missing_name == "mystery_gift_unlocked"
      return pbShowdown if missing_name == "pbShowdown" && respond_to?(:pbShowdown)
    end
    raise
  end if method_defined?(:tef_anil_original_execute_script)

  def pbShowdown(*_args)
    exported = TravelExpansionFramework.anil_export_pokepaste! if defined?(TravelExpansionFramework) &&
                                                                  TravelExpansionFramework.respond_to?(:anil_export_pokepaste!)
    if exported
      pbMessage(_INTL("Your team was copied as a PokePaste export.")) if respond_to?(:pbMessage)
    else
      pbMessage(_INTL("There was no team to export.")) if respond_to?(:pbMessage)
    end
    return exported ? true : false
  rescue => e
    TravelExpansionFramework.log("[anil] pbShowdown failed safely: #{e.class}: #{e.message}") if defined?(TravelExpansionFramework) &&
                                                                                                TravelExpansionFramework.respond_to?(:log)
    pbMessage(_INTL("The export could not be completed.")) if respond_to?(:pbMessage)
    return false
  end unless method_defined?(:pbShowdown)

  def get_rare_candies(*_args)
    return true
  end unless method_defined?(:get_rare_candies)

  def recharge_vial(*_args)
    return true
  end unless method_defined?(:recharge_vial)

  def todas_entrenadores_importantes_hechos?(*_args)
    return false
  end unless method_defined?(:todas_entrenadores_importantes_hechos?)

  def online_limpiar_reglas_previas(*_args)
    return true
  end unless method_defined?(:online_limpiar_reglas_previas)

  def restore_original_team(*_args)
    return true
  end unless method_defined?(:restore_original_team)

  def pbCableClub(*_args)
    pbMessage(_INTL("Online features from this imported game are not available here.")) if respond_to?(:pbMessage)
    return false
  rescue
    return false
  end unless method_defined?(:pbCableClub)

  def tef_anil_call_global_method(method_name, *args)
    name = method_name.to_sym
    if Object.private_method_defined?(name) || Object.method_defined?(name)
      return Object.instance_method(name).bind(self).call(*args)
    end
    if defined?(Kernel) && Kernel.respond_to?(name)
      return Kernel.send(name, *args)
    end
    return nil
  rescue
    return nil
  end

  def pbItemBall(item = nil, quantity = 1, *_args)
    picked_up = false
    if item
      picked_up = tef_anil_call_global_method(:pbItemBall, item, quantity)
      if !picked_up
        picked_up = send(:pbReceiveItem, item, quantity) if respond_to?(:pbReceiveItem, true)
        picked_up = tef_anil_call_global_method(:pbReceiveItem, item, quantity) if !picked_up
      end
    end
    setTempSwitchOn("A") if picked_up && respond_to?(:setTempSwitchOn)
    return picked_up ? true : false
  rescue
    return true
  end if !method_defined?(:pbItemBall)

  def permalocke_restore_slots(*_args)
    return true
  end if !method_defined?(:permalocke_restore_slots)

  def pbChoosePokemon(*args)
    if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:party) && !$Trainer.party.empty?
      variable_id = TravelExpansionFramework.integer(args[0], 0)
      $game_variables[variable_id] = 0 if variable_id > 0 && defined?($game_variables) && $game_variables
      return 0
    end
    return nil
  rescue
    return nil
  end if !method_defined?(:pbChoosePokemon)

  def pbChooseNonEggPokemon(*args)
    return pbChoosePokemon(*args)
  rescue
    return nil
  end if !method_defined?(:pbChooseNonEggPokemon)

  def pbGetPokemon(variable_id = 1)
    value = pbGet(variable_id) if respond_to?(:pbGet)
    return value if value.respond_to?(:species)
    index = TravelExpansionFramework.integer(value, -1)
    return $Trainer.party[index] if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:party) && index >= 0
    return nil
  rescue
    return nil
  end if !method_defined?(:pbGetPokemon)

  def pbRegisterPartner(*_args)
    return true
  end if !method_defined?(:pbRegisterPartner)

  def pbDeregisterPartner(*_args)
    return true
  end if !method_defined?(:pbDeregisterPartner)

  def pbHallOfFameEntry(*_args)
    return true
  end if !method_defined?(:pbHallOfFameEntry)

  def pbMostrarListaStarters(*_args)
    return true
  end

  def pbMostrarPkmnAnimado(pokemon = nil, *_args)
    if defined?($game_variables) && $game_variables && pokemon
      $game_variables[1] = pokemon
      $game_variables[3] = pokemon.name if pokemon.respond_to?(:name)
    end
    return true
  rescue
    return true
  end

  def pbTermninarPkmnAnimado(*_args)
    return true
  end

  def pbTerminarPkmnAnimado(*args)
    return pbTermninarPkmnAnimado(*args)
  end

  def show_random_starter_picture(region_index = 0)
    species = TravelExpansionFramework.anil_choose_starter(region_index)
    if defined?($game_variables) && $game_variables
      $game_variables[31] = TravelExpansionFramework.anil_starter_pool(region_index)
      if defined?(Pokemon)
        pokemon = Pokemon.new(species, 5) rescue nil
        $game_variables[1] = pokemon if pokemon
        $game_variables[3] = pokemon.name if pokemon && pokemon.respond_to?(:name)
      end
    end
    return species
  rescue
    return :BULBASAUR
  end

  def give_starter_random(region_index = 0)
    species = show_random_starter_picture(region_index)
    pokemon = ($game_variables[1] rescue nil)
    if pokemon && respond_to?(:pbAddPokemon)
      return pbAddPokemon(pokemon)
    elsif defined?(pbAddPokemon)
      return pbAddPokemon(species, 5)
    end
    return true
  rescue
    return true
  end

  def pbGetKeyItem(key_name = nil, *_args)
    raw = key_name.to_s.sub(/_key\z/i, "")
    item = raw.empty? ? nil : raw.upcase.to_sym
    if item && defined?(GameData::Item) && (GameData::Item.try_get(item) rescue nil)
      return send(:pbReceiveItem, item) if respond_to?(:pbReceiveItem, true)
      return tef_anil_call_global_method(:pbReceiveItem, item)
    end
    if item && tef_anil_active? &&
       TravelExpansionFramework.respond_to?(:ensure_external_item_registered) &&
       TravelExpansionFramework.respond_to?(:anil_key_item_reference?) &&
       TravelExpansionFramework.anil_key_item_reference?(item)
      imported = TravelExpansionFramework.ensure_external_item_registered(TravelExpansionFramework::ANIL_EXPANSION_ID, item)
      if imported && defined?(GameData::Item) && (GameData::Item.try_get(imported) rescue nil)
        return send(:pbReceiveItem, imported) if respond_to?(:pbReceiveItem, true)
        return tef_anil_call_global_method(:pbReceiveItem, imported)
      end
    end
    TravelExpansionFramework.anil_remember_value("key_item_#{raw}", true) if tef_anil_active? && !raw.empty?
    return true
  rescue
    return true
  end

  def getItemRandomFromPokeball(*_args)
    item = [:POTION, :POKEBALL, :ANTIDOTE, :REPEL].find { |candidate| GameData::Item.try_get(candidate) rescue false }
    picked_up = false
    if item
      picked_up = pbItemBall(item, 1) if respond_to?(:pbItemBall, true)
      picked_up = tef_anil_call_global_method(:pbItemBall, item, 1) if !picked_up
      if !picked_up
        picked_up = send(:pbReceiveItem, item) if respond_to?(:pbReceiveItem, true)
        picked_up = tef_anil_call_global_method(:pbReceiveItem, item) if !picked_up
      end
    end
    setTempSwitchOn("A") if picked_up && respond_to?(:setTempSwitchOn)
    return picked_up ? true : false
  rescue
    setTempSwitchOn("A") rescue nil
    return true
  end

  def combate_importante_legendario(species, level = 50, *_args)
    resolved = TravelExpansionFramework.anil_valid_species(species) || species
    return pbWildBattle(resolved, level) if respond_to?(:pbWildBattle)
    return Kernel.pbWildBattle(resolved, level) if defined?(Kernel) && Kernel.respond_to?(:pbWildBattle)
    return true
  rescue
    return true
  end

  def registrar_legendario_derrotado(species = nil, *_args)
    TravelExpansionFramework.anil_remember_value("legendary_defeated_#{species}", true) if tef_anil_active?
    return true
  rescue
    return true
  end

  def reiniciar_legendario?(species = nil, *_args)
    return false if !tef_anil_active?
    return TravelExpansionFramework.anil_value("legendary_reset_#{species}", false) ? true : false
  rescue
    return false
  end

  def raid_battle(type = nil, *_args)
    TravelExpansionFramework.anil_remember_value("last_alpha_den_type", type.to_s) if tef_anil_active?
    return true
  rescue
    return true
  end

  def contar_primeros_pokemon(limit = nil)
    return 0 if !defined?($Trainer) || !$Trainer
    count = 0
    dex = $Trainer.pokedex if $Trainer.respond_to?(:pokedex)
    return 0 if !dex
    max = TravelExpansionFramework.integer(limit, 0)
    if dex.respond_to?(:seen?)
      (1..max).each { |id| count += 1 if dex.seen?(id) rescue false }
    end
    return count
  rescue
    return 0
  end

  def give_vial(*_args)
    [:POKEVIAL, :POTION].each do |item|
      next if !(GameData::Item.try_get(item) rescue nil)
      return pbReceiveItem(item) if respond_to?(:pbReceiveItem)
    end
    return true
  rescue
    return true
  end

  def change_pokemon_form(pokemon = nil, form = 0, *_args)
    target = pokemon || ($game_variables[1] rescue nil)
    if target && target.respond_to?(:form=)
      target.form = TravelExpansionFramework.integer(form, 0)
      target.calc_stats if target.respond_to?(:calc_stats)
    end
    return true
  rescue
    return true
  end

  def combate_torre_batalla(*_args)
    return true
  end

  def generar_entrenador_torre_batalla(*_args)
    return true
  end

  alias tef_anil_original_pbTrainerIntro pbTrainerIntro if method_defined?(:pbTrainerIntro) && !method_defined?(:tef_anil_original_pbTrainerIntro)

  def pbTrainerIntro(symbol)
    if tef_anil_active?
      TravelExpansionFramework.external_trainer_catalog(TravelExpansionFramework::ANIL_EXPANSION_ID) if TravelExpansionFramework.respond_to?(:external_trainer_catalog)
      data = TravelExpansionFramework.imported_trainer_type_data(symbol) if TravelExpansionFramework.respond_to?(:imported_trainer_type_data)
      runtime = data[:runtime_id] if data.is_a?(Hash)
      if runtime && respond_to?(:tef_anil_original_pbTrainerIntro, true)
        return tef_anil_original_pbTrainerIntro(runtime) rescue true
      end
      pbGlobalLock if respond_to?(:pbGlobalLock)
      return true
    end
    return tef_anil_original_pbTrainerIntro(symbol) if respond_to?(:tef_anil_original_pbTrainerIntro, true)
    return true
  rescue
    return true
  end

  def pbEncounter(*_args)
    return true
  end if !method_defined?(:pbEncounter)

  def pbChooseFossil(*args)
    return true
  end if !method_defined?(:pbChooseFossil)

  def reviving_fossil(*args)
    return true
  end if !method_defined?(:reviving_fossil)

  def pbChoosePokeball(*args)
    return true
  end if !method_defined?(:pbChoosePokeball)

  def pbBattlePointShop(*args)
    return true
  end if !method_defined?(:pbBattlePointShop)

  def pbStartTradePC(*args)
    return true
  end if !method_defined?(:pbStartTradePC)

  def pbChoosePokemonForTradePC(*args)
    return true
  end if !method_defined?(:pbChoosePokemonForTradePC)

  def pbLearnEggMoveScreen(*args)
    return true
  end if !method_defined?(:pbLearnEggMoveScreen)
end if defined?(Interpreter)
