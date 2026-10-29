# Contrato: comandos IPC (alvo `wallpaper`)

Os comandos são chamados com `qs -p <pasta da UI> ipc call wallpaper <função> [args]`. No laboratório,
isso vira `lab/ipc qs -p ~/nier/ui ipc call wallpaper …`. O alvo já existe desde a 001 (`motion`,
`isMoving`) e ganha as funções abaixo. Um `yorha wallpaper …` (S4) vai ser um invólucro destes
comandos.

| Função | Retorno | Uso |
|---|---|---|
| `motion(on: bool)` | — | (001) Liga ou desliga o movimento das cenas até reiniciar |
| `isMoving()` | `"true"` / `"false"` | (001) Verificação |
| `list()` | JSON: `[{ "id", "type", "name", "group", "available" }]` | O catálogo, na ordem da lista |
| `set(id: string, monitor: string)` | `"ok"` ou `"error: <motivo>"` | Aplica. `monitor` = nome da saída, ou `""`/`"all"` pra todos (FR-019) |
| `next(monitor: string)` | `"ok"` ou `"error: …"` | Próximo item disponível. `""` = monitor em foco |
| `prev(monitor: string)` | `"ok"` ou `"error: …"` | Anterior |
| `transition(kind: string)` | `"ok"` ou `"error: …"` | `camouflage`, `wipe`, `tiles` ou `crossfade` |
| `camouflage(cell: int, trail: int, glitch: int)` | `"ok"` ou `"error: …"` | Ajuste fino (validação do data-model) |
| `filter(path: string, on: bool)` | `"ok"` ou `"error: …"` | Filtro de papel de uma imagem |
| `picker(action: string)` | `"ok"` | `open`, `close` ou `toggle` |
| `dump()` | JSON (abaixo) | "Comando que responde" (princípio IV) |

Formato do `wallpaper dump`:

```json
{
  "all": "scene:menu",
  "monitors": [
    { "name": "Virtual-1", "current": "scene:menu", "own": "", "transitioning": false, "kind": "camouflage", "elapsed": 0 }
  ],
  "transition": { "kind": "camouflage", "cell": 24, "trail": 2600, "glitch": 2, "instant": true },
  "catalog": { "count": 7, "folder": "/home/arch/nier/ui/fixtures/wallpapers", "folderMissing": false },
  "picker": { "open": true, "screen": "Virtual-1", "focus": "options", "index": 2, "item": "scene:dark", "option": 1, "monitor": "All monitors", "transitionLabel": "Camouflage" }
}
```

**Detalhes:**
- `own` é a escolha própria do monitor (vazia quando ele segue "todos").
- `picker` é `null` com o seletor fechado.
- `elapsed` é o tempo da transição em andamento, em ms.

**Atalho na VM:** `ALT + W` → `picker toggle` (research R11). Nos padrões do instalador, vai ser
`SUPER + W`.

## Emenda da US6: o tom da barra (2026-10-27)

**`wallpaper dump`:** cada entrada de `monitors` ganha `luma`, a luminância medida da faixa de cima da
imagem na tela (0–1, três casas), ou `null` quando é uma cena ou a imagem ainda não foi medida.

**`hud dump`** (alvo `hud`, da 001): cada entrada de monitor ganha:

```json
{
  "tone": "light",
  "toneMix": 1,
  "texts": [
    { "role": "time", "text": "13:37:00", "x": 1830, "y": 9, "w": 80, "h": 22, "color": "#d7d1b3ff", "plate": "" },
    { "role": "tab", "text": "01", "x": 46, "y": 3, "w": 67, "h": 33, "color": "#d7d1b3ff", "plate": "#d7d1b329" }
  ]
}
```

- `toneMix`: a mistura que a barra mostra agora, de 0 (papel) a 1 (claro), com três casas.
- `tone`: `"light"` com `toneMix` ≥ 0,5, senão `"paper"`.
- `texts`: os textos visíveis da barra (abas, título, rótulos e valores das leituras, data, hora),
  com a caixa em px lógicos da janela, a cor do texto (`#rrggbbaa`) e, nas abas, a cor da placa
  embaixo do texto (vazia nos outros). Servem pra medir o contraste nos pixels (SC-011).

**`hud visible(on: bool)`** (novo, só pra testes): esconde (`false`) ou mostra as barras de todos os
monitores, sem lembrar nada. Serve pra fotografar o papel de parede sozinho embaixo da barra e medir
a área vazia (SC-012) e o contraste dos textos (SC-011).
