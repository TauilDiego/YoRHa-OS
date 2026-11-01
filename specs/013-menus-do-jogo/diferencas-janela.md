# Diferenças esperadas do modo janela parado (T053, FR-017)

Feito na junção, em 01.11, na VM `t013-j4`, perfil 1080. As mesmas 17 telas foram capturadas duas
vezes, paradas, no modo janela e com os dados de teste (`fixtures/pause-default.json`, que congelam o
relógio e ligam o `Tokens.instant`):
- **antes:** o shell da fundação (`e3c8545`), antes das frentes;
- **depois:** o shell da junção, com as correções.

A comparação é com `lab/diffshot`, em pixels diferentes. A evidência fica em
`~/.local/share/nier-lab/out/013-juncao-antes-depois/` (`antes/`, `depois/`, `diffs.txt` e os recortes
em `recortes/`).

## Por tela

| Tela | Pixels | O que muda | De onde |
|---|---|---|---|
| Menu, APPS | 2 228 | A aba LOG na barra de abas | US8 (B) |
| Menu, WINDOWS | 2 214 | A aba LOG | US8 (B) |
| Menu, SYSTEM (Display) | 10 299 | A aba LOG; as abas se deslocam | US8 (B) |
| Menu, POWER | 9 758 | A aba LOG; as abas se deslocam | US8 (B) |
| SYSTEM › Sound | 14 759 | + Interface volume, Sound folder, Use our sounds, Boot and login sounds (9 opções). Sem Typing sound (decisão do dono) | US5 (D) |
| SYSTEM › Appearance | 15 783 | + Menu presentation (Floating panel), entre Bar contrast e Vignette | US4 (B) |
| SYSTEM › Keyboard | 10 731 | Layout ("US Internatio…") vira Layouts ("US ▸"), a lista com a janelinha | US6 (C) |
| SYSTEM › Network | 10 237 | Só a aba LOG. O 4º valor de Network (`guest`) aparece só na janelinha | US6 (C) |
| Log | 66 076 | O popup "LOG -Transmissions" vira a aba "LOG -Text Log", com a barra de abas e "Tab Next tab" no rodapé. A coluna de valor das opções do log é uma só (T057) | US8 (B), T057 |
| Seletor de papel de parede | 69 | Os valores das opções (All monitors, Camouflage) andam 1–2 px | `ScrollingLabel` nos valores (A, FR-012) |
| Galeria 1 | 0 | — | — |
| Galeria 2 | 106 | Os valores das linhas de opção andam 1–2 px | `ScrollingLabel` (A) |
| Galeria 3 | 33 | Idem, nas opções do seletor em miniatura | `ScrollingLabel` (A) |
| Galeria 4 | 12 977 | O véu do diálogo: de tinta a 55% pra preto a 20% (×0,8 do jogo) | FR-010 (A) |
| Galeria 5 | 0 | — | — |
| Galeria 6 | 137 | As opções do log com a coluna de valor única | T057 |
| Galeria 7 | 76 469 | A lista e o título se mexendo (A) e a janelinha simples e a múltipla (C), novas na página | A, C |

## O que não aparece numa tela parada com dados de teste

Com os dados de teste, o `Tokens.instant` liga e os efeitos param. Fora dos testes, o modo janela muda
também nisto, de propósito:
- **Pulso:** a linha "viva" e a aba aberta pulsam (FR-002).
- **Texto que não cabe:** rola no lugar do "…" (FR-012). Com Reduce motion, continua cortado.
- **Fundo:** o papel de parede para com um menu aberto (FR-011).
- **Rótulos longos:** Sound › "Boot and login sounds" corta com "…" na tela parada com dados de teste;
  com o movimento ligado, rola.

## Achados do antes e depois, corrigidos na junção

- **Subtítulo velho com `Tokens.instant`:** WINDOWS com "-Launcher", SYSTEM com "-Open Windows",
  POWER com "-Settings". O `PageHeader` copiava o subtítulo antes do binding atualizar. Corrigido em
  `5a1e9e9`.
- **Galeria 7:** a lista e o título da frente A ficavam embaixo das janelinhas da frente C. Corrigido no
  mesmo commit.
