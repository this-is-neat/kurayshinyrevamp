module CustomSpeciesFramework
  SAFE_FUSION_BODY_ID = 1 unless const_defined?(:SAFE_FUSION_BODY_ID)
  SAFE_FUSION_HEAD_ID = 25 unless const_defined?(:SAFE_FUSION_HEAD_ID)

  def self.valid_fusion_component_number?(value)
    number = value.to_i
    return false if number <= 0
    return false if actual_triple_fusion_number?(number) rescue false
    return false if actual_fusion_number?(number) rescue false
    return false if custom_species_id_number?(number) && !standard_fusion_compatible?(number)
    return GameData::Species::DATA.has_key?(number) if defined?(GameData::Species::DATA)
    return number <= Settings::NB_POKEMON
  rescue
    return false
  end

  def self.safe_fusion_component_number(value, fallback = SAFE_FUSION_BODY_ID)
    candidates = []
    resolved = resolve_id_number(value) rescue nil
    candidates << resolved if resolved
    candidates << value.to_i if value.respond_to?(:to_i)
    candidates.each do |candidate|
      return candidate.to_i if valid_fusion_component_number?(candidate)
    end
    fallback_number = fallback.to_i
    return fallback_number if valid_fusion_component_number?(fallback_number)
    return SAFE_FUSION_BODY_ID
  end

  def self.safe_fusion_components_from_id(id)
    text = id.to_s
    if text[/\AB(\d+)H(\d+)\z/i]
      return [
        safe_fusion_component_number($1, SAFE_FUSION_BODY_ID),
        safe_fusion_component_number($2, SAFE_FUSION_HEAD_ID)
      ]
    end
    if text[/\A(\d+)_x_(\d+)\z/i]
      return [
        safe_fusion_component_number($2, SAFE_FUSION_BODY_ID),
        safe_fusion_component_number($1, SAFE_FUSION_HEAD_ID)
      ]
    end
    if text[%r{\A(\d+)/(\d+)\z}]
      return [
        safe_fusion_component_number($1, SAFE_FUSION_BODY_ID),
        safe_fusion_component_number($2, SAFE_FUSION_HEAD_ID)
      ]
    end
    resolved = resolve_id_number(id) rescue nil
    if resolved && valid_fusion_component_number?(resolved)
      number = resolved.to_i
      return [number, number]
    end
    log("Recovered malformed fused species id #{id.inspect}; using safe title-screen fallback.")
    return [SAFE_FUSION_BODY_ID, SAFE_FUSION_HEAD_ID]
  rescue => e
    log("Failed to parse fused species id #{id.inspect}: #{e.class}: #{e.message}")
    return [SAFE_FUSION_BODY_ID, SAFE_FUSION_HEAD_ID]
  end

  def self.safe_intro_fusion_pair(pair, max_poke = -1)
    values = Array(pair)
    max_number = max_poke.to_i
    fallback_head = SAFE_FUSION_HEAD_ID
    fallback_body = SAFE_FUSION_BODY_ID
    if max_number > 0
      fallback_head = [[fallback_head, max_number].min, 1].max
      fallback_body = [[fallback_body, max_number].min, 1].max
    end
    head = safe_fusion_component_number(values[0], fallback_head)
    body = safe_fusion_component_number(values[1], fallback_body)
    if max_number > 0
      head = fallback_head if head > max_number
      body = fallback_body if body > max_number
    end
    return [head, body]
  end
end

if defined?(GameData::FusedSpecies)
  module GameData
    class FusedSpecies
      alias csf_original_get_body_number_from_symbol get_body_number_from_symbol unless method_defined?(:csf_original_get_body_number_from_symbol)
      alias csf_original_get_head_number_from_symbol get_head_number_from_symbol unless method_defined?(:csf_original_get_head_number_from_symbol)

      def get_body_number_from_symbol(id)
        body, _head = CustomSpeciesFramework.safe_fusion_components_from_id(id)
        return body
      rescue
        return csf_original_get_body_number_from_symbol(id) rescue CustomSpeciesFramework::SAFE_FUSION_BODY_ID
      end

      def get_head_number_from_symbol(id)
        _body, head = CustomSpeciesFramework.safe_fusion_components_from_id(id)
        return head
      rescue
        return csf_original_get_head_number_from_symbol(id) rescue CustomSpeciesFramework::SAFE_FUSION_HEAD_ID
      end
    end
  end
end

if defined?(get_head_number_from_symbol) && !defined?(csf_original_global_get_head_number_from_symbol)
  alias csf_original_global_get_head_number_from_symbol get_head_number_from_symbol
end

def get_head_number_from_symbol(id)
  _body, head = CustomSpeciesFramework.safe_fusion_components_from_id(id)
  return head
rescue
  return csf_original_global_get_head_number_from_symbol(id) rescue CustomSpeciesFramework::SAFE_FUSION_HEAD_ID
end

if defined?(get_body_number_from_symbol) && !defined?(csf_original_global_get_body_number_from_symbol)
  alias csf_original_global_get_body_number_from_symbol get_body_number_from_symbol
end

def get_body_number_from_symbol(id)
  body, _head = CustomSpeciesFramework.safe_fusion_components_from_id(id)
  return body
rescue
  return csf_original_global_get_body_number_from_symbol(id) rescue CustomSpeciesFramework::SAFE_FUSION_BODY_ID
end

if defined?(getRandomCustomFusionForIntro) && !defined?(csf_original_getRandomCustomFusionForIntro)
  alias csf_original_getRandomCustomFusionForIntro getRandomCustomFusionForIntro
end

def getRandomCustomFusionForIntro(returnRandomPokemonIfNoneFound = true, customPokeList = [], maxPoke = -1, recursionLimit = 3)
  pair = nil
  begin
    pair = csf_original_getRandomCustomFusionForIntro(returnRandomPokemonIfNoneFound, customPokeList, maxPoke, recursionLimit)
  rescue => e
    CustomSpeciesFramework.log("Title-screen fusion picker recovered from #{e.class}: #{e.message}")
  end
  pair = [] if pair.nil? || pair.length < 2
  return CustomSpeciesFramework.safe_intro_fusion_pair(pair, maxPoke)
end

