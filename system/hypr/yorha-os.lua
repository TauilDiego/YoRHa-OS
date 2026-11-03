-- YoRHa-OS in Hyprland: the keys, layer rules and autostart the shell needs (spec 014,
-- contracts/encaixe.md). Include it with the one line `yorha` prints, at the top of
-- ~/.config/hypr/hyprland.lua; it is read through ".../current/", so it follows every update.
-- It writes nothing and sets no window rules of the person's.
-- YORHA_MOD, a global set on a line before the include, changes the modifier (default SUPER).

-- The yorha command of the version in use, found from this file's own path (".../current/system/hypr/"),
-- so the keys work even when ~/.local/bin is not in Hyprland's PATH.
local here = (debug and debug.getinfo(1, "S").source or ""):gsub("^@", ""):match("^(.*)/[^/]*$")
local yorha = here and (here .. "/../../bin/yorha")
    or (os.getenv("HOME") .. "/.local/share/yorha-os/current/bin/yorha")
local mod = YORHA_MOD or "SUPER"
local function ipc(args)
  return hl.dsp.exec_cmd(yorha .. " ipc " .. args)
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
hl.bind(mod .. " + Escape", ipc("pause toggle"))
hl.bind(mod .. " + I", ipc("settings toggle"))
hl.bind(mod .. " + W", ipc("wallpaper picker toggle"))
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
