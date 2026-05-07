# Travel Expansion Framework Release Install

This mod lets one Kuray Infinite Fusion save visit registered external Pokemon fangame installs through the bedroom PC/travel terminal. Infinite Fusion stays authoritative for the save file, party, PC/storage, bag, dex progress, battle UI, and recovery.

## Install The Mod

1. Copy the whole `travel_expansion_framework` folder into `Mods/travel_expansion_framework`.
2. Copy the whole `custom_species_framework` folder into `Mods/custom_species_framework` if you want imported/custom Pokemon species from those worlds to resolve safely.
3. Keep both folder names exactly as shown.
4. Launch the game once. The framework writes reports under `Logs/travel_expansion_framework/Reports`.
5. Use the bedroom PC/travel terminal to enter any detected world.

`travel_expansion_framework` can load worlds by itself, but `custom_species_framework` is the paired release component for custom Fakemon/species registration, save repair, missing-pack fallback, and restoring dormant species when a pack returns.

## Install External Game Worlds

The framework does not bundle the other games. Install or extract each game beside the Infinite Fusion folder, then leave the game files in their own folders.

Default expected layout:

```text
C:/Games/
  PIF/
    Mods/travel_expansion_framework/
  Reborn/
  Xenoverse/
  Insurgence/
  Uranium/
  Opalo/
  Empyrean/
  Realidea/
  Soulstones/
  Soulstones2/
  Anil/
  Bushido/
  DarkHorizon/
  Infinity/
  SolarEclipse/
  Vanguard/
  Z/Pokemon Z V2.13/
  ChaosInVesita/
  Deserted/
  GadirDelux/
  HollowWoods/
  Keishou/
  UnbreakableTies/
```

If your folders are somewhere else, edit `Mods/travel_expansion_framework/travel_expansion_sources.json`. Each world entry has a `root` and optional `root_aliases`. Point those at the local install folder that contains that game's `Data`, `Graphics`, `Audio`, `Game.ini`, or archive files.

## Registered Release Candidate Worlds

Reborn, Xenoverse, Insurgence, Uranium, Opalo, Empyrean, Realidea, Soulstones, Soulstones 2, Anil, Bushido, Dark Horizon, Infinity, Solar Eclipse, Vanguard, Pokemon Z, Chaos in Vesita, Deserted, Gadir Deluxe, Hollow Woods, Keishou, and Unbreakable Ties.

## Save Safety Rules

- Do not merge external game files into the host `Data`, `Graphics`, or `Audio` folders.
- You can install one world or many worlds. Missing worlds should fail closed.
- If a world is removed later, loading the save should rescue the player to the host/Pallet anchor and keep old world, map, species, and item references as dormant metadata.
- Imported Pokemon species/items that disappear should be replaced or removed safely, then restored when the source pack returns if the original reference can be resolved again.
- Host dex progress should not be reset by an imported game's intro/setup scripts.

## Release Diagnostics

Useful files:

- `Logs/travel_expansion_framework/framework.log`
- `Logs/travel_expansion_framework/Reports/release_compatibility_index.json`
- `Logs/travel_expansion_framework/Reports/external_project_scan.json`
- `Logs/travel_expansion_framework/Reports/registry_snapshot.json`

The framework rotates `framework.log` before it grows too large. New crash reports should become entries in `release_shim_catalog.json` first, then move into a world-specific compatibility file once verified.

## Smoke Test For A World

1. Enter the world from the PC/travel terminal.
2. Complete the first required dialogue.
3. Trigger one map transfer.
4. Open the pause menu and town map.
5. Run one wild battle and one trainer battle.
6. Save, quit, reload.
7. Return home through the Trainer Card/return-home escape path.

No black screen should last indefinitely, `$game_temp.player_transferring` should not remain stuck, and movement/menu input should return after transfers.
