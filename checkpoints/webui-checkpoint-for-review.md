# WebUI checkpoint — review then execute

**Status:** design locked, **not implemented**. No `webui/` tree in SkyrimNet_DOM. SexLab overlay has no ControlPanel modes, no target sentinels, no foreign table/detail hosts.

**Purpose:** cold-start a **new model**. First **review** this checkpoint against sources (do not trust the inventory blindly). Then **execute** in the order below. Do not rediscover the architecture unless a locked decision is wrong.

**Companion plan:** `c:\Users\bhuff\.cursor\plans\dom_webui_interface_529aeaa6.plan.md` (same decisions; this file is the handoff).

**Date:** 2026-09-15.

---

## How to use this file

1. Read **Locked decisions**, **Hard rules**, **Repos**.
2. **Review pass:** verify DOM_Keys leaves vs menu-openers; SexLab catalog loader; Papyrus 8-arg / pause quirks. File findings as questions, do not silently reverse locked UX.
3. **Execute** phase 0 → 5. SexLab SKSE/JS first (DOM catalogs cannot paint without hosts).
4. After implementation: append quirks to each repo `KNOWLEDGEBASE.md`; update docs listed at the end.

Do **not** commit unless the user asks.

---

## Locked decisions (user)

| ID | Decision |
|----|----------|
| D1 | **Host = SexLab PrismaUI overlay.** No DOM SKSE DLL, no second `CreateView`. Same ControlPanel stays upper-left. |
| D2 | ControlPanel **title becomes a mode pulldown**. Built-in `SkyrimNet SexLab`. Third parties drop JSON under SexLab `webui/ControlPanel/`. DOM label **`SkyrimNet DOM`**. Switching mode **closes** the previous TargetMenu + main-panel set and **loads** that mode’s `catalogRoot`. |
| D3 | Config files are **JSON** (SexLab ActionCatalog is JSON-only). User originally said YAML; do not add yaml-cpp unless a later review insists. |
| D4 | **Unified TargetMenu** in DOM mode (one left-column row set, eligibility omits). **Not** five different root wheels (slave/trainer/slaver/NPC/group). |
| D5 | **Status is a main panel**, not a TargetMenu row. Full slave **stats + configuration** (old Status-wheel toggles live here). |
| D6 | Main panel **Slaves**: table of **all owned slaves** (DOM02 aliases, not nearby-only). Columns: Name, Trainer, Standing order, duty, respectful, silent, fight, orgasm, restrained/jailed, next punishment. Row click → set target. |
| D7 | ControlPanel **target pulldown** gains **All Slaves** (sentinel, no FormID). Selects group `DOMAll*` TargetMenu + opens Slaves roster. **No** left-column Group row. **No** “player focus means group”. |
| D8 | In DOM mode, SexLab TargetMenu (sex/punish/outfit/DD bondage/leash) and SexLab views (Scene Menu / Animation / OStim framework) **are not shown**. Training may include sex/rape/masturbate because those SexLab rows are gone. |
| D9 | Do **not** edit Diary of Mine / PAH sources. Call leaf `DOM_Keys` / `DOM_Actor` / `DOMInteract` / existing `SkyrimNet_DOM_Actions`. |

---

## Goal (player-visible)

Player opens the existing SexLab WebUI hotkey (`\`). ControlPanel mode **SkyrimNet DOM**. Target pulldown: nearby actors + **All Slaves**. Left: DOM command pulldowns. Right: **Status** (one actor) or **Slaves** (roster). Commands go to DOM packages, not UIExtensions wheels.

---

## Repos and roots

| Repo | Root | Role |
|------|------|------|
| SkyrimNet_DOM | `c:\Skyrim\dev\mods\SkyrimNet_DOM` | Manifest, catalogs, Papyrus `TM_*`, ControlPanel registration payload, player/dev docs |
| SkyrimNet_SexLab | `c:\Skyrim\dev\mods\SkyrimNet_SexLab` | Overlay host: C++/JS/natives, ControlPanel loader, generic `data_table` / `actor_detail`, **developer docs** |
| Diary of Mine (read-only) | `c:\Skyrim\dev\mods\PAH Diary Of Mine` | Wheel/hotkey source of truth. **Do not modify.** |

Quest FormIDs (local `0x800`): `SkyrimNet_DOM.esp`, `SkyrimNet_SexLab.esp`. DOM_Keys quest EditorID `DOM02Topic`.

---

## Hard rules

From DOM `AGENTS.md` / `docs/developers/papyrus.md`:

- Confidence ≥ 90% preferred; document gaps if lower. **Never assume SE = VR.**
- Papyrus compile: Cursor task **`compile: pyro`** / `skyrimse.ppj` only.
- Consult `KNOWLEDGEBASE.md` before script/game changes; append quirks after.
- Do not write ESP/ESM/BSA directly.
- Caprica: natives cannot use a parameter named `scriptName`.
- SkyrimNet YAML/WebUI `parameterMapping`: **hard max 8 args**.
- PrismaUI `Focus(..., pause=true)`: paused overlay blocks SexLab `StartThread` and SkyrimNet decorator VM calls. **Close overlay before scene/package work** (`closeWebUI: true` on TargetMenu execute). Status/Slaves stay open.
- `eligibilityRules` are evaluated in **C++ at catalog build**, not in a paused Papyrus decorator call — reuse existing faction decorators (`get_faction_rank`, `is_in_faction`, `is_in_combat`).
- Do not call any `DOM_Keys` function that `OpenMenu()` / `UIWheelMenu` / `Message.Show` (the `DOMDo*Menu` / `ShowCall*` / `ShowDOM*` family). Call **leaves** (`DOMDoFollowMe`, `DOMDoActionActor`, `DOMAllOrderSlaves`, …).

SexLab WebUI contract: `c:\Skyrim\dev\mods\SkyrimNet_SexLab\docs\developers\webui.md` (today: “Foreign main panels … DOM wiring is deferred” — that sentence is what we replace).

---

## Architecture (locked)

```
SexLab hotkey
  → PrismaUI SkyrimNet_SexLab/index.html (paused)
  → ControlPanel
       mode pulldown: SkyrimNet SexLab | SkyrimNet DOM | (future JSON)
       views pulldown: per-mode MainPanels (+ None)
       target pulldown: nearby actors [+ All Slaves in DOM mode]
  → TargetMenu left column: per-mode Actor options (or Scene if SexLab + animating)
  → Main panel right: per-mode
       DOM: Status (actor_detail) | Slaves (data_table)
  → JS onAction papyrus → C++ ExecutePapyrusOption → SkyrimNet_DOM_Menu TM_*
  → DOM_Keys / SkyrimNet_DOM_Actions leaves
```

Filesystem:

- SexLab loads `Data/SKSE/Plugins/SkyrimNet_SexLab/webui/ControlPanel/*.json` (mode registry).
- Built-in SexLab mode uses today’s `webui/TargetMenu` + `webui/MainPanels`.
- DOM mode `catalogRoot`: `SKSE/Plugins/SkyrimNet_DOM/webui` (under Data).
- DOM FOMOD/install **copies** `0200_skyrimnet_dom.json` into SexLab `webui/ControlPanel/` (same third-party pattern as bondage JSON). Prefer authoring that file in the DOM repo and documenting the install path.

---

## Review: source files to read

### Diary of Mine (inventory; do not edit)

| File | Why |
|------|-----|
| `PAH Diary Of Mine/Scripts/Source/DOM_Keys.psc` | All wheels + hotkeys. Router `DOMDoCallMenu` ~772. Slave top `ShowCallSlaveMenu` ~801. Group `ShowCallGroupMenu` ~1023. Leaves vs `*Menu` openers. `DOMAllOrderSlaves` ~9176. Hotkey defaults ~246–287. |
| `DOM_MCM.psc` | Wheel/hotkey MCM (`$Wheel menu`, `$Hotkeys`) |
| `DOM_PAH.psc` | PAH order fork |
| `DOMInteractionPerk.psc` | Activate: bag, abduct, tie/untie, wake |
| `DOMMagicAbuseMenu.psc` | Spell → `DOMDoCallMenu` |
| `pahcore.psc` | Legacy capture/whistle (out of v1) |
| `DOM_Actor.psc` | `behaviour`, `is_trainer`, `actor_trainer`, `DoOrder` |
| `DOM_Interactor.psc` | Tie/untie execution |

**Menu vs leaf (review must confirm before wiring):**

| Safe to call from WebUI | Do **not** call (opens UIExtensions) |
|-------------------------|--------------------------------------|
| `DOMDoFollowMe`, `DOMDoStandStill`, `DOMDoWaitSandbox`, `DOMDoFavor` | `DOMDoCallMenu`, `DOMDoOrderMenu`, `ShowCall*` |
| `DOMDoOpenInventory`, `DOMDoPutInBag`, `DOMDoUntie` | `DOMDoTieUpMenu`, `ShowDOMOrderMenu` |
| `DOMDoFlatter(actor, type)`, `DOMDoInsult(actor, type)` | `DOMDoFlatterMenu`, `DOMDoInsultMenu` |
| `DOMDoPraise`, `DOMDoScold`, `DOMDoActionActor` | `DOMDoAbuseMenu`, `DOMDoPraisingMenu` |
| `DOMDoBeRespectful`, `DOMDoBeSilent`, `DOMDoFightForMe` | `DOMDoStatusMenu` |
| `DOMDoSetOrgasmStatus`, `DOMDoEntertain(actor, type)` | `DOMDoTrainingMenu`, `DOMDoPoseMenu` |
| `DOMDoCleanTheMess`, `DOMDoWork(actor, type)`, `DOMDoJail` | Task submenu openers |
| `DOMDoStatus`, `DOMDOMood` (read-only strings for Status panel) | `DOMWheelTraits` as a blocking wheel |
| `DOMAllOrderSlaves(order, …)`, `DOMAllOrderSlavesAndSlavers` | `DOMAllOrderMenu`, `DOMDoCallGroupMenu` |

Order event strings used by group/hotkey backends (non-exhaustive): `Follow`, `FollowIfPosing`, `Kneel`, `Attention`, `StandStill`, `WaitHere`, `Scold`, `Praise`, `Insult`, `Flatter`, `BeNaked`, `Strip`, `StripAll`, `Masturbate`, `NoOrgasm`, `FreeOrgasm`, `BeRespectful`, `BeSilent`, `FightForMe`, `DontFightForMe`, `Work`, `GoToJail`, `InBag`, `OutBag`, `GatherBag`, `Display`, `Salute`, `Shower`, `LookAtMe`, `TurnAround`, `ComeHere`, `DrinkThis`, `MarkMe`, `BrandMe`.

`DOMDoCallMenu` routing: slaver faction → slaver wheel; PAH/DOM slave rank 2 → trainer; else slave; else NPC. No target → sack or group (`groupIsDefaultMenu`). WebUI replaces this with **eligibility + All Slaves sentinel**.

### SkyrimNet_SexLab (must change)

| File | Why |
|------|-----|
| `docs/developers/webui.md` | Contract. Add **ControlPanel modes**, **Target sentinels**, **Foreign main panels**. Remove “DOM wiring is deferred”. |
| `llms.txt`, `AGENTS.md` | Doc map still points at `webui.md` — keep, ensure new headings are findable. |
| `KNOWLEDGEBASE.md` | Pause, mode swap, sentinel, table payload. |
| `SKSE_Source/src/ActionCatalog.cpp` | `Load()` / `LoadOptionFiles` / `BuildMainPanelsCatalog` / `SwitchMainPanel` — today **one** webui dir. |
| `SKSE_Source/src/WebUI.cpp` | JS listeners (`onAction`, `onMainPanelChange`). Add `onControlModeChange`, `onMainPanelRow`. |
| `SKSE_Source/src/Papyrus_WebUI.cpp` | Nearby actors; `Target_Current` is `RE::Actor*`. Sentinel needs a non-actor focus. |
| `Scripts/Source/SkyrimNet_SexLab_WebUI.psc` | Add `WebUI_PushMainPanelData(String json)` (name flexible). Existing: `Target_Menu_Open`, `WebUI_CloseOverlay`, `SetNearbyActorsJson`. |
| `PrismaUI/views/SkyrimNet_SexLab/index.html` | `.control-panel-title` hardcoded. `#control-actor-pulldown`. Pulldown `type` already nests `papyrus` children (~5171). No `data_table` / `actor_detail` DOM. |
| `webui/TargetMenu/Actor/options/0400_sex.json` | Shape for `type: papyrus` + `eligibilityRules`. |
| `webui/MainPanels/*.json` | `builtin` vs `papyrus` (zero-arg open/close only — does not paint). |

JS already supports TargetMenu `type: pulldown` with child `type: papyrus` — first production use will be DOM.

### SkyrimNet_DOM (must change)

| File | Why |
|------|-----|
| `Scripts/Source/SkyrimNet_DOM_Menu.psc` | Stub. Revive as TM dispatcher on quest `0x800`. Trace helper currently mislabels `SkyrimNet_DOM_Event`. |
| `Scripts/Source/SkyrimNet_DOM_Actions.psc` | Existing sex/punish/dress/masturbate executes. |
| `Scripts/Source/SkyrimNet_DOM_Decorators.psc` | `FillSlaveFields` / `Get_Actor_Info` — Status + Slaves JSON. Reuse; do not invent parallel keys. |
| `Scripts/Source/SkyrimNet_DOM_API.psc` | `GetThreads` alias walk: `GetMaxActorCount()` + `actorAliases` (not `GetActorCount` — lags). |
| `docs/reference/json-keys.md` | Canonical lowercase keys for the Status/Slaves payloads. |
| `SKSE/Plugins/SkyrimNet_DOM/slave_behaviours.json` | Standing-order display strings. |
| `SKSE/Plugins/SkyrimNet/external/goodprovider.dom/actions/*.yaml` | LLM twins; WebUI does not require YAML for `type: papyrus`. |
| `docs/authors/actions.md` | Two executors: `DOM_Keys` vs `SkyrimNet_DOM_Actions`. |

`manifest/` does **not** exist. SexLab `manifest/Scripts/Source/*.psc.md` are old script-review XML — **do not copy that format**. `manifest/DOM.md` is the **interaction contract** for this WebUI.

---

## DOM TargetMenu (v1 vs v2)

**v1 left column** (one JSON file each, numeric prefix, `type: pulldown`):

| File (suggested) | Label | Scope |
|------------------|-------|--------|
| `1100_order.json` | order | Single slave + All Slaves group leaves |
| `1110_abuse.json` | abuse | Same (slaver historically “Speech”) |
| `1120_training.json` | training | Includes sex/rape/masturbate via existing Actions (slaver “Physical”) |
| `1130_restrain.json` | restrain | DOM furniture, not DD |
| `1140_clothes.json` | clothes | DOM naked/rip/weapons, not SexLab outfit |

**Not TargetMenu:** status (D5), group (D7).

**v2:** `management`, `trainees`, `services`; sack; richer punish-reason / furniture-variant choosers.

**High-traffic v1 leaves:** follow / stand / wait; praise / insult / flatter / promise / scold; kneel / display; strip / be-naked; bag; inventory; Status toggles on the detail panel (respectful, silent, fight, orgasm, task).

`closeWebUI`: **true** on TargetMenu execute; **false** on Status/Slaves.

---

## Main panels (DOM `catalogRoot`)

### Status — `actor_detail`

Focused actor. Empty/wrong bucket must not happen: slave / trainer / slaver / NPC use the matching `json-keys.md` bucket.

**Read-only:** name, title, owner, trainer (`is_trainer` + `actor_trainer` name), standing order (`behaviour` → `slave_behaviours.json`), mood, obedient, `training_mind` / `training_sex`, punishment next/current, restrained / bound / jailed, `orders.*`, arousal triad, gear flags, promise, love/loyal. Personality/feelings/status text via `DOMDoStatus` / `DOMDOMood` / core message helpers as display, not extra wheels.

**Config (old Status wheel):** respectful, silent, fight for me, orgasm allow/deny, task (maid / `DOMDoWork` types / jail). Papyrus: `DOMDoBeRespectful`, `DOMDoBeSilent`, `DOMDoFightForMe`, `DOMDoSetOrgasmStatus`, `DOMDoCleanTheMess`, `DOMDoWork`, `DOMDoJail`.

All Slaves selected: prefer **Slaves** roster as primary view; Status may show a count summary — do not keep a stale single-slave editor as if it were the group.

### Slaves — `data_table`

All owned slaves (`DOM02` `actorAliases` / `GetMaxActorCount()`). Not nearby-only. Click row → `onMainPanelRow` → set target FormID (allowed even if far) → refresh Status.

v1 columns: Name, Trainer, Standing order, Duty/task, Respectful, Silent, Fight, Orgasm, Restrained/jailed, Next punishment.

Cap or paginate if JSON stalls PrismaUI.

---

## ControlPanel registration (DOM → SexLab folder)

Install to `Data/SKSE/Plugins/SkyrimNet_SexLab/webui/ControlPanel/0200_skyrimnet_dom.json`:

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
  "closeFunction": "TM_ModeClosed"
}
```

Built-in SexLab mode: `id` `sexlab`, `label` `SkyrimNet SexLab`, implicit catalog = SexLab `webui/` (optional `0000_sexlab.json` for symmetry).

Mode JSON may later declare **target sentinels** (DOM: `{ "id": "all_slaves", "label": "All Slaves" }`). If not in the registry file, hardcode the sentinel when mode id is `skyrimnet_dom` — prefer schema-driven so future mods can add sentinels.

---

## SexLab implementation notes (for the executing model)

1. **Per-mode catalogs** in `ActionCatalog`: SexLab actor/scene/mainPanels stay; additional modes load `catalogRoot/TargetMenu/Actor` + `catalogRoot/MainPanels`. Scene catalog remains SexLab-only (animating + SexLab mode).
2. **`onControlModeChange`:** `SwitchMainPanel("")` → previous `closeFunction` → select mode → `configureControlPanel` + `configureTargetMenu` → `openFunction`. Keep actor focus unless the new mode requires a sentinel.
3. **Remember last mode** across overlay hide if cheap; default SexLab on first open of a session is OK.
4. **Title pulldown** replaces `.control-panel-title` text; same pulldown widget as views/target.
5. **DOM mode chrome:** hide `#framework-row`; views = DOM MainPanels only (Status, Slaves) + None. Do not show Scene Menu / Animation.
6. **All Slaves:** inject into actor pulldown (after player). `onControlActorChange` must not require `RE::Actor*`. Internally `Target_Current` null + `focusKind = all_slaves` (name flexible). Rebuild TargetMenu with group eligibility.
7. **Foreign hosts** in `index.html` main-panel host:
   - `data_table` — columns from MainPanel JSON; rows from `WebUI_PushMainPanelData`
   - `actor_detail` — stats + control widgets from JSON
8. Today `type: papyrus` MainPanel only calls zero-arg open/close — **does not render**. Open function must push JSON after native exists.
9. Row click: `onMainPanelRow` → set target → optional switch views to Status.
10. **CMake** rebuild SKSE; copy DLL to `SKSE/Plugins/`. Overlay HTML is `PrismaUI/views/` not under SKSE.

Suggested native (Papyrus_WebUI + `.psc`):

```papyrus
Function WebUI_PushMainPanelData(String json) global native
```

Payload shape (review may tweak; keep one envelope):

```json
{ "panel": "data_table"|"actor_detail", "columns": [], "rows": [], "fields": [], "controls": [] }
```

---

## DOM Papyrus (`SkyrimNet_DOM_Menu`)

On quest `SkyrimNet_DOM` (`0x800`). Fix Trace tag to `SkyrimNet_DOM_Menu`.

| Function | Role |
|----------|------|
| `TM_ModeOpened` / `TM_ModeClosed` | Zero-arg |
| `TM_StatusPanelOpen` / close | Build detail JSON from Decorators; `WebUI_PushMainPanelData` |
| `TM_SlavesPanelOpen` / close | Walk aliases; table JSON |
| `TM_StatusApply` (or per-control) | respectful / silent / fight / orgasm / task |
| `TM_DoOrder(speaker, target, eventName, type, flag)` | `DOMDoActionActor`; `target == None` → `DOMAllOrderSlaves` |
| `TM_DoNamed(speaker, target, fn, type)` | Named leaves (flatter/insult/entertain/follow/bag/inventory) |
| Sex/punish/dress | Call existing `SkyrimNet_DOM_Actions` |

`RegisterObeyCommand` where YAML already narrates.

Do not add UIExtensions imports.

---

## Execution order

### Phase 0 — `manifest/DOM.md`

Write `c:\Skyrim\dev\mods\SkyrimNet_DOM\manifest\DOM.md` **before** JSON/Papyrus. It is the contract: TargetMenu rows, Status/Slaves fields, All Slaves, leaf function names, YAML twins, hotkey map, v1 vs v2, `closeWebUI` rules. Review this file against `DOM_Keys.psc` before coding catalogs.

### Phase 1 — SexLab host

ControlPanel loader, mode pulldown, catalog swap, All Slaves sentinel, `data_table` / `actor_detail`, `WebUI_PushMainPanelData`. Compile SKSE. Smoke: SexLab mode still works (sex/punish/Scene Menu).

**Docs in the same change:** `docs/developers/webui.md` new sections (ControlPanel modes, target sentinels, foreign main panels). `llms.txt` / `AGENTS.md` if a split file is needed (prefer headings in `webui.md`). `KNOWLEDGEBASE.md` quirks.

### Phase 2 — DOM catalogs

`SKSE/Plugins/SkyrimNet_DOM/webui/TargetMenu/Actor/defaults.json` + `options/*.json`. `MainPanels/0100_status.json`, `0200_slaves.json`. ControlPanel `0200_skyrimnet_dom.json` (DOM-owned, installed into SexLab dir).

### Phase 3 — DOM Papyrus

Revive Menu; pyro compile. Wire leaves only.

### Phase 4 — DOM docs

`llms.txt` WebUI row. `docs/players/overview.md` (hotkey → mode → Status/Slaves/All Slaves). `docs/developers/papyrus.md` (Menu not a stub). `KNOWLEDGEBASE.md` if anything paused/alias-walk related.

### Phase 5 — in-game check (when the user can run the game)

- SexLab mode unchanged.
- Switch to SkyrimNet DOM: title, views, no OStim row, no Scene Menu.
- Target a slave: Status fills; Order follow works; overlay unpauses/hides on execute.
- All Slaves: roster; group follow/kneel.
- Click roster row: target + Status.
- Missing `SkyrimNet_DOM.esp`: mode omitted (`requiresPlugin`).

---

## Confidence (planning)

| Area | % | Gap |
|------|---|-----|
| Leaf `DOMDo*` + Actions + decorator fields for v1 | 85 | Confirm every v1 JSON leaf is not a `*Menu` opener |
| ControlPanel mode swap + `catalogRoot` | 70 | ActionCatalog assumes one dir |
| All Slaves without `RE::Actor*` | 70 | Nearby pipeline is actor-only |
| Foreign `data_table` / `actor_detail` | 70 | papyrus MainPanels do not paint today |
| Pause vs packages | 80 | Known SexLab StartThread issue; close on execute |

Reviewer should bump these after reading current `ActionCatalog.cpp` / `Papyrus_WebUI.cpp` nearby code.

---

## Out of scope (v1)

- Editing PAH / UIExtensions wheels
- DOM SKSE DLL / second PrismaUI view
- YAML parser for ControlPanel
- Sack menu, `moveKey` bone tooling, debug test-pose, diary as a panel
- Trainer management / trainees / NPC services (v2)
- Duplicating SexLab DD bondage / leash / outfit StorageUtil
- VR parity claims
- Commits / FOMOD zip unless asked

---

## Review questions (answer before coding if still ambiguous)

1. **JSON vs YAML** for ControlPanel — locked JSON; reopen only if SexLab maintainers require YAML.
2. **All Slaves vs player** in the pulldown — keep player as a normal actor; All Slaves is a separate sentinel (do not overload player = group).
3. **Log/Settings in DOM mode** — plan default: hide SexLab-only builtins. Including Log is optional; Status/Slaves are required views.
4. **Where `0200_skyrimnet_dom.json` lives in git** — DOM repo (`SKSE/Plugins/SkyrimNet_DOM/webui/ControlPanel/` or `fomod-source`) copied into SexLab’s ControlPanel on install. Do not make SexLab the only copy of DOM’s label.

If review finds a locked UX decision unworkable (e.g. sentinel cannot work without an actor), stop and ask the user; do not silently use “player = group”.

---

## Agent policy reminder

- DOM: `AGENTS.md`, `llms.txt`, `KNOWLEDGEBASE.md`, `docs/reference/papyrus-rules.md`.
- SexLab: sibling `AGENTS.md`, `docs/developers/webui.md`, `KNOWLEDGEBASE.md`.
- Compile DOM Papyrus with **`compile: pyro`**. Compile SexLab SKSE with CMake tasks in SexLab `.vscode`.
- Direct writes to ESP/BSA blocked. Game-dir edits need care.
- Commit only on explicit user request; message format in `AGENTS.md`.
