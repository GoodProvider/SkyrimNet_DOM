# Requirements

## Required

- Diary of Mine (`DiaryOfMine.esm`)
- SkyrimNet **0.25.0+** (Beta 25). This mod ships LLM content as plugin `goodprovider.dom` under `Data/SKSE/Plugins/SkyrimNet/external/`. Older SkyrimNet builds that only read `prompts/` and `config/actions/` will not load those files.
- SkyrimNet_SexLab

## Optional

- SkyrimNetUDNG — device grouping when present

## Notes

- Put load order so Diary of Mine, SkyrimNet, and SkyrimNet_SexLab are available before this mod’s scripts run.
- Sex / punish / masturbate YAML executes through SkyrimNet_SexLab scene helpers — that mod must be working (Actions refresh if needed; see SexLab player FAQ).

## Related

- Player overview: [overview.md](overview.md)
- SexLab requirements (sibling): [../SkyrimNet_SexLab/docs/players/requirements.md](../../../SkyrimNet_SexLab/docs/players/requirements.md)
