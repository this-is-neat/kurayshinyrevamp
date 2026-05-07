require "json"
require "fileutils"

module GameData
  class Species; end
  class Move; end
  class Ability; end
  class Item; end
  class Type; end
end

GAME_ROOT = File.expand_path(ARGV[0] || File.join(__dir__, "..", "..", ".."))
MOD_ROOT = File.expand_path(ARGV[1] || File.join(__dir__, ".."))
CATALOG_FILE = File.expand_path(ARGV[2] || File.join(__dir__, "data", "game_catalog.json"))
DATA_ROOT = File.join(GAME_ROOT, "Data")
SPECIES_DATA_FILE = File.join(DATA_ROOT, "species.dat")
MOVES_DATA_FILE = File.join(DATA_ROOT, "moves.dat")
ABILITIES_DATA_FILE = File.join(DATA_ROOT, "abilities.dat")
ITEMS_DATA_FILE = File.join(DATA_ROOT, "items.dat")
TYPES_DATA_FILE = File.join(DATA_ROOT, "types.dat")
FRAMEWORK_SPECIES_DIR = File.join(MOD_ROOT, "data", "species")
USER_CREATED_SPECIES_FILE = File.join(FRAMEWORK_SPECIES_DIR, "user_created_species.json")
IMAGE_EXTENSIONS = %w[.png .gif .jpg .jpeg .bmp].freeze

def load_marshaled_hash(path)
  return {} unless File.exist?(path)
  Marshal.load(File.binread(path))
rescue
  {}
end

def ivar(object, name, fallback = nil)
  return fallback if object.nil?
  object.instance_variable_defined?(name) ? object.instance_variable_get(name) : fallback
end

def to_id(value)
  return nil if value.nil?
  text = value.to_s.strip
  return nil if text.empty?
  text.upcase
end

def display_text(value, fallback = "")
  text = value.nil? ? "" : value.to_s.dup
  begin
    text = text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
  rescue
  end
  text = text.strip
  text.empty? ? fallback : text
end

def titleize_token(value)
  text = display_text(value)
  return "" if text.empty?
  text.split("_").map { |part| part.capitalize }.join(" ")
end

def calculate_bst(base_stats)
  (base_stats || {}).values.compact.map { |value| value.to_i }.sum
end

def resolve_game_asset_url(relative_path)
  return nil if relative_path.nil?
  normalized = relative_path.to_s.tr("\\", "/").sub(%r{\A/+}, "")
  return nil if normalized.empty?
  absolute = File.join(GAME_ROOT, normalized)
  if File.extname(normalized).empty?
    IMAGE_EXTENSIONS.each do |extension|
      candidate_relative = "#{normalized}#{extension}"
      candidate_absolute = "#{absolute}#{extension}"
      return "/game/#{candidate_relative}" if File.file?(candidate_absolute)
    end
  else
    return "/game/#{normalized}" if File.file?(absolute)
  end
  nil
end

def resolve_mod_asset_url(relative_path)
  return nil if relative_path.nil?
  normalized = relative_path.to_s.tr("\\", "/").sub(%r{\A/+}, "")
  return nil if normalized.empty?
  absolute = File.join(MOD_ROOT, normalized)
  if File.extname(normalized).empty?
    IMAGE_EXTENSIONS.each do |extension|
      candidate_relative = "#{normalized}#{extension}"
      candidate_absolute = "#{absolute}#{extension}"
      return "/mod/#{candidate_relative}" if File.file?(candidate_absolute)
    end
  else
    return "/mod/#{normalized}" if File.file?(absolute)
  end
  nil
end

def load_framework_species_definitions
  definitions = []
  return definitions unless Dir.exist?(FRAMEWORK_SPECIES_DIR)

  Dir.glob(File.join(FRAMEWORK_SPECIES_DIR, "*.json")).sort.each do |path|
    next if File.basename(path).downcase == "user_created_species.json"
    begin
      payload = JSON.parse(File.read(path, mode: "r:BOM|UTF-8"))
      species_entries = payload.is_a?(Hash) ? payload["species"] : nil
      next unless species_entries.is_a?(Array)
      species_entries.each do |entry|
        next unless entry.is_a?(Hash)
        entry["_source_file"] = path
        definitions << entry
      end
    rescue
    end
  end

  begin
    payload = JSON.parse(File.read(USER_CREATED_SPECIES_FILE, mode: "r:BOM|UTF-8"))
    species_entries = payload.is_a?(Hash) ? payload["species"] : nil
    if species_entries.is_a?(Array)
      species_entries.each do |entry|
        next unless entry.is_a?(Hash)
        entry["_source_file"] = USER_CREATED_SPECIES_FILE
        definitions << entry
      end
    end
  rescue
  end

  definitions
end

def build_move_entry(move)
  {
    "id" => to_id(ivar(move, :@id)),
    "name" => display_text(ivar(move, :@real_name), to_id(ivar(move, :@id))),
    "type" => to_id(ivar(move, :@type)),
    "category" => ivar(move, :@category, 2).to_i,
    "category_name" => case ivar(move, :@category, 2).to_i
                       when 0 then "Physical"
                       when 1 then "Special"
                       else "Status"
                       end,
    "power" => ivar(move, :@base_damage, 0).to_i,
    "accuracy" => ivar(move, :@accuracy, 0).to_i,
    "pp" => ivar(move, :@total_pp, 0).to_i,
    "priority" => ivar(move, :@priority, 0).to_i,
    "description" => display_text(ivar(move, :@real_description))
  }
end

def build_ability_entry(ability)
  {
    "id" => to_id(ivar(ability, :@id)),
    "name" => display_text(ivar(ability, :@real_name), to_id(ivar(ability, :@id))),
    "description" => display_text(ivar(ability, :@real_description))
  }
end

def build_item_entry(item)
  {
    "id" => to_id(ivar(item, :@id)),
    "name" => display_text(ivar(item, :@real_name), to_id(ivar(item, :@id))),
    "id_number" => ivar(item, :@id_number, 0).to_i,
    "pocket" => ivar(item, :@pocket, 0).to_i,
    "description" => display_text(ivar(item, :@real_description))
  }
end

def build_type_entry(type)
  {
    "id" => to_id(ivar(type, :@id)),
    "name" => display_text(ivar(type, :@real_name), to_id(ivar(type, :@id)))
  }
end

def build_named_entry(id, lookup)
  normalized_id = to_id(id)
  return nil unless normalized_id
  lookup[normalized_id] || { "id" => normalized_id, "name" => titleize_token(normalized_id) }
end

def build_named_list(entries, lookup)
  Array(entries).map { |entry| build_named_entry(entry, lookup) }.compact
end

def build_level_moves(entries, move_lookup)
  Array(entries).map do |entry|
    level, move_id = entry
    move = build_named_entry(move_id, move_lookup)
    next nil unless move
    move.merge("level" => level.to_i)
  end.compact
end

def build_simple_move_list(entries, move_lookup)
  Array(entries).map { |entry| build_named_entry(entry, move_lookup) }.compact
end

def base_species_visuals(id_number, species_id)
  {
    "front" => resolve_game_asset_url("Graphics/BaseSprites/#{id_number}"),
    "back" => resolve_game_asset_url("Graphics/BaseSprites/#{id_number}"),
    "icon" => resolve_game_asset_url("Graphics/Pokemon/Icons/#{species_id}") || resolve_game_asset_url(format("Graphics/Icons/icon%03d", id_number)),
    "shiny_front" => nil,
    "shiny_back" => nil,
    "overworld" => nil
  }
end

def custom_species_visuals(definition)
  assets = definition["assets"].is_a?(Hash) ? definition["assets"] : {}
  {
    "front" => resolve_mod_asset_url(assets["front"]),
    "back" => resolve_mod_asset_url(assets["back"]) || resolve_mod_asset_url(assets["front"]),
    "icon" => resolve_mod_asset_url(assets["icon"]),
    "shiny_front" => resolve_mod_asset_url(assets["shiny_front"]),
    "shiny_back" => resolve_mod_asset_url(assets["shiny_back"]),
    "overworld" => resolve_mod_asset_url(assets["overworld"])
  }
end

def build_species_reference(species_id, id_number_map, name_map)
  normalized_id = to_id(species_id)
  return nil unless normalized_id
  {
    "id" => normalized_id,
    "name" => name_map[normalized_id] || titleize_token(normalized_id),
    "id_number" => id_number_map[normalized_id]
  }
end

def build_evolutions(entries, id_number_map, name_map)
  Array(entries).map do |entry|
    if entry.is_a?(Array)
      target_id, method_id, parameter, = entry
      normalized_method = to_id(method_id)
      {
        "species" => build_species_reference(target_id, id_number_map, name_map),
        "method" => {
          "id" => normalized_method,
          "name" => titleize_token(normalized_method),
          "parameter_kind" => parameter.nil? ? nil : parameter.class.name,
          "minimum_level" => normalized_method&.start_with?("LEVEL") && parameter.is_a?(Integer) ? parameter.to_i : 0
        },
        "parameter" => parameter.is_a?(Symbol) ? to_id(parameter) : parameter
      }
    elsif entry.is_a?(Hash)
      target_id = entry["species"] || entry[:species]
      method_id = entry["method"] || entry[:method]
      parameter = entry["parameter"] || entry[:parameter]
      normalized_method = to_id(method_id)
      {
        "species" => build_species_reference(target_id, id_number_map, name_map),
        "method" => {
          "id" => normalized_method,
          "name" => titleize_token(normalized_method),
          "parameter_kind" => parameter.nil? ? nil : parameter.class.name,
          "minimum_level" => normalized_method&.start_with?("LEVEL") && parameter.is_a?(Integer) ? parameter.to_i : 0
        },
        "parameter" => parameter.is_a?(Symbol) ? to_id(parameter) : parameter
      }
    end
  end.compact
end

species_data = load_marshaled_hash(SPECIES_DATA_FILE)
moves_data = load_marshaled_hash(MOVES_DATA_FILE)
abilities_data = load_marshaled_hash(ABILITIES_DATA_FILE)
items_data = load_marshaled_hash(ITEMS_DATA_FILE)
types_data = load_marshaled_hash(TYPES_DATA_FILE)
framework_definitions = load_framework_species_definitions

move_entries = moves_data.values.map { |entry| build_move_entry(entry) }.compact.sort_by { |entry| [entry["name"].downcase, entry["id"]] }
ability_entries = abilities_data.values.map { |entry| build_ability_entry(entry) }.compact.sort_by { |entry| [entry["name"].downcase, entry["id"]] }
item_entries = items_data.values.map { |entry| build_item_entry(entry) }.compact.sort_by { |entry| [entry["name"].downcase, entry["id_number"]] }
type_entries = types_data.values.map { |entry| build_type_entry(entry) }.compact.sort_by { |entry| [entry["name"].downcase, entry["id"]] }

move_lookup = move_entries.each_with_object({}) { |entry, hash| hash[entry["id"]] = entry }
ability_lookup = ability_entries.each_with_object({}) { |entry, hash| hash[entry["id"]] = entry }
item_lookup = item_entries.each_with_object({}) { |entry, hash| hash[entry["id"]] = entry }

base_species_objects = species_data.values.select { |entry| ivar(entry, :@form, 0).to_i == 0 }
base_max_id = base_species_objects.map { |entry| ivar(entry, :@id_number, 0).to_i }.max || 0

id_number_map = {}
name_map = {}

base_species_objects.each do |entry|
  id = to_id(ivar(entry, :@id))
  next unless id
  id_number_map[id] = ivar(entry, :@id_number, 0).to_i
  name_map[id] = display_text(ivar(entry, :@real_name), id)
end

framework_definitions.each do |definition|
  id = to_id(definition["id"])
  next unless id
  slot = definition["slot"].to_i
  id_number_map[id] = if definition["id_number"]
                        definition["id_number"].to_i
                      elsif slot > 0
                        base_max_id + slot
                      else
                        base_max_id + id_number_map.size + 1
                      end
  name_map[id] = display_text(definition["name"], id)
end

species_entries = base_species_objects.map do |entry|
  id = to_id(ivar(entry, :@id))
  next nil unless id
  id_number = ivar(entry, :@id_number, 0).to_i
  {
    "id" => id,
    "species" => id,
    "name" => display_text(ivar(entry, :@real_name), id),
    "id_number" => id_number,
    "category" => display_text(ivar(entry, :@real_category), "Unknown Species"),
    "pokedex_entry" => display_text(ivar(entry, :@real_pokedex_entry)),
    "design_notes" => "",
    "template_source_label" => "",
    "types" => [to_id(ivar(entry, :@type1)), to_id(ivar(entry, :@type2))].compact.uniq,
    "base_stats" => (ivar(entry, :@base_stats, {}) || {}).each_with_object({}) { |(key, value), hash| hash[to_id(key)] = value.to_i },
    "bst" => calculate_bst(ivar(entry, :@base_stats, {})),
    "base_exp" => ivar(entry, :@base_exp, 0).to_i,
    "growth_rate" => build_named_entry(ivar(entry, :@growth_rate), {}),
    "gender_ratio" => build_named_entry(ivar(entry, :@gender_ratio), {}),
    "catch_rate" => ivar(entry, :@catch_rate, 0).to_i,
    "happiness" => ivar(entry, :@happiness, 0).to_i,
    "abilities" => build_named_list(ivar(entry, :@abilities, []), ability_lookup),
    "hidden_abilities" => build_named_list(ivar(entry, :@hidden_abilities, []), ability_lookup),
    "moves" => build_level_moves(ivar(entry, :@moves, []), move_lookup),
    "tutor_moves" => build_simple_move_list(ivar(entry, :@tutor_moves, []), move_lookup),
    "egg_moves" => build_simple_move_list(ivar(entry, :@egg_moves, []), move_lookup),
    "tm_moves" => [],
    "egg_groups" => build_named_list(ivar(entry, :@egg_groups, []), {}),
    "hatch_steps" => ivar(entry, :@hatch_steps, 0).to_i,
    "evolutions" => build_evolutions(ivar(entry, :@evolutions, []), id_number_map, name_map),
    "previous_species" => nil,
    "family_species" => [],
    "height" => ivar(entry, :@height, 0).to_i,
    "weight" => ivar(entry, :@weight, 0).to_i,
    "color" => build_named_entry(ivar(entry, :@color), {}),
    "shape" => build_named_entry(ivar(entry, :@shape), {}),
    "habitat" => build_named_entry(ivar(entry, :@habitat), {}),
    "generation" => ivar(entry, :@generation, 0).to_i,
    "kind" => "base_game",
    "source" => "base_game",
    "fusion_rule" => "standard",
    "fusion_compatible" => true,
    "starter_eligible" => false,
    "encounter_eligible" => false,
    "trainer_eligible" => false,
    "source_pack" => "",
    "source_url" => "",
    "creator" => "",
    "credit_text" => "",
    "usage_permission" => "",
    "auto_import_allowed" => false,
    "manual_review_required" => false,
    "import_notes" => "",
    "regional_variant" => false,
    "variant_scope" => "",
    "variant_family" => "",
    "base_species" => nil,
    "fallback_species" => nil,
    "visuals" => base_species_visuals(id_number, id),
    "world_data" => {
      "encounter_eligible" => false,
      "trainer_eligible" => false,
      "encounter_rarity" => "",
      "encounter_zones" => [],
      "trainer_roles" => [],
      "trainer_notes" => "",
      "encounter_level_min" => 0,
      "encounter_level_max" => 0
    },
    "fusion_meta" => {
      "rule" => "standard",
      "compatible" => true,
      "head_offset_x" => 0,
      "head_offset_y" => 0,
      "body_offset_x" => 0,
      "body_offset_y" => 0,
      "naming_notes" => "",
      "sprite_hints" => ""
    },
    "export_meta" => {
      "framework_managed" => false,
      "slot" => nil,
      "json_filename" => "",
      "recommended_internal_id" => id,
      "author" => "",
      "version" => "",
      "pack_name" => "",
      "tags" => []
    }
  }
end.compact

framework_entries = framework_definitions.map do |definition|
  id = to_id(definition["id"])
  next nil unless id
  fusion_rule = display_text(definition["fusion_rule"], "standard").downcase
  {
    "id" => id,
    "species" => id,
    "name" => display_text(definition["name"], id),
    "id_number" => id_number_map[id],
    "category" => display_text(definition["category"], "Custom Species"),
    "pokedex_entry" => display_text(definition["pokedex_entry"]),
    "design_notes" => display_text(definition["design_notes"]),
    "template_source_label" => display_text(definition["template_source_label"]),
    "types" => [to_id(definition["type1"]), to_id(definition["type2"])].compact.uniq,
    "base_stats" => (definition["base_stats"] || {}).each_with_object({}) { |(key, value), hash| hash[to_id(key)] = value.to_i },
    "bst" => calculate_bst(definition["base_stats"]),
    "base_exp" => definition["base_exp"].to_i,
    "growth_rate" => build_named_entry(definition["growth_rate"], {}),
    "gender_ratio" => build_named_entry(definition["gender_ratio"], {}),
    "catch_rate" => definition["catch_rate"].to_i,
    "happiness" => definition["happiness"].to_i,
    "abilities" => build_named_list(definition["abilities"], ability_lookup),
    "hidden_abilities" => build_named_list(definition["hidden_abilities"], ability_lookup),
    "moves" => Array(definition["moves"]).map do |move|
      next nil unless move.is_a?(Hash)
      move_entry = build_named_entry(move["move"], move_lookup)
      next nil unless move_entry
      move_entry.merge("level" => move["level"].to_i)
    end.compact,
    "tutor_moves" => build_simple_move_list(definition["tutor_moves"], move_lookup),
    "egg_moves" => build_simple_move_list(definition["egg_moves"], move_lookup),
    "tm_moves" => build_simple_move_list(definition["tm_moves"], move_lookup),
    "egg_groups" => build_named_list(definition["egg_groups"], {}),
    "hatch_steps" => definition["hatch_steps"].to_i,
    "evolutions" => build_evolutions(definition["evolutions"], id_number_map, name_map),
    "previous_species" => nil,
    "family_species" => [],
    "height" => definition["height"].to_i,
    "weight" => definition["weight"].to_i,
    "color" => build_named_entry(definition["color"], {}),
    "shape" => build_named_entry(definition["shape"], {}),
    "habitat" => build_named_entry(definition["habitat"], {}),
    "generation" => definition["generation"].to_i,
    "kind" => display_text(definition["kind"], "fakemon"),
    "source" => definition["source"] ? display_text(definition["source"]) : "framework",
    "fusion_rule" => fusion_rule,
    "fusion_compatible" => fusion_rule != "blocked",
    "starter_eligible" => !!definition["starter_eligible"],
    "encounter_eligible" => !!definition["encounter_eligible"],
    "trainer_eligible" => !!definition["trainer_eligible"],
    "source_pack" => display_text(definition["source_pack"]),
    "source_url" => display_text(definition["source_url"]),
    "creator" => display_text(definition["creator"]),
    "credit_text" => display_text(definition["credit_text"]),
    "usage_permission" => display_text(definition["usage_permission"]),
    "auto_import_allowed" => !!definition["auto_import_allowed"],
    "manual_review_required" => !!definition["manual_review_required"],
    "import_notes" => display_text(definition["notes"]),
    "regional_variant" => display_text(definition["kind"]).downcase == "regional_variant",
    "variant_scope" => display_text(definition["variant_scope"]),
    "variant_family" => display_text(definition["variant_family"]),
    "base_species" => to_id(definition["base_species"]),
    "fallback_species" => display_text(definition["fallback_species"]),
    "visuals" => custom_species_visuals(definition),
    "world_data" => {
      "encounter_eligible" => !!definition["encounter_eligible"],
      "trainer_eligible" => !!definition["trainer_eligible"],
      "encounter_rarity" => display_text(definition["encounter_rarity"]),
      "encounter_zones" => Array(definition["encounter_zones"]),
      "trainer_roles" => Array(definition["trainer_roles"]),
      "trainer_notes" => display_text(definition["trainer_notes"]),
      "encounter_level_min" => definition["encounter_level_min"].to_i,
      "encounter_level_max" => definition["encounter_level_max"].to_i
    },
    "fusion_meta" => {
      "rule" => fusion_rule,
      "compatible" => fusion_rule != "blocked",
      "head_offset_x" => definition["head_offset_x"].to_i,
      "head_offset_y" => definition["head_offset_y"].to_i,
      "body_offset_x" => definition["body_offset_x"].to_i,
      "body_offset_y" => definition["body_offset_y"].to_i,
      "naming_notes" => display_text(definition["fusion_naming_notes"]),
      "sprite_hints" => display_text(definition["fusion_sprite_hints"])
    },
    "export_meta" => {
      "framework_managed" => true,
      "slot" => definition["slot"],
      "json_filename" => File.basename(definition["_source_file"].to_s),
      "recommended_internal_id" => id,
      "author" => display_text(definition["creator"]),
      "version" => display_text(definition["version"]),
      "pack_name" => display_text(definition["source_pack"]),
      "tags" => Array(definition["tags"])
    }
  }
end.compact

all_species = (species_entries + framework_entries).uniq { |entry| entry["id"] }
entries_by_id = all_species.each_with_object({}) { |entry, hash| hash[entry["id"]] = entry }
parents = Hash.new { |hash, key| hash[key] = [] }
children = Hash.new { |hash, key| hash[key] = [] }

all_species.each do |entry|
  Array(entry["evolutions"]).each do |evolution|
    target_id = evolution.dig("species", "id")
    next unless target_id && entries_by_id[target_id]
    parents[target_id] << entry["id"] unless parents[target_id].include?(entry["id"])
    children[entry["id"]] << target_id unless children[entry["id"]].include?(target_id)
  end
end

all_species.each do |entry|
  previous_id = parents[entry["id"]].first
  entry["previous_species"] = previous_id ? build_species_reference(previous_id, id_number_map, name_map) : nil

  visited = {}
  queue = [entry["id"]]
  family = []
  until queue.empty?
    current_id = queue.shift
    next if visited[current_id]
    visited[current_id] = true
    family << build_species_reference(current_id, id_number_map, name_map)
    queue.concat(parents[current_id])
    queue.concat(children[current_id])
  end
  entry["family_species"] = family.compact.sort_by { |member| [member["id_number"].to_i, member["name"].to_s] }
end

catalog_payload = {
  "generated_at" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
  "framework" => {
    "version" => "standalone",
    "active_starter_set" => "",
    "standard_species_min" => 1,
    "standard_species_max" => base_max_id
  },
  "types" => type_entries,
  "abilities" => ability_entries,
  "moves" => move_entries,
  "items" => item_entries,
  "growth_rates" => all_species.map { |entry| entry["growth_rate"] }.compact.uniq { |entry| entry["id"] }.sort_by { |entry| entry["name"].to_s.downcase },
  "gender_ratios" => all_species.map { |entry| entry["gender_ratio"] }.compact.uniq { |entry| entry["id"] }.sort_by { |entry| entry["name"].to_s.downcase },
  "egg_groups" => all_species.flat_map { |entry| Array(entry["egg_groups"]) }.compact.uniq { |entry| entry["id"] }.sort_by { |entry| entry["name"].to_s.downcase },
  "body_colors" => all_species.map { |entry| entry["color"] }.compact.uniq { |entry| entry["id"] }.sort_by { |entry| entry["name"].to_s.downcase },
  "body_shapes" => all_species.map { |entry| entry["shape"] }.compact.uniq { |entry| entry["id"] }.sort_by { |entry| entry["name"].to_s.downcase },
  "habitats" => all_species.map { |entry| entry["habitat"] }.compact.uniq { |entry| entry["id"] }.sort_by { |entry| entry["name"].to_s.downcase },
  "evolution_methods" => all_species.flat_map { |entry| Array(entry["evolutions"]).map { |evolution| evolution["method"] } }.compact.uniq { |entry| entry["id"] }.sort_by { |entry| entry["name"].to_s.downcase },
  "stats" => %w[HP ATTACK DEFENSE SPECIAL_ATTACK SPECIAL_DEFENSE SPEED].map { |id| { "id" => id, "name" => titleize_token(id) } },
  "species" => all_species.sort_by { |entry| [entry["id_number"].to_i, entry["name"].to_s.downcase, entry["id"]] },
  "starter_sets" => []
}

FileUtils.mkdir_p(File.dirname(CATALOG_FILE))
temp_file = "#{CATALOG_FILE}.tmp"
File.write(temp_file, JSON.generate(catalog_payload))
FileUtils.mv(temp_file, CATALOG_FILE, force: true)
puts "Wrote catalog to #{CATALOG_FILE}"
