# Research: Menu de pausa (007)

Fase 0 do plano. Cada item segue o formato **Decisão / Por quê / Alternativas**. As fontes da web
estão no fim. Nada aqui foi executado: os pontos marcados **(spike)** são conferidos na VM na
tarefa T003 antes do contrato congelar.

## R1. Uma janela, quatro páginas, a moldura com abas

**Decisão:** o menu é um `PopupWindow` só (a moldura da 003), com uma variante de cabeçalho com abas
no `PopupFrame`: quando `tabs` não está vazio, o painel desenha a barra de abas (`TabBar` da 001),
depois o título com a data e a hora à direita, e o corpo começa mais abaixo (`bodyTop`, R12). As
quatro páginas (`AppsPage`, `WindowsPage`, a `SettingsPage` da 003 e `PowerPage`) ficam num
`StackLayout`-like de `Loader`s: cada uma é criada na primeira visita e fica viva até o menu
fechar, pra guardar a posição da pipa (FR-005). Só a aba aberta fica visível e com o foco.

**Por quê:** reaproveita a moldura inteira (escurecimento, fade, clique fora, fechamento em duas
fases, teclado exclusivo) sem cópia (FR-032). Criar na primeira visita poupa o custo de APPS (ícones)
quando o menu abre em outra aba.

**Alternativas:** uma janela por aba (perde o "trocar sem fechar" e duplica o fade); um
`PauseFrame` novo copiado do `PopupFrame` (cópia, contra a FR-032); as quatro páginas sempre
criadas (mais simples, mas paga os ícones de APPS em toda abertura).

**Revisto na implementação (T016, 2026-10-28):** as quatro páginas são criadas junto com o menu (a
alternativa "sempre criadas"). A APPS só desenha um ícone, o da prévia (a lista é texto), então o
custo que o `Loader` pouparia é pequeno; e o `pause dump` precisa do estado de abertura de uma aba
ainda não visitada (contracts/ipc.md), que só a página sabe montar. O menu continua sendo
descarregado inteiro ao fechar.

## R2. O `SUPER + I`: aba SYSTEM, não popup avulso (decisão pedida ao plano)

**Decisão:** o `SUPER + I` (`ALT + I` na VM) passa a abrir o menu de pausa na aba SYSTEM. O popup
avulso da 003 (`SettingsPopup.qml` e o `LazyLoader` dele no `shell.qml`) sai; a `SettingsPage` é
reusada dentro do menu. O alvo IPC `settings` continua, como um alias:
- `settings open` = `pause tab system`;
- `settings toggle` = abre em SYSTEM, troca pra SYSTEM ou fecha (a regra do atalho, FR-001);
- `settings close` = `pause close`, só quando o menu está em SYSTEM; noutra aba, nada;
- `settings dump` mantém o formato da 003 (os campos vêm da página SYSTEM; `open` só é `true` com a
  aba SYSTEM aberta);
- `settings reset` continua.

**Por quê:**
- **uma superfície só:** as configurações existem num lugar, com o mesmo estado (categoria, pipa);
  dois popups com a mesma página teriam dois estados e dois jeitos de fechar;
- **coerente com o jogo:** SYSTEM é uma aba do menu de pausa;
- **o atalho continua valendo** pro dono, e os roteiros da 003 continuam chamando o mesmo alvo;
- **as abas por aba ficam adiadas** (decisão do dono), mas o `SUPER + I` já existe: mantê-lo como o
  único atalho direto não cria atalho novo.

**Custo:** os screenshots de referência da 003 mudam (a página ganha as abas, o título desce e o
rodapé ganha `Tab Next tab`), então o `lab/check-003` é adaptado (T021): as checagens de teclas e
valores ficam iguais, as de geometria passam a ler o `dump`.

**Alternativa:** manter o popup avulso pro `SUPER + I` e a SYSTEM do menu como segunda entrada. Sai
mais barato agora (o `check-003` não muda), mas deixa duas molduras pra mesma página e um
"qual dos dois?" pra sempre.

## R3. Atalhos

**Decisão:**

| Onde | Tecla | Comando |
|---|---|---|
| VM (`lab/guest/hyprland.lua`) | `ALT + Escape` | `qs -p ~/nier/ui ipc call pause toggle` |
| VM | `ALT + I` (já existe) | `qs -p ~/nier/ui ipc call settings toggle` (agora: aba SYSTEM) |
| Sistema instalado (S3/U7) | `SUPER + Escape` | `pause toggle` |
| Sistema instalado | `SUPER + I` | `settings toggle` |

**Por quê:** a convenção ALT da VM evita colidir com o host no modo `--window` (research R4 da 003).
`ALT + Escape` não está em uso no `hyprland.lua` da VM.

**Alternativas:** os atalhos por aba do mockup (`SUPER + Space`, `SUPER + Tab`, `SUPER + Grave`):
adiados pelo dono. O `pause tab <aba>` já deixa ligá-los depois só na config do Hyprland.

## R4. Apps: `DesktopEntries` do Quickshell

**Decisão:** a fonte real é `DesktopEntries.applications` (Quickshell 0.3.1):
- **o que entra:** só entradas `Type=Application` que não são `Hidden` nem `NoDisplay` (a própria
  lista já filtra);
- **um id, uma entrada:** a resolução de prioridade (usuário acima do sistema) é do Quickshell; o
  serviço ainda descarta ids repetidos, por garantia;
- **ao vivo:** desde a 0.2.1 o Quickshell acompanha as mudanças nas pastas de `.desktop` em tempo
  real (sinal `applicationsChanged`), o que cobre o SC-009 (app novo em ≤ 2 s) **(spike)**;
- **campos usados:** `id`, `name`, `genericName`, `comment`, `icon`, `command` (o `Exec` já
  separado em argv), `categories`, `keywords`, `runInTerminal`, `workingDirectory`, `startupClass`
  e `actions` (`DesktopAction`: `name`, `command`).

**Abrir um app (FR-012):**
- **sem interpretador:** `Quickshell.execDetached({ command, workingDirectory })` com o argv da
  entrada, depois de tirar os códigos de campo (`%f %F %u %U %d %D %n %N %i %c %k %v %m`), que o
  `execute()` do Quickshell ignora. O texto da busca nunca chega ao comando;
- **app de terminal:** `[...Settings.terminal, "-e", ...argv]`, com a chave nova `terminal` no
  `defaults.json` (padrão `["kitty"]`);
- **comando inexistente:** antes de abrir, `["sh", "-c", "command -v -- \"$1\" >/dev/null", "sh",
  argv0]` (script fixo, o nome vai como argumento, nunca interpretado). Falhou: uma linha `WARN` no
  log com o motivo, e o app não ganha uso (caso de borda);
- **área de trabalho escolhida:** `Current` abre onde o usuário está; `01`–`10` primeiro leva o
  usuário pra lá (`Compositor.focus(n)`, que já existe) e depois abre. Assim não passa nada por
  `exec_cmd` (que é uma string de shell) e funciona igual no Niri.

**Por quê:** é a API pronta do Quickshell, com os `.desktop` já interpretados e observados, sem
dependência nova. `execDetached` não usa shell.

**Spike (T003, 2026-10-27, `teste-c`, Quickshell 0.3.2, `lab/perf` `2026-10-27T215958-vm-teste-c-007-spike`):**
- um `.desktop` copiado pra `~/.local/share/applications/` aparece em `DesktopEntries.applications`
  em ≈0,1 s (`applicationsChanged`), e some no mesmo tempo quando é apagado. O rascunho está em
  `YoRHa-OS-private/lab/mockups/desktop-spike/`;
- **mas** a pasta tem que existir quando o shell sobe: com `~/.local/share/applications/` criada
  depois, o Quickshell não a observa. O `check-007` cria a pasta antes de reiniciar o shell; o
  instalador (S3) deve criá-la também;
- o `DesktopEntry.id` vem **sem** o `.desktop` (`kitty`, `yorha-test`): o serviço `Apps` acrescenta
  o sufixo, pra os ids reais e os da fixture terem a mesma forma (`kitty.desktop`).

**Alternativas:**
- ler os `.desktop` à mão com `FileView` (reimplementar a spec freedesktop, as prioridades e o
  observador);
- `hl.dsp.exec_cmd(cmd, { workspace = "N silent" })`: abre na área de trabalho sem levar o usuário,
  mas o comando vira uma string de shell (precisa de aspas à prova de tudo) e só existe no Hyprland;
- `uwsm app -- argv`: põe o app numa unidade do systemd (bom pra sessão uwsm), mas muda o ciclo de
  vida do processo; fica como melhoria pro instalador (S3).

## R5. Busca de apps

**Decisão:** uma biblioteca JS pura, `shell/services/appsearch.js` (`.pragma library`), com:
- `normalize(s)`: `NFD`, tira os diacríticos, minúsculas (`Café` → `cafe`, `FIRE` → `fire`);
- `rank(apps, query, uses)`: a faixa de cada app pela FR-010 (0 nome começa com a consulta; 1 uma
  palavra do nome começa; 2 o nome contém; 3 nome genérico ou palavra-chave contém; 4 comando
  contém); fora das faixas, fora da lista; empate: mais usos, depois A–Z pelo nome normalizado.

O roteiro do SC-004 chama a busca por IPC (`pause search <texto>`) e lê `apps.results` no `dump`.

**Por quê:** função pura, sem QML, fácil de conferir com as 10 consultas; a mesma ordem vale pra
fixture e pra dados reais.

**Alternativas:** busca difusa (fuzzy) com pontuação contínua: menos previsível e difícil de provar
com "o esperado em primeiro".

## R6. Ícones: tinta, cor original ou quadrado

**Decisão:**
- **caminho:** `Quickshell.iconPath(entry.icon, true)` (vazio quando o tema não tem o ícone); sem
  ícone, o ícone genérico da categoria, desenhado pelo projeto (`shell/assets/icons/category-*.svg`:
  `system`, `network`, `media`, `office`, `dev`, `graphics`, `game`, `other`);
- **`Ink` (padrão):** um shader de duas cores, `shell/shaders/duotone.frag`: a luminância do ícone
  mistura de `Tokens.color.darkGray` (escuro) a `Tokens.color.lightYellow` (claro), vezes o alfa. O
  ícone fica em tinta sobre o papel, sem perder o desenho. Compilado pelo `build.sh` da 004 (o
  `lab/sync` já recompila na VM). Sem o `.qsb`: `MultiEffect` com `colorization: 1` e a cor da
  tinta, com um aviso no log (como o fallback da 004);
- **`Original color`:** o `Image` puro;
- **`Square only`:** o quadrado do jogo (`Square` da 001), grande, no lugar do ícone;
- **fixtures:** ícones SVG desenhados pelo projeto em `shell/fixtures/pause/icons/` (os glifos
  genéricos do mockup), pra screenshots iguais e nada de ícone de terceiros no repositório.

**Ajuste na T004 (2026-10-28):** os 8 genéricos de categoria são em tinta (`#4E4B42`), como pedido;
os 16 glifos de teste (`shell/fixtures/pause/icons/`) são só de traço, mas cada um numa cor própria
(azul, verde, vermelho…). Em tinta, o estilo `Original color` ficaria igual ao `Ink` e os três shots
do SC-013 não provariam a troca; com cor, a diferença entre os três estilos aparece no screenshot.

**Por quê:** o mockup pedia "o ícone recolorido pro tom do papel"; a silhueta pura (só o alfa em
tinta) apaga o desenho de ícones cheios, e a colorização do Qt multiplica pela luminância (escurece
demais, como na 004). O duotone resolve com um shader de poucas linhas na infraestrutura que já
existe.

**Alternativas:** silhueta pelo alfa (perde detalhe); `MultiEffect` sozinho (escurece); exigir um
tema de ícones monocromático (depende do sistema do usuário).

## R7. Janelas e áreas de trabalho: `hyprctl -j`, no adaptador

**Decisão:** o `Compositor` (o único arquivo que fala com o Hyprland) ganha `windows` e
`workspaceList`, lidos de `hyprctl clients -j` e `hyprctl workspaces -j` por `Process`, como o
`monitorQuery` que já existe:
- **quando:** ao iniciar, e nos eventos crus do Hyprland `openwindow`, `closewindow`,
  `movewindow(v2)`, `windowtitle(v2)`, `changefloatingmode`, `workspace(v2)`,
  `createworkspace(v2)`, `destroyworkspace(v2)`, `moveworkspace(v2)`, `activewindowv2` e
  `fullscreen`, juntos num `Timer` de 50 ms (uma rajada de eventos vira uma leitura). Isso cabe no
  "acompanha em ≤ 1 s" (FR-017, SC-006);
- **campos usados de cada janela:** `address`, `class`, `title`, `initialTitle`, `workspace.id` /
  `workspace.name`, `monitor`, `at`, `size`, `floating`, `focusHistoryID` (0 = a janela em foco),
  `pid`;
- **área especial:** `workspace.id < 0` (nome `special:…`) vira o grupo `SPECIAL`;
- **app de cada janela:** `class` em minúsculas comparado com o `startupClass` e com o id (sem
  `.desktop`) das entradas; sem par, o próprio `class`;
- **fixtures:** domínio `windows` (data-model) com as mesmas formas.

**Por quê:** nas notas do projeto (Quickshell + Hyprland 0.56 com Lua), `Hyprland.monitors` fica
vazio e os `refresh*()` esvaziam as listas; o JSON do `hyprctl` traz tudo que o mapa precisa
(posição, tamanho, flutuante) num formato estável, e o adaptador continua sendo o único lugar a
trocar no Niri (S5).

**Alternativas:** `Hyprland.toplevels` do Quickshell (`HyprlandToplevel.lastIpcObject`): menos
processos, mas sofre das mesmas manias com config em Lua; fica pra quando o Quickshell corrigir.

## R8. Ações nas janelas (spike)

**Decisão:** pelo `Hyprland.dispatch` com expressões Lua, como o `Compositor.focus` já faz:

| Ação | Lua (`Hyprland.usingLua`) | Config antiga |
|---|---|---|
| ir pra janela | `hl.dsp.focus({ window = "address:0x…" })` | `focuswindow address:0x…` |
| mover sem seguir | `hl.dsp.window.move({ workspace = N, follow = false, window = "address:0x…" })` | `movetoworkspacesilent N,address:0x…` |
| flutuar | `hl.dsp.window.float({ action = "toggle", window = "address:0x…" })` | `togglefloating address:0x…` |
| fechar (pedido educado) | `hl.dsp.window.close({ window = "address:0x…" })` | `closewindow address:0x…` |

- **validação antes de montar a expressão:** o endereço tem que bater com `^0x[0-9a-f]+$` e a área
  de trabalho tem que ser um inteiro de 1 a 10; senão, nada é enviado e o log registra;
- **ir pra janela de outra área de trabalho:** o `focus` por janela já troca a área (conferir no
  spike; se não trocar, `focus({ workspace })` antes);
- **fechar:** é o pedido educado (`close`), nunca o `kill`; o app pode perguntar antes.

**Spike (T003):** na VM, conferir cada expressão por `hyprctl dispatch '<expr>'` e pelo
`Hyprland.dispatch`, inclusive o `follow = false` (a wiki lista o campo sem dizer o efeito).
Resultado no `research.md` e na tarefa. Se alguma não existir com esse nome, o adaptador usa a forma
que funcionar, sem mudar o contrato (`Compositor.focusWindow` etc.).

**Resultado do spike (T003, Hyprland 0.56.2):** as quatro expressões existem com esses nomes e
fazem o esperado, sem ajuste na tabela:
- `hl.dsp.focus({ window = "address:0x…" })` numa janela de outra área de trabalho troca a área e dá
  o foco (não precisa do `focus({ workspace })` antes);
- `hl.dsp.window.move({ workspace = 4, follow = false, window = … })` na janela em foco da área 2
  leva a janela pra 4 e o monitor **fica** na 2 (o `follow = false` é o "silent");
- `hl.dsp.window.float({ action = "toggle", window = … })` alterna o `floating`;
- `hl.dsp.window.close({ window = … })` fecha (o kitty sem processo fecha na hora);
- uma expressão errada responde `error: … attempt to call a nil value` (código 7), sem efeito.

## R9. Sessão e energia: logind, por argv

**Decisão:** um serviço novo, `Session`, que só chama programas por argv (nada de shell):

| O quê | Comando |
|---|---|
| pode? (`Suspend`, `Hibernate`, `Reboot`, `PowerOff`) | `busctl --json=short call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager Can<Ação>` → `yes`/`challenge` = disponível; `no`/`na` = apagado, com o motivo ("Not supported on this machine.", "Not allowed.") |
| quem está segurando | `busctl --json=short call … ListInhibitors` → `a(ssssuu)`: `what`, `who`, `why`, `mode`, uid, pid. Só os `mode = block` com `what` contendo `shutdown` (Reboot, Shut down, Log out) ou `sleep` (Suspend, Hibernate) |
| Lock | `loginctl lock-session` (o sinal `Lock` do logind; quem desenha a tela é o locker da sessão, e o do YoRHa-OS vem no U5) |
| Log out | sessão do uwsm (`uwsm check is-active` responde 0): `uwsm stop`; senão `loginctl terminate-session <XDG_SESSION_ID>` |
| Suspend, Hibernate, Reboot, Shut down | `systemctl suspend`, `hibernate`, `reboot`, `poweroff` |
| status | `USER` = `$USER`; `HOST` = `/proc/sys/kernel/hostname`; `UPTIME` = `/proc/uptime` (relido a cada minuto com o menu aberto); `BATTERY` = o serviço `Battery` da 001; `WINDOWS` = `Compositor.windows.length` |

- **quando lê:** as capacidades e os bloqueios são relidos ao entrar na aba POWER e ao abrir o
  diálogo (não ficam em polling);
- **segurança dos testes:** com **qualquer** fixture ativa, o `Session` nunca executa uma ação: só
  registra em `lastAction`. Uma ação real só acontece com o shell sem fixtures (o roteiro do SC-007
  faz isso de propósito, só pro `Reboot`, só na VM);
- **ordem e recusa (precisão da FR-023):** `Lock`, `Suspend` e `Hibernate` fecham o menu e então
  executam (a tela tem que estar limpa); `Log out`, `Reboot` e `Shut down` executam depois da
  confirmação e o menu fecha quando o comando é aceito (saída 0). Uma recusa (saída ≠ 0: falta de
  permissão, um programa bloqueando) deixa o menu aberto com o erro em `alert` no quadro; a de uma
  ação que já fechou o menu vai pro log e pro quadro de POWER na próxima abertura (`lastError`).

**Por quê:** é o caminho padrão do systemd, sem dependência nova (`busctl`, `loginctl` e
`systemctl` vêm no `systemd`); `--json=short` dá saída estável pra ler; o polkit permite essas
ações pra sessão ativa local sem agente (as que pedem senha falham e caem na "recusa").

**Spike (T003):** dentro da sessão gráfica (o `qs` roda nela), `CanSuspend`, `CanHibernate`,
`CanReboot` e `CanPowerOff` respondem `{"type":"s","data":["yes"]}`; por SSH (sessão não ativa)
respondem `challenge`, então o roteiro lê as capacidades pelo `pause dump`, nunca pelo SSH. A VM diz
`yes` até pra `Hibernate` (sem swap): o motivo "apagado" só aparece com a fixture. `ListInhibitors`
com um `systemd-inhibit --what=shutdown --who=pacman --mode=block` rodando na sessão devolve
`{"type":"a(ssssuu)","data":[[["shutdown","pacman","System update in progress","block",1000,1233]]]}`
(um `systemd-inhibit` lançado por SSH falha: precisa da sessão ativa). `loginctl lock-session` sai
com 0 e o sinal `org.freedesktop.login1.Session.Lock` aparece em `sudo busctl monitor` (o monitor
precisa de root). `uwsm check is-active` sai com 0 na VM (sessão do uwsm).

**Na VM:** não há locker instalado, então a prova do `Lock` é o sinal no barramento
(`busctl monitor org.freedesktop.login1`, dentro da VM) e não um screenshot. A sessão da VM é do uwsm
(`exec uwsm start hyprland.desktop` no `bash_profile`), com login automático no tty1: um `Log out`
real reinicia a sessão, o que dá pra conferir pelo id da sessão (opcional).

**Alternativas:** D-Bus direto do QML (o Quickshell não tem cliente D-Bus genérico); `hyprctl
dispatch exit` pro Log out (a wiki do Hyprland desaconselha com uwsm).

## R10. Opções do menu em SYSTEM, trocáveis na hora

**Decisão:**
- **catálogo:** a categoria nova `menu` ("Pause menu") no `settings-default.json`, depois de
  `appearance`, com as cinco escolhas da FR-034. Uma escolha ganha o campo opcional `ids` (mesmo
  tamanho de `values`), pra o código ler um id estável e não o rótulo nem o índice;
- **leitura:** `SettingsModel.choiceId(catId, optId)` devolve o id do valor em uso (`""` sem `ids`).
  O menu liga as propriedades nele (`AppsPage.iconStyle: SettingsModel.choiceId("menu", "icons")`),
  então mudar a opção em SYSTEM muda o menu na hora, sem reabrir;
- **sessão:** os valores vivem em memória, como todo o catálogo da 003 (FR-018 da 003).
  **Guardar entre sessões** segue o mecanismo que a opção `Bar contrast` (frente A da 004, em
  paralelo) adotar; se ela chegar antes da implementação desta spec com outro formato (ex.: uma
  chave do `shell.json` espelhada no catálogo), a T009 se ajusta a ele. É a pergunta 1 do relatório.

**Conferido na T009 (2026-10-28):** o `Bar contrast` (acabamento da 004, mesclado na 007) guarda os
valores de **todo** o catálogo no `SettingsState` (`$XDG_STATE_HOME/yorha-os/settings.json`, chave
`settings.<categoria>.<opção>`, contracts/settings-state.md da 004). A categoria `menu` usa esse
mesmo mecanismo sem código a mais: as cinco opções ficam salvas entre sessões (o "salvar sempre" do
dono), e o `settings reset` as volta ao padrão. Com fixtures, ficam só em memória.

**Por quê:** o catálogo já é a fonte das telas de SYSTEM; um campo opcional e uma função são o
mínimo pra uma opção ter efeito, sem mudar a 003. Uma categoria nova (e não linhas em
`appearance`) evita conflito de merge com o `Bar contrast`, que mexe em `appearance`.

**Alternativas:** chaves no `shell.json` (não trocam pela UI; a regra geral pede SYSTEM); índice
fixo no código (quebra se a ordem dos valores mudar).

## R11. Fixados e usos: arquivo de estado

**Decisão:** `$XDG_STATE_HOME/yorha-os/apps.json` (`{ "version": 1, "pinned": [ids], "uses": { id: n } }`),
lido no início e gravado com `FileView` (`atomicWrites`) a cada mudança, no mesmo padrão do
`wallpaper.json` da 004. Arquivo ilegível: começa vazio e registra no log. Com a fixture `apps`
ativa, nada é gravado (os valores da fixture valem em memória). A última aba usada vale pela sessão
do shell, em memória (FR-001).

**Por quê:** constituição III (estado do usuário fora da config dele); padrão já validado na 004.

## R12. Geometria do painel com abas

**Decisão:** em px do jogo no quadro de 1612 × 908 da 003 (o mesmo `s`), lidos do mockup:

| Peça | y | Notas |
|---|---|---|
| barra de abas | 26 | abas de 214 × 47 (`HeaderButton`), faixas verticais, x 48 |
| régua pontilhada | 83 | 10 abaixo das abas (`TabBar.ruleGap`); a aba aberta desce até ela |
| título + data/hora | 127 | `PageHeader` à esquerda; `Clock.dateText` + `timeText` à direita, `small` |
| régua lisa | 189 | |
| corpo (`bodyTop`) | 221 | até 24 acima da régua do rodapé (820), como na 004 |
| rodapé | 820 / 846 | igual à 003 |

Sem abas, o `PopupFrame` continua como na 003 (título em 42, régua em 112, corpo em 150/170), então
o seletor de papel de parede não muda. A `PickerLayout` e a `SettingsPage` ganham `startY` (padrão 150
e 170, os de hoje) pra começar no `bodyTop`. As colunas continuam nas larguras da 004
(`pickerListW` etc.): o corpo fica mais baixo, não mais estreito, e a lista rola por entradas
inteiras.

## R13. Teclado e foco

**Decisão:**
- **a raiz do menu** (`PauseMenu`, um `FocusScope`) trata o que as páginas não aceitam: `Tab` →
  próxima aba, `Backtab` (Shift+Tab chega assim no Qt) → anterior, dando a volta; letra, número ou
  símbolo (`event.text` imprimível, sem Ctrl/Alt) → vai pra busca de APPS se a aba for APPS, senão
  nada;
- **as páginas** já deixam passar o que não usam (`event.accepted = false` na `PickerLayout` e na
  `SettingsPage`); a `PickerLayout` ganha um ajuste: o `Esc` da lista vira o sinal
  `closeRequested()`, e a `AppsPage` decide (limpa a busca, ou repassa o fechar);
- **Tab vai pra primeira coluna** da aba nova (FR-007), mantendo o item onde a pipa estava;
- **o foco do Qt** nunca anda por Tab sozinho (nenhum item tem `activeFocusOnTab`).

## R14. Laboratório e paralelismo

**Decisão:**
- **branch privada:** `lab-007` no `YoRHa-OS-private`, saindo da `lab-004-acab` (a mais nova);
- **roteiro:** `lab/check-007`, no padrão do `check-004` (`ok`/`ko`, pasta de evidência,
  `summary.txt`, `--only <bloco>`, os dois perfis via `lab/profile`), com um bloco marcado por
  frente pra o merge ser fácil;
- **janelas de teste:** o roteiro abre três `kitty --title …` em duas áreas de trabalho por
  `lab/ipc 'hyprctl dispatch …'` e lê os endereços do `hyprctl clients -j`;
- **app de teste:** um `.desktop` copiado pra `~/.local/share/applications/` da VM (SC-009);
- **VMs:** no máximo 4 ao mesmo tempo, cada uma com `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G` (limite do
  dono). As três frentes paralelas usam `teste-a`, `teste-b` e `teste-c`; se outra rodada estiver
  usando VMs, as frentes andam duas por vez (a terceira espera). A quarta vaga fica livre.

## R15. Abas novas depois (text log da 008)

**Decisão:** as abas são uma lista de dados no `PauseMenu` (`[{ id, label, title, subtitle,
page }]`), com APPS, WINDOWS, SYSTEM e POWER. O dono pediu o text log da U4 "também como aba quando
a U3 entrar": a 008 acrescenta uma entrada nessa lista, sem mudar a moldura. Nada disso é feito
aqui.

## Fontes

- Quickshell `DesktopEntry` (0.3): https://quickshell.org/docs/v0.3.0/types/Quickshell/DesktopEntry/
- Quickshell `DesktopEntries` (0.3.1): https://quickshell.org/docs/v0.3.1/types/Quickshell/DesktopEntries
- Changelog do Quickshell 0.2.1 (entradas acompanhadas em tempo real):
  https://git.outfoxxed.me/quickshell/quickshell/src/commit/11d6d67961fa09a764250474fcf73572547a6743/changelog/v0.2.1.md
- Hyprland 0.56, dispatchers em Lua (`hl.dsp.focus`, `hl.dsp.window.move/float/close`, `hl.dsp.exit`,
  seletores `address:0x…`, aviso sobre uwsm): https://wiki.hypr.land/0.56.0/Configuring/Basics/Dispatchers/
- freedesktop Desktop Entry Specification (códigos de campo, `NoDisplay`, `Hidden`, `Actions`):
  https://specifications.freedesktop.org/desktop-entry-spec/latest/
- logind D-Bus (`CanSuspend`, `CanHibernate`, `ListInhibitors`, `Lock`):
  https://www.freedesktop.org/software/systemd/man/latest/org.freedesktop.login1.html
