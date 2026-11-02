# Quickstart: validar a primeira release

Tudo roda no lab (`../YoRHa-OS-private/lab/`), nunca no host, a não ser as ferramentas do lab
(`lab/015/canal` e `lab/015/release`). Cada sessão abre com `lab/perf begin "<teste>"` e fecha com
`lab/perf end --result …`. As VMs sobem com `--audio-capture` e `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`.

## Preparação

1. `lab/new t015 --from hypr-iso` e o `lab/015/prep t015`, que deixa o `hyprland.lua` de uma pessoa
   comum, como a 014 fazia.
2. Montar as versões de teste a partir da branch da 015:
   `lab/015/release build 0.0.1 --ref 015-primeira-release --lab-only` e uma `0.0.2` depois de um
   commit.
3. `lab/015/canal start` (8714). Pro espelho: `lab/015/canal start --port 8715`.

## Os cenários

| # | Cenário | Como | Evidência | SC |
|---|---|---|---|---|
| 1 | Instalar sem variável | Na `t015`, o comando do README com `YORHA_ORIGIN` apontando pro canal (a única diferença do público) e `YORHA_YES=1`; entrar de novo | `yorha status` com a versão, `stable` e a origem; screenshot da barra; `shell.log` sem erro de QML | SC-001 |
| 2 | Checksum errado | `canal corrupt 0.0.2`; instalar | Saída 4, nada em `~/.local/share/yorha-shell` | US1-2 |
| 3 | Update e rollback | Instalada a 0.0.1, publicar a 0.0.2 no canal; "Update now"; depois `yorha rollback` | Transmissão, `status` antes e depois, screenshots | US2-1 |
| 4 | Canal de teste | Duas VMs; uma com `yorha channel testing`. Montar `0.0.3 --pre` | A de teste vê e atualiza; a estável responde `up-to-date` (log do canal e `update --check`) | SC-002 |
| 5 | Nunca voltar sozinho | Tirar a 0.0.3 do índice do canal | `update --check` = `up-to-date` na VM que está na 0.0.3 | US2-3 |
| 6 | Origem fora do ar | Canal em 8714 e 8715, origens com as duas; `canal stop --port 8714`; instalar e atualizar | Os dois terminam; o log de 8715 mostra os pedidos | SC-010 |
| 7 | Conferência desligada | `auto-check` desligado; reiniciar o shell; esperar 3 min | Zero pedidos no log do canal; `updates dump` com os timers parados | SC-010 |
| 8 | As recusas do `build` | Uma mudança não commitada; um número repetido; um número menor; um arquivo de teste proibido (um `.wem` vazio numa branch de teste) | As quatro saem 1, com o motivo | SC-004 |
| 9 | O nome | Instalada uma versão montada, procurar `yorha-os` nas pastas do produto, nos textos da UI (screenshots) e no pacote (`release check`) | Nenhuma ocorrência fora da lista de histórico | SC-005 |
| 10 | Trocar de nome, ida e volta | `0.0.4 --lab-only` de uma branch de teste com `fake-shell`/`fakecmd`; atualizar e depois `rollback` | Nas duas pontas: pastas e links, atalho do comando, a linha antiga carregando o shell, shell no ar, log limpo | SC-009 |
| 11 | O sinal | Com versão nova e a transmissão fechada: as cinco formas, uma por vez, trocadas com o shell aberto | Screenshots de cada forma; `updates dump` (`signVisible`); clique no `UPDATE` abre SYSTEM › Updates; depois do update, nada | SC-006 |
| 12 | Regressão | `check-003`, `004`, `007`, `008`, `013` e o `check-014` adaptado | Os roteiros passam | SC-007 |
| 13 | Lint | `shellcheck` e `qmllint` como no `lint.yml`, dentro de uma VM | Sem erro | SC-007 |

## Depois da `main`: a release de verdade

Cada passo com o OK do dono.

1. `lab/015/release build 0.1.0` (da `main`), com as notas escritas à mão.
2. Os cenários 1, 3 e 11 de novo com a 0.1.0 servida pelo canal (o mesmo arquivo que vai subir).
3. A página da release pro dono (notas, checksum, evidência): SC-008.
4. Push, renomear o repositório, apagar as branches, lint verde (research R9).
5. `lab/015/release publish 0.1.0`: o checksum baixado de volta bate (SC-003).
6. Numa VM limpa, o comando do README sem variável nenhuma (SC-001, agora com o GitHub de verdade).
7. `build 0.1.1 --pre` → teste no lab → `publish 0.1.1`: a VM no canal de teste recebe e volta com o
   rollback, a estável não é avisada (SC-002). `promote 0.1.1` quando o dono quiser.
