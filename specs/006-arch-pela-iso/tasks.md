---
description: "Tarefas da 006: Arch completo na VM, instalado pela ISO (fase S2)"
---

# Tasks: Arch completo na VM (instalado pela ISO)

**Input**: `specs/006-arch-pela-iso/` (plan.md, spec.md, research.md, data-model.md, contracts/,
quickstart.md), com as decisões do dono de 2026-10-27 (spec, "Decisões do dono").

**Tests**: a spec não pede testes automatizados. A prova de cada tarefa é a evidência da VM
(princípio IV): códigos de saída, o `checks.txt`, o `install.log`, o `console.png` e, na US3, o
`lab/shot` do Hyprland, sempre dentro de `lab/perf begin … --kind 006-s2 --task 006/<T>` … `lab/perf end`,
com `NIER_LAB_VM` exportado.

**Caminhos**:
- `specs/006-arch-pela-iso/…` = repositório público `nier-os` (branch `006-arch-pela-iso`);
- `lab/…` = repositório privado `rien-OS-private` (branch `lab-s2`). Todo o código desta fase fica lá.

**Recursos**: **uma VM por vez**, `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G` (teto do dono). As VMs desta fase são
a `arch-iso` (e camadas descartáveis sobre ela) e discos de spike, apagados no fim. Nenhuma camada
existente (`basic`, `arch-limpo`, `hypr-base`, `dev`, `teste-*`) é tocada.

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: história da spec (US1–US4)

---

## Phase 1: Setup (spike e chave de release)

**Purpose**: confirmar no lab, com uma VM de rascunho, as hipóteses do research (R2, R3, R8) antes de
escrever o comando, e fixar a chave que assina a ISO.

- [ ] T001 **Spike, parte 1 (boot sem tecla):** baixar a ISO 2026.10.01 pra `$LAB_HOME/images/` (curl, conferindo sha256 e assinatura à mão), gerar um `cidata` com `xorriso` (scripts provisórios em `$LAB_HOME/out/006-spike/`, fora do `lab/`), ligar um disco de rascunho `spike-iso` com a ISO + o `cidata` (`--soft`, 2 CPUs, 4 GB) e conferir: a ISO dá boot sozinha no OVMF; o cloud-init acha o `cidata`, instala a chave do root e escreve o marcador na serial; o SSH do root responde; o `screendump` do QMP funciona com `--soft`. **Se o cloud-init não achar o `cidata`, testar o plano B** (research R2: boot direto no kernel com `script=`) e registrar a decisão. Medir o download da ISO
- [ ] T002 **Spike, parte 2 (archinstall):** na mesma VM, `archinstall --dry-run` com a configuração padrão do contrato até passar sem aviso (guardar o `user_configuration.json` salvo como referência); depois uma instalação completa, cronometrada (tempo de download dos pacotes à parte, decisão 5), o segundo boot só pelo disco (NVRAM gravada) e se o archinstall copia o log pro sistema instalado. Apagar os discos do spike no fim e anotar os resultados (tempos reais × research R8) pra T013
- [ ] T003 [P] Fixar a chave de release do Arch em `lab/keys/archlinux-release.asc` (impressão digital `3E80CA1A8B89F69CBA57D98A76A5EF9054449A5C`, conferida contra o WKD e contra o chaveiro do pacman, sem mexer no chaveiro do host)

**Checkpoint**: o caminho desassistido está escolhido e medido; a configuração padrão passa no `--dry-run`.

---

## Phase 2: Foundational (contrato compartilhado)

**Purpose**: o que todos os comandos novos usam. **Depois do T005, os contratos ficam congelados.**

- [ ] T004 `lab/lib.sh`: `lock_get <chave> [campo]` (lê o `images.lock` no formato novo; uma linha sem `=` é `basic=<linha>`), `lock_set <chave> <linha>` (reescreve só a linha da chave), `disk_free_gb`, e `qemu_base_args <nome>` (os argumentos comuns do QEMU, tirados do `lab/up`); `lab/up` passa a usar `qemu_base_args` sem mudar a interface nem o comportamento (conferir comparando a linha de comando gerada antes e depois, sem ligar nenhuma camada existente); `lab/fetch` (sem argumento) lê a `basic` por `lock_get`
- [ ] T005 `lab/images.lock` no formato novo (`basic=…` + `iso=archlinux-2026.10.01-x86_64.iso sha256=…`), conforme contracts/images-lock.md. **Congela os contratos**

**Checkpoint**: lock, chave e argumentos do QEMU prontos.

---

## Phase 3: User Story 2 - A ISO é sempre a mesma e sempre conferida (Priority: P1)

**Goal**: a ISO fixada é baixada (mirror ou arquivo histórico) e só fica disponível depois do hash
duplo e da assinatura com a chave fixada.

**Independent Test**: `lab/fetch iso` conferindo a ISO; uma cópia com um byte trocado recusada; a
mais nova reescrevendo o lock.

- [ ] T006 [US2] `lab/fetch iso [--latest]` (contracts/lab-install-iso.md): download pra `*.part` do `geo.mirror.pkgbuild.com/iso/<v>/` com fallback pro `archive.archlinux.org/iso/<v>/`; sha256 contra o `sha256sums.txt` **e** o `sha256=` do lock; assinatura num `GNUPGHOME` temporário só com `lab/keys/archlinux-release.asc`, exigindo o `VALIDSIG` da impressão digital fixada; ISO somente leitura e `images/<iso>.verify.txt`; código 2 e `*.rejected` na recusa; `--latest` reescreve só a linha `iso=`. `NIER_LAB_ISO=<arquivo>` verifica outro arquivo (pra testar a recusa). `lab/fetch` sem argumento continua igual
- [ ] T007 [US2] Validar (quickstart, cenários 1 e 2): `lab/fetch iso` conferindo a ISO do spike; cópia com um byte trocado → código 2, `*.rejected`, nenhuma VM ligada (SC-004); o fallback do arquivo histórico com uma versão que já saiu do mirror (só os arquivos pequenos); `--latest` sem mudança de versão deixa o lock igual

**Checkpoint**: a ISO só chega à VM verificada.

---

## Phase 4: User Story 1 - Um comando instala o Arch pela ISO oficial (Priority: P1) 🎯 MVP

**Goal**: `lab/install-iso` entrega a camada `arch-iso` congelada, sem tecla, e prova o segundo boot.

**Independent Test**: dentro do `lab/perf`, `lab/install-iso`; depois uma camada descartável sobre a
`arch-iso` responde no SSH com `yes`, `btrfs`, `0`.

- [ ] T008 [P] [US1] `lab/iso/archinstall.json`: a configuração padrão que passou no `--dry-run` do spike (systemd-boot sem UKI, btrfs `@`/`@home`/`@log`/`@pkg` com `compress=zstd`, zram, NetworkManager, perfil mínimo, `en_US`/`us`, UTC, mirror `geo.mirror.pkgbuild.com`), sem `disk_config` (gerado), com as adaptações do lab (openssh + sshd, chave do lab, `/etc/sudoers.d/90-nier-lab`, hostname `nier-lab`) num bloco identificado (FR-014); nada que impeça acrescentar o Plymouth depois (decisão 2)
- [ ] T009 [P] [US1] `lab/iso/user-data` e `lab/iso/meta-data` (modelos do contrato archinstall-config.md, "Disco `cidata`"): só a chave do lab pro root e o marcador `RIEN-LAB-SEED-OK` na serial
- [ ] T010 [P] [US1] `lab/iso/check-arch-iso`: roda no sistema instalado (como `arch`, sudo sem senha) e imprime as conferências do contrato (`hostname`, `bootloader`, `root_fs`, `root_subvol`, `subvols`, `swap`, `network`, `online`, `system`, `failed_units`, `user`, `sudo_nopasswd`, `root_locked`, `kernel`, `packages`, `archinstall_log`) em `chave=valor`; um modo `--expect` compara com o esperado e devolve ≠ 0 se algo decisivo não bater (as dependentes da configuração viram informativas com `--config` próprio)
- [ ] T011 [P] [US1] `lab/ls` mostra `iso:<versão>` / `incompleta:<passo>` na coluna BASE (raiz sem link); `lab/rm` apaga também `<nome>.manifest.json` e `<nome>.creds`; `lab/new --from` recusa uma base `incompleta:*` e uma base que não está congelada só se for incompleta (o resto igual)
- [ ] T012 [US1] `lab/install-iso [<nome>] [--config] [--disk] [--snapshot] [--redo] [--keep-on-fail] [--timeout]`: os passos 0–10 do contrato (`preflight`, `iso`, `seed`, `boot-iso`, `ssh-iso`, `dry-run`, `install`, `collect`, `reboot`, `checks`, `freeze`), cada um como `lab/perf mark`; `disk_config` gerado de `--disk`; senha gerada em `vms/<nome>.creds` (600) e hash feito dentro da ISO por stdin; credenciais apagadas da ISO antes de desligar; `steps.tsv`, `serial.log`, `install.live.log`, `install.log`, `user_configuration.json`, `checks.txt`, `console.png`, `manifest.json` na pasta `out/install-iso-<data>/`, registrados no `perf_artifact`; `trap` de falha/interrupção (screendump, `quit`, limpeza ou `incompleta:<passo>`, códigos 1–6 e 130); padrão `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G`
- [ ] T013 [US1] Primeira execução completa (quickstart, cenários 4 e 5): `lab/perf begin "006: arch-iso pela ISO" --kind 006-s2 --task 006/T013`; `lab/install-iso`; código 0, `lab/ls` com `arch-iso` base `iso:2026.10.01`; `checks.txt` 100% (SC-003); tempo ≤ 20 min (SC-001), tempo de cada passo, download dos pacotes e disco da camada no relatório (SC-008)
- [ ] T014 [US1] Cenário 6 (SC-002, US1.2): `lab/new teste-iso --from arch-iso`, `lab/up teste-iso --soft`, SSH em ≤ 60 s, `bootctl is-installed; findmnt -no FSTYPE /; systemctl --failed --no-legend | wc -l` → `yes`, `btrfs`, `0`; conferências de novo pelo `lab/iso/check-arch-iso`
- [ ] T015 [US1] Cenário 8 (US1.4, FR-004): `lab/install-iso` de novo → código 1, nada muda; com `teste-iso` em cima, `lab/install-iso --redo` → recusa

**Checkpoint**: a fase S2 está entregue (o "pronto quando" do `PLAN.md`).

---

## Phase 5: User Story 3 - A camada nova serve de base pro resto do laboratório (Priority: P2)

**Goal**: a preparação da `hypr-base` roda sem mudança sobre uma camada da `arch-iso`, e nenhuma
camada existente muda.

**Independent Test**: `hypr-base.sh` na `teste-iso`, Hyprland + smoke no `lab/shot`; hashes das bases
iguais antes e depois.

- [ ] T016 [US3] Cenário 7 (SC-005): na `teste-iso`, mandar `lab/guest` + `lab/provision` por tar e rodar `LAB_TZ=UTC bash ~/lab-guest/hypr-base.sh` sem mudança; `lab/down`; `lab/up teste-iso` (3D); `lab/sync --src lab/smoke`; `lab/shot` com o Hyprland e o smoke da UI. O que a `hypr-base.sh` precisar a mais vira registro (não muda a camada)
- [ ] T017 [US3] Cenário 11 (SC-006): `sha256sum -c` dos discos de `basic`, `arch-limpo` e `hypr-base` tirados antes do T013; `lab/ls` sem diferença nas camadas que já existiam

**Checkpoint**: a `arch-iso` é base utilizável pra S3.

---

## Phase 6: User Story 4 - Uma falha deixa pistas e não deixa lixo (Priority: P3)

**Goal**: falhas param no passo certo, com logs e screenshot, sem camada pela metade.

**Independent Test**: configuração inválida e Ctrl+C no meio da instalação.

- [ ] T018 [US4] `lab/iso/testes/invalida.json` (recusada pelo `--dry-run` do archinstall) e o cenário 3 (SC-007, US4.1): código 4 em ≤ 3 min, mensagem do archinstall, `install` não começou no `steps.tsv`, nenhuma camada nova
- [ ] T019 [US4] Cenário 9 (US4.3): `lab/install-iso teste-int`, Ctrl+C (SIGINT) durante o passo `install` → código 130, VM desligada, sem `teste-int` no `lab/ls`, `console.png` e `install.live.log` parcial na pasta de saída; mesma rodada com `--keep-on-fail` → `incompleta:install` e `lab/new --from` recusa

**Checkpoint**: o comando falha de um jeito investigável.

---

## Phase 7: Polish & documentação

- [ ] T020 [P] `shellcheck` (container `koalaman/shellcheck:stable`, label `nier-lab`) limpo em `lab/install-iso`, `lab/fetch`, `lab/lib.sh`, `lab/up`, `lab/ls`, `lab/rm`, `lab/new`, `lab/iso/check-arch-iso`
- [ ] T021 Cenário 10 (SC-009): a senha da `arch-iso` não aparece em `$LAB_HOME/out/`, nos relatórios nem nos repositórios (busca → 0)
- [ ] T022 `lab/README.md`: árvore de camadas com a `arch-iso` ao lado, `lab/fetch iso` e `lab/install-iso` em "Uso no dia a dia", tempos e disco medidos, impressão digital da chave, e "Lições" da fase
- [ ] T023 `specs/006-arch-pela-iso/relatorio.md`: evidência por critério de sucesso com os ids do `lab/perf`, tempos, download e disco, desvios, a recomendação sobre o cache de pacotes (decisão 5) e o que fica pro dono

---

## Dependencies & Execution Order

- **Setup (T001–T003):** T001 → T002 (mesma VM, sequenciais); T003 independente.
- **Foundational (T004–T005):** depois do T003 (o lock usa o hash conferido); bloqueia tudo o que vem depois.
- **US2 (T006–T007):** depois do T005.
- **US1 (T008–T015):** T008–T011 em paralelo depois do T002 (a configuração vem do spike) e do T005;
  T012 depois de T006 e T008–T011; T013 → T014 → T015 (VM, sequenciais).
- **US3 (T016–T017):** depois do T014 (usa a `teste-iso`).
- **US4 (T018–T019):** depois do T012; VM, então em série com as outras histórias (uma VM por vez).
- **Polish:** T020 a qualquer momento depois do T012; T021–T023 no fim.

### Parallel Opportunities

- T003 junto com o spike; T008, T009, T010 e T011 entre si (arquivos separados, sem VM).
- Todas as tarefas com VM são **sequenciais**: o teto do dono é uma VM desta fase por vez.

## Parallel Example: User Story 1

```text
T008 lab/iso/archinstall.json
T009 lab/iso/user-data + meta-data
T010 lab/iso/check-arch-iso
T011 lab/ls, lab/rm, lab/new
```

## Implementation Strategy

1. **MVP:** Setup → Foundational → US2 → US1 (T013 é o "pronto quando" da S2).
2. **Depois:** US3 (prova que a camada serve de base) e US4 (falhas).
3. **Fim:** shellcheck, busca da senha, README e relatório.
