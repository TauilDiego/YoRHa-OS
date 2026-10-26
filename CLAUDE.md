# rien-OS

Personalização do Arch Linux (Hyprland, Niri depois) com uma UI própria inspirada em
NieR:Automata. As regras estão em `.specify/memory/constitution.md` e valem acima de tudo.

## Regras que mais importam

- **Nada do projeto roda no sistema do dono.** UI, instalador e builds rodam só no ambiente de
  testes privado, que fica num repositório privado irmão (`../rien-OS-private/lab/`, ver o
  `README.md` de lá). Se ele não existir na sua cópia, não rode nada: pergunte.
- **Spec antes de código:** `/speckit-specify` → `/speckit-plan` → `/speckit-tasks`, com o dono
  aprovando a spec e o plano.
- **Pronto só com evidência:** screenshot do ambiente de testes, comando que responde, log sem erro de QML.
- **Tarefas `[P]`** vão pra agentes paralelos, cada um com worktree e VM próprios.
- **Git:** o dono commita na branch principal; agentes, só nas branches deles.
- **Idioma:** conversa, docs e specs em português; código e comentários em inglês.

## Onde está cada coisa

| Arquivo | Conteúdo |
|---|---|
| `PLAN.md` | Roteiro: fases U (UI) e S (sistema), decisões |
| `specs/` | Specs das fases (criadas pelo Spec Kit) |
| `shell/` | A UI (Quickshell) |
