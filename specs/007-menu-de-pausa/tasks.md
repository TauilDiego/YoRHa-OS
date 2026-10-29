---
description: "Tarefas da 007: menu de pausa (U3)"
---

# Tasks: Menu de pausa

**Input**: `specs/007-menu-de-pausa/` (plan.md, spec.md, research.md, data-model.md, contracts/,
quickstart.md)

**Status**: plano e tarefas aprovados pelo dono (27.10; a T012a em 28.10). Fases 1–3 em andamento na `007-menu-de-pausa`; as frentes A, B e C saem depois da T022.

**Decisões do dono (28.10, depois da T022):** aceitas as quatro do agente: a altura das páginas é `startY` (o Qt recusa `top`); as quatro páginas são criadas junto com o menu; os ícones de teste de APPS são coloridos, pra o SC-013 provar a troca de estilo; a fixture de hibernação é `na`.

**Tests**: a spec não pede testes automatizados. A prova de cada tarefa é a evidência da VM
(princípio IV): screenshot, `qs ipc call pause dump`, teclas reais via QMP, `hyprctl … -j` e log de
QML sem erro, sempre dentro de `lab/perf begin/end`.

**Caminhos**:
- `shell/…`, `specs/…`, `docs/…` = repositório público `nier-os`;
- `lab/…` = repositório privado `rien-OS-private`, branch `lab-007`
  (`~/projects/rien-OS-private-wt/lab007/lab/`).

**VMs:** no máximo 4 ao mesmo tempo, cada uma com `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G` (limite do
dono). O contrato e a US1 usam a `teste-a`; as frentes usam `teste-a`, `teste-b` e `teste-c`. Se
outras rodadas estiverem com VMs, as frentes andam duas por vez.

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: vai pra um agente paralelo, com worktree e VM próprios (constituição VI). Nas fases 4–7,
  `[P]` quer dizer "em paralelo com as outras frentes"; **dentro de uma frente, a ordem é a dos IDs**.
- **[Story]**: história da spec (US1–US5).
- **Frentes:** **A** = APPS (worktree `nier-os-wt/impl007-apps`, branch `007-apps`, VM `teste-a`);
  **B** = WINDOWS (`impl007-janelas`, `007-janelas`, `teste-b`); **C** = POWER
  (`impl007-energia`, `007-energia`, `teste-c`). Todas saem da `007-menu-de-pausa` depois da T022.

---

## Phase 1: Setup (laboratório, spike e desenhos)

**Purpose**: o atalho na VM, a confirmação das APIs que o plano supõe e os ícones do projeto.

- [x] T001 Criar a worktree privada `~/projects/rien-OS-private-wt/lab007` (branch `lab-007`, saindo da `lab-004-acab`) e, em `lab/guest/hyprland.lua`, acrescentar `hl.bind("ALT + Escape", hl.dsp.exec_cmd("qs -p ~/nier/ui ipc call pause toggle"))`, mantendo o `ALT + I` (research R3)
- [x] T002 [P] Criar o esqueleto do `lab/check-007` no padrão do `lab/check-004` (`ok`/`ko`, pasta de evidência, `summary.txt`, `--only us1|apps|windows|power|live|gallery`, os dois perfis por `lab/profile`, VM deixada em 1080), com blocos marcados por frente (`# --- 007 frente A: início/fim` etc.), o ajudante que abre `kitty --title A|B|C` em duas áreas de trabalho e devolve os endereços (`hyprctl clients -j`), e o `lab/guest/rien-test.desktop` do SC-009; documentar na seção "Uso no dia a dia" do `lab/README.md` (sem VM)
- [x] T003 **Spike na VM** (`lab/perf begin "007: spike"`, `teste-a`, 2 núcleos, 4 GB): com duas janelas `kitty`, conferir por `lab/ipc 'hyprctl dispatch …'` as expressões do research R8 (`hl.dsp.focus({ window = "address:…" })` numa janela de outra área: troca de área?; `hl.dsp.window.move({ workspace = 2, follow = false, window = … })`; `hl.dsp.window.float({ action = "toggle", window = … })`; `hl.dsp.window.close({ window = … })`); a saída de `busctl --json=short call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate` e `ListInhibitors` (com um `systemd-inhibit --what=shutdown --mode=block sleep 60` rodando); o sinal `Lock` em `busctl monitor org.freedesktop.login1` depois de `loginctl lock-session`; `uwsm check is-active`; e um QML de rascunho (em `lab/mockups/desktop-spike/`, privado) mostrando que `DesktopEntries.applications` ganha um `.desktop` copiado pra `~/.local/share/applications/` em ≤ 2 s. Registrar os resultados no `research.md` (R4, R8, R9). **Se uma expressão não existir com esse nome, ajustar só a tabela do R8 antes da T012; se o `DesktopEntries` não acompanhar, parar e levar ao dono**
- [x] T004 [P] Desenhar os ícones do projeto (SVG só de traço, 64 × 64, tinta `#4E4B42`, sem nada de terceiros): os ≈16 glifos genéricos do mockup em `shell/fixtures/pause/icons/` (terminal, browser, files, editor, mail, chat, music, video, image, pdf, settings, monitor, radio, wave, game, code) e os 8 genéricos de categoria em `shell/assets/icons/category-{system,network,media,office,dev,graphics,game,other}.svg` (sem VM)

**Checkpoint**: o atalho existe na VM, as APIs supostas estão confirmadas e os desenhos prontos.

---

## Phase 2: Foundational (contrato)

**Purpose**: as interfaces de [contracts/](contracts/) que todas as frentes usam, e os arquivos
compartilhados (textos, tokens, fixtures, catálogo, `shell.qml`) prontos de uma vez.
**Uma sessão só, em sequência, na `teste-a`** (tarefas pequenas, mexendo em arquivos que as frentes
vão usar). **⚠️ Depois da T018, os contratos ficam congelados.**

- [x] T005 `shell/strings/Strings.qml`: grupo `pause` com todo texto fixo da spec, em inglês (FR-028): rótulos, títulos e subtítulos das abas; textos do rodapé (`%1 apps · type to search`, `%1 windows · %2 workspaces`, `Up %1`); teclas (`Next tab`, `Open`, `Options`, `Clear`, `Focus`, `Actions`, `Confirm`, `Cancel`); grupos (`PINNED`, `ALL APPS`, `WORKSPACE %1`, `SPECIAL`); busca (`SEARCH`, `%1 RESULTS`, `No apps match.`, `Check the spelling, or search by what the app does.`); `No open windows.`; as linhas de opção e de informação de APPS e WINDOWS; as 6 ações de POWER com descrição, efeito (`%1 open windows will close.`, `The session stays as it is.`), motivos (`Not supported on this machine.`, `Not allowed.`) e títulos de diálogo (`Shut down?`…); o status (`USER`, `HOST`, `UPTIME`, `BATTERY`, `WINDOWS`, `NO ERROR`); os erros curtos de fixture ausente
- [x] T006 `shell/ds/Tokens.qml`: `space.pauseTabsY` 26, `pauseRuleY` 83, `pauseTitleY` 127, `pauseHRuleY` 189, `pauseBodyY` 221 (research R12), `confirmW` 760, `confirmRowsW` 420, `appIconSize` 160, `mapW` × `mapH` 512 × 288, `statusMeterW` 150, `statusBox` 22
- [x] T007 Fixtures (data-model, "Fixtures"): `shell/fixtures/pause-default.json` (os domínios da `hud-default.json` + `apps`, `windows`, `session`), `shell/fixtures/pause/apps.json` (≈30 apps do mockup, com nomes, nomes genéricos, palavras-chave e comandos que cubram as 10 consultas do SC-004, ações em Firefox e kitty, 4 fixados, usos, ícones da T004, `kitty` com o comando real `["kitty"]`, um app com comando inexistente), `windows.json` (o monitor `Virtual-1` 1920 × 1080, 7 janelas em 3 áreas + 1 na especial, uma flutuante, uma em foco), `session.json` (Hibernate `no`, um inibidor `block` de `shutdown` do `pacman`), e as de borda `pause-empty.json`, `pause-long.json` (+ `pause/apps-long.json`, `pause/windows-long.json` com dois monitores), `pause-broken.json`, `pause-live.json` (sem `windows` e `session`) e `pause/session-refuse.json`. Validar todos contra `contracts/pause-fixtures.schema.json` num container (`python-jsonschema`, label `nier-lab`), dentro do `lab/perf`
- [x] T008 `shell/config/defaults.json` + `shell/services/Settings.qml`: a chave `terminal` (padrão `["kitty"]`; lista não vazia de strings, senão o padrão + aviso)
- [x] T009 Catálogo e opções (research R10): em `shell/fixtures/settings-default.json`, a categoria `menu` depois de `appearance`, com as 5 escolhas e os `desc` de contracts/services.md; em `shell/services/SettingsModel.qml`, `choiceId(catId, optId)` e a validação de `ids` no `problemOf`; em `specs/003-settings-popup/contracts/settings.schema.json`, a propriedade opcional `ids`. **Antes:** conferir na `004-wallpaper-system` como o `Bar contrast` ficou; se ele guardou o valor entre sessões, usar o mesmo mecanismo aqui (e registrar no research R10)
- [x] T010 `shell/services/Apps.qml` (singleton, no `services/qmldir`) com a interface inteira de contracts/services.md e a lógica de fixture: lê o domínio `apps`, `listed("az")`, `byId`, `count`, `error`; `search` devolve `[]` e `launch` só registra `lastLaunch` até a frente A
- [x] T011 `shell/services/Session.qml` (singleton, no `qmldir`) com a interface inteira e a lógica de fixture: `actions` e `status` do domínio `session` (com `confirm` lido de `SettingsModel.choiceId("menu", "confirm")`), `dryRun = Fixtures.active`, `run` registrando `lastAction` (e respondendo recusa pras ids de `refuse`), sinais `accepted`/`refused`
- [x] T012 `shell/services/Compositor.qml`: `windows`, `workspaceList`, `monitorList`, `windowsRevision`, `focusWindow`, `moveWindow`, `toggleFloating`, `closeWindow` e `lastWindowAction`, com a lógica de fixture (domínio `windows`, mudanças em memória); sem fixture, listas vazias até a frente B
- [x] T012a Adaptador do compositor (contracts/compositor.md, proposta de 28.10): dividir o `shell/services/Compositor.qml` em fachada + `shell/services/compositor/HyprlandBackend.qml` sem mudar comportamento; `NullBackend.qml`; escolha por `NIER_COMPOSITOR` / `HYPRLAND_INSTANCE_SIGNATURE` / `NIRI_SOCKET` / `XDG_CURRENT_DESKTOP` num `Loader`; `backendName` e `capabilities` na fachada e no `pause dump`; `Window.id` (com `address` como sinônimo). Prova: `check-u1` 15/0, `check-003` 25/0 e `check-004` 58/0 como antes, 0 px nas imagens de referência, e com `NIER_COMPOSITOR=none` a barra abre com 0 erros de QML
- [x] T013 `shell/popup/PopupFrame.qml` + `PopupWindow.qml`: `tabs`, `tab`, `clock`, `tabClicked(int)` e `bodyTop` (contracts/components.md, research R12). `TabBar` em y 26 sem pipa, a haste até a régua em `motion.touch` (instantânea com `Tokens.instant`), título em 127 com a data e a hora à direita, régua em 189. Sem `tabs`, o desenho de hoje (o seletor da 004 não pode mudar: `lab/check-004`, bloco do seletor, continua passando)
- [x] T014 `shell/ds/composites/SearchHeader.qml` (novo) + `GroupedList.qml` (`search`, `emptyText`) + `PickerLayout.qml` (`startY`, `searchHeader`, `emptyText`, opções `toggle`/`action`, `triggered(int)`), sem mudar o comportamento de hoje com os padrões
- [x] T015 `shell/settings/SettingsPage.qml`: `startY` (padrão 170) e `extraKeys` (acrescentadas ao `keys`)
- [x] T016 `shell/pause/PauseMenu.qml` (esqueleto) + `shell/pause/AppsPage.qml`, `WindowsPage.qml`, `PowerPage.qml` (só `keys`, `footerLeft`, `dumpState()` e um `Label` com o nome, nas assinaturas do contrato) + a `SettingsPage` na aba SYSTEM; em `shell/shell.qml`, o `LazyLoader` do `PauseMenu` no lugar do `SettingsPopup` (abrindo no monitor em foco e fechando em duas fases, como hoje), o `IpcHandler` `pause` com todas as funções de contracts/ipc.md, o `settings` como alias (R2) e a regra de um popup por vez com o seletor da 004; apagar `shell/settings/SettingsPopup.qml`
- [x] T017 `docs/design-system.md`: registrar no §7 que a moldura ganhou a variante com abas (a seção completa vem na T045), pra o contrato congelado ter referência no design system
- [x] T018 Verificar na VM (`lab/perf begin "007: contrato"`, `teste-a`, fixture `pause-default.json`): carrega com 0 erros e 0 avisos de QML; `ALT + Escape` abre o esqueleto em APPS, Tab troca, `pause tab power`/`dump`/`isOpen`/`reset`/`search` respondem; `settings dump` mantém o formato da 003; `wallpaper picker open` fecha o menu; o `lab/check-004` (bloco do seletor) passa; `qmllint` limpo dentro da VM. **Congela o contrato**

**Checkpoint**: contrato congelado. A US1 pode começar.

---

## Phase 3: User Story 1 - Abrir o menu e trocar de aba (Priority: P1) 🎯 MVP

**Goal**: o menu abre por `ALT + Escape` (e `ALT + I` em SYSTEM), troca de aba por Tab, Shift+Tab e
clique, fecha pelos três caminhos e devolve o teclado; SYSTEM já é a página da 003 inteira.

**Independent Test**: com `pause-default.json`, abrir pelos dois atalhos e por IPC, trocar de aba
pelos três jeitos, um screenshot por aba, fechar pelos três caminhos, conferindo `pause dump` e a
janela em foco do compositor (SC-005).

- [x] T019 [US1] `shell/pause/PauseMenu.qml` completo: a lista de abas (R15); Tab/Backtab dando a volta, o clique e o `hovered` nas abas (FR-004); `lastTab` pela sessão; a pipa guardada por aba enquanto aberto e as regras de abertura da FR-006; o título, o rodapé e as teclas da aba (com `Tab Next tab`); texto imprimível encaminhado à APPS (R13); fechar por `closeRequested` das páginas, clique fora, `pause toggle` e o `SUPER + I` em SYSTEM; nada anima com `Tokens.instant`; `dumpState()` no formato do contrato
- [x] T020 [US1] Aba SYSTEM: a `SettingsPage` com `startY` = `bodyTop` + 34 e `extraKeys`, o rodapé à esquerda com a versão, e o alias `settings` lendo dela (`dump` no formato da 003, `isOpen` só em SYSTEM); a categoria `Pause menu` aparece e muda valores
- [x] T021 [US1] `lab/check-003` adaptado à aba SYSTEM (research R2): abre por `ALT + I`/`settings open`, as checagens de teclas e valores ficam iguais, as de geometria leem o `settings dump`, e as imagens de referência são refeitas; roda inteiro em 1080 e hidpi
- [x] T022 [US1] Validar (`lab/perf begin "007: US1"`, `teste-a`): bloco `us1` do `lab/check-007` com o cenário 5 do quickstart (SC-005: tempo de abertura, a sequência de teclas, os três fechamentos com o kitty voltando ao foco), o cenário 2 nas 4 abas (SC-002) e um shot por aba nos dois perfis; `lab/check-003` passando; log sem erro nem aviso. **Depois disso, as frentes A, B e C saem desta branch**

**Checkpoint**: MVP: um menu navegável com SYSTEM funcionando e as outras abas vazias.

**Evidência das fases 1–3 (28.10, `teste-a`):** `lab/perf` `2026-10-27T215958-vm-teste-c-007-spike`
(T003), `2026-10-28T160804-vm-teste-a-007-auditoria-do-wip-resgatado` (auditoria, T012a: `check-u1`
15/0, `check-003` 25/0 em 1080 e hidpi, `check-004` 58/0 antes e depois, 14 imagens de referência
com 0 px de diferença, fixtures válidas no schema num container) e `2026-10-28T170024-vm-teste-a-007-us1`
(T022: `check-007 --only us1,compositor` 16/0, `check-u1` 15/0, `check-003` 25/0, VM com 4 núcleos).

---

## Phase 4: User Story 2 - Abrir um app pela aba APPS (Priority: P1) — frente A

**Goal**: o launcher: lista com PINNED e ALL APPS, busca ao digitar, prévia com o ícone no estilo
escolhido, opções do app, Enter abre e fecha o menu.

**Independent Test**: com o catálogo de teste, as 10 consultas do SC-004 por `pause search`; com
teclas reais, `ALT + Escape`, `k i t`, Enter abre um kitty de verdade em ≤ 2 s (SC-003).

- [x] T023 [P] [US2] `shell/services/appsearch.js` (`.pragma library`): `normalize`, `tier` e `rank` (research R5, FR-010), sem dependência de QML
- [x] T024 [P] [US2] `shell/shaders/duotone.frag` (GLSL 440, uniforms `ink` e `paper`, luminância → mistura × alfa) e `shell/ds/base/AppIcon.qml` com os estilos `ink`/`color`/`square`, o fallback em `MultiEffect` sem o `.qsb` (um aviso só) e o ícone genérico quando `source` está vazio. Conferir que o `lab/sync` compila o shader na VM sem aviso
- [x] T025 [P] [US2] `shell/services/Apps.qml`: `listed(order)` com `az`/`used`, `search` pela `appsearch.js`, `windowsOf` e as contagens pelo `Compositor.windows`, `setPinned` (em memória por enquanto), `launch` com os códigos de campo removidos, o terminal, a checagem do executável (`sh -c 'command -v -- "$1"' sh <argv0>`), a área de trabalho (`Compositor.focus` antes) e o `execDetached` (research R4), mais o `lastLaunch`
- [x] T026 [P] [US2] `shell/pause/AppsPage.qml`: a `PickerLayout` com a lista (grupos, ou o `SearchHeader` com os resultados, ou `No apps match.`), a prévia (`Card` com `mark`, `AppIcon` de 160 numa área `light-gray` de 512 × 288, a descrição), as opções (`Open`, as ações do app, `Workspace ◂ Current ▸`, `Pinned ◂ ON ▸`) e as informações (`CATEGORY`, `COMMAND`, `WINDOWS`); `type`/`backspace`/`clear`; o Esc da lista limpa a busca ou fecha; Enter/`Open` abre e fecha o menu; mudar `Pinned` move o app de grupo com a pipa junto (FR-013); rodapé e teclas da FR-014; `dumpState()`
- [x] T027 [P] [US2] As opções da frente A ao vivo: `iconStyle`, `order` e `runningApp` da `AppsPage` ligados a `SettingsModel.choiceId("menu", …)`; com `Go to window`, Enter num app com janela vai pra janela mais recente dele (`Compositor.focusWindow`, `lastAction.kind: window`)
- [x] T028 [P] [US2] Validar (`lab/perf begin "007: APPS"`, `teste-a`): bloco `apps` do `lab/check-007` com os cenários 3 (SC-003, kitty real com `pause-live.json`), 4 (SC-004, as 10 consultas), as telas de APPS e das duas buscas do cenário 1 nos dois perfis, a metade APPS do cenário 13 (3 estilos de ícone, a ordem, o app com janela) e as bordas de APPS do cenário 15 (comando inexistente com `WARN` e sem uso a mais, nomes longos, rolagem com `pause-long.json`)

**Checkpoint**: o dono já pode usar o menu no lugar do launcher, com dados de teste.

**Evidência da fase 4 (28.10, `teste-a`, 2 núcleos, 4 GB):** `lab/perf` `2026-10-28T211127-vm-teste-a-007-apps-desenvolvimento-t023-t027`
(desenvolvimento) e `2026-10-28T211652-vm-teste-a-007-apps` (T028: `check-007 --only apps` 12/0 em
1080 e hidpi, com o SC-003 em ≈0,3 s depois do Enter, as 10 consultas do SC-004, os 3 estilos de
ícone do SC-013, o Delete fora da busca; o fallback do shader sem o `.qsb` com um aviso só; `qmllint`
limpo). Também corrigido: o `PauseMenu` deixava o Delete (`\x7f`) e outros caracteres de controle
irem pra busca.

---

## Phase 5: User Story 3 - Ver e mexer nas janelas pela aba WINDOWS (Priority: P2) — frente B

**Goal**: as janelas por área de trabalho, o mapa com a escolhida em tinta, as ações (ir, mover,
flutuar, fechar), ao vivo.

**Independent Test**: com três janelas reais em duas áreas (`pause-live.json`), conferir a lista e
o mapa, ir pra uma janela da outra área, mover outra e fechar uma terceira, pelo compositor (SC-006).

- [ ] T029 [P] [US3] `shell/ds/composites/WorkspaceMap.qml`: o contorno na proporção do monitor dentro de 512 × 288, a faixa da barra, os retângulos na escala, a escolhida em tinta com o título, linhas na grade física (como a 001); vazio = só o contorno e a faixa
- [ ] T030 [P] [US3] `shell/services/compositor/HyprlandBackend.qml` (contracts/compositor.md §5), fonte real das janelas (research R7): `hyprctl clients -j`, `workspaces -j` e o `monitors -j` que já existe, relidos nos eventos crus listados no R7 por um `Timer` de 50 ms; `monitorList` com o tamanho lógico; a janela em foco pelo `focusHistoryID`; a área especial; `windowsRevision`. Leitura que falha mantém a última lista e registra no log
- [ ] T031 [P] [US3] `shell/services/compositor/HyprlandBackend.qml` (contracts/compositor.md §5), ações reais (research R8, com os nomes confirmados na T003): `focusWindow`, `moveWindow` (sem seguir), `toggleFloating`, `closeWindow` por `Hyprland.dispatch`, com o endereço validado por `^0x[0-9a-f]+$` e a área por inteiro 1–10 (senão, nada é enviado e o log registra), e a forma da config antiga quando `!Hyprland.usingLua`
- [ ] T032 [P] [US3] `shell/pause/WindowsPage.qml`: a `PickerLayout` com os grupos (`WORKSPACE 01`…, `SPECIAL` no fim; dentro do grupo por `y` e `x`), a marca `●` na janela em foco, o nome do app pelo `Apps` (ou o `class`), a prévia (`Card` com o `WorkspaceMap` e o título inteiro), as opções (`Focus`, `Workspace ◂ 01 ▸`, `Floating ◂ OFF ▸`, `Close`) e as informações (`APP`, `MONITOR`, `SIZE`); a pipa abre na janela em foco e segue o `address` quando a lista muda (vizinha quando ela some; foco volta pra lista se as opções estavam abertas); `No open windows.` com o rodapé só com `Tab` e `Esc`; rodapé e teclas da FR-018; `dumpState()`
- [ ] T033 [P] [US3] Validar (`lab/perf begin "007: WINDOWS"`, `teste-b`): bloco `windows` do `lab/check-007` com o cenário 6 (SC-006: as 3 janelas, Enter em C, mover B, fechar A em ≤ 1 s, `hyprctl clients -j` e `activewindow -j` a cada passo, shot do mapa), a tela de WINDOWS do cenário 1 nos dois perfis e as bordas de WINDOWS do cenário 15 (`pause-empty.json`, `pause-long.json` com dois monitores e SPECIAL, título vazio e enorme)

**Checkpoint**: WINDOWS substitui o alt-tab e a visão das áreas de trabalho.

---

## Phase 6: User Story 4 - Energia com confirmação pela aba POWER (Priority: P2) — frente C

**Goal**: as 6 ações, o quadro com o que vai acontecer, o status da sessão, o diálogo com a pipa em
`Cancel` e nada executando com dados de teste.

**Independent Test**: com `pause-default.json`, disparar cada ação e conferir o diálogo, o
cancelamento e o registro no `dump`; sem fixtures, um `Reboot` confirmado reinicia a VM (SC-007).

- [ ] T034 [P] [US4] `shell/ds/composites/StatusCard.qml`: `Card` com `mark`, os pares rótulo/valor com o `Meter` opcional, a régua, a fileira de quadrados e o rodapé `NO ERROR` ou o aviso em `alert` (contracts/components.md)
- [ ] T035 [P] [US4] `shell/ds/composites/ConfirmDialog.qml`: a tinta sobre o painel (clique = cancela), o `Card` de 760 com o título, o texto, os bloqueios em `alert`, as duas `OptionRow` de ação a 420, a pipa em `start`, o rodapé próprio, ↑↓/Enter/Esc e `geometry()`
- [ ] T036 [P] [US4] `shell/services/Session.qml`, fonte real (research R9): `Can*` e `ListInhibitors` por `busctl --json=short` em `refresh()`; o status (`$USER`, `/proc/sys/kernel/hostname`, `/proc/uptime` a cada minuto com o menu aberto, `Battery`, `Compositor.windows`); `run` por argv (`loginctl lock-session`; `uwsm stop` ou `loginctl terminate-session`; `systemctl suspend|hibernate|reboot|poweroff`), `busy`, `accepted`/`refused` pela saída do processo, `lastError`; **nada executa com `dryRun`**
- [ ] T037 [P] [US4] `shell/pause/PowerPage.qml`: a `GroupedList` com as 6 ações (as indisponíveis `dim`), o `DescriptionCard` (o que faz, o `effect` com o número de janelas, o motivo ou o erro), o `StatusCard`, o `ConfirmDialog` pras ações que confirmam (`confirm` e `confirm-start` ligados a `SettingsModel.choiceId`), a ordem de fechar e executar da FR-023, o diálogo cancelado quando o menu perde o teclado, `Session.refresh()` ao entrar na aba, rodapé e teclas da FR-024, `dumpState()`
- [ ] T038 [P] [US4] Validar (`lab/perf begin "007: POWER"`, `teste-c`): bloco `power` do `lab/check-007` com o cenário 7 (SC-007 com fixtures), a tela de POWER e o diálogo de `Shut down` do cenário 1 nos dois perfis, a metade POWER do cenário 13 (`Every action`, `Action`), a recusa (`pause/session-refuse.json`: menu aberto e erro no quadro) e, sem fixtures, o `Lock` provado pelo sinal em `busctl monitor`. Em outra sessão `lab/perf begin "007: reboot real"`, o cenário 8 (o `Reboot` confirmado zera o `/proc/uptime` da `teste-c`)

**Checkpoint**: o menu cobre launcher, janelas e energia.

---

## Phase 7: User Story 5 - Dados reais na VM (Priority: P3) — frentes A e B

**Goal**: os apps instalados de verdade, com ícone do tema e estado guardado; as janelas
acompanhando ao vivo.

**Independent Test**: um `.desktop` novo aparece em ≤ 2 s com o menu aberto; um app fixado continua
fixado depois de reiniciar o shell; janelas abrindo e fechando com o menu aberto (SC-009, US5).

- [x] T039 [P] [US5] Frente A, `shell/services/Apps.qml`, fonte real (research R4): `DesktopEntries.applications` (ids repetidos descartados), a categoria mapeada pras 8 do projeto, `Quickshell.iconPath(icon, true)` com o genérico da categoria quando falta, `runInTerminal`, `startupClass`, as ações, e a lista refeita no `applicationsChanged`
- [x] T040 [P] [US5] Frente A, estado dos apps (research R11): `$XDG_STATE_HOME/rien-os/apps.json` lido no início e gravado com `FileView` (`atomicWrites`) a cada fixar e a cada uso; arquivo ilegível começa vazio com uma linha no log; nada é gravado com a fixture `apps`; `~/.config` nunca é tocado
- [x] T041 [P] [US5] Frente A, validar (`lab/perf begin "007: APPS reais"`, `teste-a`): bloco `live` do `lab/check-007`, metade dos apps (cenário 10, SC-009: o `rien-test.desktop` em ≤ 2 s, o fixado depois de `pkill -x qs`, o `apps.json` na VM, `~/.config/rien-os/` intacto) e um shot de APPS com os apps reais da VM
- [ ] T042 [P] [US5] Frente B, validar (`lab/perf begin "007: WINDOWS ao vivo"`, `teste-b`): bloco `live`, metade das janelas (US5, cenário 2: com WINDOWS aberto, abrir e fechar janelas por `lab/ipc`, o `dump` acompanha em ≤ 1 s e a pipa fica no mesmo item ou vai pro vizinho; uma janela que muda de título)

**Checkpoint**: o menu está pronto pra substituir o launcher do Serpantinum na U7.

**Evidência da frente A na fase 7 (28.10, `teste-a`):** `lab/perf` `2026-10-28T212938-vm-teste-a-007-apps-reais-desenvolvimento-t039-t040`
(desenvolvimento) e `2026-10-28T213342-vm-teste-a-007-apps-reais` (T041: `check-007 --only us1,apps,live`
30/0: o `rien-test.desktop` em ≈0,3 s, fixado e usado continua depois do `pkill -x qs`, `apps.json`
em `~/.local/state/rien-os/`, `~/.config/rien-os/` intacto; `qmllint` limpo).

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: juntar as frentes, documentar e provar tudo junto.

- [ ] T043 Mesclar `007-apps`, `007-janelas` e `007-energia` na `007-menu-de-pausa` (e os blocos do `lab/check-007` na `lab-007`), nessa ordem; carregar na `teste-a` e conferir 0 erros e 0 avisos de QML
- [ ] T044 `shell/gallery/Gallery.qml`: a página 4 (Tab três vezes), carregada só enquanto aparece, com as peças da seção "Galeria" do contracts/components.md
- [ ] T045 `docs/design-system.md`: seção "§9 Menu de pausa (spec 007)" com a moldura com abas e a geometria do R12, as quatro páginas, os componentes novos (com os estados), os acréscimos em `PopupFrame`, `PickerLayout`, `GroupedList` e `SettingsPage`, as opções de `Pause menu`, as teclas e os comandos `pause`
- [ ] T046 Validar tudo (`lab/perf begin "007: validação"`, `teste-a`): o `lab/check-007` inteiro nos dois perfis (cenários ⚙ 1–7, 9–13, 15 e 16 do quickstart), com a rajada do SC-008, o log e o `qmllint` do SC-010, o shot da galeria do SC-011 e o SC-013 completo; o `lab/check-003` e o `lab/check-004` sem regressão
- [ ] T047 Imagem de revisão pro dono (SC-012): as 12 telas do cenário 1 e os 3 estilos de ícone, ao lado do mockup, e o `specs/007-menu-de-pausa/relatorio.md` com o resumo dos relatórios do `lab/perf`, os desvios e as pendências
- [ ] T048 Rodar o `/speckit-analyze` e corrigir o que ele achar nos artefatos

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (fase 1):** T001 primeiro; T002 e T004 podem andar junto (sem VM); T003 precisa da T001.
- **Foundational (fase 2):** depende da T003 (os nomes do R8). Uma sessão, em ordem. A T018 congela.
- **US1 (fase 3):** depende da T018. Sequencial. A T022 libera as frentes.
- **Frentes A, B e C (fases 4–7):** dependem da T022 e não dependem umas das outras: cada uma mexe
  nos próprios arquivos (A: `Apps.qml`, `appsearch.js`, `AppIcon`, `duotone.frag`, `AppsPage`; B:
  `WorkspaceMap`, `Compositor.qml`, `WindowsPage`; C: `StatusCard`, `ConfirmDialog`, `Session.qml`,
  `PowerPage`) e no próprio bloco do `lab/check-007`.
- **Polish (fase 8):** depende das três frentes.

### Pontos de contato entre frentes (só leitura, pelo contrato congelado)

- A lê `Compositor.windows` (contagem por app) e chama `Compositor.focus`/`focusWindow`: com a
  fixture `windows`, isso já funciona desde a T012, então A não espera B.
- B lê `Apps.byId` (nome do app de uma janela): com a fixture `apps`, já funciona desde a T010.
- C lê `Compositor.windows.length` (o efeito "N open windows will close."): idem.

### Within Each Front

- Componente e serviço primeiro (os primeiros IDs da fase), depois a página, depois as opções, por
  último a validação.

---

## Parallel Example: as três frentes depois da T022

```text
Agente A (impl007-apps, teste-a):    T023 → T024 → T025 → T026 → T027 → T028 → T039 → T040 → T041
Agente B (impl007-janelas, teste-b): T029 → T030 → T031 → T032 → T033 → T042
Agente C (impl007-energia, teste-c): T034 → T035 → T036 → T037 → T038
```

Cada agente usa `NIER_LAB_VM=<vm> NIER_LAB_CPUS=2 NIER_LAB_MEM=4G` e abre cada teste com
`lab/perf begin`. A quarta VM fica livre (máximo de 4). Se só houver duas VMs livres, A e C vão
primeiro (APPS é a P1; POWER tem o reboot real, mais demorado), e B entra quando uma delas acabar.

---

## Implementation Strategy

### MVP First

1. Fases 1 e 2 (laboratório, spike, contrato congelado).
2. Fase 3 (US1): o menu abre, troca de aba e tem SYSTEM.
3. **Parar e validar:** o dono pode olhar a moldura com abas antes das frentes.

### Incremental Delivery

1. US1 → a moldura e SYSTEM.
2. + US2 (frente A) → o launcher, já usável.
3. + US3 e US4 (frentes B e C, em paralelo com a A) → janelas e energia.
4. + US5 → dados reais e estado.
5. Polish → galeria, design system, validação completa, revisão do dono.

## Notes

- 48 tarefas: setup 4, contrato 14, US1 4, US2 6, US3 5, US4 5, US5 4, polish 6.
- Os arquivos compartilhados (`Strings`, `Tokens`, fixtures, catálogo, `shell.qml`, `qmldir`) só
  mudam na fase 2 e no merge (T043). Se uma frente precisar de um texto novo, ela o acrescenta num
  bloco marcado do `Strings.qml` e avisa no relatório.
- Commits em português, só nas branches das worktrees; o merge na principal é do dono.
