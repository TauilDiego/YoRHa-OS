# Contrato: configuração do archinstall e disco `cidata`

Formatos do **archinstall 4.5** (o da ISO 2026.10.01; research R3). Os arquivos ficam no laboratório
privado:

```
rien-OS-private/lab/iso/
├── archinstall.json     # configuração padrão (sem disk_config: o lab gera)
├── user-data            # modelo do cloud-init (a chave pública entra na hora)
└── check-arch-iso       # as conferências do passo 9, rodadas no sistema instalado
```

Nenhum deles tem segredo. As credenciais são geradas a cada execução e nunca são versionadas.

## Configuração padrão (`lab/iso/archinstall.json`)

O bloco marcado `custom_commands` + `packages` + `services` + `hostname` é a lista das **adaptações do
laboratório** (FR-014, research R6). Todo o resto é o que um usuário escolheria.

```json
{
  "version": "4.5",
  "script": "guided",
  "archinstall-language": "English",
  "locale_config": { "kb_layout": "us", "sys_enc": "UTF-8", "sys_lang": "en_US" },
  "timezone": "UTC",
  "ntp": true,
  "kernels": ["linux"],
  "bootloader_config": { "bootloader": "Systemd-boot", "uki": false, "removable": false },
  "swap": { "enabled": true, "algorithm": "zstd" },
  "network_config": { "type": "nm" },
  "profile_config": { "profile": { "main": "Minimal" }, "gfx_driver": null, "greeter": null },
  "mirror_config": {
    "custom_servers": [{ "url": "https://geo.mirror.pkgbuild.com/$repo/os/$arch" }],
    "mirror_regions": {},
    "optional_repositories": [],
    "custom_repositories": []
  },
  "pacman_config": { "color": false, "parallel_downloads": 5 },

  "hostname": "nier-lab",
  "packages": ["openssh"],
  "services": ["sshd"],
  "custom_commands": [
    "install -dm700 -o arch -g arch /home/arch/.ssh",
    "printf '%s\\n' '@LAB_PUBKEY@' > /home/arch/.ssh/authorized_keys",
    "chown arch:arch /home/arch/.ssh/authorized_keys && chmod 600 /home/arch/.ssh/authorized_keys",
    "printf 'arch ALL=(ALL) NOPASSWD: ALL\\n' > /etc/sudoers.d/90-nier-lab && chmod 440 /etc/sudoers.d/90-nier-lab"
  ]
}
```

Notas:
- **`@LAB_PUBKEY@`** é trocado pela chave pública do lab (`$LAB_HOME/id_ed25519.pub`) na hora de
  mandar pra ISO. A chave pública não é segredo, mas fica fora do repositório público mesmo assim.
- **`--snapshot AAAA/MM/DD`** troca o `custom_servers` por
  `https://archive.archlinux.org/repos/AAAA/MM/DD/$repo/os/$arch`.
- **Os nomes exatos de alguns campos** (`profile_config` com `gfx_driver: null`, `sys_lang` com ou sem
  `.UTF-8`) são confirmados no spike com `--dry-run`. A regra é: o arquivo final é o que o
  `--dry-run` do archinstall aceita sem aviso, e o `user_configuration.json` que ele salva vira a
  referência.

## `disk_config` gerado

O lab gera o bloco a partir do tamanho do disco (`--disk`, padrão 40 GiB) e o injeta na configuração.
GPT, setor de 512 B, alinhado em 1 MiB:

| Partição | Início | Tamanho | Tipo | Montagem | Opções |
|---|---|---|---|---|---|
| ESP | 1 MiB | 1 GiB | `fat32`, flags `boot`, `esp` | `/boot` | — |
| raiz | 1025 MiB | o resto menos 1 MiB (tabela GPT de reserva) | `btrfs` | (subvolumes) | `compress=zstd` |

Subvolumes: `@` → `/`, `@home` → `/home`, `@log` → `/var/log`, `@pkg` → `/var/cache/pacman/pkg`.

Forma (abreviada; os campos seguem `examples/config-sample.json` do archinstall 4.5):

```json
"disk_config": {
  "config_type": "default_layout",
  "device_modifications": [{
    "device": "/dev/vda",
    "wipe": true,
    "partitions": [
      { "obj_id": "<uuid>", "status": "create", "type": "primary",
        "start": { "sector_size": { "unit": "B", "value": 512 }, "unit": "MiB", "value": 1 },
        "size":  { "sector_size": { "unit": "B", "value": 512 }, "unit": "GiB", "value": 1 },
        "fs_type": "fat32", "flags": ["boot", "esp"], "mountpoint": "/boot",
        "mount_options": [], "btrfs": [], "dev_path": null },
      { "obj_id": "<uuid>", "status": "create", "type": "primary",
        "start": { "sector_size": { "unit": "B", "value": 512 }, "unit": "MiB", "value": 1025 },
        "size":  { "sector_size": { "unit": "B", "value": 512 }, "unit": "MiB", "value": 39934 },
        "fs_type": "btrfs", "flags": [], "mountpoint": null,
        "mount_options": ["compress=zstd"], "dev_path": null,
        "btrfs": [
          { "name": "@", "mountpoint": "/" },
          { "name": "@home", "mountpoint": "/home" },
          { "name": "@log", "mountpoint": "/var/log" },
          { "name": "@pkg", "mountpoint": "/var/cache/pacman/pkg" }
        ] }
    ]
  }],
  "btrfs_options": { "snapshot_config": null }
}
```

## Credenciais (geradas a cada execução)

```json
{ "users": [{ "username": "arch", "enc_password": "<hash yescrypt>", "sudo": true, "groups": [] }] }
```

- Sem `root_enc_password`: o root fica bloqueado (conferência `root_locked`).
- A senha em texto puro existe só em `$LAB_HOME/vms/<nome>.creds` (modo 600).
- O hash é feito **dentro da ISO**: a senha entra por stdin num `python -c` que chama
  `archinstall.lib.crypt.crypt_yescrypt`. Ela nunca aparece numa linha de comando (nem no `ps` da VM).
- O arquivo vai pra `/root/rien-lab/user_credentials.json` na ISO e é apagado no passo 7, junto com a
  cópia que o archinstall salva em `/var/log/archinstall/`. Nada disso vai pra pasta de saída.

## Disco `cidata` (cloud-init NoCloud)

Uma ISO 9660 com rótulo `cidata`, feita no host com
`xorriso -as genisoimage -output <seed.iso> -volid cidata -joliet -rock user-data meta-data`.

`meta-data`:

```yaml
instance-id: rien-lab-<nome>-<AAAAMMDDHHMMSS>
local-hostname: archiso
```

`user-data`:

```yaml
#cloud-config
write_files:
  - path: /root/.ssh/authorized_keys
    permissions: '0600'
    content: |
      @LAB_PUBKEY@
runcmd:
  - [sh, -c, 'echo RIEN-LAB-SEED-OK > /dev/ttyS0']
```

- **Só abre a porta.** O `cidata` não leva a configuração nem as credenciais: elas vão pelo SSH
  (research R2).
- **Implementado com um item a mais** (2026-10-27): o `user-data` também grava
  `/etc/ssh/sshd_config.d/90-rien-lab.conf` com `PerSourcePenaltyExemptList 10.0.2.2/32` e recarrega o
  sshd antes do marcador. Vale só pro sistema da ISO (não vai pro instalado) e evita que o sshd recuse
  o lab depois da rajada de conexões da sonda de boot ([lab-install-iso.md](lab-install-iso.md),
  "Notas da implementação").
- **Conferido no spike (T001):** o cloud-init 26.2 da ISO 2026.10.01 acha o `cidata` sozinho; o
  marcador sai na serial em ~43 s. O plano B (`script=`) não foi preciso.
- **`sys_lang`** fica `en_US` (sem `.UTF-8`), como no exemplo do archinstall; o `--dry-run` aceitou a
  configuração padrão sem aviso.
- **O marcador na serial** é o sinal de que o cloud-init rodou. Se ele não aparecer em 3 minutos, o
  passo 4 falha com "cloud-init não achou o cidata" e o `console.png` mostra a tela.
