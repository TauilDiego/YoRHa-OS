# Implementation Plan: Base visual YoRHa e HUD

**Branch**: `001-yorha-base-hud` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-yorha-base-hud/spec.md` (aprovada em 2026-10-27)

## Summary

Construir em `shell/` (Quickshell/QML) o design system YoRHa e o HUD do topo, a partir dos tokens
do `docs/design-system.md`. As peças ficam em camadas: tokens → primitivas → base → compostos →
superfícies.

O HUD é um `PanelWindow` por monitor, com:
- abas de workspace vindas de um adaptador do Hyprland;
- telemetria (CPU, MEM, VOL, BAT);
- título da janela ativa;
- relógio.

Todos os dados passam por serviços que aceitam fixtures. A galeria abre por IPC. A escala
segue o modelo do Serpantinum: pixels lógicos, um fator `s` por superfície e um `uiScale` do
usuário.

A verificação acontece toda no laboratório privado, dentro de `lab/perf`. O laboratório ganha:
- o perfil 2560x1600 @1,25;
- o carregamento de fixtures na VM;
- a comparação de screenshots;
- suporte a várias VMs ao mesmo tempo, pros agentes paralelos.

## Technical Context

**Language/Version**: QML (Qt 6) sobre Quickshell 0.3.1; Lua (config do Hyprland na VM); Bash (lab)

**Primary Dependencies**: módulos do Quickshell: `Quickshell`, `Quickshell.Wayland`,
`Quickshell.Hyprland`, `Quickshell.Io` (`FileView`, `JsonAdapter`, `IpcHandler`, `Process`),
`Quickshell.Services.Pipewire`, `Quickshell.Services.UPower`; `QtQuick.Shapes`. A fonte M PLUS 1
(OFL) vai junto no repositório.

**Storage**: arquivos: `shell/config/defaults.json` (gerenciado),
`$XDG_CONFIG_HOME/rien-os/shell.json` (usuário) e fixtures JSON.

**Testing**: evidência na VM:
- screenshots (`lab/shot`, `lab/diffshot`);
- `qs ipc call hud dump`;
- `qmllint` dentro da VM;
- log de QML (relatório do `lab/perf`).

Não há framework de teste unitário no U1 (princípio VII).

**Target Platform**: Arch Linux + Hyprland 0.56+ (Lua). Só na VM do laboratório até a U7.

**Project Type**: desktop shell (UI de Wayland em QML)

**Performance Goals**: sem meta no U1 (a otimização é da U6). A regra é não usar blur, e o custo
de cada teste é medido no host pelo `lab/perf`.

**Constraints**:
- sem blur e sem transparência sobre o desktop (FR-008);
- pixels lógicos (FR-008b);
- dois screenshots com fixtures idênticos pixel a pixel (SC-002);
- zero erros e zero avisos de QML (FR-017).

**Scale/Scope**: 1 HUD por monitor, ~16 componentes de design system, 7 serviços, 1 galeria, 3
alvos de IPC.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Status |
|---|---|---|
| I. Sistema do dono intocável | A UI, o `qmllint` e os testes rodam só na VM. No host, só ferramentas do lab (QEMU, ssh, rsync, ImageMagick pra comparar imagens, o leitor `lab/perf`) | ✅ |
| II. Camada sobre Arch limpo | O U1 não instala nada no sistema. O `shell/` é carregado pelo `qs -p` | ✅ (n/a) |
| III. Padrões × arquivos do usuário | `config/defaults.json` é gerenciado; o `shell.json` do usuário só sobrescreve (R6) | ✅ |
| IV. Pronto com evidência da VM | Cada SC tem prova no [quickstart.md](quickstart.md): screenshot, `hud dump`, log | ✅ |
| V. Spec antes de código | Spec aprovada em 2026-10-27; este plano aguarda aprovação antes do `/speckit-tasks` | ✅ |
| VI. Paralelizar | Os contratos ([contracts/](contracts/)) vêm antes e ficam congelados. Depois, primitivas/base, serviços, HUD e galeria vão em paralelo, cada agente com worktree e VM próprios. Pré-requisito: lab com várias VMs (R10) | ✅ (com pré-requisito) |
| VII. Simplicidade | Sem framework de teste nem abstração extra; o único adaptador (`Compositor`) é exigido pelas restrições | ✅ |
| Restrições: marcas | Nada do jogo no repositório: a fonte é a M PLUS 1 (OFL), as cores vêm do Figma CC BY (creditado), as referências do jogo ficam só no privado | ✅ |

**Re-check pós-design (Fase 1):** sem violações. A tabela de complexidade fica vazia.

## Project Structure

### Documentation (this feature)

```text
specs/001-yorha-base-hud/
├── spec.md
├── plan.md              # este arquivo
├── research.md          # Fase 0: R1–R10
├── data-model.md        # Fase 1: entidades
├── quickstart.md        # Fase 1: roteiro de validação na VM
├── contracts/
│   ├── components.md    # interface dos componentes QML
│   ├── services.md      # interface dos serviços
│   ├── ipc.md           # comandos qs ipc
│   └── fixtures.schema.json
├── checklists/requirements.md
└── tasks.md             # gerado pelo /speckit-tasks (ainda não existe)
```

### Source Code (repository root)

```text
shell/
├── shell.qml                  # ShellRoot: Variants(screens) → Hud; LazyLoader → Gallery; IpcHandlers
├── ds/
│   ├── Tokens.qml             # singleton: cores, tipografia, sombras, espaços, motion, line()/px()
│   ├── primitives/            # Label, Square, Rule, GridBackground, Vignette
│   ├── base/                  # HeaderButton, ListItem, Selector, Meter, PageHeader, Card
│   └── composites/            # TabBar, CursorList
├── services/                  # singletons: Clock, Telemetry, Audio, Battery, Compositor, Settings, Fixtures
├── strings/Strings.qml        # textos fixos em inglês (FR-018)
├── hud/                       # Hud.qml (PanelWindow por monitor) + Telemetry/Clock/Title parts
├── gallery/Gallery.qml        # tela cheia, vinheta, todas as peças com nome
├── config/defaults.json       # uiScale 1, barHeight 40, vignette true
├── fixtures/                  # hud-default.json, battery-low.json, no-battery.json, muted.json, long-title.json, no-window.json
└── assets/fonts/              # MPLUS1[wght].ttf + OFL.txt

rien-OS-private/lab/           # (privado) mudanças do laboratório
├── up, profile                # NIER_LAB_PROFILE=hidpi (2560x1600) + lab/profile hidpi|1080
├── sync                       # --env KEY=VAL → ~/nier/ui.env
├── guest/nier-ui-run          # carrega ~/nier/ui.env antes do qs
├── diffshot                   # compare -metric AE
└── lib.sh, perf               # várias VMs ao mesmo tempo (NIER_LAB_VM → porta SSH e sessão perf próprias)
```

**Structure Decision**: um projeto só (`shell/`), organizado pelas camadas do design system. As
pastas espelham as camadas pra que a regra "cada camada só usa as de baixo" possa ser
conferida pelos imports. As mudanças do laboratório ficam no repositório privado.

## Ordem de execução (pra o `/speckit-tasks`)

1. **Laboratório (sequencial):**
   - fixtures na VM (`sync --env`, `nier-ui-run`);
   - `diffshot`;
   - perfil `hidpi`;
   - várias VMs ao mesmo tempo.
2. **Contrato (sequencial):**
   - `Tokens.qml`;
   - `Strings.qml`;
   - `Settings` e `Fixtures`;
   - esqueleto do `shell.qml` com os IPC;
   - fixtures JSON;
   - fonte.

   A partir daqui, as interfaces de [contracts/](contracts/) ficam congeladas.
3. **Paralelo `[P]`:**
   - **A:** primitivas + base;
   - **B:** serviços (Clock, Telemetry, Audio, Battery, Compositor);
   - **C:** compostos (depende de A, mas só pela interface).
4. **Superfícies:** HUD (H1, H2) e galeria (H3). Podem ir em paralelo entre si.
5. **Validação:** o [quickstart.md](quickstart.md) inteiro, dentro de `lab/perf`, e a entrega dos
   screenshots pra revisão do dono (SC-006).

## Complexity Tracking

Sem violações da constituição a justificar.
