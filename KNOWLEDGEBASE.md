# Knowledgebase

Master reference for quirks, gotchas, and cross-version differences discovered while working on SkyrimNet_DOM (and shared Skyrim/Papyrus pitfalls).

**Standing rule:** consult this file before changes; after debugging or research sessions, append new facts here.

For agent policy (safety, confidence), see [AGENTS.md](AGENTS.md). For protocol contracts, see [docs/reference/](docs/reference/).

## DOM-specific

| Fact | Notes |
|------|-------|
| DOM owns arousal | SLSO and other arousal mods do not drive DOM’s `arousal_factor`. See [docs/players/overview.md](docs/players/overview.md). |
| Ext2 not registered by default | Many DOM Ext2 ModEvents exist in `SkyrimNet_DOM_Events` but `SetSendExternalEventsExt2` is off — spam control. See [docs/authors/events.md](docs/authors/events.md). |
| Ext3 required for NotificationSent | `DOMOnNotificationSent` is Ext3-gated in DOM Core. Events must call `SetSendExternalEventsExt3(true)` or melt/orgasm HUD still shows while SkyrimNet never gets the ModEvent. Prefer notifications over `DOMOnOrgasm` (faster; leave Orgasm unregistered to avoid double `DOMSlave_Orgasmed`). |
| Actor lock key | Scene eligibility uses StorageUtil `skyrimnet_sexlab_scene_actor_lock` (shared with SkyrimNet_SexLab). |

## Dom melt without DirectNarration (2026-07-27)

**Symptom**: Papyrus shows `IsOrgasmingAfterArousal` + widget `… brain melts … orgasm` for a Dom slave (e.g. Toy), but SexLab DN is Bob-only (`Bob is orgasming`) or denies the slave (`… was denied an orgasm`) — no `" is orgasming."` for the Dom actor.

**Cause**: `SendExternalEventSSBS("NotificationSent", …)` early-returns when Ext3 is off. `OnNotificationSent` never runs → `Handler_DOM.DOMSlave_Orgasmed` / `OrgasmCustom` never feed custom orgasm text. SexLab Combined skips Dom fill and may treat `orgasm_expected[slave]=0` as deny.

**Fix**: Enable Ext3 in `Register_Events`; keep `DOMOnOrgasm` commented.

## Shared engine gotchas

See the short list in [AGENTS.md](AGENTS.md). Expand here when a session proves a SE/VR or Papyrus quirk for this project.
