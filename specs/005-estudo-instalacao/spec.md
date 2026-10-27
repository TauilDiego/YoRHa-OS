# Feature Specification: Estudo de instalação (U2)

**Feature Branch**: `005-estudo-instalacao` (sai da `004-wallpaper-system`, que já traz a 003)

**Created**: 2026-10-27

**Status**: Rascunho, aguardando a aprovação do dono

**Input**: Fase U2 do `PLAN.md`: "Estudo de instalação | Métodos A–D comparados, com o HUD como carga
(8.4) | `docs/estudo-instalacao.md` escrito e método escolhido". Os métodos estão na seção "Estudo:
como instalar e atualizar a UI" do manual do laboratório privado (antes, §8.4 do `PLAN.md`):
- **A. script + git:** o modelo do Omarchy v2/v3, que é o modelo do projeto;
- **B. pacote no AUR;**
- **C. repositório pacman próprio;**
- **D. versões lado a lado, com troca e volta (rollback).**

A carga é a UI de verdade (`shell/`, com o HUD, o popup de configurações e o papel de parede). O
resultado alimenta a S3 (instalador v0) e a S4 (`rien update` e migrations).

## Contexto

O projeto é uma camada sobre um Arch limpo (constituição II). Ainda não existe instalador: hoje a UI
chega na VM pelo `lab/sync`, que é ferramenta de desenvolvimento, não de entrega. Antes da S3 é preciso
saber, com números da VM, qual jeito de entregar e atualizar a camada é o mais seguro e o mais barato
de manter, sem quebrar a regra de que update nunca mexe nos arquivos do usuário (constituição III).

Esta fase é um **estudo**, não um produto: ela escreve protótipos descartáveis de cada método, roda
os mesmos cenários em cada um, mede, e termina com um documento e uma escolha. O instalador de
verdade é a S3.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Instalar e atualizar a UI pelos quatro métodos, medindo (Priority: P1)

O dono quer ver, lado a lado, o que acontece quando a mesma UI é instalada num Arch recém-instalado e
depois atualizada, por cada um dos quatro métodos. Cada método começa de uma VM nova, igual pros
quatro, e passa pelo mesmo roteiro:
1. instalar a versão 0.1 da carga;
2. entrar na sessão e ver a UI no ar;
3. atualizar pra versão 0.2, que muda algo visível, traz uma dependência nova e exige uma migration
   (um arquivo de estado do usuário muda de formato);
4. ver a UI 0.2 no ar, com a migration aplicada uma única vez.

**Why this priority**: É o núcleo do estudo. Sem essas medidas não há comparação, e é o caminho que
todo usuário vai percorrer (instalar uma vez, atualizar sempre).

**Independent Test**: Rodar o roteiro num método só, numa VM descartável, dentro de uma sessão de
medição, e conferir: o screenshot da 0.1, o da 0.2, a versão informada pelo comando de versão, o
arquivo de estado migrado e o relatório de custo.

**Acceptance Scenarios**:

1. **Given** uma VM nova a partir da camada de Arch limpo, **When** o método instala a 0.1, **Then** a
   sessão abre com a UI 0.1 (screenshot), o comando de versão responde 0.1, o log da UI não tem erro de
   QML, e o tempo, os bytes baixados e o número de pedidos de privilégio ficam registrados.
2. **Given** a 0.1 instalada, com arquivos do usuário de exemplo em `~/.config`, **When** o método
   atualiza pra 0.2, **Then** a UI 0.2 aparece (screenshot), a dependência nova está instalada, a
   migration rodou uma vez (o arquivo de estado está no formato novo), e os arquivos do usuário têm o
   mesmo conteúdo de antes (soma de verificação igual).
3. **Given** a 0.2 instalada, **When** o mesmo update é pedido de novo, **Then** nada muda: nenhuma
   migration roda de novo, nenhum arquivo é reescrito (idempotência).
4. **Given** uma 0.2 publicada e a 0.1 instalada, **When** o usuário só abre a sessão, **Then** o estudo
   registra se e como o método avisa que existe update.

---

### User Story 2 - Um documento que compara e uma escolha (Priority: P1)

O dono lê um documento curto, com uma página de resumo e uma matriz de comparação em que cada célula
aponta pra uma evidência (relatório de medição, screenshot, log) ou pra uma fonte citada. No fim, um
método (ou uma combinação justificada de métodos) é escolhido, e o documento lista o que a S3 e a S4
herdam: estrutura de pastas, passos do update, onde rodam as migrations, como volta uma versão.

**Why this priority**: É o "pronto quando" da fase no `PLAN.md`. Sem ele o estudo não serve pra
decidir nada.

**Independent Test**: Com os dados da US1, escrever o documento e conferir que toda célula da matriz
tem evidência ou fonte, que os pesos foram fixados antes das medições e que a escolha segue da conta.

**Acceptance Scenarios**:

1. **Given** as medições de todos os métodos, **When** o documento é escrito, **Then** ele tem: resumo
   de uma página, matriz com todos os critérios pros quatro métodos, a conta da pontuação, os métodos
   eliminados pelos critérios obrigatórios (e por quê), a escolha e as entradas pra S3 e S4.
2. **Given** a matriz, **When** o dono troca os pesos, **Then** ele consegue refazer a conta só com o que
   está no documento (os pesos e as notas ficam separados e visíveis).
3. **Given** uma afirmação sobre um método que não foi medida na VM (por exemplo, regras do AUR),
   **When** ela entra no documento, **Then** traz a fonte e é marcada como "pesquisa", não como medida.

---

### User Story 3 - Quando algo dá errado: volta, interrupção e recuperação (Priority: P2)

O dono quer saber o que cada método faz quando um update dá errado. São três situações:
- **versão quebrada:** a 0.3 publicada abre com erro;
- **interrupção:** a VM desliga no meio do update (durante o download, durante a troca dos arquivos e
  durante a migration);
- **sem rede:** o servidor da carga some no meio de uma instalação ou de um update.

Pra cada uma, o estudo registra o estado em que a máquina fica, se a UI ainda abre, quais passos levam
de volta a uma versão que funciona e quanto tempo isso leva.

**Why this priority**: O Arch é rolling e quebra coisas (risco do `PLAN.md`). Um método que instala bem
mas não volta é um risco pro usuário. Vem depois da US1 porque depende do roteiro de update pronto.

**Independent Test**: Num método só: publicar a 0.3 quebrada, atualizar, tentar voltar pra 0.2 e medir;
repetir com o desligamento forçado em cada um dos três pontos.

**Acceptance Scenarios**:

1. **Given** a 0.2 instalada e a 0.3 quebrada publicada, **When** o usuário atualiza e depois pede a
   volta, **Then** o estudo registra se a volta existe, quantos passos e quanto tempo leva, e se o estado
   do usuário (já migrado) continua legível pela 0.2.
2. **Given** um update em andamento, **When** a VM é desligada à força num dos três pontos, **Then**
   depois de religar o estudo registra: a UI abre ou não, em qual versão, se a próxima tentativa de
   update conserta sozinha, e o que o usuário precisa fazer.
3. **Given** o servidor da carga fora do ar, **When** o usuário instala ou atualiza, **Then** o estudo
   registra a mensagem que aparece e confere que a versão que estava instalada continua funcionando.

---

### User Story 4 - Confiança: de onde vem o que é instalado (Priority: P2)

O dono quer saber, por método, o que garante que a carga instalada é a que ele publicou: o que é
verificado, o que o usuário precisa aceitar (uma chave, um repositório), e o que acontece se alguém
trocar a carga no servidor.

**Why this priority**: A instalação começa com um comando baixado da internet (risco `curl | bash` do
`PLAN.md`). Um método sem verificação precisa de mitigação antes de ir a público (S6).

**Independent Test**: Num método só: servir uma carga adulterada (um arquivo trocado depois da
publicação) e conferir se a instalação ou o update recusa.

**Acceptance Scenarios**:

1. **Given** uma carga adulterada no servidor, **When** o método instala ou atualiza, **Then** o estudo
   registra se o método detecta e recusa, e com qual mensagem.
2. **Given** um usuário novo, **When** ele instala, **Then** o estudo registra o que ele precisa
   confiar e fazer à mão (importar chave, adicionar repositório, revisar receita).

---

### User Story 5 - O custo de manter, pro dono (Priority: P2)

O dono mantém o projeto sozinho. Pra cada método, o estudo faz de verdade, no laboratório, uma
publicação da 0.2: do commit pronto até a versão disponível pros usuários. Conta os passos manuais, o
tempo, a infraestrutura necessária (hospedagem, chave de assinatura, automação) e o que pode quebrar
sem ele mexer (por exemplo, uma atualização de biblioteca do Arch que exige republicar).

**Why this priority**: Um método bom pro usuário e caro pro dono não se sustenta. O `bin/` do Omarchy v3
com 114 comandos é o exemplo de escopo que cresce (risco do `PLAN.md`).

**Independent Test**: Num método só: cronometrar e listar os passos de publicar a 0.2 a partir do
commit, sem automação nova além do protótipo.

**Acceptance Scenarios**:

1. **Given** a 0.2 pronta no git, **When** o dono publica pelo método, **Then** o estudo registra passos,
   tempo, segredos envolvidos (chave) e o que precisa existir antes (hospedagem, conta, automação).
2. **Given** a camada pessoal num repositório privado, **When** o estudo avalia o método, **Then** ele
   diz se o mesmo método serve pra entregar o módulo pessoal, e com qual custo.

---

### Edge Cases

- **Arquivo gerenciado editado pelo usuário** (alguém mexe direto na pasta de padrões): o update
  conflita, sobrescreve ou guarda backup? Cada método é testado com uma edição dessas.
- **Dois usuários na mesma máquina:** quando a carga é instalada pro sistema todo, as migrations (que
  são por usuário) rodam pra quem, e quando? O roteiro inclui um segundo usuário que entra depois do
  update.
- **Volta depois de uma migration:** a 0.2 consegue ler um estado que a 0.3 já migrou? Se não, o método
  precisa guardar uma cópia do estado antes de migrar.
- **Outro gerenciador de pacotes rodando** (trava do pacman) no momento do update.
- **Pacotes de dependência novos que exigem atualizar o sistema todo** (atualização parcial não é
  suportada no Arch): o método força um update completo, avisa ou ignora?
- **Biblioteca do Qt atualizada no Arch** depois da instalação: alguma parte da carga precisa ser
  refeita (os shaders compilados, por exemplo)?
- **Desinstalar:** o que sobra no disco depois de remover (fora de escopo no produto, mas medido aqui,
  porque pesa na escolha).
- **Disco quase cheio** durante o update: só registrado se o método guarda várias versões (D).

## Requirements *(mandatory)*

### Functional Requirements

**Carga e versões**

- **FR-001**: A carga MUST ser a UI do `shell/` num commit fixo, a mesma pros quatro métodos, incluindo
  o que ela precisa gerar no destino (os shaders compilados).
- **FR-002**: O estudo MUST ter três versões da carga, geradas no laboratório a partir desse commit:
  - **0.1:** a UI como está;
  - **0.2:** uma mudança visível na tela, uma dependência de sistema nova e uma mudança de formato num
    arquivo de estado do usuário, que exige uma migration;
  - **0.3:** uma versão que abre com erro, pra testar a volta.
  O `shell/` do repositório não muda nesta fase.
- **FR-003**: Todos os métodos MUST cumprir o mesmo contrato de entrega: um comando que abre a UI, um
  comando que informa a versão, padrões gerenciados separados dos arquivos do usuário, estado do
  usuário em `~/.local/state/rien-os/`, migrations que rodam uma vez por usuário.

**Ambiente e medição**

- **FR-004**: Todo cenário MUST rodar no laboratório privado, numa VM descartável criada da mesma camada
  pros quatro métodos, dentro de uma sessão `lab/perf` (constituição I e IV).
- **FR-005**: O que no mundo real seria público (o repositório git, o AUR, o repositório pacman, os
  pacotes de versão) MUST ser simulado no laboratório. Nada é publicado de verdade nesta fase.
- **FR-006**: Builds de pacotes e assinaturas MUST rodar num container do laboratório ou numa VM, com
  uma chave descartável só do laboratório.
- **FR-007**: As medidas de tempo MUST ser repetidas três vezes por método, em VMs novas, uma de cada
  vez, e o documento MUST usar a mediana.
- **FR-008**: Cada execução MUST gerar um registro com: método, cenário, versão de origem e de destino,
  tempo, bytes da carga, bytes de dependências, pedidos de privilégio, resultado, evidências (ids de
  screenshots e o id do relatório `lab/perf`).

**Critérios medidos**

- **FR-009**: O estudo MUST medir, por método:
  - tempo e bytes da primeira instalação (separando carga e dependências);
  - tempo e bytes do update 0.1 → 0.2;
  - pedidos de privilégio na instalação, no update e na volta;
  - se a dependência nova entra sozinha;
  - como o usuário fica sabendo do update;
  - migrations: uma vez por usuário, idempotentes, onde rodam;
  - volta pra versão anterior: existe, passos, tempo, estado do usuário legível;
  - interrupção nos três pontos: estado depois de religar e passos de recuperação;
  - comportamento sem rede;
  - verificação da carga (adulteração detectada ou não) e o que o usuário precisa confiar;
  - o que sobra depois de desinstalar;
  - espaço em disco usado.
- **FR-010**: O estudo MUST conferir, em toda execução, que os arquivos do usuário em `~/.config` não
  mudaram (soma antes e depois). Um método que altere arquivo do usuário sem backup está eliminado
  (constituição III).
- **FR-011**: O estudo MUST registrar, por método, o custo de publicação pro dono (US5): passos manuais,
  tempo, infraestrutura, segredos e o que obriga a republicar sem mudança no projeto.
- **FR-012**: O estudo MUST avaliar o encaixe de cada método no modelo do projeto: camada sobre Arch
  limpo, padrões × arquivos do usuário, módulos opcionais, camada pessoal privada, e o uso futuro no
  Niri e no Omarchy (S5, S7), por avaliação escrita com fonte.

**Decisão**

- **FR-013**: Os critérios, os pesos e as notas de 0 a 3 (com o que cada nota significa) MUST ser fixados
  e registrados antes da primeira medição.
- **FR-014**: Critérios obrigatórios MUST eliminar um método antes da conta: alterar arquivo do usuário
  sem backup; não ter como rodar migrations por usuário; deixar a máquina sem UI e sem caminho de
  recuperação documentado depois de uma interrupção.
- **FR-015**: `docs/estudo-instalacao.md` MUST trazer: resumo de uma página, a matriz com evidência ou
  fonte em cada célula, a conta, a escolha (um método ou uma combinação justificada) e as entradas
  concretas pra S3 e S4.
- **FR-016**: O que vier de pesquisa (e não de medição) MUST vir com a fonte e marcado como pesquisa.
- **FR-017**: Os protótipos dos métodos são descartáveis e ficam fora do produto; só o documento e as
  conclusões entram no repositório público.

### Key Entities

- **Método**: um dos quatro jeitos de entregar (A, B, C, D), com o protótipo que instala, atualiza, volta
  e desinstala, e a simulação do lado do servidor (repositório git, receita no estilo AUR, repositório
  pacman, pacotes de versão).
- **Versão da carga**: 0.1, 0.2 ou 0.3, com o que muda em cada uma (tela, dependência, formato do estado).
- **Cenário**: um roteiro do estudo (instalar, atualizar, repetir o update, volta, interrupção em um
  ponto, sem rede, carga adulterada, segundo usuário, desinstalar, publicar).
- **Execução**: uma passada de um cenário num método, com o registro de medidas e as evidências.
- **Critério**: o que é comparado, com peso, as âncoras das notas 0–3, e se é obrigatório.
- **Matriz**: as notas de cada método em cada critério, cada uma ligada a execuções ou fontes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Os quatro métodos passam pelos cenários de instalar, atualizar e repetir o update, três vezes
  cada, e 100% das execuções têm registro, screenshot da UI no ar e relatório de medição.
- **SC-002**: Os cenários de falha (versão quebrada, interrupção nos três pontos, sem rede, carga
  adulterada, segundo usuário) rodam pelo menos uma vez em cada método, com o resultado registrado.
- **SC-003**: Em nenhuma execução os arquivos do usuário mudaram sem backup; se mudaram, o método está
  marcado como eliminado no documento, com a evidência.
- **SC-004**: Na máquina do dono, os relatórios mostram só as ferramentas do laboratório rodando
  (QEMU, container, ssh, rsync); nenhum processo da UI, do instalador ou de build.
- **SC-005**: O documento tem uma página de resumo e uma matriz em que 100% das células apontam pra uma
  execução ou pra uma fonte citada; um leitor refaz a conta com outros pesos usando só o documento.
- **SC-006**: O método escolhido tem, pra cada cenário de falha, um caminho de recuperação escrito que,
  seguido na VM, devolve a UI funcionando em até 5 minutos.
- **SC-007**: O documento lista pelo menos as entradas pra S3 (estrutura de pastas, ponto de entrada,
  instalação das dependências) e pra S4 (passos do update, onde rodam as migrations, como volta uma
  versão, como o usuário fica sabendo), e o dono aprova a escolha.

## Assumptions

- **Nada é publicado de verdade:** o AUR, a hospedagem do repositório pacman e as versões de D são
  simulados num servidor do laboratório. A publicação real fica pra S6, com aprovação do dono. Uma
  checagem pontual contra o AUR real (instalar um pacote de shell Quickshell que já existe lá) pode
  entrar como referência de experiência do usuário, sem publicar nada.
- **A carga é só a UI** (`shell/`, com os shaders compilados no destino). O tema de cursor
  (`system/cursors/`), que tem um build pesado, entra como carga secundária opcional, só pra medir a
  diferença entre "montar no destino" e "baixar pronto".
- **A escolha vale pra camada inteira, não só pra UI:** a UI é a carga de teste, mas o que se aprende
  decide como a S3 entrega também os padrões, o `bin/` e as migrations. Combinações (por exemplo, um
  método pra camada e outro pras partes compiladas) são permitidas, se justificadas.
- **Os pesos de partida** (ver o plano) dão mais peso a recuperação, atualização e manutenção do que à
  velocidade da primeira instalação. O dono pode trocar antes das medições.
- **Os protótipos** ficam no repositório privado do laboratório; o repositório público recebe o
  documento.
- **Só Hyprland**; o Niri (S5) e o pacote pro Omarchy (S7) entram só como avaliação escrita.
- **Um usuário com sudo**, como a S3 assume; um segundo usuário é criado só pro cenário de dois usuários.
- **Rollback do sistema inteiro** (snapshots do disco antes de um update do pacman) é avaliado só como
  pesquisa; a medição cobre a volta da camada.
