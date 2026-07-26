# Editing YAML actions

Users are expected to tweak and add SkyrimNet actions. This guide covers the DOMSlave YAML set.

See also: [README](README.md) · [Prompts](Prompts.md) · [Code](Code.md)

## Where

Authoritative actions live here:

```
SKSE/Plugins/SkyrimNet/config/actions/DOMSlave_*.yaml
```

Do **not** use `SKSE/Plugins/SkyrimNet_DOM/actions.json` — that file is legacy and is no longer registered.

## Copy a sibling

Start from an existing file in the same family:

| Family | Examples | Typical executor |
|--------|----------|------------------|
| `Be_` | flatter, insult, praise-tell, promises, scold, refuse | `DOM_Keys` / `DOMDoActionActor` |
| `Act*` | `ActSilent`, `ActRespectful`, `ActMyMaid` | `DOM_Keys` |
| `Pose_` | display, dance, chair, presentations | `DOM_Keys` |
| FightForMe / chores / movement / drink | Follow, Kneel, DoFlowers, DrinkAlcohol | `DOM_Keys` |
| Dress / Undress | `DOMSlave_Dress.yaml`, `DOMSlave_Undress.yaml` | `SkyrimNet_DOM_Actions` |
| `sex_` / masturbate / stop-masturbate | start, refuse, harder, stop allowed/disallowed | `SkyrimNet_DOM_Actions` |
| `punish_` | spanking, whipping/oral, refused, other | `SkyrimNet_DOM_Actions` |

Category parents (e.g. `DOMSlave_Be_.yaml`, `DOMSlave_Pose_.yaml`) group related actions — keep `customCategory` aligned with siblings.

## Key fields

| Field | Role |
|-------|------|
| `name` | Unique action id (e.g. `DOMSlave_Be_PraisedTell`) |
| `description` | LLM-facing text — this drives action **selection** |
| `customCategory` | Groups the action for SkyrimNet (e.g. `SkyDOM_Be`) |
| `enabled` | `false` to disable without deleting |
| `questEditorId` | Quest that owns the script (`DOM02Topic` for DOM_Keys, `SkyrimNet_DOM` for our Actions) |
| `scriptName` | Papyrus script to call |
| `executionFunctionName` | Function on that script |
| `parameterMapping` | Maps LLM/runtime args → Papyrus parameters |
| `eligibilityRules` | When the action may appear |
| `defaultPriority` | Optional priority hint |

## Two execution styles

### 1. DOM_Keys (social / pose / chore)

Calls Diary of Mine directly. Example: [`DOMSlave_Be_PraisedTell.yaml`](SKSE/Plugins/SkyrimNet/config/actions/DOMSlave_Be_PraisedTell.yaml)

- `scriptName: DOM_Keys`
- `executionFunctionName: DOMDoActionActor`
- Static params usually include `the_event` (e.g. `Praise`), `type` (e.g. `tell`), and `the_flag`

Copy a `Be_` or `Pose_` sibling and change the static event/type values to match DOM’s expected strings.

### 2. SkyrimNet_DOM_Actions (sex / punish / dress)

Calls our bridge, which talks to DOM and/or SkyrimNet_SexLab. Example: [`DOMSlave_punish_spanking.yaml`](SKSE/Plugins/SkyrimNet/config/actions/DOMSlave_punish_spanking.yaml)

Common execute functions:

- `StartScene_Consensual_Two` / `StartScene_Nonconsensual_Two`
- `StartScene_masturbate` / `StopScene_Masturbate`
- `UndressDress_Execute` / `Dress_Execute`
- `AddPunishmentReason`

**Parameter names in YAML must match the Papyrus function signature** (see [Code](Code.md)). Wrong names or counts fail at runtime.

Dress also uses Papyrus eligibility helpers:

```yaml
eligibilityScriptName: SkyrimNet_DOM_Actions
eligibilityFunctionName: Dress_IsEligible
```

## parameterMapping types

- `speaker` — the acting NPC (usually the slave)
- `static` — fixed `value` (event name, method, flags)
- `dynamic` — filled by the LLM / SkyrimNet (e.g. `superior`, `target`, `style`, `reason`)

Keep `name` identical to the Papyrus / DOM argument name.

## Eligibility

Reuse conditions from a sibling. Common pattern for slaves:

- In `DOMPlayerSlaveFaction` (rank as required by siblings)
- Not in combat
- Not SexLab-animating / OStim / device faction
- Not holding `skyrimnet_sexlab_scene_actor_lock`

Tighten rules for scene actions; keep social `Be_` rules lighter when appropriate.

## Punishment reasons

Refuse / punish-other actions pass a `reason` string into `AddPunishmentReason`. Those strings must resolve via:

- `SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json` (aliases + narration)
- DOM’s own punishment indexes
- Helper prompt: `SKSE/Plugins/SkyrimNet/prompts/helpers/dom_punishment_reason.prompt`

Adding a **new** reason needs the JSON (and a valid DOM index) — a YAML-only change is not enough.

## Disable vs delete

Prefer `enabled: false` over deleting files (physical praise and Pose_Submissive already use this).

## Tips

- Optimize `description` for LLM selection clarity, not long prose
- After changing Papyrus execute functions, recompile and update YAML mappings together
- Test eligibility by checking faction / scene state of the speaker
