https://github.com/GoodProvider/SkyrimNet_DOM/releases/tag/0.2.0

Requires SkyrimNet 0.25.0+ (Beta 25) and SkyrimNet_SexLab 0.36.5+. Torture and heal features need Injury Engine.

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
