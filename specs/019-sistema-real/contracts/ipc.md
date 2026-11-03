# Contrato: `settings dump` (acréscimos)

Soma-se a `specs/003-settings-popup/contracts/ipc.md`. Os campos antigos não mudam de forma.

| Campo | Forma | Requisito |
|---|---|---|
| `live` | Inclui as linhas `sys.*` | FR-010 |
| `dimmed` | Inclui `available` falso | FR-004 |
| `reasons` | `{ "cat.opt": "motivo" }`, das linhas apagadas por `available` | FR-004 |
| `hidden` | `["cat.opt"]` das linhas que somem; uma categoria vazia não entra em `values` | FR-045 |
| `backend` | `Compositor.backendName` | US7.2 |
| `fileBase` | `{ compositor, shell }` | SC-009 |

`values` traz só as linhas visíveis. Com a janelinha aberta, o `pause dump` traz `system.choice` com `readOnly`, e `pause choice
pick` responde `error` nela.

**Espera na subida:** como hoje, o `settings dump` pode responder antes de o catálogo ser lido; quem testa abre o menu uma vez.
