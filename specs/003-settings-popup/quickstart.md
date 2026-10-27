# Quickstart: validar a 003 no laboratório

Este é o roteiro que prova cada critério de sucesso com evidência da VM (princípio IV). Tudo roda no
ambiente privado (`rien-OS-private/lab`) e **dentro de uma sessão de medição**. Nada disso roda na
máquina do dono. O `lab/check-003` automatiza os cenários 1–9, como o `lab/check-u1` faz com a 001.

## Preparação

```sh
cd ~/projects/rien-OS-private
export NIER_LAB_VM=teste-a
lab/perf begin "003: validação do popup de configurações" --kind 003-validacao --task 003
lab/up teste-a && lab/profile 1080
lab/sync --env NIER_FIXTURES=fixtures/hud-default.json   # congela as animações (FR-022)
lab/ipc 'qs -p ~/nier/ui ipc call settings reset'
```

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
| 8 | SC-005 | `fixtures clear`, abrir, `lab/burst <região das opções> 16` enquanto `lab/key down` troca de opção | Nos quadros, a pipa some do item antigo e reaparece no novo em ≈240 ms; a pipa clara da categoria fica parada |
| 9 | SC-007 | Trecho do log do último carregamento + `qmllint` na VM | 0 erros e 0 avisos de QML |
| 10 | SC-008 | `ipc call gallery open`, `lab/shot galeria` | Os componentes novos, com nome e estados (FR-024) |
| 11 | Bordas | `fixtures load fixtures/settings-broken.json` e `settings-long.json`, abrir, `lab/shot` | Mensagem curta no quadro, sem quebrar; a coluna longa rola com a pipa sempre visível e corta com reticências |

## Fechamento

```sh
lab/down teste-a
lab/perf end --result pass --note "003 validada"
```

O relatório do `lab/perf` vai pro `rien-OS-relatorios`. Os screenshots dos cenários 2 e 3, lado a
lado com o mockup, são a evidência pra aprovação do dono (SC-009).
