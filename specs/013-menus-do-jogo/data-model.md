# Data model: Menus do jogo (013)

## Opções novas (`SettingsState`, salvas como as outras)

| Chave | Tipo | Padrão | Onde aparece | Regra |
|---|---|---|---|---|
| `shell.menuPresentation` | `"floating"` \| `"fullscreen"` | `"floating"` | Appearance › Menu presentation | Troca ao vivo (FR-013) |
| `sound.ui` | bool | `true` | Sound › Interface sounds | Desliga todos os sons da interface, menos os de boot e login |
| `sound.volume` | int 0–100 | `40` | Sound › Interface volume | Por cima do volume do sistema |
| ~~`sound.typing`~~ | — | — | — | Sai (decisão do dono, 01.11: sem som de digitação, nem como opção) |
| `sound.folder` | string | `""` (os nossos) | Sound › Sound folder | Arquivo por evento (contracts/sounds.md). O que faltar usa o nosso |
| `sound.bootLogin` | bool | `true` | Sound › Boot and login sounds | Copiado pro estado de som (abaixo) |
| `input.kbLayouts` | string[] (≥ 1) | o layout atual | Keyboard › Layouts (janelinha múltipla) | Aplicado no Hyprland (research R6) |

A opção antiga Keyboard › Layout (uma só escolha) vira a lista acima.

## Estado de som salvo (`~/.local/state/yorha-os/sound.json`)

Escrito pelo serviço `Sounds` quando o volume, o mudo ou `sound.bootLogin` mudam:

```json
{ "volume": 0.64, "muted": false, "uiVolume": 40, "bootLogin": true, "updated": "2026-10-31T21:00:00-03:00" }
```

Lido no boot pelo `yorha-boot-sound`, do último usuário que entrou (`/var/lib/sddm/state.conf`).
- **Sem o arquivo:** toca a 30%.
- **Com `muted` ou `bootLogin` falso:** não toca.

## Eventos de som

| Evento | Quando | Nosso arquivo (`system/sounds/`) | Espelha (frente C) |
|---|---|---|---|
| `move` | cursor anda numa lista | `move.wav` | 03 tique |
| `change` | um valor muda (◂ ▸, controle deslizante) | `move.wav` | 03 |
| `confirm` | Enter, clique, entrar numa coluna | `confirm.wav` | 06 brilho |
| `back` | Esc, sair de uma coluna | `back.wav` | 03 mais grave |
| `open` / `close` | abrir / fechar um menu | `open.wav` / `close.wav` | 19 / 19 ao contrário |
| `tab` | trocar de aba | `tab.wav` | 22 |
| `dialog` | confirmar um diálogo | `dialog.wav` | 07 duas notas |
| `choiceOpen` / `choicePick` | abrir / escolher na janelinha | `open.wav` / `confirm.wav` | 19 / 06 |
| `notify` / `notifyCritical` | notificação normal / crítica | `notify.wav` / `notify-critical.wav` | 09 / 10 |
| `osd` | passo do volume ou do brilho | `move.wav` | 03 |
| ~~`typing`~~ | não toca (decisão do dono, 01.11) | `typing.wav` e a receita saíram na limpeza de 01.11 | 08 |
| `sessionStart` | o desktop aparece depois do login | `session-start.wav` | 02 |
| `bootStart` | a placa de som fica pronta no boot | `boot-start.wav` | 01 |
| `loginIntro`, `loginMove`, `loginConfirm`, `loginError`, `loginPower` | eventos da tela de login | `intro.wav`, `move.wav`, `confirm.wav`, `error.wav`, `close.wav` | 01, 03, 06, inventado, 19 ao contrário |

`error` não tem som no jogo, então é inventado: um tique grave duplo.

## Estado do menu (no `pause dump`)

O que entra:
- `presentation`;
- `tab` (agora também `"log"`);
- `anim`: `"idle" | "opening" | "assembling" | "tab" | "closing"`;
- `choice`: `null`, ou `{ option, values, selected, multi, checked[] }`.

Usados pelo `check-013` pra esperar o fim de cada animação e conferir a janelinha.
