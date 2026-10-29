# Quickstart: validar o Arch instalado pela ISO no laboratório

Este é o roteiro que prova cada critério de sucesso com evidência da VM (princípio IV). Tudo roda no
ambiente privado (`YoRHa-OS-private/lab`), **dentro de uma sessão de medição**. No sistema do dono só
rodam o QEMU, o `curl`, o `gpg`, o `sha256sum`, o `xorriso` e o `ssh`, que já são do laboratório.

Use uma VM só sua (`NIER_LAB_VM`) e recursos menores, pra não atrapalhar os agentes em paralelo.

## Preparação

```sh
cd ~/projects/YoRHa-OS-private
export NIER_LAB_CPUS=2 NIER_LAB_MEM=4G
lab/ls > /tmp/camadas-antes.txt
sha256sum ~/.local/share/nier-lab/vms/{basic,arch-limpo,hypr-base}.qcow2 > /tmp/discos-antes.txt   # SC-006: só as congeladas (dev e teste-* mudam com os outros agentes)
```

## Cenários

| # | Prova | Como | Esperado |
|---|---|---|---|
| 1 | US2, FR-006–009 | `lab/perf begin "006: ISO verificada" --kind 006-iso --task 006`; `lab/fetch iso`; `lab/perf end --result pass` | ISO em `images/`, somente leitura; `verify.txt` com o hash igual ao do `images.lock` e `Good signature` com a impressão digital fixada |
| 2 | SC-004 | Copiar a ISO pra uma pasta temporária, trocar um byte (`printf '\x00' \| dd conv=notrunc seek=$((1<<20)) bs=1 of=…`), apontar o comando pra ela (`NIER_LAB_ISO=<cópia> lab/install-iso teste-ruim`) | Código 2, "ISO recusada", nenhuma VM ligada (`lab/ls` igual), a cópia vira `*.rejected` |
| 3 | SC-007, US4.1 | `lab/install-iso teste-ruim --config lab/iso/testes/invalida.json` (uma configuração que o archinstall recusa, por exemplo um `disk_config` com um dispositivo que não existe; o exemplo exato sai do spike) | Código 4 em ≤ 3 min; a mensagem do archinstall aparece; `teste-ruim` não existe no `lab/ls`; o disco não foi gravado (o passo `install` nem começou no `steps.tsv`) |
| 4 | **SC-001, SC-008** (o "pronto quando") | `lab/perf begin "006: arch-iso pela ISO" --kind 006-arch-iso --task 006`; `lab/install-iso`; `lab/perf end --result pass --note "<ISO>, archinstall <versão>"` | Código 0 sem tecla nenhuma, em ≤ 20 min (meta < 10); `lab/ls` mostra `arch-iso` como `base`, BASE `iso:2026.10.01`; o relatório do `lab/perf` tem os marcadores `iso … freeze` com a duração de cada um, a CPU/memória do host e o crescimento do disco do lab |
| 5 | SC-003 | Ler `out/install-iso-*/checks.txt` | Todas as conferências com o esperado do [contrato](contracts/lab-install-iso.md#conferências-passo-9-checkstxt); `install.log` termina com a linha de conclusão e não tem `Traceback` nem `ERROR` |
| 6 | SC-002, US1.2 | `lab/perf begin "006: camada sobre a arch-iso" --kind 006-arch-iso`; `lab/new teste-iso --from arch-iso`; `NIER_LAB_VM=teste-iso lab/up teste-iso --soft`; `NIER_LAB_VM=teste-iso lab/ssh 'sudo bootctl is-installed; findmnt -no FSTYPE /; systemctl --failed --no-legend \| wc -l'` (o `bootctl` precisa de root pra ler a ESP) | O SSH responde em ≤ 60 s (o `boot_to_ssh_s` do relatório); a resposta é `yes`, `btrfs`, `0` |
| 7 | SC-005, US3 | Na `teste-iso` ligada: mandar `guest/` e `provision/` por tar e rodar `LAB_TZ=UTC bash ~/lab-guest/hypr-base.sh` (o mesmo que o `lab/bootstrap` faz); `lab/down`; `lab/up teste-iso` (com 3D); `lab/sync --src lab/smoke`; `lab/shot` | A preparação termina sem erro; o screenshot mostra o Hyprland com o smoke da UI. `lab/down`, `lab/rm teste-iso`, `lab/perf end --result pass` |
| 8 | US1.4, FR-004 | `lab/install-iso` de novo; depois `lab/new x --from arch-iso` e `lab/install-iso --redo` | 1º: avisa que `arch-iso` existe, código 1, nada muda. 2º: recusa porque `x` depende dela. `lab/rm x` |
| 9 | US4.3 | `lab/install-iso teste-int` e, durante o passo `install` (marcador no `steps.tsv`), Ctrl+C (num teste automatizado: SIGINT pro grupo do processo, com o SIGINT restaurado; um job em segundo plano herda o SIGINT ignorado) | Código 130; VM desligada (`lab/ls` sem `teste-int`); a pasta de saída tem `console.png` e o `install.live.log` parcial |
| 10 | SC-009 | `pw=$(sed -n 's/^password=//p' ~/.local/share/nier-lab/vms/arch-iso.creds); grep -rF -- "$pw" ~/.local/share/nier-lab/out/ ~/projects/YoRHa-OS-relatorios/ ~/projects/YoRHa-OS-private/ ~/projects/nier-os-project/YoRHa-OS*/ \| wc -l` | `0` |
| 11 | SC-006 | `sha256sum -c /tmp/discos-antes.txt`; `diff <(lab/ls \| grep -v -E 'arch-iso\|teste-' ) <(grep -v -E 'arch-iso\|teste-' /tmp/camadas-antes.txt)` | Todos `OK`; nenhuma diferença nas camadas que já existiam |

## Evidência pra revisão

- os relatórios do `lab/perf` dos cenários 1, 4 e 6–7 (em `~/projects/YoRHa-OS-relatorios/runs/`);
- a pasta `out/install-iso-*/` do cenário 4 (`checks.txt`, `install.log`, `console.png`,
  `manifest.json`);
- o screenshot do Hyprland sobre a `arch-iso` (cenário 7);
- as saídas dos cenários 2, 3, 8–11.

Um `relatorio.md` na pasta da spec junta tudo no fim, como na 003.
