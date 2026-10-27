# Feature Specification: Configurações num popup

**Feature Branch**: `003-settings-popup` (sai da `001-yorha-base-hud`, que ainda não foi pro `main`)

**Created**: 2026-10-27

**Status**: Rascunho, aguardando a aprovação do dono

**Input**: Pedido do dono, a partir do mockup aprovado da aba SYSTEM
(https://claude.ai/artifact/Hi6evdHnH2tFQw9eyKv2H5; cópia em
`rien-OS-private/lab/mockups/configuracoes/index.html`): "essa tela por enquanto vamos fazer o
fundo escurecer e essa janela abrir como um popup igual o super + K aqui do serpantinum. só que
escurecendo o fundo do SO". Dados: "tudo fixture".

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Abrir e fechar as configurações por cima do desktop (Priority: P1)

Em qualquer momento da sessão, o usuário aperta um atalho e as configurações aparecem como um popup
no centro do monitor em foco. O resto da tela (janelas, barra do topo, fundo) continua visível, mas
escurecido, pra deixar claro que o popup tem o foco. O popup tem a cara dos menus do jogo: papel com
grid, vinheta, título `SYSTEM -Settings` com a sombra chapada e a régua embaixo. Ele fecha pelo mesmo
atalho, pelo Esc ou com um clique fora dele.

**Why this priority**: Sem abrir e fechar, nada do resto existe. É também o padrão de "janela por cima
do desktop" que os próximos menus (U3) vão reaproveitar.

**Independent Test**: Na VM, abrir pelo atalho e por IPC, tirar um screenshot (popup centrado, resto
escurecido), fechar pelos três caminhos e conferir que a tela volta ao normal e que o teclado volta
pra janela que estava em foco.

**Acceptance Scenarios**:

1. **Given** o desktop com o kitty aberto, **When** o usuário aperta o atalho, **Then** o popup
   aparece centrado no monitor em foco, com um fade curto, e o resto do monitor fica escurecido sem
   desfoque.
2. **Given** o popup aberto, **When** o usuário aperta o atalho de novo, aperta Esc com o foco nas
   categorias, ou clica fora do popup, **Then** o popup e o escurecimento somem e o teclado volta
   pra janela anterior.
3. **Given** o popup aberto, **When** o usuário digita, **Then** as teclas vão pro popup e não pra
   janela de trás.
4. **Given** dois monitores, **When** o popup abre, **Then** ele aparece só no monitor em foco; o
   outro fica como estava.

---

### User Story 2 - Navegar pelas categorias e opções como num menu do jogo (Priority: P1)

O popup mostra três colunas: as categorias à esquerda (Display, Sound, Network, Bluetooth,
Appearance, Keyboard, Power), as opções da categoria no meio e, à direita, um quadro que descreve o
que está em foco. Embaixo, um rodapé mostra as teclas que valem agora. O usuário anda com as setas
ou com o mouse; a pipa marca onde ele está. Ela fica parada, como no jogo, e pisca ao trocar de
item.

**Why this priority**: É a interação que define o padrão dos menus do rien-OS. Junto com a US1, já
entrega uma tela navegável de ponta a ponta.

**Independent Test**: Na VM, com dados de teste, mandar teclas reais (setas, Enter, Esc) e
movimentos de mouse, e conferir pelo estado exportado e por screenshots que o foco, a categoria
mostrada, a pipa, o quadro e o rodapé mudam como descrito.

**Acceptance Scenarios**:

1. **Given** o popup aberto com o foco nas categorias, **When** o usuário aperta ↓, **Then** a
   próxima categoria fica marcada e as opções dela aparecem na hora no meio.
2. **Given** o foco nas categorias, **When** o usuário aperta → ou Enter, **Then** o foco vai pra
   primeira opção; a categoria continua marcada e a pipa dela fica clara e parada.
3. **Given** o foco nas opções, **When** o usuário aperta Esc, **Then** o foco volta pras
   categorias; um segundo Esc fecha o popup.
4. **Given** o foco numa opção, **When** o usuário aperta ↑ ou ↓, **Then** a pipa some do item
   antigo e reaparece no novo, num blink suave.
5. **Given** o mouse sobre um item, **When** ele passa por cima de outro, **Then** o foco e a pipa
   vão junto; passar por cima de uma categoria troca as opções mostradas.
6. **Given** qualquer item em foco, **When** o foco muda, **Then** o quadro da direita mostra o
   nome e a descrição do item, e o rodapé mostra só as teclas que valem pra ele.

---

### User Story 3 - Mudar valores (Priority: P2)

Cada opção mostra o valor atual à direita. O usuário liga e desliga, escolhe entre valores, ajusta
sliders, dispara ações e lê informações, tudo pelo teclado ou pelo mouse. O quadro mostra o valor
padrão e o atual. Opções que dependem de outra (a rede escolhida depende do Wi-Fi; os aparelhos e a
busca dependem do Bluetooth) ficam apagadas quando a outra está desligada, e o quadro diz o que
fazer.

**Why this priority**: Sem mudar valores a tela é só uma vitrine, mas as US1 e US2 já validam o
visual e a navegação, e nesta fase os valores são de teste.

**Independent Test**: Na VM, com dados de teste, mudar uma opção de cada tipo por teclas reais e
por clique, e conferir no estado exportado e no screenshot o valor novo, o quadro e as opções
dependentes.

**Acceptance Scenarios**:

1. **Given** o foco em "Night light" (OFF), **When** o usuário aperta → ou Enter, **Then** o valor
   vira ON e o quadro mostra DEFAULT OFF e NOW ON.
2. **Given** o foco em "Scale" (1.25×), **When** o usuário aperta →, **Then** o valor vira 1.50×;
   no último valor, a seta da direita fica apagada e → não muda nada.
3. **Given** o foco em "Brightness" (70), **When** o usuário aperta ←, **Then** o valor cai um
   passo (65) e o medidor encolhe; um clique na trilha leva o valor pro ponto clicado.
4. **Given** "Bluetooth" ON, **When** o usuário desliga, **Then** "K2 Keyboard", "Headphones" e
   "Pair a device" ficam apagados, continuam focáveis, e o quadro de cada um diz "Turn on Bluetooth
   first."; ← nessas linhas volta pras categorias.
5. **Given** o foco em "Pair a device", **When** o usuário aperta Enter, **Then** o quadro mostra
   um aviso de ação em andamento por alguns segundos e depois volta ao normal.
6. **Given** o foco numa opção de informação (ex.: "Battery"), **When** o usuário aperta ← ou →,
   **Then** nada muda (← volta pras categorias), e o rodapé não mostra "Change".
7. **Given** valores mudados, **When** o popup fecha e abre de novo na mesma sessão, **Then** os
   valores mudados continuam; depois de reiniciar o shell, voltam aos dos dados de teste.

---

### Edge Cases

- **Atalho com o popup já aberto em outro monitor:** o popup fecha (o atalho alterna).
- **Monitor em foco muda com o popup aberto:** o popup fica onde abriu até fechar.
- **Tela pequena ou com escala alta:** o popup encolhe junto (o tamanho é uma fração da tela) e os
  textos longos de valor e de descrição quebram ou cortam com reticências, sem vazar das colunas.
- **Categoria com mais opções do que cabem:** a coluna rola junto com o foco, e a pipa nunca fica
  fora da área visível.
- **Dados de teste ausentes ou inválidos:** o popup abre com uma mensagem de erro curta no quadro,
  em vez de quebrar; o log registra o motivo.
- **Movimento reduzido:** com a opção de movimento reduzido do rien-OS ligada, nem o fade de
  abertura nem o blink acontecem (a pipa só pula).
- **Fixtures ativas (testes):** nada anima, pra dois screenshots saírem iguais.
- **Teclas repetidas rápido:** um blink novo cancela o anterior; a pipa termina sempre no item em
  foco.

## Requirements *(mandatory)*

### Functional Requirements

**Abrir e fechar (US1)**

- **FR-001**: O popup MUST abrir e fechar por um atalho de teclado da sessão (`SUPER + I` na VM)
  e por comandos de controle `open`, `close` e `toggle`, pra testes e pra outros atalhos.
- **FR-002**: O popup MUST abrir centrado no monitor em foco, com um tamanho proporcional à tela
  (≈84% da largura e da altura, num token) e o layout do mockup aprovado em escala.
- **FR-003**: Enquanto o popup está aberto, o resto do monitor MUST ficar coberto por uma camada
  de tinta translúcida (≈55%), **sem desfoque** (constituição VII). Janelas, barra do topo e fundo
  continuam visíveis por baixo.
- **FR-004**: O popup MUST fechar pelo mesmo atalho, por Esc com o foco nas categorias e por um
  clique na área escurecida. Ao fechar, o foco do teclado volta pra janela que o tinha.
- **FR-005**: Enquanto aberto, o popup MUST receber todo o teclado; nada vai pra janela de trás.
- **FR-006**: A abertura MUST ter um fade curto (≈150 ms, token) do escurecimento e do popup; o
  fechamento é imediato.

**Aparência**

- **FR-007**: O popup MUST usar o design system da 001: papel com grid, vinheta (desligável pela
  config `vignette` que já existe), sombra deslocada chapada, título `SYSTEM` com a sombra e o
  complemento `-Settings`, régua lisa embaixo do título e régua lisa acima do rodapé. Nada de
  cor, tamanho ou tempo fora dos tokens.
- **FR-008**: O popup NÃO tem as abas do menu de pausa; elas ficam pro U3.
- **FR-009**: O layout MUST seguir o mockup aprovado: categorias à esquerda com as faixas
  verticais, opções no meio com o nome da categoria e a contagem de opções em cima, quadro de
  descrição à direita, rodapé de teclas embaixo à direita e a versão do rien-OS embaixo à
  esquerda.

**Navegação (US2)**

- **FR-010**: Existe um foco só, numa de duas colunas: categorias ou opções. Regras:
  - **categorias:** ↑/↓ movem (dando a volta nas pontas) e trocam as opções mostradas na hora;
    → ou Enter levam o foco pra primeira opção; Esc fecha o popup;
  - **opções:** ↑/↓ movem (dando a volta); ←/→ mudam o valor quando a opção muda de valor; ←
    numa opção que não muda (ação, informação ou apagada) volta pras categorias; Enter alterna,
    avança ou dispara (por tipo); Esc volta pras categorias.
- **FR-011**: O mouse MUST mover o foco ao passar por cima de um item; passar por uma categoria
  troca as opções; clicar numa categoria leva o foco pras opções; clicar numa opção age como Enter;
  clicar nas setas ◂ ▸ muda o valor pra esse lado; clicar na trilha de um slider leva o valor pro
  ponto clicado.
- **FR-012**: O item em foco MUST aparecer destacado (faixa de tinta que varre da esquerda, com os
  trilhos) e com a pipa à esquerda. A categoria da coluna sem foco continua destacada, com a pipa
  **clara**. Na coluna de opções sem foco, nenhum item fica destacado.
- **FR-013**: A pipa MUST ficar parada e piscar ao trocar de item (some do antigo, reaparece no
  novo), como a FR-005 da 001 (`motion.blink`, 240 ms). A pipa clara não pisca.
- **FR-014**: O quadro da direita MUST mostrar:
  - com o foco nas categorias: o nome da categoria, uma frase sobre ela e quantas opções tem;
  - com o foco numa opção: o nome, a descrição, DEFAULT e NOW (quando a opção tem valor), e um
    aviso quando a opção está apagada (o que fazer) ou quando uma ação está em andamento.
- **FR-015**: O rodapé MUST mostrar só as teclas que valem no foco atual:
  - categorias: `↑↓ Select`, `→ Open`, `Esc Close`;
  - opção que muda: `↑↓ Select`, `←→ Change`, `Esc Back`;
  - ação: `↑↓ Select`, `Enter <ação>`, `Esc Back`;
  - informação ou apagada: `↑↓ Select`, `Esc Back`.

**Valores (US3)**

- **FR-016**: Cada opção é de um de cinco tipos, com o valor à direita:
  - **liga/desliga:** `◂ ON ▸` / `◂ OFF ▸`; ←, → e Enter alternam;
  - **escolha:** `◂ valor ▸` numa lista fixa; ← e → andam sem dar a volta, e a seta da ponta
    fica apagada; Enter avança dando a volta;
  - **slider:** o medidor do HUD em versão editável, com o número; ←/→ mudam um passo (definido
    por opção, entre 0 e 100);
  - **ação:** um rótulo (`Search`, `Set up`, `Open`) com uma seta; Enter mostra o aviso de
    andamento no quadro por ≈2 s; nada mais acontece;
  - **informação:** só leitura (`Not connected`, `87% · charging`).
  As setas ◂ ▸ só aparecem na linha em foco.
- **FR-017**: Uma opção pode depender de outra de liga/desliga. Com a outra desligada, ela fica
  apagada (o estado `dimmed` da 001), continua focável, não muda de valor nem dispara, e o quadro
  diz o que fazer ("Turn on Wi-Fi first.", "Turn on Bluetooth first.").
- **FR-018**: Os valores MUST valer só em memória durante a sessão do shell: continuam ao fechar e
  reabrir; voltam aos dos dados de teste quando o shell reinicia. **Nada** mexe no sistema nem
  grava arquivo.

**Dados, textos e testes**

- **FR-019**: As categorias e opções MUST vir de um arquivo de dados de teste do shell
  (`settings-default.json`), com as 7 categorias e as opções do mockup aprovado: nome, tipo,
  valores, valor atual, padrão, passo, dependência, rótulo e aviso de ação, e descrição.
- **FR-020**: Todo texto fixo da UI MUST ficar em inglês, no lugar central de textos da 001, pra
  tradução no U5b. Os textos que vêm do arquivo de dados aparecem como vierem.
- **FR-021**: O shell MUST exportar, por comando de controle, o estado do popup: aberto ou não,
  monitor, coluna em foco, categoria, opção em foco e os valores atuais (como o `hud dump`).
- **FR-022**: Com fixtures ativas, nada anima (fade, varredura, blink), pra screenshots iguais.
- **FR-023**: Abrir, navegar e fechar MUST deixar o log do shell sem erro e sem aviso de QML.

**Componentes do design system**

- **FR-024**: As peças novas MUST virar componentes reutilizáveis do design system, aparecer na
  galeria com os estados delas e entrar no `docs/design-system.md`:
  - **linha de opção**, nos 5 tipos, nos estados normal, em foco e apagada;
  - **seletor de valor** `◂ valor ▸`, com as setas apagadas na ponta;
  - **medidor editável** (slider);
  - **quadro de descrição** (o card com DEFAULT/NOW e aviso);
  - **rodapé de teclas**;
  - **lista de categorias sem foco** (pipa clara);
  - **moldura de popup** com o escurecimento.

### Key Entities

- **Categoria:** nome, frase de descrição, lista ordenada de opções.
- **Opção:** nome, tipo (liga/desliga, escolha, slider, ação, informação), descrição; conforme o
  tipo: valor atual, valor padrão, lista de valores, passo, rótulo da ação e aviso de andamento,
  texto de informação; opcionalmente, uma chave (pra outras dependerem dela) e a chave da qual ela
  depende.
- **Estado do popup:** aberto ou fechado, monitor, coluna em foco, categoria atual, opção em foco,
  ação em andamento.

## Success Criteria *(mandatory)*

Cada critério diz qual evidência da VM o comprova (constituição IV).

- **SC-001**: Com dados de teste, o popup aberto aparece centrado sobre o desktop escurecido, nas 7
  categorias, em 1920x1080 @1 e em 2560x1600 @1,25. Evidência: 14 screenshots e o estado exportado
  de cada um.
- **SC-002**: Com fixtures, dois screenshots do popup aberto, tirados um depois do outro, são
  idênticos (0 px de diferença). Evidência: os dois screenshots e a diferença.
- **SC-003**: Uma sequência de teclas reais enviada à VM (↓ ×3, →, ↓, →, Esc, Esc) termina com o
  estado esperado em cada passo (categoria, coluna, opção, valor) e com o popup fechado no fim.
  Evidência: o estado exportado depois de cada tecla.
- **SC-004**: O popup abre em até 0,3 s depois do atalho, medido do host, e fecha pelos 3 caminhos
  (atalho, Esc, clique fora) com o teclado voltando pra janela anterior. Evidência: tempos, estado
  exportado e a janela em foco do compositor antes e depois.
- **SC-005**: Uma troca de opção sem fixtures mostra, numa sequência de quadros, a pipa sumindo do
  item antigo e reaparecendo no novo em ≈240 ms, e a pipa clara parada na outra coluna. Evidência:
  a sequência de quadros.
- **SC-006**: Uma mudança de cada tipo de opção (liga/desliga, escolha nas duas pontas, slider por
  tecla e por clique, ação, dependência do Bluetooth) produz o valor e o quadro esperados.
  Evidência: estado exportado e screenshots.
- **SC-007**: O log do shell fica sem erro e sem aviso de QML depois de abrir, navegar por todas as
  categorias e fechar. Evidência: o trecho do log e a checagem de lint limpa.
- **SC-008**: A galeria mostra cada componente novo com os estados da FR-024, com nome. Evidência:
  screenshot da galeria.
- **SC-009**: O dono aprova o visual comparando os screenshots com o mockup.

## Assumptions

- **Onde roda:** só na VM do laboratório (constituição I). O atalho `SUPER + I` vai na config do
  Hyprland da VM; na máquina do dono, entra pelo instalador (S3) ou na troca (U7).
- **Decisões do mockup, aprovadas pelo dono ("perfeito"):** setas pro liga/desliga (não os dois
  botões), pipa clara na coluna sem foco (não some), blink de 240 ms, quadro de descrição à direita,
  as 7 categorias com as opções do mockup.
- **Suposições visuais, calibráveis depois por token:** escurecimento ≈55% de tinta; fade de
  abertura ≈150 ms; popup ≈84% da tela; fechamento sem animação.
- **Fora do escopo:**
  - as abas e o resto do menu de pausa (U3): launcher, janelas, energia;
  - qualquer efeito real das opções (fala com PipeWire, NetworkManager, BlueZ, Hyprland etc.);
  - gravar as mudanças em arquivo;
  - a tela cheia substituindo o desktop (ideia do dono pra depois);
  - o novo papel de parede, que o dono ainda vai definir;
  - tradução (U5b).
- **Dependências:** os componentes, tokens e serviços da 001 (design system, CursorList, ListItem,
  Selector com blink, Meter, Card, régua, vinheta, fixtures, configurações do usuário) e o
  laboratório com os perfis 1080 e hidpi.
- **Movimento reduzido:** ainda não existe uma opção real; a spec só exige que, quando existir, o
  popup a respeite. Nos testes, o comportamento sem animação vem das fixtures (FR-022).
