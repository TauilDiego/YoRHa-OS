# Contrato: o canal público (e o do lab, que imita o formato)

Uma **origem** é um endereço base. O canal público é `https://github.com/TauilDiego/YoRHa-Shell`; o
lab é `http://10.0.2.2:8714` (e `:8715` como espelho de teste). Toda origem responde aos mesmos
caminhos (research R1):

| Pedido | Resposta |
|---|---|
| `GET <origem>/releases/latest/download/latest` | `<v>` da estável mais nova (pode redirecionar) |
| `GET <origem>/releases/latest/download/install.sh` | O instalador da estável mais nova |
| `GET <origem>/releases.atom` | Feed Atom com uma `<entry>` por release (estável e pré-release), mais nova primeiro, cada uma com um link `…/releases/tag/v<v>` |
| `GET <origem>/releases/download/v<v>/manifest` | O manifesto da release: o nome do produto e o arquivo do pacote (data-model.md) |
| `GET <origem>/releases/download/v<v>/<arquivo>` | Um arquivo da release `<v>` (data-model.md) |
| outro | 404 |

## Como o produto lê

- **Canal `stable`:** `latest` acima. Pré-releases nunca aparecem.
- **Canal `testing`:** o maior `v<v>` do feed, com `<v>` no formato `^[0-9]+\.[0-9]+\.[0-9]+$` (as
  outras tags são ignoradas), comparado por `sort -V`. Inclui as estáveis: quem está no canal de teste
  também recebe as versões estáveis.
- **Sempre `curl -fsSL`**, com `--max-time 20` na conferência e nos downloads pequenos.
- **O pacote pelo manifesto:** o produto lê o `manifest` da versão e baixa o `package` que ele diz, com o `.sha256` ao lado. Sem manifesto (404), cai em `<YORHA_NAME>-<v>.tar.gz`.
- **Origens em ordem:** a primeira que responde vence. Os arquivos de uma versão (manifesto, pacote,
  `.sha256`) vêm todos da mesma origem; se um falha, a versão inteira é tentada na próxima. O
  download começa pela origem que respondeu o `latest` (ou o feed) e depois segue as outras na ordem
  do `origins`. Um checksum que não bate não passa pra próxima origem: sai 4.
- **Nada é mandado além do pedido:** sem identificador, sem a versão instalada, sem dado da máquina.
  O cabeçalho `User-Agent` é o padrão do `curl`.

## O canal do lab (`lab/015/canal`, privado)

`start [--port N] [--dir <releases>]` · `stop [--port N]` · `status` · `log [--port N]` ·
`corrupt <v>|off` (o `.sha256` daquela versão sai errado, pro teste de checksum).

- Lê `~/.local/share/nier-lab/015/releases/` (`index.json` e as pastas).
- `latest` = a maior versão com `pre: false`; o feed lista todas, inclusive as `labOnly`.
- O log tem uma linha JSON por pedido (`ts`, `port`, `path`, `status`).
- O `lab/014/canal` sai de uso; o `check-014` passa a usar este.
