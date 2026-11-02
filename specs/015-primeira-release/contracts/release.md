# Contrato: `lab/015/release` (privado, roda no host)

python3, só biblioteca padrão. Lê o repositório pelo `git` e nunca executa código do projeto
(research R4). Saídas: 0 ok · 1 recusa (com o motivo numa linha) · 2 uso errado.

| Comando | Faz |
|---|---|
| `build <v> [--ref <ref>] [--pre] [--lab-only] [--notes <arquivo>]` | Monta `releases/v<v>/` (data-model.md). `--ref` padrão: `main` do repositório público. Sem `--notes`, gera o rascunho com os assuntos dos commits de primeiro pai desde a última tag `v*` |
| `list` | As releases montadas: versão, ref, commit, pré/estável, só-lab, publicada ou não, sha256 |
| `check <v>` | Repassa as conferências de arquivo proibido e de nome provisório sobre o pacote montado |
| `publish <v>` | Pede confirmação no terminal. Cria a release como rascunho (`gh release create v<v> --draft --target <commit> --title "YoRHa-Shell <v>" --notes-file NOTES.md [--prerelease]`, com os 6 arquivos), baixa cada arquivo de volta (`gh release download`) e compara o sha256; só então tira o rascunho (`gh release edit v<v> --draft=false`, com `--latest` numa estável). Grava `published` |
| `promote <v>` | Pede confirmação. `gh release edit v<v> --prerelease=false --latest`. Grava `pre: false` |

## As recusas do `build` (FR-005, SC-004)

1. O checkout da ref tem mudança não commitada (`git status --porcelain` não vazio).
2. `<v>` fora de `^[0-9]+\.[0-9]+\.[0-9]+$`; com `--lab-only`, fora de `^0\.0\.[0-9]+$`; sem
   `--lab-only`, começando por `0.0.`.
3. `<v>` já existe no índice ou nas tags do GitHub (`git ls-remote --tags origin`), ou não é maior que
   a maior versão publicável que existe (as `--lab-only` só se comparam entre si).
4. O pacote tem arquivo proibido ou o nome provisório fora da lista de histórico
   (contracts/nome.md).

## As recusas do `publish`

- A release é `--lab-only`.
- O commit não está no GitHub (`git branch -r --contains` em `origin/main`).
- Já existe a tag no GitHub.
- O `YORHA_ORIGINS[0]` do `name.sh` do commit não é o repositório do remote `origin` (o `install.sh`
  da release, e o update de quem a instala, pediriam as versões em outro lugar). O `promote` também
  recusa por isso. Até a T039 (`gh repo rename`) é o caso: a origem já é `TauilDiego/YoRHa-Shell`.
- O checksum baixado de volta é diferente do montado: a release continua rascunho (ninguém a vê), e
  o comando sai 1 dizendo o que fazer.

`publish` e `promote` aceitam `--dry-run`: fazem as conferências e imprimem os comandos do `gh` sem rodar
(saem 1 se alguma conferência recusou, listando todas). Sem terminal pra confirmar, a resposta é não.

Nenhum comando grava token ou credencial em arquivo; o `gh` usa a autenticação que já existe no host.
