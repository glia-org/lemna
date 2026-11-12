# Third-party material in LemnaClicks

## The default sound pack (`Sources/LemnaClicks/DefaultPack/`)

All twelve clicks are cut from three recordings of one mechanical keyboard, a Keychron K10 with linear
switches, by the Freesound user **Sadiquecat** (recorded and uploaded on 2025-02-22, in the pack
"Computer sounds", https://freesound.org/people/Sadiquecat/packs/38565/).

| Recording | Page | Cut into |
|---|---|---|
| Keychron k10 A to + individual keys (#789628) | https://freesound.org/people/Sadiquecat/sounds/789628/ | `letter-1` … `letter-6`, `backspace-1`, `backspace-2` |
| Keychron k10 space_bar (#789630) | https://freesound.org/people/Sadiquecat/sounds/789630/ | `space-1`, `space-2` |
| Keychron k10 Enter (#789629) | https://freesound.org/people/Sadiquecat/sounds/789629/ | `paragraph-1`, `paragraph-2`, `send-1` (below) |

### Licence: CC0 1.0 (public domain dedication)

Checked on each of the three pages on 2026-10-27. Each page shows the licence "Creative Commons 0", linked to
http://creativecommons.org/publicdomain/zero/1.0/, with the statement:

> You can copy, modify, distribute and perform the sound, even for commercial purposes, all without the need
> of asking permission to the author.

and the author's description of each sound adds:

> Attribution is greatly appreciated but not required. Recommendation : X sound by Sadiquecat on
> Freesound.org in CC0 licence.

Credit, as the author asks: Keychron K10 key sounds by Sadiquecat on Freesound.org, CC0.

### What was taken and what was done to it

- **Source files:** Freesound's public high-quality previews (Ogg Vorbis, 96 kHz stereo, about 215–300
  kbit/s), because the originals (96 kHz 24-bit WAV/FLAC) download only with a Freesound login. SHA-256:
  `0a961580d1ac4fe60a999c4f7986e1bb73df4afba37424295ac45f7b8db72a2c` 789628-hq.ogg,
  `6065458f3baf73195246377ee79f51e5182d940943295d0712f06954db93b7cd` 789629-hq.ogg,
  `1617888e64d456878d71083787b62572125e6c501c92dda77ed6c14bc41e0a16` 789630-hq.ogg
  (from `https://cdn.freesound.org/previews/789/<id>_5287430-hq.ogg`).
- **Decoded** to 48 kHz mono 16-bit: `ffmpeg -i <id>-hq.ogg -ar 48000 -ac 1 -c:a pcm_s16le <id>.wav`.
- **Cut** with `tools/cut_click.py cut <in> <out> <time s> <span ms> [--rate r]`: from 2 ms before the hit's
  peak, the key press only (each span ends before the key's release sound), 0.5 ms fade-in, 25 ms
  half-cosine fade-out, peaks normalised to -6 dBFS, 70–123 ms each, 102 KB together:

  | File | From | Time (s) | Span (ms) | Rate |
  |---|---|---|---|---|
  | letter-1 … letter-6 | 789628 | 1.170, 3.007, 5.966, 6.859, 10.606, 11.921 | 70, 70, 74, 82, 92, 82 | 1 |
  | backspace-1, backspace-2 | 789628 | 2.059, 13.477 | 68, 68 | 0.88 |
  | space-1, space-2 | 789630 | 0.006 | 116 | 1, 0.94 |
  | paragraph-1, paragraph-2 | 789629 | 0.006 | 92 | 1, 0.94 |

- **Backspace** has no recording of its own: its two clicks are two other letter hits played 12 % slower
  (lower and a little longer). **Space and Return** have one take each: the second sample of each is the same
  take 6 % slower.

## How the new packs were measured

Brightness and decay below come from one script (not kept: this is all it does) run over every cut and over the
default pack's, so the figures compare with each other: the spectral centroid and the share of energy above 5 kHz from 2 ms before a cut's peak to
40 ms after it (a 2048-point FFT under a Tukey window with 2 ms tapers), and the time from the peak to -30 dB in 2 ms
RMS frames. Measured that way the default pack's letters have a centroid of 1.9–2.8 kHz (mean 2.5) and 7–22 % of
their energy above 5 kHz (mean 14 %), -30 dB after 44–72 ms. (`research_notes/Flow sounds and ambience/sounds.md`
measured other windows and gives 0–1 % for two of these cuts; compare within this file.) Nothing was listened to.

## The Typewriter pack (`Sources/LemnaClicks/TypewriterPack/`)

All twelve clicks are cut from three recordings of one manual typewriter by the Freesound user **moodyfingers**
(uploaded on 2024-05-03, in the pack "Silver Typewriter Pack", https://freesound.org/people/moodyfingers/packs/40966/;
recorded with a smartphone microphone, noise-reduced, normalised and converted to 44.1 kHz by the uploader).

| Recording | Page | Cut into |
|---|---|---|
| Silver Typewriter (Keystroke) (#734313) | https://freesound.org/people/moodyfingers/sounds/734313/ | `letter-1` … `letter-6`, `backspace-1`, `backspace-2` |
| Silver Typewriter (Space Bar) (#734318) | https://freesound.org/people/moodyfingers/sounds/734318/ | `space-1`, `space-2` |
| Silver Typewriter (Carriage Return Lever 3) (#734312) | https://freesound.org/people/moodyfingers/sounds/734312/ | `paragraph-1`, `paragraph-2` |
| Silver Typewriter (Margin Release and Carriage Return) (#734314) | https://freesound.org/people/moodyfingers/sounds/734314/ | `send-1` (below) |

### Licence: CC0 1.0 (public domain dedication)

Checked on 2026-10-28 on each of the pack's nine pages: "Creative Commons 0", linked to
http://creativecommons.org/publicdomain/zero/1.0/. The uploader's description adds, beside the licence:

> Credit/Attribution is not mandatory. However, if you choose to do so, you may provide the URL of this sound or
> mention my name (along with the title of the sound) in your description, video, game or project.

and asks that the sounds not be used in "prohibited (obscene, misleading, political, propaganda and/or hateful)
content" nor "on AI apps, models or anything of the sorts". Lemna is none of these: it holds no AI model and trains
none.

Credit, as the uploader suggests: Silver Typewriter (Keystroke), (Space Bar), (Carriage Return Lever 3) and, for the
send (below), (Margin Release and Carriage Return) by moodyfingers on Freesound.org, CC0.

### What was taken and what was done to it

- **Source files:** Freesound's HQ previews (Ogg Vorbis, 44.1 kHz stereo, 192 kbit/s; the originals are 44.1 kHz
  24-bit FLAC, which download only with a login), from `https://cdn.freesound.org/previews/734/<id>_15504031-hq.ogg`.
  SHA-256:
  `5917ea41c8c47aba4550f1687c811a0f639b04c95f368c102f5b1983ba45d033` 734313-hq.ogg,
  `12c280d7fd011c842777ec42f190de08f95cd5c1808232bf19efaf0e7840e091` 734318-hq.ogg,
  `3cc29a75213781e46b1ef76c1ee6ffeb5d239c9f48c161921cf01b04b67a85c1` 734312-hq.ogg.
- **Decoded** through a low-pass to 48 kHz mono 16-bit:
  `ffmpeg -i <id>-hq.ogg -af lowpass=f=3500:p=2 -ar 48000 -ac 1 -c:a pcm_s16le <id>.wav` (two-pole, 12 dB/octave,
  -3 dB at 3.5 kHz). Why not the high shelf the research note proposed: measured on the letter cuts below, a shelf of
  -6 dB from 4.5 kHz left 72–89 % of the energy above 5 kHz, still far brighter than the default pack.
- **Cut** with `tools/cut_click.py cut <in> <out> <time s> <span ms> [options]`: from 2 ms before the hit's peak
  (`--lead`: further before it), the strike and its ring up to the next sound of the mechanism (the key's return
  some 100 ms later), 0.5 ms fade-in, 25 ms half-cosine fade-out (`--fade`), peaks normalised to -6 dBFS and then
  moved by `--gain`, 78–180 ms each, 125,764 bytes together:

  | File | From | Time (s) | Span (ms) | Options |
  |---|---|---|---|---|
  | letter-1 … letter-6 | 734313 | 0.200, 0.940, 1.595, 1.765, 2.285, 3.035 | 98, 90, 100, 100, 90, 95 | `--gain` 0, -1.5, -1.1, -2.5, -3.5, 0 |
  | space-1, space-2 | 734318 | 1.282, 2.075 | 110, 110 | |
  | paragraph-1 | 734312 | 1.265 | 176 | `--lead 31 --fade 40 --max 250` |
  | paragraph-2 | 734312 | 2.455 | 180 | `--fade 40 --max 250` |
  | backspace-1, backspace-2 | 734313 | 0.940, 3.035 | 70, 70 | `--rate 0.9 --gain -6` |

- **Letters** are the six strikes of the keystroke recording (it holds five keystrokes, one of them two strikes
  170 ms apart). They are levelled by their loudest 4 ms rather than by their peak (the recipe of
  `sounds.md` §5): the gains above bring each to the quietest, which narrows the spread of their energy over the first
  40 ms from 6.7 to 3.2 dB.
- **Return** is the carriage-return lever's ratchet, two of its pulls (the recording holds eight), 176 and 180 ms:
  longer than a key, which a paragraph's rarity allows.
- **Backspace**: the pack has none, and the one CC0 backspace recording found (khwez, #712231) is MP3 at source and
  another machine; so two of the keystrokes, 10 % slower and 6 dB lighter, shortened.
- **Measured** (see above), the letters before the low-pass (the same cuts from an unfiltered decode), with the
  shelf instead, and as shipped:

  | Letters | Centroid | Energy above 5 kHz | Peak to -30 dB |
  |---|---|---|---|
  | unfiltered | 9.8–13.1 kHz (mean 10.9) | 86–94 % (mean 91 %) | 48–80 ms |
  | high shelf -6 dB from 4.5 kHz | 8.2–12.1 kHz (mean 9.8) | 72–89 % (mean 83 %) | |
  | low-pass 3.5 kHz, as shipped | 1.4–5.1 kHz (mean 3.5) | 5–41 % (mean 23 %) | 66–82 ms |
  | default pack (Keychron) | 1.9–2.8 kHz (mean 2.5) | 7–22 % (mean 14 %) | 44–72 ms |

  Space 10.8 and 11.9 kHz with 88 and 92 % above 5 kHz before, 2.1 and 2.3 kHz with 11 and 14 % after; Return 13.2
  and 12.0 kHz (94 and 91 %) before, 1.1 kHz (4 %) after; backspace 8.6 and 8.5 kHz (89 and 87 %) before, 4.2 kHz
  (27 and 25 %) after. In the source the strikes fall 30 dB below their peak 48–102 ms after it.

## The Soft pack (`Sources/LemnaClicks/SoftPack/`)

Cut from six recordings by **Sadiquecat**, the default pack's uploader (uploaded on 2025-04-16, in the same pack
"Computer sounds", https://freesound.org/people/Sadiquecat/packs/38565/; Zoom H2n in MS mode, trimmed and normalised
by the uploader): the letters and the space bar of a MacBook Air M2, the Enter and Delete keys of a FUJITSU keyboard.

| Recording | Page | Cut into |
|---|---|---|
| MBA A key mono (#799109) | https://freesound.org/people/Sadiquecat/sounds/799109/ | `letter-1`, `letter-4` |
| MBA R key mono (#799110) | https://freesound.org/people/Sadiquecat/sounds/799110/ | `letter-2`, `letter-5` |
| MBA Regular keys Multi-take MS (#799111) | https://freesound.org/people/Sadiquecat/sounds/799111/ | `letter-3`, `letter-6` |
| MBA Space-bar Multi-take MS (#799112) | https://freesound.org/people/Sadiquecat/sounds/799112/ | `space-1`, `space-2` |
| FUJITSU Computers Keyboard - Enter key Press Mono (#799116) | https://freesound.org/people/Sadiquecat/sounds/799116/ | `paragraph-1`, `paragraph-2`, `send-1` (below) |
| FUJITSU Computers Keyboard - Delete key Press Mono (#799115) | https://freesound.org/people/Sadiquecat/sounds/799115/ | `backspace-1`, `backspace-2` |

### Licence: CC0 1.0 (public domain dedication)

Checked on 2026-10-28 on each of the six pages (and on 799113, 799114, 799117, 799118, 799122–799124): "Creative
Commons 0", linked to http://creativecommons.org/publicdomain/zero/1.0/, with the uploader's note as for the default
pack: "Attribution is greatly appreciated but not required. Recommendation : X sound by Sadiquecat on Freesound.org
in CC0 licence."

Credit, as the author asks: MacBook Air M2 and FUJITSU key sounds by Sadiquecat on Freesound.org, CC0.

### What was taken and what was done to it

- **Source files:** the HQ previews (Ogg Vorbis, 96 kHz; the originals are 96 kHz 24-bit WAV), from
  `https://cdn.freesound.org/previews/799/<id>_5287430-hq.ogg`. SHA-256:
  `8db847cecc5621cd34b80141bb3a90dabfd3777b6a0c0401dfb104b130f6b4ab` 799109-hq.ogg,
  `6f53fdbcba277a4bd3560ae7dd3152d84b58030385a953d60cdd7b8398d0a109` 799110-hq.ogg,
  `b4ecebb6a1ff0102ef538fdb130cb24927b109a81433d5290f195ac576076f51` 799111-hq.ogg,
  `8ff930d76f107945344122856715d6c71c453d37ddfa2a0b51133924cb2ff2f2` 799112-hq.ogg,
  `d556ca28e4ba9506e4f5ae77c7800c2d271cfe111ee6f64303465ea9d40b27e9` 799116-hq.ogg,
  `2ce9ea7852f1057703b603ab791dd292f0cb8b57abdeac5f929efbdda3336bc9` 799115-hq.ogg.
- **Decoded** to 48 kHz mono 16-bit as the default pack (`-ar 48000 -ac 1 -c:a pcm_s16le`), except:
  - the two multi-takes (799111, 799112) are a raw MS pair, mid then side; only the mid is taken
    (`-af "pan=mono|c0=c0"`): the side carries the room, its floor about 15 dB above the mid's;
  - Enter and Delete through a high-pass (`-af highpass=f=150:p=2`, 12 dB/octave): 72–75 % of their energy lies
    below 80 Hz (the handheld recorder's or the desk's thump, not the key), which peak normalisation would otherwise
    turn into a boom 7–10 dB above the letters' energy.
- **Cut** with `tools/cut_click.py` as above, the press only (each span ends before the key's release), 68–119 ms
  each, 103,868 bytes together:

  | File | From | Time (s) | Span (ms) | Options |
  |---|---|---|---|---|
  | letter-1, letter-4 | 799109 | 0.028 | 74 | letter-4 `--rate 0.95` |
  | letter-2, letter-5 | 799110 | 0.015 | 80 | letter-5 `--rate 0.95` |
  | letter-3, letter-6 | 799111 (mid) | 1.160 | 80 | letter-6 `--rate 0.95` |
  | space-1, space-2 | 799112 (mid) | 1.926, 4.347 | 68, 70 | |
  | paragraph-1, paragraph-2 | 799116 | 0.088 | 110 | `--lead 8`; paragraph-2 also `--rate 0.94` |
  | backspace-1, backspace-2 | 799115 | 0.040 | 112 | `--lead 10`; backspace-2 also `--rate 0.94` |

- **Takes:** three distinct letter presses, each also 5 % slower. 799109 is 799111's first take (their waveforms
  correlate at 0.97), so 799111 gives its second; 799113 (MBA Space-bar mono) is likewise 799112's fourth take, and
  brighter than the other four (3.4 kHz centroid against 0.2–0.5), so the space cuts are two of the darker ones. Enter
  and Delete have one take each: the second sample of each is the same take 6 % slower, as in the default pack.
- **Measured:** letters 0.35–1.13 kHz with 1–9 % of their energy above 5 kHz, -30 dB after 22–64 ms; space 0.26 and
  0.47 kHz; Enter and Delete 0.28–0.34 kHz after the high-pass (0.08–0.11 kHz before).

## The Electric pack (`Sources/LemnaClicks/ElectricPack/`)

Cut from four recordings of one electric typewriter by the Freesound user **magedu** (uploaded on 2015-06-29 and
2015-08-17, in the pack "Typewriter", https://freesound.org/people/magedu/packs/17107/; Zoom H4n and Rode NTG-3, 96 kHz
24-bit mono).

| Recording | Page | Cut into |
|---|---|---|
| typewriter_electric_typing_01.wav (#277721) | https://freesound.org/people/magedu/sounds/277721/ | `letter-1` … `letter-6`, `backspace-1`, `backspace-2` |
| typewriter_electric_spacebar.wav (#277724) | https://freesound.org/people/magedu/sounds/277724/ | `space-1` |
| typewriter_electric_spacebar_several_times.wav (#319944) | https://freesound.org/people/magedu/sounds/319944/ | `space-2` |
| typewriter_electric_return.wav (#319945) | https://freesound.org/people/magedu/sounds/319945/ | `paragraph-1`, `paragraph-2`, `send-1` (below) |

### Licence: CC BY 4.0 (attribution required)

Checked on 2026-10-28 on each of the four pages and on the pack's other electric sounds (277722, 277723, 319943):
"Attribution 4.0", linked to https://creativecommons.org/licenses/by/4.0/. The licence (section 3(a)) requires, with
every copy: the creator's name as they give it, a link to the material, a notice that it is under CC BY 4.0 with a
link to the licence, and a note of what was changed. The credit line, word for word as it is also in the pack's
`pack.json` (`attribution`), which ships with the clicks in the app's `Contents/Resources/ElectricPack`:

> typewriter_electric_typing_01.wav (https://freesound.org/people/magedu/sounds/277721/),
> typewriter_electric_spacebar.wav (https://freesound.org/people/magedu/sounds/277724/),
> typewriter_electric_spacebar_several_times.wav (https://freesound.org/people/magedu/sounds/319944/) and
> typewriter_electric_return.wav (https://freesound.org/people/magedu/sounds/319945/) by magedu
> (https://freesound.org/people/magedu/), from the pack Typewriter (https://freesound.org/people/magedu/packs/17107/),
> licensed under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Changed for Lemna: cut into single key
> sounds, high-pass filtered at 150 Hz, peak-normalised, some slowed and lowered in level, the return also spliced
> shorter (its clutch's impact onto the end of the carriage's run). No warranties are given.

"spliced" came with the send (pass 19a, below), on 2026-10-30.

### What was taken and what was done to it

- **Source files:** the HQ previews (Ogg Vorbis, 96 kHz mono), from
  `https://cdn.freesound.org/previews/<id ÷ 1000>/<id>_4877562-hq.ogg`. SHA-256:
  `8a3fbb258fba7ed38201c41ff5fb3ca0b309d58098962373220c83a4be16417c` 277721-hq.ogg,
  `9520cf646189b140521c01774acafa8a3cb5bbe810459e990a973daa7456b64b` 277724-hq.ogg,
  `10dbe300ec9f59d1eb1777cf596a7920282c3896effd17c350ce03cafe243999` 319944-hq.ogg,
  `b968b9460e1d37e664c5705d912a7da10bf110703da1ec095192c28b1f9d8936` 319945-hq.ogg.
- **Decoded** through a high-pass against the motor's hum:
  `ffmpeg -i <id>-hq.ogg -af highpass=f=150:p=2 -ar 48000 -ac 1 -c:a pcm_s16le <id>.wav`. Between the keys of
  typing_01 the floor is -57 dBFS with 77 % of its energy below 150 Hz (typing_02, not used: -55 dBFS, 94 %); after the
  filter -63 dBFS and 25 %, while the strikes keep their measures (centroid within 0.2 kHz). So the hum no longer gates
  on and off with each key at the level it did.
- **Cut** with `tools/cut_click.py` as above, 74–638 ms each, 209,600 bytes together:

  | File | From | Time (s) | Span (ms) | Options |
  |---|---|---|---|---|
  | letter-1 … letter-6 | 277721 | 0.702, 1.784, 3.332, 3.487, 5.797, 6.726 | 100 each | |
  | space-1 | 277724 | 0.445 | 110 | |
  | space-2 | 319944 | 0.843 | 74 | |
  | paragraph-1, paragraph-2 | 319945 | 0.313 | 600 | `--fade 200 --max 700`; paragraph-2 also `--rate 0.94` |
  | backspace-1, backspace-2 | 277721 | 1.064, 3.982 | 70, 70 | `--rate 0.9 --gain -6` |

- **Letters** are six strikes of the run with no other key within 140 ms after them. **Return** is the motor's
  carriage return, 1.3 s from its impact to the margin stop in the recording: its impact and the first part of the run, 600 ms with a 200 ms fade out
  (paragraphs are rare); one take, the second sample 6 % slower. **Backspace**: none in the pack; two other strikes of
  the run, 10 % slower and 6 dB lighter, as in the Typewriter pack. The quick spaces of 319944 come 80 ms apart, so
  `space-2` is 74 ms.
- **Measured:** letters 3.2–4.2 kHz with 12–37 % of their energy above 5 kHz (mean 23 %, as the Typewriter pack's after
  its low-pass), -30 dB after 72–86 ms; no low-pass, as they sit near the Typewriter pack's brightness; space 3.1 kHz
  (9 and 11 %); Return 1.8–2.0 kHz.

## The send sounds (`send-1.wav` in each pack, pass 19a)

⌘⏎'s sound when it pastes (DESIGN.md K1, amended 2026-10-30): one sample per pack, cut from a recording by the pack's
own uploader of the pack's own machine; for three packs the very file its Return was cut from. The evidence and the
cuts are `research_notes/Lemna rain/sendoff.md` (§2, the Recommendation); nothing was listened to.

| Pack | Recording | Page | Licence |
|---|---|---|---|
| Keychron (`DefaultPack`) | Keychron k10 Enter (#789629), Sadiquecat | https://freesound.org/people/Sadiquecat/sounds/789629/ | CC0 1.0 |
| `TypewriterPack` | Silver Typewriter (Margin Release and Carriage Return) (#734314), moodyfingers | https://freesound.org/people/moodyfingers/sounds/734314/ | CC0 1.0 |
| `SoftPack` | FUJITSU Computers Keyboard - Enter key Press Mono (#799116), Sadiquecat | https://freesound.org/people/Sadiquecat/sounds/799116/ | CC0 1.0 |
| `ElectricPack` | typewriter_electric_return.wav (#319945), magedu | https://freesound.org/people/magedu/sounds/319945/ | CC BY 4.0 |

### Licences

Checked on 2026-10-30 on each of the four pages. 789629, 734314 and 799116: "Creative Commons 0", linked to
http://creativecommons.org/publicdomain/zero/1.0/, with the uploaders' notes as quoted above (Sadiquecat:
"Attribution is greatly appreciated but not required"; moodyfingers: credit not mandatory, and the two riders, no
prohibited content, not on AI apps or models). 319945: "Attribution 4.0", linked to
https://creativecommons.org/licenses/by/4.0/; already in the Electric pack's credit line, whose note of what was changed
now says "spliced" (above). 734314 is new to the Typewriter pack (one of the pack's nine pages checked on 2026-10-28);
its credit is in the Typewriter pack's line above.

### What was taken and what was done to it

- **Source files:** the HQ previews, as for the packs, downloaded again on 2026-10-30 from
  `https://cdn.freesound.org/previews/<id ÷ 1000>/<id>_<uploader id>-hq.ogg` (Sadiquecat 5287430, moodyfingers
  15504031, magedu 4877562). 789629, 799116 and 319945 have the SHA-256 given above, unchanged; new:
  `2673ceed8d8841ddf4ec2a5433ffcf2ded99460702a26cc23672a12ab5038575` 734314-hq.ogg (Ogg Vorbis, 44.1 kHz stereo).
- **Decoded** with each pack's own filter, as above: Keychron none, Typewriter the 3.5 kHz low-pass, Soft and Electric
  the 150 Hz high-pass.
- **Made** with `tools/cut_click.py` (`cut` as above; `splice` joins two spans of a take); `tools/build_packs.sh` holds
  every command and makes the four files (run on 2026-10-30, it also remade the three packs' 36 clicks byte for byte as
  shipped):

  | File | From | Commands | Length |
  |---|---|---|---|
  | `DefaultPack/send-1` | 789629 | `cut 789629.wav send-1.wav 0.006 290 --fade 120 --max 400` | 290 ms |
  | `TypewriterPack/send-1` | 734314 | decoded through `lowpass=f=3500:p=2,atrim=8.78:9.24,asetpts=PTS-STARTPTS,afade=t=in:d=0.03:curve=qsin` (the return's last 460 ms, its run faded in over 30 ms) into `734314-tail.wav`, then `cut 734314-tail.wav send-1.wav 0.0 440 --lead 30 --fade 60 --max 500` | 440 ms |
  | `SoftPack/send-1` | 799116 | `cut 799116.wav send-1.wav 0.088 240 --lead 8 --fade 80 --max 300` | 240 ms |
  | `ElectricPack/send-1` | 319945 | `splice 319945.wav 319945-splice.wav 0.305 0.45 1.45 1.76 --cross 30` (the clutch's impact and burst, then the carriage run's last 310 ms over a 30 ms equal-power crossfade), then `cut 319945-splice.wav send-1.wav 0.0 420 --lead 8 --fade 100 --max 500` | 420 ms |

  133,616 bytes together. Every send peaks at -6 dBFS as the clicks do, no `--gain`.
- **Keychron and Soft** keep what their Return's cut stops before: the key's release. **Typewriter**: the carriage's
  run and its stop at the margin, not the lever (the pack's Return is the lever's ratchet); no bell, as the pack holds
  none; the fade-in is made in the decode, as `cut` fades in over 0.5 ms only, which would click in the middle of the
  run. **Electric**: a made sound, as a motor's carriage does not get shorter; the return as recorded puts the stop at
  about 1.27 s, a second after the text has gone (the panel's E2, not taken).
- **Measured** (sendoff.md §6's method: onsets in 2 ms RMS frames after two 200 Hz high-passes, envelopes in 5 and
  10 ms RMS frames, M max the loudest 400 ms of ffmpeg's `ebur128` over the file padded with 0.5 s of silence), times
  from the start of the file:

  | Pack | What lands when | Last frame within 40 dB of the loudest | M max: send | Return (`paragraph-1`) | `letter-1` |
  |---|---|---|---|---|---|
  | Keychron | the press at 2 ms, its release at 98 ms, about 10 dB under it | 240 ms | -28.0 LUFS | -28.2 | -32.2 |
  | Typewriter | the run, 11–19 dB under the stop; the stop at 257 ms, the file's peak | 385 ms | -25.1 LUFS | -22.3 | -31.7 |
  | Soft | the press at 8 ms (-8.2 dBFS, 2.2 dB under its Return's), its release at 121 ms, the file's peak | 205 ms | -27.2 LUFS | -27.7 | -33.2 |
  | Electric | the clutch's impact at 8 ms, the file's peak, its burst to about 120 ms, the run, the margin stop at about 250 ms, 17 dB under the impact | 335 ms | -26.8 LUFS | -25.5 | -26.6 |

## The Stone pack (`Sources/LemnaClicks/StonePack/`, pass 23a)

The click pack of the mindful theme, CK1 of `docs/design-panel-lemna-themes.html` (picked 2026-10-31; the evidence and
the plan in `research_notes/Lemna themes/sound.md` §4 and its Recommendations), with its space replaced: the user,
2026-10-31, "the space sound of the stone sound theme is really not good". The panel's space was kyles 452621, a
fingertip on a wooden counter: another material, and very dark (0.1–0.4 kHz). Now the keys all come from one rock on
one board, Return from a low slit drum, the send from a hand chime.

| Recording | Page | Cut into |
|---|---|---|
| Single Rock Hitting wood 3.wav (#319223), worthahep88 | https://freesound.org/people/worthahep88/sounds/319223/ | `letter-1`, `letter-5` |
| Single rock hitting wood.wav (#319226), worthahep88 | https://freesound.org/people/worthahep88/sounds/319226/ | `letter-2`, `letter-6`, `backspace-1` |
| Single Rock hitting wood 4.wav (#319227), worthahep88 | https://freesound.org/people/worthahep88/sounds/319227/ | `letter-3`, `letter-7`, `space-1`, `space-2` |
| Single Rock hitting wood 2.wav (#319228), worthahep88 | https://freesound.org/people/worthahep88/sounds/319228/ | `letter-4`, `letter-8`, `backspace-2` |
| VCSL, Slit Drum, `LogDrumLo_MedM_v1_rr1_Sum.wav` and `LogDrumLo_MedM_v2_rr1_Sum.wav` | https://github.com/sgossner/VCSL/tree/c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e/Idiophones/Struck%20Idiophones/Slit%20Drum | `paragraph-1`, `paragraph-2` |
| VCSL, Hand Chimes, `sus_E4_r01_main.wav` | https://github.com/sgossner/VCSL/tree/c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e/Idiophones/Struck%20Idiophones/Hand%20Chimes | `send-1` |

### Licences: CC0 1.0 (public domain dedication)

- **worthahep88:** checked on 2026-10-31 on each of the four pages: "Creative Commons 0", linked to
  http://creativecommons.org/publicdomain/zero/1.0/, with the statement quoted for the default pack ("You can copy,
  modify, distribute and perform the sound, even for commercial purposes, all without the need of asking permission
  to the author."). Uploaded on 2015-08-09 ("Rocks hitting wood to simulate bullets hitting wood"), 48 kHz 16-bit
  stereo, 0.13–0.74 s each; no credit is asked. Credit, none owed: Single rock hitting wood,
  2, 3 and 4 by worthahep88 on Freesound.org, CC0.
- **VCSL**, the Versilian Community Sample Library by Versilian Studios, at commit
  `c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e` (2026-01-14, the head of `master` on 2026-10-31): checked on 2026-10-31,
  the repository's `LICENSE` is the CC0 1.0 Universal legal code (GitHub reads it as CC0-1.0), and its README says:

  > This collection is under a Creative Commons 0 license. Essentially it's Public Domain- you can do whatever you want
  > with these sounds (even make commercial software), no royalties, no credit, no special terms.

### What was taken and what was done to it

- **Source files:**
  - worthahep88: the HQ previews (Ogg Vorbis, 48 kHz stereo; the originals, 48 kHz 16-bit WAV, download only with a
    login), from `https://cdn.freesound.org/previews/319/<id>_3443504-hq.ogg`. SHA-256:
    `5add35eaf13ed4b81f47091a5a4c1a962c4609526a4113f0c216e78b753bcf61` 319223-hq.ogg,
    `f8352b27ec25d65a7056bcbaa5c61bd27bf490122d80c92a2c660ed910cc2a67` 319226-hq.ogg,
    `69b6e8641249c0b1342df23e68f925e44899015bec1edd9255c5603ea93e9b6b` 319227-hq.ogg,
    `309ad3640f0c662989fcfac2773e38f5718b869ba4ee8e374f7dd0dc9409f4fc` 319228-hq.ogg.
  - VCSL: the WAVs themselves (lossless, 44.1 kHz stereo; the drum 16-bit, the chime 24-bit), from
    `https://raw.githubusercontent.com/sgossner/VCSL/c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e/<path>`; their git blob ids
    match the commit's tree. SHA-256:
    `cb77b9a6e7fc560d03b45102632ee0be5d08158cb03f59d63dd6fd2c4443ba4f` LogDrumLo_MedM_v1_rr1_Sum.wav,
    `609a9ae5441a007371e0dc3120d7e6d4ad5d23073f5f4fb3f16d0dc08823dfc4` LogDrumLo_MedM_v2_rr1_Sum.wav,
    `7196b23009e1acc8e03591c35e54144487991c75cfe22413e84e0bbfeb478caf` sus_E4_r01_main.wav.
- **Decoded** to 48 kHz mono 16-bit with no filter (`-ar 48000 -ac 1 -c:a pcm_s16le`), the chime from its strike, 6 ms
  into the file, with the last 400 ms of its 900 faded out on a raised cosine in the decode
  (`-af atrim=start=0.006,asetpts=PTS-STARTPTS,afade=t=out:st=0.5:d=0.4:curve=hsin`), as `cut` fades a third of a cut at
  most.
- **Cut** with `tools/cut_click.py cut` as above (from 2 ms before the peak unless `--lead`, the fade-out 25 ms or a
  third of the cut, 20 ms on the 60 ms letters), every command in `tools/build_packs.sh`; 200,972 bytes together:

  | File | From | Time (s) | Span (ms) | Options |
  |---|---|---|---|---|
  | letter-1 … letter-4 | 319223, 319226, 319227, 319228 | 0.038, 0.172, 0.069, 0.093 | 60 | `--gain -1.9` |
  | letter-5 … letter-8 | the same | the same | 60 | `--rate 0.94 --gain -1.9` |
  | space-1, space-2 | 319227 | 0.069 | 60 | `--rate 0.8`, `--rate 0.75`; `--gain 2.6` |
  | backspace-1, backspace-2 | 319226, 319228 | 0.172, 0.093 | 60 | `--rate 0.88 --gain -1.9` |
  | paragraph-1, paragraph-2 | LogDrumLo v1, v2 | 0.0 | 200 | `--lead 10 --fade 50 --max 250 --gain -4.1` |
  | send-1 | sus_E4 (decoded as above) | 0.0 | 900 | `--lead 30 --max 1000 --gain -14` |

- **Letters:** each file holds one hit; four takes, each also 6 % slower (sound.md's eight). **Backspace:** two of the
  brighter takes 12 % slower, as the default pack's. **Return:** two strengths of the low log drum (velocity layers 1
  and 2), cut from their onset, 200 ms. **Send:** one hand chime, E4 (661 Hz), 900 ms.
- **The space**, new: the dullest of the four takes, 319227 (centroid 1.20 kHz, the others 1.56–1.89), 20 and 25 %
  slower: 0.96 and 0.89 kHz, lower and darker than any letter (1.13–1.89 kHz), as the Keychron space (1.04–1.17 kHz)
  is to its letters (1.94–2.78), and like it about 4 LU over the letters by M max. The same rock on the same board, so
  it stays in the family; with no ring in the 60 ms taken, it has no note and keeps the ±3 %. Looked at and not taken,
  as no better: worthahep88's Single Rock hit Dirt (#319222, #319229, CC0, the same rock on the same day), 0.25–0.39
  kHz, as dark as the fingertip that was rejected; Pebbles on wooden bench (#682166, HenKonen, CC0), 4.2–6.9 kHz with
  bounces. No better CC0 source was found.
- **Levelled by loudness** (sound.md §4.3–4.4; pass 19a's "peaks at -6 dBFS, no gain" does not hold for this pack):
  each kind's cuts take one `--gain` that brings their mean M max (measured as for the sends above) to the mean of the
  default pack's same kind, so that their spread is kept and a switch of packs changes no loudness:

  | Kind | Keychron, mean M max | Stone cut at -6 dBFS, mean | `--gain` | Stone as shipped, mean | Peaks |
  |---|---|---|---|---|---|
  | letter | -33.89 LUFS | -31.99 | -1.9 dB | -33.89 (-32.8 to -35.0) | -7.9 dBFS |
  | space | -30.06 | -32.65 | +2.6 | -30.05 | -3.4 |
  | backspace | -33.68 | -31.82 | -1.9 | -33.72 | -7.9 |
  | paragraph | -28.13 | -24.03 | -4.1 | -28.13 | -10.1 |
  | send | -27.98 | -13.99 | -14 | -27.99 | -20.0 |

  A typing stream as sound.md §6 makes it (letters with every sixth key a space, volume 0.6) measures -35.6, -34.2 and
  -32.4 LUFS at 3, 5 and 8 keys a second, the default pack's -35.6, -34.2 and -32.3.
- **Pitched** (`pack.json`: `"pitched": ["paragraph", "send"]`): the drum has its modes at 183 and 108 Hz, the chime
  one note; they play at their recorded rate, every time the same (sound.md §4.2). The keys are unpitched and keep the
  ±3 %.
- **Measured** (as the other packs above; times from the file's start):

  | File | Length | Centroid | Energy above 5 kHz | Peak to -30 dB |
  |---|---|---|---|---|
  | letter-1 … letter-4 | 60 ms | 1.56, 1.87, 1.20, 1.89 kHz | 1.2, 4.0, 0.1, 2.9 % | 26–30 ms |
  | letter-5 … letter-8 | 63.8 ms | 1.45, 1.71, 1.13, 1.75 kHz | 0.9, 3.0, 0.0, 2.4 % | 28–32 ms |
  | space-1, space-2 | 75, 80 ms | 0.96, 0.89 kHz | 0 % | 32, 34 ms |
  | backspace-1, backspace-2 | 68.2 ms | 1.60, 1.64 kHz | 2.7, 2.2 % | 34, 28 ms |
  | paragraph-1, paragraph-2 | 200 ms | 0.19, 0.24 kHz | 0 % | 60, 166 ms |
  | send-1 | 900 ms | 0.66 kHz | 0 % | 786 ms (the fade) |

## The rain bed (`Sources/LemnaClicks/Beds/Rain/`, pass 23a)

The bed of the mindful theme, BD1 of `docs/design-panel-lemna-themes.html` (picked 2026-10-31; sound.md §1–§3 and
its Recommendations): 90 s of light rain, looped.

| Recording | Page | Made into |
|---|---|---|
| Light rain in the forest (Brazil) (#585845), felix.blume | https://freesound.org/people/felix.blume/sounds/585845/ | `rain.caf` |

### Licence: CC0 1.0 (public domain dedication)

Checked on 2026-10-31 on the page: "Creative Commons 0", linked to http://creativecommons.org/publicdomain/zero/1.0/,
with the statement quoted for the default pack. Uploaded on 2021-09-05: rain at night in a forest by a village,
recorded from a balcony with an ORTF pair (two Schoeps CCM4) on a Sound Devices MixPre-6, a 48 kHz 24-bit stereo WAV of
14:02; no credit is asked. Credit, none owed: Light rain in the forest (Brazil) by
felix.blume on Freesound.org, CC0.

### What was taken and what was done to it

- **Source file:** the HQ preview (Ogg Vorbis, 48 kHz stereo, 192 kbit/s, 842.2 s, 25,558,700 bytes), from
  `https://cdn.freesound.org/previews/585/585845_1661766-hq.ogg`. SHA-256:
  `a8dfef99c9bbf4729c921cc6ae52499f02a424f612d9313340c08990579cea5d` 585845-hq.ogg.
- **Decoded** to 48 kHz stereo float through a high-pass, the light first 5½ minutes only (sound.md §3.1):
  `-af highpass=f=80:p=2,atrim=start=30:end=333,asetpts=PTS-STARTPTS` (two-pole, 12 dB/octave, -3 dB at 80 Hz).
- **Loop points by spectral match:** `tools/loop_points.py match 585845.wav 0 210` tried 2,101 starts, 0.1 s apart, and
  ranked them by how the band spectra of the loop's last 2 s and its first 2 s as played (crossfaded) differ, RMS over
  21 bands from 100 Hz to 16 kHz. The best, taken: 186.1 s into the stretch, 0.21 dB; then 1.9, 62.1, 68.3 and 2.2 s,
  0.22–0.24 dB; the worst 2.16 dB at 42.5 s. **The loop is 3:36.1 to 5:06.1 of the recording**, its head crossfaded
  with 5:06.1 to 5:09.1.
- **Made** with ffmpeg, sample-exact (`atrim` by sample): the 3 s overhang faded out on a quarter cosine and laid over
  the head's first 3 s, faded in on a quarter sine (`afade curve=qsin`; the squares of the two gains sum to 1), then the
  rest of the 90 s: 4,320,000 frames. **Encoded** to AAC by Core Audio:
  `afconvert -f caff -d aac -b 128000 -q 127`, 1,477,949 bytes, SHA-256
  `cd502580f9851783dddb4500f754b0da0a40731b9c46aa7252b5fb31302a44c1` rain.caf. AVAudioFile reads exactly 4,320,000 frames
  from it (the CAF's packet table holds the encoder's priming and remainder), so the seam survives. CAF rather than
  m4a because an m4a carries its creation time; four runs of `build_packs.sh`, one from an empty work folder, made
  these bytes (the first run's file was 2 bytes shorter, which was not explained).
- **Measured** on the loop as Core Audio decodes it (`afconvert -f WAVE -d LEF32`), with ffmpeg's ebur128 and a scratch
  script (not kept; sound.md §6's method):
  - integrated -26.0 LUFS (`lufs` in `bed.json`), each channel alone -29.5 and -28.6; loudness range 1.1 LU, 3 s
    loudness SD 0.44 LU, no 400 ms window 6 LU over the median (the loudest 4.1 LU over); 0.19 % of the energy under
    150 Hz, 10.4 % above 5 kHz, centroid 2.06 kHz; the channels correlate at 0.22;
  - the wrap: a sample step of 0.0024 across it against 0.057 for the 99.9th percentile of all steps; 0.5 s either
    side at -33.24 and -33.32 dBFS; band spectra 2 s either side 0.65 dB apart (RMS), 1.71 dB at most (sound.md §2.2:
    within about 1 dB, as Apple's consecutive rain clips);
  - played: the player's gain, 10^((-43 - lufs) / 20) / 0.6 (`Bed.gain`), puts it at -43 LUFS over the two channels,
    -46 on each, at a `bedVolume` of 0.6. The main mixer copies the mono clicks to both channels at full level
    (measured offline, AVAudioEngine's manual rendering: a mono 0.5 at volume 0.6 comes out 0.3 on each), so the
    clicks' -34.2 LUFS at 5 keys a second as one channel are -31.2 over the two: the bed stands 12 LU under them in
    both measures, as sound.md §2.3 set it.

## The beds of pass 28 (`Sources/LemnaClicks/Beds/Ship/`, `Lab/`, `Space/`, `Synth/`)

Four beds beside the rain, FB2, FB6, FB7 and FB8 of `docs/design-panel-lemna-future-bed.html` (the user, 2026-11-02:
"FB8, FB7, FB6 (cut the low low end a bit)", then "And FB2 (cut low low end again)"; the search, the measures and the
candidates not taken are in `research_notes/Lemna future bed/candidates.md`). Lab, Space and Synth fail the steadiness
rule the rain was chosen by (sound.md §1.5: blips, swells, a chord progression); the user picked them knowing it. Each
is 90 s of one recording, looped, made by `tools/build_beds.sh`.

| Bed | Recording | Page | Made into |
|---|---|---|---|
| Ship (FB2) | inside spaceship.wav (#45347), jaava73 | https://freesound.org/people/jaava73/sounds/45347/ | `ship.caf` |
| Lab (FB6) | Sci-fi Laboratory Ambience (#212025), qubodup | https://freesound.org/people/qubodup/sounds/212025/ | `lab.caf` |
| Space (FB7) | Space Ambience.wav (#174450), Sonicfreak | https://freesound.org/people/Sonicfreak/sounds/174450/ | `space.caf` |
| Synth (FB8) | Angelic Pad Loop.wav (#242773), PhonZz | https://freesound.org/people/PhonZz/sounds/242773/ | `synth.caf` |

### Licences

Checked on 2026-11-02 on each page.

- **Ship, Space, Synth: CC0 1.0** (public domain dedication): "Creative Commons 0", linked to
  http://creativecommons.org/publicdomain/zero/1.0/, with the statement quoted for the default pack. No credit is asked
  (Sonicfreak's page: "Feel free to use this with or without giving credit to me"). Credit, none owed: inside
  spaceship.wav by jaava73, Space Ambience.wav by Sonicfreak and Angelic Pad Loop.wav by PhonZz, on Freesound.org, CC0.
- **Lab: CC BY** (attribution required). The page's licence field says "Attribution 4.0", linked to
  https://creativecommons.org/licenses/by/4.0/; the author's description still says "This sound is licensed under CC
  Attribution 3.0 License" and asks for attribution "in the form of: Sci-fi Laboratory Ambience by Iwan Gabovitch under
  CC-BY 3.0 License with sounds by wolick, swiftoid, Diboz", in plain text with links: "Sci-fi Laboratory Ambience
  http://freesound.org/people/qubodup/sounds/212025 by Iwan ‘qubodup’ Gabovitch http://freesound.org/people/qubodup
  under CC-BY 3.0 License http://creativecommons.org/licenses/by/3.0/legalcode with sounds by wolick, swiftoid, Diboz".
  It adds, as its reading of the licence: "sound boards, games and software must include a credits screen with working
  weblinks" (open item 5). **The credit line names CC BY 4.0**, the page's licence field, Freesound's record of the
  licence the sound is offered under (and the Electric pack's, so the credits keep one form), **and names 3.0 with its
  link too**, so it meets both: CC BY 4.0 §3(a) asks for the creator as they ask to be named, a link to the material,
  the licence with its link and a note of what was changed; CC BY 3.0 §4(a) and (b) the licence's URI with every copy,
  the author's name, the title, the link the author gives and, for an adaptation, what was done. It keeps the author's
  own words (the title, "Iwan ‘qubodup’ Gabovitch" as in their plain-text form, "with sounds by wolick, swiftoid,
  Diboz"). Word for word as in `Beds/Lab/bed.json` (`attribution`), which ships with the loop in the app's
  `Contents/Resources/Beds/Lab`, and in short in the site's footer:

  > Sci-fi Laboratory Ambience (https://freesound.org/people/qubodup/sounds/212025/) by Iwan ‘qubodup’ Gabovitch
  > (https://freesound.org/people/qubodup/) with sounds by wolick, swiftoid, Diboz, licensed under CC BY 4.0
  > (https://creativecommons.org/licenses/by/4.0/); the author's description gives CC BY 3.0
  > (https://creativecommons.org/licenses/by/3.0/legalcode). Changed for Lemna: 90 s of it cut and looped, its end
  > crossfaded over its head, high-pass filtered at 80 and 120 Hz, lowered in level. No warranties are given.

  The three sounds it mixes are CC0 (the description: "Sounds under CC0": wolick's "Kaiju Lab Interior Ambience
  #1.wav", swiftoid's "Cinematic Deep Rumble", Diboz's "control_room.wav", #211683).

### What was taken and what was done to it

- **Source files:** the HQ previews (Ogg Vorbis), from `https://cdn.freesound.org/previews/<id ÷ 1000>/<id>_<uploader
  id>-hq.ogg`, each in a folder of its own; two are long, and only their first 8 MiB were fetched (`curl -r
  0-8388607`), the loops lying within them. SHA-256:
  `43c4e77e877640985403d68a93ac78619c4cb7279ad131c8aadf638a409b1e63` 45347-hq.ogg (45347_359482, whole, 2,173,534 bytes;
  the original a 44.1 kHz 16-bit stereo WAV of 2:11.3, uploaded 2007-12-26, its source not named),
  `bd6280156f0771478fd31b136177b5fb6e9968883d6f7b0329f3f2d26b4ffc8d` 212025-hq.ogg (212025_71257, the first 8 MiB, 374 s
  of 10:00; Ogg Vorbis at the source too, uploaded 2013-12-28),
  `4105b1883743fcdc826dc71b988ae3fda8aadcda25c8f210e5c3a0a8433e9eb9` 174450-hq.ogg (174450_746632, whole, 3,139,751
  bytes; a 48 kHz 16-bit stereo WAV of 2:31.4, uploaded 2013-01-16, "created by blowing into a microphone while slowly
  changing pitches", then slowed down and pitched lower),
  `a1a93bfdc893d1f18c7b6c2a4a580355f38845159e7ec129db121ca37713f362` 242773-hq.ogg (242773_3946286, the first 8 MiB,
  420 s of 18:08; a 44.1 kHz 16-bit stereo WAV, uploaded 2014-07-18, "a basic chord progression with a drone note",
  F♯, 120 bpm).
- **Decoded** to 48 kHz stereo float through the rain's two-pole high-pass, `highpass=f=80:p=2` (12 dB/octave, -3 dB
  at 80 Hz). **The low cut**, Ship and Lab only: a second two-pole high-pass after it, `highpass=f=120:p=2`
  (Butterworth, -3 dB at 120 Hz; together -24 dB/octave far below). Lab's low end is a 57 Hz rumble (swiftoid's),
  62.5 % of its energy after the first filter; Ship's lowest content is its hum's two lowest partials at 100 and 117 Hz,
  under its strongest at 147 Hz, nothing under 80 Hz to speak of (0.3 %). 120 Hz rather than a lower corner: at 100 Hz
  Ship's share under 150 Hz would go only from 55 to 48 % and its laptop loss (below) from 3.2 to 2.6 dB, next to
  nothing; at 120 Hz Lab's rumble falls 13 dB more and Ship's 100 Hz partial 5 dB, while the hum's body, Lab's 120–200
  Hz and Ship's 147 Hz and 300–500 Hz, loses at most 3 dB at 120 Hz and 1.6 dB at 147 Hz before the levelling, which
  gives it back (it puts the rest 1.2 dB higher than on the panel in Ship, 3.5 dB in Lab). Space and Synth: no low
  cut.
- **Loop points by spectral match,** as the rain's (`tools/loop_points.py match <id>.wav 0 <last>` on the decoded
  file; for Ship and Lab after the low cut, which left their first starts first):

  | Bed | Starts tried | Taken (the first) | Next four | Worst | The loop in the recording |
  |---|---|---|---|---|---|
  | Ship | 381 (0–38 s) | 5.3 s, 0.10 dB | 14.1, 16.0, 16.3, 16.9 s; 0.11–0.14 dB | 1.71 dB at 36.2 s | 0:05.3–1:35.3 |
  | Lab | 2,801 (0–280 s) | 48.7 s, 0.32 dB | 279.4, 279.8, 279.3, 242.6 s; 0.44–0.51 dB | 13.38 dB at 218.3 s | 0:48.7–2:18.7 |
  | Space | 581 (0–58 s) | 4.3 s, 0.47 dB | 4.4, 4.1, 4.5, 4.6 s; 0.50–0.57 dB | 19.14 dB at 58.0 s | 0:04.3–1:34.3 |
  | Synth | 3,261 (0–326 s) | 90.8 s, 0.25 dB | 90.7, 90.5, 90.6, 322.6 s; 0.26–0.30 dB | 5.83 dB at 183.9 s | 1:30.8–3:00.8 |

  Each loop's head crossfaded with the 3 s after its end, as the rain's (quarter sines, sample-exact): 4,320,000 frames.
- **Levelled** to -26 LUFS over both channels (the rain's loudness; or lower if the sample peak passed -1 dBFS, which
  none did), with ffmpeg's `volume`: Ship -0.1 dB (it measured -25.9 LUFS after the low cut; -24.7 without it), Lab -3.5
  dB (-22.5; -19.0 without), Space -2.3 dB (-23.7), Synth -7.8 dB (-18.2). **Encoded** to AAC by Core Audio as the
  rain, `afconvert -f caff -d aac -b 128000 -q 127`:

  | File | Bytes | SHA-256 | `lufs` as decoded | Sample peak |
  |---|---|---|---|---|
  | `ship.caf` | 1,251,047 | `caefae306d879181037d1e1e527d8b149ee262f5c05b05f2554618d914870798` | -26.0 | -12.0 dBFS |
  | `lab.caf` | 1,473,969 | `fd0c140cb600fc35496f3f94e825492073fe73bc764916e94c4b2ae7c1dab39e` | -26.0 | -13.8 dBFS |
  | `space.caf` | 1,433,729 | `bff3f0ebd356b8a9a55f0abeaff14ce709d208186703bd74d75e52cf056e04c3` | -26.0 | -13.0 dBFS |
  | `synth.caf` | 1,446,331 | `5c82cc1d769bee000eddfdc3b6a18f0dd0a846e57f5674b3ca33107aa741d1d2` | -26.1 | -13.0 dBFS |

  Space and Synth are the panel's FB7 and FB8 byte for byte; two runs of `build_beds.sh`, the second from an empty work
  folder, made these bytes. AVAudioFile reads exactly 4,320,000 frames from each (the tests).
- **Measured** on each loop as Core Audio decodes it, with the code bed's `analyze.py` and the future bed's `extra.py`
  (`research_notes/Lemna future bed/candidates.md` §3 and §9, its columns; ffmpeg's ebur128 for the range):

  | Bed | 3 s SD LU | Range LU | Under 150 Hz | Laptop loss | Onsets/min | Tonal | Clicks over it: broadband / 1–4 kHz / body |
  |---|---|---|---|---|---|---|---|
  | Rain | 0.49 | 1.1 | 0.2 % | 0.0 dB | 3 | 1 | 21.3 / 20.1 / 6.0 dB |
  | Ship | 0.35 | 1.0 | 40.5 % (52.4 without the cut) | 2.2 dB (3.2) | 0 | 2 | 20.8 / 47.9 / 6.8 dB |
  | Lab | 0.27 | 1.0 | 38.1 % (80.0) | 4.7 dB (7.8) | 133 | 14 | 19.6 / 36.1 / 6.6 dB |
  | Space | 1.73 | 4.9 | 42.8 % | 3.6 dB | 7 | 3 | 18.9 / 40.6 / 3.3 dB |
  | Synth | 1.02 | 3.0 | 5.5 % | 0.8 dB | 0 | 27 | 17.8 / 28.0 / -0.8 dB |

  The laptop loss is the loudness a 4th-order 200 Hz high-pass takes away, a stand-in for a laptop's speakers. Lab's
  57 Hz rumble is now 11.2 % of its energy (62.5 % without the cut), 2.3 dB under its strongest hum partial (9.6 dB
  over it); as the levelling brought the rest up by 3.5 dB, its blips (Diboz's, 133 a minute) stand 3.5 dB higher
  against the clicks than on the panel (above 5 kHz 3.1 % of its energy, 0.8 % before). Ship's 100 and 117 Hz partials
  are 8.5 and 4.5 dB under its 147 Hz one (5.2 and 2.9 dB before). Synth's pad sits on the clicks' body (200 Hz–1 kHz,
  -0.8 dB) and its chords change every few bars; the loop is 45 of the progression's bars, so it wraps from one place
  in it to another (the spectra 0.25 dB apart).
- **Played** as the rain: `Bed.gain` puts each at -43 LUFS over the two channels at a `bedVolume` of 0.6, 12 LU under
  the clicks.

## Open items

1. Swap in the lossless originals of all four packs (a Freesound login downloads them) and rerun the commands
   above.
2. Typewriter packs: done on 2026-10-28 (Typewriter, Electric, above). The earlier finding that no permissively
   licensed typewriter recording exists was wrong (`sounds.md` §3.1).
3. Distinct takes would replace the pitched copies: backspace and second takes of space and Return in the default
   pack; Return and the letters in the Soft pack (three presses), Enter and Delete there; Return in the Electric pack.
   No backspace recording of either typewriter exists.
4. The Soft pack's Enter and Delete come from another keyboard (a FUJITSU membrane board) than its letters and space
   bar (a MacBook Air): whether they belong together is for the ear.
5. Before Lemna goes to others (DESIGN.md X1): the Electric pack's and the Lab bed's credit lines also in the app's
   About panel or a credits file in the bundle, where a user sees it; the Lab's author asks software for "a credits
   screen with working weblinks" (pass 28). Addressed in the app, pass 44, not yet seen live: About Lemna (the
   menu-bar item's menu) shows `app/Credits.html` in the standard About panel, both lines verbatim with their URLs as
   links, beside every other pack's, bed's and the font's credit; `CreditsTests` checks the file against this one and
   the json.
6. Nothing in the three new packs was listened to; every choice above (the filters, the spans, the levels) is by
   measurement. A pack that sounds wrong is fixed by changing a command above and running it again.
7. Stone and the rain (pass 23a) were not listened to either: the space's rates (0.8, 0.75) and level, the Return's
   two strengths, the chime's 900 ms and the bed's -43 LUFS (sound.md: "set every level by ear against the clicks
   on the built-in speakers and on headphones") are for the ear. The originals of worthahep88's takes and of
   585845 (a login) would replace the previews.
8. The beds of pass 28 were not listened to in the app either (the user heard the panel's previews, the same loops
   but for Ship's and Lab's low cut): the 120 Hz corner, Lab's blips 3.5 dB nearer the clicks after the levelling, and
   the four at -43 LUFS against the clicks are for the ear. The originals (a login) of the four would replace the
   previews.
