# Specification Quality Checklist: Pod e text log (notificações e OSD)

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

- **O que a spec cita de propósito, como na 003 e na 004:**
  - o "servidor de notificações do freedesktop" e o `notify-send`: são o contrato com os apps e a
    evidência do "pronto quando" do `PLAN.md`, não uma escolha de código;
  - o "log sem aviso de QML", os "comandos de controle" e o `lab/perf`, que são a evidência definida
    pela constituição (IV);
  - as peças do design system que já existem (`CursorList`, `KeyHints`, `OptionRow`, `Meter`) e a
    configuração `reduceMotion`.

  Não escolhe tecnologia nem estrutura de código.
- **Sem [NEEDS CLARIFICATION]:** o dono não pôde ser consultado durante a escrita. As decisões que
  mudam o resultado ficaram com um padrão razoável na spec e viraram perguntas em aberto no relatório
  e no mockup (posição das transmissões, posição do OSD, histórico em disco, nome da voz do rien-OS,
  log em popup próprio ou aba do menu de pausa). Trocar qualquer uma muda só a FR correspondente.
- **Suposições calibráveis por token:** tinta da faixa (≈84%), velocidade de digitação (≈90 caracteres
  por segundo, no máximo ≈0,7 s), tempos por urgência, tempo do OSD (≈1,2 s).
- **Atalhos (`SUPER + N`, `SUPER + CTRL + N`; ALT na VM):** suposições, trocáveis na config.
- **Pronta para** `/speckit-clarify` (se o dono quiser responder as perguntas antes) ou `/speckit-plan`,
  depois da aprovação do dono (constituição V).
