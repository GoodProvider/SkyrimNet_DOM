https://github.com/GoodProvider/SkyrimNet_DOM/releases/tag/0.2.1

Requires SkyrimNet 0.25.0+ (Beta 25) and SkyrimNet_SexLab 0.36.5+. Torture and heal features need Injury Engine.

## Unreleased

### Skyrim VR
- DOM's menus open on VR with SkyrimNet_SexLab's controller button (Grip + A by default; needs the SexLab update that adds it). Untested in a headset.

### Bug Fixes
- NPC slaves can now act on "stand here", "follow me", and "display yourself" through the AI. These three actions failed to load and logged `Failed to register action` in SkyrimNet.log.

### Baths
- Bath me and bath you are now described as they happen, with a different description at each stage
- From the WebUI, the bath waits for the current line to finish before moving to the next stage
- Baths started from DOM's own menu are described too, for slaves only
- The end of a finished bath is now described
- A slave washing themselves is now described when they start and when they stop, from the WebUI or DOM's spell
- The WebUI shower is no longer refused more often than DOM's spell, and a slave who is busy now shows a message instead of being ordered to wash
- Fixed: during bath me and bath you, the AI could give the slave other orders that moved them out of position
- Fixed: the slave could stay in the washing animation after a bath
- Fixed: the player stayed undressed after bath me

### Diary of Mine 8.5.6d
- Now requires Diary of Mine 8.5.6d or later
- Fixed: shower, bath me, bath you, and Pose > Breasts did nothing in the WebUI
- Showering only works in water; out of water the slave dries off instead, as in DOM's own menu
- Fixed: wash narration was lost with the extended DOM events option on
- Punishment reasons match DOM's again, with new ones for refusing a kiss, refusing a body check, and being a useless trainer
- The AI now knows when a slave is bathing or restrained on duty or in jail

## 0.2.1

### Items
- Diary of Mine item names and descriptions now come with the DOM plugin
- DOM Training Info no longer shows in what NPCs are carrying, so the AI won't mention it

### Bug Fixes
- Fixed: a just-captured slave fought a SkyrimNet_Leashed leash and could not be talked to

### Install
- Needs the matching SkyrimNet_Leashed update for the leash fix
- Delete old `SkyrimNet/config/items/diaryofmine_*.yaml` if still there
- Also delete `SkyrimNet/overlay/items/diaryofmine-esm_*.yaml`; old copies override the new ones
- Smaller download: debug symbols (`.pdb`) are no longer included

## 0.2.0

### Poses and gestures
- The AI now sees and narrates what slaves are visibly doing: kneeling, bowing, gestures
- Tune it in the dashboard: `dom.events.poses`, `gestures`, `gesture_cooldown`

### Torture counts as punishment
- Torturing a slave with Injury Engine (whip, hands, spells, Punish panel) trains them like DOM
- A list of the slave's open punishment reasons appears; pick one, random, none or your own
- With "When player tortures let player choose" off, a reason is picked at random
- SkyrimNet hears why: "Bob is punishing Nina because she refused to comply..."
- The SexLab Punish panel lists the slave's DOM reasons

### Healing counts as praise
- Healing Hands or SexLab Aid on a slave praises them; a slave in shock is comforted instead
- A list of praise reasons appears when you heal; "Being a good slave" is always first
- Turn it off with "Ask player praise reason when healing"

### Bug Fixes
- Fixed: a slave the AI agreed to have sex (or follow an order) kept refusing
- Fixed: a whipping that stopped partway left the punishment stuck with no reason list
- Fixed: Healing Hands no longer triggers comfort narration

### WebUI
- New DOM entries in the SexLab menus: orders, abuse, training, restraints, clothes, management
- New **DOM Info** panel with a slave's profile
- Optional dashboard setting `dom.info.show_enjoyment` shows the slave's enjoyment details
