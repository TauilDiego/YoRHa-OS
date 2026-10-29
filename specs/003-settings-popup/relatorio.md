# Relatório da implementação: Configurações num popup (spec 003)

**Data:** 2026-10-27.

**Onde:**
- branch `003-settings-popup` (código e docs);
- branch `lab-003` do repositório privado (laboratório).

**Lab:**
- VM `teste-a` (4 GB, 6 CPUs), com boot no perfil hidpi pra ter os dois modos;
- tudo dentro de sessões `lab/perf`.

**Status:** as 41 tarefas estão feitas. Falta só a aprovação visual do dono (SC-009), com a
imagem de revisão abaixo.

## O que ficou pronto

- **Atalho:** `ALT + I` na VM (`SUPER + I` nas instalações, S3/U7) e o alvo IPC `settings`
  (`open`, `close`, `toggle`, `isOpen`, `dump`, `reset`) abrem o popup no monitor em foco.
- **Moldura:**
  - o resto da tela fica sob tinta a 55%, sem desfoque;
  - o painel de papel (84% da tela) tem vinheta, sombra chapada, título `SYSTEM -Settings`,
    réguas, a versão no rodapé e as teclas que valem agora;
  - fade de 150 ms na abertura;
  - fecha na hora pelo atalho, pelo Esc ou pelo clique fora, e o teclado volta pra janela
    anterior.
- **Três colunas do mockup:**
  - categorias à esquerda (faixas verticais, pipa clara quando perdem o foco);
  - as opções da categoria no meio;
  - o quadro de descrição à direita.
- **Foco de duas colunas:**
  - pelo teclado, com as regras da FR-010;
  - pelo mouse (FR-011): hover, clique, setas ◂ ▸ e trilha do slider.
  - A pipa fica parada e pisca ao trocar de item.
- **Cinco tipos de opção:** liga/desliga, escolha, slider, ação e informação.
  - Valores em memória: ficam ao fechar e reabrir, voltam ao catálogo quando o shell reinicia.
  - Dependências: o Wi-Fi e o Bluetooth apagam as opções que precisam deles.
  - As ações mostram um aviso por 2 s.
- **Catálogo:** `shell/fixtures/settings-default.json`, com 7 categorias e 36 opções, os textos do
  mockup e validação contra o schema. Tem também os casos de borda:
  - catálogo ausente;
  - 14 opções com textos longos;
  - categoria vazia.
- **Design system:**
  - peças novas: `ValueStepper`, `KeyHints`, `OptionRow`, `OptionList`, `DescriptionCard`,
    `PopupFrame` e `PopupWindow`;
  - acréscimos: `Meter` editável/invertido, `CursorList` sem foco/dando a volta/conduzida,
    `ListItem.reserve` e o blink do `Selector` com movimento reduzido.
  - Tudo está na página 2 da galeria (Tab) e na seção 7 do `docs/design-system.md`.
- **Movimento reduzido:** com `reduceMotion` no `shell.json`, o fade e o blink ficam
  instantâneos. Com fixtures, nada anima.
- **Laboratório (`lab-003`):**
  - `lab/check-003 [--only …] [--profile 1080|hidpi]`, com os cenários 1–11 do
    [quickstart](quickstart.md);
  - o `lab/burst` agora grava a hora de cada quadro;
  - README atualizado.

## Evidência por critério

As sessões estão em `~/projects/YoRHa-OS-relatorios/runs/<id>`. A evidência fica em
`~/.local/share/nier-lab/out/`.

| Critério | Resultado | Evidência |
|---|---|---|
| SC-001 | Popup centrado a 84% nas 7 categorias, em 1920x1080 @1 (painel 1613×907 em 154,87) e em 2560x1600 @1,25 (1720×1075 em 164,102). O escurecimento confere pixel a pixel na faixa do HUD: 0,45·fundo + 0,55·tinta, com desvio ≤ 0,9 em 255, sem desfoque. No hidpi, a régua e a faixa saem sem meio pixel | `check-003-final-1080/1080-cat*.png` + `.json`; `check-003-final-hidpi/hidpi*-cat*`; sessão `…161856…validacao` |
| SC-002 | Dois screenshots seguidos do popup aberto: 0 px de diferença, nos dois perfis | `check-003-final-*/sc002-*.png` |
| SC-003 | ↓↓↓ → ↓ → Esc Esc com teclas reais (QMP): Bluetooth → opções → K2 Keyboard → (→ não muda informação) → categorias → fechado, com o `dump` conferido a cada passo | `check-003-final-*/sc003-steps.txt` |
| SC-004 | Abre em 45–99 ms: da tecla enviada até a camada aparecer, medido na VM. Os 3 caminhos fecham em ≈210–370 ms; o clique é medido do host e inclui o ssh. Um `touch` digitado com o popup aberto não chega no kitty; digitado depois de fechar, chega | `check-003-final-*/sc004-*`; sessão `…154645…us1` |
| SC-005 | A pipa some do item antigo e só depois aparece no novo: ≈223 ms em 1080 e ≈238–263 ms em hidpi, estimados pelo ajuste das curvas de cada metade (token: 240 ms). A pipa clara da categoria fica igual em todos os quadros. Com `reduceMotion` a pipa só pula | `check-003-final-1080-s8/` e `-hidpi-s8/` (`sc005-*-frames/`, `times.txt`) |
| SC-006 | Uma mudança de cada tipo, por tecla e por clique: setas, trilha a 1/4 → 25, dependência do Bluetooth (3 apagadas, focáveis, aviso no quadro, ← volta), ação com aviso de 2 s e informação inerte. Os valores ficam ao reabrir e voltam com o reinício | `check-003-final-*/sc006-*`; sessão `…161514…us3` |
| SC-007 | 0 erros e 0 avisos de QML nas duas rodadas; `qmllint` limpo, fora os falsos positivos conhecidos. Ver o aviso do Qt em "Pendências" | `check-003-final-*/log-after-launch.txt`, `qmllint.txt` |
| SC-008 | Página 2 da galeria (Tab) com cada peça nova, nos seus estados e com nome | `check-003-final-1080/gallery-p2.png` |
| SC-009 | **Aguarda o dono.** Imagem de revisão: mockup × VM (1080 e hidpi, mesmo estado), a galeria e as 7 categorias | `~/.local/share/nier-lab/out/003-revisao-sc009.png` |
| Regressão | `lab/check-u1` na branch 003: 15 PASS / 0 FAIL | `check-u1-003/`; sessão `…162932…check-u1` |

## Decisões e desvios

Cada um está registrado no `tasks.md` e, quando muda interface, no contrato.

- **Colunas 300 / 600 / 440, contra 330 / 560 / 460 no plano.** Com 560, "Background motion" e
  outros rótulos do mockup saíam cortados, e o quadro ficava a 24 px das opções. As opções começam
  em x 480 e o quadro em 1124. Atualizei os tokens, o contrato e a R5.
- **Medidas do mockup onde ele diverge das tarefas:** setas de 11×16 e 34 px entre as dicas de
  tecla.
- **Escala do painel:** `s` = o menor entre altura/908 e largura/1612. Em 16:10, só a altura
  fazia o quadro vazar pros lados. A sobra vai pra altura, e o rodapé fica colado embaixo.
- **Sombra do painel em tinta** (`shadow.popup`, 6 px). A `boxShadow` clara do design system
  viraria um brilho sobre o escurecimento.
- **Moldura dividida em `PopupFrame` e `PopupWindow`.** O `PopupFrame` é o desenho; o
  `PopupWindow` é a janela, o teclado e o fade. Assim a galeria mostra a moldura em miniatura.
  Pra 004 a interface não muda.
- **`ListItem.reserve`** (novo): o rótulo corta com reticências antes do valor. Os rótulos de
  lista agora sempre cortam na borda da faixa (antes vazavam).
- **Apagada + em foco:** um véu de tinta a 45% sobre a faixa deixa o texto claro a 55%, como no
  mockup. Assim o `ListItem` não precisou de um estado novo.
- **Hover:** só move o foco quando o ponteiro se mexe de verdade. O Qt reenvia hover a itens que
  surgem sob um ponteiro parado (o popup abrindo, as linhas de outra categoria), e isso roubava o
  foco do teclado.
- **Categoria vazia:** sem `→ Open` no rodapé (só as teclas que valem). A FR-015 foi ajustada.
- **Amostras da galeria tiradas do próprio catálogo,** sem duplicar textos no `Strings`.
- **Frentes `[P]` em sequência:** as três foram feitas por um agente só, numa VM só, porque a RAM
  do host só comporta uma VM por agente (a `teste-b` está com a 004).

## Correções feitas no caminho

**Na UI:**
- `flatMap` não existe no JavaScript do QML (V4).
- O modo proporcional de altura de linha do Qt multiplicava o espaçamento da fonte; passou a ser
  `FixedHeight`, como o CSS.
- Um laço de binding de largura no `OptionRow`, por medir o próprio texto cortado e pela
  `implicitWidth`.
- O `Flickable` desfazia o binding do `contentY`; a coluna virou um item recortado que rola em
  linhas inteiras.
- `scrollY` virava NaN quando `follow()` rodava com `pitch` 0.
- `Array.isArray` dava falso pra lista de opções.

**No laboratório:**
- A medição do blink cortava as pontas suaves das curvas; agora é estimada pelo ajuste delas.
- No hidpi, os recortes estavam em px lógicos, e o `grim` devolve px físicos.
- A checagem de meio pixel confundia a sombra da faixa com um degrau.

## Análise (T041, `/speckit-analyze`)

Feita com `SPECIFY_FEATURE_DIRECTORY=specs/003-settings-popup`; não há `extensions.yml`.

| ID | Categoria | Gravidade | Onde | Achado | O que foi feito |
|---|---|---|---|---|---|
| I1 | Inconsistência | MÉDIA | spec.md (Status), plan.md (Constitution Check V) | Spec "aguardando aprovação" e plano "⏳", mas os dois foram aprovados | Status e ✅ atualizados |
| I2 | Inconsistência | MÉDIA | spec.md US1, FR-007 | "papel com grid": o dono tirou o grid de todo o YoRHa-OS em 2026-10-27, e a implementação não tem grid | Texto ajustado |
| I3 | Inconsistência | MÉDIA | spec.md (Suposições), research.md R11 | "movimento reduzido ainda não existe": `Settings.reduceMotion` entrou com a 004 e o popup respeita | Texto ajustado, com o mecanismo (`Tokens.instant`) |
| I4 | Inconsistência | MÉDIA | quickstart.md | Preparação sem o boot hidpi, `lab/burst <região> 16` com a assinatura antiga, `check-003` "1–9" | Reescrito em torno do `check-003 [--profile]` |
| I5 | Inconsistência | BAIXA | plan.md (estrutura, escopo) | Faltavam `PopupFrame`, `ListItem`/`Selector` e o catálogo longo; contagem de componentes antiga | Árvore e escopo atualizados |
| I6 | Inconsistência | BAIXA | data-model.md (Estado do popup) | `busy` no `dump` sem entrada no modelo | Linha acrescentada |
| I7 | Lacuna | MÉDIA | contracts/services.md × 001 `fixtures.schema.json` | O domínio `settings` da fixture não está no schema da 001, que tem `additionalProperties: false` | Anotado no contrato da 003. O schema da 001 fica pra o merge, porque a 004 pode mexer no mesmo arquivo |
| C1 | Cobertura | MÉDIA | spec.md US1 cenário 4, casos de borda de monitor | Dois monitores e troca de monitor com o popup aberto: o lab tem um monitor só, e nenhuma tarefa testa | **Aberto.** O código abre no monitor em foco do `hyprctl` e fixa a tela até fechar, mas não há evidência com dois monitores |
| C2 | Cobertura | BAIXA | FR-001 | `SUPER + I` no sistema instalado não tem tarefa | Fora do escopo por desenho (S3/U7) |
| K1 | Constituição | — | IV, SC-007 | O log tem 1 WARN do Qt por abertura (abaixo); não é QML | Contado à parte e documentado no quickstart; a decisão é do dono |

**Métricas:**
- requisitos: 24 FR e 9 SC;
- 41 tarefas;
- cobertura de 100% das FR com tarefa (FR-001 em parte: o atalho da instalação é de outra fase);
- 0 achados críticos, 0 duplicações e 0 ambiguidades novas.

## Custo no host (`lab/perf`)

Foram 10 sessões, todas `pass`, com 0 erros de QML no fim de cada uma.

| Sessão | Tarefa | Duração | CPU da VM |
|---|---|---|---|
| `2026-10-27T153155-…-003-contrato…` | T012 | 116 s | 34,7 s |
| `2026-10-27T154033-…-003-frente-c…` | T021 | 84 s | 10,2 s |
| `2026-10-27T154318-…-003-frentes-a-e-b…` | T013–T020 | 186 s | 21,6 s |
| `2026-10-27T154645-…-003-us1…` | T022–T025 | 284 s | 31,9 s |
| `2026-10-27T155247-…-003-us2…` | T026–T031 | 1287 s | 293,8 s |
| `2026-10-27T161514-…-003-us3…` | T032–T035 | 146 s | 33,0 s |
| `2026-10-27T161856-…-003-validacao…` | T038 | 618 s | 181,9 s |
| `2026-10-27T162932-…-003-regressao-da-001…` | T039 | 86 s | 30,8 s |
| `2026-10-27T163130-…-003-imagem-de-revisao…` | T040 | 1279 s | 67,9 s |
| `2026-10-27T165434-…-003-desligar…` | T041 | 17 s | 1,8 s |
| **Total** | | **4103 s (68,4 min)** | **707,6 s** |

- **Pico de memória da VM (RSS do QEMU):** 2,87 GB, com 4 GB configurados.
- **CPU do host acima da base:** média de 2,4 pontos percentuais por sessão, no máximo 5,8 (a do
  contrato, com o container do schema).
- **Pressão (PSI):** 23 s de espera somados nas 10 sessões.
- **Disco escrito pela VM:** 3,85 GB.

Observações:
- A sessão T040 inclui ≈17 min em que fiquei parado. A sessão principal tinha ligado o modo de
  plano.
- A VM ficou ligada de 15:32 a 16:54 (82 min). Os ≈14 min fora das sessões foram de escrever
  código, sem teste.

## Commits

- **`003-settings-popup`:**
  - `01840d4` contrato;
  - `642b034` peças do design system, moldura e US1;
  - `7915eb5` US2;
  - `8ab4bc6` US3;
  - `6b3e857` acabamento (T036–T038);
  - mais o commit deste relatório e da T041.

  Antes de mim, a sessão principal fez `0bf600e` (`Compositor.focusedMonitor`,
  `Settings.reduceMotion`).
- **`lab-003`:**
  - `604ee68` esqueleto do `check-003` e `times.txt` do `burst`;
  - `cdb5b32` US1;
  - `ed66c20` US2;
  - `b0dd35f` US3;
  - `07c7ca0` `check-003` completo.

  Antes de mim, a sessão principal fez `4997d2f` (`click`, `burst`, `ALT + I`/`ALT + W`).

## Pendências pro dono

1. **SC-009, aprovação visual:** `~/.local/share/nier-lab/out/003-revisao-sc009.png`.
   - O mockup ainda mostra as abas do menu de pausa, o relógio e o grid.
   - Os três ficaram fora de propósito: FR-008 e a decisão de tirar o grid.
2. **WARN `qt.qpa.wayland.textinput` (um por abertura de popup ou galeria):**
   - **Causa:** o Qt 6.12.0 chama `disableSurface` numa janela recém-focada que nunca habilitou
     o text-input. O `dev` do Qt já corrige isso.
   - **Hoje:** não é QML; o `check-003` conta à parte e o `lab/perf` conta como `qml_warnings`.
   - **Pra calar:** um `//@ pragma Env QT_LOGGING_RULES=qt.qpa.wayland.textinput.warning=false`
     no `shell.qml`.
   - **Não silenciei:** a decisão é sua.
3. **Dois monitores:** não testados (o lab tem um monitor só). Ver C1.
4. **Régua pontilhada do HUD depois do `lab/profile`:** fica com a escala anterior até a próxima
   consulta de monitores (comportamento da 001; abrir o popup faz essa consulta).
5. **Blink na VM:** ≈223–263 ms, contra os 240 do token. A VM não serve pra julgar fluidez (README
   do lab); calibrar na máquina real, na homologação.
6. **Merge com a 004 (arquivos compartilhados):** `shell.qml`, `Strings.qml`, `Tokens.qml`,
   `Gallery.qml` e `docs/design-system.md`.
   - Os acréscimos da 003 estão em blocos marcados "spec 003".
   - O `PopupWindow` mantém a interface do contrato, mais `s` e `panel` só de leitura.
