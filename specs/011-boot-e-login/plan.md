# Implementation Plan: Boot e login

**Branch**: `011-boot-e-login` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Input**: `specs/011-boot-e-login/spec.md`, aprovada pelo dono em 29.10 (commit `9290733`). A base é
a `main` (001–004, 006, 007). Os números do boot são os da análise 4K
(`YoRHa-OS-private/pessoal/referencias/jogo/boot-analise.md`). O login é o do protótipo aprovado
(artefato 28209760, v3.2).

**Status**: aprovado pelo dono em 29.10 ("sim manda bala"), com a saída da lista em 0,4 s e os 0,9 s do jogo como opção (`exit=game`).

## Summary

São três peças, que se encontram na faixa de passagem:
- **o tema de boot:** um tema `script` do Plymouth. Ele digita a lista de checagens com as etapas
  reais do boot (os nomes vêm do systemd e passam por um catálogo nosso), com a película, a lente, as
  faixas de interferência e o anel de carregamento claro. O que precisaria de processamento por pixel
  sai pronto do build, como imagem;
- **o tema de login:** um tema QML do SDDM, em Qt 6, no greeter em X11. Ele refaz o protótipo
  aprovado com cópias adaptadas das peças do design system (o greeter não tem Quickshell). Uma
  máquina de estados só manda em todas as animações, pras duas regras do dono;
- **o módulo de instalação:** `yorha-os-boot-login`, com `install`, `uninstall` e `status`. Ele põe os
  temas numa pasta gerenciada, cria drop-ins com nome próprio, ativa o Plymouth (hook no initramfs e
  `splash` no kernel) com backup e desfaz tudo conferindo os hashes.

A passagem do boot pro login é um drop-in do `sddm.service`, no estilo do GDM. O Plymouth não sai antes
da hora, a lista sai e o X sobe por cima do último quadro (preto). O greeter começa com a faixa
"Loading user data…".

A prova é o `lab/check-011`, numa camada nova de VM (`boot-iso`), com a captura do boot (`lab/bootcap`)
e o teste de estresse das animações. Tudo dentro do `lab/perf`.

## Decisões deste plano (pro dono)

1. **A saída da lista fica em 0,4 s, e a do jogo (0,9 s) vira opção** (research R9). É a única mudança
   em relação aos números aprovados. A saída acontece no caminho do boot, e a spec dá no máximo
   0,5 s de atraso pro tema todo (SC-002). A opção `exit=game` do tema de boot traz os 0,9 s de
   volta, com o custo anotado.
2. **O greeter roda em X11** (R1). É o padrão do SDDM e a passagem do Plymouth pro X é conhecida. O
   greeter em Wayland fica pra depois.
3. **As peças do design system entram no login como cópias adaptadas** (R3), com uma checagem do lab
   que compara os números. Juntar tudo num núcleo sem Quickshell fica pra depois do merge da 008 e da
   010, que mexem nos mesmos arquivos.
4. **O glitch do login é o do protótipo, em QML, sem shader** (R4). É o que foi aprovado e não depende
   de compilar shader na máquina.
5. **As imagens do tema de boot são geradas no lab e vão pro repositório** (R6, R11), uns poucos MB. A
   instalação não precisa de Python nem de Pillow na máquina.

## Technical Context

**Language/Version**: QML (Qt 6, o do SDDM 0.21 no Arch) pro login; a linguagem de script do Plymouth
(24.x) pro boot; bash pro módulo de instalação e pro ajudante `yorha-boot-watch`; Python 3 com Pillow e
numpy só no build das imagens, dentro do lab.

**Primary Dependencies**: SDDM 0.21 (`sddm-greeter-qt6`), Plymouth 24.x (plugin `script`, com o
`label` pro texto), mkinitcpio (com drop-ins), systemd-boot. A fonte M PLUS 1 (OFL). Os quadros do anel
de carregamento (NieR Cursors, Beinsezii, MIT, recoloridos; spec 002).

**Storage**: arquivos. As opções do usuário ficam em `/etc/yorha-os/login.conf`; o manifesto e os
backups, em `/var/lib/yorha-os/`.

**Testing**: no lab do repositório privado, na branch `lab-011`:
- o `lab/check-011`, com os modos `login`, `power`, `journal`, `fallback` e `undo`;
- o `lab/bootcap` (o `screendump` do QMP a cada 0,25 s, com a folha de contato);
- o `lab/011/stress-greeter`;
- o `sddm-greeter-qt6 --test-mode` pra iterar a tela sem reiniciar;
- o `lab/perf` em volta de cada teste.

**Target Platform**: Arch Linux com systemd-boot (a VM `arch-iso` do lab, instalada pelo `archinstall`)
e o SDDM. Os dois perfis de tela do dono: 1920×1080 a 1 e 2560×1600 a 1,25.

**Project Type**: temas de sistema (SDDM e Plymouth) mais um módulo de instalação.

**Performance Goals**:
- boot com o tema no máximo 0,5 s mais lento que sem ele (SC-002);
- o tema de boot a 25 quadros/s ou mais na VM;
- a entrada do login cortada em até 1 quadro depois da primeira tecla (SC-003).

**Constraints**:
- o tema nunca trava o boot nem o login (FR-026, FR-034);
- sem imagem, fonte, texto ou som do jogo;
- nada roda na máquina do dono;
- no máximo quatro VMs ao mesmo tempo, com 4 CPUs e 4 GB cada.

**Scale/Scope**:
- duas telas (boot e login) e três modos extras do boot (senha do disco, desligar, reiniciar);
- um catálogo de umas 30 etapas;
- até 20 usuários no teste.

## Constitution Check

*GATE: antes da pesquisa e de novo depois do desenho.*

| Princípio | Como o plano cumpre | Antes | Depois |
|---|---|---|---|
| I. O sistema do dono é intocável | Tudo roda na VM. O build das imagens roda no lab. Nada de Plymouth ou SDDM na máquina do dono | ✅ | ✅ |
| II. Camada sobre um Arch limpo | O módulo instala por cima de um Arch com SDDM e Plymouth, sem imagem própria | ✅ | ✅ |
| III. Padrões gerenciados separados | Os temas ficam em `/usr/share/yorha-os/`. Os arquivos criados são drop-ins com nome próprio. As opções do usuário ficam em `/etc/yorha-os/login.conf`, nunca sobrescrito. O que é editado (entradas do bootloader) tem backup e manifesto, e o `uninstall` desfaz | ✅ | ✅ |
| IV. Pronto exige evidência da VM | Cada SC tem um comando do `lab/check-011`, uma captura ou um log (quickstart.md) | ✅ | ✅ |
| V. Spec antes de código | A spec foi aprovada em 29.10; este plano espera a aprovação | ✅ | ✅ |
| VI. Paralelizar o independente | O boot, o login e o módulo são independentes depois do contrato e das ferramentas do lab (abaixo) | ✅ | ✅ |
| VII. Simplicidade | Sem shader no login, sem núcleo compartilhado antes da hora e sem blur. O Plymouth usa imagens prontas em vez de efeito por pixel | ✅ | ✅ |
| Marcas | Textos, fontes e imagens nossos. Os números do jogo são só comportamento | ✅ | ✅ |
| Licenças | O que espelhar o Qylock fica sob GPL-3.0 (compatível); o anel é MIT (Beinsezii); a fonte é OFL. Tudo no `CREDITS.md` | ✅ | ✅ |

Nenhuma violação, então a tabela de complexidade fica vazia.

## Project Structure

### Documentation (this feature)

```text
specs/011-boot-e-login/
├── spec.md
├── plan.md              este arquivo
├── research.md          R0–R16
├── data-model.md        catálogo, linhas, estados do greeter, opções, manifesto
├── quickstart.md        a validação no lab, passo a passo
├── contracts/
│   ├── sddm-theme.md    arquivos, API do SDDM, teclado, log
│   ├── plymouth-theme.md arquivos, mensagens, opções, números
│   └── install-cli.md   comandos, saídas, o que cria e o que edita
├── checklists/requirements.md
└── tasks.md             (o /speckit-tasks gera)
```

### Source Code (repository root)

```text
system/
├── boot/plymouth/yorha-os/
│   ├── yorha-os.plymouth
│   ├── yorha-os.script
│   ├── stages.tsv                 o catálogo das etapas
│   ├── config                     exit=fast|game, effects=full|calm
│   ├── assets/                    as imagens geradas (película, vinheta, anéis, faixa, anel claro)
│   ├── gen/                       o gerador das imagens (Python, roda no lab)
│   └── watch/yorha-boot-watch     o ajudante das falhas (bash) e a unidade dele
├── login/sddm/yorha-os/
│   ├── metadata.desktop
│   ├── theme.conf
│   ├── Main.qml
│   ├── components/                Users, AuthCard, Actions, Clock, KeyBar, ConfirmDialog,
│   │                              Bridge, GlitchTitle, Welcome, GreeterState
│   ├── ds/                        as cópias adaptadas: Tokens, Rule, PaperDecor, Vignette,
│   │                              Selector, ListItem, Label, LoadingRing
│   └── assets/ring/               o anel, tinta sobre papel
├── boot-login/
│   ├── yorha-os-boot-login        install | uninstall | status
│   └── files/                     os drop-ins (sddm.conf.d, sddm.service.d, mkinitcpio.conf.d)
│                                  e o login.conf de exemplo
└── cursors/yorha-cursors/gen/fam_loading.py    + a saída de quadros PNG (R11)

CREDITS.md                         + Qylock (GPL-3.0), M PLUS 1 (OFL) e o anel (MIT)
```

No repositório privado, branch `lab-011`:

```text
lab/
├── bootcap                        a captura do boot pelo QMP, com a folha de contato
├── check-011                      login | power | journal | fallback | undo | ds-sync
└── 011/
    ├── provision-boot-iso         a camada boot-iso (SDDM, Plymouth, sem login automático)
    ├── users                      os usuários de teste (2, ou 20 com --many)
    ├── stress-greeter             as 20 sequências do SC-006
    └── archinstall-luks.json      a VM com disco criptografado (US4)
```

**Structure Decision**: o repositório já guarda o que vai pro sistema em `system/` (o tema de cursor
está lá). Os dois temas e o módulo seguem o mesmo lugar, cada um na sua pasta. O lab fica no
repositório privado, como em todas as specs.

## Ordem e paralelismo

1. **Fundação (sequencial):** a camada `boot-iso`, os usuários, o `lab/bootcap` e a sondagem R0 numa
   VM. O resultado da sondagem fecha as decisões R6 a R8.
2. **Três frentes em paralelo**, cada uma com worktree e VM próprios (`[P]`):
   - **boot:** o gerador das imagens, o script, o catálogo, o ajudante das falhas e os modos de
     desligar e reiniciar (US2, US5);
   - **login:** as cópias do design system, os componentes, a máquina de estados e as opções (US1,
     US3);
   - **módulo:** `install`, `uninstall` e `status`, com o manifesto e os backups (FR-040 a FR-042).
3. **Junção (sequencial):** a passagem do boot pro login (o drop-in do `sddm.service`), o
   `lab/check-011` completo, o estresse, a captura final e a página de revisão do dono.
4. **Por último:** a senha do disco (US4), na VM com LUKS.

São três VMs no paralelo, abaixo do limite de quatro.

## Complexity Tracking

Nenhuma violação da constituição. A duplicação das peças do design system no login (R3) é
temporária e tem dono: uma tarefa de depois do merge da 008 e da 010 junta tudo num núcleo sem
Quickshell, junto com a tela de bloqueio (U5).
