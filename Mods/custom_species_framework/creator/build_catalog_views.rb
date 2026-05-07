require "json"
require "fileutils"

GAME_ROOT = File.expand_path(ARGV[0] || File.join(__dir__, "..", "..", ".."))
CATALOG_FILE = File.expand_path(ARGV[1] || File.join(__dir__, "data", "game_catalog.json"))
SUMMARY_FILE = File.expand_path(ARGV[2] || File.join(__dir__, "data", "game_catalog.summary.json"))
SPECIES_DIR = File.expand_path(ARGV[3] || File.join(__dir__, "data", "catalog_species"))

def display_text(value, fallback = "")
  text = value.nil? ? "" : value.to_s.dup
  begin
    text = text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
  rescue
  end
  text = text.strip
  text.empty? ? fallback : text
end

def calculate_bst(base_stats)
  Hash(base_stats || {}).values.compact.map { |value| value.to_i }.sum
end

def normalize_named_entry(entry)
  return nil if entry.nil?
  if entry.is_a?(Hash)
    id = display_text(entry["id"] || entry["name"])
    return nil if id.empty?
    return {
      "id" => id,
      "name" => display_text(entry["name"], id)
    }
  end
  text = display_text(entry)
  return nil if text.empty?
  { "id" => text, "name" => text }
end

def normalize_named_entry_list(entries)
  Array(entries).filter_map { |entry| normalize_named_entry(entry) }
end

def normalize_species_reference(entry)
  return nil if entry.nil?
  if entry.is_a?(Hash)
    id = display_text(entry["id"] || entry["species"] || entry["name"])
    return nil if id.empty?
    reference = { "id" => id }
    name = display_text(entry["name"])
    reference["name"] = name unless name.empty?
    id_number = entry["id_number"]
    reference["id_number"] = id_number.to_i if id_number
    return reference
  end
  text = display_text(entry)
  return nil if text.empty?
  { "id" => text, "name" => text }
end

def normalize_species_reference_list(entries)
  Array(entries).filter_map { |entry| normalize_species_reference(entry) }
end

def normalize_evolution_list(entries)
  Array(entries).filter_map do |entry|
    next unless entry.is_a?(Hash)
    species = normalize_species_reference(entry["species"])
    next unless species
    evolution = { "species" => species }
    method = normalize_named_entry(entry["method"])
    evolution["method"] = method if method
    evolution["parameter"] = entry["parameter"] if entry.key?("parameter")
    evolution
  end
end

def normalize_visuals(entry)
  visuals = entry.is_a?(Hash) ? entry : {}
  {
    "front" => visuals["front"],
    "back" => visuals["back"],
    "icon" => visuals["icon"],
    "shiny_front" => visuals["shiny_front"],
    "shiny_back" => visuals["shiny_back"],
    "overworld" => visuals["overworld"]
  }.delete_if { |_, value| value.nil? || value.to_s.strip.empty? }
end

def summary_species(entry)
  return nil unless entry.is_a?(Hash)
  id = display_text(entry["id"])
  return nil if id.empty?

  base_stats = Hash(entry["base_stats"] || {})
  {
    "id" => id,
    "species" => entry["species"] || id,
    "name" => display_text(entry["name"], id),
    "id_number" => entry["id_number"].to_i,
    "category" => display_text(entry["category"], "Unknown Species"),
    "pokedex_entry" => display_text(entry["pokedex_entry"]),
    "types" => Array(entry["types"]).compact.map(&:to_s),
    "base_stats" => base_stats,
    "bst" => (entry["bst"] || calculate_bst(base_stats)).to_i,
    "abilities" => normalize_named_entry_list(entry["abilities"]),
    "hidden_abilities" => normalize_named_entry_list(entry["hidden_abilities"]),
    "growth_rate" => normalize_named_entry(entry["growth_rate"]),
    "gender_ratio" => normalize_named_entry(entry["gender_ratio"]),
    "egg_groups" => normalize_named_entry_list(entry["egg_groups"]),
    "evolutions" => normalize_evolution_list(entry["evolutions"]),
    "previous_species" => normalize_species_reference(entry["previous_species"]),
    "family_species" => normalize_species_reference_list(entry["family_species"]),
    "height" => entry["height"].to_i,
    "weight" => entry["weight"].to_i,
    "generation" => entry["generation"].to_i,
    "kind" => entry["kind"],
    "source" => entry["source"],
    "fusion_rule" => entry["fusion_rule"],
    "fusion_compatible" => !!entry["fusion_compatible"],
    "regional_variant" => !!entry["regional_variant"],
    "variant_family" => entry["variant_family"],
    "base_species" => normalize_species_reference(entry["base_species"]),
    "fallback_species" => normalize_species_reference(entry["fallback_species"]),
    "fusion_source" => entry["fusion_source"],
    "visuals" => normalize_visuals(entry["visuals"]),
    "detail_level" => "summary"
  }.delete_if { |_, value| value.nil? }
end

def safe_species_filename(species_id)
  normalized = display_text(species_id).upcase.gsub(/[^A-Z0-9_.-]/, "_")
  normalized.empty? ? "UNKNOWN" : normalized
end

abort("Catalog file not found: #{CATALOG_FILE}") unless File.file?(CATALOG_FILE)

catalog = JSON.parse(File.read(CATALOG_FILE, mode: "r:BOM|UTF-8"))
species_entries = Array(catalog["species"])

summary_payload = {
  "generated_at" => catalog["generated_at"],
  "framework" => catalog["framework"],
  "types" => normalize_named_entry_list(catalog["types"]),
  "moves" => normalize_named_entry_list(catalog["moves"]),
  "abilities" => normalize_named_entry_list(catalog["abilities"]),
  "items" => normalize_named_entry_list(catalog["items"]),
  "growth_rates" => normalize_named_entry_list(catalog["growth_rates"]),
  "gender_ratios" => normalize_named_entry_list(catalog["gender_ratios"]),
  "egg_groups" => normalize_named_entry_list(catalog["egg_groups"]),
  "body_colors" => normalize_named_entry_list(catalog["body_colors"]),
  "body_shapes" => normalize_named_entry_list(catalog["body_shapes"]),
  "habitats" => normalize_named_entry_list(catalog["habitats"]),
  "evolution_methods" => Array(catalog["evolution_methods"]).filter_map do |entry|
    next unless entry
    if entry.is_a?(Hash)
      id = display_text(entry["id"] || entry["name"])
      next if id.empty?
      {
        "id" => id,
        "name" => display_text(entry["name"], id),
        "parameter_kind" => entry["parameter_kind"]
      }.delete_if { |_, value| value.nil? }
    else
      text = display_text(entry)
      next if text.empty?
      { "id" => text, "name" => text }
    end
  end,
  "species" => species_entries.filter_map { |entry| summary_species(entry) }
}

FileUtils.mkdir_p(File.dirname(SUMMARY_FILE))
FileUtils.mkdir_p(SPECIES_DIR)

Dir.glob(File.join(SPECIES_DIR, "*.json")).each do |existing|
  FileUtils.rm_f(existing)
end

summary_temp = "#{SUMMARY_FILE}.tmp"
File.write(summary_temp, JSON.generate(summary_payload))
FileUtils.mv(summary_temp, SUMMARY_FILE, force: true)

species_entries.each do |entry|
  next unless entry.is_a?(Hash)
  species_id = display_text(entry["id"])
  next if species_id.empty?
  file_name = "#{safe_species_filename(species_id)}.json"
  species_path = File.join(SPECIES_DIR, file_name)
  temp_path = "#{species_path}.tmp"
  File.write(temp_path, JSON.generate({ "ok" => true, "species" => entry }))
  FileUtils.mv(temp_path, species_path, force: true)
end

puts "Wrote summary to #{SUMMARY_FILE}"
puts "Wrote species details to #{SPECIES_DIR}"
