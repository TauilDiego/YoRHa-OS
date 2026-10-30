# Sondagem R0 (T006): o que a VM respondeu

Feita em 29.10 na `teste-011` (camada `boot-iso`: SDDM 0.21.0 com `sddm-greeter-qt6`, Plymouth 26.134,
mkinitcpio 42.2, systemd 262, kernel 7.2.11), em `--soft`, 4 CPUs e 4 GB. O tema mínimo da sondagem e
os drop-ins estão em `lab/011/sondagem/` (branch `lab-011` do repositório privado). As capturas são do
`lab/bootcap`, uma a cada 0,25 s.

**Relatório do `lab/perf`:** `2026-10-29T165505-vm-teste-011-011-t006-sondagem-r0`, resultado ok.
CPU do host 8,8 % em média (pico 77,8 %), 19 comandos do lab.

## Resultado

| # | Pergunta (research R0) | Resposta | Evidência |
|---|---|---|---|
| 1 | O systemd manda o nome de cada unidade pro Plymouth? | **Sim.** O `SetUpdateStatusFunction` recebe o nome cru da unidade (`systemd-journald.service`, `home.mount`, `dev-disk-by\x2ddiskseq-4.swap`): 43 unidades em ~2 s de tela | `bootcap-teste-011-20261029-183446`, quadro 25 |
| 2 | O script tem `Image.Crop`? | **Sim** (`crop: yes 20x10`). O rasgo pode cortar uma linha no meio, como no jogo | o mesmo boot, quadro 31 |
| 3 | ~100 sprites a ≥25 quadros/s? | **Sim, ~33 quadros/s** (o contador foi de 20 a 70 entre 5,86 s e 7,39 s), com 100 sprites se mexendo e o texto refeito a cada 5 quadros | quadros 22 e 28 |
| 4 | A M PLUS 1 chega no initramfs e o `Image.Text` desenha com ela? | **Sim, sozinha:** o hook `plymouth` do mkinitcpio copia a fonte do `Font=` do tema (pelo fontconfig) como `Plymouth.ttf`. **Mas no initramfs só ASCII:** "ÁÉÕ" e "■" viraram quadrados. No desligar (que roda do sistema montado), os acentos aparecem | quadros 22 (boot) e 2 do reboot |
| 5 | `Plymouth.GetMode()` no desligar? | **Sim:** `reboot` no reboot (a `plymouth-reboot.service` sobe o Plymouth). Numa VM, a tela de desligar dura ~0,2 s | `bootcap-teste-011-20261029-183531`, quadro 2 |
| 6 | A passagem pro SDDM sem console? | **Sim, na terceira tentativa** (abaixo). Preto → lista → preto → login, sem texto de console, e o login aparece em ~8,4 s, como na linha de base (8,37 s) | `bootcap-teste-011-20261029-183446` |

## A passagem (R8): duas tentativas travaram

- **Tentativa 1** (`plymouth deactivate` antes, `quit --retain-splash` depois do greeter) e **tentativa
  2** (`quit --retain-splash` antes do SDDM): **o login nunca abre.** O SDDM 0.21 sobe o X no VT 2 (não
  tem opção pra usar o VT 1). O `--retain-splash` deixa o tty1 em modo gráfico (`KD_GRAPHICS`), e o
  kernel ignora a troca de VT a partir de um VT gráfico em `VT_AUTO`. O X fica parado pra sempre em
  `vt_waitactive` (visto em `/proc/<pid>/stack`), e o greeter nunca sobe.
- **Tentativa 3 (a que vale):** antes do SDDM, com o Plymouth ainda cobrindo a tela, o tty1 é limpo e
  o cursor dele é escondido (`setterm --cursor off --clear all > /dev/tty1`). Depois o Plymouth sai
  **sem** reter a imagem. O tty1 volta pro modo texto, vazio e preto, e o X troca pro VT 2
  normalmente. Como a saída da lista já termina no preto, o preto do tty1 não aparece como emenda.

O drop-in da tentativa 3:

```ini
[Unit]
Conflicts=plymouth-quit.service
After=plymouth-start.service
OnFailure=plymouth-quit.service

[Service]
ExecStartPre=-/usr/bin/plymouth display-message --text=yorha:exit
ExecStartPre=-/usr/bin/sleep 0.4
ExecStartPre=-/bin/sh -c '/usr/bin/setterm --cursor off --clear all > /dev/tty1'
ExecStartPre=-/usr/bin/plymouth quit
```

O SDDM já passa `-background none` pro X por padrão, então o `sddm.conf.d` não precisa disso.

## O que muda no plano

- **R6:** o rasgo corta a linha no meio com `Image.Crop`.
- **R6 e R7:** **todo texto do boot fica em ASCII**: sem acento e sem "…" (vira "..."). O desligar
  (US5) pode usar "…".
- **R7:** o catálogo é necessário mesmo: o nome que chega é o cru (`dev-disk-by\x2ddiskseq-4.swap`).
- **R8:** vale a tentativa 3. O greeter sobe no VT 2, sobre o preto do tty1.
- **R12:** o drop-in do mkinitcpio só põe o hook; a fonte vem pelo `Font=` do tema.
- **SC-002:** o primeiro boot com o tema chegou no login praticamente no mesmo tempo da linha de base.
  A medição de verdade (vários boots, com e sem o tema) é a T041.

## Ferramentas do lab que saíram da fundação

- `lab/011/make-boot-iso` (T002): a camada `boot-iso`, congelada.
- `lab/011/users` (T003): `ana` e `bruno`, ou 20 usuários com `--many`.
- `lab/bootcap` (T004): a captura do boot pelo QMP, com a folha de contato. O greeter é detectado
  por `pgrep -f '^/usr/bin/sddm-greeter'` (a primeira versão casava com o próprio comando de checagem).
- `lab/011/install-dev` (T005): a instalação de laboratório dos temas.
