# SkyrimNet_DOM

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/goodprovider) 

SkyrimNet support for Diary of Mine.

# (Alpha) SkyrimNet_DOM
Basic SkyrimNet support for Diary of Mine. 
This is in a very rough state.
https://github.com/GoodProvider/SkyrimNet_DOM/releases
# Features 
- converts most of the DOM Events into directNarration or events 
    - DOM doesn't currently translate everything it does into events 
- Captures many dom activies as Actions 
    - full list here SKSE/Plugins/SkyrimNet_DOM/actions.json
- contains item descripts for the ropes
    - if you make more diaryofmind descriptions, please give them to me
- contains Healing Hands Trigger
    - Used to clean up all the blood, when its time for comfort
    - Cast healing (she thanks me) 
    - dialogue "\*Bring in for a warm hug\* You understand, this was your fault \*She fears, but doesn't want to believe, he may be right\*"
- Supports whip, fire, ice, and spark torture/punishment via Injury Engine and SkyrimNet-Sexlab

# Required
- SkyrimNet (dependencies)
- SkyrimNet Sexlab (dependencies) 
- Injury Engine (dependencies) 

# Recommanded
- SkyrimNet Leashed

- **Players:** [docs/players/overview.md](docs/players/overview.md) · [requirements](docs/players/requirements.md)
- **Authors:** [actions](docs/authors/actions.md) · [prompts](docs/authors/prompts.md) · [events](docs/authors/events.md) · [punishment](docs/authors/punishment.md) · [content](docs/authors/content.md)
- **Developers:** [papyrus](docs/developers/papyrus.md)
- **Agents:** [AGENTS.md](AGENTS.md) · [llms.txt](llms.txt) · [release-guide.xml](release-guide.xml)
- **Changelog:** [CHANGELOG.md](CHANGELOG.md) · [CHANGELOG-player.md](CHANGELOG-player.md) · [CHANGELOG-developer.md](CHANGELOG-developer.md)

## Quick start

1. Install requirements ([docs/players/requirements.md](docs/players/requirements.md)). SkyrimNet **0.25.0+**.
2. Enable SkyrimNet narration; keep Diary of Mine + SkyrimNet_SexLab loaded.
3. See player notes for arousal, spam, and obedience quirks ([docs/players/overview.md](docs/players/overview.md)).

## Extending

| Task | Doc |
|------|-----|
| New / edit YAML actions | [docs/authors/actions.md](docs/authors/actions.md) |
| Prompts / `dom_actor` | [docs/authors/prompts.md](docs/authors/prompts.md), [docs/reference/json-keys.md](docs/reference/json-keys.md) |
| Punishment reasons | [docs/authors/punishment.md](docs/authors/punishment.md) |
| Events / DN | [docs/authors/events.md](docs/authors/events.md) |
| Items | [docs/authors/content.md](docs/authors/content.md) |
| Papyrus bridge | [docs/developers/papyrus.md](docs/developers/papyrus.md), [docs/reference/papyrus-rules.md](docs/reference/papyrus-rules.md) |
