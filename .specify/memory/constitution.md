<!--
Sync Impact Report
- Versão: 1.1.0 → 1.1.1 (PATCH: esclarece a lista de ferramentas do ambiente de testes que rodam
  no host; nenhuma regra muda).
- Princípio I: a lista passa a citar o ImageMagick (comparação de screenshots, `lab/diffshot`) e o
  python3 (o amostrador somente-leitura do `lab/perf` e scripts do laboratório), que já eram
  usados (achado A1 do `/speckit-analyze` da spec 001, aprovado pelo dono em 2026-10-27).
- Templates: nenhum muda.
- Anterior (1.0.1 → 1.1.0): o princípio I passou a aceitar containers no ambiente de testes.
-->
# rien-OS Constitution

Nome provisório. É uma personalização do Arch Linux (Hyprland primeiro, Niri depois) com uma
UI própria inspirada em NieR:Automata. O roteiro geral está em `PLAN.md`; esta constituição
fixa as regras que nenhuma spec, plano ou tarefa pode violar.

## Core Principles

### I. O sistema do dono é intocável (NÃO NEGOCIÁVEL)

- **Nada do projeto roda na máquina do dono:** nem a UI, nem o instalador, nem builds de
  pacotes, nem serviços de teste. Tudo isso roda no ambiente de testes privado: VMs, pro teste
  bruto, e containers sem privilégios especiais, pra UI. Esse ambiente é mantido fora do
  repositório público.
- **O que pode rodar no sistema do dono:** só as ferramentas do ambiente de testes (QEMU,
  Docker, `ssh`, `rsync`, `inotifywait`, ImageMagick pra comparar screenshots e `python3` pros
  scripts do laboratório, como o amostrador somente-leitura do `lab/perf`) e as do fluxo de spec
  (`uv`/Spec Kit, `git`).
- **O que não pode ser tocado:** `~/.config`, a config do Hyprland do dono e o Serpantinum.
- **Instalar qualquer coisa nova no sistema do dono** exige aprovação explícita dele.
- **A UI só vai pro sistema do dono** quando ele mesmo decidir, depois de homologar na VM.

Motivo: a máquina do dono é homologada e funciona; o projeto não pode colocá-la em risco.

### II. Camada sobre um Arch limpo, não imagem

O produto transforma um Arch recém-instalado no ambiente do projeto, rodando um script ou
pacote por cima dele. Não existe ISO nem imagem própria.

O conteúdo se divide em quatro camadas:
- **base:** todo mundo recebe;
- **módulos:** opcionais;
- **hardware:** instalado quando detectado;
- **pessoal:** fica num repositório privado separado.

### III. Padrões gerenciados separados dos arquivos do usuário

- **O que é do projeto** vive numa pasta gerenciada e pode ser substituído em qualquer update.
- **Os arquivos do usuário** só carregam os padrões e sobrescrevem o que quiserem. Update
  nunca altera arquivo do usuário.
- **Mudanças de formato** viram migrations idempotentes.
- **Arquivo existente** nunca é sobrescrito sem backup.

### IV. Pronto exige evidência da VM

Uma tarefa só está pronta quando existe prova verificável produzida no laboratório:
- um screenshot tirado no ambiente de testes;
- um comando que responde;
- um log sem erro de QML.

"Funciona na minha cabeça" não conta. Cada critério de aceite de uma spec MUST dizer qual
evidência o comprova.

### V. Spec antes de código

Toda fase do `PLAN.md` passa por spec → plan → tasks antes de implementar:
- o dono aprova a spec e o plano;
- código sem spec aprovada é só pra correções pequenas;
- quando uma ambiguidade muda o que vai ser construído, ela é perguntada ao dono, não decidida
  em silêncio.

### VI. Paralelizar o que for independente

- **Trabalho que dá pra dividir** MUST rodar em agentes paralelos, cada um com worktree git e
  VM próprios (porta de SSH própria).
- **As tarefas paralelizáveis** são marcadas `[P]` no `tasks.md`.
- **O contrato compartilhado** (tokens de design, interfaces de componentes e serviços) vem
  antes e é estável durante o paralelo.
- **Trabalho sequencial** continua sequencial.

### VII. Implementar antes de otimizar; simplicidade

- **Desempenho tem fase própria** (U6). Até lá vale uma regra só: nada de blur em tela cheia.
- **Abstração** só entra quando uma segunda necessidade concreta aparecer.
- **A estética NieR** é chapada (papel, tinta, sem transparência), e isso já é uma vantagem de
  desempenho.

## Restrições

- **Plataforma:**
  - Arch Linux e derivados;
  - Hyprland 0.56+ com config em Lua (`hl.*`); Niri depois;
  - Quickshell 0.3.x (QML / Qt 6).
- **A UI fala com o compositor por um adaptador.** Os dados de sistema chegam por serviços que
  aceitam fixtures, pra os screenshots saírem determinísticos.
- **Marcas:** NieR e YoRHa são marcas da Square Enix. Nada de fontes (FOT-Rodin), sons, logos
  ou vídeos do jogo no repositório. O nome público vai ser próprio.
- **Segredos:** tokens, chaves, perfis de navegador e configs de VPN nunca entram no repositório.
- **Licença:** AGPL-3.0-or-later (`LICENSE`).
  - Código de terceiros só entra se a licença for compatível: MIT, BSD, GPL-3.0 ou AGPL-3.0.
  - O aviso de autoria original é mantido.
  - Código vindo do Serpantinum (AGPL) entra com crédito no arquivo e em `CREDITS.md`.

## Fluxo de desenvolvimento

- **Git:**
  - o dono faz os commits na branch principal;
  - agentes commitam só nas branches das worktrees deles;
  - o merge na principal é do dono.
- **Idioma:** documentação, specs e conversa em português; código e comentários de código em
  inglês.
- **Ciclo de uma fase:**
  1. `/speckit-specify`;
  2. `/speckit-clarify` (quando houver dúvida);
  3. `/speckit-plan`;
  4. `/speckit-tasks`;
  5. execução: tarefas `[P]` vão pra agentes, e cada uma é verificada no lab;
  6. revisão contra a spec;
  7. homologação do dono.
- **Testes:** VM pro teste bruto, containers pra UI, os dois no ambiente privado.

## Governance

- **Precedência:** esta constituição vale mais do que qualquer spec, plano ou tarefa. Um
  conflito se resolve mudando a spec, ou emendando a constituição com aprovação do dono.
- **Emendas:**
  - toda emenda registra a versão e a data;
  - **MAJOR:** remove ou redefine um princípio;
  - **MINOR:** adiciona um princípio ou seção, ou amplia o que um deles cobre;
  - **PATCH:** muda redação.
- **Revisão:** toda revisão de entrega confere os princípios I, IV e V explicitamente.
- **Fontes complementares:** `PLAN.md` (roteiro) e o
  inventário da camada pessoal (num repositório privado).

**Version**: 1.1.1 | **Ratified**: 2026-10-26 | **Last Amended**: 2026-10-27
