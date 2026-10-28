# Hypha as the name: trademarks, products, domains (as of 2026-10-28)

Question: can "Hypha" name the small macOS writing app (menu-bar accessory, personal use now, maybe public later, bundle id `dev.hypha.app` or similar)? This follows the Hypha section of `name.md` (§2), which used aggregators only and did not search EUIPO or DPMA.

This is a research note, not legal advice. A real clearance search for a public launch is a lawyer's job.

## Verdict

1. **Risk of confusion in class 9/42: high.** One company, WI Licencing Pty Ltd (apparently the IP holder behind the Australian "Hypha" HyphaMESH radios), holds the identical word mark HYPHA in the US (class 9, reg. 6976595, live) for goods that literally include "downloadable and recorded computer programs for … word processing", and in the EU (EUTM 018663735, class 9, live) for "Computerprogramme; Computersoftware" with no restriction. In a registry, a writing app named HYPHA is the same mark on the same goods. In the shop the overlap is small, because the owner sells mesh-radio hardware to emergency services. The registry is the hurdle: an application would very likely be refused or opposed.
2. **Personal use: no real risk.** Infringement needs use in trade ("in the course of trade" in the EU, "use in commerce" in the US). An app built and run on your own Mac, not offered to anyone, is neither. The bundle id is not a trademark use. `dev.hypha.app` is the reverse of hypha.dev, which someone else registered (2025-03-19). Apple does not check this as far as I know (unverified), but it breaks the reverse-DNS convention, so an id under a domain you hold is cleaner.
3. **Before a public release:** (a) a manual check in USPTO TSDR and EUIPO eSearch plus (both refused automated access here), or a paid clearance search, in classes 9 and 42 for US, EU, DE and UK. (b) A decision on the WI Licencing marks: rename (most likely), ask for consent or coexistence, or have a lawyer look at a non-use attack on the software goods. A US expungement petition for goods never used is possible 3–10 years after registration, so from 2026-02-14. The EU five-year use grace period ends 2027-07-12. Even a free release counts: a free download from a website or GitHub can be use in commerce, and a free app on the App Store very likely is. Adding a word ("Hypha Writer") does not help: HYPHA stays the dominant part.

## Method

- **USPTO:** tmsearch.uspto.gov is a JavaScript app. Its backend refused, the TSDR status pages answered 429 and the TSDR API now wants a key ("Beginning October 2, you'll need to register for an API key …"). US records therefore come from two mirrors of USPTO data, [Trademarkia](https://www.trademarkia.com/search/trademarks?q=hypha) and [GleanMark](https://gleanmark.com/trademark/uspto-90256874). The goods texts quoted below match on both. Status is as the mirrors show it, **not verified at TSDR**. Justia and uspto.report answered 403.
- **EUIPO and DPMA:** EUIPO eSearch plus and TMview reset the connection, and WIPO's Global Brand Database sits behind a captcha. All three are **not queried directly**. [DPMAregister](https://register.dpma.de/DPMAregister/marke/basis) answered. It holds German marks (DE), EU trade marks (EM, data supplied by EUIPO) and international registrations covering Germany or the EU (IR), and its terms allow software-assisted queries below 5000 a day. I ran a smart search for "hypha", "hyphae", "hyphe" and "hypha app", and an expert search `md = hypha` (it also matches "hyphae"). Wildcard queries (`hyph?`) returned nothing, so marks that merely *start* with HYPHA (like HYPHAWAY) are **not covered** for DE/EU.
- **Products:** Apple's iTunes Search API (`entity=macSoftware`, `software`, `iPadSoftware`; US and DE storefronts), GitHub's public search API (sorted by stars), and web search.
- **Domains:** registry RDAP through rdap.org (Google Registry for .app/.dev/.page, Verisign for .com). 200 = registered, 404 = not registered. .io and .so have no RDAP; for those, DNS and the site.

## 1. Trademarks

### Hits in class 9 or 42 (the ones that matter)

| Mark | Office, number | Owner | Status | Classes | Goods (relevant part) | Dates |
|---|---|---|---|---|---|---|
| **HYPHA** (word) | US serial 90256874, reg. **6976595** | WI Licencing Pty Ltd, Darra QLD, AU | **Live, registered** (mirrors) | **9** | Telecom equipment, plus "Computer equipment, apparatus and systems, namely, **downloadable and recorded computer programs for managing telecommunications connections, word processing, editing audio and video**; Downloadable and recorded computer software for database management, photo editing" | filed 2020-10-15 (intent to use), first use 2022-01-20, reg. 2023-02-14 |
| **HYPHA** (word) | US serial 90975032, reg. 6944737 | WI Licencing Pty Ltd | Live, registered (mirrors) | 37, **42** | 42: "Repair and maintenance of computer software programs"; 37: repair of telecom apparatus | filed 2020-10-15, reg. 2023-01-03 |
| **hypha** (word) | **EUTM 018663735** | WI Licencing Pty Ltd, AU (rep. Marchi & Partners, Milan) | **Registered** (DPMAregister, EM data) | **9**, 37, 38 | 9: telecom equipment … "Computerausrüstungen, -geräte und -systeme, einschließlich, aber nicht ausschließlich, Computerprogramme; **Computersoftware**; Computerhardware" … ; 38: telecom services | filed 2022-03-01, reg. 2022-07-12, expires 2032-03-01 |
| HYPHA (word) | US serial 90575917, reg. 6683087 | Hyphametrics, Inc., New York | Live, registered (mirrors) | 16, 35, **42** | 42: "online non-downloadable computer software for tracking and generating reports regarding consumer behavior" (marketing and media measurement) | filed 2021-03-12, reg. 2022-03-29 |
| HYPHAE (word) | US serial 50109978 | Hyphae Technologies, Inc., Sausalito CA | **Pending**, not yet examined | 42 | SaaS "for searching, comparing, evaluating, and visualizing the properties of materials" for product and building design | filed 2026-09-15 (intent to use) |
| HYPHAE (word) | US serial 99339039 | Carbon Based LLC | **Dead**, abandoned 2026-09-22 | 42 | SaaS using AI (materials) | filed 2025-08-15. `name.md` still listed it as live |
| HYPHAE (word) | EUTM 019015906 | MycoWorks, Inc., Emeryville US | Registered | 9, 12, 16, 18, 25 | 9: phone cases, eyewear and similar (mycelium leather), **no software** | filed 2024-04-18, reg. 2024-09-07 |
| HYPHAE | US serial 97413053 | MycoWorks, Inc. | Dead, abandoned 2023-06-21 | 9, 12, … | phone cases etc. | filed 2022-05-16 |
| PROJECT HYPHAE | US serial 97070094 | FRSecure LLC | Live, registered 2022-12-20 | 42 | computer security consultancy | filed 2021-10-12 |
| HYPHAWAY | US serial 90842425 | HyphaWay, LLC | Live, registered 2026-06-02 | 42 | SaaS for financial planning | filed 2021-07-23 |
| HYPH (word) | EUTM 018598424 | HYPH Ireland Ltd | Registered | 9, 42 | music composition and creation software (a near-miss, not HYPHA) | filed 2021-11-11, reg. 2022-05-18 |

Who WI Licencing is: apparently the IP holder for the "Hypha" brand of Wireless Innovation Pty Ltd, Brisbane (inferred from the brand and the owner's Brisbane-suburb address, **not confirmed** in a company register). Wireless Innovation makes HyphaMESH portable mesh radios (HyphaCAP, HyphaMAP, the REX kit) for emergency services and mining ([Good Design](https://good-design.org/projects/hyphamesh-by-wireless-innovation/), [CCR 2022](https://criticalcommunicationsreview.com/ccr/news/107386/hypha-by-wireless-innovation-inc-announces-launch-of-the-deployable-hyphamesh-range-extension-rex-kit)). It is active: FY2025 annual report, Nov 2025 ([CCR](https://www.criticalcommunicationsreview.com/ccr/financial/117612/hypha-reports-strong-fy2025-performance-and-charts-course-for-global-expansion)), site [hypha.world](https://www.hypha.world/au/). The word-processing and photo-editing items are a long boilerplate goods list. Whether they were ever used is open, and that is exactly what a non-use challenge would test.

### Other HYPHA marks (other classes, low relevance)

| Mark | Number | Owner | Status | Classes / goods |
|---|---|---|---|---|
| HYPHA | US 90975033 | WI Licencing | Live, reg. 2023-01-10 | 38 telecom access |
| HYPHA | US 97508023, reg. 7436156 | Hyphametrics | Live, reg. 2024-07-09 | 41 online non-downloadable publications (marketing) |
| HYPHA | US 88750915, reg. 6135016 | an individual | Live, reg. 2020-08-25 (last USPTO activity 2025-08-25 per GleanMark) | 41 live music, composition |
| HYPHA | US 90607574 | Ontologie, Inc. | Live, reg. 2022-07-26 | 36 environmental investment advice |
| HYPHA (figurative) | EUTM 018907544 | UAB "Skin sync", Vilnius | Registered 2024-01-10 | 3 cosmetics with fungal ingredients |
| Hypha lite | EUTM 018496891 | ISA Tantec Ltd, Macau | Registered 2021-10-09 | 18 leather |
| HYPHA LITE, HYPHALUX | US 90810677, 90810671 | ISA Tantec Ltd | Live | 18 leather |
| HYPHA LABS | US 98442510 | Hypha Labs, Inc. | Live, reg. 2026-05-19 | 7 bioreactors |
| HYPHA NETWORK | US 50124267 | an individual | Pending | 44 psychedelic-assisted therapy |
| HYPHA LIFE NATURALLY POWERED BY MUSHROOMS | US 99809125 | Hypha Life, Inc. | Pending | 32 drinks |
| HYPHA EXPEDITION, HYPHA WORKS | US 97187534, 77770354 | — | Dead | 1/5, 12 |
| (figurative, word not shown) | DE 302014056973 | an individual, Berlin | **Deleted** 2024-09-01 | 9 social-app software, 35, 38, 42, 45 |
| PolyCYPs (owner name match) | IR 1396133 (EU) | Hypha Discovery Ltd, UK | Protected | biotech; the owner is called Hypha, the mark is not |

- **"HYPHA APP":** no mark of that wording, in DPMAregister (0 hits) or on Trademarkia (only the HYPHA marks above).
- **German national register (DE):** no live HYPHA or HYPHAE mark.
- **Not checked:** UK IPO; Australian register (WI Licencing's home market, likely a HYPHA mark there, **unverified**); EU/DE marks that merely begin with HYPHA (wildcards failed); WIPO Global Brand Database directly (captcha).

## 2. Products and companies named Hypha (activity in 2026)

None of them is a writing or note app, and none is on the Mac App Store. Closest to writing: the London "collaborative innovation" platform (now apparently gone) and Mycorrhiza Wiki, which calls its pages "hyphae".

| Name | What | Active in 2026? | Source |
|---|---|---|---|
| Hypha (WI Licencing / Wireless Innovation) | mesh-radio hardware for emergency services; **holds the class 9 marks** | yes (FY2025 report) | above |
| Hypha (Open Technology Fund) | open-source grant and submission management platform, owns hypha.app | yes: [HyphaApp/hypha](https://github.com/HyphaApp/hypha) 79★, pushed 2026-10-27; [docs.hypha.app](https://docs.hypha.app/) | GitHub |
| Hypha DAO / Hypha Limited | DAO tooling; iOS "Hypha Wallet" (Productivity, last update 2024-11-19), "SEEDS Light Wallet" | yes: [hypha-dao/hypha-web](https://github.com/hypha-dao/hypha-web) pushed 2026-10-28 | [App Store](https://apps.apple.com/us/app/hypha-wallet/id1659926348) |
| Hypha: Grow Mushrooms (Demeter Mycolabs LLC) | mushroom grow tracker, iOS/Android/web, App Store category **Productivity**; holds **hyphaapp.com** (registered 2026-09-24); no ™ shown | yes: updated 2026-10-23 | [App Store](https://apps.apple.com/us/app/hypha-grow-mushrooms/id6761784620), [hyphaapp.com](https://hyphaapp.com/) |
| HyphaMetrics | media audience measurement ("what the world is watching"); holds HYPHA in 16/35/41/42 | yes (site live; attorney change filed 2026-03-10) | [hyphametrics.com](https://www.hyphametrics.com/) |
| Hypha Worker Co-operative, Toronto | tech co-op | yes: [hyphacoop/handbook](https://github.com/hyphacoop/handbook) pushed 2026-10-19 | GitHub |
| CodeSoul-co/Hypha | LLM agent framework, **449★** | yes: pushed 2026-09-04 | [GitHub](https://github.com/CodeSoul-co/Hypha) |
| Hypha-ROS | robot car kits, 342★ and 266★ | no (last push 2020/2018) | [GitHub](https://github.com/Hypha-ROS) |
| amun-ai/hypha | AI app and data framework (PyPI `hypha`), 27★ | yes: pushed 2026-10-20 | [GitHub](https://github.com/amun-ai/hypha), [PyPI](https://pypi.org/project/hypha/) |
| Hypha, London | "collaborative innovation" platform, ~15 staff, founded 2020 | **probably not**: hypha.cc now redirects to a parking page | [Built In](https://builtinlondon.uk/company/hypha) |
| Mycorrhiza Wiki | file and Git based wiki engine whose pages are called "hyphae"; a writing-adjacent use of the word, not a product name | yes | [mycorrhiza.wiki](https://mycorrhiza.wiki/help/en/hypha), [GitHub](https://github.com/bouncepaw/mycorrhiza) |
| Other iOS apps | DanceHypha (social), Hyphae Learning (education), Hypha Dynamics Inc. apps (IssueID, SiteDNA) | yes | iTunes Search API |
| Setapp | no Hypha app found (web search; Setapp's catalogue not searched directly) | — | — |

GitHub counts: 559 repositories match "hypha", 155 match "hyphae". At or above 100★: CodeSoul-co/Hypha (449), Hypha-ROS/hypharos_minicar (342), Hypha-ROS/hypharos_racecar (266), and for "hyphae" jasonwebb/2d-space-colonization-experiments (227, generative art). None is a writing tool.

## 3. Domains

| Domain | State | Details |
|---|---|---|
| hypha.app | registered | since 2019-09-11, expires 2027-09-11; redirects to docs.hypha.app (OTF) |
| hypha.dev | registered | since 2025-03-19 (GoDaddy, locked); a "Launching Soon" page, "© 2025 Hypha", no product named |
| hypha.io | registered | no RDAP for .io; name servers at atom.com, and the site redirects to [atom.com/name/Hypha.io](https://www.atom.com/name/Hypha.io), a domain marketplace, so **apparently for sale** (price not seen, the page answered 403) |
| gethypha.com | registered | since 2022-02-22; parked, GoDaddy "for sale" page |
| hyphaapp.com | registered | since **2026-09-24**; Demeter Mycolabs' mushroom app |
| hypha.com | registered | since 2008-03-21 (Dynadot); no response over HTTPS |
| hypha.org | registered | since 2013; an artist's site, Seattle, apparently dormant |
| hypha.page | registered | since 2026-02-27; no response over HTTPS |
| **hyphawriter.app** | **free** | 404 at Google Registry |
| **hyphawrite.app**, **hyphaapp.app** | **free** | 404 |
| **hyphawriter.com**, **usehypha.com** | **free** | 404 at Verisign |
| hypha.ink | free | 404 "No data found" (premium pricing not checked) |
| hypha.so | probably free, **unverified** | no RDAP, no DNS delegation; WHOIS on port 43 timed out |
| hypha.writer | no such TLD | — |

"Free" means not registered on 2026-10-28. It says nothing about price.

## Sources

- DPMAregister: [basic search](https://register.dpma.de/DPMAregister/marke/basis), [terms of use](https://register.dpma.de/DPMAregister/service/nutzungsbedingungen). Records: EM 018663735, 018907544, 019015906, 018496891, 018598424; DE 302014056973; IR 1396133.
- US mirrors: Trademarkia ([hypha](https://www.trademarkia.com/search/trademarks?q=hypha), [hyphae](https://www.trademarkia.com/search/trademarks?q=hyphae), [90256874](https://www.trademarkia.com/hypha-90256874), [90975032](https://www.trademarkia.com/hypha-90975032), [90575917](https://www.trademarkia.com/hypha-90575917), [97508023](https://www.trademarkia.com/hypha-97508023), [50109978](https://www.trademarkia.com/hyphae-50109978)); GleanMark ([90256874](https://gleanmark.com/trademark/uspto-90256874), [90975032](https://gleanmark.com/trademark/uspto-90975032), [90575917](https://gleanmark.com/trademark/uspto-90575917), [88750915](https://gleanmark.com/trademark/uspto-88750915), [50109978](https://gleanmark.com/trademark/uspto-50109978), [90842425](https://gleanmark.com/trademark/uspto-90842425)). USPTO's own record (TSDR) for each: `https://tsdr.uspto.gov/#caseNumber=<serial>&caseType=SERIAL_NO` (not reached).
- RDAP: `https://rdap.org/domain/<name>`.
- App Store: `https://itunes.apple.com/search?term=hypha&entity=software&country=us`.
- GitHub: `https://api.github.com/search/repositories?q=hypha&sort=stars`.

## Raphe and Ductus

The same check for the two runner-up names from `name.md`, with the variants RAPHE/RAPHÉ and DUCTUS/DUKTUS (German spelling, identical in sound for a German speaker), on 2026-10-28.

**Method, and what changed since the Hypha check.** The same sources were used, and the same ones were unreachable: USPTO TSDR and tmsearch, EUIPO eSearch plus, TMview and WIPO. DPMAregister's expert search stopped working: the control query `md = hypha`, which gave 4 hits earlier the same day, now returns 0. The DE/EU/IR results below therefore rest on DPMAregister's smart search only. It searches the full text of each record (mark, owner, goods), and earlier it found all four HYPHA/HYPHAE EU marks, so it is a valid probe. It matches whole words only, though, so marks that merely start with these words are **not covered**. US records come from the Trademarkia search, plus GleanMark/Trademarkia detail pages for the full goods text; none was verified at TSDR. Products were checked with the iTunes Search API (US, Mac and iOS), the GitHub search API and web search. Domains were checked by RDAP (Google Registry, Verisign), with DNS for .io.

### Raphe: verdict

1. **Risk of confusion in class 9/42: low (low to medium in the EU).** There is no RAPHE or RAPHÉ mark anywhere I could check: DPMAregister has 0 hits for DE, EU and IR, and the US has a single dead filing in class 40. The nearest mark is **RAPHA** (Rapha Racing Ltd, the cycling-apparel brand): EUTM 016088676, registered 2017, class 9 including "Software für Videospiele; Mobile Apps". The two words are one letter apart, but they sound different (EN "RAF-uh" vs "RAY-fee"/"RAF-ee") and mean different things, and Rapha's goods are cycling goods. Its US class 9 registration (79205650) has no software (that part is struck out). Products called Raphe exist (a neuromarketing SaaS, an Indian drone maker), but none in writing.
2. **Personal use: no real risk** (no use in trade; the same reasoning as for Hypha).
3. **Before a public release:** a manual TSDR/EUIPO/UK check that includes RAPHA and sound-alikes (RAFE, RAPHAEL), which I did not search. raphe.app is still free if wanted. Of the three names, Raphe is the only one with no identical or same-sounding mark on software, so it is the only one where filing your own mark looks open (my judgement, not checked with a lawyer).

### Ductus: verdict

1. **Risk of confusion in class 9/42: low in the registries, medium in the German market.**
   - **DUCTUS:** no live mark in class 9 or 42 anywhere checked. Pelikan's DUCTUS for pens has lapsed (IR 966971 expired 2018; US 79054786 cancelled 2018); the German DUCTUS files are destroyed (dead).
   - **DUKTUS, the same sound in German:** DE word mark **"duktus" 397168403** (tempus GmbH, Giengen, a planner maker) covers class 9 "Computerhard- und -software", class 16 writing instruments and diaries, and class 41. It has been registered since 1997 and is renewed until 2027-04-30; it is old enough that the owner can be asked to prove use.
   - **Two writing-adjacent German products, unregistered, called "Duktus":**
     - a macOS dictation app "Duktus" (formerly "VoiceFlow", v0.5.0 on 2026-04-26, Fn-key dictation, German release notes; [releases](https://github.com/bottiman77/duktus-releases)), probably the one behind duktus.app (registered the same day, 2026-04-20, **link inferred**);
     - [duktus PRO](https://duktus-pro.de/): AI-drafted documentation for psychotherapists "from notes, dictation and case context"; active, its status page was updated 2026-10-28.

   In Germany a software title can be protected by use alone (Werktitel, §5 MarkenG; my understanding, not checked with a lawyer). So these two count even without a registration.
2. **Personal use: no real risk.**
3. **Before a public release:**
   - a lawyer's check that includes German title rights (Werktitel);
   - whether tempus still uses "duktus" for software, and whether it renews in April 2027;
   - keep the Latin spelling *Ductus*: in the registries it is clean, while *Duktus* is crowded.

   ductus.app and ductus.dev are taken; ductusapp.com and ductuswriter.app are free.

### Raphe and Ductus: trademark hits

| Mark | Office, number | Owner | Status | Classes | Goods (relevant part) |
|---|---|---|---|---|---|
| RAPHE PHARMACEUTIQUE LABORATORIE | US 97816115 | an individual | **Dead**, abandoned 2025-03-17 | 40 | custom manufacture of OTC drugs |
| RAPHE, RAPHÉ | DE / EM / IR | — | **no hits** (DPMAregister smart search) | — | — |
| RAPHA (near miss) | EUTM 016088676 | Rapha Racing Ltd, London | Registered 2017-03-29, expires 2036 | 3, **9**, 12, 16, 35, 39, 41, 43 | 9: eyewear, helmets, downloadable publications, "Software für Videospiele; **Mobile Apps**" |
| RAPHA (near miss) | US 79205650 | Rapha Racing Ltd | Live, registered | 9, 16, … | 9: eyewear, helmets, downloadable image and multimedia files (cycling); software and computers struck out |
| RAPHA (near miss), other | EUTM 003820354 (18, 25), 019381006 (an individual, 16/36/41/43–45, registered 2026-09-25), RAPHA MYR 018063499 (5) | — | registered | not 9/42 | — |
| DUCTUS | US 79054786 | Pelikan Vertriebsgesellschaft mbH & Co. KG | **Dead**, cancelled 2018-04-04 | 16 | writing instruments, fountain pens |
| Ductus | IR 966971 (EU) | Pelikan Vertriebsgesellschaft | **Lapsed** (expiry 2018-04-04) | 16 | stationery, writing instruments |
| ductus / Ductus | DE 1132679, 304706450, 307337928, 307340449 | — | dead (file destroyed) | — | — |
| UNUS · PROBITAS INTEGRITAS · DUCTUS | US 97503885, 97503864 | International Brotherhood of Omega Delta Phi | Live | 25, 35 | fraternity clothing and association services |
| other US DUCTUS compounds | US 75701990, 87615955, 85257916 | — | Dead | 41, 37, 14/35 | — |
| **duktus** (word) | **DE 397168403** | tempus GmbH, Giengen | **Registered** 1997-05-28, protected until 2027-04-30 | **9**, 16, 41 | 9: "Computerhard- und -software"; 16: printed matter, "Schreibgeräte", "Kalender, Tagebücher"; 41: management training |
| DUKTUS (word) | DE 303378468 | an individual, Stuttgart | Registered 2003-12-09, until 2033-07-31 | 35, **42** | 42: "Aktualisierung von Internetseiten; Design von Home-Pages und Web-Seiten; digitale Bildbearbeitung"; 35: advertising agency |
| DUKTUS STUDIO | DE 3020202456719 | an architects' partnership, Berlin | Registered 2021-01-14 | 16, **42** | 42: product, shop and furniture design (architecture) |
| DUKTUS (word and figurative) | EUTM 008448169, 009098451, 011030889, 011030897; IR 1077783 | vR production (DUKTUS) GmbH, Wetzlar (ductile iron pipes) | Registered | 6, 40, **42** / 17, 19, 20 | 42: engineering research, quality testing, technical consulting (pipes) |
| (figurative) | DE 3020192416124 | CFQ Handels GmbH | Registered | 25, 27 | shoes, clothing, yoga mats |
| DUKTUS | US 79087497, 79135159, 79076948, 79133067 | Duktus (Production) GmbH | **Dead** (2014–2020) | 6, 40, 17, 19 | pipes |

DPMAregister smart search for "duktus" also lists marks that only mention it in the owner's name (the pipe maker's BLS, BRS, TSP, TYTON SIT PLUS, VRS, TELL, Plug & Play). They are left out above.

### Raphe and Ductus: products and companies

| Name | What | Active in 2026? | Source |
|---|---|---|---|
| Raphe (raphe.io) | "predictive intelligence software that decodes creative performance at the neural level" (neuromarketing SaaS, waitlist) | yes, the site is live | [raphe.io](https://raphe.io/) |
| Raphe mPhibr | Indian aerospace and drone maker, holds raphe.com | yes | [raphe.com](https://www.raphe.com/) |
| raphe.dev | a freelance web developer's portfolio (French) | yes | raphe.dev |
| Raphe on the App Store or GitHub | none; GitHub has 252 repositories, all names like "Rapheal…", top 3★; one small CLI `raphecrypt` | — | APIs |
| **Duktus (Mac app)** | Fn-key dictation app for macOS, formerly VoiceFlow, German | v0.5.0 2026-04-26; nothing newer seen | [GitHub releases](https://github.com/bottiman77/duktus-releases) |
| **duktus PRO** | AI-drafted clinical documentation from notes and dictation, for psychotherapists (DE) | yes, status page updated 2026-10-28 | [duktus-pro.de](https://duktus-pro.de/), [status repo](https://github.com/jqttk/duktus-status) |
| Ductus (getductus.com) | "code-first integration engine for healthcare", Rust and TypeScript, "in development"; domain registered 2026-10-07 | yes, new | [getductus.com](https://getductus.com/) |
| Ductus (ductus.com, formerly Data Ductus) | IT consultancy, Sweden | yes | [ductus.global](https://ductus.global/) |
| Ductus (research tools) | free Windows handwriting-analysis software (HAL record); UC3M "Ductus Generator" for transcribing manuscripts | academic | [HAL](https://hal.archives-ouvertes.fr/hal-00828824), [UC3M](https://www.uc3m.es/innovacion/media/innovacion/doc/archivo/doc_ot176/uc3m-176_ductus-generator.pdf) |
| Pelikan Ductus | a former fountain-pen line (mark lapsed in 2018) | no | registers |
| Ductus/Duktus on the App Store | none (Mac or iOS); GitHub has 72 repositories for "ductus" (top: wikiotics/ductus, retired) and 9 for "duktus" | — | APIs |

### Raphe and Ductus: domains

| Domain | State | Details |
|---|---|---|
| **raphe.app** | **free** | 404 at Google Registry |
| raphe.dev | registered | since 2025-03-25 (GoDaddy); a developer portfolio |
| raphe.io | registered | no RDAP for .io; DNS at Namecheap, the site is the neuromarketing SaaS |
| raphe.com, raphe.org | registered | 2002 (Raphe mPhibr), 2023 |
| **rapheapp.com, getraphe.com, raphewriter.app** | **free** | 404 at Verisign / Google Registry |
| ductus.app, ductus.dev | registered | both on 2024-09-20 via Cloudflare; no response over HTTPS |
| ductus.io | registered | name servers at Afternic (a domain marketplace), so apparently for sale (**unverified**) |
| ductus.com, ductus.org, getductus.com | registered | 1995 (IT consultancy), 2022, **2026-10-07** (healthcare engine) |
| duktus.app | registered | 2026-04-20 (INWX); a page titled "Duktus" |
| **ductusapp.com, ductuswriter.app, duktusapp.com** | **free** | 404 at Verisign / Google Registry |
