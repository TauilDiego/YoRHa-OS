# Contrato: `lab/install-iso` (e `lab/fetch iso`)

Comandos novos do laboratório privado (`rien-OS-private/lab/`). Este contrato fixa a interface, os
passos, os arquivos e os códigos de saída; o script em si é da implementação.

## `lab/fetch iso [--latest]`

Baixa e confere a ISO oficial fixada no `images.lock` ([images-lock.md](images-lock.md)).

| Entrada | Efeito |
|---|---|
| `lab/fetch iso` | Usa a linha `iso=` do `images.lock`. Se ela não existir, age como `--latest` |
| `lab/fetch iso --latest` | Descobre a versão mais nova em `…/iso/latest/`, baixa, confere e **reescreve** a linha `iso=` (nome + sha256). As outras linhas do lock ficam iguais |
| `lab/fetch` (sem argumento) e `lab/fetch --latest` | Igual a hoje: a imagem `basic` |

Passos e garantias:
1. baixa (se faltar) `archlinux-<v>-x86_64.iso`, `.iso.sig` e `sha256sums.txt` de
   `https://geo.mirror.pkgbuild.com/iso/<v>/`; se der 404, de `https://archive.archlinux.org/iso/<v>/`.
   Downloads vão pra `*.part` e só são renomeados no fim;
2. confere o hash da ISO contra o `sha256sums.txt` **e** contra o `sha256=` do lock (com `--latest`, o
   lock recebe o hash do `sha256sums.txt` depois da assinatura passar);
3. confere a assinatura num `GNUPGHOME` temporário com só `lab/keys/archlinux-release.asc`, e exige
   que a impressão digital do assinante (`VALIDSIG` no `--status-fd`) seja a fixada;
4. deixa a ISO somente leitura em `$LAB_HOME/images/` e escreve `images/<iso>.verify.txt` (hash e
   linha da assinatura).

Saída: o caminho da ISO na saída padrão; código 0. Falha de hash ou assinatura: código 2, a ISO fica
como `*.rejected` (pra investigar) e não é usada.

## `lab/install-iso [<nome>] [opções]`

```
lab/install-iso [<nome>] [--config <arquivo.json>] [--disk <tamanho>] [--snapshot AAAA/MM/DD]
                [--redo] [--keep-on-fail] [--timeout <minutos>]
```

| Opção | Padrão | O que faz |
|---|---|---|
| `<nome>` | `arch-iso` | Nome da camada nova |
| `--config` | `lab/iso/archinstall.json` | Configuração do archinstall ([archinstall-config.md](archinstall-config.md)). O bloco `disk_config` é sempre gerado pelo lab a partir de `--disk`, a não ser que o arquivo traga um com `"device": "/dev/vda"` |
| `--disk` | `40G` | Tamanho virtual do disco (qcow2 esparso) |
| `--snapshot` | — | Usa os pacotes do Arch Linux Archive daquela data em vez dos do dia |
| `--redo` | — | Apaga e refaz a camada, se nenhuma outra depender dela |
| `--keep-on-fail` | — | Na falha, mantém o disco como `<nome>` **incompleto** (nunca congelado), pra investigar com `lab/up` |
| `--timeout` | `20` | Limite do passo `install`, em minutos |

Variáveis respeitadas: `NIER_LAB_CPUS` (padrão **2** neste comando, teto do dono), `NIER_LAB_MEM` (padrão **4G**),
`NIER_LAB_HOME` e, só pra testar a recusa, `NIER_LAB_ISO=<arquivo>` (usa esse arquivo no lugar da ISO
fixada, com a mesma verificação contra o `images.lock`). O comando exporta `NIER_LAB_VM=<nome>` pra si: funciona com outras VMs ligadas.

### Passos

Cada passo vira um marcador do `lab/perf` (`lab/perf mark "<passo>"`) quando há sessão aberta.

| # | Passo (marcador) | O que acontece | Falha → código |
|---|---|---|---|
| 0 | `preflight` | KVM e OVMF presentes; `<nome>` livre (ou `--redo` sem dependentes); espaço livre ≥ 6 GB (4 GB com a ISO já baixada); chave SSH do lab existe | 1 |
| 1 | `iso` | `lab/fetch iso` (baixa só se faltar; confere sempre) | 2 |
| 2 | `seed` | Gera `run/<nome>-seed.iso` (rótulo `cidata`) com `meta-data` (`instance-id` novo) e `user-data` (chave do lab pro root + marcador na serial) | 1 |
| 3 | `boot-iso` | Cria `vms/<nome>.qcow2` vazio e `vms/<nome>.vars.fd` (cópia do OVMF limpo); liga o QEMU `--soft` com o disco, a ISO e o `cidata` como CD-ROMs somente leitura, serial pra arquivo, QMP | 3 |
| 4 | `ssh-iso` | Espera o marcador do cloud-init na serial e o SSH do root (limite 5 min); depois `systemctl is-system-running --wait` dentro da ISO | 3 |
| 5 | `dry-run` | Gera a senha (só no host do lab, `vms/<nome>.creds`, modo 600), o hash dela **dentro da ISO** (`crypt_yescrypt`, senha por stdin) e as credenciais; manda config + credenciais pra `/root/rien-lab/` por tar no SSH; roda `archinstall --config … --creds … --silent --dry-run` | 4 |
| 6 | `install` | `archinstall --config … --creds … --silent --skip-version-check`, com o log ao vivo em `out/…/install.live.log`; limite `--timeout`. Sucesso = código 0 **e** linha de conclusão no `install.log` | 5 |
| 7 | `collect` | Copia da ISO: `/var/log/archinstall/install.log`, o `user_configuration.json` salvo pelo archinstall; **apaga** `/root/rien-lab/` e o arquivo de credenciais salvo pelo archinstall antes de desligar | 5 |
| 8 | `reboot` | `poweroff` na ISO; liga de novo **só com o disco** (sem CD-ROMs), com `discard=unmap` | 6 |
| 9 | `checks` | SSH como `arch` com a chave do lab (limite 2 min); roda as conferências (abaixo) → `checks.txt`; `fstrim -av`; `screendump` → `console.png`; grava `manifest.json` | 6 |
| 10 | `freeze` | `lab/down <nome>`; escreve `vms/<nome>.base` = `iso:<versão>`; `lab/freeze <nome>`; apaga o `seed` | 6 |

Em qualquer falha ou `SIGINT`/`SIGTERM` (`trap`): `screendump` se a VM estiver ligada, `quit` pelo QMP,
apaga `vms/<nome>.*` (ou, com `--keep-on-fail`, renomeia o `.base` pra `incompleta:<passo>`), apaga o
`seed` e imprime o passo que falhou e a pasta de saída. Interrupção: código **130**.

### Conferências (passo 9, `checks.txt`)

Cada linha é `chave=valor`; o passo falha se qualquer `esperado` não bater. Com a configuração padrão:

| Chave | Comando (no sistema instalado) | Esperado |
|---|---|---|
| `hostname` | `cat /etc/hostname` | `nier-lab` |
| `bootloader` | `bootctl is-installed` | `yes` |
| `root_fs` | `findmnt -no FSTYPE /` | `btrfs` |
| `root_subvol` | `findmnt -no OPTIONS / \| grep -o 'subvol=[^,]*'` | `subvol=/@` |
| `subvols` | `sudo btrfs subvolume list / \| awk '{print $NF}' \| sort \| paste -sd,` | contém `@home,@log,@pkg` |
| `swap` | `swapon --noheadings --show=NAME` | `/dev/zram0` |
| `network` | `systemctl is-active NetworkManager` | `active` |
| `online` | `nmcli -t -f STATE general` | `connected` |
| `system` | `systemctl is-system-running` | `running` |
| `failed_units` | `systemctl --failed --no-legend \| wc -l` | `0` |
| `user` | `id -nG arch` | contém `wheel` |
| `sudo_nopasswd` | `sudo -n true && echo ok` | `ok` (adaptação do lab) |
| `root_locked` | `sudo passwd -S root \| awk '{print $2}'` | `L` |
| `kernel` | `pacman -Q linux` | informativo |
| `packages` | `pacman -Qq \| wc -l` | informativo |
| `archinstall_log` | `test -d /var/log/archinstall && echo yes` | `yes` (a confirmar no spike; se o archinstall não copiar o log pro alvo, vira informativo) |

Com `--config` próprio, as linhas dependentes da configuração (`bootloader`, `root_fs`, `root_subvol`,
`subvols`, `swap`, `network`) passam a ser **informativas**, e só as gerais (`system`, `failed_units`,
`hostname`, `user`, `sudo_nopasswd`) decidem.

### Arquivos

| Caminho (`$LAB_HOME/…`) | Conteúdo | Vida |
|---|---|---|
| `images/archlinux-<v>-x86_64.iso` (+ `.sig`, `.verify.txt`), `images/iso-<v>.sha256sums.txt` | ISO verificada, somente leitura | Até ser apagada à mão |
| `vms/<nome>.qcow2`, `vms/<nome>.vars.fd` | Disco e NVRAM do UEFI (com a entrada do systemd-boot) | A camada |
| `vms/<nome>.base` | `iso:<versão>` (ou `incompleta:<passo>`) | A camada |
| `vms/<nome>.manifest.json` | [data-model.md](../data-model.md), "Manifesto" | A camada |
| `vms/<nome>.creds` | Usuário e senha do lab (modo 600). **Nunca** sai de `$LAB_HOME` | A camada |
| `run/<nome>-seed.iso` | O `cidata` | Só durante a execução |
| `out/install-iso-<AAAAMMDD-HHMMSS>/` | `verify.txt`, `serial.log`, `install.live.log`, `install.log`, `user_configuration.json`, `checks.txt`, `console.png`, `manifest.json`, `steps.tsv` (passo, início, fim, resultado) | Fica; cada arquivo vai pro `perf_artifact` com sha256 |

O `lab/rm <nome>` passa a apagar também o `.manifest.json` e o `.creds`. O `lab/ls` mostra
`iso:<versão>` na coluna BASE.

### Saída

Sucesso (código 0), última linha na saída padrão: o caminho da pasta de saída. No erro padrão, um
resumo:

```
[lab] pronto: 'arch-iso' (ISO 2026.10.01, archinstall 4.5), 7m42s, 2,4 GB
[lab] logs: ~/.local/share/nier-lab/out/install-iso-20261027-201500
```

### Códigos de saída

| Código | Significado |
|---|---|
| 0 | Camada pronta e congelada |
| 1 | Pré-condição (KVM, espaço, nome em uso, chave) |
| 2 | ISO recusada (hash ou assinatura) |
| 3 | A ISO não deu boot ou não abriu o SSH |
| 4 | Configuração recusada pelo archinstall (`--dry-run`); o disco não foi tocado |
| 5 | A instalação falhou ou passou do tempo |
| 6 | O sistema instalado não subiu ou falhou numa conferência |
| 130 | Interrompido |

## Notas da implementação (2026-10-27)

A interface, os passos, os arquivos e os códigos acima valem como estão. A implementação acrescentou:

- **Porta própria:** o `install-iso` escolhe a primeira porta a partir de 2240 que não está ouvindo
  nem em nenhum `run/*.port` (o `lib.sh` cai na 2222 quando a VM de um agente está desligada).
- **SSH com nova tentativa:** todo comando mandado pelo SSH é idempotente e tenta de novo no código
  255 (até ~1 min). Motivo: o sshd (OpenSSH ≥ 9.8) tem `PerSourcePenalties`, todo o lab chega pelo NAT
  do QEMU (10.0.2.2), e a sonda de boot do `lab/perf` deixa uma rajada de conexões sem autenticação
  quando o sshd sobe; o sshd então recusa o lab por 15 s ou mais. Na ISO, o `cidata` isenta o
  10.0.2.2 (`/etc/ssh/sshd_config.d/90-rien-lab.conf`, só no sistema da ISO) e recarrega o sshd.
- **Instalação num `systemd-run` na ISO** (`rien-archinstall`, `RemainAfterExit`, `RuntimeMaxSec` =
  `--timeout`): uma queda do SSH não mata o archinstall; o host lê `SubState`, `Result` e
  `ExecMainStatus` da unidade e copia a saída pra `install.live.log`.
- **Recusa no `--dry-run`:** código ≠ 0, **ou** `- ERROR -`/`Traceback` no log do archinstall, **ou**
  nenhum `user_configuration.json` salvo. O `disk-after-dry-run.txt` mostra o disco sem tabela nem
  assinatura.
- **Arquivos a mais na pasta de saída:** `dry-run.log`, `dry-run.install.log`, `disk-after-dry-run.txt`,
  `config.source.json`, `config.sent.json`, `iso-sshd.log`, `ssh.log`, `ssh-retries.log` (se houve),
  `fstrim.txt`, `packages.txt`, `journal-warnings.txt`.
- **Conferências:** `swap` sai `/dev/zram0`; `subvols` inclui também `var/lib/machines` e
  `var/lib/portables` (criados pelo systemd); `archinstall_log` = `yes` (o archinstall copia o log pro
  sistema instalado).
- **Testes de falha:** `lab/iso/testes/invalida.json` (código 4) e `lab/iso/testes/sem-esp.json`
  (passa no `--dry-run` do archinstall 4.5, falha na instalação, código 5).
