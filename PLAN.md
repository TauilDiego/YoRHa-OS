# YoRHa-Shell — plano

> Documento vivo, atualizado em 2026-11-02.

## 1. O que é

**Um sistema visual para o Arch Linux**, inspirado em NieR:Automata. A pessoa instala por cima de
um Arch que já funciona (Hyprland primeiro, Niri depois), e o desktop ganha a cara do projeto:
- **o shell:** barra, menu de pausa, notificações do Pod, OSD e papel de parede;
- **um núcleo opcional:** o tema de boot e de login, o cursor e os sons.

Ele **não** gerencia os pacotes, o hardware nem as configs de quem instala. O nome público é
YoRHa-Shell, e o comando é `yorha` (decidido em 02.11).

**Regra de ouro:** o seu sistema é homologado e não roda nada do projeto. A UI e o instalador
rodam numa VM. A UI só chega na sua máquina quando você mesmo decidir trocar, depois de homologar
na VM.

## 2. Modelo

| Projeto | O que é | O que a gente tira dele |
|---|---|---|
| **Serpantinum** | Um shell em Quickshell que vive nas pastas dele (`~/.local/share/serpantinum`, `~/.config/serpantinum/settings.json`), com um CLI e um aviso de versão nova | **É o nosso modelo:** pastas e config próprias, o aviso de update e o "Update now" |
| Omarchy v2/v3 | Uma personalização inteira do Arch, com `omarchy update` e migrations | As migrations e o jeito de atualizar. Pacotes, hardware e configs ficam de fora |
| Omarchy v4 | ISO + pacotes, com o desktop em plugins Quickshell | Opção futura: um pacote de plugins NieR pra quem usa Omarchy (S7) |

## 3. Partes

| Parte | O que é | Onde fica |
|---|---|---|
| **Shell** | A UI em Quickshell (`shell/`) | `~/.local/share/yorha-shell/versions/<v>/`, com o link `current` |
| **Núcleo opcional** | Boot (Plymouth), login (SDDM) e som de boot (`system/boot-login`); o cursor (`system/cursors`); os sons (`system/sounds`) | O que precisa de root vai pro sistema com backup e desfazer; o resto fica nas pastas do usuário |
| **Config do usuário** | O `shell.json` e o estado que os menus salvam | `~/.config/yorha-shell/` e `~/.local/state/yorha-shell/` |

O seu `hyprland.lua` continua seu. O projeto traz um arquivo com os atalhos e o autostart, e você
inclui ele com uma linha.

## 4. Princípios

1. **Pastas próprias.** Nada é escrito fora delas sem perguntar.
2. **Padrões gerenciados separados dos seus arquivos.**
   - A versão em `versions/<v>` é trocada a cada update.
   - O `~/.config/yorha-shell/` é só seu, e update nunca mexe nele.
   - Mudança de formato vira migration.
3. **Idempotente.** Rodar o instalador duas vezes dá o mesmo resultado.
4. **Nunca sobrescrever sem backup.** O que precisa de root tem um comando de desfazer.
5. **O compositor fica atrás de um adaptador.** Os atalhos ficam num arquivo que a pessoa inclui.
6. **Segredos nunca entram no repositório.**
7. **O nome fica num lugar só.** `yorha`, `yorha-shell` e os caminhos estão no `lib/yorha/name.sh`,
   e o update sabe trocar o nome, se um dia for preciso (spec 015).

## 5. Estrutura

No repositório:

```
YoRHa-Shell/
├── shell/        a UI (Quickshell)
├── system/       o núcleo opcional: boot/, login/, boot-login/ (o módulo com root), cursors/,
│                 sounds/; e hypr/, o arquivo pra incluir no Hyprland (spec 014)
├── bin/          o CLI `yorha` (spec 014)
├── install.sh    instala a versão escolhida (spec 014)
├── migrations/   scripts com data, rodam uma vez por usuário
├── specs/
└── docs/
```

Na máquina de quem instala (método D do estudo 005):

```
~/.local/share/yorha-shell/versions/<v>/   uma pasta por versão (guarda 3)
~/.local/share/yorha-shell/current         link pra versão em uso
~/.local/bin/yorha                         o CLI
~/.config/yorha-shell/                     só seu
~/.local/state/yorha-shell/                estado, migrations feitas, backups
```

## 6. Fluxos

- **Instalar:** `bash <(curl -fsSL https://github.com/TauilDiego/YoRHa-Shell/releases/latest/download/install.sh)`.
  - Confere as dependências do shell e pergunta antes de instalar o que falta.
  - Baixa a versão estável mais nova das releases do GitHub e confere o checksum.
  - Mostra a linha pra incluir no `hyprland.lua`.
- **Atualizar:** `yorha update`, ou SYSTEM › Updates › "Update now", que o menu mostra quando uma
  transmissão avisa que saiu versão nova.
  - Baixa e confere a versão nova.
  - Copia o estado.
  - Roda as migrations.
  - Troca o `current` e reinicia o shell.
- **Voltar:** `yorha rollback` volta a versão e o estado.
- **Núcleo opcional:** `yorha boot-login install|uninstall|status`, que pede sudo.
- **Desinstalar:** `yorha uninstall` deixa a máquina como estava.

O método vem do estudo 005 (`docs/estudo-instalacao.md`, método D). A v0 é só pelo CLI, em texto
simples. Uma interface mais caprichada pro instalador fica pra depois.

## 7. A UI

- **O YoRHa-Shell convive com o Serpantinum até a U7.** Dá pra trocar entre os dois, e a tabela da
  S1 diz o que ainda falta pra troca.
- **A UI NieR é desenvolvida em `shell/`** e substitui o Serpantinum quando cobrir o mínimo:
  barra, menu de pausa no lugar do launcher, notificações, OSD, lock, polkit, energia e
  workspaces.
- **Pra tela, ela fala com o compositor por um adaptador.** Começa com Hyprland, depois Niri.
- **Os dados chegam por serviços que aceitam fixtures** (relógio fixo, bateria em 87%,
  notificações de exemplo). Assim os screenshots de teste saem sempre iguais e dá pra
  comparar uma versão com a outra.
- **Desempenho fica pra depois.** Primeiro a gente implementa, e a otimização vira uma fase
  própria (U6). Até lá vale só o bom senso: nada de blur em tela cheia. Na U6 a gente mede o
  custo por quadro na VM (`QSG_RENDER_TIMING`) e ajusta a UI pra GPU integrada fraca.

## 8. Testes

Tudo que roda código do projeto (UI, instalador, builds) roda num **ambiente de testes privado**,
mantido fora deste repositório. São dois tipos de ambiente:
- **VM:** pro teste bruto (instalação, updates, login, lock, polkit, systemd);
- **containers leves:** pra UI, com screenshots.

Os critérios de aceite de cada spec dizem qual evidência comprova a entrega (screenshot, log,
comando).

## 9. Fases

**F0 Fundação (comum às duas trilhas):** repo git, estrutura, CI de lint (`shellcheck`,
`qmllint`). Fica pronta quando a CI rodar no primeiro commit.

Depois disso são duas trilhas paralelas, que se encontram quando a UI NieR substitui o
Serpantinum.

**Trilha UI (NieR)**

| Fase | Entrega | Pronto quando |
|---|---|---|
| U0 Laboratório | Ambiente de testes privado (VM + containers), com sync e screenshot | Uma mudança em `shell/` aparece no ambiente de testes em segundos, com screenshot como prova |
| U1 Base visual | Design system (tokens, componentes, shaders), fixtures e HUD | Screenshot do HUD com dados de teste |
| U2 Estudo de instalação ✅ | Métodos A–D comparados, com o HUD como carga | `docs/estudo-instalacao.md` escrito e método escolhido (D, versões lado a lado) |
| U3 Menu de pausa ✅ | Launcher, janelas, energia | Screenshot de cada aba |
| U4 Pod e text log ✅ | Notificações e OSD | Uma notificação de teste vira transmissão do Pod |
| U5 Lock e polkit | Tela de bloqueio (PAM) e agente de polkit, testados de verdade na VM | Bloquear, desbloquear e autorizar uma ação funcionam na VM |
| U5a Boot e login ✅ | Splash de boot no Plymouth e tela de login com a UI NieR: tema QML do SDDM (spec 011; a escolha ficou com o SDDM). O bootloader continua o systemd-boot, escolha do dono, então o menu dele não ganha tema | Na VM, um reboot mostra o splash e cai na tela de login nova (screenshots dos dois, do boot até o login); entrar com senha certa abre o Hyprland e com senha errada mostra o erro; o log do boot fica sem erro do tema |
| U5b i18n | Troca de idioma da UI (inglês padrão; português e outros) | A UI inteira muda de idioma por configuração |
| U6 Otimização | Medir o custo por quadro, cortar efeitos caros, opção de reduzir movimento | A UI cabe no orçamento numa GPU integrada |
| U7 Troca | A UI NieR substitui o Serpantinum na sua máquina, só depois de homologada na VM | Você usa um dia inteiro sem voltar pro Serpantinum |

**Trilha sistema (instalar, atualizar e encaixar o shell)**

| Fase | Entrega | Pronto quando |
|---|---|---|
| S1 Serpantinum × YoRHa-Shell | O que o Serpantinum faz por você hoje e o que o YoRHa-Shell já tem | Você revisou a tabela, e ela diz o que falta pra U7 |
| S2 Arch completo na VM ✅ | ISO + archinstall desassistido | Um comando entrega um `arch-limpo` instalado pela ISO |
| S3 Instalação e encaixe (CLI) ✅ | `install.sh`, o CLI `yorha`, as dependências do shell e o arquivo de atalhos do Hyprland (spec 014). Desde a 015, o comando de instalação é o público, pelas releases do GitHub | Numa VM limpa, um comando instala e o shell sobe pelo Hyprland da pessoa |
| S4 Updates ✅ (v0) | `yorha update` e `rollback`, migrations, o aviso no shell e o "Update now" (a v0 veio na spec 014). O canal público veio na 015: as releases do GitHub, com os canais `stable` e `testing`, o sinal de versão nova que fica e a origem pronta pra um espelho. A assinatura fica pra S6 | Atualizar de v0.1 pra v0.2 funciona na VM, pelo CLI e pelo menu |
| S5 Niri | O adaptador do shell e um arquivo de atalhos pro Niri | O mesmo checklist passa no Niri |
| S6 Público | Docs, release assinada (a assinatura entra antes da 1.0), testes em EndeavourOS/CachyOS | Alguém de fora instala sem ajuda |
| S7 (opcional) | Pacote de plugins pro Omarchy usando o mesmo código da UI | — |

**Lembrete da S3, feito na 014:** o supervisor (`yorha shell start`) cria `~/.local/share/applications/`
antes de subir o shell. O Quickshell só observa essa pasta se ela existir quando ele sobe (spec 007:
spike T003, research R4, e T041).

## 10. Riscos

| Risco | Mitigação |
|---|---|
| Escopo (o `bin/` do Omarchy v3 tinha 114 comandos) | Começar só com o que você usa; cada fase entrega algo usável |
| Dependências que mudam (Quickshell, Hyprland) | O instalador confere as versões; o laboratório roda com os pacotes do dia |
| O Arch é rolling e quebra coisas (o Hyprland 0.55 passar pra Lua quebrou vários projetos) | Migrations; laboratório rodando com os pacotes do dia |
| `curl \| bash` | Script curto e legível; versões com tag e checksum |
| Marcas da Square Enix (UI NieR e o nome YoRHa-Shell) | Projeto de fã, gratuito, sem ligação com a Square Enix, e o README diz isso; nada de fontes, sons, logos ou vídeos do jogo; o nome muda por um update comum, se um dia for preciso |
| A UI na VM pode ficar lenta com renderização 3D virtualizada | Medir no U0; os efeitos da UI podem ser desligados |

## 11. Decisões em aberto

1. **O nome definitivo do projeto.** *Resolvida em 02.11:* YoRHa-Shell, com o comando `yorha` (ver
   "Decisões tomadas").
2. **A assinatura das versões.** A 0.1.0 sai só com o `.sha256`; a assinatura entra antes da 1.0.

## Decisões tomadas

- **2026-10-26, camada pessoal:** fica num repositório privado separado. *Superada em 29.10:* o
  projeto ficou só visual e não tem mais camada pessoal; o repositório privado guarda o lab e as
  referências.
- **2026-10-26, nada roda no seu sistema:** a UI, o instalador e os builds rodam em VM. A UI só
  vai pra sua máquina depois de homologada.
- **2026-10-26, VM e não Docker:** o desenvolvimento da UI acontece numa VM, que também serve
  pra testar instalação e updates.
- **2026-10-26, licença:** AGPL-3.0-or-later. Repositório público: `TauilDiego/YoRHa-OS`.
- **2026-10-26, nome:** YoRHa-OS (provisório). Dados pessoais ficam fora do repositório público.
- **2026-10-26, implementar antes de otimizar:** a otimização de desempenho fica pra U6.
- **2026-10-26, testes:** o ambiente de testes (VM + containers) é privado e fica fora do
  repositório público.
- **2026-10-26, U0 concluído** (ambiente privado).
- **2026-10-27, alternativas de design viram opções:** quando um design tem alternativas, elas
  viram opções do System Settings, trocadas ao vivo, com a recomendada como padrão. A primeira é o
  Bar contrast (Normal / High) da spec 004.
- **2026-10-27, limite do laboratório:** no máximo 4 VMs ligadas ao mesmo tempo, com 2 núcleos e
  4 GB cada.
- **2026-10-29, sistema visual:** o projeto é só um sistema visual, como o Serpantinum. Não
  gerencia pacotes, hardware nem configs de quem instala. O núcleo que a experiência pede (boot,
  login) entra com confirmação, backup e desfazer.
- **2026-11-01, instalação v0 pelo CLI:** instalar e atualizar só pelo `yorha`, em texto simples.
  No shell, uma transmissão avisa a versão nova e SYSTEM › Updates tem o "Update now". Uma
  interface mais caprichada fica pra depois.
- **2026-11-01, tudo na `main`:** as branches de spec, de frente e de lab terminam mescladas na `main`
  e apagadas. Não ficam branches nem worktrees parados.
- **2026-11-02, o nome público:** YoRHa-Shell, e o comando continua `yorha`. O dono quis um nome do
  jogo, e o projeto não vai ser vendido. O risco é de marca, e ele aceita com três proteções:
  - a constituição registra a decisão (2.1.0, Restrições, Marcas);
  - o update sabe trocar o nome sozinho, se um dia for preciso;
  - o README diz que é um projeto de fã, gratuito e sem ligação com a Square Enix.
- **2026-11-02, assinatura:** a 0.1.0 sai sem assinatura, só com o checksum. A assinatura entra antes
  da 1.0.
- **2026-11-02, telemetria:** decidida (ligada por padrão e desligável no instalador, como no
  Serpantinum, com os campos dele e os nossos), mas adiada pra spec 016, porque depende da VPS. Até
  lá, o shell só pergunta qual é a versão mais nova.
- **2026-11-02, a VPS na spec 016:** o site, o endereço curto de instalação, uma cópia do checksum, o
  espelho das releases e o receptor da telemetria. A 015 já deixa o instalador e o update prontos pra
  uma segunda origem.

## Histórico

- **2026-10-26:** avaliado usar o Omarchy 4 como base (desktop em plugins + ISO). Descartado
  como base, porque o objetivo é uma personalização em cima de um Arch limpo, sem imagem. A
  ideia fica como opcional (S7).
- **2026-10-26:** avaliado um "aquário" em Docker (Hyprland sem tela,
  `HYPRLAND_HEADLESS_ONLY=1`). Trocado pela VM, que cobre também instalação, updates e
  serviços do sistema (SDDM, polkit, systemd).
- **2026-10-28:** S2 concluída (spec 006): o `lab/install-iso` instala o Arch pela ISO oficial sem
  nenhuma tecla, em cerca de 5,5 min, e congela a camada `arch-iso` (13 de 13 conferências). O dono
  decidiu que a cadeia do Hyprland passa a ser montada sobre ela, junto com as camadas do Niri e do
  Mango do estudo 009.
- **2026-10-29:** U5a concluída (spec 011): o tema de boot do Plymouth (a lista de checagens com as
  etapas reais, a faixa no desligar e o pedido de senha do disco), o tema de login do SDDM (o
  protótipo aprovado) e o módulo `yorha-shell-boot-login`, que instala com backup e desfaz. Na VM: nenhum
  console do ligar ao login, o boot +0,80 s (limite de 1 s, aceito pelo dono), 20 de 20 no estresse do
  login e o journal limpo em 10 ciclos. O dono quase aprovou: a velocidade das linhas do boot (texto
  na hora, só o glitch) vira a spec 012.
- **2026-10-30:** spec 012 concluída: as linhas do boot aparecem inteiras na hora (`typing=instant`,
  o padrão), e a digitação do jogo fica como opção (`typing=game`). Na VM: 32 linhas num boot do
  zero (eram 2 a 5), 35 quadros/s na rajada e o login +0,90 s em relação ao boot sem tema, com a base
  remedida no mesmo dia. O limite é 1 s, então a margem é curta.
- **2026-10-31:** U4 concluída (spec 008): as notificações viram transmissões do Pod, com o text log,
  o OSD e as opções. Visual aprovado pelo dono. A `main` (007) foi mesclada na 008, com os conflitos
  resolvidos pelas decisões do dono. Os roteiros 003, 004, 007 e 008 passaram (110/0 na 008, nos dois
  perfis).
- **2026-11-01:** spec 013 concluída (menus do jogo). Ela trouxe:
  - o movimento medido no jogo;
  - os triângulos ao abrir e fechar;
  - o texto que rola;
  - a escolha entre janela e tela cheia;
  - a janelinha de escolhas;
  - os sons nossos, também no boot e no login;
  - o text log como aba do menu.

  Na VM, os roteiros 003, 004, 007, 008, 011 e 013 passaram. O dono aprovou a tela cheia depois do
  T058, e as decisões abertas estão no `relatorio.md` da spec. No mesmo dia, todas as branches dos
  dois repositórios foram mescladas na `main` e apagadas (as specs 005, 009 e 010 entraram na `main`),
  e o código órfão saiu.
- **2026-11-01:** S3 e S4 concluídas na v0 (spec 014): um comando instala o YoRHa-Shell na pasta dele
  (`~/.local/share/yorha-shell`, versões lado a lado), uma linha no `hyprland.lua` encaixa o shell e os
  atalhos, e o `yorha` atualiza, volta, migra, liga o boot e o login e desinstala. O canal da v0 é o
  repositório local. Na VM, o `check-014` passou inteiro, e os roteiros 003, 004, 007, 008 e 013
  também. Na sessão do dono, uma instalação do zero recebeu uma correção pelo aviso e pelo "Update
  now", voltou com `yorha rollback` e foi de novo com `yorha update`. Os achados da sessão viraram
  correções na hora: as categorias do SYSTEM passaram a rolar, e o instalador diz onde a linha vai.

## Fontes

- Omarchy v2/v3 (`boot.sh`, `install.sh`, `default/` vs `config/`): https://github.com/omacom/omarchy/tree/v3.0.0
- Omarchy v4 (plugins, ISO, VM): https://github.com/omacom/omarchy
- archinstall (`--config`, `--silent`, perfil Hyprland): https://github.com/archlinux/archinstall
- Imagens oficiais de VM do Arch: https://gitlab.archlinux.org/archlinux/arch-boxes
- Hyprland sem tela e aninhado: `hyprtester` e o wiki em https://github.com/hyprwm/Hyprland
- Serpantinum: https://github.com/ilyamiro/serpantinum
- Referência visual YoRHa: https://github.com/metakirby5/yorha
