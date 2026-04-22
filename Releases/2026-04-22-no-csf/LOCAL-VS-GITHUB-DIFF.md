# Local Workspace vs GitHub Repo Notes

Comparison target:

- Repository: `this-is-neat/kurayshinyrevamp`
- GitHub commit compared: `9e45249e2d0fa7e0bc6baa5d62b3c0c5bd35c07d`
- Compared on: 2026-04-22

## Scope

This comparison checked the current local `C:\Games\PIF` workspace against the current GitHub repo contents.

The local side was filtered to exclude runtime and packaging output folders that are not part of the clean project diff:

- `dist/`
- `Cache/`
- `Logs/`
- `ExportedPokemons/`
- `__pycache__/`
- temp probe folders and temp creator server logs
- local debug/output files such as `game_launch_pid.txt`, `mega_debug.txt`, `mod_browser_debug.txt`, and similar local-only scratch files

## High-level counts

- Local files included in the filtered comparison: `556,800`
- GitHub tracked files checked directly on this Windows machine: `25,219`
- Unchanged tracked files: `15,273`
- Tracked files changed locally: `7,863`
- Local-only files not present in GitHub: `533,664`
- GitHub-only tracked files missing from the filtered local comparison: `2,083`

Note:

- `37` GitHub-tracked paths could not be checked directly on this Windows machine because their names were not valid local Windows paths in this checkout.

## Biggest tracked-file change areas

- `Graphics/`: `7,190` tracked files differ locally
- `Data/`: `652` tracked files differ locally
- root files: `11` tracked files differ locally
- `InstallerBootstrap/`: `8` tracked files differ locally
- smaller tracked changes also appear under `(Deprecated)/` and `(Source)/`

Examples of tracked files that differ locally:

- `Data/CommonEvents.rxdata`
- `Data/items.dat`
- `Data/map_connections.dat`
- `Data/map_metadata.dat`
- many `Data/Map*.rxdata` files
- `Graphics/Autotiles/ShallowWater.png`
- many `Graphics/BaseSprites/*` files
- `InstallerBootstrap/InstallerEngine.cs`
- `InstallerBootstrap/PayloadLocator.cs`
- `InstallerBootstrap/BundledSevenZip.cs`

## Biggest local-only areas

- `Graphics/`: `528,011` local-only files
- `ModDev/`: `4,482` local-only files
- `REQUIRED_BY_INSTALLER_UPDATER/`: `342` local-only files
- `Audio/`: `301` local-only files
- `Data/`: `300` local-only files
- `Mods/`: `178` local-only files
- `Libs/`: `24` local-only files
- `Fonts/`: `11` local-only files
- `KIFM/`: `4` local-only files
- `InstallerUpdater/`: `1` local-only file

Examples of local-only content:

- `Mods/counterfeit_shinies/*`
- `Mods/uncap_trainer_rematch_level/*`
- `Mods/MoveInCircles/*`
- `Mods/custom_species_framework/*`
- `KIFM/server.rb`
- `KIFM/launch_server.bat`
- `package_release.ps1`
- `pif_installer.iss`
- `REQUIRED_BY_INSTALLER_UPDATER/7z.exe`
- `REQUIRED_BY_INSTALLER_UPDATER/7z.dll`
- `Graphics/Alternate Trainers/*`

Important note:

- `custom_species_framework` exists in the local workspace and shows up in this comparison as local-only mod content, even though it was intentionally excluded from the current public packaged build.

## Top-level differences

Top-level names that exist locally but not in the GitHub repo root:

- `autoupdate_multiplayer.bat`
- `autoupdater.rb`
- `Installer_ModManager2_0.bat`
- `InstallerUpdater/`
- `KIFM/`
- `Libs/`
- `ModDev/`
- `package_release.bat`
- `package_release.ps1`
- `pif_installer.iss`
- `release_notes_2026-04-22-no-csf.md`

Top-level names that exist in the GitHub repo root but not in the filtered local comparison:

- `ExportedPokemons/`
- `Releases/`

## GitHub-only areas

Most GitHub-only tracked paths came from:

- `ExportedPokemons/`: `2,079` files
- `Releases/`: `4` files

Interpretation:

- `ExportedPokemons/` is heavily represented in the current GitHub repo, but it was intentionally excluded from the local comparison scope because it is not part of the clean packaged client.
- `Releases/2026-04-22-no-csf/` exists on GitHub because the packaging and release notes were posted there as part of this release work.

## Summary

The local workspace is significantly ahead of the current GitHub tree in three big ways:

1. There is a very large local graphics expansion beyond the current GitHub repo.
2. There are hundreds of local `Data/` and thousands of tracked `Graphics/` changes that alter the playable build directly.
3. There is a separate layer of local modding, installer, updater, and multiplayer tooling that is present in the workspace but not fully represented in the GitHub repo root yet.
