# Contrato: serviços (007)

A UI lê dados **só** pelos serviços (`shell/services/`, singletons). Regras de sempre: só o
`Compositor` fala com o Hyprland; uma leitura que falha nunca lança erro na UI (vira `error` + uma
linha no log); nenhum texto vindo do usuário passa por shell.

## `Apps` (novo)

| Membro | Tipo | Notas |
|---|---|---|
| `apps` | lista de `App` (data-model) | Todos, sem ordem garantida |
| `ready` | bool | A lista carregou ao menos uma vez |
| `error` | string | `""` ou a mensagem curta do quadro (fixture ausente/inválida) |
| `count` | int | |
| `listed(order)` | lista de entradas da `GroupedList` | Sem busca: `{ group: "PINNED" }`, os fixados, `{ group: "ALL APPS" }`, os outros na `order` (`az`/`used`); itens `{ label, trailing, id }` (`trailing` = janelas abertas, ou `""`) |
| `search(query)` | lista de ids | Pela `appsearch.js` (research R5); `query` vazia → `[]` |
| `byId(id)` | `App` ou `null` | |
| `windowsOf(id)` | lista de `Window` | As janelas abertas do app (pelo `windowClass`), a mais recente primeiro |
| `launch(id, action, workspace)` | `"ok"` ou `"error: …"` | `action`: índice de `actions` ou `-1` (o app); `workspace`: `0` (atual) ou 1–10. Confere o executável, leva à área (se ≠ 0), abre por `execDetached` (research R4), soma um uso e grava o estado. Com a fixture `apps`, abre de verdade (os comandos da fixture são de teste) mas não grava o estado. Sempre registra `lastLaunch` |
| `lastLaunch` | `{ id, action, workspace, command, ok, reason }` ou `null` | Pro `pause dump` |
| `setPinned(id, on)` | void | Grava o estado (sem fixture) |

**Fonte real:** `DesktopEntries.applications` (atualiza sozinho, research R4) + o estado
`$XDG_STATE_HOME/yorha-os/apps.json` (R11). **Fixture:** domínio `apps` = caminho de um arquivo no
formato `#/$defs/appsFile` de [pause-fixtures.schema.json](pause-fixtures.schema.json).

## `appsearch.js` (novo, `.pragma library`)

| Função | Retorno |
|---|---|
| `normalize(s)` | string sem diacríticos, minúscula |
| `tier(app, q)` | 0–4 (FR-010) ou −1 (fora) |
| `rank(apps, q)` | apps em ordem: faixa, `uses` decrescente, nome normalizado |

## `Compositor` (acréscimos)

> **28.10:** a partir da T012a, o `Compositor` vira uma fachada sobre um backend por compositor. Os nomes abaixo continuam, com `id` no lugar de `address`. Veja `contracts/compositor.md`.

| Membro | Tipo | Notas |
|---|---|---|
| `windows` | lista de `Window` (data-model) | Real: `hyprctl clients -j` relido nos eventos (research R7); fixture: domínio `windows` |
| `workspaceList` | lista de `Workspace` | Real: `hyprctl workspaces -j`; fixture: derivada das janelas |
| `monitorList` | lista de `{ name, w, h, focused }` | Do `hyprctl monitors -j` que já é lido (largura e altura lógicas = tamanho ÷ escala); fixture: `windows.monitors` |
| `windowsRevision` | int | Sobe a cada leitura nova (pra quem guarda cópia) |
| `focusWindow(address)` | `"ok"`/`"error: …"` | Research R8; com fixture `windows`: só registra em `lastWindowAction` e muda a janela em foco da fixture em memória |
| `moveWindow(address, ws)` | `"ok"`/`"error: …"` | `ws` 1–10; sem seguir. Com fixture: move em memória e registra |
| `toggleFloating(address)` | `"ok"`/`"error: …"` | Com fixture: alterna em memória e registra |
| `closeWindow(address)` | `"ok"`/`"error: …"` | Pedido educado. Com fixture: tira da lista em memória e registra |
| `lastWindowAction` | `{ kind, address, workspace }` ou `null` | Pro `pause dump` |

O `focus(id)` e o `focusedMonitor` da 001/003 continuam.

## `Session` (novo)

| Membro | Tipo | Notas |
|---|---|---|
| `actions` | lista de `PowerAction` (data-model) | Na ordem da lista; `confirm` calculado com `SettingsModel.choiceId("menu", "confirm")` |
| `status` | `Session` (data-model) | |
| `dryRun` | bool | `Fixtures.active`: **nenhuma** ação executa com fixture ativa (research R9) |
| `refresh()` | void | Relê capacidades e bloqueios (ao entrar em POWER e ao abrir o diálogo) |
| `run(id)` | void | Executa pela tabela do research R9 (ou só registra, em `dryRun`); preenche `lastAction` e, numa recusa, `lastError` |
| `lastAction`, `lastError` | ver data-model | |
| `busy` | string | O id da ação em andamento (entre disparar e o comando responder) |

**Sinais:** `accepted(id)` (comando terminou com 0, ou `dryRun`), `refused(id, reason)`. O menu fecha
no `accepted` das ações que confirmam e antes de `run` nas outras (research R9).

**Fixture:** domínio `session` = caminho de um arquivo no formato `#/$defs/sessionFile`.

## `SettingsModel` (acréscimos)

| Membro | Tipo | Notas |
|---|---|---|
| `choiceId(catId, optId)` | string | `ids[value]` de uma escolha com `ids`; `""` sem `ids`, sem a opção ou fora de faixa |

**Validação do catálogo** (`problemOf`): uma escolha com `ids` precisa de `ids.length ==
values.length`, todos strings não vazias e únicas.

**Catálogo** (`shell/fixtures/settings-default.json`): categoria nova depois de `appearance`.

```json
{
  "id": "menu", "label": "Pause menu",
  "about": "How the pause menu looks and what it asks before acting.",
  "options": [
    {"id": "icons", "label": "App icons", "type": "choice", "desc": "How APPS shows an app's icon. Ink redraws it in the paper's ink; Original color keeps its colors; Square only shows the game's square.", "values": ["Ink", "Original color", "Square only"], "ids": ["ink", "color", "square"], "value": 0, "default": 0},
    {"id": "app-order", "label": "App order", "type": "choice", "desc": "Order of ALL APPS when you are not searching. Search results always put the most used first.", "values": ["A–Z", "Most used"], "ids": ["az", "used"], "value": 0, "default": 0},
    {"id": "running-app", "label": "Running app", "type": "choice", "desc": "What Enter does on an app that already has a window: open another one, or go to its window.", "values": ["New window", "Go to window"], "ids": ["new", "focus"], "value": 0, "default": 0},
    {"id": "confirm", "label": "Confirm", "type": "choice", "desc": "Which POWER actions ask first. Risky ones: log out, reboot and shut down. Every action: lock and suspend too.", "values": ["Risky ones", "Every action"], "ids": ["risky", "all"], "value": 0, "default": 0},
    {"id": "confirm-start", "label": "Dialog starts on", "type": "choice", "desc": "Where the cursor starts in a confirmation. On Cancel, a second Enter never acts by accident.", "values": ["Cancel", "Action"], "ids": ["cancel", "action"], "value": 0, "default": 0}
  ]
}
```

O `settings.schema.json` da 003 ganha a propriedade opcional `ids` (lista de strings) nas escolhas;
o arquivo atualizado fica em `specs/003-settings-popup/contracts/settings.schema.json` no merge (a
T009 faz a mudança).

## `Settings` (acréscimo)

| Chave | Padrão | Validação |
|---|---|---|
| `terminal` | `["kitty"]` | lista não vazia de strings; senão o padrão + aviso |

## `Fixtures` (acréscimo)

Os domínios `apps`, `windows` e `session` (caminhos de arquivo), servidos por `has`/`get` como os
outros. O `fixtures.schema.json` da 001 ganha os três no merge na principal, como o `settings` da 003
(pendência já anotada).
