# Sondagem da 013 (T006)

Feita em 31.10 em duas VMs, cada uma dentro do `lab/perf`, com `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`:
- **`teste-b`** (`hypr-base` + passos `notify` e `sound`, `lab/up --audio-capture`): S1, R2, R5, R6 e
  a disputa da placa (S4). Relatório
  `2026-10-31T215024-vm-teste-b-013-sondagem-na-teste-b-s1-som-r2-qsb-r5`.
- **`teste-011`** (`boot-iso`, `--soft --audio-capture`): S3 e o som de boot de verdade (S4).
  Relatório `2026-10-31T220953-vm-teste-011-013-sondagem-na-teste-011-s3-greeter-e-p`.

Os testes usaram uma config mínima do Quickshell (`~/nier/probe`, fora do repo) ao lado da UI, e uma
regra do udev com unidade e script de teste na `teste-011`, removidos no fim.

## Resumo

| Risco | Resultado | Muda o plano? |
|---|---|---|
| S1, latência do `SoundEffect` | Tecla → som em até ~30 ms na VM (alvo: 50). `play()` repetido toca sempre | Não. O `pw-play` fica só como plano B, sem uso previsto |
| S3, greeter e PipeWire | O usuário `sddm` alcança o PipeWire pelo socket. `SoundEffect` toca como `sddm` | Não |
| S4, `aplay` e o WirePlumber | O som de boot toca antes do greeter. Mas se o PipeWire pedir a placa durante o `aplay`, o nó da placa some até o WirePlumber reiniciar | **Sim, pouco:** o tema espera o fim do som de boot antes do primeiro som (abaixo) |
| R2, `.qsb` no Quickshell | Carrega e desenha | Não |
| R5, ordem das camadas Overlay | A superfície criada por último fica em cima | Não: o plano B da research funciona |
| R6, `kb_layout` com Lua | `hyprctl eval` aplica na hora; `hyprctl keyword` não funciona | Não, com o caminho definido |

## S1. O `SoundEffect` no shell

**Montagem:** o `move.wav` num `SoundEffect`, tocado de três jeitos:
- 20 vezes pelo IPC, com a hora do `play()` (relógio da VM);
- 20 teclas reais pelo `lab/key`, com a hora de envio no host e a do `Keys.onPressed` na VM;
- duas rajadas no mesmo `SoundEffect`: 6 toques a cada 30 ms e 6 a cada 200 ms.

A gravação é o monitor do sink nulo (`lab/013/audio-rec`), alinhada por 4 marcadores de 1 kHz tocados
com `pw-play`.

**Medidas:**

| Trecho | Mín. | Mediana | p95 | Máx. |
|---|---|---|---|---|
| `play()` → som, contra o marcador | −35,6 | −25,4 | −16,1 | −15,6 ms |
| tecla (no QML) → som, contra o marcador | −41,1 | −31,2 | −22,5 | −20,6 ms |
| tecla enviada pelo host → `Keys.onPressed` | 2,7 | 3,7 | 4,7 | 4,7 ms |

- **Leitura:** o número negativo quer dizer que o som do `SoundEffect` sai antes do som de um `pw-play`
  disparado no mesmo instante. O `pw-play` do marcador leva no máximo 28–44 ms: é o tempo inteiro dele,
  menos o pulso de 50 ms.
- **Resultado:** o `play()` → som fica em até ~20 ms, no pior caso 29 ms. Com os ~4 ms da tecla, dá
  ≤ ~30 ms, abaixo dos 50 ms do SC-008.
- **Quantum:** o PipeWire da VM roda com quantum mínimo de 1024 (21 ms; o WirePlumber faz isso em VM).
  No hardware real, o quantum menor só baixa esses números.
- **Rajadas:**
  - a 30 ms, cada `play()` gerou um ataque (6 de 6), mas os ataques saem presos à grade do quantum, em
    pares a 17–22 ms;
  - a 200 ms, 6 de 6 no ritmo certo.

  O conjunto de 3 instâncias e o debounce de 40 ms do plano continuam valendo.
- **Pacotes:** o backend é o FFmpeg (`qt.multimedia.ffmpeg: Using Qt multimedia with FFmpeg version
  n9.0.2`). O `status` vai a `Ready` (2) logo depois de carregar.

## S3. O greeter e o PipeWire

Na `teste-011` com o passo `sound` (a camada `boot-iso` não tinha `wireplumber`, `pipewire-pulse`,
`qt6-multimedia` nem `alsa-utils`):
- **Sockets:** `pipewire.socket`, `pipewire-pulse.socket` e `wireplumber.service` ficam habilitados
  pra todos os usuários pelos pacotes. O `user@966` (o `sddm`) sobe no boot e escuta os sockets.
- **Ativação:** nada roda até o primeiro cliente. Um `pactl info` como `sddm` (com o `XDG_RUNTIME_DIR`
  da sessão `greeter`) subiu o `pipewire`, o `wireplumber` e o `pipewire-pulse`, com o sink da placa.
- **Som:**
  - `pw-play` como `sddm` tocou na placa;
  - um `SoundEffect` como `sddm` (o `qml` do Qt, offscreen) também tocou;
  - os dois estão no WAV gravado pelo QEMU.

**Não verificado:** dentro do próprio `sddm-greeter-qt6` (X11), que é a T048 da frente D. O usuário e a
sessão são os mesmos, então a expectativa é a mesma.

## S4. O som de boot

**No boot** (`teste-011`, regra `SOUND_INITIALIZED=1` + unidade `Type=simple` +
`aplay -D plughw:0 boot-start-30.wav`):
- **Placa:** fica pronta em 3,03 s, e a unidade sobe no mesmo instante.
- **Som:** o `aplay` toca de 3,04 a 4,27 s, com `rc=0`, e o som está no WAV do QEMU (o mixer da HDA
  emulada não começa mudo).
- **Greeter:** o `user@` do `sddm` sobe em 4,28 s, sem PipeWire até o primeiro som.

**A disputa pela placa** (`teste-b`, com o WirePlumber da sessão):
1. **Placa ociosa** (sink suspenso): o `aplay -D plughw:0` toca.
2. **O PipeWire tocando:** o `aplay` sai com `Device or resource busy`. É o caso previsto no contrato:
   o script desiste calado.
3. **O `aplay` segurando a placa, e o PipeWire pede ela:**
   - o nó vai pra `error (Start error: Device or resource busy)`;
   - o WirePlumber registra `Failed to create ALSA node … Object activation aborted`;
   - o sink da placa **some e não volta sozinho**. Nem um `udevadm trigger --action=change` traz ele de
     volta, só reiniciar o WirePlumber.

   A research supunha que o WirePlumber tentaria de novo.

**Consequência:** o som de boot não pode estar tocando quando o PipeWire do greeter abre a placa. Como
esse PipeWire só sobe no primeiro som do tema, a regra fica assim:
- o script grava `/run/yorha-os/sound.state` **depois** do `aplay` (ou logo, quando não toca);
- o tema só cria os seus `SoundEffect` quando esse arquivo existe, esperando no máximo 2 s.

O login nunca espera nada disso. O pior caso é a intro do login tocar sem som, se o arquivo não chegar
a tempo. A sessão do usuário tem um WirePlumber próprio, que sobe no login, bem depois do som de boot.

**Não verificado:** o mixer de uma placa de verdade num sistema recém-instalado (o "primeiro boot
mudo"). A VM não reproduz isso.

## R2. Um `.qsb` no Quickshell

- **Compilação:** um shader de teste compilado pelo `lab/013/qsb` (`qsb --qt6`, 1,6 kB).
- **Uso:** num `ShaderEffect` com `ShaderEffectSource` (`hideSource`) sobre um retângulo, desenhou as
  listras sobre o "QSB".
- **Log:** sem erro de shader. Os únicos avisos são os do `qt.qpa.wayland.textinput`, o bug conhecido do
  Qt 6.12 que o `nier-ui-run` silencia.

## R5. A ordem das superfícies Overlay

Duas `PanelWindow` na camada Overlay:
- **Menu antes do toast:** com o "toast" criado antes do "menu", o menu cobre o toast.
  `hyprctl layers` lista `["yorha-probe-toast","yorha-probe-menu"]`.
- **Toast recriado:** escondido e mostrado de novo, o toast volta pra cima (`["yorha-probe-menu",
  "yorha-probe-toast"]`).

A regra é que a superfície criada por último fica em cima. Assim:
- um toast que chega com o menu cheio aberto já nasce por cima;
- um que já estava na tela fica coberto até a superfície ser recriada.

O plano B da R5 (o `NotifyLayer` recria a sua superfície quando o menu abre) funciona.

## R6. Keyboard › Layouts no Hyprland 0.56 com Lua

- **Keyword:** `hyprctl keyword input:kb_layout us,br` é recusado: `keyword can't work with non-legacy
  parsers. Use eval.`
- **Eval:** `hyprctl eval 'hl.config({ input = { kb_layout = "us,br" } })'` aplica na hora, em todos os
  teclados. O `hyprctl devices` mostra `layout: "us,br"`, e o `hyprctl getoption input:kb_layout` dá
  `str: us,br`.
- **Troca:** `hyprctl switchxkblayout all next` troca (`active_keymap: Portuguese (Brazil)`). Na
  configuração, o atalho pode ser um `hl.dsp.exec_cmd("hyprctl switchxkblayout all next")`.
- **Recarregar:** o `hyprctl reload` volta ao que está no arquivo. Por isso a opção aplica por `eval` e
  também precisa estar na configuração gerenciada.

## S6. As ferramentas de gravação

- **Placa emulada (`lab/up --audio-capture`):**
  - funciona com a placa num endereço fixo (`00:1b.0`);
  - sem endereço fixo, ela empurra o disco virtio pro slot seguinte. A entrada de boot do UEFI aponta
    pro slot antigo, a VM cai no PXE e a entrada some das variáveis UEFI. Na `teste-b`, as variáveis
    foram restauradas do `hypr-base`.
- **Cabeçalho do WAV:** o QEMU deixa os tamanhos zerados quando a VM desliga por dentro, e o `lab/down`
  agora reescreve eles.
- **O que fica no WAV:** só o tempo com fluxo aberto.
- **Gravação na sessão (`lab/013/audio-rec`):**
  - grava o monitor do sink nulo com marcadores;
  - mede o desvio entre os relógios por uma conexão SSH aberta: −4,7 ms, com 2 ms de ida e volta. Uma
    conexão por medida dava 150 ms de ida e volta e um desvio errado;
  - o `lab/key` grava a hora de cada tecla com `NIER_LAB_KEYLOG`.

## Na junção (01.11): o backend de som trocou pra GStreamer

**O que aconteceu:**
- **Na regressão da 007:** o log do shell numa VM chegou a 1,27 GB, ~15 milhões de linhas de
  `QSocketNotifier: Invalid socket 88 and type 'Read', disabling...`. O disco da VM encheu, e o
  `/run/user` também, com o log detalhado do Quickshell. O shell caiu.
- **No laço:** o `qs` fica em ~160% de CPU. A primeira linha é sempre `QSocketNotifier: Socket
  notifiers cannot be enabled or disabled from another thread`.

**Medido na `t013-j3`:**

| Teste | FFmpeg (o padrão) | GStreamer |
|---|---|---|
| Abrir app pelo menu (Enter numa ação), sons ligados | o laço na 8ª abertura | nenhum em 20 voltas (6 aberturas registradas) |
| O mesmo com os sons desligados | nenhum em 30 voltas | — |
| 60 voltas de `sounds play` + um processo comum (`ls` do `Sounds`) ao mesmo tempo | 13,6 milhões de linhas | 0 linhas, nenhum aviso |
| `play()` → som contra o marcador (20 toques) | mediana −25, máx. −15,6 ms (T006) | mediana −32, máx. −23 ms (teto do marcador 39 ms) |

**Conclusão:** é uma corrida da thread de áudio do backend FFmpeg do Qt 6.12 com qualquer processo que
o shell abre enquanto um som toca. Não é do nosso código.

> **Correção (06.11.2026, fix-laco-log):** a conclusão acima está errada na causa, e "nenhum em 20 voltas" com o
> GStreamer era amostra pequena. O laço é uma corrida do Qt Multimedia 6.12.0 quando a voz de um `SoundEffect`
> termina sozinha, e acontece com FFmpeg, GStreamer e Pulse, com ou sem processo aberto. Por isso também não
> vale, abaixo, "o laço não o pega" no greeter. Quem segura o laço no shell é o guarda do log em `bin/yorha`.

**A troca:**
- **No shell:** `//@ pragma Env QT_MEDIA_BACKEND=gstreamer` no `shell.qml`.
- **No greeter:** fica no FFmpeg, explícito no `GreeterEnvironment` (`QT_MEDIA_BACKEND=ffmpeg`). Com o
  GStreamer no greeter, o `boot-timing` deu +0,13 s, acima do limite de 0,1. Com o FFmpeg, +0,03 s. O
  greeter não abre processos com um som tocando, então o laço não o pega.
- **Dependências:** passam a ser os dois backends:
  - `qt6-multimedia-gstreamer` (o shell), que já puxa `gst-plugins-good`, `gst-libav` e `libpulse`.
    Sem o `gst-plugin-pipewire` também toca, pelo `pipewire-pulse`;
  - `qt6-multimedia-ffmpeg` (o greeter).
