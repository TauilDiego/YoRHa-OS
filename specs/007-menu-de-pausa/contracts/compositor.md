# Contrato: adaptador do compositor

**Status:** aprovado pelo dono em 2026-10-28 (tarefa T012a). Implementado na T012a: fachada +
`HyprlandBackend.qml` + `NullBackend.qml`; o `NiriBackend` e o `MangoBackend` ficam pro estudo 009 (até
lá, `niri` e `mango` caem no `NullBackend`, com um aviso no log). Entra na 007 antes da frente B
(WINDOWS), porque é nela que o código preso ao Hyprland quase dobra.

**Por quê:** o dono quer experimentar o Niri e o Mango (MangoWC), além do Hyprland. Hoje só o
`services/Compositor.qml` fala com o Hyprland, mas a interface dele tem formas do Hyprland: ids
inteiros de área de trabalho, endereços `0x…` e posições absolutas das janelas. Este contrato tira
essas formas da interface sem mudar nada pra quem usa.

## 1. Divisão

```
shell/services/Compositor.qml          fachada (singleton): a única coisa que a UI usa
shell/services/compositor/
    HyprlandBackend.qml                fala com o Hyprland (Quickshell.Hyprland + hyprctl)
    NiriBackend.qml                    S5 / estudo 009: niri msg --json
    MangoBackend.qml                   estudo 009: mmsg
    NullBackend.qml                    sem compositor conhecido: listas vazias, ações recusadas
```

- **A fachada** guarda o que não depende de compositor:
  - as fixtures (`workspaces`, `activeWindow`, `windows`, `notifications.fullscreen`);
  - as validações e o `lastWindowAction`;
  - a regra das abas da barra (§4);
  - o `revision` e o `windowsRevision`.

  Hoje isso está misturado com o Hyprland; depois da mudança, fica num lugar só.
- **O backend** só lê o estado ao vivo e executa ações. Ele não sabe de fixtures.
- **A escolha do backend** é feita uma vez, na partida, pelo ambiente:
  1. `NIER_COMPOSITOR` (`hyprland`, `niri`, `mango`): força um, pra testes;
  2. `HYPRLAND_INSTANCE_SIGNATURE` → Hyprland;
  3. `NIRI_SOCKET` → Niri;
  4. `XDG_CURRENT_DESKTOP` contendo `mango` → Mango (a confirmar no 009);
  5. nenhum → `NullBackend`, com um aviso no log.

  O backend é criado por um `Loader`, então só o arquivo escolhido é carregado. **Conferido na
  T012a:** com `NIER_COMPOSITOR=none`, o `HyprlandBackend.qml` não é compilado (nenhum `import
  Quickshell.Hyprland` acontece) e a barra e o menu abrem com 0 erros de QML.

## 2. Tipos

Os ids são **strings opacas**, e a UI nunca interpreta o conteúdo. No Hyprland, o id da janela
continua sendo o endereço `0x…`, então as fixtures da 007 não mudam.

```
Monitor   { name, x, y, w, h, scale, focused }          // w/h lógicos (tamanho ÷ escala)
Workspace { key, index, label, monitor, focused, exists, windows: [id] }
Window    { id, appClass, title, workspaceKey, monitor, floating, focused, focusOrder,
            fullscreen, rect: {x, y, w, h} | null, column: {index, row} | null }
```

- `Workspace.key` identifica a área (Hyprland: o id em texto; Niri: o id interno; Mango: o número
  da tag). `index` é a posição 1, 2, 3… no monitor, que é o número que a barra mostra.
- `Window.rect` é a posição lógica, quando o compositor tem posições livres (Hyprland, Mango
  flutuante). `column` serve pros layouts em colunas que rolam (Niri, o scroller do Mango). Um dos
  dois vem preenchido; o mapa da aba WINDOWS desenha conforme o que vier.

## 3. O que cada backend declara

```
capabilities {
    workspaceModel:   "numbered" | "dynamic" | "tags"
    canFloat:         bool
    canMoveToWorkspace: bool
    actsOnAnyWindow:  bool      // false: as ações só valem pra janela em foco (foca antes)
    hasGeometry:      "rect" | "columns" | "none"
    fullscreenKnown:  bool
}
```

A UI usa as capacidades pra se adaptar sem saber o nome do compositor:
- `canFloat = false` → a ação "Float" some do menu da janela;
- `actsOnAnyWindow = false` → a fachada foca a janela antes de mover ou fechar;
- `hasGeometry = "none"` → o mapa vira uma lista por área de trabalho.

## 4. Interface da fachada (a única que a UI enxerga)

Tudo o que já existe continua com o mesmo nome. Os acréscimos estão marcados com **novo**.

| Membro | Tipo | Notas |
|---|---|---|
| `backendName` **novo** | string | `"hyprland"`, `"niri"`, `"mango"` ou `"none"`; aparece no `pause dump` e no log |
| `capabilities` **novo** | objeto (§3) | Com fixture: as do Hyprland, pra que as imagens de referência não mudem |
| `monitorScales` | `{ name: scale }` | Como hoje |
| `focusedMonitor` | string | Como hoje (com fixture, a primeira tela) |
| `refreshFocusedMonitor()` | void | Como hoje |
| `monitorList` | lista de `Monitor` | Como na 007 |
| `activeTitle` | string | Como hoje |
| `focusedFullscreen` | bool | Como na 008; `false` quando `fullscreenKnown = false` |
| `refreshFullscreen()` | void | Como na 008 |
| `workspacesFor(monitor)` | lista de `{ id, exists, focused, monitor }` | **Mesma forma de hoje**: `id` = `index`. A regra das abas depende do modelo: `numbered` e `tags`, de 1 até max(5, maior existente, foco); `dynamic`, as que existem no monitor, sem completar até 5 |
| `focus(index)` | void | Vai pra área `index` do monitor em foco (o backend converte pra `key`) |
| `workspaceList` | lista de `Workspace` | Como na 007, com `key` e `index` |
| `windows` | lista de `Window` | Como na 007, com `id` no lugar de `address` (o `address` continua como sinônimo enquanto a 007 migra) |
| `focusWindow(id)` | `"ok"` / `"error: …"` | Como na 007 |
| `moveWindow(id, index)` | `"ok"` / `"error: …"` | `index` 1–10 no monitor da janela, sem seguir. `error: unsupported` sem `canMoveToWorkspace` |
| `toggleFloating(id)` | `"ok"` / `"error: …"` | `error: unsupported` sem `canFloat` |
| `closeWindow(id)` | `"ok"` / `"error: …"` | Pedido educado |
| `lastWindowAction` | `{ kind, id, workspace }` ou `null` | Como na 007 |
| `revision`, `windowsRevision` | int | Como hoje |

## 5. Interface do backend (interna)

```
readonly property string name
readonly property var capabilities
readonly property var monitors          // [Monitor]
readonly property var workspaces        // [Workspace], key e index preenchidos
readonly property var windows           // [Window]
readonly property string activeTitle
readonly property bool fullscreen
signal changed()                        // a fachada sobe revision/windowsRevision
function activeIndexOn(monitor): int    // a área mostrada no monitor (0 = nenhuma conhecida); a regra das abas da barra
function refresh(what)                  // "monitors" | "windows" | "fullscreen" | "all"
function focusWorkspace(key)
function focusWindow(id)
function moveWindow(id, key)
function toggleFloating(id)
function closeWindow(id)
function validId(id): bool
```

As ações devolvem `void`, e o resultado chega pelo `changed()`. A fachada devolve `"ok"` depois
de validar, como faz hoje.

## 6. Como cada compositor responde

O Hyprland é o que existe hoje. **As colunas do Niri e do Mango são hipóteses, conferidas no
estudo 009.**

| Precisa de | Hyprland (hoje) | Niri (a confirmar) | Mango (a confirmar) |
|---|---|---|---|
| Monitores e escala | `hyprctl monitors -j` | `niri msg --json outputs` | `wlr-output-management` ou `mmsg` |
| Monitor em foco | campo `focused` | `niri msg --json focused-output` | `mmsg -g` |
| Áreas de trabalho | `Hyprland.workspaces`, `hyprctl workspaces -j` | `niri msg --json workspaces` (`id`, `idx`, `output`) | tags por saída, via `mmsg -g` |
| Janelas | `hyprctl clients -j` | `niri msg --json windows` | foreign-toplevel (sem a tag?) + `mmsg` |
| Janela ativa e tela cheia | `hyprctl activewindow -j` | `focused-window` (tela cheia: ?) | `mmsg -g` (título; tela cheia: ?) |
| Eventos | `Hyprland.rawEvent` | `niri msg --json event-stream` | `mmsg -w` (watch) |
| Ir pra área | `hl.dsp.focus({ workspace })` | `action focus-workspace <idx>` | `mmsg -d view,<tag>` |
| Focar janela | dispatch por endereço | `action focus-window --id` | só a janela em foco? |
| Mover, flutuar, fechar | dispatch por endereço | `move-window-to-workspace`, `toggle-window-floating`, `close-window` (com `--id`) | `tag`, `togglefloating`, `killclient` na janela em foco |
| Modelo | `numbered` | `dynamic` | `tags` |

## 7. O que muda nas tarefas da 007

- **Nova tarefa, antes da frente B:**
  - dividir o `Compositor.qml` em fachada + `HyprlandBackend.qml`, sem mudar o comportamento;
  - `NullBackend.qml`;
  - escolha do backend pelo ambiente;
  - `backendName` e `capabilities` no `pause dump`.

  **Prova:** `check-u1`, `check-003` e `check-004` com os mesmos números de antes, e 0 px de
  diferença nas imagens de referência.
- **A frente B (WINDOWS)** implementa o `dispatchWindow` no `HyprlandBackend`, e não na fachada.
  O mapa desenha a partir de `rect`/`column`, e as ações escondem o que as `capabilities` negam.
- **O `check-007`** ganha um bloco que roda com `NIER_COMPOSITOR=none`: a barra e o menu abrem sem
  compositor, com listas vazias e 0 erros de QML.
- **Fora da 007:** os backends do Niri e do Mango (S5, depois do estudo 009) e o gerador de atalhos
  (`config.kdl`, `config.conf` do Mango), que o `PLAN.md` já prevê.
