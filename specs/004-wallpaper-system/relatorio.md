# Relatório da implementação: Sistema de papel de parede (spec 004)

**Data:** 2026-10-27.

**Onde:**
- branch `004-wallpaper-system` (US1, US3, US4, US5 e o polimento sem o seletor) e `004-seletor`
  (US2, o seletor, e o polimento que dependia dele), no repositório público;
- branches `lab-004` e `lab-004-seletor` do repositório privado (laboratório).

**Lab:** VMs `teste-a`, `teste-b` e `teste-c` (o seletor só na `teste-c`, 4 GB, com boot no perfil
hidpi pra ter os dois modos); tudo dentro de sessões `lab/perf`.

**Status:** as 47 tarefas estão feitas. Falta a aprovação visual do dono (SC-010), com as imagens de
revisão abaixo.

## O que ficou pronto

- **Fundo fiel ao jogo (US1):** a cena `menu` (papel com a vinheta medida, arcos duplos e feixes que
  respiram, sem grid e sem grão), mais `rules`, `dark` e `plain`, todas definidas por JSON.
- **Seletor (US2):** `ALT + W` na VM (`SUPER + W` nas instalações) e `qs ipc call wallpaper picker
  open|close|toggle`. Abre no monitor em foco, sobre o desktop escurecido, na moldura da 003:
  - lista agrupada (SCENES, IMAGES, VIDEO) com a pipa e a marca `● ALL` no que está aplicado;
  - prévia ao vivo: a cena desenhada pequena, a imagem decodificada no tamanho da prévia, com o
    filtro, e "NOT YET" no vídeo;
  - opções `Monitor`, `Transition` e, nas imagens, `Paper filter`, mais as informações `TYPE`,
    `LAYERS`, `MOTION` e `NOW ON`;
  - rodapé de teclas por foco, navegação em duas colunas, mouse, Enter aplicando com a transição
    escolhida, Esc voltando ou fechando;
  - o estado sai no `wallpaper dump` (objeto `picker`).
- **Transições (US3):** camuflagem (de fábrica), varredura, quadradinhos e crossfade, num shader só.
- **Imagens (US4):** a pasta observada, cortadas sem esticar, com o filtro de papel desligável.
- **Estado e comando (US5):** a escolha por monitor sobrevive a reiniciar; `next`, `prev`, `set`…
- **Design system:** a `GroupedList` e o composto `PickerLayout` (lista + prévia + opções),
  documentados no §8 e na página 3 da galeria (cenas, filtro, quadro parado de cada transição,
  lista agrupada com e sem foco, o layout em miniatura).

## Evidência por critério

Pastas em `~/.local/share/nier-lab/out/`; relatórios em `~/projects/YoRHa-OS-relatorios/runs/<id>`.

| Critério | Evidência | Sessão `lab/perf` |
|---|---|---|
| SC-001 | Centro, bordas e cantos a ≤ 2 níveis (1080) e ≤ 3 (hidpi) do jogo; alta frequência 0,0 / 0,35 (sem grid) | `2026-10-27T195507` (`004-seletor-check-004`) |
| SC-002 | Fundo: 0 px nos dois perfis. Seletor aberto: 0 px em 1080 e em hidpi | `2026-10-27T195507` |
| SC-003 | As 4 cenas e as 3 imagens aplicadas, imagens com o corte esperado (diferença média ≤ 0,07) | `2026-10-27T195507` |
| SC-004 | Teclas reais `ALT+W`, ↓ ↓ Enter → ↓ → Esc Esc: um `dump` por tecla bate com o passo; fim em `scene:dark`, `wipe`, `picker: null`. Em 1080 e hidpi (`sc004-*-passos.txt`) | `2026-10-27T195507` |
| SC-005 | Rajadas das 4 transições (T032) | `2026-10-27T155020` (`004-T032-transicoes`) |
| SC-006 | `scene:dark` no Virtual-1 volta depois de `pkill qs`; `~/.config/yorha-os` intocado | `2026-10-27T195507` |
| SC-007 | `nova.jpg` no catálogo em 0,33 s e, com o seletor aberto, na lista dele em 0,30 s; o nome com espaços, aspas e `#` aplica | `2026-10-27T195507`, `2026-10-27T200317` |
| SC-008 | Log do roteiro inteiro: 0 erros e 0 avisos de QML (fora o aviso conhecido do Qt 6.12.0 ao abrir um popup, contado à parte como na 003); `qmllint` limpo | `2026-10-27T195507` |
| SC-009 | Camuflagem 0,63 s de CPU do `qs` por troca, a ≈60 fps; crossfade 0,18 s (T033) | `2026-10-27T155509`, `2026-10-27T155649` |
| SC-010 | **Aguarda o dono:** `004-seletor-revisao.png` (mockup × VM no mesmo estado, 1080 e hidpi) e `004-revisao-sc010.png` (cenas, filtro, seletor, camuflagem, galeria) | `2026-10-27T200447` |

Mais, no `check-004` (US2): vídeo apagado (NOT YET, Enter sem efeito), `Paper filter` só nas imagens
(← no primeiro valor volta pra lista), `Monitor` = Virtual-1 aplica só nele (`own`), mouse (hover
move o foco, ▸ muda o valor, clique aplica, clique fora fecha), `ALT+W` como toggle, a pasta
inexistente com o aviso "Put pictures in ~/nao-existe" e a galeria. Regressão: `check-u1` 15/15 e
`check-003 --profile 1080` 25/25, com o popup de configurações idêntico pixel a pixel ao de antes.

## Decisões e desvios

As das fases anteriores estão no `tasks.md` (T012, T016, T028–T030, T034, T035, T038). As do seletor:

- **`GroupedList` é um composto novo**, não um alias: a `CursorList` da 003 não tem grupos. Usa as
  mesmas peças (faixas, `ListItem`, pipa com o blink) e a mesma geometria da lista de categorias da
  003 (itens 8 px mais à esquerda que no mockup, como lá).
- **Linhas de opção menores** (`contentScale` 0,815), como no mockup ("a size smaller to fit the
  card"), mas na mesma faixa de 48 px e com a mesma pipa. Pra isso, `ListItem` e `OptionRow`
  ganharam `contentScale`, e o `Card`, o quadrado do título (`mark`).
- **O composto reutilizável é o `PickerLayout`** (lista + prévia no meio + opções e informações), com
  a navegação e o rodapé. O seletor só põe os dados e o `PreviewCard`.
- **Monitor** é estado do seletor: volta pra "All monitors" a cada abertura. A transição e o filtro
  valem na hora (o SC-004 termina com `wipe` sem um segundo Enter).
- **`Paper filter` é uma escolha `On`/`Off`**, não um liga/desliga: assim ← no primeiro valor volta
  pra lista, como nas outras opções.
- **Ajuste fino da camuflagem** fica fora do seletor (as tarefas não pedem): continua no `shell.json`
  e no `ipc call wallpaper camouflage`.
- **Um popup de cada vez:** abrir o seletor fecha as configurações, e vice-versa.
- **A linha "BAR" do mockup** (tom da barra) ficou de fora: é da frente da barra transparente, feita
  em paralelo.
- **Marcas `● <saída>`:** com o nome inteiro da saída (`DP-1`), não o prefixo do mockup (`DP`), que
  ficaria ambíguo com `DP-2`. Na VM, com um monitor só, sempre aparece `● ALL`.
- **Galeria:** página 3 (Tab duas vezes), carregada só enquanto aparece. O quadro parado de cada
  transição usa a `WallpaperTransition` real com `hold(ms)` (semente 1, origem no meio).
- **Hover:** como na 003, o primeiro evento depois de abrir não move o foco; o roteiro passa o
  ponteiro pelo papel do painel antes de ir pro item.

## Correções feitas no caminho

- `WallpaperPicker`: uma propriedade com maiúscula (`W`) não carrega em QML; virou `ws`.
- `GroupedList`: `top` é uma propriedade final do `Item`; virou `topPad`. Os títulos de grupo agora
  têm a linha de 18 px do mockup (CSS `line-height: 1`), e os itens caem na mesma altura dele.
- Galeria: o `dpr` lê a tela pela `QsWindow.window` num `var` (o `qmllint` reclamava do `screen`).
- `check-004`: voltar ao estado da fixture recarregando a mesma fixture não muda nada; o roteiro
  passou a repor a escolha por IPC. O índice esperado no cenário do mouse estava errado (T045).

## Análise (T047, `/speckit-analyze`)

Nenhum conflito com a constituição, e toda FR e todo SC têm tarefa e evidência. Resolvido nos
artefatos: o status da spec e do plano (aprovados), o `ALT + W` da VM na FR-006, a linha `Paper
filter` na FR-007, o aviso conhecido do Qt contado à parte na FR-024, o `PickerLayout` na estrutura do
plano e a nota de dependência da US2 no `tasks.md`. Fica registrado: com uma saída só na VM, as
marcas por saída (`● DP-1`) e monitores com escalas diferentes ao mesmo tempo não foram vistos.

## Custo no host (`lab/perf`)

Sessões do seletor, todas na `teste-c`:

| Sessão | Tarefa | Duração | CPU do backend |
|---|---|---|---|
| `2026-10-27T193322` implementação e primeiras telas | T025 | 526 s | 84,8 s |
| `2026-10-27T194211` check-004 com o seletor | T027 | 767 s | 218,5 s |
| `2026-10-27T195507` validação final (u1, 003, 004) | T044 | 490 s | 160,6 s |
| `2026-10-27T200317` correção do roteiro do mouse | T045 | 82 s | 18,5 s |
| `2026-10-27T200447` imagens de revisão | T046 | 138 s | 16,9 s |

A spec 004 inteira somou 33 sessões, 6990 s e 1724 s de CPU do backend (VMs e containers).

## Commits

Repositório público:
- `efa6ce4`, `7a7b017`: spec, plano e tarefas;
- `a87e37b`, `0a2953e`, `d6b9eac`: US1 (fundo fiel);
- `00c684e`: laboratório de shaders, imagens de teste e contrato;
- `d0d71ac`: o fundo vira a cena `menu`;
- `b8ed9bc`, `9202444`, `0a469a3`: US3, US4, US5;
- `5464921`, `3c95624`: polimento sem o seletor;
- `e39f26d`: merge da 003;
- branch `004-seletor`: o seletor, a galeria e o design system (T023–T026, T041, T042), e as tarefas
  e este relatório (T027, T043–T047).

Repositório privado (`lab-004-seletor`): `check-004` com o seletor e o README; a correção do
cenário do mouse.

## Pendências pro dono

1. **SC-010, aprovação visual:** `~/.local/share/nier-lab/out/004-seletor-revisao.png` (o seletor:
   mockup × VM) e `~/.local/share/nier-lab/out/004-revisao-sc010.png` (o resto).
2. **Linhas de opção a 0,815:** seguem o mockup; se preferir o tamanho normal da 003, o quadro de
   opções precisa de ≈470 px de largura (hoje 404) e a lista fica mais estreita.
3. **O `Monitor` voltar pra "All monitors" a cada abertura:** confirmar, ou lembrar a última escolha.
4. **Merge** da `004-seletor` com a branch da barra transparente (as duas mexem em `Tokens.qml`,
   `Strings.qml` e `WallpaperTransition.qml`, em blocos marcados).
