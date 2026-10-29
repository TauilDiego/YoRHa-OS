# Implementation Plan: Sistema de papel de parede

**Branch**: `004-wallpaper-system` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-wallpaper-system/spec.md` (aprovada pelo dono em
2026-10-27, junto com a 003 e a ideia de fazer a US1 antes)

## Summary

O shell passa a ter um sistema próprio de papel de parede, sem ferramenta de fora. O fundo continua
sendo um `PanelWindow` por monitor na camada de fundo (como na 001), mas o que ele desenha vira um
**papel de parede escolhido**, de três tipos:
- **cena:** procedural, definida por um JSON de parâmetros;
- **imagem:** da pasta do usuário, com o filtro de papel opcional;
- **vídeo:** depois, no U6.

A escolha é por monitor, guardada como estado. A troca usa uma **transição** escolhida pelo usuário,
desenhada por um único shader de fragmento com quatro modos:
- **camuflagem**, de fábrica;
- **varredura;**
- **quadradinhos;**
- **crossfade.**

O shader recebe os dois fundos (o antigo e o novo) como texturas vivas. O **seletor** é um popup na
moldura da 003 (lista agrupada, prévia ao vivo, opções em duas colunas). Tudo também se controla
pelo IPC `wallpaper`.

A US1 (o fundo fiel ao jogo: sem grid, sem grão, vinheta medida, arcos duplos, feixes em segmentos,
respiração lenta) está **em implementação na branch `004-us1-fundo` (sessão principal)**. Este plano
transforma esse fundo na cena `menu`.

Toda a verificação fica no laboratório privado, dentro de `lab/perf`. O laboratório ganha:
- o `lab/check-004`;
- o atalho do seletor na VM;
- a compilação dos shaders dentro da VM;
- imagens de teste geradas num container.

## Technical Context

**Language/Version**: QML (Qt 6.11) sobre Quickshell 0.3.1; GLSL 440 (shaders, compilados pra
`.qsb`); Lua (config do Hyprland na VM); Bash (lab e o script de shaders).

**Primary Dependencies**:
- módulos do Quickshell: `Quickshell`, `Quickshell.Wayland` (`PanelWindow`, `WlrLayershell`) e
  `Quickshell.Io` (`FileView`, `IpcHandler`, `Process`);
- Qt: `QtQuick` (`ShaderEffect`, `ShaderEffectSource`, `Image`), `QtQuick.Effects` (`MultiEffect`, pro
  filtro de papel) e `Qt.labs.folderlistmodel` (a pasta de imagens);
- `qsb` (pacote `qt6-shadertools`), só onde a UI roda (a VM e, no futuro, o instalador);
- os componentes da 001 (Tokens, Rule, Vignette, PaperDecor, CursorList, Card, Selector) e os da 003
  (moldura de popup, linha de opção, seletor de valor, rodapé de teclas, foco em duas colunas).

**Storage**:
- `shell/config/defaults.json` (gerenciado: pasta, transição de fábrica, `reduceMotion`);
- `$XDG_CONFIG_HOME/yorha-os/shell.json` (do usuário, só lido);
- `$XDG_STATE_HOME/yorha-os/wallpaper.json` (estado: escolha por monitor, transição, filtros
  desligados);
- `shell/wallpaper/scenes/*.json` (as cenas de fábrica);
- `shell/fixtures/wallpapers/` (imagens de teste).

**Testing**: evidência na VM:
- screenshots (`lab/shot`, `lab/diffshot`);
- medição de cor e de padrão de grid no screenshot;
- `qs ipc call wallpaper dump`;
- teclas reais (`lab/key`, QMP);
- rajadas de `grim` pra sequência de quadros;
- `qmllint` dentro da VM;
- log de QML.

Tudo fica dentro de `lab/perf`, num roteiro `lab/check-004`. Sem testes unitários (princípio VII).

**Target Platform**: Arch Linux + Hyprland 0.56+ (Lua), só na VM até a U7. Perfis 1920x1080 @1 e
2560x1600 @1,25.

**Project Type**: desktop shell (UI de Wayland em QML)

**Performance Goals**: sem meta (U6). O custo da camuflagem fica registrado no `lab/perf` (SC-009). A
regra é: nada de blur; cena parada não repinta; o shader só existe durante a transição.

**Constraints**:
- dois screenshots iguais com fixtures (SC-002), o que pede semente fixa e transição instantânea;
- nenhum nome de arquivo passa por shell (FR-012);
- o sistema nunca escreve em `~/.config` (constituição III);
- zero erros e avisos de QML (FR-024);
- nada do jogo no repositório: as imagens de teste são geradas pelo projeto.

**Scale/Scope**:
- 4 cenas;
- uma pasta de imagens (testado com 4 arquivos, um quebrado e um com nome difícil);
- 1 shader com 4 modos;
- 1 seletor;
- ~8 componentes novos;
- 1 alvo de IPC estendido;
- 2 serviços novos.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Status |
|---|---|---|
| I. Sistema do dono intocável | A UI, o `qsb`, o `qmllint` e os testes rodam só na VM. As imagens de teste são geradas num container (`nier-lab`). No host, só as ferramentas do lab (QEMU, ssh, rsync, Docker, ImageMagick pra medir e comparar screenshots, o leitor `lab/perf`). A emenda que lista o ImageMagick e o Python do `lab/perf` está sendo feita na 001 (T039) | ✅ |
| II. Camada sobre Arch limpo | Nada instalado no sistema. O `qt6-shadertools` entra na VM (camada `hypr-base`/`dev`) e, depois, na lista de pacotes base do instalador (S3) | ✅ |
| III. Padrões × arquivos do usuário | Os padrões ficam em `config/defaults.json`; o `shell.json` do usuário só é lido; a escolha vai pra um **arquivo de estado** (`$XDG_STATE_HOME`), nunca pra config. A pasta de imagens do usuário só é lida (nem criada) | ✅ |
| IV. Pronto com evidência da VM | Cada SC tem prova no [quickstart.md](quickstart.md): screenshot com medição, `wallpaper dump`, rajada de quadros, log | ✅ |
| V. Spec antes de código | Spec e plano aprovados pelo dono em 2026-10-27. A US1 foi autorizada pelo dono a ir antes ("só a US1 da 004 primeiro") | ✅ |
| VI. Paralelizar | Os contratos ([contracts/](contracts/)) vêm antes e congelam. O catálogo de imagens (US4), o estado (US5) e o shader (US3) vão em paralelo, em arquivos separados. O seletor (US2) espera os componentes da 003 | ✅ |
| VII. Simplicidade | Um shader só pra as quatro transições; o filtro de papel usa o `MultiEffect` do Qt (sem shader próprio); sem ferramenta externa; sem testes unitários | ✅ |
| Restrições: marcas | As cenas são desenhadas do zero com medidas do jogo; nenhuma imagem do jogo; as de teste são geradas | ✅ |
| Restrições: sem blur | Nenhum blur. O escurecimento do seletor é uma camada de tinta translúcida (como na 003) | ✅ |

**Re-check pós-design (Fase 1):** sem violações. Duas notas:
- **Atalho na VM:** fica `ALT + W`, e não `SUPER + W` (research R11). É a convenção do `lab/guest/hyprland.lua`,
  pra não colidir com os atalhos do host no modo `--window`. `SUPER + W` fica pros padrões do instalador (S3).
  Não muda a intenção da spec.
- **Shaders:** os `.qsb` não entram no git (`.gitignore`). São compilados onde a UI roda (research R3).

## Project Structure

### Documentation (this feature)

```text
specs/004-wallpaper-system/
├── spec.md
├── plan.md              # este arquivo
├── research.md          # Fase 0: R1–R14
├── data-model.md        # Fase 1: entidades
├── quickstart.md        # Fase 1: roteiro de validação na VM (lab/check-004)
├── contracts/
│   ├── components.md    # componentes QML novos e os reaproveitados da 001/003
│   ├── services.md      # WallpaperCatalog, WallpaperStore e acréscimos em Settings/Compositor/Fixtures
│   ├── ipc.md           # alvo `wallpaper` estendido
│   ├── scene.schema.json  # formato de uma cena (shell/wallpaper/scenes/*.json)
│   └── state.schema.json  # formato do estado ($XDG_STATE_HOME/yorha-os/wallpaper.json)
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
shell/
├── shell.qml                    # Variants(screens) → Wallpaper; LazyLoader → WallpaperPicker; IpcHandler `wallpaper`
├── wallpaper/
│   ├── Wallpaper.qml            # PanelWindow de fundo por monitor: WallpaperTransition com o item atual
│   ├── Scene.qml                # cena procedural a partir de um JSON (papel, vinheta, arcos, feixes, réguas, trama escura)
│   ├── WallpaperView.qml        # um papel de parede: Scene ou imagem (+ PaperFilter)
│   ├── WallpaperTransition.qml  # dois slots + ShaderEffectSource + ShaderEffect (4 modos)
│   ├── WipeEdge.qml             # borda da varredura: Rule dotted girada 90°
│   ├── PaperFilter.qml          # MultiEffect (colorização pro papel) + Vignette
│   ├── WallpaperPicker.qml      # o seletor (popup da 003): lista agrupada + prévia + opções + teclas
│   ├── PreviewCard.qml          # Card com o nome, a WallpaperView pequena e a descrição
│   └── scenes/                  # menu.json, rules.json, dark.json, plain.json
├── shaders/
│   ├── transition.frag          # camuflagem / varredura / quadradinhos / crossfade
│   └── build.sh                 # qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 … (roda onde a UI roda)
├── services/
│   ├── WallpaperCatalog.qml     # cenas + imagens da pasta (FolderListModel), arquivos quebrados de fora
│   ├── WallpaperStore.qml       # escolha por monitor, transição, filtros; lê/escreve o estado; set/next/prev
│   ├── Settings.qml             # + reduceMotion, wallpaperFolder, wallpaperTransition, camouflage
│   ├── Compositor.qml           # + focusedMonitor (do mesmo hyprctl monitors -j)
│   └── Fixtures.qml             # + domínio `wallpaper`
├── ds/composites/
│   ├── GroupedList.qml          # lista de cursor com títulos de grupo (SCENES/IMAGES/VIDEO), aviso e itens apagados
│   └── PickerLayout.qml         # o composto lista + prévia + opções (FR-022), com o foco em duas colunas
├── strings/Strings.qml          # + textos do seletor e dos tipos
├── config/defaults.json         # + chaves novas
└── fixtures/
    ├── wallpaper-default.json   # domínio `wallpaper`: pasta de teste, escolha, transição
    └── wallpapers/              # ruins.jpg, dunes.png, "parede 'teste' #1 (larga).png", quebrada.jpg (gerados)

YoRHa-OS-private/lab/             # (privado)
├── guest/hyprland.lua           # ALT + W → ipc call wallpaper picker toggle
├── sync                         # depois do rsync, roda shell/shaders/build.sh na VM se algum .frag mudou
├── check-004                    # roteiro do quickstart (cores, grid, teclas, rajadas, estado)
└── burst                        # rajada de grim dentro da VM (N quadros a cada M ms), reaproveitável
```

**Structure Decision**: tudo fica no `shell/wallpaper/`, que já existe, mais dois serviços. O catálogo
(o que existe) e a escolha (o que está aplicado) ficam em serviços separados, pra US4 e US5 andarem em
paralelo sem mexer no mesmo arquivo. O shader fica em `shell/shaders/`, com o script que compila. Os
componentes de popup e de opção vêm da 003 e não são duplicados aqui.

## Dependências entre specs

- **001:** design system, `PaperDecor`, `Vignette`, `Rule`, `CursorList`, `Card`, `Selector` (com o
  blink), `Fixtures`, `Settings` e `Compositor`.
- **003:** a moldura de popup (escurecimento + papel), a linha de opção, o seletor de valor `◂ ▸`, o
  rodapé de teclas, o estado "sem foco" da `CursorList` e a navegação em duas colunas. **As tarefas do
  seletor (US2) dependem da implementação da 003.**

  As tarefas que não usam o seletor (cenas, transição por IPC, imagens, estado) **não dependem** dela e
  podem andar antes.
- **US1 da 004:** em implementação na branch `004-us1-fundo` (sessão principal). As tarefas dela estão
  no tasks.md com essa nota. Quando ela entrar na `004-wallpaper-system`, as T021–T022 ("extrair a
  cena") transformam o fundo dela na cena `menu`.

## Ordem de execução (pra o `/speckit-tasks`)

1. **Laboratório e spike (sequencial no começo):**
   - **compilar e rodar um shader trivial na VM via virgl:** é a pendência "shaders via virgl" do
     `lab/README.md`. Se falhar, as transições caem pro crossfade em QML puro e a camuflagem é
     replanejada;
   - script de shaders + gancho no `lab/sync`;
   - imagens de teste num container;
   - `ALT + W` na VM;
   - `lab/burst`;
   - esqueleto do `lab/check-004`.
2. **Contrato (sequencial):**
   - chaves do `Settings`;
   - textos;
   - domínio `wallpaper` nas fixtures;
   - `Compositor.focusedMonitor`;
   - as interfaces de `WallpaperCatalog` e `WallpaperStore`;
   - o IPC `wallpaper` com respostas vazias;
   - os 4 JSON de cena.

   A partir daqui, [contracts/](contracts/) congela.
3. **US1 (sessão principal, já em curso)** → extrair a cena `menu` (`Scene.qml`).
4. **Paralelo `[P]`:**
   - **A:** US3 (shader + `WallpaperTransition`), testado por IPC `set`;
   - **B:** US4 (imagens no catálogo, `PaperFilter`);
   - **C:** US5 (estado, `next`/`prev`, monitores).
5. **US2 (depois da 003):** `GroupedList`, prévia, `WallpaperPicker`, atalho.
6. **Polimento:**
   - galeria (cenas, filtro, quadros congelados de cada transição);
   - `docs/design-system.md`;
   - o roteiro inteiro do quickstart dentro de `lab/perf`;
   - screenshots pro dono (SC-010).

## Emenda: a barra sobre o fundo (US6, 2026-10-27)

Aprovada pelo dono em 2026-10-27, pelo plano e pelo mockup. Feita na branch `004-barra-tom` (sai da
`004-wallpaper-system` em `e39f26d`), em paralelo com o seletor (US2), que fica em outra branch. Nos
arquivos que os dois mexem (`Tokens.qml`, `docs/design-system.md`, `tasks.md`, `lab/check-004`), as
mudanças desta emenda ficam em blocos marcados, pra facilitar o merge.

**Como funciona:**
- **A barra** (`shell/hud/Hud.qml`): `color: "transparent"`; saem o `Rectangle` de papel e a
  `Vignette` da faixa. O papel de parede já cobre o monitor inteiro (ancorado nos 4 lados, com
  `ExclusionMode.Ignore`, na camada de fundo), então ele aparece embaixo. A barra lê o tom do monitor
  dela em `WallpaperStore.toneMix[monitor]`.
- **Paletas** (`shell/ds/Tokens.qml`): `Tokens.hudPaper` (os tokens de hoje) e `Tokens.hudLight` (a
  proposta aprovada), com os papéis `ink`, `ink2`, `rest`, `sel`, `selInk`, `track`, `fill`, `rule` e
  `alert`; `Tokens.toneMix(a, b, t)` mistura duas cores canal a canal (com alfa, como o mockup) e
  `Tokens.hudColor(papel, t)` dá a cor de um papel no tom `t`. Com `t = 0` as funções devolvem a cor
  de papel sem conta nenhuma, então nada que não é a barra muda.
- **Componentes:** `Label`, `Rule`, `HeaderButton`, `Meter` e `TabBar` ganham `property real tone: 0`
  e pintam com `Tokens.hudColor(…, tone)`. A barra passa o tom dela pra todos.
- **Tom por monitor** (`shell/services/WallpaperStore.qml`): `toneMix` (monitor → 0..1), escrito por
  cada `Wallpaper`; `toneOf(id)` dá o tom de destino de um item: cena `dark` → 1, outras cenas → 0,
  imagem → luminância < 0,45 ? 1 : 0, ou −1 enquanto a imagem não foi medida.
- **Luminância** (`shell/wallpaper/WallpaperView.qml`): quando a imagem fica pronta e ainda não foi
  medida, a vista se fotografa (`grabToImage` em 480 px de largura, com o filtro de papel, se ligado)
  e um `Canvas` invisível lê a faixa de cima com `getImageData` (o `putImageData` não pinta neste
  Quickshell, mas o `getImageData` lê; conferido na VM, `lab/perf` 2026-10-27T192747). O resultado
  fica no `WallpaperCatalog.lumas`, por caminho e por filtro ligado/desligado.
- **Cobertura da faixa** (`shell/wallpaper/WallpaperTransition.qml`): `topProgress` (0..1), em JS, com
  as mesmas contas do `transition.frag` (origem, `reveal`, célula e o mesmo hash pra camuflagem;
  posição da borda pra varredura; sorteio por quadradinho pra quadradinhos; progresso pra
  crossfade), só nas células que ficam embaixo da barra.
- **Mistura** (`shell/wallpaper/Wallpaper.qml`): parado, o tom é o do fundo na tela; numa transição,
  `de + (para − de) × smoothstep(topProgress)`, com `de` = o tom no instante em que ela começou (numa
  troca no meio de outra, o tom do quadro parado). Enquanto a imagem nova carrega, ou o tom dela não
  é conhecido, a barra segura o tom que tinha. Com `instant` não há transição: o tom troca na hora.
- **`hud dump`:** ganha `tone`, `toneMix` e `texts` (cada texto com a caixa e a cor, pros testes de
  contraste); o `wallpaper dump` ganha a `luma` medida por monitor.

**Constitution Check da emenda:** sem violações. A barra transparente revê a FR-008 da 001 ("sem
transparência sobre o desktop") só na barra, por decisão do dono; nada de blur (VII). Os testes
rodam na `teste-a`, dentro de `lab/perf` (I, IV). A spec foi emendada antes do código (V).

**Verificação:** `lab/check-004` ganha um bloco marcado (tom no `hud dump`, contraste medido nos
pixels, área vazia contra a cena sem a barra) e o `lab/check-u1` deixa de supor papel fixo na faixa
da barra. Rajadas da camuflagem Menu → Dark e da varredura. A imagem escura de teste (`night.jpg`)
entra no `lab/make-test-wallpapers`.

## Complexity Tracking

Sem violações da constituição a justificar.
