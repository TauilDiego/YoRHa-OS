# Feature Specification: Boot e login

**Feature Branch**: `011-boot-e-login` (sai da `main`)

**Created**: 2026-10-29

**Status**: Rascunho, com duas perguntas pro dono marcadas `[NEEDS CLARIFICATION]` (FR-040 e US5)

**Input**: Fase U5a do `PLAN.md` (§9): "Splash de boot no Plymouth e tela de login com a UI NieR:
tema QML do SDDM ou um greeter em Quickshell (a escolha sai da spec). O bootloader continua o
systemd-boot, escolha do dono, então o menu dele não ganha tema". O aceite do plano: "Na VM, um
reboot mostra o splash e cai na tela de login nova (screenshots dos dois, do boot até o login);
entrar com senha certa abre o Hyprland e com senha errada mostra o erro; o log do boot fica sem
erro do tema".

**Decisões do dono que esta spec segue (29.10.2026)**:
- **Etapas do boot:** o menu do bootloader fica fora ("nem ligo"). Entram o boot (Plymouth) e o
  login (SDDM), que o dono chamou de "muito muito importante".
- **Boot:** a direção 1 do estudo do boot (artefato a3c01dba "YoRHa-OS Boot e Plymouth"). É a lista
  de checagens "[ OK ]" da tela de boot do jogo, escrita com as etapas reais do boot e com texto
  nosso. O comportamento e os números saem da análise 4K do boot do jogo (artefato f3ee156f
  "YoRHa-OS Boot do jogo: análise 4K"; parâmetros em `YoRHa-OS-private/pessoal/referencias/jogo/
  boot-analise.md`). O dono achou a reprodução "muito igual".
- **Carregamento:** o spinner do boot e a espera do login usam o anel de carregamento do tema de
  cursor (`Loading_Circle`, spec 002), a regra de "uma animação de carregamento só" (spec 010, item
  D). Nunca um spinner novo.
- **Faixa de passagem:** a faixa "Loading user data…" liga o boot ao login. Ela é lisa, fica fora da
  lente e da película, e abre e fecha como uma linha de CRT. O dono aprovou ("ficou perfeito").
- **Login:** um tema próprio do SDDM, com o layout do Qylock (Darkkal44, GPL-3.0) e o nosso design
  system, sem nome, personagem ou texto do jogo. A proposta interativa (artefato 28209760 "YoRHa-OS
  Login: proposta", v3.2) foi aprovada ("é isso mesmo", "tudo perfeito"). Com isso, a escolha do
  PLAN fica no tema do SDDM, não num greeter em Quickshell.
- **Lista de usuários:** sempre visível, mesmo com um usuário só, com o "Other user…" pra trocar.
- **Relógio:** o relógio grande fica no centro.
- **Entrada do login:** ao ligar, a entrada completa com o glitch; ao sair da sessão ou trocar de
  usuário, só um fade. A entrada nunca trava. Duas regras do dono: **uma animação nunca pode bugar
  por cima de outra**, e **quem tenta logar antes da entrada terminar cancela a animação** e cai
  direto no login, com o que já digitou.
- **Réguas e fundo:** o fundo do login é a cena "Menu" do papel de parede (spec 004). As réguas são
  as do shell, no tamanho do jogo: a de cima no lugar da régua da barra, a de baixo na altura da
  cena "Menu + rules". É o mesmo tamanho que a barra vai usar (spec 010, item A, decidido em 29.10).
- **Regra geral:** toda alternativa de design vira uma opção, com a recomendação como padrão. Aqui
  as opções ficam na configuração do tema, porque o login roda antes de qualquer sessão.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Entrar pela tela de login nova (Priority: P1)

O computador termina de ligar e mostra a tela de login do YoRHa-OS. O fundo é o papel do desktop,
com a vinheta, os arcos e os feixes respirando devagar, e com as réguas pontilhadas em cima e
embaixo. Por cima ficam o cabeçalho "LOGIN -Authentication" e três colunas:
- à esquerda, a lista de usuários, com a pipa no último usuário que entrou;
- no centro, o relógio grande, a data e o nome do sistema;
- à direita, o cartão "Authentication", com o campo de senha, e as opções Session, Reboot e Shut
  down.

Embaixo da régua de baixo fica a barra de teclas. O usuário digita a senha, aperta Enter e entra na
sessão escolhida.

**Why this priority**: É a tela que o dono chamou de "muito muito importante" e a que todo mundo vê
todo dia. Sozinha, sem o boot novo, ela já entrega a cara do sistema antes do desktop.

**Independent Test**: Na VM do laboratório, com o tema ativo e dois usuários de teste:
- reiniciar até o login e tirar screenshots nos dois perfis de monitor;
- entrar com a senha certa e conferir, por um comando que responde na sessão do usuário, que o
  Hyprland abriu;
- repetir com a senha errada, com o "Other user…", com a troca de sessão e com o Reboot e o Shut
  down;
- conferir o estado da VM (ligada, reiniciando, desligada) pelo monitor da VM.

**Acceptance Scenarios**:

1. **Given** a VM terminando o boot, **When** o login aparece, **Then** a tela tem o fundo da cena
   "Menu", as duas réguas pontilhadas do shell, o cabeçalho, as três colunas e a barra de teclas, e
   o campo de senha já recebe o teclado.
2. **Given** o login pronto, **When** o usuário digita, **Then** cada caractere vira um quadradinho
   que entra com animação. Passando da largura do campo, os mais antigos saem pela esquerda sob um
   "…", e o cursor fica sempre visível. Backspace encolhe o último quadradinho; Esc limpa o campo.
3. **Given** a senha certa, **When** o usuário aperta Enter, **Then** o anel de carregamento aparece
   enquanto a senha é conferida. Em seguida a tela mostra "Welcome, <usuário>" com a sessão
   escolhida, e a sessão abre pro usuário certo.
4. **Given** a senha errada, **When** o usuário aperta Enter, **Then** aparece "Authentication
   failed." na cor de alerta, o painel de autenticação rasga 7 px (em 4K) como as faixas de
   interferência do boot, e o campo se limpa pra nova tentativa.
5. **Given** a lista com mais de um usuário, **When** o usuário aperta ↑ ou ↓ ou clica num nome,
   **Then** o destaque varre da esquerda (a tinta, os dois trilhos e a sombra), a pipa pisca do item
   antigo pro novo em 240 ms e o campo de senha se limpa.
6. **Given** "Other user…" selecionado, **When** o usuário digita um nome, aperta Enter, digita a
   senha e aperta Enter, **Then** a sessão abre pra esse nome, se a senha bater.
7. **Given** o login pronto, **When** o usuário aperta Tab ou Shift+Tab, clica em Session ou nas
   setas ◂ ▸, **Then** a sessão troca entre as instaladas. A sessão que estiver na tela é a que
   abre, e na próxima vez a última usada já vem escolhida.
8. **Given** o login pronto, **When** o usuário escolhe Reboot ou Shut down, **Then** abre o diálogo
   de confirmação do menu de pausa (spec 007), com Cancel marcado. Cancel ou Esc fecham sem fazer
   nada. Confirmar fecha a tela, mostra a faixa "Rebooting…" ou "Shutting down…" e a máquina
   reinicia ou desliga de verdade.
9. **Given** o Caps Lock ligado, **When** o usuário digita no campo de senha, **Then** a mensagem
   "Caps Lock is on." aparece no cartão.
10. **Given** mais usuários do que cabem na coluna (mais de 10), **When** o usuário anda pela lista,
    **Then** ela rola em linhas inteiras, com uma barra de rolagem fina e o contador "n / total".

---

### User Story 2 - Ligar o computador e ver a lista de checagens (Priority: P1)

Do preto, o boot entra com um fade numa tela escura com a película de LCD do jogo. Um cabeçalho com
pontinhos animados e o anel de carregamento no canto superior direito ficam fixos. Embaixo, a lista
de checagens vai sendo digitada linha por linha, cada uma com uma etapa real do boot e o estado
dela. As faixas de interferência passam, escurecem e rasgam o texto por alguns quadros. Quando o
boot termina, a lista some num fade e a faixa de passagem leva pro login.

**Why this priority**: É o primeiro contato com o sistema a cada boot e o que o dono pediu pra ficar
"muito igual" ao jogo. É independente do login: com o login padrão do SDDM, ela já entrega o boot
novo.

**Independent Test**: Na VM, reiniciar com a captura de tela do laboratório (uma imagem a cada 0,25 s)
e montar a sequência do ligar até o login. Comparar, lado a lado com a análise 4K, a entrada, a
digitação, a película, a lente, as faixas, a saída e a faixa de passagem. Repetir com um boot
artificialmente lento (uma etapa que espera alguns segundos) e com o boot rápido normal.

**Acceptance Scenarios**:

1. **Given** a VM desligada, **When** ela liga e o kernel começa, **Then** a tela sai do preto num
   fade linear de ~1 s pra tela escura com a película (malha de 14 px em 4K), o cabeçalho com texto
   nosso e pontinhos que ciclam a cada 1,156 s, e o anel de carregamento claro no canto.
2. **Given** a lista correndo, **When** uma etapa do boot começa ou termina, **Then** uma linha com
   o nome dela, escrito por nós, é digitada a ~77 letras/s. A letra da ponta é sorteada da própria
   linha. A linha nasce apagada só nos primeiros ~50 ms, as linhas ficam ~0,11 s uma da outra e o
   estado aparece no fim ("OK" e equivalentes).
3. **Given** a tela de boot, **When** o tempo passa, **Then** a lente (aberração radial só no
   vermelho, ~0,21 %) e a película ficam paradas sobre tudo. As faixas de interferência aparecem
   ~7 vezes por segundo, duram de 1 a 8 quadros, escurecem ~12 %, mostram anéis concêntricos fracos
   e deslocam o conteúdo dentro delas 7 px (em 4K). A película nunca rasga.
4. **Given** a última linha escrita, **When** o boot ainda espera alguma etapa, **Then** um cursor
   `_` pisca depois dela (0,49 s aceso, 0,49 s apagado) e o anel continua girando.
5. **Given** o boot pronto pro login, **When** a lista sai, **Then** ela some num fade de 0,9 s em
   degraus, com os rasgos continuando. Depois vêm o preto, a faixa "Loading user data…" abrindo
   como uma linha de CRT, a faixa fechando de volta numa linha e o login (US3).
6. **Given** uma etapa do boot que falha, **When** a linha dela é escrita, **Then** o estado sai como
   falha, na cor de alerta, e o boot segue como seguiria sem o tema.

---

### User Story 3 - Do boot pro login sem emenda, e sem nunca travar (Priority: P2)

Entre o fim da lista e o login não aparece texto de console, tela piscando nem outro tema. A faixa
de passagem fecha, o nome "YoRHa-OS" entra embaralhado no escuro com o glitch e o papel do login
aparece por baixo. Quem já sabe a senha não precisa esperar nada disso: o campo aceita digitação
desde o primeiro quadro, e uma tecla, um Enter ou um clique cortam a animação na hora. Ao sair da
sessão ou trocar de usuário, o login volta só com um fade.

**Why this priority**: Amarra o boot ao login como uma coisa só, que é o "momento jogo" do sistema.
Depende das duas histórias P1 pra existir inteira, mas cada metade dela é testável com uma delas só.

**Independent Test**: Na VM, capturar a sequência do fim do boot até o login pronto e conferir que
nenhuma imagem mostra console ou outro tema. Com teclas enviadas pela VM: digitar a senha durante
a entrada e apertar Enter; clicar durante a entrada; sair da sessão e voltar. Em cada caso, conferir
o estado final por screenshot.

**Acceptance Scenarios**:

1. **Given** o fim do boot, **When** o login assume a tela, **Then** a sequência é contínua: preto,
   faixa, nome com glitch, papel e painéis, em ~3,8 s, sem texto de console nem quadro branco.
2. **Given** a entrada correndo, **When** o usuário digita, **Then** a animação para na hora, o login
   aparece pronto e os caracteres digitados já estão no campo.
3. **Given** a entrada correndo e a senha digitada, **When** o usuário aperta Enter, **Then** a
   entrada é cortada e o login segue como no cenário 3 da US1. Com o campo vazio, o Enter só corta
   a entrada, sem erro.
4. **Given** a entrada correndo, **When** o usuário clica na tela, **Then** a animação para e o login
   aparece pronto, com o campo em foco.
5. **Given** uma sessão aberta, **When** o usuário sai dela ou troca de usuário, **Then** o login
   volta com um fade, sem a faixa nem o glitch.
6. **Given** a opção de entrada em "fade" ou "nenhuma", ou o movimento reduzido ligado, **When** o
   login aparece depois do boot, **Then** ele usa o fade (ou aparece direto), sem o glitch.

---

### User Story 4 - Senha do disco no boot (Priority: P3)

Em máquinas com o disco criptografado, o boot para e pede a senha do disco antes de seguir. A tela
de boot mostra o pedido no estilo do login: o campo com um quadradinho por caractere, o "…" quando
passa da largura e a mensagem de erro se a senha estiver errada. Depois disso a lista continua.

**Why this priority**: Nem toda máquina tem o disco criptografado, mas uma tela de boot que não sabe
pedir essa senha deixa o usuário sem entrar. O mínimo (FR-030) é sempre deixar o pedido funcionar;
o estilo é a parte P3.

**Independent Test**: Numa VM de teste com o disco criptografado, reiniciar, conferir o pedido por
screenshot, errar uma vez, acertar e conferir que o boot segue até o login.

**Acceptance Scenarios**:

1. **Given** um disco criptografado, **When** o boot chega no pedido de senha, **Then** a tela mostra
   o campo no estilo do login, por cima da tela de boot.
2. **Given** a senha errada, **When** o usuário aperta Enter, **Then** aparece o erro e o campo se
   limpa; **When** acerta, **Then** a lista segue.

---

### User Story 5 - Desligar e reiniciar com a mesma cara (Priority: P3)

[NEEDS CLARIFICATION: a tela de desligar e reiniciar entra nesta spec? A proposta seria: ao
desligar ou reiniciar (pelo login, pelo menu de pausa ou por comando), a tela escura do boot
mostra a faixa "Shutting down…" ou "Rebooting…", como no protótipo do login, até a máquina apagar.
O estudo do boot listou o desligar como etapa desejada, mas a forma não foi decidida.]

**Why this priority**: Fecha o ciclo visual do boot, mas o sistema funciona sem ela.

**Independent Test**: Na VM, desligar e reiniciar pelos três caminhos, capturando a tela até a VM
apagar, e conferir que nenhuma imagem mostra texto de console.

**Acceptance Scenarios**:

1. **Given** uma sessão aberta, **When** o usuário desliga pelo menu de pausa, **Then** a tela de boot
   mostra a faixa "Shutting down…" até a VM apagar.
2. **Given** uma sessão aberta, **When** o usuário reinicia, **Then** a faixa diz "Rebooting…" e o
   boot seguinte começa normalmente (US2).

---

### Edge Cases

- **O tema do login falha ao carregar** (erro de QML, arquivo faltando): o login continua possível,
  com o tema padrão do próprio SDDM. A pessoa nunca fica trancada pra fora por causa do tema.
- **O tema do boot não está ativo** (sem o tema no initramfs ou sem o parâmetro de splash): o boot
  segue em texto, como antes, e o login aparece normalmente.
- **Boot rápido demais:** o boot nunca espera a animação. Se o boot termina antes de a lista acabar
  de ser digitada, as linhas que faltam são descartadas e a saída começa.
- **Boot que trava esperando algo** (disco, rede): o cursor `_` pisca depois da última linha e o
  anel gira; a tela nunca congela parada sem movimento.
- **Vários monitores:** o login fica no monitor principal; os outros mostram só o fundo (a cena e
  as réguas), sem os painéis. A tela de boot aparece em todos.
- **Os dois perfis do dono** (1920×1080 a 1 e 2560×1600 a 1,25): tudo escala pela altura da tela, e
  as réguas e a película ficam nítidas nos pixels físicos.
- **Nenhum usuário listável** (o SDDM esconde contas de sistema): a lista mostra só o "Other user…",
  já selecionado.
- **Nome de usuário longo:** corta com "…" na lista e cabe no "Welcome".
- **Muitos usuários** (20 ou mais): a lista rola em linhas inteiras (US1, cenário 10).
- **Sessão lembrada que não existe mais:** o login escolhe a primeira sessão instalada.
- **A conferência da senha demora** (o atraso do PAM depois de um erro dura ~2 s): o anel de
  carregamento aparece no cartão, e o campo e o Enter ficam travados até a resposta, sem envio
  duplo.
- **Entradas rápidas por cima de animações** (digitar durante a entrada, trocar de usuário no meio
  da varredura, abrir o diálogo durante o rasgo, apertar Enter duas vezes): o estado final é sempre
  um estado válido (login pronto, boas-vindas, diálogo aberto ou desligando), sem duas animações
  sobrepostas nem tela presa.
- **Teclado:** a senha é digitada com o layout de teclado do sistema, o mesmo da sessão.
- **Movimento reduzido:** nada de glitch, rasgo, respiração do fundo nem varredura; tudo troca na
  hora.

## Requirements *(mandatory)*

### Functional Requirements

**Login (SDDM)**

- **FR-001**: O login MUST ter o layout aprovado na proposta (artefato 28209760, v3.2): o cabeçalho
  "LOGIN -Authentication"; a lista de usuários à esquerda; o relógio, a data e o nome do sistema no
  centro; o cartão "Authentication" com Session, Reboot e Shut down à direita; e a barra de teclas
  embaixo.
- **FR-002**: O fundo do login MUST ser a cena "Menu" do papel de parede (spec 004), desenhada como o
  shell desenha: a vinheta medida, os arcos duplos e os feixes a 42°, respirando no ritmo do shell
  (ciclo de 600 s).
- **FR-003**: As réguas MUST ser a régua pontilhada do shell, no tamanho do jogo (s=1). A de
  cima fica na altura da régua da barra; a de baixo, na altura da régua da cena "Menu + rules"
  (y 1012 em 1080p).
- **FR-004**: A lista de usuários MUST aparecer sempre, mesmo com um usuário só, e terminar no "Other
  user…". Ela começa no último usuário que entrou.
- **FR-005**: A troca de item nas listas (usuários, opções, diálogo) MUST seguir o design system: a
  varredura da esquerda (tinta, trilhos e sombra) em 150 ms na entrada, saída instantânea, e a pipa
  parada que pisca na troca (some, pula e aparece, 240 ms no total).
- **FR-006**: O campo de senha MUST mostrar um quadradinho por caractere, com animação de entrada e
  de saída. Passando da largura, os mais antigos saem pela esquerda sob um "…", e o cursor fica
  sempre visível.
- **FR-007**: O teclado MUST funcionar como na barra de teclas: ↑↓ trocam de usuário, Enter entra,
  Tab e Shift+Tab trocam de sessão, Esc limpa o campo. O mouse MUST fazer o mesmo pelos cliques.
- **FR-008**: O "Other user…" MUST abrir um campo de nome acima da senha. O Enter no nome passa pra
  senha.
- **FR-009**: O login MUST autenticar pelo próprio SDDM (PAM do sistema) e abrir a sessão escolhida
  pro usuário escolhido ou digitado.
- **FR-010**: Enquanto a senha é conferida, o cartão MUST mostrar o anel de carregamento do cursor
  (variante tinta sobre papel), e uma segunda tentativa MUST ficar travada até a resposta.
- **FR-011**: A senha errada MUST mostrar "Authentication failed." na cor de alerta, rasgar o painel
  de autenticação 7 px (em 4K, por ~0,32 s) e limpar o campo.
- **FR-012**: O Caps Lock ligado MUST ser avisado no cartão.
- **FR-013**: Reboot e Shut down MUST pedir confirmação no diálogo do menu de pausa (spec 007), com
  Cancel marcado. Confirmado, o login mostra a faixa "Rebooting…" ou "Shutting down…" e pede ao
  sistema pra reiniciar ou desligar.
- **FR-014**: A sessão MUST ser escolhida entre as instaladas, por Tab, Shift+Tab, clique ou ◂ ▸, e a
  última usada MUST vir escolhida.
- **FR-015**: Com mais de 10 usuários, a lista MUST rolar em linhas inteiras, com a barra de rolagem
  e o contador "n / total".
- **FR-016**: Depois da senha certa, a tela MUST mostrar "Welcome, <usuário>" e a sessão antes de
  passar pra ela.

**Entrada do login e animações**

- **FR-017**: Depois do boot, o login MUST entrar com a sequência aprovada: preto, a faixa "Loading
  user data…" fechando numa linha, o nome "YoRHa-OS" embaralhado com glitch no escuro, o papel
  aparecendo por baixo e os painéis subindo, em ~3,8 s.
- **FR-018**: O campo MUST aceitar digitação desde o primeiro quadro da entrada. Uma tecla, um Enter
  ou um clique durante a entrada MUST cortá-la na hora, mantendo o que foi digitado. O Enter com o
  campo vazio só corta a entrada.
- **FR-019**: Ao sair da sessão ou trocar de usuário, o login MUST voltar só com um fade, sem a faixa
  nem o glitch.
- **FR-020**: Nenhuma animação MUST rodar por cima de outra do mesmo elemento: começar uma animação
  cancela a anterior, e o estado final é sempre um estado válido da tela.
- **FR-021**: Enquanto o login não está pronto (durante a entrada, a saída ou o desligar), os
  controles invisíveis MUST NOT reagir ao mouse.

**Boot (Plymouth)**

- **FR-022**: O boot MUST mostrar a tela escura do jogo, com a película de LCD, a lente, as faixas de
  interferência com rasgo e anéis, a cintilação geral, a vinheta lateral e os números da análise
  4K. Nada disso usa imagem, texto, fonte ou emblema do jogo.
- **FR-023**: O boot MUST mostrar um cabeçalho com texto nosso e pontinhos animados, e o anel de
  carregamento do cursor (variante clara sobre escuro) no canto superior direito.
- **FR-024**: Cada linha da lista MUST corresponder a uma etapa real do boot, com um nome escrito por
  nós e o estado dela no fim. A digitação, a letra da ponta, o brilho inicial e o intervalo entre
  linhas seguem a análise 4K.
- **FR-025**: Uma etapa que falha MUST aparecer como falha, na cor de alerta.
- **FR-026**: O tema de boot MUST NOT atrasar o boot: quando o sistema está pronto pro login, a saída
  começa, e as linhas que faltam são descartadas.
- **FR-027**: A saída do boot MUST ser o fade de 0,9 s em degraus, seguido da faixa de passagem (lisa,
  fora da lente e da película, abrindo e fechando como uma linha de CRT) e do login.
- **FR-028**: Entre o boot e o login, MUST NOT aparecer texto de console, quadro branco ou outro tema.
- **FR-029**: Um boot que espera algo MUST mostrar o cursor `_` piscando depois da última linha e o
  anel girando.
- **FR-030**: O pedido de senha do disco criptografado MUST continuar funcionando com o tema. O
  estilo do login nesse pedido (quadradinhos, "…", erro) é da US4.

**Opções**

- **FR-031**: A configuração do tema do login MUST ter estas opções, com o padrão primeiro:
  - entrada: `full`, `fade` ou `none`;
  - relógio: `big`, `small` ou `none`;
  - lista de usuários: `always` ou `auto` (some com um usuário só);
  - movimento reduzido: `off` ou `on`.
- **FR-032**: O movimento reduzido MUST tirar o glitch, o rasgo, a respiração do fundo e as
  varreduras, e usar a entrada `fade`.
- **FR-033**: A configuração padrão MUST ficar na pasta gerenciada do projeto, e a do usuário MUST só
  sobrescrever o que ele quiser, sem que um update mexa nela (constituição, princípio III).

**Robustez**

- **FR-034**: Se o tema do login não carregar, o SDDM MUST cair no tema padrão dele, e o login MUST
  continuar possível.
- **FR-035**: Sem o tema de boot ativo, o boot MUST seguir em texto e terminar no login.
- **FR-036**: Em vários monitores, o login MUST ficar no principal, e os outros MUST mostrar só o fundo.
- **FR-037**: Tudo MUST escalar pela altura da tela e ficar nítido a 1920×1080 com escala 1 e a
  2560×1600 com escala 1,25.

**Créditos e marcas**

- **FR-038**: O que vier do Qylock (a parte que conversa com o SDDM: usuários, sessões, envio da
  senha) MUST manter o aviso de autoria e a licença GPL-3.0 nos arquivos, e entrar no `CREDITS.md`.
- **FR-039**: Os textos do boot e do login MUST ser nossos e em inglês, como o resto da UI. Nada do
  jogo entra (nomes, personagens, textos, fontes, emblemas, sons).

**Instalação**

- **FR-040**: A camada visual MUST trazer os dois temas na pasta gerenciada e escolher o tema do SDDM
  por um arquivo de configuração próprio, sem editar o arquivo do usuário. [NEEDS CLARIFICATION: o
  tema de boot precisa de duas mudanças no sistema, fora do tema em si: o Plymouth no initramfs
  (com a imagem refeita) e o parâmetro `splash` na linha do kernel, que fica na entrada do
  systemd-boot. Na direção "só visual", o instalador faz essas duas mudanças, com backup e um
  jeito de desfazer, ou só instala o tema e documenta os passos?]

### Key Entities

- **Etapa do boot:** uma unidade do sistema que começa ou termina durante o boot. Tem o nome técnico,
  o nome escrito por nós que aparece na lista e o estado (em andamento, pronta, falhou).
- **Usuário listável:** uma conta que o SDDM mostra (nome, nome de exibição). O último usuário que
  entrou é lembrado.
- **Sessão:** uma sessão instalada (Hyprland, Niri…), com nome e se foi a última usada.
- **Opções do tema:** entrada, relógio, lista de usuários e movimento reduzido, com o padrão gerenciado
  e a sobrescrita do usuário.

## Success Criteria *(mandatory)*

Cada critério diz a evidência que o comprova (constituição, princípio IV).

### Measurable Outcomes

- **SC-001**: Do ligar ao login pronto, nenhuma das capturas da VM (uma a cada 0,25 s) mostra texto
  de console, quadro branco ou outro tema. *Evidência:* a sequência de capturas de um reboot,
  numa folha de contato.
- **SC-002**: O tema de boot não deixa o boot mais lento: o tempo do ligar ao login pronto fica no
  máximo 0,5 s acima do mesmo boot sem o tema. *Evidência:* dois relatórios do `lab/perf`, com e
  sem o tema, na mesma VM.
- **SC-003**: Quem digita a senha certa e aperta Enter durante a entrada entra na sessão sem esperar
  a animação: a entrada some em até 1 quadro depois da primeira tecla. *Evidência:* teclas
  enviadas pela VM e as capturas antes e depois.
- **SC-004**: Com a senha certa, a sessão escolhida abre pro usuário certo em 10 de 10 tentativas
  (os dois usuários de teste, as duas sessões quando houver). *Evidência:* um comando que responde
  dentro da sessão (o compositor listando as telas) depois de cada login.
- **SC-005**: Com a senha errada, o erro aparece e o campo aceita uma nova tentativa sem recarregar a
  tela, em 10 de 10 tentativas. *Evidência:* capturas e o log do SDDM.
- **SC-006**: Num teste de 20 sequências rápidas de teclas e cliques por cima das animações
  (entrada, troca de usuário, diálogo, senha errada, Enter duplo), a tela termina sempre num estado
  válido. *Evidência:* o log do teste e a captura final de cada sequência.
- **SC-007**: Em 10 ciclos de boot, login e saída, o log do SDDM e o do boot não mostram nenhum erro
  ou aviso de QML vindo dos temas. *Evidência:* o trecho do journal de cada ciclo.
- **SC-008**: Com o tema do login quebrado de propósito, o login continua possível pelo tema padrão
  do SDDM. *Evidência:* captura do tema padrão e o comando que responde na sessão aberta.
- **SC-009**: Confirmar Reboot e Shut down no login reinicia e desliga a VM; Cancel e Esc não fazem
  nada. *Evidência:* o estado da VM pelo monitor dela, antes e depois.
- **SC-010**: Os screenshots do login nos dois perfis de monitor batem com a proposta aprovada, e a
  sequência do boot bate com a análise 4K. *Evidência:* a página de revisão com as capturas lado a
  lado e a aprovação visual do dono.

## Assumptions

- **Gerenciador de login:** o SDDM, como no ambiente do laboratório. Com outro gerenciador (GDM,
  ly…), o tema de login simplesmente não é usado.
- **Bootloader:** o systemd-boot, com o menu sem tema (decisão do dono).
- **Opções fora da sessão:** o login roda antes de qualquer sessão, então não lê as configurações do
  shell. As opções ficam na configuração do tema (FR-031). Se dá pra ligar o "Reduce motion" do
  System Settings ao tema, fica pro plano.
- **Usuários listáveis:** valem as regras normais do SDDM (contas de usuário comuns, sem as
  escondidas). O SDDM lembra o último usuário e a última sessão.
- **Idioma:** os textos da tela ficam em inglês, como o resto da UI; a troca de idioma é a fase U5b.
- **Anel de carregamento:** os quadros saem do gerador do tema de cursor (spec 002). A variante clara
  sobre escuro e o componente compartilhado são o item D da spec 010. Se a 010 ainda não tiver
  feito, esta spec gera só as variantes que usa, pelo mesmo gerador.
- **Nomes das etapas do boot:** cobrem as etapas comuns de um Arch com Hyprland (sistema de arquivos,
  rede, som, Bluetooth, sessão gráfica…). Uma etapa sem nome nosso aparece com um nome genérico, nunca
  com o nome técnico cru.
- **Fora do escopo:** a tela de bloqueio e o polkit (U5), o menu do bootloader, a troca de idioma
  (U5b) e o tema dos apps.
- **Ambiente de testes:** tudo roda na VM do laboratório (constituição, princípio I), com as
  capturas de tela pelo monitor da VM.
