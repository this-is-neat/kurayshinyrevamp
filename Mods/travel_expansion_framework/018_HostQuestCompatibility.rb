module TravelExpansionFramework
  HOST_QUEST_ID_ALIASES = {
    0                     => "pewter_1",
    1                     => "pewter_2",
    2                     => "pewter_3",
    "cerulean_1"          => 3,
    "cerulean_field_1"    => 6,
    "cerulean_field_2"    => 7,
    "cerulean_field_3"    => 8,
    "vermillion_1"        => 9,
    "vermillion_2"        => 4,
    "vermillion_3"        => 12,
    "vermillion_field_1"  => 13,
    "vermillion_field_2"  => 64,
    "celadon_1"           => 14,
    "celadon_2"           => 15,
    "celadon_3"           => 16,
    "celadon_field_1"     => 17,
    "fuchsia_1"           => 20,
    "fuchsia_2"           => 19,
    "fuchsia_3"           => 18,
    "fuchsia_4"           => 56,
    "crimson_1"           => 21,
    "crimson_2"           => 22,
    "crimson_3"           => 23,
    "saffron_field_1"     => 24,
    "pokemart_johto"      => 5,
    "pokemart_sinnoh"     => 25,
    "saffron_1"           => 26,
    "saffron_2"           => 27,
    "saffron_3"           => 28,
    "cinnabar_1"          => 29,
    "cinnabar_2"          => 30,
    "cinnabar_3"          => 42,
    "pokemart_alola"      => 62,
    "pokemart_hoenn"      => 31,
    "violet_1"            => 33,
    "violet_2"            => 34,
    "blackthorn_1"        => 35,
    "blackthorn_2"        => 36,
    "blackthorn_3"        => 37,
    "pokemart_kalos"      => 38,
    "ecruteak_1"          => 39,
    "kin_1"               => 40,
    "pokemart_unova"      => 41,
    "kin_2"               => 43,
    "legendary_deoxys_1"  => 44,
    "legendary_deoxys_2"  => 45,
    "kin_field_1"         => 46,
    "legendary_necrozma_1" => 47,
    "legendary_necrozma_2" => 48,
    "legendary_necrozma_3" => 49,
    "legendary_necrozma_4" => 50,
    "legendary_necrozma_5" => 51,
    "legendary_necrozma_6" => 52,
    "legendary_necrozma_7" => 53,
    "pewter_field_1"      => 54,
    "legendary_meloetta_1" => 57,
    "legendary_meloetta_2" => 58,
    "legendary_meloetta_3" => 59,
    "legendary_meloetta_4" => 60,
    "legendary_cresselia_1" => 61,
    "pewter_field_2"      => 63,
    "goldenrod_police_1"  => 65,
    "pinkan_police"       => 66
  } if !const_defined?(:HOST_QUEST_ID_ALIASES)

  HOST_QUEST_DEFINITIONS = {
    "pewter_field_3" => {
      :name        => "Fossilized Resin",
      :description => "A scientist at Pewter City's museum wants help clearing Beedrill away from a fossilized resin dig site in Viridian Forest.",
      :branch      => :field,
      :sprite      => "BW (82)",
      :location    => "Pewter City",
      :color       => :field
    },
    "crimson_4" => {
      :name        => "Waterfall Wonder",
      :description => "A man in Crimson City wants to know what lies at the top of the large waterfall north of the city.",
      :branch      => :hotel,
      :sprite      => "BW (28)",
      :location    => "Crimson City",
      :color       => :hotel
    }
  } if !const_defined?(:HOST_QUEST_DEFINITIONS)

  def self.host_quest_constant(name, fallback)
    constant_name = name.to_s
    return Object.const_get(constant_name) if Object.const_defined?(constant_name)
    return fallback
  rescue
    return fallback
  end

  def self.host_quest_branch(kind)
    return host_quest_constant(:QuestBranchField, "Field Quests") if kind == :field
    return host_quest_constant(:QuestBranchHotels, "Hotel Quests")
  end

  def self.host_quest_color(kind)
    return host_quest_constant(:FieldQuestColor, :PURPLE) if kind == :field
    return host_quest_constant(:HotelQuestColor, :GOLD)
  end

  def self.host_quest_id(id)
    return id if id.nil?
    normalized = id.is_a?(String) ? id.strip : id
    if normalized.is_a?(String) && normalized[/\A\d+\z/] && defined?(::QUESTS) && ::QUESTS[normalized.to_i]
      return normalized.to_i
    end
    return HOST_QUEST_ID_ALIASES[normalized] if HOST_QUEST_ID_ALIASES.has_key?(normalized)
    return normalized
  end

  def self.host_quest_equivalent_ids(id)
    normalized = host_quest_id(id)
    ids = [id, normalized]
    HOST_QUEST_ID_ALIASES.each do |alias_id, target_id|
      ids << alias_id if host_quest_id(target_id) == normalized
    end
    return ids.compact.uniq
  rescue
    return [id].compact
  end

  def self.same_host_quest_id?(left, right)
    return host_quest_id(left) == host_quest_id(right)
  rescue
    return left == right
  end

  def self.host_quest_entry(id)
    install_host_quest_compatibility!
    normalized = host_quest_id(id)
    return ::QUESTS[normalized] if defined?(::QUESTS) && ::QUESTS[normalized]
    return ::QUESTS[id] if defined?(::QUESTS) && ::QUESTS[id]
    return nil
  end

  def self.install_host_quest_compatibility!
    return if !defined?(::QUESTS) || !defined?(::Quest)
    if ::QUESTS["cerulean_2"] && ::QUESTS["cerulean_2"].respond_to?(:id=)
      ::QUESTS["cerulean_2"].id = "cerulean_2"
    end
    HOST_QUEST_DEFINITIONS.each do |quest_id, data|
      next if ::QUESTS[quest_id]
      branch = host_quest_branch(data[:branch])
      color = data[:color] == :field ? host_quest_color(:field) : host_quest_color(:hotel)
      ::QUESTS[quest_id] = ::Quest.new(
        quest_id,
        data[:name].to_s,
        data[:description].to_s,
        branch,
        data[:sprite].to_s,
        data[:location].to_s,
        color
      )
    end
  rescue => e
    log("Host quest compatibility install failed: #{e.class}: #{e.message}") if respond_to?(:log)
  end
end

TravelExpansionFramework.install_host_quest_compatibility!
TravelExpansionFramework.log("018_HostQuestCompatibility loaded from #{__FILE__}") if TravelExpansionFramework.respond_to?(:log)

alias tef_host_quest_original_pbAcceptNewQuest pbAcceptNewQuest unless defined?(tef_host_quest_original_pbAcceptNewQuest)
def pbAcceptNewQuest(id, bubblePosition = 20, show_description = true)
  TravelExpansionFramework.install_host_quest_compatibility!
  normalized = TravelExpansionFramework.host_quest_id(id)
  if !TravelExpansionFramework.host_quest_entry(normalized)
    TravelExpansionFramework.log("[quest] blocked missing quest #{id.inspect}") if TravelExpansionFramework.respond_to?(:log)
    return false
  end
  return tef_host_quest_original_pbAcceptNewQuest(normalized, bubblePosition, show_description)
end

alias tef_host_quest_original_isQuestAlreadyAccepted? isQuestAlreadyAccepted? unless defined?(tef_host_quest_original_isQuestAlreadyAccepted?)
def isQuestAlreadyAccepted?(id)
  $Trainer.quests = [] if $Trainer && $Trainer.quests.class == NilClass
  return false if !$Trainer || !$Trainer.quests
  ids = TravelExpansionFramework.host_quest_equivalent_ids(id)
  for quest in $Trainer.quests
    return true if ids.any? { |quest_id| TravelExpansionFramework.same_host_quest_id?(quest.id, quest_id) }
  end
  return false
end

alias tef_host_quest_original_pbCompletedQuest? pbCompletedQuest? unless defined?(tef_host_quest_original_pbCompletedQuest?)
def pbCompletedQuest?(id)
  $Trainer.quests = [] if $Trainer && $Trainer.quests.class == NilClass
  return false if !$Trainer || !$Trainer.quests
  ids = TravelExpansionFramework.host_quest_equivalent_ids(id)
  for quest in $Trainer.quests
    next if !quest.completed
    return true if ids.any? { |quest_id| TravelExpansionFramework.same_host_quest_id?(quest.id, quest_id) }
  end
  return false
end

alias tef_host_quest_original_finishQuest finishQuest unless defined?(tef_host_quest_original_finishQuest)
def finishQuest(id, silent = false)
  normalized = TravelExpansionFramework.host_quest_id(id)
  return false if !TravelExpansionFramework.host_quest_entry(normalized)
  return tef_host_quest_original_finishQuest(normalized, silent)
end

alias tef_host_quest_original_pbAddQuest pbAddQuest unless defined?(tef_host_quest_original_pbAddQuest)
def pbAddQuest(id)
  normalized = TravelExpansionFramework.host_quest_id(id)
  return false if isQuestAlreadyAccepted?(normalized)
  return false if !TravelExpansionFramework.host_quest_entry(normalized)
  return tef_host_quest_original_pbAddQuest(normalized)
end

alias tef_host_quest_original_pbDeleteQuest pbDeleteQuest unless defined?(tef_host_quest_original_pbDeleteQuest)
def pbDeleteQuest(id)
  result = nil
  TravelExpansionFramework.host_quest_equivalent_ids(id).each do |quest_id|
    result = tef_host_quest_original_pbDeleteQuest(quest_id)
  end
  return result
end

alias tef_host_quest_original_pbSetQuest pbSetQuest unless defined?(tef_host_quest_original_pbSetQuest)
def pbSetQuest(id, completed)
  result = nil
  TravelExpansionFramework.host_quest_equivalent_ids(id).each do |quest_id|
    result = tef_host_quest_original_pbSetQuest(quest_id, completed)
  end
  return result
end

alias tef_host_quest_original_pbSetQuestName pbSetQuestName unless defined?(tef_host_quest_original_pbSetQuestName)
def pbSetQuestName(id, name)
  result = nil
  TravelExpansionFramework.host_quest_equivalent_ids(id).each do |quest_id|
    result = tef_host_quest_original_pbSetQuestName(quest_id, name)
  end
  return result
end

alias tef_host_quest_original_pbSetQuestDesc pbSetQuestDesc unless defined?(tef_host_quest_original_pbSetQuestDesc)
def pbSetQuestDesc(id, desc)
  result = nil
  TravelExpansionFramework.host_quest_equivalent_ids(id).each do |quest_id|
    result = tef_host_quest_original_pbSetQuestDesc(quest_id, desc)
  end
  return result
end

alias tef_host_quest_original_pbSetQuestNPC pbSetQuestNPC unless defined?(tef_host_quest_original_pbSetQuestNPC)
def pbSetQuestNPC(id, npc)
  result = nil
  TravelExpansionFramework.host_quest_equivalent_ids(id).each do |quest_id|
    result = tef_host_quest_original_pbSetQuestNPC(quest_id, npc)
  end
  return result
end

alias tef_host_quest_original_pbSetQuestNPCSprite pbSetQuestNPCSprite unless defined?(tef_host_quest_original_pbSetQuestNPCSprite)
def pbSetQuestNPCSprite(id, sprite)
  result = nil
  TravelExpansionFramework.host_quest_equivalent_ids(id).each do |quest_id|
    result = tef_host_quest_original_pbSetQuestNPCSprite(quest_id, sprite)
  end
  return result
end

alias tef_host_quest_original_pbSetQuestLocation pbSetQuestLocation unless defined?(tef_host_quest_original_pbSetQuestLocation)
def pbSetQuestLocation(id, location)
  result = nil
  TravelExpansionFramework.host_quest_equivalent_ids(id).each do |quest_id|
    result = tef_host_quest_original_pbSetQuestLocation(quest_id, location)
  end
  return result
end

alias tef_host_quest_original_pbSetQuestColor pbSetQuestColor unless defined?(tef_host_quest_original_pbSetQuestColor)
def pbSetQuestColor(id, color)
  result = nil
  TravelExpansionFramework.host_quest_equivalent_ids(id).each do |quest_id|
    result = tef_host_quest_original_pbSetQuestColor(quest_id, color)
  end
  return result
end
