-- YoRHa-Shell in Hyprland: the keys, layer rules and autostart the shell needs (spec 014,
-- contracts/encaixe.md). Include it with the one line `yorha` prints, at the top of
-- ~/.config/hypr/hyprland.lua; it is read through ".../current/", so it follows every update.
-- It writes nothing and sets no window rules of the person's.
-- YORHA_MOD, a global set on a line before the include, changes the modifier (default SUPER).

-- The yorha command of the version in use, found from this file's own path (".../current/system/hypr/"),
-- so the keys work even when ~/.local/bin is not in Hyprland's PATH.
local here = (debug and debug.getinfo(1, "S").source or ""):gsub("^@", ""):match("^(.*)/[^/]*$")
local yorha = here and (here .. "/../../bin/yorha")
    or (os.getenv("HOME") .. "/.local/share/yorha-shell/current/bin/yorha")
local mod = YORHA_MOD or "SUPER"
local function ipc(args)
  return hl.dsp.exec_cmd(yorha .. " ipc " .. args)
end
-- The menu keys go to the shell as global shortcuts (hyprland_global_shortcuts_v1, "yorha:<name>"):
-- no process starts, so the menu is up right after the key. Opening it also puts Hyprland in the
-- submap "yorha-menu" until the menu has the keyboard (the shell ends it, or it ends by itself after
-- 1.5 s): there, the keys typed meanwhile go to the shell as "yorha:key-<k>" and every other key is
-- swallowed, so nothing typed right after the shortcut reaches the window under the menu; the shell
-- hands those keys to the menu. A Hyprland without these calls falls back to the IPC.
local menu_keys = {}
for c in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
  menu_keys[#menu_keys + 1] = { c, c }
  menu_keys[#menu_keys + 1] = { "SHIFT + " .. c, "shift-" .. c }
end
for c in ("0123456789"):gmatch(".") do menu_keys[#menu_keys + 1] = { c, c } end
for _, k in ipairs({ "space", "minus", "period", "Return", "KP_Enter", "BackSpace", "Tab", "Escape", "Up", "Down" }) do
  menu_keys[#menu_keys + 1] = { k, k }
end
local capture = pcall(function()
  assert(hl.dsp.global and hl.dsp.submap and hl.define_submap and hl.timer and hl.get_layers)
  hl.define_submap("yorha-menu", function()
    for _, k in ipairs(menu_keys) do hl.bind(k[1], hl.dsp.global("yorha:key-" .. k[2])) end
    hl.bind(mod .. " + Escape", hl.dsp.global("yorha:pause"))
    hl.bind(mod .. " + I", hl.dsp.global("yorha:settings"))
    hl.bind("catchall", hl.dsp.no_op())
  end)
end)
YORHA_MENU_SEQ = YORHA_MENU_SEQ or 0
local function menu_open()
  for _, l in ipairs(hl.get_layers() or {}) do
    if l.namespace == "yorha-popup" then return true end
  end
  return false
end
local function shortcut(name, args)
  local ok, d = pcall(function() return hl.dsp.global("yorha:" .. name) end)
  if not (ok and d) then return ipc(args) end
  if not capture then return d end
  return function()
    hl.dispatch(d)
    local open = true
    pcall(function() open = menu_open() end)
    if open then return end
    hl.dispatch(hl.dsp.submap("yorha-menu"))
    YORHA_MENU_SEQ = YORHA_MENU_SEQ + 1
    local seq = YORHA_MENU_SEQ
    hl.timer(function()
      if seq == YORHA_MENU_SEQ and hl.get_current_submap() == "yorha-menu" then
        hl.dispatch(hl.dsp.submap("reset"))
      end
    end, { timeout = 1500, type = "oneshot" })
  end
end

-- Transparent layers (the bar, notifications, OSD, popups) need GL buffers with alpha. Hyprland
-- 0.57.0 turned quirks:skip_non_kms_dmabuf_formats on by default (hyprwm/Hyprland#15803): it then
-- offers clients only the formats the display planes can scan out, and on a GPU whose planes take
-- just XRGB8888 (e.g. virtio-gpu) every GL client gets an opaque buffer, so the bar's empty area is
-- drawn black instead of the wallpaper. Upstream reverted that default (#16731, after 0.57.0); this
-- keeps the old default until then. A person's own setting, later in their config, still wins.
-- pcall: an option this Hyprland does not know must not stop the rest of this file.
pcall(hl.config, { quirks = { skip_non_kms_dmabuf_formats = false } })

hl.on("hyprland.start", function()
  hl.exec_cmd(yorha .. " shell start")
end)

-- The menus (spec 007/013), the settings (003), the wallpaper picker (004), the text log and do not
-- disturb (008).
hl.bind(mod .. " + Escape", shortcut("pause", "pause toggle"))
hl.bind(mod .. " + I", shortcut("settings", "settings toggle"))
-- T, not W: SUPER+W closes the focused window in many setups.
hl.bind(mod .. " + T", ipc("wallpaper picker toggle"))
hl.bind(mod .. " + N", ipc("notify toggle"))
hl.bind(mod .. " + CTRL + N", ipc("notify dnd toggle"))

-- Volume, microphone and brightness keys; the shell's OSD shows the change (spec 008).
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 2%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- The shell draws its own fades and sweeps (008) and the menus' grid and triangles (013).
hl.layer_rule({ name = "yorha-notify-noanim", match = { namespace = "^yorha-notify$" }, no_anim = true })
hl.layer_rule({ name = "yorha-osd-noanim", match = { namespace = "^yorha-osd$" }, no_anim = true })
hl.layer_rule({ name = "yorha-popup-noanim", match = { namespace = "^yorha-popup$" }, no_anim = true })
