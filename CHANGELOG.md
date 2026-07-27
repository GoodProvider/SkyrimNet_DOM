# Updates since 0.0.3

- Split two-person consensual sex into `DOMSlave_Sex_Two_Fucking` (penis) and `DOMSlave_Sex_Two_Giving` (`no_penis`); removed monolithic `DOMSlave_sex_start_2`
- Dropped `style` from punish and three-person sex YAML/Papyrus quest args to stay within SkyrimNet’s 8-parameter limit (2P sex still maps `style`)
- Fixed eligibility lock key to `skyrimnet_sexlab_scene_actor_lock` on Be/Pose/FightForMe/punish/sex category actions
- Tightened `Be_FlatteredSexy` eligibility (`required: true`); `Be_Refused` uses `rejector`
- Hardened null checks for punishment reasons, event registration, and masturbate stop/threads
- Animation-end cleanup now routes through `GetActorsFinishedWithScene` (incl. SexLab clear-animating)
- Moved author docs to `guides/`; README/AGENTS updated
- Release zip includes full `SKSE/` again (0.0.3 was scripts-only)
