# Data model: SYSTEM de verdade

## Opção do catálogo (acréscimos)

| Campo | Tipo | Regra |
|---|---|---|
| `setting` | string | Passa a aceitar `sys.<provedor>.<chave>`, com `<provedor>` em `audio`, `power`, `display`, `input` (e `proof`, só no catálogo de teste) |
| `requires` | string | Capacidade do compositor; sem ela, a linha some (FR-045) |
| `opens` | string | Só em `action`: `sys.<provedor>.<chave>` cuja lista abre na janelinha, só leitura |

Uma linha `sys.*` **não** tem `value`, `default` nem `values` no catálogo (FR-002): `problemOf` e o schema recusam esses
campos nela. Tipos aceitos: `choice`, `slider`, `toggle`, `info`.

## Chaves salvas em `settings.json`

| Chave | Valor | Quem grava | Observação |
|---|---|---|---|
| `shell.uiScale` | número, 0,5–3,0 | `Settings` (1D) | FR-032, FR-033 |
| `shell.barHeight` | inteiro, 28–96 | `Settings` (1D) | FR-032, FR-033 |
| `input.repeatDelay` | inteiro, ms | `SysInput` (1C) | FR-024 |
| `input.repeatRate` | inteiro, ≥ 5 | `SysInput` (1C) | FR-024, FR-028 |
| `input.capsRule` | `""`, `caps:escape` ou `ctrl:nocaps` | `SysInput` (1C) | `""` = sem regra do Caps, salva de propósito |
| `input.kbLayouts` | lista | já existe (013) | Duas bases: `kb_layout` e `kbLayouts` |
| `fileBase.compositor` | `{ session, values: { repeatDelay, repeatRate, capsPart, kbLayout } }` | `FileWins` | Guardada mesmo pra linha nunca mexida (FR-039) |
| `fileBase.shell` | `{ "<chave salva>": <valor cru do shell.json> }` | `FileWins` | Ausente do mapa = ausente do arquivo |

**Nunca salvas:** saída, volume, mudo, microfone, luz de tela (FR-017).

**Removidas na subida (FR-007):** `SettingsModel.retired` lista `settings.sound.{output,volume,mute,mic}`,
`settings.display.{resolution,refresh,scale,brightness}`, `settings.keyboard.{caps,delay,rate}` e
`settings.appearance.{ui-scale,bar-height}`. A remoção é idempotente e não depende de a frente da linha já ter entrado.

## Transições da regra do arquivo

```text
leitura (gatilho, valores, erros)
  gatilho = start, sessão gravada = sessão atual → não compara; reaplica o salvo
  gatilho = start, sessão diferente             → como reload
  gatilho = reload, com erros de config          → não compara; reaplica o salvo
  gatilho = reload, sem erros:
    sem base gravada                              → grava a base; nada é esquecido; reaplica
    por chave: valor lido = base                  → reaplica o salvo, se houver
    por chave: valor lido ≠ base                  → grava a base nova; esquece o salvo; não reaplica
```

No `shell.json` é igual, com dois gatilhos: subida do shell e arquivo mudou. Ilegível, sem permissão, ou JSON que não é
objeto: nada acontece. `FileNotFound`: todas as chaves viram ausentes, o que é uma edição das que estavam lá.

## Fixtures novos (schema de `specs/001-yorha-base-hud`)

| Domínio | Forma |
|---|---|
| `audioDevices` | `{ sinks: [{ id, label, volume, muted }], sources: [{ id, label, volume, muted }], defaultSink, defaultSource }` |
| `brightness` | `null` (sem luz de tela), ou `{ percent, device, tool }`; `tool: false` = sem `brightnessctl` |
| `monitors` | `[{ name, width, height, refreshRate, scale, focused }]` |
| `input` | `{ repeatDelay, repeatRate, kbOptions, kbLayout, modifier }`; `modifier: null` = o compositor não disse |
| `sysProof` | `{ level: { choice, slider, toggle, info }, list: [{ id, label }], available, reason, failWrites }`, só pro catálogo de prova |

## Catálogos

| Arquivo | Papel |
|---|---|
| `shell/fixtures/settings-default.json` | Catálogo do produto (FR-019 da 003, revista) |
| `shell/fixtures/settings-showroom.json` | Cópia do catálogo em `670a99f`, congelada: a mecânica das checks antigas |
| `shell/fixtures/settings-proof.json` | Só a categoria de prova, ligada a `sys.proof.*` |
