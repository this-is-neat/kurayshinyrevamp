# Fakemon Importer

This importer converts reusable third-party Fakemon packs into the existing Custom Species Framework format with:

- dry-run-first intake
- permission scanning and review queues
- credit and usage tracking
- asset discovery for front, back, icon, shiny, and overworld sprites
- framework bundle generation for `data/species/*.json` plus imported asset folders
- optional live insertion into the current framework after validation

## Quick Start

1. Launch the game once so `creator/data/game_catalog.json` is up to date.
2. Edit `config/source_manifest.json` or copy the example file as a starting point.
3. Run `launch_importer.bat` for a dry run.
4. Inspect:
   - `import_output/import_report.json`
   - `import_output/review_queue.json`
   - `import_output/rejected_items.json`
   - `import_output/credits_manifest.json`
   - `import_output/framework_bundle/`
5. If the dry run is clean, run:

```powershell
powershell -ExecutionPolicy Bypass -File ".\Mods\custom_species_framework\importer\import_fakemon_pack.ps1" -ApplyBundle
```

## Community Pack Builder

The importer now includes a reusable Pokengine community-pack builder:

- Script: `tools/build_pokengine_pack.ps1`
- One-click launcher: `launch_build_mongratis_pack.bat`
- Example community spec: `config/community_packs/mongratis_community_sampler.json`

The bundled example builds a structured pack from approved Mongratis species pages on Pokengine, downloads the source art, converts the sprites to importer-friendly PNG files, preserves per-species credit text, and writes a ready-to-use source manifest fragment under:

- `sources/mongratis_community_sampler/`

That generated pack includes:

- `species.json`
- `credits_manifest.json`
- `PERMISSIONS.txt`
- `README.txt`
- `raw_pages/*.html`
- normalized `assets/front`, `assets/back`, `assets/icon`, and optional `assets/overworld`

Current curated example result:

- `Hissiorite`, `Cobarett`, `Merlicun`, and `Sunnydra` dry-run as ready imports
- `Pythonova` is intentionally routed to review because its source page uses `Corrosive Bite`, which is not present in the current Infinite Fusion move catalog

This keeps the intake safe: the framework auto-imports the valid entries and leaves the unsupported move case visible for manual review instead of silently altering it.

## Supported Source Types

- `folder`
- `structured_pack`
- `zip`
- `github_zip`
- `html_page`

## Safety Defaults

- `strict_permission_mode = true`
- `dry_run_only = true`
- `overwrite_existing_species = false`
- partial entries require review by default

## Output

The importer writes:

- `import_output/assets/`
- `import_output/species/species_manifest.json`
- `import_output/species/species_data.json`
- `import_output/framework_bundle/`
- `import_output/credits_manifest.json`
- `import_output/import_report.json`
- `import_output/review_queue.json`
- `import_output/rejected_items.json`
- `import_output/NOTICE_imports.txt`

If `-ApplyBundle` is used, the generated bundle is copied into the live framework root and a `rollback_manifest.json` is written to the output folder.

## Framework Mapping

The default mapping writes imported assets under pack-scoped folders like:

- `Graphics/Pokemon/Imported/{pack_slug}/Front/{internal_id}.png`
- `Graphics/Pokemon/Imported/{pack_slug}/Back/{internal_id}.png`
- `Graphics/Pokemon/Imported/{pack_slug}/Icons/{internal_id}.png`

This keeps imported content namespaced while still letting the existing framework load the species through normal JSON registration and runtime asset installation.
