---
description: "Tarefas do U1: base visual YoRHa e HUD"
---

# Tasks: Base visual YoRHa e HUD

**Input**: `specs/001-yorha-base-hud/` (plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md)

**Tests**: a spec não pede testes automatizados. A prova de cada tarefa é a evidência da VM
(princípio IV): screenshot, `qs ipc call …` que responde e log de QML sem erro, sempre dentro
de `lab/perf begin/end`.

**Caminhos**:
- `shell/…` = repositório público `nier-os`;
- `lab/…` = repositório privado `rien-OS-private`, irmão do público
  (`~/projects/rien-OS-private/lab/`).

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: história da spec (US1 = H1, US2 = H2, US3 = H3)

---

## Phase 1: Setup (laboratório e estrutura)

**Purpose**: deixar o laboratório pronto pra fixtures, comparação de screenshots, perfil hidpi e
agentes paralelos, e criar o esqueleto do `shell/`.

- [x] T001 Criar a estrutura de pastas do plan.md: `shell/ds/{primitives,base,composites}`, `shell/services`, `shell/strings`, `shell/hud`, `shell/gallery`, `shell/config`, `shell/fixtures`, `shell/assets/fonts` (remover `shell/.gitkeep`)
- [x] T002 [P] `lab/sync`: aceitar `--env KEY=VAL` (repetível). Grava `~/nier/ui.env` na VM, instala/atualiza `~/.local/bin/nier-ui-run` a partir de `lab/guest/nier-ui-run` e reinicia o `qs` (`pkill -x qs`) só quando o env ou o runner mudarem
- [x] T003 [P] `lab/guest/nier-ui-run`: carregar `~/nier/ui.env` (`set -a; . ~/nier/ui.env; set +a`) antes de cada `qs -p "$ui"`
- [x] T004 [P] Criar `lab/diffshot a.png b.png`: imprime o número de pixels diferentes (`magick compare -metric AE`) e sai com 0 só quando for 0
- [x] T005 [P] `lab/up` + `lab/profile`: `NIER_LAB_PROFILE=hidpi` liga a VM com tela de 2560x1600; `lab/profile hidpi|1080` aplica a escala 1.25/1 via `lab/ipc hyprctl eval 'hl.monitor({output="",mode="preferred",position="auto",scale=…})'`
- [x] T006 `lab/lib.sh`: várias VMs ao mesmo tempo. Com `NIER_LAB_VM=<nome>`, os comandos usam essa VM; a porta SSH sai de `run/<vm>.port` (primeira livre a partir de 2222, gravada pelo `lab/up`); a sessão `lab/perf` fica em `run/perf-<vm>.session`; sem `NIER_LAB_VM`, nada muda. `NIER_LAB_CPUS`/`NIER_LAB_MEM` continuam valendo
- [x] T007 Criar as camadas `teste-a`, `teste-b` e `teste-c` (`lab/new teste-x --from hypr-base`) e provar duas VMs ligadas juntas, cada uma com o seu `lab/shot` e o seu relatório `lab/perf`. `shellcheck` (Docker `koalaman/shellcheck:stable`) limpo em todos os scripts mudados
- [x] T008 Documentar T002–T007 na seção "Uso no dia a dia" de `lab/README.md`

**Checkpoint**: laboratório pronto pra agentes paralelos.

---

## Phase 2: Foundational (contrato + peças compartilhadas)

**Purpose**: o contrato que todas as histórias usam. **⚠️ Depois do T016, as interfaces de
`contracts/` ficam congeladas.**

- [x] T009 Baixar a M PLUS 1 variável (`MPLUS1[wght].ttf`) e o `OFL.txt` do repositório `google/fonts` (`ofl/mplus1/`) para `shell/assets/fonts/`, e acrescentar o crédito em `CREDITS.md`
- [x] T010 Criar `shell/ds/Tokens.qml` (singleton) com os grupos `color`, `type`, `shadow`, `space`, `motion` e `vignette` do data-model.md, mais as funções `line(v, s)` ("≥ 1 e inteiro") e `px(v, s)`. Carrega a fonte por `FontLoader`, usa "FOT-Rodin ProN"/"Helvetica Now Micro" quando estiverem em `Qt.fontFamilies()`, e `motion.frozen` segue `Fixtures.active`
- [x] T011 [P] Criar `shell/strings/Strings.qml` (singleton): `CPU`, `MEM`, `VOL`, `BAT`, `SYSTEM` e os nomes da galeria, todos em inglês (FR-018)
- [x] T012 [P] Criar `shell/config/defaults.json` (`uiScale` 1, `barHeight` 40, `vignette` true) e `shell/services/Settings.qml` (singleton, `FileView` + `JsonAdapter`), que sobrescreve com `$XDG_CONFIG_HOME/rien-os/shell.json`. Validação do data-model: `uiScale` "0,5–3,0, fora usa o padrão e registra um aviso"; `barHeight` "limitado a 28–48"
- [x] T013 [P] Criar `shell/services/Fixtures.qml` (singleton): lê o JSON de `NIER_FIXTURES` (`Quickshell.env`), expõe `active`, `source`, `data`, `load(path)` e `clear()`; um domínio ausente fica `undefined` (contracts/fixtures.schema.json)
- [x] T014 [P] Criar as fixtures em `shell/fixtures/`: `hud-default.json` (workspaces 1–3 com o 2 em foco, CPU 23, MEM 41, VOL 64, BAT 87, "kitty — ~/projetos", 2026-10-26T13:37:00), `hud-live-ws.json` (igual, sem `workspaces`), `battery-low.json`, `no-battery.json`, `muted.json`, `long-title.json` e `no-window.json`
- [x] T015 Criar `shell/shell.qml`: `ShellRoot` com os `IpcHandler` `gallery` (`open`, `close`, `toggle`, `isOpen`), `fixtures` (`load`, `clear`) e `hud` (`dump`), conforme contracts/ipc.md. `dump` devolve `[]` até a US1
- [x] T016 Verificar na VM (`lab/perf begin "U1: contrato"`): carrega com 0 erros e 0 avisos; `qs -p ~/nier/ui ipc call fixtures load ~/nier/ui/fixtures/hud-default.json` responde `ok`; `qmllint` dentro da VM sem erros. **Congela o contrato**
- [x] T017 [P] Primitivas em `shell/ds/primitives/`: `Label.qml`, `Square.qml`, `Rule.qml` (`plain`/`dotted`/`vertical`; a pontilhada segue o padrão do design-system §6), `GridBackground.qml` (passo 7) e `Vignette.qml` (bordas `#A6A18D`, cantos `#8B8877`), seguindo contracts/components.md
- [x] T018 [P] Base em `shell/ds/base/` (parte 1): `Selector.qml` (pipa 32×14 com furo + 2 quadradinhos de 5 px a ±10 px, alinhados com a ponta; balanço de ±5 px em 1 s, `InOutSine`, congelado quando `Tokens.motion.frozen`) e `Meter.qml` (`hp-bar` chapado 163×11, anima o valor, `alert` quando `critical`)
- [x] T019 [P] Base em `shell/ds/base/` (parte 2): `HeaderButton.qml` (estados `normal`/`hovered`/`selected`/`dimmed`, tinta pintando da esquerda pra direita em `Tokens.motion.highlight`, trilhos, sombra, `Selector` em `hovered`/`selected`, `reachRule` faz a aba selecionada descer até a régua) e `ListItem.qml` (mesmos estados, variantes `opaque`/`plain`, `trailing`)
- [x] T020 [P] Base em `shell/ds/base/` (parte 3): `PageHeader.qml` (caixa alta, sombra `text-shadow` em ≈15% do tamanho do texto) e `Card.qml` (cabeçalho de tinta + corpo `lightYellow`)

**Checkpoint**: contrato congelado e peças disponíveis. As histórias podem começar.

---

## Phase 3: User Story 1 - HUD com cara de NieR (Priority: P1) 🎯 MVP

**Goal**: barra no topo de cada monitor com abas, título, telemetria e relógio, com dados reais
ou fixos.

**Independent Test**: com `hud-default.json`, `lab/shot` mostra exatamente os cenários 1–4 da H1,
e `hud dump` traz os mesmos valores.

- [x] T021 [P] [US1] `shell/services/Clock.qml`: `SystemClock` com precisão de segundos, ou a hora fixa de `Fixtures.data.clock`
- [x] T022 [P] [US1] `shell/services/Telemetry.qml`: `cpu` e `mem` como `Reading` (data-model). `FileView` em `/proc/stat` e `/proc/meminfo` com `reload()` a cada 2 s; **se o `FileView` não ler `/proc` na VM, usar `Process` + `StdioCollector` (research R3)**. Leitura que falha "vira value: 0"
- [x] T023 [P] [US1] `shell/services/Audio.qml`: `vol` a partir de `Pipewire.defaultAudioSink` + `PwObjectTracker`; `extra: "muted"` e valor 0 quando mudo; fixture `volume`
- [x] T024 [P] [US1] `shell/services/Battery.qml`: `bat` a partir de `UPower.displayDevice`; `available: false` sem bateria; `critical` "value < 0.15 e sem carregar"; `extra: "charging"`; fixture `battery` (null = sem bateria)
- [x] T025 [P] [US1] `shell/services/Compositor.qml`: o único arquivo que importa `Quickshell.Hyprland`. `workspacesFor(monitorName)` devolve ids de 1 até "max(5, maior id existente, id em foco)", "só ids ≥ 1"; `activeTitle`; `focus(id)` (com a fixture `workspaces`, só atualiza o estado fixo)
- [x] T026 [US1] `shell/ds/composites/TabBar.qml`: faixas verticais + `HeaderButton` por aba + régua pontilhada; a aba `selected` desce até a régua; sinal `activated(index)`
- [x] T027 [US1] `shell/hud/Hud.qml`: `PanelWindow` no topo, `exclusiveZone` = altura (`Settings.barHeight`, 40), `s = tabH/47` com `tabH = barHeight × 31/40` × `Settings.uiScale`; da esquerda pra direita: marca (as duas faixas), `TabBar`, título centralizado (`elide`), `CPU`/`MEM`/`VOL`/`BAT` (`Label` + `Meter` + número), data `yyyy.MM.dd` e hora; régua pontilhada embaixo; sem vinheta
- [x] T028 [US1] Em `shell/shell.qml`: `Variants` sobre `Quickshell.screens` criando um `Hud` por monitor, e `hud.dump()` real (formato de contracts/ipc.md)
- [x] T029 [US1] Validar no lab (`lab/perf begin "U1: HUD"`): cenários 1–4 da H1 por screenshot + `dump`; casos de borda com `fixtures load` (battery-low, no-battery, muted, long-title, no-window); 0 erros de QML

**Checkpoint**: MVP pronto, a barra funciona sozinha.

---

## Phase 4: User Story 2 - Trocar de workspace pela barra (Priority: P2)

**Goal**: clicar numa aba troca o workspace; o hover mostra o destaque.

**Independent Test**: com `hud-live-ws.json`, clicar na aba 03 leva ao workspace 3 em ≤ 0,5 s
(`hud dump` + screenshot).

- [x] T030 [US2] `shell/hud/Hud.qml` + `TabBar.qml`: clique → `Compositor.focus(id)`; `HoverHandler` → estado `hovered` em abas não selecionadas, voltando ao normal quando o mouse sai
- [x] T031 [US2] Validar no lab (`lab/perf begin "U1: abas"`): clique simulado (`lab/ipc hyprctl dispatch workspace 3` como controle + clique real via QMP `input-send-event`, ou `ydotool`/`wlrctl` se houver na VM), medir o tempo até o `dump` mostrar a 03 `selected` (SC-003); screenshot do hover

**Checkpoint**: US1 e US2 funcionam.

---

## Phase 5: User Story 3 - Galeria do design system (Priority: P3)

**Goal**: tela cheia com todas as peças e estados, com nome, aberta por comando.

**Independent Test**: `gallery open` → screenshot com 100% das peças do FR-003 e estados do
FR-004 → `gallery close`.

- [x] T032 [P] [US3] `shell/ds/composites/CursorList.qml`: faixas verticais + `ListItem`s + `Selector` no item atual; sinal `activated(index)`
- [x] T033 [US3] `shell/gallery/Gallery.qml`: `PanelWindow` de tela cheia na camada `Overlay` (via `LazyLoader` no `shell.qml`), `keyboardFocus` exclusivo (Esc fecha), `GridBackground`, `Vignette` (se `Settings.vignette`), `s = altura/1080`; seções com nome: primitivas, `HeaderButton` e `ListItem` nos 4 estados, `Selector` claro e escuro balançando, `Meter` normal e crítico, `PageHeader`, `Card`, `TabBar` e `CursorList`
- [x] T034 [US3] Ligar os `IpcHandler` `gallery` (`open`/`close`/`toggle`/`isOpen`) ao `LazyLoader` em `shell/shell.qml`
- [x] T035 [US3] Validar no lab (`lab/perf begin "U1: galeria"`): `open` → screenshot → conferir peça por peça (SC-004) → `close` e Esc

**Checkpoint**: as três histórias funcionam.

---

## Phase 7: User Story 4 - Fundo da área de trabalho (Priority: P4)

**Goal**: o fundo inteiro do desktop é o papel do menu, com movimento sutil.

**Independent Test**: workspace vazio → screenshot mostra o fundo; com fixtures, dois
screenshots iguais; `lab/perf` com e sem movimento.

- [x] T041 [US4] Spec (História 4, FR-019–FR-021, SC-009/SC-010), design system §2/§5 e contratos atualizados
- [x] T042 [US4] `shell/ds/primitives/PaperDecor.qml`: arcos e feixes desenhados uma vez num Canvas (linhas na grade física), `phase` 0–1 movendo as camadas por transformação, sem repintar
- [x] T043 [US4] `shell/wallpaper/Wallpaper.qml`: `PanelWindow` por monitor na camada Background (namespace `rien-wallpaper`), `GridBackground` + `PaperDecor` + `Vignette`; `Timer` de 10 passos/s parado com `Tokens.frozen` ou `Settings.wallpaperMotion: false`
- [x] T044 [US4] `Settings.wallpaperMotion` (padrão true), `Variants` no `shell.qml` e IPC `wallpaper` (`motion(on)`, `isMoving()`)
- [x] T045 [US4] `lab/check-u1`: SC-009 (workspace vazio + dois screenshots iguais)
- [x] T046 [US4] Validar no lab: check-u1 completo, hidpi nítido, e duas sessões `lab/perf` de 60 s (com e sem movimento) pro SC-010

---

## Phase 6: Polish & validação final

- [x] T036 Rodar o quickstart.md inteiro numa sessão `lab/perf begin "U1: validação" --kind u1-validacao --task 001`: SC-001 a SC-005, SC-007, SC-008 (`lab/profile hidpi` e `1080`), casos de borda e `qmllint`
- [x] T037 Corrigir o que o T036 apontar e repetir só os cenários afetados
- [ ] T038 [P] Polir o visual contra `docs/design-system.md` §6 (régua pontilhada, proporções da aba, título), comparando lado a lado com as referências privadas
- [ ] T039 [P] Rodar `/speckit-analyze` e resolver as inconsistências entre spec, plano e tarefas
- [x] T040 Escrever `specs/001-yorha-base-hud/relatorio-noite.md` (o que ficou pronto com a evidência, o que faltou, as decisões tomadas sozinho, o custo somado do `lab/perf`, os commits) e montar a imagem final com HUD 1080p + HUD hidpi + galeria

---

## Dependencies & Execution Order

- **Setup (T001–T008)** → **Foundational (T009–T020)** → US1 → US2; a **US3** depende só do Foundational (+ T026 pra mostrar o `TabBar`).
- T016 congela o contrato. T017–T020 só começam depois dele.
- Dentro da US1: os serviços T021–T025 são [P] entre si; T026 depende de T019; T027 depende de T021–T026; T028 depende de T027.
- US2 depende da US1 (o HUD existe). US3 pode correr em paralelo com a US1 depois do Foundational.

## Parallel Example (agentes, cada um com worktree e VM própria)

```text
Depois do T016:
  Agente A (teste-a): T017, T018, T019, T020   → primitivas + base
  Agente B (teste-b): T021, T022, T023, T024, T025 → serviços
  Agente C (teste-c): T032 (CursorList) com a interface do contrato, depois T026 (TabBar) quando o T019 chegar
Depois das peças:
  Agente HUD: T027, T028, T029, T030, T031
  Agente Galeria: T033, T034, T035
```

## Implementation Strategy

1. **MVP = US1:** Setup + Foundational + US1 já entregam a barra completa, com evidência.
2. Depois US2 (interação) e US3 (galeria). As duas podem correr em paralelo depois do MVP.
3. Cada fase termina com evidência no lab e relatório no `rien-OS-relatorios`. Nenhuma tarefa é
   marcada `[x]` sem prova.
