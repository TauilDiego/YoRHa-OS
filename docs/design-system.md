# Design system do YoRHa-OS

> Rascunho pra discussão. Baseado na biblioteca **"NieR: Automata - UI"**, de
> [tyleo](https://tyleo.com) ([Figma Community](https://www.figma.com/community/file/1598348131070316402/nier-automata-ui),
> licença [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)). Os valores abaixo foram
> lidos desse arquivo. Onde a gente diverge, está marcado como **desvio**.

**Objetivo:** ficar o mais perto possível da UI do jogo e continuar usável num desktop de
verdade. As peças são em camadas: cada nível só usa os níveis de baixo.

```
tokens       cores · tipografia · sombras · espaçamentos · animações
primitivas   texto · quadrado · régua (lisa / pontilhada / vertical) · fundo (grid / arcos / linhas)
base         botão-aba · item de lista · seletor · medidor · título de página · card
compostos    barra de abas · lista com cursor · card com cabeçalho · card de status · barra de dicas
telas        HUD (U1) · menu de pausa (U3) · Pod/OSD (U4) · lock (U5)
```

A referência é uma tela de **1920x1080**. Os tamanhos abaixo são nessa escala.

## 1. Tokens

### Cores

Do Figma (coleção `theme`):

| Token | Valor | Uso |
|---|---|---|
| `dark-gray` | `#4E4B42` | Tinta: texto, item selecionado, cabeçalho de card, quadrado |
| `medium-gray` | `#676458` | Tinta secundária |
| `light-gray` | `#B1AB93` | Botão/aba em repouso, barra de HP, faixas |
| `dark-yellow` | `#C9C5AB` | Fundo da página (papel) |
| `light-yellow` | `#D7D1B3` | Corpo de card, texto invertido |
| `box-shadow` | `#7C7E6C` a 69% | Sombra de caixa |
| `text-shadow` | `#7E7E74` a 57% | Sombra de título |
| `grid` | `#4E4B42` a 6% | Grid do fundo |

| `alert` | `#8F3A30` | **Desvio (decidido):** só estados críticos (bateria crítica, erro) |

O Figma não tem estado de alerta, por isso o `alert`. Ele é um vermelho escuro e dessaturado,
pra conviver com a sépia, e tem contraste ≥ 3:1 sobre `light-gray`, `dark-yellow` e
`light-yellow` (4,3:1 sobre o papel).

### Tipografia

| Estilo | Fonte | Peso | Tamanho/linha | Espaçamento | Uso |
|---|---|---|---|---|---|
| `page-header` | Helvetica Now Micro | Regular | 55/42 | 3px | Título grande da página ("ITEMS") |
| `subheader` | FOT-Rodin ProN | DB | 27/27 | 3px | Subtítulo ("-All Items") |
| `header-button` | FOT-Rodin ProN | DB | 27/27 | 3px | Abas do topo |
| `list-button` | FOT-Rodin ProN | M | 27/27 | 0 | Itens de lista |
| `card-header` | FOT-Rodin ProN | M | 27/27 | 2px | Cabeçalho de card |
| `standard` | FOT-Rodin ProN | DB | 23/23 | 1px | Texto corrido |
| `small` | FOT-Rodin ProN | M | 18/18 | 2px | Texto pequeno |
| `button` | FOT-Rodin ProN | DB | 16/16 | 0 | Botões e teclas |

**Desvio necessário:** FOT-Rodin e Helvetica Now Micro são comerciais e não podem ser
distribuídas. Usamos fontes abertas parecidas como padrão, e as originais quando o usuário as
tiver instaladas. **Decidido (2026-10-27): M PLUS 1** (OFL) em tudo, títulos inclusive:

| Papel | Padrão | Se instalada |
|---|---|---|
| Títulos (`page-header`) | M PLUS 1, peso forte (Bold ou ExtraBold, escolhido na galeria) | Helvetica Now Micro |
| Todo o resto | M PLUS 1, DB → SemiBold, M → Medium | FOT-Rodin ProN |

Comprar as originais foi descartado: a Rodin só é
vendida por assinatura da Fontworks LETS (¥49.500/ano) e a Helvetica Now Micro sai a partir de
US$ 42,99.

### Sombras

| Token | Deslocamento | Desfoque | Cor | Uso |
|---|---|---|---|---|
| `text-drop-shadow` | ≈15% do tamanho do texto (8, 8 no título de 55) | 0 | `text-shadow` | Título grande |
| `box-drop-shadow` | 3, 3 | 0 | `box-shadow` | Caixas, cards, item destacado |
| `soft-drop-shadow` | 3, 3 | 4 | preto a 42,5% | Superfícies flutuantes |

As sombras são sempre deslocadas pra baixo e pra direita, chapadas, sem desfoque. A única
exceção é a `soft`.

### Espaçamentos

| Token | Valor |
|---|---|
| `button-margin` | 10 |
| `horizontal-page-margin` | 62 |
| `vertical-page-margin` | 39 |
| `top-page-body-margin` | 31 |
| `bottom-page-body-margin` | 22 |
| `card-width` × `card-height` | 538 × 578 |
| `header-card-body-horizontal-margin` | 22 |
| `header-card-body-gap` | 15 |
| `body-to-footer` | 57 |

Cantos sempre retos (raio 0).

## 2. Primitivas

- **Quadrado:** o marcador antes de todo item e aba. Tinta em repouso, claro quando o item está
  invertido.
- **Régua:**
  - **lisa;**
  - **pontilhada:** uma linha com um traço pendurado embaixo a cada 77 px e, no meio do caminho
    entre dois traços, um trio ∵ de pontos **redondos** (como no Figma); aparece sob a barra de
    abas e no rodapé;
  - **vertical:** as faixas duplas na lateral das listas.
- **Fundo:** papel `dark-yellow` com vinheta radial, arcos de círculo e feixes de linhas diagonais
  finas. **Sem grid** (o jogo não tem; medido em 2026-10-27, §6) e **sem grão** (o jogo tem um grão
  fino, mas o dono preferiu sem).
  Medido nas capturas do jogo (§6):
  - **arcos:** círculos grandes (raio ≈ 600–1100 px a 1080p) com centro fora da tela, traço de
    2 px em tinta a ~10%;
  - **feixes:** 2 a 4 linhas paralelas (≈12 px entre elas), descendo da esquerda pra direita a
    ~35°, traço de 1–2 px em tinta a ~8%;
  - **movimento:** no jogo, o fundo "respira" devagar. No desktop, os arcos giram e os feixes
    deslizam bem lentamente (uma volta a cada ~10 min), em passos de pixel inteiro.

## 3. Peças base

### Botão-aba (`header-button`)

Tem ícone (quadrado) + texto e mede 214×47. São 7px entre o quadrado e o texto. No Figma, a
borda esquerda reserva espaço pro cursor; no YoRHa-OS, as abas não têm seletor (ver §5).

| Estado | Fundo | Quadrado e texto | Cursor |
|---|---|---|---|
| Dormant (repouso) | `light-gray` | `dark-gray` | — |
| Hovered (foco) | `dark-gray` | `light-yellow` | — |
| Selected | `dark-gray` | `light-yellow` | — |

Na barra de abas, a aba Selected desce até a régua de baixo e se funde com ela (§6).

### Seletor / cursor do Pod (`selector`)

Uma forma de pipa (losango alongado) apontando pra direita, com um furo redondo. Tem duas
variantes: escura e clara. Fica à esquerda do item em foco. O `dot-selector` é a variante
menor, com pontos.

O seletor completo é a pipa **+ 2 quadradinhos** empilhados entre a ponta dela e o item: um acima
e outro abaixo do eixo. Medidas aproximadas, tiradas do Figma em 1×:
- pipa de ≈32×14, com o furo perto da traseira;
- quadradinhos de ≈5×5, sempre na cor `dark-gray` (com a pipa escura e com a clara);
- os centros dos quadradinhos ficam a ±10 px do eixo, alinhados com a ponta, ≈7 px antes do
  item.

A pipa e os quadradinhos ficam **parados**, como no jogo. Ao trocar de item, eles piscam juntos:
somem do item antigo e reaparecem no novo, com ease in-out (`motion.blink`, ≈240 ms no total).

### Item de lista

Quadrado + texto `list-button`. No item selecionado:
- a faixa fica invertida (`dark-gray` com texto claro);
- aparecem trilhos finos acima e abaixo;
- o seletor aparece à esquerda.

Na **lista opaca**, o corpo é `light-yellow` com as faixas verticais duplas. Na **transparente**,
os itens são caixas `light-gray` soltas, com a sombra `box`.

### Medidor (`hp-bar`)

Uma barra chapada de 163×11, sem borda, com a cor `light-gray`.

### Título de página (`page-header`)

O título em `page-header`, com a sombra `text-drop-shadow` (8,8), e o subtítulo começando com
"-" ao lado.

### Card

Cabeçalho `dark-gray` com texto claro (`card-header`) e corpo `light-yellow`, de 538×578, cantos
retos. O corpo pode ter imagem, texto e um rodapé alinhado à direita.

## 4. Compostos (referência: a página `nier-page` do Figma)

- **Barra de abas:**
  - uma faixa vertical à esquerda;
  - as abas (o Figma põe o seletor na aba em foco; no YoRHa-OS, não, ver §5);
  - a régua pontilhada embaixo.
- **Lista com cursor:** faixas verticais + itens + barra de rolagem + seletor.
- **Card de status:** pares rótulo/valor alinhados, medidor, fileira de quadrados vazios e um
  rodapé centralizado (ex.: "NO ERROR").
- **Barra de dicas** (rodapé da página): a instrução à esquerda ("Select item."), as teclas à
  direita (caixas escuras com a letra) com a ação, e a régua pontilhada embaixo.

## 5. Desvios pro desktop (decididos em 2026-10-27)

| Ponto | No jogo (1080p) | No YoRHa-OS |
|---|---|---|
| Altura da barra do topo | Aba de 47px, texto 27px | **Revisado (2026-10-27):** barra de 68px, configurável de 28 a 96. De cima pra baixo: 3px de folga, a aba (33px, `s ≈ 0,70`), um vão de 17px de jogo (12px) e a régua pontilhada **na escala do jogo** (`s × 1,0`: pontos de 4px, padrão de 20px de altura), nítida em pixels físicos inteiros. A aba em foco desce até a régua por uma haste animada (`motion.touch`, 160 ms, logo depois da tinta; recolhe em `motion.untouch`, 120 ms). A versão cheia fica pros menus de tela inteira |
| Escala | Fixa em 1080p | Tokens em medidas do jogo × fator da tela × `uiScale` (ver "Escala") |
| Fontes | Comerciais | M PLUS 1 por padrão; as originais quando estiverem instaladas |
| Alerta | Não existe | `alert` `#8F3A30`, só pra estados críticos |
| Sombra do título | 8,8 fixo | Proporcional ao tamanho do texto (≈15%) |
| Cursor (pipa) | Parado; pula de um item pro outro | **Decidido (2026-10-27):** parado, e pisca ao trocar de item (some e reaparece com ease in-out, `motion.blink` ≈240 ms) |
| Abas da barra | Seletor (pipa) ao lado da aba em foco | **Decidido (2026-10-27):** as abas nunca têm seletor, nem no HUD nem nos menus: só as abas lado a lado. A pipa fica só nos itens de lista |
| Fundo do desktop | Só nos menus | **Decidido (2026-10-27):** o fundo inteiro da área de trabalho é o papel do menu (vinheta, arcos e feixes, sem grid, com movimento sutil que pode ser desligado). Desde a spec 004 ele é um papel de parede do próprio YoRHa-OS, trocável (§8) |
| Vinheta | Em todos os menus | Como no jogo (bordas `#A6A18D`, cantos `#8B8877`), desligável. Nos menus de tela cheia e na tela inteira do desktop, sem emenda (2026-10-27). As janelas, as abas, a régua e os textos ficam por cima, sem vinheta. Desde a spec 004 (US6) a barra do topo não pinta mais a faixa dela: a vinheta que aparece embaixo da barra é a do próprio papel de parede (§8, "A barra sobre o fundo") |
| Fundo da barra do topo | O HUD do jogo flutua sobre a cena | **Decidido (2026-10-27, spec 004 US6):** a barra não tem fundo próprio. O papel de parede e as transições passam por baixo dela, e as cores dela seguem o fundo do monitor: tom papel ou tom claro (§8, "A barra sobre o fundo") |

### Escala

Segue o modelo do Serpantinum, que funciona bem com monitores de escalas diferentes (ex.: um
1920x1080 em escala 1 ao lado de um 2560x1600 em escala 1,25 = 2048x1280 lógicos):

- **Tudo em pixels lógicos.** A escala fracionária do monitor fica com o Hyprland e o Qt; a UI
  não calcula DPI nem lê a resolução física.
- **Tokens nas medidas do jogo a 1080p** (as desta página). Cada tela aplica um fator `s`:
  - HUD: `s = alturaDaAba / 47`. Com a barra padrão de 68px, a aba tem 33px e `s ≈ 0,70`;
  - menus de tela inteira: `s = alturaLógicaDoMonitor / 1080`, pra ocupar a tela como no jogo.
- **`uiScale`** (padrão 1) multiplica tudo, pra quem quiser a UI maior ou menor sem mexer na
  escala do monitor.
- Linhas finas (grid, réguas) arredondam pra pixel inteiro, com mínimo de 1px, pra ficar nítidas.
- Testes no laboratório nos dois perfis: 1920x1080 @1 e 2560x1600 @1,25.

## 6. Observações do jogo

As medidas saíram de capturas nativas em 1920x1080 da Steam Community e das imagens oficiais em
1600x900 do blog da PlatinumGames ([artigo do designer de UI Hisayoshi Kijima](https://www.platinumgames.com/official-blog/article/9624)),
convertidas pra 1080p (×1,2). As imagens ficam só no repositório privado, pra referência pessoal.
**M** = medido no pixel (±1–2 px, ±3 por canal de cor). **E** = estimado.

| Ponto | Figma (tyleo) | Jogo | Recomendação |
|---|---|---|---|
| Aba inativa | 214×47 | **M** 216×48, fundo `#B1AC98`, passo de 254 entre abas (espaço de 38) | Seguir o Figma |
| Aba ativa | — | **M** tinta `#4A483E`, desce do topo das abas até a régua (≈72 px) e se funde com ela | **Decidido:** encosta na régua |
| Texto da aba | 27 | **M** maiúsculas de 22 px → **E** fonte ≈29–30, caixa alta, espaçamento largo | Manter 27; testar 29 |
| Ícone → texto | 7 | **M** ícone 30×29 a 9 px da borda, ≈10 px até o texto | Seguir o Figma |
| Margem horizontal | 62 | **M** 62 nos dois lados | Seguir o Figma |
| Margem vertical | 39 | **M** abas começam em y=37; a régua de baixo fica a ≈62 da borda | Seguir o Figma; a de baixo é maior |
| Régua sob as abas | — | **M** linha de 2 px; tracinhos de 12×3–5 px a cada 77 px embaixo | Adotar |
| Régua pontilhada | — | **M** a cada 77 px, um traço de 12×4 pendurado na linha e, no meio do caminho até o próximo, um trio de pontos redondos (∵) de ≈6–7 px, centros a 16 px, 2ª fileira 12 px abaixo (confere com o Figma) | Adotar |
| Título da página | 55, tracking 3 | **M** maiúsculas de 42 px → **E** fonte ≈56–58 | Seguir o Figma |
| Sombra do título | 8,8 | **M** ≈(8–9, 8), dura, cor ≈`#8C897C` | Manter; proporcional (§5) |
| Sombra de painéis | 3,3 | **M** 3–4 px, dura, ≈`#716D61` | Seguir o Figma |
| Papel | `#C9C5AB` | **M** `#C7C2AA`–`#C8C3AC` | Seguir o Figma |
| Vinheta | — | **M** bordas `#A6A18D`, cantos `#8C8978`, em todas as telas de menu; perfil num círculo de meia diagonal (o centro de cima e de baixo fica papel) | **Decidido:** como no jogo, na tela inteira do desktop e nos menus de tela cheia, desligável |
| Grid | 6% | **Revisto (2026-10-27):** não existe no fundo do jogo; a leitura anterior era a compressão das capturas | Tirar do fundo (feito na 004 US1) |
| Fundo (medido) | — | **M** centro `#C8C3AC`, bordas `#A6A18D`, cantos `#8C8978` (vinheta radial); grão fino, desvio ≈2 níveis em 255 (o YoRHa-OS fica sem, escolha do dono); diagonais ≈20 níveis mais escuras que o papel (≈17% de tinta), em feixes de 2–3 linhas que começam e terminam na tela; arcos duplos (dois círculos a ≈6 px), centro fora da tela | Seguir (spec 004) |
| Fundo escuro | — | **M** atrás de popups e legendas: `#141414`, arcos e diagonais cinza até ≈`#454545` | Variante pra testar |
| `light-yellow` | `#D7D1B3` | **M** `#D2CDB4`–`#D4CEB5` | Seguir o Figma |
| `light-gray` | `#B1AB93` | **M** `#B0AB97` | Seguir o Figma |
| Tinta | `#4E4B42` | **M** `#4A473E`–`#565448` | Seguir o Figma |
| Item selecionado | faixa + trilhos | **M** faixa de 48 px (≈37 em SETTINGS), trilhos de 2 px a 5 px da faixa, passo de 60 px | Seguir o Figma |
| Item não selecionado | — | **M** faixa `light-gray` em listas de categoria; sem faixa em listas de conteúdo | Ter as duas variantes |
| Cursor | pipa | **M** pipa ≈38×18 com furo + ":" (2 quadradinhos de 5 px), ≈22 px antes da faixa; fica apagada na lista que perdeu o foco | Seguir o Figma + estado "inativo" |
| Barra de dicas | — | **M** 1796×78, `light-yellow`, bloco de tinta de 14 px à esquerda, sombra de 3 px | Adotar |
| Medidor | 163×11 chapado | **M** menu: 183×11 chapado. HUD do jogo: ≈316×9, trilho escuro translúcido, tiques nas pontas | **Decidido:** o `hp-bar` do menu também no HUD |
| Faixa de tutorial | — | **M** tela toda, ≈263 px, tinta translúcida com retícula, texto `#E5E5E3` | Referência pras notificações (U4) |

**Movimento (E, sem medição quadro a quadro):**
- Kijima diz que as animações deviam parecer "úmidas" (fluidas). Qualquer botão pula a animação
  de fechar.
- **Realce de item:** a faixa varre da esquerda pra direita junto com os trilhos, em ≈100–150 ms
  com desaceleração. A spec usa 0,15 s (token `motion.highlight`).
- **Cursor:** parado. O YoRHa-OS acrescenta um blink suave quando ele troca de item (ver §5).
- **Fechar o menu:** a tela se desfaz em estilhaços triangulares, em ≈300–500 ms.
- **Estado danificado:** aberração cromática e glitch no texto.
- Os tempos ficam em tokens, pra calibrar depois com gravação a 60 fps no laboratório.

## 7. Popup e configurações (spec 003)

As peças da tela de configurações (`specs/003-settings-popup`), que viram padrão dos menus do U3.
Medidas em px do jogo; cada superfície multiplica pelo seu `s`. Todas estão na página 2 da
galeria (Tab), com os estados abaixo.

### Tokens novos

| Token | Valor | Uso |
|---|---|---|
| `color.dim` | `#141310` a 55% | Escurecimento do desktop atrás do popup. **Sem desfoque** (constituição VII) |
| `shadow.popup` | 6, em tinta | Sombra chapada do painel. A `box-shadow` clara viraria brilho sobre o escurecimento |
| `space.popupShare` | 0,84 | Fração da tela ocupada pelo painel |
| `space.popupW` × `popupH` | 1612 × 908 | Quadro de desenho do painel (84% de 1920 × 1080) |
| `space.settingsCatsW` / `OptsW` / `CardW` | 300 / 600 / 440 | As três colunas das configurações |
| `space.stepperValueW` | 190 | Texto entre ◂ e ▸ |
| `space.sliderW` | 220 | Trilha do slider |
| `motion.popupFade` | 150 ms | Fade de abertura do popup e do escurecimento; o fechamento é imediato |
| `motion.actionBusy` | 2000 ms | Quanto tempo o aviso de uma ação fica no quadro |
| `reduced` / `instant` | — | Movimento reduzido (`reduceMotion` no `shell.json`): o fade e o blink da pipa ficam instantâneos, como com fixtures |

### Moldura de popup (`PopupFrame`, `PopupWindow`)

- Uma janela só, transparente, na camada `Overlay`, cobrindo o monitor em foco.
- O resto da tela fica sob `color.dim` (janelas, barra do topo e fundo continuam visíveis).
- No centro, o painel de papel com `popupShare` da largura e da altura, sombra `shadow.popup` e a
  vinheta própria (a mesma config `vignette`).
- **Dentro do painel:**
  - título de página (`SYSTEM -Settings`) em (48, 42);
  - régua lisa em y 112;
  - régua lisa 88 px acima do fundo;
  - texto à esquerda do rodapé (`small`, `medium-gray`);
  - rodapé de teclas à direita.
- **Escala:** `s` = o menor entre altura do painel / 908 e largura / 1612, × `uiScale`. Em telas
  16:10 a sobra vai pra altura, e o rodapé fica colado embaixo.
- **Interação:**
  - teclado exclusivo enquanto aberto;
  - clique no escurecimento fecha;
  - o fade de abertura vale pros dois juntos.
- **Fechamento em duas fases:** some e solta o teclado na hora; a janela sai 150 ms depois.
- **Reuso:** a mesma moldura serve o seletor de papel de parede (spec 004).

### Lista de categorias sem foco (`CursorList`, `focused: false`)

O item atual fica `selected`: faixa, trilhos e a pipa **clara e parada**. Passar o foco de uma
coluna pra outra não pisca a pipa clara; a escura pisca ao entrar no item novo.

### Linha de opção (`OptionRow`)

O item de lista `plain` (sem faixa em repouso) com o valor à direita, a 16 px da borda.

| Tipo | Valor | ← / → | Enter / clique |
|---|---|---|---|
| liga/desliga | `◂ ON ▸` / `◂ OFF ▸` | alterna | alterna |
| escolha | `◂ valor ▸`, seta da ponta a 30% | anda, sem dar a volta | avança, dando a volta |
| slider | trilha de 220 × 11 + número (46 px, à direita) | ± o passo da opção, 0–100 | clique ou arraste na trilha: o ponto clicado |
| ação | rótulo + seta (11 × 16) | ← volta pras categorias | aviso no quadro por `actionBusy` |
| informação | texto `medium-gray` | ← volta pras categorias | nada |

| Estado | Faixa | Texto e valor | Pipa | Setas ◂ ▸ |
|---|---|---|---|---|
| normal | nenhuma | tinta | — | escondidas (o espaço fica) |
| em foco | tinta, trilhos, sombra | `light-yellow` quando a varredura passa por eles; informação a 75% | escura | visíveis |
| apagada | nenhuma | `medium-gray` | — | escondidas |
| apagada + em foco | tinta | `light-yellow` a 55% | escura | visíveis, apagadas |

- Rótulos e valores longos cortam com reticências.
- O texto livre (ação, informação) ocupa no máximo 45% da linha.
- Os valores usam 23 px, peso 500 e algarismos tabulares.

### Seletor de valor (`ValueStepper`)

`◂ valor ▸`:
- triângulos de 11 × 16;
- 14 px até o texto;
- o texto centrado em 190 px.

As setas só aparecem na linha em foco. A da ponta da lista fica a 30% e o clique numa seta muda o
valor pra esse lado.

### Slider (`Meter` editável)

O medidor do HUD com dois acréscimos:
- `editable`: clique ou arraste na trilha (área de toque 12 px acima e abaixo);
- `inverted`: trilha `medium-gray` e preenchimento `light-yellow`, sobre a faixa de tinta.

### Quadro de descrição (`DescriptionCard`)

O `Card` com o quadrado claro de 14 px antes do título, como no mockup.
- **Corpo:** a descrição (23 px, peso 500, linhas a 1,5 × o tamanho); depois um aviso (18 px,
  peso 600): `alert` pro que fazer antes ("Turn on Wi-Fi first.") ou tinta pra ação em andamento.
- **Pé:** linhas `DEFAULT` / `NOW`, ou `SETTINGS` com o foco nas categorias. O rótulo vai em
  `medium-gray` e o valor em peso 600.
- **Altura:** mínima de 360, cresce com o texto até o rodapé. O que não couber corta com
  reticências.

### Rodapé de teclas (`KeyHints`)

Caixa de tinta com a tecla (`button`, `light-yellow`), de 34 × 30 no mínimo e 8 px de folga dos
lados, e o rótulo `small` a 12 px; 34 px entre as dicas. Mostra só as teclas que valem no foco
atual:

| Foco | Teclas |
|---|---|
| categorias | `↑↓ Select` `→ Open` `Esc Close` (sem `→ Open` numa categoria vazia) |
| opção que muda | `↑↓ Select` `←→ Change` `Esc Back` |
| ação | `↑↓ Select` `Enter <ação>` `Esc Back` |
| informação ou apagada | `↑↓ Select` `Esc Back` |

### Foco em duas colunas (a regra)

- **Um foco só:** fica nas categorias ou nas opções.
- **Mover nas categorias** já troca as opções; → ou Enter entra; Esc volta (ou fecha, nas
  categorias); ← numa linha que não muda também volta.
- **O mouse move o foco junto,** mas só quando o ponteiro se mexe de verdade: um ponteiro parado
  sobre itens que aparecem embaixo dele (popup abrindo, outra categoria) não rouba o foco do
  teclado.
- **Rolagem:** uma coluna que não cabe rola em linhas inteiras, com a pipa sempre visível.

## 8. Papel de parede (spec 004)

O YoRHa-OS desenha o próprio papel de parede, sem ferramenta de fora (`swww`, `hyprpaper`…): um
fundo por monitor na camada de fundo do Wayland. Cada monitor mostra a escolha dele, ou a de
"todos os monitores", ou a cena `menu`. A escolha é estado do usuário
(`$XDG_STATE_HOME/yorha-os/wallpaper.json`), nunca a config dele. Há três tipos: **cenas**,
**imagens** da pasta do usuário e **vídeo** (depois, no U6).

### Cenas

Uma cena é um JSON em `shell/wallpaper/scenes/<id>.json` (formato em
`specs/004-wallpaper-system/contracts/scene.schema.json`). A geometria fica no componente
(`Scene` + `PaperDecor`), igual pra todas; o JSON só liga camadas e escolhe cores e movimento.

| Parâmetro | O que faz | `menu` |
|---|---|---|
| `paper.center` | Cor do papel | `#C9C5AB` |
| `paper.edge`, `paper.corner` | Alvos da vinheta (bordas, cantos) | `#A6A18D`, `#8C8978` |
| `layers.arcs` | 4 arcos com centro fora da tela, 2 duplos (+7 px no raio) | sim |
| `layers.beams` | 4 feixes de 2–3 linhas a 42°, começos +34 px e fins −60 px por linha | sim |
| `layers.rules` | Régua pontilhada em y 1012 (tinta a 90%); a de cima é a da barra | não |
| `layers.dots` | Trama da cena escura: 1 px a cada 4 px, branco a 7% | não |
| `lineAlpha` | Tinta das linhas | 0,15 |
| `motion.arcPeriod` / `arcAmplitude` | Os arcos balançam ± graus em torno do próprio centro | 600 s / 9° |
| `motion.beamPeriod` / `beamAmplitude` | Os feixes deslizam ± px ao longo da direção | 300 s / 70 px |

| Cena | Papel | Arcos | Feixes | Réguas | Trama |
|---|---|---|---|---|---|
| `menu` (padrão) | papel | ✓ | ✓ | — | — |
| `rules` | papel | ✓ | ✓ | ✓ | — |
| `dark` | `#141414` → `#101010` → `#0A0A0A`, linhas `#96948C` a 20% | ✓ | ✓ | — | ✓ |
| `plain` | papel | — | — | — | — |

- **Vinheta:** as cenas de papel usam a vinheta medida (§1, "Vinheta"). A barra do topo é
  transparente (spec 004 US6), então a vinheta do fundo passa embaixo dela, sem emenda. A cena
  escura escurece pro preto com a força que o `edge` e o `corner` dela pedem.
- **Papel:** o centro é o `dark-yellow` (`#C9C5AB`), a 1–2 níveis do medido no jogo (`#C8C3AC`):
  é o mesmo papel do resto do design system.
- **Movimento:** no ciclo de 600 s do shell; para com dados de teste ou com `wallpaperMotion: false`.

### Imagens e filtro de papel

- **Pasta:** `wallpaperFolder` (padrão `~/Pictures/Wallpapers`), só lida e observada: um arquivo
  novo aparece sem reiniciar. Entram `jpg`, `png` e `webp`; o resto fica de fora, com uma linha no
  log.
- **Na tela:** cobre o monitor sem esticar (o excesso é cortado, centralizado), decodificada no
  tamanho físico do monitor.
- **Filtro de papel** (de fábrica, desligável por imagem): as cores puxadas pro papel e uma
  vinheta mais suave por cima, como no mockup.
  - **cor:** `MultiEffect` com `colorization` 0,85 e `Tokens.wallpaper.filterTint` `#FFFAD9`,
    que é o matiz do papel em brilho cheio: a colorização do Qt multiplica a luminância pela cor,
    e com o papel em si a imagem escurecia ≈30 níveis;
  - **vinheta:** tinta de 0 (a partir de meio raio) a 0,26 nas bordas e 0,35 nos cantos.

### Transições

A troca nunca é um corte seco. A transição é escolha do usuário, e vale pro seletor e pra troca
por comando. Todas são um shader só (`shell/shaders/transition.frag`), sobre o fundo antigo e o
novo como texturas vivas; as cores chegam do `Tokens`.

| Transição | Duração | Como é |
|---|---|---|
| **Camuflagem** (de fábrica) | 1200 ms + rastro + 450 ms (≈4,3 s de fábrica) | Ver abaixo |
| **Varredura** | 900 ms, ease in-out | O novo entra da esquerda; a borda é a régua pontilhada em pé (linha na borda, tracinhos e trios do lado novo) e passa 40 px da tela pra sair inteira |
| **Quadradinhos** | 900 ms, ease in-out | Células de 24 px, da esquerda pra direita com 30% de sorteio; cada uma vira primeiro um quadrado de tinta a 90% com 4 px de margem, depois o novo |
| **Crossfade** | 900 ms, ease in-out | Um some enquanto o outro aparece |

**Camuflagem, etapa por etapa** (medidas em px do jogo, a 1080p):
1. **A onda:** sai de um ponto sorteado perto do centro (±15% da tela) e cruza a tela em
   1200 ms. Cada célula (`cell`: 16, 24 ou 32 px; de fábrica 24) tem o seu momento:
   1200 ms × (0,85 × distância até a origem ÷ maior distância + 0,15 × sorteio).
2. **Refração:** nos 200 ms antes da onda, o fundo antigo da célula treme (até 6×4 px) e, na
   metade final, vira mosaico de 4 px.
3. **Brilho:** nos primeiros 60 ms, a borda de 2 px da célula fica clara (`glint` a 55%).
4. **Entrada pixelada:** o novo entra em blocos de 12 px (até 130 ms), 6 px (até 260 ms) e 4 px
   (até 400 ms), e fica nítido.
5. **Rastro:** durante `trail` ms (800, 1500 ou 2600; de fábrica 2600), um véu claro (`glint` a 10%)
   e o contorno de 2 px em tinta a 30% vão sumindo.
6. **Falhas:** enquanto o rastro dura, uma célula falha por um quadro (33 ms) com chance
   0 / 0,0008 / 0,006 (`glitch` 0, 1, 2; de fábrica 2, "visíveis") vezes a força do rastro: em 30%
   das vezes mostra o fundo antigo; senão, o novo deslocado 2 ou 4 px na horizontal.
7. **Fim:** 450 ms depois do rastro, o efeito sai e só o fundo novo fica.

**Regras de todas:**
- **instantâneas** com dados de teste (screenshots iguais) ou com `reduceMotion: true`;
- **uma troca no meio de outra** parte do quadro que está na tela, sem pulo;
- **sem o shader compilado** (`.qsb`, gerado por `shell/shaders/build.sh` onde a UI roda), viram
  um crossfade, com um aviso no log;
- **custo medido na VM** (spec 004, SC-009; sem meta até o U6): 10 camuflagens custaram 0,63 s de
  CPU do Quickshell por troca, a ≈60 fps; 10 crossfades, 0,18 s. Por segundo animado o CPU é
  parecido: o extra da camuflagem fica na GPU.

<!-- spec 004 US6 (004-barra-tom): início -->
### A barra sobre o fundo (US6)

A barra do topo não tem fundo próprio (emenda da spec 004, aprovada pelo dono em 2026-10-27): o
papel de parede de cada monitor, com as transições, passa por baixo dela, e os arcos e os feixes
cruzam a faixa da barra, como no jogo. As cores da barra seguem o fundo do monitor dela, em dois
tons:

| Papel | Uso | Tom papel | Tom claro |
|---|---|---|---|
| `ink` | texto principal, hora, tinta da aba normal, rótulos das leituras | `#4E4B42` | `#D7D1B3` |
| `ink2` | título, data, valores, tinta da aba apagada | `#676458` | `#96948C` |
| `rest` | placa da aba, faixas verticais | `#B1AB93` | `#D7D1B3` a 16% |
| `sel` / `selInk` | placa e tinta da aba em foco (e da destacada) | `#4E4B42` / `#D7D1B3` | `#D7D1B3` / `#4E4B42` |
| `track` / `fill` | trilho e preenchimento do medidor | `#B1AB93` / `#4E4B42` | `#D7D1B3` a 22% / `#D7D1B3` |
| `rule` | régua pontilhada | `#4E4B42` | `#96948C` a 75% |
| `alert` | estado crítico | `#8F3A30` | `#C0574A` |

O tom papel são os tokens de sempre (§1). Os dois ficam em `Tokens.hudPaper` e `Tokens.hudLight`;
`Tokens.hudColor(papel, tom)` dá a cor de um papel num tom de 0 (papel) a 1 (claro), misturando
canal a canal, com alfa. `Label`, `Rule`, `HeaderButton`, `Meter` e `TabBar` recebem `tone` (padrão
0, que deixa a galeria, o popup e todo o resto como sempre foram).

**Qual tom:**
- cenas de papel (`menu`, `rules`, `plain`) → papel;
- cena `dark` → claro;
- imagem → a luminância média (0,2126 R + 0,7152 G + 0,0722 B) da faixa de cima (a altura da barra
  mais 12 px) da imagem como aparece, com o filtro de papel, se ligado: abaixo de 0,45
  (`Tokens.hudLightBelow`), claro; senão, papel. É medida uma vez por imagem, quando ela fica
  pronta, e guardada por caminho e filtro.

**Na troca:** as cores misturam do tom antigo pro novo enquanto a transição cobre a faixa da barra,
com `smoothstep`: na camuflagem, a fração das células de cima já reveladas; na varredura, a borda ÷
a largura; nos quadradinhos, a fração dos de cima já começados; no crossfade, o progresso. Com
dados de teste ou movimento reduzido, a troca é instantânea. Cada monitor tem o seu tom.

**Limitação:** uma janela flutuante arrastada pra cima da barra aparece por trás das abas e dos
textos, porque o Hyprland só reserva a faixa da barra pras janelas lado a lado.

<!-- spec 004 US6 (004-barra-tom): fim -->

### Lista + prévia + opções (`PickerLayout`)

O layout da tela ITEMS do jogo, pra qualquer seletor dentro da moldura de popup (§7): uma lista
agrupada à esquerda, a prévia ao vivo do item em foco no meio e, à direita, o quadro de opções com
as informações. É o corpo do seletor de papel de parede e serve pros próximos menus do mesmo tipo
(tema, fonte, som…). Medidas em px do jogo, no quadro de 1612 × 908 da moldura:

| Peça | Onde | Medidas |
|---|---|---|
| Lista agrupada | x 48, y 150 | itens de 380 (`space.pickerListW`), depois das faixas e da pipa |
| Prévia (o que o menu põe no meio) | x 560, y 150 | 560 de largura (`space.pickerPreviewW`) |
| Quadro "Options" | x 1160, y 150 | 404 de largura (`space.pickerOptionsW`); a pipa das linhas fica no vão de 40 px antes dele |
| Fim das colunas | 24 px acima da régua do rodapé | a lista rola dali pra baixo |

- **Lista agrupada (`GroupedList`):** a lista de cursor com títulos de grupo.
  - **título:** texto `small`, `medium-gray`, alinhado com os itens, numa linha de 18 px, com 10 px
    acima (menos o primeiro) e 2 abaixo; nunca recebe o cursor;
  - **aviso:** uma linha `small` debaixo de um título vazio (ex.: "Put pictures in ~/Pictures/Wallpapers");
  - **item:** o item de lista `opaque`, com a marca à direita em `small` (`● ALL`, ou as saídas);
  - **item apagado:** o estado `dimmed`; com o cursor, a faixa de tinta e o texto claro a 55% (como
    a linha de opção apagada);
  - **sem foco:** o item atual fica `selected`, com a pipa clara e parada (§7);
  - **rolagem:** quando não cabe, rola na hora, por entradas inteiras, mostrando o item atual com os
    trilhos e, se ele for o primeiro do grupo, o título.
- **Prévia (`PreviewCard`, no seletor de papel de parede):** o card com o quadrado claro antes do
  título (`Card` com `mark`), a mídia de 512 × 288 numa moldura de 2 px `medium-gray`, 24 px das
  bordas, e a descrição embaixo (23 px, peso 500, linhas a 1,45 × o tamanho, no mínimo 100 px).
- **Quadro de opções:** o `Card` com `mark` e o título "Options"; as linhas de opção (§7) de escolha,
  `◂ valor ▸`, desenhadas a 0,815 (`space.pickerOptionScale`: rótulo de 22 px, quadrado de 18, valor
  de 19 num espaço de 155) na mesma faixa de 48 px e com a mesma pipa; uma régua de 2 px
  `light-gray`; e as linhas de informação: rótulo `small` em caixa alta `medium-gray` à esquerda,
  valor `small` peso 600 à direita, quebrando linha quando não cabe.
- **Foco em duas colunas** (a regra do §7, com a lista no lugar das categorias):
  - **lista:** ↑↓ andam (dando a volta, pulando os títulos); Enter aplica (nada num item apagado);
    → vai pra primeira opção; Esc fecha;
  - **opções:** ↑↓ andam; ←→ mudam o valor, sem dar a volta; ← no primeiro valor volta pra lista;
    Enter avança o valor, dando a volta; Esc volta;
  - **mouse:** passar por cima move o foco (só com o ponteiro se mexendo de verdade); clicar num
    item aplica; clicar numa seta muda o valor; clicar no resto da linha avança.
- **Rodapé de teclas:**

| Foco | Teclas |
|---|---|
| lista | `↑↓ Select` `Enter Apply` `→ Options` `Esc Close` (sem `Enter Apply` num item apagado) |
| opções | `↑↓ Select` `←→ Change` `Esc Back` |

**No seletor de papel de parede** (`WallpaperPicker`, `ALT + W` na VM, `qs ipc call wallpaper picker
open|close|toggle`):
- **título:** `WALLPAPER -Select`; rodapé à esquerda: `YoRHa-OS 0.1 · N monitors`;
- **lista:** SCENES, IMAGES e VIDEO, com `● ALL` (ou as saídas) no que está aplicado; abre com o
  cursor no papel de parede do monitor em que abriu;
- **opções:** `Monitor` (All monitors, depois cada saída), `Transition` (as quatro) e, só nas
  imagens, `Paper filter` (On/Off). A transição e o filtro valem na hora; o monitor é só do seletor e
  volta pra "All monitors" a cada abertura;
- **informações:** `TYPE`, `LAYERS`, `MOTION` e `NOW ON`;
- **Enter** aplica no monitor escolhido (ou em todos), com a transição escolhida, que acontece atrás
  do escurecimento.

**Peças da 001/003 que ganharam um acréscimo:**
- `Card.mark`: o quadrado claro de 14 px antes do título (o título que não cabe corta com
  reticências);
- `ListItem.trailingRole` (o papel do texto da direita) e `ListItem.contentScale` / `OptionRow.contentScale`
  (texto, quadrado e valor menores na mesma faixa, trilhos, sombra e pipa).

A galeria mostra tudo isso na página 3 (Tab duas vezes): as quatro cenas, uma imagem com e sem o
filtro, um quadro parado de cada transição (camuflagem em 700 ms; as outras na metade), a lista
agrupada com e sem foco e o layout inteiro em miniatura.

### Tokens e configuração

- **Tokens do layout** (`Tokens.space`): `pickerListW` 380, `pickerPreviewW` 560, `pickerOptionsW`
  404, `pickerMediaW` × `pickerMediaH` 512 × 288, `pickerOptionScale` 0,815.
- **Tokens** (`Tokens.wallpaper`): `darkLine`, `darkVignette`, `ruleAlpha`, `darkRuleAlpha`,
  `dotWeave`, `glint` `#E6E1C8`, `inkSquare`, `filterTint`, `filterAmount`, `filterVignette*`,
  `reveal` 1200, `lead` 200, `settle` 450, `duration` 900.
- **Configuração** (`config/defaults.json`, sobrescrita pelo `shell.json` do usuário):
  `wallpaperFolder`, `wallpaperTransition` (`camouflage`), `camouflage` (`cell` 24, `trail` 2600,
  `glitch` 2) e `reduceMotion`. A última escolha feita (no seletor ou por comando) vale mais que a
  config e fica no arquivo de estado.
- **Comandos:** `qs ipc call wallpaper list | set <id> <monitor|all> | next | prev | transition
  <tipo> | camouflage <cell> <trail> <glitch> | filter <caminho> <true|false> | picker
  <open|close|toggle> | dump`.

## Créditos

Componentes, tokens e anatomia baseados em **"NieR: Automata - UI"**, de **tyleo**,
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). As páginas de screenshots do jogo
desse arquivo não foram usadas. NieR:Automata é marca da Square Enix; o YoRHa-OS é um projeto de
fã, sem relação com ela.
