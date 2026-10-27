# Contrato: comandos IPC (alvo `wallpaper`)

Os comandos são chamados com `qs -p <pasta da UI> ipc call wallpaper <função> [args]`. No laboratório,
isso vira `lab/ipc qs -p ~/nier/ui ipc call wallpaper …`. O alvo já existe desde a 001 (`motion`,
`isMoving`) e ganha as funções abaixo. Um `rien wallpaper …` (S4) vai ser um invólucro destes
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
| `picker(action: string)` | `"ok"` ou `"error: …"` | `open`, `close` ou `toggle`; outra palavra responde erro |
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

O `picker` também traz, pra conferência nos testes (US2):
- `optionId` (`monitor`, `transition`, `filter` ou `null`) e `filter` (`On`/`Off` numa imagem, senão `null`);
- `keys`: o rodapé de teclas, como `"↑↓ Select"`;
- `preview` (`title`, `text`, `type`) e `info` (`"Type: Scene"`…);
- `entries`: a lista como aparece (títulos, avisos e itens com a marca, ex. `"Menu ● ALL"`, `"Videos (dim)"`);
- `geometry`: `s`, `panel`, `item` (o item ou a opção em foco), `value` (o `◂ valor ▸` da opção em
  foco), `preview` e `options`, em px lógicos.

**Detalhes:**
- `own` é a escolha própria do monitor (vazia quando ele segue "todos").
- `picker` é `null` com o seletor fechado.
- `option` é `null` com o foco na lista.
- `monitor` é o rótulo do valor da opção Monitor (`All monitors` ou o nome da saída).
- `elapsed` é o tempo da transição em andamento, em ms.

**Atalho na VM:** `ALT + W` → `picker toggle` (research R11). Nos padrões do instalador, vai ser
`SUPER + W`.
