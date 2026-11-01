# Relatório da 014: instalação e encaixe do shell, v0 pelo CLI

Branch `014-instalacao-pelo-cli` (público) e `lab-014` (privado), em 01.11.2026. Spec e plano
aprovados pelo dono em 01.11, com os ajustes do FR-017 (o cursor fica fora da v0) e do SC-007. O
dono escolheu a execução em sequência, sem frentes paralelas. As 30 tarefas estão feitas; a
mescla na `main` espera o OK dele.

## O que ficou pronto

- **Instalar com um comando (US1).**
  `YORHA_OS_CHANNEL=<url> bash <(curl -fsSL <url>/install.sh)`:
  - confere as pré-condições (não é root, é Arch, tem Hyprland, tem rede);
  - lista as dependências que faltam e só instala depois de um "s" (o `sudo` só entra aí);
  - baixa a versão mais nova, confere o `.sha256` e desempacota em
    `~/.local/share/yorha-os/versions/0.N`, com o `current` trocado de uma vez;
  - não toca no `~/.config/hypr` (conferido byte a byte) e, de novo, sai com 2 apontando pro
    `yorha update`;
  - no fim, mostra a linha do `hyprland.lua` e diz que ela vai no arquivo, não no terminal. Se a
    linha já está lá, só pede um login novo (T029).
- **Uma correção chega pelo `yorha update` (US2).**
  - `update --check` (texto ou JSON) não muda nada.
  - `update` baixa, confere, desempacota, copia o estado, troca, roda as migrations (uma vez por
    usuário) e reinicia o shell. Guarda as 3 versões mais novas.
  - `rollback` volta a versão anterior e o estado de antes do update.
  - Um update interrompido em qualquer passo deixa uma versão que sobe (SC-004).
- **O shell avisa, e o "Update now" atualiza (US3).**
  - O `Updater.qml` confere 30 s depois de subir e de hora em hora.
  - Uma versão nova vira uma transmissão do Pod, uma vez por versão; clicar abre SYSTEM › Updates.
  - SYSTEM › Updates mostra a versão em uso, a disponível e o "Update now", que abre o `kitty` com o
    `yorha update`.
  - Fora da instalação (o lab comum), a categoria diz "Not installed with yorha", e o log fica limpo.
- **O encaixe no Hyprland é um arquivo (US4).**
  - `system/hypr/yorha-os.lua` sobe o shell pelo supervisor (`yorha shell start`, uma instância só,
    que passa pra versão nova sozinho) e liga os atalhos pelo `yorha ipc`.
  - Também tem as teclas de volume e brilho e as regras `no_anim` (a decisão 8 da 013).
  - A pessoa inclui com uma linha `pcall(dofile, …)`: sem o YoRHa-OS, o Hyprland sobe sem erro.
  - `YORHA_MOD = "ALT"` na linha de cima troca o SUPER (o lab usa ALT).
- **O boot e o login pelo CLI (US5).** `yorha boot-login install|uninstall|status` chama o módulo
  da 011, com o "s" e o `sudo`.
- **Desinstalar (US6).** `yorha uninstall` para o shell, apaga a pasta, o comando e o estado, e
  lembra de tirar a linha do `hyprland.lua`.
- **O canal da v0 é o repositório local** (decisão do dono, FR-005). O `lab/014/canal` serve, no
  host, cada commit da ref seguida como a versão `0.<commits>`, com o tarball do `git archive`.
  O GitHub fica pra depois.

## Evidência (VMs do lab)

| Critério | Resultado | Onde |
|---|---|---|
| Instalar (US1, SC-001) | `deps` + `install` 12/0; com a mensagem nova, `install` 11/0 | `…105950`, `…111120`, `…145146` |
| Encaixe (US4) | `encaixe` 8/0 (o shell sobe sozinho depois do login; as teclas chegam pelo `yorha ipc`) | `…110937` e junção |
| Update, migration, rollback, interrupção (US2, SC-002–SC-004) | 27/0; o rollback do estado 14/0 | `…111732`, `…115103` |
| Aviso e "Update now" (US3, SC-005) | `notice` + `updates-menu` 14/0 | `…112746` |
| Boot e login (US5) | `boot-login` 5/0 na `teste-011` | `…113233` |
| Desinstalar (US6, SC-006) | 6/0; com a reinstalação sobre a linha, 7/0 | `…113501`, `…145146` |
| `check-014` inteiro | 65/0 | junção `…115245` |
| Regressão (SC-007) | `check-003` 25/0 ×2, `check-004` 63/0, `check-007` 76/0, `check-008` 110/0 ×2, `check-013` sons 44/0 | junção, 01.11 |
| Depois das correções da T029 | `check-003` 25/0, `check-007` 76/0, `check-013` inteiro 162/11 (10 do dump novo, corrigido, e o FR-009 de tempo, já conhecido), `check-013 modes` 44/0 | `…131843`, `…131845`, `…131847`, `…133318`, `…133320` |
| Pasta `applications` (lembrete da S3) | na `t014` sem a pasta, o update pra 0.98 a criou, e um app novo apareceu no APPS ao vivo | `…145523`, `…145621` |
| Sessão do dono (T029) | 0.94 do zero → aviso → "Update now" → 0.97 → `rollback` → 0.94 → `update` → 0.97; um shell só, log sem aviso | `…130054` |

Relatórios do `lab/perf` em `YoRHa-OS-relatorios/runs/2026-11-01T…`. Na sessão do dono (1 h 47 min
com a VM aberta), a CPU do host ficou 1,2 ponto acima da base em média, com pico de 31%. Nunca houve
mais de 4 VMs ligadas.

## Achados

- **O `qs ipc` precisa do `WAYLAND_DISPLAY` da sessão:** o `qs` filtra as instâncias pelo display.
  Pelo `ssh` puro, o `yorha ipc` não acha o shell; os roteiros chamam pelo `lab/ipc`.
- **Os shaders são compilados na máquina** (`yorha_prepare`), e o `pipewire-pulse` entrou nas
  dependências.
- **Uma VM sem placa de som** enche o log do shell de avisos do `QSoundEffect`. Os roteiros da 014
  sobem a VM com `--audio-capture`.
- **Espelho do Arch velho:** as VMs usam o ALA de 28.10. Numa máquina com a base de pacotes velha, o
  `pacman -S` pode dar 404; o caminho é oferecer `pacman -Syu --needed`, com o "s" da pessoa.
- **Sessão do dono (T029):**
  - as 10 categorias do SYSTEM passavam do rodapé no painel flutuante. A `CursorList` não rolava, e
    a rolagem das listas guardava pixels, então a tela cheia deixava a coluna rolada à toa. Agora
    rola em linhas inteiras, guardada em linhas, com a roda do mouse;
  - a linha Lua foi colada no terminal, e ela já estava no `hyprland.lua`. A mensagem do instalador
    mudou;
  - o aviso aparece uma vez por versão e some: quem não vê na hora só acha a versão nova no LOG ou
    em SYSTEM › Updates (decisão 1 abaixo);
  - no lab, um relogin deixa a instância velha do Hyprland pra trás; o `GUEST_ENV` pega a mais nova.

## Decisões pro dono

1. **Um sinal do update que fique na tela** até a pessoa atualizar (hoje, só a transmissão, uma vez
   por versão). Fica pra conversar, uma coisa por vez.
2. **"Update now" apagado em vez de escondido** quando não há versão nova. O contrato dizia
   "visível só com versão nova"; apagado mostra que a opção existe e segue o padrão das outras
   opções apagadas.

## Limites e pendências

- **Máquina de verdade:** tudo foi testado em VM.
- **Canal público e assinatura:** a v0 lê o repositório local, com `.sha256`. O GitHub e a
  assinatura das versões ficam pra S6.
- **O cursor** fica fora da v0 (FR-017).
- **Niri:** o arquivo de encaixe é só do Hyprland (S5).
