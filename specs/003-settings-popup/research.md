# Pesquisa (Fase 0): Configurações num popup

Cada item segue o formato: decisão, motivo e o que foi descartado. As APIs foram conferidas nos
`qmltypes` do Quickshell 0.3.1 (`/usr/lib/qt6/qml/Quickshell/…`), a mesma versão da VM. O que já
foi decidido na 001 (escala, fixtures, tokens, adaptador do compositor) vale aqui e não se repete.

## R1. Uma janela só: escurecimento + popup

- **Decisão:** o popup é **um** `PanelWindow` por abertura, na camada `Overlay`, ancorado nas
  quatro bordas do monitor, com `exclusionMode: Ignore` e `color: "transparent"`. Dentro dele:
  - um `Rectangle` na tela inteira com a cor de escurecimento (token, ≈55%);
  - o painel centrado (papel, vinheta própria, sombra chapada), com ≈84% da largura e da altura;
  - um `MouseArea` no escurecimento: clique fora do painel → fecha (FR-004).
- **Motivo:**
  - o clique fora vira um clique na própria janela, sem truques de foco;
  - o escurecimento e o painel aparecem e somem juntos, no mesmo quadro;
  - é o mesmo esquema da galeria da 001, que já funciona.
- **Descartado:**
  - **duas janelas** (fundo escurecido + popup): sincronizar o fade e o foco entre elas é mais
    frágil, e o clique fora cai na janela errada;
  - **`HyprlandFocusGrab`:** é específico do Hyprland e quebraria a regra de que só o
    `Compositor` importa `Quickshell.Hyprland`.

## R2. Teclado exclusivo e volta do foco

- **Decisão:**
  - enquanto aberto, `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` (FR-005);
  - **fechamento em duas fases**, como a galeria: primeiro o popup solta o foco (`None`) e some
    (fechamento imediato, FR-006); 150 ms depois, o `LazyLoader` descarrega a janela. Isso evita o
    aviso `qt.qpa.wayland.textinput` que a 001 achou ao destruir uma superfície com foco;
  - a volta do teclado pra janela anterior é do compositor: ao sair a camada com foco exclusivo, o
    Hyprland devolve o foco à última janela. A evidência é o `hyprctl activewindow -j` antes e
    depois (SC-004).
- **Motivo:** FR-004/FR-005 sem guardar estado de foco na UI.
- **Descartado:** `OnDemand` (o teclado só viria depois de um clique) e reativar a janela anterior
  por dispatch (duplica o que o compositor já faz).

## R3. Abrir no monitor em foco

- **Decisão:**
  - o `Compositor` ganha `focusedMonitor` (nome), lido do `hyprctl monitors -j` (campo
    `focused`), que ele já consulta pra escala. Na abertura, o adaptador refaz a consulta e o
    popup recebe `screen` = a `ShellScreen` com esse nome (`Quickshell.screens`);
  - se o monitor em foco mudar com o popup aberto, ele fica onde abriu (caso de borda);
  - o `dump` traz o nome do monitor.
- **Motivo:**
  - a galeria deixa o compositor escolher (sem `screen`), mas aí o popup não sabe em que monitor
    está, e o `dump` precisa disso;
  - o `Hyprland.focusedMonitor` do Quickshell fica vazio no Hyprland 0.56 com config em Lua
    (mesmo problema do `Hyprland.monitors`, anotado no `Compositor.qml`).
- **Descartado:** um popup por monitor (`Variants`): só um deve abrir.

## R4. Atalho

- **Decisão:**
  - **na VM do laboratório:** `ALT + I`, como os outros atalhos de `lab/guest/hyprland.lua`, que
    usa ALT pra não colidir com os atalhos do host no modo `--window`;
  - **no sistema instalado (S3/U7):** `SUPER + I`, como diz a spec;
  - o atalho chama `qs -p <ui> ipc call settings toggle`.
- **Motivo:** a convenção do laboratório. A FR-001 foi ajustada pra registrar as duas teclas.
- **Descartado:** `GlobalShortcut` do Quickshell (depende de protocolo do Hyprland e fica fora do
  adaptador).

## R5. Escala e layout do popup

- **Decisão:**
  - o conteúdo do painel é desenhado num quadro de **1612 × 908 px do jogo** (84% de 1920 × 1080)
    e escala com `s = altura do painel / 908`, vezes `Settings.uiScale`. Em 1080p, `s ≈ 1`: os
    textos ficam no tamanho do jogo, como no mockup;
  - as colunas do mockup de tela cheia (categorias 400, opções 640, quadro 538) encolhem pra
    caber: **categorias 300, opções 600, quadro 440** (ver [contracts/components.md](contracts/components.md); na implementação
    as categorias e o quadro cederam espaço pras opções, que com 560 cortavam rótulos do mockup como
    "Background motion");
  - linhas finas na grade física, com as funções da 001 (`Tokens.line`, `snap`, `hair`).
- **Motivo:** FR-002 ("≈84%… o layout do mockup aprovado em escala") e FR-008b da 001 (pixels
  lógicos, sem DPI).
- **Descartado:** reaproveitar o layout de 1920 × 1080 e encolher tudo pra 84%. Os textos cairiam
  pra ≈23 px e ficariam pequenos demais no notebook.

## R6. Dados das configurações

- **Decisão:**
  - um serviço novo, `services/SettingsModel.qml` (singleton), carrega o catálogo de
    `shell/fixtures/settings-default.json` (formato em
    [contracts/settings.schema.json](contracts/settings.schema.json));
  - **os valores vivem em memória**, durante a sessão do shell. Fechar e abrir mantém; reiniciar o
    shell volta ao arquivo (FR-018);
  - a fixture ativa pode trocar o catálogo: o domínio `settings` (um caminho) aponta pra outro
    arquivo. É assim que se testam os dados ausentes ou inválidos (caso de borda) e a coluna que
    não cabe;
  - **erro de leitura:** o modelo fica com `error` preenchido, o popup abre com a mensagem no
    quadro e o log registra o motivo.
- **Motivo:**
  - a FR-019 pede os dados num arquivo;
  - o caminho por fixture segue o padrão R4 da 001 (domínio ausente = padrão).
- **Descartado:**
  - ler o catálogo pelo `Settings` (que é a configuração do usuário e não pode ser escrita);
  - gravar os valores num arquivo (fora do escopo, FR-018).

## R7. Dependências e ações

- **Decisão:**
  - uma opção de liga/desliga pode ter `key`; outra pode ter `needs: <key>`. A opção que depende
    fica `dimmed` quando a outra está desligada;
  - a mensagem vem do próprio catálogo (`needs` → texto), não do `Strings`, porque é dado;
  - **ações:** Enter guarda `busy = <id da opção>` e um `Timer` de 2 s limpa. Nada mais acontece.
- **Motivo:** FR-016/FR-017.

## R8. Navegação em duas colunas

- **Decisão:**
  - o estado de foco (coluna, categoria, opção) fica num objeto do popup (`SettingsPage`), não nos
    componentes;
  - as teclas são tratadas num `FocusScope` da página (`Keys.onPressed`), com as regras da FR-010;
  - os componentes só sabem desenhar e avisar cliques e hovers;
  - a `CursorList` ganha:
    - `focused` (sem foco → item atual `selected`, pipa clara e parada);
    - `wrap` (dar a volta nas pontas);
  - a coluna de opções é um composto novo, `OptionList`, que rola junto com o foco quando a lista
    não cabe (caso de borda).
- **Motivo:**
  - a mesma regra de duas colunas vai servir ao seletor de papel de parede (spec 004);
  - deixar o foco num lugar só evita dois componentes brigando pelo teclado.
- **Descartado:** `KeyNavigation` do Qt entre as listas. Não cobre "← volta quando a linha não muda".

## R9. A pipa entre colunas

- **Decisão:**
  - **coluna em foco:** a pipa escura com o blink da 001 (`Selector.shown`; o `ListItem` já pisca
    sozinho ao trocar de item);
  - **coluna sem foco:** a categoria fica `selected`, e o `ListItem` já desenha a pipa clara;
  - a pipa clara **não pisca** (FR-013) sem mudança nenhuma: de `hovered` pra `selected` o item
    continua com tinta, então `Selector.shown` não muda e só o `tone` troca, na hora.
- **Motivo:** FR-012/FR-013, reaproveitando o que a 001 já faz. O `Selector` não muda.

## R10. Valores por tipo

- **Decisão:** um composto `OptionRow` desenha o `ListItem` (variante `plain`) e põe à direita o
  valor do tipo:
  - **liga/desliga e escolha:** `ValueStepper` novo (base), com `◂ valor ▸`. As setas só aparecem
    com a linha em foco; a da ponta fica apagada;
  - **slider:** o `Meter` da 001, com dois acréscimos:
    - `editable` (clique na trilha emite `picked(value)`);
    - `inverted` (trilha `mediumGray` e preenchimento `lightYellow` sobre a faixa de tinta);
  - **ação:** rótulo + seta;
  - **informação:** texto `mediumGray`.

  O valor troca de cor junto com a varredura da faixa: claro quando `inked`.
- **Motivo:** FR-016 e FR-024 (componentes reutilizáveis na galeria).
- **Descartado:** um `ListItem` com um slot genérico pro valor. A faixa da 001 desenha o rótulo
  duas vezes (tinta e claro, recortado pela varredura) e um slot teria que ser instanciado duas
  vezes.

## R11. Fade de abertura, sem animação nos testes

- **Decisão:**
  - o escurecimento e o painel entram juntos com `opacity` 0 → 1 em `Tokens.motion.popupFade`
    (150 ms); o fechamento é imediato;
  - com `Tokens.frozen` (fixtures), o fade, a varredura e o blink ficam instantâneos (FR-022);
  - **movimento reduzido** (caso de borda): a opção `Settings.reduceMotion` entrou junto com a 004.
    O `shell.qml` liga `Tokens.reduced`, e `Tokens.instant` (= `frozen || reduced`) deixa o fade
    e o blink instantâneos. A varredura da faixa continua presa só às fixtures.
- **Motivo:** FR-006, FR-022 e a constituição VII (nada de abstração antes da segunda necessidade).

## R12. IPC e evidência

- **Decisão:** um alvo novo, `settings`:
  - `open`, `close`, `toggle`, `isOpen`;
  - `dump`: JSON com o estado inteiro (FR-021);
  - `reset`: volta os valores ao catálogo sem reiniciar o shell, pra o roteiro de teste começar
    sempre do mesmo ponto.

  As teclas reais chegam pela VM via QMP (`lab/key`), não por IPC (SC-003).
- **Motivo:** princípio IV ("comando que responde"), como o `hud dump`.

## R13. Laboratório (privado)

- **`lab/guest/hyprland.lua`:** `ALT + I` → `qs -p ~/nier/ui ipc call settings toggle`.
- **`lab/click x y`:** extraído do `check-u1`. Move o ponteiro e clica via QMP; serve ao clique
  fora (SC-004) e ao clique na trilha (SC-006).
- **`lab/burst <região> <n>`:** captura `n` quadros seguidos de uma região com `grim` dentro da
  VM e traz pro host. É o roteiro de quadros do blink, feito à mão em 2026-10-27, virando ferramenta
  (SC-005).
- **`lab/check-003`:** o roteiro do [quickstart.md](quickstart.md), como o `lab/check-u1`. Imprime
  PASS/FAIL por critério e junta a evidência numa pasta.
- **Medição:** tudo dentro de `lab/perf begin/end`. Os agentes paralelos usam `NIER_LAB_VM`
  (`teste-a`, `teste-b`, `teste-c`), cada um com a sua porta e a sua sessão.
- **Lint:** o `qmllint` roda dentro da VM, como na 001. A CI do F0 roda o mesmo no GitHub.
