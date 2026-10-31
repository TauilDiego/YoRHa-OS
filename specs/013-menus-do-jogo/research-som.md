# Research (som): Menus do jogo (013)

Data: 2026-10-31. Pacotes: Arch `extra` em container `archlinux:latest` (qt6-multimedia 6.12.0-1, quickshell 0.3.2-1, sddm 0.21.0-7, pipewire 1:1.6.10-1, wireplumber 0.5.18-1, alsa-utils 1.2.16-1, qemu-desktop 11.1.3-1). "Não verificado" = precisa de áudio real; o container não tem placa e eu não rodo VM.

## S1. Tocar WAV no Quickshell

**Decision.** `SoundEffect` (QtMultimedia, `import QtMultimedia`) como caminho principal. Um componente `UiSound` com um *pool* de 3 `SoundEffect` por som (rodízio) para tick e typing, 1 para os demais; debounce de 40 ms por som e teto de 4 sons simultâneos (como em `C/sons.md` §6). Fallback: `Process { command: ["pw-play", "--volume", v, file] }` (ou `paplay`), com o mesmo debounce, ligado por `NIER_SOUND_BACKEND=process`/opção interna.

**Rationale.**
- Docs Qt 6: `SoundEffect` toca "uncompressed audio files (typically WAV)", mono ou estéreo, 48000 Hz recomendado, pensado para feedback de baixa latência; o arquivo é carregado/parseado uma vez e o `play()` só dispara (https://doc.qt.io/qt-6/qml-qtmultimedia-soundeffect.html). Propriedades no `plugins.qmltypes` do pacote: `source, loops, volume, muted, playing, status, audioDevice`. Não há `category`/`media.role` em Qt 6 (ao contrário do Qt 5).
- Saída: `qt6-multimedia` depende de `libpulse` e `pipewire` e de um `qt6-multimedia-backend`. O backend Arch é `qt6-multimedia-ffmpeg` (provides `qt6-multimedia-backend`, plugin `/usr/lib/qt6/plugins/multimedia/libffmpegmediaplugin.so`) ou `-gstreamer`. Escolher **ffmpeg** (padrão upstream, o `ffmpeg` já vem no desktop). O áudio sai pelo servidor Pulse, ou seja `pipewire-pulse`, então o volume e o mudo do sistema valem sem código (FR-023). O `AudioOutput`/`MediaPlayer` seguem o mesmo caminho.
- `Quickshell.Services.Pipewire` (`/usr/lib/qt6/qml/Quickshell/Services/Pipewire/`) **só controla e observa** nós (`PwNode.audio.volume/muted`, `defaultAudioSink`, `PwLinkGroup`, `PwObjectTracker`); não tem tipo que toque áudio. Serve para ler o volume/mudo do sistema (R4), não para tocar.
- `Process` + `pw-play`: `pw-play`/`pw-cat`/`pw-record` ficam em `pipewire-audio`; `paplay` em `libpulse`. Custo: um fork+conexão ao PipeWire por clique (ordem de 10–40 ms; **não verificado**), por isso só fallback.
- `MediaPlayer`: mais formatos (OGG), mas sobe um pipeline por toque; ruim para tick. Fica para sons longos fora do alvo de 50 ms (não precisamos).

**Alternatives considered.** `MediaPlayer`+`AudioOutput` (latência/custo, ver acima); `pw-play` como padrão (processo por tick, rajada a 5/s empilha processos); biblioteca C++ própria no Quickshell (fora de escopo, Quickshell só carrega QML); `canberra-gtk-play`/libcanberra (outra dependência, sem pool).

**Evidence.**
```
$ pacman -Si qt6-multimedia   -> 6.12.0-1, Depends: libpulse pipewire qt6-base qt6-multimedia-backend
$ pacman -Si qt6-multimedia-ffmpeg -> 6.12.0-1, Provides: qt6-multimedia-backend, Depends: ffmpeg ...
$ pacman -Ql qt6-multimedia | grep qmldir -> /usr/lib/qt6/qml/QtMultimedia/qmldir  (módulo "QtMultimedia", plugin quickmultimediaplugin)
$ plugins.qmltypes: QSoundEffect { source loops loopsRemaining volume muted playing status audioDevice }
$ pacman -Fl pipewire-audio libpulse -> usr/bin/pw-play pw-cat pw-record ; usr/bin/paplay pactl
```
Pacotes para o lab/instalador: `qt6-multimedia qt6-multimedia-ffmpeg pipewire pipewire-pulse wireplumber` (os dois últimos já devem estar na imagem; `lab/provision` não cita áudio, **conferir** em `lab/provision/hypr-base.sh`, não achei menção a pipewire em `lab/`).

**Risks.**
- Latência real de `SoundEffect` sobre pipewire-pulse (buffer do `QAudioSink`, ~20–60 ms) **não verificada**; medir (R6) e, se > 50 ms, trocar o backend por `Process` ou manter um stream aberto. Comportamento de `play()` com o som já tocando (reinicia ou sobrepõe) **não documentado**: o pool de 3 com `stop()+play()` evita depender disso.
- Se `pipewire-pulse` estiver parado, `SoundEffect` fica mudo/`Error`: mostrar o `status` no log e cair no fallback.
- WAV só (OGG não garantido em `SoundEffect`): a pasta do usuário (FR-021) vale para `.wav`; documentar. Arquivo inválido: `status === SoundEffect.Error` → cair no som nosso.

## S2. Nossos arquivos de som

**Decision.** WAV PCM 16-bit, **mono, 48000 Hz** (igual ao PipeWire padrão, sem reamostrar; é o formato que `C/sons.md` §5 já pede), pico entre -12 e -6 dBFS (tick -12, chime -10, typing -16), sem cabeçalho extra. Durações: tick 40 ms (o arquivo de 200 ms do demo tem silêncio: cortar o final em 120 ms só se o eco de 80 ms entrar), select 150–450 ms, open/close 250 ms, dialog_ok ~320 ms, typing 12 ms, notificação 450/800 ms. Nome do arquivo = nome do evento (`tick.wav`, `select.wav`, `back.wav`, `open.wav`, `close.wav`, `tab.wav`, `dialog_ok.wav`, `notify.wav`, `notify_critical.wav`, `typing.wav`, `boot.wav`, `login_*.wav`, `session_start.wav`), em `shell/assets/sounds/`. Geração reproduzível: `shell/assets/sounds/gen/synth.py` (derivado de `C/exemplo/synth_demo.py`, numpy+wave, `rng = default_rng(7)` fixa a semente) rodando no container `nier-lab-py`:
```
docker run --rm --label nier-lab -u "$(id -u):$(id -g)" -v <repo>/shell/assets/sounds:/w nier-lab-py \
  python3 -I /w/gen/synth.py /w
```
Variantes do boot: o mesmo `boot.wav` renderizado em níveis fixos (ver R4) pelo mesmo script (`--gain-db`), gerando `boot-10.wav … boot-100.wav`; sem `sox` em runtime. Um teste (`sha256sum` dos WAVs) detecta mudança da receita.

**Rationale.** 48 kHz mono = sem conversão; WAV é o único formato garantido do `SoundEffect`; mono é espelhado pelo PipeWire nos dois canais. 16-bit é suficiente (os brilhos de 11–14 kHz saem de 48 kHz sem aliasing: Nyquist 24 kHz). Os arquivos pequenos (tick 40 ms ≈ 3,8 kB) ficam na memória.
**Alternatives.** `sox` (receita do `sons.md` §5.1, "não testado"; mais uma dependência e mixagem de camadas pior que numpy); OGG/Opus (menor, mas `SoundEffect` não garante; ganho zero para 20 arquivos); 44,1 kHz (reamostra).
**Evidence.** `C/exemplo/synth_demo.py` já gera `tick, typing, select_chime, dialog_ok, open_whoosh` em "48 kHz mono 16-bit" com numpy+wave (cabeçalho do arquivo). `sons.md` §5.6 diz que rodou no `nier-lab-py`.
**Licença.** São do projeto, gerados por receita original (números só de caráter, `sons.md` §5): entram sob a licença do repositório; não usar os cortes do jogo como fonte (nenhum arquivo do jogo entra, FR-020). Anotar isso no `README` da pasta.
**Risks.** As receitas **nunca foram ouvidas** (`sons.md` §0 e §5.6): o dono ajusta de ouvido; 11–14 kHz mal toca em alto-falante de notebook e cansa alguns ouvidos: gerar também a variante "suave" (frequências/2) e deixar o parâmetro no script. Faltam receitas para `back` (tick 1,5 kHz sem eco), `close` (whoosh invertido), `notify_critical`, `session_start`, `login_*`: escrever e marcar como "inventado" como já faz o `sons.md`.

## S3. Sons no greeter do SDDM

**Decision.** Tocar com `SoundEffect` dentro do tema QML (`import QtMultimedia`), WAV 48 kHz mono em `/usr/share/yorha-os/login/assets/sounds/`, via servidor PipeWire do usuário `sddm`. Com um *self-check*: se o `SoundEffect` der `Error` ou não houver servidor, o tema segue em silêncio (sem erro visível, sem travar a animação). O módulo de boot/login instala `qt6-multimedia`+`qt6-multimedia-ffmpeg` como dependência e deixa o login **sem som** se faltarem. Fallback medido por tentativa: se o teste no lab mostrar que o greeter não alcança o PipeWire, **tocar os sons do login com o próprio serviço root de R4** (o greeter pede via arquivo/socket; ex.: `sddm` escreve um nome em `/run/yorha-os/ui-sound` e uma unidade `.path` toca com `aplay -D plughw`), ou aceitar "sem som no login" e registrar o motivo na spec.

**Rationale.**
- O greeter roda como o usuário `sddm` (`/usr/lib/sysusers.d/sddm.conf`: `u sddm - "SDDM Greeter Account" /var/lib/sddm`) e `/etc/pam.d/sddm-greeter` tem `session optional pam_systemd.so`: o greeter ganha sessão logind, `XDG_RUNTIME_DIR=/run/user/<uid sddm>` e um `systemd --user`.
- Os pós-instalação do Arch habilitam globalmente `pipewire.socket`, `pipewire-pulse.socket` e `wireplumber.service` (`systemctl --global enable ...` no `install` de cada pacote; lido de `/var/lib/pacman/local/*/install` no container). Logo o `systemd --user` do `sddm` sobe o PipeWire por socket quando o primeiro cliente conecta (comportamento sob SDDM **não verificado**; relatos de que o PipeWire do `sddm` às vezes não sobe ou sobe depois: https://github.com/reaperwatch/sel-sddm-fedora, https://forum.manjaro.org/t/howto-workaround-no-audio-output-on-boot-with-pipewire-1-2-0/168188). Receitas conhecidas: `sudo -u sddm pw-cli info 0` para testar; `loginctl enable-linger sddm` se o `user@` do sddm não ficar.
- `sddm-greeter-qt6` linka Qt6 Quick/Qml do sistema (`ldd`); o módulo QML `QtMultimedia` é carregado do import path do sistema (`/usr/lib/qt6/qml`), então `import QtMultimedia` funciona se o pacote existir. **Não verificado** rodando o greeter (o greeter é X11 no sddm 0.21, `DisplayServer=x11`, e não toca ao ser aberto por `sddm-greeter-qt6 --test-mode` neste container sem X).
- O mesmo greeter já lê `/run/yorha-os/handoff` com `QML_XHR_ALLOW_FILE_READ=1` (`system/boot-login/files/sddm.conf.d/yorha-os.conf`), então ler `/run/yorha-os/sound.state` (R4) é igual.
- Efeito colateral útil: o PipeWire do `sddm` tem de largar a placa para o do usuário que entra? Não: o `user@sddm` sai com a sessão do greeter; o do usuário reserva a placa de novo. Risco de som cortado/estalo na troca (**não verificado**).

**Alternatives.** ALSA direto pelo QtMultimedia (sem PipeWire no `sddm`): o backend ffmpeg sai pelo Pulse, então só funciona com `pipewire-alsa`/`pulse`; se for preciso, apontar `audioDevice` para um dispositivo ALSA, mas ele brigaria com o PipeWire que já tem a placa; `aplay -D plughw` por serviço root (acima); `QT_MEDIA_BACKEND`/`QT_AUDIO` variáveis em `GreeterEnvironment` (**não verificado**).
**Risks.** (1) Greeter sem servidor de som: login mudo (aceito, documentar). (2) Qualquer coisa de áudio que bloqueie a thread do QML trava as animações do greeter: `SoundEffect` carrega em outra thread, mas medir com o `lab/011/boot-timing` (FR-033: +1 s da 011, +0,1 s do tema). (3) `GreeterEnvironment` já é usado: acrescentar com vírgula, não sobrescrever. (4) Docs oficiais do SDDM não falam de áudio; nenhum issue upstream confirma que o greeter toca som (a busca não achou): tratar tudo como experimento do lab.

## S4. Som de boot

**Decision.** Unidade de sistema `yorha-os-boot-sound.service`, instalada pelo `yorha-os-boot-login`, `Type=simple`, disparada pelo **udev** quando a placa fica pronta (evento `change` do `card*`, regra `ENV{SYSTEMD_WANTS}+="yorha-os-boot-sound.service"`), tocando por ALSA direto (`aplay -q -D plughw:<card>`), sem mexer no mixer. Nenhum `Before=` em `display-manager`/`graphical.target`/`sound.target`/`plymouth-quit`; é *fire-and-forget*.
```
# /etc/udev/rules.d/80-yorha-os-boot-sound.rules   (nome a combinar)
SUBSYSTEM=="sound", KERNEL=="card*", ACTION=="change", ENV{SOUND_INITIALIZED}=="1", \
  ENV{SYSTEMD_WANTS}+="yorha-os-boot-sound.service"

# /etc/systemd/system/yorha-os-boot-sound.service
[Unit]
Description=YoRHa-OS boot sound
After=alsa-restore.service            # mixer restaurado; só ordena, não atrasa ninguém
ConditionPathExists=!/run/yorha-os/boot-sound.done
ConditionPathExists=/usr/share/yorha-os/boot/sounds
[Service]
Type=simple
ExecStart=/usr/share/yorha-os/boot/sound/yorha-boot-sound
TimeoutStartSec=5
RuntimeMaxSec=6
Nice=10
User=root   # ou DynamicUser com SupplementaryGroups=audio (ver Risks)
```
O script: lê `/var/lib/sddm/state.conf` (`[Last] User=`), lê o estado do usuário, grava a cópia sanitizada em `/run/yorha-os/sound.state` (0644, para o greeter), toca o WAV do nível certo e cria `/run/yorha-os/boot-sound.done`. Termina em ~1–2 s, antes de o WirePlumber da sessão pedir a placa (o WirePlumber só sobe quando existe `user@` do primeiro cliente, ou seja no login/greeter).

**Volume e mudo.** O shell (Quickshell) grava, a cada mudança (debounce 500 ms) e no logout, `~/.local/state/yorha-os/sound.json` = `{"volume":0.30,"muted":false,"bootLogin":true}` com o volume/mudo do sink padrão (`Pipewire.defaultAudioSink.audio`) e a opção "Boot and login sounds". O serviço root pega o usuário em `/var/lib/sddm/state.conf` (`[Last] User=`; `Configuration.h` do SDDM: `<home de sddm>/state.conf`, chaves `Session`, `User`: https://github.com/sddm/sddm/blob/develop/src/common/Configuration.h) e lê o arquivo na home dele (root lê qualquer home; se a home for criptografada e ainda não montada, não existe: cai nos 30 %). Sem arquivo ou sem usuário: 30 %. Mudo ou `bootLogin:false`: não toca. O serviço aceita só números (0..1) e boolean, ignora o resto. Escalar sem tocar o mixer: **variantes pré-renderizadas** (`boot-10/20/30/40/50/70/100.wav`), escolhe a mais próxima (curva ganho = (v)² como a do `sons.md` §6.1). `softvol` do ALSA exige um controle novo no mixer e config em `/etc/asound.conf` (mexe no sistema); `sox -v` adiciona dependência (`sox` 14.8.0.1-1 puxa `ffmpeg`, `wavpack`... ) para um ganho que o script já faz.
**Por que `plughw:N` e não `default`:** com `pipewire-alsa` instalado, o `default` do ALSA vira PipeWire (`/etc/alsa/conf.d/99-pipewire-default.conf`), que não existe ainda no boot de sistema (é serviço de usuário). `plughw:N` abre a placa direto e reamostra/converte (mono 48 kHz → o que o hardware aceitar). O número da placa vem do próprio evento udev (`%E{ALSA_CARD_NUMBER}` via template `yorha-os-boot-sound@.service`; a variante simples usa `aplay -l`/`/proc/asound/cards` e pega a primeira placa que não é HDMI: **a escolher no lab**).

**Rationale.** `sound.target` não garante placa (é `StopWhenUnneeded` e o alsa-utils o liga por `alsa-restore.service`, que roda mesmo sem placa por `ConditionPathExistsGlob=/dev/snd/control*`); o udev `change` com `SOUND_INITIALIZED=1` (`/usr/lib/udev/rules.d/78-sound-card.rules`) é o sinal oficial de "cartão completo". `Type=simple` com nada ordenado depois dele não atrasa nenhuma unidade (`oneshot` só atrasaria o que tem `After=` nele, e mantém o *start job* ativo; evitar). O udev dispara na ordem natural (2–4 s no boot do dono, durante a lista do Plymouth), e `ConditionPathExists=!.../done` impede repetir em placa HDMI/USB depois.
**Alternatives.** `aplay` com `After=sound.target` (placa pode não existir); regra em *initramfs* (bloqueia o boot do mkinitcpio; fora da regra "não atrasar"); tocar pelo PipeWire do sistema (`pipewire --system`: não é suporte padrão do Arch); tocar de dentro do Plymouth (a spec proíbe mudar o Plymouth, FR-028); usar o `yorha-boot-watch.service` existente (`WantedBy=sysinit.target`, `ConditionPathExists=/run/plymouth/pid`) como gancho: roda cedo demais (antes da placa) e é do fluxo de falhas.
**Acesso exclusivo.** O `aplay` com `plughw` abre o `hw` exclusivo. O WirePlumber (ALSA monitor, reserva `org.freedesktop.ReserveDevice1`, https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/alsa.html) tenta abrir a placa quando sobe; se o `aplay` ainda segura, ele recebe `EBUSY` e tenta de novo (relato: re-tenta por 1 s após handover, https://github.com/esoltys/luminous/pull/1876; **não verificado** no WirePlumber 0.5.18 para o caso `aplay` que não usa D-Bus). Por isso o som tem de ser curto (≤ 1,5 s, `RuntimeMaxSec=6` mata um travado) e tocar *antes* do primeiro login/greeter (o `user@` só aparece com a sessão do greeter, depois do `sddm.service`, que espera `plymouth-quit.service`). Se o boot do sistema for tão rápido que o greeter chegue antes do fim do WAV, o resultado é no pior caso um sink que nasce 1 s depois; **medir** `boot-timing` (FR-033).
**Evidence.**
```
$ pacman -Ql alsa-utils | grep -E "sound.target|service|rules"
 /usr/lib/systemd/system/alsa-restore.service  (ConditionPathExistsGlob=/dev/snd/control*, Type=oneshot)
 /usr/lib/systemd/system/sound.target.wants/alsa-restore.service  alsa-state.service
 /usr/lib/udev/rules.d/90-alsa-restore.rules  /usr/lib/systemd/system/alsa-card-wait@.service
$ cat /usr/lib/udev/rules.d/78-sound-card.rules  -> "ACTION=="add|change", KERNEL=="controlC*" ... SOUND_INITIALIZED=1" (comentário: "control node is the sync point")
$ cat /usr/lib/systemd/system/sound.target  -> StopWhenUnneeded=yes (sem Wants de placa)
$ cat /usr/lib/systemd/system/sddm.service -> After=systemd-user-sessions plymouth-quit systemd-logind
$ cat /usr/lib/tmpfiles.d/sddm.conf -> d /var/lib/sddm 0750 sddm sddm ; (state.conf fica nessa pasta, legível só por sddm/root)
```
**Risks.** (1) Mixer da placa em mudo/baixo num sistema novo: o boot soa mudo até o `alsa-restore`/WirePlumber ter salvo o estado (primeiro boot depois da instalação), aceito e documentado; o oposto (volume alto do `Master` do ALSA) é o mesmo volume da sessão anterior, o que é o desejado. (2) A home pode estar criptografada/bloqueada: cai nos 30 %. (3) Rodar como root só para ler um arquivo de usuário: endurecer com `ProtectSystem=strict`, `PrivateNetwork=yes`, `NoNewPrivileges=yes`, `ReadOnlyPaths=/home`, `RuntimeDirectory=yorha-os` (cuidado: não apagar o `/run/yorha-os/handoff` do Plymouth ao reiniciar a unidade; usar `RuntimeDirectoryPreserve=yes`). (4) Placa com `snd_hda_intel` `power_save` pode estalar/chiar ao ligar (https://bbs.archlinux.org/viewtopic.php?id=301316): começar o WAV com 20 ms de silêncio. (5) VM do lab: o `hda-output` do QEMU (R6) é a única placa; testar a ordem real do udev lá (**não verificado**).

## S5. Som de entrada, uma vez por login

**Decision.** O shell toca `session_start.wav` quando `Quickshell` sobe **e** o arquivo `$XDG_RUNTIME_DIR/yorha-os/session-start-played` não existe; cria o arquivo depois de tocar. `$XDG_RUNTIME_DIR` (`/run/user/<uid>`, tmpfs, apagado no logout) vale como chave de "este login": o reload do shell (`qs` reiniciado, `hyprctl reload`, falha e reinício) acha o arquivo e não toca; logout/login apaga a pasta e toca. O teste é feito pelo `FileView`/`Process` do Quickshell ou, mais simples e sem corrida, por um `ExecStartPre`-equivalente no `nier-ui-run` (o wrapper do lab): `mkdir` atômico `mkdir "$XDG_RUNTIME_DIR/yorha-os/session-start.lock"` (falha = já tocou) e depois exporta `YORHA_PLAY_SESSION_START=1` para o shell.
**Rationale.** Atômico (`mkdir`), sem estado persistente, sem relógio. Combina com "só abrir o desktop depois do login" (FR-030). O som toca quando a primeira janela do shell fica pronta (`Component.onCompleted` de um `Variants`/`PanelWindow` visível), não no boot do processo.
**Alternatives.** Variável de ambiente no Hyprland (`exec-once`): `exec-once` só roda uma vez por sessão do Hyprland, mas não ajuda quando o shell é lançado de fora; flag em `~/.cache` (sobrevive a reboot: toca nunca mais); `systemd --user` unidade `ConditionPathExists=!` (mais peças).
**Evidence.** O lab inicia o shell por `lab/guest/nier-ui-run` e Hyprland por `hyprland.lua` (`ls YoRHa-OS-private/lab/guest`); nenhum dos dois toca em `XDG_RUNTIME_DIR` hoje. **Não verificado**: reinício do Quickshell no lab.
**Risks.** `XDG_RUNTIME_DIR` com `loginctl enable-linger` não é apagado no logout (o usuário fica com `user@` ativo): toca só no primeiro login depois do boot. Aceitar, ou também gravar o `XDG_SESSION_ID` dentro do arquivo e comparar.

## S6. Verificação no lab

**Decision.** `lab/up <vm> --audio-capture [<arquivo.wav>]` acrescenta aos `args` da VM a placa HDA com saída para WAV no host; dentro da sessão, para o shell/menu, `pw-record` num sink nulo. As duas medições se complementam: a (a) vê o boot e o login (antes do PipeWire do usuário), a (b) vê a sessão.

**(a) QEMU.** Em `lab/up`, no array `args=(... -device virtio-keyboard-pci -device virtio-tablet-pci)` (linha ~28), antes do `case $mode`, acrescentar quando a flag estiver ligada (a flag entra no `for a in "$@"` junto de `--no-wait`):
```
-audiodev wav,id=nierlab-snd,path=$(audio_of "$name"),out.frequency=48000,out.channels=2,out.format=s16
-device ich9-intel-hda -device hda-output,audiodev=nierlab-snd
```
(`audio_of` = novo helper em `lib.sh`, ao lado de `qmp_of/log_of`, ex.: `~/…/vms/<nome>.audio.wav`.) Sem a flag, mantém a VM sem placa de som (hoje não há `-audiodev`/`-device` de áudio em `lab/up`; o grep por `audio|sound|hda` não achou nada).
Verificado no container `qemu-desktop 11.1.3-1`: `-audiodev help` lista `none alsa dbus jack oss pa pipewire sdl spice wav`; `-device help` lista `intel-hda`, `ich9-intel-hda`, `hda-output`, `hda-duplex`, `hda-micro`, `AC97`; o comando abaixo sobe sem erro e cria o arquivo (44 bytes de cabeçalho no início):
```
qemu-system-x86_64 -S -display none -machine q35 -audiodev wav,id=snd0,path=/tmp/x.wav \
  -device ich9-intel-hda -device hda-output,audiodev=snd0     # sobe; arquivo criado
-device hda-duplex,audiodev=snd0   # erro: "Can not open 'adc' (no host audio driver)"  -> usar hda-OUTPUT com o backend wav
```
Cuidados: (i) o backend `wav` grava no *relógio virtual do convidado*, e só quando há *stream* aberto, então a linha do tempo do WAV não é a do relógio de parede, e silêncio sem stream não é gravado: alinhar com um **marcador** (ex.: o convidado toca um pulso de 1 kHz/50 ms em T0 e o host anota `date +%s.%N` na saída do `lab/ssh` que dispara; o pulso no WAV dá o offset). (ii) O arquivo só é finalizado (cabeçalho com tamanho) ao encerrar o QEMU: `lab/down` limpo; para ler antes, tratar `data` com tamanho 0 (ffmpeg lê com `-f s16le` após 44 bytes). (iii) `ich9-intel-hda` combina com `-machine q35` (o `lab/up` usa q35). (iv) O boot do convidado tem de ter `snd_hda_intel` e a firmware nada a mais (VM: sem `sof-firmware`).

**(b) Dentro da sessão.**
```
pactl load-module module-null-sink sink_name=nierlab media.class=Audio/Sink  # ou: pw-cli create-node adapter factory.name=support.null-audio-sink node.name=nierlab media.class=Audio/Sink
pactl set-default-sink nierlab                       # o shell passa a tocar no sink nulo
pw-record --target nierlab.monitor --rate 48000 --channels 1 /tmp/cap.wav &
```
O monitor de um sink nulo grava exatamente o que o shell manda (sem passar pela placa), com o relógio do convidado. Funciona sem placa de som e sem `-audiodev`. Vira `lab/perf`/novo `lab/sound-capture start|stop`.

**Alinhar com as teclas.** `lab/key` fala QMP (`input-send-event`); o `lab/key` deve registrar `t_key=$(date +%s.%N)` do host na hora do envio (o QMP dá `timestamp` do evento no host: `{"event":...,"timestamp":{"seconds":…,"microseconds":…}}`, ver o formato no `lab/key`: **não li o código**) e, na (b), `pw-record` grava a hora de início do convidado (`date +%s.%N` do `lab/ssh`, relógio do convidado = relógio do host na VM com KVM clock, desvio < ms, **não verificado**). Latência = `t_primeira_amostra_acima_do_ruído − t_key`, calculada no Python (`numpy`: limiar de -40 dBFS, janela 1 ms); alvo ≤ 50 ms (SC-008). O resultado entra no relatório do `lab/perf end` (cita no resumo: "tick→som: N ms p95"). Para a rajada (FR-024), contar o número de picos no WAV e comparar com o número de teclas.

**Risks.** (1) O jitter do QMP+VM (~5–15 ms) entra na latência medida: reportar mediana e p95 de ≥ 20 teclas. (2) A gravação (b) mede até o sink nulo, não o hardware: some a latência fixa do HDA (~10–20 ms, **não verificado**). (3) O WAV do (a) cresce ~190 kB/s (stereo s16 48 kHz): só ligar sob demanda. (4) `QT_QPA`/headless: a VM `--headless` (egl-headless) não afeta o áudio.

## Resumo de pacotes

Runtime: `qt6-multimedia`, `qt6-multimedia-ffmpeg` (Quickshell e greeter), `pipewire`, `pipewire-pulse`, `wireplumber` (já usados pela sessão), `alsa-utils` (`aplay` do boot, versão 1.2.16-1). Lab: `qemu-desktop` 11.1.3-1 (já exigido por `require_qemu`), `nier-lab-py` para os WAVs. Sem `sox`.

## Pontos para a spec decidir ou medir primeiro (nada disso foi verificado)
1. Latência do `SoundEffect` em pipewire-pulse (≤ 50 ms) e comportamento de `play()` repetido.
2. O greeter do SDDM conseguir tocar (PipeWire do usuário `sddm`).
3. Ordem real udev vs. WirePlumber e o `EBUSY` entre `aplay` e a sessão.
4. Estado de mixer num sistema novo (boot mudo no primeiro boot).
