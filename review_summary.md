# SkyrimNet_DOM Review Summary (Pass 8)

Companions: `review-checkpoint.xml`, `review_execution-plan.xml`.

**Status: applied** — Pass 8 fixes per user answers. Recompile Events, API, Actions, Decorators.

## Applied

| ID | Fix |
|----|-----|
| C1 | `DOMSlave_Sex_Two_Fucking` / `DOMSlave_Sex_Two_Giving` (SexLab sex2 Fucking/Giving model) |
| I1 | `SexLab_AnimationEnd` → `GetActorsFinishedWithScene` + orgasm restore |
| I2 | `AddPunishmentReason` guards `slave` / `mind` / `slaveActor` |
| I3 | `Be_FlatteredSexy` `required: true` |
| I5 | `GetThreads` checks actor before `IsBusy` |
| I6 | `Be_Refused` param `rejector` |
| M1 | `StopScene_Masturbate` guards `d_keys` |
| M2 | FightForMe description `Ordered` |
| M3 | Decorators Trace labels |
| I5b | `Register_Events` guards `player` / `main` / `main.d_core` (Pass 8 follow-up) |

## Wontfix

| ID | Reason |
|----|--------|
| I4 | Dress/Undress stay without scene-lock / SexLabAnimatingFaction (fast actions); faction stuck-state fixed by I1 |

## Sex_Two split

- Fucking: methods `pussy|mouth|ass`, direction `fucking|fucked in`, `setting_name` empty
- Giving: SexLab giving methods, direction `getting|giving`, `setting_name: no_penis`

## Rules unchanged

Diary Of Mine immutable. DOM Actions always `superior`; SexLab never.
