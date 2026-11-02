# YoRHa-Shell

Uma interface para o Linux inspirada em NieR:Automata: barra, papel de parede, menu de pausa com o
movimento dos menus do jogo (em janela ou tela cheia), notificações no estilo do Pod, sons da
interface, telas de boot e login e, mais pra frente, a tela de bloqueio. Feita em
[Quickshell](https://quickshell.org/) para o Hyprland, no Arch Linux.

Os sons que vêm com o YoRHa-Shell são nossos. Quem tem o jogo no PC pode usar os da própria cópia, por
uma pasta de sons ([`docs/sons-do-jogo.md`](docs/sons-do-jogo.md)).

> **Estado:** em desenvolvimento. Tudo é testado num laboratório de máquinas virtuais antes de chegar
> em uma máquina de verdade. O instalador existe, mas ainda não há um endereço público de versões.

## Instalar e atualizar

Num Arch com o Hyprland funcionando, como o seu usuário:

```sh
YORHA_OS_CHANNEL=<endereço das versões> bash <(curl -fsSL <endereço das versões>/install.sh)
```

- **O instalador** confere o que o shell precisa e pergunta antes de instalar qualquer pacote.
- **Onde fica:** tudo vai pra `~/.local/share/yorha-shell/`, e o comando `yorha` pra `~/.local/bin/`.
- **O seu `~/.config/hypr` não é tocado.** No fim, ele mostra uma linha pra você colocar no topo do
  `hyprland.lua`; ela sobe o shell e liga os atalhos (SUPER; `YORHA_MOD = "ALT"` na linha de cima
  troca).
- **`yorha update`** traz a versão nova, e **`yorha rollback`** volta pra anterior, com o estado de
  antes. Quando sai versão nova, uma transmissão avisa, e SYSTEM › Updates tem o "Update now".
- **`yorha status`** mostra o que está instalado.
- **`yorha boot-login install`** põe as telas de boot e de login, com backup; `uninstall` desfaz.
- **`yorha uninstall`** tira tudo. A sua config em `~/.config/yorha-shell` fica.

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
