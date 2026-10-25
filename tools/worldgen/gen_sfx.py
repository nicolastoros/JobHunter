"""Synthesises the game's sound effects (44.1 kHz, 16-bit stereo WAV) into assets/audio/sfx.
Layered synthesis: pitched bodies, noise transients, inharmonic bells, filtered sweeps, soft saturation
and a stereo convolution reverb. No samples needed; run again to tweak any sound."""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
OUT = "C:/Users/nicol/OneDrive/Documentos/JobHunter/assets/audio/sfx"
rng = np.random.default_rng(7)


# ---------------------------------------------------------------- building blocks
def t_(d):
    return np.arange(int(SR * d)) / SR


def env(d, a=0.005, decay=0.2, sustain=0.0, curve=4.0):
    """Attack then exponential-ish decay to `sustain` over the whole length."""
    t = t_(d)
    e = np.minimum(t / max(a, 1e-4), 1.0)
    tail = np.clip((t - a) / max(decay, 1e-4), 0, None)
    return e * (sustain + (1 - sustain) * np.exp(-curve * tail))


def sweep(f0, f1, d, shape="exp", wave="sine"):
    t = t_(d)
    if shape == "exp":
        f = f0 * (f1 / f0) ** (t / d)
    else:
        f = f0 + (f1 - f0) * t / d
    ph = 2 * np.pi * np.cumsum(f) / SR
    if wave == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1.0) - 1
    if wave == "tri":
        return 2 * np.abs(2 * ((ph / (2 * np.pi)) % 1.0) - 1) - 1
    return np.sin(ph)


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, min(hi, SR / 2 - 100)], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, btype="low", fs=SR, output="sos"), x)


def hp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, btype="high", fs=SR, output="sos"), x)


def swept_bp(x, f0, f1, q=3.0):
    """Band-pass whose centre glides from f0 to f1 (state-variable filter)."""
    n = len(x)
    fc = f0 * (f1 / f0) ** (np.arange(n) / n)
    out = np.zeros(n)
    low = band = 0.0
    damp = 1.0 / q
    for i in range(n):
        f = 2 * np.sin(np.pi * fc[i] / SR)
        high = x[i] - low - damp * band
        band += f * high
        low += f * band
        out[i] = band
    return out


def bell(freq, d, partials=((1, 1.0), (2.76, 0.5), (5.4, 0.25), (8.93, 0.12)), decay=1.0):
    t = t_(d)
    y = np.zeros_like(t)
    for k, (ratio, amp) in enumerate(partials):
        y += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t * (3 + k * 2.5) / decay)
    return y * np.minimum(t / 0.002, 1)


def pad(freqs, d, detune=0.006, cutoff=1800):
    t = t_(d)
    y = np.zeros_like(t)
    for f in freqs:
        for dt in (-detune, 0, detune):
            y += sweep(f * (1 + dt), f * (1 + dt), d, wave="saw") * 0.2
    return lp(y, cutoff, 4)


def mix(*parts):
    n = max(len(p) for p, _o in parts)
    y = np.zeros(n)
    for p, off in parts:
        o = int(off * SR)
        if o >= n:
            continue
        m = min(len(p), n - o)
        y[o:o + m] += p[:m]
    return y


def pad_to(x, d):
    n = int(SR * d)
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:max(n, len(x))]


def sat(x, drive=1.5):
    return np.tanh(x * drive) / np.tanh(drive)


_IR = {}


def reverb(x, size=1.0, mix_=0.25, bright=6000):
    """Stereo convolution reverb with a synthetic decaying-noise impulse response."""
    key = (size, bright)
    if key not in _IR:
        d = 0.25 + 1.4 * size
        t = t_(d)
        decay = np.exp(-t * 6.0 / d)
        irs = []
        for _ in range(2):
            ir = noise(d) * decay
            ir = lp(ir, bright, 2)
            ir[: int(0.008 * SR)] *= 0.2         # pre-delay feel
            irs.append(ir / np.sqrt(np.sum(ir ** 2)))
        _IR[key] = irs
    x = np.concatenate([x, np.zeros(len(_IR[key][0]))])
    wet = [signal.fftconvolve(x, ir)[: len(x)] for ir in _IR[key]]
    return np.stack([x * (1 - mix_) + w * mix_ * 1.4 for w in wet], axis=1)


def widen(st, ms=0.0007):
    """A hair of inter-channel delay for width."""
    k = int(ms * SR)
    st = st.copy()
    st[:, 1] = np.concatenate([np.zeros(k), st[:-k, 1]]) if k else st[:, 1]
    return st


def save(name, st, gain=0.9):
    if st.ndim == 1:
        st = np.stack([st, st], axis=1)
    # cut the silent end of the reverb tail (-60 dB), fade out, normalise, write 16-bit
    level = np.max(np.abs(st), axis=1)
    loud = np.nonzero(level > np.max(level) * 0.001)[0]
    if len(loud):
        st = st[: min(len(st), loud[-1] + int(0.02 * SR))]
    n = len(st)
    fade = int(min(0.03 * SR, n // 4))
    st[-fade:] *= np.linspace(1, 0, fade)[:, None]
    peak = np.max(np.abs(st)) or 1.0
    st = st / peak * gain
    os.makedirs(OUT, exist_ok=True)
    wavfile.write(os.path.join(OUT, name + ".wav"), SR, (st * 32767).astype(np.int16))
    print("%-16s %.2fs" % (name, n / SR))


# ---------------------------------------------------------------- the sounds
def swing():
    d = 0.24
    body = swept_bp(noise(d), 500, 2600, q=2.5) * env(d, 0.03, 0.12, curve=5)
    air = hp(noise(d), 3000) * env(d, 0.02, 0.07) * 0.25
    save("swing", widen(reverb(body + air, 0.3, 0.12)), 0.6)


def hit(crit=False):
    d = 0.5 if crit else 0.32
    thump = sweep(150, 48, 0.16) * env(0.16, 0.001, 0.08, curve=4) * 1.1
    click = hp(noise(0.012), 2500) * env(0.012, 0.0005, 0.004) * 0.9
    crunch = bp(noise(0.09), 700, 2600) * env(0.09, 0.001, 0.03) * 0.8
    y = mix((thump, 0), (click, 0), (crunch, 0.002))
    if crit:
        ring = bell(1180, 0.6, ((1, 1), (1.58, 0.7), (2.24, 0.5), (2.98, 0.35), (4.1, 0.2)), decay=0.5) * 0.45
        slice_ = swept_bp(noise(0.15), 4000, 1200, 4) * env(0.15, 0.002, 0.06) * 0.5
        y = mix((sat(y, 2.2), 0), (ring, 0.004), (slice_, 0))
        save("crit", widen(reverb(pad_to(y, d), 0.6, 0.22)), 0.95)
    else:
        save("hit", reverb(pad_to(sat(y, 1.8), d), 0.25, 0.1), 0.85)


def hurt():
    d = 0.45
    whump = sweep(220, 70, 0.22) * env(0.22, 0.002, 0.1) * 1.0
    grit = bp(noise(0.18), 200, 1200) * env(0.18, 0.003, 0.06) * 0.7
    tone = sweep(330, 160, 0.25, wave="tri") * env(0.25, 0.01, 0.12) * 0.25
    y = sat(mix((whump, 0), (grit, 0), (tone, 0.01)), 2.5)
    save("hurt", reverb(pad_to(y, d), 0.35, 0.15), 0.85)


def mon_die():
    d = 0.8
    squelch = swept_bp(noise(0.35), 900, 180, 3) * env(0.35, 0.005, 0.2) * 1.2
    wob = 1 + 0.5 * np.sin(2 * np.pi * 18 * t_(0.35))
    drop = sweep(380, 60, 0.4) * env(0.4, 0.004, 0.25) * 0.6
    poof = lp(noise(0.25), 1500) * env(0.25, 0.01, 0.1) * 0.4
    y = mix((squelch * wob, 0), (drop, 0), (poof, 0.05))
    save("monster_die", widen(reverb(pad_to(sat(y, 1.6), d), 0.5, 0.2)), 0.8)


def coin():
    d = 0.7
    a = bell(2093, 0.5, ((1, 1), (2.0, 0.3), (3.01, 0.2), (4.2, 0.1)), 0.35)
    b = bell(2637, 0.5, ((1, 1), (2.0, 0.3), (3.01, 0.2), (4.2, 0.1)), 0.35)
    tick = hp(noise(0.006), 5000) * 0.5
    y = mix((tick, 0), (a, 0), (tick, 0.06), (b, 0.06))
    save("coin", widen(reverb(pad_to(y, d), 0.4, 0.25)), 0.55)


NOTE = {"C5": 523.25, "E5": 659.25, "G5": 783.99, "C6": 1046.5, "E6": 1318.5, "G6": 1568.0, "B5": 987.77, "D6": 1174.7,
        "A5": 880.0, "C4": 261.63, "E4": 329.63, "G4": 392.0, "C3": 130.81, "G3": 196.0, "C7": 2093.0}


def arp(notes, step, d_note=1.0, amp=0.6):
    return mix(*[(bell(NOTE[n], d_note, decay=0.9) * amp, i * step) for i, n in enumerate(notes)])


def loot(kind):
    if kind == "rare":
        y = arp(["C6", "E6", "G6"], 0.07, 0.9, 0.5)
        save("loot_rare", widen(reverb(pad_to(y, 1.4), 0.8, 0.3)), 0.6)
    elif kind == "epic":
        y = mix((arp(["G5", "C6", "E6", "G6", "C7"], 0.065, 1.0, 0.5), 0),
                (pad([NOTE["C4"], NOTE["G4"], NOTE["E5"]], 1.4) * env(1.4, 0.15, 0.9, curve=2) * 0.35, 0.05))
        save("loot_epic", widen(reverb(pad_to(y, 2.2), 1.0, 0.35)), 0.7)
    else:
        shimmer = swept_bp(noise(1.2), 2000, 9000, 6) * env(1.2, 0.3, 0.8, curve=2) * 0.25
        choir = pad([NOTE["C3"], NOTE["G3"], NOTE["C4"], NOTE["E4"], NOTE["G4"]], 2.6, 0.008, 2200) * env(2.6, 0.25, 2.0, curve=1.8) * 0.5
        y = mix((choir, 0), (arp(["C5", "E5", "G5", "C6", "E6", "G6", "C7"], 0.08, 1.2, 0.45), 0.15), (shimmer, 0.3))
        save("loot_legendary", widen(reverb(pad_to(y, 3.6), 1.4, 0.4)), 0.8)


def level_up():
    rise = swept_bp(noise(0.6), 300, 6000, 4) * env(0.6, 0.4, 0.2) * 0.35
    y = mix((rise, 0), (arp(["C5", "E5", "G5", "C6", "E6", "G6"], 0.06, 1.2, 0.5), 0.3),
            (pad([NOTE["C4"], NOTE["E4"], NOTE["G4"], NOTE["C5"]], 1.6) * env(1.6, 0.05, 1.2, curve=2) * 0.4, 0.3))
    save("level_up", widen(reverb(pad_to(y, 2.8), 1.2, 0.35)), 0.8)


def potion():
    d = 0.75
    parts = [(lp(noise(0.12), 600) * env(0.12, 0.005, 0.05) * 0.6, 0)]   # uncork
    t0 = 0.12
    for i in range(7):
        f = rng.uniform(260, 520)
        dd = rng.uniform(0.05, 0.09)
        parts.append((sweep(f, f * 2.3, dd) * env(dd, 0.004, 0.03) * 0.5, t0))
        t0 += rng.uniform(0.05, 0.08)
    sparkle = arp(["E6", "G6", "C7"], 0.05, 0.6, 0.15)
    y = mix(*parts, (sparkle, 0.45))
    save("potion", widen(reverb(pad_to(y, d + 0.5), 0.4, 0.2)), 0.65)


def creak(d, f=90):
    t = t_(d)
    fm = f * (1 + 0.25 * np.sin(2 * np.pi * 3.1 * t) + 0.1 * np.sin(2 * np.pi * 7.3 * t))
    ph = 2 * np.pi * np.cumsum(fm) / SR
    pulses = (np.sin(ph) > 0.92).astype(float)
    return bp(pulses + 0.05 * noise(d), 300, 2500) * env(d, 0.05, d * 0.6, 0.3, 2)


def chest():
    thunk = mix((sweep(120, 70, 0.12) * env(0.12, 0.001, 0.05) * 0.9, 0), (bp(noise(0.05), 400, 1800) * env(0.05, 0.001, 0.02) * 0.5, 0))
    y = mix((creak(0.45, 70), 0), (thunk, 0.42), (arp(["C6", "G6", "C7"], 0.05, 0.8, 0.25), 0.5))
    save("chest", widen(reverb(pad_to(y, 1.5), 0.6, 0.25)), 0.75)


def door():
    latch = mix((hp(noise(0.02), 2000) * env(0.02, 0.0005, 0.006) * 0.8, 0), (sweep(900, 600, 0.03) * env(0.03, 0.001, 0.01) * 0.3, 0))
    y = mix((latch, 0), (creak(0.6, 55), 0.05))
    save("door", reverb(pad_to(y, 1.0), 0.7, 0.25), 0.6)


def ui_click():
    y = mix((np.sin(2 * np.pi * 1900 * t_(0.04)) * env(0.04, 0.0005, 0.012) * 0.6, 0), (hp(noise(0.005), 4000) * 0.4, 0))
    save("ui_click", reverb(pad_to(y, 0.12), 0.1, 0.08), 0.45)


def ui_open():
    y = mix((swept_bp(noise(0.22), 2500, 700, 2) * env(0.22, 0.03, 0.1), 0), (bell(1568, 0.3, decay=0.4) * 0.12, 0))
    save("ui_open", widen(reverb(pad_to(y, 0.45), 0.3, 0.15)), 0.45)


def horn():
    d = 1.6
    t = t_(d)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t)
    brass = np.zeros_like(t)
    for f, a in ((110, 1.0), (165, 0.7), (220, 0.4)):
        ph = 2 * np.pi * np.cumsum(f * vib) / SR
        brass += a * (2 * ((ph / (2 * np.pi)) % 1.0) - 1)
    cut = 400 + 2600 * np.minimum(t / 0.25, 1) * np.exp(-np.maximum(t - 0.6, 0) * 2)
    # time-varying low-pass in blocks
    out = np.zeros_like(brass)
    blk = 512
    zi = None
    for i in range(0, len(brass), blk):
        sos = signal.butter(2, float(cut[i]), btype="low", fs=SR, output="sos")
        if zi is None:
            zi = signal.sosfilt_zi(sos) * 0
        out[i:i + blk], zi = signal.sosfilt(sos, brass[i:i + blk], zi=zi)
    out *= env(d, 0.08, 1.2, 0.0, 2.2)
    drum = sweep(90, 40, 0.4) * env(0.4, 0.002, 0.25) * 0.8
    y = mix((sat(out * 0.5, 1.6), 0), (drum, 0), (drum, 0.35))
    save("horn", widen(reverb(pad_to(y, 2.4), 1.3, 0.35)), 0.8)


def skill():
    d = 0.6
    whoosh = swept_bp(noise(d), 300, 4000, 3) * env(d, 0.08, 0.3) * 0.8
    sparkle = sweep(600, 2400, 0.35, wave="tri") * env(0.35, 0.01, 0.2) * 0.15
    y = mix((whoosh, 0), (sparkle, 0.05), (bell(NOTE["G6"], 0.5, decay=0.5) * 0.2, 0.12))
    save("skill", widen(reverb(pad_to(y, 1.2), 0.8, 0.3)), 0.7)


def player_die():
    d = 2.2
    fall = sweep(220, 55, 1.2, wave="tri") * env(1.2, 0.02, 1.0, curve=2) * 0.5
    rumble = lp(noise(1.5), 180, 4) * env(1.5, 0.05, 1.2, curve=2) * 1.2
    y = mix((fall, 0), (rumble, 0), (pad([NOTE["C3"], 155.56, NOTE["G3"]], 1.8, 0.01, 900) * env(1.8, 0.3, 1.4, curve=2) * 0.4, 0.2))
    save("player_die", widen(reverb(pad_to(y, d), 1.4, 0.4)), 0.8)


def quest():
    y = mix((arp(["G5", "C6", "E6"], 0.09, 1.0, 0.5), 0), (arp(["G6"], 0.1, 1.2, 0.55), 0.3),
            (pad([NOTE["C4"], NOTE["E4"], NOTE["G4"]], 1.3) * env(1.3, 0.05, 1.0, curve=2) * 0.3, 0.25))
    save("quest", widen(reverb(pad_to(y, 2.0), 1.0, 0.3)), 0.7)


if __name__ == "__main__":
    swing(); hit(False); hit(True); hurt(); mon_die(); coin()
    loot("rare"); loot("epic"); loot("legendary"); level_up(); potion(); chest(); door()
    ui_click(); ui_open(); horn(); skill(); player_die(); quest()
