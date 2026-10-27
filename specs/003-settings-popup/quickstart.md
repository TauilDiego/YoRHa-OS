# Quickstart: validar a 003 no laboratório

Este é o roteiro que prova cada critério de sucesso com evidência da VM (princípio IV). Tudo roda no
ambiente privado (`rien-OS-private/lab`) e **dentro de uma sessão de medição**. Nada disso roda na
máquina do dono. O `lab/check-003` automatiza os cenários 1–11, como o `lab/check-u1` faz com a 001,
e roda o roteiro inteiro num perfil (`--profile 1080|hidpi`) ou só alguns cenários (`--only 2,5`).

## Preparação

```sh
cd ~/projects/rien-OS-private
export NIER_LAB_VM=teste-a NIER_LAB_PROFILE=hidpi   # boot no hidpi: aí os dois modos existem
lab/perf begin "003: validação do popup de configurações" --kind 003-validacao --task 003
lab/up teste-a
lab/check-003                      # perfil 1080 (o cenário 3 passa pelo hidpi)
lab/check-003 --profile hidpi      # o roteiro inteiro em 2560x1600 @1,25
```

O `check-003` faz a preparação sozinho: perfil, `ui.log` vazio, `lab/sync --env
NIER_FIXTURES=fixtures/hud-default.json` (congela as animações, FR-022), shell reiniciado e
`settings reset`. Ele também abre um kitty no workspace 1 pros testes de teclado.

O catálogo é sempre `shell/fixtures/settings-default.json` ([data-model.md](data-model.md)). A
fixture `hud-default.json` só fixa o resto (hora, telemetria) e congela as animações.

## Cenários

| # | Prova | Como | Esperado |
|---|---|---|---|
| 1 | SC-004 (abrir) | `lab/ipc 'hyprctl activewindow -j'`; `lab/key alt-i`; medir até `settings isOpen` = `true` | Abre em ≤ 0,3 s medido do host; `dump.monitor` = o monitor em foco |
| 2 | SC-001 | Pra cada categoria: `lab/shot`, `settings dump`, `lab/key down` | 7 screenshots: popup centrado, resto escurecido sem desfoque, a categoria marcada com a pipa e as opções dela; o `dump` bate |
| 3 | SC-001 (hidpi) | `lab/profile hidpi`, repetir o cenário 2, `lab/profile 1080` | Mesmo layout em 2560x1600 @1,25, réguas e faixas sem meio pixel |
| 4 | SC-002 | Dois `lab/shot` seguidos com o popup aberto, `lab/diffshot` | 0 px de diferença |
| 5 | SC-003 | `settings reset`; a partir das categorias, `lab/key` em ↓ ×3, →, ↓, →, Esc, Esc, com `settings dump` depois de cada uma | Bluetooth → foco nas opções → "K2 Keyboard" → ainda "K2 Keyboard" (→ não muda informação) → categorias → fechado |
| 6 | SC-006 | Na ordem: "Night light" →; "Scale" → até o fim e → de novo; "Brightness" ← e `lab/click` na trilha; "Bluetooth" desligado e os 3 dependentes; "Pair a device" com Bluetooth ligado + Enter; "Battery" ← | Valores e quadro como nos cenários 1–7 da US3; `dimmed` lista os 3; o aviso some depois de 2 s; ← em "Battery" volta pras categorias |
| 7 | SC-004 (fechar) | Fechar pelos 3 caminhos: `lab/key alt-i`; Esc nas categorias; `lab/click` num ponto escurecido. Depois de cada um, `hyprctl activewindow -j` | Popup fechado e a mesma janela ativa de antes de abrir |
| 8 | SC-005 | `fixtures clear`, abrir, `lab/burst 30 0 "<região das pipas>"` em segundo plano e `lab/key down`; depois o mesmo com `reduceMotion: true` no `shell.json` (com reinício do shell) | Nos quadros (com o `times.txt`), a pipa some do item antigo e reaparece no novo em ≈240 ms, estimados pelo ajuste das curvas de cada metade; a pipa clara da categoria fica parada; com movimento reduzido ela só pula |
| 9 | SC-007 | Trecho do log do último carregamento + `qmllint` na VM | 0 erros e 0 avisos de QML |
| 10 | SC-008 | `ipc call gallery open`, Tab (página 2), `lab/shot` | Os componentes novos, com nome e estados (FR-024) |
| 11 | Bordas | `fixtures load fixtures/settings-broken.json` e `settings-long.json`, abrir, `lab/shot` | Mensagem curta no quadro, sem quebrar; a coluna longa rola com a pipa sempre visível e corta com reticências |

## Fechamento

```sh
lab/down teste-a
lab/perf end --result pass --note "003 validada"
```

O relatório do `lab/perf` vai pro `rien-OS-relatorios`. Os screenshots dos cenários 2 e 3, lado a
lado com o mockup, são a evidência pra aprovação do dono (SC-009): a imagem fica em
`~/.local/share/nier-lab/out/003-revisao-sc009.png` (ver [relatorio.md](relatorio.md)).

**Log (cenário 9):** o Qt 6.12.0 escreve um WARN `qt.qpa.wayland.textinput` toda vez que uma janela
sem campo de texto ganha o teclado (o popup, a galeria). Não é QML e não sai do nosso código. O
`check-003` conta esse aviso à parte; silenciar ou não fica pro dono decidir.
