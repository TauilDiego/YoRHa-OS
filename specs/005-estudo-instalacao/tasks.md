---
description: "Tarefas da 005: estudo de instalação (U2)"
---

# Tasks: Estudo de instalação (U2)

**Input**: `specs/005-estudo-instalacao/` (plan.md, spec.md, research.md, experimentos.md, data-model.md,
contracts/, quickstart.md)

**Tests**: a fase **é** um teste. Não há testes automatizados; a prova de cada tarefa é a evidência da VM
(princípio IV): registro da execução (`contracts/run.schema.json`), screenshot, resposta de `yorha version`
e do IPC da UI, log de QML, sempre dentro de `lab/perf begin "…" --kind 005-u2 --task 005/<T>` …
`lab/perf end`, com `NIER_LAB_VM` exportado.

**Caminhos**:
- `specs/…`, `docs/…` = repositório público (worktree `YoRHa-OS-wt/spec005`, branch `005-estudo-instalacao`);
- `lab/u2/…` = repositório privado (worktree `YoRHa-OS-private-wt/lab-u2`, branch `lab-u2`).

**Limite do dono (2026-10-27):** uma VM por vez, `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G`. Os protótipos são
independentes (`[P]`), mas todas as execuções na VM são sequenciais.

**Fixado antes de medir (experimentos §6.1):**
- **commit da carga:** `422cca7` (último commit que mexe no `shell/`, vindo da 004);
- **mirror:** Arch Linux Archive de **2026-10-26**, servido por um cache no servidor do lab;
- **critérios, pesos e notas:** experimentos §5, sem mudança (decisão 4 do dono).

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: história da spec (US1–US5)

---

## Phase 1: Setup (decisões e fixação)

- [x] T001 Merge da `004-wallpaper-system` na `005-estudo-instalacao` (traz o `shell/`, a carga) e registrar as decisões do dono em `spec.md`, `plan.md`, `experimentos.md` e `checklists/requirements.md`, trocando as escolhas abertas
- [x] T002 Fixar o commit da carga (`422cca7`), a data do mirror (2026-10-26) e os pesos num commit desta branch, antes da primeira medição (R16, experimentos §6.1)

---

## Phase 2: Foundational (lab: base, servidor, fábrica, carga, roteiro)

**⚠️ Nenhum protótipo é medido antes desta fase terminar.** Tudo no privado, em `lab/u2/`.

- [ ] T003 `lab/u2/lib.sh` (variáveis comuns: `U2_HOME=~/.local/share/nier-lab/u2`, porta do servidor, data do mirror, commit da carga) e `lab/u2/imagem/Dockerfile`: imagem `nier-lab-u2` (Arch no mirror fixo, com `python`, `git`, `base-devel`, `gnupg`, `qt6-shadertools`, `pacman-contrib`), usada pela fábrica e pelo servidor
- [ ] T004 `lab/u2/servidor up|down|log|stall|drop` + `lab/u2/servidor.py`: container `nier-lab` em `127.0.0.1:<porta>` que serve `srv/` estático e faz cache do Arch Linux Archive da data fixa em `/archive/`, registrando bytes por pedido (separa carga × dependências); `stall <padrão>` segura um download pela metade (S6a, S7b)
- [ ] T005 `lab/u2/base` + `lab/u2/guest/` (`u2-base.sh`, `hyprland.lua`, `u2-ui-run`, arquivos do usuário de exemplo): cria `u2-base` da `arch-limpo` (mirror pelo cache, Hyprland, uwsm, kitty, grim, login automático; **sem** Quickshell, Qt 6 extra, `qt6-shadertools`, `jq`, `git`). Conferir: `qt6-imageformats` ausente, `findmnt -no FSTYPE /` (R9). Congelar com `lab/freeze`
- [ ] T006 `lab/u2/carga <versão>` + `lab/u2/carga/` (`0.2.patch`, `0.3.patch`, `migrations/`, `webp`): árvores 0.1, 0.2 e 0.3 a partir de `git archive 422cca7 shell` (data-model "Versão da carga"); o `shell/` do público não muda
- [ ] T007 `lab/u2/fabrica <método> <versão>`: no container, chave descartável do lab e chave "atacante" (`U2_HOME/gnupg`), e os artefatos de cada método (A: repositório git com tags assinadas; B: receita + `.SRCINFO` + tarball; C: `makepkg --sign` + `repo-add --sign`; D: tarball + `sha256` + assinatura + `latest`)
- [ ] T008 `lab/u2/publicar <método> <versão>` e `lab/u2/adulterar <método> carga|tudo` (S8a/S8b)
- [ ] T009 `lab/u2/rodar <método> <cenário…> [--n N] [--from <camada>]` + `lab/u2/registro.py`: cria a VM, mede (tempo, `ui_s`, bytes no log do servidor, `sudo` no journal, soma de `~/.config`, disco), tira screenshot, grava o registro do `run.schema.json` em `~/.local/share/nier-lab/out/u2/<m>/` e apaga a VM
- [ ] T010 `lab/u2/tabelas`: mediana, mínimo e máximo por método e cenário, e a matriz com a conta (pesos do dono e pesos iguais)

**Checkpoint**: servidor no ar, `u2-base` congelada, três versões da carga, artefatos dos quatro métodos.

---

## Phase 3: User Story 1 — instalar e atualizar pelos quatro métodos, medindo (P1) 🎯 MVP

**Goal**: os quatro protótipos cumprem o contrato e passam por S1–S4 três vezes.

**Independent Test**: `lab/u2/rodar <m> S1 S4 S2 S3` numa VM nova: screenshot da 0.1 e da 0.2, `yorha version`,
`wallpaper.json` com `format: 2`, `~/.config` igual, registro e relatório `lab/perf`.

- [ ] T011 [P] [US1] Protótipo A em `lab/u2/metodo-a/` (`boot.sh`, `install.sh`, `bin/yorha`, `PUBLICAR.md`): clone por tag, `install.sh` com `pacman -S --needed`, `git verify-tag`, backup de arquivo gerenciado editado, sem `pull`/`reset --merge` (R1)
- [ ] T012 [P] [US1] Protótipo B em `lab/u2/metodo-b/` (`PKGBUILD`, `yorha-os.install`, `bin/yorha`, `PUBLICAR.md`): pacote de versão, shaders no `build()`, update = `git pull` + `makepkg -si`, migrations no `yorha-shell` (R3, R8)
- [ ] T013 [P] [US1] Protótipo C em `lab/u2/metodo-c/` (`PKGBUILD`, `yorha-os.conf`, `bin/yorha`, `PUBLICAR.md`): chave + bloco `[yorha-os]`, update = `pacman -Syu` + migrations, aviso por `checkupdates` (R4, R10)
- [ ] T014 [P] [US1] Protótipo D em `lab/u2/metodo-d/` (`install-d.sh`, `bin/yorha`, `PUBLICAR.md`): `versions/<v>`, troca atômica de `current` (`mv -T`), backup do estado antes da migration, `yorha rollback` (R5)
- [ ] T015 [US1] Validação (repetição 0, não conta): `lab/u2/rodar <m> S1 --n 0` pros quatro; o que passar vira `prototipado` e gera a camada `u2-<m>-v01` (0.1 instalada), congelada, base das execuções de função
- [ ] T016 [US1] Execuções de tempo: S1 → S4 → S2 → S3 encadeados numa VM nova por método e rodada, nas ordens A B C D, D C B A, A B C D (experimentos §6.4)

**Checkpoint**: 12 cadeias medidas, os quatro métodos `medido` no caminho feliz.

---

## Phase 4: User Story 3 — volta, interrupção e recuperação (P2)

**Independent Test**: num método, `rodar <m> S5` e `S6a|b|c` a partir de `u2-<m>-v01`; registro com `recovery`.

- [ ] T017 [US3] S5 (0.2 → 0.3 quebrada → volta pra 0.2) nos quatro métodos
- [ ] T018 [US3] S6a/b/c (desligamento no download, na troca dos arquivos e na migration) nos quatro métodos, com a recuperação seguida até a UI responder
- [ ] T019 [US3] S7a/b (servidor fora do ar na instalação e no meio do update) nos quatro métodos

---

## Phase 5: User Story 4 — confiança (P2)

- [ ] T020 [US4] S8a (carga trocada) e S8b (carga e metadados regerados sem a chave do dono) nos quatro métodos; registrar o que o usuário confia na instalação

---

## Phase 6: User Story 5 — custo de manter (P2)

- [ ] T021 [US5] S12: seguir o `PUBLICAR.md` de cada método, do commit pronto até a 0.2 disponível, cronometrando passos, segredos e infraestrutura (no container da fábrica)
- [ ] T022 [US5] Avaliação escrita: o mesmo método serve pro módulo pessoal (repositório privado)? Com qual custo (FR-012, US5 #2)

---

## Phase 7: Casos de borda (spec, Edge Cases)

- [ ] T023 S9 (segundo usuário), S10 (arquivo gerenciado editado) e S11 (desinstalar) nos quatro métodos
- [ ] T024 B-ref: numa `u2-base` nova, instalar o `yay` do AUR real e um pacote de shell Quickshell que existe lá, só leitura (decisão 1)
- [ ] T025 S13 (opcional, decisão 3): o tema de cursor como segunda carga, montado no destino (A, D) × pronto no pacote (B, C), se houver tempo

---

## Phase 8: User Story 2 — o documento e a escolha (P1, depende de todas as outras)

- [ ] T026 [US2] `lab/u2/tabelas` com todos os registros; matriz critério × método com nota, justificativa e ids de execução ou R-n; eliminados pelos G1–G3
- [ ] T027 [US2] Conferir no wiki do Arch ao vivo as citações que vieram do espelho de abril de 2026 (research: R3, R4, R13); marcar as que não der pra conferir
- [ ] T028 [US2] Escrever `docs/estudo-instalacao.md` (experimentos §7): resumo, como foi medido, matriz, eliminados, medidas, falhas, entradas pra S3 e S4, pesquisa, ameaças, riscos
- [ ] T029 Conferência final: SC-001…SC-007 contra os registros, princípios I, IV e V, `/speckit-analyze` leve; `lab/ls` sem VM `u2-*-<n>` sobrando; `lab/u2/servidor down`
- [ ] T030 `lab/README.md` (privado): seção do `lab/u2/` em "Uso no dia a dia"; commits nas duas branches

---

## Dependencies & Execution Order

- **Setup (1)** → **Foundational (2)** → **US1 (3)**: os protótipos (T011–T014) são `[P]` entre si, mas
  todos dependem de T003–T009.
- **US3, US4, US5 e borda (4–7)** dependem do T015 (camadas `u2-<m>-v01`). Entre si são independentes,
  mas rodam em sequência pelo limite de uma VM.
- **US2 (8)** depende de tudo; é P1 porque é o "pronto quando" da fase.

## Parallel Example

```text
# Protótipos, em arquivos diferentes (só escrita; a validação na VM é sequencial):
T011 lab/u2/metodo-a/   T012 lab/u2/metodo-b/   T013 lab/u2/metodo-c/   T014 lab/u2/metodo-d/
```

## Implementation Strategy

1. **MVP:** fases 1–3 (o caminho feliz medido nos quatro) já permitem uma comparação parcial.
2. **Falhas e confiança** (4–5) decidem K2–K5; **manutenção** (6) decide K6, o maior peso.
3. **Se um método crescer muito além do previsto**, ele é cortado no que decide a comparação, e o documento
   diz o que foi cortado.
