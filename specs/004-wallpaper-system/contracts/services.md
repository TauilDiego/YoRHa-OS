# Contrato: serviços (`shell/services/`, singletons)

A UI lê o papel de parede **só** por estes serviços. As entidades estão em
[../data-model.md](../data-model.md).

## Novos

| Serviço | Expõe | Fonte real | Fixture |
|---|---|---|---|
| `WallpaperCatalog` | `items` (lista de `Wallpaper`), `byId(id)` → `Wallpaper` ou `null`, `folder` (caminho em uso), `folderMissing` (bool), `count` | `shell/wallpaper/scenes/*.json` + `FolderListModel` na `Settings.wallpaperFolder` (R6) | `wallpaper.folder` |
| `WallpaperStore` | `all`, `monitors`, `transition`, `paperFilterOff`, `resolve(monitorName)` → id, `set(id, monitorName)` (`""` ou `"all"` = todos), `step(monitorName, delta)` (próximo/anterior), `setTransition(kind)`, `setCamouflage(cell, trail, glitch)`, `setPaperFilter(path, on)`, `instant` (bool) | `$XDG_STATE_HOME/rien-os/wallpaper.json` (R8) + `Settings` | `wallpaper.all`, `wallpaper.monitors`, `wallpaper.transition` |

**Regras:**
- **`set` e `step` não desenham nada.** Eles mudam a escolha. Cada `Wallpaper` (um por monitor) observa
  `resolve(nome)` e dispara a própria transição.
- **`instant`** = `Fixtures.active || Settings.reduceMotion`.
- **Com a fixture `wallpaper` ativa,** o `WallpaperStore` não escreve o arquivo de estado.
- **Ordem do `step`:** a do catálogo, pulando os itens indisponíveis (o vídeo), e dando a volta
  nas pontas.
- **Ids inválidos:** `set` com um id que não está no catálogo devolve erro e não muda nada.

**Emenda da US6 (2026-10-27): o tom da barra**

| Serviço | Acréscimo | Notas |
|---|---|---|
| `WallpaperStore` | `toneMix` (`{ monitor: 0..1 }`), `setToneMix(monitor, v)`, `toneOf(id)` → `1` claro, `0` papel, `-1` ainda não se sabe | `toneMix` é escrito por cada `Wallpaper` (o tom que a barra mostra agora); `toneOf` aplica a FR-026 ao item: cena `dark` → 1, outras cenas → 0, imagem → luminância medida < 0,45 |
| `WallpaperCatalog` | `lumas` (`{ chave: 0..1 }`), `lumaOf(path, filtered)`, `setLuma(path, filtered, v)` | A luminância da faixa de cima de cada imagem, medida uma vez pela `WallpaperView` e guardada por caminho e por filtro ligado/desligado. Some quando o arquivo sai da pasta |

## Acréscimos

| Serviço | Acréscimo | Fonte |
|---|---|---|
| `Settings` | `reduceMotion`, `wallpaperFolder`, `wallpaperTransition`, `camouflage` | `defaults.json` + `shell.json` (data-model) |
| `Compositor` | `focusedMonitor` (nome da saída) | campo `focused` do `hyprctl monitors -j` que já é lido para as escalas; atualizado nos mesmos eventos |
| `Fixtures` | domínio `wallpaper` | data-model, "Fixture" |

**Regras:**
- **Só o `Compositor` fala com o Hyprland**, como na 001.
- **Uma leitura que falha nunca lança erro na UI:**
  - estado ilegível → começa vazio e registra no log;
  - pasta inexistente → `folderMissing: true`.
