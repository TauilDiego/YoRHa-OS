# Contrato: `images.lock`

Arquivo de fixação das imagens oficiais do laboratório (`YoRHa-OS-private/lab/images.lock`). Hoje ele
tem uma linha só, com o nome da imagem `basic`. Passa a ter **uma linha por imagem**:

```
basic=Arch-Linux-x86_64-basic-20261015.611680.qcow2
iso=archlinux-2026.10.01-x86_64.iso sha256=<64 caracteres hex>
```

Regras:
- **Formato da linha:** `<chave>=<arquivo>` seguido de campos opcionais `campo=valor` separados por
  espaço. Linhas vazias e começando com `#` são ignoradas.
- **Chaves:**
  - `basic` (lida pelo `lab/fetch`);
  - `iso` (lida pelo `lab/fetch iso` e pelo `lab/install-iso`). O campo `sha256` é **obrigatório**
    nela.
- **Compatibilidade:** uma linha sem `=` é lida como `basic=<linha>`, que é o arquivo de hoje. O
  `lab/fetch` reescreve o arquivo no formato novo na primeira vez que mudar a `basic`.
- **Atualização:** só o `--latest` do comando correspondente reescreve a sua linha; as outras ficam
  como estão.
- **Git:** o lock é versionado no repositório privado. Atualizar a ISO é um commit com a versão nova no
  assunto, pra dar pra achar quando uma instalação passou a falhar.
- **A chave de assinatura** fica em `lab/keys/archlinux-release.asc`. A impressão digital esperada
  (`3E80CA1A8B89F69CBA57D98A76A5EF9054449A5C`) fica numa constante do `lab/fetch` e no README do lab;
  trocar a chave é um passo manual, conferido pelo dono.
