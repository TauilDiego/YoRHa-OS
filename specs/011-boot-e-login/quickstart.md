# Quickstart: validar o boot e o login no lab

Tudo roda na VM do laboratório (constituição, princípio I), a partir de `YoRHa-OS-private/lab` na
branch `lab-011`. Cada teste fica dentro do `lab/perf` (begin/end), e o relatório entra no resumo.
Os comandos novos (`lab/011/*`, `lab/bootcap`, `lab/check-011`) são tarefas desta spec.

## Pré-requisitos

- A camada `hypr-iso` pronta (`lab/ls`). A `boot-iso` sai dela (abaixo).
- No máximo quatro VMs ligadas, com `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`.

## 1. Preparar a VM

```sh
lab/perf begin "011 preparar" --kind 011
lab/new teste-011 --from boot-iso          # boot-iso: hypr-iso + SDDM + Plymouth, sem login automático
lab/sync                                   # o repositório público vai pra VM
lab/011/users teste-011                    # dois usuários de teste; --many 20 pro teste da lista longa
lab/ssh 'sudo system/boot-login/yorha-os-boot-login install'
lab/perf end --result ok
```

**Esperado:** `install` sai com 0, e o `status` mostra os temas, o hook no initramfs, o `splash` na
entrada do systemd-boot e o manifesto.

## 2. Ver a tela do login sem reiniciar (iteração rápida)

```sh
lab/ssh 'sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/yorha-os' &
lab/shot                                   # nos dois perfis: 1080 e hidpi (2560×1600 a 1,25)
```

**Esperado:** a tela do protótipo aprovado (artefato 28209760, v3.2), sem erro de QML no log.

## 3. Do ligar ao login (SC-001, SC-002)

```sh
lab/perf begin "011 boot com tema" --kind 011
lab/bootcap teste-011 --until login        # screendump a cada 0,25 s + folha de contato
lab/perf end --result ok
```

Repetir com o tema desligado (`yorha-os-boot-login uninstall`) pra ter a linha de base.

**Esperado:** a folha mostra preto, a lista, a saída, a faixa e o login, sem console. Do ligar ao
login pronto, no máximo 0,5 s acima da linha de base.

## 4. Entrar, errar e trocar (US1, US3; SC-003 a SC-005, SC-009)

```sh
lab/check-011 login        # senha certa e errada, Other user, sessão, digitar durante a entrada
lab/check-011 power        # Reboot e Shut down: Cancel não faz nada; confirmar reinicia e desliga
```

**Esperado:** a sessão abre pro usuário certo (o `loginctl` mostra a sessão gráfica dele e o Hyprland
responde); o erro rasga e limpa o campo; o estado da VM muda só depois da confirmação.

## 5. Estresse das animações (SC-006)

```sh
lab/011/stress-greeter teste-011 --sequences 20
```

**Esperado:** em cada sequência, o último `yorha-login: state=` do journal é um estado válido, e a
captura final bate com ele.

## 6. Robustez (SC-007, SC-008, SC-011)

```sh
lab/check-011 journal      # 10 ciclos de boot, login e saída; zero aviso de QML dos temas
lab/check-011 fallback     # tema quebrado de propósito: o login padrão do SDDM entra
lab/check-011 undo         # uninstall + reboot: boot em texto, login padrão, hashes iguais aos de antes
```

## 7. Senha do disco (US4)

```sh
lab/install-iso arch-iso-luks --config lab/iso/archinstall-luks.json
lab/bootcap teste-luks --until password    # o campo no estilo do login; errar uma vez, depois acertar
```

## 8. Revisão do dono (SC-010)

Uma página de revisão com as capturas do login nos dois perfis e a sequência do boot, lado a lado com
a análise 4K. A aprovação visual é do dono.
