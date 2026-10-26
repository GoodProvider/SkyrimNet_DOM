# Items and dialogue blacklist

SkyrimNet content that is not YAML actions or prompt slices: item renames/descriptions and the Dialogue Actions blacklist.

See also: [events.md](events.md) · [../players/overview.md](../players/overview.md)

## Items

Path (content plugin, SkyrimNet Beta 25+):

```
SKSE/Plugins/SkyrimNet/external/goodprovider.dom/items/
```

Example — Wrist Rope ([`diaryofmine-esm_EB8659.yaml`](../../SKSE/Plugins/SkyrimNet/external/goodprovider.dom/items/diaryofmine-esm_EB8659.yaml)):

```yaml
form: "DiaryOfMine.esm|0xEB8659"
originalName: Wrist Rope
customName: Rope cuffs
customDescription: A rough rope binding the wrists together and making arms useless.
```

| Field | Role |
|-------|------|
| `form` | `"Plugin.esm\|0x<id>"`, quoted (DOM items use `DiaryOfMine.esm`) |
| `originalName` | Sanity check / docs |
| `customName` | Optional display rename |
| `customDescription` | LLM-facing item text |
| `show_in_prompts` | `false` hides the item from NPC equipment lists in prompts (default `true`). `enabled` is refused on items. |

The filename must be the form stem of `form`, compared exactly: `DiaryOfMine.esm|0xEB8659` → `diaryofmine-esm_EB8659.yaml` (see SkyrimNet `docs/modding/CONTENT_ROOTS.md`). That simple rule only holds for plugin names made of `a-z0-9_`. A name with other characters (spaces, dots) or longer than 40 bytes gets a hash suffix, e.g. `Mod A.esp|0x000123` → `mod_a-a44f2ca6_000123.yaml`. Let the dashboard name those files. The SkyrimNet dashboard's Items page can export a record in this shape.

`diaryofmine-esm_BB1B47.yaml` (DOM Training Info) is shipped with `show_in_prompts: false`.

If you write more Diary of Mine item descriptions, please share them.

## Dialogue Actions blacklist

Path (content plugin, SkyrimNet Beta 25 rc11+):

```
SKSE/Plugins/SkyrimNet/external/goodprovider.dom/dialogue_actions/
```

SkyrimNet's `available_dialogue` decorator shows vanilla/mod dialogue to the LLM. Core `0740_quest_dialogue.prompt` puts it under "Quests You Could Raise", and the `SpeakQuestLine` action can fire those lines. Diary of Mine's `DOM01` ("Diary Of Mine Readers Manager") has a quest type and an objective, so SkyrimNet classes its player→slave command menu (Orders, rope/chain poses) as quest dialogue. [`dom01_readers_manager.yaml`](../../SKSE/Plugins/SkyrimNet/external/goodprovider.dom/dialogue_actions/dom01_readers_manager.yaml) blacklists it:

```yaml
kind: lists
name: Diary of Mine Readers Manager
description: Keeps the LLM from seeing or firing Diary of Mine's DOM01 player-to-slave command menu (Orders, bondage poses) as quest dialogue.
blacklist:
  - DOM01
```

| Field | Role |
|-------|------|
| `kind: lists` | Whitelist/blacklist file |
| `blacklist` | Quest EditorIDs (whole quest), or `TIF__XXXXXXXX` for a single line |
| `whitelist` | Lines to allow even when their category is disabled |

SkyrimNet ships examples in `SKSE/Plugins/SkyrimNet/library/skyrimnet.base/dialogue_actions/` (`nff_follower_controller.yaml` blacklists `nwsFollowerController`). In game, the entries appear under SkyrimNet Settings (search "blacklist"). The blacklist applies to every `available_dialogue` mode (`quest`, `fires`, `ids`, unfiltered).

## Tips

- Copy a sibling item YAML for Diary of Mine items; for other plugins, export from the dashboard's Items page so the filename stem is right.
- Triggers are independent of `DOMSlave_*.yaml` eligibility — they key off SkyrimNet event criteria only.
