#!/usr/bin/env python3
"""Cut one key click for a LemnaClicks pack out of a recording. Standard library only.

The input is a 48 kHz mono 16-bit PCM WAV; decode anything else first, for example
    ffmpeg -i take.flac -ar 48000 -ac 1 -c:a pcm_s16le take48.wav

    cut_click.py hits take48.wav
        lists the key hits (time, peak, a 5 ms-per-column envelope) to choose from
    cut_click.py cut take48.wav out.wav AT SPAN_MS [--rate R] [--gain DB] [--lead MS] [--fade MS] [--max MS]
        cuts the hit whose peak lies in [AT - 5 ms, AT + 30 ms], SPAN_MS of source after it,
        read at playback rate R (R < 1 lowers the pitch and lengthens the click)

A cut starts 2 ms before the peak (every millisecond of lead-in is latency), fades in over
0.5 ms and out over the last 25 ms (half cosine), is peak-normalised to -6 dBFS and never
exceeds 150 ms. Choose SPAN_MS to end before the key's release, so the click is the press.
--gain lowers (or raises) the normalised click by DB, a lighter key than the rest of the pack;
--lead starts the cut MS before the peak instead of 2, for a key whose loudest moment comes well
after its onset (SPAN_MS still counts from the cut's start); --fade is the fade-out in ms (25);
--max raises the 150 ms limit, for a long sound such as a carriage return (paragraph).

    cut_click.py splice take48.wav out.wav A0 A1 B0 B1 [--cross MS]
        joins [A0, A1] s of the take to [B0, B1] s of it, the second laid over the first's last MS ms (30)
        with an equal-power crossfade (quarter sines, as ffmpeg's acrossfade c1=qsin c2=qsin), unnormalised;
        for a sound made shorter than it was recorded, which `cut` then cuts as any other
"""
import array, math, sys, wave

FS = 48000
MAX_MS = 150
PEAK = 10 ** (-6 / 20)


def read(path):
    with wave.open(path, "rb") as w:
        if (w.getframerate(), w.getnchannels(), w.getsampwidth()) != (FS, 1, 2):
            sys.exit(f"{path}: need 48 kHz mono 16-bit PCM")
        return [v / 32768 for v in array.array("h", w.readframes(w.getnframes()))]


def write(path, x):
    pcm = array.array("h", (max(-32768, min(32767, round(v * 32767))) for v in x))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(pcm.tobytes())


def hits(x):
    ms = FS // 1000
    env = [max(abs(v) for v in x[i:i + ms]) for i in range(0, len(x) - ms, ms)]
    top = max(env)
    on = top * 10 ** (-30 / 20)
    armed, quiet = True, 0
    for i, v in enumerate(env):
        quiet = quiet + 1 if v < on / 2 else 0
        armed = armed or quiet >= 40  # 40 ms below half the threshold re-arms
        if armed and v >= on:
            armed = False
            p = max(env[i:i + 20])
            shape = "".join("#" if v > p * 0.3 else "+" if v > p * 0.1 else "." if v > p * 0.03 else " "
                            for v in env[i:i + 200:5])
            print(f"t={i / 1000:7.3f}  peak={20 * math.log10(p):6.1f} dBFS  |{shape}|")


def cut(x, at, span_ms, rate, gain_db=0.0, lead_ms=2.0, fade_ms=25.0, max_ms=MAX_MS):
    lo, hi = int((at - 0.005) * FS), int((at + 0.030) * FS)
    peak = max(range(max(lo, 0), min(hi, len(x))), key=lambda i: abs(x[i]))
    start = max(peak - int(lead_ms * FS / 1000), 0)
    span = min(span_ms * FS // 1000, len(x) - start - 1)
    n = min(int(span / rate), int(max_ms * FS / 1000))
    y = []
    for k in range(n):  # linear interpolation is enough for a click (the player does the same)
        p = start + k * rate
        i = int(p)
        y.append(x[i] + (x[i + 1] - x[i]) * (p - i))
    fin, fout = FS // 2000, min(int(fade_ms * FS / 1000), n // 3)
    for k in range(fin):
        y[k] *= k / fin
    for k in range(fout):
        y[n - fout + k] *= 0.5 * (1 + math.cos(math.pi * (k + 1) / fout))
    g = PEAK * 10 ** (gain_db / 20) / max(abs(v) for v in y)
    return [v * g for v in y]


def splice(x, a0, a1, b0, b1, cross_ms=30.0):
    a, b = x[int(a0 * FS):int(a1 * FS)], x[int(b0 * FS):int(b1 * FS)]
    n = min(int(cross_ms * FS / 1000), len(a), len(b))
    w = [math.pi / 2 * (k + 0.5) / n for k in range(n)]
    return a[:len(a) - n] + [a[len(a) - n + k] * math.cos(w[k]) + b[k] * math.sin(w[k]) for k in range(n)] + b[n:]


if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == "hits":
        hits(read(a[1]))
    elif len(a) >= 5 and len(a) % 2 == 1 and a[0] == "cut":
        opts = dict(zip(a[5::2], map(float, a[6::2])))
        if not set(opts) <= {"--rate", "--gain", "--lead", "--fade", "--max"}:
            sys.exit(__doc__)
        write(a[2], cut(read(a[1]), float(a[3]), int(a[4]), opts.get("--rate", 1.0), opts.get("--gain", 0.0),
                        opts.get("--lead", 2.0), opts.get("--fade", 25.0), opts.get("--max", MAX_MS)))
    elif len(a) in (7, 9) and a[0] == "splice" and (len(a) == 7 or a[7] == "--cross"):
        write(a[2], splice(read(a[1]), *map(float, a[3:7]), *map(float, a[8:9])))
    else:
        sys.exit(__doc__)
