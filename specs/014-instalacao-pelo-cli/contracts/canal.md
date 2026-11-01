# Contrato: o canal do lab (`lab/014/canal`, privado)

Servidor HTTP em `127.0.0.1:8714` no host; as VMs chegam por `http://10.0.2.2:8714`.

| Pedido | Resposta |
|---|---|
| `GET /latest` | `0.N` (texto), a versão mais nova da ref seguida |
| `GET /yorha-os-0.N.tar.gz` | `git archive --prefix=yorha-os-0.N/ --add-virtual-file=yorha-os-0.N/VERSION:0.N <commit de N>`, em gzip |
| `GET /yorha-os-0.N.tar.gz.sha256` | `<sha256>  yorha-os-0.N.tar.gz` |
| `GET /install.sh` | O `install.sh` da ref seguida |
| outro | 404 |

Comandos (`lab/014/canal`):
- `start`;
- `stop`;
- `status`;
- `follow <pasta> [ref]`, que troca a fonte sem reiniciar;
- `log`, com uma linha JSON por pedido.

Só commits viram versão. Um `N` que a ref não tem dá 404.
