# Pesquisa (Fase 0): Arch completo na VM

Cada item segue o formato: decisão, motivo e o que foi descartado. As versões foram conferidas em
2026-10-27 nos mirrors oficiais e nos repositórios do archiso e do archinstall (fontes no fim de cada
item). **Nenhuma VM foi ligada nesta pesquisa:** os números de tempo são estimativas, e o spike da
primeira tarefa (plano, "Ordem de execução") confirma ou corrige cada um.

## R1. O que é a `basic` hoje

- **Fato:** a `basic` é a imagem oficial de VM do Arch publicada pelo projeto **arch-boxes**
  (`Arch-Linux-x86_64-basic-<data>.<build>.qcow2`, ~512 MB). O `lab/fetch` baixa do
  `geo.mirror.pkgbuild.com/images/`, confere o `.SHA256` e a assinatura da CI do arch-boxes (chave
  fixada em `lab/keys/arch-boxes.asc`) e liga a imagem como camada somente leitura. O arquivo de
  fixação `images.lock` tem hoje **uma linha**, com o nome da imagem.
- **O que ela já traz:** usuário `arch` com senha `arch` e sudo sem senha, `sshd` ligado, rede por
  DHCP, disco de tamanho fixo. A `arch-limpo` só acrescenta a chave SSH do lab e o hostname `nier-lab`
  (`lab/bootstrap`).
- **Consequência pra S2:** a `basic` é um Arch "já instalado por outra pessoa". Ela não passa pelas
  escolhas que um usuário faz no archinstall (carregador, sistema de arquivos, swap, rede, perfil), e
  é justamente isso que a S3 precisa encontrar.
- **Fontes:** `rien-OS-private/lab/{fetch,bootstrap,images.lock,README.md}`;
  https://gitlab.archlinux.org/archlinux/arch-boxes

## R2. Como dirigir a ISO sem ninguém olhando

O que a ISO oficial (perfil `releng` do archiso) traz, conferido no repositório do archiso:
- `archinstall` e `cloud-init` na lista de pacotes; os cinco serviços do cloud-init ligados
  (`cloud-init-local`, `-main`, `-network`, `cloud-config`, `cloud-final`);
- `sshd` ligado, com `PermitRootLogin yes` e `PasswordAuthentication yes`
  (`/etc/ssh/sshd_config.d/10-archiso.conf`). A senha do root vem vazia, então ninguém entra por
  senha até alguém definir uma ou instalar uma chave;
- no UEFI, o systemd-boot com `timeout 15` e a entrada padrão do Arch: **o boot acontece sozinho**,
  sem tecla;
- `/root/.automated_script.sh`, que roda no login automático do tty1 e executa o que vier no
  parâmetro de kernel `script=` (URL ou caminho local);
- `choose-mirror`, que troca a mirrorlist pelo parâmetro de kernel `mirror=`.

Opções avaliadas:

| Opção | Como | Precisa mudar o boot? | Robustez |
|---|---|---|---|
| **A. Disco `cidata` (cloud-init NoCloud)** | Um segundo drive (uma ISO de poucos KB com rótulo `cidata`, feita com `xorriso`) com `user-data` e `meta-data`. O cloud-init da ISO acha o rótulo sozinho | Não. A ISO dá boot pela entrada padrão | Alta: zero tecla, ISO intacta, mecanismo documentado pelo cloud-init e ligado no `releng` |
| B. `script=` no kernel | O `.automated_script.sh` baixa e roda o script | Sim. Ou se edita a linha do boot com teclas, ou se dá boot direto no kernel (`-kernel/-initrd/-append`, extraídos da ISO com `xorriso`, com `archisobasedir=arch archisosearchuuid=<uuid>`) | Média: o boot direto pula o carregador da ISO (menos "real"), e o script precisa vir de uma URL (um servidor HTTP no host) ou de um caminho que já exista na ISO |
| C. Console serial | `console=ttyS0` e um script lendo/escrevendo pela serial | Sim (o UEFI da ISO não liga a serial) | Média; ótima como **canal de diagnóstico**, ruim como canal de comando |
| D. `sendkey` pelo QMP | Digitar os comandos no console | Não | Baixa: depende de tempo, mapa de teclado e do estado da tela. Só como último recurso |
| E. NoCloud pela serial SMBIOS | `-smbios type=1,serial=ds=nocloud;s=http://10.0.2.2:8000/` | Não | Média: exige um servidor HTTP no host durante a instalação |

- **Decisão:** **A + SSH**, em duas metades:
  1. **O `cidata` só abre a porta.** O `user-data` instala a chave pública do lab em
     `/root/.ssh/authorized_keys` (por `write_files`, que não depende do `disable_root` do
     cloud-init) e escreve um marcador na serial (`/dev/ttyS0`) quando termina. Mais nada.
  2. **O host dirige a instalação pelo SSH**, como o `lab/bootstrap` já faz com a `hypr-base`:
     espera o SSH do root, espera o sistema da ISO assentar (`systemctl is-system-running --wait`,
     como o próprio `.automated_script.sh` recomenda, por causa do `pacman-init`), manda a
     configuração e as credenciais por `stdin` (tar pelo SSH, sem arquivo no host fora do lab), roda o
     archinstall e recebe o código de saída e o log ao vivo.
- **Motivo:**
  - nenhuma tecla, nenhum parâmetro de boot mudado: a ISO dá boot exatamente como na máquina de um
    usuário;
  - o host vê tudo: código de saída, log ao vivo, tempo de cada passo (marcadores do `lab/perf`);
  - reusa o que o lab já tem (porta livre, `wait_ssh`, `ssh` com a chave do lab, QMP);
  - o `xorriso` já é pré-requisito do lab (pacote `libisoburn`), então nada novo entra no sistema do
    dono.
- **Diagnóstico:** a serial vai pra um arquivo (como no `lab/up`), com os marcadores do `user-data`.
  Na falha, um `screendump` do QMP guarda a tela do console. Com `--soft` (sem `egl-headless`) o
  `screendump` deve funcionar; o README do lab só registrou a falha dele com `egl-headless`
  (**confirmar no spike**).
- **Descartado como principal:** B (muda o boot ou exige servidor), C (só diagnóstico), D (frágil), E
  (servidor no host). **Plano B documentado:** se o cloud-init da ISO não achar o `cidata`, o spike
  testa B com boot direto no kernel e `script=` apontando pra um caminho no próprio `cidata` montado
  pelo script; D fica só pra destravar uma tela, nunca no fluxo normal.
- **Fontes:**
  - archiso `releng`: `configs/releng/packages.x86_64`, `airootfs/etc/systemd/system/*.wants`,
    `airootfs/etc/ssh/sshd_config.d/10-archiso.conf`, `efiboot/loader/loader.conf`,
    `airootfs/root/.automated_script.sh`, `airootfs/usr/local/bin/choose-mirror` —
    https://gitlab.archlinux.org/archlinux/archiso (espelho: https://github.com/archlinux/archiso)
  - cloud-init NoCloud (rótulo `cidata`, arquivos `user-data`/`meta-data`, `instance-id`
    obrigatório, exemplo com `genisoimage -volid cidata -joliet -rock`):
    https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html
  - Wiki: https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH (instalar pela ISO via SSH)

## R3. Formato da configuração e das credenciais do archinstall

- **Versão atual:** a ISO 2026.10.01 traz o **archinstall 4.5** (`arch/pkglist.x86_64.txt` da ISO).
  As versões 4.x saíram de março a setembro de 2026.
- **Linha de comando** (archinstall 4.5, `archinstall/lib/args.py`):
  - `--config <arquivo>` / `--config-url`: a configuração (JSON);
  - `--creds <arquivo>` / `--creds-url`: as credenciais (JSON), separadas da configuração;
  - `--creds-decryption-key` (ou `ARCHINSTALL_CREDS_DECRYPTION_KEY`): pra credenciais cifradas
    (arquivo começando com `$`);
  - `--silent`: sem nenhuma pergunta nem confirmação. **Só vale com uma configuração**; sem ela, é
    ignorado;
  - `--dry-run`: lê, valida e salva a configuração, e sai sem instalar;
  - outros úteis: `--skip-ntp`, `--skip-wkd`, `--offline`, `--debug` (avisa que grava credenciais no
    log: **não usar**), `--skip-version-check`.
- **Configuração** (`user_configuration.json`; chaves de `ArchConfigType`): `version`, `script`,
  `locale_config`, `archinstall-language`, `disk_config`, `profile_config`, `mirror_config`,
  `network_config`, `bootloader_config`, `app_config`, `swap`, `hostname`, `kernels`, `ntp`,
  `timezone`, `services`, `packages`, `pacman_config`, `custom_commands`.
  - **`disk_config` exige o layout explícito.** Os tipos são `default_layout`, `manual_partitioning`
    e `pre_mounted_config`, mas mesmo o `default_layout` precisa da lista `device_modifications` com o
    dispositivo (`/dev/vda` na VM), as partições, `start`/`size` em `{sector_size, unit, value}`,
    `fs_type`, `mountpoint`, `flags`, `status: "create"`, `obj_id` e, no btrfs, a lista de subvolumes
    (`{name, mountpoint}`). Então o lab **gera** o bloco de disco a partir do tamanho do disco
    (contrato em [contracts/archinstall-config.md](contracts/archinstall-config.md)).
  - `bootloader_config`: `{"bootloader": "Systemd-boot", "uki": false, "removable": false}`.
  - `network_config`: `{"type": "nm"}` (outros: `iso`, `nm_iwd`, `iwd`, `manual`).
  - `swap`: `{"enabled": true, "algorithm": "zstd"}` (zram).
  - `custom_commands`: comandos rodados no chroot do sistema instalado, **depois** dos serviços e
    **antes** do `genfstab`. É onde ficam as adaptações do lab (FR-014).
- **Credenciais** (`user_credentials.json`):
  ```json
  { "users": [{ "username": "arch", "enc_password": "<hash yescrypt>", "sudo": true, "groups": [] }] }
  ```
  - `root_enc_password` é opcional quando há um usuário com sudo. **Decisão:** sem senha de root
    (root bloqueado), como o archinstall permite e muita gente faz;
  - o archinstall 4.x espera **hash** (`enc_password`); o texto puro (`!password`) só existe como
    compatibilidade e é marcado como obsoleto;
  - o hash é **gerado dentro da ISO**, pelo próprio archinstall
    (`archinstall.lib.crypt.crypt_yescrypt`), por SSH: a senha passa por `stdin`, nunca na linha de
    comando, e nada roda no host além do SSH.
- **Validação antes de apagar o disco (FR-013):** `archinstall --config … --creds … --silent
  --dry-run` lê e valida a configuração sem tocar no disco.
  - **Medido (T018):** um campo inválido (sistema de arquivos inexistente) é recusado com código 1.
    Mas o `validate_bootloader_layout` **não** pegou um systemd-boot sem ESP: a configuração passou
    no `--dry-run` e só falhou na instalação ("Could not detect boot at mountpoint /mnt"). O
    `--dry-run` é a primeira barreira, não a única; o sucesso continua exigindo a instalação e o
    segundo boot.
- **Cuidado: código de saída.** No fluxo `guided` do 4.5, algumas recusas (por exemplo, a validação do
  carregador) chamam `error()` e **retornam** sem levantar exceção. Então o código 0 **não** prova a
  instalação. O sucesso exige: código 0 **e** a linha de conclusão no `install.log` **e** o segundo boot
  pelo disco (FR-017).
- **Descartado:** credenciais cifradas (`--creds-decryption-key`): a chave teria que viajar do mesmo
  jeito que as credenciais, sem ganho; manter as credenciais fora de qualquer repositório e fora dos
  logs resolve.
- **Fontes:** https://github.com/archlinux/archinstall (tag `4.5`: `examples/config-sample.json`,
  `examples/creds-sample.json`, `archinstall/lib/args.py`, `archinstall/lib/models/{device,users,network,bootloader}.py`,
  `archinstall/scripts/guided.py`); https://archinstall.archlinux.page/installing/guided.html (docs,
  parcialmente desatualizadas: ainda falam da 2.x)

## R4. Escolhas da instalação padrão

- **Decisão (FR-011):** systemd-boot; kernel `linux`; GPT com ESP de 1 GiB em FAT32 montada em `/boot`
  e o resto em btrfs com os subvolumes padrão do archinstall (`@` → `/`, `@home`, `@log` →
  `/var/log`, `@pkg` → `/var/cache/pacman/pkg`) e `compress=zstd`; swap em zram; NetworkManager;
  perfil `Minimal`; `en_US.UTF-8`, teclado `us`; fuso UTC; NTP ligado; `pipewire` não (o perfil
  mínimo não tem áudio); pacotes extras: só `openssh` (adaptação do lab, R6).
- **Motivo:** são as respostas mais comuns no archinstall pra um desktop e batem com a máquina de
  referência do projeto. A S3 testa o instalador em cima disso, e as variações (ext4, GRUB, rede pela
  ISO) entram como outros arquivos de configuração (FR-012).
- **Descartado:** perfil com desktop (a S3 é quem instala o Hyprland); `ext4` como padrão (menos
  parecido com o uso real); criptografia (fora do escopo).

## R5. Verificação da ISO

- **Fatos (2026-10-27):** release atual **2026.10.01** (kernel 7.2.7, 1,64 GB). Em
  `https://geo.mirror.pkgbuild.com/iso/<versão>/` ficam `archlinux-<versão>-x86_64.iso`, o `.sig`,
  `sha256sums.txt` e `b2sums.txt`. A ISO é assinada pela chave de release
  **3E80 CA1A 8B89 F69C BA57 D98A 76A5 EF90 5444 9A5C** (`pierre@archlinux.org`); a página de download
  manda buscar a chave por WKD (`gpg --auto-key-locate clear,wkd --locate-external-key …` ou
  `sq network wkd search …`). Os arquivos de hash **não** são assinados; só a ISO.
- **Decisão:** o mesmo esquema do `lab/fetch`, estendido:
  1. a chave pública de release fica **fixada** em `lab/keys/archlinux-release.asc` (exportada uma vez,
     com a impressão digital conferida contra a página de download e anotada no README do lab);
  2. a verificação usa um `GNUPGHOME` temporário com só essa chave (sem WKD na hora: rede não é
     confiança);
  3. confere o `sha256sums.txt` do mirror **e** o hash fixado no `images.lock` (os dois têm que bater);
  4. confere a assinatura `.sig` e exige que a impressão digital de quem assinou seja a fixada;
  5. só então a ISO vira somente leitura em `$LAB_HOME/images/`.
- **Descartado:** confiar só no hash do mirror (não é assinado); buscar a chave por WKD a cada uso
  (depende da rede e muda em silêncio se a chave mudar); usar o chaveiro do pacman do host (a página
  de download não o indica pra ISO, e ele muda a cada update do host; pode servir só pra conferir a
  impressão digital uma vez, ao fixar a chave).
- **Fontes:** https://archlinux.org/download/ ; https://geo.mirror.pkgbuild.com/iso/2026.10.01/

## R6. Adaptações do laboratório

O lab precisa entrar e mandar no sistema sem senha. O que um usuário **não** teria, e o lab
acrescenta:

| Adaptação | Por quê | Onde |
|---|---|---|
| `openssh` instalado e `sshd` ligado | Todos os comandos do lab falam por SSH | `packages` + `services` |
| Chave pública do lab em `~arch/.ssh/authorized_keys` | Entrar sem senha | `custom_commands` |
| `/etc/sudoers.d/90-nier-lab`: `arch ALL=(ALL) NOPASSWD: ALL` | A preparação da `hypr-base` e os testes usam `sudo` sem terminal | `custom_commands` |
| Hostname `nier-lab` | Igual às outras camadas | `hostname` |

- **Decisão:** essas quatro, e só elas, num bloco marcado da configuração padrão, repetidas num
  `manifest` guardado ao lado da camada (FR-014). O resto é archinstall puro.
- **Motivo:** a S3 vai precisar saber o que é "do usuário" e o que é "do lab". E um teste futuro pode
  remover o arquivo do sudo pra testar o caminho com senha.
- **Usuário `arch`:** igual ao da `basic`, pra a `hypr-base.sh` e o `GUEST_USER` do `lib.sh` servirem
  sem mudança (US3).
- **Descartado:** senha fixa conhecida (`arch`/`arch`, como a `basic`): o lab é local, mas uma senha
  gerada por camada custa pouco e permite testar o sudo com senha na S3.

## R7. Reprodutibilidade

- **ISO fixada:** o `images.lock` passa a ter uma linha por imagem, `chave=valor`:
  ```
  basic=Arch-Linux-x86_64-basic-20261015.611680.qcow2
  iso=archlinux-2026.10.01-x86_64.iso sha256=<64 hex>
  ```
  Uma linha sem `=` continua sendo lida como a `basic` (compatível com o arquivo de hoje). Contrato em
  [contracts/images-lock.md](contracts/images-lock.md).
- **De onde baixar:** `geo.mirror.pkgbuild.com/iso/<versão>/` (mantido pela equipe do Arch, o mesmo
  host que o `lab/fetch` já usa). Os mirrors guardam só as ISOs dos últimos ~3 meses; depois disso, o
  fallback é `https://archive.archlinux.org/iso/<versão>/` (conferido: tem 2026.08.01 a 2026.10.01).
- **Pacotes:**
  - **Padrão: pacotes do dia**, com a mirrorlist fixada em `geo.mirror.pkgbuild.com` no
    `mirror_config.custom_servers` (um mirror só, previsível, em vez do que o `reflector`/`choose-mirror`
    escolheria). É o que um usuário tem, e é a mitigação do `PLAN.md` §10 ("laboratório rodando com os
    pacotes do dia");
  - **Opção:** `--snapshot AAAA/MM/DD` troca o servidor por
    `https://archive.archlinux.org/repos/AAAA/MM/DD/$repo/os/$arch` e fixa os pacotes daquela data
    (pra repetir uma instalação que falhou ou bisectar).
  - O manifesto da camada guarda a lista de pacotes instalados (`pacman -Q`), pra comparar duas
    camadas.
- **Cache de pacotes:**
  - **Decisão: nenhum nesta fase.** A instalação mínima baixa ~600–800 MB (o `linux-firmware`,
    dividido em pacotes, é a maior parte). Medir primeiro (princípio VII);
  - **Se a medição mostrar que vale** (por exemplo, mais de 3 minutos só de download, ou várias
    instalações por dia na S3), a opção preferida é um proxy de cache do pacman num container com o
    rótulo `nier-lab` (permitido pela constituição I), apontado no `custom_servers` pelo endereço do
    host visto da VM (`10.0.2.2`). Fica registrado como trabalho futuro;
  - **Descartado:** compartilhar uma pasta do host com a VM (9p/virtiofs) como cache do `pacstrap`: o
    `virtiofs` precisa de um daemon no host, e o `pacstrap` do archinstall usa o cache do sistema alvo.

## R8. Tempo e disco esperados

Estimativas (**a confirmar no spike, com `lab/perf`**), com `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G` (teto do dono) pra
deixar folga pros agentes em paralelo:

| Passo | Tempo estimado | Base da estimativa |
|---|---|---|
| Download da ISO (1,64 GB, só na primeira vez) | 2–5 min | depende da banda; 1,64 GB a 100 Mbit/s ≈ 2,2 min |
| Verificação (sha256 + assinatura) | 5–10 s | ler 1,64 GB do disco |
| Boot da ISO até o SSH do root | 40–70 s | 15 s do menu do systemd-boot + boot do live (talvez copiando o squashfs pra RAM) + cloud-init |
| Assentar (`pacman-init`, sincronização do chaveiro, NTP) | 10–90 s | o archinstall espera o chaveiro por WKD e o NTP |
| Validação (`--dry-run`) | < 10 s | só lê e valida |
| Instalação (download ~700 MB + pacstrap + mkinitcpio + carregador) | 3–8 min | depende da banda e do mirror |
| Desligar, segundo boot pelo disco, conferências | 30–60 s | a `basic` leva ~7 s do boot ao SSH (relatórios do `lab/perf`); o sistema novo deve ficar na mesma ordem |
| **Total, com a ISO já baixada** | **≈ 5–11 min** | meta da SC-001: < 10 min, limite 20 min |

**Medido (2026-10-27, 2 CPUs, 4 GB, `lab/perf`):** download da ISO 476 s (1,64 GB, ~3,4 MB/s);
verificação 4 s; boot da ISO até o SSH 40–44 s, e até o `is-system-running` ~48–64 s; `--dry-run`
8–9 s; instalação 246–258 s, dos quais 210–219 s são o `pacstrap` da base (703 MiB de pacotes);
segundo boot até o SSH 7–10 s; **total 335–340 s (5,6 min)**. Camada: **1749 MB** depois do
`fstrim` (704 MB são o cache do pacman no `@pkg`).

Disco (em `~/.local/share/nier-lab/`):
- ISO: 1,64 GB (uma vez por versão fixada); `cidata`: < 1 MB por execução;
- camada `arch-iso`: qcow2 esparso de 40 GiB virtuais (o mesmo tamanho da `basic`), ocupando
  **≈ 2–3 GB** reais (sistema + pacotes no `@pkg`). Antes de congelar, um `fstrim` dentro da VM e o
  disco com `discard=unmap` devolvem o que o btrfs liberou;
- logs e screenshot: < 5 MB por execução;
- espaço livre exigido pra começar (FR-021): **6 GB** (ISO + camada + folga), ou 4 GB se a ISO já
  estiver baixada.

## R9. Como a camada entra na cadeia

Opções:

| Opção | O que muda | Risco |
|---|---|---|
| **A. Base paralela `arch-iso`** | Nova raiz, ao lado da `basic`: `arch-iso` (instalada pela ISO, congelada) → `teste-*` da S3. A `basic → arch-limpo → hypr-base → dev/teste-*` fica igual | Nenhum pras camadas atuais. Duas bases pra manter |
| B. Substituir `basic → arch-limpo` | `arch-limpo` passa a vir da ISO; `hypr-base`, `dev` e `teste-*` são refeitas por cima | Alto agora: os agentes em paralelo usam `dev` e `teste-a/b/c`; refazer tudo no meio da trilha da UI quebra o trabalho deles |
| C. `lab/bootstrap --iso` | O bootstrap ganha uma chave pra montar tudo do zero a partir da ISO | Útil depois; nesta fase, duplica a decisão de B |

- **Decisão: A.** A camada nova é uma **raiz** (um disco sem camada de baixo), registrada com a origem
  `iso:<versão>` no `<nome>.base`, então o `lab/ls` mostra de onde ela veio e o `lab/rm` continua
  protegendo as camadas de cima. O `lab/new teste-x --from arch-iso` funciona sem mudança.
- **Depois (decisão do dono):** se a US3 passar (a `hypr-base.sh` roda sem mudança sobre a
  `arch-iso`), a troca da base da UI vira uma tarefa pequena e separada: `hypr-base` refeita sobre a
  `arch-iso`, e a `basic` aposentada ou mantida só pra comparação. Isso fica pra quando nenhum agente
  estiver usando as camadas.
- **A ISO não é camada.** Ela fica em `$LAB_HOME/images/`, como os arquivos da `basic`, mas não ganha
  um link em `vms/`, porque não é um disco que se liga.

## R10. Evidência do "pronto quando"

A frase do `PLAN.md` é "um comando entrega um `arch-limpo` instalado pela ISO". A prova, toda dentro
de uma sessão do `lab/perf` (princípio IV):

```
lab/perf begin "006: arch-iso pela ISO" --kind 006-arch-iso --task 006
lab/install-iso                      # marcadores: iso, boot-iso, ssh-iso, dry-run, install, reboot, checks, freeze
lab/perf end --result pass --note "archinstall 4.5, ISO 2026.10.01"
```

O que fica registrado:
- **no relatório do `lab/perf`:** a duração total e de cada passo (marcadores), a CPU e a memória do
  host, o `boot_to_ssh_s` das duas VMs (a da ISO e a do segundo boot), e o disco do lab no início e no
  fim (o crescimento é o tamanho da camada);
- **na pasta de saída** (`$LAB_HOME/out/install-iso-<data>/`, cada arquivo registrado com sha256 pelo
  `perf_artifact`):
  - `verify.txt`: hash conferido e a linha `Good signature` com a impressão digital;
  - `install.log`: o log do archinstall, copiado da ISO;
  - `user_configuration.json`: a configuração que o archinstall salvou (sem as credenciais);
  - `checks.txt`: as respostas do sistema instalado, no segundo boot ([contracts/lab-install-iso.md](contracts/lab-install-iso.md), "Conferências");
  - `console.png`: o `screendump` do console no fim (o prompt de login do sistema instalado);
  - `manifest.json`: ISO, versão do archinstall, adaptações do lab e a lista de pacotes.
- **"Comando que responde":** `NIER_LAB_VM=teste-iso lab/ssh 'bootctl is-installed && findmnt -no FSTYPE / && systemctl --failed --no-legend | wc -l'`
  numa camada criada sobre a `arch-iso` responde `yes`, `btrfs` e `0`.
- **Screenshot:** o `console.png` (o lab não tem `grim` num sistema sem desktop) e, na US3, o
  `lab/shot` do Hyprland sobre a `arch-iso`.
- **"Log sem erro":** o `install.log` termina com a linha de conclusão e não tem `ERROR`/`Traceback`.

## R11. Recursos da VM durante a instalação

- **Decisão:** a instalação liga a VM com `--soft` (sem 3D: não há tela gráfica a ver) e, por padrão,
  `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G` (teto do dono, 2026-10-27). A porta SSH é a primeira livre (`free_port`), e o comando exporta
  `NIER_LAB_VM=<nome>` pra si, então funciona com outras VMs ligadas.
- **Motivo:** o archinstall não precisa de mais; sobra CPU e memória pros agentes que estão usando
  `teste-a/b/c` ao mesmo tempo.
