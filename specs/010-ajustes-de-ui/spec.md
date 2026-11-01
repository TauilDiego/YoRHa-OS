# Feature Specification: Ajustes de UI

**Feature Branch**: `010-ajustes-de-ui` (sai da `main` com a 007 e a 006 mescladas)

**Created**: 2026-10-29

**Status**: Rascunho. Junta os ajustes pequenos de UI que o dono pediu em 29.10. Ainda não foi
disparada: quando for, passa pelo fluxo normal do Spec Kit (specify → plan → tasks) a partir desta
lista.

**Input**: Pedidos do dono em 29.10.2026, na revisão da 007 e nas pendências antigas da 004; o item F
em 01.11.2026, depois da 013.

## Itens

### A. Régua do papel de parede igual à da barra

A linha de baixo da cena `rules` do papel de parede (spec 004) está no tamanho do jogo (s=1), e a
régua da barra (spec 001/004) está em s≈0,70. O dono pediu pra **igualar as duas** (29.10).

**Decidido (29.10):** vence o tamanho do jogo (s=1). O dono comparou as duas na proposta do login
(artefato 28209760 "YoRHa-OS Login: proposta", v3.1, com a régua de cima no lugar da da barra) e
disse que a de baixo "tá muito melhor". A barra passa a desenhar a régua em s=1.

Fica pro `specify` resolver o encaixe: em s=1 o padrão da régua desce 28 px, e na barra de 68 px a
soma (aba 33 + vão 12 + régua 28 = 73) passa da altura. Os caminhos: subir a barra pra ~73 px,
encurtar o vão, ou deixar o padrão pendurado abaixo da zona reservada, por cima das janelas.

### B. Rodapé do painel com o diálogo de confirmação aberto

No POWER (spec 007), com o diálogo "Shut down?" (ou Log out, Reboot) aberto, o rodapé do painel
continua mostrando as teclas da lista (`Enter Shut down`, `Tab Next tab`, `Esc Close`), além do
rodapé do próprio diálogo. O ajuste: esconder (ou apagar) o rodapé do painel enquanto o diálogo
estiver aberto. O dono não tem objeção (29.10).

### C. Opção de usar o cursor padrão do sistema

O tema de cursor do projeto (`system/cursors/yorha-cursors`, spec 002) tem que ser opcional. No
System Settings (`ALT + I` no lab, `SUPER + I` em instalação real), uma opção troca, na hora, entre
o cursor YoRHa (padrão) e o cursor normal do sistema, sem a personalização. Segue a regra do dono
de implementar alternativas como opções trocáveis no System Settings.

### D. Uma animação de carregamento só, a do cursor

O dono definiu (29.10): o anel de carregamento do tema de cursor (`Loading_Circle`, em
`system/cursors/yorha-cursors/gen/fam_loading.py`, quadros do NieR Cursors da Beinsezii, MIT,
recoloridos) é **a** animação de carregamento de quase tudo no sistema. Isso vale pro Plymouth, pro
SDDM enquanto entra, pro shell (abrindo app, aplicando configuração ou papel de parede) e pro bloqueio
conferindo a senha. Entregas:

- um componente único no design system, que todo lugar de espera usa;
- duas variantes de cor, geradas pelo mesmo build do cursor: tinta sobre papel e clara sobre escuro
  (pras telas e faixas escuras);
- os quadros também em sequência de PNG, pro Plymouth.

### E. Número do volume colado na barra (OSD da 008)

No OSD de volume (spec 008), o número da porcentagem fica muito perto da barra de volume. O dono pediu
(29.10) pra afastar os dois. Vale olhar junto o OSD de brilho e o de microfone, que usam a mesma peça.

### F. Transição de papel de parede com os triângulos do menu

O dono pediu (01.11) que o efeito de triângulos que abre e fecha o menu (spec 013,
`popup/shaders/triangles.frag`) vire mais uma transição do papel de parede (spec 004), ao lado de
camouflage, wipe, tiles e crossfade.

O dono também pediu um rastro opcional, como o da camouflage: a troca começa numa onda a partir de
um ponto sorteado perto do meio da tela, e atrás da frente ficam as bordas dos triângulos (claras,
com as cópias vermelha e ciano) apagando aos poucos.

As duas peças já existem:
- **os triângulos (013, `TriangleReveal.qml`):** a grade de 240×120 px do jogo com bordas a 45°, as
  cores e a ordem sorteada por célula;
- **a onda e o rastro (004, modo camouflage de `shaders/transition.frag`):** a origem sorteada
  (meio da tela ± 15%) e os contornos que somem em `trail` ms.

Vira um modo novo no `transition.frag` que junta as duas. Ele só roda durante a troca, como os
outros: parado, não custa nada.

A decidir no `specify`, um ponto por vez:
- a ordem das células: sorteada como no menu, em onda a partir do ponto, ou as duas como opção;
- o rastro: ligado ou desligado por padrão, e se usa o ajuste "Trail" da camouflage (400 a
  4000 ms) ou ganha um próprio;
- os quadros escuros que algumas células mostram no menu: entram ou não;
- "Reduce motion": a troca é instantânea, como nas outras transições.

As variações viram opções trocáveis no System Settings, com a recomendada como padrão.

## Como o dono revisa

Cada item entrega **duas imagens, antes e depois**, das mesmas telas e no mesmo perfil (1080 e
hidpi), e elas são abertas no Chrome do dono pra ele ver o que mudou. A revisão final vai numa
página de artefato, como nas outras specs.

## Fora daqui

- Hyprland 0.57: fica pra depois (dono, 29.10).
- O filtro de cor do papel de parede, mais frio que o mockup, foi aprovado como está (dono, 29.10).
- O feedback do cursor (polegares das mãos, formato "move") continua pendente com o dono; se
  chegar antes desta spec ser disparada, entra como item D.
