# Player overview

(Alpha) SkyrimNet_DOM — basic SkyrimNet support for Diary of Mine.

Requirements: [requirements.md](requirements.md). Authoring: [../authors/actions.md](../authors/actions.md). Changelog: [../../CHANGELOG.md](../../CHANGELOG.md).

LLM actions and prompts ship as SkyrimNet plugin `goodprovider.dom` (External on the Plugins page). Requires SkyrimNet 0.25.0+. Tune Ext2 / notification ring / short-lived TTL in the SkyrimNet dashboard (`dom.events.*`), not an in-game MCM.

## In-game WebUI

Open the SkyrimNet SexLab overlay hotkey (`\` by default), then set the ControlPanel **mode** pulldown to **SkyrimNet DOM**.

- **Target** pulldown: nearby actors plus **All Slaves** (group orders; opens the Slaves roster).
- **Views:** **Status** (focused actor stats + respectful/silent/fight/orgasm/task toggles) and **Slaves** (all owned aliases, not nearby-only). Click a roster row to focus that slave and open Status, even if they are far.
- Left **TargetMenu:** pulldowns that can be used on the focused actor (order / abuse / training / restrain / clothes). Slave-only pulldowns are omitted for non-slaves. SexLab sex/scene rows are hidden in DOM mode; sex/punish live under training.
- TargetMenu execute closes the overlay so DOM packages can run. Status/Slaves stay open while you flip flags.

Contract: [../../manifest/DOM.md](../../manifest/DOM.md). Requires SkyrimNet_SexLab’s overlay.

## What it does

- Converts most DOM activity into Direct Narration or SkyrimNet events
  - DOM does not expose everything as events; Ext2 is off unless you enable it — see [../authors/events.md](../authors/events.md)
- SkyrimNet YAML actions for common slave orders (`SKSE/Plugins/SkyrimNet/external/goodprovider.dom/actions/`)
  - Social (`Be_`): flatter, insult, praise-tell, promises, scold, refuse
  - `Act*` (silent / respectful / maid), Poses, FightForMe, chores/entertain, movement/posture, drink
  - Dress / Undress
  - Sex (2P penis / no_penis, 3P) / masturbate / stop-masturbate / refuse (via SkyrimNet_SexLab scene helpers)
  - Punish (+ refused / other → punishment reasons)
- Character bio prompts for DOM actors (slaves, slavers, and others — appearance, bondages, skills, aged notifications, and more)
- Punishment reason mapping (`SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json`)
- Item descriptions for DOM ropes (`config/items/`)
- Healing Hands trigger — cleanup / comfort Direct Narration when healing is cast

## Notes / FAQ

### Actions or prompts missing after updating SkyrimNet

Confirm SkyrimNet is 0.25.0 or later, then check **Plugins > Installed Plugins** for `goodprovider.dom` with an **External** badge. Files left in the old `prompts/` or `config/actions/` folders are ignored. **Plugins > Import Old Content** is for personal tweaks, not this mod — an imported copy hides later updates.

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
