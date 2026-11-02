"""periods.py CODE_BED_TOOLS bed.wav...: is there a period in a band's envelope? For 150-500 Hz and 1-4 kHz: the
envelope in 50 ms frames (dB, mean removed), its autocorrelation at 0.5, 1, 2, 3 and 5 s, and its peaks up to 10 s of
at least 0.08 prominence (candidates.md §3, "Periods"). A noise with no period decorrelates within 0.5 s and has no
peak above about 0.1."""
import sys, numpy as np
from scipy import signal
sys.dont_write_bytecode = True  # no __pycache__ in the code bed's tools
sys.path.insert(0, sys.argv[1]); import analyze as A
for p in sys.argv[2:]:
    x, sr = A.readany(p); m = x.mean(axis=1)
    for lo, hi in ((150, 500), (1000, 4000)):
        b = signal.sosfilt(signal.butter(4, [lo, hi], "bp", fs=sr, output="sos"), m)
        e = 10 * np.log10(A.blocks(b, sr, 0.05, 0.05) + 1e-20); e = e - e.mean()
        c = np.correlate(e, e, "full")[len(e) - 1:]; c /= c[0]
        pk, _ = signal.find_peaks(c[:200], prominence=0.08)
        print("%-18s %4d-%4d Hz: r at 0.5/1/2/3/5 s %s; peaks %s" % (p.split("/")[-1], lo, hi,
              " ".join("%.2f" % c[int(l / 0.05)] for l in (0.5, 1, 2, 3, 5)),
              ", ".join("%.2f s r %.2f" % (k * 0.05, c[k]) for k in pk[:4]) or "none"))
