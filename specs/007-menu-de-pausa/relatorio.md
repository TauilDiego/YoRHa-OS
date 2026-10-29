# Relatório da implementação: Menu de pausa (spec 007)

**Data:** 2026-10-27 a 2026-10-29.

**Onde:**
- branch `007-menu-de-pausa` do repositório público, com as frentes `007-apps` (A), `007-janelas` (B)
  e `007-energia` (C) juntadas na T043;
- branch `lab-007` do repositório privado (laboratório), com os blocos das três frentes no
  `lab/check-007`.

**Lab:** VMs `teste-a`, `teste-b` e `teste-c`, cada uma com 2 núcleos e 4 GB (limite do dono), no
máximo 3 do lab ligadas ao mesmo tempo, boot no perfil hidpi pra ter os dois modos. Tudo dentro de
sessões `lab/perf`.

**Status:** as 48 tarefas estão feitas. Falta a aprovação visual do dono (SC-012), com a imagem de
revisão abaixo.

## O que ficou pronto

- **Moldura com abas (US1):** o popup da 003 com `APPS`, `WINDOWS`, `SYSTEM` e `POWER`, a data e a
  hora no título, Tab/Shift+Tab dando a volta, `ALT + Escape` (geral) e `ALT + I` (SYSTEM), a pipa
  guardada por aba enquanto aberto, os três jeitos de fechar devolvendo o teclado à janela de antes.
- **APPS (US2):** o launcher no layout lista + prévia + opções da 004: PINNED e ALL APPS, busca por
  digitação (nome, nome genérico, palavras-chave, comando, sem acento), o ícone nos 3 estilos
  (`ink` por shader), `Open`, as ações do app, `Workspace` e `Pinned`; a busca sem resultado esconde o
  card Options.
- **WINDOWS (US3):** as janelas reais do Hyprland por área de trabalho (SPECIAL no fim), o mapa da
  área com a janela escolhida em tinta, `Focus`, `Workspace`, `Floating` e `Close` por
  `Hyprland.dispatch`, acompanhando o compositor ao vivo.
- **POWER (US4):** as 6 ações com as capacidades reais do logind, o quadro com o efeito e o motivo,
  o `StatusCard`, o `ConfirmDialog` com os bloqueios (`ListInhibitors`), a ordem de fechar e executar
  da FR-023 e o reboot real provado na VM.
- **Dados reais (US5):** os apps do `DesktopEntries` (um `.desktop` novo em ≈0,3 s), o estado em
  `~/.local/state/yorha-os/apps.json`, as janelas ao vivo.
- **Opções (`SYSTEM › Pause menu`):** `App icons`, `App order`, `Running app`, `Confirm` e
  `Dialog starts on`, valendo na hora.
- **Acabamento (T043, decisões do dono em 28.10):** a `GroupedList` rola em linhas inteiras (a
  primeira e a última linha à vista nunca ficam cortadas), pelo teclado e pela roda do mouse; a
  `PickerLayout` ganhou `optionsVisible`.
- **Galeria (T044):** a página 4 com as peças novas nos estados do contrato.
- **Design system (T045):** `docs/design-system.md` §9.

## Evidência por critério

| Critério | Resultado | `lab/perf` |
|---|---|---|
| SC-001 | As 7 telas do cenário 1 (4 abas, diálogo de Shut down, busca `fir` e `zzz`) com o `dump` que bate, em 1080 e hidpi (14 shots) | `2026-10-28T235337-vm-teste-a-007-validacao` (`out/007-t046-007-both`); de novo em `2026-10-29T003229-vm-teste-a-007-validacao-acabamento` (`out/007-t046c-007-both`, 76/0) |
| SC-002 | Dois shots seguidos de cada aba: 0 px, nos dois perfis | idem |
| SC-003 | `ALT+Escape`, `k`, `i`, `t`, Enter (5 teclas reais) abrem um kitty real ≈0,35 s depois do Enter | idem |
| SC-004 | As 10 consultas do roteiro trazem o esperado em primeiro; `zzz` com `No apps match.` | idem |
| SC-005 | Abre em ≤ 0,3 s; a sequência de teclas e os três fechamentos com o kitty voltando ao foco | idem |
| SC-006 | 3 kitty reais em 2 áreas: Enter em C, B movida pra 02, A fechada em ≈0,3 s, `hyprctl` a cada passo | idem |
| SC-007 | Com fixtures: Lock/Suspend sem diálogo, os outros com diálogo (Cancel por Esc, clique fora e `Cancel`), Hibernate apagado, o `pacman` no diálogo; sem fixtures, o `Lock` pelo sinal do logind; o reboot real zera o `/proc/uptime` | idem e `2026-10-28T235417-vm-teste-c-007-validacao` (`out/007-t046-007-reboot`, 3/0) |
| SC-008 | Bloco `burst` do `check-007` (sem fixtures): no ↓ em APPS a pipa volta inteira 71 ms depois de sumir (critério: até 0,21 s, decisão do dono em 29.10); trocando de aba, os vãos entre as abas sem tinta em todos os quadros | `2026-10-29T003229-vm-teste-a-007-validacao-acabamento` (`out/007-t046c-007-both/sc008-down.txt`, `sc008-gone.png`, `sc008-back.png`) |
| SC-009 | `yorha-test.desktop` em ≈0,3 s com o menu aberto; fixado e usado continua depois do `pkill -x qs`; `~/.config/yorha-os/` intacto | `2026-10-28T235337-vm-teste-a-007-validacao` |
| SC-010 | Log do roteiro inteiro com 0 erros e 0 avisos de QML (a única linha é a `expected-warn` do app de comando inexistente); `qmllint` dentro da VM limpo (os 12 falsos positivos conhecidos) | idem e `…-teste-c-007-validacao` (`out/007-t046-qmllint.txt`) |
| SC-011 | Galeria, página 4, nos dois perfis (dois shots iguais, o Tab seguinte volta à 1) | `2026-10-29T000458-…` (`out/007-t046-007-gallery`) |
| SC-012 | **Aguarda o dono:** `out/007-revisao-sc012.png` (mockup × VM 1080 × VM hidpi nas 7 telas, e os 3 estilos de ícone) | `2026-10-29T001018-container-teste-a-007-imagem-de-revisao-sc-012` |
| SC-013 | Cada opção de `Pause menu` muda na hora: os 3 estilos (shots `apps-icons-*`), a ordem, o Enter num app com janela, `Every action`, `Action` | `2026-10-28T235337-vm-teste-a-007-validacao` |

**Sem regressão (T046):** `check-u1` 15/0 e `check-004` 58/0 (`2026-10-28T235337-vm-teste-b-007-validacao`,
`out/007-t046-u1`, `out/007-t046-004`), `check-003` 25/0 em 1080 e em hidpi
(`…-teste-c-007-validacao`, `out/007-t046-003-1080`, `out/007-t046-003-hidpi`).

**Imagens de referência:**
- `check-003` 1080, contra `out/007-us1-003`: iguais, fora a `gallery-p2` (o contador da galeria
  passou de 2/3 pra 2/4, T044) e a `sc004-open` (1 nível, já variava entre as referências antigas).
- `check-003` hidpi: **a referência passa a ser `out/007-t046-003-hidpi`**. A antiga
  (`out/007-final-003-hidpi`) era de antes da T022; contra a da T043 (`out/007-t043-003-hidpi`) só
  mudam a `gallery-p2` (2/3 → 2/4) e a `sc004-open` (7 px, o kitty real atrás do painel).
- `check-004`, contra `out/007-t043c-004`: a lista do seletor igual em todos os shots; os dois que
  rolam (`us2-filtro-off`, `us2-video`) mudaram na T043 só pelo corte (antes o título `SCENES`
  aparecia cortado no alto); a `galeria-p3` muda pelo contador (3/3 → 3/4); o resto é o fundo
  animado e diferenças de 1 nível na barra entre VMs.

**Bordas (cenário 15), todas no `check-007`:** `pause-empty`, `pause-long` (rolagem em linhas
inteiras, a roda em 14 passos sem corte e com o título esperando o item, reticências, dois monitores,
SPECIAL), a recusa (`pause-refuse`), o comando inexistente, o seletor fechando o menu e
`pause-broken` (bloco `broken`: erro curto em APPS, WINDOWS e POWER, APPS sem o card Options e sem
o traço da lista vazia, SYSTEM anda; os avisos da fixture quebrada marcados `expected-warn`).

**Acabamento da T046 (dono, 29.10):** `check-007` 76/0 nos dois perfis, `check-004` 58/0 e
`check-003` 25/0 em 1080 (0 px contra `out/007-t046-003-1080`). No `check-004`, a lista do seletor
fica igual, fora a `sc007-seletor-nova`: com a imagem nova, o título `VIDEO` ficava sozinho embaixo
(o `Videos` não cabia) e agora espera o item, que é a regra nova.

## Decisões e desvios

- **Frentes em paralelo (constituição VI):** A, B e C em worktrees e VMs próprios, juntadas na T043
  sem conflito de código (só o `tasks.md`).
- **As quatro páginas criadas junto com o menu** (T016, R1 revisto): a APPS desenha um ícone só.
- **Altura das páginas por `startY`** (o Qt recusa `top`), ícones de teste coloridos, fixture de
  hibernação `na` (decisões do dono, 28.10).
- **`nier-ui-run` ativa o `xdg-desktop-portal` antes do primeiro `qs`** (decisão do dono, 28.10): o
  aviso `qt.qpa.services` do boot sumiu.
- **T043 (dono, 28.10):** rolagem em linhas inteiras (primeira e última linha) também pela roda;
  `PickerLayout.optionsVisible` só na busca sem resultado; a POWER continua com as colunas próprias
  (o card da direita é o `StatusCard`, a lista fica `selected` e ignora o ponteiro com o diálogo
  aberto, e o Enter do rodapé tem o nome da ação).
- **A roda do mouse** não fazia nada na lista; agora rola uma linha por passo, só quando a lista não
  cabe (sem rolagem, nada muda na 003/004), e a pipa que sai da vista vai pro item inteiro mais perto.
- **`PopupFrame.hoveredTab`** (T044): só pra galeria mostrar uma aba `hovered` sem o ponteiro.
- **Contador da galeria:** as páginas passaram a 2/4, 3/4 e 4/4.
- **SC-008 "até 0,21 s"** no lugar de "≈240 ms" (decisão do dono, 29.10; o blink de 240 ms da
  pipa continua como o desenho da animação).
- **T022 rodou com a VM de 4 núcleos** (registrado na evidência da fase 3), acima do limite de 2 do
  dono; as validações seguintes usaram 2.

## Correções feitas no caminho

- O `PauseMenu` deixava o Delete e outros caracteres de controle irem pra busca (T028).
- O `AppIcon` procura o `.qsb` antes, sem os avisos repetidos do Qt (T024).
- A última linha da `GroupedList` primeiro exigia caber com o espaço dos trilhos, e o seletor da
  004 perdia o `Videos`; agora a linha inteira basta (T043).
- A galeria página 4 passava da borda em 16:10; a coluna do diálogo ficou mais estreita (T044).
- O bloco `gallery` do `check-007` falhou uma vez em hidpi pelo desenho do ponteiro; o roteiro agora
  tira o ponteiro do caminho antes dos shots (T046).
- `pkill -f` dentro do `lab/ssh` (ou um `pgrep -f` num laço de espera) casa com a própria linha de
  comando: use um padrão ancorado (lição registrada no `lab/README.md`).

## Análise (T048, `/speckit-analyze`)

Corrigidos nos artefatos:
- **I1** (inconsistência, MEDIUM): SC-001 dizia "6 telas" e "12 screenshots", mas lista 7 por perfil
  → 7 e 14 na spec, no quickstart e na T047.
- **I2** (MEDIUM): a FR-009 não dizia que o card Options some na busca sem resultado → acrescentado
  (decisão do dono, T043).
- **I3** (MEDIUM): o caso de borda da rolagem não falava da última linha nem da roda → acrescentado.
- **I4** (LOW): o `plan.md` ainda dizia "Loaders por aba" → as 4 páginas criadas com o menu (R1).
- **I5** (LOW): o caminho da worktree privada e o status no topo do `tasks.md` estavam velhos.
- **C1** (cobertura, MEDIUM): o quickstart marcava o cenário 9 (SC-008) e o `pause-broken` como
  automáticos (⚙), mas o `check-007` não os tinha → marcados como manuais na T048 e, depois, a
  pedido do dono, automatizados (blocos `burst` e `broken`) e desmarcados.
- **L1** (LOW, lab): o uso do `check-007` listava blocos `options` e `edges` que não existem.

Sem violação da constituição; todas as FR e SC têm tarefa.

## Custo no host (`lab/perf`, T046)

| Sessão | Duração | CPU acima da base | RAM (RSS do QEMU) |
|---|---|---|---|
| `teste-a` (`check-007` inteiro, 2 perfis) | ≈10 min | +6,8 pp em média | ≈3,1 GB |
| `teste-b` (`check-u1`, `check-004`) | ≈10,5 min | +6,7 pp | ≈2,8 GB |
| `teste-c` (`check-003` 1080 e hidpi, `qmllint`, reboot) | ≈6,6 min | +3,5 pp | ≈2,7 GB |

As três rodaram juntas; a RAM usada do host foi a ≈19,2 GB no pico, sem pressão relevante (PSI de
memória 0,1 s).

## Pendências pro dono

1. **SC-012:** aprovar `~/.local/share/nier-lab/out/007-revisao-sc012.png` (o mockup foi renderizado
   no container `nier-lab-chromium`; as peças estão em `out/007-revisao/`).
2. **Respondidas pelo dono (29.10, "os 5 como recomendado") e feitas:** card Options escondido na
   APPS sem dados; sem o traço de 7 px da lista vazia; título de grupo sozinho embaixo escondido
   (vai com o item); SC-008 "até 0,21 s"; a rajada e o `pause-broken` no `check-007`.
3. **S3:** o instalador tem que criar `~/.local/share/applications/` antes de subir o shell (no
   `PLAN.md` e nas premissas da spec).
