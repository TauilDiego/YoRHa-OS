---
description: "Tarefas da 004: sistema de papel de parede"
---

# Tasks: Sistema de papel de parede

**Input**: `specs/004-wallpaper-system/` (plan.md, spec.md, research.md, data-model.md, contracts/,
quickstart.md)

**Tests**: a spec não pede testes automatizados. A prova de cada tarefa é a evidência da VM
(princípio IV): screenshot (com medição, quando o critério pede), `qs ipc call wallpaper dump`,
rajada de quadros e log de QML sem erro, sempre dentro de `lab/perf begin/end`.

**Caminhos**:
- `shell/…` = repositório público `nier-os`;
- `lab/…` = repositório privado `rien-OS-private`, irmão do público
  (`~/projects/rien-OS-private/lab/`).

**Dependência de outra spec**: o seletor (US2) usa os componentes da **003** (moldura de popup,
linha de opção, seletor de valor, rodapé de teclas, foco em duas colunas). As fases US3, US4 e US5
**não** dependem da 003 e podem andar antes, testadas pelo IPC.

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: história da spec (US1–US5)

---

## Phase 1: Setup (laboratório, shaders e imagens de teste)

**Purpose**: provar que shaders rodam na VM, compilar os `.qsb` onde a UI roda, ter imagens de
teste e as ferramentas de evidência (rajada, roteiro).

- [x] T001 **Spike:** compilar um shader trivial (inverte as cores de um retângulo) com `qsb` dentro da VM e rodá-lo num `ShaderEffect` via virgl, numa sessão `lab/perf begin "004: spike de shader"`. Guardar em `lab/mockups/shader-spike/` (privado) e registrar o resultado na seção "Pra validar no primeiro dia" do `lab/README.md`. **Se falhar, parar e levar ao dono** (research R3) — **feito:** `qsb` 6.12 (já na `hypr-base`, em `/usr/lib/qt6/bin/qsb`) compila GLSL 440 dentro da VM, e um `ShaderEffect` com dois `ShaderEffectSource` vivos e um uniform roda via virgl (status Compiled, screenshot certo). `lab/mockups/shader-spike/`; `lab/perf` 2026-10-27T152402
- [x] T002 [P] Criar `shell/shaders/build.sh`: pra cada `*.frag` em `shell/shaders/`, roda `qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o <x>.frag.qsb <x>.frag` só se o `.frag` for mais novo que o `.qsb`. Bash com `set -euo pipefail`, argumentos em argv, sem `eval`; sai com 0 e um aviso se o `qsb` não existir. `shellcheck` limpo (container `koalaman/shellcheck:stable`) — **feito:** procura o `qsb` no PATH e em `/usr/lib/qt6/bin`; `shellcheck` limpo (`lab/perf` 2026-10-27T153158)
- [x] T003 [P] `lab/provision` (camadas `hypr-base`/`dev`): instalar `qt6-shadertools` na VM. Em seguida, `lab/sync`: depois do rsync, rodar `~/nier/ui/shaders/build.sh` dentro da VM quando algum `.frag` mudou — **feito:** o `lab/provision/hypr-base.sh` já instalava o `qt6-shadertools` desde o começo (as camadas congeladas não foram tocadas; a `teste-b` já tem o `qsb`). O `lab/sync` recompila na VM quando um `.frag` ou o `build.sh` muda, apagando antes o `.qsb` velho (o rsync mantém o mtime do host); conferido no T028
- [x] T004 [P] Criar `lab/make-test-wallpapers`: num container `archlinux` com `imagemagick` (label `nier-lab`), gera em `shell/fixtures/wallpapers/` os arquivos `ruins.jpg` (1920×1080, gradiente + silhuetas), `dunes.png` (1600×1200), `parede 'teste' #1 (larga).png` (2560×1080) e `quebrada.jpg` (bytes aleatórios), cada um com < 300 KB. Rodar uma vez e commitar as imagens no público — **feito:** `lab/perf` 2026-10-27T153158 (container): `ruins.jpg` 30 KB, `dunes.png` 21 KB, nome difícil 21 KB, `quebrada.jpg` 40 KB
- [x] T005 [P] `lab/guest/hyprland.lua`: `hl.bind("ALT + W", hl.dsp.exec_cmd("qs -p ~/nier/ui ipc call wallpaper picker toggle"))`, seguindo a convenção ALT da VM (research R11) — **feito pela sessão principal** (`4997d2f`, `lab-004`)
- [x] T006 [P] Criar `lab/burst N MS [x,y WxH] [nome]`: um laço de `grim` dentro da VM (por `lab/ssh`, com `$GUEST_ENV`), N quadros a cada MS ms, baixados pra `$LAB_HOME/out/burst-<nome>/` com uma montagem (`magick montage`, no host). Registrado no `lab/perf` — **feito pela sessão principal** (`4997d2f`, `lab-004`)
- [x] T007 Criar o esqueleto do `lab/check-004` (no padrão do `lab/check-u1`: `ok`/`ko`, pasta de evidência, `summary.txt`) e documentar T003–T007 na seção "Uso no dia a dia" do `lab/README.md` — **feito:** esqueleto com `ok`/`ko`, `summary.txt`, sync com a fixture, reinício limpo e workspace vazio; README com shaders, `make-test-wallpapers` e `check-004`

**Checkpoint**: shaders compilam e rodam na VM; imagens de teste e ferramentas prontas.

---

## Phase 2: Foundational (contrato)

**Purpose**: as interfaces de [contracts/](contracts/) que todas as histórias usam.
**⚠️ Depois do T016, os contratos ficam congelados.**

- [x] T008 `shell/config/defaults.json` + `shell/services/Settings.qml`: as chaves `reduceMotion` (false), `wallpaperFolder` (`~/Pictures/Wallpapers`, com o `~` expandido), `wallpaperTransition` (`camouflage`) e `camouflage` (`{ cell: 24, trail: 2600, glitch: 2 }`), com a validação do data-model.md (fora da faixa → padrão + aviso) — **feito** (`reduceMotion` veio da sessão principal, `0bf600e`); validação de `cell`/`trail`/`glitch` em `Settings.camouflageError`, reaproveitada pelo IPC
- [x] T009 [P] `shell/strings/Strings.qml`: grupo `wallpaper` com o título (`WALLPAPER`, `-Select`), os grupos (`SCENES`, `IMAGES`, `VIDEO`), as opções (`Monitor`, `All monitors`, `Transition`, `Camouflage`, `Wipe`, `Tiles`, `Crossfade`, `Paper filter`, `On`, `Off`), as informações (`Type`, `Layers`, `Motion`, `Now on`), as teclas (`Select`, `Apply`, `Options`, `Change`, `Back`, `Close`), os textos do vídeo, de imagem e de pasta vazia (`Put pictures in …`). Tudo em inglês (FR-023) — **feito**
- [x] T010 [P] `shell/fixtures/wallpaper-default.json`: os domínios da `hud-default.json` mais o domínio `wallpaper` do data-model.md (`folder: "fixtures/wallpapers"`, `all: "scene:menu"`, transição de fábrica). O `Fixtures` já serve o domínio novo (`has`/`get`); conferir — **feito**; `Fixtures.has/get` já servem o domínio novo
- [x] T011 [P] `shell/services/Compositor.qml`: `focusedMonitor` (nome da saída) lido do campo `focused` do `hyprctl monitors -j` que já é consultado pras escalas, atualizado nos mesmos eventos (research R9) — **feito pela sessão principal** (`0bf600e`)
- [x] T012 [P] `shell/wallpaper/scenes/menu.json`, `rules.json`, `dark.json` e `plain.json`, válidos contra `contracts/scene.schema.json` (tabela do data-model.md; textos do mockup em inglês). Conferir os quatro com um validador de JSON Schema num container — **feito:** as 4 válidas contra o schema (python-jsonschema, Draft 2020-12, container; `lab/perf` 2026-10-27T153933). **Desvio:** o centro das cenas de papel é `#C9C5AB` (o `Tokens.color.darkYellow` que a US1 já usa), não o `#C8C3AC` medido: a barra usa o mesmo papel, então o fundo fica sem emenda com ela (FR-004), e o `menu` dá o mesmo screenshot da US1 (T021). Fica a 1–2 níveis do medido (SC-001 aceita 4)
- [x] T013 `shell/services/WallpaperCatalog.qml` (singleton, registrado no `services/qmldir`): lê as cenas de `wallpaper/scenes/` na ordem de fábrica, acrescenta a entrada fixa do vídeo (`available: false`) e expõe a interface inteira de contracts/services.md (`items`, `byId`, `folder`, `folderMissing`, `count`). As imagens entram na US4 — **feito**
- [x] T014 `shell/services/WallpaperStore.qml` (singleton): escolha em memória (`all`, `monitors`, `resolve` com o fallback do data-model, `set`, `step`, `setTransition`, `setCamouflage`, `setPaperFilter`, `transition`, `instant`), lendo a fixture `wallpaper` quando ativa. A persistência entra na US5 — **feito**
- [x] T015 `shell/shell.qml`: o `IpcHandler` `wallpaper` com todas as funções de contracts/ipc.md (`list`, `set`, `next`, `prev`, `transition`, `camouflage`, `filter`, `dump`; `picker` responde `"ok"` sem efeito até a US2), mantendo `motion` e `isMoving` — **feito**
- [x] T016 Verificar na VM (`lab/perf begin "004: contrato"`): carrega com 0 erros e 0 avisos; `ipc call wallpaper list` traz as 4 cenas + o vídeo; `set scene:dark all` responde `ok` e o `dump` mostra `all: scene:dark`; `set scene:nada all` responde erro; `qmllint` limpo dentro da VM. **Congela o contrato** — **feito:** 0 erros e 0 avisos de QML; `list` = 4 cenas + 3 imagens + vídeo; `set scene:dark all` = `ok` e `dump` com `all: scene:dark`; `set scene:nada all` = erro; `qmllint` limpo (fora os falsos positivos conhecidos). `lab/perf` 2026-10-27T153730, evidência `out/004-T016-contrato`. **Desvio (R6):** o `Image` do Qt loga um `WARN` quando não consegue decodificar um arquivo, o que quebraria o SC-008; os arquivos da pasta passam por um `file --brief --mime-type -- <caminhos>` (argv, sem shell; o `file` faz parte do pacote `base` do Arch) e só jpg/png/webp entram, com uma linha `INFO` no log pros outros

**Checkpoint**: contrato congelado. As histórias podem começar.

---

## Phase 3: User Story 1 - Um fundo igual ao dos menus do jogo (Priority: P1) 🎯 MVP

> **T017–T020 feitas na branch `004-us1-fundo` e integradas (`a87e37b`).** Falta a T021–T022,
> que transformam o fundo na cena `menu`.

**Goal**: o desktop mostra o fundo dos menus do jogo, medido: sem grid, sem grão, vinheta medida,
arcos duplos e feixes em segmentos que respiram.

**Independent Test**: workspace vazio, screenshot medido (cores e ausência de grid) em 1080 e
hidpi; dois screenshots iguais com fixtures.

- [x] T017 [US1] Tirar o grid do fundo e da barra: `shell/wallpaper/Wallpaper.qml` e `shell/hud/Hud.qml` deixam de usar o `GridBackground`. O primitivo sai de `shell/ds/primitives/` e da galeria se mais nada o usar (com `Tokens.color.grid`)
- [x] T018 [US1] `shell/ds/primitives/PaperDecor.qml` refeito com a geometria do mockup: 4 arcos (2 duplos, +7 px), 4 feixes de 2–3 linhas a 42° que começam e terminam na tela (começos escalonados 34 px, fins 60 px por linha), linhas em tinta a 15%, respiração (arcos ±9° em 600 s, feixes ±70 px em 300 s, os dois no ciclo de 600 s do `wallpaperPhase`, com defasagem por elemento), linhas nítidas na grade física
- [x] T019 [US1] Calibrar o papel + a `Vignette` pras medidas: centro `#C8C3AC`, bordas `#A6A18D`, cantos `#8C8978` (design system §6), sem emendar com a barra (FR-004)
- [x] T020 [US1] Validar (`lab/perf begin "004: US1 fundo"`): cenário 1 do quickstart (cores ≤ 4 níveis e sem grid, em 1080 e hidpi), cenário 2 (fundo), `lab/check-u1` ainda 15/15 — **feito** em `a87e37b` (branch `004-us1-fundo`, já integrada): check-u1 15/15; cores a ≤ 4 níveis do jogo em 1080 e 2560x1600 @1,25; `lab/perf` 2026-10-27T144633
- [x] T021 [US1] Extrair o fundo da US1 pra `shell/wallpaper/Scene.qml`, guiado pelos parâmetros (`params` do contracts/components.md): papel com as cores, camadas `arcs`/`beams`/`rules` (com `Rule` dotted em y 108 e 1012) e `dots` (`Canvas` com pontos de 1 px a cada 4 px, pintado uma vez), `lineAlpha`, `motion`. A cena `menu.json` tem que dar o mesmo screenshot da T020 (`lab/diffshot` = 0) — **feito:** `Scene.qml` + `PaperDecor`/`Vignette` com parâmetros opcionais (padrões iguais aos de antes). `lab/diffshot` entre a árvore `236b350` e a cena `menu` = **0 px em 1080 e em 2560x1600 @1,25** (`lab/perf` 2026-10-27T154138, `out/004-T021-cena`). A trama do `dark` usa `fillRect` (o `putImageData` e o padrão de `ImageData` não pintam nada neste Canvas)
- [x] T022 [US1] `shell/wallpaper/WallpaperView.qml` (cena por enquanto; imagem na US4) e `shell/wallpaper/Wallpaper.qml` mostrando `WallpaperStore.resolve(screen.name)`, com troca seca. Validar: `ipc call wallpaper set` com cada cena muda o fundo (screenshot + `dump`) — **feito:** `set scene:<cena> all` troca o fundo pras 4 cenas, com o `dump` certo (`out/004-T022-cenas`, montagem incluída); trama do `dark` medida em `#252525`; `lab/check-u1` sem regressão (o único FAIL era um lint da `WallpaperView`, corrigido e conferido)

**Checkpoint**: MVP: o fundo fiel está no desktop e já troca de cena por comando.

---

## Phase 4: User Story 2 - Escolher no seletor (Priority: P1)

> **Pendente: depende da 003 (US2).** A implementação das outras fases foi feita antes (branch
> `004-wallpaper-system`); esta fase e o polimento ligado ao seletor ficam pra quando a 003 entrar.
>
> **Depende da implementação da 003** (moldura de popup, linha de opção, seletor de valor, rodapé de
> teclas, foco em duas colunas). Começa quando a 003 entrar na `004-wallpaper-system`.

**Goal**: o seletor no layout ITEMS: lista agrupada com a pipa, prévia ao vivo, opções em duas
colunas, aplica por monitor.

**Independent Test**: `ALT + W` e IPC abrem; teclas reais (SC-004) terminam no estado esperado.

- [ ] T023 [P] [US2] `shell/ds/composites/GroupedList.qml`: a `CursorList` com títulos de grupo sem foco, itens apagados (`dim`), a marca de aplicado à direita (`● ALL` / `● DP`), `focused: false` = pipa clara e parada (estado da 003). Se a 003 já der grupos à `CursorList`, este arquivo vira um alias fino — **pendente: depende da 003 (US2).**
- [ ] T024 [P] [US2] `shell/wallpaper/PreviewCard.qml`: `Card` da 001 com o nome, uma `WallpaperView` pequena (cena viva com `s` = 512/1920; imagem com `sourceSize` 512×288 e o filtro; vídeo = "NOT YET") e a descrição — **pendente: depende da 003 (US2).**
- [ ] T025 [US2] `shell/wallpaper/WallpaperPicker.qml`: `PanelWindow` `Overlay` no monitor em foco, `keyboardFocus: Exclusive`, com a moldura da 003 (escurecimento + papel), o título `WALLPAPER -Select`, a `GroupedList`, o `PreviewCard` e o card "Options" (linhas `Monitor`, `Transition` e `Paper filter` só pra imagem, mais as informações), o rodapé de teclas por foco, a navegação em duas colunas (FR-008) e o `dump()` do data-model ("Picker"). Abre focado no item aplicado no monitor — **pendente: depende da 003 (US2).**
- [ ] T026 [US2] `shell/shell.qml`: `LazyLoader` do `WallpaperPicker` (fechamento em duas fases, como a galeria) e `picker(open|close|toggle)` ligado; `dump` inclui o `picker` — **pendente: depende da 003 (US2).**
- [ ] T027 [US2] Validar (`lab/perf begin "004: seletor"`): cenário 4 do quickstart com teclas reais (`lab/key`) e `ALT + W`; screenshot do seletor aberto sobre o fundo escurecido, em 1080 e hidpi; cenário 2 (seletor aberto, `diffshot` = 0); linhas SC-004 no `lab/check-004` — **pendente: depende da 003 (US2).**

**Checkpoint**: o dono escolhe o papel de parede no seletor.

---

## Phase 5: User Story 3 - Transições (Priority: P2)

**Goal**: toda troca usa a transição escolhida; a camuflagem é a de fábrica.

**Independent Test**: sem fixtures, rajada de quadros de cada transição (`set` por IPC); troca no meio
de outra parte da tela atual.

- [x] T028 [P] [US3] `shell/shaders/transition.frag` (GLSL 440, `#version 440`, bloco `qt_Matrix`/`qt_Opacity` do `ShaderEffect`): os 4 modos com os uniforms e as etapas do research R4 (camuflagem: refração, brilho, mosaico 12/6/4 px, rastro, falha por `hash(célula, seed, frame)`; varredura; quadradinhos; crossfade). Compila com o `build.sh` na VM sem aviso — **feito:** compila sem aviso pelo `build.sh` na VM (pelo gancho do `lab/sync`). Medidas em px do jogo = px do canvas do mockup × 2 (refração 6/4 px, mosaico 12/6/4, contorno 2 px, falha deslocada 2–4 px). **Desvios:** `frame` = `elapsed / 33,3` (não 16,7): mantém a taxa de falhas do mockup, que rodava a ~30 fps, e cada falha dura um quadro dele; o rastro some de forma contínua (o mockup usava 8 degraus só por desempenho). O hash é o "Hash without Sine" (MIT, Dave Hoskins), creditado no `CREDITS.md`
- [x] T029 [P] [US3] `shell/wallpaper/WipeEdge.qml`: `Rule { kind: "dotted"; rotation: -90 }` da 001, do tamanho da altura da tela, posicionado em `x = progress · (largura + 40)` (research R5) — **feito.** **Desvio:** `rotation: 90` (não −90), com origem no canto: assim a linha fica na borda e os tracinhos e trios ficam do lado do fundo novo, como no mockup
- [x] T030 [US3] `shell/wallpaper/WallpaperTransition.qml`: dois slots (`Loader` de `WallpaperView`), `ShaderEffectSource` vivos com `textureSize` físico, `ShaderEffect` com o `transition.frag.qsb`, animação de `elapsed` (camuflagem: até `1200 + trail + 450` ms; outras: 900 ms, ease in-out), `seed`/`origin` sorteados (com fixtures: 1 e o centro), `instant` (fixtures ou `reduceMotion`), fallback de crossfade em QML puro se o `.qsb` não existir (aviso uma vez) e troca no meio de outra partindo da tela atual (FR-017) — **feito.** **Desvio (FR-017):** em vez de usar como origem uma textura viva da transição em andamento (texturas recursivas), a troca no meio de outra pausa a atual, tira um `grabToImage` (no tamanho físico) e parte desse quadro parado; o fundo antigo deixa de respirar só durante a nova troca (≤ 4,3 s, imperceptível). Sem o `.qsb`: crossfade por opacidade, com um aviso
- [x] T031 [US3] `shell/wallpaper/Wallpaper.qml` passa a usar a `WallpaperTransition` com `kind`/`cell`/`trail`/`glitch` do `WallpaperStore`; `dump` mostra `transitioning`, `kind` e `elapsed` por monitor — **feito**
- [x] T032 [US3] Validar (`lab/perf begin "004: transições"`): cenário 5 do quickstart (as 4 rajadas, `menu` ↔ `dark`); FR-017 (dois `set` a 300 ms, rajada mostra que não pula); `reduceMotion: true` num `shell.json` da VM = troca instantânea; fixtures = instantânea — **feito** (`lab/perf` 2026-10-27T155020, `out/004-T032-transicoes`, com `bursts.txt` e montagens): camuflagem menu→dark e dark→menu em 40×100 ms (refração antes da onda, brilho na frente, células pixeladas, contorno e véu sumindo, falhas de 1 quadro, fim limpo), varredura com a régua na borda, quadradinhos com o quadrado de tinta, crossfade; FR-017: o segundo `set` parte do quadro na tela, sem pulo; `reduceMotion: true` e fixtures = instantânea. Nota: um `shell.json` criado com o shell rodando só vale depois de reiniciar (o `Settings` da 001 não observa arquivo que não existia)
- [x] T033 [US3] Medir o custo (SC-009): sessões `lab/perf` com 10 trocas de camuflagem e 10 de crossfade (opcional `QSG_RENDER_TIMING=1`), sem meta; anotar no relatório — **feito:** camuflagem (`lab/perf` 2026-10-27T155509): 10 trocas, `qs` 6,25 s de CPU em 49,5 s (12,6% de um núcleo), janela do fundo ≈60 fps (intervalo p95 17 ms, quadro p95 17 ms, máx 19), NVIDIA do host 32% média / p95 58%, QEMU 34% de um núcleo; crossfade (2026-10-27T155649): `qs` 1,82 s em 16,3 s (11,2%), quadro p95 17 ms, NVIDIA 26% / p95 42%. Por segundo animado o CPU do `qs` é parecido (0,15 × 0,20 s): o extra da camuflagem fica na GPU. `out/004-T033-custo`

**Checkpoint**: as quatro transições funcionam, com a camuflagem de fábrica.

---

## Phase 6: User Story 4 - Usar as minhas imagens (Priority: P2)

**Goal**: as imagens da pasta aparecem no catálogo, cobrem a tela sem distorcer e recebem o filtro
de papel.

**Independent Test**: com a pasta de teste, `list` traz as 3 imagens válidas; cada uma aplica
cortada, com e sem filtro; arquivo novo aparece em ≤ 2 s.

- [x] T034 [US4] `shell/services/WallpaperCatalog.qml`: imagens via `FolderListModel` (`folder` = `Settings.wallpaperFolder` ou a pasta da fixture; `nameFilters` jpg/jpeg/png/webp nas duas caixas; `showDirs: false`; ordem por nome), `fileUrl` como URL, sondagem com `Image` de 32×32 pra deixar de fora os quebrados (linha no log via `console.info`), `folderMissing` quando a pasta não existir; nenhum nome passa por shell (FR-011, FR-012) — **feito** (escrito junto com o T013). **Desvio (R6):** a sondagem é um `file --brief --mime-type` em argv (ver T016), não um `Image` de 32×32. A existência da pasta vem de um segundo `FolderListModel` na pasta-mãe (só diretórios), que também faz uma pasta criada depois entrar sozinha
- [x] T035 [P] [US4] `shell/wallpaper/PaperFilter.qml`: `MultiEffect` com `colorization: 0.85` e `colorizationColor` = papel do centro, mais a `Vignette` por cima (research R7) — **feito.** **Desvio (R7):** a colorização do `MultiEffect` multiplica a luminância pela cor, então com o papel do centro a imagem ficava ~30 níveis mais escura que o filtro "color" do mockup. A cor do filtro é o matiz do papel em brilho cheio (`Tokens.wallpaper.filterTint` `#FFFAD9`): diferença média pro mockup de −4,9/−3,2/−0,4 níveis (`out/004-T037-imagens/filter-vs-mockup.png`). Os escuros ficam um pouco menos quentes que no mockup; o dono confere no SC-010. A imagem entra no `MultiEffect` por um `ShaderEffectSource` dela já cortada
- [x] T036 [US4] `shell/wallpaper/WallpaperView.qml`: imagem com `PreserveAspectCrop`, `sourceSize` = tamanho físico do monitor, `asynchronous`, `cache: false`, e `PaperFilter` a menos que o caminho esteja em `WallpaperStore.paperFilterOff` — **feito**
- [x] T037 [US4] Validar (`lab/perf begin "004: imagens"`): cenário 3 do quickstart (as 3 imagens, cortadas, com e sem filtro via `ipc call wallpaper filter`, lado a lado com o mockup), cenário 7 (arquivo novo ≤ 2 s; nome difícil aplica) e a borda da pasta inexistente (cenário 11) — **feito** (`lab/perf` 2026-10-27T155929, `out/004-T037-imagens`): as 3 imagens aplicam, cortadas sem esticar, com e sem filtro; `nova.jpg` aparece em 0,28 s e some em 0,25 s; o nome difícil aplica; pasta inexistente = `folderMissing` sem imagens (e criada depois, as imagens entram); `set image:/nao/existe` = erro; log sem aviso

**Checkpoint**: imagens funcionando, com filtro.

---

## Phase 7: User Story 5 - Lembrar e controlar por comando (Priority: P3)

**Goal**: a escolha sobrevive a reiniciar; `next`/`prev` no monitor em foco; fallbacks de monitor e
de arquivo.

**Independent Test**: `set scene:dark <monitor>`, reiniciar o `qs`, conferir; `next`/`prev` pelo
`dump`.

- [x] T038 [US5] `shell/services/WallpaperStore.qml`: persistência em `$XDG_STATE_HOME/rien-os/wallpaper.json` (research R8): leitura por `FileView`, escrita com `setText` + `atomicWrites`, agrupada em 250 ms, criação da pasta por `Process` em argv só se preciso; nada escrito com a fixture `wallpaper` ativa; prioridade estado > `shell.json` > `defaults.json`; estado ilegível começa vazio com linha no log — **feito.** O `FileView.setText` cria a pasta sozinho (conferido na VM), então o `Process` de `mkdir` saiu (como o R8 previa). O estado é lido bloqueando no início, então o primeiro quadro já mostra a escolha salva, sem transição
- [x] T039 [US5] `next`/`prev` no `Compositor.focusedMonitor` quando o monitor vem vazio; fallback de monitor sem escolha e de imagem apagada (`resolve`, com linha no log) (FR-019, FR-020) — **feito** (o `step`, o `resolve` e o fallback já vinham do T014; a imagem salva só é resolvida depois de o catálogo ler a pasta, pra não trocar pra cena padrão e voltar no início)
- [x] T040 [US5] Validar (`lab/perf begin "004: estado"`): cenário 6 do quickstart (reinício do `qs`, arquivo de estado conferido, `~/.config/rien-os/` intocado), `next`/`prev` pelo `dump`, imagem apagada → cena padrão — **feito** (`lab/perf` 2026-10-27T160430, `out/004-T040-estado`): estado gravado e de volta depois do `pkill qs`, sem transição; `next`/`prev` no monitor em foco; imagem apagada = cena padrão + linha no log; prioridade estado > `shell.json` > padrão; nada escrito com a fixture `wallpaper` (md5 igual); estado ilegível = começa vazio com uma linha `INFO`; `~/.config/rien-os/` nunca criado

**Checkpoint**: as cinco histórias funcionam.

---

## Phase 8: Polish & validação final

- [ ] T041 [P] `shell/gallery/Gallery.qml`: seção "Wallpaper" (FR-022) com as 4 cenas em miniatura, uma imagem de teste com e sem filtro, um quadro congelado de cada transição (`elapsed`/`progress` fixos, `seed = 1`) e a `GroupedList` com e sem foco — **pendente: depende da 003 (US2).** A página da galeria já está cheia (três colunas e a barra de abas) e a 003 também vai pôr peças nela; a seção Wallpaper (cenas, filtro, quadros congelados das transições e a `GroupedList`) entra junto com o seletor, quando o layout da galeria for decidido com as peças das duas
- [ ] T042 [P] `docs/design-system.md`: as cenas (parâmetros), o filtro de papel, as 4 transições (com a camuflagem descrita etapa por etapa) e o layout lista + prévia + opções como composto reutilizável (FR-022) — **parcial:** feito o §8 do `docs/design-system.md` (era §7 antes do merge da 003) (cenas e parâmetros, imagens, filtro de papel, as 4 transições com a camuflagem etapa por etapa, regras, custo medido, tokens e configuração) e corrigida a linha "Fundo do desktop" do §5 (ainda citava o grid). **Pendente: depende da 003 (US2):** o layout lista + prévia + opções como composto reutilizável
- [x] T043 [P] Conferir FR-023 (nenhum texto fixo fora do `Strings.qml`, por grep) e "nenhuma cor fora do `Tokens.qml`", por grep em `shell/wallpaper/` e `shell/shaders/` (as cores do shader chegam por uniform) — **feito:** nenhum texto de UI fixo fora do `Strings.qml` em `shell/wallpaper/` e nos serviços novos (só linhas de log e respostas de IPC, em inglês); a única cor literal (um fallback em `Scene.towardTint`) passou a vir do `Tokens`, sem mudar a tela (`dark` = 0 px de diferença); o shader recebe as cores por uniform. Conferido na VM dentro da sessão `lab/perf` 2026-10-27T160835
- [ ] T044 Rodar o quickstart inteiro com o `lab/check-004` numa sessão `lab/perf begin "004: validação" --kind validacao --task 004` (SC-001 a SC-008, bordas, galeria), em `lab/profile 1080` e `hidpi` — **parcial:** o `lab/check-004` roda tudo o que não depende do seletor: **21 PASS / 0 FAIL** em 1080 e hidpi (SC-001, SC-002 do fundo, SC-003, SC-006, SC-007, SC-008, bordas, FR-017), mais o `lab/check-u1` 15/15 (`lab/perf` 2026-10-27T160835, `out/004-check-004`). **Pendente: depende da 003 (US2):** SC-004, a metade do SC-002 com o seletor aberto e a galeria
- [ ] T045 Corrigir o que o T044 apontar e repetir só os cenários afetados — **pendente: depende da 003 (US2).**
- [ ] T046 Escrever `specs/004-wallpaper-system/relatorio.md` (o que ficou pronto com a evidência, decisões tomadas sozinho, custo somado do `lab/perf`, commits) e montar a imagem final pra o dono (SC-010): as 4 cenas, o seletor aberto, uma imagem com e sem filtro e 6 quadros da camuflagem, ao lado do mockup — **pendente: depende da 003 (US2).**
- [ ] T047 Rodar `/speckit-analyze` e resolver as inconsistências entre spec, plano e tarefas — **pendente: depende da 003 (US2).**

---

## Dependencies & Execution Order

- **Setup (T001–T007):** o T001 vem primeiro e pode parar tudo (sem shader na VM, sem camuflagem).
  T002–T006 são [P] entre si; o T007 fecha a fase.
- **Foundational (T008–T016):**
  - T008–T012 são [P], exceto o T008, que vem antes porque o `Settings` é lido por todos;
  - T013 e T014 dependem do T012;
  - T015 depende de T013 e T014;
  - **o T016 congela o contrato.**
- **US1 (T017–T022):**
  - T017–T020 estão na branch `004-us1-fundo` (sessão principal) e não esperam o Foundational;
  - T021–T022 dependem da US1 integrada e do T016.
- **Depois do T022, três frentes em paralelo:**
  - **US3 (T028–T033):** T028 e T029 são [P]; T030 depende deles; T031 depende do T030;
  - **US4 (T034–T037):** T035 é [P]; T036 depende de T034 e T035;
  - **US5 (T038–T040):** só no `WallpaperStore.qml`, que nenhuma outra frente edita depois do T014.
- **US2 (T023–T027):** espera a **implementação da 003**. T023 e T024 são [P]; T025 depende deles e da
  T031 (aplicar com transição); T026 depende do T025.
- **Polish (T041–T047):** depois de todas as histórias. T041–T043 são [P].

## Parallel Example (agentes, cada um com worktree e VM própria)

```text
Depois do T022:
  Agente A (teste-a): T028, T029 → T030 → T031 → T032, T033   (transições)
  Agente B (teste-b): T034, T035 → T036 → T037                (imagens)
  Agente C (teste-c): T038 → T039 → T040                      (estado)
Quando a 003 estiver implementada e integrada:
  Agente D (teste-a): T023, T024 → T025 → T026 → T027         (seletor)
Polimento:
  Agente E: T041 · Agente F: T042 · Agente G: T043  →  T044–T047 em sequência
```

## Implementation Strategy

1. **MVP = US1:** o fundo fiel (já em curso na `004-us1-fundo`) + a cena extraída (T021–T022). O
   desktop fica igual ao jogo e troca de cena por comando.
2. **Depois:** US3, US4 e US5 em paralelo, todas testáveis pelo IPC, sem esperar a 003.
3. **US2:** o seletor, assim que a 003 estiver pronta. É P1 pra o dono, mas depende de outra spec.
4. Cada fase termina com evidência no lab e relatório no `rien-OS-relatorios`. Nenhuma tarefa é
   marcada `[x]` sem prova.
