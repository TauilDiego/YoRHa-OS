# Modelo de dados: Estudo de instalação

As entidades da spec, com os campos que o estudo registra. O formato de uma execução está em
[contracts/run.schema.json](contracts/run.schema.json); o que todo protótipo precisa
oferecer está em [contracts/contrato-de-entrega.md](contracts/contrato-de-entrega.md).

## Método

| Campo | Conteúdo |
|---|---|
| `id` | `A`, `B`, `C` ou `D` |
| `nome` | script + git · AUR · repositório pacman · versões lado a lado |
| `servidor` | o que o servidor do lab publica pra ele (ver [experimentos.md](experimentos.md) §2) |
| `instala_em` | onde a carga fica no cliente (`~/.local/share/yorha-os/…` ou `/usr/share/yorha-os/…`) |
| `migrations_em` | onde as migrations por usuário rodam (no `yorha update` ou no começo da sessão) |
| `prototipo` | pasta do protótipo no lab privado (`lab/u2/metodo-<id>/`) |

## Versão da carga

Geradas no lab a partir de um commit fixo do `shell/` (o `HEAD` da `005-estudo-instalacao` quando as
tarefas começarem). Os remendos ficam no lab privado (`lab/u2/carga/`), nunca no `shell/`.

| Versão | Muda | Serve pra |
|---|---|---|
| **0.1** | nada: a UI como está, mais o arquivo de versão | instalação |
| **0.2** | (1) um texto visível no HUD com a versão; (2) uma dependência nova do sistema (candidata: `qt6-imageformats`, que as imagens `webp` da 004 pedem; confirmar na tarefa que ela não está na `u2-base`); (3) o estado do papel de parede muda de formato (`monitors` → `outputs` em `wallpaper.json`, com `"format": 2`), e a 0.2 só lê o formato novo | update, migration, dependência |
| **0.3** | um erro de QML no `shell.qml` (a UI não abre) e uma migration nova (`"format": 3`) | volta, versão quebrada |

Regras:
- toda versão traz `VERSION` e a lista de dependências dela (`packages`), no formato que cada método
  precisar (lista, `depends=()`);
- a migration 0.1 → 0.2 é idempotente: rodar duas vezes dá o mesmo arquivo;
- a 0.2 não lê o formato 3: é isso que prova se a volta precisa restaurar o estado.

## Cenário

| id | Nome | Versões | Repetições |
|---|---|---|---|
| `S1` | primeira instalação | – → 0.1 | 3 (medida de tempo) |
| `S2` | update | 0.1 → 0.2 | 3 (medida de tempo) |
| `S3` | update repetido (idempotência) | 0.2 → 0.2 | 1 |
| `S4` | aviso de update | 0.1, com 0.2 publicada | 1 |
| `S5` | versão quebrada e volta | 0.2 → 0.3 → 0.2 | 1 |
| `S6a/b/c` | interrupção no download / na troca dos arquivos / na migration | 0.1 → 0.2 | 1 cada (até 3 se o ponto exato falhar) |
| `S7a/b` | sem rede na instalação / no update | – → 0.1, 0.1 → 0.2 | 1 cada |
| `S8a/b` | carga adulterada / carga e metadados adulterados | 0.1 → 0.2 | 1 cada |
| `S9` | segundo usuário entra depois do update | 0.1 → 0.2 | 1 |
| `S10` | arquivo gerenciado editado pelo usuário | 0.1 → 0.2 | 1 |
| `S11` | desinstalar | 0.2 → – | 1 |
| `S12` | publicar a 0.2 (lado do dono) | – | 1 |
| `S13` | carga secundária (cursor), opcional | – → 0.1 | 1 |

## Execução

Uma passada de um cenário num método, numa VM nova. Gravada como JSON em
`~/.local/share/nier-lab/out/u2/<método>/<cenário>-<n>.json` e anexada ao relatório `lab/perf` da sessão.
Campos principais (o esquema completo está no contrato):

- **identidade:** método, cenário, repetição, versão de origem e de destino, VM, commit da carga;
- **tempo:** do comando até o fim (`dur_s`) e até a UI responder (`ui_s`);
- **rede:** bytes da carga (log do servidor do lab) e bytes de dependências (contador da placa da VM
  menos a carga);
- **privilégio:** quantos `sudo`/pacman como root rodaram (journal da VM);
- **resultado:** `ok`, `falhou`, `recuperado`, com a versão que ficou no ar e o estado do arquivo de
  estado (formato);
- **usuário:** soma dos arquivos de `~/.config` antes e depois (iguais ou não) e backups criados;
- **recuperação** (S5–S8): passos, comandos e tempo até a UI voltar;
- **evidências:** caminhos dos screenshots (com sha256 do `lab/shot`), trecho do log da UI, id do
  relatório `lab/perf`.

## Critério

| Campo | Conteúdo |
|---|---|
| `id` | `K1`…`K10` ou `G1`…`G3` |
| `peso` | inteiro; os pesos de `K` somam 100; `G` são obrigatórios (sem peso) |
| `ancoras` | o que significa nota 0, 1, 2 e 3 (texto curto, fixado antes de medir) |
| `fontes` | cenários que alimentam a nota, ou "pesquisa" |

Os valores de partida estão em [experimentos.md](experimentos.md) §5.

## Matriz

Uma linha por critério, uma coluna por método. Cada célula: a nota (0–3), uma frase de justificativa e
os ids das execuções ou das fontes (R-n do [research.md](research.md)). A conta é
`Σ peso × nota / 3`, de 0 a 100, só entre os métodos que passaram nos critérios `G`. A matriz é a
seção central do `docs/estudo-instalacao.md`.

**Transições de um método no estudo:** `proposto` → `prototipado` (o protótipo cumpre o contrato na
S1) → `medido` (todas as execuções feitas) → `eliminado` (falhou num `G`) ou `pontuado`.
