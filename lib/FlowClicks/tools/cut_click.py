#!/usr/bin/env python3
"""Cut one key click for a FlowClicks pack out of a recording. Standard library only.

The input is a 48 kHz mono 16-bit PCM WAV; decode anything else first, for example
    ffmpeg -i take.flac -ar 48000 -ac 1 -c:a pcm_s16le take48.wav

    cut_click.py hits take48.wav
        lists the key hits (time, peak, a 5 ms-per-column envelope) to choose from
    cut_click.py cut take48.wav out.wav AT SPAN_MS [--rate R]
        cuts the hit whose peak lies in [AT - 5 ms, AT + 30 ms], SPAN_MS of source after it,
        read at playback rate R (R < 1 lowers the pitch and lengthens the click)

A cut starts 2 ms before the peak (every millisecond of lead-in is latency), fades in over
0.5 ms and out over the last 25 ms (half cosine), is peak-normalised to -6 dBFS and never
exceeds 150 ms. Choose SPAN_MS to end before the key's release, so the click is the press.
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


def cut(x, at, span_ms, rate):
    lo, hi = int((at - 0.005) * FS), int((at + 0.030) * FS)
    peak = max(range(max(lo, 0), min(hi, len(x))), key=lambda i: abs(x[i]))
    start = max(peak - 2 * FS // 1000, 0)
    span = min(span_ms * FS // 1000, len(x) - start - 1)
    n = min(int(span / rate), MAX_MS * FS // 1000)
    y = []
    for k in range(n):  # linear interpolation is enough for a click (the player does the same)
        p = start + k * rate
        i = int(p)
        y.append(x[i] + (x[i + 1] - x[i]) * (p - i))
    fin, fout = FS // 2000, min(25 * FS // 1000, n // 3)
    for k in range(fin):
        y[k] *= k / fin
    for k in range(fout):
        y[n - fout + k] *= 0.5 * (1 + math.cos(math.pi * (k + 1) / fout))
    g = PEAK / max(abs(v) for v in y)
    return [v * g for v in y]


if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == "hits":
        hits(read(a[1]))
    elif len(a) in (5, 7) and a[0] == "cut" and (len(a) == 5 or a[5] == "--rate"):
        write(a[2], cut(read(a[1]), float(a[3]), int(a[4]), float(a[6]) if len(a) == 7 else 1.0))
    else:
        sys.exit(__doc__)
