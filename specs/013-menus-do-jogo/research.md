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

## R6. Keyboard › Layouts no Hyprland 0.56 (configuração em Lua)

**Decisão:** a lista vira `input.kb_layout` (separado por vírgula), aplicada sem reiniciar. A troca é por
um atalho de "próximo layout" (`hyprctl switchxkblayout`). Na F0, conferir na VM qual caminho o 0.56 com
Lua aceita em tempo de execução (`hyprctl keyword` ou a API Lua). Se nenhum aceitar sem recarregar, a
opção escreve na configuração gerenciada e pede um recarregamento.

**Por quê:** é a primeira configuração "lista" que faz sentido no desktop, e o dono pediu um exemplo
real.

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

## S1–S6. Som

Vêm da pesquisa da frente de som (em andamento):
- **S1:** como o shell toca;
- **S2:** formato e geração dos nossos;
- **S3:** o tema de login;
- **S4:** o som de boot;
- **S5:** o som de entrada;
- **S6:** como gravar o áudio da VM.

Cada um entra aqui com Decisão / Por quê / Alternativas / Evidência / Riscos.
