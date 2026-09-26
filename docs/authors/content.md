# Items and triggers

SkyrimNet content that is not YAML actions or prompt slices: item renames/descriptions, hit→Direct Narration triggers, and the Dialogue Actions blacklist.

See also: [events.md](events.md) · [../players/overview.md](../players/overview.md)

## Items

Path:

```
SKSE/Plugins/SkyrimNet/config/items/
```

Example — Wrist Rope ([`diaryofmine_EB8659.yaml`](../../SKSE/Plugins/SkyrimNet/config/items/diaryofmine_EB8659.yaml)):

```yaml
plugin: DiaryOfMine.esm
formID: 0xEB8659
originalName: Wrist Rope
customName: Rope cuffs
customDescription: A rough rope binding the wrists together and making arms useless.
```

| Field | Role |
|-------|------|
| `plugin` + `formID` | Resolve the base form (DOM items use `DiaryOfMine.esm`) |
| `originalName` | Sanity check / docs |
| `customName` | Optional display rename |
| `customDescription` | LLM-facing item text |
| `enabled` | `false` to ship a stub without applying it |

`diaryofmine_BB1B47.yaml` (DOM Training Info) is an example stub with `enabled: false`.

If you write more Diary of Mine item descriptions, please share them.

## Triggers

Path (Beta 25 content plugin):

```
SKSE/Plugins/SkyrimNet/external/goodprovider.dom/triggers/
```

**Healing Hands** ([`Healing_Hands.yaml`](../../SKSE/Plugins/SkyrimNet/external/goodprovider.dom/triggers/Healing_Hands.yaml), `name: Healing_Hands`) — comfort / blood-cleanup narrative hook:

- Fires on `hit` when `weapon_id` equals Healing Hands (316402).
- Response type `direct_narration` with warm “healed / grateful” copy.
- Audience `target`; short cooldown (`cooldownSeconds: 5` in the trigger file).

This is SkyrimNet config, not Papyrus in this mod. Use it when play calls for cleaning up welts before comfort dialogue (see [../players/overview.md](../players/overview.md)).

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

- Copy a sibling item YAML; keep `plugin`/`formID` exact.
- Prefer `enabled: false` over deleting unfinished entries.
- Triggers are independent of `DOMSlave_*.yaml` eligibility — they key off SkyrimNet event criteria only.
