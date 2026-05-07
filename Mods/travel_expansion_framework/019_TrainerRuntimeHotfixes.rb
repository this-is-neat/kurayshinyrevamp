module TravelExpansionFramework
  module_function

  def trainer_hotfix_candidate_expansion_ids(preferred_expansion_id = nil)
    ids = []
    candidates = []
    candidates << preferred_expansion_id
    if respond_to?(:current_map_expansion_id)
      candidates << current_map_expansion_id
      if defined?($game_map) && $game_map && $game_map.respond_to?(:map_id)
        candidates << current_map_expansion_id($game_map.map_id)
      end
    end
    candidates.each do |candidate|
      expansion = candidate.to_s
      next if expansion.empty? || ids.include?(expansion)
      ids << expansion
    end
    return ids
  rescue
    fallback = preferred_expansion_id.to_s
    return fallback.empty? ? [] : [fallback]
  end

  def trainer_hotfix_load_imported_trainer(tr_type, tr_name, tr_version = 0, preferred_expansion_id = nil)
    return nil if !respond_to?(:load_external_trainer)
    trainer_hotfix_candidate_expansion_ids(preferred_expansion_id).each do |expansion_id|
      trainer = load_external_trainer(expansion_id, tr_type, tr_name, tr_version)
      return trainer if trainer
    end
    return nil
  rescue => e
    log("[trainer hotfix] imported trainer load failed for #{tr_type}/#{tr_name}/#{tr_version}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  TRAINER_SPRITE_HOTFIX_EXTENSIONS = [".png", ".gif", ".jpg", ".jpeg", ".bmp"].freeze if !const_defined?(:TRAINER_SPRITE_HOTFIX_EXTENSIONS)

  def trainer_sprite_hotfix_expansion_id(trainer)
    return nil if trainer.nil?
    expansion_id = trainer.instance_variable_get(:@travel_expansion_expansion_id) if trainer.instance_variable_defined?(:@travel_expansion_expansion_id)
    expansion = expansion_id.to_s
    return nil if expansion.empty?
    return expansion
  rescue
    return nil
  end

  def trainer_sprite_hotfix_path(trainer)
    return nil if trainer.nil?
    if trainer.respond_to?(:sprite_override)
      path = trainer.sprite_override.to_s
      return path if !path.empty?
    end
    if trainer.respond_to?(:travel_expansion_external_trainer_type_data)
      data = trainer.travel_expansion_external_trainer_type_data
      if data.is_a?(Hash)
        [:front_sprite, :overworld_sprite].each do |key|
          path = data[key].to_s
          return path if !path.empty?
        end
      end
    end
    return nil
  rescue
    return nil
  end

  def trainer_sprite_hotfix_actual_path(trainer)
    logical = trainer_sprite_hotfix_path(trainer)
    return nil if logical.nil? || logical.to_s.empty?
    expansion_id = trainer_sprite_hotfix_expansion_id(trainer)
    if expansion_id && respond_to?(:resolve_runtime_path_for_expansion)
      resolved = resolve_runtime_path_for_expansion(expansion_id, logical, TRAINER_SPRITE_HOTFIX_EXTENSIONS)
      return resolved if resolved
    end
    exact = runtime_existing_path(logical) if respond_to?(:runtime_existing_path)
    return exact if exact
    exact = runtime_exact_file_path(logical) if respond_to?(:runtime_exact_file_path)
    return prefer_game_relative_path(exact) if exact && respond_to?(:prefer_game_relative_path)
    return exact
  rescue => e
    log("[trainer sprite hotfix] failed to resolve actual path #{logical}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def trainer_sprite_hotfix_bitmap(path)
    return nil if path.nil? || path.to_s.empty?
    exact = runtime_existing_path(path) if respond_to?(:runtime_existing_path)
    exact ||= runtime_exact_file_path(path) if respond_to?(:runtime_exact_file_path)
    exact ||= path
    if defined?(RPG::Cache) && RPG::Cache.respond_to?(:load_bitmap_path)
      cached = RPG::Cache.load_bitmap_path(exact)
      return cached.bitmap if cached && cached.respond_to?(:bitmap)
      return cached if cached
    end
    return AnimatedBitmap.new(exact).bitmap if defined?(AnimatedBitmap)
    return Bitmap.new(exact)
  rescue => e
    log("[trainer sprite hotfix] failed to load #{path}: #{e.class}: #{e.message}") if respond_to?(:log)
    return nil
  end

  def trainer_sprite_hotfix_ebdx_transition_base(trainer)
    return nil if trainer.nil?
    data = trainer.respond_to?(:travel_expansion_external_trainer_type_data) ? trainer.travel_expansion_external_trainer_type_data : nil
    if data.is_a?(Hash)
      id_number = integer(data[:id_number], 0)
      if id_number > 0
        candidate = sprintf("%03d", id_number)
        return candidate if pbResolveBitmap("Graphics/EBDX/Transitions/Common/#{candidate}")
      end
      return "outdoor"
    end
    return nil
  rescue
    return nil
  end

  def apply_trainer_sprite_hotfix!(sprite, trainer, sprite_key = nil)
    return false if sprite.nil? || trainer.nil?
    path = trainer_sprite_hotfix_actual_path(trainer) || trainer_sprite_hotfix_path(trainer)
    return false if path.nil?
    if sprite.respond_to?(:setBitmap)
      sprite.setBitmap(path)
    else
      bitmap = trainer_sprite_hotfix_bitmap(path)
      return false if bitmap.nil?
      sprite.bitmap = bitmap
    end
    current_bitmap = sprite.bitmap
    return false if current_bitmap.nil?
    if sprite.respond_to?(:src_rect) && current_bitmap
      if sprite.bitmap.width > sprite.bitmap.height * 2
        sprite.src_rect.x = 0
        sprite.src_rect.width = sprite.bitmap.width / 5
      else
        sprite.src_rect.x = 0
        sprite.src_rect.width = sprite.bitmap.width
      end
      sprite.src_rect.height = sprite.bitmap.height
    end
    sprite.ox = sprite.src_rect.width / 2 if sprite.respond_to?(:ox=) && sprite.respond_to?(:src_rect)
    sprite.oy = current_bitmap.height if sprite.respond_to?(:oy=) && current_bitmap
    if respond_to?(:log)
      key = sprite_key ? " #{sprite_key}" : ""
      log("[trainer sprite hotfix] applied#{key} #{path} class=#{sprite.class}")
    end
    return true
  rescue => e
    log("[trainer sprite hotfix] failed to apply sprite #{sprite_key || '(unknown)'}: #{e.class}: #{e.message}") if respond_to?(:log)
    return false
  end
end

TravelExpansionFramework.log("019_TrainerRuntimeHotfixes loaded from #{__FILE__}") if TravelExpansionFramework.respond_to?(:log)

alias tef_hotfix_original_pbLoadTrainer pbLoadTrainer if defined?(pbLoadTrainer) && !defined?(tef_hotfix_original_pbLoadTrainer)
def pbLoadTrainer(tr_type, tr_name, tr_version = 0)
  imported = TravelExpansionFramework.trainer_hotfix_load_imported_trainer(tr_type, tr_name, tr_version)
  if imported
    TravelExpansionFramework.log("[trainer hotfix] resolved #{tr_type}/#{tr_name}/#{tr_version}") if TravelExpansionFramework.respond_to?(:log)
    return imported
  end
  return tef_hotfix_original_pbLoadTrainer(tr_type, tr_name, tr_version) if defined?(tef_hotfix_original_pbLoadTrainer)
  return nil
end

if defined?(KIFTrainerSprite)
  class KIFTrainerSprite
    alias tef_sprite_hotfix_original_setTrainerBitmap setTrainerBitmap unless method_defined?(:tef_sprite_hotfix_original_setTrainerBitmap)

    def setTrainerBitmap(trainer = nil)
      trainer = @trainer if trainer.nil?
      imported_path = TravelExpansionFramework.trainer_sprite_hotfix_actual_path(trainer) || TravelExpansionFramework.trainer_sprite_hotfix_path(trainer)
      if imported_path
        bitmap = TravelExpansionFramework.trainer_sprite_hotfix_bitmap(imported_path)
        if bitmap
          self.bitmap = bitmap
          self.ox = self.bitmap.width / 2
          self.oy = self.bitmap.height
          @loaded = true
          return
        end
      end
      tef_sprite_hotfix_original_setTrainerBitmap(trainer)
    end
  end
end

if defined?(DynamicTrainerSprite)
  class DynamicTrainerSprite
    alias tef_sprite_hotfix_original_setTrainerBitmap setTrainerBitmap unless method_defined?(:tef_sprite_hotfix_original_setTrainerBitmap)

    def setTrainerBitmap(file = nil)
      imported_path = TravelExpansionFramework.trainer_sprite_hotfix_actual_path(@trainer) || TravelExpansionFramework.trainer_sprite_hotfix_path(@trainer)
      file = imported_path if imported_path
      tef_sprite_hotfix_original_setTrainerBitmap(file)
    end
  end
end

if defined?(PokeBattle_Scene)
  class PokeBattle_Scene
    alias tef_sprite_hotfix_original_pbCreateTrainerFrontSprite pbCreateTrainerFrontSprite unless method_defined?(:tef_sprite_hotfix_original_pbCreateTrainerFrontSprite)

    def pbCreateTrainerFrontSprite(idxTrainer, trainerType, numTrainers = 1, sprite_override = nil, custom_appearance = nil)
      trainer = nil
      trainer = @battle.opponent[idxTrainer] if @battle && @battle.respond_to?(:opponent)
      imported_path = TravelExpansionFramework.trainer_sprite_hotfix_actual_path(trainer) || TravelExpansionFramework.trainer_sprite_hotfix_path(trainer)
      sprite_override = imported_path if imported_path
      tef_sprite_hotfix_original_pbCreateTrainerFrontSprite(idxTrainer, trainerType, numTrainers, sprite_override, custom_appearance)
    end
  end
end

if defined?(PokeBattle_SceneEBDX)
  class PokeBattle_SceneEBDX
    alias tef_sprite_hotfix_original_loadBackdrop loadBackdrop unless method_defined?(:tef_sprite_hotfix_original_loadBackdrop)
    alias tef_sprite_hotfix_original_initializeSprites initializeSprites unless method_defined?(:tef_sprite_hotfix_original_initializeSprites)

    def loadBackdrop(*args)
      result = tef_sprite_hotfix_original_loadBackdrop(*args)
      trainer = (@battle && @battle.respond_to?(:opponent)) ? Array(@battle.opponent).compact.first : nil
      base = TravelExpansionFramework.trainer_sprite_hotfix_ebdx_transition_base(trainer)
      if base && @sprites.is_a?(Hash) && @sprites["trainer_Anim"] && @sprites["trainer_Anim"].respond_to?(:setBitmap)
        begin
          @sprites["trainer_Anim"].setBitmap("Graphics/EBDX/Transitions/Common/#{base}")
          TravelExpansionFramework.log("[trainer sprite hotfix] applied EBDX trainer_Anim #{base}") if TravelExpansionFramework.respond_to?(:log)
        rescue => e
          TravelExpansionFramework.log("[trainer sprite hotfix] failed EBDX trainer_Anim #{base}: #{e.class}: #{e.message}") if TravelExpansionFramework.respond_to?(:log)
        end
      end
      return result
    end

    def initializeSprites(*args)
      result = tef_sprite_hotfix_original_initializeSprites(*args)
      if @battle && @battle.respond_to?(:opponent) && @sprites.is_a?(Hash)
        Array(@battle.opponent).each_with_index do |trainer, i|
          sprite = @sprites["trainer_#{i}"]
          next if sprite.nil?
          TravelExpansionFramework.apply_trainer_sprite_hotfix!(sprite, trainer, "EBDX trainer_#{i}")
        end
      end
      return result
    end
  end
end
