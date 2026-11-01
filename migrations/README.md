# Migrations

Mudanças que rodam uma vez só no estado da pessoa quando chega uma versão nova (spec 014,
data-model.md).

- **Arquivo:** `AAAAMMDDhhmm-<nome>.sh`, bash, idempotente, rodando como a pessoa.
- **Quando roda:** no `yorha update`, depois da troca de versão. Roda em ordem e só as que ainda não
  têm marca em `~/.local/state/yorha-os/migrations/`.
- **O ambiente:** `YORHA_STATE`, `YORHA_CONFIG` e `YORHA_FROM` (a versão de onde o estado veio).
- **Regra:** nunca escrever em `~/.config/yorha-os` sem backup. Se uma falhar, o update para, e o
  `yorha rollback` volta tudo.
- **Instalação nova:** as migrations que vêm com a versão contam como feitas.

A v0 não tem nenhuma.
