# Implementation Plan: Arch completo na VM (instalado pela ISO)

**Branch**: `006-arch-pela-iso` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/006-arch-pela-iso/spec.md` (spec e plano aprovados pelo
dono em 2026-10-27, com as decisões abaixo)

## Decisões do dono (2026-10-27)

Substituem as perguntas em aberto do rascunho (detalhes na spec, "Decisões do dono"):

| # | Decisão | Efeito no plano |
|---|---|---|
| 1 | `arch-iso` **ao lado** da cadeia atual; nenhuma camada existente muda | research R9, opção A. A troca da base da `hypr-base` é outra tarefa, depois |
| 2 | systemd-boot (sem GRUB), btrfs com subvolumes, zram, NetworkManager, perfil mínimo; variantes pelo `--config` na S3; Plymouth depois | `lab/iso/archinstall.json` como no contrato. Nada de UKI nem de hooks fora do padrão: o Plymouth entra depois só com o pacote, o hook `plymouth` no `mkinitcpio.conf` e `splash` nas opções da entrada do systemd-boot |
| 3 | Sudo sem senha pro usuário do lab, marcado e removível | `/etc/sudoers.d/90-nier-lab`, listado no manifesto |
| 4 | Pacotes do dia + `--snapshot <data>` opcional (Arch Linux Archive) | research R7 |
| 5 | Sem cache de pacotes agora; medir o download e dizer se um cache compensa | research R7; o tempo de download sai do `install.live.log` e do `lab/perf` |
| — | Uma VM desta fase por vez, `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G` (teto do dono: 4 VMs, 2 núcleos e 4 GB cada) | O padrão do `lab/install-iso` passa a ser **2 CPUs e 4 GB** (era 4/4) |

## Summary

O laboratório ganha **um comando**, `lab/install-iso`, que instala o Arch do jeito que um usuário
instala e congela o resultado como uma camada nova, a `arch-iso`:
1. **ISO:** a oficial, fixada no `images.lock` (versão + sha256) e conferida pelo hash e pela
   assinatura de release, com a chave fixada no lab (`lab/fetch iso`);
2. **boot sem tecla:** a ISO dá boot pela entrada padrão; um segundo drive `cidata` (cloud-init
   NoCloud, já ligado na ISO) só instala a chave SSH do lab pro root;
3. **instalação dirigida pelo SSH:** o host manda a configuração e as credenciais, roda o archinstall
   da ISO com `--dry-run` (valida sem tocar no disco) e depois com `--silent`, vendo o código de saída
   e o log ao vivo;
4. **prova:** desliga, liga só pelo disco, roda as conferências (carregador, btrfs, zram,
   NetworkManager, nenhum serviço com falha), tira um screenshot do console e congela.

A camada nova entra **ao lado** da cadeia atual (`basic → arch-limpo → hypr-base`), sem mudar nada
dela. Tudo roda dentro do `lab/perf`, com um marcador por passo.

A implementação fica toda no repositório privado (`YoRHa-OS-private/lab/`). O repositório público
recebe só esta spec.

## Technical Context

**Language/Version**: Bash (scripts do lab, como os que existem: `set -euo pipefail`, `source lib.sh`);
JSON (configuração do archinstall); YAML do cloud-init (`user-data`); Python só **dentro da ISO**
(gerar o hash da senha com o módulo do próprio archinstall).

**Primary Dependencies**:
- no host (todas já são do lab, nada novo): `qemu-system-x86_64`, `qemu-img`, OVMF (`edk2-ovmf`),
  `xorriso` (`libisoburn`, pro `cidata`), `curl`, `gpg`, `sha256sum`, `ssh`, `socat` (QMP), `jq`;
- na ISO oficial 2026.10.01: archinstall 4.5, cloud-init 26.2, openssh 10.5, systemd-boot (research
  R2, R3).

**Storage**: `$LAB_HOME/images/` (ISO verificada), `$LAB_HOME/vms/` (camada, NVRAM, `.base`, manifesto,
credenciais), `$LAB_HOME/run/` (`cidata`, socket QMP, serial), `$LAB_HOME/out/install-iso-*/`
(evidência); `lab/images.lock`, `lab/keys/archlinux-release.asc` e `lab/iso/` no repositório privado.

**Testing**: o roteiro do [quickstart.md](quickstart.md), dentro do `lab/perf`: códigos de saída, o
`checks.txt` (conferências no sistema instalado), o `install.log`, o `console.png` (QMP `screendump`)
e, na US3, o `lab/shot` do Hyprland sobre a camada nova. `shellcheck` nos scripts novos e mudados (o
lint da F0). Sem testes unitários (princípio VII).

**Target Platform**: o laboratório (QEMU/KVM + OVMF, UEFI, rede de usuário) no host do dono; o
convidado é o Arch instalado pela ISO.

**Project Type**: ferramenta de linha de comando do laboratório (infraestrutura de teste).

**Performance Goals**: instalação completa < 10 min com a ISO já baixada (limite 20 min, SC-001);
segundo boot até o SSH < 60 s (SC-002); configuração inválida recusada em < 3 min (SC-007).

**Constraints**:
- ISO oficial sem modificação, sem tecla e sem mudar parâmetros de boot (research R2);
- nenhuma senha em linha de comando, terminal, log guardado ou repositório (FR-015, SC-009);
- convive com outras VMs ligadas (porta livre, `NIER_LAB_VM`, 2 CPUs e 4 GB por padrão, decisão do dono);
- não muda nenhuma camada existente (FR-005, SC-006);
- o archinstall pode mudar o formato da configuração entre versões: a validação com `--dry-run` vem
  antes de qualquer gravação (FR-013).

**Scale/Scope**: 2 comandos novos (`lab/install-iso`, `lab/fetch iso`), 1 configuração padrão, 1 modelo
de `user-data`, 1 roteiro de conferências; mudanças pequenas em `lab/fetch`, `lib.sh`, `lab/up`
(argumentos do QEMU compartilhados), `lab/ls`, `lab/rm`, `lab/new` e no `README.md` do lab.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Status |
|---|---|---|
| I. Sistema do dono intocável | O archinstall, o cloud-init e o sistema instalado rodam só dentro da VM. No host rodam só as ferramentas que o lab já usa (QEMU, `qemu-img`, `xorriso` do `libisoburn` já aprovado, `curl`, `gpg`, `sha256sum`, `ssh`, `socat`). Nenhum pacote novo no host. O hash da senha é feito **dentro da ISO** | ✅ |
| II. Camada sobre Arch limpo, não imagem | A ISO é a **oficial**, sem modificação, usada do jeito que um usuário usa. O projeto continua sem ISO ou imagem própria; esta fase justamente produz o "Arch limpo" realista sobre o qual a camada do projeto vai ser testada (S3) | ✅ |
| III. Padrões × arquivos do usuário | Não se aplica ao produto (é infraestrutura do lab). Dentro do lab: as adaptações (SSH, sudo, hostname) ficam separadas e listadas num manifesto, pra a S3 saber o que é "do usuário" | ✅ |
| IV. Pronto exige evidência da VM | Cada SC tem prova no [quickstart.md](quickstart.md): códigos de saída, `checks.txt`, `install.log`, `console.png`, o `lab/shot` da US3 e o relatório do `lab/perf` | ✅ |
| V. Spec antes de código | Spec e plano escritos juntos a pedido do dono e **aprovados por ele em 2026-10-27**, com as decisões acima registradas | ✅ |
| VI. Paralelizar | Os contratos ([contracts/](contracts/)) vêm antes. Depois, `lab/fetch iso`, o gerador de configuração/`cidata` e o roteiro de conferências vão em paralelo (arquivos separados). O spike e a integração são sequenciais. Nenhum agente precisa de VM pra as tarefas `[P]` de escrita; a VM só entra no spike e na validação | ✅ |
| VII. Simplicidade | Sem cache de pacotes, sem servidor HTTP no host, sem imagem própria; reusa o `lib.sh` (porta livre, `wait_ssh`, `qmp`, `perf`). O cache só entra se a medição pedir | ✅ |
| Restrições: segredos | Senha gerada por camada, só em `$LAB_HOME` (modo 600); hash feito na VM com a senha por stdin; credenciais apagadas da ISO antes de desligar; `--debug` do archinstall proibido (grava credenciais no log) | ✅ |
| Fluxo: git | Spec no repositório público (branch `006-arch-pela-iso`); scripts no privado, numa branch do agente, merge do dono | ✅ |

**Re-check pós-design (Fase 1):** sem violações. Duas notas:
- **A camada nova é uma raiz** (um disco sem camada de baixo). Hoje só a `basic` é raiz, e ela é um
  link pra imagem baixada. O `lab/rm`, o `lab/ls` e o `lab/new` passam a entender `iso:<versão>` e
  `incompleta:<passo>` no `.base` (contrato).
- **O passo `checks` faz um `screendump` pelo QMP**, que o README do lab registra como falho só com
  `egl-headless`; aqui a VM liga com `--soft`. Se falhar mesmo assim, o screenshot vira um
  `journalctl -b` + `systemctl status` em texto e a pendência vai pro README (não muda a spec).

## Project Structure

### Documentation (this feature)

```text
specs/006-arch-pela-iso/
├── spec.md
├── plan.md              # este arquivo
├── research.md          # Fase 0: R1–R11
├── data-model.md        # Fase 1: ISO, configuração, credenciais, camada, manifesto, execução
├── quickstart.md        # Fase 1: roteiro de validação no lab
├── contracts/
│   ├── lab-install-iso.md     # comandos, passos, conferências, arquivos, códigos de saída
│   ├── images-lock.md         # formato novo do images.lock
│   └── archinstall-config.md  # configuração padrão, disk_config gerado, credenciais, cidata
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks (ainda não)
```

### Source Code (repositório privado)

```text
YoRHa-OS-private/lab/
├── install-iso              # NOVO: o comando (passos 0–10 do contrato)
├── fetch                    # + subcomando `iso`; lê o images.lock no formato novo (compatível com o antigo)
├── images.lock              # + linha iso=… sha256=…
├── keys/archlinux-release.asc   # NOVO: chave de release do Arch, fixada
├── iso/
│   ├── archinstall.json     # NOVO: configuração padrão (sem disk_config)
│   ├── user-data            # NOVO: modelo do cloud-init
│   ├── check-arch-iso       # NOVO: conferências, roda no sistema instalado e imprime chave=valor
│   └── testes/invalida.json # NOVO: configuração recusada de propósito (quickstart, cenário 3)
├── lib.sh                   # + qemu_base_args (extraído do lab/up), lock_get, disk_free_gb
├── up                       # passa a usar qemu_base_args (sem mudança de comportamento)
├── ls                       # coluna BASE mostra iso:<versão> / incompleta:<passo>
├── rm                       # apaga também .manifest.json e .creds
├── new                      # recusa --from de uma camada incompleta
└── README.md                # árvore de camadas com a arch-iso, comandos novos, "Lições"
```

**Structure Decision**: um comando novo e auto-contido (`install-iso`), com a configuração e os
modelos numa pasta própria (`lab/iso/`), pra o resto do lab mudar o mínimo. A única refatoração é
tirar a montagem dos argumentos do QEMU do `lab/up` pra uma função do `lib.sh`, porque o `install-iso`
precisa dos mesmos argumentos mais os CD-ROMs; o `lab/up` continua com a mesma interface e o mesmo
comportamento. O `lab/bootstrap` não muda nesta fase.

## Dependências entre specs

- **Nenhuma com a trilha da UI (001–004).** Esta spec não toca em `shell/` nem nas camadas que os
  agentes da UI usam.
- **S3 (instalador v0)** depende desta: os `teste-*` da S3 nascem de `lab/new … --from arch-iso`.
- **Troca da base da `hypr-base`** (opcional, decisão do dono): depende da US3 passar e de nenhum
  agente estar usando `dev`/`teste-*`.

## Ordem de execução (pra o `/speckit-tasks`)

1. **Spike (sequencial, uma VM `teste-iso-spike`, dentro do `lab/perf`):** à mão, com os scripts
   provisórios fora do `lab/`:
   - a ISO dá boot sozinha no OVMF com o `cidata` e o cloud-init instala a chave (marcador na serial);
   - o `screendump` funciona com `--soft`;
   - `archinstall --dry-run` aceita a configuração padrão; ajustar os nomes de campo até passar sem
     aviso e guardar o `user_configuration.json` salvo como referência;
   - uma instalação completa, cronometrada (confirma ou corrige a tabela de tempos do research R8);
   - o segundo boot pela NVRAM gravada e o fallback `EFI/BOOT/BOOTX64.EFI`;
   - se o archinstall copia o log pro sistema instalado.

   Se o cloud-init não achar o `cidata`, o spike testa o plano B (research R2) antes de seguir.
2. **Contrato (sequencial):** `images.lock` no formato novo + leitura compatível no `lib.sh`;
   `qemu_base_args` no `lib.sh` e o `lab/up` usando ela (conferir com `lab/up dev` que nada mudou); a
   chave de release fixada. A partir daqui, [contracts/](contracts/) congela.
3. **Em paralelo `[P]`** (arquivos separados, sem VM):
   - `lab/fetch iso` (download, archive, hash, assinatura, `--latest`);
   - `lab/iso/archinstall.json`, o gerador do `disk_config` e o `user-data`;
   - `lab/iso/check-arch-iso`;
   - `lab/ls`, `lab/rm`, `lab/new` (os estados do `.base`).
4. **Integração (sequencial):** o `lab/install-iso` (passos, `trap`, marcadores, pasta de saída,
   manifesto) e a primeira execução completa (quickstart, cenário 4).
5. **Validação:** quickstart, cenários 1–11, e o `relatorio.md`.
6. **Documentação:** `README.md` do lab (árvore de camadas, comandos, tempos medidos, lições); a nota
   no `PLAN.md` (fase S2 concluída) fica pro dono.

## Riscos

| Risco | Efeito | Mitigação |
|---|---|---|
| O cloud-init da ISO não acha o `cidata` ou não roda o `write_files` pro root | Sem SSH na ISO | Marcador na serial + `console.png`; plano B do research R2 (boot direto no kernel com `script=`), testado no spike |
| O formato da configuração muda numa versão nova do archinstall | A instalação para | `--dry-run` antes de gravar (FR-013); ISO fixada, então a versão do archinstall só muda quando o lock muda; o manifesto anota a versão |
| Código 0 do archinstall sem instalação completa | Camada quebrada congelada | Sucesso só com a linha de conclusão no log **e** o segundo boot com as conferências (FR-017) |
| Mirror lento ou fora do ar; sincronização do chaveiro demorada | Instalação longa ou falha | Limite de tempo (FR-016); um mirror só, previsível; `--snapshot` pra repetir; cache de pacotes como trabalho futuro se a medição pedir |
| ISO some dos mirrors (≈ 3 meses) | Download falha | Fallback pro `archive.archlinux.org` (FR-009) |
| Chave de release do Arch troca | Verificação falha | Mensagem clara; troca manual, conferida pelo dono, com commit no repositório privado |
| Concorrência com os agentes da UI (CPU, memória, portas) | Testes deles ficam lentos | 2 CPUs / 4 GB por padrão (teto do dono), uma VM desta fase por vez, porta livre automática; o custo fica no `lab/perf` |
| Disco do dono enche (ISO 1,6 GB + camada ~2–3 GB por execução) | Lab para | Conferência de espaço antes (FR-021); `fstrim` + `discard` antes de congelar; `lab/rm` apaga tudo da camada |
| A `hypr-base.sh` assume coisas da `basic` (rede, pacotes, sudo) | US3 falha | Adaptações do lab dão sudo sem senha e o usuário `arch`; o que mais faltar vira ajuste na `hypr-base.sh` (registrado), não na camada |
| Vazamento da senha | Segredo exposto | Senha por stdin, hash na VM, credenciais apagadas da ISO, sem `--debug`; cenário 10 do quickstart procura a senha em tudo |

## Complexity Tracking

Sem violações da constituição.
