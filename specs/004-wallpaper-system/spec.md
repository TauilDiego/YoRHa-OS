# Feature Specification: Sistema de papel de parede

**Feature Branch**: `004-wallpaper-system` (sai da `003-settings-popup`, porque reusa a moldura de popup)

**Created**: 2026-10-27

**Status**: Aprovada pelo dono (2026-10-27); implementada (ver `relatorio.md`)

**Input**: Pedido do dono: "o papel de parede eu quero que a gente explore opções pois quero depois
adicionar um seletor [...] a minha ideia é fazer um sistema próprio pra controlar o papel de parede
[...] a ideia é que fique o mais fiel ao fundo do jogo. que não tem esse 'quadriculado' que a gente
adicionou". Decisões tomadas no mockup aprovado
(https://claude.ai/artifact/UW66HpHwKmEshV1CeJmWke; cópia em
`rien-OS-private/lab/mockups/papel-de-parede/index.html`):
- **fundo:** cena "Menu", sem grid e sem grão;
- **transição:** uma opção do usuário; de fábrica, a camuflagem (célula 24 px, rastro longo, falhas visíveis);
- **primeiro corte:** as quatro cenas e as imagens da pasta do usuário;
- **vídeo:** fica pro U6.

**Emenda de 2026-10-27, "A barra sobre o fundo" (US6):** o dono viu a 004 na VM e pediu que o efeito
pegasse a tela inteira: "o efeito não se propaga pro fundo como um todo, o fundo da topbar não é
afetado". A barra do topo deixa de pintar o próprio papel e passa a mostrar o papel de parede por
baixo, com um tom que acompanha o fundo. Aprovada pelo dono em 2026-10-27, pelo plano e pelo mockup
(`rien-OS-private/lab/mockups/papel-de-parede/index.html`, seção "the bar over the desktop"). Ela
substitui a FR-004 desta spec e a FR-002a da 001 na parte da barra (o HUD pintava a faixa de cima da
vinheta).

**Emenda de 2026-10-27 (2), "Contraste da barra" (decisão do dono, acabamento da 004):** o SC-011
falhava nas paletas aprovadas. O dono decidiu:
- uma opção nova, **Bar contrast** (Normal / High), em System Settings › Appearance (a 003), com
  Normal de padrão, trocando ao vivo (FR-030);
- **High**, tom papel: os textos secundários da barra (título, data, valores, tinta da aba apagada)
  usam a tinta principal no lugar da `ink2`, e a hora fica mais pesada; o tom claro ganha uma `ink2`
  mais clara, pra aba apagada chegar a 4,5:1 (FR-028);
- o SC-011 passa a valer pro **High nos dois tons** e pro **tom claro no Normal**; o tom papel no
  Normal é medido e relatado, sem ser critério;
- o aviso do Qt 6.12.0 ao abrir um popup é silenciado (FR-024).

**Emenda de 2026-10-27 (3), decisões do dono depois da medição:**
- **High = P2:** com a tinta principal, o High não chegava a 4,5:1 no tom papel (hora 2,57 na vinheta
  do canto, abas 3,78, imagem de meio-tom 1,60). O dono escolheu a P2: no tom papel, tinta
  `#2E2C27` e uma placa de papel (`#C9C5AB` a 55%) atrás dos textos da barra, só no High (FR-028).
  O Normal não muda.
- **Salvar sempre:** o que muda no popup de configurações continua depois de reiniciar o shell, num
  arquivo de estado comum (`$XDG_STATE_HOME/rien-os/settings.json`), que as specs 007 e 008 vão
  reusar (FR-031, `contracts/settings-state.md`). Revê a FR-018 da 003.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Um fundo igual ao dos menus do jogo (Priority: P1)

Ao entrar na sessão, o desktop mostra o fundo dos menus do jogo:
- papel bege, mais claro no centro e escurecendo nas bordas e nos cantos;
- arcos finos (alguns duplos) com o centro fora da tela;
- feixes de duas ou três diagonais curtas.

As linhas respiram devagar. Não há grid nem grão. A barra do topo continua fazendo parte da mesma
vinheta, sem emenda.

**Why this priority**: É o que o dono vê o tempo todo, e o fundo de hoje (com grid) não é fiel ao
jogo. Sozinha, esta história já resolve o pedido "por enquanto só o fundo".

**Independent Test**: Na VM, com dados de teste, tirar um screenshot de um workspace vazio e medir
as cores do centro, das bordas e dos cantos; conferir que não há padrão de grid; comparar lado a lado
com o mockup aprovado.

**Acceptance Scenarios**:

1. **Given** um workspace vazio, **When** o desktop aparece, **Then** o centro do fundo tem a cor do
   papel medida no jogo e as bordas e os cantos escurecem como a vinheta medida.
2. **Given** o fundo na tela, **When** se procura um padrão repetido de grid, **Then** não há nenhum.
3. **Given** o movimento ligado e sem dados de teste, **When** passam alguns minutos, **Then** os arcos
   e os feixes mudaram de posição suavemente; com dados de teste ou com o movimento desligado, ficam
   parados.

---

### User Story 2 - Escolher o papel de parede num seletor no tema do jogo (Priority: P1)

O usuário aperta um atalho e abre o seletor de papel de parede: um popup no centro, com o resto da
tela escurecido, no layout da tela de itens do jogo:
- **à esquerda:** a lista de papéis de parede, agrupada em cenas, imagens e vídeo;
- **no meio:** uma prévia ao vivo do que está em foco;
- **à direita:** o quadro de opções (monitor e transição) e as informações.

Enter aplica no monitor escolhido, ou em todos.

**Why this priority**: É o "sistema próprio" que o dono pediu, e é o que facilita comparar e
escolher.

**Independent Test**: Na VM, abrir pelo atalho e por comando de controle, navegar com teclas reais,
aplicar uma cena em todos os monitores e outra só num, e conferir pelo estado exportado e por
screenshots.

**Acceptance Scenarios**:

1. **Given** o desktop, **When** o usuário aperta o atalho do seletor, **Then** o popup abre com a
   lista, a prévia do item em foco e as opções; o papel de parede atual aparece marcado na lista.
2. **Given** o foco num item, **When** o usuário aperta ↑ ou ↓, **Then** a pipa pisca pro item novo e a
   prévia passa a mostrar ele, ao vivo.
3. **Given** o foco num item, **When** o usuário aperta Enter, **Then** o fundo de trás troca pelo item,
   com a transição escolhida, no monitor escolhido (ou em todos).
4. **Given** o foco na lista, **When** o usuário aperta →, **Then** o foco vai pras opções; ←/→ mudam o
   monitor e a transição; Esc volta pra lista; um segundo Esc fecha o seletor.
5. **Given** o item "Videos", **When** ele está em foco, **Then** aparece apagado, a prévia diz que vem
   depois e Enter não faz nada.

---

### User Story 3 - Transições à escolha, com a camuflagem de fábrica (Priority: P2)

Trocar de papel de parede nunca é um corte seco. O usuário escolhe a transição, e a escolha vale
tanto pro seletor quanto pra troca por comando:
- **camuflagem** (de fábrica): o fundo antigo ondula como ar quente pouco antes de uma onda chegar;
  cada quadradinho vira com um brilho na borda, entra pixelado e fica nítido; o contorno dele fica um
  tempo e some; de vez em quando um quadradinho falha por um quadro;
- **varredura:** o fundo novo entra da esquerda pra direita, com a borda desenhada como a régua do jogo;
- **quadradinhos:** o fundo novo aparece em quadradinhos, cada um precedido por um quadrado de tinta;
- **crossfade:** um fundo some enquanto o outro aparece.

**Why this priority**: A troca já funciona sem transição (US2); a transição é o acabamento que o dono
quer, e a camuflagem é o diferencial.

**Independent Test**: Na VM, sem dados de teste, trocar entre "Menu" e "Dark" com cada transição e
gravar uma sequência de quadros; conferir as etapas de cada uma nos quadros.

**Acceptance Scenarios**:

1. **Given** a transição de fábrica, **When** o fundo troca, **Then** a sequência de quadros mostra a
   refração antes da onda, os quadradinhos pixelados resolvendo, os contornos sumindo e, ao fim, o
   fundo novo limpo.
2. **Given** a transição trocada pra varredura, **When** o fundo troca, **Then** o novo entra da
   esquerda pra direita, com a borda de régua.
3. **Given** o movimento reduzido, ou dados de teste ativos, **When** o fundo troca, **Then** a troca é
   instantânea.

---

### User Story 4 - Usar as minhas imagens (Priority: P2)

O usuário põe imagens numa pasta de papéis de parede e elas aparecem no seletor, no grupo de
imagens, com miniatura. Aplicadas, cobrem a tela inteira sem distorcer. Por padrão, recebem o
filtro de papel (as cores puxadas pro tom do papel, mais a vinheta), que o usuário pode desligar
por imagem.

**Why this priority**: As cenas resolvem o fundo fiel (US1); as imagens são pra quem quer uma foto
sem sair do tema.

**Independent Test**: Na VM, pôr duas imagens de teste na pasta, abrir o seletor, aplicar cada uma
com e sem filtro e conferir os screenshots; adicionar uma terceira imagem com o seletor aberto e ver
que ela aparece.

**Acceptance Scenarios**:

1. **Given** duas imagens na pasta, **When** o seletor abre, **Then** as duas aparecem no grupo de
   imagens, com o nome do arquivo e a miniatura na prévia.
2. **Given** uma imagem aplicada, **When** a proporção dela é diferente da tela, **Then** ela cobre a
   tela toda, cortando as sobras, sem esticar.
3. **Given** o filtro de papel desligado pra uma imagem, **When** ela é aplicada, **Then** aparece com
   as cores originais.
4. **Given** um arquivo corrompido na pasta, **When** o seletor abre, **Then** ele não aparece e o log
   registra o motivo; o resto funciona.

---

### User Story 5 - Lembrar e controlar por comando (Priority: P3)

A escolha de cada monitor sobrevive a reiniciar o shell e a sessão. Também dá pra listar, aplicar,
avançar e voltar papéis de parede por comando, pra atalhos e scripts.

**Why this priority**: Sem lembrar, toda sessão volta pro padrão; o comando abre caminho pra atalhos,
mas o seletor (US2) já cobre o uso diário.

**Independent Test**: Na VM, aplicar "Dark" num monitor, reiniciar o shell e conferir; usar os
comandos de controle e conferir o estado exportado.

**Acceptance Scenarios**:

1. **Given** "Dark" aplicado no monitor 1, **When** o shell reinicia, **Then** o monitor 1 volta com
   "Dark" e os outros com o que tinham.
2. **Given** o comando "próximo", **When** ele roda, **Then** o monitor em foco troca pro próximo
   papel de parede da lista, com a transição escolhida.
3. **Given** um monitor que nunca recebeu escolha (recém-conectado), **When** ele aparece, **Then** usa a
   escolha "todos os monitores" ou, se não houver, a cena padrão.

---

### User Story 6 - A barra sobre o fundo (Priority: P1)

> Emenda aprovada pelo dono em 2026-10-27, pelo plano e pelo mockup.

A barra do topo não tem fundo próprio: o papel de parede (a cena, a imagem e as transições) aparece
embaixo dela, e os arcos e os feixes cruzam a faixa da barra, como no jogo. A cor da barra acompanha
o fundo do monitor dela:
- **tom papel** (as cores de hoje) nas cenas de papel e nas imagens claras;
- **tom claro** (texto claro, placas claras translúcidas) na cena Dark e nas imagens escuras.

Quando o fundo troca, a barra muda de tom junto com a transição, no momento em que ela passa pela
faixa da barra.

**Why this priority**: É o pedido do dono depois de ver a 004 na VM. Sem ela, a troca de fundo para
na barra e a faixa dela fica papel em cima de um fundo escuro.

**Independent Test**: Na VM, com dados de teste, aplicar cada cena e cada imagem de teste e conferir
pelo `hud dump` (tom) e por screenshots (a área vazia da barra igual ao fundo; o contraste do texto
medido nos pixels). Sem dados de teste, gravar rajadas da camuflagem Menu → Dark e da varredura.

**Acceptance Scenarios**:

1. **Given** a cena Menu, **When** o desktop aparece, **Then** os arcos e os feixes passam por baixo da
   barra, e a barra fica no tom papel.
2. **Given** a cena Menu, **When** o fundo troca pra Dark, **Then** a barra fica no tom claro, e a troca
   de tom acontece enquanto a transição cobre a faixa da barra.
3. **Given** uma imagem escura, **When** ela é aplicada, **Then** a barra fica no tom claro; numa imagem
   clara, no tom papel.
4. **Given** o movimento reduzido ou dados de teste ativos, **When** o fundo troca, **Then** o tom troca
   na hora.
5. **Given** dois monitores com fundos diferentes, **When** um deles troca, **Then** só a barra dele
   muda de tom.

### Edge Cases

- **Pasta de imagens inexistente ou vazia:** o grupo de imagens mostra só um aviso de onde pôr as
  imagens; nada quebra.
- **Imagem muito grande:** a miniatura e a prévia carregam reduzidas; o seletor não trava.
- **Nome de arquivo estranho** (espaços, aspas, acentos): aparece e aplica normalmente.
- **Imagem aplicada apagada da pasta:** na próxima sessão, aquele monitor volta pra cena padrão e o
  log registra.
- **Troca no meio de outra transição:** a nova começa a partir do que está na tela, sem pulo.
- **Monitores com escalas diferentes:** cenas e imagens ficam nítidas em cada um (1080 @1 e
  2560x1600 @1,25).
- **Movimento desligado** (`wallpaperMotion: false`): as cenas ficam paradas; as transições
  continuam, a não ser que o movimento reduzido esteja ligado.
- **Imagem ainda não medida** (US6): até a luminância da faixa de cima sair (alguns quadros depois de
  a imagem carregar), a barra fica no tom que tinha; depois segue a regra.
- **Troca no meio de outra** (US6): o tom parte de onde a barra estava e vai pro tom do fundo novo.
- **Janela flutuante arrastada pra cima da barra** (US6): aparece por trás das abas e dos textos,
  porque a barra fica na camada de cima e o Hyprland só reserva a faixa dela pras janelas lado a
  lado. Limitação aceita; a barra não pinta nada pra esconder a janela.

## Requirements *(mandatory)*

### Functional Requirements

**Fundo fiel (US1)**

- **FR-001**: A cena padrão ("Menu") MUST reproduzir o fundo dos menus do jogo medido em
  `docs/design-system.md` §6:
  - papel com vinheta radial: centro `#C8C3AC`, bordas `#A6A18D`, cantos `#8C8978`;
  - arcos finos, alguns duplos (dois círculos a ≈6–7 px), com o centro fora da tela;
  - feixes de 2–3 diagonais paralelas (≈42°) que começam e terminam na tela;
  - linhas em tinta a ≈15%.
- **FR-002**: O fundo MUST NOT ter grid nem grão (decisão do dono, 2026-10-27).
- **FR-003**: As linhas MUST respirar devagar (os arcos giram e os feixes deslizam pouco, num ciclo de
  minutos), seguindo a configuração `wallpaperMotion` que já existe, e param com dados de teste.
- **FR-004**: A barra do topo MUST continuar dentro da mesma vinheta do fundo, sem emenda (decisão da
  001). **Revisto pela emenda da US6 (2026-10-27):** a barra não pinta mais papel nem vinheta; o que
  aparece embaixo dela é o próprio papel de parede (FR-025), então a continuidade vale por
  construção.

**Catálogo e seletor (US2, US4)**

- **FR-005**: O catálogo MUST ter três tipos de papel de parede:
  - **cenas:** de fábrica "Menu", "Menu + rules", "Dark" e "Plain", definidas por parâmetros (cores,
    camadas, movimento), sem imagem;
  - **imagens:** os arquivos `jpg`, `png` e `webp` da pasta do usuário (padrão `~/Pictures/Wallpapers`,
    configurável);
  - **vídeos:** só listados, apagados, como "depois".
- **FR-006**: O seletor MUST abrir por um atalho da sessão (`SUPER + W`; na VM, `ALT + W`, research R11) e por comando de
  controle, como o popup da 003:
  - centrado no monitor em foco;
  - resto da tela escurecido, sem desfoque;
  - teclado só pra ele;
  - fecha com Esc ou com um clique fora.
- **FR-007**: O layout MUST seguir o mockup aprovado: título `WALLPAPER -Select`; lista à esquerda
  agrupada (SCENES, IMAGES, VIDEO) com a pipa; prévia ao vivo no meio, com o nome e uma descrição;
  quadro "Options" à direita, com Monitor e Transition (e, nas imagens, Paper filter, FR-010), mais
  Type, Layers, Motion e Now on; rodapé de teclas.
- **FR-008**: A navegação MUST seguir o padrão de duas colunas da 003:
  - lista: ↑/↓ movem, Enter aplica, → vai pras opções, Esc fecha;
  - opções: ↑/↓ movem, ←/→ mudam o valor, ← no primeiro valor volta pra lista, Esc volta;
  - o mouse move o foco, e clicar num item aplica;
  - a pipa fica parada, pisca na troca e fica clara na coluna sem foco.
- **FR-009**: Os itens aplicados MUST aparecer marcados na lista com o monitor em que estão (ou
  "ALL").
- **FR-010**: As imagens MUST cobrir a tela inteira sem distorcer (cortando as sobras) e carregar
  reduzidas na lista e na prévia. O filtro de papel vem ligado e pode ser desligado por imagem.
- **FR-011**: A pasta de imagens MUST ser observada: arquivos novos ou apagados aparecem ou somem do
  seletor sem reiniciar. Arquivos ilegíveis ficam de fora, com uma linha no log.
- **FR-012**: Nenhum nome de arquivo MUST passar por um interpretador de comandos. Nomes com espaços,
  aspas ou acentos funcionam.

**Transições (US3)**

- **FR-013**: Toda troca de papel de parede MUST usar a transição escolhida pelo usuário, uma de:
  camuflagem (de fábrica), varredura, quadradinhos ou crossfade. A escolha fica nas opções do seletor
  e numa configuração do usuário.
- **FR-014**: A camuflagem MUST ter, nesta ordem, por quadradinho:
  - refração do fundo antigo pouco antes da onda;
  - brilho na borda na hora da troca;
  - entrada pixelada que resolve até nítida;
  - contorno que fica e some ao longo do rastro;
  - falhas raras de um quadro (deslocamento de 1–2 px ou o fundo antigo).
  Os três parâmetros (célula, rastro, falhas) são configuráveis; de fábrica: célula 24 px, rastro
  longo (≈2,6 s) e falhas visíveis.
- **FR-015**: A varredura, os quadradinhos e o crossfade MUST seguir o mockup aprovado (≈0,9 s, ease
  in-out).
- **FR-016**: Com movimento reduzido ou dados de teste ativos, a troca MUST ser instantânea.
- **FR-017**: Uma troca no meio de outra MUST partir do que está na tela.

**Estado e controle (US5)**

- **FR-018**: A escolha por monitor (e a de "todos") e a transição MUST ser guardadas como estado do
  usuário e sobreviver a reiniciar o shell. Elas ficam fora dos arquivos de configuração do usuário,
  que o sistema nunca escreve (constituição III).
- **FR-019**: Comandos de controle MUST permitir: listar o catálogo, aplicar um item (num monitor ou em
  todos), ir pro próximo ou pro anterior no monitor em foco, abrir o seletor e exportar o estado (item
  por monitor, transição, transição em andamento).
- **FR-020**: Um monitor sem escolha própria MUST usar a escolha "todos"; sem ela, a cena padrão.
- **FR-021**: Com dados de teste, o catálogo MUST usar uma pasta de imagens de teste do próprio
  shell, pros screenshots saírem iguais.

**Design system, textos e qualidade**

- **FR-022**: As peças novas MUST entrar na galeria e no `docs/design-system.md`:
  - a cena de papel com seus parâmetros;
  - o filtro de papel;
  - cada transição;
  - o layout de lista + prévia + opções, reutilizável pros próximos menus.
- **FR-023**: Todo texto fixo MUST ficar em inglês, no lugar central de textos.
- **FR-024**: Abrir o seletor, navegar, aplicar com cada transição e fechar MUST deixar o log sem erro
  e sem aviso. **Revisto pela emenda (2), 2026-10-27:** o aviso do Qt 6.12.0 que todo popup loga ao
  abrir (`qt.qpa.wayland.textinput`, um bug da plataforma já corrigido no Qt dev) é silenciado, e só
  ele: `QT_LOGGING_RULES=qt.qpa.wayland.textinput.warning=false` no ambiente em que o `qs` inicia
  (o `//@ pragma Env` do `shell.qml` chega tarde demais pro logger do Quickshell 0.3.2; conferido na
  VM). A regra sai quando o Arch trouxer o Qt corrigido. O log fica com 0 avisos, sem exceção.

**A barra sobre o fundo (US6, emenda de 2026-10-27)**

- **FR-025**: A barra do topo MUST NOT ter fundo próprio: o papel de parede do monitor e as
  transições aparecem embaixo dela. Abas, faixas, medidores, textos e a régua pontilhada ficam por
  cima. Isso revê a FR-002a e a FR-008 da 001 só na barra (a barra era papel opaco com a faixa da
  vinheta).
- **FR-026**: O tom da barra MUST seguir o papel de parede do monitor dela:
  - cenas de papel (`menu`, `rules`, `plain`) → tom **papel**;
  - cena com `kind: "dark"` → tom **claro**;
  - imagem → a luminância média (0,2126 R + 0,7152 G + 0,0722 B, sRGB/255) da faixa de cima (a altura
    da barra mais 12 px, ≈40/540 da tela a 1080), medida na imagem como aparece (com o filtro de
    papel, se ligado), uma vez por imagem; abaixo de 0,45 → tom claro, senão papel.
- **FR-027**: Durante uma transição, as cores da barra MUST misturar do tom de antes pro tom novo
  (0 → 1, com `smoothstep`) no intervalo em que a transição cobre a faixa da barra:
  - camuflagem: a fração das células da faixa de cima já reveladas;
  - varredura: a posição da borda ÷ a largura;
  - quadradinhos: a fração dos quadradinhos das linhas de cima já começados;
  - crossfade: o progresso com ease.

  Com movimento reduzido ou dados de teste, a troca de tom MUST ser instantânea.
- **FR-028**: As duas paletas, em [r, g, b, a] (cada papel de cor da barra):

  | Papel | Uso | Papel (tom papel) | Claro (tom claro) |
  |---|---|---|---|
  | `ink` | texto principal, hora, tinta da aba normal, rótulos das leituras | 78,75,66,1 | 215,209,179,1 |
  | `ink2` | título, data, valores, tinta da aba apagada | 103,100,88,1 (High: 78,75,66,1) | 175,172,161,1 |
  | `rest` | placa da aba, faixas verticais | 177,171,147,1 | 215,209,179,0,16 |
  | `sel` | placa da aba em foco (e destacada) | 78,75,66,1 | 215,209,179,1 |
  | `selInk` | tinta da aba em foco | 215,209,179,1 | 78,75,66,1 |
  | `track` | trilho do medidor | 177,171,147,1 | 215,209,179,0,22 |
  | `fill` | preenchimento do medidor | 78,75,66,1 | 215,209,179,1 |
  | `rule` | régua pontilhada | 78,75,66,1 | 150,148,140,0,75 |
  | `alert` | estado crítico | `#8F3A30` | `#C0574A` |

  O tom papel é igual aos tokens de hoje. **Emenda (2), com a (3):** com Bar contrast = High, o tom
  papel usa a tinta `#2E2C27` em `ink`, `ink2` e `sel` (`Tokens.hudPaperHigh`), põe uma placa de
  papel `#C9C5AB` a 55% (`Tokens.hudHighPlate`) atrás do título, de cada leitura (rótulo, medidor e
  valor), da data e da hora, com 3 × 2 px de folga, e a hora sai em Bold no lugar de DemiBold. A
  placa some junto com o tom papel (alfa × (1 − tom)); o tom claro é o mesmo nos dois modos, com a `ink2` clareada de 150,148,140 pra
  175,172,161 (a aba apagada ia a 3,6–4,2:1 sobre a placa). Os componentes da barra (aba, barra de abas, medidor,
  régua e texto) recebem o tom como parâmetro, com 0 (papel) de padrão: a galeria, o popup da 003 e
  tudo que não é a barra MUST continuar idênticos, pixel a pixel.
- **FR-029**: O `hud dump` MUST mostrar, por monitor, o `tone` (`"paper"` ou `"light"`) e o `toneMix`
  (0 = papel, 1 = claro); o `wallpaper dump`, a luminância medida da imagem de cada monitor.
  **Emenda (2):** e o `contrast` (`"normal"` ou `"high"`).
- **FR-030** (emenda (2)): A opção **Bar contrast** (`Normal` / `High`) MUST aparecer em System
  Settings › Appearance, logo depois de "Top bar height", e trocar a barra na hora, com o popup
  aberto. O valor vem da configuração `barContrast` (`"normal"` / `"high"`, padrão `"normal"` no
  `defaults.json`, sobrescrito pelo `shell.json`), como as outras configurações do shell. **Emenda
  (3):** a troca pelo popup é salva no estado (`shell.barContrast`, FR-031) e vale mais que a config;
  o `settings reset` volta ao valor configurado.
- **FR-031** (emenda (3), decisão do dono de 2026-10-27, "salvar sempre"): Todo valor mudado no popup
  de configurações MUST continuar depois de reiniciar o shell. Um mecanismo comum guarda os valores
  em `$XDG_STATE_HOME/rien-os/settings.json` (nunca no `~/.config`): lido no início, escrito 250 ms
  depois da última mudança, de forma atômica, por cima da base (`shell.json` e `defaults.json`). O
  `settings reset` limpa o estado. Com fixtures, o arquivo não é lido nem escrito. O contrato
  (chaves, API, a marca `persist` do catálogo) está em `contracts/settings-state.md`, pra ser
  reusado pelas specs 007 e 008.

### Key Entities

- **Papel de parede:** id, tipo (cena, imagem, vídeo), nome, descrição; cena: parâmetros (cores,
  camadas, movimento); imagem: caminho e filtro de papel ligado/desligado.
- **Escolha:** pra cada monitor (pelo nome) e pra "todos", o id do papel de parede.
- **Transição:** o tipo e, pra camuflagem, célula, rastro e intensidade das falhas.
- **Tom da barra** (US6): por monitor, a mistura de 0 (papel) a 1 (claro) que a barra mostra agora;
  o tom de destino sai do papel de parede (cena) ou da luminância medida (imagem, guardada por
  caminho e por filtro ligado/desligado).

## Success Criteria *(mandatory)*

Cada critério diz qual evidência da VM o comprova (constituição IV).

- **SC-001**: Num workspace vazio, com dados de teste, as cores do centro, das bordas e dos cantos do
  fundo ficam a até 4 níveis (em 255) das medidas do jogo, e não há padrão repetido de grid. Evidência:
  screenshot e medição, em 1080 @1 e em 2560x1600 @1,25.
- **SC-002**: Com dados de teste, dois screenshots seguidos do fundo e do seletor aberto são idênticos.
  Evidência: os screenshots e a diferença.
- **SC-003**: As quatro cenas e duas imagens de teste aparecem no seletor e, aplicadas, no fundo.
  Evidência: um screenshot de cada, com o estado exportado.
- **SC-004**: Uma sequência de teclas reais (abrir, ↓ ×2, Enter, →, ↓, →, Esc, Esc) termina com o
  papel de parede e a transição esperados e o seletor fechado. Evidência: o estado exportado depois de
  cada tecla.
- **SC-005**: Cada uma das quatro transições, gravada em quadros, mostra as etapas da FR-014/FR-015 e
  termina com o fundo novo limpo. Evidência: as sequências de quadros.
- **SC-006**: A escolha de um monitor sobrevive a reiniciar o shell. Evidência: estado exportado antes
  e depois e screenshot.
- **SC-007**: Uma imagem adicionada à pasta com o seletor aberto aparece na lista em até 2 s, e uma
  imagem com nome cheio de espaços e aspas aplica normalmente. Evidência: estado exportado e
  screenshot.
- **SC-008**: O log fica sem erro e sem aviso de QML depois do roteiro inteiro. Evidência: o trecho do
  log e o lint limpo.
- **SC-009**: O custo de uma transição de camuflagem fica registrado no `lab/perf` (sem meta; a meta
  vem no U6). Evidência: o relatório da sessão.
- **SC-010**: O dono aprova o visual comparando com o mockup. Evidência: a aprovação.
- **SC-011** (US6, revisto pela emenda (2)): Todo texto da barra tem contraste ≥ 4,5:1 (o 5º percentil
  dos pixels da caixa do texto) contra os pixels atrás dele, nas 4 cenas e nas imagens de teste,
  **com Bar contrast = High nos dois tons, e com Normal no tom claro**. Com Normal no tom papel, o
  contraste é medido e relatado, sem ser critério. Evidência: medição nos screenshots (a cor do
  texto contra o fundo sem a barra, com a placa da aba por cima quando é uma aba), em 1080 e hidpi,
  nos dois modos.
- **SC-014** (emenda (3)): Sem fixtures, uma opção mudada por teclas reais no popup continua depois de
  reiniciar o `qs`; o único arquivo escrito fica em `~/.local/state/rien-os/`; o `settings reset`
  volta ao catálogo e à config, também depois de outro reinício. Evidência: `settings dump` e
  `hud dump` antes e depois, o arquivo de estado e a lista de arquivos escritos (`lab/check-004`).
- **SC-012** (US6): A área vazia da barra (sem abas, textos, medidores e régua) fica a ≤ 2 níveis (em
  255) da cena que está embaixo. Evidência: o mesmo fundo fotografado com a barra e sem ela, nas 4
  cenas e nas imagens de teste.
- **SC-013** (US6): O `hud dump` mostra `tone: "light"` na cena Dark e numa imagem de teste escura, e
  `"paper"` nas outras; as rajadas da camuflagem Menu → Dark e da varredura mostram a troca passando
  por baixo da barra e o tom virando quando ela chega na faixa. Evidência: os `dump`s e as rajadas.

## Assumptions

- **Onde roda:** só na VM (constituição I). O atalho vai na config do Hyprland da VM.
- **Sem ferramenta externa de papel de parede:** o próprio shell desenha o fundo na camada de fundo
  do compositor, como já faz desde a 001. Nada de `swww`, `hyprpaper` ou `awww`.
- **Mockup e medidas:** o mockup aprovado e a seção "Fundo (medido)" do design system são a
  referência visual. Nenhuma imagem do jogo entra no repositório; as imagens de teste são geradas
  pelo projeto.
- **Fora do escopo:**
  - papel de parede em vídeo (U6);
  - baixar papéis de parede da internet;
  - editar os parâmetros de uma cena pela interface;
  - a opção de transição dentro do popup de configurações da 003, que hoje só usa dados de teste;
    ela entra quando a 003 ligar opções reais.
- **Ordem sugerida:** a US1 pode ir antes, sozinha, porque substitui o fundo com grid da 001; as
  outras dependem da moldura de popup da 003.
- **Desempenho:** implementar antes de otimizar (constituição VII). A camuflagem é a parte mais cara;
  o custo dela é medido aqui e otimizado no U6.
