# Quickstart: rodar o estudo de instalação no laboratório

Roteiro de como os experimentos do [experimentos.md](experimentos.md) rodam no ambiente privado
(`YoRHa-OS-private/lab`). **Nada disso roda na máquina do dono** além das ferramentas do lab (QEMU,
Docker, `ssh`, `rsync`, o leitor do `lab/perf`). Toda linha que liga uma VM ou um container fica dentro
de uma sessão `lab/perf`.

Os comandos `lab/u2/*` ainda não existem: são criados pelas tarefas desta fase (`/speckit-tasks`), no
repositório privado (R15). Aqui fica o que cada um precisa fazer e o que se espera ver.

## Peças novas no lab (a criar)

| Comando | Faz |
|---|---|
| `lab/u2/base` | cria e congela a camada `u2-base` a partir da `arch-limpo` (Hyprland, uwsm, kitty, login automático, `u2-ui-run`, mirror fixo do Arch Linux Archive; **sem** Quickshell e sem as dependências da UI) |
| `lab/u2/carga <versão>` | gera a carga 0.1, 0.2 ou 0.3 a partir do commit fixado do `shell/` + remendos (`lab/u2/carga/`), num diretório de trabalho do lab |
| `lab/u2/fabrica <método> <versão>` | num container `nier-lab` (Arch, usuário sem privilégio): tarball + soma + assinatura (A, D), receita + `.SRCINFO` (B), `makepkg --sign` + `repo-add --sign` (C), com a chave descartável de `~/.local/share/nier-lab/u2/gnupg` |
| `lab/u2/servidor up\|down\|log` | container `nier-lab` com HTTP estático e log de bytes, em `127.0.0.1:<porta>`; a VM chega por `10.0.2.2:<porta>` |
| `lab/u2/publicar <método> <versão>` | põe o que a fábrica gerou no servidor (tag no git nu, receita, banco do pacman, `latest`) |
| `lab/u2/adulterar <método> carga\|tudo` | S8a / S8b |
| `lab/u2/rodar <método> <cenário> [--n N]` | cria `u2-<método>-<n>` da `u2-base`, liga, roda o cenário, coleta o registro ([contracts/run.schema.json](contracts/run.schema.json)), tira os screenshots, desliga e apaga a VM |
| `lab/u2/tabelas` | junta os registros em tabelas (mediana, mín., máx.) pro documento |

## Preparação (uma vez)

```sh
cd ~/projects/YoRHa-OS-private
lab/perf begin "005: preparação do estudo" --kind estudo --task 005
lab/u2/base                      # u2-base congelada; confere: findmnt -no FSTYPE / (R9), sem quickshell
lab/u2/servidor up
for v in 0.1 0.2 0.3; do lab/u2/carga $v; done
for m in A B C D; do for v in 0.1 0.2 0.3; do lab/u2/fabrica $m $v; done; done
lab/perf end --result pass --note "u2-base, servidor e artefatos prontos"
```

Antes da primeira medição: commit desta branch com o commit da carga, a data do mirror e os pesos
(experimentos §6.1).

## Validar os protótipos (repetição 0, não conta)

```sh
export NIER_LAB_CPUS=4 NIER_LAB_MEM=4G
for m in A B C D; do
  lab/perf begin "005: $m S1 #0 (validação)" --kind estudo --task 005
  lab/u2/publicar $m 0.1
  lab/u2/rodar $m S1 --n 0
  lab/perf end --result pass
done
```

**Esperado:** pros quatro, `yorha version` = `yorha-os 0.1 (<m>)`, screenshot com o HUD, `wallpaper dump`
responde, 0 erros de QML, `user_config_unchanged: true`. Só então o método passa a `prototipado`.

## Execuções de tempo (uma VM por vez)

```sh
n=0
for ordem in "A B C D" "D C B A" "A B C D"; do n=$((n+1))
  for m in $ordem; do
    for s in S1 S2 S3 S4; do
      lab/perf begin "005: $m $s #$n" --kind estudo --task 005
      lab/u2/rodar $m $s --n $n       # S2–S4 publicam a 0.2 antes, sozinhos
      lab/perf end --result pass
    done
  done
done
```

Nenhuma outra VM do estudo ligada durante essas execuções (outras fases podem estar usando `teste-*`;
isso fica anotado no `lab/perf` e o documento cita).

## Execuções de função (podem ir em paralelo, um agente por método)

Cada agente com sua worktree e `NIER_LAB_VM=u2-<m>-<n>` (porta própria):

| Cenário | Comando | Esperado / o que olhar |
|---|---|---|
| S5 | `lab/u2/rodar <m> S5` | 0.3 sem UI (log com o erro de QML de propósito); depois da volta, `yorha version` = 0.2, screenshot, `state_format` registrado |
| S6a/b/c | `lab/u2/rodar <m> S6a` (b, c) | registro com `live_version`, `state_format`, `recovery.steps` e `recovery.automatic`; recuperação seguida até a UI responder, ≤ 5 min |
| S7a/b | `lab/u2/rodar <m> S7a` (b) | `result: refused` ou `failed` com `message`; em b, `live_version` = 0.1 |
| S8a/b | `lab/u2/adulterar <m> carga` + `rodar <m> S8a`; `tudo` + `S8b` | quem recusa, com qual mensagem |
| S9 | `lab/u2/rodar <m> S9` | marcadores de migration de `beta` criados na entrada; nada fora de `~beta/.local/state/yorha-os` mudou |
| S10 | `lab/u2/rodar <m> S10` | conflito / sobrescrita / backup; a UI 0.2 abre ou não |
| S11 | `lab/u2/rodar <m> S11` | `leftovers` |
| S12 | o agente segue o `PUBLICAR.md` do protótipo (no lab), cronometrando | passos, tempo, segredos, infraestrutura |
| S13 (opcional) | `lab/u2/rodar <m> S13` | tempo e pacotes de build que ficam |
| B-ref | `lab/u2/rodar B-ref S1`: numa `u2-base` nova, instala o `yay` do AUR real e um pacote de shell Quickshell que já existe lá; só leitura | custo de instalar o helper e de montar no destino |

Cada linha dentro de `lab/perf begin "005: <m> <cenário>"` … `lab/perf end`.

## Fechamento

```sh
lab/u2/tabelas > ~/.local/share/nier-lab/out/u2/tabelas.md
lab/u2/servidor down
lab/ls                           # nenhuma u2-<m>-<n> sobrando; u2-base fica congelada
```

Com as tabelas e os registros, escrever `docs/estudo-instalacao.md` nesta branch (experimentos §7) e
conferir os critérios de sucesso:

| SC | Como conferir |
|---|---|
| SC-001 | 4 métodos × S1–S3 × 3 repetições = 36 registros com screenshot e `perf_run_id` |
| SC-002 | S5–S10 com pelo menos um registro por método |
| SC-003 | todos os registros com `user_config_unchanged: true`, ou o método marcado como eliminado (G1) |
| SC-004 | o `report.md` de cada sessão mostra no host só QEMU, Docker, `ssh`, `rsync` e o amostrador |
| SC-005 | toda célula da matriz tem id de execução ou R-n; a conta com pesos iguais está ao lado |
| SC-006 | pro método escolhido, cada S5–S8 tem `recovery.dur_s` ≤ 300 seguindo os passos escritos |
| SC-007 | seções 7 e 8 do documento preenchidas; o dono aprova a escolha |
