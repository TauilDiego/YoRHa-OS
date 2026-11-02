# Data Model: Primeira release pública

Sem banco. Tudo é arquivo: na máquina de quem instala, numa release e no lab. O que não aparece aqui
continua como na 014 (`specs/014-instalacao-pelo-cli/data-model.md`).

## Na máquina de quem instala

Os nomes saem do `name.sh` da versão em uso. Com YoRHa-Shell:

| Caminho | Conteúdo | Muda na 015 |
|---|---|---|
| `~/.local/share/yorha-shell/versions/<v>/` | A versão desempacotada, imutável | Pasta renomeada (era `yorha-os`) |
| `~/.local/share/yorha-shell/current` | Link pra versão em uso | — |
| `~/.local/share/yorha-shell/previous` | A versão de antes do último update | — |
| `~/.local/share/yorha-shell/origins` | **Novo.** As origens, uma por linha, a principal primeiro (R3) | Substitui o `channel` da 014, que guardava a URL |
| `~/.local/share/yorha-shell/channel` | **Novo sentido:** `stable` ou `testing` | — |
| `~/.local/state/yorha-shell/` | O estado (menus, sons, `updates.json`, migrations, cópias) | Pasta renomeada |
| `~/.config/yorha-shell/` | A config da pessoa; o produto nunca escreve | Pasta renomeada |
| `~/.local/bin/yorha` | Link pro comando da versão em uso | — |
| `$XDG_RUNTIME_DIR/yorha-shell/` | Trava do supervisor, pid, `shell.root`, as travas por login | Pasta renomeada; ganha `update-reminded-<v>` (R7) |

**Depois de uma troca de nome** (R6, de `A` pra `B`):

| Caminho | O que fica lá |
|---|---|
| `~/.local/share/B/` | Tudo o que estava em `~/.local/share/A/` |
| `~/.local/share/A/renamed-to` | `B` e o caminho do comando novo |
| `~/.local/share/A/current/system/hypr/A.lua` | Uma linha: `pcall(dofile, <o B.lua da versão em uso>)` |
| `~/.local/state/A`, `~/.config/A` | Links pra `…/B` |
| `~/.local/bin/<cmd de A>` | Link pro comando de B (atalho) |
| `~/.local/state/B/renamed-from` | `A`, o comando antigo e a data (o rollback e o uninstall usam) |

O rollback desfaz isso na ordem inversa. O uninstall de B remove também o atalho, os links e a pasta
de compatibilidade de A.

## Configurações novas (SYSTEM › Updates)

Na categoria `updates` de `shell/fixtures/settings-default.json`:

| id | Tipo | Valores | Padrão |
|---|---|---|---|
| `sign` | choice | `bar` · `menu` · `both` · `login` · `off` | `both` |
| `auto-check` | toggle | — | ligado |

Elas são gravadas como as outras opções do menu. As opções `installed`, `available` e `update-now` da
014 continuam.

## Uma release

No GitHub, como `v<versão>`, e na pasta do lab, como `releases/v<versão>/`, com os mesmos arquivos:

| Arquivo | Conteúdo |
|---|---|
| `yorha-shell-<v>.tar.gz` | O `git archive` da ref, com o prefixo `yorha-shell-<v>/` e o `VERSION` virtual; sem o que é `export-ignore` |
| `yorha-shell-<v>.tar.gz.sha256` | `<sha256>  yorha-shell-<v>.tar.gz` |
| `latest` | `<v>` e uma quebra de linha |
| `install.sh` | O `install.sh` da ref, com a origem padrão gravada a partir do `name.sh` da mesma ref |
| `NOTES.md` | As notas: o que mudou e como atualizar. É também o corpo da release no GitHub |

**Marcas da release:**
- estável, ou pré-release (do canal de teste);
- só do lab (`--lab-only`): nunca vai pro GitHub, e o número é `0.0.N`.

## No lab (host, fora dos repositórios)

`~/.local/share/nier-lab/015/`:

| Caminho | Conteúdo |
|---|---|
| `releases/index.json` | Uma entrada por release: `version`, `commit`, `ref`, `pre`, `labOnly`, `built`, `sha256`, `published` (a data, quando foi pro GitHub) |
| `releases/v<v>/` | Os arquivos da release (acima) |
| `canal-<porta>.json`, `.pid`, `.log` | O estado e o log de cada instância do canal |

**As transições de uma release:**
1. `build` cria a entrada com `published: null`.
2. `publish` grava a data e o checksum conferido de volta.
3. `promote` muda `pre` pra falso.

Uma release `labOnly` não passa do passo 1.
