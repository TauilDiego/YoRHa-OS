# Contrato: provedor do sistema

Fixado na etapa 0 e estável durante o paralelo (FR-011). Mudar qualquer coisa aqui depois do congelamento (T021) é parar
as frentes e avisar quem coordena.

## Interface

Cada provedor é um singleton em `shell/services/`, registrado no `qmldir` e no `SysProviders.byName`.

| Membro | Obrigatório | O que faz |
|---|---|---|
| `levelsOf(key): list` | sim | Ids estáveis dos valores, nunca índices (FR-003). `[]` em slider, toggle e info |
| `labelsOf(key): list` | sim | Os textos, na mesma ordem de `levelsOf` |
| `levelOf(key): any` | sim | O valor real. Slider: número, pode passar da faixa. Toggle: bool. Info: o texto |
| `setLevel(key, level): void` | sim | Pede a mudança. Nunca lança. Em info não faz nada |
| `available(key): bool` | sim | `false` só pelo que falta na máquina (FR-004) |
| `reason(key): string` | sim | O motivo, de `Strings.settings.sys`; `""` se disponível |
| `rangeOf(key): { min, max }` | só slider | Limites de ← →, e do clique; padrão 0–100 |
| `note(key): string` | não | Falha da última escrita ou estado (microfone mudo) |
| `metaOf(key): list` | não | Linhas a mais do card, antes de NOW (o nome da tela) |
| `listOf(key): list` | só `opens` | As linhas da janelinha só leitura |
| `resetSaved(): void` | não | Limpa o que o produto guarda (FR-006). Só `SysInput` tem |

## Regras

- **Reatividade:** `levelOf`, `labelsOf`, `available` e `reason` leem propriedades com notify, então a binding que as chama
  acompanha. Um provedor nunca obriga a página a relê-lo.
- **Escrita otimista:** depois de `setLevel`, `levelOf` devolve o pedido por até 300 ms ou até o sistema confirmar. Falhou: volta
  ao real e `note` diz por quê (FR-002).
- **Fixture primeiro (FR-009):** com o domínio presente, lê dele e `setLevel` muda só a memória. Sem o domínio, lê do sistema,
  mas com `Fixtures.active` nunca escreve.
- **Serviço ausente:** nenhum aviso no log, no molde do `Battery.qml`.
- **Sem cópia salva (FR-017):** `audio`, `power` e `display` não falam com `SettingsState`.

## Chaves

| Setting | Tipo | Frente |
|---|---|---|
| `sys.audio.output` / `.volume` / `.mute` / `.mic` | choice / slider / toggle / slider | 1A |
| `sys.power.battery` | info | 1B |
| `sys.display.resolution` / `.refresh` / `.scale` | info | 1B |
| `sys.display.brightness` | slider | 1B |
| `sys.input.caps` / `.delay` / `.rate` | choice / choice / slider | 1C |
| `sys.input.shortcuts` | `opens` de action | 1C |

## O que `SettingsModel` faz por eles (etapa 0; nenhuma frente mexe nele)

- `liveOf` reconhece `sys.`; `resolve` põe `values` por `labelsOf`, ou `text` por `levelOf` em info. Lista vazia vira `["—"]`.
- `value`: choice = índice do nível; slider = o nível preso à faixa; `display` mostra o número real (edge case do volume).
- `step` e `pick` respeitam `rangeOf`. A partir de um valor acima do topo, ← anda a partir do real e → não faz nada.
- `isDimmed` e `needsText` incluem `available` e `reason`.
- `reset` não chama `setLevel` em `sys.*`; chama `resetSaved` onde há (FR-006, FR-029).
- `activate` não toca som se o valor não mudou (uma saída só).
- `visibleCategories`: sem as linhas de `requires` que o compositor não tem, e sem as categorias vazias. Toda tela usa ela.
- `SettingsPage` só mostra NOW em linha `sys.*` (FR-005), segue a lista aberta (US2.6) e abre `opens` só leitura.
