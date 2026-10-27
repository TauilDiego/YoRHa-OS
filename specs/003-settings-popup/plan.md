# Implementation Plan: Configurações num popup

**Branch**: `003-settings-popup` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-settings-popup/spec.md` (aprovada em 2026-10-27)

## Summary

Construir em `shell/` o popup de configurações do mockup aprovado: o resto do monitor escurece e um
painel de papel abre no centro, com categorias, opções e um quadro de descrição, navegável pelo
teclado e pelo mouse, tudo com dados de teste.

O que entra:
- **uma janela só por abertura:** um `PanelWindow` `Overlay` transparente na tela inteira do monitor
  em foco, com o escurecimento, o painel e o clique fora (research R1);
- **a moldura reutilizável:** `PopupWindow` (escurecimento + painel + fade + fechamento em duas
  fases). A spec 004 usa ela no seletor de papel de parede;
- **um serviço novo:** `SettingsModel` lê o catálogo de `shell/fixtures/settings-default.json` e
  guarda os valores em memória;
- **componentes novos no design system:**
  - `ValueStepper`, `KeyHints`, `OptionRow`, `OptionList` e `DescriptionCard`;
  - acréscimos no `Meter` (editável, invertido) e na `CursorList` (sem foco, dar a volta);
- **o alvo IPC `settings`:** `open`, `close`, `toggle`, `isOpen`, `dump`, `reset`.

A verificação acontece toda no laboratório privado, dentro de `lab/perf`. O laboratório ganha o
atalho `ALT + I`, os ajudantes `lab/click` e `lab/burst` e o roteiro `lab/check-003`.

## Technical Context

**Language/Version**: QML (Qt 6) sobre Quickshell 0.3.1; Lua (config do Hyprland na VM); Bash (lab)

**Primary Dependencies**: os mesmos módulos da 001 (`Quickshell`, `Quickshell.Wayland`,
`Quickshell.Io`), mais `QtQuick` (`Flickable` pra rolagem). Nenhuma dependência nova.

**Storage**: `shell/fixtures/settings-default.json` (catálogo, só leitura). Os valores vivem em
memória (FR-018). Nada é gravado.

**Testing**: evidência na VM:
- screenshots (`lab/shot`, `lab/diffshot`, `lab/burst`);
- `qs ipc call settings dump`;
- teclas e cliques reais via QMP (`lab/key`, `lab/click`);
- `qmllint` dentro da VM;
- o log de QML no relatório do `lab/perf`.

Sem framework de teste unitário (princípio VII).

**Target Platform**: Arch Linux + Hyprland 0.56+ (Lua). Só na VM do laboratório até a U7.

**Project Type**: desktop shell (UI de Wayland em QML)

**Performance Goals**: sem meta (U6). Sem desfoque no escurecimento (FR-003, constituição VII).
O custo do popup aberto entra no relatório do `lab/perf`.

**Constraints**:
- sem blur (FR-003);
- dois screenshots com fixtures idênticos (SC-002);
- zero erros e zero avisos de QML (FR-023);
- nada mexe no sistema (FR-018).

**Scale/Scope**: 1 popup por vez, 7 categorias, 36 opções, 5 componentes novos e 2 estendidos, 1
serviço novo, 1 alvo de IPC.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Status |
|---|---|---|
| I. Sistema do dono intocável | A UI, o `qmllint` e os testes rodam só na VM. No host, só ferramentas do lab. O atalho entra na config da VM, não na do dono | ✅ |
| II. Camada sobre Arch limpo | Não instala nada | ✅ (n/a) |
| III. Padrões × arquivos do usuário | O catálogo é do projeto; nada é gravado no `~/.config` | ✅ |
| IV. Pronto com evidência da VM | Cada SC tem prova no [quickstart.md](quickstart.md): screenshot, `settings dump`, teclas via QMP, quadros, log | ✅ |
| V. Spec antes de código | Spec aprovada em 2026-10-27; **este plano aguarda a aprovação do dono** antes da implementação | ⏳ |
| VI. Paralelizar | O contrato ([contracts/](contracts/)) vem antes e congela. Depois, três frentes `[P]`, cada uma com worktree e VM (`teste-a/b/c`): componentes, moldura, serviço | ✅ |
| VII. Simplicidade | Sem framework de teste. Uma abstração nova (`PopupWindow`), justificada pela segunda necessidade já aprovada (o seletor da 004) | ✅ |
| Restrições: marcas | Nada do jogo; textos em inglês no `Strings`; o catálogo é de exemplo | ✅ |

**Re-check pós-design (Fase 1):** sem violações.

**Nota sobre a spec:** a FR-001 dizia `SUPER + I` "na VM". O laboratório usa ALT nos atalhos pra
não colidir com o host no modo `--window` (research R4). A FR-001 foi ajustada pra registrar as
duas teclas.

## Project Structure

### Documentation (this feature)

```text
specs/003-settings-popup/
├── spec.md
├── plan.md                  # este arquivo
├── research.md              # Fase 0: R1–R13
├── data-model.md            # Fase 1: categorias, opções, estado do popup
├── quickstart.md            # Fase 1: roteiro de validação na VM
├── contracts/
│   ├── components.md        # interface dos componentes e o layout do painel
│   ├── services.md          # SettingsModel + acréscimo no Compositor
│   ├── ipc.md               # alvo `settings` e o atalho
│   └── settings.schema.json # formato do catálogo
├── checklists/requirements.md
└── tasks.md                 # /speckit-tasks
```

### Source Code (repository root)

```text
shell/
├── shell.qml                    # + LazyLoader → SettingsPopup; IpcHandler "settings"
├── ds/
│   ├── Tokens.qml               # + color.dim, space.popup*/settings*, motion.popupFade/actionBusy
│   ├── base/
│   │   ├── ValueStepper.qml     # novo: ◂ valor ▸
│   │   ├── KeyHints.qml         # novo: rodapé de teclas
│   │   └── Meter.qml            # + editable, inverted, picked()
│   └── composites/
│       ├── CursorList.qml       # + focused, wrap, keysEnabled
│       ├── OptionRow.qml        # novo: ListItem plain + valor por tipo
│       ├── OptionList.qml       # novo: coluna de opções com rolagem
│       └── DescriptionCard.qml  # novo: Card com descrição, aviso, DEFAULT/NOW
├── popup/
│   └── PopupWindow.qml          # novo: escurecimento + painel + fade (reutilizável, spec 004)
├── settings/
│   ├── SettingsPopup.qml        # novo: PopupWindow + SettingsPage
│   └── SettingsPage.qml         # novo: as três colunas e o foco de duas colunas
├── services/
│   ├── SettingsModel.qml        # novo: catálogo + valores em memória
│   ├── Compositor.qml           # + focusedMonitor
│   └── qmldir                   # + SettingsModel
├── strings/Strings.qml          # + grupo `settings`
├── gallery/Gallery.qml          # + os componentes novos
└── fixtures/
    ├── settings-default.json    # novo: o catálogo do mockup
    ├── settings-broken.json     # novo: caso de borda (catálogo ausente)
    └── settings-long.json       # novo: caso de borda (14 opções, textos longos)

rien-OS-private/lab/             # (privado)
├── guest/hyprland.lua           # + ALT + I → settings toggle
├── click                        # novo: clique via QMP (extraído do check-u1)
├── burst                        # novo: n quadros de uma região, com grim na VM
└── check-003                    # novo: o quickstart automatizado
```

**Structure Decision**: o mesmo projeto (`shell/`), seguindo as camadas da 001. Os componentes
genéricos vão pro design system; a moldura de popup ganha uma pasta própria (`popup/`) porque é uma
superfície reutilizável, não uma peça de layout. As mudanças do laboratório ficam no repositório
privado.

## Ordem de execução (pro `/speckit-tasks`)

1. **Laboratório (sequencial):** atalho na VM, `lab/click`, `lab/burst`, esqueleto do `lab/check-003`.
2. **Contrato (sequencial):**
   - tokens e textos;
   - catálogo e fixtures de borda;
   - `SettingsModel` com a interface completa (lógica mínima);
   - `Compositor.focusedMonitor`;
   - o IPC `settings` no `shell.qml` com uma janela vazia.

   A partir daqui, as interfaces de [contracts/](contracts/) ficam congeladas.
3. **Paralelo `[P]`**, cada frente com worktree e VM:
   - **A, design system:** `ValueStepper`, `KeyHints`, `Meter`, `CursorList`, `DescriptionCard`,
     depois `OptionRow` e `OptionList`;
   - **B, moldura:** `PopupWindow` (escurecimento, painel, fade, clique fora, duas fases);
   - **C, serviço:** a lógica do `SettingsModel` (tipos, dependências, ações, `reset`, `dump`).
4. **Histórias:**
   - US1: `SettingsPopup` abrindo e fechando;
   - US2: `SettingsPage` com navegação;
   - US3: valores.

   Cada uma é validada no lab.
5. **Acabamento:**
   - galeria e design system;
   - o `lab/check-003` inteiro em 1080 e hidpi, dentro de `lab/perf`;
   - os screenshots pra aprovação do dono (SC-009);
   - o `/speckit-analyze`.

## Complexity Tracking

Sem violações da constituição a justificar.
