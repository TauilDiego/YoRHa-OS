# Contrato: componentes (008)

Interface pública das peças novas e dos acréscimos às da 001, 003 e 004. Vem antes da fase paralela
e **fica estável durante ela** (princípio VI); mudar uma interface exige atualizar este arquivo antes.
Valem as regras da 001: `property real s: 1`; cores, fontes, medidas e tempos só via `Tokens`; textos
fixos só via `Strings`; cada camada importa só as de baixo.

Medidas em px do jogo (1080p), vezes `s`, tiradas do mockup aprovado
(`YoRHa-OS-private/lab/mockups/transmissoes/index.html`).

## Tokens novos (`Tokens.notify`)

| Campo | Valor | Uso |
|---|---|---|
| `band` | `#1E1D19` a 84% | Tinta da faixa |
| `bandDot` | `#000000` a 32%, passo 5, raio 0,9 | Retícula |
| `bandText`, `bandText2` | `#E6E1C8`; o mesmo a 62% | Texto claro; hora, `×N`, contorno do × |
| `bandLine` | `#E6E1C8` a 14%, 2 px | Arcos finos |
| `bandEdge` | `#E6E1C8` a 10%, 1 px | Contorno interno (legível sobre o fundo escuro) |
| `bandShadow` | 3, `#000000` a 22% | Sombra chapada |
| `block` | 14 | Bloco da urgência |
| `stackW`, `stackGap`, `stackRight`, `stackTop` | 540, 12, 16, 12 (abaixo da barra) | Corner |
| `topPad` | 360 | Top band: coluna do texto (margem dos lados) |
| `subtitleW`, `subtitleBottom` | 1100, 210 | Subtitle |
| `critMinH`, `critCol`, `critSide` | 230, 1080, 62 | Faixa crítica |
| `imageSize` | 72 | Imagem |
| `actionH`, `maxActions` | 32, 3 | Botões |
| `lines`, `critLines` | 4, 3 | Corte do corpo |
| `osdW`, `osdH`, `osdBottom`, `osdMeterW` | 600, 72, 110, 300 | OSD |
| `bandTrack` | `#D7D1B3` a 22% | Trilha do progresso e do medidor do OSD (emenda de 2026-10-29) |
| `cps`, `typeMaxMs` | 90, 700 | Digitação (`motion`) |
| `lowMs`, `normalMs`, `perCharsMs`, `maxMs`, `osdHold` | 4000, 6000, 1000 / 80 car. além de 120, 12000, 1200 | Tempos (FR-007, FR-029) |
| `sweep`, `fade` | `motion.highlight` (150), 150 | Entrada e saída |

Tipografia (papéis novos em `Tokens.type`): `bandWho` 17/600/2, `bandTitle` 23/600/0,5, `bandBody`
19/500/0,5 (linha 1,5), `bandTime` 16/500/1,5, `bandAction` 16/600/1, `bandTag` 13/600/2, `critWho` 20,
`critTitle` 30, `critBody` 23, `osdLabel` 20/600/3, `osdValue` 23/500/1 (algarismos tabulares).

**Emenda de 2026-10-29 (decisão do dono):** o medidor sobre a faixa (o progresso da transmissão e o
do OSD) é a trilha translúcida do mockup (`Tokens.notify.bandTrack`, `#D7D1B3` a 22%, a altura do
`hp-bar`) com o preenchimento `light-yellow`, e não o `Meter` invertido da 003: sobre a tinta da
faixa, o `Meter` (trilha de papel opaca) pesava demais. A FR-028 e o caso de borda "Progresso" da spec
("medidor invertido") ficam valendo por essa trilha.

## Primitivas (`shell/ds/primitives/`)

| Componente | Propriedades | Notas |
|---|---|---|
| `Band` (novo) | `arcs: bool`, `block: color` (ou transparente), `shadow: bool` | O material da faixa: tinta, retícula (um `Image` de ladrilho 5×5 gerado uma vez, `fillMode: Tile`, sem shader), contorno interno, arcos (`Shape` estático, só com `arcs`), bloco de 14 à esquerda. Nada anima |

## Base (`shell/ds/base/`)

| Componente | Propriedades | Sinais | Notas |
|---|---|---|---|
| `TypedText` (novo) | `text` (styled), `from: int`, `instant: bool`, `maxLines`, `role` (papel tipográfico), `color` | `done()` | `shown`, `typing` (só leitura); `complete()`. Uma `NumberAnimation` (R8); cursor de bloco só durante a digitação; corta em `maxLines` com reticências |
| `ActionButton` (novo) | `text`, `enabled`, `on: bool` | `clicked()` | Contorno claro de 2 px, `bandAction`; mouse por cima ou `on`: a tinta clara varre da esquerda (`sweep`) e o texto fica escuro; `enabled: false` → 35% |
| `Tag` (novo) | `text`, `fill: color`, `outline: bool` | — | A etiqueta `CRITICAL` (fundo `alert`) e a `NEW` (contorno de 1,5) |
| `ListItem` (acréscimo) | `lead: string`, `tag: string`, `markColor: color` | — | `lead`: texto em peso 600 antes do rótulo (até 150, reticências); `tag`: `Tag` com contorno antes do `trailing`; `markColor`: cor do quadradinho (padrão: a do texto). Vazios = como antes |
| `Meter` | sem mudança | — | Não entra na faixa: o progresso e o OSD usam a trilha translúcida do mockup (emenda acima) |

## Compostos (`shell/ds/composites/`)

| Componente | Propriedades | Sinais | Notas |
|---|---|---|---|
| `Transmission` (novo) | `entry` (objeto do data-model), `speaker`, `count`, `layout`: `"corner"` / `"top"` / `"subtitle"` / `"preview"`, `instant`, `typeFrom`, `remainingFrac` (0–1), `paused`, `replying` | `typedOut()`, `clicked(button)`, `closeClicked()`, `actionClicked(id)`, `replyOpened()`, `replySent(text)`, `replyCancelled()`, `hoverChanged(bool)` | A faixa + quem fala (quadradinho, nome, `×N`, `Tag CRITICAL`, hora; × no lugar da hora com o mouse), título, `TypedText`, imagem (à direita), progresso (trilha translúcida `bandTrack` + preenchimento `light-yellow` + número), ações (`ActionButton`, até 3), campo de resposta (só com `replying`), linha de tempo. `"preview"`: sem linha de tempo, sem ×, corpo até 9 linhas (meio do log) |
| `CriticalBand` (novo) | `entries`, `page`, `instant` | `pageStepped(dir)`, `closeClicked(id)`, `actionClicked(id, action)` | Largura do monitor, coluna centrada de 1080, `1/N` com ◂ ▸, ×, arcos |
| `OsdView` (novo) | `kind`, `value`, `muted`, `meter: bool`, `label` | — | Faixa 600×72: quadradinho, rótulo (168), medidor de 300 na trilha translúcida (apagado a 35% no mudo), número à direita |
| `TransmissionStack` (novo) | `items` (lista de `Transmission` do data-model), `position`, `topInset` (abaixo da barra ou da crítica), `bottomInset` (área do OSD), `overflow: int` | `overflowClicked()` | Posiciona as transmissões nas 3 posições (FR-004) e a linha `+N in log`; troca de posição sem animação (FR-041); as outras deslizam com `sweep` |
| `GroupedList` (acréscimo) | itens com `lead`, `tag`, `markColor` | — | Repassa pro `ListItem` |
| `PickerLayout` (acréscimo) | `fluid: bool` (padrão `false`), `lazyList: bool` (padrão `false`); opções `{ id, label, type: "toggle" }` (valor 0/1) e `{ id, label, type: "action", text }` | `triggered(int option)` | `fluid`: colunas e topo a partir de `width`/`height`, nas proporções do quadro de 1612 × 908 (research R16). `lazyList`: a lista cria só as linhas à vista (o log de 100–200 entradas, SC-005). Opção `toggle`: ←/→ e Enter trocam 0/1. Opção `action`: valor = `text` + ▸; Enter ou clique → `triggered`; ←/→ não mudam nada; rodapé `Enter <text>`. Padrões antigos: a 004 não muda. **Emenda de 2026-10-29:** os nomes (`triggered`, toggle 0/1, o rodapé) são os da branch `007-menu-de-pausa`, que fez o mesmo acréscimo em paralelo, pra as duas terem a mesma interface no merge |

## Superfícies (`shell/notify/`, pasta nova)

| Componente | Propriedades | Sinais | Notas |
|---|---|---|---|
| `NotifyLayer` | `screen` | — | `PanelWindow` por monitor (R9): `TransmissionStack` + `CriticalBand` do monitor, `mask` = caixas visíveis, teclado `OnDemand` só com `replying`. Expõe `dumpBoxes()` |
| `OsdWindow` | `screen`, `position` | — | `PanelWindow` do tamanho do OSD, sem input (R9) |
| `LogPage` | `s`, `host`: `"popup"` / `"pause"`, `active: bool` | `closeRequested()` | O corpo do log (FR-044): `PickerLayout { fluid: true }` com a `GroupedList` (NOW/EARLIER), `LogPreview` no meio, opções `Do not disturb`/`Show`/`Clear all` e as informações `UNREAD`, `KEPT`, `SERVER`. Expõe `title` (`LOG`), `subtitle` (`-Transmissions`), `footerLeft`, `keys`, `dumpState()`, `restart()`. Teclas da data-model (Enter ação padrão, Delete dispensa) |
| `LogPreview` | `entry`, `s` | `actionClicked(id)` | `Card` com `mark` (quem fala), a `Transmission` `"preview"` digitando de novo ao trocar de entrada, a frase de estado e APP/RECEIVED/URGENCY/STATUS |
| `LogPopup` | `screen`, `keyboardActive` | `closeRequested()` | `PopupWindow` (003) + `LogPage` (`host: "popup"`); título, subtítulo, rodapé e teclas vêm da página |
| `LogCounter` (`shell/hud/`) | `tone`, `s` | `clicked()` | `LOG 3` / `DND 3` antes do relógio (FR-025), escondido com 0 não lidas e sem DND; segue o tom da barra (004 US6) |

**Pra a 007 (aba do menu de pausa):** a aba usa `LogPage { host: "pause"; s; width; height }` no corpo
do menu e lê `title`/`subtitle`/`footerLeft`/`keys` dela; abrir a aba faz `NotifyStore.logOpen = true`
e `markAllRead()`. Nada mais da 008 precisa mudar.

## Galeria

Página nova (Tab três vezes): a faixa nas três urgências; transmissão com ações, com imagem, com
progresso, com `×N`, com resposta aberta, digitando (quadro parado na metade); a faixa crítica com
`1/2`; o OSD (volume, mudo, microfone, brilho); a pilha nas três posições em miniatura; a `LogPage`
em dois tamanhos (o corpo do popup e o corpo do menu de pausa, SC-016); o contador da barra nos dois
tons.
