#===============================================================================
# Trainer class for the player
#===============================================================================
class Player < Trainer
  attr_accessor :trainer_type
  attr_accessor :name
  attr_accessor :id
  attr_accessor :language
  attr_accessor :party
  attr_accessor :quests
  attr_accessor :quests_repaired
  attr_accessor :sprite_override
  attr_accessor :custom_appearance
  attr_accessor :quest_points
  attr_accessor :secretBase_uuid
  attr_accessor :secretBase
  attr_accessor :owned_decorations
  attr_accessor :last_time_saved
  attr_accessor :save_slot
  attr_accessor :autosave_steps

  # @return [Integer] the character ID of the player
  attr_accessor :character_ID
  # @return [Integer] the player's outfit
  attr_accessor :outfit #old - unused

  attr_accessor :skin_tone
  attr_accessor :clothes
  attr_accessor :hat
  attr_accessor :hat2

  attr_accessor :hair
  attr_accessor :hair_color
  attr_accessor :hat_color
  attr_accessor :hat2_color

  attr_accessor :clothes_color
  attr_accessor :unlocked_clothes
  attr_accessor :unlocked_hats
  attr_accessor :unlocked_hairstyles
  attr_accessor :unlocked_card_backgrounds

  attr_accessor :dyed_hats
  attr_accessor :dyed_clothes

  attr_accessor :favorite_hat
  attr_accessor :favorite_hat2

  attr_accessor :favorite_clothes

  attr_accessor :last_worn_outfit
  attr_accessor :last_worn_hat
  attr_accessor :last_worn_hat2

  attr_accessor :surfing_pokemon


  attr_accessor :card_background
  attr_accessor :unlocked_card_backgrounds

  attr_accessor :seen_qmarks_sprite


  # @return [Array<Boolean>] the player's Gym Badges (true if owned)
  attr_accessor :badges
  # @return [Integer] the player's money
  attr_reader   :money
  # @return [Integer] the player's Game Corner coins
  attr_reader   :coins
  # @return [Integer] the player's battle points
  attr_reader   :battle_points
  # @return [Integer] the player's soot
  attr_reader   :soot
  # @return [Pokedex] the player's Pokédex
  attr_reader   :pokedex
  # @return [Boolean] whether the Pokédex has been obtained
  attr_accessor :has_pokedex
  # @return [Boolean] whether the Pokégear has been obtained
  attr_accessor :has_pokegear
  # @return [Boolean] whether the player has running shoes (i.e. can run)
  attr_accessor :has_running_shoes
  # @return [Boolean] whether the creator of the Pokémon Storage System has been seen
  attr_accessor :seen_storage_creator
  # @return [Boolean] whether Mystery Gift can be used from the load screen
  attr_accessor :mystery_gift_unlocked
  # @return [Array<Array>] downloaded Mystery Gift data
  attr_accessor :mystery_gifts
  attr_accessor :beat_league
  attr_accessor :new_game_plus_unlocked
  attr_accessor :new_game_plus

  def full_name
    return "#{trainer_type_name} #{@name}"
  end

  def public_ID(id = nil)
    trainer_id = id || @id || 0
    return trainer_id & 0xFFFF
  end

  def secret_ID(id = nil)
    trainer_id = id || @id || 0
    return trainer_id >> 16
  end

  def make_foreign_ID
    loop do
      foreign_id = rand(2**16) | (rand(2**16) << 16)
      return foreign_id if foreign_id != @id
    end
  end

  def trainer_type_name
    return GameData::TrainerType.get(trainer_type).name
  end

  def base_money
    return GameData::TrainerType.get(trainer_type).base_money
  end

  def gender
    return GameData::TrainerType.get(trainer_type).gender if @trainer_type
    return GENDER_MALE if male?
    return GENDER_FEMALE if female?
    return 2
  end

  def skill_level
    return 100 if $game_switches[SWITCH_GAME_DIFFICULTY_HARD]
    return GameData::TrainerType.get(trainer_type).skill_level
  end

  def skill_code
    return GameData::TrainerType.get(trainer_type).skill_code
  end

  def has_skill_code?(code)
    current_skill_code = skill_code
    return current_skill_code && current_skill_code != "" && current_skill_code[/#{code}/]
  end

  def badge_count
    return (@badges || []).count(true)
  end

  def party
    @party ||= []
    return @party
  end

  def party=(value)
    @party = value || []
  end

  def pokemon_party
    return party.find_all { |pokemon| pokemon && !pokemon.egg? }
  end

  def able_party
    return party.find_all { |pokemon| pokemon && !pokemon.egg? && !pokemon.fainted? }
  end

  def party_count
    return party.length
  end

  def pokemon_count
    return pokemon_party.length
  end

  def able_pokemon_count
    return able_party.length
  end
  
  # Compatibility: allow $Trainer.pokemonCount for event scripts
  def pokemonCount
    pokemon_count
  end

  def highest_level_pokemon_in_party
    max_level = 0
    party.each do |pokemon|
      next if !pokemon || !pokemon.respond_to?(:level)
      max_level = pokemon.level if pokemon.level > max_level
    end
    return max_level
  end

  def party_full?
    return party_count >= Settings::MAX_PARTY_SIZE
  end

  def all_fainted?
    return able_pokemon_count == 0
  end

  def first_party
    return party[0]
  end

  def first_pokemon
    return pokemon_party[0]
  end

  def first_able_pokemon
    return able_party[0]
  end

  def last_party
    return (party.length > 0) ? party[party.length - 1] : nil
  end

  def last_pokemon
    filtered_party = pokemon_party
    return (filtered_party.length > 0) ? filtered_party[filtered_party.length - 1] : nil
  end

  def last_able_pokemon
    filtered_party = able_party
    return (filtered_party.length > 0) ? filtered_party[filtered_party.length - 1] : nil
  end

  def has_other_able_pokemon?(index)
    party.each_with_index { |pokemon, i| return true if i != index && pokemon&.able? }
    return false
  end

  def has_species?(species, form = -1)
    return pokemon_party.any? { |pokemon| pokemon && pokemon.isSpecies?(species) && (form < 0 || pokemon.form == form) }
  end

  def has_species_or_fusion?(species, form = -1)
    return pokemon_party.any? { |pokemon| (pokemon && pokemon.isSpecies?(species) && (form < 0 || pokemon.form == form)) || pokemon&.isFusionOf(species) }
  end

  def has_fateful_species?(species)
    return pokemon_party.any? { |pokemon| pokemon && pokemon.isSpecies?(species) && pokemon.obtain_method == 4 }
  end

  def has_pokemon_of_type?(type)
    return false if !GameData::Type.exists?(type)
    type = GameData::Type.get(type).id
    return pokemon_party.any? { |pokemon| pokemon && pokemon.hasType?(type) }
  end

  def get_pokemon_with_move(move)
    pokemon_party.each { |pokemon| return pokemon if pokemon.hasMove?(move) }
    return nil
  end

  def heal_party
    party.each { |pokemon| pokemon.heal if pokemon }
  end

  def lowest_difficulty
    @lowest_difficulty = 1 if @lowest_difficulty.nil?
    return @lowest_difficulty
  end

  def lowest_difficulty=(value)
    @lowest_difficulty = value
  end

  def selected_difficulty
    @selected_difficulty = lowest_difficulty if @selected_difficulty.nil?
    return @selected_difficulty
  end

  def selected_difficulty=(value)
    @selected_difficulty = value
  end

  def game_mode
    @game_mode = 0 if @game_mode.nil?
    return @game_mode
  end

  def game_mode=(value)
    @game_mode = value
  end

  def male?
    return true if @trainer_type && (GameData::TrainerType.get(@trainer_type).male? rescue false)
    return pbGet(VAR_TRAINER_GENDER) == GENDER_MALE rescue false
  end

  def female?
    return true if @trainer_type && (GameData::TrainerType.get(@trainer_type).female? rescue false)
    return pbGet(VAR_TRAINER_GENDER) == GENDER_FEMALE rescue false
  end

  def trainer_type
    if @trainer_type.is_a?(Integer)
      @trainer_type = GameData::Metadata.get_player(@character_ID || 0)[0]
    end
    return @trainer_type
  end

  # Sets the player's money. It can not exceed {Settings::MAX_MONEY}.
  # @param value [Integer] new money value
  def money=(value)
    validate value => Integer
    @money = value.clamp(0, Settings::MAX_MONEY)
  end

  def last_worn_outfit
    if !@last_worn_outfit
      if pbGet(VAR_TRAINER_GENDER) == GENDER_MALE
        @last_worn_outfit = DEFAULT_OUTFIT_MALE
      else
        @last_worn_outfit = DEFAULT_OUTFIT_FEMALE
      end
    end
    return @last_worn_outfit
  end


  def last_worn_hat(is_secondary=false)
    return is_secondary ? @last_worn_hat2 : @last_worn_hat
  end


  def set_last_worn_hat(value, is_secondary=false)
    if is_secondary
      @last_worn_hat = value
    else
      @last_worn_hat = value
    end
  end


  def last_worn_hat2
    return @last_worn_hat2
  end

  # Sets the player's coins amount. It can not exceed {Settings::MAX_COINS}.
  # @param value [Integer] new coins value
  def coins=(value)
    validate value => Integer
    @coins = value.clamp(0, Settings::MAX_COINS)
  end

  def outfit=(value)
    @outfit=value
  end

  def favorite_hat(is_secondary=false)
    return is_secondary ?  @favorite_hat2 : @favorite_hat
  end


  #todo change to set_favorite_hat(value,is_secondary=false)
  def set_favorite_hat(value,is_secondary=false)
    if is_secondary
      @favorite_hat=value
    else
      @favorite_hat2=value
    end
  end

  def hat_color(is_secondary=false)
    return is_secondary ? @hat2_color : @hat_color
  end
  def hat(is_secondary=false)
    return is_secondary ? @hat2 : @hat
  end

  def set_hat(value, is_secondary=false)
    if value.is_a?(Symbol)
      value = HATS[value].id
    end
    if is_secondary
      @hat2= value
    else
      @hat=value
    end
    refreshPlayerOutfit()
  end


  #todo : refactor to always use set_hat instead
  def hat=(value)
    if value.is_a?(Symbol)
      value = HATS[value].id
    end
    @hat=value
    refreshPlayerOutfit()
  end

  #todo : refactor to always use set_hat instead
  def hat2=(value)
    if value.is_a?(Symbol)
      value = HATS[value].id
    end
    @hat2=value
    refreshPlayerOutfit()
  end

  def hair=(value)
    if value.is_a?(Symbol)
      value = HAIRSTYLES[value].id
    end
    @hair=value
    refreshPlayerOutfit()
  end

  def clothes=(value)
    if value.is_a?(Symbol)
      value = OUTFITS[value].id
    end
    @clothes=value
    refreshPlayerOutfit()
  end

  def clothes_color=(value)
    @clothes_color=value
    $Trainer.dyed_clothes= {} if !$Trainer.dyed_clothes
    $Trainer.dyed_clothes[@clothes] = value if value
    refreshPlayerOutfit()
  end

  def set_hat_color(value, is_secondary=false)
    if is_secondary
      @hat2_color=value
    else
      @hat_color=value
    end
    $Trainer.dyed_hats= {} if !$Trainer.dyed_hats
    worn_hat = is_secondary ? @hat2 : @hat
    $Trainer.dyed_hats[worn_hat] = value if value
    refreshPlayerOutfit()
  end


  def hat_color=(value)
    @hat_color=value
    $Trainer.dyed_hats= {} if !$Trainer.dyed_hats
    worn_hat = @hat
    $Trainer.dyed_hats[worn_hat] = value if value
    refreshPlayerOutfit()
  end

  def hat2_color=(value)
    @hat2_color=value
    $Trainer.dyed_hats= {} if !$Trainer.dyed_hats
    worn_hat = @hat2
    $Trainer.dyed_hats[worn_hat] = value if value
    refreshPlayerOutfit()
  end

  def unlock_clothes(outfitID,silent=false)
    update_global_clothes_list()
    outfit = $PokemonGlobal.clothes_data[outfitID]
    @unlocked_clothes = [] if !@unlocked_clothes
    @unlocked_clothes << outfitID if !@unlocked_clothes.include?(outfitID)

    if !silent
      filename = getTrainerSpriteOutfitFilename(outfitID)
      name= outfit ? outfit.name : outfitID
      unlock_outfit_animation(filename,name)
    end
  end

  def unlock_hat(hatID,silent=false)
    update_global_hats_list()

    hat = $PokemonGlobal.hats_data[hatID]
    @unlocked_hats = [] if !@unlocked_hats
    @unlocked_hats << hatID if !@unlocked_hats.include?(hatID)


    if !silent
      filename = getTrainerSpriteHatFilename(hatID)
      name= hat ? hat.name : hatID
      unlock_outfit_animation(filename,name)
    end
  end

  def unlock_hair(hairID,silent=false)
    update_global_hairstyles_list()

    hairstyle = $PokemonGlobal.hairstyles_data[hairID]
    if hairID.is_a?(Symbol)
      hairID = HAIRSTYLES[hairID].id
    end
    @unlocked_hairstyles = [] if !@unlocked_hairstyles
    @unlocked_hairstyles << hairID if !@unlocked_hairstyles.include?(hairID)

    if !silent
      filename = getTrainerSpriteHairFilename("2_" + hairID)
      name= hairstyle ? hairstyle.name : hairID
      unlock_outfit_animation(filename,name)
    end
  end

  def unlock_outfit_animation(filepath,name,color=2)
    outfit_preview = PictureWindow.new(filepath)
    outfit_preview.x = Graphics.width/4
    musicEffect= "Key item get"
    pbMessage(_INTL("{1} obtained \\C[{2}]{3}\\C[0]!\\me[{4}]",$Trainer.name,color,name,musicEffect))
    outfit_preview.dispose
  end

  def surfing_pokemon=(species)
    @surfing_pokemon = species
  end


  def skin_tone=(value)
    @skin_tone=value
    $scene.reset_player_sprite
    #$scene.spritesetGlobal.playersprite.updateCharacterBitmap
  end

  def beat_league=(value)
    @beat_league = value
  end
  def new_game_plus_unlocked=(value)
    @new_game_plus_unlocked = value
  end
  # Sets the player's Battle Points amount. It can not exceed
  # {Settings::MAX_BATTLE_POINTS}.
  # @param value [Integer] new Battle Points value
  def battle_points=(value)
    validate value => Integer
    @battle_points = value.clamp(0, Settings::MAX_BATTLE_POINTS)
  end

  # Sets the player's soot amount. It can not exceed {Settings::MAX_SOOT}.
  # @param value [Integer] new soot value
  def soot=(value)
    validate value => Integer
    @soot = value.clamp(0, Settings::MAX_SOOT)
  end

  # @return [Integer] the number of Gym Badges owned by the player
  def badge_count
    return @badges.count { |badge| badge == true }
  end


  def new_game_plus=(value)
    @new_game_plus = value
  end
  #=============================================================================

  # (see Pokedex#seen?)
  # Shorthand for +self.pokedex.seen?+.
  def seen?(species)
    return @pokedex.seen?(species)
  end

  # (see Pokedex#owned?)
  # Shorthand for +self.pokedex.owned?+.
  def owned?(species)
    return @pokedex.owned?(species)
  end

  def can_change_outfit()
    return false if isOnPinkanIsland()
    return true
  end

  #=============================================================================

  def initialize(name, trainer_type)
    @trainer_type = GameData::TrainerType.get(trainer_type).id
    @name = name
    @id = rand(2 ** 16) | rand(2 ** 16) << 16
    @language = pbGetLanguage
    @party = []
    @sprite_override = nil
    @custom_appearance = nil
    @lowest_difficulty = 2
    @selected_difficulty = 2
    @game_mode = 0
    @quest_points = 0
    @character_ID          = -1
    @outfit                = 0
    @hat                   = 0
    @hat2                  = 0

    @hair                  = 0
    @clothes               = 0
    @hair_color            = 0
    @skin_tone             = 0
    @badges                = [false] * 8
    @money                 = Settings::INITIAL_MONEY
    @coins                 = 0
    @battle_points         = 0
    @soot                  = 0
    @pokedex               = Pokedex.new
    @has_pokedex           = false
    @has_pokegear          = false
    @has_running_shoes     = false
    @seen_storage_creator  = false
    @mystery_gift_unlocked = false
    @mystery_gifts         = []
    @beat_league             =  false
    @new_game_plus_unlocked  =  false
    @new_game_plus         = false
    @surfing_pokemon = nil
    @last_worn_outfit = nil
    @last_worn_hat = nil
    @last_worn_hat2 = nil

    @dyed_hats = {}
    @dyed_clothes = {}

    @favorite_hat = nil
    @favorite_hat2 =nil
    @favorite_clothes = nil

    @card_background = Settings::DEFAULT_TRAINER_CARD_BG
    @unlocked_card_backgrounds = [@card_background]

    @seen_qmarks_sprite = false
  end
end
