# Contrato: serviços (`shell/services/`, singletons)

A UI lê dados **só** destes serviços. Cada um usa as fixtures do seu domínio quando
`Fixtures` tiver esse domínio (research R4); senão, usa o dado real.

| Serviço | Expõe | Fonte real | Domínio da fixture |
|---|---|---|---|
| `Clock` | `date` | `SystemClock` (segundos) | `clock` |
| `Telemetry` | `cpu: Reading`, `mem: Reading` | `/proc/stat`, `/proc/meminfo` a cada 2 s (R3) | `cpu`, `mem` |
| `Audio` | `vol: Reading` | `Pipewire.defaultAudioSink` | `volume` |
| `Battery` | `bat: Reading` | `UPower.displayDevice` | `battery` |
| `Compositor` | `workspacesFor(monitorName)` → lista de `Workspace`, `activeTitle`, `focus(id)` | `Quickshell.Hyprland` (R1) | `workspaces`, `activeWindow` |
| `Settings` | `uiScale`, `barHeight`, `vignette` | `config/defaults.json` + `$XDG_CONFIG_HOME/rien-os/shell.json` | — |
| `Fixtures` | `active`, `source`, `data`, `load(path)`, `clear()` | `NIER_FIXTURES` | — |

Os formatos de `Reading` e `Workspace` estão em `../data-model.md`.

**Regras:**
- Uma leitura que falha nunca lança erro na UI: ela vira `value: 0` (ou `available: false` para
  a bateria).
- **Só o `Compositor` importa `Quickshell.Hyprland`.** Trocar pelo Niri (S5) = um novo
  `Compositor`.
- Com a fixture `workspaces` ativa, `focus(id)` só atualiza o estado fixo, sem mexer no
  compositor real. Pra testar o clique de verdade (SC-003), use fixtures sem o domínio
  `workspaces`.
