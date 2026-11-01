# Contrato: IPC (o que muda na 013)

Chamada: `qs -p <pasta da UI> ipc call <alvo> <função> [args]`; no lab, `lab/ipc 'qs -p ~/nier/ui ipc call …'`.

## `pause`

| Função | Retorno | Uso |
|---|---|---|
| `open(tab)` | — | Agora aceita `log` (US8). Sem argumento, abre na última aba |
| `dump()` | JSON | Ganha `presentation`, `anim` e `choice` (data-model.md) |
| `fps(cmd)` | `"ok"` / JSON | `start` zera e começa a contar; `stop` devolve `{ frames, seconds, mean, p95, worstMs }` (research R7). Só pros testes |
| `choice(cmd, arg)` | `"ok"` / `"error: …"` | `open` (na opção com foco), `pick <i>`, `toggle <i>`, `close`. Pros testes da US6 |

## `notify`

| Função | Mudança |
|---|---|
| `open()` / `toggle()` | Viram atalhos de `pause open log` / alternar o menu na aba LOG (o `LogPopup` sai) |

## `sounds` (novo)

| Função | Retorno | Uso |
|---|---|---|
| `play(event)` | `"ok"` / `"error: …"` | Toca um evento (contracts/sounds.md) |
| `dump()` | JSON | `{ enabled, volume, folder, overrides: [eventos], last: [{ event, t }] }` (sem `typing`: não há som de digitação). `t` é o `Date.now()` do `play()` (ms, relógio da VM), pra comparar com os ataques do `lab/013/audio-rec onsets` |

## `settings`

As chaves novas (data-model.md) mudam por `settings set <chave> <valor>` e aparecem no `settings dump`
(`shellValues`). O valor é lido como JSON quando dá (`true`, `40`), senão como texto. Uma lista vai
separada por vírgula (`settings set input.kbLayouts us,br`), porque o `qs ipc call` não passa os
colchetes. `null` volta pro valor da configuração.
