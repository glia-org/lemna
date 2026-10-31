#!/usr/bin/env python3
"""Find where to loop an ambient bed for LemnaClicks. Standard library only; ffmpeg does the filtering.

    loop_points.py match take.wav FROM TO [--loop S] [--cross S] [--ffmpeg PATH]
        lists the five loop starts in [FROM, TO] s (0.1 s steps) whose wrap matches best: the band spectra of the
        loop's last 2 s against its first 2 s as played, its head crossfaded with the S s that follow its end

A loop is [start, start + LOOP) s of the take (90 s), the next CROSS s (3) laid over its head with an equal-power
crossfade (quarter sines, as ffmpeg's afade curve=qsin, the overhang fading out), so the wrap itself is seamless and
the head turns into the take's own continuation; build_packs.sh makes it with ffmpeg. What can still be heard is the
change of sound across the wrap: the spectrum of the loop's end against its head. The bands are 21 of a third of an
octave or so between 100 Hz and 16 kHz (ffmpeg's two-pole bandpass, on the take's mix to mono), their power read per
0.1 s by astats; the head's power is the crossfade's, the two parts adding as uncorrelated noise does. The distance is
the RMS over the bands of the dB difference.
"""
import math, re, subprocess, sys

FRAME = 0.1  # s
EDGES = [100 * (16000 / 100) ** (k / 21) for k in range(22)]


def band_powers(path, ffmpeg):
    bands = []
    for lo, hi in zip(EDGES, EDGES[1:]):
        f = "aformat=channel_layouts=mono,bandpass=f=%.1f:width_type=o:w=%.4f,asetnsamples=n=%d:p=0," \
            "astats=metadata=1:reset=1:measure_perchannel=none:measure_overall=RMS_level," \
            "ametadata=mode=print:key=lavfi.astats.Overall.RMS_level:file=/dev/stdout" % (
                math.sqrt(lo * hi), math.log2(hi / lo), round(48000 * FRAME))
        out = subprocess.run([ffmpeg, "-hide_banner", "-nostats", "-loglevel", "error", "-i", path, "-af", f,
                              "-ar", "48000", "-f", "null", "-"], capture_output=True, text=True, check=True).stdout
        db = re.findall(r"RMS_level=(\S+)", out)
        bands.append([0.0 if v in ("-inf", "inf") else 10 ** (float(v) / 10) for v in db])
    return bands


def match(bands, start, stop, loop, cross):
    L, X, W = round(loop / FRAME), round(cross / FRAME), round(2 / FRAME)
    w = [math.sin(math.pi / 2 * (t + 0.5) / X) ** 2 for t in range(W)]  # the head's share as it fades in
    n = len(bands[0])
    found = []
    for s in range(round(start / FRAME), round(stop / FRAME) + 1):
        if s + L + X > n:
            break
        d = 0.0
        for p in bands:
            before = sum(p[s + L - W:s + L])
            after = sum(w[t] * p[s + t] + (1 - w[t]) * p[s + L + t] for t in range(W))
            d += (10 * math.log10((after + 1e-20) / (before + 1e-20))) ** 2
        found.append((math.sqrt(d / len(bands)), s * FRAME))
    return sorted(found)


if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) >= 4 and a[0] == "match" and len(a) % 2 == 0:
        opts = dict(zip(a[4::2], a[5::2]))
        if not set(opts) <= {"--loop", "--cross", "--ffmpeg"}:
            sys.exit(__doc__)
        found = match(band_powers(a[1], opts.get("--ffmpeg", "ffmpeg")), float(a[2]), float(a[3]),
                      float(opts.get("--loop", 90)), float(opts.get("--cross", 3)))
        for d, s in found[:5]:
            print(f"start={s:7.1f} s  wrap differs by {d:.2f} dB RMS over the bands")
        print(f"({len(found)} starts tried; the worst {found[-1][0]:.2f} dB at {found[-1][1]:.1f} s)")
    else:
        sys.exit(__doc__)
