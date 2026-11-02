# Contrato: o `install.sh` e o `yorha` (o que muda da 014)

O resto continua como em `specs/014-instalacao-pelo-cli/contracts/cli.md`: as saídas, as mensagens
`yorha: …` em inglês e o "sem terminal interativo, a resposta é não".

## `install.sh`

```sh
bash <(curl -fsSL https://github.com/TauilDiego/YoRHa-Shell/releases/latest/download/install.sh)
```

| Variável | Efeito | Padrão |
|---|---|---|
| `YORHA_ORIGIN` | Uma origem no lugar das padrão (lab, espelho), ou várias separadas por espaço (a principal primeiro) | As origens do `name.sh` gravadas na release |
| `YORHA_CHANNEL` | `stable` ou `testing` | `stable` |
| `YORHA_YES` | `1` responde "sim" a tudo (automação, lab) | — |

- Sem nenhuma variável, instala a estável mais nova (FR-001). A versão vem do `latest` da origem; o
  pacote e o `.sha256`, de `releases/download/v<v>/`.
- Escreve `origins` e `channel` em `$YORHA_HOME` (data-model.md).
- `YORHA_OS_CHANNEL` (da 014) deixa de existir.
- As saídas 0–4 continuam; a 1 cobre também "nenhuma origem respondeu".

## `yorha`

| Comando | Muda | Saída |
|---|---|---|
| `status` | Mostra também o canal (`stable`/`testing`), as origens e, depois de uma troca de nome, a linha nova pro `hyprland.lua` | 0 |
| `channel` | **Novo.** Mostra o canal | 0 |
| `channel stable\|testing` | **Novo.** Troca o canal; a próxima conferência já usa | 0; 2 valor errado |
| `update --check [--json]` | Lê o canal e as origens (contracts/canal-publico.md). O JSON ganha `"channel"` e `"origin"` (a que respondeu) | 0; 1 nenhuma origem respondeu |
| `update` | Depois de baixar e conferir, entrega o fim pra versão nova: `<nova>/bin/<cmd> _finish-update --from <v> --from-home <pasta>` | 0; 1; 4; 5 |
| `_finish-update --from <v> --from-home <pasta>` | **Novo, interno.** Na versão nova: troca de nome se preciso (research R6), copia o estado, troca o `current`, migra, poda, reinicia o shell | 0; 5 migration |
| `rollback` | Se a anterior tem outro nome, desfaz a troca antes de voltar | 0; 3 |
| `shell start` | Exporta `YORHA_ROOT` (era `YORHA_OS_ROOT`) e `YORHA_NAME` pro `qs`; segue o `renamed-to` em vez de parar | — |
| `uninstall` | Remove também o atalho, os links e a pasta de compatibilidade de um nome antigo | 0; 1 |
| `version` | `yorha-shell <v>` | 0 |

## `lib/yorha/name.sh`

```sh
YORHA_NAME=yorha-shell
YORHA_CMD=yorha
YORHA_PRETTY=YoRHa-Shell
YORHA_ORIGINS=(https://github.com/TauilDiego/YoRHa-Shell)   # 016: + the VPS mirror
# YORHA_HOME, YORHA_STATE, YORHA_CONFIG, YORHA_BIN, YORHA_KEEP as in 014
```

## `lib/yorha/channel.sh` (novo, o núcleo que as frentes usam)

| Função | Faz |
|---|---|
| `yorha_origins` | As origens em uso: `YORHA_ORIGIN`, ou `$YORHA_HOME/origins`, ou `YORHA_ORIGINS` |
| `yorha_channel` | `stable` ou `testing` (`YORHA_CHANNEL`, ou `$YORHA_HOME/channel`, ou `stable`) |
| `yorha_latest` | Imprime `<v> <origem>` da versão mais nova do canal, tentando as origens em ordem; 1 se nenhuma respondeu |
| `yorha_fetch_release <v> <pasta> [nome] [origem]` | Baixa o pacote e o `.sha256` de `<v>` pra `<pasta>`, da primeira origem que tiver os dois, e confere; 1 rede, 4 checksum. Com `[origem]` (a que respondeu o `yorha_latest`), começa por ela e segue as outras em ordem |

O `install.sh` não tem o `lib/` antes de baixar: ele carrega uma cópia mínima dessas duas funções
(`yorha_latest` e o download), gravada pelo `release build` a partir do `channel.sh` da mesma ref, pra
não haver duas versões do mesmo código.
