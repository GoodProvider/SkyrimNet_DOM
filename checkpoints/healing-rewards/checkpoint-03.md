# Healing rewards — checkpoint 03

Previous: [checkpoint-02.md](checkpoint-02.md). Repos: SkyrimNet_DOM `webui`, SkyrimNet_SexLab `profile`.

## Result
The user verified the checkpoint-02 fix in game: a SexLab Aid heal opens the "praise X for" list with "being a good slave", the queued reasons, and custom.

## Commits (this session)
- SkyrimNet_DOM: all pending healing-rewards work (Events/Menu/Main + `.pex`, manifest `dom.praise.heal_choose_reason` now defaults on, docs, KB, changelogs, checkpoints).
- SkyrimNet_SexLab `23f29f22`: only the Aid event hunks (`Aid.cpp` `NotifyAidStart` + 2 call sites, the `orgasm-engine.md` ModEvents row, the `CHANGELOG-developer.md` "Aid mod event" entry). This was staged as a filtered patch. The rest of that tree stays uncommitted, including HUD narration `callerNarrates`, the animation filter row, the DLL, and the already staged `0160_platonic.json` deletion, which was left as it was.

## Not committed: SexLab `Choice_Open`
The choice list is uncommitted in SexLab, and DOM's torture-reason and heal-praise lists depend on it. It spans the `Papyrus_WebUI.cpp/.h` native, `SkyrimNet_SexLab_WebUI.psc`/`.pex`, `index.html` (`#choice-panel` CSS/HTML, Esc handling, the `configureChoice`/`openChoiceSolo`/`choiceText*` JS), and the `webui.md` Choice_Open line. The `opensText` hunks can't be split from it, so it needs its own SexLab commit as one feature.

## Still open
- The ESL caster FormID round trip (`as Int` → `Game.GetFormEx`) is untested.
- The checkpoint-01 Aid tests the user did not report on: the potion accept/refuse path, a channel praising once, a follower using LLM `SexLab_Aid`, a shocked slave getting care, a stamina-only Aid doing nothing, and a Healing Hands cast still firing once.
- The SexLab DLL is not committed. It ships with the next SexLab commit that covers the rest of the tree.
