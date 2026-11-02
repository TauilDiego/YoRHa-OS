# Contrato: o sinal de versão nova e a conferência automática

## SYSTEM › Updates

| id | Rótulo | Tipo | Texto de ajuda |
|---|---|---|---|
| `installed` | Installed | info | (014) |
| `available` | Available | info | (014) |
| `update-now` | Update now | action | (014) |
| `sign` | Update sign | choice: Bar · Menu · Bar and menu · Each login · Off (ids `bar`, `menu`, `both`, `login`, `off`), padrão `both` | "How a newer version stays on screen until you update. Off shows only the first transmission." |
| `auto-check` | Check automatically | toggle, padrão ligado | "Checks for a newer version 30 s after the shell starts and then every hour. Off: only `yorha update` checks." |

## As formas (`Updater.sign`)

| Forma | Com `Updater.available` verdadeiro |
|---|---|
| `bar` | `hud/UpdateTag.qml` na barra: quadrado + `UPDATE` + `<latest>`, antes do contador do LOG, no tom e na placa da barra (como o `LogCounter`). Clique → `Updater.showUpdates()` |
| `menu` | Tag `NEW` (a mesma `Tag` e o mesmo texto do LOG) na aba SYSTEM do `TabBar` e na linha da categoria Updates |
| `both` | `bar` + `menu` |
| `login` | Nada fixo; a transmissão da 014 volta uma vez por login enquanto houver versão nova (trava `update-reminded-<latest>` em `$XDG_RUNTIME_DIR/<nome>`) |
| `off` | Só a transmissão da primeira vez (014) |

- A transmissão da primeira vez continua em todas as formas.
- Trocar a forma vale na hora (binding), sem reiniciar o shell.
- Com `available` falso (depois do update), nada aparece em nenhuma forma.

## A conferência automática (`Updater.autoCheck`)

- Os timers de 30 s e de 1 h rodam só com `installed && autoCheck`.
- Desligada: `check()` roda ao abrir SYSTEM › Updates e pelo IPC `updates check`.

## IPC `updates` (o `dump` ganha campos)

`dump` → `{ …(014), "sign": "both", "autoCheck": true, "timers": { "first": false, "hourly": true },
"signVisible": { "bar": true, "menuTab": true, "menuRow": true } }`

O `check-015` usa esses campos junto com os screenshots.
