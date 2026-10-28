# Pesquisa (Fase 0): Pod e text log

Cada item: **Decisão**, **Motivo**, **Alternativas**. As fontes são a documentação e o código do
Quickshell (`Quickshell.Services.Notifications`, `Quickshell.Services.Pipewire`), a especificação de
notificações do freedesktop (1.2) e o que a 003 e a 004 já aprenderam na VM. O que só a VM confirma
fica marcado **(spike T004)** e é a primeira coisa a rodar.

## R1. O servidor de notificações

- **Decisão:** um `NotificationServer` do Quickshell dentro de um serviço novo, `NotifyStore`
  (singleton). Ele anuncia: `bodySupported`, `bodyMarkupSupported`, `actionsSupported`,
  `imageSupported`, `persistenceSupported`, `inlineReplySupported` (nome confirmado no spike; no
  código, o servidor só anuncia `inline-reply` quando a flag está ligada) e `keepOnReload: true`. Toda
  notificação recebida ganha `tracked = true` na hora; sair da tela não chama `dismiss()` nem `expire()`
  (FR-008): só o usuário (dispensar, limpar o log) ou o app (`closed` com `CloseRequested`) encerram a
  notificação.
- **Motivo:** é o servidor do freedesktop que o Quickshell já traz, sem daemon novo e sem D-Bus escrito
  à mão; o `keepOnReload` reemite as notificações vivas depois de recarregar o shell
  (`lastGeneration = true`), o que cobre "sobrevive a recarregar".
- **Alternativas:** mako/dunst com tema (não fazem transmissão, nem log navegável); servidor próprio em
  Python (um daemon a mais, contra a VII).

## R2. Saber se o shell é mesmo o servidor (FR-002)

- **Decisão:** o código do Quickshell tenta registrar `org.freedesktop.Notifications`; se outro
  processo já tem o nome, ele só loga um aviso e tenta de novo quando o nome ficar livre. Como a UI não
  recebe esse resultado, o `NotifyStore` pergunta ao barramento, por `Process` com argv (sem shell):
  `busctl --user status org.freedesktop.Notifications`, lendo `PID=` e `Comm=`. `server: true` quando o
  `Comm` é o do Quickshell (`quickshell`/`qs`); senão `server: false` e uma linha `console.info` com o
  processo dono. Pergunta no começo (depois de 500 ms), a cada 30 s enquanto `server: false` e a cada
  `notify dump`.
- **Motivo:** é o único jeito de exportar `server` sem mexer no Quickshell. O `GetServerInformation`
  responde `quickshell` quando somos nós, mas não diz quem é o outro.
- **Ressalva:** o aviso do próprio Quickshell ("could not register…") cai no log como `WARN` quando há
  outro servidor. É o caso de borda da FR-002, não o roteiro normal: o SC-012 roda sem outro servidor e
  o teste da borda filtra essa linha conhecida.

## R3. Nenhum outro servidor na VM

- **Decisão:** a camada `hypr-base` não tem mako, dunst, swaync nem o Serpantinum (conferido no
  `lab/provision/hypr-base.sh`). O cuidado é a **ativação por D-Bus**: qualquer pacote que instale um
  `.service` com `Name=org.freedesktop.Notifications` em `/usr/share/dbus-1/services/` faz o primeiro
  `notify-send` acordar esse daemon se o shell estiver reiniciando naquele instante, e aí o daemon fica
  com o nome. O `lab/check-008` confere, antes de tudo: nenhum arquivo de serviço com esse nome
  (`grep -l` nos dois diretórios de serviços), nenhum processo `mako|dunst|swaync`, e o dono do nome é o
  `qs`. A VM de teste (`teste-*`) recebe só `libnotify` (o `notify-send`), `pipewire`, `wireplumber` e
  `brightnessctl`, por um passo de provisão novo (`lab/provision/notify.sh`), sem tocar as camadas
  congeladas.
- **Motivo:** sem isso o SC-001 depende de sorte. O caso de borda "outro servidor rodando" é testado de
  propósito, subindo um servidor falso de teste (`lab/notify-client hold-name`, que só pega o nome) e
  derrubando-o depois.
- **Alternativas:** instalar o mako e mascarar o serviço (mais coisa pra lembrar; nada ganha).

## R4. Substituição (`replaces_id`) e agrupamento

- **Decisão:** no Quickshell, uma notificação que substitui outra **reaproveita o mesmo objeto**:
  `updateProperties` muda os campos e nenhum sinal `notification` novo chega. O `NotifyStore` liga
  `summaryChanged`, `bodyChanged`, `actionsChanged`, `hintsChanged`, `imageChanged` e `urgencyChanged`
  de cada objeto rastreado a um `replace(id)` que atualiza a entrada do log e a transmissão no lugar
  (FR-016) e guarda o índice do primeiro caractere diferente, de onde a digitação recomeça (FR-006).
  Vários sinais seguidos da mesma atualização se juntam num só (`Qt.callLater`).
- **Agrupamento (FR-017):** a chave é `desktopEntry` ou, sem ela, `appName`. Chegou uma do mesmo app
  com a transmissão dele na tela → a transmissão passa a mostrar a nova, `count + 1`, e o tempo
  recomeça; no log, cada uma é uma entrada.

## R5. Ações e resposta

- **Decisão:** `actions` (lista de `NotificationAction`: `identifier`, `text`, `invoke()`); a ação de
  id `default` não vira botão: é o clique na transmissão (FR-009). `resident` decide se a notificação
  continua viva depois da ação (FR-013). A resposta usa `hasInlineReply`, `inlineReplyPlaceholder` e
  `sendInlineReply(text)` (o rótulo do botão é o `inlineReplyPlaceholder` ou `Reply`). Só com o campo de
  resposta aberto a janela das transmissões pede teclado (`WlrKeyboardFocus.OnDemand`); ao mandar ou
  cancelar, volta a `None`, e o Hyprland devolve o foco à janela de antes **(spike T004)**.
- **Cliente de teste:** `notify-send --action=… --wait` imprime o id da ação clicada (SC-004). Pra
  resposta, o `notify-send` não serve: o `lab/notify-client` usa o `gdbus` (pacote `glib2`, já na base)
  pra chamar `Notify` com a ação `inline-reply` e espera o sinal `NotificationReplied` com
  `gdbus monitor`, imprimindo o texto recebido. O mesmo cliente manda a substituição (`replaces_id`), a
  dica `value` (progresso), `image-path` e a enxurrada de 100.

## R6. Imagens

- **Decisão:** `Notification.image` é uma string (caminho de arquivo, URL ou o `image://` que o
  Quickshell cria pros dados de imagem enviados). Um caminho de arquivo passa antes pelo mesmo filtro da
  004 (`file --brief --mime-type -- <caminho>`, argv), porque o `Image` do Qt loga `WARN` quando não
  decodifica um arquivo (achado da 004, R6); fora de jpg/png/webp → ignorada com `console.info`. O
  `image://` do Quickshell entra direto. O quadrado é de 72 px × escala, `PreserveAspectCrop`,
  `sourceSize` no tamanho físico, assíncrono.
- **Alternativas:** mostrar o ícone do app (o jogo não tem; o quadradinho ocupa o lugar, decisão da
  spec).

## R7. Marcação e segurança do texto (FR-036)

- **Decisão:** uma função pura `NotifyText.sanitize(body)` escapa tudo (`&`, `<`, `>`, aspas) e devolve
  só `<b>`, `<i>` e `<u>` reabertos a partir das tags originais bem formadas; `<a href>` vira o texto do
  link; `<img>` e o resto saem. O resultado é desenhado com `Text.StyledText`. O título e o nome do app
  são `PlainText`. Nada do texto vai pra `Process` (o injetor de exemplos usa textos fixos do
  `Strings`, nunca texto recebido).
- **Digitação com marcação:** a função `NotifyText.cut(styled, n)` devolve os primeiros `n` caracteres
  **visíveis**, fechando as tags abertas, pra o negrito não "pular" no fim da digitação.

## R8. Digitação, cursor e tempo

- **Decisão:** um componente `TypedText` com `shown` (int, caracteres visíveis) animado por **uma**
  `NumberAnimation` linear de `from` até o fim, com duração `min(n / cps, maxMs)` (`cps` 90, `maxMs`
  700, em tokens). O cursor de bloco é um `Rectangle` posto no fim do texto visível via
  `positionToRectangle`, só durante a digitação (como no mockup); ele some ao terminar. `instant` (fixtures, movimento reduzido, `Typing: Off`) → `shown` no
  fim, sem cursor (FR-031). O tempo na tela é outro `Timer` por transmissão, que só começa com
  `TypedText.done`, pausa com o mouse por cima ou o campo de resposta aberto, e expõe `remaining` (ms)
  pro `dump` e pra linha de tempo (uma `NumberAnimation` na largura, parada com `instant`).
- **Motivo:** uma animação por transmissão, sem `Timer` de 11 ms; é o único movimento contínuo da fase
  (spec, "Desempenho").

## R9. As janelas: transmissões, OSD e log

- **Transmissões:** um `Variants` sobre `Quickshell.screens` com um `LazyLoader` por monitor, ativo só
  enquanto aquele monitor tem algo pra mostrar. Dentro, `NotifyLayer`: `PanelWindow` transparente na
  tela inteira (como a `PopupWindow` da 003), camada `Overlay` (a crítica aparece até sobre tela cheia),
  `exclusionMode: Ignore`, namespace `rien-notify`, `mask` = a união das caixas visíveis (o resto da
  tela continua clicável), teclado `None` (ou `OnDemand` com a resposta aberta). A posição da pilha
  (Corner, Top band, Subtitle) e a da faixa crítica são calculadas dentro dela, então trocar a opção
  não recria janela (FR-041).
- **OSD:** `OsdWindow`, outra `PanelWindow` `Overlay`, do tamanho do OSD, ancorada embaixo ou em cima
  com margem, `mask` vazia (não pega clique, FR-030), teclado `None`, namespace `rien-osd`, criada só
  enquanto o OSD está visível.
- **Log:** `LogPopup` = `PopupWindow` da 003 com a `LogPage` dentro. Abre e fecha como os outros
  popups do `shell.qml` (monitor em foco relido, fechamento em duas fases). Abrir o log fecha o
  configurações e o seletor, e vice-versa.
- **Animações do compositor:** as três namespaces ganham `noanim` na config da VM (como o `rien-popup`
  precisa pra screenshots iguais), pra o fade e a varredura serem só os nossos.
- **Alternativas:** uma janela por transmissão (layer surfaces demais numa enxurrada); janela fixa por
  monitor sempre criada (superfície transparente parada a toa).

## R10. O monitor em foco na hora da chegada

- **Decisão:** o `Compositor` passa a atualizar `focusedMonitor` também no evento `focusedmon` do
  Hyprland (hoje só relê nos eventos de monitor e antes de abrir popup), pra uma notificação que chega
  saber o monitor sem esperar um `hyprctl`. Com a opção `Monitor` num nome fixo, vale o nome (se ele
  existir; senão o em foco, caso de borda).

## R11. Tela cheia em foco (FR-027)

- **Decisão:** acréscimo no `Compositor`: `focusedFullscreen: bool`, do campo `fullscreen` do
  `hyprctl activewindow -j`, relido nos eventos `fullscreen`, `activewindow` e `workspace`. Com
  fixtures: o domínio `notifications.fullscreen` (padrão `false`). Continua sendo o único arquivo que
  fala com o Hyprland.

## R12. As fontes do OSD (FR-028)

- **Volume e mudo:** `Pipewire.defaultAudioSink.audio` (`volume`, `muted`), que o `Audio` da 001 já
  rastreia com `PwObjectTracker`. O serviço novo `Osd` liga `volumeChanged`/`mutedChanged` do nó atual;
  troca de nó padrão e o primeiro valor (shell iniciando) **não** mostram OSD. O valor mostrado é o real
  (`round(volume × 100)`, pode passar de 100, caso de borda); o medidor satura em 100.
- **Microfone:** `Pipewire.defaultAudioSource.audio.muted` → `MIC ON`/`MIC OFF`, sem medidor.
- **Brilho:** o sysfs não avisa mudança por inotify, então o `FileView.watchChanges` não serve. O `Osd`
  roda `udevadm monitor --kernel --subsystem-match=backlight` (argv, processo longo, `SplitParser`) e,
  a cada evento, relê `brightness` e `max_brightness` do primeiro dispositivo em
  `/sys/class/backlight/`. Sem dispositivo (a VM), `brightnessAvailable: false` e só o IPC mostra o OSD
  de brilho. A prova com luz de fundo de verdade fica pra homologação do dono (U7), como a spec já diz.
- **Na VM:** sem placa de som, o PipeWire não tem saída. O `lab/provision/notify.sh` cria um sink e um
  source nulos persistentes (config do WirePlumber em `~/.config/wireplumber/` **da VM**) e o
  `lab/guest/hyprland.lua` liga `XF86AudioRaiseVolume`/`LowerVolume`/`Mute`/`MicMute` ao `wpctl` com
  passo de 2% (o "64 → 66" da spec). O `lab/key volumeup` manda a tecla real pelo QMP.
- **Supressão (FR-029):** `Osd.suppress(kind, on)`. A `SettingsPage` liga a supressão do volume e do
  mudo enquanto o foco está em `sound.volume`/`sound.mute`, e do brilho em `display.brightness`. Hoje
  essas opções são de teste (não mudam o sistema), mas a regra já fica pronta e testada: com o foco no
  slider, um `wpctl` de fora não mostra OSD.

## R13. Opções que valem de verdade no catálogo da 003 (FR-038)

- **Decisão:** o catálogo ganha um campo opcional por opção, `live: "<fonte>.<chave>"`. O
  `SettingsModel` passa a ler e escrever o valor dessas opções numa **fonte viva** registrada por nome
  (`liveSources`: `notify` → `NotifyPrefs`), em vez da memória: `value()` lê da fonte; `step`,
  `activate` e `pick` escrevem nela; `reset()` não toca opções vivas. Uma fonte viva expõe
  `liveValue(key)`, `setLiveValue(key, v)`, `liveValues(key)` (pra a `Monitor`, cujos valores são as
  saídas) e o sinal `liveChanged`. As outras opções continuam dados de teste (FR-018 da 003).
- **Motivo:** a categoria Notifications vale de verdade sem tornar o resto da 003 real. É o mesmo
  problema da opção "Bar contrast" da 004, em andamento em paralelo: **o campo `live` é proposto como o
  contrato comum**. Se a "Bar contrast" chegar antes com outro mecanismo, a 008 adota o dela (tarefa
  T013 confere antes de escrever).
- **Alternativas:** um popup de opções próprio das notificações (contra a regra do dono: as opções
  ficam nas configurações do sistema); tornar todo o `SettingsModel` real (fora do escopo).
- **Emenda (T013, 2026-10-28):** a "Bar contrast" da 004 chegou antes, com o campo `"setting":
  "<chave>"` e a API `levelsOf`/`levelOf`/`setLevel`, e com o `SettingsState` ("salvar sempre",
  `specs/004-wallpaper-system/contracts/settings-state.md`, que já reservava o prefixo
  `notifications.`). A 008 adota os dois: as opções da categoria usam `"setting": "notify.<chave>"`, o
  `NotifyPrefs` expõe a mesma API (mais `labelsOf`, pros rótulos do `Strings`), e o `SettingsModel`
  manda as chaves `notify.*` pra ele. O campo `live`, os `liveSources` e o `valuesFrom` não existem.

## R14. Onde as escolhas e o log ficam guardados (FR-019, FR-040)

- **Decisão:**
  - padrões do projeto em `shell/config/defaults.json`, bloco `notifications` (gerenciado);
  - o `shell.json` do usuário pode sobrescrever cada chave (só lido, como na 004);
  - as escolhas e o não perturbe no `SettingsState` da 004 (`$XDG_STATE_HOME/rien-os/settings.json`,
    chaves `notifications.<chave>`; vale mais que os dois de cima). **Emenda da T013:** era um
    `notifications.json` próprio, escrito pelo `NotifyPrefs`; o `SettingsState` já faz isso (leitura
    no início, escrita atômica juntada, nada com fixtures);
  - o log salvo em `$XDG_STATE_HOME/rien-os/text-log.json`, só com `Saved`.
- **Permissão do log salvo (SC-015):** antes da primeira escrita, `install -m 600 /dev/null <arquivo>`
  (argv). O `FileView` escreve atômico (arquivo temporário + rename); se o rename não mantiver o 600
  **(spike T004)**, o `NotifyStore` roda `chmod 600 -- <arquivo>` depois de cada escrita. Escritas se
  juntam num `Timer` de 500 ms (uma enxurrada de 100 vira uma escrita).
- **Voltar pra Session only:** apaga o arquivo na hora (`rm -f -- <arquivo>`, argv) (FR-019).
- **Com fixtures:** nada é escrito (FR-043), como o `WallpaperStore`.
- **Arquivo ilegível ou de versão desconhecida:** vai pra `text-log.json.bak-<data>`, o log começa
  vazio e uma linha `console.info` diz o motivo (caso de borda; não pode ser `warn`, pela FR-037).

## R15. Sobreviver a recarregar o shell (FR-019)

- **Decisão:** o estado da sessão (entradas do log como dados simples, lidas/não lidas, contagem
  `+N in log`) fica num `PersistentProperties` (`reloadableId: "notify-session"`), que o Quickshell
  mantém entre recargas. Depois da recarga, as notificações vivas reemitidas pelo servidor
  (`lastGeneration`) são religadas às entradas pelo `id`; a entrada sem objeto vivo vira "fechada".
  A pilha na tela não volta (o que estava na tela vai pro log como lido).

## R16. A tela do log em dois lugares (FR-044)

- **Decisão:** `LogPage` é o corpo, sem janela: recebe `s` e o tamanho do corpo do pai, desenha as três
  colunas e expõe `title`, `subtitle`, `footerLeft`, `keys`, `dumpState()` e `restart()` — o mesmo
  formato da `SettingsPage`, que a 007 já planeja pôr na aba SYSTEM (FR-019 da 007). O `LogPopup` é a
  `PopupWindow` + `LogPage`; a 007 põe a mesma `LogPage` numa aba.
- **Layout proporcional:** o `PickerLayout` da 004 usa posições fixas do quadro de 1612 × 908. A 007
  pede colunas proporcionais ao corpo (FR-008 dela). A 008 acrescenta ao `PickerLayout`, sem mudar o
  padrão: `fluid: bool` (as três colunas e o topo calculados a partir de `width`/`height`, mantendo as
  proporções do quadro) e opções do tipo `action` (`{ id, label, type: "action", text }`, Enter ou
  clique → `invoked(option)`). É o mesmo acréscimo que a 007 vai precisar: **contrato comum**,
  combinado no plano da 007 (pergunta ao dono).
- **Linhas do log:** a `GroupedList` ganha, nos itens, `lead` (texto em peso forte antes do rótulo:
  quem fala + `×N`), `tag` (a caixinha `NEW`) e `markColor` (o quadradinho em `alert` nas críticas); o
  `trailing` já existe (a hora). Acréscimos com padrão vazio: a 004 não muda.

## R17. O injetor de testes e as fixtures (FR-032)

- **Decisão:**
  - `notify sample <nome>` roda, pelo `Process` com argv, o `notify-send` (ou o `gdbus`, pros casos que
    o `notify-send` não cobre) com os textos fixos do mockup: passa pelo caminho real de um app. Nomes:
    `normal`, `actions`, `reply`, `critical`, `flood5`, `long`, `progress`, `low`, `script100`, `system`
    (a voz do sistema);
  - **fixtures** (domínio `notifications`, arquivo `shell/fixtures/notifications-default.json` e
    variações): o log, a pilha, as críticas, o OSD, o não perturbe, a tela cheia e as opções, com horas
    fixas. Com fixtures, as transmissões da fixture não expiram nem digitam, e as que chegarem por D-Bus
    aparecem inteiras, sem tempo (screenshots iguais, SC-002).
- **Mensagens do próprio rien-OS:** um `NotifyStore.system(title, body, urgency)` cria uma entrada com
  a voz do sistema, sem passar pelo D-Bus (não há app pra avisar). Nesta fase, só o injetor e o aviso
  "notification server unavailable" usam.

## R18. Enxurrada (SC-005)

- **Decisão:** as chegadas entram numa fila e são aplicadas num `Timer` de 16 ms (um quadro): o log é
  um array JS trocado uma vez por quadro, não uma vez por notificação; a pilha aplica o limite e o
  agrupamento sobre o lote. O log corta no `Log size` no mesmo passo. A lista do log usa a rolagem por
  entradas da `GroupedList` (sem `ListView` de 100 delegados vivos).

## R19. Medir o tempo do "pronto quando" (SC-001)

- **Decisão:** dentro da VM, o `lab/check-008` grava `date +%s%3N` antes do `notify-send`; o `notify
  dump` traz, por transmissão, `arrivedAt` e `shownAt` (ms, `Date.now()` no shell) e `typedAt`. Tudo no
  relógio da VM, sem depender da latência do SSH.
