# Player Identity and Bedroom

This addon adds:

- a third `Nonbinary` player identity option in the active Kuray character select flow
- an expanded intro age range from `10` to `99`
- centralized they/them pronoun helpers for player-facing text
- a bedroom style choice during intro that reuses the existing room maps without gender-locking them
- a bedroom PC menu option that lets the player change their bedroom color/style later
- a free one-time intro hair dye customization step that reuses the existing outfit preview and dye logic

## Compatibility notes

- The addon is built as a managed mod in `Mods/player_identity_bedroom`.
- It avoids editing base script files or map RXDATA directly.
- Bedroom routing is patched at load time through targeted `load_data` overrides that keep the engine's native transfer commands intact.
- Existing saves keep their legacy bedroom behavior until a bedroom style is explicitly chosen on a new intro flow.
- The player's actual identity is stored separately from `VAR_TRAINER_GENDER`, while the framework variable stays binary for compatibility with existing event-page conditions and asset assumptions.
- Legacy saves from earlier addon revisions are migrated at runtime so a nonbinary save no longer leaves the base gender variable at `2`.

## Current asset assumption

The base game only exposes binary default player appearance assets in the intro preview. To stay framework-safe, the addon separates:

- player identity/pronouns
- presentation fallback for binary outfit assets

For the `Nonbinary` option, the addon preserves a binary presentation fallback for asset-driven systems while keeping the player's saved identity/pronouns as nonbinary.

## New message token

Future dialogue can use:

- `\pp[subject]`
- `\pp[object]`
- `\pp[possessive_adjective]`
- `\pp[possessive]`
- `\pp[reflexive]`
- `\pp[be]`
- `\pp[have]`
- `\pp[do]`

Prefix any token with `cap_` to capitalize it, for example `\pp[cap_subject]`.
