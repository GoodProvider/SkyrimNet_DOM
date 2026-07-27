# Editing YAML actions

Users are expected to tweak and add SkyrimNet actions. This guide covers the DOMSlave YAML set.

See also: [prompts.md](prompts.md) · [punishment.md](punishment.md) · [events.md](events.md) · [../developers/papyrus.md](../developers/papyrus.md)

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
| `sex_` / masturbate / stop-masturbate | 2P penis / no_penis, 3P, refuse, harder, stop allowed/disallowed | `SkyrimNet_DOM_Actions` |
| `punish_` | spanking, whipping/oral, refused, other | `SkyrimNet_DOM_Actions` |

Category parents (e.g. `DOMSlave_Be_.yaml`, `DOMSlave_Pose_.yaml`) group related actions — keep `customCategory` aligned with siblings.

Two-person consensual sex is split into siblings (copy the matching one):

| File | Action name | `setting_name` | Notes |
|------|-------------|----------------|-------|
| `DOMSlave_sex_start_2_penis.yaml` | `DOMSlave_Sex_Two_Fucking` | `""` | Maps `style`; methods `pussy\|mouth\|ass` |
| `DOMSlave_sex_start_2_no_penis.yaml` | `DOMSlave_Sex_Two_Giving` | `"no_penis"` | Maps `style`; oral/handjob-style methods |

There is no monolithic `DOMSlave_sex_start_2.yaml`.

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

## Hard limit: 8 parameters

SkyrimNet has a **hard limit of 8 parameters** on action YAMLs (`parameterMapping` entries passed to `ExecuteQuestFunction`). A 9th argument will not work — trim static/dynamic params, fold values into Papyrus defaults, or split into separate actions.

## Two execution styles

### 1. DOM_Keys (social / pose / chore)

Calls Diary of Mine directly. Example: [`DOMSlave_Be_PraisedTell.yaml`](../../SKSE/Plugins/SkyrimNet/config/actions/DOMSlave_Be_PraisedTell.yaml)

- `scriptName: DOM_Keys`
- `executionFunctionName: DOMDoActionActor`
- Static params usually include `the_event` (e.g. `Praise`), `type` (e.g. `tell`), and `the_flag`

Copy a `Be_` or `Pose_` sibling and change the static event/type values to match DOM’s expected strings.

### 2. SkyrimNet_DOM_Actions (sex / punish / dress)

Calls our bridge, which talks to DOM and/or SkyrimNet_SexLab. Example: [`DOMSlave_punish_spanking.yaml`](../../SKSE/Plugins/SkyrimNet/config/actions/DOMSlave_punish_spanking.yaml)

Common execute functions:

- `StartScene_Consensual_Two` / `StartScene_Nonconsensual_Two`
- `StartScene_masturbate` / `StopScene_Masturbate`
- `UndressDress_Execute` / `Dress_Execute`
- `AddPunishmentReason`

**Parameter names in YAML must match the Papyrus function signature** (see [../developers/papyrus.md](../developers/papyrus.md)). Wrong names or counts fail at runtime. Stay within the **8-parameter** hard limit above.

`StartScene_Consensual_Three` and `StartScene_Nonconsensual_Two` omit `style` from the quest mapping and always pass `style=""` into SexLab. Two-person consensual YAML (`sex_start_2_penis` / `sex_start_2_no_penis`) still maps `style` into `StartScene_Consensual_Two`.

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

## Eligibility recipes

Reuse conditions from a sibling. Slave vs non-slave is a **faction rank**, not a boolean.

### `DOMPlayerSlaveFaction` rank

| Pattern | Typical check | Examples |
|---------|---------------|----------|
| Player slave | `get_faction_rank` `== 1` (or category parent `> 0`) | Follow, Dress, Pose, most `Be_` children |
| Non-slave | `get_faction_rank` `== -1` | `DOMSlave_Follow_non_slave.yaml`, `DOMSlave_*_non_slave.yaml` |

Copy a `*_non_slave.yaml` sibling when the order should apply to non-slaves (often a different `scriptName` / SkyrimNet library execute).

### Scene / device lock stack

Most movement / pose / sex / punish actions also require the speaker is free:

| Check | Intent |
|-------|--------|
| `is_in_combat` == false | Not fighting |
| `SexLabAnimatingFaction` rank `< 1` | Not in SexLab anim |
| `OStimActorCountFaction` not in faction (where used) | Not in OStim |
| `dse_dm_FactionActorUsingDevice` not in faction | Not on a device |
| `DOMActionTied` rank `< 0` (where used) | Not DOM-tied for that action |
| `papyrus_util` `HasIntValue` `skyrimnet_sexlab_scene_actor_lock` == false | Not locked by SkyrimNet_SexLab scene |

Category parents (`DOMSlave_Be_.yaml`, `DOMSlave_Pose_.yaml`, `DOMSlave_sex_.yaml`, …) often define the shared lock stack — keep children aligned.

Tighten rules for scene actions; keep social `Be_` rules lighter when appropriate.

### Papyrus eligibility helpers

Dress / undress also call script-side checks:

```yaml
eligibilityScriptName: SkyrimNet_DOM_Actions
eligibilityFunctionName: Dress_IsEligible   # or Undress_IsEligible
```

YAML faction rules alone are not enough for those actions.

## Punishment reasons

Refuse / punish-other actions pass a `reason` string into `AddPunishmentReason`. Full checklist: [punishment.md](punishment.md).

Short version: strings must resolve via `punishment_reason.json` + DOM indexes + `dom_punishment_reason.prompt`. YAML-only changes are not enough.

## Disable vs delete

Prefer `enabled: false` over deleting files (physical praise and Pose_Submissive already use this).

## Tips

- Optimize `description` for LLM selection clarity, not long prose
- After changing Papyrus execute functions, recompile and update YAML mappings together
- Test eligibility by checking faction / scene state of the speaker
