# Quickstart: validar o estudo 009 no laboratório

Roteiro pra provar cada critério de sucesso da [spec](spec.md). Tudo roda pelo lab privado
(`YoRHa-OS-private/lab/`, branch `lab-009`), nunca no sistema do dono. Todo bloco fica dentro de uma
sessão `lab/perf` (`--kind 009 --task 009/T…`), e o relato cita o resumo do relatório.

**Regras de VM** (valem pra todos os cenários):
- antes de ligar: `lab/ls` e `pgrep -af qemu-system`; no máximo **4 VMs no total** e **2 deste estudo**;
- sempre `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G` e, com mais de uma ligada, `NIER_LAB_VM=<vm>` em todo comando;
- `lab/up` já espera o SSH (lab-sonda); `--no-wait` só quando o cenário mede o boot por conta própria.

```
export NIER_LAB_CPUS=2 NIER_LAB_MEM=4G
L=~/projects/nier-os-project/YoRHa-OS-private-wt/lab-009/lab
```

## 0. Antes de tudo: o retrato das bases (SC-002)

```
$L/ls; pgrep -af qemu-system
sha256sum ~/.local/share/nier-lab/vms/{basic,arch-limpo,hypr-base,arch-iso}.qcow2 > lab/009/bases.sha256
```
**Esperado:** o arquivo com 4 hashes, commitado na `lab-009` antes da primeira mudança. No fim do estudo,
`sha256sum -c lab/009/bases.sha256` dá `OK` nas 4.

## 0b. Spike do 3D (research A4, R4, R15): antes de qualquer coisa do Niri e do Mango

```
export NIER_LAB_VM=spike-3d
$L/perf begin "009: spike 3D niri/mango" --kind 009 --task 009/T…
$L/new spike-3d --from arch-iso; $L/up spike-3d --soft      # --soft só pra instalar, sem sessão
$L/ssh 'sudo pacman -S --noconfirm niri mangowm quickshell kitty grim wlr-randr'   # na data fixa
# login automático no tty1 + bash_profile provisório com `exec niri-session` (depois, `exec mango`)
$L/down spike-3d; NIER_LAB_COMPOSITOR=niri $L/up spike-3d   # --headless: virgl + egl-headless
# conferir:
$L/ipc niri msg --json outputs; $L/shot niri
$L/ipc 'mmsg get all-monitors'; $L/shot mango
$L/down spike-3d; $L/rm spike-3d; $L/perf end --result pass|fail
```
**Esperado:** os dois sobem com `--headless`, o `grim` captura, o `lab/ipc` responde. Também: o formato do
`MANGO_INSTANCE_SIGNATURE`, a forma de `--window` com cada um e as versões na data fixa. Se o
`egl-headless` não servir, o estudo para e pergunta ao dono (pergunta 3 do plano).

## 1. A cadeia do Hyprland sobre a `arch-iso` (US1, SC-001)

```
export NIER_LAB_VM=hypr-iso
$L/perf begin "009: hypr-iso" --kind 009 --task 009/T…
$L/bootstrap                       # monta a hypr-iso (e as outras) sem tocar no que existe
$L/ls                              # hypr-iso congelada, base arch-iso, compositor hyprland
export NIER_LAB_VM=teste-hiso
$L/new teste-hiso --from hypr-iso
NIER_LAB_PROFILE=hidpi $L/up teste-hiso
$L/sync --src ~/projects/nier-os-project/YoRHa-OS/shell     # a main (a3a9120)
$L/check-u1; $L/check-003; $L/check-003 --profile hidpi; $L/check-004
$L/down teste-hiso; $L/perf end --result pass|fail
```
**Esperado:** `check-u1` 15/0, `check-003` 25/0 (nos dois perfis), `check-004` 58/0. Só aí a promoção:
`lab/new` passa a usar `hypr-iso` por padrão, o README do lab e a Central mudam. Com qualquer FAIL, nada
é promovido e a diferença vai pro relatório.

**Recriar as `teste-*` (FR-004), uma por vez:**
```
$L/ls; pgrep -af qemu-system; ls ~/.local/share/nier-lab/run/*.pid
# só se a camada não está ligada, nenhum qemu cita o disco dela e nenhuma camada tem ela como base:
$L/rm teste-a && $L/new teste-a --from hypr-iso
```
**Esperado:** cada `teste-*` livre recriada; as ocupadas listadas como pendentes no `central/resumao.md`.

## 2. Niri e Mango no lab (US2, SC-003, SC-004, SC-005)

```
$L/bootstrap                       # cria niri-base e mango-base se faltarem; de novo: não faz nada
$L/ls                              # as duas congeladas, base arch-iso, compositor niri / mango
for c in niri mango; do
  export NIER_LAB_VM=teste-$c
  $L/new teste-$c --from $c-base
  $L/up teste-$c
  $L/sync --src ~/projects/nier-os-project/YoRHa-OS/shell
  $L/shot; $L/ipc env | grep -E 'WAYLAND|NIRI|XDG_CURRENT'
  $L/profile 1080; $L/profile hidpi; $L/profile 1080
  $L/key alt-ret; $L/shot kitty; $L/key alt-q; $L/shot fechou
  $L/key alt-i; $L/shot config; $L/key esc
  $L/key alt-w; $L/shot seletor; $L/key esc
  $L/key alt-2; $L/shot area2; $L/key alt-1
  $L/click 960 540; $L/burst 8 0 full teste
  $L/down teste-$c
done
```
**Esperado:** `lab/009/ferramentas.tsv` com as 30 linhas (10 ferramentas × 3 compositores) e a prova de
cada uma; os 5 atalhos com screenshot nos 3 compositores. `lab/up teste-$c --window` é conferido junto
da sessão do dono (cenário 6). No Hyprland, os roteiros do cenário 1 rodam de novo depois das mudanças
nas ferramentas e continuam 15/0, 25/0, 58/0.

## 3. A UI da `main` em cada compositor (US3, SC-006, SC-007)

Em cada compositor, com o `ui.log` esvaziado antes e o `qs` reiniciado:
```
$L/ssh 'pkill -x qs; : > ~/nier/ui.log'; sleep 5
$L/shot barra; $L/key alt-i; $L/shot config; $L/key esc; $L/key alt-w; $L/shot seletor; $L/key esc
$L/profile hidpi; (os mesmos 4)
$L/ssh 'cat ~/nier/ui.log' > lab/009/ui/<c>/ui.log
```
**Esperado:** 8 screenshots por compositor (16 no total), `itens.tsv` com cada item classificado e
`import-hyprland.txt` com as linhas exatas do log (ou "silêncio" e o log inteiro). Se o `qs` entrar em
laço de reinício, o roteiro guarda as 3 primeiras partidas e para o `nier-ui-run`.

## 4. Amostras pro contrato (US4, SC-008)

Os cenários `S0`–`S3` e as linhas `L01`–`L10` e `Q-…` do [contrato de amostras](contracts/amostras.md),
nos três compositores (o Hyprland como referência).
**Esperado:** `index.tsv` com 100% das células do Niri e do Mango com estado; `tabela-s6.md` gerada;
`capabilities.json` com os 3 compositores.

## 5. Custo e animações (SC-009, FR-033)

Três rodadas por compositor, uma VM por vez, com `teste-<c>` recriada a cada rodada (disco igual):
```
$L/perf begin "009: custo <c> rodada N" --kind 009 --task 009/T…
$L/new teste-<c>-custo --from <base>; $L/up teste-<c>-custo --no-wait
# boot até a UI: do início do QEMU até a primeira linha do ui.log (relógio da VM, research R10)
sleep 120   # parado, sem janela
$L/perf end --result n/a; $L/down teste-<c>-custo; $L/rm teste-<c>-custo
```
Rajadas das 4 ações em cada compositor (`lab/burst` em segundo plano + o atalho).
**Esperado:** `custo.tsv` com 9 linhas e a mediana; `rajadas/<c>/<acao>/` com `resumo.txt`.

## 6. Sessão do dono (US5, SC-010)

```
NIER_LAB_VM=teste-niri $L/up teste-niri --window; NIER_LAB_VM=teste-niri $L/profile 1080
```
**Esperado:** um comando abre a janela com a UI; as colinhas (`lab/009/sessao/colinha-*.md`) têm até 30
linhas; a `folha.md` tem os 12 campos de nota vazios (mais o da visão geral "com plugin") e a evidência de cada um.

## 7. Hyprland com plugin (FR-038, SC-014)

Numa camada descartável `hypr-plugins` sobre a `hypr-iso` (nunca na cadeia padrão): o `hyprpm` com uma
cópia da comunidade do `hyprexpo` (o oficial saiu; research A5, R3, pergunta 2 do plano), rajada e
screenshot da visão geral, o tempo de compilação e o que quebra. As colunas do Hyprland são nativas e
entram na nota oficial (layout `scrolling` nas áreas 3–5 da sessão do dono). Apagar a camada no fim.

## 8. Relatório e fechamento (US6, SC-011, SC-012, SC-013)

- `docs/estudo-compositores.md`, etapa 1, no formato do [contrato do relatório](contracts/relatorio.md).
- `sha256sum -c lab/009/bases.sha256` → 4 × OK.
- Nos relatórios `lab/perf` do estudo, a lista de processos do host só tem ferramentas do lab; nenhuma
  sessão com mais de 2 VMs do estudo nem mais de 4 no total.
- Entrada no `central/resumao.md` e a Central atualizada.
- **Depois da folha do dono:** etapa 2 do relatório (notas dele, conta, recomendação).
