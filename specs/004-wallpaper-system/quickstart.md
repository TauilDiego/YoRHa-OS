# Quickstart: validar o sistema de papel de parede no laboratório

Este é o roteiro que prova cada critério de sucesso com evidência da VM (princípio IV). Tudo roda no
ambiente privado (`YoRHa-OS-private/lab`) e **dentro de uma sessão de medição**. Nada disso roda na
máquina do dono. O `lab/check-004` automatiza as linhas marcadas com ⚙.

## Preparação

```sh
cd ~/projects/YoRHa-OS-private
lab/perf begin "004: validação do papel de parede" --kind validacao --task 004
lab/up teste-c && lab/profile 1080
lab/sync --env NIER_FIXTURES=~/nier/ui/fixtures/wallpaper-default.json   # manda shell/, compila os shaders na VM
```

**Fixture `shell/fixtures/wallpaper-default.json`:**
- o domínio `wallpaper` aponta pra `fixtures/wallpapers/`;
- `all: scene:menu`;
- transição de fábrica.

Ela inclui os domínios da `hud-default.json`, pra barra também ficar fixa. O formato está em
[data-model.md](data-model.md) ("Fixture").

**Imagens de teste (`shell/fixtures/wallpapers/`):**
- `ruins.jpg` (16:9);
- `dunes.png` (4:3);
- `parede 'teste' #1 (larga).png` (21:9, nome difícil);
- `quebrada.jpg` (corrompida).
- `night.jpg` (16:9, escura: a barra fica no tom claro; emenda da US6).

## Cenários

| # | Prova | Como | Esperado |
|---|---|---|---|
| 1 ⚙ | SC-001 | Workspace vazio, `lab/shot fundo`; medir com ImageMagick as médias do centro (400×200), do meio das laterais e dos cantos (80×80, fora da barra e das linhas); alta frequência (imagem − blur de 3 px) numa área de 400×200 sem linhas | Centro, bordas e cantos a ≤ 4 níveis de `#C8C3AC` / `#A6A18D` / `#8C8978`; desvio da alta frequência < 1,0 (sem grid). Repetir com `lab/profile hidpi` |
| 2 ⚙ | SC-002 | Dois `lab/shot` do fundo, `lab/diffshot`; depois, com `ipc call wallpaper picker open`, mais dois e outro `diffshot` | 0 px de diferença nos dois pares |
| 3 ⚙ | SC-003 | Pra cada id do `ipc call wallpaper list` (4 cenas + 3 imagens válidas): `set <id> all`, `lab/shot`, `dump` | O `dump` mostra o id em `current`; o screenshot mostra a cena ou a imagem cobrindo a tela (4:3 e 21:9 cortadas, sem esticar), com o filtro de papel nas imagens; `quebrada.jpg` não está na lista |
| 4 ⚙ | SC-004 | `lab/key alt-w`, `dump`; depois `lab/key down` ×2, `ret`, `right`, `down`, `right`, `esc`, `esc`, um `dump` depois de cada tecla | Fim: `current` = 3º item (`scene:dark`), transição = `wipe`, `picker: null`; cada `dump` intermediário bate com o passo (foco, índice, opção) |
| 5 | SC-005 | `ipc call fixtures clear`; pra cada transição: `ipc call wallpaper transition <kind>`, `lab/burst` (camuflagem: 40 quadros / 100 ms; outras: 15 / 70 ms) disparado junto com `set scene:dark all` (e de volta pra `scene:menu`) | Camuflagem: quadros com refração antes da onda, células pixeladas resolvendo, contornos sumindo, uma falha de 1 quadro e, no fim, o fundo novo limpo. Varredura: borda de régua andando da esquerda pra direita. Quadradinhos: quadrados de tinta antes das células novas. Crossfade: mistura. Fecha com `ipc call fixtures load …wallpaper-default.json` |
| 6 ⚙ | SC-006 | Sem fixture `wallpaper` (`fixtures load hud-default.json`): `set scene:dark Virtual-1`, `lab/ssh 'pkill -x qs'`, esperar, `dump` + `lab/shot`; conferir `~/.local/state/yorha-os/wallpaper.json` na VM | Depois do reinício, `current` continua `scene:dark`; o arquivo de estado tem `monitors.Virtual-1 = scene:dark`; `~/.config/yorha-os/` não foi tocado |
| 7 ⚙ | SC-007 | Seletor aberto; `lab/ssh cp ~/nier/ui/fixtures/wallpapers/ruins.jpg ~/nier/ui/fixtures/wallpapers/nova.jpg`; `dump` a cada 250 ms; depois `set` do arquivo de nome difícil | `nova.jpg` aparece no catálogo em ≤ 2 s; o nome difícil aplica (`dump` + screenshot). Apagar `nova.jpg` no fim |
| 8 ⚙ | SC-008 | Relatório do `lab/perf end` (seção "Dentro da VM") + `qmllint` dentro da VM | 0 erros e 0 avisos de QML no roteiro (a linha do `quebrada.jpg` usa `console.info`, R6); lint limpo, fora os falsos positivos conhecidos |
| 9 | SC-009 | Sessão `lab/perf` à parte: 10 trocas seguidas com camuflagem, e outra com crossfade (opcional: `QSG_RENDER_TIMING=1` em `~/nier/ui.env`) | O custo das duas fica no relatório, sem meta |
| 10 | SC-010 | Imagem final: as 4 cenas, o seletor aberto, uma imagem com e sem filtro e 6 quadros da camuflagem, ao lado do mockup | O dono aprova |
| 11 | Bordas | `Settings.wallpaperFolder` numa pasta inexistente (via `shell.json` na VM); `ipc call wallpaper set image:/nao/existe all`; troca no meio de outra (dois `set` com 300 ms entre eles, sem fixtures) | Grupo IMAGES com o aviso de onde pôr imagens; `set` responde erro; a segunda troca parte da tela atual, sem pulo (rajada) |
| 12 | Galeria | `ipc call gallery open`, `lab/shot galeria` | Seção Wallpaper com as cenas, o filtro, o quadro congelado de cada transição e a lista com e sem foco |

## Fechamento

```sh
lab/down
lab/perf end --result pass --note "004 validada"
```

O relatório vai pro `YoRHa-OS-relatorios`. Os screenshots, as rajadas e os `dump`s são a evidência
pra revisão do dono (SC-010).
