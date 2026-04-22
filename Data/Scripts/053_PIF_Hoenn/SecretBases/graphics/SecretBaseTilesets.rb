class Game_Map
  SECRET_BASE_TILESET_OVERRIDES = {
    :BUSH => 100,
    :CAVE => 101,
    :TREE => 102,
  }

  alias __tileset_swap_updateTileset updateTileset

  def updateTileset
    secret_base_map_id = get_secret_base_map_id if defined?(get_secret_base_map_id)
    if secret_base_map_id && @map_id == secret_base_map_id && $Trainer && $Trainer.secretBase
      override = SECRET_BASE_TILESET_OVERRIDES[$Trainer.secretBase.biome_type]
      @map.tileset_id = override if override
    end
    __tileset_swap_updateTileset
  end
end


