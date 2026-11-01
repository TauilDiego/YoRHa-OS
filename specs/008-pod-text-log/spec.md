# Feature Specification: Pod e text log (notificações e OSD)

**Feature Branch**: `008-pod-text-log` (sai da `004-wallpaper-system`, porque reusa a moldura de popup
da 003, o layout de lista + prévia + opções da 004 e a barra transparente da emenda da 004)

**Created**: 2026-10-27

**Status**: Decisões do dono de 2026-10-27 aplicadas (seção "Clarifications"); spec e plano aguardando a
aprovação do dono

**Input**: Fase U4 do `PLAN.md` (§9): "U4 Pod e text log | Notificações e OSD | Uma notificação de
teste vira transmissão do Pod". O shell passa a ser o servidor de notificações do desktop, no lugar
de mako/dunst. As notificações aparecem do jeito que o jogo mostra as falas do Pod e o text log:
quem fala, um texto que vai sendo digitado e um histórico que dá pra abrir. A fase também cobre os
avisos de tela (OSD) de volume, brilho e afins, na mesma linguagem. A faixa de tutorial do jogo
(`docs/design-system.md` §6) é a referência visual. Mockup desta spec (publicado pela sessão
principal; arquivo de trabalho `mock008/index.html` no scratchpad da sessão).

## Vocabulário

- **Transmissão:** uma notificação na tela, no estilo das falas do Pod.
- **Faixa:** o material das superfícies passageiras desta fase (transmissão, faixa crítica, OSD):
  tinta translúcida com retícula e arcos finos, texto claro, como a faixa de tutorial do jogo.
- **Quem fala:** o rótulo da transmissão. É o nome do app; as mensagens do próprio YoRHa-OS falam
  com a **voz do sistema**, `Relay 01` de fábrica (nome nosso, não o do jogo; trocável nas
  configurações).
- **Text log:** o histórico das transmissões. É uma tela só, que aparece num popup próprio agora e
  numa aba do menu de pausa quando o U3 (spec 007) chegar.
- **Opções de notificações:** a categoria "Notifications" das configurações (spec 003), onde ficam as
  alternativas de desenho desta fase, trocáveis ao vivo.

## Clarifications

### Session 2026-10-27 (decisões do dono)

- **Regra geral:** alternativa de desenho vira opção nas configurações do sistema, trocável ao vivo, com
  a recomendada de fábrica, mesmo quando o dono acha que não vai usar. → Nova categoria
  **Notifications** no catálogo da 003 (US7, FR-038 a FR-043).
- Q: Onde aparecem as transmissões normais? → A: as três, como opção `Position`: **Corner** (de
  fábrica), **Top band** e **Subtitle** (FR-004).
- Q: Onde fica o OSD? → A: opção `OSD position`: **Bottom** (de fábrica) ou **Top** (FR-028).
- Q: O text log vai pro disco? → A: opção `Text log`: **Session only** (de fábrica) ou **Saved** (as
  últimas 100 no estado do usuário) (FR-019).
- Q: Como o YoRHa-OS se chama quando fala? → A: opção `System voice`: **Relay 01** (de fábrica),
  **YoRHa-OS** ou **System** (FR-003).
- Q: O text log é popup ou aba do menu de pausa? → A: **os dois**: popup agora e aba do menu de pausa
  quando o U3 chegar, com a mesma tela (FR-020, FR-044).
- Q: Atalhos? → A: **adiados pelo dono.** `SUPER + N` (log) e `SUPER + CTRL + N` (não perturbe), com
  ALT na VM, ficam como proposta, pendentes de confirmação (FR-020, FR-026).
- Pela regra geral, também viram opção as outras escolhas únicas que tinham alternativa razoável:
  monitor, quantas na tela, duração, digitação, tamanho do log e o que fazer em tela cheia (FR-039).
- **OSD:** o aviso curto que aparece ao mudar volume, microfone ou brilho.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Uma notificação vira transmissão (Priority: P1)

Um app manda uma notificação (ou o usuário roda `notify-send` no terminal). No monitor em foco,
abaixo da barra do topo e encostada na direita (na posição de fábrica, `Corner`; US7), aparece uma
transmissão:
- a faixa entra varrendo da borda;
- em cima, um quadradinho e quem fala ("Firefox", "Relay 01") com a hora à direita;
- embaixo, o título em peso forte e o texto, que vai sendo digitado com um cursor de bloco no fim.

Depois de um tempo que depende do tamanho do texto, a transmissão some e fica guardada no text log.
Passar o mouse por cima pausa o tempo; clicar fecha (ou dispara a ação padrão, US3). Várias
transmissões empilham, a mais nova em cima.

**Why this priority**: É o "pronto quando" da fase e o que substitui o servidor de notificações de
hoje. Sozinha, já entrega notificações usáveis no tema.

**Independent Test**: Na VM, sem outro servidor de notificações rodando, mandar `notify-send "Build"
"The nightly build finished."` e tirar screenshots durante a digitação e depois dela; conferir o
estado exportado (transmissões na tela, quem fala, texto, tempo restante).

**Acceptance Scenarios**:

1. **Given** o desktop e nenhum outro servidor de notificações, **When** o shell inicia, **Then** ele
   passa a ser o servidor de notificações da sessão, e o estado exportado diz isso.
2. **Given** o shell servindo, **When** um app manda uma notificação, **Then** a transmissão aparece
   no monitor em foco, abaixo da barra, encostada na direita, com quem fala, a hora, o título e o
   texto digitando.
3. **Given** uma transmissão digitando, **When** o usuário passa o mouse por cima, **Then** o texto
   aparece inteiro na hora e o tempo para até o mouse sair.
4. **Given** uma transmissão sem ação padrão, **When** o usuário clica nela, **Then** ela some e fica
   no text log; com o botão direito, some sempre, mesmo com ação padrão.
5. **Given** três transmissões na tela, **When** chega a quarta, **Then** a mais velha (não crítica)
   sai da tela pro text log e a nova entra em cima; se a que saiu nem tinha terminado de digitar, ela
   conta como não lida.
6. **Given** um app que manda de novo a mesma notificação (substituindo a anterior), **When** ela
   chega, **Then** a transmissão existente muda no lugar, digitando só a parte do texto que mudou.

---

### User Story 2 - Urgência: baixa, normal e crítica (Priority: P1)

As transmissões mostram a urgência que o app pediu:
- **baixa:** um bloco cinza na esquerda da faixa e menos tempo na tela;
- **normal:** um bloco claro;
- **crítica:** uma faixa larga, da largura do monitor, logo abaixo da barra, como a faixa de tutorial
  do jogo, com o bloco e a etiqueta `CRITICAL` na cor `alert`. Ela não some sozinha: fica até o
  usuário dispensar ou agir, e a pilha das outras desce pra baixo dela enquanto ela está na tela.

**Why this priority**: Sem urgência, um aviso de bateria acabando some como um e-mail qualquer. Junto
com a US1, cobre o mínimo de notificações pra trocar o Serpantinum (PLAN §7).

**Independent Test**: Na VM, mandar uma notificação de cada urgência (`notify-send -u low|normal|critical`),
tirar screenshots e conferir pelo estado exportado quanto tempo cada uma fica.

**Acceptance Scenarios**:

1. **Given** uma notificação de urgência baixa, **When** ela chega, **Then** aparece com o bloco cinza
   e some em ≈4 s depois de digitar.
2. **Given** uma notificação crítica, **When** ela chega, **Then** a faixa larga aparece no monitor em
   foco, logo abaixo da barra, com o vermelho `alert` no bloco e na etiqueta `CRITICAL`, e continua lá
   depois de 60 s.
3. **Given** a faixa crítica na tela, **When** o usuário clica no × ou numa ação dela, **Then** ela some
   e fica no text log.
4. **Given** uma faixa crítica e transmissões normais ao mesmo tempo, **When** chegam outras normais,
   **Then** elas continuam empilhando no canto, abaixo da faixa; a faixa crítica não conta no limite de
   três.

---

### User Story 3 - Ações e resposta (Priority: P2)

Quando o app oferece ações ("Open", "Snooze", "Mark as read"), elas aparecem como botões na parte de
baixo da transmissão. Clicar numa ação avisa o app e fecha a transmissão (a não ser que o app peça
pra ela ficar). Quando o app aceita resposta (mensageiros), aparece o botão "Reply": clicar abre um
campo de texto dentro da transmissão; Enter manda a resposta, Esc cancela. Só nessa hora a
transmissão pega o teclado.

**Why this priority**: Muitos apps (agenda, e-mail, mensageiros, downloads) dependem das ações; sem
elas, a notificação é só leitura. As US1 e US2 já funcionam sem.

**Independent Test**: Na VM, mandar `notify-send --action=open=Open --action=later=Snooze "Calendar"
"Stand-up in 10 minutes."`, clicar em "Snooze" e conferir que o comando imprime `later`; repetir com
um cliente de teste que aceita resposta e conferir o texto recebido.

**Acceptance Scenarios**:

1. **Given** uma transmissão com duas ações, **When** ela aparece, **Then** os dois botões ficam embaixo
   do texto, na ordem que o app mandou.
2. **Given** os botões na tela, **When** o usuário clica num deles, **Then** o app recebe a ação e a
   transmissão some.
3. **Given** uma notificação que aceita resposta, **When** o usuário clica em "Reply", digita e aperta
   Enter, **Then** o app recebe o texto, a transmissão some e o teclado volta pra janela de antes.
4. **Given** o campo de resposta aberto, **When** o usuário aperta Esc, **Then** o campo fecha sem
   mandar nada e o tempo da transmissão volta a correr.

---

### User Story 4 - O text log (Priority: P2)

O usuário aperta um atalho (ou clica no contador da barra) e abre o text log: um popup no centro do
monitor em foco, com o resto da tela escurecido, no layout de lista + prévia + opções da 004. A mesma
tela vira a aba de log do menu de pausa quando o U3 (spec 007) chegar:
- **à esquerda:** as transmissões da sessão, da mais nova pra mais velha, agrupadas em NOW
  (última hora) e EARLIER, com a pipa;
- **no meio:** a transmissão em foco, inteira, na faixa, digitada de novo ao receber o foco, com as
  ações que ainda valem;
- **à direita:** as opções (Do not disturb, o filtro Show e Clear all) e as contagens.

Abrir o log marca tudo como lido. Com a opção `Text log` em `Saved`, o log também mostra as
transmissões das sessões anteriores (as últimas 100), sem ações.

**Why this priority**: É a metade "text log" da fase e o lugar pra ler o que passou rápido, o que
chegou em não perturbe e o que foi cortado numa enxurrada. As transmissões já funcionam sem ele.

**Independent Test**: Na VM, com dados de teste, abrir pelo atalho e por comando, navegar com teclas
reais, disparar a ação de uma entrada, dispensar outra, limpar tudo e conferir pelo estado exportado
e por screenshots.

**Acceptance Scenarios**:

1. **Given** cinco transmissões na sessão, **When** o usuário abre o text log, **Then** as cinco
   aparecem na lista, a mais nova em foco, e o meio mostra o texto inteiro dela.
2. **Given** o foco numa entrada, **When** o usuário aperta ↑ ou ↓, **Then** a pipa pisca pra entrada
   nova e o meio digita o texto dela de novo.
3. **Given** uma entrada cujo app ainda espera a ação, **When** o usuário aperta Enter, **Then** a ação
   padrão dispara e a entrada fica marcada como respondida.
4. **Given** uma entrada cujo app já fechou a notificação, **When** ela está em foco, **Then** as ações
   aparecem apagadas e o meio diz "The app closed this notification."
5. **Given** o foco numa entrada, **When** o usuário aperta Delete, **Then** a entrada sai do log e o
   foco vai pra próxima.
6. **Given** o foco na lista, **When** o usuário aperta →, **Then** o foco vai pras opções; ←/→ mudam
   Do not disturb e o filtro; Enter em "Clear all" esvazia o log; Esc volta; um segundo Esc fecha.
7. **Given** transmissões não lidas, **When** o log abre, **Then** o contador da barra zera.
8. **Given** a opção `Text log` em `Saved` e entradas no log, **When** o usuário sai da sessão e entra
   de novo, **Then** o log abre com as mesmas entradas (as últimas 100), marcadas como de uma sessão
   anterior, com as ações apagadas.
9. **Given** a tela do log desenhada num corpo de outro tamanho (o do menu de pausa), **When** ela
   aparece, **Then** as três colunas se ajustam ao corpo, sem cortar nem vazar, com as mesmas teclas.

---

### User Story 5 - OSD de volume, microfone e brilho (Priority: P2)

Ao mudar o volume (pelas teclas, por outro app ou por comando), aparece na parte de baixo do monitor
em foco, centralizado (de fábrica; `OSD position` muda pro topo, US7), um aviso curto na faixa: quadradinho, o nome (VOLUME), o medidor (na trilha
translúcida da faixa; emenda de 2026-10-29) e o número. Mudo mostra MUTE e o medidor apagado. O mesmo vale pro brilho
da tela (BRIGHTNESS) e pro microfone (MIC ON / MIC OFF, sem medidor). Apertar várias vezes atualiza o
mesmo aviso, que some ≈1,2 s depois da última mudança.

**Why this priority**: O OSD está na lista do mínimo pra trocar o Serpantinum (PLAN §7) e usa a mesma
faixa, mas é independente das notificações.

**Independent Test**: Na VM, mudar o volume três vezes seguidas e conferir que aparece um aviso só,
com o valor que o sistema informa; repetir com mudo e com o brilho (na VM, por comando, porque não há
luz de fundo).

**Acceptance Scenarios**:

1. **Given** o volume em 64, **When** o usuário aperta a tecla de aumentar, **Then** o OSD mostra
   VOLUME, o medidor e 66 (o passo do sistema), no monitor em foco.
2. **Given** o OSD na tela, **When** o usuário aperta a tecla mais duas vezes, **Then** o mesmo OSD
   atualiza o valor e o tempo recomeça; nunca há dois OSDs.
3. **Given** o volume mudo, **When** o OSD aparece, **Then** ele mostra MUTE com o medidor apagado.
4. **Given** o popup de configurações aberto com o foco no slider de volume, **When** o valor muda por
   ele, **Then** o OSD não aparece (o popup já mostra o valor).

---

### User Story 6 - Não perturbe (Priority: P3)

O usuário liga o não perturbe por atalho, por comando ou nas opções do text log. Enquanto ele está
ligado, nada aparece na tela, a não ser as críticas: tudo vai direto pro text log como não lido, e a
barra mostra `DND` com o número de não lidas. O OSD continua aparecendo (é resposta a uma ação do
próprio usuário). Uma janela em tela cheia faz o mesmo que o não perturbe enquanto está em foco.

**Why this priority**: É conforto, não o mínimo. As outras histórias funcionam sem ele.

**Independent Test**: Na VM, ligar o não perturbe, mandar cinco notificações normais e uma crítica,
e conferir pelos screenshots e pelo estado exportado: nenhuma normal na tela, a crítica na tela, seis
no log, cinco não lidas na barra.

**Acceptance Scenarios**:

1. **Given** o não perturbe ligado, **When** chega uma notificação normal, **Then** ela não aparece, vai
   pro log como não lida e o contador da barra sobe.
2. **Given** o não perturbe ligado, **When** chega uma crítica, **Then** a faixa crítica aparece mesmo
   assim.
3. **Given** o não perturbe ligado, **When** o shell reinicia, **Then** ele continua ligado.
4. **Given** uma janela em tela cheia em foco, **When** chega uma notificação normal, **Then** ela vai
   direto pro log; ao sair da tela cheia, nada aparece de uma vez (o contador da barra avisa).

---

### User Story 7 - As opções de notificações (Priority: P2)

O usuário abre as configurações do sistema (popup da 003, ou a aba SYSTEM do menu de pausa quando o
U3 chegar) e encontra a categoria **Notifications**, com as alternativas desta fase: não perturbe,
posição das transmissões (Corner, Top band, Subtitle), posição do OSD (Bottom, Top), o log no disco
(Session only, Saved), a voz do sistema (Relay 01, YoRHa-OS, System) e as outras escolhas (monitor,
quantas na tela, duração, digitação, tamanho do log, tela cheia). Cada mudança vale na hora, sem
reiniciar nada: a próxima transmissão (e as que estão na tela) já aparece do jeito novo. As escolhas
ficam guardadas como estado do usuário e sobrevivem a reiniciar o shell.

**Why this priority**: É a regra geral do dono (alternativa vira opção). As US1–US6 funcionam com os
valores de fábrica sem ela.

**Independent Test**: Na VM, abrir as configurações, ir em Notifications, trocar `Position` pras três
posições mandando um `notify-send` em cada, trocar `OSD position` mudando o volume, trocar `System
voice` disparando uma mensagem do YoRHa-OS, trocar `Text log` pra `Saved`, reiniciar o shell e conferir
o log; tudo por screenshots e pelo estado exportado.

**Acceptance Scenarios**:

1. **Given** as configurações abertas, **When** o usuário vai pra categoria Notifications, **Then** ela
   mostra as opções da FR-039 com os valores atuais e, no quadro de descrição, o que cada uma faz e o
   padrão.
2. **Given** `Position` em `Corner` e uma transmissão na tela, **When** o usuário troca pra `Top band`,
   **Then** a transmissão na tela passa pra faixa no topo na hora, e as próximas chegam lá.
3. **Given** `Position` em `Subtitle`, **When** chega uma notificação, **Then** ela aparece embaixo, no
   centro do monitor, como as falas do Pod, acima do OSD; as mais novas embaixo.
4. **Given** `OSD position` em `Top`, **When** o volume muda, **Then** o OSD aparece no topo, logo abaixo
   da barra (ou da faixa crítica, se houver uma).
5. **Given** `System voice` em `System`, **When** o YoRHa-OS manda uma mensagem própria, **Then** quem fala
   é `System`; as notificações dos apps não mudam.
6. **Given** `Text log` em `Saved`, **When** o usuário troca pra `Session only`, **Then** o arquivo do log
   é apagado na hora e o log da sessão continua na memória.
7. **Given** uma escolha feita, **When** o shell reinicia, **Then** ela continua valendo; a config do
   usuário (`shell.json`) nunca é escrita.

### Edge Cases

- **Enxurrada** (um app manda 5 em 1 s, ou um script manda 100): transmissões seguidas do mesmo app se
  juntam numa só, com o contador `×5` ao lado de quem fala e o texto da mais nova; apps diferentes
  respeitam o limite de três na tela; as que saírem antes de terminar de digitar vão pro log como não
  lidas, com a linha `+N in log` embaixo da pilha. O log guarda as 100 mais novas e descarta as mais
  velhas.
- **Texto longo:** na tela, até 4 linhas, cortadas com reticências e a linha `More in log`; a digitação
  acelera pra terminar em no máximo ≈0,7 s. No log, o texto aparece inteiro, com rolagem.
- **Título longo ou nome de app longo:** uma linha, cortada com reticências.
- **Sem nome de app:** quem fala vira o nome do app pela entrada de desktop, se houver; senão,
  `Unknown`.
- **Sem texto, só título:** a transmissão fica com uma linha só, sem cursor de digitação.
- **Imagem** (avatar, miniatura): aparece num quadrado de 72 px à direita do texto, cortado no centro,
  sem cantos arredondados, com uma moldura de 2 px. Imagem que não carrega é ignorada, com uma linha no
  log do shell. O ícone do app não aparece: o quadradinho ocupa o lugar dele, como no jogo.
- **Marcação no texto:** negrito, itálico e sublinhado aparecem; links viram texto comum; o resto da
  marcação é tirado, nunca interpretado.
- **Progresso** (a dica de valor 0–100, usada por downloads e scripts): a transmissão mostra o medidor
  (na trilha translúcida da faixa) embaixo do texto e atualiza no lugar quando o app manda o valor novo.
- **Crítica durante o não perturbe:** aparece (US6). Crítica em tela cheia: aparece também.
- **Duas críticas:** a segunda entra na mesma faixa, que mostra a mais nova e `1/2` com setas ◂ ▸ pra
  ver a outra.
- **App fecha a notificação:** a transmissão some da tela; a entrada fica no log com as ações apagadas.
- **Notificação passageira** (o app pede pra não guardar): aparece e não entra no log.
- **Outro servidor de notificações rodando:** o shell não consegue ser o servidor; o resto da UI
  funciona, o log do shell diz qual processo tem o nome e o estado exportado mostra `server: false`.
- **Monitor em foco muda com transmissões na tela:** elas ficam onde apareceram até sumir; as novas
  vão pro monitor em foco.
- **Monitor desconectado com transmissões nele:** elas vão pro log como não lidas, sem erro.
- **Movimento reduzido ou dados de teste:** nada anima: a faixa aparece sem varrer, o texto aparece
  inteiro, sem cursor, e a linha de tempo some; o OSD aparece e some sem fade.
- **Volume acima de 100%:** o medidor fica cheio e o número mostra o valor real (ex.: 120).
- **Tela pequena ou escala alta:** as larguras são em medidas do jogo × escala da tela; nada vaza do
  monitor.
- **`Top band` com a faixa crítica:** a crítica fica em cima, logo abaixo da barra; as faixas normais
  empilham embaixo dela, cada uma da largura do monitor, a mais nova em cima.
- **`Subtitle` com o OSD embaixo:** a pilha fica acima da área do OSD, que nunca é coberta; a mais nova
  fica embaixo, mais perto do centro de baixo.
- **OSD no topo com a faixa crítica:** o OSD desce pra logo abaixo da faixa crítica.
- **Troca de posição com transmissões na tela:** elas mudam de lugar na hora, sem animação, e mantêm o
  tempo restante.
- **Log salvo e privacidade:** o arquivo só pode ser lido pelo usuário; as passageiras nunca entram;
  imagens só entram como caminho de arquivo (imagem enviada em dados não é gravada); ações e respostas
  não são gravadas.
- **Log salvo ilegível ou de outra versão:** o log começa vazio, o arquivo vai pra um backup ao lado e
  o log do shell registra o motivo.
- **Diminuir o tamanho do log:** as entradas mais velhas além do novo limite saem na hora (e do
  arquivo, com `Saved`).
- **Monitor fixo que não existe mais:** as transmissões vão pro monitor em foco até ele voltar; a opção
  continua mostrando o nome dele.

## Requirements *(mandatory)*

### Functional Requirements

**Servidor (US1)**

- **FR-001**: O shell MUST ser o servidor de notificações da sessão (o padrão do freedesktop), no lugar
  de mako, dunst ou do servidor do Serpantinum, e anunciar que sabe: corpo, marcação básica, ações,
  resposta, imagens e persistência.
- **FR-002**: Se outro processo já for o servidor, o shell MUST continuar funcionando sem as
  transmissões, registrar o motivo no log e exportar `server: false`.

**Transmissão (US1)**

- **FR-003**: Cada notificação MUST aparecer como uma transmissão na faixa (tinta translúcida com
  retícula, texto claro, cantos retos, sem desfoque), com:
  - um bloco de 14 px na esquerda, na cor da urgência (FR-010);
  - quem fala: quadradinho + nome do app (ou a voz do sistema, `Relay 01` de fábrica, pras mensagens
    do YoRHa-OS; FR-039), `small`, e a hora de chegada à direita;
  - o título, uma linha, peso forte;
  - o texto, até 4 linhas, digitando;
  - opcionalmente: imagem (à direita), medidor de progresso e botões de ação (embaixo);
  - uma linha fina embaixo que encolhe com o tempo restante.
- **FR-004**: A pilha MUST ficar no monitor escolhido (de fábrica, o em foco na hora da chegada; ou um
  monitor fixo pelo nome), com até 3 transmissões (opção `On screen`), numa das três posições da opção
  `Position`, todas como no mockup:
  - **Corner** (de fábrica): abaixo da barra do topo, encostada na direita, 540 de largura, a mais nova
    em cima;
  - **Top band**: faixas da largura do monitor logo abaixo da barra, o texto numa coluna centrada,
    separadas por 2 px, a mais nova em cima;
  - **Subtitle**: embaixo, no centro, 1100 de largura, acima da área do OSD, a mais nova embaixo.
- **FR-005**: A transmissão MUST entrar com uma varredura da faixa a partir da borda (≈150 ms, o
  `motion.highlight`) e sair com um fade (≈150 ms). As outras da pilha deslizam pro lugar novo.
- **FR-006**: O texto MUST ser digitado: título e quem fala aparecem inteiros; o corpo entra a ≈90
  caracteres por segundo, com um cursor de bloco no fim, e acelera pra nunca passar de ≈0,7 s. Passar o
  mouse completa na hora. Uma substituição digita só a partir do primeiro caractere diferente.
- **FR-007**: O tempo na tela MUST começar depois da digitação e valer: o que o app pedir, quando pedir;
  senão, baixa 4 s, normal 6 s + 1 s a cada 80 caracteres além de 120 (no máximo 12 s); crítica, sem
  limite. O mouse por cima pausa o tempo.
- **FR-008**: Sair da tela (por tempo, por clique, por limite da pilha) MUST NOT fechar a notificação
  pro app: ela continua viva no log, e as ações continuam valendo, até o usuário dispensar ou limpar o
  log, ou o app fechar. Dispensar avisa o app.
- **FR-009**: Clique esquerdo MUST disparar a ação padrão, quando houver, e senão dispensar da tela;
  clique direito MUST sempre dispensar da tela; um × aparece com o mouse por cima.

**Urgência (US2)**

- **FR-010**: A urgência MUST mudar o bloco da esquerda e o tempo: baixa em `medium-gray`, normal em
  `light-yellow`, crítica em `alert` (`#8F3A30`). A crítica também leva a etiqueta `CRITICAL` (texto
  claro sobre `alert`) ao lado de quem fala e, no log, o quadradinho em `alert`. São os únicos usos do
  `alert` nesta fase.
- **FR-011**: A crítica MUST aparecer como a faixa larga: a largura inteira do monitor em foco, logo
  abaixo da barra, com arcos finos na faixa, o texto numa coluna centrada, as ações embaixo do texto e,
  à direita, `1/N` com ◂ ▸ (quando houver mais de uma) e o ×. Ela fica até ser dispensada ou
  respondida e não conta no limite da pilha; enquanto ela está na tela, a pilha desce pra baixo dela.

**Ações e resposta (US3)**

- **FR-012**: As ações do app MUST aparecer como botões embaixo do texto, na ordem que o app mandou, até
  3 (as outras ficam no log). Botão: contorno claro de 2 px, texto `button`; com o mouse por cima, a
  tinta clara varre da esquerda e o texto fica escuro.
- **FR-013**: Uma ação MUST avisar o app e fechar a transmissão, a não ser que o app peça pra ela
  ficar (residente).
- **FR-014**: Quando o app aceita resposta, o botão "Reply" MUST abrir um campo de uma linha dentro da
  transmissão, que só então pega o teclado. Enter manda e fecha; Esc cancela e devolve o teclado pra
  janela de antes. Enquanto o campo está aberto, o tempo da transmissão para.
- **FR-015**: As transmissões MUST NOT pegar o teclado em nenhum outro caso; digitar numa janela
  nunca vai parar numa transmissão.

**Agrupamento (US1)**

- **FR-016**: Uma notificação que o app manda como substituta de outra MUST mudar a transmissão (ou a
  entrada do log) no lugar.
- **FR-017**: Notificações seguidas do mesmo app que chegam enquanto a anterior dele ainda está na
  tela MUST se juntar na mesma transmissão: ela mostra a mais nova, com `×N` ao lado de quem fala, e
  o tempo recomeça. No log, cada uma continua sendo uma entrada.
- **FR-018**: Quando a pilha está cheia, a transmissão nova MUST entrar e a mais velha (não crítica) sair
  pro log. Se a que saiu não tinha terminado de digitar, ela conta como não lida, e a linha `+N in log`
  aparece embaixo da pilha com essas não lidas; clicar nela abre o log. A linha some quando a pilha
  esvazia ou o log abre.

**Text log (US4)**

- **FR-019**: O log MUST guardar as transmissões (as 100 mais novas; opção `Log size`), menos as
  passageiras, conforme a opção `Text log`:
  - **Session only** (de fábrica): em memória; sobrevive a recarregar o shell, não a sair da sessão;
    nada vai pro disco;
  - **Saved**: também num arquivo no estado do usuário (`$XDG_STATE_HOME/yorha-os/`), legível só por
    ele, regravado a cada mudança; ao entrar na sessão, o log volta com as entradas salvas, marcadas
    como de uma sessão anterior e sem ações. Voltar pra `Session only` apaga o arquivo na hora.
- **FR-020**: O log MUST abrir por um atalho da sessão (proposta: `SUPER + N`; na VM, `ALT + N`;
  **pendente de confirmação do dono**), por comando de controle e por clique no contador da barra, como
  o popup da 003: centrado no monitor em foco, resto escurecido sem desfoque, teclado só pra ele, fecha
  com Esc ou clique fora.
- **FR-021**: O layout MUST seguir o mockup (no popup; no menu de pausa, o título e o rodapé são os
  da moldura do menu, FR-044): título `LOG -Transmissions`; lista à esquerda agrupada em
  NOW e EARLIER, cada linha com quadradinho, quem fala, título e hora, mais `×N` e a etiqueta `NEW`
  quando for o caso; no meio, o quadro com a transmissão em foco na faixa, inteira, com as ações, e
  APP, RECEIVED, URGENCY e STATUS embaixo; à direita, o quadro "Options" com Do not disturb, Show (All,
  Unread, Critical) e Clear all, mais UNREAD, KEPT e SERVER; rodapé de teclas.
- **FR-022**: A navegação MUST seguir o padrão de duas colunas da 003: lista com ↑/↓, Enter dispara a
  ação padrão, Delete dispensa a entrada, → vai pras opções, Esc fecha; opções com ←/→ e Enter; Esc
  volta. O mouse move o foco. A pipa fica parada, pisca na troca (240 ms) e fica clara na coluna sem
  foco. O rodapé mostra só as teclas que valem.
- **FR-023**: Ao receber o foco, a entrada MUST ser digitada de novo no meio (FR-006); as ações de uma
  notificação que o app já fechou ficam apagadas, com a frase "The app closed this notification."
- **FR-024**: Abrir o log MUST marcar tudo como lido e zerar o contador da barra.

**Barra do topo**

- **FR-025**: A barra MUST mostrar, antes do relógio, o contador de não lidas (`LOG 3`), escondido em
  zero, e `DND` no lugar de `LOG` com o não perturbe ligado. O contador segue o tom da barra (emenda da
  004: tinta sobre papel, claro sobre fundo escuro).

**Não perturbe (US6)**

- **FR-026**: O não perturbe MUST ligar e desligar por atalho (proposta: `SUPER + CTRL + N`; na VM,
  `ALT + CTRL + N`; **pendente de confirmação do dono**), por comando, pelas opções do log e pela
  categoria Notifications das configurações, e ser guardado como estado do usuário (sobrevive a
  reiniciar o shell), fora dos arquivos de configuração dele. Os quatro caminhos mostram sempre o
  mesmo valor.
- **FR-027**: Com o não perturbe ligado, ou com uma janela em tela cheia em foco (com a opção
  `In fullscreen` em `Hold`, de fábrica; em `Show`, a tela cheia não segura nada), as notificações
  baixas e normais MUST ir direto pro log como não lidas; as críticas aparecem. Com o log aberto, as
  novas entram direto na lista dele, marcadas como novas, em vez de aparecer na pilha.

**OSD (US5)**

- **FR-028**: Mudar o volume, o mudo, o mudo do microfone ou o brilho da tela, por qualquer caminho, MUST
  mostrar o OSD no monitor em foco, centralizado, na posição da opção `OSD position` (de fábrica,
  `Bottom`, a 110 da borda de baixo; `Top`, logo abaixo da barra ou da faixa crítica): faixa, quadradinho, nome, medidor
  na trilha translúcida do mockup (largura 300, os 11 px do `hp-bar`; emenda de 2026-10-29, decisão do
  dono: não o `Meter` invertido da 003) e número com algarismos tabulares; MUTE com o medidor
  apagado; MIC ON / MIC OFF sem medidor.
- **FR-029**: Um OSD MUST ficar ≈1,2 s depois da última mudança e atualizar no lugar; nunca há dois. O
  OSD não aparece quando a mudança vem de um menu do YoRHa-OS que já mostra o valor, e não entra no log.
- **FR-030**: O OSD MUST aparecer com o não perturbe ligado e MUST NOT pegar o teclado nem o mouse.

**Movimento, dados de teste e estado**

- **FR-031**: Com movimento reduzido (`reduceMotion`) ou dados de teste, nada MUST animar: sem varredura,
  sem fade, texto inteiro de uma vez e sem cursor, sem a linha de tempo.
- **FR-032**: Com dados de teste, o log e a pilha MUST vir de um arquivo de fixtures do shell
  (`notifications-default.json`), com horas fixas, pros screenshots saírem iguais. Um comando de
  controle MUST disparar as notificações de exemplo do mockup (normal, com ações, com resposta e
  imagem, crítica, enxurrada de 5, texto longo, com progresso, baixa, 100 de um script), mandando-as
  pelo caminho real de um app.
- **FR-033**: Comandos de controle MUST permitir: abrir e fechar o log, ligar e desligar o não
  perturbe, dispensar tudo da tela, limpar o log, mostrar um OSD com um valor (pra testes e pra VM sem
  brilho), mudar as opções de notificações e exportar o estado (servidor, não perturbe, opções,
  transmissões na tela com posição e tempo restante, log, não lidas, OSD visível).

**Design system, textos e qualidade**

- **FR-034**: As peças novas MUST entrar na galeria e no `docs/design-system.md` (§9):
  - a **faixa** (material) e a **faixa crítica**;
  - a **transmissão**, nas três urgências, com ações, imagem, progresso, `×N` e resposta;
  - o **texto digitado**;
  - o **botão de ação** sobre a faixa;
  - o **OSD**, com medidor, mudo e sem medidor;
  - o contador da barra.
  O log reusa a moldura da 003, `CursorList`, `KeyHints`, `OptionRow` e o layout de lista + prévia +
  opções da 004. As três posições da pilha e as duas do OSD aparecem na galeria.
- **FR-035**: Todo texto fixo MUST ficar em inglês, no lugar central de textos (`Strings`); o texto
  das notificações aparece como o app mandou.
- **FR-036**: Nenhum texto de notificação MUST passar por um interpretador de comandos, nem ser lido
  como marcação além de negrito, itálico e sublinhado (ver "Marcação no texto" nos casos de borda).
- **FR-037**: O roteiro inteiro (todas as histórias) MUST deixar o log do shell sem erro e sem aviso de
  QML.

**Opções de notificações (US7)**

- **FR-038**: As configurações da 003 MUST ganhar a categoria **Notifications** (depois de Sound), com
  as opções da FR-039. Diferente das outras categorias da 003 (que continuam dados de teste), estas
  valem de verdade: mudar uma opção muda o comportamento na hora, sem reiniciar o shell nem recarregar
  nada.
- **FR-039**: As opções, com o valor de fábrica primeiro:
  - `Do not disturb`: Off / On (o mesmo estado da FR-026);
  - `Position`: Corner / Top band / Subtitle (FR-004);
  - `OSD position`: Bottom / Top (FR-028);
  - `System voice`: Relay 01 / YoRHa-OS / System (FR-003);
  - `Text log`: Session only / Saved (FR-019);
  - `Log size`: 100 / 50 / 200 (FR-019);
  - `Monitor`: Focused / cada saída pelo nome (FR-004);
  - `On screen`: 3 / 1 / 5 (FR-004, FR-018);
  - `Duration`: Normal / Short (×0,66) / Long (×1,5), sobre os tempos da FR-007 (o tempo pedido pelo
    app não muda);
  - `Typing`: On / Off (Off: o texto aparece inteiro, como com movimento reduzido, FR-006);
  - `In fullscreen`: Hold / Show (FR-027).
- **FR-040**: As escolhas MUST ser guardadas como estado do usuário (`$XDG_STATE_HOME/yorha-os/`),
  nunca na config dele. A ordem de quem vale: a escolha guardada, depois o `shell.json` do usuário,
  depois os padrões do projeto (como o papel de parede da 004).
- **FR-041**: Uma troca de `Position`, `OSD position`, `Monitor` ou `On screen` MUST valer também pro
  que já está na tela: as transmissões mudam de lugar na hora (sem animação) e mantêm o tempo
  restante; o que passar do novo limite sai pro log.
- **FR-042**: O quadro de descrição de cada opção MUST dizer o que ela faz e o padrão; `Text log` diz
  que `Saved` grava as mensagens no disco e que voltar pra `Session only` apaga o arquivo.
- **FR-043**: Com dados de teste, as opções MUST valer só em memória (nada é gravado), pra os testes
  não mexerem no estado do usuário.

**O log em dois lugares**

- **FR-044**: A tela do log MUST ser uma peça só, que funciona em qualquer corpo de painel: no popup
  próprio (agora) e como aba do menu de pausa (spec 007, quando ela chegar), sem cópia. Ela se ajusta
  ao tamanho que recebe e expõe o título, o texto do rodapé e as teclas pra moldura que a hospeda
  desenhar.

### Key Entities

- **Notificação:** id, app (nome, entrada de desktop), quem fala, título, texto, urgência, tempo pedido
  pelo app, ações (id e rótulo), aceita resposta, imagem, valor de progresso, residente, passageira,
  hora de chegada, se substitui outra.
- **Transmissão na tela:** a notificação, o monitor, a posição na pilha, quanto já digitou, tempo
  restante, pausada ou não, contagem `×N`.
- **Entrada do log:** a notificação, lida ou não, respondida ou não, viva (o app ainda escuta) ou
  fechada.
- **Estado de notificações:** servidor ativo, não perturbe, não lidas, filtro do log.
- **OSD:** tipo (volume, microfone, brilho), valor, mudo, monitor, tempo restante.
- **Opções de notificações:** os valores da FR-039, de onde cada um veio (escolha guardada, config do
  usuário, padrão).

## Success Criteria *(mandatory)*

Cada critério diz qual evidência da VM o comprova (constituição IV). Os testes rodam dentro de
`lab/perf begin/end`.

- **SC-001**: Um `notify-send` na VM vira transmissão no monitor em foco em até 0,5 s, com quem fala,
  título e texto; o texto termina de digitar em até 0,8 s depois de aparecer. Evidência: screenshots
  durante e depois da digitação, o estado exportado e o tempo medido do host. (É o "pronto quando" da
  fase.)
- **SC-002**: Com dados de teste, dois screenshots seguidos da pilha (normal, com ações, com imagem, com
  progresso), da faixa crítica, do OSD e do log aberto são idênticos (0 px de diferença), em 1920x1080 @1
  e 2560x1600 @1,25. Evidência: os screenshots e a diferença.
- **SC-003**: Uma notificação de cada urgência fica na tela o tempo da FR-007 (±0,3 s), e a crítica
  continua na tela depois de 60 s. Evidência: o estado exportado a cada segundo.
- **SC-004**: Clicar numa ação faz o `notify-send --action` imprimir o id dela; a resposta de um cliente
  de teste chega com o texto digitado; nos dois casos o teclado volta pra janela de antes. Evidência: a
  saída dos comandos e a janela em foco do compositor antes e depois.
- **SC-005**: 100 notificações em 1 s deixam no máximo 3 transmissões na tela, 100 entradas no log e a
  barra com o número certo de não lidas; o log abre em até 0,3 s logo depois, e o CPU do shell volta ao
  repouso em até 5 s. Evidência: estado exportado, screenshot e o relatório do `lab/perf`.
- **SC-006**: Cinco notificações do mesmo app em 1 s viram uma transmissão `×5`, e o log tem 5 entradas.
  Evidência: screenshot e estado exportado.
- **SC-007**: Com o não perturbe ligado, 5 normais e 1 crítica deixam 0 normais e 1 crítica na tela, 6
  entradas no log e `DND 5` na barra; o não perturbe sobrevive a reiniciar o shell. Evidência:
  screenshots e estado exportado antes e depois.
- **SC-008**: Três mudanças de volume seguidas mostram um OSD só, com o valor que o sistema informa, que
  some entre 1,0 e 1,5 s depois da última; mudo mostra MUTE. Evidência: estado exportado, o volume
  lido do sistema e a sequência de quadros.
- **SC-009**: Uma sequência de teclas reais no log (abrir, ↓ ×2, Enter, Delete, →, ←/→ no não
  perturbe, Esc, Esc) termina com o estado esperado em cada passo e o log fechado. Evidência: o estado
  exportado depois de cada tecla.
- **SC-010**: Com dois monitores, a transmissão, a faixa crítica e o OSD aparecem só no monitor em foco.
  Evidência: screenshots dos dois monitores.
- **SC-011**: Com movimento reduzido, o primeiro quadro em que a transmissão aparece já tem o texto
  inteiro. Evidência: a sequência de quadros.
- **SC-012**: O log do shell fica sem erro e sem aviso de QML depois do roteiro inteiro, e o lint fica
  limpo. Evidência: o trecho do log e o lint.
- **SC-013**: O dono aprova o visual comparando os screenshots com o mockup. Evidência: a aprovação.
- **SC-014** (US7): Cada valor de `Position` e de `OSD position`, trocado pelas configurações com teclas
  reais, muda o lugar da transmissão (ou do OSD) já na tela e o da próxima, sem reiniciar o shell e sem
  aviso de QML. Evidência: screenshots antes e depois de cada troca e o estado exportado.
- **SC-015** (US7): Com `Text log` em `Saved`, 5 entradas sobrevivem a reiniciar o shell e a reiniciar a
  sessão da VM; o arquivo tem permissão só do usuário; voltar pra `Session only` apaga o arquivo; nada é
  escrito no `~/.config`. Evidência: o estado exportado, `stat` do arquivo e a lista do `~/.config` antes
  e depois.
- **SC-016** (FR-044): A tela do log desenhada num corpo do tamanho do menu de pausa (na galeria) fica
  sem corte e sem vazamento em 1080 e hidpi. Evidência: screenshots da galeria.

## Assumptions

- **Onde roda:** só na VM (constituição I). Os atalhos vão na config do Hyprland da VM, com ALT no lugar
  de SUPER, como na 003. A VM não tem outro servidor de notificações; o laboratório instala o `libnotify`
  (pro `notify-send`) se faltar.
- **Brilho na VM:** a VM não tem luz de fundo; o OSD de brilho é testado por comando de controle. O
  teste com luz de fundo de verdade fica pra homologação na máquina do dono (U7).
- **Quem muda o volume:** as teclas de volume continuam na config do compositor; o OSD só observa as
  mudanças (FR-028), não muda nada.
- **Sem sons:** as transmissões não tocam som nesta fase (nada de sons do jogo, e o YoRHa-OS ainda não
  tem sons próprios).
- **Histórico no disco:** de fábrica, o log vive só na sessão, por privacidade (mensagens de chat e
  e-mail); `Saved` é escolha do usuário (FR-019).
- **Nome de quem fala:** o nome do app, como ele mesmo se apresenta; o YoRHa-OS fala com a voz do sistema
  (`Relay 01` de fábrica). O formato "nome + número" lembra o do jogo sem copiar o texto dele.
- **Medidas e cores:** a faixa (tinta ≈84%, retícula, arcos) e os tempos são estimativas, em tokens,
  calibráveis na VM. O material vem da faixa de tutorial medida no §6; nenhuma imagem do jogo entra no
  repositório.
- **Fora do escopo:**
  - ações com ícone, sons e notificações com vídeo;
  - regras por app (silenciar um app, mudar urgência);
  - OSD de luz do teclado, layout do teclado e Caps Lock (o componente serve pra eles depois);
  - pôr a aba de log no menu de pausa: é trabalho da 007 (a 008 entrega a tela pronta pra isso, FR-044);
  - as configurações de outras categorias da 003 passarem a valer de verdade (só Notifications vale aqui);
  - tradução (U5b).
- **Dependências:** a moldura de popup, `CursorList`, `OptionRow`, `DescriptionCard`, `KeyHints`,
  `Meter` (inverted) e o movimento reduzido da 003; o layout de lista + prévia + opções da 004; a barra
  transparente com o tom do fundo (emenda da 004, já na base), onde entra o contador; o catálogo de
  configurações da 003, que ganha a categoria Notifications; a opção "Bar contrast" da 004, em
  andamento em paralelo, que também é uma opção que vale de verdade (as duas usam o mesmo jeito de
  ligar uma opção do catálogo a um valor real); a moldura do menu de pausa da 007, pra aba de log.
- **Desempenho:** implementar antes de otimizar (constituição VII). A retícula e os arcos são desenho
  estático da faixa, sem desfoque; a digitação é o único movimento contínuo. O custo de uma enxurrada é
  medido aqui (SC-005); a meta vem no U6.
- **Atalhos:** `SUPER + N` e `SUPER + CTRL + N` (ALT na VM) são proposta; o dono adiou as decisões de
  atalho. Na VM eles entram como provisórios, pra os testes; trocar é só mudar a config.
- **Perguntas em aberto:** as cinco da versão anterior foram respondidas pelo dono em 2026-10-27
  (ver "Clarifications").
