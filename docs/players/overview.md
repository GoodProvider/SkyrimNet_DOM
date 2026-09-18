# Player overview

(Alpha) SkyrimNet_DOM — basic SkyrimNet support for Diary of Mine.

Requirements: [requirements.md](requirements.md). Authoring: [../authors/actions.md](../authors/actions.md). Changelog: [../../CHANGELOG.md](../../CHANGELOG.md).

LLM actions and prompts ship as SkyrimNet plugin `goodprovider.dom` (External on the Plugins page). Requires SkyrimNet 0.25.0+. Tune Ext2 / notification ring / short-lived TTL in the SkyrimNet dashboard (`dom.events.*`), not an in-game MCM.

## In-game WebUI

Open the SkyrimNet SexLab overlay hotkey (`\` by default). There is no separate DOM mode.

- **Target** pulldown: nearby actors plus **All Slaves** (group orders; opens the Slaves roster).
- **Views:** Scene Menu, Animation, **Status** (focused actor stats + respectful/silent/fight/orgasm/task/jail 1–7), **Slaves** (all owned aliases, not nearby-only), Log, Settings. Status and Slaves show a **DOM** superscript. Click a roster row to focus that slave and open Status, even if they are far. All Slaves Status is a group count plus the same order buttons.
- Left **TargetMenu:** SexLab rows plus DOM pulldowns that can be used on the focused actor (order / abuse / training / restrain / clothes, plus management / trainees for trainers, services for NPCs, sack when a burlap sack is under the crosshair). DOM options show a **DOM** badge above the label. Slave-only pulldowns are omitted for non-slaves. Child wheels open as button panels on the right (poses, gag/plug, blindfold, cuffing, live praise reasons). Furniture (chains / post / cage / cross / pillory / wheel) opens a Parameter Panel of named variants from `restrains/{kind}.json` plus random. **Order → Follow** shows **follow** or **follow: tight|close|short|long** from the slave’s current distance; picking a distance starts/sets follow (modes 0–3). **Walking** applies gait as soon as you pick a type (walking / follow on four / follow on hands and knees). **Wait** is a single button. Insult, flatter, threaten, promise, and non-sex comfort are spoken as transformed player dialogue. **Comfort → sex / rape** open SexLab Scene Parameter Panels (comforting transform + mind, then scene). **Punish** is a Parameter Panel (Start plus reason and method); reason always includes **custom** (text panel) and **no reason**. **Sack** shows put-in-bag or open/take from the focused slave’s bag state. Leash lives in SkyrimNet_Leashed. **Restrain** owns all bondage (tie poses, furniture, gag/plug, blindfold, cuffs, untie). **Training → Sex** and **Rape** open SexLab Scene Parameter Panels. Masturbate shows pose buttons when idle, Stop/Harder when already masturbating.
- **During a sex scene** the TargetMenu switches to Scene options (stop / stage / position / animation). DOM still offers **abuse** speech there: live praise, scold, insult, flatter, threaten, promise, and comfort (care / guilt / threat / insult). **Comfort → pain** opens slap face / slap ass / twist nipple / slap breasts / custom and narrates `*{player} comforts {slave} by {gesture}*` (asterisks mark narrative for the LLM). Punish, upkeeping, and comfort sex/rape stay Actor-only.
- TargetMenu execute closes the overlay so DOM packages can run. Status/Slaves and live punish/praise choosers stay open. Each order is Direct Narrated as the player ordering the target (or “the slaves”).

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

### Ordered slaves may refuse

Hotkey orders and DOM YAML commands roll Diary of Mine `DOM_Mind.WillObey` through `SkyrimNet_DOM.dll` **before** the command runs. Refuse is narrated (`{slave} refuses {superior}'s command to {action}.`). Obey is `{slave} obeys {superior}'s command to {action}.`; DOM Ext2 / HUD order text is suppressed for that command. DOM sex orders register an Order event with the same obey sentence (e.g. `have vaginal sex with Bob`), then SexLab StageStart narrates the scene. SexLab overlay sex/rape is not gated.

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
