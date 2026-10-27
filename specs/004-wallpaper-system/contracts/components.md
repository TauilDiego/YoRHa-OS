# Contrato: componentes QML

Todos recebem `s` (o fator da superfície, como na 001) quando têm medida. As cores vêm do `Tokens`;
os textos, do `Strings`.

## Novos (`shell/wallpaper/`, `shell/ds/composites/`)

| Componente | Propriedades | Sinais / funções | Comportamento |
|---|---|---|---|
| `Scene` | `params` (objeto da cena), `s`, `phase` (0–1, do `shell.qml`) | — | Desenha papel + vinheta + arcos + feixes + réguas + trama conforme `params` (data-model). Com a cena parada, nada repinta. Linhas na grade física (como a 001) |
| `WallpaperView` | `wallpaper` (item do catálogo), `s`, `phase`, `screenSize` (px físicos), `paperFilter` (bool) | — | Cena → `Scene`. Imagem → `Image` com `PreserveAspectCrop`, `sourceSize` = `screenSize`, `asynchronous`, `cache: false`, e `PaperFilter` quando `paperFilter`. Vídeo → nada (não é aplicável) |
| `PaperFilter` | `source` (Item), `enabled` | — | `MultiEffect` com `colorization: 0.85` e `colorizationColor` = papel do centro, mais a `Vignette` da 001 por cima (R7) |
| `WallpaperTransition` | `current` (id), `screenSize`, `s`, `phase`, `kind`, `cell`, `trail`, `glitch`, `instant` | `running`, `elapsed`, `seed` (leitura) | Dois slots (`Loader` de `WallpaperView`). Quando `current` muda: se `instant` ou se não houver `.qsb` → troca seca (ou crossfade QML, sem shader); senão, `ShaderEffect` com `transition.frag.qsb` sobre dois `ShaderEffectSource` vivos (R2, R4). Na varredura, uma `Rule { kind: "dotted"; rotation: -90 }` acompanha a borda (R5). Troca no meio de outra parte da tela atual (FR-017) |
| `GroupedList` | `model` (entradas `{ group }`, `{ note }` e itens `{ label, trailing, dim }`), `currentIndex` (conta só os itens), `focused`, `wrap`, `keysEnabled`, `s` | `activated(int index)`, `hoveredIndex(int index)`, `itemAt(index)`, `itemData(index)` | Composto novo em `ds/composites/` (a `CursorList` da 003 não tem grupos), com as mesmas peças: faixas, `ListItem` e a pipa com o blink. Títulos `small` sem foco; `note` = aviso debaixo de um título; `dim` = item apagado que ainda recebe o cursor; marca à direita em `small`. `focused: false` = estado "sem foco" da 003 (pipa clara, parada). Rola por entradas inteiras, com o item atual sempre visível |
| `PickerLayout` | `entries`, `index`, `column` (`list`/`options`), `option`, `options` (`[{ id, label, values }]`), `values` (id → índice), `info` (`[{ label, value }]`), `s`; a prévia é a propriedade padrão | `applied(int index)`, `picked(int option, int value)`, `closeRequested()`; `keys`, `restart(i)`, `geometry()` | O composto "lista + prévia + opções" (FR-022, design-system §8), em `ds/composites/`: `GroupedList` à esquerda, a prévia no meio, o card "Options" com linhas de escolha e as informações à direita, a navegação em duas colunas e o rodapé de teclas por foco |
| `PreviewCard` | `wallpaper`, `s`, `phase`, `dpr`, `paperFilter` | — | `Card` com o nome, a `WallpaperView` pequena (cena viva a 512/1920; imagem decodificada no tamanho físico de 512 × 288, com o filtro; vídeo = "NOT YET") e a descrição |
| `WallpaperPicker` | `screen` (a saída em foco), `phase` | `closeRequested()` | O seletor (FR-006–FR-009): `PopupWindow` da 003 (título `WALLPAPER -Select`) com o `PickerLayout`: o catálogo por grupo com as marcas, o `PreviewCard` e as opções `Monitor`, `Transition` e `Paper filter` (só imagens) + informações (Type, Layers, Motion, Now on). `dumpState()` devolve o estado do data-model "Picker" |

## Reaproveitados

| De | Componente | Uso aqui |
|---|---|---|
| 001 | `Vignette` | Papel das cenas e filtro de papel |
| 001 | `Rule` (`dotted`) | Réguas da cena `rules` e borda da varredura |
| 001 | `PaperDecor` (refeito na US1) | Arcos e feixes da `Scene` |
| 001 | `CursorList`, `ListItem`, `Selector` | Base da `GroupedList` |
| 001 | `Card`, `PageHeader` | Prévia, opções, título |
| 003 | moldura de popup (escurecimento + papel + sombra) | `WallpaperPicker` |
| 003 | linha de opção + seletor de valor `◂ ▸` | Opções do seletor |
| 003 | rodapé de teclas | Rodapé do seletor |
| 003 | foco em duas colunas | Navegação lista ↔ opções |

Os nomes finais dos componentes da 003 são os do `contracts/components.md` dela. Este contrato só
depende do comportamento descrito na spec 003 (FR-010–FR-016, FR-024).

## Galeria (FR-022)

A galeria da 001 ganha uma seção "Wallpaper" com estas peças:
- as 4 cenas em miniatura (cena viva com `s` pequeno);
- uma imagem de teste com e sem filtro;
- um quadro congelado de cada transição. É a `WallpaperTransition` com `elapsed`/`progress` fixos e
  `seed = 1`: camuflagem em 700 ms (refração, mosaico e rastro visíveis), varredura em 50%,
  quadradinhos em 50% e crossfade em 50%;
- a `GroupedList` nos estados com foco e sem foco;
- o `PickerLayout` em miniatura, numa `PopupFrame` sobre a cena `menu`.

Fica na página 3 da galeria (Tab duas vezes), carregada só enquanto aparece.
