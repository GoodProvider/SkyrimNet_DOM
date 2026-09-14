# Editing prompts

Users are expected to tweak DOM prompt files for bio context and action-selection instructions.

See also: [actions.md](actions.md) · [punishment.md](punishment.md) · [events.md](events.md) · [../reference/json-keys.md](../reference/json-keys.md) · [../reference/protocol-tokens.md](../reference/protocol-tokens.md)

## Trees

| Path | Namespace rule |
|------|----------------|
| `SKSE/Plugins/SkyrimNet/external/goodprovider.dom/prompts/submodules/character_bio/` | **Shared namespace** across files. Numeric prefixes control order (`0006` runs before `0410`). |
| `SKSE/Plugins/SkyrimNet/external/goodprovider.dom/prompts/submodules/user_final_instructions/` | **Each file is its own namespace** — locals do not carry across files. |
| `SKSE/Plugins/SkyrimNet/external/goodprovider.dom/prompts/helpers/` | Shared helpers for actions/reasons (e.g. `dom_punishment_reason.prompt`, sex-start helpers). |

SkyrimNet_DOM also works alongside SkyrimNet_SexLab prompts under that mod’s `SKSE/Plugins/SkyrimNet/external/goodprovider.sexlab/prompts` tree.

## character_bio (shared namespace)

`0006_dom_variables.prompt` loads `dom_actor` for later bio slices. Later files (`0015`–`0031`, `0305`, `0410`, `0413`, `0515`, `7200`, …) assume those variables exist.

### DOM actor load pattern

Typical flow:

1. Check `DOMActorFaction` (any DOM actor: slave, slaver, or other)
2. If live (not paused): `dom_get_actor_info(actorUUID)` (Papyrus decorator)
3. Else / fallback: `read_json("SkyrimNet_DOM/actors/<name>.json")` (written by Events `SaveActorInfo` on DN — see [events.md](events.md))
4. Gate output on `dom_actor.loaded`

Do **not** re-`read_json` into `dom_actor` after it is already loaded — that clobbers Papyrus data (this bit `0413` before).

Decorator JSON uses **bare lowercase** keys via `ObjectToLowerCaseKeyJson`. Payload is three exclusive buckets — see [../reference/json-keys.md](../reference/json-keys.md):

| Bucket | Gate in prompts | Examples |
|--------|-----------------|----------|
| **thin** | `dom_actor.loaded` | role flags, history, fetishes, gear, arousal, virgin, notifications |
| **slaver** | `dom_faction == "slaver"` | title, trainees, skills, career, camp, love interest |
| **slave** | `dom_actor.is_slave` | owner, training, punishment, orders, experience, love/loyal, promise |

**Presentation rule:** 0–100 scales → qualitative sentences (see `0515`, `0016`, `0031`). Counters (`trauma_days`, `career.*`, `experience.*`, `trainee_count`) stay numeric. Fixed ranks (`history_rank`, `family_history_rank`, virgin, promise) → one short sentence each.

Paused JSON may lack newer keys until the next DN/`SaveActorInfo` refresh — use `existsIn` when reading optional fields.

### Render gates

Bio files usually gate on render mode, e.g.:

- `show_internal` — full / thoughts / transform / equipment, etc.
- `show_external_only` — `dialogue_target` (what others see)

Do not dump internal-only state into external dialogue modes.

### Adding a bio slice

1. Pick a numeric prefix for sort order relative to existing files
2. Gate on the matching bucket (`loaded` / `dom_faction == "slaver"` / `is_slave`)
3. Read fields already on `dom_actor` — bare lowercase keys
4. Keep one job per file (appearance vs bondages vs skills vs notifications)

| Prefix | File | Role |
|--------|------|------|
| 0006 | variables | load `dom_actor` |
| 0015 | characteristics | status, fetishes, history |
| 0016 | slaver | trainees, skills sentences, career |
| 0017 | orders | slave standing orders |
| 0018 | promise / virgin | slave promise; virgin for all loaded |
| 0030 | experience | slave counters + trauma_days + family history |
| 0031 | love / loyal | slave syndrome sentence bands |
| 7200 | notifications | `## Slavery Events` |

## user_final_instructions

`0551_dom_instructions.prompt` biases action selection for **slaves** (`DOMPlayerSlaveFaction` / `is_slave`). Prefer DOMSlave actions, gag/obedience context, etc.

Because each file is isolated:

- Redefine any locals you need inside this file
- Edit carefully — this heavily steers the LLM’s action choices

## Helpers

- `helpers/dom_punishment_reason.prompt` — allowed punishment reason strings for the LLM (keep in sync with `punishment_reason.json`)
- Sex-start helpers — used by older/legacy action description templates

When you add a new punish reason to JSON, update the helper list too — full checklist: [punishment.md](punishment.md).

## SexLab coexistence

Some prompts peek at SexLab state via:

- Globals / decorators from SkyrimNet_SexLab
- `read_json("SkyrimNet_SexLab/threads.json")` when time is paused

Do not invent ad-hoc JSON keys for data Skyrim emits. Keys: [../reference/json-keys.md](../reference/json-keys.md). Protocol values: [../reference/protocol-tokens.md](../reference/protocol-tokens.md).

## Tips

- Prefer small, ordered bio files over one giant prompt
- Test both live (decorator) and paused (JSON file) paths when changing `dom_actor` loading
- After changing action names or categories in YAML, update user instructions that mention them
