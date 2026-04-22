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

- `PIF-player-build-20260422-no-csf-WebSetup.exe` is the GitHub-friendly installer. It now carries the latest changed-file overlay inside the installer itself.
- If your target folder already looks like the public 2026-04-22 no-CSF release, the installer applies only the embedded changed files update.
- If your target folder is empty or missing the base release, the installer downloads the original 2026-04-22 no-CSF base package from GitHub first and then applies the embedded changed files update.
- The installer now has a dedicated `Update Only` button for existing installs, so players can skip the base download on purpose and apply just the latest bundled changed files.
- Payload files are split into GitHub-safe parts because GitHub cannot host this build as one single 11+ GB release asset.

## Installer refresh

- The web installer was refreshed after first release to use bundled native `7z` extraction for empty install folders, which is much faster than the original managed extraction path for this archive.
- The installer window layout was also adjusted so the action buttons are no longer clipped at the bottom on the affected display scale.
- The web installer was refreshed again later on 2026-04-22 to clean up canceled installs more safely, stage extraction before deployment, and remove stale temp payload files instead of leaving large leftovers behind.
- This refresh is meant to make download-and-install testing safer for players by reducing partial installs and wasted disk space after a cancel or failed run.
- The current installer refresh turns the public download into a cumulative overlay installer: only the changed packaged files are bundled into the new download, while clean installs still work because the installer can fetch the older base release automatically when needed.

## Current changed-file update

- The current embedded overlay contains `56` changed packaged files, about `4.432 MB` before compression and about `676 KB` as the embedded archive.
- Updated data files include `Data/pokedex/dex.json`, `Data/REMOTE_VERSION`, `Data/Scripts/DownloadedSettings.rb`, and `Data/sprites/CUSTOM_SPRITES`.
- Added art/content for new packaged species ids `1207` through `1211`, including battlers, EBDX sprites, icons, and imported `mongratis_community_sampler` Pokemon assets.
- Updated `Mods/counterfeit_shinies/002_Core.rb` and `Mods/counterfeit_shinies/004_Hooks.rb`.
- The full overlay file list is recorded in `PIF-player-build-20260422-no-csf-update1.manifest.txt`.

## Exclusions

- No personal save data
- No personal config or private state files
- No `custom_species_framework` content yet

## Install notes

1. Download `PIF-player-build-20260422-no-csf-WebSetup.exe`.
2. Run it.
3. Use `Update Only` if you already have Kuray Infinite Fusion installed in that folder and only want the latest changed files.
4. Use `Install / Repair` if this is a fresh install or if that folder may still need the base release files.

## Checksums

- The web installer checksum is provided in `PIF-player-build-20260422-no-csf-WebSetup.sha256.txt`.
- The packaged build manifest is included as `PIF-player-build-20260422-no-csf.manifest.txt`.
- The current changed-file overlay manifest is included as `PIF-player-build-20260422-no-csf-update1.manifest.txt`.
- Current web installer SHA-256: `16b22012adf9af87413e956ff9756966e0c17cc7556088dbcbfc4806ebe822df`

## Comparison Notes

- A local-workspace-vs-GitHub comparison note for this build is recorded in `LOCAL-VS-GITHUB-DIFF.md`.
