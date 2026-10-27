# Feature Specification: Base visual YoRHa e HUD

**Feature Branch**: `001-yorha-base-hud`

**Created**: 2026-10-26

**Status**: Aprovada pelo dono em 2026-10-27 (alinhada com o design system em `docs/design-system.md`)

**Input**: User description: "U1 — Base visual: design system YoRHa (inspirado na UI de NieR:Automata) e o HUD (barra do topo) da UI rien-OS, rodando no Quickshell dentro da VM do laboratório. Design system: paleta papel/tinta (#D1CDB7 fundo, #BAB5A1 fraco, #DCD8C0 claro, #454138 tinta, um vermelho só pra alerta), grid fino no fundo, quadrado como marcador, item de menu que pinta da esquerda pra direita com trilhos acima/abaixo e sombra deslocada, cursor que balança, títulos em caixa alta com sombra, painel com faixa de cabeçalho escura, medidor estilo barra de HP, linha dupla. HUD: barra no topo com workspaces como abas do menu de pausa (01, 02...; ativo invertido, vazios apagados, clique troca), telemetria CPU/MEM/VOL/BAT com medidores, relógio e data, título da janela ativa. Os dados vêm de serviços que aceitam fixtures (relógio fixo, bateria 87%, etc.) pra screenshots determinísticos. Sem blur. Verificação por screenshot no lab."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver o estado do sistema numa barra com cara de NieR (Priority: P1)

Ao entrar na sessão, o usuário vê no topo da tela uma barra no estilo da interface dos androides
YoRHa: papel bege com um grid fino, tinta escura e uma régua pontilhada embaixo. De um relance, a barra
mostra:
- em qual workspace ele está e quais workspaces têm janelas;
- o título da janela ativa;
- a carga de CPU e memória, o volume e a bateria, cada um com um medidor no estilo da barra de
  vida do jogo;
- a data e a hora.

**Why this priority**: É a primeira peça da UI que o usuário vê o tempo todo, e a que prova que a
estética funciona num desktop de verdade. Sozinha, ela já substitui a barra de outro shell.

**Independent Test**: Ligar a VM do laboratório com a UI e dados de teste, tirar um screenshot e
conferir que todos os elementos aparecem com a aparência descrita.

**Acceptance Scenarios**:

1. **Given** uma sessão com 3 workspaces existentes e o 2 em foco, **When** a barra aparece,
   **Then** as abas 01–05 aparecem; a 02 aparece invertida (fundo escuro, texto claro); a 01 e a
   03 aparecem normais; a 04 e a 05 aparecem apagadas.
2. **Given** dados de teste com bateria em 87%, volume em 64%, CPU em 23% e memória em 41%,
   **When** a barra aparece, **Then** cada leitura mostra o rótulo, um medidor preenchido na
   proporção certa e o número.
3. **Given** uma janela ativa com o título "kitty — ~/projetos", **When** a barra aparece,
   **Then** o título aparece no centro, cortado com reticências se não couber. O título é dado do
   usuário e aparece como vier; os textos fixos da UI continuam em inglês (FR-018).
4. **Given** o relógio de teste fixo em 2026-10-26 13:37:00, **When** a barra aparece,
   **Then** ela mostra "2026.10.26" e "13:37:00".

---

### User Story 2 - Trocar de workspace pela barra (Priority: P2)

O usuário clica numa aba de workspace e o desktop vai pra ele. A aba clicada passa a aparecer
invertida, com a animação de "tinta pintando da esquerda pra direita".

**Why this priority**: Transforma a barra de só leitura em ferramenta, e é a primeira interação
que mostra a animação característica dos menus do jogo.

**Independent Test**: Na VM, clicar numa aba (ou simular o clique) e conferir por screenshot que o
workspace mudou e que a aba nova está destacada.

**Acceptance Scenarios**:

1. **Given** o workspace 1 em foco, **When** o usuário clica na aba 03, **Then** o desktop vai pro
   workspace 3 e a aba 03 fica invertida em até meio segundo.
2. **Given** o cursor do mouse sobre uma aba que não está ativa, **When** o usuário passa o mouse
   por cima, **Then** a aba mostra o estado de destaque (tinta pintando, trilhos acima e abaixo,
   sombra deslocada) e volta ao normal quando o mouse sai.

---

### User Story 3 - Galeria do design system (Priority: P3)

O dono do projeto (e os agentes que vão construir as próximas telas) abre uma tela de galeria com
todas as peças do design system lado a lado, cada uma nos seus estados:
- primitivas: marcador quadrado, réguas (lisa, pontilhada e vertical), fundo com grid;
- botão-aba e item de lista: normal, destacado, selecionado e apagado;
- seletor (claro e escuro);
- medidor (normal e crítico);
- título de página;
- card;
- compostos: barra de abas e lista com cursor.

**Why this priority**: As próximas fases (menu de pausa, notificações, lock) são construídas com
essas peças. Ver todas juntas evita que cada tela reinvente o visual e serve de referência pra
revisão. A galeria não é usada no dia a dia do usuário final.

**Independent Test**: Abrir a galeria na VM por comando, tirar um screenshot e conferir que cada
peça e cada estado aparecem.

**Acceptance Scenarios**:

1. **Given** a UI rodando na VM, **When** a galeria é aberta por comando, **Then** ela ocupa a
   tela e mostra todas as peças listadas, cada uma com o nome escrito ao lado.
2. **Given** a galeria aberta, **When** o comando de fechar é enviado (ou Esc é pressionado),
   **Then** ela some e o desktop volta ao normal.

---

### User Story 4 - Fundo da área de trabalho (Priority: P4)

No lugar do wallpaper, a área de trabalho inteira mostra o papel dos menus do jogo: bege com o
grid fino, a vinheta nas bordas e, bem apagados, arcos de círculo grandes e feixes de linhas
diagonais, que se movem muito devagar.

**Why this priority**: Completa a imersão: com janelas fechadas, a tela inteira parece um menu
YoRHa. Pedido do dono depois de ver a UI rodando (2026-10-27).

**Independent Test**: Num workspace sem janelas, tirar um screenshot na VM e conferir o fundo;
com dados de teste, dois screenshots seguidos saem iguais.

**Acceptance Scenarios**:

1. **Given** um workspace vazio, **When** a sessão está aberta, **Then** o fundo mostra papel,
   grid, vinheta, arcos e feixes diagonais em todos os monitores, nítidos em qualquer escala.
2. **Given** `wallpaperMotion: false` no `shell.json` (ou dados de teste ativos), **When** o
   tempo passa, **Then** o fundo fica parado.

---

### Edge Cases

- **Sem bateria** (desktop ou VM sem bateria): a leitura de bateria some, em vez de mostrar 0%.
- **Bateria baixa:** abaixo de 15% e sem carregar, a leitura de bateria fica vermelha.
  Carregando, ela mostra um indicador de carga.
- **Áudio mudo:** a leitura de volume indica que está mudo e mostra o medidor vazio.
- **Mais de 5 workspaces existentes:** a barra mostra abas até o maior workspace existente ou em
  foco. Workspaces especiais ou com número negativo não aparecem.
- **Nenhuma janela ativa:** a área do título fica vazia, sem texto de erro.
- **Título muito longo:** é cortado com reticências e nunca empurra as outras áreas.
- **Fonte original do jogo ausente:** a UI usa a M PLUS 1 sem quebrar o layout. Se o usuário
  tiver a original instalada (FOT-Rodin ProN, Helvetica Now Micro), ela é usada.
- **Dados de sistema indisponíveis** (ex.: leitura de CPU falha): o medidor fica em 0 e a UI não
  trava nem mostra erro.
- **Mais de um monitor:** cada monitor tem a sua barra, mostrando o workspace em foco daquele
  monitor.
- **Monitores com escalas diferentes** (ex.: 1920x1080 @1 ao lado de 2560x1600 @1,25): a barra
  tem a mesma altura lógica nos dois, e as linhas finas continuam nítidas.

## Requirements *(mandatory)*

### Functional Requirements

**Design system**

- **FR-001**: A UI MUST usar só os tokens de cor do design system (`docs/design-system.md` §1,
  tirados do Figma de tyleo):

  | Token | Cor | Papel |
  |---|---|---|
  | `dark-gray` | `#4E4B42` | Tinta: texto, item selecionado, cabeçalho de card |
  | `medium-gray` | `#676458` | Tinta secundária |
  | `light-gray` | `#B1AB93` | Aba/botão em repouso, medidor, faixas |
  | `dark-yellow` | `#C9C5AB` | Fundo (papel) |
  | `light-yellow` | `#D7D1B3` | Corpo de card, texto invertido |
  | `box-shadow` | `#7C7E6C` a 69% | Sombra de caixa |
  | `text-shadow` | `#7E7E74` a 57% | Sombra de título |
  | `grid` | `#4E4B42` a 6% | Grid do fundo |
  | `alert` | `#8F3A30` | Só estados críticos; a única cor fora da sépia |
- **FR-002**: Superfícies de fundo MUST mostrar um grid fino e regular, com linhas nítidas em
  qualquer escala de tela.
- **FR-002a**: Superfícies de tela cheia (a galeria e os menus futuros) MUST ter a vinheta do jogo:
  as bordas escurecem até ≈`#A6A18D` e os cantos até ≈`#8B8877`. A vinheta MUST poder ser
  desligada. O papel do HUD entra na vinheta do fundo, contínua com ele, sem emenda; abas, régua
  e textos ficam por cima, sem vinheta (decisão do dono em 2026-10-27: a vinheta pega a tela
  inteira, mas não as janelas).
- **FR-003**: O design system MUST oferecer estas peças reutilizáveis, em camadas (cada camada
  só usa as de baixo), com os nomes de `docs/design-system.md`:
  - **tokens:** cores, tipografia, sombras, espaçamentos, durações de animação;
  - **primitivas:** texto, marcador quadrado, régua (lisa, pontilhada e vertical), fundo com grid;
  - **base:** botão-aba, item de lista, seletor (variantes clara e escura), medidor, título de
    página, card;
  - **compostos:** barra de abas e lista com cursor.
- **FR-004**: O botão-aba e o item de lista MUST ter os estados normal, destacado (ao passar o mouse ou com o
  cursor do teclado), selecionado (persistente) e apagado. Ao destacar:
  - a tinta pinta o item da esquerda pra direita;
  - o texto inverte de cor;
  - aparecem trilhos finos acima e abaixo;
  - aparece uma sombra deslocada.

  A duração da transição é um token, começando em 0,15 s (a análise do jogo estima ≈100–150 ms);
  o valor final é calibrado depois.
- **FR-005**: O cursor de seleção MUST ser a pipa (seletor) + 2 quadradinhos empilhados entre a
  ponta dela e o item. Ele fica parado, como no jogo; ao trocar de item, MUST piscar: some do
  item antigo e reaparece no novo, com ease in-out, em `motion.blink` (≈240 ms no total; pedido do
  dono em 2026-10-27). Ele aparece no item de lista destacado e no selecionado; as abas não têm seletor
  (decisão do dono em 2026-10-27).
- **FR-006**: Títulos de página MUST aparecer em caixa alta, com espaçamento largo entre letras
  e a sombra `text-shadow` chapada, deslocada pra baixo e pra direita em ≈15% do tamanho do
  texto.
- **FR-007**: O medidor MUST ser uma barra chapada sem borda (o `hp-bar` do Figma): trilho
  `light-gray`, preenchimento em tinta na proporção do valor (0 a 100%), animação quando o valor
  muda e preenchimento `alert` no estado crítico. É o mesmo medidor nos menus e no HUD.
- **FR-008**: Nenhuma peça MUST usar desfoque (blur) nem transparência sobre o desktop.
- **FR-008a**: A tipografia MUST usar a M PLUS 1 (OFL) por padrão, com pesos mais fortes nos
  títulos. Se FOT-Rodin ProN ou Helvetica Now Micro estiverem instaladas, MUST usá-las nos
  papéis delas, sem mudar o layout.
- **FR-008b**: Todas as medidas MUST estar em pixels lógicos, sem cálculo de DPI: os tokens guardam
  as medidas do jogo a 1080p, e cada tela multiplica por um fator `s` (no HUD, `alturaDaAba/47`)
  e por um `uiScale` do usuário (padrão 1). Linhas finas arredondam pra pixel inteiro, com
  mínimo de 1px.

**HUD**

- **FR-009**: O HUD MUST ocupar uma faixa no topo de cada monitor e reservar o espaço dela, pra
  que as janelas não fiquem por baixo. A faixa MUST ter 68px lógicos por padrão (aba de 33px),
  configurável entre 28 e 96px, com a barra de abas do jogo, um vão visível entre as abas e a
  régua pontilhada embaixo, na escala do jogo (revisado pelo dono em 2026-10-27: era 40px, com
  vão de ≈2px e régua bem menor).
- **FR-010**: O HUD MUST mostrar, da esquerda pra direita:
  1. a marca do sistema: as duas faixas verticais do jogo, sem nome nem logo (o nome rien-OS
     aparece só na galeria e nos menus);
  2. as abas de workspace;
  3. o título da janela ativa (centralizado);
  4. as leituras de CPU, memória, volume e bateria;
  5. a data e a hora.
- **FR-011**: As abas MUST mostrar números com dois dígitos (01, 02…), de 1 até o maior entre 5,
  o maior workspace existente e o workspace em foco, nestes estados:
  - **em foco:** invertida, descendo até a régua de baixo e se fundindo com ela. A descida é
    animada: logo depois da tinta, uma haste desce até a régua (`motion.touch`), e recolhe
    quando a aba perde o foco (`motion.untouch`). Com dados de teste, é instantâneo;
  - **existente:** normal;
  - **inexistente:** apagada.

  As abas ficam lado a lado e **não** têm seletor, nem no HUD nem nos menus (decisão do dono em
  2026-10-27); o destaque ao passar o mouse continua.
- **FR-012**: Clicar numa aba MUST levar o desktop pra aquele workspace.
- **FR-013**: Cada leitura de telemetria MUST mostrar o rótulo, um medidor e o valor numérico
  inteiro, e se atualizar sozinha:
  - CPU e memória a cada 2 s no máximo;
  - volume e bateria quando mudarem.
- **FR-014**: O relógio MUST mostrar segundos e a data no formato ano.mês.dia, atualizando a cada
  segundo.

**Dados de teste e verificação**

- **FR-015**: Todo dado que a UI lê do sistema MUST poder ser substituído por dados de teste
  fixos:
  - hora;
  - CPU e memória;
  - volume;
  - bateria;
  - workspaces;
  - janela ativa.

  Assim, dois screenshots da mesma tela saem idênticos.
- **FR-016**: A galeria do design system MUST poder ser aberta e fechada por comando, sem teclado
  nem mouse, pra os testes automáticos.
- **FR-017**: A UI MUST carregar sem nenhum erro ou aviso de carregamento no log da sessão da VM.
- **FR-018**: Todo texto fixo da UI (rótulos do HUD, nomes na galeria, títulos) MUST estar em
  inglês, no estilo do jogo: `CPU`, `MEM`, `VOL`, `BAT`, `SYSTEM`. Não há troca de idioma no U1; a
  internacionalização (i18n) vem numa fase futura. Por isso os textos fixos ficam reunidos num
  lugar só, e não espalhados pelas telas.

**Fundo da área de trabalho**

- **FR-019**: Cada monitor MUST ter um fundo desenhado na camada de fundo do Wayland (atrás de
  todas as janelas), com papel, grid, vinheta, arcos de círculo e feixes de linhas diagonais.
  Nada de imagem: o fundo é desenhado e fica nítido em qualquer resolução e escala.
- **FR-020**: Os arcos e os feixes MUST se mover de forma sutil e contínua (uma volta a cada
  vários minutos), sem redesenhar a cena a cada quadro. O movimento MUST poder ser desligado
  (`wallpaperMotion` no `shell.json`) e MUST parar quando há dados de teste.
- **FR-021**: A vinheta do fundo MUST seguir a configuração `vignette`.

### Key Entities

- **Paleta/tokens:** o conjunto nomeado de cores, tamanhos de texto, espaçamentos e durações de
  animação que todas as peças usam. Muda num lugar só.
- **Leitura de telemetria:** rótulo, valor de 0 a 100%, estado crítico (sim/não) e estado extra
  (carregando, mudo).
- **Workspace:** número, se existe, se está em foco, monitor.
- **Fonte de dados:** sistema real ou dados de teste fixos. Quem decide é o ambiente; a UI não
  muda por causa disso.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Com os dados de teste, um screenshot do HUD na VM mostra todos os elementos dos
  cenários da História 1, conferidos item a item.
- **SC-002**: Dois screenshots seguidos do HUD com dados de teste são idênticos pixel a pixel.
- **SC-003**: Clicar numa aba troca o workspace e destaca a aba em até 0,5 s.
- **SC-004**: A galeria mostra 100% das peças do FR-003 e todos os estados do FR-004, cada um
  identificado pelo nome.
- **SC-005**: O log da sessão na VM tem zero erros e zero avisos de carregamento da UI.
- **SC-006**: O dono do projeto, olhando os screenshots, reconhece a estética YoRHa e aprova sem
  pedir mudanças estruturais: no máximo ajustes de cor, tamanho ou espaçamento.
- **SC-007**: Uma mudança num arquivo da UI aparece na VM em até 3 s, com a recarga ao vivo do
  laboratório.
- **SC-008**: Na VM, nos perfis 1920x1080 @1 e 2560x1600 @1,25, a barra mede a altura padrão em px lógicos (68) e o
  grid e as réguas aparecem nítidos (sem borrado de meio pixel) nos screenshots.

- **SC-009**: Num workspace vazio, o screenshot mostra o fundo (papel e grid no centro da tela);
  com dados de teste, dois screenshots seguidos são idênticos.
- **SC-010**: O custo do fundo com e sem movimento fica registrado no `lab/perf` (sem meta no
  U1: otimizar é da U6).

## Assumptions

- **Onde roda:** a UI roda só na VM do laboratório (constituição, princípio I). A troca no
  sistema do dono é a fase U7.
- **Compositor:** só o Hyprland neste U1. O Niri fica pra S5, mas a leitura de workspaces e da
  janela ativa fica isolada pra facilitar a troca depois.
- **Fonte:** as originais (FOT-Rodin, Helvetica Now Micro) não são distribuídas. O padrão é a
  M PLUS 1, e as originais são usadas se o usuário as tiver instalado.
- **Referência de tela:** 1920x1080 em escala 1 e 2560x1600 em escala 1,25 (2048x1280
  lógicos), os dois monitores do dono. Os dois perfis são conferidos na VM.
- **Fora do escopo do U1:**
  - painéis que abrem ao clicar na telemetria;
  - controle de volume pela barra;
  - bandeja do sistema (tray);
  - menu de pausa, notificações, OSD e lock (fases seguintes);
  - otimização de desempenho (U6).
- **Desempenho:** o U1 não otimiza a UI (isso fica pra U6). Vale só a regra de não usar blur. O
  custo de cada teste na máquina do dono é medido sempre, pelo `lab/perf` do ambiente privado.
- **Paleta e anatomia:** a referência é o Figma "NieR: Automata - UI" de tyleo (CC BY 4.0,
  crédito em `CREDITS.md`), com correções vindas da observação dos menus do jogo
  (`docs/design-system.md` §6). Não é uma especificação oficial.
