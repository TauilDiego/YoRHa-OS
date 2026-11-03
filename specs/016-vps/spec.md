# Feature Specification: A VPS do projeto

**Feature Branch**: `016-vps` (sai da `main`; depende da 015 mesclada)

**Created**: 2026-11-02

**Status**: Rascunho, pra revisão do dono

**Input**: A 015 tirou da primeira release tudo o que dependia da VPS do dono e mandou pra uma spec
própria. Do PLAN (Decisões tomadas, 02.11): "a VPS na spec 016: o site, o endereço curto de
instalação, uma cópia do checksum, o espelho das releases e o receptor da telemetria. A 015 já deixa
o instalador e o update prontos pra uma segunda origem."

O ponto de partida é a 015:
- o canal público são as releases do GitHub, lidas pelos endereços de `github.com`, sem a API
  (research R1 da 015);
- toda origem responde aos mesmos caminhos (`latest`, `releases.atom`, `manifest`, o pacote e o
  `.sha256`; `contracts/canal-publico.md` da 015);
- as origens ficam numa lista, a principal primeiro, e o espelho entra "só acrescentando uma linha
  no `name.sh`" (research R3 da 015, FR-018);
- a 0.1.0 sai sem assinatura, só com o checksum.

A VPS é do dono e ainda não tem nada. O projeto ainda não tem domínio.

## Clarifications

### Decidido antes desta spec (02.11, na 015)

- Q: O que vai na VPS? → A: O site de apresentação, o endereço curto de instalação, uma cópia do
  checksum das releases, o espelho das releases e o receptor da telemetria. Foi a proposta do
  assistente na 015; o dono seguiu sem objetar.
- Q: O espelho é o quê? → A: A segunda origem do FR-018 da 015, com os mesmos caminhos do GitHub. O
  GitHub continua sendo a principal.
- Q: Telemetria? → A: Sim. O dono, depois de ver a do Serpantinum: "pior que na real adicionar uma
  telemetria seria bom. pelo mesmo motivo de ele ter feito no dele. só pra medir dados dos sistemas
  que estão instalando... pode fazer".
- Q: Ligada ou desligada por padrão? → A: **Ligada (opt-out), como no Serpantinum** ("faz igual o
  serpantinum"). O instalador mostra que ela está ligada e o que vai, e dá pra desligar ali mesmo,
  antes de qualquer envio. **Desligada, não manda nada**, nem o ID nem a versão (o Serpantinum ainda
  manda os dois).
- Q: Quais campos? → A: **Todos os do Serpantinum, mais os nossos.** Os dele: o ID, a operação, as
  versões, o resultado, os pacotes que falharam, o sistema, o kernel, a arquitetura, a CPU, a GPU, a
  RAM, o compositor, o desktop e a sessão. Os nossos: as versões do compositor e do Quickshell e os
  monitores (quantos, a resolução e a escala). O dono: "preciso saber tudo igual ele sabe pois depois
  vamos adicionar suporte pro niri e mango". O compositor e a versão dele saem de um jeito que sirva
  pros três.
- Q: Quem manda? → A: Só o instalador e o `yorha`. O shell nunca manda nada.
- Q: Onde fica o receptor? → A: **Na VPS do dono**, com HTTPS, sem guardar o IP e sem log de acesso.
  O dono: "eu n tenho nada pra salvar isso ainda lá na VPS né. tu consegue debugar qualquer coisa ai
  se precisar". Cada mudança na VPS tem o OK dele.
- Q: E os testes? → A: Os testes do lab mandam pra um receptor local, nunca pra VPS.
- **Adiada da 015 pra cá (02.11):** o dono: "deixa sem telemetria no momento depois a gente adiciona
  isso". As decisões acima valem aqui.

### Abertas nesta spec

As três perguntas estão marcadas com [NEEDS CLARIFICATION] no texto (FR-001, FR-006 e FR-013).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Instalar por um endereço curto (Priority: P1) 🎯 MVP

Uma pessoa vê o projeto num post e quer instalar. Em vez do endereço longo das releases do GitHub,
ela digita um endereço curto, no domínio do projeto. Ele entrega o mesmo instalador da release
estável mais nova, e a instalação segue como na 015.

**Why this priority**: É o que a pessoa copia de um post, de um vídeo ou do site. O endereço longo do
GitHub funciona, mas é difícil de lembrar e de digitar.

**Independent Test**: No lab, com uma réplica da VPS e um domínio de teste, rodar o comando curto
numa VM limpa: a versão instalada é a estável mais nova, e o instalador é o mesmo arquivo da release
(mesmo checksum). Depois, o mesmo na VPS de verdade, com o OK do dono.

**Acceptance Scenarios**:

1. **Given** um Arch com o Hyprland e sem o produto, **When** a pessoa roda o comando curto,
   **Then** ele instala a release estável mais nova, como o comando longo da 015.
2. **Given** uma release nova publicada, **When** a pessoa roda o comando curto, **Then** ela recebe
   o instalador da release nova, sem ninguém mexer na VPS à mão.
3. **Given** o endereço curto fora do ar, **When** a pessoa roda o comando, **Then** a falha é clara
   e nada muda na máquina; o README e o site mostram o comando longo como alternativa.

---

### User Story 2 - O espelho e a segunda conferência do checksum (Priority: P1)

Com o GitHub fora do ar, a instalação e o update terminam pelo espelho da VPS, que tem as mesmas
releases nos mesmos caminhos. E, com o GitHub no ar, o produto confere o checksum do pacote contra
uma cópia guardada na VPS: se alguém trocar um arquivo de uma release num dos dois lugares, a
diferença aparece e nada é instalado.

**Why this priority**: É a proteção que a 015 adiou junto com a assinatura. Uma origem só é um ponto
único de falha e de ataque; duas origens independentes que precisam concordar cobrem os dois casos
até a assinatura chegar.

**Independent Test**: No lab, com a réplica da VPS: tirar o GitHub de teste do ar e instalar e
atualizar pelo espelho; depois, trocar o `.sha256` de uma versão só num dos lados e conferir que a
instalação e o update recusam, dizendo qual origem diverge.

**Acceptance Scenarios**:

1. **Given** uma release publicada, **When** ela sai no GitHub, **Then** o espelho tem os mesmos
   arquivos, com os mesmos caminhos e o mesmo checksum, e a cópia do checksum tem a linha dela.
2. **Given** o GitHub fora do ar, **When** a pessoa instala ou atualiza, **Then** a operação termina
   pelo espelho, e a mensagem diz que usou o espelho.
3. **Given** as duas origens no ar, **When** o checksum de uma versão no GitHub não bate com a cópia
   da VPS, **Then** nada é instalado, e a mensagem diz que as duas origens discordam (sai 4, como um
   checksum que não bate na 015).
4. **Given** a cópia do checksum fora do ar e o GitHub no ar, **When** a pessoa instala ou atualiza,
   **Then** o comportamento segue o FR-006.
5. **Given** uma máquina instalada pela 0.1.0, que só conhece o GitHub, **When** ela atualiza pra
   uma versão que já traz o espelho, **Then** a lista de origens dela ganha o espelho, sem ela fazer
   nada.

---

### User Story 3 - A telemetria, ligada por padrão e desligável (Priority: P2)

No fim da instalação, o instalador diz que manda um relatório anônimo e mostra os campos. A pessoa
pode desligar ali mesmo, antes de qualquer envio, ou depois, por um comando. Ligada, cada instalação
e cada update mandam um relatório pro receptor na VPS. Desligada, nada sai da máquina.

**Why this priority**: O dono quer saber em que sistemas o produto é instalado, pra decidir o
suporte ao Niri e ao MangoWC. É útil, mas o produto funciona sem ela, por isso P2.

**Independent Test**: No lab, com o receptor local: instalar com a telemetria ligada e conferir que
chega um relatório com todos os campos e sem nenhum dado pessoal; instalar com ela desligada (na
pergunta, pela variável ou pelo comando) e conferir, pelo log do receptor e pela rede da VM, que nada
foi mandado.

**Acceptance Scenarios**:

1. **Given** uma instalação nova, **When** o instalador chega no fim, **Then** ele diz que a
   telemetria está ligada, lista os campos e pergunta se a pessoa quer desligar, antes de mandar
   qualquer coisa.
2. **Given** a telemetria ligada, **When** uma instalação, um update ou um rollback terminam (com
   sucesso ou com erro), **Then** um relatório com os campos do FR-011 chega ao receptor.
3. **Given** a telemetria desligada, **When** qualquer operação roda, **Then** nenhum pedido sai pro
   receptor, nem com o ID nem com a versão, e não existe ID guardado na máquina.
4. **Given** a pessoa quer mudar depois, **When** ela roda o comando de ligar, desligar ou ver o
   estado, **Then** a escolha vale desde o próximo envio, e o estado mostra o que seria mandado.
5. **Given** o receptor fora do ar ou lento, **When** a operação termina, **Then** ela termina
   igual, sem esperar mais que alguns segundos e sem mensagem de erro pra pessoa.
6. **Given** um relatório recebido, **When** o dono olha os dados guardados, **Then** não há IP, nome
   de usuário, nome da máquina, caminhos nem lista de programas.

---

### User Story 4 - O site do projeto (Priority: P2)

Quem chega pelo domínio vê um site com a cara do projeto: o que é, screenshots, o comando de
instalação, os requisitos, o aviso de projeto de fã e os links pro repositório e pras releases. O
site também explica a telemetria: o que vai, como desligar e o que fica guardado.

**Why this priority**: É a vitrine e o lugar do comando curto, mas o produto se instala sem ele, pelo
README.

**Independent Test**: No lab, servir o site na réplica da VPS e abrir no navegador do lab: as
páginas abrem, o comando de instalação é o curto, e os links funcionam. Na VPS de verdade, com o OK
do dono, abrir pelo domínio com HTTPS.

**Acceptance Scenarios**:

1. **Given** o site publicado, **When** alguém abre o domínio, **Then** a página mostra o que é o
   projeto, screenshots, o comando curto, os requisitos e o aviso de projeto de fã.
2. **Given** uma release nova, **When** o site é aberto, **Then** ele mostra a versão estável mais
   nova sem ninguém editar o site à mão.
3. **Given** a página de privacidade, **When** alguém a lê, **Then** ela lista os campos da
   telemetria, diz como desligar e o que é guardado, e bate com o que o instalador mostra.

---

### User Story 5 - Publicar uma release também na VPS (Priority: P1)

Quando o dono publica uma release (o passo separado da 015, com o OK dele), o mesmo passo leva os
arquivos pro espelho e grava a linha da cópia do checksum, a partir dos arquivos testados no lab.
Nada na VPS é atualizado à mão.

**Why this priority**: Sem isso, o espelho e a cópia ficam pra trás na primeira release nova, e a
conferência cruzada começa a recusar instalações boas.

**Independent Test**: No lab, publicar uma versão de teste na réplica da VPS: o espelho tem os
arquivos, a cópia tem a linha, e os checksums são os mesmos do pacote testado.

**Acceptance Scenarios**:

1. **Given** uma release montada e testada, **When** o dono dá o OK pra publicar, **Then** ela vai
   pro GitHub e pra VPS com os mesmos arquivos, e o passo confere os dois lados no fim.
2. **Given** a VPS fora do ar na hora de publicar, **When** o passo roda, **Then** ele para antes do
   GitHub e diz por quê, pra uma origem nunca ficar com uma release que a outra não tem.
3. **Given** uma pré-release, **When** ela é publicada, **Then** o espelho a trata como o GitHub: o
   canal estável do espelho não a oferece.

### Edge Cases

- **GitHub e VPS fora do ar ao mesmo tempo:** instalar falha com uma mensagem clara e sem mudar nada;
  a conferência do shell falha em silêncio no HUD, como na 015.
- **Espelho atrasado** (a release saiu no GitHub e não no espelho): a conferência de versão que cair
  no espelho vê uma versão mais velha e não oferece nada errado; o update nunca volta versão.
- **Release retirada:** ela sai dos dois lados e da cópia do checksum pelo mesmo passo.
- **Origem fixada pela pessoa** (`YORHA_ORIGIN`): vale por cima da lista, como na 015; a conferência
  cruzada só roda quando a lista padrão está em uso.
- **A mesma operação duas vezes** (a pessoa roda o update de novo depois de um erro): são dois
  relatórios, e o dono vê duas linhas; não há deduplicação na v0.
- **Relatório malformado ou grande demais:** o receptor recusa sem guardar.
- **Pessoa que desinstala:** o `yorha uninstall` apaga o ID e a escolha da telemetria junto com o
  resto.
- **Certificado do HTTPS vencido:** o produto não aceita a VPS sem HTTPS válido; ela conta como fora
  do ar.

## Requirements *(mandatory)*

### Functional Requirements

**Domínio e endereço curto**

- **FR-001**: O projeto MUST ter um domínio próprio, com HTTPS válido, apontando pra VPS do dono.
  [NEEDS CLARIFICATION: qual domínio? O dono ainda não tem nenhum. Ele escolhe e compra, ou quer
  uma lista de sugestões livres pra escolher? O nome entra no README, no site, no `name.sh` e no
  comando curto.]
- **FR-002**: Um endereço curto no domínio MUST entregar o `install.sh` da release estável mais nova,
  byte a byte igual ao da release no GitHub. O comando curto MUST ser uma linha, no mesmo formato do
  comando da 015 (`bash <(curl -fsSL <endereço>)`).
- **FR-003**: O README e o site MUST mostrar o comando curto primeiro e o longo do GitHub como
  alternativa.

**Espelho e cópia do checksum**

- **FR-004**: A VPS MUST servir um espelho das releases com os mesmos caminhos de uma origem da 015
  (`latest`, `releases.atom`, `manifest`, o pacote e o `.sha256` de cada versão), estável e
  pré-release com a mesma regra do GitHub.
- **FR-005**: A VPS MUST guardar uma cópia do checksum de cada release publicada, gravada pelo passo
  de publicar a partir do pacote testado no lab, nunca copiada do GitHub.
- **FR-006**: Antes de instalar um pacote, o instalador e o update MUST conferir o checksum dele
  contra as duas origens. Se elas discordarem, MUST recusar e dizer qual diverge. Se só uma
  responder, [NEEDS CLARIFICATION: segue com a que respondeu, avisando que a segunda conferência não
  foi feita, ou recusa até as duas responderem? Seguir não deixa ninguém sem instalar quando a VPS
  cai; recusar protege mais, mas a VPS vira um ponto de falha.]
- **FR-007**: A lista padrão de origens MUST passar a ter o GitHub primeiro e o espelho depois, e uma
  máquina instalada antes MUST ganhar o espelho pelo update comum, sem passo manual.
- **FR-008**: O passo de publicar da 015 MUST levar a release também pra VPS (espelho e cópia), com
  o mesmo OK do dono, e MUST conferir os dois lados no fim. Com a VPS fora do ar, ele MUST parar
  antes de publicar no GitHub.
- **FR-009**: Retirar uma release MUST tirá-la dos dois lados e da cópia num passo só.

**Telemetria**

- **FR-010**: A telemetria MUST vir ligada por padrão. O instalador MUST mostrar, antes de qualquer
  envio, que ela está ligada, a lista dos campos e como desligar, e MUST deixar desligar ali mesmo.
  Uma variável de ambiente MUST desligá-la sem pergunta (pra instalações automáticas), e um comando
  do `yorha` MUST ligar, desligar e mostrar o estado com o relatório que seria mandado.
- **FR-011**: O relatório MUST ter os campos do Serpantinum e os nossos:
  - um ID aleatório da instalação;
  - a operação (instalação, update, rollback) e o resultado (sucesso ou o erro);
  - a versão de antes e a de depois;
  - os pacotes que falharam;
  - o sistema (a distribuição), o kernel e a arquitetura;
  - a CPU, a GPU e a RAM (o modelo e o total, sem números de série);
  - o compositor e a versão dele, o desktop e a sessão;
  - a versão do Quickshell;
  - os monitores: quantos, a resolução e a escala de cada um.

  O compositor e a versão MUST sair de um jeito que sirva pro Hyprland, pro Niri e pro MangoWC.
- **FR-012**: O relatório MUST NOT ter nome de usuário, nome da máquina, caminhos, lista de
  programas, endereço de rede ou qualquer outro identificador além do ID aleatório.
- **FR-013**: Desligada, a telemetria MUST NOT mandar nada, e o ID MUST NOT existir na máquina.
  Ligar de novo cria um ID novo. [NEEDS CLARIFICATION: os dados ficam só pro dono (um resumo que ele
  vê no lab), ou o site mostra estatísticas públicas (quantas instalações, por distribuição e por
  compositor)? Muda o que o site tem e o que a página de privacidade promete.]
- **FR-014**: Só o instalador e o `yorha` MUST mandar relatórios. O shell MUST NOT mandar nada; a
  conferência de versão dele continua sem dado nenhum além do pedido (FR-012 da 015).
- **FR-015**: Um receptor fora do ar ou lento MUST NOT atrasar a operação mais que 5 segundos nem
  mostrar erro; o relatório é perdido, sem nova tentativa.
- **FR-016**: O receptor MUST rodar na VPS, com HTTPS, MUST NOT guardar o IP de quem manda e MUST
  NOT manter log de acesso. Ele MUST recusar relatórios malformados ou grandes demais.
- **FR-017**: Os testes do lab MUST mandar pra um receptor local; nenhum teste manda pra VPS.

**Site**

- **FR-018**: O site MUST ser estático e MUST ter: o que é o projeto, screenshots tirados no lab, o
  comando curto, os requisitos, a versão estável mais nova, o aviso de projeto de fã (como no
  README) e os links pro repositório e pras releases.
- **FR-019**: O site MUST ter uma página de privacidade que lista os campos da telemetria, diz como
  desligar e o que fica guardado, igual ao que o instalador mostra.
- **FR-020**: O site MUST NOT ter nada do jogo (fontes, sons, logos, vídeos, imagens), nem rastreador
  de terceiros, nem cookies.
- **FR-021**: O código do site MUST ficar no repositório público, e publicar o site MUST ser um passo
  do lab, com o OK do dono.

**A VPS**

- **FR-022**: Toda mudança na VPS (instalar, configurar, publicar) MUST ter o OK do dono, e MUST ser
  ensaiada antes numa réplica no lab.
- **FR-023**: A configuração da VPS MUST ser reproduzível a partir do repositório privado (a VPS pode
  ser refeita do zero), e nenhum segredo (chaves, certificados, senhas) MUST entrar em nenhum
  repositório.
- **FR-024**: Nada desta spec MUST rodar na máquina do dono: os ensaios rodam no lab, e o resto na
  VPS (princípio I).

### Key Entities

- **Origem**: um endereço base que responde aos caminhos da 015. Agora são duas na lista padrão: o
  GitHub (principal) e o espelho na VPS.
- **Cópia do checksum**: uma linha por release publicada (a versão, o arquivo do pacote e o
  checksum), gravada pelo passo de publicar.
- **Relatório de telemetria**: os campos do FR-011, de uma operação de uma máquina, com a data do
  recebimento (sem hora exata, sem IP).
- **Escolha da telemetria**: ligada ou desligada, guardada na pasta de estado do produto, com o ID
  quando ligada.
- **Site**: páginas estáticas geradas a partir do repositório público.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Numa VM limpa, a instalação pelo comando curto leva um comando, e o instalador
  recebido tem o mesmo checksum do `install.sh` da release.
- **SC-002**: No lab, com a origem principal fora do ar, a instalação e o update terminam pelo
  espelho em 10 de 10 tentativas.
- **SC-003**: No lab, com o `.sha256` trocado só num dos lados, a instalação e o update recusam em
  10 de 10 tentativas, e a mensagem diz qual origem diverge.
- **SC-004**: Depois de publicar uma release, os dois lados e a cópia têm os mesmos checksums, e o
  passo de publicar diz isso no fim.
- **SC-005**: Com a telemetria desligada (pelos três caminhos: a pergunta, a variável e o comando),
  o receptor local recebe 0 pedidos e a rede da VM não mostra nenhum pedido pro receptor, numa
  instalação, um update e um rollback.
- **SC-006**: Com a telemetria ligada, cada operação gera exatamente 1 relatório, com todos os
  campos do FR-011 preenchidos numa VM com Hyprland, e nenhum dos dados do FR-012.
- **SC-007**: Com o receptor fora do ar, a operação termina no máximo 5 segundos depois do que
  terminaria sem telemetria.
- **SC-008**: O site abre pelo domínio com HTTPS válido, e o dono aprova a página antes de ela ir
  pra VPS.
- **SC-009**: A VPS pode ser refeita do zero pelo passo do lab, e depois disso SC-001 a SC-004
  passam de novo.

## Assumptions

- **Depende da 015 mesclada:** o canal público, a lista de origens, o passo de publicar e o nome
  YoRHa-Shell vêm dela.
- **A conferência do shell:** a conferência de versão do shell continua lendo as origens em ordem,
  sem conferência cruzada (ela não instala nada); a cruzada é só pra quem baixa um pacote.
- **Tamanho do espelho:** cabe na VPS guardar todas as releases (cada pacote tem poucos MB); se um
  dia não couber, o espelho guarda as últimas e o GitHub fica com o histórico.
- **Retenção da telemetria:** os relatórios ficam guardados por 12 meses; depois disso, só os
  totais por mês.
- **Quando a telemetria manda:** no fim da instalação, do update e do rollback. O `uninstall` não
  manda nada (a pessoa está saindo).
- **Idioma do site:** o mesmo do README (português); uma versão em inglês fica pra U5b (i18n).
- **Tecnologia do site:** fica pro plano (um gerador de site estático, no estilo do Docusaurus, ou
  algo mais simples).
- **Fora desta spec:** a assinatura das releases (S6, antes da 1.0), o Ko-fi, um painel de
  telemetria no navegador e qualquer serviço na VPS além dos desta spec.
- **Máquina do dono:** como sempre, nada roda nela.
