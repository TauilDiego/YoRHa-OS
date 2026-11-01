# Tema de boot (Plymouth): `yorha-os`

A tela de boot do YoRHa-OS (spec 011): a lista de checagens com as etapas reais do boot, a película,
a lente, as faixas de interferência e o anel de carregamento. No desligar e no reiniciar, só a faixa
de passagem. Plugin `script` do Plymouth.

## Arquivos

- `yorha-os.plymouth` e `yorha-os.script`: o tema. `ImageDir` e `ScriptFile` apontam pra
  `/usr/share/plymouth/themes/yorha-os` (o instalador copia o tema pra lá; o hook do mkinitcpio não
  segue pasta ligada).
- `stages.tsv`: o catálogo das etapas (nome da unidade → texto nosso, grupo). As regras estão no
  cabeçalho do arquivo.
- `config`: as opções (`exit=fast|game`, `effects=full|calm`, `typing=instant|game`; `debug=on`
  mostra os quadros/s, só pro lab).
- `gen/embed-stages.py`: o Plymouth não lê arquivo em tempo de execução, então o catálogo, as opções e
  as larguras das letras da fonte vão pra dentro do script, entre os marcadores `@generated`. **Rode
  depois de mudar `stages.tsv` ou `config`** (no lab: `lab/011/boot-embed`) e refaça o initramfs.
- `gen/assets.py`: gera `assets/` (no lab: `lab/011/boot-assets`, num container). As imagens são
  commitadas, então a instalação não precisa de Python.
- `assets/`: película (`film-<p>.png`, um ladrilho por período), vinheta, anéis das faixas
  (`rings.png`, a tela inteira em 1080p; o script recorta a faixa), as pontas da faixa de passagem
  (`band-cap-l/r.png`, em 4K), os pontinhos dela (`band-dots-<p>.png`), pixels de cor e a fonte.
  `assets/ring/` sai do gerador do cursor (`lab/011/ring-frames`).
- `assets/font/YoRHaOSBoot.ttf`: a M PLUS 1 (OFL, `OFL.txt` ao lado) como instância estática
  (peso 600), cortada no latim e renomeada "YoRHa-OS Boot". **Precisa estar instalada nas fontes do
  sistema** (`/usr/share/fonts/yorha-os/`) antes do `mkinitcpio`: o hook acha a fonte pelo `Font=` do
  tema e a copia como `Plymouth.ttf`.
- `watch/yorha-boot-watch` e `watch/yorha-boot-watch.service`: o ajudante que avisa o tema das
  unidades que falharam (fica em `/usr/share/yorha-os/boot/watch/`, fora do initramfs).

## Como funciona

- **Camadas:** conteúdo (marca d'água, cabeçalho, linhas, cursor, anel) → faixas de interferência
  (um pedaço do fundo, o conteúdo rasgado 3,5 px pra esquerda, o escurecimento e os anéis) → película
  → vinheta → preto (a entrada, a saída e a cintilação). A película nunca rasga.
- **A lente** é uma cópia vermelha de cada texto, deslocada pela posição na tela (0,21 %); o brilho é
  uma cópia borrada (reduzida e ampliada de novo), a 35 %.
- **As linhas** vêm do `SetUpdateStatusFunction`: o systemd manda o nome de cada unidade **que ficou
  ativa** (as que falham não chegam por aí). O catálogo dá o texto; as que só são contadas viram uma
  linha genérica por grupo quando a fila esvazia ("Starting system services (11)"). A primeira linha
  ("Kernel loaded") e a da raiz ("Mounting the root volume", no `SetRootMountedFunction`) são etapas
  reais que não passam pelo systemd.
- **Linhas na hora (`typing=instant`, o padrão, spec 012):** a linha aparece inteira no quadro em que
  fica pronta, sem digitação, sem a letra sorteada, sem nascer apagada e sem o intervalo entre linhas;
  só o glitch se mexe. Entram até 4 linhas novas por quadro, porque cada uma desenha três imagens
  (texto, cópia vermelha, brilho). As unidades fora do catálogo viram a linha do grupo no máximo a
  cada 0,5 s, com a contagem acumulada. Esperando, o cursor pisca depois da última linha. Num boot
  do zero da VM passam umas 30 linhas em ~2,5 s, a ~35 quadros/s.
- **Digitação (`typing=game`, a da 011):** cada linha é desenhada uma vez (texto, cópia vermelha,
  brilho), um pedaço por quadro antes da vez dela, e digitada recortando essa imagem nas posições das
  letras (as larguras da fonte, embutidas no script). Os dois plugins de texto (o `label-freetype` no
  initramfs e o `label-pango` depois da troca de raiz) posicionam as letras por essas larguras. Num
  boot rápido só dá tempo de 2 a 5 linhas.
- **Falhas:** o `yorha-boot-watch` segue o journal e manda `yorha:fail:<unidade>`. A linha da unidade
  passa pra `[FAIL]` na cor de alerta; sem linha, ela entra na frente da fila com o texto do catálogo
  ou o genérico do grupo. Na saída, as falhas pendentes aparecem na hora (não dá tempo de digitar).
  O `--flush` do ajudante consulta o journal sem esperar (o journal seguido chega ~0,5 s atrasado):
  o drop-in do `sddm.service` deve chamá-lo logo antes do `yorha:exit`.
- **Saída:** `yorha:exit` descarta a fila (o boot nunca espera a lista) e apaga em degraus de 3
  quadros do jogo, 0,4 s (`exit=fast`) ou 0,9 s (`exit=game`), até o preto.
- **Desligar e reiniciar:** com `Plymouth.GetMode()` = `shutdown` ou `reboot`, só a faixa de
  passagem sobre o preto, já aberta, com "Shutting down…" ou "Rebooting…" (no desligar o texto vem do
  sistema montado, então o "…" desenha).
- **Só ASCII no boot:** o `label-freetype` do initramfs não desenha acento nem "…".

## Escolhas de desenho que não estavam na spec (pra revisão do dono)

Feitas pela regra "a mais próxima da análise 4K"; cada uma é fácil de trocar.

- **Cabeçalho:** "STARTUP" (60 px em 1080p) e "-System check" (24 px) com os pontinhos, no lugar e
  tamanho do "LOADING - BOOTING SYSTEM" da reprodução aprovada. Texto nosso.
- **Marca d'água:** "YoRHa-OS" e "SYSTEM INTERFACE" bem fracos (12 %) no centro, com as quedas
  próprias da análise, como na reprodução aprovada (artefato f3ee156f). O spec não cita a marca.
- **Fonte:** uma instância estática SemiBold (600), entre o 500 do cabeçalho e o 700 das linhas da
  reprodução, porque o initramfs só carrega um arquivo de fonte. Na tela, o texto sai mais fino e
  mais escuro que o do jogo (a película passa por cima dele). Dá pra subir pra 700.
- **A faixa de desligar** aparece já aberta (sem a abertura de linha de CRT), pra emendar na faixa do
  login sem repetir a animação; o texto segue a análise (rgb(138,137,135), peso normal), não o
  protótipo do login (#96958F, negrito).
- **Linha do catálogo:** `texto ... [ OK ]` digitada inteira; a falha troca o estado por `[FAIL]` em
  rgb(192,87,74) (o `alert` do tom escuro dos tokens do shell).
- **Película:** o vão é uma camada rgb(5,0,0) a 65 % sobre a célula, o que dá o vão medido
  rgb(12,7,4). A lente não pega a película (seria preciso processar pixel).

## Testar

No lab (nunca na máquina do dono):

```sh
lab/011/install-dev <vm> --no-login --boot <repo>/system/boot/plymouth/yorha-os
lab/bootcap <vm> --reboot --until login          # o boot, uma captura a cada 0,25 s
lab/011/slow-unit <vm> --boot 5                  # um boot lento; --shutdown 3 segura o desligar
lab/011/fail-unit <vm>                           # uma unidade do catálogo e uma genérica que falham
lab/bootcap <vm> --poweroff --until off          # o desligar
lab/011/ply-try <vm>                             # iteração rápida, sem reiniciar (pango, sistema montado)
```

Pra medir os quadros/s, `debug=on` no `config` e `lab/011/boot-embed`.
