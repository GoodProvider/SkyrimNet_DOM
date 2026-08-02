# AGENTS.md

Agent guidance for SkyrimNet_DOM (SkyrimNet ↔ Diary of Mine bridge, with SkyrimNet_SexLab).

## What this is

Bridge mod between SkyrimNet (LLM) and Diary of Mine. Sex/punish scenes go through SkyrimNet_SexLab.

## Key paths

| Path | Role |
|------|------|
| `Scripts/Source/` | Papyrus source |
| `Scripts/` | Compiled `.pex` |
| `Headers/` | Papyrus headers |
| `skyrimse.ppj` | Pyro project |

Repo root: `c:\Skyrim\dev\mods\SkyrimNet_DOM`.

Sibling: `c:\Skyrim\dev\mods\SkyrimNet_SexLab` — see its [docs/](../SkyrimNet_SexLab/docs/) and [README](../SkyrimNet_SexLab/README.md).

## Documentation map

| Job | Read |
|-----|------|
| Agent router | [llms.txt](llms.txt) |
| Players | [docs/players/overview.md](docs/players/overview.md) |
| Action YAML | [docs/authors/actions.md](docs/authors/actions.md) |
| Prompts | [docs/authors/prompts.md](docs/authors/prompts.md) |
| Events | [docs/authors/events.md](docs/authors/events.md) |
| Punishment | [docs/authors/punishment.md](docs/authors/punishment.md) |
| Content | [docs/authors/content.md](docs/authors/content.md) |
| Papyrus | [docs/developers/papyrus.md](docs/developers/papyrus.md) |
| Release docs | [release-guide.xml](release-guide.xml) + [release-checkpoint.xml](release-checkpoint.xml) |

### Canonical contracts (do not restate elsewhere)

| Topic | File |
|-------|------|
| Papyrus language / naming / traces | [docs/reference/papyrus-rules.md](docs/reference/papyrus-rules.md) |
| Protocol value tokens (`_pain_`, …) | [docs/reference/protocol-tokens.md](docs/reference/protocol-tokens.md) |
| External JSON keys | [docs/reference/json-keys.md](docs/reference/json-keys.md) |

## Compile

- Papyrus: VS Code/Cursor task **`compile: pyro`** / `skyrimse.ppj` only (unless maintainer asks otherwise).

Tools under game `tools/`: Champollion, Caprica, XEditLib, Spriggit (see notes in historical sessions / sibling repo).

## Commit messages

Format (required for agent-generated commits):

1. Subject: ≤ ~72 chars, imperative summary of *why* / outcome (not a file dump).
    - focus on the goal of the change, not wht the change did
2. Blank line.
3. Body: multi-line `-` bullets naming concrete artifacts (paths, keys, YAML action names, FormIDs).

Do not use a single paragraph essay. Do not use vague subjects (`update`, `fix`, `wip`, `compiled`).

Good:

    Fix DOM slave sex start eligibility for no-penis scenes

    - SKSE/.../DOMSlave_sex_start_2_no_penis.yaml: gate on HasPenis
    - Scripts/Source/SkyrimNet_DOM_Actions.psc: StartScene_Consensual_Two target assign
    - docs/reference/json-keys.md: document bare lowercase keys

Bad:

    Refactored action functions and YAML configurations for improved clarity...

## Standing rules

- **Nexus first:** search the mod’s Nexus page before investigating blind.
- **Knowledgebase:** consult [KNOWLEDGEBASE.md](KNOWLEDGEBASE.md) before changes; append new quirks after sessions.
- **INI load order:** Skyrim.ini then SkyrimPrefs.ini (last wins).
- **SE ≠ VR** — never assume parity.
- **Prompts:** `character_bio` files share one namespace; each `user_final_instructions` file is its own namespace. DOM prompts coexist with SkyrimNet_SexLab under `SKSE/Plugins/SkyrimNet/prompts`.

### Top gotchas (see KNOWLEDGEBASE for detail)

RemoveSpell vs DispelSpell; spell effect casting types; fragile VMAD; PlayIdle fails in VR; Wait() under 100ms unreliable; ESL FormID range; loose files override BSA; Condition OR > AND; non-auto properties blank on load; PreWEAPON/PreSHIELD CTD in VR; ONAM for ESM temps; SetVehicle HMD desync; GoToState("") in OnUnload; navmesh CK-only.

## Safety rules

Hooks in `.claude/settings.json` may enforce these.

### Hard blocked

- Deleting game/config install dirs or Bethesda registry keys
- Direct writes to ESP/ESM/ESL/BSA/BA2 (use xelib / Spriggit)

### Requires confirmation

- Edits in game/config directories; `.psc`/`.pex`; Skyrim INIs; SKSE plugin INIs; load-order files; destructive shell on those trees

### General

- Review diffs before applying; user knows modding/INI; propose hook/KB gaps when risk patterns appear
- Audit trail may live under `.claude/backups/`

## Confidence (mandatory before game/script/ESP changes)

1. State confidence 0–100% and assumptions
2. Investigate: KNOWLEDGEBASE, sources, web for SE/VR quirks
3. Target ≥ 90%; if lower, document gaps
4. Never assume SE = VR

| Range | Action |
|-------|--------|
| 95–100% | Proceed with confirmation |
| 80–94% | Proceed with caveats |
| 60–79% | Research more |
| < 60% | Do not proceed |

Checklist: KB → sources → web → rollback → hook-gap check.
