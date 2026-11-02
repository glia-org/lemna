"""Measure candidate beds as sound.md §6 does, plus a pulse score and a click-masking margin.

    analyze.py CLICKS_DIR bed1.wav [bed2.wav ...] [--from S --to S]
Each bed: 48 kHz float WAV (mono or stereo). Prints one line of metrics per bed.
Ist: integrated loudness (BS.1770, gated) over both channels; S-SD: SD of 3 s short-term loudness every 0.1 s;
burst: share of 400 ms windows > 6 LU over their median; LF/HF: energy share < 150 Hz / > 5 kHz; cen: centroid;
on/min: onsets a minute above 1 kHz (sound.md §6 rule); pulse: the highest normalised autocorrelation of the
10 ms > 1 kHz energy envelope; wrap/p99.9: the sample step from the last frame to the first over the 99.9th percentile of all steps (< 1: no click) at lags 0.15-4 s (0 none, 1 a strict period), and its lag; tonal: Welch peaks of
>= 12 dB prominence 150 Hz-8 kHz; margin: the loudest 10 % of 10 ms frames of a 60 s Keychron typing stream
(5 keys/s, gain 0.6) over the bed's left channel with the bed at -43 LUFS over both channels (Bed.level), at the same instants, median dB, broadband and 1-4 kHz.
"""
import sys, wave, numpy as np
from scipy import signal

def read(path):
    import soundfile  # noqa
def readwav(path):
    with wave.open(path, "rb") as w:
        n, ch, sw, sr = w.getnframes(), w.getnchannels(), w.getsampwidth(), w.getframerate()
        b = w.readframes(n)
    if sw == 2:
        x = np.frombuffer(b, "<i2").astype(np.float64) / 32768
    elif sw == 4:
        x = np.frombuffer(b, "<f4").astype(np.float64)  # ffmpeg pcm_f32le writes WAVE_FORMAT_IEEE_FLOAT
    else:
        raise SystemExit("unsupported width")
    return x.reshape(-1, ch), sr

def readany(path):
    # wave module rejects IEEE float format tag 3; parse by hand
    import struct
    d = open(path, "rb").read()
    pos, fmt, data = 12, None, None
    while pos < len(d) - 8:
        cid, sz = d[pos:pos + 4], struct.unpack("<I", d[pos + 4:pos + 8])[0]
        body = d[pos + 8:pos + 8 + sz]
        if cid == b"fmt ":
            tag, ch, sr, _, _, bits = struct.unpack("<HHIIHH", body[:16])
            if tag == 0xFFFE: tag = struct.unpack("<H", body[24:26])[0]
            fmt = (tag, ch, sr, bits)
        elif cid == b"data":
            data = body
        pos += 8 + sz + (sz & 1)
    tag, ch, sr, bits = fmt
    if tag == 3 and bits == 32: x = np.frombuffer(data, "<f4").astype(np.float64)
    elif tag == 1 and bits == 16: x = np.frombuffer(data, "<i2").astype(np.float64) / 32768
    elif tag == 1 and bits == 24:
        a = np.frombuffer(data, np.uint8).reshape(-1, 3)
        x = ((a[:, 0].astype(np.int32) | (a[:, 1].astype(np.int32) << 8) | (a[:, 2].astype(np.int32) << 16)) << 8 >> 8) / 8388608.0
    else: raise SystemExit("unsupported %r" % (fmt,))
    return x.reshape(-1, ch), sr

def kweight(x, sr):
    assert sr == 48000
    b1, a1 = [1.53512485958697, -2.69169618940638, 1.19839281085285], [1.0, -1.69065929318241, 0.73248077421585]
    b2, a2 = [1.0, -2.0, 1.0], [1.0, -1.99004745483398, 0.99007225036621]
    return signal.lfilter(b2, a2, signal.lfilter(b1, a1, x, axis=0), axis=0)

def blocks(z, sr, win, hop):
    p = (z ** 2).sum(axis=1) if z.ndim == 2 else z ** 2
    c = np.concatenate([[0], np.cumsum(p)])
    W, H = int(win * sr), int(hop * sr)
    idx = np.arange(0, len(p) - W + 1, H)
    return (c[idx + W] - c[idx]) / W

def lufs_of(ms): return -0.691 + 10 * np.log10(ms + 1e-30)

def integrated(z, sr):
    m = blocks(z, sr, 0.4, 0.1)
    l = lufs_of(m); m = m[l > -70]
    if not len(m): return -99
    rel = lufs_of(m.mean()) - 10
    return lufs_of(m[lufs_of(m) > rel].mean())

def metrics(x, sr, clicks=None):
    mono = x.mean(axis=1)
    z = kweight(mono, sr)
    I = integrated(z, sr)
    Ist = integrated(kweight(x, sr), sr)  # BS.1770 over both channels, as ffmpeg's ebur128 and bed.json
    st = lufs_of(blocks(z, sr, 3.0, 0.1)); ssd = st.std()
    mo = lufs_of(blocks(z, sr, 0.4, 0.1)); burst = 100 * (mo > np.median(mo) + 6).mean()
    f, P = signal.welch(mono, sr, nperseg=8192)
    lf = 100 * P[f < 150].sum() / P.sum(); hf = 100 * P[f > 5000].sum() / P.sum(); cen = (f * P).sum() / P.sum()
    band14 = 100 * P[(f >= 1000) & (f <= 4000)].sum() / P.sum()
    # onsets above 1 kHz (sound.md §6)
    hp = signal.sosfilt(signal.butter(4, 1000, "hp", fs=sr, output="sos"), mono)
    r = 10 * np.log10(blocks(hp, sr, 0.01, 0.01) + 1e-20)
    floor = np.percentile(r, 20); on = []; last = -1e9
    for i in range(5, len(r)):
        if r[i] - r[max(0, i - 5):i].min() >= 9 and r[i] - floor >= 15 and (i - last) >= 12:
            on.append(i); last = i
    onmin = len(on) / (len(r) * 0.01 / 60)
    # pulse: autocorrelation of the >1 kHz energy envelope, 10 ms frames
    e = blocks(hp, sr, 0.01, 0.01); e = np.log10(e + 1e-12); e = e - signal.savgol_filter(e, 301, 1); e -= e.mean()
    ac = np.correlate(e, e, "full")[len(e) - 1:]; ac /= ac[0]
    lo, hi = 15, 400; k = lo + int(np.argmax(ac[lo:hi])); pulse, plag = ac[k], k * 0.01
    # tonal peaks
    fw, Pw = signal.welch(mono, sr, nperseg=16384); dB = 10 * np.log10(Pw + 1e-30)
    sel = (fw >= 150) & (fw <= 8000)
    pk, pr = signal.find_peaks(dB, prominence=12)
    tonal = int(sum(1 for p in pk if sel[p]))
    # modulation: the 1-16 Hz fluctuation of each band's 5 ms envelope over its mean (fluctuation strength peaks
    # near 4 Hz, Schlittmeier 2012); the largest of four octave-wide bands
    mod = 0.0
    for lo_, hi_ in ((500, 1000), (1000, 2000), (2000, 4000), (4000, 8000)):
        bb = signal.sosfilt(signal.butter(4, [lo_, hi_], "bp", fs=sr, output="sos"), mono)
        ev = np.sqrt(blocks(bb, sr, 0.005, 0.005) + 1e-20)
        em = signal.sosfiltfilt(signal.butter(2, [1, 16], "bp", fs=200, output="sos"), ev)
        mod = max(mod, em.std() / ev.mean())
    # stereo width: correlation L/R
    corr = np.corrcoef(x[:, 0], x[:, 1])[0, 1] if x.shape[1] == 2 else 1.0
    step = np.abs(np.diff(x, axis=0)).max(axis=1); wrap = np.abs(x[0] - x[-1]).max()
    out = dict(Ist=Ist, wrap=wrap / np.percentile(step, 99.9), I=I, ssd=ssd, burst=burst, lf=lf, hf=hf, cen=cen, b14=band14, onmin=onmin, pulse=pulse, plag=plag,
               tonal=tonal, corr=corr, mod=mod, dur=len(mono) / sr)
    if clicks is not None:
        n = min(len(clicks), len(mono))
        g = 10 ** ((-43 - Ist) / 20); bed = x[:n, 0] * g; c = clicks[:n]  # the bed at Bed.level, one ear
        def frames(s, sos=None):
            if sos is not None: s = signal.sosfilt(sos, s)
            return 10 * np.log10(blocks(s, sr, 0.01, 0.01) + 1e-20)
        sos14 = signal.butter(4, [1000, 4000], "bp", fs=sr, output="sos")
        for name, sos in (("mB", None), ("m14", sos14)):
            fc, fb = frames(c, sos), frames(bed, sos)
            top = fc >= np.percentile(fc, 90)
            out[name] = float(np.median(fc[top] - fb[top]))
    return out

def typing_stream(d, sr, secs=60, rate=5.0, seed=7):
    letters = [readany(f"{d}/letter-{i}.wav")[0].mean(axis=1) for i in range(1, 7)]
    spaces = [readany(f"{d}/space-{i}.wav")[0].mean(axis=1) for i in (1, 2)]
    rng = np.random.default_rng(seed); out = np.zeros(int(secs * sr) + sr); t = 0.0; k = 0; prev = -1
    while t < secs:
        k += 1
        pool = spaces if k % 6 == 0 else letters
        j = rng.integers(len(pool))
        if pool is letters and j == prev: j = (j + 1) % len(pool)
        if pool is letters: prev = j
        s = pool[j] * 0.6; i0 = int(t * sr); out[i0:i0 + len(s)] += s[:len(out) - i0]
        t += 0.07 + rng.exponential(1 / rate - 0.07)
    return out[:int(secs * sr)]

if __name__ == "__main__":
    a = sys.argv[1:]; cd = a[0]; paths = a[1:]
    clicks = typing_stream(cd, 48000)
    zc = kweight(clicks, 48000)
    print(f"typing stream: I {integrated(zc, 48000):.1f} LUFS (mono)")
    print("%-28s %6s %5s %6s %5s %5s %6s %5s %6s %10s %5s %5s %6s %6s" % ("file", "Ist", "S-SD", "burst%", "LF%", "HF%", "cen", "1-4k%", "on/min", "pulse@lag", "tonal", "corr", "mB", "m1-4k") + "  wrap/p99  mod")
    for p in paths:
        x, sr = readany(p)
        m = metrics(x, sr, clicks)
        print("%-28s %6.1f %5.2f %6.2f %5.1f %5.1f %6.0f %5.1f %6.0f %5.2f@%4.2f %5d %5.2f %6.1f %6.1f %5.2f %5.2f" % (
            p.split("/")[-1][:28], m["Ist"], m["ssd"], m["burst"], m["lf"], m["hf"], m["cen"], m["b14"], m["onmin"],
            m["pulse"], m["plag"], m["tonal"], m["corr"], m["mB"], m["m14"], m["wrap"], m["mod"]))
