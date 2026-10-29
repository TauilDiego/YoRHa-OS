# Research: Boot e login (011)

Decisões técnicas do plano. Cada uma diz o que foi escolhido, por quê e o que ficou de fora. As que
dependem de um comportamento que só a VM confirma têm uma verificação na tarefa de sondagem (R0).

## R0. Uma sondagem no lab antes de tudo

**Decisão:** a primeira tarefa depois das ferramentas do lab é uma sondagem curta na VM, que confirma
seis coisas de que o plano depende:
1. o systemd manda o nome de cada unidade pro Plymouth (`SetUpdateStatusFunction`);
2. o script do Plymouth tem `Image.Crop` (pro rasgo cortar uma linha no meio, R6);
3. o script segura ~100 sprites a 25 quadros/s ou mais na VM;
4. a fonte M PLUS 1 chega no initramfs e o `Image.Text` desenha com ela;
5. o `Plymouth.GetMode()` devolve `shutdown` e `reboot` no desligar;
6. a passagem pro SDDM (R8) não mostra console.

**Por quê:** essas seis coisas decidem detalhes do tema de boot e são baratas de testar (uma VM, um
tema mínimo). O que falhar muda só a decisão correspondente abaixo, que já traz o plano B.

## R1. O login é um tema QML do SDDM, com o greeter em X11

**Decisão:** um tema do SDDM em Qt 6 (`QtVersion=6` no `metadata.desktop`), rodando no greeter
padrão em X11. O servidor X sobe com `-background none`, pra o último quadro do boot ficar na tela até
o greeter desenhar o primeiro.

**Por quê:** o dono aprovou o caminho do SDDM com o layout do Qylock, e o PLAN deixava a escolha pra
spec. O greeter em X11 é o padrão do SDDM no Arch, e a passagem do Plymouth pro X com
`-background none` é conhecida.

**Alternativas:**
- greeter em Wayland (com weston ou kwin): mais dependências e a passagem do Plymouth é menos
  testada. Fica pra depois, como opção;
- greeter próprio em Quickshell: o dono aprovou o SDDM, e um greeter próprio exige cuidar da
  autenticação e da sessão, que o SDDM já faz.

## R2. Do Qylock, só o jeito de conversar com o SDDM

**Decisão:** o tema fala com a API padrão do SDDM, como o Qylock faz:
- `userModel` (com `lastIndex`) e `sessionModel` (com `lastIndex`);
- `sddm.login(usuário, senha, sessão)`, `sddm.reboot()`, `sddm.powerOff()`;
- `Connections` com `onLoginFailed` e `onLoginSucceeded`;
- `keyboard` (Caps Lock) e `primaryScreen`.

O desenho é todo nosso. O que espelhar o código do Qylock (o fluxo de login e o tratamento do último
usuário) leva o aviso de autoria e a licença GPL-3.0 no arquivo, e entra no `CREDITS.md` (FR-038). A
GPL-3.0 pode ser combinada com a AGPL-3.0 do projeto (GPLv3 §13).

**Fora:** o tema "nier_automata" do Qylock usa GIFs e imagens do jogo e o `Qt5Compat.GraphicalEffects`.
Nada disso entra.

## R3. As peças do design system entram no tema como cópias adaptadas

**Decisão:** o tema traz as suas versões, sem Quickshell, de:
- `Rule`, `PaperDecor` e `Vignette` (as réguas e o fundo);
- `Selector` e `ListItem` (a pipa e a varredura);
- `Label` e um pedaço dos `Tokens`.

Elas ficam em `system/login/sddm/yorha-os/ds/`. Cada arquivo diz de qual arquivo do shell veio, e uma
checagem do lab compara os números que precisam bater (cores, período de 77 px, tamanhos da pipa,
tempos de 150 e 240 ms).

**Por quê:** o greeter do SDDM não tem os tipos do Quickshell (`QsWindow`, `Quickshell`), que as
peças do shell usam pra saber a escala do monitor. A troca é pelo `Screen.devicePixelRatio` do Qt.

**Alternativa adiada:** tirar do shell um núcleo sem Quickshell e importar nos dois. É o caminho
certo pra quando houver uma terceira tela (a de bloqueio, U5), mas agora mexeria em arquivos que a 008
e a 010 também mudam, ainda fora da `main`. Fica como tarefa de depois do merge das duas.

## R4. O glitch do login é o do protótipo, em QML, sem shader

**Decisão:** o nome embaralhado (letras sorteadas, deslocamento e inclinação aleatórios, piscadas),
a separação de cores (duas cópias do texto, vermelha e ciano, deslocadas) e o rasgo de 7 px (em 4K)
são feitos em QML e JavaScript, como no protótipo aprovado (v3.2).

**Por quê:** é o que o dono aprovou, e não depende do `qsb` nem de shader compilado na máquina.

**Alternativa:** um shader de glitch, como os do shell (`shell/shaders`). Fica pra depois, se o dono
quiser mais dos efeitos do jogo (fatias, pixelização).

## R5. Uma máquina de estados manda em todas as animações do login

**Decisão:** o greeter tem um estado só: `intro`, `ready`, `checking`, `welcome`, `leaving` ou `off`.
Cada estado é dono das suas animações e temporizadores. Entrar num estado para tudo do anterior antes
de começar (o `stopIntro()` do protótipo, generalizado). As transições permitidas estão no
`data-model.md`. Cada troca de estado vai pro log (`yorha-login: state=<estado>`).

**Por quê:** são as duas regras do dono (FR-018, FR-020): uma animação nunca roda por cima de outra, e
logar cedo corta a entrada. Com um dono só pros temporizadores, não sobra animação órfã. O log deixa o
teste de estresse (SC-006) conferir o estado final sem depender só de screenshot.

## R6. O boot é um tema `script` do Plymouth, com os efeitos pesados preparados antes

**Decisão:** o plugin `script` do Plymouth, o único que deixa programar o desenho a cada quadro
(digitar linhas, sortear letras, mover faixas). O que precisaria de processamento por pixel vira
imagem preparada no build:
- a película (um ladrilho da malha de 14 px em 4K, repetido);
- a vinheta lateral (uma imagem com alfa, esticada);
- os anéis das faixas de interferência (algumas alturas prontas);
- a arte da faixa de passagem (os arcos e as diagonais das pontas);
- o anel de carregamento, em quadros (R11).

O texto sai do `Image.Text` com a fonte M PLUS 1. A aberração só no vermelho vira uma cópia vermelha
de cada linha, deslocada conforme a posição dela na tela (uns +1,3 px na esquerda e −1,5 px na
direita, em 1080p). O brilho é uma segunda cópia fraca.

O rasgo desloca o conteúdo dentro da faixa. Com o `Image.Crop` (R0, item 2), a faixa corta uma linha
no meio, como no jogo. Sem ele, as linhas inteiras dentro da faixa é que se deslocam. A diferença
aparece na revisão visual do dono (SC-010).

**Alternativas:**
- plugin `two-step`: só toca sequências de imagens num layout fixo, então não digita linhas reais;
- vídeo ou sequência pré-gravada: não mostra as etapas reais do boot.

## R7. As linhas vêm das unidades do systemd, com nomes nossos

**Decisão:** o systemd avisa o Plymouth a cada unidade que começa. O script recebe o nome pelo
`SetUpdateStatusFunction` e procura no catálogo (`stages.tsv`: o padrão do nome da unidade, o texto
nosso e o grupo).

A fila de linhas segue três regras:
- as unidades do catálogo entram em ordem;
- as que não estão no catálogo são contadas por grupo e viram uma linha genérica ("Starting system
  services (12)") quando a fila esvazia;
- o nome técnico cru nunca aparece.

As falhas não chegam por esse canal. Um ajudante pequeno (`yorha-boot-watch`, em bash, sem
dependência nova) acompanha o journal do boot atrás de `JOB_RESULT=failed` e avisa o script com
`plymouth display-message --text=yorha:fail:<unidade>`. A linha dessa unidade passa pra falha, na cor de
alerta (FR-025). O ajudante para sozinho quando o SDDM sobe.

**Alternativa:** ler o console do boot. Foi descartada: o Plymouth não recebe o console nesse modo, e
o `quiet` esconde as mensagens.

## R8. A passagem do boot pro login

**Decisão:** um drop-in do `sddm.service` muda a ordem e faz a passagem, no estilo do GDM:
1. `Conflicts=plymouth-quit.service` e `After=plymouth-start.service`, pro Plymouth não sair antes da
   hora (o `sddm.service` do Arch espera o `plymouth-quit.service`, e é aí que o console pisca);
2. `ExecStartPre`: avisa o script (`yorha:exit`), que começa a saída da lista;
3. `ExecStartPre`: espera o tempo da saída (R9) e chama `plymouth deactivate`;
4. o X sobe com `-background none`, então o último quadro (preto) fica na tela;
5. `ExecStartPost`: `plymouth quit --retain-splash` depois que o greeter desenhou. Um limite de
   segurança garante que o Plymouth sai mesmo se o greeter não subir.

O greeter começa no preto, com a faixa "Loading user data…" (FR-017). Pra quem olha, a faixa liga a
lista ao login.

**Verificação:** SC-001 (nenhuma captura com console) e R0, item 6.

## R9. A saída da lista fica em 0,4 s por padrão, com a do jogo como opção

**Decisão:** a análise mediu a saída da lista do jogo em 0,9 s. Aqui, essa espera fica no caminho do
boot (R8, passo 3), e o SC-002 dá no máximo 0,5 s de atraso pro tema todo. Por isso a saída padrão é
de 0,4 s, nos mesmos degraus. A do jogo (0,9 s) fica como opção do tema de boot (`exit=game`), com o
custo anotado.

**Por quê:** a regra do dono de fazer as alternativas virarem opção, com a recomendação como padrão, e
a regra de que o tema nunca atrasa o boot (FR-026).

**Ponto pro dono:** é a única mudança em relação aos números aprovados. Está entre as decisões do
plano.

## R10. Desligar, reiniciar e a senha do disco

**Decisão:**
- **Desligar e reiniciar (US5):** o Plymouth já assume a tela no desligamento
  (`plymouth-poweroff.service` e `plymouth-reboot.service`). O script vê o modo pelo
  `Plymouth.GetMode()` e desenha só a tela escura com a faixa, "Shutting down…" ou "Rebooting…". No
  login, o greeter mostra a mesma faixa e chama `sddm.reboot()` ou `sddm.powerOff()` assim que ela
  abre. Assim a faixa do greeter emenda na do Plymouth, sem espera extra.
- **Senha do disco (US4):** `SetDisplayPasswordFunction` e `SetDisplayNormalFunction` desenham o
  campo no estilo do login (quadradinhos, "…", erro). O teste precisa de uma VM com disco
  criptografado: uma configuração `archinstall` com LUKS no lab, numa camada própria
  (`arch-iso-luks`). Fica por último, por ser P3.

## R11. O anel de carregamento sai do gerador do cursor

**Decisão:** o gerador do tema de cursor (`system/cursors/yorha-cursors/gen/fam_loading.py`) ganha uma
saída de quadros PNG, numa paleta e num tamanho escolhidos. Ela gera duas variantes: a clara sobre
escuro (Plymouth) e a tinta sobre papel (o login, enquanto confere a senha). São os mesmos 90 quadros a
60 quadros/s.

**Relação com a 010 (item D):** a 010 faz o componente compartilhado do shell e as variantes. Esta
spec só acrescenta a saída de quadros, que a 010 também vai usar. Quem chegar primeiro faz, e a outra
reaproveita.

## R12. A fonte e o Plymouth no initramfs

**Decisão:**
- **A fonte:** a M PLUS 1 (OFL) vai pra `/usr/share/fonts/yorha-os/`, e um drop-in do mkinitcpio
  (`/etc/mkinitcpio.conf.d/yorha-os.conf`) acrescenta os arquivos dela.
- **O hook:** o mesmo drop-in põe o hook `plymouth` logo depois do `kms`, ou do `systemd` no initramfs
  baseado em systemd. Ele muda a lista de hooks do próprio arquivo do usuário, sem reescrevê-la.
- **Fallback:** se o mkinitcpio não ler drop-ins (versão antiga), o instalador edita o
  `/etc/mkinitcpio.conf` com backup.

O instalador refaz a imagem (`mkinitcpio -P`) e confere que ela tem o tema, a fonte e o hook
(`lsinitcpio`).

## R13. O parâmetro `splash` do kernel

**Decisão:** o instalador acrescenta `splash` (e `quiet`, se faltar) nas linhas `options` das entradas
do systemd-boot (`/boot/loader/entries/*.conf`), ou no `/etc/kernel/cmdline` quando a máquina usa
imagem unificada (UKI), refazendo a imagem.

Em qualquer outro bootloader, ele não mexe: avisa e mostra o passo manual. O resto da instalação
continua (FR-041 cobre o systemd-boot; o resto é melhor esforço).

## R14. Instalar e desfazer: um módulo com três comandos

**Decisão:** ainda não existe instalador da camada visual (a 005 escolheu o método D, mas não
implementou). Esta spec traz um módulo pequeno, `system/boot-login/yorha-os-boot-login`, com três
comandos: `install`, `uninstall` e `status` (contrato em `contracts/install-cli.md`). O instalador
futuro chama esse módulo.

Ele segue a constituição (III):
- **Pastas gerenciadas:** os temas e a fonte ficam em `/usr/share/yorha-os/`. O SDDM e o Plymouth
  chegam neles por links nas pastas de tema.
- **Arquivos de sistema:** os que o módulo cria são drop-ins com nome próprio (`sddm.conf.d`,
  `sddm.service.d`, `mkinitcpio.conf.d`). Os que ele edita (entradas do bootloader e, no fallback, o
  `mkinitcpio.conf`) têm backup em `/var/lib/yorha-os/backup/<data>/`, com um manifesto e o hash de
  cada arquivo.
- **Idempotência:** rodar `install` duas vezes dá o mesmo resultado.
- **Desfazer:** o `uninstall` volta os backups, apaga o que criou, refaz a imagem e confere os
  hashes (SC-011).

## R15. As opções do login ficam fora da pasta gerenciada

**Decisão:**
- **Os padrões:** ficam no `theme.conf` do tema (gerenciado).
- **A sobrescrita do usuário:** fica em `/etc/yorha-os/login.conf`. O instalador liga esse arquivo
  como `theme.conf.user` do tema, que o SDDM lê por cima do `theme.conf`. Update nunca mexe nesse
  arquivo (FR-033).
- **Ligar ao "Reduce motion" do System Settings:** fica pra depois. O login roda antes da sessão, e
  escrever em `/etc` a partir da sessão pede uma ação de polkit (a fase U5 trata do polkit).

## R16. Como testar no lab

**Decisão:** uma camada nova de VM e ferramentas novas no lab, numa branch própria (`lab-011` no
repositório privado):
- **Camada `boot-iso`:** a `hypr-iso` sem o login automático, com o SDDM e o Plymouth instalados.
- **Usuários de teste:** `lab/011/users`, com dois usuários de teste e senha de teste, mais o modo
  com 20 usuários. As senhas só existem na VM.
- **Captura do boot:** `lab/bootcap`, com a VM em `--soft` e o `screendump` do QMP a cada 0,25 s,
  do ligar até o login, gerando a folha de contato com o ImageMagick. É a técnica do estudo do boot,
  agora num comando.
- **Iteração rápida da tela:** o `sddm-greeter-qt6 --test-mode --theme <pasta>` dentro da sessão da
  VM de desenvolvimento, sem reiniciar, com o `lab/shot`.
- **Estresse:** `lab/011/stress-greeter` manda as 20 sequências de teclas e cliques (SC-006) pelo
  `lab/key` e confere o estado no log do greeter (R5).
- **Conferência:** `lab/check-011` junta os critérios que dão pra automatizar (SC-001 a SC-009 e
  SC-011) e roda dentro do `lab/perf`.

**Limites do lab respeitados:** no máximo quatro VMs ao mesmo tempo, com 4 CPUs e 4 GB cada.
