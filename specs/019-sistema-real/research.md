# Research: SYSTEM de verdade

Leitura do código em `670a99f` e do código-fonte do Hyprland nas tags `v0.56.2` e `v0.57.1`
(`src/config/lua/ConfigManager.cpp`, `bindings/`, `src/debug/HyprCtl.cpp`). Ler a fonte não prova nada no
sentido do princípio IV: o que está marcado **prova** só vale depois da T003, na VM.

## R1. Onde se lê a base do arquivo (FR-026, FR-039)

**Decisão:** pelo jeito da spec. O backend lê `hyprctl getoption -j` logo depois do evento `configreloaded`, e na
primeira subida do shell numa sessão, sempre antes de reaplicar. A sessão é o `HYPRLAND_INSTANCE_SIGNATURE`.

**O que a fonte diz (nas duas tags):**
- `reload()` zera todas as opções (`v.second->reset()`) e roda o arquivo de novo, e só então manda `configreloaded`
  (`postConfigReload`). Uma chave que o arquivo não tem volta ao padrão do Hyprland, então o valor lido depois do
  evento é o do arquivo.
- `hl.config` dentro do `eval` só agenda um `scheduleRefresh`. Não passa pelo `postConfigReload`, então a escrita do
  produto não gera o evento.
- Salvar o arquivo já recarrega sozinho: `Config::watcher()->setOnChange` chama `reload()`, a não ser com
  `misc:disable_autoreload`. O dono não precisa dar `hyprctl reload` pra edição contar.
- **Erro de sintaxe:** `phase1Load` falha antes de zerar, o evento sai mesmo assim e os valores ficam como estavam.
  **Erro em tempo de execução:** os valores já foram zerados, e o arquivo rodou só até o erro. Nos dois casos,
  `hyprctl configerrors` tem conteúdo, e a FR-042 manda não comparar.

**A prova (T003, primeira tarefa de teste, antes de qualquer código do shell):** `lab/019/prova-base` roda sem o shell,
em `hypr-iso` (0.56.2) e `hypr-057` (0.57.0), e registra cada item em `sondagem.md`:

| Item | O que confere | Se falhar, o que acontece com o desenho |
|---|---|---|
| P1 | Chave **ausente** do arquivo: `eval` põe 50, reload volta ao padrão | O valor do `eval` sobrevive e parece edição. A comparação passa a ignorar um valor lido igual ao que o produto aplicou. Fica um limite novo: a pessoa apagar a chave não é percebida |
| P2 | Chave **no arquivo**: `eval` põe 50, reload volta ao do arquivo, nas 4 opções (`repeat_delay`, `repeat_rate`, `kb_options`, `kb_layout`) | Sem base por `getoption`. Candidato: a seção "alternativa" abaixo |
| P3 | `eval` não gera `configreloaded`, ouvindo o socket2 por 3 s | Um contador de escritas próprias ignora o evento seguinte, e a corrida com um reload de verdade vira limite conhecido |
| P4 | Salvar o arquivo gera `configreloaded`, e quantos | Vários eventos: o backend junta numa leitura só. Sem evento: só `hyprctl reload` conta, e o limite vai pro dono |
| P5 | Ler logo depois do evento dá o valor do arquivo, em 20 rodadas | Valor velho: espera curta, medida, antes de ler |
| P6 | Erro de sintaxe e erro em tempo de execução: `configerrors` tem conteúdo; o que os valores viram | `configerrors` vazio num caso: esse caso compararia e esqueceria, e a FR-042 volta pro dono |
| P7 | A assinatura muda num novo login e não muda com `pkill -x qs` | Procurar outro id de sessão no próprio Hyprland |
| P8 | `hyprctl repl 'return YORHA_MOD'` (R2) | Ver R2 |
| P9 | Formato do `getoption -j` nas 4 opções e campos `width`, `height`, `refreshRate`, `scale`, `focused` do `monitors -j` | Ajustar o parser; não muda o desenho |

**Resultado (03.11, `sondagem.md`):** P1 a P9 passam em 0.56.2 e 0.57.0, e o portão passou. A prova achou uma trava do Hyprland, e o backend chegou a esperar 300 ms antes de ler depois do `configreloaded`.
**Corrigido em 06.11:** a trava é do Hyprland, acontece nas duas versões e sem shell nenhum, e a espera, que não tinha benefício mostrado, saiu (`sondagem.md`). P5 é o que vale: o valor lido logo depois do evento é o do arquivo.

**Portão:** P1 a P7 são a prova da D2. Se P2 ou P3 falharem de um jeito que a coluna da direita não resolve, ou P1 ou P6
falharem, a etapa 0 para, e o resultado vai pro dono antes de qualquer frente: a D2 diz que a regra não muda sozinha.

**Alternativa, se a leitura depois do reload não servir:** o `yorha-shell.lua` já é incluído no topo do `hyprland.lua`. Ele
poderia embrulhar `hl.config` e registrar o que o arquivo pede, sem editar arquivo nenhum da pessoa. Pega só o que vem
depois do include, e muda a tabela `hl` da pessoa. Por isso não é a escolha de saída.

**Alternativas rejeitadas:** interpretar o `hyprland.lua` por fora (é um programa em Lua, com `require` e condições);
hash do arquivo (diz que algo mudou, não qual chave, e uma edição em outra chave apagaria tudo, contra a US4.8).

**Base do `shell.json` (FR-041):** é o `Settings.user`, cru, antes do merge com o `defaults.json`. Hoje o `parse` devolve
`{}` em JSON inválido e `userFile.loaded` não separa "não existe" de "sem permissão". O `FileView` do Quickshell 0.3.2 dá
`loadFailed(error)` com `FileNotFound`, `PermissionDenied` e `NotAFile`: só `FileNotFound` conta como "arquivo ausente"
(edição). Um JSON que não é objeto conta como ilegível.

**Primeira vez sem base (update vindo de antes da 019, e primeira instalação):** a base é só gravada, nada é esquecido
(FR-043). O limite da spec sobre `eval` antes da primeira subida continua valendo.

## R2. Como o `YORHA_MOD` chega ao shell (FR-030)

**Decisão:** `hyprctl repl 'return YORHA_MOD'`, no backend. O comando `repl` existe na `v0.56.2` e na fonte atual. Ele
devolve o valor da variável global, que vive no estado Lua da sessão e volta depois de cada reload, porque o arquivo roda
de novo. `nil` quer dizer SUPER, o padrão do próprio `yorha-shell.lua`, sem aviso. Falha do comando, ou uma saída que não
casa com `^[A-Z0-9_ +]+$`: a lista usa SUPER e o card avisa (P8 prova).

**Alternativas:** `hyprctl binds -j` com o `modmask` (com `capture`, o bind vira uma função Lua, e o bind precisaria de uma
`description` só pra ser achado; fica como reserva se P8 falhar na 0.57); passar o modificador no ambiente do `yorha shell
start` (fica velho quando a pessoa muda a variável; um `yorha-shell.lua` que escreve arquivo vai contra o comentário "It
writes nothing").

**Efeito no lab:** o `lab/guest/hyprland.lua` tem `local mod = "ALT"` e nunca define `YORHA_MOD`. A `lab-019` passa a ter
`YORHA_MOD = "ALT"` e `local mod = YORHA_MOD`, senão a US4.6 não testa nada (T001).

**A lista de atalhos:** fica em `HyprlandBackend.shortcuts`, como dado do compositor (FR-044). O shell não interpreta o
Lua. A `check-019` extrai os `hl.bind` de `system/hypr/yorha-shell.lua` e compara com a lista (US4.6), então uma tecla nova
sem atualizar a lista derruba o teste.

## R3. Níveis dos sliders e das escolhas

| Linha | Tipo | Nível guardado | Texto | Faixa e passo | Valor fora da lista |
|---|---|---|---|---|---|
| Volume | slider | % inteiro de `audio.volume × 100` | `64` | 0–100, passo 2 (FR-014) | Acima de 100 (até 150, pelas teclas): a barra fica no topo e o card mostra o número real. ← desce 2 a partir do real; → não faz nada acima de 100 |
| Microphone | slider | % inteiro | `80` | 0–100, passo 5 (o do catálogo) | Igual a Volume |
| Mute | toggle | `audio.muted` | ON/OFF | — | — |
| Output | choice | `node.name` (FR-013) | `description`, ou `nickname`, ou `name` | a lista do PipeWire | Uma saída só: um valor, ← → sem efeito |
| Brightness | slider | % inteiro de `brightness/max` | `70` | 5–100, passo 5 (FR-022) | Abaixo de 5 (pela tecla): mostra o real, ← não faz nada |
| Repeat delay | choice | ms inteiro | `300 ms` | 200, 300, 400, 600 | O da config entra na lista, em ordem (`250 ms`), enquanto for o valor em uso (FR-025) |
| Repeat rate | slider | repetições/s, inteiro | `50` | 5–100, passo 5 (FR-028) | Acima de 100: barra no topo, card com o real. Fora do passo (25, 23): anda a partir do real |
| Caps Lock | choice | `""`, `caps:escape`, `ctrl:nocaps` | Caps Lock, Escape, Control | — | Outra regra do Caps: `Custom`, que só existe enquanto for o valor em uso; escolher `Custom` não faz nada |
| Interface scale | choice | `0.9`, `1`, `1.1`, `1.25` | `110%` | — | O do `shell.json` entra na lista, em ordem (`120%`, FR-033) |
| Top bar height | choice | `40`, `50`, `68`, `80` | `68 px` | — | Igual (`72 px`) |

**Parte do Caps (FR-027):** uma entrada de `kb_options` é da parte do Caps se casa com
`^(caps:.+|ctrl:nocaps|ctrl:swapcaps.*)$`. `grp:caps_toggle` fica de fora, porque é a tecla de trocar layout da pessoa, e a
linha não mexe nele. A soma põe as entradas da pessoa primeiro: `grp:alt_shift_toggle,caps:escape` (US4.3).

**Por que Control é `ctrl:nocaps`:** a US4.10 usa essa regra como exemplo de edição da pessoa. Ela é a forma comum.

**Por que passo 2 no volume e 5 no microfone:** a FR-014 pede o passo das teclas só pro volume, e a FR-016 não pede passo.
O microfone fica com o do catálogo.

**Segurar a tecla (edge case):** o provedor guarda a posição pedida por até 300 ms, porque o PipeWire e o `hyprctl`
respondem depois. Cada escrita tem um pedido em andamento e o último na espera, no molde do `setAgain` do
`setKeyboardLayouts`.

## R4. A fonte viva `sys.*`

**Decisão:** provedores singleton, um por família, no molde do `NotifyPrefs`, atrás do registro `SysProviders`. Interface
em `contracts/system-provider.md`. `SettingsModel` passa a reconhecer o prefixo `sys.`.

**Por quê:** `SettingsModel` já lê `levelsOf`, `levelOf`, `setLevel` e `labelsOf` do `NotifyPrefs`, e o `resolve()` já faz a
lista dinâmica do `notify.monitor`. A reatividade vem de uma leitura de propriedade dentro da função chamada pela binding,
como em `value()`.

**Interface Scale e Top bar height não são `sys.*`:** a FR-032 pede o molde da U13 (`shell.*`, em `Settings.keys`). Um tipo
novo de chave, `levels`, aceita o valor fora da lista (FR-033). A DEFAULT dessas duas vira o valor configurado
(`configuredOf`), que é para onde o `settings reset` volta, e não mais o índice do catálogo.

**Alternativa rejeitada:** um provedor só, com um `switch` por chave: junta as quatro frentes no mesmo arquivo, e o
princípio VI pede o contrário.

## R5. Como seguir mudanças que não geram evento (SC-003)

`hyprctl eval` não avisa ninguém, e uma troca de modo de tela nem sempre avisa. **Decisão:** com a página do SYSTEM à vista,
`SettingsModel.watching` diz a categoria aberta. O backend relê as opções de teclado ou as telas a cada 1 s só com
`keyboard` ou `display` aberta. Com o menu fechado, nada roda. Som e luz de tela já têm evento (PipeWire e `udevadm monitor`).

## R6. PipeWire

- **Escrita:** `node.audio.volume`, `node.audio.muted`, e `Pipewire.preferredDefaultAudioSink` (é o que grava
  `default.configured.audio.sink`, e o WirePlumber guarda). A US2.8 prova que sobrevive a um reboot; se falhar, a D4 volta
  pro dono.
- **Lista:** `Pipewire.nodes.values`, com `isSink`, sem `isStream`, e `audio` diferente de nulo. Um `PwObjectTracker` no
  provedor segura os nós da lista.
- **Risco, `auto_null`:** sem nenhum aparelho, o WirePlumber pode criar a "Dummy Output". Ela não toca nada. A lista a
  ignora, e sem mais nada a linha diz "No sound output found." (US2.7). A T026 confere se ela aparece na VM.
- **Fonte na VM:** a lição da 008 vale: o source nulo tem que ser `Audio/Source`, senão o Quickshell não dá `audio` a ele.
- **A segunda saída na VM:** o `provision-step notify` cria um sink só; `lab/019/audio-sinks` acrescenta o outro.

## R7. Luz de tela

`Osd.qml` já acha o aparelho e relê por `udevadm`. Ele passa a expor `brightnessPercent` e `backlightDevice`, e lê também
na subida. `SysDisplay` escreve com `brightnessctl --device=<nome> set <n>%`, o mesmo aparelho. A ferramenta é procurada com
`command -v` uma vez na subida. Na VM, só o fixture exercita esse caminho; o de verdade é teste do dono.

## R8. UPower

O `Battery.upowerInstalled` já separa os dois casos. A VM de base não tem UPower: a `check-019` confere primeiro "UPower is
not installed.", depois instala o pacote na camada `t-*` e confere "No battery on this machine." (US3.1). `system/deps` não
muda (FR-038). Se ele entra como opcional, fica pra conversa da etapa 3.

## R9. O que já está pronto

A busca por `hyprctl` e `Quickshell.Hyprland` fora de `shell/services/compositor/` já só acha dois comentários em
`Compositor.qml` (US7.4). `YORHA_COMPOSITOR=niri` já cai no `NullBackend` (`backendFiles[...] ?? none`), com um WARN, que a
`check-019` marca `expected-warn` (FR-046).

## R10. As checks antigas

| Check | O que quebra sem mudar | O que muda |
|---|---|---|
| 003 | A US3 antiga (Night, Scale, Brightness, K2, Battery `87%`) usa o catálogo falso | Roda com `hud-default`, que ganha o domínio `settings` (T004); o roteiro só muda os textos do comentário |
| 004 | `.values == {}` depois do `settings reset`: agora ficam as chaves `fileBase.*` | O filtro ignora `fileBase.*` |
| 007 | No bloco `compositor`, o SYSTEM com `none` perde linhas | Confere `hidden`; `pause-*` ganham `settings` |
| 008 | `notifications-*` abrem SYSTEM com o catálogo do produto | Ganham `settings`. O `osd-quiet` continua sem fixture e passa a testar as linhas reais |
| 013 | O bloco `choice` usa `home-2G`, e `ncat` conta categorias no arquivo | `choice` com fixture; `ncat` conta pelo `settings dump` (uma categoria pode sumir) |

A `check-015` só existe nas branches `lab-015*`; a `lab-019` a herda da `lab-015-correcoes`. Ela não mexe no SYSTEM.
