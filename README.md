# YoRHa-Shell

Uma interface para o Linux inspirada em NieR:Automata: barra, papel de parede, menu de pausa com o
movimento dos menus do jogo (em janela ou tela cheia), notificações no estilo do Pod, sons da
interface, telas de boot e login e, mais pra frente, a tela de bloqueio. Feita em
[Quickshell](https://quickshell.org/) para o Hyprland, no Arch Linux.

Os sons que vêm com o YoRHa-Shell são nossos. Quem tem o jogo no PC pode usar os da própria cópia, por
uma pasta de sons ([`docs/sons-do-jogo.md`](docs/sons-do-jogo.md)).

> **Estado:** prévia, antes da 1.0. Cada versão é testada em máquinas virtuais antes de sair, mas
> ainda pode quebrar coisas de uma versão pra outra.

> **Projeto de fã.** O YoRHa-Shell é gratuito e não tem ligação com a Square Enix. NieR e YoRHa são
> marcas da Square Enix. Nada do jogo vem junto: nem fontes, nem sons, nem imagens, nem vídeos.

## Requisitos

- Arch Linux ou um derivado.
- Hyprland 0.56 ou mais novo, com a config em Lua (`~/.config/hypr/hyprland.lua`).

O instalador confere o resto (o Quickshell, o Qt e as outras dependências do shell) e pergunta antes
de instalar qualquer pacote.

## Instalar

Num Arch com o Hyprland funcionando, como o seu usuário (sem `sudo`):

```sh
bash <(curl -fsSL https://github.com/TauilDiego/YoRHa-Shell/releases/latest/download/install.sh)
```

- **O que ele baixa:** a versão estável mais nova, das
  [releases](https://github.com/TauilDiego/YoRHa-Shell/releases). Antes de instalar, ele confere o
  pacote pelo checksum; se não bater, não instala nada.
- **Onde fica:** tudo vai pra `~/.local/share/yorha-shell/`, e o comando `yorha` pra `~/.local/bin/`.
- **O seu `~/.config/hypr` não é tocado.** No fim, o instalador mostra uma linha pra você colocar no
  topo do `hyprland.lua`:

  ```lua
  pcall(dofile, os.getenv("HOME") .. "/.local/share/yorha-shell/current/system/hypr/yorha-shell.lua")
  ```

  - É Lua pro Hyprland, não um comando de terminal: abra o arquivo num editor, cole a linha no topo,
    salve e entre de novo na sessão.
  - Ela sobe o shell e liga os atalhos, com SUPER. Pra usar ALT, ponha `YORHA_MOD = "ALT"` na linha
    de cima.
  - O `pcall` faz o Hyprland seguir normal se o YoRHa-Shell não estiver instalado.

## Usar

| Comando | O que faz |
|---|---|
| `yorha status` | Mostra a versão instalada, o canal e de onde vêm as versões |
| `yorha update` | Traz a versão nova, se houver |
| `yorha rollback` | Volta pra versão anterior, com o estado de antes |
| `yorha channel` | Mostra o canal: `stable` (o padrão) ou `testing` |
| `yorha channel stable\|testing` | Troca o canal. No `testing` chegam também as versões de teste (pré-releases), que podem ter mais problemas |
| `yorha boot-login install` | Põe as telas de boot (Plymouth) e de login (SDDM). Pede `sudo` e faz backup do que troca |
| `yorha boot-login uninstall` | Tira as telas de boot e de login e volta o backup |
| `yorha uninstall` | Tira o YoRHa-Shell. A sua config em `~/.config/yorha-shell` fica |

- **Versão nova:** o shell confere 30 s depois de subir e depois a cada hora. Quando sai uma, uma
  transmissão avisa, e um sinal fica na barra e no menu até você atualizar (SYSTEM › Updates escolhe
  onde, ou desliga).
  SYSTEM › Updates também tem o "Update now", que roda o `yorha update`.
- **Conferência automática:** dá pra desligar em SYSTEM › Updates. Aí só o `yorha update` confere.
- **Sem telemetria:** o shell só pergunta qual é a versão mais nova.
- **Desinstalar:** o `yorha uninstall` pergunta se tira também o estado salvo
  (`~/.local/state/yorha-shell`). Os pacotes do sistema que o instalador pôs ficam, e a linha do
  `hyprland.lua` é sua: tire ela à mão.

## Inspirações

Este projeto não existiria sem o trabalho de outras pessoas. Nada destes projetos foi copiado ou
embutido aqui: eles foram a referência e a inspiração para uma versão própria. O que foi
efetivamente usado, com a licença de cada coisa, está em [`CREDITS.md`](CREDITS.md).

- **[NieR:Automata](https://nierautomata.square-enix-games.com/)**, da PlatinumGames e da Square
  Enix: a linguagem visual inteira, do menu de pausa à tela de boot.
- **[Serpantinum](https://github.com/ilyamiro/serpantinum)**, de ilyamiro: a ideia de um shell
  completo em Quickshell sobre o Hyprland, que vive nas pastas dele e avisa quando sai versão nova.
- **[Omarchy](https://github.com/basecamp/omarchy)**, da Basecamp: o jeito de atualizar, com um
  comando e migrations.
- **[Qylock](https://github.com/Darkkal44/qylock)**, de Darkkal44: o layout da tela de login.
- **[nierlock](https://github.com/xendak/nierlock)**, de xendak: ideias para a tela de bloqueio.
- **[Unit-3](https://github.com/samyns/Unit-3)**, de samyns: o seletor de papel de parede em
  Quickshell.
- **[Nier-Automata-Rice](https://github.com/anteczko/Nier-Automata-Rice)**, de anteczko: referências
  de papel de parede e de fundo.
- **[O post de jinzurei](https://x.com/jinzurei/status/2083322529058582761)**: referência de
  papel de parede e de fundo.

## Créditos e licenças

O código do YoRHa-Shell é distribuído sob a [GNU AGPL-3.0-or-later](LICENSE). Fontes, desenhos e
trechos de código de terceiros usados no projeto, com as licenças de cada um, estão em
[`CREDITS.md`](CREDITS.md).

NieR:Automata e YoRHa são marcas da Square Enix. O YoRHa-Shell é um projeto de fã, sem afiliação, e
não distribui fontes, sons, imagens nem vídeos do jogo.
