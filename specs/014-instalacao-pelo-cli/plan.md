# Implementation Plan: Instalação e encaixe do shell, v0 pelo CLI

**Branch**: `014-instalacao-pelo-cli` | **Date**: 2026-11-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/014-instalacao-pelo-cli/spec.md`

## Summary

O YoRHa-OS ganha um jeito de ser instalado e atualizado numa máquina de verdade, só pelo terminal.
Partes:
- **`install.sh`:** confere as dependências e põe a versão em `~/.local/share/yorha-os/`, no método D
  do estudo 005.
- **CLI `yorha`:** `update`, `rollback`, `shell`, `ipc`, `boot-login` e `uninstall`.
- **Arquivo de encaixe:** o Hyprland da pessoa inclui com uma linha.
- **No shell:** um serviço que avisa a versão nova e SYSTEM › Updates › "Update now".

O canal de versões da v0 é o próprio repositório local: um servidor do lab lê a `main` (ou um worktree)
e cada commit vira uma versão. É isso que deixa o dono testar se as correções futuras chegam numa
máquina instalada.

## Technical Context

**Language/Version**:
- bash 5 (`install.sh` e `yorha`), como o protótipo D;
- QML / Qt 6 com Quickshell 0.3 (o shell);
- Lua (o arquivo do Hyprland 0.56);
- python 3 só com a biblioteca padrão (o canal do lab, no host).

**Primary Dependencies**:
- **No destino:** `curl`, `tar`, `sha256sum`, `pacman`, `sudo` e o manifesto `system/deps`
  (research R3).
- **No host:** `git` 2.55, por causa do `git archive --add-virtual-file`.

**Storage**: Arquivos nas pastas do produto (data-model.md). Sem banco.

**Testing**: VMs do lab (`lab/check-014` + os roteiros 003, 004, 007, 008 e 013), medidas com o
`lab/perf`.

**Target Platform**: Arch Linux com Hyprland 0.56+ (config em Lua). O Niri fica fora da v0.

**Project Type**: CLI + shell desktop (Quickshell) + scripts do lab.

**Performance Goals**:
- `update` de uma versão de ~12 MB em segundos, na rede do lab;
- o Updater do shell não pesa (uma conferência por hora, um processo curto).

**Constraints**:
- **Isolamento:** nada fora das pastas do produto sem perguntar (constituição 2.0.0, princípio II);
- **Versão em uso:** a que está em uso nunca é tocada antes da troca atômica;
- **Root:** só por `sudo`, depois de um "s".

**Scale/Scope**: Uma pessoa por máquina; 3 versões guardadas; ~20 tarefas.

## Constitution Check

*Conferido antes da pesquisa e de novo depois do desenho.*

| Princípio | Como a 014 cumpre |
|---|---|
| I. O sistema do dono é intocável | Tudo roda nas VMs. No host, só o canal (python do lab, lendo o git) e o `lab/perf` |
| II. Sistema visual sobre um Arch limpo | Pastas próprias; o `hyprland.lua` é da pessoa (uma linha que ela inclui); dependências e boot-login só com "s" e `sudo`; desinstalar e desfazer existem |
| III. Padrões separados dos arquivos do usuário | As versões são imutáveis; `~/.config/yorha-os` nunca é escrito; migrations marcadas; cópia do estado antes do update |
| IV. Pronto exige evidência da VM | `lab/check-014` com screenshots, IPC e log de QML, medido |
| V. Spec antes de código | Spec aprovada em 01.11; este plano vai pro dono |
| VI. Paralelizar | Três frentes possíveis depois da fundação (abaixo), só se o dono quiser |
| VII. Simplicidade | bash do protótipo; sem servidor, AUR, TUI ou systemd na v0 |

Nenhuma violação. Os dois ajustes na spec vêm da pesquisa e são pro dono aprovar junto com o plano:
- **FR-017:** o cursor fica fora da v0 (research R8);
- **SC-007:** os roteiros antigos rodam como hoje, e o shell instalado é conferido pelo `check-014`
  (research R9).

## Project Structure

### Documentation (this feature)

```text
specs/014-instalacao-pelo-cli/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/   cli.md · canal.md · encaixe.md · updater.md
└── tasks.md     (o /speckit-tasks)
```

### Source Code (repository root)

```text
install.sh                     # novo: o instalador (vem pelo canal)
bin/yorha                      # novo: o CLI (do protótipo D)
lib/yorha/                     # novo: name.sh (o nome num lugar só), common.sh (do protótipo), deps.sh
migrations/                    # novo: vazio na v0, com um README
system/deps                    # novo: o manifesto de dependências
system/hypr/yorha-os.lua       # novo: o encaixe
shell/services/Updater.qml     # novo: conferência, aviso, updateNow, IPC `updates`
shell/services/NotifyStore.qml # system() ganha uma ação opcional
shell/services/Sounds.qml      # sem /usr/share
shell/services/Compositor.qml  # YORHA_OS_COMPOSITOR (aceita NIER_*)
shell/services/Fixtures.qml    # YORHA_OS_FIXTURES (aceita NIER_*)
shell/fixtures/settings-default.json  # a categoria `updates`
shell/settings/SettingsPage.qml       # a ação `update-now` chama o Updater
shell/strings/Strings.qml             # os textos de Updates

../YoRHa-OS-private/lab/
├── 014/canal                  # o servidor do canal (python, no host)
├── 014/prep                   # deixa a VM t014 com um hyprland.lua comum
├── 014/hyprland-limpo.lua     # o hyprland.lua de uma pessoa comum, com a linha do encaixe
├── check-014                  # o roteiro, por blocos
└── README.md                  # a seção da 014
```

**Structure Decision**: O produto ganha `install.sh`, `bin/`, `lib/yorha/`, `migrations/`,
`system/deps` e `system/hypr/`, como o `PLAN.md` §5 já prevê. O lab ganha a pasta `014/` e o
`check-014`, no padrão das outras specs.

## Fases

1. **Setup:**
   - o canal no lab;
   - a camada `t014`;
   - o esqueleto do `check-014`;
   - o worktree descartável `t014-canal`.
2. **Fundação** (sequencial, contrato estável): `lib/yorha/name.sh` e `common.sh`, o formato da versão
   e o `bin/yorha` com `version`/`status`.
3. **Frentes** (paralelizáveis, cada uma com VM própria, se o dono quiser):
   - **A, instalar e atualizar** (US1, US2, US6): `install.sh`, `system/deps`, `update`, `rollback`,
     `migrate`, `uninstall`;
   - **B, encaixe e shell instalado** (US4, US5): `shell start/restart`, `ipc`,
     `system/hypr/yorha-os.lua`, caminhos e nomes (R8), `boot-login`;
   - **C, o aviso** (US3): `Updater.qml`, `NotifyStore.system` com ação, a categoria `updates`, o
     "Update now".
4. **Junção:**
   - o `check-014` inteiro;
   - a regressão 003, 004, 007, 008 e 013;
   - o README e o design system;
   - a sessão do dono numa janela da VM: instalar, commitar uma correção e ver chegar.

## Complexity Tracking

Sem violações a justificar.
