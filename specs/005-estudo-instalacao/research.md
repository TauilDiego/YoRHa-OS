# Pesquisa (Fase 0): Estudo de instalação

Cada item segue o formato da 004: **decisão** (o que o estudo faz com isso), **motivo** e
**descartado**, com as **fontes**. O que é fato de pesquisa entra no `docs/estudo-instalacao.md` marcado
como "pesquisa" (FR-016); o que precisa de prova é medido na VM e está marcado **a verificar no lab**.

Fontes consultadas em 2026-10-27. Parte do wiki do Arch e do AUR bloqueia leitura automática; nesses
casos a fonte é um espelho Kiwix do wiki de abril de 2026 (`wikipedia.jakami.de/content/archlinux_en_all_maxi_2026-04/…`).
**Antes de publicar o documento, conferir essas citações no wiki ao vivo.** Abreviação: `O3/` =
`https://github.com/omacom/omarchy/blob/v3.0.0/` (o repositório `basecamp/omarchy` redireciona pra
`omacom/omarchy`).

## R1. Método A: como o Omarchy v2/v3 instala e atualiza (o nosso modelo)

- **O que ele faz:**
  - **`boot.sh`:** instala o `git` (`sudo pacman -Syu --needed git`), apaga e clona de novo
    `~/.local/share/omarchy` (`OMARCHY_REPO`, padrão `basecamp/omarchy`; `OMARCHY_REF`, padrão
    `master`) e roda o `install.sh` (`O3/boot.sh`).
  - **`install.sh`:** `set -eEo pipefail`; fases `preflight → packaging → config → login → post-install`,
    cada passo por `run_logged`, com log em `/var/log/omarchy-install.log` (`O3/install.sh`,
    `O3/install/helpers/logging.sh`). O preflight recusa o que não for Arch puro, root ou x86_64
    (`O3/install/preflight/guard.sh`) e **marca todas as migrations existentes como feitas**
    (`O3/install/preflight/migrations.sh`).
  - **pacotes:** listas simples (`install/omarchy-base.packages`) instaladas com
    `sudo pacman -S --needed` (`O3/install/packaging/base.sh`). Nada de AUR na instalação: o que viria do
    AUR sai do repositório próprio `[omarchy]` (`O3/default/pacman/pacman.conf`).
  - **`omarchy-update`:** snapshot (`omarchy-snapshot create`) → `omarchy-update-git`
    (`git pull --autostash` do branch atual, não de uma tag; com conflito, `git reset --merge`) →
    `omarchy-update-perform` (pacotes do sistema com `pacman -Syu`, `yay -Sua` se houver pacotes de
    fora, `omarchy-migrate`, oferta de reinício) (`O3/bin/omarchy-update`, `O3/bin/omarchy-update-git`,
    `O3/bin/omarchy-update-perform`, `O3/bin/omarchy-update-system-pkgs`).
  - **migrations:** `migrations/<unix-ts>.sh`; depois de rodar, `touch ~/.local/state/omarchy/migrations/<arquivo>`;
    se falhar, `gum confirm` "Skip and continue?" (pula e marca em `skipped/`) (`O3/bin/omarchy-migrate`).
    A v4 escreve a regra: "Migrations must be idempotent", com marcadores por usuário
    (https://github.com/omacom/omarchy/blob/v4.0.0/docs/migrations.md).
  - **padrões × usuário:** `config/` é copiado uma vez pra `~/.config/`; o `hyprland.conf` do usuário
    carrega `~/.local/share/omarchy/default/hypr/*` e depois os arquivos dele
    (`O3/config/hypr/hyprland.conf`); `omarchy-refresh-config` recoloca o padrão com backup
    `.bak.<epoch>` (`O3/bin/omarchy-refresh-config`).
  - **aviso de update:** `omarchy-update-available` compara a maior tag remota (`git ls-remote --tags`)
    com a local; o Waybar roda isso de hora em hora (`O3/bin/omarchy-update-available`,
    `O3/config/waybar/config.jsonc`).
  - **canais:** `omarchy-channel-set` (stable/edge/dev, depois rc) aparece na v3.3.0
    (https://github.com/omacom/omarchy/blob/v3.3.0/bin/omarchy-channel-set).
- **Problemas reais desse modelo:**
  - editar arquivos dentro de `~/.local/share/omarchy` trava o `git pull`
    (https://github.com/omacom/omarchy/issues/240; manual: https://learn.omacom.io/2/the-omarchy-manual/65/dotfiles);
  - Ctrl+C no passo do git com `reset --merge` deixou um sistema inutilizável
    (https://github.com/omacom/omarchy/issues/1298);
  - apagar o branch `master` quebrou update e instalação (https://github.com/omacom/omarchy/issues/12436);
  - uma migration não idempotente travou a fila em instalações antigas
    (https://github.com/omacom/omarchy/issues/7078; também #9284 e #14467).
- **Decisão:** o protótipo A segue o Omarchy v3, com três correções que os problemas acima pedem e que
  o estudo mede:
  - instala e atualiza **por tag** (`git fetch --tags` + `checkout` da maior tag), nunca por branch;
  - não usa `pull` nem `reset --merge`: um arquivo gerenciado editado pelo usuário é detectado
    (`git status --porcelain`) e guardado em backup antes do `checkout` (cenário S10);
  - marca as migrations existentes como feitas na instalação nova, igual ao Omarchy.
- **Motivo:** é o modelo escolhido pelo dono (`PLAN.md` §2); o estudo compara o modelo, não os defeitos
  que já se sabe corrigir.
- **Descartado:** copiar o `omarchy-update` inteiro (snapshot de sistema, canais, `yay`): fora do escopo
  da carga.

## R2. Omarchy v4: de git pra pacotes do sistema

- **O que mudou:** na v4 ("Quattro", 2026-08-14) o Omarchy saiu do git e virou pacotes do sistema
  (`omarchy`, `omarchy-settings`), instalados em `/usr/share/omarchy` e `/etc/skel`, só por ISO; o
  `boot.sh` sumiu (https://github.com/omacom/omarchy/releases/tag/v4.0.0,
  https://github.com/omacom/omarchy/blob/v4.0.0/docs/file-layout.md,
  https://github.com/omacom/omarchy/blob/v4.0.0/manual/02-getting-started.md).
  - **update:** um hook do pacman bloqueia `pacman -Syu` direto (exige `omarchy-update`), o update pega
    uma trava e exige 10 GiB livres, e **um aviso no login pede as migrations pendentes**
    (https://github.com/omacom/omarchy/blob/v4.0.0/docs/update-process.md);
  - **canais:** stable, rc, edge e dev (dev = um checkout git em `~/omarchy`)
    (https://github.com/omacom/omarchy/blob/v4.0.0/manual/30-updates.md);
  - **repositório:** a CI monta, assina com GPG, sobe pra um bucket R2 e serve em
    `pkgs.omarchy.org/<canal>/<arch>`; "Packages only move forward" (https://github.com/omacom-io/omarchy-pkgs).
- **Decisão:** a v4 é o precedente direto do método C e entra no documento como tal. O detalhe que
  importa pro estudo: **com pacote do sistema, as migrations por usuário saem do pacman e vão pro
  começo da sessão** (R8).
- **Motivo:** mostra que o próprio modelo do projeto migrou de A pra C quando cresceu; o estudo precisa
  dizer se isso vale pra um mantenedor sozinho.
- **Descartado:** adotar a v4 como base (decidido no `PLAN.md`, Histórico 2026-10-26).

## R3. Método B: AUR

- **Regras que se aplicam a nós:**
  - não pode empacotar o que já está nos repositórios oficiais; teste de utilidade: "Will anyone else
    want to use this package?";
  - pacote de git leva o sufixo `-git`; binário pronto, `-bin`; `.SRCINFO` regenerado a cada mudança;
    o repositório do pacote deve trazer `LICENSE` ou `REUSE.toml`
    (https://wikipedia.jakami.de/content/archlinux_en_all_maxi_2026-04/AUR_submission_guidelines).
- **Pra quem instala:**
  - "AUR packages are user-produced content. Any use of the provided files is at your own risk.";
    revisar o PKGBUILD; `base-devel` é pressuposto; `makepkg` não roda como root (sai com código 10)
    (https://wikipedia.jakami.de/content/archlinux_en_all_maxi_2026-04/Arch_User_Repository,
    https://man.archlinux.org/man/makepkg.8);
  - os helpers (yay, paru) não estão nos repositórios oficiais, são "unsupported by definition" e se
    instalam com `git clone` + `makepkg -si` (https://github.com/Jguer/yay, https://github.com/Morganamilo/paru);
  - pacote `-git`: `pkgver()` com `git describe` ou `r<n>.<hash>`
    (https://wikipedia.jakami.de/content/archlinux_en_all_maxi_2026-04/VCS_package_guidelines); o helper só
    percebe commit novo com `--devel` (yay `-Y --devel --save`; paru guarda em
    `$XDG_STATE_HOME/paru/devel.json`) (https://raw.githubusercontent.com/Morganamilo/paru/master/man/paru.8).
- **Disponibilidade:** o Omarchy criou o repositório próprio "as replacement for AUR … to avoid AUR
  DDoS fallout" (https://github.com/omacom/omarchy/releases/tag/v2.0.0), e quedas do Chaotic-AUR
  quebraram instalações (https://github.com/omacom/omarchy/issues/727).
- **Decisão:** o protótipo B é um pacote **de versão** (`rien-os`, fonte = tarball da tag com
  `sha256sums`), não `-git`, pra o usuário poder ficar numa versão e voltar. O AUR é simulado por um
  repositório git com o PKGBUILD e o `.SRCINFO` no servidor do lab; o cliente faz o que um helper faz
  (`git clone`/`pull` + `makepkg -si`). O custo de instalar um helper entra numa execução de
  referência com o **yay de verdade** instalando um pacote que já existe no AUR (por exemplo
  `caelestia-shell`), só leitura, sem publicar nada (premissa da spec).
- **Motivo:** publicar no AUR é ação pública e fica pra S6, com aprovação do dono; o fluxo do helper é
  `git` + `makepkg`, que dá pra reproduzir.
- **Descartado:** um AUR falso completo com a API RPC (os helpers dependem dela; caro demais pra um
  estudo); `-git` como forma principal (não fixa versão).

## R4. Método C: repositório pacman próprio

- **Como funciona:**
  - `repo-add` lê pacotes prontos e atualiza o banco (`<repo>.db.tar.zst`, com o link `<repo>.db`);
    `--sign` assina o banco e `--verify` confere a assinatura antes de mexer
    (https://man.archlinux.org/man/repo-add.8;
    https://wikipedia.jakami.de/content/archlinux_en_all_maxi_2026-04/Pacman/Tips_and_tricks);
  - o cliente adiciona `[rien-os]` com `Server = …/$arch` no `pacman.conf`; `SigLevel` padrão é
    `Required TrustedOnly` (https://man.archlinux.org/man/pacman.conf.5);
  - assinatura dos pacotes com `makepkg --sign` (https://man.archlinux.org/man/makepkg.8); o usuário
    confia na chave com `pacman-key --recv-keys`, `--finger` e `--lsign-key`
    (https://wikipedia.jakami.de/content/archlinux_en_all_maxi_2026-04/Pacman/Package_signing);
  - hospedagem: arquivos estáticos por HTTPS bastam (o Omarchy serve de um bucket R2 atrás de CDN, R2).
- **Precedentes de como o usuário adiciona:** Chaotic-AUR (`pacman-key --recv-key` + `--lsign-key`,
  `pacman -U` do keyring e da mirrorlist, bloco no `pacman.conf`, `pacman -Syu`;
  https://aur.chaotic.cx/docs); CachyOS (um `cachyos-repo.sh` que faz o mesmo;
  https://wiki.cachyos.org/features/optimized_repos/).
- **Cuidado:** atualização parcial não é suportada no Arch
  (https://wikipedia.jakami.de/content/archlinux_en_all_maxi_2026-04/System_maintenance). Instalar o
  pacote novo do nosso repositório puxa dependências do `[extra]`, então o update do método C é sempre
  um `pacman -Syu` do sistema inteiro.
- **Decisão:** o protótipo C monta e assina num container do lab, com uma **chave GPG descartável do
  lab** (nunca a do dono), publica com `repo-add --sign` no servidor do lab, e o cliente adiciona a chave
  e o repositório como no Chaotic-AUR. O update é `sudo pacman -Syu` seguido do passo de migrations por
  usuário (R8). Volta: `pacman -U` do pacote anterior no cache.
- **Motivo:** é o caminho do Omarchy v4, do Chaotic-AUR e do CachyOS; o estudo mede o custo real pro
  dono (chave, hospedagem, CI) contra o ganho (assinatura, dependências, desinstalação limpa).
- **Descartado:** um pacote keyring próprio (`rien-os-keyring`): só faz sentido em público (S6); no
  estudo a chave é importada à mão e isso é contado como passo do usuário.

## R5. Método D: versões lado a lado, com troca atômica

- **Precedentes:**
  - Capistrano: `releases/<data>/`, `shared/` ligado em cada versão e `current` como link que só muda
    depois de um deploy bem-sucedido (https://capistranorb.com/documentation/getting-started/structure/);
  - Home Manager: gerações e `home-manager switch --rollback`
    (https://nix-community.github.io/home-manager/usage/rollbacks.html);
  - OSTree: várias implantações paralelas, e a volta é bootar a anterior
    (https://ostreedev.github.io/ostree/deployment/, https://ostreedev.github.io/ostree/atomic-rollbacks/);
  - chezmoi aplica arquivos de forma atômica, mas não tem volta documentada
    (https://www.chezmoi.io/what-does-chezmoi-do/).
- **Atomicidade:** `rename(2)` troca o destino sem um instante em que ele some (falha com `EXDEV` entre
  sistemas de arquivos) (https://man7.org/linux/man-pages/man2/rename.2.html). `ln -sfn` não é atômico
  (apaga e cria); o certo é `ln -s novo tmp && mv -Tf tmp current`
  (https://deployer.org/blog/atomic-symlinks, fonte secundária).
- **Decisão:** o protótipo D guarda `~/.local/share/rien-os/versions/<versão>/` e troca
  `~/.local/share/rien-os/current` com link temporário + `mv -T` no mesmo sistema de arquivos. Antes de
  cada migration, copia `~/.local/state/rien-os/` pra `~/.local/state/rien-os/backups/<versão-de-origem>/`;
  `rien rollback` troca o link de volta **e** restaura essa cópia. Guarda as 3 últimas versões. A carga
  chega como tarball da tag com `sha256` e assinatura destacada.
- **Motivo:** é a única forma das quatro em que a volta é desenho, não improviso; o estudo precisa
  saber se ela compensa o espaço e o código a mais.
- **Descartado:** Nix/Home Manager (outro gerenciador inteiro, fora do modelo "camada sobre Arch");
  OSTree (é imagem, contra a constituição II).
- **Nota pro documento:** D é um *layout*, não um transporte. Ele combina com A (cada versão sai de uma
  tag do git) ou com um tarball. A combinação A+D é avaliada no documento a partir das medidas de A e
  de D, sem protótipo próprio.

## R6. Como outros shells Quickshell chegam ao usuário

| Projeto | Instala com | Atualiza com | Fonte |
|---|---|---|---|
| Caelestia | AUR `caelestia-shell` (+ `-git`); dots por `caelestia-cli` | `caelestia update` | https://github.com/caelestia-dots/shell, https://github.com/caelestia-dots/caelestia |
| end-4 (illogical-impulse) | `bash <(curl -s https://ii.clsty.link/get)` ou `./setup install`; 14 PKGBUILDs locais montados com `makepkg -Afsi` | `git pull && ./setup install` | https://github.com/end-4/dots-hyprland, https://ii.clsty.link/en/ii-qs/01setup/ |
| DankMaterialShell | agora `dux-shell` no `[extra]`; também AUR `-git` e script `curl … \| sh` | pacman | https://archlinux.org/packages/extra/x86_64/dux-shell/, https://github.com/AvengeMedia/DankMaterialShell |
| Noctalia | `sudo pacman -S noctalia` (`[extra]`); a v5 nem depende mais do Quickshell | pacman | https://docs.noctalia.dev/noctalia/getting-started/installation/ |
| Serpantinum (o shell do dono hoje) | instalador próprio (`PLAN.md` §7) | — | https://github.com/ilyamiro/serpantinum |

- **Decisão:** o documento cita essa tabela como contexto. A trajetória comum (script → AUR → repositório
  oficial) é um dado: um caminho futuro "E. repositório oficial do Arch" existe, mas depende de um Trusted
  User adotar o pacote e fica como nota pra S6, fora da comparação.
- **Motivo:** mostra o que a comunidade aceita e o que um usuário de Quickshell já espera.

## R7. Quickshell e o Qt: o que quebra quando o Arch atualiza

- **Fatos:** o `quickshell` (0.3.2) está no `[extra]`, sem restrição de versão nas dependências do Qt
  (https://archlinux.org/packages/extra/x86_64/quickshell/). O próprio Quickshell avisa que, montado do
  AUR, ele "may break whenever Qt is updated" (https://quickshell.org/docs/guide/install-setup/), e há
  relatos de `undefined symbol … Qt_6_PRIVATE_API` resolvidos recompilando
  (https://bbs.archlinux.org/viewtopic.php?id=307155, https://bbs.archlinux.org/viewtopic.php?id=314672).
- **Decisão:** em todos os métodos a carga **depende do `quickshell` do `[extra]`** e nunca leva um
  Quickshell próprio. A carga é QML + fontes + shaders; a única parte gerada são os `.qsb`. Se um update
  do Qt invalida `.qsb` gerados antes é **a verificar no lab** (o `shell/shaders/build.sh` já cai pra um
  crossfade quando falta o `qsb`). O resultado entra no critério de manutenção ("o que obriga a
  republicar sem mudança no projeto").
- **Motivo:** sem código compilado contra o Qt, os métodos B e C não herdam o problema de rebuild que
  os repositórios de terceiros têm.

## R8. Migrations por usuário quando a carga é do sistema

- **Fatos:** os hooks do pacman (`alpm-hooks`) rodam na transação, com gatilho por pacote ou caminho
  (https://man.archlinux.org/man/alpm-hooks.5); a página não diz com qual usuário, e o natural é root
  (**inferência, a verificar no lab**). A v4 do Omarchy resolve com um aviso no login que roda as
  migrations pendentes do usuário (R2).
- **Decisão:** nos métodos B e C, o pacote instala o ponto de entrada `rien-shell`, que, antes de abrir a
  UI, roda as migrations pendentes **do usuário que está entrando** (marcadores em
  `~/.local/state/rien-os/migrations/`, como no Omarchy). Nos métodos A e D o `rien update` roda as
  migrations, e o `rien-shell` roda também as pendentes (pra cobrir o segundo usuário, cenário S9). O
  contrato está em [contracts/contrato-de-entrega.md](contracts/contrato-de-entrega.md).
- **Motivo:** constituição III (migrations idempotentes, update não toca no arquivo do usuário) e o caso
  de dois usuários, que só existe quando a carga é do sistema.
- **Descartado:** um hook do pacman que roda `sudo -u <cada usuário>`: mexe na casa de usuários que nem
  estão logados.

## R9. Volta do sistema inteiro: snapshots

- **Fatos:** o `snap-pac` cria snapshots do snapper antes e depois de cada transação do pacman
  (https://github.com/wesbarnett/snap-pac); o Omarchy tira snapshot a cada update e restaura pelo Limine,
  mas **restaura a raiz e não o `/home`** (https://github.com/omacom/omarchy/blob/v4.0.0/manual/47-system-snapshots.md,
  https://raw.githubusercontent.com/basecamp/omarchy/master/bin/omarchy-snapshot).
- **Decisão:** fora da medição (premissa da spec). O documento registra que o snapshot de sistema **não
  substitui** a volta da camada: o estado do usuário (`~/.local/state/rien-os`) e a cópia em
  `~/.local/share` (A, D) ficam no `/home`. Se a imagem do lab usa btrfs é **a verificar no lab**
  (`findmnt -no FSTYPE /` na `u2-base`); fica como nota pra S4.

## R10. Como o usuário fica sabendo que tem update

- **Fatos:** Omarchy v3: `git ls-remote --tags` de hora em hora, no Waybar (R1). Pacotes: o
  `checkupdates` (pacote `pacman-contrib`) usa um banco à parte em `/tmp/checkup-db-<uid>`, sem tocar no
  banco do sistema e sem root (https://man.archlinux.org/man/checkupdates.8). AUR: o helper compara com o
  AUR (`yay -Qua`) e, pra `-git`, só com `--devel` (R3).
- **Decisão:** cada protótipo implementa `rien update --check` (contrato) com o mecanismo natural do
  método: tags remotas (A), `.SRCINFO` remoto (B), `checkupdates` filtrado pelo repositório (C), arquivo
  `latest` no servidor (D). O estudo mede: precisa de root, quanto baixa, quanto demora (cenário S4). O
  indicador na barra fica pra S4.

## R11. Simular a publicação no laboratório

- **Decisão:** um **servidor de distribuição** num container do lab (rótulo `nier-lab`, sem privilégios),
  com um servidor HTTP estático que registra os bytes de cada pedido, publicado só em `localhost` do host.
  A VM chega nele por `10.0.2.2:<porta>` (rede de usuário do QEMU). Ele serve:
  - **A:** um repositório git nu servido por HTTP simples (`git update-server-info`), com as tags
    `v0.1`, `v0.2`, `v0.3`, e o `boot.sh`;
  - **B:** um repositório git com o `PKGBUILD` e o `.SRCINFO`, e os tarballs das tags;
  - **C:** o repositório pacman (`rien-os.db`, pacotes e assinaturas);
  - **D:** os tarballs, as somas, as assinaturas e o arquivo `latest`.
  As montagens (`makepkg`, `repo-add`, assinatura) rodam num container de Arch separado, como usuário sem
  privilégios. A chave é descartável e fica em `~/.local/share/nier-lab/u2/`, fora de qualquer git.
- **Motivo:** constituição I (nada de build no host) e FR-005 (nada publicado). O log do servidor dá os
  bytes da carga sem estimativa.
- **Descartado:** servir de dentro da própria VM cliente (não mede rede); uma segunda VM servidora
  (custa mais na máquina do dono sem ganho de medida); GitHub de verdade (publica).

## R12. Interromper no ponto certo

- **Decisão:** os protótipos escrevem a fase em que estão (`download`, `apply`, `migrate`) em
  `~/.local/state/rien-os/u2-phase` e, com `U2_PAUSE_AT=<fase>`, esperam 20 s nela. O roteiro do lab
  espera a fase aparecer (pelo `lab/ssh`) e desliga a VM à força pelo QMP (`quit`, equivalente a puxar o
  cabo). Nos métodos B e C a fase `apply` é o próprio pacman extraindo: o roteiro espera a trava
  `/var/lib/pacman/db.lck` aparecer e desliga; se o momento escapar, repete até 3 vezes com outro atraso
  e registra qual pegou.
- **Motivo:** sem pausa, o desligamento cai em pontos aleatórios e não dá pra comparar os métodos.
- **Descartado:** `kill` no processo (não simula queda de energia nem cache de disco).

## R13. Como medir tempo, bytes e privilégio

- **Decisão:**
  - **tempo:** o próprio roteiro marca o começo e o fim do comando; "UI no ar" é o primeiro instante em
    que `qs … ipc` responde, conferido por um `lab/shot`;
  - **bytes da carga:** log do servidor do lab; **bytes de dependências:** contador `rx_bytes` da placa
    da VM menos a carga;
  - **privilégio:** linhas do `sudo` no journal da VM durante a execução (o usuário `arch` tem `sudo`
    sem senha no lab; o número de pedidos vale como "quantas vezes um usuário real digitaria a senha");
  - **arquivos do usuário:** `sha256sum` de tudo em `~/.config` antes e depois;
  - **custo no host:** o `lab/perf` de sempre.
  - **mirror fixo:** durante o estudo, a `u2-base` aponta o pacman pro Arch Linux Archive numa data fixa
    (a do início das medições), pra as dependências serem as mesmas em todas as execuções
    (https://wiki.archlinux.org/title/Arch_Linux_Archive, **conferir no wiki ao vivo**).
- **Motivo:** FR-007 e FR-008. Repetir três vezes com versões de pacote fixas separa a variação da rede
  da diferença entre métodos.

## R14. Onde o Quickshell procura a config

- **Fatos:** o Quickshell procura a subpasta `quickshell` em "every XDG standard config path"
  (normalmente `~/.config/quickshell`), `-c <nome>` escolhe uma config e `-p <caminho>` roda uma config
  de qualquer lugar (https://quickshell.org/docs/guide/introduction/).
- **Decisão:** todos os métodos abrem a UI pelo ponto de entrada `rien-shell`, que chama `qs -p` com o
  caminho da carga instalada. Assim nenhum método escreve em `~/.config/quickshell` (constituição III).
  Se `/etc/xdg/quickshell/<nome>` também funciona (útil pros pacotes) é **a verificar no lab**, só como
  nota.

## R15. Onde ficam os protótipos e o que é publicado

- **Decisão:** os protótipos (scripts dos quatro métodos, receitas, roteiros, remendos das versões)
  ficam no repositório privado, em `rien-OS-private/lab/u2/`. O repositório público recebe o
  `docs/estudo-instalacao.md` e, nesta branch, os artefatos da spec. Quando a S3 começar, o que o método
  escolhido precisar é reescrito no público, já no desenho final.
- **Motivo:** FR-017; os protótipos citam o servidor do lab, portas e a chave descartável. Ideias do
  Omarchy (MIT) podem ser usadas com crédito, se algum trecho for copiado (constituição: licenças).
- **Descartado:** `install/prototipos/` no público (código descartável no repositório do produto).

## R16. Como decidir sem viés

- **Decisão:** os critérios, os pesos e as âncoras das notas ([experimentos.md](experimentos.md) §5)
  ficam fixados e commitados **antes** da primeira execução medida (FR-013). Mudança depois disso só com
  registro no documento ("peso trocado em <data>, motivo"). O documento mostra a conta com os pesos de
  partida e, ao lado, a conta com pesos iguais, pra mostrar se a escolha depende dos pesos.
- **Motivo:** quem escreve os protótipos tende a favorecer o método que já tem em mente (aqui, a
  hipótese de partida, ver o plano).
