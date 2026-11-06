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
| `signal configRead(values, trigger, errors)` | Uma por leitura terminada; `errors` é o `configerrors`, sem as linhas vazias. Leitura que não veio inteira não emite nada (nada é comparado) |
| `signal configWriteDone(ok, error)` | Uma por `setConfigValues` terminado; `error` é o que o compositor disse. A 1C usa pra voltar ao real e dizer no card (FR-002) |
| `shortcuts` / `shortcutModifier` | Lista `{ id, keys, usesMod }`; o modificador, ou `""` se o compositor não disse |
| `keyboardLayoutsNote` | **Sai.** A linha some, no lugar da nota (FR-045) |

## `HyprlandBackend.qml`

- `monitors` guarda `width`, `height` e `refreshRate`, em px físicos e Hz (FR-023).
- `readConfig`: `hyprctl --batch` com `j/getoption` das 4 opções e `j/configerrors`, um pedido só, e uma leitura pedida no meio roda
  depois, com o gatilho mais forte (P4). `[[EMPTY]]` vira `""`; o `configerrors -j` sem erro é `[""]` (P9, `sondagem.md`).
- `configreloaded` chama `readConfig("reload")`, que espera 300 ms antes de ler (entrou por causa da trava de `sondagem.md`, contra a qual não tem benefício mostrado); `Component.onCompleted`,
  `readConfig("start")`.
- `setConfigValues`: um `eval` de `hl.config({ input = { … } })`. Inteiros validados; `kb_options` e `kb_layout` só com
  `^[a-z0-9_:,]*$`, porque entram no comando, como `setKeyboardLayouts` já faz. Saída que não começa com `ok` é erro. Vale o último pedido,
  e nunca roda no meio de uma leitura que compara: o que ela acha tem que ser o valor do arquivo.
- A leitura `mismatch → reaplica` dentro de `layoutQuery` **sai** (1C): quem decide reaplicar é o `FileWins`.

## `NullBackend.qml`

Todas as capacidades acima falsas, `sessionId: ""`, `readConfig` não faz nada, `setConfigValues` responde `error: no compositor`.
Os valores salvos ficam guardados: nada é comparado nem esquecido sem compositor.
