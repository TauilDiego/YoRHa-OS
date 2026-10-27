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
| `space` | `popupShare` | 0.84 | Fração da tela ocupada pelo painel (FR-002) |
| `space` | `popupW`, `popupH` | 1612, 908 | Quadro de desenho do painel, em px do jogo (research R5) |
| `space` | `settingsCatsW`, `settingsOptsW`, `settingsCardW` | 330, 560, 460 | Larguras das três colunas |
| `space` | `stepperValueW` | 190 | Largura do texto entre ◂ e ▸ |
| `space` | `sliderW` | 220 | Trilha do slider |
| `motion` | `popupFade` | 150 | Fade de abertura (FR-006) |
| `motion` | `actionBusy` | 2000 | Duração do aviso de ação (FR-016) |

## Base (`shell/ds/base/`)

| Componente | Propriedades | Sinais | Notas |
|---|---|---|---|
| `ValueStepper` (novo) | `text`, `ink` (cor), `arrows: bool`, `atStart: bool`, `atEnd: bool` | `stepped(int dir)` | `◂ valor ▸`. As setas só aparecem com `arrows`; a da ponta fica a 30%. Clique numa seta → `stepped(-1/+1)` |
| `Meter` (acréscimos) | `editable: bool` (padrão false), `inverted: bool` (padrão false) | `picked(real value)` | `editable`: clique ou arraste na trilha → `picked(0–1)`. `inverted`: trilha `mediumGray`, preenchimento `lightYellow` (sobre a faixa de tinta). O resto da 001 não muda |
| `KeyHints` (novo) | `model`: lista de `{ key, label }` | — | Fileira alinhada à direita: caixa de tinta com a tecla + rótulo `small`. 34×30·s por caixa, 30·s entre itens |
| `ListItem`, `Selector`, `Card`, `PageHeader`, `Rule` | sem mudança de interface | — | A pipa clara da coluna sem foco já sai do `ListItem` em `selected` (research R9) |

## Compostos (`shell/ds/composites/`)

| Componente | Propriedades | Sinais | Notas |
|---|---|---|---|
| `CursorList` (acréscimos) | `focused: bool` (padrão true), `wrap: bool` (padrão false) | os da 001 | `focused: false` → item atual em `selected` (faixa + trilhos + pipa clara parada). `wrap` faz `move()` dar a volta nas pontas. A lista não trata mais o teclado sozinha quando o pai define `keysEnabled: false` (novo, padrão true) |
| `OptionRow` (novo) | `option` (objeto do catálogo, ver data-model), `value`, `dimmed: bool`, `focused: bool` | `stepped(int dir)`, `picked(real value)`, `activated()` | `ListItem` `plain` + o valor do tipo (research R10). `focused` → faixa de tinta + pipa escura. `dimmed` → estado `dimmed` da 001; não emite `stepped`/`picked` |
| `OptionList` (novo) | `options`, `values` (mapa id → valor), `dims` (mapa id → bool), `currentIndex`, `focused: bool` | `hoveredIndex(int i)`, `stepped(int i, int dir)`, `picked(int i, real value)`, `activated(int i)` | Coluna de `OptionRow` que rola junto com o foco quando não cabe. Sem faixas verticais (como no mockup) |
| `DescriptionCard` (novo) | `title`, `text`, `note`, `noteKind`: `"alert"` / `"info"`, `meta`: lista de `{ label, value }` | — | `Card` da 001 com o corpo do mockup: descrição (`standard`, peso 500), aviso (`alert` ou tinta), linhas `DEFAULT`/`NOW` ou `SETTINGS` embaixo |

## Superfícies

| Componente | Onde | Propriedades | Sinais | Notas |
|---|---|---|---|---|
| `PopupWindow` (novo) | `shell/popup/PopupWindow.qml` | `screen`, `keyboardActive: bool`, `title`, `subtitle`, `footerLeft`, `keys` (modelo do `KeyHints`), `default property` (o corpo) | `dismissed()` | `PanelWindow` `Overlay` na tela inteira, transparente: escurecimento + painel centrado de `popupShare` (research R1). Expõe `s` (altura do painel / `popupH` × `uiScale`). Clique no escurecimento → `dismissed()`. Fade de `popupFade` na entrada. **Reutilizável:** a spec 004 usa pro seletor de papel de parede |
| `SettingsPage` (novo) | `shell/settings/SettingsPage.qml` | `s` | `closeRequested()` | O corpo: categorias (`CursorList`, `wrap`), cabeçalho da coluna de opções (nome + contagem), `OptionList`, `DescriptionCard`. É o dono do foco de duas colunas (research R8) e expõe `dumpState()` |
| `SettingsPopup` (novo) | `shell/settings/SettingsPopup.qml` | `screen`, `keyboardActive` | `closeRequested()` | `PopupWindow` com título `SYSTEM`, subtítulo `-Settings`, a versão à esquerda do rodapé e `SettingsPage` dentro |

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
