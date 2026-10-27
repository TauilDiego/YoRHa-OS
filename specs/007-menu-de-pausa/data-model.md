# Modelo de dados: Menu de pausa (007)

As entidades que a UI manipula. Os nomes de campo ficam em inglês, como no código. Os formatos dos
arquivos de teste estão em [contracts/pause-fixtures.schema.json](contracts/pause-fixtures.schema.json).

## Tab

| Campo | Tipo | Regras |
|---|---|---|
| `id` | enum `apps`, `windows`, `system`, `power` | Ordem fixa; Tab anda nessa ordem, dando a volta |
| `label` | string | `APPS`, `WINDOWS`, `SYSTEM`, `POWER` (do `Strings`) |
| `title`, `subtitle` | string | `APPS` / `-Launcher`, `WINDOWS` / `-Open Windows`, `SYSTEM` / `-Settings`, `POWER` / `-Session` |
| `footerLeft` | string | Calculado pela página (FR-014, FR-018, FR-019, FR-024) |
| `keys` | lista de string | O rodapé de teclas da página no foco atual, mais `Tab Next tab` |

A lista é dado (research R15): a 008 pode acrescentar uma aba.

## App

| Campo | Tipo | Fonte real | Regras |
|---|---|---|---|
| `id` | string | `DesktopEntry.id` | Único; repetido = descartado (vale o primeiro, que já é o do usuário) |
| `name` | string | `name` | Corta com reticências na lista |
| `genericName` | string | `genericName` | Pode ser vazio |
| `description` | string | `comment` | Vazio → o `genericName`; vazio também → `""` |
| `category` | string | primeira de `categories` que o projeto conhece, mapeada pra `System`, `Network`, `Media`, `Office`, `Development`, `Graphics`, `Game` ou `Other` | Escolhe o ícone genérico |
| `icon` | string (caminho) | `Quickshell.iconPath(icon, true)` | `""` → ícone genérico da categoria |
| `command` | lista de string | `command`, sem os códigos de campo | Nunca vazio (entrada sem comando fica de fora, com log) |
| `keywords` | lista de string | `keywords` | |
| `terminal` | bool | `runInTerminal` | `true` → abre com `Settings.terminal` |
| `workingDirectory` | string | `workingDirectory` | |
| `windowClass` | string | `startupClass`, ou o id sem `.desktop` | Pra contar as janelas abertas |
| `actions` | lista de `{ name, command }` | `actions` | Uma linha de opção por ação |
| `pinned` | bool | estado (R11) | |
| `uses` | int ≥ 0 | estado (R11) | +1 só quando o comando existe e foi disparado |
| `windows` | int ≥ 0 | calculado (`Compositor.windows` com o mesmo `class`) | Aparece à direita da linha quando > 0 |

**Lista sem busca:** grupo `PINNED` (os fixados, na ordem em que foram fixados) e grupo `ALL APPS`
(os outros), em A–Z pelo nome normalizado ou, com `App order = Most used`, por `uses` decrescente e
depois A–Z. Grupo vazio não aparece.

**Lista com busca:** só os resultados (research R5), sem grupos; o cabeçalho mostra `SEARCH`, a
consulta e `N RESULTS`; sem resultado, a linha `No apps match.`.

## Window

| Campo | Tipo | Fonte real (`hyprctl clients -j`) | Regras |
|---|---|---|---|
| `address` | string | `address` | `^0x[0-9a-f]+$`; chave da janela |
| `appClass` | string | `class` | |
| `app` | string | o `name` do App com o mesmo `windowClass`, ou o `class` | Mostrado à direita da linha |
| `title` | string | `title` | Vazio → `app` |
| `workspace` | int, ou `-1` pra especial | `workspace.id` (< 0 = especial) | |
| `workspaceName` | string | `workspace.name` | `special:…` vira o grupo `SPECIAL` |
| `monitor` | string | nome da saída (de `monitor`, o id, cruzado com `hyprctl monitors -j`) | |
| `x`, `y`, `w`, `h` | int | `at`, `size` | px lógicos do layout do compositor |
| `floating` | bool | `floating` | |
| `focused` | bool | `focusHistoryID == 0` | A marca `●` e a pipa inicial (FR-006) |

**Grupos:** um por área de trabalho com janela, `WORKSPACE 01`… em ordem de número, e `SPECIAL` por
último. Dentro do grupo: de cima pra baixo e da esquerda pra direita (`y`, depois `x`).

## Workspace

| Campo | Tipo | Regras |
|---|---|---|
| `id` | int (−1 = especial) | |
| `monitor` | string | |
| `windows` | lista de `address` | |

O mapa (`WorkspaceMap`) desenha o monitor da janela escolhida: o contorno na proporção do monitor
(largura e altura lógicas do `hyprctl monitors -j`, ou da fixture), a faixa da barra
(`Settings.barHeight`) e os retângulos das janelas da área de trabalho dela.

## PowerAction

| Campo | Tipo | Regras |
|---|---|---|
| `id` | enum `lock`, `logout`, `suspend`, `hibernate`, `reboot`, `poweroff` | Ordem da lista: Lock, Log out, Suspend, Hibernate, Reboot, Shut down |
| `label` | string | `Lock`, `Log out`, `Suspend`, `Hibernate`, `Reboot`, `Shut down` |
| `confirm` | bool | Calculado: `logout`/`reboot`/`poweroff` com `Confirm = Risky ones`; todas com `Every action` |
| `available` | bool | `Can<Ação>` = `yes`/`challenge`; `lock` e `logout` sempre |
| `reason` | string | Quando apagada: `Not supported on this machine.` / `Not allowed.` |
| `blockers` | lista de `{ who, why }` | Inibidores `block` do tipo certo (research R9) |
| `effect` | string | O que vai acontecer agora: `N open windows will close.` (Log out, Reboot, Shut down), `The session stays as it is.` (Lock, Suspend, Hibernate) |

## Session (status)

| Campo | Tipo | Fonte |
|---|---|---|
| `user` | string | `$USER` |
| `host` | string | `/proc/sys/kernel/hostname` |
| `uptime` | int (s) | `/proc/uptime`; mostrado como `2h 14m` (`Up 2h 14m` no rodapé) |
| `battery` | `{ percent, charging }` ou `null` | serviço `Battery` (001) |
| `windows` | int | `Compositor.windows.length` |
| `note` | string | `""` → `NO ERROR`; senão o aviso (ex.: o primeiro inibidor, ou `lastError`) em `alert` |
| `lastAction` | `{ id, at, executed }` ou `null` | A última ação disparada (com fixtures, `executed: false`) |
| `lastError` | string | A última recusa, mostrada no quadro até a próxima ação |

## MenuOption (categoria `menu` do catálogo de SYSTEM)

| id | Rótulo | `values` | `ids` | Padrão |
|---|---|---|---|---|
| `icons` | App icons | `Ink`, `Original color`, `Square only` | `ink`, `color`, `square` | 0 |
| `app-order` | App order | `A–Z`, `Most used` | `az`, `used` | 0 |
| `running-app` | Running app | `New window`, `Go to window` | `new`, `focus` | 0 |
| `confirm` | Confirm | `Risky ones`, `Every action` | `risky`, `all` | 0 |
| `confirm-start` | Dialog starts on | `Cancel`, `Action` | `cancel`, `action` | 0 |

Os `desc` (quadro) estão no contrato de serviços. O campo `ids` é opcional no catálogo e, quando
existe, tem o mesmo tamanho de `values`.

## Estado do menu (`PauseMenu` + `shell.qml`)

| Campo | Tipo | Notas |
|---|---|---|
| `open` | bool | |
| `monitor` | string | Onde abriu; não muda até fechar |
| `tab` | id de Tab | |
| `lastTab` | id de Tab | Pela sessão do shell; `apps` no começo |
| `column` | por aba: `list`/`options` (APPS, WINDOWS), `categories`/`options` (SYSTEM), `list` (POWER) | |
| `index` | por aba | A pipa guardada (FR-005) enquanto o menu está aberto |
| `query` | string | Busca de APPS; limpa ao fechar |
| `dialog` | `{ action, row }` ou `null` | `row`: `action` ou `cancel` |
| `lastAction` | `{ kind, id, detail }` ou `null` | `app` (id, ação, área), `window` (endereço, `focus`/`move`/`float`/`close`, área), `power` (id) |

**Transições:**

```
fechado --(atalho geral / pause open / pause toggle)--> aberto em lastTab
fechado --(SUPER+I / settings open|toggle / pause tab X)--> aberto em X
aberto em X --(Tab / Shift+Tab / clique na aba / pause tab Y / SUPER+I com X≠system)--> aberto em Y
aberto --(atalho geral / Esc na 1ª coluna sem busca / clique fora / pause close / SUPER+I em system)--> fechado
aberto em power --(Enter numa ação que confirma)--> diálogo
diálogo --(Esc / clique fora / Cancel / perda de foco)--> aberto em power (pipa na ação)
diálogo --(confirma)--> executa (R9)
```

Ao fechar: a busca é limpa, as pipas guardadas são esquecidas (as regras de abertura da FR-006
valem de novo) e `lastTab` fica com a aba em que o menu estava.

## Arquivo de estado dos apps (`$XDG_STATE_HOME/rien-os/apps.json`)

```json
{ "version": 1, "pinned": ["kitty.desktop", "firefox.desktop"], "uses": { "kitty.desktop": 42 } }
```

Ids que não existem mais são mantidos (o app pode voltar) e ignorados na lista.

## Fixtures

A fixture `shell/fixtures/pause-default.json` tem os domínios da `hud-default.json` mais três
domínios novos, cada um o caminho de um arquivo (como o `settings` da 003):

| Domínio | Arquivo | Conteúdo |
|---|---|---|
| `apps` | `fixtures/pause/apps.json` | ≈30 apps do mockup (nomes, nomes genéricos, descrições, categorias, comandos, palavras-chave, ações, ícones de `fixtures/pause/icons/`), 4 fixados e as contagens de uso |
| `windows` | `fixtures/pause/windows.json` | o monitor (nome, largura, altura), 7 janelas em 3 áreas de trabalho + 1 na especial, com posição, tamanho, flutuante e a em foco |
| `session` | `fixtures/pause/session.json` | usuário, host, uptime, as capacidades (Hibernate `no`), um inibidor `block` de `shutdown` ("pacman", "System update in progress") e o resto |

**Fixtures de borda:**
- `pause-empty.json`: nenhuma janela, catálogo com 3 apps, nenhum fixado;
- `pause-long.json`: nomes e títulos enormes, 60 apps (rolagem), dois monitores, a área especial;
- `pause-broken.json`: os três domínios apontam pra arquivos que não existem (cada aba mostra o
  erro curto no quadro; as outras abas e SYSTEM funcionam);
- `pause-live.json`: os domínios da `hud-default.json` e `apps`, **sem** `windows` e `session`, pra
  WINDOWS ler as janelas reais com o catálogo fixo (SC-006). Mesmo assim, nenhuma ação de energia
  executa com fixture ativa (R9).
