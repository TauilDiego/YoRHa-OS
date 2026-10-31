# Contrato: som de boot e de login (módulo `yorha-os-boot-login`)

Os detalhes e as evidências estão em [research-som.md](../research-som.md), S3 e S4.

## O que o módulo instala

| Caminho | O quê |
|---|---|
| `/etc/udev/rules.d/80-yorha-os-boot-sound.rules` | No evento da placa (`SUBSYSTEM=="sound"`, `ENV{SOUND_INITIALIZED}=="1"`), pede ao systemd o `yorha-os-boot-sound.service` |
| `/etc/systemd/system/yorha-os-boot-sound.service` | `Type=simple`, sem `Before=` nenhum e sem nada que dependa dele. `TimeoutSec` curto |
| `/usr/share/yorha-os/boot/sound/yorha-boot-sound` | O script: acha o volume e toca, depois termina |
| `/usr/share/yorha-os/boot/sound/boot-start-<nível>.wav` | O som de início, pré-calculado em alguns volumes (S2) |

Tudo entra no manifesto da 011. O `uninstall` remove, e o `status` mostra.

## O script

1. **Usuário:** lê o último usuário em `/var/lib/sddm/state.conf` (`[Last] User=`).
2. **Estado:** lê o `~/.local/state/yorha-os/sound.json` desse usuário (data-model.md).
3. **Decide:**
   - com `muted` ou `bootLogin: false`, termina calado;
   - sem o arquivo, usa 30%;
   - com o arquivo, escolhe o nível mais próximo de `volume`.
4. **Greeter:** grava `/run/yorha-os/sound.state` (`{ "level": …, "enabled": … }`), pro tema de login ler.
5. **Toca:** `aplay -q -D plughw:<placa> boot-start-<nível>.wav`. Se der `EBUSY` (o WirePlumber já
   pegou a placa), desiste calado e registra uma linha no journal.

## O tema de login

- **Config:** `sounds=on|off` (padrão `on`), no `config` do tema.
- **Arquivos:** os sons de `intro`, `move`, `confirm`, `error` e `close` ficam no tema.
- **Volume:** vem de `/run/yorha-os/sound.state`. Sem o arquivo, 30%.
- **Sem servidor de áudio** (S3): fica calado, sem erro na tela.

## Opção do usuário

`sound.bootLogin` (data-model.md) é copiado pro `sound.json` pelo shell. O `sounds` do tema segue o que
o módulo instalou e não muda pela sessão.

## Garantias

- O login não espera o som (SC-013: ≤ 0,1 s de diferença no `boot-timing`).
- O PipeWire da sessão sobe sem erro, com ou sem o som.
- Depois do `uninstall`, sobra só o que era do usuário (o `sound.json`).
