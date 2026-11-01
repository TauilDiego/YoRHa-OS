# Contrato: o Updater do shell e SYSTEM › Updates

## `services/Updater.qml` (singleton)
| Propriedade | Valor |
|---|---|
| `installed` | `true` quando o `qs` subiu com `YORHA_OS_ROOT` (pelo `yorha shell start`) |
| `current` | a versão em uso (`$YORHA_OS_ROOT/VERSION`) |
| `latest`, `available` | da última conferência |
| `state` | `not-installed` \| `idle` \| `checking` \| `error` |

- **Conferência:** `$YORHA_OS_ROOT/bin/yorha update --check --json`, 30 s depois de subir e a cada hora.
  Com erro, `state=error` e nada aparece pra pessoa.
- **Aviso:** versão nova e diferente de `notified` vira `NotifyStore.system("Update available", "Version
  0.N is ready.", "normal", …)` com a ação de abrir SYSTEM › Updates. O `notified` é gravado em
  `updates.json`.
- **`updateNow()`:** abre o terminal da config rodando o `yorha update` (research R7).
- **IPC `updates`:** `check` (força) e `dump` (as propriedades em JSON).

## SYSTEM › Updates (categoria `updates` do catálogo)
| Opção | Tipo | Texto |
|---|---|---|
| `installed` | `info` | "Installed" · `0.M` (ou "Not installed with yorha") |
| `available` | `info` | "Available" · `0.N` ou "Up to date" |
| `update-now` | `action` | "Update now", visível só com `available` |
