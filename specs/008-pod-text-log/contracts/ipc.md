# Contrato: comandos IPC (alvo `notify`)

Chamada: `qs -p <pasta da UI> ipc call notify <função> [args]`; no laboratório,
`lab/ipc 'qs -p ~/nier/ui ipc call notify …'`. Um `IpcHandler` novo no `shell.qml`. Um `yorha notify …`
(S4) vai ser um invólucro destes comandos.

| Função | Retorno | Uso |
|---|---|---|
| `open()` | — | Abre o log no monitor em foco (FR-020). Já aberto: nada |
| `close()` | — | Fecha (duas fases) |
| `toggle()` | — | Alterna. É o que o atalho chama |
| `isOpen()` | `"true"` / `"false"` | Verificação |
| `dnd(mode: string)` | `"on"` / `"off"` ou `"error: …"` | `on`, `off`, `toggle`; devolve o estado novo. É o que o atalho do não perturbe chama |
| `clear()` | `"ok"` | Clear all (FR-033) |
| `dismissAll()` | `"ok"` | Esvazia a tela, tudo pro log |
| `invoke(id: int, action: string)` | `"ok"` / `"error: …"` | Dispara uma ação (testes) |
| `osd(kind: string, value: int, muted: bool)` | `"ok"` / `"error: …"` | `volume`, `mic`, `brightness` (FR-033, VM sem brilho) |
| `sample(name: string)` | `"ok"` / `"error: …"` | **Injetor de testes** (FR-032): manda a notificação de exemplo pelo caminho real (`notify-send`/`gdbus`). Nomes: `normal`, `actions`, `reply`, `critical`, `flood5`, `long`, `progress`, `low`, `script100`, `system` |
| `pref(key: string, value: string)` | `"ok"` / `"error: …"` | Muda uma opção (FR-039), com o mesmo efeito das configurações. Valores como no data-model (`position top`, `logSize 50`, `monitor ""`) |
| `prefsReset()` | `"ok"` | Volta as opções ao padrão e apaga as escolhas do estado |
| `dump()` | JSON (abaixo) | "Comando que responde" (princípio IV) |

Formato do `notify dump`:

```json
{
  "server": true,
  "serverOwner": "qs",
  "held": false,
  "fullscreen": false,
  "prefs": {
    "dnd": false, "position": "corner", "osdPosition": "bottom", "voice": "relay", "log": "session",
    "logSize": 100, "monitor": "", "onScreen": 3, "duration": "normal", "typing": true, "fullscreen": "hold",
    "origin": { "position": "state", "voice": "default" }
  },
  "unread": 2,
  "overflow": 0,
  "screen": [
    {
      "id": 41, "monitor": "Virtual-1", "speaker": "Firefox", "title": "Build", "body": "The nightly build finished.",
      "urgency": "normal", "count": 1, "typed": true, "shown": 27, "remaining": 4120, "paused": false,
      "replying": false, "actions": ["Open", "Snooze"], "image": false, "progress": null,
      "arrivedAt": 1793108220123, "shownAt": 1793108220171, "typedAt": 1793108220470,
      "box": { "x": 1364, "y": 80, "w": 540, "h": 148 }
    }
  ],
  "critical": { "monitor": "Virtual-1", "ids": [44], "page": 1, "box": { "x": 0, "y": 80, "w": 1920, "h": 230 } },
  "log": { "count": 6, "limit": 100, "saved": false, "file": "", "ids": [44, 43, 42, 41, 40, 39] },
  "entries": [
    { "id": 44, "speaker": "Relay 01", "title": "Battery critical", "urgency": "critical", "read": false,
      "isNew": false, "alive": true, "earlier": false, "answered": "" }
  ],
  "osd": { "kind": "volume", "value": 66, "muted": false, "monitor": "Virtual-1", "remaining": 900,
           "box": { "x": 660, "y": 898, "w": 600, "h": 72 } },
  "page": null
}
```

- `screen[].box`, `critical.box` e `osd.box`: px lógicos do monitor (pros cliques dos testes e pra
  conferir as posições, SC-014).
- **Acréscimo de 2026-10-29 (pros cliques dos testes):** `screen[].controls` =
  `{ "buttons": [{ "label", "x", "y", "w", "h" }], "field": caixa ou null }` (os botões de ação e o
  Reply, na ordem; o campo de resposta aberto) e `critical.controls` = `{ "prev", "next", "close" }`
  (◂, ▸ e ×; `prev`/`next` `null` com uma página só), nas mesmas coordenadas.
- `screen[].remaining`: `null` com fixtures; `critical` nunca expira.
- `entries`: só as 20 primeiras (o `dump` de uma enxurrada fica pequeno); `log.ids` traz todas.
- `osd`: `null` sem OSD na tela.
- `page`: `null` com o log fechado; aberto, o `LogPage.dumpState()`:

```json
{
  "host": "popup", "monitor": "Virtual-1", "focus": "options", "index": 0, "option": 1, "filter": "all",
  "entry": 44, "keys": ["↑↓ Select", "←→ Change", "Esc Back"],
  "preview": { "speaker": "Relay 01", "status": "Waiting", "note": "" },
  "rows": ["NOW", "■ Relay 01 · Battery critical · 13:37", "…"],
  "geometry": { "s": 1.0, "panel": { "x": 154, "y": 87, "w": 1612, "h": 906 }, "item": { "x": 118, "y": 237, "w": 420, "h": 48 } }
}
```

## Acréscimos em alvos existentes

- **`hud dump`** (001/004): cada monitor ganha `log: { "visible": true, "text": "LOG 3", "box": {…} }`
  (o contador da FR-025), e o item entra em `texts` com `role: "log"` (contraste, SC-011 da 004).
- **`settings dump`** (003): `values.notifications` mostra os valores vivos; o campo novo
  `live: ["notifications.dnd", …]` lista as opções que valem de verdade.

## Atalhos (proposta, **pendentes de confirmação do dono**)

| Onde | Tecla | Comando |
|---|---|---|
| VM do laboratório (`lab/guest/hyprland.lua`) | `ALT + N` | `qs -p ~/nier/ui ipc call notify toggle` |
| VM do laboratório | `ALT + CTRL + N` | `qs -p ~/nier/ui ipc call notify dnd toggle` |
| VM do laboratório | `XF86AudioRaiseVolume` / `LowerVolume` / `Mute` / `MicMute` | `wpctl` (2%), pro OSD reagir a teclas reais |
| Sistema instalado (S3/U7) | `SUPER + N`, `SUPER + CTRL + N` | os mesmos, com a pasta da UI instalada |

Na VM eles entram como provisórios: os testes precisam de teclas reais (SC-009). Trocar depois da
decisão do dono é só mudar a config e esta tabela.
