# Barebones version of PIF class to maintain save compatibility with KIF
class PIFSprite
  attr_accessor :type
  attr_accessor :head_id
  attr_accessor :body_id
  attr_accessor :alt_letter
  attr_accessor :local_path

  #types:
  # :AUTOGEN, :CUSTOM, :BASE
  def initialize(type, head_id, body_id, alt_letter = "")
    @type = type
    @head_id = head_id
    @body_id = body_id
    @alt_letter = alt_letter
    @local_path = nil
  end

  def base?
    @type == :BASE
  end

  def custom?
    @type == :CUSTOM
  end

  def autogen?
    @type == :AUTOGEN
  end

  def to_filename
    suffix = @alt_letter.to_s
    return "#{@head_id}#{suffix}.png" if base?
    return "#{@head_id}.#{@body_id}#{suffix}.png"
  end

  def dump_info
    echoln("PIFSprite(type=#{@type}, head_id=#{@head_id}, body_id=#{@body_id}, alt_letter=#{@alt_letter}, local_path=#{@local_path})")
  end
end

def pif_sprite_from_spritename(spritename, autogen = false)
  spritename = spritename.split(".png")[0] #remove the extension
  if spritename =~ /^(\d+)\.(\d+)([a-zA-Z]*)$/ # Two numbers with optional letters
    type = :CUSTOM
    head_id = $1.to_i # Head (e.g., "1" in "1.2.png")
    body_id = $2.to_i # Body (e.g., "2" in "1.2.png")
    alt_letter = $3 # Optional trailing letter (e.g., "a" in "1.2a.png")

  elsif spritename =~ /^(\d+)([a-zA-Z]*)$/ # One number with optional letters
    type = :BASE
    head_id = $1.to_i # Head (e.g., "1" in "1.png")
    alt_letter = $2 # Optional trailing letter (e.g., "a" in "1a.png")
  else
    echoln "Invalid sprite format: #{spritename}"
    return nil
  end
  type = :AUTOGEN if autogen

  pif_sprite = PIFSprite.new(type, head_id, body_id, alt_letter)
  pif_sprite.local_path = check_for_local_sprite(pif_sprite)
  
  return pif_sprite
end

def check_for_local_sprite(pif_sprite)
  return pif_sprite.local_path if pif_sprite.local_path
  if pif_sprite.type == :BASE
    sprite_path = "#{Settings::CUSTOM_BASE_SPRITES_FOLDER}#{pif_sprite.head_id}#{pif_sprite.alt_letter}.png"
  else
    sprite_path = "#{Settings::CUSTOM_BATTLERS_FOLDER_INDEXED}#{pif_sprite.head_id}/#{pif_sprite.head_id}.#{pif_sprite.body_id}#{pif_sprite.alt_letter}.png"
  end
  return pbResolveBitmap(sprite_path)
end

class BattleSpriteLoader
  def load_base_sprite(species)
    species_id = normalize_species_id(species)
    load_bitmap_from_path(get_unfused_sprite_path(species_id))
  end

  def load_fusion_sprite(head_id, body_id, spriteform_body = nil, spriteform_head = nil)
    head_num = normalize_species_id(head_id)
    body_num = normalize_species_id(body_id)
    load_bitmap_from_path(get_fusion_sprite_path(head_num, body_num, spriteform_body, spriteform_head))
  end

  def get_pif_sprite_from_species(species)
    species_id = normalize_species_id(species)
    if fusion_species_id?(species_id)
      body_id = getBodyID(species_id)
      head_id = getHeadID(species_id, body_id)
      path = get_fusion_sprite_path(head_id, body_id)
      pif_sprite = PIFSprite.new(custom_fusion_path?(path) ? :CUSTOM : :AUTOGEN, head_id, body_id, extract_alt_letter(path))
      pif_sprite.local_path = pbResolveBitmap(path) || path
      return pif_sprite
    end
    path = get_unfused_sprite_path(species_id)
    pif_sprite = PIFSprite.new(:BASE, species_id, nil, extract_alt_letter(path))
    pif_sprite.local_path = pbResolveBitmap(path) || path
    return pif_sprite
  end

  def load_pif_sprite(pif_sprite)
    load_pif_sprite_directly(pif_sprite)
  end

  def load_pif_sprite_directly(pif_sprite)
    return nil if !pif_sprite
    return load_bitmap_from_path(pif_sprite) if pif_sprite.is_a?(String)
    load_bitmap_from_path(sprite_path_for_pif_sprite(pif_sprite))
  end

  def preload(pif_sprite)
    bitmap = load_pif_sprite(pif_sprite)
    bitmap.dispose if bitmap && bitmap.respond_to?(:dispose)
  rescue
  end

  def preload_sprite_from_pokemon(pokemon)
    return if !pokemon
    bitmap = if pokemon.respond_to?(:isFusion?) && pokemon.isFusion?
      load_fusion_sprite(pokemon.head_id, pokemon.body_id, pokemon.spriteform_body, pokemon.spriteform_head)
    else
      load_base_sprite(pokemon.id_number)
    end
    bitmap.dispose if bitmap && bitmap.respond_to?(:dispose)
  rescue
  end

  def registerSpriteSubstitution(pif_sprite)
    return if !pif_sprite || !$PokemonGlobal
    $PokemonGlobal.alt_sprite_substitutions = {} if !$PokemonGlobal.alt_sprite_substitutions
    key = pif_sprite.base? ? pif_sprite.head_id.to_s : getSpeciesIdForFusion(pif_sprite.head_id, pif_sprite.body_id).to_s
    path = sprite_path_for_pif_sprite(pif_sprite)
    $PokemonGlobal.alt_sprite_substitutions[key] = path if path
  rescue
  end

  private

  def normalize_species_id(species)
    return species.id_number if species.respond_to?(:id_number)
    return species.id_number if species.is_a?(GameData::Species) rescue false
    return species if species.is_a?(Integer)
    return getDexNumberForSpecies(species)
  end

  def fusion_species_id?(species_id)
    return isFusion(species_id) if defined?(method(:isFusion)) rescue false
    species_id.to_i > Settings::NB_POKEMON
  end

  def custom_fusion_path?(path)
    normalized_path = path.to_s.tr("\\", "/")
    normalized_custom = Settings::CUSTOM_BATTLERS_FOLDER_INDEXED.to_s.tr("\\", "/")
    normalized_path.start_with?(normalized_custom)
  end

  def extract_alt_letter(path)
    basename = File.basename(path.to_s, ".png")
    match = basename.match(/\A\d+(?:\.\d+)?([A-Za-z]+)\z/)
    return "" if !match
    match[1].to_s
  end

  def sprite_path_for_pif_sprite(pif_sprite)
    return nil if !pif_sprite
    return pif_sprite.local_path if pif_sprite.respond_to?(:local_path) && pif_sprite.local_path && pbResolveBitmap(pif_sprite.local_path)
    if pif_sprite.base?
      preferred = "#{Settings::CUSTOM_BASE_SPRITES_FOLDER}#{pif_sprite.head_id}#{pif_sprite.alt_letter}.png"
      return preferred if pbResolveBitmap(preferred)
      return get_unfused_sprite_path(pif_sprite.head_id)
    end
    preferred = "#{Settings::CUSTOM_BATTLERS_FOLDER_INDEXED}#{pif_sprite.head_id}/#{pif_sprite.to_filename}"
    return preferred if pbResolveBitmap(preferred)
    return get_fusion_sprite_path(pif_sprite.head_id, pif_sprite.body_id)
  end

  def load_bitmap_from_path(path)
    resolved = pbResolveBitmap(path) || path
    return AnimatedBitmap.new(resolved) if resolved
    return AnimatedBitmap.new(Settings::DEFAULT_SPRITE_PATH)
  end
end
