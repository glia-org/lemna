# The Matrix's digital rain, in numbers, for Lemna's Rain (as of 2026-10-30)

Question: what does the "digital rain" of *The Matrix* (1999 titles and monitors, the 2003 sequels' titles, the 2021
*Resurrections* code) actually do, in numbers precise enough that Lemna's Rain (M2) can imitate its motion in Lemna's own
palette (text #d8dce3, accent #7aa7f0, no green) and with Lemna's glyph atlas (ASCII 33–126, Latin-1)? The ask behind it:
"even more like the matrix rain animations ... ambient in the background (low key, but still covering more or less the
whole screen) and then it should simply get more intense when writing".

Read first: `app/Sources/LemnaCore/Scenes.swift` (`struct Rain`) and the Rain block of `Ambience.Tuning` in
`app/Sources/LemnaCore/Ambience.swift`; DESIGN A1 (M2, C1, R1).

Tags as in `research_notes/Lemna rain/sendoff.md`: **[P]** practice: an interview, a maker's statement, a fan
implementation's code or docs; **[M]** my measurement or computation from source code (method in §7); **[I]** inference.
**UNVERIFIED** marks what I could not check. Nobody has published a frame-by-frame measurement of the film footage that
I could find; every number for "the film" below is either a maker's statement or the tuning of a recreation that was
matched to the footage by eye. Nothing here was watched frame by frame.

## Takeaway

1. **The glyphs do not fall. The light does.** In the film and in the most faithful recreation, each glyph sits fixed in
   a grid cell; a "raindrop" is a wave of brightness that runs down a column and lights the glyphs it passes, which then
   dim in place. Animal Logic made "certain characters ... appear to repeat or 'stick' in the same place" (befores &
   afters, 2019) [P]; Rezmason: "The 2D glyphs are in a *fixed grid* and *don't move*" [P]. Lemna's Rain draws each trail
   glyph at a fixed offset above its head, so the whole string slides down: the one difference that most gives it away.
2. **Heads step a cell at a time and are the palest, brightest cell; the trail is coloured and fades linearly.** jwz:
   the screens "definitely scrolled a character at a time, not a pixel at a time" [P]. Rezmason's head ("cursor") is a
   separate, near-white colour drawn at 2× intensity over a trail whose brightness falls linearly from 0.6 to 0 [M].
   In Lemna's palette that is a head in the text colour and a trail in the accent: the reverse of C1's mapping today.
3. **Speeds differ per column, about 2:1, and are constant within a column.** Rezmason classic (his "2003"): 15–30 rows/s
   (100 × fallSpeed 0.3 × a per-column factor of 0.5–1); his "1999" (operator): 30–60 rows/s [M]. Drops in one column
   share its speed, so they "can never collide" [P]. Lemna's 150–300 pt/s at its 37 pt rows is 4–8 rows/s.
4. **Trails are long and vary a lot.** Rezmason classic: 55 % of each column is lit at any time, trails of 23 / 35 / 90
   rows (5th / 50th / 95th percentile) on a screen about 50 rows tall; operator: median 71 rows, longer than the screen;
   Resurrections: 26 rows and 40 % lit [M]. Terminal recreations draw lengths uniformly from 3 or 10 % of the height to
   the full height [P]. Lemna's trail is 4–8 glyphs.
5. **Every glyph keeps changing in place.** Rezmason classic changes each cell about 1.8 times a second (cycleSpeed 0.03
   a frame at 60 fps, random phase per cell) [M]; neo changes 10 % of the cells every 300–400 ms with a flicker; tte has
   a 0.005 chance per glyph per frame (0.3/s at 60 fps, 0.6/s in Omarchy's 120 Hz screensaver) [P]. The sequels' titles
   cycle each cell through one fixed order of 57 glyphs (Rezmason's `glyph order.txt`) [P]. Lemna's 1.5/s is in range.
6. **The glyphs are mirrored left to right, not upside down.** Whiteley: "I turned all of the numbers and the graphics
   back to front"; Wikipedia: "mirror images of half-width kana characters and Western Latin letters and numerals" [P].
   The set is mostly katakana plus digits (no 6 in Rezmason's 1999–2003 font), z, and `: . " = * + < > |` [P].
7. **The film is soft.** "Pixel effects and blurs and glows" (Justen Marshall, Animal Logic); "low resolution and somewhat
   blurry/washed out" (jwz); Rezmason blooms the glyphs and then tone-maps them (bloom strength 0.7) [P].
8. **The whole screen is covered in the films' idle look; "intense" is an artefact of the recreations.** Rezmason classic
   lights every column; xmatrix fills 75 %, glmatrix 20 %, neo about one drop per column per screen transit [P]. The
   cleanest precedent for a two-state rain is Rezmason's Playdate port: the rain's clock runs at 0.15× with the crank out
   and ramps to 1× by 0.07 a frame when it is docked [P].
9. **For Lemna (§6):** a fixed grid of 14 pt glyphs at an 18.5 pt square pitch (81 × 53 on a 1512 × 982 pt screen,
   Rezmason's 80 × 50), drops as brightness waves; idle 30 % of columns, 5–10 rows/s, trails 6–18 rows, head α 0.35;
   typing ramps one intensity I to 70 % of columns, 15–30 rows/s, trails 10–30, head α 0.85, mutation 0.3 → 1.5/s;
   attack τ 0.25 s, release τ 1.2 s; 30 Hz idle, 60 Hz typing. About 290 sprites idle and 1,300 while typing (cap 2,000).
10. **Tension with DESIGN.** An idle rain reverses A1's "typing feeds and silence starves" and its 4 s end with the
   display link paused, and puts continuous travelling motion beside the text, the kind F0 cites as most distracting
   (Bartram 2003). It is the user's ask; it needs a line in DESIGN A1 and a power measurement (§5).

## 1. Glyph set and rendering in the film

### 1.1 Design and origin

- **Designer:** Simon Whiteley, production designer at Animal Logic, drew the glyphs; Justen Marshall (then technical
  lead) wrote the mental ray shader that streamed them (befores & afters, Ian Failes, 2019-03-27,
  https://beforesandafters.com/2019/03/27/secrets-of-the-matrix-code/) [P]. Animation in Softimage, rendered in mental
  ray; the code was generated early so it could play on the set's monitors [P].
- **First concept:** "a three-dimensional type that clicked over as it tumbled", running across the screen; turned
  vertical after the top-to-bottom, right-to-left layout of the Japanese cookbooks (same source) [P].
- **Source of the shapes:** katakana chosen over hiragana and kanji for "these very nice simple strokes"; hand-drawn from
  his wife's Japanese cookbooks and cooking magazines and from children's alphabet sheets, scanned; Arabic numerals mixed
  in; scanning clipped tops and bottoms, and he added strokes, dots and icons (befores & afters) [P]. "I like to tell
  everybody that The Matrix's code is made out of Japanese sushi recipes"; "It's not actually a book ... It's a
  magazine" (CNET 2017, quoted by HuffPost UK via Yahoo, 2024-06-21,
  https://au.news.yahoo.com/just-learned-code-matrix-m-132426303.html; SoraNews24, 2017-10-25,
  https://soranews24.com/2017/10/25/secret-of-the-matrix-code-finally-revealed/) [P]. The CNET original
  (https://www.cnet.com/news/lego-ninjago-movie-simon-whiteley-matrix-code-creator/) did not load: UNVERIFIED first-hand.
  Readers have found no readable recipe in the code; the sushi line is a joke he tells (Wikipedia, tagged citation
  needed) [P].
- **Mirroring:** "I turned all of the numbers and the graphics back to front" (Whiteley, befores & afters), so the code
  reads as seen from inside [P]. Wikipedia (https://en.wikipedia.org/wiki/Matrix_digital_rain): "a custom typeface
  designed by Simon Whiteley, which includes mirror images of half-width kana characters and Western Latin letters and
  numerals"; no official version of the typeface was ever released [P]. Left-right mirroring, not vertical: nothing in the
  sources flips glyphs upside down.
- **Colour:** "matched the look of text on an old IBM CRT monitor" (befores & afters) [P].
- **The window:** "It looks like rain running down a window as if you're looking out onto a cold, bleak world"
  (Whiteley) [P].

### 1.2 The glyphs as recovered

- Rezmason (https://github.com/Rezmason/matrix, read at 5ba9049, 2024-10-31) took the trilogy's glyphs from vectors in a
  2007 promotional SWF for an official Matrix game: "some treatment of katakana, but they also include a few characters
  from Susan Kare's Chicago typeface" [P]. His `matrixcode` set cycles 57 glyphs; the font he ships
  (`assets/Matrix-Code.ttf`) maps 60 code points: `" * + 0 1 2 3 4 5 7 8 9 : < > z | ¦ © ╌ ▪ ー ꞊` and 33 katakana
  (ア ウ エ オ カ キ ケ コ サ シ ス セ ソ タ ツ テ ナ ニ ヌ ネ ハ ヒ ホ マ ミ ム メ モ ヤ ヨ ラ リ ワ) [M]. No 6.
- *Resurrections* (2021) widened the set to 135 glyphs, which Rezmason recovered from trailers, a watch ad and BUF's
  making-of frames [P]. BUF Paris did 72 shots on the film (https://buf.com/films/the-matrix-resurrections), with no
  detail on the code [P]; the on-screen-graphics studio was told "the only element that was entirely off limits was the
  green-hued code" (Creative Review, https://www.creativereview.co.uk/the-matrix-resurrections-on-screen-graphics/) [P].
- tte's default `rain_symbols` (50): `2 5 9 8 Z * ) : . " = + - ¦ | _` plus 34 half-width katakana [P].
- **The ASCII overlap** of the film's set and tte's (what Lemna's atlas can draw): `0 1 2 3 4 5 7 8 9 Z z : . " = * + -
  < > | _` [I].

### 1.3 Head, trail, gradient, mutation, glow

- **Head:** the brightest and palest cell of a drop. Rezmason draws it in its own channel ("isolateCursor"): colour
  hsl(0.242, 1, 0.73) × `cursorIntensity` 2 added over the palette, which at the head's brightness 0.6 gives about
  rgb(0.91, 1.0, 0.55) before bloom, against the trail's top colour of about rgb(0.38, 0.96, 0.24) (palette hsl(0.3,
  0.9, L) at L 0.6) [M]. Others: tte head `#dbffdb`, trail a random pick of a 6-step gradient `#92be92` → `#185318`;
  cmatrix and neo a white bold head; unimatrix white on one drop in three; Ametrix example head `#d9ffd9`, tail
  `#00ff41` [P]. So "paler", not only "brighter".
- **Gradient along the trail:** Rezmason classic is linear. A cell's brightness is the falling edge of a sawtooth,
  `b = 1 − fract(w(x))`, shown as `1.1 b − 0.5` (baseContrast 1.1, baseBrightness −0.5) through a palette whose lightness
  follows brightness (0 → 0, 0.2 → 0.2, 0.7 → 0.7, 0.8 → 0.8), so the trail runs linearly from 0.6 just above the head
  to 0 at its top, then dark until the next head [M]. The 1999 look (Rezmason's operator) is flat: every lit glyph at one
  level (`brightnessOverride` 0.22) under a much brighter head (`cursorIntensity` 3): "flatter, crowded, without a
  gradient" [P]. glmatrix: brightness waves with a 22-cell period running down each strip [P]. neo: random shade per cell
  by default, a gradient from the head optional [P].
- **Persistence:** a cell lit by a passing head stays lit and dims in place. In Rezmason the time from head to dark is
  trail rows ÷ speed: about 35 ÷ (15–30) = 1.2–2.3 s for a median trail [M]. In cmatrix, tte, neo and unimatrix a glyph
  is written by the head and stays at its colour until the tail erases it; neo lets a drop that stopped early linger
  1–3,000 ms (`--lingerms`) [P]. Marshall on the original: "it would have two different characters at different levels
  of brightness" in one cell, and some characters held in place, "that persistence of vision, optical illusion kind of
  thing" [P].
- **Mutation:** Rezmason classic adds `cycleSpeed` 0.03 to each cell's age per frame and swaps its glyph at 1, so every
  cell, lit or dark, changes every 33 frames (0.56 s at 60 fps, 1.8/s) with a random phase; operator 0.01 a frame in steps
  of 8 frames (`cycleFrameSkip`): a change every 100 frames, 1.7 s; the Playdate port 2/s [M]. The sequels' titles step
  each cell through one fixed order, `モエヤキオカ7ケサスz152ヨタワ4ネヌナ98ヒ0ホア3ウ セ¦:"꞊ミラリ╌ツテニハソ▪—<>0|+*コシマムメ`
  (Rezmason's `glyph order.txt`; "no longer drives the glyph cycle in this project") [P]. neo: 10 % of cells glitch,
  all at once every 300–400 ms, bright for the first quarter of the interval and dim for the last [P]. tte: 0.005 a glyph
  a frame. cmatrix `-k`: one in 8 per step. xmatrix: 5 "spinners" (cells that change all the time). glmatrix: one glyph in
  20 spins, every 1–3 frames, and one spinner in 800 stops per spin [P].
- **Glow:** Marshall built the final look with "pixel effects and blurs and glows" [P]. Rezmason: "Matrix symbols aren't
  just some shade of phosphorous green; they're first given a bloom effect, and then get tone-mapped to the green color
  palette" (bloomStrength 0.7, bloomSize 0.4, highPassThreshold 0.1) [P]. jwz on the monitors: "low resolution and
  somewhat blurry/washed out" [P].

### 1.4 The three eras, as Rezmason tunes them

Rezmason aliases `1999` to operator, `2003` to classic and `2021` to resurrections (`js/config.js`). Classic is "mostly
based on the sequels' opening title graphics"; operator "is more reminiscent of the matrix code as it appears in the
first movie's opening titles, and on operators' screens" [P]. *Reloaded* took the rain into depth, "sliding down multiple
virtual sheets of glass" (Pushing Pixels, 2017-03-29,
https://www.pushing-pixels.org/2017/03/29/how-deep-the-rabbit-hole-goes.html) [P].

| | 1999 (operator) | 2003 (classic, default) | 2021 (resurrections) |
|---|---|---|---|
| Columns across | 108 | 80 | 70 |
| Cell (height : width) | 1.35 | 1 | 1 |
| Rows visible on 16:10 [M] | ≈ 50 | ≈ 50 | ≈ 44 |
| Head speed, rows/s [M] | 30–60 | 15–30 | 15–30 |
| Brightness along a trail | flat 0.22 | linear 0.6 → 0 | linear 0.47 → 0, top 8 % of the palette to white |
| Trail rows p5 / p50 / p95 [M] | 46 / 71 / 179 | 23 / 35 / 90 | 17 / 26 / 67 |
| Share of cells lit [M] | 0.55 | 0.55 | 0.40 |
| Head intensity | 3 | 2 | 2 |
| Glyph change | every 1.7 s, 8-frame steps | every 0.56 s | every 0.56 s |
| Bloom strength / size | 0.75 / 0.6 | 0.7 / 0.4 | 0.7 / 0.4 |
| Extra | occasional square ripple | | "glint" highlights on glyph strokes, 135 glyphs |

Rezmason's `3d` version (volumetric, raindropLength 0.3, fallSpeed 0.5) has trails of 7 / 10 / 27 rows [M].

## 2. Column dynamics

- **Columns across a frame:** 80 (2003), 108 (1999), 70 (2021) in Rezmason; the grid is `numColumns` square and fills the
  width, so a 16:10 screen shows 80 ÷ 1.6 = 50 rows (`rainPass.vert.glsl`: `pos.xy *= screenSize`) [M]. cmatrix and
  unimatrix use every other terminal column [P].
- **Active at once:** in Rezmason every column carries rain; at any moment 55 % of all cells are lit (classic) [M].
  xmatrix's default `density` is 75 % of the screen, glmatrix's 20 % [P]. neo spawns `columns × density ÷ (rows ÷
  chars/s)` drops a second, about one per column per screen transit at density 1, at most 3 per column [P].
- **Speeds:** per column, constant. Rezmason: rows/s = 100 × fallSpeed × animationSpeed × u, u uniform in 0.5–1 per
  column, from `getRainBrightness` (phase advances 0.01 per row, fallSpeed × u per second) [M]; the wobble term changes the
  spacing and shape of drops, not their speed [M]. Other recreations: tte one row every 3–16 frames (`rain_fall_delay_range`
  2–15), so 3.75–20 rows/s at its default 60 fps and 7.5–40 rows/s at Omarchy's 120 [M]; cmatrix 25 rows/s for every
  column (a step per 40 ms frame at `-u 4`), `-a` makes it 6.25, 12.5 or 18.75 [M]; unimatrix 6.7 rows/s at its default
  speed 85 (a 150 ms step), `-a` divides by 1–3 [M]; neo at most 8 chars/s, `-a` 1/3–1 of that per column [P]; glmatrix
  a bell-shaped 0–0.3 cells a frame at 33 Hz, mean ≈ 5 cells/s [M]; xmatrix re-rolls each feeder's wait (0–8 ticks)
  with a 10 % chance per step, so its drops change speed on the way [M]; Ametrix example `speed` 18–38 (unit unstated) [P].
- **Collisions:** "Multiple raindrops often occupy a column at the same time, and they may have different speeds, but they
  can never collide" (Rezmason: speed per column, drop spacing per sawtooth tooth) [P].
- **Trail lengths:** Rezmason as in §1.4. tte: uniform from 10 % of the column's height to all of it; cmatrix: 3 to
  rows − 1, with a gap of 1 to rows before the next; neo: half the drops run from the top to their end line, the other half
  are 1 to rows − 2 long, and a third stop before the bottom (`--rippct` 33); xmatrix: 3 + 0…height glyphs, and three
  times in four a gap instead; Ametrix example 14–48, capped at 0.75 of the rows [P].
- **Drops per column:** Rezmason one sawtooth tooth per drop, period 100 × raindropLength rows (75 for classic, so 0.67
  heads per column on a 50-row screen at any moment) [M]; neo up to 3 [P]; cmatrix and tte one at a time [P].
- **Where drops start:** at the top edge in Rezmason, tte, cmatrix and neo [P]. Rezmason's optional intro starts from a
  blank screen: the middle column at 1 s, the column at three quarters at 2 s, the rest between 2.5 and 8.5 s, the edges
  last [M]. xmatrix's "bottom" feeders start at a random row in the top half of the screen [P].
- **Stepping:** the head moves a whole cell at a time. Rezmason computes brightness per cell, so the head jumps cell by
  cell while each cell's brightness fades smoothly frame by frame [M]. jwz: "definitely scrolled a character at a time,
  not a pixel at a time" [P]. The films run at 24 frames a second.
- **Ends:** a drop runs off the bottom (Rezmason, cmatrix) or stops at an end line and its tail runs on (neo, tte); tte
  holds a full-height column 20–45 frames before trimming it, then with an 8 % chance a step slides what is left down
  one row [P].

## 3. Density: idle and intense, and how the recreations tune it

- The films have no idle state: the code fills the frame from the first moment (classic: all columns, 55 % of cells lit).
  What a low-key version keeps is the grid, the per-column speeds, the stepped heads, the pale head over a coloured
  linear trail and the mutation; what it can drop is the share of columns and the brightness [I].
- **Knobs for intensity, by implementation:**
  - Rezmason: `animationSpeed` (one clock for falling, cycling and fading), `fallSpeed`, `cycleSpeed`, `raindropLength`
    ("Adjusts the frequency of raindrops (and their length) in a column"), `numColumns`, `bloomStrength`, `baseBrightness`
    and `baseContrast` (which share of the sawtooth shows), `cursorIntensity`, `brightnessDecay` (1 = no smoothing;
    nightmare 0.75, paradise 0.05), `fps` 0–60 [P]. Slow versions: paradise `fallSpeed` 0.02 (1–2 rows/s), twilight
    0.1 (5–10 rows/s), megacity `animationSpeed` 0.5 [M].
  - Rezmason's Playdate port (`playdate/matrix_c/main.c`, the simplest statement of the model): 20 px cells, per-cell
    time `−0.03 y + offset + t × u` (u 0.5–1), so 17–33 rows/s, a 33-row period, an 8-row fade, glyph change 2/s; the
    clock's rate falls to 0.15 with the crank out and climbs back to 1 by 0.07 a frame when it is docked [M].
  - tte `matrix`: `rain_fall_delay_range` 2–15 frames, `rain_column_delay_range` 3–9 frames between starting 1–3 new
    columns, `symbol_swap_chance` 0.005, `color_swap_chance` 0.001, `rain_time` 15 s, `resolve_delay` 3 frames,
    `highlight_color` `#dbffdb`, `rain_color_gradient` `#92be92 #185318`, `final_gradient_stops` `#92be92 #336b33`
    (read at fc6f75e, 2026-10-29) [P]. Omarchy runs it at `--frame-rate 120` (v3) and ttfx at a 120 Hz virtual clock (v4),
    which doubles every per-frame rate (`research_notes/Lemna effects/omarchy.md` §5.4) [P].
  - cmatrix: `-u 0–9` step delay in tens of ms (default 4), `-a` async, `-k` "Every characters change", `-b`/`-B` bold
    (read at 5c082c6, 2023-12-09). Its man page: "This program is very CPU intensive" [P].
  - unimatrix: `-s` speed 0–100 (default 85; delay = (100 − speed) × 10 ms), `-a`, `-f` "flashers" (one writer cell in
    10 keeps changing) (read at dff519f) [P].
  - neo: `--density` 1.0 (best 0.25–4), `--speed` 8, `--async`, `--glitchpct` 10, `--glitchms` 300,400, `--lingerms`
    1,3000, `--rippct` 33, `--shortpct` 50, `--maxdpc` 3, `--fps` 60 ("Lower frame rates will reduce CPU usage and improve
    battery life on portable devices") (read at 6ba93ac) [P].
  - xscreensaver: xmatrix `--density` 75, `--delay` 10000 µs, 5 spinners; glmatrix `--density` 20, `--speed` 1.0,
    `--delay` 30000 µs, fog, waves and rotation on (https://www.mankier.com/6/xmatrix, https://www.mankier.com/6/glmatrix;
    sources `hacks/xmatrix.c`, `hacks/glx/glmatrix.c` via the github.com/Zygo/xscreensaver mirror) [P].
- The macOS screensaver "by the TerminalApp folks" in the brief: I found no such project. Open macOS savers: Ametrix
  (https://github.com/YaphetSf/ametrix: AppKit/Core Text, `frameRate` 15–120, `density` 0.2–3.0, example Menlo 16, speed
  18–38, trail 14–48, `minimumTailAlpha` 0.08) and MatrixRain (github.com/burakoskay/MatrixRain), neither read in code [P].

## 4. What separates a real Matrix rain from the cheap one

Each item names who says it.

1. **Sliding strings instead of fixed glyphs.** The film's glyphs "stick in the same place" (Animal Logic); Rezmason's
   first-listed rule [P]. Lemna's Rain slides its strings today.
2. **Smooth pixel scrolling instead of a cell at a time** (jwz, in the header of `xmatrix.c`, written for people sending
   him patches) [P].
3. **All columns at one speed.** cmatrix's default is lockstep (its `-a` exists to fix it); Rezmason varies speed 2:1 per
   column; an Inventive HQ tutorial calls columns "moving in lockstep" one of the reasons most versions look wrong
   (search summary only, page refused the fetch: UNVERIFIED) [P].
4. **One trail length.** Every faithful version spreads lengths 3–4× or more (Rezmason p5 to p95 ≈ 4×, tte 10×) [M].
5. **Heads not distinct.** Every version listed above gives the head its own pale colour or white and bold [P].
6. **No mutation.** The common canvas snippet, as posted under Rezmason's HN thread (2022-09-23,
   https://news.ycombinator.com/item?id=32951362): glyphs "01" in 10 px Arial, every column one row a frame every 35 ms
   (all at 28.6 rows/s), a column restarting at the top with a 2.5 % chance a frame once past the bottom, the glyph in the
   trail's own colour (no head), `rgba(10, 10, 10, 0.04)` laid over the whole canvas each frame; no glyph ever changes
   once drawn [P]. It shows items 2, 3, 5 and 6 at once.
7. **A frame-rate-bound exponential fade.** That overlay dims every glyph by 4 % a frame: half its brightness in 17
   frames (0.6 s), a trail whose length changes with the frame rate [M]; Rezmason's trail is linear in time and space.
8. **Too crisp and saturated.** The film is soft (Marshall, jwz, Rezmason's bloom) [P].
9. **Wrong glyphs:** binary, full-width or unmirrored katakana, plain Latin text. "Get the right glyphs. Like the actual
   ones" (Rezmason) [P].
10. **The official 1999 screensaver** "was very inaccurate and did not match what the computer screens in the movie did"
   (jwz); Rezmason: it was made by the website team in Macromedia Director; an HN reader remembers "the glyphs and
   animation didn't seem right" [P].
11. **Accuracy check by the makers:** Rezmason's README notes a Vice Motherboard feature (2022) "with insight into the
   effect from Lilly Wachowski"; search summaries say she found it as good as or better than the original. The article
   itself did not load: UNVERIFIED [P].

## 5. Accessibility and running it continuously

- **WCAG 2.2.2 Pause, Stop, Hide (A):** moving content that "(1) starts automatically, (2) lasts more than five seconds,
  and (3) is presented in parallel with other content" needs "a mechanism for the user to pause, stop, or hide it" unless
  essential; "Moving content can also be a severe distraction for some people"
  (https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html) [P]. An idle rain qualifies. Lemna already has the
  mechanism (Session › Ambience ▸ Off; Off at first, D0).
- **WCAG 2.3.3 Animation from Interactions (AAA):** "Motion animation triggered by interaction can be disabled", with
  `prefers-reduced-motion` as the sufficient technique (C39)
  (https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html) [P]. Lemna: Reduce Motion forces Off (S1).
- **Distraction:** DESIGN F0 cites Bartram 2003 and Maglio & Campbell 2000: travelling motion beside a text task is the
  most distracting kind measured. A screen-wide idle rain is that, in peripheral vision, for the whole session [I].
  Hence the low idle alphas and speeds in §6.
- **Flashes (WCAG 2.3.1):** single glyph swaps are far below the area that counts; keep the ramp between states slow
  (≥ 0.25 s), so the screen never pulses [I].
- **Frame budget:** Lemna measured (DESIGN A1, release, 2×) the step at 1.6–26 µs a frame at the cap, encode and commit
  9–12 µs, the GPU 0.39–0.58 ms for 2,000 glyphs over a 3024 × 1964 drawable: 2–4 % of a 16.7 ms frame [P]. At 60 Hz that
  is 23–35 ms of GPU work a second at the cap. The cost of running it continuously is mostly elsewhere: "Every time your
  app updates ... content to screen, it requires the CPU, GPU, and screen to be active", and "Extraneous or inefficient
  drawing can pull system resources out of low-power states" (Apple, Energy Efficiency Guide for Mac Apps,
  https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/UsingEfficientGraphics.html)
  [P], plus WindowServer composing a full-screen layer on every screen each frame. I found no controlled watt figure for
  a full-screen 60 Hz overlay on a Mac: measure it (`sudo powermetrics --samplers gpu_power,cpu_power -i 1000`, box open,
  Ambience Off against Rain idle) before shipping [I].
- **Cheapest faithful choice:** the heads step a cell at a time and the film runs at 24 fps, so the idle rain loses
  nothing at 30 Hz (`CAMetalDisplayLink.preferredFrameRateRange` 24–30) and halves the frames; 60 Hz only while typing [I].

## 6. Parameters for Lemna

### 6.1 What changes, and why

| Lemna today (pass 18) | The film / Rezmason | Change |
|---|---|---|
| Trail glyphs drawn at `y + (k + 1) × row` from the head: the string slides | glyphs fixed in cells, light moves | a grid of cells, each with a glyph and a brightness; a drop is a head that lights cells |
| Trail ×0.75 a glyph, 4–8 glyphs | linear, 23–90 rows | linear in time per cell, 6–30 rows |
| Head accent, trail text (C1) | head pale, trail coloured | head text #d8dce3, trail accent #7aa7f0 (needs the user's OK: amends C1) |
| Nothing without keys, gone 4 s after the last | always, whole screen | an idle rain while the box shows (needs a line in A1) |
| Every drop dies at 3 s | runs off the bottom | dies when its trail has left the screen |
| 150–300 pt/s on 37 pt rows (4–8 rows/s) | 15–30 rows/s, 2:1 per column | per-column speed, 2:1, scaled by intensity |
| Glyphs a–z | katakana, digits, few symbols, mirrored | `012345789Zz:."=*+-<>|_` (optional; a–z is Lemna's own), mirrored if the shader allows |
| `rainScale` 1.0: 21 × 37 pt cells, 26 rows on a 982 pt screen | ≈ 50 rows, square cells | `rainScale` 0.5 and an 18.5 pt square pitch: 53 rows |

### 6.2 The set

Units: rows of the rain grid (18.5 pt), seconds, α over the dim. One intensity I in 0…1 drives everything between the two
columns; values not marked per-drop are read when a drop starts, so a drop keeps its speed and length.

| Parameter | Idle (I = 0) | Typing (I = 1) | Based on |
|---|---|---|---|
| Glyph size | `rainScale` 0.5 (Menlo 14 pt) | same | Rezmason's ≈ 19 pt square cells at 80 columns on a 1512 pt wide screen [M] |
| Grid pitch | 18.5 pt across and down (81 × 53 on 1512 × 982 pt) | same | Rezmason classic: square cells, 80 × 50 on 16:10 [M] |
| Columns showing a drop | 0.30 | 0.70 | between glmatrix 20 % and xmatrix 75 % / Rezmason 100 %; capped by the sprite budget [P][I] |
| New drops per screen-second | ≈ 2.8 | ≈ 18 (+ one per key) | = active × columns × mean speed ÷ (rows + mean trail), at 81 × 53 [M] |
| Column speed, rows/s | 5–10 (93–185 pt/s) | 15–30 (278–555 pt/s) | Rezmason classic 15–30 and its 2:1 per column; twilight 5–10; neo 8 max [M][P] |
| Trail length, rows | 6–18, log-uniform | 10–30, log-uniform | Rezmason's skew (median nearer the short end, p95 ≈ 4 × p5); classic 23–90 scaled to an ambient screen [M][I] |
| Gap before the next drop in a column | ≥ 3 rows | ≥ 2 rows | Rezmason's never-collide rule; drops in a column share its speed [P] |
| Head α (text #d8dce3) | 0.35 | 0.85 | pass 15 "subtle" 0.3 and pass 16 0.8 (DESIGN A1) [P] |
| Trail top α (accent #7aa7f0) | 0.20 | 0.50 | Rezmason: trail top 0.6 on the palette, head 2 × 0.6 of a paler colour, so the trail's top is 0.5 of the head by signal, ≈ 0.75 by luminance; here ≈ 0.58 [M] |
| Trail fade | linear to 0 over trail ÷ speed seconds, per cell | same | Rezmason sawtooth [M] |
| Glyph change per lit glyph per s | 0.3 | 1.5 | tte 0.3/s at 60 fps, neo ≈ 0.3/s; Rezmason 1.8/s [M][P] |
| Glyph change, how | instant swap; optional: a fixed cyclic order over the set | same | Rezmason, tte, cmatrix swap; the sequels' fixed order [P] |
| Head glow (optional) | none | one extra sprite per head, scale 1.8, α 0.15, text colour | Rezmason bloom 0.7, Marshall's glows; test it, a scaled glyph is not a blur [P][I] |
| Frame rate | 30 Hz | 60 Hz | the film's 24 fps and cell-stepped heads; Apple's energy guide [P][I] |
| Sprites, 1512 × 982 pt | ≈ 290 | ≈ 1,100 + 200 (6 keys/s) to 340 (10 keys/s) from keys | 24 × 12 and 57 × 19 lit cells plus heads; a key drop lives ≈ 2.4 s [M] |

**Key drops (every glyph key, Space and Return none, as now):** in the key's column at the key's row height (as now),
the typed glyph at the head, α 0.95 in the text colour (or the accent, if C1 stays), its trail in the accent from 0.55,
8–20 rows log-uniform, at its column's current speed so it never cuts through a background drop; where it overlaps a
background trail each cell takes the brighter of the two (one sprite a cell, as Rezmason's one brightness a cell).

**The ramp:** target I* = min(keys of the last `rateWindow` (2 s) ÷ 2 s ÷ 6 keys/s, 1); 6 keys/s is about 70 words a
minute, so ordinary typing reaches 0.5–0.8 (the existing `fastRate` 10 would leave it near half). I follows I* with
τ = 0.25 s rising (the first keys show within half a second) and τ = 1.2 s falling, starting 0.8 s after the last key, so
the rain is back near idle about 4 s after the last key, as today's `linger`. Asymmetric so the pauses between words
(0.2–0.5 s) do not make it pulse [I]. Precedent for a ramped rain clock: Rezmason's Playdate port, 0.15× → 1× at 0.07 a
frame [P]. Implementation sketch: a rain clock running at s(I) = 1/3 + 2/3 I (speeds and glyph changes together, as
Rezmason's `animationSpeed`), spawn rate and α lerped by I, trail length set per drop [I].

**State and cost:** a cell array (glyph slot, brightness, fade per second, role) of 81 × 53 = 4,293 cells on a
1512 × 982 pt screen, 138 × 78 = 10,764 on 2560 × 1440 pt; heads as a short list; sprites only for cells above α 0.02.
On a large display the typing state passes the 2,000 cap (≈ 2,050–2,200 at 2560 × 1440 pt): drop the dimmest trail
cells first, then spawn fewer [M][I].

**Mirroring:** the vertex shader builds a quad's corners from `corner × half_size` and its atlas UV from `corner` alone
(`Particles.swift`, `sprite_vertex`), so a glyph sprite with a negative width would probably draw mirrored; check the
fragment shader's use of `half_size` first. UNVERIFIED [I].

### 6.3 For the user to decide

1. The idle rain amends A1 ("typing feeds and silence starves", gone 4 s after the last key, the display link paused) and
   runs the link for as long as the box shows: record it in DESIGN, and measure the power (§5).
2. Head and trail colours: the film's mapping (head text, trail accent) against C1 (head accent, trail text).
3. Idle rain on every screen's dim (Rain's current reach) or only on the box's screen (a third of the cost on three
   screens, and nothing moving at the edge of sight on the others).
4. Glyphs: the film's ASCII overlap, a–z, or both; mirrored or not.
5. Looks to imitate: 2003 classic (gradient trails; recommended for low-key) or 1999 operator (flat, crowded, fast).

## 7. Method

- Cloned at depth 1 into a scratch folder and read in code: Rezmason/matrix (5ba9049: `js/config.js`,
  `shaders/glsl/rainPass.raindrop.frag.glsl`, `rainPass.symbol.frag.glsl`, `rainPass.frag.glsl`, `rainPass.vert.glsl`,
  `palettePass.frag.glsl`, `js/regl/rainPass.js`, `glyph order.txt`, `playdate/matrix_c/main.c`, the cmaps of
  `assets/Matrix-Code.ttf` and `Matrix-Resurrected.ttf` with fontTools), ChrisBuilds/terminaltexteffects (fc6f75e:
  `effects/effect_matrix.py`, `engine/terminal.py`), abishekvashok/cmatrix (5c082c6: `cmatrix.c`, `cmatrix.1`),
  will8211/unimatrix (dff519f), st3w/neo (6ba93ac: `doc/neo.6`, `src/cloud.cpp`), xscreensaver's `xmatrix.c` and
  `glmatrix.c` (Zygo mirror, master).
- Trail and gap lengths [M]: Rezmason's brightness `b = 1 − fract(w(x))`, `w(x) = x + 0.3 sin(√2 x) + 0.2 sin(√5 x)`,
  `x = (0.01 y + c) / raindropLength`, a cell shown when `contrast × b + brightness > 0`; for 20,000 consecutive teeth,
  the rows from w = n to the threshold (trail) and from there to n + 1 (gap), by bisection. Speeds from the phase per row
  (0.01) and per second (fallSpeed × u). Frame-based rates of the terminal programs converted at their default frame
  rates or delays.
- Lemna's cell (Menlo 28 pt, the atlas's 171 glyphs, 2 pt pad, 2×): 21 × 37 pt, computed with Core Text as
  `Ambience.Glyphs` does; at `rainScale` 0.5, 10.5 × 18.5 pt [M].
- Web: Wikipedia, befores & afters, SoraNews24, HuffPost UK via Yahoo, No Film School (2025-08-28, which repeats befores
  & afters), Pushing Pixels, Creative Review, BUF, the W3C Understanding pages, Apple's archived energy guide, HN via the
  Algolia API. Not reachable: CNET, Vice, Inventive HQ, the Internet Archive.
