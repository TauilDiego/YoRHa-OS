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
- [X] T002 Criar a `lab-013` a partir da `lab-008` (que já tem a `main` privada e a `lab-007`, com o `check-007`; a `main` privada não tem) e a worktree
  `YoRHa-OS-private-wt/lab-013`
- [X] T003 `lab/up --audio-capture`: placa emulada `ich9-intel-hda` + `hda-output` com `-audiodev wav`,
  saída em `out/audio-<vm>-<data>.wav` (research S6); documentar no `lab/README.md`
- [X] T004 `lab/013/audio-rec`: gravar o monitor do sink nulo na sessão (`pw-record`), com um pulso
  marcador pra alinhar com os tempos do `lab/key`
- [X] T005 `lab/provision-step sound`: `qt6-multimedia`, `qt6-multimedia-ffmpeg`, `alsa-utils`,
  `pipewire-audio` na VM; `lab/013/qsb`: compilar shaders com `qt6-shadertools` num container
- [X] T006 Sondagem na `teste-b` e na `teste-011`, registrada em `specs/013-menus-do-jogo/sondagem.md`:
  - latência do `SoundEffect` contra os 50 ms (S1);
  - o greeter alcança o PipeWire? (S3);
  - `aplay -D plughw` antes do WirePlumber e o `EBUSY` (S4);
  - `kb_layout` em tempo de execução no 0.56 com Lua (R6);
  - um `.qsb` carregando no Quickshell (R2);
  - a ordem das camadas Overlay, toast sobre o menu (R5).

  Ajustar a research no que mudar.
- [X] T007 `lab/013/sounds-gen`: gerar `system/sounds/*.wav` (eventos da data-model) e os níveis do
  `boot-start` no container `nier-lab-py`, com semente fixa (S2); nota no `CREDITS.md` (sons nossos)
- [X] T008 Esqueleto do `lab/check-013` com os blocos do quickstart (`--only`, `--profile`, `--mode`)

## Phase 2: Foundational (fundação, F1, o que as frentes dividem)

- [X] T009 `shell/ds/Tokens.qml`: o bloco `motion` com os números da research R1; tudo 0 com
  `Tokens.instant`
- [X] T010 `shell/ds/primitives/ScrollingLabel.qml`: pausa, rola a 60 px/s, pausa, volta; só quando não
  cabe; corta com "…" com `Tokens.instant` (FR-012, FR-016); página na galeria
- [X] T011 `shell/ds/base/TypedText.qml`: letra da ponta sorteada do próprio texto, velocidade por
  parâmetro (FR-004, FR-005)
- [X] T012 `shell/services/Settings.qml` / `SettingsState`: as chaves de data-model.md, as strings novas
  em `shell/strings/Strings.qml`
- [X] T013 `shell/popup/PopupFrame.qml` e `PopupWindow.qml`: `presentation` (`floating` | `fullscreen`),
  a geometria do painel e o `s` do painel de 84% nos dois modos (R4), ainda sem animação
- [X] T014 `shell/ds/composites/PickerLayout.qml`: dividir o `fluid` em `stretch` e `bodyOnly` (frente D
  §5), sem mudar o modo janela
- [X] T015 IPC: `pause dump` com `presentation`, `anim` e `choice`; `pause fps start|stop` (R7);
  `sounds` com `play` e `dump` (contracts/ipc.md); `settings set <chave> <valor>`, que o contrato
  supõe e o `shell.qml` ainda não tem (o `check-013 --mode` usa)
- [X] T016 `shell/services/Sounds.qml`: a API (`play(event)`) e os nomes dos eventos, ainda sem tocar,
  pras frentes A e C chamarem

**Checkpoint**: a fundação na `teste-b` sem erro de QML, e os roteiros da 003, 004, 007 e 008 verdes
(nada visível mudou).

Feito em 31.10: log de QML e `qmllint` limpos; `check-003` 25/0 nos dois perfis, `check-004` 58/0,
`check-007` 76/0 (com a galeria de 7 páginas), `check-008` 110/0 nos dois perfis. O `first` da 008 em
hidpi falhou uma vez com 4 VMs na GPU e passou 3 de 3 sozinho.

## Phase 3: User Story 1 - Navegar com o movimento do jogo (P1) 🎯 MVP · Frente A

- [X] T017 [P] [US1] `ds/base/ListItem.qml`: varredura de 400 ms OutQuart e recolher de 200 ms da linha
  que perde a seleção (FR-001)
- [X] T018 [US1] `ListItem` e `ds/composites/TabBar.qml`: a camada do pulso na linha "viva" e na aba
  aberta (FR-002)
- [X] T019 [US1] `ds/base/PageHeader.qml`: título some, espera e digita (FR-004)
- [X] T020 [US1] `CursorList`, `GroupedList`, `OptionList`: `enter()` em cascata, com os rótulos
  digitando (FR-005)
- [X] T021 [US1] `popup/PopupFrame.qml`: a troca de aba (some, vazio, monta), cortada por uma troca nova
  (FR-006)
- [X] T022 [US1] `ds/base/KeyHints.qml` e o rótulo do rodapé: entrada com desfoque e deslize (FR-007)
- [X] T023 [US1] `OptionList` (entrada escalonada) e `ListItem.leave()` (esticar e apagar) (FR-008)
- [X] T024 [US1] Validar na `t013-mov`: blocos `motion` e `keys` do `check-013`, nos dois perfis

Feito em 01.11 (frente A, `t013-mov`): `check-013 --only motion,keys` nos dois perfis. Seleção,
pulso, título, troca de aba, cascata, rodapé e sublista dentro de ±1 quadro do jogo (mediana de 3
rajadas, medidas pelo `lab/013/measure`); keys 3/3. Os tempos são medidos com o driver de animação de
relógio de parede: o relógio de quadros da VM corre a ~62 qps e o Qt conta 60, então com o driver
normal tudo anda ~3,5% mais rápido na VM.

## Phase 4: User Story 2 - Abrir, fechar e confirmar como no jogo (P1) · Frente A

- [X] T025 [US2] `popup/TriangleReveal.qml` + `popup/shaders/triangles.frag` (`.qsb` pelo
  `lab/013/qsb`): grade com franja, triângulos ao abrir e ao fechar, no retângulo do painel (FR-009, R2)
- [X] T026 [US2] `PopupFrame`/`PopupWindow`: a montagem em ordem depois dos triângulos (réguas, abas,
  título, cartões, linhas, rodapé, ponteiro) e o fechamento animado antes de soltar a janela (FR-009)
- [X] T027 [US2] `ds/composites/ConfirmDialog.qml`: escurecer pra ×0,8, a faixa do título primeiro, o
  corpo com fade e desfoque; fechar com desfoque (FR-010)
- [X] T028 [US2] `wallpaper/Scene.qml` e `PopupFrame`: congelar a `phase` do papel com um menu aberto
  (FR-011)
- [X] T029 [US2] Validar: blocos `open` e `dialog`, nos dois perfis

Feito em 01.11 (frente A): `open` e `dialog` 20/0 em 1080. Em hidpi, o fechamento mediu ~190 ms
contra 230 (os quadros da VM chegam irregulares nessa resolução; as células somem dentro dos 230) e a
saída do cartão do diálogo oscilou entre as medidas; o resto passa. O `yorha-popup` ficou sem animação
de camada no Hyprland do lab, como o `yorha-notify` (falta levar à configuração do produto).

## Phase 5: User Story 3 - O texto que não cabe rola (P2) · Frente A

- [X] T030 [US3] Usar o `ScrollingLabel` na `ListItem`, no `ValueStepper`, nos cabeçalhos de cartão e
  nas linhas de informação (FR-012, FR-016)
- [X] T031 [US3] Validar: blocos `marquee` e `reduce`

Feito em 01.11 (frente A): `marquee` e `reduce` passam nos dois perfis (pausas de ~1,0 s, 60 px/s do
jogo; com Reduce motion, o 1º quadro já é o final e o texto longo fica cortado). Regressão da frente A
(a completa é da T052): `check-007` 76/0 nos dois perfis; `check-003` 22/3 nos dois, com as 3 falhas
(SC-004: o comando digitado não chega no terminal depois de fechar) iguais com o código da fundação
nesta VM, então do ambiente.

## Phase 6: User Story 4 - Janela ou tela cheia (P2) · Frente B

- [X] T032 [P] [US4] As páginas na tela cheia:
  - painel sem tinta e sem sombra, com o papel estático;
  - colunas com `stretch` em APPS, WINDOWS, no seletor e no log;
  - ~~SYSTEM centralizado~~ (trocado pelo T058);
  - limite de largura em ultrawide (FR-013, FR-014).
- [X] T033 [US4] Appearance › Menu presentation e a troca ao vivo, mantendo aba, seleção e foco (FR-013)
- [X] T034 [US4] Toasts críticos e OSD por cima do menu cheio (R5, FR-014)
- [X] T035 [US4] Validar na `t013-modos`: blocos `modes` e `perf`, nos dois modos e nos dois perfis

## Phase 7: User Story 8 - O histórico como aba do menu (P3) · Frente B

- [X] T036 [US8] `pause/PauseMenu.qml`:
  - a aba `log` entre WINDOWS e SYSTEM;
  - `notify/LogPage.qml` com o host `pause`;
  - tirar `notify/LogPopup.qml`;
  - SUPER+N, o contador da barra e `notify open` abrindo o menu em LOG;
  - marcar como lido ao fechar (FR-034).
- [X] T037 [US8] Validar: bloco `log-tab` e os blocos de log do `check-008` com o host `pause`

## Phase 8: User Story 6 - Escolher numa janelinha (P2) · Frente C

- [X] T038 [P] [US6] `ds/composites/ChoicePopup.qml`:
  - presa à direita da linha, com escurecimento ×0,8;
  - ponteiro do lado direito;
  - sobe perto da borda e rola em linhas inteiras;
  - página na galeria (FR-025, FR-027).
- [X] T039 [US6] `ds/composites/OptionRow.qml`: Enter numa escolha com mais de 3 valores abre a
  janelinha; ←→ continuam mudando direto (FR-025)
- [X] T040 [US6] O modo múltiplo (quadradinhos, pelo menos um marcado) e Keyboard › Layouts aplicado no
  Hyprland (FR-026, R6)
- [X] T041 [US6] Validar na `t013-escolha`: bloco `choice`, nos dois modos e nos dois perfis

## Phase 9: User Story 5 - Os sons da interface (P2) · Frente D

- [X] T042 [P] [US5] `services/Sounds.qml` completo:
  - `SoundEffect` em conjunto de 3, debounce de 40 ms, no máximo 4 sons;
  - pasta própria;
  - volume de interface;
  - digitação;
  - "não perturbe" e a tela cheia segurada nas notificações;
  - o `sound.json` (FR-019 a FR-024, S1).
- [X] T043 [US5] Ligar os eventos:
  - menus (`move`, `change`, `confirm`, `back`, `open`, `close`, `tab`, `dialog` e os da janelinha);
  - notificações, OSD e digitação;
  - o som de entrada uma vez por login (FR-019, FR-030, S5).
- [X] T044 [US5] Configurações › Sound: as opções da data-model (FR-022)
- [X] T045 [US5] `docs/sons-do-jogo.md`: como usar os sons da própria cópia de PC (só links pra guias e
  ferramentas) e os nomes dos eventos (FR-021)
- [X] T046 [US5] Validar na `t013-som` com `--audio-capture`: blocos `sounds` e `sound-opts` (SC-008,
  SC-009)

## Phase 10: User Story 7 - Som no boot e no login (P3) · Frente D

- [X] T047 [US7] `system/boot-login/`: a regra udev, o `yorha-os-boot-sound.service`, o script e os WAV
  por nível; `install`, `uninstall` e `status` no manifesto (contracts/boot-sound.md, FR-028, FR-031,
  FR-032)
- [X] T048 [US7] `system/login/sddm/yorha-os/`: os sons do tema, a chave `sounds` e a leitura de
  `/run/yorha-os/sound.state` (FR-029, S3)
- [X] T049 [US7] Lab: `check-011 undo` cobrindo o som de boot; `lab/bootcap --audio-capture`
- [X] T050 [US7] Validar na `teste-011`: blocos `bootsound`, `boot-timing` e `undo` (SC-012, SC-013)

## Phase 11: Polish & junção (F3)

- [X] T051 Mesclar as frentes na `013-menus-do-jogo` e na `lab-013`; resolver o que A e B mexeram no
  `PopupFrame`
  - decisão do dono (01.11): **sem som de digitação, nem como opção**. Tirar o que a frente D ligou: o
    evento `typing` no campo de busca de APPS, a opção Sound › Typing sound, a chave `sound.typing` e os
    casos dela no `sound-opts`. O `typing.wav` fica no repo, sem uso;
  - ligar `choiceOpen`/`choicePick` na janelinha da frente C (as frentes C e D trabalharam separadas)
- [X] T052 `check-013` inteiro nos dois perfis e nos dois modos; `check-003`, `check-004`, `check-007`,
  `check-008` e `check-011` verdes (SC-004)
  - feito na junção (01.11): `check-013` verde no modo janela nos dois perfis; na tela cheia, 154/6 e
    153/7, com as falhas nas medidas de tempo da frente A (decisão 7 da página de revisão);
    `check-003` 25/0 ×2, `check-004` 58/0, `check-007` 76/0, `check-008` 110/0 ×2; na `teste-011`,
    `bootsound` + `boot-timing` 11/0 (+0,04 s), `check-011 login` 6/0, `intro` 13/0, `undo` ok;
  - achado na regressão: o backend FFmpeg do Qt entra em laço com processo + som; o shell usa o
    GStreamer, e o greeter fica no FFmpeg (sondagem.md, "Na junção")
- [X] T053 A lista das diferenças esperadas do modo janela parado (FR-017), com `lab/diffshot` contra as
  evidências: `diferencas-janela.md` (17 telas, antes e depois, na junção)
  - já conhecida: a galeria passou de 6 pra 7 páginas (a 7 é a da fundação), então os subtítulos
    "N/6" viraram "N/7" (o `check-007` agora dá Tab ×4 pra voltar à 1)
- [X] T054 `docs/design-system.md` (movimento, `ScrollingLabel`, `ChoicePopup`, apresentação, sons) e
  `README.md`
- [ ] T055 Sessão do dono numa janela da VM: os dois modos, a janelinha e os sons; ajustar os números
  (SC-007, SC-011)
- [X] T057 Acabamento herdado da 008: no log, o ◂ OFF ▸ (coluna estreita de 70) não alinha com o
  valor de Show logo abaixo; alinhar as colunas de valor das opções do log
- [X] T058 Pedido do dono na sessão (01.11): na tela cheia, SYSTEM e POWER esticam as colunas como as
  outras abas, em vez de centralizar o quadro de 1612. A coluna da esquerda fica na margem do título,
  a do meio no meio e o card da direita termina na ponta da régua, como nos frames do jogo. O
  `check-013` (bloco `modes`) passa a medir as colunas das 5 abas pelo `geometry.columns` do dump.
  Aprovado pelo dono na `teste-011`. Na `t013-modos`: `check-013 --only modes` 44/0 em 1080 e
  hidpi, `check-003` 25/0 nos dois perfis, `check-007` 76/0, qmllint limpo (perf
  `2026-11-01T083120-vm-t013-modos-013-t058-tela-cheia-colunas-alinhadas`)
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
