# Feature Specification: Menus do jogo (efeitos medidos e tela cheia)

**Feature Branch**: `013-menus-do-jogo` (sai da `main`; a implementação começa depois da 008 mesclada,
porque as duas mexem nas mesmas peças do design system)

**Created**: 2026-10-31

**Status**: Rascunho, com 3 perguntas pro dono

**Input**: Em 31.10 o dono disse: "a gente precisa adicionar algumas coisas pra deixar o negócio mais
fiel […] tou sentindo muita originalidade em alguns efeitos e eu gosto disso, mas eu queria outras coisas
mais próximas do game". Ele também pediu duas versões dos menus que já existem, em janela flutuante e
em tela cheia, adaptando o que já existe sem refazer: "pra conseguir dar fidelidade com os efeitos do
jogo e seguir adaptando". E fixou a regra do texto que não cabe: rola até o fim, volta pro começo e
rola de novo.

Quatro frentes mediram os vídeos do jogo e o nosso código. As análises ficam fora do repositório, em
`~/Videos/nier-ref/menus/analise/`:
- A: a UI no jogo;
- B: o menu principal;
- C: os sons;
- D: o inventário das nossas telas.

O protótipo interativo é o artefato "YoRHa-OS Protótipo: menus do jogo". O dono testou e copiou as
escolhas dele (privado: `lab/mockups/menus-jogo/escolhas-2026-10-31.md`):
- os 12 efeitos no modo do jogo;
- o texto rolando e o fundo parado;
- os números padrão;
- a janela como modo de tela.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navegar nos menus com o movimento do jogo (Priority: P1)

O usuário abre o menu de pausa e anda pelas listas, pelas abas e pelas colunas. Cada movimento tem o
jeito do jogo:
- **seleção:** o fundo escuro da linha cresce da esquerda e o texto clareia só onde ele passou, e a
  linha selecionada "respira";
- **ponteiro:** some numa linha e aparece na outra, sem deslizar;
- **troca de aba:** o título digita e as linhas entram em cascata, digitando;
- **rodapé:** a ajuda de teclas entra deslizando;
- **sublista:** uma sublista nova entra escalonada.

**Why this priority**: É o que o usuário faz o tempo todo. É também onde o dono sentiu a falta do
jogo.

**Independent Test**: Na VM, com uma rajada de quadros (`lab/burst`) de cada movimento:
- descer uma linha;
- trocar de coluna;
- trocar de aba;
- trocar de categoria nas configurações.

Os tempos medidos batem com os do jogo (FR-001 a FR-008), com tolerância de 1 quadro.

**Acceptance Scenarios**:

1. **Given** o menu aberto numa lista, **When** a seleção desce uma linha, **Then** o fundo da linha
   nova cresce da esquerda (OutQuart, 0,40 s) enquanto o da antiga recolhe (0,20 s), e o texto fica
   claro só onde o fundo já passou.
2. **Given** a seleção parada numa coluna com foco, **When** o tempo passa, **Then** a linha
   selecionada e a aba aberta clareiam e voltam num ciclo de 1,333 s.
3. **Given** o foco numa lista, **When** a seleção muda de linha, **Then** o ponteiro não desliza: some
   na antiga e aparece na nova. **When** o foco passa pra outra coluna, **Then** o ponteiro da coluna
   nova entra deslizando 25 px pra direita, e a coluna sem foco fica só com o ":".
4. **Given** uma aba aberta, **When** o usuário troca de aba, **Then** o conteúdo some (133 ms), fica
   vazio (67 ms), o título digita (~20 letras/s, com a letra da ponta sorteada da própria palavra) e
   as linhas entram em cascata (33 ms entre elas) com os rótulos digitando (~28 letras/s).
5. **Given** a ajuda do rodapé, **When** ela muda, **Then** o texto novo entra inteiro, desfocado, e
   desliza 20 px da esquerda (0,3 s).
6. **Given** as configurações, **When** o usuário troca de categoria, **Then** as opções novas entram
   com fade e um deslize de 10 px, escalonadas (34 ms).

---

### User Story 2 - Abrir, fechar e confirmar como no jogo (Priority: P1)

Abrir o menu mostra a grade e os triângulos do jogo, e o conteúdo se monta em ordem. Fechar desfaz os
triângulos. Um diálogo de confirmação escurece a tela como o do jogo. O fundo do menu fica parado.

**Why this priority**: É a primeira coisa que se vê do menu, e o momento mais característico do jogo.

**Independent Test**: `lab/burst` da abertura, do fechamento e do diálogo de "Shut down" na VM, nos dois
modos de tela.

**Acceptance Scenarios**:

1. **Given** o menu fechado, **When** ele abre, **Then** aparece uma grade clara com franja de cor (3
   quadros) e, em 0,30 s, triângulos de 240×120 viram papel em ordem aleatória (alguns passando por um
   quadro escuro). Depois vêm, em ordem:
   - as réguas, que se desenham;
   - as abas, em cascata;
   - o título, que digita;
   - os cartões, as linhas, o rodapé e o ponteiro.

   Tudo fica completo em ~1,5 s.
2. **Given** o menu aberto, **When** ele fecha, **Then** os triângulos somem em ordem aleatória em
   0,23 s, levando junto o conteúdo que está em cada um.
3. **Given** uma ação que sai do menu (abrir um app, ir pra uma janela, uma ação de energia), **When**
   o usuário confirma, **Then** a seleção estica ~2× e apaga (0,12 s) antes do fechamento.
4. **Given** POWER › Shut down, **When** o diálogo abre, **Then** a tela escurece até 80% (170 ms), a
   faixa do título aparece primeiro e o corpo entra em 3–4 quadros, com "Cancel" selecionado. **When**
   ele fecha, **Then** sai com um borrão e o escurecimento volta em 170 ms.
5. **Given** um menu aberto, **When** o tempo passa, **Then** o fundo de papel não se mexe.

---

### User Story 3 - O texto que não cabe rola (Priority: P2)

Um nome de janela, um valor de opção ou um título de cartão maior que o espaço não é cortado com "…":
ele rola até o fim, espera, volta pro começo e rola de novo. O que cabe fica parado.

**Why this priority**: É regra do dono, e os títulos de janela e os valores longos são comuns.

**Independent Test**: Uma janela de título longo em WINDOWS e um valor longo nas configurações. Um
`lab/burst` mostra a rolagem e as pausas.

**Acceptance Scenarios**:

1. **Given** um texto maior que o espaço, **When** ele aparece, **Then** fica parado 1,0 s, rola até o
   fim a 60 px/s, fica parado 1,0 s e volta pro começo, sem parar.
2. **Given** um texto que cabe, **When** ele aparece, **Then** fica parado.

---

### User Story 4 - Escolher janela ou tela cheia (Priority: P2)

Em Configurações › Appearance, a opção "Menu presentation" escolhe entre o painel flutuante (como hoje,
o padrão) e a tela cheia (como o jogo). A troca vale na hora, inclusive com o menu aberto.

**Why this priority**: O dono quer as duas versões. O padrão é a janela, que ele escolheu no
protótipo.

**Independent Test**: Na VM, trocar a opção com o menu aberto e tirar screenshots das 4 abas, do
seletor de papel de parede e do text log nos dois modos e nos dois perfis.

**Acceptance Scenarios**:

1. **Given** "Floating panel", **When** um menu abre, **Then** ele ocupa o painel de 84% sobre o desktop
   escurecido, como hoje, e os efeitos acontecem dentro do painel.
2. **Given** "Full screen", **When** um menu abre, **Then** o papel cobre a tela toda e as colunas usam
   a largura extra. As letras e as linhas ficam do mesmo tamanho que no modo janela, nada fica 19% maior.
3. **Given** um menu aberto, **When** o usuário troca a opção, **Then** o menu passa pro outro modo sem
   fechar, mantendo a aba, a seleção e o foco.
4. **Given** a tela cheia, **When** chega uma notificação crítica ou o OSD de volume, **Then** ela
   aparece por cima do menu.

---

### User Story 5 - Manter o jeito atual como alternativa (Priority: P3)

Quem preferir o movimento de hoje pode voltar a ele nas configurações. É a regra do dono: toda
alternativa vira opção, e a recomendada fica como padrão.

**Why this priority**: É a regra de sempre, mas o padrão já entrega o pedido.

**Independent Test**: Trocar a opção e conferir que o movimento volta ao da 007 (varredura de 150 ms,
pipa piscando, fade de abertura de 150 ms e o resto na hora).

**Acceptance Scenarios**:

1. **Given** a alternativa atual escolhida, **When** o usuário navega, **Then** o menu se mexe como na
   007. [NEEDS CLARIFICATION: um interruptor só pra todos os efeitos ("Menu motion: Game / Classic"),
   um por efeito, ou nenhum (só o jogo, mais o "Reduce motion")?]

---

### Edge Cases

- **Teclas rápidas:**
  - três Tabs seguidos levam três abas adiante, e uma troca nova corta a anterior;
  - durante a abertura, uma troca de aba assume no lugar da montagem;
  - durante o fechamento (0,23 s), as teclas são ignoradas.
- **Reduce motion** (opção que já existe): tudo vai direto pro estado final. Não há triângulos,
  digitação, cascata, pulso, deslize nem crossfade, e o texto que não cabe volta a ser cortado com
  "…".
- **Navegar durante a digitação:** a linha termina de aparecer na hora certa e não fica pela metade.
- **Tela cheia em telas diferentes de 16:9:**
  - em ultrawide, as colunas têm um limite de largura e o conteúdo fica centralizado;
  - no notebook, 2560×1600 com escala 1,25.
- **Text log com 100 entradas:** a lista sob demanda continua abrindo em menos de 0,3 s (SC-005 da
  008), mesmo com a cascata.
- **Seleção sobre um item desabilitado:** o fundo e o texto usam as cores apagadas.
- **Um texto rolando que fica selecionado:** continua rolando, com as cores da seleção.

## Requirements *(mandatory)*

### Functional Requirements

Os números vêm dos vídeos do jogo (vídeo 1 a 30 quadros/s, ±33 ms; vídeo 2 a ~59 quadros/s) e são os
que o dono aprovou no protótipo.

- **FR-001** (seleção): o fundo da linha selecionada MUST crescer da esquerda pra direita em 0,40 s
  (OutQuart). O da linha anterior MUST recolher em 0,20 s ao mesmo tempo. O texto, o quadrado e os
  valores MUST ficar claros só onde o fundo já passou.
- **FR-002** (pulso): a linha selecionada da coluna com foco e a aba aberta MUST clarear e voltar num
  ciclo de 1,333 s (subida de ~0,35 s, topo curto, descida de ~0,32 s, repouso). O ciclo recomeça
  depois que a seleção assenta.
- **FR-003** (ponteiro): o ponteiro MUST NOT deslizar entre linhas:
  - ao trocar de linha, some na antiga (~0,18 s) enquanto aparece na nova (~0,15 s);
  - ao ganhar foco, entra desfocado e desliza 25 px pra direita;
  - na coluna sem foco, MUST mostrar só o ":".
- **FR-004** (título): ao trocar de tela, o título antigo MUST sumir em 100 ms, ficar 200 ms vazio e o
  novo MUST digitar a ~20 letras/s, com uma letra sorteada do próprio texto na ponta e sem cursor.
- **FR-005** (cascata): ao montar uma lista, as linhas MUST entrar uma a uma, 33 ms entre elas, com os
  rótulos digitando a ~28 letras/s (o selecionado a ~20). O rodapé, o texto dos diálogos e os cartões
  de descrição MUST NOT digitar.
- **FR-006** (troca de aba): o conteúdo MUST sumir em 133 ms, ficar 67 ms vazio e se montar de novo
  (FR-004, FR-005). Os cartões que as abas têm em comum ficam parados. Uma troca nova MUST cortar a que
  está em andamento.
- **FR-007** (rodapé): a ajuda de teclas nova MUST entrar inteira, desfocada, com a opacidade em 130 ms
  e um deslize de 20 px da esquerda em 300 ms.
- **FR-008** (trocar de nível):
  - uma sublista nova MUST entrar com fade e deslize de 10 px, escalonada (34 ms por linha, 170 ms,
    desacelerando);
  - uma ação que sai do menu MUST esticar a seleção ~2× e apagá-la em 120 ms antes do fechamento.
- **FR-009** (abrir e fechar):
  - **abrir:** MUST mostrar a grade (100 ms, com franja de cor), depois os triângulos de 240×120 virando
    papel em ordem aleatória (300 ms, ~30% passando por um quadro escuro) e depois o conteúdo em ordem:
    réguas, abas, título, cartões, linhas, rodapé e ponteiro;
  - **fechar:** os triângulos MUST sumir em ordem aleatória em 230 ms;
  - **no modo janela:** os triângulos e a grade ficam dentro do painel.
- **FR-010** (diálogo):
  - **abrir:** a tela MUST escurecer até 80% em 170 ms; a faixa do título MUST aparecer no primeiro
    quadro e o corpo em 3–4 quadros, sem escalar nem deslizar; a opção segura ("Cancel") vem
    selecionada;
  - **fechar:** com um borrão, e o escurecimento volta em 170 ms.
- **FR-011** (fundo): com um menu aberto, o papel do fundo MUST ficar parado.
- **FR-012** (texto que não cabe): um texto maior que o espaço MUST rolar:
  - parado 1,0 s;
  - rola até o fim a 60 px/s;
  - parado 1,0 s;
  - volta pro começo, e o ciclo repete.

  Isso vale pros rótulos das linhas, os valores das opções, os títulos dos cartões e as linhas de
  informação. Um texto que cabe MUST ficar parado e sem "…".
- **FR-013** (modos de tela): Configurações › Appearance MUST ter a opção "Menu presentation", com
  "Floating panel" (padrão) e "Full screen".
  - **Escala:** a mesma nos dois modos (altura da tela / 1080).
  - **Troca:** ao vivo, sem fechar o menu e sem perder a aba, a seleção ou o foco.
  - **Persistência:** a escolha fica salva como as outras opções.
- **FR-014** (onde vale): FR-001 a FR-013 MUST valer:
  - no menu de pausa (APPS, WINDOWS, SYSTEM e POWER);
  - nas configurações;
  - no seletor de papel de parede;
  - no text log (depois da 008);
  - nos diálogos de confirmação.

  A barra, as notificações, o OSD e o papel de parede MUST NOT mudar. Em tela cheia, as notificações
  críticas e o OSD MUST aparecer por cima do menu.
- **FR-015** (alternativa): o movimento atual (da 007) MUST continuar disponível como opção.
  [NEEDS CLARIFICATION: um interruptor só, um por efeito, ou nenhum? Ver a US5.]
- **FR-016** (reduce motion): com "Reduce motion" ligado, todos os efeitos MUST ir direto pro estado
  final, e o texto que não cabe MUST ser cortado com "…".
- **FR-017** (sem regressão): parado, o modo janela MUST ficar igual às evidências atuais da 003, 004,
  007 e 008, fora os pontos que os efeitos mudam de propósito. Esses pontos ficam listados no
  relatório: o ":" na coluna sem foco e o texto rolando no lugar do "…".
- **FR-018** (desempenho): as transições MUST manter a fluidez (SC-002) nos dois modos, e um menu
  parado MUST NOT gastar mais CPU do que hoje, fora o pulso e o texto rolando.

## Success Criteria *(mandatory)*

Cada critério diz a evidência que o comprova (constituição, princípio IV), sempre dentro do `lab/perf`.

- **SC-001**: Cada movimento de FR-001 a FR-012 tem os tempos dentro de ±1 quadro (33 ms) do jogo, nos
  perfis 1080 e hidpi. *Evidência:* um `lab/burst` por movimento, com a folha de quadros e os tempos.
- **SC-002**: Em 95% dos quadros das transições, a tela fica a 30 quadros/s ou mais na VM, nos dois
  modos e nos dois perfis. *Evidência:* a medição dos quadros durante um roteiro fixo (abrir, 3 trocas
  de aba, 6 linhas, diálogo), como o botão "medir" do protótipo.
- **SC-003**: A troca entre janela e tela cheia funciona com o menu aberto, mantendo aba, seleção e foco.
  *Evidência:* screenshots das 4 abas, do seletor e do log nos dois modos, e o `dump` do estado antes e
  depois.
- **SC-004**: Nada regride. *Evidência:* os roteiros da 003, 004, 007 e 008 verdes nos dois perfis
  (com os ajustes de FR-017 explicados no relatório).
- **SC-005**: Teclas rápidas não travam nem perdem nada. *Evidência:* um roteiro com `lab/key`:
  - 3 Tabs seguidos levam 3 abas adiante;
  - um Tab durante a abertura acerta o título;
  - Esc durante a montagem fecha o menu.
- **SC-006**: "Reduce motion" desliga tudo. *Evidência:* rajadas que mostram o estado final já no
  primeiro quadro.
- **SC-007**: O dono vê na janela da VM, nos dois modos, e aprova. *Evidência:* a aprovação dele.

## Assumptions

- **A referência visual é o protótipo** ("YoRHa-OS Protótipo: menus do jogo"). O que estiver nele e não
  estiver aqui segue o protótipo.
- **Sons:** fora desta spec. Vão numa spec própria, com:
  - os sons nossos como padrão;
  - volume e liga/desliga;
  - a "pasta de sons" pra quem tem o jogo de PC.

  No lab, os recortes provisórios continuam fora do git.
  [NEEDS CLARIFICATION: confirmar que os sons ficam pra uma spec separada.]
- **Escolhas com muitos valores** (a janelinha do jogo, que abre colada à direita da linha, e a
  seleção de várias opções pra configurações que são listas): fora desta spec, por enquanto.
  [NEEDS CLARIFICATION: entram aqui como um item a mais, ou depois?]
- **Nenhum material do jogo entra no repositório** (imagens, fontes, sons): os números foram medidos e
  o desenho é nosso.
- **A 008 entra na `main` antes da implementação.** Se a 010 tocar as mesmas peças, ela vem depois ou
  em paralelo, só onde não conflita.
- **O text log como 5ª aba do menu de pausa** fica pra depois. Aqui ele continua um popup próprio.
- **Os números podem ser ajustados** depois que o dono vir na VM, sem uma spec nova.
