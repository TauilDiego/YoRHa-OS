# Contrato: serviços (003)

Os serviços da 001 continuam como estão, com um acréscimo no `Compositor`. O serviço novo segue as
mesmas regras: a UI lê dados só dele, e uma leitura que falha nunca lança erro na UI.

| Serviço | Expõe | Fonte | Domínio da fixture |
|---|---|---|---|
| `SettingsModel` (novo) | ver abaixo | `shell/fixtures/settings-default.json` | `settings`: caminho de outro catálogo |
| `Compositor` (acréscimo) | `focusedMonitor: string`, `refreshFocusedMonitor(): void` | `hyprctl monitors -j` (campo `focused`), a mesma consulta da escala | — (com fixtures, o monitor é o primeiro de `Quickshell.screens`) |

## `SettingsModel` (`shell/services/SettingsModel.qml`, singleton)

| Membro | Tipo | Notas |
|---|---|---|
| `categories` | lista de `Category` (data-model) | Na ordem do arquivo |
| `error` | string | `""` quando o catálogo carregou; senão, a mensagem curta mostrada no quadro (caso de borda) |
| `busy` | string | `"cat.opt"` da opção com ação em andamento, ou `""`. Limpa sozinho depois de `motion.actionBusy` |
| `value(catId, optId)` | var | `bool` (liga/desliga), `int` índice (escolha), `int` 0–100 (slider), `null` (ação, informação) |
| `display(catId, optId)` | string | O texto do valor: `ON`/`OFF`, o rótulo da escolha, o número, o texto da ação ou da informação |
| `defaultDisplay(catId, optId)` | string | O mesmo, pro valor padrão; `""` se a opção não tem padrão |
| `isDimmed(catId, optId)` | bool | `needs` aponta pra um liga/desliga desligado (FR-017) |
| `needsText(catId, optId)` | string | A mensagem do catálogo pro `needs` da opção ("Turn on Bluetooth first.") |
| `step(catId, optId, dir)` | void | ←/→: alterna (liga/desliga), anda sem dar a volta (escolha), soma `dir × step` com limite 0–100 (slider). Nada se `isDimmed` |
| `activate(catId, optId)` | void | Enter: alterna, avança dando a volta (escolha), dispara o aviso (ação). Nada se `isDimmed` ou informação |
| `pick(catId, optId, v)` | void | Slider: valor = `round(v × 100)` |
| `reset()` | void | Volta todos os valores ao catálogo (IPC, research R12) |
| `dumpValues()` | objeto | `{ catId: { optId: valor de exibição } }` pro `settings dump` |
| `dimmedIds()` | lista | As opções apagadas, como `"cat.opt"`, pro `settings dump` |

**Domínio `settings` das fixtures:** listado no `fixtures.schema.json` da 001 desde o acabamento da
004 (2026-10-27), junto com o domínio `wallpaper` da 004.

**Regras:**
- As mudanças só valem em memória (FR-018). Nada é gravado.
- Catálogo inválido: `categories` vazio, `error` preenchido, um `console.warn` com o motivo.
