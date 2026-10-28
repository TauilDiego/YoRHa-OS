# Feature Specification: Niri e Mango no laboratório (estudo de compositores)

**Feature Branch**: `009-compositores` (sai da `main`, `a3a9120`; o laboratório fica na branch privada
`lab-009`, que é a `lab-s2` com a `lab-004-acab` juntada)

**Created**: 2026-10-28

**Status**: Rascunho, aguardando a aprovação do dono (constituição V). Três perguntas em aberto, no fim.

**Input**: O PRD do estudo 009 (`rien-OS-private/central/prd-009-compositores.md`, de 2026-10-28),
aprovado pelo dono como direção, com as respostas dele no §6. Resumo do pedido: colocar o **Niri** e o
**MangoWC (Mango)** no laboratório, ao lado do **Hyprland**, com a nossa UI rodando, e comparar os três
com números, pra o dono decidir entre ficar só no Hyprland, suportar mais de um ou trocar o padrão.

## Contexto

O rien-OS foi feito pro Hyprland. O dono gostou de dois outros compositores: o **Niri** (o que ele achou
mais parecido com o macOS, com colunas que rolam) e o **Mango** (que tem coisas interessantes). Antes de
decidir qualquer coisa, ele quer **usar os dois com a nossa UI**, sem tocar no sistema dele, e ter
números pra comparar com o Hyprland.

Em paralelo, a 007 propôs um **contrato de adaptador de compositor** (branch `007-menu-de-pausa`,
`specs/007-menu-de-pausa/contracts/compositor.md`, commit `fc561cd`). A tabela §6 dele tem as colunas do
Niri e do Mango como **hipóteses**, e o §1 deixa um risco em aberto: o que o `import Quickshell.Hyprland`
faz fora do Hyprland. Este estudo confirma ou corrige essas hipóteses com saídas reais.

Hoje o laboratório tem duas cadeias de camadas:

```
basic → arch-limpo → hypr-base → dev, teste-a/b/c, camadas de outros agentes
arch-iso (spec 006: Arch instalado pela ISO oficial com o archinstall) → teste-* da S3
```

Ao fim do estudo, a ideia é que os três compositores partam da mesma base, a mais próxima de uma
instalação real:

```
arch-iso
├── hypr-iso     Hyprland (a cadeia nova, que vira a padrão depois de passar nos roteiros)
│   ├── dev, teste-a/b/c (recriadas aqui só depois da promoção, ver US1)
├── niri-base    Niri
│   └── teste-niri
└── mango-base   Mango
    └── teste-mango
```

Esta fase é um **estudo**, não um produto: ela monta camadas e ferramentas no laboratório privado,
coleta amostras, mede e termina com um documento e uma recomendação. Os backends do Niri e do Mango no
shell são a S5, depois.

## Decisões do dono (2026-10-28, PRD §6)

1. **Base:** a `arch-iso` pras três: Niri, Mango **e o Hyprland**. Era a decisão pendente da 006
   ("trocar a base da `hypr-base` pela `arch-iso`"); vira a fase 0 deste estudo (US1).
2. **AUR:** pode instalar do AUR **na VM**, com a versão fixada no relatório.
3. **O que avaliar** (os quatro critérios de experiência):
   - a **visão geral das janelas** (o "Mission Control");
   - a **rolagem em colunas**;
   - as **animações** (abrir, fechar, trocar de área, mover);
   - os **atalhos e o jeito de usar** no dia a dia, incluindo a config e o custo de mantê-la.

   Os gestos de touchpad não passam pela VM: são avaliados pela documentação, e o relatório diz isso.
   Os pesos são propostos nesta spec, pro dono aprovar (seção "Critérios e pesos").
4. **O Hyprland entra na comparação** com o mesmo roteiro, já sobre a `arch-iso`.

## Critérios e pesos (proposta, pro dono aprovar)

A nota de cada critério vai de 0 a 3. A pontuação de um compositor é `Σ (peso × nota) / 3`, de 0 a 100.
O relatório mostra, ao lado, a mesma conta com pesos iguais, e os pesos e as notas ficam separados pra o
dono refazer a conta com outros números.

**Experiência (60):** os quatro critérios do dono.

| Critério | Peso | 0 | 1 | 2 | 3 |
|---|---|---|---|---|---|
| Visão geral das janelas | 15 | Não existe nem por plugin | Só por plugin ou script de terceiros | Nativa, mas limitada (sem escolher janela com o mouse, ou sem todas as áreas) | Nativa, mostra todas as janelas e áreas, escolhe com teclado e mouse |
| Rolagem em colunas | 15 | Não existe | Só por plugin, ou um layout que imita mal | Nativa, como um layout entre outros, com limitações anotadas | Nativa e central no modelo, com atalhos coerentes pra coluna e rolagem |
| Animações (abrir, fechar, trocar de área, mover) | 10 | Sem animação ou com falhas visíveis | Animam, mas com quadros quebrados ou poucas opções | Animam as quatro ações, configuráveis | As quatro, configuráveis por ação, sem falha visível nas rajadas |
| Atalhos e uso diário (inclui a config e o custo de mantê-la) | 20 | Os atalhos do lab não dão pra reproduzir | Reproduz, mas a config é frágil ou muda muito entre versões | Reproduz tudo, config legível, recarga ao vivo | Tudo isso e um jeito de usar que o dono aprova na sessão manual |

**Técnicos (40):**

| Critério | Peso | 0 | 1 | 2 | 3 |
|---|---|---|---|---|---|
| Cobertura do IPC × `capabilities` do contrato | 15 | Não lista áreas nem janelas | Lista, mas sem eventos ou sem agir em janela | Lista, tem eventos e age só na janela em foco (`actsOnAnyWindow = false`) | Lista, tem eventos e age em qualquer janela por id, com tela cheia e flutuante conhecidos |
| Risco de manutenção | 10 | Projeto parado ou de uma pessoa sem lançamentos | Lançamentos irregulares e quebras frequentes de config/IPC | Lançamentos regulares, quebras anunciadas | Lançamentos regulares, IPC estável e documentado, comunidade ativa |
| Custo medido (RAM e CPU parado, boot até a UI) | 10 | Mais que o dobro do Hyprland em algum número | Até 2× | Até 1,25× | Igual ou melhor que o Hyprland |
| Empacotamento | 5 | Só compilando à mão | Só AUR `-git` | AUR com versão | Repositório oficial do Arch |

**Critérios eliminatórios** (antes da conta; um compositor eliminado continua documentado):
- não aceitar a barra da UI (sem layer-shell, a UI não aparece);
- não ter como a UI listar áreas de trabalho e a janela em foco (IPC ou protocolo);
- não dar pra instalar de forma reproduzível na VM (nem pacote, nem receita do AUR que compile).

**Regra da recomendação (proposta):**
- **trocar o padrão:** só se o candidato passar o Hyprland por **10 pontos ou mais**, com nota ≥ 2 no
  IPC e no risco de manutenção;
- **Hyprland + um deles:** se o candidato ficar a **até 10 pontos** do Hyprland (ou acima), com nota
  ≥ 2 no IPC;
- **só Hyprland:** nos outros casos.

O relatório pode recomendar diferente da regra, mas tem que dizer por quê.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - O Hyprland sobre a `arch-iso`, sem derrubar ninguém (Priority: P1)

O agente monta uma cadeia nova do Hyprland em cima da `arch-iso` (por exemplo, `hypr-iso`), **ao lado**
da `hypr-base` atual, com a mesma preparação. Ela só vira a padrão (no `lab/new`, no `lab/bootstrap`, no
README do lab e na Central) depois de passar com os mesmos números da cadeia atual: `check-u1` 15/0,
`check-003` 25/0 e `check-004` 58/0. Depois da promoção, as camadas de teste são recriadas sobre ela,
uma de cada vez e só quando ninguém está usando. A cadeia antiga continua no disco até o dono dizer que
pode apagar.

**Why this priority**: Sem isso, o Hyprland é comparado sobre uma base diferente (a imagem de nuvem) da
dos outros dois, e a comparação de custo não vale. É também a decisão 1 do dono.

**Independent Test**: Criar a cadeia nova, uma camada de teste sobre ela, rodar os três roteiros dentro
de `lab/perf` e comparar com os números da cadeia antiga; conferir o hash das bases congeladas antes e
depois.

**Acceptance Scenarios**:

1. **Given** a `arch-iso` congelada e a `hypr-base` com camadas em cima, **When** a cadeia nova é
   montada, **Then** ela fica congelada com outro nome, e a `hypr-base`, a `arch-iso` e as camadas dos
   outros agentes continuam iguais (mesmo hash, mesma lista).
2. **Given** uma camada de teste sobre a cadeia nova, **When** os três roteiros rodam, **Then** o
   resultado é `check-u1` 15/0, `check-003` 25/0 e `check-004` 58/0, e só aí a cadeia nova vira a
   padrão.
3. **Given** a cadeia nova promovida, **When** uma camada `teste-*` vai ser recriada, **Then** antes a
   lista de camadas e a lista de VMs ligadas mostram que ela está livre; se estiver em uso, ela fica
   como está e entra no relatório como pendente.
4. **Given** um roteiro que falha na cadeia nova, **When** o agente investiga, **Then** a cadeia nova não
   é promovida, a antiga continua a padrão e a diferença fica registrada.

---

### User Story 2 - Niri e Mango em camadas próprias, com as ferramentas do lab (Priority: P1)

O agente cria a `niri-base` e a `mango-base` sobre a `arch-iso`, no mesmo molde da `hypr-base`: uma
preparação por camada, um passo no `lab/bootstrap`, congeladas. Cada uma entra direto no compositor no
login automático, sobe a UI de `~/nier/ui` sozinha e tem uma config mínima com os mesmos atalhos em ALT
do Hyprland do lab. Por cima delas, `teste-niri` e `teste-mango`. As ferramentas do lab (`up`,
`up --window`, `shot`, `ipc`, `profile`, `sync`, `key`, `click`, `burst`) funcionam nas três famílias,
escolhendo o jeito certo pelo compositor da VM, sem mudar nada no que já funciona no Hyprland.

**Why this priority**: É o que permite ver, medir e comparar. Sem screenshot e sem IPC na VM, nenhuma
outra parte do estudo tem evidência (constituição IV).

**Independent Test**: Rodar o `lab/bootstrap` num lab que já tem a `arch-iso`, criar `teste-niri`, ligar,
mandar a UI, tirar screenshot nos dois perfis, rodar um comando de IPC, apertar `ALT+Enter` e clicar;
repetir no Mango; rodar os três roteiros no Hyprland.

**Acceptance Scenarios**:

1. **Given** um lab com a `arch-iso` e sem as camadas novas, **When** o `lab/bootstrap` roda, **Then** ele
   cria a `niri-base` e a `mango-base` congeladas, e as camadas que já existiam não mudam (hash igual).
2. **Given** o `lab/bootstrap` já rodado, **When** ele roda de novo, **Then** não refaz nada.
3. **Given** `teste-niri` ligada, **When** a VM termina o boot, **Then** ela entra sozinha no Niri e a UI
   aparece sem nenhum comando manual; o mesmo vale pra `teste-mango`.
4. **Given** cada uma das três VMs, **When** se usa `ALT+Enter`, `ALT+Q`, `ALT+I`, `ALT+W` e `ALT+1…5`,
   **Then** abre o kitty, fecha a janela, abre as configurações, abre o seletor de papel de parede e
   troca de área, com screenshot de cada um.
5. **Given** cada VM, **When** se roda cada ferramenta do lab (incluindo `profile 1080` e
   `profile hidpi`), **Then** a tabela "ferramenta × compositor" fica preenchida com OK ou com a falha e
   o contorno; no Hyprland os três roteiros continuam 15/0, 25/0 e 58/0.

---

### User Story 3 - A UI da `main` rodando em cada compositor (Priority: P1)

O dono quer saber o que da UI atual (001, 003 e 004 completas) aparece e o que quebra fora do Hyprland,
**sem mudar o `shell/`**. O esperado é que a barra, o papel de parede, as configurações e o seletor
apareçam, e que as abas de área de trabalho e o título da janela fiquem vazios, porque o
`Compositor.qml` só fala com o Hyprland. O ponto que mais importa é registrar **exatamente** o que o
`import Quickshell.Hyprland` faz fora do Hyprland: erro, aviso ou silêncio.

**Why this priority**: Responde o risco do §1 do contrato, que decide se o adaptador precisa isolar o
import do Hyprland num arquivo carregado só no Hyprland. E mostra ao dono o tamanho do trabalho da S5.

**Independent Test**: Em `teste-niri`, mandar a UI da `main`, tirar os screenshots da barra, do
papel de parede, de `ALT+I` e de `ALT+W` em 1080 e hidpi, guardar o `~/nier/ui.log` e classificar cada
item.

**Acceptance Scenarios**:

1. **Given** a UI da `main` (`a3a9120`) sincronizada sem mudança, **When** a sessão do Niri sobe,
   **Then** existem screenshots da barra, do papel de parede, das configurações e do seletor, em 1080 e
   hidpi, e o `ui.log` completo daquela partida.
2. **Given** o `ui.log`, **When** se procura o que veio do `import Quickshell.Hyprland` e do
   `Compositor.qml`, **Then** o relatório cita as linhas exatas (ou diz "silêncio", com o log inteiro
   como prova) e diz se o resto da UI carregou.
3. **Given** cada item da UI (barra, abas, título, relógio, bateria, papel de parede, configurações,
   seletor, contraste da barra), **When** ele é olhado em cada compositor, **Then** ele fica
   classificado como "funciona", "parcial" ou "quebra", com o screenshot e a linha do log.
4. **Given** o mesmo no Mango, **Then** o mesmo resultado, por compositor.

---

### User Story 4 - Amostras pro contrato do adaptador (Priority: P2)

Pra cada linha da tabela §6 do contrato (monitores e escala, monitor em foco, áreas, janelas, janela
ativa e tela cheia, eventos, ir pra área, focar janela, mover/flutuar/fechar, modelo), o agente roda a
consulta ou a ação na VM de cada compositor e guarda a saída. Cada célula fica **confirmada**,
**corrigida** (com o comando certo) ou **não existe** (com o contorno, se houver). Sai também a proposta
das `capabilities` de cada compositor e a tabela §6 corrigida, como proposta de mudança pro dono.

**Why this priority**: É a entrada concreta da S5 e da frente B da 007. Vem depois da US2 porque
precisa das VMs e do IPC funcionando.

**Independent Test**: Numa VM só, rodar as consultas das dez linhas e conferir que cada uma tem um
arquivo de amostra e um estado na tabela.

**Acceptance Scenarios**:

1. **Given** `teste-niri` com duas janelas abertas em áreas diferentes, uma flutuante e uma em tela
   cheia, **When** as consultas rodam, **Then** cada linha tem a saída guardada, e as perguntas abertas
   do Niri estão respondidas: como saber se a janela está em tela cheia, se ela é flutuante, e que dados
   de coluna ou posição servem pro mapa da aba WINDOWS.
2. **Given** `teste-mango` no mesmo estado, **When** as consultas e ações rodam, **Then** as perguntas
   abertas do Mango estão respondidas: se dá pra agir numa janela que **não** está em foco (mover,
   fechar, focar por id), como obter a tag de cada janela e se existe um fluxo de eventos.
3. **Given** os dois, **When** a escala muda pro perfil hidpi, **Then** a amostra mostra a escala
   fracionária por monitor e qual monitor está em foco.
4. **Given** as amostras, **When** a tabela é preenchida, **Then** cada compositor tem uma proposta de
   `capabilities` (`workspaceModel`, `canFloat`, `canMoveToWorkspace`, `actsOnAnyWindow`, `hasGeometry`,
   `fullscreenKnown`) com a amostra que justifica cada valor, e a regra de detecção do §1 (variáveis de
   ambiente de cada sessão) está confirmada ou corrigida.

---

### User Story 5 - Uma sessão pro dono usar com as mãos (Priority: P2)

O dono liga cada compositor numa janela no desktop dele (`lab/up teste-niri --window`,
`lab/up teste-mango --window` e o Hyprland pra comparar) e usa por alguns minutos, com uma colinha curta
na mão: os atalhos de cada um em ALT, o que vale olhar pra cada um dos quatro critérios de experiência, e
o aviso de que os gestos de touchpad não passam pela VM.

**Why this priority**: Três dos quatro critérios do dono são de sensação, e a VM não serve pra julgar
fluidez (lab, "Limites"). Sem a sessão dele, essas notas ficam só do agente.

**Independent Test**: Com as camadas da US2 prontas, um comando liga cada sessão; a colinha cabe numa
tela e lista os atalhos que foram conferidos na US2.

**Acceptance Scenarios**:

1. **Given** as camadas prontas, **When** o dono roda o comando da colinha, **Then** a janela abre com o
   compositor, a UI e a resolução do perfil pedido, sem nenhum outro passo.
2. **Given** a colinha, **When** o dono a lê, **Then** ela tem, por compositor: como ligar e desligar, os
   atalhos em ALT (os do lab e os nativos que valem testar: visão geral, colunas, mover janela), o que
   olhar em cada critério e o aviso sobre os gestos.
3. **Given** as notas do dono depois da sessão, **When** elas chegam, **Then** o relatório as registra
   ao lado das do agente, e a conta é refeita com elas (ver a pergunta 2).

---

### User Story 6 - O relatório e a recomendação (Priority: P1)

O dono lê `docs/estudo-compositores.md` (público, em português): um resumo de uma página, a tabela
Hyprland × Niri × Mango, a conta com os pesos aprovados e com pesos iguais, os eliminados (e por quê) e a
recomendação: só Hyprland, Hyprland + um deles, ou trocar o padrão. Junto, a tabela §6 do contrato
corrigida, como proposta de mudança.

**Why this priority**: É o "pronto" do estudo; sem ele, nada é decidido. Depende das outras histórias.

**Independent Test**: Com os dados das US1–US5, conferir que toda célula da tabela aponta pra uma
evidência (amostra, screenshot, relatório `lab/perf`) ou pra uma fonte marcada como pesquisa, e que um
leitor refaz a conta com outros pesos só com o documento.

**Acceptance Scenarios**:

1. **Given** as medidas e as amostras, **When** o documento é escrito, **Then** ele cobre, por
   compositor: como instalar (repositório oficial ou AUR, versão), o IPC (o que lê, o que faz, eventos),
   o que a UI precisa × o que ele oferece (as `capabilities`), o custo medido, os riscos de manutenção,
   os quatro critérios de experiência, a conta e a recomendação.
2. **Given** uma afirmação que não foi medida na VM (gestos, cadência de lançamentos, planos do
   projeto), **When** ela entra no documento, **Then** traz a fonte e a marca "pesquisa".
3. **Given** o documento pronto, **When** o estudo termina, **Then** existe uma entrada no
   `central/resumao.md` com o resultado, os commits e as decisões pro dono, e a rien-OS Central lista os
   comandos e camadas novos.

### Edge Cases

- **Outro agente usando uma camada ou VM:** antes de recriar, apagar ou congelar qualquer coisa, o agente
  confere a lista de camadas e as VMs ligadas. Se houver uso, ele espera ou pula, e anota. Nunca
  derruba a VM de outro agente.
- **Limite de VMs:** no máximo 4 ligadas no total, somando as dos outros agentes, e no máximo 2 deste
  estudo ao mesmo tempo. Se já houver 4, o estudo espera.
- **Compositor sem captura de tela pelo protocolo que o lab usa:** o `lab/shot` cai num caminho
  alternativo (a captura do próprio compositor ou a da VM no modo sem 3D), e a tabela anota. Sem nenhum
  screenshot possível, a evidência daquele compositor é marcada como incompleta no relatório.
- **Compositor que não sobe com a aceleração 3D da VM, ou que exige outro modo de vídeo:** o estudo
  tenta o modo sem 3D, anota a diferença e mede os dois quando houver.
- **Compositor sem suporte ao uwsm:** ele sobe pelo jeito que o próprio projeto recomenda, e o relatório
  anota (pesa em "uso diário").
- **Pacote do AUR que não compila ou muda de versão no meio do estudo:** a versão usada fica fixada
  (versão e commit da receita); se uma versão nova sair, o estudo continua na fixada e anota a nova.
- **A UI travar ou entrar em laço de reinício fora do Hyprland:** o `nier-ui-run` reinicia o
  Quickshell a cada 2 s; o estudo guarda o log das primeiras partidas e para o laço pra não encher o
  disco nem o log.
- **Escala fracionária (hidpi, 1,25):** as manias conhecidas do Quickshell com escala fracionária
  (lições do lab) são conferidas em cada compositor; um desalinhamento novo é anotado com screenshot.
- **Um monitor só na VM:** as perguntas por monitor (escala de cada um, monitor em foco) pedem dois. O
  estudo tenta uma segunda saída virtual; se o lab não suportar com 3D, a resposta vem da documentação e
  é marcada como pesquisa.
- **Atalho em ALT que colide com um atalho nativo do compositor:** o atalho do lab ganha, e a colisão é
  anotada na colinha.
- **Gestos de touchpad:** não passam pela VM; avaliados só pela documentação.
- **Fluidez:** a VM não serve pra julgar fluidez (a imagem passa pelo virgl e por uma janela na mesma
  GPU). As rajadas de quadros medem se a animação existe e se quebra, não se é suave.

## Requirements *(mandatory)*

### Functional Requirements

**Fase 0: o Hyprland sobre a `arch-iso` (US1)**

- **FR-001**: O lab MUST ganhar uma cadeia do Hyprland sobre a `arch-iso` (nome sugerido `hypr-iso`),
  montada com a mesma preparação da `hypr-base`, ao lado da cadeia atual.
- **FR-002**: A `hypr-base` atual MUST NOT ser sobrescrita, renomeada nem refeita enquanto houver camadas
  em cima dela. O hash dos discos congelados (`basic`, `arch-limpo`, `hypr-base`, `arch-iso`) MUST ser o
  mesmo antes e depois do estudo.
- **FR-003**: A cadeia nova MUST só virar a padrão (base padrão do `lab/new`, o `lab/bootstrap`, o README
  do lab e a Central) depois que uma camada de teste sobre ela passar em `check-u1` 15/0, `check-003`
  25/0 e `check-004` 58/0, com os relatórios do `lab/perf` como prova.
- **FR-004**: Depois da promoção, as camadas `teste-*` MUST ser recriadas sobre a cadeia nova, uma de cada
  vez, e só depois de conferir que nenhum agente está usando cada uma (lista de camadas e VMs ligadas).
  Uma camada em uso fica como está e entra como pendente.
  [NEEDS CLARIFICATION: o PRD pede pra recriar as `teste-*` (§2, item 0), mas também diz que mexer nas
  `teste-a/b/c` está fora do escopo (§3), e a 007 e a 008 estão usando o lab agora. Recriar dentro do
  009 ou deixar pro dono?]
- **FR-005**: A cadeia antiga MUST continuar no disco até o OK explícito do dono; o estudo não a apaga.
- **FR-006**: O `lab/bootstrap` MUST montar, num lab vazio, a `arch-iso` (pelo comando da 006) e, sobre
  ela, a cadeia do Hyprland, a `niri-base` e a `mango-base`, pulando o que já existe.

**Camadas do Niri e do Mango (US2)**

- **FR-007**: O lab MUST ter as camadas `niri-base` e `mango-base` sobre a `arch-iso`, cada uma com uma
  preparação própria, um passo no `lab/bootstrap` e congeladas, no mesmo molde da `hypr-base`.
- **FR-008**: Cada camada MUST ter o compositor, o uwsm (se o compositor suportar; senão, anotado),
  Quickshell, kitty, a ferramenta de screenshot e a de área de transferência, rsync, jq, os mesmos módulos
  Qt 6 e as mesmas fontes da `hypr-base`, e o fuso do host.
- **FR-009**: Cada camada MUST entrar sozinha no compositor pelo login automático no tty1, com um perfil
  de login próprio por camada.
- **FR-010**: Cada camada MUST subir a UI de `~/nier/ui` pelo mesmo `nier-ui-run` da `hypr-base`, na
  partida do compositor.
- **FR-011**: Cada compositor MUST ter uma config mínima no lab, com os mesmos atalhos em ALT: `ALT+Enter`
  abre o kitty; `ALT+Q` fecha a janela; `ALT+I` abre as configurações; `ALT+W` abre o seletor de papel de
  parede; `ALT+1…5` troca de área de trabalho. A config do Hyprland do lab, que hoje não tem `ALT+1…5`,
  MUST ganhar esses atalhos (só acréscimo), pra os três terem o mesmo roteiro.
- **FR-012**: Pacotes que não estão no repositório oficial MAY vir do AUR, compilados **dentro da VM**,
  com a versão e o commit da receita fixados e registrados (decisão 2).
- **FR-013**: O lab MUST ter as camadas de teste `teste-niri` e `teste-mango`.
- **FR-014**: O estudo MUST registrar a versão de cada compositor, do Quickshell e do Qt em cada camada.

**Ferramentas do lab (US2)**

- **FR-015**: Onde uma ferramenta depende do Hyprland, ela MUST escolher o comportamento pelo compositor
  da VM, sem mudar o que faz no Hyprland. Vale pra: `lab/shot`, `lab/burst`, `lab/ipc` (as variáveis da
  sessão de cada compositor), `lab/profile 1080|hidpi` (resolução e escala), `lab/sync` (leva a config do
  compositor certo pras camadas `teste-*` e recarrega), `lab/click` (o tamanho lógico da tela) e
  `lab/up --window`.
- **FR-016**: `lab/key` e `lab/click` (que mandam teclas e cliques pela VM) MUST ser conferidos nos dois
  compositores novos.
- **FR-017**: O estudo MUST deixar uma tabela "ferramenta × compositor" com OK, falha e contorno, e a
  prova de cada célula.
- **FR-018**: Os roteiros `check-u1`, `check-003` e `check-004` MUST continuar 15/0, 25/0 e 58/0 no
  Hyprland depois das mudanças nas ferramentas. Nos compositores novos, eles MAY rodar como informação
  (o resultado entra no relatório, mas não é critério).

**A UI da `main` em cada compositor (US3)**

- **FR-019**: A UI usada MUST ser a da `main` em `a3a9120`, sem mudança. O `shell/` não muda neste estudo.
- **FR-020**: Em cada compositor, nos perfis 1080 e hidpi, o estudo MUST guardar screenshots da barra,
  do papel de parede, das configurações (`ALT+I`) e do seletor (`ALT+W`), o `~/nier/ui.log` da partida e a
  classificação de cada item ("funciona", "parcial", "quebra").
- **FR-021**: O estudo MUST registrar exatamente o que o `import Quickshell.Hyprland` faz fora do
  Hyprland (as linhas do log, ou "silêncio" com o log inteiro) e se o resto da UI carrega.
- **FR-022**: O estudo SHOULD responder também a dúvida do §1 do contrato: se um arquivo que importa
  `Quickshell.Hyprland` e **não é carregado** (por estar num `Loader` que escolhe outro) custa algo fora
  do Hyprland, com um spike descartável no lab.

**Amostras pro contrato (US4)**

- **FR-023**: Pra cada linha da tabela §6 do contrato, e pra cada compositor (o Hyprland como
  referência), o estudo MUST rodar a consulta ou a ação na VM e guardar a saída (JSON ou texto) em
  `lab/009/amostras/`, no repositório privado.
- **FR-024**: Cada célula das colunas do Niri e do Mango MUST terminar como "confirmada", "corrigida" (com
  o comando certo) ou "não existe" (com o contorno, se houver).
- **FR-025**: O estudo MUST responder, com amostra: no Mango, agir numa janela fora de foco (mover,
  fechar, focar por id), a tag de cada janela e o fluxo de eventos; no Niri, tela cheia, flutuante e os
  dados de coluna ou posição; nos dois, a escala fracionária por monitor, o monitor em foco e a variável
  de ambiente que identifica a sessão (regra de escolha do backend, §1 do contrato).
- **FR-026**: O estudo MUST propor, por compositor, os valores das `capabilities` do contrato, cada um
  ligado à amostra que o justifica.
- **FR-027**: Spikes descartáveis (um QML ou script que prova uma consulta) MAY existir, só no lab
  privado. Os backends de verdade (`NiriBackend.qml`, `MangoBackend.qml`) ficam fora (S5).
- **FR-028**: O estudo SHOULD tentar uma segunda saída de vídeo na VM pras perguntas por monitor; se não
  der, a resposta vem da documentação, marcada como pesquisa.

**Sessão do dono (US5)**

- **FR-029**: O lab MUST ligar cada compositor numa janela no desktop do dono com um comando, e uma
  colinha curta MUST listar, por compositor: como ligar e desligar, os atalhos em ALT, os atalhos
  nativos que valem testar (visão geral, colunas, mover janela), o que olhar em cada critério de
  experiência e que os gestos de touchpad não passam pela VM.
- **FR-030**: As notas do dono, quando vierem, MUST entrar no relatório ao lado das do agente, e a conta
  MUST ser refeita com elas.
  [NEEDS CLARIFICATION: nos quatro critérios de experiência, valem as notas do agente, as do dono depois
  da sessão manual, ou as duas? E a recomendação final espera essa sessão?]

**Medição (todas)**

- **FR-031**: Todo teste MUST rodar dentro de uma sessão `lab/perf` (`--kind 009 --task 009/T…`), e cada
  relato MUST citar o resumo do relatório.
- **FR-032**: O custo MUST ser medido do mesmo jeito nos três: RAM e CPU da VM parada com a UI no ar, e o
  tempo do boot até a UI aparecer, no mesmo perfil, com a mesma UI e a mesma VM (2 núcleos, 4 GB), três
  vezes cada, usando a mediana.
- **FR-033**: As animações MUST ser registradas com rajadas de quadros das quatro ações (abrir, fechar,
  trocar de área, mover) em cada compositor; a nota diz se a animação existe e se quebra, não se é suave.
- **FR-034**: No máximo 2 VMs deste estudo MUST estar ligadas ao mesmo tempo, nunca mais de 4 no total,
  cada uma com 2 núcleos e 4 GB, e todo comando com mais de uma VM ligada MUST dizer qual VM usa.

**Relatório e decisão (US6)**

- **FR-035**: Os critérios, os pesos, as âncoras das notas e a regra da recomendação MUST ser os
  aprovados pelo dono nesta spec, fixados antes da primeira medida.
- **FR-036**: `docs/estudo-compositores.md` MUST trazer: resumo de uma página; a tabela Hyprland × Niri ×
  Mango com instalação (repositório ou AUR, versão), IPC (leitura, ações, eventos), `capabilities`, custo
  medido, riscos de manutenção e os quatro critérios de experiência; a conta com os pesos aprovados e com
  pesos iguais; os eliminados; e a recomendação.
- **FR-037**: Toda célula da tabela MUST apontar pra uma evidência (amostra, screenshot, relatório) ou pra
  uma fonte marcada como "pesquisa". Os gestos de touchpad entram só como pesquisa.
- **FR-038**: A visão geral e a rolagem em colunas do Hyprland MUST ser avaliadas
  [NEEDS CLARIFICATION: só com o que vem no Hyprland, ou também com os plugins oficiais (por exemplo, o
  de visão geral e o de colunas)? Muda bastante as notas dele nesses dois critérios.]
- **FR-039**: O relatório MUST trazer a tabela §6 do contrato corrigida como **proposta de mudança**; o
  estudo não edita a branch da 007.
- **FR-040**: O estudo MUST deixar uma entrada no `central/resumao.md` (resultado, commits, decisões pro
  dono) e atualizar a rien-OS Central com os comandos e as camadas novas.

**Isolamento**

- **FR-041**: Nada roda no sistema do dono além das ferramentas aceitas do lab (constituição I). A
  compilação de pacotes do AUR, os compositores e a UI rodam só dentro da VM.
- **FR-042**: O documento público MUST NOT trazer dados pessoais, caminhos do host do dono nem segredos;
  as amostras e o lab ficam no repositório privado.

### Key Entities

- **Cadeia de camadas**: uma base congelada e as camadas por cima dela (`arch-iso` → `hypr-iso`,
  `niri-base`, `mango-base` → `teste-*`), com o hash de cada base e quem a usa.
- **Compositor sob estudo**: Hyprland, Niri ou Mango, com a versão, de onde vem (repositório oficial ou
  AUR, com o commit da receita), como sobe (uwsm ou não) e a config mínima do lab.
- **Ferramenta do lab**: um comando `lab/*`, com o resultado em cada compositor (OK, falha, contorno).
- **Item da UI**: barra, abas, título, relógio, bateria, papel de parede, configurações, seletor,
  contraste; com a classificação por compositor, o screenshot e a linha do log.
- **Amostra**: a saída de uma consulta ou ação de uma linha do §6 do contrato, num compositor, com o
  comando, a data e o estado da VM (janelas abertas, perfil).
- **Capacidades**: os seis valores do §3 do contrato, por compositor, cada um ligado a amostras.
- **Critério**: nome, peso, âncoras 0–3, se é eliminatório; com as notas do agente e, depois, as do dono.
- **Medida de custo**: compositor, rodada (1–3), RAM e CPU parado, tempo até a UI, id do relatório
  `lab/perf`.
- **Colinha**: o texto curto da sessão manual, por compositor.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A cadeia do Hyprland sobre a `arch-iso` passa em `check-u1` 15/0, `check-003` 25/0 e
  `check-004` 58/0 (os mesmos números da cadeia antiga), e só depois disso vira a padrão.
- **SC-002**: O hash das bases congeladas que já existiam (`basic`, `arch-limpo`, `hypr-base`,
  `arch-iso`) é o mesmo antes e depois do estudo, e 100% das camadas dos outros agentes continuam na
  lista; nenhuma VM de outro agente foi desligada pelo estudo.
- **SC-003**: Num lab que já tem a `arch-iso`, um comando cria a `niri-base` e a `mango-base` sem nenhuma
  tecla apertada; rodar de novo não muda nada.
- **SC-004**: Nas três famílias, as 10 ferramentas (`up`, `up --window`, `shot`, `burst`, `ipc`,
  `profile 1080`, `profile hidpi`, `sync`, `key`, `click`) têm resultado registrado com prova: 100% das
  células da tabela preenchidas.
- **SC-005**: Os 5 atalhos em ALT funcionam nos três compositores, com um screenshot por atalho.
- **SC-006**: Existem os 16 screenshots da UI da `main` (4 telas × 2 perfis × Niri e Mango), com o
  `ui.log` de cada partida, e 100% dos itens da UI classificados por compositor.
- **SC-007**: O efeito do `import Quickshell.Hyprland` fora do Hyprland está descrito com as linhas
  exatas do log (ou com o log inteiro provando o silêncio) nos dois compositores.
- **SC-008**: 100% das células das colunas do Niri e do Mango na tabela §6 (10 linhas × 2) têm amostra e
  estado; as perguntas abertas do PRD (3 do Mango, 3 do Niri, 2 dos dois) têm resposta com amostra ou,
  só as de monitor, com fonte marcada como pesquisa.
- **SC-009**: O custo tem 3 rodadas por compositor, com a mediana e a maior diferença entre rodadas, nos
  três compositores, medidas do mesmo jeito.
- **SC-010**: O dono liga cada sessão manual com **um** comando, e a colinha de cada compositor cabe numa
  tela (até 30 linhas).
- **SC-011**: No documento, 100% das células da tabela apontam pra uma evidência ou pra uma fonte marcada
  como pesquisa, e um leitor refaz a conta com outros pesos usando só o documento.
- **SC-012**: Os relatórios do `lab/perf` mostram, no sistema do dono, só as ferramentas do lab; nenhum
  compositor, Quickshell ou compilação de pacote. Nunca houve mais de 2 VMs do estudo nem mais de 4 no
  total ligadas ao mesmo tempo.
- **SC-013**: O dono recebe uma recomendação (só Hyprland, Hyprland + um, ou trocar o padrão) que segue
  da conta ou explica por que não, a tabela §6 corrigida, a entrada no resumão e a Central atualizada.

## Assumptions

- **De onde vem cada compositor (hipótese, o estudo confirma):** o Hyprland e o Niri estão no
  repositório oficial do Arch; o Mango vem do AUR (decisão 2). A versão de cada um fica fixada no
  relatório.
- **A base é a `arch-iso` da 006**, como está congelada. O estudo monta por cima e não a muda.
- **O nome `hypr-iso`** é sugestão do PRD; o plano pode escolher outro, desde que não reaproveite
  `hypr-base`.
- **A preparação do Hyprland roda sem mudança sobre a `arch-iso`** (a 006 provou isso no SC-005 dela). O
  acréscimo de `ALT+1…5` na config do Hyprland do lab é só acréscimo e não colide com os roteiros, que
  são conferidos depois (FR-018).
- **A UI é a da `main` (`a3a9120`)**, não a da 007: o adaptador do contrato ainda não existe. O estudo
  mostra o que a UI de hoje faz fora do Hyprland.
- **O lab escolhe o comportamento pelo compositor da VM** a partir da camada (ou de uma marca gravada nela
  na preparação); como, fica pro plano.
- **Animações e fluidez:** a VM mostra se a animação existe e se quebra (rajadas de quadros); a sensação
  de fluidez fica pra sessão do dono e, de verdade, pra máquina real. Por isso as animações pesam 10, e
  não 15.
- **Gestos de touchpad:** só pela documentação (decisão 3).
- **Monitores:** a VM tem uma saída; a segunda é uma tentativa (FR-028).
- **O que é público e o que é privado:** a spec e o `docs/estudo-compositores.md` vão pro repositório
  público; as preparações, as configs dos compositores, as ferramentas, as amostras, os spikes e a colinha
  ficam no repositório privado do lab (branch `lab-009`).
- **Fora do escopo:** os backends do Niri e do Mango no shell (S5); o gerador de atalhos e regras de
  janela (`config.kdl`, a config do Mango); mudar a `arch-iso` ou a `hypr-base` atual; qualquer coisa no
  sistema do dono; avaliar fluidez de verdade.
- **Recursos:** no máximo 2 VMs deste estudo ligadas, cada uma com 2 núcleos e 4 GB (memória
  `feedback-vm-limits` e PRD §4).

## Perguntas pro dono

As três perguntas marcadas na spec (FR-004, FR-030 e FR-038), com a recomendação do agente:

1. **Recriar as `teste-a/b/c` dentro do 009?** (FR-004) O PRD manda recriar as `teste-*` sobre a cadeia
   nova (§2, item 0), mas lista "mexer nas `teste-a/b/c`" como fora do escopo (§3), e a 007 e a 008 estão
   usando o lab. **Recomendação:** recriar dentro do 009, só depois da promoção, uma de cada vez e só
   quando a camada estiver livre (lista de camadas e VMs ligadas); o que estiver em uso fica pendente no
   resumão, pro dono liberar.
2. **Quem dá as notas dos critérios de experiência, e a recomendação espera a sessão do dono?** (US5,
   FR-030) **Recomendação:** o agente dá notas provisórias com a evidência (rajadas, amostras,
   documentação) e entrega o relatório com a recomendação marcada "provisória"; as notas do dono, depois
   da sessão manual, substituem as do agente nos quatro critérios de experiência, e a recomendação final
   sai com elas.
3. **O Hyprland é avaliado com plugins oficiais?** (FR-038) Nativamente, ele não tem visão geral nem é
   centrado em colunas como o Niri; com os plugins oficiais, tem. **Recomendação:** a nota oficial é só
   com o que vem no Hyprland; os plugins oficiais entram numa camada de teste descartável e aparecem numa
   linha à parte ("com plugin"), com o custo de manter plugin no risco de manutenção.
