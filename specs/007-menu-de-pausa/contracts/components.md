# Contrato: componentes QML (007)

Todos recebem `s` (o fator da superfície) quando têm medida. Cores do `Tokens`, textos do `Strings`.
Medidas em px do jogo no quadro de 1612 × 908 da moldura (research R12).

## Acréscimos em peças existentes

| Componente | Acréscimo | Comportamento |
|---|---|---|
| `PopupFrame` (003) | `tabs` (`[{ label }]`, padrão `[]`), `tab` (int), `clock` (bool), `tabClicked(int)`, `bodyTop` (leitura, px lógicos) | Com `tabs` vazio, nada muda (o seletor da 004 continua igual). Com abas: `TabBar` em y 26 (a aba `tab` em `selected`, as outras `normal`/`hovered`, sem pipa), título em 127 com `Clock.dateText` e `timeText` à direita quando `clock`, régua lisa em 189, `bodyTop` = 221. A aba nova faz a haste até a régua (`motion.touch`; instantânea com `Tokens.instant`) |
| `PopupWindow` (003) | repassa `tabs`, `tab`, `clock`, `tabClicked`, `bodyTop` | — |
| `PickerLayout` (004) | `top` (game px, padrão 150), `searchHeader` (`{ query, count }` ou `null`), `emptyText`; opções com `type`: `choice` (padrão, como hoje), `toggle`, `action`; sinal `triggered(int option)` | `action`: rótulo + seta (`OptionRow` tipo ação); Enter ou clique → `triggered`; → não faz nada e ← volta pra lista. `toggle`: `◂ ON ▸`, como na 003. O `Esc` da lista continua emitindo `closeRequested()` (a página decide). Teclas que não usa continuam sem `accepted` (Tab, letras) |
| `GroupedList` (004) | `search` (`{ query, count }` ou `null`), `emptyText` | Com `search`: no lugar dos títulos de grupo, o cabeçalho de busca (`SearchHeader`) no alto; sem itens, a linha `emptyText` em `medium-gray` |
| `SettingsPage` (003) | `top` (game px, padrão 170), `extraKeys` (lista acrescentada ao rodapé) | Na aba SYSTEM: `top` = 221, `extraKeys` = `["Tab Next tab"]`. Fora isso, igual à 003 |
| `SettingsModel` (003) | ver contracts/services.md | — |

## Novos no design system (`shell/ds/`)

| Componente | Onde | Propriedades | Sinais / funções | Comportamento |
|---|---|---|---|---|
| `SearchHeader` | `composites/` | `query`, `count`, `s` | — | `SEARCH` (`small`, tinta) + a consulta numa caixa `light-yellow` com o cursor de texto piscando (parado com `Tokens.frozen`) + `N RESULTS` à direita (`small`, `medium-gray`). Linha de 30 px |
| `AppIcon` | `base/` | `source` (caminho), `style` (`ink`/`color`/`square`), `size` (game px), `s` | — | `ink`: `ShaderEffect` com `shaders/duotone.frag.qsb` (tinta → `light-yellow` pela luminância, × alfa); sem o `.qsb`, `MultiEffect` colorizado, com um aviso uma vez. `color`: `Image`. `square`: o `Square` da 001 no tamanho do ícone. `source` vazio → o ícone genérico da categoria (passado pela página) |
| `WorkspaceMap` | `composites/` | `monitor` (`{ name, w, h }`), `bar` (altura lógica da barra), `windows` (`[{ address, x, y, w, h, title, focused }]`), `selected` (address), `s` | — | Contorno de 2 px `medium-gray` na proporção do monitor, dentro da área de 512 × 288 (letterbox); a faixa da barra em `light-gray`; cada janela um retângulo `light-gray` com contorno `dark-gray` de 1 px, na escala; a escolhida em tinta (`dark-gray`) com o título em `light-yellow` (`small`, cortado). Vazio: só o contorno e a faixa |
| `StatusCard` | `composites/` | `title`, `rows` (`[{ label, value, meter }]`, `meter` 0–1 ou `null`), `boxes` (int, padrão 6), `note` (string), `s` | — | O "card de status" do §4: `Card` com `mark`; pares rótulo (tinta) / valor (à direita, tabular), com um `Meter` de 150 × 11 quando `meter`; régua `light-gray`; a fileira de quadrados vazios (22 px, borda 2 px `medium-gray`); o rodapé centralizado `NO ERROR` (`small`, espaçamento 3) ou `note` em `alert` |
| `ConfirmDialog` | `composites/` | `title`, `text`, `note` (`alert`), `blockers` (`[{ who, why }]`), `actionLabel`, `start` (`cancel`/`action`), `s`; `row` (leitura: `action`/`cancel`) | `confirmed()`, `cancelled()`; `geometry()` | Sobre o painel: tinta `color.dim` no painel inteiro (clique nela = `cancelled`); no centro, `Card` de 760 com `mark`, o título, o texto (23 px), os bloqueios em `alert` (`who: why`), duas `OptionRow` de ação (`actionLabel`, `Cancel`) a 420 de largura, a pipa em `start`, e o rodapé próprio (`↑↓ Select` `Enter Confirm` `Esc Cancel`). ↑↓ andam dando a volta; Enter confirma a linha (em `Cancel` = `cancelled`); Esc = `cancelled`. Pega as teclas enquanto aberto |

## Novos no menu (`shell/pause/`)

| Componente | Propriedades | Sinais / funções | Comportamento |
|---|---|---|---|
| `PauseMenu` | `screen`, `keyboardActive`, `tab` (id), `phase` | `closeRequested()`, `tabChanged(string)`; `setTab(id)`, `search(text)`, `dumpState()`, `restart()` | `PopupWindow` com `tabs` (R15), `clock: true`, o título/subtítulo/rodapé/teclas da página aberta. Um `Loader` por aba, criado na primeira visita e mantido até fechar; só a aberta visível e com o foco. Raiz `FocusScope`: Tab/Backtab trocam (dando a volta), texto imprimível vai pra `AppsPage.type(text)` na aba APPS. `tabClicked` troca. `dismissed` (clique fora) → `closeRequested`. Monta o `pause dump` |
| `AppsPage` | `s`, `top`, `iconStyle`, `order`, `runningApp` | `closeRequested()`; `type(text)`, `backspace()`, `clear()`, `dumpState()`, `keys`, `footerLeft` | `PickerLayout` com a lista de `Apps` (grupos ou busca), a prévia (`Card` com `mark`: `AppIcon` de 160 game px no centro de uma área de 512 × 288 `light-gray`, o nome no título e a descrição), as opções (`Open` ação, as ações do app, `Workspace` escolha `Current`/`01`–`10`, `Pinned` liga/desliga) e as informações (`CATEGORY`, `COMMAND`, `WINDOWS`). Backspace apaga; o Esc da lista limpa a busca, ou fecha. Enter/`Open` → `Apps.launch`, menu fecha. `Running app = Go to window` e o app com janela: Enter vai pra janela mais recente dele (`Compositor.focusWindow`) |
| `WindowsPage` | `s`, `top` | `closeRequested()`; `dumpState()`, `keys`, `footerLeft` | `PickerLayout` com os grupos por área de trabalho, a prévia (`Card` com o `WorkspaceMap` e o título inteiro embaixo), as opções (`Focus` ação, `Workspace` 01–10, `Floating` liga/desliga, `Close` ação) e as informações (`APP`, `MONITOR`, `SIZE`). Abre na janela em foco. A pipa segue a janela pelo `address` quando a lista muda; se ela some, vai pra vizinha (a de baixo, ou a de cima no fim) e, se as opções estavam abertas, o foco volta pra lista. Sem janelas: `No open windows.` e o mapa vazio da área atual |
| `PowerPage` | `s`, `top`, `confirmMode`, `dialogStart` | `closeRequested()`; `dumpState()`, `keys`, `footerLeft` | `GroupedList` sem grupos com as 6 ações (as indisponíveis `dim`), o `DescriptionCard` (nome, o que faz, `effect`, o motivo ou o erro em `alert`) na coluna do meio e o `StatusCard` (`USER`, `HOST`, `UPTIME`, `BATTERY` com medidor, `WINDOWS`) na da direita, nas posições da `PickerLayout`. Enter: ação apagada → nada; que confirma → `ConfirmDialog`; senão → `Session.run`. Relê `Session.refresh()` ao entrar na aba |

A aba SYSTEM é a `SettingsPage` da 003, com `top` e `extraKeys` (acima).

## Galeria (FR-033)

Uma página nova da galeria (a 4ª, Tab três vezes), carregada só enquanto aparece:
- o `PopupFrame` com abas em miniatura, em cada aba selecionada e com uma `hovered`;
- o `SearchHeader` com consulta e o estado sem resultado (a `GroupedList` com `emptyText`);
- o `AppIcon` nos três estilos, com um ícone da fixture e sem ícone (genérico);
- o `WorkspaceMap` vazio, com janelas e com a escolhida em tinta;
- o `StatusCard` com `NO ERROR` e com aviso;
- o `ConfirmDialog` com a pipa em `Cancel` e na ação.

## Reaproveitados (sem cópia, FR-032)

| De | Componente | Uso |
|---|---|---|
| 001 | `TabBar`, `HeaderButton`, `PageHeader`, `Card`, `Rule`, `Square`, `Meter`, `Label` | Moldura, prévias, status |
| 003 | `PopupFrame`/`PopupWindow`, `CursorList` (sem foco, blink), `OptionRow`, `ValueStepper`, `DescriptionCard`, `KeyHints`, `SettingsPage`, a regra das duas colunas | Moldura, SYSTEM, POWER, diálogo |
| 004 | `PickerLayout`, `GroupedList`, `Card.mark`, `contentScale` | APPS, WINDOWS, POWER |
