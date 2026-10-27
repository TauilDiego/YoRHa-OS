# Contrato: componentes do design system

É a interface pública de cada componente QML. Ela vem antes da fase paralela e **fica estável
durante ela** (princípio VI). Mudar uma interface exige atualizar este arquivo primeiro.

Regras para todos os componentes:
- `property real s: 1`: fator de escala da superfície (research R5). Toda medida é `Tokens.x * s`
  e toda linha é `Tokens.line(v, s)`.
- **Cores e fontes só via `Tokens`**, nada de literal.
- **Camadas:** um componente só importa das camadas abaixo da sua
  (tokens → primitives → base → composites).

## Primitivas (`shell/ds/primitives/`)

| Componente | Propriedades | Notas |
|---|---|---|
| `Label` | `text`, `role` (nome de estilo em `Tokens.type`), `color`, `upper: bool` | Texto com a tipografia do sistema |
| `Square` | `size` (padrão 22), `color` | O marcador |
| `Rule` | `kind`: `"plain"` / `"dotted"` / `"vertical"`, `color` | A pontilhada repete o padrão de pontos (§6) |
| `GridBackground` | `step` (padrão 7) | Papel + grid a 6% |
| `Vignette` | `enabled` | FR-002a. Overlay por cima de tudo. Só em tela cheia |
| `PaperDecor` | `phase` (0–1) | FR-019/FR-020. Arcos e feixes diagonais do fundo, desenhados uma vez; `phase` move as camadas sem repintar |

## Base (`shell/ds/base/`)

| Componente | Propriedades | Sinais | Notas |
|---|---|---|---|
| `HeaderButton` | `text`, `state`: `"normal"` / `"hovered"` / `"selected"` / `"dimmed"`, `reachRule: bool`, `ruleY` | `clicked()` | 214×47·s. Com `selected` + `reachRule`, uma haste desce até a régua logo depois da tinta (`motion.touch`) e recolhe ao perder a seleção (`motion.untouch`) (FR-011). Mostra o `Selector` em `hovered`/`selected`, a menos que `showSelector: false` |
| `ListItem` | `text`, `state` (os mesmos 4), `variant`: `"opaque"` / `"plain"`, `trailing: string` | `clicked()` | Faixa de tinta que pinta da esquerda pra direita + trilhos + sombra (FR-004) |
| `Selector` | `tone`: `"dark"` / `"light"`, `bobbing: bool` | — | Pipa + 2 quadradinhos, balançando juntos (FR-005). Congela quando `Tokens.motion.frozen` |
| `Meter` | `value` (0–1), `critical: bool`, `w` (padrão 163), `h` (padrão 11) | — | `hp-bar` chapado. Anima a mudança de valor. `critical` → `alert` (FR-007) |
| `PageHeader` | `title`, `subtitle` | — | Caixa alta + sombra proporcional (FR-006) |
| `Card` | `title`, `default property` (corpo), `footer` | — | Cabeçalho de tinta + corpo `lightYellow` |

## Compostos (`shell/ds/composites/`)

| Componente | Propriedades | Sinais | Notas |
|---|---|---|---|
| `TabBar` | `model`: lista de `{ label, state }`, `showSelector` (padrão true; o HUD usa false) | `activated(int index)` | Faixas verticais + abas + régua pontilhada embaixo. A aba selecionada desce até a régua. `tabGeometry(i)` → `{ x, w }` na janela |
| `CursorList` | `model`: lista de `{ label, trailing }`, `currentIndex` | `activated(int index)` | Faixas verticais + itens + seletor no item atual |

## Superfícies (`shell/hud/`, `shell/gallery/`)

| Componente | Propriedades | Notas |
|---|---|---|
| `Hud` | `screen` (`ShellScreen`) | Um por monitor (`Variants` sobre `Quickshell.screens`). `PanelWindow` no topo com `exclusiveZone` = altura (FR-009) |
| `Wallpaper` | `screen` (`ShellScreen`) | Um por monitor, camada Background, `GridBackground` + `PaperDecor` + `Vignette` (FR-019–FR-021) |
| `Gallery` | — | Tela cheia, `Overlay`, `Vignette` ligada se `Settings.vignette` (FR-002a). Abre e fecha por IPC; Esc fecha |
