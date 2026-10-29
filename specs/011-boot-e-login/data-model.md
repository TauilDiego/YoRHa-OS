# Data Model: Boot e login (011)

## Boot (Plymouth)

### Etapa do catálogo (`stages.tsv`)

Uma linha por etapa que tem nome nosso.

| Campo | O que é | Regras |
|---|---|---|
| `pattern` | Padrão do nome da unidade (`systemd-udevd.service`, `NetworkManager.service`, `*.mount`) | Glob simples; o primeiro que bate vence |
| `label` | O texto da linha, em inglês, escrito por nós | Até 48 caracteres; sem nome técnico nem texto do jogo |
| `group` | O grupo pra linha genérica (`services`, `volumes`, `devices`, `network`, `session`) | Uma das palavras da lista |

Uma unidade sem padrão no catálogo só é contada no grupo dela (R7).

### Linha da lista (em memória, no script)

| Campo | O que é |
|---|---|
| `text` | `label` mais o estado, ou a linha genérica do grupo |
| `unit` | O nome da unidade (pra marcar a falha depois); vazio nas genéricas |
| `status` | `running` → `ok` ou `failed` |
| `typed` | Quantas letras já apareceram (a digitação, ~77 letras/s) |
| `born` | Quando começou (a linha fica apagada só nos primeiros ~50 ms) |

**Fila:** as linhas esperam a digitação da anterior, com ~0,11 s entre elas. Quando chega o
`yorha:exit`, a fila é descartada e a saída começa (FR-026).

### Estado da tela de boot

`fade-in` (~1 s do preto) → `listing` (linhas, faixas, cursor `_`) → `exit` (saída em degraus, 0,4 s
ou 0,9 s) → congelada pelo `plymouth deactivate`.

Os outros modos do script:
- `password`: o pedido da senha do disco, por cima da lista; volta pra `listing`;
- `shutdown` e `reboot`: só a faixa (US5).

## Login (SDDM)

### Usuário e sessão

Vêm dos modelos do SDDM (`userModel`, `sessionModel`). O tema não guarda nada. O SDDM lembra o último
usuário e a última sessão (`lastIndex`). O tema acrescenta um item no fim da lista de usuários, o
"Other user…", que não é um usuário.

### Opções do tema

O `theme.conf` gerenciado, com o `theme.conf.user` (= `/etc/yorha-os/login.conf`) por cima:

| Chave | Valores (o padrão primeiro) | Efeito |
|---|---|---|
| `intro` | `full`, `fade`, `none` | A entrada depois do boot (FR-017, FR-019) |
| `clock` | `big`, `small`, `none` | O relógio do centro |
| `userList` | `always`, `auto` | `auto` esconde a lista com um usuário só |
| `reduceMotion` | `false`, `true` | Tira o glitch, o rasgo, a respiração e as varreduras; força `intro=fade` (FR-032) |

Um valor inválido vale como o padrão e gera um aviso no log, uma vez.

### Estado do greeter (R5)

```text
            ┌──────────── tecla / Enter / clique ────────────┐
 (boot) ──► intro ──(fim da sequência)──► ready ◄────────────┘
             │                             │  ▲
             │ (sem boot: logout/troca)    │  │ falha (rasgo, campo limpo)
             └──────── fade ─────────────► │  │
                                           ▼  │
                                        checking ──sucesso──► welcome ──► (sessão)
                                           
 ready ──Reboot/Shut down confirmado──► leaving ──► (o sistema reinicia ou desliga)
 ready ──diálogo aberto──► ready (subestado `dialog`)
 off: só no protótipo (no sistema real, a máquina desliga)
```

**Regras:**
- entrar num estado para todas as animações e temporizadores do anterior;
- em `intro`, `checking`, `welcome` e `leaving`, os controles não reagem ao mouse (FR-021);
- em `checking`, o campo e o Enter ficam travados até a resposta do SDDM (FR-010);
- cada transição escreve `yorha-login: state=<estado>` no log do greeter.

## Instalação

### Manifesto (`/var/lib/yorha-os/boot-login.json`)

| Campo | O que é |
|---|---|
| `version` | A versão do módulo que instalou |
| `installed_at` | Data e hora |
| `created` | Arquivos e links criados pelo módulo (são apagados no `uninstall`) |
| `edited` | Arquivos editados, cada um com o caminho do backup e os hashes de antes e depois |
| `initramfs` | Se a imagem foi refeita e o resultado da conferência (`lsinitcpio`) |
| `bootloader` | `systemd-boot`, `uki` ou `other` (manual) |

**Regras:**
- `install` duas vezes não cria um segundo backup do mesmo arquivo; vale o primeiro;
- `uninstall` sem manifesto não faz nada e sai com erro;
- depois do `uninstall`, o hash de cada arquivo editado bate com o hash de antes (SC-011).
