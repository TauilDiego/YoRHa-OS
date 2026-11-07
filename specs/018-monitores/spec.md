# Feature Specification: a aba DISPLAYS

**Feature Branch**: `018-monitores` (sai da `019-sistema-real`, commit bf4e7fd)

**Created**: 2026-11-06

**Status**: Rascunho, esperando a aprovação do dono. Só a spec: sem plano, sem tarefas, sem código.

**Input**: O dono pediu, em 03.11, uma aba do menu de pausa pra arrumar os monitores, e decidiu que ela entra na 0.1.0
com tudo real: "imagina ai o cara trocar resolução do monitor e não fazer nada". As respostas às 14 perguntas da proposta
estão em "Decisões do dono".

**Protótipo**: https://claude.ai/artifact/MucKGki42WGujoM6ABZSUX, versão 1794017700-da09. O movimento e o visual aprovados
são da versão 1793967953-6226.

**Etapa:** é a etapa 2 da 019. Esta spec cobre a linha "Mudar Resolution, Refresh rate e Scale" da tabela da onda 2 da
019 e resolve o "Conflito pra 018" de lá.

## Pro dono decidir

**P1. Quando o teste no monitor de verdade acontece?** Boa parte desta spec só se prova em tela de verdade (a tabela em
"Como cada coisa se prova"). Só que a 0.1.0 espera a 018, e a sua migração espera a 0.1.0: do jeito que está, a release
sairia sem ninguém ter trocado o modo de um painel real. **Recomendo:** antes de publicar, você instala um candidato a
release do lado do Serpantinum na sua máquina (o caminho seguro que já combinamos, e por decisão sua, princípio I) e roda
a lista. A 0.1.0 só publica com a lista marcada. Sem isso, a alternativa é publicar dizendo nas notas que os monitores
não foram testados em hardware, e eu não recomendo.

**P2. Confirma SYSTEM › Display?** Resolution, Refresh rate e Scale saem de lá, e Display fica com Brightness, Night light e
o atalho "Arrange displays…". Isso foi um padrão do coordenador, não uma resposta sua. **Recomendo:** confirmar. Com dois
monitores, um valor só não faz sentido. Com o nome novo, a categoria Display e a aba DISPLAYS ficam quase iguais. Não renomeei
nenhuma: uma é categoria dentro de SYSTEM, a outra é aba, e o atalho liga as duas.

### Padrões que escolhi, sem perguntar

Cada um está num requisito. Diga se algum estiver errado.

- **Editar a linha de uma tela esquece a tela inteira naquela linha**, não só o campo editado, porque o Hyprland trata a
  regra como um bloco (FR-034).
- **Um conjunto de telas nunca visto** herda o que as telas já conhecidas tinham, e a tela nova entra colada à direita
  (FR-047).
- **Um modo salvo que a tela não oferece mais** cai na mesma resolução com a maior taxa até a salva, e o valor salvo fica
  guardado pra quando o modo voltar (FR-048).
- **Duas coisas que não estavam na lista do dono e entram por segurança:** a linha "Forget this arrangement" (FR-029),
  porque sem ela o único jeito de voltar ao arquivo seria editá-lo, e o comando `yorha displays forget` (FR-028), pra
  quando a tela estiver preta e o menu não der pra ver.
- **"Lines for my config" sai**, sem pergunta: com a regra do dono, ninguém precisa colar linhas.
- **`settings reset` não mexe no arranjo** (FR-037), porque um reset não pode apagar uma tela sem confirmação.
- **A tela conectada não manda notificação.** A proposta sugeria uma; ficou de fora, por não ter sido pedida.

### Contradições achadas

Nenhuma com a constituição depois da emenda. Com a 019 e com o que existe, estas:

1. **019 FR-044** diz que "a comparação da FR-026 é igual pra todo compositor; só a leitura é do backend". Aqui não dá: a
   comparação, a volta dos 15 s e a restauração precisam rodar com o shell desligado, então moram dentro do compositor. A
   FR-061 desta spec abre essa exceção.
2. **019 FR-023, D5 e os cenários US3.5 a US3.7** falam de três linhas de Display que seguem a tela em foco. Saem. O que eles
   provam muda de lugar (ver "SYSTEM › Display: a migração").
3. **Comentário do `yorha-shell.lua`** ("It writes nothing"): a restauração sem shell pode precisar gravar, pra lembrar o que
   foi esquecido. A sondagem S6 decide; se gravar, o comentário muda.
4. **Princípio IV** pede evidência da VM em todo critério, e parte desta spec só se prova em hardware. A saída é a mesma da
   019: a lógica prova na VM, com fixture onde preciso, e o resto fica na lista do dono, sem se dizer pronto sem ele (SC-009).

## A emenda da constituição (2.3.0, MINOR)

Aprovada pelo dono e aplicada em `.specify/memory/constitution.md` nesta branch. Amplia o que o princípio II cobre. Depois
do item "O que o sistema já oferece", entra:

> - **O arranjo de monitores:** o produto pode guardar, na pasta de estado dele, o arranjo de monitores que a pessoa
>   escolheu (modo, escala, rotação, posição, tela ligada ou não, espelho e tela principal, por conjunto de telas) e
>   aplicá-lo em tempo de execução, também depois de um reload e quando uma tela entra ou sai. Nunca edita o `hyprland.lua`
>   nem outra config pessoal. Se a pessoa editar no arquivo dela o que vale pra uma tela, vale o arquivo, e o produto
>   esquece o que tinha guardado pra aquela tela.

O princípio III continua igual: os arquivos do usuário sobrescrevem o que quiserem, porque uma edição sempre vence.

## Revisões de specs anteriores

- **019, tabela das 31 opções:** Display › Resolution, Refresh rate e Scale deixam de ser linhas de Display. Contam como
  reais pela DISPLAYS (019 FR-012, SC-008). O catálogo do produto passa de 63 pra 61 linhas: saem 3, entra 1.
- **019, "Conflito pra 018" e o fim da D3:** resolvidos pela decisão D6 desta spec. "This menu wins" não existe.
- **019 FR-006:** `settings reset` também não mexe no arranjo.
- **019, FR-044:** ver "Contradições", item 1.
- **019, limite "reload com o arquivo editado e o shell desligado":** não vale aqui, porque a comparação roda no compositor
  (FR-036).
- **007, lista de abas:** a lista ganha `displays`, depois de `windows`. A largura de 214 px fica: DISPLAYS cabe, com 17 px de jogo livres, medido no protótipo.

A 019 está sendo commitada por outro agente, então este texto não edita o `spec.md` dela. As notas vão lá na junção.

## User Scenarios & Testing *(mandatory)*

### Como cada coisa se prova

Toda rodada abre com `lab/perf begin` e fecha com `lab/perf end --result …`, em 1080 e em 1,25, no Hyprland 0.56.2 e no 0.57.
As evidências saem de uma `check-018`, nova, no lab privado.

**O que o lab tem** (`lab/README.md`, `lab/009/spikes/duas-saidas.md`):

- **A segunda tela é uma saída `headless`**, com `hyprctl output create headless [nome]` e `output remove`, como a check-004,
  a 008 e a 019 já fazem. Ela dispara os eventos de entrar e sair. O `grim` captura as duas.
- **`Virtual-1` tem lista de modos e descrição** (`Red Hat Inc. QEMU Monitor`, sem serial), vistas em `P9-monitors.json`.
- **Não existe segunda cabeça real pra agente.** `NIER_LAB_OUTPUTS=2` fica desconectado com `egl-headless` (spike T034). Só
  com `--window`, na mesa do dono, e isso nunca foi testado no Hyprland: ele pode tentar antes do hardware.
- **Não se sabe ainda** a descrição e os modos de uma saída `headless`. Vem da sondagem S5, antes de confiar nos testes de
  modelo e de telas iguais.

| Requisito | Na VM | Só em hardware (lista do dono) |
|---|---|---|
| Aplicar modo, escala, rotação, posição, ligar e desligar (FR-005 a FR-010) | **De verdade:** `hyprctl monitors all -j` e screenshot, em `Virtual-1` e na `headless` | Painel de 240 Hz e Dell de 100 Hz trocando de modo, o tempo que a imagem leva pra voltar, NVIDIA com escala fracionária e rotação |
| Colar de novo e nunca sobrepor (FR-014, FR-015) | **De verdade:** contas contra `monitors all -j` | Ponteiro passando de uma tela pra outra, de verdade |
| Espelhar (FR-012, FR-013) | **De verdade:** `mirrorOf` e screenshot | Tamanhos e taxas diferentes em espelho |
| A volta dos 15 s (FR-018 a FR-025) | **De verdade:** `kill -STOP`, `kill -9`, reload, VM desligada à força, tempo medido | Tela que ficou preta de verdade |
| Modo recusado (FR-026) | **Só fixture** e um modo inválido pedido ao Hyprland | O painel recusando um modo, sem sinal |
| Arquivo editado (FR-032 a FR-042) | **De verdade**, com um `hyprland.lua` de teste e `sha256sum` | A sua config, na migração |
| Conferir e avisar (FR-030, FR-031) | **De verdade**, com um `hl.on` de teste que re-cola as telas, como o seu `monitors.lua` | O próprio `monitors.lua` |
| Perfis, entrar e sair (FR-043 a FR-052) | **De verdade**, com a `headless` e o shell parado. O nome da `headless` muda a cada criação, o que testa "porta diferente, mesmo modelo" se a S5 confirmar | Cabo de verdade, Dell de DP-1 pra DP-2, dock, suspender e voltar |
| Duas telas iguais (FR-044) | **Se a S5 confirmar**, duas `headless` iguais. Senão, fixture | **Ninguém tem dois monitores iguais hoje.** Fica sem prova em hardware, e isso é dito nas notas da release |
| Modo que a tela não oferece mais (FR-048) | **Fixture**, mais um modo salvo à mão em `Virtual-1` | Cabo pior ou dock limitando a taxa |
| Tela principal (FR-053 a FR-056) | **De verdade:** `workspaces -j`, `getoption`, posição do ponteiro depois do login | O ponteiro ao logar, nas suas telas |
| Sem dupla piscada no reload (FR-039) | **Contando** mudanças de modo no log e em `monitor.layout_changed` | Olhar se a tela pisca |
| Visual e movimento (FR-065 a FR-068) | **De verdade:** `lab/burst`, screenshots, `lab/perf` | Olhar no notebook e no Dell |
| Barra, papel de parede e notificações depois de mudar a tela (US1, cenário 7) | **De verdade**, com screenshots | As duas telas, de perto |

### User Story 1 - Mudar uma tela de verdade (Priority: P1)

A pessoa abre DISPLAYS, escolhe uma tela e muda resolução, taxa, escala, rotação, ou liga e desliga. Tudo o que a linha
mostra é verdade, e mudar faz a tela mudar.

**Why this priority**: É a razão da aba, e a razão de ela estar na 0.1.0.

**Independent Test**: Na VM, com `Virtual-1`, trocar cada valor por teclas reais, aplicar, manter e conferir no `hyprctl`.

**Acceptance Scenarios**:

1. **Given** a aba aberta, **When** a pessoa escolhe outra resolução e aplica, **Then** a tela fica nela. **Evidência:**
   `monitors all -j` e screenshot.
2. **Given** a resolução escolhida, **When** a linha Refresh rate abre, **Then** ela lista só as taxas daquela resolução, e
   a escolhida vale depois de aplicar. **Evidência:** `displays dump` contra `availableModes`.
3. **Given** 2560×1600, **When** a linha Scale abre, **Then** 1,50× não aparece e o card diz por quê. **Evidência:** dump e
   screenshot.
4. **Given** um arquivo com escala 1,4 numa tela, **When** a linha abre, **Then** ela mostra `1.40×`, sem mudar nada, e
   escolher outro valor funciona. **Evidência:** dump.
5. **Given** cada valor de Orientation, **When** é aplicado, **Then** `transform` e o tamanho lógico batem. **Evidência:**
   `monitors all -j`, screenshot do mapa e da tela.
6. **Given** duas telas ligadas, **When** uma é desligada e aplicada, **Then** os workspaces dela vão pra outra; **When** só
   uma sobra, **Then** a linha Screen dela fica apagada com "The last screen on can't be turned off.". **Evidência:**
   `monitors all -j`, `workspaces -j`, dump.
7. **Given** qualquer mudança aplicada, **When** ela termina, **Then** barra, papel de parede e notificações estão certos em
   cada tela, sem erro no log. **Evidência:** screenshots, log do QML.
8. **Given** o catálogo e a aba, **When** procuro VRR, Adaptive sync ou Flip, **Then** não acho nada. **Evidência:** busca no
   código e no dump.
9. **Given** um arquivo com `vrr = 1` e `bitdepth = 10` numa tela, **When** a pessoa muda só a taxa e aplica, **Then** os
   dois continuam. **Evidência:** `monitors all -j`, `getoption`.

---

### User Story 2 - Aplicar sem medo (Priority: P1)

Nada muda até aplicar. Depois de aplicar, a pessoa tem 15 s pra confirmar. Se a tela apagou, se o shell travou, se ela não
fez nada, tudo volta sozinho.

**Why this priority**: Um modo errado pode deixar a pessoa sem imagem. Sem isso, a aba é perigosa.

**Independent Test**: Na VM, aplicar e parar o shell com `kill -STOP`, medindo quanto tempo a tela leva pra voltar.

**Acceptance Scenarios**:

1. **Given** mudanças na aba, **When** a pessoa não aplica, **Then** `monitors all -j` não muda, e a placa diz `N CHANGES NOT
   APPLIED`. **Evidência:** `monitors all -j` antes e depois, screenshot.
2. **Given** mudanças, **When** Esc é apertado, **Then** o diálogo pergunta Apply, Discard ou Stay. **Evidência:** dump.
3. **Given** um Apply, **When** o diálogo abre, **Then** ele aparece em todas as telas ligadas, com a contagem. **Evidência:**
   screenshot de cada saída, dump.
4. **Given** a contagem, **When** ninguém responde, **Then** tudo volta em até 18 s depois do Apply, e o disco não mudou.
   **Evidência:** tempo medido, `monitors all -j`, `sha256sum` do arquivo de estado.
5. **Given** a contagem, **When** Keep é escolhido, **Then** o arranjo fica, é gravado, e sobrevive a reload e a login.
   **Evidência:** `monitors all -j`, arquivo de estado.
6. **Given** a contagem, **When** Revert ou Esc, **Then** tudo volta na hora. **Evidência:** tempo medido.
7. **Given** a contagem, **When** o shell é parado com `kill -STOP`, **Then** tudo volta até o mesmo prazo. **When** é morto com
   `kill -9`, **Then** também. **Evidência:** tempo medido, nos dois casos.
8. **Given** a contagem, **When** a VM é desligada à força, **Then** o próximo login mostra o último arranjo mantido.
   **Evidência:** `monitors all -j` depois do login, arquivo de estado.
9. **Given** a contagem, **When** roda `hyprctl reload`, **Then** ela acaba, nada é mantido, e vale o último arranjo mantido.
   **Evidência:** `monitors all -j`, dump.
10. **Given** um Enter segurado desde a linha Apply, **When** o diálogo abre, **Then** a repetição não conta como Keep.
    **Evidência:** `lab/key`, dump.
11. **Given** o fixture "modo recusado", **When** aplica, **Then** volta na hora e a mensagem diz a tela e o modo. **Evidência:**
    screenshot, dump.
12. **Given** o shell novo e o Hyprland ainda com o `yorha-shell.lua` antigo, ou sem o include, **When** a aba abre, **Then** a
    linha Apply fica apagada e diz por quê, e nada pode ser aplicado. **Evidência:** dump, screenshot.
13. **Given** um arranjo salvo, **When** roda `yorha displays forget` num TTY e a pessoa loga, **Then** valem só as regras do
    arquivo dela. **Evidência:** `monitors all -j`, arquivo de estado.

---

### User Story 3 - Arrumar o mapa (Priority: P1)

A pessoa arrasta os cartões, ou move pelo teclado. As telas grudam borda com borda e nunca se sobrepõem. Se a escala ou a
rotação mudam, as telas se colam sozinhas. Entre telas, só estender ou espelhar.

**Why this priority**: É o que substitui o `monitors.lua` do dono.

**Independent Test**: Na VM com duas saídas, mudar a escala de uma e conferir que as bordas seguem encostadas.

**Acceptance Scenarios**:

1. **Given** duas telas lado a lado, **When** a escala da esquerda muda, **Then** a da direita fica encostada, sem buraco nem
   sobreposição. **Evidência:** contas em `monitors all -j`, depois de aplicar.
2. **Given** duas telas, **When** a da esquerda gira 90°, **Then** o mesmo. **Evidência:** idem.
3. **Given** um cartão, **When** é arrastado, **Then** segue o ponteiro 1:1, o encaixe aparece e, ao soltar, ele vai pro encaixe.
   **Evidência:** `lab/burst` com `lab/click`.
4. **Given** M e as setas, **When** a pessoa move, **Then** pula de encaixe em encaixe; Enter solta e Esc volta. **Evidência:** dump.
5. **Given** S, **When** apertado, **Then** a tela troca de lado com a vizinha. **Evidência:** dump, `monitors all -j`.
6. **Given** uma sobreposição que veio de fora, **When** Apply, **Then** é recusado, com a mensagem. **Evidência:** dump.
7. **Given** a tela 2 espelhando a 1, **When** aplica, **Then** `mirrorOf` bate, e a 2 aparece tracejada no mapa, sem posição.
   **Evidência:** `monitors all -j`, screenshot.
8. **Given** uma tela que é espelhada, **When** a linha Mirror dela abre, **Then** está apagada: não há cadeia. **Evidência:** dump.
9. **Given** a fonte de um espelho, **When** é desligada, **Then** o espelho vira tela normal, colada. **Evidência:** dump, `monitors all -j`.
10. **Given** I, **When** apertado, **Then** o número grande aparece em cada tela e some sozinho. **Evidência:** screenshot de cada saída.

---

### User Story 4 - O arquivo editado vence (Priority: P1)

É a regra do dono pra todas as opções. O valor do menu vale e volta depois de cada reload enquanto o arquivo não mudar. Se a
pessoa editar o arquivo, vale o arquivo, e o menu esquece.

**Why this priority**: Sem ela, o produto passa por cima da config da pessoa, ou o menu não dura.

**Independent Test**: Na VM, mudar pelo menu, dar reload sem editar (fica), editar a linha e dar reload (vale o arquivo).

**Acceptance Scenarios**:

1. **Given** um arquivo com `scale = 1` na tela, **When** o menu aplica 1,25 e mantém, **And** roda um reload sem editar, **Then**
   fica 1,25. **Evidência:** `monitors all -j`, depois do reload.
2. **Given** o cenário acima, **When** a linha muda pra `scale = 2` e recarrega, **Then** fica 2, o salvo daquela tela some, e o
   reload seguinte continua em 2. **Evidência:** `monitors all -j`, arquivo de estado.
3. **Given** valores salvos em duas telas, **When** só a linha de uma muda, **Then** a outra continua com o valor do menu.
   **Evidência:** idem.
4. **Given** um valor salvo, **When** o arquivo muda só num comentário ou em outra opção, **Then** nada é esquecido. **Evidência:** idem.
5. **Given** nenhuma regra da tela no arquivo e um valor salvo, **When** uma regra é acrescentada, **Then** vale a regra. **When**
   uma regra é apagada, **Then** o salvo também some. **Evidência:** idem.
6. **Given** o arquivo com a regra pela porta e a tela trocando de porta, sem editar nada, **When** recarrega, **Then** nada é
   esquecido. **Evidência:** idem, com a `headless`.
7. **Given** o arquivo com erro de config, **When** recarrega, **Then** nada é esquecido. **Evidência:** `configerrors`, arquivo de estado.
8. **Given** o shell parado, **When** o arquivo é editado e recarregado, **Then** vale o arquivo, e o salvo não volta quando o
   shell sobe. **Evidência:** `monitors all -j`, arquivo de estado.
9. **Given** um `hl.on` da pessoa que chama `hl.monitor` em evento, **When** recarrega duas vezes, **Then** isso não conta como
   edição. **Evidência:** arquivo de estado.
10. **Given** a rodada inteira, **When** termina, **Then** o `hyprland.lua` está igual. **Evidência:** `sha256sum`.
11. **Given** a tela com linha no arquivo, **When** a aba abre, **Then** o cartão tem CONFIG, e as opções dizem que vale até a
    pessoa editar aquela linha. **Evidência:** screenshot, dump.

---

### User Story 5 - Cada conjunto de telas guarda o seu arranjo (Priority: P1)

"Só o notebook" e "notebook + Dell" lembram cada um o seu. Plugou ou desplugou, o arranjo volta sozinho, mesmo com o shell
desligado. A tela é reconhecida pelo modelo, não pela porta.

**Why this priority**: É o que faz o arranjo sobreviver a desplugar o cabo, no dia a dia de um notebook.

**Independent Test**: Na VM, manter arranjos diferentes com e sem a `headless`, parar o shell, remover e criar a saída.

**Acceptance Scenarios**:

1. **Given** arranjos diferentes pra um e pra dois conjuntos, **When** a tela sai e volta, **Then** cada conjunto fica com o seu,
   em até 3 s. **Evidência:** `monitors all -j` com o tempo medido.
2. **Given** o shell parado, **When** a tela sai e volta, **Then** o mesmo. **Evidência:** idem, com `pgrep`.
3. **Given** o arranjo salvo e a tela voltando com outro nome de porta, **When** ela entra, **Then** é reconhecida. **Evidência:**
   `monitors all -j`, dump.
4. **Given** duas telas com a mesma descrição, **When** a aba abre, **Then** cada uma tem o seu valor, e a aba avisa que são
   separadas pela porta. **Evidência:** dump, screenshot.
5. **Given** a contagem aberta, **When** uma tela sai, **Then** a contagem acaba, nada é mantido, vale o arranjo do novo conjunto,
   e a mensagem diz isso. **Evidência:** dump, arquivo de estado.
6. **Given** um arranjo salvo com um modo que a tela não lista mais, **When** ela entra, **Then** usa o substituto, cola de novo, e
   a aba mostra o que houve. **Evidência:** dump (fixture), `monitors all -j`.
7. **Given** um conjunto em que o notebook está desligado e a outra tela sai, **When** só sobra o notebook, **Then** ele acende.
   **Evidência:** `monitors all -j`, em até 3 s.
8. **Given** a tela espelhando a outra, **When** a fonte sai, **Then** a que sobrou fica como tela normal, acesa. **Evidência:** idem.
9. **Given** um conjunto nunca visto com uma tela conhecida, **When** ele aparece, **Then** a conhecida fica como estava, a nova
   entra colada à direita, e nada é gravado. **Evidência:** `monitors all -j`, arquivo de estado.
10. **Given** a aba aberta com mudanças não aplicadas, **When** uma tela entra, **Then** o mapa redesenha, o foco fica numa tela
    que existe, e a mensagem diz que as mudanças não foram aplicadas. **Evidência:** dump, screenshot, log.
11. **Given** ninguém nunca usou a aba, **When** telas entram e saem, **Then** o produto não aplica nenhuma regra. **Evidência:**
    `hyprctl` antes e depois, ausência do arquivo de estado.

---

### User Story 6 - A tela principal (Priority: P2)

A pessoa diz qual é a tela principal, em cada conjunto: o workspace 1 fica nela, e o ponteiro começa nela.

**Why this priority**: O dono já usa isso, pela config dele, mas o resto funciona sem.

**Independent Test**: Na VM, escolher a outra saída como principal, manter, conferir o workspace 1, e logar de novo.

**Acceptance Scenarios**:

1. **Given** duas telas, **When** Main screen muda e aplica, **Then** o workspace 1 vai pra ela com as janelas. **Evidência:**
   `workspaces -j`, `clients -j`.
2. **Given** a principal salva, **When** a sessão recomeça, **Then** o ponteiro começa nela. **Evidência:** `cursorpos`.
3. **Given** dois conjuntos, **When** um troca pelo outro, **Then** cada um usa a sua principal, e o ponteiro não pula.
   **Evidência:** `workspaces -j`, `cursorpos` antes e depois.
4. **Given** um arquivo que põe o workspace 1 numa tela, **When** o menu escolhe outra, **Then** o menu vale, depois de cada
   reload; **When** a linha do arquivo muda, **Then** vale o arquivo, e o menu esquece a principal. **Evidência:** `workspaces -j`,
   arquivo de estado.
5. **Given** a principal, **When** é desligada ou vira espelho, **Then** a marca passa pra outra tela ligada. **Evidência:** dump.

---

### User Story 7 - Avisar quando outra coisa move uma tela (Priority: P2)

Depois de aplicar, a aba confere se o arranjo ficou. Se outra coisa moveu uma tela, avisa, sem adivinhar quem foi, e não briga.

**Why this priority**: É o que permite o dono trocar o `monitors.lua` dele sem ficar no escuro, e o que evita uma guerra sem fim
entre dois scripts.

**Independent Test**: Na VM, com um `hl.on("monitor.layout_changed", …)` de teste que re-cola as telas, aplicar.

**Acceptance Scenarios**:

1. **Given** um script de teste que re-cola as telas, **When** a pessoa aplica e mantém uma troca de lado, **Then** a aba diz que
   a tela mudou de lugar, de qual pra qual, e não cita script nenhum. **Evidência:** dump, screenshot.
2. **Given** o mesmo script, **When** passa 30 s, **Then** o produto não reaplicou nada: não há laço. **Evidência:** contagem de
   `monitor.layout_changed` e dos pedidos do produto.
3. **Given** o script removido, **When** roda um reload, **Then** o arranjo salvo vale e o aviso some. **Evidência:** `monitors all -j`, dump.

---

### User Story 8 - SYSTEM › Display (Priority: P2)

Display não promete o que não é dele. Quem quer mudar a tela chega na aba por um atalho.

**Why this priority**: São as linhas que a 019 deixou só leitura.

**Independent Test**: Abrir SYSTEM › Display na VM, e usar o atalho.

**Acceptance Scenarios**:

1. **Given** o catálogo do produto, **When** Display abre, **Then** tem Brightness, Night light e Arrange displays…, e nada mais.
   **Evidência:** dump, screenshot.
2. **Given** Arrange displays…, **When** Enter, **Then** o menu de pausa abre em DISPLAYS. **Evidência:** dump.
3. **Given** `YORHA_COMPOSITOR=none`, **When** os menus abrem, **Then** DISPLAYS e o atalho não aparecem. **Evidência:** dump, screenshot.
4. **Given** a check-003, com o catálogo de teste, **When** roda, **Then** passa igual. **Evidência:** `results.txt`.

---

### User Story 9 - O visual e o movimento aprovados (Priority: P2)

A aba é a que o dono aprovou no protótipo.

**Why this priority**: O dono aprovou isso em detalhe, e é onde o menu mais fica bonito ou feio.

**Independent Test**: `lab/burst` girando e arrastando um cartão, e os screenshots nas duas telas.

**Acceptance Scenarios**:

1. **Given** um cartão selecionado, **When** a captura é medida, **Then** os colchetes não cobrem o conteúdo, e o marcador tem a
   altura do cartão. **Evidência:** `geometry` no dump, screenshot.
2. **Given** uma tela em pé, **When** o cartão fica estreito, **Then** toda a informação aparece empilhada. **Evidência:** dump
   (nada em `lost`), screenshot.
3. **Given** girar, redimensionar ou mover, **When** o quadro a quadro é capturado, **Then** o movimento leva 280 ms, e o texto troca
   por fade, sem refazer a quebra. **Evidência:** `lab/burst`, tempos.
4. **Given** Reduce motion ligado, **When** o mesmo, **Then** não há movimento. **Evidência:** `lab/burst` e `lab/diffshot`.
5. **Given** a placa de teclas com `10 CHANGES NOT APPLIED`, **When** medida, **Then** nada é cortado, nas duas telas. **Evidência:**
   `geometry` no dump.
6. **Given** a posição no cartão, **When** a cor é medida, **Then** o contraste com a faixa do cabeçalho é de pelo menos 4,5:1.
   **Evidência:** a mesma medida de contraste da check-004.

---

### Edge Cases

- **Tela que apagou e voltou lenta:** a contagem é do compositor, então uma tela que leva 5 s pra dar imagem deixa 10 s pra
  responder. Vale pra hardware, e está na lista do dono.
- **Keep no último instante:** o compositor decide. Se a volta já começou, Keep não vale, e a mensagem diz isso.
- **Shell reiniciado durante a contagem:** o diálogo não volta, e a volta acontece no prazo. A aba mostra o estado real.
- **A gravação falhou no Keep (disco cheio):** o arranjo fica nesta sessão, o arquivo anterior continua, e a aba diz que não salvou.
- **Arquivo de estado ilegível:** é ignorado e fica guardado de lado, valem as regras da pessoa, e a aba diz. Nunca impede o login.
- **Reload logo depois de um Keep:** vale o que foi mantido.
- **Tela desligada pela tampa, etapa 3:** não muda o conjunto, nem o que está salvo (FR-043).
- **Vários eventos em seguida ao desplugar um dock:** vale o conjunto depois de 1 s sem evento. Uma restauração só.
- **Suspender e voltar, com uma tela sumindo e voltando:** igual ao item acima. A confirmar em hardware.
- **DPMS (tela só apagada):** não é uma mudança de conjunto.
- **A mesma tela em duas portas:** é o caso de telas iguais, sem serial (FR-044).
- **Transform com flip vindo do arquivo (4 a 7):** Orientation mostra a rotação, e mudar a rotação mantém o flip. A aba não oferece
  flip, mas não tira o da pessoa.
- **Limite: uma edição que grava o mesmo valor:** não é percebida, e o menu continua. O mesmo limite da 019.
- **Limite: uma regra que muda sozinha** (um `if` no Lua da pessoa que depende do número de telas ou do nome da máquina) parece uma
  edição, e o menu esquece. O erro cai pro lado do arquivo da pessoa.
- **Limite: o include fora do topo.** O que o arquivo pede antes dele pode não ser visto. O `yorha` manda pôr no topo, e a S1 diz se
  dá pra perceber isso.
- **Limite: ferramentas `wlr-output-management`** (nwg-displays, kanshi) passam por cima de regras. A aba só avisa (FR-030).
- **Tela nova com o menu fechado:** nada aparece. Quem quiser arrumar abre a aba.

## Requirements *(mandatory)*

### Functional Requirements

**A aba**

- **FR-001**: O menu de pausa MUST ter a aba DISPLAYS, id `displays`, depois de WINDOWS: APPS, WINDOWS, DISPLAYS, LOG, SYSTEM, POWER.
  As abas continuam com 214 px de jogo.
- **FR-002**: A página MUST ser a B: lista das telas à esquerda, mapa à direita. Enter numa tela troca a lista pelas opções dela,
  como SYSTEM faz. Não há outro layout, nem opção pra trocar.
- **FR-003**: O mapa MUST ter o estilo cartões no papel: papel pontilhado, cartão com cabeçalho de tinta, número, nome, modelo, modo,
  marcas (MAIN, rotação, CONFIG) e a posição em px lógicos no cabeçalho, sempre legível.
- **FR-004**: A lista e o mapa MUST mostrar toda tela conectada, ligada ou não. As desligadas ficam numa área OFF, e o espelho, tracejado,
  sobre a fonte. A numeração é a mesma em todo lugar: a tela embutida primeiro, depois por descrição. O cabeçalho da página mostra o conjunto atual.

**Cada tela**

- **FR-005**: As opções de uma tela MUST ser Screen (On, Off), Resolution, Refresh rate, Scale, Orientation, Mirror e Main screen. O
  grupo ALL SCREENS tem Identify screens, Apply, Undo changes e Forget this arrangement.
- **FR-006**: Resolution MUST oferecer só o que a tela lista. Um modo em uso fora da lista aparece como está. Tela sem lista: a linha
  mostra o valor e fica apagada, com o motivo (019 FR-004).
- **FR-007**: Refresh rate MUST oferecer só as taxas daquela resolução, e a escolha é da pessoa. Ao trocar a resolução, a taxa fica, se
  existir; senão, vem a maior. Os valores mostram até duas casas (`59.94 Hz`), e o valor pedido é o exato da lista.
- **FR-008**: Scale MUST oferecer só escalas que dão pixels inteiros naquele modo. Um valor em uso fora da lista aparece como está. Se
  mudar a resolução invalidar a escala, ela vai pra mais próxima válida, e a mensagem diz.
- **FR-009**: Orientation MUST oferecer Normal, 90°, 180° e 270°, com a direção de cada um conferida na S9 antes de escrever os textos.
- **FR-010**: A última tela ligada MUST NOT poder ser desligada (FR-049).
- **FR-011**: VRR, Adaptive sync e Flip MUST NOT existir, nem como opção, nem como marca, nem no que o produto guarda.

**Entre as telas**

- **FR-012**: Entre telas MUST existir só estender e espelhar.
- **FR-013**: Uma tela espelha uma fonte ligada que não é espelho. Não há cadeia. Se a fonte for desligada, o espelho volta a ser tela
  normal, colada.
- **FR-014**: A posição MUST mudar por arrastar ou pelo teclado (M), sempre em encaixes de borda com borda, e nunca sobrepõe. Apply recusa
  uma sobreposição que veio de fora. Uma tela solta (sem encostar) ganha um aviso na placa, e Apply deixa.
- **FR-015**: Ao mudar a escala, a rotação ou a resolução, a aba MUST colar as telas de novo sozinha, nos px lógicos (largura ÷ escala,
  trocadas em pé), sem buraco e sem sobreposição, com a menor posição em 0,0.
- **FR-016**: S MUST trocar a tela de lado com a vizinha que encosta.
- **FR-017**: Nada MUST mudar nas telas até Apply. Z desfaz o que não foi aplicado. Esc com mudanças pergunta Apply, Discard ou Stay.

**Aplicar, confirmar, voltar**

- **FR-018**: Apply MUST mandar o arranjo inteiro como uma tentativa, ao lado do compositor. O relógio de 15 s é armado **antes** da
  primeira mudança, e mora no compositor (no Hyprland, um `hl.timer` no arquivo incluído). O shell só pede.
- **FR-019**: Enquanto aplica, o rodapé MUST mostrar o anel Loading_Circle e `Applying…`.
- **FR-020**: O diálogo "Keep this arrangement?" MUST aparecer em todas as telas ligadas, com a contagem lida do compositor, nunca mostrando
  mais tempo do que ele tem. Uma tecla já segurada quando o diálogo abre não conta.
- **FR-021**: Keep MUST primeiro cancelar o relógio no compositor. Só com a resposta dele o arranjo é gravado, numa escrita atômica, com o
  anterior guardado como backup.
- **FR-022**: Sem resposta, o compositor MUST começar a voltar aos 15 s, sem depender do shell, e tudo está de volta em até 18 s na VM. Volta
  tudo o que a tentativa mudou, de todas as telas, ao estado de **antes do Apply**: modo, posição, escala, rotação, ligada, espelho e tela
  principal. Revert e Esc fazem o mesmo na hora. Vale com o shell travado, morto ou reiniciado. Depois de voltar, o produto relê e, se
  sobrar diferença, avisa e garante a FR-049.
- **FR-023**: Durante a tentativa, nada MUST ser gravado em disco. Se a sessão ou a máquina morrer, o próximo login usa o último arranjo
  mantido. Não existe estado intermediário a limpar. Um arquivo de estado ilegível é ignorado e guardado de lado, e nunca impede o login.
- **FR-024**: Um reload durante a tentativa MUST encerrá-la: nada é mantido, e vale o último arranjo mantido. A S4 prova o que acontece com o
  relógio nessa hora.
- **FR-025**: Uma tela que entra ou sai durante a tentativa MUST encerrá-la, igual: nada é mantido, e vale o arranjo do novo conjunto.
- **FR-026**: Até 1 s depois de aplicar, o produto MUST reler as telas. Se o modo pedido não pegou, volta na hora e diz qual tela e qual modo,
  sem esperar a contagem.
- **FR-027**: Sem o lado do compositor (include ausente, ou Hyprland ainda com o arquivo de uma versão anterior), Apply MUST ficar apagado,
  com o motivo. Sem rede de segurança não se aplica nada.
- **FR-028**: `yorha displays forget` MUST apagar o que o produto guardou sobre monitores, guardando um backup, sem precisar de compositor nem
  de shell. Vale de um TTY, e faz efeito no próximo login ou reload.
- **FR-029**: A linha Forget this arrangement MUST voltar as telas ao que o arquivo da pessoa diz, pela mesma confirmação de 15 s, e só então
  esquecer o que está salvo.

**Conferir**

- **FR-030**: Depois de aplicar e de cada restauração, com o shell no ar, o produto MUST comparar o que pediu com o que está valendo. Se a
  posição, o modo, a escala ou a rotação de uma tela forem outros, a aba avisa qual tela, do quê pra quê, enquanto a diferença existir. O texto
  MUST NOT dizer quem fez. Tolerâncias: 0,1 Hz na taxa, 1/240 na escala, nenhuma na posição.
- **FR-031**: O produto MUST NOT reagir a uma mudança que outra coisa fez reaplicando o arranjo. Ele só aplica no Apply, no reload, no login e na
  mudança de conjunto. Isso impede um laço com um script da pessoa. O valor salvo não muda por causa disso.

**O arquivo editado vence**

- **FR-032**: Um valor do menu MUST valer, e ser reaplicado depois de cada reload e login, enquanto o arquivo não mudar. Se a pessoa editar o
  que o arquivo pede pra uma tela, vale o arquivo, e o menu esquece. É a D2 da 019. Não existe opção pra trocar essa regra.
- **FR-033**: O equivalente do "valor lido do arquivo" da 019 é **a regra que o arquivo pede, não o texto do arquivo**: a lista das chamadas de
  regra de monitor feitas durante a leitura da config, por seletor, com os campos delas. Mudar um comentário ou outra opção não conta. Regras
  pedidas depois da leitura (um `hl.on` da pessoa) não contam, nem as do produto. Ausente também é um valor. A base é guardada a cada reload e
  login, antes de reaplicar. Um reload sem base nunca esquece nada. **Isso precisa de prova** (S1 e S2): esta spec não afirma que o Hyprland deixa
  fazer. Se nem S1 nem S2 provarem, volta pro dono, e a regra não muda sozinha.
- **FR-034**: Uma regra diferente da base (nova, apagada ou mudada) MUST esquecer tudo o que o menu guardou pras telas que aquele seletor pega, em
  todos os conjuntos. A linha é um bloco, porque no Hyprland a última regra que casa vale inteira. A regra de reserva (`output = ""`) conta pras
  telas sem regra própria. A porta em que a tela está não entra na comparação: trocar o cabo não é uma edição.
- **FR-035**: Com erro de config ou leitura incompleta, o produto MUST NOT comparar nem esquecer, como na 019 FR-042. O valor do menu é reaplicado.
- **FR-036**: A comparação MUST funcionar com o shell desligado, e o que ela esquece não volta quando o shell sobe. O limite da 019 sobre reload com
  o shell desligado não vale aqui.
- **FR-037**: Um update MUST NOT esquecer nada, nem mudar arquivo da pessoa. `settings reset` MUST NOT mudar telas nem o arranjo salvo. Mudanças de
  formato são migrations idempotentes (princípio III).
- **FR-038**: A regra que o menu manda MUST levar junto o que a linha da pessoa tem e o menu não mexe (`vrr`, `bitdepth`, `cm`, `sdr*`, `icc`,
  `reserved`, o flip do `transform`), porque a última regra vale inteira e o resto cairia no padrão. Se a S1 não provar, o que a tela reportar é
  levado, e a lista do que se perde vai pro dono antes do plano.
- **FR-039**: Um reload sem edição MUST NOT apagar nenhuma tela por uma troca de modo a mais. Se a S3 mostrar que isso é impossível, volta pro dono.
- **FR-040**: A marca CONFIG continua, pra toda tela com regra própria no arquivo: um reload não muda o valor do menu, mas uma edição naquela linha
  passa a valer. As opções dizem isso em uma frase. Se a S1 não provar, e o produto não souber quais telas o arquivo define, a marca sai.
- **FR-041**: "Your config wins", "This menu wins" e "Lines for my config" MUST NOT existir.
- **FR-042**: O produto MUST NOT escrever no `hyprland.lua` nem em outra config pessoal. Os dados ficam na pasta de estado dele.

**Conjuntos de telas**

- **FR-043**: Um conjunto é o conjunto das telas conectadas, ligadas ou não. A tela desligada por outra função (a tampa, etapa 3) não muda o conjunto
  nem o que está salvo. Regra do dono, pra a etapa 3 poder cumprir: "se tem tela conectada, quando fechar a tampa só desativa o monitor do notebook. se
  não tiver, quando fechar entra tudo em suspensão profunda." O adaptador oferece um jeito de apagar a embutida sem gravar nada, e a tela volta ao
  arranjo do conjunto ao ligar.
- **FR-044**: Uma tela MUST ser reconhecida pela descrição (marca, modelo e serial, quando ela informa), e o seletor usa `desc:`. Sem descrição, pela porta.
  **Duas telas com a mesma descrição:** se separam pela porta, porque `desc:` pegaria as duas. A aba avisa que trocar os cabos troca os arranjos, e
  Identify mostra qual é qual. A S5 confere o casamento por prefixo da descrição.
- **FR-045**: Keep MUST guardar só no conjunto atual. Cada conjunto tem o seu arranjo e a sua tela principal.
- **FR-046**: A restauração MUST acontecer ao logar, no reload, e ao conectar e desconectar, **do lado do compositor, sem depender do shell**, sem confirmação,
  depois de 1 s sem evento de tela, e estar pronta em até 3 s na VM.
- **FR-047**: Um conjunto nunca visto: as telas conhecidas MUST ficar com o último modo, escala e rotação mantidos em outro conjunto, a tela nova fica com o
  que o arquivo ou o compositor derem, e todas se colam, com a nova à direita. Nada é gravado até Keep. Se nada estiver salvo sobre nenhuma das telas, o
  produto não aplica nada: é o "só mexe da primeira vez que é novo" do dono.
- **FR-048**: Se um modo salvo não estiver na lista da tela: mesma resolução, com a maior taxa até a salva; se não houver, o `preferred` da tela. A tela se cola
  de novo, e a aba mostra o que está valendo e o que está salvo. O valor salvo fica, e volta quando o modo voltar.
- **FR-049**: Todas as telas apagadas MUST NOT acontecer por nada que o produto aplique. A aba recusa, o lado do compositor recusa de novo, e toda restauração
  confere. Se sobraria nenhuma, acende a embutida, ou a primeira, no `preferred`. Se for só o arquivo da pessoa que apaga tudo, o produto não interfere.
- **FR-050**: Um espelho cuja fonte saiu MUST virar tela normal, acesa e colada, com o último modo próprio, ou o `preferred`. A regra de espelho não fica valendo.
- **FR-051**: Uma tela que entra ou sai com a aba aberta MUST aparecer em até 1 s. Mudanças não aplicadas são descartadas, com uma mensagem, um diálogo aberto
  fecha, e o foco fica numa tela que existe.
- **FR-052**: Uma mudança de fora com a aba aberta (`hyprctl`, reload) MUST aparecer em até 1 s, com releitura enquanto a aba estiver à vista, porque algumas não
  geram evento (019, R5). Com mudanças não aplicadas, o mesmo do FR-051.

**A tela principal**

- **FR-053**: Main screen MUST guardar, por conjunto, onde fica o workspace 1 e onde o ponteiro começa. Só uma tela é a principal, e ela não pode ser espelho nem
  estar desligada: se for, a marca passa pra primeira ligada. Sem nada salvo, a linha mostra onde o workspace 1 está, e o produto não aplica nada.
- **FR-054**: Ao aplicar e ao restaurar, o workspace 1 MUST ir pra tela principal, com as janelas dele.
- **FR-055**: O ponteiro MUST começar na principal só no início da sessão (no Hyprland, `cursor.default_monitor`). Ele não pula quando uma tela entra ou sai.
- **FR-056**: Se o arquivo também define o workspace 1 ou o ponteiro, vale a regra das FR-032 a FR-036, com a base no que o arquivo pede pra eles. Editou: vale o arquivo
  e o menu esquece a principal.
- **FR-057**: A tampa MUST NOT entrar nesta spec. Vai pra Power › Lid closed, na etapa 3 (FR-043).

**SYSTEM › Display: a migração**

- **FR-058**: Resolution, Refresh rate e Scale MUST sair do catálogo do produto. Display MUST ficar com Brightness, Night light e a ação Arrange displays…, que abre
  o menu de pausa em DISPLAYS e tem `requires: monitorSet`. O `about` de Display muda: "Brightness and night light. Arranging your displays has its own tab.". **O dono pode
  mudar isso ao aprovar** (P2).
- **FR-059**: As três linhas nunca saíram em release (a 0.1.0 espera tudo, 019 D1), e `sys.*` não salva nada, então não há migração de quem instalou. A limpeza de
  `settings.display.resolution`, `.refresh` e `.scale` da 019 FR-007 MUST continuar: ela é uma lista fixa, que não depende das linhas existirem.
- **FR-060**: O que a prova das três linhas fazia MUST mudar de lugar, sem sumir. Ver a tabela depois dos requisitos.

**O adaptador**

- **FR-061**: Tudo MUST passar pelo adaptador (019 FR-044), com a capacidade `monitorSet`, já prevista no contrato. No `NullBackend`, ela é falsa, e a aba e o atalho somem
  (019 FR-045). **Exceção à 019 FR-044:** as garantias sem shell (FR-022, FR-036, FR-046) rodam dentro do compositor, então cada backend tem o seu lado de lá. No Hyprland, é o
  arquivo incluído. Um backend só liga `monitorSet` se cumprir essas garantias. Niri e Mango ficam prontos pra isso, e só o Hyprland entra na 0.1.0.
- **FR-062**: O domínio de fixture `monitors` MUST ganhar descrição, modos, `transform`, tela desligada, `mirrorOf` e os cenários "modo recusado", "modo fora da lista" e "telas
  iguais". Com fixture, nada é aplicado.
- **FR-063**: Tudo MUST funcionar no Hyprland 0.56.2 e no 0.57, com as mesmas evidências.
- **FR-064**: `yorha ipc displays dump` MUST dar o estado da aba pros testes: telas, rascunho, mensagens, conjunto, tentativa, base, geometria e linhas apagadas com o motivo.

**O visual e o movimento**

- **FR-065**: Os colchetes de seleção MUST empurrar o conteúdo do cartão pra dentro, sem cobri-lo. O marcador tem a altura inteira do cartão. Cartão em pé empilha toda a informação.
- **FR-066**: Girar, redimensionar e mover MUST animar em camadas separadas, com um tempo só, 280 ms ease-out, sem refazer o layout por quadro. O texto troca por fade, em vez de
  quebrar de novo.
- **FR-067**: Ao arrastar, o cartão MUST seguir o ponteiro 1:1. O encaixe desliza entre as posições com o mesmo tempo da FR-066.
- **FR-068**: Reduce motion MUST tirar todo o movimento. A contagem muda de número, e a barra anda de segundo em segundo.
- **FR-069**: Valem as regras do projeto: nenhum som de digitação, nem como opção; toda coluna cabe na área e rola por linhas inteiras, também na roda do mouse; a placa de teclas e o rodapé não
  cortam nada; o anel Loading_Circle é a única animação de espera; aparência fiel ao jogo, sem nenhum asset do jogo; linhas finas com `Tokens.vline`; textos em inglês, em `Strings.qml`.
- **FR-070**: Nenhuma ferramenta nova em `system/deps`.

### SYSTEM › Display: o que o catálogo e a check-019 perdem

| Onde | O que sai | Pra onde vai |
|---|---|---|
| Catálogo (`settings-default.json`) | 3 linhas `type: info`, `sys.display.*` | `DISPLAYS`, com escrita |
| `SysDisplay.qml` | `monitorText`, `isMonitorKey`, o timer de releitura, o `metaOf` com o nome da tela | O serviço da aba. Fica só a luz de tela. O timer vira a FR-052 |
| `Compositor.focusedMonitorInfo` | Perde o único uso. `refreshFocusedMonitor` fica: o `shell.qml` usa pra abrir os menus | O plano confere e tira |
| `019/block-reads.sh` | T032 (3 itens de `live`), US3.5, US3.6, R5, US3.7 e o fixture `monitors` | `check-018`: mesma comparação com `hyprctl`, o mesmo limite de 1 s, R5 incluído. US3.7 (seguir o foco) acaba de vez, com a D5 |
| `019/block-catalog.sh` | 3 `cat_cmp` e 3 itens em `rows` (de 15 pra 12), SC-001 | `check-018` |
| `019/block-adapter.sh` | 3 itens em `want`, que ganha `display.arrange` | Fica lá |
| `check-003` | Nada: usa o catálogo de teste (019 FR-008) | |
| `check-007` e quem conta abas | A lista de abas e os `Tab` contados (bloco `gallery`) | O plano ajusta |

### Key Entities

- **Tela**: o que está conectado. Identidade (descrição, ou porta), porta atual, modos, valores atuais.
- **Conjunto**: as identidades das telas conectadas. Tem um arranjo e uma principal.
- **Arranjo**: por tela, só o que a pessoa mudou pelo menu. Guardado em `$XDG_STATE_HOME/yorha-shell/`, com versão e backup.
- **Tentativa**: o arranjo depois do Apply, o estado de antes e o prazo. Só existe na memória do compositor.
- **Rascunho**: o que mudou na aba e não foi aplicado. Só existe no shell.
- **Base**: as regras que o arquivo pede, por seletor, na última leitura sem erro.

### O que o plano precisa provar antes (sondagens)

Rodadas na VM, sem o shell quando possível, no 0.56.2 e no 0.57, como a `prova-base` da 019.

| # | Pergunta | Se não der |
|---|---|---|
| S1 | A tabela `hl` deixa embrulhar `hl.monitor` e `hl.workspace_rule` durante a leitura da config, só pra anotar, repassando a chamada igual? Dá pra separar a leitura dos eventos depois dela? | S2 |
| S2 | Lendo `monitors all -j` logo depois do reload, antes de reaplicar, o valor é o que o arquivo pede? A 019 provou isso pra opções, não pra monitores, que podem aplicar depois | Volta pro dono (FR-033) |
| S3 | Reaplicar no `config.reloaded` causa uma troca de modo a mais? Dá pra evitar? | Volta pro dono (FR-039) |
| S4 | O `hl.timer` sobrevive a quê: morte do shell (deve), reload (provavelmente não), a tela sumir? O limite de 250 ms do `eval` deixa aplicar 3 telas? | Muda como armar, a garantia não |
| S5 | `desc:` casa por prefixo? O que uma saída `headless` informa? Duas `headless` têm a mesma descrição? | Testes por fixture, e dito no relatório |
| S6 | O Lua do compositor lê e grava arquivo (`io`, `os.rename`)? Consegue ler os erros de config sem o shell? | O plano escolhe outro caminho pra FR-036 |
| S7 | O menu sobrevive a mudar a escala, girar ou apagar a tela em que está, e continua com o teclado? | Muda o desenho da FR-020, com o dono |
| S8 | `hl.workspace_rule` em tempo de execução, mover o workspace 1, `cursor.default_monitor`, e ler o que o arquivo pede pra eles | A parte que falhar volta pro dono |
| S9 | Os campos de `monitors all -j` (desligada, `mirrorOf`), nas duas versões, e pra que lado fica o 90° | Só nomes |
| S10 | Como Forget volta ao arquivo sem deixar regra do produto: reload, ou reemitir a regra | O plano escolhe |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Todo valor da aba é igual ao do compositor em 100% das comparações da `check-018`, ou a linha está apagada com o motivo. **Evidência:** `results.txt`.
- **SC-002**: Sem resposta, com o shell normal, parado ou morto, as telas voltam em até 18 s depois do Apply, em 100% de pelo menos 20 rodadas por caso. **Evidência:** tempos em `results.txt`.
- **SC-003**: Depois de qualquer morte de sessão durante a contagem, o próximo login mostra o último arranjo mantido, e o arquivo de estado não mudou. **Evidência:** `sha256sum`, `monitors all -j`.
- **SC-004**: Em todos os cenários da User Story 4, um reload sem edição mantém o menu, e uma edição faz valer o arquivo. O `hyprland.lua` fica com o mesmo `sha256sum`. **Evidência:** `results.txt`.
- **SC-005**: Com o shell parado, cada conjunto restaura em até 3 s, em 100% de pelo menos 20 trocas. **Evidência:** tempos em `results.txt`.
- **SC-006**: Em nenhuma rodada da `check-018` o produto deixa todas as telas apagadas, ou duas telas sobrepostas. **Evidência:** um verificador lendo `monitors all -j` durante a rodada.
- **SC-007**: Depois de 30 s com um script que re-cola as telas, o produto não fez nenhum pedido além do Apply. **Evidência:** contagem na `check-018`.
- **SC-008**: A `check-018` e as 003, 004, 007, 008, 013, 014, 015 e 019 passam em 1080 e em 1,25, nas duas versões do Hyprland, com o log do QML sem WARN nem ERROR, cada rodada medida. **Evidência:** `results.txt`, log, resumo do `lab/perf`.
- **SC-009**: A lista de hardware desta spec fica com o dono, marcada item por item, e nenhum desses itens se diz pronto sem ele. **Evidência:** a lista na entrega, com a data da rodada (P1).
- **SC-010**: O dono vê o antes e o depois de cada estado da aba e de SYSTEM › Display, no Chrome dele, e aprova contra o protótipo. **Evidência:** screenshots do lab, a aprovação.

## Assumptions

- O include fica no topo do `hyprland.lua`, como o `yorha` manda.
- O dono troca o bloco que re-cola as telas do `monitors.lua` dele na migração, por decisão dele, e a aba passa a cuidar disso. Enquanto o bloco existir, a aba avisa (US7).
- Desinstalar ou tirar o include devolve as telas ao que o arquivo diz, no próximo login, porque nada foi escrito lá.
- A cópia de texto em inglês do protótipo vale até o plano ajustar. O texto da aba usa "screen" nas linhas, como o resto do SYSTEM.
- O Serpantinum antigo, sem licença na época, foi só olhado. Nada vem de lá (`PROPOSTA.md`, no lab privado).
- Os backends de Niri e Mango não entram na 0.1.0 (019). Eles vão precisar de um lado de lá próprio, e o Niri não tem scripts. É trabalho deles, depois.
- Nomes de arquivo, de chave e de função podem mudar no plano; os comportamentos e as evidências, não.

## Decisões do dono

- **D1.** Na 0.1.0, etapa 2, tudo real: "imagina ai o cara trocar resolução do monitor e não fazer nada".
- **D2.** Aba DISPLAYS depois de WINDOWS, layout B, cartões no papel. O nome era MONITORS até o dono trocar, em 06.11, olhando o protótipo. A pasta e a branch continuam `018-monitores`.
- **D3.** Por tela: resolução, taxa (escolha da pessoa), escala, rotação, posição, ligada ou não.
- **D4.** "só extender e espelhar... esquece isso de VRR não vamos fazer". Sem VRR, sem Flip. A rotação fica.
- **D5.** Nada muda até aplicar; 15 s de confirmação; sem confirmação, volta tudo sozinho, mesmo com o shell travado.
- **D6.** O valor do menu vale e volta depois de cada reload enquanto o arquivo não mudar. Editou: vale o arquivo, e o menu esquece. O produto nunca edita o `hyprland.lua`. A opção "Your config wins / This menu wins" não existe.
- **D7.** Emenda MINOR aprovada (2.3.0).
- **D8.** SYSTEM › Display: padrão do coordenador, que o dono pode mudar ao aprovar (P2).
- **D9.** A aba cola as telas de novo sozinha, confere se o arranjo ficou e avisa, sem adivinhar quem foi.
- **D10.** Perfis automáticos por conjunto, na 0.1.0, mesmo com o shell desligado, por modelo, cobrindo duas telas iguais.
- **D11.** Tela principal na 0.1.0, por perfil. Mesma regra da D6.
- **D12.** Tampa fora da 018, na etapa 3, com a regra citada na FR-043.
- **D13.** Visual e movimento aprovados na versão 1793967953-6226 do protótipo.
- **D14.** Regras do projeto: sem som de digitação, menus que cabem e rolam por linhas inteiras, anel único de espera, sem assets do jogo, "só mexer da primeira vez que é novo", tudo pelo adaptador, 0.56.2 e 0.57.
