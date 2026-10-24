# Punishment reasons

End-to-end mapping from LLM/YAML reason strings to Diary of Mine punishment indexes.

See also: [actions.md](actions.md) · [prompts.md](prompts.md) · [../developers/papyrus.md](../developers/papyrus.md)

## Pipeline

1. **DOM indexes** — `Data/SKSE/Plugins/StorageUtilData/Diary Of Mine/PunishmentReasons.json` loaded at Setup into `punishment_to_index` ([`SkyrimNet_DOM_Main.psc`](../../Scripts/Source/SkyrimNet_DOM_Main.psc)).
2. **SkyrimNet map** — [`SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json`](../../SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json) registers each `reason` (and each `alias`) → `index` + narration `description`.
3. **YAML / Papyrus** — refuse / punish-other / some scene fails call `SkyrimNet_DOM_Actions.AddPunishmentReason` → `SkyrimNet_DOM_API.AddPunishmentReason`.
4. **DOM** — `slave.mind.AddNextPunishmentReason(index)`.
5. **SkyrimNet** — `RegisterEvent("Reason to Punish", msg, slave, superior)` (not Direct Narration).

Unknown reason tokens resolve to the default (`"no reason"` / index 0). Check the Papyrus log for `unknown reason token`.

## Injury Engine torture

Injury Engine torture of a DOM slave is a DOM pain punishment (`SkyrimNet_DOM_Events.OnInjuryTorture`, mod event `Injury_Engine_Torture`). The reason is picked once per DOM punishment, even when DOM started it from a weapon hit. It comes from the first source that applies:

1. **SexLab Punish panel**: the panel lists the slave's open reasons as `"<slave>" + description + "<owner>"` (`PanelPunishReasons`). A DOM text picked there is used. A SexLab strategy or request reason becomes `didnt obey`; anything else becomes `being a bad slave`.
2. **Player, setting `dom.punish.torture_choose_reason` on**: a WebUI list: "random", `being a bad slave` and `didnt obey` (always listed, for what the LLM missed), the other open reasons, "custom" (UIExtensions text box; the text is the event reason, the DOM index is `being a bad slave`) and "no reason" (DOM index 0). Until a pick, the punishment carries a random open reason. Closing the list, or an empty custom, keeps it and sends no event.
3. **Otherwise**: a random open reason; `being a bad slave` when there are none (`DOM_Mind.GetNextPunishmentReason`).

Then `SkyrimNet_DOM_API.ApplyTortureReason` names it on the punishment and sends `RegisterEvent("dom_torture_punish", "<torturer> is punishing <slave> because <she|he>" + description + "<torturer>.")`. A reason without a `description` reads "… because of <reason>." The pronoun comes from the slave's sex.

## JSON entry shape

From [`punishment_reason.json`](../../SKSE/Plugins/SkyrimNet_DOM/punishment_reason.json) (full file is source of truth):

```json
{
  "reason": "refusing to have sex",
  "aliases": ["refused sex"],
  "index": 12,
  "description": " refused to have sex with "
}
```

| Field | Role |
|-------|------|
| `reason` | Canonical token the LLM / YAML should prefer |
| `aliases` | Alternate strings that map to the same `index` |
| `index` | Must match DOM’s punishment list index |
| `description` | Middle of narration: `slaveName` + `description` + `superiorName` + … |

Empty/missing description falls back to a generic “refused to obey … command to \<reason\>” sentence in the API.

## Helper prompt

[`dom_punishment_reason.prompt`](../../SKSE/Plugins/SkyrimNet/external/goodprovider.dom/prompts/helpers/dom_punishment_reason.prompt) is a pipe-separated allowlist for the LLM. Keep it in sync when you add or rename reasons the model must choose.

## YAML entry points

| Action | Role |
|--------|------|
| `DOMSlave_Refused.yaml` / sex refused | Passes `reason` into `AddPunishmentReason` |
| `DOMSlave_AddPunishmentReason.yaml` | Free-form / other reasons |
| Scene helpers | May inject fixed reasons (e.g. `didnt obey`, `didnt listen`) |

Parameter names must match Papyrus (`reason`, `rejector`, `superior`). Stay within the [8-parameter YAML limit](actions.md).

## Checklist: add a reason

1. Confirm the reason exists (or will exist) in DOM’s `PunishmentReasons.json` and note its **index**.
2. Add an object to `punishment_reason.json` with matching `index`, clear `reason`, optional `aliases`, and a `description` that reads well after the slave’s name.
3. Append the canonical token (and any aliases you want the LLM to use) to `dom_punishment_reason.prompt`.
4. Point refuse / other YAML `description` or `parameterMapping` at the new token if needed.
5. In-game: trigger refuse/other, confirm log shows the resolved index and a `Reason to Punish` event — not a silent `"no reason"` fallback.

YAML-only changes are not enough without a valid index and JSON registration.

## Tips

- Prefer aliases over inventing a second index for the same DOM reason.
- Index conflicts (same name, different index) are traced at load — fix the JSON, don’t ignore the log.
- Bio / decorator fields expose next/current reason names for prompts; they read DOM state, not the helper allowlist.
