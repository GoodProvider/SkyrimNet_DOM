# SkyrimNet_DOM @ webui @ 9f669fbd5f97497ad576e7fa8affbbed2adb2b8b

Review of [checkpoint-01.md](checkpoint-01.md) plus the first validator run. No plugin files were moved or edited. Supersedes checkpoint-01.

Logs: [logs/2026-10-23-19-55-28/](logs/2026-10-23-19-55-28/) holds the validator output only ([content-validate.json](logs/2026-10-23-19-55-28/content-validate.json), [content-validate.txt](logs/2026-10-23-19-55-28/content-validate.txt), [MANIFEST.txt](logs/2026-10-23-19-55-28/MANIFEST.txt)). No game logs were needed.

## Goal

Unchanged. Align how SkyrimNet_DOM ships prompts and actions with current SkyrimNet (devkit `README.txt`: **beta28-rc5**), using `../Injury_Engine/SKSE/Plugins/SkyrimNet` as the layout model.

## Results

- `content-validate.exe` on `SKSE/Plugins/SkyrimNet/external/goodprovider.dom`: **0 errors, 0 warnings, 0 shadows, 37 unresolved, `ok: true`**, 82 files checked (83 on disk; the extra one is `manifest.json`).
- The 37 unresolved entries are all runtime decorators and variables: `decnpc`, `get_nearby_npc_list`, `is_in_faction`, `dom_actor.loaded`, `actor_having_sex`, and similar. 15 are in `helpers/` and 22 in `submodules/`. The report's `not_checked` says decorators are always listed as unresolved because users register their own. They are expected, not defects. In-game rendering is still the real test.
- The current bundle layout validates. Checkpoint-01's call to leave actions, `prompts/submodules/`, `prompts/helpers/` and `dialogue_actions/` on their paths stands.

## Review of checkpoint-01

Confirmed:

- Devkit is beta28-rc5. Injury Engine layout matches what checkpoint-01 described.
- `manifest.json`: `id` `goodprovider.dom` equals the folder name, `type` `bundle`, `version` `0.1.0`, `min_skyrimnet_version` `0.25.0`, `nsfw` true. Its description still names the Healing Hands trigger and says "Item YAML stays at `config/items/`."
- Not running `content-convert.exe` on the live bundle is correct.
- No `prompts/decisions/dom/` is correct.

Corrections:

1. **`character_bio` count is 13, not 14.** The list in checkpoint-01 already had 13 names.
2. **Action stems were only spot-checked.** All 63 `actions/*.yaml` files now checked. Three differ from `name` only by case: `DOMSlave_Dress.yaml` → `DOMSlave_dress`, `DOMSlave_punish_spanking.yaml` → `DOMSlave_Punish_Spanking`, `DOMSlave_punish_whipping_oral_Target.yaml` → `DOMSlave_Punish_Whipping_Oral_Target`. These are valid. `CONTENT_ROOTS.md` (line 45) and `MIGRATING_TO_BETA25.md` ("Trigger and action filenames") compare case-insensitively, and the validator agrees. Do not rename them. Renaming an action resets players' enabled and cooldown settings.
3. **Settings decision needs its tradeoff stated.** The `MIGRATING_TO_BETA25.md` checklist says to move the schema to `settings/{Name}.yaml`. Leaving it at `config/plugins/SkyrimNet_DOM/manifest.yaml` is a deliberate deferral, not alignment. The old path "still works". `settings/` is marked "after Beta 25 rc11 (reserved on the Hub until released)", and the docs give no exact `min_skyrimnet_version` for it. Keep the deferral until that version is known. When moving it, name the file `settings/SkyrimNet_DOM.yaml` so `Plugin_SkyrimNet_DOM` and the Papyrus `GetConfig*` calls keep working. Then remove the old file from the archive.
4. **Healing Hands reference list was incomplete.** Files that still describe the deleted trigger:
   - `manifest.json` (description)
   - `docs/authors/content.md:45-47`
   - `docs/authors/actions.md:16`
   - `docs/players/overview.md:34`
   - `KNOWLEDGEBASE.md:42`
   - `CHANGELOG.md:5-6`
   - `CHANGELOG-user.md:5`
   - `versions/release-notes-0.1.0.md:3` (a past release: leave it as it is)

   No `.psc`, `.cpp` or `.h` file references it, so the trigger is pure content. HEAD's version is a `hit` trigger on `weapon_id` 316402 (`0x04D3F2`, vanilla Healing Hands) with `direct_narration` and `audience: target`. `git restore` brings it back unchanged.
5. **No item schema exists in the devkit.** `customName`, `customDescription` and `originalName` appear nowhere under `docs/`. `CONTENT_ROOTS.md` only fixes the filename (the form stem) and the `form` key. The validator cannot confirm the item shape either, because `config/items/` is outside the bundle. Moving items is still blocked.

## Findings

- KNOWLEDGEBASE note: action and trigger stems match `name` case-insensitively, but form-keyed stems (`items/` etc.) are "compared exactly" (`CONTENT_ROOTS.md` line 52).
- Validator usage: `content-validate <plugin-dir> [--base-tree <dir>] [--report <out.json>] [--render-out <dir>] [--var key=value ...] [--context <vars.json>] [--hub-path <author>/<slug>] [--verbose]`. `--render-out` with `--context` could render prompts against sample DOM variables to clear some of the unresolved entries. Not tried.

## Not yet tested

- In-game Installed Plugins badge and `SkyrimNet.log` skipped-file warnings for `goodprovider.dom`
- Whether beta28-rc5 still reads `config/items/` (look for item load lines, or hover the Wrist Rope `0xEB8659` in-game)
- In-game rendering of the 37 unresolved decorator calls
- Whether the `Healing_Hands.yaml` deletion was intentional (still undecided)

## Next

1. **Healing Hands, maintainer decision.** Either `git restore SKSE/Plugins/SkyrimNet/external/goodprovider.dom/triggers/Healing_Hands.yaml`, or keep the deletion and edit the seven live files listed in correction 4 (not the 0.1.0 release notes). Either way, bump `manifest.json` `version` (e.g. `0.1.1`) and add a `CHANGELOG.md` line.
2. Re-run `content-validate.exe` after step 1, with the report in a new `logs/<timestamp>/`.
3. In-game: load a save and check `SkyrimNet.log` for `goodprovider.dom` skipped files and for `config/items` loading. Snapshot `SkyrimNet.log` into the next logs folder.
4. Items: move only if step 3 shows `config/items/` is no longer read, or a bundled SkyrimNet item example shows the record shape. Target names are `items/diaryofmine-esm_EB8659.yaml` and `items/diaryofmine-esm_BB1B47.yaml` with `form: "DiaryOfMine.esm|0xEB8659"` / `"...|0xBB1B47"`.
5. Settings `settings/SkyrimNet_DOM.yaml`: defer until the SkyrimNet release that reads `settings/` has a known version. Then move it, raise `min_skyrimnet_version`, and drop the old file.
6. Add the case-insensitive vs exact stem note to `KNOWLEDGEBASE.md`. Fix the "Item YAML stays at `config/items/`" wording only once step 4 is decided.
