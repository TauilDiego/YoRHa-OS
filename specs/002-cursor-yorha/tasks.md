---
description: "Tarefas da spec 002: cursor YoRHa (registro retroativo)"
---

# Tasks: Cursor YoRHa

**Input**: `specs/002-cursor-yorha/` (spec.md, plan.md)

**Registro retroativo**, escrito no T039 da 001. As tarefas foram feitas em 2026-10-27, na ordem
abaixo, com o dono aprovando cada etapa. Cada uma aponta pro commit (branch `001-yorha-base-hud`)
e pra sessão `lab/perf` (relatórios em `~/projects/rien-OS-relatorios/runs/`), quando houve teste
na VM.

## Formato: `[ID] [P?] Descrição`

- **[P]**: feito em paralelo, por agentes com worktree e VM próprios

---

## Phase 1: Spec e primeira versão

- [x] C001 Escrever a spec 002 a partir do pedido do dono, conferir a licença do NieR Cursors (MIT) e registrar o crédito em `CREDITS.md`. Commit `a52c3e8`
- [x] C002 Aplicar o tema do upstream na VM e conferir sobre o papel (rejeitado pelo dono: claro demais; depois a recoloração também foi rejeitada). Sessão `2026-10-27T023441-vm-teste-a-spec-002-cursor-do-nier-check-u1`

## Phase 2: Desenho próprio

- [x] C003 Estilo aprovado como módulo único (`gen/style.py`), a nave em 6 direções (`ship.py`), a tabela dos 39 formatos com hotspots e aliases do upstream (`cursors.py`), o texto (`fam_text.py`), a folha de contato (`preview.py`), o `manifest.hl`, o `NOTICE` e o `build.sh` em container. Commit `d9050ec`
- [x] C004 Spec revisada pro desenho próprio vetorial; `defaults.conf` (`rien_cursors`, 48). Commit `60e5262`
- [x] C005 [P] Famílias C (redimensionar) e D (bordas e cantos): `fam_resize.py`, `fam_edge.py`. Commit `c88d180` (merge `67ac166`)
- [x] C006 [P] Famílias E (mãos) e F (mira, alvo, espera): `fam_hand.py`, `fam_ring.py`. Commit `c1aa7e0` (merge `a9234b6`)
- [x] C007 Tema completo (39 formatos) e a mão sobre abas e itens clicáveis (`cursorShape` no `HeaderButton` e no `ListItem`). Commit `f850d7c`; sessão `2026-10-27T033605-vm-teste-a-spec-002-tema-de-cursor-completo-39-chec` (check-u1 pass)

## Phase 3: Carregamento 1:1 (FR-007)

- [x] C008 Carregamento com os quadros do NieR Cursors, recoloridos por rampa de claridade (`fam_loading.py`); `upstream.lock` com url + sha256; `Cursor_Loading` com o círculo pequeno sobre a nossa nave. Commit `a695442`; sessão `2026-10-27T093157-vm-teste-a-cursor-carregamento-1-1-wait-progress-ch` (check-u1 pass)

## Phase 4: Validação

- [x] C009 Dono vê o tema completo na VM, em janela, no perfil hidpi. Sessão `2026-10-27T082326-vm-teste-c-dono-ve-a-ui-cursor-39-formatos-teste-c-`
- [x] C010 SC-002: tema ativo `rien_cursors` (hyprcursor) e o cursor do rien-OS sobre o papel, conferido pelo `check-u1` em cada sessão de validação da 001 (ex.: `2026-10-27T132649-vm-teste-c-u1-pipa-parada-com-blink-regua-com-ponto`)
- [x] C011 SC-003: folha de contato com os 39 formatos ao lado dos originais (`gen/preview.py`), mostrada ao dono no relatório da segunda noite (commit `c0195ec`)
- [ ] C012 SC-001 completo: screenshots da seta sobre o papel e sobre o kitty, da mão sobre uma aba e do I de texto no kitty, nos perfis 1080 e hidpi, juntos numa sessão `lab/perf`

## Dependencies

- C003 depende de C001; C005 e C006 dependem do estilo (C003) e rodaram em paralelo; C007 junta
  as famílias; C008 depende da tabela (C003).
- C012 é o que falta pra fechar a spec formalmente. O retorno do dono sobre o polegar das mãos e
  o formato "move" fica registrado no plan.md.
