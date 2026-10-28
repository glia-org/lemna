# Third-party material in LemnaClicks

## The default sound pack (`Sources/LemnaClicks/DefaultPack/`)

All twelve clicks are cut from three recordings of one mechanical keyboard, a Keychron K10 with linear
switches, by the Freesound user **Sadiquecat** (recorded and uploaded on 2025-02-22, in the pack
"Computer sounds", https://freesound.org/people/Sadiquecat/packs/38565/).

| Recording | Page | Cut into |
|---|---|---|
| Keychron k10 A to + individual keys (#789628) | https://freesound.org/people/Sadiquecat/sounds/789628/ | `letter-1` … `letter-6`, `backspace-1`, `backspace-2` |
| Keychron k10 space_bar (#789630) | https://freesound.org/people/Sadiquecat/sounds/789630/ | `space-1`, `space-2` |
| Keychron k10 Enter (#789629) | https://freesound.org/people/Sadiquecat/sounds/789629/ | `paragraph-1`, `paragraph-2` |

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

### Licence: CC0 1.0 (public domain dedication)

Checked on 2026-10-28 on each of the pack's nine pages: "Creative Commons 0", linked to
http://creativecommons.org/publicdomain/zero/1.0/. The uploader's description adds, beside the licence:

> Credit/Attribution is not mandatory. However, if you choose to do so, you may provide the URL of this sound or
> mention my name (along with the title of the sound) in your description, video, game or project.

and asks that the sounds not be used in "prohibited (obscene, misleading, political, propaganda and/or hateful)
content" nor "on AI apps, models or anything of the sorts". Lemna is none of these: it holds no AI model and trains
none.

Credit, as the uploader suggests: Silver Typewriter (Keystroke), (Space Bar) and (Carriage Return Lever 3) by
moodyfingers on Freesound.org, CC0.

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
| FUJITSU Computers Keyboard - Enter key Press Mono (#799116) | https://freesound.org/people/Sadiquecat/sounds/799116/ | `paragraph-1`, `paragraph-2` |
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
| typewriter_electric_return.wav (#319945) | https://freesound.org/people/magedu/sounds/319945/ | `paragraph-1`, `paragraph-2` |

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
> sounds, high-pass filtered at 150 Hz, peak-normalised, some slowed and lowered in level. No warranties are given.

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
5. Before Lemna goes to others (DESIGN.md X1): the Electric pack's credit line also in the app's About panel or a
   credits file in the bundle, where a user sees it.
6. Nothing in the three new packs was listened to; every choice above (the filters, the spans, the levels) is by
   measurement. A pack that sounds wrong is fixed by changing a command above and running it again.
