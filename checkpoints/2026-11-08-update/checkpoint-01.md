# Checkpoint 01: bring SkyrimNet_DOM in line with Diary of Mine 8.5.6d

Repo: `SkyrimNet_DOM` · Branch: `main` · Baseline commit: `993911f` (dirty working tree, nothing committed or edited in this pass) · Date: 2026-11-08

Compared against: `../PAH Diary Of Mine` (`meta.ini` 8.5.6, archive `Diary Of Mine 8.5.6d_SE_fomod.7z`, newest scripts 2026-11-06, `DiaryOfMine.esm` 2026-10-27).

Logs: none. This was a static source and data review, so no `logs/<timestamp>/` folder was made.

## Goal

Find what the bridge must change to work with the latest Diary of Mine. Review only: fixes are planned below and not applied.

## Result

The update breaks part of the bridge at runtime, and **the build won't reveal it**. `skyrimse.ppj` compiles against the local stubs in `Headers_Source/DOM`, not DOM's source, and those stubs still declare functions that DOM has removed.

| # | Severity | Finding | Who sees it |
|---|----------|---------|-------------|
| 1 | **High** | 5 DOM functions the WebUI calls no longer exist | Shower, bath me, bath you, and Pose > Breasts do nothing |
| 2 | Medium | `DOMOnWashSelf` payload gained an `abuser` argument | Wash narration is lost, only with `dom.events.ext2` on |
| 3 | Medium | Punishment reason table has drifted from DOM's (indices 28, 35-40) | Wrong reason or description on those punishments |
| 4 | Low | `slave_behaviours.json` lacks 4 behaviours, including `bathing` | Prompts show no activity text for those states |
| 5 | Low | Stubs carry other stale members | None today, but they hide the next break |
| 6 | Docs | No minimum DOM version is stated | Required once fix 1 lands |

## Findings

### 1. Removed functions (runtime break)

Papyrus resolves these by name at runtime, so each call fails on 8.5.6d. Expected log line: `Method ... not found on dom_actor` (not observed yet, see Not yet tested).

Callers are in [SkyrimNet_DOM_Menu.psc](../../Scripts/Source/SkyrimNet_DOM_Menu.psc). All replacements exist in 8.5.6d.

| Menu line | WebUI `fn` | Current call | Replacement | DOM source (8.5.6d) |
|-----------|-----------|--------------|-------------|---------------------|
| [1244](../../Scripts/Source/SkyrimNet_DOM_Menu.psc#L1244) | `shower` | `slave.DoShower(speaker)` | `slave.Interact_Bathing(speaker)` | `DOM_Actor.psc:16845` |
| [1250](../../Scripts/Source/SkyrimNet_DOM_Menu.psc#L1250) | `bath_me` | `slave.DoBathMaster(speaker)` | `slave.Interact_BathClient(speaker)` | `DOM_Actor.psc:16782` |
| [1252](../../Scripts/Source/SkyrimNet_DOM_Menu.psc#L1252) | `bath_me` (NPC) | `keys.DOMDoNPCBathMe(target, speaker)` | `keys.DOMDoNPCBathClient(target, speaker)` | `DOM_Keys.psc:4263` |
| [1256](../../Scripts/Source/SkyrimNet_DOM_Menu.psc#L1256) | `bath_you` | `slave.DoBathMe(speaker)` | `slave.Interact_BathActor(speaker)` | `DOM_Actor.psc:16778` |
| [1258](../../Scripts/Source/SkyrimNet_DOM_Menu.psc#L1258) | `bath_you` (NPC) | `keys.DOMDoNPCBathMe(speaker, target)` | `keys.DOMDoNPCBathActor(target, speaker)` | `DOM_Keys.psc:4267` |
| [1476](../../Scripts/Source/SkyrimNet_DOM_Menu.psc#L1476) | pose `breasts` | `slave.DoBreastsPresentation(speaker)` | `slave.DoBreastPresentation(speaker)` | `DOM_Actor.psc:13984` |

**Bath direction.** Don't swap these. In `DOM_Interactor.psc`, `Interact_BathClient` (line 2723) sets the abuser to `DOMBathingMode` rank 4 ("will be cleaned") and undresses the abuser. `Interact_BathActor` (line 2889) sets rank 3 ("will clean actor"). So `bath_me` (the slave washes the speaker) is Client and `bath_you` (the speaker washes the slave) is Actor. DOM's own wheel agrees (`DOM_Keys.psc:5989-5994`, `6067-6069`).

**Note the `bath_you` NPC call.** The old call put `speaker` first. The new one takes `(target, speaker)`, the same order as `bath_me`.

**Shower needs water now.** `Interact_Bathing` returns early when the actor isn't in water, calling only `CheckBathingDry` (`DOM_Interactor.psc:2452-2454`). DOM's wheel greys the option out in that case (`DOM_Keys.psc:5972-5974`, `5986`). The WebUI leaf is always offered, so outside water it will look like nothing happened. It also refuses restrained actors. Decide whether a HUD message is enough.

### 2. `OnWashSelf` signature

[SkyrimNet_DOM_Events.psc:1396](../../Scripts/Source/SkyrimNet_DOM_Events.psc#L1396) declares `(Form sender, string washType, bool isObedient)`. DOM now sends `SendExternalEventSASB("WashSelf", akAbuser, wash_type, flag)` (`DOM_Mind.psc:20131`, `20147`), which `DOM_SendEvt` pushes as form, form, string, bool. DOM's own docs agree (`DOM_API.psc:104`). Fix:

```papyrus
Event OnWashSelf(Form sender, Form abuser, string washType, bool isObedient)
```

The sender is Ext2-gated, so this only matters with `dom.events.ext2` on. Only `StartBathing` sends it. The bath-actor and bath-client paths don't.

### 3. Punishment reasons

[punishment_reason.json](../../SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json) loads after DOM's `PunishmentReasons.json` and overwrites the name-to-index map in `Main.Register_Punishment_Reason`.

| Index | DOM JSON | Bridge | Action |
|-------|----------|--------|--------|
| 20 | `undefined020` | `refusing to masturbate` | **Keep.** DOM's code still uses 20 for this (`DOM_Actor.psc:12830`, `13493`) |
| 28 | `refusing to bath` | `refusing to shower` | Rename to `refusing to bath`. Today this overwrites DOM's mapping of `refusing to shower` (37) with 28 and logs `index conflict` |
| 35 | `refusing to kiss` | missing | Add with a description |
| 36 | `refusing a bodycheck` | missing | Add with a description |
| 37 | `refusing to shower` | missing | Add (moved from 28) |
| 39 | `being a worthless slaver` | missing | Add, with alias `being a bad slaver` |
| 40 | `being a useless trainer` | `being a bad slaver` | Replace. DOM uses 39 for slaver and 40 for trainer (`DOM_Mind.psc:15491-15502`) |

`being a bad slaver` is an LLM token in `dom_punishment_reason.prompt` and `DOMSlave_AddPunishmentReason.yaml`, so keep it as an alias. Optionally offer the new tokens there as well.

Hardcoded index 0 ([Events:1092](../../Scripts/Source/SkyrimNet_DOM_Events.psc#L1092), [Menu:1929](../../Scripts/Source/SkyrimNet_DOM_Menu.psc#L1929), [Menu:1981](../../Scripts/Source/SkyrimNet_DOM_Menu.psc#L1981)) is still `no reason`.

### 4. Behaviour text

`Decorators.BehaviourToString` returns `""` for unknown keys. DOM's list (`DOM_Actor.psc`, behaviour index comments) has four that [slave_behaviours.json](../../SKSE/Plugins/SkyrimNet_DOM/slave_behaviours.json) lacks: `bathing`, `on_duty_restrained`, `jail_restrained`, `tied up`. Replace the stale `showering` key with `bathing`. `DOM_Actor.psc:1542` sets `behaviour = "bathing"`.

`tied up` (index 39) only appears as a comment on the return code, so confirm it's a real behaviour string before adding it.

### 5. Stub drift in `Headers_Source/DOM` (gitignored, local only)

Apply together with finding 1:

- `DOM_Actor.psc`: replace `DoBreastsPresentation` (line 541) with `DoBreastPresentation`. Remove `DoShower`, `DoBathMaster`, `DoBathMe` (lines 604-610). Add `Interact_Bathing`, `Interact_BathClient`, `Interact_BathActor`.
- `DOM_Keys.psc`: replace `DOMDoNPCBathMe` (line 151) with `DOMDoNPCBathClient` and `DOMDoNPCBathActor`.

The bridge doesn't call these, so they're cleanup only:

- `DOM_Actor.WillObeyDisgraced`, `DOM_Mind.WillObeyDisgraced`, `DOM_Util.GetPunishmentReasonIndexByName`: gone from DOM.
- `DOM_API.validMoods`, `DOM_API.TraitNames`, `DOM_Mind.FACET_Sensuality`, `DOM_Mind.MOD_Daring`: no matching declaration in DOM.
- `DOM_Core.sendDOMExternalEventToggle`: now on `DOM_SendEvt`.
- `DOM_Actor.prevPoseId`, `wait_for_equipment`: private variables in DOM, declared as properties in the stub.
- `DOM_Actor.StartSexWithNPC`: DOM added `string reason_name=""`.

SkyrimNet_SexLab also imports this stub folder. None of the removed names are called from its Papyrus source, so it needs no change.

### 6. Requirements

After fix 1 the bridge calls functions older DOM builds don't have. Add a minimum to [requirements.md](../../docs/players/requirements.md#L5) and the changelogs. The exact first version that has them is unknown; 8.5.6d is the only one verified.

## Checked and unchanged

| Contract | Coverage | Result |
|----------|----------|--------|
| Stub functions vs DOM | All 13 stub files, arity, types and defaults | Only the items above differ. `WillObey` is intact |
| Registered `DOMOn*` events | 23, every sender vs handler signature | All OK except `WashSelf` |
| Action YAML bound directly to `DOM_Keys` | 12 actions, 5 functions | Signatures match |
| Order names through `DOMOrder_Execute` / `DOMDoActionActor` | 33 actions | All still accepted |
| ESM forms | Item FormIDs, `DOM01` `0xD61`, `DOM02Topic` `0xED87C`, factions used by YAML and WebUI | All present |
| `SkyrimNet_DOM.esp` VMAD | 4 properties pointing at DOM forms | All present |
| Gesture lists | 6 names in `gestures.json` | All still loaded by `DOM_Animator.psc` |
| Orgasm and capture notification text | `brain melts`, `squirms under your grasp`, and others | Still emitted |
| C++ plugin | Searched for DOM script or member strings | None found |

**Leash overlap: no code change, test only.** DOM's `OnLeashPulled` and `OnLeashRagdollPulled` call `EnterFollowTarget(holder)` (`DOM_Core.psc:10962-11001`), and `DOMDoLeash` still does too, so the bridge's `SyncLeashFollow` is still valid and still needed while `GetActor` fails during `AfterAssign`. One new risk: `DOM_Actor.CheckLeashed` (`:6446`, run on every behaviour change at `:18152`) acts when a leash has no holder. It re-attaches the leash to the leader for the `follow_*` behaviours and disconnects it for `travel`. A SkyrimNet_Leashed wall or floor tie could be affected.

**Not caused by this update.** 11 strings in `OnNotifcationSkip` ([Events:757-789](../../Scripts/Source/SkyrimNet_DOM_Events.psc#L757-L789), such as `undergoing sex training.`) aren't in DOM's source, and weren't in the older snapshot either. They match the bridge's own `slave_behaviours.json` text. Left alone. `praise_reasons.json` differs from DOM's list, but nothing in the Papyrus, actions or WebUI references it or those strings.

## Limits of this review

- **There is no copy of the previous DOM release.** The baseline was the local stubs plus `../SkyrimNet_SexLab/extern/Source_DOM` (an older snapshot, predating `DOM_SendEvt`). So some drift above may predate 8.5.6d. What matters is the state against 8.5.6d, not when it changed.
- Behaviour was read from source. Runtime failure messages are inferred.
- `SkyrimNet_SexLab_Handler_DOM` calls were only checked against names flagged as removed or changed, not audited in full.

## Not yet tested

- Nothing was compiled or run in game.
- `bath_me` / `bath_you` with no water nearby. DOM has a tub animation path, but the no-water case wasn't traced to its end.
- Whether a mismatched `OnWashSelf` is dropped outright. Expected from Papyrus argument matching, not observed.
- `CheckLeashed` against a SkyrimNet_Leashed wall or floor tie.

## Next

Confidence in the plan: about 90%. The assumptions are the bath mapping above (taken from DOM's source and wheel menu) and that index 28/37 should follow DOM's JSON. Rollback is a git revert plus restoring the stubs, which aren't in git, so back up `Headers_Source/DOM` first.

1. Back up `Headers_Source/DOM`, then apply the stub changes in finding 5.
2. Apply finding 1 in `SkyrimNet_DOM_Menu.psc`, then fix `OnWashSelf` (finding 2).
3. Update `punishment_reason.json` (finding 3) and `slave_behaviours.json` (finding 4).
4. Decide the no-water behaviour for the `shower` WebUI leaf.
5. Run `compile: pyro` and confirm a clean build.
6. Update `requirements.md`, the changelogs, and `KNOWLEDGEBASE.md`. Add that the stubs hide DOM renames from the compiler, so a post-update diff is required.
7. In game on 8.5.6d: WebUI shower (in water and out), bath me, bath you (slave and NPC), Pose > Breasts. With `dom.events.ext2` on, confirm wash narration. Tie a DOM slave to a wall with SkyrimNet_Leashed, then order follow. Check `Papyrus.0.log` for `not found on dom_` and `index conflict`.
