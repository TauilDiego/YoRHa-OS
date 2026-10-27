# Pesquisa (Fase 0): Base visual YoRHa e HUD

Cada item segue o formato: decisão, motivo e o que foi descartado. As APIs foram conferidas nos
`qmltypes` do Quickshell 0.3.1 (`/usr/lib/qt6/qml/Quickshell/…`), a mesma versão da VM.

## R1. Fonte dos dados do Hyprland

- **Decisão:** usar o singleton `Hyprland` de `Quickshell.Hyprland`. Ele expõe `workspaces`,
  `monitors`, `focusedMonitor`, `activeToplevel` e `dispatch()`; o `HyprlandWorkspace` tem `id`,
  `focused`, `active`, `monitor`, `toplevels` e `activate()`; o `HyprlandMonitor` tem
  `activeWorkspace`. Esse acesso fica atrás de um adaptador (`services/Compositor.qml`), e o
  resto da UI só conhece o adaptador.
- **Motivo:** é nativo, reage a eventos e já suporta a config em Lua (`usingLua`). O adaptador
  isola a troca pelo Niri (S5), como pede a constituição.
- **Descartado:** chamar `hyprctl -j` em loop (polling, mais caro e com atraso).

## R2. Áudio e bateria

- **Decisão:**
  - **volume:** `Pipewire.defaultAudioSink.audio` (`volume`, `muted`), com `PwObjectTracker` no
    sink pra manter os dados vivos;
  - **bateria:** `UPower.displayDevice` (`percentage`, `state`, `isLaptopBattery`, `isPresent`).
    A leitura some quando não houver bateria.
- **Motivo:** os dois são serviços nativos do Quickshell e reagem a mudanças (FR-013: "quando
  mudarem").
- **Descartado:** `wpctl`/`upower` via processo.

## R3. CPU e memória

- **Decisão:** `FileView` em `/proc/stat` e `/proc/meminfo`, com `reload()` num `Timer` de 2 s. A
  CPU é o delta de `/proc/stat` entre duas leituras. **A verificar no lab:** se o `FileView` lê
  arquivos de `/proc`, que têm tamanho 0. Se não ler, a alternativa é um `Process` com
  `cat /proc/stat /proc/meminfo` e `StdioCollector`.
- **Motivo:** não precisa de dependência nova e custa uma leitura a cada 2 s.
- **Descartado:** `top` ou `free` em processo (mais caros de interpretar).

## R4. Dados de teste (fixtures)

- **Decisão:**
  - um singleton `services/Fixtures.qml` lê um JSON cujo caminho vem da variável de ambiente
    `NIER_FIXTURES` (`Quickshell.env`);
  - **cada domínio é opcional:** domínio ausente no JSON = dado real. Assim dá pra fixar tudo
    para um screenshot e, ao mesmo tempo, testar o clique real nas abas (SC-003) só com hora e
    telemetria fixas;
  - `Fixtures` também aceita `load(path)` e `clear()` via IPC, pra trocar de cenário sem
    reiniciar (bateria baixa, mudo, sem bateria…).
  - Formato: `contracts/fixtures.schema.json`.
- **Motivo:** FR-015, SC-002 e o princípio IV (evidência determinística).
- **Descartado:**
  - um modo "teste" global: perde a chance de misturar dado real com dado fixo;
  - mocks dentro de cada componente: espalha a lógica.

## R5. Escala

- **Decisão:**
  - **tokens nas medidas do jogo a 1080p**, num singleton (`ds/Tokens.qml`);
  - **cada componente recebe `s`** (propriedade, padrão 1) e multiplica as medidas por ela. A
    superfície decide o `s`:
    - HUD: `s = tabH / 47`, com `tabH = round(barHeight × 0,485)` (33 px dos 68 padrão; no
      U1 era `barHeight × 31/40`);
    - tela cheia: `s = altura lógica / 1080`;
  - **`uiScale`** vem da configuração e multiplica tudo;
  - **linhas** usam `Tokens.line(v, s)` = `max(1, round(v·s))`, pra ficar nítidas (FR-002,
    SC-008);
  - **nada de DPI nas medidas:** a escala fracionária fica com o Hyprland e o Qt, como no
    Serpantinum;
  - **linhas finas na grade física** (revisto depois do hidpi): o Qt só informa a escala inteira
    do buffer, então o `Compositor` lê a escala fracionária de cada monitor (`hyprctl monitors -j`)
    e a publica em `Tokens.monitorScales`. As primitivas com linhas finas usam `Tokens.snap()` e
    `Tokens.hair()` com essa escala, pra cair em pixel físico inteiro a 1,25.
- **Motivo:** FR-008b. Com `s` vindo da superfície, o mesmo componente serve ao HUD e aos menus
  sem um segundo conjunto de tamanhos.
- **Descartado:**
  - um `s` global num singleton: o HUD e a galeria precisam de valores diferentes ao mesmo
    tempo;
  - `Item.scale`: borra o texto e as linhas.

## R6. Configuração do usuário

- **Decisão:** padrões em `shell/config/defaults.json` (gerenciado). O arquivo do usuário fica
  em `$XDG_CONFIG_HOME/rien-os/shell.json` e só sobrescreve as chaves que tiver. São lidos com
  `FileView` + `JSON.parse`, com validação campo a campo (o `JsonAdapter` foi trocado na
  implementação). Chaves: `uiScale`, `barHeight` (28–96; no U1 era 28–48), `vignette` (bool) e
  `wallpaperMotion` (bool, H4).
- **Motivo:** princípio III (padrões gerenciados separados dos arquivos do usuário).
- **Descartado:** constantes no código (o usuário não conseguiria mudar).

## R7. Fonte

- **Decisão:**
  - **padrão:** a M PLUS 1 (OFL, fonte variável) vai junto no repositório, em
    `shell/assets/fonts/`, com a licença `OFL.txt`, e é carregada por `FontLoader`. Assim não
    depende do que estiver instalado;
  - **originais:** se `Qt.fontFamilies()` tiver "FOT-Rodin ProN" ou "Helvetica Now Micro", o
    `Tokens` usa a original nos papéis dela.
- **Motivo:** FR-008a, e a OFL permite redistribuir. A constituição proíbe só as fontes do jogo.
- **Descartado:** depender do fontconfig do sistema. A lição do Serpantinum é que o nome pode
  falhar em silêncio.

## R8. Animações (FR-004, FR-005)

- **Decisão:**
  - **realce:** um retângulo de tinta cresce da esquerda pra direita
    (`NumberAnimation` na largura, `Easing.OutCubic`) em `Tokens.motion.highlight` = 150 ms;
  - **balanço do seletor:** `SequentialAnimation` em loop, ±5 px, período de 1 s,
    `Easing.InOutSine`. O seletor é um `Item` com a pipa (`Shape`) e os 2 quadradinhos, então
    tudo balança junto;
  - **screenshots iguais (SC-002):** com fixtures ativas, `Tokens.frozen` pausa as animações numa
    posição fixa.
  - **revisto em 2026-10-27:** o balanço saiu; a pipa fica parada, como no jogo, e pisca ao trocar
    de item (`motion.blink`, 240 ms; T054).
- **Motivo:** a spec pede o tempo como token e calibração depois. Sem o congelamento, o balanço
  quebraria a comparação pixel a pixel.

## R9. Galeria e IPC

- **Decisão:**
  - **galeria:** `PanelWindow` de tela cheia na camada `Overlay`, criada por `LazyLoader` (só
    existe quando aberta), com `keyboardFocus: Exclusive` pra receber o Esc;
  - **IPC:** `IpcHandler` (`Quickshell.Io`) com os alvos `gallery`, `fixtures` e `hud`
    (`contracts/ipc.md`);
  - **`hud.dump()`:** devolve em JSON o que a barra está mostrando. É o "comando que responde"
    (princípio IV), conferível sem olhar pixel.
- **Motivo:** FR-016 e verificação automática.

## R10. Laboratório (privado)

- **Perfil 2560x1600 @1,25 (SC-008):**
  - `lab/up` passa a aceitar `NIER_LAB_PROFILE=hidpi`: tela virtual de 2560x1600;
  - um comando novo, `lab/profile hidpi|1080`, aplica a escala via
    `hyprctl eval 'hl.monitor({… scale = 1.25})'`;
  - `guest/hyprland.lua` continua com 1,0 por padrão.
- **Fixtures na VM:** `guest/nier-ui-run` lê `~/nier/ui.env` (se existir) antes de rodar o `qs`.
  O `lab/sync` ganha `--env NIER_FIXTURES=…`.
- **Comparação pixel a pixel (SC-002):** `lab/diffshot a.png b.png` (ImageMagick
  `compare -metric AE`).
- **Agentes em paralelo (princípio VI):**
  - hoje o lab liga uma VM por vez;
  - passa a aceitar uma porta SSH e uma sessão `lab/perf` por VM, selecionadas por
    `NIER_LAB_VM`;
  - é pré-requisito da fase paralela das tarefas.
- **Lint:** o `qmllint` roda **dentro da VM** (`lab/ssh`), nunca no host.
- **Medição:** toda verificação fica dentro de `lab/perf begin/end`.
