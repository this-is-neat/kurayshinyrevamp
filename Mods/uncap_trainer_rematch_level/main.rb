#==============================================================================
# Uncap Trainer Rematch Level
# Original author: An Unsocial Pigeon
#
# Removes the level cap used when calculating trainer rematch Pokemon levels.
# Ported from the legacy single-file mod format to the folder-based mod loader.
#==============================================================================

if defined?($uncap_trainer_rematch_level_loaded) && $uncap_trainer_rematch_level_loaded
  puts "[Uncap Trainer Rematch Level] Duplicate load skipped."
else
  $uncap_trainer_rematch_level_loaded = true

  if respond_to?(:getLevelCap, true) &&
     !respond_to?(:uncap_trainer_rematch_level_original_getLevelCap, true)
    alias uncap_trainer_rematch_level_original_getLevelCap getLevelCap
  end

  def getLevelCap(*_args)
    return 100
  end

  puts "[Uncap Trainer Rematch Level] Loaded."
end
