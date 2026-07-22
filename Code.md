# Developer guide (Papyrus)

How SkyrimNet_DOM bridges Diary of Mine to SkyrimNet. For YAML/prompt editing, see [Actions](Actions.md) and [Prompts](Prompts.md). Overview: [README](README.md).

Full Papyrus / string-pool conventions: [AGENTS.md](AGENTS.md).

## Role

Bridge **Diary of Mine** ↔ **SkyrimNet**, with sex/punish scenes going through **SkyrimNet_SexLab**. Do **not** modify Diary of Mine scripts — call `DOM_Keys` / `DOM_API` / `DOM_Actor` only.

## Key paths

| Path | Role |
|------|------|
| `Scripts/Source/` | Edit Papyrus (`.psc`) here |
| `Scripts/` | Compiled `.pex` output |
| `Headers/` | Import headers for Caprica / project |
| `skyrimse.ppj` | Papyrus project (imports + compile) |

## Script map

| Script | Responsibility |
|--------|----------------|
| `SkyrimNet_DOM_Main` | Init / Setup; load punishment indexes + `punishment_reason.json`; register decorators; kick Actions/Events Setup |
| `SkyrimNet_DOM_Events` | DOM → Direct Narration / `RegisterEvent` / short-lived events; SexLab anim start/end hooks |
| `SkyrimNet_DOM_Actions` | YAML-callable executes: scenes, masturbate, dress/undress, `AddPunishmentReason` |
| `SkyrimNet_DOM_API` | Shared helpers (`GetSlave`, `AddPunishmentReason`, scene wrappers, tracing) |
| `SkyrimNet_DOM_Decorators` | Registers `dom_get_actor_info` for prompts |
| `SkyrimNet_DOM_Menu` | Stub (old target menu removed) |
| `SkyrimNet_DOM_PlayerRef` | Load-game refresh |

Legacy `Register_Actions()` from `actions.json` is commented out — SkyrimNet loads YAML from `config/actions/` instead.

## Punishment pipeline

1. DOM’s `PunishmentReasons.json` (StorageUtilData) → numeric indexes
2. `SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json` → LLM-facing names / aliases → those indexes
3. YAML refuse / PunishementOther → `SkyrimNet_DOM_Actions.AddPunishmentReason` → `SkyrimNet_DOM_API.AddPunishmentReason`

New reasons need both a valid DOM index and an entry (or alias) in `punishment_reason.json`, plus the helper prompt list when the LLM must choose them.

## When YAML is not enough

1. Add or change a Papyrus function on `SkyrimNet_DOM_Actions` (or API helper)
2. Recompile via `skyrimse.ppj` (or Caprica with the same imports)
3. Point YAML `scriptName` / `executionFunctionName` / `parameterMapping` at the new signature
4. Keep Headers in sync if you maintain stripped headers for Caprica

Parameter names and counts in YAML must match Papyrus exactly.

## Conventions (short)

- Functions/Events: UpperCamelCase matching `EndFunction` / `EndEvent`
- Variables/properties: lowerCamel / snake mix
- Arrays: use `if a` — never `if a == None` (runtime error)
- JSON emitted for external consumers: keys start with `_`
- Protocol tokens for case-sensitive matching: wrap in underscores (`_gagged_`)

See [AGENTS.md](AGENTS.md) for the full list.

## Compile / tools

- Project compile: `skyrimse.ppj` (preferred for this repo)
- Caprica / Champollion: see tools notes in AGENTS.md
- Always include commented lines when citing line numbers

## Dependencies in code

Setup fails without Diary of Mine. Actions/Events bind to `SkyrimNet_SexLab.esp` for scene manager / SexLab hooks. OStim / UDNG are soft checks where present.
