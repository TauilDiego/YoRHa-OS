# Implementation Plan: SYSTEM de verdade

**Branch**: `019-sistema-real` | **Date**: 2026-11-03 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/019-sistema-real/spec.md` (aprovada pelo dono em 03.11)

**Status**: esperando o OK do dono (princípio V). A T003 é o primeiro passo depois dele.

## Summary

As 15 opções das etapas 0 e 1 param de inventar valor. Cada linha passa a falar com o sistema por um **provedor** (`sys.*`), e
o que depende do compositor passa pelo adaptador. Quem edita o próprio arquivo fica com o que escreveu, em todas as opções com
arquivo por trás. Tudo sem editar arquivo da pessoa e sem ferramenta nova.

As decisões de desenho:
- **Fonte viva:** `"setting": "sys.<provedor>.<chave>"`, atendida por um singleton por família (`SysAudio`, `SysPower`,
  `SysDisplay`, `SysInput`), no molde do `NotifyPrefs` (R4, `contracts/system-provider.md`). A linha nunca lê `value` do
  catálogo.
- **Base do arquivo:** lida com `getoption` logo depois do `configreloaded`, e na primeira subida de uma sessão, antes de
  reaplicar; o `shell.json` é lido cru, na subida e quando muda. Um singleton só, `FileWins`, compara e esquece
  (R1, `contracts/file-rule.md`). **A T003 prova isso na VM antes de qualquer código.**
- **`YORHA_MOD`:** `hyprctl repl 'return YORHA_MOD'`, no backend (R2).
- **Interface scale e Top bar height:** ficam em `Settings.keys`, no molde da U13, com um tipo novo que aceita valor fora da
  lista (R4, FR-032, FR-033).
- **Linha que some:** `"requires": "<capacidade>"` no catálogo, e `SettingsModel.visibleCategories` (FR-045).

## Technical Context

**Language/Version**: QML / JS (Qt 6.12), Quickshell 0.3.2, Bash (lab), Lua (config do Hyprland)

**Primary Dependencies**: `Quickshell.Services.Pipewire`, `Quickshell.Services.UPower`, `hyprctl`, `wpctl`, `udevadm`, `brightnessctl` (opcional). Nada novo em `system/deps` (FR-038)

**Storage**: `$XDG_STATE_HOME/yorha-shell/settings.json` (`SettingsState`); leitura de `shell.json`

**Testing**: `lab/check-019` (novo) e as checks antigas, em VM, com `lab/perf`

**Target Platform**: Arch, Hyprland 0.56 e 0.57 com config em Lua. Niri e Mango só pelo `NullBackend` nesta spec

**Project Type**: UI de desktop (shell Quickshell)

**Performance Goals**: mudança de fora na linha em até 1 s (SC-003). Releitura periódica só com a categoria aberta (R5). Sem otimização além disso (princípio VII)

**Constraints**: nenhum arquivo da pessoa é escrito; com fixtures nada é lido nem escrito no sistema; log sem WARN/ERROR; nada roda na máquina do dono

**Scale/Scope**: 15 opções (etapas 0 e 1); sob a regra do arquivo, as chaves da FR-041 e 4 opções do compositor. As 16 restantes têm só a seção de dependências abaixo

## Constitution Check

*GATE: passa antes da pesquisa e depois do desenho.*

| Princípio | Como o plano cumpre |
|---|---|
| I. Sistema do dono | Tudo roda em VM. O hardware real entra só como teste do dono, depois de instalar. A leitura da fonte do Hyprland foi pelo GitHub; nenhum `hyprctl` rodou no host |
| II. Sistema visual | `hyprland.lua` e `shell.json` são só lidos. A escrita em tempo de execução é o que a emenda 2.2.0 permite. A check-019 confere o `sha256sum` |
| III. Padrões e usuário | Update não esquece valor (FR-043). A remoção dos valores falsos é idempotente (FR-007) |
| IV. Evidência | Cada tarefa de teste nomeia a evidência, e cada rodada fica em `lab/perf` |
| V. Spec antes de código | Spec aprovada. **O plano espera o OK do dono.** Se a prova falhar, a D2 volta pra ele |
| VI. Paralelo com contrato antes | Etapa 0 sequencial, com a T003 antes; as frentes só começam depois do congelamento (T021) |
| VII. Simplicidade | Um provedor por família, nenhuma camada a mais. `SysProof` tem uso concreto: testar a mecânica antes de existir som |
| Restrições (adaptador, marcas, licença) | FR-044 cumprida; nenhum asset; nenhum código de terceiro. Serpantinum fica só como referência das etapas 2 e 3 |

Sem violações. Nenhuma linha em Complexity Tracking.

## Project Structure

### Documentation

```text
specs/019-sistema-real/
├── spec.md, plan.md, research.md, data-model.md, quickstart.md, tasks.md
├── sondagem.md          # resultado da T003
└── contracts/           # system-provider, file-rule, compositor-adapter, ipc
```

### Source Code

```text
shell/services/
├── SysProviders.qml, SysAudio.qml, SysPower.qml, SysDisplay.qml, SysInput.qml, SysProof.qml, FileWins.qml   # novos
├── SettingsModel.qml, Settings.qml, Compositor.qml, Osd.qml, compositor/{HyprlandBackend,NullBackend}.qml
shell/settings/SettingsPage.qml, shell/ds/composites/ChoicePopup.qml, shell/shell.qml, shell/strings/
shell/fixtures/settings-{default,showroom,proof}.json, sys-*.json

YoRHa-OS-private/lab/ (branch lab-019)
├── check-019, 019/prova-base, 019/audio-sinks, 019/block-*.sh
└── check-003, check-004, check-007, check-008, check-013, guest/hyprland.lua
```

## Frentes, modelo e donos dos arquivos

Toda frente de implementação roda em **Opus 5.5, esforço high**, pedido do dono pra esta spec.

| Frente | Modelo | Worktree / branch | Lab | VM | Só ela mexe em |
|---|---|---|---|---|---|
| **0** (sequencial) | Opus 5.5 high | esta / `019-sistema-real` | `lab-019` | `t-prova-56`, `t-prova-57`, `t-base-0` | `SettingsModel`, `SettingsPage`, `ChoicePopup`, `shell.qml`, `FileWins`, `SysProviders`, `SysProof`, `Strings`, `qmldir`, schemas, `Settings.keys`, `NullBackend`, `check-019` |
| **1A** [P] | Opus 5.5 high | `YoRHa-OS-wt/019-a` / `019-a` | `lab-019-a` | `t-som-1a` | `SysAudio`, bloco `sound` do catálogo, `019/block-audio.sh` |
| **1B** [P] | Opus 5.5 high | `YoRHa-OS-wt/019-b` / `019-b` | `lab-019-b` | `t-leituras-1b` | `SysPower`, `SysDisplay`, `Osd`, blocos `display` e `power`, `019/block-reads.sh` |
| **1C** [P] | Opus 5.5 high | `YoRHa-OS-wt/019-c` / `019-c` | `lab-019-c` | `t-teclado-1c` | `SysInput`, partes de teclado de `HyprlandBackend` e `Compositor`, bloco `keyboard`, `019/block-keyboard.sh` |
| **1D** [P] | Opus 5.5 high | `YoRHa-OS-wt/019-d` / `019-d` | `lab-019-d` | `t-aparencia-1d` | `Settings.uiScale` e `barHeight`, bloco `appearance`, `Hud`, `PopupFrame` e o layout que estourar, `019/block-appearance.sh` |
| **J** (junção, sequencial) | Opus 5.5 high | esta | `lab-019` | `t-juncao-1`, `t-juncao-2` | os merges, a rodada inteira |

Lab: no máximo 4 VMs ao mesmo tempo, cada uma com `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`, nomes `t-<tema>-*` (o `provision-step` já os aceita).
As branches do lab nunca vão pro GitHub. A `lab-019` sai da `lab-015-correcoes` (`b44fe67`) e por isso traz a `check-015`, que só
existe nas `lab-015*`; a `check-014` também está lá.

### Como as frentes dividem o que é compartilhado

- **`shell/fixtures/settings-default.json`:** uma opção por linha. Cada frente muda só as linhas do próprio bloco de categoria
  (`sound`; `display` e `power`; `keyboard`; `appearance`). Entre dois blocos há sempre linhas que ninguém muda, e o git junta sem conflito. A etapa 0 só
  põe `requires` em Layouts. Nenhuma frente muda ordem, categoria, `about` nem o `needs`.
- **`Settings.keys`:** só a etapa 0 mexe. Ela já deixa `shell.uiScale` e `shell.barHeight`. As chaves `input.*` não entram na tabela,
  porque não têm chave no `shell.json`: ficam direto no `SettingsState`, com o `SysInput`.
- **`Strings.qml`, `qmldir`, `SettingsModel`, `SettingsPage`, schemas:** só a etapa 0, com todos os textos e singletons das quatro frentes.
  Os singletons começam como esqueleto, fora do catálogo do produto; então uma linha falsa continua falsa até a frente dela entrar, e nunca aparece
  o estado "indisponível" por falta de código (FR-004).
- **`HyprlandBackend` e `Compositor`:** a etapa 0 entrega a leitura, a escrita e as telas. Só a 1C mexe de novo, nas partes de teclado; a 1B lê pela fachada.
- **`check-019`:** a etapa 0 entrega o esqueleto, que faz `source` de `019/block-*.sh`. Cada frente só escreve o próprio arquivo.
- **Mudança no contrato durante o paralelo:** a frente para e avisa quem coordena. Nenhuma frente edita arquivo de outra.

## O que não se prova na VM (teste do dono, depois de instalar)

Nenhuma tarefa roda na máquina do dono. A entrega da etapa 1 traz esta lista marcada como dele (SC-007):
saídas reais (alto-falante, fone, HDMI) e microfone real; a sensação da repetição e o Caps Lock físico; Interface scale e barra no notebook; o
Hz real do painel; bateria, carregador e luz de tela de verdade.

## Etapas 2 e 3 (sem tarefas aqui)

A 0.1.0 espera as duas (FR-012, D1). Cada item recebe requisitos quando chegar a vez, e usa o contrato desta spec sem mudar: provedor novo em `SysProviders`,
capacidade nova no adaptador.

| Etapa | Item | Depende de |
|---|---|---|
| 2 | Mudar Resolution, Refresh rate e Scale | Spec 018 e as decisões do dono sobre ela; `monitorSet` no adaptador. A proposta da 018 tira as três do Display |
| 2 | Cursor size | D-21 (o cursor no instalador); `cursorSize` no adaptador |
| 2 | Language | Fase U5b: `Strings.qml` e o catálogo por idioma |
| 3 | Power › Profile | Conversa com o dono: power-profiles-daemon |
| 3 | Screen off after, Suspend after | Conversa: IdleMonitor e logind; suspender sem trancar liga com a D-03 e a 017 |
| 3 | Night light | Conversa: hyprsunset |
| 3 | Lid closed | Conversa: logind e bind `switch:`; `lidSwitch` no adaptador |
| 3 | Wi-Fi, Network, Wired, VPN | Conversa: NetworkManager |
| 3 | Bluetooth, tudo | Conversa: bluez |
| 3 | Airplane mode | Network e Bluetooth prontos |

A ordem da etapa 3 é a da spec, e cada ferramenta **espera uma conversa com o dono**; cada uma aceita entra como opcional em `system/deps`. O UPower entra nessa
conversa (R8). A SC-008 (nenhum valor inventado no catálogo) só fecha com as duas etapas prontas.

## Riscos

| Risco | O que faz |
|---|---|
| A prova da T003 falha | Coluna da direita de R1; se não resolver, a etapa 0 para e a D2 volta pro dono |
| Layout não aguenta 125% com 40 px ou 80 px (FR-034) | É o risco da 1D, e ela é dona dos arquivos de layout que precisar mudar. Mudança que cruze com outra frente vai pra junção |
| `check-*` antigas quebram por detalhe do novo catálogo | T018 ajusta antes do paralelo, e a T020 confere |
| A saída não sobrevive ao reboot (US2.8) | A D4 volta pro dono |
| Versão da 0.57 diferente da 0.56 | A prova roda nas duas; `hypr-057` é camada de `lab-057` (armadilhas no README dessa branch) |

## Complexity Tracking

Nenhuma violação da constituição.
