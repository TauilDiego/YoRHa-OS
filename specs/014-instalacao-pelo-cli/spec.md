# Feature Specification: Instalação e encaixe do shell, v0 pelo CLI

**Feature Branch**: `014-instalacao-pelo-cli` (sai da `main` com a constituição 2.0.0)

**Created**: 2026-11-01

**Status**: Aprovada pelo dono em 01.11, junto com o plano (com os ajustes do FR-017 e do SC-007)

**Input**: Em 01.11 o dono decidiu, entre seis jeitos de instalar e atualizar, fazer só o CLI: "gostei
da ideia de fazer o F. só o cli pois depois a gente pode melhorar isso. quero algo funcional por agora
e não tudo completão saca? mas a ideia de aparecer uma notificação termos uma opção nas configurações
do sistema de 'atualize agora' e ele starta o comando de update da CLI seria interessante, que é o que
o serpantinum faz hoje". E depois: "quero tentar fazer o instalador logo. pois quero testar se as
updates seguintes conseguem aplicar as correções futuras que vamos fazer".

A base é o estudo 005, que escolheu o método D (versões lado a lado, `docs/estudo-instalacao.md`
§8–§9). O protótipo está no lab privado (`lab/u2/metodo-d`): `install-d.sh` e o `yorha` com `update`,
`rollback`, `migrate` e `uninstall`. Pela constituição 2.0.0, o produto vive nas pastas dele e só mexe
no sistema com confirmação, backup e desfazer. O nome YoRHa-OS é provisório.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Instalar com um comando (Priority: P1) 🎯 MVP

Num Arch com o Hyprland funcionando, a pessoa roda um comando:
- o instalador confere as dependências do shell e diz quais faltam;
- ele pergunta antes de instalar qualquer uma;
- ele põe a versão mais nova nas pastas do produto, deixa o comando `yorha` no `PATH` e mostra a
  linha pra incluir no `hyprland.lua`.

Com a linha incluída, o próximo login já abre o shell, com os atalhos.

**Why this priority**: Sem isso, nada do resto existe. É também o que leva o YoRHa-OS da VM do lab pra
qualquer máquina.

**Independent Test**: Numa VM limpa da camada `hypr-iso`, sem o `~/nier/ui` do lab:
1. rodar o comando de instalação;
2. aceitar as dependências;
3. incluir a linha no `hyprland.lua`;
4. sair e entrar de novo.

A barra aparece, e os atalhos abrem o menu de pausa, as configurações e o seletor de papel de parede.

**Acceptance Scenarios**:

1. **Given** um Arch com o Hyprland e sem o YoRHa-OS, **When** a pessoa roda o comando de instalação,
   **Then** ele lista as dependências que faltam e só instala depois de um "sim".
2. **Given** a instalação concluída, **When** ela termina, **Then**:
   - a versão está em `~/.local/share/yorha-os/versions/<v>/`;
   - o `current` aponta pra ela;
   - o `yorha` responde no terminal;
   - a mensagem final mostra a linha exata pra incluir no `hyprland.lua`.
3. **Given** a linha incluída, **When** a pessoa entra no Hyprland, **Then** o shell sobe sozinho e os
   atalhos SUPER funcionam.
4. **Given** o YoRHa-OS já instalado, **When** a pessoa roda o comando de instalação de novo, **Then**
   ele diz que já está instalado e aponta pro `yorha update`, sem mudar nada.

---

### User Story 2 - Uma correção nova chega pelo `yorha update` (Priority: P1)

Uma correção commitada no projeto vira uma versão nova. Na máquina que já tem o YoRHa-OS, o
`yorha update`:
- baixa a versão nova, confere e desempacota ao lado da atual;
- guarda uma cópia do estado;
- roda as migrations;
- troca a versão em uso e reinicia o shell.

A correção aparece. Se algo der errado, o `yorha rollback` volta a versão e o estado de antes.

**Why this priority**: É o motivo do dono pra fazer o instalador agora: provar que as próximas
correções chegam numa máquina instalada.

**Independent Test**: Na VM instalada, que segue a `main` pelo servidor do lab:
1. commitar uma correção visível e uma migration de teste;
2. rodar o `yorha update`: o shell volta na v0.2, com a correção e a migration aplicada uma vez só;
3. rodar o `yorha rollback`: a v0.1 volta com o estado de antes.

**Acceptance Scenarios**:

1. **Given** a v0.1 instalada e um commit novo na fonte (a v0.2), **When** a pessoa roda `yorha update --check`,
   **Then** ele responde que a v0.2 está disponível, sem mudar nada.
2. **Given** o mesmo cenário, **When** a pessoa roda `yorha update`, **Then**:
   - a v0.2 entra em uso;
   - as migrations dela rodam uma vez;
   - o shell reinicia na v0.2;
   - a v0.1 continua guardada.
3. **Given** a v0.2 em uso, **When** a pessoa roda `yorha rollback`, **Then** a v0.1 volta, junto com o
   estado como estava antes do update.
4. **Given** um update interrompido no meio (sem rede ou desligando a VM), **When** a máquina volta,
   **Then** a versão que estava em uso continua inteira e funcionando, e um novo `yorha update`
   termina o serviço.
5. **Given** uma versão com o checksum errado, **When** o `yorha update` baixa, **Then** ele recusa e
   não muda nada.

---

### User Story 3 - O shell avisa, e o "Update now" atualiza (Priority: P2)

O shell confere de tempos em tempos se saiu versão nova. Quando sai, chega uma transmissão do Pod:
"Update available". Clicar nela abre SYSTEM › Updates, com a versão em uso, a nova e a opção "Update
now". O "Update now" abre um terminal rodando o `yorha update`, à vista, como o Serpantinum faz. No
fim, o shell reinicia na versão nova.

**Why this priority**: É o jeito do dono de atualizar sem lembrar do comando. Mas o CLI sozinho (US2)
já resolve.

**Independent Test**: Com a v0.1 instalada na VM:
1. commitar uma mudança na fonte (a v0.2);
2. esperar a conferência (ou forçar pelo IPC): chega a transmissão;
3. abrir SYSTEM › Updates › "Update now": o terminal roda o update e o shell volta na v0.2.

**Acceptance Scenarios**:

1. **Given** uma versão nova na fonte, **When** o shell confere, **Then** chega uma transmissão com o
   número da versão, uma vez por versão (a mesma versão não avisa de novo a cada conferência).
2. **Given** a transmissão, **When** a pessoa clica nela, **Then** o menu abre em SYSTEM › Updates.
3. **Given** SYSTEM › Updates, **When** a pessoa escolhe "Update now", **Then** abre o terminal da
   config (`kitty`, por padrão) rodando o `yorha update`.
4. **Given** nenhuma versão nova, **When** a pessoa abre SYSTEM › Updates, **Then** aparece a versão
   em uso e "Up to date", sem o "Update now".
5. **Given** a conferência sem rede, **When** ela falha, **Then** nada aparece, nada quebra, e a
   próxima conferência tenta de novo.

---

### User Story 4 - O encaixe no Hyprland é um arquivo da pessoa incluir (Priority: P2)

O projeto traz um arquivo de Hyprland com os atalhos SUPER, o autostart do shell e as regras de janela
que o shell precisa. O `hyprland.lua` da pessoa continua dela: ela inclui o arquivo com uma linha.
Nada no `~/.config/hypr` é escrito pelo instalador.

**Why this priority**: É o que separa o produto da config pessoal, como manda a constituição 2.0.0.
Hoje os atalhos só existem no lab.

**Independent Test**: Na VM instalada, com a linha incluída, os atalhos SUPER fazem o que o
`lab/guest/hyprland.lua` faz com ALT. Os roteiros do lab rodam com o shell iniciado por esse arquivo.

**Acceptance Scenarios**:

1. **Given** a linha incluída, **When** o Hyprland sobe, **Then** o shell inicia uma vez só.
2. **Given** a linha incluída, **When** a pessoa usa os atalhos SUPER, **Then** eles abrem o menu de
   pausa, as configurações, o seletor de papel de parede e o Não perturbe, e controlam volume e brilho
   com o OSD.
3. **Given** um update, **When** a versão troca, **Then** o arquivo incluído continua valendo, porque
   ele aponta pra versão em uso, não pra uma pasta de versão.

---

### User Story 5 - O núcleo opcional pelo CLI (Priority: P3)

O tema de boot e de login da 011 é instalado, conferido e desfeito pelo `yorha boot-login`, que pede a
senha de administrador e usa o módulo que já faz backup e desfazer.

**Why this priority**: O módulo já existe (011). Aqui ele só ganha uma porta pelo CLI.

**Independent Test**: Numa VM da camada `boot-iso`:
1. `yorha boot-login install` → reboot: o boot e o login são os do YoRHa-OS;
2. `yorha boot-login uninstall` → reboot: tudo volta como era, com os hashes de antes.

**Acceptance Scenarios**:

1. **Given** o YoRHa-OS instalado, **When** a pessoa roda `yorha boot-login install`, **Then** ele
   explica o que vai mudar no sistema e só continua depois de um "sim" e da senha.
2. **Given** o boot e o login instalados, **When** a pessoa roda `yorha boot-login status`, **Then** a
   resposta é a do módulo da 011.

---

### User Story 6 - Desinstalar (Priority: P3)

O `yorha uninstall` tira o YoRHa-OS da máquina: as versões, o comando e o autostart. Ele lembra a
pessoa de tirar a linha do `hyprland.lua` e de desfazer o boot e o login, se estiverem instalados.

**Why this priority**: Faz parte de "mexer só com desfazer", mas pode vir por último.

**Independent Test**: Na VM instalada, `yorha uninstall`. Nenhum arquivo do produto sobra fora da
config e do estado da pessoa, e o Hyprland sobe sem o shell.

**Acceptance Scenarios**:

1. **Given** o YoRHa-OS instalado, **When** a pessoa roda `yorha uninstall`, **Then**:
   - as versões e o comando saem;
   - o `~/.config/yorha-os/` fica;
   - o estado só sai se a pessoa disser que sim.
2. **Given** o boot e o login instalados, **When** a pessoa desinstala, **Then** o `yorha` avisa e
   oferece desfazer os dois antes.

---

### Edge Cases

- **Rodar como root:** o instalador e o `yorha` recusam. O root só entra pelo sudo, nos passos que
  pedem.
- **Sem internet na instalação:** nada é instalado e a mensagem diz por quê.
- **Uma dependência recusada:** o instalador diz o que não vai funcionar sem ela e para. Ele não
  instala um shell que não sobe.
- **Duas versões do shell rodando** (por exemplo, o Serpantinum também no autostart): o `yorha` avisa
  na instalação. A troca entre os dois fica pra U7.
- **Update com o menu aberto:** o shell reinicia do mesmo jeito; nada do estado se perde.
- **Fonte trocada pra uma versão mais velha que a em uso:** o `update` não volta versão. Pra voltar, é o
  `rollback`.
- **Rollback sem versão anterior:** a mensagem diz que não há pra onde voltar.
- **Pasta de versão incompleta** (de um update interrompido): é limpa no próximo update.
- **O terminal da config não existe:** o "Update now" mostra a mensagem com o comando pra rodar à mão.

## Requirements *(mandatory)*

### Functional Requirements

**Instalação**
- **FR-001**: Um comando de instalação, baixado e rodado pela pessoa, MUST instalar a versão mais nova
  nas pastas do produto (`~/.local/share/yorha-os/versions/<v>/`, o link `current` e o `yorha` em
  `~/.local/bin`).
- **FR-002**: O instalador MUST listar as dependências do shell que faltam e só instalá-las depois da
  confirmação da pessoa (com sudo e o gerenciador de pacotes do Arch).
- **FR-003**: O instalador MUST NOT escrever no `~/.config/hypr` nem em nenhum arquivo do sistema. Ele
  MUST mostrar a linha que a pessoa inclui no `hyprland.lua`.
- **FR-004**: A instalação MUST ser idempotente: rodar de novo numa máquina instalada não muda nada e
  aponta pro `yorha update`.

**Versões e update**
- **FR-005**: O canal de versões da v0 MUST ser o próprio repositório local (decisão do dono, 01.11:
  "tu num pode fazer puxar da worktree local não? melhor eu acho"):
  - um servidor do lab lê direto do repo, sem passo de publicar;
  - cada commit vira uma versão, com o número tirado do git (`0.<commits>`) e um checksum;
  - o que não foi commitado não entra;
  - por padrão a VM segue a `main`, e dá pra ela seguir o worktree de uma spec, pra testar uma
    correção antes de mesclar.

  Mais tarde, a mesma fonte aponta pro repo público no GitHub.
- **FR-006**: O `yorha update --check` MUST dizer se há versão nova, sem mudar nada, e ter uma saída
  que o shell consegue ler.
- **FR-007**: O `yorha update` MUST:
  - baixar e conferir o checksum;
  - desempacotar ao lado da versão em uso;
  - guardar uma cópia do estado;
  - trocar a versão em uso de forma atômica;
  - rodar as migrations pendentes;
  - reiniciar o shell.

  Uma falha antes da troca MUST deixar a versão em uso intocada.
- **FR-008**: Uma migration MUST rodar uma vez só por usuário e ficar marcada no estado.
- **FR-009**: O `yorha rollback` MUST voltar a versão anterior e o estado como estava antes do update.
- **FR-010**: O `yorha` MUST guardar as 3 versões mais novas e apagar as mais velhas, nunca a que está
  em uso.
- **FR-011**: Um commit novo na fonte seguida MUST aparecer como versão nova no `yorha update --check`,
  sem nenhum outro passo. Trocar a fonte seguida (a `main` ou um worktree) MUST ser um comando.

**Shell**
- **FR-012**: O shell MUST conferir o `yorha update --check` ao subir e a cada hora, e guardar a
  última conferência no estado.
- **FR-013**: Uma versão nova MUST virar uma transmissão do Pod uma vez por versão; clicar MUST abrir
  SYSTEM › Updates.
- **FR-014**: SYSTEM › Updates MUST mostrar a versão em uso, a disponível (se houver) e a opção "Update
  now", que abre o terminal da config rodando o `yorha update`.
- **FR-015**: O shell MUST continuar funcionando, sem erro no log de QML, quando não foi instalado pelo
  `yorha` (o lab, com `~/nier/ui`): SYSTEM › Updates mostra "Not installed with yorha".

**Encaixe**
- **FR-016**: O projeto MUST trazer um arquivo de Hyprland (`system/hypr/`) com:
  - os atalhos SUPER;
  - o autostart do shell;
  - a regra `no_anim` do `yorha-popup`.

  O arquivo MUST apontar pra versão em uso (pelo `current` ou pelo `yorha`), nunca pra uma pasta de
  versão.
- **FR-017**: O shell MUST achar os sons e os assets pela pasta da versão (sem `/usr/share`). O cursor
  fica fora da v0: o tema precisa ser compilado, e a versão é o `git archive` do commit (research R8,
  aprovado pelo dono em 01.11). Ele entra quando as versões ganharem um passo de build.
- **FR-018**: As variáveis de ambiente do produto MUST ter o nome do produto (`YORHA_OS_*`); as velhas
  (`NIER_*`) continuam aceitas enquanto o lab usar.
- **FR-019**: O nome do produto (`yorha`, `yorha-os`, as pastas) MUST ficar num lugar só no instalador
  e no CLI.

**Núcleo e desinstalação**
- **FR-020**: O `yorha boot-login install|uninstall|status` MUST chamar o módulo da 011, com a
  confirmação e o sudo pedidos na hora.
- **FR-021**: O `yorha uninstall` MUST:
  - tirar as versões, o comando e o autostart;
  - manter a config;
  - perguntar antes de apagar o estado;
  - lembrar a linha do `hyprland.lua` e o boot e login instalados.

### Key Entities

- **Versão:** um arquivo com o produto inteiro (o shell, o `system/`, o `bin/`, as migrations), com o
  número `0.N` e um checksum.
- **Canal de versões:** onde o `yorha` acha o número mais novo e baixa as versões. Na v0, o
  repositório local (a `main` ou o worktree de uma spec), servido pelo lab.
- **Pasta do produto:** `~/.local/share/yorha-os/`, com `versions/<v>/`, o `current`, a anterior e os
  downloads em andamento.
- **Estado:** `~/.local/state/yorha-os/`, com o que os menus salvam, as migrations feitas, as cópias
  de antes de cada update e a última conferência de versão.
- **Config:** `~/.config/yorha-os/`, só da pessoa. Update e desinstalação nunca mexem nela.
- **Migration:** um script com data, que roda uma vez por usuário, na troca de versão.
- **Arquivo de encaixe:** o arquivo de Hyprland que a pessoa inclui.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Numa VM limpa, a instalação leva um comando e uma linha no `hyprland.lua`, e o shell sobe
  no próximo login.
- **SC-002**: Uma correção commitada aparece na VM instalada depois de um `yorha update`, sem nenhum
  outro passo (nem publicar, nem copiar).
- **SC-003**: A migration de teste roda exatamente uma vez, e o rollback devolve o estado de antes,
  byte a byte.
- **SC-004**: Um update interrompido em qualquer passo deixa a VM com uma versão que sobe; testado em 3
  pontos do update.
- **SC-005**: Da transmissão "Update available" até o shell na versão nova: no máximo 3 cliques e
  nenhum comando digitado.
- **SC-006**: Depois do `yorha uninstall`, nenhum arquivo do produto sobra fora da config e do estado.
- **SC-007**: Os roteiros 003, 004, 007, 008 e 013 passam com as mudanças da 014 no shell, como hoje
  pelo lab. O shell iniciado pela instalação sobe com o log de QML limpo e responde ao IPC
  (`check-014`; research R9, aprovado pelo dono em 01.11).

## Assumptions

- O teste é todo no lab, medido com o `lab/perf`. Nada roda na máquina do dono (princípio I).
- Os atalhos SUPER são os mesmos que o lab usa com ALT (incluindo os provisórios da 008).
- A v0 confere só o checksum. A assinatura das versões entra antes da S6, como diz o `PLAN.md`.
- O terminal do "Update now" é o da config do shell (`terminal`, hoje `kitty`).
- A troca entre o Serpantinum e o YoRHa-OS na mesma máquina fica pra U7.
- O Niri fica de fora da v0. O arquivo de encaixe é só pro Hyprland.
- O protótipo do método D (`lab/u2/metodo-d`) é reaproveitado. As partes do estudo que não entram
  (instalar pacotes de "módulos", compilar shaders) saem.
