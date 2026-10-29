# Módulo de boot e login: `yorha-os-boot-login`

Instala, confere e desfaz o tema de boot (Plymouth) e o tema de login (SDDM) da spec 011, seguindo
`specs/011-boot-e-login/contracts/install-cli.md`. Roda como root. O instalador da camada visual
(futuro) chama este módulo.

```sh
sudo system/boot-login/yorha-os-boot-login install [--dry-run] [--src <raiz>]
sudo system/boot-login/yorha-os-boot-login uninstall [--dry-run]
sudo system/boot-login/yorha-os-boot-login status
```

- `--dry-run`: só lista o que faria, com o diff de cada arquivo que seria editado.
- `--src <raiz>`: de onde vêm os temas, a fonte e os drop-ins, numa árvore com o mesmo desenho do
  repositório (`system/login/sddm/yorha-os`, `system/boot/plymouth/yorha-os`, `shell/assets/fonts`,
  `system/boot-login/files`). O padrão é `YORHA_OS_SRC` ou o próprio repositório onde o módulo está.

**Saídas:** 0 deu certo (ou nada a fazer); 1 pré-condição (não é root; falta SDDM, Plymouth ou
mkinitcpio; falta um tema na origem) ou erro inesperado; 2 o initramfs não foi refeito ou não tem o
tema (os backups ficam, o `uninstall` desfaz); 3 bootloader não suportado (o resto é instalado e o
passo manual aparece); 4 `uninstall` sem manifesto, ou um arquivo editado mudou depois da instalação
(fica como está, e a diferença aparece). O `status` usa os mesmos códigos.

## O que ele cria (gerenciado: trocado a cada `install`, apagado no `uninstall`)

- `/usr/share/yorha-os/login/`, com o link `/usr/share/sddm/themes/yorha-os` apontando pra ela, e
  `/usr/share/yorha-os/boot/`;
- `/usr/share/plymouth/themes/yorha-os/`: **uma cópia** de `/usr/share/yorha-os/boot`, não um link.
  O hook `plymouth` do mkinitcpio 42 copia o tema com `add_full_dir`, e o `add_file` muda pro caminho
  real todo arquivo cuja pasta-mãe é um link: com o link, a imagem fica sem
  `themes/yorha-os/yorha-os.plymouth` e o tema não sobe (visto no lab);
- `/usr/share/fonts/yorha-os/` (M PLUS 1, OFL), com `fc-cache`;
- os drop-ins de `files/`: `/etc/sddm.conf.d/yorha-os.conf` (`Current=yorha-os`),
  `/etc/mkinitcpio.conf.d/yorha-os.conf` (o hook `plymouth` depois do `kms`, ou do `udev`/`systemd`) e,
  se existirem, os `files/sddm.service.d/*.conf` em `/etc/systemd/system/sddm.service.d/`;
- as unidades `system/boot/plymouth/yorha-os/watch/*.service` em `/etc/systemd/system/`, habilitadas.
  O script delas fica em `/usr/share/yorha-os/boot/watch/` (o `ExecStart` aponta pra lá);
- `/etc/yorha-os/login.conf`, a partir de `files/login.conf`, **só se ainda não existir**, ligado
  como `theme.conf.user` do tema. É do usuário: o módulo nunca sobrescreve nem apaga;
- `/var/lib/yorha-os/boot-login.json` (o manifesto) e `/var/lib/yorha-os/backup/<data>/`.

Um arquivo que já estava num caminho gerenciado e não é do módulo vai pro backup (`displaced/`) e
volta no `uninstall`.

## O que ele edita (com backup e os dois hashes no manifesto)

- as entradas do systemd-boot com `linux` (linha `options`: `quiet` e `splash`, se faltarem), ou o
  `/etc/kernel/cmdline` numa máquina com UKI;
- o `/etc/plymouth/plymouthd.conf` (o tema), pelo próprio `plymouth-set-default-theme` rodando numa
  cópia;
- o `/etc/mkinitcpio.conf`, só num mkinitcpio sem drop-ins.

O primeiro backup é o que vale: `install` de novo não faz outro. O `uninstall` volta cada arquivo e
confere o hash de antes. Se o arquivo mudou depois da instalação, ele fica como está, a diferença
aparece e o manifesto guarda só ele; o resto é desfeito, e um novo `uninstall` termina depois que o
arquivo for resolvido. No fim, o manifesto vai pra pasta do backup.

## Testar

Numa VM do lab, nunca na máquina do dono (constituição, princípio I): `lab/check-011 undo <vm>` no
repositório privado (dry-run, `install` duas vezes, `status`, boot com e sem o tema pelo
`lab/bootcap`, `uninstall` com os hashes de antes, e as saídas 1 a 4).

Pra testar um caminho que a VM não tem: `YORHA_OS_BOOTLOADER=systemd-boot|uki|other` força o
bootloader, e `YORHA_OS_MKINITCPIO_DROPINS=0` força a edição do `/etc/mkinitcpio.conf`.
