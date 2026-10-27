# Modelo de dados: Configurações num popup

São as entidades que a UI manipula. Os nomes de campo ficam em inglês, como no código. O formato do
arquivo está em [contracts/settings.schema.json](contracts/settings.schema.json).

## Category

| Campo | Tipo | Regras |
|---|---|---|
| `id` | string | Único no catálogo; minúsculas (`display`, `bluetooth`) |
| `label` | string | Mostrado na lista e, em maiúsculas, no cabeçalho da coluna de opções |
| `about` | string | Frase do quadro quando o foco está na categoria |
| `options` | lista de `Option` | Ordem do arquivo; pode ser vazia (a coluna mostra só o cabeçalho) |

## Option

| Campo | Tipo | Regras |
|---|---|---|
| `id` | string | Único na categoria |
| `label` | string | Cortado com reticências se não couber |
| `type` | enum `toggle`, `choice`, `slider`, `action`, `info` | Define como o valor aparece e reage (FR-016) |
| `desc` | string | Descrição do quadro |
| `key` | string? | Só em `toggle`; outras opções dependem dele por `needs` |
| `needs` | string? | Com o toggle de mesmo `key` desligado → `dimmed` (FR-017) |
| `value`, `default` | bool / int | `toggle`: bool; `choice`: índice; `slider`: 0–100 |
| `values` | lista de string | Só `choice` |
| `step` | int | Só `slider` (passo de ←/→) |
| `text` | string | `action`: rótulo; `info`: texto |
| `busy` | string | Só `action`: aviso de andamento |

**Transições do valor (FR-016):**

| Tipo | ← / → | Enter | Clique |
|---|---|---|---|
| `toggle` | alterna | alterna | alterna (nas setas também) |
| `choice` | −1 / +1, sem dar a volta | +1, dando a volta | setas: −1/+1; no resto: +1 dando a volta |
| `slider` | −`step` / +`step`, limite 0–100 | — | na trilha: o ponto clicado |
| `action` | ← volta pras categorias | aviso por 2 s | igual a Enter |
| `info` | ← volta pras categorias | — | — |

Opção `dimmed`: nenhuma mudança; ← volta pras categorias.

## Catálogo padrão (`shell/fixtures/settings-default.json`)

As 7 categorias e as opções do mockup aprovado, com estes ids:

| Categoria | Opções (id: tipo) |
|---|---|
| `display` | `resolution: choice`, `refresh: choice`, `scale: choice`, `brightness: slider`, `night: toggle` |
| `sound` | `output: choice`, `volume: slider`, `mute: toggle`, `mic: slider`, `ui-sounds: toggle` |
| `network` | `wifi: toggle (key wifi)`, `network: choice (needs wifi)`, `wired: info`, `vpn: action`, `airplane: toggle` |
| `bluetooth` | `bluetooth: toggle (key bt)`, `keyboard: info (needs bt)`, `headphones: info (needs bt)`, `pair: action (needs bt)` |
| `appearance` | `ui-scale: choice`, `bar-height: choice`, `vignette: toggle`, `bg-motion: toggle`, `reduce-motion: toggle`, `cursor-size: choice`, `language: choice` |
| `keyboard` | `layout: choice`, `caps: choice`, `delay: choice`, `rate: slider`, `shortcuts: action` |
| `power` | `battery: info`, `profile: choice`, `screen-off: choice`, `suspend: choice`, `lid: choice` |

Os textos, valores e padrões são os do mockup (`rien-OS-private/lab/mockups/configuracoes/index.html`).
Nada disso mexe no sistema: até "Vignette" e "Reduce motion" são só dados aqui (FR-018). Ligar
opções de verdade fica pra uma spec futura.

**Fixtures de catálogo pros casos de borda** (domínio `settings` da fixture ativa):
- `settings-broken.json`: aponta pra um catálogo que não existe → `error`;
- `settings-long.json`: uma categoria com 14 opções e rótulos e valores longos → rolagem e reticências.

## Estado do popup (`SettingsPage` + `shell.qml`)

| Campo | Tipo | Notas |
|---|---|---|
| `open` | bool | Do `shell.qml` |
| `monitor` | string | Nome do monitor onde abriu (research R3) |
| `focus` | enum `categories`, `options` | Uma coluna só tem o foco (FR-010) |
| `category` | int | Índice; mover nas categorias troca as opções na hora |
| `option` | int | Índice; volta a 0 quando a categoria muda; `null` no `dump` com o foco nas categorias |

**Transições do foco (FR-010):**

```
categorias --(→ / Enter / clique na categoria)--> opções
opções --(Esc / ← numa linha que não muda)--> categorias
categorias --(Esc / clique fora / atalho)--> fechado
opções --(clique fora / atalho)--> fechado
```

Ao abrir de novo na mesma sessão, o foco volta pras categorias, na categoria em que estava.
