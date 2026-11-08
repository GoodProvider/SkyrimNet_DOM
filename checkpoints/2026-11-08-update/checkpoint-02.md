# Checkpoint 02: SkyrimNet_DOM updated for Diary of Mine 8.5.6d

Repo: `SkyrimNet_DOM` (plus `../SkyrimNet_SexLab`) · Branch: `main` · Baseline commit: `993911f` · Date: 2026-11-08 · Supersedes [checkpoint-01.md](checkpoint-01.md)

Logs: none. Build and static checks only, no `logs/<timestamp>/` folder was made.

## Goal

Apply checkpoint-01's six findings. Nothing is committed.

## Status

All six are applied and compile. **Nothing has been run in game.**

| Check | Result |
|-------|--------|
| SkyrimNet_DOM `skyrimse.ppj`, full rebuild | 10 succeeded, 0 failed |
| SkyrimNet_SexLab `skyrimse.ppj`, full rebuild | 31 succeeded, 0 failed |
| SkyrimNet_SexLab `skyrimse-pplus.ppj`, full rebuild | 1 succeeded, 0 failed |
| `punishment_reason.json`, `slave_behaviours.json` | Both parse, 40 entries each |
| Removed names in both repos' `Scripts/Source` and in `Headers_Source/DOM` | None left |
| Compiled `.pex` strings | `SkyrimNet_DOM_Menu.pex` and `SkyrimNet_SexLab_Handler_DOM.pex` hold the new names, none of the old |

## What changed

1. [SkyrimNet_DOM_Menu.psc](../../Scripts/Source/SkyrimNet_DOM_Menu.psc): six calls moved to the 8.5.6d names. The NPC `bath_you` call is now `(target, speaker)`.
2. [SkyrimNet_DOM_Events.psc:1396](../../Scripts/Source/SkyrimNet_DOM_Events.psc#L1396): `OnWashSelf` takes `Form abuser`. The body is unchanged, so narration still names the player as the one giving the order.
3. [punishment_reason.json](../../SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json): 28 renamed; 35, 36, 37, 39 added; 40 replaced. `being a bad slaver` is an alias of 39. New tokens added to `dom_punishment_reason.prompt` and `DOMSlave_AddPunishmentReason.yaml`.
4. [slave_behaviours.json](../../SKSE/Plugins/SkyrimNet_DOM/slave_behaviours.json): `showering` became `bathing`; `on_duty_restrained` and `jail_restrained` added.
5. `Headers_Source/DOM` (gitignored): stale members removed and new ones added. Backup in `.claude/backups/2026-11-08-dom-stubs/`.
6. [requirements.md](../../docs/players/requirements.md#L5), the three changelogs and `KNOWLEDGEBASE.md` updated.

## Corrections to checkpoint-01

- **SexLab did need a change.** `SkyrimNet_SexLab_Handler_DOM.psc` read `mind.FACET_Sensuality` and `mind.MOD_Daring`, both gone from DOM. Now `PRISM_Sensuality` (`DOM_Mind.psc:9713`) and `MOD_SocialBoldness` (`DOM_Mind.psc:10246-10247`). This affected DOM arousal math and the step roll on 8.5.6d. The user chose to fix it here.
- **`tied up` was not added.** It is a `GetBehaviourString()` label (`DOM_Actor.psc:18598`). The behaviour value is `tied` (`:1569`), already in the JSON.
- **Shower out of water is not silent.** `Interact_Bathing` falls to `CheckBathingDry`, which notifies. No bridge HUD message was added.

## Beyond the plan

- `../SkyrimNet_SexLab/skyrimse.ppj` gained `<Import>@ModsFolder\Leash Framework\Source\Scripts</Import>`. `SkyrimNet_DOM_Events` needs `LeashFramework`, and without this import `Handler_DOM` and `Handler_DOM_PR` failed to compile while Pyro still exited 0, so the handler fix couldn't reach a `.pex`. `SkyrimNet_SexLab_Handler_DOM.pex` had been stale since 2026-10-31.
- Only SexLab's `CHANGELOG.md` was updated; its player and developer changelogs have no unreleased section yet.

## Working tree notes

- The full rebuilds rewrote every tracked `.pex` in both repos (10 in DOM, about 32 in SexLab). Only `SkyrimNet_DOM_Menu`, `SkyrimNet_DOM_Events` and `SkyrimNet_SexLab_Handler_DOM` have source changes from this work. The `.pex` for `SkyrimNet_DOM_InfoPanel` also picks up that file's existing uncommitted source edits.
- Other uncommitted changes in the tree were there before this session.

## Not yet tested

- Everything in game, on 8.5.6d.
- `bath_me` / `bath_you` with no water nearby. DOM's tub path wasn't traced to its end.
- `DOM_Actor.CheckLeashed` against a SkyrimNet_Leashed wall or floor tie (risk from checkpoint-01, no code change).

## Next

1. In game on 8.5.6d: WebUI shower in and out of water; bath me and bath you with a slave and with an NPC; Pose > Breasts.
2. With `dom.events.ext2` on, confirm wash narration.
3. Run a DOM scene through SexLab and confirm arousal rises normally.
4. Tie a DOM slave to a wall with SkyrimNet_Leashed, then order follow.
5. Check `Papyrus.0.log` for `not found on dom_`, `FACET_Sensuality`, `MOD_Daring`, and `index conflict`.
6. Commit both repos when satisfied. SexLab's `skyrimse.ppj` and `Handler_DOM` should ship together with this bridge update.
