# Quickstart: validar a 013 na VM

Tudo roda no laboratório privado (constituição I), dentro do `lab/perf begin/end`, com
`NIER_LAB_CPUS=4 NIER_LAB_MEM=4G` exportado. O roteiro inteiro vira o `lab/check-013`
(`--only <bloco>`, `--profile 1080|hidpi`, `--mode floating|fullscreen`), no padrão do `check-008`: `ok`/`ko`
por item, uma pasta de evidência e um `summary.txt`.

## Preparação

```
export NIER_LAB_VM=teste-b NIER_LAB_CPUS=4 NIER_LAB_MEM=4G YORHA_OS_REPO=<worktree>
lab/perf begin "013: check" --task 013/check --backend vm
lab/up teste-b --audio-capture          # placa de som emulada, saída num WAV no host (research S6)
lab/provision-step notify               # já existia (008)
lab/sync --src <worktree>/shell
lab/check-013 [--only <bloco>] [--profile 1080|hidpi] [--mode floating|fullscreen]
lab/down; lab/perf end
```

## Blocos

| Bloco | Passos | Evidência | SC |
|---|---|---|---|
| `motion` | Uma rajada por efeito: descer uma linha, trocar de coluna, trocar de aba, trocar de categoria, rodapé | Folha por efeito e os tempos medidos contra `Tokens.motion` (±1 quadro) | SC-001 |
| `open` | Abrir, fechar, ação que sai (abrir um app de teste) | Rajadas: grade, triângulos, montagem, fechamento, esticar | SC-001 |
| `dialog` | POWER › Shut down, Cancel e de novo | Rajada da abertura e do fechamento; `dump` com a seleção em Cancel | SC-001 |
| `marquee` | Janela de título longo (WINDOWS), valor longo (Sound › Output) | Rajada de 3 s: pausa, rolagem a 60 px/s, pausa, volta | SC-001 |
| `perf` | `pause fps start`; abrir, 3 abas, 6 linhas, diálogo; `pause fps stop` | `p95` ≥ 30 qps, nos dois modos e nos dois perfis | SC-002 |
| `modes` | Trocar `shell.menuPresentation` com o menu aberto em cada aba, no seletor e no log | Screenshots dos dois modos; `dump` igual antes e depois (aba, seleção, foco) | SC-003 |
| `keys` | `lab/key`: 3 Tabs seguidos; Tab durante a abertura; Esc durante a montagem | `dump`: aba certa, título certo, menu fechado | SC-005 |
| `reduce` | `Reduce motion` ligado; rajadas de abrir, aba e seleção | O primeiro quadro já mostra o estado final; texto longo cortado com "…" | SC-006 |
| `choice` | Network › Network (Enter, ↓, Enter); Esc; Keyboard › Layouts (marcar 2, desmarcar 1, tentar desmarcar o último) | Screenshots, rajada da abertura, `dump` a cada passo; layouts no `hyprctl devices` | SC-010 |
| `sounds` | Gravação da saída; roteiro de teclas (`move`, `confirm`, `back`, `open`, `close`, `tab`, `dialog`, janelinha); notificação normal e crítica; com DND | WAV gravado + tempos das teclas; cada som no evento certo e em até 50 ms | SC-008 |
| `sound-opts` | 4 passadas: sons desligados; volume 10%; digitação ligada; pasta com um `confirm.wav` próprio | A mesma gravação: nada / baixo / tiques / o arquivo próprio só no `confirm` | SC-009 |
| `log-tab` | SUPER+N (ALT+N no lab) e clique no contador da barra | `dump`: menu aberto em `log`; os blocos de log da 008 passando com o host `pause` | US8 |
| `regress` | `check-003`, `check-004`, `check-007`, `check-008` nos dois perfis | Todos verdes (com as diferenças esperadas da FR-017 explicadas) | SC-004 |

## Boot e login (VM `teste-011`, camada `boot-iso`)

```
export NIER_LAB_VM=teste-011 NIER_LAB_CPUS=4 NIER_LAB_MEM=4G YORHA_OS_REPO=<worktree>
lab/011/install-module teste-011                 # com o som de boot
lab/bootcap teste-011 --until login --audio-capture
lab/011/boot-timing teste-011 3                  # com e sem os sons (sound.bootLogin)
lab/check-011 undo                               # o desinstalar tira o som de boot
```

| Bloco | Evidência | SC |
|---|---|---|
| `bootsound` | WAV do boot: o som de início depois da placa pronta, os sons da tela de login (entrada, mover, senha errada, confirmar), o som de entrada; journal ao lado | SC-012 |
| `boot-timing` | Diferença ≤ 0,1 s com e sem os sons; PipeWire da sessão sem erro | SC-013 |
| `undo` | Depois do `uninstall`, a unidade e o script somem e o sistema volta ao estado de antes | FR-032 |

## Fecho

O dono vê os dois modos e ouve os sons numa janela da VM (`lab/up --window`). SC-007 e SC-011.
