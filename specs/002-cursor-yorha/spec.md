# Feature Specification: Cursor YoRHa

**Feature Branch**: `001-yorha-base-hud` (vai junto no merge do U1)

**Created**: 2026-10-27

**Status**: Aprovada pelo dono em 2026-10-27 (junto com o plano)

**Input**: Pedido do dono: "o cursor padrão fica feio e muito claro num tema claro; pode
adiantar a implementação de um cursor igual o do jogo, com a setinha e as duas bolinhas embaixo
da parte maior", usando https://github.com/Beinsezii/NieR-Cursors se a licença permitir.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cursor do jogo em todo o desktop (Priority: P1)

O usuário move o mouse e vê o cursor dos menus do NieR: a setinha em forma de pipa, com a
bolinha e os dois losangos embaixo. Os outros formatos (mão em links e abas, I de texto, espera
animada, redimensionar, proibido) seguem o mesmo estilo. O cursor é legível tanto sobre o papel
claro quanto sobre um terminal escuro.

**Why this priority**: O cursor padrão do Hyprland destoa da UI e some sobre o fundo claro, o
que atrapalha até os testes.

**Independent Test**: Na VM, screenshots com o ponteiro sobre o papel, sobre o kitty, sobre uma
aba da barra e dentro do texto do kitty, em 1080p e no perfil hidpi.

**Acceptance Scenarios**:

1. **Given** a sessão aberta na VM, **When** o ponteiro está sobre o fundo, **Then** aparece a
   seta do NieR Cursors, nítida.
2. **Given** o ponteiro sobre o texto do kitty, **When** ele para ali, **Then** aparece o
   cursor de texto do tema.
3. **Given** o perfil 2560x1600 @1,25, **When** o ponteiro aparece, **Then** ele usa um tamanho
   nativo do tema (sem esticar uma imagem pequena).

### Edge Cases

- **Formato que o tema não tem:** cai no Adwaita (`Inherits=Adwaita`).
- **Release do upstream mudou** (hash diferente): a instalação falha com erro claro, em vez de
  instalar outra coisa.

## Requirements *(mandatory)*

- **FR-001**: O tema de cursor padrão MUST ser o NieR Cursors (MIT), com todos os seus formatos
  e o Adwaita de reserva.
- **FR-002**: O cursor MUST ser legível em fundo claro e escuro.
- **FR-003**: O cursor MUST ficar nítido em 1080p e em 2560x1600 @1,25, no tamanho 32 lógico (escolhido pelo dono; o 24 ficava pequeno e apagado sobre o papel).
- **FR-004**: O tema MUST NOT entrar no git (52 MB). Ele vem do release do upstream, fixado por
  URL + sha256 em `system/cursors/nier-cursors.lock`; um hash diferente faz a instalação
  falhar.
- **FR-005**: O crédito MUST ficar em `CREDITS.md`, e o `LICENSE` do upstream MUST ir junto do
  tema instalado.

## Success Criteria *(mandatory)*

- **SC-001**: Screenshots na VM mostram a seta sobre o papel e sobre o kitty, a mão sobre uma
  aba da barra e o I de texto no kitty, nas duas escalas.
- **SC-002**: O tema ativo na VM é `nier_cursors`, sem erros de cursor no log do Hyprland.

## Assumptions

- **Onde roda:** só na VM. Na máquina do dono, entra pelo instalador (S3) ou na troca (U7).
- **Fora do escopo:** converter pra hyprcursor (vetorial). Só se o XCursor não ficar bom.
- **Marca:** o tema é arte de fã, sob MIT, inspirada no jogo. Não traz nenhum arquivo do jogo; a
  pasta `reference/` do upstream, que tem capturas, não é usada.
