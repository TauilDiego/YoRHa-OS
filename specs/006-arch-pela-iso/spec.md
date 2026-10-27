# Feature Specification: Arch completo na VM (instalado pela ISO)

**Feature Branch**: `006-arch-pela-iso` (sai da `004-wallpaper-system`; não mexe em nada dela)

**Created**: 2026-10-27

**Status**: Rascunho, aguardando a aprovação do dono

**Input**: Fase S2 do `PLAN.md`: "Arch completo na VM | ISO + archinstall desassistido (8.5) | Um
comando entrega um `arch-limpo` instalado pela ISO". Pedido do dono: começar agora, em paralelo com
a trilha da UI.

## Contexto

Hoje o laboratório privado monta as camadas assim:

```
basic        imagem oficial de VM do Arch (pronta, já instalada por quem publica a imagem)
└── arch-limpo   + chave SSH do lab, hostname
    └── hypr-base    + Hyprland, Quickshell, login automático
        ├── dev
        └── teste-*
```

A `basic` é uma imagem de nuvem/VM: o Arch já vem instalado, com um usuário e um disco de tamanho
fixo. Ela é ótima pra desenvolver a UI, mas não é o que um usuário de verdade tem. Quem instala o
Arch numa máquina dá boot na **ISO oficial** e roda o **archinstall**, escolhendo carregador de
boot, sistema de arquivos, swap e rede.

O instalador da personalização (S3) e os updates (S4) precisam ser testados sobre esse sistema
realista. Esta fase faz o laboratório produzir, sozinho, um Arch instalado do mesmo jeito que o
usuário instala.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Um comando instala o Arch pela ISO oficial, sem ninguém olhando (Priority: P1)

O agente (ou o dono) roda **um comando** no laboratório. Sem nenhuma interação, ele:
1. usa a ISO oficial do Arch, já baixada e verificada;
2. liga uma VM nova com um disco vazio e dá boot na ISO;
3. roda o archinstall com um arquivo de configuração e um de credenciais, sem perguntas;
4. desliga, liga de novo **só pelo disco** e confere que o sistema instalado sobe;
5. congela o resultado como uma camada nova do laboratório, que serve de base pra outras.

No fim, o comando imprime o nome da camada, a versão da ISO, o tempo gasto e onde ficaram os logs.

**Why this priority**: É a entrega da fase. Sem ela, a S3 testa o instalador sobre uma imagem que
nenhum usuário tem.

**Independent Test**: Num laboratório que já tem a ISO verificada, rodar o comando dentro de uma
sessão de medição e, no fim, criar uma camada descartável por cima da camada nova, ligar e conferir
por comandos que é um Arch instalado pelo archinstall (carregador de boot, sistema de arquivos,
usuário, rede, nenhum serviço com falha).

**Acceptance Scenarios**:

1. **Given** um laboratório com a ISO verificada e sem a camada nova, **When** o comando roda,
   **Then** termina sozinho, com sucesso, e a camada nova aparece congelada na lista de camadas, com
   a ISO de origem anotada.
2. **Given** a camada nova, **When** uma VM descartável criada sobre ela liga, **Then** o sistema
   sobe pelo disco (sem a ISO), responde no SSH do lab com o usuário do lab e não tem nenhum serviço
   com falha.
3. **Given** a VM descartável ligada, **When** se pergunta pelo carregador de boot, pelo sistema de
   arquivos da raiz, pela swap, pela rede e pela origem da instalação, **Then** as respostas batem
   com o arquivo de configuração usado, e o log do archinstall está guardado junto da camada.
4. **Given** que a camada nova já existe, **When** o comando roda de novo sem pedir pra refazer,
   **Then** ele avisa e não faz nada; pedindo pra refazer, ele recusa se houver camadas em cima dela.

---

### User Story 2 - A ISO é sempre a mesma e sempre conferida (Priority: P1)

A ISO usada fica **fixada** no laboratório (versão e hash), como já acontece com a imagem `basic`.
Antes de cada uso, ela é conferida pelo hash publicado e pela assinatura da equipe do Arch, com uma
chave fixada no repositório privado. Atualizar a ISO é um passo explícito, que muda o arquivo de
fixação.

**Why this priority**: Reproduzir uma falha de instalação exige saber exatamente qual ISO foi usada.
E nada que não foi verificado pode dar boot no laboratório.

**Independent Test**: Baixar a ISO fixada, conferir; depois, numa cópia com um byte trocado, conferir
de novo e ver a recusa; por fim, pedir a mais nova e ver o arquivo de fixação mudar.

**Acceptance Scenarios**:

1. **Given** um laboratório sem a ISO, **When** a ISO é pedida, **Then** a versão fixada é baixada e
   só fica disponível depois de passar no hash e na assinatura.
2. **Given** uma ISO adulterada ou com assinatura inválida, **When** a instalação começa, **Then** ela
   para antes de ligar qualquer VM, com uma mensagem clara.
3. **Given** a versão fixada já saiu dos mirrors comuns, **When** ela é pedida, **Then** vem do arquivo
   histórico oficial do Arch, com a mesma verificação.
4. **Given** um pedido explícito da ISO mais nova, **When** ele roda, **Then** o arquivo de fixação passa
   a apontar pra versão nova (e o hash dela), e a versão antiga continua no disco até ser apagada.

---

### User Story 3 - A camada nova serve de base pro resto do laboratório (Priority: P2)

A camada instalada pela ISO entra na cadeia de camadas **ao lado** da que vem da imagem `basic`, sem
quebrar nada do que existe. Sobre ela dá pra criar camadas de teste do mesmo jeito de sempre, e a
mesma preparação que hoje transforma o `arch-limpo` na `hypr-base` funciona em cima dela.

**Why this priority**: É o que torna a camada útil pra S3 e S4. Mas a US1 sozinha já é entregável: um
Arch realista onde rodar o instalador à mão.

**Independent Test**: Criar uma camada descartável sobre a camada nova, rodar nela a preparação da
`hypr-base`, ligar e tirar um screenshot do Hyprland com o smoke da UI.

**Acceptance Scenarios**:

1. **Given** a camada nova, **When** se cria uma camada de teste em cima dela, **Then** os comandos de
   sempre do laboratório (ligar, SSH, screenshot, desligar, apagar) funcionam nela sem mudança.
2. **Given** uma camada de teste sobre a camada nova, **When** a preparação da `hypr-base` roda nela,
   **Then** o Hyprland sobe com o login automático e o screenshot mostra o smoke da UI.
3. **Given** as camadas que já existem (`basic`, `arch-limpo`, `hypr-base`, `dev`, `teste-*`), **When**
   a fase termina, **Then** nenhuma delas mudou, e os agentes que estavam usando as VMs em paralelo
   não foram afetados.

---

### User Story 4 - Uma falha deixa pistas e não deixa lixo (Priority: P3)

Se algo dá errado (sem rede, mirror fora do ar, archinstall recusando a configuração, sistema que não
sobe depois da instalação), o comando para com uma mensagem que diz **em que passo** falhou e onde
estão os logs e um screenshot do console. Nenhuma camada pela metade fica congelada nem aparece como
base utilizável.

**Why this priority**: Instalações desassistidas falham em silêncio quando não são feitas pra
explicar. Mas isso só importa depois que o caminho feliz existe.

**Independent Test**: Rodar com uma configuração inválida de propósito e, depois, cortar a rede da VM
no meio; nos dois casos, conferir a mensagem, os logs, o screenshot e a ausência da camada.

**Acceptance Scenarios**:

1. **Given** uma configuração inválida, **When** o comando roda, **Then** ele falha **antes** de
   apagar o disco da VM, diz que a configuração foi recusada e mostra o motivo dado pelo archinstall.
2. **Given** uma falha no meio da instalação, **When** o comando termina, **Then** a VM está desligada,
   o log do archinstall e um screenshot do console estão na pasta de saída, e a camada não existe
   (ou existe marcada como incompleta só se o usuário pediu pra mantê-la pra investigar).
3. **Given** que o comando foi interrompido (Ctrl+C), **When** ele para, **Then** a VM é desligada e a
   camada pela metade é apagada.

### Edge Cases

- **Outra VM ligada em paralelo** (agentes): a instalação usa a porta SSH livre seguinte, como as
  outras VMs, e não precisa que as outras sejam desligadas.
- **Pouco espaço no disco do dono:** o comando confere o espaço livre antes de baixar ou criar
  qualquer coisa e para com o número que falta.
- **Sem aceleração de virtualização:** para com a mesma mensagem dos outros comandos do laboratório.
- **A chave de assinatura do Arch mudou:** a verificação falha; o comando explica que a chave fixada
  precisa ser atualizada (passo manual, conferido pelo dono).
- **O archinstall da ISO nova mudou o formato da configuração:** a configuração é validada antes de
  apagar o disco; se for recusada, o comando para (US4, cenário 1).
- **O archinstall termina "com sucesso" mas o sistema não sobe:** o sucesso só vale depois do segundo
  boot pelo disco; sem ele, é falha.
- **Os mirrors de pacotes estão lentos ou fora:** a instalação tem um tempo máximo; passado o limite,
  é falha com o log de onde parou.
- **Senha de usuário:** nunca aparece no terminal, no log guardado nem no repositório.

## Requirements *(mandatory)*

### Functional Requirements

**Comando e camada**
- **FR-001**: O laboratório MUST ter **um comando** que produz, sem interação, uma camada instalada
  pela ISO oficial do Arch com o archinstall, e a congela como base.
- **FR-002**: O nome padrão da camada nova MUST ser `arch-iso`, e o comando MUST aceitar outro nome.
- **FR-003**: A camada nova MUST ficar registrada como tendo vindo da ISO (com a versão), e a lista de
  camadas MUST mostrar isso.
- **FR-004**: O comando MUST recusar sobrescrever uma camada existente sem um pedido explícito, e MUST
  recusar refazer uma camada que tem outras camadas em cima.
- **FR-005**: As camadas existentes (`basic` → `arch-limpo` → `hypr-base` → `dev`/`teste-*`) MUST
  continuar funcionando sem mudança.

**ISO**
- **FR-006**: A ISO usada MUST ser a oficial, sem modificação, e MUST estar fixada (versão e hash) no
  arquivo de fixação de imagens do laboratório.
- **FR-007**: Antes de qualquer boot, a ISO MUST passar pelo hash publicado, pelo hash fixado e pela
  assinatura da equipe de release do Arch, verificada com uma chave fixada no repositório privado.
- **FR-008**: Atualizar a ISO MUST ser um pedido explícito, que muda o arquivo de fixação.
- **FR-009**: Uma versão que saiu dos mirrors comuns MUST ser buscada no arquivo histórico oficial.

**Instalação**
- **FR-010**: A instalação MUST usar o archinstall que vem na ISO, com um arquivo de configuração e um
  de credenciais, no modo sem perguntas.
- **FR-011**: A configuração padrão MUST reproduzir as escolhas mais comuns de quem instala um desktop
  com o archinstall: carregador systemd-boot, kernel `linux`, btrfs com os subvolumes padrão, swap em
  zram, NetworkManager, perfil mínimo (sem desktop), idioma e teclado `en_US`/`us`, fuso UTC.
- **FR-012**: O comando MUST aceitar outro arquivo de configuração, pra a S3 testar variações (outro
  sistema de arquivos, outro carregador).
- **FR-013**: A configuração MUST ser validada pelo próprio archinstall **antes** de qualquer mudança
  no disco da VM.
- **FR-014**: Tudo o que o laboratório acrescenta ao que um usuário teria (o acesso por SSH com a chave
  do lab, sudo sem senha pro usuário do lab, o hostname do lab) MUST ficar num lugar só, identificado
  como "adaptação do laboratório", e listado num manifesto guardado junto da camada.
- **FR-015**: A senha do usuário MUST ser gerada pra cada camada, guardada só nos dados locais do
  laboratório (fora de qualquer repositório) e nunca impressa nem gravada em log.
- **FR-016**: A instalação MUST ter um tempo máximo; passado o limite, é falha.

**Verificação e evidência**
- **FR-017**: O sucesso MUST exigir um segundo boot só pelo disco, com SSH respondendo e nenhum
  serviço com falha.
- **FR-018**: O comando MUST guardar, numa pasta de saída por execução: o resultado da verificação da
  ISO, o log do archinstall, a configuração efetivamente usada (sem as credenciais), as respostas das
  conferências do sistema instalado e um screenshot do console no fim.
- **FR-019**: O comando MUST funcionar dentro de uma sessão do `lab/perf`, e cada passo (download,
  boot da ISO, instalação, segundo boot, conferência) MUST aparecer como marcador na medição.

**Falhas**
- **FR-020**: Em qualquer falha ou interrupção, o comando MUST desligar a VM, apagar a camada pela
  metade (a não ser que o usuário peça pra manter, e aí ela fica marcada como incompleta e nunca
  congelada) e dizer em que passo parou e onde estão os logs.
- **FR-021**: O comando MUST conferir antes de começar: aceleração de virtualização, espaço livre e
  que o nome pedido não está em uso.

**Isolamento**
- **FR-022**: Nada disso roda no sistema do dono além das ferramentas já aceitas do laboratório (o
  emulador, o download, a conferência de hash e assinatura, o SSH e a criação de imagens de disco).
  O archinstall roda só dentro da VM.

### Key Entities

- **ISO fixada**: versão, nome do arquivo, hash, assinatura e de onde veio (mirror ou arquivo
  histórico).
- **Configuração de instalação**: as escolhas do archinstall (disco, carregador, sistema de arquivos,
  swap, rede, perfil, idioma, fuso, pacotes extras). Vem com uma padrão; outras podem ser passadas.
- **Credenciais**: usuário do lab e o hash da senha dele. Geradas por camada e nunca versionadas.
- **Adaptações do laboratório**: a lista do que o lab acrescenta a uma instalação de usuário (FR-014).
- **Camada `arch-iso`**: o disco instalado e congelado, com a ISO de origem, o manifesto das
  adaptações e a pasta de logs da instalação que a criou.
- **Execução**: uma rodada do comando, com os passos, os tempos, o resultado e a pasta de saída.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Num laboratório com a ISO já baixada, **um comando**, sem nenhuma tecla apertada, deixa a
  camada `arch-iso` pronta e congelada em **até 20 minutos** (meta: menos de 10), medido pelo
  `lab/perf`.
- **SC-002**: Uma VM descartável sobre a `arch-iso` responde no SSH em **até 60 s** depois de ligada,
  e **0** serviços estão com falha.
- **SC-003**: As conferências no sistema instalado batem **100%** com a configuração usada: carregador,
  sistema de arquivos e subvolumes da raiz, swap, gerenciador de rede, usuário com sudo, hostname e o
  log do archinstall presente.
- **SC-004**: Uma ISO com **um byte** trocado é recusada **antes** de qualquer VM ligar, em 100% das
  tentativas.
- **SC-005**: A preparação da `hypr-base`, rodada sem mudanças sobre uma camada criada a partir da
  `arch-iso`, termina com sucesso e o screenshot mostra o Hyprland com o smoke da UI.
- **SC-006**: Rodar a fase inteira (incluindo apagar e refazer a `arch-iso`) não muda **nenhuma** das
  bases congeladas que já existiam (`basic`, `arch-limpo`, `hypr-base`): o hash dos discos delas é o
  mesmo antes e depois, e as camadas de trabalho dos outros agentes continuam na lista.
- **SC-007**: Com uma configuração inválida, o comando falha em **até 3 minutos**, sem ter mexido no
  disco da VM, e não deixa camada nova.
- **SC-008**: O relatório do `lab/perf` da instalação mostra o tempo de cada passo, o uso de CPU e
  memória no sistema do dono e o espaço em disco que a camada nova ocupa.
- **SC-009**: Nenhuma senha aparece em texto puro no terminal, nos logs guardados nem em nenhum
  repositório (busca pela senha gerada nos arquivos de saída retorna 0 resultados).

## Assumptions

- **Fora do escopo:** o instalador da personalização (S3), updates (S4), testes em hardware real,
  criptografia de disco, boot BIOS/legado e outras distros (S6).
- **A camada nova não substitui a `arch-limpo` nesta fase.** Ela entra ao lado. Trocar a base da
  `hypr-base` pela `arch-iso` é uma decisão do dono depois que a US3 passar (pergunta em aberto).
- **Pacotes do dia:** a instalação usa os repositórios atuais do Arch, como um usuário faria. Fixar
  os pacotes numa data do arquivo histórico fica como opção, não como padrão.
- **Sem cache de pacotes nesta fase:** cada instalação baixa os pacotes. O custo é medido; um cache
  só entra se a medição mostrar que vale (princípio VII).
- **Modo de boot:** UEFI, igual às outras VMs do lab.
- **Rede:** a mesma rede de usuário do emulador que o lab já usa, sem bridge nem mudança de firewall.
- **Constituição II:** a ISO usada é a oficial, sem modificação. O projeto continua sem ISO ou imagem
  própria; a ISO aqui é só a ferramenta de teste que um usuário real também usa.
- **Implementação:** fica no repositório privado do laboratório. Esta spec descreve o comportamento
  de forma genérica, sem segredos nem dados pessoais.
