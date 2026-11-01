---
description: "Tarefas da 013: menus do jogo (efeitos medidos, tela cheia, janelinha, sons, aba LOG)"
---

# Tasks: Menus do jogo

**Input**: `specs/013-menus-do-jogo/` (spec.md, plan.md, research.md, research-som.md, data-model.md,
contracts/, quickstart.md)

**Status**: geradas em 31.10, depois da aprovação do plano ("sim aprovo"). A execução começa quando a
008 estiver na `main`.

**Tests**: sem testes automatizados de código. A prova de cada tarefa é a evidência da VM (princípio
IV): rajadas (`lab/burst`), screenshots, o `dump` do IPC, a gravação do áudio da VM e o log de QML sem
erro, sempre dentro do `lab/perf begin/end`.

**Caminhos**:
- `shell/…`, `system/…`, `docs/…`, `specs/…` = repo público `YoRHa-OS`, branch `013-menus-do-jogo`
  (`YoRHa-OS-wt/spec013`);
- `lab/…` = repo privado `YoRHa-OS-private`, branch `lab-013` (`YoRHa-OS-private-wt/lab-013/lab/`).

**VMs**: no máximo 4 ao mesmo tempo, cada uma com `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`.
- **Fundação:** a `teste-b`.
- **Frentes:** `t013-mov` (A), `t013-modos` (B), `t013-escolha` (C), `t013-som` (D). A frente D usa
  também a `teste-011` pro boot, desligando a `t013-som` antes.

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: vai pra um agente paralelo, com worktree e VM próprios. Dentro de uma frente, a ordem é a dos
  IDs.
- **[Story]**: história da spec (US1–US8).

## Phase 1: Setup (preparação, F0)

- [X] T001 Mesclar a 008 na `main` (depois do agente da 008), dar push e trazer a `main` pra
  `013-menus-do-jogo`
- [ ] T002 Criar a `lab-013` a partir da `lab-008` (que já tem a `main` privada e a `lab-007`, com o `check-007`; a `main` privada não tem) e a worktree
  `YoRHa-OS-private-wt/lab-013`
- [ ] T003 `lab/up --audio-capture`: placa emulada `ich9-intel-hda` + `hda-output` com `-audiodev wav`,
  saída em `out/audio-<vm>-<data>.wav` (research S6); documentar no `lab/README.md`
- [ ] T004 `lab/013/audio-rec`: gravar o monitor do sink nulo na sessão (`pw-record`), com um pulso
  marcador pra alinhar com os tempos do `lab/key`
- [ ] T005 `lab/provision-step sound`: `qt6-multimedia`, `qt6-multimedia-ffmpeg`, `alsa-utils`,
  `pipewire-audio` na VM; `lab/013/qsb`: compilar shaders com `qt6-shadertools` num container
- [ ] T006 Sondagem na `teste-b` e na `teste-011`, registrada em `specs/013-menus-do-jogo/sondagem.md`:
  - latência do `SoundEffect` contra os 50 ms (S1);
  - o greeter alcança o PipeWire? (S3);
  - `aplay -D plughw` antes do WirePlumber e o `EBUSY` (S4);
  - `kb_layout` em tempo de execução no 0.56 com Lua (R6);
  - um `.qsb` carregando no Quickshell (R2);
  - a ordem das camadas Overlay, toast sobre o menu (R5).

  Ajustar a research no que mudar.
- [ ] T007 `lab/013/sounds-gen`: gerar `system/sounds/*.wav` (eventos da data-model) e os níveis do
  `boot-start` no container `nier-lab-py`, com semente fixa (S2); nota no `CREDITS.md` (sons nossos)
- [ ] T008 Esqueleto do `lab/check-013` com os blocos do quickstart (`--only`, `--profile`, `--mode`)

## Phase 2: Foundational (fundação, F1, o que as frentes dividem)

- [ ] T009 `shell/ds/Tokens.qml`: o bloco `motion` com os números da research R1; tudo 0 com
  `Tokens.instant`
- [ ] T010 `shell/ds/primitives/ScrollingLabel.qml`: pausa, rola a 60 px/s, pausa, volta; só quando não
  cabe; corta com "…" com `Tokens.instant` (FR-012, FR-016); página na galeria
- [ ] T011 `shell/ds/base/TypedText.qml`: letra da ponta sorteada do próprio texto, velocidade por
  parâmetro (FR-004, FR-005)
- [ ] T012 `shell/services/Settings.qml` / `SettingsState`: as chaves de data-model.md, as strings novas
  em `shell/strings/Strings.qml`
- [ ] T013 `shell/popup/PopupFrame.qml` e `PopupWindow.qml`: `presentation` (`floating` | `fullscreen`),
  a geometria do painel e o `s` do painel de 84% nos dois modos (R4), ainda sem animação
- [ ] T014 `shell/ds/composites/PickerLayout.qml`: dividir o `fluid` em `stretch` e `bodyOnly` (frente D
  §5), sem mudar o modo janela
- [ ] T015 IPC: `pause dump` com `presentation`, `anim` e `choice`; `pause fps start|stop` (R7);
  `sounds` com `play` e `dump` (contracts/ipc.md)
- [ ] T016 `shell/services/Sounds.qml`: a API (`play(event)`) e os nomes dos eventos, ainda sem tocar,
  pras frentes A e C chamarem

**Checkpoint**: a fundação na `teste-b` sem erro de QML, e os roteiros da 003, 004, 007 e 008 verdes
(nada visível mudou).

## Phase 3: User Story 1 - Navegar com o movimento do jogo (P1) 🎯 MVP · Frente A

- [ ] T017 [P] [US1] `ds/base/ListItem.qml`: varredura de 400 ms OutQuart e recolher de 200 ms da linha
  que perde a seleção (FR-001)
- [ ] T018 [US1] `ListItem` e `ds/composites/TabBar.qml`: a camada do pulso na linha "viva" e na aba
  aberta (FR-002)
- [ ] T019 [US1] `ds/base/PageHeader.qml`: título some, espera e digita (FR-004)
- [ ] T020 [US1] `CursorList`, `GroupedList`, `OptionList`: `enter()` em cascata, com os rótulos
  digitando (FR-005)
- [ ] T021 [US1] `popup/PopupFrame.qml`: a troca de aba (some, vazio, monta), cortada por uma troca nova
  (FR-006)
- [ ] T022 [US1] `ds/base/KeyHints.qml` e o rótulo do rodapé: entrada com desfoque e deslize (FR-007)
- [ ] T023 [US1] `OptionList` (entrada escalonada) e `ListItem.leave()` (esticar e apagar) (FR-008)
- [ ] T024 [US1] Validar na `t013-mov`: blocos `motion` e `keys` do `check-013`, nos dois perfis

## Phase 4: User Story 2 - Abrir, fechar e confirmar como no jogo (P1) · Frente A

- [ ] T025 [US2] `popup/TriangleReveal.qml` + `popup/shaders/triangles.frag` (`.qsb` pelo
  `lab/013/qsb`): grade com franja, triângulos ao abrir e ao fechar, no retângulo do painel (FR-009, R2)
- [ ] T026 [US2] `PopupFrame`/`PopupWindow`: a montagem em ordem depois dos triângulos (réguas, abas,
  título, cartões, linhas, rodapé, ponteiro) e o fechamento animado antes de soltar a janela (FR-009)
- [ ] T027 [US2] `ds/composites/ConfirmDialog.qml`: escurecer pra ×0,8, a faixa do título primeiro, o
  corpo com fade e desfoque; fechar com desfoque (FR-010)
- [ ] T028 [US2] `wallpaper/Scene.qml` e `PopupFrame`: congelar a `phase` do papel com um menu aberto
  (FR-011)
- [ ] T029 [US2] Validar: blocos `open` e `dialog`, nos dois perfis

## Phase 5: User Story 3 - O texto que não cabe rola (P2) · Frente A

- [ ] T030 [US3] Usar o `ScrollingLabel` na `ListItem`, no `ValueStepper`, nos cabeçalhos de cartão e
  nas linhas de informação (FR-012, FR-016)
- [ ] T031 [US3] Validar: blocos `marquee` e `reduce`

## Phase 6: User Story 4 - Janela ou tela cheia (P2) · Frente B

- [ ] T032 [P] [US4] As páginas na tela cheia:
  - painel sem tinta e sem sombra, com o papel estático;
  - colunas com `stretch` em APPS, WINDOWS, no seletor e no log;
  - SYSTEM centralizado;
  - limite de largura em ultrawide (FR-013, FR-014).
- [ ] T033 [US4] Appearance › Menu presentation e a troca ao vivo, mantendo aba, seleção e foco (FR-013)
- [ ] T034 [US4] Toasts críticos e OSD por cima do menu cheio (R5, FR-014)
- [ ] T035 [US4] Validar na `t013-modos`: blocos `modes` e `perf`, nos dois modos e nos dois perfis

## Phase 7: User Story 8 - O histórico como aba do menu (P3) · Frente B

- [ ] T036 [US8] `pause/PauseMenu.qml`:
  - a aba `log` entre WINDOWS e SYSTEM;
  - `notify/LogPage.qml` com o host `pause`;
  - tirar `notify/LogPopup.qml`;
  - SUPER+N, o contador da barra e `notify open` abrindo o menu em LOG;
  - marcar como lido ao fechar (FR-034).
- [ ] T037 [US8] Validar: bloco `log-tab` e os blocos de log do `check-008` com o host `pause`

## Phase 8: User Story 6 - Escolher numa janelinha (P2) · Frente C

- [ ] T038 [P] [US6] `ds/composites/ChoicePopup.qml`:
  - presa à direita da linha, com escurecimento ×0,8;
  - ponteiro do lado direito;
  - sobe perto da borda e rola em linhas inteiras;
  - página na galeria (FR-025, FR-027).
- [ ] T039 [US6] `ds/composites/OptionRow.qml`: Enter numa escolha com mais de 3 valores abre a
  janelinha; ←→ continuam mudando direto (FR-025)
- [ ] T040 [US6] O modo múltiplo (quadradinhos, pelo menos um marcado) e Keyboard › Layouts aplicado no
  Hyprland (FR-026, R6)
- [ ] T041 [US6] Validar na `t013-escolha`: bloco `choice`, nos dois modos e nos dois perfis

## Phase 9: User Story 5 - Os sons da interface (P2) · Frente D

- [ ] T042 [P] [US5] `services/Sounds.qml` completo:
  - `SoundEffect` em conjunto de 3, debounce de 40 ms, no máximo 4 sons;
  - pasta própria;
  - volume de interface;
  - digitação;
  - "não perturbe" e a tela cheia segurada nas notificações;
  - o `sound.json` (FR-019 a FR-024, S1).
- [ ] T043 [US5] Ligar os eventos:
  - menus (`move`, `change`, `confirm`, `back`, `open`, `close`, `tab`, `dialog` e os da janelinha);
  - notificações, OSD e digitação;
  - o som de entrada uma vez por login (FR-019, FR-030, S5).
- [ ] T044 [US5] Configurações › Sound: as opções da data-model (FR-022)
- [ ] T045 [US5] `docs/sons-do-jogo.md`: como usar os sons da própria cópia de PC (só links pra guias e
  ferramentas) e os nomes dos eventos (FR-021)
- [ ] T046 [US5] Validar na `t013-som` com `--audio-capture`: blocos `sounds` e `sound-opts` (SC-008,
  SC-009)

## Phase 10: User Story 7 - Som no boot e no login (P3) · Frente D

- [ ] T047 [US7] `system/boot-login/`: a regra udev, o `yorha-os-boot-sound.service`, o script e os WAV
  por nível; `install`, `uninstall` e `status` no manifesto (contracts/boot-sound.md, FR-028, FR-031,
  FR-032)
- [ ] T048 [US7] `system/login/sddm/yorha-os/`: os sons do tema, a chave `sounds` e a leitura de
  `/run/yorha-os/sound.state` (FR-029, S3)
- [ ] T049 [US7] Lab: `check-011 undo` cobrindo o som de boot; `lab/bootcap --audio-capture`
- [ ] T050 [US7] Validar na `teste-011`: blocos `bootsound`, `boot-timing` e `undo` (SC-012, SC-013)

## Phase 11: Polish & junção (F3)

- [ ] T051 Mesclar as frentes na `013-menus-do-jogo` e na `lab-013`; resolver o que A e B mexeram no
  `PopupFrame`
- [ ] T052 `check-013` inteiro nos dois perfis e nos dois modos; `check-003`, `check-004`, `check-007`,
  `check-008` e `check-011` verdes (SC-004)
- [ ] T053 A lista das diferenças esperadas do modo janela parado (FR-017), com `lab/diffshot` contra as
  evidências
- [ ] T054 `docs/design-system.md` (movimento, `ScrollingLabel`, `ChoicePopup`, apresentação, sons) e
  `README.md`
- [ ] T055 Sessão do dono numa janela da VM: os dois modos, a janelinha e os sons; ajustar os números
  (SC-007, SC-011)
- [ ] T057 Acabamento herdado da 008: no log, o ◂ OFF ▸ (coluna estreita de 70) não alinha com o
  valor de Show logo abaixo; alinhar as colunas de valor das opções do log
- [ ] T056 `relatorio.md` e a página de revisão; atualizar o `PLAN.md`, o mapa do projeto e a Central

## Dependencies & Execution Order

- **Setup (T001–T008):** primeiro. T001 depende do agente da 008. T006 decide os riscos de S1, S3, S4, R2,
  R5 e R6 antes das frentes.
- **Fundação (T009–T016):** depois do setup; bloqueia as frentes.
- **Frentes A (T017–T031), B (T032–T037), C (T038–T041) e D (T042–T050):** em paralelo depois da
  fundação.
  - A e B tocam o `PopupFrame`: A anima e B mexe na geometria (as interfaces vêm da T013).
  - C usa a `ListItem` e o `ScrollingLabel` da fundação.
  - D só liga os eventos que A e C já chamam.
- **Junção (T051–T056):** depois das quatro frentes.

## Parallel Example

```text
Depois da fundação, quatro agentes, cada um com worktree e VM:
  A: T017 → T031 (t013-mov)
  B: T032 → T037 (t013-modos)
  C: T038 → T041 (t013-escolha)
  D: T042 → T050 (t013-som, depois teste-011)
```

## Implementation Strategy

- **MVP = setup + fundação + frente A até a T024 (US1):** o menu já anda como o jogo. Dá pra mostrar ao
  dono antes do resto.
- **Ordem de risco:** a sondagem (T006) vem antes de tudo, porque decide o som no login, o som de boot e
  o shader.
- **Ajustes de número** depois da sessão do dono não pedem spec nova.
