"""Synthesise a "Code" bed for Lemna: a loop that is periodic by construction (every layer is built on a circle of
exactly LOOP s, so its end runs into its head with no seam and no crossfade).

    synth_code.py OUT.wav [--loop 90] [--seed 1999] [--rain RAIN.wav] [--layers glass,fizz,hum,hiss] [--rate 35]
                  [--glass-lo 2500] [--glass-hi 7000] [--glass-tilt 0] [--tau-lo 3] [--tau-hi 10] [--fizz-lo 5000]
                  [--glass-db 0] [--fizz-db -13] [--hum-db -17] [--hiss-db -21] [--rain-db 0] [--target -26]

Layers, from the film's brief as its sound designer told it ("electrical and wet at the same time"; about 70 % of
the code made in MetaSynth, whose image synth turns each pixel into a sine oscillator, height = pitch, brightness =
level, colour = pan; synthetic sounds layered with water dripping into a barrel):
  glass  sine grains, the "pixels": RATE a second (Poisson), GLASS_LO-GLASS_HI log-uniform (2.5-7 kHz), GLASS_TILT dB an octave above GLASS_LO, each rising 5-25 % like a drop's
         chirp, decaying in TAU_LO-TAU_HI ms (3-10), level log-normal (sd 4 dB), panned at random (equal power), then a short room
         (RT60 0.7 s, 0.8-9 kHz, decorrelated per channel, circular convolution) for the barrel.
  fizz   a fused trickle: 250 noise ticks a second, 1.5 ms, high-passed at 5 kHz, through the same room.
  hum    the electricity: a 55 Hz series, harmonics 1-10 weighted to 110-330 Hz, with narrow noise around them; each
         frequency a whole number of cycles in the loop.
  hiss   a faint noise floor, 3-12 kHz, falling 3 dB an octave.
  rain   (--rain) a decoded 90 s loop laid under the rest, already seamless.
Every layer is set to its dB relative to the glass layer's loudness (BS.1770 on the mono mix), the mix high-passed at
80 Hz (zero phase, circular) and scaled to TARGET LUFS integrated (both channels, as bed.json's lufs), or lower if the sample peak would pass
-1 dBFS. Writes 32-bit float stereo WAV at 48 kHz; prints the parameters and the levels.
"""
import sys, struct, numpy as np

SR = 48000

def opts(a):
    o = dict(loop=90.0, seed=1999, rain=None, layers="glass,fizz,hum,hiss", rate=35.0, glass_lo=2500.0, glass_hi=7000.0, glass_tilt=0.0, tau_lo=3.0, tau_hi=10.0, fizz_lo=5000.0, glass_db=0.0, fizz_db=-13.0,
             hum_db=-17.0, hiss_db=-21.0, rain_db=0.0, target=-26.0)
    out = a[0]; i = 1
    while i < len(a):
        k = a[i].lstrip("-").replace("-", "_"); v = a[i + 1]; i += 2
        if k not in o: sys.exit(__doc__)
        o[k] = v if k in ("rain", "layers") else float(v)
    return out, o

def readf32(path):
    d = open(path, "rb").read(); pos = 12; fmt = data = None
    while pos < len(d) - 8:
        cid, sz = d[pos:pos + 4], struct.unpack("<I", d[pos + 4:pos + 8])[0]
        if cid == b"fmt ": fmt = struct.unpack("<HHIIHH", d[pos + 8:pos + 24])
        if cid == b"data": data = d[pos + 8:pos + 8 + sz]
        pos += 8 + sz + (sz & 1)
    assert fmt[0] in (3, 0xFFFE) and fmt[5] == 32 and fmt[2] == SR, fmt
    return np.frombuffer(data, "<f4").astype(np.float64).reshape(-1, fmt[1])

def writef32(path, x):
    x = np.asarray(x, "<f4"); n, ch = x.shape; b = x.tobytes()
    hdr = b"RIFF" + struct.pack("<I", 36 + len(b)) + b"WAVEfmt " + struct.pack("<IHHIIHH", 16, 3, ch, SR, SR * ch * 4, ch * 4, 32)
    open(path, "wb").write(hdr + b"data" + struct.pack("<I", len(b)) + b)

def kw_loudness_st(x):
    """BS.1770 integrated loudness over both channels (ffmpeg's ebur128, bed.json's lufs), the loop read as periodic."""
    from scipy import signal
    b1, a1 = [1.53512485958697, -2.69169618940638, 1.19839281085285], [1.0, -1.69065929318241, 0.73248077421585]
    b2, a2 = [1.0, -2.0, 1.0], [1.0, -1.99004745483398, 0.99007225036621]
    z = signal.lfilter(b2, a2, signal.lfilter(b1, a1, np.concatenate([x, x]), axis=0), axis=0)[len(x):]
    p = np.concatenate([[0], np.cumsum((z * z).sum(1))]); W, H = int(0.4 * SR), int(0.1 * SR)
    idx = np.arange(0, len(z) - W + 1, H); m = (p[idx + W] - p[idx]) / W
    L = lambda v: -0.691 + 10 * np.log10(v + 1e-30)
    m = m[L(m) > -70]; rel = L(m.mean()) - 10
    return L(m[L(m) > rel].mean())

def kw_loudness(mono):
    from scipy import signal
    b1, a1 = [1.53512485958697, -2.69169618940638, 1.19839281085285], [1.0, -1.69065929318241, 0.73248077421585]
    b2, a2 = [1.0, -2.0, 1.0], [1.0, -1.99004745483398, 0.99007225036621]
    z = signal.lfilter(b2, a2, signal.lfilter(b1, a1, np.concatenate([mono, mono])))[len(mono):]  # run in: periodic
    p = np.concatenate([[0], np.cumsum(z * z)]); W, H = int(0.4 * SR), int(0.1 * SR)
    idx = np.arange(0, len(z) - W + 1, H); m = (p[idx + W] - p[idx]) / W
    L = lambda v: -0.691 + 10 * np.log10(v + 1e-30)
    m = m[L(m) > -70]; rel = L(m.mean()) - 10
    return L(m[L(m) > rel].mean())

def band(N, lo, hi, slope_db_oct=0.0, order=2):
    """Zero-phase magnitude response on the rfft grid of N: Butterworth-like edges, a tilt in dB/octave from 1 kHz."""
    f = np.fft.rfftfreq(N, 1 / SR); f[0] = 1e-3
    g = np.ones_like(f)
    if lo: g *= 1 / np.sqrt(1 + (lo / f) ** (2 * order))
    if hi: g *= 1 / np.sqrt(1 + (f / hi) ** (2 * order))
    if slope_db_oct: g *= 10 ** (slope_db_oct * np.log2(f / 1000) / 20)
    g[0] = 0; return g

def circ_filter(x, g):
    return np.fft.irfft(np.fft.rfft(x, axis=0) * g[:, None], n=x.shape[0], axis=0)

def room(N, rng, rt60=0.7, length=1.5, predelay=0.012):
    n = int(length * SR); t = np.arange(n) / SR
    ir = np.zeros((N, 2))
    for c in range(2):
        h = rng.standard_normal(n) * np.exp(-6.9 * t / rt60)
        H = np.fft.rfft(h, n=2 * n) * band(2 * n, 800, 9000)[: n + 1]
        h = np.fft.irfft(H, n=2 * n)[:n]; h /= np.sqrt((h ** 2).sum())
        d = int(predelay * SR); ir[d:d + n, c] = h
    return np.fft.rfft(ir, axis=0)

def apply_room(x, R, wet=0.55):
    y = np.fft.irfft(np.fft.rfft(x, axis=0) * R, n=x.shape[0], axis=0)
    return np.sqrt(1 - wet) * x + np.sqrt(wet) * y

def glass(N, L, rng, rate, lo=2500.0, hi=7000.0, tilt=0.0, tau_lo=0.003, tau_hi=0.010):
    x = np.zeros((N, 2)); n = rng.poisson(rate * L)
    for _ in range(n):
        t0 = int(rng.uniform(0, N)); f0 = np.exp(rng.uniform(np.log(lo), np.log(hi)))
        r = rng.uniform(1.05, 1.25); tau = rng.uniform(tau_lo, tau_hi); dur = 6 * tau
        m = int(dur * SR); t = np.arange(m) / SR
        ph = 2 * np.pi * f0 * dur / np.log(r) * (r ** (t / dur) - 1) + rng.uniform(0, 2 * np.pi)
        env = np.exp(-t / tau) * np.minimum(1, t / 0.0005)
        s = np.sin(ph) * env * 10 ** ((rng.normal(0, 4) + tilt * np.log2(f0 / lo)) / 20)
        p = rng.uniform(-0.8, 0.8); a = (p + 1) * np.pi / 4
        idx = (t0 + np.arange(m)) % N
        x[idx, 0] += s * np.cos(a); x[idx, 1] += s * np.sin(a)
    return x, n

def fizz(N, L, rng, rate=250, lo=5000.0):
    x = np.zeros((N, 2))
    for c in range(2):
        k = rng.poisson(rate * L); pos = rng.integers(0, N, k)
        np.add.at(x[:, c], pos, rng.standard_normal(k) * 10 ** (rng.normal(0, 3, k) / 20))
    m = int(0.0015 * SR); t = np.arange(m) / SR
    ker = np.zeros(N); ker[:m] = np.random.default_rng(7).standard_normal(m) * np.exp(-t / 0.0004)
    K = np.fft.rfft(ker) * band(N, lo, 14000)
    return np.fft.irfft(np.fft.rfft(x, axis=0) * K[:, None], n=N, axis=0)

def hum(N, L, rng):
    t = np.arange(N) / SR; x = np.zeros((N, 2))
    f1 = round(55.0 * L) / L
    amps = [0.15, 0.5, 1.0, 0.7, 0.5, 0.35, 0.25, 0.15, 0.1, 0.06]
    for k, a in enumerate(amps, 1):
        f = k * f1; ph = rng.uniform(0, 2 * np.pi, 2)
        x[:, 0] += a * np.sin(2 * np.pi * f * t + ph[0]); x[:, 1] += a * np.sin(2 * np.pi * f * t + ph[1] * 0.2)
    # narrow noise round the harmonics: periodic noise shaped on the rfft grid
    f = np.fft.rfftfreq(N, 1 / SR); g = np.zeros_like(f)
    for k, a in enumerate(amps, 1): g += a * np.exp(-0.5 * ((f - k * f1) / 1.5) ** 2)
    nz = np.stack([np.fft.irfft(g * np.exp(1j * rng.uniform(0, 2 * np.pi, len(f))), n=N) for _ in range(2)], 1)
    nz *= 0.35 * np.sqrt((x ** 2).mean() / (nz ** 2).mean())
    return x + nz

def hiss(N, rng):
    x = rng.standard_normal((N, 2)); return circ_filter(x, band(N, 3000, 12000, slope_db_oct=-3.0))

if __name__ == "__main__":
    out, o = opts(sys.argv[1:]); L = o["loop"]; N = int(round(L * SR)); rng = np.random.default_rng(int(o["seed"]))
    layers = o["layers"].split(","); R = room(N, rng)
    parts = {}
    if "glass" in layers:
        g, ng = glass(N, L, rng, o["rate"], o["glass_lo"], o["glass_hi"], o["glass_tilt"], o["tau_lo"] / 1000, o["tau_hi"] / 1000); parts["glass"] = apply_room(g, R); print(f"glass: {ng} grains ({ng / L:.1f}/s)")
    if "fizz" in layers: parts["fizz"] = apply_room(fizz(N, L, rng, lo=o["fizz_lo"]), R, wet=0.4)
    if "hum" in layers: parts["hum"] = hum(N, L, rng)
    if "hiss" in layers: parts["hiss"] = hiss(N, rng)
    if o["rain"]:
        r = readf32(o["rain"]); assert r.shape[0] == N, (r.shape, N); parts["rain"] = r
    ref = kw_loudness(parts["glass"].mean(1)) if "glass" in parts else kw_loudness(next(iter(parts.values())).mean(1))
    mix = np.zeros((N, 2))
    for k, x in parts.items():
        lk = kw_loudness(x.mean(1)); want = ref + o.get(k + "_db", 0.0); gk = 10 ** ((want - lk) / 20)
        mix += x * gk; print(f"{k}: {want - ref:+.1f} dB re glass")
    mix = circ_filter(mix, band(N, 80, None))
    I = kw_loudness_st(mix); g = 10 ** ((o["target"] - I) / 20); pk = np.abs(mix * g).max()
    if pk > 10 ** (-1 / 20): g *= 10 ** (-1 / 20) / pk
    mix *= g; I2 = kw_loudness_st(mix)
    print(f"loop {L} s = {N} frames, seed {int(o['seed'])}; integrated {I2:.1f} LUFS (both channels), sample peak "
          f"{20 * np.log10(np.abs(mix).max()):.1f} dBFS; wrap step {np.abs(mix[0] - mix[-1]).max():.5f}")
    writef32(out, mix)
