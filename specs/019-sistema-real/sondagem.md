# Sondagem: a prova da base do arquivo (T003)

Rodada em 03.11, sem o shell, nas duas versões, com `lab/019/prova-base` (um `hyprland.lua` de teste e `socat` no socket2). Pastas:
`~/.local/share/nier-lab/out/prova-base-t-prova-56-20261103-200852` e `…-t-prova-57-20261103-200852`, e cópia em
`YoRHa-OS-private/central/sistema-real-019/etapa-0/t003/`.

| Versão | Camada | Hyprland |
|---|---|---|
| 0.56.2 | `t-prova-56`, de `hypr-iso` | `hyprland 0.56.2-4`, commit `efb5099` |
| 0.57.0 | `t-prova-57`, de `hypr-057` | `hyprland 0.57.0-3`, commit `0aa6745` |

## Resultado: P1 a P9 passam nas duas versões

| Item | 0.56.2 | 0.57.0 | O que se viu |
|---|---|---|---|
| P1 chave ausente | PASS | PASS | `600\|25\|[[EMPTY]]\|us` → `eval` `50\|50\|caps:escape\|de` → reload volta aos padrões |
| P2 chave no arquivo | PASS | PASS | `250\|30\|grp:alt_shift_toggle\|us,br` → `eval` → reload volta ao do arquivo, nas 4 opções |
| P3 `eval` sem evento | PASS | PASS | 3 `eval` em 3 s: 0 `configreloaded`; controle, 1 reload: 1 |
| P4 salvar gera evento | PASS | PASS | Um evento por save, escrevendo no lugar ou trocando o arquivo (`mv`), e também salvando os mesmos bytes |
| P5 leitura depois do evento | PASS | PASS | 60 leituras (20 por reload, 20 no lugar, 20 por `mv`), 0 erradas; a leitura leva até 62 ms |
| P6 erros de config | PASS | PASS | Sintaxe, tempo de execução e valor inválido: `configerrors` já tem conteúdo na leitura do evento. Sintaxe: os valores ficam como estavam (o `eval` continua). Tempo de execução: zerados, o arquivo rodou até o erro |
| P6b chave desconhecida | PASS | PASS | `configerrors` diz `unknown config key`; lida 4 s depois, pra não cair na trava abaixo |
| P7 assinatura | PASS | PASS | `qs` reiniciado vê a mesma; `hl.dsp.exit()` e novo login trocam, e o valor lido é o do arquivo |
| P8 `YORHA_MOD` | PASS | PASS | `nil` sem a variável, `ALT`, `ALT + SHIFT`. Apagada do arquivo, um reload volta a `nil` |
| P9 formatos | PASS | PASS | `getoption -j`: `int` nas duas de repetição, `str` nas outras, com `"[[EMPTY]]"` pra vazio sem nada no arquivo. `kb_options = ""` por `eval` responde `""`. `monitors -j`: `width`, `height`, `refreshRate` (`74.998` na VM), `scale`, `focused`. `configerrors -j` sem erro é `[""]`. `hyprctl --batch "j/… ; j/…"` responde tudo num pedido, separado por linhas em branco |

**A regra da D2 fica como o dono decidiu.** O portão passa, e nada na tabela da direita de R1 precisou entrar.

## O que a prova achou além da tabela: a 0.56.2 pode travar

Na primeira rodada da prova, o Hyprland 0.56.2 parou de responder: `hyprctl` dá `Hyprland IPC didn't respond in time`, para sempre, e a
sessão inteira fica parada, até reiniciar. A linha principal fica presa assim (`eu-stack`, cópia em `t003/prova-trava-56/`):

```
Hyprgraphics::CAsyncResourceGatherer::await
Render::IHyprRenderer::renderText
ErrorOverlay::COverlay::createQueued
Render::IHyprRenderer::renderMonitor
```

É o aviso de erro de config do próprio Hyprland, desenhando o texto. Acontece com um erro na config **e** um pedido pelo socket logo depois do
`configreloaded`. `lab/019/prova-trava`, em rodadas de save com erro, cada trava custando um reboot da VM:

| Leitura depois do evento | 0.56.2 | 0.57.0 |
|---|---|---|
| Nenhuma | 0 em 50 | 0 em 50 |
| Na hora | **6 em 50** (+ 2 em 16 na 1ª rodada, e as 2 da exploração) | 0 em 50 |
| 300 ms depois | 0 em 50 | 0 em 50 |
| Shell real, lendo a config sem esperar | **1 em 30** | não medido |
| Shell real, com a espera só na leitura da config | 0 em 30 | não medido |
| Shell real, com a espera em tudo que o backend pede | 0 em 40 | não medido |

**O que muda no desenho:** é a consequência de P5 em R1, "espera curta, medida, antes de ler". Depois do `configreloaded`, o backend espera 300 ms
antes de ler a config, as telas e as janelas (`configWait`, `afterReload`). A base continua sendo o valor do arquivo: nada mais escreve nessa janela, e
uma escrita do próprio menu pedida nela espera a leitura acabar. Um `hyprctl eval` de fora nesses 300 ms cairia na base: é o mesmo tipo de limite do "`eval`
antes da primeira subida", com a janela bem menor. A D2 não muda.

**O que continua fora do nosso controle:** o Quickshell pede `monitors` e `workspaces` por conta própria nesse mesmo evento (o módulo `Quickshell.Hyprland`).
Com ele, são 0 travas em 70 rodadas. É amostra, não garantia.

**A `main` tem o mesmo risco hoje:** o `HyprlandBackend` lá lê `monitors -j` e `getoption` logo depois do `configreloaded`. Quem tem um erro na config em 0.56.2,
com o shell no ar, pode ter a sessão parada. Na 0.57.0 não apareceu em nenhuma rodada.

## Medição

| Sessão | `lab/perf` | Resultado |
|---|---|---|
| Exploração, 0.56.2 | `2026-11-03T194920-vm-t-prova-56-019-t002-exploracao-da-prova-base-0-56-2` | n/a: achou a trava |
| `prova-base` e `prova-trava`, 0.56.2 | `2026-11-03T200852-vm-t-prova-56-019-t003-prova-base-e-prova-trava-t-prov` | pass |
| `prova-base` e `prova-trava`, 0.57.0 | `2026-11-03T200852-vm-t-prova-57-019-t003-prova-base-e-prova-trava-t-prov` | pass |
| Taxa de travas, 0.56.2 | `2026-11-03T201925-vm-t-prova-56-019-t003-prova-trava-taxa-com-e-sem-leit` | n/a |
| Taxa de travas, 0.57.0 | `2026-11-03T201925-vm-t-prova-57-019-t003-prova-trava-taxa-com-e-sem-leit` | n/a |
| Shell real, as três linhas da tabela | `2026-11-03T201932-vm-t-base-0-019-t004-t013-subir-o-shell-da-etapa-0-t` | n/a |
