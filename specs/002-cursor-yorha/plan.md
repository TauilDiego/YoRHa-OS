# Implementation Plan: Cursor YoRHa

**Branch**: `001-yorha-base-hud` (vai junto no merge do U1) | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Plano retroativo.** A spec 002 foi implementada direto, no mesmo dia em que foi escrita, com o
dono aprovando cada passo (a seta, o estilo, o tema completo, o carregamento 1:1). Este plano é o
registro do que foi construído, escrito depois, no T039 da 001. **Exceção ao princípio V registrada**:
o cursor não é uma fase do `PLAN.md`, e as aprovações foram dadas peça por peça na conversa, não
num plano formal.

## Summary

Um tema de cursor próprio, o **rien-OS Cursors** (`rien_cursors`), com os 39 formatos do NieR
Cursors de Beinsezii (MIT): os mesmos nomes, aliases e hotspots, mas desenho vetorial próprio, no
estilo da "nave" do minigame de hacking aprovado pelo dono. Os dois formatos de carregamento usam
os quadros do NieR Cursors 1:1, recoloridos pra paleta do rien-OS (FR-007). O tema sai como
hyprcursor (SVG, desenhado no tamanho exato pelo Hyprland) com um XCursor de reserva gerado dos
mesmos SVGs.

## Technical Context

**Language/Version**: Python 3 (geradores de SVG e PNG), Bash (`build.sh`, `lab/cursor`)

**Primary Dependencies** (só dentro do container de build): Pillow, numpy, `hyprcursor-util`,
`rsvg-convert` (librsvg), `xcursorgen`, `curl`

**Storage**: fontes no repositório (`system/cursors/rien-cursors/gen/*.py`, `manifest.hl`,
`NOTICE`, `upstream.lock`); o tema montado fica fora do repositório (cache do laboratório)

**Testing**: evidência na VM: `lab/cursor` aplica o tema; `lab/check-u1` confere o cursor do
rien-OS sobre o papel; a folha de contato (`gen/preview.py`) mostra os 39 formatos

**Target Platform**: Hyprland 0.56+ (hyprcursor) com XCursor de reserva; só na VM até o
instalador (S3) ou a troca (U7)

**Constraints**:
- o único download é o release do NieR Cursors, conferido pelo sha256 do `upstream.lock` (sem
  hash igual, o build falha);
- nenhum arquivo do jogo no repositório;
- tamanho padrão 48 lógicos (`system/cursors/defaults.conf`).

## Constitution Check

| Princípio | Como foi cumprido | Status |
|---|---|---|
| I. Sistema do dono intocável | O build roda num container (`archlinux:latest`); o tema só é aplicado na VM (`lab/cursor`) | ✅ |
| III. Padrões × arquivos do usuário | O tema e o `defaults.conf` são padrões gerenciados; a escolha do usuário fica pro instalador (S3) | ✅ (n/a no U1) |
| IV. Pronto com evidência | `check-u1` e sessões `lab/perf` por etapa (ver tasks.md) | ✅ (SC-001 completo pendente) |
| V. Spec antes de código | Spec aprovada antes do código; o plano é retroativo | ⚠️ exceção registrada |
| Restrições: licença e marcas | NieR Cursors é MIT, com crédito em `CREDITS.md` e no `NOTICE`; desenho próprio; capturas do jogo só no repositório privado | ✅ |

## Project Structure

```text
system/cursors/
├── build.sh                    # monta hyprcursor + XCursor num container; baixa e confere o upstream
├── defaults.conf               # name=rien_cursors, size=48
└── rien-cursors/
    ├── manifest.hl             # manifesto do hyprcursor
    ├── NOTICE                  # crédito ao Beinsezii (MIT), instalado junto do tema
    ├── upstream.lock           # url + sha256 do release do NieR Cursors (FR-007)
    └── gen/
        ├── style.py            # o estilo aprovado: placas, chanfro, frestas, esfera, blocos, profundidade
        ├── ship.py             # a nave (seta) em 6 direções
        ├── cursors.py          # a tabela dos 39 formatos: nomes, aliases e hotspots do upstream
        ├── fam_pointer.py, fam_text.py, fam_resize.py, fam_edge.py, fam_hand.py, fam_ring.py
        ├── fam_loading.py      # carregamento 1:1 do upstream, recolorido por rampa de claridade
        └── preview.py          # folha de contato (39 formatos ao lado dos originais)
```

No laboratório (privado): `lab/cursor` monta o tema (com cache) e aplica na VM.

## Decisões registradas

- **Rejeitados pelo dono:** o tema do upstream como estava (claro demais) e a recoloração dele
  (feia e serrilhada, por ser XCursor raster). Daí o desenho próprio vetorial.
- **Carregamento:** os quadros do upstream (90 quadros a 60 fps, 8 tamanhos), com o alfa intacto
  e uma rampa de claridade que não estica os claros (esticar fazia a trama dele virar xadrez).
- **Mão:** aparece sobre abas e itens clicáveis (`cursorShape` no `HeaderButton` e no `ListItem`).
- **Em aberto:** o retorno do dono sobre o polegar das mãos e o formato "move", e se o fork
  `TauilDiego/NieR-Cursors` pode ser apagado.

## Complexity Tracking

| Violação | Por que | Alternativa mais simples descartada |
|---|---|---|
| Plano depois do código (princípio V) | O dono pediu pra adiantar o cursor e aprovou cada passo na hora | Parar a cada etapa pra um plano formal atrasaria um ajuste visual iterativo |
