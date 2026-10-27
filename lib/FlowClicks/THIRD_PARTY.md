# Third-party material in FlowClicks

## The default sound pack (`Sources/FlowClicks/DefaultPack/`)

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

### Open items

1. Swap in the lossless originals (a Freesound login downloads them) and rerun the commands above.
2. A typewriter pack: no permissively licensed typewriter recording was found (DESIGN.md, Open 1); record one
   or buy one with a redistribution licence.
3. Distinct takes for backspace and second takes of space and Return would replace the pitched copies.
