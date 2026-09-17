# DOM WebUI interaction contract

Source of truth for DOM rows and panels in the SexLab overlay. Catalog JSON and `SkyrimNet_DOM_Menu` `TM_*` must match this file. Diary of Mine sources are read-only.

Player path: SexLab overlay hotkey (`\`) → target pulldown (nearby + **All Slaves**) → left TargetMenu (SexLab rows plus eligible DOM pulldowns) → views **Status** or **Slaves** (alongside Scene Menu / Animation / Log / Settings).

Do **not** call any `DOM_Keys` function that `OpenMenu()` / `UIWheelMenu` / `Message.Show` (`DOMDo*Menu`, `ShowCall*`, `ShowDOM*`, `DOMAll*Menu`, `DOMWheelTraits` as a blocking wheel). Call leaves only.

---

## Input model

| Control | Role |
|---------|------|
| Views pulldown | SexLab MainPanels plus DOM **Status** / **Slaves** when `SkyrimNet_DOM.esp` is loaded. **None** clears the right host. Non-`sexlab` `source` shows as a leading superscript on the view label (`DOM` Status). |
| Target pulldown | Nearby actors as SexLab today, plus sentinel **All Slaves** (`id: all_slaves`, no FormID) from the Slaves MainPanel JSON. Player stays a normal actor. Do **not** treat player focus as group. |
| Crosshair | Still seeds the default actor on overlay open. All Slaves is an explicit pick. |

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
| Live punish/praise list openers | `false` | `TM_ListPunishReasons` / `TM_ListPraiseReasons` / `TM_ListPraiseTypes` keep overlay open |
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
| management | slaver **or** slave rank `== 2` (trainer) | NPC / All Slaves / rank-1 slave |
| trainees | slaver **or** slave rank `== 2` | NPC / All Slaves / rank-1 slave |
| services | NPC (not slave, not slaver) | slave / slaver / All Slaves |
| sack | any overlay focus (crosshair `DOM_BurlapSack`) | — |

Fleeing actors: wheels no-op (`DOMCore.IsFleeing`). Omit via combat/flee when a C++ condition exists; Papyrus leaves still return early.

---

## TargetMenu (unified left column)

One JSON file each under `SKSE/Plugins/SkyrimNet_SexLab/webui/TargetMenu/Actor/options/` (this repo overlays into SexLab’s Data path). Each root has `"source": "dom"` and `"requiresPlugin": "SkyrimNet_DOM.esp"`. Non-`sexlab` sources render as a 50% badge in the upper left above the option. **Status is not a row. Group is not a row.**

Speaker is always the player. Target is `currentActor`, or `None` for All Slaves.

Child wheels are nested TargetMenu nodes `{ "type": "pulldown", "layout": "buttons" }` (SexLab ParameterPanel). Live lists use `WebUI_PushCascadeChoices` (not catalog JSON). Actor pickers use `"optionsFrom": "nearby_actors"`. Every `TM_*` leaf calls `OrderNarration` (`{player} orders {name|the slaves} to {action}.`) plus `RegisterObeyCommand` when there is a target. Skip extra order DN on `panel: scene_start` **Start** (SexLab narrates the scene). Ext2 event DNs may still fire. **DOM leash is not in this overlay** — SkyrimNet_Leashed owns leash UI. All bondage lives under **restrain**. Do not call `DOMDo*Menu` / `ShowDOM*` / `OpenMenu()`.

### `0800_dom_order.json` — order

| Label | Who | Leaf | close |
|-------|-----|------|-------|
| Inventory | single slave / slaver | `DOMDoOpenInventory` | true |
| Follow | single slave / slaver, not on duty | SexLab `panel: fields` (distance 0–5 + walk walking/crawling) → `TM_DoFollowApply` **Start**. Crawling narrates **follow on four**. | true on Start |
| Follow all | All Slaves | `DOMAllOrderSlavesAndSlavers("Follow")` | true |
| Walking | single slave / slaver, not on duty | SexLab `panel: fields` type pulldown (`applyOnChange`): walking / follow on four / follow on hands and knees → `TM_DoWalkingApply` (does **not** start follow) | true on pick |
| Stand all | All Slaves | `DOMAllOrderSlavesAndSlavers("StandStill")` | true |
| Wait | single slave / slaver, not on duty | `DOMDoWaitSandbox` (immediate button) | true |
| Wait all | All Slaves | `DOMAllOrderSlavesAndSlavers("WaitHere")` | true |
| Favor | single slave / slaver | `DOMDoFavor` | true |
| Put in bag | single slave | `DOMDoPutInBag` | true |
| All in bag / Open bags / Gather bags | All Slaves | `InBag` / `OutBag` / `GatherBag` | true |
| Pose | single slave | One list: Chair, Light, Flowers, Drinks, Cute, Dance, Music, Submissive, Ass, Breasts, Pussy | true |
| Pose all | All Slaves | `DOMAllOrderSlaves("Display")` | true |

No Follow/Walking/Wait leash panels. No Order untie (restrain owns bondage). Follow **Start** starts follow if needed then applies distance + walk. Walking type pick applies gait immediately (does not `EnterFollowPlayer`). Wait is a single leaf. Nested `panel: fields` keeps the order pulldown (`keepNav`). Never `DOMDoFollowMe` when `behaviour == "follow_player"`. Never `DOMDoFollowMenu`.

### `0810_dom_abuse.json` — abuse

| Label | Who | Leaf | close |
|-------|-----|------|-------|
| Praise | single slave / slaver | `TM_ListPraiseReasons` → live types → `StartPraising` | false then true |
| Praise all | All Slaves | `DOMAllOrderSlavesAndSlavers("Praise")` | true |
| Scold | single (+ NPC) | typed `TM_DoNamed` | true |
| Insult / Flatter / Threaten / Comfort / Promise | single (+ NPC insult/flatter/hug) | `TransformDialogue` then DOM leaf; **no** order DN | true |
| * all | All Slaves | `DOMAllOrderSlaves` (order DN) | true |
| Upkeeping | slave / slaver / NPC | bath / look / turn / come / **Follow actor** (`nearby_actors`) / drink / mark / brand | true |
| Punish | single slave | `TM_PunishPanelOpen` → `panel: fields` (Start + live reason + live method) → `StartPunishing` | false then true on Start |
| NPC extras | NPC | shower / bath me / bath you / hug / feed / walk on 4 | true |

Punish reasons walk the same crying / angry / posture / `"being a bad slave"` fallbacks as `ShowDOMPunishmentMenu`. Punish methods come from `GetJSONNumberOfPunishmentTypes` / `GetJSONPunishmentTypeNameByIndex`. Praise types come from `GetJSONNumberOfPraisingTypes` / `GetJSONPraisingTypeNameByIndex`.

### `0820_dom_training.json` — training

| Label | Who | Leaf | close |
|-------|-----|------|-------|
| Attention | single slave | stand / display / salute / kneel | true |
| Attention all / Kneel all | All Slaves | `Attention` / `Kneel` | true |
| Inspect | single slave | Front / Back / Floor / display | true |
| Kiss | slave / slaver | Short / Love / Long / Forced / Dominant / Side / Vampire | true |
| Masturbate (idle) | slave, not `DOMActionMasturbating`, not on duty | Standing / Kneeling / Laying → `StartScene_masturbate` | true |
| Masturbate (active) | `DOMActionMasturbating` | Stop / Harder | true |
| Masturbate all | All Slaves | `Masturbate` | true |
| Sex | slave / slaver | SexLab `panel: scene_start` clone of `0400_sex.json` (`StartScene_Consensual_Two`) | true on Start |
| Rape | single slave | SexLab `panel: scene_start` clone of `0420_rapes.json` (`StartScene_Nonconsensual_Two_TargetVictim`, `objectRelation: "to victim"`, `settingName: "punish_pleasure_pain_rape"`) | true on Start |

Do **not** nest Clothes here. Orgasm allow/deny lives on **Status**. Nested `scene_start` keeps parent pulldown (`keepNav`).

### `0830_dom_restrain.json` — restrain (DOM furniture, not DD)

| Label | Who | Leaf | close |
|-------|-----|------|-------|
| Tie | single slave | rope poses 0–6 + random (`DOMTiedUpByIndex`) | true |
| Untie | single | `DOMDoUntie` | true |
| Tie all | All Slaves | `DOMAllOrderSlaves("TieUp")` | true |
| Chains / post / cage / cross / pillory / wheel | single slave | `TM_ListRestrainVariants` labels from `SKSE/Plugins/SkyrimNet_DOM/restrains/{kind}.json` (default `variant #`) + random → `*ByIndex` | false then true |
| Gag / plug | single slave | cloth / ball / ring / log; vaginal / anal plug | true |
| Blindfold | single slave | leather–db (`GetBlindfold` 1–6) / remove / random | true |
| Cuffing | single slave | `TM_DoRestrain` `cuff` 0–5 / `uncuff` (does **not** start follow) | true |

Do not call `DOMDoTieUpMenu` / `ShowDOM*`. Do not use SexLab `panel: bondage`.

### `0840_dom_clothes.json` — clothes (DOM state, not SexLab outfit)

| Label | Who | Leaf | close |
|-------|-----|------|-------|
| Rip-off / rip-off everything | single slave | `DOMDoRipOff` / `Interact_UndressAll` | true |
| Strip / strip all (actor) / be naked / dress | single slave | `DOMDoStrip` / `DOMDoStripAll` / `DOMDoBeNaked` / `Dress_Execute` | true |
| Re-equip / weapons / armor | single slave | `SendOrderEquipInventory` / `HoldNoWeapons` / `HoldWeapons` / `WearNoArmor` / `WearArmor` | true |
| Group | All Slaves | `BeNaked` / `DontBeNaked` / `Strip` / `StripAll` / `EquipInventoryForced` / `StripWeapons` / `StripArmor` | true |

### `0850_dom_management.json` / `0860_dom_trainees.json`

Trainer hub (slaver **or** slave rank `== 2`). Management: list / set camp / travel / guard / gather / **Add trainee** / **Unload trainee** (`nearby_actors`) / unload all. Trainees: display / tie / chain / restrain / masturbate / punish / rape / orgy. `TM_DoTrainer`.

### `0870_dom_services.json`

NPC only: rape slave / sex with / player 3some (`panel: scene_start`) / re-equip / equip no clothes.

### `0880_dom_sack.json`

Open / Open and tie / Take **or** put in bag, from `TM_ListSackOptions` based on focused slave `wait_in_bag` / `the_bag_iam_in` (crosshair sack `GetVictim()` as fallback). `TM_DoSack` uses `ResolveSack`.

---

## Main panels

Install under `SKSE/Plugins/SkyrimNet_SexLab/webui/MainPanels/` (this repo overlays into SexLab’s Data path). `"source": "dom"` and `"requiresPlugin": "SkyrimNet_DOM.esp"` on each file.

### Status — `0300_dom_status.json` (`actor_detail`)

Focused actor. Empty/wrong bucket must not happen: slave / trainer / slaver / NPC use the matching [json-keys.md](../docs/reference/json-keys.md) bucket from `Get_Actor_Info` / `FillSlaveFields`.

**Read-only (v1):** name, title, owner, trainer (`is_trainer` + `GetTrainer()` display name — UI field `trainer`, not a new decorator key), standing order (`behaviour` via `slave_behaviours.json`), mood sentence, obedient, `training_mind` / `training_sex`, punishment next/current, restrained / bound / jailed, `orders.*`, arousal triad, gear flags, promise, love/loyal. Personality / feelings / long status text: display strings from `DOMDoStatus` / `DOMDOMood` / `DOMWheelTraits` / `NPCWheelFeelings` **message helpers** (`NPCStatsMessage`, `NPCMoodMessage`, `DOMTraitsMessage`, `NPCFeelingsMessage`) — never `OpenMenu()`.

**Config (old Status wheel):** respectful, silent, fight for me, orgasm allow/deny, task (maid / `DOMDoWork` types 1–6 / jail modes 1–7).

| Control | Leaf |
|---------|------|
| Respectful | `DOMDoBeRespectful` / group `BeRespectful` |
| Silent | `DOMDoBeSilent` / group `BeSilent` |
| Fight | `DOMDoFightForMe` / group `FightForMe` |
| Orgasm / No orgasm | `DOMDoSetOrgasmStatus` / group `FreeOrgasm` / `NoOrgasm` |
| Maid / sweep | `DOMDoCleanTheMess` |
| Work 1–6 | `DOMDoWork(actor, type)` / group `Work` |
| Jail 1–7 | `EnterJailTravel(mode)` (standstill / wait / tied / cuffs back / front / crossed / cuffed) |

Papyrus: `TM_StatusPanelOpen` / `TM_StatusPanelClose` / `TM_StatusApply`.

All Slaves: count summary (`owned`, `nearby`, `on_duty`, `restrained`) plus the same group Status buttons (respectful / silent / fight / orgasm / noorgasm / task). Personality/feelings stay read-only.

### Slaves — `0400_dom_slaves.json` (`data_table`)

All owned slaves via `DOM02.actorAliases` / `GetMaxActorCount()` (not `GetActorCount` / `actorArray` — those lag). Not nearby-only.

v1 columns: Name, Trainer, Standing order, Duty/task, Respectful, Silent, Fight, Orgasm, Restrained/jailed, Next punishment.

Cap at 43 rows (MCM page size). If more aliases exist, set `truncated: true`. Click row → FormID focus → Status (`rowClickMainPanel: status` on this file).

Papyrus: `TM_SlavesPanelOpen` / `TM_SlavesPanelClose`.

Sentinels and roster-click live on this JSON (not a ControlPanel mode file):

```json
"rowClickMainPanel": "status",
"sentinels": [{ "id": "all_slaves", "label": "All Slaves", "mainPanel": "slaves" }]
```

---

## Overlay install path

SexLab loads TargetMenu/MainPanels only from `Data/SKSE/Plugins/SkyrimNet_SexLab/webui/`. This repo authors DOM files there (MO2 overlay). SexLab git does not vendor them. There is no ControlPanel mode JSON and no `catalogRoot` swap.

---

## Papyrus dispatcher (`SkyrimNet_DOM_Menu` on quest `0x800`)

Trace tag: `SkyrimNet_DOM_Menu` (not `SkyrimNet_DOM_Event`).

| Function | Role |
|----------|------|
| `TM_ModeOpened` / `TM_ModeClosed` | Unused traces (ControlPanel modes removed) |
| `TM_StatusPanelOpen` / `TM_StatusPanelClose` | Build `actor_detail` JSON; `WebUI_PushMainPanelData` |
| `TM_SlavesPanelOpen` / `TM_SlavesPanelClose` | Walk aliases; `data_table` JSON |
| `TM_StatusApply(speaker, target, control, value)` | respectful / silent / fight / orgasm / task / `jail:1`–`jail:7`; All Slaves group leaves |
| `OrderNarration(speaker, target, orderDesc)` | `{player} orders {name\|the slaves} to {orderDesc}.` via `DirectNarration`; `RegisterObeyCommand` when target set |
| `SpeakAsPlayer(speaker, target, line)` | `SkyrimNetApi.TransformDialogue` then `RegisterObeyCommand`; no order DN (insult/flatter/threaten/promise/comfort) |
| `TM_DoOrder(speaker, target, eventName, type, flag)` | `DOMDoActionActor`; Promise uses `SpeakAsPlayer`; bags / slavers / slaves group flags |
| `TM_DoFollow(speaker, target, kind, type)` | Legacy one-shot: `distance` / `follow_walk4` start follow; `wait_distance` / `walk4` do not; leftover `cuff` / `uncuff` do not. Overlay cuffing uses `TM_DoRestrain`. No `leash` / `unleash` |
| `TM_DoFollowApply(speaker, target, distance, walk4)` | Follow Parameter Panel **Start** (walk 0 walking / 1 crawling) |
| `TM_DoWalkingApply(speaker, target, walkType)` | Walking type pick: `walking` / `four` / `knees` |
| `TM_DoNamed` | Poses, kiss, clothes extras, NPC shower/bath/feed, group event names; insult/flatter/threaten/comfort use `SpeakAsPlayer` |
| `TM_DoRestrain(speaker, target, kind, flag)` | tie / furniture `*ByIndex` / gag / plug / blindfold / cuff; group `DOMAllOrderSlaves` event strings |
| `TM_ListRestrainVariants(speaker, target, kind)` | Live furniture names from `restrains/{kind}.json` |
| `TM_DoMasturbate(speaker, target, kind)` | pose start / `harder` / `stop` |
| `TM_PunishPanelOpen` / `TM_ListPraiseReasons` / `TM_ListPraiseTypes` | `WebUI_PushCascadeChoices` live lists / fields |
| `TM_DoPunish(speaker, target, reason, type)` / `TM_DoPraise` | `StartPunishing` / `StartPraising` |
| `TM_DoTrainer` / `TM_ListSackOptions` / `TM_DoSack` | trainer hub / sack by slave bag state |
| Sex / rape | Training and services `panel: scene_start` on `SkyrimNet_SexLab_Actions` (no extra order DN on Start) |

SexLab natives: `WebUI_PushMainPanelData`, `WebUI_PushCascadeChoices`, `WebUI_GetFocusActor`, `WebUI_GetFocusKind`. Cascade JSON uses `JValueToJsonString` (preserve camelCase). MainPanel JSON uses `ObjectToLowerCaseKeyJson`.

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
| Abduction (H) | services |
| Follow / follow-all | order |
| Diary | out of overlay UI (native `DOMOpenDiary`) |
| Status / mood / traits / feels | Status panel display |
| Fixme (K) | out of overlay UI |

Out of overlay UI: `moveKey` bone tooling, debug test-pose, diary as a panel. Sack is `0880_dom_sack.json`.

---

## Do not

- Edit Diary of Mine / PAH sources
- Add a DOM SKSE DLL or second PrismaUI `CreateView`
- YAML parser for overlay catalogs
- Duplicate SexLab DD bondage / SexLab leash / outfit StorageUtil
- DOM leash UI (SkyrimNet_Leashed owns leash rows)
- Claim VR parity
- Commit unless asked
