# Implementation Plan: Pod e text log (notificações e OSD)

**Branch**: `008-pod-text-log` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/008-pod-text-log/spec.md`, com as decisões do dono de
2026-10-27 (seção "Clarifications"). **Aguardando a aprovação do dono** (constituição V).

## Summary

O shell vira o servidor de notificações do desktop (o `NotificationServer` do Quickshell), e cada
notificação aparece como uma transmissão do Pod: uma faixa de tinta translúcida com retícula, quem
fala, o título e o texto sendo digitado. O que passou fica no text log, uma tela que serve tanto no
popup próprio (agora) quanto na aba do menu de pausa (spec 007, depois). Volume, microfone e brilho
mostram um OSD na mesma faixa. As alternativas de desenho viram opções da categoria
**Notifications** das configurações da 003, que valem de verdade e trocam ao vivo.

O que entra em `shell/`:
- **quatro serviços:**
  - `NotifyStore`: o servidor, o log, a pilha, a crítica;
  - `NotifyPrefs`: as opções e o não perturbe, guardados no estado do usuário;
  - `NotifyText`: funções puras de texto;
  - `Osd`: PipeWire e luz de fundo;
- **as peças da faixa no design system:** `Band`, `TypedText`, `ActionButton`, `Tag`, `Transmission`,
  `CriticalBand`, `OsdView`, `TransmissionStack`;
- **as superfícies em `shell/notify/`:** `NotifyLayer` (uma janela por monitor, só enquanto tem algo),
  `OsdWindow`, `LogPage` (o corpo reutilizável), `LogPreview` e `LogPopup` (a moldura da 003);
- **o contador da barra** (`LogCounter`);
- **acréscimos compatíveis:**
  - `PickerLayout` (`fluid`, opções de ação) e `GroupedList`/`ListItem` (`lead`, `tag`, `markColor`);
  - `SettingsModel` (opções vivas, campo `live`);
  - `Compositor` (`focusedFullscreen`, evento `focusedmon`);
- **o alvo IPC `notify`**, com o injetor de exemplos que manda pelo caminho real (`notify-send`/`gdbus`).

A verificação acontece no laboratório privado, dentro de `lab/perf`:
- `lab/provision-step notify` (libnotify, PipeWire com sink e source nulos, brightnessctl), sem tocar as
  camadas congeladas;
- `lab/notify-client` (gdbus: resposta, substituição, progresso, enxurrada, dono falso do nome);
- os atalhos provisórios `ALT + N` e `ALT + CTRL + N` e as teclas de volume;
- o roteiro `lab/check-008` em 1080 e hidpi (2560x1600 @1,25).

## Technical Context

**Language/Version**: QML (Qt 6) sobre Quickshell 0.3.x; Lua (config do Hyprland na VM); Bash (lab)

**Primary Dependencies**:
- módulos do Quickshell: `Quickshell`, `Quickshell.Wayland`, `Quickshell.Io` (`Process`, `FileView`,
  `IpcHandler`, `PersistentProperties`) e **dois novos nesta fase**:
  - `Quickshell.Services.Notifications` (o servidor);
  - `Quickshell.Services.Pipewire` (já usado pelo `Audio`);
- Qt: `QtQuick`, `QtQuick.Shapes` (arcos estáticos);
- os componentes da 001, 003 e 004.

**Nenhum pacote novo no sistema instalado além de `libnotify`** (o `notify-send`, que os scripts dos
usuários já esperam; entra na lista base na S3). Na VM de teste: `libnotify`, `pipewire`,
`wireplumber`, `brightnessctl`.

**Storage** (research R14):
- `shell/config/defaults.json` → bloco `notifications` (gerenciado);
- `$XDG_CONFIG_HOME/yorha-os/shell.json` → bloco `notifications` (do usuário, só lido);
- `$XDG_STATE_HOME/yorha-os/settings.json` (o `SettingsState` da 004, chaves `notifications.<chave>`) → as
  escolhas e o não perturbe (emenda da T013);
- `$XDG_STATE_HOME/yorha-os/text-log.json` → o log salvo, modo 600, só com `Text log: Saved`.

**Testing**: evidência na VM:
- `notify-send`, `lab/notify-client`, teclas e cliques reais (`lab/key`, `lab/click`);
- `qs ipc call notify dump`, `hud dump`, `settings dump`;
- screenshots, `lab/diffshot`, `lab/burst`;
- `wpctl`, `stat`, `busctl`;
- `qmllint` e o log de QML no relatório do `lab/perf`.

Sem framework de teste unitário (VII).

**Target Platform**: Arch + Hyprland 0.56+ (Lua). Só na VM até a U7. Perfis 1920x1080 @1 e
2560x1600 @1,25.

**Project Type**: desktop shell (UI de Wayland em QML)

**Performance Goals**: sem meta (U6). Medido aqui:
- o custo de uma enxurrada de 100 (SC-005);
- o CPU com uma transmissão digitando.

Regras: nada de blur; a retícula é um ladrilho estático, não shader; uma animação por transmissão; as
janelas só existem com conteúdo.

**Constraints**:
- **teclado:** nunca roubar (FR-015);
- **texto recebido:**
  - nunca vai pra shell;
  - nunca vira marcação além de `b`, `i` e `u` (FR-036);
- **screenshots:** iguais com fixtures (SC-002);
- **log de QML:** zero erros e zero avisos no roteiro normal (FR-037);
- **disco:** nada escrito com fixtures, nada no `~/.config` (FR-040, FR-043).

**Scale/Scope**:
- até 3 transmissões por monitor (opção: 1 ou 5), 1 faixa crítica, 1 OSD e um log de 100 entradas
  (opção: 50 ou 200);
- 7 histórias e 11 opções;
- 4 serviços novos, 8 peças de design system, 6 superfícies e 1 alvo de IPC;
- 6 acréscimos compatíveis.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Status |
|---|---|---|
| I. Sistema do dono intocável | **Onde roda:** UI, `qmllint`, `notify-send`, `gdbus`, PipeWire e testes rodam só nas VMs `teste-*`. **No host:** só as ferramentas do lab (QEMU, ssh, rsync, ImageMagick, o `lab/perf`). **Provisão:** os pacotes de teste entram na VM descartável (`lab/provision notify`), não nas camadas congeladas nem no host. **Atalhos:** vão na config da VM | ✅ |
| II. Camada sobre Arch limpo | O `libnotify` vai pra lista base do instalador na S3 (anotado); nada é instalado agora | ✅ |
| III. Padrões × arquivos do usuário | **Padrões:** ficam em `config/defaults.json`. **`shell.json`:** só lido. **Escolhas e log salvo:** vão pro estado (`$XDG_STATE_HOME`), nunca pra config. **Log salvo ilegível:** vai pra backup antes de ser trocado | ✅ |
| IV. Pronto com evidência da VM | Cada SC tem bloco no `lab/check-008` ([quickstart.md](quickstart.md)): dump, screenshot, `notify-send`/`gdbus`, `wpctl`, `stat`, log | ✅ |
| V. Spec antes de código | **Spec:** decisões do dono aplicadas. **Este plano:** espera a aprovação do dono. **Atalhos:** marcados como pendentes, como ele pediu | ⏳ aprovação |
| VI. Paralelizar | **Contratos:** [contracts/](contracts/) vêm antes e congelam (T020). **Frentes `[P]`:** quatro, cada uma com worktree e VM (`teste-a..d`), dentro do limite do lab (4 VMs, 2 núcleos e 4 GB cada): design system, servidor + opções, OSD, tela do log | ✅ |
| VII. Simplicidade | **Reuso:** a moldura, o layout e a lista vêm da 003/004, com acréscimos compatíveis. **Estrutura:** um serviço por assunto; sem daemon novo, sem shader novo, sem framework de teste. **Abstração nova:** o campo `live` no catálogo, justificado por duas necessidades concretas (Notifications e "Bar contrast") | ✅ |
| Restrições: marcas | Material desenhado do zero com medidas do §6; nenhum texto, som ou imagem do jogo; `Relay 01` é nome nosso | ✅ |
| Restrições: sem blur | A faixa é tinta translúcida chapada com retícula; o escurecimento do log é o da 003 | ✅ |
| Restrições: segredos | O log salvo é opt-in, modo 600, fora do repositório; nada do usuário em fixtures | ✅ |

**Re-check pós-design (Fase 1):** sem violações. Três notas:
- **A 003 dizia "nada é gravado" (FR-018 dela).** A categoria Notifications é a exceção, por decisão
  do dono (regra geral). As outras categorias continuam dados de teste. A FR-038 desta spec registra
  isso.
- **O aviso do Quickshell com outro servidor no barramento** é um `WARN` esperado só no caso de borda
  da FR-002. O `lab/check-008` filtra essa linha pelo texto, só no bloco `edge` (research R2).
- **Atalhos:** `ALT + N` e `ALT + CTRL + N` entram provisórios na VM, pra existir tecla real nos testes
  (SC-009). A escolha final é do dono.

## Project Structure

### Documentation (this feature)

```text
specs/008-pod-text-log/
├── spec.md
├── plan.md                       # este arquivo
├── research.md                   # Fase 0: R1–R19
├── data-model.md                 # Fase 1: Entry, Transmission, CriticalBand, Osd, NotifyPrefs, estado do log
├── quickstart.md                 # Fase 1: o lab/check-008
├── contracts/
│   ├── components.md             # peças da faixa, superfícies, acréscimos (PickerLayout, GroupedList, ListItem)
│   ├── services.md               # NotifyStore, NotifyPrefs, NotifyText, Osd + acréscimos
│   ├── ipc.md                    # alvo `notify`, acréscimos em `hud dump`/`settings dump`, atalhos (pendentes)
│   └── notifications.schema.json # fixture, arquivo de estado, log salvo
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
shell/
├── shell.qml                      # + Variants → LazyLoader → NotifyLayer; OsdWindow; LogPopup (abre/fecha como os outros); IpcHandler `notify`
├── notify/                        # novo
│   ├── NotifyLayer.qml            # PanelWindow por monitor: pilha + faixa crítica, mask, teclado só na resposta
│   ├── OsdWindow.qml              # PanelWindow do OSD, sem input
│   ├── LogPage.qml                # corpo do log (popup e aba da 007)
│   ├── LogPreview.qml             # o meio: a transmissão em foco + APP/RECEIVED/URGENCY/STATUS
│   └── LogPopup.qml               # PopupWindow (003) + LogPage
├── hud/
│   ├── Hud.qml                    # + LogCounter antes do relógio
│   └── LogCounter.qml             # novo
├── ds/
│   ├── Tokens.qml                 # + notify (material, medidas, tempos) e papéis tipográficos da faixa
│   ├── primitives/Band.qml        # novo
│   ├── base/
│   │   ├── TypedText.qml          # novo
│   │   ├── ActionButton.qml       # novo
│   │   ├── Tag.qml                # novo
│   │   └── ListItem.qml           # + lead, tag, markColor
│   └── composites/
│       ├── Transmission.qml       # novo
│       ├── CriticalBand.qml       # novo
│       ├── OsdView.qml            # novo
│       ├── TransmissionStack.qml  # novo
│       ├── GroupedList.qml        # + lead, tag, markColor nos itens
│       └── PickerLayout.qml       # + fluid, opções de ação
├── services/
│   ├── NotifyStore.qml            # novo
│   ├── NotifyPrefs.qml            # novo
│   ├── NotifyText.qml             # novo (funções puras)
│   ├── Osd.qml                    # novo
│   ├── Compositor.qml             # + focusedFullscreen, focusedmon
│   ├── SettingsModel.qml          # + "setting": "notify.<chave>" (o mecanismo da 004)
│   ├── Settings.qml               # + bloco notifications
│   └── qmldir                     # + os quatro
├── settings/SettingsPage.qml      # + Osd.suppress no foco de volume/mudo/brilho
├── strings/Strings.qml            # + grupo notify (rótulos, opções, descrições, exemplos do injetor)
├── gallery/Gallery.qml            # + página da 008
├── config/defaults.json           # + notifications
└── fixtures/
    ├── settings-default.json      # + categoria notifications (live)
    ├── notifications-default.json # novo: o mockup (log de 6, pilha de 3, crítica, OSD)
    ├── notifications-positions.json # novo: a mesma pilha pra as 3 posições (prefs)
    ├── notifications-long.json    # novo: texto longo, título longo, sem app, só título, 100 entradas
    ├── notifications-dnd.json     # novo: DND 5 + crítica
    └── notify/avatar.png          # novo: imagem de teste gerada (container), < 20 KB

YoRHa-OS-private/lab/               # (privado, branch lab-008)
├── provision/notify.sh            # pacotes de teste na VM descartável + sink/source nulos
├── notify-client                  # gdbus: reply, replace, progress, flood, hold-name
├── guest/hyprland.lua             # + ALT+N, ALT+CTRL+N (provisórios), teclas de volume → wpctl, noanim nas namespaces yorha-notify/yorha-osd
└── check-008                      # o quickstart (--only, --profile)
```

**Structure Decision**:
- **Pasta própria:** as superfícies de notificação vão em `shell/notify/`, como a `wallpaper/` da 004.
- **Design system:** as peças da faixa entram nele porque a galeria e outras fases vão usar, como os
  futuros OSDs da U5/U6.
- **Serviços separados por assunto:** servidor/log, opções, texto e OSD ficam em arquivos diferentes.
  Assim as frentes paralelas não mexem no mesmo arquivo.
- **A tela do log não tem janela própria** (`LogPage`), pra a 007 pôr a mesma tela numa aba sem cópia.

## Dependências entre specs

- **Base (já na branch):** 001 (tokens, `CursorList`, `Card`, `Meter`, `Fixtures`, `Compositor`), 003
  (moldura, `OptionRow`, `KeyHints`, `SettingsModel`), 004 (`PickerLayout`, `GroupedList`, barra com
  tom).
- **"Bar contrast" (004, em paralelo):** também é uma opção do catálogo que vale de verdade. O campo
  `live` (research R13) é proposto como o mecanismo comum. A T013 começa conferindo a branch da 004:
  se ela já tiver um mecanismo, a 008 adota o dela e atualiza `contracts/services.md` antes de seguir.
- **007 (menu de pausa, em planejamento em paralelo):**
  - **o que a 007 precisa da 008:** pôr a aba de log é trabalho da 007; a 008 entrega a `LogPage`
    pronta (`host: "pause"`) e a regra de abertura (`logOpen` + `markAllRead`);
  - **o que as duas compartilham:** os acréscimos no `PickerLayout` (`fluid`, opções de ação). Se a
    007 implementar antes, a 008 usa os dela.
- **Ordem de merge:** a 008 sai da 004 e mescla a 004 de novo antes da integração (T026), pra pegar a
  "Bar contrast". Com a 007, qualquer ordem: quem chegar depois adapta os pontos comuns acima. Os
  blocos da 008 no `shell.qml`, `Tokens.qml`, `Strings.qml`, `docs/design-system.md` e
  `settings-default.json` ficam marcados (`// --- spec 008 ---`), como na 004, pra facilitar o merge.

## Ordem de execução (pra o `/speckit-tasks`)

1. **Laboratório e spike (sequencial):**
   - a provisão de teste na VM, o `lab/notify-client`, os atalhos provisórios e as teclas de volume;
   - **spike do servidor na VM**, que confirma:
     - os nomes do `NotificationServer` (`inlineReplySupported`);
     - o `image://`, a substituição no lugar e o teclado `OnDemand` devolvendo o foco;
     - o 600 depois de uma escrita atômica.

     Se o servidor não funcionar, parar e levar ao dono;
   - o esqueleto do `lab/check-008`.
2. **Contrato (sequencial; fixtures primeiro):**
   - tokens e textos;
   - o `Band` (o material da faixa, que as frentes A, C e D usam);
   - fixtures (as quatro e a imagem de teste);
   - `defaults.json` e `Settings`;
   - `NotifyText` completo (é puro e pequeno);
   - as interfaces de `NotifyPrefs`, `NotifyStore` e `Osd` lendo só a fixture;
   - `SettingsModel` com o campo `live` e a categoria Notifications;
   - `Compositor`;
   - o IPC `notify` com respostas da fixture;
   - verificação e **congelamento**.
3. **Paralelo `[P]`** (4 VMs, 2 núcleos e 4 GB cada; uma frente por worktree):
   - **A, design system (`teste-a`):** `TypedText`, `ActionButton`, `Tag`, `Transmission`,
     `CriticalBand`, `TransmissionStack` e a página da galeria, tudo com fixtures;
   - **B, servidor e opções (`teste-b`):**
     - o `NotifyStore` real (servidor, log, pilha, agrupamento, enxurrada, DND, tela cheia, log salvo,
       recarga);
     - o `NotifyPrefs` com o estado;
     - provado por `notify-send` e `dump`, sem desenho;
   - **C, OSD (`teste-c`):** `OsdView` (sobre o `Band`, que entra no contrato), `Osd` (PipeWire, udev,
     supressão), `OsdWindow` e a supressão na `SettingsPage`;
   - **D, tela do log (`teste-d`):** acréscimos no `PickerLayout`/`GroupedList`/`ListItem`, `LogPage`,
     `LogPreview`, `LogPopup` e `LogCounter`, com fixtures; a prévia usa a `Transmission` da A
     quando ela chegar (até lá, um `Card` com o texto).
4. **Integração por história (sequencial, uma VM):**
   - US1: `NotifyLayer`, que junta A e B: o "pronto quando";
   - US2: faixa crítica;
   - US3: ações e resposta;
   - US4: log ligado ao store, atalho, contador;
   - US5: OSD nas posições;
   - US6: DND e tela cheia;
   - US7: as opções nas configurações, ao vivo.

   Cada uma é validada no `lab/check-008 --only …`.
5. **Acabamento:**
   - `docs/design-system.md` §9;
   - o `lab/check-008` inteiro em 1080 e hidpi;
   - a imagem de revisão pro dono;
   - o relatório;
   - o `/speckit-analyze`.

## Complexity Tracking

Sem violações da constituição a justificar.
