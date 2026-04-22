# Kuray Infinite Fusion Player Build - 2026-04-22

This release packages the current playable client from the updated `kurayshinyrevamp` build with the latest local gameplay, script, and content changes from this version of the project.

## Highlights

- Includes the current full playable client with sprites, mods, and multiplayer files needed for this build.
- Includes newer gameplay/content changes already staged in this local version, including the non-CSF updates that were packaged into the 2026-04-22 player build.
- Excludes personal information, save files, local logs, and machine-specific state.
- Excludes `custom_species_framework` and its generated assets for now.

## Notable included changes from this build

- Updated non-CSF mods and script changes from this local version of the game.
- Included mods verified in the packaged build such as `counterfeit_shinies`, `uncap_trainer_rematch_level`, and `MoveInCircles`.
- Includes the newer battle/chat script updates that were present in the packaged client when this release was built.

## Download options

- `PIF-player-build-20260422-no-csf-WebSetup.exe` is the GitHub-friendly installer. It downloads the game payload from this release and installs to your `Games` folder with shortcuts.
- Payload files are split into GitHub-safe parts because GitHub cannot host this build as one single 11+ GB release asset.

## Installer refresh

- The web installer was refreshed after first release to use bundled native `7z` extraction for empty install folders, which is much faster than the original managed extraction path for this archive.
- The installer window layout was also adjusted so the action buttons are no longer clipped at the bottom on the affected display scale.

## Exclusions

- No personal save data
- No personal config or private state files
- No `custom_species_framework` content yet

## Install notes

1. Download `PIF-player-build-20260422-no-csf-WebSetup.exe`.
2. Run it.
3. Let it download the release payload from GitHub and install the game to your `Games` folder.

## Checksums

- The web installer checksum is provided in `PIF-player-build-20260422-no-csf-WebSetup.sha256.txt`.
- The packaged build manifest is included as `PIF-player-build-20260422-no-csf.manifest.txt`.
