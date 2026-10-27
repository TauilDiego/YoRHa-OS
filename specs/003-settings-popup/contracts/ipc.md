# Contrato: comandos IPC (003)

Os alvos da 001 continuam. A 003 acrescenta o alvo `settings`, um `IpcHandler` no `shell.qml`.
Chamada: `qs -p <pasta da UI> ipc call settings <função>`; no laboratório,
`lab/ipc 'qs -p ~/nier/ui ipc call settings …'`.

| Função | Retorno | Uso |
|---|---|---|
| `open()` | — | Abre no monitor em foco (FR-001). Já aberto: nada |
| `close()` | — | Fecha (fechamento em duas fases, research R2) |
| `toggle()` | — | Alterna. É o que o atalho chama |
| `isOpen()` | `"true"` / `"false"` | Verificação |
| `dump()` | JSON (abaixo) | Estado inteiro (FR-021) |
| `reset()` | — | Volta os valores ao catálogo, pros testes (research R12) |

Formato do `settings dump`:

```json
{
  "open": true,
  "monitor": "Virtual-1",
  "focus": "options",
  "category": "bluetooth",
  "option": "pair",
  "busy": "",
  "error": "",
  "keys": ["↑↓ Select", "Enter Search", "Esc Back"],
  "card": { "title": "Pair a device", "note": "Turn on Bluetooth first." },
  "values": {
    "display": { "resolution": "2560 × 1600", "refresh": "120 Hz", "scale": "1.25×", "brightness": "70", "night": "OFF" },
    "bluetooth": { "bluetooth": "OFF", "keyboard": "Connected", "headphones": "Paired", "pair": "Search" }
  },
  "dimmed": ["bluetooth.keyboard", "bluetooth.headphones", "bluetooth.pair"],
  "geometry": {
    "s": 1.0,
    "panel": { "x": 154, "y": 87, "w": 1612, "h": 906 },
    "item": { "x": 672, "y": 437, "w": 557, "h": 48 },
    "value": null
  }
}
```

- `focus`: `"categories"` ou `"options"`. Com o foco nas categorias, `option` é `null`.
- `keys` é o que o rodapé mostra (FR-015), `"<tecla> <rótulo>"`.
- `card.note` é `""` quando o quadro não tem aviso.
- `busy` é a opção com ação em andamento, como `"cat.opt"`.
- `geometry` (px lógicos da tela, pros cliques dos testes): o fator `s`, o painel, o item em foco
  (categoria ou opção) e o controle do valor da opção em foco (o seletor `◂ valor ▸` ou a trilha do
  slider; `null` nos outros tipos). Com o popup fechado, `null`.
- Com o popup fechado, `open` é `false` e o resto mostra o último estado (os valores ficam em memória).

## Atalho

| Onde | Tecla | Comando |
|---|---|---|
| VM do laboratório (`lab/guest/hyprland.lua`) | `ALT + I` | `qs -p ~/nier/ui ipc call settings toggle` |
| Sistema instalado (S3/U7) | `SUPER + I` | o mesmo, com a pasta da UI instalada |
