# Pesquisa (Fase 0): Sistema de papel de parede

Cada item segue o formato: decisão, motivo e o que foi descartado. As APIs foram conferidas nos
`qmltypes` do Quickshell 0.3.1 e do Qt 6.11 (`/usr/lib/qt6/qml/…`), a mesma versão da VM. O que
precisa de prova na VM está marcado **a verificar no lab**.

A referência visual é o mockup aprovado (`rien-OS-private/lab/mockups/papel-de-parede/index.html`);
os algoritmos abaixo são a tradução do JavaScript dele pro shell.

## R1. Cena procedural: o fundo fiel vira um JSON de parâmetros

- **Decisão:**
  - **o arquivo:** uma cena é um JSON em `shell/wallpaper/scenes/<id>.json`, no formato de
    [contracts/scene.schema.json](contracts/scene.schema.json):
    - cores do papel (centro, bordas, cantos) ou a variante escura;
    - camadas `arcs`, `beams`, `rules`, `dots` (a trama da variante escura);
    - movimento: período e amplitude da respiração.
  - **o componente:** `Scene.qml` desenha a cena a partir desse JSON, reaproveitando o que a US1 fizer:
    - **papel com vinheta:** a cor base mais o `Vignette` da 001, calibrado pras medidas
      (`#C8C3AC` → `#A6A18D` → `#8C8978`);
    - **arcos e feixes:** a camada de linhas (o `PaperDecor` refeito na US1), com a geometria do
      mockup: 4 arcos, 2 duplos (+7 px no raio), e 4 feixes de 2–3 linhas a 42°, com começos e fins
      escalonados (34 px e 60 px por linha);
    - **réguas:** `Rule { kind: "dotted" }` da 001 em y = 108 e y = 1012 (px do jogo);
    - **trama escura:** um `Canvas` pintado uma vez com pontos de 1 px a cada 4 px, em branco a 7%;
  - **as quatro cenas de fábrica:**
    - `menu`: papel, arcos e feixes;
    - `rules`: `menu` + réguas;
    - `dark`: `#141414`, linhas cinza a 20%, trama;
    - `plain`: só papel e vinheta;
  - **o movimento** segue o mockup (velocidade "real"):
    - os arcos oscilam ±9° em torno do próprio centro, com período de 420 s;
    - os feixes deslizam ±70 px ao longo da direção, com período de 300 s;
    - cada elemento tem uma defasagem própria;
    - a fase vem do `Timer` que já existe no `shell.qml`, que para com fixtures, com
      `wallpaperMotion: false` ou pelo IPC.
- **Motivo:** FR-001–FR-005. As cenas viram dados, não código: uma cena nova é um JSON. A US1 já
  entrega o desenho, e este item só põe os números num arquivo.
- **Descartado:**
  - **uma imagem pré-renderizada por cena:** não respira, e não fica nítida em toda escala;
  - **cada cena como um componente QML diferente:** duplica o desenho.
- **Nota:** se a US1 girar os arcos com `rotation` num `Canvas` maior, as linhas podem perder a
  nitidez de 1 px. A US1 decide e mede (hoje, a 001 move as camadas só em pixels físicos inteiros).

## R2. Pilha de desenho do fundo e das transições

- **Decisão:**
  - **o desenho:** cada `Wallpaper` (um por monitor) tem um `WallpaperTransition` com dois slots
    (`Loader`), `a` e `b`:
    - fora de transição, só o slot atual existe e aparece direto;
    - numa troca, o novo item carrega no outro slot;
  - **a transição:**
    - os dois slots viram texturas vivas: `ShaderEffectSource { live: true; hideSource: true }`;
    - um `ShaderEffect` (R4) mistura as duas;
    - ao fim, o slot antigo é descarregado e o efeito some;
    - as cenas continuam respirando durante a troca;
  - **a resolução:** as texturas são feitas no tamanho do monitor em pixels físicos
    (`textureSize` = tamanho × escala do monitor), pra não borrar no 1,25.
- **Motivo:** o shader só existe durante a transição (custo zero com o fundo parado), e a troca
  pega o fundo antigo **como está na tela**, inclusive no meio de outra transição (FR-017): o slot
  "antigo" passa a ser um `ShaderEffectSource` da própria transição em andamento.
- **Descartado:**
  - **capturar a tela com `ScreencopyView`:** pega as janelas por cima e depende do protocolo;
  - **`grabToImage` do fundo antigo:** congela o movimento e custa uma leitura de GPU por troca.

## R3. Shaders: onde compilar o `.qsb`

- **Decisão:**
  - **a fonte:** GLSL 440 em `shell/shaders/transition.frag` (só fragmento; o vértice padrão do
    `ShaderEffect` serve);
  - **o script:** `shell/shaders/build.sh` roda
    `qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o <x>.frag.qsb <x>.frag` pra cada `.frag`.
    Ele é idempotente e só recompila o que mudou;
  - **onde roda:** **onde a UI roda**:
    - no lab, o `lab/sync` chama o script dentro da VM quando um `.frag` muda;
    - no futuro, o instalador (S3) chama o mesmo script.
  - **sem compilador:** se o `qsb` faltar, a transição cai pro crossfade em QML puro (opacidade) e o
    log avisa uma vez.
  - **no git:** o `.qsb` continua fora (`.gitignore`).
  - **spike antes de tudo, a verificar no lab:** um shader trivial rodando na VM via virgl. É a
    pendência "shaders via virgl" do `lab/README.md`. Se o virgl falhar, a camuflagem não tem como
    ser provada na VM, e o plano volta pro dono.
- **Motivo:**
  - o Qt 6 não compila GLSL em tempo de execução: o `ShaderEffect` só aceita `.qsb`;
  - compilar onde roda evita binário no repositório e garante o formato certo pro Qt da máquina;
  - o `qt6-shadertools` é pequeno e já existe no Arch.
- **Descartado:**
  - **commitar o `.qsb`:** é binário, desatualiza em silêncio e o `.gitignore` já o exclui;
  - **compilar num container no host:** funcionaria, mas o Qt do container pode divergir do Qt da
    máquina;
  - **fazer a camuflagem em `Canvas`, como no mockup:** o `Canvas` do QML pinta na CPU. Seriam milhares
    de `drawImage` por quadro em 1920×1080 físicos, o que não fica fluido nem no host.

## R4. A camuflagem no shader

O algoritmo do mockup, por fragmento, com tudo em pixels lógicos do monitor (`itemSize`), o que deixa
o resultado igual em qualquer escala.

**Uniforms:**

| Uniform | O que é |
|---|---|
| `mode` | 0 camuflagem, 1 varredura, 2 quadradinhos, 3 crossfade |
| `elapsed` | ms desde o início da troca |
| `progress` | 0–1, já com ease in-out; usado pelos outros modos |
| `revealMs` | 1200 |
| `trailMs` | 800 / 1500 / 2600 |
| `cell` | tamanho da célula em px do jogo × `s` |
| `glitch` | probabilidade por célula e por quadro: 0 / 0,0008 / 0,006, como no mockup |
| `origin` | 0–1, ponto de saída da onda, perto do centro |
| `seed` | semente da troca |
| `frame` | índice do quadro, `floor(elapsed / 16,7)` |
| `ink` | cor da tinta, do `Tokens` |
| `light` | cor clara, do `Tokens` |
| `itemSize` | tamanho do item em px lógicos |

**Por célula:**
- `r = revealMs · (0,85 · dist(centro da célula, origem) / dist máx + 0,15 · hash(célula, seed))`;
- `age = elapsed − r`.

**Etapas:**
- **`age < −200`:** o fundo antigo, sem mexer.
- **`−200 ≤ age < 0`, a refração:**
  - `k = 1 + age/200`;
  - amostra o antigo deslocado por `(sin(t·9+φ)·3k, cos(t·7+φ)·2k)` px, com `φ = hash(célula)`;
  - com `k > 0,5`, a amostra é em mosaico de 4 px.
- **`age ≥ 0`, o novo pixelado:** a amostra do novo é quantizada em blocos de 12 px (`age < 130`),
  6 px (`< 260`) e 4 px (`< 400`), e nítida depois.
- **Brilho na frente:** `age < 60` e o pixel na borda de 1 px da célula → mistura com `light` a 55%.
- **Rastro:** enquanto `age < trailMs`, com `a = 1 − age/trailMs`:
  - véu de `light` a `0,10·a`;
  - a borda de 1 px em `ink` a `0,30·a`.
- **Falha:** `hash(célula, seed, frame) < glitch·a`:
  - em 30% dos casos, o fundo antigo;
  - senão, o novo deslocado ±1–2 px na horizontal.
- **Fim:** quando `elapsed > revealMs + trailMs + 450`.

**Os outros modos:**
- **varredura:** novo onde `x < progress · (largura + 40)`; a borda é desenhada fora do shader
  (R5);
- **quadradinhos:** células de 24 px; limiar `s = 0,7 · (coluna/colunas) + 0,3 · hash`. Se
  `progress > s + 0,08`, mostra o novo; se `progress > s`, um quadrado de tinta com 4 px de
  margem; senão, o antigo;
- **crossfade:** `mix(antigo, novo, progress)`.

Duração: 900 ms com ease in-out (FR-015).

**Determinismo:**
- `seed` e `origin` saem de um gerador com semente;
- com fixtures, a troca é instantânea (FR-016);
- a galeria mostra quadros congelados de cada modo, com `elapsed`/`progress` fixos e `seed = 1`, pra
  SC-002 continuar valendo.

**Movimento reduzido:** com `Settings.reduceMotion`, a troca é instantânea.

- **Motivo:** o fragment shader faz por pixel o que o mockup fazia por célula, em uma passada de GPU,
  e cada etapa continua mapeada no código, pra calibrar com o dono. `frame` e `seed` tornam a falha
  "aleatória" e ainda reproduzível.
- **Descartado:**
  - **uma grade de `Item`s com `ShaderEffectSource` por célula:** milhares de itens;
  - **partículas:** não reproduzem o mosaico.

## R5. Borda da varredura

- **Decisão:** a borda é um `Rule { kind: "dotted"; rotation: -90 }` da 001, num `Item` que acompanha
  `x = progress · (largura + 40)`, desenhado por cima do `ShaderEffect`. A régua girada em 90° traz os
  tracinhos e os trios ∵ do jogo ao longo da borda, nítidos (rotação de ângulo reto).
- **Motivo:** reaproveita a régua pronta (e nítida no 1,25) em vez de redesenhar o padrão no shader.
- **Descartado:** desenhar os tracinhos no shader (código duplicado da `Rule`).

## R6. Imagens da pasta do usuário

- **Decisão:**
  - **a pasta:** `FolderListModel` (`Qt.labs.folderlistmodel`, já instalado com o
    `qt6-declarative`):
    - `folder` = a pasta do `Settings`;
    - `nameFilters` = `*.jpg *.jpeg *.png *.webp` (com as versões maiúsculas);
    - `showDirs: false`, ordenada por nome;
  - **mudanças na pasta:** o modelo observa a pasta sozinho, então um arquivo novo ou apagado
    aparece ou some sem reiniciar (FR-011, SC-007: até 2 s);
  - **caminhos:** a URL vem do papel `fileUrl` do modelo (um `QUrl` já codificado). No estado, o
    caminho é guardado como texto local e volta a ser URL com `encodeURIComponent` em cada segmento.
    **Nenhum nome passa por shell** (FR-012);
  - **arquivos quebrados:** um `Image` de sondagem por arquivo (`sourceSize` 32×32, `asynchronous`,
    `cache: false`). Com `status === Image.Error`, o arquivo sai do catálogo e o log ganha uma linha
    (`console.warn`, que é aviso de QML, não erro). **A verificar no lab:** se o aviso conta como
    "aviso" no SC-008. Se contar, a linha vai pro `console.info`;
  - **na tela:** `Image` com `fillMode: Image.PreserveAspectCrop`, `sourceSize` = tamanho físico do
    monitor, `asynchronous: true` e `cache: false` (FR-010);
  - **miniatura e prévia:** `sourceSize` 512×288.
- **Motivo:** tudo nativo do Qt, sem processo de fora, com observação de pasta incluída. A lição
  do Unit-3 (cada miniatura decodificando a imagem inteira) está resolvida pelo `sourceSize`.
- **Descartado:**
  - `ls`/`find` via `Process`: precisa interpretar a saída e não observa a pasta;
  - `FileView` (é pra arquivo, não pra pasta).

## R7. Filtro de papel

- **Decisão:** `PaperFilter.qml` = a imagem → `MultiEffect` (`QtQuick.Effects`) com
  `colorization: 0.85` e `colorizationColor` = papel do centro (`#C8C3AC`) → `Vignette` por cima,
  como no mockup (`globalCompositeOperation: "color"` a 85% + vinheta de tinta a 35% nos cantos). O
  filtro vem ligado e é desligado por imagem (estado, R8).
- **Motivo:** o `MultiEffect` já vem compilado no Qt, sem `.qsb` próprio. A colorização dele preserva a
  luminância e troca o matiz, que é o efeito do modo "color" do mockup. **A verificar no lab:** a
  comparação lado a lado com o mockup, no SC-003.
- **Descartado:** um shader próprio de "color blend" (mais um `.qsb` pra manter, pra um efeito que o Qt
  já tem).

## R8. Estado: escolha por monitor, transição e filtros

- **Decisão:**
  - **o arquivo:** `$XDG_STATE_HOME/rien-os/wallpaper.json` (padrão
    `~/.local/state/rien-os/wallpaper.json`), no formato de
    [contracts/state.schema.json](contracts/state.schema.json):
    - `all`;
    - `monitors { nome: id }`;
    - `transition { kind, cell, trail, glitch }`;
    - `paperFilterOff [caminhos]`;
  - **a leitura:** um `FileView` lê;
  - **a escrita:** `setText(JSON)`, com `atomicWrites: true`, depois de cada mudança, agrupada em
    250 ms;
  - **a pasta `rien-os`:** se não existir, é criada por `Process { command: ["mkdir", "-p", dir] }`,
    em forma de argv, sem shell. **A verificar no lab:** se o `FileView` cria a pasta sozinho. Se
    criar, o `Process` sai;
  - **com fixtures:** o estado vem da fixture e **nada é escrito** (os screenshots não sujam o estado
    da VM);
  - **ordem de prioridade da transição:** estado (a última escolha no seletor) > `shell.json` do
    usuário > `defaults.json` (camuflagem, 24 px, rastro longo, falhas visíveis).
- **Motivo:**
  - FR-018: sobrevive a reiniciar;
  - constituição III: o estado não é config, e o sistema não escreve em `~/.config`;
  - escrita atômica: o arquivo nunca fica pela metade.
- **Descartado:**
  - **gravar no `shell.json`:** viola a III;
  - **`Quickshell.statePath()`:** a pasta é por shell, e o caminho deixaria de ser previsível pro
    `rien` (S4).

## R9. Monitores

- **Decisão:**
  - **identidade:** o monitor é o nome da saída (`ShellScreen.name`, ex.: `DP-1`, `eDP-1`);
  - **resolução da escolha:** `monitors[nome]` → `all` → `scene:menu` (FR-020);
  - **arquivo que sumiu:** imagem escolhida que não existe mais cai pro mesmo fallback e registra no
    log;
  - **monitor em foco** (pra `next`/`prev` e pra onde o seletor abre): o `Compositor` ganha
    `focusedMonitor`, lido do mesmo `hyprctl monitors -j` que já traz as escalas (campo `focused`),
    atualizado nos eventos que já existem. O `Compositor` continua sendo o único que fala com o
    Hyprland.
- **Motivo:** o nome da saída é estável entre reinícios; o fallback cobre monitor novo e imagem
  apagada.
- **Descartado:** o índice do monitor (muda com a ordem de conexão).

## R10. O seletor

- **Decisão:**
  - **a janela:** `WallpaperPicker.qml`, carregado por `LazyLoader` (como a galeria e o popup da 003),
    num `PanelWindow` de camada `Overlay` no monitor em foco, com `keyboardFocus: Exclusive`;
  - **a moldura e a navegação** vêm da 003: escurecimento, papel, sombra, pipa, duas colunas, linha
    de opção, seletor de valor e rodapé de teclas;
  - **as peças:**
    - **lista:** `GroupedList`, uma `CursorList` com títulos de grupo (SCENES, IMAGES, VIDEO) que não
      recebem foco. Se a 003 já der grupos à `CursorList`, usa direto;
    - **prévia:** `Card` da 001 com uma `WallpaperView` pequena: a cena viva com `s` = 512/1920, ou a
      imagem com `sourceSize` 512×288 e filtro. Pro vídeo, o texto "NOT YET";
    - **opções:** linhas `Monitor` (All monitors + cada saída), `Transition` (Camouflage, Wipe,
      Tiles, Crossfade) e, só pras imagens, `Paper filter` (On/Off), mais as informações Type, Layers,
      Motion e Now on.
  - **o estado do seletor** (foco, item, opção) fica no componente e sai no `wallpaper dump`.
- **Motivo:** FR-006–FR-009 e o layout do mockup; nada de moldura nova (princípio VII).
- **Descartado:** o carrossel do Unit-3 (bonito, mas fora do layout ITEMS que o dono aprovou).

## R11. Atalho na VM

- **Decisão:** **`ALT + W`** no `lab/guest/hyprland.lua`
  (`hl.bind("ALT + W", hl.dsp.exec_cmd("qs -p ~/nier/ui ipc call wallpaper picker toggle"))`). O
  `SUPER + W` da spec fica pros padrões gerenciados do instalador (S3).
- **Motivo:** o `hyprland.lua` da VM já usa ALT no lugar de SUPER, "pra nada colidir com os atalhos do
  host no modo `--window`". A intenção da spec (um atalho da sessão) não muda.

## R12. Movimento reduzido e chaves novas do `Settings`

- **Decisão:** o `defaults.json` ganha:
  - `reduceMotion: false`, a primeira chave de movimento reduzido do shell, que a FR-016 da 004 e o
    caso de borda da 003 pedem;
  - `wallpaperFolder: "~/Pictures/Wallpapers"`;
  - `wallpaperTransition: "camouflage"`;
  - `camouflage: { cell: 24, trail: 2600, glitch: 2 }`.

  O `Settings` valida assim:
  - `cell` ∈ {16, 24, 32};
  - `trail` entre 400 e 4000;
  - `glitch` ∈ {0, 1, 2};
  - fora disso, usa o padrão e registra um aviso.
- **Motivo:** FR-013, FR-014 e FR-016; a 003 já previa respeitar o movimento reduzido "quando existir".

## R13. Laboratório e evidência

- **Imagens de teste:** geradas uma vez num container (`archlinux` + `imagemagick`, label
  `nier-lab`) e commitadas em `shell/fixtures/wallpapers/`, cada uma com menos de 300 KB:
  - `ruins.jpg`: 1920×1080, gradiente + silhuetas, como no mockup;
  - `dunes.png`: 1600×1200 (4:3), pra testar o corte;
  - `parede 'teste' #1 (larga).png`: 2560×1080 (21:9, nome difícil);
  - `quebrada.jpg`: bytes aleatórios.

  São geradas pelo projeto, sem direito de terceiros.
- **Fixture `wallpaper-default.json`:** domínio `wallpaper` com:
  - `folder: "fixtures/wallpapers"`;
  - `all: "scene:menu"`;
  - `transition` de fábrica.
- **Medição do fundo (SC-001):** no screenshot de um workspace vazio, a média de três áreas:
  - o centro;
  - o meio das laterais;
  - os cantos, fora da barra e sem linhas.

  O limite é 4 níveis das medidas. **Sem grid:** o desvio da alta frequência (imagem − blur de 3 px)
  numa área de 400×200 sem linhas fica abaixo de 1,0. O grid antigo, a 6%, dá ≈3. ImageMagick no host,
  como o `diffshot`, depois da emenda da constituição da 001.
- **Teclas reais (SC-004):** com o `lab/key` (QMP).
- **Rajadas (SC-005):** um `lab/burst N ms [região]` novo roda um laço de `grim` **dentro da VM**,
  disparado por ssh antes do `set`. É o mesmo truque usado pra provar o blink da pipa. Sem fixtures, já
  que com elas a troca é instantânea. Pra camuflagem: 40 quadros a cada 100 ms; pros outros modos: 15
  quadros a cada 70 ms.
- **Arquivo novo na pasta (SC-007):** `lab/ssh cp` de uma imagem pra pasta de teste com o seletor
  aberto; o `dump` é consultado a cada 250 ms até 2 s.
- **Tudo junto:** `lab/check-004`, no padrão do `lab/check-u1` (PASS/FAIL por linha, pasta de
  evidência), dentro de `lab/perf`.

## R14. Custo

- **Decisão:** o SC-009 só registra. Uma sessão `lab/perf` com 10 trocas seguidas de camuflagem, e
  outra com 10 de crossfade, pra comparar. Opcionalmente, com `QSG_RENDER_TIMING=1` no
  `~/nier/ui.env` pra ter o tempo por quadro no log, que vai pro relatório.
- **Motivo:** constituição VII (implementar antes de otimizar); os números servem de base pro U6.
