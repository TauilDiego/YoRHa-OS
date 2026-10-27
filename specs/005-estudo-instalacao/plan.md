# Implementation Plan: Estudo de instalação (U2)

**Branch**: `005-estudo-instalacao` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-estudo-instalacao/spec.md` (rascunho, escrito junto com
este plano a pedido do dono; **os dois aguardam aprovação**)

## Summary

A fase compara quatro jeitos de entregar e atualizar a camada (A script + git, B AUR, C repositório
pacman próprio, D versões lado a lado), usando a UI de verdade (`shell/`) como carga. Pra cada método
existe um **protótipo descartável** que cumpre o mesmo [contrato de entrega](contracts/contrato-de-entrega.md)
(`rien-shell`, `rien version`, `rien update [--check]`, `rien rollback`, `rien migrate`, `rien uninstall`).

Os protótipos rodam em VMs novas, criadas de uma camada própria (`u2-base`, um Arch com Hyprland mas
sem as dependências da UI). Eles buscam a carga num **servidor de distribuição** num container do lab,
que simula GitHub, AUR, repositório pacman e pacotes de versão, sem publicar nada. Os pacotes e as
assinaturas saem de uma **fábrica** em outro container, com uma chave descartável.

São 13 cenários ([experimentos.md](experimentos.md) §4):
- **o caminho feliz:** instalar, atualizar, repetir o update, aviso de update;
- **as falhas:** versão quebrada e volta, interrupção em três pontos, sem rede, carga adulterada;
- **casos de borda:** segundo usuário, arquivo gerenciado editado, desinstalar;
- **o lado do dono:** publicar uma versão.

Cada execução grava um registro ([contracts/run.schema.json](contracts/run.schema.json)) e fica dentro de
`lab/perf`. Os critérios, os pesos e as notas são fixados antes de medir (experimentos §5). O resultado é
`docs/estudo-instalacao.md`, com a matriz, a conta, a escolha e as entradas pra S3 e S4.

A pesquisa ([research.md](research.md)) já trouxe três fatos que moldam o desenho:
- **o Omarchy v4 saiu do git pra pacotes do sistema** (R2), e com isso as migrations por usuário foram
  pro login (R8);
- **o `quickshell` está no `[extra]`** (R7): nenhum método precisa levar um Quickshell próprio nem
  recompilar quando o Qt muda;
- **os problemas reais do modelo A** (pull de branch, `reset --merge`, migration que trava a fila) já têm
  correção conhecida (R1), e o protótipo A já nasce com ela.

**Hipótese de partida, a testar:** A+D (tags do git + versões lado a lado com troca atômica) ganha em
custo e volta; C ganha em confiança e desinstalação; B perde em manutenção (experimentos §1).

## Technical Context

**Language/Version**: Bash 5 (protótipos e roteiros do lab); PKGBUILD/makepkg (B, C); JSON (registros).
A carga é QML (Qt 6) sobre Quickshell 0.3.x, sem mudança no `shell/`.

**Primary Dependencies**:
- no cliente (VM): `pacman`, `git`, `curl`, `base-devel` (B), `pacman-contrib` (`checkupdates`, C),
  `gnupg` (verificação em D), `quickshell` e Qt 6 do `[extra]` (dependências da carga);
- na fábrica (container): `makepkg`, `repo-add`, `gpg`, `qsb` (`qt6-shadertools`);
- no servidor (container): um servidor HTTP estático que registra bytes por pedido;
- no lab: `lab/new`, `lab/up`, `lab/ssh`, `lab/shot`, `lab/perf`, QMP (desligamento forçado).

**Storage**: arquivos. Na VM, os caminhos do contrato (`~/.local/share/rien-os/`, `/usr/share/rien-os/`,
`~/.local/state/rien-os/`). No lab, `~/.local/share/nier-lab/u2/` (chave descartável, artefatos,
registros). No público, só `docs/estudo-instalacao.md`.

**Testing**: o estudo **é** o teste. Cada cenário gera um registro com evidência (screenshot com sha256,
resposta de IPC, log de QML, relatório `lab/perf`). Validação dos protótipos pela repetição 0 do S1. Sem
testes unitários (constituição VII).

**Target Platform**: Arch Linux x86_64, Hyprland 0.56+ (Lua), na VM do lab (`u2-base`), perfil `1080`,
4 CPUs e 4 GB por VM.

**Project Type**: estudo comparativo com protótipos de instalador (CLI em shell); entrega um documento.

**Performance Goals**: sem meta de desempenho. As medidas de tempo servem pra comparar métodos entre si,
na mesma VM (experimentos §8).

**Constraints**:
- nada no host além das ferramentas do lab (constituição I); build só em container;
- nada publicado de verdade (FR-005);
- nenhuma escrita em `~/.config` (constituição III, G1);
- chave de assinatura descartável, fora de qualquer git (constituição: segredos);
- execuções de tempo com uma VM por vez; as de função podem ir em paralelo;
- os pesos ficam fixos antes da primeira medição.

**Scale/Scope**: 4 protótipos + 1 execução de referência (yay real); 13 cenários; ≈ 36 execuções de
tempo e ≈ 50 de função; 3 versões de carga; 1 documento.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Status |
|---|---|---|
| I. Sistema do dono intocável | Protótipos, instalação, `makepkg`, `repo-add` e assinatura rodam só em VM e containers `nier-lab` sem privilégio. O servidor de distribuição é um container com porta só em `127.0.0.1`. No host, só QEMU, Docker, `ssh`, `rsync` e o `lab/perf`. Nenhum pacote novo no host. A chave é do lab, não do dono. O SC-004 confere nos relatórios | ✅ |
| II. Camada sobre Arch limpo | Todo método parte de uma `u2-base` (Arch limpo + sessão) e põe a camada por cima; nenhum gera imagem. O D guarda versões da camada, não do sistema | ✅ |
| III. Padrões × arquivos do usuário | O contrato proíbe escrever em `~/.config`; toda execução compara a soma de `~/.config` antes e depois (G1, elimina). Migrations idempotentes, com backup antes de escrever, e o S3 prova a idempotência. O S10 mede o que cada método faz com arquivo gerenciado editado | ✅ |
| IV. Pronto exige evidência da VM | Cada SC tem prova no [quickstart.md](quickstart.md): registro, screenshot, IPC, log, `lab/perf`. O documento só aceita célula com execução ou fonte | ✅ |
| V. Spec antes de código | Spec e plano escritos juntos, **ambos aguardando o dono**; nenhum protótipo antes da aprovação e do `/speckit-tasks` | ✅ (pendente de aprovação) |
| VI. Paralelizar | O contrato de entrega e o formato do registro vêm antes e congelam. Os 4 protótipos (e os cenários de função) vão em paralelo, um agente por método, cada um com worktree e VM `u2-<m>-<n>` (porta própria). As execuções de tempo ficam sequenciais de propósito, pra não contaminar a medida. Não usa `teste-a/b/c` | ✅ |
| VII. Simplicidade | Protótipos mínimos (sem menu, canais nem indicador); A+D avaliada por composição, sem quinto protótipo; AUR simulado por git + `makepkg` em vez de um AUR falso com API | ✅ |
| Restrições: segredos | A chave descartável fica em `~/.local/share/nier-lab/u2/`; o documento público não cita portas, chaves nem caminhos da máquina do dono | ✅ |
| Restrições: licença | Ideias do Omarchy (MIT) e do Capistrano entram como referência; se um trecho for copiado num protótipo, vai com crédito. Os protótipos ficam no privado | ✅ |
| Restrições: marcas | Nada do jogo entra; a carga é a UI do projeto | ✅ |

**Re-check pós-design (Fase 1):** sem violações. Três notas:
- **Servidor em container no host:** é ferramenta de teste (Docker já é permitido pelo princípio I); ele
  só serve arquivos estáticos e não roda código do projeto.
- **Execução de referência com o AUR real (B-ref):** baixa do AUR **dentro da VM**; não publica nada.
- **O `shell/` não muda nesta fase:** as versões 0.2 e 0.3 são remendos aplicados no lab sobre uma cópia.

## Project Structure

### Documentation (this feature)

```text
specs/005-estudo-instalacao/
├── spec.md
├── plan.md               # este arquivo
├── research.md           # Fase 0: R1–R16, com fontes
├── experimentos.md       # Fase 1: desenho dos experimentos (ambiente, protótipos, cenários, critérios, protocolo)
├── data-model.md         # Fase 1: método, versão, cenário, execução, critério, matriz
├── quickstart.md         # Fase 1: como rodar no lab privado
├── contracts/
│   ├── contrato-de-entrega.md   # interface comum dos protótipos (comandos, caminhos, migrations)
│   └── run.schema.json          # formato do registro de uma execução
├── checklists/requirements.md
└── tasks.md              # /speckit-tasks (ainda não)
```

### Source Code (repository root)

No repositório público, a fase só acrescenta o documento:

```text
docs/
└── estudo-instalacao.md     # o resultado (FR-015)
```

No repositório privado (`rien-OS-private`), ao lado do lab que já existe:

```text
lab/u2/
├── base                 # cria a u2-base
├── carga                # gera 0.1/0.2/0.3 a partir do commit fixado
│   ├── 0.2.patch        # texto de versão no HUD, dependência nova, leitura do formato 2
│   ├── 0.3.patch        # erro de QML de propósito
│   └── migrations/      # wallpaper-format-2.sh, wallpaper-format-3.sh
├── fabrica              # container: tarball, receita, makepkg --sign, repo-add --sign
├── servidor             # container: HTTP estático com log de bytes
├── publicar · adulterar · rodar · tabelas
├── guest/u2-ui-run      # abre rien-shell quando ele existir
├── metodo-a/            # boot.sh, install.sh, bin/rien, PUBLICAR.md
├── metodo-b/            # PKGBUILD, rien-os.install, bin/rien, PUBLICAR.md
├── metodo-c/            # PKGBUILD (o mesmo de B), pacman.conf.d/rien-os.conf, bin/rien, PUBLICAR.md
└── metodo-d/            # install-d.sh, bin/rien, PUBLICAR.md
```

**Structure Decision**: protótipos, roteiros e chave no privado (R15, FR-017); conclusões no público.
Quando a S3 começar, o método escolhido é reescrito no público na estrutura do `PLAN.md` §5 (`boot.sh`,
`install/`, `bin/`, `migrations/`).

## Fases de trabalho (pra o `/speckit-tasks`)

1. **Contrato e critérios congelados:** contrato de entrega, formato do registro e experimentos §5
   commitados (já nesta branch); fixar o commit da carga e a data do mirror.
2. **Fundação do lab** (sequencial): `u2-base`, servidor, fábrica, `carga`, `rodar` (com a coleta do
   registro e das evidências), `tabelas`.
3. **Protótipos** `[P]`: A, B, C e D em paralelo, cada um validado pela S1 #0.
4. **Execuções de tempo** (sequencial): S1–S4 (+ S13), 3 rodadas em ordem alternada.
5. **Execuções de função** `[P]`: S5–S12 por método, mais a B-ref.
6. **Documento:** tabelas, matriz, conta (com pesos de partida e iguais), escolha, entradas pra S3/S4;
   rever as citações do wiki no site ao vivo.
7. **Revisão:** `/speckit-analyze`, conferência dos princípios I, IV e V, e homologação do dono.

## Complexity Tracking

Nenhuma violação da constituição a justificar.
