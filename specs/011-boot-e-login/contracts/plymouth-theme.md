# Contrato: o tema do Plymouth (`yorha-os`)

## Arquivos

```text
/usr/share/yorha-os/boot/           (gerenciado; o Plymouth chega por /usr/share/plymouth/themes/yorha-os)
├── yorha-os.plymouth               ModuleName=script; ImageDir e ScriptFile apontam pra cá
├── yorha-os.script                 o tema
├── stages.tsv                      o catálogo das etapas (data-model.md); o build o embute no script
├── config                          as opções do tema de boot (abaixo)
└── assets/                         as imagens preparadas no build (research R6): película, vinheta,
                                    anéis das faixas, arte da faixa de passagem, quadros do anel claro
```

## O que o script recebe

| De onde | Como chega | O que faz |
|---|---|---|
| systemd, a cada unidade que começa | `SetUpdateStatusFunction(nome)` | Põe uma linha na fila ou conta no grupo (R7) |
| `yorha-boot-watch`, numa unidade que falhou | `display-message` `yorha:fail:<unidade>` | Marca a linha dessa unidade como falha |
| drop-in do `sddm.service`, o login vai subir | `display-message` `yorha:exit` | Descarta a fila e começa a saída (R8, R9) |
| cryptsetup, a senha do disco | `SetDisplayPasswordFunction(prompt, bullets)` | O campo no estilo do login (US4) |
| o Plymouth, no desligar | `Plymouth.GetMode()` = `shutdown` ou `reboot` | Só a faixa (US5) |

Mensagens com `yorha:` que o script não conhece são ignoradas. As outras mensagens do sistema
aparecem como uma linha comum.

## Opções do tema de boot (`config`)

| Chave | Valores (o padrão primeiro) | Efeito |
|---|---|---|
| `exit` | `fast`, `game` | A saída da lista: 0,4 s (`fast`) ou os 0,9 s do jogo (`game`, R9) |
| `effects` | `full`, `calm` | `calm` tira as faixas, o rasgo e a cintilação (movimento reduzido) |

## Números (da análise 4K; valores em 1080p)

Entrada ~1,0 s linear. Digitação ~77 letras/s; a primeira linha a ~20 letras/s. A linha nasce apagada
por ~50 ms, e as linhas ficam ~0,11 s uma da outra. Cursor 0,49 s aceso e 0,49 s apagado. Pontinhos
do cabeçalho em ciclo de 1,156 s. Malha de 7 px. Faixas ~7/s, 1–8 quadros, escurecendo ~12 %, com
rasgo de 3,5 px. Aberração só no vermelho, ~0,21 %. Cintilação geral de 3,5–5,4 %, uma vez a cada
~1,2 s. Saída de 0,4 s (`fast`) ou 0,9 s (`game`), em degraus de ~3 quadros. A faixa de passagem é lisa,
rgb(15,15,15), com o texto em rgb(138,137,135).
