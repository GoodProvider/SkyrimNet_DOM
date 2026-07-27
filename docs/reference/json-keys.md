# External JSON keys

Canonical rules for JSON that Skyrim emits and external consumers read (decorators, paused actor files, `threads.json`, prompts).

## Rule

Use **bare lowercase** keys only:

- `speaking_modifiers`, `actors`, `uuid`, `loaded`, `arousal_factor`, `is_slave`, …

Do **not** invent Title Case or leading-`_` keys (`Actors`, `_actors`) for this pipeline.

Always serialize via `SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson` so export casing is stable under Skyrim’s string pool.

Protocol **values** (speaking modifiers) are separate — still `_pain_`, etc. See [protocol-tokens.md](protocol-tokens.md). Leading `_` is reserved for those values, not for JSON keys.

## DOM call sites

- Decorator `dom_get_actor_info` in [`Scripts/Source/SkyrimNet_DOM_Decorators.psc`](../../Scripts/Source/SkyrimNet_DOM_Decorators.psc)
- Paused actor JSON written by Events `SaveActorInfo` under `SKSE/Plugins/SkyrimNet_DOM/actors/`

SexLab thread/scene export uses the same utility in the SkyrimNet_SexLab tree.
