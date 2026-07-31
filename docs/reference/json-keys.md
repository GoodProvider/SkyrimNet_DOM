# External JSON keys

Canonical rules for JSON that Skyrim emits and external consumers read (decorators, paused actor files, `threads.json`, prompts).

## Rule

Use **bare lowercase** keys only:

- `speaking_modifiers`, `actors`, `uuid`, `loaded`, `arousal_factor`, `is_slave`, `dom_faction`, …

Do **not** invent Title Case or leading-`_` keys (`Actors`, `_actors`) for this pipeline.

Always serialize via `SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson` so export casing is stable under Skyrim’s string pool.

Protocol **values** (speaking modifiers) are separate — still `_pain_`, etc. See [protocol-tokens.md](protocol-tokens.md). Leading `_` is reserved for those values, not for JSON keys.

## DOM `dom_get_actor_info` buckets

Decorator: [`Scripts/Source/SkyrimNet_DOM_Decorators.psc`](../../Scripts/Source/SkyrimNet_DOM_Decorators.psc).  
Paused actor JSON: Events `SaveActorInfo` under `SKSE/Plugins/SkyrimNet_DOM/actors/`.

### Thin (every loaded DOMActor)

`loaded`, `source`, `name`, `is_slave`, `is_slaver`, `dom_faction` (`slave` \| `slaver` \| `other`), `history_rank`, `notifications`, `mood_sentence`, `behaviour`, arousal triad, `known_fetishes`, `hidden_fetishes`, gear/`has_*` / `is_naked` / dirty/wet / tears/mark, `virgin.{vaginal,oral,anal,same,gangbang}`.

### Slaver (`dom_faction == "slaver"`)

`title`, `trainee_count`, `trainee_names`, `is_love_interest`, `camp_name`, `skills.*`, `career.*`.

### Slave (`is_slave`)

`owner`, `is_obedient`, `is_trainer`, `title`, `training_mind`, `training_sex`, `punishment`, love/devoted/ashamed, restrained/bound/jailed, `orders.*`, `is_walking_on_four`, `is_respectful`, `family_history_rank`, `promise_rank`, `promise_oath`, `experience.*`, `trauma_days`, `love.*`, `loyal.*`.

Prompts must not read slaver-only or slave-only keys without the matching gate (missing keys throw).

SexLab thread/scene export uses the same lowercase-key utility in the SkyrimNet_SexLab tree.
