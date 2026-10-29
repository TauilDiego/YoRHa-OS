# Feature Specification: Menu de pausa

**Feature Branch**: `007-menu-de-pausa` (sai da `004-wallpaper-system`, que já tem a 003 mesclada:
o menu reusa a moldura de popup da 003 e o layout lista + prévia + opções da 004)

**Created**: 2026-10-27

**Status**: Decisões do dono aplicadas (2026-10-27); plano e tarefas aguardando a aprovação dele

**Input**: Fase U3 do `PLAN.md` (§9): "U3 Menu de pausa | Launcher, janelas, energia | Screenshot de
cada aba". O §7 diz que a UI NieR põe "menu de pausa no lugar do launcher". As abas são as do
cabeçalho do mockup aprovado das configurações (`YoRHa-OS-private/lab/mockups/configuracoes/`):
**APPS**, **WINDOWS**, **SYSTEM** e **POWER**. Sobre a tela, o dono disse, na 003: "eu pensei em ele
ter uma animação substituindo a tela como um todo, mas isso não é muito comum no mundo linux… por
enquanto vamos fazer o fundo escurecer e essa janela abrir como um popup igual o SUPER+K do
Serpantinum". Decisão do dono que vale aqui: as abas nunca têm a pipa; ela fica só nos itens de
lista, parada, com o blink de 240 ms ao trocar de item. Mockup desta spec:
https://claude.ai/artifact/QPR6gpmyWMDR9pgwXTLbEb (cópia em `YoRHa-OS-private/lab/mockups/menu-de-pausa/`).

**Decisões do dono (2026-10-27)**, que substituem as suposições provisórias do rascunho:
- **Regra geral:** toda alternativa de design vira uma opção em SYSTEM (as configurações), trocável
  na hora, com a recomendação como padrão, mesmo quando o dono acha que não vai usar (FR-034).
- **Moldura:** só o popup sobre o desktop escurecido. A variante de tela cheia sai de vez.
- **Troca de aba:** Tab e Shift+Tab, mais o clique numa aba. As abas não têm a pipa.
- **Ícones dos apps:** em tinta. Pela regra geral, o estilo vira opção: `Ink` (padrão),
  `Original color` ou `Square only`.
- **POWER como proposto:** `Lock` e `Suspend` agem na hora; `Log out`, `Reboot` e `Shut down`
  confirmam, com a pipa começando em `Cancel`.
- **Atalhos:** só `SUPER + Escape` abre o menu (na última aba usada, APPS na primeira vez);
  `ALT + Escape` na VM do laboratório. Os atalhos diretos por aba ficam pra depois (fora do
  escopo). O `SUPER + I` da 003 continua abrindo as configurações; o plano decidiu que ele abre o
  menu na aba SYSTEM (plan.md, "Decisões").

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Abrir o menu de pausa e trocar de aba (Priority: P1)

O usuário aperta um atalho e o menu de pausa abre por cima do desktop escurecido, como o popup da
003: o painel de papel no centro do monitor em foco, com a barra de abas do jogo no alto (APPS,
WINDOWS, SYSTEM, POWER), o título da aba embaixo dela, o corpo da aba e o rodapé de teclas. Um
atalho só (`SUPER + Escape`) abre o menu na última aba usada; o `SUPER + I` da 003 abre direto em
SYSTEM. Com o menu aberto, Tab e Shift+Tab trocam de aba, e o clique numa aba também. A aba aberta é a que desce até a régua
pontilhada; nenhuma aba tem a pipa.

**Why this priority**: É a moldura de todas as outras histórias. Sozinha, com a aba SYSTEM (que já
existe na 003), já entrega um menu navegável.

**Independent Test**: Na VM, com dados de teste, abrir pelos dois atalhos e por comando de controle,
trocar de aba por Tab, Shift+Tab e clique, tirar um screenshot de cada aba e fechar pelos três
caminhos, conferindo o estado exportado e a janela em foco do compositor antes e depois.

**Acceptance Scenarios**:

1. **Given** o desktop com o kitty em foco, **When** o usuário aperta o atalho geral, **Then** o
   menu abre na última aba usada (APPS na primeira vez), centrado no monitor em foco, com o resto
   da tela escurecido sem desfoque.
2. **Given** o menu aberto em APPS, **When** o usuário aperta Tab três vezes, **Then** o menu passa
   por WINDOWS, SYSTEM e POWER, nessa ordem; um quarto Tab volta pra APPS; Shift+Tab anda pro outro
   lado.
3. **Given** o menu aberto em WINDOWS, **When** o usuário aperta `SUPER + I`, **Then** o menu
   troca pra SYSTEM sem fechar; **When** aperta `SUPER + I` de novo, **Then** o menu fecha.
4. **Given** o menu aberto, **When** o usuário aperta Esc com o foco na primeira coluna da aba,
   aperta o atalho geral ou clica fora do painel, **Then** o menu fecha e o teclado volta pra
   janela que estava em foco.
5. **Given** o menu fechado, **When** o usuário aperta `SUPER + I` (o atalho das configurações da
   003), **Then** o menu abre na aba SYSTEM, com as configurações da 003 dentro dela, e essa passa
   a ser a última aba usada.
6. **Given** qualquer aba, **When** a aba muda, **Then** o título, o corpo, o texto do rodapé à
   esquerda e as teclas do rodapé mudam junto, e a aba nova desce até a régua.

---

### User Story 2 - Abrir um app pela aba APPS (Priority: P1)

APPS é o launcher, no layout da tela de itens do jogo: a lista de apps à esquerda (os fixados
primeiro, depois todos em ordem alfabética), uma prévia no meio (o ícone do app em tinta, ou no
estilo escolhido em SYSTEM, o nome e uma descrição) e, à direita, as opções do app (abrir, as ações próprias dele, em que área de
trabalho abrir, fixar) e as informações. O usuário digita pra filtrar; Enter abre o app e fecha o
menu.

**Why this priority**: É o que o dono usa várias vezes por hora e o que o §7 do plano pede pra
substituir. Com a US1, já dá pra usar o menu no lugar do launcher do Serpantinum.

**Independent Test**: Na VM, com o catálogo de teste, abrir APPS pelo atalho geral, digitar consultas e
conferir a ordem dos resultados no estado exportado; com dados reais, abrir o kitty pelo menu e
conferir que uma janela nova do kitty apareceu no compositor.

**Acceptance Scenarios**:

1. **Given** APPS aberto sem busca, **When** a lista aparece, **Then** mostra o grupo PINNED e
   depois o grupo ALL APPS (os outros apps, A–Z), com a pipa no primeiro app; à direita de cada app
   aparece quantas janelas dele estão abertas, quando houver.
2. **Given** APPS aberto, **When** o usuário digita `fir`, **Then** a lista vira só os resultados,
   em ordem de relevância, com a consulta e a contagem no alto da coluna, e a pipa no primeiro.
3. **Given** um resultado em foco, **When** o usuário aperta Enter, **Then** o app abre, o menu
   fecha na hora e o app conta um uso a mais.
4. **Given** um app em foco, **When** o usuário aperta →, **Then** o foco vai pras opções do app:
   `Open`, as ações do próprio app (ex.: `New private window`), `Workspace ◂ Current ▸` e
   `Pinned ◂ ON ▸`; Esc volta pra lista.
5. **Given** uma busca digitada, **When** o usuário aperta Backspace, **Then** a busca perde um
   caractere; **When** aperta Esc, **Then** a busca é limpa (o menu só fecha num segundo Esc).
6. **Given** uma busca sem resultado, **When** a lista fica vazia, **Then** a coluna diz que nada
   bate, o quadro sugere conferir a grafia e Enter não faz nada.

---

### User Story 3 - Ver e mexer nas janelas pela aba WINDOWS (Priority: P2)

WINDOWS lista as janelas abertas, agrupadas por área de trabalho (`WORKSPACE 01`, `02`…), com a
janela em foco marcada. No meio, um mapa da área de trabalho da janela em foco: o contorno do
monitor com as janelas como retângulos, e a janela escolhida em tinta. À direita, as ações da
janela (ir pra ela, mover pra outra área de trabalho, flutuar, fechar) e as informações. Enter vai
pra janela e fecha o menu.

**Why this priority**: Fecha o "janelas" do U3 e substitui o alt-tab e a visão geral de áreas de
trabalho, mas o dono já troca de janela pelos atalhos do Hyprland, então vem depois do launcher.

**Independent Test**: Na VM, com três janelas de teste em duas áreas de trabalho, abrir WINDOWS,
conferir a lista e o mapa no screenshot, ir pra uma janela da outra área de trabalho com Enter e
mover outra pelas opções, conferindo no compositor a janela ativa e a área de trabalho de cada
janela.

**Acceptance Scenarios**:

1. **Given** janelas em duas áreas de trabalho, **When** WINDOWS abre, **Then** a lista mostra os
   grupos em ordem de número, cada janela com o título e o app, e a pipa começa na janela que
   estava em foco.
2. **Given** uma janela em foco na lista, **When** o usuário anda com ↑/↓, **Then** o mapa do meio
   mostra a área de trabalho daquela janela, com ela em tinta.
3. **Given** uma janela de outra área de trabalho em foco, **When** o usuário aperta Enter,
   **Then** o menu fecha, o compositor vai pra área de trabalho dela e ela fica em foco.
4. **Given** as ações de uma janela abertas com →, **When** o usuário muda `Workspace ◂ 01 ▸` pra
   02, **Then** a janela vai pra área de trabalho 02 na hora, a lista se reagrupa e a pipa continua
   nela.
5. **Given** a ação `Close` em foco, **When** o usuário aperta Enter, **Then** o compositor pede
   pra janela fechar; ela some da lista quando fechar de fato, e a pipa vai pra vizinha.

---

### User Story 4 - Energia com confirmação pela aba POWER (Priority: P2)

POWER lista as ações de sessão e energia: `Lock`, `Log out`, `Suspend`, `Hibernate`, `Reboot` e
`Shut down`. No meio, o quadro descreve a ação em foco e o que vai acontecer (ex.: "6 open windows
will close."); à direita, um quadro de status da sessão, como o "Status" do jogo. `Log out`,
`Reboot` e `Shut down` pedem confirmação num diálogo do próprio menu, com o foco em `Cancel`;
`Lock` e `Suspend` agem direto, porque não perdem nada. Uma ação que a máquina não suporta aparece
apagada, com o motivo.

**Why this priority**: Fecha o "energia" do U3. Sem ela o menu ainda é útil (US1–US3), e as ações
são as mais arriscadas de testar, então vêm com cuidado extra.

**Independent Test**: Na VM, com dados de teste (nenhuma ação executa de verdade), disparar cada
ação e conferir no estado exportado o diálogo, o cancelamento e a ação registrada; depois, sem
dados de teste, confirmar um `Reboot` e ver a VM voltar.

**Acceptance Scenarios**:

1. **Given** POWER aberto, **When** o usuário aperta Enter em `Lock`, **Then** o menu fecha e a
   sessão bloqueia, sem diálogo.
2. **Given** `Shut down` em foco, **When** o usuário aperta Enter, **Then** abre o diálogo
   "Shut down?" por cima do painel, com o que vai acontecer, as linhas `Shut down` e `Cancel`, e a
   pipa em `Cancel`.
3. **Given** o diálogo aberto, **When** o usuário aperta Esc, clica fora do diálogo ou confirma
   `Cancel`, **Then** o diálogo fecha, nada acontece e o foco volta pra `Shut down` na lista.
4. **Given** o diálogo aberto, **When** o usuário vai pra `Shut down` e aperta Enter, **Then** o
   menu fecha e a máquina desliga (com dados de teste, a ação só fica registrada).
5. **Given** uma máquina sem hibernação configurada, **When** `Hibernate` está em foco, **Then** a
   linha aparece apagada, o quadro diz o motivo e Enter não faz nada.
6. **Given** um programa segurando o desligamento (ex.: uma atualização em andamento), **When** o
   diálogo de `Shut down` abre, **Then** ele mostra em `alert` quem está segurando e por quê.

---

### User Story 5 - Dados reais na VM (Priority: P3)

Fora dos testes, as abas mostram o sistema de verdade: os apps instalados (os atalhos de app do
padrão freedesktop, nas pastas do sistema e do usuário), as janelas e áreas de trabalho do
compositor, ao vivo, e as ações de energia do gerenciador de sessão. Os fixados e as contagens de
uso ficam guardados como estado do usuário.

**Why this priority**: As US1–US4 se provam com dados de teste (screenshots iguais); esta história
liga as fontes reais, pra o menu poder substituir o launcher na U7.

**Independent Test**: Na VM, instalar um app de teste e ver ele aparecer em APPS sem reiniciar;
abrir e fechar janelas com o menu aberto e ver a lista acompanhar; fixar um app, reiniciar o shell
e ver que continua fixado.

**Acceptance Scenarios**:

1. **Given** o menu aberto em APPS, **When** um app novo é instalado, **Then** ele aparece na
   lista em até 2 s.
2. **Given** WINDOWS aberto, **When** uma janela abre ou fecha em outro lugar, **Then** a lista e o
   mapa acompanham em até 1 s, e a pipa fica no mesmo item ou vai pro vizinho.
3. **Given** um app fixado, **When** o shell reinicia, **Then** ele continua no grupo PINNED, e as
   contagens de uso continuam.

---

### Edge Cases

- **`SUPER + I` com o menu aberto em outra aba:** troca pra SYSTEM sem fechar; aberto em SYSTEM,
  fecha (alterna). O atalho geral sempre fecha um menu aberto.
- **Atalho com o menu aberto em outro monitor:** o menu fecha (como a 003).
- **Monitor em foco muda com o menu aberto:** o menu fica onde abriu até fechar.
- **Troca de aba no meio de uma busca:** a busca de APPS fica guardada enquanto o menu está aberto
  e é limpa quando ele fecha.
- **Tecla de letra fora de APPS:** não faz nada (só APPS tem busca); números e letras nunca trocam
  de aba.
- **Busca com acento ou maiúscula:** `cafe` acha "Café", `FIRE` acha "Firefox".
- **App sem ícone, com nome enorme ou duplicado:** sem ícone, a prévia mostra o ícone genérico da
  categoria; o nome longo corta com reticências; um app com o mesmo id nas pastas do usuário e do
  sistema aparece uma vez só, valendo o do usuário.
- **App escondido** (marcado pra não aparecer em menus): fica de fora.
- **App que falha ao abrir** (comando inexistente): o menu já fechou; o log registra o motivo e o
  app não ganha contagem.
- **App de terminal:** abre dentro do terminal padrão.
- **Nenhuma janela aberta:** WINDOWS mostra "No open windows." na lista, o mapa vazio da área de
  trabalho atual, e o rodapé só mostra `Tab` e `Esc`.
- **Janela some com o menu aberto:** sai da lista; se era a escolhida, a pipa vai pra vizinha; se
  as ações dela estavam abertas, o foco volta pra lista.
- **Janela com título vazio ou enorme:** sem título, mostra o nome do app; o título longo corta com
  reticências na lista e aparece inteiro no quadro.
- **Área de trabalho especial** (scratchpad): vira um grupo `SPECIAL` no fim da lista.
- **Janelas em dois monitores:** todas aparecem; o mapa mostra o monitor da janela escolhida e o
  quadro diz qual é.
- **Diálogo de energia aberto e o menu perde o foco** (ex.: outro atalho): o diálogo cancela.
- **Ação de energia recusada pelo sistema** (sem permissão): o menu continua aberto e o quadro mostra
  o erro em `alert`.
- **Dados de teste ausentes ou inválidos numa aba:** a aba abre com uma mensagem de erro curta no
  quadro, em vez de quebrar; as outras abas funcionam; o log registra.
- **Tela pequena ou escala alta:** o painel encolhe junto (fração da tela, como a 003); os textos
  cortam com reticências sem vazar das colunas; a lista rola em linhas inteiras, com a pipa sempre
  visível: a primeira e a última linha à vista nunca ficam cortadas, pelo teclado ou pela roda do
  mouse (a roda rola uma linha por passo, só quando a lista não cabe; decisão do dono, 28.10, T043).
- **Movimento reduzido ou fixtures ativas:** nada anima (fade, varredura, blink, haste da aba).
- **Opção do menu mudada em SYSTEM com o menu aberto:** vale na hora, sem fechar nem reabrir (ex.:
  o estilo dos ícones muda a prévia de APPS assim que o usuário volta pra aba).
- **Outro popup aberto** (seletor de papel de parede da 004): abrir o menu fecha o seletor, e
  abrir o seletor fecha o menu; só um popup por vez.
- **Teclas repetidas rápido:** um blink novo cancela o anterior; a pipa termina sempre no item em
  foco; trocar de aba várias vezes seguidas termina na aba certa.

## Requirements *(mandatory)*

### Functional Requirements

**Moldura e abas (US1)**

- **FR-001**: O menu MUST abrir e fechar por atalhos da sessão e por comandos de controle:
  - **um atalho geral**, `SUPER + Escape` (`ALT + Escape` na VM, na convenção ALT da 003 e da
    004), que abre o menu na última aba usada na sessão do shell (APPS na primeira vez) e fecha um
    menu aberto;
  - **o atalho das configurações da 003**, `SUPER + I` (`ALT + I` na VM), que abre o menu em SYSTEM,
    troca pra SYSTEM com o menu aberto em outra aba e fecha com ele aberto em SYSTEM;
  - os comandos `open`, `close`, `toggle` e `tab <aba>` (abre nela, ou troca pra ela); os
    comandos de controle da 003 (`settings open|close|toggle|dump|reset`) continuam funcionando e
    agem na aba SYSTEM.
  Os atalhos diretos de APPS, WINDOWS e POWER ficam fora do escopo (decisão do dono).
- **FR-002**: O menu MUST usar a moldura de popup da 003 (`PopupFrame`/`PopupWindow`): o monitor em
  foco escurecido com `color.dim` (sem desfoque), o painel de papel com `popupShare` da tela, a
  vinheta, a sombra `shadow.popup`, o fade de abertura `motion.popupFade` e o fechamento imediato,
  em duas fases. Teclado exclusivo enquanto aberto; o clique fora fecha; ao fechar, o foco volta pra
  janela anterior.
- **FR-003**: Dentro do painel, de cima pra baixo, o menu MUST ter:
  - a barra de abas do design system (`TabBar` com `HeaderButton`): as faixas verticais, as quatro
    abas APPS, WINDOWS, SYSTEM e POWER, e a régua pontilhada; a aba aberta fica `selected` e desce
    até a régua;
  - o título da aba (`PageHeader`), com a sombra: `APPS -Launcher`, `WINDOWS -Open Windows`,
    `SYSTEM -Settings`, `POWER -Session`; a data e a hora à direita, na mesma linha;
  - a régua lisa;
  - o corpo da aba;
  - a régua lisa de baixo, o texto da aba à esquerda (`small`, `medium-gray`) e o rodapé de teclas
    (`KeyHints`) à direita.
- **FR-004**: As abas MUST NOT ter a pipa nem foco de teclado próprio (decisão do dono): a aba muda
  por Tab / Shift+Tab (dando a volta), pelo `SUPER + I` (só pra SYSTEM), pelo comando `tab` ou pelo
  clique; o mouse sobre uma aba
  mostra o estado `hovered` dela. A pipa fica só nos itens das listas.
- **FR-005**: Trocar de aba MUST trocar o corpo na hora (sem animação de página); a aba nova faz a
  animação da haste até a régua da 001 (`motion.touch`). Cada aba guarda a posição da pipa enquanto
  o menu está aberto, exceto as regras de abertura da FR-006.
- **FR-006**: Onde a pipa começa quando o menu abre: APPS no primeiro app, sem busca; WINDOWS na
  janela que estava em foco; SYSTEM onde estava da última vez (como a 003); POWER em `Lock`.
- **FR-007**: As colunas MUST seguir a regra de foco em duas colunas da 003 (design system §7),
  acrescida de:
  - Esc na primeira coluna fecha o menu (exceto com busca em APPS, FR-011);
  - Tab / Shift+Tab trocam de aba em qualquer coluna, e o foco vai pra primeira coluna da aba nova;
  - o mouse só move o foco quando o ponteiro se mexe de verdade.
- **FR-008**: O layout do corpo MUST ser em colunas proporcionais ao painel (não em posições
  fixas), pra o mesmo layout servir telas 16:9 e 16:10 e o `uiScale`. Não existe versão em tela
  cheia (decisão do dono).

**APPS (US2)**

- **FR-009**: APPS MUST usar o layout lista + prévia + opções da 004:
  - **lista** (`GroupedList` da 004, com a pipa): grupo `PINNED`, depois `ALL APPS` (os não
    fixados, A–Z); cada linha com o quadrado, o nome do app e, à direita, quantas janelas dele estão
    abertas (como a quantidade de um item no jogo), quando houver;
  - **prévia** (`Card`): o nome, o ícone do app no estilo da opção `App icons` (FR-034): `Ink`, o
    padrão, recolore o ícone em tinta sobre o papel; `Original color` mostra as cores do ícone;
    `Square only` mostra o quadrado do jogo no lugar do ícone; e a descrição. Nas linhas da lista
    fica sempre o quadrado do jogo;
  - **opções** (`Card` com `OptionRow`): `Open` (ação), as ações próprias do app (ação, uma por
    linha), `Workspace ◂ Current ▸` (escolha: a atual ou 01–10, onde o app abre) e `Pinned ◂ ON ▸`
    (liga/desliga); embaixo, as informações `CATEGORY`, `COMMAND` e `WINDOWS`. Na busca sem
    resultado, o card de opções some, como no mockup (decisão do dono, 28.10, T043).
- **FR-010**: Com o foco em APPS, toda letra, número ou símbolo digitado MUST ir pra busca, que
  aparece no alto da coluna (`SEARCH` + a consulta + `N RESULTS`) no lugar dos grupos. A busca não
  diferencia maiúsculas nem acentos e procura no nome, no nome genérico, nas palavras-chave e no
  comando do app. A ordem: nome que começa com a consulta, palavra do nome que começa com ela,
  nome que contém, nome genérico ou palavra-chave, comando; no empate, o mais usado e depois A–Z.
- **FR-011**: Na busca, Backspace apaga o último caractere; Esc limpa a busca inteira (um segundo
  Esc fecha o menu); ↑/↓ andam nos resultados; Enter abre o resultado em foco.
- **FR-012**: Enter na lista (ou `Open` nas opções) MUST abrir o app com a área de trabalho escolhida
  em `Workspace`, fechar o menu na hora e somar um uso ao app. As ações próprias do app abrem do
  mesmo jeito. O texto da busca nunca passa por um interpretador de comandos.
- **FR-013**: Mudar `Pinned` MUST mover o app entre os grupos na hora, com a pipa acompanhando o app.
- **FR-014**: O rodapé de APPS MUST mostrar, na lista: `↑↓ Select`, `Enter Open`, `→ Options`,
  `Tab Next tab`, `Esc Close` (com busca: `Esc Clear`); nas opções, as teclas da 003 pro tipo da
  linha. O texto à esquerda: `N apps · type to search`.

**WINDOWS (US3)**

- **FR-015**: WINDOWS MUST usar o mesmo layout:
  - **lista**: as janelas agrupadas por área de trabalho (`WORKSPACE 01`, em ordem de número; a
    especial por último, como `SPECIAL`), cada uma com o título (ou o nome do app, sem título) e,
    à direita, o app; a janela que estava em foco tem a marca `●`;
  - **prévia**: o mapa da área de trabalho da janela escolhida, desenhado pelo projeto: o contorno
    do monitor, a faixa da barra do topo e as janelas como retângulos nas posições e proporções
    reais, a escolhida em tinta com o título, as outras em `light-gray` com contorno; embaixo, o
    título inteiro;
  - **opções**: `Focus` (ação), `Workspace ◂ 01 ▸` (escolha: 01–10), `Floating ◂ OFF ▸`
    (liga/desliga) e `Close` (ação); embaixo, `APP`, `MONITOR`, `SIZE`.
- **FR-016**: Enter na lista (ou `Focus`) MUST fechar o menu, ir pra área de trabalho da janela e
  dar foco a ela. Mudar `Workspace` move a janela na hora, sem sair da área de trabalho atual;
  `Floating` alterna na hora; `Close` pede pra janela fechar (o app pode perguntar antes, por
  exemplo pra salvar).
- **FR-017**: A lista e o mapa MUST acompanhar o compositor ao vivo enquanto o menu está aberto
  (janelas que abrem, fecham, mudam de título ou de área de trabalho), com a pipa ficando na mesma
  janela ou indo pra vizinha.
- **FR-018**: O rodapé de WINDOWS MUST mostrar: `↑↓ Select`, `Enter Focus`, `→ Actions`,
  `Tab Next tab`, `Esc Close`; o texto à esquerda: `N windows · M workspaces`.

**SYSTEM**

- **FR-019**: SYSTEM MUST ser a página de configurações da 003 inteira (categorias, opções, quadro
  de descrição, valores de teste em memória, dependências, avisos), dentro do corpo do menu, mais a
  categoria nova `Pause menu` (FR-034). O que muda em relação à 003: a página ganha a barra de abas
  (a FR-008 da 003, "sem abas", deixa de valer), o título fica abaixo das abas, as colunas se
  ajustam ao corpo menor e o rodapé ganha `Tab Next tab`. O texto à esquerda continua a versão do
  YoRHa-OS. O popup avulso da 003 deixa de existir: `SUPER + I` e o comando `settings` abrem o menu
  em SYSTEM (FR-001).

**POWER (US4)**

- **FR-020**: POWER MUST ter:
  - **lista** (`CursorList`, sem grupos): `Lock`, `Log out`, `Suspend`, `Hibernate`, `Reboot`,
    `Shut down`;
  - **quadro** (`DescriptionCard`): o nome, o que a ação faz e o que vai acontecer agora (ex.:
    "6 open windows will close."), e o motivo quando a ação está apagada;
  - **status** (o "card de status" do design system §4): pares rótulo/valor da sessão (`USER`,
    `HOST`, `UPTIME`, `BATTERY`, `WINDOWS`), a fileira de quadrados e o rodapé centralizado
    (`NO ERROR`, ou o aviso em `alert`).
- **FR-021**: Com a opção `Confirm` no padrão (`Risky ones`, FR-034), `Lock` e `Suspend` MUST agir
  direto (fechando o menu antes) e `Log out`, `Reboot` e `Shut down` MUST abrir um diálogo de
  confirmação; com `Every action`, todas confirmam. `Hibernate` age como `Suspend` quando a máquina
  suporta e fica apagado (o estado `dimmed`) quando não.
- **FR-022**: O diálogo de confirmação (`ConfirmDialog`, novo) MUST:
  - aparecer centrado por cima do painel, com o painel escurecido por `color.dim`;
  - ser um `Card` com o título (`Shut down?`), o que vai acontecer, os programas que estão
    segurando a ação (em `alert`), e duas linhas `OptionRow` de ação: a ação e `Cancel`;
  - começar com a pipa em `Cancel` (o padrão da opção `Dialog starts on`, FR-034; a alternativa
    é começar na ação);
  - confirmar com Enter ou clique na linha da ação; cancelar com Esc, clique fora dele, Enter em
    `Cancel` ou qualquer perda de foco do menu;
  - ter o próprio rodapé de teclas: `↑↓ Select`, `Enter Confirm`, `Esc Cancel`.
- **FR-023**: `Lock`, `Suspend` e `Hibernate` MUST fechar o menu antes de executar (a tela tem que
  estar limpa); `Log out`, `Reboot` e `Shut down` executam depois da confirmação e fecham o menu
  quando o sistema aceita. Uma recusa do sistema (falta de permissão, um programa bloqueando)
  mantém o menu aberto, com o erro no quadro; a recusa de uma ação que já fechou o menu vai pro log
  e aparece no quadro de POWER na próxima abertura. Com dados de teste, nada executa: a ação fica
  registrada no estado exportado. (Precisão feita no plano, 2026-10-27.)
- **FR-024**: O rodapé de POWER MUST mostrar: `↑↓ Select`, `Enter <ação>` (nada numa ação
  apagada), `Tab Next tab`, `Esc Close`; o texto à esquerda: `Up <tempo>`.

**Dados, textos e testes**

- **FR-025**: Cada aba MUST ler os dados por um serviço que aceita dados de teste (como a 001 e a
  003), pros screenshots saírem iguais. Os arquivos de teste: catálogo de apps (com ícones gerados
  pelo projeto, nomes, categorias, ações, fixados e contagens), janelas e áreas de trabalho (com as
  posições e os tamanhos), e o estado da sessão e das ações de energia (incluindo uma não suportada
  e um programa segurando o desligamento).
- **FR-026**: As fontes reais (US5) MUST ser:
  - **apps:** os atalhos de app do padrão freedesktop nas pastas de dados do sistema e do usuário,
    observadas (um app novo aparece sem reiniciar), com o ícone do tema de ícones;
  - **janelas e áreas de trabalho:** o compositor, pelo adaptador da UI (Hyprland primeiro, Niri
    depois);
  - **energia:** o gerenciador de sessão do sistema (o que ele diz que pode, os programas
    segurando, e as ações), e o bloqueio da sessão pelo mesmo caminho (quem desenha a tela de
    bloqueio é o locker da sessão; o do YoRHa-OS vem no U5).
- **FR-027**: Os apps fixados e as contagens de uso MUST ficar como estado do usuário, fora dos
  arquivos de configuração dele (constituição III), e sobreviver a reiniciar o shell. Com dados de
  teste, valem só em memória.
- **FR-028**: Todo texto fixo da UI MUST ficar em inglês, no lugar central de textos (`Strings`),
  pra tradução no U5b. Os nomes vindos dos dados aparecem como vierem.
- **FR-029**: O shell MUST exportar, por comando de controle, o estado do menu: aberto ou não,
  monitor, aba, coluna em foco, item em foco em cada aba, a busca e os resultados de APPS, os
  grupos de WINDOWS, o diálogo de POWER, os valores das opções do menu (FR-034), a última ação
  disparada (app aberto, janela focada ou
  movida, ação de energia), as teclas do rodapé e a geometria do item em foco (pros cliques dos
  testes).
- **FR-030**: Com fixtures, nada anima (fade, varredura, blink, haste da aba), pra screenshots
  iguais. Com o movimento reduzido (`reduceMotion`), o mesmo.
- **FR-031**: Abrir, navegar por todas as abas, buscar, abrir o diálogo e fechar MUST deixar o log
  do shell sem erro e sem aviso de QML.

**Opções do menu em SYSTEM (regra geral do dono)**

- **FR-034**: As alternativas de design do menu MUST virar opções de escolha numa categoria nova
  de SYSTEM, `Pause menu`, trocáveis na hora (o menu aberto muda sem reabrir), com a recomendação
  como padrão:

  | Opção | Valores (padrão primeiro) | O que muda |
  |---|---|---|
  | `App icons` | `Ink`, `Original color`, `Square only` | O ícone na prévia de APPS (FR-009) |
  | `App order` | `A–Z`, `Most used` | A ordem do grupo ALL APPS sem busca |
  | `Running app` | `New window`, `Go to window` | Enter num app que já tem janela: abre outra, ou vai pra janela dele (a mais recente) |
  | `Confirm` | `Risky ones`, `Every action` | Quais ações de POWER pedem confirmação (FR-021) |
  | `Dialog starts on` | `Cancel`, `Action` | Onde a pipa começa no diálogo de confirmação (FR-022) |

  Os valores valem pela sessão do shell, em memória, como as outras opções da 003; guardar entre
  sessões segue o mesmo caminho que a opção `Bar contrast` da 004 adotar (plan.md).

**Componentes do design system**

- **FR-032**: O menu MUST reusar as peças aprovadas, sem cópia: a moldura de popup e o
  escurecimento (003), `CursorList` com a pipa parada, o blink e o estado sem foco (003),
  `OptionRow` nos tipos ação, liga/desliga, escolha e informação, `ValueStepper`,
  `DescriptionCard`, `KeyHints`, a regra de foco em duas colunas (003), o layout lista + prévia +
  opções e a `GroupedList` (004), `TabBar`, `HeaderButton`, `PageHeader`, `Card`, `Rule` (001).
- **FR-033**: As peças novas MUST virar componentes do design system, aparecer na galeria com os
  estados e entrar no `docs/design-system.md`:
  - **moldura do menu de pausa** (`PauseMenu`): painel + barra de abas + título + corpo + rodapé;
  - **cabeçalho de busca** da lista (`SEARCH` + consulta + contagem, e o estado sem resultado);
  - **mapa de área de trabalho** (`WorkspaceMap`): vazio, com janelas, com a escolhida em tinta;
  - **card de status** (`StatusCard`, o composto do §4 que ainda não existia), com `NO ERROR` e com
    aviso;
  - **diálogo de confirmação** (`ConfirmDialog`), com a pipa em `Cancel` e na ação.

### Key Entities

- **Aba:** id (`apps`, `windows`, `system`, `power`), rótulo, título e complemento, texto do
  rodapé, posição da pipa guardada.
- **App:** id, nome, nome genérico, descrição, categoria, ícone, comando, palavras-chave, se abre
  num terminal, ações próprias (nome e comando), fixado ou não, contagem de usos.
- **Janela:** id, app, título, área de trabalho, monitor, posição e tamanho, flutuante ou não, se
  está em foco.
- **Área de trabalho:** número (ou especial), monitor, janelas.
- **Ação de energia:** id, rótulo, se pede confirmação, se está disponível (e o motivo quando não),
  os programas que a seguram.
- **Estado do menu:** aberto ou fechado, monitor, aba, coluna em foco, busca, diálogo aberto,
  última ação.
- **Opção do menu:** id, rótulo, valores (o primeiro é o padrão), valor em uso; vive na categoria
  `Pause menu` das configurações (FR-034).

## Success Criteria *(mandatory)*

Cada critério diz qual evidência da VM o comprova (constituição IV).

- **SC-001** ("pronto quando" do PLAN): com dados de teste, um screenshot de cada uma das 4 abas,
  do diálogo de `Shut down` e da busca de APPS com resultado e sem resultado (7 telas), em
  1920x1080 @1 e em 2560x1600 @1,25. Evidência: os 14 screenshots e o estado exportado de cada um.
- **SC-002**: com fixtures, dois screenshots seguidos de cada aba são idênticos (0 px de diferença).
  Evidência: os screenshots e a diferença.
- **SC-003**: do desktop até um app aberto, por teclas reais enviadas à VM, bastam no máximo 5
  teclas (atalho geral com APPS como última aba, três letras, Enter), e a janela nova aparece no compositor em até 2 s.
  Evidência: as teclas, o tempo medido do host e a lista de janelas antes e depois.
- **SC-004**: com o catálogo de teste, 10 consultas do roteiro (começo do nome, palavra do meio,
  nome genérico, palavra-chave, acento, maiúscula, sem resultado) trazem o resultado esperado em
  primeiro nas 10. Evidência: o estado exportado de cada consulta.
- **SC-005**: o menu abre em até 0,3 s depois do atalho, medido do host; uma sequência de teclas
  reais (atalho geral, Tab ×4, Shift+Tab, `SUPER + I`, `SUPER + I`) termina com o estado esperado
  em cada passo e com o menu fechado; os três jeitos de fechar devolvem o teclado à janela
  anterior. Evidência: tempos, estado exportado por tecla e a janela em foco do compositor.
- **SC-006**: com três janelas de teste reais em duas áreas de trabalho, WINDOWS lista exatamente as
  três, nos grupos certos; Enter numa janela da outra área de trabalho a deixa ativa; mudar
  `Workspace` de outra a move; `Close` numa terceira a tira da lista em até 1 s. Evidência: estado
  exportado e as janelas do compositor antes e depois de cada passo, mais um screenshot do mapa.
- **SC-007**: com dados de teste, `Lock` e `Suspend` registram a ação sem diálogo; `Log out`,
  `Reboot` e `Shut down` abrem o diálogo com a pipa em `Cancel`; Esc, clique fora e `Cancel` não
  registram nada; confirmar registra a ação; `Hibernate` não suportado não faz nada; o programa
  segurando aparece no diálogo. Sem dados de teste, um `Reboot` confirmado reinicia a VM.
  Evidência: estado exportado por passo e o tempo ligado da VM antes e depois do reboot.
- **SC-008**: numa sequência de quadros sem fixtures, trocar de item mostra a pipa sumindo e
  reaparecendo inteira em até 0,21 s depois de sumir (medido na T046; decisão do dono, 29.10, no
  lugar de "≈240 ms"), e nenhuma aba mostra a pipa em nenhum quadro. Evidência: os quadros.
- **SC-009**: um app de teste instalado com o menu aberto aparece em APPS em até 2 s; um app fixado
  continua fixado depois de reiniciar o shell. Evidência: estado exportado e screenshot.
- **SC-010**: o log fica sem erro e sem aviso de QML depois do roteiro inteiro. Evidência: o trecho
  do log e o lint limpo.
- **SC-011**: a galeria mostra cada componente novo da FR-033, com os estados. Evidência: screenshot
  da galeria.
- **SC-012**: o dono aprova o visual comparando os screenshots com o mockup. Evidência: a
  aprovação.
- **SC-013**: com o menu aberto, mudar cada opção da categoria `Pause menu` em SYSTEM muda o
  comportamento na hora, sem fechar o menu: os 3 estilos de ícone na prévia de APPS, a ordem de ALL
  APPS, o Enter num app com janela, quais ações de POWER confirmam e onde a pipa começa no diálogo.
  Evidência: um screenshot da prévia por estilo e o estado exportado depois de cada mudança.

## Assumptions

- **Onde roda:** só na VM do laboratório (constituição I). Os atalhos vão na config do Hyprland da
  VM, na convenção ALT; na máquina do dono, entram pelo instalador (S3) ou na troca (U7). Nenhuma
  ação de energia é testada fora da VM, e só a VM reinicia.
- **Decisões do dono (2026-10-27):** as do topo desta spec. Ficaram de fora, por decisão dele: a
  tela cheia; Q/E pra trocar de aba (as letras vão pra busca de APPS); a linha de abas focável com
  ←→ como no jogo (custaria um Esc a mais pra fechar).
- **Padrões (viraram opções pela regra geral, FR-034):** Enter em APPS abre uma instância nova
  mesmo com o app aberto (`Running app`); a lista de apps é A–Z, e a busca é que usa a contagem de
  usos (`App order`); o diálogo começa em `Cancel` (`Dialog starts on`). Sem opção: WINDOWS ordena
  as janelas de cada grupo de cima pra baixo e da esquerda pra direita na tela.
- **Fora do escopo:**
  - a tela cheia substituindo o desktop (descartada pelo dono);
  - os atalhos diretos de APPS, WINDOWS e POWER (adiados pelo dono; os comandos `pause tab <aba>`
    já permitem ligá-los depois sem mudar o shell);
  - miniaturas ao vivo das janelas (o mapa resolve agora; a miniatura entra no U6, quando o custo
    for medido);
  - arrastar janelas no mapa;
  - busca de arquivos, calculadora, comandos ou web dentro de APPS;
  - editar os atalhos de app pela interface;
  - a tela de bloqueio em si (U5) e o agente de polkit (U5);
  - o seletor de papel de parede da 004, que continua um popup próprio (pode virar uma ação em
    SYSTEM › Appearance depois);
  - efeitos reais das configurações de SYSTEM (continuam de teste, como na 003);
  - tradução (U5b).
- **Dependências:** a 003 (moldura de popup, `CursorList` sem foco, `OptionRow`, `ValueStepper`,
  `DescriptionCard`, `KeyHints`, a página de configurações) e a 004 (layout lista + prévia +
  opções, `GroupedList`, que nasce no seletor da 004, US2); a 001 (tokens, `TabBar`, `HeaderButton`,
  `PageHeader`, `Card`, `Rule`, fixtures, adaptador do compositor). Se a `GroupedList` da 004 ainda
  não existir quando o plano desta spec for feito, ela entra aqui, no contrato da 004.
- **Instalador (S3):** o instalador tem que criar `~/.local/share/applications/` antes de subir o
  shell. O Quickshell só observa essa pasta se ela já existir quando ele sobe; criada depois, um app
  instalado não aparece em APPS até o shell reiniciar (achado do spike T003, research R4, e da T041).
- **Movimento reduzido:** respeita o `reduceMotion` que já existe (003/004).
- **Laboratório:** no máximo 4 VMs ao mesmo tempo, cada uma com 2 núcleos e 4 GB (limite do dono
  pra rodada de 2026-10-27); as frentes paralelas do plano cabem nisso.
