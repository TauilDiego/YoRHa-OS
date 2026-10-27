# Contrato: componentes (003)

É a interface pública das peças novas e dos acréscimos às da 001. Ela vem antes da fase paralela e
**fica estável durante ela** (princípio VI). Mudar uma interface exige atualizar este arquivo
primeiro.

As regras da 001 continuam:
- `property real s: 1` em todo componente;
- cores, fontes, medidas e tempos só via `Tokens`;
- textos fixos só via `Strings`;
- cada camada só importa as de baixo (tokens → primitives → base → composites → superfícies).

## Tokens novos (`shell/ds/Tokens.qml`)

| Grupo | Campo | Valor | Uso |
|---|---|---|---|
| `color` | `dim` | `#141310` a 55% | Escurecimento atrás do popup (FR-003) |
| `shadow` | `popup` | 6 | Sombra chapada do painel, em tinta (`darkGray`): a `boxShadow` clara viraria brilho sobre o escurecimento |
| `space` | `popupShare` | 0.84 | Fração da tela ocupada pelo painel (FR-002) |
| `space` | `popupW`, `popupH` | 1612, 908 | Quadro de desenho do painel, em px do jogo (research R5) |
| `space` | `settingsCatsW`, `settingsOptsW`, `settingsCardW` | 330, 560, 460 | Larguras das três colunas |
| `space` | `stepperValueW` | 190 | Largura do texto entre ◂ e ▸ |
| `space` | `sliderW` | 220 | Trilha do slider |
| `motion` | `popupFade` | 150 | Fade de abertura (FR-006) |
| `motion` | `actionBusy` | 2000 | Duração do aviso de ação (FR-016) |
| — | `reduced`, `instant` | `false`; `frozen \|\| reduced` | Movimento reduzido (`Settings.reduceMotion`, ligado no `shell.qml`): o fade do popup e o blink da pipa ficam instantâneos, como com fixtures (caso de borda) |

## Base (`shell/ds/base/`)

| Componente | Propriedades | Sinais | Notas |
|---|---|---|---|
| `ValueStepper` (novo) | `text`, `ink` (cor), `arrows: bool`, `atStart: bool`, `atEnd: bool` | `stepped(int dir)` | `◂ valor ▸`. As setas (11×16, como no mockup) só aparecem com `arrows`; a da ponta fica a 30%. Clique numa seta → `stepped(-1/+1)` |
| `Meter` (acréscimos) | `editable: bool` (padrão false), `inverted: bool` (padrão false) | `picked(real value)` | `editable`: clique ou arraste na trilha → `picked(0–1)`. `inverted`: trilha `mediumGray`, preenchimento `lightYellow` (sobre a faixa de tinta). O resto da 001 não muda |
| `KeyHints` (novo) | `model`: lista de `{ key, label }` | — | Fileira alinhada à direita: caixa de tinta com a tecla + rótulo `small`. Caixa de 34×30·s no mínimo (8·s de folga dos lados), 12·s até o rótulo, 34·s entre itens (medidas do mockup) |
| `ListItem` (acréscimo) | `reserve: real` (padrão 0, px) | — | Espaço à direita que o pai ocupa com um valor (o `OptionRow`); o rótulo corta com reticências antes dele. Com 0, nada muda |
| `Selector`, `Card`, `PageHeader`, `Rule` | sem mudança de interface | — | A pipa clara da coluna sem foco já sai do `ListItem` em `selected` (research R9). O blink usa `Tokens.instant` |

## Compostos (`shell/ds/composites/`)

| Componente | Propriedades | Sinais | Notas |
|---|---|---|---|
| `CursorList` (acréscimos) | `focused: bool` (padrão true), `wrap: bool` (padrão false), `keysEnabled: bool` (padrão true) | os da 001 + `hoveredIndex(int index)` | `focused: false` → item atual em `selected` (faixa + trilhos + pipa clara parada). `wrap` faz `move()` dar a volta nas pontas. Com `keysEnabled: false` o pai conduz a lista: ela não trata o teclado e não mexe no `currentIndex` sozinha (hover e clique só avisam, por `hoveredIndex` e `activated`) |
| `OptionRow` (novo) | `option` (objeto do catálogo, ver data-model), `value`, `dimmed: bool`, `focused: bool`; `hovered` (só leitura) | `stepped(int dir)`, `picked(real value)`, `activated()` | `ListItem` `plain` + o valor do tipo (research R10). `focused` → faixa de tinta + pipa escura. `dimmed` → estado `dimmed` da 001; não emite `stepped`/`picked`. `dimmed` + `focused` → a faixa e a pipa, com o texto claro a 55% (como no mockup) |
| `OptionList` (novo) | `options`, `values` (mapa id → valor), `dims` (mapa id → bool), `currentIndex`, `focused: bool` | `hoveredIndex(int i)`, `stepped(int i, int dir)`, `picked(int i, real value)`, `activated(int i)` | Coluna de `OptionRow` que rola junto com o foco quando não cabe. Sem faixas verticais (como no mockup) |
| `DescriptionCard` (novo) | `title`, `text`, `note`, `noteKind`: `"alert"` / `"info"`, `meta`: lista de `{ label, value }` | — | `Card` da 001 com o corpo do mockup: descrição (`standard`, peso 500), aviso (`alert` ou tinta), linhas `DEFAULT`/`NOW` ou `SETTINGS` embaixo |

## Superfícies

| Componente | Onde | Propriedades | Sinais | Notas |
|---|---|---|---|---|
| `PopupWindow` (novo) | `shell/popup/PopupWindow.qml` | `screen`, `keyboardActive: bool`, `title`, `subtitle`, `footerLeft`, `keys` (modelo do `KeyHints`), `default property` (o corpo); `s`, `panel` (só leitura) | `dismissed()` | `PanelWindow` `Overlay` na tela inteira, transparente (namespace `rien-popup`): escurecimento + painel centrado de `popupShare` (research R1). Expõe `s` = o menor entre altura do painel / `popupH` e largura / `popupW`, × `uiScale` (em 16:10 a altura sozinha faria o quadro de 1612 vazar pros lados; a sobra vai pra altura, e o rodapé fica colado embaixo). O corpo ocupa o painel inteiro, em px do painel. Clique no escurecimento → `dismissed()`. Fade de `popupFade` na entrada (instantâneo com `Tokens.instant`); com `keyboardActive: false` some na hora e deixa os cliques passarem. Desenho em `PopupFrame` (mesma pasta), que a galeria mostra em miniatura. **Reutilizável:** a spec 004 usa pro seletor de papel de parede |
| `SettingsPage` (novo) | `shell/settings/SettingsPage.qml` | `s`, `category` (índice, entra e sai), `keys` (só leitura, pro rodapé) | `closeRequested()` | O corpo: categorias (`CursorList`, `wrap`), cabeçalho da coluna de opções (nome + contagem), `OptionList`, `DescriptionCard`. É o dono do foco de duas colunas (research R8) e expõe `dumpState()` e `restart()` (volta pras categorias ao reabrir) |
| `SettingsPopup` (novo) | `shell/settings/SettingsPopup.qml` | `screen`, `keyboardActive`, `category` | `closeRequested()` | `PopupWindow` com título `SYSTEM`, subtítulo `-Settings`, a versão à esquerda do rodapé e `SettingsPage` dentro; repassa `dumpState()`. O `shell.qml` guarda a `category` entre aberturas |

## Layout do painel (px do jogo, quadro de 1612 × 908)

| Peça | x | y | Largura | Notas |
|---|---|---|---|---|
| Título `SYSTEM -Settings` | 48 | 42 | — | `PageHeader` |
| Régua lisa | 48 | 112 | painel − 96 | `Rule plain` |
| Legenda `CATEGORIES` | 118 | 136 | — | `small`, `mediumGray` |
| Faixas verticais + categorias | 48 / 118 | 170 | 330 | `CursorList` (a pipa usa os 39 px antes do item) |
| Nome da categoria + contagem | 518 | 136 | — | `small`; nome em tinta, contagem em `mediumGray` |
| Opções | 518 | 170 | 560 | `OptionList`; a pipa fica nos 39 px antes |
| Quadro de descrição | 1104 | 170 | 460 | `DescriptionCard`, altura mínima 360 |
| Régua do rodapé | 48 | 820 | painel − 96 | `Rule plain` |
| Versão | 48 | 846 | — | `small`, `mediumGray` |
| Teclas | direita − 48 | 846 | — | `KeyHints` |

As réguas e o rodapé (y ≥ 820) se medem a partir de baixo do painel (altura − 88 em px do jogo):
quando o painel é mais alto que 908·s (telas 16:10), a sobra fica entre as colunas e o rodapé.
As listas começam no y 170 com os itens (os trilhos ficam 7 px acima).
