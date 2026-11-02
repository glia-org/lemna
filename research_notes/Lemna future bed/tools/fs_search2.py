"""Parse freesound search result HTML (paths as args): id, user, uploader id, duration, downloads, rating avg, n ratings, licence guess, title."""
import re, sys, html
seen = {}
rows = []
for path in sys.argv[1:]:
    t = open(path, encoding="utf-8", errors="replace").read()
    ms = list(re.finditer(r'<div[^>]*data-sound-id="(\d+)"[^>]*>', t))
    for k, m in enumerate(ms):
        seg = t[m.start(): ms[k + 1].start() if k + 1 < len(ms) else len(t)]
        a = dict(re.findall(r'data-([a-z-]+)="([^"]*)"', m.group(0)))
        sid = a.get("sound-id")
        if sid in seen: continue
        seen[sid] = 1
        r = re.search(r'rating of ([0-9.]+)', seg); n = re.search(r'rating__count[^>]*>\((\d+)', seg)
        lic = re.search(r'title="(Creative Commons 0|Attribution[^"]*|[^"]*Commons[^"]*)"', seg)
        lic2 = re.findall(r'bw-icon-(cc[a-z-]*|by|nc|zero)', seg)
        rows.append((int(a.get("num-downloads", "0") or 0), sid, a.get("username", "?"), a.get("user-id", "?"),
                     float(a.get("duration", "0") or 0), r.group(1) if r else "-", n.group(1) if n else "0",
                     lic.group(1) if lic else ",".join(sorted(set(lic2))), html.unescape(a.get("title", "?"))[:70], path.split("/")[-1]))
for row in sorted(rows, reverse=True):
    print("%7d  %-7s %-20s u%-9s %5.0fs  r%-4s n%-4s %-14s %s  [%s]" % row)
