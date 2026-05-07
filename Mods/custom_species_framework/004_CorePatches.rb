module GameData
  class Species
    class << self
      alias csf_original_get get unless method_defined?(:csf_original_get)
      alias csf_original_try_get try_get unless method_defined?(:csf_original_try_get)

      def csf_nonfusion_path_query?(value)
        text = value.to_s
        return false if text.empty?
        return false if text.match?(/\AB\d+H\d+\z/)
        return false if text.include?("_x_")
        return text.include?("/")
      rescue
        return false
      end

      def csf_missing_species_placeholder
        placeholder = self::DATA[CustomSpeciesFramework::MISSING_SPECIES_ID] rescue nil
        placeholder ||= self::DATA[:PIKACHU] rescue nil
        return placeholder
      rescue
        return nil
      end

      def get(other)
        query = other
        query = query.to_sym if query.is_a?(String)
        if query.is_a?(Integer)
          translated_query = CustomSpeciesFramework.translate_legacy_species_number(query)
          query = translated_query if translated_query
        end
        aliased_query = nil
        if query.is_a?(String) || query.is_a?(Symbol)
          aliased_query = CustomSpeciesFramework.compatibility_alias_target(query)
        elsif query.is_a?(Integer) && query > CustomSpeciesFramework::FRAMEWORK_BASE_NB_POKEMON
          aliased_query = CustomSpeciesFramework.compatibility_alias_target(query)
        end
        query = aliased_query if !aliased_query.nil?
        canonical_query = CustomSpeciesFramework.canonical_species_id(query)
        query = canonical_query if !canonical_query.nil?
        return self::DATA[query] if self::DATA.has_key?(query)
        if query.is_a?(Symbol) && CustomSpeciesFramework.custom_internal_symbol?(query)
          placeholder = self::DATA[CustomSpeciesFramework::MISSING_SPECIES_ID]
          placeholder ||= self::DATA[:PIKACHU]
          return placeholder if placeholder
          return self::DATA.values.find { |entry| entry.is_a?(GameData::Species) }
        end
        if csf_nonfusion_path_query?(other)
          placeholder = csf_missing_species_placeholder
          return placeholder if placeholder
        end
        return csf_original_get(other)
      end

      def try_get(other)
        query = other
        query = query.to_sym if query.is_a?(String)
        if query.is_a?(Integer)
          translated_query = CustomSpeciesFramework.translate_legacy_species_number(query)
          query = translated_query if translated_query
        end
        aliased_query = nil
        if query.is_a?(String) || query.is_a?(Symbol)
          aliased_query = CustomSpeciesFramework.compatibility_alias_target(query)
        elsif query.is_a?(Integer) && query > CustomSpeciesFramework::FRAMEWORK_BASE_NB_POKEMON
          aliased_query = CustomSpeciesFramework.compatibility_alias_target(query)
        end
        query = aliased_query if !aliased_query.nil?
        canonical_query = CustomSpeciesFramework.canonical_species_id(query)
        query = canonical_query if !canonical_query.nil?
        return self::DATA[query] if self::DATA.has_key?(query)
        if query.is_a?(Symbol) && CustomSpeciesFramework.custom_internal_symbol?(query)
          placeholder = self::DATA[CustomSpeciesFramework::MISSING_SPECIES_ID]
          placeholder ||= self::DATA[:PIKACHU]
          return placeholder if placeholder
        end
        return nil if csf_nonfusion_path_query?(other)
        return csf_original_try_get(other)
      end
    end
  end
end

module GameData
  class Species
    def is_fusion
      return CustomSpeciesFramework.actual_fusion_number?(@id_number)
    end
  end
end

class Pokemon
  def isFusion?
    return CustomSpeciesFramework.actual_fusion_number?(species_data.id_number) && !self.isTripleFusion?
  end
end

def isFusion(num)
  return CustomSpeciesFramework.actual_fusion_number?(num)
end

def isSpeciesFusion(species)
  return CustomSpeciesFramework.actual_fusion_number?(species)
end

def species_is_fusion(species_id)
  return CustomSpeciesFramework.actual_fusion_number?(species_id)
end

alias csf_original_getDexNumberForSpecies getDexNumberForSpecies unless defined?(csf_original_getDexNumberForSpecies)
def getDexNumberForSpecies(species)
  resolved_id = CustomSpeciesFramework.resolve_id_number(species)
  return resolved_id if resolved_id
  dex_number = csf_original_getDexNumberForSpecies(species)
  translated_id = CustomSpeciesFramework.translate_legacy_species_number(dex_number)
  return translated_id if translated_id
  return dex_number
end

def getPokemon(dexNum)
  if dexNum.is_a?(Integer)
    translated_id = CustomSpeciesFramework.translate_legacy_species_number(dexNum)
    dexNum = translated_id if translated_id
  end
  if dexNum.is_a?(Integer) && defined?(GameData::Species::DATA) && GameData::Species::DATA.has_key?(dexNum)
    return GameData::Species::DATA[dexNum]
  end
  return GameData::Species.get(dexNum)
end
