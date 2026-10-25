# Checkpoint 01 — `Configuration 'Plugin_SkyrimNet_DOM' not found`

Repo: `SkyrimNet_DOM` · Branch: `webui` · Baseline: `263b1f1` (plus uncommitted working tree) · Date: 2026-10-23

Logs: [logs/2026-10-23-21-58-21/](logs/2026-10-23-21-58-21/) (`SkyrimNet.log`, `Papyrus.0.log`, `MANIFEST.txt`)

## Goal

Find the cause of `[2026-10-23 21:53:30.297] [error] [ConfigManager.h:236] Configuration 'Plugin_SkyrimNet_DOM' not found`.

## Findings

- **The settings manifest did not parse at startup.** [SkyrimNet.log:288](logs/2026-10-23-21-58-21/SkyrimNet.log#L288): `PluginConfig.cpp:198 Failed to initialize from settings schema ...\SkyrimNet_DOM\manifest.yaml: yaml-cpp: error at line 44, column 234: unexpected scalar`. Next comes [L289](logs/2026-10-23-21-58-21/SkyrimNet.log#L289) `PluginConfigDiscovery.cpp:95 Failed to load plugin config 'Plugin_SkyrimNet_DOM'`. The same error appears again at L322/323 and L405/406.
- **So the config never got registered.** Every Papyrus config read logs `ConfigManager.h:236 ... not found` and then `PapyrusConfigUtils.cpp:45 GetConfigInt: ... returning default value` (10 hits, the first at 21:53:30.297). Every DOM setting fell back to its default (`dom.events.*`, `dom.punish.torture_choose_reason`, `dom.praise.heal_choose_reason`), and the DOM settings were missing from the WebUI.
- **Cause:** the new, uncommitted field `dom.praise.heal_choose_reason` at [manifest.yaml:44](../../SKSE/Plugins/SkyrimNet/config/plugins/SkyrimNet_DOM/manifest.yaml#L44). Its `description:` is a double-quoted string that contained `"Being a good slave"`. The inner `"` ended the string, and yaml-cpp reported column 234, which is where `Being` starts.

## Results

- Fixed: the inner quotes are now single quotes (`'Being a good slave'`). The wording is unchanged.
- Checked: a scan of every line in the manifest finds balanced double quotes. A full YAML parse did **not** run because PyYAML is not installed. In-game load is the real test.
- [KNOWLEDGEBASE.md](../../KNOWLEDGEBASE.md) has a new section: "Manifest YAML error drops the whole config".

## Not yet tested

- In-game reload of the fixed manifest.

## Next

1. Relaunch the game, then check `SkyrimNet.log` for **no** `PluginConfig ... SkyrimNet_DOM` error and **no** `Plugin_SkyrimNet_DOM' not found`.
2. In the SkyrimNet WebUI settings, check that SkyrimNet_DOM lists the Events, Punishment and Praise categories.
3. Commit the manifest fix together with the rest of the `heal_choose_reason` work.
