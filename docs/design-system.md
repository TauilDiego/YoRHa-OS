# Design system do rien-OS

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
borda esquerda reserva espaço pro cursor; no rien-OS, as abas não têm seletor (ver §5).

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
  - as abas (o Figma põe o seletor na aba em foco; no rien-OS, não, ver §5);
  - a régua pontilhada embaixo.
- **Lista com cursor:** faixas verticais + itens + barra de rolagem + seletor.
- **Card de status:** pares rótulo/valor alinhados, medidor, fileira de quadrados vazios e um
  rodapé centralizado (ex.: "NO ERROR").
- **Barra de dicas** (rodapé da página): a instrução à esquerda ("Select item."), as teclas à
  direita (caixas escuras com a letra) com a ação, e a régua pontilhada embaixo.

## 5. Desvios pro desktop (decididos em 2026-10-27)

| Ponto | No jogo (1080p) | No rien-OS |
|---|---|---|
| Altura da barra do topo | Aba de 47px, texto 27px | **Revisado (2026-10-27):** barra de 68px, configurável de 28 a 96. De cima pra baixo: 3px de papel, a aba (33px, `s ≈ 0,70`), um vão de 17px de jogo (12px) e a régua pontilhada **na escala do jogo** (`s × 1,0`: pontos de 4px, padrão de 20px de altura), nítida em pixels físicos inteiros. A aba em foco desce até a régua por uma haste animada (`motion.touch`, 160 ms, logo depois da tinta; recolhe em `motion.untouch`, 120 ms). A versão cheia fica pros menus de tela inteira |
| Escala | Fixa em 1080p | Tokens em medidas do jogo × fator da tela × `uiScale` (ver "Escala") |
| Fontes | Comerciais | M PLUS 1 por padrão; as originais quando estiverem instaladas |
| Alerta | Não existe | `alert` `#8F3A30`, só pra estados críticos |
| Sombra do título | 8,8 fixo | Proporcional ao tamanho do texto (≈15%) |
| Cursor (pipa) | Parado; pula de um item pro outro | **Decidido (2026-10-27):** parado, e pisca ao trocar de item (some e reaparece com ease in-out, `motion.blink` ≈240 ms) |
| Abas da barra | Seletor (pipa) ao lado da aba em foco | **Decidido (2026-10-27):** as abas nunca têm seletor, nem no HUD nem nos menus: só as abas lado a lado. A pipa fica só nos itens de lista |
| Fundo do desktop | Só nos menus | **Decidido (2026-10-27):** o fundo inteiro da área de trabalho é o papel do menu (grid, vinheta, arcos e feixes, com movimento sutil que pode ser desligado), no lugar do wallpaper |
| Vinheta | Em todos os menus | Como no jogo (bordas `#A6A18D`, cantos `#8B8877`), desligável. Nos menus de tela cheia e na tela inteira do desktop: o fundo e o papel da barra do topo formam uma vinheta só, sem emenda (2026-10-27). As janelas, as abas, a régua e os textos ficam por cima, sem vinheta |

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
| Fundo (medido) | — | **M** centro `#C8C3AC`, bordas `#A6A18D`, cantos `#8C8978` (vinheta radial); grão fino, desvio ≈2 níveis em 255 (o rien-OS fica sem, escolha do dono); diagonais ≈20 níveis mais escuras que o papel (≈17% de tinta), em feixes de 2–3 linhas que começam e terminam na tela; arcos duplos (dois círculos a ≈6 px), centro fora da tela | Seguir (spec 004) |
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
- **Cursor:** parado. O rien-OS acrescenta um blink suave quando ele troca de item (ver §5).
- **Fechar o menu:** a tela se desfaz em estilhaços triangulares, em ≈300–500 ms.
- **Estado danificado:** aberração cromática e glitch no texto.
- Os tempos ficam em tokens, pra calibrar depois com gravação a 60 fps no laboratório.

## Créditos

Componentes, tokens e anatomia baseados em **"NieR: Automata - UI"**, de **tyleo**,
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). As páginas de screenshots do jogo
desse arquivo não foram usadas. NieR:Automata é marca da Square Enix; o rien-OS é um projeto de
fã, sem relação com ela.
