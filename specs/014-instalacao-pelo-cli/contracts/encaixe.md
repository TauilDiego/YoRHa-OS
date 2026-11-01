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
  | SUPER+W | `wallpaper picker toggle` |
  | SUPER+N | `notify toggle` |
  | SUPER+CTRL+N | `notify dnd toggle` |
- as teclas de volume, microfone (`wpctl`) e brilho (`brightnessctl`); o OSD do shell mostra a mudança;
- `layer_rule` com `no_anim` pra `yorha-notify`, `yorha-osd` e `yorha-popup`.

O arquivo não escreve em nada e não define regras de janela da pessoa.
