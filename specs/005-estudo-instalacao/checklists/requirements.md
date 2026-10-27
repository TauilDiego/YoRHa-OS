# Specification Quality Checklist: Estudo de instalação (U2)

**Purpose**: Validar a completude e a qualidade da spec antes do planejamento
**Created**: 2026-10-27
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- **O que a spec cita de propósito:**
  - os quatro métodos pelo nome (AUR, repositório pacman, git): eles **são** o objeto do estudo, definido no
    `PLAN.md`, e não uma escolha de implementação;
  - o `lab/perf`, os screenshots e o log de QML, porque são a evidência definida pela constituição (IV);
  - `~/.config` e `~/.local/state/rien-os/`, porque são a fronteira da constituição III e o caminho que a
    004 já usa pro estado.
- **Escolhas feitas sem o dono** (ele não pôde ser consultado; entram como suposições, revisáveis na
  aprovação, e não como [NEEDS CLARIFICATION]):
  - nada publicado de verdade (tudo simulado no laboratório);
  - carga = `shell/`; cursor como carga secundária opcional;
  - a escolha vale pra camada inteira, com combinações permitidas;
  - pesos de partida no plano;
  - protótipos no repositório privado.
- **Escopo:** é um estudo. O produto (instalador, `rien update`) é a S3 e a S4.
- **Pronta para** `/speckit-plan` (já escrito junto, a pedido do dono). As duas esperam aprovação
  (constituição V).
