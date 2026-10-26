https://github.com/GoodProvider/SkyrimNet_DOM/releases/tag/0.2.1

Requires SkyrimNet 0.25.0 (Beta 25) or later and SkyrimNet_SexLab 0.36.5 or later.

## 0.2.1

### Items
- Item YAMLs ship in the content plugin: `external/goodprovider.dom/items/diaryofmine-esm_EB8659.yaml` and `diaryofmine-esm_BB1B47.yaml`; `config/items/` copies removed
- DOM Training Info uses `show_in_prompts: false` (was `enabled: false`, which items refuse) and is now hidden from NPC equipment in prompts

### Bug Fixes
- Fixed: a Leash Framework holder leash on a DOM slave makes DOM follow the holder (`SkyrimNet_DOM_Events.OnLeashFrameworkLeash`, `SyncLeashFollow`)

### Install
- A legacy file SkyrimNet migrated into `overlay/items/` overrides the plugin record; users must delete it
- The leash fix needs the matching SkyrimNet_Leashed update

### Build
- Manifests at 0.2.1; the release zip no longer includes the 32 MB `SkyrimNet_DOM.pdb`

## 0.2.0

### Poses and gestures
- Slave poses and gestures are sent to the AI through a new SKSE hook and `dom.events.*` settings

### Torture counts as punishment
- Injury Engine torture of a slave is a DOM pain punishment (`Injury_Engine_Torture`) and trains them
- The player picks the reason (`dom.punish.torture_choose_reason`); the Punish panel lists DOM reasons
- SkyrimNet is told why through the `dom_torture_punish` event

### Healing counts as praise
- Healing Hands and SexLab Aid (`SkyrimNet_SexLab_AidStart`) praise the slave; a shocked slave gets care
- The reason list is `dom.praise.heal_choose_reason`

### Bug Fixes
- Fixed: LLM-ordered actions were always refused after DOM's `WillObey` gained a sixth argument
- Fixed: pain punishments stuck; they now end after 20 s idle (`EndWhipping`)
- Removed the Healing Hands `hit` trigger

### WebUI
- DOM TargetMenu entries `08xx_dom_*` and the **DOM Info** MainPanel `0850_dom_info.json`
- `dom.info.show_enjoyment` adds the orgasm-meter inputs

## 0.1.0

https://github.com/GoodProvider/SkyrimNet_DOM/releases/tag/0.1.0

Requires SkyrimNet 0.25.0 (Beta 25) or later. LLM actions and prompts install as plugin `goodprovider.dom` (External on the Plugins page). Do not use Plugins > Import Old Content for this mod's files.

- Actions, prompts, and Healing Hands now live in the SkyrimNet plugin folder. Files left in the old `prompts/` or `config/actions/` places are ignored.
- Tune Ext2 spam, notification history size, and short-lived event lifetime in the SkyrimNet dashboard (`dom.events.*`).
- Newly captured slaves get Direct Narration when they are assigned, instead of waiting for a late “just captured” mood.
- Slave melt/climax text still drives orgasm narration; the “squirms as your orgasm” tease no longer counts as the slave climaxing.
- Masturbating DOM slaves show up in SexLab activity prompts even when the game is paused.
