# Specification Quality Checklist: A VPS do projeto

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-11-02
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [ ] No [NEEDS CLARIFICATION] markers remain (três, pro dono: FR-001 o domínio, FR-006 a
  conferência com uma origem só, FR-013 os dados públicos ou só do dono)
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

- As decisões da telemetria tomadas na 015 (02.11) estão nas Clarifications como decididas: ligada
  por padrão, nada quando desligada, os campos do Serpantinum mais os nossos, só o instalador e o
  `yorha` mandam, o receptor na VPS sem IP e sem log, testes com receptor local.
- O GitHub, a VPS, o HTTPS e os caminhos das origens aparecem como decisões e contratos do projeto
  (a 015 já fixou o formato das origens), não como detalhe de implementação. A tecnologia do site e
  o jeito de servir o espelho ficam pro plano.
- `bash <(curl -fsSL …)` no FR-002 é a interface com a pessoa (o mesmo formato do comando da 015).
- Pronta pro `/speckit-clarify` (as três perguntas) e depois pro `/speckit-plan`, com a aprovação do
  dono.
