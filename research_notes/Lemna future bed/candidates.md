# Future bed candidates: sources, how they were made, measurements, as of 2026-11-02

Scope: a second bed beside the Rain bed that fits the Code ambience, after the films' code sound was turned down (the
user, 2026-11-02, having heard `docs/design-panel-lemna-code-bed.html`: "Do not apply the new sounds, I don't like
them."; then: "To have an alternative for the matrix ambient sound, maybe look for cool programming/future vibe sounds
that work as background sounds and that are freely available and that we could add based on their license. Show
popular ones when you are unsure."). So: no tone grains, no MetaSynth-like texture, nothing like that round; recorded
or designed ambiences of machines, ships and space, under a licence that allows bundling them in a distributed app.

The panel is `docs/design-panel-lemna-future-bed.html`; its previews are in `docs/design-panel-lemna-future-bed_files/`.
The `.caf` loops for the app were left in the scratch folder of the session that made them and are rebuilt by
`tools/build_candidates.sh`; only the one picked goes into `lib/LemnaClicks/Sources/LemnaClicks/Beds/<Name>/`.
Tags as in `research_notes/Lemna themes/sound.md` (cited as *sound*): **[P]** practice or a page's own text, **[M]** my
measurement, **[I]** inference. **Nothing was listened to**: every judgement here is a measurement or an inference,
and the ear decides on the panel.

**Picked 2026-11-02:** FB8, FB7, FB6 and FB2, built in pass 28 as the Synth, Space, Lab and Ship beds, FB6 and FB2
with a low cut (§9).

## Takeaway

- **Recommended: FB2, a spaceship cabin** (jaava73, Freesound 45347, CC0, 3.7K downloads, 4.3 from 71 ratings): a dark,
  even hull hum, as steady as the rain (3 s loudness SD 0.36 LU against 0.49, loudness range 1.0 LU, no onsets, no
  period), with nothing above 1 kHz, so the clicks stand clearer over it than over the rain in every band: 20.2 dB
  broadband, 48.9 dB in 1–4 kHz, 7.6 dB in their body at 200 Hz–1 kHz (rain 21.3, 20.1, 6.0). Popular, CC0, no credit.
- **Second: FB3, a sci-fi hall** (Kinoton 353159, CC0, 7.0K downloads, 4.7 from 103 ratings): soft ventilation over a
  hollow rumble, very wide; steady by the rule but at its edge (0.94 LU, range 2.3 LU, a slow wander in 150–500 Hz).
- **FB1, a real server room** (KVV_Audio 715475, CC0) is the steadiest of all (0.17 LU) and the most "programming",
  but its fan noise sits on the clicks' body (0 dB margin in 200 Hz–1 kHz against the rain's 6): the clicks would keep
  their tick and lose their thock. Few downloads (161).
- **Popular, and failing the steadiness rule** (on the panel because the user asked to hear popular ones): FB6, the most
  downloaded sci-fi lab (9.7K), carries 132 blips a minute; FB7, the most downloaded CC0 space ambience (11.8K), swells
  (1.73 LU, range 4.9 LU); FB8, a popular CC0 pad (6.5K, 214 ratings), is a chord progression.
- **The genre is dark.** Ship, hall and drone ambiences keep 40–80 % of their energy under 150 Hz, where the rain keeps
  0.2 %. On laptop speakers, which give little under 150–200 Hz, they lose 3–8 dB of loudness (a 200 Hz high-pass as a
  stand-in) and sound thinner than in headphones; the server room and the pad lose about 1 dB, the rain nothing.
- **Pixabay, freepd and archive.org gave nothing usable** (§1.2); OpenGameArt's popular "space" entries are music.

## 1. Where it was looked for

### 1.1 Freesound

Searches read on 2026-11-02 without a login, licence filter `license:("Creative Commons 0" OR "Attribution")` (so no
NonCommercial), duration 60 s or more, sorted by **Downloads (most first)**, two pages each (30 results), parsed with
`tools/fs_search2.py` (downloads, average rating and number of ratings from the result page). Queries: server room, data
center, server rack, computer room, mainframe, computer fan, computer hum, hard drive, pc ambience, spaceship ambience,
spaceship interior, spaceship bridge, space station, starship, sci-fi ambience, sci fi room tone, space drone, space
ambience, deep space, dark ambient drone, cyberpunk, cyberpunk city, futuristic city, city rain night, retro computer,
old computer, terminal room, laboratory ambience, reactor hum, engine room, ambient pad, drone pad, synth drone,
electronic ambience, hacker, futuristic ambience; then (page 1) spaceship hum, sci-fi hum, cyberpunk ambience, cyberpunk
rain, neon rain, computer lab, spaceship engine loop, space station ambience, hum loop, air conditioning hum, ship
interior hum, electrical hum, drone loop, space hum, sci-fi drone, starship hum, ventilation hum, laptop fan, computer
ambience, ambient drone; and sorted by **Rating (highest first)** for spaceship ambience, server room, sci-fi ambience,
space drone, spaceship interior, cyberpunk. 43 sounds were fetched and measured (§3, §4), with one OpenGameArt track (§1.2).

"Popular" below is the page's own count on 2026-11-02: downloads (Freesound rounds to 0.1K above 1,000), average rating
of 5 and the number of ratings. In these searches the most downloaded ambiences have 3.5K–27K downloads; an ambience
with a few hundred is ordinary.

What the searches turned up, as a whole [M]: the most downloaded "space" and "drone" sounds are designed atmospheres that
swell (blown microphones slowed down, evolving drones, a ship passing), or music; the steady ones are hums and room
tones. "Hacker", "terminal room" and "retro computer" find music, typing (which would sit on the clicks) or a computer
booting, nothing steady.

### 1.2 Other sites

- **Pixabay** (sound effects): every page, the licence included, answered 403 to scripted requests (Cloudflare); the
  licence was read through a fetch tool on 2026-11-02 (terms dated 20 October 2026). Section 5: "You cannot sell or
  distribute the Content (either in digital or physical form) on a Standalone basis", standalone being "where no
  creative effort has been applied to the Content and it remains in substantially the same form", which "includes using
  content in its original form, or only applying filters, color changes, resizing, or cropping"; section 8 forbids
  "bulk, large-scale or systematic copying". [I] A bed is a cropped, levelled loop of one sound, shipped as a file in the
  app's bundle, where anyone can copy it out: close to "substantially the same form". *sound* §3.4 reached the same
  verdict for the rain. Not used; nothing was downloaded.
- **OpenGameArt**: searched with Sound Effect and Music, licences CC0, CC-BY 3.0 and 4.0, sorted by favourites
  (`tools/oga_page.py` reads favourites and per-file downloads). The popular entries are music: "Background space track"
  by yd (CC0, 121 favourites, 8,239 downloads), measured as an example: an LMMS track with a pulse (0.43) and 54 tonal
  peaks; "Space ambient" by Osmic (CC-BY 3.0, 39 favourites, 2,231 downloads), "a space ambient tune @ 10 beat per
  minute"; "High Tech Lab" by remaxim (74 favourites), "electronic music, mostly matching action games". The ambience
  entries ("Sci-fi ambience SFX", "Scifi City – Ambient Loop", "Background Rumble Noise") have 7–12 favourites and are
  15–20 s long.
- **freepd.com**: closed ("FreePD.com - Site Closed … 2008-2025").
- **archive.org**: the advanced search with a licence filter answered "Invalid or no response from Elasticsearch"; without
  it, "spaceship ambience" found three items with no licence field, one of them a re-upload of a Freesound/Pixabay
  sound. Items carry the uploader's own licence claim; not pursued.

## 2. The candidates

HQ previews from `https://cdn.freesound.org/previews/<id ÷ 1000>/<id>_<uploader id>-hq.ogg` (Ogg Vorbis), as *sound* §3
did; the originals need a login. Each preview went into its own download folder; only ffmpeg read it. Where the preview
is long, only its first 8 MiB were fetched (`curl -r 0-8388607`), marked "first 8 MiB". Licences as each page's licence
field showed it on 2026-11-02.

| ID | Category | Source | Licence | Popular (page, 2026-11-02) | Loop | Preview, SHA-256 |
|---|---|---|---|---|---|---|
| **FB1** | server room | [715475](https://freesound.org/people/KVV_Audio/sounds/715475/) "AMBTech_Server Room Noise 01_KVV_FREE" by **KVV_Audio** (12846320), 2023-12-14; WAV 96/24 stereo, 1:42.5. Page: "recorded in a small server room. Recorded operation of 2 server stacks", Zoom, XY | **CC0** | 161 downloads, too few ratings to show | 90 s from 6.2 s; wrap matched to 0.09 dB | full, 2,341,293 B, `4fb697f51936d5cacb0f81502be069f979204141ce6cea2682ffeb6790fe172f` |
| **FB2** | spaceship cabin | [45347](https://freesound.org/people/jaava73/sounds/45347/) "inside spaceship.wav" by **jaava73** (359482), 2007-12-26; WAV 44.1/16 stereo, 2:11.3. Page: "sound inside spaceship? we all have been there. At least in our dreams.."; no source named | **CC0** | **3.7K downloads, 4.3 (71 ratings)** | 90 s from 5.3 s; 0.11 dB | full, 2,173,534 B, `43c4e77e877640985403d68a93ac78619c4cb7279ad131c8aadf638a409b1e63` |
| **FB3** | sci-fi hall, reactor room | [353159](https://freesound.org/people/Kinoton/sounds/353159/) "Room Tone, Sci Fi, Large Hall" by **Kinoton** (2247456), 2016-08-31; WAV 48/24 stereo, 3:00.0. Page: "Soft Ventilation, Hollow Rumble, General Drone, Possible applications: Space Ship, Server Room, Military Lab, Reactor Room" | **CC0** | **7.0K downloads, 4.7 (103)** | 90 s from 28.9 s; 0.17 dB | full, 3,566,371 B, `2331e015bbedc710586a4a2b4da830775f822003afb8fd6227006571805543d1` |
| **FB4** | station drone | [686237](https://freesound.org/people/db3005/sounds/686237/) "Space Station Drone" by **db3005** (9621730), 2023-05-06; WAV 48/32 stereo, 2:00.0. Page: "the constant hum and buzz of the space station's machinery and equipment" | **CC0** | 844 downloads, 5.0 (32) | 90 s from 20.3 s; 0.42 dB | full, 2,133,464 B, `732db3b035f11dbd29b0ece9f6ad5d5d99fc2bf11d4972ec5a0ebad2a30f80e1` |
| **FB5** | cyberpunk rain | [743999](https://freesound.org/people/Rmshh/sounds/743999/) "Cyberpunk rain ambience (rain and city noises stem)" by **Rmshh** (5188925), 2024-06-29; WAV 44.1/32 stereo, 2:02.9. Page: "Generative cyberpunk rain ambience made in SunVox" | **CC BY 4.0**. Credit: *"Cyberpunk rain ambience (rain and city noises stem)" by Rmshh (https://freesound.org/s/743999/), CC BY 4.0, cut and looped* | 234 downloads, 4.8 (4) | 90 s from 16.2 s; 0.18 dB | full, 2,650,053 B, `92636f899641902f361e85fe8bef9d897cd4e0944b5d7af5779a9bc3106eda64` |
| **FB6** | sci-fi lab | [212025](https://freesound.org/people/qubodup/sounds/212025/) "Sci-fi Laboratory Ambience" by **qubodup** (71257), 2013-12-28; **Ogg Vorbis at source**, 10:00. Page: "a starship research laboratory, a computer science center or an utopian communications array", mixed from three CC0 sounds: wolick 191852, swiftoid "Cinematic Deep Rumble", Diboz 211683 | **CC BY 4.0** in the page's licence field; the description still says CC BY 3.0 and asks for *"Sci-fi Laboratory Ambience by Iwan Gabovitch under CC-BY 3.0 License with sounds by wolick, swiftoid, Diboz"* | **9.7K downloads, 4.8 (102)** | 90 s from 48.7 s; 0.27 dB | first 8 MiB (374 s), `bd6280156f0771478fd31b136177b5fb6e9968883d6f7b0329f3f2d26b4ffc8d` |
| **FB7** | deep space | [174450](https://freesound.org/people/Sonicfreak/sounds/174450/) "Space Ambience.wav" by **Sonicfreak** (746632), 2013-01-16; WAV 48/16 stereo, 2:31.4. Page: "created by blowing into a microphone while slowly changing pitches … slowed down" | **CC0** | **11.8K downloads, 4.8 (108)**: the most downloaded CC0 space ambience found | 90 s from 4.3 s; 0.47 dB | full, 3,139,751 B, `4105b1883743fcdc826dc71b988ae3fda8aadcda25c8f210e5c3a0a8433e9eb9` |
| **FB8** | electronic pad | [242773](https://freesound.org/people/PhonZz/sounds/242773/) "Angelic Pad Loop.wav" by **PhonZz** (3946286), 2014-07-18; WAV 44.1/16 stereo, 18:08. Page: "a basic chord progression with a drone note … a 64 bar loop with 8 bars of drone after. Key: f# Tempo: 120 bpm" | **CC0** | **6.5K downloads, 4.7 (214)** | 90 s from 90.8 s; 0.25 dB | first 8 MiB (420 s), `a1a93bfdc893d1f18c7b6c2a4a580355f38845159e7ec129db121ca37713f362` |

Every loop: decoded through the rain's 80 Hz high-pass to 48 kHz stereo float; loop start by `lib/LemnaClicks/tools/
loop_points.py match <src> 0 <last start> --loop 90` (the best of 95–3,261 starts tried, 0.1 s apart); the next 3 s laid
over the head on quarter sines (as the rain); scaled to −26 LUFS over both channels (FB1 −1.9 dB, FB2 −1.3, FB3 +11.5,
FB4 +4.2, FB5 +10.7, FB6 −7.0, FB7 −2.3, FB8 −7.8); AAC 128 kbit/s in CAF with `afconvert -f caff -d aac -b 128000
-q 127`; measured again as Core Audio decodes it (ffmpeg's ebur128, as for the rain's `lufs`): FB1 −26.1, FB2 −26.0, FB3 −26.0,
FB4 −26.1, FB5 −26.1, FB6 −26.0, FB7 −26.0, FB8 −26.1 LUFS, sample peaks −12.6 to −14.3 dBFS, 4,320,000 frames each.
CAF sizes and SHA-256 (a second run of the build made the same bytes; the code bed's note saw AAC differ below
−50 dBFS between runs):

| Loop | Bytes | SHA-256 |
|---|---|---|
| FB1 | 1,482,908 | `8b6275a77df6637d5632615f99f96f5b2b3ba8be2e9f1b64f375ed7078fc060d` |
| FB2 | 1,206,539 | `4cce0dc5927e0be8da337ff804d2905563aff7b74f22e3c25e0eeea8c926e14e` |
| FB3 | 1,422,616 | `6dad2733ebcf42e2be341c4b2cb9fa040609e8fd2090b153696d71c168868b4a` |
| FB4 | 1,472,639 | `915a963c8084e45744ffd375cb13f39e7da544fc774f4d690d47ad859e79c641` |
| FB5 | 1,421,205 | `ff4bcd7eec96d0e76bebcfdfa3b228855c5869048a063cdf380e5fa57b688340` |
| FB6 | 1,465,892 | `7b4d842c1c96177fa16664c8c2788410af7dc825b872974a5d3e9dc9f067ba1a` |
| FB7 | 1,433,729 | `bff3f0ebd356b8a9a55f0abeaff14ce709d208186703bd74d75e52cf056e04c3` |
| FB8 | 1,446,331 | `5c82cc1d769bee000eddfdc3b6a18f0dd0a846e57f5674b3ca33107aa741d1d2` |

Previews: the same loops as m4a, AAC 128 kbit/s (−26.0 to −26.1 LUFS; the rain's −26.3). Spectrograms: 20 s of each
CAF as decoded, 40 Hz to 16 kHz on a log scale.

## 3. Measurements [M]

Each loop as Core Audio decodes the CAF, with the code bed's `tools/analyze.py` (columns as `research_notes/Lemna code
bed/candidates.md` §3) and this note's `tools/extra.py`; loudness range from ffmpeg's ebur128. Added here:
- **Body:** the clicks' margin in 200 Hz–1 kHz (*sound* §2.3 reports this band for the rain beds, 3.3–19.0 dB), by the
  same method as analyze.py's: the loudest 10 % of 10 ms frames of the 60 s Keychron typing stream over the bed's left
  channel at −43 LUFS over both, median.
- **Laptop:** the loudness lost when a 4th-order 200 Hz high-pass stands in for laptop speakers (no speaker was
  measured; a MacBook's built-in speakers give little under about 150–200 Hz [I]).

| Bed | S-SD LU | LRA LU | Burst % | LF % | Centroid Hz | 1–4 kHz % | On/min | Pulse (lag) | Mod | Tonal | Corr | Clicks over it: broadband / 1–4 kHz / body, dB | Laptop dB | Wrap |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Rain bed (today) | 0.49 | 1.1 | 0 | 0.2 | 2,076 | 42.5 | 3 | 0.05 (2.6 s) | 0.33 | 1 | 0.22 | 21.3 / 20.1 / 6.0 | 0.0 | 0.03 |
| FB1 server room | **0.17** | 0.5 | 0 | 12.3 | 536 | 10.1 | 0 | 0.04 (2.3 s) | 0.10 | 8 | 0.82 | 17.8 / 23.7 / **0.0** | 1.3 | 0.49 |
| **FB2 spaceship cabin** | 0.36 | 1.0 | 0 | 52.4 | 225 | 0.0 | 0 | 0.04 (2.3 s) | 0.33 | 2 | 0.49 | 20.2 / 48.9 / 7.6 | 3.2 | 0.43 |
| FB3 sci-fi hall | 0.94 | 2.3 | 0 | 42.2 | 187 | 0.1 | 0 | 0.06 (0.3 s) | 0.12 | 6 | 0.05 | 18.3 / 44.5 / 4.4 | 4.9 | 0.50 |
| FB4 station drone | 0.24 | 0.7 | 0 | 54.5 | 193 | 0.8 | 0 | **0.22 (3.0 s)** | 0.18 | 69 | 0.36 | 19.1 / 34.0 / 5.5 | 5.5 | 0.78 |
| FB5 cyberpunk rain | 0.62 | 1.9 | 0 | 25.7 | 507 | 10.9 | 0 | 0.08 (0.2 s) | 0.12 | 0 | 0.00 | 18.7 / 24.1 / 1.7 | 1.6 | 0.74 |
| FB6 sci-fi lab | 0.27 | 0.9 | 0 | 80.0 | 169 | 0.1 | **132** | 0.15 (0.15 s) | **1.59** | 14 | 0.73 | 17.1 / 39.5 / 9.6 | 7.8 | 0.05 |
| FB7 deep space | **1.73** | **4.9** | 0 | 42.8 | 219 | 0.1 | 7 | 0.09 (0.4 s) | 0.73 | 3 | 0.00 | 18.9 / 40.6 / 3.3 | 3.6 | 0.51 |
| FB8 angelic pad | 1.02 | **3.0** | 0 | 5.5 | 411 | 3.0 | 0 | 0.11 (0.3 s) | 0.26 | **27** | 0.47 | 17.8 / 28.0 / **−0.8** | 0.8 | 0.34 |

Reading it:
- **The bar** is the rain's (*sound* §1.5, the steadiness rule): 3 s loudness SD at most about 1 LU, no bursts, no audible
  period, no voices or events, well under the clicks. Its "nothing under 150 Hz to speak of" was written against rumble
  in rain recordings (wind, traffic, handling); in a hum it is the sound itself, so here it is read as the laptop column:
  how much of the bed a laptop's speakers drop.
- **Broadband margins are lower than the rain's for every candidate** (17.1–20.2 dB against 21.3): the loudness that
  levels them (K-weighting) counts low frequencies less, so a dark bed at −43 LUFS carries more low energy. In 1–4 kHz,
  where a click's tick is, every candidate leaves the clicks clearer than the rain does (23.7–48.9 dB against 20.1).
- **The clicks' body** (200 Hz–1 kHz) is where the candidates differ. FB1's fans and FB8's pad fill it (0.0 and −0.8 dB:
  the body sits at the bed's level), FB5 nearly (1.7 dB); FB2, FB4 and FB6 leave it clearer than the rain (5.5–9.6 dB).
- **Periods** (`tools/periods.py`: band envelopes in 50 ms frames, autocorrelated):
  the rain, FB1 and FB2 decorrelate within 0.5 s with no peak above 0.10 at any lag. FB4 has a throb: 0.29 at 3 s in
  150–500 Hz and a 9 dB sweep in 1–4 kHz that holds for seconds (0.87 at 0.5 s), the pulse column's 0.22 at 3.03 s.
  FB3 wanders slowly in 150–500 Hz (0.39 at 0.5 s, no peak), FB5 in 1–4 kHz (0.67 at 0.5 s, a peak of 0.24 at 7.9 s).
- **FB6's 132 onsets a minute** are its blips (Diboz's "pseudo-random high pitched blips"): sparse tonal events, the
  changing-state case (*sound* §1.4), and the nearest thing on this panel to the tone grains the user turned down.
- **FB7** swells by 4.9 LU over the loop (a slowed breath); **FB8** changes chord every few bars (27 tonal peaks, range
  3.0 LU): segmented pitch change, the case *sound* §1.4 says disrupts verbal memory whatever the level.
- **FB4's 69 tonal peaks** are a held harmonic series (a hum), continuous pitch rather than a sequence.

## 4. Measured and not taken

Screened on up to 180 s from 2 s of each preview (or its first 8 MiB), decoded as above (`tools/screen.sh`; the
measures as §3, on the stretch rather than a loop). Downloads and ratings from the result pages.

| ID | Title, author | Licence | Popular | Why not |
|---|---|---|---|---|
| [4096](https://freesound.org/s/4096/) | rarexport-05.wav, plagasul | CC BY 4.0 | 27.5K, 4.3 (665) | The most downloaded of all found: "a tense coming and going reverbered strange breath"; S-SD 4.49 LU, 53 % under 150 Hz |
| [370754](https://freesound.org/s/370754/) | drone Space wind scifi.wav, ztitchez | CC BY 4.0 | 11.0K, 4.8 (124) | Swells: S-SD 4.06, pulse 0.56; "ominous" by intent |
| [320529](https://freesound.org/s/320529/) | cargoshipstarfleet.wav, vumseplutten1709 | CC0 | 9.8K, 4.6 (63) | A ship "nears, passes and fades out": S-SD 9.0, bursts 9.5 % |
| [20705](https://freesound.org/s/20705/) | spacedrone3.wav, Elektrocell | CC0 | 9.0K, 4.3 (142) | S-SD 2.67: "many little bugs working in big wind" |
| [38970](https://freesound.org/s/38970/) | archi_soundscape_electric1.wav, ElanHickler | CC0 | 7.5K, 4.3 (79) | S-SD 1.67, 73 % under 150 Hz, channels in part opposed (−0.47) |
| [211683](https://freesound.org/s/211683/) | control_room.wav, Diboz | CC0 | 6.2K, 4.8 (80) | 132 blips a minute (heard in FB6, which mixes it) |
| [609250](https://freesound.org/s/609250/) | Journey To The Interweb, Aemyn | CC0 | 5.7K, 4.3 (303) | A collage of stretched effects: S-SD 5.62, bursts 22 % |
| [104555](https://freesound.org/s/104555/) | Tone Drone.wav, thatjeffcarter | CC BY 4.0 | 5.2K, 4.9 (23) | S-SD 8.63, 147 onsets a minute, pulse 0.50 at 1 s |
| [254378](https://freesound.org/s/254378/) | Energy shield, Eevan | CC0 | 4.9K, 4.7 (83) | "pulsating": pulse 0.38 at 1.25 s, 96 % under 150 Hz |
| [219937](https://freesound.org/s/219937/) | Drone 007.wav, JarredGibb | CC0 | 4.5K, 4.5 (43) | Evolving: S-SD 3.46 |
| [443499](https://freesound.org/s/443499/) | Spaceship Ambience, PotatokingXII | CC0 | 3.6K, 4.9 (43) | Steady (0.28) and "seamless", but 77 % under 150 Hz, centroid 123 Hz: 9.7 dB lost on laptop speakers; FB2 is the same idea at 3.2 dB |
| [424415](https://freesound.org/s/424415/) | space ship atmos, CuddleNucks | CC BY 3.0 | 2.7K, 4.6 (19) | Mono, a flutter (pulse 0.67 at 0.15 s), 31 onsets a minute |
| [251624](https://freesound.org/s/251624/) | Dark-City_futuristic_ambient (near machinery vents), OnlyTheGhosts | CC BY 4.0 | 2.5K, 4.8 (50) | S-SD 1.69, 53 % under 150 Hz (first 8 MiB of a 32 min preview) |
| [322970](https://freesound.org/s/322970/) | spaceship.aif, LogicMoon | CC BY 4.0 | 2.4K, 4.8 (39) | 79 % under 150 Hz: 9.1 dB lost on laptop speakers |
| [256269](https://freesound.org/s/256269/) | Space ship atmosphere, jmayoff | CC0 | 1.8K, 4.9 (38) | Brown noise: 97 % under 150 Hz |
| [98930](https://freesound.org/s/98930/) | noisy server computer.wav, the_toilet_guy | CC BY 4.0 | 1.4K, 4.6 (14) | Microphones inside the case: S-SD 1.53, channels opposed (−0.66), so a mono speaker cancels it |
| [211994](https://freesound.org/s/211994/) | Computer Hum Noise, qubodup | CC0 | 1.4K, 4.7 (19) | Steady (0.14), but 60 s: no 90 s loop (57 s at most). FB1's fallback if a shorter loop is fine |
| [416070](https://freesound.org/s/416070/) | Blade Runner Ambient, onderwish | CC0 | 1.3K, 4.6 (36) | Mono, S-SD 1.89, pulse 0.42; named after a film, which the app could not carry |
| [345010](https://freesound.org/s/345010/) | Tech Background, caboose3146 | CC0 | 1.2K, 5.0 (18) | 209 onsets a minute, pulse 0.55 |
| [339046](https://freesound.org/s/339046/) | Filtered note, cabled_mess | CC0 | 1.1K, 4.9 (18) | Mono, bursts 18 %, pulse 0.75 at 2.85 s |
| [329907](https://freesound.org/s/329907/) | server room emissions.wav, aerror | CC0 | 1.0K, 4.9 (16) | Electromagnetic pickup, not air: S-SD 6.38, bursts 16 %, pulse 0.58 |
| [726484](https://freesound.org/s/726484/) | Sci-fi space traveling ambient suit, Simonus18 | CC0 | 927, 4.7 (28) | Pulse 0.79 at 2.08 s |
| [160591](https://freesound.org/s/160591/) | computer-noise_dell_d505_oldhdd_2004.wav, matucha | CC BY 4.0 | 909, 4.6 (14) | Hard-drive seeks: S-SD 2.46, bursts 3.6 % |
| [479258](https://freesound.org/s/479258/), [268198](https://freesound.org/s/268198/), [413489](https://freesound.org/s/413489/), [349030](https://freesound.org/s/349030/), [262357](https://freesound.org/s/262357/), [479463](https://freesound.org/s/479463/) | Futuristic.aif; All comments; Drone – … sci fi generator; dervied low drone; dischordientspace; buzzy cyberpunk pads | CC0 | 467–839, 4.9–5.0 | The best-rated drones: S-SD 1.08–17.97 LU, or pulses of 0.28–0.74 |
| [650743](https://freesound.org/s/650743/) | static noise from room, fan, air conditioner, electricity, lartti | CC0 | 804, 4.6 (28) | A netbook's microphone: S-SD 1.99, bursts 4.5 % |
| [614461](https://freesound.org/s/614461/) | 17. flying spaceship interior (roomtone), secondbody | CC0 | 563, 4.9 (12) | The steadiest measured (0.10 LU) and close to FB2, but nothing above 1 kHz and a faint original (−38.6 LUFS, 12.6 dB of gain); FB2's alternative |
| [536529](https://freesound.org/s/536529/) | Server Room ATMOS.wav, Smice_6 | CC0 | 434, 4.8 (4) | Steady (0.30) but mono and 62 s |
| [149915](https://freesound.org/s/149915/) | sh_Star_Engine_1.wav, shall555 | CC0 | 251 | 99 % under 150 Hz, S-SD 3.72 |
| [646877](https://freesound.org/s/646877/) | data center ambient noise.wav, Andron827 | CC0 | 138 | Mono, 54 % under 150 Hz |
| [727078](https://freesound.org/s/727078/) | Blade Runner ambient 03 – vehicles outside the streets, Simonus18 | CC0 | 99 | Vehicles pass: bursts 28 % |

## 5. Verdict per candidate

| ID | Steady (*sound* §1.5) | Clicks clear | Laptop | Fits Code [I] | Verdict |
|---|---|---|---|---|---|
| FB1 server room | Yes, the steadiest | Tick yes (23.7), body no (0.0) | Holds (1.3 dB) | The machine the code runs on | **Passes; risk:** fan noise is the white/pink noise of D1's evidence (*sound* §1.1, g −0.21 without ADHD), and the clicks lose their thock |
| **FB2 spaceship cabin** | Yes | Yes, in every band | Thinner (3.2 dB) | A ship's hull around the screens | **Recommended** |
| FB3 sci-fi hall | Yes, at the edge (0.94, range 2.3) | Yes (body 4.4) | Thinner (4.9 dB) | A hollow machine hall | **Second pick**, popular |
| FB4 station drone | Loudness yes; a 3 s throb | Yes | Thinner (5.5 dB) | Electrical hum | **Risk:** the throb is a lilt an ear can lock onto, as CB1's was |
| FB5 cyberpunk rain | Yes (0.62), slow swells | Tick yes, body nearly no (1.7) | Holds (1.6 dB) | Rain again | **Passes; risk:** two of three beds would be rain, as CB4 was; credit line |
| FB6 sci-fi lab | No: 132 blips a minute | Yes | Thin (7.8 dB) | A computer at work | **Fails** (changing state); popular |
| FB7 deep space | No: swells, range 4.9 | Yes | Thinner (3.6 dB) | Space | **Fails**; the most popular CC0 |
| FB8 angelic pad | No: a chord progression | Tick yes, body no (−0.8) | Holds (0.8 dB) | Music, not a place | **Fails**; popular |

Fatigue at −43 LUFS [I]: none of the passing four has a high band (FB2, FB3 almost nothing above 1 kHz, FB1 0.1 % above
5 kHz, the rain 10.6 %), so none hisses. No study tests a machine hum under writing; D1's noise evidence (white and pink noise) is the nearest,
and a hum is darker than either.

## 6. What any pick adds

As the Rain bed (`lib/LemnaClicks/README.md`, "Adding a bed"): a folder `Beds/<Name>` with its CAF (1.2–1.5 MB) and a
`bed.json` (`lufs` as §2 measured, −26.0 or −26.1), a second entry in Session › Sound ▸ beside the
Rain bed, its lines in `THIRD_PARTY.md` (page, licence, check date, preview SHA-256, loop) and in `tools/build_packs.sh`.
CC BY picks (FB5, FB6) add a credit line in THIRD_PARTY and, before Lemna goes to others, where a user sees it (THIRD_PARTY
open item 5). The engine plays one bed at a time; two picks are two menu items. No theme turns a new bed on (the code
bed's D2, recommended there and not taken with it).

## 7. Not verified

- How any of it sounds, on laptop speakers or headphones; whether FB2 reads as a ship or as a fridge, FB1 as servers or
  as a hair dryer; the level by ear (every bed at −43 LUFS, *sound* §2.3).
- The laptop column is a filter, not a speaker measurement.
- FB2's source: the author names none; it may be a recording of any machine or a synthesis.
- FB6's licence: the page's field says CC BY 4.0, its description CC BY 3.0 with a credit line in a form of its own; a
  pick should follow the field and give the author's credit as asked.
- The originals (a login) of the eight; FB6 and FB8 were measured on their previews' first 8 MiB only.
- Anything over 10–20 minutes of writing; the masking margins with packs other than Keychron.

## 8. Tools

In `tools/`; Python runs with `uv run -q --with numpy --with scipy python -I`, the parsers with the standard library.
- `fs_search2.py` — Freesound result pages: id, uploader, uploader id, duration, downloads, rating, number of ratings,
  licence, title (the code bed's `fs_search.py` plus the rating). Pages fetched with `curl -A "Mozilla/5.0"
  'https://freesound.org/search/?q=<q>&f=license%3A%28%22Creative+Commons+0%22+OR+%22Attribution%22%29+duration%3A%5B60+TO+*%5D&s=Downloads+%28most+first%29&page=<n>'`
  (or `s=Rating+%28highest+first%29`); the sound pages from `https://freesound.org/s/<id>/`, read with the code bed's
  `fs_page.py`.
- `oga_page.py` — OpenGameArt content pages: author, licences, favourites, files with sizes and download counts.
- `screen.sh <fb> <repo> id…` — §4's screening; the previews in `<fb>/dl/<id>/<id>-hq.ogg`.
- `build_candidates.sh <fb> <repo>` — §2's loops, CAFs, m4a previews and spectrograms into `<fb>/out`, then §3's measures.
- `extra.py`, `periods.py` — §3's body margin and laptop column; the band-envelope periods.

## 9. What shipped (pass 28, 2026-11-02)

The user, having heard the panel: "FB8, FB7, FB6 (cut the low low end a bit)", then "And FB2 (cut low low end again)".
FB6, FB7 and FB8 fail §5's steadiness verdict; the user picked them knowing it (the rule stands for recommendations).
They are four beds after the Rain bed in Session › Sound ▸, named for the menu: **Ship** (FB2), **Lab** (FB6),
**Space** (FB7), **Synth** (FB8), in `lib/LemnaClicks/Sources/LemnaClicks/Beds/<Name>/` (`bed.json`, `<name>.caf`),
made by `lib/LemnaClicks/tools/build_beds.sh <fb> <repo>` from the same previews (`<fb>/dl/<id>/<id>-hq.ogg`); the
panel's `build_candidates.sh` is unchanged and still makes the panel's previews. Credits, licences and every step:
`lib/LemnaClicks/THIRD_PARTY.md`, "The beds of pass 28".

**The low cut** [M], FB2 and FB6 only: a second two-pole Butterworth high-pass, `highpass=f=120:p=2`, after the 80 Hz
one every loop has, before the loop and the levelling; then levelled to −26 LUFS again. 120 Hz because FB2 has nothing
under 80 Hz (0.3 % of its energy): its "low low end" is its hum's two lowest partials, 99.6 and 117.2 Hz, under its
strongest at 146.5 Hz, and a corner at 100 Hz would barely touch them (under 150 Hz 55 → 48 %, laptop 3.2 → 2.6 dB in a
scratch trial at 80–140 Hz); FB6's is a 57 Hz rumble, 62.5 % of its energy, which 120 Hz takes 13 dB further down while
its hum's body (120–200 Hz) loses at most 3 dB before the levelling gives it back. Measured on the shipped loops as
decoded, against the panel's:

| | Under 150 Hz | Under 200 Hz lost (laptop, §3) | Gain to −26 LUFS | Other |
|---|---|---|---|---|
| FB2 → Ship | 52.4 → 40.5 % | 3.2 → 2.2 dB | −1.3 → −0.1 dB | 99.6 / 117.2 Hz partials 5.2 / 2.9 → 8.5 / 4.5 dB under the 146.5 Hz one; 3 s SD 0.36 → 0.35 LU; clicks' body 7.6 → 6.8 dB; wrap/p99.9 0.43 → 0.07 |
| FB6 → Lab | 80.0 → 38.1 % | 7.8 → 4.7 dB | −7.0 → −3.5 dB | 57 Hz rumble 62.5 → 11.2 % of the energy, 9.6 dB over the strongest hum partial → 2.3 dB under it; blips 3.5 dB nearer the clicks (1–4 kHz margin 39.5 → 36.1 dB, above 5 kHz 0.8 → 3.1 %); 132 → 133 onsets a minute |

Ship's mod rose 0.33 → 0.79, all of it in 4–8 kHz at −91 dBFS (its noise floor, inaudible); 0.5–2 kHz unchanged
(0.27, 0.13). Loop starts: `loop_points.py` on the filtered decodes ranked the same starts first (FB2 5.3 s, 0.10 dB;
FB6 48.7 s, 0.32 dB).

**Final files** (two runs of `build_beds.sh`, the second from an empty work folder, made the same bytes; Space and Synth
are §2's FB7 and FB8 byte for byte):

| Bed | File | Bytes | SHA-256 | LUFS as decoded | Peak dBFS | 3 s SD LU | LRA LU | Laptop dB | Clicks over it: broadband / 1–4 kHz / body, dB |
|---|---|---|---|---|---|---|---|---|---|
| Ship | `ship.caf` | 1,251,047 | `caefae306d879181037d1e1e527d8b149ee262f5c05b05f2554618d914870798` | −26.0 | −12.0 | 0.35 | 1.0 | 2.2 | 20.8 / 47.9 / 6.8 |
| Lab | `lab.caf` | 1,473,969 | `fd0c140cb600fc35496f3f94e825492073fe73bc764916e94c4b2ae7c1dab39e` | −26.0 | −13.8 | 0.27 | 1.0 | 4.7 | 19.6 / 36.1 / 6.6 |
| Space | `space.caf` | 1,433,729 | `bff3f0ebd356b8a9a55f0abeaff14ce709d208186703bd74d75e52cf056e04c3` | −26.0 | −13.0 | 1.73 | 4.9 | 3.6 | 18.9 / 40.6 / 3.3 |
| Synth | `synth.caf` | 1,446,331 | `5c82cc1d769bee000eddfdc3b6a18f0dd0a846e57f5674b3ca33107aa741d1d2` | −26.1 | −13.0 | 1.02 | 3.0 | 0.8 | 17.8 / 28.0 / −0.8 |

Each 4,320,000 frames (90 s at 48 kHz, stereo), decoded whole in 30–38 ms into 34.6 MB of floats (AVAudioFile, best of
five, release build, this Mac; the rain 38 ms). **The level at the wrap** [M]: the half second either side of it
differs by 0.12–1.29 dB per channel (Ship's left 1.29, Lab's left 1.18, the rain 0.15–0.20), at the 11th–74th
percentile of each loop's own differences between adjacent half seconds (their median 0.4–1.1 dB, their 90th 1.2–2.3
dB); the panel's FB2 already had 1.15 dB there. So pass 23a's test, 1 dB at most, became "no more than nine in ten of
the loop's own adjacent half seconds". **FB6's credit** names CC BY 4.0 (the page's field) and CC BY 3.0 (the author's
text), each with its link, in the author's own words (THIRD_PARTY.md).
