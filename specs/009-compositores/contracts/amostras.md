# Contrato: amostras pro adaptador do compositor (`lab/009/amostras/`)

Cada linha da tabela §6 do contrato da 007 (`specs/007-menu-de-pausa/contracts/compositor.md`, commit
`fc561cd`) vira uma ou mais amostras: a saída crua de uma consulta ou ação, rodada pelo `lab/ipc` na VM
de cada compositor, num estado conhecido. As amostras ficam no repositório privado (branch `lab-009`).

## Pastas e nomes

```
lab/009/amostras/
├── index.tsv                       # uma linha por amostra (abaixo)
├── cenarios.md                     # como montar S0–S3 em cada compositor
├── hyprland/L01-monitores.json     # referência: o que o HyprlandBackend usa hoje
├── niri/L01-monitores.json
├── niri/L05-janela-ativa.json
├── niri/Q-niri-tela-cheia.txt
├── mango/L03-areas.txt
├── mango/Q-mango-acao-fora-de-foco.txt
└── …
```

Nome: `<linha>-<slug>.<json|txt>`. Uma ação (ir pra área, focar, mover, flutuar, fechar) guarda **três
coisas no mesmo arquivo `.txt`**, separadas por uma linha `### `: o estado antes (a consulta de
janelas/áreas), a saída da ação e o estado depois. Assim a amostra prova que a ação fez o que se esperava.

## Linhas

| Id | Linha do §6 | O que a amostra mostra |
|---|---|---|
| `L01` | Monitores e escala | nome, tamanho lógico e físico, escala, posição; em `S2` a escala 1,25 |
| `L02` | Monitor em foco | qual saída tem o foco; em `S3`, depois de mudar o foco |
| `L03` | Áreas de trabalho | id/chave, índice no monitor, monitor, foco, se existe, janelas |
| `L04` | Janelas | id, classe, título, área, monitor, flutuante, foco, ordem de foco, tela cheia, posição ou coluna |
| `L05` | Janela ativa e tela cheia | título e se está em tela cheia, com a janela de `S1` em tela cheia |
| `L06` | Eventos | 10 s do fluxo de eventos enquanto o roteiro abre, foca, move e fecha uma janela |
| `L07` | Ir pra área | ação + antes/depois |
| `L08` | Focar janela | por id, numa janela que não está em foco |
| `L09` | Mover, flutuar, fechar | as três, por id, numa janela que **não** está em foco; se só der na em foco, a amostra mostra a recusa e o contorno (focar antes) |
| `L10` | Modelo | `numbered`, `dynamic` ou `tags`, com a amostra que mostra o comportamento (ex.: o que acontece ao ir pra área 5 quando só existem 2) |

**Perguntas extras** (FR-025):

| Id | Pergunta |
|---|---|
| `Q-mango-acao-fora-de-foco` | Mango: mover, fechar e focar por id uma janela fora de foco |
| `Q-mango-tag-por-janela` | Mango: como saber a tag de cada janela |
| `Q-mango-eventos` | Mango: existe fluxo de eventos? Formato |
| `Q-niri-tela-cheia` | Niri: como saber se a janela está em tela cheia |
| `Q-niri-flutuante` | Niri: `is_floating` existe e muda com a ação |
| `Q-niri-coluna` | Niri: os dados de coluna/posição pro mapa da aba WINDOWS |
| `Q-escala-por-monitor` | Os dois: escala fracionária por monitor (precisa de `S3`; sem `S3`, fonte marcada "pesquisa") |
| `Q-deteccao` | Os três: as variáveis de ambiente da sessão (`env` dentro da sessão gráfica), pra regra do §1 |
| `Q-import-hyprland` | Niri e Mango: o spike do `Loader` que não carrega um arquivo com `import Quickshell.Hyprland` (FR-022) |

## Cenários (estado da VM antes da amostra)

| Id | Estado |
|---|---|
| `S0` | Logo depois do boot, com a UI no ar e sem janela |
| `S1` | Perfil 1080. Área 1: dois kitty (`kitty --class nier-a`, `nier-b`), o `nier-b` flutuante. Área 2: um kitty `nier-c` em tela cheia. Foco no `nier-a` |
| `S2` | `S1` com `lab/profile hidpi` (2560x1600 a 1,25) |
| `S3` | Duas saídas (se o lab conseguir, research R12); escalas 1 e 1,25 |

Os títulos e as classes são fixos pra amostra ser comparável entre os compositores. O `cenarios.md` diz
os comandos de cada compositor pra chegar em cada estado.

## `index.tsv`

Tab-separated, com cabeçalho:

```
id	compositor	cenario	comando	arquivo	formato	estado	correcao	data	perf_id
L04	niri	S1	niri msg --json windows	niri/L04-janelas.json	json	confirmada	-	2026-10-29T10:12	2026-10-29T1005…
L09	mango	S1	mmsg …	mango/L09-mover-flutuar-fechar.txt	txt	corrigida	focar antes (…)	…	…
```

- `estado`: `confirmada` (a célula do §6 está certa), `corrigida` (o comando certo vai em `correcao`) ou
  `nao-existe` (o contorno, se houver, vai em `correcao`). Nas linhas `hyprland`, `referencia`.
- `perf_id`: a sessão `lab/perf` em que a amostra foi tirada.

## Saída pro relatório

O `lab/009/tabela-s6.md` é gerado a partir do `index.tsv`: a tabela §6 com as colunas do Niri e do Mango
corrigidas e, em cada célula, o id da amostra. Ela vai pro `docs/estudo-compositores.md` como **proposta
de mudança** (FR-039); a branch da 007 não é editada.
