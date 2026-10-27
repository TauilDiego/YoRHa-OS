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
| `wallpaper` | `motion(on: bool)` | — | Liga ou desliga o movimento do fundo (sobrepõe o `wallpaperMotion` até reiniciar) |
| `wallpaper` | `isMoving()` | `"true"` / `"false"` | Verificação |
| `hud` | `dump()` | JSON (abaixo) | "Comando que responde" (princípio IV) |

Formato do `hud dump`, com uma entrada por monitor:

```json
[{
  "monitor": "Virtual-1",
  "height": 68,
  "tabs": [{ "label": "01", "state": "normal", "x": 26, "w": 67 }, { "label": "02", "state": "selected", "x": 100, "w": 67 }],
  "title": "kitty — ~/projetos",
  "readings": [{ "key": "cpu", "label": "CPU", "value": 23, "critical": false, "extra": "none", "available": true }],
  "date": "2026.10.26",
  "time": "13:37:00"
}]
```

`x` e `w` são a posição e a largura da aba na janela, em px lógicos (servem pros testes de
clique). Os estados de aba no `dump` são `selected` (em foco), `normal` (existe) e `dimmed` (apagada).

**Acréscimo da spec 004 (US6, 2026-10-27):** cada entrada ganha `tone` (`"paper"`/`"light"`),
`toneMix` (0..1) e `texts` (caixa e cor de cada texto da barra), e o alvo `hud` ganha `visible(on:
bool)`, só pra testes. O formato está em `specs/004-wallpaper-system/contracts/ipc.md`, "Emenda da
US6".
