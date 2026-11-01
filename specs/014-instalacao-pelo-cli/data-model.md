# Data model: Instalação e encaixe do shell, v0 pelo CLI

## Versão
- **Número:** `0.N`. O `N` é a contagem de commits da ref seguida, pelo primeiro pai (research R1).
- **Arquivo:** `yorha-os-0.N.tar.gz`, o `git archive` do commit com um `VERSION` dentro, e o
  `yorha-os-0.N.tar.gz.sha256`.
- **Regra:** o `update` só vai pra um número maior que o em uso. Pra voltar, é o `rollback`.

## Canal (no lab)
- **Fonte:** um repositório ou worktree e uma ref (padrão: `main`).
- **Estado:** `~/.local/share/nier-lab/014/canal.json`, com `{ "source": "<pasta>", "ref": "<ref>" }`.
- **Endpoints:** ver `contracts/canal.md`.

## Pasta do produto: `~/.local/share/yorha-os/`
| Caminho | O que é |
|---|---|
| `versions/<v>/` | Uma versão desempacotada, imutável (guarda 3) |
| `versions/.<v>.part/` | Desempacotamento em andamento; apagado no próximo `update` |
| `current` → `versions/<v>` | Link relativo, trocado de forma atômica |
| `previous` | O número da versão antes do último `update` (pro `rollback`) |
| `downloads/<v>/` | Download em andamento; apagado depois de conferir |
| `channel` | O endereço do canal |

Mais os links `~/.local/bin/yorha` → `current/bin/yorha`.

## Estado: `~/.local/state/yorha-os/`
| Caminho | O que é |
|---|---|
| `settings.json`, `sound.json`, … | O que os menus salvam (já existe) |
| `migrations/<id>` | Uma marca por migration feita |
| `last-version` | A versão da última vez que as migrations rodaram |
| `backups/<v>/` | A cópia do estado antes do update que saiu da versão `<v>` |
| `updates.json` | `{ "lastCheck": <epoch>, "notified": "0.N", "latest": "0.N" }` (o Updater do shell) |

## Config: `~/.config/yorha-os/`
Só da pessoa (`shell.json`). Nada da 014 escreve aqui.

## Migration
- **Arquivo:** `migrations/<AAAAMMDDhhmm>-<nome>.sh`, com bash idempotente e o usuário como dono.
- **Quando roda:** no `update`, depois da troca. Roda em ordem e só o que não tem marca.
- **Se falhar:** o `update` para e diz qual migration, e o `rollback` volta tudo.

## Dependência (`system/deps`)
Uma linha por pacote: `<pacote> <obrigatória|opcional> <motivo>`.
