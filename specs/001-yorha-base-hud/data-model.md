# Modelo de dados: Base visual YoRHa e HUD

São as entidades que a UI manipula. Os nomes de campo ficam em inglês, como no código.

## Tokens (`ds/Tokens.qml`, singleton)

Fonte única dos valores do `docs/design-system.md`. Todos os tamanhos estão em pixels do jogo a
1080p.

| Grupo | Campos | Regras |
|---|---|---|
| `color` | `darkGray`, `mediumGray`, `lightGray`, `darkYellow`, `lightYellow`, `boxShadow`, `textShadow`, `grid`, `alert` | Valores do FR-001. Nenhuma cor fora daqui (verificável com grep por `#` fora do `Tokens.qml`) |
| `type` | `pageHeader`, `subheader`, `headerButton`, `listButton`, `cardHeader`, `standard`, `small`, `button`: cada um com `{ family, size, weight, letterSpacing }` | `family` = M PLUS 1, ou a original quando instalada (R7) |
| `shadow` | `text { ratio: 0.15 }`, `box { x: 3, y: 3 }`, `soft { x: 3, y: 3, blur: 4, color }` | O `text` é proporcional ao tamanho (FR-006) |
| `space` | `buttonMargin` 10, `pageMarginH` 62, `pageMarginV` 39, `tabH` 47, `tabW` 214, `meterW` 163, `meterH` 11, `selector { w: 32, h: 14, dot: 5, dotOffset: 10, gap: 7 }` | Medidas do §1, §3 e §6 |
| `motion` | `highlight` 150, `touch` 160, `untouch` 120, `blink` 240, `frozen` (bool) | `frozen` = true quando há fixtures (R8) |
| `vignette` | `edge` `#A6A18D`, `corner` `#8B8877` | FR-002a |
| funções | `line(v, s)`, `px(v, s)` | `line` ≥ 1 e inteiro |

## Settings (`services/Settings.qml`, singleton)

| Campo | Tipo | Padrão | Validação |
|---|---|---|---|
| `uiScale` | real | 1.0 | 0,5–3,0. Fora da faixa, usa o padrão e registra um aviso |
| `barHeight` | int | 68 | Limitado a 28–96 |
| `vignette` | bool | true | — |

Origem: `shell/config/defaults.json`, sobrescrito por `$XDG_CONFIG_HOME/rien-os/shell.json`.

## Workspace (do `services/Compositor.qml`)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | int | Só ids ≥ 1 (especiais e negativos ficam de fora) |
| `exists` | bool | O workspace existe no compositor |
| `focused` | bool | Em foco **no monitor da barra** |
| `monitor` | string | Nome do monitor |

**Lista de abas por monitor:** ids de 1 até `max(5, maior id existente, id em foco)`. O estado
de cada aba é `focused` → "em foco"; `exists` → "normal"; senão → "apagada" (FR-011).

## ActiveWindow

| Campo | Tipo | Notas |
|---|---|---|
| `title` | string | `""` quando não há janela ativa (o título fica vazio, sem erro) |

## Reading (telemetria)

| Campo | Tipo | Notas |
|---|---|---|
| `key` | enum `cpu`, `mem`, `vol`, `bat` | |
| `label` | string | De `Strings` (FR-018) |
| `value` | real 0–1 | Leitura que falha → 0 |
| `critical` | bool | `bat`: `value < 0.15` e sem carregar |
| `extra` | enum `none`, `charging`, `muted` | |
| `available` | bool | `bat` sem bateria → false, e a leitura some |

Atualização: `cpu` e `mem` a cada ≤ 2 s; `vol` e `bat` por evento.

## Clock

`date` (`SystemClock`, precisão de segundos), ou o valor fixo das fixtures. É exibido como
`yyyy.MM.dd` e `HH:mm:ss`.

## Fixtures (`services/Fixtures.qml`, singleton)

| Campo | Tipo | Notas |
|---|---|---|
| `active` | bool | true quando há algum JSON carregado |
| `source` | string | Caminho carregado (`NIER_FIXTURES` ou `load()`) |
| `clock`, `cpu`, `mem`, `volume`, `battery`, `workspaces`, `activeWindow` | opcionais | Formato em `contracts/fixtures.schema.json`. Domínio ausente = dado real |

**Transições:** sem fixtures → `load(path)` → com fixtures → `clear()` → sem fixtures. Cada
serviço reage na hora.

## Strings (`strings/Strings.qml`, singleton)

Todos os textos fixos (`CPU`, `MEM`, `VOL`, `BAT`, `SYSTEM`, nomes da galeria…), num lugar só
(FR-018).
