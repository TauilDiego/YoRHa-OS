# Implementation Plan: Niri e Mango no laboratório (estudo de compositores)

**Branch**: `009-compositores` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/009-compositores/spec.md` (aprovada pelo dono em 2026-10-28,
com os pesos, a regra da recomendação e as três respostas da seção "Clarifications")

**Laboratório**: branch privada `lab-009` (`rien-OS-private-wt/lab-009`): a `lab-s2` com a `lab-004-acab`
(`eeccbc5`) e, depois, a `lab-s2` de novo com a `lab-sonda` (`d7bac80`).

## Decisões que valem pro plano

| # | Decisão (spec) | Efeito no plano |
|---|---|---|
| D1 | `arch-iso` pras três; a cadeia do Hyprland ao lado da atual (fase 0) | `hypr-iso` montada pela mesma `provision/hypr-base.sh`; promoção só com 15/0, 25/0, 58/0 (research R13) |
| D2 | AUR na VM, versão fixada | **Não é usado:** o Mango virou `mangowm` e está no repositório oficial (research A1, R2). O AUR (`mangowm-git`) fica como plano B, compilado na VM |
| D3 | Os 4 critérios de experiência; gestos só pela documentação | Evidência pra folha do dono: rajadas, screenshots, documentação; nenhuma nota do agente |
| D4 | O Hyprland no mesmo roteiro | Todas as amostras, medidas e rajadas também no Hyprland (`hypr-iso`) |
| C1 | `teste-a/b/c` recriadas só depois da promoção e só se livres (`lab/ls`, `pgrep -af qemu-system`, `.pid`) | Regra de "livre" no [data-model](data-model.md); passo próprio na ordem de execução |
| C2 | Só o dono dá as notas de experiência; a recomendação espera | Relatório em duas etapas ([contracts/relatorio.md](contracts/relatorio.md)) |
| C3 | Hyprland puro na nota oficial; plugins numa linha "com plugin" | As colunas já são do Hyprland puro (layout `scrolling` no núcleo desde a 0.54) e o plugin oficial de visão geral não existe mais (research A5, R3): a linha "com plugin" vira só visão geral, com uma cópia da comunidade do `hyprexpo` numa camada descartável `hypr-plugins`. **Pergunta 2** |
| — | lab-sonda: `lab/up` espera o SSH e sai 0 (`--no-wait` pra pular); o `perf.py` não sonda a porta; `ssh_vm` não cai na 2222 com a VM desligada; `wait_ssh N` conta segundos | O tempo "boot até a UI" é medido dentro da VM (research R10), não pelo `lab/up`; os scripts novos chamam `wait_ssh` em segundos; nenhum comando novo depende da 2222 |

## Achados da pesquisa que mudam o pedido

Detalhes no [research.md](research.md), "Achados que mudam o PRD, a spec ou o contrato da 007":
- **A1/A2, Mango:** virou **mangowm**, está no `extra` (0.18.3) e o IPC é outro: `mmsg get|watch|dispatch`,
  em JSON, pelo socket de `$MANGO_INSTANCE_SIGNATURE`, e o `dispatch … client,<id>` age em janela fora de
  foco. As hipóteses do §6 do contrato pro Mango estão desatualizadas.
- **A3, Niri:** o IPC não informa tela cheia; o resto do §6 do Niri se confirma pelo código da 26.04.
- **A4, os dois:** não rodam sem 3D (nem `--soft`, nem o fallback do `screendump`). O primeiro spike do
  estudo é o `egl-headless` com virgl nos dois.
- **A5, Hyprland:** colunas são nativas desde a 0.54; o plugin oficial de visão geral saiu.
- **A6, Hyprland 0.57.0** saiu hoje, com mudanças no Lua: fixar a data dos pacotes (pergunta 1).
- **A7, Quickshell:** sem módulo do Niri ou do Mango, mas com módulos genéricos (ext-workspace e
  foreign-toplevel) que os dois implementam: amostra extra pra S5.
- **R8, a UI da `main`:** fora do Hyprland, além das abas e do título vazios, o `Compositor.qml` perde a
  escala por monitor e o monitor em foco (vêm do `hyprctl`), então no hidpi as linhas finas podem sair
  desalinhadas e os pop-ups (`ALT+I`, `ALT+W`) podem não abrir; o log ganha o aviso
  `$HYPRLAND_INSTANCE_SIGNATURE is unset. Cannot connect to hyprland.` e um `Error making request` por
  pedido (lido no código do Quickshell; confirmado na VM).

## Summary

O estudo coloca o Niri e o Mango no laboratório, ao lado do Hyprland, todos sobre a `arch-iso`, roda a UI
da `main` nos três, coleta amostras pro contrato do adaptador, mede o custo e prepara a sessão manual do
dono. O resultado é o `docs/estudo-compositores.md`, em duas etapas (técnica agora; notas do dono e
recomendação depois).

A abordagem, em sete passos:
1. **Fase 0:** a cadeia `hypr-iso` (Hyprland sobre a `arch-iso`) é montada ao lado da `hypr-base`,
   passa nos três roteiros e só então vira a padrão; as `teste-*` são recriadas uma por vez, se livres.
2. **Camadas novas:** `niri-base` e `mango-base`, cada uma com uma preparação no molde da
   `hypr-base.sh`, um perfil de login, uma config mínima com os atalhos em ALT e uma **marca de
   compositor** no host (`vms/<base>.compositor`).
3. **Ferramentas:** o `lib.sh` ganha `compositor_of <vm>` (sobe a cadeia do `.base`; padrão
   `hyprland`) e o `GUEST_ENV` passa a exportar as variáveis de qualquer sessão. Só os comandos que
   falam com o compositor mudam (`profile`, `sync`, `click`, `cursor`, e o `up`, que recusa `--soft` no
   Niri e no Mango), cada um com um `case` por compositor; o ramo do Hyprland fica idêntico ([contracts/lab-compositor.md](contracts/lab-compositor.md)).
4. **A UI da `main`** em cada compositor, nos dois perfis, com o `ui.log` e a classificação dos itens.
5. **Amostras** das 10 linhas do §6 e das perguntas extras, num estado padrão da VM
   ([contracts/amostras.md](contracts/amostras.md)), e a proposta de `capabilities`.
6. **Medidas:** custo (3 rodadas, mediana) e rajadas das 4 animações em cada compositor; o Hyprland com
   plugin numa camada descartável.
7. **Sessão e relatório:** colinhas, folha de notas vazia, relatório etapa 1, resumão e Central.

## Technical Context

**Language/Version**: Bash (scripts do lab, `set -euo pipefail`, `source lib.sh`), como os que existem;
configs dos compositores (Lua do Hyprland 0.56, KDL do Niri, `config.conf` do Mango); QML só no spike
descartável do `Loader` (FR-022); Markdown/TSV/JSON pras amostras e o relatório.

**Primary Dependencies**:
- no host: nada novo. As mesmas ferramentas do lab (QEMU, `qemu-img`, `ssh`, `rsync`, `socat`, `jq`,
  `sha256sum`, ImageMagick do `lab/diffshot`, `python3` do `lab/perf`);
- na VM, todos do repositório oficial, numa data fixa do Arch Linux Archive (research R15, pergunta 1):
  Hyprland 0.56.2 + uwsm, `niri` 26.04, `mangowm` 0.18.3, `quickshell` 0.3.2, kitty, grim, wl-clipboard,
  `wlr-randr` (Mango), os módulos Qt 6 e as fontes da `hypr-base`. Nada do AUR.

**Storage**: `$LAB_HOME/vms/` (camadas e a marca `.compositor`), `$LAB_HOME/out/` (screenshots,
rajadas); no repositório privado, `lab/provision/{niri,mango}-base.sh`, `lab/guest/{niri,mango}/`,
`lab/009/` (amostras, tabelas, sessão); no público, só a spec e `docs/estudo-compositores.md`.

**Testing**: o roteiro do [quickstart.md](quickstart.md), dentro do `lab/perf`; os roteiros existentes
(`check-u1`, `check-003`, `check-004`) como regressão do Hyprland; `shellcheck` nos scripts novos e
mudados. Sem testes unitários (princípio VII).

**Target Platform**: o laboratório (QEMU/KVM, OVMF, virgl com `egl-headless` ou janela GTK) no host do
dono; o convidado é a `arch-iso` (archinstall: systemd-boot, btrfs, zram, NetworkManager).

**Project Type**: estudo com infraestrutura de teste (scripts do lab) e um documento.

**Performance Goals**: não há meta de produto; o estudo **mede** boot até a UI, RAM e CPU parado. Os
roteiros do Hyprland não podem ficar mais lentos do que hoje por causa das mudanças nas ferramentas.

**Constraints**:
- nada roda no host além das ferramentas do lab (constituição I); o plugin da comunidade compila na VM;
- Niri e Mango exigem 3D: só `--headless` (virgl + `egl-headless`) e `--window` (research A4);
- máximo 2 VMs do estudo e 4 no total, 2 núcleos e 4 GB cada;
- as bases congeladas que já existem não mudam (hash igual), e nenhuma VM de outro agente é desligada;
- o comportamento das ferramentas no Hyprland não muda (roteiros 15/0, 25/0, 58/0);
- o `shell/` não muda (a UI é a `main` `a3a9120`).

**Scale/Scope**: 2 preparações novas (`niri-base.sh`, `mango-base.sh`), 2 configs de compositor, 2
perfis de login; mudanças em `lib.sh`, `bootstrap`, `new`, `ls`, `profile`, `sync`, `click`, `cursor`,
`up` (só mensagem) e no README do lab; `guest/hyprland.lua` ganha `ALT+1…5`; a pasta `lab/009/`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Status |
|---|---|---|
| I. Sistema do dono intocável | Compositores, UI e o plugin do Hyprland (`hyprpm`) rodam e compilam só na VM. No host, só as ferramentas do lab. A sessão do dono é uma janela do QEMU (`--window`) | ✅ |
| II. Camada sobre Arch limpo | As três bases ficam sobre a `arch-iso` (Arch instalado pela ISO oficial, como um usuário). Nenhuma imagem própria | ✅ |
| III. Padrões × arquivos do usuário | Não se aplica ao produto (é o lab). No lab, as configs dos compositores são do lab (`lab/guest/`), e o `lab/sync` só escreve a config do compositor da própria VM | ✅ |
| IV. Pronto exige evidência da VM | Cada SC tem prova no [quickstart.md](quickstart.md): screenshots, amostras, `ui.log`, relatórios `lab/perf`, hashes das bases | ✅ |
| V. Spec antes de código | Spec aprovada em 2026-10-28; este plano espera a aprovação do dono antes do `/speckit-tasks` | ✅ |
| VI. Paralelizar | Os contratos (marca de compositor, `GUEST_ENV`, formato das amostras) vêm primeiro. Depois, o Niri e o Mango correm em paralelo (preparação, config, amostras), um agente e uma VM cada, dentro do limite de 2 VMs do estudo | ✅ |
| VII. Simplicidade | Sem abstração de "driver" no lab: uma função `compositor_of` e um `case` nos 4 comandos que falam com o compositor. Spikes descartáveis, sem backend no shell | ✅ |
| Restrições: marcas, segredos, licença | Nada do jogo; nenhum segredo; o plugin da comunidade só é compilado na VM descartável; nada de código de terceiros entra no repositório | ✅ |
| Fluxo: git | Spec e relatório no público (`009-compositores`); scripts e amostras no privado (`lab-009`); merges do dono | ✅ |

**Re-check pós-design (Fase 1):** sem violações. Duas notas:
- **A marca `.compositor` mora no host**, ao lado do `.base`, e não na VM: assim as ferramentas não
  precisam de um SSH a mais pra decidir, e a `hypr-base` antiga (sem marca) continua `hyprland` por
  padrão, sem mudar o disco congelado dela.
- **O `guest/hyprland.lua` ganha `ALT+1…5`.** O `lab/sync` leva esse arquivo pras `teste-*` dos outros
  agentes; é só acréscimo, e os três roteiros são rodados de novo pra provar que nada mudou.

## Project Structure

### Documentation (this feature)

```text
specs/009-compositores/
├── spec.md
├── plan.md              # este arquivo
├── research.md          # Fase 0: R1–R14
├── data-model.md        # Fase 1: camada/marca, compositor, amostra, capacidades, medidas, notas
├── quickstart.md        # Fase 1: roteiro de validação no lab
├── contracts/
│   ├── lab-compositor.md    # o lab por compositor: marca, GUEST_ENV, cada ferramenta, preparações, configs
│   ├── amostras.md          # formato das amostras, cenários S0–S3, índice
│   └── relatorio.md         # o documento em duas etapas, a colinha e a folha de notas
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks (depois da aprovação)
```

### Source Code (repositório privado, branch `lab-009`)

```text
rien-OS-private/lab/
├── lib.sh                    # + compositor_of; GUEST_ENV exporta NIRI_SOCKET e as variáveis da sessão
├── bootstrap                 # + arch-iso (pelo install-iso), hypr-iso, niri-base, mango-base; a antiga continua
├── new                       # base padrão: hypr-iso depois da promoção (até lá, hypr-base)
├── ls                        # + coluna COMPOSITOR
├── profile                   # case: hyprctl eval | niri msg output | wlr-randr
├── sync                      # leva só a config do compositor da VM; recarrega do jeito dele
├── click                     # tamanho lógico pelo compositor
├── cursor                    # setcursor só no Hyprland; nos outros, a config/variável de cursor
├── up                        # recusa --soft (e o fallback sem GPU) em camadas niri/mango; LAB_MAX_OUTPUTS só no spike
├── provision/
│   ├── hypr-base.sh          # + espelho na data fixa se LAB_ALA_DATE vier (sem ela, igual a hoje)
│   ├── niri-base.sh          # NOVO
│   └── mango-base.sh         # NOVO (pacote oficial mangowm)
├── guest/
│   ├── hyprland.lua          # + ALT+1…5 e um `local.lua` opcional (só a sessão do dono usa: colunas nas áreas 3–5)
│   ├── bash_profile          # Hyprland (sem mudança)
│   ├── niri/{config.kdl,bash_profile}     # NOVO
│   └── mango/{config.conf,bash_profile}   # NOVO
├── 009/                      # NOVO: bases.sha256, versoes/, ferramentas.tsv, ui/, amostras/, rajadas/,
│                             #       custo.tsv, capabilities.json, tabela-s6.md, sessao/, spikes/
└── README.md                 # árvore com hypr-iso/niri-base/mango-base, ferramentas por compositor, lições
```

O repositório público recebe só `docs/estudo-compositores.md` (e esta spec). O `shell/` não muda.

**Structure Decision**: o lab continua um conjunto de comandos pequenos com o `lib.sh` comum. O
compositor de cada VM é um dado da camada (como o `.base`), e os poucos comandos que dependem dele
escolhem com um `case`. Uma "camada de driver" por compositor seria abstração antes da hora (VII): são
quatro comandos e três ramos.

## Dependências entre specs

- **007 (contrato do adaptador):** este estudo **lê** o contrato (commit `fc561cd`) e devolve uma
  proposta de mudança no relatório; não edita a branch da 007. A frente B da 007 pode usar as amostras.
- **006 (`arch-iso`):** base das três cadeias; não muda.
- **S5 (Niri no produto):** depende deste estudo e da decisão do dono.
- **Agentes da 007 e da 008:** usam `teste-a/b/c` sobre a `hypr-base`; a promoção da `hypr-iso` não os
  afeta até a recriação, que só acontece com a camada livre (C1).

## Ordem de execução (pra o `/speckit-tasks`)

0. **Spike do 3D (1 VM, antes de tudo que é Niri/Mango):** numa camada descartável sobre a `arch-iso`,
   instalar `niri` e `mangowm` e conferir que os dois sobem com `--headless` (virgl + `egl-headless`) e
   com `--window`, que o `grim` captura e que o `qs` mostra uma janela de teste. Se o `egl-headless` não
   servir, o estudo para e pergunta ao dono (plano B do research R4). Também os pacotes na data fixa
   (pergunta 1).
1. **Retrato e contrato (sequencial, sem VM):** `lab/009/bases.sha256`; `compositor_of` e o `GUEST_ENV`
   novo no `lib.sh`; a coluna no `lab/ls`. A partir daqui, [contracts/](contracts/) congela.
2. **Fase 0 (sequencial, 1 VM):** `bootstrap` monta a `hypr-iso`; `teste-hiso` roda os três roteiros;
   promoção (README, `lab/new`, Central) só com 15/0, 25/0, 58/0.
3. **Em paralelo `[P]`, um agente e uma VM cada (2 VMs do estudo):**
   - **Niri:** `niri-base.sh`, `guest/niri/`, ramo `niri` em `profile`/`sync`/`click`/`cursor`, a tabela
     de ferramentas, a UI da `main`, as amostras;
   - **Mango:** o mesmo pro Mango (`mangowm` do `extra`), com atenção aos campos do JSON do `mmsg`, que
     não estão documentados.

   Os dois mexem em arquivos diferentes, menos o `case` dos 4 comandos: cada um acrescenta só o seu
   ramo; o merge é por bloco.
4. **Regressão do Hyprland (1 VM):** os três roteiros de novo, com as ferramentas mudadas e o
   `ALT+1…5`.
5. **Recriar as `teste-*` (sem VM):** uma por vez, só as livres; as ocupadas vão pro resumão.
6. **Medidas e spikes (sequencial, 1 VM por vez):** custo, 3 rodadas × 3 compositores; rajadas das 4
   ações nos três; o Hyprland com o `hyprexpo` da comunidade (`hypr-plugins`, descartável); a segunda
   saída de vídeo (R12); uwsm no Niri e no Mango (R5); a rota genérica do Quickshell (A7) e o `Loader`
   (R8).
7. **Sessão e relatório:** colinhas, folha de notas, relatório etapa 1, `tabela-s6.md`, resumão,
   Central; conferir `sha256sum -c` das bases. **Para aqui** e espera a folha do dono; a etapa 2 do
   relatório é uma tarefa à parte, depois.

## Tempo de VM estimado

Estimativa a partir dos tempos medidos (006: `install-iso` ~6 min; `hypr-base.sh` ~5–8 min com
download; os três roteiros ~10–15 min juntos, sessões 191921 e 194211 do `lab/perf`). Detalhe no
research R14.

| Bloco | VM·h | VMs juntas |
|---|---|---|
| Fase 0 (`hypr-iso` + 3 roteiros, uma repetição prevista) | 1,0 | 1 |
| Niri: camada, ferramentas, UI, amostras | 2,5 | 1 |
| Mango: camada, ferramentas, UI, amostras | 2,5 | 1 (em paralelo com o Niri) |
| Regressão do Hyprland | 0,5 | 1 |
| Custo (9 rodadas) e rajadas (12) | 2,0 | 1 |
| Spikes: 3D (primeiro), uwsm, rota genérica, `Loader`, `hypr-plugins`, duas saídas | 1,5 | 1 |
| **Total** | **≈ 10 VM·h** | **≈ 6–7 h de relógio** com o Niri e o Mango em paralelo |

Mais a sessão manual do dono (~30–45 min, 1 VM por vez, com `--window`).

## Riscos

| Risco | Efeito | Mitigação |
|---|---|---|
| Niri ou Mango não sobem com virgl + `egl-headless` (os dois exigem 3D; não há `--soft`) | Sem VM invisível pra eles | Spike 0 antes de tudo; plano B do research R4 (`rendernode` explícito, ou `--window` com o OK do dono); se nada servir, o estudo para e pergunta |
| `grim` falha num compositor | Sem screenshot | Os dois têm wlr-screencopy (R4); o fallback `screendump` não serve sem 3D, então a falha vira bloqueio e pergunta |
| O JSON do `mmsg` não traz tag, flutuante ou tela cheia | Células do §6 vazias | A amostra registra o que vem; o contorno é o `ToplevelManager`/ext-workspace (A7) ou o estado da tag pelo `get tags`; vira `nao-existe` com contorno |
| O Arch publica o Hyprland 0.57 no meio do estudo | Fase 0 compara outra versão; Lua quebra | Data fixa dos pacotes (R15, pergunta 1) |
| `uwsm` sem suporte num compositor | Partida diferente da do Hyprland | Partida recomendada pelo projeto; anotado; o "boot até a UI" é medido do mesmo ponto nos três (research R5, R10) |
| A UI entra em laço de reinício fora do Hyprland | Log enorme, CPU alta | O roteiro guarda as 3 primeiras partidas e para o `nier-ui-run` (quickstart, cenário 3) |
| Mudança nas ferramentas quebra os roteiros do Hyprland dos outros agentes | Regressão em 007/008 | Ramo `hyprland` idêntico ao código de hoje; regressão (passo 4) antes de juntar; as mudanças ficam na `lab-009` até o merge do dono |
| `ALT+1…5` colide com algum roteiro | Roteiro quebra | Os roteiros não usam `ALT+número` (conferido no `check-003`/`check-004`); a regressão prova |
| Recriar `teste-*` de outro agente no meio do trabalho dele | Perda de trabalho | Regra de "livre" (C1) conferida na hora; nunca `lab/rm` com processo vivo; pendente no resumão |
| Limite de VMs estourado pelos outros agentes | Estudo para | Conferir antes de cada `lab/up`; esperar; o paralelo Niri/Mango vira sequencial se faltar vaga |
| A cópia da comunidade do `hyprexpo` não compila na 0.56.2 | Linha "com plugin" vazia | Documentar a falha (é evidência de risco de manutenção) e citar a documentação como pesquisa |
| Um só mantenedor no Mango, lançamentos semanais com chaves renomeadas | Config do lab quebra no meio do estudo | Data fixa (R15); a quebra entra no risco de manutenção |

## Perguntas pro dono (antes do `/speckit-tasks`)

1. **Fixar a data dos pacotes nas três camadas?** (research R15) O Hyprland 0.57 saiu hoje com mudanças
   no Lua. **Recomendação:** sim, as três preparações e a regressão numa data fixa do Arch Linux Archive
   (2026/10/28: Hyprland 0.56.2, Niri 26.04, mangowm 0.18.3, Quickshell 0.3.2). A 0.57 fica pra uma
   tarefa à parte.
2. **O que vira a linha "com plugin" do Hyprland?** (research A5, R3) A resposta 3 falava em plugins
   oficiais de visão geral e de colunas, mas as colunas já são nativas (0.54) e o plugin oficial de visão
   geral saiu em 2026-05-12. **Recomendação:** a nota oficial do Hyprland puro inclui o layout de colunas
   nativo (a sessão do dono liga ele nas áreas 3–5); a linha "com plugin" fica só pra visão geral, com uma
   cópia da comunidade do `hyprexpo` numa camada descartável, marcada como "plugin da comunidade"; se não
   compilar na 0.56.2, a linha registra isso.
3. **Se o `egl-headless` não servir pro Niri ou pro Mango** (research R4), pode ligar a VM deles com
   `--window` (uma janela do QEMU no seu desktop) durante os testes? **Recomendação:** só se o spike 0
   falhar, e aí perguntar de novo com o resultado; até lá, não muda nada.

## Complexity Tracking

Sem violações da constituição.
