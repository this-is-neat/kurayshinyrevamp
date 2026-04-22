#===============================================================================
# Pokémon icons
#===============================================================================
class PokemonBoxIcon < IconSprite
  attr_accessor :pokemon

  def initialize(pokemon, viewport = nil)
    @logical_x = 0
    @logical_y = 0
    @icon_offset_x = 0
    @icon_offset_y = 0
    @heldox = 0
    @heldoy = 0
    super(0, 0, viewport)
    @pokemon = pokemon
    @release = Interpolator.new
    @startRelease = false
    refresh
  end

  def releasing?
    return @release.tweening?
  end

  def useRegularIcon(species)
    dexNum = getDexNumberForSpecies(species)
    return true if dexNum <= Settings::NB_POKEMON
    return false if $game_variables == nil
    return true if $game_variables[VAR_FUSION_ICON_STYLE] != 0
    bitmapFileName = sprintf("Graphics/Icons/icon%03d", dexNum)
    return true if pbResolveBitmap(bitmapFileName)
    return false
  end

  def createRBGableShiny(pokemon)
    result_icon = AnimatedBitmap.new(GameData::Species.icon_filename_from_pokemon(pokemon))
    if pokemon.shiny? && $PokemonSystem.shiny_icons_kuray == 1 && access_deprecated_kurayshiny() != 1
      result_icon.pbGiveFinaleColor(pokemon.shinyR?, pokemon.shinyG?, pokemon.shinyB?, pokemon.shinyValue?, pokemon.shinyKRS?, pokemon.shinyOmega?)
    end
    return result_icon
  end

  def createFusionIcon(species, spriteform_head = nil, spriteform_body = nil)
    bodyPoke_number = getBodyID(species)
    headPoke_number = getHeadID(species, bodyPoke_number)

    bodyPoke = GameData::Species.get(bodyPoke_number).species
    headPoke = GameData::Species.get(headPoke_number).species

    icon1 = AnimatedBitmap.new(GameData::Species.icon_filename(headPoke, spriteform_head))
    icon2 = AnimatedBitmap.new(GameData::Species.icon_filename(bodyPoke, spriteform_body))

    directory_name = "Graphics/Pokemon/FusionIcons"
    checkDirectory(directory_name) if respond_to?(:checkDirectory)
    dexNum = getDexNumberForSpecies(species)
    dexNum = GameData::Species.get(dexNum).id_number if dexNum.is_a?(Symbol)

    customiconname = customIcons(dexNum) if respond_to?(:customIcons)
    if customiconname
      result_icon = AnimatedBitmap.new(customiconname)
    else
      ensureFusionIconExists
      bitmapFileName = sprintf("Graphics/Pokemon/FusionIcons/icon%03d", dexNum)
      headPokeFileName = GameData::Species.icon_filename(headPoke, spriteform_head)
      bitmapPath = sprintf("%s.png", bitmapFileName)
      generated_new_icon = generateFusionIcon(headPokeFileName, bitmapPath)
      result_icon = generated_new_icon ? AnimatedBitmap.new(bitmapPath) : icon1

      for i in 0..icon1.width - 1
        for j in ((icon1.height / 2) + Settings::FUSION_ICON_SPRITE_OFFSET)..icon1.height - 1
          temp = icon2.bitmap.get_pixel(i, j)
          result_icon.bitmap.set_pixel(i, j, temp)
        end
      end
    end

    if @pokemon && @pokemon.shiny? && $PokemonSystem.shiny_icons_kuray == 1 && access_deprecated_kurayshiny() != 1
      result_icon.pbGiveFinaleColor(@pokemon.shinyR?, @pokemon.shinyG?, @pokemon.shinyB?, @pokemon.shinyValue?, @pokemon.shinyKRS?, @pokemon.shinyOmega?)
    end
    return result_icon
  end

  def release
    self.ox = self.src_rect.width / 2 # 32
    self.oy = self.src_rect.height / 2 # 32
    self.x += self.src_rect.width / 2 # 32
    self.y += self.src_rect.height / 2 # 32
    @release.tween(self, [
      [Interpolator::ZOOM_X, 0],
      [Interpolator::ZOOM_Y, 0],
      [Interpolator::OPACITY, 0]
    ], 100)
    @startRelease = true
  end

  def refresh(fusion_enabled = true)
    return if !@pokemon
    if self.use_big_icon?
      if $PokemonSystem.shiny_icons_kuray == 1
        if @pokemon.kuraycustomfile? == nil
          tempBitmap = GameData::Species.sprite_bitmap_from_pokemon(@pokemon)
        else
          if pbResolveBitmap(@pokemon.kuraycustomfile?) && !@pokemon.egg? && (!$PokemonSystem.kurayindividcustomsprite || $PokemonSystem.kurayindividcustomsprite == 0)
            filename = @pokemon.kuraycustomfile?
            tempBitmap = (filename) ? AnimatedBitmap.new(filename).recognizeDims() : nil
            if @pokemon.shiny? && tempBitmap
              tempBitmap.pbGiveFinaleColor(@pokemon.shinyR?, @pokemon.shinyG?, @pokemon.shinyB?, @pokemon.shinyValue?, @pokemon.shinyKRS?, @pokemon.shinyOmega?)
            end
          else
            tempBitmap = GameData::Species.sprite_bitmap_from_pokemon(@pokemon)
          end
        end
      else
        if @pokemon.kuraycustomfile? == nil
          tempBitmap = GameData::Species.sprite_bitmap_from_pokemon(@pokemon, false, nil, false)
        else
          if pbResolveBitmap(@pokemon.kuraycustomfile?) && !@pokemon.egg? && (!$PokemonSystem.kurayindividcustomsprite || $PokemonSystem.kurayindividcustomsprite == 0)
            filename = @pokemon.kuraycustomfile?
            tempBitmap = (filename) ? AnimatedBitmap.new(filename).recognizeDims() : nil
          else
            tempBitmap = GameData::Species.sprite_bitmap_from_pokemon(@pokemon, false, nil, false)
          end
        end
      end
      if @pokemon.egg?
        tempBitmap.scale_bitmap(1.0 / 2.0)
        @icon_offset_x = -8
        @icon_offset_y = -8
      else
        tempBitmap.scale_bitmap(1.0 / 3.0)
        @icon_offset_x = -16
        @icon_offset_y = -16
      end
      self.setBitmapDirectly(tempBitmap)
    elsif @pokemon.egg?
      self.setBitmap(GameData::Species.icon_filename_from_pokemon(@pokemon))
    elsif useRegularIcon(@pokemon.species)
      self.setBitmapDirectly(createRBGableShiny(@pokemon))
    elsif useTripleFusionIcon(@pokemon.species)
      self.setBitmap(pbResolveBitmap(sprintf("Graphics/Icons/iconDNA")))
    else
      self.setBitmapDirectly(createFusionIcon(@pokemon.species, @pokemon.spriteform_head, @pokemon.spriteform_body))
      if fusion_enabled
        self.visible = true
      else
        self.visible = false
      end
    end
    self.src_rect = Rect.new(0, 0, self.bitmap.height, self.bitmap.height)
  end

  def update
    super
    @release.update
    self.color = Color.new(0, 0, 0, 0)
    dispose if @startRelease && !releasing?
  end
end









