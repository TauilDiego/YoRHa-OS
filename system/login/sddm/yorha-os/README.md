# Tema de login (SDDM): `yorha-os`

A tela de login do YoRHa-OS (spec 011), do protótipo aprovado (artefato "YoRHa-OS Login: proposta",
v3.2): o papel da cena "Menu" com as réguas do shell, a lista de usuários, o relógio, o cartão de
autenticação, Session, Reboot e Shut down, e a entrada depois do boot. Qt 6, greeter em X11.

- `metadata.desktop`, `theme.conf` (os padrões) e `Main.qml`.
- `components/`: as partes da tela e a máquina de estados das animações.
- `ds/`: cópias adaptadas, sem Quickshell, das peças do design system do shell. Os números precisam
  bater com os do shell: `lab/check-011 ds-sync`.
- `assets/ring/`: o anel de carregamento, tinta sobre papel (`lab/011/ring-frames`).

As opções do usuário ficam em `/etc/yorha-os/login.conf`, que o instalador liga como
`theme.conf.user`.

**Testar sem reiniciar:** `sddm-greeter-qt6 --test-mode --theme <esta pasta>` dentro da VM.
