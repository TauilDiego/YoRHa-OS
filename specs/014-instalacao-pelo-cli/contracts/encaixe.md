# Contrato: o arquivo de encaixe do Hyprland

**Arquivo:** `system/hypr/yorha-os.lua`. É lido pelo `current`, então acompanha os updates.

**A linha que a pessoa inclui** no começo do `~/.config/hypr/hyprland.lua`:

```lua
pcall(dofile, os.getenv("HOME") .. "/.local/share/yorha-os/current/system/hypr/yorha-os.lua")
```

**O que o arquivo faz:**
- `hl.on("hyprland.start", …)` roda `yorha shell start`, uma vez;
- os atalhos chamam só o `yorha ipc …` (nunca um caminho de versão):
  | Tecla | Ação |
  |---|---|
  | SUPER+Escape | `pause toggle` |
  | SUPER+I | `settings toggle` |
  | SUPER+T | `wallpaper picker toggle` (não o SUPER+W, que fecha a janela em muitas configs; decisão do dono, 03.11) |
  | SUPER+N | `notify toggle` |
  | SUPER+CTRL+N | `notify dnd toggle` |
- as teclas de volume, microfone (`wpctl`) e brilho (`brightnessctl`); o OSD do shell mostra a mudança;
- `layer_rule` com `no_anim` pra `yorha-notify`, `yorha-osd` e `yorha-popup`.
- `quirks:skip_non_kms_dmabuf_formats = false` (num `pcall`): o padrão de antes da 0.57.0 do Hyprland,
  que o upstream desfez depois (#16731). Com ele ligado, numa GPU cujos planos só aceitam XRGB8888, os
  clientes GL recebem buffers sem alfa e as camadas transparentes (a barra, as notificações) saem pretas.
  Uma linha da pessoa depois do include vence.

O arquivo não escreve em nada e não define regras de janela da pessoa.
