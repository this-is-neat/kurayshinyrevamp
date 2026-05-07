# Custom Species Framework

Standalone framework mod for Pok\u00e9mon Infinite Fusion that adds:

- deterministic registration for custom species
- full Fakemon support
- regional variants that coexist with originals instead of overwriting them
- starter-set integration with rival counter-picks
- Pok\u00e9dex, save, art, encounter, and trainer extension hooks
- data-driven per-species fusion rules
- a browser-based creator for importing custom species and managing a custom starter trio

## Install

1. Copy the `custom_species_framework` folder into `Mods/`.
2. Start the game normally. The Mod Manager will load the framework automatically.
3. Start a new save and use the base game's opening starter-set menu. The framework inserts `Fakemon Trio` directly into that list.
4. Leave `data/framework_config.json` at its default settings if you want the opening prompt to default to the included Fakemon trio.
5. Launch the game once after updating the framework if you want to use the browser creator. The framework exports a live game-data catalog for the creator at boot.

No core script editing is required for the shipped content.

## Multi-World Travel Pairing

For the multi-world travel release, install this folder beside `travel_expansion_framework`. The travel framework handles world/map routing and save recovery; this framework handles custom species registration, imported Fakemon data, sprite resolution, dex/save hooks, and missing-pack fallback for Pokemon in the party, PC, encounters, and trainer battles.

## Browser Creator

Launch `creator/launch_creator.bat` to open the local browser-based studio UI. The launcher now replaces any stale creator-server instance first, so rerunning it is the quickest way to recover if an older browser session got stuck.

The studio now includes:

- a Pokédex-style viewer for the installed base game plus framework species
- side-by-side comparison mode for two species
- a tabbed Fakemon creation studio with live preview on the right rail
- a starter-trio integration panel
- validation summaries, autosave, undo/redo, and export packaging tools

The creator workflow lets you:

- build full custom Fakemon or regional variants through step-based tabs instead of hand-editing JSON
- import front, back, and icon art through the browser, with automatic conversion to game-ready PNG files
- choose types, abilities, items, growth rates, egg groups, habitats, and evolution rules from the installed game's data catalog
- define level-up moves, TM moves, tutor moves, and egg moves
- clone an existing species as a starting template
- start from built-in role templates such as starters, bugs, fossils, birds, babies, and pseudo-legendaries
- save a creator-managed starter trio and make it the active default starter set
- save a species and queue a playable delivery ticket for the in-game home PC from the same guided workflow
- export a saved species as a shareable framework pack zip without manually assembling files

Creator-managed files:

- `data/species/user_created_species.json`
- `data/creator_starter_sets.json`
- `data/creator_delivery_queue.json`
- `creator/data/game_catalog.json`
- `creator/data/exports/*.zip`

Restart the game after saving creator content so the framework can validate and register the updated species data on a fresh boot.

## Home PC Delivery Flow

The Integration view now includes a `Home PC Delivery` tab that turns the creator into a guided publish pipeline instead of stopping at saved JSON.

Flow:

1. Build or edit a species in the browser creator.
2. Open `Integration -> Home PC Delivery`.
3. Review the publish checklist, choose the specimen level and item settings, and click `Publish To Home PC`.
4. Restart the game if the species is new or changed.
5. Use the player's bedroom PC and choose `Custom Species Delivery` to claim the queued species into the party or a box.

The home-PC menu patch is compatibility-minded with the base trainer PC flow, the bedroom addon, and the counterfeit bedroom PC menu.

## Pack Importer

The framework now also ships a strict intake pipeline for reusable third-party Fakemon packs under `importer/`.

Use it when you want to bring in external Fakemon content without hand-merging JSON and sprites:

- `importer/launch_importer.bat`
- `importer/config/source_manifest.json`
- `importer/config/importer_config.json`
- `importer/config/framework_mapping.json`

Behavior:

- defaults to dry run first
- scans permission text and routes ambiguous sources to review
- preserves source pack, creator, source URL, usage permission, and required credit text
- validates types, abilities, and moves against `creator/data/game_catalog.json`
- stages transformed assets and a framework-ready insertion bundle in `importer/import_output/`
- can optionally apply the generated bundle into the live framework only after validation passes

Read `importer/README.md` before using it on a real pack source.

## Included Content

- `CSF_VERDALYK` - Grass starter Fakemon
- `CSF_CINDRAKE` - Fire starter Fakemon
- `CSF_AQUALITH` - Water starter Fakemon
- `CSF_SANDSHREW_GLACIAL` - sample regional variant
- `CSF_SANDSLASH_GLACIAL` - sample regional evolution

The three starter Fakemon are enabled by default, appear as a selectable opening starter set, and are intentionally non-fusible.

## Files

- `data/framework_config.json`
  Central feature toggle and active starter set.
- `data/starter_sets.json`
  Data-driven starter trios, intro-menu ordering, lab routing, and rival counter-picks.
- `data/creator_starter_sets.json`
  Creator-managed starter trio data written by the browser tool.
- `data/creator_delivery_queue.json`
  Browser-to-game delivery queue for species published to the player's home PC.
- `data/species/fakemon_starters.json`
  The shipped Fakemon starter definitions.
- `data/species/regional_variants.json`
  Sample regional-variant definitions.
- `data/species/user_created_species.json`
  Creator-managed custom species written by the browser tool.
- `data/encounters.json`
  Optional wild-encounter injection hooks.
- `data/trainer_hooks.json`
  Optional trainer-party injection hooks.
- `creator/`
  Browser creator app, launcher, and exported catalog data.
- `importer/`
  Dry-run-first Fakemon pack intake pipeline, bundle generator, and import reports.

## Adding More Fakemon

Add another entry to `data/species/fakemon_starters.json` or drop a new `*.json` file into `data/species/`. The framework auto-loads every JSON file in that folder using the same schema:

```json
{
  "id": "CSF_MYMON",
  "slot": 6,
  "kind": "fakemon",
  "name": "MyMon",
  "category": "Test Species",
  "pokedex_entry": "A short dex entry.",
  "type1": "GRASS",
  "type2": null,
  "base_stats": {
    "HP": 50,
    "ATTACK": 55,
    "DEFENSE": 45,
    "SPECIAL_ATTACK": 60,
    "SPECIAL_DEFENSE": 50,
    "SPEED": 55
  },
  "abilities": ["OVERGROW"],
  "hidden_abilities": ["LEAFGUARD"],
  "moves": [
    { "level": 1, "move": "TACKLE" },
    { "level": 5, "move": "ABSORB" }
  ],
  "starter_eligible": false,
  "fusion_rule": "blocked",
  "assets": {
    "front": "Graphics/Pokemon/Front/CSF_MYMON",
    "back": "Graphics/Pokemon/Back/CSF_MYMON",
    "icon": "Graphics/Pokemon/Icons/CSF_MYMON"
  }
}
```

Guidelines:

- Use stable, contiguous `slot` values starting from `1` for real custom species.
- The framework auto-allocates real Pokédex numbers above the current installed species count, so custom species stay out of fusion ID space.
- Legacy `id_number` values in the old `252000+` format are still accepted and remapped automatically for backward compatibility.
- Keep internal IDs prefixed with `CSF_` to avoid collisions and improve save recovery.
- Supply front, back, and icon art for playable Fakemon.
- Leave `fusion_rule` as `blocked` unless you are intentionally adding fusion-compatible output support.

If you use the browser creator, it handles the JSON structure, asset-path setup, and imported sprite copies for you automatically.

## Adding More Regional Variants

Regional variants are separate registered species entries, not replacements.

Use `kind: "regional_variant"` and set:

- `base_species`
- `fallback_species`
- custom stats, types, abilities, moves, and Pok\u00e9dex text

Example pattern:

```json
{
  "id": "CSF_RATTATA_DUSK",
  "slot": 7,
  "kind": "regional_variant",
  "base_species": "RATTATA",
  "fallback_species": "RATTATA",
  "variant_family": "DUSK",
  "name": "Rattata (Dusk)",
  "category": "Shadow Mouse",
  "pokedex_entry": "A short dex entry.",
  "type1": "DARK",
  "type2": "NORMAL",
  "fusion_rule": "restricted"
}
```

Because variants are independent species entries, the original Pok\u00e9mon and the variant can both exist in the same save, encounter table, trainer roster, and Pok\u00e9dex history.

## Encounter Hooks

Enable entries in `data/encounters.json` to inject custom species into wild encounters without editing core encounter tables by hand.

## Trainer Hooks

Enable entries in `data/trainer_hooks.json` to replace a specific trainer slot with a custom species after the trainer party is built.

## Starter Set Selection

On a fresh save, the intro sequence now asks which starter set that save file should use.

Shipped choices:

- `Framework Fakemon Trio`
- `Kanto Classic`
- `Johto Classic`
- `Hoenn Classic`
- `Sinnoh Classic`
- `Kalos Classic`

The selection is stored per save file. A save that chooses a classic regional set keeps the base game's corresponding starter-lab routing, while a save that chooses the framework trio keeps the normal Kanto lab flow and swaps the visible starters through the framework override.
The framework patches the visible opening starter menu used by this build of Infinite Fusion, so the Fakemon choice appears in the same place as Kanto, Johto, Hoenn, Sinnoh, Kalos, Mixed Generations, and Custom.
If the browser creator saves a `creator_custom_trio`, the framework adds it as its own selectable starter-set option and can mark it as the active default starter trio.

To add another selectable starter pack later, add a new entry to `data/starter_sets.json` and set:

- `intro_selectable`
- `intro_order`
- `startup_mode`
- `replace_default_starters`

`startup_mode` controls how the opening lab flow routes that save:

- `species_override` keeps the normal Oak's Lab map and lets the framework replace the visible trio
- `kanto_map`, `johto_map`, `hoenn_map`, `sinnoh_map` use the base game's existing regional starter maps
- `custom_map` is reserved for content packs that intentionally want the game's hidden custom-starter lab route

## Compatibility Notes

- The framework reserves real standard-species IDs above the current installed species count, then recomputes the fusion and triple-fusion thresholds so custom species never overlap fusion numbering.
- Legacy saves or variables that still contain old `252000+` framework IDs are remapped to the current runtime IDs on load.
- The Pok\u00e9dex stores custom seen/owned state separately from the base and fusion arrays, which avoids resizing core fusion data.
- If a save still references a removed `CSF_` species while the framework is installed, the framework swaps it to `CSF_MISSINGNO` instead of silently falling back to an unrelated Pok\u00e9mon.
- Full uninstall is still unsafe if the save currently owns custom species. Move or remove custom species before uninstalling the mod entirely.
- The included encounter and trainer hooks are shipped disabled by default so the framework does not alter the broader game world beyond the starter trio.
