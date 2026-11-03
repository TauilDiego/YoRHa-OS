# Contrato: o adaptador (acréscimos)

Soma-se a `specs/007-menu-de-pausa/contracts/compositor.md`. Tudo que depende do compositor (FR-044) entra por aqui.

## Capacidades novas do backend

| Capacidade | Hyprland | `none` | Usada por |
|---|---|---|---|
| `keyboardLayouts` | sim | não | Layouts |
| `keyboardOptions` | sim | não | Caps Lock, Repeat delay, Repeat rate |
| `monitorInfo` | sim | não | Resolution, Refresh rate, Scale |
| `shortcutsList` | sim | não | Shortcuts |
| `configFile` | sim | não | `FileWins` |

Etapas 2 e 3 acrescentam `monitorSet`, `cursorSize` e `lidSwitch`.

## Fachada (`Compositor.qml`)

| Membro | Regra |
|---|---|
| `supports(cap): bool` | Capacidade do backend real. Com o domínio `input`, as de teclado são verdadeiras; com `monitors`, `monitorInfo` |
| `focusedMonitorInfo` | `{ name, width, height, refreshRate, scale }` ou `null`; segue o foco. Do fixture `monitors`, se houver |
| `sessionId` | Do backend; `""` no `none` |
| `configValues` | Última leitura: `{ repeatDelay, repeatRate, kbOptions, kbLayout }` |
| `readConfig(trigger)` | Pede uma leitura; `trigger` é `start`, `reload` ou `poll` |
| `setConfigValues(map): string` | `"ok"` ou `"error: …"`; só as chaves do mapa |
| `signal configRead(values, trigger, errors)` | Uma por leitura terminada; `errors` é o `configerrors` |
| `shortcuts` / `shortcutModifier` | Lista `{ id, keys, usesMod }`; o modificador, ou `""` se o compositor não disse |
| `keyboardLayoutsNote` | **Sai.** A linha some, no lugar da nota (FR-045) |

## `HyprlandBackend.qml`

- `monitors` guarda `width`, `height` e `refreshRate`, em px físicos e Hz (FR-023).
- `readConfig`: `getoption -j` das 4 opções e `configerrors`, numa rodada só, e uma leitura pedida no meio roda depois (P4).
- `configreloaded` chama `readConfig("reload")`; `Component.onCompleted`, `readConfig("start")`.
- `setConfigValues`: um `eval` de `hl.config({ input = { … } })`. Inteiros validados; `kb_options` e `kb_layout` só com
  `^[a-z0-9_:,]*$`, porque entram no comando, como `setKeyboardLayouts` já faz. Saída que não começa com `ok` é erro.
- A leitura `mismatch → reaplica` dentro de `layoutQuery` **sai** (1C): quem decide reaplicar é o `FileWins`.

## `NullBackend.qml`

Todas as capacidades acima falsas, `sessionId: ""`, `readConfig` não faz nada, `setConfigValues` responde `error: no compositor`.
Os valores salvos ficam guardados: nada é comparado nem esquecido sem compositor.
