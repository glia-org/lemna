# A mindful theme for Lemna: the look, its ambience and the theme model (as of 2026-10-31)

Question (the user, 2026-10-31): a second theme that "leans a lot more into the mindfulness side of things ... a user
interface theme that is much more minimalism", with ambient sounds (wind chimes, light rain) and ambient animations to
match, and a theme system so that more can follow. Today's one look (the user's "nerd mode", liked and kept): box
#0e1013, text #d8dce3, accent #7aa7f0, Menlo 28, a 1 pt accent border (B1), 10 pt corners, the dim the box's colour at
0.5 (D1), DESIGN T2, F1, A1, L1 and N (Lemna is duckweed: fronds floating on still water).

Read first: DESIGN T2 (in F1), F0, F1, A1, L1, N; `research_notes/Flow writing tool design options/prior_art_tools.md`
(the tools surveyed for mechanics), `flow_psychology.md` §8 (calm framing), `research_notes/Flow sounds and
ambience/visuals.md` (the evidence on motion beside a text task, Breathe, the HIG; not repeated here, cited by
section) and, in this folder, `architecture.md` (where the look lives in the code, three theme models, the light-theme
traps). This note is about the look; the sound bed and the click pack are `architecture.md` §4 and K1's.

Tags: **[E]** evidence (a study or a standard), **[P]** practice (what an app ships or its maker says), **[M]**
measured or computed here, **[I]** inference. UNVERIFIED marks what could not be checked on a primary page.

Method: web search and pages (two of the surveys, theme systems and calm-app palettes, were done by delegated agents and
spot-checked: ZenPen's CSS re-read through the GitHub API, OmmWriter's pages re-read); Bear 2's theme files read from the
JSON it ships inside its app bundle; Google Fonts' metadata and the font repositories' licences read through their
APIs; x-heights measured with Core Text at 28 pt (installed fonts, and OFL fonts downloaded from `google/fonts`);
contrast ratios with the WCAG 2 formula; a dim's look computed as an alpha blend in sRGB-encoded values (the way a
window over another is usually composited; not checked against WindowServer). Screens: a 14-inch 3024 × 1964 panel at
50 cm, where 1 pt = 0.200 mm = 1.38 arcmin [M].

## Takeaway

1. **Calm writing apps are quiet, not decorated** [P]: near-white or warm-paper surfaces (L 0.80–1.0) or near-black,
   never pure white on pure black in their calm themes; body text at 7–10:1, not 15–20:1; no border round the writing
   area; one accent; still backgrounds; UI fades of 250–600 ms and no motion of the text (§1). OmmWriter, the closest,
   bundles nothing: background, music, key sound and font are separate choices, and its critics name repetition and an
   abrupt stop, not the look (§1.1).
2. **Light or dark:** dark-on-light reads better for normal vision, by little at Lemna's size [E]; in Lemna a pale box
   is also the only one that is never darker than its dimmed surround, which lighting standards ask for, and a pale wash
   draws slow gradients without banding (one 8-bit step is 1 % of luminance at code 230 against 8.8 % at code 14) [M].
   Against it: summoned over a dark app, a pale wash brightens the whole screen about 7× as a contrast ratio (§2.1).
   **Follow the system appearance**: paper by day, a warm dark by night.
3. **Contrast can drop from 13.9:1 to about 9:1 at no cost**: reading speed is "very tolerant to contrast reduction"
   for letters of 0.25–2° (Lemna's em is about 0.64°), and alike for either polarity (Legge et al. 1987) [E]. At 28 pt
   Lemna's line is WCAG "large text": AA asks 3:1, AAA 4.5:1 (§2.2).
4. **Type is character, not legibility**: serifs make no measurable difference (Arditi & Cho 2005), the fastest font
   differs per reader (Wallace et al. 2022), rounder letters felt more pleasant and read a little faster (Medved et al.
   2023) [E]. A proportional face shows about 40 % more text per width than Menlo and needs about 30 pt to keep Menlo
   28's x-height [M]. iA Writer's fonts are OFL but their makers ask text editors not to bundle them (§2.3).
5. **The calm motion register is the HIG's Reduce Motion register applied by taste**: fades instead of scaling and
   travel; the glide's 140 ms stays, since slower text reads as lag (§2.7).
6. **Ambience:** no speed threshold was found under which motion stops costing a text task; onsets capture, travel
   distracts most, discrete beats continuous (`visuals.md` §2). What a mindful scene can do is be slow, sparse, onset-
   free and mostly still, and recede while the writer types. Nature scenes restore attention in *breaks* (Lee et al.
   2015; modest overall, Ohly et al. 2016), not beside a task (§3.1).
7. **Rings on still water** are the one scene that is Lemna's own habitat and also the cheapest of the mindful set to
   draw well: three crests, a still centre, amplitude falling with radius and time, crossing rings adding (§3.2).
8. **Theme models elsewhere** [P]: writing apps theme colours and keep the font apart; terminals bundle more; nearly
   nobody bundles sound; following the system's light/dark is the norm; user overrides usually survive a switch because
   they live in another layer, and only VS Code scopes them per theme (§4). This supports `architecture.md`'s A (a
   preset that writes the existing axes) for Lemna.
9. **Recommendation (§5):** a theme "Still": paper #F3F0E8 / text #46433D / duckweed-green caret #577446 on a pale
   sage wash #D3D8CE at 0.74 by day, and #1C1B18 / #E2DACA / sage #A2B88E on #0F1412 at 0.62 by night; Literata 30 pt;
   no accent border, a tonal hairline; 16 pt continuous corners; open by fade alone; Ripples as its ambience, a drop per
   word, rare drops at rest, nothing per key.

## 1. Prior art: what calm writing, focus and meditation apps look like

### 1.1 OmmWriter, the closest

- **Versions, not "chapters"** [P]: no "chapter" or named look was found on its pages or in reviews. Dāna I (2010,
  free) had three backgrounds and three soundscapes; Dāna II eight backgrounds and seven soundscapes, "some of them ...
  more than just static pictures" ([Cult of Mac 2010](https://www.cultofmac.com/news/ommwriter-updated-pay-what-you-like-as-long-as-it-ends-in-a-1-review));
  the current GAIA has "10 backgrounds" that cannot be customised ([FAQ](https://ommwriter.com/faq)), nine tracks (four
  ambient, five instrumental, with titles like "The speed of a cloud") and five typefaces: Open Sans, DejaVu Sans, Noto
  Serif, PT Serif, Cygnet Round ([description](https://ommwriter.com/description/)).
- **The look** [P]: full screen, the toolbar hidden while typing; still nature images (a snowscape with leafless trees),
  all-white, grey linen and coloured gradients ([Macworld 2012](https://www.macworld.com/article/217142/ommwriter_dana_helps_you_focus_when_writing.html));
  "the gentle hues of blue, red and white, fade and mix into one another" ([a 2013 user review](https://writeoutloudblog.com/2013/09/14/ommwriter-a-must-for-the-distracted-writer/));
  GAIA: backgrounds "emulating the passing of the day" and two made with "a colour therapy expert, using chromotherapy
  and the studied movement of colour" ([description](https://ommwriter.com/description/)).
- **How audio and picture combine** [P]: as separate choices, not sets: "The menu has six different items: font, font
  size, background image, music, typing sound, and saving your document" ([MakeUseOf 2012](https://www.makeuseof.com/tag/meet-writing-deadlines-distraction-free-writing-environment-ommwriter/));
  one device volume for music and keys, each only mutable ([FAQ](https://ommwriter.com/faq)); the music stops when you
  leave: "if you leave the bubble, the music stops automatically" (FAQ), which a fan found jarring: "you are jerked,
  rudely back into the 'real world'" (the 2013 review).
- **What worked** [P]: the isolation and the key sounds ("well-designed and in the background", the 2013 review;
  Capterra reviews in `prior_art_tools.md`); a seamless loop.
- **What did not** [P]: repetition ("They can get old pretty quickly", "the musical hamster wheel"), the grey linen
  "doesn't contrast enough", a "very small underscore cursor that can be difficult to spot", no volume control, unlabelled
  round buttons (Macworld). No review found calls it kitsch; the nearest are the repetition and the chromotherapy claim,
  for which no evidence was found (warm or shifting colour at a box's light level is physiologically null,
  `visuals.md` §2.5).
- **For Lemna** [I]: OmmWriter's calm is the empty full screen and the sound, not its pictures. Its two failures are
  Lemna's to avoid: a cursor too thin to find, and a bed that loops audibly.

### 1.2 Writing apps' calm looks

| App | Surface / text (contrast) | Type | Edge, motion | Source |
|---|---|---|---|---|
| ZenPen (MIT) | light #fdfdfd / #111 (18.6:1); dark #111 / #fafafa (18.1:1) | Lora, 22 px on 30 px | no border; theme swap `transition: all 600ms`, UI opacity 400 ms, panels 250 ms; radii 3–5 px on controls | [style.css](https://github.com/tholman/zenpen/blob/master/css/style.css) [P, read] |
| Bear 2, Red Graphite (default) | #ffffff / #444444 (9.7:1), secondary #888888, accent and cursor #DD4C4F (4.0:1) | "BearSansUI", 15 pt, line height 1.5 | — | the theme JSON in Bear's bundle [P, read] |
| Bear 2, Duotone Snow | #fdfdfd / #44526b (7.7:1), accent #d37e7e | as above | — | same |
| Bear 2, Solarized Light | #fdf6e3 / #323e45 (10.2:1) | as above | — | same |
| Bear 2, Everforest Light / Rosé Pine Dawn / Catppuccin Latte | #FFFBEF / #4E5659 (7.3:1); #faf4ed / #575279 (6.7:1); #EFF1F5 / #4c4f69 (7.1:1) | — | — | same |
| Bear 2, Dark Graphite / Everforest Dark / Rosé Pine | #1D1E1F / #DFE0E0 (12.6:1); #1E2326 / #D3C6AA (9.4:1); #232136 / #e0def4 (11.9:1) | — | — | same |
| Solarized (the palette) | base3 #fdf6e3 / base00 #657b83 (4.1:1): "reduces brightness contrast but ... retains contrasting hues"; "Black text on white ... is akin to reading a book in direct sunlight and tires the eye" (a maker's claim) | — | — | [ethanschoonover.com](https://ethanschoonover.com/solarized/) [P] |
| Everforest | "designed to be warm and soft in order to protect developers' eyes" (a maker's claim) | — | — | [README](https://github.com/sainnhe/everforest) [P] |
| iA Writer | Light/Dark, "Match system appearance"; own hex values UNVERIFIED (an iA-like community theme: #F7F7F7 / #1A1A1A, 16.2:1; accent #18BEEC) | iA Writer Mono/Duo/Quattro, "modified versions of IBM Plex"; duospace gives m, M, w, W 50 % more room; a single-storey g because fewer shapes look calmer | three sizes that follow the window | [settings](https://ia.net/writer/support/basics/settings), [duospace](https://ia.net/topics/in-search-of-the-perfect-writing-font), [iA-Fonts](https://github.com/iaolo/iA-Fonts) [P] |
| Calmly Writer | themes Light, Dark, Dark Blue, Dune, Old School; focus dims all but the paragraph; a customisable caret, "hide the caret while typing" | OpenDyslexic offered | hex UNVERIFIED | [site](https://calmlywriter.com/), [help](https://calmlywriter.com/help.htm) [P] |
| Ulysses | a theme holds a palette with light and dark modes; fonts are a separate setting | — | — | [editor themes](https://help.ulysses.app/styles-themes/editor-themes) [P] |
| Freewrite devices | E Ink, front-lit on the Smart Typewriter, not on the Traveler; "looks like printed paper"; lag the one complaint | screen fonts UNVERIFIED | — | [Freewrite](https://getfreewrite.com/pages/freewrite-e-ink-display), `prior_art_tools.md` [P] |
| Flowstate, Blank Page, Cold Turkey Writer | no visual specification found | | | — |

Contrast ratios computed here [M].

### 1.3 Meditation apps

- **Apple Breathe / Mindfulness** [P]: a blue-green flower of translucent circles that grows on the inhale and shrinks
  on the exhale; about 7 breaths a minute by default, 4–10 adjustable; reported 4 s in / 6 s out; haptics carry the
  rhythm with eyes closed; it is the foreground task, never shown beside one (`visuals.md` §4.1). The easing is not
  published (UNVERIFIED).
- **Apple's breathing sleep light** [P]: a sinusoid with a rest at zero, "a simple linear ramp does not seem as
  natural" (US 6,658,577; `visuals.md` §4.2): the one published rule for calm luminance motion.
- **Calm** [P]: a "Scene" is "the visual background and ambient sound" as one, e.g. Rain on Leaves, Mountain Lake,
  with a Scene Volume slider and silent scenes ("Silent Earth") ([Calm help](https://support.calm.com/hc/en-us/articles/115002474307)):
  picture and bed bundled at the scene, not at the theme. No official palette is published (a blue near #60B0E7 is
  an outside estimate, UNVERIFIED).
- **Headspace** [P]: a proprietary cut of Aperçu (secondary), a saturated orange (hex estimates vary:
  #FF7E1D, #F47D31), illustration rather than photography; a breathing circle reported at 4 s in, 6 s out, ease-in-out,
  from a reconstruction, not Headspace ([third-party guide](https://blakecrosley.com/guides/design/headspace), UNVERIFIED).

### 1.4 Paper and e-ink

- E-ink is reflective, so "paper" on a backlit screen can only be a colour [I]. Published or sampled paper colours: a
  2011 Kindle's sepia #f1e7d0 (forum-measured, UNVERIFIED for current apps); Apple Books' Focus theme about #FFFCF4
  (sampled by a developer, [forum](https://developer.apple.com/forums/thread/730524)); Solarized #fdf6e3; Everforest
  #FFFBEF; Rosé Pine Dawn #faf4ed. Apple Books' theme colours are compiled into the app (not readable as files).
- Warmth does not protect the eyes or sleep at a box's light level: the box emits ≲0.4 % of a white screen's light,
  two to three orders under the evening limit (`visuals.md` §2.5). A warm paper is taste and association [I].
- Literata was commissioned for Google Play Books as its default e-book face (2015) and is OFL ([Wikipedia](https://en.wikipedia.org/wiki/Literata)).

### 1.5 Evidence-backed or decoration

| Feature | Status | Why |
|---|---|---|
| Full-screen isolation, hidden chrome | backed in spirit | calm technology's "smallest possible amount of attention" (`flow_psychology.md` §8); Lemna's dim already does it |
| Key sounds | liked, small evidence | `flow_psychology.md` §5 |
| Reduced but adequate contrast | backed | Legge et al. 1987 (§2.2) |
| Positive polarity (dark on light) | backed, small at large sizes | Piepenbrock et al.; Dobres et al. 2017 (§2.1) |
| Warm paper colour, warm text on dark | taste; one study for warm text on dark | Fan et al. 2024 (§2.1) |
| Nature backgrounds, still | mood; restorative only when looked at in breaks | Lee et al. 2015, Ohly et al. 2016 (§3.1) |
| Moving or colour-shifting backgrounds ("chromotherapy") | decoration, with a cost when seen | `visuals.md` §1, §2.1–2.2 |
| Breathing animations | foreground exercises; a pacer beside a task competes with it | `visuals.md` §2.4 |
| Sound beds | at best neutral for a typical writer | `sounds.md` §8.1 |

## 2. "Minimal and calm" in measurable terms, for one line in a box

### 2.1 Light or dark surface

- **Performance** [E]: with normal vision, dark-on-light won proofreading and acuity at every age; the advantage grows
  as characters shrink and was not felt by the readers (Piepenbrock et al., `visuals.md` §2.6); at night light mode
  performed better in a glance-reading task, by day no difference (Dobres, Chahine & Reimer 2017); NN/g: "in users with normal
  vision, light mode leads to better performance most of the time", yet offer dark ([NN/g 2020](https://www.nngroup.com/articles/dark-mode/)).
  At Lemna's 28–30 pt the small-character cost is minimal (`visuals.md` §2.6).
- **Fatigue** [E]: 30 tablet users showed no difference in visual fatigue between modes, small differences in
  flicker fusion and dry eye ([Sengsoon & Intaruk 2025](https://doi.org/10.3390/ijerph22040609));
  under negative polarity, yellow text gave the least fatigue and red the most, and more ambient light helped
  ([Fan et al. 2024](https://doi.org/10.3390/s24113516)). For a dark variant: warm off-white text, not blue-white.
- **The surround** [E, M]: EN 12464-1 wants the task brighter than its near surround (≤3:1) (`visuals.md` §2.6). Box
  against dimmed surround, as (L+0.05) ratios:

| Look | over a black app | over a #1E1E1E app | over a white app |
|---|---|---|---|
| Today (#0e1013, dim #0e1013 at 0.5) | 1.05 | 0.93 | 0.28 (surround 3.6× the box) |
| Paper #F3F0E8 on a #D3D8CE wash at 0.74 | 2.34 | 2.05 | 1.15 |
| Dusk #1C1B18 on a #0F1412 wash at 0.62 | 1.14 | 0.93 | 0.30 |

  Only the pale box meets the standard over every app [M].
- **The summon** [M]: a pale wash over a dark app raises the screen's luminance from 0.013 to 0.38 (a 6.9× ratio) at
  every summon, a full-screen brightening that the dark looks never cause. One such change is no flash hazard (WCAG
  2.3.1 counts three a second), but at night it is glare. A light theme should therefore come with a dark variant
  chosen by the system appearance, the way Ulysses, iA Writer, VS Code, Ghostty and kitty follow it (§4).
- **Gradients** [M]: one 8-bit code step is +8.8 % luminance at code 14 (today's box), +5.8 % at 28, +1.0 % at 220–243.
  A mist, a breath or a fading ring can be drawn smoothly on a pale wash and bands on a dark one unless dithered.

### 2.2 Contrast

- **Reading tolerates less contrast** [E]: "Within this range [0.25–2°], reading was very tolerant to contrast
  reduction—for 1 degree letters, reading rate decreased by less than a factor of two for a tenfold reduction in
  contrast. The results were very similar for white-on-black and black-on-white text" ([Legge, Rubin & Luebker 1987](https://doi.org/10.1016/0042-6989(87)90028-9)).
  Lemna's 28 pt em is about 0.64° at 50 cm (`visuals.md` §2), inside the range.
- **The standards** [E]: WCAG 1.4.3 AA asks 4.5:1, or 3:1 for large text (18 pt, i.e. 24 CSS px, or 14 pt bold); 1.4.6
  AAA 7:1 and 4.5:1 ([W3C](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)). Lemna's 28 pt macOS
  points draw at about 28 CSS px: large text [I]. Non-text parts the user must see (the caret, a hairline that is the
  only edge) need 3:1 under 1.4.11 ([W3C](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)). The
  HIG asks at least 4.5:1 and "strive for" 7:1 for custom colours (`visuals.md` §4.3).
- **What calm apps choose** [P, M]: 6.7–10.2:1 in Bear's calm light themes, 9.4–12.6:1 in its dark ones (§1.2); only
  ZenPen and an iA-like theme go to 16–19:1.
- **For Lemna** [I]: text about 9:1 by day and 12:1 by night keeps AAA with a margin and is visibly softer than 13.9:1;
  muted at least 3:1 (large-text AA), 4.5:1 under Increase Contrast; the caret at least 4.5:1, being the one mark the eye
  keeps; the V2 fade may go under 3:1 on purpose, as today.

### 2.3 Type

- **Serif or sans** [E]: fonts differing only in serifs did not differ in legibility or reading speed ([Arditi & Cho
  2005](https://doi.org/10.1016/j.visres.2005.06.013)); across 16 fonts the fastest and slowest font differed by 35 %
  in words per minute per reader, preference did not predict speed, and "one font does not fit all" ([Wallace et al.
  2022, TOCHI 29(4)](https://jeffhuang.com/papers/Readability_TOCHI22.pdf)). Round or rounded letters were rated more
  pleasant and read faster than angular ones (eight typefaces, children and adults, [Medved et al. 2023](https://doi.org/10.3389/fpsyg.2023.1107839));
  round typefaces led listeners to expect smoother, calmer music and made neutral music seem more pleasant (an Oxford study, [ORA](https://ora.ox.ac.uk/objects/uuid:7beb83c1-86ab-4fe4-b1d4-78297324d8a5)).
  The writer reads a few words at a time on Lemna's line, so reading speed matters less than the line's feel [I].
- **Size and density** [M], Core Text at 28 pt, a sample sentence of 44 characters:

| Face | Licence, bytes | x-height at 28 pt | pt per character | Size for Menlo 28's x-height (15.3 pt) |
|---|---|---|---|---|
| Menlo (today) | system | 15.3 (0.55 em) | 16.9 | 28 |
| SF Pro (system) / SF Pro Rounded (`.rounded`) | system, 0 B | 14.2 (0.51) | 11.9 | 30 |
| New York (`.serif`) | system, 0 B | 11.8 (0.42) | 12.5 | 36 |
| Charter / Iowan Old Style | installed with macOS, 0 B | 13.6 (0.49) | 12.3 / 12.6 | 31.5 |
| Seravek / Optima / Avenir Next | installed with macOS, 0 B | 13.4 / 13.4 / 13.1 | 12.0 / 12.0 / 12.8 | 32 / 32 / 32.7 |
| Literata (opsz 7–72) | OFL, 0.96 MB variable | 14.1 (0.50) | 12.3 | 30.4 |
| Source Serif 4 (opsz 8–60) | OFL, 1.21 MB | 13.3 (0.48) | 12.2 | 32.2 |
| Newsreader (opsz 6–72) | OFL, 0.45 MB | 11.9 (0.43) | 10.9 | 35.9 |
| Fraunces (opsz 9–144, SOFT 0–100) | OFL, 0.36 MB | 13.5 (0.48) | 12.0 | 31.7 |
| IBM Plex Serif / Sans | OFL, 0.16 / 0.54 MB | 14.4 / 14.2 | 13.1 / 12.1 | 29.7 / 30.2 |
| Inter (opsz 14–32) | OFL, 0.88 MB | 14.6 (0.52) | 11.3 | 29.3 |
| Atkinson Hyperlegible Next | OFL, 0.11 MB | 13.9 (0.50) | 11.8 | 30.8 |
| Nunito (rounded) | OFL, 0.28 MB | 13.6 (0.48) | 12.2 | 31.6 |
| EB Garamond | OFL, 0.85 MB | 11.2 (0.40) | 10.5 | 38.2 |

  Variable fonts measured at opsz 28 where they have the axis. Licences: the repositories' (`rsms/inter`,
  `adobe-fonts/source-serif`, `googlefonts/literata`, `productiontype/Newsreader`, `IBM/plex`,
  `googlefonts/atkinson-hyperlegible-next`, `octaviopardo/EBGaramond12`, `googlefonts/fraunces`), all OFL-1.1; sizes
  are `google/fonts`' files. System designs come from `NSFontDescriptor.withDesign(_:)` (`.serif`, `.rounded`,
  `.monospaced`), macOS 10.15 ([Apple](https://developer.apple.com/documentation/appkit/nsfontdescriptor/withdesign(_:))),
  usable without bundling; Charter, Iowan Old Style, Athelas and Seravek sit in the sealed system volume's
  `Supplemental` fonts on macOS 26 [M].
- **iA Writer's fonts** [P]: OFL-1.1 (the `LICENSE.md` beside each family), but the makers' guidelines say "Do not
  create text editors that bundle our fonts or use them as their default typefaces. This includes minimalist text
  editors" and point to IBM Plex instead ([iA-Fonts README](https://github.com/iaolo/iA-Fonts)). Lemna is such an
  editor: leave them out.
- **What changes with a proportional face** [M, I]: about 40 % more text per width (12 vs 16.9 pt a character), so
  V2's visible span holds more words; each glide step varies with the glyph (an i moves less than an m), which is how
  type moves on paper. The code's Menlo assumptions (Drift's cell, `Line.tail`, the ambience atlas made once, Rain's
  grid) are `architecture.md` §6's list; Rain's grid should keep a monospaced face whatever the line uses.

### 2.4 The edge: border, shadow, corners

- **Border** [P]: none of the calm writing apps draws a border round its writing area (§1.2). B1's 1 pt accent border
  is today's look's one bold line; a calm look drops it.
- **But the box must still be found** [M]: on a pale wash over a white app the box is only 1.15× its surround, so it
  needs an edge: a shadow (a sheet on a table), a hairline a shade darker than the box, or a difference of temperature
  (warm paper on a cool sage wash). A hairline #D9D4C8 on #F3F0E8 is 1.30:1: an edge, not a line. `architecture.md` §7
  notes the system shadow is dropped on the hand-off's first frame, a pop on a light dim; so a hairline plus the warm/cool
  split, and a shadow only once that drop is fixed.
- **Corners** [E, P]: people prefer curved objects to sharp-angled ones ([Bar & Neta 2006](https://doi.org/10.1111/j.1467-9280.2006.01759.x));
  macOS 26 windows use larger radii than before, and not one radius for all ([a developer's survey](https://mjtsai.com/blog/2025/10/16/tahoe-window-corners)).
  `CALayer.cornerCurve = .continuous` (macOS 10.15) draws Apple's continuous corner, which has no curvature jump where
  the straight edge meets the arc [P]. For a 4 em box (112–120 pt tall), 16 pt is 13–14 % of its height: rounder than
  today's 10 pt, still a card, not a pill [I].

### 2.5 The dim

- **Strength** [M]: today's 0.5 passes half the screen behind; Paper's wash at 0.74 hides the app behind more, so the
  box becomes the brightest, flattest thing on screen; Dusk at 0.62 cuts night glare over a light app (surround L 0.15
  instead of 0.25).
- **Colour** [I]: the water. A pale sage-grey wash (#D3D8CE) under a warm paper box makes the box read as a leaf on
  water even where their luminances meet; at night a deep green-black (#0F1412).
- **A real blur is possible** [P]: the dim is a window per screen, so each can hold an `NSVisualEffectView` with
  `blendingMode = .behindWindow`, which "blends and blurs ... with the contents behind the window, such as the desktop
  or other windows" ([Apple](https://developer.apple.com/documentation/appkit/nsvisualeffectview/blendingmode-swift.enum/behindwindow)),
  material `.fullScreenUI` ("the background of a full-screen modal interface") or `.hudWindow`, with a tint layer and
  the ambience's Metal layer over it; macOS 26 adds `NSGlassEffectView`. Limits: the blur radius is not settable through
  public API, the material's tint follows the appearance, Reduce Transparency makes it solid, and its cost over a whole
  screen is not measured [I]. The larger cost is functional: under a blur the app behind cannot be read, and Lemna
  writes into it, often in answer to what it shows [I]. Hence an option ("Mist", §5.3), not the default.
- **Without a blur** [I]: a high-alpha pale wash already reads as frosted; a ±1-code static noise can dither a light
  gradient but adds nothing as texture (`visuals.md` §1, candidate e).

### 2.6 The caret

- Keep the bar [P, I]: OmmWriter's underscore was "very small ... difficult to spot" (Macworld); Lemna's caret is the
  fixation point and never moves. A 2 pt × 1.2 em bar (today's `Line.caretRect`), ends rounded by 1 pt, steady (macOS
  has "Prefer non-blinking cursor"; Lemna never blinks), in the one accent at ≥4.5:1.
- An underline would sit under the baseline, away from where the new glyph emerges, and could be read as a text
  decoration [I].

### 2.7 Motion in a calm register

- The HIG's Reduce Motion practice is "Replacing transitions in x-, y-, and z-axes with fades" (`visuals.md` §4.3);
  Bartram ranks blink < linear < zoom < travel in distraction (`visuals.md` §2.2). A calm open is therefore a fade with
  no 87 % scale, the same 300 ms on F1's curve [I].
- The glide stays 140 ms on easeOutQuint: animated text position already reads as lag in other tools when long
  (`visuals.md` §6.1), and slower is not calmer at the fixation point [I]. The glyph fade's 80 ms can stay; 140 ms (on
  F1's scale) is the try if the line should feel softer.
- The hand-off may keep H1 (the one bold moment, F1), or take a calm form: the line's glyphs fade in place over 200 ms
  while one ring leaves the box's outline across the wash and fades by 1.2 s, the text "dropped into the water". That
  ring is a discrete, self-caused event at the end of a session, not in a planning pause (F0's (g) objection was to a
  ring on Return) [I].

### 2.8 The menu-bar mark

- The HIG: menu bar extras use images whose "black and clear colors ... define their shapes; the system can apply
  other colors" ([HIG, the menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)). The mark
  (L1's M3, a template) is drawn by the system in the menu bar's colour whatever Lemna's theme, and it is already a
  line and a caret. Minimal means leaving it alone; a mark per theme would be invisible as a theme cue and cost a second
  icon set [I].

## 3. Ambient animation in a mindful register

### 3.1 What the evidence allows

- Already established (`visuals.md` §2): abrupt onsets, motion onsets, looming and travel capture attention; gradual
  change goes unseen; continuous motion beside a text task cost the most corrections (Maglio & Campbell 2000); travel
  is the most distracting motion type and ~1 Hz cues less than ~2 Hz (Bartram et al. 2003); "the slow fade appears to
  be the best secondary display animation type tested" (McCrickard et al. 2003). The user has overridden this for
  Rain (A1, pass 19b); a mindful theme can be the place where it is honoured again.
- **No "safe speed" exists in the literature found** [E]: motion is detectable at about 1–2 arcmin/s in central vision
  with a stationary reference (Leibowitz, as cited in [a 2025 review](https://www.mdpi.com/2411-5134/10/3/33));
  peripheral thresholds scale with the coarser resolution there ([McKee & Nakayama 1984](https://doi.org/10.1016/0042-6989(84)90140-8)).
  On the 14-inch screen 1 pt/s is 1.4 arcmin/s [M]: drift at 1–2 pt/s reads as almost still; rings at 36 pt/s
  (0.83°/s) are plainly motion.
- **Restoration** [E]: Attention Restoration Theory's "soft fascination" (water, foliage, clouds) has modest support:
  of 13 meta-analyses of attention measures, 3 favoured nature exposure ([Ohly et al. 2016](https://doi.org/10.1080/10937404.2016.1196155));
  40 s looking at a meadow roof *between* blocks of a sustained-attention task cut omission errors against a concrete
  roof (N = 150, [Lee et al. 2015](https://www.ltl.org.uk/wp-content/uploads/2019/02/40-second-green-roof-views-sustain-attention.pdf)).
  Both are breaks, not motion beside the task [I]: the scene's place is the pause and the glance away, and it should be
  quieter while keys come.
- **Calm technology** [E]: the periphery calms when it *informs* (Weiser & Brown; `visuals.md` §2.3). Rings that come
  from the writer's own words carry a trace of activity; a bed that ignores the keys is pure mood [I].
- **Oscillation** [P]: visionOS: "avoid showing an oscillation that has a frequency of around 0.2 Hz" and keep the
  amplitude low (`visuals.md` §4.3), about moving objects in an immersive field; a sway or a breath of 5 s is exactly
  that period.

### 3.2 Rings on still water: what makes them look right

- **Physics** [E]: on water the slowest ripples travel at 0.23 m/s (λ 1.7 cm); a drop's waves "propagate outside an
  expanding circle of fluid at rest" ([Wikipedia, capillary wave](https://en.wikipedia.org/wiki/Capillary_wave)): a few
  crests move out and the centre goes still behind them. In two dimensions a ring's energy spreads over its
  circumference, so its amplitude falls about as 1/√r, and viscosity damps it in time [I, standard wave physics].
  Waves pass through each other and add where they cross (linear superposition).
- **Craft** [P]: games fake rain ripples with a precomputed ring texture animated per circle by a time offset, so rings
  never start in step; a ring rises and falls through a clamped sine envelope and fades linearly; four layers at
  `TimeMul = (1.0, 0.85, 0.93, 1.13)` let density follow rain intensity; ripples need not be synced to the drops'
  impacts, as the eye cannot tell in rain; the weakness the author names is perfect circles (Lagarde, [Water drop 2b](https://seblagarde.wordpress.com/2013/01/03/water-drop-2b-dynamic-rain-and-its-effects/)).
  The classic height-field ripple (two buffers; each cell the sum of its four neighbours halved, minus its value two
  steps back, times a damping such as 0.99) gives true interference at a cost per pixel per frame ([a port of the
  algorithm](https://learn.microsoft.com/de-de/archive/blogs/nikola/building-the-reallistic-water-ripples-sample-in-silverlight)).
- **Cheap 2D approximation for Lemna** [I]: per drop 2–3 crests drawn as soft rings (a Gaussian across the stroke, as
  `architecture.md` §5's `ring` shape), each with a fainter trough ring 3 pt inside it to suggest the slope; amplitude
  ramping from 0 over 150–200 ms (a real drop starts at its peak, but an abrupt onset is the capture class to avoid),
  then `a(t, r) = peak · e^(−t/τ) · √(r₀/r)`; radii and starts jittered a little so no two drops look stamped; rings
  that cross add. Refraction of what lies under the water is impossible (Lemna cannot see the app behind) and not
  needed: the trough-and-crest pair reads as slope.

### 3.3 Other candidates

| Candidate | Evidence and risk | Verdict |
|---|---|---|
| **Ripples** | discrete, self-caused when fed by words; looming-like expansion, so keep onsets soft and rings small (≤160 pt ≈ 3.7°) | **yes**, the theme's scene |
| **Duckweed fronds** (a few floating, nudged by passing rings) | near-still drift (≤1.5 pt/s ≈ 2 arcmin/s); the habitat made literal; figurative, so kitsch if many or bright | yes, as part of Ripples, few and faint |
| **Mist** (slow drifting fog) | gradual change, mostly unseen when slow; a full-screen fragment pass runs every frame (power at rest, `architecture.md` §5); bands on dark | maybe, light variant only, or with dither |
| **Wind-chime sway** (rods hanging from the top edge) | continuous oscillation near the 0.2 Hz the HIG warns about; figurative; the chime *sound* is a changing-state sound K1 ruled out (`architecture.md` Q3) | later, if the chime bed is built; periods 7–11 s, ±1.5° |
| **Breathing glow** | a pacer competes with writing; adherence fell to 27.5 % under a hard task; invisible when below threshold (`visuals.md` §2.4) | no; if wanted, its own mode, never on the box |
| **Drifting or falling leaves** | travel, the most distracting motion type, crossing the field | no |
| **Rain streaks** | Rain (M2) exists; a falling streak is travel | no for this theme |

### 3.4 How typing could feed them

| Coupling | Onset rate while typing | Fit | Verdict |
|---|---|---|---|
| a drop per key | 3–8 Hz at the periphery, never decaying between keys | the onset train F0 rejected for the box | no |
| **a drop per word** (Space, Return) | about 0.7–0.9 Hz at 40–55 wpm [M] | discrete (Maglio's third guideline), near Bartram's ~1 Hz, and informative (calm technology) | **yes** |
| a bed that ignores the keys | none | pure mood; the restoration evidence is for pauses | yes for the rest state |
| the inverse: water stills while you write, drops return in pauses | none while typing | least motion during the task; but a scene that rises in pauses marks the pause (Dux Speltz 2021's pressure, F0's (g)) unless its return is slow (τ ≥ 3 s) | a try, not the default |

Recommended mix [I]: rare drops at rest (a bed), a drop per word while writing, nothing per key, and no "more intense
when writing": the reverse of Rain's pass 19b on purpose, so the two themes feel different in kind.

### 3.5 Sound and picture

- Calm bundles picture and bed in one "Scene"; OmmWriter keeps them apart (§1.1, §1.3) [P].
- Sparse visible drops with audible drops invite sync; dense rain does not (Lagarde, §3.2). Lemna's beds and scenes
  run on different threads, and linking them is new work (`architecture.md` §5) [I]. So: a light-rain bed is a steady
  texture with no visible counterpart, rings are the words; if single drop sounds are ever played, they should come
  from the same events as the rings.

## 4. How other apps model a theme

| App | A theme holds | Outside the theme | Light/dark | On a switch |
|---|---|---|---|---|
| iA Writer | Light or Dark only; "Templates" style preview and export | typeface (Mono/Duo/Quattro), size, line width | "Match system appearance" | nothing to lose |
| Bear 2 | palette per part of the window; its JSON also names an editor font, size and line height (`BearSansUI-Regular`, 15, 1.5) [P, read] | the Typography settings | light and dark themes | font settings separate (whether they override the theme's: UNVERIFIED) |
| Ulysses | palette, markup colours, light and dark modes in one theme | font and layout | Match System / Light / Dark | fonts kept |
| Obsidian | community CSS | Appearance fonts beat the theme's; snippets on top | follows the OS by default | settings survive (they are not in the theme) |
| VS Code | colours (colour theme), separately file icons and product icons | fonts | preferred dark and light themes with `window.autoDetectColorScheme` | `workbench.colorCustomizations` global, or per theme with `"[Theme]": {}` |
| Ghostty | any config option ("can set any valid configuration option") | — | `theme = light:X,dark:Y` | explicit colours in the config override the theme's |
| kitty | a `.conf` of settings | — | `light-theme.auto.conf`, `dark-theme.auto.conf` | the kitten comments out the user's old colour lines |
| iTerm2 / Apple Terminal | colour presets (colours only) / a profile: fonts, colours, background, cursor, bell, behaviour | — | per profile, separate light and dark colours (iTerm2) | presets copied into the profile (UNVERIFIED) |
| OmmWriter | nothing bundled: background, music, key sound, font chosen apart | — | — | — |
| Calm | a Scene: picture and sound together | volume | — | — |

Sources: [iA settings](https://ia.net/writer/support/basics/settings), [iA templates](https://ia.net/writer/support/preview/templates),
[Bear themes](https://blog.bear.app/2018/10/write-your-way-with-beautiful-themes-and-bear-pro/), [Ulysses editor themes](https://help.ulysses.app/styles-themes/editor-themes),
[Ulysses customisation](https://help.ulysses.app/mac-customization-guide), [Obsidian themes](https://obsidian.md/help/themes),
[Obsidian appearance](https://obsidian.md/help/appearance), [Obsidian forum on precedence](https://forum.obsidian.md/t/css-style-precedence/108933),
[VS Code themes](https://code.visualstudio.com/docs/configure/themes), [Ghostty config](https://ghostty.org/docs/config/reference),
[kitty themes](https://sw.kovidgoyal.net/kitty/kittens/themes/), [Alacritty imports](https://alacritty.org/config-alacritty.html),
[iTerm2 colours](https://iterm2.com/documentation-preferences-profiles-colors.html), [Terminal profiles](https://support.apple.com/guide/terminal/use-profiles-to-change-the-look-of-terminal-windows-trml107/mac),
[Typora custom CSS](https://support.typora.io/Add-Custom-CSS/), OmmWriter and Calm as in §1 [P].

What follows [I]:
1. Three models: a bundle of everything (Terminal profiles, Ghostty, kitty, Typora's CSS); colours only beside
   independent axes (the writing apps, VS Code, iTerm2); a preset with overrides in a higher layer (Obsidian, Typora's
   `*.user.css`, VS Code's customisations, Ghostty).
2. Fonts sit outside the theme in every writing app checked; Lemna has no font setting at all, so its theme is where
   the face is chosen (as in Terminal's profiles).
3. Sound is bundled with a look nowhere among these except Calm's scenes; a theme that "really changes" the app with
   sound (the user's ask) goes past the norm, which is fine when the axes stay settable by hand.
4. Following the system appearance is standard; a light theme should carry its dark variant.
5. Overrides usually survive because they live in another layer; resets are the bundle tools' habit (kitty). No
   complaint about either was found. This supports `architecture.md`'s A, the preset that writes the pack, the bed and
   the ambience, keeps the menus showing what holds and leaves the Effects ticks and ⌘K alone; per-theme memory (B)
   has VS Code as its precedent if lost tweaks are ever reported.

## 5. Recommendations for Lemna

### 5.1 Still (recommended): one theme, a day and a night variant

The name is a placeholder for the user ("still" water, where duckweed floats); today's look stays as it is, as
`architecture.md`'s `lemna` theme. The variant follows `NSApp.effectiveAppearance` (light → day, dark → night); a
manual override is not needed until asked [I].

| Role | Day | Night | Why |
|---|---|---|---|
| Box surface | #F3F0E8 (L 0.87) | #1C1B18 (L 0.011) | a warm paper a little greyer than Solarized's or Everforest's, to temper a large pale area; a warm near-black as the calm dark themes use, not #0e1013's blue-black (§1.2) |
| Text | #46433D, 8.7:1 | #E2DACA, 12.4:1 | AAA with margin and softer than 13.9:1 at no reading cost (Legge 1987); warm off-white on dark (Fan 2024) |
| Muted | #86817A, 3.4:1 (Increase Contrast #6B675F, 4.9:1) | #8C8476, 4.7:1 (IC #A69D8E, 6.4:1) | large-text AA; the night muted meets 4.5:1 even without IC, which T2's #5c646f does not |
| V2 fade | toward the surface, as today | as today | — |
| Caret and accent | duckweed green #577446, 4.6:1 (IC #465E38, 6.3:1) | sage #A2B88E, 8.0:1 | one accent, Lemna's own green; ≥4.5:1 for the fixation mark |
| Edge | no border; hairline #D9D4C8 (1.30:1) | hairline #34312C (1.33:1) | the box must be found on a pale wash over a light app (1.15×); no accent border (§2.4) |
| Shadow | none until the hand-off's shadow drop is fixed (`architecture.md` §7), then soft | none (unseen on dark) | |
| Corners | 16 pt, `cornerCurve = .continuous` | same | curvature preference (Bar & Neta 2006); rounder than 10 pt, still a card |
| Dim | #D3D8CE (pale sage) at α 0.74 | #0F1412 at α 0.62 | day: box ≥ surround over any app (1.15–2.34, EN 12464-1); night: less glare than 0.5 over a light app |
| Font | Literata, opsz = size, regular, 30 pt | same | an e-book face made for screens, OFL, 0.96 MB (a static 400 instance is smaller); 30 pt keeps Menlo 28's x-height (15.1 vs 15.3 pt); box 4 em = 120 pt. Zero-byte fallback: Charter 31 pt. Rounded alternative: SF Pro Rounded 30 pt |
| Caret shape | 2 × 36 pt bar (1.2 em), 1 pt rounded ends, steady | same | §2.6 |
| Glide | 140 ms, easeOutQuint (unchanged) | same | §2.7 |
| Glyph fade | 80 ms (140 ms to try) | same | |
| Open / close | 300 ms fade, no scale / 200 ms fade | same | fades instead of zoom (HIG Reduce Motion practice; Bartram) |
| Hand-off | glyphs fade in place 200 ms; one ring (two crests) from the box's outline over the wash, gone by 1.2 s; or H1 unchanged | same | §2.7 |
| Paragraph ` ¶ ` | 200 ms fade (unchanged) | same | |
| Ambience ink | #3F4A3C, blended "over" (not added), alphas about 0.6 of pass 16's | #C9D3C4, added, alphas about 0.5 of pass 16's | additive light is invisible on a pale wash (`architecture.md` §7); on near-black a ring of α 0.1 is +300 % luminance, so night needs less [M] |
| Preset for the other axes | Ambience ▸ Ripples; Sound ▸ the Soft pack (or a mindful pack when one exists); a light-rain bed if built | same | `architecture.md` A |
| Menu-bar mark, app icon | unchanged | unchanged | §2.8 |

### 5.2 Two alternatives

- **Paper** (the day column, always): one look, no appearance logic. Cost: at every summon over a dark app, the pale wash
  brightens the screen about 7× (§2.1), at night too; macOS users in dark appearance mostly run dark apps [I].
- **Dusk** (the night column, always): nearest to today's behaviour and the cheapest, since none of `architecture.md`
  §7's light-only work is needed (additive ambience, the shadow drop and `.darkAqua` all hold). Cost: the box stays
  darker than its surround over light apps (0.30), the inversion `visuals.md` §6.2 raised, and positive polarity's small
  advantage goes.
- **Mist** (a dim option for either, not a theme): `NSVisualEffectView`, `.behindWindow`, `.fullScreenUI`, under a tint
  #DCE2DF at α 0.45 (day). The most "frosted" and minimal; costs: the app behind becomes unreadable, the GPU cost over
  every screen is unmeasured, Reduce Transparency turns it solid, the radius is not settable (§2.5).

### 5.3 Ambient animations, the shortlist with parameters

All: on the dim only, never on the box; Ambience ▸ Off and Reduce Motion stop them (A1's rule); 30 Hz is enough for
these speeds (36 pt/s is 1.2 pt a frame); every alpha below is a starting value to be judged by eye on a light and a
dark app, like pass 16's.

**1. Ripples** (recommended):

| Parameter | Value | Why |
|---|---|---|
| Drops at rest | Poisson, 0.12 per second per screen (mean 8 s apart), anywhere on the dim at least 48 pt from the box | a bed, sparse enough to be glanced at rather than watched |
| Drops while writing | one per word (Space, Return), where the word's last letter key lies (pass 16's keyboard map, `Stage.screenX`), at least 0.8 s apart; none per key; the rest rate unchanged | ≈0.7–0.9 Hz, discrete, informative (§3.4) |
| Crests per drop | 3, 9 pt apart, the outer leading; a trough ring 3 pt inside each at 0.4 of its alpha | slope without refraction (§3.2) |
| Speed | 36 pt/s (0.83°/s at 50 cm); the still centre follows at 0.7 of it | real ripples' leading crests and calm centre |
| Onset | alpha 0 → peak over 180 ms, easeOutQuint | no abrupt onset |
| Peak alpha | day 0.16 ("over", ink #3F4A3C); night 0.07 (added, #C9D3C4) | about −16 to −20 % luminance on the day wash [M]; night lower for the dark base |
| Decay | `peak · e^(−t/1.4 s) · √(12 pt / r)`; gone below α 0.01 or at 4.5 s (r ≈ 160 pt, 3.7°) | 2D spreading and damping |
| Crossing | rings add | reads as interference |
| Jitter | radius spacing ±15 %, ring width 1.2–2 pt, start ±40 ms per crest | "perfect circles" was the game's weakness |
| Cap | 24 drops alive (≈150 sprites with troughs) | far under the 2,000 cap |
| Fronds (optional) | 3–7 clusters of 1–3 ovals, 7 × 5 pt, #6F8F5A at α 0.35 (day) / #7E9A6B at 0.25 (night); drift ≤ 1.5 pt/s, turn ≤ 2°/s; a passing crest pushes one 1.5 pt outwards, a spring returns it over 1.2 s; never over the box | the habitat; near-still (§3.1) |
| Hand-off ring (if taken, §2.7) | two crests from the box's outline, 60 pt/s, peak 0.18 / 0.08, gone by 1.2 s | the one bold moment, in water |

**2. Mist** (maybe; day variant first): two octaves of smooth noise at 600 and 260 pt scale drifting at +3 and −2
pt/s, modulating the wash by ±4 % luminance by day (≈ ±4 code values at 220, smooth) and ±1.5 % by night with ±0.5 LSB
dither; no response to keys; drawn at 15 Hz as one full-screen pass, so its power at rest should be measured before it
ships (A1's `powermetrics` line).

**3. Chime sway** (later, only with a chime bed): 5 rods from the top edge in the middle 40 % of the width, 60–140 pt
long and 3 pt wide, ink at α 0.18 (day); damped pendulums with periods 7–11 s (0.09–0.14 Hz, away from 0.2 Hz),
±1.5°; an impulse per Return only, and a brief brightening when a chime sounds if the strikes are Lemna's own events.

**Not for this theme:** a breathing glow (a pacer beside a task, §3.3), falling leaves (travel), drops per key (the
onset train), Rain's "more intense when writing".

## 6. Points for the user

1. Light-first with a night variant (Still), light only (Paper), or dark only (Dusk) (§5.1–5.2).
2. The face: Literata (bundled, a book), Charter (installed, a book, 0 bytes) or SF Pro Rounded (installed, soft,
   0 bytes) (§2.3).
3. The hand-off: H1 as it is, or the fade with one ring (§2.7).
4. Mist as a dim option at all, given that it hides the app being written into (§2.5).
5. Ripples' coupling: a drop per word with a sparse bed (recommended), a bed only, or the inverse (§3.4).

## 7. Not verified

iA Writer's, Calmly Writer's, Ulysses' and Apple Books' own colour values; Calm's and Headspace's palettes and motion
timings; Apple Breathe's easing; whether Bear's typography settings override a theme's font; how macOS composites a
translucent window (sRGB-encoded or linear: the dim values above assume encoded); the GPU cost of a full-screen
behind-window blur and of a Mist pass; Leibowitz's motion threshold read from a secondary review, not the 1955 paper;
the font sizes of static instances; how Literata, Charter and SF Pro Rounded look on the line at 30 pt (to be judged
in the box, by eye, against Menlo 28); every alpha in §5.3.
