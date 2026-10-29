# YoRHa-OS — plano

> Codinome interno. Documento vivo, atualizado em 2026-10-27.

## 1. O que é

**A sua personalização do Arch Linux.** Um comando transforma um Arch recém-instalado no
seu ambiente:
- Hyprland (Niri depois);
- os seus apps, atalhos e scripts;
- tema;
- uma UI própria inspirada em NieR:Automata.

Outras pessoas podem instalar a mesma coisa e escolher o que querem.

**Não é** uma ISO ou imagem (como o Omarchy 4), nem um shell avulso que obriga você a se
adaptar às regras de outra pessoa (como o Serpantinum).

**Regra de ouro:** o seu sistema é homologado e não roda nada do projeto. A UI, o
instalador e o build dos pacotes rodam numa VM. A UI só chega na sua máquina quando você
mesmo decidir trocar, depois de homologar na VM.

## 2. Modelo

| Projeto | O que é | O que a gente tira dele |
|---|---|---|
| **Omarchy v2/v3** | *"Turn a fresh Arch installation into a fully-configured… system… by running a single command"* (MIT) | **É o nosso modelo.** `boot.sh` → `install.sh`, pacotes em listas, padrões separados das configs do usuário, migrations, `omarchy-update` |
| Omarchy v4 | Virou ISO + pacotes, com o desktop em plugins Quickshell | Fica como opção futura: um pacote de plugins NieR pra quem usa Omarchy (S7) |
| Serpantinum | Só o shell; compositor, atalhos e apps ficam por sua conta | Aqui é o contrário: a camada inteira é sua, e as suas ideias entram como módulos |

## 3. Camadas

É isso que torna distribuível: os outros recebem a base mais os módulos que escolherem, e
você recebe tudo isso mais o pessoal.

| Camada | Quem recebe | Exemplos |
|---|---|---|
| **Base** | Todo mundo | Hyprland + uwsm, portais, Quickshell, PipeWire, NetworkManager, Bluetooth, SDDM, kitty, zsh + starship, ferramentas de terminal, captura, clipboard, fontes |
| **Módulos** | Quem escolher | dev, jogos, comunicação, áudio avançado, atalhos estilo Mac, Niri… |
| **Hardware** | Detectado automaticamente | NVIDIA, microcode Intel/AMD, áudio de notebook, utilitários de fabricante |
| **Pessoal** | Só você | Apps de trabalho, atalhos e scripts próprios |

A classificação item a item fica no repositório privado da camada pessoal (`inventario.md`).

## 4. Princípios

1. **Padrões gerenciados separados dos seus arquivos.**
   - O que é do projeto fica em `~/.local/share/yorha-os/default/` e é substituído a cada update.
   - O seu `~/.config/hypr/hyprland.lua` só carrega os padrões e depois os seus arquivos, que
     sobrescrevem o que quiserem.
   - Update nunca mexe no que é seu. Acaba o "reaplicar patches".
2. **Idempotente.** Rodar o instalador duas vezes dá o mesmo resultado.
3. **Nunca sobrescrever sem backup.** Qualquer arquivo existente vai antes pra
   `~/.local/state/yorha-os/backups/<data>/`.
4. **Módulos, não monolito.** Cada área (pacotes, áudio, rede, login, shell, compositor) é um
   script independente.
5. **O shell é um encaixe.** Começa com o que funciona hoje e é trocado pela UI NieR quando
   ela estiver pronta.
6. **Compositor separado do resto.** Atalhos e regras de janela ficam descritos num lugar só,
   e um gerador escreve o `hyprland.lua` (e, depois, o `config.kdl` do Niri).
7. **Segredos nunca entram no repositório.** O instalador configura o app; o login fica por
   conta da pessoa.

## 5. Estrutura do repositório

```
YoRHa-OS/
├── boot.sh            one-liner: instala o git, clona a versão escolhida em ~/.local/share/yorha-os e roda o install.sh
├── install.sh         preflight → pacotes → hardware → config → login → pós-instalação (com log)
├── install/
│   ├── preflight/     é Arch? tem internet? não está rodando como root? tem espaço?
│   ├── packages/      base.packages, modules/<módulo>.packages, hardware/<item>.packages
│   ├── hardware/      detecção: nvidia, intel/amd, notebook…
│   ├── config/        um script por área: áudio, rede, bluetooth, teclado, zram…
│   ├── login/         SDDM (+ tema)
│   └── post-install/  primeira inicialização e reboot
├── default/           configs gerenciadas: hypr/, kitty/, zsh/, starship, btop, fastfetch, gtk…
├── config/            sementes: o que é copiado pro ~/.config do usuário uma única vez
├── shell/             a UI NieR (Quickshell)
├── bin/               CLI `yorha`: update · refresh <app> · module enable/disable · pkg add/remove · doctor
├── migrations/        scripts com timestamp, rodam uma vez por usuário
└── docs/
```

O conteúdo pessoal fica num **repositório privado separado**, instalado como um módulo extra
que só você ativa.

## 6. Fluxos (da personalização)

**Instalar.** Num Arch recém-instalado, logado com um usuário que tem sudo:
1. `curl -fsSL <url>/boot.sh | bash`;
2. um menu (feito com `gum`) pergunta quais módulos instalar;
3. instala tudo;
4. reinicia no SDDM, e o Hyprland abre já configurado.

**Atualizar.** `yorha update`:
1. pega a versão nova;
2. roda as migrations pendentes;
3. instala os pacotes que entraram nas listas;
4. atualiza o sistema;
5. reinicia o shell.

**Voltar uma config pro padrão.** `yorha refresh hyprland` restaura o padrão de uma config
gerenciada, fazendo backup antes.

**Desinstalar.** Fora do escopo inicial. O que existe são os backups de tudo que foi substituído.

O jeito exato de instalar e atualizar **a UI** sai do estudo da seção 8.4.

## 7. A UI

- **O shell é um encaixe.** Na S3 ele usa o Serpantinum, instalado pelo instalador oficial
  dele, pra VM reproduzir o seu uso de hoje enquanto a UI NieR não fica pronta.
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
| U2 Estudo de instalação | Métodos A–D comparados, com o HUD como carga (8.4) | `docs/estudo-instalacao.md` escrito e método escolhido |
| U3 Menu de pausa | Launcher, janelas, energia | Screenshot de cada aba |
| U4 Pod e text log | Notificações e OSD | Uma notificação de teste vira transmissão do Pod |
| U5 Lock e polkit | Tela de bloqueio (PAM) e agente de polkit, testados de verdade na VM | Bloquear, desbloquear e autorizar uma ação funcionam na VM |
| U5a Boot e login | Splash de boot no Plymouth e tela de login com a UI NieR: tema QML do SDDM ou um greeter em Quickshell (a escolha sai da spec). O bootloader continua o systemd-boot, escolha do dono, então o menu dele não ganha tema | Na VM, um reboot mostra o splash e cai na tela de login nova (screenshots dos dois, do boot até o login); entrar com senha certa abre o Hyprland e com senha errada mostra o erro; o log do boot fica sem erro do tema |
| U5b i18n | Troca de idioma da UI (inglês padrão; português e outros) | A UI inteira muda de idioma por configuração |
| U6 Otimização | Medir o custo por quadro, cortar efeitos caros, opção de reduzir movimento | A UI cabe no orçamento numa GPU integrada |
| U7 Troca | A UI NieR substitui o Serpantinum na sua máquina, só depois de homologada na VM | Você usa um dia inteiro sem voltar pro Serpantinum |

**Trilha sistema (personalização do Arch)**

| Fase | Entrega | Pronto quando |
|---|---|---|
| S1 Inventário | Classificação em base/módulo/hardware/pessoal (o rascunho já está pronto) | Você revisou o inventário (repositório privado) |
| S2 Arch completo na VM ✅ | ISO + archinstall desassistido (8.5) | Um comando entrega um `arch-limpo` instalado pela ISO |
| S3 Instalador v0 | Arch limpo → o seu uso, com o Serpantinum no encaixe do shell | O checklist bate na VM |
| S4 Updates | `yorha update` e migrations, usando o que o U2 aprendeu | Atualizar de v0.1 pra v0.2 funciona na VM |
| S5 Niri | Gerador de atalhos e regras de janela, adaptador de workspaces no shell | O mesmo checklist passa no Niri |
| S6 Público | Docs, nome público, licença, testes em EndeavourOS/CachyOS | Alguém de fora instala sem ajuda |
| S7 (opcional) | Pacote de plugins pro Omarchy usando o mesmo código da UI | — |

**Lembrete pra S3 (instalador):** criar `~/.local/share/applications/` antes de subir o shell. O
Quickshell só observa essa pasta se ela existir quando ele sobe; sem isso, um app instalado depois
não aparece no menu de pausa até o shell reiniciar (spec 007: spike T003, research R4, e T041).

## 10. Riscos

| Risco | Mitigação |
|---|---|
| Escopo (o `bin/` do Omarchy v3 tinha 114 comandos) | Começar só com o que você usa; cada fase entrega algo usável |
| Hardware dos outros (e o seu, que a VM não tem) | Detecção e módulos de hardware; decidir como testar na S3 |
| O Arch é rolling e quebra coisas (o Hyprland 0.55 passar pra Lua quebrou vários projetos) | Migrations; laboratório rodando com os pacotes do dia |
| `curl \| bash` | Script curto e legível; versões com tag e checksum |
| Marcas da Square Enix (UI NieR) | Nome público próprio; nada de fontes, sons, logos ou vídeos do jogo |
| A UI na VM pode ficar lenta com renderização 3D virtualizada | Medir no U0; os efeitos da UI podem ser desligados |

## 11. Decisões em aberto

1. **Instalar o QEMU** (`qemu-desktop`, `edk2-ovmf`, `libisoburn`) no seu sistema, ou usar a
   alternativa via Docker (8.1)?
2. **Nome público e licença.** Sugestão: MIT, igual ao Omarchy.
3. **Shell provisório na S3:** Serpantinum (reproduz o seu uso de hoje) ou só uma barra básica?
4. **Revisar o inventário** (repositório privado), principalmente os `?` e a seção "Achados".
5. **O protótipo NieR** que já existe no repositório vira a semente de `shell/`?

## Decisões tomadas

- **2026-10-26, camada pessoal:** fica num repositório privado separado. Pode virar público
  quando a licença for definida.
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

## Fontes

- Omarchy v2/v3 (`boot.sh`, `install.sh`, `default/` vs `config/`): https://github.com/omacom/omarchy/tree/v3.0.0
- Omarchy v4 (plugins, ISO, VM): https://github.com/omacom/omarchy
- archinstall (`--config`, `--silent`, perfil Hyprland): https://github.com/archlinux/archinstall
- Imagens oficiais de VM do Arch: https://gitlab.archlinux.org/archlinux/arch-boxes
- Hyprland sem tela e aninhado: `hyprtester` e o wiki em https://github.com/hyprwm/Hyprland
- Serpantinum: https://github.com/ilyamiro/serpantinum
- Referência visual YoRHa: https://github.com/metakirby5/yorha
