# Contrato: o CLI `yorha` e o `install.sh`

Tudo roda como o usuário. O root só entra pelo `sudo`, nos passos que pedem, e sempre depois de um "s".

## `install.sh`
`YORHA_OS_CHANNEL=<url> bash <(curl -fsSL <url>/install.sh)`

| Saída | Quando |
|---|---|
| 0 | Instalou; mostra a linha do `hyprland.lua` e diz que ela vai no arquivo, não no terminal (T029). Se o `hyprland.lua` já tem a linha, só pede pra entrar de novo |
| 1 | Pré-condição: é root, não é Arch, sem Hyprland, sem rede; nada mudou |
| 2 | Já instalado; aponta pro `yorha update` |
| 3 | Uma dependência obrigatória foi recusada; nada do produto foi instalado |
| 4 | Checksum errado; nada mudou |

## `yorha`
| Comando | Faz | Saídas |
|---|---|---|
| `status` | Versão em uso, anterior, canal, dependências, se o shell está rodando, boot-login | 0 |
| `update --check` | `available 0.N` ou `up-to-date`; não muda nada | 0; 1 sem canal |
| `update --check --json` | `{"current":"0.M","latest":"0.N","available":true}` | 0; 1 sem canal (`{"error":"…"}`) |
| `update` | Baixa, confere, desempacota, copia o estado, troca, migra, reinicia o shell | 0; 1 rede; 4 checksum; 5 migration |
| `rollback` | Volta a versão anterior e o estado | 0; 3 sem anterior |
| `shell start` | Supervisor do `qs` (uma instância só) | não sai enquanto o `current` existir |
| `shell restart` | `pkill -x qs`; o supervisor sobe a versão em uso | 0 |
| `ipc <args…>` | `qs -p <shell da versão em uso> ipc call <args…>` | a do `qs` |
| `boot-login install\|uninstall\|status` | O módulo da 011, com "s" e `sudo` | a do módulo |
| `uninstall` | Remove (research R11) | 0; 1 se a pessoa desistir |
| `version` | `yorha-os 0.N` | 0 |

As mensagens são em inglês, curtas e começam por `yorha:`. Uma pergunta aceita `s`/`y` como sim. Sem
terminal interativo, a resposta é "não".
