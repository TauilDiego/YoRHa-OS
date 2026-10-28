---
description: "Tarefas do estudo 009: Niri e Mango no laboratório, ao lado do Hyprland"
---

# Tasks: Niri e Mango no laboratório (estudo de compositores)

**Input**: `specs/009-compositores/` (spec.md, plan.md, research.md, data-model.md, contracts/,
quickstart.md), com a spec e o plano aprovados pelo dono em 2026-10-28 (spec, "Clarifications"; plano,
"Decisões do dono sobre o plano").

**Tests**: a spec não pede testes automatizados. A prova de cada tarefa é a evidência da VM (princípio IV):
screenshots, amostras, `ui.log`, saídas de comando e relatórios `lab/perf`, sempre dentro de
`lab/perf begin "009: …" --kind 009 --task 009/<T>` … `lab/perf end --result …`, com `NIER_LAB_VM`
exportado. `shellcheck` nos scripts novos e mudados.

**Caminhos**:
- `specs/009-compositores/…` e `docs/estudo-compositores.md` = repositório público `nier-os` (branch
  `009-compositores`, worktree `nier-os-wt/spec009`);
- `lab/…` = repositório privado `rien-OS-private` (branch `lab-009`, worktree
  `rien-OS-private-wt/lab-009`). Todo o código do lab e as amostras ficam lá.

**Recursos e regras de execução** (plano, "Decisões do dono sobre o plano"):
- **2026-10-28 (dono):** as VMs passam a usar **4 núcleos** (`NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`); o custo
  (T042) é medido com 4 núcleos nos três compositores, e o relatório registra isso;
- no máximo **2 VMs deste estudo** ao mesmo tempo e **4 no total** (a 007 usa `teste-a`, a 008 usa
  `teste-b`); antes de cada `lab/up`, contar as VMs ligadas pelos `.pid`; com 4, esperar;
- `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G` (até 2026-10-28 17h, 2 núcleos); `NIER_LAB_VM=<vm>` em todo comando;
- sem subagentes: as partes do Niri e do Mango são feitas pelo mesmo agente (as tarefas `[P]` podem rodar
  em duas VMs ao mesmo tempo, ou em sequência);
- pacotes na data fixa `LAB_ALA_DATE=2026/10/28` (P1);
- nunca tocar `teste-a`/`teste-b` ligadas nem branches de outros agentes; promoção da `hypr-iso` só na
  `lab-009`.

**Pausa (2026-10-28 ~17:07, dono offline):** estado em `lab/009/estado-pausa.md` (branch `lab-009`). Em
andamento: T012 (`check-004` interrompido em 35/0; refazer), T022 (feito no Niri; falta o Mango), T025
(Niri feito), T028 e T035 (Niri feitos), T032 (amostras coletadas, falta o índice). Retomar pelo T012.

**Paradas obrigatórias:** (a) spike 0 falhando (T003); (b) qualquer decisão do dono; (c) fim da Phase 8
(relatório etapa 1 e folha de notas prontos, T046).

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: história da spec (US1–US6)

---

## Phase 1: Setup (retrato, pastas e spike do 3D)

**Purpose**: fixar o estado inicial do lab e provar que o Niri e o Mango sobem na VM invisível com 3D
antes de escrever qualquer coisa pra eles (research A4, R4).

- [x] T001 Criar `lab/009/` (subpastas `versoes/`, `ui/`, `amostras/`, `rajadas/`, `sessao/`, `spikes/`) e o retrato `lab/009/bases.sha256` (`sha256sum` de `basic`, `arch-limpo`, `hypr-base` e `arch-iso` em `$LAB_HOME/vms/`, resolvendo os links), mais `lab/009/inicio.txt` com `lab/ls` e as VMs ligadas no começo; commit na `lab-009` (SC-002) — **feito:** retrato em `lab/009/bases.sha256`
- [x] T002 Conferir o espelho do Arch Linux Archive de 2026/10/28 (`https://archive.archlinux.org/repos/2026/10/28/`) e as versões que ele dá pros pacotes do estudo (`hyprland`, `niri`, `mangowm`, `quickshell`, `qt6-base`, `mesa`, `wlr-randr`, `grim`), lendo os bancos `extra.db`/`core.db` no host só com `curl` + `tar` (sem pacman no host); guardar em `lab/009/versoes/ala-2026-10-28.txt` (P1, research R15) — **feito:** `lab/009/versoes/ala-2026-10-28.txt` (Hyprland 0.56.2-4, niri 26.04-1, mangowm 0.18.3-1, quickshell 0.3.2-1)
- [x] T003 **Spike 0 (3D), `lab/perf --task 009/T003`:** camada descartável `spike-3d` sobre a `arch-iso`; com `--soft` (sem sessão) apontar o pacman pro espelho de 2026/10/28, `pacman -Syu` e instalar `niri mangowm quickshell kitty grim wlr-randr jq`; login automático no tty1 com `bash_profile` provisório (`exec niri-session`); religar com `--headless` (virgl + `egl-headless`) e conferir: o Niri sobe, `grim` captura (`lab/shot`), `niri msg --json outputs` responde pelo `lab/ipc`; trocar pro `exec mango` e conferir o mesmo com `mmsg get all-monitors` e `wlr-randr --json`; anotar como achar o `MANGO_INSTANCE_SIGNATURE` (formato, `systemctl --user show-environment`, `/proc/<pid>/environ`), o `NIRI_SOCKET`, o `XDG_CURRENT_DESKTOP` e as versões; apagar a camada. Resultado em `lab/009/spikes/3d.md`. **Se o Niri ou o Mango não subirem com `--headless`, PARAR e relatar (P3)** — **feito:** **passou**: os dois sobem com `--headless`, `grim` e IPC ok (`lab/perf` 2026-10-28T164121; `lab/009/spikes/3d.md`); achado: laço do `niri-session` no `bash_profile`, corrigido com guarda

**Checkpoint**: os dois sobem com 3D invisível, ou o estudo parou pra o dono decidir.

---

## Phase 2: Foundational (o lab sabe o compositor)

**Purpose**: o contrato do lab ([contracts/lab-compositor.md](contracts/lab-compositor.md)) §1, §2 e §3
(`up`). **Depois do T006, os contratos ficam congelados**; uma divergência achada depois corrige o
contrato antes do código.

- [x] T004 `lab/lib.sh`: `compositor_of <vm>` (`NIER_LAB_COMPOSITOR` → `vms/<vm>.compositor` → sobe o `.base` → `hyprland`); `GUEST_ENV` acrescenta `NIRI_SOCKET` e `MANGO_INSTANCE_SIGNATURE` só quando existem (forma achada no T003), sem mudar as variáveis de hoje; conferir com `bash -n`, `shellcheck` e, numa VM do Hyprland já ligada pelo estudo (não `teste-a`/`teste-b`), que o `GUEST_ENV` gera o mesmo ambiente de antes (contrato §1–§2) — **feito:** `GUEST_ENV` idêntico no Hyprland (diff do `env` na `teste-hiso`)
- [x] T005 [P] `lab/ls`: coluna `COMPOSITOR` (de `compositor_of`), sem mudar as outras colunas (contrato §1) — **feito:** coluna COMPOSITOR
- [x] T006 [P] `lab/up`: com `compositor_of` `niri` ou `mango`, recusar `--soft` e o fallback "sem GPU" do `--headless` com `"o <compositor> exige 3D"` (código 1); Hyprland sem mudança (comparar a linha do QEMU gerada antes e depois com um QEMU falso, como no T004 da 006) (contrato §3, research A4). **Congela os contratos** — **feito:** `--soft` recusado na `teste-niri`

**Checkpoint**: as ferramentas sabem o compositor de cada VM; nada mudou pro Hyprland.

---

## Phase 3: User Story 1 - O Hyprland sobre a `arch-iso`, sem derrubar ninguém (Priority: P1) 🎯 MVP

**Goal**: a cadeia `hypr-iso` montada ao lado da `hypr-base`, com os mesmos números nos três roteiros, e
promovida dentro da `lab-009`.

**Independent Test**: `teste-hiso` sobre a `hypr-iso` passa em `check-u1` 15/0, `check-003` 25/0 (1080 e
hidpi) e `check-004` 58/0; `sha256sum -c lab/009/bases.sha256` dá OK.

- [x] T007 [US1] `lab/guest/hyprland.lua`: acrescentar `ALT+1…5` (área N) e, no fim, um `dofile` protegido de `~/.config/hypr/local.lua` (só se existir); nenhuma outra linha muda (FR-011, P2, contrato §5) — **feito**
- [x] T008 [US1] `lab/provision/hypr-base.sh`: com `LAB_ALA_DATE`, apontar o `/etc/pacman.d/mirrorlist` pro espelho daquela data antes do `pacman -Sy`; sem a variável, exatamente como hoje; gravar `~/.config/nier-lab/compositor` e imprimir as versões (contrato §4) — **feito**
- [x] T009 [US1] `lab/guest/nier-ui-run`: uma linha que grava a hora do início do `qs` e o `/proc/uptime` em `~/nier/ui.start` (igual nos três; research R10); conferir que o resto não muda — **feito**
- [x] T010 [US1] `lab/bootstrap`: passos `arch-iso` (pelo `lab/install-iso`, se faltar), `hypr-iso` (`new --from arch-iso`, cópia por `tar`, `LAB_TZ` + `LAB_ALA_DATE=2026/10/28`, `hypr-base.sh`, `down`, `freeze`, marca `hyprland`), sem tocar nos passos de hoje; conferir que não refaz o que existe (contrato §6) — **feito**
- [x] T011 [US1] Montar a `hypr-iso` pelo `lab/bootstrap` (`lab/perf --task 009/T011`); `lab/009/versoes/hyprland.txt`; `lab/ls` mostra a camada congelada com base `arch-iso` e compositor `hyprland` — **feito:** `hypr-iso` congelada (`lab/perf` 2026-10-28T165024)
- [ ] T012 [US1] `teste-hiso` sobre a `hypr-iso` com `NIER_LAB_PROFILE=hidpi`, `lab/sync` da `main` (`a3a9120`), `check-u1`, `check-003` (1080 e hidpi) e `check-004` (`lab/perf --task 009/T012`); guardar os resumos em `lab/009/fase0.md`. **Só com 15/0, 25/0 e 58/0** segue pro T013; com FAIL, registrar a diferença, não promover e relatar
- [ ] T013 [US1] Promoção na `lab-009`: base padrão do `lab/new` = `hypr-iso`; o `dev` de um lab vazio nasce da `hypr-iso`; README do lab (árvore de camadas); a `hypr-base` continua no `bootstrap` e no disco (FR-003, FR-005)

**Checkpoint**: a `hypr-iso` é a padrão na `lab-009`; a recriação das `teste-*` fica pro T045 (depois da regressão).

---

## Phase 4: User Story 2 - Niri e Mango em camadas próprias, com as ferramentas do lab (Priority: P1)

**Goal**: `niri-base` e `mango-base` sobre a `arch-iso`, as ferramentas funcionando nos três, e a tabela
ferramenta × compositor.

**Independent Test**: `lab/bootstrap` cria as duas bases; em `teste-niri` e `teste-mango` as 10
ferramentas e os 5 atalhos em ALT têm prova; o Hyprland continua 15/0, 25/0, 58/0.

- [x] T014 [P] [US2] `lab/guest/niri/config.kdl` (atalhos do lab e nativos em ALT, `spawn-at-startup` do `nier-ui-run`, sem cantos arredondados, animações padrão, `cursor`) e `lab/guest/niri/bash_profile` (`exec niri-session` no tty1); validar com `niri validate` na VM do T016 (contrato §5) — **feito:** `niri validate`: config válida
- [x] T015 [P] [US2] `lab/guest/mango/config.conf` (atalhos do lab e nativos em ALT, `exec_once` do `nier-ui-run`, sem blur, animações padrão, cursor) e `lab/guest/mango/bash_profile` (`exec mango`); validar com `mango -c … -p` na VM do T017 (contrato §5) — **feito**
- [x] T016 [P] [US2] `lab/provision/niri-base.sh` (contrato §4: data fixa, comuns, `niri`, login automático, config, `nier-ui-run`, fuso, versões) e o passo `niri-base` no `lab/bootstrap` (marca `niri`) — **feito**
- [x] T017 [P] [US2] `lab/provision/mango-base.sh` (contrato §4: data fixa, comuns, `mangowm wlr-randr`, login automático, config, `nier-ui-run`, fuso, versões) e o passo `mango-base` no `lab/bootstrap` (marca `mango`) — **feito**
- [x] T018 [US2] Rodar o `lab/bootstrap` (`lab/perf --task 009/T018`): cria a `niri-base` e a `mango-base` (até 2 VMs ao mesmo tempo); rodar de novo e conferir que não faz nada (SC-003); `lab/009/versoes/{niri,mango}.txt` — **feito:** `niri-base` e `mango-base` congeladas (`lab/perf` 165035 e 165046); segunda passada não fez nada
- [ ] T019 [P] [US2] `lab/profile`: `case` por compositor — Niri: `niri msg output <saída> mode …` + `scale …`, leitura de `niri msg --json outputs`; Mango: `wlr-randr --output … --mode … --scale …`, leitura de `wlr-randr --json`; Hyprland igual (contrato §3)
- [ ] T020 [P] [US2] `lab/sync`: escreve só a config do compositor da VM (`hyprland.lua` / `niri/config.kdl` / `mango/config.conf`) e recarrega e reinicia o `nier-ui-run` do jeito de cada um; Hyprland igual (contrato §3)
- [ ] T021 [P] [US2] `lab/click` (tamanho lógico por compositor) e `lab/cursor` (Hyprland: `setcursor`; Niri e Mango: tema instalado + a opção da config) (contrato §3)
- [ ] T022 [US2] Tabela ferramenta × compositor (`lab/perf --task 009/T022`), em `teste-niri` e `teste-mango` (2 VMs): `up`, `shot`, `burst`, `ipc`, `profile 1080`, `profile hidpi`, `sync`, `key`, `click` com prova cada; `up --window` fica pra sessão do dono (T040) e entra como "pendente: dono"; os 5 atalhos em ALT com um screenshot cada nos dois; preencher `lab/009/ferramentas.tsv` (30 linhas, as do Hyprland vêm do T023) (FR-015–FR-017, SC-004, SC-005)
- [ ] T023 [US2] Regressão do Hyprland com as ferramentas novas (`lab/perf --task 009/T023`): `teste-hiso` (ou uma nova sobre a `hypr-iso`), os três roteiros 15/0, 25/0, 58/0, os 5 atalhos com screenshot e as linhas `hyprland` da `ferramentas.tsv` (FR-018)
- [ ] T024 [US2] Spike do uwsm (`lab/perf --task 009/T024`): numa camada descartável de cada, `uwsm start` com o Niri e com o Mango; anotar se sobe e o que muda; não vira padrão (FR-008, research R5); `lab/009/spikes/uwsm.md`

**Checkpoint**: três famílias de VM com as mesmas ferramentas e atalhos.

---

## Phase 5: User Story 3 - A UI da `main` rodando em cada compositor (Priority: P1)

**Goal**: o que aparece e o que quebra da UI da `main` no Niri e no Mango, com o efeito exato do
`import Quickshell.Hyprland`.

**Independent Test**: 16 screenshots (4 telas × 2 perfis × 2 compositores), `ui.log` de cada partida,
`itens.tsv` completo, `import-hyprland.txt` com as linhas exatas.

- [ ] T025 [P] [US3] Niri (`lab/perf --task 009/T025`): `lab/sync` da `main`, `pkill -x qs` com o `ui.log` esvaziado, screenshots da barra, `ALT+I`, `ALT+W` e o papel de parede em 1080 e hidpi; `ui.log` em `lab/009/ui/niri/`; se o `qs` entrar em laço, guardar 3 partidas e parar o `nier-ui-run`; `import-hyprland.txt` com as linhas exatas (ou "silêncio" + o log inteiro) (FR-019–FR-021)
- [ ] T026 [P] [US3] Mango: o mesmo do T025, em `lab/009/ui/mango/`
- [ ] T027 [US3] `lab/009/ui/itens.tsv`: cada item (barra, abas, título, relógio, bateria, papel de parede, configurações, seletor, contraste) × compositor × perfil, com `funciona`/`parcial`/`quebra`, screenshot e linha do log; conferir as hipóteses do research R8 (escala por monitor, monitor em foco, pop-ups) (SC-006, SC-007)
- [ ] T028 [US3] Spike do `Loader` (`lab/009/spikes/loader/`, `lab/perf --task 009/T028`): `shell.qml` mínimo com um `Loader` escolhendo entre um arquivo que importa `Quickshell.Hyprland` e um que não importa, no Niri e no Mango; log e `/proc/<pid>/maps` (FR-022, research R8)
- [ ] T029 [US3] (Informativo) `check-u1`, `check-003`, `check-004` no Niri e no Mango; resultado no `lab/009/ui/roteiros.md`, sem critério (FR-018)

**Checkpoint**: a lista do que funciona e do que quebra, com prova.

---

## Phase 6: User Story 4 - Amostras pro contrato do adaptador (Priority: P2)

**Goal**: todas as células do §6 do contrato da 007 com amostra e estado, as `capabilities` propostas e a
tabela corrigida ([contracts/amostras.md](contracts/amostras.md)).

**Independent Test**: `lab/009/amostras/index.tsv` com 100% das células do Niri e do Mango com estado;
`tabela-s6.md` gerada; `capabilities.json` com os três.

- [x] T030 [US4] `lab/009/amostras/cenarios.md`: os comandos de cada compositor pra chegar em `S0`, `S1` (kitty `nier-a` e `nier-b` flutuante na área 1, `nier-c` em tela cheia na área 2, foco no `nier-a`), `S2` (hidpi) e `S3` (duas saídas, se o T034 der) — **feito**
- [ ] T031 [P] [US4] Amostras do Hyprland (referência), `L01`–`L10` + `Q-deteccao`, em `lab/009/amostras/hyprland/` (`lab/perf --task 009/T031`)
- [ ] T032 [P] [US4] Amostras do Niri, `L01`–`L10`, `Q-niri-tela-cheia` (testar a inferência tamanho da janela = tamanho lógico da saída), `Q-niri-flutuante`, `Q-niri-coluna`, `Q-deteccao`, `L06` com 10 s de `event-stream` (`lab/perf --task 009/T032`)
- [ ] T033 [P] [US4] Amostras do Mango, `L01`–`L10`, `Q-mango-acao-fora-de-foco` (`dispatch … client,<id>` em mover, fechar, focar), `Q-mango-tag-por-janela`, `Q-mango-eventos` (`mmsg watch`), `Q-deteccao` (`lab/perf --task 009/T033`)
- [ ] T034 [US4] Spike de duas saídas (até 30 min, `lab/perf --task 009/T034`): `max_outputs=2` por variável no `lab/up` (sem mudar o padrão), numa camada descartável; se o compositor listar as duas e aceitar escalas 1 e 1,25, amostras `S3` de `L01`, `L02` e `Q-escala-por-monitor` nos três; senão, fonte marcada "pesquisa" (FR-028, research R12)
- [ ] T035 [US4] Spike da rota genérica (`lab/009/spikes/generico/`, `lab/perf --task 009/T035`): um QML mínimo que lista áreas (`Quickshell.WindowManager`) e janelas (`ToplevelManager`) no Niri, no Mango e no Hyprland; amostra `Q-quickshell-generico` (research A7)
- [ ] T036 [US4] `index.tsv` completo, `lab/009/tabela-s6.md` (gerada do índice) e `lab/009/capabilities.json` com os seis campos por compositor, cada um ligado às amostras (FR-023–FR-026, SC-008)

**Checkpoint**: o contrato tem resposta pra cada célula.

---

## Phase 7: User Story 5 - Uma sessão pro dono usar com as mãos (Priority: P2)

**Goal**: as camadas da sessão, as colinhas, a folha de notas vazia com a evidência, e o Hyprland com o
plugin da comunidade.

**Independent Test**: um comando liga cada sessão; colinhas ≤ 30 linhas; `folha.md` com os 12 campos
vazios + o da visão geral "com plugin", cada um com evidência.

- [ ] T037 [US5] Camada `teste-hypr-sessao` sobre a `hypr-iso` com o `~/.config/hypr/local.lua` (layout `scrolling` nas áreas 3–5; atalhos nativos de colunas, mover, tela cheia, flutuar em ALT) (P2, contrato §5); conferir com screenshot de 4 janelas na área 3
- [ ] T038 [US5] Rajadas das 4 animações (abrir, fechar, trocar de área, mover) nos três, mais visão geral (Niri, Mango) e rolagem de colunas (Niri, Mango, Hyprland áreas 3–5), em `lab/009/rajadas/<c>/<acao>/` com `resumo.txt` (quadros com mudança, duração aparente, quadros quebrados) (`lab/perf --task 009/T038`, FR-033, research R11)
- [ ] T039 [US5] Hyprland com plugin (`lab/perf --task 009/T039`): camada descartável `hypr-plugins` sobre a `hypr-iso`; `hyprpm` com uma cópia da comunidade do `hyprexpo` (marcada "plugin da comunidade"); se compilar na 0.56.2, screenshot e rajada da visão geral; se não, o erro e o tempo gasto como risco de manutenção; apagar a camada (FR-038, P2)
- [ ] T040 [US5] Colinhas `lab/009/sessao/colinha-{hyprland,niri,mango,hyprland-plugin}.md` (≤ 30 linhas, formato do [contrato do relatório](contracts/relatorio.md)) com o comando de uma linha pra ligar com `--window`, os atalhos do lab e os nativos, o que olhar por critério, gestos só por documentação, colisões (FR-029, SC-010)
- [ ] T041 [US5] `lab/009/sessao/folha.md`: por critério de experiência (com as âncoras) e compositor, só a coluna "Evidência" preenchida (rajadas, screenshots, documentação); nota e comentário vazios; o "com plugin" só na visão geral (FR-030, C2)

**Checkpoint**: o dono tem tudo pra testar e dar as notas.

---

## Phase 8: User Story 6 - O relatório (etapa 1) (Priority: P1)

**Goal**: `docs/estudo-compositores.md` com a parte técnica e a evidência; recomendação pendente.

**Independent Test**: toda célula com evidência ou "(pesquisa)"; conta técnica refazível; nenhuma nota de
experiência; recomendação "pendente: notas do dono".

- [ ] T042 [US6] Custo (`lab/perf`, uma sessão por rodada, `--task 009/T042`): 3 rodadas × 3 compositores, cada uma numa camada nova (`teste-<c>-custo`), `--headless`, perfil 1080, sem fixtures, sem janela; boot até a UI pelo `~/nier/ui.start` + `systemd-analyze`; 120 s parado; RAM e CPU da VM, do `qs` e do compositor; `lab/009/custo.tsv` com mediana e maior diferença (FR-032, SC-009, research R10)
- [ ] T043 [US6] Notas técnicas (IPC, risco de manutenção, custo, empacotamento) por compositor, com as âncoras aprovadas e a evidência, em `lab/009/notas-tecnicas.md`; eliminatórios conferidos (FR-035)
- [ ] T044 [US6] `docs/estudo-compositores.md`, etapa 1 (repositório público, branch `009-compositores`): as seções do [contrato do relatório](contracts/relatorio.md), a tabela §6 corrigida como proposta, o que fica pra S5, as fontes; sem caminhos do host nem dados pessoais (FR-036–FR-039, FR-042, SC-011)
- [ ] T045 [US1] Recriar as `teste-*` sobre a `hypr-iso`, uma por vez, só as livres naquela hora (`lab/ls`, `pgrep -af qemu-system`, `.pid` com processo vivo, nenhuma camada com ela como base); as ocupadas vão pendentes pro resumão (FR-004, C1)
- [ ] T046 [US6] Fechamento: `sha256sum -c lab/009/bases.sha256` (4 × OK), conferir nos relatórios `lab/perf` do estudo que só rodaram ferramentas do lab no host e que nunca houve mais de 2 VMs do estudo nem 4 no total (SC-002, SC-012); entrada no `rien-OS-private/central/resumao.md` (resultados, commits, pendências do dono, a 0.57 como tarefa à parte); a Central atualizada com os comandos e camadas novos. **PARAR e relatar** (parada c), com a lista dos screenshots e rajadas que melhor mostram visão geral, colunas e animações de cada compositor

**Checkpoint**: etapa 1 entregue; o estudo espera a folha do dono.

---

## Phase 9: Polish (depois da folha do dono)

- [ ] T047 README do lab: árvore com `hypr-iso`/`niri-base`/`mango-base`, ferramentas por compositor, "Lições" do estudo; `shellcheck` em tudo que mudou
- [ ] T048 Etapa 2 do relatório: copiar as notas do dono da `folha.md`, a conta completa (pesos aprovados e iguais), a recomendação pela regra aprovada (SC-013). **Só depois que o dono devolver a folha**

---

## Dependencies & Execution Order

- **Setup (T001–T003)**: T003 é bloqueante pra tudo do Niri e do Mango; se falhar, para.
- **Foundational (T004–T006)**: depois do T003; bloqueia as US2–US6.
- **US1 (T007–T013)**: depende de T004 (marca); pode correr junto com o começo da US2 (T014–T017 são só
  arquivos). O T045 (recriar as `teste-*`) fica pro fim, depois da regressão (T023).
- **US2 (T014–T024)**: T018 depende de T014–T017; T022 depende de T018–T021; T023 depende de T019–T021 e
  do T013.
- **US3 (T025–T029)**: depende do T022 (ferramentas no Niri e no Mango).
- **US4 (T030–T036)**: depende do T022; T036 depende de T031–T035.
- **US5 (T037–T041)**: T037 depende do T013; T041 depende do T038 e do T039.
- **US6 (T042–T046)**: T042 depende das três bases; T044 depende de US3, US4, T042, T043; T046 é o último.

### Paralelo (no máximo 2 VMs deste estudo)

- T014 ∥ T015 ∥ T016 ∥ T017 (arquivos, sem VM).
- T019 ∥ T020 ∥ T021 (arquivos diferentes).
- Niri ∥ Mango em duas VMs: T025 ∥ T026; T032 ∥ T033.
- T031 (Hyprland) cabe numa das duas vagas quando um dos compositores estiver parado.

## Implementation Strategy

1. **MVP = Setup + Foundational + US1**: a `hypr-iso` promovida na `lab-009`, com os mesmos números.
2. **US2 + US3**: as duas bases novas e a UI da `main` nelas (o que o dono mais quer ver).
3. **US4**: as amostras (entrada da S5 e da frente B da 007).
4. **US5 + US6 etapa 1**: sessão do dono e relatório técnico; parada (c).
5. **Etapa 2**: só com a folha do dono.
