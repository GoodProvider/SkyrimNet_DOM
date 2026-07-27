# Knowledgebase

Master reference for quirks, gotchas, and cross-version differences discovered while working on SkyrimNet_DOM (and shared Skyrim/Papyrus pitfalls).

**Standing rule:** consult this file before changes; after debugging or research sessions, append new facts here.

For agent policy (safety, confidence), see [AGENTS.md](AGENTS.md). For protocol contracts, see [docs/reference/](docs/reference/).

## DOM-specific

| Fact | Notes |
|------|-------|
| DOM owns arousal | SLSO and other arousal mods do not drive DOM’s `arousal_factor`. See [docs/players/overview.md](docs/players/overview.md). |
| Ext2 not registered by default | Many DOM Ext2 ModEvents exist in `SkyrimNet_DOM_Events` but `SetSendExternalEventsExt2` is off — spam control. See [docs/authors/events.md](docs/authors/events.md). |
| Actor lock key | Scene eligibility uses StorageUtil `skyrimnet_sexlab_scene_actor_lock` (shared with SkyrimNet_SexLab). |

## Shared engine gotchas

See the short list in [AGENTS.md](AGENTS.md). Expand here when a session proves a SE/VR or Papyrus quirk for this project.
