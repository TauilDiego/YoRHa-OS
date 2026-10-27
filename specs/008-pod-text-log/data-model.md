# Modelo de dados: Pod e text log

Os nomes de campo ficam em inglês, como no código. Os formatos de arquivo estão em
[contracts/notifications.schema.json](contracts/notifications.schema.json).

## Entry (uma notificação no log)

Criada pelo `NotifyStore` a cada notificação recebida (ou pela fixture, ou por `system()`).

| Campo | Tipo | Regras |
|---|---|---|
| `id` | int | O id do servidor (o que o app recebeu). Nas da fixture e nas do sistema, negativo (não colide) |
| `app` | string | `appName`; vazio → o nome da entrada de desktop (`desktopEntry`), senão `Unknown` |
| `appKey` | string | `desktopEntry` ou `app`: a chave do agrupamento (FR-017) |
| `speaker` | string | Quem fala: `app`, ou a voz do sistema (`NotifyPrefs.voice`) quando `system: true`. Calculado na hora de desenhar, então trocar a voz muda até as antigas |
| `system` | bool | Mensagem do próprio rien-OS |
| `title` | string | `summary`, texto puro, uma linha |
| `body` | string | `NotifyText.sanitize(body)` (só `<b>`, `<i>`, `<u>`) |
| `urgency` | enum `low`, `normal`, `critical` | Do app; sem dica → `normal` |
| `timeout` | int ms \| null | `expireTimeout` > 0 → ms pedidos pelo app; `0`/ausente → `null` (usa a FR-007) |
| `actions` | lista de `{ id, label }` | Na ordem do app, sem a `default`. Na tela, até 3 (FR-012) |
| `hasDefault` | bool | Existe a ação `default` (clique dispara) |
| `reply` | `{ label }` \| null | Com `hasInlineReply`: o rótulo (placeholder ou `Reply`) |
| `image` | string | URL pronta pro `Image` (`file://…` conferido, ou `image://…`), ou `""` |
| `progress` | int 0–100 \| null | A dica `value` |
| `resident` | bool | Continua viva depois de uma ação |
| `transient` | bool | Não entra no log (aparece e some) |
| `at` | int ms | Hora de chegada (`Date.now()`; na fixture, fixa) |
| `read` | bool | Lida: terminou de digitar na tela, ou o log foi aberto depois que ela chegou |
| `isNew` | bool | Era não lida quando o log abriu (mostra `NEW` enquanto o log está aberto) |
| `answered` | string | `""`, ou o id da ação disparada / `reply` |
| `alive` | bool | O app ainda escuta (objeto rastreado). `false` → ações apagadas, "The app closed this notification." |
| `earlier` | bool | Veio do log salvo de uma sessão anterior: `alive: false`, sem ações, STATUS "Earlier session" |
| `typedFrom` | int | Primeiro caractere diferente na última substituição (FR-006); 0 numa nova |

**Transições:**

```
recebida ──► (DND / tela cheia com Hold / log aberto) ──► log, read=false
recebida ──► pilha (Transmission) ──► sai da tela ──► log (read = terminou de digitar)
log ──(abrir o log)──► read=true, isNew = !read_antes
viva ──(app fecha: closed CloseRequested)──► alive=false (fica no log)
viva ──(usuário dispensa / Delete / Clear all)──► dismiss() ──► sai do log
viva ──(ação, não residente)──► invoke() ──► alive=false, answered=id
```

**Validação ao carregar o log salvo:** `version: 1`, `entries` lista; cada entrada com `title` e `at`
numéricos; o resto com padrão. Inválido → backup + log vazio (research R14). Nunca gravados: `actions`,
`reply`, `image` que não é `file://`, e as `transient`.

## Transmission (uma entrada na tela)

| Campo | Tipo | Regras |
|---|---|---|
| `entry` | id | A entrada mostrada (a mais nova do grupo) |
| `count` | int | `×N` do agrupamento (1 = sem marca) |
| `monitor` | string | Onde apareceu (fica lá até sair, caso de borda) |
| `shown` | int | Caracteres visíveis do corpo (`TypedText`) |
| `typed` | bool | Terminou de digitar |
| `remaining` | int ms \| null | Tempo que falta; `null` na crítica e com fixtures |
| `paused` | bool | Mouse por cima ou campo de resposta aberto |
| `replying` | bool | Campo de resposta aberto (só uma transmissão por vez) |
| `arrivedAt`, `shownAt`, `typedAt` | int ms | Pra o SC-001 (research R19) |

**Tempo na tela (FR-007 + `Duration`):** `entry.timeout` quando o app pediu; senão
`low` 4000, `normal` `min(12000, 6000 + 1000 × ceil(max(0, len(corpo) − 120) / 80))`, `critical` sem
fim; vezes o fator de `Duration` (`Short` 0,66, `Normal` 1, `Long` 1,5) quando não foi o app que pediu.
Começa em `typedAt`.

**Pilha (FR-018, `On screen`):** até `NotifyPrefs.onScreen` normais/baixas; a crítica fica fora (na
faixa crítica). Cheia → a mais velha sai pro log; se não tinha terminado de digitar, `overflow + 1`
(a linha `+N in log`). `overflow` zera quando a pilha esvazia ou o log abre.

## CriticalBand

| Campo | Tipo | Regras |
|---|---|---|
| `entries` | lista de ids | As críticas na tela, a mais nova primeiro |
| `page` | int | Qual está à mostra (`1/N`, ◂ ▸) |
| `monitor` | string | Onde está |

Some quando a lista esvazia (cada uma sai por ×, ação ou o app fechar).

## Osd

| Campo | Tipo | Regras |
|---|---|---|
| `kind` | enum `volume`, `mic`, `brightness` | |
| `value` | int | 0–∞ (volume pode passar de 100); `brightness` 0–100 |
| `muted` | bool | `volume`: MUTE + medidor apagado; `mic`: MIC OFF |
| `meter` | bool | `false` em `mic` |
| `monitor` | string | O em foco na hora |
| `remaining` | int ms | `Tokens.notify.osdHold` (1200) depois da última mudança |

Só existe um (FR-029). `suppressed` (por tipo) vem de `Osd.suppress(kind, on)`.

## NotifyPrefs (as opções, FR-039)

| Chave (`live`) | Opção | Valores (o primeiro é o de fábrica) | Tipo no catálogo |
|---|---|---|---|
| `dnd` | Do not disturb | `false`, `true` | toggle |
| `position` | Position | `corner`, `top`, `subtitle` (rótulos Corner, Top band, Subtitle) | choice |
| `osdPosition` | OSD position | `bottom`, `top` | choice |
| `voice` | System voice | `relay`, `rienos`, `system` (Relay 01, rien-OS, System) | choice |
| `log` | Text log | `session`, `saved` (Session only, Saved) | choice |
| `logSize` | Log size | `100`, `50`, `200` | choice |
| `monitor` | Monitor | `""` (Focused) ou o nome de uma saída | choice (valores vivos) |
| `onScreen` | On screen | `3`, `1`, `5` | choice |
| `duration` | Duration | `normal`, `short`, `long` | choice |
| `typing` | Typing | `true`, `false` | toggle |
| `fullscreen` | In fullscreen | `hold`, `show` | choice |

Cada valor tem a origem (`state`, `user`, `default`) pro `notify dump`. Valor inválido no
`shell.json` → padrão + `console.info` (não `warn`, FR-037); valor inválido no estado → padrão e o
estado é regravado.

**Arquivo de estado** (`$XDG_STATE_HOME/rien-os/notifications.json`):
`{ "version": 1, "dnd": false, "prefs": { "position": "corner", … } }` — só as chaves que o usuário
mudou.

## Categoria `notifications` do catálogo (`settings-default.json`)

Entra depois de `sound`. Cada opção tem `live: "notify.<chave>"`, `desc` (FR-042) e `values` (rótulos
em inglês, do `Strings`); `value`/`default` no catálogo são só referência (o valor vem da fonte viva).
A opção `monitor` tem `valuesFrom: "notify.monitor"`. Toggles vivos (`dnd`, `typing`) não usam `key`
nem `needs`.

## Estado do log aberto (`LogPage`)

| Campo | Tipo | Notas |
|---|---|---|
| `open` | bool | Do `shell.qml` (popup) ou da 007 (aba) |
| `host` | enum `popup`, `pause` | Quem desenha a moldura |
| `focus` | enum `list`, `options` | Foco em duas colunas |
| `index` | int | Entrada em foco (na lista filtrada) |
| `option` | int \| null | `null` com o foco na lista |
| `filter` | enum `all`, `unread`, `critical` | Opção `Show`, só da tela (volta pra `all` a cada abertura) |
| `pending` | string | Ação em andamento na entrada (aviso curto) |

**Transições do foco:** as do `PickerLayout` (design system §8), com: Enter na lista → ação padrão
(entrada viva com `hasDefault`; senão nada); Delete → dispensa e foco na próxima; opções: `Do not
disturb` (toggle), `Show` (choice), `Clear all` (ação; Enter limpa).
