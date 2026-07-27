# Items and triggers

SkyrimNet content that is not YAML actions or prompt slices: item renames/descriptions and hit→Direct Narration triggers.

See also: [README](../README.md) · [Events](Events.md)

## Items

Path:

```
SKSE/Plugins/SkyrimNet/config/items/
```

Example — Wrist Rope ([`diaryofmine_EB8659.yaml`](../SKSE/Plugins/SkyrimNet/config/items/diaryofmine_EB8659.yaml)):

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

If you write more Diary of Mine item descriptions, please share them (README already asks).

## Triggers

Path:

```
SKSE/Plugins/SkyrimNet/config/triggers/
```

**Healing Hands** ([`Healing Hands.yaml`](../SKSE/Plugins/SkyrimNet/config/triggers/Healing%20Hands.yaml)) — comfort / blood-cleanup narrative hook:

- Fires on `hit` when `weapon_id` equals Healing Hands (316402).
- Response type `direct_narration` with warm “healed / grateful” copy.
- Audience `target`; short cooldown.

This is SkyrimNet config, not Papyrus in this mod. Use it when play calls for cleaning up welts before comfort dialogue (see README Features).

## Tips

- Copy a sibling item YAML; keep `plugin`/`formID` exact.
- Prefer `enabled: false` over deleting unfinished entries.
- Triggers are independent of `DOMSlave_*.yaml` eligibility — they key off SkyrimNet event criteria only.
