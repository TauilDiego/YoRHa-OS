# Implementation Plan: Linhas do boot na hora

**Branch**: `012-linhas-do-boot` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Status**: aprovado pelo dono em 29.10, junto com a spec e as tarefas.

## Summary

Uma opção nova no tema de boot, `typing=instant|game`, com `instant` como padrão. No modo `instant`,
o `list_update` do `yorha-os.script` mostra cada linha da fila inteira assim que as imagens dela
ficam prontas, sem a digitação nem o intervalo, e começa várias por quadro, dentro de um orçamento de
tempo de preparação. As linhas por grupo passam a ter um limite de frequência (no máximo uma de cada
grupo a cada 0,5 s), porque, sem a digitação, a fila esvazia a todo quadro. O glitch não muda. O modo
`game` é exatamente o código da 011.

## Technical Context

**Language/Version**: a linguagem de script do Plymouth (26.x), como na 011.

**Primary Dependencies**: o tema `system/boot/plymouth/yorha-os` da 011 e o `gen/embed-stages.py`,
que copia o `config` pro script.

**Testing**: no lab (a `main` privada já tem as ferramentas da 011): `lab/011/install-module`,
`lab/bootcap`, `lab/011/boot-timing`, o `debug=on` pros quadros/s e uma sessão do dono na janela
(`lab/up --window`). Tudo dentro do `lab/perf`.

**Constraints**: a preparação das imagens de uma linha (o texto, a cópia vermelha e o brilho) custa
alguns milissegundos no initramfs. Por isso, um orçamento por quadro decide quantas linhas novas
entram em cada quadro, e o que não couber entra no quadro seguinte.

## Constitution Check

| Princípio | Como o plano cumpre |
|---|---|
| I. O sistema do dono é intocável | Só na VM do lab |
| III. Padrões gerenciados | A opção fica no `config` do tema, como `exit` e `effects` |
| IV. Evidência da VM | Cada SC tem a captura ou a medição |
| V. Spec antes de código | Spec, plano e tarefas pra aprovação do dono antes do código |
| VII. Simplicidade | Um modo novo no laço que já existe; o modo do jogo fica intacto |

Nenhuma violação.

## Decisão de desenho

- **Ordem das linhas:** continua a da chegada das etapas. A fila da 011 continua existindo, mas no
  modo `instant` ela não segura nada.
- **Orçamento por quadro:** no máximo 4 linhas novas por quadro, ajustado pela medição de quadros/s
  (SC-002).
- **Linhas por grupo:** uma linha de cada grupo a cada 0,5 s, com a contagem acumulada.

## Project Structure

```text
system/boot/plymouth/yorha-os/
├── config                 + typing=instant|game
├── yorha-os.script        o modo instant no list_update; o limite das linhas por grupo
├── gen/embed-stages.py    + a opção typing
└── README.md              a opção nova
specs/011-boot-e-login/contracts/plymouth-theme.md   a opção typing na tabela de opções
specs/012-linhas-do-boot/                             spec, plano, tarefas, relatório
```
