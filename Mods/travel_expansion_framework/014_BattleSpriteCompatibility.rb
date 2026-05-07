module TravelExpansionFramework
  module_function

  def imported_trainer_battle_sprite_patches_enabled?
    return respond_to?(:imported_trainer_native_battle_sprites_enabled?) && imported_trainer_native_battle_sprites_enabled?
  rescue
    return false
  end

  def imported_external_trainer?(trainer)
    return false if trainer.nil?
    return trainer.respond_to?(:travel_expansion_external_trainer?) && trainer.travel_expansion_external_trainer?
  rescue
    return false
  end

  def imported_trainer_sprite_path(trainer, fallback = nil)
    return nil if !imported_trainer_battle_sprite_patches_enabled?
    candidates = []
    candidates << fallback
    candidates << trainer.sprite_override if trainer && trainer.respond_to?(:sprite_override)
    if trainer && trainer.respond_to?(:travel_expansion_external_trainer_type_data)
      data = trainer.travel_expansion_external_trainer_type_data
      if data.is_a?(Hash)
        candidates << data[:front_sprite]
        candidates << data[:overworld_sprite]
      end
    end
    candidates.each do |candidate|
      logical = normalize_string_or_nil(candidate)
      next if logical.nil?
      return logical if pbResolveBitmap(logical)
    end
    return nil
  rescue
    return nil
  end

  def load_logical_bitmap(logical_path)
    logical = normalize_string_or_nil(logical_path)
    return nil if logical.nil?
    normalized = logical.gsub("\\", "/").sub(/\A\.\//, "")
    return nil if normalized.empty?
    normalized = normalized.sub(/\A\//, "")
    ext = File.extname(normalized)
    normalized = normalized[0...-ext.length] if !ext.empty?
    folder = File.dirname(normalized)
    folder = "" if folder == "."
    folder = "#{folder}/" if !folder.empty? && !folder.end_with?("/")
    filename = File.basename(normalized)
    return nil if filename.nil? || filename.empty?
    return RPG::Cache.load_bitmap(folder, filename)
  rescue => e
    log("[battle sprites] failed to load #{logical_path}: #{e.class}: #{e.message}")
    return nil
  end

  def apply_imported_trainer_bitmap!(sprite, bitmap)
    return if sprite.nil? || bitmap.nil?
    sprite.bitmap = bitmap
    if sprite.bitmap.width > sprite.bitmap.height * 2
      sprite.src_rect.x = 0
      sprite.src_rect.width = sprite.bitmap.width / 5
    else
      sprite.src_rect.x = 0
      sprite.src_rect.width = sprite.bitmap.width
    end
    sprite.src_rect.height = sprite.bitmap.height
    sprite.ox = sprite.src_rect.width / 2
    sprite.oy = sprite.bitmap.height
  rescue => e
    log("[battle sprites] failed to apply bitmap: #{e.class}: #{e.message}")
  end

  def imported_trainer_bitmap(trainer, fallback = nil)
    return nil if trainer.nil?
    imported_path = imported_trainer_sprite_path(trainer, fallback)
    return nil if imported_path.nil?
    return load_logical_bitmap(imported_path)
  rescue
    return nil
  end

  def apply_imported_trainer_sprite_to_scene!(scene, idx, trainer, fallback = nil)
    return if !imported_trainer_battle_sprite_patches_enabled?
    return if scene.nil? || !imported_external_trainer?(trainer)
    sprite = nil
    if scene.instance_variable_defined?(:@sprites)
      sprites = scene.instance_variable_get(:@sprites)
      sprite = sprites["trainer_#{idx}"] if sprites.is_a?(Hash)
      sprite = sprites["trainer_#{idx + 1}"] if sprite.nil? && sprites.is_a?(Hash)
    end
    return if sprite.nil?
    bitmap = imported_trainer_bitmap(trainer, fallback)
    return if bitmap.nil?
    apply_imported_trainer_bitmap!(sprite, bitmap)
  rescue => e
    log("[battle sprites] failed to patch scene trainer #{idx}: #{e.class}: #{e.message}")
  end
end

class PokeBattle_Scene
  alias tef_imported_trainer_original_pbCreateTrainerFrontSprite pbCreateTrainerFrontSprite

  def pbCreateTrainerFrontSprite(idxTrainer, trainerType, numTrainers = 1, sprite_override = nil, custom_appearance = nil)
    tef_imported_trainer_original_pbCreateTrainerFrontSprite(idxTrainer, trainerType, numTrainers, sprite_override, custom_appearance)
    return if !TravelExpansionFramework.imported_trainer_battle_sprite_patches_enabled?
    return if !@battle || !@battle.respond_to?(:opponent)
    trainer = @battle.opponent[idxTrainer] rescue nil
    return if !TravelExpansionFramework.imported_external_trainer?(trainer)
    imported_path = TravelExpansionFramework.imported_trainer_sprite_path(trainer, sprite_override)
    return if imported_path.nil?
    sprite = @sprites["trainer_#{idxTrainer + 1}"]
    return if sprite.nil?
    bitmap = TravelExpansionFramework.load_logical_bitmap(imported_path)
    return if bitmap.nil?
    TravelExpansionFramework.apply_imported_trainer_bitmap!(sprite, bitmap)
  end
end

class PokeBattle_Scene
  if method_defined?(:initializeSprites) && !method_defined?(:tef_imported_trainer_original_initializeSprites)
    alias tef_imported_trainer_original_initializeSprites initializeSprites

    def initializeSprites(*args)
      result = tef_imported_trainer_original_initializeSprites(*args)
      return result if !TravelExpansionFramework.imported_trainer_battle_sprite_patches_enabled?
      if @battle && @battle.respond_to?(:opponent)
        Array(@battle.opponent).each_with_index do |trainer, idx|
          TravelExpansionFramework.apply_imported_trainer_sprite_to_scene!(self, idx, trainer)
        end
      end
      return result
    end
  end
end

if defined?(KIFTrainerSprite)
  class KIFTrainerSprite
    alias tef_imported_trainer_original_setTrainerBitmap setTrainerBitmap unless method_defined?(:tef_imported_trainer_original_setTrainerBitmap)

    def setTrainerBitmap(trainer = nil)
      tef_imported_trainer_original_setTrainerBitmap(trainer)
      return if !TravelExpansionFramework.imported_trainer_battle_sprite_patches_enabled?
      trainer = @trainer if trainer.nil?
      return if !TravelExpansionFramework.imported_external_trainer?(trainer)
      bitmap = TravelExpansionFramework.imported_trainer_bitmap(trainer)
      return if bitmap.nil?
      TravelExpansionFramework.apply_imported_trainer_bitmap!(self, bitmap)
      @loaded = true
    end
  end
end

alias tef_imported_trainer_original_pbBattleAnimationOverride pbBattleAnimationOverride
def pbBattleAnimationOverride(viewport, battletype = 0, foe = nil)
  return tef_imported_trainer_original_pbBattleAnimationOverride(viewport, battletype, foe) if !TravelExpansionFramework.imported_trainer_battle_sprite_patches_enabled?
  if (battletype == 1 || battletype == 3) && foe.is_a?(Array) && foe.length == 1
    trainer = foe[0]
    return false if TravelExpansionFramework.imported_external_trainer?(trainer)
  end
  return tef_imported_trainer_original_pbBattleAnimationOverride(viewport, battletype, foe)
end
