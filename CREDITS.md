# Créditos

## Design

- **"NieR: Automata - UI"**, de **tyleo** ([tyleo.com](https://tyleo.com)):
  - [arquivo na Figma Community](https://www.figma.com/community/file/1598348131070316402/nier-automata-ui);
  - licença: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/);
  - uso: tokens (cores, tipografia, sombras, espaçamentos) e anatomia dos componentes descritos
    em [`docs/design-system.md`](docs/design-system.md), adaptados pro desktop.

## Fontes

- **M PLUS 1**, de The M+ FONTS Project Authors
  ([github.com/coz-m/MPLUS_FONTS](https://github.com/coz-m/MPLUS_FONTS)):
  - licença: [SIL Open Font License 1.1](shell/assets/fonts/OFL.txt);
  - arquivo: `shell/assets/fonts/MPLUS1[wght].ttf` (fonte variável, tirada de
    [google/fonts](https://github.com/google/fonts/tree/main/ofl/mplus1));
  - uso: fonte padrão da UI, no lugar das fontes comerciais do jogo.

## Cursores

- **YoRHa-OS Cursors** (`system/cursors/`): desenho próprio, vetorial, com os 39 formatos e a
  composição do **NieR Cursors**, de **Beinsezii**
  ([github.com/Beinsezii/NieR-Cursors](https://github.com/Beinsezii/NieR-Cursors)), licença MIT
  (Copyright (c) 2020 Beinsezii). Os dois cursores de carregamento usam os quadros renderizados
  dela, recoloridos; o release é baixado no build e conferido pelo sha256. O aviso MIT vai junto
  do tema instalado (`NOTICE`). A seta segue a "nave" do minigame de hacking de NieR:Automata;
  nenhum arquivo do jogo é usado.

## Código de terceiros

Código de outros projetos só entra com licença compatível com a AGPL-3.0 e com crédito aqui e no
próprio arquivo.

- **Hash without Sine**, de **David Hoskins** ([shadertoy.com/view/4djSRW](https://www.shadertoy.com/view/4djSRW)),
  licença MIT (Copyright (c) 2014 David Hoskins): a função `hash` de três linhas em
  `shell/shaders/transition.frag` (os sorteios por célula das transições do papel de parede).

## Marcas

NieR:Automata e YoRHa são marcas da Square Enix. O YoRHa-OS é um projeto de fã, sem afiliação. Não
distribuímos fontes, sons, imagens nem vídeos do jogo.
