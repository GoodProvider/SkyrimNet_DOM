## Unreleased

- Fixed: a slave the AI had agreed to have sex (or follow another order) kept refusing. When the AI decides the slave obeys, the slave now obeys. Orders you give from the menu still check the slave's obedience.
- Torturing a slave with Injury Engine (whip, hands, torture spells, the SexLab Punish panel) now counts as a Diary of Mine punishment and trains the slave.
- New dashboard setting "When player tortures let player choose" (on by default). When you start torturing a slave, a list of the slave's open punishment reasons appears. Pick one, "random", "no reason", or "custom" to type your own (it trains like "being a bad slave"). "Being a bad slave" and "didnt obey" are always listed, for things the AI missed. With the setting off, a reason is chosen at random.
- SkyrimNet hears why, for example: "Bob is punishing Nina because she refused to comply with the sexual demands of Bob."
- The SexLab Punish panel lists the slave's Diary of Mine reasons. Punishing for a SexLab reason (a refused request or the slave's own agenda) counts as "didnt obey".
- Casting Healing Hands on a slave praises them. A slave in shock is comforted with care instead (no hug animation plays).
- New dashboard setting "Ask player praise reason when healing" (off by default). When you heal a slave, a list of their praise reasons appears, plus "custom" to type your own. Closing the list gives no praise. "Being a good slave" is always first in the list, and it is the reason used with the setting off.

## 0.1.1

- Healing Hands no longer triggers comfort narration (trigger removed).

## 0.1.0

https://github.com/GoodProvider/SkyrimNet_DOM/releases/tag/0.1.0

Requires SkyrimNet 0.25.0 (Beta 25) or later. LLM actions and prompts install as plugin `goodprovider.dom` (External on the Plugins page). Do not use Plugins > Import Old Content for this mod's files.

- Actions, prompts, and Healing Hands now live in the SkyrimNet plugin folder. Files left in the old `prompts/` or `config/actions/` places are ignored.
- Tune Ext2 spam, notification history size, and short-lived event lifetime in the SkyrimNet dashboard (`dom.events.*`).
- Newly captured slaves get Direct Narration when they are assigned, instead of waiting for a late “just captured” mood.
- Slave melt/climax text still drives orgasm narration; the “squirms as your orgasm” tease no longer counts as the slave climaxing.
- Masturbating DOM slaves show up in SexLab activity prompts even when the game is paused.
