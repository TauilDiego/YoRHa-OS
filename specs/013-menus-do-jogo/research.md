# Research: Menus do jogo (013)

As decisões técnicas do plano, no formato Decisão / Por quê / Alternativas. R1–R8 tratam do visual;
S1–S6, do som, que vêm da pesquisa da frente de som.

## R1. Os números ficam no `Tokens.motion`

**Decisão:** um bloco de constantes com os números do jogo, aprovados no protótipo. Todas as peças leem
dali, e com `Tokens.instant` (Reduce motion) tudo vira 0.

| Constante | Valor | Origem |
|---|---|---|
| `selectIn` / `selectOut` | 400 ms OutQuart / 200 ms InOutQuad | A-10, protótipo |
| `pulse` | 1333 ms; subida 350, topo 83, descida 317, repouso; +32% de luz | A-12 |
| `titleOut`, `titleGap`, `titleCps` | 100 ms, 200 ms, 20 letras/s | A-30, B-07 |
| `cascadeStep`, `labelCps` | 33 ms, 28 letras/s | A-18, A-32, B-08, B-15 |
| `tabOut`, `tabGap` | 133 ms, 67 ms | A-42 |
| `footFade`, `footSlide`, `footDx` | 130 ms, 300 ms, 20 px | A-33 |
| `levelStep`, `levelIn`, `levelDx`, `leave` | 34 ms, 170 ms, 10 px, 120 ms (×2,1) | B-12, B-14, B-24 |
| `openGrid`, `openTris`, `closeTris` | 100, 300, 230 ms; triângulos 240×120; 30% com quadro escuro | A-40, A-41 |
| `dialogDim`, `dialogTo` | 170 ms, ×0,8 | A-20, A-46 |
| `marqueeSpeed`, `marqueeHold` | 60 px/s, 1,0 s em cada ponta | regra do dono, protótipo |

**Por quê:** é um lugar só pra ajustar depois que o dono vir na VM ("os números podem ser ajustados").

## R2. Os triângulos são um `ShaderEffect`

**Decisão:** `popup/TriangleReveal.qml` aplica um shader de fragmento sobre a camada do painel
(`layer.enabled` só durante a animação). O shader faz três coisas:
- calcula, por pixel, a célula da grade (triângulos isósceles de 240×120 alternando pra cima e pra
  baixo, em px do jogo × `s`);
- sorteia o instante de cada célula com um hash do índice e uma semente por abertura;
- devolve três estados: transparente, o quadro escuro (30% das células) ou o painel.

Na fase da grade, o mesmo shader desenha as linhas claras com a franja vermelha e ciano. O GLSL é
compilado com `qsb` (`qt6-shadertools`) num container do lab, e o `.qsb` vai versionado, como as imagens
do boot da 011.

**Por quê:**
- **Uma passada na GPU, sem DOM:** no protótipo, recortar o painel a cada quadro custava caro, e a
  versão em canvas resolveu. Aqui o equivalente é o shader.
- **Modo janela:** o shader recorta só o retângulo do painel, então funciona igual.

**Sondagem (T006):** um `.qsb` do `lab/013/qsb` carregou num `ShaderEffect` no Quickshell da VM, sem
erro ([sondagem.md](sondagem.md)).

**Alternativas:**
- 150 `Shape` com opacidade: mais objetos e mais trabalho na CPU.
- `Canvas` do QML: desenho por software, lento em tela cheia.

## R3. O texto que clareia na seleção já existe

**Decisão:** manter as duas cópias da `ListItem` (a `Face` escura e a clara, recortada pela faixa de
tinta). Muda só a animação (R1), e entra o recolher da linha que perde a seleção. Hoje ela zera na hora
(`sweep = 0`); passa a animar a largura de volta em `selectOut`.

**Por quê:** é o que o jogo faz, e o código já desenha assim desde a 001.

## R4. A escala na tela cheia

**Decisão:** `s` continua o do painel de 84% (`min(panelH/908, panelW/1612) × uiScale`) nos dois modos.
Na tela cheia, só a geometria do painel muda (a janela inteira), e o espaço extra vai pro layout:
- colunas `stretch`;
- SYSTEM centralizado;
- limite de largura em ultrawide.

**Por quê:**
- **Tamanho igual nos dois modos:** a spec pede as letras do mesmo tamanho (US4.2), e a frente D mostrou
  que `s = H/1080` deixaria tudo 19% maior.
- **Janela intacta:** essa fórmula não mexe no modo janela (FR-017).

**Alternativa:** `s = H/1080` em tudo. Mais fiel ao jogo em 1080, mas muda o modo janela no notebook.

## R5. As notificações por cima do menu cheio

**Decisão:** testar a ordem entre as superfícies Overlay (o menu e o `NotifyLayer`). Se o Hyprland não
garantir que o toast fica por cima, o `NotifyLayer` recria a sua superfície depois que o menu abre (a
última surface criada fica em cima) e o teste do `check-013` cobre isso.

**Por quê:** a frente D apontou o risco. Não há como declarar a ordem entre duas superfícies da mesma
camada.

**Sondagem (T006):** a superfície Overlay criada por último fica em cima. Um toast que já estava na tela
fica coberto pelo menu, e recriar a superfície dele traz ele pra frente. O plano B vale.

## R6. Keyboard › Layouts no Hyprland 0.56 (configuração em Lua)

**Decisão:** a lista vira `input.kb_layout` (separado por vírgula), aplicada sem reiniciar por
`hyprctl eval 'hl.config({ input = { kb_layout = "us,br" } })'` e gravada também na configuração
gerenciada (o `hyprctl reload` volta ao arquivo). A troca é por um atalho de "próximo layout"
(`hyprctl switchxkblayout all next`).

**Sondagem (T006):** o `hyprctl keyword` não funciona com a configuração em Lua ("Use eval"); o `eval`
aplica na hora em todos os teclados.

**Por quê:** é a primeira configuração "lista" que faz sentido no desktop, e o dono pediu um exemplo
real.

**Implementação (frente C, 31.10):**
- `Compositor.applyKeyboardLayouts()` aplica `Settings.kbLayouts` no começo, quando muda e quando o backend vê `configreloaded`; o `HyprlandBackend` roda `hyprctl eval` (config em Lua) ou `hyprctl keyword` (hyprlang). Só nomes XKB (`^[a-z]{2,8}$`) entram no comando. Os outros compositores (Niri, Mango, `none`) não têm `keyboardLayouts` nas capacidades: a opção guarda e o quadro diz que não aplica.
- Medido: depois de um `hyprctl reload` o layout volta pro do arquivo e o shell o reaplica em ~150 ms.
- **Fica pro instalador (fora daqui):** o layout padrão e o atalho de troca (`hl.dsp.exec_cmd("hyprctl switchxkblayout all next")`) na configuração gerenciada do Hyprland.
- Os layouts da opção são nomes sem variante (`us`, `br`, `pt`, `es`, `de`, `fr`): o "US International" da opção antiga precisaria de `kb_variant` por layout (aberto, do dono).

## R7. A medição de quadros/s na VM (SC-002)

**Decisão:** um contador de debug no shell (`FrameAnimation`, com o tempo de cada quadro da janela do
menu), ligado só pelo IPC (`pause fps start|stop`). O `stop` devolve a média, o percentil 95 e o pior
quadro, igual ao botão "medir" do protótipo. O `check-013` roda o mesmo roteiro fixo.

**Por quê:** a rajada do `lab/burst` mostra os tempos dos efeitos, mas não conta quadros perdidos. O
contador mede o que a tela mostrou.

## R8. A aba LOG

**Decisão:** a `LogPage` entra no `PauseMenu` com o host `"pause"`, que ela já prevê (`LogPage.qml:30`).
O `LogPopup` sai; o IPC `notify open|toggle` vira um atalho pra `pause open log`. A regra de marcar como
lido ao fechar passa pro fechamento do menu.

**Por quê:** a página foi feita pra isso (frente D, "o mais pronto"), e um lugar só pro histórico é mais
simples.

## S1–S6. Som (detalhes, evidências e riscos em [research-som.md](research-som.md))

- **S1, tocar no shell.**
  - **Decisão:** `SoundEffect` do QtMultimedia, com os arquivos carregados na abertura:
    - um conjunto de 3 instâncias pros sons repetidos (tique e digitação);
    - debounce de 40 ms;
    - no máximo 4 sons ao mesmo tempo.
  - Passa pelo PipeWire, então o volume e o mudo do sistema valem sozinhos.
  - **Pacotes:** `qt6-multimedia`, `qt6-multimedia-ffmpeg`.
  - **Alternativa (fallback):** `Process` com `pw-play` (`pipewire-audio`).
  - O `Quickshell.Services.Pipewire` só lê e controla os nós (serve pra ler o volume), não toca som.
  - **Sondagem (T006):** tecla → som em até ~30 ms na VM (quantum de 21 ms), e `play()` repetido toca
    sempre. O `pw-play` fica sem uso previsto.
- **S2, os nossos arquivos.**
  - **Formato:** WAV PCM 16 bits, 48 kHz, mono.
  - **Geração:** pelo `synth_demo.py` da frente C, no container `nier-lab-py`, com semente fixa (sai
    sempre igual).
  - **Boot:** o som de boot tem versões pré-calculadas por volume, então nada de `sox` em tempo de
    execução.
- **S3, a tela de login.**
  - **Decisão:** `SoundEffect` no tema, pelo PipeWire do usuário `sddm`. O PAM do greeter tem
    `pam_systemd`, e o Arch habilita os sockets do PipeWire pra todos os usuários.
  - **Sondagem (T006):** o usuário `sddm` alcança o PipeWire, que sobe pelo socket no primeiro cliente, e
    um `SoundEffect` toca como `sddm`. Falta conferir dentro do próprio greeter (T048).
  - **Plano B:** o serviço de boot (root) toca os sons de login pela placa. Plano C: login sem som,
    com o boot e a sessão mantidos.
- **S4, o som de boot.**
  - **Gatilho:** uma regra udev no evento da placa (`SOUND_INITIALIZED=1`) dispara um serviço
    `Type=simple`, sem nada ordenado depois dele, então nunca segura o login.
  - **Saída:** toca com `aplay -D plughw:N`. O `default` iria pro PipeWire, pelo `pipewire-alsa`.
  - **Volume e mudo:** vêm do `sound.json` do último usuário (`[Last] User=` em
    `/var/lib/sddm/state.conf`). Sem informação, 30%; mudo, nada.
  - **Greeter:** uma cópia vai pra `/run/yorha-os/sound.state`.
  - **Riscos:**
    - `EBUSY` se o WirePlumber pegar a placa antes: o script desiste calado;
    - o mixer da placa mudo num sistema recém-instalado.
  - **Sondagem (T006):** no boot da `teste-011`, o som toca de 3,04 a 4,27 s, antes do greeter. Mas se o
    PipeWire pede a placa enquanto o `aplay` toca, o nó da placa some e só volta reiniciando o
    WirePlumber. Por isso o `sound.state` é gravado **depois** do `aplay`, e o tema só cria os sons
    quando ele existe (até 2 s de espera). O PipeWire do greeter só sobe no primeiro som.
- **S5, o som de entrada.** Uma vez por login: um `mkdir` atômico de uma trava em `$XDG_RUNTIME_DIR`.
  Recarregar o shell não repete o som.
- **S6, gravar o áudio da VM.** (Sondagem: a placa vai num endereço fixo, `00:1b.0`, senão o disco muda
  de slot e o UEFI não acha o boot; o `lab/down` corrige o cabeçalho do WAV.)
  - **Placa emulada:** `-audiodev wav,id=snd0,path=<arquivo>` + `-device ich9-intel-hda -device
    hda-output,audiodev=snd0` (QEMU 11.1.3 aceita; o `hda-duplex` falha com o backend `wav`). Entra
    no `lab/up` como `--audio-capture`.
  - **Na sessão:** `pw-record` do monitor do sink nulo.
  - **Alinhamento:** o WAV segue o relógio da VM, então um pulso marcador no começo alinha com os
    tempos do `lab/key`.
