# Feature Specification: Primeira release pública

**Feature Branch**: `015-primeira-release` (sai da `main` com a 014 mesclada)

**Created**: 2026-11-01

**Status**: Rascunho; pergunta 1 respondida em 02.11 (o nome), faltam 2 (uma de cada vez)

**Input**: Em 01.11, depois de fechar a 014, o dono adiou as funcionalidades novas (o clima no HUD
entre elas) e marcou o próximo marco: "primeiro terminar o instalador e updater depois features
quando tiver finalizado esse marco ai vamo gerar a primeira release e publicar". E depois: "sim".

O ponto de partida é a v0 da 014, que funciona na VM, mas só com o canal local:
- o `install.sh` e o `yorha update` leem o repositório local, servido pelo `lab/014/canal`;
- a versão é `0.<commits>` e depende da branch: na `main` dá 0.73, na branch da 014 dava 0.98;
- o aviso de versão nova aparece uma vez por versão e some (decisão 1 da página de revisão da 014);
- a constituição (Restrições, Marcas) diz que o nome público vai ser próprio, e o PLAN deixa em
  aberto o nome definitivo e a assinatura das versões.

## Clarifications

### Session 2026-11-02

- Q: Qual é o nome público? → A: **YoRHa-Shell**, com o comando `yorha`. O dono: "pois a gente
  migra pra YoRHa-Shell não? melhor aí os comandos continuam yorha no terminal". Ele quer um nome
  do jogo ("queria um nome mais in game"), e o projeto não vai ser vendido (no máximo um Ko-fi pra
  doações). Os nomes próprios conferidos (Bunker, Kikai, Orbital e outros) ficaram de lado.
  - O risco é de marca, não de conteúdo: o pacote não traz nada do jogo (sons sintetizados pela
    receita da 013, tokens CC BY do tyleo, fonte OFL, cursores com base MIT). A Square Enix tem
    "4 YoRHa" registrado nos EUA (classes 9, 16 e 41); "YoRHa" sozinho não apareceu numa busca
    rápida.
  - "Shell" descreve melhor o produto que "OS": é uma UI que vive nas pastas dela, não um sistema
    operacional.
  - O dono aceita o risco com três proteções: a constituição muda (FR-016), o update sabe trocar o
    nome sozinho se um dia for preciso (FR-017) e o README diz que é um projeto de fã, sem ligação
    com a Square Enix (FR-013).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Instalar pelo endereço público (Priority: P1) 🎯 MVP

Uma pessoa com um Arch e o Hyprland funcionando lê o README do repositório público e roda o comando
de instalação que está lá, sem configurar nada antes. O instalador baixa a release estável mais
nova, confere a integridade dela e segue como na 014: dependências com um "sim", as pastas do
produto e a linha do `hyprland.lua`.

**Why this priority**: É o que transforma o projeto em algo que outra pessoa consegue usar. Sem
isso, publicar não serve pra nada.

**Independent Test**: Numa VM limpa da camada `hypr-iso`, com internet, rodar o comando copiado do
README, aceitar as dependências, incluir a linha e entrar de novo: a barra aparece, os atalhos
funcionam, e `status` mostra a versão publicada e o canal público.

**Acceptance Scenarios**:

1. **Given** um Arch com o Hyprland e sem o produto, **When** a pessoa roda o comando do README,
   **Then** ele instala a release estável mais nova publicada, sem pedir nenhuma variável de
   ambiente.
2. **Given** a release baixada, **When** o arquivo não bate com o checksum publicado, **Then** nada
   é instalado e a mensagem diz o que houve.
3. **Given** a instalação concluída, **When** a pessoa pede o `status`, **Then** ele mostra a versão
   (ex.: `0.1.0`) e o canal público.

---

### User Story 2 - Uma versão nova publicada chega pelo update (Priority: P1)

Com uma release instalada, sai uma release nova. A máquina descobre sozinha, avisa, e a pessoa
atualiza pelo "Update now" ou pelo terminal. Se der problema, o rollback volta a versão anterior.

**Why this priority**: É o motivo da 014 e o que o dono quis testar desde o começo: as correções
futuras chegando em quem já instalou.

**Independent Test**: Duas VMs instaladas pela release estável, uma delas no canal de teste.
Publica-se uma versão de teste: a VM do canal de teste é avisada, atualiza pelo "Update now" e volta
com o rollback; a VM do canal estável não é avisada.

**Acceptance Scenarios**:

1. **Given** a versão 0.1.0 instalada e uma 0.1.1 publicada, **When** o shell confere, **Then** a
   transmissão avisa da 0.1.1 e o "Update now" atualiza.
2. **Given** uma versão de teste (pré-release) publicada, **When** uma máquina no canal estável
   confere, **Then** ela não é oferecida.
3. **Given** a versão mais nova publicada é menor que a instalada (uma release retirada, por
   exemplo), **When** o shell confere, **Then** nada é oferecido: o update nunca volta versão
   sozinho.
4. **Given** o canal público fora do ar, **When** o shell confere, **Then** o HUD não mostra erro, e
   SYSTEM › Updates diz que não conseguiu conferir.

---

### User Story 3 - Montar e publicar uma release com um comando (Priority: P1)

O dono decide soltar uma versão: dá o número, e um comando monta a release a partir da `main`
(o pacote, o checksum, o script de instalação e as notas). O mesmo pacote é testado no lab antes de
sair. Publicar é um passo separado, que só acontece com o OK do dono.

**Why this priority**: Sem um jeito repetível de montar a release, cada versão vira trabalho manual e
o teste no lab pode não bater com o que foi publicado.

**Independent Test**: Montar a 0.1.0 a partir de uma `main` limpa, servir o pacote pelo canal do lab
e instalar numa VM; conferir que o checksum do pacote publicado é igual ao testado.

**Acceptance Scenarios**:

1. **Given** a `main` limpa e o número 0.1.0, **When** o comando monta a release, **Then** saem o
   pacote, o checksum, o script de instalação e as notas, e nada é publicado ainda.
2. **Given** mudanças não commitadas, um número já usado ou menor que o último, **When** o comando
   roda, **Then** ele recusa e diz por quê.
3. **Given** a release montada e testada, **When** o dono dá o OK, **Then** ela é publicada no canal
   público com os mesmos arquivos testados.

---

### User Story 4 - O nome público: YoRHa-Shell (Priority: P1)

Antes de publicar, o produto troca o nome provisório YoRHa-OS por **YoRHa-Shell**, em tudo o que a
pessoa vê: as pastas (`~/.local/share/yorha-shell` e as irmãs em `state` e `config`), os arquivos
do sistema (o arquivo que o `hyprland.lua` inclui, os temas do Plymouth e do SDDM, os serviços), os
textos da UI, o README e o repositório. O comando continua `yorha`, e as variáveis `YORHA_*` também.

**Why this priority**: Depois de publicado, trocar o nome obriga a migrar as pastas de todo mundo
que instalou. Antes, a troca é editar arquivos: o nome está em `lib/yorha/name.sh` e as instalações
só existem nas VMs do lab.

**Independent Test**: Numa VM, instalar pelo pacote montado e conferir que nenhum texto visível,
pasta ou comando usa o nome provisório.

**Acceptance Scenarios**:

1. **Given** o nome decidido, **When** a release é montada, **Then** o comando, as pastas, as
   variáveis de ambiente e os textos da UI usam o nome novo.
2. **Given** a release instalada, **When** se procura o nome provisório nas pastas do produto e nos
   textos da UI, **Then** ele não aparece (fora dos créditos e do histórico).

---

### User Story 5 - O aviso que fica (Priority: P2)

Quem perde a transmissão de versão nova ainda vê, de algum jeito, que há uma atualização esperando,
até atualizar.

**Why this priority**: Na sessão da 014, o próprio dono não viu o aviso da primeira vez. Sem um sinal
que fique, a pessoa só descobre a versão nova abrindo o LOG ou SYSTEM › Updates.

**Independent Test**: Com uma versão nova disponível, deixar a transmissão sumir sem clicar: o sinal
continua visível; depois do update, ele some.

**Acceptance Scenarios**:

1. **Given** uma versão nova e a transmissão já fechada, **When** a pessoa olha a tela, **Then** o
   sinal está lá [NEEDS CLARIFICATION: onde e como o sinal aparece: na barra, como marca NEW no
   menu, ou outra forma?].
2. **Given** o update feito, **When** o shell volta, **Then** o sinal some.

---

### User Story 6 - O repositório público em ordem (Priority: P3)

Quem chega no repositório encontra a `main` atual, sem branches velhas, com o README explicando o
que é o projeto, o estado dele (antes da 1.0, testado em VM), como instalar, atualizar e desinstalar,
e a verificação automática (lint) passando.

**Why this priority**: É a primeira impressão de quem vai instalar. Não muda o produto, por isso P3.

**Independent Test**: Abrir o repositório público e conferir a `main`, as branches, o README e o
resultado da verificação automática.

**Acceptance Scenarios**:

1. **Given** a release pronta, **When** o dono dá o OK pra publicar, **Then** a `main` é enviada e as
   15 branches velhas do GitHub são apagadas, cada passo com o OK dele.
2. **Given** a `main` publicada, **When** a verificação automática roda, **Then** ela passa.

### Edge Cases

- **Canal público fora do ar ou com limite de acessos:** instalar falha com uma mensagem clara e sem
  mudar nada; a conferência do shell falha em silêncio no HUD e aparece em SYSTEM › Updates.
- **Release com um arquivo faltando** (envio pela metade): o update recusa e mantém a versão atual.
- **Máquina do lab instalada pelo canal local** (versões `0.<commits>`): no canal público, ela é
  reinstalada do zero; não há migração da numeração velha (só existiu em VMs).
- **Pessoa que fixou um canal** (o local ou o de teste) pela variável de ambiente: ela continua
  valendo por cima do canal público.
- **Arquivo do jogo ou do lab dentro do pacote:** a montagem recusa (fontes, sons e vídeos do jogo;
  qualquer coisa do repositório privado).
- **Nome novo e uma instalação com o nome provisório** (só VMs do lab): fica fora; a VM é refeita.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O README MUST trazer um comando de instalação que funciona sem nenhuma variável de
  ambiente e instala a release estável mais nova.
- **FR-002**: O canal público MUST ser as releases do repositório público no GitHub. A variável de
  ambiente do canal (renomeada com o produto) MUST continuar valendo por cima dele, pro canal do lab
  e pro canal de teste.
- **FR-003**: Toda release MUST ter um número escolhido ao montar, no formato `MAJOR.MINOR.PATCH`
  (a primeira é `0.1.0`). Versões MUST ser comparadas pelo número, nunca pela contagem de commits, e
  o update MUST NOT oferecer uma versão menor que a instalada.
- **FR-004**: Uma release MUST conter o pacote do produto, o checksum dele, o script de instalação
  daquela versão e as notas do que mudou.
- **FR-005**: Um comando MUST montar a release a partir da `main`, sem publicar. Ele MUST recusar se
  houver mudança não commitada, se o número já existir ou for menor que o último, ou se o pacote
  tiver arquivo proibido (do jogo ou do lab).
- **FR-006**: O canal do lab MUST conseguir servir uma release montada, pra que o teste use
  exatamente os arquivos que vão ser publicados.
- **FR-007**: Publicar MUST ser um passo separado, que só roda com o OK do dono, e MUST enviar os
  mesmos arquivos testados.
- **FR-008**: Pré-releases (versões de teste) MUST ser ignoradas pelo canal estável e oferecidas só a
  quem escolheu o canal de teste.
- **FR-009**: A integridade MUST ser conferida sempre pelo checksum; [NEEDS CLARIFICATION: a
  primeira release sai também com assinatura, ou a assinatura fica pra S6, como diz o PLAN?].
- **FR-010**: O nome público YoRHa-Shell MUST ser aplicado antes de publicar: pastas, arquivos do
  sistema, textos da UI, README e repositório. O comando `yorha` e as variáveis `YORHA_*` ficam. O
  nome provisório só fica nas specs antigas, no histórico e nos créditos. Renomear o repositório no
  GitHub MUST ter o OK do dono (o GitHub redireciona o endereço antigo).
- **FR-011**: Com uma versão nova disponível, o shell MUST manter um sinal visível até a pessoa
  atualizar (forma e lugar: ver a US5). O sinal MUST poder ser desligado em SYSTEM › Updates.
- **FR-012**: A conferência do shell MUST continuar como na 014 (30 s depois de subir e a cada
  hora) e MUST caber no limite de acessos anônimos do canal público.
- **FR-013**: O README MUST dizer o estado do projeto (antes da 1.0, testado em VM), os requisitos
  (Arch, Hyprland 0.56+ com config em Lua), e como instalar, atualizar, voltar e desinstalar. Ele
  MUST dizer também que é um projeto de fã, gratuito, sem ligação com a Square Enix, e que NieR e
  YoRHa são marcas dela.
- **FR-014**: Antes de publicar, a `main` MUST ser enviada ao GitHub, as branches velhas apagadas e
  a verificação automática (lint) passando. Cada push e cada exclusão MUST ter o OK do dono.
- **FR-015**: Nada do jogo (fontes, sons, logos, vídeos) e nada do repositório privado MUST entrar no
  pacote da release.
- **FR-016**: A constituição (Restrições, Marcas) MUST passar a registrar a decisão do nome: o nome
  público usa YoRHa (YoRHa-Shell) por escolha do dono, o projeto é gratuito e de fã, e continua
  valendo que nada do jogo entra no repositório. A emenda segue o processo de emendas da própria
  constituição.
- **FR-017**: O update MUST saber trocar o nome do produto numa versão nova: mover as pastas, trocar
  o comando e a linha do `hyprland.lua` (avisando a pessoa), e manter o rollback funcionando. Assim,
  se um dia for preciso trocar o nome, isso sai como um update comum. Na 015 a troca é testada no
  lab com um nome de mentira, de ida e volta.

### Key Entities

- **Release**: um número de versão, o pacote, o checksum, o script de instalação e as notas;
  estável ou de teste.
- **Canal**: de onde a máquina tira as releases. O público (GitHub), o de teste (pré-releases) e o
  do lab (local).
- **Sinal de versão nova**: o que fica visível enquanto há uma release mais nova que a instalada.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Numa VM limpa, a instalação pelo comando do README leva um comando e uma linha no
  `hyprland.lua`, e o shell sobe no próximo login.
- **SC-002**: Com a 0.1.0 publicada e uma versão de teste depois dela, a VM do canal de teste vai pra
  versão nova pelo "Update now" e volta com o rollback; a VM do canal estável não é avisada.
- **SC-003**: O pacote publicado tem o mesmo checksum do pacote testado no lab, nas duas releases.
- **SC-004**: Montar uma release a partir de uma `main` limpa leva um comando, e as três recusas
  (mudança não commitada, número repetido ou menor, arquivo proibido) acontecem no teste.
- **SC-005**: Nenhum texto visível, pasta ou comando da release usa o nome provisório.
- **SC-006**: Com a transmissão fechada sem clique, o sinal de versão nova continua visível até o
  update, e some depois dele.
- **SC-007**: Os roteiros 003, 004, 007, 008, 013 e 014 (adaptado ao canal público) passam, e a
  verificação automática passa na `main` publicada.
- **SC-008**: O dono aprova a página da release antes de ela ser publicada.

## Assumptions

- **Público:** quem instala usa Arch (ou derivado) com Hyprland 0.56+ e config em Lua. Testes em
  EndeavourOS e CachyOS ficam pra S6.
- **Estado:** a 0.1.0 é uma prévia, antes da 1.0; o README avisa que pode quebrar entre versões.
- **Canal de teste:** as versões de teste são pré-releases no mesmo repositório; o canal estável
  ignora pré-releases.
- **"Update now" apagado** quando não há versão nova (decisão 2 da página da 014) continua como
  está, a menos que o dono diga outra coisa.
- **Sem telemetria:** a conferência de versão só lê o canal público.
- **Fora desta spec:** o clima no HUD e as outras funcionalidades da S1 (depois do marco), o Niri
  (S5) e o cursor (FR-017 da 014).
- **Máquina do dono:** como sempre, nada roda nela; o teste é em VM, com acesso à internet pra ler
  o canal público.
