# Writes the app icon variants of round 2 (docs/design-panel-icon-round-2.html; DESIGN.md L1): I1's body with the
# menu-bar mark M3 on it, its line tapered to a point and its caret at 60 %. 1024 px canvas, Apple's 824 px
# body as a superellipse (n = 5), the app's colours. No shadow: app/make-icon.swift draws it, as AppKit's SVG reader
# skips filters. Run: python3 assets/logo/icons.py (writes icon-I1-M3-{a,b,c}.svg next to this file).
import math
import pathlib
import sys

TEXT, CARET = "#d8dce3", "#7aa7f0"

# M3 in its 16 pt square (assets/logo/mark-M3.svg): a 12 pt line from x 2 to 14, 1.5 pt tall from the caret's left edge
# (8.5) on, narrowing from there to a point at its left end on the line's middle; the caret 1.5 pt wide and 8.5 pt
# tall, centred on the line. The icon keeps the point: StatusMark's 1 pt end is for the pixels of a 1× menu bar.
CARET_AT, CARET_H = .6, 8.5 / 12  # the caret's middle and its height as shares of the line

# id, file, mark width as a share of the 824 px body, line weight in px of the 1024 px canvas (10 % of the mark's
# width: the 16 pt mark's 12.5 % is set by its pixels and reads heavy at this size), the thin end's fade (its opacity
# at the point, None for none)
VARIANTS = [
    ("J1", "a", .70, 58, None),
    ("J2", "b", .70, 58, .35),
    ("J3", "c", .80, 66, .35),
]


def n(v):
    return f"{v:.1f}".rstrip("0").rstrip(".")


def squircle(cx=512, cy=512, a=412, e=5, k=360):
    pts = []
    for i in range(k):
        t = 2 * math.pi * i / k
        c, s = math.cos(t), math.sin(t)
        x = cx + a * math.copysign(abs(c) ** (2 / e), c)
        y = cy + a * math.copysign(abs(s) ** (2 / e), s)
        pts.append(f"{x:.1f} {y:.1f}")
    return "M" + "L".join(pts) + "Z"


def icon(width, weight, fade):
    w = width * 824
    x0, x1 = 512 - w / 2, 512 + w / 2
    t, h = weight, CARET_H * w
    xc = x0 + CARET_AT * w - t / 2  # the caret's left edge, where the taper begins
    body = squircle()
    defs = ('<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#181a1d"/>'
            '<stop offset="1" stop-color="#0e1013"/></linearGradient>')
    fill = TEXT
    if fade is not None:
        # From the point at `fade` to full strength halfway to the caret.
        defs += (f'<linearGradient id="tip" gradientUnits="userSpaceOnUse" x1="{n(x0)}" y1="0" x2="{n((x0 + xc) / 2)}" '
                 f'y2="0"><stop offset="0" stop-color="{TEXT}" stop-opacity="{fade:g}"/>'
                 f'<stop offset="1" stop-color="{TEXT}"/></linearGradient>')
        fill = "url(#tip)"
    line = (f"M{n(x0)} 512L{n(xc)} {n(512 - t / 2)}H{n(x1)}V{n(512 + t / 2)}H{n(xc)}Z")
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'
            f'<defs>{defs}</defs><path d="{body}" fill="url(#bg)"/>'
            f'<path d="{body}" fill="none" stroke="#fff" stroke-opacity=".07" stroke-width="3"/>'
            f'<path d="{line}" fill="{fill}"/>'
            f'<rect x="{n(xc)}" y="{n(512 - h / 2)}" width="{n(t)}" height="{n(h)}" fill="{CARET}"/></svg>\n')


def main(out):
    for vid, f, width, weight, fade in VARIANTS:
        what = (f"mark {width * 100:.0f} % of the body, line {weight} px"
                + (f", the thin end fading to {fade * 100:.0f} %" if fade else ""))
        head = (f"<!-- App icon {vid} (I1 from M3: {what}), docs/design-panel-icon-round-2.html. 1024 px canvas, "
                "Apple's 824 px body (superellipse, n = 5). No shadow: app/make-icon.swift draws it, as AppKit's SVG "
                "reader skips filters. Written by icons.py. -->\n")
        (out / f"icon-I1-M3-{f}.svg").write_text(head + icon(width, weight, fade))


if __name__ == "__main__":
    main(pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(__file__).parent)
