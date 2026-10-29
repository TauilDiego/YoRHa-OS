# Feature Specification: Ajustes de UI

**Feature Branch**: `010-ajustes-de-ui` (sai da `main` com a 007 e a 006 mescladas)

**Created**: 2026-10-29

**Status**: Rascunho. Junta os ajustes pequenos de UI que o dono pediu em 29.10. Ainda não foi
disparada: quando for, passa pelo fluxo normal do Spec Kit (specify → plan → tasks) a partir desta
lista.

**Input**: Pedidos do dono em 29.10.2026, na revisão da 007 e nas pendências antigas da 004.

## Itens

### A. Régua do papel de parede igual à da barra

A linha de baixo da cena `rules` do papel de parede (spec 004) está no tamanho do jogo (s=1), e a
régua da barra (spec 001/004) está em s≈0,70. O dono pediu pra **igualar as duas** (29.10). Qual
tamanho vence sai do `specify`, com as duas versões lado a lado pro dono escolher.

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

## Como o dono revisa

Cada item entrega **duas imagens, antes e depois**, das mesmas telas e no mesmo perfil (1080 e
hidpi), e elas são abertas no Chrome do dono pra ele ver o que mudou. A revisão final vai numa
página de artefato, como nas outras specs.

## Fora daqui

- Hyprland 0.57: fica pra depois (dono, 29.10).
- O filtro de cor do papel de parede, mais frio que o mockup, foi aprovado como está (dono, 29.10).
- O feedback do cursor (polegares das mãos, formato "move") continua pendente com o dono; se
  chegar antes desta spec ser disparada, entra como item D.
