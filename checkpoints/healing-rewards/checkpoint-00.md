# Healing rewards — checkpoint 00

Repos and baselines:
- `SkyrimNet_DOM`: branch `webui`, baseline `263b1f1`, uncommitted.
- `SkyrimNet_SexLab`: branch `profile`, baseline `902bcd77`, uncommitted and mixed with unrelated pending edits.

Logs: none yet. The work has not been tested in game.

## Goal
Healing Hands on a DOM slave **rewards** (praises) them instead of giving care comfort, unless the slave is in shock. A setting optionally lets the player pick the praise reason.

## Decisions
- **Reward = praise.** DOM has no "reward" action. Its reward is `DOM_Actor.StartPraising(abuser, reason, type)`, which fires `DOMOnPraised`, which the existing `Events.OnPraised` narrates.
- **Shocked = care.** A slave with `DOM_Mind.mood == "shocked"` still gets `ComfortCareNoHug`. Everyone else is praised.
- **Type is always `"tell"`**, so no pat or kiss idle interrupts the spell cast.
- **Setting** `dom.praise.heal_choose_reason` ("Ask player praise reason when healing", default off, category Praise):
  - On, player heals → SexLab `Choice_Open` list. The default reason comes first, then DOM's queued praise reasons, then "crying" (DOM toggle), then **custom** (inline text).
  - Pick → praise for that reason. Blank custom → default reason.
  - **Close / Esc → no praise** (user decision).
- **Default reason** is "being a good slave" ("being a good slaver" for slavers), from `Menu.DefaultPraiseReason`. It is always listed first and is used when the setting is off.

## Changes

### SkyrimNet_DOM
- [SkyrimNet_DOM_Events.psc](../../Scripts/Source/SkyrimNet_DOM_Events.psc), `OnInjuryHealStart`: routing as described above.
- [SkyrimNet_DOM_Main.psc](../../Scripts/Source/SkyrimNet_DOM_Main.psc): `heal_choose_reason` property, read in `ApplyPluginConfig`.
- [SkyrimNet_DOM_Menu.psc](../../Scripts/Source/SkyrimNet_DOM_Menu.psc):
  - `DefaultPraiseReason` (global) and `PraiseReasonList` (shared with `TM_ListPraiseReasons`, which now also lists the default first).
  - `OpenHealPraiseList`, `HealPraiseChoice`, and `TM_DoHealPraise(speaker, slaveId, reason)`. The parameter mapping order matches this signature.
- [manifest.yaml](../../SKSE/Plugins/SkyrimNet/config/plugins/SkyrimNet_DOM/manifest.yaml): the new setting.
- Docs: `CHANGELOG.md`, `CHANGELOG-user.md`, `docs/developers/papyrus.md` (Healing Hands line), `docs/players/overview.md`, `KNOWLEDGEBASE.md` ("Heal = praise unless shocked").

### SkyrimNet_SexLab
- `PrismaUI/views/SkyrimNet_SexLab/index.html`, solo choice list:
  - An `opensText` row shows `#choice-text` (input + Ok).
  - Ok or Enter calls `firePapyrusOption(opt, {<first dynamic mapping name>: text})`.
  - Esc closes the text box first, then the list.
  - Functions: `choiceTextOpen`, `choiceTextClose`, `choiceTextIsOpen`, `choiceTextOk`.
- `docs/developers/webui.md`: Choice_Open line.

## Results
- Pyro `compile: pyro` succeeds: Events, Main and Menu compile with 0 failures.
- C++ `Choice_Open` (SexLab `SKSE_Source/src/Papyrus_WebUI.cpp:508`) forwards the JSON unchanged, so `openstext` reaches the view.

## Findings / risks
- **The `"shocked"` mood string is inferred.** It comes from `DOMOnMoodChange` → `mood_to_Sentence`. DOM's source is not available locally. If shocked slaves get praised, check `mind.mood` against `DOM_Core.GetMood(target)` in a trace.
- **Positional mapping.** Papyrus `parameterMapping` looks positional (every existing callback matches its order). If the list's picks arrive with swapped arguments, this is why.
- **HTML not deployed.** The SexLab view edit only takes effect once that HTML is deployed. Without it, clicking custom fires with no text, which gives the default reason.

## Not yet tested
Everything in game.

## Next
1. Deploy both mods: the DOM `.pex` files and the SexLab `index.html`. Load a save with a DOM slave and Healing Hands equipped.
2. Setting off, heal a calm slave → DOM praise notification and `OnPraised` narration for "being a good slave", no care.
3. Heal a shocked slave (Status panel Mood field) → `ComfortCareNoHug` trace and the "Comforting … with care" notification.
4. Setting on, heal a calm slave:
   - The list shows the default first, then queued reasons and custom.
   - Pick a reason → praise for that reason.
   - Custom + text → praise for the text.
   - Close / Esc → no praise.
5. Regression checks:
   - The torture reason list still works.
   - The TargetMenu praise menu still works, with the default now first.
6. Capture `SkyrimNet_DOM` / `Papyrus.0.log` traces (`OnInjuryHealStart`, `OpenHealPraiseList`, `TM_DoHealPraise`) into `checkpoints/healing-rewards/logs/`.
7. Commit both repos once the tests pass. The SexLab repo has unrelated pending changes, so stage only `index.html` and `docs/developers/webui.md`.
