# Tema de login (SDDM): `yorha-os`

A tela de login do YoRHa-OS (spec 011), do protótipo aprovado (artefato "YoRHa-OS Login: proposta",
v3.2): o papel da cena "Menu" com as réguas do shell, a lista de usuários, o relógio, o cartão de
autenticação, Session, Reboot e Shut down, e a entrada depois do boot. Qt 6, greeter em X11.

- `metadata.desktop`, `theme.conf` (os padrões) e `Main.qml` (a tela; o SDDM carrega uma por monitor,
  e os painéis só vão no principal).
- `components/`: as partes da tela. `GreeterState.qml` é a máquina de estados que manda em todas as
  animações (`intro`, `ready`, `checking`, `welcome`, `leaving`). `SddmLink.qml` é a conversa com o
  SDDM, no jeito do Qylock (Darkkal44, GPL-3.0; o aviso está no arquivo).
- `ds/`: cópias adaptadas, sem Quickshell, das peças do design system do shell. Os números precisam
  bater com os do shell: `lab/check-011 ds-sync`.
- `assets/ring/`: o anel de carregamento, tinta sobre papel (`lab/011/ring-frames`).

## Opções

No `theme.conf` (o padrão primeiro): `intro` = `full` | `fade` | `none`, `clock` = `big` | `small` |
`none`, `userList` = `always` | `auto`, `reduceMotion` = `false` | `true`. As do usuário ficam em
`/etc/yorha-os/login.conf`, que o instalador liga como `theme.conf.user`. Um valor inválido vale o padrão
e gera um aviso no log, uma vez.

## A entrada depois do boot

A entrada completa (faixa, nome com glitch, papel) só toca no primeiro greeter depois do boot: quando
`/run/yorha-os/handoff` (o `/proc/uptime` da passagem, gravado pelo drop-in do `sddm.service`) tem menos
de 30 s. Senão, e depois de um logout, é o fade. Pra ler esses dois arquivos, o greeter precisa de
`QML_XHR_ALLOW_FILE_READ=1` no `GreeterEnvironment` do SDDM (o drop-in `sddm.conf.d` do módulo).

## Log

O greeter do SDDM 0.21 escreve no journal, com o identificador `sddm-greeter-qt6`:
`journalctl -b -t sddm-greeter-qt6`. O tema escreve `yorha-login: state=<estado>` a cada troca de
estado, `yorha-login: intro=<full|fade>` na entrada e `yorha-login: option <chave>=<valor> invalid,
using <padrão>` pra uma opção inválida. Se o tema não carregar, o SDDM escreve "Fallback to embedded
theme" e mostra o tema padrão dele.

## Testar no lab

`lab/011/install-dev <vm> --no-boot --login <esta pasta>` e `sudo systemctl restart sddm` na VM; depois
`lab/check-011 login`, `power` e `intro` (no `lab/README.md` privado).
