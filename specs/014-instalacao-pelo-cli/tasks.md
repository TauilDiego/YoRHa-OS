---
description: "Tarefas da 014: instalação e encaixe do shell, v0 pelo CLI"
---

# Tasks: Instalação e encaixe do shell, v0 pelo CLI

**Input**: `specs/014-instalacao-pelo-cli/` (spec.md, plan.md, research.md, data-model.md, contracts/,
quickstart.md)

**Status**: geradas em 01.11, depois da aprovação do plano pelo dono ("sim"). Setup e fundação feitos em 01.11
(lab-014 `cbde342`; perf `…104434-vm-t014-…` e `…104645-vm-t014-…`).

**Tests**: sem testes automatizados de código. A prova de cada tarefa é a evidência da VM (princípio
IV): a saída dos comandos, o `dump` do IPC, screenshots e o log de QML sem erro, sempre dentro do
`lab/perf begin/end`.

**Caminhos**:
- `install.sh`, `bin/…`, `lib/…`, `migrations/…`, `system/…`, `shell/…`, `docs/…`, `specs/…` = repo
  público, branch `014-instalacao-pelo-cli` (`YoRHa-OS-wt/spec014`);
- `lab/…` = repo privado, branch `lab-014` (`YoRHa-OS-private-wt/lab-014/lab/`). As duas branches
  terminam mescladas na `main` e apagadas.

**VMs**: no máximo 4 ao mesmo tempo, cada uma com `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`.
- **Fundação:** a `t014`, uma camada da `hypr-iso` com um `hyprland.lua` comum.
- **Frentes**, se forem em paralelo: `t014-a`, `t014-b` e `t014-c`.
- **US5:** a `teste-011` (camada `boot-iso`).

**Versões de teste**: commits no worktree descartável `YoRHa-OS-wt/t014-canal` (branch `t014-canal`),
que o canal segue. Nada dele vai pra `main`.

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: pode ir pra um agente paralelo, com worktree e VM próprios. Dentro de uma frente, a ordem é
  a dos IDs.
- **[Story]**: história da spec (US1–US6).

## Phase 1: Setup (F0)

- [X] T001 Criar a `lab-014` a partir da `main` privada e o worktree `YoRHa-OS-private-wt/lab-014`
- [X] T002 `lab/014/canal`, em python só com a biblioteca padrão (contracts/canal.md):
  - `start`, `stop`, `status`, `follow <pasta> [ref]` e `log`;
  - `/latest`, o tarball pelo `git archive --add-virtual-file`, o `.sha256` e o `/install.sh`;
  - uma opção de teste pra servir um checksum errado (US2, cenário 5)
- [X] T003 O worktree descartável `YoRHa-OS-wt/t014-canal` (branch `t014-canal`, saindo da 014), e o
  canal seguindo ele
- [X] T004 A camada `t014` (`lab/new t014 --from hypr-iso`), o `lab/014/prep` e o
  `lab/014/hyprland-limpo.lua`, um Hyprland de pessoa comum, sem o `nier-ui-run` nem o `~/nier/ui`
- [X] T005 O esqueleto do `lab/check-014`, por blocos, no padrão do `check-013`, e a seção da 014 no
  `lab/README.md`. Validar: de dentro da `t014`, `curl 10.0.2.2:8714/latest` responde (medido)

## Phase 2: Foundational (F1, o que as frentes dividem)

- [X] T006 `lib/yorha/name.sh`, com o nome, as pastas e o arquivo do canal num lugar só (FR-019), e o
  `lib/yorha/common.sh`, levado do `lab/u2/comum/yorha-common.sh` (sem a instalação de pacotes por
  listas)
- [X] T007 `bin/yorha`: o despacho, `version` e `status`; o `VERSION` lido da pasta da versão
- [X] T008 `system/deps` (research R3) e o `migrations/README.md` (o formato da data-model)
- [X] T009 Validar na `t014`: uma versão desempacotada à mão e o `current` apontando pra ela. O
  `yorha version` e o `yorha status` respondem (medido)

## Phase 3: User Story 1 - Instalar com um comando (P1) 🎯 MVP · Frente A

- [ ] T010 [P] [US1] `lib/yorha/deps.sh`: `pacman -T`, a lista do que falta, a pergunta e o
  `sudo pacman -S --needed`. Uma obrigatória recusada sai com 3
- [ ] T011 [US1] `install.sh` (contracts/cli.md):
  - as pré-condições;
  - as dependências;
  - o download e a conferência do sha256;
  - o desempacotar em `versions/.<v>.part` → `versions/<v>`;
  - o `switch`, o link do `yorha` e o canal guardado;
  - a linha do `hyprland.lua` no fim;
  - a saída 2 quando já está instalado
- [ ] T012 [US1] Validar na `t014`: blocos `install` e `deps` (aceitar; recusar uma obrigatória → 3;
  rodar de novo → 2)

## Phase 4: User Story 4 - O encaixe no Hyprland (P2, parte do MVP) · Frente B

O MVP é a US1 com a US4: sem o encaixe, o shell instalado não sobe no login.

- [ ] T013 [P] [US4] `yorha shell start|restart` e `yorha ipc` (research R4). O supervisor vem do
  `lab/guest/nier-ui-run` e tem:
  - a espera do portal;
  - o `QT_LOGGING_RULES`;
  - o lock;
  - o laço que resolve o `current`;
  - o `YORHA_OS_ROOT`
- [ ] T014 [P] [US4] `system/hypr/yorha-os.lua` (contracts/encaixe.md)
- [ ] T015 [P] [US4] Caminhos e nomes (research R8):
  - `services/Sounds.qml` sem `/usr/share`;
  - `YORHA_OS_COMPOSITOR` e `YORHA_OS_FIXTURES` aceitando `NIER_*` (`services/Compositor.qml`,
    `services/Fixtures.qml`);
  - o lab continua funcionando
- [ ] T016 [US4] Validar na `t014`, com a linha incluída e um novo login:
  - o shell sobe uma vez;
  - os atalhos SUPER (pelo `lab/key`) abrem o menu, as configurações e o seletor;
  - os `dump` do IPC respondem;
  - o log de QML fica limpo;
  - screenshot (bloco `encaixe`)

## Phase 5: User Story 2 - Uma correção chega pelo `yorha update` (P1) · Frente A

- [ ] T017 [US2] `yorha update [--check [--json]]`, do protótipo D:
  - o download e o sha256, com `.part`;
  - a cópia do estado, a troca e as migrations;
  - o `prune`, que guarda 3;
  - `yorha shell restart`;
  - recusar uma versão mais velha e limpar o que sobrou de um update interrompido
- [ ] T018 [US2] `yorha rollback` e `yorha migrate`, com as marcas em `state/migrations/`
- [ ] T019 [US2] Validar na `t014`, com commits no `t014-canal` (uma mudança visível no HUD e uma
  migration de teste):
  - blocos `update`, `migration` e `rollback` (o estado igual byte a byte);
  - bloco `interrupt`, em 3 pontos: no download, entre o desempacotar e a troca, e numa migration;
  - checksum errado → 4, sem mudar nada

## Phase 6: User Story 3 - O aviso e o "Update now" (P2) · Frente C

- [ ] T020 [P] [US3] `services/Updater.qml` (contracts/updater.md), com o IPC `updates check|dump`;
  o `NotifyStore.system()` ganha uma ação opcional, que abre o menu em SYSTEM › Updates
- [ ] T021 [US3] A categoria `updates` no catálogo (`shell/fixtures/settings-default.json`), os textos
  no `Strings.qml` e a ação `update-now` chamando o `Updater.updateNow()`. Fora da instalação, aparece
  "Not installed with yorha"
- [ ] T022 [US3] Validar:
  - na `t014`, blocos `notice` e `updates-menu`: uma conferência forçada dá uma transmissão por
    versão; clicar abre Updates; "Update now" abre o `kitty` com o update; o shell volta na versão
    nova;
  - no lab comum (sem instalação): a categoria diz "Not installed" e o log fica limpo;
  - os roteiros 003 e 007, com as diferenças esperadas da categoria nova

## Phase 7: User Story 5 - O boot e o login pelo CLI (P3) · Frente B

- [ ] T023 [US5] `yorha boot-login install|uninstall|status` (research R10)
- [ ] T024 [US5] Validar na `teste-011`:
  - instalar o `yorha` pelo canal;
  - `boot-login install` → reboot (`lab/bootcap`);
  - `boot-login uninstall` → reboot, com os hashes de antes (bloco `boot-login`)

## Phase 8: User Story 6 - Desinstalar (P3) · Frente A

- [ ] T025 [US6] `yorha uninstall` (research R11)
- [ ] T026 [US6] Validar na `t014`:
  - nenhum arquivo do produto sobra fora da config e do estado;
  - o Hyprland sobe sem o shell, e a linha com `pcall` não quebra nada (bloco `uninstall`)

## Phase 9: Polish & junção (F3)

- [ ] T027 Juntar as frentes. Rodar o `check-014` inteiro e os roteiros 003, 004, 007, 008 e 013
  (SC-007), com a lista das diferenças esperadas
- [ ] T028 Documentação:
  - README: instalar e atualizar;
  - `docs/design-system.md`: a categoria Updates e a transmissão;
  - `PLAN.md`: S3 e S4;
  - `lab/README.md`: a 014
- [ ] T029 Sessão do dono numa janela da VM:
  - instalar do zero;
  - commitar uma correção e ver chegar, pelo `yorha update` e pelo "Update now"
- [ ] T030 Fechamento:
  - `relatorio.md` e a página de revisão;
  - Mapa e Central;
  - apagar o `t014-canal`;
  - mesclar a 014 e a `lab-014` na `main`, com o OK do dono

## Dependencies & Execution Order

- **Setup (T001–T005)** → **Fundação (T006–T009)** → frentes.
- **Frente A:** T010 → T011 → T012 → T017 → T018 → T019 → T025 → T026.
- **Frente B:** T013 → T014 → T015 → T016 → T023 → T024. A T016 precisa da T011 da frente A (o
  instalador põe a versão).
- **Frente C:** T020 → T021 → T022. A T022 precisa da T017 (o update) e da T013 (o shell pelo
  supervisor).
- **Junção (T027–T030):** depois das três frentes.

## Parallel Example

```text
Depois da fundação, três agentes, cada um com worktree e VM:
  A: T010 → T012, T017 → T019, T025 → T026 (t014-a)
  B: T013 → T016, T023 → T024 (t014-b, depois teste-011)
  C: T020 → T022 (t014-c)
```

Em sequência (sem agentes), a ordem é: A até a T012 → B até a T016 (o MVP) → A até a T019 → C → B
(US5) → A (US6) → junção.

## Implementation Strategy

- **MVP = setup + fundação + US1 + US4:** numa VM limpa, um comando instala e o shell sobe pelo
  Hyprland da pessoa.
- **O objetivo do dono vem logo depois, com a US2:** commitar uma correção e ver ela chegar pelo
  `yorha update`.
- **O aviso (US3)** completa o jeito de atualizar sem lembrar do comando.
- **US5 e US6** fecham a v0.
