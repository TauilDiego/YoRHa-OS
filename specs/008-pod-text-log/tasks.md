---
description: "Tarefas da 008: Pod e text log (notificações e OSD)"
---

# Tasks: Pod e text log (notificações e OSD)

**Input**: `specs/008-pod-text-log/` (plan.md, spec.md, research.md, data-model.md, contracts/,
quickstart.md)

**Status**: plano aprovado pelo dono. MVP (T001–T027) pronto em 2026-10-28; US2 (T028–T031) pronta em 2026-10-29.

**Tests**: a spec não pede testes automatizados. A prova de cada tarefa é a evidência da VM
(princípio IV): `qs ipc call notify dump` (e `hud dump`, `settings dump`), screenshot, `lab/diffshot`,
`lab/burst`, a saída do `notify-send`/`lab/notify-client`, `wpctl`, `stat` e o log de QML sem erro e
sem aviso, sempre dentro de `lab/perf begin/end`.

**Caminhos**:
- `shell/…` = repositório público `YoRHa-OS` (esta worktree);
- `lab/…` = repositório privado `YoRHa-OS-private` (`~/projects/YoRHa-OS-private/lab/`), branch
  `lab-008`.

**Laboratório**: no máximo **4 VMs ao mesmo tempo, 2 núcleos e 4 GB cada**
(`NIER_LAB_CPUS=2 NIER_LAB_MEM=4G`). Cada frente paralela usa a própria `teste-*` e a própria porta
SSH (`NIER_LAB_VM=<vm>`).

**Atalhos**: `ALT + N` e `ALT + CTRL + N` são **provisórios** (proposta pendente do dono); trocar é
mudar o `lab/guest/hyprland.lua` e `contracts/ipc.md`.

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: história da spec (US1–US7)
- **Frente** (A–D, no fim de cada tarefa paralela): qual agente faz (ver "Frentes paralelas")

---

## Phase 1: Setup (laboratório e spike)

**Purpose**: a VM de teste com `notify-send`, PipeWire e nenhum outro servidor; o cliente de teste;
o servidor do Quickshell provado na VM antes de qualquer desenho.

- [x] T001 [P] Criar `lab/provision/notify.sh` (roda **dentro** da VM `teste-*`, nunca nas camadas congeladas) e a entrada `lab/provision notify`. Ele instala `libnotify pipewire wireplumber brightnessctl` com `pacman -S --needed`, liga `pipewire`/`wireplumber` do usuário e cria um sink e um source nulos persistentes (config do WirePlumber em `~/.config/wireplumber/wireplumber.conf.d/` **da VM**), com o sink padrão em 64%. Termina falhando se achar um `.service` com `Name=org.freedesktop.Notifications` em `/usr/share/dbus-1/services/` ou `~/.local/share/dbus-1/services/` (research R3). Bash `set -euo pipefail`, `shellcheck` limpo (container) — **feito** (`lab-008` `2f33636`): a entrada é `lab/provision-step notify` (`lab/provision` já é a pasta dos passos); rodou de novo nesta sessão sem erro, sink nulo a 64%; `lab/perf` 2026-10-28T160556 (`teste-b`)
- [x] T002 [P] Criar `lab/notify-client` (roda na VM, via `lab/ssh`; só `gdbus`, do `glib2`). Subcomandos (research R5):
  - `reply` (ação `inline-reply`; espera `NotificationReplied` com `gdbus monitor` e imprime o texto);
  - `replace <id>`, `progress <id> <0-100>`, `flood <n> [app]`, `image <caminho>`;
  - `hold-name` (pega `org.freedesktop.Notifications` e segura até Ctrl-C, pro caso de borda da FR-002).

  Textos fixos ou de argv, sem `eval`; `shellcheck` limpo — **feito** (`2f33636`); `send` passou a aceitar app vazio (caso de borda); usado pelo bloco `edge` do `check-008`
- [x] T003 [P] `lab/guest/hyprland.lua`:
  - os atalhos provisórios:
    - `ALT + N` → `qs -p ~/nier/ui ipc call notify toggle`;
    - `ALT + CTRL + N` → `… notify dnd toggle`;
  - as teclas de volume:
    - `XF86AudioRaiseVolume`/`LowerVolume` → `wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 2%+/-`;
    - `XF86AudioMute` → `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`;
    - `XF86AudioMicMute` → o mesmo no source;
  - regras de camada sem animação pras namespaces `yorha-notify` e `yorha-osd` (conferir como o `yorha-popup` já está).

  Conferir que o `lab/key` manda `volumeup`, `volumedown`, `audiomute` pelo QMP. Registrar no `lab/README.md` — **feito** (`2f33636`): ALT+N, ALT+CTRL+N, as quatro teclas de volume e as `layer_rule` `no_anim`; o `lab/key` manda qcodes do QMP (`volumeup`, `volumedown`, `audiomute`)
- [x] T004 **Spike na VM** (`lab/perf begin "008: spike do servidor"`): uma UI mínima em `lab/mockups/notify-spike/shell.qml` com um `NotificationServer` (todas as flags de research R1). Ela loga cada notificação (campos, `actions`, `hints`, `image`) e confirma:
  1. `notify-send` chega e o `busctl --user status` mostra o `qs` como dono;
  2. o nome exato da flag de resposta (`inlineReplySupported`) e o `lab/notify-client reply` recebendo o texto do `sendInlineReply`;
  3. `replaces_id` muda o mesmo objeto, sem sinal novo (R4);
  4. a `image` de um `image-path` e de dados de imagem (`image://…`);
  5. um `PanelWindow` com `WlrKeyboardFocus.OnDemand` → `None` devolvendo o foco pra janela de antes;
  6. `keepOnReload` reemitindo com `lastGeneration` depois de uma recarga;
  7. o modo 600 mantido depois de uma escrita atômica do `FileView` (R14);
  8. o `udevadm monitor --kernel --subsystem-match=backlight` rodando sem root.

  Registrar o resultado na seção "Validações" do `lab/README.md`. **Se 1 ou 2 falharem, parar e levar ao dono.** — **feito** (`2f33636`, `lab/perf` 2026-10-27T222820, `teste-a`): as 8 perguntas respondidas no `lab/README.md`; a resposta usa `Exclusive` (o `OnDemand` só pega o teclado depois de um clique)
- [x] T005 Criar o esqueleto do `lab/check-008` no padrão do `lab/check-u1` (`ok`/`ko`, pasta de evidência, `summary.txt`, `--only <bloco>`, `--profile 1080|hidpi`). Ele já roda as pré-condições do quickstart (sem outro servidor, dono do nome, sink nulo, log limpo) e o bloco `server`. Documentar T001–T005 no `lab/README.md` — **feito** (`2f33636`): pré-condições + bloco `server` (PASS nesta sessão)

**Checkpoint**: a VM de teste aceita `notify-send`, o servidor do Quickshell funciona, as perguntas do
spike têm resposta.

---

## Phase 2: Foundational (contrato; fixtures primeiro)

**Purpose**: tudo que as frentes paralelas usam. **⚠️ Depois do T020, [contracts/](contracts/) fica
congelado.**

- [x] T006 [P] `shell/ds/Tokens.qml`, bloco marcado `// --- spec 008 ---`:
  - o grupo `notify`, com todos os campos de contracts/components.md ("Tokens novos"): `band` `#1E1D19` a 84%, `bandDot`, `bandText` `#E6E1C8`, `bandText2`, `bandLine`, `bandEdge`, `bandShadow`, `block` 14, `stackW` 540, `stackGap` 12, `stackRight` 16, `stackTop` 12, `topPad` 360, `subtitleW` 1100, `subtitleBottom` 210, `critMinH` 230, `critCol` 1080, `critSide` 62, `imageSize` 72, `actionH` 32, `maxActions` 3, `lines` 4, `critLines` 3, `osdW` 600, `osdH` 72, `osdBottom` 110, `osdMeterW` 300;
  - os tempos: `cps` 90, `typeMaxMs` 700, `lowMs` 4000, `normalMs` 6000, `perCharsMs` 1000 a cada 80 além de 120, `maxMs` 12000, `osdHold` 1200;
  - os papéis tipográficos da faixa — **feito**; o lint e o carregamento limpos (`lab/perf` 2026-10-28T160556 (`teste-b`))
- [x] T007 [P] `shell/strings/Strings.qml`, grupo `notify` (inglês, FR-035):
  - o título (`LOG`, `-Transmissions`), `NOW`, `EARLIER`, `NEW`, `CRITICAL`, `+%1 in log`, `More in log`, `Reply`, `Send`, `Unknown`;
  - as frases do meio: "The app closed this notification.", "From an earlier session.", "No transmissions.", "Nothing here yet. New transmissions land here.";
  - as opções e valores do log (`Do not disturb`, `Show`, `All`, `Unread`, `Critical`, `Clear all`, `Clear`);
  - as informações: `UNREAD`, `KEPT`, `SERVER`, `APP`, `RECEIVED`, `URGENCY`, `STATUS`;
  - o OSD: `VOLUME`, `MUTE`, `MIC ON`, `MIC OFF`, `BRIGHTNESS`;
  - as teclas;
  - os rótulos e descrições das 11 opções da FR-039, com a descrição do `Text log` da FR-042;
  - as vozes (`Relay 01`, `YoRHa-OS`, `System`);
  - os textos fixos dos exemplos do injetor (mockup) — **feito**
- [x] T008 [P] Gerar `shell/fixtures/notify/avatar.png` (96×96, desenhado do zero, < 20 KB) e `shell/fixtures/notify/broken.png` (bytes aleatórios) num container `nier-lab` com ImageMagick (`lab/make-test-notify-images`) — **feito**: `avatar.png` 96×96, 1004 B; `broken.png` 3000 B aleatórios (`lab/make-test-notify-images`, `lab-008` `882ca2d`)
- [x] T009 Fixtures (domínio `notifications`, válidas contra `contracts/notifications.schema.json#/$defs/fixture`; conferir num container com python-jsonschema). Todas com `clock` fixo e os domínios da `hud-default.json`:
  - `shell/fixtures/notifications-default.json`: o mockup, com log de 6, pilha de 3 (normal, com ações, com imagem `fixtures/notify/avatar.png`), uma crítica, o OSD em volume 66, `overflow` 0;
  - `notifications-positions.json`: a mesma pilha, com o OSD;
  - `notifications-long.json`: título e app longos, sem app, só título, texto de 600 caracteres, marcação com `<b>`, `<a>`, `<img>` e `<script>`, progresso 40, 100 entradas;
  - `notifications-dnd.json`: DND, 5 normais não lidas e 1 crítica — **feito**: as 4 fixtures válidas contra `#/$defs/fixture` (python-jsonschema num container `archlinux`, label `nier-lab`)
- [x] T010 [P] `shell/config/defaults.json` + `shell/services/Settings.qml`: bloco `notifications` com os padrões da FR-039 (`position: "corner"`, `osdPosition: "bottom"`, `voice: "relay"`, `log: "session"`, `logSize: 100`, `monitor: ""`, `onScreen: 3`, `duration: "normal"`, `typing: true`, `fullscreen: "hold"`). `Settings.notifications` junta `defaults` + `shell.json` chave a chave; valor fora dos enums do schema → padrão + `console.info` (não `warn`, FR-037) — **feito**: `notifications.position: "nada"` no `shell.json` da VM → `corner` + uma linha `INFO` (`settings: notifications.position = "nada" is not an option…`), `onScreen: 5` → origem `user`
- [x] T011 [P] `shell/services/NotifyText.qml` (singleton, funções puras de contracts/services.md):
  - `sanitize`: escapa tudo, só `<b>`/`<i>`/`<u>` bem formadas, links viram texto, `<img>` e o resto saem;
  - `plain`, `cut` (n caracteres visíveis, fechando tags), `firstDiff`;
  - `duration`: `low` 4000; `normal` `min(12000, 6000 + 1000 × ceil(max(0, len − 120) / 80))`; `critical` `null`; × fator quando o app não pediu tempo — **feito**; `<script>`/`<style>` saem com o conteúdo (bloco `edge`, marcação)
- [x] T012 `shell/services/NotifyPrefs.qml` (singleton). A interface inteira de contracts/services.md, incluindo a **fonte viva** (`liveValue`, `setLiveValue`, `liveValues`, `liveChanged`). Precedência: fixture → padrões + `shell.json`; `set` em memória e validado. A escrita do estado entra na T049 — **feito**, com a interface da emenda da T013 (`levelsOf`/`levelOf`/`setLevel`/`labelsOf` no lugar da "fonte viva"); `set` valida e grava no `SettingsState` (memória com fixtures)
- [x] T013 `shell/services/SettingsModel.qml` + `shell/fixtures/settings-default.json`. **Primeiro, conferir a branch da "Bar contrast" (004):**
  - se ela já tiver um jeito de opção que vale de verdade, adotar o dela e atualizar `contracts/services.md` e research R13 antes de seguir;
  - senão, o campo `live` (research R13):
    - `liveSources: { notify: NotifyPrefs }`;
    - `value`/`step`/`activate`/`pick`/`display` delegam pras opções vivas;
    - `valuesFrom` pra `Monitor`;
    - `reset()` não toca as vivas;
    - `isLive()`;
    - `dumpValues()` com o valor vivo.

  A categoria `notifications` entra depois de `sound`, com as 11 opções da FR-039 (`live: "notify.<chave>"`, `desc` do `Strings`). As outras categorias não mudam — **feito — a 004 já tinha o mecanismo:** `"setting"` + `SettingsState` ("salvar sempre"). Adotado, com a emenda em `contracts/services.md`, research R13/R14, data-model, plan e no schema; `settings dump` traz `live` e `values.notifications` com os valores vivos
- [x] T014 `shell/services/NotifyStore.qml` (singleton): a interface inteira de contracts/services.md lendo **só a fixture** (`entries`, `stack`, `critical`, `unread`, `overflow`, `logOpen`, `held`, `dumpState()`); as funções de ação mudam o estado em memória. O servidor entra na T025 — **feito**: com a `notifications-default.json`, `dump` = 6 entradas, 3 na tela, 1 crítica
- [x] T015 [P] `shell/services/Osd.qml` (singleton): `current` da fixture, `show(kind, value, muted)` (valida `volume|mic|brightness`), `hide`, `suppress`, `brightnessAvailable: false`. As fontes reais entram na T043 — **feito**: `osd` da fixture (volume 66); `notify osd volume 50 false` → `ok` e o `dump`; `osd nada …` → erro (o resto do `Osd` é da US5, não validado)
- [x] T016 [P] `shell/services/Compositor.qml`: `focusedFullscreen` (do `hyprctl activewindow -j`, eventos `fullscreen`/`activewindow`/`workspace`; fixture `notifications.fullscreen`) e `focusedMonitor` atualizado também no evento `focusedmon` (research R10, R11) — **feito**: kitty em tela cheia → `fullscreen: true`, `held: true`; de volta → `false`. **Corrigido:** o `fullscreen` do `hyprctl` é um modo e uma janela só maximizada (1) segurava as transmissões; agora só o bit de tela cheia (2) conta
- [x] T017 [P] `shell/ds/primitives/Band.qml`: o material (tinta, retícula em ladrilho estático, contorno interno, arcos com `Shape` opcional, bloco de 14, sombra), contracts/components.md. Na galeria, um retângulo de faixa sobre o papel e sobre a cena `dark` — **feito**: a retícula virou ladrilho (SVG) e os arcos um `Shape`, como no contrato (o WIP pintava ponto a ponto num `Canvas`, ~1,4 s travado por janela nova); na galeria, sobre o papel e sobre o escuro
- [x] T018 `shell/shell.qml` + `shell/services/qmldir`. Registrar `NotifyStore`, `NotifyPrefs`, `NotifyText` e `Osd`. O `IpcHandler` `notify` vem com todas as funções de contracts/ipc.md: as que dependem do servidor ou do log aberto respondem `"error: not yet"` até a história delas; `dump` sai no formato do contrato, com `page: null` — **feito**: o `IpcHandler` `notify` já traz as funções de todas as histórias (as das US2+ ainda não validadas)
- [x] T019 [P] `hud dump` com `log: { visible, text, box }` (vazio até a T040); `settings dump` com `live` e `values.notifications` (contracts/ipc.md, "Acréscimos") — **feito**: `hud dump` com `log` (e `LOG 99` depois da enxurrada); `settings dump` com `live` e `values.notifications`
- [x] T020 Verificar na VM (`lab/perf begin "008: contrato"`, `teste-a`):
  - carrega com 0 erros e 0 avisos;
  - `notify dump` com a fixture default traz 6 entradas, 3 na tela e 1 crítica, e o `body` da `notifications-long.json` sai sanitizado;
  - `notify pref position top` → `ok`, e o `dump` mostra `position: "top"`, `origin.position: "state"` (em memória com fixture);
  - `notify pref position nada` → erro;
  - `settings dump` mostra a categoria `notifications` com os valores vivos;
  - `qmllint` limpo.

  **Congela o contrato** — **feito** (`lab/perf` 2026-10-28T160556 (`teste-b`)): 0 erros e 0 avisos; `dump` da fixture default 6/3/1; o corpo da `notifications-long.json` sanitizado; `pref position top` → `ok`, `position: "top"`, origem `state`; `pref position nada` → erro; `settings dump` com a categoria; `qmllint` limpo. **Contrato congelado** (com a emenda da T013)

**Checkpoint**: contrato congelado; as quatro frentes podem começar.

---

## Phase 3: User Story 1 - Uma notificação vira transmissão (Priority: P1) 🎯 MVP

**Goal**: um `notify-send` vira transmissão no canto do monitor em foco, digitando, e vai pro log.

**Independent Test**: `lab/check-008 --only server,first,group,flood` (SC-001, SC-005, SC-006).

- [x] T021 [P] [US1] `shell/ds/base/TypedText.qml`. Uma `NumberAnimation` de `shown` de `from` até o fim, em `min(n / Tokens.notify.cps, typeMaxMs)`; o texto visível é `NotifyText.cut`; cursor de bloco só durante a digitação; `instant` → inteiro, sem cursor (FR-031); corte em `maxLines` com reticências; `complete()`, `done()`. Na galeria: quadro parado na metade — **Frente A** — **feito**; o cursor sai do fim da última linha (`lineLaidOut`): o `Text` não tem `positionToRectangle`, como o research R8 supunha
- [x] T022 [P] [US1] `shell/ds/composites/Transmission.qml` (contracts/components.md). Monta:
  - `Band` + quem fala (quadradinho, nome com reticências, `×N`, hora; × no lugar da hora com o mouse);
  - título numa linha, `TypedText`;
  - imagem de 72 (`PreserveAspectCrop`, moldura de 2 px, `file://` só depois do filtro da R6; senão ignorada com `console.info`);
  - progresso (`Meter` invertido + número);
  - linha de tempo (`remainingFrac`, parada com `instant`);
  - `More in log` quando corta.

  Layouts `corner` e `preview`. Sinais `clicked(button)`, `closeClicked`, `hoverChanged`, `typedOut` — **Frente A** — **feito**; `stillAt` repassado ao `TypedText` (galeria)
- [x] T023 [P] [US1] `shell/ds/composites/TransmissionStack.qml`:
  - as três posições da FR-004, todas aqui (a opção vem na US7): **Corner** 540 à direita, a mais nova em cima; **Top band** com faixas da largura toda, coluna de 360 dos lados e 2 px entre elas; **Subtitle** com 1100 centrada, acima de `bottomInset`, a mais nova embaixo;
  - `topInset`, a linha `+N in log` (`overflowClicked`);
  - entrada com varredura de `sweep` a partir da borda, saída com fade de 150, as outras deslizando; troca de posição sem animação (FR-041); `instant` sem nada animado — **Frente A** — **feito**; a linha fica recortada até o primeiro quadro da janela (`FrameAnimation`) e só então varre e avisa o store (`appeared`), pra a digitação começar quando aparece de verdade
- [x] T024 [P] [US1] Galeria (`shell/gallery/Gallery.qml`, página nova da 008, parte 1): a transmissão normal, com imagem, com progresso, com `×5` e digitando; a pilha nas três posições em miniatura — **Frente A** — **feito**: a `GalleryNotify` ligada como página 4 (Tab ×3); screenshot na sessão. Em 2560×1600 @1 a coluna 3 passa da borda (a galeria inteira escala pela altura); em 16:9 cabe
- [x] T025 [P] [US1] `NotifyStore` real (research R1, R2, R4, R15, R17, R18), em `shell/services/NotifyStore.qml`:
  - **servidor:** `NotificationServer` com as flags do spike (`tracked = true`), `server`/`serverOwner` pelo `busctl` (argv), `entries` montadas como no data-model (`app` → `desktopEntry` → `Unknown`; `transient` fora do log);
  - **substituição** no lugar, com `typedFrom` = `firstDiff`;
  - **agrupamento:** por `appKey` enquanto a anterior está na tela, `count + 1`, tempo recomeça;
  - **pilha:** limite (`NotifyPrefs.onScreen`) com a mais velha saindo e `overflow` quando não tinha terminado;
  - **lote** de 16 ms pra enxurrada; corte em `logSize` ("O log guarda as 100 mais novas e descarta as mais velhas");
  - **tempo** por `NotifyText.duration`, começando em `typedAt` e pausando com `pause(id, on)`; `arrivedAt`/`shownAt`/`typedAt`;
  - **monitor** na chegada (`NotifyPrefs.monitor` ou `Compositor.focusedMonitor`; nome que sumiu → em foco);
  - **recarga:** `PersistentProperties` (`reloadableId: "notify-session"`), religando os objetos com `lastGeneration`;
  - **injetor:** `sample(name)` pelo `Process` com argv (`notify-send`/`gdbus`, textos do `Strings`).

  Provado por `notify-send` + `dump`, sem desenho — **Frente B** — **feito**: agrupamento (`×5`, as anteriores não lidas se não terminaram de digitar), pilha cheia (`+1 in log`, a que saiu digitando fica não lida), substituição, lote, `logSize`, pausa com o mouse, recarga (log mantido, a viva religada e a ação chegando no `notify-send -w`), injetor em ordem (laço de `sh` com argv). **Corrigido:** o prazo da digitação era agendado antes de a transmissão entrar na pilha; `appeared`/`typed` aplicados depois da atualização da vista (laço de binding). Evidência `out/008-t026-163250`
- [x] T026 [US1] `shell/notify/NotifyLayer.qml` + `shell/shell.qml`. Antes, mesclar a `004-wallpaper-system` de novo (pega a "Bar contrast"), em commit próprio:
  - **janelas:** um `Variants` sobre as telas, com um `LazyLoader` ativo só com conteúdo naquele monitor;
  - **`PanelWindow`:** `Overlay`, `exclusionMode: Ignore`, namespace `yorha-notify`, `mask` = união das caixas, teclado `None`;
  - **dentro:** `TransmissionStack` com `topInset` abaixo da barra (`Settings.barHeight` × escala);
  - **cliques** (FR-009): esquerdo dispara a ação padrão ou `hide`; direito `hide`; × `hide`;
  - **mouse por cima:** `pause` + `complete()`;
  - **saída:** monitor que some → as dele vão pro log como não lidas;
  - **dump:** `dumpBoxes()` alimenta `screen[].box` — **feito**: clique esquerdo sem ação padrão esconde (fica no log, lida); com ação padrão o `notify-send -w` imprime `default`; direito só esconde; o × esconde; o mouse por cima pausa (`remaining` parado) e completa; fora da caixa nada (a `mask`). A `004-wallpaper-system` já estava mesclada (nada novo). Evidência `out/008-t026-163250`. O monitor que some fica pro bloco `monitors` (T054)
- [x] T027 [US1] `lab/check-008` blocos `first`, `group`, `flood` e a primeira parte do `edge` (sem app, só título, marcação, imagem quebrada, passageira, substituição, progresso 0→100), com `lab/burst` e a medição da research R19. Rodar em `lab/perf`; **é o "pronto quando" da fase** — **feito** (`lab/perf` 2026-10-28T160556 (`teste-b`)): `lab/check-008 --only server,first,group,flood,edge` **18 PASS, 0 FAIL** em 1080 (`out/check-008-1080-20261028-165654`) e em hidpi (`out/check-008-hidpi-20261028-165758`): na tela 68 ms depois do `notify-send`, digitada 289 ms depois (SC-001), ×5 (SC-006), 100 no log com 99 não lidas e `LOG 99`, CPU do `qs` 3% 5 s depois (repouso 1%) (SC-005). O "log abre em ≤ 0,3 s" do SC-005 sai como `INFO` (262/248 ms; 136–325 ms em outras rodadas): o log é da US4 e a `GroupedList` cria um delegado por entrada; o critério passa pra T040

**Checkpoint**: MVP — notificações usáveis no tema.

---

## Phase 4: User Story 2 - Urgência: baixa, normal e crítica (Priority: P1)

**Goal**: o bloco e o tempo de cada urgência; a faixa crítica larga que não some.

**Independent Test**: `lab/check-008 --only urgency` (SC-003).

- [x] T028 [P] [US2] `shell/ds/base/Tag.qml` (`CRITICAL` sobre `alert`, `NEW` com contorno) e as urgências na `Transmission` (bloco `medium-gray` / `light-yellow` / `alert`; `Tag CRITICAL` ao lado de quem fala). Os únicos usos do `alert` são os da FR-010 — **Frente A** — **feito** (`lab/perf` 2026-10-29T102807, `teste-b` recriada, 4 núcleos): `lab/check-008 --only urgency` lê o pixel do bloco no screenshot: baixa `#676458`, normal `#D7D1B3`, crítica `#8F3A30`, em 1080 e hidpi (`out/check-008-1080-20261029-103510/urgency-cores.png`)
- [x] T029 [P] [US2] `shell/ds/composites/CriticalBand.qml`: a largura do monitor, a coluna de 1080 centrada, arcos, até 3 linhas de corpo, ações embaixo, `1/N` com ◂ ▸ (`pageStepped`) e ×, altura mínima 230. Na galeria, com `1/2` — **Frente A** — **feito** (`lab/perf` 2026-10-29T102807, `teste-b` recriada, 4 núcleos). **Corrigido:** o ◂ 1/2 ▸ e o × saíam no canto esquerdo (ancorados num `reveal` cuja largura a varredura deixava errada; agora a varredura é um `progress` que só recorta) e os triângulos (um `Canvas`) não pintavam; viraram um `Shape`. O `dump` ganhou `critical.controls` (◂, ▸, ×) pros cliques: ▸ → 2/2, ◂ → 1/2, × tira a crítica em foco e as duas ficam no log, vivas (`urgency-paginas.png`)
- [x] T030 [P] [US2] `NotifyStore`: as críticas vão pra `critical` (fora do limite da pilha, a mais nova primeiro, `page`), nunca expiram; os tempos `low`/`normal` da FR-007; as críticas passam por cima de `held` (US6) — **Frente B** — **feito** (`lab/perf` 2026-10-29T102807, `teste-b` recriada, 4 núcleos): baixa 3961/3994 ms e normal 5974/5984 ms depois de digitadas (1080/hidpi), a crítica na faixa em 65 s; com o não perturbe ligado a normal vai pro log e a crítica aparece (`urgency-dnd.png`). Fim da US2: `lab/check-008 --only urgency` **13/0** em 1080 (`out/check-008-1080-20261029-103510`) e hidpi (`out/check-008-hidpi-20261029-103819`); regressão `check-u1` 15/0, `check-003` 25/0; `check-004` 57/1, com a falha (`Failed to load configuration`) causada por uma edição da US4 sincronizada no meio da rodada, refeita no fim da US3
- [x] T031 [US2] `NotifyLayer`: a `CriticalBand` logo abaixo da barra, e a pilha com `topInset` abaixo dela enquanto ela está na tela; `critical.box` no `dump`. `lab/check-008` bloco `urgency` (o `dump` a cada segundo por 65 s; screenshot da faixa) — **feito** (`lab/perf` 2026-10-28T170342, `teste-b`, 4 núcleos): `lab/check-008 --only urgency` 6/0 (`out/check-008-1080-20261028-170435`): baixa saiu 3984 ms e normal 5960 ms depois de digitadas, a crítica ainda na faixa em 65 s, a pilha abaixo da faixa. T028–T030 ainda sem marcar: falta conferir as cores do bloco por urgência, a paginação ◂ ▸ por clique e a crítica com `held` (US6)

---

## Phase 5: User Story 3 - Ações e resposta (Priority: P2)

**Goal**: botões de ação e o campo de resposta, sem roubar o teclado fora disso.

**Independent Test**: `lab/check-008 --only actions,reply` (SC-004).

- [x] T032 [P] [US3] `shell/ds/base/ActionButton.qml` (contorno de 2 px, varredura clara no hover, `enabled: false` a 35%) e, na `Transmission`, as ações (até 3, na ordem do app) e o campo de resposta de uma linha (só com `replying`; Enter → `replySent`, Esc → `replyCancelled`). Na galeria, com a resposta aberta — **Frente A** — **feito** (`lab/perf` 2026-10-29T105454, `teste-b`): os botões Open e Snooze embaixo do texto, na ordem do app (`out/check-008-1080-20261029-105645/actions.png`); o campo de resposta abre dentro da transmissão (`reply-aberto.png`); na galeria, a transmissão com a resposta aberta (página 4)
- [x] T033 [P] [US3] `NotifyStore`:
  - `invoke(id, action)`: `NotificationAction.invoke()`; fecha se não `resident` (FR-013); `answered`;
  - `reply(id, text)`: `sendInlineReply`;
  - `dismiss`, `hide`, `hideAll`, `clear`;
  - `alive: false` quando o app fecha (`closed` com `CloseRequested`);
  - sair da tela nunca chama `dismiss`/`expire` (FR-008).

  **Frente B** — **feito** (`lab/perf` 2026-10-29T105454, `teste-b`): a ação chega no `notify-send --wait` (`later`, `default`), a entrada fica `answered` e `alive: false`; o clique direito só esconde (a entrada continua viva); o `CloseNotification` do app tira da tela e deixa a entrada com `alive: false`; o Clear all avisa o app (`closed 2` no `lab/notify-client`)
- [x] T034 [US3] `NotifyLayer`:
  - teclado `WlrKeyboardFocus.OnDemand` só enquanto uma transmissão está com `replying`, e uma por vez;
  - volta a `None` ao mandar ou cancelar (FR-014, FR-015);
  - o tempo pausa com o campo aberto.

  `lab/check-008` blocos `actions` e `reply` (cliques pela `box`, `hyprctl activewindow` antes e depois) — **feito** (`lab/perf` 2026-10-29T105454, `teste-b`): o teclado é `Exclusive` só com o campo aberto (decisão do spike T004, item 5); o tempo para com o campo aberto e volta a correr depois do Esc; a janela em foco é a mesma antes e depois e um comando digitado chega no kitty (FR-014, FR-015). `lab/check-008 --only actions,reply` **12/0** em 1080 (`out/check-008-1080-20261029-105645`) e hidpi (`out/check-008-hidpi-20261029-105806`). O `dump` ganhou `screen[].controls` (as caixas dos botões e do campo) pros cliques

---

## Phase 6: User Story 4 - O text log (Priority: P2)

**Goal**: o log num popup, com a tela pronta pra aba do menu de pausa.

**Independent Test**: `lab/check-008 --only log-keys,gallery` (SC-009, SC-016).

- [x] T035 [P] [US4] `shell/ds/base/ListItem.qml` + `shell/ds/composites/GroupedList.qml`: `lead` (peso 600, até 150, reticências), `tag` (`Tag` com contorno antes do `trailing`), `markColor`. Vazios = como antes; conferir que o seletor da 004 dá o mesmo screenshot (`lab/diffshot` contra a `004-wallpaper-system`) — **Frente D** — **feito** (`lab/perf` 2026-10-29T111419, `teste-b`): o seletor da `004-wallpaper-system` e o da 008, com a `wallpaper-default.json` e as mesmas teclas (ALT + W; ↓ →), dão **0 px** de diferença, aberto e nas opções (`out/008-t035-picker-111815`). **Novo (decisão do dono, 2026-10-29):** `GroupedList.lazy`: só as linhas à vista (e uma margem, em blocos de 8) são criadas, cada uma no lugar calculado pelo tipo (item, título); sem `lazy` a lista da 004 não muda
- [x] T036 [P] [US4] `shell/ds/composites/PickerLayout.qml`:
  - `fluid` (colunas e topo a partir de `width`/`height`, nas proporções do quadro de 1612 × 908);
  - opções `type: "action"` (valor = `text` + ▸; Enter/clique → `invoked`; ←/→ nada).

  Com `fluid: false`, o seletor da 004 dá o mesmo screenshot. **Antes, conferir se a 007 já fez o mesmo** (plan.md, "Dependências") — **Frente D** — **feito** (`lab/perf` 2026-10-29T111419, `teste-b`): a `007-menu-de-pausa` fez o mesmo acréscimo em paralelo (opções `toggle` e `action`, sinal `triggered`); a 008 adotou os nomes dela (`triggered`, toggle 0/1, rodapé `Enter <text>`), com a emenda em `contracts/components.md`. O texto do `PickerLayout` ainda difere entre as duas: o merge fica pro dono (ver decisões pendentes). Mais `lazyList` (a lista preguiçosa). Seletor da 004: 0 px (T035)
- [x] T037 [US4] `shell/notify/LogPreview.qml` + `shell/notify/LogPage.qml` (contracts/components.md; data-model "Estado do log aberto"):
  - **lista:** NOW (última hora) / EARLIER, filtrada por `Show`;
  - **meio:** a `Transmission` `"preview"` digitando de novo a cada troca; até ela chegar da Frente A, um `Card` com o texto;
  - **ações:** apagadas com a frase de fechada, ou "From an earlier session.";
  - **opções:** `Do not disturb` (o mesmo `NotifyPrefs.dnd`), `Show`, `Clear all`; as informações `UNREAD`, `KEPT n / limite`, `SERVER`;
  - **teclas:** Enter ação padrão, Delete dispensa e foca a próxima, → opções, Esc volta/fecha; rodapé só com as teclas que valem;
  - **saída:** `title`/`subtitle`/`footerLeft`/`keys`/`dumpState()`/`restart()`.

  **Frente D** — **feito** (`lab/perf` 2026-10-29T111419, `teste-b`): a `LogPage` com a lista preguiçosa; NOW/EARLIER, Show, Do not disturb, Clear all; a entrada cujo app fechou diz "The app closed this notification." (`log-fechada.png`); Enter dispara a ação padrão (a entrada fica `answered: default`), Delete dispensa e o foco vai pra próxima; o rodapé só com as teclas que valem (`out/check-008-1080-20261029-112026/log-aberto.png`)
- [x] T038 [US4] `shell/notify/LogPopup.qml` + `shell/shell.qml`: abre e fecha como os outros popups (monitor em foco relido, duas fases), um popup por vez (abrir o log fecha configurações e seletor, e vice-versa); `notify open|close|toggle|isOpen`; `dump.page` — **Frente D** — **feito** (`lab/perf` 2026-10-29T111419, `teste-b`): ALT + N, `notify open`/`toggle`; um popup por vez: abrir o log fecha configurações e seletor, e eles fecham o log
- [x] T039 [P] [US4] `shell/hud/LogCounter.qml` + `shell/hud/Hud.qml`: `LOG n` antes do relógio, escondido com 0 e sem DND, `DND n` com DND; o tom da barra (004 US6, `Tokens.hudColor`); clique → `notify open`; `hud dump` com `log` e `texts` `role: "log"` — **Frente D** — **feito** (`lab/perf` 2026-10-29T111419, `teste-b`): `LOG 2` na barra depois de duas não lidas, o clique nele abre o log e zera; `hud dump texts` com `role: "log"` (`LOG`, `1`); os dois tons na galeria (T053)
- [x] T040 [US4] Ligar o log ao store: `logOpen` (as novas entram na lista marcadas `NEW`, FR-027), `markAllRead()` ao abrir (FR-024), `+N in log` → abre o log. `lab/check-008` bloco `log-keys` com teclas reais (SC-009), e o "log abre em ≤ 0,3 s logo depois" da enxurrada (SC-005; no bloco `flood` ele é só `INFO`, ver T027: a `GroupedList` cria um delegado por entrada e passa perto do limite). Anotar em `contracts/components.md` o que a 007 usa (já escrito; conferir) — **feito** (`lab/perf` 2026-10-29T111419, `teste-b`): o log abre em **58 ms** (1080) e **99 ms** (hidpi) depois da enxurrada de 100, antes 136–325 ms (SC-005 vira critério no bloco `flood`); abrir marca tudo como lido (`unread: 0`, o contador some); com o log aberto a nova entra na lista marcada NEW e não na tela (FR-027); `+3 in log` → clique abre o log e a linha some. `lab/check-008 --only flood,log-keys`: **21/0** em hidpi (`out/check-008-hidpi-20261029-111707`), e o `log-keys` completo 21/0 em 1080 (`out/check-008-1080-20261029-112026`). A seção da 007 em `contracts/components.md` continua certa

---

## Phase 7: User Story 5 - OSD de volume, microfone e brilho (Priority: P2)

**Goal**: um OSD só, na faixa, que reage a qualquer mudança.

**Independent Test**: `lab/check-008 --only osd,osd-quiet` (SC-008).

- [x] T041 [P] [US5] `shell/ds/composites/OsdView.qml`: `Band` 600×72, quadradinho, rótulo (168), `Meter` invertido de 300 (35% no mudo; cheio acima de 100), número tabular à direita; `MIC ON/OFF` sem medidor. Na galeria: volume, mudo, microfone, brilho — **Frente C** — **feito** (`lab/perf` 2026-10-29T113600, `teste-b`): a faixa de 600 × 72 com o medidor na trilha translúcida (emenda do contrato, decisão do dono), MUTE com o medidor a 35% (`out/check-008-1080-20261029-113819/osd-mudo.png`), 120 com o medidor cheio (`osd-120.png`); na galeria, os quatro tipos
- [x] T042 [P] [US5] `Osd` real (research R12), em `shell/services/Osd.qml`:
  - **volume e mudo:** `Pipewire.defaultAudioSink.audio`, valor real `round(volume × 100)`;
  - **microfone:** `defaultAudioSource.audio.muted`;
  - **sem OSD** no primeiro valor nem na troca de nó;
  - **brilho:** `udevadm monitor --kernel --subsystem-match=backlight` (argv, `SplitParser`) + releitura de `brightness`/`max_brightness`; `brightnessAvailable`;
  - **tempo:** 1200 ms depois da última mudança, atualiza no lugar;
  - **`suppress(kind, on)`.**

  **Frente C** — **feito** (`lab/perf` 2026-10-29T113600, `teste-b`): 64 → 66 na primeira tecla real e um OSD só depois de três mudanças, com o valor do `wpctl` (70); some 1232 ms (1080) e 1222 ms (hidpi) depois da última (SC-008); MIC OFF / MIC ON pelo mudo do source. **Corrigido no lab:** o source nulo era `Audio/Source/Virtual`, e o Quickshell não dá `audio` a esse tipo de nó (um microfone de verdade é `Audio/Source`): o `lab/provision-step notify` cria o source como `Audio/Source`
- [x] T043  [P] [US5] `shell/notify/OsdWindow.qml` + `shell/shell.qml`: `PanelWindow` `Overlay` do tamanho do OSD, `mask` vazia, teclado `None`, namespace `yorha-osd`, só enquanto há OSD. Embaixo a `osdBottom` do monitor em foco (a posição `Top` vem na US7); aparece com DND; `osd.box` no `dump` — **Frente C** — **feito** (`lab/perf` 2026-10-29T113600, `teste-b`): embaixo, centrado, a 110 da borda (`osd.box` `{x: 659, y: 895, w: 600, h: 72}` em 1080); aparece com o não perturbe e não entra no log; uma camada `yorha-osd` só
- [x] T044 [P] [US5] `shell/settings/SettingsPage.qml`: `Osd.suppress("volume", …)` com o foco em `sound.volume`/`sound.mute`, `"brightness"` em `display.brightness` (FR-029) — **Frente C** — **feito** (`lab/perf` 2026-10-29T113600, `teste-b`): com o foco em Sound › Volume e em Mute (teclas reais), o `wpctl` de fora não mostra OSD; com o popup fechado, volta a mostrar (bloco `osd-quiet`). O brilho fica pra homologação (a VM não tem luz de fundo)
- [x] T045 [US5] `lab/check-008` blocos `osd` (`lab/key volumeup` ×3, `wpctl get-volume`, `lab/burst`, mudo, `notify osd brightness 40`, volume 120%) e `osd-quiet` — **feito** (`lab/perf` 2026-10-29T113600, `teste-b`): `lab/check-008 --only osd,osd-quiet` **11/0** em 1080 (`out/check-008-1080-20261029-113819`) e hidpi (`out/check-008-hidpi-20261029-114054`)

---

## Phase 8: User Story 6 - Não perturbe (Priority: P3)

**Goal**: com DND ou tela cheia, só as críticas aparecem; o resto vai pro log.

**Independent Test**: `lab/check-008 --only dnd,fullscreen` (SC-007).

- [ ] T046 [P] [US6] `NotifyStore`:
  - `held` = `NotifyPrefs.dnd` ou (`Compositor.focusedFullscreen` e `fullscreen == "hold"`);
  - com `held` ou `logOpen`, `low`/`normal` vão direto pro log não lidas, e as críticas aparecem;
  - ao sair da tela cheia, nada aparece de uma vez.

  `notify dnd on|off|toggle`. A persistência do DND fica com o `NotifyPrefs` (T048) — **Frente B**
- [ ] T047 [US6] `lab/check-008` blocos `dnd` (tecla real `ALT + CTRL + N`, 5 + 1, `DND 5` no `hud dump`, reinício do `qs`) e `fullscreen` (kitty em tela cheia)

---

## Phase 9: User Story 7 - As opções de notificações (Priority: P2)

**Goal**: a categoria Notifications vale de verdade, troca ao vivo e fica guardada.

**Independent Test**: `lab/check-008 --only prefs,saved` (SC-014, SC-015).

- [ ] T048 [P] [US7] `NotifyPrefs` com o estado (research R14; **emenda da T013:** as escolhas já ficam no `SettingsState` da 004, chaves `notifications.<chave>`; aqui sobra conferir origem, reset, valor inválido e o "nunca no `~/.config`"):
  - **ordem de quem vale:** `$XDG_STATE_HOME/yorha-os/notifications.json` (`{ "version": 1, "dnd", "prefs" }`, só as chaves mudadas) acima de `shell.json` e dos padrões;
  - **`origin`;**
  - **`reset()`** apaga as escolhas;
  - **estado inválido** → padrão e regravar;
  - **com fixtures**, nada escrito (FR-043);
  - **nunca escreve no `~/.config`.**

  **Frente B**
- [ ] T049 [P] [US7] Log salvo no `NotifyStore` (FR-019, research R14), formato `contracts/notifications.schema.json#/$defs/savedLog`:
  - **quando grava:** só com `log == "saved"` e sem fixtures;
  - **permissão:** `install -m 600 /dev/null` antes da primeira escrita, e `chmod 600` depois de cada escrita se o spike mostrou que precisa;
  - **escritas** juntas em 500 ms;
  - **nunca grava** ações, respostas, `transient` nem imagem que não seja `file://`;
  - **ao entrar na sessão:** as entradas voltam com `earlier: true`;
  - **Session only** → `rm -f --` na hora;
  - **arquivo ilegível** → `.bak-<data>` + log vazio + `console.info`;
  - **`logSize` menor** corta na hora.

  **Frente B**
- [ ] T050 [US7] Ligar as opções ao vivo:
  - **`Position`** → `TransmissionStack.position`, mudando também o que está na tela, sem animação, mantendo o tempo (FR-041);
  - **`OSD position`** → `OsdWindow`: `Top` logo abaixo da barra ou da faixa crítica;
  - **`Monitor`, `On screen`** (o que passar sai pro log), **`Duration`, `Typing`** (`Off` = `instant` no `TypedText`);
  - **`System voice`** → `speaker` das entradas `system`, até as antigas;
  - **`In fullscreen`**.

  Conferir as bordas da spec: `Top band` com a crítica, `Subtitle` com o OSD, OSD no topo com a crítica
- [ ] T051 [US7] `lab/check-008` blocos `prefs` (configurações › Notifications com teclas reais: `Position` nas três, `OSD position` Top, `System voice` System + `notify sample system`) e `saved` (5 entradas; reiniciar o `qs` e a sessão da VM; `stat -c %a`; voltar pra Session only; `ls -la ~/.config` igual)

---

## Phase 10: Polish & Cross-Cutting Concerns

- [ ] T052 [P] `docs/design-system.md` §9 (bloco marcado):
  - a faixa e a faixa crítica, a transmissão, o texto digitado, o botão de ação, o OSD, o contador;
  - as três posições e as duas do OSD;
  - a `LogPage` e como a 007 a usa;
  - os tokens, as opções e os comandos.
- [ ] T053 [P] Galeria completa (`shell/gallery/Gallery.qml`): tudo da contracts/components.md "Galeria", incluindo a `LogPage` em dois tamanhos (corpo do popup e corpo do menu de pausa, SC-016) e o contador nos dois tons
- [ ] T054 `lab/check-008` inteiro em 1080 e em hidpi (2560x1600 @1,25), dentro de `lab/perf`, incluindo `shots` (cada cena duas vezes, `lab/diffshot` = 0, SC-002), `monitors` (segundo monitor headless, SC-010), `reduced` (SC-011), o resto do `edge` (outro servidor com `lab/notify-client hold-name`) e `lint` (`qmllint` + log de QML; só a linha esperada do bloco `edge`, SC-012)
- [ ] T055 Imagem de revisão pro dono (`~/.local/share/nier-lab/out/008-revisao.png`): os screenshots de `shots`, `prefs` e `gallery` ao lado do mockup (SC-013)
- [ ] T056 `specs/008-pod-text-log/relatorio.md`: o que foi feito, as evidências (`lab/perf` de cada bloco), os desvios, o custo da enxurrada, as pendências pro dono (atalhos, homologação do brilho na U7)
- [ ] T057 `/speckit-analyze` e as correções que ele apontar

---

## Frentes paralelas (princípio VI)

Depois do T020 (contrato congelado), até **4 agentes ao mesmo tempo**, cada um com worktree própria
saindo da `008-pod-text-log` e VM própria (2 núcleos, 4 GB):

| Frente | VM | Tarefas | Arquivos (sem sobreposição) |
|---|---|---|---|
| **A, design system** | `teste-a` | T021, T022, T023, T024, T028, T029, T032 | `ds/base/TypedText`, `Tag`, `ActionButton`; `ds/composites/Transmission`, `TransmissionStack`, `CriticalBand`; a página da 008 na galeria |
| **B, servidor e opções** | `teste-b` | T025, T030, T033, T046, T048, T049 | `services/NotifyStore`, `services/NotifyPrefs` |
| **C, OSD** | `teste-c` | T041, T042, T043, T044 | `ds/composites/OsdView`, `services/Osd`, `notify/OsdWindow`, o bloco do OSD no `shell.qml`, `settings/SettingsPage` |
| **D, tela do log** | `teste-d` | T035, T036, T037, T038, T039 | `ds/base/ListItem`, `ds/composites/GroupedList`, `PickerLayout`; `notify/LogPage`, `LogPreview`, `LogPopup`; `hud/LogCounter`, `hud/Hud`; o bloco do log no `shell.qml` |

- **`shell.qml`:** C e D mexem em blocos marcados diferentes (`// --- spec 008: osd ---`,
  `// --- spec 008: log ---`); o merge é linha a linha.
- **Galeria:** a A é dona da página da 008; C e D entregam os exemplos deles como componentes de galeria
  (`gallery/notify/*.qml`), que a A inclui no T053.
- **Integração** (T026, T027, T031, T034, T040, T045, T047, T050, T051) é sequencial, numa VM, depois de
  mesclar as frentes que cada uma usa.

## Dependencies & Execution Order

- **Setup (T001–T005):**
  - T001–T003 em paralelo;
  - T004 depende de T001–T003;
  - T005 depende de T004.

  **T004 é portão:** se o servidor não funcionar na VM, para tudo.
- **Foundational (T006–T020):**
  - T006, T007, T008, T010, T011, T015, T016, T017, T019 em paralelo;
  - T009 depende de T008 (a imagem);
  - T012 depende de T010; T013 depende de T012; T014 depende de T009 e T011;
  - T018 depende de T012–T016;
  - T020 depende de tudo e congela.
- **Frentes A–D:** começam juntas depois do T020.
- **Integração por história** (cada uma espera as tarefas das frentes que usa):
  - US1 (T026, T027): espera A (T021–T023) e B (T025);
  - US2 (T031): espera T028–T030;
  - US3 (T034): espera T032 e T033;
  - US4 (T040): espera D (T035–T039) e, pra a prévia final, T022;
  - US5 (T045): espera C (T041–T044);
  - US6 (T047): espera T046;
  - US7 (T050, T051): espera T048, T049, T023 e T043.
- **Polish (T052–T057):** depois de todas as histórias. T054 antes de T055–T057.

**Ordem das histórias** (pela prioridade e pelas dependências): US1 → US2 → (US3, US4, US5 em
qualquer ordem) → US6 → US7.

## Parallel Example: depois do T020

```text
Agente A (teste-a): T021 TypedText → T022 Transmission → T023 TransmissionStack → T024 galeria → T028 Tag/urgências → T029 CriticalBand → T032 ActionButton/resposta
Agente B (teste-b): T025 NotifyStore real → T030 críticas → T033 ações → T046 DND/tela cheia → T048 estado das opções → T049 log salvo
Agente C (teste-c): T041 OsdView → T042 Osd real → T043 OsdWindow → T044 supressão
Agente D (teste-d): T035 ListItem/GroupedList → T036 PickerLayout → T037 LogPage → T038 LogPopup → T039 LogCounter
```

## Implementation Strategy

1. **MVP = US1** (T001–T027): `notify-send` vira transmissão, que é o "pronto quando" do `PLAN.md`.
   Parar e mostrar ao dono, se ele quiser ver antes do resto.
2. **Mínimo pra trocar o Serpantinum** (PLAN §7): MVP + US2 + US5 (urgência e OSD).
3. **Incremento:** US3, US4, US6 e US7, cada uma validada no `lab/check-008 --only …` antes da próxima.
4. **Acabamento:** o roteiro inteiro em 1080 e hidpi, a imagem de revisão e o relatório (SC-013).
