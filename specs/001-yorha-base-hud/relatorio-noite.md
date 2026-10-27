# Relatório da noite (2026-10-27): implementação do U1

## Resumo

O U1 está **implementado e validado na VM**. O HUD, a galeria e o design system completo estão
no `shell/`. O roteiro do `quickstart.md`, automatizado em `lab/check-u1`, passa **12 de 12**
checks em 1080p, e o SC-008 passa em 2560x1600 @1,25. Ficam 37 de 40 tarefas concluídas; as 3
pendentes dependem de você ou são opcionais (ver "Pendências").

Imagem final (HUD em 1080p, HUD em hidpi, galeria): enviada na conversa e salva em
`/tmp/claude-1000/-home-diego-projects-nier-os/af714ffc-7877-47c9-a81d-c3bc321932d9/scratchpad/u1-final.png`.

## Critérios de sucesso

Evidência em `~/.local/share/nier-lab/out/check-u1-20261027-015500/`, mais a sessão de hidpi.

| Critério | Resultado | Evidência |
|---|---|---|
| SC-001 HUD com os dados de teste | ✅ abas 01–05 (02 descendo até a régua), CPU 23 / MEM 41 / VOL 64 / BAT 87, título, 2026.10.26 13:37:00 | `sc001-hud.png`, `sc001-dump.json` |
| SC-002 dois screenshots iguais | ✅ 0 px de diferença na faixa do HUD | `sc002-a-hud.png`, `sc002-b-hud.png` |
| SC-003 clique na aba | ✅ clique real via QMP na aba 03 → workspace 3 em ≤ 0,34 s, medido do host incluindo o ssh (≈ 27 ms dentro da VM) | `sc003-click.png`, `sc003-latency-s.txt` |
| SC-004 galeria | ✅ todas as peças e estados com nome; abre e fecha por IPC e por Esc | `sc004-gallery.png`, `sc004-after-esc.png` |
| SC-005 / FR-017 log | ✅ 0 erros e 0 avisos no último carregamento | `log-after-launch.txt` |
| SC-006 aprovação visual | ⏳ **é sua** | imagem final |
| SC-007 recarga ao vivo | ✅ 2,2 s | `sc007-reload-s.txt` |
| SC-008 hidpi | ✅ barra com 40 px lógicos = 50 físicos; grid e régua na grade física, sem meio pixel | `sc008-hidpi.png` |
| Casos de borda | ✅ bateria baixa (vermelha), sem bateria (some), mudo ("MUTE"), título longo (reticências + 7 abas), sem janela (vazio) | `edge-*.png`, `edge-*.json` |
| qmllint | ✅ limpo, fora dois falsos positivos conhecidos do Quickshell | `qmllint.txt` |

## Como a noite foi

1. **Laboratório (privado):**
   - várias VMs ao mesmo tempo (`NIER_LAB_VM`, porta e sessão `lab/perf` por VM);
   - `lab/sync --env` (fixtures na VM);
   - `lab/diffshot`;
   - perfil hidpi (`NIER_LAB_PROFILE=hidpi` + `lab/profile`);
   - `lab/check-u1`.
2. **Contrato:** feito por mim: tokens, textos, configurações, fixtures, IPC, fonte M PLUS 1
   embutida.
3. **Agentes em paralelo**, cada um com worktree e VM próprios:
   - primitivas + base (`teste-a`) e serviços (`teste-b`);
   - depois, HUD (`teste-a`) e galeria (`teste-b`).
4. **Integração e correções** feitas por mim (`teste-c`):
   - nitidez em escala fracionária;
   - título vazio na partida;
   - fechamento da galeria;
   - validação final.

## Problemas encontrados e corrigidos

- **Fonte variável fina:** o Qt ignorava o peso da M PLUS 1. Corrigido no `Label` (eixo `wght`),
  então todo texto passa pelo `Label`.
- **hidpi borrado:** o Qt informa escala 2 pra tela, e a janela renderiza em 1,25. Agora a escala
  real vem de `hyprctl monitors -j` e as primitivas de linha fina encaixam na grade física.
- **`Hyprland.monitors` vazio e `refreshMonitors()`/`refreshWorkspaces()` esvaziam as listas**
  com a config em Lua. Removi as chamadas e o título inicial vem de `hyprctl activewindow -j`.
- **UPower sem daemon gerava 2 WARN:** a bateria só usa o UPower se ele estiver instalado.
- **`pkill -f nier-ui-run` matava o próprio comando** no lab: o runner agora é reiniciado por um
  script via stdin.

## Decisões tomadas sozinho (confira)

- **Realce:** 150 ms (token), como estava proposto.
- **Pipa na aba selecionada do HUD:** escura. A clara some sobre o papel; foi o que a maquete
  aprovada mostrava.
- **Espaço do seletor:** reservado antes de **toda** aba, pra o hover não fazer a aba fugir do
  mouse. O passo entre abas fica igual ao do jogo.
- **Régua pontilhada da barra:** em escala reduzida (s × 0,3), parecida com a A2. O padrão em
  tamanho cheio não cabe em 40 px.
- **Volume mudo:** mostra "MUTE". Bateria carregando: "87+".
- **Abas apagadas:** fundo `lightGray` com tinta `mediumGray`. A A2 usava opacidade 0,55, então
  ficaram um pouco mais fortes que na maquete.
- **Galeria:** card reduzido (538×220) pra caber; a lista com cursor usa um cursor só, como no
  jogo.
- Os agentes fizeram mais acréscimos aditivos ao contrato. Estão listados nas mensagens de
  merge e nos commits deles.

## Pendências

1. **T038 polimento visual, depende de você:**
   - a pipa duplicada da sua imagem: não reproduzi em 6 quadros; preciso saber de onde veio;
   - a pipa clara;
   - a intensidade das abas apagadas.
2. **WARN do Qt ao fechar a galeria:** `qt.qpa.wayland.textinput … disableSurface`, 1 por
   fechamento. É interno do Qt, aparece só ao **fechar** (não no carregamento) e não afeta nada.
   Já testei e não resolveu:
   - fechar em duas fases (reduziu de 2 pra 1);
   - esconder a janela em vez de destruir;
   - `QT_WAYLAND_TEXT_INPUT_PROTOCOL`.
3. **T039 `/speckit-analyze`:** não rodei.
4. **SC-006:** sua aprovação visual.

## Custo no seu sistema (`lab/perf`)

- **10 sessões** com duração somada de 2809 s; algumas rodaram em paralelo.
- **CPU:** 660 s de CPU nas VMs; no host, de −1,9 a +3,9 pp acima da base; pico de 21%.
- **RAM:** pico de 2,7 GB por VM.
- **Pressão nos seus processos:** no máximo 1,8 s de espera de CPU por sessão.
- Detalhes em `~/projects/rien-OS-relatorios/HISTORY.md`.

## Commits (nada foi enviado pro GitHub)

- **`nier-os`, branch `001-yorha-base-hud`:**
  - design system, spec, plano e tarefas;
  - contrato;
  - merges dos 4 agentes;
  - correções.

  Use `git log --oneline main..001-yorha-base-hud`.
- **`rien-OS-private`, branch `lab-u1`:** `lab/perf`, várias VMs, fixtures na VM, `diffshot`,
  perfil hidpi, `check-u1`, referências.
- **`rien-OS-relatorios`, `main`:** um commit por sessão de teste.
- A `main` de cada repositório ficou intocada. O merge é seu.

## Como ver

```sh
cd ~/projects/rien-OS-private
export NIER_LAB_VM=teste-c
lab/up teste-c && lab/check-u1          # roda tudo de novo e junta a evidência
lab/ipc 'qs -p ~/nier/ui ipc call gallery open' && lab/shot galeria
lab/up teste-c --window                 # ou ver numa janela (ALT+Enter abre o kitty)
```
