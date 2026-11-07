# Relatório da 013: menus do jogo

Branch `013-menus-do-jogo`, de 31.10 a 01.11.2026. Spec, plano e tarefas aprovados pelo dono em 31.10.
A execução teve a preparação, a sondagem e a fundação (eu), quatro frentes em paralelo, cada uma com
worktree e VM próprias, e a junção (eu):
- A, movimento (Opus);
- B, tela cheia e aba LOG (Sonnet);
- C, janelinha de escolhas (Sonnet);
- D, sons (Sonnet).

A 013 foi pra `main` em 01.11, a pedido do dono ("mergeia tudo"). Depois veio o T058, que ele pediu
na sessão de teste. As 58 tarefas estão feitas.

## O que ficou pronto

- **Movimento do jogo (US1, frente A).** Só o movimento do jogo, sem alternativa; o "Reduce motion"
  desliga tudo. As peças:
  - a varredura da linha selecionada (400 ms, OutQuart) e o recolher da que perde a seleção (200 ms);
  - o pulso na linha "viva" e na aba;
  - o título que some, espera e digita;
  - as listas entrando em cascata;
  - a troca de aba (some, fica vazio, monta), cortada por uma troca nova;
  - o rodapé entrando com desfoque e deslize;
  - as opções escalonadas, e a saída que estica e apaga a linha.
- **Abrir, fechar e confirmar (US2, frente A).**
  - Os triângulos na abertura e no fechamento (`popup/TriangleReveal.qml`, shader `triangles.frag`
    compilado em `.qsb`).
  - A montagem em ordem: réguas, abas, conteúdo.
  - O diálogo escurece o menu pra ×0,8 e mostra a faixa do título primeiro.
  - O papel de parede congela enquanto um menu está aberto.
- **Texto que não cabe rola (US3, frente A).** O `ScrollingLabel` nas linhas, nos valores e nos
  cabeçalhos de cartão. Com "Reduce motion", o texto volta a ser cortado com "…".
- **Janela ou tela cheia (US4, frente B).** Appearance › Menu presentation, com a janela flutuante
  como padrão.
  - A troca é ao vivo e mantém aba, seleção e foco.
  - As letras têm o mesmo tamanho nos dois modos.
  - Na tela cheia, as colunas de todas as abas vão da margem do título à ponta da régua (T058), com
    limite de largura em ultrawide.
  - Os toasts críticos e o OSD ficam por cima do menu cheio.
- **O text log como aba (US8, frente B).** A aba LOG fica entre WINDOWS e SYSTEM. O popup próprio da
  008 (`LogPopup`) saiu.
- **Janelinha de escolhas (US6, frente C).**
  - Enter numa escolha com mais de 3 valores abre o `ChoicePopup`.
  - O modo múltiplo usa quadradinhos, com pelo menos um marcado.
  - Keyboard › Layouts é aplicado no Hyprland.
- **Sons da interface (US5, frente D).**
  - São 13 sons nossos, sintetizados pela receita `system/sounds/gen/synth.py`. Som do jogo nunca
    entra no repo.
  - Configurações › Sound:
    - liga e desliga;
    - volume da interface;
    - "Sound folder", pra quem tem o jogo de PC usar os sons da própria cópia (`docs/sons-do-jogo.md`);
    - sons de boot e login.
  - Regras: 40 ms de intervalo mínimo por evento, até 4 sons ao mesmo tempo, mudo e não perturbe
    respeitados.
  - Não há som de digitação, nem como opção (decisão do dono, 01.11). O `typing.wav` e a receita dele
    saíram na limpeza de 01.11.
- **Som no boot e no login (US7, frente D).**
  - O módulo `yorha-os-boot-login` instala:
    - uma regra udev;
    - o `yorha-os-boot-sound.service`;
    - o script e um WAV por nível de volume.
  - O tema de login toca os sons dele e lê o volume e o mudo do `sound.json` do último usuário.
  - O `uninstall` desfaz tudo.

## Evidência (VMs do lab)

| Critério | Resultado | Onde |
|---|---|---|
| Movimento, abrir/fechar, diálogo, marquee, teclas (US1–US3) | verdes no modo janela nos dois perfis, depois das correções da junção; p95 de 59,7 a 59,9 quadros/s | frente A (`t013-mov`); junção `…015107`, `…015237`, `…023201` |
| Tela cheia (US4) | `modes` 44/0 em 1080 e hidpi, com as colunas medidas nas 5 abas (T058) | `…083120-…-t058-…` |
| Tela cheia, blocos de tempo da frente A | 154/6 em 1080 e 153/7 em hidpi: as falhas são medidas de tempo com o painel do tamanho da tela | junção `…015300`, `…015427` (decisão 7) |
| Janelinha (US6) | `choice` 10/0 em 2 perfis × 2 modos | `…230956-…-t013-escolha-…` |
| Sons (US5) | `sounds` e `sound-opts` 60/0 nos dois perfis, no GStreamer; atraso tecla → som com mediana ≤ 28 ms | junção `…021841`, `…021909`; frente D `…230704` |
| Som no boot e no login (US7) | `bootsound` + `boot-timing` 11/0, boot +0,04 s; `check-011 login` 6/0, `intro` 13/0; `undo` 52/0 com o som de boot | `…023928-…-teste-011-…`, `…232521-…-teste-011-…` |
| Aba LOG (US8) | `log-tab` verde; os blocos de log do `check-008` passam com o host `pause` | frente B `…231016` |
| Modo janela parado (FR-017) | 17 telas antes e depois, só as diferenças esperadas | `diferencas-janela.md`, `…022149` |
| Regressão | `check-003` 25/0 ×2, `check-004` 58/0, `check-007` 76/0, `check-008` 110/0 ×2 | junção, 01.11 |

Relatórios do `lab/perf` (em `YoRHa-OS-relatorios/runs/`):
- **Sondagem e fundação (31.10):** `…215024` e `…220953` (sondagem), `…221545` (esqueleto do
  `check-013`), `…222432` (fundação), `…222933` a `…225606` (regressão da fundação).
- **Frentes (31.10 e 01.11):**
  - A: `…230545`, `…010921`;
  - B: `…230048`, `…231016`;
  - C: `…230257`, `…230956`, `…231558`;
  - D: `…230704`, `…232521`.
- **Junção (01.11):** de `…013345` a `…023928`.
- **Sessão do dono e T058 (01.11):** `…080943` (teste-011, tudo junto, com som) e `…083120`.

O impacto no host ficou em poucos pontos de CPU acima da base, e nunca houve mais de 4 VMs ligadas.

## Achados

- **Qt Multimedia com FFmpeg:** iniciar um processo enquanto um `SoundEffect` toca põe o shell num
  laço de `QSocketNotifier`, com log de 1,27 GB e disco cheio. Por isso o shell usa o GStreamer
  (pragma no `shell.qml`). A tela de login ficou no FFmpeg, porque com o GStreamer o boot ficava
  +0,13 s mais lento (com o FFmpeg, +0,03 s). Os dois backends entram nas dependências.

> **Correção (06.11.2026, fix-laco-log):** o achado acima está errado na causa. O laço é uma corrida do Qt
> Multimedia 6.12.0 (a voz de um `SoundEffect` que termina sozinha é destruída na thread de tempo real do
> PipeWire), e acontece com FFmpeg, GStreamer e Pulse; o GStreamer não evita. Quem segura o laço é o guarda
> do log em `bin/yorha`. O pragma continua pela latência menor.
- **`aplay` segurando a placa** derruba o nó ALSA do WirePlumber até ele reiniciar. Por isso o
  `sound.state` só é gravado depois do `aplay`, e o tema de login espera por ele.
- **Layout de teclado no Hyprland com config em Lua:** o `hyprctl keyword` é recusado. O que funciona
  é `hyprctl eval 'hl.config({input={kb_layout=…}})'`.
- **Camadas Overlay:** a última superfície criada fica por cima. É isso que põe o OSD e a crítica
  sobre o menu cheio.

## Decisões tomadas no caminho (pro dono confirmar)

Estão na página de revisão, com fotos e números:
1. a aparência da janelinha de escolhas;
2. as variantes de layout;
3. o 4º valor de Network, "guest";
4. as marcas NEW somem ao sair da aba LOG ou ao fechar o menu;
5. a faixa crítica por cima do título do menu cheio;
6. o esticar da frente A, o véu do diálogo e o pulso na placa da aba;
7. aceitar a tolerância de tempo da tela cheia e adaptar o `check-013`;
8. a regra `no_anim` do Hyprland pro `yorha-popup` na config do produto.

## Limites e pendências

- **As 8 decisões acima.**
- **Sessão do dono (T055):** foi na `teste-011`, com a cadeia inteira (boot, login e shell, com som),
  em vez da `teste-b`. O dono aprovou a tela cheia depois do T058 ("o que já temos está ótimo"). Ele
  não comentou os sons um a um. Os detalhes que ele ainda quer mudar vão pra spec 010, quando ele
  listar.
- **Máquina de verdade:** tudo foi testado em VM.
- **Sons do jogo:** só pela pasta do próprio dono. Mapear os sons extraídos depende de comprar o jogo
  de PC (backlog).
