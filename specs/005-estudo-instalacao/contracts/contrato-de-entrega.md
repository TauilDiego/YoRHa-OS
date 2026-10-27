# Contrato de entrega (o que todo protótipo cumpre)

Os quatro protótipos (A, B, C, D) oferecem a mesma interface, pra que os cenários do
[experimentos.md](../experimentos.md) rodem iguais em todos e só o jeito de entregar mude. É também o
rascunho da interface que a S3 e a S4 vão implementar de verdade. Os nomes de comando, caminhos e
variáveis ficam em inglês (são código); a explicação, em português.

## Caminhos

| Caminho | Dono | Conteúdo |
|---|---|---|
| `<carga>` | o método | a UI instalada: `~/.local/share/rien-os/shell` (A), `/usr/share/rien-os/shell` (B, C), `~/.local/share/rien-os/current/shell` (D) |
| `<carga>/../VERSION` | o método | a versão (`0.1`, `0.2`, `0.3`) |
| `<carga>/../packages` | o método | dependências de sistema da versão (uma por linha); em B e C, as mesmas do `depends=()` |
| `<carga>/../migrations/<unix-ts>.sh` | o método | migrations da camada, em ordem |
| `~/.config/rien-os/` | **o usuário** | só lido. Nenhum protótipo cria, apaga ou escreve aqui (constituição III) |
| `~/.local/state/rien-os/` | a UI e as migrations | estado do usuário (`wallpaper.json`, da 004) |
| `~/.local/state/rien-os/migrations/<arquivo>` | `rien migrate` | marcador: a migration já rodou pra este usuário |
| `~/.local/state/rien-os/backups/<data-ou-versão>/` | os protótipos | cópias antes de sobrescrever qualquer coisa (constituição III; `PLAN.md` §4.3) |
| `~/.local/state/rien-os/u2-phase` | os protótipos | **só do estudo:** a fase atual (`download`, `apply`, `migrate`, `done`) pros cenários S6 |

## Comandos

Todos imprimem uma linha final legível e saem com 0 em sucesso, diferente de 0 em erro. Nenhum
passa nomes de arquivo por um interpretador (`eval`, `sh -c "$x"`).

| Comando | Faz | Root |
|---|---|---|
| `rien-shell` | roda `rien migrate` (pendentes do usuário atual) e depois `exec qs -p <carga>` | não |
| `rien version` | imprime `rien-os <versão> (<método>)` | não |
| `rien update --check` | imprime `up-to-date` ou `available <versão>`; não muda nada no disco do sistema | não |
| `rien update` | leva pra maior versão publicada, instala as dependências novas, roda as migrations do usuário atual, reinicia a UI (`pkill -x qs`; o `u2-ui-run` reabre) | quando o método precisar (medido) |
| `rien rollback` | volta pra versão anterior instalada; diz o que fez com o estado. Num método sem volta nativa, imprime os passos manuais e sai com 3 | quando o método precisar |
| `rien migrate` | roda as migrations sem marcador, em ordem; cada uma que der certo ganha marcador; a primeira que falhar para a fila e sai com erro (sem "pular e seguir", ao contrário do Omarchy v3) | não |
| `rien uninstall` | remove o que o método instalou; mantém `~/.config/rien-os/` e `~/.local/state/rien-os/`; lista o que ficou | quando o método precisar |

Nos métodos B e C, o comando nativo (`makepkg -si`, `pacman -Syu`) também vale como update; as
migrations então rodam no próximo `rien-shell` (R8). Os dois caminhos são medidos.

## Migrations

- Um script Bash por arquivo, nomeado pelo instante Unix, rodado como o usuário, com
  `RIEN_STATE=~/.local/state/rien-os`.
- **Idempotente:** rodar de novo não muda o resultado (S3).
- **Backup antes de escrever:** copia o arquivo de estado pra `backups/<versão-de-origem>/`.
- Instalação nova marca todas as migrations existentes como feitas (como o Omarchy, R1).
- A 0.2 traz `…-wallpaper-format-2.sh` (`monitors` → `outputs`, `"format": 2`); a 0.3 traz
  `…-wallpaper-format-3.sh`.

## Variáveis só do estudo

| Variável | Efeito |
|---|---|
| `U2_SERVER` | base do servidor do lab (`http://10.0.2.2:<porta>`) |
| `U2_PAUSE_AT` | `download`, `apply` ou `migrate`: espera 20 s nessa fase (S6) |
| `U2_RUN_ID` | id da execução, repassado pro log do servidor e pro registro |

## Prova de que o protótipo cumpre o contrato

Na S1 de validação (estado `prototipado`): `rien version` responde 0.1; `rien-shell` abre a UI
(screenshot + `qs -p <carga> ipc call wallpaper dump`); `rien update --check` responde `up-to-date`;
`find ~/.config/rien-os -newer <marca>` vazio.
