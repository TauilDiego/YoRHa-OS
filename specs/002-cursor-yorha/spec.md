# Feature Specification: Cursor YoRHa

**Feature Branch**: `001-yorha-base-hud` (vai junto no merge do U1)

**Created**: 2026-10-27

**Status**: Aprovada pelo dono em 2026-10-27; revisada no mesmo dia (desenho próprio, vetorial)

**Input**: Pedido do dono: "o cursor padrão fica feio e muito claro num tema claro; pode
adiantar a implementação de um cursor igual o do jogo, com a setinha e as duas bolinhas embaixo
da parte maior", usando https://github.com/Beinsezii/NieR-Cursors se a licença permitir.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cursor do jogo em todo o desktop (Priority: P1)

O usuário move o mouse e vê o cursor dos menus do NieR: a setinha em forma de pipa, com a
bolinha e os dois losangos embaixo. Os outros formatos (mão em links e abas, I de texto, espera
animada, redimensionar, proibido) seguem o mesmo estilo. O cursor é legível tanto sobre o papel
claro quanto sobre um terminal escuro.

**Why this priority**: O cursor padrão do Hyprland destoa da UI e some sobre o fundo claro, o
que atrapalha até os testes.

**Independent Test**: Na VM, screenshots com o ponteiro sobre o papel, sobre o kitty, sobre uma
aba da barra e dentro do texto do kitty, em 1080p e no perfil hidpi.

**Acceptance Scenarios**:

1. **Given** a sessão aberta na VM, **When** o ponteiro está sobre o fundo, **Then** aparece a
   seta do NieR Cursors, nítida.
2. **Given** o ponteiro sobre o texto do kitty, **When** ele para ali, **Then** aparece o
   cursor de texto do tema.
3. **Given** o perfil 2560x1600 @1,25, **When** o ponteiro aparece, **Then** ele usa um tamanho
   nativo do tema (sem esticar uma imagem pequena).

### Edge Cases

- **Formato que o tema não tem:** cai no Adwaita (`Inherits=Adwaita`).
- **Release do upstream mudou** (hash diferente): a instalação falha com erro claro, em vez de
  instalar outra coisa.

## Requirements *(mandatory)*

- **FR-001**: O tema de cursor padrão MUST ser o **rien-OS Cursors**, com os **39 formatos** do
  NieR Cursors de Beinsezii (MIT), os mesmos aliases e hotspots do original, e o Adwaita de
  reserva pro que faltar. 37 formatos são desenho próprio, vetorial (SVG). Os dois de carregamento
  seguem a FR-007.
- **FR-002**: O estilo MUST ser o aprovado pelo dono na seta (2026-10-27), aplicado a todos os
  formatos por um módulo único (`system/cursors/rien-cursors/gen/style.py`):
  - **forma:** a nave do minigame de hacking do jogo, inclinada pra cima e pra esquerda, com a
    traseira em 75% do comprimento do jogo;
  - **placas:** claras, com chanfro (luz de cima e da esquerda) e contorno de tinta;
  - **frestas:** grossas;
  - **esfera:** cinza chapada `#4B4A43`;
  - **blocos:** claros, com profundidade;
  - **profundidade:** a mesma em tudo, mostrando embaixo e à direita.
- **FR-003**: O cursor MUST ficar nítido e sem serrilhado em qualquer tamanho e escala. Ele é
  entregue como **hyprcursor** (o Hyprland desenha o SVG no tamanho exato), com um **XCursor**
  de reserva gerado dos mesmos SVGs. O tamanho padrão é **48** lógicos
  (`system/cursors/defaults.conf`).
- **FR-004**: Os fontes (geradores Python + SVG) MUST ficar no repositório, pequenos; o tema é
  montado por `system/cursors/build.sh` num container. O único download é o release do NieR
  Cursors pra FR-007, conferido pelo sha256 de `rien-cursors/upstream.lock`.
- **FR-005**: O crédito ao Beinsezii (MIT) MUST ficar em `CREDITS.md` e no `NOTICE` instalado
  junto do tema.
- **FR-006**: Os formatos animados (espera, progresso, proibido) MUST manter a animação no
  hyprcursor e no XCursor.
- **FR-007** (pedido do dono, 2026-10-27): O carregamento MUST ser o do NieR Cursors 1:1, só
  com a paleta trocada, porque é idêntico ao loading do jogo.
  - **`Loading_Circle`** (`wait`): os 90 quadros dela a 60 fps, nos 8 tamanhos (24 a 128), com
    o alfa intacto. A cor passa por uma rampa de claridade: os escuros dela viram `#2F2D28` e
    `#4B4A43`; os claros mantêm a claridade e ganham o tom da paleta.
  - **`Cursor_Loading`** (`progress`): a nossa nave com o círculo pequeno dela, recolorido, por
    cima, na posição e no tamanho dela. A borda de fora do círculo, onde a seta e o losango dela
    passavam por baixo, é refeita a partir do lado limpo dessa mesma borda.
  - **Formato:** os dois são raster (PNG por tamanho), não vetoriais
    (`system/cursors/rien-cursors/gen/fam_loading.py`).

## Success Criteria *(mandatory)*

- **SC-001**: Screenshots na VM mostram a seta sobre o papel e sobre o kitty, a mão sobre uma
  aba da barra e o I de texto no kitty, nas duas escalas.
- **SC-002**: O tema ativo na VM é `rien_cursors` (hyprcursor), sem erros de cursor no log do
  Hyprland.
- **SC-003**: A folha de contato mostra os 39 formatos ao lado dos originais, legíveis em 48 px
  sobre o papel e sobre o terminal.

## Assumptions

- **Onde roda:** só na VM. Na máquina do dono, entra pelo instalador (S3) ou na troca (U7).
- **Histórico:** primeiro foi usado o tema do upstream como estava e depois uma recoloração
  dele. As duas versões foram rejeitadas pelo dono (clara demais; feia e serrilhada), o que
  levou ao desenho próprio vetorial.
- **Marca:** desenho próprio, inspirado no jogo e no tema de Beinsezii (MIT). Nenhum arquivo do
  jogo entra no repositório; as capturas usadas como referência ficam no repositório privado.
