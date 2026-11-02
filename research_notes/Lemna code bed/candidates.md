# Code bed candidates: sources, how they were made, measurements, as of 2026-11-02

Read `film.md` first (what the films' code sound is made of, and why none of it may be used). The panel is
`docs/design-panel-lemna-code-bed.html`; its previews are in `docs/design-panel-lemna-code-bed_files/`. The `.caf`
loops for the app were left in the scratch folder of the session that made them and are rebuilt by
`tools/build_candidates.sh`; only the one picked goes into `lib/LemnaClicks/Sources/LemnaClicks/Beds/Code/`.

Tags as in `film.md`. **Nothing was listened to**: every judgement here is a measurement or an inference, and the ear
decides on the panel.

## Takeaway

- **Recommended: CB3, synthesised.** Built from the film's components (clean tone grains, rising drips, a short
  hollow room, a faint electrical hum) and as steady as the rain bed by every measure (3 s loudness SD 0.50 LU against
  the rain's 0.49, no bursts, no onsets, no period); the clicks stand 23.0 dB over it broadband and 20.3 dB in 1–4 kHz,
  as much as over the rain or more. Periodic by construction over exactly 90 s, no licence question, tunable later.
- **Fallback: CB4,** the rain bed with CB3's grains over it: the steadiest of all (0.35 LU), the film's own recipe of
  synthetic sound over water, but close to the Rain bed it would sit beside.
- **CB1** (MetaSynth, the film's tool, CC BY 3.0) measures steady but is a narrow mono insect-like trill with a faint
  1.5 Hz swell and a source voice of unknown origin; **CB2** (CC0, granular "rain and sand on a metal plate") is the
  least steady (1.13 LU, loudness range 3.3 LU) and swells in its low mids.
- Freesound has no CC0 or CC BY "digital rain" that meets the rain's steadiness and reads as code: of 21 measured,
  the on-topic ones are bursty, clicky, pulsed or very bright (§3).

## 1. The candidates

Freesound pages read on 2026-11-02 without a login; licences as each page showed them that day. HQ previews from
`https://cdn.freesound.org/previews/<id ÷ 1000>/<id>_<uploader id>-hq.ogg` (Ogg Vorbis), as `sound.md` §3 did; the
originals need a login. Each preview went into its own download folder; only ffmpeg read it.

| ID | Source | Licence | Loop | Made |
|---|---|---|---|---|
| **CB1** | [41497](https://freesound.org/people/Fishdog/sounds/41497/) "metasynth bugnite.aif" by **Fishdog** (uploader 414267), uploaded 2007-09-29; AIFF 44.1 kHz stereo, 1:20.4. The author: made in MetaSynth from a recorded voice ("Welcome to…") turned into "a swampy backdrop of synthesized…birds? frogs? bugs?" | **CC BY 3.0** (`creativecommons.org/licenses/by/3.0/`). Credit: *"metasynth bugnite.aif" by Fishdog (https://freesound.org/s/41497/), CC BY 3.0* | 70 s from 3.6 s; `loop_points.py` wrap 0.19 dB | HQ preview (SHA-256 `050e9bfddf6bbb606987e238b5cd642b985fb206d8d9e3890c52ef5ec76a84ef`), 80 Hz high-pass, 48 kHz, the next 3 s laid over the head on quarter sines, −9.6 dB to −26 LUFS |
| **CB2** | [838983](https://freesound.org/people/bassimat/sounds/838983/) "Sand and Rain Texture from Granular Synthesis" by **bassimat** (uploader 15636277), uploaded 2025-12-20; WAV 48 kHz 32-bit stereo, 1:16.8. The author: "rain and sand hitting a metallic plate", made by recording vinyl crackles, adding modulated noise and bit-rate reduction, reverb and delay | **CC0 1.0** | 63 s from 1.7 s; wrap 0.41 dB (70 s and 66 s matched no better than 1.3 dB) | HQ preview (SHA-256 `23a7392f38bb38c3180829c41cf34783130b37a1e150aa5dc7dac4f9b3b732d0`), as CB1, −6.7 dB |
| **CB3** | Synthesised for Lemna, `tools/synth_code.py` (§2) | the project's own (Apache-2.0); no third-party material | 90 s, periodic by construction | numpy/scipy, seed 1999 |
| **CB4** | The Rain bed's loop (felix.blume 585845, CC0; `lib/LemnaClicks/THIRD_PARTY.md`) decoded from `rain.caf`, with CB3's glass and fizz layers over it at the same loudness | CC0 + own | 90 s, both layers on the same 90 s circle | `synth_code.py --layers glass,fizz --rain` |
| CB3 sparse | CB3's grains at 6 a second, 10–25 ms, no fizz: the sketch's "sparse ticks", for comparison only | own | 90 s | `synth_code.py --rate 6 --tau-lo 10 --tau-hi 25 --layers glass,hum,hiss` |

Every loop was scaled to −26 LUFS over both channels (the rain bed's `lufs`; `Bed.level` plays every bed at −43),
coded to AAC 128 kbit/s in CAF with `afconvert -f caff -d aac -b 128000 -q 127`, and measured again as Core Audio
decodes it: CB1 −26.0, CB2 −26.3, CB3 −26.1, CB4 −26.1 LUFS (the `lufs` for `bed.json`). Sizes: CB1 0.87 MB (70 s),
CB2 1.04 MB (63 s), CB3 1.48 MB, CB4 1.47 MB (90 s). Previews: the same loops as m4a, AAC 128 kbit/s.

## 2. CB3's synthesis

`tools/synth_code.py OUT.wav --glass-lo 2200 --glass-hi 6500 --glass-tilt -3 --rate 60 --tau-lo 2 --tau-hi 6
--fizz-lo 4500 --fizz-db -15 --hiss-db -24` (the rest at their defaults: `--loop 90 --seed 1999 --hum-db -17
--target -26`). Every layer is built on a circle of 4,320,000 frames, so the loop has no seam to hide.

| Layer | From the film (`film.md` §2) | Parameters | Level |
|---|---|---|---|
| glass | MetaSynth's pixels as oscillators; drips | 60 sine grains a second (Poisson; 5,435 in the loop), pitch log-uniform 2.2–6.5 kHz, −3 dB an octave up from 2.2 kHz, each rising 5–25 % over its life (a drop's chirp), decaying in 2–6 ms (e-folding, 6τ long, 0.5 ms attack), level log-normal sd 4 dB, panned at random within ±0.8 (equal power) | reference |
| room | the barrel | noise impulse response, RT60 0.7 s, 1.5 s long, 0.8–9 kHz, 12 ms pre-delay, decorrelated per channel, circular convolution; glass 55 % wet, fizz 40 % | — |
| fizz | many pixels at once: a fused trickle | 250 noise ticks a second per channel, 1.5 ms (0.4 ms decay), 4.5–14 kHz | −15 dB |
| hum | electricity | a 55 Hz series, harmonics 1–10 weighted to 110–330 Hz, with narrow noise (1.5 Hz wide) round each; every frequency a whole number of cycles in 90 s | −17 dB |
| hiss | a floor between the grains | noise 3–12 kHz, −3 dB an octave | −24 dB |

Then an 80 Hz high-pass (zero phase, circular) and the gain to −26 LUFS; sample peak −11.7 dBFS. Tunable later
without a new source: the grain rate (density against the changing-state risk), the pitch range (brightness against
masking), the hum (off with `--layers glass,fizz,hiss`), the seed.

## 3. Measurements [M]

Method as `sound.md` §6, with `tools/analyze.py`: each loop as Core Audio decodes the CAF. I: integrated loudness over
both channels. S-SD: SD of the 3 s short-term loudness every 0.1 s. Burst: share of 400 ms windows 6 LU over their
median. LF, HF: energy share under 150 Hz, over 5 kHz. On/min: onsets a minute above 1 kHz (`sound.md` §6's rule).
Pulse: the highest autocorrelation of the 10 ms envelope above 1 kHz at lags 0.15–4 s (0 none, 1 a strict period).
Mod: the 1–16 Hz fluctuation of four octave bands' envelopes over their mean, the largest (fluctuation strength peaks
near 4 Hz; Schlittmeier et al. 2012). Tonal: spectrum peaks of 12 dB prominence, 150 Hz–8 kHz. Corr: L/R correlation.
Margin: the loudest 10 % of 10 ms frames of a 60 s Keychron typing stream (5 keys a second, gain 0.6; −34.3 LUFS,
`sound.md` §2.3's −34.2) over one channel of the bed played at −43 LUFS over both, at the same instants, median dB.
Wrap: the step from the last frame to the first over the 99.9th percentile of all steps (under 1: no click).

| Bed | S-SD LU | LRA LU | Burst % | LF % | HF % | Centroid Hz | 1–4 kHz % | On/min | Pulse (lag) | Mod | Tonal | Corr | Margin dB (1–4 kHz) | Wrap |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Rain bed (today) | 0.49 | 1.1 | 0 | 0.2 | 10.6 | 2,076 | 42.5 | 3 | 0.05 (2.6 s) | 0.33 | 1 | 0.22 | 21.3 (20.1) | 0.03 |
| CB1 MetaSynth | 0.34 | 1.0 | 0 | 0.0 | 20.3 | 3,534 | 76.9 | 0 | 0.20 (0.68 s) | 0.60 | 3 | 1.00 | 22.1 (19.1) | 0.37 |
| CB2 sand and rain | 1.13 | 3.3 | 0 | 3.9 | 31.5 | 3,819 | 17.6 | 15 | 0.14 (0.16 s) | 0.57 | 11 | 0.12 | 23.1 (24.8) | 0.10 |
| **CB3 synth** | 0.50 | 1.6 | 0 | 0.1 | 15.6 | 3,580 | 64.5 | 0 | 0.04 (1.7 s) | 0.54 | 20 | 0.14 | 23.0 (20.3) | 0.34 |
| CB4 rain + synth | 0.35 | 1.0 | 0 | 0.1 | 13.1 | 2,744 | 51.7 | 1 | 0.04 (2.7 s) | 0.33 | 1 | 0.20 | 21.8 (20.2) | 0.40 |
| CB3 sparse | 1.83 | 5.8 | 4.6 | 0.1 | 10.3 | 3,339 | 69.0 | 190 | 0.17 (0.15 s) | 1.32 | 32 | 0.17 | 28.2 (27.3) | 0.06 |

Reading it:
- **CB1's** swell is visible in a 6 s spectrogram: brighter patches in 2–3.5 kHz every 0.6–0.7 s, the 0.20 at 0.68 s.
  Faint, but a regular lilt is what an ear can lock onto. It is mono (corr 1.00), so it sits in the middle of the head.
- **CB2** dips and swells in 200–800 Hz over seconds (a near-gap at about 5 s in its first 20 s): S-SD and LRA twice
  the rain's, and with a 63 s loop a swell comes back every minute.
- **CB3's** 20 tonal peaks are the hum's steady harmonics, continuous pitch and not a sequence (`sound.md` §1.4); its
  spectrum has a gap at 0.7–2 kHz, where the clicks' body is.
- **CB3 sparse** fails as predicted: 190 separately heard grains a minute, bursts 4.6 %, three times the fluctuation.

## 4. Measured and not taken

All from the same searches (CC0 and CC BY, 40 s or longer: "matrix code", "matrix ambience", "matrix rain", "digital
rain", "code rain", "data stream", "data rain", "data ambience", "computer data", "glitch trickle", "digital drips",
"crystalline texture", "digital water", "granular rain", "glass rain", "ice crystals texture", "shimmer texture",
"tinkling", "crystal glitch", "electronic rain", "glitch ambience", "sci-fi computer ambience", "cyberspace ambience",
"server room", "data center ambience", "metasynth"). None of the results titled after the film was the film's audio.

| ID | Title, author | Licence | Why not |
|---|---|---|---|
| [869343](https://freesound.org/people/bassimat/sounds/869343/) | Irregular Rain of Frozen Glitches and Crystalline Digital Fragments, bassimat | CC0 | The most on-topic title, but sharp broadband clicks at 357 a minute with a pulse (0.30 at 0.37 s) and mod 1.38: a bed of clicks under the key clicks; centroid 7.3 kHz |
| [869782](https://freesound.org/people/bassimat/sounds/869782/) | Electromagnetic Glitches, Scratches and Delicate Electrical Buzzes, bassimat | CC0 | "Electrical" and steady (0.84 LU), but 72 % of its energy above 5 kHz (centroid 9.4 kHz): a hiss with bursts every half second; 66 s |
| [865133](https://freesound.org/people/bassimat/sounds/865133/) | Ice Rain Breathing with High-Frequency Granular Glitches, bassimat | CC0 | "Breathing" swells (S-SD 1.90, bursts 1.8 %), centroid 1.6 kHz on the clicks; 62 s; the rain's source not named |
| [332453](https://freesound.org/people/cabled_mess/sounds/332453/) | Synthesized rain, frying, …, cabled_mess (Pure Data) | CC0 | 83 % above 5 kHz (centroid 11.8 kHz), "frying"; narrow (corr 0.92) |
| [368685](https://freesound.org/people/cabled_mess/sounds/368685/) | Alien Waters [loop], cabled_mess | CC0 | A tonal pad (72 tonal peaks), mono, centroid 0.6 kHz |
| [870568](https://freesound.org/people/bassimat/sounds/870568/) | Low Frequency Resonating Drone with Oscillating Granular Rain, bassimat | CC0 | 74 % under 150 Hz: gone on laptop speakers |
| [772279](https://freesound.org/people/newlocknew/sounds/772279/) | Atonal Crystal Chime Texture 1, newlocknew | CC0 | S-SD 15 LU: swells and transitions; chimes |
| [844133](https://freesound.org/people/Alex_hears_things/sounds/844133/) | Echo drops, Alex_hears_things | CC0 | Bursts 25 %, 43 % under 150 Hz |
| [866969](https://freesound.org/people/bassimat/sounds/866969/) | Microscopic Irregular Organic Glitches, Clicks and Pulses, bassimat | CC0 | Pulse 0.49, mod 2.04, 372 onsets a minute |
| [789056](https://freesound.org/people/Alex_hears_things/sounds/789056/) | Digital Data Stream, Alex_hears_things | CC0 | 42 s, S-SD 1.86, a gesture rather than a bed |
| [615924](https://freesound.org/people/Raining-0n-Satrn/sounds/615924/) | Glitchy Atmospheric Rain | CC0 | "Rhythmically interesting clicks", pulse 0.15, mono, 48 s |
| [209408](https://freesound.org/people/deefinmoosik/sounds/209408/), [315944](https://freesound.org/people/Chris1426/sounds/315944/) | Blackhole rain; Datagrave-Cryogen01 | CC0 | S-SD 4.8 and 2.9 LU |
| [353159](https://freesound.org/people/Kinoton/sounds/353159/) | Room Tone, Sci Fi, Large Hall, Kinoton | CC0 | A rumble (40 % under 150 Hz, centroid 190 Hz); a possible low layer, not needed |
| [857474](https://freesound.org/people/ayamahambho/sounds/857474/) | digital bubbles, ayamahambho | CC BY 4.0 | Its base pitch steps every few seconds (sample and hold): segmented pitch change; mod 1.31 |
| [636238](https://freesound.org/people/el-bee/sounds/636238/), [15896](https://freesound.org/people/milo/sounds/15896/) | Glass shard tinkle texture; metal rain | CC BY | 99.7 % above 5 kHz; bursts 5 % with a pulse |
| [212025](https://freesound.org/people/qubodup/sounds/212025/) | Sci-fi Laboratory Ambience, qubodup | CC BY 3.0 | A lab drone with no glass or water; downloaded, not needed |

Provenance, for any later pick from bassimat (a prolific account uploading since 2025): several of its textures name
third-party sources (a commercial chime pack, a commercial cracks library, another synth's output), where a CC0 on the
derivative may not hold. CB2 names only its own recordings and noise; 869343 and 869782 name the author's own CC0 EMF
recordings (845874, pack 44617).

## 5. Not verified

- How any of it sounds, on laptop speakers or headphones; whether CB3's grains read as glass or as plastic, and its hum
  as electricity or as a fault; CB1's swell by ear.
- CB1's source voice: Fishdog does not say whose it is; transformed beyond recognition, but a derivative all the same.
- The masking margin with the other packs (only Keychron measured); the bed over 10–20 minutes of writing.
- That Bluetooth, other audio and power behave as for the rain (`sound.md` §2.5–2.7): nothing bed-specific there.
- Not bit-identical: `afconvert`'s AAC differs from run to run below −50 dBFS (two builds compared); every measure above was the same to the decimal on the rebuild.
