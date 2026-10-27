# Contrato: comandos IPC

Os comandos são chamados com `qs -p <pasta da UI> ipc call <alvo> <função> [args]`. No
laboratório, isso vira `lab/ipc qs -p ~/nier/ui ipc call …`. Cada alvo é um `IpcHandler` no
`shell.qml`.

| Alvo | Função | Retorno | Uso |
|---|---|---|---|
| `gallery` | `open()` | — | Abre a galeria (FR-016) |
| `gallery` | `close()` | — | Fecha |
| `gallery` | `toggle()` | — | Alterna |
| `gallery` | `isOpen()` | `"true"` / `"false"` | Verificação |
| `fixtures` | `load(path: string)` | `"ok"` ou a mensagem de erro | Troca de cenário sem reiniciar |
| `fixtures` | `clear()` | — | Volta aos dados reais |
| `hud` | `dump()` | JSON (abaixo) | "Comando que responde" (princípio IV) |

Formato do `hud dump`, com uma entrada por monitor:

```json
[{
  "monitor": "Virtual-1",
  "height": 40,
  "tabs": [{ "label": "01", "state": "normal" }, { "label": "02", "state": "selected" }],
  "title": "kitty — ~/projetos",
  "readings": [{ "key": "cpu", "label": "CPU", "value": 23, "critical": false, "extra": "none", "available": true }],
  "date": "2026.10.26",
  "time": "13:37:00"
}]
```

Os estados de aba no `dump` são `selected` (em foco), `normal` (existe) e `dimmed` (apagada).
