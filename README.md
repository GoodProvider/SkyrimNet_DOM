# (Alpha) SkyrimNet_DOM

Basic SkyrimNet support for Diary of Mine. This is in a very rough state.

# Features

- Converts most DOM activity into Direct Narration or SkyrimNet events
  - DOM does not expose everything it does as events; not every Ext2 path is registered here
- SkyrimNet YAML actions for common slave orders (`SKSE/Plugins/SkyrimNet/config/actions/DOMSlave_*.yaml`)
  - Social (`Be_`): flatter, insult, praise-tell, promises, scold, refuse
  - `Act*` (silent / respectful / maid), Poses, FightForMe, chores/entertain, movement/posture, drink
  - Dress / Undress
  - Sex (2P penis / no_penis, 3P) / masturbate / stop-masturbate / refuse (via SkyrimNet_SexLab scene helpers)
  - Punish (+ refused / other → punishment reasons)
- Character bio prompts for DOM slaves (appearance, bondages, skills, aged notifications, and more)
- Punishment reason mapping (`SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json`) for refuse / punish-other flows
- Item descriptions for DOM ropes
  - If you write more Diary of Mine item descriptions, please share them
- Healing Hands trigger
  - Used to clean up blood when it is time for comfort
  - Cast healing (she thanks me)
  - Example dialogue: `*Bring in for a warm hug* You understand, this was your fault *She fears, but doesn't want to believe, he may be right*`

# Required

- Diary of Mine (`DiaryOfMine.esm`)
- SkyrimNet
- SkyrimNet_SexLab

Optional: SkyrimNetUDNG (device grouping when present).

# Notes

- DOM has its own arousal system
  - Arousal-changing mods are ignored for DOM arousal
  - This includes SLSO; it does not really change DOM's arousal
- DOM is very spammy — it emits far more events than we can send to the LLM
  - They will be in history, but you should use Direct Narration or dialogue to give context
- DOM has its own obedience logic, so the LLM will sometimes say yes while DOM says no. Roll with it.
- Occasional Direct Narration helps frame events to match the story you want

# Guides

- **[Actions](guides/Actions.md)** — Edit or add `DOMSlave_*.yaml` actions: eligibility, `parameterMapping`, DOM_Keys vs `SkyrimNet_DOM_Actions` (SkyrimNet hard limit: 8 YAML parameters).
- **[Prompts](guides/Prompts.md)** — Edit character_bio (shared namespace) and user_final_instructions (isolated namespaces); how `dom_actor` loads.
- **[Events](guides/Events.md)** — DOM → Direct Narration / notifications / `RegisterEvent`; paused actor JSON side effect.
- **[Punishment](guides/Punishment.md)** — Add or alias punishment reasons (`punishment_reason.json` + helper + DOM indexes).
- **[Content](guides/Content.md)** — Item descriptions and triggers (e.g. Healing Hands).
- **[Code](guides/Code.md)** — Papyrus bridge layout under `Scripts/Source`, events/actions/API/decorators, compile via `skyrimse.ppj`.
- **[Updates](CHANGELOG.md)** — What changed since 0.0.3.
