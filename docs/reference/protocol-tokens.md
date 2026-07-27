# Protocol tokens (speaking modifiers)

Canonical rules for string **values** matched outside Skyrim (prompts, Inja `contains`, case-sensitive tooling).

## Why wrap

Skyrim pools string identity **case-insensitively**. The first casing that loads wins; later casings collapse into that pool. Game casing is unstable across load orders.

For tokens that must match **outside** the game, wrap with underscores so the literal stays unique and stable:

- `_pleasure_`
- `_pain_`
- `_gagged_`
- `_kissing_`

Plain English (`pain`) is unsafe as a protocol value token.

## Where they appear

- SexLab scene JSON `speaking_modifiers` (consumed via SkyrimNet_SexLab)
- Activity / bio prompts: `contains(speaker.speaking_modifiers, "_pain_")` (case-sensitive)

Adding a token:

1. Emit `_yourtoken_` from scene settings / Papyrus (usually in SkyrimNet_SexLab).
2. Add matching `contains(..., "_yourtoken_")` in activity (and narration) prompts.
3. Document it here; for scene JSON shape see sibling mod `docs/reference/scene-settings.md`.

## Not the same as JSON keys

External JSON **keys** are bare lowercase (`speaking_modifiers`, `actors`). See [json-keys.md](json-keys.md). Lowercasing keys does **not** protect values.
