# Quickstart: validar o menu de pausa no laboratório

O roteiro que prova cada critério de sucesso com evidência da VM (princípio IV). Tudo roda no
ambiente privado (`rien-OS-private/lab`, branch `lab-007`) e **dentro de uma sessão de medição**.
Nada disso roda na máquina do dono. O `lab/check-007` automatiza as linhas marcadas com ⚙; cada
frente tem o seu bloco marcado no roteiro (`--only us1|apps|windows|power|live|gallery`).

## Preparação

```sh
cd ~/projects/rien-OS-private
export NIER_LAB_VM=teste-a NIER_LAB_CPUS=2 NIER_LAB_MEM=4G     # limite do dono: ≤ 4 VMs de 2 núcleos e 4 GB
lab/perf begin "007: validação do menu de pausa" --kind validacao --task 007
lab/up teste-a && lab/profile 1080
lab/sync --src <worktree>/shell --env NIER_FIXTURES=~/nier/ui/fixtures/pause-default.json
```

- **Fixture `pause-default.json`:** os domínios da `hud-default.json` mais `apps`, `windows` e
  `session` (data-model, "Fixtures"). Com ela, nenhuma ação de energia executa (research R9).
- **Atalhos da VM:** `ALT + Escape` (menu) e `ALT + I` (SYSTEM).
- **Perfis:** cada bloco ⚙ roda em `lab/profile 1080` e de novo em `lab/profile hidpi`
  (2560x1600 @1,25), e o roteiro deixa a VM em 1080.

## Cenários

| # | Prova | Como | Esperado |
|---|---|---|---|
| 1 ⚙ | SC-001 | `pause reset`; `pause tab <aba>` + `lab/shot` + `pause dump` pras 4 abas; `tab power`, `lab/key down` ×5 (Shut down), `ret` → diálogo, shot; `pause search fir`, shot; `pause search zzz`, shot | 6 screenshots por perfil (12), cada um com o `dump` que bate (aba, título, rodapé, teclas; diálogo com `row: cancel`; busca com `results` e sem) |
| 2 ⚙ | SC-002 | Pra cada aba, dois `lab/shot` seguidos, `lab/diffshot` | 0 px de diferença nas 4 |
| 3 ⚙ | SC-003 | `fixtures load pause-live.json`, `pause reset`, `hyprctl clients -j` (antes); `lab/key alt-esc`, `k`, `i`, `t`, `ret`, medindo do host; `hyprctl clients -j` a cada 100 ms até aparecer um `kitty` novo | 5 teclas; a janela nova em ≤ 2 s; `lastAction` = `kitty.desktop`; o menu fechado |
| 4 ⚙ | SC-004 | As 10 consultas do roteiro (`fir`, `term`, `browser`, `pdf`, `cafe`, `FIRE`, `edit`, `vol`, `btop`, `zzz`) por `pause search`, um `dump` cada | O esperado de cada uma em `results[0]` (a tabela do roteiro fica no `check-007`); `zzz` com `results: []` e a linha `No apps match.` |
| 5 ⚙ | SC-005 | `pause reset`; tempo do host de `lab/key alt-esc` até `isOpen = true` (e o primeiro quadro com o painel, por `lab/burst`); depois `tab`×4, `shift-tab`, `alt-i`, `alt-i`, um `dump` por tecla; fechar pelos 3 caminhos (Esc, `alt-esc`, `lab/click` fora) com o kitty em foco antes, conferindo `hyprctl activewindow -j` depois | Abre em ≤ 0,3 s; APPS → WINDOWS → SYSTEM → POWER → APPS → POWER (Shift+Tab) → SYSTEM (`alt-i`) → fechado (`alt-i`); o kitty volta a ter o teclado nos três fechamentos |
| 6 ⚙ | SC-006 | `fixtures load pause-live.json`; o roteiro abre `kitty --title A`/`B` na área 1 e `C` na 2; `pause tab windows`, `dump`; `lab/key` até C + `ret`; reabre, vai até B, `right`, muda `Workspace` pra 02; vai até A, `Close`; `hyprctl clients -j` e `activewindow -j` depois de cada passo; shot do mapa | 3 janelas em 2 grupos; C ativa na área 2; B na área 2; A some da lista em ≤ 1 s; o mapa mostra a escolhida em tinta |
| 7 ⚙ | SC-007 | Com `pause-default.json`: Enter em Lock e em Suspend; Enter em Log out, Reboot e Shut down (o diálogo, `row: cancel`), fechando com Esc, com clique fora e com `Cancel`; de novo, ↑ + Enter (confirma); Hibernate (apagado); o diálogo de Shut down com o bloqueio | `lastAction` só nas confirmações e em Lock/Suspend (`executed: false`); nenhum registro nos cancelamentos; Hibernate não faz nada; `blockers` com o `pacman` |
| 8 | SC-007 (real) | Sessão `lab/perf` à parte: `fixtures clear`; `lab/ssh cat /proc/uptime`; menu → POWER → Reboot → ↑ → Enter; esperar a VM voltar (`lab/ssh` responde); `cat /proc/uptime` de novo | O tempo ligado zerou (a VM reiniciou); antes do reboot, o diálogo tinha a pipa em `Cancel` |
| 9 ⚙ | SC-008 | Sem fixtures, `lab/burst 20 40` com `down` no meio, em APPS; outra rajada trocando de aba | Pipa some e volta em ≈240 ms; nenhum quadro com pipa nas abas |
| 10 ⚙ | SC-009 | `fixtures clear`; menu em APPS; `lab/ssh` copia `rien-test.desktop` pra `~/.local/share/applications/`; `pause dump` a cada 250 ms; depois fixa o app (`right`, `Pinned`), `lab/ssh 'pkill -x qs'`, espera, `dump` | O app aparece em ≤ 2 s; depois do reinício, continua em PINNED (`~/.local/state/rien-os/apps.json` com o id); `~/.config/rien-os/` intacto. Apagar o `.desktop` no fim |
| 11 ⚙ | SC-010 | Relatório do `lab/perf end` (seção "Dentro da VM") + `qmllint` dentro da VM | 0 erros e 0 avisos de QML no roteiro; lint limpo, fora os falsos positivos conhecidos |
| 12 ⚙ | SC-011 | `gallery open`, Tab ×3, `lab/shot galeria-007` | A página 4 com cada componente novo nos estados do contrato |
| 13 ⚙ | SC-013 | Menu aberto; pra cada opção de `Pause menu`: `tab system`, ir até a opção, `right`; `tab` de volta pra aba que ela muda; shot + `dump` | `options` muda no `dump`; a prévia de APPS nos 3 estilos (3 shots); ALL APPS reordena; Enter num app com janela vai pra ela (`lastAction.kind: window`); `Every action` faz Lock pedir confirmação; `Action` começa o diálogo na ação |
| 14 | SC-012 | Imagem final: as 12 telas do cenário 1 + os 3 estilos de ícone, ao lado do mockup | O dono aprova |
| 15 ⚙ | Bordas | `pause-empty.json` (WINDOWS vazio, rodapé só com `Tab` e `Esc`), `pause-long.json` (rolagem com a pipa visível, reticências, dois monitores, SPECIAL), `pause-broken.json` (erro curto por aba, SYSTEM funciona), a recusa (`session.refuse`), app com comando inexistente (`WARN` no log, sem uso a mais), `wallpaper picker open` com o menu aberto (o menu fecha) | Como na spec (Edge Cases) |
| 16 ⚙ | 003 | `lab/check-003` adaptado (T019) | Continua passando com as configurações dentro da aba SYSTEM |

## Fechamento

```sh
lab/profile 1080
lab/down
lab/perf end --result pass --note "007 validada"
```

O relatório vai pro `rien-OS-relatorios`. Os screenshots, as rajadas e os `dump`s são a evidência
pra revisão do dono (SC-012).
