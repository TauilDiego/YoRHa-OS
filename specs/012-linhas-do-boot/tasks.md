---
description: "Tarefas da 012: linhas do boot na hora"
---

# Tasks: Linhas do boot na hora

**Input**: `specs/012-linhas-do-boot/` (spec.md, plan.md)

**Status**: aprovadas pelo dono em 29.10 ("pronto agora roda ele"). Todas feitas em 30.10; o relatório está em `relatorio.md`.

**Tests**: a prova é a evidência da VM (princípio IV), sempre dentro do `lab/perf`. A VM é a
`teste-011` (camada `boot-iso`, com a 011 instalada pelo módulo). Sem agentes paralelos: é uma frente
só e pequena.

## Phase 1: User Story 1 - Ver as etapas do boot passando (Priority: P1) 🎯 MVP

- [X] T001 [US1] Acrescentar `typing=instant|game` (padrão `instant`) em `system/boot/plymouth/yorha-os/config` e em `gen/embed-stages.py`, que leva o valor pro script como `cfg_typing`
- [X] T002 [US1] Escrever o modo `instant` no `list_update` de `system/boot/plymouth/yorha-os/yorha-os.script`: a linha aparece inteira no quadro em que fica pronta, sem digitação, sem a letra sorteada, sem nascer apagada e sem o `GAP`; até 4 linhas novas por quadro (orçamento da preparação)
- [X] T003 [US1] Limitar as linhas por grupo no modo `instant`: no máximo uma linha de cada grupo a cada 0,5 s, com a contagem acumulada
- [X] T004 [US1] Instalar pelo módulo na `teste-011` e capturar um boot do zero com `lab/bootcap` (SC-001: pelo menos 15 linhas antes da saída, nenhuma pela metade, faixas presentes); com `debug=on`, medir os quadros/s na rajada (SC-002, ≥ 25); `lab/011/boot-timing` com três boots (SC-003, ≤ +1 s)

## Phase 2: User Story 2 - A digitação do jogo como opção (Priority: P2)

- [X] T005 [US2] Com `typing=game`, capturar um boot e conferir a digitação da 011 (SC-004); voltar o padrão pra `instant`

## Phase 3: Fecho

- [X] T006 Documentar a opção em `system/boot/plymouth/yorha-os/README.md` e em `specs/011-boot-e-login/contracts/plymouth-theme.md`
- [X] T007 Abrir a `teste-011` numa janela pro dono ver e testar (SC-005), e ajustar o que ele pedir
- [X] T008 Escrever `specs/012-linhas-do-boot/relatorio.md` (as capturas, os quadros/s, o tempo de boot e os relatórios do `lab/perf`) e atualizar o PLAN

## Dependencies

T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008. A US2 depende da US1 porque as duas mexem no
mesmo laço.
