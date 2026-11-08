# Requirements

## Required

- Diary of Mine (`DiaryOfMine.esm`) **8.5.6d or later**. Older versions don't have the bath, shower and breast-pose functions this mod calls. 8.5.6d is the only version tested against.
- SkyrimNet **0.25.0+** (Beta 25). This mod ships LLM content as plugin `goodprovider.dom` under `Data/SKSE/Plugins/SkyrimNet/external/`. Older SkyrimNet builds that only read `prompts/` and `config/actions/` will not load those files.
- SkyrimNet_SexLab
- Magelight UI 0.30.1+, the UI host for SkyrimNet_SexLab's overlay (needs SkyrimNet_SexLab newer than 0.36.6)

## Skyrim VR

DOM's menus live in SkyrimNet_SexLab's overlay, so on VR they open the way SexLab's menu does: with SexLab's hotkey enabled, **Grip + A** opens or closes it (SexLab's **VR menu button** settings; needs the SexLab build that adds them). Point with the laser; B / Y closes. `SkyrimNet_DOM.dll` loads on SE, AE and VR. Not yet tested in a headset.

## Optional

- SkyrimNetUDNG — device grouping when present

## Notes

- Put load order so Diary of Mine, SkyrimNet, and SkyrimNet_SexLab are available before this mod’s scripts run.
- Sex / punish / masturbate YAML executes through SkyrimNet_SexLab scene helpers — that mod must be working (Actions refresh if needed; see SexLab player FAQ).

## Related

- Player overview: [overview.md](overview.md)
- SexLab requirements (sibling): [../SkyrimNet_SexLab/docs/players/requirements.md](../../../SkyrimNet_SexLab/docs/players/requirements.md)
