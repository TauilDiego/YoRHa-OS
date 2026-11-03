# Feature Specification: SYSTEM de verdade

**Feature Branch**: `019-sistema-real` (sai da `015-correcoes`, commit 15bea74)

**Created**: 2026-11-03

**Status**: Rascunho. O dono aprovou o plano e a ordem das ondas e respondeu às 5 perguntas em 03.11
(ver "Decisões do dono"). Falta ele aprovar o texto e os requisitos de "Acrescentados, a aprovar".

**Input**: A auditoria da 015 (D-01) achou 31 das 63 opções do SYSTEM (SUPER+I) com valores
inventados: Wi-Fi `home-5G`, teclado Bluetooth `K2 Keyboard`, bateria `87% · charging` num PC sem
bateria. Mudar o valor só grava no `settings.json`. O dono, em 03.11: "mapear tudo que a gente tem
faltando e fazer um plano pra implementar TODAS os placeholders... classificar por ordem de
complexidade e fazer os mais simples. os que dependem de outra ferramenta tu fala comigo pra gente
ir ajustando." Ele decidiu não esconder nem apagar: as opções viram reais, das simples pras
difíceis. Fonte: o plano aprovado (`frolicking-juggling-lemon.md`); aqui, "onda" é o que o plano
chama de onda.

## As 31 opções

As outras 32 opções do catálogo já são reais e não mudam: Sound (5, da 013), Notifications (11),
Appearance (5), Pause menu (5), Keyboard › Layouts (1), Updates (5).

Onda 1 tem 15 opções, a onda 2 acrescenta 2 e a onda 3, 14. Resolution, Refresh rate e Scale aparecem
em duas ondas: leem na 1B e mudam na 2.

| Opção | Onda | O que a linha faz quando real | De onde vem o valor | Sem o hardware ou a ferramenta |
|---|---|---|---|---|
| Display › Resolution | 1B lê; 2 muda | 1B: mostra a resolução real, só leitura. 2: troca | `hyprctl monitors -j` | Sem resposta do compositor: apagada com o motivo |
| Display › Refresh rate | 1B lê; 2 muda | 1B: mostra os Hz reais, só leitura. 2: troca | `hyprctl monitors -j` | Igual a Resolution |
| Display › Scale | 1B lê; 2 muda | 1B: mostra a escala real, só leitura. 2: troca | `hyprctl monitors -j` | Igual a Resolution |
| Display › Brightness | 1B | Lê e muda a luz da tela | sysfs, o mesmo aparelho que o `Osd.qml` usa; escreve por `brightnessctl` | Sem luz de tela: apagada, "No backlight on this screen." Com luz e sem `brightnessctl`: mostra o valor, não muda, e o card diz por quê |
| Display › Night light | 3 | Esquenta as cores | hyprsunset (a conversar) | A definir na conversa com o dono |
| Sound › Output | 1A | Troca a saída padrão do sistema | `Pipewire.nodes` e a saída padrão do PipeWire, que guarda a escolha; o produto não guarda cópia | Nenhuma saída: apagada, "No sound output found." |
| Sound › Volume | 1A | Lê e muda o volume da saída padrão | PipeWire, sem cópia salva | Igual a Output |
| Sound › Mute | 1A | Liga e desliga o mudo da saída padrão | PipeWire, sem cópia salva | Igual a Output |
| Sound › Microphone | 1A | Lê e muda o nível do microfone padrão | PipeWire, sem cópia salva | Sem microfone: apagada, "No microphone found." |
| Network › Wi-Fi | 3 | Liga e desliga o Wi-Fi | NetworkManager (Networking) | Sem Wi-Fi ou sem o serviço: a definir na conversa |
| Network › Network | 3 | Lista as redes e conecta; pede senha na tela | NetworkManager | Igual a Wi-Fi |
| Network › Wired | 3 | Mostra o estado do cabo | NetworkManager | Igual a Wi-Fi |
| Network › VPN | 3 | Abre ou liga uma VPN | NetworkManager; hoje só pelo `nmcli` | Igual a Wi-Fi |
| Network › Airplane mode | 3 | Desliga os rádios | Wi-Fi e Bluetooth prontos | Depende dos dois |
| Bluetooth › Bluetooth | 3 | Liga e desliga | bluez (Bluetooth) | Sem adaptador ou sem o serviço: a definir na conversa |
| Bluetooth › K2 Keyboard | 3 | É um exemplo inventado: vira a lista real de aparelhos, que muda em tempo real | bluez | Igual a Bluetooth |
| Bluetooth › Headphones | 3 | Igual a K2 Keyboard | bluez | Igual a Bluetooth |
| Bluetooth › Pair a device | 3 | Procura e pareia | bluez | Igual a Bluetooth |
| Appearance › Interface scale | 1D | Muda o tamanho da UI na hora | `Settings.uiScale`; salvo na pasta de estado | Não depende de nada |
| Appearance › Top bar height | 1D | Muda a altura da barra na hora | `Settings.barHeight`; salvo na pasta de estado | Não depende de nada |
| Appearance › Cursor size | 2 | Muda o tamanho do ponteiro | Depende do cursor vir no instalador (D-21) | A definir com a D-21 |
| Appearance › Language | 2 | Troca o idioma da UI | Fase U5b: `Strings.qml` e catálogo por idioma | A definir na U5b |
| Keyboard › Caps Lock | 1C | Muda o que a tecla faz | `input:kb_options` do Hyprland, somado ao que a pessoa já tem; salvo na pasta de estado | Compositor sem suporte: apagada com o motivo |
| Keyboard › Repeat delay | 1C | Muda a espera antes de repetir | `input:repeat_delay`; salvo na pasta de estado | Igual a Caps Lock |
| Keyboard › Repeat rate | 1C | Muda a velocidade da repetição | `input:repeat_rate`; salvo na pasta de estado | Igual a Caps Lock |
| Keyboard › Shortcuts | 1C | Abre a lista dos atalhos do produto, só leitura | Os binds do `yorha-shell.lua`, com o `YORHA_MOD` em uso | Compositor que não diz o modificador: a lista usa SUPER e avisa |
| Power › Battery | 1B | Mostra a carga real, só leitura | `Battery.qml` (UPower) | Sem bateria: apagada, "No battery on this machine." Sem UPower: apagada, "UPower is not installed." |
| Power › Profile | 3 | Troca o perfil de energia | power-profiles-daemon | A definir na conversa |
| Power › Screen off after | 3 | Desliga a tela depois do tempo parado | IdleMonitor (embutido) | A definir na conversa |
| Power › Suspend after | 3 | Suspende depois do tempo parado | IdleMonitor e logind; liga com a tela de bloqueio (D-03, 017) | A definir na conversa |
| Power › Lid closed | 3 | Age ao fechar a tampa | Inibidor do logind e bind `switch:` do Hyprland | Sem tampa: a definir na conversa |

## Revisões de specs anteriores

- **003, FR-018** ("Nada mexe no sistema"): passa a valer só pras opções sem provedor do sistema. As
  opções `sys.*` desta spec mudam o sistema em tempo de execução. A regra "com fixtures nada é lido
  nem escrito" continua, e vale também pro sistema.
- **003, FR-019** (o catálogo é dado de teste): `shell/fixtures/settings-default.json` passa a ser o
  catálogo do produto. Os dados de teste vão pra `fixtures/settings-showroom.json` (FR-008).
- **003, FR-017** (linha apagada por dependência): a mesma aparência passa a valer pra "o sistema não
  tem isso" (FR-004).

## Princípio II

Nada desta spec edita o `hyprland.lua` da pessoa. Leitura e mudança passam pelo compositor e pelo
PipeWire, e o que o produto guarda fica em `$XDG_STATE_HOME/yorha-shell/settings.json`. Os dois pontos
que encostavam no princípio foram decididos pelo dono em 03.11:

1. **"O `hyprland.lua` e os dotfiles são da pessoa" (1C).** Uma linha que a pessoa mudou no menu vence a
   config dela e volta depois de cada reload, sem editar o arquivo. Uma linha que ela não mexeu fica com
   o valor do arquivo. Ver D2.
2. **"O que fica de fora: hardware" (1A, 1B e a onda 3).** "Hardware" quer dizer drivers e firmware. A
   emenda MINOR da constituição (2.2.0) diz isso nesta branch. Ver D3.

## User Scenarios & Testing *(mandatory)*

### Como cada coisa se prova

Toda rodada abre com `lab/perf begin` e fecha com `lab/perf end --result …`, na tela de 1080 e na de
1,25. As evidências abaixo saem da `check-019`, nova, no lab privado.

| O quê | Como se prova | Teste do dono, depois de instalar |
|---|---|---|
| Som | **De verdade na VM**, com 2 null sinks e uma fonte: `settings dump` e `wpctl` | Saídas reais (alto-falante, fone, HDMI), microfone real |
| Teclado | **De verdade na VM**: `settings dump` e `hyprctl getoption -j` | A sensação da repetição, o Caps Lock físico |
| Interface scale, Top bar height | **De verdade na VM**: screenshots e `settings dump` | Olhar no notebook |
| Display (leitura) | **De verdade na VM**: `settings dump` contra `hyprctl monitors -j` | Hz real do painel |
| Bateria, luz de tela | **Só por fixture.** O estado sem o recurso é real na VM | Bateria, carregador e luz de tela de verdade |

### User Story 1 - A base comum (Onda 0, Priority: P1)

Quem abre o SYSTEM vê o que o sistema diz, e uma linha que o sistema não tem como atender fica
apagada e diz por quê. Essa base vem antes do paralelo (princípio VI), num agente só: som, leituras,
teclado e aparência se apoiam nela.

**Why this priority**: Sem ela, cada frente inventa o próprio jeito de ligar uma linha ao sistema.

**Independent Test**: Com o catálogo de teste, as checks antigas passam sem mudar o que testam; com
o catálogo do produto, uma opção de prova ligada a um provedor lê, muda e fica indisponível.

**Acceptance Scenarios**:

1. **Given** uma linha `sys.*` com o provedor disponível, **When** o valor muda no sistema, **Then**
   a linha mostra o novo valor. **Evidência:** `settings dump`, antes e depois.
2. **Given** um provedor com `available` falso, **When** o foco chega na linha, **Then** ela fica
   apagada, continua focável, ← → e Enter não fazem nada, e o card diz o motivo. **Evidência:**
   screenshot e `settings dump` (`dimmed` e o motivo).
3. **Given** um `settings.json` com `settings.sound.volume` e `settings.display.brightness` salvos pela
   versão anterior, **When** o shell sobe duas vezes, **Then** esses valores não são aplicados e somem
   do arquivo. **Evidência:** `jq` no `settings.json` antes e depois das duas subidas.
4. **Given** a linha Sound › Volume, **When** roda `settings reset`, **Then** o volume do sistema não
   muda. **Evidência:** `wpctl get-volume` antes e depois.
5. **Given** o fixture `settings` apontando pro showroom, **When** rodam a check-003, a 008 e a 013,
   **Then** elas passam testando a mesma mecânica (escolha, toggle, `needs`, ação ocupada).
   **Evidência:** `results.txt` das três e o relatório do `lab/perf`.

---

### User Story 2 - Som (Onda 1A, Priority: P1)

A pessoa escolhe a saída, muda o volume, o mudo e o microfone no menu. As teclas e o menu mostram
sempre o mesmo número, porque os dois leem o sistema.

**Why this priority**: É o que mais se usa, e o Pipewire já é dependência.

**Independent Test**: Na VM, com 2 null sinks, trocar a saída e o volume pelo teclado e conferir no
`wpctl`.

**Acceptance Scenarios**:

1. **Given** 2 null sinks, **When** a pessoa escolhe o outro em Output, **Then** ele vira a saída padrão.
   **Evidência:** `wpctl status` e `settings dump`.
2. **Given** Volume em foco, **When** → é apertado, **Then** o volume sobe 2 e a barra acompanha, sem
   OSD. **Evidência:** `wpctl get-volume`, screenshot da barra, teste `osd-quiet` da check-008.
3. **Given** o menu aberto em Volume, **When** `wpctl set-volume` muda de fora, **Then** a linha segue em
   até 1 s. **Evidência:** `settings dump` com o tempo medido.
4. **Given** a linha Mute, **When** é ligada, **Then** a saída padrão fica muda, a barra mostra MUTE e a
   linha Volume continua mostrando o nível. **Evidência:** `wpctl get-volume` (`[MUTED]`), screenshot.
5. **Given** uma fonte na VM, **When** Microphone muda, **Then** o nível da fonte padrão muda.
   **Evidência:** `wpctl get-volume @DEFAULT_AUDIO_SOURCE@`.
6. **Given** a saída escolhida é removida (`pw-cli destroy` no null sink), **When** a lista está aberta,
   **Then** a lista perde o item, o foco cai num item que existe e o log fica limpo. **Evidência:**
   screenshot, `settings dump`, log do QML.
7. **Given** nenhum sink, **When** a categoria abre, **Then** Output, Volume e Mute ficam apagadas com o
   motivo. **Evidência:** screenshot e `settings dump`.
8. **Given** a outra saída escolhida em Output, **When** a VM reinicia, **Then** ela continua a saída padrão, e
   o `settings.json` não tem a escolha. **Evidência:** `wpctl status` antes e depois, `jq` no `settings.json`.
   Se a saída não ficar, a decisão D4 volta pro dono.

---

### User Story 3 - Leituras: bateria, luz de tela, Display (Onda 1B, Priority: P1)

Nenhum número inventado sobre a máquina: bateria, luz e tela mostram o que é verdade, ou dizem que
a máquina não tem.

**Why this priority**: É a informação falsa mais visível da D-01.

**Independent Test**: Na VM sem fixture, Battery e Brightness apagadas com o motivo e Display igual ao
`hyprctl`. Com fixture, os valores do fixture.

**Acceptance Scenarios**:

1. **Given** a VM sem bateria, **When** Power abre, **Then** Battery está apagada, com "No battery on this
   machine.", e a barra continua sem BAT. **Evidência:** screenshot e `settings dump`.
2. **Given** o fixture `battery` com `{percent: 64, charging: false}` e depois `{percent: 87, charging:
   true}`, **When** Power abre, **Then** a linha diz `64%` e depois `87% · charging`. **Evidência:**
   screenshots do fixture. O hardware real é teste do dono.
3. **Given** a VM sem luz de tela, **When** Display abre, **Then** Brightness está apagada com "No backlight
   on this screen.". **Evidência:** screenshot e `settings dump`.
4. **Given** o fixture `brightness` com 40, **When** → é apertado, **Then** a linha vai a 45, em memória, sem
   rodar nada no sistema. **Evidência:** `settings dump` do fixture. A escrita real é teste do dono.
5. **Given** o perfil `hidpi` e o de 1080 da VM, **When** Display abre, **Then** Resolution, Refresh rate e
   Scale batem com o monitor em foco no `hyprctl monitors -j`, e ← → não mudam nada. **Evidência:**
   `settings dump` comparado com o `hyprctl`, screenshot, nas duas telas.
6. **Given** a escala muda por `hyprctl eval` com o menu aberto, **When** passa 1 s, **Then** a linha Scale
   mostra o valor novo. **Evidência:** `settings dump`.
7. **Given** duas telas (uma saída `headless` a mais na VM), **When** o foco passa pra outra, **Then** as três
   linhas mostram os valores dela, e o card, o nome dela. **Evidência:** `settings dump` comparado com o
   `hyprctl monitors -j`, screenshot.

---

### User Story 4 - Teclado (Onda 1C, Priority: P2)

A pessoa ajusta a repetição e o Caps Lock no menu, a mudança vale na hora, sobrevive a reload e a
login, e o arquivo dela não é tocado. Keyboard › Shortcuts mostra os atalhos de verdade.

**Why this priority**: Depende só do Hyprland e repete um padrão aprovado, mas pesa menos que os dados
falsos sobre a máquina.

**Independent Test**: Na VM, mudar Repeat delay, dar `hyprctl reload` e conferir `getoption`.

**Acceptance Scenarios**:

1. **Given** Repeat delay em 400, **When** a pessoa escolhe 300, **Then** `input:repeat_delay` vira 300 na
   hora. **Evidência:** `hyprctl getoption -j input:repeat_delay`.
2. **Given** o valor mudado, **When** roda `hyprctl reload` e, depois, o shell reinicia, **Then** o valor
   escolhido volta nos dois casos. **Evidência:** `getoption` depois de cada um, `settings.json`.
3. **Given** a config com `kb_options = "grp:alt_shift_toggle"`, **When** Caps Lock vira Escape, **Then**
   `input:kb_options` tem `grp:alt_shift_toggle,caps:escape`; **When** volta a Caps Lock, **Then** só
   sobra `grp:alt_shift_toggle`. **Evidência:** `getoption -j input:kb_options`.
4. **Given** a config com `repeat_delay = 250`, sem nada salvo, **When** Keyboard abre, **Then** a linha
   mostra `250 ms`, nada é aplicado e nada é salvo. **Evidência:** `settings dump`, `settings.json`.
5. **Given** Repeat rate, **When** o slider desce até o fim, **Then** para no mínimo e a tecla continua
   repetindo. **Evidência:** `getoption -j input:repeat_rate`.
6. **Given** `YORHA_MOD = "ALT"` na VM, **When** Shortcuts abre, **Then** a lista mostra ALT+Esc, ALT+I,
   ALT+T, ALT+N, ALT+CTRL+N e as teclas de volume e de luz, e nada falso: é a mesma lista do
   `yorha-shell.lua`. **Evidência:** screenshot e a comparação feita pela check-019.
7. **Given** a check-019 inteira rodada, **When** ela termina, **Then** o `hyprland.lua` da VM está igual.
   **Evidência:** `sha256sum` antes e depois.
8. **Given** a config com `repeat_delay = 250` e `repeat_rate = 30`, **When** a pessoa muda só Repeat delay pra
   300 e roda `hyprctl reload`, **Then** `repeat_delay` fica em 300 e `repeat_rate` fica em 30, o do arquivo.
   **Evidência:** `getoption -j` das duas, depois do reload.

---

### User Story 5 - Aparência (Onda 1D, Priority: P2)

A pessoa muda o tamanho da UI e a altura da barra pelo menu, e vê na hora, sem editar `shell.json`.

**Why this priority**: Não depende de nada, mas mexe no layout inteiro e é a frente com mais risco
visual.

**Independent Test**: Na VM, trocar as duas opções e olhar o menu e a barra em 1080 e em 1,25.

**Acceptance Scenarios**:

1. **Given** Interface scale, **When** cada valor (90, 100, 110, 125%) é escolhido, **Then** a UI muda na
   hora, o foco fica na linha e nenhuma coluna do menu passa da área dela. **Evidência:** screenshot de
   cada valor, nas duas telas, e `settings dump` (`geometry`).
2. **Given** Top bar height, **When** cada valor (40, 50, 68, 80 px) é escolhido, **Then** a barra muda, as
   janelas se ajustam e nada é cortado. **Evidência:** screenshots e `hyprctl layers`.
3. **Given** as combinações 125% com 40 px, 125% com 80 px e 90% com 40 px, **When** a barra e o menu são
   abertos, **Then** nada é cortado e nada estoura a tela. **Evidência:** screenshots, nas duas telas.
4. **Given** um valor escolhido, **When** o shell reinicia, **Then** ele continua. **Evidência:**
   `settings.json` e `settings dump`.
5. **Given** um `shell.json` com `barHeight: 72` e `uiScale: 1.2`, nada salvo, **When** Appearance abre,
   **Then** a linha mostra `72 px` e `120%`, a UI usa esses valores e o log não reclama. **Evidência:**
   screenshot, `settings dump`, log do QML.
6. **Given** os dois valores salvos, **When** roda `settings reset`, **Then** voltam ao do `shell.json`.
   **Evidência:** `settings dump`.

---

### Edge Cases

- **Volume acima de 100%:** as teclas sobem até 150% (`wpctl -l 1.5`). O slider mostra o topo e o card, o
  número real. O volume só muda quando a pessoa mexe na linha.
- **Segurar a tecla no slider:** a última posição vence, e as mudanças não se acumulam na fila.
- **A escrita falhou** (`brightnessctl` recusou, `hyprctl eval` respondeu erro): a linha volta ao valor real
  e o card diz o que houve.
- **Dois aparelhos de luz de tela:** a leitura e a escrita falam do mesmo.
- **Só uma saída:** a linha Output mostra o nome dela, e ← → não fazem nada.
- **Nomes longos de aparelho:** o texto corre em letreiro (`ScrollingLabel`), como nos outros menus.
- **Mais de 3 saídas:** Enter abre a janelinha de escolha, que rola por linhas inteiras.
- **Microfone mudo pela tecla:** Microphone mostra o nível, e o card diz que está mudo.
- **`kb_options` com outra regra pro Caps Lock** (`caps:swapescape`, `ctrl:swapcaps`): a linha mostra `Custom`.
  Escolher um valor troca essa regra; sem escolha, nada muda.
- **A pessoa mudou a própria config e deu reload, sem nada salvo no menu:** a linha segue o novo valor.
- **Teclado com regra própria na config (`hl.device`):** o valor geral não vale pra ele. Fica como está.
- **Saídas que aparecem em outro perfil da placa de som:** Output lista só as que o PipeWire expõe; trocar
  o perfil da placa fica fora.
- **Tela em foco muda com o menu aberto:** Display segue a tela em foco, e o card troca o nome (D5).
- **A pessoa edita a config depois de mudar a linha no menu:** o valor do menu continua vencendo (D2).

## Requirements *(mandatory)*

### Functional Requirements

**Onda 0: base comum (antes do paralelo)**

- **FR-001**: `SettingsModel` MUST aceitar uma terceira fonte viva, além de `Settings` e `NotifyPrefs`:
  `"setting": "sys.<provedor>.<chave>"`, atendida por um provedor com `levelsOf`, `levelOf`, `setLevel`,
  `available` e `reason`.
- **FR-002**: Uma linha `sys.*` MUST mostrar só o que o provedor diz, nunca o `value` do catálogo nem um
  valor salvo. Se a escrita falhar, a linha volta ao valor real e o card diz o que houve.
- **FR-003**: A lista de valores de uma linha `sys.*` MAY ser dinâmica, pelo caminho do `resolve()` já usado
  no `notify.monitor`. O que for salvo de uma lista dessas MUST ser um id estável, nunca um índice.
- **FR-004**: Uma linha com `available` falso MUST ficar apagada, focável e sem efeito, com o motivo no card,
  no mesmo visual do `needs`. Esse estado é só pro que falta na máquina da pessoa (sem bateria, sem luz de
  tela, ferramenta ausente), nunca pra uma opção que o produto ainda não fez. O `settings dump` MUST trazer essas linhas em `dimmed` e o motivo. Os textos
  ficam em inglês, em `Strings.qml`.
- **FR-005**: O card de uma linha `sys.*` MUST mostrar só NOW. A linha DEFAULT não existe pra um valor que é
  do sistema.
- **FR-006**: `settings reset` MUST NOT mudar volume, mudo, microfone, saída nem luz de tela. Ele limpa o que
  o produto guarda (teclado e aparência).
- **FR-007**: Na subida, os valores `settings.<cat>.<opt>` de linhas que viraram reais MUST ser ignorados e
  removidos, de forma idempotente (princípio III). Um valor falso antigo nunca é aplicado ao sistema.
- **FR-008**: MUST existir `fixtures/settings-showroom.json`, cópia do catálogo de hoje. A check-003, a 008 e
  a 013 passam a usá-lo pelo domínio de fixture `settings`.
- **FR-009**: O schema de fixtures (`specs/001-yorha-base-hud/contracts/fixtures.schema.json`) MUST ganhar os
  domínios `audioDevices`, `brightness`, `monitors` e `input`. Cada provedor MUST seguir o padrão do
  `Battery.qml`: fixture primeiro, depois o módulo, e nenhum aviso no log quando o serviço falta. Com fixture
  ativo, nada é escrito no sistema. `network`, `bluetooth` e `powerProfile` só entram na onda 3.
- **FR-010**: `specs/003-settings-popup/contracts/settings.schema.json` e a validação do catálogo
  (`problemOf`) MUST aceitar as linhas `sys.*` e o `live` do `settings dump` MUST listá-las.
- **FR-011**: O contrato do provedor (FR-001, FR-003, FR-004) MUST estar pronto e estável antes das frentes
  1A a 1D (princípio VI).
- **FR-012**: A 0.1.0 MUST sair com as 31 opções reais, feitas na ordem das ondas (D1). Isso inclui as ondas 2
  e 3: as 16 linhas que as ondas 0 e 1 não cobrem e a mudança de Resolution, Refresh rate e Scale. Nenhum valor
  inventado fica no catálogo do produto na release.

**Onda 1A: som**

- **FR-013**: Sound › Output MUST listar as saídas do PipeWire (sem fluxos de aplicativos), pelo nome legível,
  marcar a saída padrão real e, ao escolher, trocá-la. O id é o `node.name`. O produto MUST NOT guardar essa
  escolha: quem guarda é o PipeWire (D4).
- **FR-014**: Sound › Volume MUST ler e mudar o volume da saída padrão, em passos de 2, os mesmos das teclas.
  Com mudo, a linha continua mostrando o nível.
- **FR-015**: Sound › Mute MUST ler e mudar o mudo da saída padrão. O texto da linha MUST deixar de dizer
  "every output".
- **FR-016**: Sound › Microphone MUST ler e mudar o nível da fonte padrão.
- **FR-017**: A saída, o volume, o mudo e o microfone MUST NOT ter cópia salva: ela brigaria com as teclas e com
  o `wpctl`.
- **FR-018**: Uma mudança de fora (teclas, `wpctl`, outro programa) MUST aparecer na linha em até 1 s. A
  supressão do OSD que já existe (`SettingsPage`, 008 FR-029) continua valendo.

**Onda 1B: leituras**

- **FR-019**: Power › Battery MUST mostrar o que o `Battery.qml` lê (`64%`, `87% · charging`). Sem bateria ou
  sem UPower, fica apagada com o motivo certo.
- **FR-020**: Display › Brightness MUST ler a % real, que o `Osd.qml` passa a expor, e seguir mudanças de
  fora em até 1 s. Sem luz de tela, fica apagada com o motivo.
- **FR-021**: Display › Brightness MUST escrever por `brightnessctl`, no mesmo aparelho da leitura. Sem
  `brightnessctl`, a linha mostra o valor e não muda, e o card diz por quê.
- **FR-022**: Pela linha, a luz MUST NOT descer abaixo de 5%, pra tela não apagar por um clique no slider.
- **FR-023**: Até a onda 2, Display › Resolution, Refresh rate e Scale MUST virar informação só de leitura, com os valores do
  `hyprctl monitors -j` (o `HyprlandBackend` passa a guardar `width`, `height` e `refreshRate`). Seguem o
  compositor, sem reiniciar o shell. Mostram a tela em foco, com o nome dela no card, e seguem o foco (D5).

**Onda 1C: teclado**

- **FR-024**: Keyboard › Repeat delay, Repeat rate e Caps Lock MUST ler o valor do compositor e, ao mudar,
  aplicar na hora, pelo mesmo caminho do `setKeyboardLayouts`, e salvar na pasta de estado do produto.
- **FR-025**: Enquanto a pessoa não mudar a linha, o produto MUST NOT aplicar nem salvar nada. Um valor da
  config que não está na lista aparece como está (`250 ms`).
- **FR-026**: O valor salvo MUST voltar na subida do shell e depois de cada reload do Hyprland, como os layouts
  da 013. Uma linha que a pessoa mudou vence a config dela (D2).
- **FR-027**: Caps Lock MUST mexer só na parte do Caps de `kb_options`, somando ao que a pessoa já tem.
- **FR-028**: Repeat rate MUST mostrar repetições por segundo e não chegar a 0, porque 0 desliga a repetição.
  O mínimo é 5, o passo do slider.
- **FR-029**: `settings reset` MUST limpar os valores salvos do teclado sem dar reload. O da config da pessoa
  volta no próximo reload ou login, e a linha mostra sempre o valor real.
- **FR-030**: Keyboard › Shortcuts MUST abrir a lista dos atalhos do `yorha-shell.lua`, só leitura, com o
  `YORHA_MOD` em uso. Se o compositor não disser o modificador, a lista usa SUPER e avisa. A descrição da linha
  MUST dizer que são os atalhos do produto.
- **FR-031**: Num compositor que não aplica essas opções, as linhas MUST ficar apagadas com o motivo, como a
  nota de `keyboardLayoutsNote`.

**Onda 1D: aparência**

- **FR-032**: Appearance › Interface scale e Top bar height MUST aplicar na hora e salvar em `shell.uiScale` e
  `shell.barHeight`, com o valor salvo vencendo o `shell.json`, no molde das opções da U13.
- **FR-033**: Um `uiScale` ou `barHeight` do `shell.json` válido na faixa de hoje (0,5–3,0; 28–96) e fora da
  lista do menu MUST continuar valendo e aparecer na linha. O molde da U13 descartaria esse valor; aqui não pode.
- **FR-034**: Em todos os valores, nas duas telas, a barra e os menus MUST caber e nada fica cortado.

**Regras que continuam (ondas 0 e 1)**

- **FR-035**: Nenhum som de digitação, nem como opção. As linhas usam só os sons que o SYSTEM já toca.
- **FR-036**: Toda coluna e toda lista novas (saídas, atalhos) MUST caber na área e rolar por linhas inteiras,
  também na roda do mouse, sem invadir o rodapé.
- **FR-037**: Toda linha fina nova MUST usar `Tokens.vline`.
- **FR-038**: Nenhuma ferramenta nova em `system/deps` nesta spec. Tudo que as ondas 0 e 1 usam já é dependência
  ou já é opcional, com a ressalva do UPower em Assumptions.

### Ondas 2 e 3: só escopo e dependência

As duas ondas entram na 0.1.0 (D1), depois da onda 1. Os requisitos delas não estão aqui: cada item terá os
seus quando chegar a vez, e cada ferramenta da onda 3 é conversada com o dono, uma por vez.

**Onda 2 (depende de outra frente):**

| Opções | Depende de |
|---|---|
| Mudar Resolution, Refresh rate e Scale | Spec 018 (aba de telas, com a confirmação que volta sozinha), que espera as decisões do dono. A proposta dela tira as três do Display |
| Appearance › Cursor size | O cursor vir no instalador (D-21) |
| Appearance › Language | Fase U5b: `Strings.qml` e o catálogo por idioma, pt-BR primeiro |

**Onda 3 (conversa com o dono, uma ferramenta por vez, nesta ordem):**

| Opções | Depende de | Tamanho |
|---|---|---|
| Power › Profile | power-profiles-daemon | S |
| Power › Screen off after, Suspend after | IdleMonitor (embutido) e logind; suspender sem trancar liga com a tela de bloqueio (D-03, 017) | S–M |
| Display › Night light | hyprsunset, que ninguém tem instalado | M |
| Power › Lid closed | Inibidor do logind e bind `switch:` do Hyprland; só notebook | M |
| Network › Wi-Fi, Network, Wired, VPN | NetworkManager (Networking). Pede senha na tela; a VPN só existe pelo `nmcli` | L |
| Bluetooth › tudo | bluez (Bluetooth); a lista de aparelhos muda em tempo real | L |
| Network › Airplane mode | Network e Bluetooth prontos | S |

Cada ferramenta aceita entra depois como opcional em `system/deps`, e o instalador pergunta antes de
instalar (`lib/yorha/deps.sh`). Rede e Bluetooth já estão na emenda do princípio II (D3).

### Key Entities

- **Provedor do sistema**: fonte viva de uma família de linhas (`audio`, `power`, `display`, `input`). Diz os
  valores, o valor atual, se está disponível e o motivo.
- **Linha indisponível**: linha `sys.*` com `available` falso; tem um motivo e nenhum efeito.
- **Aparelho**: item de lista dinâmica, com id estável e nome legível.
- **Catálogo do produto / catálogo de teste**: `settings-default.json` e `settings-showroom.json`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Nas 15 opções das ondas 0 e 1, o valor mostrado é igual ao do sistema em 100% das comparações da
  check-019, ou a linha está apagada com o motivo. **Evidência:** `results.txt` da check-019.
- **SC-002**: Ao fim da onda 1, na VM sem fixture, o `settings dump` não traz `87% · charging` nem um valor de
  Display, som ou teclado que o sistema não confirma. **Evidência:** a busca feita pela check-019 no dump.
- **SC-003**: Uma mudança feita fora do menu aparece na linha em até 1 s. **Evidência:** tempo medido na check-019.
- **SC-004**: Depois de uma rodada inteira, o `settings.json` não tem volume, mudo, microfone nem luz de tela, e o
  `hyprland.lua` da VM tem o mesmo `sha256sum`. **Evidência:** `jq` e `sha256sum` na check-019.
- **SC-005**: A check-003, 004, 007, 008, 013, 014, 015 e 019 passam, em 1080 e em 1,25, com o log do QML sem WARN
  nem ERROR, cada rodada medida. **Evidência:** `results.txt`, o log e o resumo do relatório do `lab/perf`.
- **SC-006**: O dono vê o antes e o depois de cada categoria mudada do SYSTEM, no Chrome dele, e aprova.
  **Evidência:** os screenshots do lab e a aprovação.
- **SC-007**: A lista de testes de hardware (tabela de "Como cada coisa se prova") fica marcada como teste do dono,
  e nenhuma entrega da onda 1 se diz pronta nesses itens sem ele. **Evidência:** a lista na entrega da onda 1.
- **SC-008**: Antes da 0.1.0, com as ondas 2 e 3 prontas, as 31 opções são reais, e o `settings dump` do catálogo do
  produto na VM sem fixture não traz `home-5G`, `K2 Keyboard` nem outro valor inventado. **Evidência:** a busca no
  dump, feita na ref da release, e o resumo do relatório do `lab/perf`.

## Assumptions

- A VM só tem rede por cabo, áudio (null sink) e Hyprland. Não tem Wi-Fi, Bluetooth, bateria, tampa nem luz de tela.
- Battery, quando não há bateria, fica apagada com o motivo, a regra geral da onda 0. O plano dizia "some ou apaga".
- A linha Battery continua visível, e a barra segue escondendo o BAT como hoje.
- O UPower é usado hoje pelo `Battery.qml`, mas **não está em `system/deps`**. Num notebook sem ele, a linha só diz
  que falta. Esta spec não acrescenta; a decisão fica pro plano ou pra conversa da onda 3.
- Enquanto as ondas 2 e 3 não terminam, o catálogo da branch ainda tem as linhas falsas delas. Isso não sai em release
  (FR-012, SC-008).
- Volume, luz e saída mudados pelo menu são do sistema e ficam como estão se a pessoa desinstalar. O teclado volta
  ao da config no login seguinte, porque nada foi escrito na config dela.
- As chamadas `hyprctl eval`, `getoption` e os campos do `monitors -j` valem na 0.56 e na 0.57; o plano confere isso.
- O `YORHA_MOD` é uma variável do Lua e o shell não a enxerga hoje. O plano escolhe como perguntar ao compositor.
- O plano técnico pode mudar nomes de chaves; os comportamentos e as evidências desta spec, não.

## Decisões do dono (03.11)

**D1. As linhas que faltam: a 0.1.0 espera as 31.** "a gente faz a 0.1.0 com tudo isso... sem problema. o importante é
implementar na ordem dessas atividades ai." A release inclui as ondas 2 (a 018, o cursor no instalador, Language) e 3.
Não há estado intermediário de "ainda não feito" na release (FR-012, SC-008).

**D2. No teclado, o menu vence.** "o nosso prevalece. a pessoa edita depois se quiser". Uma linha que a pessoa mudou no
menu vence a config e volta depois de um reload; uma linha que ela não mexeu fica com o valor do arquivo (FR-025, FR-026).

**D3. "Hardware" quer dizer drivers e firmware.** O produto pode ler e mudar, em tempo de execução, o que o sistema já
oferece (som, luz de tela, teclado, rede, Bluetooth), sem instalar driver nem editar arquivo do sistema. A constituição
2.2.0 diz isso nesta branch. A pergunta da 018, sobre quem vence nas regras de monitor, continua aberta lá.

**D4. Sound › Output não é guardado pelo produto.** O PipeWire guarda a saída padrão (FR-013, FR-017). A VM confere
reiniciando; se a saída não ficar, a decisão volta pro dono (User Story 2, cenário 8).

**D5. Display mostra a tela em foco**, com o nome dela no card, e segue o foco (FR-023).

### Acrescentados, a aprovar

O dono ainda não viu estes quatro requisitos, que não vieram do plano:

- **FR-006**: `settings reset` não muda volume, mudo, microfone, saída nem luz de tela.
- **FR-007**: valores falsos salvos pela versão anterior são removidos na subida, sem nunca serem aplicados.
- **FR-022**: pela linha, a luz de tela não desce abaixo de 5%.
- **FR-028**: Repeat rate tem mínimo de 5, porque 0 desliga a repetição.
