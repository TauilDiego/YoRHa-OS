# Contrato: o tema do SDDM (`yorha-os`)

## Arquivos

```text
/usr/share/yorha-os/login/          (gerenciado; o SDDM chega por /usr/share/sddm/themes/yorha-os)
├── metadata.desktop                Type=sddm-theme, MainScript=Main.qml, ConfigFile=theme.conf, QtVersion=6
├── theme.conf                      os padrões (data-model.md, "Opções do tema")
├── theme.conf.user -> /etc/yorha-os/login.conf
├── Main.qml                        uma instância por tela; os painéis só na principal (FR-036)
├── components/                     as partes da tela (lista, cartão, ações, relógio, teclas, diálogo,
│                                   faixa, título com glitch, boas-vindas)
├── ds/                             as cópias adaptadas do design system (research R3)
└── assets/ring/                    os quadros do anel, tinta sobre papel (R11)
```

## O que o tema usa do SDDM

| Do SDDM | Pra quê |
|---|---|
| `userModel` (`name`, `realName`, `lastIndex`) | A lista de usuários e o último que entrou |
| `sessionModel` (`name`, `lastIndex`) | A troca de sessão e a última usada |
| `sddm.login(usuário, senha, índice)` | Entrar |
| `sddm.onLoginFailed` / `sddm.onLoginSucceeded` | O erro (rasgo) e as boas-vindas |
| `sddm.reboot()` / `sddm.powerOff()` | Reboot e Shut down, depois da confirmação |
| `keyboard.capsLock` | O aviso de Caps Lock |
| `primaryScreen` | Onde vão os painéis |
| `config.<chave>` | As opções do tema |

## Teclado

| Tecla | Efeito |
|---|---|
| ↑ / ↓ | Troca de usuário (com a varredura e a pipa) |
| Enter | No nome: vai pra senha. Na senha: entra. Durante a entrada: corta (FR-018) |
| Tab / Shift+Tab | Troca de sessão |
| Esc | Limpa o campo; no diálogo, cancela |
| Qualquer letra durante a entrada | Corta a entrada e já entra no campo |

## Log

O greeter escreve no log (que o SDDM manda pro journal):
- `yorha-login: state=<intro|ready|checking|welcome|leaving>` a cada transição;
- `yorha-login: option <chave>=<valor> invalid, using <padrão>` uma vez por opção inválida.

Erros e avisos de QML do tema não podem aparecer (SC-007).
