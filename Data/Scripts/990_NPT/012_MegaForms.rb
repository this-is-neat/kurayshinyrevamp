#===============================================================================
# Debug logger — writes to Data/Scripts/990_NPT/mega_debug.txt
#===============================================================================
module MegaDebug
  LOG_PATH = "mega_debug.txt"

  def self.clear
    File.open(LOG_PATH, "w") { |f| f.puts "=== Mega Debug Log #{Time.now} ===" }
  end

  def self.log(msg)
    File.open(LOG_PATH, "a") { |f| f.puts "[#{Time.now.strftime('%H:%M:%S')}] #{msg}" }
  rescue
  end
end
MegaDebug.clear

#===============================================================================
# 012_MegaForms.rb
#
# Mega Evolution support for NPT:
#   A. Pokemon#makeMega / makeUnmega use form_simple= instead of the NO-OP form=
#      + mega? / getUnmegaForm fixed (get_species_form ignores form param)
#   B. PokeBattle_Battle#pbCanMegaEvolve? — enables the mechanic (was return false)
#   C. PokeBattle_Battle#pbMegaEvolve — full override with EBDX particle animation
#      ported to run directly on scene sprites (bypasses EBDX wrapper system)
#   D. Mega stone item registrations (Gen 9 Pack / PLZA stones)
#   E. NPT module alias — registers new mega forms + patches existing ones
#      after NPT.register_all_species completes
#   F. Guard pbSpriteSetAnimFrame against disposed bitmaps (mega anim crash fix)
#   G. Fallback MEGAEVOLUTION2 animation (registered but not used — C bypasses it)
#   H. Revert mega forms at end of battle
#===============================================================================

#===============================================================================
# F. Guard pbSpriteSetAnimFrame against disposed bitmaps
#
# When Mega Evolution fires mid-animation the old Pokémon sprite bitmap is
# disposed by the form-change code while the animation player still holds a
# reference to it.  sprite.bitmap is non-nil on a disposed bitmap, so the
# normal nil-check passes and .width raises RGSSError: disposed bitmap.
# Wrapping the method here lets us skip the frame silently instead of crashing.
#===============================================================================
alias _npt_pbSpriteSetAnimFrame pbSpriteSetAnimFrame
def pbSpriteSetAnimFrame(sprite, frame, user = nil, target = nil, inEditor = false)
  return if sprite.bitmap && sprite.bitmap.disposed?
  _npt_pbSpriteSetAnimFrame(sprite, frame, user, target, inEditor)
end

class PokemonBattlerSprite
  alias _npt_pbSetOrigin pbSetOrigin
  def pbSetOrigin
    return if @_iconBitmap && @_iconBitmap.disposed?
    _npt_pbSetOrigin
  end
end

#===============================================================================
# G. KIF-compatible MEGAEVOLUTION2 animation
#
# The stock EBDX MEGAEVOLUTION2 animation uses particle effects and helper
# methods that can crash silently in the KIF static-sprite environment.
# The rescue in withCommonParams eats the error, but databoxes have already
# been hidden, leaving the scene broken.
#
# This replaces it with a simple flash-and-swap that works with KIF sprites.
#===============================================================================
if defined?(EliteBattle) && EliteBattle.respond_to?(:defineCommonAnimation)
  EliteBattle.defineCommonAnimation(:MEGAEVOLUTION2) do
    # Store databox visibility
    isVisible = []
    @battlers.each_with_index do |b, i|
      isVisible.push(false)
      next if !b
      isVisible[i] = @sprites["dataBox_#{i}"] ? @sprites["dataBox_#{i}"].visible : false
      @sprites["dataBox_#{i}"].visible = false if @sprites["dataBox_#{i}"]
    end
    @scene.clearMessageWindow if @scene.respond_to?(:clearMessageWindow)

    pokemon = @battlers[@targetIndex]
    back = @targetIndex % 2 == 0

    # Ensure target sprite is fully visible before animating
    @targetSprite.visible = true
    @targetSprite.opacity = 255
    @targetSprite.tone = Tone.new(0, 0, 0, 0)

    # Flash sprite white
    10.times do
      @targetSprite.tone.all += 25.5 if @targetSprite.tone.all < 255
      @scene.wait(1)
    end

    # Swap to mega form sprite
    if @targetSprite.respond_to?(:setPokemonBitmap)
      @targetSprite.setPokemonBitmap(pokemon, back)
    end

    # Brief white hold
    pbSEPlay("Anim/Refresh") rescue nil
    @scene.wait(4)

    # Fade tone back to normal
    10.times do
      @targetSprite.tone.all -= 25.5 if @targetSprite.tone.all > 0
      @scene.wait(1)
    end
    @targetSprite.tone = Tone.new(0, 0, 0, 0)

    # Play cry
    playBattlerCry(@battlers[@targetIndex]) if respond_to?(:playBattlerCry)
    @scene.wait(8)

    # Restore ALL battler sprites — ensure nothing is left invisible
    @battlers.each_with_index do |b, i|
      next if !b
      sprite = @sprites["pokemon_#{i}"]
      if sprite && !sprite.disposed?
        sprite.visible = true
        sprite.opacity = 255
      end
      @sprites["dataBox_#{i}"].visible = true if @sprites["dataBox_#{i}"]
    end

    @vector.reset if @vector && @vector.respond_to?(:reset)
    @scene.wait(8, true)
  end
end

#===============================================================================
# H. Revert mega forms at end of battle
#
# The core engine only calls makeUnmega on caught Pokémon.  This hook ensures
# all player Pokémon revert to their base form when the battle ends.
#===============================================================================
class PokeBattle_Battle
  alias _npt_pbEndOfBattle pbEndOfBattle
  def pbEndOfBattle
    # Revert all mega-evolved Pokémon before battle cleanup
    eachInTeam(0, 0) do |pkmn, _i|
      next if !pkmn
      pkmn.makeUnmega if pkmn.mega?
      # Revert Zero to Hero fusion transformations
      if pkmn.instance_variable_get(:@zero_hero_transformed)
        pkmn.changeFormSpecies(:PALAFIN_1, :PALAFIN) rescue nil
        pkmn.instance_variable_set(:@zero_hero_transformed, nil)
        pkmn.instance_variable_set(:@zero_to_hero_switched, nil)
      end
      # Revert Schooling fusion transformations
      if pkmn.instance_variable_get(:@schooling_form) == 1
        pkmn.changeFormSpecies(:WISHIWASHI_1, :WISHIWASHI) rescue nil
        pkmn.instance_variable_set(:@schooling_form, nil)
      end
      # Revert Power Construct fusion transformations
      if pkmn.instance_variable_get(:@power_construct_state) == 1
        from = pkmn.instance_variable_get(:@power_construct_from) || :ZYGARDE
        complete = (from == :ZYGARDE_1) ? :ZYGARDE_3 : :ZYGARDE_2
        pkmn.changeFormSpecies(complete, from) rescue nil
        pkmn.instance_variable_set(:@power_construct_state, nil)
        pkmn.instance_variable_set(:@power_construct_from, nil)
      end
    end
    _npt_pbEndOfBattle
  end
end

#===============================================================================
# A. Fix Pokemon#makeMega, makeUnmega, mega?, getUnmegaForm
#
# Two bugs in this engine prevent mega reversion from working:
#   1. Pokemon#form= is a NO-OP (all code commented out).
#      form_simple= writes @form directly and calls calc_stats.
#   2. GameData::Species.get_species_form(species, form) IGNORES the form
#      parameter — it always returns the base form's data.  This means
#      species_data never has mega_stone set for mega forms, so mega?
#      always returns false and getUnmegaForm always returns -1.
#
# Fix: Override mega? and getUnmegaForm to scan GameData::Species directly
# instead of relying on the broken species_data lookup.
#===============================================================================
class Pokemon
  # Track fusion mega state (which component was swapped)
  attr_accessor :fusion_mega_from    # base species symbol swapped out (e.g. :CHARIZARD)
  attr_accessor :fusion_mega_to      # mega species id swapped in   (e.g. :CHARIZARD_1)
  attr_accessor :fusion_pre_mega_dex # dex number before mega (for sprite resolution)

  #---------------------------------------------------------------------------
  # getMegaForm — extended for fusions
  # For fusions: checks if any component species has a matching mega stone/move
  #---------------------------------------------------------------------------
  alias _npt_getMegaForm getMegaForm
  def getMegaForm
    if isFusion?
      GameData::Species.each do |data|
        next unless data.mega_stone || data.mega_move
        next unless data.unmega_form == 0  # only base→mega entries
        next unless isFusionOf(data.species)
        if data.mega_stone && hasItem?(data.mega_stone)
          return data.form
        elsif data.mega_move && hasMove?(data.mega_move)
          return data.form
        end
      end
      return 0
    else
      _npt_getMegaForm
    end
  end

  #---------------------------------------------------------------------------
  # getFusionMegaData — returns { base: :CHARIZARD, mega_id: :CHARIZARD_1 }
  # or nil if this fusion can't mega evolve
  #---------------------------------------------------------------------------
  def getFusionMegaData
    return nil unless isFusion?
    GameData::Species.each do |data|
      next unless data.mega_stone || data.mega_move
      next unless data.unmega_form == 0
      next unless isFusionOf(data.species)
      if (data.mega_stone && hasItem?(data.mega_stone)) ||
         (data.mega_move && hasMove?(data.mega_move))
        return { base: data.species, mega_id: data.id }
      end
    end
    return nil
  end

  #---------------------------------------------------------------------------
  # makeMega / makeUnmega — fusion-aware
  #---------------------------------------------------------------------------
  alias _npt_makeMega makeMega
  def makeMega
    if isFusion?
      mega_data = getFusionMegaData
      if mega_data
        @fusion_mega_from = mega_data[:base]
        @fusion_mega_to   = mega_data[:mega_id]
        # Store pre-mega dex so sprite resolution uses the original fusion ID
        # (after changeFormSpecies, the dex math breaks for sprites)
        @fusion_pre_mega_dex = GameData::Species.get(@species).id_number
        # Set spriteform for the mega-evolving component so sprite_filename
        # resolves to Japeal folders like 3_1/ instead of 1153/
        mega_form = GameData::Species.get(mega_data[:mega_id]).form
        if hasHeadOf?(mega_data[:base])
          @spriteform_head = mega_form
        elsif hasBodyOf?(mega_data[:base])
          @spriteform_body = mega_form
        end
        MegaDebug.log "makeMega fusion: base=#{mega_data[:base]} mega_id=#{mega_data[:mega_id]} form=#{mega_form}"
        MegaDebug.log "  pre_mega_dex=#{@fusion_pre_mega_dex} sf_head=#{@spriteform_head} sf_body=#{@spriteform_body}"
        MegaDebug.log "  hasHead=#{hasHeadOf?(mega_data[:base])} hasBody=#{hasBodyOf?(mega_data[:base])}"
        changeFormSpecies(mega_data[:base], mega_data[:mega_id])
      end
    else
      mega_form = getMegaForm
      self.form_simple = mega_form if mega_form > 0
    end
  end

  alias _npt_makeUnmega makeUnmega
  def makeUnmega
    if isFusion? && @fusion_mega_from && @fusion_mega_to
      changeFormSpecies(@fusion_mega_to, @fusion_mega_from)
      @fusion_mega_from    = nil
      @fusion_mega_to      = nil
      @fusion_pre_mega_dex = nil
      @spriteform_head     = nil
      @spriteform_body     = nil
    elsif !isFusion?
      unmega_form = getUnmegaForm
      self.form_simple = unmega_form if unmega_form >= 0
    end
  end

  #---------------------------------------------------------------------------
  # mega? / getUnmegaForm — fusion-aware
  #---------------------------------------------------------------------------
  alias _npt_mega? mega?
  def mega?
    # Fusion mega: tracked by the swap flag
    return true if isFusion? && @fusion_mega_from
    # Non-fusion: scan GameData directly (species_data is broken)
    GameData::Species.each do |data|
      next if data.species != @species || data.form != @form
      return true if data.mega_stone || data.mega_move
    end
    return false
  end

  alias _npt_getUnmegaForm getUnmegaForm
  def getUnmegaForm
    return 0 if isFusion? && @fusion_mega_from  # signal "can unmega"
    return -1 unless mega?
    GameData::Species.each do |data|
      next if data.species != @species || data.form != @form
      next unless data.mega_stone || data.mega_move
      return data.unmega_form || 0
    end
    return -1
  end
end

#===============================================================================
# A2. Mega Fusion Sprite Resolution Hook
#
# After changeFormSpecies swaps a fusion component to a mega form (e.g.
# VENUSAUR → VENUSAUR_1), the dex math breaks for sprites: head_id becomes
# 1153 (VENUSAUR_1's id_number) instead of 3, and getBodyID/getHeadID
# extract wrong values because head > NB_POKEMON.
#
# This hook detects mega fusions (via fusion_pre_mega_dex) and resolves
# sprites using the original dex number + spriteform, mapping to Japeal
# folder format (e.g. 3_1/3_1.970.png for Mega Venusaur + Finizen).
#
# NPT re-registers some Pokemon with new id_numbers (e.g. Emboar 500→611)
# but Japeal sprite folders still use the original dex (500_1/ not 611_1/).
# When the NPT-id-based path fails, we look up the original dex from the
# species.dat entries that are still in GameData::Species::DATA.
#===============================================================================
module GameData
  class Species
    class << self
      alias _npt_mega_sprite_bitmap_from_pokemon sprite_bitmap_from_pokemon
    end

    # Find the original (Japeal/species.dat) dex number for a species.
    # When NPT re-registers a species with a new id_number, the old
    # DATA[original_id] entry remains in the hash. This scans for it.
    @@_npt_japeal_dex_cache = {}
    def self._npt_japeal_dex(species_sym)
      return @@_npt_japeal_dex_cache[species_sym] if @@_npt_japeal_dex_cache.key?(species_sym)
      current_id = self.get(species_sym).id_number rescue nil
      return current_id unless current_id
      self::DATA.each do |key, data|
        next unless key.is_a?(Integer)
        next if key == current_id
        next unless data.respond_to?(:species) && data.species == species_sym
        next unless data.respond_to?(:form) && data.form == 0
        # Found the original species.dat entry with a different id_number
        MegaDebug.log "  japeal_dex: #{species_sym} NPT=#{current_id} original=#{key}"
        @@_npt_japeal_dex_cache[species_sym] = key
        return key
      end
      @@_npt_japeal_dex_cache[species_sym] = current_id
      current_id
    end

    def self.sprite_bitmap_from_pokemon(pkmn, back = false, species = nil, makeShiny = true)
      # Only intercept for mega-evolved fusions with stored pre-mega dex
      if pkmn.respond_to?(:fusion_pre_mega_dex) && pkmn.fusion_pre_mega_dex
        dex = pkmn.fusion_pre_mega_dex
        sf_body = pkmn.spriteform_body
        sf_head = pkmn.spriteform_head
        mega_from = pkmn.fusion_mega_from

        MegaDebug.log "sprite_bitmap_from_pokemon: dex=#{dex} sf_body=#{sf_body} sf_head=#{sf_head} mega_from=#{mega_from}"

        # Try 1: sprite_filename with NPT id-based dex + spriteform
        filename = self.sprite_filename(dex, sf_body, sf_head)
        MegaDebug.log "  NPT path: #{filename.inspect}"

        # Try 2: If NPT path returned the default/missing sprite,
        # rebuild the fusion dex using the Japeal (species.dat) dex number
        if filename == Settings::DEFAULT_SPRITE_PATH && mega_from
          head_id = getHeadID(dex, getBodyID(dex))
          body_id = getBodyID(dex)
          japeal_id = _npt_japeal_dex(mega_from)

          if japeal_id != head_id || japeal_id != body_id
            if sf_head
              # Head is mega: replace head with Japeal dex
              japeal_dex = getSpeciesIdForFusion(japeal_id, body_id)
            else
              # Body is mega: replace body with Japeal dex
              japeal_dex = getSpeciesIdForFusion(head_id, japeal_id)
            end
            filename = self.sprite_filename(japeal_dex, sf_body, sf_head)
            MegaDebug.log "  Japeal path: dex=#{japeal_dex} filename=#{filename.inspect}"
          end
        end

        if filename && filename != Settings::DEFAULT_SPRITE_PATH
          sprite = AnimatedBitmap.new(filename).recognizeDims() rescue nil
          MegaDebug.log "  sprite loaded: #{!sprite.nil?}"
          if sprite
            # Apply shiny coloring
            if makeShiny && pkmn.shiny?
              if $PokemonSystem.kuraynormalshiny == 1
                sprite.shiftColors(self.calculateShinyHueOffset(dex, pkmn.bodyShiny?, pkmn.headShiny?))
              else
                sprite.pbGiveFinaleColor(pkmn.shinyR?, pkmn.shinyG?, pkmn.shinyB?, pkmn.shinyValue?, pkmn.shinyKRS?)
              end
            end
            sprite.scale_bitmap(pkmn.sprite_scale)
            return sprite
          end
        end
        MegaDebug.log "  falling through to default resolution"
      end

      _npt_mega_sprite_bitmap_from_pokemon(pkmn, back, species, makeShiny)
    end
  end
end

#===============================================================================
# B. Enable PokeBattle_Battle#pbCanMegaEvolve?
#
# The core implementation simply returns false.  This alias restores the
# commented-out Essentials v21.1 logic so that any Pokémon holding a
# registered mega stone can trigger the battle button.
#===============================================================================
class PokeBattle_Battle
  alias _npt_pbCanMegaEvolve? pbCanMegaEvolve?
  def pbCanMegaEvolve?(idxBattler)
    return false if $game_switches[Settings::NO_MEGA_EVOLUTION]
    return false if !@battlers[idxBattler].hasMega?
    return false if wildBattle? && opposes?(idxBattler)
    return true  if $DEBUG && Input.press?(Input::CTRL)
    return false if @battlers[idxBattler].effects[PBEffects::SkyDrop] >= 0
    return false if !pbHasMegaRing?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @megaEvolution[side][owner] == -1
  end
end

#===============================================================================
# C. PokeBattle_Battle#pbMegaEvolve — full override
#
# The core pbMegaEvolve calls two vanilla common animations (MegaEvolution and
# MegaEvolution2).  The first can set sprite opacity/visibility to 0 and the
# second (EBDX's particle-heavy version) can crash mid-way, leaving the scene
# broken.  This override replaces the entire sequence:
#   1. Display messages
#   2. makeMega + form sync
#   3. Update sprite via pbChangePokemon
#   4. Play our simple KIF-compatible MegaEvolution2 animation
#   5. Display mega name
#   6. Trigger ability effects
#===============================================================================
class PokeBattle_Battle
  alias _npt_pbMegaEvolve pbMegaEvolve
  def pbMegaEvolve(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasMega? || battler.mega?
    trainerName = pbGetOwnerName(idxBattler)
    # Break Illusion
    if battler.hasActiveAbility?(:ILLUSION)
      BattleHandlers.triggerTargetAbilityOnHit(battler.ability, nil, battler, nil, self)
    end
    # Mega Evolve message
    case battler.pokemon.megaMessage
    when 1   # Rayquaza
      pbDisplay(_INTL("{1}'s fervent wish has reached {2}!", trainerName, battler.pbThis))
    else
      pbDisplay(_INTL("{1}'s {2} is reacting to {3}'s {4}!",
         battler.pbThis, battler.itemName, trainerName, pbGetMegaRingName(idxBattler)))
    end
    # Change form data (stats, type, ability) — sprite NOT yet updated
    is_fusion = battler.pokemon.isFusion?
    battler.pokemon.makeMega
    if is_fusion
      # Fusion mega: check if a sprite exists for the mega fusion form.
      # Must use the full sprite resolution chain (not raw pbResolveBitmap)
      # because fusion sprites live at Graphics/Battlers/{head}/{head}.{body}.png
      # and the .pak system extracts lazily via download_autogen_sprite.
      has_mega_sprite = false
      back = (idxBattler % 2 == 0)
      begin
        bmp = GameData::Species.sprite_bitmap_from_pokemon(battler.pokemon, back)
        has_mega_sprite = !bmp.nil?
        bmp.dispose if bmp && bmp.respond_to?(:dispose)
      rescue
        has_mega_sprite = false
      end
      battler.pbUpdate(true)
      _npt_mega_animate(idxBattler, !has_mega_sprite)  # swap sprite only if exists
    else
      # Normal mega: form change + sprite swap + full animation
      battler.form = battler.pokemon.form
      battler.pbUpdate(true)
      _npt_mega_animate(idxBattler)
    end
    # Display result
    megaName = battler.pokemon.megaName
    megaName = _INTL("Mega {1}", battler.pokemon.speciesName) if nil_or_empty?(megaName)
    pbDisplay(_INTL("{1} has Mega Evolved into {2}!", battler.pbThis, megaName))
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @megaEvolution[side][owner] = -2
    if battler.isSpecies?(:GENGAR) && battler.mega?
      battler.effects[PBEffects::Telekinesis] = 0
    end
    pbCalculatePriority(false, [idxBattler]) if Settings::RECALCULATE_TURN_ORDER_AFTER_MEGA_EVOLUTION
    # Trigger ability + form-change side effects
    battler.pbEffectsOnSwitchIn
    MultipleForms.call("changePokemonOnMegaEvolve", battler, self) rescue nil
  end

  #---------------------------------------------------------------------------
  # Full EBDX-style mega evolution animation — runs directly on scene
  # sprites, bypassing the EBDX CallbackWrapper/withCommonParams system
  # that caused sprite disposal crashes.
  #
  # Ported from 660_EBDX/018_EBDX_CommonAnimations.rb MEGAEVOLUTION2.
  # Uses particles, rays, ripples, circle, background scroll, and impact.
  #---------------------------------------------------------------------------
  def _npt_mega_animate(idxBattler, skip_sprite_swap = false)
    sprite = @scene.sprites["pokemon_#{idxBattler}"] rescue nil
    return unless sprite && !sprite.disposed?

    viewport = sprite.viewport
    back = (idxBattler % 2 == 0)
    battler = @battlers[idxBattler]
    fp = {}

    # Hide databoxes
    isVisible = []
    @battlers.each_with_index do |b, i|
      isVisible.push(false)
      next if !b
      db = @scene.sprites["dataBox_#{i}"] rescue nil
      next unless db
      isVisible[i] = db.visible
      db.visible = false
    end
    @scene.clearMessageWindow rescue nil

    begin
      factor = sprite.zoom_x
      cx, cy = sprite.getCenter(true)

      #--- Background ---
      fp["bg"] = ScrollingSprite.new(viewport)
      fp["bg"].setBitmap("Graphics/EBDX/Animations/Moves/ebMegaBg")
      fp["bg"].speed = 32
      fp["bg"].opacity = 0

      #--- 16 Particles ---
      for i in 0...16
        fp["c#{i}"] = Sprite.new(viewport)
        fp["c#{i}"].z = sprite.z + 10
        fp["c#{i}"].bitmap = pbBitmap(sprintf("Graphics/EBDX/Animations/Moves/ebMega%03d", rand(4)+1))
        fp["c#{i}"].center!
        fp["c#{i}"].opacity = 0
      end

      #--- 8 Rays ---
      rangle = []
      for i in 0...8; rangle.push((360/8)*i + 15); end
      for j in 0...8
        fp["r#{j}"] = Sprite.new(viewport)
        fp["r#{j}"].bitmap = pbBitmap("Graphics/EBDX/Animations/Moves/ebMega005")
        fp["r#{j}"].ox = 0
        fp["r#{j}"].oy = fp["r#{j}"].bitmap.height / 2
        fp["r#{j}"].opacity = 0
        fp["r#{j}"].zoom_x = 0
        fp["r#{j}"].zoom_y = 0
        fp["r#{j}"].x = cx
        fp["r#{j}"].y = cy
        a = rand(rangle.length)
        fp["r#{j}"].angle = rangle[a]
        fp["r#{j}"].z = sprite.z + 2
        rangle.delete_at(a)
      end

      #--- 3 Ripples ---
      for j in 0...3
        fp["v#{j}"] = Sprite.new(viewport)
        fp["v#{j}"].bitmap = pbBitmap("Graphics/EBDX/Animations/Moves/ebMega006")
        fp["v#{j}"].center!
        fp["v#{j}"].x = cx
        fp["v#{j}"].y = cy
        fp["v#{j}"].opacity = 0
        fp["v#{j}"].zoom_x = 2
        fp["v#{j}"].zoom_y = 2
      end

      #--- Circle ---
      bw = (sprite.bitmap.width * 1.25).to_i
      bh = (sprite.bitmap.height * 1.25).to_i
      fp["circle"] = Sprite.new(viewport)
      fp["circle"].bitmap = Bitmap.new(bw, bh)
      fp["circle"].bitmap.bmp_circle
      fp["circle"].center!
      fp["circle"].x = cx
      fp["circle"].y = cy
      fp["circle"].z = sprite.z + 10
      fp["circle"].zoom_x = 0
      fp["circle"].zoom_y = 0

      #--- Defocus background ---
      z = 0.02
      @scene.sprites["battlebg"].defocus rescue nil
      pbSEPlay("Anim/Harden", 120) rescue nil

      #--- Main loop (128 frames) ---
      for i in 0...128
        fp["bg"].opacity += 8
        fp["bg"].update
        sprite.tone.all += 8 if sprite.tone.all < 255

        # Particle animation
        for j in 0...16
          next if j > (i / 8)
          if fp["c#{j}"].opacity == 0 && i < 72
            fp["c#{j}"].opacity = 255
            x, y = randCircleCord((96 * factor).to_i)
            fp["c#{j}"].x = cx - 96 * factor + x
            fp["c#{j}"].y = cy - 96 * factor + y
          end
          fp["c#{j}"].x += (cx - fp["c#{j}"].x) * 0.1
          fp["c#{j}"].y += (cy - fp["c#{j}"].y) * 0.1
          fp["c#{j}"].opacity -= 16
        end

        # Ray animation
        for j in 0...8
          if fp["r#{j}"].opacity == 0 && j <= (i % 128) / 16 && i < 96
            fp["r#{j}"].opacity = 255
            fp["r#{j}"].zoom_x = 0
            fp["r#{j}"].zoom_y = 0
          end
          fp["r#{j}"].opacity -= 4
          fp["r#{j}"].zoom_x += 0.05
          fp["r#{j}"].zoom_y += 0.05
        end

        # Circle animation
        if i < 48
          # nothing
        elsif i < 64
          fp["circle"].zoom_x += factor / 16.0
          fp["circle"].zoom_y += factor / 16.0
        elsif i >= 124
          fp["circle"].zoom_x += factor
          fp["circle"].zoom_y += factor
        else
          z *= -1 if (i - 96) % 4 == 0
          fp["circle"].zoom_x += z
          fp["circle"].zoom_y += z
        end

        pbSEPlay("Anim/Twine", 80) if i == 40
        pbSEPlay("Anim/Refresh") if i == 56

        # Ripple animation
        if i >= 24
          for j in 0...3
            next if j > (i - 32) / 8
            next if fp["v#{j}"].zoom_x <= 0
            fp["v#{j}"].opacity += 16
            fp["v#{j}"].zoom_x -= 0.05
            fp["v#{j}"].zoom_y -= 0.05
          end
        end

        @scene.pbGraphicsUpdate
        Input.update
      end

      #--- White flash + dispose particles ---
      viewport.color = Color.white
      pbSEPlay("Vs flash", 80) rescue nil
      sprite.tone.all = 0
      pbDisposeSpriteHash(fp)
      fp = {}

      #--- Refocus background ---
      @scene.sprites["battlebg"].focus rescue nil

      #--- Impact effect ---
      fp["impact"] = Sprite.new(viewport)
      fp["impact"].bitmap = pbBitmap("Graphics/EBDX/Pictures/impact")
      fp["impact"].center!(true)
      fp["impact"].z = 999
      fp["impact"].opacity = 0

      #--- Swap sprite to mega form (skip for fusions — keep fusion sprite) ---
      unless skip_sprite_swap
        sprite.setPokemonBitmap(battler.pokemon, back) rescue nil
      end
      db = @scene.sprites["dataBox_#{idxBattler}"] rescue nil
      db.refresh if db && db.respond_to?(:refresh)

      #--- Play cry ---
      battler.pokemon.play_cry if battler && battler.pokemon

      #--- Impact animation (24 frames) ---
      k = -2
      for i in 0...24
        fp["impact"].opacity += 64
        fp["impact"].angle += 180 if i % 4 == 0
        fp["impact"].mirror = !fp["impact"].mirror if i % 4 == 2
        k *= -1 if i % 4 == 0
        viewport.color.alpha -= 16 if i > 1
        @scene.moveEntireScene(0, k, true, true) rescue nil
        @scene.pbGraphicsUpdate
        Input.update
      end

      #--- Fade impact (16 frames) ---
      for i in 0...16
        fp["impact"].opacity -= 64
        fp["impact"].angle += 180 if i % 4 == 0
        fp["impact"].mirror = !fp["impact"].mirror if i % 4 == 2
        @scene.pbGraphicsUpdate
        Input.update
      end

      fp["impact"].dispose if fp["impact"] && !fp["impact"].disposed?

    rescue => e
      echoln "[990_NPT] Mega animation error: #{e.message}" rescue nil
      pbDisposeSpriteHash(fp) rescue nil if fp
    ensure
      # ALWAYS restore scene state regardless of animation success/failure
      viewport.color = Color.new(0, 0, 0, 0) if viewport && !viewport.disposed?
      sprite.tone = Tone.new(0, 0, 0, 0) if sprite && !sprite.disposed?
      sprite.visible = true if sprite && !sprite.disposed?
      sprite.opacity = 255 if sprite && !sprite.disposed?

      # Make sure sprite shows mega form even if animation failed mid-way
      unless skip_sprite_swap
        @scene.pbChangePokemon(battler, battler.pokemon) rescue nil
      end
      @scene.pbRefreshOne(idxBattler) rescue nil

      # Restore all pokemon sprite visibility
      @battlers.each_with_index do |b, i|
        next if !b
        s = @scene.sprites["pokemon_#{i}"] rescue nil
        next unless s && !s.disposed?
        s.visible = true
        s.opacity = 255
      end

      # Restore databox visibility
      @battlers.each_with_index do |b, i|
        next if !b
        db = @scene.sprites["dataBox_#{i}"] rescue nil
        next unless db
        db.visible = true if isVisible[i]
      end

      # Ensure background is refocused
      @scene.sprites["battlebg"].focus rescue nil
    end
  end
end

#===============================================================================
# D. Mega stone item registrations (Gen 9 Pack — PLZA stones)
#
# Registered inside GameData::Item.load so they survive the items.dat reload
# (bare unless-register calls are wiped when the .dat file is loaded).
# Uses the same alias-chain pattern as 659_Multiplayer/015_Items/001_ItemRegistry.rb.
#
# type: 12  → is_mega_stone? returns true (engine checks @type == 12, not flags)
# id_number: 9300-9344  → unique IDs that don't clash with base game or MP items
#===============================================================================

if defined?(GameData) && defined?(GameData::Item)
  class GameData::Item
    class << self
      alias npt_mega_stones_original_load load
      def load
        npt_mega_stones_original_load

        npt_mega_stones = [
          { id: :CLEFABLITE,    id_number: 9300, name: "Clefablite",    name_plural: "Clefablites",    description: "Have Clefable hold it, and it will be able to Mega Evolve."       },
          { id: :VICTREEBELITE, id_number: 9301, name: "Victreebelite", name_plural: "Victreebelites", description: "Have Victreebel hold it, and it will be able to Mega Evolve."     },
          { id: :STARMINITE,    id_number: 9302, name: "Starminite",    name_plural: "Starminites",    description: "Have Starmie hold it, and it will be able to Mega Evolve."        },
          { id: :DRAGONINITE,   id_number: 9303, name: "Dragoninite",   name_plural: "Dragoninites",   description: "Have Dragonite hold it, and it will be able to Mega Evolve."      },
          { id: :MEGANIUMITE,   id_number: 9304, name: "Meganiumite",   name_plural: "Meganiumites",   description: "Have Meganium hold it, and it will be able to Mega Evolve."       },
          { id: :FERALIGITE,    id_number: 9305, name: "Feraligite",    name_plural: "Feraligites",    description: "Have Feraligatr hold it, and it will be able to Mega Evolve."     },
          { id: :SKARMORITE,    id_number: 9306, name: "Skarmorite",    name_plural: "Skarmorites",    description: "Have Skarmory hold it, and it will be able to Mega Evolve."       },
          { id: :FROSLASSITE,   id_number: 9307, name: "Froslassite",   name_plural: "Froslassites",   description: "Have Froslass hold it, and it will be able to Mega Evolve."       },
          { id: :EMBOARITE,     id_number: 9308, name: "Emboarite",     name_plural: "Emboarites",     description: "Have Emboar hold it, and it will be able to Mega Evolve."         },
          { id: :EXCADRITE,     id_number: 9309, name: "Excadrite",     name_plural: "Excadrites",     description: "Have Excadrill hold it, and it will be able to Mega Evolve."      },
          { id: :SCOLIPITE,     id_number: 9310, name: "Scolipite",     name_plural: "Scolipites",     description: "Have Scolipede hold it, and it will be able to Mega Evolve."      },
          { id: :SCRAFTINITE,   id_number: 9311, name: "Scraftinite",   name_plural: "Scraftinites",   description: "Have Scrafty hold it, and it will be able to Mega Evolve."        },
          { id: :EELEKTROSSITE, id_number: 9312, name: "Eelektrossite", name_plural: "Eelektrossites", description: "Have Eelektross hold it, and it will be able to Mega Evolve."     },
          { id: :CHANDELURITE,  id_number: 9313, name: "Chandelurite",  name_plural: "Chandelurites",  description: "Have Chandelure hold it, and it will be able to Mega Evolve."      },
          { id: :CHESNAUGHTITE, id_number: 9314, name: "Chesnaughtite", name_plural: "Chesnaughtites", description: "Have Chesnaught hold it, and it will be able to Mega Evolve."     },
          { id: :DELPHOXITE,    id_number: 9315, name: "Delphoxite",    name_plural: "Delphoxites",    description: "Have Delphox hold it, and it will be able to Mega Evolve."        },
          { id: :GRENINJITE,    id_number: 9316, name: "Greninjite",    name_plural: "Greninjites",    description: "Have Greninja hold it, and it will be able to Mega Evolve."        },
          { id: :PYROARITE,     id_number: 9317, name: "Pyroarite",     name_plural: "Pyroarites",     description: "Have Pyroar hold it, and it will be able to Mega Evolve."         },
          { id: :FLOETTITE,     id_number: 9318, name: "Floettite",     name_plural: "Floettites",     description: "Have special Floette hold it to Mega Evolve."                     },
          { id: :MALAMARITE,    id_number: 9319, name: "Malamarite",    name_plural: "Malamarites",    description: "Have Malamar hold it, and it will be able to Mega Evolve."        },
          { id: :BARBARACITE,   id_number: 9320, name: "Barbaracite",   name_plural: "Barbaracites",   description: "Have Barbaracle hold it, and it will be able to Mega Evolve."     },
          { id: :DRAGALGITE,    id_number: 9321, name: "Dragalgite",    name_plural: "Dragalgites",    description: "Have Dragalge hold it, and it will be able to Mega Evolve."       },
          { id: :HAWLUCHANITE,  id_number: 9322, name: "Hawluchanite",  name_plural: "Hawluchanites",  description: "Have Hawlucha hold it, and it will be able to Mega Evolve."       },
          { id: :ZYGARDITE,     id_number: 9323, name: "Zygardite",     name_plural: "Zygardites",     description: "Have Complete Forme Zygarde hold it to Mega Evolve."              },
          { id: :DRAMPANITE,    id_number: 9324, name: "Drampanite",    name_plural: "Drampanites",    description: "Have Drampa hold it, and it will be able to Mega Evolve."         },
          { id: :FALINKSITE,    id_number: 9325, name: "Falinksite",    name_plural: "Falinksites",    description: "Have Falinks hold it, and it will be able to Mega Evolve."        },
          { id: :RAICHUNITEX,   id_number: 9326, name: "Raichunite X",  name_plural: "Raichunite Xs",  description: "Have Raichu hold it, and it will be able to Mega Evolve."         },
          { id: :RAICHUNITEY,   id_number: 9327, name: "Raichunite Y",  name_plural: "Raichunite Ys",  description: "Have Raichu hold it, and it will be able to Mega Evolve."         },
          { id: :CHIMECHITE,    id_number: 9328, name: "Chimechite",    name_plural: "Chimechites",    description: "Have Chimecho hold it, and it will be able to Mega Evolve."       },
          { id: :ABSOLITEZ,     id_number: 9329, name: "Absolite Z",    name_plural: "Absolite Zs",    description: "Have Absol hold it, and it will be able to Mega Evolve."          },
          { id: :STARAPTITE,    id_number: 9330, name: "Staraptite",    name_plural: "Staraptites",    description: "Have Staraptor hold it, and it will be able to Mega Evolve."      },
          { id: :GARCHOMPITEZ,  id_number: 9331, name: "Garchompite Z", name_plural: "Garchompite Zs", description: "Have Garchomp hold it, and it will be able to Mega Evolve."       },
          { id: :LUCARIONITEZ,  id_number: 9332, name: "Lucarionite Z", name_plural: "Lucarionite Zs", description: "Have Lucario hold it, and it will be able to Mega Evolve."       },
          { id: :HEATRANITE,    id_number: 9333, name: "Heatranite",    name_plural: "Heatranites",    description: "Have Heatran hold it, and it will be able to Mega Evolve."        },
          { id: :DARKRANITE,    id_number: 9334, name: "Darkranite",    name_plural: "Darkranites",    description: "Have Darkrai hold it, and it will be able to Mega Evolve."        },
          { id: :GOLURKITE,     id_number: 9335, name: "Golurkite",     name_plural: "Golurkites",     description: "Have Golurk hold it, and it will be able to Mega Evolve."         },
          { id: :MEOWSTICITE,   id_number: 9336, name: "Meowsticite",   name_plural: "Meowsticites",   description: "Have Meowstic hold it, and it will be able to Mega Evolve."       },
          { id: :CRABOMINITE,   id_number: 9337, name: "Crabominite",   name_plural: "Crabominites",   description: "Have Crabominable hold it, and it will be able to Mega Evolve."   },
          { id: :GOLISOPITE,    id_number: 9338, name: "Golisopite",    name_plural: "Golisopites",    description: "Have Golisopod hold it, and it will be able to Mega Evolve."       },
          { id: :MAGEARNITE,    id_number: 9339, name: "Magearnite",    name_plural: "Magearnites",    description: "Have Magearna hold it, and it will be able to Mega Evolve."       },
          { id: :ZERAORITE,     id_number: 9340, name: "Zeraorite",     name_plural: "Zeraorites",     description: "Have Zeraora hold it, and it will be able to Mega Evolve."        },
          { id: :SCOVILLAINITE, id_number: 9341, name: "Scovillainite", name_plural: "Scovillainites", description: "Have Scovillain hold it, and it will be able to Mega Evolve."     },
          { id: :GLIMMORANITE,  id_number: 9342, name: "Glimmoranite",  name_plural: "Glimmoranites",  description: "Have Glimmora hold it, and it will be able to Mega Evolve."       },
          { id: :TATSUGIRINITE, id_number: 9343, name: "Tatsugirinite", name_plural: "Tatsugirinites", description: "Have Tatsugiri hold it, and it will be able to Mega Evolve."      },
          { id: :BAXCALIBRITE,  id_number: 9344, name: "Baxcalibrite",  name_plural: "Baxcalibrites",  description: "Have Baxcalibur hold it, and it will be able to Mega Evolve."     },
          { id: :VENUSAURITE,   id_number: 9345, name: "Venusaurite",   name_plural: "Venusaurites",   description: "Have Venusaur hold it, and it will be able to Mega Evolve."        },
          # ── Official Gen 6-7 Mega Stones (40 items, IDs 9400-9439) ──
          { id: :CHARIZARDITEX,  id_number: 9400, name: "Charizardite X",  name_plural: "Charizardite Xs",  description: "Have Charizard hold it, and it will be able to Mega Evolve."  },
          { id: :CHARIZARDITEY,  id_number: 9401, name: "Charizardite Y",  name_plural: "Charizardite Ys",  description: "Have Charizard hold it, and it will be able to Mega Evolve."  },
          { id: :BLASTOISINITE,  id_number: 9402, name: "Blastoisinite",   name_plural: "Blastoisinites",   description: "Have Blastoise hold it, and it will be able to Mega Evolve." },
          { id: :ALAKAZITE,      id_number: 9403, name: "Alakazite",       name_plural: "Alakazites",       description: "Have Alakazam hold it, and it will be able to Mega Evolve."  },
          { id: :GENGARITE,      id_number: 9404, name: "Gengarite",       name_plural: "Gengarites",       description: "Have Gengar hold it, and it will be able to Mega Evolve."    },
          { id: :KANGASKHANITE,  id_number: 9405, name: "Kangaskhanite",   name_plural: "Kangaskhanites",   description: "Have Kangaskhan hold it, and it will be able to Mega Evolve." },
          { id: :PINSIRITE,      id_number: 9406, name: "Pinsirite",       name_plural: "Pinsirites",       description: "Have Pinsir hold it, and it will be able to Mega Evolve."    },
          { id: :GYARADOSITE,    id_number: 9407, name: "Gyaradosite",     name_plural: "Gyaradosites",     description: "Have Gyarados hold it, and it will be able to Mega Evolve."  },
          { id: :AERODACTYLITE,  id_number: 9408, name: "Aerodactylite",   name_plural: "Aerodactylites",   description: "Have Aerodactyl hold it, and it will be able to Mega Evolve." },
          { id: :MEWTWONITEX,    id_number: 9409, name: "Mewtwonite X",    name_plural: "Mewtwonite Xs",    description: "Have Mewtwo hold it, and it will be able to Mega Evolve."    },
          { id: :MEWTWONITEY,    id_number: 9410, name: "Mewtwonite Y",    name_plural: "Mewtwonite Ys",    description: "Have Mewtwo hold it, and it will be able to Mega Evolve."    },
          { id: :AMPHAROSITE,    id_number: 9411, name: "Ampharosite",     name_plural: "Ampharosites",     description: "Have Ampharos hold it, and it will be able to Mega Evolve."  },
          { id: :SCIZORITE,      id_number: 9412, name: "Scizorite",       name_plural: "Scizorites",       description: "Have Scizor hold it, and it will be able to Mega Evolve."    },
          { id: :HERACRONITE,    id_number: 9413, name: "Heracronite",     name_plural: "Heracronites",     description: "Have Heracross hold it, and it will be able to Mega Evolve." },
          { id: :HOUNDOOMINITE,  id_number: 9414, name: "Houndoominite",   name_plural: "Houndoominites",   description: "Have Houndoom hold it, and it will be able to Mega Evolve."  },
          { id: :TYRANITARITE,   id_number: 9415, name: "Tyranitarite",    name_plural: "Tyranitarites",    description: "Have Tyranitar hold it, and it will be able to Mega Evolve." },
          { id: :BLAZIKENITE,    id_number: 9416, name: "Blazikenite",     name_plural: "Blazikenites",     description: "Have Blaziken hold it, and it will be able to Mega Evolve."  },
          { id: :GARDEVOIRITE,   id_number: 9417, name: "Gardevoirite",    name_plural: "Gardevoirites",    description: "Have Gardevoir hold it, and it will be able to Mega Evolve." },
          { id: :MAWILITE,       id_number: 9418, name: "Mawilite",        name_plural: "Mawilites",        description: "Have Mawile hold it, and it will be able to Mega Evolve."    },
          { id: :AGGRONITE,      id_number: 9419, name: "Aggronite",       name_plural: "Aggronites",       description: "Have Aggron hold it, and it will be able to Mega Evolve."    },
          { id: :BANETTITE,      id_number: 9420, name: "Banettite",       name_plural: "Banettites",       description: "Have Banette hold it, and it will be able to Mega Evolve."   },
          { id: :GARCHOMPITE,    id_number: 9421, name: "Garchompite",     name_plural: "Garchompites",     description: "Have Garchomp hold it, and it will be able to Mega Evolve."  },
          { id: :LUCARIONITE,    id_number: 9422, name: "Lucarionite",     name_plural: "Lucarionites",     description: "Have Lucario hold it, and it will be able to Mega Evolve."   },
          { id: :LATIASITE,      id_number: 9423, name: "Latiasite",       name_plural: "Latiasites",       description: "Have Latias hold it, and it will be able to Mega Evolve."    },
          { id: :LATIOSITE,      id_number: 9424, name: "Latiosite",       name_plural: "Latiosites",       description: "Have Latios hold it, and it will be able to Mega Evolve."    },
          { id: :SWAMPERTITE,    id_number: 9425, name: "Swampertite",     name_plural: "Swampertites",     description: "Have Swampert hold it, and it will be able to Mega Evolve."  },
          { id: :SCEPTILITE,     id_number: 9426, name: "Sceptilite",      name_plural: "Sceptilites",      description: "Have Sceptile hold it, and it will be able to Mega Evolve."  },
          { id: :SABLENITE,      id_number: 9427, name: "Sablenite",       name_plural: "Sablenites",       description: "Have Sableye hold it, and it will be able to Mega Evolve."   },
          { id: :ALTARIANITE,    id_number: 9428, name: "Altarianite",     name_plural: "Altarianites",     description: "Have Altaria hold it, and it will be able to Mega Evolve."   },
          { id: :GALLADITE,      id_number: 9429, name: "Galladite",       name_plural: "Galladites",       description: "Have Gallade hold it, and it will be able to Mega Evolve."   },
          { id: :SHARPEDONITE,   id_number: 9430, name: "Sharpedonite",    name_plural: "Sharpedonites",    description: "Have Sharpedo hold it, and it will be able to Mega Evolve."  },
          { id: :SLOWBRONITE,    id_number: 9431, name: "Slowbronite",     name_plural: "Slowbronites",     description: "Have Slowbro hold it, and it will be able to Mega Evolve."   },
          { id: :STEELIXITE,     id_number: 9432, name: "Steelixite",      name_plural: "Steelixites",      description: "Have Steelix hold it, and it will be able to Mega Evolve."   },
          { id: :PIDGEOTITE,     id_number: 9433, name: "Pidgeotite",      name_plural: "Pidgeotites",      description: "Have Pidgeot hold it, and it will be able to Mega Evolve."   },
          { id: :GLALITITE,      id_number: 9434, name: "Glalitite",       name_plural: "Glalitites",       description: "Have Glalie hold it, and it will be able to Mega Evolve."    },
          { id: :DIANCITE,       id_number: 9435, name: "Diancite",        name_plural: "Diancites",        description: "Have Diancie hold it, and it will be able to Mega Evolve."   },
          { id: :METAGROSSITE,   id_number: 9436, name: "Metagrossite",    name_plural: "Metagrossites",    description: "Have Metagross hold it, and it will be able to Mega Evolve." },
          { id: :LOPUNNITE,      id_number: 9437, name: "Lopunnite",       name_plural: "Lopunnites",       description: "Have Lopunny hold it, and it will be able to Mega Evolve."   },
          { id: :SALAMENCITE,    id_number: 9438, name: "Salamencite",     name_plural: "Salamencites",     description: "Have Salamence hold it, and it will be able to Mega Evolve." },
          { id: :BEEDRILLITE,    id_number: 9439, name: "Beedrillite",     name_plural: "Beedrillites",     description: "Have Beedrill hold it, and it will be able to Mega Evolve."  },
        ]

        npt_mega_stones.each do |stone|
          register({
            id:          stone[:id],
            id_number:   stone[:id_number],
            name:        stone[:name],
            name_plural: stone[:name_plural],
            pocket:      1,
            price:       0,
            field_use:   0,
            battle_use:  0,
            type:        12,
            description: stone[:description],
          })
        end

        npt_mega_rings = [
          { id: :MEGARING,    id_number: 9350, name: "Mega Ring",    name_plural: "Mega Rings",    description: "A ring that allows Pokémon holding a Mega Stone to Mega Evolve in battle." },
          { id: :MEGABRACELET, id_number: 9351, name: "Mega Bracelet", name_plural: "Mega Bracelets", description: "A bracelet that allows Pokémon holding a Mega Stone to Mega Evolve in battle." },
          { id: :MEGACUFF,    id_number: 9352, name: "Mega Cuff",    name_plural: "Mega Cuffs",    description: "A cuff that allows Pokémon holding a Mega Stone to Mega Evolve in battle." },
          { id: :MEGACHARM,   id_number: 9353, name: "Mega Charm",   name_plural: "Mega Charms",   description: "A charm that allows Pokémon holding a Mega Stone to Mega Evolve in battle." },
        ]

        npt_mega_rings.each do |ring|
          next if self::DATA.has_key?(ring[:id])
          register({
            id:          ring[:id],
            id_number:   ring[:id_number],
            name:        ring[:name],
            name_plural: ring[:name_plural],
            pocket:      8,
            price:       0,
            field_use:   0,
            battle_use:  0,
            type:        1,
            description: ring[:description],
          })
        end
      end
    end

    #=========================================================================
    # Name/Description fallback for dynamically registered items
    # Without Multiplayer, pbGetMessage returns "" for NPT items (id 9300+)
    # because they aren't in the compiled messages.dat. This adds a fallback
    # to @real_name / @real_description (set during register).
    #=========================================================================
    unless method_defined?(:mp_items_original_name)
      alias npt_items_original_name name
      def name
        translated = npt_items_original_name rescue nil
        return translated if translated && !translated.empty?
        return @real_name if @real_name
        return @id.to_s
      end
    end

    unless method_defined?(:mp_items_original_description)
      alias npt_items_original_description description
      def description
        translated = npt_items_original_description rescue nil
        return translated if translated && !translated.empty?
        return @real_description if @real_description
        return ""
      end
    end
  end
end

#===============================================================================
# E. NPT module hook — new mega form registrations + existing mega patches
#
# Aliases NPT.register_all_species (same pattern as 011_NPTForms.rb).
# After all base NPT species are loaded:
#   1. Patches 12 existing _N alternate forms with mega_stone / unmega_form
#   2. Registers 44 new mega forms, inheriting all non-delta fields from the
#      base species (which is already in GameData::Species by this point).
#
# FROSLASS_1 note: the Gen 9 Pack PBS lists MegaStone = CLEFABLITE (error).
# We correct it here to FROSLASSITE.
#===============================================================================

# ---------------------------------------------------------------------------
# Data tables
# ---------------------------------------------------------------------------

# Existing NPT alternate forms that need mega_stone / unmega_form injected.
# Values are the item symbol of the matching mega stone.
NPT_MEGA_PATCHES = {
  ABOMASNOW_1: :ABOMASITE,
  AUDINO_1:    :AUDINITE,
  CAMERUPT_1:  :CAMERUPTITE,
  CHIMECHO_1:  :CHIMECHITE,
  EMBOAR_1:    :EMBOARITE,
  EXCADRILL_1: :EXCADRITE,
  FALINKS_1:   :FALINKSITE,
  MALAMAR_1:   :MALAMARITE,
  MANECTRIC_1: :MANECTITE,
  MEDICHAM_1:  :MEDICHAMITE,
  SHAYMIN_1:   :SHARMINITE,
  ZYGARDE_4:   :ZYGARDITE,
}.freeze

# New mega forms to register.  Each hash supplies DELTA fields only; all other
# fields are copied from the base species at registration time.
NPT_NEW_MEGAS = [
  # Mega Clefable
  {
    id:          :CLEFABLE_1,
    id_number:   1109,
    species:     :CLEFABLE,
    form:        1,
    mega_stone:  :CLEFABLITE,
    unmega_form: 0,
    form_name:   "Mega Clefable",
    type1_override: :FAIRY,
    type2_override: :FLYING,
    base_stats_override: { HP: 95, ATTACK: 80, DEFENSE: 93, SPECIAL_ATTACK: 135, SPECIAL_DEFENSE: 110, SPEED: 70 },
    height:      1.7,
    weight:      42.3,
    pokedex:     "It flies by using the power of moonlight to control gravity within a radius of over 32 feet around it.",
    generation:  9,
  },

  # Mega Victreebel
  {
    id:          :VICTREEBEL_1,
    id_number:   1110,
    species:     :VICTREEBEL,
    form:        1,
    mega_stone:  :VICTREEBELITE,
    unmega_form: 0,
    form_name:   "Mega Victreebel",
    base_stats_override: { HP: 80, ATTACK: 125, DEFENSE: 85, SPECIAL_ATTACK: 135, SPECIAL_DEFENSE: 95, SPEED: 70 },
    height:      4.5,
    weight:      125.5,
    pokedex:     "The volume of this Pokémon's acid has increased and filling its mouth. If it's not careful, it will overflow and spill out.",
    generation:  9,
  },

  # Mega Starmie
  {
    id:          :STARMIE_1,
    id_number:   1111,
    species:     :STARMIE,
    form:        1,
    mega_stone:  :STARMINITE,
    unmega_form: 0,
    form_name:   "Mega Starmie",
    base_stats_override: { HP: 60, ATTACK: 140, DEFENSE: 105, SPECIAL_ATTACK: 130, SPECIAL_DEFENSE: 105, SPEED: 120 },
    height:      2.3,
    weight:      80.0,
    pokedex:     "Its movements have become more humanlike. Whether it's simply trying to communicate or wants to supplant humanity is unclear.",
    generation:  9,
  },

  # Mega Dragonite
  {
    id:          :DRAGONITE_1,
    id_number:   1112,
    species:     :DRAGONITE,
    form:        1,
    mega_stone:  :DRAGONINITE,
    unmega_form: 0,
    form_name:   "Mega Dragonite",
    base_stats_override: { HP: 91, ATTACK: 124, DEFENSE: 115, SPECIAL_ATTACK: 145, SPECIAL_DEFENSE: 125, SPEED: 100 },
    height:      1.7,
    weight:      42.3,
    pokedex:     "Mega Evolution has excessively powered up this Pokémon's feelings of kindness. It finishes off its opponents with mercy in its heart.",
    generation:  9,
  },

  # Mega Meganium
  {
    id:          :MEGANIUM_1,
    id_number:   1113,
    species:     :MEGANIUM,
    form:        1,
    mega_stone:  :MEGANIUMITE,
    unmega_form: 0,
    form_name:   "Mega Meganium",
    type1_override: :GRASS,
    type2_override: :FAIRY,
    base_stats_override: { HP: 80, ATTACK: 92, DEFENSE: 115, SPECIAL_ATTACK: 143, SPECIAL_DEFENSE: 115, SPEED: 80 },
    height:      2.4,
    weight:      201.0,
    pokedex:     "This Pokémon can fire a tremendously powerful Solar Beam from its four flowers. Another name for this is Mega Sol Cannon.",
    generation:  9,
  },

  # Mega Feraligatr
  {
    id:          :FERALIGATR_1,
    id_number:   1114,
    species:     :FERALIGATR,
    form:        1,
    mega_stone:  :FERALIGITE,
    unmega_form: 0,
    form_name:   "Mega Feraligatr",
    type1_override: :WATER,
    type2_override: :DRAGON,
    base_stats_override: { HP: 85, ATTACK: 160, DEFENSE: 125, SPECIAL_ATTACK: 89, SPECIAL_DEFENSE: 93, SPEED: 78 },
    height:      2.3,
    weight:      108.8,
    pokedex:     "With its arms and hoodlike fin, this Pokémon forms a gigantic set of jaws with a bite 10 times as powerful as Feraligatr's actual jaws.",
    generation:  9,
  },

  # Mega Skarmory
  {
    id:          :SKARMORY_1,
    id_number:   1115,
    species:     :SKARMORY,
    form:        1,
    mega_stone:  :SKARMORITE,
    unmega_form: 0,
    form_name:   "Mega Skarmory",
    base_stats_override: { HP: 65, ATTACK: 140, DEFENSE: 110, SPECIAL_ATTACK: 40, SPECIAL_DEFENSE: 100, SPEED: 110 },
    weight:      40.4,
    pokedex:     "It flies faster than the speed of sound. After whipping up shock waves to send enemies flying, it finishes them off with its talons.",
    generation:  9,
  },

  # Mega Froslass  (Gen9 Pack lists CLEFABLITE in error; corrected to FROSLASSITE)
  {
    id:          :FROSLASS_1,
    id_number:   1116,
    species:     :FROSLASS,
    form:        1,
    mega_stone:  :FROSLASSITE,
    unmega_form: 0,
    form_name:   "Mega Froslass",
    base_stats_override: { HP: 70, ATTACK: 80, DEFENSE: 70, SPECIAL_ATTACK: 140, SPECIAL_DEFENSE: 100, SPEED: 120 },
    height:      2.6,
    weight:      29.6,
    pokedex:     "This Pokémon can use eerie cold air imbued with ghost energy to freeze even insubstantial things, such as flames or the wind.",
    generation:  9,
  },

  # Mega Scolipede
  {
    id:          :SCOLIPEDE_1,
    id_number:   1117,
    species:     :SCOLIPEDE,
    form:        1,
    mega_stone:  :SCOLIPITE,
    unmega_form: 0,
    form_name:   "Mega Scolipede",
    base_stats_override: { HP: 60, ATTACK: 140, DEFENSE: 149, SPECIAL_ATTACK: 75, SPECIAL_DEFENSE: 99, SPEED: 62 },
    height:      3.2,
    weight:      230.5,
    pokedex:     "Its deadly venom gives off a faint glow. The venom affects Scolipede's mind, honing its viciousness.",
    generation:  9,
  },

  # Mega Scrafty
  {
    id:          :SCRAFTY_1,
    id_number:   1118,
    species:     :SCRAFTY,
    form:        1,
    mega_stone:  :SCRAFTINITE,
    unmega_form: 0,
    form_name:   "Mega Scrafty",
    base_stats_override: { HP: 65, ATTACK: 130, DEFENSE: 135, SPECIAL_ATTACK: 55, SPECIAL_DEFENSE: 135, SPEED: 68 },
    weight:      31.0,
    pokedex:     "Mega Evolution has caused Scrafty's shed skin to turn white, growing tough and supple. Of course, this Pokémon is still as feisty as ever.",
    generation:  9,
  },

  # Mega Eelektross
  {
    id:          :EELEKTROSS_1,
    id_number:   1119,
    species:     :EELEKTROSS,
    form:        1,
    mega_stone:  :EELEKTROSSITE,
    unmega_form: 0,
    form_name:   "Mega Eelektross",
    base_stats_override: { HP: 85, ATTACK: 145, DEFENSE: 80, SPECIAL_ATTACK: 135, SPECIAL_DEFENSE: 90, SPEED: 80 },
    height:      3.0,
    weight:      180.0,
    pokedex:     "It now generates 10 times the electricity it did before Mega Evolving. It discharges this electricity from its false Eelektrik, which are made of mucus.",
    generation:  9,
  },

  # Mega Chandelure
  {
    id:          :CHANDELURE_1,
    id_number:   1120,
    species:     :CHANDELURE,
    form:        1,
    mega_stone:  :CHANDELURITE,
    unmega_form: 0,
    form_name:   "Mega Chandelure",
    base_stats_override: { HP: 60, ATTACK: 75, DEFENSE: 110, SPECIAL_ATTACK: 175, SPECIAL_DEFENSE: 110, SPEED: 90 },
    height:      2.5,
    weight:      69.6,
    pokedex:     "One of its eyes is a window linking our world with the afterlife. This Pokémon draws in hatred and converts it into power.",
    generation:  9,
  },

  # Mega Chesnaught
  {
    id:          :CHESNAUGHT_1,
    id_number:   1121,
    species:     :CHESNAUGHT,
    form:        1,
    mega_stone:  :CHESNAUGHTITE,
    unmega_form: 0,
    form_name:   "Mega Chesnaught",
    base_stats_override: { HP: 88, ATTACK: 137, DEFENSE: 172, SPECIAL_ATTACK: 74, SPECIAL_DEFENSE: 115, SPEED: 44 },
    pokedex:     "It has fortified armor and a will to defend at all costs. Both are absurdly strong.",
    generation:  9,
  },

  # Mega Delphox
  {
    id:          :DELPHOX_1,
    id_number:   1122,
    species:     :DELPHOX,
    form:        1,
    mega_stone:  :DELPHOXITE,
    unmega_form: 0,
    form_name:   "Mega Delphox",
    base_stats_override: { HP: 75, ATTACK: 69, DEFENSE: 72, SPECIAL_ATTACK: 159, SPECIAL_DEFENSE: 125, SPEED: 134 },
    pokedex:     "It wields flaming branches to dazzle its opponents before incinerating them with a huge fireball.",
    generation:  9,
  },

  # Mega Greninja
  {
    id:          :GRENINJA_3,
    id_number:   1123,
    species:     :GRENINJA,
    form:        3,
    mega_stone:  :GRENINJITE,
    unmega_form: 0,
    form_name:   "Mega Greninja",
    base_stats_override: { HP: 72, ATTACK: 125, DEFENSE: 77, SPECIAL_ATTACK: 133, SPECIAL_DEFENSE: 81, SPEED: 142 },
    pokedex:     "This Pokémon spins a giant shuriken at high speed to make it float, then clings to it upside down to catch opponents unawares.",
    generation:  9,
  },

  # Mega Pyroar
  {
    id:          :PYROAR_1,
    id_number:   1124,
    species:     :PYROAR,
    form:        1,
    mega_stone:  :PYROARITE,
    unmega_form: 0,
    form_name:   "Mega Pyroar",
    base_stats_override: { HP: 86, ATTACK: 88, DEFENSE: 92, SPECIAL_ATTACK: 129, SPECIAL_DEFENSE: 86, SPEED: 126 },
    weight:      93.3,
    pokedex:     "This Pokémon spews flames hotter than 18,000 degrees Fahrenheit. It swings around its grand, blazing mane as it protects its allies.",
    generation:  9,
  },

  # Mega Floette (Eternal)
  {
    id:          :FLOETTE_6,
    id_number:   1125,
    species:     :FLOETTE,
    form:        6,
    mega_stone:  :FLOETTITE,
    unmega_form: 0,
    form_name:   "Mega Floette",
    base_stats_override: { HP: 74, ATTACK: 85, DEFENSE: 87, SPECIAL_ATTACK: 155, SPECIAL_DEFENSE: 148, SPEED: 102 },
    weight:      100.8,
    pokedex:     "The Eternal Flower has absorbed all the energy from Mega Evolution. The flower now attacks enemies on its own.",
    generation:  9,
  },

  # Mega Barbaracle
  {
    id:          :BARBARACLE_1,
    id_number:   1126,
    species:     :BARBARACLE,
    form:        1,
    mega_stone:  :BARBARACITE,
    unmega_form: 0,
    form_name:   "Mega Barbaracle",
    type1_override: :ROCK,
    type2_override: :FIGHTING,
    base_stats_override: { HP: 72, ATTACK: 140, DEFENSE: 130, SPECIAL_ATTACK: 64, SPECIAL_DEFENSE: 106, SPEED: 88 },
    height:      2.2,
    weight:      100.0,
    pokedex:     "It uses its many arms to toy with its opponents. This keeps the head extremely busy.",
    generation:  9,
  },

  # Mega Dragalge
  {
    id:          :DRAGALGE_1,
    id_number:   1127,
    species:     :DRAGALGE,
    form:        1,
    mega_stone:  :DRAGALGITE,
    unmega_form: 0,
    form_name:   "Mega Dragalge",
    base_stats_override: { HP: 65, ATTACK: 85, DEFENSE: 105, SPECIAL_ATTACK: 132, SPECIAL_DEFENSE: 163, SPEED: 44 },
    height:      2.1,
    weight:      100.3,
    pokedex:     "It spits a liquid that causes the regenerative power of cells to run wild. The liquid is deadly poison to everything other than itself.",
    generation:  9,
  },

  # Mega Hawlucha
  {
    id:          :HAWLUCHA_1,
    id_number:   1128,
    species:     :HAWLUCHA,
    form:        1,
    mega_stone:  :HAWLUCHANITE,
    unmega_form: 0,
    form_name:   "Mega Hawlucha",
    base_stats_override: { HP: 78, ATTACK: 137, DEFENSE: 100, SPECIAL_ATTACK: 74, SPECIAL_DEFENSE: 93, SPEED: 118 },
    height:      1.0,
    weight:      25.0,
    pokedex:     "Mega Evolution has pumped up all its muscles. Hawlucha flexes to show off its strength.",
    generation:  9,
  },

  # Mega Zygarde (Complete form's mega variant)
  {
    id:          :ZYGARDE_5,
    id_number:   1129,
    species:     :ZYGARDE,
    form:        5,
    mega_stone:  :ZYGARDITE,
    unmega_form: 0,
    form_name:   "Mega Zygarde",
    base_stats_override: { HP: 216, ATTACK: 70, DEFENSE: 91, SPECIAL_ATTACK: 216, SPECIAL_DEFENSE: 85, SPEED: 100 },
    abilities_override: [:POWERCONSTRUCT],
    height:      7.7,
    weight:      610.0,
    generation:  9,
  },

  # Mega Drampa
  {
    id:          :DRAMPA_1,
    id_number:   1130,
    species:     :DRAMPA,
    form:        1,
    mega_stone:  :DRAMPANITE,
    unmega_form: 0,
    form_name:   "Mega Drampa",
    base_stats_override: { HP: 78, ATTACK: 85, DEFENSE: 110, SPECIAL_ATTACK: 160, SPECIAL_DEFENSE: 116, SPEED: 36 },
    weight:      240.5,
    pokedex:     "Drampa's cells have been invigorated, allowing it to regain its youth. It manipulates the atmosphere to summon storms.",
    generation:  9,
  },

  # Mega Raichu X
  {
    id:          :RAICHU_2,
    id_number:   1131,
    species:     :RAICHU,
    form:        2,
    mega_stone:  :RAICHUNITEX,
    unmega_form: 0,
    form_name:   "Mega Raichu X",
    base_stats_override: { HP: 60, ATTACK: 135, DEFENSE: 95, SPECIAL_ATTACK: 110, SPECIAL_DEFENSE: 90, SPEED: 95 },
    height:      1.2,
    weight:      38.0,
    pokedex:     "It resembles an X as it flies through the air with 50 million volts of electricity sparking from its ears and forked tail.",
    generation:  9,
  },

  # Mega Raichu Y
  {
    id:          :RAICHU_3,
    id_number:   1132,
    species:     :RAICHU,
    form:        3,
    mega_stone:  :RAICHUNITEY,
    unmega_form: 0,
    form_name:   "Mega Raichu Y",
    base_stats_override: { HP: 60, ATTACK: 135, DEFENSE: 95, SPECIAL_ATTACK: 110, SPECIAL_DEFENSE: 90, SPEED: 95 },
    height:      1.0,
    weight:      26.0,
    pokedex:     "It fires bolts of electricity from the tip of its tail and from the spiky tufts of fur growing out of its temples. This electricity forms the letter Y.",
    generation:  9,
  },

  # Mega Absol Z
  {
    id:          :ABSOL_2,
    id_number:   1133,
    species:     :ABSOL,
    form:        2,
    mega_stone:  :ABSOLITEZ,
    unmega_form: 0,
    form_name:   "Mega Absol Z",
    type1_override: :DARK,
    type2_override: :GHOST,
    base_stats_override: { HP: 65, ATTACK: 154, DEFENSE: 60, SPECIAL_ATTACK: 151, SPECIAL_DEFENSE: 75, SPEED: 60 },
    height:      1.0,
    weight:      26.0,
    pokedex:     "Using fur that it has made into sharp, clawlike shapes, it cuts down foes with a single blow. This is an act of kindness to keep them from suffering.",
    generation:  9,
  },

  # Mega Staraptor
  {
    id:          :STARAPTOR_1,
    id_number:   1134,
    species:     :STARAPTOR,
    form:        1,
    mega_stone:  :STARAPTITE,
    unmega_form: 0,
    form_name:   "Mega Staraptor",
    type1_override: :FIGHTING,
    type2_override: :FLYING,
    base_stats_override: { HP: 85, ATTACK: 140, DEFENSE: 100, SPECIAL_ATTACK: 110, SPECIAL_DEFENSE: 60, SPEED: 90 },
    height:      1.9,
    weight:      50.0,
    pokedex:     "Mega Staraptor is a top-class flier. It can easily soar through the sky while gripping a Steelix that weighs more than 880 lbs.",
    generation:  9,
  },

  # Mega Garchomp Z
  {
    id:          :GARCHOMP_2,
    id_number:   1135,
    species:     :GARCHOMP,
    form:        2,
    mega_stone:  :GARCHOMPITEZ,
    unmega_form: 0,
    form_name:   "Mega Garchomp Z",
    type1_override: :DRAGON,
    type2_override: nil,
    base_stats_override: { HP: 108, ATTACK: 130, DEFENSE: 85, SPECIAL_ATTACK: 151, SPECIAL_DEFENSE: 141, SPEED: 85 },
    weight:      99.0,
    pokedex:     "Garchomp has gained a new Mega-Evolved form. It flies around foes at Mach speed and cuts them to shreds with its sinister wing claws.",
    generation:  9,
  },

  # Mega Lucario Z
  {
    id:          :LUCARIO_2,
    id_number:   1136,
    species:     :LUCARIO,
    form:        2,
    mega_stone:  :LUCARIONITEZ,
    unmega_form: 0,
    form_name:   "Mega Lucario Z",
    base_stats_override: { HP: 70, ATTACK: 100, DEFENSE: 70, SPECIAL_ATTACK: 151, SPECIAL_DEFENSE: 164, SPEED: 70 },
    height:      1.3,
    weight:      49.4,
    pokedex:     "By completely cloaking itself in its aura, Mega Lucario Z can parry all manner of attacks, battling as if it were gracefully dancing.",
    generation:  9,
  },

  # Mega Heatran
  {
    id:          :HEATRAN_1,
    id_number:   1137,
    species:     :HEATRAN,
    form:        1,
    mega_stone:  :HEATRANITE,
    unmega_form: 0,
    form_name:   "Mega Heatran",
    base_stats_override: { HP: 91, ATTACK: 120, DEFENSE: 106, SPECIAL_ATTACK: 67, SPECIAL_DEFENSE: 175, SPEED: 141 },
    height:      2.8,
    weight:      570.0,
    pokedex:     "It's said that if it goes all out, it can heat its body up to temperatures over 1.8 million degrees Fahrenheit. This heat keeps enemies at bay.",
    generation:  9,
  },

  # Mega Darkrai
  {
    id:          :DARKRAI_1,
    id_number:   1138,
    species:     :DARKRAI,
    form:        1,
    mega_stone:  :DARKRANITE,
    unmega_form: 0,
    form_name:   "Mega Darkrai",
    base_stats_override: { HP: 70, ATTACK: 120, DEFENSE: 130, SPECIAL_ATTACK: 85, SPECIAL_DEFENSE: 165, SPEED: 130 },
    height:      3.0,
    weight:      240.0,
    pokedex:     "Its dark power blocks out the sun, plunging the surrounding area into darkness. There is no escaping its evil eye.",
    generation:  9,
  },

  # Mega Golurk
  {
    id:          :GOLURK_1,
    id_number:   1139,
    species:     :GOLURK,
    form:        1,
    mega_stone:  :GOLURKITE,
    unmega_form: 0,
    form_name:   "Mega Golurk",
    base_stats_override: { HP: 89, ATTACK: 159, DEFENSE: 105, SPECIAL_ATTACK: 55, SPECIAL_DEFENSE: 70, SPEED: 105 },
    height:      4.0,
    weight:      330.0,
    pokedex:     "The energy within Golurk has been stimulated by Mega Evolution. The Pokémon could explode at any moment.",
    generation:  9,
  },

  # Mega Meowstic (Male Mega)
  {
    id:          :MEOWSTIC_2,
    id_number:   1140,
    species:     :MEOWSTIC,
    form:        2,
    mega_stone:  :MEOWSTICITE,
    unmega_form: 0,
    form_name:   "Mega Meowstic",
    base_stats_override: { HP: 74, ATTACK: 48, DEFENSE: 76, SPECIAL_ATTACK: 124, SPECIAL_DEFENSE: 143, SPEED: 101 },
    height:      0.8,
    weight:      10.1,
    pokedex:     "Mega Meowstic can use its psychic power to compress or expand anything. It overwhelms foes by contorting space itself.",
    generation:  9,
  },

  # Mega Meowstic (Female Mega)
  {
    id:          :MEOWSTIC_3,
    id_number:   1141,
    species:     :MEOWSTIC,
    form:        3,
    mega_stone:  :MEOWSTICITE,
    unmega_form: 0,
    form_name:   "Mega Meowstic",
    base_stats_override: { HP: 74, ATTACK: 48, DEFENSE: 76, SPECIAL_ATTACK: 124, SPECIAL_DEFENSE: 143, SPEED: 101 },
    height:      0.8,
    weight:      10.1,
    pokedex:     "Mega Meowstic can use its psychic power to compress or expand anything. It overwhelms foes by contorting space itself.",
    generation:  9,
  },

  # Mega Crabominable
  {
    id:          :CRABOMINABLE_1,
    id_number:   1142,
    species:     :CRABOMINABLE,
    form:        1,
    mega_stone:  :CRABOMINITE,
    unmega_form: 0,
    form_name:   "Mega Crabominable",
    base_stats_override: { HP: 97, ATTACK: 157, DEFENSE: 122, SPECIAL_ATTACK: 33, SPECIAL_DEFENSE: 62, SPEED: 107 },
    height:      2.6,
    weight:      252.8,
    pokedex:     "It can pulverize reinforced concrete with a light swing of one of its fists, each of which is covered in a thick layer of ice.",
    generation:  9,
  },

  # Mega Golisopod
  {
    id:          :GOLISOPOD_1,
    id_number:   1143,
    species:     :GOLISOPOD,
    form:        1,
    mega_stone:  :GOLISOPITE,
    unmega_form: 0,
    form_name:   "Mega Golisopod",
    type1_override: :BUG,
    type2_override: :STEEL,
    base_stats_override: { HP: 75, ATTACK: 150, DEFENSE: 175, SPECIAL_ATTACK: 40, SPECIAL_DEFENSE: 70, SPEED: 120 },
    height:      2.3,
    weight:      148.0,
    pokedex:     "It uses four of its arms to fiercely assail its foes. Once they've been pushed to the brink of defeat, it finishes them off with the arms it kept hidden.",
    generation:  9,
  },

  # Mega Magearna (Original Color)
  {
    id:          :MAGEARNA_2,
    id_number:   1144,
    species:     :MAGEARNA,
    form:        2,
    mega_stone:  :MAGEARNITE,
    unmega_form: 0,
    form_name:   "Mega Magearna (Original Color)",
    base_stats_override: { HP: 80, ATTACK: 125, DEFENSE: 115, SPECIAL_ATTACK: 95, SPECIAL_DEFENSE: 170, SPEED: 115 },
    height:      1.3,
    weight:      248.1,
    pokedex:     "This is Magearna once a previously hidden mode activates. The emotions Magearna had begun to feel now hide away as it fells foe after foe.",
    generation:  9,
  },

  # Mega Magearna
  {
    id:          :MAGEARNA_3,
    id_number:   1145,
    species:     :MAGEARNA,
    form:        3,
    mega_stone:  :MAGEARNITE,
    unmega_form: 0,
    form_name:   "Mega Magearna",
    base_stats_override: { HP: 80, ATTACK: 125, DEFENSE: 115, SPECIAL_ATTACK: 95, SPECIAL_DEFENSE: 170, SPEED: 115 },
    height:      1.3,
    weight:      248.1,
    pokedex:     "A mechanism to remove Magearna's limitations has lain secretly within it for 500 years. This mechanism is triggered by a Mega Stone.",
    generation:  9,
  },

  # Mega Zeraora
  {
    id:          :ZERAORA_1,
    id_number:   1146,
    species:     :ZERAORA,
    form:        1,
    mega_stone:  :ZERAORITE,
    unmega_form: 0,
    form_name:   "Mega Zeraora",
    base_stats_override: { HP: 88, ATTACK: 157, DEFENSE: 75, SPECIAL_ATTACK: 153, SPECIAL_DEFENSE: 147, SPEED: 80 },
    height:      1.5,
    weight:      44.5,
    pokedex:     "It stores up 10 lightning strikes' worth of electricity. When it stops limiting itself, it's in the strongest class of electric Pokémon.",
    generation:  9,
  },

  # Mega Scovillain
  {
    id:          :SCOVILLAIN_1,
    id_number:   1147,
    species:     :SCOVILLAIN,
    form:        1,
    mega_stone:  :SCOVILLAINITE,
    unmega_form: 0,
    form_name:   "Mega Scovillain",
    base_stats_override: { HP: 65, ATTACK: 138, DEFENSE: 85, SPECIAL_ATTACK: 75, SPECIAL_DEFENSE: 138, SPEED: 85 },
    height:      1.2,
    weight:      22.0,
    pokedex:     "Mega Evolution has dialed up this Pokémon's spiciness. It swings its \"necktie\" around to wallop its foes.",
    generation:  9,
  },

  # Mega Glimmora
  {
    id:          :GLIMMORA_1,
    id_number:   1148,
    species:     :GLIMMORA,
    form:        1,
    mega_stone:  :GLIMMORANITE,
    unmega_form: 0,
    form_name:   "Mega Glimmora",
    base_stats_override: { HP: 83, ATTACK: 90, DEFENSE: 105, SPECIAL_ATTACK: 101, SPECIAL_DEFENSE: 150, SPEED: 96 },
    height:      2.8,
    weight:      77.0,
    pokedex:     "Glimmora's petals—now larger and separated from its main body—rotate around it to provide defense while scattering poisonous fragments.",
    generation:  9,
  },

  # Mega Tatsugiri (Curly Mega)
  {
    id:          :TATSUGIRI_3,
    id_number:   1149,
    species:     :TATSUGIRI,
    form:        3,
    mega_stone:  :TATSUGIRINITE,
    unmega_form: 0,
    form_name:   "Mega Tatsugiri (Curly Form)",
    base_stats_override: { HP: 68, ATTACK: 65, DEFENSE: 90, SPECIAL_ATTACK: 92, SPECIAL_DEFENSE: 135, SPEED: 125 },
    height:      0.6,
    weight:      24.0,
    pokedex:     "Tatsugiri's brain has been invigorated by Mega Evolution, making it even wilier. It can create and command copies of itself.",
    generation:  9,
  },

  # Mega Tatsugiri (Droopy Mega)
  {
    id:          :TATSUGIRI_4,
    id_number:   1150,
    species:     :TATSUGIRI,
    form:        4,
    mega_stone:  :TATSUGIRINITE,
    unmega_form: 0,
    form_name:   "Mega Tatsugiri (Droopy Form)",
    base_stats_override: { HP: 68, ATTACK: 65, DEFENSE: 90, SPECIAL_ATTACK: 92, SPECIAL_DEFENSE: 135, SPEED: 125 },
    height:      0.6,
    weight:      24.0,
    pokedex:     "It solidifies the energy of Mega Evolution, building up an overflowing pile to launch as projectiles. These projectiles explode on contact.",
    generation:  9,
  },

  # Mega Tatsugiri (Stretchy Mega)
  {
    id:          :TATSUGIRI_5,
    id_number:   1151,
    species:     :TATSUGIRI,
    form:        5,
    mega_stone:  :TATSUGIRINITE,
    unmega_form: 0,
    form_name:   "Mega Tatsugiri (Stretchy Form)",
    base_stats_override: { HP: 68, ATTACK: 65, DEFENSE: 90, SPECIAL_ATTACK: 92, SPECIAL_DEFENSE: 135, SPEED: 125 },
    height:      0.6,
    weight:      24.0,
    pokedex:     "Using the energy of Mega Evolution, it creates a dish to ride upon, allowing it to move with total freedom—even through the air.",
    generation:  9,
  },

  # Mega Baxcalibur
  {
    id:          :BAXCALIBUR_1,
    id_number:   1152,
    species:     :BAXCALIBUR,
    form:        1,
    mega_stone:  :BAXCALIBRITE,
    unmega_form: 0,
    form_name:   "Mega Baxcalibur",
    base_stats_override: { HP: 115, ATTACK: 175, DEFENSE: 117, SPECIAL_ATTACK: 87, SPECIAL_DEFENSE: 105, SPEED: 101 },
    height:      2.1,
    weight:      315.0,
    pokedex:     "Baxcalibur's dorsal blade has grown even more massive thanks to Mega Evolution. This Pokémon fires beams from the hilt at its solar plexus.",
    generation:  9,
  },

  # ─── Official Gen 6-7 Mega Species (42 forms, IDs 1153-1194) ───
  # Mega Venusaur
  {
    id:          :VENUSAUR_1,
    id_number:   1153,
    species:     :VENUSAUR,
    form:        1,
    mega_stone:  :VENUSAURITE,
    unmega_form: 0,
    form_name:   "Mega Venusaur",
    type1_override: :GRASS,
    type2_override: :POISON,
    base_stats_override: { HP: 80, ATTACK: 100, DEFENSE: 123, SPECIAL_ATTACK: 122, SPECIAL_DEFENSE: 120, SPEED: 80 },
    abilities_override: [:THICKFAT],
    height:      24,
    weight:      1555,
    generation:  6,
  },

  # Mega Charizard X
  {
    id:          :CHARIZARD_1,
    id_number:   1154,
    species:     :CHARIZARD,
    form:        1,
    mega_stone:  :CHARIZARDITEX,
    unmega_form: 0,
    form_name:   "Mega Charizard X",
    type1_override: :FIRE,
    type2_override: :DRAGON,
    base_stats_override: { HP: 78, ATTACK: 130, DEFENSE: 111, SPECIAL_ATTACK: 130, SPECIAL_DEFENSE: 85, SPEED: 100 },
    abilities_override: [:TOUGHCLAWS],
    height:      17,
    weight:      1105,
    generation:  6,
  },

  # Mega Charizard Y
  {
    id:          :CHARIZARD_2,
    id_number:   1155,
    species:     :CHARIZARD,
    form:        2,
    mega_stone:  :CHARIZARDITEY,
    unmega_form: 0,
    form_name:   "Mega Charizard Y",
    type1_override: :FIRE,
    type2_override: :FLYING,
    base_stats_override: { HP: 78, ATTACK: 104, DEFENSE: 78, SPECIAL_ATTACK: 159, SPECIAL_DEFENSE: 115, SPEED: 100 },
    abilities_override: [:DROUGHT],
    height:      17,
    weight:      1005,
    generation:  6,
  },

  # Mega Blastoise
  {
    id:          :BLASTOISE_1,
    id_number:   1156,
    species:     :BLASTOISE,
    form:        1,
    mega_stone:  :BLASTOISINITE,
    unmega_form: 0,
    form_name:   "Mega Blastoise",
    base_stats_override: { HP: 79, ATTACK: 103, DEFENSE: 120, SPECIAL_ATTACK: 135, SPECIAL_DEFENSE: 115, SPEED: 78 },
    abilities_override: [:MEGALAUNCHER],
    height:      16,
    weight:      1011,
    generation:  6,
  },

  # Mega Alakazam
  {
    id:          :ALAKAZAM_1,
    id_number:   1157,
    species:     :ALAKAZAM,
    form:        1,
    mega_stone:  :ALAKAZITE,
    unmega_form: 0,
    form_name:   "Mega Alakazam",
    base_stats_override: { HP: 55, ATTACK: 50, DEFENSE: 65, SPECIAL_ATTACK: 175, SPECIAL_DEFENSE: 105, SPEED: 150 },
    abilities_override: [:TRACE],
    height:      12,
    weight:      480,
    generation:  6,
  },

  # Mega Gengar
  {
    id:          :GENGAR_1,
    id_number:   1158,
    species:     :GENGAR,
    form:        1,
    mega_stone:  :GENGARITE,
    unmega_form: 0,
    form_name:   "Mega Gengar",
    type1_override: :GHOST,
    type2_override: :POISON,
    base_stats_override: { HP: 60, ATTACK: 65, DEFENSE: 80, SPECIAL_ATTACK: 170, SPECIAL_DEFENSE: 95, SPEED: 130 },
    abilities_override: [:SHADOWTAG],
    height:      14,
    weight:      405,
    generation:  6,
  },

  # Mega Kangaskhan
  {
    id:          :KANGASKHAN_1,
    id_number:   1159,
    species:     :KANGASKHAN,
    form:        1,
    mega_stone:  :KANGASKHANITE,
    unmega_form: 0,
    form_name:   "Mega Kangaskhan",
    base_stats_override: { HP: 105, ATTACK: 125, DEFENSE: 100, SPECIAL_ATTACK: 60, SPECIAL_DEFENSE: 100, SPEED: 100 },
    abilities_override: [:PARENTALBOND],
    height:      22,
    weight:      1000,
    generation:  6,
  },

  # Mega Pinsir
  {
    id:          :PINSIR_1,
    id_number:   1160,
    species:     :PINSIR,
    form:        1,
    mega_stone:  :PINSIRITE,
    unmega_form: 0,
    form_name:   "Mega Pinsir",
    type1_override: :BUG,
    type2_override: :FLYING,
    base_stats_override: { HP: 65, ATTACK: 155, DEFENSE: 120, SPECIAL_ATTACK: 65, SPECIAL_DEFENSE: 90, SPEED: 105 },
    abilities_override: [:AERILATE],
    height:      17,
    weight:      590,
    generation:  6,
  },

  # Mega Gyarados
  {
    id:          :GYARADOS_1,
    id_number:   1161,
    species:     :GYARADOS,
    form:        1,
    mega_stone:  :GYARADOSITE,
    unmega_form: 0,
    form_name:   "Mega Gyarados",
    type1_override: :WATER,
    type2_override: :DARK,
    base_stats_override: { HP: 95, ATTACK: 155, DEFENSE: 109, SPECIAL_ATTACK: 70, SPECIAL_DEFENSE: 130, SPEED: 81 },
    abilities_override: [:MOLDBREAKER],
    height:      65,
    weight:      3050,
    generation:  6,
  },

  # Mega Aerodactyl
  {
    id:          :AERODACTYL_1,
    id_number:   1162,
    species:     :AERODACTYL,
    form:        1,
    mega_stone:  :AERODACTYLITE,
    unmega_form: 0,
    form_name:   "Mega Aerodactyl",
    type1_override: :ROCK,
    type2_override: :FLYING,
    base_stats_override: { HP: 80, ATTACK: 135, DEFENSE: 85, SPECIAL_ATTACK: 70, SPECIAL_DEFENSE: 95, SPEED: 150 },
    abilities_override: [:TOUGHCLAWS],
    height:      21,
    weight:      790,
    generation:  6,
  },

  # Mega Mewtwo X
  {
    id:          :MEWTWO_1,
    id_number:   1163,
    species:     :MEWTWO,
    form:        1,
    mega_stone:  :MEWTWONITEX,
    unmega_form: 0,
    form_name:   "Mega Mewtwo X",
    type1_override: :PSYCHIC,
    type2_override: :FIGHTING,
    base_stats_override: { HP: 106, ATTACK: 190, DEFENSE: 100, SPECIAL_ATTACK: 154, SPECIAL_DEFENSE: 100, SPEED: 130 },
    abilities_override: [:STEADFAST],
    height:      23,
    weight:      1270,
    generation:  6,
  },

  # Mega Mewtwo Y
  {
    id:          :MEWTWO_2,
    id_number:   1164,
    species:     :MEWTWO,
    form:        2,
    mega_stone:  :MEWTWONITEY,
    unmega_form: 0,
    form_name:   "Mega Mewtwo Y",
    base_stats_override: { HP: 106, ATTACK: 150, DEFENSE: 70, SPECIAL_ATTACK: 194, SPECIAL_DEFENSE: 120, SPEED: 140 },
    abilities_override: [:INSOMNIA],
    height:      15,
    weight:      330,
    generation:  6,
  },

  # Mega Ampharos
  {
    id:          :AMPHAROS_1,
    id_number:   1165,
    species:     :AMPHAROS,
    form:        1,
    mega_stone:  :AMPHAROSITE,
    unmega_form: 0,
    form_name:   "Mega Ampharos",
    type1_override: :ELECTRIC,
    type2_override: :DRAGON,
    base_stats_override: { HP: 90, ATTACK: 95, DEFENSE: 105, SPECIAL_ATTACK: 165, SPECIAL_DEFENSE: 110, SPEED: 45 },
    abilities_override: [:MOLDBREAKER],
    height:      14,
    weight:      615,
    generation:  6,
  },

  # Mega Scizor
  {
    id:          :SCIZOR_1,
    id_number:   1166,
    species:     :SCIZOR,
    form:        1,
    mega_stone:  :SCIZORITE,
    unmega_form: 0,
    form_name:   "Mega Scizor",
    type1_override: :BUG,
    type2_override: :STEEL,
    base_stats_override: { HP: 70, ATTACK: 150, DEFENSE: 140, SPECIAL_ATTACK: 65, SPECIAL_DEFENSE: 100, SPEED: 75 },
    abilities_override: [:TECHNICIAN],
    height:      20,
    weight:      1250,
    generation:  6,
  },

  # Mega Heracross
  {
    id:          :HERACROSS_1,
    id_number:   1167,
    species:     :HERACROSS,
    form:        1,
    mega_stone:  :HERACRONITE,
    unmega_form: 0,
    form_name:   "Mega Heracross",
    type1_override: :BUG,
    type2_override: :FIGHTING,
    base_stats_override: { HP: 80, ATTACK: 185, DEFENSE: 115, SPECIAL_ATTACK: 40, SPECIAL_DEFENSE: 105, SPEED: 75 },
    abilities_override: [:SKILLLINK],
    height:      17,
    weight:      625,
    generation:  6,
  },

  # Mega Houndoom
  {
    id:          :HOUNDOOM_1,
    id_number:   1168,
    species:     :HOUNDOOM,
    form:        1,
    mega_stone:  :HOUNDOOMINITE,
    unmega_form: 0,
    form_name:   "Mega Houndoom",
    type1_override: :DARK,
    type2_override: :FIRE,
    base_stats_override: { HP: 75, ATTACK: 90, DEFENSE: 90, SPECIAL_ATTACK: 140, SPECIAL_DEFENSE: 90, SPEED: 115 },
    abilities_override: [:SOLARPOWER],
    height:      19,
    weight:      495,
    generation:  6,
  },

  # Mega Tyranitar
  {
    id:          :TYRANITAR_1,
    id_number:   1169,
    species:     :TYRANITAR,
    form:        1,
    mega_stone:  :TYRANITARITE,
    unmega_form: 0,
    form_name:   "Mega Tyranitar",
    type1_override: :ROCK,
    type2_override: :DARK,
    base_stats_override: { HP: 100, ATTACK: 164, DEFENSE: 150, SPECIAL_ATTACK: 95, SPECIAL_DEFENSE: 120, SPEED: 71 },
    abilities_override: [:SANDSTREAM],
    height:      25,
    weight:      2550,
    generation:  6,
  },

  # Mega Blaziken
  {
    id:          :BLAZIKEN_1,
    id_number:   1170,
    species:     :BLAZIKEN,
    form:        1,
    mega_stone:  :BLAZIKENITE,
    unmega_form: 0,
    form_name:   "Mega Blaziken",
    type1_override: :FIRE,
    type2_override: :FIGHTING,
    base_stats_override: { HP: 80, ATTACK: 160, DEFENSE: 80, SPECIAL_ATTACK: 130, SPECIAL_DEFENSE: 80, SPEED: 100 },
    abilities_override: [:SPEEDBOOST],
    height:      19,
    weight:      520,
    generation:  6,
  },

  # Mega Gardevoir
  {
    id:          :GARDEVOIR_1,
    id_number:   1171,
    species:     :GARDEVOIR,
    form:        1,
    mega_stone:  :GARDEVOIRITE,
    unmega_form: 0,
    form_name:   "Mega Gardevoir",
    type1_override: :PSYCHIC,
    type2_override: :FAIRY,
    base_stats_override: { HP: 68, ATTACK: 85, DEFENSE: 65, SPECIAL_ATTACK: 165, SPECIAL_DEFENSE: 135, SPEED: 100 },
    abilities_override: [:PIXILATE],
    height:      16,
    weight:      484,
    generation:  6,
  },

  # Mega Mawile
  {
    id:          :MAWILE_1,
    id_number:   1172,
    species:     :MAWILE,
    form:        1,
    mega_stone:  :MAWILITE,
    unmega_form: 0,
    form_name:   "Mega Mawile",
    type1_override: :STEEL,
    type2_override: :FAIRY,
    base_stats_override: { HP: 50, ATTACK: 105, DEFENSE: 125, SPECIAL_ATTACK: 55, SPECIAL_DEFENSE: 95, SPEED: 50 },
    abilities_override: [:HUGEPOWER],
    height:      10,
    weight:      235,
    generation:  6,
  },

  # Mega Aggron
  {
    id:          :AGGRON_1,
    id_number:   1173,
    species:     :AGGRON,
    form:        1,
    mega_stone:  :AGGRONITE,
    unmega_form: 0,
    form_name:   "Mega Aggron",
    base_stats_override: { HP: 70, ATTACK: 140, DEFENSE: 230, SPECIAL_ATTACK: 60, SPECIAL_DEFENSE: 80, SPEED: 50 },
    abilities_override: [:FILTER],
    height:      22,
    weight:      3950,
    generation:  6,
  },

  # Mega Banette
  {
    id:          :BANETTE_1,
    id_number:   1174,
    species:     :BANETTE,
    form:        1,
    mega_stone:  :BANETTITE,
    unmega_form: 0,
    form_name:   "Mega Banette",
    base_stats_override: { HP: 64, ATTACK: 165, DEFENSE: 75, SPECIAL_ATTACK: 93, SPECIAL_DEFENSE: 83, SPEED: 75 },
    abilities_override: [:PRANKSTER],
    height:      12,
    weight:      130,
    generation:  6,
  },

  # Mega Garchomp
  {
    id:          :GARCHOMP_1,
    id_number:   1175,
    species:     :GARCHOMP,
    form:        1,
    mega_stone:  :GARCHOMPITE,
    unmega_form: 0,
    form_name:   "Mega Garchomp",
    type1_override: :DRAGON,
    type2_override: :GROUND,
    base_stats_override: { HP: 108, ATTACK: 170, DEFENSE: 115, SPECIAL_ATTACK: 120, SPECIAL_DEFENSE: 95, SPEED: 92 },
    abilities_override: [:SANDFORCE],
    height:      19,
    weight:      950,
    generation:  6,
  },

  # Mega Lucario
  {
    id:          :LUCARIO_1,
    id_number:   1176,
    species:     :LUCARIO,
    form:        1,
    mega_stone:  :LUCARIONITE,
    unmega_form: 0,
    form_name:   "Mega Lucario",
    type1_override: :FIGHTING,
    type2_override: :STEEL,
    base_stats_override: { HP: 70, ATTACK: 145, DEFENSE: 88, SPECIAL_ATTACK: 140, SPECIAL_DEFENSE: 70, SPEED: 112 },
    abilities_override: [:ADAPTABILITY],
    height:      13,
    weight:      575,
    generation:  6,
  },

  # Mega Latias
  {
    id:          :LATIAS_1,
    id_number:   1177,
    species:     :LATIAS,
    form:        1,
    mega_stone:  :LATIASITE,
    unmega_form: 0,
    form_name:   "Mega Latias",
    type1_override: :DRAGON,
    type2_override: :PSYCHIC,
    base_stats_override: { HP: 80, ATTACK: 100, DEFENSE: 120, SPECIAL_ATTACK: 140, SPECIAL_DEFENSE: 150, SPEED: 110 },
    abilities_override: [:LEVITATE],
    height:      18,
    weight:      520,
    generation:  6,
  },

  # Mega Latios
  {
    id:          :LATIOS_1,
    id_number:   1178,
    species:     :LATIOS,
    form:        1,
    mega_stone:  :LATIOSITE,
    unmega_form: 0,
    form_name:   "Mega Latios",
    type1_override: :DRAGON,
    type2_override: :PSYCHIC,
    base_stats_override: { HP: 80, ATTACK: 130, DEFENSE: 100, SPECIAL_ATTACK: 160, SPECIAL_DEFENSE: 120, SPEED: 110 },
    abilities_override: [:LEVITATE],
    height:      23,
    weight:      700,
    generation:  6,
  },

  # Mega Swampert
  {
    id:          :SWAMPERT_1,
    id_number:   1179,
    species:     :SWAMPERT,
    form:        1,
    mega_stone:  :SWAMPERTITE,
    unmega_form: 0,
    form_name:   "Mega Swampert",
    type1_override: :WATER,
    type2_override: :GROUND,
    base_stats_override: { HP: 100, ATTACK: 150, DEFENSE: 110, SPECIAL_ATTACK: 95, SPECIAL_DEFENSE: 110, SPEED: 70 },
    abilities_override: [:SWIFTSWIM],
    height:      19,
    weight:      1020,
    generation:  6,
  },

  # Mega Sceptile
  {
    id:          :SCEPTILE_1,
    id_number:   1180,
    species:     :SCEPTILE,
    form:        1,
    mega_stone:  :SCEPTILITE,
    unmega_form: 0,
    form_name:   "Mega Sceptile",
    type1_override: :GRASS,
    type2_override: :DRAGON,
    base_stats_override: { HP: 70, ATTACK: 110, DEFENSE: 75, SPECIAL_ATTACK: 145, SPECIAL_DEFENSE: 85, SPEED: 145 },
    abilities_override: [:LIGHTNINGROD],
    height:      19,
    weight:      552,
    generation:  6,
  },

  # Mega Sableye
  {
    id:          :SABLEYE_1,
    id_number:   1181,
    species:     :SABLEYE,
    form:        1,
    mega_stone:  :SABLENITE,
    unmega_form: 0,
    form_name:   "Mega Sableye",
    type1_override: :DARK,
    type2_override: :GHOST,
    base_stats_override: { HP: 50, ATTACK: 85, DEFENSE: 125, SPECIAL_ATTACK: 85, SPECIAL_DEFENSE: 115, SPEED: 20 },
    abilities_override: [:MAGICBOUNCE],
    height:      5,
    weight:      1610,
    generation:  6,
  },

  # Mega Altaria
  {
    id:          :ALTARIA_1,
    id_number:   1182,
    species:     :ALTARIA,
    form:        1,
    mega_stone:  :ALTARIANITE,
    unmega_form: 0,
    form_name:   "Mega Altaria",
    type1_override: :DRAGON,
    type2_override: :FAIRY,
    base_stats_override: { HP: 75, ATTACK: 110, DEFENSE: 110, SPECIAL_ATTACK: 110, SPECIAL_DEFENSE: 105, SPEED: 80 },
    abilities_override: [:PIXILATE],
    height:      15,
    weight:      206,
    generation:  6,
  },

  # Mega Gallade
  {
    id:          :GALLADE_1,
    id_number:   1183,
    species:     :GALLADE,
    form:        1,
    mega_stone:  :GALLADITE,
    unmega_form: 0,
    form_name:   "Mega Gallade",
    type1_override: :PSYCHIC,
    type2_override: :FIGHTING,
    base_stats_override: { HP: 68, ATTACK: 165, DEFENSE: 95, SPECIAL_ATTACK: 65, SPECIAL_DEFENSE: 115, SPEED: 110 },
    abilities_override: [:INNERFOCUS],
    height:      16,
    weight:      564,
    generation:  6,
  },

  # Mega Sharpedo
  {
    id:          :SHARPEDO_1,
    id_number:   1184,
    species:     :SHARPEDO,
    form:        1,
    mega_stone:  :SHARPEDONITE,
    unmega_form: 0,
    form_name:   "Mega Sharpedo",
    type1_override: :WATER,
    type2_override: :DARK,
    base_stats_override: { HP: 70, ATTACK: 140, DEFENSE: 70, SPECIAL_ATTACK: 110, SPECIAL_DEFENSE: 65, SPEED: 105 },
    abilities_override: [:STRONGJAW],
    height:      25,
    weight:      1303,
    generation:  6,
  },

  # Mega Slowbro
  {
    id:          :SLOWBRO_1,
    id_number:   1185,
    species:     :SLOWBRO,
    form:        1,
    mega_stone:  :SLOWBRONITE,
    unmega_form: 0,
    form_name:   "Mega Slowbro",
    type1_override: :WATER,
    type2_override: :PSYCHIC,
    base_stats_override: { HP: 95, ATTACK: 75, DEFENSE: 180, SPECIAL_ATTACK: 130, SPECIAL_DEFENSE: 80, SPEED: 30 },
    abilities_override: [:SHELLARMOR],
    height:      20,
    weight:      1200,
    generation:  6,
  },

  # Mega Steelix
  {
    id:          :STEELIX_1,
    id_number:   1186,
    species:     :STEELIX,
    form:        1,
    mega_stone:  :STEELIXITE,
    unmega_form: 0,
    form_name:   "Mega Steelix",
    type1_override: :STEEL,
    type2_override: :GROUND,
    base_stats_override: { HP: 75, ATTACK: 125, DEFENSE: 230, SPECIAL_ATTACK: 55, SPECIAL_DEFENSE: 95, SPEED: 30 },
    abilities_override: [:SANDFORCE],
    height:      105,
    weight:      7400,
    generation:  6,
  },

  # Mega Pidgeot
  {
    id:          :PIDGEOT_1,
    id_number:   1187,
    species:     :PIDGEOT,
    form:        1,
    mega_stone:  :PIDGEOTITE,
    unmega_form: 0,
    form_name:   "Mega Pidgeot",
    type1_override: :NORMAL,
    type2_override: :FLYING,
    base_stats_override: { HP: 83, ATTACK: 80, DEFENSE: 80, SPECIAL_ATTACK: 135, SPECIAL_DEFENSE: 80, SPEED: 121 },
    abilities_override: [:NOGUARD],
    height:      22,
    weight:      505,
    generation:  6,
  },

  # Mega Glalie
  {
    id:          :GLALIE_1,
    id_number:   1188,
    species:     :GLALIE,
    form:        1,
    mega_stone:  :GLALITITE,
    unmega_form: 0,
    form_name:   "Mega Glalie",
    base_stats_override: { HP: 80, ATTACK: 120, DEFENSE: 80, SPECIAL_ATTACK: 120, SPECIAL_DEFENSE: 80, SPEED: 100 },
    abilities_override: [:REFRIGERATE],
    height:      21,
    weight:      3502,
    generation:  6,
  },

  # Mega Diancie
  {
    id:          :DIANCIE_1,
    id_number:   1189,
    species:     :DIANCIE,
    form:        1,
    mega_stone:  :DIANCITE,
    unmega_form: 0,
    form_name:   "Mega Diancie",
    type1_override: :ROCK,
    type2_override: :FAIRY,
    base_stats_override: { HP: 50, ATTACK: 160, DEFENSE: 110, SPECIAL_ATTACK: 160, SPECIAL_DEFENSE: 110, SPEED: 110 },
    abilities_override: [:MAGICBOUNCE],
    height:      11,
    weight:      278,
    generation:  6,
  },

  # Mega Metagross
  {
    id:          :METAGROSS_1,
    id_number:   1190,
    species:     :METAGROSS,
    form:        1,
    mega_stone:  :METAGROSSITE,
    unmega_form: 0,
    form_name:   "Mega Metagross",
    type1_override: :STEEL,
    type2_override: :PSYCHIC,
    base_stats_override: { HP: 80, ATTACK: 145, DEFENSE: 150, SPECIAL_ATTACK: 105, SPECIAL_DEFENSE: 110, SPEED: 110 },
    abilities_override: [:TOUGHCLAWS],
    height:      25,
    weight:      9429,
    generation:  6,
  },

  # Mega Rayquaza
  {
    id:          :RAYQUAZA_1,
    id_number:   1191,
    species:     :RAYQUAZA,
    form:        1,
    mega_move:   :DRAGONASCENT,
    unmega_form: 0,
    form_name:   "Mega Rayquaza",
    type1_override: :DRAGON,
    type2_override: :FLYING,
    base_stats_override: { HP: 105, ATTACK: 180, DEFENSE: 100, SPECIAL_ATTACK: 180, SPECIAL_DEFENSE: 100, SPEED: 115 },
    abilities_override: [:DELTASTREAM],
    height:      108,
    weight:      3920,
    generation:  6,
  },

  # Mega Lopunny
  {
    id:          :LOPUNNY_1,
    id_number:   1192,
    species:     :LOPUNNY,
    form:        1,
    mega_stone:  :LOPUNNITE,
    unmega_form: 0,
    form_name:   "Mega Lopunny",
    type1_override: :NORMAL,
    type2_override: :FIGHTING,
    base_stats_override: { HP: 65, ATTACK: 136, DEFENSE: 94, SPECIAL_ATTACK: 54, SPECIAL_DEFENSE: 96, SPEED: 135 },
    abilities_override: [:SCRAPPY],
    height:      13,
    weight:      283,
    generation:  6,
  },

  # Mega Salamence
  {
    id:          :SALAMENCE_1,
    id_number:   1193,
    species:     :SALAMENCE,
    form:        1,
    mega_stone:  :SALAMENCITE,
    unmega_form: 0,
    form_name:   "Mega Salamence",
    type1_override: :DRAGON,
    type2_override: :FLYING,
    base_stats_override: { HP: 95, ATTACK: 145, DEFENSE: 130, SPECIAL_ATTACK: 120, SPECIAL_DEFENSE: 90, SPEED: 120 },
    abilities_override: [:AERILATE],
    height:      18,
    weight:      1126,
    generation:  6,
  },

  # Mega Beedrill
  {
    id:          :BEEDRILL_1,
    id_number:   1194,
    species:     :BEEDRILL,
    form:        1,
    mega_stone:  :BEEDRILLITE,
    unmega_form: 0,
    form_name:   "Mega Beedrill",
    type1_override: :BUG,
    type2_override: :POISON,
    base_stats_override: { HP: 65, ATTACK: 150, DEFENSE: 40, SPECIAL_ATTACK: 15, SPECIAL_DEFENSE: 80, SPEED: 145 },
    abilities_override: [:ADAPTABILITY],
    height:      14,
    weight:      405,
    generation:  6,
  },
].freeze

# ---------------------------------------------------------------------------
# Registration helper — builds a full Species hash from base + mega delta
# ---------------------------------------------------------------------------
def npt_register_mega_form(mega)
  base = GameData::Species.get(mega[:species]) rescue nil
  unless base
    echoln "[990_NPT] Skipping #{mega[:id]}: base species #{mega[:species]} not found"
    return
  end

  bs_override = mega[:base_stats_override] || {}
  base_bs     = base.base_stats

  t1 = mega.key?(:type1_override) ? mega[:type1_override] : base.type1
  t2 = mega.key?(:type2_override) ? mega[:type2_override] : base.type2

  GameData::Species.register({
    id:          mega[:id],
    id_number:   mega[:id_number],
    species:     mega[:species],
    form:        mega[:form],
    mega_stone:  mega[:mega_stone],
    unmega_form: mega[:unmega_form],

    form_name:     mega[:form_name],
    name:          base.real_name,
    category:      base.category,
    pokedex_entry: mega[:pokedex] || base.pokedex_entry,

    type1: t1,
    type2: t2,

    base_stats: {
      HP:              bs_override[:HP]              || base_bs[:HP],
      ATTACK:          bs_override[:ATTACK]          || base_bs[:ATTACK],
      DEFENSE:         bs_override[:DEFENSE]         || base_bs[:DEFENSE],
      SPECIAL_ATTACK:  bs_override[:SPECIAL_ATTACK]  || base_bs[:SPECIAL_ATTACK],
      SPECIAL_DEFENSE: bs_override[:SPECIAL_DEFENSE] || base_bs[:SPECIAL_DEFENSE],
      SPEED:           bs_override[:SPEED]           || base_bs[:SPEED],
    },

    evs:         base.evs,
    base_exp:    base.base_exp,
    growth_rate: base.growth_rate,

    gender_ratio: base.gender_ratio,
    catch_rate:   base.catch_rate,
    happiness:    base.happiness,
    egg_groups:   base.egg_groups,
    hatch_steps:  base.hatch_steps,
    incense:      nil,

    abilities:        mega[:abilities_override] || base.abilities,
    hidden_abilities: base.hidden_abilities,

    moves:       base.moves,
    tutor_moves: base.tutor_moves,
    egg_moves:   base.egg_moves,

    wild_item_common:   nil,
    wild_item_uncommon: nil,
    wild_item_rare:     nil,

    evolutions: [],

    height:     mega[:height]     || base.height,
    weight:     mega[:weight]     || base.weight,
    color:      base.color,
    shape:      base.shape,
    habitat:    nil,
    generation: mega[:generation] || base.generation,

    back_sprite_x:         0,
    back_sprite_y:         0,
    front_sprite_x:        0,
    front_sprite_y:        0,
    front_sprite_altitude: 0,
    shadow_x:              0,
    shadow_size:           2,
  })
  echoln "[990_NPT] Registered #{mega[:id]} (id=#{mega[:id_number]}, stone=#{mega[:mega_stone]})"
end

# ---------------------------------------------------------------------------
# NPT module alias
# ---------------------------------------------------------------------------
module NPT
  class << self
    alias _npt_pre_mega_forms register_all_species

    def register_all_species
      _npt_pre_mega_forms

      # 1. Patch existing NPT alternate forms with mega_stone / unmega_form
      NPT_MEGA_PATCHES.each do |sym, stone|
        sp = GameData::Species.get(sym) rescue nil
        next unless sp
        sp.instance_variable_set(:@mega_stone,  stone)
        sp.instance_variable_set(:@unmega_form, 0)
        echoln "[990_NPT] Patched mega_stone=#{stone} onto #{sym}"
      end

      # 2. Register brand-new mega forms
      NPT_NEW_MEGAS.each { |mega| npt_register_mega_form(mega) }
    end
  end
end
