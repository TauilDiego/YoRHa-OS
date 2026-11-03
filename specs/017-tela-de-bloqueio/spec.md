# Feature Specification: Tela de bloqueio

**Feature Branch**: `017-tela-de-bloqueio` (sai da `main`)

**Created**: 2026-11-02

**Status**: Rascunho, pra revisão do dono

**Input**: Fase U5 do `PLAN.md` (§9), a metade do lock: "Tela de bloqueio (PAM) e agente de polkit,
testados de verdade na VM", com o aceite "Bloquear, desbloquear e autorizar uma ação funcionam na
VM". A U5a (boot e login) já saiu nas specs 011 e 012.

Por que agora:
- o dono quer trocar o Serpantinum pelo YoRHa-Shell nesta semana, e hoje o YoRHa-Shell não tem tela
  de bloqueio: POWER › Lock chama `loginctl lock-session`, mas ninguém atende;
- as opções de Power "Screen off after", "Suspend after" e "Lid closed" existem no menu desde a 003,
  mas só como dados de exemplo: não fazem nada.

Por isso esta spec é uma v0 enxuta: bloquear, desbloquear com a senha e ficar seguro. O resto vai
pra "Fora da v0", no fim.

## Clarifications

### Decidido antes desta spec

- **A cara:** a família da tela de LOGIN da 011 (o protótipo aprovado, "é isso mesmo"): o papel da
  cena "Menu", as réguas do shell, o cabeçalho, o relógio grande e o cartão de autenticação com um
  quadradinho por caractere.
- **A espera:** enquanto a senha é conferida, o anel de carregamento do cursor (`Loading_Circle`),
  a regra de uma animação de carregamento só (spec 010, item D). Nunca um spinner novo.
- **Sem som de digitação**, de jeito nenhum, nem como opção (dono, 01.11). Os outros sons do shell
  (confirmar, erro) podem tocar, seguindo "Interface sounds".
- **Alternativas de design viram opções** trocadas na hora, com a recomendada como padrão (dono,
  27.10).
- **O pedido de bloquear** é o de hoje: POWER › Lock chama `loginctl lock-session`. O bloqueio atende
  esse pedido, venha ele do menu, de um atalho ou de outro programa.
- **O tempo sem uso** pode vir de um serviço de ociosidade ou de um timer do próprio shell: a escolha
  fica pro plano.

### Abertas nesta spec

As duas perguntas estão marcadas com [NEEDS CLARIFICATION] no texto (FR-002 e FR-010).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bloquear e desbloquear com a senha (Priority: P1) 🎯 MVP

O dono sai da mesa e escolhe POWER › Lock (ou o atalho). A tela inteira vira a tela de bloqueio na
hora: nada do desktop fica visível. No centro, o relógio grande; à direita, o cartão de autenticação
com o nome dele e o campo de senha já recebendo o teclado. Ele volta, digita a senha, aperta Enter,
o anel gira enquanto a senha é conferida e o desktop volta como estava.

**Why this priority**: É o mínimo pra trocar o Serpantinum. Sem isso, o dono fica sem bloqueio.

**Independent Test**: Na VM do lab, com o shell instalado: bloquear pelo menu, tirar screenshot,
digitar a senha certa pelas teclas da VM e conferir, por screenshot e por um comando que responde
(o estado da sessão no `loginctl`), que a sessão voltou destravada e com as janelas no lugar.

**Acceptance Scenarios**:

1. **Given** uma sessão aberta, **When** o usuário escolhe POWER › Lock ou roda
   `loginctl lock-session`, **Then** todas as telas ficam cobertas em menos de 1 s, e nenhum quadro
   mostra o desktop depois disso.
2. **Given** a tela de bloqueio, **When** ela aparece, **Then** tem o fundo da cena "Menu", as duas
   réguas, o cabeçalho, o relógio grande com a data, e o cartão com o nome do usuário e o campo de
   senha com o foco.
3. **Given** o campo de senha, **When** o usuário digita, **Then** cada caractere vira um quadradinho,
   como no login (o "…" quando passa da largura, Backspace encolhe, Esc limpa), sem som de digitação.
4. **Given** a senha certa, **When** o usuário aperta Enter, **Then** o anel de carregamento aparece
   enquanto ela é conferida, a tela some e o desktop volta como estava (janelas, workspace, foco).
5. **Given** o Caps Lock ligado, **When** o usuário digita, **Then** o cartão mostra "Caps Lock is
   on.".
6. **Given** a tela de bloqueio, **When** chega uma notificação, **Then** ela não aparece por cima
   (fica no text log pra depois).

---

### User Story 2 - A senha errada (Priority: P1)

O usuário erra a senha. A tela diz isso no estilo do login e deixa tentar de novo. Se o sistema
travar novas tentativas por um tempo (depois de erros seguidos), a tela diz isso e quanto falta.

**Why this priority**: Faz parte de desbloquear: sem um erro claro, a pessoa não sabe se errou ou se
a tela travou.

**Independent Test**: Na VM: errar a senha uma vez e tirar screenshot; errar até o sistema travar as
tentativas e tirar screenshot da mensagem; esperar e acertar.

**Acceptance Scenarios**:

1. **Given** a senha errada, **When** o usuário aperta Enter, **Then** aparece "Authentication
   failed." na cor de alerta, o cartão rasga como no login (7 px em 4K), o som de erro toca (se os
   sons estiverem ligados) e o campo se limpa.
2. **Given** erros seguidos até o sistema travar novas tentativas, **When** o usuário tenta de novo,
   **Then** a tela diz que as tentativas estão travadas e por quanto tempo, sem rasgar a cada tecla.
3. **Given** o tempo de trava passado, **When** o usuário acerta a senha, **Then** desbloqueia
   normalmente.
4. **Given** a conferência demorando (o sistema leva alguns segundos pra responder a uma senha
   errada), **When** o usuário espera, **Then** o anel gira o tempo todo, e o campo não aceita outro
   Enter até a resposta.

---

### User Story 3 - Bloquear sozinho: sem uso e antes de suspender (Priority: P1)

O dono deixa o computador parado. Depois do tempo escolhido em SYSTEM › Power, a tela bloqueia
sozinha. E, se o computador suspender (pelo menu, pela tampa ou pelo sistema), ele já volta
bloqueado: o primeiro quadro depois de acordar é a tela de bloqueio, nunca o desktop.

**Why this priority**: O bloqueio que só funciona quando a pessoa lembra de bloquear não protege. O
Serpantinum faz isso hoje na máquina do dono.

**Independent Test**: Na VM, com o tempo encurtado por uma opção de teste: deixar parada e conferir
que bloqueia no tempo; suspender pela VM, acordar e conferir pelas capturas do lab que nenhum quadro
mostra o desktop.

**Acceptance Scenarios**:

1. **Given** "Lock after" em 5 min (o padrão), **When** ninguém mexe no teclado nem no mouse por 5
   min, **Then** a tela bloqueia.
2. **Given** um vídeo em tela cheia ou outro programa pedindo pra tela não apagar, **When** o tempo
   passa, **Then** a tela não bloqueia sozinha.
3. **Given** "Lock before suspend" ligado (o padrão), **When** o computador suspende por qualquer
   caminho, **Then** a tela bloqueia antes, e ao acordar o primeiro quadro é a tela de bloqueio.
4. **Given** "Lock after" em "Never", **When** o tempo passa, **Then** a tela não bloqueia sozinha (o
   bloqueio antes de suspender continua valendo).
5. **Given** a opção trocada em SYSTEM › Power, **When** a escolha muda, **Then** vale na hora, sem
   reiniciar o shell.

---

### User Story 4 - Várias telas (Priority: P2)

Com dois monitores, as duas telas ficam cobertas. O cartão de autenticação fica numa só (a do
foco); a outra mostra o papel e o relógio. Um monitor ligado com a tela bloqueada já aparece coberto.

**Why this priority**: O dono usa o painel do notebook e um Dell externo. Com uma tela só, a v0 já
funciona; com duas, ela precisa cobrir as duas pra ser segura.

**Independent Test**: Na VM com dois monitores: bloquear e tirar screenshot das duas telas; ligar um
terceiro monitor com a tela bloqueada e conferir que ele aparece coberto.

**Acceptance Scenarios**:

1. **Given** dois monitores, **When** a tela bloqueia, **Then** os dois ficam cobertos, e o cartão
   aparece só no monitor do foco.
2. **Given** a tela bloqueada, **When** um monitor é ligado, **Then** ele aparece coberto desde o
   primeiro quadro.
3. **Given** a tela bloqueada, **When** o monitor com o cartão é desligado, **Then** o cartão passa
   pra outro monitor, com o que já foi digitado.
4. **Given** escalas diferentes (1,25 no notebook, 1 no externo), **When** a tela bloqueia, **Then**
   cada tela segue a regra do tamanho do jogo do design system.

---

### User Story 5 - Screenshots determinísticos no lab (Priority: P2)

Quem desenvolve abre a tela de bloqueio no lab com dados de teste (relógio fixo, nome de usuário de
exemplo) e em cada estado (pronta, digitando, conferindo, senha errada, tentativas travadas, Caps
Lock), sem precisar bloquear de verdade, e tira screenshots que saem iguais a cada vez.

**Why this priority**: É o que permite revisar o visual e comparar versões. Não muda o produto, mas
é a evidência que a constituição pede (princípio IV).

**Independent Test**: No lab, abrir cada estado pelas fixtures nos dois perfis de monitor, tirar
screenshots duas vezes e comparar: as imagens batem.

**Acceptance Scenarios**:

1. **Given** as fixtures, **When** um estado é pedido, **Then** a tela aparece nele, com o relógio
   fixo, sem conferir senha nenhuma.
2. **Given** duas capturas do mesmo estado, **When** são comparadas, **Then** são iguais.
3. **Given** o modo de fixtures, **When** ele está ligado, **Then** ele nunca desbloqueia nem trava
   uma sessão de verdade.

### Edge Cases

- **O shell cai com a tela bloqueada:** a sessão continua bloqueada (o compositor não mostra o
  desktop), e o supervisor que sobe o shell de novo traz a tela de bloqueio de volta. Se nem isso
  der, a pessoa desbloqueia por um terminal de texto (TTY) com um comando documentado no README.
- **Bloquear duas vezes** (o menu e o tempo sem uso ao mesmo tempo): fica uma tela só, sem animação
  por cima de animação.
- **Bloquear com o menu de pausa, um diálogo ou uma transmissão abertos:** eles somem antes da tela
  de bloqueio cobrir, e não voltam por cima dela.
- **Teclas de volume e brilho com a tela bloqueada:** continuam funcionando (os atalhos do arquivo
  do produto já valem com a tela travada).
- **Senha vazia + Enter:** não manda nada pro sistema, sem erro.
- **Usuário sem senha:** fora da v0; o bloqueio não deve deixar a sessão inacessível (o comportamento
  exato fica pro plano).
- **Movimento reduzido ligado:** sem o rasgo e sem as varreduras, como no login.
- **Hora mudando com a tela bloqueada** (fuso, horário de verão): o relógio acompanha.

## Requirements *(mandatory)*

### Functional Requirements

**Bloquear e desbloquear**

- **FR-001**: O shell MUST atender o pedido de bloquear da sessão (`loginctl lock-session`, o que
  POWER › Lock já manda) e cobrir todas as telas em menos de 1 s.
- **FR-002**: O bloqueio MUST ser o do YoRHa-Shell quando o produto está instalado e o shell está
  rodando. [NEEDS CLARIFICATION: e quando a pessoa já tem outro bloqueador ligado ao mesmo pedido
  (o hyprlock com o hypridle, por exemplo, que é o caso comum de quem vem do Serpantinum)? O
  YoRHa-Shell assume sozinho, com uma opção pra desligar o dele, ou só atende se a pessoa ligar o
  dele? O produto não mexe na config da pessoa (princípio II), então dois bloqueadores podem
  aparecer juntos se os dois atenderem.]
- **FR-003**: A tela MUST conferir a senha do usuário da sessão pelo PAM do sistema, sem guardar a
  senha em lugar nenhum além da memória durante a conferência.
- **FR-004**: Desbloquear MUST devolver a sessão como estava: as janelas, o workspace e o foco.
- **FR-005**: Com a tela bloqueada, nenhum conteúdo do desktop, nem transmissões, nem o menu, MUST
  aparecer em nenhuma tela. Se o shell cair, a sessão MUST continuar bloqueada.
- **FR-006**: O README MUST dizer como desbloquear por um terminal de texto se a tela de bloqueio
  não voltar.

**A cara**

- **FR-007**: A tela MUST seguir a família do LOGIN da 011: o fundo da cena "Menu", as réguas do
  shell no tamanho do jogo, um cabeçalho no mesmo estilo (texto nosso), o relógio com a data no
  centro e o cartão de autenticação à direita com o nome do usuário, o campo de quadradinhos e as
  mensagens. Sem lista de usuários, sem Session, sem Reboot e sem Shut down na v0.
- **FR-008**: A espera da conferência MUST usar o anel de carregamento do cursor. A senha errada
  MUST mostrar "Authentication failed." na cor de alerta, com o rasgo do login, e limpar o campo. As
  tentativas travadas pelo sistema MUST aparecer com o tempo que falta. O Caps Lock MUST aparecer
  como no login.
- **FR-009**: A tela MUST NOT ter som de digitação. Os sons de confirmar e de erro MAY tocar,
  seguindo "Interface sounds" e o volume do shell.

**Bloquear sozinho**

- **FR-010**: SYSTEM › Power MUST ganhar "Lock after" (1 min, 5 min, 10 min, 15 min, 30 min, Never;
  padrão 5 min) e "Lock before suspend" (padrão ligado), valendo na hora. [NEEDS CLARIFICATION: a v0
  também faz funcionar as opções de Power que hoje são só de exemplo ("Screen off after", "Suspend
  after" e "Lid closed")? Sem elas, quem vem do Serpantinum perde o apagar da tela e o suspender
  sozinho, se eles estiverem no Serpantinum e não na config dela; com elas, a spec cresce.]
- **FR-011**: O tempo sem uso MUST respeitar os pedidos de programas pra tela não apagar (vídeo,
  apresentação).
- **FR-012**: Com "Lock before suspend" ligado, a tela MUST estar bloqueada antes de o computador
  suspender, e o primeiro quadro depois de acordar MUST ser a tela de bloqueio.

**Telas**

- **FR-013**: Todo monitor MUST ficar coberto, inclusive os ligados com a tela bloqueada. O cartão
  MUST ficar só no monitor do foco e passar pra outro, com o que foi digitado, se esse monitor sair.

**Opções e testes**

- **FR-014**: As alternativas de design MUST ser opções trocadas na hora em SYSTEM › Power, com a
  recomendada como padrão: o relógio (`big`, `small`, `none`, como no login; padrão `big`). O
  movimento reduzido MUST valer como no resto do shell.
- **FR-015**: A tela MUST ter um modo de fixtures pro lab, com o relógio fixo, um usuário de
  exemplo e cada estado (pronta, digitando, conferindo, senha errada, tentativas travadas, Caps
  Lock), que nunca bloqueia nem desbloqueia uma sessão de verdade.
- **FR-016**: O estado da tela MUST poder ser lido por um comando (bloqueada ou não, o estado do
  cartão), pros testes do lab.
- **FR-017**: A tela MUST escrever no log do shell cada troca de estado, sem a senha, e sem erro de
  QML num ciclo normal.

### Key Entities

- **Sessão bloqueada**: o estado da sessão (bloqueada ou não), que o sistema e o shell enxergam
  igual.
- **Cartão de autenticação**: o estado da conferência (pronto, digitando, conferindo, senha errada,
  tentativas travadas), o que foi digitado (só na memória) e o monitor em que está.
- **Opções do bloqueio**: "Lock after", "Lock before suspend" e o relógio, em SYSTEM › Power, salvas
  como as outras opções do menu.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Na VM, em 20 bloqueios pelo menu e pelo comando, a tela cobre tudo em menos de 1 s, e
  nenhuma captura do lab (uma a cada 0,25 s) mostra o desktop depois do pedido.
- **SC-002**: Na VM, 20 de 20 desbloqueios com a senha certa voltam pra sessão com as janelas no
  lugar, e 20 de 20 tentativas com a senha errada são recusadas com a mensagem.
- **SC-003**: Na VM, as tentativas travadas pelo sistema aparecem com o tempo que falta, e a senha
  certa desbloqueia depois do tempo.
- **SC-004**: Com o tempo sem uso encurtado no lab, a tela bloqueia no tempo escolhido, com no máximo
  5 s de diferença, e não bloqueia com um programa pedindo pra tela não apagar.
- **SC-005**: Em 10 suspensões da VM com "Lock before suspend" ligado, nenhuma captura depois de
  acordar mostra o desktop.
- **SC-006**: Com dois monitores, as duas telas ficam cobertas, e o cartão aparece só numa (screenshot
  das duas nos perfis do lab).
- **SC-007**: Em 5 quedas forçadas do shell com a tela bloqueada, a sessão continua bloqueada, e a
  tela volta quando o shell sobe de novo.
- **SC-008**: As capturas de cada estado das fixtures saem iguais em duas rodadas, nos dois perfis
  de monitor, e o dono aprova o visual antes do merge.
- **SC-009**: Em 10 ciclos de bloquear e desbloquear, o log do shell não tem erro de QML, e a senha
  não aparece em nenhum log.

## Assumptions

- **Público:** o mesmo da 015 (Arch, Hyprland 0.56+ com config em Lua). O Niri fica pra S5.
- **O usuário da sessão** é quem desbloqueia; não há "Other user…" nem troca de usuário na v0.
- **As tentativas travadas** vêm da regra do próprio sistema (no Arch, o padrão trava depois de
  alguns erros seguidos); a tela só mostra, não muda a regra.
- **A entrada da tela** é rápida (cobre tudo de uma vez e os painéis entram com um fade curto), sem
  o glitch do login: o bloqueio tem que ser instantâneo. Um glitch como opção fica pra depois.
- **Depois da 015:** o nome é YoRHa-Shell, e os textos e caminhos seguem o da `main` na hora do
  plano.
- **Fora da v0:**
  - o agente de polkit (a outra metade da U5, numa spec própria);
  - digital e outros jeitos de entrar além da senha;
  - trocar de usuário, Reboot, Shut down e Suspend na tela de bloqueio;
  - notificações, controle de música e o OSD por cima da tela de bloqueio;
  - um papel de parede próprio do bloqueio;
  - o glitch de entrada como opção;
  - usuários sem senha.
- **Máquina do dono:** como sempre, nada roda nela; o teste é em VM. A troca do Serpantinum na
  máquina do dono é decisão dele, depois de homologar na VM (U7).
