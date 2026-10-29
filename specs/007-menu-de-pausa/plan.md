# Implementation Plan: Menu de pausa

**Branch**: `007-menu-de-pausa` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: `specs/007-menu-de-pausa/spec.md`, com as decisões do dono de 2026-10-27 aplicadas
(commit `9a69e39`). A base de código é a `004-wallpaper-system` mesclada nesta branch (001, 003 e
004 completas: a moldura de popup, `GroupedList`, `PickerLayout`, `PreviewCard`, a barra
transparente com tom).

**Status**: aprovado pelo dono (27.10; o adaptador do compositor, contracts/compositor.md, em 28.10). Em implementação (tasks.md).

## Summary

O menu de pausa é **um popup da 003 com abas**. Um `PopupWindow` só, com a barra de abas do jogo no
painel e quatro páginas: APPS, WINDOWS, SYSTEM e POWER. Ele abre por `SUPER + Escape` (`ALT +
Escape` na VM), na última aba usada; o `SUPER + I` abre direto em SYSTEM.

**As páginas reusam o que já existe:**
- **APPS e WINDOWS:** o `PickerLayout` da 004 (lista agrupada, prévia, opções);
- **SYSTEM:** a `SettingsPage` da 003, inteira;
- **POWER:** a `GroupedList`, o `DescriptionCard` e um `StatusCard` novo, nas colunas da 004.

**As peças novas do design system:**
- `SearchHeader`;
- `AppIcon` (tinta, cor original ou quadrado);
- `WorkspaceMap`;
- `StatusCard`;
- `ConfirmDialog`.

**Os dados chegam por três fontes, cada uma com fixture:**
- **`Apps`:** os `DesktopEntries` do Quickshell, mais o estado dos fixados e dos usos;
- **`Compositor`:** as janelas e áreas de trabalho pelo `hyprctl -j`, e as ações por dispatch em
  Lua;
- **`Session`:** o logind, por `busctl`, `loginctl` e `systemctl`.

**A regra geral do dono vira a categoria `Pause menu` em SYSTEM:** cinco escolhas lidas ao vivo pelo
menu (`SettingsModel.choiceId`).

**Tudo se controla pelo IPC `pause`.** O `settings` da 003 vira um alias da aba SYSTEM.

**A prova é o `lab/check-007`:** roda na VM nos perfis 1080 e hidpi, dentro do `lab/perf`.

## Decisões deste plano

1. **`SUPER + I` abre o menu na aba SYSTEM**, e o popup avulso da 003 sai (research R2). Há uma
   superfície só pras configurações, com um estado só. O alvo `settings` continua, como alias, com
   o `dump` no formato da 003. Custo: o `lab/check-003` é adaptado (T021).
2. **As opções da regra geral** ficam numa categoria nova, `menu` ("Pause menu"), com o campo
   opcional `ids` nas escolhas (research R10):
   - `App icons`: `Ink` / `Original color` / `Square only`;
   - `App order`: `A–Z` / `Most used`;
   - `Running app`: `New window` / `Go to window`;
   - `Confirm`: `Risky ones` / `Every action`;
   - `Dialog starts on`: `Cancel` / `Action`.

   Elas valem pela sessão. Guardar entre sessões segue o mecanismo do `Bar contrast` (pergunta 1).
3. **Abrir um app nunca passa por shell** (research R4):
   - abre com `execDetached` e o argv do `.desktop`;
   - pra outra área de trabalho, o usuário vai pra lá antes;
   - o comando inexistente é conferido antes.
4. **Ícone em tinta = shader duotone** (`shaders/duotone.frag`), na infraestrutura de shaders da 004,
   com fallback em `MultiEffect` (research R6).
5. **Janelas pelo `hyprctl clients -j`** no `Compositor` (research R7), por causa das manias do
   Quickshell com o Hyprland em Lua; as ações vão por `Hyprland.dispatch` com expressões
   `hl.dsp.*` validadas (R8, conferidas num spike).
6. **Energia sem risco nos testes:** com qualquer fixture ativa, nenhuma ação executa (research R9).
   Só o cenário 8 do quickstart reinicia a VM, de propósito, sem fixture.
7. **Precisão da FR-023** (a spec foi ajustada junto com este plano):
   - `Lock`, `Suspend` e `Hibernate` fecham o menu e então executam;
   - `Log out`, `Reboot` e `Shut down` executam depois da confirmação e fecham o menu quando o
     sistema aceita;
   - uma recusa mantém o menu aberto, com o erro.

## Technical Context

**Language/Version**: QML (Qt 6.11) sobre Quickshell 0.3.1; JS (`.pragma library`) pra busca; GLSL
440 (o shader duotone, compilado pra `.qsb` onde a UI roda); Lua (config do Hyprland na VM); Bash
(lab).

**Primary Dependencies**: `Quickshell` (`DesktopEntries`, `execDetached`, `iconPath`),
`Quickshell.Wayland`, `Quickshell.Io` (`Process`, `FileView`, `IpcHandler`), `Quickshell.Hyprland`
(só no `Compositor`), `QtQuick`, `QtQuick.Effects` (fallback do ícone). Comandos do sistema, por
argv: `hyprctl`, `busctl`, `loginctl`, `systemctl`, `uwsm` (quando a sessão é dele), `sh` (só o
script fixo `command -v`). **Nenhuma dependência nova:** tudo vem com `systemd`, `hyprland`,
`uwsm` e `quickshell`, que já estão na VM e na base do instalador.

**Storage**:
- `$XDG_STATE_HOME/rien-os/apps.json` (fixados e usos; estado, nunca config);
- `shell/config/defaults.json` (+ `terminal`);
- `shell/fixtures/settings-default.json` (+ categoria `menu`);
- `shell/fixtures/pause-*.json` e `shell/fixtures/pause/` (dados e ícones de teste).

**Testing**: evidência na VM:
- screenshots (`lab/shot`, `lab/diffshot`, `lab/burst`);
- `qs ipc call pause dump` e `settings dump`;
- teclas e cliques reais via QMP (`lab/key`, `lab/click`);
- `hyprctl clients -j` e `activewindow -j` dentro da VM;
- `busctl monitor` (o sinal `Lock`);
- `/proc/uptime` (o reboot real);
- `qmllint` dentro da VM;
- o log de QML no relatório do `lab/perf`.

Sem testes unitários (princípio VII). A busca é uma função pura conferida pelas 10 consultas do
SC-004.

**Target Platform**: Arch Linux + Hyprland 0.56+ (Lua), só na VM até a U7. Perfis 1920x1080 @1 e
2560x1600 @1,25.

**Project Type**: desktop shell (UI de Wayland em QML)

**Performance Goals**: sem meta (U6). Abrir em ≤ 0,3 s (SC-005); a lista de janelas acompanha em
≤ 1 s (FR-017); um app novo aparece em ≤ 2 s (SC-009). As quatro páginas são criadas junto com o menu (research R1, revisto na T016); nenhum
polling (as janelas leem nos eventos; a energia, ao entrar na aba).

**Constraints**:
- sem blur (constituição VII);
- dois screenshots iguais com fixtures (SC-002), o que pede a fixture de janelas, o relógio fixo e
  nada animando;
- nenhum texto do usuário passa por shell (FR-012);
- nenhuma ação de energia com fixture;
- zero erros e zero avisos de QML (FR-031);
- `~/.config` nunca é escrito (constituição III);
- **limite do laboratório:** no máximo 4 VMs, cada uma com 2 núcleos e 4 GB.

**Scale/Scope**:
- 4 abas e 1 alvo de IPC novo (+ o alias);
- 3 serviços (2 novos: `Apps` e `Session`; o `Compositor` estendido) e 1 biblioteca JS;
- 5 componentes novos no design system e 4 páginas;
- 1 shader;
- acréscimos em 6 peças existentes;
- ≈30 apps e 8 janelas de teste.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Status |
|---|---|---|
| I. Sistema do dono intocável | A UI, o `qsb`, o `qmllint`, os roteiros e as ações de energia rodam só na VM. No host, só as ferramentas do lab (QEMU, ssh, rsync, ImageMagick, o `lab/perf`). A validação dos JSON contra o schema roda num container. Os atalhos entram na config da VM; os do sistema instalado ficam pro instalador (S3/U7) | ✅ |
| II. Camada sobre Arch limpo | Não instala nada: `systemd`, `uwsm`, `hyprland` e `quickshell` já são da base | ✅ |
| III. Padrões × arquivos do usuário | O padrão `terminal` fica no `defaults.json` (sobrescrito pelo `shell.json`, que só é lido). Os fixados e os usos são **estado** (`$XDG_STATE_HOME`). As opções de SYSTEM ficam em memória (como na 003) até a decisão da pergunta 1 | ✅ |
| IV. Pronto com evidência da VM | Cada SC tem prova no [quickstart.md](quickstart.md): screenshot, `pause dump`, teclas via QMP, `hyprctl`, o sinal no barramento, o uptime, rajadas, log | ✅ |
| V. Spec antes de código | As decisões do dono entraram na spec antes do plano. Este plano espera a aprovação. A ambiguidade que muda o que se constrói (guardar as opções entre sessões) vai como pergunta | ⏳ aprovação |
| VI. Paralelizar | O contrato ([contracts/](contracts/)) vem antes e congela (T018). Depois da US1, três frentes `[P]` (APPS, WINDOWS, POWER), cada uma com worktree e VM (`teste-a/b/c`, 2 núcleos e 4 GB). Os arquivos compartilhados (`Strings`, `Tokens`, `shell.qml`, catálogo, fixtures) ficam prontos no contrato; o `check-007` tem um bloco marcado por frente | ✅ |
| VII. Simplicidade | Reusa a moldura, o layout e a página de configurações (sem cópia). As abstrações novas têm segunda necessidade: `PopupFrame.tabs` (o text log da 008 vira aba); `ids` no catálogo (cinco opções e o `Bar contrast`). Um shader de poucas linhas. Sem framework de teste | ✅ |
| Restrições: marcas e licença | Os ícones de teste e os genéricos são desenhados pelo projeto; nenhum ícone de app de terceiros entra no repositório; textos em inglês no `Strings` | ✅ |
| Restrições: adaptador | Só o `Compositor` fala com o Hyprland (janelas, ações, `focus`); o resto é compositor-agnóstico (logind, `.desktop`) | ✅ |

**Re-check pós-design (Fase 1):** sem violações. Três notas:
- **Ajuste da spec:** a FR-023 ganhou a ordem por ação (decisão 7).
- **Spike antes do contrato:** os dispatchers `hl.dsp.window.*` por endereço e o `follow = false`
  não estão documentados com exemplo. A T003 confere na VM. Se o nome mudar, só muda o adaptador,
  e o contrato fica igual.
- **Sem locker na VM:** a prova do `Lock` é o sinal do logind no barramento; a tela de bloqueio é
  do U5.

## Project Structure

### Documentation (this feature)

```text
specs/007-menu-de-pausa/
├── spec.md
├── plan.md                        # este arquivo
├── research.md                    # Fase 0: R1–R15
├── data-model.md                  # Fase 1: abas, apps, janelas, energia, opções, estado, fixtures
├── quickstart.md                  # Fase 1: roteiro de validação (lab/check-007)
├── contracts/
│   ├── components.md              # componentes novos, acréscimos e a galeria
│   ├── services.md                # Apps, appsearch.js, Compositor, Session, SettingsModel, Settings
│   ├── ipc.md                     # alvo `pause`, alias `settings`, atalhos
│   └── pause-fixtures.schema.json # formatos dos arquivos de teste
├── checklists/requirements.md
└── tasks.md                       # /speckit-tasks
```

### Source Code (repository root)

```text
shell/
├── shell.qml                    # LazyLoader → PauseMenu (no lugar do SettingsPopup); IpcHandler `pause`; `settings` vira alias; um popup por vez
├── pause/                       # novo
│   ├── PauseMenu.qml            # PopupWindow com abas, as 4 páginas criadas com o menu (R1 revisto na T016), Tab/Shift+Tab, texto → APPS, dump
│   ├── AppsPage.qml             # PickerLayout + prévia (AppIcon) + opções do app + busca
│   ├── WindowsPage.qml          # PickerLayout + WorkspaceMap + ações da janela
│   └── PowerPage.qml            # GroupedList + DescriptionCard + StatusCard + ConfirmDialog
├── popup/
│   ├── PopupFrame.qml           # + tabs, tab, clock, tabClicked, bodyTop
│   └── PopupWindow.qml          # repassa os acréscimos
├── settings/
│   ├── SettingsPage.qml         # + startY, extraKeys
│   └── SettingsPopup.qml        # sai (a aba SYSTEM substitui)
├── ds/
│   ├── Tokens.qml               # + space.pause* (R12), confirmW, mapW/H, appIcon
│   ├── base/AppIcon.qml         # novo
│   └── composites/
│       ├── SearchHeader.qml     # novo
│       ├── WorkspaceMap.qml     # novo
│       ├── StatusCard.qml       # novo
│       ├── ConfirmDialog.qml    # novo
│       ├── GroupedList.qml      # + search, emptyText
│       └── PickerLayout.qml     # + startY, searchHeader/emptyText, opções action/toggle, triggered
├── services/
│   ├── Apps.qml                 # novo
│   ├── appsearch.js             # novo
│   ├── Session.qml              # novo
│   ├── Compositor.qml           # + windows, workspaceList, monitorList, focus/move/float/closeWindow
│   ├── SettingsModel.qml        # + choiceId, validação de ids
│   ├── Settings.qml             # + terminal
│   └── qmldir                   # + Apps, Session
├── shaders/duotone.frag         # novo
├── assets/icons/category-*.svg  # novo: 8 ícones genéricos, do projeto
├── strings/Strings.qml          # + grupo `pause`
├── config/defaults.json         # + terminal
├── gallery/Gallery.qml          # + página 4
└── fixtures/
    ├── settings-default.json    # + categoria `menu`
    ├── pause-default.json       # novo (+ pause-empty, pause-long, pause-broken, pause-live)
    └── pause/                   # novo: apps.json, apps-long.json, windows.json, windows-long.json, session.json, session-refuse.json, icons/*.svg

specs/003-settings-popup/contracts/settings.schema.json   # + `ids` opcional nas escolhas
docs/design-system.md                                      # + §9 Menu de pausa

rien-OS-private/lab/             # (privado, branch lab-007)
├── guest/hyprland.lua           # + ALT + Escape → pause toggle
├── check-003                    # adaptado: SYSTEM dentro do menu
└── check-007                    # novo: o quickstart, com um bloco por frente
```

**Structure Decision**: uma pasta nova `shell/pause/` pras páginas do menu (como `settings/` e
`wallpaper/`); os componentes genéricos vão pro design system; os serviços seguem a regra "a UI lê
só dos serviços". O `SettingsPopup` sai porque a aba SYSTEM o substitui (decisão 1). O laboratório
muda só no repositório privado.

## Dependências entre specs

- **001:** tokens, `TabBar`, `HeaderButton`, `PageHeader`, `Card`, `Rule`, `Square`, `Meter`,
  `Fixtures`, `Clock`, `Battery`, `Compositor`.
- **003:** moldura de popup, `CursorList`, `OptionRow`, `ValueStepper`, `DescriptionCard`,
  `KeyHints`, `SettingsPage`, `SettingsModel`, o IPC `settings`, `lab/check-003`.
- **004:** `PickerLayout`, `GroupedList`, `Card.mark`, `contentScale`, a infraestrutura de shaders
  (`build.sh` + o gancho do `lab/sync`), o padrão de arquivo de estado (`WallpaperStore`).
- **Em paralelo, agora:**
  - **004-acabamento (frente A):** a opção `Bar contrast` em SYSTEM › Appearance. Esta spec não
    mexe em `appearance` e se alinha ao mecanismo de persistência que ela adotar (T009);
  - **008 (U4):** o dono quer o text log também como aba do menu. A lista de abas é dado (R15), e a
    008 acrescenta a aba quando a 007 estiver na base dela.

## Ordem de execução (pro `/speckit-tasks`)

1. **Laboratório e spike (sequencial):**
   - branch `lab-007`;
   - `ALT + Escape`;
   - spike dos dispatchers e do logind;
   - esqueleto do `check-007`;
   - ícones de teste e genéricos.
2. **Contrato (sequencial, uma sessão):**
   - tokens e textos;
   - fixtures;
   - catálogo `menu` + `choiceId`;
   - interfaces de `Apps`, `Session` e `Compositor` (lógica de fixture);
   - acréscimos em `PopupFrame`, `PickerLayout`, `GroupedList` e `SettingsPage`;
   - `pause` IPC com o menu vazio;
   - `settings` como alias.

   Verificado na VM, **congela** (T018).
3. **US1 (sequencial, MVP):**
   - `PauseMenu` com as abas e o teclado;
   - SYSTEM dentro;
   - fechar e devolver o foco;
   - `check-003` adaptado.
4. **Paralelo `[P]`**, três frentes, cada uma com worktree e VM:
   - **A, APPS (US2 + US5 dos apps):** `appsearch.js`, `AppIcon` + duotone, `SearchHeader`,
     `Apps`, `AppsPage`, as opções `icons`/`app-order`/`running-app`, os `.desktop` reais e o
     estado;
   - **B, WINDOWS (US3 + US5 das janelas):** `WorkspaceMap`, as janelas reais e as ações no
     `Compositor`, `WindowsPage`;
   - **C, POWER (US4):** `StatusCard`, `ConfirmDialog`, `Session` real, `PowerPage`, as opções
     `confirm`/`confirm-start`, o reboot real.

   Com VMs ocupadas por outras rodadas, as frentes andam duas por vez (máximo de 4 VMs).
5. **Acabamento (sequencial):**
   - merge das frentes;
   - galeria (página 4);
   - `docs/design-system.md` §9;
   - `check-007` inteiro nos dois perfis;
   - imagem pro dono (SC-012);
   - relatório;
   - `/speckit-analyze`.

## Complexity Tracking

Sem violações da constituição a justificar.
