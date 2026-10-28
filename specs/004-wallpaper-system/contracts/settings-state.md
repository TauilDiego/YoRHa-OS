# Contrato: configurações salvas (`SettingsState`)

Decisão do dono de 2026-10-27, "salvar sempre": o que o usuário muda num menu continua depois de
reiniciar o shell. Emenda (3) da spec 004; revê a FR-018 da 003. As specs 007 (menu de pausa) e
008 (notificações) usam o mesmo mecanismo pras opções delas.

## Onde fica

- **Arquivo:** `$XDG_STATE_HOME/rien-os/settings.json` (sem a variável, `~/.local/state/rien-os/`).
  Nunca no `~/.config` (constituição III).
- **Formato:** `{ "version": 1, "values": { "<chave>": <valor JSON> } }`.
- **Leitura:** uma vez, quando o shell inicia, bloqueando (o primeiro quadro já sai com o valor salvo).
  Um arquivo ilegível vira estado vazio, com uma linha `INFO` no log.
- **Escrita:** 250 ms depois da última mudança, de uma vez, atômica (`FileView.atomicWrites`). A
  pasta é criada quando falta.
- **Prioridade:** estado > `shell.json` do usuário > `config/defaults.json`. A config continua sendo
  a base; o estado só sobrescreve.
- **Com fixtures** (`Fixtures.active`): o arquivo não é lido nem escrito. O estado vive só na memória
  (as trocas valem até a fixture mudar), então os testes não dependem da VM nem a sujam.

## API (`services/SettingsState.qml`, singleton)

| Membro | Tipo | Notas |
|---|---|---|
| `values` | objeto | Chave → valor; trocar avisa os bindings |
| `persisted` | bool | `false` com fixtures |
| `path` | string | O arquivo |
| `has(key)` | bool | |
| `get(key, fallback)` | var | O valor salvo ou `fallback` |
| `set(key, value)` | void | Salva (nada acontece se o valor é o mesmo) |
| `remove(key)` | void | Volta pra base |
| `clear(prefix)` | void | Apaga as chaves que começam com `prefix` |

**Chaves:** `"<dono>.<id>"`. Cada dono valida o que lê de volta e ignora um valor inválido.
- `settings.<categoria>.<opção>`: os valores do popup de configurações (toggle: bool; choice:
  índice; slider: 0–100);
- `shell.<chave>`: as configurações do shell trocadas ao vivo pelo popup (`shell.barContrast`:
  `"normal"` / `"high"`), lidas pelo `Settings`;
- `pause.…` (007) e `notifications.…` (008): reservados pras próximas specs.

## Catálogo de um menu (`settings.schema.json` da 003)

- **`"persist"`** (padrão `true`): `false` deixa uma opção fora do estado (volta ao valor do
  catálogo quando o shell reinicia).
- **`"setting": "<chave>"`** (só em choice): liga a opção a uma configuração do shell. O valor vem de
  `Settings.levelOf(chave)`, e a troca chama `Settings.setLevel(chave, nível)`, que salva em
  `shell.<chave>`. Os `values` seguem a ordem de `Settings.levelsOf(chave)`.
- **Reset** (`qs ipc call settings reset`): `SettingsState.clear("settings.")`, mais
  `Settings.setLevel(chave, "")` pra cada opção com `setting`. Volta tudo ao catálogo e à config, e
  o arquivo fica com `values` vazio.

**Pra um menu novo (007, 008):** use um prefixo próprio, leia com `get` (validando), escreva com
`set` e limpe o seu prefixo no reset do menu. Uma configuração do shell que outro lugar lê (como a
barra lê `barContrast`) vai pro `Settings`, com `levelsOf`/`levelOf`/`setLevel`.

## Evidência

`lab/check-004`, bloco "saved settings": sem fixtures, duas opções mudadas por teclas reais
continuam depois de reiniciar o `qs`; o único arquivo escrito fica em `~/.local/state/rien-os/`;
o `settings reset` volta ao catálogo e esvazia o estado, também depois de outro reinício.
