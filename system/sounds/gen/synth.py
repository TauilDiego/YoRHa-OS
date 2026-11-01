#!/usr/bin/env python3
"""YoRHa-OS UI sounds (spec 013): original recipes, numpy + wave only, 48 kHz mono 16-bit WAV.

Usage: synth.py <outdir> [--freq-scale 0.5]

The numbers (brightness, length, loudness ranking) describe the character of a game-like UI, as
measured in the spec's sound study; waveforms and envelopes are ours and no game audio is used.
Each sound has its own fixed seed, so changing one recipe leaves the others byte-identical.
--freq-scale scales every frequency (0.5 is the "soft" variant for small laptop speakers).
"""
import os
import sys
import wave
import zlib

import numpy as np

SR = 48000
FS = 1.0          # frequency scale (--freq-scale)
rng = None        # reseeded per sound


def t(ms):
    return np.arange(int(SR * ms / 1000)) / SR


def env_exp(tt, att_ms, tau_ms):
    a = np.clip(tt / (att_ms / 1000), 0, 1)
    return a * np.exp(-tt / (tau_ms / 1000))


def sine(f, tt):
    return np.sin(2 * np.pi * f * FS * tt)


def silence(ms):
    return np.zeros(int(SR * ms / 1000))


def place(buf, sig, at_ms, gain_db=0.0):
    i = int(SR * at_ms / 1000)
    n = min(len(sig), len(buf) - i)
    buf[i:i + n] += sig[:n] * 10 ** (gain_db / 20)


def hp_noise(n, fc=6000):
    x = rng.standard_normal(n)
    X = np.fft.rfft(x)
    X *= np.fft.rfftfreq(n, 1 / SR) > fc * FS
    return np.fft.irfft(X, n)


def lp_noise(n, fc=800):
    x = rng.standard_normal(n)
    X = np.fft.rfft(x)
    X *= np.fft.rfftfreq(n, 1 / SR) < fc
    return np.fft.irfft(X, n)


def sweep_noise(ms, f0, f1, width=2500):
    """White noise through a band-pass whose centre glides from f0 to f1 (by 10 ms blocks)."""
    n = int(SR * ms / 1000)
    x = rng.standard_normal(n + 960)
    out = np.zeros(n + 960)
    blk, hop = 960, 480
    win = np.hanning(blk)
    ff = np.fft.rfftfreq(blk, 1 / SR)
    for i in range(0, n, hop):
        fc = (f0 + (f1 - f0) * min(i / n, 1.0)) * FS
        S = np.fft.rfft(x[i:i + blk] * win)
        S *= np.exp(-((ff - fc) / (width * FS)) ** 2)
        out[i:i + blk] += np.fft.irfft(S, blk)
    return out[:n]


def norm(x, peak_db):
    return x / np.abs(x).max() * 10 ** (peak_db / 20)


def fade_out(x, ms=5):
    n = min(len(x), int(SR * ms / 1000))
    x[-n:] *= np.linspace(1, 0, n)
    return x


# --- the tick family: cursor, value change, OSD step -------------------------------------------

def ping(f, ms=40, tau=5):
    tt = t(ms)
    return sine(f, tt) * env_exp(tt, 0.5, tau)


def move():
    b = silence(120)
    tt = t(40)
    click = hp_noise(len(tt)) * env_exp(tt, 0.3, 1.2)
    p = ping(2050) + 0.5 * sine(8300, tt) * env_exp(tt, 0.3, 3)
    place(b, 0.6 * click / np.abs(click).max() + p, 0)
    place(b, ping(2050), 80, -14)                       # faint echo
    return norm(b, -12)


def back():                                             # invented: lower, no echo
    b = silence(60)
    tt = t(40)
    click = hp_noise(len(tt), 4000) * env_exp(tt, 0.3, 1.0)
    place(b, 0.5 * click / np.abs(click).max() + ping(1500, tau=6), 0)
    return norm(b, -12)


def error():                                            # invented: a low double tick
    b = silence(170)
    for at in (0, 90):
        place(b, ping(900, 50, 9), at)
        place(b, 0.3 * ping(2700, 30, 3), at)
    return norm(b, -12)


def tab():                                              # a short run of bright clicks
    b = silence(110)
    tt = t(14)
    for k, at in enumerate((0, 24, 48)):
        c = hp_noise(len(tt), 7000) * env_exp(tt, 0.2, 1.5) + 0.6 * sine(6200 + 900 * k, tt) * env_exp(tt, 0.2, 2.5)
        place(b, c, at, -3 * k)
    return norm(b, -12)


def typing():
    b = silence(30)
    tt = t(12)
    place(b, (hp_noise(len(tt), 8000) * 0.5 + sine(13100, tt)) * env_exp(tt, 0.3, 2.2), 0)
    return norm(b, -16)


# --- the chime family: confirm, notifications, the session -------------------------------------

def shimmer(ms, tau, att=20):
    tt = t(ms)
    s = sum(g * sine(f, tt) for f, g in ((11175, 1), (12660, 0.3), (14470, 0.3)))
    return s * env_exp(tt, att, tau)


def confirm():
    b = silence(450)
    place(b, shimmer(420, 80), 0)
    place(b, hp_noise(len(t(10))) * env_exp(t(10), 0.3, 2) * 0.5, 0)
    p = t(60)
    place(b, sine(1485, p) * env_exp(p, 3, 15), 110, -6)
    return norm(fade_out(b), -10)


def notify():
    b = silence(800)
    place(b, shimmer(780, 150), 0)
    tt = t(780)
    place(b, sine(4970, tt) * env_exp(tt, 15, 220), 0, -8)
    place(b, sine(9300, tt) * env_exp(tt, 10, 120), 0, -10)
    place(b, hp_noise(len(t(10))) * env_exp(t(10), 0.3, 2) * 0.5, 0)
    return norm(fade_out(b, 20), -8)


def notify_critical():                                  # the big chime, twice more, with a mid tone
    b = silence(1150)
    for k, at in enumerate((0, 170, 340)):
        place(b, shimmer(700, 130), at, -4 * k)
        tt = t(240)
        place(b, sine(2350, tt) * env_exp(tt, 4, 60), at, -6 - 4 * k)
    tt = t(1100)
    place(b, sine(4970, tt) * env_exp(tt, 15, 300), 0, -10)
    return norm(fade_out(b, 30), -8)


def session_start():                                    # the long confirm, with a soft rise first
    b = silence(1000)
    w = sweep_noise(300, 2500, 9000) * env_exp(t(300), 200, 400)
    place(b, w / np.abs(w).max(), 0, -10)
    place(b, shimmer(760, 180, 25), 240)
    tt = t(700)
    place(b, sine(4970, tt) * env_exp(tt, 20, 200), 240, -12)
    return norm(fade_out(b, 30), -10)


def dialog():                                           # two notes, a rising fifth
    b = silence(450)
    for at in (30, 130):
        tt = t(45)
        place(b, (sine(1800, tt) + 0.25 * sine(9000, tt)) * env_exp(tt, 3, 14), at)
    tt = t(160)
    place(b, (sine(2650, tt) + 0.25 * sine(13250, tt)) * env_exp(tt, 3, 55), 160)
    return norm(fade_out(b), -10)


# --- the noise family: menus and the boot ------------------------------------------------------

def whoosh(ms, f0, f1, att, tau):
    w = sweep_noise(ms, f0, f1) * env_exp(t(ms), att, tau)
    return fade_out(w, 15)


def open_():
    return norm(whoosh(250, 3000, 12000, 40, 110), -12)


def close():
    return norm(whoosh(230, 12000, 3000, 25, 90), -12)


def granular(ms, f0, f1, att, tau, gate_hz=25):
    w = sweep_noise(ms, f0, f1) * env_exp(t(ms), att, tau)
    tt = t(ms)
    gate = (rng.random(int(ms / 1000 * gate_hz) + 1) > 0.35).astype(float)
    g = np.repeat(gate, int(SR / gate_hz))[:len(tt)]
    g = np.convolve(g, np.ones(96) / 96, mode="same")     # 2 ms edges, no clicks
    body = lp_noise(len(tt), 800) * env_exp(tt, att, tau)
    return w * (0.35 + 0.65 * g) + 0.3 * body / np.abs(body).max() * np.abs(w).max()


def boot_start():                                       # starts with 20 ms of silence (research S4)
    b = silence(1250)
    place(b, granular(900, 2500, 9500, 140, 300), 20)
    place(b, shimmer(420, 90), 760, -6)
    return norm(fade_out(b, 30), -8)


def intro():                                            # the login screen appears
    b = silence(800)
    place(b, granular(520, 3000, 10000, 90, 180), 0)
    place(b, shimmer(300, 70), 420, -8)
    return norm(fade_out(b, 20), -10)


SOUNDS = {
    "move": move, "back": back, "error": error, "tab": tab, "typing": typing,
    "confirm": confirm, "notify": notify, "notify-critical": notify_critical,
    "session-start": session_start, "dialog": dialog,
    "open": open_, "close": close, "boot-start": boot_start, "intro": intro,
}
# The boot sound at fixed levels (research S4): gain = level², the curve of the volume slider.
BOOT_LEVELS = (10, 20, 30, 40, 50, 70, 100)


def save(path, x):
    x = np.clip(x, -1, 1)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(np.round(x * 32767).astype("<i2").tobytes())


def main():
    global FS, rng
    if len(sys.argv) < 2:
        sys.exit("uso: synth.py <pasta> [--freq-scale 0.5]")
    out = sys.argv[1]
    if sys.argv[2:4] and sys.argv[2] == "--freq-scale":
        FS = float(sys.argv[3])
    os.makedirs(os.path.join(out, "boot"), exist_ok=True)
    for name, fn in SOUNDS.items():
        rng = np.random.default_rng(zlib.crc32(name.encode()))
        x = fn()
        save(os.path.join(out, name + ".wav"), x)
        peak = 20 * np.log10(np.abs(x).max())
        print(f"{name:16s} {len(x) * 1000 / SR:6.0f} ms  pico {peak:6.1f} dBFS")
        if name == "boot-start":
            for lv in BOOT_LEVELS:
                save(os.path.join(out, "boot", f"boot-start-{lv}.wav"), x * (lv / 100) ** 2)
            print(f"{'boot/boot-start-N':16s} níveis {', '.join(map(str, BOOT_LEVELS))}")


if __name__ == "__main__":
    main()
