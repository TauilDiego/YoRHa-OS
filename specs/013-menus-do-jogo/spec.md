# Feature Specification: Menus do jogo (efeitos medidos e tela cheia)

**Feature Branch**: `013-menus-do-jogo` (sai da `main`; a implementação começa depois da 008 mesclada,
porque as duas mexem nas mesmas peças do design system)

**Created**: 2026-10-31

**Status**: Aprovada pelo dono em 31.10 ("vai manda bala"), com a aba LOG e o ponteiro atual. Em 31.10 ele decidiu: só o movimento do jogo, e sons e a janelinha de escolhas entram nesta spec ("faz tudo junto nessa")

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
- **ponteiro:** continua como hoje, a nossa pipa piscando ao mudar de linha (escolha do dono no
  protótipo);
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
3. **Given** o foco numa lista, **When** a seleção muda de linha, **Then** o ponteiro se comporta como
   na 007: some (120 ms), pula pra linha nova e aparece (120 ms). Na coluna sem foco, ele fica claro e
   parado.
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

### User Story 5 - Os sons da interface (Priority: P2)

Mover o cursor, confirmar, voltar, abrir e fechar o menu, trocar de aba, confirmar um diálogo e receber
uma notificação têm som, no caráter dos sons do jogo:
- curtos e agudos, construídos com clique e brilho, sem grave;
- seco pra ação repetida e com cauda pra evento importante.

Os sons são nossos, sintetizados a partir das medidas da frente C. Quem tem o jogo de PC pode apontar
uma pasta com os sons originais extraídos da própria cópia, pra uso pessoal.

**Why this priority**: O dono pediu tudo junto. O som completa a sensação do jogo, mas o menu funciona
sem ele.

**Independent Test**: Na VM, gravar a saída de áudio (o monitor do sink nulo) enquanto um roteiro aperta
as teclas. Cada evento toca o som certo no tempo certo, e as opções de volume e de desligar funcionam.

**Acceptance Scenarios**:

1. **Given** os sons ligados, **When** o cursor anda numa lista, **Then** toca o tique curto (~30 ms)
   a cada passo, inclusive ao mudar um valor.
2. **Given** os sons ligados, **When** o usuário confirma, volta, abre ou fecha o menu, troca de aba ou
   confirma um diálogo, **Then** toca o som de cada evento:
   - confirmar: o brilho com cauda;
   - voltar: o tique mais grave;
   - abrir: o chiado de abertura;
   - fechar: o chiado ao contrário;
   - trocar de aba: o som de aba;
   - confirmar o diálogo: as duas notas subindo.
3. **Given** uma notificação normal ou crítica, **When** ela chega, **Then** toca o brilho
   correspondente. Com "não perturbe" ou em tela cheia segurada (regras da 008), ela não toca.
4. **Given** Configurações › Sound, **When** o usuário desliga os sons da interface ou baixa o volume
   deles, **Then** isso vale na hora. Não há som de digitação (decisão do dono, 01.11; abaixo).
5. **Given** uma pasta de sons escolhida, **When** um evento tem um arquivo com o nome dele lá, **Then**
   toca esse arquivo. **When** não tem, **Then** toca o som nosso.

---

### User Story 6 - Escolher numa janelinha, como no jogo (Priority: P2)

Uma opção com muitos valores (rede, saída de som, layout de teclado) abre uma janelinha colada à
direita da linha, como o menu de opções do jogo. A tela escurece, o ponteiro passa pro lado direito,
apontando pra esquerda, e a lista de valores aparece. As configurações que são listas de coisas (os
layouts de teclado ativos ao mesmo tempo, por exemplo) usam a mesma janelinha com quadradinhos
marcáveis.

**Why this priority**: O dono pediu. Cicla ◂ ▸ por dez valores é pior que escolher numa lista.

**Independent Test**: Na VM, abrir Configurações › Network › Network e Keyboard › Layouts. Escolher um
valor, marcar e desmarcar dois layouts, cancelar com Esc, e conferir o estado com o `dump`.

**Acceptance Scenarios**:

1. **Given** uma opção com mais de 3 valores, **When** o usuário aperta Enter nela, **Then**:
   - a tela escurece até 80% em 170 ms;
   - a janelinha aparece colada à direita da linha, com fade e desfoque em ~3 quadros;
   - o ponteiro fica no lado direito, apontando pra esquerda, no valor atual.
2. **Given** a janelinha aberta, **When** o usuário escolhe um valor com Enter (ou clique), **Then** ela
   fecha, o valor muda e o escurecimento volta em 170 ms. **When** aperta Esc ou clica fora, **Then**
   fecha sem mudar nada.
3. **Given** uma configuração de lista (Keyboard › Layouts), **When** a janelinha abre, **Then** cada
   valor tem um quadradinho. Enter marca ou desmarca, e o fechamento guarda o conjunto. Pelo menos um
   fica sempre marcado.
4. **Given** uma opção com até 3 valores, **When** o usuário mexe nela, **Then** continua o ◂ ▸ de
   hoje.
5. **Given** a janelinha aberta, **When** o texto de um valor não cabe, **Then** ele rola (US3).

---

### User Story 7 - Som no boot e no login (Priority: P3)

Ao ligar, quando a placa de som fica pronta (uns 2–4 s depois, durante a lista de checagens), toca o
som de "sistema iniciando". A tela de login tem sons próprios:
- a entrada com glitch;
- mover na lista de usuários;
- confirmar;
- a senha errada;
- Reboot e Shut down.

Quando o desktop aparece depois do login, toca um som curto de confirmação.

**Why this priority**: O dono pediu ("se tu conseguir adicionar o som no boot tu é um monstro"). É o
mais arriscado da spec, porque mexe no boot e no módulo da 011.

**Independent Test**: A VM ganha uma placa de som emulada, com a saída gravada num arquivo no host. Um
boot do zero até o desktop mostra cada som no momento certo, e o `lab/011/boot-timing` mostra que o boot
não ficou mais lento.

**Acceptance Scenarios**:

1. **Given** um boot do zero com o módulo instalado, **When** a placa de som fica pronta, **Then** toca
   o som de início uma vez. O Plymouth continua igual e o áudio normal do sistema sobe depois sem erro.
2. **Given** a tela de login, **When** ela entra, o usuário move na lista, confirma ou erra a senha, ou
   escolhe Reboot ou Shut down, **Then** toca o som de cada evento.
3. **Given** um login certo, **When** o desktop aparece, **Then** toca o som de entrada uma vez.
4. **Given** a última sessão saiu com o som mudo, **When** o computador liga, **Then** nenhum som de boot
   ou de login toca. **Given** um volume salvo, **Then** os sons seguem esse volume. **Given** nenhuma
   informação salva, **Then** tocam baixo (30%).

---

### User Story 8 - O histórico como aba do menu (Priority: P3)

O text log da 008 (o histórico das notificações) vira a aba LOG do menu de pausa, entre WINDOWS e
SYSTEM. Com isso, o menu reúne apps, janelas, histórico, sistema e energia. SUPER+N e o clique no
contador da barra abrem o menu direto na aba LOG.

**Why this priority**: O dono aprovou. É barato, porque a tela do log já foi feita pra viver dentro do
menu.

**Independent Test**: Na VM, abrir o menu com SUPER+N (ALT+N no lab) e pelo contador da barra, e
navegar pelo log como na 008. Os roteiros da 008 passam com o log dentro do menu.

**Acceptance Scenarios**:

1. **Given** o desktop, **When** o usuário aperta SUPER+N ou clica no contador, **Then** o menu de pausa
   abre na aba LOG.
2. **Given** o menu aberto em outra aba, **When** o usuário troca até LOG, **Then** o histórico aparece
   com a troca de aba do jogo (FR-006), e a lista, a prévia e as opções funcionam como na 008.
3. **Given** a aba LOG, **When** o usuário fecha o menu, **Then** as notificações vistas contam como
   lidas, como na 008.

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
- **Colunas na tela cheia:** em todas as abas, a coluna da esquerda fica na margem do título, a do
  meio fica no meio e o card da direita termina na ponta da régua, como nos frames do jogo (na
  SYSTEM: categorias, opções e descrição).
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
- **FR-003** (ponteiro): o ponteiro MUST continuar como na 007, por escolha do dono no protótipo (E4
  "Atual"):
  - a pipa nossa, parada;
  - ao trocar de linha, ela pisca: some em 120 ms (ease-in), pula e aparece em 120 ms (ease-out);
  - na coluna sem foco, fica clara e não pisca.

  O ponteiro do jogo (o cruzamento e o ":") não entra.
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
- **FR-015** (sem alternativa): o movimento do jogo MUST ser o único. O da 007 (varredura de 150 ms,
  pipa piscando, o resto na hora) sai e não fica como opção. É decisão do dono em 31.10: "deixa tudo
  como padrão do jogo, descarta o resto". A única variação é o "Reduce motion" (FR-016).
- **FR-016** (reduce motion): com "Reduce motion" ligado, todos os efeitos MUST ir direto pro estado
  final, e o texto que não cabe MUST ser cortado com "…".
- **FR-017** (sem regressão): parado, o modo janela MUST ficar igual às evidências atuais da 003, 004,
  007 e 008, fora os pontos que os efeitos mudam de propósito. Esses pontos ficam listados no
  relatório, como o texto rolando no lugar do "…".
- **FR-018** (desempenho): as transições MUST manter a fluidez (SC-002) nos dois modos, e um menu
  parado MUST NOT gastar mais CPU do que hoje, fora o pulso e o texto rolando.
- **FR-019** (sons, eventos): a interface MUST tocar um som em cada um destes eventos:
  - mover o cursor;
  - mudar um valor;
  - confirmar;
  - voltar;
  - abrir e fechar um menu;
  - trocar de aba;
  - confirmar um diálogo;
  - abrir e escolher na janelinha;
  - notificação normal e crítica;
  - passo do OSD.

  O mapa dos eventos segue a frente C (`C/sons.md` §4).
- **FR-020** (sons, padrão): os sons padrão MUST ser nossos, sintetizados pelas receitas da frente C,
  gerados no lab e versionados no repositório. Nenhum arquivo de som do jogo MUST entrar no
  repositório.
- **FR-021** (sons, pasta própria): uma opção MUST permitir apontar uma pasta de sons. Um arquivo com o
  nome do evento nessa pasta MUST substituir o som nosso daquele evento, e o que faltar MUST continuar
  com o nosso. A documentação MUST explicar, com links, como extrair os sons da própria cópia de PC do
  jogo (guias e ferramentas da comunidade), sem nunca linkar arquivos prontos.
- **FR-022** (sons, opções): Configurações › Sound MUST ter:
  - "Interface sounds" (ligado por padrão);
  - o volume deles (padrão 40%);
  - ~~"Typing sound" (desligado por padrão)~~: **sem som de digitação** (decisão do dono, 01.11:
    "acho bom não ter som de digitação de forma alguma"). Nenhuma letra digitada toca som, e não há
    opção pra ligar. Ele pode voltar depois como opção, se o dono pedir;
  - a pasta de sons (padrão: os nossos).

  Tudo MUST valer na hora e ficar salvo.
- **FR-023** (sons, regras): os sons MUST respeitar o volume e o mudo do sistema. Os sons de
  notificação MUST respeitar o "não perturbe" e a tela cheia segurada da 008. "Reduce motion" MUST NOT
  desligar os sons.
- **FR-024** (sons, tempo): o som MUST começar no máximo 50 ms depois da ação. Sons repetidos (cursor
  segurado, digitação) MUST NOT se acumular nem cortar a interface.
- **FR-025** (janelinha): uma opção com mais de 3 valores MUST abrir, com Enter, uma janelinha colada à
  direita da linha, com a lista de valores. A janelinha:
  - escurece a tela até 80% em 170 ms;
  - aparece com fade e desfoque em ~3 quadros;
  - põe o ponteiro do lado direito, apontando pra esquerda.

  ↑↓ movem, Enter escolhe, Esc e o clique fora cancelam. ←→ na linha MUST continuar mudando o valor
  direto.
- **FR-026** (várias opções): uma configuração de lista MUST usar a mesma janelinha com quadradinhos
  marcáveis. Enter marca ou desmarca; o fechamento guarda; pelo menos um valor MUST ficar marcado. A
  primeira configuração assim é Keyboard › Layouts (os layouts ativos, trocados por um atalho).
- **FR-027** (janelinha, limites):
  - perto da borda de baixo, a janelinha MUST subir pra caber;
  - com muitos valores, ela MUST rolar em linhas inteiras;
  - ela MUST seguir FR-001 a FR-012 (seleção, pulso, ponteiro, texto que rola);
  - nos dois modos de tela, ela MUST ficar dentro do menu.
- **FR-028** (som de boot): o módulo de boot e login (da 011) MUST tocar o som de início uma vez,
  quando a placa de som fica pronta, direto na placa e sem esperar o áudio da sessão. Ele MUST terminar
  antes do áudio normal do sistema assumir e MUST NOT impedir que ele suba. O Plymouth MUST NOT mudar.
- **FR-029** (sons do login): o tema de login MUST tocar os sons dos seus eventos, com o mesmo mapa e o
  mesmo caráter de FR-019:
  - a entrada com glitch;
  - mover na lista;
  - confirmar;
  - a senha errada;
  - Reboot e Shut down.
- **FR-030** (som de entrada): ao abrir o desktop depois do login, MUST tocar o som de entrada uma vez.
- **FR-031** (volume no boot): os sons de boot e de login MUST seguir o volume e o mudo salvos da última
  sessão do último usuário que entrou. Sem informação, MUST tocar a 30%.
- **FR-032** (opção): Configurações › Sound MUST ter "Boot and login sounds" (ligado por padrão), e o
  `config` do tema de login MUST ter a mesma chave. O desinstalar do módulo MUST tirar tudo isso e
  devolver o sistema como estava.
- **FR-033** (sem atraso): os sons de boot e de login MUST NOT atrasar o boot. O login continua dentro
  do limite de +1 s da 011, e a soma com o tema MUST NOT crescer mais de 0,1 s.
- **FR-034** (aba LOG): o text log MUST virar a aba LOG do menu de pausa, entre WINDOWS e SYSTEM, com o
  mesmo conteúdo e as mesmas teclas da 008. SUPER+N e o contador da barra MUST abrir o menu nessa aba.
  O popup separado do log MUST sair, e o menu passa a ser o único lugar do histórico.

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
- **SC-008**: Cada evento de FR-019 toca o som certo e começa no máximo 50 ms depois da tecla.
  *Evidência:* uma gravação da saída de áudio da VM durante um roteiro com `lab/key`, com os tempos de
  cada tecla e de cada som.
- **SC-009**: Desligar os sons, mudar o volume, ligar a digitação e apontar uma pasta com um arquivo de
  um evento só funcionam na hora (o evento dessa pasta toca o arquivo, os outros tocam os nossos).
  *Evidência:* a mesma gravação, em quatro passadas.
- **SC-010**: A janelinha abre, escolhe, cancela e marca várias opções como em FR-025 a FR-027, nos dois
  modos e nos dois perfis. *Evidência:* screenshots, `lab/burst` da abertura e o `dump` do estado depois
  de cada passo.
- **SC-011**: O dono ouve os sons nossos e aprova o caráter deles. *Evidência:* a aprovação dele.
- **SC-012**: Num boot do zero até o desktop, a gravação da saída de áudio da VM mostra o som de início,
  os sons da tela de login e o som de entrada nos momentos certos, e mais nada fora deles. *Evidência:*
  a gravação (placa emulada com saída em arquivo), com os tempos ao lado do journal.
- **SC-013**: O boot não fica mais lento e o áudio do sistema sobe normal. *Evidência:*
  `lab/011/boot-timing` com três boots (diferença ≤ 0,1 s em relação a sem os sons) e o estado do áudio
  na sessão sem erro.

## Assumptions

- **A referência visual é o protótipo** ("YoRHa-OS Protótipo: menus do jogo"). O que estiver nele e não
  estiver aqui segue o protótipo.
- **Sons:** os nossos são a referência de caráter da frente C (`C/sons.md`), e o dono aprova de ouvido
  (SC-011). Nos testes do lab, os recortes provisórios do vídeo continuam fora do git. A tabela que liga
  os arquivos extraídos do jogo aos nossos eventos depende de uma cópia de PC original, que o dono ainda
  não tem. Até lá, a pasta própria funciona pelo nome do evento, e a documentação diz quais nomes usar.
- **Notificações:** os sons de notificação (FR-019) entram na 008 já mesclada, sem mudar o resto dela.
- **Desligar:** a faixa de passagem do desligar e do reiniciar fica sem som nesta spec. O Plymouth não toca som, e no desligar o áudio já está descendo.
- **Nenhum material do jogo entra no repositório** (imagens, fontes, sons): os números foram medidos e
  o desenho é nosso.
- **A 008 entra na `main` antes da implementação.** Se a 010 tocar as mesmas peças, ela vem depois ou
  em paralelo, só onde não conflita.
- **Os números podem ser ajustados** depois que o dono vir na VM, sem uma spec nova.
