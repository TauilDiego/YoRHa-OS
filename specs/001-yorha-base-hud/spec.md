# Feature Specification: Base visual YoRHa e HUD

**Feature Branch**: `001-yorha-base-hud`

**Created**: 2026-10-26

**Status**: Draft (clarificações resolvidas)

**Input**: User description: "U1 — Base visual: design system YoRHa (inspirado na UI de NieR:Automata) e o HUD (barra do topo) da UI rien-OS, rodando no Quickshell dentro da VM do laboratório. Design system: paleta papel/tinta (#D1CDB7 fundo, #BAB5A1 fraco, #DCD8C0 claro, #454138 tinta, um vermelho só pra alerta), grid fino no fundo, quadrado como marcador, item de menu que pinta da esquerda pra direita com trilhos acima/abaixo e sombra deslocada, cursor que balança, títulos em caixa alta com sombra, painel com faixa de cabeçalho escura, medidor estilo barra de HP, linha dupla. HUD: barra no topo com workspaces como abas do menu de pausa (01, 02...; ativo invertido, vazios apagados, clique troca), telemetria CPU/MEM/VOL/BAT com medidores, relógio e data, título da janela ativa. Os dados vêm de serviços que aceitam fixtures (relógio fixo, bateria 87%, etc.) pra screenshots determinísticos. Sem blur. Verificação por screenshot no lab."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver o estado do sistema numa barra com cara de NieR (Priority: P1)

Ao entrar na sessão, o usuário vê no topo da tela uma barra no estilo da interface dos androides
YoRHa: papel bege com um grid fino, tinta escura e uma linha dupla embaixo. De um relance, a barra
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
   **Then** o título aparece no centro, cortado com reticências se não couber.
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
- item de menu: normal, destacado, selecionado e apagado;
- painel com cabeçalho;
- título grande;
- medidor (normal e crítico);
- cursor balançando;
- marcador quadrado;
- linha dupla;
- fundo com grid.

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

### Edge Cases

- **Sem bateria** (desktop ou VM sem bateria): a leitura de bateria some, em vez de mostrar 0%.
- **Bateria baixa:** abaixo de 15% e sem carregar, a leitura de bateria fica vermelha.
  Carregando, ela mostra um indicador de carga.
- **Áudio mudo:** a leitura de volume indica que está mudo e mostra o medidor vazio.
- **Mais de 5 workspaces existentes:** a barra mostra abas até o maior workspace existente ou em
  foco. Workspaces especiais ou com número negativo não aparecem.
- **Nenhuma janela ativa:** a área do título fica vazia, sem texto de erro.
- **Título muito longo:** é cortado com reticências e nunca empurra as outras áreas.
- **Fonte original do jogo ausente:** a UI usa uma fonte aberta substituta sem quebrar o layout.
  Se o usuário tiver a fonte original instalada, ela é usada.
- **Dados de sistema indisponíveis** (ex.: leitura de CPU falha): o medidor fica em 0 e a UI não
  trava nem mostra erro.
- **Mais de um monitor:** cada monitor tem a sua barra, mostrando o workspace em foco daquele
  monitor.

## Requirements *(mandatory)*

### Functional Requirements

**Design system**

- **FR-001**: A UI MUST usar uma paleta única com estas cores:

  | Papel | Cor |
  |---|---|
  | Fundo | `#D1CDB7` |
  | Grid | Um tom levemente mais escuro que o fundo |
  | Fraco | `#BAB5A1` |
  | Claro | `#DCD8C0` |
  | Tinta | `#454138` |
  | Tinta secundária | Mais clara que a tinta |
  | Alerta | Um vermelho, a única cor fora da paleta sépia, usado só pra estados críticos |
- **FR-002**: Superfícies de fundo MUST mostrar um grid fino e regular, com linhas nítidas em
  qualquer escala de tela.
- **FR-003**: O design system MUST oferecer estas peças reutilizáveis:
  - marcador quadrado;
  - texto com a tipografia do sistema;
  - item de menu;
  - cursor;
  - título grande;
  - painel com cabeçalho;
  - medidor;
  - linha dupla;
  - fundo com grid.
- **FR-004**: O item de menu MUST ter os estados normal, destacado (ao passar o mouse ou com o
  cursor do teclado), selecionado (persistente) e apagado. Ao destacar:
  - a tinta pinta o item da esquerda pra direita;
  - o texto inverte de cor;
  - aparecem trilhos finos acima e abaixo;
  - aparece uma sombra deslocada.

  A transição dura em torno de 0,2 s.
- **FR-005**: O cursor de seleção MUST balançar lateralmente de forma contínua e suave enquanto
  está visível.
- **FR-006**: Títulos grandes MUST aparecer em caixa alta, com espaçamento largo entre letras e
  uma sombra deslocada no tom fraco.
- **FR-007**: O medidor MUST ter contorno, preencher na proporção do valor (0 a 100%), animar
  quando o valor muda e ficar vermelho no estado crítico.
- **FR-008**: Nenhuma peça MUST usar desfoque (blur) nem transparência sobre o desktop.

**HUD**

- **FR-009**: O HUD MUST ocupar uma faixa no topo de cada monitor e reservar o espaço dela, pra
  que as janelas não fiquem por baixo.
- **FR-010**: O HUD MUST mostrar, da esquerda pra direita:
  1. a marca do sistema;
  2. as abas de workspace;
  3. o título da janela ativa (centralizado);
  4. as leituras de CPU, memória, volume e bateria;
  5. a data e a hora.
- **FR-011**: As abas MUST mostrar números com dois dígitos (01, 02…), de 1 até o maior entre 5,
  o maior workspace existente e o workspace em foco, nestes estados:
  - **em foco:** invertida;
  - **existente:** normal;
  - **inexistente:** apagada.
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

## Assumptions

- **Onde roda:** a UI roda só na VM do laboratório (constituição, princípio I). A troca no
  sistema do dono é a fase U7.
- **Compositor:** só o Hyprland neste U1. O Niri fica pra S5, mas a leitura de workspaces e da
  janela ativa fica isolada pra facilitar a troca depois.
- **Fonte:** a fonte original (FOT-Rodin) não é distribuída. O padrão é uma fonte aberta, e a
  original é usada se o usuário a tiver instalado.
- **Referência de tela:** 1920x1080 em escala 1 (a VM). A UI precisa funcionar também em
  telas maiores com escala fracionária (por exemplo 2560x1600 em 1,25), mas isso só é conferido
  na homologação.
- **Fora do escopo do U1:**
  - painéis que abrem ao clicar na telemetria;
  - controle de volume pela barra;
  - bandeja do sistema (tray);
  - menu de pausa, notificações, OSD e lock (fases seguintes);
  - otimização de desempenho (U6).
- **Sem desempenho:** o U1 não mede desempenho. Vale só a regra de não usar blur.
- **Paleta:** a referência é o projeto comunitário `metakirby5/yorha`, não uma especificação
  oficial do jogo.
