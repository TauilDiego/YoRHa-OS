# Tema de boot (Plymouth): `yorha-os`

A tela de boot do YoRHa-OS (spec 011): a lista de checagens com as etapas reais do boot, a película,
a lente, as faixas de interferência e o anel de carregamento. No desligar e no reiniciar, só a faixa
de passagem. Plugin `script` do Plymouth.

- `yorha-os.plymouth` e `yorha-os.script`: o tema.
- `stages.tsv`: o catálogo das etapas (nome da unidade → texto nosso). O build embute no script.
- `config`: as opções (`exit=fast|game`, `effects=full|calm`).
- `assets/`: as imagens geradas no lab e commitadas (`gen/assets.py`); `assets/ring/` sai do gerador
  do cursor (`lab/011/ring-frames`).
- `watch/`: o ajudante que avisa o tema das unidades que falharam.

**Só ASCII nos textos do boot:** no initramfs, o Plymouth não desenha acento nem "…" (sondagem R0).

**Testar:** no lab, `lab/011/install-dev <vm>` e `lab/bootcap <vm> --until login` (quickstart da 011).
