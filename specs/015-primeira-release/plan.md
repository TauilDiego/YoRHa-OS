# Implementation Plan: Primeira release pública

**Branch**: `015-primeira-release` | **Date**: 2026-11-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/015-primeira-release/spec.md` (aprovada pelo dono em 02.11)

**Status**: aprovado pelo dono em 02.11 ("aprovadoooo"), com a emenda 2.1.0 e os três ajustes na spec, já aplicados

## Summary

A v0 da 014 instala e atualiza, mas só a partir do canal do lab. A 015 leva isso pro público.

As partes:
- **O canal público:** as releases do GitHub, lidas pelos endereços comuns de `github.com`, sem a API
  e sem o limite de acessos dela. O canal do lab passa a imitar os mesmos endereços (R1).
- **Os números de versão:** `MAJOR.MINOR.PATCH` de verdade. Ser versão de teste é só uma marca da
  release, e promover pra estável não remonta o pacote (R2).
- **As origens:** um arquivo com a origem principal e os espelhos. O espelho da VPS entra na 016 sem
  mexer no código (R3).
- **Montar e publicar:** uma ferramenta do lab, `lab/015/release`, monta, confere, publica e promove.
  O pacote testado é o mesmo que sobe (R4).
- **O nome YoRHa-Shell:** aplicado por uma tabela. O QML ganha um singleton `Product`, e o nome sai
  do código (R5).
- **A troca de nome:** a 0.1.0 já sai sabendo entregar o fim do update pra versão nova. É isso que
  deixa uma troca futura de nome sair como um update comum, sem editar o `hyprland.lua` da pessoa
  (R6).
- **O sinal de update:** fica na barra e no menu, com cinco formas, e a conferência automática pode
  ser desligada (R7, R8).
- **O repositório em ordem:**
  - uma auditoria antes do push;
  - o push e a renomeação do repositório;
  - as branches velhas apagadas;
  - o lint verde, com o motivo de ele nunca ter rodado investigado (R9).

## Technical Context

**Language/Version**:
- bash 5 (`install.sh`, `yorha`, `lib/yorha/`);
- QML / Qt 6 com Quickshell 0.3 (o shell);
- Lua (o encaixe do Hyprland);
- python 3, só com a biblioteca padrão (o canal e a ferramenta de release do lab, no host).

**Primary Dependencies**:
- **No destino:** `curl` (agora com `-L`), `tar`, `sha256sum`, `pacman`, `sudo` e o manifesto
  `system/deps`. Nada novo.
- **No host:** `git` (o `git archive --add-virtual-file`) e `gh`, que já está instalado e
  autenticado e só é usado pra publicar, com o OK do dono.

**Storage**: Arquivos (data-model.md). Sem banco.

**Testing**: VMs do lab com o `check-015` em blocos e a regressão (003, 004, 007, 008, 013 e o 014
adaptado), medidas pelo `lab/perf` (quickstart.md).

**Target Platform**: Arch Linux com Hyprland 0.56+ (config em Lua).

**Project Type**: CLI + shell desktop (Quickshell) + ferramentas do lab.

**Performance Goals**:
- a conferência faz um pedido pequeno por hora, por máquina;
- instalar e atualizar um pacote de uns 10 MB leva segundos.

**Constraints**:
- **Princípio I:** nada do projeto roda no host. Montar a release é `git archive`, `sha256sum` e
  cópia de texto.
- **Princípios II e III:** o `hyprland.lua` e a config da pessoa nunca são editados, nem na troca de
  nome.
- **Publicar** (push, renomear, apagar, publicar, promover) só acontece com o OK do dono, um passo de
  cada vez.

**Scale/Scope**: Uma pessoa por máquina; 2 canais; 1 origem na 0.1.0 (2 no lab); ~35 tarefas.

## Constitution Check

*Conferido antes da pesquisa e de novo depois do desenho.*

| Princípio | Como a 015 cumpre |
|---|---|
| I. O sistema do dono é intocável | Tudo roda nas VMs. No host, só ferramentas do lab: o canal e o `release` (python3 e `git`, sem executar código do projeto; a fonte do boot é regerada na VM) e o `gh` pra publicar, com o OK do dono |
| II. Sistema visual sobre um Arch limpo | Pastas próprias, com o nome novo. A troca de nome deixa a linha antiga funcionando por um arquivo de compatibilidade e só avisa a linha nova |
| III. Padrões separados dos arquivos do usuário | A config da pessoa muda de pasta com um link no caminho antigo, sem mudar o conteúdo. Update nunca edita arquivo da pessoa |
| IV. Pronto exige evidência da VM | Cada cenário do quickstart diz a evidência: screenshot, comando ou log |
| V. Spec antes de código | Spec aprovada em 02.11; este plano vai pro dono |
| VI. Paralelizar | Quatro frentes depois da fundação, cada uma com agente, worktree e VM próprios (R11) |
| VII. Simplicidade | Um formato de endereços pras três origens; nada de servidor, API, `jq` ou assinatura na 0.1.0 |
| Restrições, Marcas | **Emenda 2.1.0 (FR-016), abaixo.** Nada do jogo no pacote, conferido pela montagem (contracts/nome.md) |
| Restrições, Segredos | O `gh` usa a autenticação do host; nenhum token vai pra arquivo do repositório |

Nenhuma violação. Pro dono aprovar junto com o plano:

**A emenda da constituição (FR-016), 2.0.0 → 2.1.0 (MINOR):**
- **Título:** "YoRHa-OS Constitution" vira "YoRHa-Shell Constitution".
- **Abertura:** sai o "Nome provisório.".
- **Restrições, Marcas:** a regra fica assim:
  > NieR e YoRHa são marcas da Square Enix. O nome público, YoRHa-Shell, usa YoRHa por escolha do
  > dono (02.11.2026): o projeto é gratuito, de fã, sem ligação com a Square Enix, e diz isso no
  > README. Nada de fontes (FOT-Rodin), sons, logos ou vídeos do jogo no repositório nem nos pacotes.
  > Se um dia for preciso, o nome muda por um update comum (o produto sabe trocar de nome).
- **Sync Impact Report:** ganha a entrada da 2.1.0.

**Três ajustes na spec que vieram da pesquisa:**
1. **FR-017:** "trocar o comando e a linha do `hyprland.lua` (avisando a pessoa)" passa a ser:
   - o comando antigo vira um atalho pro novo;
   - a linha antiga continua funcionando por um arquivo de compatibilidade;
   - a pessoa é avisada da linha nova;
   - o arquivo dela nunca é editado (princípios II e III; R6).
2. **SC-010:** "em uma hora" passa a ser "em 3 minutos, com os timers parados no `updates dump`"
   (R8). O primeiro pedido sairia aos 30 s, e esperar uma hora não prova mais nada.
3. **FR-002:** a variável do canal vira duas: `YORHA_ORIGIN` (o endereço) e `YORHA_CHANNEL` (`stable`
   ou `testing`), no lugar de `YORHA_OS_CHANNEL` (R3).

## Project Structure

### Documentation (this feature)

```text
specs/015-primeira-release/
├── plan.md
├── research.md      R1–R11
├── data-model.md
├── quickstart.md
├── contracts/       canal-publico.md · cli.md · release.md · nome.md · sinal.md
├── checklists/requirements.md
└── tasks.md         (o /speckit-tasks)
```

### Source Code (repository root)

```text
.gitattributes                 # novo: export-ignore de specs/, .specify/, .claude/, .github/
install.sh                     # origens e canal, curl -L, o núcleo do canal gravado pelo build
bin/yorha                      # channel, _finish-update, rollback e supervisor que seguem a troca de nome
lib/yorha/name.sh              # YoRHa-Shell; YORHA_ORIGINS
lib/yorha/channel.sh           # novo: origens, canal, latest, download com fallback
lib/yorha/rename.sh            # novo: a troca de nome nos dois sentidos (R6)
system/hypr/yorha-shell.lua    # renomeado
system/boot/plymouth/yorha-shell/, system/login/sddm/yorha-shell/, system/boot-login/…  # renomeados
system/cursors/                # o tema "YoRHa-Shell Cursors"
shell/services/Product.qml     # novo: o nome e as pastas do produto
shell/services/Updater.qml     # sign, autoCheck, a forma "login", o dump novo
shell/hud/UpdateTag.qml        # novo: o UPDATE na barra
shell/hud/Hud.qml              # o UpdateTag antes do LogCounter
shell/ds/composites/TabBar.qml # uma tag por aba
shell/settings/…, shell/fixtures/settings-default.json  # sign e auto-check
shell/strings/Strings.qml      # os textos novos e o nome
README.md                      # FR-013 (instalar, atualizar, voltar, desinstalar, estado, aviso de fã)
.specify/memory/constitution.md  # a emenda 2.1.0
.github/workflows/lint.yml     # + workflow_dispatch
PLAN.md, CLAUDE.md, docs/      # o nome; S3 e S4 com o canal público

../YoRHa-OS-private/lab/       (branch lab-015)
├── 015/canal                  # novo: o canal no formato do GitHub, várias portas
├── 015/release                # novo: build, list, check, publish, promote
├── 015/prep                   # a VM t015 com um hyprland.lua comum
├── 015/check.d/               # os blocos do check-015, um por frente
├── check-015                  # roda os blocos
├── check-003…014, guest/, 011/, lib.sh  # o nome novo
└── README.md                  # a seção da 015
```

**Structure Decision:** o produto ganha `channel.sh`, `rename.sh`, `Product.qml` e `UpdateTag.qml`,
e o resto muda no lugar. O lab ganha a pasta `015/`, no padrão das outras specs. O `lab/014/canal`
sai de uso.

## Fases

1. **Setup** (um agente, Opus 5.5 · médio):
   - a `lab-015` e o worktree dela;
   - o `lab/015/canal`;
   - o `lab/015/release build`, `list` e `check` (o `publish` e o `promote` vêm na junção);
   - a camada `t015` e o `015/prep`;
   - o esqueleto do `check-015`.
2. **Fundação** (sequencial; o contrato fica estável depois dela):
   1. **A troca do nome pela tabela** (Haiku · baixo), nos dois repositórios, conferida pela busca do
      contracts/nome.md.
   2. **A fonte do boot regerada na VM e a regressão** depois da troca (Opus 5.5 · médio).
   3. **O núcleo:** `lib/yorha/channel.sh`, `name.sh` com `YORHA_ORIGINS` e o singleton `Product.qml`
      (Opus 5.5 · médio).
3. **Frentes paralelas**, cada uma com agente (Opus 5.5 · médio), worktree e VM próprios, no máximo
   4 VMs:
   - **A, instalar e atualizar pelo canal público** (US1, US2, US3; FR-018): `install.sh`, o `update`
     com origens e canal, `yorha channel`, a numeração nova e as recusas do `build`. Cenários 1 a 6 e
     8.
   - **B, o sinal e a conferência** (US5; FR-011, FR-019): `Product` no QML, `UpdateTag`, a tag no
     `TabBar` e na categoria, a forma `login`, o `autoCheck` e o `dump`. Cenários 7 e 11.
   - **C, o update que troca o nome** (US4; FR-017): `_finish-update`, `rename.sh`, o supervisor, o
     rollback, o uninstall e a versão `fake-shell` de teste. Cenário 10.
   - **D, os textos e o repositório** (US6; FR-013, FR-014, FR-016):
     - o README;
     - a emenda da constituição;
     - o PLAN, o CLAUDE.md e os docs;
     - o `workflow_dispatch` no lint;
     - o lint rodando numa VM;
     - a auditoria do histórico antes do push.

     Cenários 9 e 13.
4. **Junção** (Opus 5.5 · médio, até 2 VMs):
   - as frentes entram na `015-primeira-release`;
   - o `check-015` inteiro e a regressão (cenário 12);
   - o `release publish` e o `promote`, testados pelo modo `--dry-run`, que imprime os comandos do
     `gh` sem rodar;
   - a sessão do dono numa janela da VM: instalar, atualizar pelo aviso e trocar a forma do sinal.
5. **A release de verdade** (quickstart, "Depois da `main`"), um passo de cada vez com o OK do dono:
   1. o merge na `main`;
   2. o `build 0.1.0`;
   3. o teste do mesmo arquivo no lab;
   4. a página da release;
   5. a auditoria, o push, a renomeação do repositório e a limpeza das branches;
   6. o `publish`;
   7. o comando do README numa VM limpa;
   8. a 0.1.1 de teste.

   Esses comandos a sessão principal roda, porque são poucos e vão pra fora.

## Complexity Tracking

Sem violações a justificar.
