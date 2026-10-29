---
description: "Tarefas da 011: boot e login (U5a)"
---

# Tasks: Boot e login

**Input**: `specs/011-boot-e-login/` (plan.md, spec.md, research.md, data-model.md, contracts/,
quickstart.md)

**Status**: aprovadas em 29.10 ("sim"). Setup e fundação feitos (T001–T010; a sondagem está em `sondagem.md`).

**Tests**: a spec não pede testes automatizados de código. A prova de cada tarefa é a evidência da VM
(princípio IV): screenshot ou captura do boot, um comando que responde (`loginctl`, `pgrep`, o estado
da VM pelo QMP) e o journal sem erro de QML, sempre dentro de `lab/perf begin/end`.

**Caminhos**:
- `system/…`, `specs/…`, `CREDITS.md`, `README.md` = repositório público `YoRHa-OS`;
- `lab/…` = repositório privado `YoRHa-OS-private`, branch `lab-011`
  (`~/projects/nier-os-project/YoRHa-OS-private-wt/lab-011/lab/`).

**VMs:** no máximo 4 ao mesmo tempo, cada uma com `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G` (limite do dono).
A fundação usa a `teste-011`. As frentes usam `t011-boot`, `t011-login` e `t011-inst` (já existe uma
`teste-boot` do estudo do boot), e a `teste-011` fica desligada enquanto elas rodam.

## Formato: `[ID] [P?] [Story] Descrição`

- **[P]**: vai pra um agente paralelo, com worktree e VM próprios (constituição VI). Nas fases das
  frentes, `[P]` quer dizer "em paralelo com as outras frentes"; **dentro de uma frente, a ordem é a
  dos IDs**.
- **[Story]**: história da spec (US1–US5).
- **Frentes** (todas saem da `011-boot-e-login` depois da T010):
  - **A** = boot: worktree `YoRHa-OS-wt/impl011-boot`, branch `011-boot`, VM `t011-boot`. Fases 4 e 7.
  - **B** = login: worktree `YoRHa-OS-wt/impl011-login`, branch `011-login`, VM `t011-login`. Fase 3.
  - **C** = instalação: worktree `YoRHa-OS-wt/impl011-instalar`, branch `011-instalar`, VM
    `t011-inst`. Fase 5.

---

## Phase 1: Setup (laboratório e sondagem)

**Purpose**: a VM com SDDM e Plymouth, as ferramentas de captura e a confirmação do que o plano supõe.

- [X] T001 Criar a branch `lab-011` no repositório privado a partir da `lab-009` (a que tem a `hypr-iso` e o `install-iso`), com a worktree `~/projects/nier-os-project/YoRHa-OS-private-wt/lab-011`, e anotar a origem em `lab/README.md`
- [X] T002 Escrever `lab/011/provision-boot-iso`: a partir da `hypr-iso`, instalar `sddm` e `plymouth`, tirar o login automático, habilitar o `sddm.service` e congelar a camada `boot-iso` (com a marca de compositor); documentar a camada na árvore de `lab/README.md`
- [X] T003 [P] Escrever `lab/011/users <vm> [--many 20]`: cria dois usuários de teste (`ana`, `bruno`) com a senha de teste em `lab/011/users.env` (só existe no lab), ou 20 usuários com `--many`; idempotente
- [X] T004 [P] Escrever `lab/bootcap <vm> --until login|password|off [--every 0.25]`: liga a VM em `--soft`, tira `screendump` pelo QMP no intervalo, grava `times.txt` (hora de cada quadro desde o ligar), para na condição e monta a folha de contato com o ImageMagick em `out/bootcap-<data>/`; documentar em `lab/README.md`
- [X] T005 Escrever `lab/011/install-dev <vm>`: instalação só de laboratório, até a frente C entregar o módulo. Liga as pastas do repositório sincronizado (`system/login/sddm/yorha-os`, `system/boot/plymouth/yorha-os`) nas pastas de tema, copia a fonte de `shell/assets/fonts/` pra `/usr/share/fonts/yorha-os/`, escolhe o tema no SDDM e no Plymouth, põe o hook `plymouth` e o `splash` e refaz o initramfs
- [X] T006 Sondagem R0 na `teste-011` (de `boot-iso`), com um tema `script` mínimo em `lab/011/sondagem/`. Confirmar os seis itens da research R0: (1) nomes das unidades no `SetUpdateStatusFunction`, (2) `Image.Crop`, (3) ~100 sprites a ≥25 quadros/s, (4) M PLUS 1 no initramfs com `Image.Text`, (5) `GetMode()` = `shutdown`/`reboot`, (6) a passagem pro SDDM sem console com o drop-in da R8. Registrar em `specs/011-boot-e-login/sondagem.md` (com os relatórios do `lab/perf` e as capturas) e ajustar `research.md` (R6–R8) no que mudar
- [X] T007 Criar o esqueleto do plano: `system/boot/plymouth/yorha-os/`, `system/login/sddm/yorha-os/` e `system/boot-login/`, cada um com um `README.md` curto (o que é, como gerar, como testar no lab), e as entradas novas em `CREDITS.md`: Qylock (Darkkal44, GPL-3.0, pro que espelhar a conversa com o SDDM) e o uso da M PLUS 1 e do anel do NieR Cursors (MIT) nos temas

---

## Phase 2: Foundational (o que as frentes dividem)

**Purpose**: o anel de carregamento e os números do design system, antes das frentes.

**⚠️ CRITICAL**: nenhuma frente começa antes desta fase.

- [X] T008 Acrescentar a saída de quadros em `system/cursors/yorha-cursors/gen/fam_loading.py` (`--frames <pasta> --palette light|ink --size <px>`): os mesmos 90 quadros a 60 quadros/s, recoloridos pela rampa existente. Gerar no lab `system/boot/plymouth/yorha-os/assets/ring/` (claro sobre escuro, 128 px) e `system/login/sddm/yorha-os/assets/ring/` (tinta sobre papel, 64 px) e commitar os PNG. Avisar no `README.md` do cursor que a 010 (item D) reaproveita esta saída
- [X] T009 Escrever `system/login/sddm/yorha-os/ds/Tokens.qml`: o pedaço dos `Tokens` do shell que o login usa (cores, `space` das listas e da pipa, `motion.highlight` 150 e `motion.blink` 240, `vignette`, `wallpaper.ruleAlpha`), com o cabeçalho "port of shell/ds/Tokens.qml; keep the numbers in sync"
- [X] T010 Escrever o modo `ds-sync` de `lab/check-011`: compara os números que precisam bater entre `system/login/sddm/yorha-os/ds/` e `shell/ds/` (cores, período 77 e marcas da régua, arcos e feixes do `PaperDecor`, tamanhos da pipa, 150/240 ms, vinheta) e falha na primeira diferença

**Checkpoint**: fundação pronta. As frentes A, B e C podem começar, cada uma na sua worktree e VM.

---

## Phase 3: User Story 1 - Entrar pela tela de login nova (Priority: P1) 🎯 MVP · Frente B

**Goal**: o tema do SDDM com o layout aprovado: entrar, errar, trocar de usuário e de sessão,
reiniciar e desligar com confirmação.

**Independent Test**: com `lab/011/install-dev` na `t011-login`, reiniciar até o login; tirar
screenshots nos dois perfis; entrar com `ana` e `bruno` (o `loginctl` mostra a sessão gráfica e o
`pgrep -u <usuário> Hyprland` responde); errar a senha; usar o "Other user…"; trocar a sessão;
Reboot e Shut down com Cancel e com confirmação (estado da VM pelo QMP).

- [X] T011 [P] [US1] Portar `ds/Rule.qml`, `ds/PaperDecor.qml` e `ds/Vignette.qml` em `system/login/sddm/yorha-os/ds/` a partir de `shell/ds/primitives/`, trocando o `QsWindow`/`Tokens.scaleOf` pelo `Screen.devicePixelRatio`, com o cabeçalho de origem; a régua no modo `crisp`
- [X] T012 [P] [US1] Portar `ds/Selector.qml`, `ds/ListItem.qml` e `ds/Label.qml` de `shell/ds/base/` e `shell/ds/primitives/`: a varredura da esquerda (tinta, trilhos e sombra) em 150 ms na entrada e saída instantânea; a pipa parada que pisca em 240 ms (some com ease-in, pula, aparece com ease-out)
- [X] T013 [US1] Escrever `components/GreeterState.qml`: os estados `intro`, `ready`, `checking`, `welcome`, `leaving`, com as transições do `data-model.md`; `enter(estado)` para todas as animações e temporizadores do estado anterior antes de começar; cada transição escreve `yorha-login: state=<estado>` no log; `inert` verdadeiro fora de `ready` (FR-021)
- [X] T014 [US1] Escrever `metadata.desktop` (`Type=sddm-theme`, `MainScript=Main.qml`, `ConfigFile=theme.conf`, `QtVersion=6`), `theme.conf` e a leitura das opções em `Main.qml`: `intro` = `full`|`fade`|`none`, `clock` = `big`|`small`|`none`, `userList` = `always`|`auto`, `reduceMotion` = `false`|`true`, padrão o primeiro; "Um valor inválido vale como o padrão e gera um aviso no log, uma vez"
- [X] T015 [US1] Montar `Main.qml`: o fundo da cena "Menu" (papel, `PaperDecor` respirando no ciclo de 600 s, `Vignette`), a régua de cima na altura da régua da barra (y 48 em 1080p) e a de baixo em y 1012, as duas em s=1; o cabeçalho "LOGIN -Authentication"; as três colunas e a barra de teclas abaixo da régua de baixo; os painéis só no `primaryScreen`, e os outros monitores só com o fundo (FR-036); tudo escalado pela altura da tela
- [X] T016 [US1] Escrever `components/Users.qml`: o `userModel` mais o "Other user…" no fim, começando no `lastIndex`; ↑↓ e clique; a varredura e a pipa; mais de 10 usuários rola em linhas inteiras com a barra fina e o contador "n / total"; `userList=auto` esconde a lista com um usuário só; nome longo corta com "…"; sem usuário listável, só o "Other user…", já selecionado
- [X] T017 [US1] Escrever `components/AuthCard.qml`: o campo de senha com um quadradinho por caractere (entra com o "pop", sai encolhendo; passando da largura, os mais antigos saem pela esquerda sob o "…"; o cursor sempre visível); o campo de nome do "Other user…" (Enter passa pra senha); o aviso "Caps Lock is on." pelo `keyboard.capsLock`; a linha de mensagem; em `checking`, o anel (`assets/ring`, tinta) e o campo e o Enter travados (FR-010)
- [X] T018 [US1] Escrever `components/Actions.qml` e `components/KeyBar.qml`: Session com o `sessionModel` e o `lastIndex`, trocando por Tab, Shift+Tab, clique e ◂ ▸ (sessão lembrada que não existe mais: a primeira); Reboot e Shut down; a barra de teclas (`↑↓ Select`, `Enter Log in`, `Tab Session`, `Esc Clear`) e a dica à esquerda
- [X] T019 [US1] Escrever `components/ConfirmDialog.qml` e o estado `leaving`: o diálogo do menu de pausa com Cancel marcado (↑↓, Enter, Esc, a pipa); confirmado, a tela apaga, abre a faixa "Rebooting…" ou "Shutting down…" e chama `sddm.reboot()` ou `sddm.powerOff()` assim que a faixa abre (research R10)
- [X] T020 [US1] Ligar o login ao SDDM em `Main.qml`: `sddm.login(usuário escolhido ou digitado, senha, sessão)`; `onLoginFailed` → "Authentication failed." na cor de alerta, o rasgo de 0,18 cqw (7 px em 4K) por ~0,32 s no painel e o campo limpo; `onLoginSucceeded` → "Welcome, <usuário>" e a sessão. O que espelhar o Qylock leva o aviso de autoria e a GPL-3.0 no arquivo
  - Feito em `components/SddmLink.qml` (a conversa com o SDDM, com o aviso do Qylock e a GPL-3.0); o `Main.qml` só a usa.
- [X] T021 [US1] Escrever `components/Clock.qml` (`big`, `small`, `none`) com o relógio e a data do protótipo
- [X] T022 [US1] Escrever os modos `login` e `power` de `lab/check-011` e validar a US1 na `t011-login`, dentro do `lab/perf`: screenshots nos dois perfis (também pelo `sddm-greeter-qt6 --test-mode`); 10 logins certos (SC-004) e 10 errados (SC-005) entre `ana` e `bruno`; "Other user…"; a sessão trocada é a que abre; Reboot e Shut down com Cancel, Esc e confirmação (SC-009); a lista com `lab/011/users --many 20`; journal sem aviso de QML do tema
  - Evidência (frente B, 29.10): os modos `login`, `power`, `intro` e `edges` em `lab/011/check-<modo>` (ajudantes em `lab/011/greeter.sh`), no greeter de verdade (reinício do SDDM), não no `--test-mode`. 1080: login 7/0 (SC-004 10/10, SC-005 10/10, Other user, 21 usuários), power 8/0 (Cancel, Esc e clique fora sem efeito; Reboot reinicia e Shut down desliga), bordas 5/0; hidpi (2560×1600): login 3/3 e 3/3, power 8/0. Journal do greeter sem erro nem aviso de QML do tema em todas. Capturas em `~/.local/share/nier-lab/out/011-login-evidencias/`.

**Checkpoint**: o login novo funciona sozinho na VM, com o boot ainda em texto. É o MVP.

---

## Phase 4: User Story 2 - Ligar o computador e ver a lista de checagens (Priority: P1) · Frente A

**Goal**: o tema `script` do Plymouth com a lista das etapas reais, os efeitos medidos e a saída.

**Independent Test**: na `t011-boot`, com o login padrão do SDDM, `lab/bootcap t011-boot --until
login` num boot normal, num boot lento (uma unidade de teste que espera 5 s) e num boot com uma unidade
que falha; folhas de contato lado a lado com a análise 4K.

- [X] T023 [P] [US2] Escrever `system/boot/plymouth/yorha-os/gen/assets.py` (Pillow e numpy; roda no lab) e gerar em `assets/`: o ladrilho da película (malha de 14 px em 4K; célula rgb(27,24,20), vão rgb(12,7,4)), a vinheta lateral (−30 a −55 % na borda, topo −8 %, base −14 %), os anéis concêntricos das faixas (~200 px de espaçamento em 4K, em algumas alturas) e a arte da faixa de passagem (os 2 arcos de raios 442 e 487 e as 2 diagonais, espelhados); `README.md` diz como regerar
- [X] T024 [US2] Escrever `system/boot/plymouth/yorha-os/stages.tsv` com umas 30 etapas de um Arch com Hyprland: `pattern` (glob sobre o nome cru da unidade, como `systemd-journald.service` ou `dev-*.swap`; o primeiro que bate vence), `label` ("Até 48 caracteres; sem nome técnico nem texto do jogo", em inglês e **só ASCII**, porque o initramfs não desenha acento nem "…") e `group` (`services`, `volumes`, `devices`, `network`, `session`); e `gen/embed-stages.py`, que embute o catálogo no script no build (o Plymouth não lê arquivo em tempo de execução)
- [X] T025 [US2] Escrever `yorha-os.plymouth` e o núcleo de `yorha-os.script`: entrada do preto em ~1,0 s linear; o cabeçalho com texto nosso e os pontinhos em ciclo de 1,156 s (0,15 / 0,34 / 0,34 / 0,36 s); o anel claro no canto superior direito a 60 quadros/s; a película e a vinheta; o texto em rgb(223,218,210)
- [X] T026 [US2] Escrever a lista em `yorha-os.script`: `SetUpdateStatusFunction` → catálogo ou contagem por grupo; a fila (digitação ~77 letras/s, a 1ª linha ~20 letras/s; a letra da ponta sorteada da própria linha; a linha apagada só nos primeiros ~50 ms; ~0,11 s entre linhas); a linha genérica do grupo quando a fila esvazia ("Starting system services (12)"); o nome técnico cru nunca aparece; o cursor `_` piscando 0,49/0,49 s depois da última linha
- [X] T027 [US2] Escrever as faixas e a lente em `yorha-os.script`: ~7 faixas/s, 1–8 quadros, escurecendo ~12 % (até 20 %), com os anéis e o rasgo de −3,5 px no conteúdo (cortando a linha com `Image.Crop`, confirmado na T006); a cópia vermelha deslocada pela posição na tela (aberração ~0,21 %) e a cópia fraca do brilho; a cintilação de 3,5–5,4 % a cada ~1,2 s; a opção `effects=calm` tira faixas, rasgo e cintilação
- [X] T028 [US2] Escrever a saída em `yorha-os.script` e o arquivo `config`: a mensagem `yorha:exit` descarta a fila e começa o fade em degraus de ~3 quadros, 0,4 s com `exit=fast` (padrão) ou 0,9 s com `exit=game`; depois, preto. Mensagens `yorha:` desconhecidas são ignoradas; as outras viram uma linha comum
- [X] T029 [US2] Escrever `system/boot/plymouth/yorha-os/watch/yorha-boot-watch` (bash, sem dependência nova) e `yorha-boot-watch.service` (`DefaultDependencies=no`, `After=plymouth-start.service`): segue o journal do boot atrás de `JOB_RESULT=failed` e manda `plymouth display-message --text=yorha:fail:<unidade>`; para quando o `sddm.service` começa. No script, a linha da unidade passa pra falha, na cor de alerta
- [X] T030 [US2] Validar a US2 na `t011-boot`, dentro do `lab/perf`: `lab/bootcap` num boot normal, num boot lento (`lab/011/slow-unit`, uma unidade que espera 5 s: o cursor e o anel continuam) e num boot com `lab/011/fail-unit` (a linha em falha); medir os quadros/s; montar as folhas lado a lado com a análise 4K

**Checkpoint**: o boot novo funciona sozinho, terminando no login padrão do SDDM.

---

## Phase 5: Frente C - Instalar e desfazer (FR-040 a FR-042)

**Goal**: o módulo `yorha-os-boot-login`, com `install`, `uninstall` e `status`, seguindo
`contracts/install-cli.md`.

**Independent Test**: na `t011-inst`, `install` duas vezes, `status`, `uninstall` e reboot;
o boot e o login voltam ao que eram, e os hashes dos arquivos editados batem com os de antes (SC-011).

- [X] T031 [P] Escrever o esqueleto de `system/boot-login/yorha-os-boot-login`: os três comandos e o `--dry-run`; a checagem de root e de SDDM e Plymouth instalados (saída 1); o manifesto `/var/lib/yorha-os/boot-login.json` com `version`, `installed_at`, `created`, `edited` (caminho, backup, hash antes e depois), `initramfs` e `bootloader`
- [X] T032 [P] Escrever o `install`: os temas em `/usr/share/yorha-os/login` e `/usr/share/yorha-os/boot` com os links nas pastas de tema; a fonte em `/usr/share/fonts/yorha-os/` (e `fc-cache`); os drop-ins de `system/boot-login/files/` (`sddm.conf.d` só com o `Current=yorha-os`; `mkinitcpio.conf.d` com o hook depois do `kms` ou do `systemd`, a fonte vem pelo `Font=` do tema; o fallback editando o `mkinitcpio.conf` com backup); a unidade do `yorha-boot-watch`; o `/etc/yorha-os/login.conf` só se não existir, ligado como `theme.conf.user`; `plymouth-set-default-theme yorha-os`; `mkinitcpio -P` e a conferência pelo `lsinitcpio` (saída 2). "`install` duas vezes não cria um segundo backup do mesmo arquivo; vale o primeiro"
- [X] T033 [P] Escrever o `splash` no `install`: as linhas `options` de `/boot/loader/entries/*.conf` (mais o `quiet`, se faltar), com backup; o `/etc/kernel/cmdline` numa máquina com UKI, refazendo a imagem; outro bootloader: avisa, mostra o passo manual e sai com 3 depois do resto
- [X] T034 [P] Escrever o `uninstall` e o `status`: volta os backups, apaga o que criou, avisa que o `/etc/yorha-os/login.conf` ficou, refaz o initramfs e confere os hashes; "`uninstall` sem manifesto não faz nada e sai com erro" (4), e um arquivo editado que mudou depois da instalação não é sobrescrito (4, mostrando a diferença); o `status` mostra o que está instalado, o bootloader, o initramfs e se os arquivos ainda batem
- [X] T035 Escrever o modo `undo` de `lab/check-011` e validar a frente C na `t011-inst`, dentro do `lab/perf`: `--dry-run`, `install` duas vezes (idempotente), `status`, `uninstall`, reboot com `lab/bootcap` (boot em texto, login padrão) e hashes iguais aos de antes (SC-011); refazer na `arch-iso` pura (sem SDDM) pra conferir a saída 1

**Checkpoint**: o módulo instala e desfaz numa VM limpa.

---

## Phase 6: User Story 3 - Do boot pro login sem emenda, e sem nunca travar (Priority: P2) · Junção

**Goal**: a passagem do Plymouth pro SDDM, a entrada do login cancelável e o fade na volta.

**Independent Test**: com o módulo da frente C instalando os temas das frentes A e B na `teste-011`,
`lab/bootcap` do ligar até o login pronto; digitar e clicar durante a entrada; sair da sessão e voltar;
`lab/011/stress-greeter`.

- [X] T036 [US3] Juntar as frentes A, B e C na `011-boot-e-login` (merge das três branches, resolvendo conflitos) e trocar o `lab/011/install-dev` pelo módulo em todas as checagens
- [X] T037 [US3] Escrever `system/boot-login/files/sddm.service.d/yorha-os.conf` com a **tentativa 3 da sondagem** (`sondagem.md`): `Conflicts=plymouth-quit.service`, `After=plymouth-start.service`, `OnFailure=plymouth-quit.service`; `ExecStartPre` que manda `yorha:exit`, grava `/run/yorha-os/handoff` (o `/proc/uptime` da passagem), espera a saída (0,4 s ou 0,9 s, conforme o `config` do tema de boot), limpa o tty1 e esconde o cursor dele (`setterm --cursor off --clear all > /dev/tty1`) e chama `plymouth quit` **sem** `--retain-splash` (com ele, o X trava no VT 2). Em `sddm.conf.d/yorha-os.conf`: `Current=yorha-os` e o `GreeterEnvironment` que deixa o greeter ler `/run/yorha-os/handoff` e `/proc/uptime`
- [X] T038 [US3] Escrever a entrada no greeter (`components/Bridge.qml`, `components/GlitchTitle.qml` e o estado `intro`): preto, a faixa "Loading user data…" abrindo e fechando como uma linha de CRT, o nome embaralhado (16 passos de 50 ms, a separação vermelha e ciano), o papel e os painéis subindo, em ~3,8 s; o campo recebe teclas desde o primeiro quadro; tecla, Enter ou clique cortam a entrada mantendo o que foi digitado, e o Enter com o campo vazio só corta (FR-018)
- [X] T039 [US3] Decidir entre entrada completa e fade no greeter: entrada completa só no primeiro greeter depois do boot (o `/run/yorha-os/handoff` existe e tem menos de 30 s em relação ao `/proc/uptime`); senão, só o fade (logout e troca de usuário, FR-019); `intro=fade`, `intro=none` e `reduceMotion=true` (sem glitch, rasgo, respiração nem varredura) valem em qualquer caso
  - A marca vale uma vez só: o greeter guarda a última que usou no cache do usuário `sddm` (`~/.cache/yorha-os/greeter.conf`), então um logout antes dos 30 s também volta com fade. Precisa de `QML_XHR_ALLOW_FILE_READ=1` no `GreeterEnvironment` (T037); sem ele o Qt avisa no log e a entrada cai no fade. `lab/check-011 intro`: 13/0 em 1080 e em hidpi.
- [X] T040 [US3] Escrever `lab/011/stress-greeter <vm> --sequences 20`: as 20 sequências de teclas e cliques pelo `lab/key` (digitar durante a entrada, trocar de usuário no meio da varredura, abrir o diálogo durante o rasgo, Enter duplo, senha errada seguida de certa…), conferindo em cada uma o último `yorha-login: state=` do journal e a captura final
- [X] T041 [US3] Validar a US3 na `teste-011`, dentro do `lab/perf`: `lab/bootcap --until login` sem console nem quadro branco (SC-001); o tempo do ligar ao login com e sem o tema, no máximo +0,5 s (SC-002); digitar a senha durante a entrada e apertar Enter: a entrada some em até 1 quadro e a sessão abre (SC-003); o clique corta; logout volta com fade; o estresse passa nas 20 sequências (SC-006)

**Checkpoint**: boot e login emendam, e a entrada nunca trava.

---

## Phase 7: User Story 5 - Desligar e reiniciar com a mesma cara (Priority: P3) · Frente A

**Goal**: a faixa "Shutting down…" ou "Rebooting…" no desligamento, por qualquer caminho.

**Independent Test**: na `t011-boot`, desligar e reiniciar pelo login, por `systemctl poweroff` e por
`systemctl reboot`, com `lab/bootcap --until off`; nenhuma captura com console.

- [X] T042 [US5] Escrever o modo de desligamento em `yorha-os.script`: com `Plymouth.GetMode()` = `shutdown` ou `reboot` (ou o equivalente que a T006 achar), só a tela escura com a faixa de passagem dizendo "Shutting down…" ou "Rebooting…", sem lista e sem texto de console (FR-030a)
- [X] T043 [US5] Validar a US5 na `t011-boot`, dentro do `lab/perf`: os três caminhos com `lab/bootcap --until off`; do login, a faixa do greeter emenda na do Plymouth

---

## Phase 8: User Story 4 - Senha do disco no boot (Priority: P3) · por último

**Goal**: o pedido da senha do disco no estilo do login, sem nunca quebrar o pedido.

**Independent Test**: numa VM com disco criptografado, `lab/bootcap --until password`; errar uma vez,
acertar e seguir até o login.

- [ ] T044 [US4] Escrever `lab/011/archinstall-luks.json` (a configuração padrão do lab com LUKS no `@`) e criar as camadas `arch-iso-luks` e a equivalente da `boot-iso` (com `lab/011/provision-boot-iso --from arch-iso-luks`); documentar em `lab/README.md`
- [ ] T045 [US4] Escrever o modo senha em `yorha-os.script`: `SetDisplayPasswordFunction(prompt, bullets)` e `SetDisplayNormalFunction`, com o campo do login (um quadradinho por caractere, os antigos saindo sob o "…", o erro e o campo limpo); sem o tema ativo, o pedido padrão continua (FR-030)
- [ ] T046 [US4] Validar a US4 na VM com LUKS, dentro do `lab/perf`: o pedido no estilo do login, a senha errada uma vez, a certa e o boot seguindo até o login

---

## Phase 9: Polish & Cross-Cutting

**Purpose**: as checagens de robustez, os créditos e a revisão do dono.

- [ ] T047 Escrever os modos `journal` e `fallback` de `lab/check-011` e rodar o `lab/check-011` completo na `teste-011` nos dois perfis, dentro do `lab/perf`: 10 ciclos de boot, login e saída sem aviso de QML nem erro dos temas (SC-007); o tema quebrado de propósito (o `Main.qml` renomeado) deixa o login padrão do SDDM entrar (SC-008); `ds-sync` passa
- [ ] T048 [P] Conferir os créditos: o aviso do Qylock e a GPL-3.0 nos arquivos que espelham a conversa com o SDDM; `CREDITS.md` com o Qylock, o anel (MIT) e a fonte (OFL); o Qylock na lista "Inspirações" do `README.md` (layout); nada do jogo em `system/`
- [ ] T049 Escrever `specs/011-boot-e-login/relatorio.md` (o que foi feito, os relatórios do `lab/perf`, os totais do `lab/check-011`) e montar a página de revisão do dono: o login nos dois perfis, a folha do boot lado a lado com a análise 4K, a passagem e o desligamento (SC-010)
- [ ] T050 Atualizar o status da U5a em `PLAN.md`, o mapa do projeto e a Central, e anotar a tarefa de depois: juntar as peças do design system do login e do shell num núcleo sem Quickshell, depois do merge da 008 e da 010 (research R3)

---

## Dependencies & Execution Order

- **Setup (T001–T007):** sequencial na `teste-011`, com a T003 e a T004 em paralelo. A T006 (sondagem)
  pode mudar as decisões R6–R8; as frentes só começam depois dela.
- **Foundational (T008–T010):** depois do setup; bloqueia as frentes.
- **Frentes em paralelo (depois da T010):**
  - **A:** US2 (T023–T030), depois US5 (T042–T043);
  - **B:** US1 (T011–T022);
  - **C:** instalação (T031–T035).
- **Junção (US3, T036–T041):** depois de A (até a T030), B e C.
- **US4 (T044–T046):** por último, depois da junção.
- **Polish (T047–T050):** depois de tudo.

### Dentro de cada frente

- **B:** as cópias do design system (T011, T012) e a máquina de estados (T013) antes da tela (T014–T021);
  a validação (T022) por último.
- **A:** as imagens (T023) e o catálogo (T024) antes do script (T025–T029); a validação (T030) por
  último.
- **C:** o esqueleto (T031) antes do resto; a validação (T035) por último.

## Parallel Example

```text
Depois da T010, três agentes ao mesmo tempo (três VMs, abaixo do limite de quatro):

Agente A (impl011-boot, t011-boot):      T023 → T024 → T025 → … → T030 → T042 → T043
Agente B (impl011-login, t011-login):    T011 + T012 → T013 → T014 → … → T022
Agente C (impl011-instalar, t011-inst): T031 → T032 + T033 + T034 → T035
```

## Implementation Strategy

1. **MVP:** setup, fundação e a US1 (frente B). O login novo funciona na VM com o boot em texto.
2. **Incremento 1:** a US2 (frente A) traz o boot novo, que já termina no login padrão do SDDM.
3. **Incremento 2:** a frente C e a junção (US3) emendam tudo e trocam a instalação de laboratório
   pelo módulo.
4. **Incremento 3:** a US5 (desligar) e a US4 (senha do disco).
5. **Fecho:** robustez, créditos e a revisão do dono.

Os agentes só disparam com o OK do dono, e cada frente reporta com as capturas e os relatórios do
`lab/perf`.
