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

## O que a prova achou além da tabela: o Hyprland pode travar

> **Corrigido em 05.11, na junção.** O texto de 03.11 dizia que a trava era da 0.56.2, que dependia de um pedido logo depois do `configreloaded`, e que a espera de 300 ms a evitava. Nada disso se sustenta.
> A medida que vale é a da `fix-trava-reload` (`central/fix-trava-reload/rodadas-056/resumo.txt` e `rodadas-057/resumo.txt`):
>
> | Saves com erro na config, travas por rodadas | Com a espera de 300 ms | `main`, sem a espera | Sem shell nenhum |
> |---|---|---|---|
> | 0.56.2 | 5 em 400 (1,2%) | 6 em 400 (1,5%) | 21 em 400 (5,2%) |
> | 0.57.0 | 3 em 200 (1,5%) | 6 em 200 (3,0%) | 11 em 200 (5,5%) |
>
> - **A espera não tem benefício mostrado contra a trava.** Com a espera e sem ela não dá pra separar: p combinado 0,50, diferença de +0,67 ponto percentual, intervalo de 95% de −0,78 a +2,11.
> - **A causa não são os nossos pedidos.** Sem shell nenhum, a trava acontece, e mais do que com o shell (0.56.2: 21 em 400 contra 6 em 400, Fisher p = 0,005; 0.57.0: 11 em 200 contra 6 em 200, p = 0,322, sem separar).
> - **O que a trava precisa é um erro na config na hora em que o aviso é desenhado** (a pilha abaixo, `COverlay::createQueued` → `renderText` → `await`). Um pedido logo depois do `configreloaded` não é necessário.
> - **Os números de 03.11 não valem.** O "0 em 70 rodadas" do shell real e o "na 0.57.0 não apareceu" caem: a 0.57.0 trava, a mesma pilha, também em `1c/estresse-057/stack-1.txt`. O "6 em 50 lendo na hora, 0 em 50 com 300 ms" da tabela abaixo foi amostra pequena.
>
> As tabelas abaixo ficam como foram medidas em 03.11. Elas não sustentam o que este texto dizia antes.

Na primeira rodada da prova, o Hyprland 0.56.2 parou de responder: `hyprctl` dá `Hyprland IPC didn't respond in time`, para sempre, e a
sessão inteira fica parada, até reiniciar. A linha principal fica presa assim (`eu-stack`, cópia em `t003/prova-trava-56/`):

```
Hyprgraphics::CAsyncResourceGatherer::await
Render::IHyprRenderer::renderText
ErrorOverlay::COverlay::createQueued
Render::IHyprRenderer::renderMonitor
```

É o aviso de erro de config do próprio Hyprland, desenhando o texto. Acontece com um erro na config quando o aviso é desenhado; um pedido logo depois do
`configreloaded` não é necessário (ver a correção acima). `lab/019/prova-trava`, em rodadas de save com erro, cada trava custando um reboot da VM:

| Leitura depois do evento | 0.56.2 | 0.57.0 |
|---|---|---|
| Nenhuma | 0 em 50 | 0 em 50 |
| Na hora | **6 em 50** (+ 2 em 16 na 1ª rodada, e as 2 da exploração) | 0 em 50 |
| 300 ms depois | 0 em 50 | 0 em 50 |
| Shell real, lendo a config sem esperar | **1 em 30** | não medido |
| Shell real, com a espera só na leitura da config | 0 em 30 | não medido |
| Shell real, com a espera em tudo que o backend pede | 0 em 40 | não medido |

**O que está no código hoje:** depois do `configreloaded`, o backend espera 300 ms antes de ler a config, as telas e as janelas (`configWait`, `afterReload`). Ela entrou por causa desta trava, e a medida acima não mostra benefício.
A decisão de manter ou tirar é do dono, e este texto não a antecipa. A base continua sendo o valor do arquivo: nada mais escreve nessa janela, e uma escrita do próprio menu pedida nela espera a leitura acabar. Um `hyprctl eval` ou `dispatch` de fora nesses 300 ms cai nos limites da spec. A D2 não muda.

**A `main` tem o mesmo risco hoje, com o shell ou sem ele:** quem tem um erro na config pode ter a sessão parada, na 0.56.2 e na 0.57.0.

## Medição

| Sessão | `lab/perf` | Resultado |
|---|---|---|
| Exploração, 0.56.2 | `2026-11-03T194920-vm-t-prova-56-019-t002-exploracao-da-prova-base-0-56-2` | n/a: achou a trava |
| `prova-base` e `prova-trava`, 0.56.2 | `2026-11-03T200852-vm-t-prova-56-019-t003-prova-base-e-prova-trava-t-prov` | pass |
| `prova-base` e `prova-trava`, 0.57.0 | `2026-11-03T200852-vm-t-prova-57-019-t003-prova-base-e-prova-trava-t-prov` | pass |
| Taxa de travas, 0.56.2 | `2026-11-03T201925-vm-t-prova-56-019-t003-prova-trava-taxa-com-e-sem-leit` | n/a |
| Taxa de travas, 0.57.0 | `2026-11-03T201925-vm-t-prova-57-019-t003-prova-trava-taxa-com-e-sem-leit` | n/a |
| Shell real, as três linhas da tabela | `2026-11-03T201932-vm-t-base-0-019-t004-t013-subir-o-shell-da-etapa-0-t` | n/a |
| Taxa com o shell, 0.56.2 (frente 1B, Display à vista, menu fechado, sem shell) | `2026-11-05T155706-…`, `2026-11-05T160534-…`, `2026-11-05T161257-vm-t-leituras-1b-019-1b-taxa-de-trava-da-0-56-2-shell-rea` | n/a |
| Sondas da 0.57.0 (frente 1C) | `2026-11-05T165104-vm-t-teclado-57-019-1c-sondas-na-0-57-quem-apaga-o-confi` | n/a |
| A taxa final, 0.56.2 (com a espera, `main`, sem shell) | `2026-11-05T164642-…` e `2026-11-05T200438-vm-t-trava-56-fix-trava-reload-taxa-de-travas-0-56-2-r` | n/a |
| A taxa final, 0.57.0 (com a espera, `main`, sem shell) | `2026-11-05T200548-…` e `2026-11-05T215822-vm-t-trava-57-fix-trava-reload-taxa-de-travas-0-57-0-c` | n/a |
