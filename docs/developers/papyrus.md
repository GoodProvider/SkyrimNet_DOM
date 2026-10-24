# Developer guide (Papyrus)

How SkyrimNet_DOM bridges Diary of Mine to SkyrimNet. For YAML/prompt editing, see [../authors/actions.md](../authors/actions.md) and [../authors/prompts.md](../authors/prompts.md). Overview: [../players/overview.md](../players/overview.md).

Also: [../authors/events.md](../authors/events.md) · [../authors/punishment.md](../authors/punishment.md) · [../authors/content.md](../authors/content.md). Contracts: [../reference/papyrus-rules.md](../reference/papyrus-rules.md), [../reference/json-keys.md](../reference/json-keys.md), [../reference/protocol-tokens.md](../reference/protocol-tokens.md).

## Role

Bridge **Diary of Mine** ↔ **SkyrimNet**, with sex/punish scenes going through **SkyrimNet_SexLab**. Do **not** modify Diary of Mine scripts — call `DOM_Keys` / `DOM_API` / `DOM_Actor` only.

## Key paths

| Path | Role |
|------|------|
| `SKSE_Source/` | `SkyrimNet_DOM.dll` (DomObedience natives); CMake `--preset release` |
| `Scripts/Source/` | Edit Papyrus (`.psc`) here |
| `Scripts/` | Compiled `.pex` output |
| `Headers/` | Import headers for Caprica / project |
| `skyrimse.ppj` | Papyrus project (imports + compile) |
| `SKSE/Plugins/SkyrimNet/external/goodprovider.dom/` | Beta 25 content plugin (actions + prompts + dialogue_actions; `manifest.json`) |
| `SKSE/Plugins/SkyrimNet/config/plugins/SkyrimNet_DOM/` | Settings schema (`Plugin_SkyrimNet_DOM`, `dom.events.*`) |
| `SKSE/Plugins/SkyrimNet_SexLab/webui/` | Overlay TargetMenu Actor options (`0800_dom_*` through `0880_dom_sack.json`) + Status/Slaves MainPanels (deploys into SexLab’s webui folder) |
| `manifest/DOM.md` | WebUI interaction contract (TargetMenu leaves, panels, All Slaves) |

## Script map

| Script | Responsibility |
|--------|----------------|
| `SkyrimNet_DOM_Main` | Init / Setup; load punishment indexes + `punishment_reason.json`; register decorators; kick Actions/Events Setup; `ApplyPluginConfig` / `OnPluginConfigSaved` |
| `SkyrimNet_DOM_Events` | DOM → Direct Narration / `RegisterEvent` / short-lived events; SexLab anim start/end hooks; Ext2 gated by `dom.events.ext2`; honors `ShouldSkipEventNarration` — see [../authors/events.md](../authors/events.md) |
| `SkyrimNet_DOM_Actions` | YAML-callable executes: scenes, masturbate, dress/undress, `DOMOrder_Execute` (gated DOM_Keys wrapper), `WebUI_StartScene_*` (TargetMenu consensual gate), `AddPunishmentReason` |
| `SkyrimNet_DOM_Obedience` | Hidden: `TryOrder` / `TryOrderSexCast` / `ShouldSkipEventNarration`; rolls `DOM_Mind.WillObey(..., do_msg=false)` and emits refuse/obey DN or sex `RegisterEvent` |
| `SkyrimNet_DOM_Native` | Hidden natives implemented by `SkyrimNet_DOM.dll` (kind catalog, skip table, narration strings) |
| `SkyrimNet_DOM_API` | Shared helpers (`GetSlave`, `AddPunishmentReason`, scene wrappers, tracing) |
| `SkyrimNet_DOM_Decorators` | Registers `dom_get_actor_info` (thin / slaver / slave buckets) — [../reference/json-keys.md](../reference/json-keys.md) |
| `SkyrimNet_DOM_Menu` | SexLab overlay dispatcher on quest `0x800`: Status/Slaves JSON (`WebUI_PushMainPanelData`), live punish/praise (`WebUI_PushCascadeChoices`), Scene comfort-by-pain (`TM_ListComfortPainActions` / `TM_DoComfortByPain`), `TM_StatusApply`, `TM_DoNamed`/`TM_DoOrder`/`TM_DoFollow`/`TM_DoFollowDistance`/`TM_DoFollowApply`/`TM_DoWalkingApply`/`TM_DoRestrain`/`TM_DoMasturbate`/`TM_DoTrainer`/`TM_DoSack`. Training **sex** is DOM `WebUI_StartScene_*` (gated); **rape** is SexLab `scene_start` (ungated). Abuse **comfort sex/rape** use `WebUI_StartScene_Comfort_*` (transform + mind, no DOM `Anim_Sexlab`). Abuse **punish** is live `panel: fields` via `TM_PunishPanelOpen` (custom/`no reason`; method **rape** → `TM_PunishRapeRecord` + SexLab scene, no `Anim_Sexlab`; other methods → `TM_DoPunish`). Order **follow** is distance buttons with live label (`follow` / `follow: short`, modes 0–3). Order **walking** is `panel: fields` with `applyOnChange`. Abuse insult/flatter/threaten/promise/non-sex comfort use `TransformDialogue`. Furniture restrain variants are `TM_ListRestrainVariants` → `panel: fields`. Gated `TM_*` leaves use `GateOrder` / `TryOrder`; ungated / missing DLL fall back to `OrderNarration`. Trace tag `SkyrimNet_DOM_Menu`. Contract: [../../manifest/DOM.md](../../manifest/DOM.md). |
| `SkyrimNet_DOM_PlayerRef` | Load-game refresh |

Legacy `Register_Actions()` from `actions.json` is commented out — SkyrimNet loads YAML from `external/goodprovider.dom/actions/`.

## Punishment pipeline

Full checklist: [../authors/punishment.md](../authors/punishment.md).

1. DOM’s `PunishmentReasons.json` (StorageUtilData) → numeric indexes
2. `SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json` → LLM-facing names / aliases → those indexes
3. YAML refuse / AddPunishmentReason → `SkyrimNet_DOM_Actions.AddPunishmentReason` → `SkyrimNet_DOM_API.AddPunishmentReason` → `RegisterEvent("Reason to Punish", …)`
4. Injury Engine torture: `Injury_Engine_Torture(Form attacker, Form victim, String source, Int hits, String cause)` → `Events.OnInjuryTorture`. The first hit runs `StartPunishingByIndex(.., 0, "pain")` and `StartTortureReason`, which uses `TakePanelReason`, then `OpenPunishReasons`, then `Menu.OpenTortureReasonList` (SexLab `Choice_Open`) or a random reason, then `ApplyTortureReason`. Every hit runs `mind.HandlePunishmentOnHit`. The list's pick runs `Menu.TM_DoTortureReason(speaker, reason, slaveId)`.
5. Healing Hands: `Injury_Engine_HealStart(Form caster, Form target, Int source)` → `Events.OnInjuryHealStart` (source 1 = spell, caster has `0x04D3F2` equipped). Shocked slave (`mind.mood == "shocked"`) → `ComfortCareNoHug`. Otherwise the player with `dom.praise.heal_choose_reason` gets `Menu.OpenHealPraiseList` (SexLab `Choice_Open`, reasons from `PraiseReasonList` + custom). The pick runs `Menu.TM_DoHealPraise(speaker, slaveId, reason)`, and Close gives no praise. Everyone else: `StartPraising(caster, DefaultPraiseReason(mind), "tell")` ("being a good slave" / "being a good slaver"; also used for a blank custom).
6. SexLab Aid: `SkyrimNet_SexLab_AidStart` (sender = target, strArg `"<spell|potion>|<caster FormID signed decimal>"`, numArg = health) → `Events.OnSexLabAidStart` → the same `HealSlave` routing, any caster, no Healing Hands check. SexLab sends it once per health Aid on another actor (`Aid::Apply`, `Aid::StartChannel`).

## SexLab bridge / arousal

- YAML order/pose/chore executes call `SkyrimNet_DOM_Actions.DOMOrder_Execute` (DomObedience then `DOM_Keys`). YAML sex/punish/masturbate still call `SkyrimNet_DOM_Actions` scene helpers, which forward into **SkyrimNet_SexLab**. Social Be_/praise/insult stay on `DOM_Keys`.
- Watch the [8-parameter](../authors/actions.md) limit (`style` dropped on some signatures).
- DOM owns arousal; SLSO and other arousal mods do not drive DOM’s arousal factor ([../players/overview.md](../players/overview.md)).
- Anim start/end + orgasm notification routing: [../authors/events.md](../authors/events.md).
- Live masturbate threads: `GetThreads` walks `DOM02.actorAliases` / `GetMaxActorCount` (`GetActorCount` / `actorArray` lag until after Mind `AfterAssign`). `StartScene_masturbate` / `StopScene_Masturbate` call `SaveThreadsJson` so paused SexLab `0050` does not keep a stale dump. On SexLab 0.36.5+ that is a shim kept for DOM: `Scene_Manager.SaveThreadsJson` → `PushDomThreads` → native `Threads_SetDom`, and SexLab's C++ writes `sexlab_get_threads` / `threads.json`. Keep calling `SaveThreadsJson` (works on older SexLab too).
- Build: DOM compiles against `SkyrimNet_SexLab\Scripts\Source`, so `skyrimse.ppj` also imports SexLab `Headers_Source` and `Headers_Source\LoversLedger` (stubs those scripts reference). See [KNOWLEDGEBASE.md](../../KNOWLEDGEBASE.md).
- Overlay live lists: SexLab native `WebUI_PushCascadeChoices` + `index.html` `setCascadeChoices`. Rebuild the SexLab SKSE plugin if that native is missing; without it punish/praise stay empty after the opener click. Do not bake `punishment_reason.json` into overlay catalogs.

## Paused actor JSON

DN paths call `SaveActorInfo`, writing `SKSE/Plugins/SkyrimNet_DOM/actors/<DisplayName>.json` for paused-prompt fallback. Live prompts use `dom_get_actor_info` — see [../authors/prompts.md](../authors/prompts.md) and [../authors/events.md](../authors/events.md).

## When YAML is not enough

1. Add or change a Papyrus function on `SkyrimNet_DOM_Actions` (or API helper)
2. Recompile via `skyrimse.ppj` (or Caprica with the same imports)
3. Point YAML `scriptName` / `executionFunctionName` / `parameterMapping` at the new signature
4. Keep Headers in sync if you maintain stripped headers for Caprica

Parameter names and counts in YAML must match Papyrus exactly.

## Conventions

Do not restate contracts here — see [../reference/papyrus-rules.md](../reference/papyrus-rules.md), [../reference/json-keys.md](../reference/json-keys.md), [../reference/protocol-tokens.md](../reference/protocol-tokens.md).

## Compile / tools

- Project compile: `skyrimse.ppj` / Cursor task **`compile: pyro`** when available
- SKSE plugin: `SKSE_Source` CMake `--preset release` from a VS 2022 x64 Developer Prompt (vcpkg CommonLibSSE-NG; copies `SkyrimNet_DOM.dll` to `SKSE/Plugins/`)
- Caprica / Champollion under game `tools/` (see [AGENTS.md](../../AGENTS.md))
- Always include commented lines when citing line numbers

## Dependencies in code

Setup fails without Diary of Mine. Actions/Events bind to `SkyrimNet_SexLab.esp` for scene manager / SexLab hooks. OStim / UDNG are soft checks where present.
