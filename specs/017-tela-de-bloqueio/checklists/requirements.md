# Specification Quality Checklist: Tela de bloqueio

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-11-02
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [ ] No [NEEDS CLARIFICATION] markers remain (duas, pro dono: FR-002 a convivência com outro
  bloqueador, FR-010 as outras opções de Power na v0)
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

- `loginctl lock-session`, o PAM e o Hyprland aparecem como decisões e restrições do projeto (o
  pedido que POWER › Lock já manda, a senha do sistema, a plataforma da constituição), não como
  detalhe de implementação. Serviço de ociosidade ou timer do shell, e como cobrir as telas, ficam
  pro plano.
- A v0 é enxuta de propósito (o dono quer trocar o Serpantinum nesta semana); o que fica fora está
  listado nas Assumptions.
- O agente de polkit, a outra metade da U5 no PLAN, fica numa spec própria.
- Pronta pro `/speckit-clarify` (as duas perguntas) e depois pro `/speckit-plan`, com a aprovação do
  dono.
