# Relatório da 011: boot e login

Branch `011-boot-e-login`, de 29.10.2026. Spec, plano e tarefas aprovados pelo dono no mesmo dia. A
execução teve a fundação e a sondagem (eu), três frentes em paralelo (A boot, B login, C
instalação), cada uma com worktree e VM próprias, e a junção (eu). 48 das 50 tarefas estão feitas; as
duas que faltam (T049 e T050) são o fecho com o dono. Nada foi pra `main`.

## O que ficou pronto

- **Boot (Plymouth, US2 e US5).** A lista de checagens com as etapas reais do boot (57 padrões no
  catálogo, o resto em linhas genéricas por grupo), a película, a lente, as faixas de interferência
  com o rasgo cortando a linha, o anel de carregamento claro, a marca d'água, as falhas em `[FAIL]` e
  o cursor `_` num boot que espera. A saída leva 0,4 s, ou 0,9 s quando uma etapa falhou. No desligar
  e no reiniciar, só a faixa. De 30 a 36 quadros/s na VM. Texto só em ASCII, porque é o que o
  initramfs desenha. A fonte é uma instância estática da M PLUS 1, peso 700.
- **Login (SDDM, US1 e US3).** O protótipo aprovado (v3.2) em QML no greeter Qt 6, nos dois perfis.
  Tem a lista com varredura e pipa, a senha em quadradinhos com o "…", o "Other user…", a sessão
  ◂ ▸, Reboot e Shut down com confirmação, o rasgo na senha errada, a mensagem do PAM quando a conta
  trava e as opções do tema. A entrada depois do boot é faixa, glitch e papel. Ela é cortada por
  tecla, Enter ou clique, e na volta da sessão vira só um fade. Não há tela de boas-vindas (o dono
  tirou: o SDDM fecha o login 32 ms depois de aceitar a senha).
- **Passagem.** O script `yorha-boot-handoff` (que o drop-in do `sddm.service` chama) pega as falhas
  de última hora, marca o boot, avisa a lista, espera a saída, limpa o tty1 e fecha o Plymouth sem
  reter a imagem (com `--retain-splash`, o X trava no VT 2; ver `sondagem.md`).
- **Senha do disco (US4).** Um cartão no estilo do login sobre a tela de boot, com o "…" e o "Try
  again.".
- **Instalação (FR-040 a FR-042).** O `yorha-os-boot-login`, com `install`, `uninstall` e `status`. Ele
  faz backup e manifesto com hashes, é idempotente, cobre systemd-boot e UKI, e pra outro bootloader
  mostra o passo manual. O `uninstall` volta os arquivos com o hash de antes.

## Evidência (VM do lab, `teste-011` e as VMs das frentes)

| Critério | Resultado | Onde |
|---|---|---|
| SC-001 sem console do ligar ao login | nenhum quadro com console | `bootcap-teste-011-20261029-201223` |
| SC-002 atraso do boot (limite 1 s) | +0,80 s (3,05 → 3,85 s até o greeter, 3 boots cada) | `lab/011/boot-timing` |
| SC-003 senha durante a entrada | a entrada some e a sessão abre | `check-intro` 13/0 (1080 e hidpi) |
| SC-004 login certo | 10/10 | frente B, `check-login` |
| SC-005 login errado | 10/10 | frente B, `check-login` |
| SC-006 estresse das animações | 20/20 | `stress-greeter-teste-011-20261029-205250` |
| SC-007 journal limpo | 10 ciclos, 0 erros ou avisos dos temas | `check-journal-teste-011-20261029-205637` |
| SC-008 tema quebrado | o tema embutido do SDDM entra; 4/0 | `check-fallback-teste-011-20261029-210252` |
| SC-009 Reboot e Shut down | 8/0 | `check-power` (junção, 1080) |
| SC-011 desfazer | 74/0, hashes iguais aos de antes | frente C, `check-undo` |
| Outros | `ds-sync` 49/0; `check-login` 6/0 nos dois perfis; UKI 13/0; saída 1 sem SDDM 5/0 | |
| US4 | cartão, senha errada, "Try again.", senha certa, boot até o login | `bootcap-teste-011-20261029-211915` |

Relatórios do `lab/perf` (em `YoRHa-OS-relatorios/runs/`, 29.10):
- **Fundação:** `…165111-…-t002-boot-iso`, `…165505-…-t006-sondagem-r0`, `…183743-…-t008-anel-em-quadros`.
- **Frentes:**
  - A: `…190305-…-t025-t029…`, `…192648-…-t030-validar-a-us2…`, `…193823-…-t043…`;
  - B: `…194238-…-t022-login-1080`, `…194602-…-t038-t039…`;
  - C: `…191334-…-t035-check-011-undo-2a-rodada`, `…191751-…-t033-caminho-uki`.
- **Junção:** `…201148-…-t036-integracao-pelo-modulo`, `…205239-…-t040-…-final`,
  `…205626-…-t047-journal-10-ciclos`, `…210241-…-t047-fallback`, `…210319-…-checagens-da-juncao-1080`,
  `…210841-…-checagens-da-juncao-hidpi`, `…211704-…-t046-senha-do-disco-num-boot-real`.

Em todos, o impacto no host ficou de 0 a 8 pontos de CPU acima da base, e sempre houve no máximo 4
VMs ligadas.

## Decisões tomadas no caminho (pro dono confirmar na revisão)

- **Boot:**
  - cabeçalho "STARTUP -System check";
  - linhas "… [ OK ]" e "[FAIL]";
  - marca d'água "YoRHa-OS / SYSTEM INTERFACE" mantida;
  - peso 700;
  - falha leva a saída pros 0,9 s;
  - num boot rápido aparecem poucas linhas (o dono escolheu manter assim).
- **Login:**
  - o anel da conferência fica na linha de mensagem do cartão;
  - `clock=small` com metade do tamanho, e `clock=none` esconde relógio e data;
  - a faixa abre com o ponto e a linha de CRT, como no jogo;
  - qualquer tecla corta a entrada e já vale (uma seta move a seleção);
  - a mensagem do PAM só aparece quando diz mais que a falha comum;
  - a cor da faixa é a medida no jogo, nos dois temas.
- **Instalação:**
  - a pasta do Plymouth é cópia (o hook do mkinitcpio não segue link de pasta);
  - o `plymouthd.conf` entra entre os editados;
  - o `uninstall` parcial deixa o arquivo mudado e sai com 4;
  - os backups ficam.
- **Correções da junção:**
  - o que se digita antes da lista de usuários carregar vai pro campo de senha;
  - a marca de boot só é gravada com o Plymouth no ar;
  - a ajuda de logout do lab escolhe a instância mais nova do Hyprland.

## Limites e pendências

- **Raiz criptografada:** não foi testada com o pedido de senha dentro do initramfs. O teste usou um
  volume do `crypttab`, pedido depois da troca de raiz. O texto do cartão é ASCII, então deve
  funcionar igual.
- **Vários monitores** (FR-036): implementado, mas não testado; o `--soft` tem uma saída só.
- **UKI:** conferida no conteúdo da imagem, sem boot.
- **Máquina de verdade:** tudo foi testado em VM. Instalar na máquina do dono é decisão dele, depois
  da homologação.
- **Depois do merge da 008 e da 010:** juntar as cópias do design system do login e do shell num
  núcleo sem Quickshell (research R3).
- **T050:** PLAN, mapa do projeto e Central, depois da aprovação.
