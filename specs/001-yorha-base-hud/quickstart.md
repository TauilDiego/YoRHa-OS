# Quickstart: validar o U1 no laboratório

Este é o roteiro que prova cada critério de sucesso com evidência da VM (princípio IV). Tudo
roda no ambiente privado (`rien-OS-private/lab`) e **dentro de uma sessão de medição**. Nada
disso roda na máquina do dono.

## Preparação

```sh
cd ~/projects/rien-OS-private
lab/perf begin "U1: validação do HUD" --kind u1-validacao --task 001
lab/up dev
lab/sync --env NIER_FIXTURES=~/nier/ui/fixtures/hud-default.json   # manda shell/ + liga as fixtures
```

Fixture padrão (`shell/fixtures/hud-default.json`):
- workspaces 1–3 existem, com o 2 em foco;
- CPU 23, MEM 41, VOL 64, BAT 87;
- título "kitty — ~/projetos";
- relógio em 2026-10-26 13:37:00.

O formato está em [contracts/fixtures.schema.json](contracts/fixtures.schema.json).

## Cenários

| # | Prova | Como | Esperado |
|---|---|---|---|
| 1 | SC-001 | `lab/shot hud` + `lab/ipc qs -p ~/nier/ui ipc call hud dump` | O screenshot mostra as abas 01–05 (02 invertida e descendo até a régua, 04/05 apagadas), as 4 leituras, o título e "2026.10.26 13:37:00". O `dump` traz os mesmos valores ([contracts/ipc.md](contracts/ipc.md)) |
| 2 | SC-002 | Dois `lab/shot`, depois `lab/diffshot a.png b.png` | 0 pixels diferentes (o balanço fica congelado com fixtures) |
| 3 | SC-003 | Fixture sem o domínio `workspaces`, `lab/key` / clique na aba 03, `hud dump` | O workspace 3 entra em foco e a aba 03 é `selected` em ≤ 0,5 s |
| 4 | SC-004 | `ipc call gallery open`, `lab/shot galeria`, `ipc call gallery close` | Todas as peças do FR-003 e todos os estados do FR-004 aparecem, com nome, vinheta e seletor com os 2 quadradinhos |
| 5 | SC-005 / FR-017 | O relatório do `lab/perf end` (seção "Dentro da VM") | 0 erros e 0 avisos no último carregamento |
| 6 | SC-007 | Editar um arquivo em `shell/` com `lab/sync --watch` ligado, depois `lab/shot` | A mudança aparece em ≤ 3 s |
| 7 | SC-008 | `lab/profile hidpi` + `lab/shot`, depois `lab/profile 1080` + `lab/shot` | A barra tem 68 px lógicos (85 px físicos no hidpi), e o grid e as réguas não têm meio pixel |
| 8 | Bordas | `ipc call fixtures load` com `battery-low.json`, `no-battery.json`, `muted.json`, `long-title.json` e `no-window.json` | BAT vermelha; BAT some; VOL mudo e vazio; título com reticências; título vazio |
| 9 | Lint | `lab/ssh 'qmllint -I … ~/nier/ui/**/*.qml'` | Sem erros |

## Fechamento

```sh
lab/down
lab/perf end --result pass --note "U1 validado"
```

O relatório (custo no host + guest + screenshots com hash) vai pro `rien-OS-relatorios`. Os
screenshots e o `dump` são a evidência pra revisão do dono (SC-006).
