# SkyrimNet_DOM Review Summary (Pass 7)

Companions: `review-checkpoint.xml`, `review_execution-plan.xml`.

**Status: applied** — Pass 7 fixes per user answers. Recompile Actions + Events.

## Applied

| ID | Fix |
|----|-----|
| C1 | Actor lock → `skyrimnet_sexlab_scene_actor_lock` |
| C2 | `DOMSlave_Sex_One` / `Sex_Two` / `Sex_Three` |
| C3 | Removed unused `Actor third`; YAML↔PSC positional match |
| I1 | Nonconsensual_Two target/victim guards |
| I2 | Sex category PARAMS aligned to leaf style/method/direction |
| I3 | Re-enabled `DOMOnMoodChange` |
| I4 | Hug path `return` |
| M1 | 0305 grammar |
| M2 | `DOMSlave_Undress` → `UndressDress_Execute` → `SetShouldBeNaked`; description `undress` |
| M3 | Consensual_Three Trace labels |

## Undress wiring

- YAML: `executionFunctionName: UndressDress_Execute`, description `undress` (no “commanded by [Superior]”)
- PSC: `UndressDress_Execute(Actor speaker, Actor superior)` → PAH `DOM_Actor.SetShouldBeNaked(superior)`

## Rules unchanged

Diary Of Mine immutable. DOM Actions always `superior`; SexLab never.
