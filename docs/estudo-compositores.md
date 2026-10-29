# Estudo de compositores: Hyprland × Niri × Mango (etapa 1, técnica)

Spec 009 (`specs/009-compositores/`). Etapa 1 de 2: a parte técnica, com a evidência de experiência
juntada pra sessão do dono. **Recomendação: pendente (notas do dono).** A etapa 2 entra quando o dono
devolver a folha de notas.

## 1. Resumo

**A pergunta:** a UI do YoRHa-OS (Quickshell) roda no Niri e no Mango? O que funciona, o que quebra, quanto
custa, e como os dois se comparam ao Hyprland, pra o dono decidir entre ficar só no Hyprland, suportar
mais de um ou trocar o padrão.

**O que foi feito:** as três cadeias montadas sobre a mesma base (o Arch instalado pela ISO oficial, spec
006), com os pacotes do mesmo dia (Arch Linux Archive, 2026/10/28); as ferramentas do laboratório
passaram a saber o compositor de cada VM; a UI da `main` rodou nos três, em 1080 e em hidpi; cada linha
da tabela §6 do contrato de compositor da 007 ganhou uma amostra real; custo medido em 3 rodadas por
compositor; rajadas das animações; colinhas e folha de notas pra sessão do dono.

**Números principais:**

| | Hyprland 0.56.2 | Niri 26.04 | Mango 0.18.3 |
|---|---|---|---|
| A UI aparece (barra, papel de parede, pop-ups) | sim | sim | sim |
| Abas e título da barra | sim | não (vazios: o adaptador é só Hyprland) | não (idem) |
| IPC: lista áreas e janelas, eventos, age em qualquer janela por id | sim | sim (sem tela cheia no IPC) | sim |
| Boot até a UI (mediana de 3) | 4,6 s | 3,2 s | 3,2 s |
| RAM da VM parada (mediana) | 866 MB | 566 MB | 612 MB |
| Visão geral nativa | não | sim | sim |
| Colunas que rolam | sim (layout `scrolling` do núcleo) | sim (o modelo inteiro) | sim (layout `scroller`) |
| Pacote | repositório oficial | repositório oficial | repositório oficial (`mangowm`) |
| Nota técnica (de 40) | 36,7 | 31,7 | 30,0 |

Nenhum dos três é eliminado. **Recomendação: pendente** (faltam as quatro notas de experiência do dono, 60
dos 100 pontos).

## 2. Como foi medido

- **Camadas:** `hypr-iso`, `niri-base` e `mango-base`, as três sobre a `arch-iso` (Arch 2026.10.01 pela
  ISO oficial com o archinstall), congeladas; os pacotes de 2026/10/28 pelo Arch Linux Archive (Hyprland
  0.56.2-4, niri 26.04-1, mangowm 0.18.3-1, Quickshell 0.3.2-1, mesa 26.2.5). As camadas de teste nascem
  delas e são descartáveis.
- **Como sobem:** cada um pelo jeito oficial: Hyprland com `uwsm start hyprland.desktop`, Niri com
  `niri-session`, Mango com `mango` direto do tty1; login automático no tty1.
- **VM:** QEMU com virgl e `egl-headless` (3D invisível), **4 núcleos e 4 GB** (decisão do dono de
  2026-10-28), uma saída de vídeo (1920x1080 escala 1, ou 2560x1600 escala 1,25 no perfil hidpi).
- **UI:** a `main` (`a3a9120`) com a renomeação pra YoRHa-OS (2026-10-29), sem mudança de código pra este
  estudo.
- **Limites:** a VM não serve pra julgar fluidez (o `grim` tira um quadro a cada 60–110 ms); gestos de
  touchpad não passam pela VM (só pela documentação); **duas saídas não dão** com `egl-headless` (a
  segunda cabeça da GPU virtual fica desconectada nos três), então a escala por monitor e o foco entre
  monitores ficam como pesquisa; o modo `--window` fica pra sessão do dono; o Hyprland 0.57 (saiu em
  2026-10-28) não foi testado (tarefa à parte, combinada com o dono); a
  máquina do dono estava com outros testes (spec 008) numa VM ao lado durante parte das medidas
  (registrado nos relatórios do `lab/perf`).
- **Evidência:** cada teste numa sessão `lab/perf` (citadas pelo id); screenshots citados pelo nome e pelo
  sha256 (16 primeiros dígitos) que o `lab/shot` registrou; as amostras de IPC e as rajadas ficam no
  repositório privado do laboratório.

## 3. Tabela Hyprland × Niri × Mango

### 3.1 Instalação e partida

| | Hyprland | Niri | Mango |
|---|---|---|---|
| Pacote | `extra/hyprland` 0.56.2-4 | `extra/niri` 26.04-1 | `extra/mangowm` 0.18.3-1 (era "MangoWC"; mudou de nome e entrou no `extra` em 2026) |
| Dependências que vieram junto (além das comuns) | `uwsm`, `hyprpm` à parte | nenhuma obrigatória além do `niri` | `wlroots0.20`, `scenefx`, `xorg-xwayland` |
| Como sobe | `uwsm start hyprland.desktop` | `niri-session` (sessão systemd) | `mango` (sobe o próprio `mango-session.target`) |
| uwsm | é o padrão do lab | sobe com `uwsm start niri.desktop` (spike; não é o padrão) | sobe com `uwsm start mango.desktop`, junto com o `mango-session.target` (spike) |
| Exige 3D | não (roda com `--soft`) | sim (sem 3D não sobe) | sim (sem GL não sobe) |
| Login automático, autostart da UI | `hl.on("hyprland.start")` | `spawn-sh-at-startup` | `exec_once=` |

Fontes: (pesquisa) páginas dos pacotes no archlinux.org; spike 0 do estudo (`lab/perf`
`2026-10-28T164121`).

### 3.2 Protocolos que a UI e o lab usam

| | Hyprland | Niri | Mango |
|---|---|---|---|
| wlr-layer-shell (barra, pop-ups) | sim | sim | sim |
| wlr-screencopy (`grim`) | sim | sim | sim |
| gerência de saídas (`wlr-randr` / IPC) | `hyprctl` | `niri msg output` | `wlr-randr` |
| lista de janelas (wlr-foreign-toplevel) | sim | sim | sim |
| áreas pelo ext-workspace (`Quickshell.WindowManager`) | só a área atual | sim | sim (as 9 tags) |

Evidência: as ferramentas do lab nos três (`ferramentas.tsv`: 27 `ok`, 3 `pendente: dono` pro
`--window`); o spike da rota genérica (amostra `Q-quickshell-generico` nos três).

### 3.3 IPC

| | Hyprland | Niri | Mango |
|---|---|---|---|
| Lê | `hyprctl -j` (monitors, workspaces, clients, activewindow) | `niri msg --json` (outputs, focused-output, workspaces, windows, focused-window) | `mmsg get` (all-monitors, all-tags, all-clients, focusing-client) |
| Age | `hyprctl dispatch` (Lua) por `address:` em qualquer janela | `niri msg action … --id` em qualquer janela | `mmsg dispatch … client,<id>` em qualquer janela |
| Eventos | socket2 (texto, um evento por linha) | `event-stream` (JSON, estado inicial + deltas) | `mmsg watch …` (JSON, o estado inteiro a cada mudança) |
| Tela cheia | sim | **não** (contorno: foreign-toplevel ou tamanho da janela) | sim |
| Flutuante | sim | sim | sim |
| Geometria | retângulo | coluna/linha na fita | retângulo |

A tabela linha a linha, com a amostra de cada célula, está na seção 6.

### 3.4 `capabilities` propostas

| Campo | Hyprland | Niri | Mango |
|---|---|---|---|
| `workspaceModel` | `numbered` | `dynamic` | `tags` |
| `canFloat` | `true` | `true` | `true` |
| `canMoveToWorkspace` | `true` | `true` | `true` |
| `actsOnAnyWindow` | `true` | `true` | `true` (o contrato da 007 supunha `false`) |
| `hasGeometry` | `rect` | `columns` | `rect` |
| `fullscreenKnown` | `true` | `false` (ou `true` pelo foreign-toplevel) | `true` |

### 3.5 A UI da `main`

| Item | Niri (1080 e hidpi) | Mango (1080 e hidpi) |
|---|---|---|
| Barra | funciona | funciona |
| Abas | **quebra**: 5 abas fixas, todas apagadas, clicar não faz nada | **quebra** (idem) |
| Título | **quebra**: sempre vazio | **quebra** (idem) |
| Relógio | funciona | funciona |
| Bateria | funciona (a VM não tem bateria; a leitura some, como no Hyprland) | funciona |
| Papel de parede | funciona; o screenshot sem a barra é idêntico ao do Mango pixel a pixel | funciona |
| Configurações (`ALT+I`) | funciona (abre no único monitor) | funciona |
| Seletor (`ALT+W`) | funciona | funciona |
| Contraste da barra | funciona (tom e contraste vêm do papel, não do compositor) | funciona |

- **O `import Quickshell.Hyprland`** (o `Compositor.qml` é o único arquivo que importa) não dá erro de
  QML nem laço de reinício. O log ganha um aviso, `$HYPRLAND_INSTANCE_SIGNATURE is unset. Cannot connect
  to hyprland.`, e um aviso por chamada ao `hyprctl` que não existe
  (`Process failed to start … QList("hyprctl", "monitors", "-j")`, a cada evento de monitor;
  `… "activewindow", "-j"` uma vez). Não aparece o `Error making request` que a pesquisa previa.
- **Num `Loader` que não carrega o arquivo com o import:** silêncio total no log, nos dois. Quando o
  arquivo é carregado, só o aviso acima. (Amostra `Q-import-hyprland`.) Isso confirma o desenho do §1
  do contrato da 007: o backend escolhido por um `Loader`.
- **O que a pesquisa previa e se confirmou só em parte:** sem o `hyprctl`, a UI perde a escala por monitor
  e o monitor em foco. Em hidpi as linhas finas continuam nítidas, mas o passo das marcas da barra muda
  ~1 px; os pop-ups abrem porque há um monitor só (com dois, abririam no primeiro, não no que tem o
  foco).
- **Diferença entre os dois:** no Mango o log também tem `Failed to create pipewire context` e um aviso
  do portal. É da camada, não do compositor: a `mango-base` não instalou um `xdg-desktop-portal-*` (nas
  outras duas ele entra e traz o PipeWire junto). A barra mostra o volume 0 nos dois casos na VM.
- **Roteiros da UI** (`check-u1`, `check-003`, `check-004`): rodam inteiros no Hyprland (15/0, 25/0,
  25/0, 58/0) e param no primeiro `hyprctl` no Niri e no Mango (8 PASS antes disso no `check-u1`, com
  fixtures a UI desenha igual).

Screenshots (16): Niri `teste-niri-20261029-104709-niri-1080-barra.png` (ca19f5d8baac9e77),
`…-104711-niri-1080-config.png` (47485b3787d4970c), `…-104715-niri-1080-seletor.png` (bd4bb578cbd75b1f),
`…-104717-niri-1080-papel.png` (fdefd9a7d09dda40), `…-104726-niri-hidpi-barra.png` (722b21d496cc54f8),
`…-104729-niri-hidpi-config.png` (3b57176dc21b644c), `…-104733-niri-hidpi-seletor.png`
(51aa0e1bdb78f5ca), `…-104736-niri-hidpi-papel.png` (151edc2a27862c08); Mango
`teste-mango-20261029-103520-mango-1080-barra.png` (cf723980d7c42d9a), `…-103522-mango-1080-config.png`
(94cadc73d8d2e18c), `…-103526-mango-1080-seletor.png` (7126185bc427c3fe), `…-103528-mango-1080-papel.png`
(fdefd9a7d09dda40), `…-103538-mango-hidpi-barra.png` (e82d8c336144ed7b), `…-103540-mango-hidpi-config.png`
(93f9115f40c1fc90), `…-103544-mango-hidpi-seletor.png` (d8b41cfded0fca59), `…-103547-mango-hidpi-papel.png`
(151edc2a27862c08). Sessões `lab/perf` `2026-10-29T104616` (Niri) e `2026-10-29T103500` (Mango).

### 3.6 Custo medido

Três rodadas por compositor, cada uma numa camada nova (disco igual), uma VM por vez, 4 núcleos e 4 GB,
1080, `--headless`, sem fixtures e sem janela; 120 s parado depois da UI pronta. "Boot até a UI" é o
tempo desde o início do kernel até o HUD responder pelo IPC do Quickshell, medido dentro da VM. Entre
parênteses, a maior diferença entre as rodadas.

| Medida | Hyprland | Niri | Mango |
|---|---|---|---|
| Boot até a UI (s) | 4.55 (±0.31, n=3) | 3.18 (±0.06, n=3) | 3.23 (±0.14, n=3) |
| RAM usada na VM, parada (MB) | 866 (±24.00, n=3) | 566 (±16.00, n=3) | 612 (±3.00, n=3) |
| CPU da VM, parada (% dos 4 núcleos) | 0.98 (±0.32, n=3) | 1.19 (±0.05, n=3) | 1.15 (±0.03, n=3) |
| RSS do qs (MB) | 202 (±2.00, n=3) | 198 (±0.00, n=3) | 203 (±0.00, n=3) |
| CPU do qs (% de 1 núcleo) | 2.35 (±0.97, n=3) | 2.44 (±0.12, n=3) | 2.1 (±0.14, n=3) |
| RSS do compositor (MB) | 232 (±14.00, n=3) | 82 (±0.00, n=3) | 64 (±0.00, n=3) |
| CPU do compositor (% de 1 núcleo) | 0.9 (±0.29, n=3) | 1.82 (±0.27, n=3) | 0.76 (±0.06, n=3) |

**Razão pro Hyprland (mediana):** niri: boot 0.70×, RAM 0.65×, CPU 1.21×; mango: boot 0.71×, RAM 0.71×, CPU 1.17×

- O boot mais longo do Hyprland vem do uwsm (o `qs` começa ~4,2 s depois do kernel, contra ~3,0 s); o
  sistema até o `multi-user` leva ~2,5 s nos três (`systemd-analyze`).
- A RAM a mais do Hyprland é quase toda do processo do compositor (~230 MB, contra 82 e 64 MB).
- A CPU parada é baixa nos três (~1% dos 4 núcleos); a diferença entre eles é menor que a variação do
  Hyprland entre rodadas.
- Sessões `lab/perf` em "Fontes".

### 3.7 Riscos de manutenção

| | Hyprland | Niri | Mango |
|---|---|---|---|
| Cadência | uma versão menor a cada 2–3 meses, com correções no meio | a cada 3–6 meses (a 26.04 já tem 6 meses) | quase semanal (0.17.4 a 0.18.3 em 4 semanas) |
| Quebras recentes | a 0.57 (2026-10-28) muda partes do Lua; a config antiga acabou | config KDL estável; o IPC tem crate versionado (`niri_ipc`) | a 0.18.0 renomeou chaves da config (com script de migração) |
| Quem mantém | equipe grande (hyprwm) | um mantenedor principal e muitos colaboradores | **um autor com ~2.050 commits** (o segundo tem 23), 88 colaboradores |
| Plugins | `hyprpm`; o `hyprexpo` oficial saiu (2026-05); cópias da comunidade | não tem plugins (tudo no núcleo) | não tem plugins |

Fontes: (pesquisa) releases no GitHub de cada projeto; contribuidores pela API do GitHub
(`mangowm/mango`); PR #663 do `hyprland-plugins`.

### 3.8 Critérios de experiência (evidência; a nota é do dono)

| Critério | Hyprland | Hyprland com plugin* | Niri | Mango |
|---|---|---|---|---|
| Visão geral (15) | não existe no puro | `hyprexpo` da comunidade (`sandwichfarm/hyprexpo`, fixado pra 0.56.2): compilou e carregou em ~3,5 min; grade 3x3 das áreas (`hypr-plugins-20261029-115757-hyprexpo-aberto.png`) | nativa (`toggle-overview`); rajada e screenshot | nativa (`toggleoverview`); rajada e screenshot |
| Colunas (15) | layout `scrolling` do núcleo nas áreas 3–5 da sessão; 4 janelas na fita (`teste-hypr-sessao-20261029-115224-hypr-sessao-area3-4janelas.png`), rajada | — | o modelo inteiro; rajada | layout `scroller` (um entre vários); rajada |
| Animações (10) | as quatro animam, curvas longas (350–900 ms aparentes) | — | as quatro animam (250–400 ms) | as quatro animam (335–630 ms) |
| Atalhos e uso diário (20) | 5 atalhos do lab ok; Lua com recarga; a 0.57 mexe no Lua | — | 5 atalhos ok; KDL com recarga e validação; áreas dinâmicas | 5 atalhos ok; texto com recarga e validação; 9 tags fixas |

\* não entra na conta oficial. Notas: em branco até a sessão do dono (folha no laboratório,
`lab/009/sessao/folha.md`).

## 4. Conta

Pontuação = Σ (peso × nota) / 3. Só a parte técnica (máximo 40) por enquanto.

Notas técnicas dadas pelo agente com as âncoras aprovadas (o porquê de cada uma no laboratório,
`lab/009/notas-tecnicas.md`): IPC — Hyprland 3, Niri 2 (sem tela cheia no IPC), Mango 3; risco de
manutenção — Hyprland 2 (a config muda muito entre versões), Niri 3, Mango 1 (um autor, chaves
renomeadas a cada poucas semanas); custo — Hyprland 3 (referência), Niri 2 e Mango 2 (CPU parada 1,2× a
do Hyprland, boot e RAM melhores); empacotamento — 3 nos três.

| Critério (peso) | Hyprland | Niri | Mango |
|---|---|---|---|
| IPC (15) | 3 → 45 | 2 → 30 | 3 → 45 |
| Risco de manutenção (10) | 2 → 20 | 3 → 30 | 1 → 10 |
| Custo (10) | 3 → 30 | 2 → 20 | 2 → 20 |
| Empacotamento (5) | 3 → 15 | 3 → 15 | 3 → 15 |
| **Técnico, pesos aprovados** (Σ/3, de 40) | **36,7** | **31,7** | **30,0** |
| Técnico, pesos iguais (12,5 × Σ notas / 3, de 50) | 45,8 | 41,7 | 37,5 |

Experiência (60): **pendente: notas do dono.** Eliminatórios: nenhum dos três (os três aceitam a barra por
layer-shell, listam áreas e a janela em foco, e instalam do repositório oficial).

## 5. Recomendação

**Pendente: notas do dono.** A regra aprovada (trocar o padrão só com +10 pontos e nota ≥ 2 no IPC e no
risco de manutenção; Hyprland + um deles a até 10 pontos com IPC ≥ 2; senão só Hyprland) só pode ser
aplicada com as quatro notas de experiência.

O que já dá pra ver: na parte técnica o Hyprland lidera (36,7 contra 31,7 e 30,0); pra trocar o padrão,
um candidato precisaria passar o Hyprland por 10 pontos ou mais, ou seja, tirar nas notas de experiência
pelo menos 15 (Niri) ou 16,7 (Mango) pontos a mais que ele. O Mango também não cumpre a condição de
risco de manutenção ≥ 2 pra trocar o padrão (nota 1): no máximo "Hyprland + Mango". O Niri cumpre as
duas condições técnicas (IPC 2, manutenção 3).

## 6. Proposta de mudança no contrato da 007

A tabela §6 do `specs/007-menu-de-pausa/contracts/compositor.md` (commit `fc561cd`) com as colunas do
Niri e do Mango conferidas. Entre colchetes, a amostra (`lab/009/amostras/index.tsv`, repositório privado).

| Precisa de | Hyprland (referência) | Niri 26.04 | Mango (mangowm 0.18.3) |
|---|---|---|---|
| Monitores e escala | `hyprctl -j monitors` [L01] | `niri msg --json outputs` — **confirmada** [niri/L01] | mmsg get all-monitors: width/height lógicos, scale, x/y, tags; wlr-randr --json pros modos — **corrigida** [mango/L01] |
| Monitor em foco | `hyprctl -j monitors (focused)` [L02] | `niri msg --json focused-output` — **confirmada** [niri/L02] | não há 'focused': 'active' + o monitor do cursorpos; com uma saída só não dá pra provar (S3) — **corrigida** [mango/L02] |
| Áreas de trabalho | `hyprctl -j workspaces` [L03] | `niri msg --json workspaces` — **confirmada** [niri/L03] | mmsg get all-tags (index, is_active, client_count, layout) por saída; 9 tags fixas — **corrigida** [mango/L03] |
| Janelas | `hyprctl -j clients` [L04] | `niri msg --json windows` — **confirmada** [niri/L04] | mmsg get all-clients já traz id, appid, title, tags, monitor, is_floating, is_fullscreen, is_focused, x/y/width/height (sem foreign-toplevel) — **corrigida** [mango/L04] |
| Janela ativa e tela cheia | `hyprctl -j activewindow; hl.dsp.window.fullscreen` [L05] | título ok; tela cheia sem campo: layout.window_size == outputs[].logical (inferência) ou o Toplevel.fullscreen do ToplevelManager — **corrigida** [niri/L05] | mmsg get focusing-client: título e is_fullscreen — **corrigida** [mango/L05] |
| Eventos | `socket2 ($XDG_RUNTIME_DIR/hypr/<sig>/.socket2.sock), 10 s` [L06] | `niri msg --json event-stream, 10 s` — **confirmada** [niri/L06] | mmsg watch all-clients\|all-tags\|focusing-client: o estado inteiro a cada mudança (não um delta) — **corrigida** [mango/L06] |
| Ir pra área | `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'` [L07] | `niri msg action focus-workspace 2` — **confirmada** [niri/L07] | mmsg dispatch view,<tag> (não -d) — **corrigida** [mango/L07] |
| Focar janela | `hyprctl dispatch 'hl.dsp.focus({ window = "address:…" })'` [L08] | `niri msg action focus-window --id <id>` — **confirmada** [niri/L08] | focusid client,<id> foca qualquer janela (também em outra tag, que passa a ser a vista) — **corrigida** [mango/L08] |
| Mover, flutuar, fechar | `hl.dsp.window.move/float/close({ window = "address:…" })` [L09] | mover usa --window-id (não --id) e --focus false pra não seguir a janela; as três agem fora de foco — **corrigida** [niri/L09] | as três agem fora de foco com client,<id>; tag,<n> (sem silent) leva a vista e o foco junto — **corrigida** [mango/L09] |
| Modelo | `hl.dsp.focus({ workspace = 7 })` [L10] | `niri msg action focus-workspace 9` — **confirmada** [niri/L10] | `mmsg dispatch view,7; view,12; toggleview,2` — **confirmada** [mango/L10] |

Perguntas extras:

| Pergunta | Compositor | Estado | Resposta |
|---|---|---|---|
| Q-niri-tela-cheia | niri | nao-existe | inferir por window_size == tamanho lógico da saída, ou ToplevelManager (Q-quickshell-generico) |
| Q-niri-flutuante | niri | confirmada | is_floating existe e muda; flutuante tem layout.pos_in_scrolling_layout null |
| Q-niri-coluna | niri | confirmada | layout.pos_in_scrolling_layout = [coluna, linha], tile_size por janela |
| Q-deteccao | niri | confirmada | NIRI_SOCKET; XDG_CURRENT_DESKTOP=niri |
| Q-import-hyprland | niri | confirmada | o Loader que não carrega o arquivo com o import fica em silêncio; carregado, só o aviso HYPRLAND_INSTANCE_SIGNATURE |
| Q-quickshell-generico | niri | confirmada | áreas (ext-workspace) e janelas com fullscreen (foreign-toplevel) |
| Q-mango-acao-fora-de-foco | mango | corrigida | age em qualquer janela por client,<id> (a hipótese 'só a em foco' estava errada) |
| Q-mango-tag-por-janela | mango | confirmada | campo tags (lista) em cada cliente |
| Q-mango-eventos | mango | confirmada | 13 linhas em 10 s em cada fluxo; JSON por linha |
| Q-deteccao | mango | confirmada | XDG_CURRENT_DESKTOP=mango; também MANGO_INSTANCE_SIGNATURE (caminho do socket), mais específico |
| Q-import-hyprland | mango | confirmada | igual ao Niri |
| Q-quickshell-generico | mango | confirmada | 9 tags como windowsets (shouldDisplay só na ativa); toplevels com fullscreen |
| Q-escala-por-monitor | niri | pesquisa | S3 impossível na VM ('Output "Virtual-2" is not connected'); escala fracionária por saída documentada (wiki Outputs); a S2 prova 1,25 numa saída (niri/L01) |
| Q-escala-por-monitor | mango | pesquisa | S3 impossível na VM ('unknown output Virtual-2'); a S2 prova 1,25 numa saída (mango/L01-monitores-S2.txt); o foco por monitor só pelo cursorpos |

**Regra de detecção do §1:** confirmada. Pro Mango, usar `MANGO_INSTANCE_SIGNATURE` (o caminho do socket
do IPC, sempre definido na sessão) em vez de procurar "mango" no `XDG_CURRENT_DESKTOP` (que também vale).
Ordem proposta: `NIER_COMPOSITOR` → `HYPRLAND_INSTANCE_SIGNATURE` → `NIRI_SOCKET` →
`MANGO_INSTANCE_SIGNATURE` → `NullBackend`.

**O risco do `import Quickshell.Hyprland`** (§1, "a confirmar"): resolvido. Dentro de um `Loader` que não
carrega o arquivo, não custa nada no log.

**`capabilities`:** as da seção 3.4. A mudança que importa: Mango com `actsOnAnyWindow: true` (as ações
por `client,<id>` valem em qualquer janela) e `fullscreenKnown: true`; Niri com `fullscreenKnown: false`.

## 7. O que fica pra S5

- **`NiriBackend`:** `niri msg --json` pra ler e `niri msg action` pra agir; o `event-stream` pra
  reatividade (atualizações nem sempre atômicas: juntar por um tique). Tela cheia pelo `ToplevelManager`
  do Quickshell (o foreign-toplevel informa) ou pela inferência de tamanho. O mapa da aba WINDOWS pode
  desenhar as colunas de verdade (`pos_in_scrolling_layout`).
- **`MangoBackend`:** `mmsg get` / `dispatch … client,<id>` / `watch`. As tags são fixas (9) e uma janela
  pode estar em várias; a barra mostra as 5 primeiras como hoje. O `watch` manda o estado inteiro a cada
  mudança: comparar antes de redesenhar.
- **Rota genérica:** o `Quickshell.WindowManager` (ext-workspace) e o `ToplevelManager` funcionam no Niri
  e no Mango (no Hyprland, só a área atual): um backend genérico de leitura é possível, com o IPC de cada
  um só pras ações.
- **A fachada precisa esconder:** o modelo de áreas (número, dinâmico, tags), a forma de agir numa janela
  (address, id, client) e a tela cheia do Niri. Também tirar o `hyprctl` do `Compositor.qml` (escala por
  monitor e monitor em foco): a escala pode vir do Quickshell (`screen`) e o monitor em foco do backend.
- **Roteiros do lab:** os `check-*` precisam de um `case` por compositor pra trocar de área e ler monitor.
- **Riscos:** a cadência semanal e o autor único do Mango; a falta de tela cheia no IPC do Niri; a 0.57 do
  Hyprland (Lua) ainda não testada no lab (tarefa à parte).

## 8. Fontes

Pesquisa (consultadas em 2026-10-28 e 2026-10-29):
- Pacotes: https://archlinux.org/packages/extra/x86_64/hyprland/ ;
  https://archlinux.org/packages/extra/x86_64/niri/ ; https://archlinux.org/packages/extra/x86_64/mangowm/
- Arch Linux Archive: https://archive.archlinux.org/repos/2026/10/28/
- Hyprland: https://github.com/hyprwm/Hyprland/releases/tag/v0.57.0 ; https://hypr.land/news/update54 ;
  https://wiki.hypr.land/0.56.0/Configuring/Layouts/Scrolling-Layout/ ;
  https://github.com/hyprwm/hyprland-plugins/pull/663 ; https://github.com/sandwichfarm/hyprexpo
- Niri: https://niri-wm.github.io/niri/IPC.html ; https://niri-wm.github.io/niri/Gestures.html ;
  https://api.github.com/repos/niri-wm/niri/releases ;
  https://niri-wm.github.io/niri/niri_ipc/struct.WindowLayout.html
- Mango: https://mangowm.github.io/docs/ipc ; https://api.github.com/repos/mangowm/mango/releases ;
  https://api.github.com/repos/mangowm/mango/contributors ;
  https://mangowm.github.io/docs/window-management/layouts
- Quickshell: https://quickshell.org/changelog ;
  https://github.com/quickshell-mirror/quickshell/blob/master/src/wayland/hyprland/ipc/connection.cpp

Laboratório (repositório privado; ids do `lab/perf`):
- Fase 0 do Hyprland: `2026-10-29T102845` (u1 15/0, 003 25/0 e 25/0, 004 58/0).
- Ferramentas: `2026-10-29T104914` (Hyprland), `2026-10-28T165751` (Niri), `2026-10-29T102908` (Mango).
- UI: `2026-10-29T104616` (Niri), `2026-10-29T103500` (Mango).
- Amostras: `2026-10-29T105028` (Hyprland), `2026-10-28T170453` (Niri), `2026-10-29T103745` (Mango);
  spikes `2026-10-28T170155` (Niri), `2026-10-29T103623` (Mango).
- Rajadas: `2026-10-29T105203` e `…115137` (Hyprland), `2026-10-29T105333` e `…105524` (Niri), `2026-10-29T103931`, `…120124`,
  `…104232`, `…104322`, `…104405` (Mango).
- Roteiros informativos: `2026-10-29T105600` (Niri), `2026-10-29T104446` (Mango).
- Custo: Hyprland `2026-10-29T112004`, `…113005`, `…114007`; Niri `2026-10-29T112403`, `…113405`,
  `…114407`; Mango `2026-10-29T112704`, `…113705`, `…114707` (rodadas anteriores com a sonda da UI
  quebrada, descartadas: `…105934`, `…110315`, `…110943`).
- Sessão do Hyprland com colunas: `2026-10-29T115137`; Hyprland com plugin: `2026-10-29T115341`.
- Spikes: uwsm `2026-10-29T115130` (Niri) e `…115345` (Mango); duas saídas `2026-10-29T115720`,
  `…115805`, `…115950`; spike 0 (3D) `2026-10-28T164121`.
