# SkyrimNet_DOM @ webui (Healing Hands removed)

Supersedes [checkpoint-02.md](checkpoint-02.md). Logs: [logs/2026-10-23-20-26-20/](logs/2026-10-23-20-26-20/) (validator only).

## Goal

Unchanged. Align SkyrimNet_DOM content shipping with SkyrimNet beta28-rc5, using Injury Engine as the layout model.

## Done this session

- Decision closed: **Healing Hands trigger removed** (`triggers/Healing_Hands.yaml` deleted; bundle ships no `triggers/`).
- `manifest.json`: description no longer names the trigger; `version` 0.1.1.
- Docs: `docs/authors/content.md` Triggers section removed (retitled "Items and dialogue blacklist"); `docs/authors/actions.md` triggers row; `docs/players/overview.md` bullet; `AGENTS.md`, `docs/developers/papyrus.md`, `llms.txt`, `README.md` no longer say the bundle has triggers.
- `KNOWLEDGEBASE.md`: removal noted; case-insensitive action/trigger stems vs exact form-keyed stems (checkpoint-02 step 6, first half).
- `CHANGELOG.md` / `CHANGELOG-user.md`: new 0.1.1 sections. 0.1.0 history, `versions/release-notes-0.1.0.md`, `release-checkpoint.xml` left as past records.
- `content-validate.exe`: 0 errors, 0 warnings, 0 shadows, 37 unresolved (runtime decorators, expected), 82 files, `ok: true`.

## Not yet tested

- In-game Installed Plugins badge and `SkyrimNet.log` skipped-file warnings for `goodprovider.dom`
- Whether beta28-rc5 still reads `config/items/`
- In-game rendering of the 37 unresolved decorator calls

## Next

1. In-game: check `SkyrimNet.log` for `goodprovider.dom` skipped files and `config/items` loading; snapshot it into a new logs folder.
2. Items: move to `items/diaryofmine-esm_EB8659.yaml` / `items/diaryofmine-esm_BB1B47.yaml` only if step 1 shows `config/items/` is no longer read, or an item example shows the record shape. Then fix the "Item YAML stays at `config/items/`" wording (manifest, KB, CHANGELOG).
3. Settings `settings/SkyrimNet_DOM.yaml`: defer until the SkyrimNet version that reads `settings/` is known.
