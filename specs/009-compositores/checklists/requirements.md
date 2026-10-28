# Specification Quality Checklist: Niri e Mango no laboratório (estudo de compositores)

**Purpose**: Validar a completude e a qualidade da spec antes do planejamento
**Created**: 2026-10-28
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [ ] No [NEEDS CLARIFICATION] markers remain
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

- **O que a spec cita de propósito:** os compositores (Hyprland, Niri, Mango), o Quickshell, os
  comandos `lab/*`, o `lab/perf` e o contrato do adaptador (`capabilities`, tabela §6). Não são escolhas
  de implementação: o **objeto** do estudo são os compositores e o que o IPC deles oferece à UI, as
  ferramentas do lab são o ambiente exigido pela constituição (I e IV) e o contrato é a entrada que o
  estudo confirma. Como fazer cada ferramenta escolher o compositor da VM fica pro plano.
- **Decisões do dono já incorporadas (PRD §6, 28.10):** `arch-iso` pras três (fase 0, US1); AUR na VM
  com versão fixada; os quatro critérios de experiência; o Hyprland no mesmo roteiro. Nenhuma delas
  virou pergunta.
- **Pesos propostos** (seção "Critérios e pesos"), pro dono aprovar junto com a spec: experiência 60
  (visão geral 15, colunas 15, animações 10, atalhos e uso diário 20) e técnicos 40 (IPC 15, risco de
  manutenção 10, custo medido 10, empacotamento 5), com âncoras 0–3, três eliminatórios e uma regra de
  recomendação.
- **Três [NEEDS CLARIFICATION], todos de escopo ou de decisão do dono** (o agente não podia perguntar):
  1. FR-004: recriar as `teste-a/b/c` dentro do 009 (o PRD §2 manda, o §3 exclui);
  2. FR-030: quem dá as notas dos critérios de experiência e se a recomendação espera a sessão do dono;
  3. FR-038: o Hyprland avaliado só nativo ou também com os plugins oficiais.
  Cada um tem a recomendação do agente na seção "Perguntas pro dono" da spec. Levar pro
  `/speckit-clarify` ou responder na aprovação, antes do `/speckit-plan`.
- **Validação:** uma passada; os itens marcados passam. O único em aberto é o das marcas, de propósito.
