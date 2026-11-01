# Research: Instalação e encaixe do shell, v0 pelo CLI

Todas as decisões partem do estudo 005 (método D, `docs/estudo-instalacao.md` §8–§9) e do protótipo
`lab/u2/metodo-d` (privado). O que foi conferido no lab ou na máquina do dono foi só lido.

## R1. O canal: o repositório local, servido pelo lab

**Decisão:** um servidor do lab, `lab/014/canal`, em python só com a biblioteca padrão. Ele roda no host,
em `127.0.0.1:8714`, e as VMs chegam nele por `http://10.0.2.2:8714`: na rede "user" do QEMU, o
`10.0.2.2` é o loopback do host. O servidor:
- **segue uma fonte:** um repositório ou worktree e uma ref (`main` por padrão). A escolha fica num
  arquivo de estado do lab e se troca com `lab/014/canal follow <pasta> [ref]`;
- **numera:** a versão é `0.N`, com `N = git rev-list --count --first-parent <ref>`, e o commit de
  cada `N` sai de `git rev-list --first-parent --reverse <ref>`;
- **atende:**
  - `/latest`, com o número mais novo;
  - `/yorha-os-0.N.tar.gz`, gerado na hora com `git archive --add-virtual-file=yorha-os-0.N/VERSION:0.N <commit>` (o `--prefix` não vale pro arquivo virtual, então ele leva o caminho completo);
  - `/yorha-os-0.N.tar.gz.sha256`;
  - `/install.sh`, da ref seguida.

Só entram commits; o que não foi commitado nunca vira versão.

**Por quê:**
- é o pedido do dono: puxar do worktree local, sem passo de publicar;
- `git archive` é só leitura e reproduzível;
- o `--add-virtual-file` existe no git do host (2.55).

**Alternativas:**
- o servidor do estudo 005 (`lab/u2/servidor.py`, num container): precisa publicar à mão;
- `git fetch` dentro da VM: precisaria de um sshd no host, o que fere o princípio I;
- rsync do host pra VM: é empurrar, não puxar, e não testa o `update`.

**Limite:**
- **Trocar da `main` pra um worktree e voltar** pode dar um número menor. Depois de mesclar, a `main`
  conta 1 pelo merge, e o `update` não volta versão. Nesse caso é `yorha rollback`, ou reinstalar.
- **A versão final pra outras pessoas** (as Releases do GitHub) usa a mesma forma de versão. Fica fora
  da v0.

## R2. O CLI e o instalador saem do protótipo D

**Decisão:** reaproveitar do `lab/u2/metodo-d/bin/yorha` e do `comum/yorha-common.sh`:
- `fetch`, `switch` (o link `current` trocado com `ln -sfn` + `mv -T`) e `prune` (guarda 3);
- a cópia do estado antes do update;
- `rollback`, `migrate` e as marcas de migration.

O que muda:
- **sai:** a assinatura GPG (a v0 confere só o sha256, como diz o `PLAN.md`), a instalação de pacotes
  por listas de "módulos" e a compilação de shaders (o `.qsb` já vem no repo);
- **entram:**
  - a conferência das dependências (R3);
  - `shell` e `ipc` (R4);
  - `boot-login` (R10);
  - `uninstall` com perguntas (R11);
  - `update --check --json`.
- **O `install.sh` fica na raiz do repo e vem pelo canal:**
  `bash <(curl -fsSL http://10.0.2.2:8714/install.sh)`. O endereço do canal entra por
  `YORHA_OS_CHANNEL`, e o instalador guarda ele em `~/.local/share/yorha-os/channel`.
- **O nome do produto** (`yorha`, `yorha-os`, as pastas) fica num lugar só: `lib/yorha/name.sh`
  (FR-019).

## R3. As dependências do shell

**Decisão:** um manifesto, `system/deps`, com um pacote do Arch por linha e o motivo.
- **Obrigatórias**, tiradas das provisões do lab (`hypr-base.sh`, `sound.sh`, `notify.sh`) e dos
  comandos que o shell chama:
  - `quickshell`;
  - `qt6-declarative`, `qt6-svg`, `qt6-5compat`, `qt6-shadertools`, `qt6-wayland`;
  - `qt6-multimedia`, `qt6-multimedia-gstreamer`, `qt6-multimedia-ffmpeg`;
  - `libnotify`, `file`, `uwsm`, `curl`;
  - `wireplumber` (o `wpctl` dos atalhos de volume) e `pipewire-pulse` (por onde os sons do shell
    tocam; achado na T016).
- **Opcionais**, cada uma com o que deixa de funcionar sem ela: `brightnessctl` (atalhos de brilho) e
  `kitty` (o "Update now").
- **Fora do manifesto:** o Hyprland, que é pré-requisito.

O `install.sh` confere com `pacman -T`, lista o que falta e só roda `sudo pacman -S --needed` depois de
um "s". Se a pessoa recusar uma obrigatória, ele para.

## R4. O shell instalado: supervisor, reinício e IPC

**Decisão:** `yorha shell start` é um supervisor, levado do `lab/guest/nier-ui-run`.
- **Ao subir:**
  - espera o portal;
  - aplica o `QT_LOGGING_RULES` conhecido;
  - pega um lock em `$XDG_RUNTIME_DIR`, pra ter uma instância só;
  - num laço, resolve o caminho real de `current/shell` e roda `qs -p <real>`, com
    `YORHA_OS_ROOT=<pasta da versão>`.
- **Se o `qs` sair:** sobe de novo em 1 s. Ele para se o `current` sumir (desinstalado).
- **`yorha shell restart`:** `pkill -x qs`. O laço sobe a versão nova, e é assim que o update reinicia o
  shell.
- **`yorha ipc …`:** `qs -p <real current>/shell ipc call …`. O caminho é o mesmo que o supervisor usou,
  então o `qs` acha a instância. Os atalhos chamam o `yorha ipc`, nunca um caminho de versão.

**Alternativa:** um serviço `systemd --user`. Fica pra depois: o autostart do Hyprland é o encaixe que
a pessoa controla, e o lab já usa esse modelo.

## R5. O encaixe no Hyprland

**Decisão:** `system/hypr/yorha-os.lua`.
- **Atalhos:**
  - SUPER no lugar do ALT do lab: `SUPER+Escape` menu de pausa, `SUPER+I` configurações, `SUPER+W`
    seletor, `SUPER+N` log, `SUPER+CTRL+N` não perturbe;
  - as teclas de volume (`wpctl`) e de brilho (`brightnessctl`).
- **Regras:** as `layer_rule` `no_anim` de `yorha-notify`, `yorha-osd` e `yorha-popup`.
- **Autostart:** `hl.on("hyprland.start", …)` com `yorha shell start`.
- **A linha que a pessoa inclui:**
  `pcall(dofile, os.getenv("HOME") .. "/.local/share/yorha-os/current/system/hypr/yorha-os.lua")`.
  O `pcall` evita que o Hyprland quebre se o YoRHa-OS for desinstalado.

Como o arquivo é lido pelo `current`, um update troca o arquivo junto. Os atalhos que conflitarem com
os da pessoa ficam a cargo dela: ela inclui o arquivo antes dos atalhos dela.

## R6. O aviso no shell

**Decisão:** um serviço novo, `services/Updater.qml`.
- **Só funciona com `YORHA_OS_ROOT`.** Sem ele (o lab com `~/nier/ui`), fica em "not installed", sem
  rodar nada (FR-015).
- **Confere** rodando `$YORHA_OS_ROOT/bin/yorha update --check --json`: 30 s depois de subir e a cada
  hora.
- **Guarda** a última conferência e a última versão avisada em `~/.local/state/yorha-os/updates.json`.
- **Versão nova** vira `NotifyStore.system(…)`, uma vez por versão. O `system()` ganha uma ação
  opcional: clicar abre o menu em SYSTEM › Updates.
- **IPC:** `updates check` (força a conferência, pros testes) e `updates dump`.

## R7. SYSTEM › Updates e o "Update now"

**Decisão:** uma categoria nova, `updates`, no catálogo (`shell/fixtures/settings-default.json`). Ela
usa os tipos que já existem:
- `info` pra "Installed" e "Available";
- `action` pra "Update now", que só aparece com versão nova.

A ação chama o `Updater.updateNow()`, que abre o terminal da config:
- com o `kitty`: `kitty --hold <yorha> update`;
- com outro terminal: `<terminal> -e sh -c '<yorha> update; read'`;
- sem terminal: uma transmissão com o comando pra rodar à mão.

## R8. Caminhos e nomes

- **`services/Sounds.qml`:** sai a regra `/usr/share/yorha-os/sounds`. Ficam `YORHA_OS_SOUNDS` e
  `shell/../system/sounds`, que vale também na pasta da versão.
- **Variáveis:** `YORHA_OS_COMPOSITOR` e `YORHA_OS_FIXTURES`, aceitando `NIER_COMPOSITOR` e
  `NIER_FIXTURES` enquanto o lab usar.
- **O cursor fica fora da v0.** O tema precisa ser compilado (`system/cursors/build.sh`, com
  ferramentas pesadas num container), e o `git archive` não traz o tema pronto. Ele entra quando as
  versões forem montadas com um passo de build. É a mudança no FR-017, que o dono aprova junto com o
  plano.

## R9. Como testar no lab

- **A VM:** uma camada `t014` da `hypr-iso`, com um `hyprland.lua` de pessoa comum
  (`lab/014/hyprland-limpo.lua`: só o terminal e a linha do encaixe). O `nier-ui-run` e o `~/nier/ui`
  do lab não entram.
- **As versões de teste** (a correção visível e a migration de teste) são commits num worktree
  descartável, `YoRHa-OS-wt/t014-canal`, branch `t014-canal`. O canal segue esse worktree, e nada
  disso vai pra `main`. O worktree e a branch são apagados no fim.
- **`lab/check-014`**, com blocos `install`, `deps`, `encaixe`, `update`, `migration`, `rollback`,
  `interrupt` (3 pontos do update), `notice`, `updates-menu`, `boot-login` (na `teste-011`) e
  `uninstall`. Ele usa o `lab/perf`.
- **SC-007:** os roteiros 003, 004, 007, 008 e 013 rodam como hoje, com as mudanças da 014 no shell. O
  `check-014` confere o shell instalado (log de QML limpo, IPC, screenshot). É o ajuste no texto do
  SC-007, que o dono aprova junto.

## R10. O boot e o login pelo CLI

**Decisão:** `yorha boot-login <install|uninstall|status>`.
1. Explica o que muda no sistema.
2. Pede "s".
3. Roda `sudo "$YORHA_OS_ROOT/system/boot-login/yorha-os-boot-login" <cmd> --src "$YORHA_OS_ROOT"`.

O código de saída é o do módulo da 011.

## R11. Desinstalar

**Decisão:** `yorha uninstall`.
1. Para o supervisor e o `qs`.
2. Apaga as versões, o `current`, os links em `~/.local/bin` e o canal.
3. Mantém o `~/.config/yorha-os/`.
4. Pergunta antes de apagar o `~/.local/state/yorha-os/`.
5. No fim, lembra a linha do `hyprland.lua` e, se o `boot-login status` disser que está instalado,
   oferece desfazer antes.
