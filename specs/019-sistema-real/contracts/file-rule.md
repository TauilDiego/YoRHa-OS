# Contrato: o arquivo editado vence (`FileWins`)

Singleton `shell/services/FileWins.qml`, da etapa 0. Implementa as FR-026, FR-027 e FR-039 a FR-043. Com
`SettingsState.persisted` falso (fixtures), não faz nada. As transições estão em `data-model.md`.

## O que ele expõe

| Membro | Uso |
|---|---|
| `compositorRules` | `[{ saved, file, part }]`: `input.repeatDelay`↔`repeatDelay`, `input.repeatRate`↔`repeatRate`, `input.capsRule`↔`kbOptions` (parte do Caps), `input.kbLayouts`↔`kbLayout` |
| `shellRules` | Montadas de `Settings.keys` (`config`), mais `shell.barContrast` e `notifications.<k>` de `notificationFallback` |
| `capsPart(kbOptions)`, `mergeCaps(kbOptions, rule)` | Funções puras da R3 |
| `applySaved()` | Monta um `setConfigValues` com o salvo sobre os valores do arquivo |
| `dump()` | `fileBase` no `settings dump` |

## O que uma frente faz com ele

- **1C:** só grava `input.*` em `SettingsState` e chama `FileWins.applySaved()`. Não compara nada.
- **1D:** só usa `Settings.setKey`. As chaves `shell.uiScale` e `shell.barHeight` já estão nas `shellRules` pela etapa 0.
- Uma chave nova com arquivo por trás entra em `Settings.keys` (etapa 2 em diante) e ganha a regra sozinha.

## Garantias

- A comparação nunca olha `merged`, só `Settings.user` cru (FR-043).
- Esquecer a chave e gravar a base nova acontecem no mesmo `SettingsState`, na mesma escrita atômica.
- Um reload sem base gravada nunca esquece nada.
- `settings reset` não apaga `fileBase.*`: a base é do arquivo, não da escolha.

## O limite

O que está em "Limite" nos Edge Cases da spec continua limite: mesmo valor gravado, `eval` antes da primeira subida, reload
com o shell desligado. A prova da T003 pode acrescentar um (R1, P1); nesse caso, ele vai pro dono.
