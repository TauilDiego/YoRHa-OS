---
description: "Tarefas da 019: SYSTEM de verdade (etapas 0 e 1, US6 e US7)"
---

# Tasks: SYSTEM de verdade

**Input**: `specs/019-sistema-real/` (`plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

**Testes:** pedidos pela spec, e a constituição exige evidência. Cada tarefa de teste nomeia a dela e roda dentro de `lab/perf begin`/`end`, com `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`.

**Formato:** `[P]` roda em paralelo com as outras frentes; dentro de uma frente, as tarefas vão em ordem. `[US#]` é a história da spec. `US2.3` é o cenário 3 da história 2. Os caminhos `lab/…`
são do repositório privado.

**Frentes (todas em Opus 5.5 high):** 0, 1A, 1B, 1C, 1D e J. Worktrees, VMs e arquivos de cada uma estão em `plan.md`. Cada agente commita só na própria branch, nunca na `main`, e o repositório privado não recebe push.
Nenhuma tarefa roda na máquina do dono.

---

## Phase 1: Prova da base (Frente 0, Opus 5.5 high)

**Purpose**: provar na VM, antes de qualquer código do shell, que a detecção da D2 funciona.

- [x] T001 Frente 0: criar a branch `lab-019` a partir de `lab-015-correcoes` (`b44fe67`), na worktree `YoRHa-OS-private-wt/lab-019`; em `lab/guest/hyprland.lua`, definir `YORHA_MOD = "ALT"` e `local mod = YORHA_MOD` (R2). **Evidência:** `git log -1 lab-019`, e `lab/check-003 --only 1` passa com o atalho ALT+I. **Feito: `196e594` na `lab-019`; `check-003 --only 1`, 2 PASS, 0 FAIL (ALT+I), `perf` `2026-11-03T200900-…-t001-…`.**
- [x] T002 Frente 0: escrever `lab/019/prova-base <vm>`, que roda P1 a P9 de `research.md` R1 sem o shell, com um `hyprland.lua` de teste e `socat` no socket2 (`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock`). Saída: PASS/FAIL por item e os valores crus em `out/prova-base-<vm>-<data>/`. **Evidência:** o script roda até o fim em `t-prova-56`, sem travar. **Feito: `lab/019/prova-base` e `prova-base.guest` rodam até o fim, com `raw/` e `results.txt`.**
- [x] T003 Frente 0: **primeira tarefa de teste.** Rodar a prova em `t-prova-56` (de `hypr-iso`, 0.56.2) e `t-prova-57` (de `hypr-057`, 0.57.0, com as armadilhas do README da `lab-057`), medida por `lab/perf`, e registrar em `specs/019-sistema-real/sondagem.md`: resultado de cada item, o caminho da pasta, o resumo do relatório. **Evidência:** `results.txt` das duas versões. **Portão:** com falha em P1 a P7 que a coluna da direita de R1 não resolva, parar e reportar: a D2 volta pro dono. **Feito: P1 a P9 passam em 0.56.2 e 0.57.0, em `sondagem.md`. A prova achou a trava do Hyprland, e a espera de 300 ms antes de ler entrou por causa dela; corrigido em 05.11: a causa não são os pedidos, e a espera não tem benefício mostrado (`sondagem.md`). `results.txt` copiados em `central/sistema-real-019/etapa-0/t003/`.**

**Checkpoint**: só segue com a prova registrada. Se uma falha mudou o desenho, atualizar `research.md` e `contracts/file-rule.md` antes da T004.

---

## Phase 2: Etapa 0, a base comum (US1, Frente 0, Opus 5.5 high)

**Goal**: o contrato (FR-011) pronto, testado e congelado antes do paralelo. **Independent Test**: com o catálogo de teste, as checks antigas passam; com o de prova, uma linha lê, muda e fica indisponível.

### Dados e textos

- [x] T004 [US1] Copiar `shell/fixtures/settings-default.json` pra `shell/fixtures/settings-showroom.json`, sem mudar nada (FR-008), e acrescentar `"settings": "fixtures/settings-showroom.json"` a todo fixture de topo que existe hoje e não tem esse domínio (`battery-low`, `hud-default`, `hud-live-ws`, `long-title`, `muted`, `no-battery`, `no-window`, `notifications-default`, `notifications-dnd`, `notifications-long`, `notifications-positions`, `pause-broken`, `pause-default`, `pause-empty`, `pause-live`, `pause-long`, `pause-refuse`, `wallpaper-default`). `settings-long` e `settings-broken` continuam apontando pros deles. Assim os screenshots de referência não mudam, e os fixtures `sys-*` novos ficam com o catálogo do produto. **Evidência:** `diff` da cópia contra `git show 670a99f:…` vazio. **Feito: `diff` vazio contra `670a99f`; 18 fixtures ganharam o `settings`.**
- [x] T005 [US1] Atualizar `specs/001-yorha-base-hud/contracts/fixtures.schema.json` com `audioDevices`, `brightness`, `monitors`, `input`, `sysProof` (FR-009; formas em `data-model.md`), e `specs/003-settings-popup/contracts/settings.schema.json` com as linhas `sys.*`, `requires` e `opens` (FR-010). **Evidência:** validar todos os JSON de `shell/fixtures/` contra os schemas num container do lab, saída sem erro. **Feito: 25 arquivos, 0 erros, num container `archlinux` (`etapa-0/t005-validacao-schemas.txt`). O schema de fixtures também ganhou `apps`, `windows`, `session` e `notifications`, que já existiam nos fixtures e o schema recusava; `desc` deixa de ser obrigatório nas linhas `notify.*`, que tiram o texto de `Strings.notify`.**
- [x] T006 [US1] Acrescentar em `shell/strings/` todos os textos das frentes em `Strings.settings.sys`, em inglês: "No sound output found.", "No microphone found.", "No backlight on this screen.", "brightnessctl is not installed, so this can't change here.", "No battery on this machine.", "UPower is not installed.", os de falha de escrita, microfone mudo, `Custom`, e os nomes da lista de atalhos (FR-004). Sem texto solto em outros arquivos. **Evidência:** `qs` sobe sem erro de QML no `ui.log`. **Feito: `Strings.settings.sys`; `ui.log` sem erro.**

### Contrato em código

- [x] T007 [US1] Criar os esqueletos `shell/services/SysAudio.qml`, `SysPower.qml`, `SysDisplay.qml`, `SysInput.qml` (interface de `contracts/system-provider.md`, listas vazias) e `SysProviders.qml` (`byName`), e registrar em `shell/services/qmldir` junto com `FileWins` e `SysProof`. **Evidência:** `qs` sobe sem erro; nenhum deles é citado por `settings-default.json`. **Feito: `qs` sobe sem erro; nenhum citado em `settings-default.json` (`grep`, 0).**
- [x] T008 [US1] Em `shell/services/Settings.qml`: tipo de chave `levels` (`levels`, `min`, `max`, `unit`), chaves `shell.uiScale` (0.9, 1, 1.1, 1.25; 0,5–3,0) e `shell.barHeight` (40, 50, 68, 80; 28–96), `levelsOf` com o valor fora da lista em ordem, `labelsOf`, `signal userFileRead(string state)` (`ok`, `missing`, `unreadable`), separando `FileNotFound` dos outros erros de `loadFailed`, e JSON que não é objeto como ilegível (R1, FR-033, FR-042). `uiScale` e `barHeight` continuam como estão até a 1D. **Evidência:** `settings dump` traz as duas em `shellValues`; os três estados do sinal, na T016. **Feito: `shellValues` traz `shell.uiScale` 1 e `shell.barHeight` 68; os três estados do sinal, na T016.**
- [x] T009 [US1] Em `shell/services/Compositor.qml` e `shell/services/compositor/{HyprlandBackend,NullBackend}.qml`: as capacidades, `supports`, `focusedMonitorInfo`, `sessionId`, `configValues`, `readConfig`, `setConfigValues`, `configRead`, e `width`, `height`, `refreshRate` em `monitors`, conforme `contracts/compositor-adapter.md`, usando o formato medido na T003 (FR-023, FR-044, FR-046). Remover `keyboardLayoutsNote` e o `multiNote` da `SettingsPage`. **Evidência:** `settings dump` com `backend`; `hyprctl` citado só em `shell/services/compositor/` e em comentários. **Feito: `backend` no dump; a busca da US7.4 só acha comentários. Acréscimo ao contrato: `configWriteDone`, pra 1C dizer no card quando o `eval` falha, e a leitura por `hyprctl --batch`.**
- [x] T010 [US1] Criar `shell/services/FileWins.qml` conforme `contracts/file-rule.md` e as transições de `data-model.md`: as duas comparações, `capsPart`, `mergeCaps`, `applySaved`, `dump`, chaves `fileBase.*` em `SettingsState` (FR-026, FR-027, FR-039, FR-041, FR-042, FR-043). **Evidência:** os testes da T016. **Feito: testes da T016.**
- [x] T011 [US1] Em `shell/services/SettingsModel.qml`, o caminho `sys.*` de `contracts/system-provider.md`: `liveOf`, `resolve`, `value`, `display`, `textOf` (info lê de `resolve`), `set`, `step`, `pick`, `activate`, `isDimmed`, `needsText`, `reset`, `dumpValues`, `liveIds`, `dimmedIds`, `reasons`, `hiddenIds`, `visibleCategories`, `watching`, `problemOf`, `liveFits` e a DEFAULT das chaves `levels`; a lista `retired`, removida na subida (FR-001 a FR-007, FR-010, FR-045). **Evidência:** a T015. **Feito: testes da T015.**
- [x] T012 [US1] Em `shell/settings/SettingsPage.qml`, `shell/ds/composites/ChoicePopup.qml`, `shell/shell.qml` e `shell/gallery/Gallery.qml`: usar `visibleCategories`; card só com NOW e com `metaOf` e `note` em `sys.*` (FR-005); janelinha que segue a lista aberta, com foco num item existente (US2.6, FR-003); `readOnly` pro `opens`, que rola por linhas inteiras e na roda (FR-036); `watching` (R5); no `settings dump`, `reasons`, `hidden`, `backend`, `fileBase` (`contracts/ipc.md`). **Evidência:** a T015. **Feito: testes da T015; `ChoicePopup.geometry` ganhou `first` e `overflows` pros testes.**
- [x] T013 [US1] Em `shell/fixtures/settings-default.json`: só `"requires": "keyboardLayouts"` em Keyboard › Layouts (FR-045). Criar `shell/services/SysProof.qml`, `shell/fixtures/settings-proof.json` (choice, slider, toggle, info, `opens`) e `shell/fixtures/sys-proof.json`, com `available` e `failWrites` vindos do fixture e mudando por `fixtures load` (FR-001, FR-003, FR-004, FR-009). **Evidência:** `settings dump` com o fixture lista as linhas em `live`. **Feito: `live` lista as 5 linhas (T015).**

### Testes da base

- [x] T014 [US1] Em `lab-019`: criar `lab/check-019` no padrão da `check-004` (`--only`, `--profile`, `summary.txt`, `results.txt`, `log_check` com `expected-warn`), que faz `source` de `lab/019/block-{contract,filewins,adapter,audio,reads,keyboard,appearance,catalog}.sh`; os das frentes começam vazios. Criar `lab/019/audio-sinks` (um segundo null sink persistente, e `Audio/Source`, R6). Documentar em `lab/README.md`. **Evidência:** `lab/check-019 --only contract` roda em `t-base-0`. **Feito: `lab/check-019`, `lab/019/audio-sinks`, `lab/README.md`.**
- [x] T015 [US1] `lab/019/block-contract.sh`, com o catálogo de prova: US1.1 (muda por `fixtures load`, `settings dump` antes e depois); US1.2 (`available` falso: focável, ← → e Enter sem efeito, motivo no card, screenshot e `dimmed`); FR-002 (`failWrites`: volta ao real e o card diz); FR-003 (lista muda, id estável); FR-005 (só NOW); `opens` só leitura. **Evidência:** `results.txt` e screenshots. **Feito: dentro da T019.**
- [x] T016 [US6] Frente 0, `lab/019/block-filewins.sh`, com chaves que já existem, sem fixture: US6.3 (Reduce motion, Vignette, Background motion, chave por chave, `shellValues` e `jq`), US6.4 (JSON inválido e volta), US6.7 (`defaults.json` muda, FR-043); mais `shell.json` apagado (Edge Case), valor inválido em chave de arquivo legível (FR-042), Bar contrast, Menu presentation, `sound.*`, `updates.*`, `notifications.*` (FR-041), e primeira subida sem base (nada esquecido). **Evidência:** `jq` no `settings.json` depois de cada passo, `results.txt`. **Feito: dentro da T019.**
- [x] T017 [US1] `lab/019/block-contract.sh`, parte da migração: US1.3 (`settings.sound.volume` e `settings.display.brightness` no arquivo, duas subidas, FR-007, `jq` antes e depois). `lab/019/block-adapter.sh`: US7.2 (`YORHA_COMPOSITOR=niri` numa sessão Hyprland, `backend` no dump, `getoption -j` antes e depois, FR-046), US7.4 (busca, SC-010), e Layouts em `hidden` com `none`. **Evidência:** `results.txt`, `jq`. **Feito: dentro da T019.**
- [x] T018 [US1] Atualizar as checks antigas em `lab-019`, conforme R10: `lab/check-003` (comentários, showroom por `hud-default`); `lab/check-004` (o `.values == {}` ignora `fileBase.*`); `lab/check-007` (bloco `compositor` confere `hidden`); `lab/check-008` (showroom nos fixtures, `osd-quiet` sem fixture testa as linhas reais); `lab/check-013` (`choice` com fixture; `ncat` pelo `settings dump`). **Evidência:** `git diff` só nesses pontos, e a T020. **Feito: `git diff` só nesses pontos, mais o `choice` da 013, que sai do fixture antes de Layouts (o compositor é real ali).**
- [x] T019 [US1] Rodar `lab/check-019 --only contract,filewins,adapter --profile both` em `t-base-0`, medida. **Evidência:** `results.txt`, `ui.log` sem WARN nem ERROR fora dos marcados, resumo do `lab/perf`. **Feito: 76 PASS, 0 FAIL, `perf` `2026-11-03T220615-vm-t-base-0-019-t019-check-019-contract-filewins-ada`.**
- [x] T020 [US1] Rodar `lab/check-003`, `004`, `007`, `008`, `013`, `014`, `015` em `t-base-0`, nos dois perfis, cada uma medida (US1.5). As que não têm `--profile` rodam como de costume. **Evidência:** `results.txt` de cada, sem FAIL novo em relação à `015-correcoes`, resumo do `lab/perf`. **Feito: `check-003` 25/0 e 25/0 (1080 e hidpi), `004` 63/0, `007` 77/0 (76 da base + 1 novo), `008` 110/0 e 110/0, `013` 173/0 (1080) e 172/1 (hidpi), `014` 68/0, `015` 116/0. Sem FAIL novo. O único FAIL é `FR-009 a grade antes dos triângulos` (137 ms; o limite é 133), o mesmo item que a base teve (`134`, `corr-check-013-142934`). Conferido alternando base `15bea74` e 019, 6 rodadas cada, `--only open` em hidpi: média 115 x 119 ms, e os dois lados falham em itens do FR-009 (`perf` `2026-11-03T222518-…-fr-009-alternado-…`). A `014` e a `015` rodam em `t-base-1`, uma camada de `lab/015/prep`: elas precisam de uma pessoa comum, sem o `nier-ui-run`. As checks antigas escrevem `summary.txt`, não `results.txt`. Evidência em `central/sistema-real-019/etapa-0/t020/`.**
- [x] T021 [US1] **Congelar o contrato:** commitar na `019-sistema-real` e na `lab-019`, escrever os dois ids aqui, em `tasks.md`, e criar as worktrees `019-a` a `019-d` e `lab-019-a` a `lab-019-d` a partir desses commits. **Evidência:** `git worktree list`. Depois disso, `SettingsModel`, `SettingsPage`, `Strings`, `qmldir` e schemas não mudam mais no paralelo. **Congelado: `50027af` na `019-sistema-real` e `df20ec2` na `lab-019`. As frentes saem do commit seguinte da `019-sistema-real`, que só escreve estes ids aqui.**

**Checkpoint**: etapa 0 fechada. As quatro frentes podem começar juntas (máximo de 4 VMs).

---

## Phase 3: Etapa 1A, som (US2, Frente 1A, Opus 5.5 high)

**Goal**: saída, volume, mudo e microfone leem e mudam o PipeWire, sem cópia. **Independent Test**: com 2 null sinks, trocar saída e volume pelo teclado e conferir no `wpctl`. VM: `t-som-1a`.

- [x] T022 [P] [US2] Frente 1A: `shell/services/SysAudio.qml`, `output`: lista de `Pipewire.nodes` (sink, sem fluxo, sem `auto_null`), `node.name` como id, nome por `description`, padrão real, e a troca por `preferredDefaultAudioSink` (FR-013, FR-017, R6); fixture `audioDevices` primeiro (FR-009). **Evidência:** a T026. **Feito em `28c5c96`: `SysAudio`, `output`. Prova na T028.**
- [x] T023 [P] [US2] Frente 1A: `SysAudio`, `volume`, `mute`, `mic`: leitura com `PwObjectTracker`, escrita em `audio.volume` e `audio.muted`, posição pedida por 300 ms, `rangeOf`, `note` de microfone mudo, motivos (FR-014, FR-015, FR-016, FR-017, FR-018). **Evidência:** a T026. **Feito em `28c5c96`: `volume`, `mute`, `mic`. Prova na T028 e em `1a/fr-002-volume-mudo.txt`.**
- [x] T024 [P] [US2] Frente 1A: em `shell/fixtures/settings-default.json`, só as linhas Output, Volume, Mute, Microphone do bloco `sound`: `setting`, sem `value`, `values`, `default`; Mute deixa de dizer "every output" (FR-015). Criar `shell/fixtures/sys-audio.json`. **Evidência:** `settings dump` lista as 4 em `live`. **Feito em `28c5c96`: as 4 linhas em `live`, `sys-audio.json`.**
- [x] T025 [P] [US2] Frente 1A: `lab/019/block-audio.sh`: US2.1 a US2.5 com `wpctl` e `settings dump`; US2.3 e SC-003 com o tempo medido (até 1 s); `osd-quiet` da `check-008`. **Evidência:** `results.txt`, screenshot da barra (MUTE). **Feito em `lab-019-a` (`3498ed4`): com o tempo medido, dentro de 1 s; `osd-quiet` na T028.**
- [x] T026 [P] [US2] Frente 1A: acrescentar ao bloco os casos de borda: US2.6 (`pw-cli destroy`, lista aberta), US2.7 (nenhum sink, conferindo se `auto_null` aparece, R6), uma saída só, mais de 3 saídas (janelinha, FR-036), nome longo (`ScrollingLabel`), volume acima de 100% (card com o real), tecla segurada. **Evidência:** screenshots, log do QML. **Feito em `lab-019-a` (`731a244`). Achou o FAIL do nome longo (corrigido na junção, item 1), a barra na Dummy Output (item 4) e o número inventado (item 5). O laço `QSocketNotifier` vira FAIL visível, e a causa é da `fix-laco-log`.**
- [x] T027 [P] [US2] Frente 1A: acrescentar ao bloco US2.8 (reboot da VM; se a saída não ficar, parar: a D4 volta pro dono), e US1.4 (`settings reset` não muda `wpctl get-volume`, FR-006). **Evidência:** `wpctl status` antes e depois, `jq`. **Feito em `731a244`: US2.8 passa, a D4 não volta pro dono; US1.4 passa.**
- [x] T028 [P] [US2] Frente 1A: rodar `lab/check-019 --only contract,audio --profile both` e `lab/check-008 --only osd-quiet`, medidas, e commitar em `019-a` e `lab-019-a`. **Evidência:** `results.txt`, `ui.log`, resumo do `lab/perf`. **Feito: `check-019 --only contract,audio` 94 PASS e 2 FAIL (`2026-11-05T161505-…-t028-…`, o nome longo no card), e 68 PASS e 0 FAIL com o patch (`2026-11-05T162731-…`); `check-008 --only osd-quiet` 3 PASS (`2026-11-05T161244-…`). Evidência em `central/sistema-real-019/1a/`.**

**Checkpoint**: som pronto na VM. Saídas e microfone reais ficam na lista do dono.

---

## Phase 4: Etapa 1B, leituras (US3, Frente 1B, Opus 5.5 high)

**Goal**: bateria, luz e tela dizem a verdade, ou dizem que a máquina não tem. **Independent Test**: sem fixture, Battery e Brightness apagadas com o motivo e Display igual ao `hyprctl`; com fixture, os valores dele. VM: `t-leituras-1b`.

- [x] T029 [P] [US3] Frente 1B: `shell/services/SysPower.qml`, `battery`: texto de `Battery.bat` (`64%`, `87% · charging`), e os dois motivos pelo `upowerInstalled` (FR-019, R8). **Evidência:** a T033. **Feito em `5cee970`. Prova na T035.**
- [x] T030 [P] [US3] Frente 1B: `shell/services/Osd.qml` expõe `brightnessPercent`, `backlightDevice`, com leitura na subida (FR-020, R7); `shell/services/SysDisplay.qml`, `brightness`: leitura, fixture, `brightnessctl --device=<nome> set <n>%`, última posição vence, faixa 5–100, ferramenta ausente, escrita falha (FR-020, FR-021, FR-022). **Evidência:** a T033. **Feito em `5cee970`: e o `Osd` lia o valor anterior depois de um reload do `FileView`, corrigido com `blockAllReads`. Prova na T035.**
- [x] T031 [P] [US3] Frente 1B: `SysDisplay`, `resolution`, `refresh`, `scale`: de `Compositor.focusedMonitorInfo`, nome da tela em `metaOf`, releitura com `watching` (FR-023, R3, R5, D5). **Evidência:** a T034. **Feito em `5cee970` e `546fcb6` (o backend não pede nada na espera depois de um reload). Prova na T035.**
- [x] T032 [P] [US3] Frente 1B: em `shell/fixtures/settings-default.json`, só as linhas Resolution, Refresh rate, Scale, Brightness do bloco `display`, com `requires: "monitorInfo"` nas três primeiras, e Battery do bloco `power`. Criar `shell/fixtures/sys-battery-64.json`, `sys-battery-87.json`, `sys-brightness.json`, `sys-no-tool.json`. **Evidência:** `settings dump` lista as 5 em `live`. **Feito em `5cee970`: as 5 linhas em `live`; schemas em `1b/t032-validacao-schemas.txt`.**
- [x] T033 [P] [US3] Frente 1B: `lab/019/block-reads.sh`: "UPower is not installed." na camada limpa e, depois de instalar `upower` na `t-leituras-1b`, US3.1 (barra sem BAT); US3.2; US3.3; US3.4 (`settings dump`, nada escrito); sem `brightnessctl` por fixture (FR-021). **Evidência:** screenshots, `settings dump`. **Feito em `lab-019-b` (`07b9801`). A luz de tela real não existe na VM: um backlight simulado (tmpfs e um `brightnessctl` falso) roda o caminho real, sem o evento de udev, que fica na lista do dono.**
- [x] T034 [P] [US3] Frente 1B: acrescentar US3.5 (duas telas, `settings dump` contra `monitors -j`), US3.6 (escala por `hyprctl eval`, em até 1 s, SC-003), US3.7 (saída `headless`, foco, nome no card). **Evidência:** comparação no `results.txt`, screenshot. **Feito em `07b9801`.**
- [x] T035 [P] [US3] Frente 1B: rodar `lab/check-019 --only contract,reads --profile both`, medida, e commitar em `019-b` e `lab-019-b`. **Evidência:** `results.txt`, `ui.log`, resumo do `lab/perf`. **Feito: `check-019 --only contract,reads --profile both` 120 PASS e 0 FAIL (`2026-11-05T154011-…-t035-…`), regressão de `check-007`, `check-008` e `adapter` (`2026-11-05T162320-…`, as três com rc 0). Evidência em `central/sistema-real-019/1b/`.**

**Checkpoint**: leituras prontas na VM. Bateria e luz de verdade ficam na lista do dono (SC-007).

---

## Phase 5: Etapa 1C, teclado (US4, Frente 1C, Opus 5.5 high)

**Goal**: repetição e Caps Lock mudam na hora, sobrevivem a reload e login, e o arquivo é da pessoa. **Independent Test**: mudar Repeat delay, dar `hyprctl reload`, conferir `getoption`. VM: `t-teclado-1c`.

- [x] T036 [P] [US4] Frente 1C: `shell/services/SysInput.qml`: `delay`, `rate`, `caps` sobre `Compositor.configValues` e `input.*` em `SettingsState`; níveis da R3 (valor fora da lista, `Custom`), `rangeOf` 5–100, `resetSaved` sem reload (FR-024, FR-025, FR-027, FR-028, FR-029); releitura com `watching` (R5); fixture `input`. **Evidência:** a T039. **Feito em `b57302a`. Prova na T042.**
- [x] T037 [P] [US6] Frente 1C: em `shell/services/compositor/HyprlandBackend.qml` e na parte de layouts de `shell/services/Compositor.qml`: sai o reaplicar por `mismatch` e o `applyKeyboardLayouts` do reload; Layouts passa por `FileWins`, como as outras (FR-026, FR-040). O reaplicar continua em ~150 ms, como a 013 mediu. **Evidência:** a T041. **Feito em `b57302a`: `check-013 --only choice` (Layouts) passa (`2026-11-05T155556-…`). Prova na T042.**
- [x] T038 [P] [US4] Frente 1C: `HyprlandBackend.shortcuts` e `shortcutModifier` (`hyprctl repl`, R2); `SysInput.shortcuts`, com aviso quando o compositor não disser (FR-030, FR-036, FR-044). Em `shell/fixtures/settings-default.json`, só as linhas Caps Lock, Repeat delay, Repeat rate e Shortcuts do bloco `keyboard`, com `requires`, e a descrição de Shortcuts dizendo que são os atalhos do produto (FR-030, FR-031). Criar `shell/fixtures/sys-input.json`. **Evidência:** a T040. **Feito em `b57302a`: `shortcuts`, `shortcutModifier`, `sys-input.json`. Prova na T042.**
- [x] T039 [P] [US4] Frente 1C: `lab/019/block-keyboard.sh`: US4.1, US4.2, US4.3, US4.4, US4.5, com `getoption -j` e `jq`; `kb_options` com regra própria (`Custom`); falha de `eval` (FR-002); `settings reset` sem reload (FR-029); `eval` de fora na linha em até 1 s (SC-003); config mudada com reload e nada salvo (Edge Case). **Evidência:** `results.txt`. **Feito em `lab-019-c` (`fd88b54`).**
- [x] T040 [P] [US4] Frente 1C: acrescentar US4.6 (extrai os `hl.bind` de `system/hypr/yorha-shell.lua` e compara com a lista aberta), US4.7 (`sha256sum`, SC-004), e o aviso do modificador pelo fixture (`modifier: null`). **Evidência:** screenshot, comparação no `results.txt`. **Feito em `fd88b54`.**
- [x] T041 [P] [US6] Frente 1C: acrescentar US4.8, US4.9, US4.10, US4.11, US6.1, US6.5, US6.6, US6.8, cada passo com `getoption -j` e `jq`; login novo (`hl.dsp.exit()`, compara como reload, FR-039); as duas bases de Layouts (`kb_layout` e `kbLayouts`). **Evidência:** `results.txt` (SC-009). **Feito em `fd88b54`. Medido à parte: um `dispatch` de fora na janela de 300 ms com a config com erro (limite na spec) e as duas bases de Layouts (decisão do dono, 05.11, na spec).**
- [x] T042 [P] [US4] Frente 1C: rodar `lab/check-019 --only contract,filewins,keyboard --profile both` em `t-teclado-1c`, e a mesma `keyboard` numa camada de `hypr-057` (`t-teclado-57`) em 1080, medidas; commitar em `019-c` e `lab-019-c`. **Evidência:** `results.txt`, `ui.log`, resumo do `lab/perf`. **Feito: `check-019 --only contract,filewins,keyboard --profile both` 170 PASS e 0 FAIL (`2026-11-05T155716-…-t042-…`), `keyboard` em 1080 na 0.57.0 (`t-teclado-57`) 51 PASS e 0 FAIL (`2026-11-05T162810-…`). As branches continuam com a mensagem "em teste" de um checkpoint, e o conteúdo é o que rodou. Evidência em `central/sistema-real-019/1c/`.**

**Checkpoint**: teclado pronto na VM. A sensação da repetição e o Caps Lock físico ficam na lista do dono.

---

## Phase 6: Etapa 1D, aparência (US5, Frente 1D, Opus 5.5 high)

**Goal**: tamanho da UI e altura da barra mudam na hora, sem estourar nada. **Independent Test**: trocar as duas opções e olhar menu e barra em 1080 e 1,25. VM: `t-aparencia-1d`.

- [x] T043 [P] [US5] Frente 1D: em `shell/services/Settings.qml`, só `uiScale` e `barHeight`: leem `valueOf("shell.uiScale")` e `valueOf("shell.barHeight")`, mantendo a faixa e o valor fora da lista (FR-032, FR-033). Em `shell/fixtures/settings-default.json`, só as linhas Interface scale e Top bar height do bloco `appearance`. **Evidência:** `settings dump`. **Feito: `settings dump` com as duas linhas em `live`, 100% e 68 px. Um valor fora da faixa no `shell.json` agora cai no padrão, como a FR-042 pede: antes o `barHeight` era limitado a 96 e arredondado.**
- [x] T044 [P] [US5] Frente 1D: `lab/019/block-appearance.sh`: US5.1 a US5.3 (screenshots e `geometry` de cada valor e das combinações, nas duas telas; `hyprctl layers`), US5.4, US5.5 (log limpo), US5.6, e o foco parado na linha quando a UI muda. **Evidência:** screenshots, `settings dump`. **Feito: o bloco nas duas telas, com screenshots em `central/sistema-real-019/1d/t047/check-019/`. As transições só têm o término medido: a janela do kitty cobre o papel de parede nos screenshots.**
- [x] T045 [P] [US5] Frente 1D: corrigir o que a T044 achar cortado ou estourado em `shell/hud/Hud.qml`, `shell/popup/PopupFrame.qml`, `shell/notify/OsdWindow.qml`, `shell/notify/NotifyLayer.qml`, `shell/pause/WindowsPage.qml` e nas transições do papel de parede, com colunas que cabem e rolam por linhas inteiras e `Tokens.vline` (FR-034, FR-036, FR-037). **Evidência:** antes e depois do mesmo screenshot, `lab/diffshot`. **Feito em `PopupFrame` (o painel cresce com a escala e para na tela inteira, então 125% vira cerca de 119% no menu), `Hud` (a regra fica no tamanho da barra, o vão cede, e a largura só encolhe) e `NotifyLayer` (a banda crítica por cima). `OsdWindow`, `WindowsPage` e as transições não precisaram de mudança. Em 100% com 68 px, 0 px de diferença contra `01d9a42` em 6 telas de cada perfil. **Fica aberto:** três transmissões longas e a banda crítica passam da tela, também em 100% (ver o relatório da 1D).**
- [x] T046 [P] [US6] Frente 1D: acrescentar US6.2 (reinício sem editar, `shell.json` ganha as duas chaves, `settings dump`, `jq`, screenshot). **Evidência:** `results.txt` (SC-009). **Feito: US6.2 nas duas telas, com `jq` no `settings.json`, `settings dump` e screenshot.**
- [x] T047 [P] [US5] Frente 1D: rodar `lab/check-019 --only contract,filewins,appearance --profile both`, `lab/check-003 --only 3` e `lab/check-004`, medidas, e commitar em `019-d` e `lab-019-d`. **Evidência:** `results.txt`, `ui.log`, resumo do `lab/perf`. **Feito em `a9e038e` e `5dd4cfe`: `check-019` 132 PASS e 0 FAIL (`2026-11-05T203039-…`), `check-003 --only 3` 4 e 0 (`…T205329-…`), `check-004` 63 e 0 (`…T205419-…`). **Intermitente, fora da 1D:** uma rodada anterior no mesmo commit teve 1 FAIL na FR-042, causado por `onFileChanged: reload()` em `Settings.qml`, que já existe na `main`; a proposta está em `central/sistema-real-019/1d/fr-042/`.**

**Checkpoint**: aparência pronta na VM. O olhar no notebook fica com o dono.

---

## Phase 7: Junção (US7, Frente J, Opus 5.5 high)

**Purpose**: juntar as frentes, fechar o que depende de todas e fazer a rodada inteira. Merge na `019-sistema-real` e na `lab-019`; **não** na `main`, que é do dono.

- [ ] T048 Frente J: mesclar `019-a` a `019-d` em `019-sistema-real` e `lab-019-a` a `lab-019-d` em `lab-019`. Um conflito em arquivo que outra frente não devia tocar é registrado como contrato furado. **Evidência:** `git log --merges`, e o catálogo com as 15 linhas em `live`.
- [ ] T049 [US7] Frente J: em `lab/019/block-adapter.sh`, US7.1 (`YORHA_COMPOSITOR=none`: teclado e Display do compositor em `hidden`, Sound funcionando, `wpctl`) e US7.3 (Keyboard vazia não aparece, nenhuma coluna vazia, screenshot, FR-031, FR-045). **Evidência:** `results.txt`, screenshot (SC-010).
- [ ] T050 Frente J: `lab/019/block-catalog.sh`: SC-001 (15 linhas comparadas com o sistema, ou apagadas com motivo), SC-002 (busca por `87% · charging` e pelos valores falsos da etapa 1 no dump), SC-004, e as regras: nenhum som novo (FR-035), `system/deps` igual à base (FR-038), `Tokens.vline` nas linhas finas novas (FR-037). **Evidência:** `results.txt`.
- [ ] T051 Frente J: rodar a rodada inteira do `quickstart.md` em `t-juncao-1` e `t-juncao-2`: `check-003`, `004`, `007`, `008`, `013`, `014`, `015`, `019`, em 1080 e 1,25, cada uma medida (SC-005). **Evidência:** `results.txt`, `ui.log`, resumo do `lab/perf`.
- [ ] T052 Frente J: anotar as revisões nas specs antigas (uma linha, apontando pra 019) em `specs/003-settings-popup/spec.md` (FR-017, FR-018, FR-019), `specs/004-wallpaper-system/spec.md` (FR-030, FR-031), `specs/008-pod-text-log/spec.md` e `specs/013-menus-do-jogo/research.md` (R6), e documentar a `check-019` em `lab/README.md`. **Evidência:** `git diff`.
- [ ] T053 Frente J: juntar em `out/019-antes-depois/` os screenshots de cada categoria mudada, antes (`670a99f`) e depois, nas duas telas (SC-006), e escrever a lista dos testes do dono do `plan.md`, marcada como dele e não feita (SC-007). Quem abre no Chrome do dono é quem coordena. **Evidência:** a pasta e a lista, citadas no relatório.

**Checkpoint**: etapas 0 e 1 prontas na branch. A release ainda espera as etapas 2 e 3 (SC-008, FR-012).

---

## Dependencies

```text
T001 → T002 → T003 (PORTÃO) → T004 … T021 (congelamento)
                                   ├─→ 1A: T022 … T028 ┐
                                   ├─→ 1B: T029 … T035 ├─→ J: T048 … T053
                                   ├─→ 1C: T036 … T042 ┤
                                   └─→ 1D: T043 … T047 ┘
```

- Nenhuma frente depende de outra. Toda frente depende da T021.
- US6 está dividida pelo que cada cenário usa: T016 (chaves existentes), T041 (compositor), T046 (aparência). O motor é a T010.
- US7 está dividida: T009, T017 (etapa 0), T049 (depois das frentes).

## Parallel Example

```text
Depois da T021, quatro agentes, cada um com worktree e VM próprios:
  1A: 019-a, lab-019-a, t-som-1a        1B: 019-b, lab-019-b, t-leituras-1b
  1C: 019-c, lab-019-c, t-teclado-1c    1D: 019-d, lab-019-d, t-aparencia-1d
```

A camada `t-teclado-57` da T042 sobe só depois de `t-teclado-1c` desligar, pra não passar de 4 VMs.

## Implementation Strategy

1. **Prova primeiro:** T001 a T003. Se a detecção não se provar, o trabalho volta pro dono antes de custar as frentes.
2. **Contrato:** T004 a T021, num agente só.
3. **Paralelo:** 1A, 1B, 1C, 1D. Cada uma entrega um pedaço testável sozinho.
4. **Junção:** T048 a T053.
5. **Depois:** o dono vê o antes e depois e faz os testes dele. As etapas 2 e 3 seguem o `plan.md`, uma conversa por ferramenta.
