---
description: "Tarefas da 003: configurações num popup"
---

# Tasks: Configurações num popup

**Input**: `specs/003-settings-popup/` (plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md)

**Tests**: a spec não pede testes automatizados. A prova de cada tarefa é a evidência da VM
(princípio IV): screenshot, `qs ipc call settings dump` que responde, teclas reais via QMP e log de
QML sem erro, sempre dentro de `lab/perf begin/end`.

**Caminhos**:
- `shell/…` = repositório público `nier-os`;
- `lab/…` = repositório privado `rien-OS-private`, irmão do público
  (`~/projects/rien-OS-private/lab/`).

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: história da spec (US1 abrir e fechar, US2 navegar, US3 mudar valores)

---

## Phase 1: Setup (laboratório)

**Purpose**: o atalho na VM e os ajudantes de teste que o roteiro da 003 precisa.

- [x] T001 [P] `lab/guest/hyprland.lua`: `hl.bind("ALT + I", hl.dsp.exec_cmd("qs -p ~/nier/ui ipc call settings toggle"))`, ao lado dos atalhos ALT que já existem (research R4); `lab/sync` leva a config pra VM das camadas `teste-*` — feito pela sessão principal (commit `4997d2f`, `lab-u1`; também `ALT + W` da 004). O `lab/sync` leva o `hyprland.lua` pras `teste-*` e recarrega o Hyprland
- [x] T002 [P] Criar `lab/click x y [vm]`: move o ponteiro pra (x, y) em px lógicos da tela e clica com o botão esquerdo via QMP (`input-send-event` abs + btn), a partir do trecho que hoje está dentro do `lab/check-u1`; o `check-u1` passa a usar o `lab/click` — feito pela sessão principal (`4997d2f`): `lab/click x y [--move] [--right]`; o `check-u1` já usa
- [x] T003 [P] Criar `lab/burst <x,y wxh> <n> <pasta>`: captura `n` quadros seguidos da região com `grim -g` dentro da VM, numa pasta temporária, e traz pro host com `tar` pelo ssh, em ordem (research R13); o loop roda dentro da VM pra os quadros saírem a ~30 ms — feito pela sessão principal (`4997d2f`), com a assinatura `lab/burst N MS ["x,y WxH"|full] [nome]` (N quadros a cada MS ms; 0 = o mais rápido). Na `lab-003` ganhou o `times.txt` (a hora de cada quadro na VM), pra medir o blink (SC-005)
- [x] T004 Criar o esqueleto de `lab/check-003` copiando a estrutura do `lab/check-u1` (pasta de evidência, `ok`/`ko`, `ipc`, `shot`, `log_after_launch`), ainda sem cenários; `shellcheck` (Docker `koalaman/shellcheck:stable`) limpo em T002–T004 — `lab/check-003 [--only 1,4,7] [pasta]`; `shellcheck` limpo em `click`, `burst` e `check-003`
- [x] T005 Documentar T001–T004 em "Uso no dia a dia" de `lab/README.md` — as linhas do `click`, do `burst` e dos atalhos vieram da sessão principal; acrescentei o `check-003` e o `times.txt`

**Checkpoint**: atalho e ajudantes prontos.

---

## Phase 2: Foundational (contrato)

**Purpose**: o contrato que todas as histórias usam. **⚠️ Depois do T012, as interfaces de
`contracts/` ficam congeladas.**

- [x] T006 `shell/ds/Tokens.qml`: os tokens novos de contracts/components.md (`color.dim`, `space.popupShare`/`popupW`/`popupH`/`settingsCatsW`/`settingsOptsW`/`settingsCardW`/`stepperValueW`/`sliderW`, `motion.popupFade`/`actionBusy`) — mais `shadow.popup` (6, em tinta) e `reduced`/`instant` (movimento reduzido), registrados no contracts/components.md. Sessão `2026-10-27T153155-vm-teste-a-003-contrato-tokens-textos-catalogo-sett`
- [x] T007 [P] `shell/strings/Strings.qml`: grupo `settings` em inglês: `title` "SYSTEM", `subtitle` "-Settings", `categories` "CATEGORIES", `count` "SETTINGS", `defaultLabel` "DEFAULT", `nowLabel` "NOW", `on` "ON", `off` "OFF", `version` "rien-OS 0.1 · Hyprland", os rótulos de tecla (`select` "Select", `open` "Open", `close` "Close", `change` "Change", `back` "Back") e `error` "Settings data unavailable."; mais os nomes das peças novas no grupo `gallery` — mais as teclas (`keyUpDown`, `keyRight`, `keyLeftRight`, `keyEnter`, `keyEsc`) e o `page2Subtitle` da galeria
- [x] T008 [P] `shell/fixtures/settings-default.json`: as 7 categorias e as 36 opções do data-model.md, com textos, valores e padrões do mockup (`rien-OS-private/lab/mockups/configuracoes/index.html`) e `needs` `{ "wifi": "Turn on Wi-Fi first.", "bt": "Turn on Bluetooth first." }`; válido contra `contracts/settings.schema.json` (checar num container) — 36 opções; validado contra o schema num container (`archlinux` + `python-jsonschema`, label `nier-lab`), na sessão do T012
- [x] T009 [P] `shell/fixtures/settings-broken.json` (`hud-default.json` + `"settings": "fixtures/does-not-exist.json"`) e `shell/fixtures/settings-long.json` (`hud-default.json` + `"settings": "fixtures/settings-catalog-long.json"`), com `shell/fixtures/settings-catalog-long.json`: uma categoria com 14 opções e rótulos e valores longos — o catálogo longo tem também uma categoria vazia (`Empty`), pro caso "pode ser vazia" do data-model
- [x] T010 `shell/services/SettingsModel.qml` (singleton, + `qmldir`): a interface completa de contracts/services.md. Carrega o catálogo (`FileView`; o domínio `settings` da fixture troca o caminho) e preenche `categories`/`error`; os outros membros existem com a lógica mínima (`value` lê do catálogo, `step`/`activate`/`pick`/`reset` vazios, `dumpValues` real) — já com a lógica inteira (a frente C foi feita na sequência, ver T021) e `dimmedIds()` pro `dump`
- [x] T011 `shell/services/Compositor.qml`: `focusedMonitor` (do `hyprctl monitors -j`, campo `focused`) e `refreshFocusedMonitor()`, que refaz a consulta; com fixtures, o primeiro de `Quickshell.screens` (contracts/services.md) — feito pela sessão principal (commit `0bf600e`), junto com `Settings.reduceMotion`
- [x] T012 `shell/shell.qml`: `property bool settingsOpen`, o fechamento em duas fases da galeria aplicado ao popup (research R2), um `LazyLoader` com um `PanelWindow` vazio de marcação e o `IpcHandler` `settings` com `open`, `close`, `toggle`, `isOpen`, `dump` (com `open`, `monitor`, `values` reais e o resto vazio) e `reset` (contracts/ipc.md). Verificar na VM (`lab/perf begin "003: contrato"`): 0 erros e 0 avisos; `settings dump` responde; `qmllint` limpo. **Congela o contrato** — a abertura espera a releitura do monitor (`Compositor.monitorScalesChanged`, com um fallback de 250 ms). Evidência: sessão `2026-10-27T153155-vm-teste-a-003-contrato-tokens-textos-catalogo-sett`: `settings dump` responde (7 categorias, `monitor` `Virtual-1`), `open`/`toggle`/`isOpen`/`reset` ok, a janela de marcação aparece em `hyprctl layers` (`rien-popup`), log do último carregamento com 0 erros e 0 avisos, `qmllint` limpo

**Checkpoint**: contrato congelado. As três frentes podem começar.

---

## Phase 3: Frentes paralelas (peças compartilhadas)

**Purpose**: as peças que as histórias montam. Uma frente por agente, cada um com worktree e VM
(`teste-a`, `teste-b`, `teste-c`).

### Frente A: design system

- [x] T013 [P] `shell/ds/base/ValueStepper.qml`: `◂ valor ▸` com as propriedades e o sinal de contracts/components.md; setas de 10×14·s, texto `standard` peso 500 centrado em `stepperValueW`; seta da ponta a 30% — setas de 11×16 como no mockup (a tarefa dizia 10×14). Verificado na página 2 da galeria (Tab), sessão `2026-10-27T154318-vm-teste-a-003-frentes-a-e-b-na-galeria-pagina-2`
- [x] T014 [P] `shell/ds/base/KeyHints.qml`: fileira alinhada à direita, caixa de tinta 34×30·s com a tecla (`button`, `lightYellow`) + rótulo `small` — caixa mínima 34×30, 12 até o rótulo e 34 entre itens, como no mockup (o contrato dizia 30). Sessão `2026-10-27T154318-vm-teste-a-003-frentes-a-e-b-na-galeria-pagina-2`
- [x] T015 [P] `shell/ds/base/Meter.qml`: `editable` (`MouseArea` na trilha → `picked(x/largura)`, também ao arrastar) e `inverted` (cores do contrato); a 001 continua igual com os padrões — clique na trilha leva o valor pro ponto clicado (conferido no screenshot: o preenchimento termina sob o ponteiro). Sessão `2026-10-27T154318-vm-teste-a-003-frentes-a-e-b-na-galeria-pagina-2`
- [x] T016 [P] `shell/ds/composites/CursorList.qml`: `focused` (sem foco → item atual `selected`), `wrap` (move dá a volta) e `keysEnabled` (desliga `Keys.onUp/Down/Return` quando o pai cuida do teclado) — mais o sinal `hoveredIndex`; com `keysEnabled: false` o pai conduz hover e clique (contracts/components.md). Sessão `2026-10-27T154318-vm-teste-a-003-frentes-a-e-b-na-galeria-pagina-2`
- [x] T017 [P] `shell/ds/composites/DescriptionCard.qml`: `Card` com `text` (`standard` 500, quebra de linha), `note` (`alert` ou tinta, conforme `noteKind`) e `meta` (linhas `small`: rótulo `mediumGray`, valor peso 600) no pé do corpo — título com o quadrado claro do mockup sobre a faixa do `Card`; linhas a 1,5 × o tamanho (`FixedHeight`, como o CSS); a descrição corta com reticências quando não cabe. Sessão `2026-10-27T154318-vm-teste-a-003-frentes-a-e-b-na-galeria-pagina-2`
- [x] T018 `shell/ds/composites/OptionRow.qml` (depois de T013 e T015): `ListItem` `plain` + o valor do tipo à direita (research R10), cor clara quando `inked`, `dimmed` bloqueia `stepped`/`picked` — `ListItem.reserve` (novo) faz o rótulo cortar antes do valor; apagada + em foco = faixa e pipa com o texto claro a 55%. Sessão `2026-10-27T154318-vm-teste-a-003-frentes-a-e-b-na-galeria-pagina-2`
- [x] T019 `shell/ds/composites/OptionList.qml` (depois de T018): `Flickable` + `Column` de `OptionRow`, `contentY` acompanha o item em foco com a pipa sempre visível; sinais de contracts/components.md — `rowAt(i)` pra geometria do `dump`. Rolagem validada no T030

### Frente B: moldura de popup

- [x] T020 [P] `shell/popup/PopupWindow.qml`: `PanelWindow` `Overlay` nas quatro bordas, transparente, `exclusionMode: Ignore`, `keyboardFocus` Exclusive/None por `keyboardActive`; escurecimento (`Tokens.color.dim`) com `MouseArea` → `dismissed()`; painel centrado de `popupShare` com papel, `Vignette` (se `Settings.vignette`), sombra chapada, `PageHeader` (`title`/`subtitle`), régua de cima, régua do rodapé, `footerLeft`, `KeyHints`(`keys`) e o corpo; `s` = altura do painel / `popupH` × `uiScale`; fade de `popupFade` na entrada, instantâneo com `Tokens.frozen` (research R1, R2, R5, R11) — o desenho ficou em `popup/PopupFrame.qml` (a galeria mostra em miniatura); `s` = o menor entre altura/908 e largura/1612 (em 16:10 a altura sozinha vazava pros lados); sombra do painel em tinta (`shadow.popup`); ao fechar, some na hora e uma `Region` vazia deixa os cliques passarem. Validado na US1, sessão `2026-10-27T154645-vm-teste-a-003-us1-abrir-e-fechar-por-cima-do-deskt`

### Frente C: serviço

- [x] T021 [P] `shell/services/SettingsModel.qml`: a lógica de contracts/services.md e data-model.md: `step`, `activate`, `pick` por tipo; `isDimmed`/`needsText` por `key`/`needs`; `busy` com `Timer` de `motion.actionBusy`; `display`/`defaultDisplay`; `reset`; catálogo inválido → `error` + `console.warn`. Verificar pelo IPC numa VM, chamando as funções por um alvo de teste temporário (removido no fim da tarefa) — 25 checagens por um alvo IPC temporário (removido): toggle, choice sem dar a volta nas setas e dando a volta no Enter, slider por passo/clique/limites, dependências wifi/bt, ação com aviso que some em 2 s, informação inerte, reset; catálogo ausente → `error` + WARN com o motivo. Sessão `2026-10-27T154033-vm-teste-a-003-frente-c-logica-do-settingsmodel-por` (saída em `out/003-t021-settingsmodel.txt`)

**Checkpoint**: peças prontas. As histórias podem começar.

---

## Phase 4: User Story 1 - Abrir e fechar por cima do desktop (Priority: P1) 🎯 MVP

**Goal**: o popup abre no monitor em foco, escurece o resto, recebe o teclado e fecha pelos três caminhos.

**Independent Test**: cenários 1, 4 e 7 do quickstart (abrir em ≤ 0,3 s; dois screenshots iguais;
fechar pelo atalho, Esc e clique fora, com a janela ativa de volta).

- [x] T022 [US1] `shell/settings/SettingsPopup.qml`: `PopupWindow` com `title`/`subtitle`/`footerLeft` do `Strings.settings`, `screen` vindo do `shell.qml`, `dismissed()` → `closeRequested()`; corpo provisório (só o título) até a US2 — sessão `2026-10-27T154645-vm-teste-a-003-us1-abrir-e-fechar-por-cima-do-deskt`
- [x] T023 [US1] `shell/shell.qml`: trocar a janela de marcação pelo `SettingsPopup`; `open()` chama `Compositor.refreshFocusedMonitor()` e escolhe a `ShellScreen` com esse nome (research R3); o monitor fica fixo enquanto aberto; `dump` com `monitor` real — a abertura espera a releitura do monitor (ver T012). Sessão `2026-10-27T154645-vm-teste-a-003-us1-abrir-e-fechar-por-cima-do-deskt`
- [x] T024 [US1] Esc no corpo provisório → `closeRequested()`; confirmar que o atalho (`lab/key alt-i`) alterna — sessão `2026-10-27T154645-vm-teste-a-003-us1-abrir-e-fechar-por-cima-do-deskt`
- [x] T025 [US1] `lab/check-003`: cenários 1, 4 e 7 do quickstart. Validar no lab (`lab/perf begin "003: US1"`): os três passam e o log fica sem erro e sem aviso de QML — `lab/check-003 --only 1,4,7,9`: 8 PASS. Abre em 45 ms (na VM, da tecla até a camada mapear); com o popup aberto, um `touch` digitado não chega no kitty; fecha pelos 3 caminhos e o `touch` digitado depois chega (teclado de volta); 2 shots iguais. Log: 0 erros e 0 avisos de QML, mais 1 WARN `qt.qpa.wayland.textinput` por abertura: bug do Qt 6.12.0 (`QWaylandInputContext::setFocusObject` desabilita o text-input de uma janela que ele nunca habilitou; corrigido no `dev` do Qt), que o `check-003` conta à parte. Sessão `2026-10-27T154645-vm-teste-a-003-us1-abrir-e-fechar-por-cima-do-deskt`, evidência `out/check-003-us1`

**Checkpoint**: o popup abre e fecha direito.

---

## Phase 5: User Story 2 - Navegar como num menu do jogo (Priority: P1)

**Goal**: as três colunas do mockup, o foco de duas colunas, a pipa com blink, o quadro e o rodapé.

**Independent Test**: cenários 2, 3, 5 e 8 do quickstart (7 categorias em 1080 e hidpi; sequência de
teclas com o `dump` a cada passo; quadros do blink).

- [x] T026 [US2] `shell/settings/SettingsPage.qml`: layout de contracts/components.md (legenda `CATEGORIES`, `CursorList` com `wrap` e `keysEnabled: false`, nome + contagem da categoria, `OptionList`, `DescriptionCard`), lendo do `SettingsModel`; `SettingsPopup` passa a usá-la como corpo — colunas rebalanceadas pra 300/600/440 (com 560, "Background motion" e outros rótulos do mockup saíam cortados; o quadro ficava a 24 px das opções); contrato e research R5 atualizados. Sessão `2026-10-27T155247-vm-teste-a-003-us2-navegar-como-num-menu-do-jogo`
- [x] T027 [US2] `SettingsPage`: estado de foco e teclas da FR-010 num `FocusScope` (`Keys.onPressed`); `focused` das duas colunas; ↑/↓ nas categorias troca as opções na hora; abrir de novo volta pras categorias na categoria em que estava (data-model) — reabrir antes do descarregamento também volta pras categorias (`restart`). Sessão `2026-10-27T155247-vm-teste-a-003-us2-navegar-como-num-menu-do-jogo`
- [x] T028 [US2] `SettingsPage`: mouse (FR-011): hover move o foco e a coluna; hover em categoria troca as opções; clique em categoria vai pras opções — o hover só move o foco quando o ponteiro se move de verdade: o Qt reenvia hover a itens que surgem sob um ponteiro parado (o popup abrindo, as linhas de outra categoria depois de ↑↓) e isso roubava o foco do teclado. Um `HoverHandler` na própria página marca o movimento e a decisão fica pra depois do evento (`Qt.callLater`); um item por cima bloqueava o hover das linhas. Testado com `lab/click --move` e ponteiro parado sobre as opções. Sessão `2026-10-27T155247-vm-teste-a-003-us2-navegar-como-num-menu-do-jogo`
- [x] T029 [US2] `SettingsPage`: quadro (FR-014) e rodapé (FR-015) conforme o foco; `SettingsPopup.keys` vem da página; `dumpState()` completo (`focus`, `category`, `option`, `keys`, `card`, `dimmed`) e ligado ao `settings dump` — `dump` com `geometry` (s, painel, item em foco, controle do valor) pros cliques dos testes. Sessão `2026-10-27T155247-vm-teste-a-003-us2-navegar-como-num-menu-do-jogo`
- [x] T030 [US2] Caso de borda da coluna longa: `settings-long.json` rola com a pipa sempre visível e corta com reticências; erro do catálogo mostra `Strings.settings.error` no quadro — a coluna tem altura de linhas inteiras e rola de linha em linha (sem linha cortada embaixo do cabeçalho); rótulos de lista sempre cortam com reticências na borda da faixa (`ListItem`); categoria vazia sem "→ Open". Corrigidos: o `Flickable` desfazia o binding do `contentY`, e a primeira chamada de `follow()` com `pitch` 0 deixava `scrollY` em NaN. Sessão `2026-10-27T155247-vm-teste-a-003-us2-navegar-como-num-menu-do-jogo`
- [x] T031 [US2] `lab/check-003`: cenários 2, 3, 5, 8 e 11. Validar no lab (`lab/perf begin "003: US2"`) em 1080 e hidpi — `lab/check-003 --only 2,3,5,8,9,11`: 15 PASS em `out/check-003-us2`. 1080 e hidpi: popup centrado a 84%; escurecimento conferido pixel a pixel na faixa do HUD (= 0,45·fundo + 0,55·tinta, desvio ≤ 0,9 de 255: sem desfoque); régua e faixa sem meio pixel no hidpi; SC-003 passo a passo; SC-005 blink entre 169 e 237 ms pelos quadros (`times.txt`), a antiga some antes da nova aparecer e a pipa clara não muda; movimento reduzido (`shell.json` do usuário, com reinício do shell) só pula. Sessão `2026-10-27T155247-vm-teste-a-003-us2-navegar-como-num-menu-do-jogo`

**Checkpoint**: a tela navega de ponta a ponta.

---

## Phase 6: User Story 3 - Mudar valores (Priority: P2)

**Goal**: os cinco tipos de opção mudam pelo teclado e pelo mouse, com dependências e ações.

**Independent Test**: cenário 6 do quickstart (uma mudança de cada tipo, por tecla e por clique,
conferida no `dump` e no screenshot).

- [x] T032 [US3] `SettingsPage`: ←/→/Enter e cliques ligados ao `SettingsModel` (`step`, `activate`, `pick`), com "← numa linha que não muda volta pras categorias"; `OptionList` recebe `values` e `dims` do modelo — já ligado na US2 (teclas e cliques chamam `step`/`activate`/`pick`). Sessão `2026-10-27T161514-vm-teste-a-003-us3-mudar-valores`
- [x] T033 [US3] Quadro: `DEFAULT`/`NOW`, aviso de dependência (`needsText`, `alert`) e aviso de ação (`busy`, tinta) que some sozinho — aviso de dependência em `alert`, aviso de ação em tinta (`noteKind`). Sessão `2026-10-27T161514-vm-teste-a-003-us3-mudar-valores`
- [x] T034 [US3] Fechar e abrir mantém os valores; reiniciar o shell (`lab/ssh 'pkill -x qs'`) volta ao catálogo (FR-018) — conferido no cenário 6: fechar e abrir mantém Night light/Scale/Brightness; depois de `pkill -x qs` voltam a OFF/1.25×/70. Sessão `2026-10-27T161514-vm-teste-a-003-us3-mudar-valores`
- [x] T035 [US3] `lab/check-003`: cenário 6. Validar no lab (`lab/perf begin "003: US3"`) — `lab/check-003 --only 6,9`: 5 PASS em `out/check-003-us3` (passo a passo em `sc006-steps.txt`). Sessão `2026-10-27T161514-vm-teste-a-003-us3-mudar-valores`

**Checkpoint**: as três histórias funcionam.

---

## Phase 7: Polish & validação final

- [x] T036 [P] `shell/gallery/Gallery.qml`: `ValueStepper` (meio, início, fim), `Meter` editável e invertido, `KeyHints`, `OptionRow` nos 5 tipos × normal/em foco/apagada, `DescriptionCard` com e sem aviso, `CursorList` sem foco; nomes no `Strings.gallery` (FR-024, SC-008) — na página 2 da galeria (Tab), com amostras tiradas do próprio catálogo (sem duplicar textos no `Strings`); a moldura aparece em miniatura (`PopupFrame`). Feita junto com a frente A, que ela serviu de banco de teste (sessão `2026-10-27T154318-vm-teste-a-003-frentes-a-e-b-na-galeria-pagina-2`); o cenário 10 do `check-003` passa nas duas rodadas da sessão `2026-10-27T161856-vm-teste-a-003-validacao-do-popup-de-configuracoes` (`gallery-p2.png`)
- [x] T037 [P] `docs/design-system.md`: as peças novas (linha de opção, seletor de valor, slider, quadro de descrição, rodapé de teclas, lista sem foco, moldura de popup) com medidas e estados — seção 7 nova, "Popup e configurações (spec 003)", antes dos créditos: tokens, moldura, lista sem foco, linha de opção (tipos × estados), seletor de valor, slider, quadro, rodapé de teclas e a regra do foco em duas colunas
- [x] T038 `lab/check-003`: cenários 9 e 10; rodar o quickstart inteiro (`lab/perf begin "003: validação" --kind 003-validacao --task 003`) em 1080 e hidpi — cenários 9 e 10 no `check-003`, mais `--profile 1080|hidpi`. Sessão `2026-10-27T161856-vm-teste-a-003-validacao-do-popup-de-configuracoes`: 1080 com 24 PASS mais os cenários 8–9 refeitos (4 PASS, blink ≈223 ms); hidpi com 23 PASS mais 8–9 refeitos depois de corrigir os recortes do teste, que eram em px lógicos e o `grim` devolve físicos (4 PASS, blink ≈263 ms). O blink passou a ser medido pelo ajuste das curvas de cada metade (InSine/OutSine): os limiares cortavam as pontas suaves. Evidência em `out/check-003-final-{1080,1080-s8,hidpi,hidpi-s8}`
- [x] T039 Corrigir o que o T038 apontar e repetir só os cenários afetados — o T038 apontou só falhas do roteiro, não da UI: a medição do blink e os recortes em px lógicos no hidpi. Corrigidas, e os cenários 8–9 repetidos nos dois perfis. Regressão da 001: `lab/check-u1` com 15 PASS / 0 FAIL na sessão `2026-10-27T162932-vm-teste-a-003-regressao-da-001-check-u1` (`out/check-u1-003`)
- [x] T040 Montar a imagem de revisão (screenshots dos cenários 2 e 3 lado a lado com o mockup) pra aprovação do dono (SC-009) e escrever `specs/003-settings-popup/relatorio.md` (o que ficou pronto com a evidência, o custo somado do `lab/perf`, os commits) — o mockup foi renderizado num container (`archlinux` + chromium headless, label `nier-lab`), só o stage 1920×1080, e posto ao lado do mesmo estado na VM em 1080 e hidpi, mais a galeria e as 7 categorias: `~/.local/share/nier-lab/out/003-revisao-sc009.png` (sessão `2026-10-27T163130-vm-teste-a-003-imagem-de-revisao-sc-009`). Relatório em [relatorio.md](relatorio.md), com o custo das 10 sessões (68,4 min, 707,6 s de CPU da VM)
- [x] T041 Rodar `/speckit-analyze` e resolver as inconsistências entre spec, plano e tarefas — 10 achados, nenhum crítico. As inconsistências foram corrigidas: status da spec e do plano, grid, movimento reduzido, quickstart, árvore do plano, data-model, domínio `settings` da fixture. Fica aberta a cobertura de dois monitores (o lab tem um monitor só). Tabela em [relatorio.md](relatorio.md#análise-t041-speckit-analyze). A VM foi desligada na sessão `2026-10-27T165434-vm-teste-a-003-desligar-a-vm-teste-a`

---

## Dependencies & Execution Order

- **Setup (Phase 1):** sem dependências. T001–T003 em paralelo; T004 depois de T002 e T003.
- **Contrato (Phase 2):** depende do Setup só pra verificação na VM. T007–T009 em paralelo; T010
  depois de T008; T012 fecha a fase e **congela o contrato**.
- **Frentes (Phase 3):** dependem do T012. As frentes A, B e C rodam em paralelo; dentro da A,
  T013–T017 em paralelo, T018 depois de T013 e T015, e T019 depois de T018.
- **US1 (Phase 4):** depende da frente B (T020).
- **US2 (Phase 5):** depende da US1 e das frentes A e C.
- **US3 (Phase 6):** depende da US2.
- **Polish (Phase 7):** T036/T037 dependem da frente A; T038–T041, de todas as histórias.

### Parallel Opportunities

- Phase 1: T001, T002 e T003.
- Phase 2: T007, T008 e T009.
- Phase 3: três agentes, cada um com worktree e VM:
  - `teste-a` com a frente A;
  - `teste-b` com a frente B;
  - `teste-c` com a frente C.
- Phase 7: T036 e T037.

## Parallel Example: Phase 3

```text
Agente 1 (worktree a, NIER_LAB_VM=teste-a): T013, T014, T015, T016, T017 → T018 → T019
Agente 2 (worktree b, NIER_LAB_VM=teste-b): T020
Agente 3 (worktree c, NIER_LAB_VM=teste-c): T021
```

## Implementation Strategy

### MVP primeiro (US1)

1. Phases 1 e 2 (laboratório e contrato).
2. Frente B (a moldura).
3. US1: o popup abre e fecha por cima do desktop escurecido. Parar e validar.

### Entrega incremental

1. US1: abrir e fechar (cenários 1, 4, 7).
2. Frentes A e C + US2: a navegação completa (cenários 2, 3, 5, 8, 11).
3. US3: os valores (cenário 6).
4. Polish: galeria, design system, validação final e revisão do dono.

## Notes

- Toda verificação fica dentro de `lab/perf begin/end`, e o resumo do relatório entra no relato da tarefa.
- Agentes commitam só nas branches dos seus worktrees; o merge na `003-settings-popup` é feito pela sessão principal.
- **Execução real (2026-10-27):** as frentes `[P]` da Phase 3 foram feitas em sequência por um agente
  só, numa VM só (`teste-a`), porque a RAM do host comporta uma VM por agente e a `teste-b` estava
  com a 004. A ordem e as dependências foram as mesmas.
- O `PopupWindow` é contrato da spec 004 também: mudar a interface dele depois do T012 exige atualizar
  `specs/003-settings-popup/contracts/components.md` e avisar a 004.
