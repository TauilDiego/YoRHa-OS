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
| `GroupedList` | `model` (lista com `{ group }` e itens `{ label, trailing, dim }`), `currentIndex`, `focused`, `s` | `activated(int index)` | `CursorList` da 001 com títulos de grupo (texto `small`, sem foco). A pipa e o blink vêm da `ListItem`/`Selector`; `focused: false` = estado "sem foco" da 003 (pipa clara, parada). Se a 003 der grupos à `CursorList`, este componente vira só um alias |
| `WallpaperPicker` | `screen` (a saída em foco) | `closeRequested()` | O seletor (FR-006–FR-009): moldura de popup da 003, título `WALLPAPER -Select`, `GroupedList` à esquerda, `Card` da prévia (nome, `WallpaperView` pequena, descrição), `Card` "Options" com linhas `Monitor`, `Transition` e `Paper filter` (só imagens) + informações (Type, Layers, Motion, Now on), rodapé de teclas. Duas colunas: lista ↔ opções (padrão da 003). `dump()` devolve o estado do data-model "Picker" |

**Emenda da US6 (2026-10-27): a barra sobre o fundo**

| Componente | Acréscimo | Comportamento |
|---|---|---|
| `WallpaperTransition` | `topProgress` (0..1, leitura), `band` (altura da faixa da barra, px lógicos) | Quanto da faixa da barra a transição em andamento já cobriu, com as mesmas contas do shader: camuflagem = fração das células da faixa já reveladas; varredura = borda ÷ largura; quadradinhos = fração dos quadradinhos das linhas da faixa já começados; crossfade = progresso. Sinal `begun()` quando uma transição começa |
| `WallpaperView` | `luma` (leitura, −1 até medir) | Imagem: quando fica pronta e não há medida guardada, mede a faixa de cima (`grabToImage` + `Canvas.getImageData`) e guarda no catálogo |
| `Wallpaper` | publica `WallpaperStore.setToneMix` | Parado: o tom do fundo na tela. Numa transição: `de + (para − de) × smoothstep(topProgress)`. Esperando a imagem nova ou a medida dela: segura o tom |
| `Label`, `Rule`, `HeaderButton`, `Meter`, `TabBar` (001) | `property real tone: 0` | Cores = `Tokens.hudColor(papel, tone)` (FR-028). Com 0, as cores de antes, sem conta |
| `Hud` (001) | `color: "transparent"`, sem `Rectangle` nem `Vignette` | Lê `WallpaperStore.toneMix[monitor]` e passa pros componentes; `dumpEntry()` ganha `tone`, `toneMix` e `texts` |

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
- a `GroupedList` nos estados com foco e sem foco.
