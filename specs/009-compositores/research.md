# Pesquisa (Fase 0): Niri e Mango no laboratório

Cada item segue o formato decisão, motivo e o que foi descartado. Tudo foi conferido na web em
2026-10-28 (fontes no fim de cada item). **Nenhuma VM foi ligada e nada rodou no host:** o que diz
"hipótese" é confirmado no começo da execução, na VM, e uma divergência corrige os contratos antes do
código.

## Achados que mudam o PRD, a spec ou o contrato da 007

| # | Achado | O que muda |
|---|---|---|
| A1 | O **MangoWC virou "mangowm"** (repositório `github.com/mangowm/mango`) e está no **repositório oficial** (`extra/mangowm` 0.18.3) | Não precisa de AUR (a decisão 2 do dono fica sem uso nos três); a suposição da spec ("o Mango vem do AUR") está errada |
| A2 | O **IPC do Mango mudou**: o protocolo dwl-ipc saiu na 0.15.0; o `mmsg` agora é `get`/`watch`/`dispatch`, responde **JSON** e fala por um socket em `$MANGO_INSTANCE_SIGNATURE`; `dispatch … client,<id>` age numa janela **fora de foco** | As hipóteses do §6 do contrato pro Mango (`mmsg -g`, `-w`, `-d`, "só a janela em foco", `wlr-output-management ou mmsg`) estão desatualizadas; `actsOnAnyWindow` provavelmente `true` |
| A3 | O **Niri não informa tela cheia** no IPC (nenhum campo `fullscreen`/`maximized` na 26.04) | `fullscreenKnown = false` no Niri, a não ser que a inferência (tamanho da janela = tamanho lógico da saída) se prove confiável na amostra |
| A4 | **Niri e Mango não rodam sem 3D**: o Niri recusa renderização por software (llvmpipe); o renderizador do Mango (scenefx) não tem fallback | O `lab/up --soft` e o fallback "sem GPU" do `--headless` não servem pra eles; o fallback `screendump` do `lab/shot` também não. O `egl-headless` com virgl é a hipótese principal e precisa do spike |
| A5 | **Hyprland:** a rolagem em colunas (`hyprscrolling`) **entrou no núcleo na 0.54**; o plugin de visão geral (`hyprexpo`) **saiu dos plugins oficiais** em 2026-05-12; não há visão geral nativa | A resposta 3 do dono ("plugins oficiais de visão geral e de colunas") não tem mais objeto: colunas são nativas, e visão geral oficial não existe. Pergunta 2 deste plano |
| A6 | **Hyprland 0.57.0 saiu hoje** (2026-10-28), com mudanças no Lua que podem quebrar configs; o Arch ainda tem 0.56.2 | Se o `pacman -Syu` da preparação pegar a 0.57, a `hypr-iso` difere da `hypr-base` (0.56) e os roteiros podem falhar por outro motivo. Pergunta 1 deste plano (fixar a data dos pacotes) |
| A7 | O **Quickshell 0.3.x** não tem módulo do Niri nem do Mango, mas tem um módulo genérico de áreas (`Quickshell.WindowManager`, protocolo ext-workspace, desde a 0.3.0) e o `ToplevelManager` (wlr-foreign-toplevel); **Niri e Mango implementam os dois** | Uma rota pra S5 que o contrato não previa: um backend genérico em cima dos protocolos, em vez de um por IPC. Vira uma amostra extra (`Q-quickshell-generico`) |

## R1. Niri: pacote e versão

- **Decisão:** `extra/niri` **26.04-1** (2026-04-25), GPL-3.0-or-later. Dependências opcionais que
  entram na camada: `xwayland-satellite` não (sem apps X11 no estudo); `xdg-desktop-portal-gnome` não
  (só pra screencast). O repositório mudou pra `github.com/niri-wm/niri`; a documentação está em
  `niri-wm.github.io/niri`.
- **Cadência:** v25.01, v25.02, v25.05 (2025-05-17), v25.05.1, v25.08 (2025-08-30), v25.11 (2025-11-29),
  v26.04 (2026-04-25): a cada 3–6 meses; a 26.04 já tem 6 meses (o maior intervalo até agora).
- **Fontes:** https://archlinux.org/packages/extra/x86_64/niri/ ;
  https://api.github.com/repos/niri-wm/niri/releases

## R2. Mango: pacote, versão e compilação

- **Decisão:** `extra/mangowm` **0.18.3-1** (2026-10-25), GPL-3.0-or-later, mantido no Arch por Robin
  Candau. Dependências: `wlroots0.20` (0.20.2), `scenefx` (0.5), seatd, libliftoff, libdisplay-info, cjson,
  pango, xorg-xwayland. O pacote traz `mango`, `mmsg`, `mangonag`, `mango.desktop`, o
  `mango-session.target` e `/etc/mango/config.conf`.
- **Sem AUR:** a decisão 2 do dono continua valendo como permissão, mas não é usada. O `mangowm-git` do
  AUR existe (não deu pra abrir a página: proteção contra robôs) e fica só como plano B.
- **Cadência e projeto:** 0.17.4 (2026-09-28), 0.17.5 (10-01), 0.18.0 (10-09, renomeou chaves da config,
  com script de migração, recarga automática e config em TOML), 0.18.1 (10-15), 0.18.2 (10-18), 0.18.3
  (10-24): **quase semanal**. Repositório de 2025-02-03, 88 contribuidores, mas **um só autor com 2.050
  commits** (o segundo tem 23). Pesa no risco de manutenção.
- **Descartado:** compilar à mão ou pelo AUR (o pacote oficial existe).
- **Fontes:** https://archlinux.org/packages/extra/x86_64/mangowm/ ;
  https://archlinux.org/packages/extra/x86_64/mangowm/files/ ;
  https://api.github.com/repos/mangowm/mango/releases ;
  https://api.github.com/repos/mangowm/mango/contributors ;
  https://raw.githubusercontent.com/mangowm/mango/main/meson.build

## R3. Hyprland: versão, colunas, visão geral e plugins

- **Versão:** `extra/hyprland` **0.56.2-4** (2026-10-03). A **0.57.0 saiu em 2026-10-28** com mudanças
  no Lua (`created` → `created_early`, `stable_id` como texto, `hl.bind` mais estrito, fim da config
  antiga). Cadência: uma versão menor a cada 2–3 meses, com correções no meio.
- **Colunas:** o layout `scrolling` está no núcleo desde a 0.54 (`hl.config({ scrolling = {…} })`,
  mensagens por `hl.dsp.layout()`, regra por área com `hl.workspace_rule`). Então a **rolagem em colunas
  é do Hyprland puro**: a sessão do dono liga esse layout nas áreas 3–5 (contrato, §5). A linha exata
  que escolhe o layout não foi lida (página cortada) e é conferida na VM.
- **Visão geral:** não existe no núcleo. O `hyprexpo` saiu do repositório oficial de plugins (PR #663,
  2026-05-12; sobraram `borders-plus-plus`, `csgo-vulkan-fix`, `hyprbars`, `hyprfocus`). Há cópias da
  comunidade, sem garantia de compilar na 0.56.2. As notas da 0.57 citam "overview" de passagem: pode
  estar vindo.
- **`hyprpm`:** pacote separado; `hyprpm update`, `hyprpm add <repo>`, `hyprpm enable <nome>`; compila
  na versão do Hyprland que está rodando.
- **Decisão (pendente da pergunta 2):** a nota oficial é do Hyprland puro, **com** o layout de colunas
  nativo. A linha "com plugin" fica só pra visão geral, com uma cópia da comunidade do `hyprexpo` numa
  camada descartável, se compilar; se não compilar, a linha diz isso (é evidência de risco).
- **Fontes:** https://archlinux.org/packages/extra/x86_64/hyprland/ ;
  https://github.com/hyprwm/Hyprland/releases/tag/v0.57.0 ; https://hypr.land/news/update54 ;
  https://wiki.hypr.land/0.56.0/Configuring/Layouts/Scrolling-Layout/ ;
  https://github.com/hyprwm/hyprland-plugins/pull/663 ; https://github.com/hyprwm/hyprland-plugins

## R4. Protocolos que a UI e o lab usam

| Protocolo | Pra quê | Hyprland | Niri 26.04 | Mango 0.18 |
|---|---|---|---|---|
| wlr-layer-shell | a barra e os pop-ups da UI | sim | sim (v5) | sim |
| wlr-screencopy | `grim` (`lab/shot`, `lab/burst`) | sim | sim (v3) | sim |
| ext-image-copy-capture | captura nova | — | **não** (PR aberto) | sim |
| wlr-output-management | `wlr-randr` (escala/modo) | sim | sim (v4) | sim |
| wlr-foreign-toplevel | lista de janelas (`ToplevelManager`) | sim | sim (v3) | sim |
| ext-foreign-toplevel-list | lista de janelas (novo) | — | sim | sim |
| ext-workspace | áreas (`Quickshell.WindowManager`) | (a conferir) | sim | sim |
| fractional-scale | escala 1,25 | sim | sim | sim |

- **Renderização:** o Niri exige EGL com aceleração (o mantenedor: "niri doesn't support software
  rendering, you must have 3d acceleration turned on"; PR de fallback aberto); `virtio-gpu` sem virgl dá
  `Missing required EGL extensions: ["EGL_EXT_device_drm"]`. O Mango sai com "couldn't create
  renderer" sem GL. Relatos de sucesso com `virtio-vga-gl` + `-display gtk,gl=on`; com `egl-headless` só
  um relato, com outra montagem. Hosts NVIDIA às vezes falham com `EGL_NOT_INITIALIZED`.
- **Decisão:** spike logo depois da `niri-base` e da `mango-base`: `lab/up --headless` (virgl +
  `egl-headless`, o que o lab usa) e `--window`. O `lab/up` recusa `--soft` nas camadas `niri` e `mango`
  (contrato, §3). Se o `egl-headless` não servir, o plano B é ligar com `--window` minimizada (custa uma
  janela no desktop do dono; só com o OK dele) ou com `-display egl-headless,rendernode=…` explícito.
- **Cursor:** com virtio-gpu, compositores wlroots podem mostrar o cursor invertido (bug do QEMU/virgl,
  corrigido no virglrenderer master); no Niri, `debug { disable-cursor-plane }` desenha o cursor no quadro.
  Só anotado; não pesa na nota.
- **Fontes:** https://wayland.app/protocols/ (tabelas de compatibilidade) ;
  https://github.com/niri-wm/niri/issues/3501 ; https://github.com/niri-wm/niri/pull/3959 ;
  https://github.com/niri-wm/niri/discussions/2570 ;
  https://raw.githubusercontent.com/mangowm/mango/main/src/main.c ;
  https://gitlab.com/qemu-project/qemu/-/issues/2315 ;
  https://niri-wm.github.io/niri/Configuration%3A-Debug-Options.html

## R5. Como cada um sobe (uwsm, login automático, autostart)

| | Hyprland | Niri | Mango |
|---|---|---|---|
| Jeito oficial | `uwsm start hyprland.desktop` (documentado, "pra usuários avançados") | `niri-session` (sobe o `niri.service`, `niri --session`, `graphical-session.target`) | `mango` direto do tty (sobe o próprio `mango-session.target`) |
| uwsm | sim (é o que o lab usa) | não documentado pelo Niri; o uwsm tem plugin pro Niri; o `niri.desktop` já chama o `niri-session` | nada no projeto; o `mango-session.target` pode brigar com as unidades do uwsm |
| Login automático (tty1) | `exec uwsm start hyprland.desktop` (hoje) | `exec niri-session` | `exec mango` |
| Autostart da UI | `hl.on("hyprland.start", …)` | `spawn-at-startup "…/nier-ui-run"` | `exec_once=…/nier-ui-run` (não `exec-once`) |
| `XDG_CURRENT_DESKTOP` | `Hyprland` | `niri` (só com `--session`) | `mango` |
| Variável do IPC | `HYPRLAND_INSTANCE_SIGNATURE` | `NIRI_SOCKET` | `MANGO_INSTANCE_SIGNATURE` |

- **Decisão:** cada um pelo **jeito oficial dele** (é o que o usuário teria): Hyprland com uwsm (como
  hoje), Niri com `niri-session`, Mango com `mango`. Os três terminam com uma sessão systemd de usuário
  (`graphical-session.target`), então o custo é comparável. Um spike curto tenta `uwsm start` no Niri e
  no Mango e anota (FR-008), sem virar o padrão.
- **Regra de detecção do §1 do contrato:** confirmada pras três variáveis; pro Mango, a variável própria
  (`MANGO_INSTANCE_SIGNATURE`) é melhor que procurar "mango" no `XDG_CURRENT_DESKTOP` (as duas valem).
- **Fontes:** https://wiki.hypr.land/0.56.0/Useful-Utilities/Systemd-start/ ;
  https://niri-wm.github.io/niri/Getting-Started.html ;
  https://raw.githubusercontent.com/niri-wm/niri/main/resources/niri.service ;
  https://man.archlinux.org/man/uwsm.1 ; https://mangowm.github.io/docs/quick-start ;
  https://mangowm.github.io/docs/configuration/basics

## R6. Niri: IPC × tabela §6 do contrato

| Linha do §6 | Hipótese do contrato | O que a 26.04 tem (fonte: código da tag v26.04) |
|---|---|---|
| Monitores e escala | `niri msg --json outputs` | Confirma: `logical {x,y,width,height,scale,transform}`, `modes`, `current_mode` |
| Monitor em foco | `focused-output` | Confirma |
| Áreas | `workspaces` (`id`, `idx`, `output`) | Confirma, mais `name`, `is_active`, `is_focused`, `is_urgent`, `active_window_id`. O `id` é estável mas não sequencial; o `idx` é a posição no monitor |
| Janelas | `windows` | Confirma: `id`, `title`, `app_id`, `pid`, `workspace_id`, `is_focused`, `is_floating`, `is_urgent`, `focus_timestamp`, `layout {pos_in_scrolling_layout: [coluna, linha] (desde 1; null se flutuante), tile_size, window_size, tile_pos_in_workspace_view, window_offset_in_tile}` |
| Janela ativa e tela cheia | `focused-window` (tela cheia: ?) | `focused-window` confirma; **tela cheia: não existe** (A3) |
| Eventos | `event-stream` | Confirma: estado inteiro primeiro, depois 19 tipos (`WorkspacesChanged`, `WorkspaceActivated`, `WindowOpenedOrChanged`, `WindowClosed`, `WindowFocusChanged`, `WindowLayoutsChanged`, `OverviewOpenedOrClosed`, `ConfigLoaded`…). Atualizações nem sempre atômicas |
| Ir pra área | `action focus-workspace <idx>` | Confirma. Índice maior que o número de áreas vai pra última (vazia) |
| Focar janela | `action focus-window --id` | Confirma (`--id` obrigatório) |
| Mover, flutuar, fechar | com `--id` | Confirma: `move-window-to-workspace --window-id N --focus false <idx>`, `toggle-window-floating --id`, `close-window --id` (sem `--id`, a em foco). Também `fullscreen-window --id` |
| Modelo | `dynamic` | Confirma: por monitor, sempre uma área vazia no fim; áreas vazias do meio somem |

- **`capabilities` propostas (hipótese):** `workspaceModel: dynamic`, `canFloat: true`,
  `canMoveToWorkspace: true`, `actsOnAnyWindow: true`, `hasGeometry: columns`, `fullscreenKnown: false`
  (ou `true` se a inferência passar na amostra `Q-niri-tela-cheia`).
- **Mapa da aba WINDOWS:** `pos_in_scrolling_layout` dá `column.index`/`row`; `tile_size` dá a largura
  relativa da coluna. Flutuantes vêm com `null` (desenhar à parte).
- **Saída por comando:** `niri msg output <nome> scale 1.25` e `mode 2560x1600@60` (temporário; some se a
  seção `output` da config mudar).
- **Fontes:** https://raw.githubusercontent.com/niri-wm/niri/v26.04/src/cli.rs ;
  https://niri-wm.github.io/niri/IPC.html ;
  https://niri-wm.github.io/niri/niri_ipc/struct.WindowLayout.html ;
  https://niri-wm.github.io/niri/niri_ipc/enum.OutputAction.html ;
  https://raw.githubusercontent.com/niri-wm/niri/v26.04/resources/default-config.kdl

## R7. Mango: IPC × tabela §6 do contrato

| Linha do §6 | Hipótese do contrato | O que a 0.18 tem (documentação e `mmsg.1`) |
|---|---|---|
| Monitores e escala | `wlr-output-management` ou `mmsg` | `mmsg get all-monitors` (JSON; campos a conferir) e `wlr-randr --json` |
| Monitor em foco | `mmsg -g` | `mmsg get all-monitors` (campo de foco a conferir) |
| Áreas | tags por saída, `mmsg -g` | `mmsg get tags <mon>` / `all-tags` / `tag <mon> <idx>` |
| Janelas | foreign-toplevel (sem a tag?) + `mmsg` | `mmsg get all-clients` / `client <id>`; se o JSON traz tag, flutuante e tela cheia **não está documentado** (amostra) |
| Janela ativa e tela cheia | `mmsg -g` (tela cheia: ?) | `mmsg get focusing-client` (campos a conferir) |
| Eventos | `mmsg -w` | `mmsg watch all-clients` / `all-tags` / `all-monitors` / `focusing-client`: estado atual, depois cada mudança |
| Ir pra área | `mmsg -d view,<tag>` | `mmsg dispatch view,<n>` |
| Focar janela | só a em foco? | `mmsg dispatch focusid client,<id>` (por id) |
| Mover, flutuar, fechar | na janela em foco | `dispatch tagsilent,<n> client,<id>`, `togglefloating client,<id>`, `killclient client,<id>` (a forma `client,<id>` vale pros dispatchers em geral; a confirmar pra cada um) |
| Modelo | `tags` | Confirma (`view 1\|3`, `view 00` = todas) |

- **`capabilities` propostas (hipótese):** `workspaceModel: tags`, `canFloat: true`,
  `canMoveToWorkspace: true`, `actsOnAnyWindow: true` (era `false` no contrato), `hasGeometry: rect` ou
  `columns` conforme o layout (o `scroller` é em colunas; a amostra diz se o JSON traz posição),
  `fullscreenKnown`: a conferir.
- **Config:** `~/.config/mango/config.conf` (ou TOML); `bind=ALT,Return,spawn,kitty`;
  `bind=ALT,q,killclient`; `bind=ALT,1,view,1`; `spawn_shell` pra linha com argumentos;
  `exec_once=`; recarga automática (0.18) e `reload_config`; `mango -c <arq> -p` valida sem subir.
  Layouts: `tile`, `scroller`, `monocle`, `grid`, `deck`… Visão geral: `toggleoverview`. Animações:
  `animation_type_open/close`, durações (abrir 400, fechar 300, tag 300, mover 500 ms).
- **Fontes:** https://raw.githubusercontent.com/mangowm/mango/main/mmsg/mmsg.1.in ;
  https://mangowm.github.io/docs/ipc ; https://mangowm.github.io/docs/bindings/keys ;
  https://github.com/mangowm/mango/releases/tag/0.15.0 ; https://github.com/mangowm/mango/pull/887 ;
  https://mangowm.github.io/docs/window-management/layouts ;
  https://mangowm.github.io/docs/visuals/animations

## R8. A UI da `main` fora do Hyprland (`import Quickshell.Hyprland`)

- **O que o código do Quickshell faz** (fonte: `src/wayland/hyprland/ipc/connection.cpp`, ramo
  `master` do espelho do Quickshell): sem `HYPRLAND_INSTANCE_SIGNATURE`, o construtor da conexão IPC
  registra **um aviso** (`qWarning`) — `$HYPRLAND_INSTANCE_SIGNATURE is unset. Cannot connect to
  hyprland.` — e retorna cedo, sem abrir os sockets. Não há erro nem queda. Depois, cada pedido
  (`dispatch`, `refreshMonitors/Workspaces/Toplevels`) falha com `Error making request:` (categoria
  `quickshell.hyprland.ipc`, aviso) e, no `dispatch`, `Failed to request dispatch of …`; o estado fica
  vazio.
- **O que se espera no `ui.log`** (hipótese, a confirmar na VM): o aviso de "unset" uma vez, quando o
  singleton `Hyprland` é tocado pela primeira vez pelo `Compositor.qml`, e um `Error making request`
  por chamada a `hyprctl`-via-Quickshell (o `Compositor.qml` da `main` faz `refresh*()` e lê
  `Hyprland.workspaces`). A UI deve carregar inteira, com as abas e o título vazios. O `Compositor.qml`
  também chama `hyprctl` por `Process` (`monitors -j`, `activewindow -j`): fora do Hyprland, o binário
  nem existe na `niri-base` e na `mango-base`, então o `Process` falha (código ≠ 0 ou "não achou"), e
  isso também é anotado.
- **Efeitos além das abas e do título** (lidos no `Compositor.qml` da `main`, hipótese a confirmar):
  - `monitorScales` vem só do `hyprctl monitors -j`; fora do Hyprland fica `{}`, e o `Tokens` usa escala
    1 pra alinhar as linhas finas. **No perfil hidpi (1,25), as linhas de 1 px podem sair borradas ou
    desalinhadas** no Niri e no Mango;
  - `liveFocusedMonitor` vem da mesma consulta; fica vazio, e as configurações (`ALT+I`) e o seletor
    (`ALT+W`) abrem "no monitor em foco": podem não abrir, ou abrir na primeira tela. É o primeiro item
    a conferir na US3;
  - `focus(id)` (clicar numa aba) vira `Hyprland.dispatch` sem conexão: só o aviso.
- **Consequência pro critério "log sem erro de QML":** fora do Hyprland, o log **não** fica limpo com a
  UI de hoje. Não é critério deste estudo (é o que ele mede), mas é a prova de que o adaptador precisa do
  `NullBackend` e de isolar o import (contrato §1, §7).
- **O `Loader` que não carrega o arquivo** (FR-022): os singletons do QML são criados no primeiro uso.
  Hipótese: um `HyprlandBackend.qml` que não é carregado não instancia a conexão e não avisa nada; o
  import em si só resolve o módulo (o plugin `Quickshell.Hyprland` é carregado, o que custa uma
  biblioteca na memória). O spike descartável (`lab/009/spikes/loader/`) prova: um `shell.qml` mínimo com
  um `Loader` escolhendo entre `A.qml` (com o import) e `B.qml` (sem), rodado no Niri, com o log e o
  `/proc/<pid>/maps` (se a biblioteca do plugin foi carregada).
- **Rota genérica (A7):** o Quickshell 0.3 tem `Quickshell.WindowManager` (áreas pelo ext-workspace) e o
  `ToplevelManager` (janelas pelo wlr-foreign-toplevel), e o Niri e o Mango implementam os dois
  protocolos. Um spike (`Q-quickshell-generico`) lista áreas e janelas por eles nos dois compositores (e
  no Hyprland, se ele tiver ext-workspace). Se funcionar, a S5 pode ter um backend genérico só pra
  leitura, e o IPC de cada um só pras ações e o que o protocolo não diz (colunas, tela cheia). Há também
  um plugin de terceiros pro Niri (`qml-niri`, MIT), só citado.
- **Decisão:** registrar as linhas exatas do log no Niri e no Mango (SC-007) e rodar os dois spikes nos
  dois.
- **Fontes da rota genérica:** https://quickshell.org/changelog ;
  https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland ; https://github.com/imiric/qml-niri
- **Fonte:** https://github.com/quickshell-mirror/quickshell/blob/master/src/wayland/hyprland/ipc/connection.cpp

## R9. Como as ferramentas do lab sabem o compositor da VM

| Opção | Como | Prós | Contras |
|---|---|---|---|
| **A. Marca no host** (`vms/<base>.compositor`, herdada pela cadeia do `.base`) | Gravada pelo `bootstrap` ao congelar a base | Sem SSH a mais por comando; a `hypr-base` antiga não muda (padrão `hyprland`); funciona com a VM desligada (`lab/ls`) | Uma camada criada à mão sem `bootstrap` precisa da marca (ou herda) |
| B. Perguntar na VM a cada comando (`pgrep niri`, variáveis) | `ssh_vm` antes de cada ação | Sempre certo, mesmo numa VM montada à mão | Um SSH a mais em todo comando (o `lab/click` e o `lab/burst` são chamados muitas vezes nos roteiros); não funciona antes da sessão subir |
| C. Arquivo dentro da VM (`~/.config/nier-lab/compositor`) | Lido por SSH | Viaja com o disco | Mesmo custo da B; mudar a `hypr-base` congelada pra ter o arquivo é proibido |

**Decisão: A**, com a variável `NIER_LAB_COMPOSITOR` pra forçar e o arquivo da C gravado só como
informação dentro da VM (útil no `lab/ssh`). O `GUEST_ENV` exporta as variáveis de todas as sessões, então
o `lab/ipc` não precisa saber o compositor.

## R10. Como medir o custo do mesmo jeito nos três

- **Boot até a UI:** o `lab/up` agora espera o SSH (lab-sonda), e o `perf.py` não sonda mais a porta;
  então o "boot" do relatório do `lab/perf` é o tempo até o SSH, que não inclui o compositor. **Decisão:**
  medir dentro da VM, pelo relógio dela: `systemd-analyze` dá o tempo do kernel e do userspace até o
  `multi-user`; o `nier-ui-run` grava a hora (`date +%s.%N`) em que o `qs` começa e o primeiro sinal de
  UI pronta (a primeira linha do `ui.log` que o Quickshell escreve ao carregar o `shell.qml`, ou um
  `qs ipc call hud dump` respondendo). "Boot até a UI" = (UI pronta) − (início do kernel, pelo
  `/proc/uptime` no mesmo instante). Tudo no relógio da VM, sem depender do SSH.
  - O `nier-ui-run` ganha só essa linha de carimbo (em inglês, no código); é o mesmo arquivo nos três.
- **Parado:** 120 s depois da UI pronta, sem janela, perfil 1080, `--headless`: o `lab/perf end` já coleta
  RAM e CPU da VM (`perf_guest_snapshot`: `free`, `/proc/stat`, o processo do Quickshell). Acrescentar o
  RSS e o CPU do processo do compositor (nome por compositor) no mesmo instante.
- **Repetição:** 3 rodadas por compositor, cada uma numa camada nova (`lab/new … --from <base>`, disco
  igual), uma VM por vez, com o host sem outro teste deste estudo; a mediana e a maior diferença.
- **Descartado:** medir no `--window` (a janela do host muda o custo) e medir com a VM do outro agente
  ligada sem anotar (o relatório do `lab/perf` registra o que mais estava ligado).

## R11. Animações e os atalhos nativos

- **Rajadas:** `lab/burst 40 0 full <acao> &` e, 0,5 s depois, o atalho da ação (`ALT+Enter` abrir,
  `ALT+Q` fechar, `ALT+2` trocar de área, o atalho nativo de mover). O `times.txt` dá a duração aparente
  (primeiro e último quadro com mudança, pelo `lab/diffshot` entre quadros vizinhos). O `grim` leva
  ≈25–40 ms por quadro, então a rajada mostra se a animação existe, quanto dura e se há quadros quebrados,
  não a suavidade (lab, "Limites").
- **Visão geral e colunas:** além das rajadas, um screenshot da visão geral aberta e uma sequência de
  screenshots de rolagem de colunas com 4 janelas.
- **Atalhos nativos:** os padrões de cada compositor (R5–R7) entram na config do lab trocando SUPER por
  ALT, e a colinha lista quais (spec, US5).

## R12. Duas saídas de vídeo na VM

- O `virtio-vga-gl` aceita `max_outputs=2`, e a QEMU ganhou em 2026 resolução por cabeça
  (`head=N`), mas com `egl-headless` não há janela no host pra segunda saída, e há relatos de a segunda
  saída aparecer "conectada mas inativa" até o convidado ligá-la. Não achamos relato de virgl + Wayland +
  `egl-headless` com duas saídas.
- **Decisão:** spike de até 30 min numa camada descartável: `max_outputs=2` no `lab/up` (por variável,
  sem mudar o padrão), ver se o compositor lista as duas saídas e se dá pra pôr escalas diferentes
  (`lab/ipc`). Se der, cenário `S3` das amostras; se não, as perguntas por monitor ficam como pesquisa
  (FR-028). O `grim` na VM captura todas as saídas, então o screenshot não depende da janela do host.
- **Fontes:** https://lists.freedesktop.org/archives/spice-devel/2024-August/053482.html ;
  https://www.mail-archive.com/qemu-commits@nongnu.org/msg12349.html ;
  https://lists.nongnu.org/archive/html/qemu-discuss/2016-12/msg00011.html ;
  https://grok.dragonflybsd.org/xref/qemu/docs/system/devices/virtio-gpu.rst?r=83561896

## R13. A cadeia `hypr-iso` e a promoção, sem derrubar ninguém

- **Fato (006, SC-005):** a `hypr-base.sh` rodou sem mudança sobre uma camada da `arch-iso` e o Hyprland
  subiu com o smoke. A diferença pra `arch-limpo` é: sem `rsync` na base (a cópia continua por `tar`),
  btrfs, zram, NetworkManager e o usuário `arch` com sudo sem senha pelo `90-nier-lab`.
- **Nome:** `hypr-iso` (sugestão do PRD). Não reaproveita `hypr-base`: as camadas `dev`, `teste-a/b/c`
  e as dos agentes apontam pro arquivo da `hypr-base` (backing file do qcow2); renomear ou refazer
  quebraria todas.
- **Promoção** = três mudanças pequenas: o padrão do `lab/new`, o passo `dev` do `lab/bootstrap` (que
  passa a nascer da `hypr-iso` num lab vazio; num lab que já tem `dev`, nada muda), o README e a Central.
  A `hypr-base` continua no `bootstrap` (pra quem tem camadas sobre ela) até o OK do dono.
- **Recriar as `teste-*`** (C1): pra cada uma, conferir na hora: não ligada (`lab/ls`, `run/<nome>.pid`
  com processo vivo), nenhum `qemu-system` citando o disco (`pgrep -af qemu-system`), nenhuma camada com
  ela como base. Livre → `lab/rm` + `lab/new --from hypr-iso`. Ocupada → pendente no resumão. Uma de cada
  vez, e a `hypr-base` fica.
- **Hash das bases:** `sha256sum` dos quatro discos congelados no começo e no fim (SC-002).

## R14. Tempo de VM

Base dos números: 006 (`install-iso` ~5,5–5,8 min com a ISO no disco; `hypr-base.sh` ~5–8 min com o
download de ~500–700 MB a ~3,5 MB/s); `lab/perf` 191921 (os três roteiros juntos: 562 s) e 194211
(`check-004` com o seletor: 767 s). A `check-004` cresceu pra 58 linhas no acabamento: ~15 min.

| Bloco | Estimativa | Nota |
|---|---|---|
| `arch-iso` (só se faltar) | 0,1–0,3 h | Já existe no lab do dono; se faltar, +8 min de download da ISO |
| `hypr-iso` + roteiros (com uma repetição) | 1,0 h | Preparação ~8 min, roteiros ~25 min por passada |
| `niri-base` + ferramentas + UI + amostras | 2,5 h | Inclui a iteração nas ferramentas |
| `mango-base` + o mesmo | 2,5 h | Pacote oficial (sem compilação); o IPC tem campos não documentados |
| Regressão do Hyprland | 0,5 h | Os três roteiros |
| Custo (9 rodadas × ~5 min) + rajadas (12 × ~5 min) | 2,0 h | Uma VM por vez |
| Spikes: 3D/`egl-headless`, uwsm, rota genérica, `hypr-plugins`, duas saídas | 1,5 h | O do 3D vem primeiro: se falhar, muda o lab |
| **Total** | **≈ 10 VM·h**, ≈ 6–7 h de relógio | Niri e Mango em paralelo (2 VMs) |

Mais a sessão manual do dono (~30–45 min, uma VM por vez, `--window`) e a etapa 2 do relatório (sem VM).

## R15. Pacotes do mesmo dia nas três camadas

- **Problema:** as preparações rodam `pacman -Syu` e instalam os pacotes do dia em que rodam. A
  `hypr-base` atual tem o Hyprland 0.56; a 0.57 saiu hoje com mudanças no Lua (A6). Se a `hypr-iso` for
  montada depois que o Arch publicar a 0.57, ela compara outra versão, o `guest/hyprland.lua` pode
  quebrar, e os roteiros da fase 0 falham por um motivo que não é a base. E as três camadas, montadas em
  dias diferentes, teriam Qt, Mesa e Quickshell diferentes, o que estraga a comparação de custo.
- **Opções:**

  | Opção | Como | Prós | Contras |
  |---|---|---|---|
  | **A. Data fixa do Arch Linux Archive** | As três preparações (e a regressão) usam o espelho do arquivo histórico num dia só (ex.: 2026/10/28) | Mesmo Hyprland (0.56.2), Qt, Mesa e Quickshell nas três; reproduzível; o `install-iso` já tem `--snapshot` com o mesmo mecanismo | Não é "o que o usuário teria hoje"; o arquivo histórico é mais lento |
  | B. Pacotes do dia | Como a 006 decidiu pra `arch-iso` | É o que o usuário teria | As três camadas podem divergir; a fase 0 fica sujeita à 0.57 |
  | C. Pacotes do dia, segurando o Hyprland | `IgnorePkg=hyprland` | Só o Hyprland fica parado | Atualização parcial (não suportada no Arch) |

- **Recomendação: A**, com a data anotada no relatório e no `lab/009/versoes/`. A troca pra 0.57 vira
  trabalho à parte (outra spec ou uma tarefa de manutenção do lab). **Pergunta 1 do plano.**
- **Fonte:** https://wiki.archlinux.org/title/Arch_Linux_Archive (mecanismo já usado pelo
  `lab/install-iso --snapshot`, spec 006)
