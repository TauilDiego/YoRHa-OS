# Modelo de dados: Sistema de papel de parede

São as entidades que a UI manipula. Os nomes de campo ficam em inglês, como no código.

## Wallpaper (item do catálogo, `services/WallpaperCatalog.qml`)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | string | `scene:<nome>` (ex.: `scene:menu`) ou `image:<caminho absoluto>` |
| `type` | `"scene"` / `"image"` / `"video"` | `video` só como entrada fixa, apagada (FR-005) |
| `name` | string | Cena: o `name` do JSON (ex.: "Menu + rules"). Imagem: o nome do arquivo |
| `description` | string | Cena: do JSON. Imagem: um texto fixo do `Strings` |
| `group` | `"SCENES"` / `"IMAGES"` / `"VIDEO"` | Título do grupo na lista |
| `url` | url | Imagem: o `fileUrl` do `FolderListModel` (R6). Cena: o URL do JSON |
| `scene` | objeto | Só cena: os parâmetros lidos do JSON ([contracts/scene.schema.json](contracts/scene.schema.json)) |
| `available` | bool | `false` pro vídeo (sempre) |

**Ordem:** as cenas na ordem de fábrica (`menu`, `rules`, `dark`, `plain`), as imagens por nome e o
vídeo por último.

**Regras:**
- Uma imagem que não decodifica fica **fora** do catálogo e gera uma linha no log (FR-011).
- A pasta é lida, nunca criada nem alterada.

## Scene (parâmetros, `shell/wallpaper/scenes/<id>.json`)

| Campo | Tipo | Exemplo (`menu`) | Notas |
|---|---|---|---|
| `name` | string | "Menu" | Mostrado na lista |
| `description` | string | "The game's menu paper…" | Mostrado na prévia (inglês, FR-023) |
| `kind` | `"paper"` / `"dark"` | `"paper"` | `dark` troca o papel por `#141414` e as linhas por cinza |
| `paper` | `{ center, edge, corner }` | `#C8C3AC`, `#A6A18D`, `#8C8978` | Medidas do design system §6. `dark`: `#141414`, `#101010`, `#0A0A0A` |
| `layers.arcs` | bool | true | 4 arcos, 2 duplos |
| `layers.beams` | bool | true | 4 feixes de 2–3 linhas a 42° |
| `layers.rules` | bool | false | Régua pontilhada em y 1012 (px do jogo); a de cima é a da barra |
| `layers.dots` | bool | false | Trama de pontos (só `dark`) |
| `lineAlpha` | real | 0.15 | Tinta das linhas (`dark`: 0.20 de cinza claro) |
| `motion.arcPeriod` | s | 600 | Período da oscilação dos arcos |
| `motion.arcAmplitude` | graus | 9 | ± em torno do centro de cada arco |
| `motion.beamPeriod` | s | 300 | Período do deslize dos feixes |
| `motion.beamAmplitude` | px do jogo | 70 | ± ao longo da direção |

As quatro cenas de fábrica são estas:

| id | `kind` | arcos | feixes | réguas | trama |
|---|---|---|---|---|---|
| `menu` | paper | ✓ | ✓ | — | — |
| `rules` | paper | ✓ | ✓ | ✓ | — |
| `dark` | dark | ✓ | ✓ | — | ✓ |
| `plain` | paper | — | — | — | — |

A geometria dos arcos e dos feixes fica no componente (a mesma do mockup), não no JSON, pra que
todas as cenas compartilhem o mesmo desenho medido.

## Assignment (escolha, `services/WallpaperStore.qml`)

| Campo | Tipo | Notas |
|---|---|---|
| `all` | id ou `""` | A escolha "todos os monitores" |
| `monitors` | `{ nomeDaSaída: id }` | Escolhas próprias. Aplicar em "todos" **limpa** as próprias |

**Resolução de um monitor (FR-020):**
1. `monitors[nome]`, se existir e estiver no catálogo;
2. senão, `all`, se existir e estiver no catálogo;
3. senão, `scene:menu`.

Um id que caiu no fallback por não existir mais gera uma linha no log.

## Transition (`WallpaperStore.transition`)

| Campo | Tipo | Padrão | Validação |
|---|---|---|---|
| `kind` | `"camouflage"` / `"wipe"` / `"tiles"` / `"crossfade"` | `"camouflage"` | Fora da lista → padrão + aviso |
| `cell` | int (px do jogo) | 24 | ∈ {16, 24, 32} |
| `trail` | int (ms) | 2600 | 400–4000 |
| `glitch` | int | 2 | ∈ {0 nenhuma, 1 leve, 2 visível} |

**Prioridade:** estado > `shell.json` > `defaults.json` (research R8).

**Instantânea** quando `Fixtures.active` ou `Settings.reduceMotion` (FR-016).

## Transição em andamento (por monitor, `WallpaperTransition`)

| Campo | Tipo | Notas |
|---|---|---|
| `from`, `to` | id | `from` pode ser "a tela atual", quando a troca começa no meio de outra (FR-017) |
| `kind` | como acima | Fixado no início da troca |
| `elapsed` | ms | Anima de 0 até o fim |
| `seed`, `origin` | real, vec2 | Sorteados no início (com fixtures: 1 e o centro) |
| `running` | bool | Sai no `dump` |

**Estados:** `idle` → (`set`) → `running` → (fim) → `idle`. Um `set` com `running` reinicia a partir da
tela atual.

## Tom da barra (emenda da US6, `WallpaperStore.toneMix`)

| Campo | Tipo | Notas |
|---|---|---|
| `toneMix[monitor]` | real 0..1 | O que a barra daquele monitor mostra agora: 0 = tom papel, 1 = tom claro. Escrito pelo `Wallpaper` do monitor; lido pelo `Hud` |
| `toneOf(id)` | 1 / 0 / −1 | Tom de destino: cena `kind: "dark"` → 1; outras cenas → 0; imagem → `luma` < 0,45 ? 1 : 0; −1 = imagem ainda não medida |
| `lumas[chave]` | real 0..1 | No `WallpaperCatalog`. Chave = `"1:"` (filtro ligado) ou `"0:"` (desligado) + o caminho. Média de 0,2126 R + 0,7152 G + 0,0722 B (sRGB/255) da faixa de cima (altura da barra + 12 px lógicos) da imagem como aparece |

**Regras:**
- **Parado:** `toneMix` = `toneOf(item na tela)`; se for −1, segura o valor que tinha.
- **Transição:** `toneMix` = `de + (para − de) × smoothstep(topProgress)`; `de` é o `toneMix` quando a
  transição começou; `para` desconhecido (−1) = `de`.
- **`instant`** (fixtures, movimento reduzido): sem transição, então troca na hora.

## Picker (estado do seletor, `WallpaperPicker`)

| Campo | Tipo | Notas |
|---|---|---|
| `open` | bool | |
| `screen` | nome da saída | Onde abriu (o monitor em foco) |
| `focus` | `"list"` / `"options"` | Duas colunas (padrão da 003) |
| `index` | int | Item em foco na lista (pula os títulos de grupo) |
| `option` | int | 0 Monitor, 1 Transition, 2 Paper filter (só imagens) |
| `monitor` | int | 0 = All monitors, depois as saídas em ordem. Só do seletor: volta pra 0 a cada abertura. No `wallpaper dump` sai o rótulo (`All monitors` ou a saída) |

## Settings (acréscimos, `services/Settings.qml`)

| Campo | Tipo | Padrão | Validação |
|---|---|---|---|
| `reduceMotion` | bool | false | — |
| `wallpaperFolder` | string | `~/Pictures/Wallpapers` | `~` expandido; pasta inexistente = grupo vazio com aviso (caso de borda) |
| `wallpaperTransition` | string | `camouflage` | Como `Transition.kind` |
| `camouflage` | `{ cell, trail, glitch }` | `{ 24, 2600, 2 }` | Como `Transition` |
| `barContrast` (emenda (2)) | `"normal"` / `"high"` | `"normal"` | Fora da lista → padrão + aviso. O popup (Appearance › Bar contrast) troca e salva no estado (`shell.barContrast`), que vale mais |

**Configurações salvas** (emenda (3)): `$XDG_STATE_HOME/rien-os/settings.json`,
`{ "version": 1, "values": { "<chave>": valor } }`; ver `contracts/settings-state.md`.

## Fixture (domínio novo `wallpaper`)

```json
{
  "wallpaper": {
    "folder": "fixtures/wallpapers",
    "all": "scene:menu",
    "monitors": {},
    "transition": { "kind": "camouflage", "cell": 24, "trail": 2600, "glitch": 2 }
  }
}
```

Com o domínio ativo:
- o catálogo lê a pasta da fixture (relativa ao `shell/`);
- a escolha e a transição vêm dela;
- **nada é escrito** no arquivo de estado;
- as trocas são instantâneas.
