# Feature Specification: Linhas do boot na hora

**Feature Branch**: `012-linhas-do-boot` (sai da `main` com a 011 mesclada)

**Created**: 2026-10-29

**Status**: Aprovada pelo dono em 29.10, junto com o plano e as tarefas

**Input**: O dono testou a 011 numa janela da VM, em 29.10, e disse: "na tela dos [ ok ] ele foi tão
rápido que eu nem vi animação nenhuma, nem nenhum log. […] deixa os texto printando na velocidade
máxima. e só o glitch aparecendo mesmo. enfim. vamos experimentando pra ver se fica legal". Na 011, o
dono tinha escolhido manter a digitação na velocidade do jogo (~77 letras/s, a primeira linha a 20
letras/s, ~0,11 s entre linhas). Num boot rápido, isso mostra só 2 a 5 linhas antes da saída. Vendo
ao vivo, ele mudou de ideia: as linhas aparecem inteiras e na hora, e a animação fica só por conta do
glitch.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver as etapas do boot passando (Priority: P1)

O computador liga, e a lista de checagens enche na velocidade em que o sistema sobe: cada etapa
aparece inteira (o texto e o `[ OK ]`) no momento em que chega, e a lista rola quando passa da tela.
O que se mexe é o glitch do jogo: as faixas de interferência que escurecem e rasgam o texto, a
cintilação, a lente e a película. No fim, a lista sai como hoje e o login entra.

**Why this priority**: É o pedido do dono. Sem isso, num boot rápido a tela de boot mal mostra o que
aconteceu.

**Independent Test**: Na VM, `lab/bootcap` de um boot do zero com o tema instalado pelo módulo. Na
folha de contato, a lista mostra muito mais etapas que na 011, nenhum quadro mostra uma linha pela
metade, e as faixas de interferência continuam aparecendo.

**Acceptance Scenarios**:

1. **Given** um boot com o tema, **When** uma etapa do sistema chega, **Then** a linha dela aparece
   inteira, com o estado, no mesmo quadro, sem digitação, sem a letra sorteada na ponta e sem nascer
   apagada.
2. **Given** várias etapas chegando juntas, **When** elas chegam, **Then** aparecem todas, no mesmo
   quadro ou nos seguintes, sem espera entre uma linha e outra, e a lista rola.
3. **Given** etapas que não estão no catálogo, **When** elas chegam, **Then** viram linhas por grupo
   com a contagem ("Starting system services (12)"), sem encher a tela de linhas "(1)".
4. **Given** a lista correndo, **When** o tempo passa, **Then** as faixas de interferência, o rasgo,
   a cintilação, a lente e a película continuam como na 011.

---

### User Story 2 - A digitação do jogo como opção (Priority: P2)

Quem preferir o ritmo do jogo liga a digitação de volta numa opção do tema de boot.

**Why this priority**: É a regra do dono de toda alternativa virar opção, com a recomendação como
padrão.

**Independent Test**: Com `typing=game` no `config` do tema de boot, a captura de um boot mostra a
digitação da 011.

**Acceptance Scenarios**:

1. **Given** `typing=game`, **When** o boot roda, **Then** as linhas são digitadas como na 011 (a
   primeira mais devagar, a letra sorteada na ponta, a linha nascendo apagada e o intervalo entre
   linhas).

---

### Edge Cases

- **Uma rajada de etapas** (dezenas em menos de um segundo): a lista acompanha sem derrubar os quadros
  por segundo abaixo de 25. Se a preparação das imagens do texto não couber num quadro, as linhas
  entram nos quadros seguintes, sem pular nenhuma.
- **Falhas, saída, senha do disco, desligar e cursor `_`:** continuam como na 011.
- **`effects=calm`** (movimento reduzido): as linhas aparecem na hora e sem glitch nenhum.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Com `typing=instant` (o padrão), cada linha MUST aparecer inteira (o texto e o estado)
  quando a etapa chega, sem digitação, sem a letra sorteada e sem nascer apagada.
- **FR-002**: As linhas MUST NOT esperar umas pelas outras: sem intervalo entre linhas, e mais de uma
  linha pode aparecer no mesmo quadro.
- **FR-003**: As etapas sem nome no catálogo MUST continuar agrupadas, numa linha por grupo com a
  contagem, no máximo uma linha de cada grupo a cada 0,5 s.
- **FR-004**: O glitch (as faixas com rasgo e anéis, a cintilação, a lente, a película e a marca
  d'água) MUST ficar como na 011, e `effects=calm` MUST continuar tirando tudo isso.
- **FR-005**: Com `typing=game`, a lista MUST se comportar exatamente como na 011.
- **FR-006**: As falhas, a saída (0,4 s ou 0,9 s), o cursor `_`, a senha do disco e o desligar MUST
  NOT mudar.
- **FR-007**: O tema MUST NOT deixar o boot mais lento que na 011 (o limite de +1 s continua), e a
  tela MUST ficar a 25 quadros/s ou mais durante as rajadas.

## Success Criteria *(mandatory)*

Cada critério diz a evidência que o comprova (constituição, princípio IV).

- **SC-001**: No boot do zero da VM `boot-iso`, a lista mostra pelo menos 15 linhas antes da saída
  (na 011 eram 2 a 5), e nenhum quadro da captura mostra uma linha pela metade. *Evidência:* a folha
  do `lab/bootcap`.
- **SC-002**: A tela fica a 25 quadros/s ou mais durante a rajada. *Evidência:* a captura com
  `debug=on`.
- **SC-003**: O login aceita teclas no máximo 1 s depois do que aceitaria sem o tema. *Evidência:*
  `lab/011/boot-timing`, três boots.
- **SC-004**: Com `typing=game`, a captura mostra a digitação da 011. *Evidência:* a folha do
  `lab/bootcap`.
- **SC-005**: O dono vê o boot na janela da VM e aprova ("vamos experimentando"). *Evidência:* a
  aprovação dele.

## Assumptions

- **Iteração:** o dono quer experimentar, então os detalhes (por exemplo, a cadência das linhas por
  grupo) podem mudar depois que ele vir na janela, sem uma spec nova.
- **Escopo:** só a lista do tema de boot muda. O login, a passagem e o módulo ficam como na 011.
