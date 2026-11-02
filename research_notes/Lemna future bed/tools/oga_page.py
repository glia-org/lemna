"""OpenGameArt content pages (paths as args): author, licences, favorites, files with sizes and download counts, body."""
import re, sys, html
def txt(s): return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", s))).strip()
for p in sys.argv[1:]:
    t = open(p, encoding="utf-8", errors="replace").read()
    fav = re.search(r'Favorites:&nbsp;</div><div class="field-items"><div class="field-item[^"]*">\s*(\d+)', t) or re.search(r'field-name-favorites.*?(\d+)', t, re.S)
    lic = re.findall(r"class='license-name'>([^<]+)", t)
    au = re.search(r"Author:&nbsp;</div>.*?<a href=\"/users/[^\"]+\">([^<]+)</a>", t, re.S)
    date = re.search(r'Art Submitted by.*?(\w+day, \w+ \d+, \d{4})', t, re.S) or re.search(r'(\w+day, \w+ \d+, \d{4} - \d+:\d+)', t)
    files = re.findall(r'href="(https://opengameart\.org/sites/default/files/[^"]+)"[^>]*download="[^"]*">[^<]+</a>\s*([\d.]+ [KM]b)\s*<span class="dlcount">\[<span class="dlcount-number"[^>]*>(\d+)</span>', t)
    body = re.search(r'field-name-body.*?<div class="field-item[^"]*"[^>]*>(.*?)</div></div></div>', t, re.S)
    print("==", p.split("/")[-1], "| fav", fav.group(1) if fav else "?", "| lic", lic, "| author", au.group(1) if au else "?", "|", date.group(1) if date else "")
    for f in files[:8]: print("    %-60s %9s %6s dl" % (f[0].split("/")[-1][:60], f[1], f[2]))
    print("   desc:", txt(body.group(1))[:400] if body else "?")
