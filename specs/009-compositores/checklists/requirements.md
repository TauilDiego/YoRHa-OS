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

- **O que a spec cita de propósito:** os compositores (Hyprland, Niri, Mango), o Quickshell, os
  comandos `lab/*`, o `lab/perf` e o contrato do adaptador (`capabilities`, tabela §6). Não são escolhas
  de implementação: o **objeto** do estudo são os compositores e o que o IPC deles oferece à UI, as
  ferramentas do lab são o ambiente exigido pela constituição (I e IV) e o contrato é a entrada que o
  estudo confirma. Como fazer cada ferramenta escolher o compositor da VM fica pro plano.
- **Decisões do dono já incorporadas (PRD §6, 28.10):** `arch-iso` pras três (fase 0, US1); AUR na VM
  com versão fixada; os quatro critérios de experiência; o Hyprland no mesmo roteiro. Nenhuma delas
  virou pergunta.
- **Pesos aprovados pelo dono em 2026-10-28** (seção "Critérios e pesos"): experiência 60
  (visão geral 15, colunas 15, animações 10, atalhos e uso diário 20) e técnicos 40 (IPC 15, risco de
  manutenção 10, custo medido 10, empacotamento 5), com âncoras 0–3, três eliminatórios e uma regra de
  recomendação.
- **As três [NEEDS CLARIFICATION] foram respondidas pelo dono na aprovação (2026-10-28)** e estão na
  seção "Clarifications" da spec:
  1. FR-004: as `teste-a/b/c` são recriadas depois da promoção, uma de cada vez, só quando livres
     (`lab/ls`, `pgrep -af qemu-system`, `.pid`); o que estiver em uso fica pendente no resumão;
  2. FR-030/FR-035a: só o dono dá as notas de experiência; o agente junta a evidência e a folha de notas,
     e a recomendação espera o dono;
  3. FR-038: a nota oficial é a do Hyprland puro; os plugins oficiais numa linha "com plugin", com o custo
     no risco de manutenção.
- **Validação:** duas passadas (rascunho e depois das respostas); todos os itens passam.
- **Aprovada pelo dono em 2026-10-28** (constituição V), com os pesos e a regra da recomendação.
