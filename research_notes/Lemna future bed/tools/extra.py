"""extra.py CODE_BED_TOOLS CLICKS_DIR bed.wav...: three measures beside analyze.py's, for beds with a low body.
full / >200 Hz / laptop loss: loudness over both channels (BS.1770 gated) in full and after a 4th-order Butterworth
high-pass at 200 Hz (a rough stand-in for laptop speakers, which give little under 150-200 Hz), and the difference;
150-500, 0.5-1k: the share of energy in those bands; m200-1k: analyze.py's click margin (the loudest 10 % of 10 ms
frames of its 60 s Keychron typing stream over the bed's left channel at -43 LUFS, median dB) in 200 Hz-1 kHz, where
the clicks' body is (sound.md §2.3 reports this band for the rain beds)."""
import sys, numpy as np
from scipy import signal
sys.dont_write_bytecode = True  # no __pycache__ in the code bed's tools
sys.path.insert(0, sys.argv[1]); import analyze as A
sr = 48000
clicks = A.typing_stream(sys.argv[2], sr)
sos = signal.butter(4, [200, 1000], "bp", fs=sr, output="sos")
for p in sys.argv[3:]:
    x, sr = A.readany(p)
    full = A.integrated(A.kweight(x, sr), sr)
    hp = signal.sosfilt(signal.butter(4, 200, "hp", fs=sr, output="sos"), x, axis=0)
    hi = A.integrated(A.kweight(hp, sr), sr)
    f, P = signal.welch(x.mean(axis=1), sr, nperseg=8192)
    b = lambda lo, hi_: 100 * P[(f >= lo) & (f < hi_)].sum() / P.sum()
    n = min(len(clicks), len(x)); bed = x[:n, 0] * 10 ** ((-43 - full) / 20)
    fc = 10 * np.log10(A.blocks(signal.sosfilt(sos, clicks[:n]), sr, 0.01, 0.01) + 1e-20)
    fb = 10 * np.log10(A.blocks(signal.sosfilt(sos, bed), sr, 0.01, 0.01) + 1e-20)
    top = fc >= np.percentile(fc, 90)
    print("%-22s full %6.1f  >200Hz %6.1f  laptop loss %4.1f dB  150-500 %5.1f%%  0.5-1k %5.1f%%  m200-1k %5.1f dB" % (
        p.split("/")[-1], full, hi, full - hi, b(150, 500), b(500, 1000), float(np.median(fc[top] - fb[top]))))
