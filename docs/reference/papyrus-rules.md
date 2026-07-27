# Papyrus rules

Canonical Papyrus language and naming rules for this repo.

## Case

Papyrus is case-insensitive (`aA` == `Aa`). Casing is for human readers only; match `EndFunction` / `EndEvent` to the declaration.

## Arrays vs None

Never compare an array to `None`. Use truthiness (`if a`), which means non-None and non-empty.

```papyrus
String[] a = None
; OK: non-None and non-empty
if a
; Runtime error
if a == None
```

## Naming

| Kind | Rule | Example |
|------|------|---------|
| Constants | `UPPER_SNAKE` | `THIS_IS_A_CONSTANT` |
| Properties / variables | start lowercase; snake or camel | `thisIs_Variable` |
| Functions / Events | start Upper case | `ThisIs_Function` |

## Debug traces

Bridge scripts route through `SkyrimNet_DOM_API.Trace_Helper` → `Debug.Trace` (and optional `Debug.Notification`).

```papyrus
Trace("FunctionName", "--- this is a debug message")
```

Logs:

| Log | Path |
|-----|------|
| Papyrus (primary for this mod) | `Documents\my games\Skyrim Special Edition\Logs\Script\Papyrus.0.log` |
| SkyrimNet (last resort; ask first) | `Documents\my games\Skyrim Special Edition\SKSE\SkyrimNet.log` |

When counting lines for reviews, include commented lines.

## Related

- Protocol value tokens: [protocol-tokens.md](protocol-tokens.md)
- External JSON keys: [json-keys.md](json-keys.md)
- Developer paths / compile: [../developers/papyrus.md](../developers/papyrus.md)
