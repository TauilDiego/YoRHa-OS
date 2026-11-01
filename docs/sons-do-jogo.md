# Usar os sons da sua cópia do jogo

O YoRHa-OS vem com sons próprios, sintetizados por receita (`system/sounds/`). Se você tem o NieR:Automata
no PC, pode fazer a interface tocar os sons de menu **da sua própria cópia**, apontando uma pasta.

**Nada do jogo vem neste repositório e nunca virá.** Este guia não linka arquivos prontos, só guias e
ferramentas da comunidade pra você extrair o que é seu, da cópia que você comprou. Não use cópias piratas.

## Como funciona

1. Crie uma pasta, por exemplo `~/sons-yorha`.
2. Ponha nela um arquivo por evento, com o **nome do evento** (tabela abaixo), em `.wav` ou `.ogg`.
   Primeiro vale o `.wav`, depois o `.ogg`.
3. Aponte a pasta:
   - em `~/.config/yorha-os/shell.json`: `{ "sound": { "folder": "~/sons-yorha" } }`; ou
   - `qs -p <shell> ipc call settings set sound.folder ~/sons-yorha`.

   Configurações › Sound › Sound folder mostra o caminho em uso. A ação "Use our sounds" volta aos nossos.
4. Vale na hora. Evento sem arquivo toca o nosso. Arquivo que não abre (corrompido, formato que o
   Qt não lê) também cai no nosso, com uma linha `sounds: …` no log (`~/nier/ui.log` no lab).

Formato que dá menos problema: WAV PCM 16 bits, 48 kHz, curto (menos de 1,5 s). Volume: o da interface
(Configurações › Sound › Interface volume) vale sobre o do sistema; deixe os arquivos num nível normal.

## Os nomes dos eventos

| Arquivo | Quando toca |
|---|---|
| `move` | o cursor anda numa lista |
| `change` | um valor muda (◂ ▸, controle deslizante) |
| `confirm` | Enter, clique, entrar numa coluna |
| `back` | Esc, sair de uma coluna |
| `open`, `close` | abrir, fechar um menu |
| `tab` | trocar de aba |
| `dialog` | confirmar um diálogo |
| `choiceOpen`, `choicePick` | abrir, escolher na janelinha de valores |
| `notify`, `notifyCritical` | notificação normal, crítica |
| `osd` | um passo do volume ou do brilho |
| `sessionStart` | o desktop aparece depois do login (uma vez por login) |

Só a interface do shell usa a pasta. O som de boot e os sons da tela de login são do módulo de
boot e login e não mudam por ela.

## Onde achar guias e ferramentas (comunidade)

Os links mudam; procure pelos nomes. Sempre da sua cópia, por ferramentas feitas pra isso:

- **Ferramentas de extração de pacotes do jogo (`.cpk`)**: o NieR:Automata guarda o som em pacotes CRI
  (`data*.cpk`). Procure "NieR Automata CPK extractor" e "NieR Automata Modding Tools" nos repositórios
  da comunidade (GitHub) e no wiki "NieR:Automata Modding" (Fextralife / Steam Guides / Nexus Mods).
- **Áudio CRI (`.wem` / `.usm` / `.awb` / `.acb`)**: ferramentas como **vgmstream** (converte
  vários formatos de jogo pra WAV) e **foobar2000 com o plugin vgmstream** abrem os `.wem`/`.awb`.
  Os sons de menu ficam nos bancos de interface (UI/SE) do jogo.
- **Identificar qual som é qual**: o jeito honesto é ouvir e dar o nome do evento você mesmo; as
  comunidades de modding e os guias do Steam listam os bancos de efeitos de interface.

Se uma ferramenta ou guia sair do ar, o caminho continua o mesmo: extrair da sua cópia, converter pra
WAV e renomear pelo evento.

## Licença e uso

Os arquivos que você extrai são do jogo e ficam só na sua máquina, na sua pasta. Não os mande
pra repositórios, issues nem pacotes do YoRHa-OS.
