# Implementation Plan: Menus do jogo (efeitos medidos e tela cheia)

**Branch**: `013-menus-do-jogo` | **Date**: 2026-10-31 | **Spec**: [spec.md](spec.md) | **Status**: aprovado pelo dono em 31.10 ("sim aprovo")

**Input**: a spec aprovada em 31.10. As análises A–D ficam em `~/Videos/nier-ref/menus/analise/`, fora
do repo. O protótipo é o artefato "YoRHa-OS Protótipo: menus do jogo", com o fonte privado em
`lab/mockups/menus-jogo/`. As escolhas do dono estão em `escolhas-2026-10-31.md` do mesmo lugar.

## Summary

Os menus do shell ganham o movimento medido no jogo:
- seleção, pulso, título digitando, cascata, troca de aba, rodapé e troca de nível;
- abrir e fechar em triângulos, o diálogo do jogo e o fundo parado;
- o texto que não cabe rolando.

O ponteiro continua o da 007, por escolha do dono. Fora o movimento, a spec traz:
- a tela cheia como opção de apresentação;
- a janelinha de escolhas, com seleção de várias opções;
- os sons da interface, do boot e do login;
- o text log como aba LOG do menu.

Quase tudo é adaptação de peças que já existem no design system:
- a `ListItem` já desenha o texto em duas cópias, recortadas pela faixa de tinta;
- a 008 trouxe a `TypedText` e o modo fluido do `PickerLayout`.

As peças novas são poucas:
- um rótulo que rola (`ScrollingLabel`);
- o efeito dos triângulos (um `ShaderEffect`);
- a janelinha (`ChoicePopup`);
- o serviço de sons (`Sounds`);
- o som de boot no módulo da 011.

## Technical Context

**Language/Version**: QML (Qt 6, Quickshell 0.3.x), GLSL compilado em `.qsb` (`qt6-shadertools`, só no
lab), Python 3 (lab: síntese dos sons), shell e systemd (som de boot, no módulo da 011), QML do tema
SDDM (Qt 6).

**Primary Dependencies**:
- `qt6-multimedia` e `qt6-multimedia-ffmpeg` (`SoundEffect`, S1);
- `alsa-utils`, pro som de boot (S4);
- `pipewire-audio`, pro fallback com `pw-play` (S1).

Nenhuma dependência nova de runtime pros efeitos visuais.

**Storage**:
- `SettingsState`, como o `shell.barContrast`, pras opções novas (data-model.md);
- `~/.local/state/yorha-os/sound.json`, o estado de som lido no boot.

**Testing**: no lab, dentro do `lab/perf`, com quatro ferramentas novas:
- `lab/check-013` (blocos do quickstart);
- `lab/burst`, pros tempos;
- uma placa de som emulada com a saída gravada no host (`lab/up --audio-capture`, research S6);
- `lab/key` pras teclas rápidas.

Regressão: os roteiros da 003, 004, 007, 008 e 011.

**Target Platform**: Arch + Hyprland 0.56 (configuração em Lua), nas VMs `teste-b` (hypr-base com o
passo `notify`) e `teste-011` (boot-iso, pra US7). Perfis 1080 e hidpi.

**Project Type**: shell de desktop (QML) + módulo de sistema (boot/login).

**Performance Goals**:
- SC-002: 30 quadros/s ou mais em 95% dos quadros das transições;
- som em até 50 ms;
- boot ≤ +0,1 s com os sons (SC-013).

**Constraints**:
- nenhum material do jogo no repo;
- o modo janela parado igual ao de hoje (FR-017);
- `Tokens.instant` (Reduce motion) leva tudo direto ao estado final.

**Scale/Scope**: ~15 arquivos QML mudados, ~7 novos, mais o módulo da 011, o tema SDDM e ferramentas
do lab.

## Constitution Check

| Princípio | Como o plano cumpre |
|---|---|
| I. O sistema do dono é intocável | Tudo roda nas VMs. Os sons são gerados num container do lab. O som de boot só é testado na `teste-011` |
| II. Camada sobre um Arch limpo | Dependências novas declaradas (`qt6-multimedia`, `alsa-utils`). Nada de imagem |
| III. Padrões gerenciados | As opções novas ficam no `SettingsState`. O som de boot entra pelo módulo, com backup e desfazer, como na 011 |
| IV. Evidência da VM | Cada SC tem o seu bloco no `check-013` (quickstart.md), com rajadas, gravações e medições |
| V. Spec antes de código | Spec aprovada. Plano e tarefas vão pro dono antes do código |
| VI. Paralelizar | Quatro frentes `[P]` depois da fundação, cada uma com worktree e VM própria (até 4 VMs a 4/4) |
| VII. Simplicidade | Adaptar as peças que existem. Um só caminho de movimento (sem alternativa), mais o Reduce motion |

Nenhuma violação.

## Design

### 1. Movimento (US1–US3)

Os números ficam em `Tokens.motion` (research R1). Cada efeito mora numa peça:

| Efeito | Peça | Mudança |
|---|---|---|
| Seleção (FR-001) | `ds/base/ListItem.qml` | A varredura passa de 150 ms OutCubic pra 400 ms OutQuart. Ela ganha o recolher (200 ms, InOutQuad) da linha que perde a seleção. As duas cópias do texto já existem |
| Pulso (FR-002) | `ListItem`, `ds/composites/TabBar.qml` | Uma camada clara sobre a faixa de tinta, com a opacidade em trapézio de 1,333 s, só quando a linha é a "viva" (coluna com foco). A aba aberta usa a mesma camada |
| Ponteiro (FR-003) | `ds/base/Selector.qml` | Sem mudança (fica o da 007) |
| Título (FR-004) | `ds/base/PageHeader.qml` + `TypedText` (008) | Fade de 100 ms, 200 ms vazio, digitação a 20 letras/s com a letra da ponta sorteada da própria palavra |
| Cascata (FR-005) | `CursorList`, `GroupedList`, `OptionList` | `enter()` com atraso por índice (33 ms): recorte da esquerda e o rótulo digitando (28/s, o selecionado a 20/s) |
| Troca de aba (FR-006) | `popup/PopupFrame.qml` | Corpo some (133 ms), 67 ms vazio, `enter()` da página. Uma troca nova cancela a anterior |
| Rodapé (FR-007) | `ds/base/KeyHints.qml` + o rótulo da esquerda | Ao mudar o modelo: opacidade em 130 ms e desfoque (`MultiEffect`), x de −20 → 0 em 300 ms |
| Nível (FR-008) | `OptionList`, `ListItem` | Entrada escalonada (34 ms, 10 px, 170 ms). `leave()`: a faixa estica ×2,1 e apaga em 120 ms |
| Abrir/fechar (FR-009) | `popup/TriangleReveal.qml` (novo) + `PopupWindow`/`PopupFrame` | `ShaderEffect` sobre a camada do painel só durante a animação (research R2). Depois, a montagem em ordem. Fechar inverte em 230 ms antes de soltar a janela |
| Diálogo (FR-010) | `ds/composites/ConfirmDialog.qml` | Escurece pra ×0,8 em 170 ms. A faixa do título no 1º quadro, o corpo com fade e desfoque em ~100 ms. Fecha com desfoque |
| Fundo (FR-011) | `wallpaper/Scene.qml`, `PopupFrame` | A `phase` do `PaperDecor` congela com um menu aberto. Na tela cheia, o papel do painel é estático |
| Texto que rola (FR-012) | `ds/primitives/ScrollingLabel.qml` (novo) | Um `Label` num `Item` com recorte. Se não couber: pausa, rola a 60 px/s, pausa, volta. Com `Tokens.instant`, corta com "…". Usado por `ListItem`, `ValueStepper`, `Card`/cabeçalho de cartão e linhas de info |

### 2. Apresentação (US4)

- **Modo:** `PopupFrame` ganha `presentation: "floating" | "fullscreen"`.
- **Escala:** `s` continua calculado pelo painel de 84% nos dois modos. Assim as letras ficam do mesmo
  tamanho e o modo janela não muda (FR-017, research R4).
- **Tela cheia:** o painel ocupa a janela, sem tinta, sem sombra, e com o `PaperDecor` estático por
  baixo.
- **`PickerLayout`:** o `fluid` da 008 se divide em `stretch` (colunas esticam) e `bodyOnly` (sem
  título e rodapé próprios), conforme a frente D §5. APPS, WINDOWS, o seletor e o log usam `stretch`
  na tela cheia.
- **SYSTEM:** centralizado num quadro de 1612 de largura. As colunas têm um limite de largura em
  ultrawide.
- **Opção:** `shell.menuPresentation` no `SettingsState`. A troca ao vivo anima a geometria do painel
  em `popupFade`, e é instantânea com `Tokens.instant`.
- **Camadas:** os toasts críticos e o OSD sobre o menu cheio. É uma ordem de camadas Overlay a
  conferir (research R5).

### 3. Janelinha de escolhas (US6)

- **Peça:** `ds/composites/ChoicePopup.qml` (nova), presa à direita da linha.
- **Visual:**
  - escurecimento ×0,8 sobre o menu;
  - lista com `ListItem` e `ScrollingLabel`;
  - `Selector` espelhado, do lado direito;
  - sobe perto da borda e rola em linhas inteiras.
- **Modo múltiplo:** quadradinhos marcáveis, com pelo menos um marcado.
- **`OptionRow`:** Enter numa escolha com mais de 3 valores abre a janelinha. ←→ continuam mudando
  direto.
- **Keyboard › Layouts:** opção nova de lista, com a troca de layout por atalho, aplicada no Hyprland
  (research R6).

### 4. Sons (US5)

- **Serviço:** `services/Sounds.qml` (novo), uma singleton que toca os eventos de contracts/sounds.md.
  - **Tecnologia e latência:** research S1.
  - **Pasta própria:** um arquivo `<evento>.wav|.ogg` substitui o nosso.
  - **Volume:** o de interface, por cima do volume do sistema; o mudo do sistema vale.
  - **Digitação:** desligada por padrão.
  - **Notificações:** respeitam o "não perturbe" e a tela cheia segurada da 008.
- **Sons nossos:** em `system/sounds/`, gerados por `lab/013/sounds-gen`, num container, com as
  receitas da frente C. São versionados e creditados como nossos.
- **Som de entrada:** uma vez por login (marca em `$XDG_RUNTIME_DIR`).
- **Estado salvo:** o serviço grava `~/.local/state/yorha-os/sound.json` (volume, mudo, opção de boot)
  quando muda.

### 5. Boot e login (US7)

- **Módulo da 011:** um serviço de sistema `yorha-boot-sound` toca o som de início quando a placa fica
  pronta (research S4). Ele lê o estado salvo do último usuário (`/var/lib/sddm/state.conf`), usa
  `alsa-utils` e nunca entra no caminho do login.
- **Desinstalar:** o `install`/`uninstall` do módulo cuidam disso, e o `check-011 undo` ganha esse
  caso.
- **Tema de login:** toca os sons dos eventos (research S3), com a chave `sounds=on|off` no `config`.
- **Lab:** a VM ganha uma placa de som emulada, com a saída num WAV no host (S6). O `boot-timing` mede
  o custo.

### 6. Aba LOG (US8)

- **Abas do `PauseMenu`:** apps, windows, log, system, power.
- **Log:** a `LogPage` usa o host `"pause"`, que ela já prevê (`LogPage.qml:30`), e o `LogPopup` sai.
- **Entradas:** SUPER+N, o contador da barra e o IPC `notify open` abrem o menu na aba LOG.
- **Lido:** marcar como lido ao fechar, como na 008.

## Project Structure

### Documentation (this feature)

```text
specs/013-menus-do-jogo/
├── spec.md
├── plan.md              # este arquivo
├── research.md          # R1–R8 (visual) e S1–S6 (som)
├── data-model.md        # opções, estados, eventos de som
├── quickstart.md        # roteiro do check-013
├── contracts/
│   ├── ipc.md           # o que muda no IPC e no dump
│   ├── sounds.md        # eventos, nomes de arquivo, regras
│   └── boot-sound.md    # unidade, script, estado, config, desinstalar
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
shell/
├── ds/Tokens.qml                       # motion: os números do jogo
├── ds/primitives/ScrollingLabel.qml    # novo
├── ds/base/{ListItem,PageHeader,KeyHints,ValueStepper,TypedText}.qml
├── ds/composites/{TabBar,CursorList,GroupedList,OptionList,OptionRow,ConfirmDialog,PickerLayout}.qml
├── ds/composites/ChoicePopup.qml       # novo
├── popup/{PopupFrame,PopupWindow}.qml
├── popup/TriangleReveal.qml            # novo, com shaders/triangles.frag(.qsb)
├── pause/PauseMenu.qml                 # aba LOG
├── notify/{LogPage,LogPopup}.qml       # LogPopup sai
├── services/{Settings,SettingsState,Sounds}.qml   # Sounds novo
├── settings/SettingsPage.qml           # Appearance › Menu presentation; Sound; Keyboard › Layouts
├── wallpaper/Scene.qml                 # fase congelada com menu aberto
└── shell.qml                           # SUPER+N → pause log; som de entrada
system/
├── sounds/*.wav                        # novos, nossos
├── boot-login/                         # yorha-boot-sound (unidade + script), install/uninstall
└── login/sddm/yorha-os/                # sons do tema e a chave sounds
docs/sons-do-jogo.md                    # como usar os sons da própria cópia (links, sem arquivos)
```

**Lab (privado, branch `lab-013`):**
- `lab/check-013`;
- `lab/013/sounds-gen`;
- `lab/013/audio-rec` (gravação do sink nulo na sessão);
- `lab/up --audio-capture`;
- as extensões do `check-011 undo`.

## Fases e paralelismo

1. **F0, preparação** (eu):
   - a 008 na `main` e a `013-menus-do-jogo` atualizada;
   - a `lab-013` a partir da `main` privada;
   - `--audio-capture`, o esqueleto do `check-013`, `sounds-gen` e a medição de quadros/s (um
     contador de debug no shell, lido pelo `dump`).
2. **F1, fundação** (eu):
   - `Tokens.motion`;
   - `ScrollingLabel`;
   - a letra da ponta na `TypedText`;
   - as chaves novas no `Settings`;
   - `presentation` e `s` no `PopupFrame`;
   - o `stretch`/`bodyOnly` no `PickerLayout`.
3. **F2, frentes `[P]`**, cada uma com worktree e VM:
   - **A, movimento:** US1–US3 e o diálogo; `ListItem`, listas, `PopupFrame` (troca de aba e montagem),
     `KeyHints`, `ConfirmDialog`, `TriangleReveal`.
   - **B, apresentação e aba LOG:** US4 e US8; as páginas no modo cheio, `PauseMenu`, `LogPage`,
     `shell.qml`.
   - **C, janelinha:** US6; `ChoicePopup`, `OptionRow`, Keyboard › Layouts.
   - **D, sons:** US5 e US7; `Sounds`, os arquivos, as notificações, o módulo de boot, o tema de login.

   A e B tocam o `PopupFrame`: a fundação deixa as interfaces prontas, A cuida da animação e B da
   geometria.
4. **F3, junção** (eu):
   - o `check-013` inteiro nos dois perfis e nos dois modos;
   - os roteiros da 003, 004, 007, 008 e 011;
   - a medição de quadros/s;
   - a sessão do dono na janela da VM;
   - o relatório e a página de revisão.

## Riscos

- **O shader na VM `--soft`** roda no llvmpipe. A medição de SC-002 é com 3D (`lab/up` padrão); no
  `--soft`, só a correção.
- **Ordem das camadas Overlay** (toast sobre o menu cheio): o Hyprland não garante. Se falhar, a camada
  das notificações sobe pra frente ao abrir o menu (R5).
- **Som no login:** depende do greeter ter um servidor de áudio (S3). O fallback é sem som no login,
  com o boot e a sessão mantidos.
- **Som de boot e o PipeWire:** o `aplay` precisa terminar antes do PipeWire abrir a placa (S4).
- **Keyboard › Layouts** com a configuração em Lua do 0.56: aplicar sem reiniciar (R6).
- **Latência do `SoundEffect`** contra os 50 ms: medir na F0, com o `pw-play` como fallback (S1).
- **Primeiro boot mudo:** o mixer da placa começa mudo num sistema novo até o estado ser salvo (S4).
- **Os nossos sons nunca foram ouvidos:** o dono aprova de ouvido (SC-011) antes da junção.
- **Regressão visual:** o `diffshot` contra as evidências do modo janela parado, com a lista de
  diferenças esperadas (FR-017).

## Complexity Tracking

Nenhuma violação da constituição pra justificar.
