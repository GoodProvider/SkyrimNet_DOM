# DOM WebUI interaction contract

Source of truth for SexLab ControlPanel mode **SkyrimNet DOM**. Catalog JSON and `SkyrimNet_DOM_Menu` `TM_*` must match this file. Diary of Mine sources are read-only.

Player path: SexLab overlay hotkey (`\`) → ControlPanel mode **SkyrimNet DOM** → target pulldown (nearby + **All Slaves**) → left TargetMenu commands → right **Status** or **Slaves**.

Do **not** call any `DOM_Keys` function that `OpenMenu()` / `UIWheelMenu` / `Message.Show` (`DOMDo*Menu`, `ShowCall*`, `ShowDOM*`, `DOMAll*Menu`, `DOMWheelTraits` as a blocking wheel). Call leaves only.

---

## Input model

| Control | Role |
|---------|------|
| Mode pulldown | `sexlab` / `skyrimnet_dom` (and future JSON). Swap unloads the previous TargetMenu + main-panel set. |
| Views pulldown | Per-mode MainPanels + **None**. DOM: **Status**, **Slaves**. Hide SexLab Scene Menu / Animation. Hide OStim framework row. Log/Settings stay SexLab-only (not shown in DOM). |
| Target pulldown | Nearby actors as SexLab today, plus sentinel **All Slaves** (`id: all_slaves`, no FormID). Player stays a normal actor. Do **not** treat player focus as group. |
| Crosshair | Still seeds the default actor on overlay open. First DOM-mode open with player selected may stay on the player; All Slaves is an explicit pick. |

Selecting **All Slaves**:

- `Target_Current` is `None`; `focusKind = all_slaves`
- TargetMenu rebuilds with group eligibility
- Views switch to **Slaves** (roster is primary)
- **Status** in this focus shows a group count summary — not a stale single-slave editor

Row click on Slaves: `onMainPanelRow` → set `Target_Current` to that FormID (allowed if far; SexLab already keeps current focus in the nearby list) → open **Status**.

---

## closeWebUI

| Surface | `closeWebUI` | Why |
|---------|--------------|-----|
| TargetMenu execute | `true` | `Focus(..., pause=true)` blocks SexLab `StartThread` and DOM packages |
| Status / Slaves open, config toggles | `false` | Player can flip several flags. Mind-flag leaves apply immediately. Package work (task / jail / follow) runs when the overlay later hides |

---

## Eligibility

C++ evaluates `eligibilityRules` at catalog build (not a paused Papyrus decorator). Fail the gate **or** leave a pulldown with zero children → the option is omitted.

New condition (SexLab host):

```json
{ "decoratorName": "webui_focus_kind", "comparisonOperator": "==", "expectedValue": "all_slaves" }
```

`!=` omits the row when the sentinel is selected. Existing `is_in_faction` / `get_faction_rank` / `is_in_combat` still apply when `currentActor` is set; they fail closed if focus is the sentinel.

Actor-type snippets (boolean `expectedValue` is fine; SexLab `AsNumber`):

```json
{ "decoratorName": "get_faction_rank", "arguments": ["currentActor", "DOMPlayerSlaveFaction"], "comparisonOperator": ">", "expectedValue": 0 }
{ "decoratorName": "is_in_faction", "arguments": ["currentActor", "DOMPlayerSlaverFaction"], "comparisonOperator": "==", "expectedValue": true }
```

| Who | Rule |
|-----|------|
| Single slave | `webui_focus_kind != all_slaves` and `DOMPlayerSlaveFaction` rank `> 0` (includes trainer rank 2) |
| Trainer | slave faction rank `== 2` |
| Slaver | `DOMPlayerSlaverFaction` |
| NPC | not slave, not slaver |
| All Slaves | `webui_focus_kind == all_slaves` |
| On duty | `DOMActionOnDuty` — omit follow/stand/wait/masturbate/task (vanilla lock); bag still allowed |

Each TargetMenu pulldown has a root `logicalOperator: OR` gate so the left column shows only pulldowns that can be used **on** the focused actor. Slave-only pulldowns are omitted when the target is not a slave.

| Pulldown | Usable on | Omitted for |
|----------|-----------|-------------|
| order | slave **or** slaver **or** All Slaves | NPC / player |
| abuse | slave **or** slaver **or** NPC **or** All Slaves | — |
| training | slave **or** slaver **or** All Slaves | NPC / player |
| restrain | slave **or** All Slaves | slaver / NPC / player |
| clothes | slave **or** All Slaves | slaver / NPC / player |

Fleeing actors: wheels no-op (`DOMCore.IsFleeing`). Omit via combat/flee when a C++ condition exists; Papyrus leaves still return early.

---

## TargetMenu (unified left column)

One JSON file each under `SKSE/Plugins/SkyrimNet_DOM/webui/TargetMenu/Actor/options/`. **Status is not a row. Group is not a row.**

Speaker is always the player. Target is `currentActor`, or `None` for All Slaves.

### v1 rows

#### `1100_order.json` — order

| Label | Who | Leaf | YAML twin | close |
|-------|-----|------|-----------|-------|
| Inventory | single slave / slaver | `DOMDoOpenInventory` | — | true |
| Follow me | single slave / slaver, not on duty | `DOMDoFollowMe` | `DOMSlave_DOMFollowNonSlave` / follow family | true |
| Follow all | All Slaves | `DOMAllOrderSlavesAndSlavers("Follow")` | — | true |
| Stand still | single slave / slaver, not on duty | `DOMDoStandStill` | `DOMSlave_StandHere` | true |
| Stand all | All Slaves | `DOMAllOrderSlavesAndSlavers("StandStill")` | — | true |
| Wait here | single slave / slaver, not on duty | `DOMDoWaitSandbox` | — | true |
| Wait all | All Slaves | `DOMAllOrderSlavesAndSlavers("WaitHere")` | — | true |
| Favor | single slave / slaver | `DOMDoFavor` | — | true |
| Put in bag | single slave | `DOMDoPutInBag` | — | true |
| All in bag | All Slaves | `DOMAllOrderSlaves("InBag")` | — | true |
| Open bags | All Slaves | `DOMAllOrderSlaves` bag-out / `OutBag` | — | true |
| Gather bags | All Slaves | `DOMAllOrderSlaves` `GatherBag` | — | true |
| Untie | single restrained | `DOMDoUntie` | — | true |
| Pose (display) | single slave | `DOMDoDisplay` | `DOMSlave_Display` | true |
| Pose all | All Slaves | `DOMAllOrderSlaves("Display")` | — | true |

Follow distance / cuff / leash / walk-on-4 nested choosers: v1 ships Follow only; richer follow modes are v2.

#### `1110_abuse.json` — abuse (slaver wheel: Speech)

| Label | Who | Leaf | YAML twin | close |
|-------|-----|------|-----------|-------|
| Praise | single slave / slaver | `DOMDoPraise` | `DOMSlave_Be_PraisedTell` | true |
| Praise all | All Slaves | `DOMAllOrderSlavesAndSlavers("Praise")` | — | true |
| Scold | single slave / slaver | `DOMDoScold` | `DOMSlave_BeScolded` | true |
| Scold all | All Slaves | `DOMAllOrderSlaves("Scold")` | — | true |
| Insult | single slave / slaver / NPC | `DOMDoInsult(actor, type)` | `DOMSlave_Be_InsultedDegrading` | true |
| Insult all | All Slaves | `DOMAllOrderSlaves("Insult")` | — | true |
| Flatter | single slave / slaver / NPC | `DOMDoFlatter(actor, type)` | `DOMSlave_Be_FlatteredSexy` | true |
| Flatter all | All Slaves | `DOMAllOrderSlaves("Flatter")` | — | true |
| Promise | single slave | `DOMDoActionActor(..., "Promise", type, …)` | `DOMSlave_BePromised*` | true |
| Promise all | All Slaves | `DOMAllOrderSlaves("…")` via promise event | `DOMSlave_Be_PromisedFreedom` | true |
| Punish (default) | single slave | `SkyrimNet_DOM_Actions.AddPunishmentReason` + existing punish scene | `DOMSLAVE_Punish` / spanking / whipping | true |

Punish-reason chooser: v1 uses default / next queued reason. Full reason picker is v2. Do not call `DOMDoAbuseMenu`.

#### `1120_training.json` — training (slaver wheel: Physical)

SexLab sex/punish/outfit rows are **hidden** in DOM mode, so sex lives here.

| Label | Who | Leaf | YAML twin | close |
|-------|-----|------|-----------|-------|
| Attention / display / salute / kneel | single slave | `DOMDoAttention` / `DOMDoDisplay` / `DOMDoSalute` / `DOMDoKneel` | `DOMSlave_Display`, `DOMSlave_Kneel` | true |
| Attention all | All Slaves | `DOMAllOrderSlaves("Attention"|"Display"|"Salute"|"Kneel")` | — | true |
| Masturbate | single slave, not on duty | `SkyrimNet_DOM_Actions.StartScene_masturbate` | masturbate YAML | true |
| Masturbate all | All Slaves | `DOMAllOrderSlaves("Masturbate")` | — | true |
| Sex | single slave / slaver | `StartScene_Consensual_Two` | `DOMSlave_Sex_Two_*` | true |
| Rape | single slave | `StartScene_Nonconsensual_Two` | punish/rape YAML | true |
| Inspect (front) | single slave | `DOMDoActionActor` inspect / `DOMSlave_InspectFront` | `DOMSlave_InspectFront` | true |

Do **not** nest Clothes here (vanilla Training slot 0). Clothes pulldown owns that. Orgasm allow/deny lives on **Status**, not this row.

#### `1130_restrain.json` — restrain (DOM furniture, not DD)

| Label | Who | Leaf | close |
|-------|-----|------|-------|
| Tie (default pose) | single slave | `DOMTiedUpByIndex(target, 0, false, false)` | true |
| Untie | single slave | `DOMDoUntie` | true |
| Tie all (default) | All Slaves | `DOMAllOrderSlaves("TieUp")` | true |
| Chains / post / cage (default index) | single slave | `DOMChains` / `DOMPost` / `DOMCage` via `*ByIndex(..., 0, false, false)` | true |

Furniture-variant and gag/blindfold choosers are v2. Do not call `DOMDoTieUpMenu` / `ShowDOM*`. Do not use SexLab `panel: bondage`.

#### `1140_clothes.json` — clothes (DOM state, not SexLab outfit)

| Label | Who | Leaf | YAML twin | close |
|-------|-----|------|-----------|-------|
| Strip | single slave | `DOMDoStrip` | `DOMSlave_Undress` | true |
| Strip all (actor) | single slave | `DOMDoStripAll` | — | true |
| Be naked | single slave | `DOMDoBeNaked` | — | true |
| Dress | single slave | `SkyrimNet_DOM_Actions.Dress_Execute` | `DOMSlave_Dress` | true |
| Be naked all | All Slaves | `DOMAllOrderSlaves("BeNaked")` | — | true |
| Strip all slaves | All Slaves | `DOMAllOrderSlaves("Strip"|"StripAll")` | — | true |

---

### v2 TargetMenu (not shipped)

`management`, `trainees`, `services`; sack; richer punish-reason / furniture-variant / follow-mode choosers; personality/feelings edit widgets.

---

## Main panels

Install under `SKSE/Plugins/SkyrimNet_DOM/webui/MainPanels/`.

### Status — `0100_status.json` (`actor_detail`)

Focused actor. Empty/wrong bucket must not happen: slave / trainer / slaver / NPC use the matching [json-keys.md](../docs/reference/json-keys.md) bucket from `Get_Actor_Info` / `FillSlaveFields`.

**Read-only (v1):** name, title, owner, trainer (`is_trainer` + `GetTrainer()` display name — UI field `trainer`, not a new decorator key), standing order (`behaviour` via `slave_behaviours.json`), mood sentence, obedient, `training_mind` / `training_sex`, punishment next/current, restrained / bound / jailed, `orders.*`, arousal triad, gear flags, promise, love/loyal. Personality / feelings / long status text: display strings from `DOMDoStatus` / `DOMDOMood` / `DOMWheelTraits` / `NPCWheelFeelings` **message helpers** (`NPCStatsMessage`, `NPCMoodMessage`, `DOMTraitsMessage`, `NPCFeelingsMessage`) — never `OpenMenu()`.

**Config (old Status wheel):** respectful, silent, fight for me, orgasm allow/deny, task (maid / `DOMDoWork` types 1–6 / jail).

| Control | Leaf |
|---------|------|
| Respectful | `DOMDoBeRespectful` |
| Silent | `DOMDoBeSilent` |
| Fight | `DOMDoFightForMe` |
| Orgasm | `DOMDoSetOrgasmStatus` |
| Maid / sweep | `DOMDoCleanTheMess` |
| Work 1–6 | `DOMDoWork(actor, type)` |
| Jail | `DOMDoJail` |

Papyrus: `TM_StatusPanelOpen` / `TM_StatusPanelClose` / `TM_StatusApply`.

All Slaves: push a count summary (`owned`, `nearby`, `on_duty`, `restrained`) — no per-slave toggles.

### Slaves — `0200_slaves.json` (`data_table`)

All owned slaves via `DOM02.actorAliases` / `GetMaxActorCount()` (not `GetActorCount` / `actorArray` — those lag). Not nearby-only.

v1 columns: Name, Trainer, Standing order, Duty/task, Respectful, Silent, Fight, Orgasm, Restrained/jailed, Next punishment.

Cap at 43 rows (MCM page size). If more aliases exist, set `truncated: true`. Click row → FormID focus → Status.

Papyrus: `TM_SlavesPanelOpen` / `TM_SlavesPanelClose`.

---

## ControlPanel registration

Canonical file in this repo:

`SKSE/Plugins/SkyrimNet_DOM/webui/ControlPanel/0200_skyrimnet_dom.json`

FOMOD / install copies it to `Data/SKSE/Plugins/SkyrimNet_SexLab/webui/ControlPanel/`.

```json
{
  "id": "skyrimnet_dom",
  "label": "SkyrimNet DOM",
  "requiresPlugin": "SkyrimNet_DOM.esp",
  "catalogRoot": "SKSE/Plugins/SkyrimNet_DOM/webui",
  "plugin": "SkyrimNet_DOM.esp",
  "questFormId": "0x800",
  "scriptName": "SkyrimNet_DOM_Menu",
  "openFunction": "TM_ModeOpened",
  "closeFunction": "TM_ModeClosed",
  "hideFramework": true,
  "sentinels": [{ "id": "all_slaves", "label": "All Slaves" }]
}
```

Built-in SexLab mode: `id` `sexlab`, `label` `SkyrimNet SexLab`, implicit catalog = SexLab `webui/`.

---

## Papyrus dispatcher (`SkyrimNet_DOM_Menu` on quest `0x800`)

Trace tag: `SkyrimNet_DOM_Menu` (not `SkyrimNet_DOM_Event`).

| Function | Role |
|----------|------|
| `TM_ModeOpened` / `TM_ModeClosed` | Zero-arg |
| `TM_StatusPanelOpen` / `TM_StatusPanelClose` | Build `actor_detail` JSON; `WebUI_PushMainPanelData` |
| `TM_SlavesPanelOpen` / `TM_SlavesPanelClose` | Walk aliases; `data_table` JSON |
| `TM_StatusApply(speaker, target, control, value)` | respectful / silent / fight / orgasm / task / jail |
| `TM_DoOrder(speaker, target, eventName, type, flag)` | `DOMDoActionActor`; `target == None` → `DOMAllOrderSlaves` / `DOMAllOrderSlavesAndSlavers` when `flag` says so |
| `TM_DoFollow` / `TM_DoStand` / `TM_DoWait` / `TM_DoBag` / `TM_DoInventory` / `TM_DoUntie` | Named leaves (no string trampoline) |
| `TM_DoFlatter` / `TM_DoInsult` / `TM_DoEntertain` | Typed leaves |
| `TM_DoRestrain(speaker, target, kind, flag)` | `DOMTiedUpByIndex` / `DOMDoUntie` / group `TieUp` |
| Sex / punish / dress | Existing `SkyrimNet_DOM_Actions` |

`RegisterObeyCommand` where YAML already narrates.

SexLab natives used: `WebUI_PushMainPanelData`, `WebUI_GetFocusActor`, `WebUI_GetFocusKind`.

---

## Payload envelopes (SexLab host)

Do not mix table and detail in one object.

`data_table`:

```json
{ "panel": "data_table", "id": "slaves", "columns": [], "rows": [], "truncated": false }
```

`actor_detail`:

```json
{ "panel": "actor_detail", "id": "status", "fields": [], "controls": [] }
```

Row: `{ "formId": 123, "cells": ["Name", ...] }`. Field: `{ "id", "label", "value" }`. Control: `{ "id", "label", "widget": "toggle"|"select"|"button", "value", "options": [] }`.

---

## Direct hotkeys (map onto TargetMenu / Status; do not call wheels)

| Hotkey default | Maps to |
|----------------|---------|
| Inventory (O) | order → inventory |
| Praise / scold | abuse |
| Bag in/out | order bag |
| Abduction (H) | v2 services |
| Follow / follow-all | order |
| Diary | out of v1 UI (native `DOMOpenDiary`) |
| Status / mood / traits / feels | Status panel display |
| Fixme (K) | out of v1 |

Out of v1 UI: sack menu, `moveKey` bone tooling, debug test-pose, diary as a panel.

---

## Do not

- Edit Diary of Mine / PAH sources
- Add a DOM SKSE DLL or second PrismaUI `CreateView`
- YAML parser for ControlPanel
- Duplicate SexLab DD bondage / leash / outfit StorageUtil
- Claim VR parity
- Commit unless asked
