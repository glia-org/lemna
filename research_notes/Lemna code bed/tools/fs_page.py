"""Print licence, description, tags, format line of freesound sound pages (paths as args)."""
import re, sys, html
def txt(s): return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", s))).strip()
for p in sys.argv[1:]:
    t = open(p, encoding="utf-8", errors="replace").read()
    title = re.search(r"<title>(.*?)</title>", t, re.S)
    lic = re.findall(r'href="(https?://creativecommons\.org/[^"]+)"', t)
    desc = re.search(r'<div[^>]*id="soundDescriptionSection"[^>]*>(.*?)</div>', t, re.S) or \
           re.search(r'<div[^>]*class="[^"]*sound-description[^"]*"[^>]*>(.*?)</div>', t, re.S)
    tags = re.findall(r'href="/browse/tags/([^/"]+)/"', t)
    ogg = re.findall(r'https://cdn\.freesound\.org/previews/\d+/\d+_\d+-hq\.ogg', t)
    meta = re.findall(r'(\d+(?:\.\d+)?\s*(?:kHz|bit|bits))', t)
    print("==", p, "|", txt(title.group(1)) if title else "?")
    print("  licence:", sorted(set(lic))[:3])
    print("  desc:", txt(desc.group(1))[:900] if desc else "?")
    print("  tags:", " ".join(sorted(set(tags)))[:300])
    print("  hq:", sorted(set(ogg))[:1], " meta:", sorted(set(meta))[:6])
