# Quickstart: validar a 008 na VM

Tudo roda no laboratório privado (constituição I), dentro de `lab/perf begin/end`. O roteiro inteiro
vira o `lab/check-008` (`--only <bloco>`, `--profile 1080|hidpi`), no padrão do `lab/check-u1`:
`ok`/`ko` por item, uma pasta de evidência e um `summary.txt`. Formatos: [contracts/ipc.md](contracts/ipc.md).

## Preparação

```
export NIER_LAB_VM=teste-b NIER_LAB_CPUS=4 NIER_LAB_MEM=4G YORHA_OS_REPO=<worktree>
lab/perf begin "008: check"
lab/up teste-b                       # o check-008 liga sozinho, no perfil hidpi (os dois modos existem)
lab/provision-step notify            # libnotify, pipewire, wireplumber, brightnessctl; sink e source nulos
lab/sync --src <worktree>/shell
lab/check-008 [--only <bloco>] [--profile 1080|hidpi]
lab/down; lab/perf end
```

**Pré-condições que o roteiro confere antes de tudo** (research R3), e para se falharem:
- nenhum `.service` com `Name=org.freedesktop.Notifications` em `/usr/share/dbus-1/services/` nem em
  `~/.local/share/dbus-1/services/`;
- nenhum processo `mako`, `dunst` ou `swaync`;
- `busctl --user status org.freedesktop.Notifications` → `Comm=qs` (ou `quickshell`);
- `wpctl status` com o sink nulo como padrão;
- o log de QML limpo desde o reinício.

## Blocos (o que cada um prova)

| Bloco | Passos | Evidência | SC |
|---|---|---|---|
| `server` | `notify dump` | `server: true`, `serverOwner` | FR-001 |
| `first` | `t0=$(date +%s%3N)`; `notify-send "Build" "The nightly build finished."`; `lab/burst` de 1 s no canto | quadros durante e depois da digitação; `shownAt − t0 ≤ 500`, `typedAt − shownAt ≤ 800` | SC-001 |
| `urgency` | `notify-send -u low|normal|critical`; `dump` a cada segundo por 65 s | tempos de saída (±0,3 s); a crítica ainda na tela em 60 s; screenshot da faixa crítica | SC-003 |
| `actions` | `notify-send --wait --action=open=Open --action=later=Snooze …` em segundo plano; clique no "Snooze" pela `box` do `dump` (`lab/click`) | saída do `notify-send` = `later`; `hyprctl activewindow` antes = depois | SC-004 |
| `reply` | `lab/notify-client reply` (gdbus); `lab/click` no "Reply"; `lab/key` digita `ok thanks` + Enter | o cliente imprime `ok thanks`; janela em foco antes = depois; Esc num segundo teste não manda nada | SC-004 |
| `flood` | `notify sample script100`; `dump` | ≤ 3 na tela, 100 no log, `unread` certo; log abre em ≤ 0,3 s; CPU do `qs` em repouso em ≤ 5 s (relatório do `lab/perf`) | SC-005 |
| `group` | `notify sample flood5` | uma transmissão `count: 5`; 5 entradas | SC-006 |
| `dnd` | `ALT + CTRL + N` (tecla real); 5 normais + 1 crítica; reiniciar o `qs` | 0 normais e 1 crítica na tela; 6 no log; `DND 5` no `hud dump`; `prefs.dnd` igual depois do reinício | SC-007 |
| `fullscreen` | kitty em tela cheia; `notify-send`; sair da tela cheia | nada na tela durante; `unread` sobe; nada aparece de uma vez depois | US6-4 |
| `osd` | `lab/key volumeup` ×3 (teclas reais); `wpctl get-volume`; `lab/burst` até 2 s; `audiomute` | um OSD só, com o valor do `wpctl`; some entre 1,0 e 1,5 s; MUTE apagado; `notify osd brightness 40` | SC-008 |
| `osd-quiet` | abrir configurações, foco em Sound › Volume; `wpctl set-volume` de fora | `osd: null` | FR-029 |
| `log-keys` | fixture `notifications-default.json`; `ALT + N`; ↓ ↓ Enter Delete → (←/→ no DND) Esc Esc, com `dump` depois de cada tecla | o estado esperado em cada passo; log fechado no fim | SC-009 |
| `monitors` | segundo monitor (`hyprctl output create headless`); foco nele; notificação, crítica e OSD | screenshots dos dois; tudo só no monitor em foco | SC-010 |
| `reduced` | `reduceMotion: true` (shell.json da VM); `lab/burst 0` na chegada | o primeiro quadro com a transmissão já tem o texto inteiro | SC-011 |
| `prefs` | configurações › Notifications com teclas reais: `Position` nas três (uma transmissão parada na tela e uma nova em cada), `OSD position` Top, `System voice` System + `notify sample system` | screenshots antes/depois; `screen[].box`, `osd.box` e `speaker` no `dump`; sem `warn` | SC-014 |
| `saved` | `Text log` → Saved; 5 notificações; reiniciar o `qs`; reiniciar a sessão da VM; voltar pra Session only | `log.count: 5` depois de cada reinício, `earlier: true`; `stat -c %a` = 600; arquivo some no fim; `ls -la ~/.config` igual antes e depois | SC-015 |
| `shots` | fixtures: pilha (normal, ações, imagem, progresso), crítica, OSD, log aberto, as 3 posições; cada um duas vezes | `lab/diffshot` = 0 px, em 1080 e hidpi | SC-002 |
| `gallery` | galeria, página da 008 | screenshots; a `LogPage` nos dois tamanhos sem corte | SC-016 |
| `edge` | sem nome de app; só título; marcação (`<b>`, `<a>`, `<img>`, `<script>`); imagem quebrada; passageira (`-e`); substituição (`notify-client replace`); progresso 0→100; volume 120%; outro servidor (`notify-client hold-name` antes de subir o `qs`) | `dump` e screenshots; no último, `server: false` e a única linha de log esperada | casos de borda |
| `lint` | `qmllint` dentro da VM; log de QML do roteiro inteiro | 0 erros, 0 avisos (fora as duas linhas esperadas do bloco `edge`/outro servidor, categoria `quickshell.service.notifications`, filtradas) | SC-012 |

Os screenshots pra aprovação do dono (SC-013) saem dos blocos `shots`, `prefs` e `gallery`, montados
lado a lado com o mockup numa imagem só (`out/008-revisao.png`).
