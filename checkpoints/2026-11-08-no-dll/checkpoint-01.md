# Checkpoint 01: Error 126 traced to a Debug DLL in the release; hotfix built, not published

Repo: `SkyrimNet_DOM` · Branch: `main` · Baseline commit: `993911f` · Date: 2026-11-08 · Supersedes [checkpoint-00.md](checkpoint-00.md)

Logs: [logs/2026-11-08-11-13-55/](logs/2026-11-08-11-13-55/) (the player's `Papyrus.0.log`, `SkyrimNet (1).log`, `MANIFEST.txt`).

## Goal

A player gets SKSE `couldn't load plugin ... SkyrimNet_DOM.dll (Error 126)`. Find out whether their Claude's Debug-build diagnosis is right, whether a new requirement is needed, and get them a working DLL.

## Status

Hotfix zip built and checked locally. **Not published:** the auto-mode permission classifier denied `gh release upload` (Create Public Surface). Not run on the player's machine. Nothing is committed.

## Findings

- The diagnosis is correct. PE import tables:
  - `0.2.1` zip / git HEAD DLL (2,921,472 bytes): `MSVCP140D`, `VCRUNTIME140D`, `VCRUNTIME140_1D`, `ucrtbased`.
  - Working-tree DLL (934,400 bytes, SHA256 `70823E3C586F73528259FE996E361C6AB01EED8B11067B2FBEC628923A0284EA`): only `KERNEL32`, `ole32`, `VERSION`, `USER32`, `SHELL32`.
- `versions/SkyrimNet_DOM 0.2.0.zip` holds a DLL of the same 2,921,472 bytes. Imports of that copy were not parsed.
- **No requirement needed.** The Release build uses the static CRT, so it needs no VC++ Redistributable. The Debug runtime ships only with Visual Studio.
- [Papyrus.0.log:42655](logs/2026-11-08-11-13-55/Papyrus.0.log): `SkyrimNet_DOM.dll missing, gestures off`.
- [SkyrimNet (1).log:15](<logs/2026-11-08-11-13-55/SkyrimNet (1).log>): player is on Skyrim 1.5.97.
- [Papyrus.0.log:42679](logs/2026-11-08-11-13-55/Papyrus.0.log): `Diary of Mine 8.5.5` (`Plugin version is: 8.050600` on the next line). Unreleased work requires 8.5.6d, which is why this is a DLL-only hotfix.
- The DLL drops into 0.2.1: `SkyrimNet_DOM_Native.psc` and `Bridge.cpp` are unchanged from HEAD. It reports itself as `v0-2-0-0` because `SKSE_Source/CMakeLists.txt` still says 0.2.0; Papyrus only tests `GetPluginVersion > 0`.

## What changed

1. `versions/SkyrimNet_DOM 0.2.1 DLL hotfix.zip` (gitignored): one file, `SKSE/Plugins/SkyrimNet_DOM.dll`.
2. [python_scripts/check_release_dll.py](../../python_scripts/check_release_dll.py), new: fails on Debug runtime names.
3. [Makefile](../../Makefile): `release: check_dll`.
4. [release-guide.xml](../../release-guide.xml), the three changelogs, [KNOWLEDGEBASE.md](../../KNOWLEDGEBASE.md).

## Verified

- Check passes on the working-tree DLL and the DLL extracted from the hotfix zip; exits 1 on the Debug DLL from git HEAD.
- Hotfix DLL hash matches the working-tree DLL.
- `make check_dll` passes; `make -n release` runs it first.
- Release DLL loaded on AE 1.6.1170 (`checkpoints/2016-11-07-errors/logs/2026-11-07-23-08-29/SkyrimNet_DOM.log`).

## Not yet tested

- This Release DLL on SE 1.5.97.
- Git HEAD still holds the Debug DLL until the working tree is committed.

## Next

1. Maintainer: send the hotfix zip to the player, or run `gh release upload 0.2.1 "versions/SkyrimNet_DOM 0.2.1 DLL hotfix.zip" --repo GoodProvider/SkyrimNet_DOM`. Nexus upload is manual.
2. Player: install it, then confirm `SkyrimNet_DOM.log` appears in the SKSE log folder and Papyrus no longer logs `SkyrimNet_DOM.dll missing`.
3. Commit the Release DLL with the next release so git HEAD stops carrying the Debug build.

## Reply for the player

> Your diagnosis was right: 0.2.1 shipped a Debug build of SkyrimNet_DOM.dll by mistake. Here's a Release build that doesn't need Visual Studio or the VC++ Redistributable. Install the zip as a mod after SkyrimNet DOM so it overwrites the old DLL. It's a single file and works with your current 0.2.1 install. It hasn't been tested on 1.5.97 yet, so if it still fails, please send me your skse64.log and SkyrimNet_DOM.log.
