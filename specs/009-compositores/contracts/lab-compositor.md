# Contrato: o laboratório com três compositores

Como o lab privado (`rien-OS-private/lab/`, branch `lab-009`) passa a lidar com Hyprland, Niri e Mango.
**Regra de ouro:** no Hyprland, todo comando faz exatamente o que faz hoje (os roteiros `check-u1`,
`check-003` e `check-004` provam). Os comandos dos compositores vêm do [research](../research.md) (R4–R7)
e são conferidos no spike 0, na VM; uma divergência corrige este contrato antes do código.

Versões de referência (research R1–R3, R15): Hyprland 0.56.2, `niri` 26.04, `mangowm` 0.18.3,
`quickshell` 0.3.2, todos do repositório oficial, numa data fixa do Arch Linux Archive.

## 1. A marca de compositor

- **Arquivo:** `$LAB_HOME/vms/<base>.compositor`, uma linha: `hyprland`, `niri` ou `mango`.
- **Quem grava:** o `lab/bootstrap`, ao congelar `hypr-iso`, `niri-base` e `mango-base`. As camadas de
  cima não ganham arquivo: herdam.
- **Quem lê:** `compositor_of <vm>` no `lib.sh`:
  1. `NIER_LAB_COMPOSITOR`, se definida (pra testes e spikes);
  2. `vms/<vm>.compositor`, se existir;
  3. senão, repete com a base (`vms/<vm>.base`), até a raiz;
  4. sem marca na cadeia: `hyprland` (a `hypr-base` antiga e as camadas dela continuam iguais).
- `lab/ls` mostra uma coluna `COMPOSITOR`.

## 2. A sessão gráfica pelo SSH (`GUEST_ENV`)

O `GUEST_ENV` continua montando `LANG`, `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY` e
`HYPRLAND_INSTANCE_SIGNATURE` como hoje, e **acrescenta** duas variáveis, só quando existem:

| Variável | De onde vem | Quem usa |
|---|---|---|
| `NIRI_SOCKET` | o primeiro `$XDG_RUNTIME_DIR/niri.*.sock` | `niri msg` |
| `MANGO_INSTANCE_SIGNATURE` | o ambiente da sessão de usuário do systemd (`systemctl --user show-environment`, onde o Mango exporta), ou o `/proc/<pid>/environ` de um processo filho da sessão (o `nier-ui-run`) | `mmsg` |

A regra exata (formato do valor do Mango) é conferida no spike 0. Variável vazia não é exportada. No
Hyprland nenhuma das duas existe, então o ambiente dos comandos fica igual ao de hoje.

## 3. Cada ferramenta

| Comando | Hyprland (hoje, sem mudança) | Niri | Mango |
|---|---|---|---|
| `lab/up` | `--headless`, `--window`, `--soft` | `--headless` (virgl + `egl-headless`) e `--window`; **recusa `--soft`** e o fallback "sem GPU" com a mensagem "o niri exige 3D" (research A4) | igual ao Niri ("o mango exige 3D") |
| `lab/shot` | `grim -` na VM; fallback `screendump` | `grim -` (wlr-screencopy v3); sem fallback (sem 3D não há sessão) | `grim -` (wlr-screencopy); sem fallback |
| `lab/burst` | `grim` em laço | igual | igual |
| `lab/ipc <cmd>` | `GUEST_ENV` + comando | igual (`niri msg --json …`) | igual (`mmsg get …`, `wlr-randr`) |
| `lab/profile 1080\|hidpi` | `hyprctl eval 'hl.monitor(…)'`; leitura `hyprctl monitors -j` | `niri msg output <saída> mode 1920x1080@60\|2560x1600@60` e `… scale 1\|1.25`; leitura `niri msg --json outputs` (`logical.scale`) | `wlr-randr --output <saída> --mode … --scale …`; leitura `wlr-randr --json` |
| `lab/sync` | escreve `~/.config/hypr/hyprland.lua` se mudou e roda `hyprctl reload`; reinicia o `nier-ui-run` com `hyprctl eval 'hl.exec_cmd(…)'` | escreve `~/.config/niri/config.kdl` (recarga automática ao salvar; `niri msg action load-config-file` pra forçar); reinicia o `nier-ui-run` com `niri msg action spawn -- ~/.local/bin/nier-ui-run` | escreve `~/.config/mango/config.conf` (recarga automática na 0.18; `mmsg dispatch reload_config` pra forçar); reinicia com `mmsg dispatch spawn,~/.local/bin/nier-ui-run` |
| `lab/click x y` | tamanho lógico de `hyprctl monitors -j` | de `niri msg --json outputs` (`logical.width/height`) | de `wlr-randr --json` (modo ÷ escala) |
| `lab/key` | QMP | QMP (sem mudança) | QMP (sem mudança) |
| `lab/cursor` | `hyprctl setcursor` | instala o tema; `cursor { xcursor-theme "…"; xcursor-size N }` na config do lab | instala o tema; a opção de cursor da config do Mango (nome conferido no spike) |
| `lab/check-*` | roteiros oficiais | só como informação (FR-018) | idem |

- Com o compositor `niri` ou `mango`, o `lab/sync` **não** escreve o `hyprland.lua`, e vice-versa: cada
  VM recebe só a config do próprio compositor.
- **Sem sessão gráfica ainda:** o `lab/sync` só escreve o arquivo; o compositor lê na próxima partida.
- **Operação sem suporte:** sai com código 3 e `"<comando>: <compositor> não suporta <o quê>"`; a linha
  da tabela de ferramentas fica `falha` com o contorno.

## 4. As preparações (`lab/provision/<base>.sh`)

Rodam **na VM**, como o usuário `arch` (sudo sem senha da `arch-iso`), no molde da `hypr-base.sh`:

1. espelho do Arch Linux Archive na data fixa (research R15; variável `LAB_ALA_DATE`, a mesma nas três),
   `pacman -Sy archlinux-keyring`, `pacman -Su`;
2. pacotes comuns: `quickshell kitty mesa grim wl-clipboard rsync jq qt6-declarative qt6-svg qt6-5compat
   qt6-shadertools qt6-wayland noto-fonts ttf-jetbrains-mono-nerd`;
3. o compositor:
   - Hyprland: `hyprland uwsm xdg-desktop-portal-hyprland` (a `hypr-base.sh` de hoje, só com o passo 1);
   - Niri: `niri` (sem `xwayland-satellite` nem portal de screencast);
   - Mango: `mangowm wlr-randr`;
4. login automático no tty1 (o `getty-autologin.conf` de hoje) e o `~/.bash_profile` da camada
   (`lab/guest/<c>/bash_profile`), que só age no tty1 e sem sessão aberta:
   - Hyprland: `exec uwsm start hyprland.desktop` (hoje);
   - Niri: `exec niri-session`;
   - Mango: `exec mango`;
5. a config do compositor e o `nier-ui-run` (o mesmo dos três), iniciado pela config:
   `hl.on("hyprland.start", …)`, `spawn-at-startup "…/nier-ui-run"`, `exec_once=…/nier-ui-run`;
6. fuso do host (`LAB_TZ`), `daemon-reload`;
7. grava `~/.config/nier-lab/compositor` (só informação dentro da VM) e imprime as versões (compositor,
   Quickshell, Qt, Mesa, data do arquivo histórico) pra `lab/009/versoes/<c>.txt`.

O `nier-ui-run` ganha uma linha (igual nos três): grava a hora em que o `qs` começa e o `/proc/uptime`
em `~/nier/ui.start`, pra medir o boot até a UI (research R10).

## 5. As configs mínimas (`lab/guest/`)

**Atalhos do lab, iguais nos três** (FR-011), ALT no lugar de SUPER:

| Atalho | Hyprland (`hyprland.lua`) | Niri (`niri/config.kdl`) | Mango (`mango/config.conf`) |
|---|---|---|---|
| `ALT+Enter` | `hl.dsp.exec_cmd("kitty")` | `Alt+Return { spawn "kitty"; }` | `bind=ALT,Return,spawn,kitty` |
| `ALT+Q` | `hl.dsp.window.close()` | `Alt+Q repeat=false { close-window; }` | `bind=ALT,q,killclient` |
| `ALT+I` | `exec_cmd("qs -p ~/nier/ui ipc call settings toggle")` | `Alt+I { spawn-sh "qs -p ~/nier/ui ipc call settings toggle"; }` | `bind=ALT,i,spawn_shell,qs -p ~/nier/ui ipc call settings toggle` |
| `ALT+W` | `… wallpaper picker toggle` | `Alt+W { spawn-sh "…"; }` | `bind=ALT,w,spawn_shell,…` |
| `ALT+1…5` | área N (**novo** no `hyprland.lua`) | `Alt+1 { focus-workspace 1; }` … | `bind=ALT,1,view,1` … |

**Atalhos nativos pra sessão do dono** (trocados pra ALT; listados na colinha):

| Ação | Hyprland | Niri | Mango |
|---|---|---|---|
| Visão geral | — (só com plugin, linha à parte) | `Alt+O { toggle-overview; }` (padrão `Mod+O`) | `bind=ALT,o,toggleoverview` |
| Colunas: foco e rolagem | layout `scrolling` nas áreas 3–5, mensagens `hl.dsp.layout(…)` em `ALT+←/→` | `focus-column-left/right`, `move-column-left/right` | layout `scroller` (`setlayout`), `focusdir` |
| Mover janela pra área | `ALT+SHIFT+N` | `Alt+Shift+N { move-window-to-workspace N; }` | `bind=ALT+SHIFT,N,tag,N` |
| Tela cheia / flutuar | `ALT+F` / `ALT+V` | `fullscreen-window` / `toggle-window-floating` | `togglefullscreen` / `togglefloating` |

Os nomes exatos dos atalhos nativos (Niri e Mango) são conferidos na config padrão de cada um na VM.

**Regras comuns:** sem blur, sem cantos arredondados, monitor no modo preferido e escala 1 (como o
`hyprland.lua` do lab); **animações no padrão de cada compositor** (é o que o dono avalia).

**O Hyprland e os outros agentes:** o `guest/hyprland.lua` é levado pelo `lab/sync` pras `teste-*` de
todo mundo. Ele só ganha acréscimos: `ALT+1…5` e, no fim, um `dofile` protegido de
`~/.config/hypr/local.lua`, que só existe na camada da sessão do dono (o layout `scrolling` nas áreas 3–5
e os atalhos nativos da tabela acima: colunas, mover, tela cheia, flutuar). Nas outras camadas o arquivo não existe e nada muda.

## 6. `lab/bootstrap`

Ordem, pulando o que já existe:

```
basic → arch-limpo → hypr-base               (como hoje; nada muda)
arch-iso        se faltar: lab/install-iso (spec 006)
hypr-iso        lab/new --from arch-iso; provision/hypr-base.sh; down; freeze; marca hyprland
niri-base       lab/new --from arch-iso; provision/niri-base.sh;  down; freeze; marca niri
mango-base      lab/new --from arch-iso; provision/mango-base.sh; down; freeze; marca mango
dev             (como hoje; num lab vazio, depois da promoção, nasce da hypr-iso)
```

Antes de criar cada base, o `bootstrap` confere que nenhuma VM com o mesmo nome está ligada; nunca
refaz uma base que existe. A `arch-iso` tem a chave do lab, mas **não** tem `rsync` (o archinstall só
acrescenta o `openssh`), então a cópia de `guest/` e `provision/` continua por `tar` pelo SSH, como na
`hypr-base`. As preparações recebem `LAB_TZ` e `LAB_ALA_DATE`.

## 7. `lab/new`

Base padrão: `hypr-base` até a promoção; depois, `hypr-iso` (uma linha no `lab/new` e no README). O
`--from` continua aceitando qualquer base.
