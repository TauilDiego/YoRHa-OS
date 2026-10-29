# Módulo de boot e login: `yorha-os-boot-login`

Instala, confere e desfaz o tema de boot e o tema de login (spec 011, `contracts/install-cli.md`):
`install`, `uninstall` e `status`, como root. Faz backup de tudo que edita (as entradas do
systemd-boot) e cria só drop-ins com nome próprio. O instalador da camada visual chama este módulo.

- `files/`: os drop-ins (`sddm.conf.d`, `sddm.service.d`, `mkinitcpio.conf.d`) e o `login.conf` de
  exemplo.

**Testar:** numa VM do lab, nunca na máquina do dono (constituição, princípio I).
