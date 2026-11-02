---
description: "Tarefas da 015: primeira release pública"
---

# Tasks: Primeira release pública

**Input**: `specs/015-primeira-release/` (spec.md, plan.md, research.md, data-model.md, contracts/,
quickstart.md)

**Status**: geradas em 02.11, depois da aprovação do plano pelo dono ("aprovadoooo").

**Tests**: sem testes automatizados de código. A prova de cada tarefa é a evidência da VM (princípio
IV): a saída dos comandos, o `dump` do IPC, screenshots e o log de QML sem erro, sempre dentro do
`lab/perf begin/end`. Os cenários numerados são os do `quickstart.md`.

**Quem executa** (research R11): cada fase ou frente vai pra um agente. A sessão principal só
planeja, escreve os briefings e confere a evidência. O modelo e o esforço estão no título de cada
fase.

**Caminhos**:
- `install.sh`, `bin/…`, `lib/…`, `system/…`, `shell/…`, `docs/…`, `README.md`, `.specify/…` = repo
  público. A base é a branch `015-primeira-release` (`YoRHa-OS-wt/spec015`), e cada frente tem uma
  branch própria saindo dela (`015-a`, `015-b`, `015-c`, `015-d`, em `YoRHa-OS-wt/015-<x>`).
- `lab/…` = repo privado. A base é a branch `lab-015` (`YoRHa-OS-private-wt/lab-015/lab/`), e cada
  frente tem uma branch própria saindo dela (`lab-015-<x>`).
- Tudo termina mesclado nas duas `main` e apagado.

**VMs**: no máximo 4 ao mesmo tempo, cada uma com `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G` e
`--audio-capture`.
- **Setup e fundação:** `t015`, uma camada da `hypr-iso` com um `hyprland.lua` comum.
- **Frentes:** `t015-a`, `t015-b`, `t015-c` e `t015-d`.

**Canal por frente**: cada uma tem a pasta de releases e as portas próprias. O canal e o `release`
aceitam `--dir`, e assim os números `0.0.N` de uma frente não colidem com os de outra:

| Quem | Portas |
|---|---|
| Fundação | 8714 e 8715 |
| A | 8721 e 8722 |
| B | 8731 |
| C | 8741 |

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: pode ir pra um agente paralelo, com worktree e VM próprios. Dentro de uma frente, a ordem é
  a dos IDs.
- **[Story]**: história da spec (US1–US6).

## Phase 1: Setup (agente S · Opus 5.5 · médio)

- [ ] T001 Criar a `lab-015` a partir da `main` privada e o worktree `YoRHa-OS-private-wt/lab-015`
- [ ] T002 `lab/015/canal`, em python só com a biblioteca padrão (contracts/canal-publico.md):
  - `start [--port N] [--dir D]`, `stop [--port N]`, `status`, `log [--port N]` e `corrupt <v>|off`;
  - os caminhos do GitHub: `releases/latest/download/<arquivo>`, `releases/download/v<v>/<arquivo>`
    e `releases.atom`, gerado do `index.json`;
  - um log JSON por porta
- [ ] T003 `lab/015/release`: `build`, `list` e `check` (contracts/release.md e contracts/nome.md),
  com `--dir`:
  - o pacote pelo `git archive --add-virtual-file` (prefixo `<YORHA_NAME>-<v>/`, lido do `name.sh` da
    ref);
  - o `.sha256`, o `latest` e o `NOTES.md` (o rascunho pelos commits, ou `--notes`);
  - o `install.sh` gravado. O bloco entre `# @@channel-core-begin` e `# @@channel-core-end` recebe o
    `lib/yorha/channel.sh` da ref, e a linha `YORHA_DEFAULT_ORIGINS=` recebe o `YORHA_ORIGINS` do
    `name.sh` da ref. Sem os marcadores (antes da T009), o `install.sh` vai como está;
  - as quatro recusas e as regras de arquivo proibido e de nome provisório;
  - `--allow-old-name`, que só vale junto com `--lab-only` e serve pra montar antes da troca do nome
    (T006)
- [ ] T004 A camada `t015` (`lab/new t015 --from hypr-iso`) e o `lab/015/prep`, levado do
  `lab/014/prep`, com o `hyprland-limpo.lua` (sem o `nier-ui-run` nem o `~/nier/ui`)
- [ ] T005 O `lab/check-015`, que roda os blocos de `lab/015/check.d/` em ordem, no padrão do
  `check-013`, e a seção da 015 no `lab/README.md`. Validar, medido:
  - `release build 0.0.1 --ref 015-primeira-release --lab-only --allow-old-name`;
  - `canal start`;
  - de dentro da `t015`, `curl -fsSL 10.0.2.2:8714/releases/latest/download/latest` responde `0.0.1`,
    e o `releases.atom` lista a versão

## Phase 2: Foundational (sequencial; bloqueia as frentes)

### F1, a troca do nome (agente N · Haiku · baixo)

- [X] T006 No repo público (branch `015-primeira-release`), aplicar a tabela do contracts/nome.md:
  - `git mv` das pastas e dos arquivos com `yorha-os` no nome;
  - a troca no conteúdo, fora da lista de histórico;
  - `YORHA_OS_<X>` vira `YORHA_<X>`, e o `YORHA_OS_CHANNEL` fica pra T009.

  Conferir com `git grep -n -i -E 'yorha[-_]?os'`: só sobram arquivos da lista de histórico. Commit
  único

  Feito em 02.11 (f64d048, Haiku): 270 caminhos e 66 arquivos. Um falso positivo foi corrigido na
  conferência (`yorha-osd`, o OSD, tinha virado `yorha-shelld`; b10960f). Ficaram pra outras tarefas:
  - a fonte do boot (T008);
  - o `YORHA_OS_CHANNEL` (T009);
  - pra frente D: as URLs `TauilDiego/YoRHa-OS` (PLAN, `metadata.desktop`) e as linhas do PLAN que
    agora dizem "o YoRHa-Shell é provisório".

  O id de voz `yorhaos` é uma chave das opções salvas e fica.
- [ ] T007 No repo privado (branch `lab-015`), a mesma tabela nos roteiros ativos:
  - `check-003` a `check-014`, `guest/`, `011/`, `014/`, `lib.sh`, `README.md` e `provision`;
  - nunca em `u2/`, `009/` ou `mockups/`.

  Mesma conferência. Commit único

### F2, a fonte, a regressão e o núcleo (agente F · Opus 5.5 · médio)

- [ ] T008 Regerar a fonte do boot como "YoRHa-Shell Boot" (`YoRHaShellBoot.ttf`) pelo
  `system/boot/plymouth/yorha-shell/gen/assets.py`, **dentro da `t015`**:
  - trocar as referências;
  - atualizar a linha do `CREDITS.md`;
  - conferir que o tema do Plymouth acha a fonte (`plymouth --show-splash` não é preciso: basta a
    conferência de arquivos do `check-011`, sem o boot)
- [ ] T009 O núcleo do canal (contracts/cli.md):
  - `lib/yorha/name.sh` com `YORHA_ORIGINS`;
  - `lib/yorha/channel.sh` com `yorha_origins`, `yorha_channel`, `yorha_latest` e
    `yorha_fetch_release`, sempre `curl -fsSL`;
  - o `install.sh` com os marcadores da T003 e o `YORHA_DEFAULT_ORIGINS=`;
  - o `.gitattributes` com o `export-ignore` de `specs/`, `.specify/`, `.claude/` e `.github/`;
  - no `bin/yorha`, separar o update em `update_check`, `update_fetch` (pelo `channel.sh`) e
    `update_finish`, sem mudar o comportamento da 014. É pra que a frente A e a frente C mexam em
    funções diferentes
- [ ] T010 `shell/services/Product.qml`:
  - o nome, o nome bonito, a pasta de estado e a de runtime, lendo `YORHA_NAME`, com `yorha-shell`
    quando o shell roda direto do repositório;
  - trocar os `yorha-shell` escritos à mão no QML (`Updater`, `Sounds` e os outros que a busca
    mostrar);
  - o supervisor (`yorha shell start`) exporta `YORHA_NAME` e `YORHA_ROOT`
- [ ] T011 Validar a fundação na `t015`, medido:
  - `release build 0.0.2 --ref 015-primeira-release --lab-only`, já sem `--allow-old-name`: o
    `check` passa (cenário 9, parte do pacote);
  - instalar com `YORHA_ORIGIN=http://10.0.2.2:8714`;
  - o shell sobe pela linha do `hyprland.lua`;
  - `yorha status` responde;
  - o `shell.log` sem erro de QML;
  - `check-003`, `004`, `007`, `008` e `013` passam com o nome novo

**Checkpoint:** o contrato (`channel.sh`, as funções do update, o `Product.qml`) fica estável. As
frentes saem daqui.

## Phase 3: US1, instalar pelo endereço público (P1) 🎯 MVP · frente A (Opus 5.5 · médio, `t015-a`, portas 8721/8722)

**Goal**: o comando do README instala a estável mais nova, sem nenhuma variável.

**Independent Test**: cenários 1 e 2.

- [ ] T012 [P] [US1] O `install.sh`:
  - as origens pelo bloco gravado (`YORHA_ORIGIN`, ou `YORHA_DEFAULT_ORIGINS`);
  - o canal pelo `YORHA_CHANNEL`;
  - escreve `origins` e `channel` em `$YORHA_HOME`;
  - as saídas 0–4 da 014, com a 1 cobrindo "nenhuma origem respondeu"
- [ ] T013 [US1] `yorha status` mostra o canal e as origens. O `lab/015/check.d/a-install` cobre os
  cenários 1 e 2, com o `canal corrupt`

## Phase 4: US2, uma versão nova publicada chega pelo update (P1) · frente A

**Goal**: a máquina descobre a versão nova pelo canal dela. O canal de teste recebe as pré-releases,
e o update nunca volta versão.

**Independent Test**: cenários 3, 4, 5 e 6.

- [ ] T014 [US2] O `update_check` pelo `yorha_latest`:
  - o `stable` lê o `latest`, e o `testing` lê o `releases.atom`;
  - a regex `^[0-9]+\.[0-9]+\.[0-9]+$`;
  - o JSON com `channel` e `origin`;
  - nunca oferece versão menor
- [ ] T015 [US2] `yorha channel` e `yorha channel stable|testing` (contracts/cli.md)
- [ ] T016 [US2] O espelho (FR-018): o `yorha_fetch_release` tenta as origens em ordem, e os arquivos
  de uma versão vêm da mesma origem
- [ ] T017 [US2] O `lab/015/check.d/a-update` cobre os cenários 3, 4, 5 e 6. No cenário 4, como as
  quatro frentes ocupam as 4 VMs, a mesma VM confere nos dois canais: no `stable`, `up-to-date`; no
  `testing`, a versão de teste, que ela instala e desfaz pelo rollback. O teste com duas VMs de
  verdade é o da T044

## Phase 5: US3, montar e publicar com um comando (P1) · frente A

**Goal**: montar, recusar o que não pode, publicar o mesmo arquivo testado.

**Independent Test**: cenário 8; o `publish --dry-run`.

- [ ] T018 [US3] O `lab/015/check.d/a-release`, que roda no host e cobre o cenário 8. As quatro
  recusas, com uma branch de teste descartável (`t015-recusa`) pro arquivo proibido
- [ ] T019 [US3] `lab/015/release publish` e `promote` (contracts/release.md):
  - o rascunho primeiro, a conferência por download e só então público;
  - `--dry-run`;
  - as recusas.

  Validar só com `--dry-run`: nada vai pro GitHub nesta tarefa

## Phase 6: US4, o nome público e a troca de nome pelo update (P1) · frente C (Opus 5.5 · médio, `t015-c`, porta 8741)

**Goal**: a troca do nome já está feita (T006–T008). Aqui a 0.1.0 aprende a trocar de nome num
update futuro (FR-017).

**Independent Test**: cenário 10 (SC-009), e o cenário 9 nas pastas instaladas e nos textos da UI.

- [ ] T020 [P] [US4] `bin/yorha`:
  - o `update` entrega o fim pra versão nova (`<nova>/bin/<cmd> _finish-update --from <v>
    --from-home <pasta>`);
  - o `_finish-update` faz o que o `update_finish` faz quando os nomes são iguais (research R6)
- [ ] T021 [US4] `lib/yorha/rename.sh`, a troca nos dois sentidos (data-model.md, "Depois de uma troca
  de nome"):
  - move `share`, `state` e `config`;
  - deixa links no `state` e no `config`;
  - a pasta de compatibilidade com o `<antigo>.lua` de uma linha;
  - o `renamed-to` e o `renamed-from`;
  - o atalho do comando
- [ ] T022 [US4] O resto do `bin/yorha` e o aviso:
  - o supervisor segue o `renamed-to`;
  - o `rollback` desfaz a troca;
  - o `uninstall` limpa o atalho, os links e a pasta antiga;
  - o `status` mostra a linha nova;
  - um singleton pequeno, `shell/services/NameChange.qml`, que manda uma vez a transmissão com a
    linha nova quando existe `renamed-from` sem aviso dado
- [ ] T023 [US4] A versão de mentira:
  - o worktree descartável `YoRHa-OS-wt/t015-fake` (branch `t015-fake`, saindo da `015-c`), com o
    `name.sh` em `fake-shell`, `fakecmd` e `Fake-Shell`;
  - `release build 0.0.N --lab-only --ref t015-fake`;
  - o `lab/015/check.d/c-rename` cobre o cenário 10, de ida e volta, com screenshots nas duas pontas

## Phase 7: US5, o aviso que fica (P2) · frente B (Opus 5.5 · médio, `t015-b`, porta 8731)

**Goal**: o sinal de versão nova fica na tela até o update, em cinco formas, e a conferência
automática pode ser desligada.

**Independent Test**: cenários 7 e 11.

- [ ] T024 [P] [US5] O catálogo e os textos:
  - `sign` e `auto-check` na categoria `updates` de `shell/fixtures/settings-default.json`;
  - os textos de ajuda do contracts/sinal.md;
  - em `shell/strings/Strings.qml`, o `UPDATE` e os rótulos das formas
- [ ] T025 [US5] `shell/services/Updater.qml`:
  - `sign` e `autoCheck` lidos das opções;
  - os timers só com `installed && autoCheck`;
  - o `check()` ao abrir SYSTEM › Updates com a conferência desligada;
  - a forma `login`, pela trava `update-reminded-<latest>` (como o `Sounds.sessionStart`);
  - os campos novos do `dump`
- [ ] T026 [US5] `shell/hud/UpdateTag.qml`, no molde do `LogCounter`:
  - o tom e a placa da barra;
  - o clique emite o `Updater.showUpdates`.

  Ligar no `shell/hud/Hud.qml`, antes do LOG
- [ ] T027 [US5] O menu:
  - `shell/ds/composites/TabBar.qml` aceita uma `tag` por aba;
  - a aba SYSTEM e a linha da categoria Updates recebem a `Tag` "NEW" com a forma `menu` ou `both`.

  Toda lista continua cabendo e rolando por linhas inteiras
- [ ] T028 [US5] O `lab/015/check.d/b-sign` cobre os cenários 7 e 11:
  - screenshots das cinco formas, trocadas com o shell aberto;
  - o clique no `UPDATE`;
  - depois do update, nada;
  - os screenshots de antes e depois guardados pra página de revisão

## Phase 8: US6, o repositório público em ordem (P3) · frente D (Opus 5.5 · médio, `t015-d`)

**Goal**: o README, a constituição, o PLAN, o lint e a auditoria prontos pro push. O push mesmo fica
pra Phase 10.

**Independent Test**: cenário 13; a auditoria sem achados (ou com os achados explicados).

- [ ] T029 [P] [US6] `README.md` (FR-013):
  - o comando público;
  - o estado (antes da 1.0, testado em VM, pode quebrar entre versões);
  - os requisitos;
  - instalar, `status`, `update`, `channel`, `rollback`, `boot-login` e `uninstall`;
  - o aviso de projeto de fã (sem ligação com a Square Enix; NieR e YoRHa são marcas dela);
  - "sem telemetria: o shell só pergunta qual é a versão mais nova".

  Nada de detalhe do lab
- [ ] T030 [US6] A emenda 2.1.0 em `.specify/memory/constitution.md`, com o texto exato do plan.md e
  a entrada no Sync Impact Report. Também:
  - os `CLAUDE.md` (o da YoRHa-OS e o da pasta do projeto, que é privado: só o texto do nome);
  - o `PLAN.md`: S3 e S4 com o canal público; nas decisões de 02.11, o nome, a assinatura antes da
    1.0, a telemetria adiada e a VPS na 016;
  - o `docs/design-system.md`, com o `UPDATE` da barra
- [ ] T031 [US6] `.github/workflows/lint.yml` ganha o `workflow_dispatch`. Rodar o `shellcheck` e o
  `qmllint` do jeito do workflow **dentro da `t015-d`** (cenário 13) e corrigir o que aparecer, no
  arquivo da frente dona ou anotado pra junção
- [ ] T032 [US6] `lab/015/audit`, que só lê o histórico que vai subir (`origin/main..015`):
  - caminhos do repositório privado;
  - padrões de token e chave;
  - binários acima de 8 MB;
  - extensões do jogo.

  Rodar e trazer o relatório

## Phase 9: Junção (agente J · Opus 5.5 · médio, até 2 VMs)

- [ ] T033 Mesclar as frentes na `015-primeira-release` e as `lab-015-<x>` na `lab-015`, resolvendo os
  conflitos (`Strings.qml`, `bin/yorha`). O `check-015` inteiro e a regressão (cenário 12), medidos
- [ ] T034 O Central (comandos novos: `yorha channel`, `lab/015/canal`, `release` e `audit`) e o Mapa
  do projeto (015 em junção)
- [ ] T035 A sessão do dono numa janela da VM:
  - instalar;
  - ver o `UPDATE` de uma versão nova e atualizar por ele;
  - trocar a forma do sinal.

  Também: as fotos de antes e depois no Chrome dele e o `specs/015-primeira-release/relatorio.md`
- [ ] T036 Com o OK do dono: o merge da 015 e da `lab-015` nas duas `main`, e as branches e os
  worktrees apagados

## Phase 10: A release de verdade (sessão principal, cada passo com o OK do dono)

- [ ] T037 `release build 0.1.0` da `main`, com as notas escritas à mão. Os cenários 1, 3 e 11 com
  esse mesmo arquivo servido pelo canal. A página da release pro dono (notas, checksum, evidência):
  SC-008
- [ ] T038 A auditoria (T032) na `main` e o push da `main` (OK)
- [ ] T039 `gh repo rename YoRHa-Shell` e o `git remote set-url` local (OK)
- [ ] T040 Apagar as 13 branches velhas do GitHub (OK)
- [ ] T041 O lint verde no GitHub: o push dispara, ou o `workflow_dispatch`. Se não rodar, investigar
  o motivo (as Actions do repositório ou da conta)
- [ ] T042 `release publish 0.1.0` (OK): o checksum baixado de volta bate (SC-003)
- [ ] T043 Numa VM limpa, o comando do README sem variável nenhuma (SC-001 com o GitHub de verdade).
  Agente · Opus 5.5 · médio
- [ ] T044 `build 0.1.1 --pre`, o teste no lab, `publish 0.1.1` (OK). A VM no canal de teste recebe a
  versão e volta pelo rollback, e a estável não é avisada (SC-002). O `promote 0.1.1` fica pra quando
  o dono quiser
- [ ] T045 O PLAN, o Mapa, o Central e a memória do projeto com a 015 concluída

## Dependencies & Execution Order

- **Setup (T001–T005)** → **Fundação (T006–T011)**, nessa ordem.
- A T006 e a T007 podem ir juntas, um agente em cada repo.
- **As frentes A, B, C e D** saem juntas depois da T011, cada uma na sua branch e na sua VM. Dentro de
  cada frente, a ordem é a dos IDs.
- **A frente C não espera a A:** ela precisa de uma versão instalada e de um update, e os dois já
  existem depois da fundação (T009), pelo canal próprio dela (8741).
- **Junção (T033–T036)** depois das quatro frentes.
- **Release (T037–T045)** depois do merge na `main`. A ordem é a da lista, e cada passo espera o OK do
  dono.

## Parallel Example

```text
Depois da T011, quatro agentes ao mesmo tempo (Opus 5.5 · médio):
  A: T012 → T019   worktree 015-a + lab-015-a, VM t015-a, portas 8721/8722
  B: T024 → T028   worktree 015-b + lab-015-b, VM t015-b, porta 8731
  C: T020 → T023   worktree 015-c + lab-015-c, VM t015-c, porta 8741
  D: T029 → T032   worktree 015-d + lab-015-d, VM t015-d
```

## Implementation Strategy

- **MVP:** Setup + Fundação + US1 (T001–T013). Isso já é "instalar YoRHa-Shell pelo canal, com o nome
  novo".
- **Depois, em paralelo:** US2 e US3 (o resto da A), US4 (a C), US5 (a B) e US6 (a D).
- **A publicação** só depois da junção e do merge, um passo de cada vez.
