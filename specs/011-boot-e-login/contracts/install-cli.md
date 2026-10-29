# Contrato: `yorha-os-boot-login`

O módulo que instala, confere e desfaz o boot e o login (research R14). Roda como root. O instalador
da camada visual (futuro) chama este módulo.

## Comandos

| Comando | O que faz |
|---|---|
| `install [--dry-run]` | Instala os temas e a fonte, cria os drop-ins, liga as opções do usuário, ativa o Plymouth (hook e `splash`), refaz o initramfs e confere. Com `--dry-run`, só lista o que faria |
| `uninstall [--dry-run]` | Volta os backups, apaga o que criou, refaz o initramfs e confere os hashes |
| `status` | Mostra o que está instalado, o bootloader detectado, se o initramfs tem o tema e se os arquivos editados ainda batem com o manifesto |

## Saídas

| Código | Quando |
|---|---|
| 0 | Deu certo (ou nada a fazer) |
| 1 | Pré-condição: não é root, falta o SDDM ou o Plymouth instalados |
| 2 | Falha ao refazer ou conferir o initramfs (os backups ficam; o `uninstall` desfaz) |
| 3 | Bootloader não suportado: o resto foi instalado, e o passo manual aparece na tela |
| 4 | `uninstall` sem manifesto, ou um arquivo editado mudou depois da instalação (não sobrescreve; mostra a diferença) |

## O que ele cria

- `/usr/share/yorha-os/login/` e `/usr/share/yorha-os/boot/`, com os links nas pastas de tema do
  SDDM e do Plymouth;
- `/usr/share/fonts/yorha-os/` (M PLUS 1, OFL);
- `/etc/sddm.conf.d/yorha-os.conf`: `Current=yorha-os` (o SDDM já passa `-background none` pro X);
- `/etc/systemd/system/sddm.service.d/yorha-os.conf`: a passagem do Plymouth (research R8);
- `/etc/systemd/system/yorha-boot-watch.service` e o script dele (research R7);
- `/etc/mkinitcpio.conf.d/yorha-os.conf`: o hook `plymouth` (a fonte vem pelo `Font=` do tema; research R12);
- `/etc/yorha-os/login.conf`, só se ainda não existir (é do usuário; nunca é sobrescrito);
- `/var/lib/yorha-os/boot-login.json` (o manifesto) e `/var/lib/yorha-os/backup/<data>/`.

## O que ele edita (com backup)

- as entradas do systemd-boot (`/boot/loader/entries/*.conf`, linha `options`), ou o
  `/etc/kernel/cmdline` numa máquina com UKI (research R13);
- o `/etc/mkinitcpio.conf`, só no fallback de um mkinitcpio sem drop-ins.

O `uninstall` não apaga o `/etc/yorha-os/login.conf`, porque é do usuário. Ele avisa que o arquivo
ficou.
