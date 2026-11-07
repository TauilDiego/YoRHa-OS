<!--
Sync Impact Report
- Versão: 2.2.0 → 2.3.0 (MINOR: amplia o que o princípio II cobre). Spec 018; o dono aprovou a emenda em
  06.11.
- Princípio II: novo item, "O arranjo de monitores". O produto pode guardar, na pasta de estado dele, o
  arranjo que a pessoa escolheu e aplicá-lo em tempo de execução. Nunca edita config pessoal, e, se a
  pessoa editar no arquivo dela o que vale pra uma tela, vale o arquivo.
- Templates: nenhum muda.

Anterior (2.2.0, 03.11):
- Versão: 2.1.0 → 2.2.0 (MINOR: amplia o que o princípio II cobre). Spec 019; o dono decidiu em 03.11.
- Princípio II, "O que fica de fora": "hardware" passa a dizer drivers e firmware. O produto pode ler
  e mudar, em tempo de execução, o que o sistema já oferece (som, luz de tela, teclado, rede,
  Bluetooth), sem instalar driver nem editar arquivo do sistema.
- Templates: nenhum muda.

Anterior (2.1.0, 02.11):
- Versão: 2.0.0 → 2.1.0 (MINOR: amplia a regra de Restrições, Marcas). Spec 015, FR-016; o dono
  aprovou a emenda junto com o plano da 015, em 02.11.
- Título: "YoRHa-OS Constitution" vira "YoRHa-Shell Constitution".
- Abertura: sai o "Nome provisório.". O nome público é YoRHa-Shell, e o comando continua `yorha`.
- Restrições, Marcas: "O nome público vai ser próprio" vira a decisão do nome. O nome usa YoRHa por
  escolha do dono; o projeto é gratuito, de fã e sem ligação com a Square Enix, e o README diz isso;
  continua valendo que nada do jogo entra no repositório, e agora também nos pacotes; o nome pode
  mudar por um update comum.
- Templates: nenhum muda.

Anterior (2.0.0, 01.11):
- Versão: 1.1.1 → 2.0.0 (MAJOR: redefine o princípio II).
- Princípio II: deixa de ser "Camada sobre um Arch limpo, não imagem", com as camadas base,
  módulos, hardware e pessoal. Passa a ser "Sistema visual sobre um Arch limpo": o shell, mais um
  núcleo opcional, nas pastas do próprio produto. É a decisão do dono de 29.10, reafirmada em
  01.11.
- Abertura: "personalização do Arch Linux" vira "sistema visual".
- Fluxo de desenvolvimento: as branches terminam mescladas na principal e apagadas (decisão do
  dono de 01.11, "quero tudo só na main").
- Governança: o inventário da camada pessoal sai das fontes complementares.
- Templates: nenhum muda.
- Anterior (1.1.0 → 1.1.1): o princípio I passou a citar o ImageMagick e o python3 entre as
  ferramentas do ambiente de testes.
-->
# YoRHa-Shell Constitution

É um sistema visual para o Arch Linux (Hyprland primeiro, Niri depois): uma UI própria inspirada
em NieR:Automata. O roteiro geral está em `PLAN.md`; esta constituição fixa as regras que nenhuma
spec, plano ou tarefa pode violar.

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

### II. Sistema visual sobre um Arch limpo

O produto é um sistema visual, como o Serpantinum. A pessoa instala por cima de um Arch que já
funciona, e o desktop ganha a cara do projeto. Não existe ISO nem imagem própria.
- **O que é do produto:**
  - o shell (a UI);
  - um núcleo opcional que a experiência completa pede: o tema de boot e de login, o cursor e os
    sons.
- **Onde ele fica:** nas pastas do próprio produto (`~/.local/share/`, `~/.config/` e
  `~/.local/state/`, na pasta com o nome dele).
- **O que precisa de root** (o boot e o login) só entra com a confirmação da pessoa, com backup
  e com um comando de desfazer.
- **O que fica de fora:**
  - gerenciar pacotes além das dependências do próprio shell;
  - hardware, no sentido de drivers e firmware;
  - serviços que não sejam da experiência;
  - as configs pessoais de quem instala. O `hyprland.lua` e os dotfiles são da pessoa; o produto
    oferece um arquivo pra ela incluir.
- **O que o sistema já oferece:** o produto pode ler e mudar em tempo de execução o som, a luz de
  tela, o teclado, a rede e o Bluetooth. Pra isso, nunca instala driver nem edita arquivo do sistema.
- **O arranjo de monitores:** o produto pode guardar, na pasta de estado dele, o arranjo de monitores que a
  pessoa escolheu (modo, escala, rotação, posição, tela ligada ou não, espelho e tela principal, por
  conjunto de telas) e aplicá-lo em tempo de execução, também depois de um reload e quando uma tela entra
  ou sai. Nunca edita o `hyprland.lua` nem outra config pessoal. Se a pessoa editar no arquivo dela o que
  vale pra uma tela, vale o arquivo, e o produto esquece o que tinha guardado pra aquela tela.

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
- **Marcas:** NieR e YoRHa são marcas da Square Enix. O nome público, YoRHa-Shell, usa YoRHa por
  escolha do dono (02.11.2026): o projeto é gratuito, de fã, sem ligação com a Square Enix, e diz
  isso no README. Nada de fontes (FOT-Rodin), sons, logos ou vídeos do jogo no repositório nem nos
  pacotes. Se um dia for preciso, o nome muda por um update comum (o produto sabe trocar de nome).
- **Segredos:** tokens, chaves, perfis de navegador e configs de VPN nunca entram no repositório.
- **Licença:** AGPL-3.0-or-later (`LICENSE`).
  - Código de terceiros só entra se a licença for compatível: MIT, BSD, GPL-3.0 ou AGPL-3.0.
  - O aviso de autoria original é mantido.
  - Código vindo do Serpantinum (AGPL) entra com crédito no arquivo e em `CREDITS.md`.

## Fluxo de desenvolvimento

- **Git:**
  - o dono faz os commits na branch principal;
  - agentes commitam só nas branches das worktrees deles;
  - o merge na principal é do dono;
  - terminada a spec ou a frente, a branch é mesclada na principal e apagada.
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
- **Fonte complementar:** `PLAN.md` (roteiro).

**Version**: 2.3.0 | **Ratified**: 2026-10-26 | **Last Amended**: 2026-11-06
