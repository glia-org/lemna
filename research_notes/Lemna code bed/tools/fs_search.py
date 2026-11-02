"""Parse freesound search result HTML files (paths as args); print id, user, duration, downloads, title, ogg url."""
import re, sys, html
seen = {}
for path in sys.argv[1:]:
    t = open(path, encoding="utf-8", errors="replace").read()
    # split per player block: each has data-sound-id ... attributes in one tag
    for m in re.finditer(r'<div[^>]*data-sound-id="(\d+)"[^>]*>', t):
        tag = m.group(0)
        a = dict(re.findall(r'data-([a-z-]+)="([^"]*)"', tag))
        sid = a.get("sound-id")
        if sid in seen: continue
        seen[sid] = 1
        print("\t".join([sid, a.get("username", "?"), "%.0f" % float(a.get("duration", "0") or 0),
                         a.get("samplerate", "?"), a.get("num-downloads", "?"), html.unescape(a.get("title", "?"))[:70],
                         a.get("ogg", "?"), path.split("/")[-1]]))
