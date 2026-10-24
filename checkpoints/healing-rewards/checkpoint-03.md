# Healing rewards — checkpoint 03

Previous: [checkpoint-02.md](checkpoint-02.md). Repos: SkyrimNet_DOM `webui`, SkyrimNet_SexLab `profile`.

## Result
The user verified the checkpoint-02 fix in game: a SexLab Aid heal opens the "praise X for" list with "being a good slave", the queued reasons, and custom.

## Commits (this session)
- SkyrimNet_DOM: all pending healing-rewards work (Events/Menu/Main + `.pex`, manifest `dom.praise.heal_choose_reason` now defaults on, docs, KB, changelogs, checkpoints).
- SkyrimNet_SexLab: only the Aid/choice-list hunks (`Aid.cpp` `NotifyAidStart`, `index.html` solo choice list `opensText`, `orgasm-engine.md`, `webui.md`, `CHANGELOG-developer.md`). The rest of that tree stays unstaged: HUD narration `callerNarrates`, the animation filter row, and the DLL.

## Still open
- The ESL caster FormID round trip (`as Int` → `Game.GetFormEx`) is untested.
- The checkpoint-01 Aid tests the user did not report on: the potion accept/refuse path, a channel praising once, a follower using LLM `SexLab_Aid`, a shocked slave getting care, a stamina-only Aid doing nothing, and a Healing Hands cast still firing once.
- The SexLab DLL is not committed. It ships with the next SexLab commit that covers the rest of the tree.
