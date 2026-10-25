# SkyrimNet_DOM @ webui @ 9f669fbd5f97497ad576e7fa8affbbed2adb2b8b

Survey only. No plugin files were moved or edited. Logs were not snapshotted: `AGENTS.md` has no Logs list, this pass did not need game logs, and `checkpoints/skyrimnet/logs/` had no loose files.

## Goal

Realign how SkyrimNet_DOM ships prompts and actions with current SkyrimNet. Location model: `../Injury_Engine/SKSE/Plugins/SkyrimNet`. API: `../SkyrimNet devkit` (README: **beta28-rc5**).

## Decisions

- This session writes the handoff and stops. The next session does the file moves.
- Follow Injury Engine for where prompts, actions, and the settings schema live.
- Do not run `content-convert.exe` on `external/goodprovider.dom/`. That tool ports a Beta 24 loose tree (`config/` + `prompts/` at the source root) into a staging directory. DOM actions and prompts are already a bundle. Pointing the converter at the live layer is the failure mode the devkit command warns against.
- Leave `prompts/helpers/` in place. Injury Engine has no helpers; SkyrimNet_SexLab still ships `prompts/helpers/` beside `prompts/decisions/`. Helper paths are prompt identities, not decision templates.
- Leave settings at `config/plugins/SkyrimNet_DOM/manifest.yaml`. Injury Engine does the same (`config/plugins/Injury_Engine/manifest.yaml`) and says so in its bundle description. Papyrus still reads `Plugin_SkyrimNet_DOM`. The devkit `settings/{Name}.yaml` root exists (after Beta 25 rc11, Hub-reserved until that release) and wins over the old path when both exist. Do not add it unless a later session is explicitly moving schemas.
- Do not invent `prompts/decisions/dom/`. DOM Papyrus and `SKSE_Source` do not call `SendCustomDecisionToLLM` / `PublicSendCustomDecisionToLLM`.

## Findings

Devkit docs that govern the layout:

- `docs/modding/MIGRATING_TO_BETA25.md` — Beta 25 ignores loose `prompts/`, `config/triggers/`, `config/actions/`. Ship `external/{author}.{slug}/` with `manifest.json`. Folder name must equal `id`.
- `docs/modding/CONTENT_ROOTS.md` — roots inside the plugin. Filename stem must equal the in-file identity (`name` for actions and triggers).
- `docs/modding/WORKFLOW_PROMPTS.md` (decision templates) and `CppAPI/PublicAPI.h` (custom decisions, v12).
- `tools/content-validate.exe` — loads a plugin the way the game does. Not run this session.
- `tools/content-convert.exe` — Beta 24 loose-tree porter. Not the tool for this tree.

### Injury Engine locations (the model)

```
SKSE/Plugins/SkyrimNet/config/plugins/Injury_Engine/manifest.yaml
SKSE/Plugins/SkyrimNet/external/goodprovider.injuryengine/
  manifest.json
  actions/*.yaml
  prompts/submodules/character_bio/*.prompt
  prompts/submodules/user_final_instructions/*.prompt
  prompts/decisions/injury_engine/*.prompt
```

`manifest.json`: `id` `goodprovider.injuryengine`, `type` `bundle`, semver `version`, `min_skyrimnet_version` `0.25.0`, `mods[]` with `Injury_Engine.esp` required. Description states that menu settings stay in `config/plugins/Injury_Engine/`.

Decision files use `[ state ]` / `[ question <id> noul|choice|score ]` / `[ criteria ]`. Chat markers (`[ system ]`, `[ user ]`) are invalid there. Call name is the path under `prompts/decisions/` without `.prompt` (`injury_engine/accept_surrender`). A leading `decisions/` is accepted. C++ entry is `PublicSendCustomDecisionToLLM` (`CppAPI/PublicAPI.h`, v12). No chat fallback: missing decision provider returns `no_decisions_route`.

### DOM locations today

Already the same bundle shape for prompts and actions:

```
SKSE/Plugins/SkyrimNet/config/plugins/SkyrimNet_DOM/manifest.yaml
SKSE/Plugins/SkyrimNet/config/items/diaryofmine_BB1B47.yaml
SKSE/Plugins/SkyrimNet/config/items/diaryofmine_EB8659.yaml
SKSE/Plugins/SkyrimNet/external/goodprovider.dom/
  manifest.json
  actions/*.yaml
  prompts/submodules/character_bio/*.prompt          (14 files)
  prompts/submodules/user_final_instructions/0551_dom_instructions.prompt
  prompts/helpers/*.prompt                           (4 files)
  dialogue_actions/dom01_readers_manager.yaml
```

`manifest.json` `id` is `goodprovider.dom` (folder matches), `type` `bundle`, `version` `0.1.0`, `min_skyrimnet_version` `0.25.0`, `mods[]` `SkyrimNet_DOM.esp` required, `nsfw` true. Description still says the bundle ships the Healing Hands trigger, that settings stay in `config/plugins/SkyrimNet_DOM/`, and that item YAML stays at `config/items/`.

Prompt set under `prompts/`:

- `submodules/character_bio/`: `0006_dom_variables`, `0015_dom_characteristics`, `0016_dom_slaver`, `0017_dom_orders`, `0018_dom_promise_virgin`, `0030_dom_experience`, `0031_dom_love_loyal`, `0055_dom_physical_activity`, `0305_dom_personality`, `0410_dom_appearance`, `0413_dom_bondages`, `0515_dom_skills`, `7200_dom_notifications`
- `submodules/user_final_instructions/0551_dom_instructions.prompt`
- `helpers/`: `dom_action_sex_start`, `dom_action_rape_start`, `dom_action_raped_by_start`, `dom_punishment_reason`

`dialogue_actions/dom01_readers_manager.yaml` is `kind: lists` with `blacklist: [DOM01]`. That root is valid in CONTENT_ROOTS (Beta 25, Hub-gated). Injury Engine has no dialogue-actions file; keep this one.

Action YAML is already one file per action under `actions/`, which is the Injury Engine location. `DOMSlave_Kneel.yaml` uses `name: DOMSlave_Kneel` (stem matches). Injury Engine’s `Torture_Target.yaml` adds `label` and `defaultPriority`; the workflow schema still treats those as ordinary fields, not a new directory.

### Working tree (not produced by this session)

Branch `webui`, HEAD `9f669fbd5f97497ad576e7fa8affbbed2adb2b8b`.

- `M AGENTS.md`
- `D SKSE/Plugins/SkyrimNet/external/goodprovider.dom/triggers/Healing_Hands.yaml`
- `?? SKSE_Source/vcpkg-ports/`
- `?? Scripts/SkyrimNet_DOM_Native.pex`
- `?? Scripts/SkyrimNet_DOM_Obedience.pex`
- `?? checkpoints/`

`Healing_Hands.yaml` is deleted in the worktree. Docs and the bundle description still describe it: `docs/authors/content.md`, `KNOWLEDGEBASE.md`, `CHANGELOG.md`, `manifest.json`. The trigger root itself is still valid (`triggers/*.yaml`, stem equals `name`). Do not treat the deletion as decided.

### Items are the location that differs

Beta 25 stops reading loose `prompts/`, `config/triggers/`, and `config/actions/`. It does not say that about `config/items/` or `config/plugins/`. CONTENT_ROOTS puts shipped item customizations in the plugin at `items/`, Hub-gated, read by 0.25.0. The filename is the form stem of `form: "Plugin.esp|0x01396B"`.

DOM still ships the legacy shape at `config/items/`:

- `diaryofmine_EB8659.yaml` — Wrist Rope / Rope cuffs (`plugin: DiaryOfMine.esm`, `formID: 0xEB8659`, `customName`, `customDescription`)
- `diaryofmine_BB1B47.yaml` — stub, `enabled: false` (`docs/authors/content.md`)

Injury Engine ships no items, so it is not a model for this root. A form-stem name for `DiaryOfMine.esm|0xEB8659`, following CONTENT_ROOTS (lowercase stem, `-esm` because the extension is `.esm`, no hash because no character was replaced, six-digit uppercase id), would be `diaryofmine-esm_EB8659.yaml` with `form: "DiaryOfMine.esm|0xEB8659"`. Same pattern for `0xBB1B47` → `diaryofmine-esm_BB1B47.yaml`. The legacy keys (`plugin`, `formID`, `originalName`, `customName`, `customDescription`) are not the record shape in CONTENT_ROOTS. Confirm the live item schema with `content-validate.exe` or a bundled example before moving them. `docs/authors/content.md` and `KNOWLEDGEBASE.md` still document `config/items/`.

### What is already aligned

- Actions: `external/goodprovider.dom/actions/`
- Bio and final-instruction prompts: `external/goodprovider.dom/prompts/submodules/...`
- Plugin id `goodprovider.dom` equals the folder name
- Settings schema: `config/plugins/SkyrimNet_DOM/manifest.yaml` (`dom.events.*`), same choice as Injury Engine

## Not yet tested

- `content-validate.exe` on `external/goodprovider.dom`
- In-game Installed Plugins badge and `SkyrimNet.log` skipped-file warnings
- Whether beta28-rc5 still loads `config/items/`
- Whether the `Healing_Hands.yaml` deletion was intentional

## Next

1. Run `../SkyrimNet devkit/tools/content-validate.exe` on `SKSE/Plugins/SkyrimNet/external/goodprovider.dom` and keep its report. Do not run `content-convert.exe` against that folder.
2. Decide `triggers/Healing_Hands.yaml`: restore it into the bundle, or drop it from `manifest.json`, `docs/authors/content.md`, `KNOWLEDGEBASE.md`, and `CHANGELOG.md`.
3. Leave actions, `prompts/submodules/`, `prompts/helpers/`, `dialogue_actions/`, and `config/plugins/SkyrimNet_DOM/manifest.yaml` on their current paths.
4. Items, only after the validator or a bundled example confirms the record shape: move the two Diary of Mine files into `external/goodprovider.dom/items/` under form-stem names, rewrite `form`, bump `manifest.json` `version`, and update `docs/authors/content.md`, `docs/players/overview.md`, and `KNOWLEDGEBASE.md`. Until that confirmation, leave `config/items/`.
5. Add `prompts/decisions/dom/` only when a script or the DLL calls `SendCustomDecisionToLLM` / `PublicSendCustomDecisionToLLM`.
6. After any shipped file change, bump `version` (strict semver). Keep `min_skyrimnet_version` at `0.25.0` unless a new root needs a later release (`settings/` is the one that is newer than 0.25.0).
