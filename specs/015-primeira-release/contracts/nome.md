# Contrato: a troca do nome e a conferência do pacote

## A tabela (research R5)

| Antes | Depois | Onde |
|---|---|---|
| `yorha-os` | `yorha-shell` | Pastas, arquivos, pacotes, temas, serviços, caminhos no código |
| `YoRHa-OS` | `YoRHa-Shell` | Textos da UI, README, docs, mensagens do CLI, constituição, CLAUDE.md |
| `YORHA_OS_<X>` | `YORHA_<X>` | Variáveis de ambiente: `ROOT`, `CHANNEL` (vira `ORIGIN` + `CHANNEL`, contracts/cli.md), `FIXTURES`, `SOUNDS`, `COMPOSITOR`, `SRC`, `BOOTLOADER`, `MKINITCPIO_DROPINS` |
| `YoRHa-OS Boot` (`YoRHaOSBoot.ttf`) | `YoRHa-Shell Boot` (`YoRHaShellBoot.ttf`) | A fonte do boot, regerada pelo `gen/assets.py` dentro da VM |
| `YoRHa-OS Cursors` | `YoRHa-Shell Cursors` | O tema do cursor |
| `yorha` (comando), `YORHA_*` (sem `_OS`) | iguais | — |

Os nomes `NIER_*` que a 014 ainda aceita como alias continuam aceitos.

## O que fica com o nome antigo (a lista de histórico)

- `specs/**` (os registros das specs);
- `PLAN.md`, na seção "Decisões tomadas" e nas linhas que datam o nome;
- `CREDITS.md`, só onde cita um arquivo pelo nome da época;
- `docs/estudo-*.md` (estudos datados);
- o `Sync Impact Report` da constituição;
- o histórico do git.

## A conferência do pacote (`release build` e `release check`)

Sobre a lista de arquivos do `tar.gz`:

| Regra | Recusa |
|---|---|
| Fontes | `*.ttf`, `*.otf`, `*.woff*` fora de `shell/assets/fonts/MPLUS1[wght].ttf` e `system/boot/plymouth/*/assets/font/*.ttf` |
| Áudio | `*.wav`, `*.ogg`, `*.mp3`, `*.flac`, `*.opus` fora de `system/sounds/` e `system/login/sddm/*/assets/sounds/` |
| Vídeo e arquivos do jogo | `*.mp4`, `*.webm`, `*.mkv`, `*.usm`, `*.bk2`, `*.bik`, `*.cpk`, `*.dat`, `*.dtt`, `*.wem`, `*.bnk`, `*.wsp` |
| Lab e privado | qualquer caminho com `lab/`, `YoRHa-OS-private`, `pessoal/`, `central/` |
| Tamanho | arquivo acima de 8 MB |
| Nome provisório | `yorha-os`, `YoRHa-OS`, `YORHA_OS` (sem diferenciar maiúsculas) num caminho ou no conteúdo de um arquivo de texto, fora da lista de histórico |

Cada recusa imprime o caminho e a regra. Na 015 a conferência não roda no CI: ela precisa do pacote
montado, que só existe no lab.
