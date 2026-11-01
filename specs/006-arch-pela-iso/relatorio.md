# Relatório: 006 — Arch completo na VM (instalado pela ISO)

**Data:** 2026-10-27 · **Fase:** S2 · **Tarefas:** 23 de 23 (`tasks.md`)

**Branches:** `006-arch-pela-iso` (público: spec, plano, tarefas, este relatório) e `lab-s2` (privado:
todo o código). Nada rodou no sistema do dono além das ferramentas do lab (QEMU, `curl`, `gpg`,
`sha256sum`, `xorriso`, `ssh`, `python3` do `lab/perf`, e o `shellcheck` num container `nier-lab`).
Uma VM desta fase por vez, com 2 CPUs e 4 GB.

## O "pronto quando" da S2

> Um comando entrega um `arch-limpo` instalado pela ISO.

```
export NIER_LAB_VM=arch-iso NIER_LAB_CPUS=2 NIER_LAB_MEM=4G
lab/install-iso            # 335 s, código 0, camada arch-iso congelada (BASE iso:2026.10.01)
```

## Evidência por critério de sucesso

Todos os ids são de `~/projects/YoRHa-OS-relatorios/runs/`.

| Critério | Resultado | Evidência |
|---|---|---|
| **SC-001** um comando, sem tecla, ≤ 20 min (meta < 10) | ✅ **5,6 min** (335 s) com a ISO no disco | `2026-10-27T224150-vm-arch-iso-006-arch-iso-pela-iso-codigo-final`; `out/install-iso-20261027-224201/steps.tsv` |
| **SC-002** SSH ≤ 60 s numa camada sobre a `arch-iso`, 0 falhas | ✅ 12,7 s; `yes`, `btrfs`, `0` | `…T221337-vm-teste-iso-006-camada-sobre-a-arch-iso`, `…T224752-…-arch-iso-final` |
| **SC-003** conferências 100% | ✅ 13/13 decisivas + 3 informativas (kernel 7.2.11, 183 pacotes, log do archinstall presente) | `checks.txt` da rodada final e do T014 |
| **SC-004** ISO com 1 byte trocado recusada antes de ligar VM | ✅ código 2 em 1,7 s, `*.rejected`, `steps.tsv` para no passo `iso` | `…T210322-vm-teste-ruim-006-iso-verificada-e-recusada` |
| **SC-005** `hypr-base.sh` sem mudança + Hyprland com o smoke | ✅ 84 s, código 0; Hyprland 0.56.2 com a barra do smoke, 0 erros de QML | `…T221444-vm-teste-iso-006-hypr-base-sobre-a-arch-iso`; `out/006-evidencia/T016-hyprland-smoke.png` |
| **SC-006** bases existentes intactas | ✅ 5/5 hashes (discos e NVRAM de `basic`, `arch-limpo`, `hypr-base`) iguais no meio e no fim | `…T221712-…-bases-intactas`, `…T224855-…-bases-intactas-no-fim` |
| **SC-007** configuração inválida falha em ≤ 3 min sem tocar no disco | ✅ código 4 em 67 s; disco sem tabela nem assinatura; sem camada | `…T221738-vm-teste-ruim-006-configuracao-invalida` |
| **SC-008** tempo de cada passo, CPU/RAM do host, disco da camada | ✅ marcadores por passo no `lab/perf`, `steps.tsv`, camada 1749 MB | relatório da rodada final |
| **SC-009** senha em 0 arquivos | ✅ 0 (controle positivo: o `.creds` acha 1) | `…T224828-vm-arch-iso-006-senha-fora-de-tudo` |

Mais evidência: refazer sem `--redo` → código 1; `--redo` com camada em cima → recusa (`…T221416`);
Ctrl+C no `install` → código 130 em ~1 s, VM desligada, sem camada; `--keep-on-fail` →
`incompleta:install` e `lab/new --from` recusa (`…T222507`).

## Tempos e disco (rodada final, 2 CPUs, 4 GB)

| Passo | Tempo |
|---|---|
| verificação da ISO (sha256 + assinatura) | 4 s |
| boot da ISO até o SSH e o sistema assentado | 48 s (marcador do cloud-init em ~40 s) |
| `--dry-run` | 9 s |
| instalação | 258 s, dos quais **219 s** são o `pacstrap` da base |
| segundo boot só pelo disco até o SSH | 7–10 s |
| **total** | **335 s** (as outras 4 rodadas completas: 331–348 s) |

- **Download:** ISO 1,64 GB em 476 s (~3,4 MB/s, uma vez por versão). Pacotes: **703 MiB por
  instalação** (~800 MB pela rede, com as bases de dados), a ~3,5 MB/s.
- **Disco:** camada `arch-iso` 1749 MB (704 MB são o cache do pacman no `@pkg`); ISO 1,64 GB.

### Cache de pacotes compensa? (decisão 5)

**Ainda não.** O download é ~65% do tempo da instalação (≈ 3,6 de 5,6 min), então um cache levaria a
instalação pra ~2 min. Mas a `arch-iso` só é refeita quando a ISO muda ou pra testar uma data do
archive: os testes da S3 nascem de `lab/new … --from arch-iso`, que é instantâneo, e a camada já leva
704 MB de pacotes no cache do pacman. Reavaliar na S3 se ela reinstalar a pilha do Hyprland muitas
vezes por dia (a `hypr-base.sh` levou 84 s nesta fase). A opção preferida continua a do research R7:
um proxy de cache num container `nier-lab`.

## Desvios e achados

1. **Caminho desassistido:** o **plano A** funcionou de primeira. O cloud-init da ISO acha o `cidata`
   sozinho; o plano B (`script=`) não foi preciso.
2. **SSH recusado logo depois do boot da ISO** (3 das 4 primeiras rodadas falharam no `--dry-run`).
   Causa, achada no journal do sshd da ISO: o sshd (OpenSSH ≥ 9.8) tem `PerSourcePenalties`, todo o
   lab chega pelo NAT do QEMU (10.0.2.2), e a sonda de boot do `lab/perf` bate na porta a cada segundo
   antes do sshd subir; o QEMU segura essas conexões e entrega uma rajada sem autenticação quando o
   sshd começa a escutar, e o sshd recusa todo mundo por 15 s. Correções no `install-iso`: o `cidata`
   isenta 10.0.2.2 **só no sistema da ISO**; o ssh tenta de novo no código 255; porta própria (2240+);
   archinstall num `systemd-run`. Depois disso: 0 penalidades, 0 novas tentativas.
3. **O `--dry-run` do archinstall 4.5 não pega tudo:** systemd-boot sem ESP passa e só falha na
   instalação. Registrado no research R3 e virou um teste (`sem-esp.json`, código 5).
4. **`bootctl is-installed` precisa de root**: o comando do quickstart ganhou `sudo`.
5. **Plymouth (decisão 2):** nada impede. O initramfs é o `mkinitcpio` padrão (`HOOKS=(base udev
   autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)`) e a entrada
   do systemd-boot tem uma linha `options` comum; acrescentar o Plymouth é instalar o pacote, pôr o
   hook e `splash` nas opções.
6. **Rodadas a mais:** duas instalações completas da `teste-int` aconteceram porque o SIGINT de
   teste foi ignorado (job em segundo plano herda o SIGINT ignorado). Foram apagadas; servem de prova
   de repetibilidade (331 s e 342 s). Lição no README do lab.

## Comandos novos (pra Central)

| Comando | O que faz |
|---|---|
| `lab/fetch iso [--latest]` | Baixa e confere a ISO oficial fixada no `images.lock` |
| `lab/install-iso [<nome>] [--config f] [--disk 40G] [--snapshot AAAA/MM/DD] [--redo] [--keep-on-fail] [--timeout min]` | Instala o Arch pela ISO e congela a camada (padrão `arch-iso`) |
| `lab/new teste-x --from arch-iso` | Camada de teste sobre o Arch instalado pela ISO |
| `lab/ssh 'bash -s -- --expect' < lab/iso/check-arch-iso` | Conferências do sistema instalado |

## Pro dono decidir

1. **Trocar a base da `hypr-base` pela `arch-iso`** (decisão 1: tarefa separada). A US3 passou: a
   `hypr-base.sh` roda sem mudança sobre ela.
2. **A sonda de boot do `lab/perf`** pode causar o mesmo SSH recusado em qualquer VM cujo sshd demore
   a subir. Hoje só o `install-iso` se protege. Corrigir no `perf.py` (por exemplo, só sondar depois
   que a porta do convidado aceitar de verdade, ou espaçar as sondas) é uma mudança pequena no lab
   compartilhado, mas mexe no que os outros agentes usam.
3. **`lib.sh` cai na porta 2222** quando a VM do `NIER_LAB_VM` está desligada: um comando de um agente
   pode bater na VM de outro. Vale um ajuste (falhar em vez de cair na 2222).
4. **Cache de pacotes:** não agora (acima); reavaliar na S3.
5. **Nota no `PLAN.md`** (S2 concluída): fica pro dono.
