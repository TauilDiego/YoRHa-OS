# Contrato: comandos IPC (007)

Os alvos da 001, da 003 e da 004 continuam. A 007 acrescenta o alvo `pause` e transforma o
`settings` num alias da aba SYSTEM (research R2). Chamada:
`qs -p <pasta da UI> ipc call pause <função> [args]`; no laboratório,
`lab/ipc 'qs -p ~/nier/ui ipc call pause …'`.

## Alvo `pause`

| Função | Retorno | Uso |
|---|---|---|
| `open()` | — | Abre no monitor em foco, na última aba usada (APPS na primeira vez). Já aberto: nada |
| `close()` | — | Fecha (duas fases, como a 003) |
| `toggle()` | — | Fecha um menu aberto; senão, abre como `open`. É o atalho geral |
| `tab(name: string)` | `"ok"` / `"error: …"` | `apps`, `windows`, `system` ou `power`: fechado → abre nela; aberto → troca. Outra palavra: erro |
| `isOpen()` | `"true"` / `"false"` | |
| `search(text: string)` | `"ok"` / `"error: …"` | Só pros testes: abre em APPS (se preciso) e põe `text` como a busca, inteira. Erro com o menu em outro monitor |
| `reset()` | — | Volta tudo ao começo, pros testes: `lastTab = apps`, pipas e busca esquecidas, diálogo fechado, `lastAction` vazia (não mexe nos valores de SYSTEM: isso é o `settings reset`) |
| `dump()` | JSON (abaixo) | O estado inteiro (FR-029) |

Formato do `pause dump`:

```json
{
  "open": true,
  "monitor": "Virtual-1",
  "tab": "apps",
  "lastTab": "apps",
  "title": "APPS -Launcher",
  "footerLeft": "31 apps · type to search",
  "keys": ["↑↓ Select", "Enter Open", "→ Options", "Tab Next tab", "Esc Close"],
  "options": { "icons": "ink", "app-order": "az", "running-app": "new", "confirm": "risky", "confirm-start": "cancel" },
  "apps": {
    "column": "list",
    "query": "",
    "item": "kitty.desktop",
    "entries": ["PINNED", "kitty 2", "Firefox", "…", "ALL APPS", "…"],
    "results": [],
    "option": null,
    "preview": { "title": "kitty", "iconStyle": "ink", "icon": "…/fixtures/pause/icons/terminal.svg" },
    "info": ["Category: System", "Command: kitty", "Windows: 2"],
    "error": ""
  },
  "windows": {
    "column": "list",
    "item": "0x55d1c0a3f2b0",
    "groups": [ { "label": "WORKSPACE 01", "windows": ["0x55d1c0a3f2b0", "0x55d1c0a40110"] } ],
    "map": { "monitor": "Virtual-1", "workspace": 1, "selected": "0x55d1c0a3f2b0", "rects": 2 },
    "option": null,
    "error": ""
  },
  "system": { "focus": "categories", "category": "display", "option": null },
  "power": {
    "item": "lock",
    "dimmed": ["hibernate"],
    "card": { "title": "Lock", "effect": "The session stays as it is.", "note": "" },
    "status": { "user": "arch", "host": "nier-lab", "uptime": "2h 14m", "battery": "87%", "windows": 7, "note": "NO ERROR" },
    "dialog": null,
    "error": ""
  },
  "lastAction": { "kind": "app", "id": "kitty.desktop", "detail": { "action": -1, "workspace": 0, "ok": true } },
  "compositor": { "backend": "hyprland", "capabilities": { "workspaceModel": "numbered", "canFloat": true, "canMoveToWorkspace": true, "actsOnAnyWindow": true, "hasGeometry": "rect", "fullscreenKnown": true } },
  "geometry": {
    "s": 0.84,
    "panel": { "x": 154, "y": 87, "w": 1612, "h": 906 },
    "tabs": [ { "x": 220, "w": 180 } ],
    "item": { "x": 260, "y": 330, "w": 320, "h": 40 },
    "value": null
  }
}
```

- Uma aba ainda não visitada nesta abertura aparece com o estado de abertura dela (FR-006).
- `apps.results` são os ids na ordem da busca (vazio sem busca); `apps.entries` é a lista como aparece.
- `power.dialog`, com o diálogo aberto: `{ "action": "poweroff", "row": "cancel", "blockers": ["pacman: System update in progress"], "keys": ["↑↓ Select", "Enter Confirm", "Esc Cancel"], "geometry": { … } }`.
- `compositor` (T012a): `{ "backend": "hyprland", "capabilities": { … } }`, o `backendName` e as `capabilities` da fachada do compositor (contracts/compositor.md).
- `lastAction.kind`: `app`, `window` (`detail`: `{ "op": "focus|move|float|close", "workspace": 2 }`)
  ou `power` (`detail`: `{ "executed": false }` com fixtures).
- `geometry` (px lógicos da tela, pros cliques): `s`, o painel, cada aba, o item em foco (lista ou
  opção) e o `◂ valor ▸` da opção em foco (`null` nos outros tipos). Com o menu fechado, `null`.
- Com o menu fechado, `open` é `false` e o resto mostra o último estado; `lastAction` continua.

## Alvo `settings` (003, agora alias da aba SYSTEM)

| Função | Agora |
|---|---|
| `open()` | `pause tab system` |
| `close()` | Fecha o menu só se ele estiver em SYSTEM |
| `toggle()` | Fechado → abre em SYSTEM; aberto em outra aba → troca pra SYSTEM; aberto em SYSTEM → fecha (FR-001) |
| `isOpen()` | `"true"` só com o menu aberto em SYSTEM |
| `dump()` | O formato da 003, com os dados da página SYSTEM; `open` como `isOpen`; `geometry` passa a vir do painel do menu |
| `reset()` | Igual à 003 |

## Atalhos

| Onde | Tecla | Comando |
|---|---|---|
| VM do laboratório (`lab/guest/hyprland.lua`) | `ALT + Escape` | `qs -p ~/nier/ui ipc call pause toggle` |
| VM | `ALT + I` (já existe) | `qs -p ~/nier/ui ipc call settings toggle` |
| Sistema instalado (S3/U7) | `SUPER + Escape` | `pause toggle` |
| Sistema instalado | `SUPER + I` | `settings toggle` |

Os atalhos diretos de APPS, WINDOWS e POWER ficam fora do escopo; quando entrarem, são só linhas
`pause tab <aba>` na config do Hyprland.

## Interação com o seletor da 004

`pause open|toggle|tab` fecham o seletor de papel de parede; `wallpaper picker open` fecha o menu.
