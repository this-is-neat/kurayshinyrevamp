#==============================================================================
# 990_NPT — Randomizer filter
#
# When NPT::Toggle.new_pokemon_disabled? is true, strip all NPT-registered
# species (id_number >= NPT::FIRST_ID) from the randomizer's source pool and
# from live lookups. Hooks:
#
#   get_pokemon_list(include_fusions)  — source pool for pbShuffleDex
#   getRandomizedTo(species)           — runtime lookup into the BST hash
#
# Behavior:
#   - get_pokemon_list: NPT IDs never enter the pool, so they can't be
#     rolled as replacement species in the first place.
#   - getRandomizedTo: if a pre-existing save already has an NPT entry in
#     $PokemonGlobal.psuedoBSTHash, fall back to the original (vanilla)
#     species ID instead of the NPT one.
#==============================================================================

alias _npt_orig_get_pokemon_list get_pokemon_list

def get_pokemon_list(include_fusions = false)
  list = _npt_orig_get_pokemon_list(include_fusions)
  return list unless NPT::Toggle.new_pokemon_disabled?
  list.reject { |id| id.is_a?(Integer) && id >= NPT::FIRST_ID }
end

alias _npt_orig_get_randomized_to getRandomizedTo

def getRandomizedTo(species)
  mapped = _npt_orig_get_randomized_to(species)
  return mapped unless NPT::Toggle.new_pokemon_disabled?
  return mapped unless mapped
  # If the randomizer mapped this species to an NPT one, fall back to the
  # original vanilla species rather than letting the NPT form through.
  if mapped.is_a?(Integer) && mapped >= NPT::FIRST_ID
    return species
  end
  data = GameData::Species.try_get(mapped) rescue nil
  if data && data.id_number >= NPT::FIRST_ID
    return species
  end
  mapped
end
