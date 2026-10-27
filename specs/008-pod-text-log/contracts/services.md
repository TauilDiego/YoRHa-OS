# Contrato: serviços (008)

As regras da 001 continuam: a UI lê dados só dos serviços; uma leitura que falha nunca lança erro na
UI; só o `Compositor` fala com o Hyprland. Entidades em [../data-model.md](../data-model.md).

## Novos (`shell/services/`, singletons, no `qmldir`)

### `NotifyPrefs` — as opções (FR-039, FR-040, FR-043)

| Membro | Tipo | Notas |
|---|---|---|
| `dnd`, `position`, `osdPosition`, `voice`, `log`, `logSize`, `monitor`, `onScreen`, `duration`, `typing`, `fullscreen` | valores do data-model | Só leitura; sempre válidos |
| `voiceName` | string | `Relay 01`, `rien-OS` ou `System` (do `Strings`) |
| `durationFactor` | real | 0,66 / 1 / 1,5 |
| `origin(key)` | `"state"`, `"user"`, `"default"` | Pro `dump` |
| `set(key, value)` | `"ok"` / `"error: …"` | Valida, aplica na hora, grava o estado (não com fixtures) |
| `setDnd(on)` | void | Atalho do `set("dnd", on)` |
| `reset()` | void | Volta tudo ao padrão do projeto + `shell.json` e apaga as escolhas do estado |
| **fonte viva** (research R13) | `liveValue(key)`, `setLiveValue(key, v)`, `liveValues(key)`, sinal `liveChanged()` | O que o `SettingsModel` usa. `liveValue` de uma escolha devolve o **índice** em `liveValues(key)`; de um toggle, o bool |

Fontes: `config/defaults.json` (bloco `notifications`) → `$XDG_CONFIG_HOME/rien-os/shell.json` (bloco
`notifications`, só lido) → `$XDG_STATE_HOME/rien-os/notifications.json` (lido e escrito). Fixture:
`notifications.prefs` e `notifications.dnd` (em memória).

### `NotifyStore` — o servidor, o log e a tela (US1–US4, US6)

| Membro | Tipo | Notas |
|---|---|---|
| `server` | bool | Somos o dono do nome (research R2) |
| `serverOwner` | string | `Comm` do dono (`"qs"`, `"mako"`, `""`) |
| `entries` | lista de `Entry` | O log, a mais nova primeiro, já cortado em `logSize`; sem `transient` |
| `stack` | lista de `Transmission` | Na tela, por monitor (`stackOn(monitor)`) |
| `critical` | `CriticalBand` \| null | |
| `unread`, `overflow` | int | Contador da barra; `+N in log` |
| `logOpen` | bool | Escrito pelo `shell.qml`/007; com ele, as novas vão pra lista (FR-027) |
| `held` | bool | `dnd` ou (`focusedFullscreen` e `fullscreen == "hold"`) |
| `entry(id)` | `Entry` \| null | |
| `invoke(id, actionId)` | `"ok"` / `"error: …"` | `"default"` = ação padrão |
| `reply(id, text)` | `"ok"` / `"error: …"` | `sendInlineReply` |
| `dismiss(id)` | void | `dismiss()` pro app + sai do log |
| `hide(id)` | void | Só sai da tela (fica no log) — o clique sem ação padrão, o botão direito, o × |
| `hideAll()` | void | Esvazia a tela (pilha + crítica), tudo pro log |
| `clear()` | void | Dispensa todas as vivas e esvazia o log (e o arquivo, com `Saved`) |
| `markAllRead()` | void | Abrir o log (FR-024) |
| `pause(id, on)`, `typed(id)`, `remainingOf(id)` | — | Ganchos da transmissão (mouse, fim da digitação) |
| `system(title, body, urgency)` | int (id) | Mensagem do rien-OS, com a voz do sistema |
| `sample(name)` | `"ok"` / `"error: …"` | O injetor (research R17) |
| `dumpState()` | objeto | Pro `notify dump` |

Fonte: `NotificationServer` (research R1). Fixture: domínio `notifications` (o log, a pilha, as
críticas; ver o schema). Log salvo: `$XDG_STATE_HOME/rien-os/text-log.json`, só com `log == "saved"` e
sem fixtures (research R14). Estado de sessão: `PersistentProperties` (research R15).

### `NotifyText` — funções puras de texto (FR-036)

| Função | Notas |
|---|---|
| `sanitize(markup)` → string | Escapa tudo; devolve só `<b>`, `<i>`, `<u>` bem formadas; links viram texto |
| `plain(markup)` → string | Sem tags (pro comprimento, pro `dump` e pro log salvo em `title`) |
| `cut(styled, n)` → string | Os `n` primeiros caracteres visíveis, fechando as tags abertas (R7) |
| `firstDiff(a, b)` → int | Índice do primeiro caractere visível diferente (substituição, FR-006) |
| `duration(entry, factor)` → int ms \| null | A regra da FR-007 + `Duration` |

### `Osd` — o aviso de volume, microfone e brilho (US5)

| Membro | Tipo | Notas |
|---|---|---|
| `current` | `Osd` \| null | O que está na tela |
| `brightnessAvailable` | bool | Existe `/sys/class/backlight/*` |
| `show(kind, value, muted)` | `"ok"` / `"error: …"` | Pro IPC e pra VM sem brilho |
| `suppress(kind, on)` | void | FR-029 (research R12) |
| `hide()` | void | |

Fontes: `Pipewire.defaultAudioSink`/`defaultAudioSource` (`Quickshell.Services.Pipewire`); brilho por
`udevadm monitor` + sysfs (research R12). Fixture: `notifications.osd` (mostra parado, sem tempo).

## Acréscimos

| Serviço | Acréscimo | Fonte |
|---|---|---|
| `Compositor` | `focusedFullscreen: bool`; `focusedMonitor` atualizado também no evento `focusedmon` | `hyprctl activewindow -j` nos eventos `fullscreen`, `activewindow`, `workspace` (R10, R11). Fixture: `notifications.fullscreen` |
| `SettingsModel` | campo `live` nas opções; `liveSources` (`{ notify: NotifyPrefs }`); `values` vivos (`valuesFrom`); `isLive(cat, opt)`; `reset()` não toca as vivas; `dumpValues()` mostra o valor vivo | research R13 |
| `Settings` | bloco `notifications` lido de `defaults.json` + `shell.json` (validado) e exposto como `Settings.notifications` (objeto); quem aplica a precedência com o estado é o `NotifyPrefs` | data-model |
| `Fixtures` | domínio `notifications` | contracts/notifications.schema.json |

**Domínio `notifications` das fixtures:** como o `settings` da 003, é novo e o `fixtures.schema.json`
da 001 (com `additionalProperties: false`) não o lista. No merge na principal, ele ganha
`"notifications": { "$ref": "rien-os/shell/notifications/1#/$defs/fixture" }`.

## Regras

- **Nenhum texto recebido vai pra um `Process`.** Os `Process` desta fase têm argv fixos (`busctl`,
  `udevadm`, `file`, `install`, `chmod`, `rm`, `notify-send`/`gdbus` com textos do `Strings`), com o
  único argumento variável sendo um caminho já validado.
- **Mensagens de log do shell desta fase** são `console.info` (casos de borda esperados) ou
  `console.warn` (erro de verdade). O roteiro normal não pode ter nenhum `warn` (FR-037).
- **Com fixtures**, nada é escrito em disco (`NotifyPrefs`, log salvo).
