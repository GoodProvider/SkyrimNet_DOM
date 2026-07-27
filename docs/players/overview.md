# Player overview

(Alpha) SkyrimNet_DOM — basic SkyrimNet support for Diary of Mine.

Requirements: [requirements.md](requirements.md). Authoring: [../authors/actions.md](../authors/actions.md). Changelog: [../../CHANGELOG.md](../../CHANGELOG.md).

## What it does

- Converts most DOM activity into Direct Narration or SkyrimNet events
  - DOM does not expose everything as events; not every Ext2 path is registered — see [../authors/events.md](../authors/events.md)
- SkyrimNet YAML actions for common slave orders (`SKSE/Plugins/SkyrimNet/config/actions/DOMSlave_*.yaml`)
  - Social (`Be_`): flatter, insult, praise-tell, promises, scold, refuse
  - `Act*` (silent / respectful / maid), Poses, FightForMe, chores/entertain, movement/posture, drink
  - Dress / Undress
  - Sex (2P penis / no_penis, 3P) / masturbate / stop-masturbate / refuse (via SkyrimNet_SexLab scene helpers)
  - Punish (+ refused / other → punishment reasons)
- Character bio prompts for DOM slaves (appearance, bondages, skills, aged notifications, and more)
- Punishment reason mapping (`SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json`)
- Item descriptions for DOM ropes
- Healing Hands trigger — cleanup / comfort Direct Narration when healing is cast

## Notes / FAQ

### DOM arousal

DOM has its own arousal system. Arousal-changing mods (including SLSO) are ignored for DOM arousal.

### Chat feels quiet or spammy

DOM emits far more events than we send to the LLM. Much lands in history or aged notifications. Use Direct Narration or dialogue to frame context when needed.

### LLM says yes, DOM says no

DOM has its own obedience logic. Roll with the mismatch.

### Occasional Direct Narration

Helps frame events to match the story you want.

## Shipped action families

| Family | What |
|--------|------|
| `Be_` / `Act*` / `Pose_` | Social and posture orders |
| FightForMe / chores / drink | Follow, kneel, flowers, alcohol, etc. |
| Dress / Undress | Clothing via bridge |
| `sex_` / masturbate | 2P fucking / giving, 3P, masturbate / stop |
| `punish_` | Spanking, whipping/oral, refused, other |

## Related

- [requirements.md](requirements.md)
- [../authors/actions.md](../authors/actions.md)
- Sibling bridge: [../SkyrimNet_SexLab/docs/players/overview.md](../../../SkyrimNet_SexLab/docs/players/overview.md) (if present)
